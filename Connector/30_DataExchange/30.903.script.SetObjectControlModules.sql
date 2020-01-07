/*

script to set the module assignments in setup.MFSQLObjectControl
this script is executed as part of the installation procedure
new modules must be added by hand into this script to be licensed

*/
GO

SET NOCOUNT ON


	   PRINT SPACE(10) + '... MFSQLObjectsControl Initialised';

              TRUNCATE TABLE Setup.[MFSQLObjectsControl];

                INSERT  INTO Setup.[MFSQLObjectsControl]
                        ( [Schema] ,
                          [Name] ,
                          [object_id] ,
                          [Type] ,
                          [Modify_Date]
                        )
                        
                       
                        SELECT  s.[name] ,
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
--UNION ALL
--SELECT s.[name],objects.Name, [objects].[object_id], type, [objects].[modify_date] FROM sys.objects
--INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id] WHERE [objects].[name] like 'tMF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%';



DECLARE @ProcRelease VARCHAR(100) = '2.0.2.7'
IF NOT EXISTS ( SELECT  Name
                FROM    Setup.[MFSQLObjectsControl]
                WHERE   [Schema] = 'setup'
                        AND Name = 'MFSQLObjectsControl' )
    BEGIN
        INSERT  INTO Setup.[MFSQLObjectsControl]
                ( [Schema] ,
                  [Name] ,
                  [object_id] ,
                  [Release] ,
                  [Type] ,
                  [Modify_Date]
                )
        VALUES  ( 'setup' , -- Schema - varchar(100)
                  'spMFSQLObjectsControl' , -- Name - varchar(100)
                  0 , -- object_id - int
                   @ProcRelease, -- Release - varchar(50)
                  'P' , -- Type - varchar(10)
                  GETDATE()  -- Modify_Date - datetime
                );
    END;
ELSE
    BEGIN
        UPDATE  moc
        SET      
                [moc].[Release] = @ProcRelease,
				moc.[Modify_Date] = GETDATE()
     
	    FROM    Setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Schema] = N'setup' and
                [moc].[Name] = N'MFSQLObjectsControl' ;
    END;




---------------   #tmp_GridResults_1   ---------------
SELECT * INTO #tmp_GridResults_1
FROM (
SELECT N'spMFCreateObjectInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFCreatePublicSharedLinkInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFDecrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFDeleteObjectInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFEncrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetClass' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetDataExportInternal' AS [name], N'1' AS [Module] UNION ALL
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

SELECT N'spMFUpdateWorkFlowState' AS [name], N'1' AS [Module] ) t;
--SELECT [name], [Module]
--FROM #tmp_GridResults_1

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.COLUMN_NAME = 'Module' AND c.TABLE_NAME = 'MFSQLObjectsControl')
Begin
ALTER TABLE setup.MFSQLObjectsControl
ADD Module INT DEFAULT((0))
END

UPDATE moc
SET module = tgr.Module
FROM setup.MFSQLObjectsControl AS moc
INNER JOIN #tmp_GridResults_1 AS tgr
ON tgr.name = moc.Name

DROP TABLE #tmp_GridResults_1
GO

