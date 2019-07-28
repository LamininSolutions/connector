

/*
LESSON NOTES

How to export update history for a property into SQL.

This example show how to get the comments from an object (Use the Adding comments example to update comments from SQL to MF)

see example for adding comments to an object or add comments manually to customer to aid the example
04.160 adding comments

applies from version 3.1.4.40 

All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

--get and review tables used in the example

SELECT * FROM mfcustomer

SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC spmfcreatetable 'purchase invoice'
EXEC spmfupdatetable 'MFPurchaseInvoice',1

-- prepare table : mark the costomers for which the comment history is required

UPDATE [dbo].[MFCustomer]
SET [Process_ID] = 5

--get comments

DECLARE @ProcessBatch_id INT;
EXEC [dbo].[spMFGetHistory]
    @MFTableName = 'MfCustomer',
    @Process_id = 5,
    @ColumnNames = 'Comment' ,
    @IsFullHistory = 1,
    @ProcessBatch_id = @ProcessBatch_id OUTPUT,
    @Debug = 0

	SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_id

--review results in history table

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch2]

-- use a join to show related information for reporting purposes

	SELECT mc.[Name_Or_Title] AS Customer, moch.[LastModifiedUtc], [moch].[Property_Value] AS Comment 
	,[mla].[AccountName] AS Modified_by
	FROM [dbo].[MFObjectChangeHistory] AS [moch]
	INNER JOIN [dbo].[MFLoginAccount] AS [mla]
	ON mla.[MFID] = [moch].[MFLastModifiedBy_ID]
	INNER JOIN [dbo].[MFCustomer] AS [mc]
	ON moch.[ObjID] = mc.[ObjID]


	
