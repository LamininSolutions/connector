
/*
Export files from M-Files
*/

-------------------------------------------------------------
-- Prepare example (Exporting all invoices from Sales Invoice class
-------------------------------------------------------------
SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC spmfcreatetable 'Sales Invoice'

EXEC spmfupdatetable 'MFSalesInvoice',1

SELECT * FROM mfsalesinvoice

--mark records for files to be exported
UPDATE MFSalesInvoice
SET process_Id = 5 WHERE filecount > 1

-------------------------------------------------------------
-- Review settings related to exporting of files
-------------------------------------------------------------

--location where files will be exported to

SELECT * FROM mfsettings WHERE name = 'RootFolder'  --all files will be exported to C:\MFSQL\FileExport\ on the SQL server

--base folder for exporting of files for selected items in class

SELECT * FROM mfclass WHERE tablename = 'MFSalesInvoice'

/*
Note that if FileExportFolder column is null, then the export will go to the root folder.
if the files must be shown 
*/

DECLARE @ProcessBatch_ID INT;
EXEC [dbo].[spMFExportFiles] @TableName = 'MFSalesInvoice',       -- nvarchar(128)
                             @PathProperty_L1 = null, -- nvarchar(128)
                             @PathProperty_L2 = null, -- nvarchar(128)
                             @PathProperty_L3 = null, -- nvarchar(128)
                             @IncludeDocID = 0,    -- bit
                             @Process_id = 5,      -- int
                             @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,               -- int
                             @Debug = 101           -- int

							 
							 
							 SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
							 
--check the files on the SQL Server

--check the file export history

SELECT * FROM [dbo].[MFExportFileHistory] AS [mefh]






