print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFSynchronizeWorkflowsStates]';
go


set nocount on;
exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFSynchronizeWorkflowsStates' -- nvarchar(100)
                               , @Object_Release = '4.10.32.77'                  -- varchar(50)
                               , @UpdateFlag = 2;                                -- smallint
-- smallint

go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFSynchronizeWorkflowsStates' --name of procedure
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
create procedure dbo.spMFSynchronizeWorkflowsStates
as
select 'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFSynchronizeWorkflowsStates
(
    @VaultSettings nvarchar(4000)
  , @Out nvarchar(max) output
  , @itemname nvarchar(100) = null
  , @IsUpdate smallint = 0
  , @Debug smallint
  , @ProcessBatch_ID int = null output
)
as
/*rST**************************************************************************

==============================
spMFSynchronizeWorkflowsStates
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @VaultSettings nvarchar(4000)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode
  @Out nvarchar(max) (output)
    fixme description
  @IsUpdate smallint
    fixme description


Purpose
=======

Called by other procedures to sync workflow states


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-07-29  LC         Improve logging and productivity
2019-08-30  JC         Added documentation
2018-04-04  DevTeam2   Added License module validation code 
2016-09-26  DevTeam2   Update @VaultSettings parmeter.
2018-11-15	LC         remove logging
2015-03-15  DEV        Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/


begin
    set nocount on;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    declare @MFTableName as nvarchar(128) = N'MFWorkflowState';
    declare @ProcessType as nvarchar(50);

    set @ProcessType = isnull(@ProcessType, 'Sync Workflow States');


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
    declare @ProcedureName as nvarchar(128) = N'dbo.spMFSynchronizeWorkflowsStates';
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
           declare @XMLReturn xml

    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = N'Backup workflow states';

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


    begin try

    if (select object_id('Tempdb..#TempMFWorkflowState')) is not null
    drop table #TempMFWorkflowState;

        create table #TempMFWorkflowState
        (
            TempT_id int identity primary key
          ,  ID int  
          , Name nvarchar(100)
          ,NewName nvarchar(100)
          , Alias nvarchar(100)
          ,NewAlias nvarchar(100)
          , MFID int
          , MFWorkflowID int
          , WorkflowMFID int
          ,Status nvarchar(10)
          ,IsUpdate bit
          ,Deleted bit
        );


        insert into #TempMFWorkflowState
        (
            ID
          , Name
          , Alias
          , MFID
          , MFWorkflowID
          ,WorkflowMFID
          ,Status
          ,IsUpdate
          ,Deleted
        )
        select MFWFS.ID
             , MFWFS.Name
             , MFWFS.Alias
             , MFWFS.MFID
             , MFWF.ID
             , MFWF.MFID 
             ,'LastUpdate'
             ,mfwfs.IsNameUpdate
             ,mfwfs.Deleted
        from dbo.MFWorkflowState      as MFWFS
            inner join dbo.MFWorkflow as MFWF
                on MFWFS.MFWorkflowID = MFWF.ID
        where MFWFS.MFID != 0 and (mfwf.Name = @itemname or @itemname is null);

        --	 End
        declare @WorkflowID int;

        select @WorkflowID = min(wf.MFID)
        from dbo.MFWorkflow wf where (wf.name = @itemname or @itemname is null);

                 -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------     

        while @WorkflowID is not null
        begin

            set @StartTime = getutcdate();

            set @ProcedureStep = N'Workfow %i ';
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @workflowID);
            end;

            ------------------------------------------------------------------------------------
            --Execute 'GetMFWorkFlowState' to get the all WorkflowsStates details in xml format
            ------------------------------------------------------------------------------------
            if @Debug > 0
                select mw.ID
                     , mw.MFID
                from dbo.MFWorkflow as mw
                where mw.MFID = @WorkflowID
                      and mw.Deleted = 0;


            exec @return_value = dbo.spMFGetWorkFlowState @VaultSettings
                                                        , @WorkflowID
                                                        , @Xml output;

set @XMLReturn = cast(@xml as xml)
           
           if isnull(@return_value, -1) <> 0
            begin


                set @DebugText = N' get states failed %s';
                set @DebugText = @DefaultDebugText + @DebugText;

                raiserror(@DebugText, 16, 1, @ProcedureName, @ProcedureStep, @Output);


            end;

            set @ProcedureStep = N'GetWorkflowStates Returned from wrapper';

            if @Debug > 0
            begin
                select @XMLReturn;
            end;

            select @Msg = N' Get states ' + Name
            from dbo.MFWorkflow
            where MFID = @WorkflowID;

            set @DebugText = N' returnvalue %i workflowid %i %s';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value, @WorkflowID, @Msg);
            end;



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

               
            IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END
 

 
          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SELECT  @ProcedureStep = 'Inserting CLR values into #WorkFlowStates';


           insert  INTO #TempMFWorkflowState
                    (   NewName
          , NewAlias
          , MFID
          , WorkflowMFID
          ,Status
                    )
                    select
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias,
                            t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                    t.c.value('(@MFWorkflowID)[1]', 'INT') AS WorkflowMFID ,
                    'New'

                    FROM    @XMLReturn.nodes('/form/WorkflowState') AS t ( c )
                    left join #TempMFWorkflowState as tmws
                    on tmws.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                    where tmws.mfid is null;

                    update temp
                    set 
                    temp.newname = t.c.value('(@Name)[1]', 'NVARCHAR(100)')  ,
                     newalias =  t.c.value('(@Alias)[1]', 'NVARCHAR(100)') ,
                    status = 'Updated'

                    from #TempMFWorkflowState temp
                    left join  @XMLReturn.nodes('/form/WorkflowState') AS t ( c )
                    on temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     where temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     and Status <> 'New'


					         update temp
                    set 
                    temp.newname = t.c.value('(@Name)[1]', 'NVARCHAR(100)')  ,
                     newalias =  t.c.value('(@Alias)[1]', 'NVARCHAR(100)') ,
                    status = 'Changed'

                    from #TempMFWorkflowState temp
                    left join  @XMLReturn.nodes('/form/WorkflowState') AS t ( c )
                    on temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     where temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     and Status = 'Updated'
					 and (temp.name <> t.c.value('(@Name)[1]', 'NVARCHAR(100)')  or
                     alias <>  t.c.value('(@Alias)[1]', 'NVARCHAR(100)'))

update tmws
set Status = 'Deleted'
from #TempMFWorkflowState as tmws
where tmws.NewName is null and tmws.Name is not null 


         select @WorkflowID =
            (
                select min(MFID)from dbo.MFWorkflow where MFID > @WorkflowID and ( name = @itemname or @itemname is null)
            );


        end; --end loop          
            
              set @DebugText = N' end of loop';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            if @debug > 10
            begin
                select 'before update',*
                from   #TempMFWorkflowState temp
                left join dbo.MFWorkflowState as mws
                on temp.mfid = mws.mfid
                end;
                
          -----------------------------------------------------
          --UPDATE MFID WITH PKID
          -----------------------------------------------------
  set @ProcedureStep = 'Update workflow id for PKID'
  update  temp
            SET     MFWorkflowID = wf.id
            from  #TempMFWorkFlowState temp
            inner join MFWorkflow wf
            on wf.MFID = WorkflowMFID
            where WorkflowMFID = wf.mfid 

                set @DebugText = N' ';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

              
        
          -----------------------------------------------------
          --Updating MFworkflowstate
          -----------------------------------------------------
declare @InsertRow int, @UpdateRow int, @DeleteRow int

           select  @ProcedureStep = 'New workflow states';

  insert  into MFWorkflowState
                    ( MFWorkflowID ,
                      MFID ,
                      Name ,
                      Alias ,
                      Deleted,
					  CreatedOn  
                    )
                    select  tmws.MFWorkflowID ,
                            tmws.MFID ,
                            tmws.newName ,
                            tmws.newAlias ,
                            0 ,
							getdate() -- Added for task 568
                    from    #TempMFWorkflowState as tmws                    
                    where tmws.status = 'New';

            SELECT  @InsertRow = @@ROWCOUNT;

            set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@InsertRow);
            end;

           SELECT  @ProcedureStep = 'Update workflow states';

				    UPDATE  wfs
                    SET  wfs.IsNameUpdate = 0 
                    ,wfs.Name = NewName
                    ,wfs.Alias = NewAlias
                    ,wfs.MFWorkflowID = wfs.MFWorkflowID
                    ,wfs.ModifiedOn = getdate()
                    ,wfs.Deleted = 0
                    FROM    MFWorkflowState wfs
                            INNER JOIN #TempMFWorkflowState as tmws
                            on  wfs.MFID = tmws.MFID 
							
                            where isnull(@IsUpdate,0) = 0 and isnull(tmws.IsUpdate,0) = 0 and tmws.status = 'Changed';

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
 set @ProcedureStep = 'Delete workflow states'
 
 ;with cte as
   (
            select  MFID
           
            FROM   #TempMFWorkflowState as tmws
            where status = 'Deleted' 
)
update wfs
set wfs.Deleted = 1, wfs.ModifiedOn = getdate()
from dbo.MFWorkflowState wfs
where mfid in (select mfid from cte)

                 SELECT  @DeleteRow = @@ROWCOUNT;
                

              set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@DeleteRow);
            end;
       

     set @ProcedureStep = ' workflow states updated'

     set @msg = ' New ' + cast(isnull(@InsertRow,0) as varchar(10)) + ' Updated ' + cast(isnull(@UpdateRow,0) as varchar(10)) + ' Deleted ' + cast(isnull(@DeleteRow,0) as varchar(10)) + ''
  
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
 

        if (@IsUpdate = 1)
        begin
            set @ProcedureStep = N'Update workflow and states';

              set @DebugText = N' %s';
            set @DebugText = @DefaultDebugText + @DebugText;


            declare @WorkFlowStateXML nvarchar(max);
            set @WorkFlowStateXML =
            (
                select isnull(TMFWFS.ID, 0)           as [WorkFlowStateDetails/@ID]
                     , isnull(TMFWFS.Name, '')        as [WorkFlowStateDetails/@Name]
                     , isnull(TMFWFS.Alias, '')       as [WorkFlowStateDetails/@Alias]
                     , isnull(TMFWFS.MFID, 0)         as [WorkFlowStateDetails/@MFID]
                     , isnull(TMFWFS.WorkflowMFID, 0) as [WorkFlowStateDetails/@MFWorkflowID]
                from dbo.MFWorkflowState            as MFWFS
                    inner join #TempMFWorkflowState as TMFWFS
                        on MFWFS.MFID = TMFWFS.MFID
                        and TMFWFS.IsUpdate = 1                                                   
                for xml path(''), root('WorkFlowState')
            );

            if @debug > 0
        select cast(@WorkFlowStateXML as xml) as 'Workflowstates for update to MF';

            if @WorkFlowStateXML is not null
            Begin
            declare @Outpout1 nvarchar(max);
            exec dbo.spMFUpdateWorkFlowState @VaultSettings
                                           , @WorkFlowStateXML
                                           , @Outpout1 out;

            set @ProcedureStep = N'Update MFWorkflowstate with results';


              set @msg = ' New ' + cast(isnull(@InsertRow,0) as varchar(10)) + ' Updated ' + cast(isnull(@UpdateRow,0) as varchar(10)) + ' Deleted ' + cast(isnull(@DeleteRow,0) as varchar(10)) + ' Include Updates to MF'

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;
       
       end
           
        end;

            if @debug > 10
            begin
                SELECT 'After update',*
                FROM   #TempMFWorkflowState temp
                left join dbo.MFWorkflowState as mws
                on temp.mfid = mws.mfid
                END;

        drop table #TempMFWorkflowState;

        set @out = @msg



        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        set @ProcedureStep = N'End';
        set @LogStatus = N'Completed';

        exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                       , @ProcessType = @ProcessType
                                       , @LogType = N'Message'
                                       , @LogText = @msg
                                       , @LogStatus = @LogStatus
                                       , @debug = @Debug;

        set @StartTime = getutcdate();


        set @LogTypeDetail = N'Status';
        set @LogStatusDetail = N'Completed';
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

