PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'dbo.spMFGetObjectvers';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFGetObjectvers', -- nvarchar(100)
    @Object_Release = '4.8.22.62',      -- varchar(50)
    @UpdateFlag = 2;                    -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFGetObjectvers' --name of procedure
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
CREATE PROCEDURE dbo.spMFGetObjectvers
AS
SELECT 'created, but not implemented yet.'; --just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFGetObjectvers
(
    @TableName NVARCHAR(100),
    @dtModifiedDate DATETIME,
    @MFIDs NVARCHAR(4000),
    @outPutXML NVARCHAR(MAX) OUTPUT,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=================
spMFGetObjectvers
=================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName nvarchar(100)
    Class table name
  @dtModifiedDate datetime
    Date from for object versions and deletions
  @MFIDs nvarchar(4000)
    comma delimited string of objids 
  @outPutXML nvarchar(max) (output)
    object versions of filtered objects
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode


Purpose
=======

To get all the object versions of the class table as XML.

Deleted objects and current objects are combined in the @OutputXML if MFIDs are used as a parameter
When Last modified date are used then the @outputXML will include the objects changed later than the date specified 
and the @DeletedOutputXML will include the objects that was deleted since the date lastmodified date.

Warning
=======

Either objids or lastmodified date must be specified. The procedure cannot be used with both filters as null.

Examples
========

.. code:: sql

    DECLARE @outPutXML    NVARCHAR(MAX),
    @DeletedoutPutXML    NVARCHAR(MAX),
    @ProcessBatch_ID3 INT;

    EXEC dbo.spMFGetObjectvers @TableName = MFLarge_volume,
    @dtModifiedDate = '2020-08-01',
    @MFIDs = null,
    @outPutXML = @outPutXML OUTPUT,
    @ProcessBatch_ID = @ProcessBatch_ID3 OUTPUT,
    @Debug = 101

    SELECT CAST(@outPutXML AS XML)
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-08-25  LC         Add return XML for deleted records
2019-12-12  LC         Improve text in MFProcessBatchDetail
2019-09-04  LC         Add connection test
2019-08-30  JC         Added documentation
2019-08-05  LC         Improve logging
2019-07-10  LC         Add debugging and messaging
2018-04-04  DEV2       Added License module validation code
2016-08-22  LC         Update settings index
2016 08-22  LC         Change objids to NVARCHAR(4000)
2015 09-21  DEV2       Removed old style vaultsettings, replace with @VaultSettings
2015-06-16  Kishore    Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @MFTableName AS NVARCHAR(128) = N'';
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Get Objver');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFGetObjectvers';
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
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
        @debug = 0;

    BEGIN TRY
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @ClassId INT;
        DECLARE @Idoc INT;

        SELECT @ClassId = MFID
        FROM dbo.MFClass
        WHERE TableName = @TableName;

        IF ISNULL(@ClassId, -1) = -1
        BEGIN
            SET @DebugText = N' Unable to find class table - check name: ' + @TableName;
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Get class id';

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        -------------------------------------------------------------
        -- Check connection to vault
        -------------------------------------------------------------
        DECLARE @IsUpToDate INT;

        SET @ProcedureStep = N'Connection test: ';

        DECLARE @TestResult INT;

        EXEC @return_value = dbo.spMFConnectionTest 
        IF @return_value <> 1
        BEGIN
            SET @DebugText = N'Connection failed ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;

        ---------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFGetObjectType
        ------------------------------------------------------------------
        SET @ProcedureStep = N'Check license';

        EXEC dbo.spMFCheckLicenseStatus 'spMFGetObjectVersInternal',
            @ProcedureName,
            @ProcedureStep;

        SET @DebugText
            = N'Filters: Class %i :Date ' + CAST(ISNULL(@dtModifiedDate, '') AS VARCHAR(30))
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Wrapper - spMFGetObjectVersInternal';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
        END;

        IF @dtModifiedDate IS NULL
           AND @MFIDs IS NULL
        BEGIN
            SET @DebugText = N' lastModified date and MFIDs cannot both be null ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;

			IF @MFIDs IS NOT NULL
            Begin
            DECLARE @From INT,
                @To       INT;

            SELECT @From = MIN(fmss.Item),
                @To      = MAX(fmss.Item)
            FROM dbo.fnMFSplitString(@MFIDs, ',') AS fmss;

			END

        DECLARE @outPutDeletedXML NVARCHAR(MAX);

        EXECUTE @return_value = dbo.spMFGetObjectVersInternal @VaultSettings,
            @ClassId,
            @dtModifiedDate,
            @MFIDs,
            @outPutXML OUTPUT,
            @outPutDeletedXML OUTPUT;

        IF @Debug > 0
        BEGIN
            SELECT @outPutXML     AS ObjVerOutput,
                @outPutDeletedXML AS DeletedObject;
        END;

        SELECT @outPutXML = CASE
                                WHEN @outPutXML = '' THEN
                                    '<form>'
                                WHEN @outPutXML = '<form />' THEN
                                    '<form>'
                                ELSE
                                    REPLACE(@outPutXML, '</form>', '')
                            END + CASE
                                      WHEN @outPutDeletedXML = '' THEN
                                          '</form>'
                                      WHEN @outPutDeletedXML = '<form />' THEN
                                          '</form>'
                                      ELSE
                                          REPLACE(@outPutDeletedXML, '<form>', '')
                                  END;

        IF (@outPutXML <> '<form /><form />' OR isnull(@outPutXML,'<form />') <> '<form />' )
        BEGIN
            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @outPutXML;

            SET @DebugText = N' wrapper returned result';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Procesing result ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @rowcount = COUNT(xmlfile.objId)
            FROM
                OPENXML(@Idoc, '/form/objVers', 1) WITH (objId INT './@objectID') xmlfile;

Set @DebugText = ' Records returned ' + CAST(@rowcount AS NVARCHAR(10))
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = ' XML Return'

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END

            SET @StartTime = GETUTCDATE();
            SET @ProcedureStep = N'Result of Getobjver';
            SET @LogTypeDetail = N'Status';
            SET @LogStatusDetail = N'In Progress';
            SET @LogTextDetail
                = N'Objver with filters: Date: ' + CAST(ISNULL(@dtModifiedDate, '2000-01-01') AS NVARCHAR(30))
                  + N' Objids: From  ' + CAST(ISNULL(@From,0) AS NVARCHAR(10)) + N' to ' + CAST(ISNULL(@To,0) AS NVARCHAR(10));
            SET @LogColumnName = N'Get Objectvers';
            SET @LogColumnValue = CAST(@rowcount AS NVARCHAR(10));

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

            IF @Idoc IS NOT null
			EXEC sys.sp_xml_removedocument @Idoc;
        END;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';
        SET @LogStatus = N'Completed';
        SET @LogText = N'Object versions updated';

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