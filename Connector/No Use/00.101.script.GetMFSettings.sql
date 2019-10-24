
/*
Get all settings 

*/
USE {varAppDB}
GO
									
DECLARE @EDIT_WEBAPPNAME_PROP NVARCHAR(128) = 'MFSQL_Manager' -- note that this is not used in MFSettings				
DECLARE @EDIT_DBROLE_PROP NVARCHAR(128) = 'db_MFSQLConnect'
DECLARE @PATH_CLR_ASSEMBLIES NVARCHAR(128) = 'C:\Program Files (x86)\Laminin Solutions\MFSQL Connector\Assemblies'
DECLARE @EDIT_APP_USER_PROP NVARCHAR(128) = 'MFSQLConnect'
DECLARE @COMBOBOX_SQLAUTHTYPE_PROP NVARCHAR(128) = 'SQL' -- APP authentication type
DECLARE @EDIT_APP_PASSWORD_PROP NVARCHAR(128) = 'Connector01' --APP initial password
DECLARE @EDIT_MFVERSION_PROP NVARCHAR(128) = N'xx.x.xxxx.xxx'
DECLARE @PATH_MFILES_CLIENT NVARCHAR(128) = N'C:\Program Files\M-Files'


IF EXISTS (	  SELECT [name]
			  FROM	 [sys].[objects]
			  WHERE	 [type] = 'U'
					 AND [name] = 'MFsettings'
		  )
	BEGIN

		SELECT @EDIT_DBROLE_PROP = CONVERT(NVARCHAR(128), [ms].[Value])
		FROM   [dbo].[MFSettings] AS [ms]
		WHERE  [ms].[Name] = 'AppUserRole'
			   AND [ms].[source_key] = 'App_Default'

		SELECT @EDIT_APP_USER_PROP = CONVERT(NVARCHAR(128), [ms].[Value])
		FROM   [dbo].[MFSettings] AS [ms]
		WHERE  [ms].[Name] = 'AppUser'
			   AND [ms].[source_key] = 'App_Default'

		SELECT @PATH_CLR_ASSEMBLIES = CONVERT(NVARCHAR(128), [ms].[Value])
		FROM   [dbo].[MFSettings] AS [ms]
		WHERE  [ms].[Name] = 'AssemblyInstallPath'
			   AND [ms].[source_key] = 'App_Default'

		SELECT @EDIT_MFVERSION_PROP = CONVERT(NVARCHAR(128), [ms].[Value])
		FROM   [dbo].[MFSettings] AS [ms]
		WHERE  [ms].[Name] = 'MFVersion'
			   AND [ms].[source_key] = 'MF_Default'


		SELECT @PATH_MFILES_CLIENT = CONVERT(NVARCHAR(128), [ms].[Value])
		FROM   [dbo].[MFSettings] AS [ms]
		WHERE  [ms].[Name] = 'MFInstallPath'
			   AND [ms].[source_key] = 'MF_Default'

	END


SELECT @EDIT_WEBAPPNAME_PROP	  AS [EDIT_WEBAPPNAME_PROP]
	 , @EDIT_DBROLE_PROP		  AS [EDIT_DBROLE_PROP]
	 , @EDIT_APP_USER_PROP		  AS [EDIT_APP_USER_PROP]
	 , @PATH_CLR_ASSEMBLIES		  AS [PATH_CLR_ASSEMBLIES]
	 , @COMBOBOX_SQLAUTHTYPE_PROP AS [COMBOBOX_SQLAUTHTYPE_PROP]
	 , @EDIT_APP_PASSWORD_PROP	  AS [EDIT_APP_PASSWORD_PROP]
	 , @EDIT_MFVERSION_PROP		  AS [EDIT_MFVERSION_PROP]
	 , @PATH_MFILES_CLIENT		  AS [PATH_MFILES_CLIENT]

GO
