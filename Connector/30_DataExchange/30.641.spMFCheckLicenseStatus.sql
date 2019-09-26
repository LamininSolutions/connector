PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCheckLicenseStatus' -- nvarchar(100)
                                    ,@Object_Release = '4.4.13.53'           -- varchar(50)
                                    ,@UpdateFlag = 2;                        -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCheckLicenseStatus' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFCheckLicenseStatus]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCheckLicenseStatus]
    @InternalProcedureName NVARCHAR(500)
   ,@ProcedureName NVARCHAR(500)
   ,@ProcedureStep sysname = 'Validate connection '
   ,@ExpiryNotification INT = 30
   ,@IsLicenseUpdate BIT = 0
   ,@ProcessBatch_id INT = NULL OUTPUT
   ,@Debug INT = 0
AS
--BELOW HEADER
/*------------------------------------------------------------------------------------------------
Author: LSUSA\LeRouxC
Create date: 21/09/2019 15:58

Test Script:

------------------------------------------------------------------------------------------------*/

--BELOW ALTER PROC AS

/*rST**************************************************************************

======================
spMFCheckLicenseStatus
======================

Return
  - 1 = Success
  - 0 = Error
Parameters
  @InternalprocedureName
    - Procedure to be checked
  @ProcedureName 
    Procedure from where the check is performed
  @ProcedureStep
    Procedure step for checking the license
  @ExpiryNotification
    Default to 30
    Sets the number of days prior to the license expiry for triggering notification
  @IsLicenseUpdate
    Default = 0
    Set to 1 to force a license update, especially after installing a new license file
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

The procedure performs a check of the license for a specific procedure. The license is controlled by vault application framework.

Additional Info
===============
The license will be checked on the M-Files server once a day.  The validity is based on the allocation of the procedure to a specific module.

Examples
========

.. code:: sql
....Check the license for a procedure
    EXEC [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFGetclass' -- nvarchar(500)
                                   ,@ProcedureName = 'test'        -- nvarchar(500)
                                   ,@ProcedureStep = 'test'         -- sysname

----

.. code:: sql
....Force the checking of the  license against the server
    EXEC [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFGetclass' -- nvarchar(500)
                                   ,@ProcedureName = 'test'        -- nvarchar(500)
                                   ,@ProcedureStep = 'test'         -- sysname
                                   ,@ExpiryNotification = 30    -- int
                                   ,@IsLicenseUpdate = 1
                                   ,@Debug = 1                 -- int

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
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

DECLARE @ModuleID NVARCHAR(20);
DECLARE @Status NVARCHAR(20);
DECLARE @VaultSettings NVARCHAR(2000);
DECLARE @ModuleErrorMessage NVARCHAR(MAX);

SET @ProcedureStep = 'Validate License ';

--DROP TABLE MFModule;
DECLARE @ProcessType AS NVARCHAR(50);
DECLARE @MFTableName AS NVARCHAR(128) = '';

SET @ProcessType = ISNULL(@ProcessType, 'Check License');

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
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = 'Start Logging';
SET @LogText = 'Processing ' + @ProcedureName;

/*
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
		  , @Validation_ID = null
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = null
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0

*/
-------------------------------------------------------------
-- Get settings
-------------------------------------------------------------
SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

-------------------------------------------------------------
-- Get module
-------------------------------------------------------------
SELECT @ModuleID = [moc].[Module]
FROM [setup].[MFSQLObjectsControl] AS [moc]
WHERE [moc].[Name] = @InternalProcedureName;

SELECT @ModuleID = ISNULL(@ModuleID, '1');

-------------------------------------------------------------
-- Create license
-------------------------------------------------------------
IF
(
    SELECT OBJECT_ID('..MFModule')
) IS NULL
BEGIN
    CREATE TABLE [MFModule]
    (
        [Module] NVARCHAR(20)
       ,[license] NVARCHAR(400)
       ,[DateLastChecked] DATETIME
            DEFAULT GETUTCDATE()
    );

    INSERT INTO [dbo].[MFModule]
    (
        [Module]
    )
    VALUES
    (1  )
   ,(2)
   ,(3)
   ,(4);
END;

DECLARE @ModuleList NVARCHAR(100) = '1,2,3,4';
DECLARE @license NVARCHAR(400);
DECLARE @DecryptedPassword NVARCHAR(2000);
DECLARE @EcryptedPassword NVARCHAR(2000);
DECLARE @ErrorCode  NVARCHAR(5)
       ,@ExpiryDate NVARCHAR(10);
DECLARE @LicenseExpiry DATETIME;
DECLARE @LastValidate DATETIME;
DECLARE @LicenseExpiryTXT NVARCHAR(10);

SET @DebugText = ' Module %s';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'Check if module exist';

IF @Debug > 0
BEGIN
    SELECT @ModuleID AS [module];

    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);
END;

-------------------------------------------------------------
--pre-check
-------------------------------------------------------------
SET @ProcedureStep = 'Pre-checks ';

DECLARE @Checkstatus INT = 0;

SELECT @Checkstatus = CASE
                          WHEN
(
    SELECT COUNT(*) FROM [sys].[objects] WHERE [name] = 'MFModule'
)   <> 1 THEN
                              1 --MFModule table does not exist
                          WHEN
(
    SELECT COUNT(*) FROM [dbo].[MFModule] WHERE [Module] = @ModuleID
)   <> 1 THEN
                              2 -- Module not in table
                          WHEN
(
    SELECT ISNULL([license], '')
    FROM [dbo].[MFModule]
    WHERE [Module] = @ModuleID
)   = '' THEN
                              3
                          ELSE
                              9
                      END;

IF @Checkstatus > 3
BEGIN
    SELECT @license = [license]
    FROM [dbo].[MFModule]
    WHERE [Module] = @ModuleID;

    EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @license         -- nvarchar(2000)
                            ,@DecryptedPassword = @license OUTPUT; -- nvarchar(2000)

    IF @Debug > 0
    BEGIN
        SELECT *
        FROM [dbo].[fnMFParseDelimitedString](@license, '|');
    END;

    SELECT @Checkstatus = CASE
                              WHEN NOT EXISTS
    (
        SELECT *
        FROM [dbo].[fnMFParseDelimitedString](@license, '|') AS [fmss]
        WHERE [fmss].[ID] = 4
    )   THEN
                                  4
                              ELSE
                                  9
                          END;
END;

IF @Checkstatus = 1
BEGIN -- check MFmodule of exist
    SET @DebugText = 'MFModule does not exist Checkstatus %i';
END;

IF @Checkstatus = 2
BEGIN -- check module of exist
    SET @DebugText = 'Module does not exist Checkstatus %i';
END;

IF @Checkstatus = 3
BEGIN -- check license initialised
    SET @DebugText = 'license has not yet been initialised Checkstatus %i';
END;

IF @Checkstatus = 4
BEGIN -- check Expiry date exist
    SET @ErrorCode = 2;
    SET @DebugText = 'License Assembly is invalid Checkstatus %i';
END;

IF @Checkstatus > 4
BEGIN -- check Expiry date exist
    SET @DebugText = 'License is valid Checkstatus %i';
END;

SET @DebugText = @DefaultDebugText + @DebugText;

IF @Debug > 0
BEGIN
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Checkstatus);
END;

-------------------------------------------------------------
-- initialise license
-------------------------------------------------------------
SET @ProcedureStep = 'initialise license';

IF @Checkstatus = 3
BEGIN
    SET @DebugText = '%s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Creating new license code for module ';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);
    END;

    BEGIN TRY -- initialise license if not exist in MFModule
        EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                       ,@ModuleID = @ModuleID           -- nvarchar(20)
                                       ,@Status = @Status OUTPUT;       -- nvarchar(20)

        SET @DebugText = ' Return spMFValidateModule module %s Status %s  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID, @Status);
        END;

        SELECT @LicenseExpiryTXT = [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2;

        SELECT @LicenseExpiry = CASE
                                    WHEN LEN(@LicenseExpiryTXT) > 0 THEN
                                        [dbo].[fnMFTextToDate](@LicenseExpiryTXT, '/')
                                    ELSE
                                        CONVERT(DATE, DATEADD(DAY, 1, GETDATE()))
                                END;

        SELECT @ErrorCode = [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 1;

        SET @ProcedureStep = 'Get Status';
        SET @DebugText = ' License expiry ' + CAST(@LicenseExpiry AS NVARCHAR(25)) + ' ErrorCode %s  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT @LicenseExpiry
                  ,@ErrorCode;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ErrorCode);
        END;

        SELECT @license = @ModuleID + '|' + @Status + '|' + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10));

        EXEC [dbo].[spMFEncrypt] @Password = @license                          -- nvarchar(2000)
                                ,@EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)
    END TRY
    BEGIN CATCH
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Unable to create license';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;

        RETURN 6;
    END CATCH;

    UPDATE [mm]
    SET [mm].[license] = @EcryptedPassword
       ,[mm].[DateLastChecked] = GETUTCDATE()
    FROM [dbo].[MFModule] [mm]
    WHERE [mm].[Module] = @ModuleID;

    SET @Checkstatus = 9;
    SET @DebugText = 'License %s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Initialise ';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @license);
    END;
END; -- end create new license

IF @Checkstatus <> 4
BEGIN

    -------------------------------------------------------------
    -- Validate license
    -------------------------------------------------------------
    SELECT @EcryptedPassword = [license]
    FROM [dbo].[MFModule]
    WHERE [Module] = @ModuleID;

    EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @EcryptedPassword          -- nvarchar(2000)
                            ,@DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Get Last Licence check';

    IF @Debug > 0
    BEGIN
        SELECT *
        FROM [dbo].[fnMFSplitString](@DecryptedPassword, '|') [fmss];

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    SELECT @ErrorCode = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@DecryptedPassword, '|') AS [fmss]
    WHERE [fmss].[ID] = 2;

    SELECT @ExpiryDate = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@DecryptedPassword, '|') AS [fmss]
    WHERE [fmss].[ID] = 3;

    SELECT @LastValidate = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@DecryptedPassword, '|') AS [fmss]
    WHERE [fmss].[ID] = 4;

    SET @DebugText
        = ' Module %s ResultCode %s Expiry Date ' + CONVERT(NVARCHAR, @ExpiryDate) + ' Last Validated '
          + CONVERT(NVARCHAR, @LastValidate);
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'License check result';

    IF @Debug > 0
    BEGIN
        SELECT @ModuleID
              ,@ErrorCode
              ,@ExpiryDate
              ,@LastValidate;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID, @ErrorCode);
    END;

    -------------------------------------------------------------
    -- LICENSE EXPIRY
    -------------------------------------------------------------
    SET @ProcedureStep = 'License expiry notification';

    DECLARE @RemainingDays   INT
           ,@lastCheckedDays INT;

    SELECT @RemainingDays   = DATEDIFF(DAY, GETUTCDATE(), CONVERT(DATE, @ExpiryDate))
          ,@lastCheckedDays = DATEDIFF(DAY, @LastValidate, GETUTCDATE());

    SET @DebugText = ' Remaining Days %i LastCheckedDays %i ';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemainingDays, @lastCheckedDays);
    END;

    -------------------------------------------------------------
    -- re-check license
    -------------------------------------------------------------
    IF @RemainingDays <= @ExpiryNotification
    BEGIN
        SET @DebugText = ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate);
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Expiry Notification ';

        IF
        (
            SELECT COUNT(*)
            FROM [dbo].[MFLog]
            WHERE [ErrorNumber] = 90003
                  AND [CreateDate] > DATEADD(DAY, -1, GETDATE())
        ) = 0
        BEGIN
            --------------------------------------------------
            -- INSERTING ERROR DETAILS INTO LOG TABLE
            --------------------------------------------------
            INSERT INTO [dbo].[MFLog]
            (
                [SPName]
               ,[ErrorNumber]
               ,[ErrorMessage]
               ,[ErrorProcedure]
               ,[ErrorState]
               ,[ErrorSeverity]
               ,[ErrorLine]
               ,[ProcedureStep]
            )
            VALUES
            (@ProcedureName, 90003, ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate), ERROR_PROCEDURE()
            ,'WARNING', 0, 0, @ProcedureStep);
        END;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;
    END; --remaining days < 30
END;

--validate license checkstatus > 4

-------------------------------------------------------------
-- LICENSE REQUIRE RECHECKING
-------------------------------------------------------------
IF (
       @lastCheckedDays > 0
       AND @Checkstatus > 4
   )
   OR @IsLicenseUpdate = 1
BEGIN TRY
    EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                   ,@ModuleID = @ModuleID           -- nvarchar(20)
                                   ,@Status = @Status OUTPUT;       -- nvarchar(20)

    SELECT @LicenseExpiryTXT = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
    WHERE [fmss].[ID] = 2;

    SELECT @LicenseExpiry = CASE
                                WHEN LEN(@LicenseExpiryTXT) > 0 THEN
                                    [dbo].[fnMFTextToDate](@LicenseExpiryTXT, '/')
                                ELSE
                                    CONVERT(DATE, DATEADD(DAY, 1, GETDATE()))
                            END;

    SELECT @ErrorCode = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
    WHERE [fmss].[ID] = 1;

    SELECT @license = @ModuleID + '|' + @Status + '|' + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10));

    EXEC [dbo].[spMFEncrypt] @Password = @license                          -- nvarchar(2000)
                            ,@EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

    UPDATE [mm]
    SET [mm].[license] = @EcryptedPassword
       ,[mm].[DateLastChecked] = GETUTCDATE()
    FROM [dbo].[MFModule] [mm]
    WHERE [mm].[Module] = @ModuleID;

    SET @DebugText = 'License %s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Refresh ';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @license);
    END;

    -------------------------------------------------------------
    -- recheck validity
    -------------------------------------------------------------
    SELECT @ErrorCode = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@license, '|') AS [fmss]
    WHERE [fmss].[ID] = 2;

    SELECT @ExpiryDate = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@license, '|') AS [fmss]
    WHERE [fmss].[ID] = 3;

    SELECT @LastValidate = [fmss].[ListItem]
    FROM [dbo].[fnMFParseDelimitedString](@license, '|') AS [fmss]
    WHERE [fmss].[ID] = 4;

    SET @DebugText
        = ' Module %s ResultCode %s Expiry Date ' + CONVERT(NVARCHAR, @ExpiryDate, 105) + ' Last Validated '
          + CONVERT(NVARCHAR, @LastValidate, 105);
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'recheck licence check result';

    IF @Debug > 0
    BEGIN
        SELECT @ModuleID
              ,@ErrorCode
              ,@ExpiryDate
              ,@LastValidate;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID, @ErrorCode);
    END;

    -------------------------------------------------------------
    -- LICENSE EXPIRY
    -------------------------------------------------------------
    SELECT @RemainingDays   = DATEDIFF(DAY, GETUTCDATE(), CONVERT(DATETIME, @ExpiryDate, 105))
          ,@lastCheckedDays = DATEDIFF(DAY, @LastValidate, GETUTCDATE());

    SET @DebugText = ' Remaining Days %i LastCheckedDays %i ';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Rechecked License expire';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemainingDays, @lastCheckedDays);
    END;

    -------------------------------------------------------------
    -- re-check license
    -------------------------------------------------------------
    IF @RemainingDays <= @ExpiryNotification
    BEGIN
        SET @DebugText = ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate);
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Expiry Notification ';

        IF
        (
            SELECT COUNT(*)
            FROM [dbo].[MFLog]
            WHERE [ErrorNumber] = 90003
                  AND [CreateDate] > DATEADD(DAY, -1, GETDATE())
        ) = 0
        BEGIN
            --------------------------------------------------
            -- INSERTING ERROR DETAILS INTO LOG TABLE
            --------------------------------------------------
            INSERT INTO [dbo].[MFLog]
            (
                [SPName]
               ,[ErrorNumber]
               ,[ErrorMessage]
               ,[ErrorProcedure]
               ,[ErrorState]
               ,[ErrorSeverity]
               ,[ErrorLine]
               ,[ProcedureStep]
            )
            VALUES
            (@ProcedureName, 90003, ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate), ERROR_PROCEDURE()
            ,'WARNING', 0, 0, @ProcedureStep);
        END;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;
    END;

    --remain days < 30

    --update license check

    -------------------------------------------------------------
    -- Report error codes
    -------------------------------------------------------------
    SET @DebugText = ' ErrorCode %s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'License validity ';

    IF @ErrorCode = '2'
    BEGIN
        RAISERROR('Proc: %s Step: %s Licence Error %s ', 16, 1, @ProcedureName, @ProcedureStep, 'License is not valid.');

        RETURN 2;
    END;

    IF @ErrorCode = '3'
    BEGIN
        RAISERROR(
                     'Proc: %s Step: %s Licence Error %s '
                    ,16
                    ,1
                    ,@ProcedureName
                    ,@ProcedureStep
                    ,'You dont have access to this module.'
                 );

        RETURN 3;
    END;

    IF @ErrorCode = '4'
    BEGIN
        RAISERROR('Proc: %s Step: %s Licence Error %s ', 16, 1, @ProcedureName, @ProcedureStep, 'Invalid License key.');

        RETURN 4;
    END;

    IF @ErrorCode = '5'
    BEGIN
        RAISERROR(
                     'Proc: %s Step: %s Licence Error %s '
                    ,16
                    ,1
                    ,@ProcedureName
                    ,@ProcedureStep
                    ,'Please install the License.'
                 );

        RETURN 5;
    END;

    RETURN @ErrorCode;
END TRY -- update license check check status > 4
BEGIN CATCH
    SET @DebugText = @@Error;
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'License check failed';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ErrorCode);
    END;

    SET @StartTime = GETUTCDATE();
    SET @LogStatus = 'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
        IF
        (
            SELECT COUNT(*)
            FROM [dbo].[MFLog]
            WHERE [ErrorNumber] = 90004
                  AND [CreateDate] > DATEADD(DAY, -1, GETDATE())
        ) = 0
        BEGIN

    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[ErrorLine]
       ,[ProcedureStep]
    )
    VALUES
    (@ProcedureName, 90004, ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE()
    ,@ProcedureStep);

    SET @ProcedureStep = 'Catch Error';
END
    /*
    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Error'
                                        ,@LogText = @LogTextDetail
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Error'
                                              ,@LogText = @LogTextDetail
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = null
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = null
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

*/
    RETURN @ErrorCode;
END CATCH;

GO