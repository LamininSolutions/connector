

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
When there is a need for performing updates into MF a record at a time then the following
procedure can be used.  This is only used in exceptional cases where complex update issues need to be resolved
*/
TRUNCATE TABLE [dbo].[MFOtherDocument]

Declare @SessionID int
exec spMFUpdateItemByItem @TableName = 'MFOtherDocument', @SessionIDOut = @SessionID output
Select @SessionID

--SHOW THE STATUS OF EACH OBJECT IN THE TABLE AUDIT HISTORY
select * from MFAuditHistory where SessionID = @SessionID

/*
Note from the listing if any objects are shown as status flag 5.  This implies that these objects could not be pulled through from M-Files and require further investigation. Note that there are two reasons why there could 
a items shown in status flag 5. a) it is a template b) it is document collection. In both cases these type of 
objects are ignored when updating from M-Files to SQL. 
*/

EXEC spmfupdatetable 'mfOtherDocument',1

DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX) 
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;
EXEC [dbo].[spMFTableAudit] @MFTableName = N'MFOtherDocument'                         -- nvarchar(128)
                           ,@MFModifiedDate = null    -- datetime
                           ,@ObjIDs = ???                             -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT       -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT       -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT   -- bit
                           ,@OutofSync = @OutofSync OUTPUT             -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                           ,@Debug = 0                               -- smallint

						   SELECT CAST(@NewObjectXml AS XML)

GO

DECLARE @Update_IDOut    INT
       ,@ProcessBatch_ID INT;
EXEC [dbo].[spMFUpdateTable] @MFTableName = N'MFOtherDocument'                         -- nvarchar(128)
                            ,@UpdateMethod = 1                          -- int
                            ,@UserId = null                              -- nvarchar(200)
                            ,@MFModifiedDate = null    -- datetime
                            ,@ObjIDs = ????                      -- nvarchar(max)
                            ,@Update_IDOut = @Update_IDOut OUTPUT       -- int
                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                            ,@SyncErrorFlag = NULL                      -- bit
                            ,@Debug = 0                                 -- smallint

SELECT * FROM [dbo].[MFUpdateHistory] AS [muh] WHERE id = @Update_IDOut

Go

