

/*
Migration script for  Settings

to check for existing entries and migrate the new settings definition into the existing table

Last Modified: 
2019-1-9	lc	Exclude MFversion from begin overwritten from SQL, show message when installing manually
2019-1-26	lc	fix futher bug on MFVersion not being updated when version changed.
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

--SELECT  @rc = COUNT(*)
--FROM    [dbo].[MFSettings];

SET @msg = SPACE(5) + DB_NAME() + ' : settings migrated: ';
RAISERROR('%s',10,1,@msg); 

BEGIN TRANSACTION;


IF ISNULL(@rc,0) = 0
BEGIN


IF (SELECT object_id('Tempdb..##Settings_temp'))IS NOT NULL
DROP TABLE ##Settings_temp;

SELECT  *
INTO    [#Settings_temp]
FROM    [dbo].[MFSettings];


TRUNCATE TABLE [dbo].[MFSettings];



INSERT  [dbo].[MFSettings]
        ( [source_key], [Name], [Description], [Value], [Enabled] )
VALUES  ( N'Email', N'SupportEmailRecipient', N'Email account for recipient of automated support mails',
          N'{varITSupportEmail}', 1 ),
        ( N'Email', N'SupportEMailProfile', N'SupportEMailProfile', N'{varEmailProfile}', 1 ),
        ( N'MF_Default', N'MFInstallPath', N'Path of MFiles installation on server', N'{varMFInstallPath}', 1 ),
        ( N'MF_Default', N'MFVersion', N'Version Number of MFiles', N'{varMFVersion}', 1 ),
        ( N'App_Default', N'App_Database', N'Database of Connector', N'{varAppDB}', 1 ),
		( N'App_Default', N'App_DetailLogging', N'ProcessBatch Update is active', N'{varLoggingRequired}', 1 ),
        ( N'App_Default', N'AssemblyInstallPath', N'Path where the Assemblies have been saved on the SQL Server',
          N'{varCLRPath}', 1 ),
        ( N'App_Default', N'AppUserRole', N'Database App User role', N'{varAppDBRole}', 1 ),
        ( N'App_Default', N'AppUser', N'Database App User', N'{varAppLogin_Name}', 1 ),
	    (
	      'Files_Default'   
	   , 'RootFolder' 
	   , 'Root folder for exporting files from M-Files'
	   , '{varExportFolder}' 
	    ,1),
	    (
	      'Files_Default'   
	   , 'FileTransferLocation' 
	   , 'Folder temporary filing of imported files from database to M-Files'
	   , '{varImportFolder}' 
	    ,1
		),
('MF_Default', 'LastMetadataStructureID', 'Latest Metadata structure ID', '1', 1),
('MF_Default', 'MFUserMessagesEnabled', 'Enable Update of User Messages in M-Files', '0', 1)

IF '{varMFVersion}' <> (SELECT CAST(VALUE AS NVARCHAR(100)) FROM MFSETTINGS WHERE Name = 'MFVersion')
BEGIN
RAISERROR('MF Version in MFSettings differ from Installation package - package version is applied',10,1)
END
 


UPDATE  [s]
SET     [s].[Value] = [st].[Value]
FROM    [dbo].[MFSettings] [s]
INNER JOIN [#Settings_temp] [st] ON [s].[Name] = [st].[Name]
WHERE st.name NOT IN ('MFVersion')

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

END

SELECT  @rc = COUNT(*)
FROM    [dbo].[MFSettings];
IF @rc > 0
   RAISERROR('%s (%d records)',10,1,@msg,@rc); 


COMMIT TRAN

GO

            
