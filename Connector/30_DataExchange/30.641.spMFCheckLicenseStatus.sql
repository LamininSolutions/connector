PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCheckLicenseStatus' -- nvarchar(100)
                                    ,@Object_Release = '4.4.13.53'            -- varchar(50)
                                    ,@UpdateFlag = 2;                        -- smallint
GO

/*
Modifications
2018-07-09		lc	Change name of MFModule table to MFLicenseModule
2019-1-19		LC	Add return values
2019-09-15      LC  Redo licensing logic, only update license every 10 days
*/

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
   ,@Debug INT = 0
AS
SET NOCOUNT ON
    DECLARE @ModuleID NVARCHAR(20);
    DECLARE @Status NVARCHAR(20);
    DECLARE @VaultSettings NVARCHAR(2000);
    DECLARE @ModuleErrorMessage NVARCHAR(MAX);

    SET @ProcedureStep = 'Validate License ';
--DROP TABLE MFModule;

DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- Get settings
-------------------------------------------------------------
SELECT @VaultSettings = [dbo].[FnMFVaultSettings]()
-------------------------------------------------------------
-- Get module
-------------------------------------------------------------

SELECT @ModuleID = module FROM setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Name] = @InternalProcedureName

SELECT @ModuleID = ISNULL(@ModuleID,'1')
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

SET @DebugText = ' Module %s';
SET @DebugText = @DefaultDebugText + @DebugText;
SET @ProcedureStep = 'Check if module exist';

IF @Debug > 0
BEGIN
    SELECT @ModuleID AS [module];

    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID);
END;

-------------------------------------------------------------

-------------------------------------------------------------
IF
(
    SELECT COUNT(*) FROM [MFModule] WHERE [Module] = @ModuleID
) > 0
BEGIN  -- check module of exist
    IF 
    (
        SELECT [license] FROM [MFModule] WHERE [Module] = @ModuleID
    ) IS NULL
    BEGIN

    Set @DebugText = '%s'
    Set @DebugText = @DefaultDebugText + @DebugText
    Set @Procedurestep = 'Creating new license code for module '
    
    IF @debug > 0
    	Begin
    		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep, @ModuleID );
    	END
    
    BEGIN TRY -- initialise license if not exist in MFModule
        EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                       ,@ModuleID = @ModuleID             -- nvarchar(20)
                                       ,@Status = @Status OUTPUT;       -- nvarchar(20)

Set @DebugText = '%s'
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'License Status '

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Status );
	END

        SELECT @LicenseExpiry = CONVERT(DATE, [fmss].[ListItem], 105)
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2;

        SELECT @ErrorCode = [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 1;

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
        RETURN 6
    END CATCH;

    
        UPDATE [mm]
        SET [mm].[license] = @EcryptedPassword
           ,[mm].[DateLastChecked] = GETUTCDATE()
        FROM [MFModule] [mm]
        WHERE [mm].[Module] = @ModuleID;

        Set @DebugText = 'License %s'
        Set @DebugText = @DefaultDebugText + @DebugText
        Set @Procedurestep = 'Initialise '
        
        IF @debug > 0
        	Begin
        		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@License );
        	END

    END -- end create new license
    ELSE -- license alraedy exist and can be checked
    BEGIN
        -------------------------------------------------------------
        -- Validate license
        -------------------------------------------------------------
        SELECT @EcryptedPassword = [license]
        FROM [MFModule]
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
            = ' Module %s ResultCode %s Expiry Date ' + CONVERT(NVARCHAR, @ExpiryDate, 105) + ' Last Validated '
              + CONVERT(NVARCHAR, @LastValidate, 105);
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'licence check result';

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
        DECLARE @RemainingDays   INT
               ,@lastCheckedDays INT;

        SELECT @RemainingDays   = DATEDIFF(DAY, GETUTCDATE(), CONVERT(DATETIME, @ExpiryDate, 105))
              ,@lastCheckedDays = DATEDIFF(DAY, @LastValidate, GETUTCDATE());

        SET @DebugText = ' Remaining Days %i LastCheckedDays %i ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'License expire';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemainingDays, @lastCheckedDays);
        END;
END
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
                                           ,@ModuleID = @ModuleID             -- nvarchar(20)
                                           ,@Status = @Status OUTPUT;       -- nvarchar(20)

            SELECT @LicenseExpiry = CONVERT(DATE, [fmss].[ListItem], 105)
            FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
            WHERE [fmss].[ID] = 2;
        SELECT @ErrorCode = [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 1;

            SELECT @license = @ModuleID + '|' + @Status + '|' + CAST(CONVERT(DATE, GETDATE()) AS VARCHAR(10));

            EXEC [dbo].[spMFEncrypt] @Password = @license                          -- nvarchar(2000)
                                    ,@EcryptedPassword = @EcryptedPassword OUTPUT; -- nvarchar(2000)

            UPDATE [mm]
            SET [mm].[license] = @EcryptedPassword
               ,[mm].[DateLastChecked] = GETUTCDATE()
            FROM [MFModule] [mm]
            WHERE [mm].[Module] = @ModuleID;

            
        Set @DebugText = 'License %s'
        Set @DebugText = @DefaultDebugText + @DebugText
        Set @Procedurestep = 'Refresh '
        
        IF @debug > 0
        	Begin
        		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@License );
        	END

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

-------------------------------------------------------------
-- Report error codes
-------------------------------------------------------------

            
        Set @DebugText = ' ErrorCode %s'
        Set @DebugText = @DefaultDebugText + @DebugText
        Set @Procedurestep = 'License validity '

        
        IF @ErrorCode = '2'
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'License is not valid.');

            RETURN 2;
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

          RETURN 3;
        END;

        IF @ErrorCode = '4'
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'Invalid License key.');

           RETURN 4;
        END;
        
        IF @ErrorCode = '5'
        BEGIN
            RAISERROR(
                         'Proc: %s Step: %s ErrorInfo %s '
                        ,16
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,'Please install the License.'
                     );

            RETURN 5;
        END;

        IF @debug > 0
        	Begin
        		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@ErrorCode );
        	END
        RETURN @ErrorCode;
END; -- module is valid
ELSE
BEGIN
    RAISERROR('Module is invalid', 16, 1);
END;

GO