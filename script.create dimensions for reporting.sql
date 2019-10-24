
/*

*/
--Created on: 2019-04-08 

DECLARE @Class NVARCHAR(100) = 'Contract or Agreement'
DECLARE @MFTableName NVARCHAR(100)
DECLARE @Rowid INT
DECLARE @DimTableName NVARCHAR(200)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Params  NVARCHAR(MAX)
DECLARE @ValuelistID int

SELECT @MFTableName = Tablename FROM mfclass WHERE name = ''
DECLARE @list AS TABLE
(
    [id] INT 
   ,[Name] NVARCHAR(100)
   ,[Dim_Name] NVARCHAR(200)
);

INSERT INTO @list
SELECT DISTINCT mfms.[Valuelist_ID],[mfms].[Valuelist]
      ,'Dim_' + [dbo].[fnMFReplaceSpecialCharacter]([mfms].[Valuelist])
FROM  [dbo].[MFvwMetadataStructure] AS [mfms]
INNER JOIN [dbo].[MFValueList] AS [mvl]
ON [mfms].[Valuelist_MFID] = mvl.[MFID]
WHERE class = @class
 AND [mvl].[RealObjectType] = 0
 
 SELECT @rowid = MIN(ID) FROM @list

 WHILE @rowid IS NOT NULL
 BEGIN
 
 SELECT @ValuelistID = id , @DimTableName = Dim_Name FROM @list AS [l] WHERE  id = @Rowid

 SELECT @DimTableName
 

 IF exists(SELECT 1 FROM sys.[tables] AS [t] WHERE [t].[name] = @DimTableName)
 BEGIN
 SET @SQL = N'DROP TABLE Report.'+ QUOTENAME(@DimTableName)+''
EXEC(@SQL)
END

SET @SQL = 'CREATE TABLE Report. ' + QUOTENAME(@DimTableName)+'
( [ID] NVARCHAR(100)
   ,[ItemName] NVARCHAR(100)
)'

EXEC(@SQL)

ALTER TABLE [dbo].[MFContractOrAgreement] --quotename(@DimtableName)
Ad


SET @SQL = '
INSERT INTO Report.' + QUOTENAME(@DimTableName)+'

SELECT MFID, Name FROM MFValuelistItems WHERE [MFValueListID] = @ValuelistID'

EXEC sp_executeSQL @SQL, N'@ValuelistID int', @ValuelistID

SELECT @Rowid = (SELECT MIN(id) FROM @List WHERE id > @Rowid)
END


