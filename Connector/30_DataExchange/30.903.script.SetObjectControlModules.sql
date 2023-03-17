
/*

script to set the module assignments in setup.MFSQLObjectControl
this script is executed as part of the installation procedure
new modules must be added by hand into this script to be licensed
add assembly modules to table and show which modules are logged.

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
SELECT N'spMFExportFiles' AS [name], N'2' AS [Module] UNION all
SELECT N'spMFExportFilesMultiClasses' AS [name], N'2' AS [Module] UNION all
SELECT N'spMFConvertTableToHtml' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetFilesDetails' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFDeleteObjectVersionList' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFUnDeleteObject' AS [name], N'2' AS [Module] UNION ALL
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
,t.[object_id]= s.[object_id]
,t.[type] = s.[type]
,t.modify_date = s.modify_date
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

IF (SELECT OBJECT_ID('tempdb..#controllist')) IS NOT null
DROP TABLE #controllist;
CREATE table #controllist (ProcName NVARCHAR(100),Method NVARCHAR(100),Logging bit)

INSERT INTO #controllist
(
    ProcName,
    Method,
    Logging
)
VALUES

('spMFEncrypt','Laminin.Security.Laminin.CryptoEngine.Encrypt',0),
('spMFGetClass','LSConnectMFilesAPIWrapper.MFilesWrapper.GetMFClasses',0),
('spMFGetLoginAccounts','LSConnectMFilesAPIWrapper.MFilesWrapper.GetLoginAccounts',0),
('spMFGetDataExportInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.ExportDataSet',0),
('spMFGetObjectType','LSConnectMFilesAPIWrapper.MFilesWrapper.GetObjectTypes',0),
('spMFGetObjectVersInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetOnlyObjectVersions',1),
('spMFGetProperty','LSConnectMFilesAPIWrapper.MFilesWrapper.GetProperties',0),
('spMFGetUserAccounts','LSConnectMFilesAPIWrapper.MFilesWrapper.GetUserAccounts',0),
('spMFGetValueList','LSConnectMFilesAPIWrapper.MFilesWrapper.GetValueLists',0),
('spMFGetValueListItems','LSConnectMFilesAPIWrapper.MFilesWrapper.GetValueListItems',0),
('spMFGetWorkFlow','LSConnectMFilesAPIWrapper.MFilesWrapper.GetMFWorkflow',0),
('spMFGetWorkFlowState','LSConnectMFilesAPIWrapper.MFilesWrapper.GetWorkflowStates',0),
('spMFSearchForObjectByPropertyValuesInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.SearchForObjectByProperties',1),
('spMFSearchForObjectInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.SearchForObject',1),
('spMFUpdateClass','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdateClassAliasInMFiles',1),
('spMFUpdateProperty','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdatePropertyAliasInMFiles',1),
('spMFUpdateObjectType','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdateObjectTypeAliasInMFiles',1),
('spMFUpdatevalueList','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdateValueListAliasInMFiles',1),
('spMFUpdateWorkFlow','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdateWorkFlowtAliasInMFiles',1),
('spMFUpdateWorkFlowState','LSConnectMFilesAPIWrapper.MFilesWrapper.UpdateWorkFlowtStateAliasInMFiles',1),
('spMFGetWorkFlowState','LSConnectMFilesAPIWrapper.MFilesWrapper.GetWorkflowStates',0),
('spMFCreateObjectInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.CreateNewObject',1),
('spmfGetMFilesVersionInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetMFilesVersion',1),
('spMFDecrypt','Laminin.Security.Laminin.CryptoEngine.Decrypt',0),
('spMFSynchronizeValueListItemsToMFilesInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.SynchValueListItems',1),
('spMFCreatePublicSharedLinkInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetPublicSharedLink',1),
('spMFGetMFilesLogInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetMFilesEventLog',1),
('spMFGetFilesInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetFiles--nolongerused',0),
('spMFGetFilesListInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetFilesList',1),
('spMFGetHistoryInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetHistory',1),
('spMFSynchronizeFileToMFilesInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.Importfile',1),
('spMFImportBlobFileToMFilesInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.ImportBlobfile',1),
('spMFValidateModule','LSConnectMFilesAPIWrapper.MFilesWrapper.ValidateModule',1),
('spMFGetMetadataStructureVersionIDInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetMetadataStructureVersionID',0),
('spMFGetUnManagedObjectDetails','LSConnectMFilesAPIWrapper.MFilesWrapper.GetUnManagedObjectDetails',1),
('spMFGetDeletedObjectsInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetDeletedObjects',1),
('spmfGetLocalMFilesVersionInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.GetLocalMFilesVersion',1),
('spMFConnectionTestInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.ConnectionTest',1),
('spMFDeleteObjectListInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.DeleteObjectList',1),
('spMFUnDeleteObjectListInternal','LSConnectMFilesAPIWrapper.MFilesWrapper.UnDeleteObjectList',1)

UPDATE moc
SET clrmodule = l.method, logging = l.logging
FROM setup.MFSQLObjectsControl AS moc
LEFT JOIN #controllist AS l
ON l.ProcName = moc.Name
WHERE type = 'pc'

--SELECT * FROM setup.MFSQLObjectsControl AS moc
GO
