

/*
LESSON NOTES

How to export update history for a property into SQL.

This example show how to get the Workflow States from an object 

applies from version 3.1.4.40 

All examples use the Sample Vault as a base

Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

--get and review tables used in the example

SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC spmfcreatetable 'purchase invoice'
EXEC spmfupdatetable 'MFPurchaseInvoice',1

SELECT * FROM [dbo].[MFPurchaseInvoice] AS [mpi]

-- prepare table : mark the costomers for which the comment history is required

UPDATE [dbo].MFPurchaseInvoice
SET [Process_ID] = 5

--get Workflow States

DECLARE @ProcessBatch_id INT;
EXEC [dbo].[spMFGetHistory]
    @MFTableName = 'MFPurchaseInvoice',
    @Process_id = 5,
    @ColumnNames = 'Workflow_State_id' ,
    @IsFullHistory = 1,
    @ProcessBatch_id = @ProcessBatch_id OUTPUT,
    @Debug = 0

	SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_id

--review results in history table

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch2]

-- use a join to show related information for reporting purposes

SELECT [mpi].[Class_ID],
       [mpi].[ObjID],
       [moch].[MFVersion],
	   mua.[LoginName],
       [mpi].[Name_Or_Title],
       [moch].[Property_Value],
	   mws.[Name]
FROM [dbo].[MFPurchaseInvoice] [mpi]
    INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
        ON [moch].[Class_ID] = [mpi].[Class_ID]
           AND [moch].[ObjID] = [mpi].[ObjID]
    INNER JOIN [dbo].[MFUserAccount] AS [mua]
        ON [mua].[UserID] = [moch].[MFLastModifiedBy_ID]
    INNER JOIN [dbo].[MFWorkflowState] AS [mws]
        ON [moch].[Property_Value] = [mws].[MFID]
WHERE mpi.[ObjID] = 361 

	
-- who caused the workflow state change for the current object

SELECT [mpi].[Class_ID],
       [mpi].[ObjID],
       [moch].[MFVersion],
	   mua.[LoginName],
       [mpi].[Name_Or_Title],
       [moch].[Property_Value],
	   mws.[Name]
FROM [dbo].[MFPurchaseInvoice] [mpi]
    INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
        ON [moch].[Class_ID] = [mpi].[Class_ID]
           AND [moch].[ObjID] = [mpi].[ObjID]
		   AND moch.[MFVersion] = mpi.[MFVersion]
    INNER JOIN [dbo].[MFUserAccount] AS [mua]
        ON [mua].[UserID] = [moch].[MFLastModifiedBy_ID]
    INNER JOIN [dbo].[MFWorkflowState] AS [mws]
        ON [moch].[Property_Value] = [mws].[MFID]
WHERE mpi.[ObjID] = 361 