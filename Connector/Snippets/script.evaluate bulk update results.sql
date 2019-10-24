
/*
scripts to evaluate large volume processing results
*/
--Created on: 2019-06-17 

TRUNCATE TABLE MFLarge_Volume
TRUNCATE TABLE [dbo].[MFAuditHistory]

SELECT  MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
WHERE class = 96


SELECT [mah].[SessionID]
,[mah].[Class]
      ,[mah].[TranDate]
      ,[mah].[StatusFlag]
FROM [dbo].[MFAuditHistory] AS [mah];

SELECT *
FROM [dbo].[MFAuditHistory] AS [mah]
WHERE [mah].[SessionID] = 11;

SELECT *
FROM [dbo].[MFAuditHistory] AS [mah]
WHERE [mah].[StatusFlag] = 1;

SELECT *
FROM [dbo].[MFAuditHistory] AS [mah]
WHERE [mah].[ObjID] = 80313;

SELECT *
FROM [dbo].[MFAuditHistory]
WHERE [StatusFlag] = 5;

SELECT * FROM [dbo].[MFAuditHistory] AS [mah] WHERE [mah].[Class] = (SELECT MFID FROM MFclass WHERE name = 'Basic_SingleProp')



SELECT *
FROM [dbo].[MFvwAuditSummary] AS [mfas];

SELECT [mlv].[Update_ID]
      ,[mlv].[LastModified]
      ,COUNT(*)
FROM [dbo].[MFLarge_volume] AS [mlv]
GROUP BY [mlv].[Update_ID]
        ,[mlv].[LastModified]
ORDER BY [mlv].[LastModified] DESC;

SELECT [mlv].[MFVersion]
      ,[mlv].[ObjID]
      ,*
FROM [dbo].[MFLarge_volume] AS [mlv]
WHERE [mlv].[ObjID] = 79907;

SELECT [objid]
      ,[mfversion]
      ,[s].[lastmodified]
      ,*
FROM [mfbasic_SingleProp] [s]
ORDER BY [s].[lastmodified] DESC;

SELECT [mlv].[MFVersion]
      ,[mlv].[ObjID]
      ,*
FROM [dbo].[MFLarge_volume] AS [mlv]
WHERE [mlv].[Update_ID] = 897;



SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

									 
SELECT * FROM MFBasic_SingleProp






SELECT *
FROM [dbo].[MFAuditHistory] AS [mah]
WHERE [mah].[ObjID] = 193269;

SELECT *
FROM [dbo].[MFvwAuditSummary] AS [mfas]
WHERE [mfas].[TableName] = 'MFBasic_SingleProp';

--Delete
-- FROM [dbo].[MFAuditHistory]
-- WHERE id IN (SELECT mah.id from [dbo].[MFAuditHistory] mah
-- left JOIN [dbo].[MFLarge_volume] AS [mlv]
-- ON mlv.objid = mah.[ObjID] AND mlv.[Class_ID] = mah.[Class]
-- WHERE mlv.id IS NULL) 

SELECT * FROM mflog order BY logid DESC
