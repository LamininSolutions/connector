PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFUpdateMFilesToMFSQL]';

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUpdateMFilesToMFSQL', -- nvarchar(100)
                                 @Object_Release = '4.9.28.73',            -- varchar(50)
                                 @UpdateFlag = 2;

-- smallint
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateMFilesToMFSQL' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

IF OBJECT_ID('tempdb..#ObjIdList') IS NULL
    CREATE TABLE #ObjIdList
    (
        listid INT IDENTITY,
        ObjId INT,
        Flag INT
    );
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateMFilesToMFSQL
AS
BEGIN
    SELECT 'created, but not implemented yet.'; --just anything will do
END;
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateMFilesToMFSQL
(
    @MFTableName NVARCHAR(128),
    @MFLastUpdateDate SMALLDATETIME = NULL OUTPUT,
    @UpdateTypeID TINYINT = 1,
    @MaxObjects INT = 100000,
    @WithObjectHistory BIT = 0,
    @RetainDeletions BIT = 0,
    @WithStats BIT = 0,
    @Update_IDOut INT = NULL OUTPUT,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @debug TINYINT = 0
)
AS
/*rST**************************************************************************

=======================
spMFUpdateMFilesToMFSQL
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFLastUpdateDate smalldatetime (output)
    returns the most recent MF Last modified date
  @UpdateTypeID tinyint (optional)
    - 1 = incremental update (default)
    - 0 = Full update
  @MaxObjects INT
    - Default = 100000
    - if UpdateTypeID = 0 then this parameter must be set if there are more than 100000 objects in the objecttype 
  @WithObjectHistory BIT
    - Default = 0 (No)
    - set to 1 to include updating the object history
  @RetainDeletions BIT
    - Default = 0 (deletions will be removed from class table)
    - set to 1 to retain any deletions since the last update
  @WithStats BIT
    - default = 0
    - Set to 1 to show progress of processing
  @Update\_IDOut int (output)
    returns the id of the last updated batch
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug tinyint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

The purpose of this procedure has migrated over time from processing records by objid to a routine that can be used by default for large and small tables to process records from M-Files to SQL.
The procedure is fundamentally based on updating M-Files to SQL using a rapid evaluation of the object version of each object and then to update based on the object id of the object.

Additional Info
===============

Setting UpdateTypeID = 0 (Full update) will perform a full audit of the class table by validating every object version in the class and run through an update of all the objects where the version in M-Files and SQL are not identical.

This will run spmfUpdateTableinBatches in silent mode. Note that the Max Objid to control the update is derived as the max(objid) in the class table + 500 of the class table.
Setting UpdateTypeID = 1 (incremental update) will perform an audit of the class table based on the date of the last modified object in the class table, and then update the records that is not identical

Deleted records in M-Files will be identified and removed.

The following importing scenarios apply:

- If the file already exist for the object then the existing file in M-Files will be overwritten. M-Files version control will record the prior version of the record.
- If the object is new in the class table (does not yet have a objid and guid) then the object will first be created in M-Files and then the file will be added.
- If the object in M-Files is a multifile document with no files, then the object will be converted to a single file object.
- if the object in M-files already have a file or files, then it would convert to a multifile object and the additional file will be added
- If the filename or location of the file cannot be found, then a error will be added in the filerror column in the MFFileImport Table.
- If the parameter option @IsFileDelete is set to 1, then the originating file will be deleted.  The default is to not delete.
- The MFFileImport table keeps track of all the file importing activity.

Warnings
========

Use spmfUpdateTableInBatches to initiate a class table instead of this procedure.

When @updateTypeID is set to 0 and the maximum objid of the object type is more than 100 000 then the @MaxObjects parameter must be set

Examples
========

Full update of class table.  Set parameter @MaxObjects to the maximum oobject id in the object type when greater than 100000 to ensure that the audit process will run in batches.  

.. code:: sql

    DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

    EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable' 
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT 
                                    ,@UpdateTypeID = 0 
                                    ,@MaxObjects = 500000
                                    ,@Withstats = 1
                                    ,@Update_IDOut = @Update_IDOut OUTPUT 
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                    ,@debug = 0;  

    SELECT @MFLastUpdateDate AS [LastModifiedDate];


For incremental updates

.. code:: sql

    DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;


    EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable'
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT
                                    ,@UpdateTypeID = 1 
                                    ,@Update_IDOut = @Update_IDOut OUTPUT 
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT 
                                    ,@debug = 0;                   

    SELECT @MFLastUpdateDate;


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-01-25  LC         allow for batch processing of audit when max object > 100000
2022-01-25  LC         increase maxobjects default to 100000
2021-12-20  LC         Maintain same processbatch_ID for entire process
2021-12-20  LC         Revise removal of deleted objects from table
2021-12-16  LC         Remove deletion of audit table with full update
2021-08-28  LC         with full update, remove objects in class table not in audit table
2021-07-03  LC         improve debugging and error reporting
2021-05-11  LC         redesign the grouping of objects to overcome persistent issues
2021-05-10  LC         add controls to validate group list creation
2021-04-26  LC         add removal of redundant class records
2021-03-17  LC         include audit statusflag =1 into incremental update
2021-03-17  LC         resolve issue where objid for exist for class in two objecttypes
2021-03-16  LC         Remove object where class has changed from audit table
2021-03-11  LC         fix objlist error when both class and audit objid is null
2021-03-10  LC         fix updatechangehistory when control table empty
2021-01-07  LC         Include override to recheck any class objects not in Audit
2020-09-04  LC         Resolve bug with full update 
2020-08-23  LC         replace get max objid with index update
2020-08-23  LC         Add parameter to retain deletions, default set to NO.
2020-08-22  LC         Elliminate use of get deleted records
2020-04-23  LC         Set maxobjects
2020-03-06  LC         Add updating of object history
2020-02-14  LC         Resolve skipped audit items where class missing items
2019-12-10  LC         Add a parameter to set the maximum number of objects in class
2019-09-27  LC         Set withstats for audit batches = 0 
2019-09-27  LC         Fix UpdateID in MFProcessBatchDetail
2019-09-03  LC         Set audittableinbatches to withstats = 0
2019-09-03  LC         Set default date for deleted record check to 2000-01-01
2019-08-30  JC         Added documentation
2019-08-05  LC         Fix bug in updating single record
2019-04-12  LC         Allow for large tables
2018-10-22  LC         Align logtext description for reporting, refine ProcessBatch messages
2018-10-20  LC         Fix processing time calculation
2018-05-10  LC         Add error if invalid table name is specified
2017-12-28  LC         Add routine to reset process_id 3,4 to 0
2017-12-25  LC         Change BatchProcessDetail log text for lastupdatedate
2017-06-29  AC         Change LogStatusDetail to 'Completed' from 'Complete'
2017-06-08  AC         Incorrect LogTypeDetail value
2017-06-08  AC         ProcessBatch_ID not passed into spMFTableAudit
2016-08-11  AC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFUpdateMFilesToMFSQL';
    DECLARE @ProcedureStep AS NVARCHAR(128) = N'Set Variables';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';

    --used on MFProcessBatch;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType AS NVARCHAR(50) = N'Status';
    DECLARE @LogText AS NVARCHAR(4000) = N'';
    DECLARE @LogStatus AS NVARCHAR(50) = N'Started';

    --used on MFProcessBatchDetail;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = N'Debug';
    DECLARE @LogTextDetail AS NVARCHAR(4000) = @ProcedureStep;
    DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
    DECLARE @EndTime DATETIME;
    DECLARE @StartTime DATETIME;
    DECLARE @StartTime_Total DATETIME = GETUTCDATE();
    DECLARE @Validation_ID INT;
    DECLARE @LogColumnName NVARCHAR(128);
    DECLARE @LogColumnValue NVARCHAR(256);
    DECLARE @RunTime AS DECIMAL(18, 4) = 0;
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    DECLARE @error AS INT = 0;
    DECLARE @output NVARCHAR(200);
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    -------------------------------------------------------------
    -- Global Constants
    -------------------------------------------------------------
    DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
    DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
    DECLARE @UpdateType_0_FullRefresh TINYINT = 0;
    DECLARE @UpdateType_1_Incremental TINYINT = 1;
    DECLARE @UpdateType_2_Deletes TINYINT = 2;
    DECLARE @MFLastModifiedDate DATETIME;
    DECLARE @DeletedInSQL INT,
            @UpdateRequired BIT,
            @OutofSync INT,
            @ProcessErrors INT,
            @Class_ID INT,
            @DefaultToObjid INT;
    DECLARE @ListID INT,
            @Groupnumber INT,
            @Message NVARCHAR(1000),
            @FromObjid INT,
            @Toobjid INT,
            @ProcessingTime INT,
            @ObjIds_toUpdate NVARCHAR(MAX);
    DECLARE @Batchsize INT = 500;
    DECLARE @BatchCount INT = 1;
    DECLARE @nextBatchID INT;
    DECLARE @tempObjidTable NVARCHAR(100);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.MFClass WHERE TableName = @MFTableName)
        BEGIN
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Start procedure';

            IF @debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- set up temp table for objidtable
            -------------------------------------------------------------
            SELECT @tempObjidTable = dbo.fnMFVariableTableName('##ObjidTable', DEFAULT);

            -------------------------------------------------------------
            -- Get/Validate ProcessBatch_ID
            SET @ProcedureStep = N'Initialise M-Files to MFSQL';

            EXEC @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                             @ProcessType = 'UpdateMFilesToMFSQL',
                                                             @LogText = @ProcedureStep,
                                                             @LogStatus = 'Started',
                                                             @debug = @debug;

            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = N'Status';
            SET @LogTextDetail = CASE
                                     WHEN @UpdateTypeID = 0 THEN
                                         'UpdateType full refresh'
                                     ELSE
                                         'UpdateType incremental refresh'
                                 END;
            SET @LogStatusDetail = N'Started';
            SET @LogColumnName = N'';
            SET @LogColumnValue = N'';

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                   @LogType = @LogTypeDetail,
                                                   @LogText = @LogTextDetail,
                                                   @LogStatus = @LogStatusDetail,
                                                   @StartTime = @StartTime,
                                                   @MFTableName = @MFTableName,
                                                   @ColumnName = @LogColumnName,
                                                   @ColumnValue = @LogColumnValue,
                                                   @LogProcedureName = @ProcedureName,
                                                   @LogProcedureStep = @ProcedureStep,
                                                   @debug = @debug;

            -------------------------------------------------------------
            -- Get column for last modified, deleted
            -------------------------------------------------------------
            DECLARE @lastModifiedColumn NVARCHAR(100);

            SELECT @lastModifiedColumn = mp.ColumnName
            FROM dbo.MFProperty AS mp
            WHERE mp.MFID = 21;

            --'Last Modified'
            DECLARE @DeletedColumn NVARCHAR(100);

            SELECT @DeletedColumn = mp.ColumnName
            FROM dbo.MFProperty AS mp
            WHERE mp.MFID = 27;

            --'Class'
            DECLARE @ClassColumn NVARCHAR(100);

            SELECT @ClassColumn = mp.ColumnName
            FROM dbo.MFProperty AS mp
            WHERE mp.MFID = 100;

            -------------------------------------------------------------
            -- Get last modified date
            -------------------------------------------------------------
            SET @ProcedureStep = N'Get last updated  ';
            SET @sqlParam = N'@MFLastModifiedDate Datetime output';
            SET @sql
                = N'
SELECT @MFLastModifiedDate = (SELECT Coalesce(MAX(' + QUOTENAME(@lastModifiedColumn) + N'),''1950-01-01'') FROM '
                  + QUOTENAME(@MFTableName) + N' );';

            EXEC sys.sp_executesql @Stmt = @sql,
                                   @Params = @sqlParam,
                                   @MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

            SET @DebugText = N'Filter Date: ' + CAST(@MFLastModifiedDate AS NVARCHAR(100));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            --		select @MFLastModifiedDate = dateadd(d,-1,@MFLastModifiedDate)

            -------------------------------------------------------------
            -- Determine the overall size of the object type index
            -------------------------------------------------------------
            /*
0 = identical : [ao].[LatestCheckedInVersion] = [t].[MFVersion] AND [ao].[deleted]= 'False' and DeletedColumn is null
1 = MF IS Later : [ao].[LatestCheckedInVersion] > [t].[MFVersion]  
2 = SQL is later : ao.[LatestCheckedInVersion] < ISNULL(t.[MFVersion],-1) 
3 = Checked out : ao.CheckedoutTo <> 0
4 =  Deleted SQL to be updated : WHEN isnull(ao.[Deleted],'True' and isnull(t.DeletedColumn,'False')
5 =  In SQL Not in audit table : N t.[MFVersion] is null and ao.[MFVersion] is not null   
6 = Not yet process in SQL : t.id IS NOT NULL AND t.objid IS NULL
*/
            DECLARE @NewObjectXml NVARCHAR(MAX);
            DECLARE @StatusFlag_0_Identical TINYINT = 0;
            DECLARE @StatusFlag_3_Checkedout TINYINT = 3;
            DECLARE @StatusFlag_1_MFilesIsNewer TINYINT = 1;
            DECLARE @StatusFlag_4_Deleted TINYINT = 4;
            DECLARE @StatusFlag_5_InMFSQLNotMF TINYINT = 5;
            DECLARE @StatusFlag_6_NotInMFSQL TINYINT = 6;

            -------------------------------------------------------------
            -- Get class id and objecttype id
            -------------------------------------------------------------
            DECLARE @ObjectType_ID INT;

            SELECT @Class_ID = mc.MFID,
                   @ObjectType_ID = mot.MFID
            FROM dbo.MFClass AS mc
                INNER JOIN dbo.MFObjectType AS mot
                    ON mc.MFObjectType_ID = mot.ID
            WHERE mc.TableName = @MFTableName;

            -------------------------------------------------------------
            -- Reset errors 3 and 4
            -------------------------------------------------------------
            SET @ProcedureStep = N'Reset process_ID errors 3 and 4 ';
            SET @sql = N'UPDATE [t]
                    SET process_ID = 0
                    FROM [dbo].' + QUOTENAME(@MFTableName) + N' AS t WHERE [t].[Process_ID] IN (3,4)';

            EXEC (@sql);

            SET @rowcount = @@RowCount;
            SET @DebugText = N'Count %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
            END;

            -------------------------------------------------------------
            -- FULL REFRESH (resets audit table)
            -------------------------------------------------------------
            BEGIN
                DECLARE @MFAuditHistorySessionID INT = NULL;

                IF @WithStats = 1
                BEGIN
                    --SELECT @rowcount = COUNT(*)
                    --FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate,',') AS fmpds
                    SELECT @rowcount = ISNULL(COUNT(mah.ID), 0)
                    FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID;

                    SET @Message = @ProcedureName + N' : Table audit started : Records in table %i';

                    RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;
                END;

                SET @sql
                    = N'
                   IF (SELECT OBJECT_ID(''tempdb..' + @tempObjidTable
                      + N''')) IS NOT NULL
                        DROP TABLE ' + @tempObjidTable + N' ;

                        CREATE TABLE ' + @tempObjidTable
                      + N' (tableid INT IDENTITY PRIMARY KEY, [objid] INT , Batchgroup int, [Type] int)

CREATE nonCLUSTERED INDEX idx_objidtable_objid ON ' + @tempObjidTable + N'(tableid,[objid],Batchgroup);';

                --IF @debug > 0
                --    PRINT @sql;

                EXEC sys.sp_executesql @sql;
/*
                -- reset maxobjids
                SELECT @MaxObjects = CASE
                                         WHEN MAX(mah.ObjID) < @MaxObjects THEN
                                             @MaxObjects
                                         ELSE
                                             @MaxObjects
                                     END
                FROM dbo.MFAuditHistory AS mah
                WHERE mah.ObjectType = @ObjectType_ID;

*/
                SET @StartTime = GETUTCDATE();

                -------------------------------------------------------------
                -- FULL REFRESH START
                -------------------------------------------------------------
                IF @UpdateTypeID = @UpdateType_0_FullRefresh
                BEGIN
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Start full refresh';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    BEGIN

                        IF @MaxObjects <= 100000
                        BEGIN
                            -------------------------------------------------------------
                            -- Get object version result based on date for full refresh
                            -- delete audithistory, recreate based on date filter = 1950-01-01
                            -------------------------------------------------------------	    
                            --truncate history
                            --DELETE FROM dbo.MFAuditHistory
                            --WHERE Class = @Class_ID
                            --      AND ObjectType = @ObjectType_ID;
                            EXEC @return_value = dbo.spMFTableAudit @MFTableName = @MFTableName,
                                                                    @MFModifiedDate = '2000-01-01',
                                                                    @ObjIDs = NULL,
                                                                    @SessionIDOut = @MFAuditHistorySessionID OUTPUT,
                                                                    @NewObjectXml = @NewObjectXml OUTPUT,
                                                                    @DeletedInSQL = @DeletedInSQL OUTPUT,
                                                                    @UpdateRequired = @UpdateRequired OUTPUT,
                                                                    @OutofSync = @OutofSync OUTPUT,
                                                                    @ProcessErrors = @ProcessErrors OUTPUT,
                                                                    @UpdateTypeID = 0,
                                                                    @ProcessBatch_ID = @ProcessBatch_ID,
                                                                    @Debug = @debug;

                            IF @debug > 0
                                SELECT @return_value AS AuditUpdate_returnvalue;

                        END; --end maxobj < 100000

                        IF @MaxObjects > 100000 -- requires batching of table audit process
                        BEGIN

                            DECLARE @ToGroup INT;
                            SELECT @BatchCount = 1;

                            SELECT @ToGroup = CASE
                                                  WHEN MIN(mah.ObjID) > 0 THEN
                                                      MIN(mah.ObjID)
                                                  ELSE
                                                      0
                                              END
                            FROM dbo.MFAuditHistory AS mah
                            WHERE mah.Class = @Class_ID;


                            WHILE @ToGroup IS NOT NULL OR @ToGroup < @MaxObjects
                            BEGIN

                                SET @StartTime = GETUTCDATE();

                                SET @DebugText = N' Group %i between %i and %i ';
                                SET @DebugText = @DefaultDebugText + @DebugText;
                                SET @ProcedureStep = N'batch audit ';

                                IF @debug > 0
                                BEGIN
                                    RAISERROR(
                                                 @DebugText,
                                                 10,
                                                 1,
                                                 @ProcedureName,
                                                 @ProcedureStep,
                                                 @BatchCount,
                                                 @ToGroup,
                                                 @MaxObjects
                                             );
                                END;


                                SELECT @ObjIds_toUpdate = STUFF(
                                                          (
                                                              SELECT TOP 50000
                                                                     ',' + CAST(l.objid AS VARCHAR(20))
                                                              FROM dbo.MFObjidList AS l
                                                              WHERE l.objid
                                                              BETWEEN @ToGroup AND @MaxObjects
                                                              ORDER BY l.objid
                                                              FOR XML PATH('')
                                                          ),
                                                          1,
                                                          1,
                                                          ''
                                                               );

                                SET @ProcedureStep = N'Get Object Versions in batches';
                                --            SET @StartTime = GETUTCDATE();
                                SET @LogTypeDetail = N'Status';
                                SET @LogTextDetail
                                    = N' Batch : ' + CAST(ISNULL(@BatchCount, 0) AS VARCHAR(30)) + N' objid : '
                                      + CAST(@ToGroup AS VARCHAR(30));
                                SET @LogStatusDetail = N'In progress';
                                SET @LogColumnName = N'';
                                SET @LogColumnValue = N'';

                                EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                       @LogType = @LogTypeDetail,
                                                                       @LogText = @LogTextDetail,
                                                                       @LogStatus = @LogStatusDetail,
                                                                       @StartTime = @StartTime,
                                                                       @MFTableName = @MFTableName,
                                                                       @ColumnName = @LogColumnName,
                                                                       @ColumnValue = @LogColumnValue,
                                                                       @LogProcedureName = @ProcedureName,
                                                                       @LogProcedureStep = @ProcedureStep,
                                                                       @debug = @debug;

                                IF @ObjIds_toUpdate IS NOT NULL
                                BEGIN

                                    EXEC @return_value = dbo.spMFTableAudit @MFTableName = @MFTableName,
                                                                            @MFModifiedDate = NULL,
                                                                            @ObjIDs = @ObjIds_toUpdate,
                                                                            @SessionIDOut = @MFAuditHistorySessionID OUTPUT,
                                                                            @NewObjectXml = @NewObjectXml OUTPUT,
                                                                            @DeletedInSQL = @DeletedInSQL OUTPUT,
                                                                            @UpdateRequired = @UpdateRequired OUTPUT,
                                                                            @OutofSync = @OutofSync OUTPUT,
                                                                            @ProcessErrors = @ProcessErrors OUTPUT,
                                                                            @UpdateTypeID = 0,
                                                                            @ProcessBatch_ID = @ProcessBatch_ID,
                                                                            @Debug = 0;
                                    ; IF @debug > 0
                                          SELECT @rowcount = COUNT(fmpds.ID)
                                          FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate, ',') AS fmpds;

                                    SET @DebugText = N' %i ';
                                    SET @DebugText = @DefaultDebugText + @DebugText;
                                    SET @ProcedureStep = N'audit result ';

                                    IF @debug > 0
                                    BEGIN
                                        SELECT CAST(@NewObjectXml AS XML);
                                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                                    END;

                                END; --if objids to update not null 

                                IF @WithStats = 1
                                BEGIN
                                    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
                                    SET @Message
                                        = @ProcedureName + N' Process audit batch ' + CAST(@BatchCount AS NVARCHAR(10))
                                          + N' : Processing time (s): '
                                          + CAST((CONVERT(FLOAT, @ProcessingTime / 1000)) AS VARCHAR(10))
                                          + N' to objid %i';

                                    RAISERROR(@Message, 10, 1, @ToGroup) WITH NOWAIT;
                                END;



                                --   SELECT @ToGroup AS [before]
                                SELECT @BatchCount = @BatchCount + 1;
                                SELECT @ToGroup =
                                (
                                    SELECT MIN(l.objid) + 50000
                                    FROM dbo.MFObjidList AS l
                                    WHERE l.objid > @ToGroup
                                          AND l.objid < @MaxObjects + 1
                                );
                            --   SELECT @ToGroup AS [after]
                            END;



                        END; -- end of batching of table audit process
                        --get toobjid from audit history
                        SELECT @Toobjid = MAX(mottco.ObjID)
                        FROM dbo.MFAuditHistory AS mottco
                        WHERE mottco.ObjectType = @ObjectType_ID
                              AND mottco.Class = @Class_ID;
                    END;

                    SET @ProcedureStep = N'Get Object Versions with Batch Audit';
                    --            SET @StartTime = GETUTCDATE();
                    SET @LogTypeDetail = N'Status';
                    SET @LogTextDetail
                        = N' Batch Audit Max Object: ' + CAST(ISNULL(@DefaultToObjid, 0) AS VARCHAR(30));
                    SET @LogStatusDetail = N'In progress';
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @LogType = @LogTypeDetail,
                                                           @LogText = @LogTextDetail,
                                                           @LogStatus = @LogStatusDetail,
                                                           @StartTime = @StartTime,
                                                           @MFTableName = @MFTableName,
                                                           @ColumnName = @LogColumnName,
                                                           @ColumnValue = @LogColumnValue,
                                                           @LogProcedureName = @ProcedureName,
                                                           @LogProcedureStep = @ProcedureStep,
                                                           @debug = @debug;
                    -------------------------------------------------------------
                    -- class table update in batches
                    -------------------------------------------------------------
                    SET @DebugText = N'Max Objid %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Set Max objid';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Toobjid);
                    END;

                    SET @ProcedureStep = N'class table update in batches';
                    SET @LogTypeDetail = N'Debug';
                    SET @LogTextDetail = N' Start Update in batches: Max objid ' + CAST(@Toobjid AS NVARCHAR(256));
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @LogType = @LogTypeDetail,
                                                           @LogText = @LogTextDetail,
                                                           @LogStatus = @LogStatusDetail,
                                                           @StartTime = @StartTime,
                                                           @MFTableName = @MFTableName,
                                                           @ColumnName = @LogColumnName,
                                                           @ColumnValue = @LogColumnValue,
                                                           @LogProcedureName = @ProcedureName,
                                                           @LogProcedureStep = @ProcedureStep,
                                                           @debug = @debug;

                    SET @error = @@Error;
                    SET @LogStatusDetail = CASE
                                               WHEN
                                               (
                                                   @error <> 0
                                                   OR @return_value = -1
                                               ) THEN
                                                   'Failed'
                                               WHEN @return_value IN ( 1, 0 ) THEN
                                                   'Complete'
                                               ELSE
                                                   'Exception'
                                           END;
                    SET @LogTypeDetail = N'Debug';
                    SET @LogTextDetail = N' Audit Batch updates completed ';
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @LogType = @LogTypeDetail,
                                                           @LogText = @LogTextDetail,
                                                           @LogStatus = @LogStatusDetail,
                                                           @StartTime = @StartTime,
                                                           @MFTableName = @MFTableName,
                                                           @ColumnName = @LogColumnName,
                                                           @ColumnValue = @LogColumnValue,
                                                           @LogProcedureName = @ProcedureName,
                                                           @LogProcedureStep = @ProcedureStep,
                                                           @debug = @debug;

                    -------------------------------------------------------------
                    -- object history update full update
                    -------------------------------------------------------------         
                    SET @ProcedureStep = N'Update object change history';

                    IF
                    (
                        SELECT ISNULL(COUNT(mochuc.ID), 0)
                        FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
                        WHERE mochuc.MFTableName = @MFTableName
                    ) > 0
                    AND @WithObjectHistory = 1
                    BEGIN
                        EXEC dbo.spMFUpdateObjectChangeHistory @MFTableName = @MFTableName,         -- nvarchar(200)
                                                               @WithClassTableUpdate = 0,           -- int
                                                               @Objids = NULL,                      -- nvarchar(max)
                                                               @ProcessBatch_ID = @ProcessBatch_ID, -- int
                                                               @Debug = @debug;                     -- smallint
                    END;

                    -- remove all items in class table not in audit table for the class
                    IF @return_value IN ( 0, 1 )
                    BEGIN
                        SET @sql
                            = N';WITH cte AS
                (
                SELECT t.objid FROM ' + QUOTENAME(@MFTableName)
                              + N' t
                LEFT JOIN dbo.MFAuditHistory AS mah 
                ON t.objid = mah.objid AND t.' + QUOTENAME(@ClassColumn)
                              + N'= mah.class 
                where mah.objid is null
                )
                DELETE FROM ' + QUOTENAME(@MFTableName) + N' WHERE objid IN (SELECT cte.objid FROM cte);';

                        EXEC (@sql);

                    END; -- return value = success
                END; -- full update with no audit details



                -------------------------------------------------------------
                -- If incremental update
                -------------------------------------------------------------
                IF @UpdateTypeID = @UpdateType_1_Incremental
                BEGIN
                    --          SET @StartTime = GETUTCDATE();
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Start incremental refresh';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @SessionIDOut INT;

                    -------------------------------------------------------------
                    -- do audit update for all changed and deleted objects
                    -------------------------------------------------------------
                    -------------------------------------------------------------
                    -- do table update with most recent update date filter
                    -------------------------------------------------------------
                    IF @debug > 0
                        SELECT @MFLastModifiedDate AS last_modified_date;

                    SET @ProcedureStep = N'Get Filtered Object Versions';
                    --          SET @StartTime = GETUTCDATE();
                    SET @LogTypeDetail = N'Status';
                    SET @LogTextDetail
                        = N' Last modified: ' + CAST(CONVERT(DATETIME, @MFLastModifiedDate, 105) AS VARCHAR(30));
                    SET @LogStatusDetail = N'In progress';
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @LogType = @LogTypeDetail,
                                                           @LogText = @LogTextDetail,
                                                           @LogStatus = @LogStatusDetail,
                                                           @StartTime = @StartTime,
                                                           @MFTableName = @MFTableName,
                                                           @ColumnName = @LogColumnName,
                                                           @ColumnValue = @LogColumnValue,
                                                           @LogProcedureName = @ProcedureName,
                                                           @LogProcedureStep = @ProcedureStep,
                                                           @debug = @debug;

                    EXEC dbo.spMFTableAudit @MFTableName = @MFTableName,
                                            @MFModifiedDate = @MFLastModifiedDate,
                                            @ObjIDs = NULL,
                                            @SessionIDOut = @SessionIDOut,
                                            @NewObjectXml = @NewObjectXml OUTPUT,
                                            @DeletedInSQL = @DeletedInSQL OUTPUT,
                                            @UpdateRequired = @UpdateRequired OUTPUT,
                                            @OutofSync = @OutofSync OUTPUT,
                                            @ProcessErrors = @ProcessErrors OUTPUT,
                                            @UpdateTypeID = 1,
                                            @ProcessBatch_ID = @ProcessBatch_ID,
                                            @Debug = @debug;

                    SET @ProcedureStep = N'update checked out and deleted objects';

                    SELECT @ObjIds_toUpdate = STUFF(
                                              (
                                                  SELECT ',' + CAST(mah.ObjID AS VARCHAR(10))
                                                  FROM dbo.MFAuditHistory AS mah
                                                  WHERE mah.Class = @Class_ID
                                                        AND mah.ObjectType = @ObjectType_ID
                                                        AND mah.StatusFlag IN ( 3, 4, 5 )
                                                  FOR XML PATH('')
                                              ),
                                              1,
                                              1,
                                              ''
                                                   );

                    SELECT @rowcount = 0;
                    SELECT @rowcount = COUNT(mah.ID)
                    FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID
                          AND mah.ObjectType = @ObjectType_ID
                          AND mah.StatusFlag IN ( 3, 4, 5 );

                    SET @LogTypeDetail = N'Status ';
                    SET @LogTextDetail = N' Checked out and Deleted Objids: ' + CAST(@rowcount AS VARCHAR(30));
                    SET @LogStatusDetail = N'In progress';
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @LogType = @LogTypeDetail,
                                                           @LogText = @LogTextDetail,
                                                           @LogStatus = @LogStatusDetail,
                                                           @StartTime = @StartTime,
                                                           @MFTableName = @MFTableName,
                                                           @ColumnName = @LogColumnName,
                                                           @ColumnValue = @LogColumnValue,
                                                           @LogProcedureName = @ProcedureName,
                                                           @LogProcedureStep = @ProcedureStep,
                                                           @debug = @debug;

                    IF @rowcount > 0
                    BEGIN

                        EXEC dbo.spMFTableAudit @MFTableName = @MFTableName,
                                                @MFModifiedDate = NULL,
                                                @ObjIDs = @ObjIds_toUpdate,
                                                @SessionIDOut = @SessionIDOut,
                                                @NewObjectXml = @NewObjectXml OUTPUT,
                                                @DeletedInSQL = @DeletedInSQL OUTPUT,
                                                @UpdateRequired = @UpdateRequired OUTPUT,
                                                @OutofSync = @OutofSync OUTPUT,
                                                @ProcessErrors = @ProcessErrors OUTPUT,
                                                @UpdateTypeID = 1,
                                                @ProcessBatch_ID = @ProcessBatch_ID,
                                                @Debug = @debug;

                    END; -- rowcount > 0

                END; -- end partial refresh setup

                -------------------------------------------------------------
                -- Get list of objects to update
                -------------------------------------------------------------
                SELECT @rowcount = 0;

                SELECT @rowcount = CASE
                                       WHEN @RetainDeletions = 0 THEN
                (
                    SELECT COUNT(mah.ID)
                    FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID
                          AND @ObjectType_ID = mah.ObjectType
                          AND mah.StatusFlag IN ( 1, 3, 4, 5 )
                )
                                       WHEN @RetainDeletions = 1 THEN
                (
                    SELECT COUNT(mah.ID)
                    FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID
                          AND @ObjectType_ID = mah.ObjectType
                          AND mah.StatusFlag IN ( 1, 3, 4, 5 )
                )
                                   END;
                IF @rowcount > 0
                BEGIN
                    SET @sqlParam = N'@Class_ID int,@ObjectType_ID int ';

                    SET @sql
                        = CASE
                              WHEN ISNULL(@RetainDeletions, 0) = 0 THEN
                                  N'INSERT INTO ' + @tempObjidTable
                                  + N'
                        (
                            ObjId,Type
                        )
SELECT objid, mah.StatusFlag
FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID AND @ObjectType_ID = mah.ObjectType and StatusFlag IN ( 1,3,4,5 )
                    order by mah.objid;'
                              WHEN @RetainDeletions = 1 THEN
                                  N'INSERT INTO ' + @tempObjidTable
                                  + N'
                        (
                            ObjId,Type
                        )
SELECT objid, mah.StatusFlag
FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID AND @ObjectType_ID = mah.ObjectType and StatusFlag IN ( 1,3,4,5 )
                    order by mah.objid;'
                          END;

                    --IF @debug > 0
                    --    PRINT @sql;

                    EXEC sys.sp_executesql @sql, @sqlParam, @Class_ID, @ObjectType_ID;
                  set  @rowcount = @@ROWCOUNT 
 
 -------------------------------------------------------------
 -- remove rows from update list with no need to perform full update
 -- deletions (4) no longer in class table; not in class (5) no longer in class table
 -------------------------------------------------------------
 
 SET @sql = CASE WHEN @RetainDeletions = 1 then N'
 Update obj
 SET type = 0
 FROM ' + @tempObjidTable
                                  + N' obj
 INNER JOIN  dbo.MFAuditHistory AS mah
 ON obj.objid = mah.objid
 INNER JOIN '+quotename(@MFTableName)+' AS t
 ON mah.objid = t.objid
 WHERE mah.Class = @Class_ID AND mah.StatusFlag =4 AND t.'+quotename(@DeletedColumn)+' IS NOT null
 ;'
 WHEN @RetainDeletions = 0
 then N'
 Update obj
 SET type = 0
 FROM ' + @tempObjidTable
                                  + N' obj
 INNER JOIN  dbo.MFAuditHistory AS mah
 ON obj.objid = mah.objid
 left JOIN '+quotename(@MFTableName)+' AS t
 ON mah.objid = t.objid
 WHERE mah.Class = @Class_ID AND mah.StatusFlag =4 AND t.GUID IS null
 ;'
 END --end case

 EXEC sp_executeSQL @SQL,N'@Class_ID int',@Class_ID

 SET @rowcount = @@ROWCOUNT

  SET @DebugText = N'';
                    SET @DebugText = ' Count %i'
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Reset Deleted objects no need to re-process';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                    END;

SET @SQL = N'Delete from ' + @tempObjidTable
                                  + N' where type = 0'
EXEC sp_executeSQL @stmt = @SQL
                    -------------------------------------------------------------
                    -- get final rowcount for update
                    -------------------------------------------------------------
SET @SQL = N'SELECT @rowcount = COUNT(objid) FROM ' + @tempObjidTable
                                  + N' obj '

EXEC sp_executeSQL @stmt = @SQL, @Param = N'@rowcount int output', @Rowcount = @rowcount output

  SET @DebugText = N'';
                    SET @DebugText = ' Count %i'
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Final rowcount to re-process ';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                    END;

 -------------------------------------------------------------
                    -- set groups
-------------------------------------------------------------
  
  IF @rowcount <= @Batchsize
                    BEGIN
                        SET @sql = N'
UPDATE ' +              @tempObjidTable + N'
SET Batchgroup = 1
WHERE objid IS NOT NULL;';

                        EXEC sys.sp_executesql @sql;
                    END;

                    IF @rowcount > @Batchsize
                    BEGIN
                        SET @sqlParam = N'@nextBatchID int output, @Batchsize int';
                        SET @sql = N'
SELECT @nextBatchID = ot.Tableid FROM ' + @tempObjidTable + N' AS ot WHERE ot.Tableid = @Batchsize + 1;';

                        EXEC sys.sp_executesql @sql, @sqlParam, @nextBatchID OUTPUT, @Batchsize;

                        SET @sqlParam = N'@batchcount int, @nextBatchID int, @Batchsize int, @debug int';
                        SET @sql
                            = N'
WHILE exists (SELECT ot.Tableid FROM ' + @tempObjidTable
                              + N' AS ot WHERE ot.Batchgroup IS NULL)
Begin

if @debug > 0
SELECT @batchcount,  @nextBatchID;

UPDATE ot 
SET ot.Batchgroup = @BatchCount
FROM ' +                @tempObjidTable
                              + N' AS ot WHERE ot.Tableid BETWEEN @nextBatchID - @BatchSize AND @nextBatchID 

SET @nextBatchID = CASE WHEN exists (SELECT ot.Tableid FROM ' + @tempObjidTable
                              + N' AS ot WHERE ot.Batchgroup IS NULL)  THEN 
@nextBatchID + @Batchsize + 1 ELSE NULL END

SET @BatchCount = @BatchCount + 1
END --end loop for batch groups;';

                        EXEC sys.sp_executesql @sql,
                                               @sqlParam,
                                               @BatchCount,
                                               @nextBatchID,
                                               @Batchsize,
                                               @debug;
                    END; -- end if for batchsize

                    SET @ProcedureStep = N'AuditTable objids: ';
                    SET @sqlParam = N'@ToObjid int output';
                    SET @sql = N'
                SELECT @Toobjid = MAX(ot.ObjID)
                FROM ' + @tempObjidTable + N' AS ot
                ;'  ;

                    EXEC sys.sp_executesql @sql, @sqlParam, @Toobjid OUTPUT;

                    SET @Toobjid = ISNULL(@Toobjid, 0);
                    SET @DebugText = N' Max %i Count %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Toobjid, @rowcount);
                    END;

                    IF @WithStats = 1
                    BEGIN
                        SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
                        SET @Message
                            = @ProcedureName + N' Updates from audit : Processing time (s): '
                              + CAST((CONVERT(FLOAT, @ProcessingTime / 1000)) AS VARCHAR(10)) + N' Records %i';

                        RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;
                    END;

                    SET @LogColumnName = N' Items to update: ';
                    SET @LogColumnValue = CAST(@rowcount AS NVARCHAR(256));
                    SET @LogStatusDetail = N'In progress';
                    SET @LogTextDetail = N' update start';

                    EXEC @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                           @LogType = @LogTypeDetail,
                                                                           @LogText = @LogTextDetail,
                                                                           @LogStatus = @LogStatusDetail,
                                                                           @StartTime = @StartTime,
                                                                           @MFTableName = @MFTableName,
                                                                           @ColumnName = @LogColumnName,
                                                                           @ColumnValue = @LogColumnValue,
                                                                           @LogProcedureName = @ProcedureName,
                                                                           @LogProcedureStep = @ProcedureStep,
                                                                           @debug = @debug;

                    SET @ProcedureStep = N' Start update process ';
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);                    
                    END;

                    -------------------------------------------------------------
                    -- Update in batches
                    -------------------------------------------------------------
                    SET @sqlParam = N'@Groupnumber int output';
                    SET @sql
                        = N'
                    SELECT @Groupnumber = MIN(Batchgroup)
                    FROM ' + @tempObjidTable + N' AS ot;';

                    EXEC sys.sp_executesql @sql, @sqlParam, @Groupnumber OUTPUT;

                    WHILE @Groupnumber IS NOT NULL
                    BEGIN
                        SET @ProcedureStep = N' Loop ';
                        SET @DebugText = N' From %i to %i Group %i count %i';
                        SET @DebugText = @DefaultDebugText + @DebugText;



                        SET @StartTime = GETUTCDATE();
                        SET @sqlParam
                            = N'@ObjIds_toUpdate nvarchar(4000) output, @Groupnumber int, @rowcount int output, @FromObjid int output, @Toobjid int output ';
                        SET @sql
                            = N' SELECT @ObjIds_toUpdate = STUFF((SELECT '','',CAST(list.ObjID AS VARCHAR(10)) FROM '
                              + @tempObjidTable
                              + N' AS list WHERE Batchgroup = @Groupnumber FOR XML PATH('''')),1,1,'''');
    SELECT @rowcount = COUNT(objid),  @FromObjid = MIN(list.ObjID), @Toobjid = MAX(list.ObjID) FROM ' + @tempObjidTable
                              + N'  AS list WHERE batchgroup = @Groupnumber
   '                    ;

                        EXEC sys.sp_executesql @sql,
                                               @sqlParam,
                                               @ObjIds_toUpdate OUTPUT,
                                               @Groupnumber,
                                               @rowcount OUTPUT,
                                               @FromObjid OUTPUT,
                                               @Toobjid OUTPUT;

                        IF @debug > 0
                        BEGIN                        
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@FromObjid,@Toobjid,@ToGroup,@rowcount);
                        END;

                        IF @rowcount > 0
                        BEGIN
                            SET @ProcedureStep = N'spMFUpdateTable UpdateMethod 1';
                            SET @LogTextDetail = N' Group# ' + ISNULL(CAST(@Groupnumber AS VARCHAR(20)), '(null)');
                            SET @LogStatusDetail = N'Started';
                            SET @LogColumnName = N'Count: ';
                            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));

                            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                   @LogType = @LogTypeDetail,
                                                                   @LogText = @LogTextDetail,
                                                                   @LogStatus = @LogStatusDetail,
                                                                   @StartTime = @StartTime,
                                                                   @MFTableName = @MFTableName,
                                                                   @ColumnName = @LogColumnName,
                                                                   @ColumnValue = @LogColumnValue,
                                                                   @LogProcedureName = @ProcedureName,
                                                                   @LogProcedureStep = @ProcedureStep,
                                                                   @debug = @debug;

                            IF @debug > 0
                            BEGIN
                                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            --          SELECT 'pre-updatetable', * FROM dbo.MFvwAuditSummary AS mfas
                            END;

                            IF @WithStats = 1
                            BEGIN
                                SET @Message
                                    = N'Batch update from ' + CAST(ISNULL(@FromObjid, 0) AS VARCHAR(10)) + N' to  '
                                      + CAST(ISNULL(@Toobjid, 0) AS VARCHAR(30));

                                RAISERROR(@Message, 10, 1) WITH NOWAIT;
                            END; --if with stats

                            IF @ObjIds_toUpdate IS NOT NULL
                            BEGIN

                                EXEC @return_value = dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                                                         @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL,
                                                                         @ObjIDs = @ObjIds_toUpdate,
                                                                         @Update_IDOut = @Update_IDOut OUTPUT,
                                                                         @ProcessBatch_ID = @ProcessBatch_ID,
                                                                         @RetainDeletions = @RetainDeletions,
                                                                         @Debug = @debug;

                                --  IF @debug > 0
                                --  BEGIN
                                ----      RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                                --      SELECT 'post-updatetable', * FROM dbo.MFvwAuditSummary AS mfas
                                --  END;

                                SET @sqlParam = N'@rowcount int output, @Update_IDOut int';
                                SET @sql
                                    = N' SELECT @rowcount = COUNT(Update_ID) FROM ' + @MFTableName
                                      + N' WHERE update_ID = @Update_IDOut;';

                                EXEC sys.sp_executesql @sql, @sqlParam, @rowcount OUTPUT, @Update_IDOut;

                                SET @error = @@Error;
                                SET @LogStatusDetail = CASE
                                                           WHEN
                                                           (
                                                               ISNULL(@error, 0) <> 0
                                                               OR @return_value = -1
                                                           ) THEN
                                                               'Failed'
                                                           WHEN @return_value IN ( 1, 0 ) THEN
                                                               'Completed'
                                                           ELSE
                                                               'Exception'
                                                       END;
                                SET @LogText = N'Return Value: ' + CAST(@return_value AS NVARCHAR(256));
                                SET @LogColumnName = N'Batch updated ';
                                SET @LogColumnValue = CAST(ISNULL(@rowcount, 0) AS NVARCHAR(256));

                                EXEC @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                                       @LogType = @LogTypeDetail,
                                                                                       @LogText = @LogTextDetail,
                                                                                       @LogStatus = @LogStatusDetail,
                                                                                       @StartTime = @StartTime,
                                                                                       @MFTableName = @MFTableName,
                                                                                       @ColumnName = @LogColumnName,
                                                                                       @ColumnValue = @LogColumnValue,
                                                                                       @Update_ID = @Update_IDOut,
                                                                                       @LogProcedureName = @ProcedureName,
                                                                                       @LogProcedureStep = @ProcedureStep,
                                                                                       @debug = @debug;
                            END;
                        END; -- objids to update is not null

                        -- rowcount to update is not null
                        -------------------------------------------------------------
                        -- update history for group
                        -------------------------------------------------------------
                        IF
                        (
                            SELECT ISNULL(COUNT(mochuc.ID), 0)
                            FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
                            WHERE mochuc.MFTableName = @MFTableName
                        ) > 0
                        AND @WithObjectHistory = 1
                        BEGIN
                            SET @sqlParam = N'@Class_ID int, @ObjIds_toUpdate nvarchar(max) output, @GroupNumber int';
                            SET @sql
                                = N';
   WITH cte AS
   (
   SELECT objid, MAX(mfversion) AS MFVersion FROM dbo.MFObjectChangeHistory AS moch 
   WHERE class_id = @Class_id
   GROUP BY objid)
   SELECT distinct @ObjIds_toUpdate = STUFF((SELECT '','' + CAST(t2.objid AS VARCHAR(10)) 
   from ' +                 QUOTENAME(@MFTableName) + N' AS t2
   INNER JOIN ' +           @tempObjidTable
                                  + N' AS fmss
   ON t2.objid = fmss.objid
   LEFT JOIN cte 
ON t2.objid = cte.objid
 WHERE t2.MFVersion > ISNULL(cte.MFVersion,0) and fmss.BatchGroup = @GroupNumber
 FOR XML PATH('''')),1,1,'''')
   ;'                       ;

                            EXEC sys.sp_executesql @sql,
                                                   @sqlParam,
                                                   @Class_ID,
                                                   @ObjIds_toUpdate OUTPUT,
                                                   @Groupnumber;

                            SET @DebugText = @ObjIds_toUpdate;
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'Get History for selected objids: ';

                            IF @debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                            END;
                        END; -- get history

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = N'Next group in loop';

                        IF @debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        IF @WithStats = 1
                        BEGIN
                            SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
                            SET @Message
                                = @ProcedureName + N' : Processing time (s): '
                                  + CAST((CONVERT(FLOAT, @ProcessingTime / 1000)) AS VARCHAR(10)) + N' Records %i';

                            RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;
                        END;

                        SET @sqlParam = N'@Groupnumber int output';
                        SET @sql
                            = N'
                            SELECT @Groupnumber = (SELECT MIN(Batchgroup) FROM ' + @tempObjidTable
                              + N' AS ot WHERE Batchgroup >@Groupnumber);';

                        EXEC sys.sp_executesql @sql, @sqlParam, @Groupnumber OUTPUT;

                        SET @DebugText = N' ' + CAST(ISNULL(@Groupnumber, 0) AS VARCHAR(10));
                        SET @DebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = N'Next group # ';

                        IF @debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;
                    END; --WHILE @Groupnumber is not null

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'End batch loop';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        SELECT 'AuditHistory',
                               *
                        FROM dbo.MFvwAuditSummary AS mfas;
                    END;
                END; --if rowcount > 0
                ELSE
                BEGIN
                    SET @LogTypeDetail = N'Status';
                    SET @LogStatusDetail = N'In progress';
                    SET @LogTextDetail = N'Nothing to update';
                    SET @LogColumnName = N'';
                    SET @LogColumnValue = N'';

                    EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                              @LogType = @LogTypeDetail,
                                                                              @LogText = @LogTextDetail,
                                                                              @LogStatus = @LogStatusDetail,
                                                                              @StartTime = @StartTime,
                                                                              @MFTableName = @MFTableName,
                                                                              @Validation_ID = @Validation_ID,
                                                                              @ColumnName = @LogColumnName,
                                                                              @ColumnValue = @LogColumnValue,
                                                                              @Update_ID = @Update_IDOut,
                                                                              @LogProcedureName = @ProcedureName,
                                                                              @LogProcedureStep = @ProcedureStep,
                                                                              @debug = @debug;
                END;

                -- end objects to up update rowcount > 0

                -------------------------------------------------------------
                -- Catch all - get history for items not included in batch update
                -------------------------------------------------------------
                IF
                (
                    SELECT ISNULL(COUNT(mochuc.ID), 0)
                    FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
                    WHERE mochuc.MFTableName = @MFTableName
                ) > 0
                AND @WithObjectHistory = 1
                BEGIN
                    SET @sqlParam = N'@Class_ID int, @ObjIds_toUpdate nvarchar(max) output';
                    SET @sql
                        = N';
   WITH cte AS
   (
   SELECT objid, MAX(mfversion) AS MFVersion FROM dbo.MFObjectChangeHistory AS moch 
   WHERE class_id = @Class_id
   GROUP BY objid)
   SELECT distinct @ObjIds_toUpdate = STUFF((SELECT '','' + CAST(t2.objid AS VARCHAR(10)) 
   from ' +         QUOTENAME(@MFTableName)
                          + N' AS t2
   LEFT JOIN cte 
ON t2.objid = cte.objid
 WHERE t2.MFVersion > ISNULL(cte.MFVersion,0)
 FOR XML PATH('''')),1,1,'''')
 '                  ;

                    EXEC sys.sp_executesql @sql,
                                           @sqlParam,
                                           @Class_ID,
                                           @ObjIds_toUpdate OUTPUT;

                    SET @DebugText = @ObjIds_toUpdate;
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Get History for remaining objids: ';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    EXEC dbo.spMFUpdateObjectChangeHistory @MFTableName = @MFTableName,
                                                           @WithClassTableUpdate = 0,
                                                           @Objids = @ObjIds_toUpdate,
                                                           @ProcessBatch_ID = @ProcessBatch_ID,
                                                           @Debug = @debug;
                END;

                -- end update object changes

                -------------------------------------------------------------
                -- remove objects from Class table, not in table audit
                -------------------------------------------------------------
                /*
                BEGIN -- remove objects
                    SET @ProcedureStep = N'Remove redundant objects';

                    DECLARE @objids NVARCHAR(4000);

                    SET @sqlParam = N'@Class_ID int, @objids NVARCHAR(4000) output ';
                    SET @sql
                        = N'
;
WITH cte AS
(
    SELECT Objid FROM ' + QUOTENAME(@MFTableName)
                          + N' AS mc
    EXCEPT
    SELECT Objid FROM dbo.MFAuditHistory AS mah WHERE Class = @Class_ID 
)
SELECT @objids = STUFF((SELECT '','' + CAST(objid AS NVARCHAR(10)) 
FROM cte 
ORDER BY objid
FOR XML PATH('''')),1,1,'''') ';

                    EXEC sys.sp_executesql @sql, @sqlParam, @Class_ID, @objids OUTPUT;

                    SELECT @rowcount = ISNULL(COUNT(fmpds.ID), 0)
                    FROM dbo.fnMFParseDelimitedString(@objids, ',') AS fmpds;

                    IF @rowcount > 0
                        EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                                 @UpdateMethod = 1,
                                                 @ObjIDs = @objids,
                                                 @RetainDeletions = @RetainDeletions,
                                                 @ProcessBatch_ID = @ProcessBatch_ID,
                                                 @Debug = @debug;

                    SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(100));
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

                -------------------------------------------------------------
                -- Update deleted documents from audit history
                -------------------------------------------------------------
                BEGIN -- remove objects
                    SET @ProcedureStep = N'update deleted objects';
                    SET @sqlParam = N'@Class_ID int, @objids NVARCHAR(4000) output ';
                    SET @sql
                        = N'
;
WITH cte AS
(
    SELECT mc.Objid FROM ' + QUOTENAME(@MFTableName)
                          + N' AS mc
    inner join dbo.MFAuditHistory AS mah 
    on mc.objid = mah.objid
    WHERE mah.Class = @Class_ID and mah.statusflag = 4
)
SELECT @objids = STUFF((SELECT '','' + CAST(cte.objid AS NVARCHAR(10)) 
FROM cte 
ORDER BY objid
FOR XML PATH('''')),1,1,'''') ';

                    EXEC sys.sp_executesql @sql, @sqlParam, @Class_ID, @objids OUTPUT;

                    SELECT @rowcount = ISNULL(COUNT(fmpds.ID), 0)
                    FROM dbo.fnMFParseDelimitedString(@objids, ',') AS fmpds;

                    IF @rowcount > 0
                        EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                                 @UpdateMethod = 1,
                                                 @ObjIDs = @objids,
                                                 @RetainDeletions = @RetainDeletions,
                                                 @ProcessBatch_ID = @ProcessBatch_ID,
                                                 @Debug = @debug;

                    SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(100));
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;
*/
                -------------------------------------------------------------
                -- Get last update date
                -------------------------------------------------------------
                SET @ProcedureStep = N'Get update date for output';
                SET @sqlParam = N'@MFLastModifiedDate Datetime output';
                SET @sql
                    = N'
SELECT @MFLastModifiedDate = (SELECT MAX(' + QUOTENAME(@lastModifiedColumn) + N') FROM ' + QUOTENAME(@MFTableName)
                      + N' );';

                EXEC sys.sp_executesql @Stmt = @sql,
                                       @Params = @sqlParam,
                                       @MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

                SET @MFLastUpdateDate = @MFLastModifiedDate;

                -------------------------------------------------------------
                -- end logging
                -------------------------------------------------------------s
                SET @error = @@Error;
                SET @ProcessType = N'Update Tables';
                SET @LogType = N'Debug';
                SET @LogStatusDetail = CASE
                                           WHEN (@error <> 0) THEN
                                               'Failed'
                                           ELSE
                                               'Completed'
                                       END;
                SET @ProcedureStep = N'finalisation';
                SET @LogTypeDetail = N'Debug';
                SET @LogTextDetail = N'MF Last Modified: ' + CONVERT(VARCHAR(20), @MFLastUpdateDate, 120);
                --		SET @LogStatusDetail = 'Completed'
                SET @LogColumnName = @MFTableName;
                SET @LogColumnValue = N'';
                SET @LogText = N'Update : ' + @MFTableName + N':Update Type ' + CASE
                                                                                    WHEN @UpdateTypeID = 1 THEN
                                                                                        'Incremental'
                                                                                    ELSE
                                                                                        'Full'
                                                                                END;
                SET @LogStatus = N'Completed';
                SET @LogStatusDetail = N'Completed';

                EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                  -- int
                                                 @ProcessType = @ProcessType,
                                                 @LogText = @LogText,
                                                 @LogType = @LogType,
                                                                  -- nvarchar(4000)
                                                 @LogStatus = @LogStatus,
                                                                  -- nvarchar(50)
                                                 @debug = @debug; -- tinyint

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                          @LogType = @LogTypeDetail,
                                                                          @LogText = @LogTextDetail,
                                                                          @LogStatus = @LogStatusDetail,
                                                                          @StartTime = @StartTime,
                                                                          @MFTableName = @MFTableName,
                                                                          @Validation_ID = @Validation_ID,
                                                                          @ColumnName = @LogColumnName,
                                                                          @ColumnValue = @LogColumnValue,
                                                                          @Update_ID = @Update_IDOut,
                                                                          @LogProcedureName = @ProcedureName,
                                                                          @LogProcedureStep = @ProcedureStep,
                                                                          --        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
                                                                          @debug = @debug;
            END; --REFRESH M-FILES --> MFSQL

            SET NOCOUNT OFF;

            RETURN 1;
        END;
        ELSE
        BEGIN
            SET @ProcedureStep = N'Validate Class Table';

            RAISERROR('Invalid Table Name', 16, 1);
        END;
    END TRY
    BEGIN CATCH
        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        INSERT INTO dbo.MFLog
        (
            SPName,
            ProcedureStep,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ErrorState,
            ErrorSeverity,
            ErrorLine
        )
        VALUES
        (@ProcedureName, @ProcedureStep, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(),
         ERROR_SEVERITY(), ERROR_LINE());

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_MESSAGE() AS ErrorMessage,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_STATE() AS ErrorState,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_LINE() AS ErrorLine,
               @ProcedureName AS ProcedureName,
               @ProcedureStep AS ProcedureStep;

        RETURN -1;
    END CATCH;
END;
GO