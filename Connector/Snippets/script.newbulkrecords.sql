
/*

*/
--Created on: 2019-06-12 

SELECT * FROM [dbo].[MFLarge_volume] AS [mlv] WHERE [mlv].[Process_ID] <> 0


INSERT INTO [dbo].[MFLarge_volume]
(
   
   [Mfsql_Message]
  
   ,[Name_Or_Title]
  
   ,[Process_ID]
  
)
SELECT 'Inserted 2019-06-13', Name_or_title + ' ' + CAST(id AS NVARCHAR(100)),1 FROM [dbo].[MFLarge_volume] AS [mlv]

EXEC spmfupdatetable 'MFLarge_Volume',1
