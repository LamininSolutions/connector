print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFSynchronizeSpecificMetadata]';
go


set nocount on;
exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFSynchronizeSpecificMetadata'
                               -- nvarchar(100)
                               , @Object_Release = '4.10.32.77'
                               -- varchar(50)
                               , @UpdateFlag = 2;
-- smallint

go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFSynchronizeSpecificMetadata' --name of procedure
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
create procedure dbo.spMFSynchronizeSpecificMetadata
as
select 'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFSynchronizeSpecificMetadata
(
    @Metadata varchar(100)
  , @IsUpdate smallint = 0
  , @ItemName varchar(100) = null
  , @Debug smallint = 0
)
as
/*rST**************************************************************************

===============================
spMFSynchronizeSpecificMetadata
===============================

Return
  - 1 = Success
  - -1 = Error
  
Parameters
  @Metadata varchar(100)
    type of metadata from list below
  @IsUpdate smallint
    default = 0
    if set to 1 the procedure will update from SQL to M-Files
  @ItemName varchar(100)
    default = null
    only applicable for valuelistitems.  Use name of valuelist to synchronise a specific valuelist
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure will synchronise the metadata for one of the following

- Properties
- Valuelist
- Valuelistitems
- Workflow
- States
- ObjectType
- LoginAccount
- UserAccount

Using the @ItemName parameter for the specifying a valuelist name, the valuelists items for a specific valuelist can be updated; similarly, by using the workflow name the workflow states for a specific workflow can be updated

Setting the @IsUpdate parameter to 1 will allow for the updating of the name from SQL to M-Files.

Additional Info
===============

This procedure is particularly useful when a small change was made in the vault that need to be pulled through.  

When changes are made to classes it is very important to perform all the dependent specific synchronizations before doing the class synchronization.

WHEN using the @Metadata parameter, only partial names can be used. 
 - use 'Proper' for 'Properties'
 - use 'Valuelist' for'Valuelist'
 - use 'Item' for'Valuelistitems'
 - use 'Workflow' for'Workflow'
 - use 'Stat' for'States'
 - use 'Object' for'ObjectType'
 - use 'Login' for'LoginAccount'
 - use 'User' for'UserAccount'

The @Update parameter is used for making a change to the name for the following objects.  A separate routine is used to make a change to valuelist items.  This update only include changing an existing item and cannot add new rows for these objects.

- Properties
- Valuelist
- Workflow
- States
- ObjectType
- LoginAccount
- UserAccount

Refer to :doc:`/procedures/spMFSynchronizeValueListItemsToMfiles/` for updating valuelist items

Examples
========

.. code:: sql

   EXEC [spMFSynchronizeSpecificMetadata] 'Class'; 

.. code:: sql

    EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'User', --  ObjectType; Class; Property; Valuelist; ValuelistItem; Workflow; State; User; Login
    @IsUpdate = 0,  -- set to 1 to push updates to M-Files
    @ItemName = NULL , --only application for valuelists, and workflow states by workflow
    @Debug = 0

------

Only update value list items for a specific valuelist

.. code:: sql

    EXEC [dbo].[spMFSynchronizeSpecificMetadata] 
    @Metadata = 'Valuelist'	-- to set this for Valuelists
    ,@ItemName = 'Country'	-- use any valuelist name to update only the valuelist items for the selected item

-----

Review the tables with the metadata

.. code:: sql

    SELECT TOP 100 * FROM [dbo].[MFProperty] as [mp]
    SELECT TOP 100 * FROM [dbo].[MFClass] as [mc]
    SELECT TOP 100 * FROM [dbo].[MFValueList] as [mvl]
    SELECT TOP 100 * FROM [dbo].[MFValueListItems] as [mvli]
    SELECT TOP 100 * FROM [dbo].[MFWorkflow] as [mw]
    SELECT TOP 100 * FROM [dbo].[MFWorkflowState] as [mws]
    SELECT TOP 100 * FROM [dbo].[MFObjectType] as [mot]
    SELECT TOP 100 * FROM [dbo].[MFUserAccount] as [mua]
    SELECT TOP 100 * FROM [dbo].[MFLoginAccount] as [mla]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-07-30  LC         Improve logging and productivity of procedure
2019-08-30  JC         Added documentation
2016-08-22  LC         Update settings index
2016-09-09  LC         Add login accounts and user accounts
2016-09-09  LC         provide for slight differences in metadata parameter
2016-09-26  DevTeam2   Removed vault settings parameters 
2016-12-08  LC         Add update as parameter
2015-04-08  Dev1       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

begin


    ---------------------------------------------
    --DECLARE LOCAL VARIABLE
    --------------------------------------------- 
    declare @VaultSettings nvarchar(4000)
          , @ProcedureStep sysname = 'START'
          , @MFvaluelistID int     = 0;

    ---------------------------------------------
    -- ACCESS CREDENTIALS FROM Setting TABLE
    ---------------------------------------------

    select @VaultSettings = dbo.FnMFVaultSettings();


    set @Metadata = case
                        when @Metadata like 'Class%' then
                            'Class'
                        when @Metadata like 'Proper%' then
                            'Properties'
                        when @Metadata like 'Valuelist' then
                            'Valuelist'
                        when @Metadata like '%Item%' then
                            'Valuelistitems'
                        when @Metadata like 'Valuelist%' then
                            'Valuelist'
                        when @Metadata like 'Workflow' then
                            'Workflow'
                        when @Metadata like '%Stat%' then
                            'States'
                        when @Metadata like 'Object%' then
                            'ObjectType'
                        when @Metadata like 'Login%' then
                            'LoginAccount'
                        when @Metadata like 'User%' then
                            'UserAccount'
                        else
                            null
                    end;

    begin
        begin try
            -- BEGIN TRANSACTION;
            ---------------------------------------------
            --DECLARE LOCAL VARIABLE
            --------------------------------------------- 
            declare @ResponseMFObject       nvarchar(2000)
                  , @ResponseProperties     nvarchar(2000)
                  , @ResponseValueList      nvarchar(2000)
                  , @ResponseValuelistItems nvarchar(2000)
                  , @ResponseWorkflow       nvarchar(2000)
                  , @ResponseWorkflowStates nvarchar(2000)
                  , @ResponseMFClass        nvarchar(2000)
                  , @ResponseLoginAccount   nvarchar(2000)
                  , @ResponseuserAccount    nvarchar(2000)
                  , @Response               nvarchar(2000)
                  , @SPName                 nvarchar(100)
                  , @Return_Value           int;

            if @Metadata = 'ObjectType'
            begin
                ---------------------------------------------
                --SYNCHRONIZE OBJECT TYPES
                ---------------------------------------------
                select @ProcedureStep = 'Synchronizing ObjectType'
                     , @SPName        = N'spMFSynchronizeObjectType';

                execute @Return_Value = dbo.spMFSynchronizeObjectType @VaultSettings
                                                                    , @Debug
                                                                    , @ResponseMFObject output
                                                                    , @IsUpdate;
            end;

            if @Metadata = 'LoginAccount'
            begin
                ---------------------------------------------
                --SYNCHRONIZE login accounts
                ---------------------------------------------
                select @ProcedureStep = 'Synchronizing Login Accoount'
                     , @SPName        = N'spMFSynchronizeLoginAccounte';

                execute @Return_Value = dbo.spMFSynchronizeLoginAccount @VaultSettings
                                                                      , @Debug
                                                                      , @ResponseLoginAccount output;
            end;


            if @Metadata = 'UserAccount'
            begin
                ---------------------------------------------
                --SYNCHRONIZEuser accounts
                ---------------------------------------------
                select @ProcedureStep = 'Synchronizing UserAccount'
                     , @SPName        = N'spMFSynchronizeUserAccount';

                execute @Return_Value = dbo.spMFSynchronizeUserAccount @VaultSettings
                                                                     , @Debug
                                                                     , @ResponseMFObject output;
            end;


            ---------------------------------------------
            --SYNCHRONIZE PROEPRTY
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Properties'
                 , @SPName        = N'spMFSynchronizeProperties';

            if @Metadata = 'Properties'
            begin
                execute @Return_Value = dbo.spMFSynchronizeProperties @VaultSettings
                                                                    , @Debug
                                                                    , @ResponseProperties output
                                                                    , @IsUpdate;
            end;

            ---------------------------------------------
            --SYNCHRONIZE VALUE LIST
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing ValueList'
                 , @SPName        = N'spMFSynchronizeValueList';

            if @Metadata = 'ValueList'
            begin
                execute @Return_Value = dbo.spMFSynchronizeValueList @VaultSettings
                                                                   , @Debug
                                                                   , @ResponseValueList output
                                                                   , @IsUpdate;
            end;

            ---------------------------------------------
            --SYNCHRONIZE VALUELIST ITEMS
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing ValueList Items'
                 , @SPName        = N'spMFSynchronizeValueListItems';

            if @Metadata = 'ValueListItems'
            begin
                --print @Metadata


                if @ItemName is not null
                begin
                    select @MFvaluelistID = isnull(ID, 0)
                    from dbo.MFValueList
                    where Name = @ItemName;

                end;
                --print @ItemName 
                --print @MFvaluelistID

                execute @Return_Value = dbo.spMFSynchronizeValueListItems @VaultSettings                                                                        
                                                                        , @ResponseValuelistItems output
                                                                        , @MFvaluelistID
                                                                        , @Debug;                                                                          

            end;

            ---------------------------------------------
            --SYNCHRONIZE WORKFLOW
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing workflow'
                 , @SPName        = N'spMFSynchronizeWorkflow';

            if @Metadata = 'Workflow'
            begin
                execute @Return_Value = dbo.spMFSynchronizeWorkflow @VaultSettings = @VaultSettings
                                                                  , @Out = @ResponseWorkflow output
                                                                  , @IsUpdate = @IsUpdate
                                                                  , @Debug = @Debug
                                                                  ;

            end;

            ---------------------------------------------
            --SYNCHRONIZE WORKFLOW STATES
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Workflow states'
                 , @SPName        = N'spMFSynchronizeWorkflowsStates';

            if @Metadata like '%State%'
            begin
                execute @Return_Value = dbo.spMFSynchronizeWorkflowsStates @VaultSettings = @VaultSettings
                                                                         , @Out = @ResponseWorkflowStates output
                                                                         , @itemname = @ItemName
                                                                         , @IsUpdate = @IsUpdate
                                                                         , @Debug = @Debug;


            end;

            ---------------------------------------------
            --SYNCHRONIZE Class
            ---------------------------------------------
            select @ProcedureStep = 'Synchronizing Class'
                 , @SPName        = N'spMFSynchronizeClasses';

            if @Metadata = 'Class'
            begin
                execute @Return_Value = dbo.spMFSynchronizeClasses @VaultSettings
                                                                 , @Debug
                                                                 , @ResponseMFClass output
                                                                 , @IsUpdate;

            --IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NULL )
            --                BEGIN

            --                    ALTER TABLE [dbo].[MFClassProperty]
            --                    WITH CHECK  ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass]([ID]);

            --                END;

            end;

            declare @ProcessStep varchar(100);
            select @ProcessStep = 'END Syncronise specific metadata';


            if @Debug > 0
            begin
                raiserror('Step %s Return %i', 10, 1, @ProcessStep, @Return_Value);
            end;


            if @Metadata = null
            begin
                print 'Invalid Selection';
                return -1;
            end;
            else
                return 1;
            set nocount off;
        --COMMIT TRANSACTION;
        end try
        begin catch
            --				ROLLBACK TRANSACTION;

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

            return 2;
        end catch;
    end;
end;

go
