

/*
Migration script for  Settings

to check for existing entries and migrate the new settings definition into the existing table

*/


SET NUMERIC_ROUNDABORT OFF;
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON;
GO
SET XACT_ABORT ON;
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
	
DECLARE @rc INT
      , @msg AS VARCHAR(250)
      , @DBname NVARCHAR(100) = DB_NAME();

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + 'Migration of Settings table';

SELECT  @rc = COUNT(*)
FROM    [dbo].[MFSettings];

SET @msg = SPACE(5) + DB_NAME() + ' : settings migrated: ';
RAISERROR('%s',10,1,@msg); 

BEGIN TRANSACTION;

SELECT  *
INTO    [#Settings_temp]
FROM    [dbo].[MFSettings];


TRUNCATE TABLE [dbo].[MFSettings];



INSERT  [dbo].[MFSettings]
        ( [source_key], [Name], [Description], [Value], [Enabled] )
VALUES  ( N'Email', N'SupportEmailRecipient', N'Email account for recipient of automated support mails',
          N'{SupportEmail}', 1 ),
        ( N'Email', N'SupportEMailProfile', N'SupportEMailProfile', N'{EmailProfile}', 1 ),
        ( N'MF_Default', N'VaultGUID', N'GUID of the vault', N'{VaultGUID}', 1 ),
        ( N'MF_Default', N'ServerURL', N'Server URL', N'{ServerURL}', 1 ),
        ( N'MF_Default', N'MFInstallPath', N'Path of MFiles installation on server', N'C:\Program Files\M-Files', 1 ),
        ( N'MF_Default', N'MFVersion', N'Version Number of MFiles', N'{MFVersion}', 1 ),
        ( N'App_Default', N'App_Database', N'Database of Connector', N'{varAppDB}', 1 ),
		( N'App_Default', N'App_DetailLogging', N'ProcessBatch Update is active', N'{DetailLogging}', 1 ),
        ( N'App_Default', N'AssemblyInstallPath', N'Path where the Assemblies have been saved on the SQL Server',
          N'{CLRPath}', 1 ),
        ( N'App_Default', N'AppUserRole', N'Database App User role', N'{varAppDBRole}', 1 ),
        ( N'App_Default', N'AppUser', N'Database App User', N'{varAppLogin_Name}', 1 ),
	    (
	      'Files_Default'   -- source_key - nvarchar(20)
	   , 'RootFolder' -- Name - varchar(50)
	   , 'Root folder for exporting files from M-Files'-- Description - varchar(500)
	   , '' -- Value - sql_variant
	    ,1-- Enabled - bit
	    )

-- migrate existing settings
--SELECT * FROM [dbo].[MFSettings] AS [s]
--DELETE MFsettings WHERE id > 9
UPDATE  [s]
SET     [s].[Value] = [st].[Value]
FROM    [dbo].[MFSettings] [s]
INNER JOIN [#Settings_temp] [st] ON [s].[Name] = [st].[Name];


--SELECT * FROM [dbo].[MFSettings] AS [s]

--migrate custom settings 
INSERT  INTO [dbo].[MFSettings]
        ( [source_key]
        , [Name]
        , [Description]
        , [Value]
        , [Enabled]
        )
        SELECT  [st].[source_key]
              , [st].[Name]
              , [st].[Description]
              , [st].[Value]
              , [st].[Enabled]
        FROM    [dbo].[MFSettings] [s]
        FULL OUTER JOIN [#Settings_temp] [st] ON [s].[Name] = [st].[Name]
        WHERE   [s].[Name] IS NULL;
/*
SELECT  * FROM    MFSettings;
*/
DROP TABLE [#Settings_temp];

SELECT  @rc = COUNT(*)
FROM    [dbo].[MFSettings];
IF @rc > 0
   RAISERROR('%s (%d records)',10,1,@msg,@rc); 


COMMIT TRAN

GO

            