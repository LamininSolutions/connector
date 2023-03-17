PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFDeleteObjectList';

SET NOCOUNT ON;
GO

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFDeleteObjectList', -- nvarchar(100)
                                 @Object_Release = '4.10.30.75',         -- varchar(50)
                                 @UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFDeleteObjectList' --name of procedure
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
CREATE PROCEDURE dbo.spMFDeleteObjectList
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFDeleteObjectList
(
    @TableName NVARCHAR(100),
    @Process_id INT,
    @DeleteWithDestroy BIT = 0,
    @RetainDeletions BIT = 0,
    @Update_ID INT = null output ,
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
  @RetainDeletions
    - Default = 0 (no)
	- Set to 1 to retain the objected objects in the class table
  @Update_ID int (output)
    - Referencing ID of the record in the MFUpdateHistory table
  @ProcessBatch_ID (optional, output)
    - Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure to delete a series of objects

Prerequisites
=============

Set process_id of objects to be deleted in the class table prior to running the delete procedure.

Additional info
===============

The return value from M-Files for the deletions include a status code and result message.  The return values are logged in the MFUpdateHistory table.

The following status codes are used:

 - 1 = Success object deleted
 - 2 = Success object version destroyed
 - 3 = Success object destroyed
 - 4 = Failed to destroy
 - 5 = Failed to delete
 - 6 = Failed to remove version

Use the parameter RetainDeletions = 1 to retain the deletions in the class table. The timestamp for the deletion will show in the deleted column.

The updated version and deleted state of the deleted record is also shown in the MFAuditHistory table.

Warning
=======

Deletions showing in the class table will be removed when the update procedure is run withoput retain deletions.  The next time this procedure is run showing deletions, all the deletions will be shown again in the class table. 

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

    -- to retain deleted records in class table for use in a third party update procedure
   
    EXEC [spMFDeleteObjectList] @tableName = 'MFCustomer'
						  , @Process_ID = 5
						  , @DeleteWithDestroy = 0
                          , @RetainDeletions = 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-01-25  LC         Set default value for Update_ID parameter
2022-02-10  LC         Add update ID to record deletions in history
2021-12-20  LC         Pair connection test with accessing assembly
2021-06-08  LC         Remove object from class table if not found
2021-06-08  LC         Fix bug to remove item on deletion from class table
2021-06-08  LC         Fix entry in MFUpdateHistory on completion of deletion
2020-12-08  LC         Reset mfversion to -1 when deleting and destroying
2020-12-03  LC         Fix bug when object is destroyed
2020-10-06  LC         Modified to process delete operation in batch
2020-08-22  LC         deleted records in class table will be removed 
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
DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFDeleteObjectList';
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
DECLARE @XML XML;
DECLARE @XMLObjectVer XML;
DECLARE @DeletedColumn NVARCHAR(100);

-----------------------------------------------------
--GET LOGIN CREDENTIALS
-----------------------------------------------------
SET @ProcedureStep = N'Get Security Variables';

DECLARE @Username NVARCHAR(2000);
DECLARE @VaultName NVARCHAR(2000);
DECLARE @VaultSettings NVARCHAR(400);
DECLARE @UpdateMethod INT;

SELECT TOP 1
       @Username = Username,
       @VaultName = VaultName
FROM dbo.MFVaultSettings;

SELECT @VaultSettings = dbo.FnMFVaultSettings();

-------------------------------------------------------------
-- Check connection to vault
-------------------------------------------------------------
DECLARE @IsUpToDate INT;
DECLARE @TestResult INT;
SET @ProcedureStep = N'Connection test: ';

-------------------------------------------------------------
-- Get deleted column name
-------------------------------------------------------------
SELECT @DeletedColumn = ColumnName
FROM dbo.MFProperty
WHERE MFID = 27;

-------------------------------------------------------------
--	Create Update_id for process start 
-------------------------------------------------------------
SET @ProcedureStep = N'set Update_ID';
SET @StartTime = GETUTCDATE();

INSERT INTO dbo.MFUpdateHistory
(
    Username,
    VaultName,
    UpdateMethod
)
VALUES
(@Username, @VaultName, 12);

SELECT @Update_ID = @@Identity;

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
                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
                                       @debug = 0;

BEGIN TRY
    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    SET @DebugText = N'';
    SET @DefaultDebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    DECLARE @Objid INT,
            @ObjectType_ID INT,
            @ClassID INT,
            @output NVARCHAR(1000),
            @itemID INT,
            @Query NVARCHAR(MAX),
            @Params NVARCHAR(MAX);

    SET NOCOUNT ON;

    SELECT @ObjectType_ID = mot.MFID,
           @ClassID = mc.MFID
    FROM dbo.MFClass AS mc
        INNER JOIN dbo.MFObjectType AS mot
            ON mot.ID = mc.MFObjectType_ID
    WHERE mc.TableName = @TableName;

    IF ISNULL(@ObjectType_ID, -1) = -1
        RAISERROR('ObjectID not found', 16, 1);

    IF @Debug = 1
        SELECT @ObjectType_ID AS ObjectTypeid;

    CREATE TABLE #ObjectList
    (
        objectType_ID INT,
        Objid INT,
        MFVersion INT,
        Destroy BIT
    );

    SET @Params = N'@ObjectType_ID int, @Process_id INT, @DeleteWithDestroy Bit';
    SET @Query
        = N'

		INSERT INTO #ObjectList
		        ( ObjectType_ID,
                [Objid],
                MFversion,
                Destroy)

SELECT  @objectType_ID, t.[ObjID], -1, @DeleteWithDestroy
FROM ' + QUOTENAME(@TableName) + N' as t
WHERE  t.[Process_ID] = @Process_id
ORDER BY objid ASC;';

    EXEC sys.sp_executesql @Stmt = @Query,
                           @Param = @Params,
                           @Process_id = @Process_id,
                           @DeleteWithDestroy = @DeleteWithDestroy,
                           @ObjectType_ID = @ObjectType_ID;

    -------------------------------------------------------------
    -- Count records to be deleted
    -------------------------------------------------------------
    SET @Params = N'@Count Int Output, @Process_id INT';
    SET @sql = N'SELECT @Count = COUNT(*) FROM ' + QUOTENAME(@TableName) + N'Where Process_ID = @Process_ID';

    EXEC sys.sp_executesql @Stmt = @sql,
                           @Param = @Params,
                           @Count = @count OUTPUT,
                           @Process_id = @Process_id;

    SET @ProcedureStep = N'Total objects to delete';
    SET @LogTypeDetail = N'Status';
    SET @LogStatusDetail = N' In Progress';
    SET @LogTextDetail = N'Total objects: ' + CAST(@count AS NVARCHAR(10));
    SET @LogColumnName = N'';
    SET @LogColumnValue = N'';

    EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
    -- Prepare XML
    -------------------------------------------------------------
    SET @XMLObjectVer =
    (
        SELECT @ObjectType_ID AS [ObjectType/@ObjectType_ID],
               @ClassID AS [Class/@Class_ID]
        FOR XML PATH(''), ROOT('ObjectType')
    );
    SET @XML =
    (
        SELECT moch.objectType_ID AS [ObjectDeleteItem/@ObjectType_ID],
               moch.Objid [ObjectDeleteItem/@ObjId],
               moch.MFVersion [ObjectDeleteItem/@MFVersion],
               moch.Destroy AS [ObjectDeleteItem/@Destroy]
        FROM #ObjectList AS moch
        ORDER BY moch.objectType_ID,
                 moch.Objid
        FOR XML PATH(''), ROOT('ObjectDeleteList')
    );

    -------------------------------------------------------------
    -- update MFupdateHistory
    -------------------------------------------------------------
    SET @ProcedureStep = N'Update MFUpdateHistory';


    UPDATE dbo.MFUpdateHistory
    SET ObjectDetails = @XMLObjectVer,
        ObjectVerDetails = @XML
    WHERE Id = @Update_ID;

    -------------------------------------------------------------
    -- Process deletions
    -------------------------------------------------------------
    DECLARE @XMLInput NVARCHAR(MAX);
    DECLARE @XMLOut NVARCHAR(MAX);

    SELECT @XMLInput = CAST(@XML AS NVARCHAR(MAX));

    SELECT @VaultSettings = dbo.FnMFVaultSettings();

    IF @Debug > 0
        SELECT @XML AS '@XML';

    SET @ProcedureStep = N'Check connection';
    SET @return_value = NULL;

    EXEC @return_value = dbo.spMFConnectionTest;

    IF @return_value <> 1
    BEGIN
        SET @DebugText = N'Connection failed ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;
    SET @StartTime = GETUTCDATE();
    IF @count > 0
       AND @return_value = 1
    BEGIN
    SET @ProcedureStep = N'Wrapper ';
        EXEC @return_value = dbo.spMFDeleteObjectListInternal @VaultSettings = @VaultSettings,
                                                              @XML = @XMLInput, -- int                                                   
                                                              @XMLOut = @XMLOut OUTPUT;


        SET @DebugText = N' ReturnValue %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT CAST(@XMLOut AS XML) XMLOut;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value);
        END;


        SET @ProcedureStep = N'Wrapper turn around';
        SET @LogTypeDetail = N'Status';
        SET @LogStatusDetail = N' In Progress';
        SET @LogTextDetail = N'Wrapper updated';
        SET @LogColumnName = N'';
        SET @LogColumnValue = N'';

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
        -- Record deletion
        -------------------------------------------------------------
        SET @ProcedureStep = N'Update MFUpdateHistory with output';


        IF @XMLOut IS NOT NULL
        BEGIN
            SET @ProcedureStep = N'Get Deleted Result';

            IF
            (
                SELECT OBJECT_ID('tempdb..#DeletedResult')
            ) IS NOT NULL
                DROP TABLE #DeletedResult;

            CREATE TABLE #DeletedResult
            (
                Objid INT,
                MFVersion INT,
                StatusCode INT,
                Message NVARCHAR(MAX)
            );

            DECLARE @Idoc INT;

            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @XMLOut;

            INSERT INTO #DeletedResult
            (
                Objid,
                MFVersion,
                StatusCode,
                Message
            )
            SELECT objId,
            MFVersion,
                   StatusCode,
                   Message
            FROM
                OPENXML(@Idoc, '/form/objVers', 1)
                WITH
                (
                    objId INT './@objId',
                    MFVersion INT './@MFVersion',
                    StatusCode INT './@statusCode',
                    Message NVARCHAR(MAX) './@Message'
                );
            SET @rowcount = @@ROWCOUNT;

            EXEC sys.sp_xml_removedocument @Idoc;

            IF @Debug > 0
            BEGIN
                SELECT '#DeletedResult',
                       *
                FROM #DeletedResult;

            SET @ProcedureStep = N'Set output message ';


            SELECT @output =
            (
                SELECT  'Deleted object count : ' + CAST(ISNULL(m.Delcount, 0) AS NVARCHAR(10)) + '; '
                FROM
                (
                    SELECT 
                           COUNT(ISNULL(dr.StatusCode, 0)) Delcount
                    FROM #DeletedResult AS dr                  
                ) m
            );

            IF @Debug > 0
                SELECT @output AS output;

            --       EXEC sys.sp_executesql @sql;
            SET @DebugText = N'Return count %i';
            SET @DebugText = @DefaultDebugText + @DebugText

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
            END;

            SET @ProcedureStep = N'Update MFUpdateHistory result';

            -------------------------------------------------------------
            -- Summarise errors
            -------------------------------------------------------------
            DECLARE @Success INT = 0,
                    @DelErrors INT = 0;


            SELECT @Success = COUNT(*)
            FROM #DeletedResult AS dr
            WHERE dr.StatusCode IN ( 1, 2, 3 );


            SELECT @DelErrors = COUNT(*)
            FROM #DeletedResult AS dr
            WHERE dr.StatusCode IN ( 4, 5, 6 );

            SET @DebugText
                = N' Success: ' + CAST(ISNULL(@Success, 0) AS VARCHAR(10)) + N'Errors: '
                  + CAST(ISNULL(@DelErrors, 0) AS VARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Summary ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @DelErrors = CASE
                                    WHEN @XMLOut IS NULL THEN
                                        1
                                    ELSE
                                        @DelErrors
                                END;

            IF @DelErrors > 0
            BEGIN
                DECLARE @ErrorList NVARCHAR(MAX);

                SELECT @ErrorList = 
                (
                    SELECT dr.Objid AS [Objver/@ObjId],
                            dr.MFVersion AS [Objver/@MFVersion],
                           dr.StatusCode AS [Objver/@StatusCode],
                           dr.Message AS [Objver/@Message]
                    FROM #DeletedResult AS dr
                    WHERE dr.StatusCode IN ( 4, 5, 6 )
                    FOR XML PATH(''), ROOT('form')
                )
                   
                   IF @Debug > 0
                   SELECT @Errorlist AS '@Errorlist';

            END;
            UPDATE dbo.MFUpdateHistory
            SET DeletedObjectVer = CAST(@XMLOut AS XML),
                MFError = @ErrorList,
                UpdateStatus = CASE
                                   WHEN @DelErrors = 0 THEN
                                       'Completed'                                   
                                   ELSE
                                       'Partial Failed'
                               END
            WHERE Id = @Update_ID;


            -------------------------------------------------------------
            -- Update Class table
            -------------------------------------------------------------

            SET @ProcedureStep = N'Reset records in class table';
            SET @sql
                = N'
            Begin tran
            Update t
            Set process_id = 0
            FROM ' + QUOTENAME(@MFTableName)
                  + N' t
                     inner join #DeletedResult dr
                     on dr.objid = t.objid;
            Commit tran';

            EXEC (@sql);

            SET @ProcedureStep = N'Update class table for deleted records';

            DECLARE @Update_IDOut INT;
            DECLARE @objids NVARCHAR(MAX);

            SELECT @objids = STUFF(
                             (
                                 SELECT ',' + CAST(dr.Objid AS NVARCHAR(10))
                                 FROM #DeletedResult AS dr
                                 FOR XML PATH('')
                             ),
                             1,
                             1,
                             ''
                                  );

            EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                     @UpdateMethod = 1,
                                     @ObjIDs = @objids,
                                     @Update_IDOut = @Update_IDOut OUTPUT,
                                     @ProcessBatch_ID = @ProcessBatch_ID,
                                     @RetainDeletions = @RetainDeletions,
                                     @Debug = 0;


            ---------------------------------------------------------------
            ---- remove records that does not exist
            ---------------------------------------------------------------

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END        -- end @xmlout not null
       

        SET @LogTextDetail
            = N' Deleted count ' + CAST(@count AS NVARCHAR(100)) + N' Failed : ' + CAST(@DelErrors AS NVARCHAR(100));
        SET @LogTypeDetail = N'Status';
        SET @ProcedureStep = N'Delete Records';
        SET @LogStatusDetail = N'Completed';
        SET @LogColumnName = N'';
        SET @LogColumnValue = N'';

        EXECUTE dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

    END; -- if @XMLout is null

     ELSE 
        BEGIN
        
        SET @errorlist =  '<form>message="No objects marked for deletion"</form>'                                      

          UPDATE dbo.MFUpdateHistory
            SET MFError = @ErrorList,
                UpdateStatus = 'Failed'                              
            WHERE Id = @Update_ID;
        END

    SET @ProcedureStep = N'Delete Records';
    SET @LogTypeDetail = N'Status';
    SET @LogStatusDetail = N'Completed';
    SET @LogTextDetail = @output + N': ' + CAST(@Objid AS VARCHAR(10));
    SET @LogColumnName = N'';
    SET @LogColumnValue = N'';

    EXECUTE dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogStatus = N'Completed';

    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Message',
                                     @LogText = @LogText,
                                     @LogStatus = @LogStatus,
                                     @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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