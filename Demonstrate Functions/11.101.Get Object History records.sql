



		-------------------------------------------------------------
	    -- GET HISTORY RECORDS
	    -------------------------------------------------------------

		
/*
Using spMFGetHistory

*/
SELECT * FROM [dbo].[MFPurchaseInvoice] AS [mc] WHERE [mc].[Process_ID] = 1

EXEC spmfupdatetable 'MFPurchaseInvoice',1

--execute from here

UPDATE MFPurchaseInvoice
SET Process_ID = 1

DECLARE @RC INT
DECLARE @TableName NVARCHAR(128) = 'MFPurchaseInvoice'
DECLARE @Process_id INT = 1
DECLARE @ColumnNames NVARCHAR(4000) = 'State_ID,Assigned_To_ID'
DECLARE @IsFullHistory BIT = 1
DECLARE @NumberOFDays INT  
DECLARE @StartDate DATETIME --= DATEADD(DAY,-1,GETDATE())
DECLARE @ProcessBatch_id INT
DECLARE @Debug INT = 0

EXECUTE @RC = [dbo].[spMFGetHistory] 
   @TableName
  ,@Process_id
  ,@ColumnNames
  ,@IsFullHistory
  ,@NumberOFDays
  ,@StartDate
  ,@ProcessBatch_id OUTPUT
  ,@Debug

SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_id
SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_id

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]

--to here

-- show list of values including property value

SELECT toh.*,mp.name AS propertyname FROM mfobjectchangehistory toh
INNER JOIN mfproperty mp
ON mp.[MFID] = toh.[Property_ID]
ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]

-- show list of values where property is a state

SELECT toh.*,mp.name AS propertyname, [mws].[Name] AS State FROM mfobjectchangehistory toh
INNER JOIN mfproperty mp
ON mp.[MFID] = toh.[Property_ID]
LEFT JOIN [dbo].[MFWorkflowState] AS [mws]
ON mws.mfid = toh.[Property_Value]
WHERE toh.[Property_ID] = 39
ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]
GO
