
/*


illustrate get deleted objects

to illustrate the function

a) using a class table 
Update item in table with auto delete


b) no class table

*/
--Created on: 2019-07-04 

-------------------------------------------------------------
-- update items with auto delete
-------------------------------------------------------------


EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer'     -- nvarchar(200)
                            ,@UpdateMethod = 1    -- int
                            ,@RetainDeletions = 1 -- bit
                           
GO

SELECT deleted, * FROM [dbo].[MFCustomer] AS [ma]

--Update deleted items in class table

SELECT * FROM mfCustomer WHERE deleted = 1

GO

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFGetDeletedObjects] @MFTableName = 'MFCustomer'      -- nvarchar(200)
                                  ,@LastModifiedDate = null -- datetime
                                  ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT                -- int
								  ,@RemoveDeleted = 1    -- bit
                                  ,@Debug = 0         -- smallint

								  GO

-------------------------------------------------------------
-- get deleted items from class
-------------------------------------------------------------
SELECT * FROM [dbo].[MFClass] AS [mc]


DECLARE @outputXML NVARCHAR(MAX);
DECLARE @VaultSettings NVARCHAR(200) = [dbo].[FnMFVaultSettings]()

EXEC [dbo].[spMFGetDeletedObjectsInternal] @VaultSettings = @VaultSettings    -- nvarchar(4000)
                                          ,@ClassID = 78       -- int
                                          ,@LastModifiedDate = null -- datetime
                                          ,@outputXML = @outputXML OUTPUT                            -- nvarchar(max)
SELECT CAST(@OUTPUTxml AS xml)