

go

/***************************************************************************
IMPORTANT : READ AND PERFORM ACTION BEFORE EXECUTING THE PREPARE SERVER SCRIPT
***************************************************************************/

/*
THIS SCRIPT HAS BEEN PREPARE TO ALLOW FOR THE AUTOMATION OF ALL THE INSTALLATION VARIABLES

2017-3-24-7h30
2018-1-20

*/

/*


Find what:						Replace With:
{varAppDB}						DatabaseName (new or existing)
{varAuthType}					Options: SQL or WINDOWS
{varAppLogin_Name}				LoginName (e.g. MFSQLConnect)
{varAppLogin_Password}			Password (e.g. Connector)
{varAppName}					Name of MFSQLManager App (e.g. MFSQLManager)
{varAppDBRole}					AppDBRole (e.g. db_MFSQLConnect)				
{varEmailProfile}
{varMFUsername}					M-FilesUserName 
{varMFPassword}					Password
{varNetworkAddress}				VaultNetworkAddress
{varVaultName}						VaultName
{varProtocolType}					MF Connection protocol
{varEndpoint}						MF Connection port
{varAuthenticationType}			MF Connection Authentication Type
{varMFDomain}						MF AD Domain
{varGUID}
{varWebURL}
{varITSupportEmail}
{varLoggingRequired}


*/

--USE {varAppDB}
go

declare @AIDebug int = 0;

declare @EDIT_WEBAPPNAME_PROP nvarchar(128);
declare @EDIT_DBROLE_PROP nvarchar(128);
declare @PATH_CLR_ASSEMBLIES nvarchar(128);
declare @EDIT_APP_USER_PROP nvarchar(128);
declare @COMBOBOX_SQLAUTHTYPE_PROP nvarchar(128);
declare @EDIT_APP_PASSWORD_PROP nvarchar(128);
declare @EDIT_MFVERSION_PROP nvarchar(128);
declare @PATH_MFILES_CLIENT nvarchar(128);
declare @EDIT_MAILPROFILE_PROP nvarchar(128);
declare @EDIT_MFUSERNAME_PROP nvarchar(128);
declare @EDIT_MFPASSWORD_PROP nvarchar(128);
declare @EDIT_NETWORKADDRESS_PROP nvarchar(128);
declare @EDIT_VAULTNAME_PROP nvarchar(128);
declare @USERDOMAIN nvarchar(128);
declare @COMBOBOX_PROTOCOL_PROP nvarchar(128);
declare @EDIT_PORT_PROP int;
declare @COMBOBOX_MFAUTHTYPE_PROP nvarchar(128);
declare @EDIT_GUID_PROP nvarchar(128);
declare @EDIT_WEBURL_PROP nvarchar(128);
declare @EDIT_ITSUPPORTEMAIL_PROP nvarchar(128);
declare @CHECKBOX_LOGGINGREQUIRED_PROP nvarchar(128);

if @AIDebug = 0
begin

    set @EDIT_WEBAPPNAME_PROP = '{varAppName}';
    set @EDIT_DBROLE_PROP = '{varAppDBRole}';
    set @PATH_CLR_ASSEMBLIES = '';
    set @EDIT_APP_USER_PROP = '{varAppLogin_Name}';
    set @COMBOBOX_SQLAUTHTYPE_PROP = '{varAuthType}';
    set @EDIT_APP_PASSWORD_PROP = '{varAppLogin_Password}';
    set @EDIT_MFVERSION_PROP = '';
    set @PATH_MFILES_CLIENT = '';
    set @EDIT_MAILPROFILE_PROP = '{varEmailProfile}';
    set @EDIT_MFUSERNAME_PROP = '{varMFUsername}';
    set @EDIT_MFPASSWORD_PROP = '{varMFPassword}';
    set @EDIT_NETWORKADDRESS_PROP = '{varNetworkAddress}';
    set @EDIT_VAULTNAME_PROP = '{varVaultName}';
    set @USERDOMAIN = '{varMFDomain}';
    set @COMBOBOX_PROTOCOL_PROP = '{varProtocolType}';
    set @EDIT_PORT_PROP = {varEndpoint};
    set @COMBOBOX_MFAUTHTYPE_PROP = '{varAuthenticationType}';
    set @EDIT_GUID_PROP = '{varGUID}';
    set @EDIT_WEBURL_PROP = '{varWebURL}';
    set @EDIT_ITSUPPORTEMAIL_PROP = '{varITSupportEmail}';
    set @CHECKBOX_LOGGINGREQUIRED_PROP = '{varLoggingRequired}';

end;
else
begin

    set @EDIT_WEBAPPNAME_PROP = 'MFSQL_Manager'; -- note that this is not used in MFSettings	 
    set @EDIT_DBROLE_PROP = 'db_MFSQLConnect';
    set @PATH_CLR_ASSEMBLIES = 'C:\Program Files (x86)\Laminin Solutions\MFSQL Connector\Assemblies';
    set @EDIT_APP_USER_PROP = 'MFSQLConnect';
    set @COMBOBOX_SQLAUTHTYPE_PROP = 'SQL'; -- APP authentication type 
    set @EDIT_APP_PASSWORD_PROP = 'Connector01'; --APP initial password
    set @EDIT_MFVERSION_PROP = N'xx.x.xxxx.xxx';
    set @PATH_MFILES_CLIENT = N'C:\Program Files\M-Files';
    set @EDIT_MAILPROFILE_PROP = 'MailProfile';
    set @EDIT_MFUSERNAME_PROP = 'M-Files User';
    set @EDIT_MFPASSWORD_PROP = 'Password';
    set @EDIT_NETWORKADDRESS_PROP = 'VaultNetworkAddress';
    set @EDIT_VAULTNAME_PROP = 'VaultName';
    set @USERDOMAIN = '';
    set @COMBOBOX_PROTOCOL_PROP = 'TCP/IP';
    set @EDIT_PORT_PROP = 2266;
    set @COMBOBOX_MFAUTHTYPE_PROP = 'M-Files User';
    set @EDIT_GUID_PROP = 'VaultGUID';
    set @EDIT_WEBURL_PROP = 'http://sub.domain.com';
    set @EDIT_ITSUPPORTEMAIL_PROP = 'Support@lamininsolutions.com';
    set @CHECKBOX_LOGGINGREQUIRED_PROP = '0';

end;

-------------------------------------------------------------
-- MFSETTINGS
-------------------------------------------------------------

if exists
(
    select [name]
    from [sys].[objects]
    where [type] = 'U'
          and [name] = 'MFsettings'
)
begin

    select @EDIT_DBROLE_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'AppUserRole'
          and [ms].[source_key] = 'App_Default';

    select @EDIT_APP_USER_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'AppUser'
          and [ms].[source_key] = 'App_Default';

    select @PATH_CLR_ASSEMBLIES = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'AssemblyInstallPath'
          and [ms].[source_key] = 'App_Default';

    select @EDIT_MFVERSION_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'MFVersion'
          and [ms].[source_key] = 'MF_Default';


    select @PATH_MFILES_CLIENT = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'MFInstallPath'
          and [ms].[source_key] = 'MF_Default';


    select @EDIT_ITSUPPORTEMAIL_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'SupportEmailRecipient'
          and [source_key] = 'Email';

    select @EDIT_MAILPROFILE_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'SupportEMailProfile'
          and [source_key] = 'Email';

    select @CHECKBOX_LOGGINGREQUIRED_PROP = convert(nvarchar(128), [ms].[Value])
    from [dbo].[MFSettings] as [ms]
    where [ms].[Name] = 'App_DetailLogging'
          and [source_key] = 'App_Default';


end;


/*
Create mail profile result
*/


declare @Result_Message nvarchar(200);

if exists (select 1 from [msdb].[dbo].[sysmail_account] as [a])
begin
    set @Result_Message = 'Database Mail Installed';


    if not exists
    (
        select [p].[name]
        from [msdb].[dbo].[sysmail_account]                  as [a]
            inner join [msdb].[dbo].[sysmail_profileaccount] as [pa]
                on [a].[account_id] = [pa].[account_id]
            inner join [msdb].[dbo].[sysmail_profile]        as [p]
                on [pa].[profile_id] = [p].[profile_id]
        where [p].[name] = @EDIT_MAILPROFILE_PROP
    )
    begin

        -- Create a Database Mail profile
        execute [msdb].[dbo].[sysmail_add_profile_sp] @profile_name = @EDIT_MAILPROFILE_PROP
                                                    , @description = 'Profile for MFSQLConnector.';

    end;

end;
else
begin

    set @Result_Message = 'Database Mail is not installed on the SQL Server';
end;


-------------------------------------------------------------
-- MFSETTINGS
-------------------------------------------------------------



if exists
(
    select [name]
    from [sys].[objects]
    where [type] = 'U'
          and [name] = 'MFVaultSettings'
)
begin


    select @EDIT_NETWORKADDRESS_PROP =
    (
        select top 1 [mvs].[NetworkAddress] from [dbo].[MFVaultSettings] as [mvs]
    )
         , @EDIT_VAULTNAME_PROP      =
    (
        select top 1 [mvs].[VaultName] from [dbo].[MFVaultSettings] as [mvs]
    )
         , @EDIT_GUID_PROP           =
    (
        select convert(nvarchar(128), [ms].[Value])
        from [dbo].[MFSettings] as [ms]
        where [ms].[Name] = 'VaultGUID'
              and [ms].[source_key] = 'MF_Default'
    )
         , @EDIT_WEBURL_PROP         =
    (
        select top 1
               convert(nvarchar(128), [ms].[Value])
        from [dbo].[MFSettings] as [ms]
        where [ms].[Name] = 'ServerURL'
              and [ms].[source_key] = 'MF_Default'
    )
         , @COMBOBOX_PROTOCOL_PROP   =
    (
        select top 1
               [mpt].[ProtocolType]
        from [dbo].[MFVaultSettings]          as [mvs]
            inner join [dbo].[MFProtocolType] as [mpt]
                on [mvs].[MFProtocolType_ID] = [mpt].[ID]
    )
         , @EDIT_PORT_PROP           =
    (
        select top 1 [mvs].[Endpoint] from [dbo].[MFVaultSettings] as [mvs]
    )
         , @COMBOBOX_MFAUTHTYPE_PROP =
    (
        select top 1
               [mat].[AuthenticationType]
        from [dbo].[MFVaultSettings]                as [mvs]
            inner join [dbo].[MFAuthenticationType] as [mat]
                on [mvs].[MFAuthenticationType_ID] = [mat].[ID]
    )
         , @EDIT_MFUSERNAME_PROP     =
    (
        select top 1 [mvs].[Username] from [dbo].[MFVaultSettings] as [mvs]
    )
         , @EDIT_MFPASSWORD_PROP     =
    (
        select top 1 [mvs].[Password] from [dbo].[MFVaultSettings] as [mvs]
    )
         , @USERDOMAIN               =
    (
        select top 1 [mvs].[Domain] from [dbo].[MFVaultSettings] as [mvs]
    );


end;


select @EDIT_WEBAPPNAME_PROP          as [EDIT_WEBAPPNAME_PROP]
     , @EDIT_DBROLE_PROP              as [EDIT_DBROLE_PROP]
     , @EDIT_APP_USER_PROP            as [EDIT_APP_USER_PROP]
     , @PATH_CLR_ASSEMBLIES           as [PATH_CLR_ASSEMBLIES]
     , @COMBOBOX_SQLAUTHTYPE_PROP     as [COMBOBOX_SQLAUTHTYPE_PROP]
     , @EDIT_APP_PASSWORD_PROP        as [EDIT_APP_PASSWORD_PROP]
     , @EDIT_MFVERSION_PROP           as [EDIT_MFVERSION_PROP]
     , @PATH_MFILES_CLIENT            as [PATH_MFILES_CLIENT]
     , @Result_Message                as [Result_Message]
     , @EDIT_NETWORKADDRESS_PROP      as [EDIT_NETWORKADDRESS_PROP]
     , @EDIT_VAULTNAME_PROP           as [EDIT_VAULTNAME_PROP]
     , @EDIT_GUID_PROP                as [EDIT_GUID_PROP]
     , @EDIT_WEBURL_PROP              as [EDIT_WEBURL_PROP]
     , @COMBOBOX_PROTOCOL_PROP        as [COMBOBOX_PROTOCOL_PROP]
     , @EDIT_PORT_PROP                as [EDIT_PORT_PROP]
     , @COMBOBOX_MFAUTHTYPE_PROP      as [COMBOBOX_MFAUTHTYPE_PROP]
     , @EDIT_MFUSERNAME_PROP          as [EDIT_MFUSERNAME_PROP]
     , @EDIT_MFPASSWORD_PROP          as [EDIT_MFPASSWORD_PROP]
     , @USERDOMAIN                    as [USERDOMAIN]
     , @EDIT_ITSUPPORTEMAIL_PROP      as [EDIT_ITSUPPORTEMAIL_PROP]
     , @EDIT_MAILPROFILE_PROP         as [EDIT_MAILPROFILE_PROP]
     , @CHECKBOX_LOGGINGREQUIRED_PROP as [CHECKBOX_LOGGINGREQUIRED_PROP];


go
