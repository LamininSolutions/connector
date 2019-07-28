PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateTable_ObjIDs_Grouped]';

SET NOCOUNT ON;
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTable_ObjIDs_Grouped', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateTable_ObjIDs_Grouped'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[spMFUpdateTable_ObjIDs_Grouped]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER PROCEDURE [dbo].[spMFUpdateTable_ObjIDs_Grouped]
    (
      @MFTableName NVARCHAR(128),
	  @MFTableSchema NVARCHAR(128) = 'dbo',
	  @UpdateMethod INT = 1, 
      @ProcessId INT = 6     ,	-- 6 Merged Updates 
      @UserId NVARCHAR(200) = NULL, --null for all user update
	  @ProcessBatch_ID INT = NULL OUTPUT,
      @Debug SMALLINT = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to group source records into batches
  **		and compile a list of OBJIDs in CSV format to pass to spMFUpdateTable
  **  
  ** Version: 1.0.0.0
  **
  ** Processing Steps:
  **					1. Calculate Number of Groups in RecordSet
  **					2. Assign Group Numbers to Source Records
  **					3. Get ObjIDs CSV List by GroupNumber
  **					4. Loop Through Groups - Execute [spMFUpdateTable]
  **						- Update Process_ID = 1
  **						- Execute [spMFUpdateTable] with ObjIDs csv list	
  **
  ** Parameters and acceptable values: 
  **					@MFTableName		NVARCHAR(128)
  **					@MFTableSchema		NVARCHAR(128)
  **					@UpdateMethod	   0: MFSQL to M-Files; 1: M-Files to MFSQL
  **					@ProcessId			INT	  -- The Process_ID in class table to evaluate for grouping
  **					@UserId				NVARCHAR(200)         
  **					@Debug				SMALLINT = 0
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					1 = success
  **					2 = Failure	
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					sp_executesql
  **					spMFUpdateTable
  **
  ** Author:			arnie@lamininsolutions.com
  ** Date:				2016-05-14
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2017-06-29	ArnieC		- @ObjIds_toUpdate change sizes to NVARCHAR(4000)
							- @ObjIds_FieldLenth change default value to 2000
  ********************************************************************************
  ** EXAMPLE EXECUTE
  ********************************************************************************
		EXEC [spMFUpdateTable_ObjIDs_Grouped]  @MFTableName = 'CLGLChart',
							  @MFTableSchema = 'dbo',
							  @UpdateMethod = 0
							  @ProcessId = 6     ,	-- 6 Merged Updates
							  @UserId = NULL, --null for all user update
							  @Debug  = 1

  ******************************************************************************/
    BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-----------------------------------------------------
	--DECLARE LOCAL VARIABLE
	-----------------------------------------------------
	   DECLARE	@return_value INT = 1
			,	@rowcount INT = 0
			,	@ProcedureName sysname = 'spMFUpdateTable_ObjIDs_Grouped'
			,	@Procedurestep NVARCHAR(128) = ''
			,	@ObjIds_FieldLenth INT = 2000
			,	@sqlQuery NVARCHAR(MAX)
			,	@sqlParam NVARCHAR(MAX)


-----------------------------------------------------
		--DECLARE VARIABLES FOR LOGGING
		-----------------------------------------------------
                  DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
                  DECLARE @DebugText AS NVARCHAR(256) = '';
                  DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
                  DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
                  DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
                  DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
                  DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
                  DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
                  DECLARE @ProcessType NVARCHAR(50)
                  DECLARE @LogType AS NVARCHAR(50) = 'Status'
                  DECLARE @LogText AS NVARCHAR(4000) = '';
                  DECLARE @LogStatus AS NVARCHAR(50) = 'Started'
                  DECLARE @Status AS NVARCHAR(128) = NULL;
                  DECLARE @Validation_ID INT = NULL;
                  DECLARE @StartTime AS DATETIME;
                  DECLARE @RunTime AS DECIMAL(18, 4) = 0;



                          SET @ProcedureStep = 'Start';
                           SET @StartTime = GETUTCDATE();
                           SET @ProcessType = @ProcedureName
                           SET @LogType = 'Status'
                           SET @LogStatus = 'Started'
                           SET @LogText = 'Group IDs for Process_ID ' + CAST(@ProcessId AS VARCHAR(10))

                           EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText
                          , @LogStatus = @LogStatus
                          , @debug = @debug

	-----------------------------------------------------
	--Calculate Number of Groups in RecordSet
	-----------------------------------------------------
	SET @ProcedureStep = 'Get Number of Groups '
	DECLARE @NumberofGroups INT
		SET @sqlQuery = N'
				SELECT  @NumberofGroups = ( SELECT   COUNT(*)
							   FROM    ' + @MFTableSchema +'.' + @MFTableName + '
							   WHERE    Process_ID = @ProcessId
							 ) / ( @ObjIds_FieldLenth --ObjIds fieldlenth
								   / ( SELECT   MAX(LEN(ObjID)) + 2
									   FROM   ' + @MFTableSchema +'.' + @MFTableName + '
									   WHERE    Process_ID = @ProcessId
									 ) --avg size of each item in csv list including comma
								   );			
				'
		SET @sqlParam = N'
							@ProcessId INT
						  ,	@ObjIds_FieldLenth INT
						  ,	@NumberofGroups INT OUTPUT
						'

		EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,	@ObjIds_FieldLenth = @ObjIds_FieldLenth
							,	@NumberofGroups =  @NumberofGroups OUTPUT

		SET @NumberofGroups = ISNULL(NULLIF(@NumberofGroups,0),1)
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d group(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@NumberofGroups);

	-----------------------------------------------------
	--Logging Number of Groups in RecordSet
	-----------------------------------------------------
	

	       SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Calculated'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Number of Groups: '
                           SET @LogColumnValue = CAST(@numberofgroups AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

	   
	-----------------------------------------------------
	--Assign Group Numbers to Source Records
	-----------------------------------------------------
	SET @ProcedureStep = 'Assign Group Numbers to Source Records '
	CREATE TABLE #GroupDtl ([ID] INT, [ObjID] INT,GroupNumber int )
	
	SET @sqlQuery = N'
					SELECT ID
				  , ObjID
				  , NTILE(@NumberofGroups) OVER ( ORDER BY ObjID ) AS GroupNumber
			FROM     ' + @MFTableSchema +'.' + @MFTableName + '
			WHERE   Process_ID = @ProcessId;
			'  

	SET @sqlParam = N'
							@ProcessId INT
						,	@NumberofGroups INT
					'

	INSERT  #GroupDtl
			( ID
			, ObjID
			, GroupNumber
			)
		EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,   @NumberofGroups = @NumberofGroups

	
		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Get ObjIDs CSV List by GroupNumber
	-----------------------------------------------------
	SET @ProcedureStep = 'Get ObjIDs CSV List by GroupNumber '

		CREATE TABLE #GroupHdr (GroupNumber INT, ObjIDs NVARCHAR(4000))
		INSERT  #GroupHdr
				( GroupNumber
				, ObjIDs
				)
				SELECT  [source].GroupNumber
					  , ObjIDs = STUFF(( SELECT ','
											  , CAST(ObjID AS VARCHAR(10))
										 FROM   #GroupDtl
										 WHERE  GroupNumber = [source].GroupNumber
									   FOR
										 XML PATH('')
									   ), 1, 1, '')
				FROM    ( SELECT    GroupNumber
						  FROM      #GroupDtl
						  GROUP BY  GroupNumber
						) [source];

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Loop Through Groups - Execute [spMFUpdateTable]
	-----------------------------------------------------
	SET @ProcedureStep = 'Loop Through Groups - Execute [spMFUpdateTable] '
		DECLARE @CurrentGroup INT, @ObjIds_toUpdate NVARCHAR(4000)

		SELECT @CurrentGroup = MIN(GroupNumber)
		FROM  #GroupHdr
		WHILE @CurrentGroup IS NOT NULL	
		BEGIN
		
			SET @sqlQuery = N'
						 UPDATE MFTable
						 SET Process_ID = CASE WHEN @UpdateMethod = 0 THEN 1 ELSE 0 END
						 FROM  ' + @MFTableSchema +'.' + @MFTableName + ' MFTable
						 INNER JOIN #GroupDtl t ON MFTable.ID = t.ID
						 WHERE t.GroupNumber = @CurrentGroup
						 AND MFTable.Process_ID = @ProcessID
						'

			SET @sqlParam = N'
								@ProcessId INT
							,	@CurrentGroup INT
							,	@UpdateMethod INT
							'

			EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,	@CurrentGroup = @CurrentGroup
							,	@UpdateMethod = @UpdateMethod


			 SELECT @rowcount = @@ROWCOUNT

			 IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: GroupNumber: %d: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@CurrentGroup,@rowcount);
		

			 SELECT @ObjIds_toUpdate = ObjIDs
			 FROM #GroupHdr
			 WHERE GroupNumber = @CurrentGroup	 

			EXEC @return_value = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName
									, @UpdateMethod = @UpdateMethod
									, @UserId = NULL
									, @MFModifiedDate = NULL
									, @ObjIDs = @ObjIds_toUpdate -- CSV List
									,@ProcessBatch_ID = @ProcessBatch_ID
									, @Debug = @Debug;

			  IF @Debug > 0
				PRINT  @ObjIds_toUpdate
			    

-----------------------------------------------------
	--Logging Completion of process for Group
	-----------------------------------------------------
	

	       SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Completed'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Group Number: '
                           SET @LogColumnValue = CAST(@CurrentGroup AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
		
             --   IF @return_value <> 1
             --   BEGIN
             --       RAISERROR('EXEC [spMFUpdateTable] @MFTableName=%s,@UpdateMethod=0 | Returned with %d',16,1,@MFTableName,@return_value);
             --   END;

	            --IF EXISTS ( SELECT    1
             --           FROM      CLGLChart
             --           WHERE     Process_ID <> 0 )
             --   BEGIN
             --       RAISERROR('EXEC [spMFUpdateTable] @MFTableName=%s,@UpdateMethod=0 | Process_ID=<>0',16,1,@MFTableName);
             --   END;

	
			SELECT @CurrentGroup = MIN(GroupNumber)
			FROM  #GroupHdr
			WHERE GroupNumber > @CurrentGroup
	
		END

--Log end of procedure

		        SET @ProcedureName = 'spMFUpdateTable_ObjIDs_Grouped';
               
                  SET @ProcedureStep = 'Grouping Process Completed ';
                  SET @LogType = 'Status'
                  SET @LogText = @Procedurestep + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
                  SET @LogStatus = N'Completed';

                  EXEC [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          ,-- int
                            @LogType = @LogType
                          ,-- nvarchar(50)
                            @LogText = @LogText
                          ,-- nvarchar(4000)
                            @LogStatus = @LogStatus
                          ,-- nvarchar(50)
                            @debug = @debug;-- tinyint


   SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Completed'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Last Group: '
                           SET @LogColumnValue = CAST(@CurrentGroup AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
		


	END




GO


