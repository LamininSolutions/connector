
GO


/*Update settings script
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
--DECLARE  @RootFolder nvarchar(128) = N'{varExportFolder}'
--DECLARE  @FileTransferLocation nvarchar(128) = N'{varImportFolder}'
--DECLARE @DetailLogging nvarchar(128) = '{varLoggingRequired}'
--DECLARE @MFInstallationPath  nvarchar(128) = N'{varMFInstallPath}'       
--DECLARE @MFilesVersion nvarchar(128) = N'{varMFVersion}'           
--DECLARE  @AssemblyInstallationPath nvarchar(128) = N'{varCLRPath}' 
--DECLARE   @SQLConnectorLogin nvarchar(128) = N'{varAppLogin_Name}'      
--DECLARE  @UserRole nvarchar(128) = N'{varAppDBRole}'              
--DECLARE  @SupportEmailAccount nvarchar(128) = N'{varITSupportEmail}'      
--DECLARE  @EmailProfile nvarchar(128) = N'{varEmailProfile}'

DECLARE @MFProtocolType_ID int 
DECLARE @MFAuthenticationType_ID int
DECLARE @Debug smallint = 0
DECLARE @EndPointInt INT



SET @EndPointInt = cast(@Endpoint AS int)
--SET @MFProtocolType_ID = CAST(@MFProtocolType AS INT)
--SET @MFAuthenticationType_ID = CAST(@MFAuthenticationType AS INT)
Select  @MFProtocolType_ID = id from MFProtocolType mpt where mpt.MFProtocolTypeValue =  @MFProtocolType
Select  @MFAuthenticationType_ID = id from MFAuthenticationType mat where mat.AuthenticationType = @mfauthenticationType



-------------------------------------------------------------
-- prevent ad hoc running of this procedure to over write existing settings that is not controlled by the installation package
-------------------------------------------------------------




-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 
   @Username = @username
-- ,  @password = @Password
 , @NetworkAddress = @NetworkAddress
  ,@Vaultname = @Vaultname
  ,@MFProtocolType_ID = @MFProtocolType_ID
  ,@Endpoint = @EndPointInt
  ,@MFAuthenticationType_ID = @MFAuthenticationType_ID
  ,@Domain = @Domain
--  ,@VaultGUID = @VaultGUID
--  ,@ServerURL = @ServerURL
 
IF EXISTS(SELECT * FROM sys.objects AS o WHERE o.name = 'spMFDecrypt')
BEGIN
EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 
  @Password = @password
END


 --EXEC dbo.spMFSettingsForDBUpdate @MFInstallationPath = @MFInstallationPath,       
 --                                 @MFilesVersion = @MFilesVersion ,            
 --                                 @AssemblyInstallationPath = @AssemblyInstallationPath,
 --                                 @SQLConnectorLogin = @SQLConnectorLogin,      
 --                                 @UserRole = @UserRole,               
 --                                 @SupportEmailAccount = @SupportEmailAccount,   
 --                                 @EmailProfile = @EmailProfile,           
 --                                 @DetailLogging = @DetailLogging,         
 --                                 @RootFolder = @RootFolder,              
 --                                 @FileTransferLocation = @FileTransferLocation,     
 --                                 @Debug = 0                      


GO


