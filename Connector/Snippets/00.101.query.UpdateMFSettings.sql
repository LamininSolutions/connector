


/*Set MFiles login 
*/

DECLARE @RC int
DECLARE @Username nvarchar(100) = N'{varMFUsername}'
DECLARE @Password nvarchar(100) = N'{varMFPassword}'
DECLARE @NetworkAddress nvarchar(100) = N'{varNetworkAddress}'
DECLARE @Vaultname nvarchar(100) = N'{varVaultName}' 
DECLARE @MFProtocolType nvarchar(100) = '{varProtocolType}'
DECLARE @Endpoint nvarchar(100) = '{varEndPoint}'
DECLARE @MFAuthenticationType nvarchar(100) = '{varAuthenticationType}'
DECLARE @Domain nvarchar(128) =  N'{varMFDomain}'
DECLARE @VaultGUID nvarchar(1000) = N'{varGUID}'
DECLARE @ServerURL nvarchar(500) = N'{varWebURL}'
DECLARE @MFilesVersion nvarchar(128) = N'{varMFVersion}'   --value comes from powershell

     
DECLARE @MFProtocolType_ID int 
DECLARE @MFAuthenticationType_ID int
DECLARE @Debug smallint = 0
DECLARE @EndPointInt INT

	 



IF EXISTS(SELECT * FROM sys.objects AS o WHERE o.name = 'spMFDecrypt')
BEGIN

SET @EndPointInt = cast(@Endpoint AS int)
Select  @MFProtocolType_ID = id from MFProtocolType mpt where mpt.ProtocolType =  @MFProtocolType
Select  @MFAuthenticationType_ID = id from MFAuthenticationType mat where mat.AuthenticationType = @mfauthenticationType

EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 
   @Username = @username
 ,  @password = @Password
 , @NetworkAddress = @NetworkAddress
  ,@Vaultname = @Vaultname
  ,@MFProtocolType_ID = @MFProtocolType_ID
  ,@Endpoint = @EndPointInt
  ,@MFAuthenticationType_ID = @MFAuthenticationType_ID
  ,@Domain = @Domain
  ,@VaultGUID = @VaultGUID
  ,@ServerURL = @ServerURL

END


GO

