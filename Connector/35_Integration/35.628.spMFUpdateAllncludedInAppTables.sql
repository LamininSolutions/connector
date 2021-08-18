PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateAllncludedInAppTables]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateAllncludedInAppTables', -- nvarchar(100)
    @Object_Release = '4.9.27.70',                    -- varchar(250)
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
    @IsIncremental INT = 1, -- set to 0 to initialise or rebuild all the tables
    @SendClassErrorReport INT = 0,
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
  @IsIncremental int
    - Default = 1 (yes)
	- Set to 0 to perform a rebuild or initialisation all included in app tables
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

This procedure can be used for initializing all the tables or to update only the differential. 

Warning
=======

Setting @IsIncremental to 0 and including a large number of tables with a large number of objects could take a considerable time to finish. 

The procedure will automatically default to using 200 000 records as default for each new class table.  

Examples
========

.. code:: sql

    --example for incremental updates (to be included in agent for daily update)
    DECLARE @ProcessBatch_ID INT;
    EXEC dbo.spMFUpdateAllncludedInAppTables @UpdateMethod = 1, 
                                         @RemoveDeleted = 1,  
                                         @IsIncremental = 1,    
                                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, 
                                         @Debug = 0
                                         
.. code:: sql

    --example for initating all table - use only when small class tables are involved
    DECLARE @ProcessBatch_ID INT;
    EXEC dbo.spMFUpdateAllncludedInAppTables @UpdateMethod = 1, 
                                         @RemoveDeleted = 1,  
                                         @IsIncremental = 0,    
                                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, 
                                         @Debug = 0


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-08-04  LC         add parameter to allow suppress of control report, default 0
2021-04-01  LC         add control report for updates
2021-03-17  LC         remove step to reset audit history to null if full 
2021-03-17  LC         set history update flag to not update if control is empty
2020-06-24  LC         Add additional debugging
2020-06-06  LC         Add exit if unable to connect to vault
2020-03-06  LC         Include spMFUpdateChangeHistory through spMFUpdateMfilestoSQL
2020-03-06  LC         Exclude MFUserMessages
2019-12-10  LC         Functionality extended to intialise all tables
2019-11-04  LC         Include spMFUpdateObjectChangeHistory in this routine
2019-08-30  JC         Added documentation
2018-11-18  LC         Remove duplicat process
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
DECLARE @ProcessType AS NVARCHAR(250);

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
DECLARE @LogType AS NVARCHAR(250) = N'Status';
DECLARE @LogText AS NVARCHAR(4000) = N'';
DECLARE @LogStatus AS NVARCHAR(250) = N'Started';
DECLARE @LogTypeDetail AS NVARCHAR(250) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(250) = N'In Progress';
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
    DECLARE @result        INT,
        @ClassName         NVARCHAR(100),
        @TableLastModified DATETIME,
        @id                INT,
        @schema            NVARCHAR(5)  = N'dbo',
        @Param             NVARCHAR(MAX),
        @UpdateTypeID      INT          = 1,
        @MFID              INT;

    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

    SELECT @ProcedureStep = N'Test Vault connection';

    DECLARE @VaultSettings NVARCHAR(400),
        @TestResult        INT;

    SET @VaultSettings = dbo.FnMFVaultSettings();

    EXEC @return_value = dbo.spMFConnectionTest 

    --   SELECT @TestResult
    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s Test Result %s', 10, 1, @ProcedureName, @ProcedureStep, @TestResult);

    IF @return_value = 1
    BEGIN
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
            MFID INT,
            TableLastModified DATETIME,
            HistoryUpdate int
        );

        INSERT INTO #TableList
        (
            ID,
            Name,
            TableName,
            MFID,
            TableLastModified,
            HistoryUpdate
        )
        SELECT mc.ID,
            mc.Name,
            mc.TableName,
            mc.MFID,
            NULL,
            CASE
                WHEN h.MFTableName IS NOT NULL THEN
                    1
                ELSE
                    0
            END
        FROM dbo.MFClass                                       AS mc
            INNER JOIN
            (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES) AS t
                ON t.TABLE_NAME = mc.TableName
            LEFT JOIN
            (
                SELECT mochuc.MFTableName
                FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
                GROUP BY mochuc.MFTableName
            )                                                  h
                ON h.MFTableName = mc.TableName
        WHERE mc.IncludeInApp IN ( 1, 2 );

        DECLARE @Row INT;

        SELECT @Row = MIN(tl.ID)
        FROM #TableList AS tl;

        IF @IsIncremental = 0
            SET @UpdateTypeID = 0;

        -------------------------------------------------------------
        -- Begin loop
        -------------------------------------------------------------
        SELECT @ProcedureStep = N'Loop to update tables';

        DECLARE @HistoryUpdate int
        
        WHILE @Row IS NOT NULL
        BEGIN
            SELECT @id = @Row;

                SELECT @MFTableName = TableName,
                    @MFID           = MFID,
                    @historyUpdate = HistoryUpdate
                FROM #TableList
                WHERE ID = @id;
        
            IF @IsIncremental = 0
            BEGIN
                SELECT @ProcedureStep = N'Delete audit history';

                --DELETE FROM dbo.MFAuditHistory
                --WHERE Class = @MFID;
            END;

            DECLARE @MFLastUpdateDate SMALLDATETIME,
                @Update_IDOut         INT;

            SELECT @ProcedureStep = N'Update with spMFupdateMfilestoMFSQL';

            SELECT @StartTime = GETUTCDATE();

            IF ISNULL(@MFTableName,'') <> '' 
            BEGIN
            
            EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,
                @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,
                @UpdateTypeID = @UpdateTypeID,
                @WithObjectHistory = @HistoryUpdate,
                @Update_IDOut = @Update_IDOut OUTPUT,
                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                @debug = 0;

            UPDATE #TableList
            SET TableLastModified = @MFLastUpdateDate
            WHERE ID = @id;
            END

            IF @Debug > 0
            BEGIN
                RAISERROR('Proc: %s Step: %s table %s', 10, 1, @ProcedureName, @ProcedureStep, @MFTableName);

                SELECT *
                FROM #TableList
                WHERE ID = @id;
            END;

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = N'Debug',
                @LogText = @ProcessType,
                @LogStatus = N'Table updated',
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

            SELECT @Row =
            (
                SELECT MIN(tl.ID) AS id
                FROM #TableList AS tl
                WHERE tl.ID > @Row
                      AND tl.TableName <> 'MFUserMessages'
            );
        END;

        -------------------------------------------------------------
        -- Send error report
        -------------------------------------------------------------
     IF @SendClassErrorReport = 1
     Begin
     EXEC dbo.spMFClassTableStats 
    @IncludeOutput = 1,
    @SendReport = 1,
    @Debug = 0
    end
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
    END; --end connection test  
    ELSE
    BEGIN
        RETURN -1;

        RAISERROR(
                     'Proc: %s Step: %s Unable to connect to vault %i ',
                     16,
                     1,
                     @ProcedureName,
                     @ProcedureStep,
                     @TestResult
                 );
    END;
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