
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
                            ,@RetainDeletions =0 -- bit
                           
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
-- NB this procedure cannot identify destroyed object
-------------------------------------------------------------
SELECT * FROM [dbo].[MFClass] AS [mc]


DECLARE @outputXML NVARCHAR(MAX);
DECLARE @VaultSettings NVARCHAR(200) = [dbo].[FnMFVaultSettings]()

EXEC [dbo].[spMFGetDeletedObjectsInternal] @VaultSettings = @VaultSettings    -- nvarchar(4000)
                                          ,@ClassID = 78       -- int
                                          ,@LastModifiedDate = null -- datetime
                                          ,@outputXML = @outputXML OUTPUT                            -- nvarchar(max)
SELECT CAST(@OUTPUTxml AS xml)

-------------------------------------------------------------
-- Identify destroyed object
-------------------------------------------------------------

DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFCustomer'    -- nvarchar(128)
                           ,@MFModifiedDate = null -- datetime
                           ,@ObjIDs = null         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0         -- smallint

SELECT @DeletedInSQL
SELECT CAST(@NewObjectXml AS XML)

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas] WHERE [mfas].[Class] = 'Customer'

SELECT objid, * FROM [dbo].[MFCustomer] AS [mc]

DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID1 INT;

EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'MFCustomer'  -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT          -- smalldatetime
                                    ,@UpdateTypeID = 1 -- tinyint
                                    ,@Update_IDOut = @Update_IDOut OUTPUT                  -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT           -- int
                                    ,@debug = 0       -- tinyint
