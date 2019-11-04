PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateAllncludedInAppTables]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUpdateAllncludedInAppTables', -- nvarchar(100)
                                 @Object_Release = '4.4.13.54',                    -- varchar(50)
                                 @UpdateFlag = 2;                                  -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateAllncludedInAppTables' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateAllncludedInAppTables
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateAllncludedInAppTables
(
    @UpdateMethod INT = 1,
    @RemoveDeleted INT = 1, --1 = Will remove all the deleted objects when this process is run
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

===============================
spMFUpdateAllncludedInAppTables
===============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @UpdateMethod int
    - Default = 1
  @RemoveDeleted int
    - Default = 1
    - Remove all the deleted objects when this process is run
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

The purpose of this procedure is to allow for daily processing of all the class table tables with includedinapp = 1.

Updating the Object Change History, based on the entries in MFObjectChangeHistoryControl is also included in this routine.

Examples
========

.. code:: sql

    DECLARE @Return int
    EXEC @Return = spMFUpdateAllncludedInAppTables 2, 0
    SELECT @return

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-11-04  LC         Include spMFUpdateObjectChangeHistory in this routine
2019-08-30  JC         Added documentation
2018-11-18  LC         Remove duplicate Audit process
2017-08-28  LC         Convert proc to include logging and process batch control
2017-06-09  LC         Change to use spmfupdateMfilestoSQL method
2017-06-09  LC         Set default of updatemethod to 1
2016-09-09  LC         Add return value
2015-07-14  DEV2       Debug mode added
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @MFTableName AS NVARCHAR(128);
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = N'Update All Tables';

-------------------------------------------------------------
-- CONSTATNS: MFSQL Global 
-------------------------------------------------------------
DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
DECLARE @Process_ID_1_Update TINYINT = 1;
DECLARE @Process_ID_6_ObjIDs TINYINT = 6; --marks records for refresh from M-Files by objID vs. in bulk
DECLARE @Process_ID_9_BatchUpdate TINYINT = 9; --marks records previously set as 1 to 9 and update in batches of 250
DECLARE @Process_ID_Delete_ObjIDs INT = -1; --marks records for deletion
DECLARE @Process_ID_2_SyncError TINYINT = 2;
DECLARE @ProcessBatchSize INT = 250;

-------------------------------------------------------------
-- VARIABLES: MFSQL Processing
-------------------------------------------------------------
DECLARE @Update_ID INT;
DECLARE @MFLastModified DATETIME;
DECLARE @Validation_ID INT;

-------------------------------------------------------------
-- VARIABLES: T-SQL Processing
-------------------------------------------------------------
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT = 0;
DECLARE @error AS INT = 0;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFUpdateAllncludedInAppTables';
DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = N'Status';
DECLARE @LogText AS NVARCHAR(4000) = N'';
DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
DECLARE @count INT = 0;
DECLARE @Now AS DATETIME = GETDATE();
DECLARE @StartTime AS DATETIME = GETUTCDATE();
DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

-------------------------------------------------------------
-- VARIABLES: DYNAMIC SQL
-------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @sqlParam NVARCHAR(MAX) = N'';

-------------------------------------------------------------
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = N'Start Logging';
SET @LogText = N'Processing ' + @ProcedureName;

EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                 @ProcessType = @ProcessType,
                                 @LogType = N'Status',
                                 @LogText = @LogText,
                                 @LogStatus = N'In Progress',
                                 @debug = @Debug;

EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                       @LogType = N'Debug',
                                       @LogText = @ProcessType,
                                       @LogStatus = N'Started',
                                       @StartTime = @StartTime,
                                       @MFTableName = @MFTableName,
                                       @Validation_ID = @Validation_ID,
                                       @ColumnName = NULL,
                                       @ColumnValue = NULL,
                                       @Update_ID = @Update_ID,
                                       @LogProcedureName = @ProcedureName,
                                       @LogProcedureStep = @ProcedureStep,
                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                                       @debug = 0;

BEGIN TRY

    -------------------------------------------------------------
    -- update class tables
    -------------------------------------------------------------
    ----------------------------------------
    --DECLARE VARIABLES
    ----------------------------------------
    DECLARE @result INT,
            @ClassName NVARCHAR(100),
            @TableLastModified DATETIME,
            @id INT,
            @schema NVARCHAR(5) = N'dbo',
            @Param NVARCHAR(MAX);

    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

    SELECT @ProcedureStep = N'Create Table list and update lastupdate date';

    IF EXISTS
    (
        SELECT name
        FROM tempdb.sys.objects
        WHERE object_id = OBJECT_ID('tempdb..#Tablelist')
    )
        DROP TABLE #TableList;

    CREATE TABLE #TableList
    (
        ID INT,
        Name VARCHAR(100),
        TableName VARCHAR(100),
        TableLastModified DATETIME
    );

    INSERT INTO #TableList
    (
        ID,
        Name,
        TableName,
        TableLastModified
    )
    SELECT mc.ID,
           mc.Name,
           mc.TableName,
           NULL
    FROM dbo.MFClass AS mc
        INNER JOIN
        (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES) AS t
            ON t.TABLE_NAME = mc.TableName
    WHERE mc.IncludeInApp IN ( 1, 2 );

    DECLARE @Row INT;

    SELECT @Row = MIN(tl.ID)
    FROM #TableList AS tl;

    -------------------------------------------------------------
    -- Begin loop
    -------------------------------------------------------------
    WHILE @Row IS NOT NULL
    BEGIN
        SELECT @id = @Row;

        SELECT @MFTableName = TableName
        FROM #TableList
        WHERE ID = @id;

        DECLARE @MFLastUpdateDate SMALLDATETIME,
                @Update_IDOut INT;

        EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,                  -- nvarchar(128)
                                         @MFLastUpdateDate = @MFLastUpdateDate OUTPUT, -- smalldatetime
                                         @UpdateTypeID = 1,                            -- tinyint
                                         @Update_IDOut = @Update_IDOut OUTPUT,         -- int
                                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,   -- int
                                         @debug = 0;                                   -- tinyint

        UPDATE #TableList
        SET TableLastModified = @MFLastUpdateDate
        WHERE ID = @id;

        SELECT @Row =
        (
            SELECT MIN(tl.ID) AS id FROM #TableList AS tl WHERE tl.ID > @Row
        );
    END;

    IF @Debug > 0
    BEGIN
        RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

        SELECT *
        FROM #TableList;
    END;


    -------------------------------------------------------------
    -- Update object change history
    -------------------------------------------------------------
    IF
    (
        SELECT COUNT(*) FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
    ) > 0
    BEGIN

        EXEC dbo.spMFUpdateObjectChangeHistory @WithClassTableUpdate = 0,
                                               @ProcessBatch_ID = 0, -- int
                                               @Debug = 0;           -- smallint

    END;
    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogType = N'debug';
    SET @LogText = N'Updated all included in App tables:Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
    SET @LogStatus = N'Completed';

    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                     @ProcessType = @ProcessType,
                                     @LogType = @LogType,
                                     @LogText = @LogText,
                                     @LogStatus = @LogStatus,
                                     @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                           @LogType = @LogType,
                                           @LogText = @ProcessType,
                                           @LogStatus = @LogStatus,
                                           @StartTime = @StartTime,
                                           @MFTableName = @MFTableName,
                                           @Validation_ID = @Validation_ID,
                                           @ColumnName = NULL,
                                           @ColumnValue = NULL,
                                           @Update_ID = @Update_ID,
                                           @LogProcedureName = @ProcedureName,
                                           @LogProcedureStep = @ProcedureStep,
                                           @debug = 0;

    RETURN 1;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();
    SET @LogStatus = N'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO dbo.MFLog
    (
        SPName,
        ErrorNumber,
        ErrorMessage,
        ErrorProcedure,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ProcedureStep
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
     @ProcedureStep);

    SET @ProcedureStep = N'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Error',
                                     @LogText = @LogTextDetail,
                                     @LogStatus = @LogStatus,
                                     @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                           @LogType = N'Error',
                                           @LogText = @LogTextDetail,
                                           @LogStatus = @LogStatus,
                                           @StartTime = @StartTime,
                                           @MFTableName = @MFTableName,
                                           @Validation_ID = @Validation_ID,
                                           @ColumnName = NULL,
                                           @ColumnValue = NULL,
                                           @Update_ID = @Update_ID,
                                           @LogProcedureName = @ProcedureName,
                                           @LogProcedureStep = @ProcedureStep,
                                           @debug = 0;

    RETURN -1;
END CATCH;
GO