
GO



USE {varAppDB}
GO

/*
script to fetch default settings from MVaultSettings in Database for AI
*/

/* Advanced installer Variables used

{MFUsername}					M-FilesUserName 
{MFPassword}					Password
{NetworkAddress}				VaultNetworkAddress
{VaultName}						VaultName
{ProtocolType}					MF Connection protocol
{Endpoint}						MF Connection port
{AuthenticationType}			MF Connection Authentication Type
{MFDomain}						MF AD Domain

*/

													
DECLARE @EDIT_MFUSERNAME_PROP NVARCHAR(128) = 'VaultUser'					
DECLARE @EDIT_MFPASSWORD_PROP  NVARCHAR(128) 				
DECLARE @EDIT_NETWORKADDRESS_PROP NVARCHAR(128) ='VaultServer'				
DECLARE @EDIT_VAULTNAME_PROP NVARCHAR(128) = 'Vault'					
declare	@USERDOMAIN NVARCHAR(128) 		
declare	@COMBOBOX_PROTOCOL_PROP int 
declare	@EDIT_PORT_PROP int = 2266	
declare	@COMBOBOX_MFAUTHTYPE_PROP int 

BEGIN TRY
if exists(
select NAME from SYS.objects WHERE TYPE = 'U' AND NAME = 'MFVaultsettings')

BEGIN


SELECT 
     @EDIT_MFUSERNAME_PROP = [mvs].[Username]
     , @EDIT_MFPASSWORD_PROP = [mvs].[Password]
     , @EDIT_NETWORKADDRESS_PROP = [mvs].[NetworkAddress]
     , @EDIT_VAULTNAME_PROP = [mvs].[VaultName]
	 --,@COMBOBOX_PROTOCOL_PROP = Case when mvs.MFProtocolType_ID = 4 then 'HTTPS'
	 -- when mvs.MFProtocolType_ID = 3 then 'Local Procedure Call'
	 -- else 'TCP/IP' end
	 --,@COMBOBOX_MFAUTHTYPE_PROP = case when mvs.MFAuthenticationType_ID = 3 then 'Specific Windows User'
	 --when mvs.MFAuthenticationType_ID = 4 then 'M-Files User' end

     , @USERDOMAIN = [mvs].[Domain] 
	 ,@COMBOBOX_PROTOCOL_PROP = mvs.MFProtocolType_ID
	,@EDIT_PORT_PROP = mvs.[Endpoint]
	,@COMBOBOX_MFAUTHTYPE_PROP = mvs.MFAuthenticationType_ID
	 FROM [dbo].[MFVaultSettings] AS [mvs]


END

SELECT      @EDIT_MFUSERNAME_PROP AS EDIT_MFUSERNAME_PROP
     , @EDIT_MFPASSWORD_PROP  AS EDIT_MFPASSWORD_PROP
     , @EDIT_NETWORKADDRESS_PROP AS EDIT_NETWORKADDRESS_PROP
     , @EDIT_VAULTNAME_PROP AS EDIT_VAULTNAME_PROP
     , @USERDOMAIN AS USERDOMAIN
	 , @COMBOBOX_PROTOCOL_PROP as COMBOBOX_PROTOCOL_PROP
	 ,@EDIT_PORT_PROP as EDIT_PORT_PROP
	 ,@COMBOBOX_MFAUTHTYPE_PROP as COMBOBOX_MFAUTHTYPE_PROP

END TRY
BEGIN CATCH
RAISERROR('Getting Defaults for Vault Settings Failed',16,1)
END CATCH

--END

GO
