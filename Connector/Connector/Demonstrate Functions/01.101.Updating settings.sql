
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
To work through the examples, select the statement as execute (F5)
*/

/*
Updating the settings 

The settings can be updated by rerunning the installation packages.
Alternatively procedures can be used.
a) Updating vault connection settings
b) Updating standard Connector settings
*/

-- CHECK VAULT SETTINGS
-- check out the settings table 
Select * from mfvaultsettings

--What if there is a problem with the connection to the vault?:  

--Inspect the settings. Table MFVaultSettings show the settings to connect to M-Files.  MFSettings table show the other settings for the Connector.

SELECT * FROM   [MFvwVaultSettings]

--or use the function to provide vault connection settings string

SELECT [dbo].[FnMFVaultSettings]()

-- note that some settings is in the MFSettings table, these settings relate to the DB settings.

SELECT * FROM  [dbo].[MFSettings] AS [ms]

--updating the M-Files user name
EXEC [spMFSettingsForVaultUpdate] @Username = 'Admin'

--change the password

EXEC spmfsettingsForVaultUpdate @Password = 'MotSys123'

--perform procedure to show a connection error

DECLARE @MessageOut NVARCHAR(50);

EXEC [dbo].[spMFVaultConnectionTest] @MessageOut = @MessageOut OUTPUT

SELECT @MessageOut

--RESET VAULT CONNECTION SETTINGS
-- run update by running installation again ; or use the following proc to update. only set the parameter values which need to be updated.
-- note that is is only necessary to specify the settings that need the change

	DECLARE @RC INT
DECLARE @Username NVARCHAR(100) = 'MFSQLConnect'
	DECLARE @Password NVARCHAR(100) = 'Connector01'
	DECLARE @NetworkAddress NVARCHAR(100)
	DECLARE @Vaultname NVARCHAR(100) 
	DECLARE @MFProtocolType_ID INT = 1
	DECLARE @Endpoint INT = 2266
	DECLARE @MFAuthenticationType_ID INT = 4
	DECLARE @Domain NVARCHAR(128) 
	DECLARE @VaultGUID NVARCHAR(128)
	DECLARE @ServerURL NVARCHAR(128)
	DECLARE @Debug SMALLINT

	EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] @Username
												   , @Password
												   , @NetworkAddress
												   , @Vaultname
												   , @MFProtocolType_ID
												   , @Endpoint
												   , @MFAuthenticationType_ID
												   , @Domain
												   , @VaultGUID
												   , @ServerURL
												   , @Debug
GO

SELECT * FROM [dbo].[MFProtocolType] AS [mpt]
--the Protocol type and authentication type are referenced in other tables

SELECT * FROM [dbo].[MFVaultSettings] AS [mvs]
LEFT JOIN [dbo].[MFProtocolType] AS [mpt]
ON mvs.[MFProtocolType_ID] = mpt.[ID]
LEFT JOIN [dbo].[MFAuthenticationType] AS [mat]
ON mvs.[MFAuthenticationType_ID] = mat.[ID]


--UPDATING / CHANGING DATABASE SETTINGS 
-- To make changes to the other Connector settings:
-- note that these changes can also be made by re-running the installation package
-- only specify the items that should change
-- to add multiple users to the support email, separate the email addresses by ; eg 'myemail@gmail.com;support@lamininsolutions.lcom'

DECLARE 
@MFInstallationPath	nvarchar(128),
@MFilesVersion	nvarchar(128),
@AssemblyInstallationPath	nvarchar(128),
@SQLConnectorLogin	nvarchar(128),
@UserRole	nvarchar(128),
@SupportEmailAccount	nvarchar(128),
@EmailProfile	nvarchar(128),
@DetailLogging	nvarchar(128),
@DBName	nvarchar(128),
@RootFolder	nvarchar(128),
@FileTransferLocation	nvarchar(128),
@Debug	SMALLINT;


EXEC [dbo].[spMFSettingsForDBUpdate] @MFInstallationPath = @MFInstallationPath       -- nvarchar(128)
                                    ,@MFilesVersion = @MFilesVersion            -- nvarchar(128)
                                    ,@AssemblyInstallationPath = @AssemblyInstallationPath -- nvarchar(128)
                                    ,@SQLConnectorLogin = @SQLConnectorLogin        -- nvarchar(128)
                                    ,@UserRole = @UserRole                 -- nvarchar(128)
                                    ,@SupportEmailAccount = @SupportEmailAccount      -- nvarchar(128)
                                    ,@EmailProfile = @EmailProfile             -- nvarchar(128)
                                    ,@DetailLogging = @DetailLogging            -- nvarchar(128)
                                    ,@DBName = @DBName                   -- nvarchar(128)
                                    ,@RootFolder = @RootFolder               -- nvarchar(128)
                                    ,@FileTransferLocation = @FileTransferLocation     -- nvarchar(128)
                                    ,@Debug = @Debug                    -- smallint
                              


					
