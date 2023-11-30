print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.dbo.[spMFUpdateMFilesToMFSQL]';

set nocount on;

exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFUpdateMFilesToMFSQL' -- nvarchar(100)
                               , @Object_Release = '4.10.32.78'           -- varchar(50)
                               , @UpdateFlag = 2;

-- smallint
if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFUpdateMFilesToMFSQL' --name of procedure
          and ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          and ROUTINE_SCHEMA = 'dbo'
)
begin
    print space(10) + '...Stored Procedure: update';

    set noexec on;
end;
else
    print space(10) + '...Stored Procedure: create';
go

if object_id('tempdb..#ObjIdList') is null
    create table #ObjIdList
    (
        listid int identity
      , ObjId int
      , Flag int
    );
go

-- if the routine exists this stub creation stem is parsed but not executed
create procedure dbo.spMFUpdateMFilesToMFSQL
as
begin
    select 'created, but not implemented yet.'; --just anything will do
end;
go

-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFUpdateMFilesToMFSQL
(
    @MFTableName nvarchar(128)
  , @MFLastUpdateDate smalldatetime = null output
  , @UpdateTypeID tinyint = 1
  , @MaxObjects int = 100000
  , @WithObjectHistory bit = 0
  , @RetainDeletions bit = 0
  , @WithStats bit = 0
  , @Update_IDOut int = null output
  , @ProcessBatch_ID int = null output
  , @debug tinyint = 0
)
as
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
2023-11-10  LC         prevent update if @objids is null
2023-11-09  LC         remove resetting process 3 and 4
2023-08-16  LC         resolve bug for deleting not in class records
2023-08-15  LC         deal with null value warning 
2022-06-06  LC         resolve issue of removal of class table objects
2022-05-06  LC         resolve bug with nextbatch_ID
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
begin
    set nocount on;
    -- SET ANSI_WARNINGS OFF
    set xact_abort on;

    -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
    declare @ProcedureName as nvarchar(128) = N'spMFUpdateMFilesToMFSQL';
    declare @ProcedureStep as nvarchar(128) = N'Set Variables';
    declare @DefaultDebugText as nvarchar(256) = N'Proc: %s Step: %s';
    declare @DebugText as nvarchar(256) = N'';

    --used on MFProcessBatch;
    declare @ProcessType nvarchar(50);
    declare @LogType as nvarchar(50) = N'Status';
    declare @LogText as nvarchar(4000) = N'';
    declare @LogStatus as nvarchar(50) = N'Started';

    --used on MFProcessBatchDetail;
    declare @LogTypeDetail as nvarchar(50) = N'Debug';
    declare @LogTextDetail as nvarchar(4000) = @ProcedureStep;
    declare @LogStatusDetail as nvarchar(50) = N'In Progress';
    declare @EndTime datetime;
    declare @StartTime datetime;
    declare @StartTime_Total datetime = getutcdate();
    declare @Validation_ID int;
    declare @LogColumnName nvarchar(128);
    declare @LogColumnValue nvarchar(256);
    declare @RunTime as decimal(18, 4) = 0;
    declare @rowcount as int = 0;
    declare @return_value as int = 0;
    declare @error as int = 0;
    declare @output nvarchar(200);
    declare @sql nvarchar(max) = N'';
    declare @sqlParam nvarchar(max) = N'';

    -------------------------------------------------------------
    -- Global Constants
    -------------------------------------------------------------
    declare @UpdateMethod_1_MFilesToMFSQL tinyint = 1;
    declare @UpdateMethod_0_MFSQLToMFiles tinyint = 0;
    declare @UpdateType_0_FullRefresh tinyint = 0;
    declare @UpdateType_1_Incremental tinyint = 1;
    declare @UpdateType_2_Deletes tinyint = 2;
    declare @MFLastModifiedDate datetime;
    declare @DeletedInSQL   int
          , @UpdateRequired bit
          , @OutofSync      int
          , @ProcessErrors  int
          , @Class_ID       int
          , @DefaultToObjid int;
    declare @ListID          int
          , @Groupnumber     int
          , @Message         nvarchar(1000)
          , @FromObjid       int
          , @Toobjid         int
          , @ProcessingTime  int
          , @ObjIds_toUpdate nvarchar(max);
    declare @Batchsize int = 500;
    declare @BatchCount int = 1;
    declare @nextBatchID int;
    declare @tempObjidTable nvarchar(100);
    declare @RemainingCount int;
    declare @isobjectChange bit;

    begin try
        if exists (select 1 from dbo.MFClass where TableName = @MFTableName)
        begin
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;
            set @ProcedureStep = N'Start procedure';

            if @debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            -------------------------------------------------------------
            -- set up temp table for objidtable
            -------------------------------------------------------------
            select @tempObjidTable = dbo.fnMFVariableTableName('##ObjidTable', default);

            -------------------------------------------------------------
            -- Get/Validate ProcessBatch_ID
            set @ProcedureStep = N'Initialise M-Files to MFSQL';

            exec @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                                           , @ProcessType = 'UpdateMFilesToMFSQL'
                                                           , @LogText = @ProcedureStep
                                                           , @LogStatus = 'Started'
                                                           , @debug = @debug;

            set @StartTime = getutcdate();
            set @LogTypeDetail = N'Status';
            set @LogTextDetail = case
                                     when @UpdateTypeID = 0 then
                                         'UpdateType full refresh'
                                     else
                                         'UpdateType incremental refresh'
                                 end;
            set @LogStatusDetail = N'Started';
            set @LogColumnName = N'';
            set @LogColumnValue = N'';

            exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                 , @LogType = @LogTypeDetail
                                                 , @LogText = @LogTextDetail
                                                 , @LogStatus = @LogStatusDetail
                                                 , @StartTime = @StartTime
                                                 , @MFTableName = @MFTableName
                                                 , @ColumnName = @LogColumnName
                                                 , @ColumnValue = @LogColumnValue
                                                 , @LogProcedureName = @ProcedureName
                                                 , @LogProcedureStep = @ProcedureStep
                                                 , @debug = @debug;

            -------------------------------------------------------------
            -- Get column for last modified, deleted
            -------------------------------------------------------------
            declare @lastModifiedColumn nvarchar(100);

            select @lastModifiedColumn = mp.ColumnName
            from dbo.MFProperty as mp
            where mp.MFID = 21;

            --'Last Modified'
            declare @DeletedColumn nvarchar(100);

            select @DeletedColumn = mp.ColumnName
            from dbo.MFProperty as mp
            where mp.MFID = 27;

            --'Class'
            declare @ClassColumn nvarchar(100);


            select @ClassColumn = mp.ColumnName
            from dbo.MFProperty as mp
            where mp.MFID = 100;


            -------------------------------------------------------------
            -- Get last modified date
            -------------------------------------------------------------
            set @ProcedureStep = N'Get last updated  ';
            set @sqlParam = N'@MFLastModifiedDate Datetime output';
            set @sql
                = N'SELECT @MFLastModifiedDate = MAX(' + quotename(@lastModifiedColumn) + N') FROM '
                  + quotename(@MFTableName) + N' t where t.' + quotename(@lastModifiedColumn) + N' is not null ;';
            --if @debug > 0
            --print @sql;

            exec sys.sp_executesql @Stmt = @sql
                                 , @Params = @sqlParam
                                 , @MFLastModifiedDate = @MFLastModifiedDate output;

			


            select @MFLastModifiedDate = isnull(@MFLastModifiedDate, '1975-01-01');

            set @DebugText = N'Filter Date: ' + cast(@MFLastModifiedDate as nvarchar(100));
            set @DebugText = @DefaultDebugText + @DebugText;

            if @debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            --		select @MFLastModifiedDate = dateadd(d,-1,@MFLastModifiedDate)

            -------------------------------------------------------------
            -- Set objectchange history requirements
            -------------------------------------------------------------
            set @ProcedureStep = N'Set objectchange history requirements  ';
            set @isobjectChange = case
                                      when
                                      (
                                          select isnull(count(mochuc.ID), 0)
                                          from dbo.MFObjectChangeHistoryUpdateControl as mochuc
                                          where mochuc.MFTableName = @MFTableName
                                      ) > 0
                                      and @WithObjectHistory = 1 then
                                          1
                                      else
                                          0
                                  end;

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
6 = to be process for change history
*/
            declare @NewObjectXml nvarchar(max);
            declare @StatusFlag_0_Identical tinyint = 0;
            declare @StatusFlag_3_Checkedout tinyint = 3;
            declare @StatusFlag_1_MFilesIsNewer tinyint = 1;
            declare @StatusFlag_4_Deleted tinyint = 4;
            declare @StatusFlag_5_InMFSQLNotMF tinyint = 5;
            declare @StatusFlag_6_NotInMFSQL tinyint = 6;

            -------------------------------------------------------------
            -- Get class id and objecttype id
            -------------------------------------------------------------
            declare @ObjectType_ID int;

            select @Class_ID      = mc.MFID
                 , @ObjectType_ID = mot.MFID
            from dbo.MFClass                as mc
                inner join dbo.MFObjectType as mot
                    on mc.MFObjectType_ID = mot.ID
            where mc.TableName = @MFTableName;

            -------------------------------------------------------------
            -- Reset errors 3 and 4
            -------------------------------------------------------------
            --set @ProcedureStep = N'Reset process_ID errors 3 and 4 ';
            --set @sql = N'UPDATE [t]
            --        SET process_ID = 0
            --        FROM [dbo].' + quotename(@MFTableName) + N' AS t WHERE [t].[Process_ID] IN (3,4)';

            --exec (@sql);

            --set @rowcount = @@rowcount;
            --set @DebugText = N'Count %i';
            --set @DebugText = @DefaultDebugText + @DebugText;

            --if @debug > 0
            --begin
            --    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
            --end;

            -------------------------------------------------------------
            -- FULL REFRESH (resets audit table)
            -------------------------------------------------------------
            begin
                declare @MFAuditHistorySessionID int = null;
                set @StartTime = getutcdate()

                if @WithStats = 1
                begin
                    --SELECT @rowcount = COUNT(*)
                    --FROM dbo.fnMFParseDelimitedString(@ObjIds_toUpdate,',') AS fmpds
                    select @rowcount = isnull(count(mah.ID), 0)
                    from dbo.MFAuditHistory as mah
                    where mah.Class = @Class_ID;

                    set @Message = @ProcedureName + N' : Table audit started : Records in table %i';
                    raiserror(@Message, 10, 1, @rowcount) with nowait;
                end;

                set @sql
                    = N'
                   IF (SELECT OBJECT_ID(''tempdb..' + @tempObjidTable
                      + N''')) IS NOT NULL
                        DROP TABLE ' + @tempObjidTable + N' ;

                        CREATE TABLE ' + @tempObjidTable
                      + N' (tableid INT IDENTITY PRIMARY KEY, [objid] INT , MFVersion INT, Batchgroup int, [Type] int)

CREATE nonCLUSTERED INDEX idx_objidtable_objid ON ' + @tempObjidTable + N'(tableid,[objid],Batchgroup);';

                if @debug > 0
                    select @tempObjidTable as tempObjidTable;


                exec sys.sp_executesql @sql;

                declare @totalobjects bigint;

                select @totalobjects = max(mah.ObjID)
                from dbo.MFAuditHistory as mah
                where mah.ObjectType = @ObjectType_ID;

                -- reset maxobjids
                select @MaxObjects = case
                                         when @totalobjects < @MaxObjects then
                                             @MaxObjects
                                         else
                                             @MaxObjects
                                     end;


                set @StartTime = getutcdate();

                -------------------------------------------------------------
                -- FULL REFRESH START
                -------------------------------------------------------------
                if @UpdateTypeID = @UpdateType_0_FullRefresh
                begin
                    set @DebugText = N'';
                    set @DebugText = @DefaultDebugText + @DebugText;
                    set @ProcedureStep = N'Start full refresh';

                    if @debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                    begin

                        if @MaxObjects <= 100000
                        begin
                            -------------------------------------------------------------
                            -- Get object version result based on date for full refresh
                            -- delete audithistory, recreate based on date filter = 1950-01-01
                            -------------------------------------------------------------	    
                            --truncate history
                            --DELETE FROM dbo.MFAuditHistory
                            --WHERE Class = @Class_ID
                            --      AND ObjectType = @ObjectType_ID;
                            exec @return_value = dbo.spMFTableAudit @MFTableName = @MFTableName
                                                                  , @MFModifiedDate = @MFLastModifiedDate
                                                                  , @ObjIDs = null
                                                                  , @SessionIDOut = @MFAuditHistorySessionID output
                                                                  , @NewObjectXml = @NewObjectXml output
                                                                  , @DeletedInSQL = @DeletedInSQL output
                                                                  , @UpdateRequired = @UpdateRequired output
                                                                  , @OutofSync = @OutofSync output
                                                                  , @ProcessErrors = @ProcessErrors output
                                                                  , @UpdateTypeID = 0
                                                                  , @ProcessBatch_ID = @ProcessBatch_ID
                                                                  , @Debug = @debug;

                            if @debug > 0
                                select @return_value as AuditUpdate_returnvalue;

                        end; --end maxobj < 100000

                        if @MaxObjects > 100000 -- requires batching of table audit process
                        begin

                            declare @ToGroup int;
                            select @BatchCount = 1;

                            select @ToGroup = case
                                                  when min(mah.ObjID) > 0 then
                                                      min(mah.ObjID)
                                                  else
                                                      0
                                              end
                            from dbo.MFAuditHistory as mah
                            where mah.Class = @Class_ID;


                            while @ToGroup is not null or @ToGroup < @MaxObjects
                            begin

                                set @StartTime = getutcdate();

                                set @DebugText = N' Group %i between %i and %i ';
                                set @DebugText = @DefaultDebugText + @DebugText;
                                set @ProcedureStep = N'batch audit ';

                                if @debug > 0
                                begin
                                    raiserror(
                                                 @DebugText
                                               , 10
                                               , 1
                                               , @ProcedureName
                                               , @ProcedureStep
                                               , @BatchCount
                                               , @ToGroup
                                               , @MaxObjects
                                             );
                                end;


                                select @ObjIds_toUpdate = stuff((
                                                                    select top 50000
                                                                           ',' + cast(l.objid as varchar(20))
                                                                    from dbo.MFObjidList as l
                                                                    where l.objid
                                                                    between @ToGroup and @MaxObjects
                                                                    order by l.objid
                                                                    for xml path('')
                                                                )
                                                              , 1
                                                              , 1
                                                              , ''
                                                               );

                                set @ProcedureStep = N'Get Object Versions in batches';
                                --            SET @StartTime = GETUTCDATE();
                                set @LogTypeDetail = N'Status';
                                set @LogTextDetail
                                    = N' Batch : ' + cast(isnull(@BatchCount, 0) as varchar(30)) + N' objid : '
                                      + cast(@ToGroup as varchar(30));
                                set @LogStatusDetail = N'In progress';
                                set @LogColumnName = N'';
                                set @LogColumnValue = N'';

                                exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                     , @LogType = @LogTypeDetail
                                                                     , @LogText = @LogTextDetail
                                                                     , @LogStatus = @LogStatusDetail
                                                                     , @StartTime = @StartTime
                                                                     , @MFTableName = @MFTableName
                                                                     , @ColumnName = @LogColumnName
                                                                     , @ColumnValue = @LogColumnValue
                                                                     , @LogProcedureName = @ProcedureName
                                                                     , @LogProcedureStep = @ProcedureStep
                                                                     , @debug = @debug;

                                if @ObjIds_toUpdate is not null
                                begin

                                    exec @return_value = dbo.spMFTableAudit @MFTableName = @MFTableName
                                                                          , @MFModifiedDate = null
                                                                          , @ObjIDs = @ObjIds_toUpdate
                                                                          , @SessionIDOut = @MFAuditHistorySessionID output
                                                                          , @NewObjectXml = @NewObjectXml output
                                                                          , @DeletedInSQL = @DeletedInSQL output
                                                                          , @UpdateRequired = @UpdateRequired output
                                                                          , @OutofSync = @OutofSync output
                                                                          , @ProcessErrors = @ProcessErrors output
                                                                          , @UpdateTypeID = 0
                                                                          , @ProcessBatch_ID = @ProcessBatch_ID
                                                                          , @Debug = 0;
                                    ; if @debug > 0
                                          select @rowcount = count(isnull(fmpds.ID,0))
                                          from dbo.fnMFParseDelimitedString(@ObjIds_toUpdate, ',') as fmpds;

                                    set @DebugText = N' %i ';
                                    set @DebugText = @DefaultDebugText + @DebugText;
                                    set @ProcedureStep = N'audit result ';

                                    if @debug > 0
                                    begin
                                        select cast(@NewObjectXml as xml);
                                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                                    end;

                                end; --if objids to update not null en toGroup loop

                                if @WithStats = 1
                                begin
                                    set @ProcessingTime = datediff(millisecond, @StartTime, getutcdate());
                                    set @Message
                                        = @ProcedureName + N' : Process audit in batches '
                                          + cast(@BatchCount as nvarchar(10)) + N' : Processing time (s): '
                                          + cast((convert(float, @ProcessingTime / 1000)) as varchar(10))
                                          + N' to objid %i';

                                    raiserror(@Message, 10, 1, @ToGroup) with nowait;
                                end;



                                --   SELECT @ToGroup AS [before]
                                select @BatchCount = @BatchCount + 1;
                                select @ToGroup =
                                (
                                    select min(l.objid) + 50000
                                    from dbo.MFObjidList as l
                                    where l.objid > @ToGroup
                                          and l.objid < @MaxObjects + 1
                                );
                            --   SELECT @ToGroup AS [after]
                            end;



                        end; -- end of batching of table audit process
                        --get toobjid from audit history
                        select @Toobjid = max(mottco.ObjID)
                        from dbo.MFAuditHistory as mottco
                        where mottco.ObjectType = @ObjectType_ID
                              and mottco.Class = @Class_ID
                              and mottco.ObjID is not null;
                    end;

                    set @ProcedureStep = N'Get Object Versions with Batch Audit';
                    --            SET @StartTime = GETUTCDATE();
                    set @LogTypeDetail = N'Status';
                    set @LogTextDetail
                        = N' Batch Audit Max Object: ' + cast(isnull(@DefaultToObjid, 0) as varchar(30));
                    set @LogStatusDetail = N'In progress';
                    set @LogColumnName = N'';
                    set @LogColumnValue = N'';

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;

                    set @LogTypeDetail = N'Debug';
                    set @LogTextDetail = N' Audit Batch updates completed ';
                    set @LogColumnName = N'';
                    set @LogColumnValue = N'';

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;

                end; -- full update with no audit details



                -------------------------------------------------------------
                -- If incremental update
                -------------------------------------------------------------
                if @UpdateTypeID = @UpdateType_1_Incremental
                begin
                    --          SET @StartTime = GETUTCDATE();
                    set @DebugText = N'';
                    set @DebugText = @DefaultDebugText + @DebugText;
                    set @ProcedureStep = N'Start incremental refresh';

                    if @debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                    declare @SessionIDOut int;

                    -------------------------------------------------------------
                    -- do audit update for all changed and deleted objects
                    -------------------------------------------------------------
                    -------------------------------------------------------------
                    -- do table update with most recent update date filter
                    -------------------------------------------------------------
                    if @debug > 0
                        select @MFLastModifiedDate as last_modified_date;

                    set @ProcedureStep = N'Get Filtered Object Versions';
                    set @LogTypeDetail = N'Status';
                    set @LogTextDetail
                        = N' Last modified: ' + cast(convert(datetime, @MFLastModifiedDate, 105) as varchar(30));
                    set @LogStatusDetail = N'In progress';
                    set @LogColumnName = N'';
                    set @LogColumnValue = N'';

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;

                    exec dbo.spMFTableAudit @MFTableName = @MFTableName
                                          , @MFModifiedDate = @MFLastModifiedDate
                                          , @ObjIDs = null
                                          , @SessionIDOut = @SessionIDOut
                                          , @NewObjectXml = @NewObjectXml output
                                          , @DeletedInSQL = @DeletedInSQL output
                                          , @UpdateRequired = @UpdateRequired output
                                          , @OutofSync = @OutofSync output
                                          , @ProcessErrors = @ProcessErrors output
                                          , @UpdateTypeID = 1
                                          , @ProcessBatch_ID = @ProcessBatch_ID
                                          , @Debug = @debug;

                    set @ProcedureStep = N'update checked out and deleted objects';

                    select @ObjIds_toUpdate = stuff((
                                                        select ',' + cast(mah.ObjID as varchar(10))
                                                        from dbo.MFAuditHistory as mah
                                                        where mah.Class = @Class_ID
                                                              and mah.ObjectType = @ObjectType_ID
                                                              and mah.StatusFlag in ( 3, 4, 5 )
                                                        for xml path('')
                                                    )
                                                  , 1
                                                  , 1
                                                  , ''
                                                   );

                    select @rowcount = 0;
                    select @rowcount = count(isnull(mah.ID,0))
                    from dbo.MFAuditHistory as mah
                    where mah.Class = @Class_ID
                          and mah.ObjectType = @ObjectType_ID
                          and mah.StatusFlag in ( 3, 4, 5 );

                    set @LogTypeDetail = N'Status ';
                    set @LogTextDetail = N' Checked out and Deleted Objids: ' + cast(@rowcount as varchar(30));
                    set @LogStatusDetail = N'In progress';
                    set @LogColumnName = N'';
                    set @LogColumnValue = N'';

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;

                    if @rowcount > 0
                    begin

                        exec dbo.spMFTableAudit @MFTableName = @MFTableName
                                              , @MFModifiedDate = null
                                              , @ObjIDs = @ObjIds_toUpdate
                                              , @SessionIDOut = @SessionIDOut
                                              , @NewObjectXml = @NewObjectXml output
                                              , @DeletedInSQL = @DeletedInSQL output
                                              , @UpdateRequired = @UpdateRequired output
                                              , @OutofSync = @OutofSync output
                                              , @ProcessErrors = @ProcessErrors output
                                              , @UpdateTypeID = 1
                                              , @ProcessBatch_ID = @ProcessBatch_ID
                                              , @Debug = @debug;

                    end; -- rowcount > 0

                end; -- end partial refresh setup

                select @LogTextDetail
                    = stuff(
                      (
                          select '| ' + mah.StatusName + ': ' + cast(isnull(count(isnull(mah.StatusName,0)), 0) as varchar(10))
                          from dbo.MFAuditHistory as mah
                          where mah.Class = @Class_ID
                          group by mah.StatusName
                          for xml path('')
                      )
                    , 1
                    , 2
                    , ''
                           );


                set @ProcedureStep = N'Finalise Audit';
                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'';
                set @LogColumnName = N'';
                set @LogColumnValue = N'';

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                        , @LogType = @LogTypeDetail
                                                                        , @LogText = @LogTextDetail
                                                                        , @LogStatus = @LogStatusDetail
                                                                        , @StartTime = @StartTime
                                                                        , @MFTableName = @MFTableName
                                                                        , @Validation_ID = @Validation_ID
                                                                        , @ColumnName = @LogColumnName
                                                                        , @ColumnValue = @LogColumnValue
                                                                        , @Update_ID = @Update_IDOut
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        , @debug = @debug;

                if @WithStats = 1
                begin

                set @ProcessingTime = datediff(millisecond, @StartTime, getutcdate());
                    set @Message = @ProcedureName + N' : Table audit result : %s' + N' : Processing time (s): '
                                          + cast((convert(float, @ProcessingTime / 1000)) as varchar(10))

                    raiserror(@Message, 10, 1, @LogTextDetail) with nowait;
                end;

                -------------------------------------------------------------
                -- Get list of objects to update
                -------------------------------------------------------------
                select @rowcount = 0;

                select @rowcount = case
                                       when @RetainDeletions = 0 then
                (
                    select count(isnull(mah.ID,0))
                    from dbo.MFAuditHistory as mah
                    where mah.Class = @Class_ID
                          and @ObjectType_ID = mah.ObjectType
                          and mah.StatusFlag in ( 1, 3, 4, 5 )
                )
                                       when @RetainDeletions = 1 then
                (
                    select count(isnull(mah.ID,0))
                    from dbo.MFAuditHistory as mah
                    where mah.Class = @Class_ID
                          and @ObjectType_ID = mah.ObjectType
                          and mah.StatusFlag in ( 1, 3, 4, 5 )
                )
                                   end;
                if @rowcount > 0
                begin
                    set @sqlParam = N'@Class_ID int,@ObjectType_ID int ';

                    set @sql
                        = case
                              when isnull(@RetainDeletions, 0) = 0 then
                                  N'INSERT INTO ' + @tempObjidTable
                                  + N'
                        (
                            ObjId, MFVersion,Type
                        )
SELECT mah.objid, mah.MFVersion, mah.StatusFlag
FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID AND @ObjectType_ID = mah.ObjectType and StatusFlag IN ( 0,1,3,4,5 )
                    order by mah.objid;'
                              when @RetainDeletions = 1 then
                                  N'INSERT INTO ' + @tempObjidTable
                                  + N'
                        (
                            ObjId,MFVersion,Type
                        )
SELECT mah.objid,mah.MFVersion, mah.StatusFlag
FROM dbo.MFAuditHistory AS mah
                    WHERE mah.Class = @Class_ID AND @ObjectType_ID = mah.ObjectType and StatusFlag IN (0,1,3,4,5 )
                    order by mah.objid;'
                          end;

                    --IF @debug > 0
                    --    PRINT @sql;

                    exec sys.sp_executesql @sql, @sqlParam, @Class_ID, @ObjectType_ID;
                    set @rowcount = @@rowcount;

                    if @UpdateTypeID = @UpdateType_0_FullRefresh
                       and @isobjectChange = 1
                    begin

                        -------------------------------------------------------------
                        -- object history update full update
                        -------------------------------------------------------------         
                        set @ProcedureStep = N'Update object change history';

                        set @sqlParam = N'@Class_ID int';
                        set @sql
                            = N';with cte as
                            (
                            select mah.objid, mah.MFversion,6 as Type from dbo.MFAuditHistory as mah 
                   left join dbo.MFObjectChangeHistory as moch
                   on mah.objid = moch.objid and mah.Class = moch.class_id and mah.objecttype = moch.ObjectType_ID
                   where  mah.mfversion > isnull(moch.MFversion,-1) and moch.objid is null
                   and mah.StatusFlag in (0,1)
                   and mah.class = @Class_ID
                            )
                            
                            Update fmss
                            Set Type = 6
                            from ' + @tempObjidTable
                              + N' fmss
                            inner join cte
                            on fmss.objid = cte.objid                     
                   '    ;

                        exec sys.sp_executesql @sql, @sqlParam, @Class_ID;


                    end; -- insert if UpdateTypeID = 0


                    -------------------------------------------------------------
                    -- get final rowcount for update
                    -------------------------------------------------------------
                    set @sql = N'SELECT @rowcount = COUNT(isnull(obj.objid,0)) FROM ' + @tempObjidTable + N' obj where obj.type > 0';

                    exec sys.sp_executesql @stmt = @sql
                                         , @Param = N'@rowcount int output'
                                         , @Rowcount = @rowcount output;

                    -------------------------------------------------------------
                    -- set groups
                    -------------------------------------------------------------
                    set @ProcedureStep = N'Setup batch groups';
                    set @LogTextDetail = N'Temptable: ' + @tempObjidTable;
                    set @LogStatusDetail = N'Started';
                    set @LogColumnName = 'rowCount';
                    set @LogColumnValue = cast(isnull(@rowcount,0) as varchar(10));

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;


                    select @nextBatchID = case
                                              when @rowcount > 0 then
                                                  1
                                              else
                                                  null
                                          end;



              

                    while @nextBatchID is not null
                    begin

                    set @ProcedureStep = 'Processing update batches'                               

                        set @sqlParam = N'@nextBatchID int, @Batchsize int';
                        set @sql
                            = N'begin tran
;with cte as
(SELECT top ' +         cast(@Batchsize as varchar) + N' ot.objid FROM ' + @tempObjidTable
                              + N' AS ot WHERE ot.Batchgroup IS NULL and ot.type > 0 order by ot.objid)

UPDATE ot 
SET ot.Batchgroup = @nextbatchID
FROM ' +  @tempObjidTable + N' AS ot
inner join cte
on cte.objid = ot.objid
commit
;'                      ;

--if @debug > 0
--                        print @SQL;

                        exec sys.sp_executesql @sql
                                             , @sqlParam
                                             , @nextBatchID
                                             , @Batchsize;
                    

set @ProcedureStep = 'get rowcount' 

                        set @sqlParam = N'@rowcount int output, @NextBatchID int';
                        set @sql = N'
Select  @rowcount = COUNT(ot.objid)  FROM ' + @tempObjidTable + N' AS ot where ot.batchgroup = @NextBatchID';

                        exec sys.sp_executesql @sql, @sqlParam, @rowcount output, @nextBatchID;

                        if @debug > 0
                            select @nextBatchID as 'batchnumber'
                                 , @rowcount    as 'Batch count';


                        set @sqlParam = N'@RemainingCount int output';
                        set @sql = N'
SELECT @RemainingCount = COUNT(isnull(objid,0)) FROM ' + @tempObjidTable + N' WHERE batchgroup IS NULL and type > 0;';

                        exec sys.sp_executesql @sql, @sqlParam, @RemainingCount output;

                        set @nextBatchID = case
                                               when @RemainingCount > 0 then
                                                   @nextBatchID + 1
                                               else
                                                   null
                                           end;


                    end; --end loop for batch groups;';

                    set @sqlParam = N'@BatchCount int output';
                    set @sql = N'
     select @BatchCount = max(batchgroup) from ' + @tempObjidTable + N' where batchgroup is not null ';
                    exec sys.sp_executesql @sql, @sqlParam, @BatchCount output;


                    set @ProcedureStep = N'Get batch groups';
                    set @LogTextDetail = N'Batches to update: ';
                    set @LogStatusDetail = N'In Process';
                    set @LogColumnName = N'Count of Batches';
                    set @LogColumnValue = @BatchCount;

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;




                    set @sqlParam = N'@rowcount int output';
                    set @sql
                        = N'Select @rowcount = count(isnull(fmss.objid,0)) from ' + @tempObjidTable + N' AS fmss where type > 0';

                    exec sys.sp_executesql @sql, @sqlParam, @rowcount output;

                    set @nextBatchID = case
                                           when @rowcount > 0 then
                                               1
                                           else
                                               null
                                       end;

                    while @nextBatchID is not null and @BatchCount <> 0
                    begin

                        --                    SET @ProcedureStep = N'AuditTable objids: ';
                        set @sqlParam = N'@ToObjid int output';
                        set @sql = N'
                SELECT @Toobjid = MAX(ot.ObjID)
                FROM ' + @tempObjidTable + N' AS ot where ot.objid is not null and type > 0
                ;'      ;

                        exec sys.sp_executesql @sql, @sqlParam, @Toobjid output;

                        set @Toobjid = isnull(@Toobjid, 0);


                        -------------------------------------------------------------
                        -- Update in batches
                        -------------------------------------------------------------
                        set @ProcedureStep = N' Start update process ';
                        set @StartTime = getutcdate();
                        set @sqlParam = N'@ObjIds_toUpdate nvarchar(4000) output, @nextBatchID int ';
                        set @sql
                            = N' SELECT @ObjIds_toUpdate = STUFF((SELECT '','',CAST(list.ObjID AS VARCHAR(10)) FROM '
                              + @tempObjidTable
                              + N' AS list WHERE Batchgroup = @nextBatchID and isnull(list.objid,0) > 0 and list.type > 0 FOR XML PATH('''')),1,1,'''');';

                        exec sys.sp_executesql @sql
                                             , @sqlParam
                                             , @ObjIds_toUpdate output
                                             , @nextBatchID;

if @debug > 0
select isnull(@ObjIds_toUpdate,'') as ObjIds_toUpdate;

                        set @sqlParam
                            = N'@nextBatchID int, @rowcount int output, @FromObjid int output, @Toobjid int output ';
                        set @sql
                            = N'SELECT @rowcount = COUNT(isnull(list.objid,0)),  @FromObjid = MIN(list.ObjID), @Toobjid = MAX(list.ObjID) FROM '
                              + @tempObjidTable
                              + N'  AS list WHERE batchgroup = @nextBatchID and isnull(list.objid,0) > 0 and list.type > 0
   '                    ;

                        exec sys.sp_executesql @sql
                                             , @sqlParam
                                             , @nextBatchID
                                             , @rowcount output
                                             , @FromObjid output
                                             , @Toobjid output;

 set @ProcedureStep = N'Batch ' ;
                    set @LogTextDetail = N'Batch: ' + cast(@nextBatchID as varchar(10)) + ' obj count ' + cast(isnull(@rowcount,0) as varchar(10)) ;
                    set @LogStatusDetail = N'In Process';
                    set @LogColumnName = N'';
                    set @LogColumnValue = '';

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;



                        if isnull(@ObjIds_toUpdate,'') <> '' and @rowcount > 0
                        begin
                            set @ProcedureStep = N' Update MF ';
                            exec @return_value = dbo.spMFUpdateTable @MFTableName = @MFTableName
                                                                   , @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL
                                                                   , @ObjIDs = @ObjIds_toUpdate
                                                                   , @Update_IDOut = @Update_IDOut output
                                                                   , @ProcessBatch_ID = @ProcessBatch_ID
                                                                   , @RetainDeletions = @RetainDeletions
                                                                   , @Debug = @debug;


                            set @sqlParam = N'@rowcount int output, @Update_IDOut int';
                            set @sql
                                = N' SELECT @rowcount = COUNT(isnull(Update_ID,0)) FROM ' + @MFTableName
                                  + N' WHERE update_ID = @Update_IDOut;';

                            exec sys.sp_executesql @sql, @sqlParam, @rowcount output, @Update_IDOut;

                            set @error = @@error;
                            set @LogStatusDetail = case
                                                       when
                                                       (
                                                           isnull(@error, 0) <> 0
                                                           or @return_value = -1
                                                       ) then
                                                           'Failed'
                                                       when @return_value in ( 1, 0 ) then
                                                           'Completed'
                                                       else
                                                           'Exception'
                                                   end;
                            set @LogText = N'Return Value: ' + cast(@return_value as nvarchar(256));
                            set @LogTextDetail = N'Batch updated ';
                            set @LogColumnName = N'Batch nr ';
                            set @LogColumnValue = cast(isnull(@nextBatchID, 0) as nvarchar(256));

                            exec @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                                 , @LogType = @LogTypeDetail
                                                                                 , @LogText = @LogTextDetail
                                                                                 , @LogStatus = @LogStatusDetail
                                                                                 , @StartTime = @StartTime
                                                                                 , @MFTableName = @MFTableName
                                                                                 , @ColumnName = @LogColumnName
                                                                                 , @ColumnValue = @LogColumnValue
                                                                                 , @Update_ID = @Update_IDOut
                                                                                 , @LogProcedureName = @ProcedureName
                                                                                 , @LogProcedureStep = @ProcedureStep
                                                                                 , @debug = @debug;

                            if @WithStats = 1
                            begin
                             set @ProcessingTime = datediff(millisecond, @StartTime, getutcdate());

                                set @Message
                                    = @ProcedureName + N' : Batch ' + cast(@nextBatchID as varchar(10))
                                      + N' update from ' + cast(isnull(@FromObjid, 0) as varchar(10)) + N' to  '
                                      + cast(isnull(@Toobjid, 0) as varchar(30)) + N' : Processing time (s): '
                                          + cast((convert(float, @ProcessingTime / 1000)) as varchar(10))

                                raiserror(@Message, 10, 1) with nowait;
                            end; --if with stats


                        end; -- end updateobjids is not null



                        select @nextBatchID = case
                                                  when @nextBatchID < @BatchCount then
                                                      @nextBatchID + 1
                                                  else
                                                      null
                                              end;

                    end; -- end of loop batch is not null

                    -------------------------------------------------------------
                    -- object change history to be updated
                    -------------------------------------------------------------
                    set @ProcedureStep = N' object change history to be updated ';

                    set @LogTextDetail = N'Updating change history: ';
                    set @LogStatusDetail = N'In Process';
                    set @LogColumnName = null;
                    set @LogColumnValue = null;

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;



                    set @sqlParam = N'@Class_id int';
                    set @sql
                        = N';  WITH cte AS
   (
   SELECT moch.objid, MAX(isnull(moch.mfversion,0)) AS MFVersion FROM dbo.MFObjectChangeHistory AS moch 
   inner join ' +   @tempObjidTable
                          + N' AS fmss
    ON moch.objid = fmss.objid
   WHERE moch.class_id = @Class_id and fmss.Type = 1
   GROUP BY moch.objid)
   Update fmss
   set Type = 6
   from ' +         @tempObjidTable
                          + N' AS fmss 
   left join cte
   ON cte.objid = fmss.objid
 where fmss.MFVersion > ISNULL(cte.MFVersion,0) 
   ;'               ;

                    exec sys.sp_executesql @sql, @sqlParam, @Class_ID;
                    set @rowcount = 0;

                    set @sqlParam = N'@rowcount int output';
                    set @sql
                        = N'Select @rowcount = count(isnull(fmss.objid,0)) from ' + @tempObjidTable + N' AS fmss  where type = 6';
                    exec sys.sp_executesql @sql, @sqlParam, @rowcount output;

                       if @debug > 0
                       exec(N'Select ''for update object change'',* from ' + @tempObjidTable + N' AS fmss  where type = 6');

                    if @WithStats = 1
                       and @isobjectChange = 1
                       and @rowcount > 0
                    begin
                        set @ProcessingTime = datediff(millisecond, @StartTime, getutcdate());
                        set @Message
                            = @ProcedureName + N' : Change History to update ' + N' ';

                        raiserror(@Message, 10, 1, @rowcount) with nowait;
                    end;


                    --set @nextBatchID = case
                    --                       when @rowcount > 0 then
                    --                           1
                    --                       else
                    --                           null
                    --                   end;

                    --while @nextBatchID is not null
                    --      and @BatchCount <> 0
                    --      and @isobjectChange = 1
                    --      and @rowcount > 0
                    --begin
                        set @ProcedureStep = N'Change history update by batch';
                        -------------------------------------------------------------
                        -- Catch all - get history for items not included in batch update
                        -------------------------------------------------------------
                        set @ObjIds_toUpdate = null;

                        set @sqlParam = N'@ObjIds_toUpdate nvarchar(max) output';
                        set @sql
                            = N';  
   SELECT distinct @ObjIds_toUpdate = STUFF((SELECT '','' + CAST(t2.objid AS VARCHAR(10)) 
   from ' +             @tempObjidTable
                              + N' AS t2
 WHERE t2.Type = 6 and batchgroup is not null
 FOR XML PATH('''')),1,1,'''')
 '                      ;

                        exec sys.sp_executesql @sql
                                             , @sqlParam
                                             , @ObjIds_toUpdate output;
                                             


                        set @sqlParam = N'@rowcount int output ';
                        set @sql
                            = N'Select @rowcount = count(isnull(fmss.objid,0)) from ' + @tempObjidTable
                              + N' AS fmss  where type = 6 and batchgroup is not null ';

                        exec sys.sp_executesql @sql, @sqlParam, @rowcount output;

                        if @debug > 0
                            select cast(@ObjIds_toUpdate as xml) as 'objectIDs for change update';


                        set @ProcedureStep = N'Update History ';
                        if @ObjIds_toUpdate is not null
                        begin

                            set @LogTypeDetail = N'Status';
                            set @LogStatusDetail = N'In progress';
                            set @LogTextDetail = N' Object Change to update ' 
                            set @LogColumnName = N'Count ';
                            set @LogColumnValue = cast(@rowcount as varchar(10));

                            execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                                    , @LogType = @LogTypeDetail
                                                                                    , @LogText = @LogTextDetail
                                                                                    , @LogStatus = @LogStatusDetail
                                                                                    , @StartTime = @StartTime
                                                                                    , @MFTableName = @MFTableName
                                                                                    , @Validation_ID = @Validation_ID
                                                                                    , @ColumnName = @LogColumnName
                                                                                    , @ColumnValue = @LogColumnValue
                                                                                    , @Update_ID = @Update_IDOut
                                                                                    , @LogProcedureName = @ProcedureName
                                                                                    , @LogProcedureStep = @ProcedureStep
                                                                                    , @debug = @debug;



                            exec dbo.spMFUpdateObjectChangeHistory @MFTableName = @MFTableName
                                                                 , @WithClassTableUpdate = 0
                                                                 , @Objids = @ObjIds_toUpdate
                                                                 , @IsFullHistory = 0
                                                                 , @ProcessBatch_ID = @ProcessBatch_ID
                                                                 , @Debug = @debug;

                            if @WithStats = 1
                               and @isobjectChange = 1
                            begin
                                set @ProcessingTime = datediff(millisecond, @StartTime, getutcdate());
                                set @Message
                                    = @ProcedureName + N' : Change History for updated '
                                      + cast(@nextBatchID as varchar(10)) + N' :  Processing time (s): '
                                      + cast((convert(float, @ProcessingTime / 1000)) as varchar(10)) + N' Records %i';

                                raiserror(@Message, 10, 1, @rowcount) with nowait;
                            end;

                        end;

                    --    select @nextBatchID = case
                    --                              when @nextBatchID < @BatchCount then
                    --                                  @nextBatchID + 1
                    --                              else
                    --                                  null
                    --                          end;

                    --end; -- end loop update object changes



                end;

                -- remove all items in class table not in audit table for the class that have process id = 0

                set @ProcedureStep = N'Remove not in class objects';
                set @DebugText = N' Audit process return value %i ';
                set @DebugText = @DefaultDebugText + @DebugText;


                if @debug > 0
                begin
                    select cast(@NewObjectXml as xml);
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value);
                end;


                --     if @return_value IN ( 0, 1 )
                begin



                    set @sql
                        = N';WITH cte AS
                (
                SELECT t.objid FROM ' + quotename(@MFTableName)
                          + N' t
                LEFT JOIN dbo.MFAuditHistory AS mah 
                ON t.objid = mah.objid AND t.' + quotename(@ClassColumn)
                          + N'= mah.class 
                where mah.objid is null or mah.statusflag = 5
                )
                DELETE FROM ' + quotename(@MFTableName)
                          + N' WHERE objid IN (SELECT cte.objid FROM cte) and process_ID = 0;';

                    exec (@sql);
                    set @rowcount = @@rowcount;


                    set @LogTypeDetail = N'Debug';
                    set @LogTextDetail = N' Deleted not in class  ';
                    set @LogColumnName = N' count ';
                    set @LogColumnValue = cast(@rowcount as varchar(10));

                    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                         , @LogType = @LogTypeDetail
                                                         , @LogText = @LogTextDetail
                                                         , @LogStatus = @LogStatusDetail
                                                         , @StartTime = @StartTime
                                                         , @MFTableName = @MFTableName
                                                         , @ColumnName = @LogColumnName
                                                         , @ColumnValue = @LogColumnValue
                                                         , @LogProcedureName = @ProcedureName
                                                         , @LogProcedureStep = @ProcedureStep
                                                         , @debug = @debug;

                end; -- return value = success



                -------------------------------------------------------------
                -- Get last update date
                -------------------------------------------------------------
                set @ProcedureStep = N'Get update date for output';
                set @sqlParam = N'@MFLastModifiedDate Datetime output';
                set @sql
                    = N'
SELECT @MFLastModifiedDate = (SELECT MAX(' + quotename(@lastModifiedColumn) + N') FROM ' + quotename(@MFTableName)
                      + N' t where t.' + quotename(@lastModifiedColumn) + N' is not null )  ;';

                --if @debug > 0
                --print @SQL;

                exec sys.sp_executesql @Stmt = @sql
                                     , @Params = @sqlParam
                                     , @MFLastModifiedDate = @MFLastModifiedDate output;

                set @MFLastUpdateDate = @MFLastModifiedDate;

                -------------------------------------------------------------
                -- end logging
                -------------------------------------------------------------s
                set @error = @@error;
                set @ProcessType = N'Update Tables';
                set @LogType = N'Debug';
                set @LogStatusDetail = case
                                           when (@error <> 0) then
                                               'Failed'
                                           else
                                               'Completed'
                                       end;
                set @ProcedureStep = N'finalisation';
                set @LogTypeDetail = N'Debug';
                set @LogTextDetail = N'MF Last Modified: ' + convert(varchar(20), @MFLastUpdateDate, 120);
                --		SET @LogStatusDetail = 'Completed'
                set @LogColumnName = @MFTableName;
                set @LogColumnValue = N'';
                set @LogText = N'Update : ' + @MFTableName + N':Update Type ' + case
                                                                                    when @UpdateTypeID = 1 then
                                                                                        'Incremental'
                                                                                    else
                                                                                        'Full'
                                                                                end;
                set @LogStatus = N'Completed';
                set @LogStatusDetail = N'Completed';

                exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                                                  -- int
                                               , @ProcessType = @ProcessType
                                               , @LogText = @LogText
                                               , @LogType = @LogType
                                                                  -- nvarchar(4000)
                                               , @LogStatus = @LogStatus
                                                                  -- nvarchar(50)
                                               , @debug = @debug; -- tinyint

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                        , @LogType = @LogTypeDetail
                                                                        , @LogText = @LogTextDetail
                                                                        , @LogStatus = @LogStatusDetail
                                                                        , @StartTime = @StartTime
                                                                        , @MFTableName = @MFTableName
                                                                        , @Validation_ID = @Validation_ID
                                                                        , @ColumnName = @LogColumnName
                                                                        , @ColumnValue = @LogColumnValue
                                                                        , @Update_ID = @Update_IDOut
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        --        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
                                                                        , @debug = @debug;
            end; --REFRESH M-FILES --> MFSQL

            set nocount off;

            return 1;
        end;
        else
        begin
            set @ProcedureStep = N'Validate Class Table';

            raiserror('Invalid Table Name', 16, 1);
        end;
    end try
    begin catch
        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        insert into dbo.MFLog
        (
            SPName
          , ProcedureStep
          , ErrorNumber
          , ErrorMessage
          , ErrorProcedure
          , ErrorState
          , ErrorSeverity
          , ErrorLine
        )
        values
        (@ProcedureName, @ProcedureStep, error_number(), error_message(), error_procedure(), error_state()
       , error_severity(), error_line());

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        select error_number()    as ErrorNumber
             , error_message()   as ErrorMessage
             , error_procedure() as ErrorProcedure
             , error_state()     as ErrorState
             , error_severity()  as ErrorSeverity
             , error_line()      as ErrorLine
             , @ProcedureName    as ProcedureName
             , @ProcedureStep    as ProcedureStep;

        return -1;
    end catch;
end;
go