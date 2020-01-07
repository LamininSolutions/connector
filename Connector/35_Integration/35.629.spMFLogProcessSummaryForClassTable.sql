
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFLogProcessSummaryForClassTable]';
go

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFLogProcessSummaryForClassTable', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFLogProcessSummaryForClassTable'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFLogProcessSummaryForClassTable]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFLogProcessSummaryForClassTable]
	(
	    @ProcessBatch_ID INT
	  , @MFTableName NVARCHAR(100)
	  , @IncludeStats BIT = 0 --Future Use
	  , @IncludeAudit BIT = 0 --Future Use
	  , @InsertCount INT = NULL	
	  , @UpdateCount INT = NULL
	  , @LogProcedureName NVARCHAR(100) = NULL
	  , @LogProcedureStep NVARCHAR(100) = NULL
	  , @LogTextDetailOUT NVARCHAR(4000) = NULL OUTPUT
	  , @LogStatusDetailOUT NVARCHAR(50) = NULL OUTPUT
	  , @debug TINYINT = 0
	)
AS
/*rST**************************************************************************

==================================
spMFLogProcessSummaryForClassTable
==================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch\_ID int (optional)
    Referencing the ID of the ProcessBatch logging table
  @MFTableName nvarchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @IncludeStats bit
    - Reserved
  @IncludeAudit bit
    - Reserved
  @InsertCount int (optional)
    - Default = NULL
    - Use to set #Inserted in LogText
  @UpdateCount int (optional)
    - Default = NULL
    - Use to set #Updated in LogText
  @LogProcedureName nvarchar(100) (optional)
    - Default = NULL
    - The calling stored procedure name
  @LogProcedureStep nvarchar(100) (optional)
    - Default = NULL
    - The step from the calling stored procedure to include in the Log
  @LogTextDetailOUT nvarchar(4000) (output)
    - The LogText written to MFProcessBatchDetail
  @LogStatusDetailOUT nvarchar(50) (output)
    - The LogStatus written to MFProcessBatchDetail
  @debug tinyint
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Calculate various totals, including error counts and update MFProcessBatch and MFProcessBatchDetail LogText and Status.

Additional Info
===============

Calculate various totals, including error counts and update MFProcessBatch and MFProcessBatchDetail LogText and Status.

Counts are performed on the MFClassTable based on MFSQL_Process_Batch and Process_ID

Counts included:

- Record Count
- Deleted Count
- Synchronization Error Count
- M-Files Error Count
- SQL Error Count
- MFLog Count related to

Based on any of the Error count being larger than 0, the LogStatusDetail will be appended with 'w/Errors' text.

The LogTextDetail is set to the following value, with only displaying the counts larger than 0:

.. code:: text

    #Records: @RecordCount | #Inserted: @InsertCount | #Updated: @UpdateCount | #Deleted: @DeletedCount | #Sync Errors: @SyncErrorCount | #MF Errors: @MFErrorCount | #SQL Errors: @SQLErrorCount | #MFLog Errors: @MFLogErrorCount

Add the following properties to M-Files Classes: MFSQL Process Batch



Prerequisites
=============

Requires use MFProcessBatch in solution.

Requires use of MFSQL Process Batch on class tables.

Warnings
========

This procedure to be used as part of an overall messaging and logging solution. It will typically be called towards the end of your processes against a specific MFClassTable.

Relies on the usage of MFSQL_Process_Batch as a property in all M-Files classes that are part of your solution. Your solution code should also be written to set the MFSQL_Process_Batch to the ProcessBatch_ID for all operations where you set the Process_ID to 1.

Examples
========

.. code:: sql

    DECLARE @LogTextDetailOUT NVARCHAR(4000)
       , @LogStatusDetailOUT NVARCHAR(50);

    EXEC [dbo].[spMFLogProcessSummaryForClassTable] @ProcessBatch_ID = ?
                 , @MFTableName = ?
                 , @InsertCount = ?
                 , @UpdateCount = ?
                 , @LogProcedureName = ?
                 , @LogProcedureStep = ?
                 , @LogTextDetailOUT = @LogTextDetailOUT OUTPUT
                 , @LogStatusDetailOUT = @LogStatusDetailOUT OUTPUT
                 , @debug = 0

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

/*******************************************************************************
  ** Desc:  Format Messages for output to Context Menu UI and/or Mulit-Line Text Property
  ** NB  this procedure relies on the use of MFSQL_Process_Batch as part of the infrastructure

  ** Parameters and acceptable values:
  **	@MFTableName:			Optional - Error message from Stats output is NOT included if not provided.
  **	@Processbatch_ID		Required - Retrieve message content values from MFProcessBatch
  **	@MessageOUT:			Optional - Return message formatted for display by Context Menu with non-asyncronous process (includes newline as \n)
  ******************************************************************************/
	BEGIN
		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''
		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFLogProcessSummaryForClassTable';
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
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;


		
		-------------------------------------------------------------
		-- VARIABLES:THIS PROC
		-------------------------------------------------------------
		DECLARE @Message NVARCHAR(4000);

		DECLARE
    @RecordCount                 INT,
    @SQLRecordCount              INT,
    @MFRecordCount               INT,
    @SyncError                   INT,
    @Process_ID_1                INT,
    @MFError                     INT,
    @SQLError                    INT,
    @MFLastModified              Datetime,
    @SessionID                   INT,
    @DeletedCount                INT,
    @SyncErrorCount_Process_ID_2 INT,
    @MFErrorCount_Process_ID_3   INT,
    @SQLErrorCount_Process_ID_4  INT,
    @MFLogError_Count            INT,
    @ProcessType                 NVARCHAR(50),
    @ClassName                   NVARCHAR(100);

		SELECT @LogStatusDetail = 'Completed'
			,  @ProcessType = [ProcessType]	
			,  @StartTime = [CreatedOnUTC]
		FROM [dbo].[MFProcessBatch]
		WHERE [ProcessBatch_ID] = @ProcessBatch_ID

		SELECT @ClassName = [Name]
		FROM [dbo].[MFClass]
		WHERE [TableName] = @MFTableName

		BEGIN try
-- Total Records updated Count
		SET @sql = N'SELECT @Count = COUNT(*)
						FROM   [dbo].' + QUOTENAME(@MFTableName) + '
						WHERE  [Mfsql_Process_Batch] = @ProcessBatch_ID'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'
		
		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @RecordCount OUTPUT

-- Deleted Count
		SET @sql = N'SELECT @Count = COUNT(*)
						FROM   [dbo].' + QUOTENAME(@MFTableName) + '
						WHERE  [Mfsql_Process_Batch] = @ProcessBatch_ID
						AND [Deleted] = 1'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'

		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @DeletedCount OUTPUT

-- SyncError Count
		SET @sql = N'SELECT @Count = COUNT(*)
						FROM   [dbo].' + QUOTENAME(@MFTableName) + '
						WHERE  [Mfsql_Process_Batch] = @ProcessBatch_ID
						AND [Process_ID] = 2
						AND [Deleted] = 0'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'

		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @SyncErrorCount_Process_ID_2 OUTPUT


-- MFError Count
		SET @sql = N'SELECT @Count = COUNT(*)
						FROM   [dbo].' + QUOTENAME(@MFTableName) + '
						WHERE  [Mfsql_Process_Batch] = @ProcessBatch_ID
						AND [Process_ID] = 3
						AND [Deleted] = 0'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'

		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @MFErrorCount_Process_ID_3 OUTPUT

-- SQLError Count
		SET @sql = N'SELECT @Count = COUNT(*)
						FROM   [dbo].' + QUOTENAME(@MFTableName) + '
						WHERE  [Mfsql_Process_Batch] = @ProcessBatch_ID
						AND [Process_ID] = 4
						AND [Deleted] = 0'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'

		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @SQLErrorCount_Process_ID_4 OUTPUT

			
-- MFLogError Count
		SET @sql = N'SELECT @Count = COUNT(DISTINCT [LogID])
						FROM   [dbo].' + QUOTENAME(@MFTableName) + ' [cl]
						INNER JOIN [dbo].[MFLog] ON [cl].[Update_ID] = [MFLog].[Update_ID]
						WHERE  [cl].[Mfsql_Process_Batch] = @ProcessBatch_ID
						AND [cl].[Deleted] = 0'

		SET @sqlParam = '@ProcessBatch_ID INT,@Count INT OUTPUT'

		EXEC [sys].[sp_executesql] @sql
								 , @sqlParam
								 , @ProcessBatch_ID
								 , @MFLogError_Count OUTPUT

--Get LogStatusDetail
		SET @LogStatusDetail = @LogStatusDetail + CASE WHEN @SyncErrorCount_Process_ID_2 > 0
												OR @MFErrorCount_Process_ID_3 > 0
												OR @SQLErrorCount_Process_ID_4 > 0
												OR @MFLogError_Count > 0 THEN ' w/Errors'
											ELSE ''
										END

--Get LogTextDetail
		SET @LogTextDetail =  '#Records: ' + ISNULL(CAST(@RecordCount AS VARCHAR(10)), '(null)')
							  + CASE WHEN @InsertCount > 0 THEN
										 ' | ' + '#Inserted: ' + ISNULL(CAST(@InsertCount AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @UpdateCount > 0 THEN
										 ' | ' + '#Updated: ' + ISNULL(CAST(@UpdateCount AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @DeletedCount > 0 THEN
										 ' | ' + '#Deleted: ' + ISNULL(CAST(@DeletedCount AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @SyncErrorCount_Process_ID_2 > 0 THEN
										 ' | ' + '#Sync Errors: '
										 + ISNULL(CAST(@SyncErrorCount_Process_ID_2 AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @MFErrorCount_Process_ID_3 > 0 THEN
										 ' | ' + '#MF Errors: '
										 + ISNULL(CAST(@MFErrorCount_Process_ID_3 AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @SQLErrorCount_Process_ID_4 > 0 THEN
										 ' | ' + '#SQL Errors: '
										 + ISNULL(CAST(@SQLErrorCount_Process_ID_4 AS VARCHAR(10)), '(null)')
									 ELSE ''
								END
							  + CASE WHEN @MFLogError_Count > 0 THEN
										 ' | ' + '#MFLog Errors: '
										 + ISNULL(CAST(@MFLogError_Count AS VARCHAR(10)), '(null)')
									 ELSE ''
								END


--Get Class Table Stats
		IF @IncludeStats = 1
			BEGIN
		--Update Class Table Audit
				IF @IncludeAudit = 1
				BEGIN
					DECLARE @SessionIDOut INT
							, @NewObjectXml NVARCHAR(MAX);

					EXEC [dbo].[spMFTableAudit] @MFTableName = @MFTableName
												, @MFModifiedDate = NULL
												, @ObjIDs = NULL
												, @ProcessBatch_ID = @ProcessBatch_ID 
												, @SessionIDOut = @SessionIDOut OUTPUT
												, @NewObjectXml = @NewObjectXml OUTPUT



				END--IF @IncludeAudit = 1

			
				EXEC [dbo].[spMFClassTableStats] @ClassTableName = @MFTableName
				,@IncludeOutput = 1


				-- smallint
				SELECT 
					  @SQLRecordCount = [s].[SQLRecordCount]
					 , @MFRecordCount  = [s].[MFRecordCount]
					 , @SyncError	   = [s].[SyncError]
					 , @Process_ID_1   = [s].[Process_ID_1]
					 , @MFError		   = [s].[MFError]
					 , @SQLError	   = [s].[SQLError]
					 , @MFLastModified = [s].[MFLastModified]
					 , @SessionID	   = [s].[sessionID]
				FROM   ##spMFClassTableStats AS [s];

			SET @LogTextDetail = @LogTextDetail + ' |  | ' + 'TOTALS' + ' | '


			END--IF @IncludeStats = 1

--Insert Log Detail

		SET @LogColumnName = 'RecordCount'
		SET @LogColumnValue = CAST(@RecordCount AS NVARCHAR(256))

		EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
													, @LogType = 'Message'
													, @LogText = @LogTextDetail
													, @LogStatus = @LogStatusDetail
													, @StartTime = @StartTime
													, @MFTableName = @MFTableName
													, @ColumnName = @LogColumnName
													, @ColumnValue = @LogColumnValue
													, @LogProcedureName = @LogProcedureName
													, @LogProcedureStep = @LogProcedureStep
													, @debug = 0
														 		
	  SET @LogTextDetailOUT = @LogTextDetail
	  SET @LogStatusDetailOUT = @LogStatusDetail

		-- Return the result of the function
		RETURN 1;

	END TRY
    
			BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = NULL
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = NULL
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH

	END

GO


