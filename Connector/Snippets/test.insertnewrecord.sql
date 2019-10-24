
DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsStructureOnly = 1



INSERT INTO [dbo].[MFInternalProject]
(
  
   [In_Progress]
   ,[Name_Or_Title]
   ,[Project_Manager_ID]
   ,[Process_ID]
   ,[ExternalID]
  
)
VALUES
(  1, 'test 5',1,1,'TR2'
    )					
	
	EXEC spmfupdatetable @MFTableName = 'MFInternalProject'	, @UpdateMethod = 0, @Updatemetadata = 1, @Debug = 100
				
			