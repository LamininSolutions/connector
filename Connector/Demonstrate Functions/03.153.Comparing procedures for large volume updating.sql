
/*
these examples include the scripts that is most usefull for processing large volume updates

these examples include all the parameters.  Most of the parameters have default settings and does not have to be included in the script to run the procedure

Note that each self standing script start and ends with GO. DO NOT RUN THIS ENTIRE SCRIPT, select the script most appropriate from GO to GO


*/
--Created on: 2019-07-08 

--SPMFUPDATETABLE : generally speaking this update routine should be used for smallish datasets.  This procedure is used in all the other routines but
--the special procedure is designed to apply the filters in different ways

--

-- from MF to SQL no filters
DECLARE @Update_IDOut    INT
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFUpdateTable] @MFTableName = 'YourTable'                 -- nvarchar(200)
                            ,@UpdateMethod = 1                          -- int
                            ,@UserId = NULL                             -- nvarchar(200)
                            ,@MFModifiedDate = NULL                     -- datetime
                            ,@ObjIDs = NULL                             -- nvarchar(max)
                            ,@Update_IDOut = @Update_IDOut OUTPUT       -- int
                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                            ,@RetainDeletions = 0                       -- bit
                            ,@Debug = 0;

                                                                        -- smallint

--logging
SELECT @Update_IDOut AS [Update_ID];

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
GO

--the same script with minimum parameters (Shorthand)

EXEC [dbo].[spMFUpdateTable] 'YourTable', 1;
GO

-- From SQL to MF with no filters

DECLARE @Update_IDOut    INT
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFUpdateTable] @MFTableName = 'YourTable'                 -- nvarchar(200)
                            ,@UpdateMethod = 0                          -- int
                            ,@UserId = NULL                             -- nvarchar(200)
                            ,@MFModifiedDate = NULL                     -- datetime
                            ,@ObjIDs = NULL                             -- nvarchar(max)
                            ,@Update_IDOut = @Update_IDOut OUTPUT       -- int
                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                            ,@RetainDeletions = 0                       -- bit
                            ,@Debug = 0;                                -- smallint

SELECT @Update_IDOut AS [Update_ID];

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
GO

--SPMFUPDATETABLEWITHLASTMODIFIEDDATE 
/*
this procedure is very powerful when only last changes from MF to SQL should be returned. Note that it does not process deletions in MF. If records are allowed to be deleted by users in MF then resort to the procs below
*/

DECLARE @Return_LastModified DATETIME
       ,@Update_IDOut        INT
       ,@ProcessBatch_ID     INT;

EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1                                  -- int
                                                ,@Return_LastModified = @Return_LastModified OUTPUT -- datetime
                                                ,@TableName = 'YourTable'                           -- sysname
                                                ,@Update_IDOut = @Update_IDOut OUTPUT               -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT         -- int
                                                ,@debug = 0;                                        -- smallint

SELECT @Return_LastModified AS [LastModified];

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
GO

--SPMFUPDATEMFILESTOSQL
/*
 this is the go to procedure for updating from MF to SQL for large tables
 Do NOT use for first data takeon of the class table.  This procedure is only operational if the class table has been initialised with the first data pull

*/

--Full Update from MF to SQL
/*
Full update of table.  This will run spmfUpdateTableinBatches in silent mode. Note that the Max Objid to control the update is derived as the max(objid) + 500 of the class table.

Due the anomoly in M-Files that undeleted records do not change last modified date in M-Files, we recommend to run this routine overnight with an agent where users routinely undelete objects.  else it can be manually run when administrators perform a undelete.

*/

DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable'                   -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
                                    ,@UpdateTypeID = 0                            -- tinyint
                                    ,@Update_IDOut = @Update_IDOut OUTPUT         -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT   -- int
                                    ,@debug = 0;                                  -- tinyint

SELECT @MFLastUpdateDate AS [LastModifiedDate];

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
GO

/*
Incremental - only changed objects will be updated. This routine make use of spMFTableAudit to determine the changes and will only update the changes. 
It will identify deletions in M-Files.  

*/
DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable'                   -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
                                    ,@UpdateTypeID = 1                            -- tinyint
                                    ,@Update_IDOut = @Update_IDOut OUTPUT         -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT   -- int
                                    ,@debug = 0;                                  -- tinyint

SELECT @MFLastUpdateDate;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

--SPMFUPDATEALLINCLUDEDINAPPTABLES

/*
This handly proc will process all the class tables marked as includedinapp in MFCLASS with spMFUpdateMFilestoSQL and @UpdateTableID = 1 (incremental)

*/
GO

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFUpdateAllncludedInAppTables] @UpdateMethod = 1                          -- int
                                            ,@RemoveDeleted = 1                         -- int
                                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                            ,@Debug = 0;                                -- smallint
GO

--SPUPDATETABLEINBATCHES

/*
It is the goto procedure to use for initialising large class tables
It is also to goto procedure to use for updating SQL to MF for large datasets.
This proc is used in other procedures

Note that the @ToObjid must be determined by you for each class.  Best way to do it is to check a recently added object in MFiles to determine the ID of the object.
Then set the @Toobjid to be x + 1000


*/

--update SQL to MF

EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'YourTable' -- nvarchar(100)
                                     ,@UpdateMethod = 0          -- int
                                     ,@WithTableAudit = 0        -- int
                                     ,@FromObjid = 1             -- bigint
                                     ,@ToObjid = 12000           -- bigint
                                     ,@WithStats = 1             -- bit
                                     ,@Debug = 0;                -- int
GO

--Update MF to SQL : class table initialisation (note the setting with @WithtableAudit)

EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'MFLarge_Volume' -- nvarchar(100)
                                     ,@UpdateMethod = 1          -- int
                                     ,@WithTableAudit = 1        -- int
                                     ,@FromObjid = 1             -- bigint
                                     ,@ToObjid = 1000          -- bigint
                                     ,@WithStats = 1             -- bit
                                     ,@Debug = 0;                -- int
GO

--SUPPORTINT PROCEDURES.  ALL THE FOLLOWING PROCEDURES ARE APPLIED IN THE ABOVE ROUTINES, HOWEVER IT CAN BE USED ON ITS ONW IN SPECIFIC USE CASES

--SPMFTABLEAUDIT

/*
Procedure extracts the object versions from MF
*/

GO

DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFBasic_SingleProp'                 -- nvarchar(128)
                           ,@MFModifiedDate = NULL                     -- datetime
                           ,@ObjIDs = null                -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT       -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT       -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT   -- bit
                           ,@OutofSync = @OutofSync OUTPUT             -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                           ,@Debug = 1;                                -- smallint

SELECT *
FROM [dbo].[MFAuditHistory] AS [mah]
WHERE [mah].[SessionID] = @SessionIDOut;

SELECT CAST(@NewObjectXml AS XML);

SELECT @DeletedInSQL   AS [DeletedInSQL]
      ,@UpdateRequired AS [UpdateRequired]
      ,@OutofSync      AS [OutofSync]
      ,@ProcessErrors  AS [ProcessErrors];

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
GO

--SPMFTABLEAUDITINBATCHES

/*
this routine calls MFTableAudit in batches.
In very large class tables it is advisable to the batch processing of object versions 
*/

EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'YourTable' -- nvarchar(100)
                                    ,@FromObjid = 1             -- int
                                    ,@ToObjid = 555000          -- int
                                    ,@WithStats = 1             -- bit
                                    ,@Debug = 0;                -- int
GO

--SPMFGETOBJVERS

/*
this routine is used in other procedures. 
It is similar to spMFTableAudit, but without the complexity and updating of the MFAuditHistory table. It simply returns the object version.  The example below includes parcing the XML record
 It is handly to perform a quick extract of object versions.  
*/

DECLARE @outPutXML       NVARCHAR(MAX)
       ,@ProcessBatch_ID INT;
DECLARE @lastmodified DATETIME;
DECLARE @Idoc INT;

--change the below to include your table name
SELECT @lastmodified = MAX([mbs].[MF_Last_Modified])
FROM [dbo].MFCustomer AS [mbs];

EXEC [dbo].[spMFGetObjectvers] @TableName = 'MFCustomer'                   -- nvarchar(100)
                              ,@dtModifiedDate = @lastmodified            -- datetime
                              ,@MFIDs = null                         -- nvarchar(4000)
                              ,@outPutXML = @outPutXML OUTPUT             -- nvarchar(max)
                              ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                              ,@Debug = 101;                              -- smallint

							  DECLARE @outPutXML1 NVARCHAR(MAX);
							  
						

EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;

WITH [cte]
AS (SELECT [xmlfile].[objId]
          ,[xmlfile].[MFVersion]
          ,[xmlfile].[GUID]
          ,[xmlfile].[ObjectType_ID]
    FROM
        OPENXML(@Idoc, '/form/objVers', 1)
        WITH
        (
            [objId] INT './@objectID'
           ,[MFVersion] INT './@version'
           ,[GUID] NVARCHAR(100) './@objectGUID'
           ,[ObjectType_ID] INT './@objectType'
        ) [xmlfile])
SELECT *
FROM [cte];

EXEC [sys].[sp_xml_removedocument] @Idoc;
GO