PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUnDeleteObject]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUnDeleteObject', -- nvarchar(100)
                                 @Object_Release = '4.9.29.73',       -- varchar(50)
                                 @UpdateFlag = 2;                     -- smallint
GO
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUnDeleteObject' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    DROP PROC dbo.spMFUnDeleteObject;
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

SET NOEXEC OFF;
GO
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUnDeleteObject
AS
SELECT 'created, but not implemented yet.'; --just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUnDeleteObject
    @MFTableName AS NVARCHAR(128),
    @ObjId int,
    @RetainDeletions BIT = 0,
    @Output NVARCHAR(2000) OUTPUT,
    @Update_ID INT OUTPUT,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
AS
/*rST**************************************************************************

==================
spMFUnDeleteObject
==================

Return
  - 1 = Success object undeleted
  - 2 =	Failed to undelete, object not found
  - -1 = SQL Error

Parameters
  @MFtableName nvarchar(128)
    Class table name
  @ObjID int
    Objid to undelete
  @RetainDeletions bit
    Default = 0 (will not retain deletions in the class table)
    Set to 1 if the deleted records are maintained in the class table
  @Output nvarchar(2000) (output)
    Output message
  @Update_ID Output
    - ID of the record in the MFUpdateHistory table
  @ProcessBatch_ID Output
    -ID of the record in the MFProcessBatch table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

An object can be undeleted from M-Files using the ClassTable by using the spMFUnDeleteObject procedure. Is it optional to undelete the object in M-Files.


Warnings
========

To undelete an object the object must be deleted.

Examples
========

.. code:: sql

      DECLARE @Output NVARCHAR(2000),
      @ProcessBatch_ID INT;
      EXEC dbo.spMFUnDeleteObject @ObjectTypeId = 0,
                            @objectId = 139
                            @Output = @Output OUTPUT,
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                            @Debug = 1

                            SELECT @output

     SELECT @rt, @update_ID, @ProcessBatch_ID1
     SELECT * FROM dbo.MFUpdateHistory AS muh WHERE id = @update_ID
     SELECT * FROM dbo.MFProcessBatch AS mpb WHERE mpb.ProcessBatch_ID = @ProcessBatch_ID1
     SELECT * FROM dbo.MFProcessBatchDetail AS mpb WHERE mpb.ProcessBatch_ID = @ProcessBatch_ID1


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-02-09  LC         Create new  procedure and assembly method
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @ObjectTypeId INT;
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Undelete Object');

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
    DECLARE @Update_IDOut INT;
    DECLARE @MFLastModified DATETIME;
    DECLARE @MFLastUpdateDate DATETIME;
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
    DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFUnDeleteObject';
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

    DECLARE @ObjectType NVARCHAR(100);

    SELECT @ObjectType = mot.Name,
           @ObjectTypeId = mot.MFID
    FROM dbo.MFObjectType AS mot
        INNER JOIN dbo.MFClass mc
            ON mc.MFObjectType_ID = mot.ID
    WHERE mc.TableName = @MFTableName;


    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Status',
                                     @LogText = @LogText,
                                     @LogStatus = N'In Progress',
                                     @debug = @Debug;

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                           @LogType = N'Debug',
                                           @LogText = @LogText,
                                           @LogStatus = N'Started',
                                           @StartTime = @StartTime,
                                           @MFTableName = NULL,
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
        SET @DebugText = N'Object Type %i; Objid  %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectTypeId, @Objid);
        END;

        -----------------------------------------------------
        -- LOCAL VARIABLE DECLARARTION
        -----------------------------------------------------
        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @Idoc INT;
        DECLARE @StatusCode INT;
        DECLARE @Message NVARCHAR(max);

        -----------------------------------------------------
        -- SELECT CREDENTIAL DETAILS
        -----------------------------------------------------
        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        ------------------------------------------------------
        --Validating Module for calling CLR Procedure
        ------------------------------------------------------
        EXEC dbo.spMFCheckLicenseStatus 'spMFUnDeleteObject',
                                        'spMFUnDeleteObject',
                                        'UnDeleting object';


        -------------------------------------------------------------
        --	Create Update_id for process start 
        -------------------------------------------------------------
        SET @ProcedureStep = N'set Update_ID';
        SET @StartTime = GETUTCDATE();

        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
               @Username = Username,
               @VaultName = VaultName
        FROM dbo.MFVaultSettings;

        INSERT INTO dbo.MFUpdateHistory
        (
            Username,
            VaultName,
            UpdateMethod
        )
        VALUES
        (@Username, @VaultName, 13);

        SELECT @Update_ID = @@Identity;
        SELECT @Update_IDOut = @Update_ID;
        -----------------------------------------------------
        -- CALLS PROCEDURE spMFDeleteObjectInternal
        -----------------------------------------------------
        -- nvarchar(2000)
        SET @ProcedureStep = N'Wrapper result';


        DECLARE @XML XML;
        DECLARE @XMLinput NVARCHAR(MAX);
        DECLARE @XMLout NVARCHAR(MAX);

        SET @XML =
        (
            SELECT @ObjectTypeId AS [ObjectUnDeleteItem/@ObjectType_ID],
                   @ObjId [ObjectUnDeleteItem/@ObjId]
            FOR XML PATH(''), ROOT('ObjectUnDeleteList')
        );

        IF @Debug > 0
            SELECT @XML;

        SET @XMLinput = CAST(@XML AS NVARCHAR(MAX));

        EXEC dbo.spMFUnDeleteObjectListInternal @VaultSettings = @VaultSettings,
                                                @XML = @XMLinput,
                                                @XMLOut = @XMLout OUTPUT;

        IF @Debug > 0
            SELECT @XMLout;

        --      PRINT @Output + ' ' + CAST(@objectId AS VARCHAR(100))
        EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @XMLout;

        SELECT @StatusCode = xmlfile.StatusCode,
               @Message = xmlfile.Message
        FROM
            OPENXML(@Idoc, '/form/objVers', 1)
            WITH
            (
                objId INT './@objId',
                StatusCode INT './@statusCode',
                Message NVARCHAR(max) './@Message'
            ) xmlfile;

        IF @Idoc IS NOT NULL
            EXEC sys.sp_xml_removedocument @Idoc;

        SET @DebugText = N' Statuscode %i; Message %s';
        SET @DebugText = @DefaultDebugText + @DebugText;


        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @StatusCode, @Message);
        END;

        IF @StatusCode = 1
        BEGIN
            EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                     @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL,
                                     @ObjIDs = @ObjId,
                                     @RetainDeletions = @RetainDeletions,
                                     @Update_IDOut = @Update_ID OUTPUT,
                                     @ProcessBatch_ID = @ProcessBatch_ID,
                                     @debug = @debug;
                                     ;
        END;

        -------------------------------------------------------------
        -- update MFupdateHistory
        -------------------------------------------------------------
        SET @ProcedureStep = N'Update MFUpdateHistory';

        DECLARE @ObjectDetails XML;
        DECLARE @ObjectVersionDetails XML;
        DECLARE @NewObjectVersionDetails XML;
        DECLARE @MFError XML;

        SET @ObjectDetails = '<form>
  <ObjectType ObjectTypeid="' + CAST(@ObjectTypeId AS VARCHAR(10)) + '" />
</form>';
        SET @ObjectVersionDetails = @XMLinput;
        SET @NewObjectVersionDetails = @XMLout;
        SET @MFError = CASE
                           WHEN @StatusCode IN ( 2 ) THEN
                               @XMLout
                           ELSE
                               NULL
                       END;


        UPDATE dbo.MFUpdateHistory
        SET ObjectDetails = @ObjectDetails,
            ObjectVerDetails = @ObjectVersionDetails,
            NewOrUpdatedObjectVer = @NewObjectVersionDetails,
            MFError = @MFError
        WHERE Id = @Update_IDOut;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';
        SET @LogStatus = CASE
                             WHEN @StatusCode IN ( 1 ) THEN
                                 'Completed'
                             ELSE
                                 'Failed'
                         END;

        SET @LogText = @Message;

        UPDATE dbo.MFUpdateHistory
        SET UpdateStatus = @LogStatus
        WHERE Id = @Update_IDOut;


        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   

        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                         @ProcessType = @ProcessType,
                                         @LogType = N'Debug',
                                         @LogText = @LogText,
                                         @LogStatus = @LogStatus,
                                         @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                               @LogType = N'Debug',
                                               @LogText = @LogText,
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

        SELECT @Output = @Message;
        RETURN @StatusCode;
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
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
         ERROR_LINE(), @ProcedureStep);

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
END;
GO