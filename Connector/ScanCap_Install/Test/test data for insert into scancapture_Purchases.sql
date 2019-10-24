

SELECT * FROM scancap.[ConfigurationMap] AS [mcm] 

--Delete all items from M-files

exec [dbo].[spMFUpdateTable] @MFTableName = N'MFVendorInvoiceDocument', -- nvarchar(128)
    @UpdateMethod = 1, -- int
    @UserId = null, -- nvarchar(200)
    @MFModifiedDate = null, -- datetime
    @ObjIDs = null, -- nvarchar(4000)
    @Update_IDOut = 0, -- int
    @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint

SELECT * FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]

UPDATE t 
SET process_id = 10
FROM [dbo].[MFVendorInvoiceDocument] t

EXEC [dbo].[spMFDeleteObjectList] @tablename = 'MFVendorInvoiceDocument', @process_ID = 10,@DeleteWithDestroy = 1


exec [dbo].[spMFUpdateTable] @MFTableName = N'MFApInvoiceLine', -- nvarchar(128)
    @UpdateMethod = 1, -- int
    @UserId = null, -- nvarchar(200)
    @MFModifiedDate = null, -- datetime
    @ObjIDs = null, -- nvarchar(4000)
    @Update_IDOut = 0, -- int
    @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint

SELECT * FROM dbo.MFAPInvoiceLine AS CIL
UPDATE t 
SET process_id = 10
FROM [dbo].[MFApInvoiceLine] t

EXEC [dbo].[spMFDeleteObjectList] @tablename = 'MFApInvoiceLine', @process_ID = 10, @DeleteWithDestroy = 1


exec [dbo].[spMFUpdateTable] @MFTableName = N'MFApInvoice', -- nvarchar(128)
    @UpdateMethod = 1, -- int
    @UserId = null, -- nvarchar(200)
    @MFModifiedDate = null, -- datetime
    @ObjIDs = null, -- nvarchar(4000)
    @Update_IDOut = 0, -- int
    @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint

	SELECT * FROM dbo.MFApInvoice AS MAI
UPDATE t 
SET process_id = 10
FROM [dbo].[MFApInvoice] t

EXEC [dbo].[spMFDeleteObjectList] @tablename = 'MFApInvoice', @process_ID = 10,@DeleteWithDestroy = 1

TRUNCATE TABLE [ScanCap].[ScanCaptureLog]
TRUNCATE TABLE dbo.Ancora_Invoices

--Payments

--exec [dbo].[spMFUpdateTable] @MFTableName = N'MFVendorPaymentDoc', -- nvarchar(128)
--    @UpdateMethod = 1, -- int
--    @UserId = null, -- nvarchar(200)
--    @MFModifiedDate = null, -- datetime
--    @ObjIDs = null, -- nvarchar(4000)
--    @Update_IDOut = 0, -- int
--    @ProcessBatch_ID = 0, -- int
--    @Debug = 0 -- smallint



--UPDATE t 
--SET process_id = 10
--FROM [dbo].[MFVendorPaymentDoc] t

--EXEC [dbo].[spMFDeleteObjectList] @tablename = 'MFVendorPaymentDoc', @process_ID = 10,@DeleteWithDestroy = 1


exec [dbo].[spMFUpdateTable] @MFTableName = N'MFVendor', -- nvarchar(128)
    @UpdateMethod = 1, -- int
    @UserId = null, -- nvarchar(200)
    @MFModifiedDate = null, -- datetime
    @ObjIDs = null, -- nvarchar(4000)
    @Update_IDOut = 0, -- int
    @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint



UPDATE t 
SET process_id = 10
FROM [dbo].[MFVendor] t

EXEC [dbo].[spMFDeleteObjectList] @tablename = 'MFVendor', @process_ID = 10,@DeleteWithDestroy = 1


--TRUNCATE TABLE [dbo].[MFVendorInvoiceDocument] 

--TRUNCATE TABLE [dbo].[MFApInvoice]
--TRUNCATE TABLE [dbo].[MFApInvoiceLine]


SELECT * FROM dbo.Ancora_Invoices AS AI
SELECT * FROM [ScanCap].[ScanCaptureLog] AS [scl]
SELECT * FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
SELECT * FROM [dbo].[MFApInvoice] AS [ci]

SELECT * FROM [dbo].[MFVendor] AS [cv]
SELECT * from dbo.Ancora_Invoices AS  i
SELECT DISTINCT filename FROM dbo.Ancora_Invoices AS  i


exec [dbo].[spMFUpdateTable] @MFTableName = N'MFApInvoice', -- nvarchar(128)
    @UpdateMethod = 0, -- int
    @UserId = null, -- nvarchar(200)
    @MFModifiedDate = null, -- datetime
    @ObjIDs = null, -- nvarchar(4000)
    @Update_IDOut = 0, -- int
    @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint


SELECT [ci].[ObjID] FROM [dbo].[MFApInvoice] AS [ci]

SELECT * FROM dbo.[MFContextMenu] AS [mcm]

SELECT * FROM [ScanCap].[ScanCaptureLog] AS [scl]
UPDATE scl
SET [scl].[UpdateStatus] = 'Initiated' , status_ID = 0 
FROM [ScanCap].[ScanCaptureLog] AS [scl] WHERE logid = 1

SELECT * FROM scancap.ancora_invoices_back AS AIB  
SELECT * FROM dbo.Ancora_Invoices  AS [i]
SELECT * FROM [dbo].[MFApInvoice] AS [ci] 

EXEC [ScanCap].[GetScannedData] @ProcessBatch_ID = 0, -- int
    @Debug = 0 -- smallint
   


	SELECT mpbd.* FROM dbo.MFProcessBatch AS MPB 
	INNER JOIN dbo.MFProcessBatchDetail AS MPBD
	ON mpb.ProcessBatch_ID = mpbd.ProcessBatch_ID
	ORDER BY MPB.ProcessBatch_ID desc
	WHERE MPB.ProcessBatch_ID = 1064

	SELECT * FROM mflog ORDER BY logid DESC
    

