/*
These scripts prepare and show how Sync Precedence for M-Files taking precedence operate

the example use MFCustomer table with objid id 135
*/

SELECT [mc].[Address_Line_2], [mc].[Process_ID], [mc].[MFVersion], [mc].[ObjID] FROM [dbo].[MFCustomer] AS [mc]
WHERE objid = 135

SELECT * FROM [dbo].[MFClass] AS [mc]

--set precendence for the MFCustomer table
update [dbo].[MFClass]
SET [SynchPrecedence] = 1
WHERE MFID = 78

--make a change in SQL
UPDATE [dbo].[MFCustomer]
SET [Process_ID] = 1, [Address_Line_2] = 'New Address 2.1'
WHERE objid = 135

--make change to objid 135 in M-Files

--execute an update.  
DECLARE @Update_ID INT, @ProcessBatch_ID int
EXEC spmfupdatetable @MFTableName = 'MFCustomer',@UpdateMethod = 0, @Update_IDOut = @Update_ID OUTPUT, @ProcessBatch_ID = @ProcessBatch_ID output


SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

		-- check the result
		-- note from the Update_ID and process log that the update procedure ran a second time to set the sync error to the correct precedence.

SELECT [mc].[Address_Line_2], [mc].[Process_ID], [mc].[MFVersion], [mc].[ObjID] FROM [dbo].[MFCustomer] AS [mc]
WHERE objid = 135

		-- note that no error messages was generated for the sync error

SELECT TOP 3 * FROM MFLog ORDER BY logid desc
