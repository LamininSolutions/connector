

/*

*/
--Created on: 2019-09-13 
;
--DROP TABLE MFModule;

DECLARE @ProcedureName AS NVARCHAR(128) = 'schema.procname';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'license validation';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;
DECLARE @Debug INT = 1;
DECLARE @Module NVARCHAR(20) = 1;

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

DECLARE @VaultSettings NVARCHAR(400) = [dbo].[FnMFVaultSettings]();
DECLARE @ModuleList NVARCHAR(100) = '1,2,3,4';
DECLARE @Status NVARCHAR(20);
DECLARE @license NVARCHAR(400);
DECLARE @DecryptedPassword NVARCHAR(2000);
DECLARE @EcryptedPassword NVARCHAR(2000);
DECLARE @ErrorCode  NVARCHAR(5)
       ,@ExpiryDate NVARCHAR(10);
DECLARE @LicenseExpiry DATETIME;
DECLARE @LastValidate DATETIME;
DECLARE @RT INT;

SET @DebugText = ' Module %s';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'Check if module exist';

IF @Debug > 0
BEGIN
    SELECT @Module AS [module];

    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Module);
END;

-------------------------------------------------------------
--pre-check
-------------------------------------------------------------
DECLARE @Checkstatus INT = 0;

SELECT @Checkstatus = CASE
                          WHEN
(
    SELECT COUNT(*) FROM [sys].[objects] WHERE [name] = 'MFModule'
)   <> 1 THEN
                              1 --MFModule table does not exist
                          WHEN
(
    SELECT COUNT(*) FROM [dbo].[MFModule] WHERE [Module] = @Module
)   <> 1 THEN
                              2 -- Module not in table
                          WHEN
(
    SELECT ISNULL([license], '')
    FROM [dbo].[MFModule]
    WHERE [Module] = @Module
)   = '' THEN
                              3
                          ELSE
                              9
                      END;

IF @Checkstatus > 3
BEGIN
    SELECT @license = [license]
    FROM [dbo].[MFModule]
    WHERE [Module] = @Module;

    EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @license         -- nvarchar(2000)
                            ,@DecryptedPassword = @license OUTPUT; -- nvarchar(2000)

    SELECT *
    FROM [dbo].[fnMFParseDelimitedString](@license, '|');

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
    RAISERROR('MFModule does not exist', 16, 1);
END;

IF @Checkstatus = 2
BEGIN -- check module of exist
    RAISERROR('Module does not exist', 16, 1);
END;

IF @Checkstatus = 3
BEGIN -- check Expiry date exist
    RAISERROR('license has not yet been initialised', 16, 1);
END;

IF @Checkstatus = 4
BEGIN -- check Expiry date exist
    RAISERROR('license is set to expired', 10, 1);
END;

SET @DebugText = ' CheckStatus %i';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'Pre-checks';

IF @Debug > 0
BEGIN
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Checkstatus);
END;

-------------------------------------------------------------
-- initialise license
-------------------------------------------------------------
SET @ProcedureStep = 'initialise license';

IF @Checkstatus IN ( 3, 4 )
BEGIN TRY -- initialise license if not exist in MFModule
    EXEC @RT = [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                         ,@ModuleID = @Module             -- nvarchar(20)
                                         ,@Status = @Status OUTPUT;       -- nvarchar(20)

    SET @DebugText = ' Return spMFValidateModule module %s Status %s  ';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Module, @Status);
    END;

    SELECT @LicenseExpiry = CASE
                                WHEN @Checkstatus = 3 THEN
    (
        SELECT CONVERT(DATE, [fmss].[ListItem], 105)
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2
    )
                                ELSE
                                    CONVERT(DATE, DATEADD(DAY, 1, GETDATE()), 105)
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

    SELECT @license = @Module + '|' + @Status + '|' + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10));

    EXEC [dbo].[spMFEncrypt] @Password = @license                          -- nvarchar(2000)
                            ,@EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

    UPDATE [mm]
    SET [mm].[license] = @EcryptedPassword
       ,[mm].[DateLastChecked] = GETUTCDATE()
    FROM [dbo].[MFModule] [mm]
    WHERE [mm].[Module] = @Module;

    SET @DebugText = 'License %s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Initialise ';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @license);
    END;
END TRY
BEGIN CATCH
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Unable to create license';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;
END CATCH;
ELSE
BEGIN
    -------------------------------------------------------------
    -- Validate license
    -------------------------------------------------------------
    SELECT @EcryptedPassword = [license]
    FROM [dbo].[MFModule]
    WHERE [Module] = @Module;

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

    SELECT @LastValidate = CASE
                               WHEN
    (
        SELECT [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@DecryptedPassword, '|') AS [fmss]
        WHERE [fmss].[ID] = 4
    )   = '' THEN
                                   DATEADD(DAY, -20, GETDATE())
                               ELSE
    (
        SELECT [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@DecryptedPassword, '|') AS [fmss]
        WHERE [fmss].[ID] = 4
    )
                           END;

    SELECT @LastValidate AS [lastvalidate];

    SET @DebugText
        = ' Module %s ResultCode %s Expiry Date ' + CONVERT(NVARCHAR, @ExpiryDate, 105) + ' Last Validated '
          + CONVERT(NVARCHAR, @LastValidate, 105);
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'licence check result';

    IF @Debug > 0
    BEGIN
        SELECT @Module
              ,@ErrorCode
              ,@ExpiryDate
              ,@LastValidate;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Module, @ErrorCode);
    END;

    -------------------------------------------------------------
    -- LICENSE EXPIRY
    -------------------------------------------------------------
    DECLARE @RemainingDays   INT
           ,@lastCheckedDays INT;

    --SELECT @RemainingDays   = DATEDIFF(DAY, GETUTCDATE(), CONVERT(DATETIME, @ExpiryDate, 105))
    --      ,@lastCheckedDays = DATEDIFF(DAY, @LastValidate, GETUTCDATE());
    SET @DebugText = ' Remaining Days %i LastCheckedDays %i ';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'License expire';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemainingDays, @lastCheckedDays);
    END;

    -------------------------------------------------------------
    -- re-check license
    -------------------------------------------------------------
    IF @RemainingDays < 30
    BEGIN
        SET @DebugText = ' License is expiring on ' + CONVERT(NVARCHAR, @ExpiryDate, 105);
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Expiry eminent: ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
    END;

    -------------------------------------------------------------
    -- LICENSE REQUIRE RECHECKING
    -------------------------------------------------------------
    IF @lastCheckedDays > 0
    BEGIN TRY
        EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                       ,@ModuleID = @Module             -- nvarchar(20)
                                       ,@Status = @Status OUTPUT;       -- nvarchar(20)

        SELECT @LicenseExpiry = CONVERT(DATE, [fmss].[ListItem], 105)
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2;

        SELECT @ErrorCode = CONVERT(DATE, [fmss].[ListItem], 105)
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 1;

        SELECT @license = @Module + '|' + @Status + '|' + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10));

        EXEC [dbo].[spMFEncrypt] @Password = @license                          -- nvarchar(2000)
                                ,@EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

        UPDATE [mm]
        SET [mm].[license] = @EcryptedPassword
           ,[mm].[DateLastChecked] = GETUTCDATE()
        FROM [dbo].[MFModule] [mm]
        WHERE [mm].[Module] = @Module;

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
            SELECT @Module
                  ,@ErrorCode
                  ,@ExpiryDate
                  ,@LastValidate;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Module, @ErrorCode);
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
        IF @RemainingDays < 30
        BEGIN
            SET @DebugText = ' License is expiring on ' + CONVERT(NVARCHAR, @ExpiryDate, 105);
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Expiry eminent: ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END;
    END TRY -- update license check
    BEGIN CATCH
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'License check failed';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
    END CATCH;

--RETURN 1
END; -- license has been created

SET @DebugText = ' ErrorCode %s';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'License validity ';

IF @ErrorCode = '2'
BEGIN
    RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'License is not valid.');

--            RETURN 2;
END;

IF @ErrorCode = '3'
BEGIN
    RAISERROR(
                 'Proc: %s Step: %s ErrorInfo %s '
                ,16
                ,1
                ,@ProcedureName
                ,@ProcedureStep
                ,'You dont have access to this module.'
             );

--            RETURN 3;
END;

IF @ErrorCode = '4'
BEGIN
    RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'Invalid License key.');

--            RETURN 4;
END;

IF @Debug > 0
BEGIN
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ErrorCode);
END;
