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
2019-09-20      LC  parameterise email notification, send only 1 email a day
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
   ,@ExpiryNotification INT = 30
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

SELECT @ModuleID = [moc].[Module] FROM [setup].[MFSQLObjectsControl] AS [moc] WHERE [moc].[Name] = @InternalProcedureName

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
DECLARE @LicenseExpiryTXT  NVARCHAR(10)

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
Set @Procedurestep = 'Pre-checks '


Declare @Checkstatus int = 0

Select @CheckStatus = case when  (select count(*) from [sys].[objects] where name = 'MFModule') <> 1 then 1 --MFModule table does not exist
when (SELECT COUNT(*) FROM [dbo].[MFModule] WHERE [Module] = @ModuleID) <> 1 then 2 -- Module not in table
when (SELECT isnull(license,'') FROM [dbo].[MFModule] WHERE [Module] = @ModuleID) = '' then 3
ELSE 9
end



if @Checkstatus > 3
Begin
Select @license = license from [dbo].[MFModule] where module = @ModuleID

        EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @license          -- nvarchar(2000)
                                ,@DecryptedPassword = @license OUTPUT; -- nvarchar(2000)

IF @Debug > 0
begin
SELECT *
        FROM [dbo].[fnMFParseDelimitedString](@license, '|')
END



Select @checkstatus = case when NOT exists(SELECT *

        FROM [dbo].[fnMFParseDelimitedString](@license, '|') AS [fmss]
        WHERE [fmss].[ID] = 4) then 4
        ELSE 9
		end


END


if  @Checkstatus = 1
BEGIN  -- check MFmodule of exist
Set @DebugText = 'MFModule does not exist Checkstatus %i'
END

IF @Checkstatus = 2
BEGIN  -- check module of exist
Set @DebugText = 'Module does not exist Checkstatus %i'
END

IF @Checkstatus = 3
BEGIN  -- check license initialised
Set @DebugText = 'license has not yet been initialised Checkstatus %i'
END

IF @Checkstatus = 4
BEGIN  -- check Expiry date exist
SET @ErrorCode = 2
Set @DebugText = 'License Assembly is invalid Checkstatus %i'
END

IF @Checkstatus > 4
BEGIN  -- check Expiry date exist
Set @DebugText = 'License is valid Checkstatus %i'
END

Set @DebugText = @DefaultDebugText + @DebugText
IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Checkstatus );
	END

    -------------------------------------------------------------
-- initialise license
-------------------------------------------------------------
Set @Procedurestep = 'initialise license'

if @Checkstatus = 3
Begin
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

Set @DebugText = ' Return spMFValidateModule module %s Status %s  '
Set @DebugText = @DefaultDebugText + @DebugText

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@ModuleID,@status );
	END
    SELECT @LicenseExpiryTXT =  [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2;
        SELECT @LicenseExpiry = case when LEN(@LicenseExpiryTXT)>0 THEN dbo.fnMFTextToDate(@LicenseExpiryTXT,'/')
		else convert(date,dateadd(DAY,1,GetDate()))
		END
        SELECT @ErrorCode = [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 1;

Set @ProcedureStep = 'Get Status'

Set @DebugText = ' License expiry '+cast(@licenseExpiry as nvarchar(25))+ ' ErrorCode %s  '
Set @DebugText = @DefaultDebugText + @DebugText

IF @Debug > 0
BEGIN
    SELECT @LicenseExpiry, @ErrorCode;

    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@ErrorCode);
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
        RETURN 6
    END CATCH;

    
        UPDATE [mm]
        SET [mm].[license] = @EcryptedPassword
           ,[mm].[DateLastChecked] = GETUTCDATE()
        FROM [dbo].[MFModule] [mm]
        WHERE [mm].[Module] = @ModuleID;

        SET @Checkstatus = 9

        Set @DebugText = 'License %s'
        Set @DebugText = @DefaultDebugText + @DebugText
        Set @Procedurestep = 'Initialise '
        
        IF @debug > 0
        	Begin
        		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@License );
        	END

    END -- end create new license


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

            IF (SELECT COUNT(*) FROM MFlog WHERE [ErrorNumber] = 90003 AND [CreateDate] > DATEADD(DAY,-1,GETDATE())) = 0
            Begin
            --------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , 90003
					 , ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate)
					 , ERROR_PROCEDURE()
					 , 'WARNING'
					 , 0
					 , 0
					 , @ProcedureStep
				   );
            END

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END; --remaining days < 30

        END --validate license checkstatus > 4

        -------------------------------------------------------------
        -- LICENSE REQUIRE RECHECKING
        -------------------------------------------------------------
        IF @lastCheckedDays > 0 AND @Checkstatus > 4
        BEGIN TRY
            EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                                           ,@ModuleID = @ModuleID             -- nvarchar(20)
                                           ,@Status = @Status OUTPUT;       -- nvarchar(20)

    SELECT @LicenseExpiryTXT =  [fmss].[ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@Status, '|') AS [fmss]
        WHERE [fmss].[ID] = 2;

        SELECT @LicenseExpiry = case when LEN(@LicenseExpiryTXT)>0 THEN dbo.fnMFTextToDate(@LicenseExpiryTXT,'/')
		else convert(date,dateadd(DAY,1,GetDate()))
		END
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

        IF @RemainingDays <= @ExpiryNotification
        BEGIN
            SET @DebugText = ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate);
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Expiry Notification ';

            IF (SELECT COUNT(*) FROM MFlog WHERE [ErrorNumber] = 90003 AND [CreateDate] > DATEADD(DAY,-1,GETDATE())) = 0
            Begin
            --------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , 90003
					 , ' License is expiring on ' + CONVERT(NVARCHAR(25), @ExpiryDate)
					 , ERROR_PROCEDURE()
					 , 'WARNING'
					 , 0
					 , 0
					 , @ProcedureStep
				   );
            END

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END; --remain days < 30
        END TRY -- update license check check status > 4
        BEGIN CATCH
            SET @DebugText = @@Error;
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'License check failed';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END CATCH; --update license check




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


GO