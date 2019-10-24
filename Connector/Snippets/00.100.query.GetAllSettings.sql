
/*
Get all MF settings
Backup settings
 
{varAppDB}

*/

GO

DECLARE @APP_DBROLE_PROP NVARCHAR(128);
DECLARE @APP_PATH_CLR_ASSEMBLIES NVARCHAR(128) = N'{varCLRPath}';
DECLARE @APP_APP_USER_PROP NVARCHAR(128);
DECLARE @APP_SQLAUTHTYPE_PROP NVARCHAR(128); -- APP authentication type
DECLARE @APP_APP_PASSWORD_PROP NVARCHAR(128); --APP initial password
DECLARE @APP_MFVERSION_PROP NVARCHAR(128) = N'{varMFVersion}';
DECLARE @APP_PATH_MFILES_CLIENT NVARCHAR(128);
DECLARE @APP_WEBURL_PROP NVARCHAR(128) = N'{varWebURL}';
DECLARE @APP_MFUSERNAME_PROP NVARCHAR(128) = N'{varMFUsername}';
DECLARE @APP_MFPASSWORD_PROP NVARCHAR(128) = N'{varMFPassword}';
DECLARE @APP_NETWORKADDRESS_PROP NVARCHAR(128) = N'{varNetworkAddress}';
DECLARE @APP_VAULTNAME_PROP NVARCHAR(128) = N'{varVaultName}';
DECLARE @APP_USERDOMAIN NVARCHAR(128) = N'{varMFDomain}';
DECLARE @APP_VaultGUID NVARCHAR(128) = N'{varGUID}';
DECLARE @APP_PROTOCOL_PROP NVARCHAR(128) = '{varProtocolType}';
DECLARE @APP_PORT_PROP NVARCHAR(128) = '{varEndPoint}';
DECLARE @APP_MFAUTHTYPE_PROP NVARCHAR(128) = '{varAuthenticationType}';
DECLARE @APP_ITSUPPORTEMAIL_PROP NVARCHAR(100) = N'{varITSupportEmail}';
DECLARE @APP_MAILPROFILE_PROP NVARCHAR(100) = N'{varEmailProfile}';
DECLARE @APP_LOGGINGREQUIRED_PROP NVARCHAR(100) = '{varLoggingRequired}';
DECLARE @APP_SQL_IMPORTFOLDER NVARCHAR(100) = N'{varImportFolder}';
DECLARE @APP_SQL_EXPORTFOLDER NVARCHAR(100) = N'{varExportFolder}';


DECLARE @SQL_DBROLE_PROP NVARCHAR(128) = 'db_MFSQLConnect';
DECLARE @SQL_PATH_CLR_ASSEMBLIES NVARCHAR(128);
DECLARE @SQL_SQLUSER_PROP NVARCHAR(128) = 'MFSQLConnect';
DECLARE @SQL_SQLAUTHTYPE_PROP NVARCHAR(128) = 'SQL'; -- SQL authentication type
DECLARE @SQL_SQLPASSWORD_PROP NVARCHAR(128) = 'Connector01'; --SQL initial password
DECLARE @SQL_MFVERSION_PROP NVARCHAR(128)  = '';
DECLARE @SQL_PATH_MFILES_CLIENT NVARCHAR(128) = 'C:\Program Files\M-Files\';
DECLARE @SQL_WEBURL_PROP NVARCHAR(128);
DECLARE @SQL_MFUSERNAME_PROP NVARCHAR(128);
DECLARE @SQL_MFPASSWORD_PROP NVARCHAR(128);
DECLARE @SQL_NETWORKADDRESS_PROP NVARCHAR(128);
DECLARE @SQL_VAULTNAME_PROP NVARCHAR(128);
DECLARE @SQL_USERDOMAIN NVARCHAR(128);
DECLARE @SQL_VaultGUID NVARCHAR(128);
DECLARE @SQL_PROTOCOL_PROP NVARCHAR(128);
DECLARE @SQL_PORT_PROP NVARCHAR(128);
DECLARE @SQL_MFAUTHTYPE_PROP NVARCHAR(128);
DECLARE @SQL_ITSUPPORTEMAIL_PROP NVARCHAR(100) = 'Support@lamininsolutions.com' ;
DECLARE @SQL_MAILPROFILE_PROP NVARCHAR(100) = 'MailProfile' ;
DECLARE @SQL_LOGGINGREQUIRED_PROP NVARCHAR(100) = '0' ;
DECLARE @SQL_SQL_IMPORTFOLDER NVARCHAR(100) = '';
DECLARE @SQL_SQL_EXPORTFOLDER NVARCHAR(100) ='';

DECLARE @MFProtocolType_ID INT;
DECLARE @MFAuthenticationType_ID INT;
DECLARE @Debug SMALLINT = 0;
DECLARE @EndPointInt INT;

IF EXISTS
(
    SELECT name
    FROM sys.objects
    WHERE type = 'U'
          AND name = 'MFsettings'
)
BEGIN
IF (SELECT object_id('Tempdb..##Settings'))IS NOT NULL
DROP TABLE ##Settings;

Select * INTO ##MFSettings from dbo.MFSettings
--sql OVERRIDES

    SELECT @SQL_DBROLE_PROP = CASE
                                  WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                      'db_MFSQLConnect'
                                  ELSE
                                      CONVERT(NVARCHAR(128), ms.Value)
                              END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'SQLUserRole'
          AND ms.source_key = 'APP_Default';


    SELECT @SQL_SQLUSER_PROP = CASE
                                   WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                       'MFSQLConnect'
                                   ELSE
                                       CONVERT(NVARCHAR(128), ms.Value)
                               END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'SQLUser'
          AND ms.source_key = 'APP_Default';

    SELECT @SQL_PATH_CLR_ASSEMBLIES = CASE
                                          WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                              @APP_PATH_CLR_ASSEMBLIES
                                          WHEN @SQL_PATH_CLR_ASSEMBLIES = @APP_PATH_CLR_ASSEMBLIES THEN
                                              @APP_PATH_CLR_ASSEMBLIES
                                          ELSE
                                              CONVERT(NVARCHAR(128), ms.Value)
                                      END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'AssemblyInstallPath'
          AND ms.source_key = 'APP_Default';

    SELECT @SQL_MFVERSION_PROP = CASE
                                     WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                         @SQL_MFVERSION_PROP
                                     WHEN CONVERT(NVARCHAR(128), ms.Value) = '' THEN
                                         @SQL_MFVERSION_PROP                            
                                     ELSE
                                         CONVERT(NVARCHAR(128), ms.Value)
                                 END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'MFVersion'
          AND ms.source_key = 'MF_Default';


    SELECT @SQL_PATH_MFILES_CLIENT = CASE
                                         WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                             @SQL_PATH_MFILES_CLIENT
                                         ELSE
                                             CONVERT(NVARCHAR(128), ms.Value)
                                     END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'MFInstallPath'
          AND ms.source_key = 'MF_Default';


    SELECT @SQL_ITSUPPORTEMAIL_PROP = CASE
                                          WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                              @SQL_ITSUPPORTEMAIL_PROP
                                          ELSE
                                              CONVERT(NVARCHAR(128), ms.Value)
                                      END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'SupportEmailRecipient'
          AND ms.source_key = 'Email';

    SELECT @SQL_MAILPROFILE_PROP = CASE
                                       WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN
                                           @SQL_MAILPROFILE_PROP
                                       ELSE
                                           CONVERT(NVARCHAR(128), ms.Value)
                                   END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'SupportEMailProfile'
          AND ms.source_key = 'Email';

    SELECT @SQL_LOGGINGREQUIRED_PROP = CASE
                                       WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN 
									   @SQL_LOGGINGREQUIRED_PROP
									   ELSE
	CONVERT(NVARCHAR(128), ms.Value)
	END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'App_DetailLogging'
          AND ms.source_key = 'APP_Default';


--APP OVERRIDES

    SELECT @SQL_SQL_IMPORTFOLDER = CASE
                                       WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN 
									   @APP_SQL_IMPORTFOLDER
									   else
	CONVERT(NVARCHAR(128), ms.Value)
	END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'FileTransferLocation'
          AND ms.source_key = 'Files_Default';

    SELECT @SQL_SQL_EXPORTFOLDER =  CASE
                                       WHEN SUBSTRING(CONVERT(NVARCHAR(128), ms.Value),1,1) = '{' THEN 
									@APP_SQL_EXPORTFOLDER
	ELSE
	CONVERT(NVARCHAR(128), ms.Value)
	END
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'RootFolder'
          AND ms.source_key = 'Files_Default';

    SELECT @SQL_VaultGUID = CONVERT(NVARCHAR(128), ms.Value)
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'VaultGUID'
          AND ms.source_key = 'MF_Default';


    SELECT @SQL_WEBURL_PROP = CONVERT(NVARCHAR(128), ms.Value)
    FROM dbo.MFSettings AS ms
    WHERE ms.Name = 'ServerURL'
          AND ms.source_key = 'MF_Default';

END

IF EXISTS
(
    SELECT name
    FROM sys.objects
    WHERE type = 'U'
          AND name = 'MFVaultsettings'
)
BEGIN


    SELECT @SQL_MFUSERNAME_PROP = mvs.Username,
           @SQL_MFPASSWORD_PROP = mvs.Password,
           @SQL_NETWORKADDRESS_PROP = mvs.NetworkAddress,
           @SQL_VAULTNAME_PROP = mvs.VaultName,
           @SQL_USERDOMAIN = mvs.Domain,
           @SQL_PROTOCOL_PROP = mpt.ProtocolType,
           @SQL_PORT_PROP = mvs.Endpoint,
           @SQL_MFAUTHTYPE_PROP = mat.AuthenticationType
    FROM dbo.MFVaultSettings AS mvs
        INNER JOIN dbo.MFProtocolType mpt
            ON mvs.MFProtocolType_ID = mpt.ID
        INNER JOIN dbo.MFAuthenticationType mat
            ON mvs.MFAuthenticationType_ID = mat.ID;

END;



SELECT
-- ISNULL(@SQL_DBROLE_PROP, @SQL_DBROLE_PROP) AS APP_DBROLE_PROP,
--       ISNULL(@SQL_SQLUSER_PROP, @SQL_SQLUSER_PROP) AS APP_APP_USER_PROP,
--       ISNULL(@APP_PATH_CLR_ASSEMBLIES, @SQL_PATH_CLR_ASSEMBLIES) AS PATH_CLR_ASSEMBLIES,
--       ISNULL(@SQL_SQLAUTHTYPE_PROP, @SQL_SQLAUTHTYPE_PROP) AS COMBOBOX_SQLAUTHTYPE_PROP,
--       ISNULL(@SQL_SQLPASSWORD_PROP, @SQL_SQLPASSWORD_PROP) AS APP_APP_PASSWORD_PROP,
       ISNULL(@SQL_MFVERSION_PROP, @APP_MFVERSION_PROP) AS APP_MFVERSION_PROP,
       ISNULL(@SQL_PATH_MFILES_CLIENT, @SQL_PATH_MFILES_CLIENT) AS PATH_MFILES_CLIENT,
       ISNULL(@APP_MFUSERNAME_PROP, @SQL_MFUSERNAME_PROP) AS APP_MFUSERNAME_PROP,
       ISNULL(@APP_MFPASSWORD_PROP, @SQL_MFPASSWORD_PROP) AS APP_MFPASSWORD_PROP,
       ISNULL(@APP_NETWORKADDRESS_PROP, @SQL_NETWORKADDRESS_PROP) AS APP_NETWORKADDRESS_PROP,
       ISNULL(@APP_VAULTNAME_PROP, @SQL_VAULTNAME_PROP) AS APP_VAULTNAME_PROP,
       ISNULL(@APP_USERDOMAIN, @SQL_USERDOMAIN) AS USERDOMAIN,
       ISNULL(@APP_VaultGUID, @SQL_VaultGUID) AS VAULTGUID,
       ISNULL(@APP_PROTOCOL_PROP, @SQL_PROTOCOL_PROP) AS COMBOBOX_PROTOCOL_PROP,
       ISNULL(@APP_PORT_PROP, @SQL_PORT_PROP) AS APP_PORT_PROP,
       ISNULL(@APP_MFAUTHTYPE_PROP, @SQL_MFAUTHTYPE_PROP) AS COMBOBOX_MFAUTHTYPE_PROP,
       ISNULL(@SQL_ITSUPPORTEMAIL_PROP, @SQL_ITSUPPORTEMAIL_PROP) AS APP_ITSUPPORTEMAIL_PROP
--       ISNULL(@SQL_MAILPROFILE_PROP, @SQL_MAILPROFILE_PROP) AS APP_MAILPROFILE_PROP,
--       ISNULL(@SQL_LOGGINGREQUIRED_PROP, @SQL_LOGGINGREQUIRED_PROP) AS CHECKBOX_LOGGINGREQUIRED_PROP,
--       ISNULL(@SQL_SQL_IMPORTFOLDER, @SQL_SQL_IMPORTFOLDER) AS APP_SQLIMPORTFOLDER,
--       ISNULL(@SQL_SQL_EXPORTFOLDER, @SQL_SQL_EXPORTFOLDER) AS APP_SQLEXPORTFOLDER,
--       ISNULL(@SQL_WEBURL_PROP, @APP_WEBURL_PROP) AS APP_WEBURL_PROP;



GO

