

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSettingsForVaultUpdate]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSettingsForVaultUpdate', -- nvarchar(100)
    @Object_Release = '3.1.5.41',                -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific settings
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			change settings index
	2016-10-12		LC			Update procedure to allow for updating of settings into the new MFVaultSettings Table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFSettingsForVaultUpdate]   
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSettingsForVaultUpdate' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: updated';
    --		DROP PROCEDURE dbo.[spMFSettingsForVaultUpdate]
    SET NOEXEC ON;

END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSettingsForVaultUpdate]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE dbo.spMFSettingsForVaultUpdate
(
    @Username NVARCHAR(100) = NULL,       --  M-Files user with vault admin rights
    @Password NVARCHAR(100) = NULL,       -- the password will be encrypted 
    @NetworkAddress NVARCHAR(100) = NULL, -- N'laminindev.lamininsolutions.com' -Vault server URL from SQL server
    @Vaultname NVARCHAR(100) = NULL,      -- vault name 
    @MFProtocolType_ID INT = NULL,        -- select items from list in MFProtocolType
    @Endpoint INT = NULL,                 -- default 2266
    @MFAuthenticationType_ID INT = NULL,  -- select item from list of MFAutenticationType
    @Domain NVARCHAR(128) = NULL,
    @VaultGUID NVARCHAR(128) = NULL,      -- N'CD6AEE8F-D8F8-413E-AB2C-398B50097D39' GUID from M-Files admin
    @ServerURL NVARCHAR(128) = NULL,      --- N'laminindev.lamininsolutions.com' Web Address of M-Files
	 @RootFolder nvarchar(128) = null,
	 @FileTransferLocation nvarchar(128) = null,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

==========================
spMFsettingsForVaultUpdate
==========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Username nvarchar(100)
    fixme description
  @Password nvarchar(100)
    fixme description
  @NetworkAddress nvarchar(100)
    fixme description
  @Vaultname nvarchar(100)
    fixme description
  @MFProtocolType\_ID int
    fixme description
  @Endpoint int
    fixme description
  @MFAuthenticationType\_ID int
    fixme description
  @Domain nvarchar(128)
    fixme description
  @VaultGUID nvarchar(128)
    fixme description
  @ServerURL nvarchar(128)
    fixme description
  @RootFolder nvarchar(128)
    fixme description
  @FileTransferLocation nvarchar(128)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN



    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM [dbo].[MFVaultSettings] AS [mvs])
    BEGIN

        INSERT INTO [dbo].[MFVaultSettings]
        (
            [Username],
            [Password],
            [NetworkAddress],
            [VaultName],
            [MFProtocolType_ID],
            [Endpoint],
            [MFAuthenticationType_ID],
            [Domain]
        )
        VALUES
        (   '',              -- Username - nvarchar(128)
            NULL,            -- Password - nvarchar(128)
            N'localhost',    -- NetworkAddress - nvarchar(128)
            N'Sample Vault', -- VaultName - nvarchar(128)
            1,               -- MFProtocolType_ID - int
            2266,            -- Endpoint - int
            4,               -- MFAuthenticationType_ID - int
            N''              -- Domain - nvarchar(128)
        );
    END;

    BEGIN

        DECLARE @Prev_Username NVARCHAR(100),
            @Prev_Password NVARCHAR(100),
            @Prev_NetworkAddress NVARCHAR(100),
            @Prev_Vaultname NVARCHAR(100),
            @Prev_MFProtocolType_ID INT,
            @Prev_Endpoint INT,
            @Prev_MFAuthenticationType_ID INT,
            @Prev_Domain NVARCHAR(128),
            @Prev_VaultGUID NVARCHAR(128),
            @Prev_ServerURL NVARCHAR(128);

        SELECT @Prev_Username = Username,
            @Prev_Password = [Password],
            @Prev_NetworkAddress = NetworkAddress,
            @Prev_Vaultname = VaultName,
            @Prev_MFProtocolType_ID = MFProtocolType_ID,
            @Prev_Endpoint = [Endpoint],
            @Prev_MFAuthenticationType_ID = MFAuthenticationType_ID,
            @Prev_Domain = Domain
        FROM dbo.MFVaultSettings AS MVS;

        SELECT @Prev_VaultGUID = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        SELECT @Prev_ServerURL = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT @Prev_Username AS Username,
                @Prev_Password AS [Password],
                @Prev_NetworkAddress AS NetworkAddress,
                @Prev_Vaultname AS Vaultname,
                @Prev_MFProtocolType_ID AS MFProtocolType_ID,
                @Prev_Endpoint AS [Endpoint],
                @Prev_MFAuthenticationType_ID AS MFAuthenticationType_ID,
                @Prev_Domain AS Domain,
                @Prev_VaultGUID AS VaultGuid,
                @Prev_ServerURL AS ServerURL;



        UPDATE mfs
        SET Username = CASE
                           WHEN @Username <> @Prev_Username
                                AND @Username IS NOT NULL THEN
                               @Username
                           ELSE
                               @Prev_Username
                       END,
            NetworkAddress = CASE
                                 WHEN @NetworkAddress <> @Prev_NetworkAddress
                                      AND @NetworkAddress IS NOT NULL THEN
                                     @NetworkAddress
                                 ELSE
                                     @Prev_NetworkAddress
                             END,
            VaultName = CASE
                            WHEN @Vaultname <> @Prev_Vaultname
                                 AND @Vaultname IS NOT NULL THEN
                                @Vaultname
                            ELSE
                                @Prev_Vaultname
                        END,
            MFProtocolType_ID = CASE
                                    WHEN @MFProtocolType_ID <> @Prev_MFProtocolType_ID
                                         AND @MFProtocolType_ID IS NOT NULL THEN
                                        @MFProtocolType_ID
                                    ELSE
                                        @Prev_MFProtocolType_ID
                                END,
            [Endpoint] = CASE
                             WHEN @Endpoint <> @Prev_Endpoint
                                  AND @Endpoint IS NOT NULL THEN
                                 @Endpoint
                             ELSE
                                 @Prev_Endpoint
                         END,
            MFAuthenticationType_ID = CASE
                                          WHEN @MFAuthenticationType_ID <> @Prev_MFAuthenticationType_ID
                                               AND @MFAuthenticationType_ID IS NOT NULL THEN
                                              @MFAuthenticationType_ID
                                          ELSE
                                              @Prev_MFAuthenticationType_ID
                                      END,
            Domain = CASE
                         WHEN @Domain <> @Prev_Domain
                              AND @Domain IS NOT NULL THEN
                             @Domain
                         ELSE
                             @Prev_Domain
                     END
        FROM MFVaultSettings mfs;

        IF @Debug > 0
            SELECT CASE
                       WHEN @VaultGUID IS NOT NULL
                            AND @VaultGUID <> @Prev_VaultGUID THEN
                           CONVERT(SQL_VARIANT, @VaultGUID)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                   END AS VaultGUID;

        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @VaultGUID IS NOT NULL
                             AND @VaultGUID <> @Prev_VaultGUID THEN
                            CONVERT(SQL_VARIANT, @VaultGUID)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                    END
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT CASE
                       WHEN @ServerURL <> @Prev_ServerURL
                            AND @ServerURL IS NOT NULL THEN
                           CONVERT(SQL_VARIANT, @ServerURL)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_ServerURL)
                   END;


        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @ServerURL <> @Prev_ServerURL
                             AND @ServerURL IS NOT NULL THEN
                            CONVERT(SQL_VARIANT, @ServerURL)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_ServerURL)
                    END
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';


        IF @Password IS NOT NULL
        BEGIN



            DECLARE @EncryptedPassword NVARCHAR(250);
            DECLARE @PreviousPassword NVARCHAR(100);


            SELECT TOP 1
                @PreviousPassword = [Password]
            FROM dbo.MFVaultSettings s;

            IF @Debug = 1
                SELECT @EncryptedPassword AS '@EncryptedPassword',
                    @PreviousPassword AS '@PreviousPassword';

            IF @PreviousPassword IS NULL
                EXEC [dbo].[spMFEncrypt] @Password = N'null', -- nvarchar(2000)
                    @EcryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000);


            EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @PreviousPassword, -- nvarchar(2000)
                @DecryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000)
        END;

        IF @Password IS NOT NULL
           AND @Password <> @PreviousPassword
        BEGIN

            EXECUTE dbo.spMFEncrypt @Password, @EncryptedPassword OUT;

            UPDATE s
            SET [s].[Password] = @EncryptedPassword
            FROM dbo.MFVaultSettings s;


        END;
    END;


    RETURN 1;
END;


GO
