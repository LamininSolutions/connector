
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + 'tMFVaultSettings_Password';
GO

SET NOCOUNT ON; 
EXEC [setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'tMFVaultSettings_Password'
  , -- nvarchar(100)
    @Object_Release = '3.1.0.21'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 GO

IF EXISTS ( SELECT  *
            FROM    [sys].[objects]
            WHERE   [objects].[type] = 'TR'
                    AND [objects].[name] = 'tMFVaultSettings_Password' )
   BEGIN
         
         DROP TRIGGER [dbo].[tMFVaultSettings_Password]
         PRINT SPACE(10) + '...Trigger dropped and recreated'
   END
GO

CREATE TRIGGER [dbo].[tMFVaultSettings_Password] ON [dbo].[MFVaultSettings]
       AFTER UPDATE
AS
       /*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-03
	Database: 
	Description: Create trigger to encrypt password
						
				 Executed when ever password is updated in [MFVaultSettings]
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  update MFVaultSettings set Password = 'Password' 
  select * from mfvaultsettings 
  
-----------------------------------------------------------------------------------------------*/
  

       SET NOCOUNT ON;

       DECLARE @result INT
       DECLARE @rc INT
             , @msg AS VARCHAR(250)
             , @Password NVARCHAR(100)
             , @Debug SMALLINT = 0

       IF UPDATE([Password])
          BEGIN
	
                SELECT  @Password = [Inserted].[Password]
                FROM    [Inserted]; 		
	
                IF @Debug > 0
                   SELECT   @Password AS 'InsertedEncryptedPassword'
                EXEC [dbo].[spMFDecrypt]
                    @EncryptedPassword = @Password
                  , -- nvarchar(2000)
                    @DecryptedPassword = @Password OUTPUT;					 	

                IF @Debug > 0
                   SELECT   @Password AS 'InsertedDecryptedPassword'

                IF @Password IS NOT NULL
                   BEGIN

                         DECLARE @EncryptedPassword NVARCHAR(250);
                         DECLARE @PreviousPassword NVARCHAR(100);

				
                         SELECT TOP 1
                                @PreviousPassword = [s].[Password]
                         FROM   [dbo].[MFVaultSettings] [s];

                         IF @Debug > 0
                            SELECT  @PreviousPassword AS '@PreviousPassword'
                                  , LEN(@PreviousPassword) AS [PWLength] 


                         IF LEN(@PreviousPassword) <> 24
                            BEGIN

                                  EXECUTE [dbo].[spMFEncrypt]
                                    @Password
                                  , @EncryptedPassword OUT;
                                  IF @Debug > 0
                                     SELECT @EncryptedPassword AS 'Encrypted PreviousPassword'
                            END
                         ELSE
                            BEGIN         
                                  EXEC [dbo].[spMFDecrypt]
                                    @EncryptedPassword = @PreviousPassword
                                  , -- nvarchar(2000)
                                    @DecryptedPassword = @PreviousPassword OUTPUT;


                                  IF @Debug > 0
                                     SELECT @PreviousPassword AS 'Decrypted PreviousPassword'

                            END

   
                         IF @Password <> @PreviousPassword
                            BEGIN
            
                                  EXECUTE [dbo].[spMFEncrypt]
                                    @Password
                                  , @EncryptedPassword OUT;

                                  UPDATE    [s]
                                  SET       [s].[Password] = @EncryptedPassword
                                  FROM      [dbo].[MFVaultSettings] [s]
                                  WHERE     ( SELECT    COUNT(*)
                                              FROM      [dbo].[MFVaultSettings] AS [mvs]
                                            ) = 1    

                            END
							
                            
                        
			                    	   	
                     


                         IF @Debug > 0
                            SELECT  [mvs].[Password]
                            FROM    [dbo].[MFVaultSettings] AS [mvs]

                   END
                         
                   
          END
   GO
   

