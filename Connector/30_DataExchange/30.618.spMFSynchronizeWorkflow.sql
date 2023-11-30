PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeWorkflow]';
GO
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeWorkflow', -- nvarchar(100)
    @Object_Release = '4.10.32.77', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeWorkflow'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkflow]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFSynchronizeWorkflow]
    (
      @VaultSettings [NVARCHAR](4000) ,
      @Out [NVARCHAR](MAX) OUTPUT,
	  @IsUpdate SMALLINT=0,
            @Debug SMALLINT ,
            @processBatch_ID int = null output
    )
AS
/*rST**************************************************************************

=======================
spMFSynchronizeWorkflow
=======================

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

Procedure is used in other procedures

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-07-30  LC         Improve logging and productivity of procedure
2019-08-30  JC         Added documentation
2018-04-04  DevTeam2   Added License module validation code
2015-03-27  Dev        Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

    BEGIN
        SET NOCOUNT ON;

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
    declare @ProcedureName as nvarchar(128) = N'dbo.spMFSynchronizeWorkflows';
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

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
        DECLARE @Xml [NVARCHAR](MAX) ,
            @Output INT ,  @XMLReturn xml

              -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID 
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


      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET VALUE LIST DETAILS FROM M-FILES
      -------------------------------------------------------------

          -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------
 set @procedurestep = 'Insert current rows into temp'
 
 if (select object_id('tempdb..#WorkflowTable')) is not null
  drop table #WorkflowTable;

  create TABLE #WorkflowTable
                (
                 TempT_id int identity primary key,
           ID int ,
            Name nvarchar(100),
          NewName nvarchar(100),
           Alias nvarchar(100),
          NewAlias nvarchar(100),
          [MFID] INT NOT NULL 
           ,Status nvarchar(10)
          ,IsUpdate bit
          ,Deleted bit
                );
                
 insert into #WorkflowTable
        (
            ID
          , Name
          , Alias
          , MFID          
          ,Status
  --        ,IsUpdate
          ,Deleted
        )
        select MFWF.ID
             , MFWF.Name
             , MFWF.Alias
             , MFWF.MFID             
             ,'LastUpdate'
   --          ,mfwf.
             ,mfwf.Deleted
        from dbo.MFWorkflow      as MFWF           
        where MFWF.MFID != 0;


        EXEC spMFGetWorkFlow @VaultSettings,
            @Xml OUTPUT;

        SET @ProcedureStep = 'GetWorkflow Returned from wrapper';
	
          set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

              if @Debug > 0
            begin
                select cast( @Xml as xml);
            end;
      
   if isnull(@return_value, -1) <> 0
            begin


                set @DebugText = N' get workflow failed %s';
                set @DebugText = @DefaultDebugText + @DebugText;

                raiserror(@DebugText, 16, 1, @ProcedureName, @ProcedureStep, @Output);


            end;

   

                  -----------------------------------------------------
          --DECLARE LOCAL VARIABLES
          -----------------------------------------------------

             set   @XMLReturn = cast(@XML as xml)

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SET @ProcedureStep = 'Inserting wrapper into @WorkflowTable';

if @debug > 0
Begin
SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME,
                            'New'
                    FROM    @XMLReturn.nodes('/form/Workflow') AS t ( c )
                    left join #WorkflowTable as wt
                    on wt.mfid = t.c.value('(@MFID)[1]', 'INT') 
end

            INSERT  INTO #WorkflowTable
                    ( MFID ,
                      newAlias ,
                      NewName,
                      Status
                    )
                    SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME,
                            'New'
                    FROM    @XMLReturn.nodes('/form/Workflow') AS t ( c )
                    left join #WorkflowTable as wt
                    on wt.mfid = t.c.value('(@MFID)[1]', 'INT') 
                    where wt.MFID is null;


  update temp
                    set 
                    temp.newname = t.c.value('(@Name)[1]', 'NVARCHAR(100)')  ,
                     newalias =  t.c.value('(@Alias)[1]', 'NVARCHAR(100)') ,
                    status = 'Updated'

                    from #WorkflowTable temp
                    left join    @XMLReturn.nodes('/form/Workflow') AS t ( c )
                    on temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     where temp.MFID =  t.c.value('(@MFID)[1]', 'INT') 
                     and Status <> 'New'


update tmws
set Status = 'Deleted'
from #WorkflowTable as tmws
where tmws.NewName is null and tmws.Name is not null 

if @debug > 0
select * from #WorkflowTable as wt;

     set @DebugText = N' ';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

                   if @debug > 10
            begin
                SELECT 'before update',*
                FROM   #WorkflowTable temp
                left join dbo.MFWorkflow as mws
                on temp.mfid = mws.mfid
                end
                

          -----------------------------------------------------
          --Updating MFworkflow
          -----------------------------------------------------
declare @InsertRow int, @UpdateRow int, @DeleteRow int

           SELECT  @ProcedureStep = 'New workflow';

  INSERT  INTO MFWorkflow
                    (
                      MFID ,
                      Name ,
                      Alias ,
                      Deleted,
					  CreatedOn  
                    )
                    SELECT  
                            tmws.MFID ,
                            tmws.newName ,
                            tmws.newAlias ,
                            0 ,
							getdate() -- Added for task 568
                    FROM    #WorkflowTable as tmws                    
                    where tmws.status = 'New';

            SELECT  @InsertRow = @@ROWCOUNT;

            set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@InsertRow);
            end;

           SELECT  @ProcedureStep = 'Update workflow ';

				    UPDATE  wfs
                    SET 
                    wfs.Name = NewName
                    ,wfs.Alias = NewAlias
                    ,wfs.ModifiedOn = getdate()
                    ,wfs.Deleted = 0
                    FROM    MFWorkflow wfs
                            INNER JOIN #WorkflowTable as tmws
                            on  wfs.MFID = tmws.MFID 
							
                            where tmws.status = 'Updated';

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
 set @ProcedureStep = 'Delete workflow'
 
 ;with cte as
   (
            select  MFID
           
            FROM   #WorkflowTable as tmws
            where status = 'Deleted' 
)
update wfs
set wfs.Deleted = 1, wfs.ModifiedOn = getdate()
from dbo.MFWorkflow wfs
where mfid in (select mfid from cte)

                 SELECT  @DeleteRow = @@ROWCOUNT;
                

              set @DebugText = N' count %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@DeleteRow);
            end;
       

     set @ProcedureStep = ' workflow updated'

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
 

      
	  --  if @IsUpdate=1
		 --Begin
		
			--Declare @WorkflowXml nvarchar(max)
			--set @WorkflowXml=( Select 
			--   isnull(TMWF.ID,0) as 'WorkFlowDetails/@ID'
			--  ,isnull(TMWF.Name,0) as 'WorkFlowDetails/@Name'
			--  ,isnull(TMWF.Alias,0) as 'WorkFlowDetails/@Alias'
			--  ,isnull(TMWF.MFID ,0) as 'WorkFlowDetails/@MFID'
			-- from MFWorkflow MWF inner join #WorkflowTable TMWF 
			-- on MWF.MFID=TMWF.MFID and (MWF.Alias!=TMWF.Alias or MWF.Name=TMWF.Name) 
             
   --          for Xml Path(''),Root('WorkFlow'))
			


			-- Declare @OutPut1 nvarchar(max)	
			-- exec spMFUpdateWorkFlow @VaultSettings,@WorkflowXml,@OutPut1

			-- Update  
			--  MWF
   --          set
			--  MWF.Name=TMWF.Name,
			--  MWF.Alias=TMWF.Alias
			-- from 
			--  MFWorkflow MWF inner join #TempMFWorkflow TMWF 
			-- on 
			--  MWF.MFID=TMWF.MFID 

		 --End

         
            if @debug > 10
            begin
                SELECT 'After update',*
                FROM   #WorkflowTable temp
                left join dbo.MFWorkflow as mws
                on temp.mfid = mws.mfid
                END;
          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #WorkflowTable;

             SET NOCOUNT OFF;

            SET @Out = @msg;
       
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
end
go


  