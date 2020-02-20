PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFDeleteObjectList';
SET NOCOUNT ON;
GO
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFDeleteObjectList', -- nvarchar(100)
                                     @Object_Release = '4.1.5.43',          -- varchar(50)
                                     @UpdateFlag = 2;                       -- smallint

GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFDeleteObjectList' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFDeleteObjectList]
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFDeleteObjectList]
(
    @TableName NVARCHAR(100),
    @Process_id INT,
    @DeleteWithDestroy BIT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
)
AS


/*rST**************************************************************************

====================
spMFDeleteObjectList
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Process_id
    - Set process_id to 5 in the class table for the objects to be included in the delete operation
  @DeleteWithDestroy
    - Default = 0 (no)
	- Set to 1 to destroy the object in M-Files
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure to delete a series of objects

Prerequisites
=============

Set process_id of objects to be deleted in the class table prior to running the delete procedure.

Examples
========

.. code:: sql

    --check items before commencing
    SELECT id, objid, deleted, [Process_ID], *
    FROM   [MFCustomer]
    --set process_id object to be deleted 
    UPDATE [MFCustomer]
    SET	   [Process_ID] = 5
    WHERE  [ID] = 13

    --CHECK MFILES BEFORE DELETING TO SHOW DIFF

    --to delete
    EXEC [spMFDeleteObjectList] 'MFCustomer'
						  , 5
						  , 0

    --or

    EXEC [spMFDeleteObjectList] @tableName = 'MFCustomer'
						  , @Process_ID = 5
						  , @DeleteWithDestroy = 0

    -- to destroy

    EXEC [spMFDeleteObjectList] 'MFCustomer'
						  , 5
						  , 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2018-04-9   lc         Delete object from class table after deletion.
2018-6-26   LC         Improve return value
2018-8-2    LC         Suppress SQL error when nothing deleted
==========  =========  ========================================================

**rST*************************************************************************/

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @MFTableName AS NVARCHAR(128) = @TableName;
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Delete Objects');

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
DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFDeleteObjectList';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = 'Status';
DECLARE @LogText AS NVARCHAR(4000) = '';
DECLARE @LogStatus AS NVARCHAR(50) = 'Started';

DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
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
SET @ProcedureStep = 'Start Logging';

SET @LogText = 'Processing ' + @ProcedureName;

EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Status',
                                     @LogText = @LogText,
                                     @LogStatus = N'In Progress',
                                     @debug = @Debug;


EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
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
                                           @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
                                           @debug = 0;


BEGIN TRY
    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    SET @DebugText = '';
    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = '';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;


    DECLARE @Objid INT,
            @ObjectTypeID INT,
            @output NVARCHAR(100),
            @itemID INT,
            @Query NVARCHAR(MAX),
            @Params NVARCHAR(MAX);

    SET NOCOUNT ON;

    SELECT @ObjectTypeID = [mot].[MFID]
    FROM [dbo].[MFClass] AS [mc]
        INNER JOIN [dbo].[MFObjectType] AS [mot]
            ON [mot].[ID] = [mc].[MFObjectType_ID]
    WHERE [mc].[TableName] = @TableName;


    IF ISNULL(@ObjectTypeID, -1) = -1
        RAISERROR('ObjectID not found', 16, 1);

    IF @Debug = 1
        SELECT @ObjectTypeID AS [ObjectTypeid];

    CREATE TABLE [#ObjectList]
    (
        [Objid] INT
    );

    SET @Params = N'@Process_id INT';
    SET @Query = N'

		INSERT INTO #ObjectList
		        ( [Objid] )

SELECT  t.[ObjID] 
FROM ' + QUOTENAME(@TableName) + ' as t
WHERE  t.[Process_ID] = @Process_id
ORDER BY objid ASC;';

    EXEC [sys].[sp_executesql] @Stmt = @Query,
                               @Param = @Params,
                               @Process_id = @Process_id;

    -------------------------------------------------------------
    -- Count records to be deleted
    -------------------------------------------------------------
    SET @Params = N'@Count Int Output, @Process_id INT';
    SET @sql = N'SELECT @Count = COUNT(*) FROM ' + QUOTENAME(@TableName) + 'Where Process_ID = @Process_ID';

    EXEC [sys].[sp_executesql] @Stmt = @sql,
                               @Param = @Params,
                               @Count = @count OUTPUT,
                               @Process_id = @Process_id;


    SET @ProcedureStep = 'Total objects to delete';
    SET @LogTypeDetail = 'Status';
    SET @LogStatusDetail = 'In Progress';
    SET @LogTextDetail = 'Total objects: ' + CAST(@count AS NVARCHAR(10));
    SET @LogColumnName = '';
    SET @LogColumnValue = '';

    EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                                                                  @LogType = @LogTypeDetail,
                                                                  @LogText = @LogTextDetail,
                                                                  @LogStatus = @LogStatusDetail,
                                                                  @StartTime = @StartTime,
                                                                  @MFTableName = @MFTableName,
                                                                  @Validation_ID = @Validation_ID,
                                                                  @ColumnName = @LogColumnName,
                                                                  @ColumnValue = @LogColumnValue,
                                                                  @Update_ID = @Update_ID,
                                                                  @LogProcedureName = @ProcedureName,
                                                                  @LogProcedureStep = @ProcedureStep,
                                                                  @debug = @Debug;

    -------------------------------------------------------------
    -- Process deletions
    -------------------------------------------------------------
    IF @Debug = 1
        SELECT *
        FROM [#ObjectList] AS [ol];

    DECLARE @getObjidID CURSOR;
    SET @getObjidID = CURSOR FOR
    SELECT [ol].[Objid]
    FROM [#ObjectList] AS [ol]
    ORDER BY [ol].[Objid] ASC;

    OPEN @getObjidID;
    FETCH NEXT FROM @getObjidID
    INTO @Objid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ProcedureStep = 'SPMFDeleteObject';

        SET @return_value = NULL;
        EXEC @return_value = [dbo].[spMFDeleteObject] @ObjectTypeId = @ObjectTypeID,           -- int
                                                      @objectId = @Objid,                      -- int
                                                      @Output = @output OUTPUT,
                                                      @DeleteWithDestroy = @DeleteWithDestroy; -- nvarchar(2000)

													  SET @output = CASE WHEN @Output IS NULL THEN '0' ELSE @Output END
                                                      
        SET @DebugText = ' Delete Output %s ReturnValue %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @output, @return_value);
        END;

        -------------------------------------------------------------
        -- Record deletion
        -------------------------------------------------------------


        SET @ProcedureStep = 'Delete Record';
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'In Progress';
        SET @LogTextDetail = @output + ': ' + CAST(@Objid AS VARCHAR(10));
        SET @LogColumnName = '';
        SET @LogColumnValue = '';

        EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                                                      @LogType = @LogTypeDetail,
                                                      @LogText = @LogTextDetail,
                                                      @LogStatus = @LogStatusDetail,
                                                      @StartTime = @StartTime,
                                                      @MFTableName = @MFTableName,
                                                      @Validation_ID = @Validation_ID,
                                                      @ColumnName = @LogColumnName,
                                                      @ColumnValue = @LogColumnValue,
                                                      @Update_ID = @Update_ID,
                                                      @LogProcedureName = @ProcedureName,
                                                      @LogProcedureStep = @ProcedureStep,
                                                      @debug = @Debug;


        -------------------------------------------------------------
        -- Delete object from class table of deletion in MF
        -------------------------------------------------------------		
        IF @return_value = 1 
        BEGIN
            SET @Query = '
			DELETE FROM ' + QUOTENAME(@TableName) + 'WHERE Objid = ' + CAST(@Objid AS VARCHAR(10));
            EXEC (@Query);
        END;


        FETCH NEXT FROM @getObjidID
        INTO @Objid;
    END;
    CLOSE @getObjidID;
    DEALLOCATE @getObjidID;

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = 'End';
    SET @LogStatus = 'Completed';
    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   

    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID,
                                         @ProcessType = @ProcessType,
                                         @LogType = N'Message',
                                         @LogText = @LogText,
                                         @LogStatus = @LogStatus,
                                         @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                                               @LogType = N'Debug',
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
    SET @LogStatus = 'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO [dbo].[MFLog]
    (
        [SPName],
        [ErrorNumber],
        [ErrorMessage],
        [ErrorProcedure],
        [ErrorState],
        [ErrorSeverity],
        [ErrorLine],
        [ProcedureStep]
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
     @ProcedureStep);

    SET @ProcedureStep = 'Catch Error';
    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                         @ProcessType = @ProcessType,
                                         @LogType = N'Error',
                                         @LogText = @LogTextDetail,
                                         @LogStatus = @LogStatus,
                                         @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
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

    RETURN 0;
END CATCH;



GO
