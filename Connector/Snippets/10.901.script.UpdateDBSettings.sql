
GO

USE {varAppDB}

GO

/*
Script to process settings from AI
*/

DECLARE @VaultGUID nvarchar(128) = N'{varGUID}'
 

   UPDATE  [dbo].[MFSettings]
            SET     Value =  CONVERT(sql_variant,@VaultGUID) 		
           WHERE  Name = 'VaultGUID'
                    AND [source_key] = 'MF_Default'


GO
