
DECLARE @MessageOut NVARCHAR(50);

EXEC [dbo].[spMFVaultConnectionTest] @MessageOut = @MessageOut OUTPUT -- nvarchar(50)

SELECT * FROM [dbo].[MFVaultSettings] AS [mvs]

EXEC [dbo].[spMFSettingsForVaultUpdate] 
                                       @Password = 'Connector01'             -- nvarchar(100)
                                       

DECLARE @returnVal NVARCHAR(MAX);
DECLARE @Prop XML
DECLARE @Settings NVARCHAR(4000)
SET @Settings = [dbo].[FnMFVaultSettings]()
SELECT @Settings

EXEC [dbo].[spMFGetProperty] @VaultSettings = @Settings -- nvarchar(4000)
                            ,@returnVal = @returnVal OUTPUT                         -- nvarchar(max)
SET @Prop = CONVERT(XML,@returnVal)

SELECT @Prop

DECLARE @ClassXML    NVARCHAR(MAX)
       ,@ClassPptXML NVARCHAR(MAX);

EXEC [dbo].[spMFGetClass] @VaultSettings = @Settings -- nvarchar(4000)
                         ,@ClassXML = @ClassXML OUTPUT                           -- nvarchar(max)
                         ,@ClassPptXML = @ClassPptXML OUTPUT                     -- nvarchar(max)

						 SELECT CONVERT(XML,@ClassXML), CONVERT(XML,@ClassPptXML)
