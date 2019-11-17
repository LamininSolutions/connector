


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateObjectChangeHistory]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFUpdateObjectChangeHistory' -- nvarchar(100)
  , @Object_Release = '4.4.13.54'
  , @UpdateFlag = 2

GO

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFUpdateObjectChangeHistory' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateObjectChangeHistory]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFUpdateObjectChangeHistory]
	(@WithClassTableUpdate INT = 1,
	@ProcessBatch_ID INT = NULL,
	   @Debug			 SMALLINT = 0
	)
AS


/*rST**************************************************************************

=============================
spMFUpdateObjectChangeHistory
=============================

Return
  - 1 = Success
  - -1 = Error

  @WithClassTableUpdate int
  - Default = 1 (yes)  

  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To process change history for multiple class table and property combinations 

Additional Info
===============

Update MFObjectChangeHistoryUpdatecontrol for each class and property to be included in the update. Use separate rows for for each property to be included. A class may have multiple rows if multiple properties are to be processed for the tables.

The routine is designed to get the last updated date for the property and the class from the MFObjectChangeHistory table. The next update will only update records after this date.

Delete the records for the class and the property to reset the records in the table MFObjectChangeHistory or to force updates prior to the last update date

This procedure is included in spMFUpdateAllIncludedInAppTables routine.  This allows for scheduling only the latter procedure in an agent to ensure that all the updates in the App is included.  

spMFUpdateObjectChangeHistory can be run on its own, either by calling it using the Context menu Actions, or any other method.

Prerequisites
=============

The table MFObjectChangeHistoryUpdatecontrol must be updated before this procedure will work

Include this procedure in an agent to schedule to update.

Warnings
========

Do not specify more than one property for a single update, rather specify a separate row for each property.

Examples
========

.. code:: sql
	INSERT INTO dbo.MFObjectChangeHistoryUpdateControl
	(
		MFTableName,
		ColumnNames
	)
	VALUES
	(   N'MFCustomer', 
		N'State_ID'  
		),
	(   N'MFPurchaseInvoice', 
		N'State_ID'  
		)

----

.. code:: sql
    exec spMFUpdateObjectChangeHistory @WithClassTableUpdate = 1, @Debug = 1
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-11-04  LC         Create procedure

==========  =========  ========================================================

**rST*************************************************************************/

	BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = ''
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Change History Update')

		-------------------------------------------------------------
		-- CONSTATNS: MFSQL Global 
		-------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
		DECLARE @Process_ID_1_Update TINYINT = 1
		DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
		DECLARE @Process_ID_9_BatchUpdate TINYINT = 9 --marks records previously set as 1 to 9 and update in batches of 250
		DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
		DECLARE @Process_ID_2_SyncError TINYINT = 2
		DECLARE @ProcessBatchSize INT = 250

		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @MFLastModified DATETIME
		DECLARE @Validation_ID int
	
		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFUpdateObjectChangeHistory';
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
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


		-------------------------------------------------------------
		-- INTIALIZE PROCESS BATCH
		-------------------------------------------------------------
		SET @ProcedureStep = 'Start Logging'

		SET @LogText = 'Processing ' + @ProcedureName

		EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
		  , @ProcessType = @ProcessType
		  , @LogType = N'Status'
		  , @LogText = @LogText
		  , @LogStatus = N'In Progress'
		  , @debug = @Debug


		EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
		  , @LogType = N'Debug'
		  , @LogText = @ProcessType
		  , @LogStatus = N'Started'
		  , @StartTime = @StartTime
		  , @MFTableName = @MFTableName
		  , @Validation_ID = @Validation_ID
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = @Update_ID
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DefaultDebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Setup ennvironment'
			
			IF @debug > 0
				Begin
					RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
				END


DECLARE @params NVARCHAR(MAX);
DECLARE @Process_ID INT = 5;
DECLARE @ColumnNames NVARCHAR(4000);
DECLARE @RC INT;
DECLARE @IsFullHistory BIT = 1;
DECLARE @NumberOFDays INT;
DECLARE @StartDate DATETIME; --= DATEADD(DAY,-1,GETDATE())
DECLARE @ID INT;
DECLARE @MFID INT;
DECLARE @ObjectType_ID INT;
DECLARE @Property_IDs NVARCHAR(MAX);

SELECT @ID = MIN(htu.id)
FROM  MFObjectChangeHistoryUpdatecontrol AS htu;
SET @params = N'@Process_id int';

IF ISNULL(@ID,0) > 0
Begin 

WHILE @ID IS NOT NULL
BEGIN
Set @DebugText = ''
Set @DefaultDebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Begin Loop'

IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END

	-------------------------------------------------------------
	-- Reset variables
	-------------------------------------------------------------
	SET @StartDate = null
    -------------------------------------------------------------
    -- Get table details
    -------------------------------------------------------------
 	Set @Procedurestep = 'Get Table variables'
    SELECT @MFTableName = htu.MFTableName,
           @ColumnNames = htu.ColumnNames
    FROM  MFObjectChangeHistoryUpdatecontrol AS htu
    WHERE htu.id = @ID;


    -------------------------------------------------------------
    -- Get property IDs
    -------------------------------------------------------------
    	Set @Procedurestep = 'Get Property IDs'
	SELECT @Property_IDs = STUFF(
                           (
                               SELECT ',' + CAST(mp.MFID AS VARCHAR(10))
                               FROM  MFObjectChangeHistoryUpdatecontrol AS htu
                                   CROSS APPLY dbo.fnMFParseDelimitedString(htu.ColumnNames, ',') AS fmpds
                                   INNER JOIN dbo.MFProperty mp
                                       ON fmpds.ListItem = mp.ColumnName
                               WHERE htu.id = htu2.id
                               FOR XML PATH('')
                           ),
                           1,
                           1,
                           ''
                                )
    FROM  MFObjectChangeHistoryUpdatecontrol AS htu2
    WHERE htu2.id = @ID;

	Set @DebugText = ''
	Set @DefaultDebugText = @DefaultDebugText + @DebugText

	
	IF @debug > 0
		BEGIN
        	
	   SELECT PropertyIDS = @Property_IDs;
			RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
		END

    -------------------------------------------------------------
    -- Update table
    -------------------------------------------------------------
	IF @WithClassTableUpdate = 1
	BEGIN
    
	Set @DebugText = ''
	Set @DefaultDebugText = @DefaultDebugText + @DebugText
	Set @Procedurestep = 'Update class Table included'
	
	IF @debug > 0
		Begin
			RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
		END
	
    DECLARE @MFLastUpdateDate SMALLDATETIME,
            @Update_IDOut INT,
            @ProcessBatch_ID1 INT;
    EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,                  -- nvarchar(128)
                                     @MFLastUpdateDate = @MFLastUpdateDate OUTPUT, -- smalldatetime
                                     @UpdateTypeID = 1,                            -- tinyint
                                     @Update_IDOut = @Update_IDOut OUTPUT,         -- int
                                     @ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT,  -- int
                                     @debug = 0;                                   -- tinyint


END

    -------------------------------------------------------------
    -- Get @startDate
    -------------------------------------------------------------
Set @Procedurestep = 'Get Start date '

    SELECT @MFID = mc.MFID,
           @ObjectType_ID = ot.MFID
    FROM dbo.MFClass AS mc
        INNER JOIN dbo.MFObjectType ot
            ON mc.MFObjectType_ID = ot.ID
    WHERE mc.TableName = @MFTableName;

    SELECT @StartDate = MAX(ISNULL(moch.LastModifiedUtc, '2000-01-01'))
    FROM dbo.MFObjectChangeHistory AS moch
    WHERE moch.ObjectType_ID = @ObjectType_ID
          AND moch.Class_ID = @MFID
          AND moch.Property_ID IN
              (
                  SELECT Item FROM dbo.fnMFSplitString(@Property_IDs, ',')
              );

    SELECT @IsFullHistory = CASE
                                WHEN @StartDate > '2000-01-01' THEN
                                    0
                                ELSE
                                    1
                            END;

Set @DebugText = CAST(@StartDate AS NVARCHAR(30))
Set @DefaultDebugText = @DefaultDebugText + @DebugText


IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END

-------------------------------------------------------------
-- Get count of class table records, if > 10 000 then batch history update
-------------------------------------------------------------
SET @params = N'@Count int output';

SET @SQL = 'SELECT @count = COUNT(*) FROM ' + QUOTENAME(@MFTableName) + N' t;'

    EXEC sys.sp_executesql @SQL, @params, @Count Output;

Set @DebugText = 'Total records: ' + CAST(@count AS nvarchar(10))
Set @DefaultDebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Updating change history '

IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END

    -------------------------------------------------------------
    -- Set objects to update in batch mode with batch size of ???
    -------------------------------------------------------------
SET @params = N'@Process_id int';


    SET @SQL = N'
UPDATE t
SET Process_ID = @Process_ID
FROM ' + QUOTENAME(@MFTableName) + N' t;';

    EXEC sys.sp_executesql @SQL, @params, @Process_ID;

    -------------------------------------------------------------
    -- Get history
    -------------------------------------------------------------

    SELECT FullHistory = @IsFullHistory,
           StartDate = @StartDate;

    EXEC dbo.spMFGetHistory @MFTableName = @MFTableName,                -- nvarchar(128)
                            @Process_id = @Process_ID,                  -- int
                            @ColumnNames = @ColumnNames,                -- nvarchar(4000)
                            @SearchString = NULL,                       -- nvarchar(4000)
                            @IsFullHistory = @IsFullHistory,            -- bit
                            @NumberOFDays = @NumberOFDays,              -- int
                            @StartDate = @StartDate,                    -- datetime
                            @Update_ID = @Update_ID OUTPUT,             -- int
                            @ProcessBatch_id = @ProcessBatch_id OUTPUT, -- int
                            @Debug = @Debug;                            -- int

    SELECT @ID =
    (
        SELECT MIN(htu.id) FROM MFObjectChangeHistoryUpdatecontrol AS htu WHERE htu.id > @ID
    );

END;

END  --end if ChangeHistoryUpdatecontrol exist

			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Message'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
			  , @LogText = @ProcessType
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0
			RETURN 1
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
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH

	END

GO
