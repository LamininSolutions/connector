PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFVaultConnectionTest]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFVaultConnectionTest' -- nvarchar(100)
                                    ,@Object_Release = '4.5.14.56'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*

Add license check into connection test
Add check and update MFVersion if invalid
add is silent option

*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFVaultConnectionTest' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFVaultConnectionTest]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFVaultConnectionTest]
    @IsSilent INT = 0
   ,@MessageOut NVARCHAR(250) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;


    /*
Procedure to perform a test on the vault connection

Created by : Leroux@lamininsolutions.com
Date: 2016-8

Usage

Exec  spMFVaultConnectionTest 

Change log
2020-02-08  LC     Fix bug for check license validation


*/
    SET NOCOUNT ON;

    DECLARE @Return_Value INT;
    DECLARE @vaultsettings NVARCHAR(4000)
           ,@ReturnVal     NVARCHAR(MAX);

    SELECT @vaultsettings = [dbo].[FnMFVaultSettings]();

    BEGIN TRY
        DECLARE @IsUpToDate BIT
               ,@RC         INT;

        EXEC @RC = [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

        IF @RC < 0
        BEGIN
            SET @MessageOut = 'Unable to Connect';
		--	SELECT @MessageOut

            RAISERROR('Error:  %s - Check MFlog or email for error detail', 16, 1, @MessageOut)
			RETURN;
        END;

        --SELECT @rc, @IsUpToDate

        -------------------------------------------------------------
        -- validate MFiles version
        -------------------------------------------------------------
   --     EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion];

        -------------------------------------------------------------
        -- validate login
        -------------------------------------------------------------

        --EXEC [dbo].[spMFGetUserAccounts] @VaultSettings = @vaultsettings -- nvarchar(4000)
        --                                ,@returnVal = @ReturnVal OUTPUT; -- nvarchar(max)
        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,[mvs].[Password] AS [EncryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            SET @MessageOut = 'Successfully connected to vault';

            SELECT @MessageOut AS [OutputMessage];
        END;

        SET @Return_Value = 1;
    END TRY
    BEGIN CATCH
        SET @MessageOut = ERROR_MESSAGE();

        IF @IsSilent = 0
            SELECT @MessageOut AS [OutputMessage];

        DECLARE @EncrytedPassword NVARCHAR(100);

        SELECT TOP 1
               @EncrytedPassword = [mvs].[Password]
        FROM [dbo].[MFVaultSettings] AS [mvs];

        DECLARE @DecryptedPassword NVARCHAR(100);

        EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @EncrytedPassword          -- nvarchar(2000)
                                ,@DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,@DecryptedPassword AS [DecryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            PRINT ERROR_MESSAGE();
        END;
    END CATCH;

   -- DECLARE @messageOut NVARCHAR(50)

    SET @MessageOut = 'License is not validated'


--    IF @Return_Value = 1
    BEGIN
        BEGIN TRY

        EXEC @return_value= dbo.spMFCheckLicenseStatus @InternalProcedureName = N'spmfGetclass',               -- nvarchar(500)
                                @ProcedureName = N'spMFVaultConnectionTest',                       -- nvarchar(500)
                                @ProcedureStep = 'Validate License:',                      -- sysname
                                @ExpiryNotification = 0,                    -- int
                                @IsLicenseUpdate = 1,                    -- bit
                                @Debug = 0                                 -- int

          IF @Return_Value = 1
          Begin
          SET @MessageOut = 'Validated License'
          END
          ELSE
          BEGIN
         
          SET @MessageOut = 'License is invalid'
           END         


            --   SELECT @Return_Value;
            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];

            RETURN 1;
        END TRY
        BEGIN CATCH
            SET @MessageOut = 'Invalid License: ' + ERROR_MESSAGE();

            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];
        END CATCH;
    END;
END;
