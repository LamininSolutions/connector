PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[Custom].[doCustomerImport]';

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'doCustomerImport'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'Custom' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [Custom].[doCustomerImport]
AS
BEGIN
       SELECT   'created, but not implemented yet.'--just anything will do
END
GO
-- the following section will be always executed
SET NOEXEC OFF
GO

alter procedure [Custom].[doCustomerImport]
      @WriteToMFiles bit = 0 --default (No)
    , @ProcessBatch_ID int output
    , @debug tinyint = 0
as /*******************************************************************************
  ** Desc:  Import posted epicor payments
  **  
  ** Version: 1.0.0.0
  **
  ** Assumptions:	
  **
  ** Processing Steps:	1. Parameter Validation
								- Get/Validate ProcessBatch_ID
								- Validate Table_ID in [ETL].[SourceTable]

  ** Parameters and acceptable values:
  **			@ProcessBatch_ID:	Optional - If not provided will initialize new, else validate against existing.
				@WriteToMFiles:		1: Yes
									0: No 
									
  ** 
  ** Tables Used:  
  **               l
  ** Return values:   = 1 Success
  **                  < 1 Failure
  **
  ** Called By:       None
  **
  ** Calls:           
  **					Sp_executesql
  **					spMFUpdateTable
  **				  	
  **
  ** Author:          arnie@lamininsolutions.com
  ** Date:            2017-05-11
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ******************************************************************************/

  
      begin

            SET NOCOUNT ON;
            SET XACT_ABORT ON;

	-------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
            DECLARE @MFTableName AS NVARCHAR(128) = 'CLCustomer'
            DECLARE @ProcessType AS NVARCHAR(50) = 'CustomerImport'

	-------------------------------------------------------------
    -- CONSTATNS: MFSQL Global 
    -------------------------------------------------------------
            DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
            DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
            DECLARE @Process_ID_1_Update TINYINT = 1	
            DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
			DECLARE @Process_ID_9_BatchUpdate TINYINT = 9	--marks records previously set as 1 to 9 and update in batches of 250
			DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
            DECLARE @Process_ID_2_SyncError TINYINT = 2
			DECLARE @ProcessBatchSize int = 250
	-------------------------------------------------------------
    -- VARIABLES: MFSQL Processing
    -------------------------------------------------------------
            DECLARE @MFUpdate_ID INT 
            DECLARE @MFLastModified DATETIME

	-------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
            DECLARE @rowcount AS INT = 0;
            DECLARE @return_value AS INT = 0;
            DECLARE @error AS INT = 0;

	-------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
            DECLARE @ProcedureName AS NVARCHAR(128) = '[Custom].[doCustomerImport]';
            DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
            DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
            DECLARE @DebugText AS NVARCHAR(256) = ''
            DECLARE @Msg AS NVARCHAR(256) = ''
            DECLARE @MsgSeverityInfo AS TINYINT = 10
            DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
            DECLARE @MsgSeverityGeneralError AS TINYINT = 16

	-------------------------------------------------------------
    -- VARIABLES: LOGGING
    -------------------------------------------------------------
            DECLARE @LogType AS NVARCHAR(50) = 'Status'
            DECLARE @LogText AS NVARCHAR(4000) = '';
            DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

            DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
            DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
            DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'

            DECLARE @LogColumnName AS NVARCHAR(128) = NULL
            DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

            DECLARE @count INT = 0;
            DECLARE @Now AS DATETIME = GETDATE();
            DECLARE @StartTime AS DATETIME;
            DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
            DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

	-------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
            DECLARE @sql NVARCHAR(MAX) = N''
            DECLARE @sqlParam NVARCHAR(MAX) = N''



	-------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
            SET @LogText = @ProcedureName + ' ' + @ProcessType + ' w/@WriteToMFiles='
                + ISNULL(CAST(@WriteToMFiles AS VARCHAR(20)), '(null)')
            EXEC [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
              , @ProcessType = @ProcessType
              , @LogType = 'Status'
              , @LogText = @LogText
              , @LogStatus = 'Started'
              , @debug = @debug
	

	-------------------------------------------------------------
    -- GET ClassID for MFTableName
    -------------------------------------------------------------
            DECLARE @MFClass_ID INT;
            SELECT  @MFClass_ID = [MFID]
            FROM    [dbo].[MFClass]
            WHERE   [TableName] = @MFTableName;	


	-------------------------------------------------------------
    -- PREPARE & CLEANSE STAGING DATA
    -------------------------------------------------------------

	IF OBJECT_ID('tempdb..#companies') IS NOT NULL DROP TABLE #companies;

	CREATE TABLE #companies(
			company_code varchar(8)
		,	db_name varchar(128)
		,	MFObjID int
		)
		INSERT [#companies] (   [company_code]
							  , [db_name]
							  , [MFObjID]
							)
			   SELECT [Epicor_Company_Code]
					, [Epicor_Database]
					, [ObjID]
			   FROM   [dbo].[CLEpicorCompany]
			   WHERE  [Is_Active] = 1

	IF OBJECT_ID('tempdb..#stage') IS NOT NULL DROP TABLE #stage;

	create table [#stage]
	(
		[Address_Block] [nvarchar](4000) null
	  , [Attention_Email] [nvarchar](100) null
	  , [Attention_Name] [nvarchar](100) null
	  , [Attention_Phone] [nvarchar](100) null
	  , [Customer_Code] [nvarchar](100)
	  , [Customer_Name] [nvarchar](100) null
	  , [Customer_Status] [nvarchar](100) null
	  , [Customer_Title] [nvarchar](100) null
	  , [Epicor_Company] [nvarchar](100) null
	  , [Epicor_Company_ID] [int]
	  , [ObjID] [int] null
	  ,
	  primary key clustered
	  (
		  [Epicor_Company_ID]
		, [Customer_Code]
	  )
	)

	

	DECLARE @db nvarchar(128)
	
	SELECT @db = min(db_name) 
	FROM #companies

	WHILE @db IS NOT NULL
	BEGIN
	SET @SQL = N'
		SELECT [Address_Block] = nullif(CONVERT(NVARCHAR(4000), ISNULL([arcust].[addr2], '''')
                            + CASE WHEN LEN(LTRIM(RTRIM(ISNULL([arcust].[addr3], '''')))) > 0 THEN CHAR(13) ELSE '''' END + ISNULL([arcust].[addr3], '''')
                            + CASE WHEN LEN(LTRIM(RTRIM(ISNULL([arcust].[addr4], '''')))) > 0 THEN CHAR(13) ELSE '''' END + ISNULL([arcust].[addr4], '''')
                            + CASE WHEN LEN(LTRIM(RTRIM(ISNULL([arcust].[addr5], '''')))) > 0 THEN CHAR(13) ELSE '''' END + ISNULL([arcust].[addr5], '''')
                            + CASE WHEN LEN(LTRIM(RTRIM(ISNULL([arcust].[addr6], '''')))) > 0 THEN CHAR(13) ELSE '''' END + ISNULL([arcust].[addr6], '''')
                            ),'''')
	    , [Attention_Email] = nullif([Attention_Email],'''')
	    , [Attention_Name]= nullif([Attention_Name],'''')
	    , [Attention_Phone]= nullif([Attention_Phone],'''')
	    , [Customer_Code]
	    , [Customer_Name]
	    , [Customer_Status] = arstat.[status_code]
		, [Customer_Title] = LEFT([customer_name],30) + '' | '' + [Customer_Code] + '' | '' + [glco].[company_code]
							+ case when arstat.[status_code] = ''INACTIVE'' THEN '' | INACTIVE'' ELSE '''' END
	    , [Epicor_Company] = [glco].[company_code]
	    , [Epicor_Company_ID] = [co].[MFObjID]
	FROM ' + quotename(@db) + '.dbo.[arcust] [arcust]
	INNER JOIN ' + quotename(@db) + '.dbo.[arstat] [arstat] ON [arstat].[status_type] = [arcust].[status_type]
	CROSS JOIN ' + quotename(@db) + '.dbo.glco glco
	INNER JOIN [#companies] CO ON [glco].[company_code] = co.[company_code]
	'

			INSERT	[#stage]
			(
				[Address_Block],
				[Attention_Email],
				[Attention_Name],
				[Attention_Phone],
				[Customer_Code],
				[Customer_Name],
				[Customer_Status],
				[Customer_Title],
				[Epicor_Company],
				[Epicor_Company_ID]

			)
			exec sp_executesql @SQL



		select @db = min(db_name) 
		from #companies
		where db_name > @db
	end

	-------------------------------------------------------------
	-- GET STATUC VALUES
	-------------------------------------------------------------


	-------------------------------------------------------------
	-- MFSQL: Refresh M-Files to MFSQL based on last modified
	-------------------------------------------------------------
	--IF ISNULL(@TimeZone_Offset_Override,0) != 0
	--BEGIN
	--		DECLARE @Last_MFModifiedDate DATETIME
	--		DECLARE @Update_IDOut INT
	--		DECLARE @TimeZone_Offset INT

 --           SELECT  @TimeZone_Offset = CAST([Value] AS INT)
 --           FROM    [dbo].[MFSettings]
 --           WHERE   [Name] = 'TimeZone_Offset'
 --                   AND [source_key] = 'Custom'

 --           IF @TimeZone_Offset_Override IS NOT NULL
 --              SET @TimeZone_Offset = @TimeZone_Offset_Override

	--		--offset by 24 hours to be sure to compensate for time zone difference
	--		SELECT @Last_MFModifiedDate = DATEADD(HOUR,@TimeZone_Offset,MAX([MF_Last_Modified])) 
	--		FROM [dbo].[CLCustomer]

	--		EXEC [dbo].[spMFUpdateTable]
	--			@MFTableName = @MFTableName
	--		  , @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL
	--		  , @UserId = NULL
	--		  , @MFModifiedDate = @Last_MFModifiedDate
	--		  , @ObjIDs = NULL
	--		  , @Update_IDOut = @Update_IDOut OUTPUT
	--		  , @ProcessBatch_ID = @ProcessBatch_ID
	--		  , @Debug = @debug
	--END

	-------------------------------------------------------------
	-- MFSQL: Refresh M-Files to MFSQL
	--	Get all objectversions from M-Files (spMFTableAudit)
	--	Match objectversions with SQL to determine objid's that need updating
	--	USE spMFUpdateTable with a filter on the objid's that is different between M-Files and SQL
	--	Determine that lastmodified date in M-Files and return it as output variable.
	--	Determine if any records have been deleted in M-Files and update SQL with the deletions.
	-------------------------------------------------------------
	DECLARE @Last_MFModifiedDate DATETIME
	EXEC [dbo].[spMFUpdateMFilesToMFSQL]
		    @ProcessBatch_ID = @ProcessBatch_ID 
		  , @UpdateTypeID = 2 --Incremental w/Deletion detection
		  , @MFTableName = @MFTableName
		  , @MFLastUpdateDate = @Last_MFModifiedDate OUTPUT
		  , @debug = @debug

	-------------------------------------------------------------
	-- MFSQL: MERGE #Source INTO MFClassTable 
	-------------------------------------------------------------

            BEGIN	
                  DECLARE @UpdateCount INT = 0
                  DECLARE @InsertCount INT = 0
		--DECLARE @DeleteCount INT = 0

                  DECLARE @tblMergeOutputSummary AS TABLE
                          (
                            [MergeAction] VARCHAR(20) NULL
                          );	
		-------------------------------------------------------------	
		-- MergeTableSQL
		-------------------------------------------------------------
		BEGIN
			MERGE [dbo].[CLCustomer] AS [target]
			USING (   SELECT [stage].[Address_Block]
						   , [stage].[Attention_Email]
						   , [stage].[Attention_Name]
						   , [stage].[Attention_Phone]
						   , [stage].[Customer_Code]
						   , [stage].[Customer_Name]
						   , [stage].[Customer_Status]
						   , [stage].[Customer_Title]
						   , [stage].[Epicor_Company]
						   , [stage].[Epicor_Company_ID]
					  FROM   [#stage] [stage]
				  ) AS [source]
			ON (   [target].[Epicor_Company_ID] = [source].[Epicor_Company_ID]
				   AND [target].[Customer_Code] = [source].[Customer_Code]
				   AND [target].[Deleted] = 0
			   )
			WHEN MATCHED AND EXISTS (   SELECT REPLACE(REPLACE(REPLACE([target].[Address_Block], ' ', ''), CHAR(13), ''), CHAR(10), '')
											 , [target].[Attention_Email]
											 , [target].[Attention_Name]
											 , [target].[Attention_Phone]
											 , [target].[Customer_Code]
											 , [target].[Customer_Name]
											 , [target].[Customer_Status]
											 , [target].[Customer_Title]
											 , [target].[Epicor_Company_ID]
										EXCEPT
										SELECT REPLACE(REPLACE(REPLACE([source].[Address_Block], ' ', ''), CHAR(13), ''), CHAR(10), '' )
											 , [source].[Attention_Email]
											 , [source].[Attention_Name]
											 , [source].[Attention_Phone]
											 , [source].[Customer_Code]
											 , [source].[Customer_Name]
											 , [source].[Customer_Status]
											 , [source].[Customer_Title]
											 , [source].[Epicor_Company_ID]
									) THEN UPDATE SET [target].[Address_Block] = [source].[Address_Block]
													, [target].[Attention_Email] = [source].[Attention_Email]
													, [target].[Attention_Name] = [source].[Attention_Name]
													, [target].[Attention_Phone] = [source].[Attention_Phone]
													, [target].[Customer_Code] = [source].[Customer_Code]
													, [target].[Customer_Name] = [source].[Customer_Name]
													, [target].[Customer_Status] = [source].[Customer_Status]
													, [target].[Customer_Title] = [source].[Customer_Title]
													, [target].[Epicor_Company_ID] = [source].[Epicor_Company_ID]
													, [target].[Process_ID] = @Process_ID_1_Update
													, [target].[Mfsql_Process_Batch] = @ProcessBatch_ID
													, [target].[Mfsql_Message] = 'Updated'
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (   [Address_Block]
						 , [Attention_Email]
						 , [Attention_Name]
						 , [Attention_Phone]
						 , [Customer_Code]
						 , [Customer_Name]
						 , [Customer_Status]
						 , [Customer_Title]
						 , [Epicor_Company]
						 , [Epicor_Company_ID]
						 , [Class_ID]
						 , [Name_Or_Title]
						 , [Single_File]
						 , [Deleted]
						 , [Process_ID]
						 , [Mfsql_Process_Batch]
						 , [Mfsql_Message]
					   )
				VALUES (   [source].[Address_Block]
						 , [source].[Attention_Email]
						 , [source].[Attention_Name]
						 , [source].[Attention_Phone]
						 , [source].[Customer_Code]
						 , [source].[Customer_Name]
						 , [source].[Customer_Status]
						 , [source].[Customer_Title]
						 , [source].[Epicor_Company]
						 , [source].[Epicor_Company_ID]
						 , @MFClass_ID
						 , [source].[Customer_Title] --Name and Title
						 , 0                         --Single File
						 , 0                         --deleted
						 , @Process_ID_1_Update      --ProcessID
						 , @ProcessBatch_ID
						 , 'Added'
					   )
			--             WHEN NOT MATCHED BY SOURCE then
			OUTPUT $action
			INTO @tblMergeOutputSummary;

			SET @rowcount = @@ROWCOUNT
			IF @rowcount > 0
				BEGIN
					SELECT @UpdateCount = COUNT(*)
					FROM   @tblMergeOutputSummary
					WHERE  [MergeAction] = 'UPDATE'

					SELECT @InsertCount = COUNT(*)
					FROM   @tblMergeOutputSummary
					WHERE  [MergeAction] = 'INSERT'

				--TODO: Log Count Details
				END --IF @RowCount > 0

		END -- MergeTableSQL
            end -- MFSQL: MERGE #Source INTO MFClassTable 


	-------------------------------------------------------------
	-- VALIDATIONS: 
	-------------------------------------------------------------
			UPDATE [target]
			SET    [target].[Mfsql_Process_Batch] = @ProcessBatch_ID
				 , [target].[Process_ID] = @Process_ID_1_Update
				 , [target].[Mfsql_Message] = 'Customer not in Source'
			FROM   [dbo].[CLCustomer] [target]
			WHERE  NOT EXISTS (   SELECT 1
								  FROM   [#stage]
								  WHERE  [Epicor_Company_ID] = [target].[Epicor_Company_ID]
										 AND [Customer_Code] = [target].[Customer_Code]
							  )
			AND [target].[Mfsql_Message] <> 'Customer not in Source'

	-------------------------------------------------------------	
	-- MFSQL: UPDATE, INSERT DELETE MFSQL --> M-FILES
	-------------------------------------------------------------
            begin
                  if @WriteToMFiles = 1
                     begin
			-------------------------------------------------------------
			-- UPDATE & INSERT MFSQL --> M-Files (process_id = 1)
			-------------------------------------------------------------
                           begin
                                 SET @count = 0;
                                 SELECT @count = COUNT([ID])
                                 FROM   [dbo].[CLCustomer]
                                 WHERE  [Deleted] = 0
										AND [Process_ID] = @Process_ID_1_Update
                                        AND [Mfsql_Process_Batch] = @ProcessBatch_ID;

                                 if @count > 0
                                    begin

                                          DECLARE @RemainingCount INT
                                          DECLARE @Duration INT

                                          UPDATE    [dbo].[CLCustomer]
                                          SET       [Process_ID] = @Process_ID_9_BatchUpdate
                                          WHERE     [Deleted] = 0
                                                    AND [Process_ID] = @Process_ID_1_Update
                                                    AND [Mfsql_Process_Batch] = @ProcessBatch_ID;

                                          SELECT    @RemainingCount = COUNT(*)
                                          FROM      [dbo].[CLCustomer]
                                          WHERE     [Deleted] = 0
                                                    AND [Process_ID] = @Process_ID_9_BatchUpdate
                                                    AND [Mfsql_Process_Batch] = @ProcessBatch_ID;
 
                                          while @RemainingCount > 0
                                                begin 
                                                      SET @StartTime = GETDATE()

                                                      SET ROWCOUNT @ProcessBatchSize --Process in batches of 250 at a time in order to show progress

                                                      UPDATE    [dbo].[CLCustomer]
                                                      SET       [Process_ID] = @Process_ID_1_Update
                                                      WHERE     [Deleted] = 0
                                                                AND [Process_ID] = @Process_ID_9_BatchUpdate
                                                                AND [Mfsql_Process_Batch] = @ProcessBatch_ID; 

                                                      SET ROWCOUNT 0

                                                      exec @return_value = [dbo].[spMFUpdateTable]
                                                        @MFTableName = @MFTableName
                                                      , @UpdateMethod = @UpdateMethod_0_MFSQLToMFiles
                                                      , @UserId = null
                                                      , @MFModifiedDate = null
                                                      , @ObjIDs = null
                                                      , @Update_IDOut = @MFUpdate_ID output
                                                      , @ProcessBatch_ID = @ProcessBatch_ID
                                                      , @Debug = @debug;

													  select    @RemainingCount = count(*)
													  from      [dbo].[CLCustomer]
													  where     [Deleted] = 0
																and [Process_ID] = @Process_ID_9_BatchUpdate
																and [Mfsql_Process_Batch] = @ProcessBatch_ID;
 
                                                end --WHILE @RemainingCount > 0
                                    end;
                           end --Update MFSQL To M-Files for process_id = 1

			-------------------------------------------------------------	
			-- DELETE MFSQL --> M-Files (process_id = 6) ** NOT IMPLEMENTED
			-------------------------------------------------------------
			
                     end --IF @WriteToMFiles = 1

            end-- MFSQL: UPDATE & INSERT MFSQL --> M-FILES

            set @LogStatus = 'Completed'
 /*************************************************************************************
	END OF PROCEDURE / LOGGING
*************************************************************************************/
            END_RUN:
	
            set @RunTime_Total = datediff(MS, @StartTime_Total, getutcdate()) / 1000

            exec @return_value = [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_ID
              , @LogText = @LogText
              , @LogStatus = @LogStatus
              , @debug = @debug
	
            return 1
	
	
      end



go