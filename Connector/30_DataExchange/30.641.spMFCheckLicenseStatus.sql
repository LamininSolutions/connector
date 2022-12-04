PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFCheckLicenseStatus', -- nvarchar(100)
    @Object_Release = '4.10.30.74',           -- varchar(50)
    @UpdateFlag = 2;                         -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFCheckLicenseStatus' --name of procedure
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
CREATE PROCEDURE dbo.spMFCheckLicenseStatus
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFCheckLicenseStatus
    @InternalProcedureName NVARCHAR(500) = 'spMFGetClass',
    @ProcedureName NVARCHAR(500) = 'spMFCheckLicenseStatus',
    @ProcedureStep sysname = 'Validate connection ',
    @ExpiryNotification INT = 30,
    @IsLicenseUpdate BIT = 0,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
AS

/*rST**************************************************************************

======================
spMFCheckLicenseStatus
======================

Return
  - 1 = Success
  - 0 = Error
Parameters
  @InternalprocedureName
    - Procedure to be checked. Default is set to check for a module 1 procedure.
  @ProcedureName
    Procedure from where the check is performed. Default is set to 'Test'
  @ProcedureStep
    Procedure step for checking the license. Default is set to 'Validate Connection'
  @ExpiryNotification
    Default set to 30
    Sets the number of days prior to the license expiry for triggering notification
  @IsLicenseUpdate
    Default = 0
    Set to 1 to force a license update, especially after installing a new license file
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode. Will show additional licensing information.

Purpose
=======

The procedure performs a check of the license for a specific procedure. The license is controlled by vault application framework.

Additional Info
===============

The license will be checked on the M-Files server once a day.  The validity is based on the allocation of the procedure to a specific module.

Examples
========

Check the license for a specific procedure

.. code:: sql

    DECLARE @rt int
    EXEC @rt = [dbo].[spMFCheckLicenseStatus] @Debug = 0
    Select @rt

    --or, for more detail feedback

     DECLARE @rt int
    EXEC @rt = [dbo].[spMFCheckLicenseStatus] @Debug = 1
    Select @rt

----

Updating the license after installing the renewal in the vault application.  

.. code:: sql

    EXEC [dbo].[spMFCheckLicenseStatus] @IsLicenseUpdate = 1
                                   ,@Debug = 1 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-11-25  LC         Improve logging and outcome messages
2021-03-15  LC         Set default schema for MFmodule
2021-01-06  LC         Debug module 2 license
2020-12-31  LC         update message for license expired
2020-12-05  LC         Rework core logic and introduce new supporting procedure
2020-12-03  LC         Improve error messages when license is invalid
2020-12-03  LC         Set additional defaults
2020-06-19  LC         Set module to 1 when null or 0
2019-10-25  LC         Improve messaging, resolve license check bug
2019-09-21  LC         Parameterise overide to check license on new license install
2019-09-20  LC         Parameterise email notification, send only 1 email a day
2019-09-15  LC         Check MFServer for license once day
2019-09-15  LC         Modify procedure to include expiry notification
2019-09-15  LC         Redo licensing logic, only update license every 10 days
2018-07-09  LC         Change name of MFModule table to MFLicenseModule
2019-01-19  LC         Add return values
2017-04-06  DEV2       Create license check procedure
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

DECLARE @ModuleID NVARCHAR(20) = N'0';
DECLARE @Status NVARCHAR(20);
DECLARE @VaultSettings NVARCHAR(2000);
DECLARE @ModuleErrorMessage NVARCHAR(MAX);

SET @ProcedureStep = 'Validate License ';

--DROP TABLE MFModule;
DECLARE @ProcessType AS NVARCHAR(50);
DECLARE @MFTableName AS NVARCHAR(128) = N'';

SET @ProcessType = ISNULL(@ProcessType, 'Check License');

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
DECLARE @Checkstatus INT = 0;
DECLARE @ModuleList NVARCHAR(100) = N'1,2,3,4';
DECLARE @license NVARCHAR(400);
DECLARE @DecryptedPassword NVARCHAR(2000);
DECLARE @EcryptedPassword NVARCHAR(2000);
DECLARE @ErrorCode       NVARCHAR(5),
    @ExpiryDate_txt      NVARCHAR(10),
    @LastcheckedDate_txt NVARCHAR(10);
DECLARE @LicenseExpiry DATE;
DECLARE @LastValidate DATE;
DECLARE @LicenseExpiryTXT NVARCHAR(10);
DECLARE @HoursfromlastChecked INT;

-------------------------------------------------------------
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = 'Start Logging';
SET @LogText = N'Processing ' + @ProcedureName;


		EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
		  , @ProcessType = @ProcessType
		  , @LogType = N'Status'
		  , @LogText = @LogText
		  , @LogStatus = N'In Progress'
		  , @debug = @Debug

                         
                           SET @LogTypeDetail = 'Status';
                           SET @LogStatusDetail = @logstatus;
                           SET @LogTextDetail = 'check license status for ' + @InternalProcedureName
                           SET @LogColumnName = '';
                           SET @LogColumnValue = '';

                           EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = null
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

-------------------------------------------------------------
-- Get settings
-------------------------------------------------------------
SELECT @VaultSettings = dbo.FnMFVaultSettings();

-------------------------------------------------------------
-- reset license table
-------------------------------------------------------------
IF @IsLicenseUpdate = 1
BEGIN
    IF
    (
        SELECT OBJECT_ID('..MFModule')
    ) IS NOT NULL
        DROP TABLE dbo.MFModule;
END;

-------------------------------------------------------------
-- Get module
-------------------------------------------------------------
SELECT @ModuleID = moc.Module
FROM setup.MFSQLObjectsControl AS moc
WHERE moc.Name = @InternalProcedureName;

SELECT @ModuleID = ISNULL(@ModuleID, '1');

SET @DebugText = N' %s';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'Get module';

IF @Debug > 0
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);

BEGIN TRY
    IF @ModuleID = '0'
    BEGIN
        SET @Msg = @InternalProcedureName + N' not in control table';
        SET @Checkstatus = 1;
        SET @DebugText = @Msg;
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Check procedure ';

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    IF @ModuleID > '0'
    BEGIN

        -------------------------------------------------------------
        -- Create license module if not exist
        -------------------------------------------------------------
        IF
        (
            SELECT OBJECT_ID('..MFModule')
        ) IS NULL
        BEGIN
            CREATE TABLE dbo.MFModule
            (
                Module NVARCHAR(20),
                license NVARCHAR(400),
                DateLastChecked DATETIME
                    DEFAULT GETUTCDATE()
            );

            INSERT INTO dbo.MFModule
            (
                Module
            )
            VALUES
            (1  ),
            (2  ),
            (3  ),
            (4  );
        END;

        SET @DebugText = N' Module %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Checked module exists';

        IF @Debug > 0
        BEGIN
            SELECT @ModuleID AS module;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);
        END;

        -------------------------------------------------------------
        -- is license update
        -------------------------------------------------------------

        -------------------------------------------------------------
        --pre-checks
        -- 1 = module table does not exsit
        -- 2 = module does not exist
        -- 3 = license in table does not exist
        -- 4 = license exists
        -- 5 = license expiry date does not exist
        -- 6 = last check date does not exist

        -------------------------------------------------------------
        SET @ProcedureStep = 'Pre-checks ';

        DECLARE @ModuleTable_ID INT;
        DECLARE @ModuleRows_count INT;
        DECLARE @LicenseInTable NVARCHAR(100);

        SELECT @ModuleTable_ID = OBJECT_ID('MFModule');

        SELECT @ModuleRows_count = COUNT(*)
        FROM dbo.MFModule
        WHERE Module = @ModuleID;

        SELECT @LicenseInTable = license
        FROM dbo.MFModule
        WHERE Module = @ModuleID;

        -------------------------------------------------------------
        -- checkstatus from MFModule
        -------------------------------------------------------------
        SELECT @Checkstatus = CASE
                                  WHEN @ModuleTable_ID = 0 THEN
                                      1
                                  WHEN @ModuleRows_count = 0 THEN
                                      2
                                  WHEN @LicenseInTable IS NULL
                                       AND @ModuleRows_count = 1 THEN
                                      3
                                  WHEN @LicenseInTable IS NOT NULL
                                       AND @ModuleRows_count = 1 THEN
                                      4
                                  ELSE
                                      NULL
                              END;

        SET @DebugText = N' Checkstatus %i ' + ' License ' + ISNULL(@LicenseInTable,'no license record');
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Checkstatus);
        END;

        -------------------------------------------------------------
        -- Check status from license
        -------------------------------------------------------------
        SET @ProcedureStep = 'Analyse license ';
        -- decrypt license for further analysis
        IF @Checkstatus = 4
        BEGIN
            SELECT @license = license
            FROM dbo.MFModule
            WHERE Module = @ModuleID;

            SET @license = ISNULL(@license, '');

            EXEC dbo.spMFDecrypt @EncryptedPassword = @license, -- nvarchar(2000)
                @DecryptedPassword = @license OUTPUT;           -- nvarchar(2000)

            IF @Debug > 0
            BEGIN
                SELECT *
                FROM dbo.fnMFParseDelimitedString(@license, '|');
            END;
        END;

        --check if license expiry date exist in decrypted license
        SELECT @ExpiryDate_txt = fmss.ListItem
        FROM dbo.fnMFParseDelimitedString(@license, '|') AS fmss
        WHERE fmss.ID = 3; -- item 3 is the license expiry

        SELECT @Checkstatus = CASE
                                  WHEN @ExpiryDate_txt IS NULL
                                       AND @Checkstatus > 3 THEN
                                      5
                                  ELSE
                                      @Checkstatus
                              END;

        SELECT @LastcheckedDate_txt = fmss.ListItem
        FROM dbo.fnMFParseDelimitedString(@license, '|') AS fmss
        WHERE fmss.ID = 4; --item 4 is the date last checked

        SELECT @HoursfromlastChecked = DATEDIFF(HOUR, CONVERT(DATE, @LastcheckedDate_txt), GETDATE());

        IF @Debug > 0
            SELECT @HoursfromlastChecked AS HoursSinceLastChecked;

        SELECT @Checkstatus = CASE
                                  WHEN @LastcheckedDate_txt IS NULL
                                       AND @Checkstatus > 3 THEN
                                      6
                                  WHEN @HoursfromlastChecked > 24 THEN
                                      10
                                  WHEN @HoursfromlastChecked < 24
                                       AND @Checkstatus = 4 THEN
                                      11
                                  ELSE
                                      @Checkstatus
                              END;

        IF @Debug > 0
        BEGIN
            SELECT @Checkstatus AS PreCheckstatus;
        END;

     

        -------------------------------------------------------------
        -- set error code to invalid license when table or module invalid
        -------------------------------------------------------------
        SELECT @ErrorCode = CASE
                                WHEN @Checkstatus IN ( 1, 2, 3 ) THEN
                                    2
                                WHEN @Checkstatus IN ( 10, 11 ) THEN
                                    1
                                ELSE
                                    -1
                            END;

        SELECT @Msg = CASE
                          WHEN @Checkstatus = 1 THEN
                              N'MFModule table does not exist '
                          WHEN @Checkstatus = 2 THEN
                              N' Module does not exist '
                          WHEN @Checkstatus = 3 THEN
                              N' license does not exist '
                              end
            
        
        
        SET @DebugText = @DefaultDebugText + @Msg;
        SET @ProcedureStep = 'Pre-checks error: ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Checkstatus);
        END;

        -------------------------------------------------------------
        -- initialise license if license does not exist
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get license';

        IF @Checkstatus IN ( 3, 10 )
           OR @Checkstatus IS NULL
        BEGIN
            SET @DebugText = N'%s';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Creating new license code for module ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);
            END;

            EXEC dbo.spMFGetLicense @ModuleID,
                @LicenseExpiry OUTPUT,
                @ErrorCode OUTPUT,
                @Checkstatus OUTPUT,
                @Status OUTPUT,
                @Debug;

            DECLARE @newLicense NVARCHAR(400);

    
                SELECT @newLicense
                    = CASE WHEN @LicenseExpiry IS NULL THEN @Status
                    Else
                    @ModuleID + N'|' + @ErrorCode + N'|' + CAST(@LicenseExpiry AS NVARCHAR(30)) + N'|'
                      + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10))
                      END;

        SET @DebugText = @Status + N' %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'License generated: '

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @newLicense);
        END;


                --encrypt the license again
                IF ISNULL(@newLicense, '') <> '' 
                BEGIN
                    EXEC dbo.spMFEncrypt @Password = @newLicense,     -- nvarchar(2000)
                        @EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

                    MERGE INTO dbo.MFModule t
                    USING
                    (
                        SELECT @ModuleID      AS Module,
                            @EcryptedPassword AS licence,
                            GETDATE()         AS Datelastcheck
                    ) s
                    ON s.Module = t.Module
                    WHEN MATCHED THEN
                        UPDATE SET t.license = s.licence,
                            t.DateLastChecked = s.Datelastcheck
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            Module,
                            license,
                            DateLastChecked
                        )
                        VALUES
                        (s.Module, s.licence, s.Datelastcheck);

                    SET @count = @@RowCount;
                END;

                SELECT @Msg =   @Status
   

                SET @DebugText = N' %s';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'MFModule updated ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @newLicense);
                END;
         END; --checkstatus 3,10
    -------------------------------------------------------------
    -- set message
    -------------------------------------------------------------
       SET @ProcedureStep = 'Set Status Message '

        SELECT @Msg = CASE
                          WHEN @Checkstatus = 1 THEN
                              N'MFModule table does not exist '
                          WHEN @Checkstatus = 2 THEN
                              N' Module does not exist '
                          WHEN @Checkstatus = 3 THEN
                              N' license does not exist '
                          WHEN @Checkstatus = 4 THEN
                              N' License Assembly is found '
                          WHEN @Checkstatus = 5 THEN
                              N' Missing expiry date in license '
                            WHEN @Checkstatus = 7 THEN
                              N' license expired '
                          WHEN @Checkstatus = 6 THEN
                              N' Missing last checked date '
                          WHEN @Checkstatus = 9 THEN 
                             N' License expires on ' + CAST(@LicenseExpiry AS NVARCHAR(30))
                          WHEN @Checkstatus = 10 THEN
                              N' License requires re-validation '
                          WHEN @Checkstatus = 11 THEN
                              N' License checked ' + CAST(@HoursfromlastChecked AS NVARCHAR(5)) + ' hours ago '
                          WHEN @Checkstatus IS NULL THEN
                              N' no pre-check'
                          
                      END;
        
        SET @DebugText = N'  %i : %s';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Checkstatus, @Msg);
        END;

          
                           SET @LogTypeDetail = 'Status';
                           SET @LogStatusDetail = @logstatus;
                           SET @LogTextDetail = 'check Status ' + @Msg
                           SET @LogColumnName = '';
                           SET @LogColumnValue = '';

                           EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = null
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug


                -------------------------------------------------------------
                -- LICENSE NOTIFICATION
                -------------------------------------------------------------
                SET @ProcedureStep = 'License notification ';

                IF @Checkstatus IN ( 9, 10 )
                BEGIN
                    SET @DebugText = 'Checkstatus 9 and 10 ' + ISNULL(@Msg,'no status');
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                
                IF @Checkstatus = 9

                -------------------------------------------------------------
                -- re-check license
                -------------------------------------------------------------
                BEGIN
                    SET @DebugText = ISNULL(@Msg, 'Expiry notification') 
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Expiry Notification ';

                      IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    IF
                    (
                        SELECT COUNT(*)
                        FROM dbo.MFLog
                        WHERE ErrorNumber = 90003
                              AND CreateDate > DATEADD(DAY, -1, GETDATE())
                    ) = 0
                    BEGIN
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
                        (@ProcedureName, 90003, @Msg, ERROR_PROCEDURE(), 'WARNING', 0, 0, @ProcedureStep);
                    END;

                  
                END; --remaining days < 30

                -------------------------------------------------------------
                -- re-validation
                -------------------------------------------------------------
                 IF @Checkstatus = 10

                 BEGIN

                    --encrypt the license again
                IF ISNULL(@newLicense, '') <> ''
                BEGIN
                    EXEC dbo.spMFEncrypt @Password = @newLicense,     -- nvarchar(2000)
                        @EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

                    MERGE INTO dbo.MFModule t
                    USING
                    (
                        SELECT @ModuleID      AS Module,
                            @EcryptedPassword AS licence,
                            GETDATE()         AS Datelastcheck
                    ) s
                    ON s.Module = t.Module
                    WHEN MATCHED THEN
                        UPDATE SET t.license = s.licence,
                            t.DateLastChecked = s.Datelastcheck
                    WHEN NOT MATCHED THEN
                        INSERT
                        (
                            Module,
                            license,
                            DateLastChecked
                        )
                        VALUES
                        (s.Module, s.licence, s.Datelastcheck);

                    SET @count = @@RowCount;
                END;

                SELECT @Msg =   @Status
   

                SET @DebugText = N' %s';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'MFModule updated ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @newLicense);
                END;

                 

                 END

                END; -- expiry notification
   --         END;
 
    END;

    -- if module > 0

    -------------------------------------------------------------
    -- log error
    -------------------------------------------------------------
    SET @ProcedureStep = 'Report error codes ';

    IF @Checkstatus IN ( 1, 2,7 )
    BEGIN
        SET @DebugText = @Status;
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'License status Notification ';

        IF
        (
            SELECT COUNT(*)
            FROM dbo.MFLog
            WHERE ErrorNumber = 90003
                  AND CreateDate > DATEADD(DAY, -1, GETDATE())
        ) = 0
        BEGIN
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
            (@ProcedureName, 90003, @Msg, ERROR_PROCEDURE(), 'WARNING', 0, 0, @ProcedureStep);
        END;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;
    END;

    --remain days < 30

    ----update license check
    -------------------------------------------------------------
    -- Report error codes
    -------------------------------------------------------------
    SET @DebugText = @Msg;
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'License validity ';

    IF @ErrorCode IN ( '2', '3', '4', '5' )
    BEGIN
        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    		-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Message'
			  , @LogText = @msg
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()
             SET @LogtextDetail = @ProcessType + ' : '  + @Msg

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = null
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = null
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0


    RETURN @ErrorCode;
END TRY -- update license check check status > 4
BEGIN CATCH
    BEGIN
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
        (@ProcedureName, 90004, @Msg, ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
            @ProcedureStep);

        SET @ProcedureStep = 'Catch Error';
    END;

    RETURN -1;
END CATCH;
GO