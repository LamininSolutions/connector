


GO

/*
Script to process settings from AI
*/

EXECUTE [dbo].[spMFSettingsForDBUpdate] 
  @MFilesVersion = '{MFVersion}'
  ,@MFInstallationPath = '{MFInstallPath}'
  ,@AssemblyInstallationPath = '{CLRPath}'
  ,@SupportEmailAccount = '{SupportEmail}'
  ,@EmailProfile = '{EmailProfile}'
  ,@SQLConnectorLogin = '{varAppLogin_Name}' 
  , @UserRole = '{varAppDBRole}' 
,  @DetailLogging = '{DetailLogging}'
, @RootFolder = '{RootFolder}'

DECLARE @VaultGUID nvarchar(128) = N'{VaultGUID}'
 DECLARE @ServerURL nvarchar(128) = N'{ServerURL}'    


   UPDATE  [dbo].[MFSettings]
            SET     Value =  CONVERT(sql_variant,@VaultGUID) 		
           WHERE  Name = 'VaultGUID'
                    AND [source_key] = 'MF_Default'

            UPDATE  [dbo].[MFSettings]
            SET     Value =  CONVERT(sql_variant,@ServerURL)
            WHERE   Name = 'ServerURL'
                    AND [source_key] = 'MF_Default';

GO
