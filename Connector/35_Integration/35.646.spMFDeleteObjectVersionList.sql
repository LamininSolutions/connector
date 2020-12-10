PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFDeleteObjectVersionList';

SET NOCOUNT ON;
GO

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFDeleteObjectVersionList', -- nvarchar(100)
    @Object_Release = '4.8.24.65',         -- varchar(50)
    @UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFDeleteObjectVersionList' --name of procedure
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
CREATE PROCEDURE dbo.spMFDeleteObjectVersionList
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFDeleteObjectVersionList
(
    @TableName NVARCHAR(100),
    @Process_id INT,
    @DeleteWithDestroy BIT = 1,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
)
AS

/*rST**************************************************************************

===========================
spMFDeleteObjectVersionList
===========================

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

Procedure to delete a series of object versions from a list

This procedure is mainly used to remove unwanted versions of objects, especially in scenarios where these versions where created by repetitive integrations.

Prerequisites
=============

Set process_id of objects to be deleted in the class table prior to running the delete procedure.

This procedure use the table MFObjectChangeHistory as source.  Explore and determine the versions to be deteled using the spmfGetHistory procedure and then to update the Process_id on MFObjectChangeHistory to 1 for the object versions to be included in the deletion.

Warning
=======

When the version to be deleted is set to the latest version the process will fail with error status 6.



Examples
========

.. code:: sql

    --check items before setting process_id
    SELECT mc.id, mch.id, mc.objid, mch.MFversion, mc.MFVersion, mch.[Process_ID], mch.property_id, mch.property_Value, mch.LastModifiedUTC
    FROM   [MFCustomer] mc
    inner join MFObjectChangeHistory mch
    on mc.objid = mch.objid and mc.class_id = mch.class_id
    order by lastModifiedUTC

    --set process_id object to be deleted 
    UPDATE MFObjectChangeHistory
    SET	   [Process_ID] = 5
    WHERE  [ID] = 13

    --CHECK MFILES BEFORE DELETING TO SHOW DIFF


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-10-06  LC         Add new procedure
==========  =========  ========================================================

**rST*************************************************************************/

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @MFTableName AS NVARCHAR(128) = @TableName;
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Delete Object versions');

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
DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFDeleteObjectVersionList';
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
DECLARE @UpdateMethod INT = 3;

SELECT TOP 1
    @Username  = Username,
    @VaultName = VaultName
FROM dbo.MFVaultSettings;

SELECT @VaultSettings = dbo.FnMFVaultSettings();

-------------------------------------------------------------
-- Check connection to vault
-------------------------------------------------------------
DECLARE @IsUpToDate INT;

SET @ProcedureStep = N'Connection test: ';

DECLARE @TestResult INT;

EXEC @return_value = dbo.spMFConnectionTest;

IF @return_value <> 1
BEGIN
    SET @DebugText = N'Connection failed ';
    SET @DebugText = @DefaultDebugText + @DebugText;

    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
END;

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
(@Username, @VaultName, @UpdateMethod);

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

    DECLARE @Objid     INT,
        @ObjectType_ID INT,
        @ClassID       INT,
        @output        NVARCHAR(1000),
        @itemID        INT,
        @Query         NVARCHAR(MAX),
        @Params        NVARCHAR(MAX);

    SET NOCOUNT ON;

    SELECT @ObjectType_ID = mot.MFID,
        @ClassID          = mc.MFID
    FROM dbo.MFClass                AS mc
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

		INSERT INTO #ObjectList
		        ( ObjectType_ID,
                [Objid],
                 MFVersion,
                Destroy)

SELECT distinct @objectType_ID, t.[ObjID], MFVersion, @DeleteWithDestroy
FROM MFObjectChangeHistory as t
WHERE  t.[Process_ID] = @Process_id
ORDER BY objid ASC
;

    -------------------------------------------------------------
    -- Count records to be deleted
    -------------------------------------------------------------
   
    SELECT @Count = COUNT(*) FROM dbo.MFObjectChangeHistory AS moch WHERE Process_ID = @Process_ID

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
            @ClassID          AS [Class/@Class_ID]
        FOR XML PATH(''), ROOT('ObjectType')
    );
    SET @XML =
    (
        SELECT moch.objectType_ID AS [ObjectDeleteItem/@ObjectType_ID],
            moch.Objid            [ObjectDeleteItem/@ObjId],
            moch.MFVersion        [ObjectDeleteItem/@MFVersion],
            moch.Destroy          AS [ObjectDeleteItem/@Destroy]
        FROM #ObjectList AS moch
        ORDER BY moch.objectType_ID,
            moch.Objid
        FOR XML PATH(''), ROOT('ObjectDeleteList')
    );
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
        SELECT @XML;

    SET @ProcedureStep = N'SPMFDeleteObject';
    SET @return_value = NULL;

    IF @count > 0
    BEGIN
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

        -------------------------------------------------------------
        -- Record deletion
        -------------------------------------------------------------
        SET @ProcedureStep = N'Update MFUpdateHistory with output';

        UPDATE dbo.MFUpdateHistory
        SET DeletedObjectVer = CAST(@XMLOut AS XML)
        WHERE Id = @Update_ID;

        IF @XMLOut IS NOT NULL
        BEGIN
            SET @ProcedureStep = N'Get Deleted Result';

            IF
            (
                SELECT OBJECT_ID('tempdb..#DeleteResult')
            ) IS NOT NULL
                DROP TABLE #DeleteResult;

            DECLARE @Idoc INT;

            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @XMLOut;

            SELECT objId,
           ObjVers as MFVersion,
                statusCode,
                Message
            INTO #DeletedResult
            FROM
                OPENXML(@Idoc, '/form/objVers', 1)
                WITH
                (
                    objId INT,
                    ObjVers INT,
                    statusCode INT,
                    Message NVARCHAR(100)
                );

            EXEC sys.sp_xml_removedocument @Idoc;

            SET @ProcedureStep = N'Set output message ';

            SELECT @output =
            (
                SELECT m.Message + ': ' + CAST(ISNULL(m.Delcount, 0) AS NVARCHAR(10)) + '; '
                FROM
                (
                    SELECT dr.Message,
                        COUNT(ISNULL(dr.statusCode, 0)) Delcount
                    FROM #DeletedResult AS dr
                    GROUP BY dr.Message
                ) m
            );

        --    EXEC sys.sp_executesql @sql;

            SET @DebugText = @output;
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                SELECT *
                FROM #DeletedResult;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @ProcedureStep = N'Update MFUpdateHistory result';

            -------------------------------------------------------------
            -- Summarise errors
            -------------------------------------------------------------
            DECLARE @Success INT,
                @DelErrors   INT,
                @NotExist    INT,
                @FailErrors  INT = 0;

            SELECT @Success = COUNT(*)
            FROM #DeletedResult AS dr
            WHERE dr.statusCode in (1,2,3);

            SELECT @NotExist = COUNT(*)
            FROM #DeletedResult AS dr
            WHERE dr.statusCode in (4,5)

            SELECT @DelErrors = COUNT(*)
            FROM #DeletedResult AS dr
            WHERE dr.statusCode =6 ;

            SET @DebugText
                = N' Not Exist: ' + CAST(ISNULL(@NotExist, 0) AS VARCHAR(10)) + N' Other errors: '
                  + CAST(ISNULL(@DelErrors, 0) AS VARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Summarise errors';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            UPDATE dbo.MFUpdateHistory
            SET UpdateStatus = CASE
                                   WHEN @DelErrors = 0 THEN
                                       'Completed'
                                   ELSE
                                       'Partial'
                               END
            WHERE Id = @Update_ID;

            -------------------------------------------------------------
            -- remove records that does not exist
            -------------------------------------------------------------
 /*           IF @NotExist > 0
            BEGIN
                SET @ProcedureStep = 'Removed records that does not exist :';
                SET 
            Begin tran
            Delete FROM MFObjectChangeHistory 
                      where objid in (Select dr.objid from 
             #DeletedResult dr
            WHERE dr.statusCode = 4)
            and MFVersion ;
            Commit tran


                SET @DebugText = CAST(ISNULL(@NotExist, 0) AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;
*/
            -------------------------------------------------------------
            -- Report failed errors
            -------------------------------------------------------------
            SET @Params = N'@FailErrors int output, @process_id int';

            SET @DebugText
                = N' Deleted count ' + CAST(@count AS NVARCHAR(100)) + N' Failed : ' + CAST(@FailErrors AS NVARCHAR(100));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @ProcedureStep = N'Failed processing';

            UPDATE dbo.MFUpdateHistory
            SET UpdateStatus = 'Failed'
            WHERE Id = @Update_ID;

            SET @LogTextDetail = N'Not all selected records for Deletion was processed, check class table';
            SET @LogTypeDetail = N'Status';
            SET @LogStatusDetail = N'Failed';
            SET @ProcedureStep = N'Delete Records';
            SET @LogTypeDetail = N'Status';
            SET @LogStatusDetail = N'Failed';
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

            SET @ProcedureStep = N'Update Table MFobjectChangeHistory with result';

            Begin tran
            UPDATE t 
SET t.Process_ID = CASE WHEN dr.statusCode IN( 1,2,3) THEN 0
ELSE 3 end
FROM #DeletedResult AS dr
INNER JOIN dbo.MFObjectChangeHistory  AS t
ON t.[objid] = dr.[objid] AND t.class_ID = @ClassID AND t.MFVersion = dr.MFVersion;
commit tran

            SET @DebugText = @LogStatusDetail;
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'End';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END; -- no records to process
    END; -- if @XMLout is null

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

    RETURN 0;
END CATCH;
GO