print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFExportFilesMultiClasses]';
go
set nocount on;
exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFExportFilesMultiClasses' -- nvarchar(100)
                               , @Object_Release = '4.10.30.75'
                               , @UpdateFlag = 2;

go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFExportFilesMultiClasses' --name of procedure
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

-- if the routine exists this stub creation stem is parsed but not executed
create procedure dbo.spMFExportFilesMultiClasses
as
select 'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
set noexec off;
go
alter procedure dbo.spMFExportFilesMultiClasses
(
    @MFTableName nvarchar(100) = null
  , @IsDownload bit = 1
  , @IncludeDocID bit = 0
  , @isSetup bit = 1
  , @WithTableUpdate bit = 0
  , @ProcessBatch_ID int = null output
  , @Debug smallint = 0
)
as
/*rST**************************************************************************
===========================
spMFExportFilesMultiClasses
===========================

Return
  - 1 = Success
  - -1 = Error

Parameters  
  @MFTableName 
    Name of Table. If not specified then all the tables set as active in MFFileExportControl will be processed
  @IsDownload 
    Default = 1
    Select 0 to only download the data about the files, without the file.
  @IncludeDocID 
    Default = 0
    Select 1 to include the objid in the file name
  @isSetup 
    Default = 1.  This will produce several views to assist with setup of the control table, and will not execute the download
    Set to 0 to perform the export
  @WithTableUpdate 
    Default = 0
    Set to 1 to perform an update of the class tables before the file export
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

This procedure allows for exporting files accross multiple classes from a vault as defined in the MFFileExportControl table.  

Additional Info
===============

This procedure use class tables as input, the classtables must therefore exist and be up to date to download the files.

To export a single table, configure the columns in MFFileExportControl and specify the tablename in the parameters of spMFExportFilesMultiClasses

If parameter MFtableName is null then the export will be performed for all files for all the objects in the classes included in the MFFileExportControl table.  To exclude a table from the export, set the Active column in the control table to 0

The MFFileExportControl include additional statistics for the export update during the process:  Total Objects with files, Total Files and Total Size of all files. The LastModified also include the datetime stamp when to process for the table was completed.

Prerequisites
=============
The classes to be included and the folder columns to use is defined in the MFFileExportControl table.
The export will use the folder defined in MFSettings under Root Folder as the root of the export of the files. Ensure that the user executing the procudure have access permissions to the folder system.
The next level of folder is defined in MFClass by Class in the column FileExportFolder. If this is set then all files for the class will start from this folder.  If this is not set for the table then the export of the files will use the next level of folders from the column definition.  
The next three levels of folders that is selected from the columns of the class is set in the MFFileExportControl table.
Multifile documents will be filed with an additional folder set as the name of the multifile document object

Folder setting examples
=======================

RootFolder: d:\VaultFiles (Set in MFSettings); No folder is set for class in MFClass

Scenario 1 - Files by department, class, and document type  

d:\VaultFiles\HR\CV\CV_Received\Filename.xxx
d:\VaultFiles\Finance\Purchases\Order\Filename.xxx
d:\VaultFiles\Finance\Purchases\Sales_invoice\Filename.xxx

Scenario 2 - Customer, Document Type
d:\VaultFiles\Customer 1\sales_invoice\Filename.xxx
d:\VaultFiles\Customer 1\Purchase_invoice\Filename.xxx


Examples
========

Setup control

.. code:: sql
  
    declare @ProcessBatch_ID int;
    exec dbo.spMFExportFilesMultiClasses @MFTableName = null
                                   , @IsDownload = 0
                                   , @IncludeDocID = 0
                                   , @isSetup = 1
                                   , @WithTableUpdate = 0
                                   , @ProcessBatch_ID = @ProcessBatch_ID output
                                   , @Debug = 0

Get filesizes from vault

.. code:: sql
  
    declare @ProcessBatch_ID int;
    exec dbo.spMFExportFilesMultiClasses @MFTableName = null
                                   , @IsDownload = 0
                                   , @IncludeDocID = 0
                                   , @isSetup = 0
                                   , @WithTableUpdate = 0
                                   , @ProcessBatch_ID = @ProcessBatch_ID output
                                   , @Debug = 0

Perform file export

.. code:: sql
  
    declare @ProcessBatch_ID int;
    exec dbo.spMFExportFilesMultiClasses @MFTableName = null
                                   , @IsDownload = 1
                                   , @IncludeDocID = 0
                                   , @isSetup = 0
                                   , @WithTableUpdate = 0
                                   , @ProcessBatch_ID = @ProcessBatch_ID output
                                   , @Debug = 0


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-03-16  LC         Update documentation
2023-02-22  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


begin
    set nocount on;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------

    declare @ProcessType as nvarchar(50);

    set @ProcessType = isnull(@ProcessType, 'Export Files');

    -------------------------------------------------------------
    -- CONSTATNS: MFSQL Global 
    -------------------------------------------------------------
    declare @UpdateMethod_1_MFilesToMFSQL tinyint = 1;
    declare @UpdateMethod_0_MFSQLToMFiles tinyint = 0;
    declare @Process_ID_1_Update tinyint = 1;
    declare @Process_ID_6_ObjIDs tinyint = 6; --marks records for refresh from M-Files by objID vs. in bulk
    declare @Process_ID_9_BatchUpdate tinyint = 9; --marks records previously set as 1 to 9 and update in batches of 250
    declare @Process_ID_Delete_ObjIDs int = -1; --marks records for deletion
    declare @Process_ID_2_SyncError tinyint = 2;
    declare @ProcessBatchSize int = 250;

    -------------------------------------------------------------
    -- VARIABLES: MFSQL Processing
    -------------------------------------------------------------
    declare @Update_ID int;
    declare @MFLastModified datetime;
    declare @Validation_ID int;

    -------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
    declare @rowcount as int = 0;
    declare @return_value as int = 0;
    declare @error as int = 0;

    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    declare @ProcedureName as nvarchar(128) = N'dbo.spMFExportFilesMultiClasses';
    declare @ProcedureStep as nvarchar(128) = N'Start';
    declare @DefaultDebugText as nvarchar(256) = N'Proc: %s Step: %s';
    declare @DebugText as nvarchar(256) = N'';
    declare @Msg as nvarchar(256) = N'';
    declare @MsgSeverityInfo as tinyint = 10;
    declare @MsgSeverityObjectDoesNotExist as tinyint = 11;
    declare @MsgSeverityGeneralError as tinyint = 16;

    -------------------------------------------------------------
    -- VARIABLES: LOGGING
    -------------------------------------------------------------
    declare @LogType as nvarchar(50) = N'Status';
    declare @LogText as nvarchar(4000) = N'';
    declare @LogStatus as nvarchar(50) = N'Started';

    declare @LogTypeDetail as nvarchar(50) = N'System';
    declare @LogTextDetail as nvarchar(4000) = N'';
    declare @LogStatusDetail as nvarchar(50) = N'In Progress';
    declare @ProcessBatchDetail_IDOUT as int = null;

    declare @LogColumnName as nvarchar(128) = null;
    declare @LogColumnValue as nvarchar(256) = null;

    declare @count int = 0;
    declare @Now as datetime = getdate();
    declare @StartTime as datetime = getutcdate();
    declare @StartTime_Total as datetime = getutcdate();
    declare @RunTime_Total as decimal(18, 4) = 0;

    -------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
    declare @sql nvarchar(max) = N'';
    declare @sqlParam nvarchar(max) = N'';

    -------------------------------------------------------------
    -- VARIABLES: CUSTOM
    -------------------------------------------------------------


    declare @TempProcess_Id int = 7;
    declare @Process_ID int = 6;
    declare @Counter int;
    declare @Batch int = 1;
    declare @Class_ID int;
    declare @Tablename nvarchar(100);
    declare @Totalcount int;
    declare @Filecount int;
    declare @FileSize int;
    declare @PathProperty_L1 nvarchar(128);
    declare @PathProperty_L2 nvarchar(128);
    declare @PathProperty_L3 nvarchar(128);
    declare @classname nvarchar(100);
    declare @ClassFolder nvarchar(100);
    declare @MFLastUpdateDate smalldatetime
          , @Update_IDOut     int;

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    set @ProcedureStep = N'Start Logging';

    set @LogText = N'Processing ' + @ProcedureName;

    exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                   , @ProcessType = @ProcessType
                                   , @LogType = N'Status'
                                   , @LogText = @LogText
                                   , @LogStatus = N'In Progress'
                                   , @debug = @Debug;


    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                         , @LogType = N'Debug'
                                         , @LogText = @ProcessType
                                         , @LogStatus = N'Started'
                                         , @StartTime = @StartTime
                                         , @MFTableName = @MFTableName
                                         , @Validation_ID = @Validation_ID
                                         , @ColumnName = null
                                         , @ColumnValue = null
                                         , @Update_ID = @Update_ID
                                         , @LogProcedureName = @ProcedureName
                                         , @LogProcedureStep = @ProcedureStep
                                         , @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT
                                         , @debug = 0;


    begin try
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------

        -------------------------------------------------------------
        -- Setup control
        -------------------------------------------------------------

        ;
        merge into dbo.MFFileExportControl t
        using
        (
            select mc.MFID
                 , ot.MFID     as ObjectType
                 , mc.TableName
                 , active      = 0
                 , ah.objectcount
                 , ah.trandate trandate
            from dbo.MFClass                mc
                inner join dbo.MFObjectType ot
                    on mc.MFObjectType_ID = ot.ID
                left join
                (
                    select h.Class         as mfid
                         , h.ObjectType
                         , count(h.ObjID)  objectcount
                         , max(h.TranDate) trandate
                    from dbo.MFAuditHistory h
                    group by h.Class
                           , h.ObjectType
                )                           ah
                    on mc.MFID = ah.mfid
                       and ah.ObjectType = ot.MFID
            where mc.MFID >= 0
        ) s
        on s.MFID = t.MFID
        when matched and (
                             isnull(t.TotalObjects, 0) <> s.objectcount
                             or t.LastModified <> trandate
                         ) then
            update set t.TotalObjects = s.objectcount
                     , t.LastModified = s.trandate
        when not matched by target then
            insert
            (
                MFID
              , ObjectType
              , Active
              , TotalObjects
              , LastModified
            )
            values
            (s.MFID, s.ObjectType, s.active, s.objectcount, s.trandate)
        when not matched by source and t.MFID is not null then
            delete;


        --control validation

        if
        (
            select object_id('tempdb..#Controlvalidation')
        ) is not null
            drop table #Controlvalidation;

        create table #Controlvalidation
        (
            mfid int
          , TableName nvarchar(100)
          , MissingTable bit
          , MissingAudit bit
          , rootfolder nvarchar(100)
          , classFolder nvarchar(100)
          , candidateColumns nvarchar(1000)
        );

        insert into #Controlvalidation
        (
            mfid
          , TableName
          , MissingTable
          , MissingAudit
          , rootfolder
          , classFolder
        )
        select mc.MFID
             , mc.TableName
             , case
                   when ist.TABLE_NAME is null then
                       1
                   else
                       0
               end
             , case
                   when mfec.MFID is null then
                       1
                   else
                       0
               end
             , (
                   select cast(Value as nvarchar(100))
                   from dbo.MFSettings
                   where Name = 'RootFolder'
               )
             , mc.FileExportFolder
        from dbo.MFClass                        mc
            inner join dbo.MFFileExportControl  as mfec
                on mc.MFID = mfec.MFID
            left join INFORMATION_SCHEMA.TABLES ist
                on mc.TableName = ist.TABLE_NAME

        --if table not exist and is active then create table
        --if class is not used, ignore
        --if table not yet populated then update

        --determine column folders


        ;
        with cte
        as (select mc.MFID                           as mfid
                 , replace(mp.ColumnName, '_ID', '') ColumnName
            from dbo.MFClassProperty      as mcp
                inner join dbo.MFProperty mp
                    on mcp.MFProperty_ID = mp.ID
                inner join dbo.MFClass    as mc
                    on mcp.MFClass_ID = mc.ID
            where mp.MFID > 999
                  and mp.MFDataType_ID in ( 8, 9 ))
        update #Controlvalidation
        set candidateColumns = stuff((
                                         select ',' + cte2.ColumnName
                                         from cte as cte2
                                         where cte2.mfid = cte.mfid
                                         for xml path('')
                                     )
                                   , 1
                                   , 1
                                   , ''
                                    )
        from cte
        where #Controlvalidation.mfid = cte.mfid;




        -------------------------------------------------------------
        -- advisory notes
        -------------------------------------------------------------
        if @isSetup = 1
        begin

            declare @AdvisoryNotes as table
            (
                id int identity
              , [Advisory Comments] nvarchar(max)
            );

            insert into @AdvisoryNotes
            values
            ('The root folder can be changed in the MFSettings table')
          , ('The class folder is setup for each class in the MFClass table column FileExportFolder')
          , ('declare @mfid int = 15
Update MFFileExportControl set Active = 1 where mfid = @mfid
Update MFFileExportControl set PathProperty_l1 = ''Customer'', PathProperty_l2 = null, PathProperty_l3 = Null where mfid = @mfid')
          , ('Use the suggested folders to pick the up to 3 columns as folders from the candidateColumns in the listing')
          , ('Use Update MFFileExportControl set PathProperty_l1 = xxx, PathProperty_l2 = null, PathProperty_l3 = Null where mfid = xxx to setup to columns for each class');

            select *
            from @AdvisoryNotes as an;

            select 'Suggested Folders'
                 , mc.TableName
                 , mec.*
            from #Controlvalidation    mec
                inner join dbo.MFClass mc
                    on mc.MFID = mec.mfid
            order by mc.Name;

            select 'MFFileExportControl'
                 , mc.TableName
                 , mec.*
            from dbo.MFFileExportControl mec
                inner join dbo.MFClass   mc
                    on mc.MFID = mec.MFID
            order by mc.Name;

        end; -- issetup advisory notes

        -------------------------------------------------------------
        -- loop through export
        -------------------------------------------------------------
        if @isSetup = 0
        begin
            set @DebugText = N'Start Loop';
            set @DebugText = @DefaultDebugText + @DebugText;
            set @ProcedureStep = N'';

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            set @StartTime = getutcdate();

            select @Class_ID = case
                                   when @MFTableName is not null then
            (
                select mc.MFID from dbo.MFClass mc where mc.TableName = @MFTableName
            )
                                   when @MFTableName is null then
            (
                select min(t.MFID) as mfid
                from dbo.MFFileExportControl t
                where t.Active = 1
            )
                               end;

            while @Class_ID is not null
            begin

                select @classname   = mc.Name
                     , @Tablename   = mc.TableName
                     , @ClassFolder = mc.FileExportFolder
                from dbo.MFClass mc
                where mc.MFID = @Class_ID;
                -------------------------------------------------------------
                --    Validate class table
                -------------------------------------------------------------
                set @ProcedureStep = N'Validate class table ';
                if
                (
                    select object_id('.dbo.' + @Tablename)
                ) is null
                begin

                    set @DebugText = N' Table ' + @Tablename + N' is not found and will be created and populated';
                    set @DebugText = @DefaultDebugText + @DebugText;

                    if @debug > 0
                    begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end

                    exec dbo.spMFCreateTable @classname;

                    exec dbo.spMFUpdateMFilesToMFSQL @MFTableName = @Tablename
                                                   , @MFLastUpdateDate = @MFLastUpdateDate output
                                                   , @UpdateTypeID = 0
                                                   , @Update_IDOut = @Update_IDOut output
                                                   , @ProcessBatch_ID = @ProcessBatch_ID
                                                   , @debug = 0;


                end; --table validation

                -------------------------------------------------------------
                -- with table update
                -------------------------------------------------------------

                if @WithTableUpdate = 1
                begin
                    exec dbo.spMFUpdateMFilesToMFSQL @MFTableName = @Tablename
                                                   , @MFLastUpdateDate = @MFLastUpdateDate output
                                                   , @UpdateTypeID = 1
                                                   , @Update_IDOut = @Update_IDOut output
                                                   , @ProcessBatch_ID = @ProcessBatch_ID
                                                   , @debug = 0;
                end;

                select @PathProperty_L1 = t.PathProperty_L1
                     , @PathProperty_L2 = t.PathProperty_L2
                     , @PathProperty_L3 = t.PathProperty_L3
                from dbo.MFFileExportControl t
                    inner join dbo.MFClass   mc
                        on t.MFID = mc.MFID
                where t.MFID = @Class_ID;


                set @ProcedureStep = N'Get Table config for ' + @Tablename;
                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'Debug';
                set @LogTextDetail
                    = N' Col 1: ' + isnull(@PathProperty_L1, 'null') + N' Col 2: ' + isnull(@PathProperty_L2, 'null')
                      + N' Col 3: ' + isnull(@PathProperty_L3, 'null');
                set @LogColumnName = @Tablename;
                set @LogColumnValue = N'';

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                        , @LogType = @LogTypeDetail
                                                                        , @LogText = @LogTextDetail
                                                                        , @LogStatus = @LogStatusDetail
                                                                        , @StartTime = @StartTime
                                                                        , @MFTableName = @Tablename
                                                                        , @Validation_ID = @Validation_ID
                                                                        , @ColumnName = @LogColumnName
                                                                        , @ColumnValue = @LogColumnValue
                                                                        , @Update_ID = @Update_ID
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        , @debug = @Debug;

                -------------------------------------------------------------
                -- Validate columns
                -------------------------------------------------------------
                set @ProcedureStep = N'Validate Columns ';

                if @PathProperty_L1 is not null
                begin
                    set @count = -1;
                    select @count = count(*)
                    from INFORMATION_SCHEMA.COLUMNS
                    where TABLE_NAME = @Tablename
                          and COLUMN_NAME = @PathProperty_L1;

                    if @count = 0 and @isSetup = 1
                        set @DebugText = N' Column ' + @PathProperty_L1 + N' for ' + @Tablename + N' is not found';
                    set @DebugText = @DefaultDebugText + @DebugText;

                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                end;


                if @PathProperty_L2 is not null
                begin
                    set @count = -1;
                    select @count = count(*)
                    from INFORMATION_SCHEMA.COLUMNS
                    where TABLE_NAME = @Tablename
                          and COLUMN_NAME = @PathProperty_L2;

                    if @count = 0 and @isSetup = 1
                        set @DebugText = N' Column ' + @PathProperty_L2 + N' for ' + @Tablename + N' is not found';
                    set @DebugText = @DefaultDebugText + @DebugText;

                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                end;

                if @PathProperty_L3 is not null
                begin
                    set @count = -1;
                    select @count = count(*)
                    from INFORMATION_SCHEMA.COLUMNS
                    where TABLE_NAME = @Tablename
                          and COLUMN_NAME = @PathProperty_L3;

                    if @count = 0 and @isSetup = 1
                        set @DebugText = N' Column ' + @PathProperty_L3 + N' for ' + @Tablename + N' is not found';
                    set @DebugText = @DefaultDebugText + @DebugText;

                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                end;
                -------------------------------------------------------------
                -- Update totals
                -------------------------------------------------------------
                set @ProcedureStep = N'Update totals ';

                set @sql = N'select @totalcount = count(*) from ' + @Tablename + N' where isnull(filecount,0) > 0 ';

                exec sys.sp_executesql @sql
                                     , N'@TotalCount int output'
                                     , @Totalcount output;

                set @sql = N'select @Filecount = sum(isnull(filecount,0)) from ' + @Tablename + N' ';

                exec sys.sp_executesql @sql, N'@Filecount int output', @Filecount output;

                update dbo.MFFileExportControl
                set TotalObjects = @Totalcount
                  , TotalFiles = @Filecount
                  , LastModified = getdate()
                from dbo.MFFileExportControl
                where MFID = @Class_ID;

                set @DebugText
                    = N' TotalObjects ' + cast(isnull(@Totalcount, 0) as varchar(10)) + N' TotalFiles '
                      + cast(isnull(@Filecount, 0) as varchar(10));
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;
                -------------------------------------------------------------
                -- Set process_id for records to update
                -------------------------------------------------------------
                set @ProcedureStep = N'Set Process_ID';
                set @count = 0;
                set @sql
                    = N'Update t
Set process_ID = @TempProcess_Id
from ' +        @Tablename
                      + N' t
left join MFExportFileHistory h
on t.objid = h.ObjID and t.Class_ID = h.ClassID
where isnull(FileCheckSum,'''') = ''''
and isnull(t.filecount,0) > 0
'               ;

                exec sys.sp_executesql @sql, N'@TempProcess_Id int', @TempProcess_Id;

                set @count = @@rowcount;

                set @DebugText = N' Process_id count ' + cast(isnull(@count, 0) as varchar(10));
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;


                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'Debug';
                set @LogTextDetail = N' To Process ' + cast(@Counter as varchar(10));
                set @LogColumnName = N'object Count';
                set @LogColumnValue = cast(@count as varchar(100));

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                        , @LogType = @LogTypeDetail
                                                                        , @LogText = @LogTextDetail
                                                                        , @LogStatus = @LogStatusDetail
                                                                        , @StartTime = @StartTime
                                                                        , @MFTableName = @Tablename
                                                                        , @Validation_ID = @Validation_ID
                                                                        , @ColumnName = @LogColumnName
                                                                        , @ColumnValue = @LogColumnValue
                                                                        , @Update_ID = @Update_ID
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        , @debug = @Debug;

                set @Counter = @count;
                while isnull(@Counter, 0) > 0
                begin

                    set @ProcedureStep = N'Get files ';

                    set @StartTime = cast(getdate() as nvarchar(30));

                    set @sql
                        = N';with cte as
( Select top 500 objid from ' + @Tablename
                          + N' p where process_ID = @TempProcess_ID
)
update p
set process_id = @Process_ID
from ' +            @Tablename + N' p
inner join cte
on p.objid = cte.objid
where p.objid = cte.objid';

                    exec sys.sp_executesql @sql
                                         , N'@TempProcess_ID int, @Process_ID int'
                                         , @TempProcess_Id
                                         , @Process_ID;

                    set @sql = N'select @Count = count(*) from ' + @Tablename + N' where process_ID = @Process_ID';
                    exec sys.sp_executesql @sql
                                         , N' @Count int output, @Process_ID int'
                                         , @count output
                                         , @Process_ID;


                    set @LogTypeDetail = N'Status';
                    set @LogStatusDetail = N'Debug';
                    set @LogTextDetail = N' Batch ' + cast(@Batch as varchar(10));
                    set @LogColumnName = N'object Count';
                    set @LogColumnValue = cast(@count as varchar(100));

                    execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                            , @LogType = @LogTypeDetail
                                                                            , @LogText = @LogTextDetail
                                                                            , @LogStatus = @LogStatusDetail
                                                                            , @StartTime = @StartTime
                                                                            , @MFTableName = @Tablename
                                                                            , @Validation_ID = @Validation_ID
                                                                            , @ColumnName = @LogColumnName
                                                                            , @ColumnValue = @LogColumnValue
                                                                            , @Update_ID = @Update_ID
                                                                            , @LogProcedureName = @ProcedureName
                                                                            , @LogProcedureStep = @ProcedureStep
                                                                            , @debug = @Debug;




                    exec dbo.spMFExportFiles @TableName = @Tablename
                                           , @PathProperty_L1 = @PathProperty_L1
                                           , @PathProperty_L2 = @PathProperty_L2
                                           , @PathProperty_L3 = @PathProperty_L3
                                           , @IsDownload = @IsDownload
                                           , @IncludeDocID = @IncludeDocID
                                           , @Process_id = @Process_ID
                                           , @ProcessBatch_ID = @ProcessBatch_ID
                                           , @Debug = 0;



                    set @sql
                        = N'Select @Counter = count(*) from ' + @Tablename + N' where process_id = @TempProcess_Id';

                    exec sys.sp_executesql @sql
                                         , N' @Counter int output, @TempProcess_ID int'
                                         , @Counter output
                                         , @TempProcess_Id;


                    if @count > 501
                    begin
                        set @DebugText = N' Processing for table stopped, check errors';
                        set @DebugText = @DefaultDebugText + @DebugText;

                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                        set @Counter = null;

                        set @LogTypeDetail = N'Status';
                        set @LogStatusDetail = N'Error';
                        set @LogTextDetail = N' Batch ' + cast(@Batch as varchar(10));
                        set @LogColumnName = N'object Count';
                        set @LogColumnValue = cast(@count as varchar(100));

                        execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                                , @LogType = @LogTypeDetail
                                                                                , @LogText = @LogTextDetail
                                                                                , @LogStatus = @LogStatusDetail
                                                                                , @StartTime = @StartTime
                                                                                , @MFTableName = @Tablename
                                                                                , @Validation_ID = @Validation_ID
                                                                                , @ColumnName = @LogColumnName
                                                                                , @ColumnValue = @LogColumnValue
                                                                                , @Update_ID = @Update_ID
                                                                                , @LogProcedureName = @ProcedureName
                                                                                , @LogProcedureStep = @ProcedureStep
                                                                                , @debug = @Debug;

                    end;

                    select @Batch = @Batch + 1;

                end;

                -------------------------------------------------------------
                -- Update totals for table
                -------------------------------------------------------------
                set @ProcedureStep = N'Update file totals ';

                select @FileSize = sum(isnull(mefh.FileSize, 0))
                from dbo.MFExportFileHistory as mefh
                where mefh.ClassID = @Class_ID;


                update dbo.MFFileExportControl
                set TotalSize = @FileSize
                  , LastModified = getdate()
                from dbo.MFFileExportControl
                where MFID = @Class_ID;


                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'Debug';
                set @LogTextDetail = N' Get File Size in bytes ';
                set @LogColumnName = @Tablename;
                set @LogColumnValue = cast(@FileSize as varchar(100));

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                                        , @LogType = @LogTypeDetail
                                                                        , @LogText = @LogTextDetail
                                                                        , @LogStatus = @LogStatusDetail
                                                                        , @StartTime = @StartTime
                                                                        , @MFTableName = @Tablename
                                                                        , @Validation_ID = @Validation_ID
                                                                        , @ColumnName = @LogColumnName
                                                                        , @ColumnValue = @LogColumnValue
                                                                        , @Update_ID = @Update_ID
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        , @debug = @Debug;



                select @Class_ID = case
                                       when @MFTableName is not null then
                                           null
                                       when @MFTableName is null then
                (
                    select min(t.MFID) as mfid
                    from dbo.MFFileExportControl t
                    where t.Active = 1
                          and t.MFID > @Class_ID
                )
                                   end;

                set @count = 0;

            end; --end class loop

        end; --if setup

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        set @ProcedureStep = N'End';
        set @LogStatus = N'Completed';
        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   

        exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                       , @ProcessType = @ProcessType
                                       , @LogType = N'Message'
                                       , @LogText = @LogText
                                       , @LogStatus = @LogStatus
                                       , @debug = @Debug;

        set @StartTime = getutcdate();

        exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                             , @LogType = N'Debug'
                                             , @LogText = @ProcessType
                                             , @LogStatus = @LogStatus
                                             , @StartTime = @StartTime
                                             , @MFTableName = @MFTableName
                                             , @Validation_ID = @Validation_ID
                                             , @ColumnName = null
                                             , @ColumnValue = null
                                             , @Update_ID = @Update_ID
                                             , @LogProcedureName = @ProcedureName
                                             , @LogProcedureStep = @ProcedureStep
                                             , @debug = 0;
        return 1;
    end try
    begin catch
        set @StartTime = getutcdate();
        set @LogStatus = N'Failed w/SQL Error';
        set @LogTextDetail = error_message();

        --------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        --------------------------------------------------
        insert into dbo.MFLog
        (
            SPName
          , ErrorNumber
          , ErrorMessage
          , ErrorProcedure
          , ErrorState
          , ErrorSeverity
          , ErrorLine
          , ProcedureStep
        )
        values
        (@ProcedureName, error_number(), error_message(), error_procedure(), error_state(), error_severity()
       , error_line(), @ProcedureStep);

        set @ProcedureStep = N'Catch Error';
        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                       , @ProcessType = @ProcessType
                                       , @LogType = N'Error'
                                       , @LogText = @LogTextDetail
                                       , @LogStatus = @LogStatus
                                       , @debug = @Debug;

        set @StartTime = getutcdate();

        exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                             , @LogType = N'Error'
                                             , @LogText = @LogTextDetail
                                             , @LogStatus = @LogStatus
                                             , @StartTime = @StartTime
                                             , @MFTableName = @MFTableName
                                             , @Validation_ID = @Validation_ID
                                             , @ColumnName = null
                                             , @ColumnValue = null
                                             , @Update_ID = @Update_ID
                                             , @LogProcedureName = @ProcedureName
                                             , @LogProcedureStep = @ProcedureStep
                                             , @debug = 0;

        return -1;
    end catch;

end;

go
