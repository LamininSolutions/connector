
/*

Test functionality version 48

*/
--Created on: 2019-03-09 

-------------------------------------------------------------
-- Import files from explorer
--This procedure imports a file or files from explorer to the objid referenced in parameter
--The object can be created in M-Files using MFSQL Connector at the same time as importing the file.
--If another file is added to a single file object, it would automatically be converted to a multifile
--Refresh M-Files view or the object F5 after running procedure to update the object to the latest version
-------------------------------------------------------------
-- The file location should point to the folder of the file the be imported
-- set IsFileDelete param = 1 if the file must be deleted after import
-- check the table MFFileImport for the results of the import


--SELECT * FROM [dbo].[MFOtherDocument] AS [mod]

--delete from MFFileImport
DECLARE @ProcessBatch_id INT;
DECLARE @FileLocation NVARCHAR(256) = 'C:\Share\Fileimport\2\'
DECLARE @FileName NVARCHAR(100) = 'CV - TommyS Hart.docx'
DECLARE @TableName NVARCHAR(256) = 'MFOtherDocuments'
DECLARE @SQLID INT = 1


 EXEC [dbo].[spMFUpdateExplorerFileToMFiles] 
	@FileName = @FileName
	,@FileLocation = @FileLocation 
	,@MFTableName = @TableName
	,@SQLID = @SQLID        																	
	,@ProcessBatch_id = @ProcessBatch_id OUTPUT      
	,@Debug = 101      
	,@IsFileDelete = 0
																					
SELECT * from [dbo].[MFFileImport] AS [mfi]			

SELECT * FROM [dbo].[MFClass] AS [mc]

SELECT * FROM [dbo].[MFOtherDocuments] AS [mod]
