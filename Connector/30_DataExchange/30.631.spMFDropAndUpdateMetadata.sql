print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFDropAndUpdateMetadata]';
go

set nocount on;

exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFDropAndUpdateMetadata' -- nvarchar(100)
                               , @Object_Release = '4.11.33.78'             -- varchar(50)
                               , @UpdateFlag = 2;
-- smallint
go

/*
MODIFICATIONS
*/
if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFDropAndUpdateMetadata' --name of procedure
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
create procedure dbo.spMFDropAndUpdateMetadata
as
select 'created, but not implemented yet.';
--just anything will do
go

-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFDropAndUpdateMetadata
    @IsResetAll smallint = 0
  , @WithClassTableReset smallint = 0
  , @WithColumnReset smallint = 0
  , @IsStructureOnly smallint = 1
  , @RetainDeletions bit = 0
  , @IsDocumentCollection bit = 0
  , @ProcessBatch_ID int = null output
  , @Debug smallint = 0
as
/*rST**************************************************************************

=========================
spMFDropAndUpdateMetadata
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsResetAll smallint (optional)
    - Default = 0
    - 1 = Reset to default values
  @WithClassTableReset smallint (optional)
    - Default = 0
    - 1 = reset all class tables included in App
  @WithColumnReset smallint (optional)
    - Default = 0
    - 1 = automatically reset column datatypes where datatypes changed
  @IsStructureOnly smallint (optional)
    - Default = 0
    - 1 = include updating of all valuelist items or only main structure elements
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To drop and update metadata for usage when creating multiple iterations of metadata and table changes during development.

Additional Info
===============

This procedure will only run if metadata structure changes were made. It is therefore useful to add this procedure as a scheduled agent, or as part of key procedures to keep the structure aligned.

Using this procedure will not overwrite custom settings in the structure tables. The custom columns include: 

================  ====================
Table             Customisable columns
================  ====================
MFClass           IncludedInApp
MFClass           TableName
MFClass           FileExportFolder
MFClass           SynchPresendence
MFProperty        ColumnName
MFValuelistItems  AppRef
MFValuelistItems  Owner_AppRef
================  ====================

This procedure can also be used to reset all the metadata, but retain
the custom settings in the Tables when the default is used or @ISResetAll = 0.

Set @ISResetAll = 1 only when custom settings in SQL should be reset to the defaults.  The following custom settings in the metadata tables. 

Setting the parameter @WithClassTableReset = 1 will drop and recreate all class tables where IncludeInApp = 1.  This is particularly usefull during testing or development to reset the class tables. This parameter is set to 0 by default.

Setting the parameter @WithColumnReset = 1 will force the synchronisation to add missing properties to class tables.  This is particularly handy when a property is added to multiple classes on the metadata cards and requires pull through to the class tables in SQL.  It will also change single lookup to multi lookup columns or visa versa.  This parameter is set to 0 by default.

Use :doc:`/procedures/spMFClassTableColumns/` to review the application and status of properties and columns on class tables.

By default this procedure will not be triggered if only valuelist items have been added in M-Files or no metadata changes have taken place.  To force this procedure to run, set the @IsStructureOnly = 0 to force an update in this scenario. 

Warnings
========

Do no run other procedures (such as spmfupdatetable) while any syncrhonisation of metadata is in progress.

The runtime of this procedure has increased, especially for large complex vaults. This is due to the extended validation checks performed during the procedure.

Not all metadata changes increases the GetMetadataStructureVersionID in M-Files. Changes to valuelist items does not set a version change for metadata changes.

The default options is not appropriate when valuelist items must be included in the update. There are several other methods to achieve the update of valuelist items rapidly, for instance :doc:`/procedures/spMFSynchronizeSpecificMetadata/`

Examples
========

Standard use without any parameters. This will retain all custom settings and only run if changes in M-Files have been detected.

.. code:: sql

     EXEC spMFDropAndUpdateMetadata

Running the procedure with default settings and no structure metadata change has taken place will exit very rapidly.

.. code:: sql

    DECLARE @ProcessBatch_ID INT;
    EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0          
                                          ,@WithClassTableReset = 0 
                                          ,@WithColumnReset = 0     
                                          ,@IsStructureOnly = 1     
                                          ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT 
                                          ,@Debug = 0 

----

To force an update of metadata when only valuelist items have changed or no metadata change has taken place, set the @IsStructureOnly = 0.

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]
               @IsStructureOnly = 0

----

The parameter @IsResetAll will remove all custom settings in SQL and reset the metadata structure to the vault.  This include removing all the class tables. This should only be used as a tool during prototyping and testing use cases.

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]
               @IsResetAll = 1

---

To reset columns when data types have changed, set the @WithColumnReset = 1

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]              
              ,@WithColumnReset = 1
              ,@IsStructureOnly = 0
              

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-12-18  LC         fix error with delimiter in reset functionality
2023-07-30  LC         Improve logging and update processing
2023-04-19  LC         Improve with column reset functionality
2021-09-30  LC         Update documentation regarding column fixes
2020-09-08  LC         Add fixing column errors in datatype 9
2019-08-30  JC         Added documentation
2019-08-27  LC         If exist table then drop, avoid sql error when table not exist
2019-08-06  LC         Change of metadata return value, remove if statement
2019-06-07  LC         Fix bug of not setting lookup table label column with correct type
2019-03-25  LC         Fix bug to update when change has taken place and all defaults are specified
2019-01-20  LC         Add prevent deleting data if license invalid
2019-01-19  LC         Add new feature to fix class table columns for changed properties
2018-11-02  LC         Add new feature to auto create columns for new properties added to class tables
2018-09-01  LC         Add switch to destinguish between structure only on including valuelist items
2018-06-28  LC         Add additional columns to user specific columns fileexportfolder, syncpreference
2017-06-20  LC         Fix begin tran bug
==========  =========  ========================================================

**rST*************************************************************************/

set nocount on;

declare @ProcedureStep varchar(100)  = 'start'
      , @ProcedureName nvarchar(128) = N'spMFDropAndUpdateMetadata';
declare @RC int;
declare @ProcessType nvarchar(50) = N'Metadata Sync';
declare @LogType nvarchar(50);
declare @LogText nvarchar(4000);
declare @LogStatus nvarchar(50);
declare @MFTableName nvarchar(128);
declare @Update_ID int;
declare @LogProcedureName nvarchar(128);
declare @LogProcedureStep nvarchar(128);
declare @ProcessBatchDetail_IDOUT as int = null;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
declare @DefaultDebugText as nvarchar(256) = N'Proc: %s Step: %s';
declare @DebugText as nvarchar(256) = N'';
declare @Msg as nvarchar(256) = N'';
declare @MsgSeverityInfo as tinyint = 10;
declare @MsgSeverityObjectDoesNotExist as tinyint = 11;
declare @MsgSeverityGeneralError as tinyint = 16;

---------------------------------------------
-- ACCESS CREDENTIALS FROM Setting TABLE
---------------------------------------------

--used on MFProcessBatchDetail;
declare @LogTypeDetail as nvarchar(50) = N'System';
declare @LogTextDetail as nvarchar(4000) = N'';
declare @LogStatusDetail as nvarchar(50) = N'In Progress';
declare @EndTime datetime;
declare @StartTime datetime;
declare @StartTime_Total datetime = getutcdate();
declare @Validation_ID int;
declare @LogColumnName nvarchar(128);
declare @LogColumnValue nvarchar(256);
declare @error as int = 0;
declare @rowcount as int = 0;
declare @return_value as int;

--Custom declarations
declare @Datatype int;
declare @Property nvarchar(100);
declare @rownr int;
declare @IsUpToDate bit;
declare @Count int;
declare @Length int;
declare @ColumnLength nvarchar(100);
declare @Labelname nvarchar(100);
declare @SQLDataType nvarchar(100);
declare @MFDatatype_ID int;
declare @SQL nvarchar(max);
declare @rowID int;
declare @MaxID int;
declare @ColumnName varchar(100);
declare @delimiter nvarchar(10) = N'_ID'; -- Delimiter for MF Type ID 9 and 10
declare @delimiterIndex int;
declare @substring nvarchar(100)

begin try

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    set @ProcedureStep = 'Start Logging';
    set @LogText = N'Processing ';

    exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                   , @ProcessType = @ProcedureName
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
                                         , @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT;

    -------------------------------------------------------------
    -- Validate license
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'validate lisense';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    declare @VaultSettings nvarchar(4000);

    select @VaultSettings = dbo.FnMFVaultSettings();

    exec @return_value = dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFGetClass' -- nvarchar(500)
                                                  , @ProcedureName = @ProcedureName         -- nvarchar(500)
                                                  , @ProcedureStep = @ProcedureStep
                                                  , @ProcessBatch_id = @ProcessBatch_ID;

    set @DebugText = N'License Return %s';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = '';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value);
    end;

    -------------------------------------------------------------
    -- Get up to date status
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'Get Structure Version ID';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    exec dbo.spMFGetMetadataStructureVersionID @IsUpToDate output;

    select @IsUpToDate = case
                             when @IsResetAll = 1 then
                                 0
                             else
                                 @IsUpToDate
                         end;
    -------------------------------------------------------------
    -- if Full refresh
    -------------------------------------------------------------


    if (
           @IsUpToDate = 0
           and @IsStructureOnly = 0
       )
       or
       (
           @IsUpToDate = 1
           and @IsStructureOnly = 0
       )
       or
       (
           @IsUpToDate = 0
           and @IsStructureOnly = 1
       )
       or @IsResetAll = 1
    begin

        set @DebugText = N' Full refresh';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'Refresh started ';

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;



        -------------------------------------------------------------
        -- License is valid - continue
        -------------------------------------------------------------			
        --    IF @return_value = 0 -- license validation returns 0 if correct

        select @ProcedureStep = 'setup temp tables';

        -------------------------------------------------------------
        -- setup temp tables
        -------------------------------------------------------------


        if exists (select * from sys.sysobjects where name = '#MFClassTemp')
        begin
            drop table #MFClassTemp;
        end;

        if exists (select 1 from sys.sysobjects where name = '#MFPropertyTemp')
        begin
            drop table #MFPropertyTemp;
        end;

        --if exists
        --(
        --    select 1
        --    from sys.sysobjects
        --    where name = '#MFValuelistItemsTemp'
        --)
        --begin
        --    drop table #MFValuelistItemsTemp;
        --end;


        --if exists
        --(
        --    select *
        --    from sys.sysobjects
        --    where name = '#MFWorkflowStateTemp'
        --)
        --begin
        --    drop table #MFWorkflowStateTemp;
        --end;

        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;



        -------------------------------------------------------------
        -- Populate temp tables
        -------------------------------------------------------------
        set @ProcedureStep = 'Populate temp tables ';

        --Insert Current MFClass table data into temp table
        select *
        into #MFClassTemp
        from
        (select * from dbo.MFClass) as cls;

        --Insert current MFProperty table data into temp table
        select *
        into #MFPropertyTemp
        from
        (select * from dbo.MFProperty) as ppt;

        --Insert current MFProperty table data into temp table
        --select *
        --into #MFValuelistItemsTemp
        --from
        --(select * from dbo.MFValueListItems) as ppt;

        --select *
        --into #MFWorkflowStateTemp
        --from
        --(select * from dbo.MFWorkflowState) as WST;

        --set @DebugText = N'';
        --set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            select *
            from #MFClassTemp as mct;

            select *
            from #MFPropertyTemp as mpt;

            --select *
            --from #MFValuelistItemsTemp as mvit;

            --select *
            --from #MFWorkflowStateTemp as mwst;

            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        -------------------------------------------------------------
        -- delete data from main tables
        -------------------------------------------------------------
        set @ProcedureStep = 'Delete existing tables';

        if
        (
            select count(*)from #MFClassTemp as mct
        ) > 0 and @IsResetAll = 1
        begin                       

            delete from dbo.MFClassProperty
            where MFClass_ID > 0;

            delete from dbo.MFClass
            where ID > -99;

            delete from dbo.MFProperty
            where ID > -99;       
			
			delete from dbo.MFObjectType
            where ID > -99;

            delete from dbo.MFLoginAccount
            where ID > -99;

            delete from dbo.MFUserAccount
            where UserID > -99;

            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;
        end;

        --delete if count(*) #classTable > 0
        -------------------------------------------------------------
        -- get new data
        -------------------------------------------------------------
        set @ProcedureStep = 'Start new Synchronization';
        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        --Synchronize metadata
        exec @return_value = dbo.spMFSynchronizeMetadata @ProcessBatch_ID = @ProcessBatch_ID output
                                                       , @Debug = @Debug;

        set @ProcedureName = N'spMFDropAndUpdateMetadata';

        if @Debug > 0
        begin
            select *
            from dbo.MFClass;

            select *
            from dbo.MFProperty;
        end;

        set @DebugText = N' Reset %i';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @IsResetAll);
        end;

        -------------------------------------------------------------
        -- update custom settings from previous data
        -------------------------------------------------------------
        --IF synchronize is success
        if (@return_value = 1 and @IsResetAll = 0)
        begin
            set @ProcedureStep = 'Update with no reset';

            update dbo.MFClass
            set TableName = #MFClassTemp.TableName
              , IncludeInApp = #MFClassTemp.IncludeInApp
              , FileExportFolder = #MFClassTemp.FileExportFolder
              , SynchPrecedence = #MFClassTemp.SynchPrecedence
            from dbo.MFClass
                inner join #MFClassTemp
                    on MFClass.MFID = #MFClassTemp.MFID
                       and MFClass.Name = #MFClassTemp.Name;

            update dbo.MFProperty
            set ColumnName = tmp.ColumnName
            from dbo.MFProperty            as mfp
                inner join #MFPropertyTemp as tmp
                    on mfp.MFID = tmp.MFID
                       and mfp.Name = tmp.Name;

            --update dbo.MFValueListItems
            --set AppRef = tmp.AppRef
            --  , Owner_AppRef = tmp.Owner_AppRef
            --from dbo.MFValueListItems            as mfp
            --    inner join #MFValuelistItemsTemp as tmp
            --        on mfp.MFID = tmp.MFID
            --           and mfp.Name = tmp.Name;

            --update dbo.MFWorkflowState
            --set IsNameUpdate = 1
            --from dbo.MFWorkflowState            as mfws
            --    inner join #MFWorkflowStateTemp as tmp
            --        on mfws.MFID = tmp.MFID
            --           and mfws.Name != tmp.Name;

            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;
        end;

        -- update old data
        -------------------------------------------------------------
        -- Class table reset
        -------------------------------------------------------------	
        if @WithClassTableReset = 1
        begin
            set @ProcedureStep = 'Class table reset';

            declare @ErrMsg varchar(200);

            set @ErrMsg = 'datatype of property has changed';

            --RAISERROR(
            --             'Proc: %s Step: %s ErrorInfo %s '
            --            ,16
            --            ,1
            --            ,'spMFDropAndUpdateMetadata'
            --            ,'datatype of property has changed, tables or columns must be reset'
            --            ,@ErrMsg
            --         );
            create table #TempTableName
            (
                ID int identity(1, 1)
              , TableName varchar(100)
            );

            insert into #TempTableName
            select distinct
                   TableName
            from dbo.MFClass
            where IncludeInApp is not null;

            declare @TCounter  int
                  , @TMaxID    int
                  , @TableName varchar(100);

            select @TMaxID = max(ID)
            from #TempTableName;

            set @TCounter = 1;

            while @TCounter <= @TMaxID
            begin
                declare @ClassName varchar(100);

                select @TableName = TableName
                from #TempTableName
                where ID = @TCounter;

                select @ClassName = Name
                from dbo.MFClass
                where TableName = @TableName;

                if exists
                (
                    select K_Table         = FK.TABLE_NAME
                         , FK_Column       = CU.COLUMN_NAME
                         , PK_Table        = PK.TABLE_NAME
                         , PK_Column       = PT.COLUMN_NAME
                         , Constraint_Name = C.CONSTRAINT_NAME
                    from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS     C
                        inner join INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK
                            on C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
                        inner join INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK
                            on C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
                        inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE  CU
                            on C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
                        inner join
                        (
                            select i1.TABLE_NAME
                                 , i2.COLUMN_NAME
                            from INFORMATION_SCHEMA.TABLE_CONSTRAINTS          i1
                                inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2
                                    on i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
                            where i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
                        )                                               PT
                            on PT.TABLE_NAME = PK.TABLE_NAME
                    where PK.TABLE_NAME = @TableName
                )
                begin
                    set @ErrMsg = 'Can not drop table ' + +'due to the foreign key';

                    raiserror(
                                 'Proc: %s Step: %s ErrorInfo %s '
                               , 16
                               , 1
                               , 'spMFDropAndUpdateMetadata'
                               , 'Foreign key reference'
                               , @ErrMsg
                             );
                end;
                else
                begin

                    if
                    (
                        select object_id(@TableName)
                    ) is not null
                    begin
                        exec ('Drop table ' + @TableName);

                        print 'Drop table ' + @TableName;
                    end;

                    exec dbo.spMFCreateTable @ClassName;

                    print 'Created table' + @TableName;
                    print 'Synchronizing table ' + @TableName;


                    declare @MFLastUpdateDate datetime, @Update_IDOut int
                    exec dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName
                                                   , @MFLastUpdateDate = @MFLastUpdateDate output
                                                   , @UpdateTypeID = 0
                                                   , @WithObjectHistory = 0
                                                   , @RetainDeletions = @RetainDeletions
                                                   , @Update_IDOut = @Update_IDOut output
                                                   , @ProcessBatch_ID = @ProcessBatch_ID output
                                                   , @debug = @debug

                end;

                set @TCounter = @TCounter + 1;
            end;

            drop table #TempTableName;

            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;
        end;

        --class table reset

        -------------------------------------------------------------
        -- perform validations
        -------------------------------------------------------------
        if @WithColumnReset = 1
        begin

            exec dbo.spMFClassTableColumns;

            select @Count
                = (sum(isnull(ColumnDataTypeError, 0)) + sum(isnull(missingColumn, 0)) + sum(isnull(MissingTable, 0))
                   + sum(isnull(RedundantTable, 0))
                  )
            from ##spmfclasstablecolumns;

            if @Count > 0
            begin
                set @DebugText = N' Count of errors %i';
                set @DebugText = @DefaultDebugText + @DebugText;
                set @ProcedureStep = 'Perform validations';

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                end;
                -------------------------------------------------------------
                -- resolve missing column
                -------------------------------------------------------------
                set @Count = 0;

                select @Count = sum(isnull(missingColumn, 0))
                from ##spmfclasstablecolumns;

                if @Count > 0
                begin
                    set @DebugText = N' %i';
                    set @DebugText = @DefaultDebugText + @DebugText;
                    set @ProcedureStep = 'Missing Column Error ';

                    if @Debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    end;

                    /*
check table before update and auto create any columns
--check existence of table
*/

                    set @rownr =
                    (
                        select min(id)from ##spMFClassTableColumns where MissingColumn = 1
                    );

                    while @rownr is not null
                    begin
                        select @MFTableName  = mc.Tablename
                             , @SQLDataType  = mdt.SQLDataType
                             , @ColumnName   = mc.ColumnName
                             , @Labelname     = mc.Columnname
                             , @ColumnLength = cast((coalesce(ColumnLength, '')) as varchar(100))
                             , @Datatype     = mc.MFDatatype_ID
                             , @Property     = mc.Property
                        from ##spMFclassTableColumns  mc
                            inner join dbo.MFDataType as mdt
                                on mc.MFDatatype_ID = mdt.MFTypeID
                        where mc.ID = @rownr;

                         if @MFDatatype_ID in ( 9, 10 )
                        begin
                            set @delimiterIndex = charindex(reverse(@delimiter), reverse(@Labelname));
                            if @delimiter > 0
                            begin
                                -- Extract the substring from the beginning of the input string up to the position of the delimiter minus 1                

                              set   @substring   = left(@Labelname, len(@Labelname) - @delimiterIndex - len(@delimiter) + 1);

                                -- Replace the input string with the modified substring
                                set @Labelname = @substring;

                            end;
                        end;

                        select @SQLDataType = mdt.SQLDataType
                        from dbo.MFDataType as mdt
                        where mdt.MFTypeID = @MFDatatype_ID;

                        begin
                            set @SQL
                                = case
                                      when @Datatype = 9 then
                                          N'Alter table ' + quotename(@MFTableName) + N' Add ' + quotename(@ColumnName)
                                          + N' ' + @SQLDataType + ', ' + quotename(@Labelname) + N' nvarchar(100)'
                                      when @Datatype = 10 then
                                          N'Alter table ' + quotename(@MFTableName) + N' Add ' + quotename(@Labelname)
                                          + N' Nvarchar(4000), ' + quotename(@ColumnName) + N' ' + @SQLDataType + ''
                                      else
                                          N'Alter table ' + quotename(@MFTableName) + N' Add ' + quotename(@ColumnName)
                                          + N' ' + @SQLDataType + ''
                                  end;

                            if @Debug > 0
                                print @SQL;

                            exec sys.sp_executesql @SQL;

                            print '##### ' + @Property + ' property as column ' + quotename(@ColumnName)
                                  + ' added for table ' + quotename(@MFTableName) + '';
                        end;


                        select @rownr =
                        (
                            select min(mc.id)
                            from ##spMFClassTableColumns mc
                            where MissingColumn = 1
                                  and mc.id > @rownr
                        );
                    end; -- end of loop
                end; -- End of mising columns



                -------------------------------------------------------------
                -- Data type errors
                -------------------------------------------------------------
                set @Count = 0;

                select @Count = sum(isnull(ColumnDataTypeError, 0))
                from ##spmfclasstablecolumns;

                if @Count > 0
                begin
                    set @DebugText = N' %i';
                    set @DebugText = @DefaultDebugText + @DebugText;
                    set @ProcedureStep = 'Data Type Error ';

                    if @Debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    end;
                end;

                begin
                    -------------------------------------------------------------
                    -- Resolve Class table column errors
                    -------------------------------------------------------------					;

                    set @rowID =
                    (
                        select min(id)from ##spMFClassTableColumns where ColumnDataTypeError = 1
                    );

                    while @rowID is not null
                    begin
                        select @TableName     = TableName
                             , @ColumnName    = ColumnName
                             , @Labelname     = Columnname
                             , @ColumnLength  = cast((coalesce(ColumnLength, '')) as varchar(100))
                             , @MFDatatype_ID = MFDatatype_ID
                        from ##spMFClassTableColumns
                        where id = @rowID;

                        --reset @labelName for lookups taking into account duplicate properties
                        if @MFDatatype_ID in ( 9, 10 )
                        begin
                            set @delimiterIndex = charindex(reverse(@delimiter), reverse(@Labelname));
                            if @delimiterindex > 0
                            begin
                                -- Extract the substring from the beginning of the input string up to the position of the delimiter minus 1                
                               
                                 set   @substring   = left(@Labelname, len(@Labelname) - @delimiterIndex - len(@delimiter) + 1);

                                -- Replace the input string with the modified substring
                                set @Labelname = @substring;

                            end;
                        end;

                        select @SQLDataType = mdt.SQLDataType
                        from dbo.MFDataType as mdt
                        where mdt.MFTypeID = @MFDatatype_ID;

                        --				SELECT * FROM dbo.MFDataType AS mdt

                        set @DebugText = N'';
                        set @DefaultDebugText = @DefaultDebugText + @DebugText;
                        set @ProcedureStep = 'Datatype error in 1,9,10,13 in column %s';

                        if @Debug > 0
                        begin
                            raiserror(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep, @ColumnName);
                        end;

                        --	SELECT @TableName,@columnName,@SQLDataType
                        if @MFDatatype_ID in ( 1, 9, 10, 13 )
                        begin try



                            set @SQL
                                = case
                                      when @MFDatatype_ID in ( 1, 13 ) then
                                          N'ALTER TABLE ' + quotename(@TableName) + N' ALTER COLUMN '
                                          + quotename(@Labelname) + N' ' + @SQLDataType + N'(' + @ColumnLength + ')'
                                      when @MFDatatype_ID in ( 9, 10 ) then
                                          N'ALTER TABLE ' + quotename(@TableName) + N' ALTER COLUMN '
                                          + quotename(@ColumnName) + N' ' + @SQLDataType + N'(' + @ColumnLength + ');'
                                      else
                                          N'ALTER TABLE ' + quotename(@TableName) + N' ALTER COLUMN '
                                          + quotename(@ColumnName) + N' ' + @SQLDataType + N'(' + @ColumnLength + ');'
                                  end;

                            if @Debug = 0
                                select @SQL;

                            exec (@SQL);

                        end try
                        begin catch
                            raiserror('Unable to change column %s in Table %s', 16, 1, @ColumnName, @TableName);
                        end catch;

                        select @rowID =
                        (
                            select min(id)
                            from ##spMFClassTableColumns
                            where id > @rowID
                                  and ColumnDataTypeError = 1
                        );
                    end; --end loop column reset
                end;

            --end WithcolumnReset

            -------------------------------------------------------------
            -- resolve missing table
            -------------------------------------------------------------

            -------------------------------------------------------------
            -- resolve redundant table
            -------------------------------------------------------------


            --check for any adhoc columns with no data, remove columns
            --check and update indexes and foreign keys
            end; --Validations
        end; -- column reset


        set @DebugText = N' %i';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'Drop temp tables ';

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        end;

        if exists (select * from sys.sysobjects where name = '#MFClassTemp')
        begin
            drop table #MFClassTemp;
        end;

        if exists (select * from sys.sysobjects where name = '#MFPropertyTemp')
        begin
            drop table #MFPropertyTemp;
        end;

        if exists
        (
            select *
            from sys.sysobjects
            where name = '#MFValueListitemTemp'
        )
        begin
            drop table #MFValueListitemTemp;
        end;


        set nocount off;

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        set @LogStatus = N'Completed';
        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'End of process';

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                       , @ProcessType = @ProcedureName
                                       , @LogType = N'Message'
                                       , @LogText = @LogText
                                       , @LogStatus = @LogStatus
                                       , @debug = @Debug;

        set @StartTime = getutcdate();

        exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                             , @LogType = N'Message'
                                             , @LogText = @ProcessType
                                             , @LogStatus = @LogStatus
                                             , @StartTime = @StartTime
                                             , @MFTableName = @MFTableName
                                             , @Validation_ID = @Validation_ID
                                             , @ColumnName = ''
                                             , @ColumnValue = ''
                                             , @Update_ID = @Update_ID
                                             , @LogProcedureName = @ProcedureName
                                             , @LogProcedureStep = @ProcedureStep
                                             , @debug = 0;





    end; -- is updatetodate and istructure only
    else
    begin
        print '###############################';
        print 'Metadata structure is up to date';
    end; --else: no processing, upto date
    return 1;
end try
begin catch
    if @@trancount > 0
        rollback;

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
    (@ProcedureName, error_number(), error_message(), error_procedure(), error_state(), error_severity(), error_line()
   , @ProcedureStep);

    set @ProcedureStep = 'Catch Error';

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
go
