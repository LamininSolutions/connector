
go

print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFSynchronizeMetadata]';
go

/*------------------------------------------------------------------------------------------------
	Author: Thejus T V
	Create date: 27-03-2015
    Desc:  The purpose of this procedure is to synchronize M-File Meta data  
															
------------------------------------------------------------------------------------------------*/


set nocount on;
exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFSynchronizeMetadata'
-- nvarchar(100)
                               , @Object_Release = '4.11.33.77'
-- varchar(50)
                               , @UpdateFlag = 2;
-- smallint

go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFSynchronizeMetadata' --name of procedure
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
create procedure dbo.spMFSynchronizeMetadata
as
select 'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
set noexec off;
go


alter procedure dbo.spMFSynchronizeMetadata
    @ProcessBatch_ID int = null output
  , @Debug smallint = 0
as

/*rST**************************************************************************

=======================
spMFSynchronizeMetadata
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======
To pull M-Files Metadata during initialisation of MFSQL Connector

Prerequisites
=============
Vault connection is valid

Warnings
========
Custom settings in the metadata structure tables such as tablename and columnname will not be retained

Examples
========

.. code:: sql

    EXEC [dbo].[spMFSynchronizeMetadata]

----

.. code:: sql

    DECLARE @return_value int
    EXEC    @return_value = [dbo].[spMFSynchronizeMetadata]
            @Debug = 0
    SELECT  'Return Value' = @return_value
    GO

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-07-30  LC         Improve logging and productivity of procedure
2018-11-15  LC         Fix processbatch_ID logging
2018-07-25  LC         Auto create MFUserMessages
2018-04-30  LC         Add to MFUserMessage
2017-08-22  LC         Improve logging
2017-08-22  LC         Change processBatch_ID to output param
2016-09-26  DEV2       Removed Vaultsettings parametes and pass them as comma separated string in @VaultSettings parameter
2016-08-22  LC         Change settings index
2015-05-25  DEV2       UserAccount and Login account is added
==========  =========  ========================================================

**rST*************************************************************************/

begin
    set nocount on;

    ---------------------------------------------
    --DECLARE LOCAL VARIABLE
    --------------------------------------------- 
    declare @VaultSettings nvarchar(4000)
          , @ProcedureStep sysname = 'START';


    declare @RC int;
    declare @ProcessType nvarchar(50) = N'Metadata Sync';
    declare @LogType nvarchar(50);
    declare @LogText nvarchar(4000);
    declare @LogStatus nvarchar(50);
    declare @ProcedureName varchar(100) = 'spMFSynchronizeMetadata';
    declare @MFTableName nvarchar(128);
    declare @Update_ID int;
    declare @LogProcedureName nvarchar(128);
    declare @LogProcedureStep nvarchar(128);

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
    select @VaultSettings = dbo.FnMFVaultSettings();


    begin

        set @ProcessType = @ProcedureName;
        set @LogType = N'Status';
        set @LogText = @ProcedureStep + N' | ';
        set @LogStatus = N'Initiate';


        execute @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                                , @ProcessType = @ProcessType
                                                , @LogType = @LogType
                                                , @LogText = @LogText
                                                , @LogStatus = @LogStatus
                                                , @debug = @Debug;


        begin try
            ---------------------------------------------
            --DECLARE LOCAL VARIABLE
            --------------------------------------------- 
            declare @ResponseMFObject       nvarchar(2000)
                  , @ResponseProperties     nvarchar(2000)
                  , @ResponseValueList      nvarchar(2000)
                  , @ResponseValuelistItems nvarchar(2000)
                  , @ResponseWorkflow       nvarchar(2000)
                  , @ResponseWorkflowStates nvarchar(2000)
                  , @ResponseLoginAccount   nvarchar(2000)
                  , @ResponseUserAccount    nvarchar(2000)
                  , @ResponseMFClass        nvarchar(2000)
                  , @Response               nvarchar(2000)
                  , @SPName                 nvarchar(100);
            ---------------------------------------------
            --SYNCHRONIZE Login Accounts
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Login Accounts'
                 , @SPName        = N'spMFSynchronizeLoginAccount';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeLoginAccount @VaultSettings
                                                                  , @Debug
                                                                  , @ResponseLoginAccount output;

            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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


            ---------------------------------------------
            --SYNCHRONIZE Login Accounts
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing User Accounts'
                 , @SPName        = N'spMFSynchronizeUserAccount';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeUserAccount @VaultSettings
                                                                 , @Debug
                                                                 , @ResponseUserAccount output;

            set @StartTime = getutcdate();


            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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
            ---------------------------------------------
            --SYNCHRONIZE OBJECT TYPES
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing ObjectType'
                 , @SPName        = N'spMFSynchronizeObjectType';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeObjectType @VaultSettings
                                                                , @Debug
                                                                , @ResponseMFObject output;

            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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

            ---------------------------------------------
            --SYNCHRONIZE VALUE LIST
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing ValueList'
                 , @SPName        = N'spMFSynchronizeValueList';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeValueList @VaultSettings
                                                               , @Debug
                                                               , @ResponseValueList output;

            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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


            ---------------------------------------------
            --SYNCHRONIZE VALUELIST ITEMS
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing ValueList Items'
                 , @SPName        = N'spMFSynchronizeValueListItems';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
            

                execute @Return_Value = dbo.spMFSynchronizeValueListItems @VaultSettings                                                                        
                                                                        , @ResponseValuelistItems output
                                                                        , 0
                                                                        , @Debug
                                                                        ,@ProcessBatch_ID = @ProcessBatch_ID;                                                                          
        

            set @StartTime = getutcdate();

            --set @LogTypeDetail = N'Message';
            --set @LogTextDetail = @SPName;
            --set @LogStatusDetail = N'Completed';
            --set @Validation_ID = null;
            --set @LogColumnValue = N'';
            --set @LogColumnValue = N'';

            --execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
            --                                              , @LogType = @LogTypeDetail
            --                                              , @LogText = @LogTextDetail
            --                                              , @LogStatus = @LogStatusDetail
            --                                              , @StartTime = @StartTime
            --                                              , @MFTableName = @MFTableName
            --                                              , @Validation_ID = @Validation_ID
            --                                              , @ColumnName = @LogColumnName
            --                                              , @ColumnValue = @LogColumnValue
            --                                              , @Update_ID = @Update_ID
            --                                              , @LogProcedureName = @ProcedureName
            --                                              , @LogProcedureStep = @ProcedureStep
            --                                              , @debug = @Debug;



            ---------------------------------------------
            --SYNCHRONIZE WORKFLOW
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing workflow'
                 , @SPName        = N'spMFSynchronizeWorkflow';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);


                execute @Return_Value = dbo.spMFSynchronizeWorkflow @VaultSettings = @VaultSettings
                                                                  , @Out = @ResponseWorkflow output
                                                                  , @IsUpdate = 0
                                                                  , @Debug = @Debug
                                                                  ,@ProcessBatch_ID = @ProcessBatch_ID
                                                                  ;


            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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


            ---------------------------------------------
            --SYNCHRONIZE WORKFLOW STATES
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Workflow states'
                 , @SPName        = N'spMFSynchronizeWorkflowsStates';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
            set @StartTime = getutcdate();

            exec dbo.spMFSynchronizeWorkflowsStates @VaultSettings = @VaultSettings
                                                  , @Out = @ResponseWorkflowStates output
                                                  , @Itemname = null
                                                  , @IsUpdate = 0
                                                  , @Debug = @Debug
                                                  , @ProcessBatch_ID = @ProcessBatch_ID;


            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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
            ---------------------------------------------
            --SYNCHRONIZE PROEPRTY
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Properties'
                 , @SPName        = N'spMFSynchronizeProperties';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeProperties @VaultSettings
                                                                , @Debug
                                                                , @ResponseProperties output;

            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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

            ---------------------------------------------
            --SYNCHRONIZE Class
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Class'
                 , @SPName        = N'spMFSynchronizeClasses';

            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            execute @return_value = dbo.spMFSynchronizeClasses @VaultSettings
                                                             , @Debug
                                                             , @ResponseMFClass output;
            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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



            -------------------------------------------------------------
            -- Create MFUSerMessage Table
            -------------------------------------------------------------


            if not exists
            (
                select name
                from sys.tables
                where name = 'MFUserMessages'
                      and schema_name(schema_id) = 'dbo'
            )
            begin

                exec dbo.spMFCreateTable @ClassName = 'User Messages' -- nvarchar(128)
                                       , @Debug = 0;                  -- smallint


            end;




            set @StartTime = getutcdate();

            set @LogTypeDetail = N'Message';
            set @LogTextDetail = @SPName;
            set @LogStatusDetail = N'Completed';
            set @Validation_ID = null;
            set @LogColumnValue = N'';
            set @LogColumnValue = N'';

            execute @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
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


            set @LogText = N'Processing ' + @ProcedureName + N' completed';
            set @LogStatus = N'Completed';

            execute @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                                    , @ProcessType = @ProcessType
                                                    , @LogType = @LogType
                                                    , @LogText = @LogText
                                                    , @LogStatus = @LogStatus
                                                    , @debug = @Debug;

            select @ProcedureStep = 'Synchronizing metadata completed';
            if @Debug > 9
                raiserror('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            return 1;
        end try
        begin catch
            set nocount on;

            set @error = @@error;
            set @LogStatusDetail = case
                                       when
                                       (
                                           @error <> 0
                                           or @return_value = -1
                                       ) then
                                           'Failed'
                                       when @return_value in ( 1, 0 ) then
                                           'Complete'
                                       else
                                           'Exception'
                                   end;

            set @LogTextDetail = @ProcedureStep + N' | Return Value: ' + cast(@return_value as nvarchar(256));
            set @LogColumnName = N'';
            set @LogColumnValue = N'';
            set @StartTime = getutcdate();

            exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                                 , @LogType = 'System'
                                                 , @LogText = @LogTextDetail
                                                 , @LogStatus = @LogStatusDetail
                                                 , @StartTime = @StartTime
                                                 , @MFTableName = @MFTableName
                                                 , @ColumnName = @LogColumnName
                                                 , @ColumnValue = @LogColumnValue
                                                 , @LogProcedureName = @ProcedureName
                                                 , @LogProcedureStep = @ProcedureStep
                                                 , @debug = @Debug;

            set @LogStatusDetail = null;
            set @LogTextDetail = null;
            set @LogColumnName = null;
            set @LogColumnValue = null;
            set @error = null;


            execute @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                                    , @ProcessType = @ProcessType
                                                    , @LogType = @LogType
                                                    , @LogText = @LogText
                                                    , @LogStatus = @LogStatus
                                                    , @debug = @Debug;

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
            (@SPName, @ProcedureStep, error_number(), error_message(), error_procedure(), error_state()
           , error_severity(), error_line());

            set nocount off;

            return -1;
        end catch;
    end;
end;


go
