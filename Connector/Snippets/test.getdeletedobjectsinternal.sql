
DECLARE @VaultSettings nvarchar(200)
DECLARE @lastModifiedDate DATETIME = '2010-01-01'
DECLARE @Classid INT
DECLARE @outputXML NVARCHAR(MAX)

SELECT @Classid = mfid FROM mfclass WHERE [TableName] = 'MFCustomer'

SELECT @VaultSettings = [dbo].[FnMFVaultSettings]()


        EXEC [dbo].[spMFGetDeletedObjectsInternal] @VaultSettings = @Vaultsettings       -- nvarchar(4000)
                                                  ,@ClassID = @ClassId                   -- int
                                                  ,@LastModifiedDate = @LastModifiedDate -- datetime
                                                  ,@outputXML = @outputXML OUTPUT;

  SELECT @outputXML