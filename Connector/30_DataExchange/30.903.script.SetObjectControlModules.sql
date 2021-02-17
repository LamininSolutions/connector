
/*

script to set the module assignments in setup.MFSQLObjectControl
this script is executed as part of the installation procedure
new modules must be added by hand into this script to be licensed

*/
GO

PRINT SPACE(10) + '... MFSQLObjectsControl Initialised';

SET NOCOUNT ON

IF (SELECT OBJECT_ID('setup.MFSQLObjectsControl')) IS NULL
RAISERROR('Incomplete installation - run installation package again',16,1);

IF (SELECT OBJECT_ID('tempdb..#tmp_GridResults_1')) IS NOT NULL
DROP TABLE #tmp_GridResults_1;

SELECT * INTO #tmp_GridResults_1
FROM (
SELECT N'spMFCreateObjectInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFCreatePublicSharedLinkInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFDecrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFDeleteObjectInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFEncrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetClass' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetDataExportInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetFilesListInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetFilesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetHistoryInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetLoginAccounts' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetMFilesLogInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spmfGetMFilesVersionInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetObjectType' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetObjectVersInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetProperty' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetUserAccounts' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetValueList' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetValueListItems' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetWorkFlow' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetWorkFlowState' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFSearchForObjectByPropertyValuesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFSearchForObjectInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFSynchronizeFileToMFilesInternal' AS [name], N'3' AS [Module] UNION ALL
SELECT N'spMFSynchronizeValueListItemsToMFilesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFUpdateClass' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateObjectType' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateProperty' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdatevalueList' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateWorkFlow' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetUnManagedObjectDetails' AS [name], N'3' AS [Module] UNION ALL
SELECT N'spMFCreateTable' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetHistory' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateWorkFlowState' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateExplorerFileToMFiles' AS [name], N'2' AS [Module]  UNION ALL
SELECT N'spMFRemoveAdditionalProperties' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFSendHTMLBodyEmail' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFPrepareTemplatedEmail' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFExportFiles' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFConvertTableToHtml' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetFilesDetails' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFDeleteObjectVersionList' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFImportBlobFilesToMFiles' AS [name], N'2' AS [Module] ) t;



--SELECT [name], [Module]
--FROM #tmp_GridResults_1

;
WITH cte AS
(
 SELECT  s.[name] AS [schema] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'MF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'spMF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%'
)
MERGE INTO setup.MFSQLObjectsControl t
USING (
SELECT cte.[schema],
       cte.[name],
       cte.[object_id],
       cte.[type],
       cte.modify_date,
       ISNULL(tgr.Module,1) AS Module FROM cte
LEFT JOIN #tmp_GridResults_1 AS tgr
ON cte.name = tgr.name) s
ON t.[Schema] = s.[schema] AND t.Name = s.name
WHEN MATCHED THEN UPDATE SET
t.Module =  s.Module
WHEN NOT MATCHED
THEN INSERT
(
[Schema]
,Name
,[object_id]
,Type
,Modify_Date
,Module
)
VALUES
(s.[schema],s.name,s.[object_id],s.type,s.modify_date,1)
;

DROP TABLE #tmp_GridResults_1

--SELECT * FROM setup.MFSQLObjectsControl AS moc
GO
