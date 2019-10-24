use {varAppDB}
GO

IF EXISTS (	  SELECT [name]
			  FROM	 [sys].[objects]
			  WHERE	 [type] = 'U'
					 AND [name] = 'MFSettings'
		  )
	BEGIN

		SELECT [EDIT_NETWORKADDRESS_PROP] = (	SELECT TOP 1 [mvs].[NetworkAddress]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)
			 , [EDIT_VAULTNAME_PROP]	  = (	SELECT TOP 1 [mvs].[VaultName]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)
			 , [VaultGUID]				  = (	SELECT CONVERT(NVARCHAR(128), [ms].[Value])
												FROM   [dbo].[MFSettings] AS [ms]
												WHERE  [ms].[Name] = 'VaultGUID'
													   AND [ms].[source_key] = 'MF_Default'
											)
			 , [EDIT_WEBURL_PROP]		  = (	SELECT TOP 1 CONVERT(NVARCHAR(128), [ms].[Value])
												FROM   [dbo].[MFSettings] AS [ms]
												WHERE  [ms].[Name] = 'ServerURL'
													   AND [ms].[source_key] = 'MF_Default'
											)
			 , [COMBOBOX_PROTOCOL_PROP]	  = (	SELECT TOP 1 [mpt].[ProtocolType]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
												INNER JOIN [dbo].[MFProtocolType] [mpt] ON [mvs].[MFProtocolType_ID] = [mpt].[ID]
											)
			 , [EDIT_PORT_PROP]			  = (	SELECT TOP 1 [mvs].[Endpoint]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)
			 , [COMBOBOX_MFAUTHTYPE_PROP] = (	SELECT TOP 1 [mat].[AuthenticationType]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
												INNER JOIN [dbo].[MFAuthenticationType] [mat] ON [mvs].[MFAuthenticationType_ID] = [mat].[ID]
											)
			 , [EDIT_MFUSERNAME_PROP]	  = (	SELECT TOP 1 [mvs].[Username]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)
			 , [EDIT_MFPASSWORD_PROP]	  = (	SELECT TOP 1 [mvs].[Password]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)
			 , [USERDOMAIN]				  = (	SELECT TOP 1 [mvs].[Domain]
												FROM   [dbo].[MFVaultSettings] AS [mvs]
											)




	END
ELSE
	BEGIN
		SELECT N'VaultNetworkAddress'	AS [EDIT_NETWORKADDRESS_PROP]
			 , N'VaultName'				AS [EDIT_VAULTNAME_PROP]
			 , N'VaultGUID'				AS [EDIT_GUID_PROP]
			 , N'http://sub.domain.com' AS [EDIT_WEBURL_PROP]
			 , 'TCP/IP'					AS [COMBOBOX_PROTOCOL_PROP]
			 , 2266						AS [EDIT_PORT_PROP]
			 , 'M-Files User'			AS [COMBOBOX_MFAUTHTYPE_PROP]
			 , N'VaultUser'				AS [EDIT_MFUSERNAME_PROP]
			 , N'Password'				AS [EDIT_MFPASSWORD_PROP]
			 , N''						AS [USERDOMAIN]





	--		,'MFSQLConnect' -- APP USer Name
	--		,'Connector01' --APP initial password
	--		,'SQL' -- APP authentication type
	--        )

	END




GO
