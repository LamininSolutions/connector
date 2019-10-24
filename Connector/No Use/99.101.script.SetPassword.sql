



GO

/*Create settings script for password setting only
{varMFPassword}

*/

DECLARE @RC int

DECLARE @Password nvarchar(100) = N'{varMFPassword}'

EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 

  @Password = @password


GO

