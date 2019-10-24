/*
These scripts prepare and show how Sync Precedence for SQL taking precedence operate

The expectation is that if SQL presedence is set ( set to 0 in MFClass for class table) then an update from SQL to MF should be processed, irrespective of any changes in M-Files.  No error report is produced.)

the example use MFCustomer table with objid id 135
*/

SELECT [mc].[Address_Line_2], [mc].[Process_ID], [mc].[MFVersion], [mc].[ObjID] FROM [dbo].[MFCustomer] AS [mc]
WHERE objid = 135

SELECT * FROM [dbo].[MFClass] AS [mc]

--set precendence for the MFCustomer table
update [dbo].[MFClass]
SET [SynchPrecedence] = 0
WHERE MFID = 78

--make a change in SQL
UPDATE [dbo].[MFCustomer]
SET [Process_ID] = 1, [Address_Line_2] = 'New Address 2.134', autoCalc = 'aut0', [Address_Line_1] = 'New 5'
WHERE objid = 135

--make change to objid 135 in M-Files. Take note of the version no.

--execute an update.  Note that spMFUpdateSynchronizeError must be included in the script just after the execution of spmfupdatetable
DECLARE @Update_ID INT, @ProcessBatch_ID int
EXEC spmfupdatetable @MFTableName = 'MFCustomer',@UpdateMethod = 0, @Update_IDOut = @Update_ID OUTPUT, @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, @Debug = 0


SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

		-- check the result
		-- note from the Update_ID and process log that the update procedure ran a second time to set the sync error to the correct precedence.

SELECT [mc].[Address_Line_2], [mc].[Process_ID], [mc].[MFVersion], [mc].[ObjID] ,*
FROM [dbo].[MFCustomer] AS [mc]
WHERE objid = 135

-- check M-Files - Refresh item to pull through the update. Take note of the version no after the update. It should show the update from SQL.

		-- note that no error messages was generated for the sync error
		-- note the version has changed from the version when the update was made in M-Files.

SELECT TOP 3 * FROM MFLog ORDER BY logid desc
