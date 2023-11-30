print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFSynchronizeValueListItems]';
go

set nocount on;
exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFSynchronizeValueListItems' -- nvarchar(100)
                               , @Object_Release = '4.10.32.77'                 -- varchar(50)
                               , @UpdateFlag = 2;                               -- smallint

go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFSynchronizeValueListItems' --name of procedure
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
create procedure dbo.spMFSynchronizeValueListItems
as
select 'created, but not implemented yet.'; --just anything will do

go
-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFSynchronizeValueListItems
(
    @VaultSettings nvarchar(4000)
  , @Out nvarchar(max) output
  , @MFvaluelistID int = 0
  , @Debug smallint
  , @ProcessBatch_ID int = null output
)
as
/*rST**************************************************************************

=============================
spMFSynchronizeValueListItems
=============================

Purpose
=======

The purpose of this procedure is to synchronize M-File VALUE LIST ITEM details. It is an internal procedure and should not be used in custom procedures on its own.

This procedure can be called with spMFSynchronizeSpecificMetadata


==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-08-03  LC         Add logging and redesign approach to synchronisation
2019-08-30  JC         Added documentation
2018-05-26  LC         Delete valuelist items that is deleted in MF
2018-04-04  DEV2       Added License module validation code.
2016-26-09  DEV2       Change vault settings
2015-03-02  DEV1       Create proc
==========  =========  ========================================================

**rST*************************************************************************/


begin
    set nocount on;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    declare @MFTableName as nvarchar(128) = N'MFValuelistItems';
    declare @ProcessType as nvarchar(50);

    set @ProcessType = isnull(@ProcessType, 'Sync Valuelist Items');


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
    declare @ProcedureName as nvarchar(128) = N'dbo.spMFSynchronizeValuelistitems';
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



    declare @Xml    nvarchar(max)
          , @Output int;
    declare @XMLReturn xml;

    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = N'Start';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

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


    --    declare @ValueListId int;

    
        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFGetValueListItems  
        ------------------------------------------------------------------
        exec dbo.spMFCheckLicenseStatus 'spMFGetValueListItems'
                                      , 'spMFSynchronizeValueListItems'
                                      , 'Checking module access for CLR procdure  spMFGetValueListItems';


    begin try

      update mvli
        set mvli.Deleted = 1
        from dbo.MFValueList                mvl
            inner join dbo.MFValueListItems as mvli
                on mvli.MFValueListID = mvl.ID
        where mvl.Deleted = 1;

        if
        (
            select object_id('Tempdb..#TempValuelistItem')
        ) is not null
            drop table #TempValuelistItem;

        create table #TempValuelistItem
        (
            TempT_id int identity primary key
          , DisplayID nvarchar(100)
          , NewDisplayID nvarchar(100)
          , Name nvarchar(100)
          , NewName nvarchar(100)
          , OwnerID int
          , NewOwnerID int
          , AppRef nvarchar(100)
          , OwnerAppRef nvarchar(100)
          , MFID int
          , GUID nvarchar(200)
          , ValuelistID int
          , MFValuelistID int
          ,Process_ID int
          , IsUpdate int
          , Status nvarchar(10)
          , Deleted bit
        );

set @ProcedureStep = N'Insert current items in Temp table';
        insert into #TempValuelistItem
        (
            DisplayID
          , Name
          , OwnerID
          , AppRef
          , OwnerAppRef
          , MFID
          , GUID
          , ValuelistID
          , MFValuelistID
          ,Process_ID
          , IsUpdate
          , Status
          , Deleted
        )
        select isnull(MFWFS.DisplayID, cast(MFWFS.ID as varchar(100)))
             , MFWFS.Name
             , isnull(MFWFS.OwnerID, 0)
             , isnull(MFWFS.AppRef, 0)
             , MFWFS.Owner_AppRef
             , isnull(MFWFS.MFID, 0)
             , MFWFS.ItemGUID
             , MFWF.ID
             , MFWF.MFID
             ,mfwfs.Process_ID
             , MFWFS.IsNameUpdate
             , 'LastUpdate'
             , MFWFS.Deleted
        --  select mfwfs.*  
        from dbo.MFValueListItems      as MFWFS
            inner join dbo.MFValueList as MFWF
                on MFWFS.MFValueListID = MFWF.ID
        where isnull(MFWFS.MFID, 0) >= 0
              and
              (
                  MFWF.ID = @MFvaluelistID
                  or @MFvaluelistID = 0
              );

              set @count = @@rowcount

   set @DebugText = N' Count %i';
    set @DebugText = @DefaultDebugText + @DebugText;


    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@count);
    end;

    
                               SET @LogTypeDetail = 'Status';
                               SET @LogStatusDetail = 'In Progress';
                               SET @LogTextDetail = ' Current value list items: ' + cast(@count as varchar(10))
                               SET @LogColumnName = 'Count';
                               SET @LogColumnValue = cast(@count as varchar(10));
    
                               EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                                @ProcessBatch_ID = @ProcessBatch_ID
                              , @LogType = @LogTypeDetail
                              , @LogText = @LogTextDetail
                              , @LogStatus = @LogStatusDetail
                              , @StartTime = @StartTime
                              , @MFTableName = @MFTableName
                              , @Validation_ID = @Validation_ID
                              , @ColumnName = @LogColumnName
                              , @ColumnValue = @LogColumnValue
                              , @Update_ID = @Update_ID
                              , @LogProcedureName = @ProcedureName
                              , @LogProcedureStep = @ProcedureStep
                              , @debug = @debug

        -----------------------------------------------------
        -- update mfvaluelistitems for all deleted valuelists
        -----------------------------------------------------
  
  set @ProcedureStep = N'update mfvaluelistitems for all deleted valuelists';


            declare @XMLResult xml;
        declare @VLID   int
              , @VLMFID int
              ,@ValuelistName nvarchar(100);
              declare @InsertRow int, @UpdateRow int, @DeleteRow int, @ChangedRow int

        select @VLID = min(mvl.ID)
        from dbo.MFValueList mvl
        where isnull(mvl.RealObjectType, 0) = 0
              and mvl.Deleted = 0             ;


                set @ProcedureStep = N'loop mfvaluelistitems from wrapper';

  set @DebugText = N' Start loop';
    set @DebugText = @DefaultDebugText + @DebugText;


    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;


        while @VLID is not null 
        begin

        if @vlid = @MFvaluelistID  or @MFvaluelistID = 0

        begin
        
            select @VLMFID = mvl.MFID
            ,@ValuelistName = mvl.name
            from dbo.MFValueList mvl
            where mvl.ID = @VLID;

            set @StartTime = getutcdate();
          
          set @ProcedureStep = ' Get items from wrapper '
            ------------------------------------------------------------------------------------------
            --Execute 'GetMFValueListItems' to get the all MFValueListItems details in xml format 
            ------------------------------------------------------------------------------------------
            exec @return_value = dbo.spMFGetValueListItems @VaultSettings
                                                         , @VLMFID
                                                         , @Xml output;

      set @DebugText = N' Returnvalue %i Valuelist MFid: %i Name %s';
    set @DebugText = @DefaultDebugText + @DebugText;


    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@return_value,@VLMFID, @ValuelistName);
    end;



            select @XMLResult = cast(@Xml as xml);

    if @debug > 0
    select @XMLResult ;

           
            select @Msg = N' Get valuelist items ' + mvl.Name
            from dbo.MFValueList mvl
            where mvl.MFID = @VLMFID;

            set @DebugText = N' returnvalue %i Valuelistid %i %s';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value, @MFvaluelistID, @Msg);
            end;



            --set @LogTypeDetail = N'Status';
            --set @LogStatusDetail = N'';
            --set @LogTextDetail = @Msg;

            --set @LogColumnName = N'';
            --set @LogColumnValue = N'';

            --execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
            --                                                        , @LogType = @LogTypeDetail
            --                                                        , @LogText = @LogTextDetail
            --                                                        , @LogStatus = @LogStatusDetail
            --                                                        , @StartTime = @StartTime
            --                                                        , @MFTableName = @MFTableName
            --                                                        , @Validation_ID = @Validation_ID
            --                                                        , @ColumnName = @LogColumnName
            --                                                        , @ColumnValue = @LogColumnValue
            --                                                        , @Update_ID = @Update_ID
            --                                                        , @LogProcedureName = @ProcedureName
            --                                                        , @LogProcedureStep = @ProcedureStep
            --                                                        , @debug = @Debug;

            -----------------------------------------------------
            --INSERT DATA FROM XML INTO TEMPORARY TABLE
            -----------------------------------------------------
set @Count = 0
            insert into #TempValuelistItem
            (
                NewName
              , MFValuelistID
              , MFID
              , NewOwnerID
              , NewDisplayID
              , GUID
              ,AppRef
              ,OwnerAppRef
              , Status
              , ValuelistID
            )
            select t.c.value('(@Name)[1]', 'NVARCHAR(100)') as NAME
                 , t.c.value('(@MFValueListID)[1]', 'INT')  as MFValueListID
                 , t.c.value('(@MFID)[1]', 'INT')           as MFID
                 , t.c.value('(@Owner)[1]', 'INT')          as OwnerID
                 , t.c.value('(@DisplayID)[1]', 'nvarchar(200)')
                 , t.c.value('(@ItemGUID)[1]', 'nvarchar(200)')
                 , appref                                   = case
                                                                  when t.c.value('(@Owner)[1]', 'INT') = 7 then
                                                                      '0#'
                                                                  when t.c.value('(@Owner)[1]', 'INT') = 0 then
                                                                      '2#'
                                                                  when t.c.value('(@Owner)[1]', 'INT')in
                                                                       (
                                                                           select MFID from dbo.MFValueList
                                                                       ) then
                                                                      '2#'
                                                                  else
                                                                      '1#'
                                                              end + cast(mvl.MFID as nvarchar(5)) + '#' + t.c.value('(@MFID)[1]', 'NVARCHAR(10)')
                 , Owner_AppRef                             = case
                                                                  when mvl.OwnerID = 7 then
                                                                      '0#'
                                                                  when mvl.OwnerID = 0 then
                                                                      '2#'
                                                                  when mvl.OwnerID in
                                                                       (
                                                                           select MFID from dbo.MFValueList
                                                                       ) then
                                                                      '2#'
                                                                  else
                                                                      '1#'
                                                              end + cast(mvl.OwnerID as nvarchar(5)) + '#' + cast(mvli.OwnerID as nvarchar(10))
                 , 'New'
                 , mvl.ID
            from @XMLResult.nodes('/VLItem/ValueListItem') as t(c)
                left join dbo.MFValueList                  mvl
                    on mvl.MFID = t.c.value('(@MFValueListID)[1]', 'INT')
                left join dbo.MFValueListItems             as mvli
                    on mvli.MFID = t.c.value('(@MFID)[1]', 'INT')
                       and mvli.MFValueListID = mvl.ID
            where mvli.ItemGUID is null;

             set @count = @@rowcount
             set @InsertRow = @Count

            set @DebugText = N' Inserted count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@count);
            end;

            
set @count = 0
            update tvi
            set NewName = t.c.value('(@Name)[1]', 'NVARCHAR(100)')
              , NewDisplayID = t.c.value('(@DisplayID)[1]', 'nvarchar(200)')
              , NewOwnerID = t.c.value('(@Owner)[1]', 'INT')
              ,status = 'Updated'
            from #TempValuelistItem                                  as tvi
                inner join @XMLResult.nodes('/VLItem/ValueListItem') as t(c)
                    on tvi.GUID = t.c.value('(@ItemGUID)[1]', 'nvarchar(200)')
            where tvi.GUID = t.c.value('(@ItemGUID)[1]', 'nvarchar(200)') and tvi.status <> 'New'
   
   set @count = @@rowcount
   set @UpdateRow = @Count

            set @DebugText = N' Updated count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@count);
            end;


set @count = 0
update tmws
set Status = 'Deleted'
from #TempValuelistItem as tmws
where tmws.NewName is null and tmws.Name is not null and tmws.MFValuelistID = @VLMFID

  set @count = @@rowcount
  set @DeleteRow = @Count

            set @DebugText = N' Deleted count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@count);
            end;

            end -- if @MFValuelistID is not null

        select @VLID = (select min(mvl.ID)
        from dbo.MFValueList mvl
        where isnull(mvl.RealObjectType, 0) = 0
              and mvl.Deleted = 0 and mvl.id > @VLID);


           update  tvi
            set tvi.IsUpdate = 1
            from #TempValuelistItem as tvi
            where DisplayID != NewDisplayID 
            or Name != NewName
            or OwnerID != NewOwnerID

            set @ChangedRow = @@rowcount


                set @msg =' Valuelist:  '+ @ValuelistName+' New ' + cast(isnull(@InsertRow,0) as varchar(10)) + ' Compared ' + cast(isnull(@UpdateRow,0) as varchar(10)) + ' Changed ' + cast(isnull(@ChangedRow,0) as varchar(10)) + ' Deleted ' + cast(isnull(@DeleteRow,0) as varchar(10)) + ''

                set @LogTypeDetail = N'Status';
            set @LogStatusDetail = N'';
            set @LogTextDetail = @Msg;

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
                                                                    , @Update_ID = @Update_ID
                                                                    , @LogProcedureName = @ProcedureName
                                                                    , @LogProcedureStep = @ProcedureStep
                                                                    , @debug = @Debug;

                     end; --loop


            if @Debug > 10
            begin
                select 'After update ',*
                from #TempValuelistItem;
            end;

            select @ProcedureStep = N'Updating MFValueListItem ';


         


            -----------------------------------------------------
          --Updating valuelist items
          -----------------------------------------------------

           select  @ProcedureStep = 'New Valuelist items';

  insert  into dbo.MFValueListItems
  (
      Name
    , MFID
    , MFValueListID
    , OwnerID
    , Deleted
    , AppRef
    , Owner_AppRef
    , ItemGUID
    , DisplayID
    , Process_ID
    , IsNameUpdate
  )

   select  tmws.NewName , 
            tmws.MFID ,
            tmws.ValuelistID,
             tmws.NewOwnerID ,
               0 ,
			 CASE WHEN mvl.OwnerID = 7 THEN '0#'
                                  WHEN mvl.OwnerID = 0 THEN '2#'
                                  WHEN mvl.OwnerID IN ( SELECT
                                                              MFID
                                                        FROM  MFValueList )
                                  THEN '2#'
                                  ELSE '1#'
                             END + CAST(mvl.MFID AS NVARCHAR(5)) + '#'
                    + CAST(tmws.MFID AS NVARCHAR(10)) ,
                    Owner_AppRef = CASE WHEN mvl.OwnerID = 7 THEN '0#'
                                        WHEN mvl.OwnerID = 0 THEN '2#'
                                        WHEN mvl.OwnerID IN ( SELECT
                                                              MFID
                                                              FROM
                                                              MFValueList )
                                        THEN '2#'
                                        ELSE '1#'
                                   END + CAST(mvl.OwnerID AS NVARCHAR(5))
                    + '#' + CAST(tmws.newOwnerID AS NVARCHAR(10))	
                    ,tmws.GUID
                    ,tmws.NewDisplayID
                    ,0
                    ,0
           from    #TempValuelistItem as tmws  
           inner join dbo.MFValueList as mvl
           on tmws.MFValuelistID = mvl.MFID
            where tmws.status = 'New';

            SELECT  @InsertRow = @@ROWCOUNT;

            set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@InsertRow);
            end;

           SELECT  @ProcedureStep = 'Update Valuelist items';

				    UPDATE  mvli
                    SET  IsNameUpdate = 0 
                    ,Name = NewName
                    ,mvli.OwnerID = NewOwnerID                  
                    ,ModifiedOn = getdate()
                    ,Deleted = 0
                    FROM  dbo.MFValueListItems as mvli
                   inner join #TempValuelistItem as tmws  
                   on mvli.ItemGUID = tmws.guid
           inner join dbo.MFValueList as mvl
           on tmws.MFValuelistID = mvl.MFID

                            where isnull(tmws.Process_ID,0) = 0 and isnull(tmws.IsUpdate,0) = 1 and tmws.status = 'Updated';

                    SELECT  @Updaterow = @@ROWCOUNT;
                
 
              set @DebugText = N' count %s';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@MSg);
            end;

          --------------------------------------------------------
          -- Process deletes states
          -----------------------------------------------------  
 set @ProcedureStep = 'Delete Valuelist items'
 
 ;with cte as
   (
            select tmws.AppRef
           
            FROM   #TempValuelistItem as tmws
            where status = 'Deleted' 
)
update wfs
set wfs.Deleted = 1, wfs.ModifiedOn = getdate()
from dbo.MFValueListItems as wfs
where Appref in (select Appref from cte)

                 SELECT  @DeleteRow = @@ROWCOUNT;
                

              set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@DeleteRow);
            end;
       

     set @ProcedureStep = ' Valuelist items updated'

     set @msg = 'All Valuelists:  New ' + cast(isnull(@InsertRow,0) as varchar(10)) + ' Updated ' + cast(isnull(@UpdateRow,0) as varchar(10)) + ' Deleted ' + cast(isnull(@DeleteRow,0) as varchar(10)) + ''
  
                set @DebugText = N' %s';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@msg);
            end;


                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'';
                set @LogTextDetail = @msg;

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
                                                                        , @Update_ID = @Update_ID
                                                                        , @LogProcedureName = @ProcedureName
                                                                        , @LogProcedureStep = @ProcedureStep
                                                                        , @debug = @Debug;
 


 if (select count(process_ID) from dbo.MFValueListItems as mvli where Process_id = 1) > 0
 begin
 

 exec dbo.spMFSynchronizeValueListItemsToMFiles @ProcessBatch_ID = @ProcessBatch_ID 
                                              , @Debug = @dEBUG
 END

        --------------------------------------------------------------------
        --Select The Next ValueListId into declared variable '@vlaueListID' 
        --------------------------------------------------------------------

         set @ProcedureStep = N' ';
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            delete from dbo.MFValueListItems
            where  Deleted = 1;
 

        if exists (select top 1 * from dbo.MFValueListItems where IsNameUpdate = 1)
        begin

            exec dbo.spmfSynchronizeLookupColumnChange;

        end;

        
            set @Out = @msg
        


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

        --       COMMIT TRANSACTION;
        return 1;
        set nocount off;

    end try
    begin catch
        --        ROLLBACK TRANSACTION;

        set nocount on;

        if @Debug = 1
        begin
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
            ('spMFInsertWorkflowState', error_number(), error_message(), error_procedure(), error_state()
           , error_severity(), error_line(), @ProcedureStep);
        end;

        declare @ErrNum       int           = error_number()
              , @ErrProcedure nvarchar(100) = error_procedure()
              , @ErrSeverity  int           = error_severity()
              , @ErrState     int           = error_state()
              , @ErrMessage   nvarchar(max) = error_message()
              , @ErrLine      int           = error_line();

        set nocount off;

        raiserror(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);
    end catch;
end;

go
