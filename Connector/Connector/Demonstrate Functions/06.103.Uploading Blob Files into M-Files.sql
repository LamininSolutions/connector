

/*

NB THIS PROCEDURE IS CURRENTLY UNDER REVISION

Uploading blob files involve
a) having a DB with all the files and source metadata. This could be a pre-exsiting third party application, or one can upload files from explorer into a temp db as part of the data refinement process and preparing the data for import, and then use MFSQL to import the data.

b) using MFSQL to extract the blob files and associate the files with metadata

*/



--************************************************************************************************************************
-------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------
-- SETUP demo environment: using the drawings document object in MF Sample Vault
-------------------------------------------------------------

EXEC dbo.spMFCreateTable 'Drawing';
EXEC dbo.spMFUpdateTable 'MFDrawing', 1;

SELECT *
FROM dbo.MFClass;

SELECT *
FROM dbo.MFDrawing;

-- note that this table does not have the required MFSQL properties. the properties can be added on the metadata card, or using SQL

ALTER TABLE MFDrawing
ADD  Mfsql_File_Unique_Ref NVARCHAR(100)

SELECT * FROM mfproperty WHERE [ColumnName] = 'Mfsql_File_Unique_Ref' 

-------------------------------------------------------------
-- View the folder that will be use as the temporary file export folder.
-------------------------------------------------------------

SELECT * FROM mfsettings WHERE name = 'FileTransferLocation'
-------------------------------------------------------------
-- EXTERNAL DB
--basic requirement is that each image must have a unique reference in the external table
-------------------------------------------------------------
--view the image source file in external database

SELECT *
FROM Scion32.scu.vw_Filedata AS vf
WHERE id = 22
--ORDER BY vf.id; --- note that this is a table from a different database with some images as blobs

-------Add New File-----------------------

-------------------------------------------------------------
-- Illustration 1:  Adding file to existing object in M-Files
-- the id is used as the unique reference to the file
-------------------------------------------------------------

--add the reference of the image to an object in the drawing file
UPDATE dbo.MFDrawing
SET Process_ID = 6
  , Mfsql_File_Unique_Ref = '22'  -- object 2 in the scion32 table will be used 
WHERE ID = 21;

DECLARE @ProcessBatch_id INT;
EXEC dbo.spMFSynchronizeFilesToMFiles @SourceTableName = 'scion32.scu.vw_Filedata',                -- varchar(100)
                                      @FileUniqueKeyColumn = 'ID',                            -- varchar(100)
                                      @FileNameColumn = 'FileName',                           -- varchar(100)
                                      @FileDataColumn = 'FileData',                           -- varchar(100)
                                     @MFTableName = 'MFDrawing',                               -- varchar(100)
                                      @BatchSize = 500,   
									   @Process_id = 6,                                  -- int
                                      @ProcessBatch_id = @ProcessBatch_id OUTPUT,             -- int
                                      @Debug = 101,                                             -- int
                                      @TargetFileUniqueKeycolumnName = 'mfsql_File_Unique_ref'; -- varchar(100)

									  DECLARE @ProcessBatch_id1 INT;
									  
	
--view wimport history table
SELECT *
FROM dbo.MFFileImport; 

--view status of drawing
SELECT id, name_or_title, MFVersion, FileCount, Single_File, mfsql_File_Unique_ref, *
FROM dbo.MFDrawing WHERE id = 21;

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID


GO

-------------------------------------------------------------
-- Illustrstion 2: Adding an image and metadata from source file 
-------------------------------------------------------------

--step 1: add new records in the target class with the associated file reference and metadata

INSERT INTO dbo.MFDrawing
(
    Mfsql_File_Unique_Ref,
    Keywords,
    Name_Or_Title,
    Process_ID
)
SELECT vf.id,
       'InsertFiles',
       vf.FileName,
       1
FROM Scion32.scu.vw_Filedata AS vf;

--step 2 Insert new records into MF

--UPDATE t 
-- SET Process_ID = 1
--FROM MFDrawing t WHERE Process_ID <> 0


--UPDATE t 
-- SET Process_ID = 1, t.Mfsql_File_Unique_Ref = null
--FROM MFDrawing t WHERE id = 2

EXEC spmfupdatetable 'MFDrawing',0

--Step 3 set process_id = 5 for the class items with files
UPDATE t 
 SET Process_ID = 6
FROM MFDrawing t 
INNER JOIN Scion32.scu.vw_Filedata AS vf
ON t.id IS NOT null



--Step 4: Update Records into M-Files

DECLARE @ProcessBatch_id INT;
EXEC dbo.spMFSynchronizeFilesToMFiles @SourceTableName = 'scion32.scu.vw_Filedata',                -- varchar(100)
                                      @FileUniqueKeyColumn = 'ID',                            -- varchar(100)
                                      @FileNameColumn = 'FileName',                           -- varchar(100)
                                      @FileDataColumn = 'FileData',                           -- varchar(100)
                                     @MFTableName = 'MFDrawing',                               -- varchar(100)
                                      @BatchSize = 500,  
									  @Process_ID = 6,                                     -- int
                                      @ProcessBatch_id = @ProcessBatch_id OUTPUT,             -- int
                                      @Debug = 1,                                             -- int
                                      @TargetFileUniqueKeycolumnName = 'mfsql_File_Unique_ref'; -- varchar(100)

SELECT *
FROM dbo.MFFileImport;
SELECT id, name_or_title, MFVersion, FileCount, Single_File, Mfsql_File_Unique_Ref, Process_ID
FROM dbo.MFDrawing;


SELECT *
FROM dbo.MFProcessBatchDetail AS mpbd
WHERE mpbd.ProcessBatch_ID = @ProcessBatch_id;

GO

--this is to reset the remaining records to be imported.
UPDATE dr
SET [dr].[Process_ID] = 5
FROM mfdrawing dr
left JOIN [dbo].[MFFileImport] AS [mfi]
ON dr.objid = mfi.[ObjID]
WHERE mfi.objid IS NULL AND dr.[Mfsql_File_Unique_Ref] IS NOT null

-------------------------------------------------------------
-- Illustration 3: Over writing and existing file in M-Files with the new file from external source
-------------------------------------------------------------


UPDATE dbo.MFDrawing
SET Process_ID = 5
WHERE Mfsql_File_Unique_Ref = '6';




EXEC dbo.spMFSynchronizeFilesToMFiles 'MFaccount',
                                      'ID',
                                      'FileName',
                                      'File',
                                      'Drawing',
                                      500;

-------------------------------Adding File to MultiFile Document-----------------------

UPDATE Mforder
SET process_id = 5
WHERE mfsql_File_Unique_ref = '2';

EXEC dbo.spMFSynchronizeFilesToMFiles 'MFaccount',
                                      'ID',
                                      'FileName',
                                      'File',
                                      'Order',
                                      500;


UPDATE dbo.MFDrawing
SET Process_ID = 0
WHERE Process_ID = 1;
DECLARE @Update_IDOut INT,
        @ProcessBatch_ID1 INT;
EXEC dbo.spMFUpdateTable @MFTableName = N'MFDrawing', -- nvarchar(200)
                         @UpdateMethod = 1;           -- smallint
