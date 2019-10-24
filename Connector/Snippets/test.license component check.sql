
/*

*/

DECLARE @MessageOut NVARCHAR(250);

EXEC [dbo].[spMFVaultConnectionTest] @IsSilent = 0 -- int
                                    ,@MessageOut = @MessageOut OUTPUT                  -- nvarchar(250)

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFSynchronizeMetadata] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT     -- int
                                    ,@Debug = 0 -- smallint

                                    SELECT * FROM [dbo].[MFLog] AS [ml]

--Created on: 2019-09-13 
SELECT * FROM setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Module] = 3

UPDATE setup.[MFSQLObjectsControl]
SET module = 1 WHERE name = 'spMFGetHistoryInternal'

DECLARE @rt int

EXEC @rt = [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFSynchronizeFileToMFilesInternal' -- nvarchar(500)
                                   ,@ProcedureName = 'Test'         -- nvarchar(500)
                                   ,@ProcedureStep = 'step'         -- sysname
                                   ,@Debug = 1
                                   SELECT @RT

                                   SELECT TOP 5 * FROM MFlog ORDER BY logid DESC
                                   
DECLARE @Status NVARCHAR(20);


DECLARE @VaultSettings NVARCHAR(400) = [dbo].[FnMFVaultSettings]()

EXEC [dbo].[spMFValidateModule] @VaultSettings = @VaultSettings -- nvarchar(2000)
                               ,@ModuleID = 4      -- nvarchar(20)
                               ,@Status = @Status OUTPUT                               -- nvarchar(20)
SELECT @Status

DECLARE @EcryptedPassword NVARCHAR(2000);

EXEC [dbo].[spMFEncrypt] @Password = 'Modules|1,2,3|2019-10-01' -- nvarchar(2000)
                        ,@EcryptedPassword = @EcryptedPassword OUTPUT      -- nvarchar(2000)
SELECT @EcryptedPassword

DECLARE @DecryptedPassword NVARCHAR(2000);

EXEC [dbo].[spMFDecrypt] @EncryptedPassword = '3QqMNe29EeCAu32uvhTHI0lkO8NVln3eKcoAaXx0daM=' -- nvarchar(2000)
                        ,@DecryptedPassword = @DecryptedPassword OUTPUT             -- nvarchar(2000)
SELECT * FROM [dbo].[fnMFSplitString](@DecryptedPassword,'|') [fmss]

GO

SELECT * FROM mfmodule

