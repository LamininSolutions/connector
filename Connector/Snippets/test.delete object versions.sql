
/*
Test object delete
*/
--Created on: 2019-08-21 

-----------------------------------------------------
DECLARE @VaultSettings NVARCHAR(4000);
DECLARE @Return_Value INT;
DECLARE @processBatch_ID int

-----------------------------------------------------
-- SELECT CREDENTIAL DETAILS
-----------------------------------------------------
SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

DECLARE @ObjectTypeId      INT           = 136
       ,@objectId          INT           = 134
       ,@Output            NVARCHAR(2000)
       ,@ObjectVersion     INT           = 10
       ,@DeleteWithDestroy BIT           = 1;

EXEC @Return_Value = [dbo].[spMFDeleteObjectInternal] @VaultSettings
                                                     ,@ObjectTypeId
                                                     ,@objectId
                                                     ,@DeleteWithDestroy
                                                     ,@ObjectVersion
                                                     ,@Output OUTPUT;

SELECT CAST(@Output AS XML);

SELECT @Return_Value;

EXEC @Return_Value = [dbo].[spMFDeleteObject] @ObjectTypeId = @ObjectTypeId            -- int
                                             ,@objectId = @objectId                    -- int
                                             ,@Output = @Output OUTPUT                 -- nvarchar(2000)
                                             ,@ObjectVersion = @ObjectVersion          -- int
                                             ,@DeleteWithDestroy = @DeleteWithDestroy
											 ,@ProcessBatch_ID = @ProcessBatch_ID output -- bit
											 ,@Debug = 0

SELECT CAST(@Output AS XML);

SELECT @Return_Value;



SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
