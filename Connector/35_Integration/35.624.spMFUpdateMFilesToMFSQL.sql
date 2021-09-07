PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFUpdateMFilesToMFSQL]';

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateMFilesToMFSQL', -- nvarchar(100)
    @Object_Release = '4.9.27.71',            -- varchar(50)
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
    @MaxObjects INT = 20000,
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
    - Default = 20000
    - This parameter has no longer any impact, 
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

Examples
========

.. code:: sql

    --Full Update from MF to SQL

    DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

    EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable' 
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT 
                                    ,@UpdateTypeID = 0 
                                    ,@Update_IDOut = @Update_IDOut OUTPUT 
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                    ,@debug = 0;  

    SELECT @MFLastUpdateDate AS [LastModifiedDate];

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
        @UpdateRequired   BIT,
        @OutofSync        INT,
        @ProcessErrors    INT,
        @Class_ID         INT,
        @DefaultToObjid   INT;
    DECLARE @Objid      INT,
        @ListID         INT,
        @LastListID     INT,
        @Groupnumber    INT,
        @Message        NVARCHAR(1000),
        @FromObjid      INT,
        @Toobjid        INT,
        @ProcessingTime INT;
    DECLARE @CurrentGroup INT,
        @ObjIds_toUpdate  NVARCHAR(4000);

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

            SELECT @Class_ID   = mc.MFID,
                @ObjectType_ID = mot.MFID
            FROM dbo.MFClass                AS mc
                INNER JOIN dbo.MFObjectType AS mot
                    ON mc.MFObjectType_ID = mot.ID
            WHERE mc.TableName = @MFTableName;

            -------------------------------------------------------------
            -- Reset errors 3 and 4
            -------------------------------------------------------------
            SET @ProcedureStep = N'Reset errors 3 and 4 ';
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
                        SELECT @rowcount = COUNT(*)
                        FROM dbo.MFAuditHistory AS mah
                        WHERE mah.Class = @Class_ID;

                        SET @Message = @ProcedureName + N' : Table audit started : Records %i';

                        RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;

                    END;
                         SET @StartTime = GETUTCDATE();
                IF @UpdateTypeID = @UpdateType_0_FullRefresh
                BEGIN
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Start full refresh';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @Tobjid INT;

                    BEGIN

                        -------------------------------------------------------------
                        -- Get object version result based on date for full refresh
                        -- delete audithistory, recreate based on date filter = 1950-01-01
                        -------------------------------------------------------------	    
                        --truncate history
                        DELETE FROM dbo.MFAuditHistory
                        WHERE Class = @Class_ID
                              AND ObjectType = @ObjectType_ID;

                        EXEC @return_value = dbo.spMFTableAudit @MFTableName = @MFTableName,
                            @MFModifiedDate = '1950-01-01',
                            @ObjIDs = NULL,
                            @SessionIDOut = @MFAuditHistorySessionID OUTPUT,
                            @NewObjectXml = @NewObjectXml OUTPUT,
                            @DeletedInSQL = @DeletedInSQL OUTPUT,
                            @UpdateRequired = @UpdateRequired OUTPUT,
                            @OutofSync = @OutofSync OUTPUT,
                            @ProcessErrors = @ProcessErrors OUTPUT,
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                            @Debug = 0;

                        IF @debug > 0
                            SELECT @return_value AS AuditUpdate_returnvalue;

                        --get toobjid from audit history
                        SELECT @Tobjid = MAX(mottco.ObjID)
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
                    --            SET @Tobjid = ISNULL(@Tobjid, 0) + 1000;
                    --      SET @Tobjid = ISNULL(@Tobjid, 0);
                    SET @DebugText = N'Max Objid %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Set Max objid';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Tobjid);
                    END;

                    SET @ProcedureStep = N'class table update in batches';
                    SET @LogTypeDetail = N'Debug';
                    SET @LogTextDetail = N' Start Update in batches: Max objid ' + CAST(@Tobjid AS NVARCHAR(256));
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
                        EXEC dbo.spMFUpdateObjectChangeHistory @MFTableName = @MFTableName, -- nvarchar(200)
                            @WithClassTableUpdate = 0,                                      -- int
                            @Objids = NULL,                                                 -- nvarchar(max)
                            @ProcessBatch_ID = @ProcessBatch_ID,                            -- int
                            @Debug = @debug;                                                -- smallint
                    END;

                    -- remove all items in class table not in audit table for the class
                    SET @sql
                        = N';WITH cte AS
                (
                SELECT t.objid FROM ' + QUOTENAME(@MFTableName)
                          + ' t
                LEFT JOIN dbo.MFAuditHistory AS mah 
                ON t.objid = mah.objid AND t.' + QUOTENAME(@ClassColumn)
                          + '= mah.class 
                where mah.objid is null
                )
                DELETE FROM ' + QUOTENAME(@MFTableName) + ' WHERE objid IN (SELECT cte.objid FROM cte);';

                    EXEC (@sql);
                END;

                -- full update with no audit details

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

                    -------------------------------------------------------------
                    -- do table update with most recent update date filter
                    -------------------------------------------------------------

                    DECLARE @SessionIDOut INT;

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
                        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                        @Debug = @debug;
                END; -- end partial refresh setup

                SET @ProcedureStep = N'Max objid';

                SELECT @Tobjid = MAX(mah.ObjID)
                FROM dbo.MFAuditHistory AS mah
                WHERE mah.Class = @Class_ID
                      AND mah.ObjectType = @ObjectType_ID;

                SET @Tobjid = ISNULL(@Tobjid, 0);
                SET @DebugText = N' from AuditTable %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Tobjid);
                END;

                -- update audit history with items not in audit table
                SET @ProcedureStep = N'Objects not in Audit Table ';
                SET @sqlParam = N'@Class_ID int, @ObjectType_ID int';
                SET @sql
                    = N'SELECT Getdate(), @ObjectType_ID, @class_ID, cl.objid, cl.MFVersion,5, ''Not matched'',1
                    FROM ' + QUOTENAME(@MFTableName)
                      + N' AS cl with (NOLOCK)
                    LEFT JOIN dbo.MFAuditHistory AS mah with (NOLOCK)
                    ON cl.objid = mah.objid AND mah.Class = @Class_id and mah.ObjectType = @ObjectType_ID
                    WHERE mah.objid IS null and cl.GUID is not null';

                INSERT INTO dbo.MFAuditHistory
                (
                    TranDate,
                    ObjectType,
                    Class,
                    ObjID,
                    MFVersion,
                    StatusFlag,
                    StatusName,
                    UpdateFlag
                )
                EXEC sys.sp_executesql @Stmt = @sql,
                    @Param = @sqlParam,
                    @Class_id = @Class_ID,
                    @objectType_ID = @ObjectType_ID;

                SET @rowcount = @@RowCount;

                IF @debug > 0
                BEGIN
                    SET @DebugText = @DefaultDebugText + N' count  %i  ';

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;

                IF @WithStats = 1
                BEGIN
                    --SELECT @rowcount = COUNT(*)
                    --FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate,',') AS fmpds
                    SELECT @rowcount = COUNT(*)
                    FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID;

                    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
                    SET @Message
                        = @ProcedureName + N' Audit processed : Processing time (s): '
                          + CAST((CONVERT(FLOAT, @ProcessingTime / 1000)) AS VARCHAR(10)) + N' Records %i';

                    RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;
                END;

                -------------------------------------------------------------
                -- Get list of objects to update
                -------------------------------------------------------------
                --prepare list of differences          
                SELECT @rowcount = COUNT(ISNULL(au.ObjID, 0))
                FROM dbo.MFAuditHistory au WITH (NOLOCK)
                --WHERE (
                --          au.UpdateFlag = 1
                --          OR au.StatusFlag IN ( 1, 3 )
                --      )
                WHERE au.StatusFlag <> 0
                      AND au.Class = @Class_ID
                      AND au.ObjectType = @ObjectType_ID;

                SET @rowcount = @@RowCount;
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

                IF @rowcount > 0
                BEGIN

                    -------------------------------------------------------------
                    -- Update in batches
                    -------------------------------------------------------------
                    SELECT @ListID = MIN(au.ObjID)
                    FROM dbo.MFAuditHistory AS au WITH (NOLOCK)
                    --WHERE (
                    --          au.UpdateFlag = 1
                    --          OR au.StatusFlag IN ( 1, 3 )
                    --      )
                    WHERE au.StatusFlag <> 0
                          AND au.Class = @Class_ID
                          AND au.ObjectType = @ObjectType_ID;

                    ;

                    SELECT @Groupnumber = CASE
                                              WHEN @ListID IS NULL THEN
                                                  NULL
                                              ELSE
                                                  1
                                          END;

                    WHILE @ListID IS NOT NULL AND @Groupnumber IS NOT NULL
                    BEGIN
                        SET @StartTime = GETUTCDATE();

                        SELECT @CurrentGroup = @Groupnumber;

                        BEGIN
                            SELECT @ObjIds_toUpdate = STUFF(
                                                      (
                                                          SELECT ',',
                                                              CAST(list.ObjID AS VARCHAR(10))
                                                          FROM
                                                          (
                                                              SELECT TOP 500
                                                                  au.ObjID
                                                              FROM dbo.MFAuditHistory AS au WITH (NOLOCK)
                                                              --WHERE (
                                                              --          au.UpdateFlag = 1
                                                              --          OR au.StatusFlag IN ( 1, 3 )
                                                              --          OR au.recid IS null
                                                              --      )
                                                              WHERE au.StatusFlag <> 0
                                                                    AND au.Class = @Class_ID
                                                                    AND au.ObjectType = @ObjectType_ID
                                                                    AND au.ObjID >= @ListID
                                                              GROUP BY au.ObjID,
                                                                  au.Class,
                                                                  au.ObjectType
                                                              ORDER BY ObjID
                                                          ) list
                                                          FOR XML PATH('')
                                                      ),
                                                               1,
                                                               1,
                                                               ''
                                                           );

                            SET @rowcount =
                            (
                                SELECT COUNT(*)
                                FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate, ',') AS fmpds
                            );

                        IF @rowcount > 0
                        Begin
                            SET @ProcedureStep = N'spMFUpdateTable UpdateMethod 1';
            --                SET @StartTime = GETUTCDATE();
                            SET @LogTextDetail = N' Group# ' + ISNULL(CAST(@CurrentGroup AS VARCHAR(20)), '(null)');
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

                            IF @debug > 9
                            BEGIN
                                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

             --               SET @StartTime = GETUTCDATE();

                            IF @WithStats = 1
                            BEGIN
                                SELECT @FromObjid = MIN(list.ObjID),
                                    @Toobjid      = MAX(list.ObjID)
                                FROM
                                (
                                    SELECT TOP 500
                                        au.ObjID
                                    FROM dbo.MFAuditHistory AS au WITH (NOLOCK)
                                    --WHERE (
                                    --          au.UpdateFlag = 1
                                    --          OR au.StatusFlag IN ( 1, 3 )
                                    --          OR au.recid IS null
                                    --      )
                                    WHERE au.StatusFlag <> 0
                                          AND au.Class = @Class_ID
                                          AND au.ObjectType = @ObjectType_ID
                                          AND au.ObjID >= @ListID
                                    GROUP BY au.ObjID,
                                        au.Class,
                                        au.ObjectType
                                    ORDER BY ObjID
                                ) list;

                                SET @Message
                                    = N'Batch update from ' + CAST(ISNULL(@FromObjid, 0) AS VARCHAR(10)) + N' to  '
                                      + CAST(ISNULL(@Toobjid,0) AS VARCHAR(30));

                                RAISERROR(@Message, 10, 1) WITH NOWAIT;
                            END;
                            END; -- --if rowcount > 0
                            --IF @debug > 0
                            --SELECT @ObjIds_toUpdate AS 'objid';
                            IF @rowcount > 0
                            BEGIN
                                EXEC @return_value = dbo.spMFUpdateTable @MFTableName = @MFTableName,
                                    @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL,
                                    @ObjIDs = @ObjIds_toUpdate,
                                    @Update_IDOut = @Update_IDOut OUTPUT,
                                    @ProcessBatch_ID = @ProcessBatch_ID,
                                    @RetainDeletions = @RetainDeletions,
                                    @Debug = 0;

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
                                SET @LogColumnName = N'MFUpdate_ID ';
                                SET @LogColumnValue = CAST(ISNULL(@Update_IDOut, 0) AS NVARCHAR(256));

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
                            END; -- objids is not null
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
                                SET @sqlParam = N'@Class_ID int, @ObjIds_toUpdate nvarchar(max) output';
                                SET @sql
                                    = N';
   WITH cte AS
   (
   SELECT objid, MAX(mfversion) AS MFVersion FROM dbo.MFObjectChangeHistory AS moch 
   WHERE class_id = @Class_id
   GROUP BY objid)
   SELECT distinct @ObjIds_toUpdate = STUFF((SELECT '','' + CAST(t2.objid AS VARCHAR(10)) 
   from ' +                     QUOTENAME(@MFTableName)
                                      + N' AS t2
   INNER JOIN (SELECT item FROM dbo.fnMFSplitString(@ObjIds_toUpdate,'','')) AS fmss
   ON t2.objid = fmss.item
   LEFT JOIN cte 
ON t2.objid = cte.objid
 WHERE t2.MFVersion > ISNULL(cte.MFVersion,0)
 FOR XML PATH('''')),1,1,'''')
   ;'                           ;

                                EXEC sys.sp_executesql @sql, @sqlParam, @Class_ID, @ObjIds_toUpdate OUTPUT;

                                SET @DebugText = @ObjIds_toUpdate;
                                SET @DebugText = @DefaultDebugText + @DebugText;
                                SET @ProcedureStep = N'Get History for selected objids: ';

                                IF @debug > 0
                                BEGIN
                                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                                END;

                            --EXEC dbo.spMFUpdateObjectChangeHistory @MFTableName = @MFTableName,
                            --    @WithClassTableUpdate = 0,
                            --    @Objids = @ObjIds_toUpdate,
                            --    @ProcessBatch_ID = @ProcessBatch_ID,
                            --    @Debug = @debug;
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
                                --SELECT @rowcount = COUNT(*)
                                --FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate,',') AS fmpds
                                SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
                                SET @Message
                                    = @ProcedureName + N' : Processing time (s): '
                                      + CAST((CONVERT(FLOAT, @ProcessingTime / 1000)) AS VARCHAR(10)) + N' Records %i';

                                RAISERROR(@Message, 10, 1, @rowcount) WITH NOWAIT;
                            END;

                            SELECT @Groupnumber = @Groupnumber + 1;

                            SET @DebugText = N' ' + CAST(ISNULL(@Groupnumber, 0) AS VARCHAR(10));
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'Next group # ';

                            IF @debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

                            SELECT @ListID =
                            (
                                SELECT TOP 1
                                    au.ObjID
                                FROM dbo.MFAuditHistory AS au WITH (NOLOCK)
                                WHERE au.ObjID > @Toobjid
                                      AND
                                      --(
                                      --    au.UpdateFlag = 1
                                      --    OR au.StatusFlag IN ( 1, 3 )
                                      --)
                                       au.StatusFlag <> 0
                                      AND au.Class = @Class_ID
                                      AND au.ObjectType = @ObjectType_ID
                                GROUP BY au.ObjID,
                                    au.Class,
                                    au.ObjectType
                                ORDER BY au.ObjID
                            );

                            SET @DebugText = N' ' + CAST(ISNULL(@ListID, 0) AS VARCHAR(10));
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'Next objid';

                            IF @debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;
                        END; --group number
                    END; --WHILE @ListID is not null

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'End batch loop';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
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

                    EXEC sys.sp_executesql @sql, @sqlParam, @Class_ID, @ObjIds_toUpdate OUTPUT;

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
                        @ProcessBatch_ID = 0,
                        @Debug = @debug;
                END;

                -------------------------------------------------------------
                -- remove objects from Class table, not in table audit
                -------------------------------------------------------------
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

                    SELECT @rowcount = COUNT(*)
                    FROM dbo.fnMFParseDelimitedString(@objids, ',') AS fmpds;

                    IF @rowcount > 0
                        EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                            @UpdateMethod = 1,
                            @ObjIDs = @objids;

                    SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(100));
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

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
            ERROR_MESSAGE()   AS ErrorMessage,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_STATE()     AS ErrorState,
            ERROR_SEVERITY()  AS ErrorSeverity,
            ERROR_LINE()      AS ErrorLine,
            @ProcedureName    AS ProcedureName,
            @ProcedureStep    AS ProcedureStep;

        RETURN -1;
    END CATCH;
END;
GO