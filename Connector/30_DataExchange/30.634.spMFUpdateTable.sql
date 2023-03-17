
go

print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFUpdateTable]';
go

set nocount on;

exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFUpdateTable'
                               -- nvarchar(100)
                               , @Object_Release = '4.10.30.75'
                               -- varchar(50)
                               , @UpdateFlag = 2;
-- smallint
go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFUpdateTable' --name of procedure
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
create procedure dbo.spMFUpdateTable
as
select 'created, but not implemented yet.';
--just anything will do
go

-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFUpdateTable
(
    @MFTableName nvarchar(200)
  , @UpdateMethod int               --0=Update from SQL to MF only; 
                                    --1=Update new records from MF; 
                                    --2=initialisation 
  , @UserId nvarchar(200) = null    --null for all user update
  , @MFModifiedDate datetime = null --NULL to select all records
  , @ObjIDs nvarchar(max) = null
  , @Update_IDOut int = null output
  , @ProcessBatch_ID int = null output
  , @SyncErrorFlag bit = 0          -- note this parameter is auto set by the operation 
  , @RetainDeletions bit = 0        --   @UpdateMetadata BIT = 0
  , @IsDocumentCollection bit = 0   -- =1 will process only document collections for the class
  , @Debug smallint = 0
)
as

/*rST**************************************************************************

===============
spMFUpdateTable
===============

Return
  - 1 = Success
  - 0 = Partial (some records failed to be inserted)
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Updatemethod
    - 0 = update from SQL to M-Files
    - 1 = update from M-Files to SQL
  @User_ID (optional)
    - Default = 0
    - User_Id from MX_User_Id column
    - This is NOT the M-Files user.  It is used to set and apply a user_id for a third party system. An example is where updates from a third party system must be filtered by the third party user (e.g. placing an order)
  @MFLastModified (optional)
    - Default = 0
    - Get objects from M-Files that has been modified in M-files later than this date.
  @ObjIDs (optional)
    - Default = null
    - ObjID's of records (separated by comma) e.g. : '10005,13203'
    - Restricted to 4000 charactes including the commas
  @Update_IDOut (optional, output)
    Output id of the record in MFUpdateHistory logging the update ; Also added to the record in the Update_ID column on the class table
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @SyncErrorFlag (optional)
    - Default = 0
    - This parameter is automatically set by spMFUpdateSynchronizeError when synchronization routine is called.
  @RetainDeletions (optional)
    - Default = 0
    - Set to 1 to keep deleted items in M-Files in the SQL table shown as "deleted" or the label of property 27 with the date time of the deletion.
  @IsDocumentCollection (optional)
    - Default = 0 (use default object type for the class)
    - Set to 1 to process objects with object type 9 (document collection) for the class.
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

This procedure get and push data between M-Files and SQL based on a number of filters.  It is very likely that this procedure will be built into your application or own procedures as part of the process of creating, updating, inserting records from your application.

When calling this procedure in a query or via another procedure it will perform the update in batch mode on all the rows with a valid process_id.

When the requirements for transactional mode has been met and a record is updated/inserted in the class table with process_id = 1, a trigger will automatically fire spMFUpdateTable to update SQL to M-Files.

A number of procedures is included in the Connector that use this procedure including:
- spMFUpdateMFilesToSQL
- spMFUpdateTablewithLastModifiedDate
- spMFUpdateTableinBatches
- spMFUpdateAllIncludedInAppTables
- spMFUpdateItembyItem

By default the object type of the class will get the object type from the MFclass Table (using the default object type of the class).  To process Document collection objects for the class, the @IsDocumentCollection must be set to 1.  

Prerequisites
=============

From M-Files to SQL
-------------------
Process_id in class table must be 0. All other rows are ignored.


From SQL to M-Files - batch mode
--------------------------------
Process_id in class table must be 1 for rows to be updated or added to M-Files. All other rows are ignored.

Warnings
========

When using a filter (e.g. for a single object) to update the table with Update method 1 and the filter object process_id is not 0 then the filter will automatically revert to updating all records. Take care to pass valid filters before passing them into the procedure call.

This procedure will not remove destroyed objects from the class table.  Use spMFUpdateMFilestoMFSQL identify and remove destroyed object.

This procedure will not remove objects from the class table where the class of the object was changed in M-Files.  Use spMFUpdateMFilestoMFSQL to identify and remove these objects from the class table.

When running this procedure without setting the objids parameter will not identify if a record was deleted in M-Files. To update deleted records, use spMFUpdateMFilestoMFSQL or set the objids for the records to be updated.

Deleted objects will only be removed if they are included in the filter 'Objids'.  Use spMFUpdateMFilestoMFSQL to identify deleted objects in general identify and update the deleted objects in the table.

Deleted objects in M-Files will automatically be removed from the class table unless @RetainDeletions is set to 1.

When the Retaindeletions flag are used, and a deleted object's deleted date is reset to null with the intent to undelete the object, it will not reset the deletions flag in M-Files for the object. Use the procedure spmfDeleteObject, or spMFDeleteObjectList to reset a deletions flag of an object.

The valid range of real datatype properties for uploading from SQL to M-Files is -1,79E27 and 1,79E27

Examples
========

.. code:: sql

    DECLARE @return_value int

    EXEC    @return_value = [dbo].[spMFUpdateTable]
            @MFTableName = N'MFCustomerContact',
            @UpdateMethod = 1,
            @UserId = NULL,
            @MFModifiedDate = null,
            @update_IDOut = null,
            @ObjIDs = NULL,
            @ProcessBatch_ID = null,
            @SyncErrorFlag = 0,
            @RetainDeletions = 0,
            @Debug = 0

    SELECT  'Return Value' = @return_value

    GO

Execute the core procedure with all parameters

----

.. code:: sql

    DECLARE @return_value int
    DECLARE @update_ID INT, @processBatchID int

    EXEC @return_value = [dbo].[spMFUpdateTable]
         @MFTableName = N'YourTableName', -- nvarchar(128)
         @UpdateMethod = 1, -- int
         @Update_IDOut = @update_ID output, -- int
         @ProcessBatch_ID = @processBatchID output

    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @processBatchID

    SELECT  'Return Value' = @return_value

Process document collection type objects for the class

----

.. code:: sql

    EXEC dbo.spMFUpdateTable @MFTableName = 'MFOtherDocument',
        @UpdateMethod = 1,
        @IsDocumentCollection = 1,
        @Debug = 101


Update from and to M-Files with all optional parameters set to default.

----

.. code:: sql

    --From M-Files to SQL
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 1
    --or
    EXEC spMFupdateTable 'MFCustomer',1

    --From SQL to M-Files
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 0
    --or
    EXEC spMFupdateTable 'MFCustomer',0

Update from and to M-Files with all optional parameters set to default.

Changelog
=========

==========  =========  =========================================================================
Date        Author     Description
----------  ---------  -------------------------------------------------------------------------
2023-03-08  LC         rework filter processing to improve throughput and reduce locks
2023-02-06  LC         Change create and modified date when new to UTC instead of local time
2022-11-18  LC         Change formatting of float to take account of culture
2022-09-02  LC         Add retain deletions to spMFUpdateSynchronizeError
2022-08-03  LC         Update sync precedence to resolve issue with not updating
2022-06-01  LC         Resolve bug with data definition in large text properties
2022-03-23  LC         Add protection against locking when updating class table
2022-03-07  LC         Fix bug with not updating AuditTable
2022-02-08  LC         Further optimize, replace UNPIVOT with new case method
2022-02-06  LC         allow null to be passed in for properties   
2022-01-28  lc         Remove table scan when updatemethod 0
2022-01-26  LC         Resolve bug related to audit table deletions removal
2021-12-20  LC         Pair connection test with Wrapper
2021-06-21  LC         Modify proc to include document collections
2021-04-14  LC         fix timestamp datatype bug
2021-03-15  LC         fix changing of class in the same object type in MF
2021-03-11  LC         update maximum valid number range to between -1,79E27 and 1,79E27
2021-01-31  LC         Fix bug on insert new into audithistory
2020-11-28  LC         Improve collection of property ids
2020-11-28  LC         Resolve issue when fail message
2020-11-24  LC         New functionality to deal with changing of classes
2020-10-20  LC         Fix locationlisation for class_id 
2020-09-21  LC         Change column name Value to avoid conflict with property
2020-08-25  LC         Fix debugging and log messaging
2020-08-27  LC         Rework logic to deal with deleted objects
2020-08-29  LC         Update treatment of required workflow errors
2020-08-22  LC         Replace boolean column Deleted with property 27
2020-07-27  LC         Add handling of delete and check out status
2020-06-13  LC         Remove xml_document when transaction failed
2020-05-12  LC         Set last modified user to MFSQL
2020-04-20  LC         exclude last modified and and MF user to be modified
2020-03-09  LC         Resolve issue with timestamp format for finish formatting
2020-02-27  LC         Resolve issue with open XML_Docs
2020-01-06  LC         Resolve issue: variable is null: @RetainDeletions
2020-01-06  LC         Resolving performance bug when filtering on objids  
2019-12-31	DEV2	   New output parameter add in spMFCreateObjectInternal to return the checkout objects.
2019-10-01  LC         Allow for rounding where float has long decimals
2019-09-02  LC         Fix conflict where class table has property with 'Name' as the name V53
2019-08-24  LC         Fix label of audithistory table inserts
2019-07-26  LC         Update removing of redundant items form AuditHistory
2019-07-13  LC         Add working that not all records have been updated
2019-06-17  LC         UPdate MFaudithistory with changes
2019-05-19  LC         Terminate early if connection cannot be established
2019-01-13  LC         Fix bug for uniqueidentifyer type columns (e.g. guid)
2019-01-03  LC         Fix bug for updating time property
2018-12-18  LC         Validate that all records have been updated, raise error if not
2018-12-06  LC         Fix bug t.objid not found
2018-11-05  LC         Include new parapameter to validate class and property structure
2018-10-30  LC         Removing cursor method for update method 0 and reducing update time by 100%
2018-10-24  LC         Resolve bug when objids filter is used with only one object
2018-10-20  LC         Set Deleted to != 1 instead of = 0 to ensure new records where deleted is not set is taken INSERT
2018-08-23  LC         Fix bug with presedence = 1
2018-08-01  LC         Fix deletions of record bug
2018-08-01  LC         New parameter @RetainDeletions to allow for auto removal of deletions Default = NO
2018-06-26  LC         Improve reporting of return values
2018-05-16  LC         Fix conversion of float to nvarchar
2018-04-04  DEV2       Added Licensing module validation code.
2017-11-03  DEV2       Added code to check required property has value or not
2017-10-01  LC         Fix bug with length of fields
2017-08-23  DEV2       Add exclude null properties from update
2017-08-22  DEV2       Add sync error correction
2017-07-06  LC         Add update of filecount column in class table
2017-07-03  LC         Modify objids filter to include ids not in sql
2017-06-22  LC         Add ability to modify external_id
2107-05-12  LC         Set processbatchdetail column detail
2016-10-10  LC         Change of name of settings table
2016-09-21  LC         Removed @UserName,@Password,@NetworkAddress and @VaultName parameters and fectch it as comma separated list in @VaultSettings parameter dbo.fnMFVaultSettings() function
2016-08-22  LC         Change objids to NVARCHAR(4000)
2016-08-22  LC         Update settings index
2016-08-20  LC         Add Update_ID as output paramter
2016-08-18  LC         Add defaults to parameters
2016-03-10  DEV2       New input variable added (@ObjIDs)
2016-03-10  DEV2       Input variable @FromCreateDate  changed to @MFModifiedDate
2016-02-22  LC         Improve debugging information; Remove is_template message when updatemethod = 1
2015-07-18  DEV2       New parameter add in spMFCreateObjectInternal
2015-06-30  DEV2       New error Tracing and Return Value as LeRoux instruction
2015-06-24  DEV2       Skip the object failed to update in M-Files
2015-04-23  DEV2       Removing Last modified & Last modified by from Update data
2015-04-16  DEV2       Adding update table details to MFUpdateHistory table
2015-04-08  DEV2       Deleting property value from M-Files (Task 57)
==========  =========  =========================================================================

**rST*************************************************************************/
declare @Update_ID    int
      , @return_value int = 1;

begin try
    --BEGIN TRANSACTION
    set nocount on;

    set xact_abort on;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    declare @Id                 int
          , @objID              int
          , @ObjectIdRef        int
          , @ObjVersion         int
          , @VaultSettings      nvarchar(4000)
          , @TableName          nvarchar(1000)
          , @XmlOUT             nvarchar(max)
          , @NewObjectXml       nvarchar(max)
          , @ObjIDsForUpdate    nvarchar(max)
          , @FullXml            xml
          , @SynchErrorObj      nvarchar(max) --Declared new paramater
          , @DeletedObjects     nvarchar(max) --Declared new paramater
          , @ProcedureName      sysname        = 'spMFUpdateTable'
          , @ProcedureStep      sysname        = 'Start'
          , @ObjectId           int
          , @ClassId            int
          , @Table_ID           int
          , @ErrorInfo          nvarchar(max)
          , @Query              nvarchar(max)
          , @Params             nvarchar(max)
          , @SynchErrCount      int
          , @ErrorInfoCount     int
          , @MFErrorUpdateQuery nvarchar(1500)
          , @MFIDs              nvarchar(4000) = N''
          , @ExternalID         nvarchar(200)
          , @Count              int
          , @ObjidCount         int            = 0
          , @CheckOutObjects    nvarchar(max)
          , @RemoveOtherClass   smallint       = 0
          , @TempStatusList     nvarchar(100);

    declare @process_ID int;
    declare @DeletedColumn nvarchar(100);
    declare @NameOrTitlename nvarchar(100);
    declare @lastModifiedColumn nvarchar(100);
    declare @ClassPropName nvarchar(100);
    declare @SelectQuery nvarchar(max); --query snippet to count records
    declare @vquery as nvarchar(max); --query snippet for filter
    declare @ParmDefinition nvarchar(500);
    declare @IsFullUpdate smallint = 0;
    -----------------------------------------------------
    --DECLARE VARIABLES FOR LOGGING
    -----------------------------------------------------
    declare @DefaultDebugText as nvarchar(256) = N'Proc: %s Step: %s';
    declare @DebugText as nvarchar(256) = N'';
    declare @LogTextDetail as nvarchar(max) = N'';
    declare @LogTextAccumulated as nvarchar(max) = N'';
    declare @LogStatusDetail as nvarchar(50) = null;
    declare @LogTypeDetail as nvarchar(50) = null;
    declare @LogColumnName as nvarchar(128) = null;
    declare @LogColumnValue as nvarchar(256) = null;
    declare @ProcessType nvarchar(50);
    declare @LogType as nvarchar(50) = N'Status';
    declare @LogText as nvarchar(4000) = N'';
    declare @LogStatus as nvarchar(50) = N'Started';
    declare @Status as nvarchar(128) = null;
    declare @Validation_ID int = null;
    declare @StartTime as datetime;
    declare @RunTime as decimal(18, 4) = 0;

    -----------------------------------------------------
    --GET LOGIN CREDENTIALS
    -----------------------------------------------------
    set @ProcedureStep = 'Get Security Variables';

    declare @Username nvarchar(2000);
    declare @VaultName nvarchar(2000);

    select top 1
           @Username  = Username
         , @VaultName = VaultName
    from dbo.MFVaultSettings;

    select @VaultSettings = dbo.FnMFVaultSettings();

    -------------------------------------------------------------
    -- set up temp table for status list
    -------------------------------------------------------------
    select @TempStatusList = dbo.fnMFVariableTableName('##StatusList', default);

    -------------------------------------------------------------
    -- Set process type
    -------------------------------------------------------------
    select @ProcessType = case
                              when @UpdateMethod = 0 then
                                  'UpdateMFiles'
                              else
                                  'UpdateSQL'
                          end;

    -------------------------------------------------------------
    --	Create Update_id for process start 
    -------------------------------------------------------------
    set @ProcedureStep = 'set Update_ID';
    set @StartTime = getutcdate();

    insert into dbo.MFUpdateHistory
    (
        Username
      , VaultName
      , UpdateMethod
    )
    values
    (@Username, @VaultName, @UpdateMethod);

    select @Update_ID = @@identity;

    select @Update_IDOut = @Update_ID;

    set @ProcedureStep = 'Start ';
    set @StartTime = getutcdate();
    set @ProcessType = @ProcedureName;
    set @LogType = N'Status';
    set @LogStatus = N'Started';
    set @LogText = N'Update using Update_ID: ' + cast(@Update_ID as varchar(10));

    if @Debug > 9
    begin
        raiserror(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    execute @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID output
                                                      , @ProcessType = @ProcessType
                                                      , @LogType = @LogType
                                                      , @LogText = @LogText
                                                      , @LogStatus = @LogStatus
                                                      , @debug = @Debug;

    if @Debug > 9
    begin
        set @DebugText = @DefaultDebugText + N' Update_ID %i';


        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_ID);
    end;

    -----------------------------------------------------------------
    -- Checking module access for CLR procdure  spMFCreateObjectInternal
    ------------------------------------------------------------------


    exec dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFCreateObjectInternal'
                                  , @ProcedureName = @ProcedureName
                                  , @ProcedureStep = @ProcedureStep
                                  , @ProcessBatch_id = @ProcessBatch_ID
                                  , @Debug = 0;


    select @process_ID = case
                             when @UpdateMethod = 0
                                  and @SyncErrorFlag = 1 then
                                 2
                             when @UpdateMethod = 0
                                  and isnull(@SyncErrorFlag, 0) = 0 then
                                 1
                             when @UpdateMethod = 1
                                  and isnull(@SyncErrorFlag, 0) = 0 then
                                 0
                             when @UpdateMethod = 1
                                  and isnull(@SyncErrorFlag, 0) = 1 then
                                 2
                             else
                                 0
                         end;

    -----------------------------------------------------
    --Convert @UserId to UNIQUEIDENTIFIER type
    -----------------------------------------------------
    set @UserId = convert(uniqueidentifier, @UserId);
    -----------------------------------------------------
    --Validate table 
    -----------------------------------------------------
    set @ProcedureStep = 'Get Table ID ';
    set @TableName = @MFTableName;

    select @Table_ID = object_id
    from sys.objects
    where name = @MFTableName;

    if @Table_ID is null
    begin
        set @DebugText = N' Class table ' + @MFTableName + N' does not exist';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'Table Exist?';

        raiserror(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    end;

    if @Debug > 0
    begin
        set @DebugText = @DefaultDebugText + N'Table: %s ';

        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
    end;

    -----------------------------------------------------
    --Set class id
    -----------------------------------------------------
    select @ClassId = MFID
    from dbo.MFClass
    where TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

    if @Debug > 0
    begin
        set @DebugText = @DefaultDebugText + N' Class: %i';

        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
    end;

    set @ProcedureStep = 'Prepare Table ';
    set @LogTypeDetail = N'Status';
    set @LogStatusDetail = N'Debug';
    set @LogTextDetail = N'For UpdateMethod ' + cast(@UpdateMethod as varchar(10));
    set @LogColumnName = N'UpdateMethod';
    set @LogColumnValue = cast(@UpdateMethod as varchar(10));

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

    -----------------------------------------------------
    --Get Object Type Id
    -----------------------------------------------------
    set @ProcedureStep = 'Get Object Type and Class ';

    select @ObjectIdRef = MFObjectType_ID
         , @ClassId     = MFID
    from dbo.MFClass
    where TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

    select @ObjectId = case
                           when @IsDocumentCollection = 1 then
                               9
                           else
                               MFID
                       end
    from dbo.MFObjectType
    where ID = @ObjectIdRef;

    if @Debug > 0
    begin
        set @DebugText = @DefaultDebugText + N' ObjectType: %i';

        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
    end;


    -------------------------------------------------------------
    -- Column variables
    -------------------------------------------------------------

    select @DeletedColumn = mp.ColumnName
    from dbo.MFProperty as mp
    where mp.MFID = 27;

    select @NameOrTitlename = ColumnName
    from dbo.MFProperty
    where MFID = 0;

    select @lastModifiedColumn = mp.ColumnName
    from dbo.MFProperty as mp
    where mp.MFID = 21; --'Last Modified'

    select @ClassPropName = mp.ColumnName
    from dbo.MFProperty as mp
    where mp.MFID = 100;



    -----------------------------------------------------
    --SELECT THE ROW DETAILS DEPENDS ON UPDATE METHOD INPUT
    -----------------------------------------------------
    set @StartTime = getutcdate();


    -------------------------------------------------------------
    -- Get objids for updating
    -------------------------------------------------------------
    set @ProcedureStep = 'Get objids into temp table ';
    if
    (
        select object_id('tempdb..#objidtable')
    ) is not null
        drop table #Objidtable;

    create table #ObjidTable
    (
        objid int primary key
      , SQLid int
      , Type int
      , Process_ID int
      , ClassID int
      , MFVersion int
      , GUID uniqueidentifier
      , name_or_title nvarchar(100)
    );

    /*
    Type 1 Unfiltered Update 
    Type 2 @objids is not null
    Type 3 @MFlastModified is not null
    type 1 and 2 will filter on @userid if not null
    type 3 only return objects later than last modified date.
    */

    declare @Queryfilter nvarchar(max);

    select @Queryfilter
        = case
              when @ObjIDs is not null then
                  N'
    select fmpds.objid, t.id, 2 , isnull(t.Process_ID,0), isnull(' + quotename(@ClassPropName)
                  + N',@Classid) ,isnull(t.MFVersion,-1), isnull(t.Guid,''{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}'')
    , isnull(t.' + quotename(@NameOrTitlename)
                  + ',''Auto'') 
    from  (select listitem as objid from dbo.fnMFParseDelimitedString(@objids,'',''))  fmpds    
    left join ' + quotename(@MFTableName)
                  + ' t
    on fmpds.objid = t.objid and (t.MX_User_ID = @UserID or @userid is null)
    '
              when @ObjIDs is null
                   and @MFModifiedDate is null then
                  N' select t.objid, t.id, 2 , isnull(t.Process_ID,0),isnull(' + quotename(@ClassPropName)
                  + N',@Classid) ,isnull(t.MFVersion,-1)
    , isnull(t.Guid,''{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}'')
    , isnull(t.'                  + quotename(@NameOrTitlename) + ',''Auto'') 
    from  '                       + quotename(@MFTableName)
                  + ' t
    where process_id = @process_ID  and (t.MX_User_ID = @UserID or @userid is null)'
              when @MFModifiedDate is not null then
                  N' select objid, id, 3,t.Process_ID, isnull(' + quotename(@ClassPropName)
                  + N',@Classid) ,t.MFVersion, t.Guid
    , '                           + @NameOrTitlename + '
    from  '                       + quotename(@MFTableName) + ' t
    where process_id = @process_ID'
          end;

    if @Debug > 0
        print @Queryfilter;
    insert into #ObjidTable
    (
        objid
      , SQLid
      , Type
      , Process_ID
      , ClassID
      , MFVersion
      , GUID
      , name_or_title
    )
    exec sys.sp_executesql @Queryfilter
                         , N'@ClassPropName nvarchar(100),@Objids nvarchar(4000), @ClassID int, @userID nvarchar(100), @process_ID int,@NameOrTitlename nvarchar(100)'
                         , @ClassPropName
                         , @ObjIDs
                         , @ClassId
                         , @UserId
                         , @process_ID
                         , @NameOrTitlename;

    select @ObjidCount = @@rowcount;

    set @DebugText = N'ObjectType %i Class %i update count %i';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId, @ClassId, @ObjidCount);
        select *
        from #ObjidTable as ot;
    end;

    -------------------------------------------------------------
    -- determine if full update is required
    -------------------------------------------------------------
    set @ProcedureStep = ' Full update ';
    select top 1
           @IsFullUpdate = ot.Type
    from #ObjidTable as ot
    group by ot.Type
    order by ot.Type;

    set @DebugText = N' %i';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @IsFullUpdate);
    end;

    -------------------------------------------------------------
    -- PROCESS UPDATEMETHOD = 0
    -------------------------------------------------------------
    set @ProcedureStep = 'process updatemethod 0';

    if @UpdateMethod = 0 --- processing of process_ID = 1
    begin

        -------------------------------------------------------------
        -- create filter query for update method 0
        -------------------------------------------------------------       
        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'filter snippet for Updatemethod 0';


        -------------------------------------------------------------
        -- is class change application
        -------------------------------------------------------------
        set @ProcedureStep = 'Get class change indicator';

        select @RemoveOtherClass = count(ClassID)
        from #ObjidTable
        where ClassID <> @ClassId;


        set @DebugText = N' %i';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemoveOtherClass);
        end;

        -------------------------------------------------------------
        -- log number of records to be updated
        -------------------------------------------------------------
        set @StartTime = getutcdate();
        set @DebugText = N'Count of records i%';
        set @DebugText = @DefaultDebugText + @DebugText;
        set @ProcedureStep = 'Start Processing UpdateMethod 0';

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjidCount);
        end;

        set @LogTypeDetail = N'Debug';
        set @LogTextDetail = N'Count filtered records ';
        set @LogStatusDetail = N'In Progress';
        set @Validation_ID = null;
        set @LogColumnName = N'process_ID';
        set @LogColumnValue = cast(isnull(@Count, 0) as nvarchar(256));

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






        --------------------------------------------------------------------------------------------
        --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
        --------------------------------------------------------------------------------------------

        declare @vsql    as nvarchar(max)
              , @XMLFile xml
              , @XML     nvarchar(max);

        set @FullXml = null;

        if (@ObjidCount > 0 and @UpdateMethod = 0)
        begin

            -------------------------------------------------------------
            -- start column value pair for update method 0
            -------------------------------------------------------------
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;
            set @ProcedureStep = 'Create Column Value Pair';

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            if
            (
                select (object_id('tempdb..#ColumnValuePair'))
            ) is not null
                drop table #ColumnValuePair;


            create table #ColumnValuePair
            (
                Id int
              , objID int
              , ObjVersion int
              , ExternalID nvarchar(100)
              , ColumnName nvarchar(200)
              , ColumnValue nvarchar(max)
              , Required bit
              , MFID int
              , DataType int
              , RetainIfNull bit
              , IsAdditional bit
            );

            create index IDX_ColumnValuePair_ColumnName
            on #ColumnValuePair (ColumnName);

            declare @colsUnpivot as nvarchar(max)
                  , @colsPivot   as nvarchar(max)
                  , @DeleteQuery as nvarchar(max)
                  , @rownr       int
                  , @Datatypes   nvarchar(100)
                  , @TypeGroup   nvarchar(100);

            -------------------------------------------------------------
            -- prepare column value pair query based on data types
            -------------------------------------------------------------
            set @Query = N'';
            set @ProcedureStep = 'Datatype table';

            declare @CaseQuery nvarchar(max);

            declare @SQL nvarchar(max);

            declare @DatatypeTable as table
            (
                id int identity
              , Datatypes nvarchar(20)
              , Type_Ids nvarchar(100)
              , TypeGroup nvarchar(100)
              , DataConversion nvarchar(258)
            );

            insert into @DatatypeTable
            (
                Datatypes
              , Type_Ids
              , TypeGroup
              , DataConversion
            )
            values
            (N'Float', N'3', 'Real', 'CAST(FORMAT(colvalue,''N'',dbo.fnMFGetCulture()) AS NVARCHAR(4000))')
          , ('Integer', '2', 'Int', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('Integer', '9', 'Int', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('Integer', '10', 'Int', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('Text', '1', 'String', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('MultiText', '13', 'String', 'CAST(colvalue AS NVARCHAR(max))')
          , ('MultiLookup', '10', 'String', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('Time', '6', 'time', 'CAST(cast(colvalue as time(0)) AS NVARCHAR(4000))')
          , ('DateTime', '7', 'Datetime'
           , 'convert(nvarchar(4000),FORMAT(convert(datetime,Colvalue,102), ''yyyy-MM-dd HH:mm:ss.fff'' ))')
          , ('Date', '5', 'Date', 'CAST(colvalue AS NVARCHAR(4000))')
          , ('Bit', '8', 'Int', 'CAST(colvalue AS NVARCHAR(4000))');

            set @ProcedureStep = 'Prepare column list';

            if
            (
                select object_id('tempdb..#ColumnList')
            ) is not null
                drop table #ColumnList;

            create table #ColumnList
            (
                MFID int
              , Column_Name nvarchar(100)
              , SQLDataType nvarchar(100)
              , MFDataType_ID int
              , Required bit
              , RetainIfNull bit
              , IsAdditional bit
            );

            insert into #ColumnList
            (
                MFID
              , Column_Name
              , SQLDataType
              , MFDataType_ID
              , Required
              , RetainIfNull
              , IsAdditional
            )
            select mfms.Property_MFID
                 , quotename(C.name)
                 , mdt.SQLDataType
                 --        mdt.ID,
                 , mdt.MFTypeID
                 , case
                       when C.is_nullable = 1 then
                           0
                       else
                           1
                   end      as Required
                 , mfms.RetainIfNull
                 , mfms.IsAdditional
            from sys.columns                         as C
                inner join dbo.MFvwMetadataStructure as mfms
                    on mfms.ColumnName = C.name
                inner join dbo.MFDataType            as mdt
                    on mfms.MFTypeID = mdt.MFTypeID
            where C.object_id = object_id(@MFTableName)
                  and isnull(mfms.Property_MFID, -1) not in ( -1 )
                  and mfms.class_MFID = @ClassId
            group by mfms.Property_MFID
                   , C.name
                   , mdt.SQLDataType
                   , mdt.MFTypeID
                   , C.is_nullable
                   , mfms.RetainIfNull
                   , mfms.IsAdditional;

            set @ProcedureStep = 'Prepare queries';

            if @Debug > 100
                select '#columnlist'
                     , *
                from #ColumnList as cl;

            set @ProcedureStep = 'insert into #ColumnValuePair';


            select @CaseQuery
                =
            (
                select ' when ''' + cl.Column_Name + ''' then '
                       + replace(dt.DataConversion, 'Colvalue', cl.Column_Name) + ' '
                from #ColumnList              as cl
                    inner join @DatatypeTable as dt
                        on dt.Type_Ids = cl.MFDataType_ID
                for xml path('')
            );




            select @SelectQuery
                = N't.id,t.Objid,t.ExternalID,t.MFVersion,'
                  + stuff((
                              select ',t.' + cl.Column_Name from #ColumnList as cl for xml path('')
                          )
                        , 1
                        , 1
                        , ''
                         );

            if @Debug > 100
                select @SelectQuery '@SelectQuery';

            set @SQL
                = N'
insert into #ColumnValuePair
select a.id, a.objid, a.MFVersion, a.externalID,  b.column_name as ColumnName
, column_value = 
    case b.column_name
    ' +     @CaseQuery
                  + N'    
    end
    ,b.Required,b.MFID,b.MFDataType_ID,RetainIfNull,IsAdditional
from (
  select ' + @SelectQuery + N'
  from ' +  @MFTableName
                  + N' t inner join 
  #ObjidTable 
  on t.id = #ObjidTable.sqlid
  ) a
cross join (
    SELECT  MFID,
    Column_Name,
    SQLDataType,
    MFDataType_ID,
    Required,
    RetainIfNull,
    IsAdditional
    From #ColumnList
  ) b (MFID,Column_Name,SQLDataType,MFDataType_ID,Required,RetainIfNull,IsAdditional);';

            if @Debug > 100
            begin
                select @SQL as 'ColumnValue pair query';
            end;


            exec sys.sp_executesql @SQL;

            set @ProcedureStep = 'update #ColumnValuePair';

            if @Debug > 100
            begin
                select 'ColumnValue pair query'
                     , *
                from #ColumnValuePair;
            end;

            update #ColumnValuePair
            set MFID = mp.MFID
              , DataType = mp.MFDataType_ID
            from #ColumnValuePair         as cvp
                inner join dbo.MFProperty mp
                    on cvp.ColumnName = mp.ColumnName;


            if @Debug > 0
                select 'Required_is_null'
                     , cvp.Id
                     , cvp.objID
                     , cvp.ObjVersion
                     , cvp.ExternalID
                     , cvp.ColumnName
                     , cvp.ColumnValue
                     , cvp.Required
                     , cvp.MFID
                     , cvp.DataType
                from #ColumnValuePair as cvp
                where cvp.Required = 1
                      and cvp.ColumnValue is null;

            -------------------------------------------------------------
            -- Remove additional properties not required
            -------------------------------------------------------------
            delete from #ColumnValuePair
            where IsAdditional = 1
                  and RetainIfNull = 0
                  and ColumnValue is null;

            -------------------------------------------------------------
            -- Validate class and property requirements
            -------------------------------------------------------------
            set @ProcedureStep = 'Validate class and property requirements';




            -------------------------------------------------------------
            -- update MFlastUpdate datetime; MFLastModified MFSQL user
            -------------------------------------------------------------
            update cvp
            set cvp.ColumnValue = case
                                      when cvp.MFID = 20 --created
                                           and cvp.ColumnValue is null then
                                          convert(
                                                     nvarchar(4000)
                                                   , format(
                                                               convert(datetime, getutcdate(), 102)
                                                             , 'yyyy-MM-dd HH:mm:ss.fff'
                                                           )
                                                 )
                                      else
                                          cvp.ColumnValue
                                  end
            from #ColumnValuePair as cvp;

            update cvp
            set cvp.ColumnValue = convert(
                                             nvarchar(4000)
                                           , format(convert(datetime, getutcdate(), 102), 'yyyy-MM-dd HH:mm:ss.fff')
                                         )
            from #ColumnValuePair as cvp
            where cvp.MFID = 21;

            declare @lastModifiedUser_ID int;

            select @lastModifiedUser_ID = mla.MFID
            from dbo.MFVaultSettings          as mvs
                inner join dbo.MFLoginAccount as mla
                    on mvs.Username = mla.UserName;

            update cvp
            set cvp.ColumnValue = cast(@lastModifiedUser_ID as nvarchar(4000))
            from #ColumnValuePair as cvp
            where cvp.MFID = 23; -- last modified

            update cvp
            set cvp.ColumnValue = case
                                      when cvp.ColumnValue is null then
                                          cast(@lastModifiedUser_ID as nvarchar(4000))
                                      else
                                          cvp.ColumnValue
                                  end
            from #ColumnValuePair as cvp
            where cvp.MFID = 25; -- created by

            if @Debug > 100
                select 'columnvaluepair'
                     , *
                from #ColumnValuePair as cvp;


            -------------------------------------------------------------
            -- END of preparating column value pair
            -------------------------------------------------------------           
            select @Count = count(isnull(cvp.Id, 0))
            from #ColumnValuePair as cvp;

            set @ProcedureStep = 'ColumnValue Pair ';
            set @LogTypeDetail = N'Debug';
            set @LogTextDetail = N'Properties for update ';
            set @LogStatusDetail = N'In Progress';
            set @Validation_ID = null;
            set @LogColumnName = N'Properties';
            set @LogColumnValue = cast(@Count as nvarchar(256));
            set @DebugText = N'Column Value Pair: %i';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            end;

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

            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;
            set @ProcedureStep = 'Creating XML for Process_ID = 1';

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            -----------------------------------------------------
            --Generate xml file -- 
            -----------------------------------------------------
            set @XMLFile =
            (
                select @ObjectId      as [Object/@id]
                     , cvp.Id         as [Object/@sqlID]
                     , cvp.objID      as [Object/@objID]
                     , cvp.ObjVersion as [Object/@objVesrion]
                     , cvp.ExternalID as [Object/@DisplayID] --Added For Task #988
                                                             --     ( SELECT
                                                             --       @ClassId AS 'class/@id' ,
                     , (
                           select
                               (
                                   select top 1
                                          tmp1.ColumnValue
                                   from #ColumnValuePair as tmp1
                                   where tmp1.MFID = 100
                               ) as [class/@id]
                             , (
                                   select tmp.MFID     as [property/@id]
                                        , tmp.DataType as [property/@dataType]
                                        , case
                                              when tmp.ColumnValue is null then
                                                  null
                                              else
                                                  tmp.ColumnValue
                                          end          as 'property' ----Added case statement for checking Required property
                                   from #ColumnValuePair as tmp
                                   where tmp.MFID <> 100
                                         --                    AND tmp.ColumnValue IS NOT NULL
                                         and tmp.Id = cvp.Id
                                   group by tmp.Id
                                          , tmp.MFID
                                          , tmp.DataType
                                          , tmp.ColumnValue
                                   order by tmp.Id
                                   --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                   for xml path(''), type
                               ) as class
                           for xml path(''), type
                       )              as Object
                from #ColumnValuePair as cvp
                group by cvp.Id
                       , cvp.objID
                       , cvp.ObjVersion
                       , cvp.ExternalID
                order by cvp.Id
                for xml path(''), root('form')
            );
            set @XMLFile =
            (
                select @XMLFile.query('/form/*')
            );

            --------------------------------------------------------------------------------------------------
            if @Debug > 100
                select @XMLFile as [@XMLFile];

            set @FullXml = isnull(cast(@FullXml as nvarchar(max)), '') + isnull(cast(@XMLFile as nvarchar(max)), '');

            if @Debug > 100
            begin
                select *
                from #ColumnValuePair as cvp;
            end;

            set @ProcedureStep = 'Count Records';

            if @Debug > 9
                raiserror('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            --Count records for ProcessBatchDetail
            set @ParmDefinition = N'@Count int output';
            set @Query = N'
					SELECT @Count = COUNT(ISNULL(id,0)) FROM ' + @MFTableName + N' WHERE process_ID = 1';

            exec sys.sp_executesql @stmt = @Query
                                 , @param = @ParmDefinition
                                 , @Count = @Count output;

            set @LogTypeDetail = N'Debug';
            set @LogTextDetail = N'XML Records for Updated method 0 ';
            set @LogStatusDetail = N'In Progress';
            set @Validation_ID = null;
            set @LogColumnName = N'process_ID = 1';
            set @LogColumnValue = cast(isnull(@Count, 0) as varchar(5));

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

            if exists (select (object_id('tempdb..#ColumnValuePair')))
                drop table #ColumnValuePair;



        end; -- End If Updatemethod = 0
    end; -- end count > 0 and update method = 0

    --------------------------------------------------------------------
    --create XML for @UpdateMethod !=0 (0=Update from SQL to MF only)
    -----------------------------------------------------
    set @StartTime = getutcdate();

    if (@UpdateMethod != 0)
    begin
        set @ProcedureStep = 'Xml for Update Method 1 ';

        declare @ObjVerXML          xml
              , @ObjVerXMLForUpdate xml
              , @CreateXmlQuery     nvarchar(max);

        if @Debug > 0
            raiserror('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);


        -------------------------------------------------------------
        -- for full update updatemethod 1
        -------------------------------------------------------------
        if @IsFullUpdate in ( 2 )
        begin
            set @ProcedureStep = 'Is full update ';
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            select @ObjVerXML =
            (
                select +cast(@ObjectId as nvarchar(20)) as 'ObjectType/@id'
                     , (
                           select objid     'objVers/@objectID'
                                , MFVersion 'objVers/@version'
                                , GUID      'objVers/@objectGUID'
                           from #ObjidTable
                           where Process_ID = 0
                           for xml path(''), type
                       )                                as ObjectType
                for xml path(''), root('form')
            );



            declare @ObjVerXmlString nvarchar(max);

            set @ObjVerXmlString = cast(@ObjVerXML as nvarchar(max));

            if @Debug > 9
            begin
                select @ObjVerXmlString as [@ObjVerXmlString];
            end;
        end;


    end; -- end is not update method 0
    -------------------------------------------------------------
    -- for filtered update update method 0
    -------------------------------------------------------------


    set @ProcedureStep = ' Prepare query for filters ';
    set @DebugText = N' Filtered Update ';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    -------------------------------------------------------------
    -- Sync error flag snippet
    -------------------------------------------------------------


    select @CreateXmlQuery
        = case
              when @UpdateMethod = 0 then
                  'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM #ObjidTable as ot
													WHERE Process_ID = 1 
                                                    FOR XML PATH(''''),ROOT(''form''))'
              when isnull(@SyncErrorFlag, 0) = 0
                   and @UpdateMethod = 1
                   and @MFModifiedDate is null then
                  'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM #ObjidTable as ot
													WHERE Process_ID = 0 
                                                    FOR XML PATH(''''),ROOT(''form''))'
              when isnull(@SyncErrorFlag, 0) = 1
                   and @UpdateMethod = 1
                   and @MFModifiedDate is null then
                  'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM #ObjidTable as ot
													WHERE Process_ID = 2
                                                    FOR XML PATH(''''),ROOT(''form''))'
              else
                  null
          end;
    -------------------------------------------------------------
    -- Compile XML query from snippets
    -------------------------------------------------------------

    if @Debug > 9
        select @CreateXmlQuery as [@CreateXmlQuery];

    set @Params = N'@ObjVerXMLForUpdate XML OUTPUT';

    if @CreateXmlQuery is not null
        exec sys.sp_executesql @CreateXmlQuery
                             , @Params
                             , @ObjVerXMLForUpdate output;

    if @Debug > 9
    begin
        select @ObjVerXMLForUpdate as [@ObjVerXMLForUpdate];
    end;



    -----------------------------------------------------
    --IF Null Creating XML with ObjectTypeID and ClassId
    -----------------------------------------------------
    set @ProcedureStep = 'Set full XML';

    if (@FullXml is null)
    begin
        set @FullXml =
        (
            select @ObjectId   as [Object/@id]
                 , @Id         as [Object/@sqlID]
                 , @objID      as [Object/@objID]
                 , @ObjVersion as [Object/@objVesrion]
                 , @ExternalID as [Object/@DisplayID] --Added for Task #988
                 , (
                       select @ClassId as [class/@id] for xml path(''), type
                   )           as Object
            for xml path(''), root('form')
        );
        set @FullXml =
        (
            select @FullXml.query('/form/*')
        );
    end;

    set @XML = N'<form>' + (cast(@FullXml as nvarchar(max))) + N'</form>';

    set @ProcedureStep = ' XML for updatemethod 0 ';
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        select cast(@XML as xml) as '@XML';
    end;

    -------------------------------------------------------------
    -- validate Objids
    -------------------------------------------------------------
    set @ProcedureStep = 'Identify Object IDs ';



    -------------------------------------------------------------
    -- Set the objectver detail XML
    -------------------------------------------------------------
    set @ProcedureStep = 'ObjverDetails for Update ';

    -------------------------------------------------------------
    -- count detail items
    -------------------------------------------------------------
    declare @objVerDetails_Count int;

    select @objVerDetails_Count = count(o.objectid)
    from
    (
        select t1.c1.value('(@objectID)[1]', 'INT') as objectid
        from @ObjVerXMLForUpdate.nodes('/form/objVers') as t1(c1)
    ) as o;

    set @DebugText = N'Count of objects %i';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objVerDetails_Count);
    end;

    set @LogTypeDetail = N'Debug';
    set @LogTextDetail = N'XML Records in ObjVerDetails for MFiles';
    set @LogStatusDetail = N'In Progress';
    set @Validation_ID = null;
    set @LogColumnValue = cast(@objVerDetails_Count as varchar(10));
    set @LogColumnName = N'ObjectVerDetails';

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

    set @ProcedureStep = 'Set input XML parameters';
    set @ObjVerXmlString = cast(@ObjVerXMLForUpdate as nvarchar(max));
    set @ObjIDsForUpdate = cast(@ObjVerXMLForUpdate as nvarchar(max));


    set @ProcedureStep = 'Get property MFIDs';

    if @Debug > 0
    begin
        raiserror('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        if @Debug > 10
            select @XML             as XML
                 , @ObjVerXmlString as ObjVerXmlString
                 , @ObjIDsForUpdate as [@ObjIDsForUpdate]
                 , @UpdateMethod    as UpdateMethod;
    end;

    -------------------------------------------------------------
    -- Get property MFIDs
    -------------------------------------------------------------
    select @MFIDs = stuff((
                              select ',' + cast(isnull(MFP.MFID, '') as nvarchar(10))
                              from INFORMATION_SCHEMA.COLUMNS as CLM
                                  left join dbo.MFProperty    as MFP
                                      on MFP.ColumnName = CLM.COLUMN_NAME
                              where CLM.TABLE_NAME = @MFTableName
                              group by MFP.MFID
                              order by MFP.MFID
                              for xml path('')
                          )
                        , 1
                        , 1
                        , ''
                         );

    if @Debug > 10
    begin
        select @MFIDs as [List of Properties];
    end;

    set @ProcedureStep = 'Update MFUpdateHistory';

    update dbo.MFUpdateHistory
    set ObjectDetails = @XML
      , ObjectVerDetails = @ObjVerXmlString
    where Id = @Update_ID;

    if @Debug > 9
        raiserror('Proc: %s Step: %s ObjectVerDetails ', 10, 1, @ProcedureName, @ProcedureStep);


    -----------------------------------------------------
    --Process Wrapper Method
    -----------------------------------------------------
    set @ProcedureStep = 'CLR Update in MFiles';
    set @StartTime = getutcdate();

    -------------------------------------------------------------
    -- Check connection to vault
    -------------------------------------------------------------

    set @ProcedureStep = 'Connection test: ';

    declare @TestResult int;

    ------------------------Added for checking required property null-------------------------------	
    set @ProcedureStep = 'wrapper';
    set @ProcedureName = 'spMFCreateObjectInternal';

    if @XML is not null
    begin
        exec dbo.spMFCreateObjectInternal @VaultSettings = @VaultSettings            -- nvarchar(4000)
                                        , @XmlFile = @XML                            -- nvarchar(max)
                                        , @objVerXmlIn = @ObjVerXmlString            -- nvarchar(max)
                                        , @MFIDs = @MFIDs                            -- nvarchar(2000)
                                        , @UpdateMethod = @UpdateMethod              -- int
                                        , @dtModifieDateTime = @MFModifiedDate       -- datetime
                                        , @sLsOfID = @ObjIDsForUpdate                -- nvarchar(max)
                                        , @CheckOutObjects = @CheckOutObjects output
                                        , @ObjVerXmlOut = @XmlOUT output             -- nvarchar(max)
                                        , @NewObjectXml = @NewObjectXml output       -- nvarchar(max)
                                        , @SynchErrorObjects = @SynchErrorObj output -- nvarchar(max)
                                        , @DeletedObjVerXML = @DeletedObjects output -- nvarchar(max)
                                        , @ErrorXML = @ErrorInfo output;             -- nvarchar(max)

    end;
    else
    begin

        set @DebugText = N' No objects to update ';
        set @DebugText = @DefaultDebugText + @DebugText;

        raiserror(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);


    end;


    set @ProcedureName = 'spMFUpdateTable';

    if @NewObjectXml = ''
        set @NewObjectXml = null;

    set @ProcedureStep = 'Analyse output';

    if @Debug > 10
    begin
        select cast(@ErrorInfo as xml) as Errorinfo;
        raiserror('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
    end;

    set @LogTypeDetail = N'Debug';
    set @LogTextDetail = N'Wrapper turnaround';
    set @LogStatusDetail = N'Assembly';
    set @Validation_ID = null;
    set @LogColumnValue = N'';
    set @LogColumnName = N'';

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

    declare @idoc3 int;
    declare @DeletedXML xml;

    set @ProcedureStep = 'Update other status items';
    set @StartTime = getutcdate();

    -------------------------------------------------------------
    -- 
    -------------------------------------------------------------
    if @Debug > 100
    begin
        select @XmlOUT as XMLout;

        select @NewObjectXml as NewObjectXml;

        select @DeletedObjects as DeletedObjects;

        select @CheckOutObjects as CheckedOutObjects;
    end;

    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'Process Exceptions';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    -------------------------------------------------------------
    -- Get status of objver
    -------------------------------------------------------------
    if
    (
        select object_id('tempdb..' + @TempStatusList + '')
    ) is not null
        exec (N'DROP TABLE ' + @TempStatusList + '');

    exec (N'CREATE TABLE ' + @TempStatusList + '
    (
        ObjectID INT PRIMARY KEY,
        Status NVARCHAR(25),
        auditStatus int,
        ClassID INT
    );

    CREATE NONCLUSTERED INDEX IDX_StatusList_Status ON ' + @TempStatusList + ' (Status)');


    -------------------------------------------------------------
    -- get status of updated records
    -------------------------------------------------------------
    if isnull(@NewObjectXml, '') <> ''
    begin

        exec sys.sp_xml_preparedocument @idoc3 output, @NewObjectXml;

        set @ProcedureStep = ' Status of returned objects ';
        set @Query
            = N'INSERT INTO ' + @TempStatusList
              + N'
        (
            ObjectID,
            Status,
            ClassID
        )
        SELECT t.objectID,
            t.Status,
            t.Class
        FROM
            OPENXML(@idoc3, ''/form/Object/properties'', 1)
            WITH
            (
                objectID INT ''../@objectId'',
                Status NVARCHAR(25) ''../@Status'',
                Class NVARCHAR(100) ''./@propertyValue'',
                ClassID INT ''./@propertyId'',
                DataType NVARCHAR(100) ''./@dataType''
            ) t
        WHERE t.ClassID = 100
              AND t.DataType IS NULL;';

        exec sys.sp_executesql @Query, N'@Idoc3 int', @idoc3;

        set @Count = @@rowcount;
        set @DebugText = N' %i ';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        end;

        if @idoc3 is not null
            exec sys.sp_xml_removedocument @idoc3;

    end; -- if @newobjectXML is not null

    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'Process Deletes phase 2';

    if isnull(@DeletedObjects, '') <> ''
    begin
        exec sys.sp_xml_preparedocument @idoc3 output, @DeletedObjects;

        set @Query
            = N'INSERT INTO ' + @TempStatusList
              + N'
        (
            ObjectID,
            Status
        )
        SELECT DISTINCT
            t.objectID,
            t.Deleted
        FROM
            OPENXML(@idoc3, ''/DelDataSet/objVers'', 1)
            WITH
            (
                objectID INT ''./Objid'',
                Deleted NVARCHAR(25) ''./Deleted''
            )                     t
            LEFT JOIN ' + @TempStatusList + N' AS sl
                ON sl.ObjectID = t.objectID';

        exec sys.sp_executesql @Query, N'@Idoc3 int', @idoc3;

        set @Count = @@rowcount;
        set @DebugText = N' %i ';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        end;

        --       WHERE sl.ObjectID IS NOT NULL;
        if @idoc3 is not null
            exec sys.sp_xml_removedocument @idoc3;
    end;

    -- @deletedobjects is not null

    set @ProcedureStep = ' checked out objects ';
    set @Query
        = N'UPDATE t 
      Set ' + quotename(@DeletedColumn) + N' = GetUTCdate()
      FROM ' + quotename(@MFTableName) + N' t
      inner join ' + @TempStatusList
          + N' l
      on l.ObjectID = t.objid
      where l.Status in (''3'',''NotInClass'')
      ';

    --IF @Debug > 0
    --    PRINT @Query;
    exec (@Query);

    set @Count = @@rowcount;
    set @DebugText = N' %i ';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
    end;

    set @ProcedureStep = ' Prepare @DeletedXML';
    set @Query
        = N'SET @DeletedXML =
        (
            SELECT *
            FROM
            (
                SELECT sl.ObjectID,
                    sl.Status
                FROM ' + @TempStatusList
          + N' AS sl
                WHERE sl.Status IN ( ''3'', ''NotInClass'' )
                GROUP BY sl.ObjectID,
                    sl.Status
            ) AS objVers
            FOR XML AUTO
        )';

    exec sys.sp_executesql @Query, N'@DeletedXML XML output', @DeletedXML;

    set @DebugText = N' ';
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    -------------------------------------------------------------
    -- Add audit table statusflag to tempstatus list
    -------------------------------------------------------------
    set @Query
        = N' UPDATE sl
        SET AuditStatus = ah.StatusFlag
        FROM ' + @TempStatusList
          + N' AS sl
              inner JOIN MFAuditHistory ah
              ON sl.ObjectID = ah.objid AND ah.objecttype = @objectID';

    exec sys.sp_executesql @Query, N'@objectID int', @ObjectId;


    if @Debug > 0
    begin
        exec (N'SELECT * FROM ' + @TempStatusList + '');
    end;

    -------------------------------------------------------------
    -- get objects that has changed class without being deleted
    -------------------------------------------------------------
    set @Params = N'@RemoveOtherClass int output, @ClassID int';
    set @vquery
        = N'SELECT @RemoveOtherClass = @RemoveOtherClass + count(*) FROM ' + @TempStatusList
          + N' where classID <> @ClassID ';
    exec sys.sp_executesql @vquery
                         , @Params
                         , @RemoveOtherClass output
                         , @ClassId;

    -------------------------------------------------------------
    -- insert object with class changed into status list
    -------------------------------------------------------------
    set @ProcedureStep = 'Reset rows not in class';

    if @RemoveOtherClass > 0
    begin
        -- get records with other class in class_id and set to deleted
        set @Count = 0;

        if @Debug > 0
            select @RemoveOtherClass as count_of_OtherClassObjects;

        declare @RemoveClassObjids nvarchar(max);

        --get objids of rows that changed class
        set @Query = null;
        set @Query
            = N' SELECT distinct sl.objectid,4
           FROM ' + @TempStatusList
              + N' AS sl
                  left join #objidTable t
                  on t.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId
                   and t.objid is null;                  
  
  '     ;

        --IF @Debug > 0
        --    SELECT @Query;

        if @Query is not null
            insert into #ObjidTable
            (
                objid
              , Type
            )
            exec sys.sp_executesql @Query, N'@ClassID int', @ClassId;

        set @Query = null;

        set @Query
            = N' Update t
 set type  = 4
 From ' + @TempStatusList
              + N' AS sl
                  inner join #objidTable t
                  on t.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId;                                    
                   ';
        if @Query is not null
            exec sys.sp_executesql @Query, N'@ClassID int', @ClassId;

        if @Debug > 0
            select '@RemoveClassObjids'
                 , *
            from #ObjidTable as ot
            where ot.Type = 4;

        set @Query = null;

        set @Query
            = N' Delete FROM ' + quotename(@MFTableName)
              + N'
        WHERE objid in (Select t.objid from #objidTable t where type = 4) ;';

        if @Debug > 0
            select @Query;

        if @Query is not null
            exec sys.sp_executesql @Query;

        set @Count = @@rowcount;
        set @DebugText = N' Delete rows with other classes %i';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        end;

        -------------------------------------------------------------
        -- update other class
        -------------------------------------------------------------
        set @ProcedureStep = 'UPdate Other Class Table';

        declare @OtherMFTableName nvarchar(100);

        if exists
        (
            select t.TABLE_NAME
            from INFORMATION_SCHEMA.TABLES as t
            where t.TABLE_NAME = @OtherMFTableName
        )
        begin

            set @Query
                = N' SELECT TOP 1
                @OtherMFTableName = mc.TableName
            FROM ' + @TempStatusList
                  + N'  AS sl
                INNER JOIN dbo.MFClass AS mc
                    ON sl.ClassID = mc.MFID
            WHERE sl.ClassID <> @ClassId';

            exec sys.sp_executesql @Query
                                 , N'@OtherMFTableName nvarchar(100) output, @classID int'
                                 , @OtherMFTableName output
                                 , @ClassId;

            if @OtherMFTableName is not null
            begin
                -------------------------------------------------------------
                -- reset audit table with class change
                -------------------------------------------------------------

                set @Query = null;
                set @Query
                    = N' Update ah
           set Class = sl.ClassID, StatusFlag = 1, StatusName = ''MFnotinSQL''
           FROM ' + @TempStatusList
                      + N' AS sl
                  inner join MFauditHistory ah
                  on ah.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId 
                   and ah.class = @ClassId;   ';

                if @Query is not null
                    exec sys.sp_executesql @Query, N'@ClassID int', @ClassId;

                -------------------------------------------------------------
                -- remove items from other class
                -------------------------------------------------------------

                select @RemoveClassObjids = stuff((
                                                      select ',' + cast(ot.objid as varchar(10))
                                                      from #ObjidTable as ot
                                                      where ot.Type = 4
                                                      for xml path('')
                                                  )
                                                , 1
                                                , 1
                                                , ''
                                                 );

                set @ProcedureStep = 'Remove from class';

                set @DebugText = N' %s @RemoveClassObjids %s';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @OtherMFTableName, @RemoveClassObjids);
                end;

                begin
                    exec dbo.spMFUpdateTable @MFTableName = @OtherMFTableName
                                           , @UpdateMethod = 1
                                           , @ObjIDs = @RemoveClassObjids
                                           , @Update_IDOut = @Update_IDOut output
                                           , @ProcessBatch_ID = @ProcessBatch_ID
                                           , @Debug = @Debug;

                    set @Query
                        = N' SElect @Count = COUNT(*) FROM ' + quotename(@OtherMFTableName)
                          + N'
                         WHERE update_ID = @Update_IDOut;';

                    exec sys.sp_executesql @Query
                                         , N'@count int output, @Update_IDOut int'
                                         , @Count output
                                         , @Update_IDOut;

                end; --delete from other table
                set @DebugText = N' Delete rows with different class %i';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                end;


            end; --update table for other class
        end; -- if other table exist
    end; -- if other class > 0

    -- end processing deletes
    -------------------------------------------------------------
    -- Remove records returned from M-Files that is not part of the class
    -------------------------------------------------------------
    set @ProcedureStep = 'Remove redundant records';
    set @Query
        = N'SELECT @Count = COUNT(ISNULL(sl.ObjectID, 0))
    FROM ' + @TempStatusList
          + N' AS sl
    WHERE sl.Status = ''NotInClass''
    GROUP BY sl.ObjectID,
        sl.Status;';

    exec sys.sp_executesql @Query, N'@count int output', @Count output;

    set @DebugText = N' Deleted items ' + cast(isnull(@Count, 0) as nvarchar(100));
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    set @ProcedureStep = 'Add logging';
    set @ProcedureStep = 'Deleted records';
    set @LogTypeDetail = N'Debug';
    set @LogTextDetail = N'Deletions';
    set @LogStatusDetail = N'InProgress';
    set @Validation_ID = null;
    set @LogColumnName = N'Deletions';
    set @LogColumnValue = isnull(cast(@Count as varchar(10)), 0);

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

    -------------------------------------------------------------
    -- Update SQL
    -------------------------------------------------------------
    set @ProcedureStep = 'Update History';
    set @StartTime = getutcdate();

    if (@Update_ID > 0)
        update dbo.MFUpdateHistory
        set NewOrUpdatedObjectVer = @XmlOUT
          , NewOrUpdatedObjectDetails = @NewObjectXml
          , SynchronizationError = @SynchErrorObj
          , DeletedObjectVer = @DeletedXML
          , MFError = @ErrorInfo
        where Id = @Update_ID;

    --New/ update Details count & log
    declare @NewOrUpdatedObjectDetails_Count int
          , @NewOrUpdateObjectXml            xml;

    set @ProcedureStep = 'Prepare XML for update into SQL';
    set @NewOrUpdateObjectXml = cast(@NewObjectXml as xml);

    select @NewOrUpdatedObjectDetails_Count = count(o.objectid)
    from
    (
        select t1.c1.value('(@objectId)[1]', 'INT') as objectid
        from @NewOrUpdateObjectXml.nodes('/form/Object') as t1(c1)
    ) as o;

    set @LogTypeDetail = N'Debug';
    set @LogTextDetail = N'XML NewOrUpdatedObjectDetails returned';
    set @LogStatusDetail = N'Output';
    set @Validation_ID = null;
    set @LogColumnValue = cast(@NewOrUpdatedObjectDetails_Count as varchar(10));
    set @LogColumnName = N'NewOrUpdatedObjectDetails';

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

    --new/update version count and log
    declare @NewOrUpdatedObjectVer_Count int
          , @NewOrUpdateObjectVerXml     xml;

    set @NewOrUpdateObjectVerXml = cast(@XmlOUT as xml);

    select @NewOrUpdatedObjectVer_Count = count(o.objectid)
    from
    (
        select t1.c1.value('(@objectId)[1]', 'INT') as objectid
        from @NewOrUpdateObjectVerXml.nodes('/form/Object') as t1(c1)
    ) as o;

    set @LogTypeDetail = N'Debug';
    set @LogTextDetail = N'ObjVer returned';
    set @LogStatusDetail = N'Output';
    set @Validation_ID = null;
    set @LogColumnValue = cast(@NewOrUpdatedObjectVer_Count as varchar(10));
    set @LogColumnName = N'NewOrUpdatedObjectVer';

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


    set @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
    set @StartTime = getutcdate();

    create table #ObjVer
    (
        ID int
      , ObjID int
      , MFVersion int
      , GUID nvarchar(100)
      , FileCount int ---- Added for task 106
    );

    declare @NewObjVerDetails_Count int;

    insert into #ObjVer
    (
        MFVersion
      , ObjID
      , ID
      , GUID
      , FileCount
    )
    select t.c.value('(@objVersion)[1]', 'INT')           as MFVersion
         , t.c.value('(@objectId)[1]', 'INT')             as ObjID
         , t.c.value('(@ID)[1]', 'INT')                   as ID
         , t.c.value('(@objectGUID)[1]', 'NVARCHAR(100)') as GUID
         , t.c.value('(@FileCount)[1]', 'INT')            as FileCount -- Added for task 106
    from @NewOrUpdateObjectVerXml.nodes('/form/Object') as t(c);

    set @Count = @@rowcount;

    if @Debug > 9
    begin
        raiserror('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        if @Debug > 100
            select '#objver'
                 , *
            from #ObjVer;
    end;

    declare @UpdateQuery nvarchar(max);

    set @UpdateQuery
        = N'	UPDATE [' + @MFTableName + N']
					SET [' + @MFTableName + N'].ObjID = #ObjVer.ObjID
					,[' + @MFTableName + N'].MFVersion = #ObjVer.MFVersion
					,[' + @MFTableName + N'].GUID = #ObjVer.GUID
					,[' + @MFTableName
          + N'].FileCount = #ObjVer.FileCount  
					,Process_ID = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE [' + @MFTableName + N'].ID = #ObjVer.ID';

    exec (@UpdateQuery);

    set @ProcedureStep = 'Update Records in ' + @MFTableName + '';
    set @LogTextDetail = @ProcedureStep;
    set @LogStatusDetail = N'Output';
    set @Validation_ID = null;
    set @LogColumnName = N'NewObjVerDetails';
    set @LogColumnValue = cast(isnull(@NewObjVerDetails_Count, 0) as varchar(10));

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

    drop table #ObjVer;

    ----------------------------------------------------------------------------------------------------------
    --Update Process_ID to 2 when synch error occcurs--
    ----------------------------------------------------------------------------------------------------------
    set @ProcedureStep = 'when synch error occurs';
    set @StartTime = getutcdate();

    ----------------------------------------------------------------------------------------------------------
    --Create an internal representation of the XML document. 
    ---------------------------------------------------------------------------------------------------------                
    create table #SynchErrObjVer
    (
        ID int
      , ObjID int
      , MFVersion int
    );

    -----------------------------------------------------
    ----Inserting the Xml details into temp Table
    -----------------------------------------------------
    declare @SynchErrorXML xml;

    set @SynchErrorXML = cast(@SynchErrorObj as xml);

    insert into #SynchErrObjVer
    (
        MFVersion
      , ObjID
      , ID
    )
    select t.c.value('(@objVersion)[1]', 'INT') as MFVersion
         , t.c.value('(@objectId)[1]', 'INT')   as ObjID
         , t.c.value('(@ID)[1]', 'INT')         as ID
    from @SynchErrorXML.nodes('/form/Object') as t(c);

    select @SynchErrCount = count(isnull(ID, 0))
    from #SynchErrObjVer;

    if @SynchErrCount > 0
    begin
        if @Debug > 9
        begin
            raiserror('Proc: %s Step: %s Count %i ', 10, 1, @ProcedureName, @ProcedureStep, @SynchErrCount);

            if @Debug > 10
                select '#SynchErrObjVer'
                     , *
                from #SynchErrObjVer;
        end;

        set @LogTypeDetail = N'User';
        set @LogTextDetail = @ProcedureStep;
        set @LogStatusDetail = N'Sync Error';
        set @Validation_ID = 2;
        set @LogColumnName = N'Synch Errors';
        set @LogColumnValue = isnull(cast(@SynchErrCount as varchar(10)), 0);

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

        -------------------------------------------------------------------------------------
        -- UPDATE THE SYNCHRONIZE ERROR
        -------------------------------------------------------------------------------------
        declare @SynchErrUpdateQuery nvarchar(max);

        ------------------------------------------------------
        --Getting @SyncPrecedence from MFClasss table for @TableName
        --IF NULL THEN insert error in error log 
        ------------------------------------------------------
        declare @SyncPrecedence int;
        set @ProcedureStep = 'Sync Errors';
        select @SyncPrecedence = SynchPrecedence
        from dbo.MFClass
        where TableName = @MFTableName;

        set @DebugText = N' Synch precedence for ' + @MFTableName + N' ' + cast(@SyncPrecedence as varchar(3));
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        set @DebugText = N' Sync Precedence %i';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @SyncPrecedence is null
        begin

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SyncPrecedence);
            end;


            set @SynchErrUpdateQuery
                = N'	UPDATE [' + @MFTableName + N']
					SET ['             + @MFTableName
                  + N'].ObjID = #SynchErrObjVer.ObjID	
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '     + cast(@Update_ID as varchar(15)) + N'
					FROM #SynchErrObjVer
					WHERE ['           + @MFTableName + N'].ID = #SynchErrObjVer.ID';

            exec (@SynchErrUpdateQuery);

            ------------------------------------------------------
            -- LOGGING THE ERROR
            ------------------------------------------------------

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                exec (N'Select ''Sync errors '', * from ' + @MFTableName + ' where process_ID = 2');
            end;

            insert into dbo.MFLog
            (
                ErrorMessage
              , Update_ID
              , ErrorProcedure
              , ExternalID
              , ProcedureStep
              , SPName
            )
            select *
            from
            (
                select 'Synchronization error occured while updating ObjID : ' + cast(ObjID as nvarchar(10))
                       + ' Version : ' + cast(MFVersion as nvarchar(10)) + '' as ErrorMessage
                     , @Update_ID                                             as Update_ID
                     , @TableName                                             as ErrorProcedure
                     , ''                                                     as ExternalID
                     , 'Synchronization Error'                                as ProcedureStep
                     , 'spMFUpdateTable'                                      as SPName
                from #SynchErrObjVer
            ) as vl;
        end;


        if isnull(@SyncPrecedence, -1) >= 0
           and @SynchErrCount > 0
        begin
            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SyncPrecedence);
            end;

            set @SynchErrUpdateQuery
                = case
                      when @SyncPrecedence = 1 then
                          N'	UPDATE [' + @MFTableName + N']
					SET ['                     + @MFTableName
                          + N'].ObjID = #SynchErrObjVer.ObjID
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '             + cast(@Update_ID as varchar(15))
                          + N'
					FROM #SynchErrObjVer
					WHERE ['                   + @MFTableName + N'].ID = #SynchErrObjVer.ID'
                      when @SyncPrecedence = 0 then
                          N'	UPDATE [' + @MFTableName + N']
					SET ['                     + @MFTableName + N'].ObjID = #SynchErrObjVer.ObjID	,[' + @MFTableName
                          + N'].MFVersion = #SynchErrObjVer.MFVersion
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '             + cast(@Update_ID as varchar(15))
                          + N'
					FROM #SynchErrObjVer
					WHERE ['                   + @MFTableName + N'].ID = #SynchErrObjVer.ID'
                  end;

            exec (@SynchErrUpdateQuery);


            ------------------------------------------------------
            -- LOGGING THE ERROR
            ------------------------------------------------------
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                exec (N'Select ''Sync errors '', * from ' + @MFTableName + ' where process_ID = 2');
            end;

        --EXEC dbo.spMFUpdateSynchronizeError @TableName = @TableName,
        --                                    @Update_ID = @Update_ID,
        --                                    @ProcessBatch_ID = @ProcessBatch_ID,
        --                                    @Debug = @Debug
        end; --ISNULL(@SyncPrecedence,-1) >= 0 AND @SynchErrCount > 0
    end; --@SynchErrCount > 0
    --end of if syncerror count
    drop table #SynchErrObjVer;

    -------------------------------------------------------------
    --Logging error details
    -------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'Perform checking for SQL Errors ';

    create table #ErrorInfo
    (
        ObjID int
      , SqlID int
      , ExternalID nvarchar(100)
      , ErrorMessage nvarchar(max)
    );

    declare @ErrorInfoXML xml;

    select @ErrorInfoXML = cast(@ErrorInfo as xml);

    insert into #ErrorInfo
    (
        ObjID
      , SqlID
      , ExternalID
      , ErrorMessage
    )
    select t.c.value('(@objID)[1]', 'INT')                  as objID
         , t.c.value('(@sqlID)[1]', 'INT')                  as SqlID
         , t.c.value('(@externalID)[1]', 'NVARCHAR(100)')   as ExternalID
         , t.c.value('(@ErrorMessage)[1]', 'NVARCHAR(MAX)') as ErrorMessage
    from @ErrorInfoXML.nodes('/form/errorInfo') as t(c);

    select @ErrorInfoCount = count(isnull(SqlID, 0))
    from #ErrorInfo;

    if @ErrorInfoCount > 0
    begin
        if @Debug > 10
        begin
            select *
            from #ErrorInfo;
        end;

        set @DebugText = N'SQL Error logging errors found ';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        select @MFErrorUpdateQuery
            = N'UPDATE [' + @MFTableName
              + N']
									   SET Process_ID = 3
									   FROM #ErrorInfo err
									   WHERE err.SqlID = [' + @MFTableName + N'].ID';

        exec (@MFErrorUpdateQuery);

        set @ProcedureStep = 'M-Files Errors ';
        set @LogTypeDetail = N'User';
        set @LogTextDetail = @ProcedureStep;
        set @LogStatusDetail = N'Error';
        set @Validation_ID = 3;
        set @LogColumnName = N'M-Files errors';
        set @LogColumnValue = isnull(cast(@ErrorInfoCount as varchar(10)), 0);

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

        insert into dbo.MFLog
        (
            ErrorMessage
          , Update_ID
          , ErrorProcedure
          , ExternalID
          , ProcedureStep
          , SPName
        )
        select 'ObjID : ' + cast(isnull(ObjID, '') as nvarchar(100)) + ',' + 'SQL ID : '
               + cast(isnull(SqlID, '') as nvarchar(100)) + ',' + ErrorMessage as ErrorMessage
             , @Update_ID
             , @TableName                                                      as ErrorProcedure
             , ExternalID
             , 'Error While inserting/Updating in M-Files'                     as ProcedureStep
             , 'spMFUpdateTable'                                               as spname
        from #ErrorInfo;
    end;
    --end of error count
    drop table #ErrorInfo;

    ------------------------------------------------------------------
    --        SET @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));
    -------------------------------------------------------------------------------------
    -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
    -------------------------------------------------------------------------------------
    set @DebugText = N'';
    set @DebugText = @DefaultDebugText + @DebugText;
    set @ProcedureStep = 'Update property details from M-Files ';

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    set @StartTime = getutcdate();

    if (
           @NewObjectXml != '<form />'
           or @NewObjectXml <> ''
           or @NewObjectXml <> null
       )
    begin
        if @Debug > 10
            select @NewObjectXml as [@NewObjectXml before updateobjectinternal];

        exec @return_value = dbo.spMFUpdateTableInternal @MFTableName
                                                       , @NewObjectXml
                                                       , @Update_ID
                                                       , @Debug = @Debug
                                                       , @SyncErrorFlag = @SyncErrorFlag;

        if @return_value <> 1
            raiserror('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
    end; -- end update table internal

    --IF @debug > 0
    --SELECT 'pre-update audit table', * FROM dbo.MFvwAuditSummary AS mfas;
    -------------------------------------------------------------
    -- Update MFaudithistory for all updated records
    -------------------------------------------------------------
    set @ProcedureStep = 'Update MFaudithistory ';


    begin transaction;

    set @ProcedureStep = 'Update MFaudit History ';
    set @Params = N'@Update_ID int, @ClassID int,@ObjectType int';
    set @Query
        = N'
        UPDATE mah WITH (UPDLOCK, SERIALIZABLE)
        SET mah.StatusFlag = CASE 
        when sl.status = ''1'' and isnull(sl.AuditStatus,0) = 0 then 0
         WHEN sl.status = ''1'' and isnull(sl.AuditStatus,0) > 0 THEN 0
        WHEN sl.status = ''2'' THEN 3
        WHEN sl.status in (''3'',''Deleted'') THEN 4
         WHEN sl.Status = ''NotInClass'' THEN 5
        end,
            mah.StatusName = CASE 
            when sl.status = ''1'' AND isnull(sl.AuditStatus,0) = 0 then ''Identical''
           WHEN sl.status = ''1'' and sl.AuditStatus > 0 THEN ''Identical''
             WHEN sl.Status = ''2'' THEN ''Checked out''
            WHEN sl.Status = ''3'' then ''Deleted''
            WHEN sl.Status = ''NotInClass'' THEN ''Not in Class'' 
            END,
          RecID = t.ID
        ,SessionID = @Update_ID
        ,TranDate = GETDATE()
        ,MFVersion = t.MFVersion 
        ,updateFlag = 0
        FROM dbo.MFAuditHistory    AS mah
         inner join ' + @TempStatusList + N' sl
         ON sl.objectID = mah.objid 
         INNER JOIN ' + quotename(@MFTableName)
          + N'  t
         ON t.objid = mah.objid AND
         mah.class = @classid AND mah.objectType = @ObjectType;';

    exec sys.sp_executesql @Stmt = @Query
                         , @Params = @Params
                         , @ClassID = @ClassId
                         , @Update_ID = @Update_ID
                         , @ObjectType = @ObjectId;

    set @rownr = @@rowcount;

    commit transaction;

    set @DebugText = N' Count ' + cast(isnull(@rownr, 0) as nvarchar(10));
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        select @Query as AuditUpdateQuery;

        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    begin transaction;

    set @ProcedureStep = 'insert new into Audit history';
    set @Params = N'@Update_ID int, @ClassID int,@ObjectType int';
    set @Query
        = N'INSERT INTO dbo.MFAuditHistory
  (
      RecID,
      SessionID,
      TranDate,
      ObjectType,
      Class,
      ObjID,
      MFVersion,
      StatusFlag,
      StatusName,
      UpdateFlag
  )
  SELECT t.id,
  t.UPDATE_ID,
  t.LastModified, 
  @ObjectType, 
 @ClassID,
  sl.ObjectID,
  t.MFVersion,
  CASE 
        WHEN isnull(sl.status,''1'') = ''1'' THEN 0
        WHEN sl.status = ''2'' THEN 3
        WHEN sl.status = ''3'' THEN 4
        WHEN sl.status  = ''NotInClass'' THEN 5
        end,
  CASE WHEN isnull(sl.status,''1'') = ''1'' THEN ''Identical''
             WHEN sl.Status = ''2'' THEN ''Checked out''
            WHEN sl.Status = ''3'' then ''Deleted''
            WHEN sl.Status = ''NotInClass'' THEN ''Not in Class'' 
            END, 0
  FROM ' + @TempStatusList + N' AS sl
  INNER JOIN ' + quotename(@MFTableName)
          + N' as t
  ON sl.ObjectID = t.objid
  left JOIN dbo.MFAuditHistory AS mah
  ON sl.ObjectID = mah.objid AND mah.class = @ClassId AND mah.ObjectType = @ObjectType
  WHERE mah.ObjID IS NULL;';

    if @Debug > 0
        select @Query as AuditInsertQuery;

    exec sys.sp_executesql @Stmt = @Query
                         , @Params = @Params
                         , @ClassID = @ClassId
                         , @Update_ID = @Update_ID
                         , @ObjectType = @ObjectId;

    set @rownr = @@rowcount;

    commit transaction;

    set @DebugText = N' Count ' + cast(isnull(@rownr, 0) as nvarchar(10));
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    --IF @debug > 0
    --SELECT 'post-update audit table', * FROM dbo.MFvwAuditSummary AS mfas;


    set @ProcedureStep = 'Delete redundant from audit history ';

    if @ObjIDs is not null
    begin
        ;
        with CTE
        as (select mah.ID
                 , mah.ObjID
            from dbo.MFAuditHistory    as mah
                inner join #ObjidTable as fmpds
                    on fmpds.objid = mah.ObjID
            where mah.Class = @ClassId
                  and mah.StatusFlag = 5)
        delete from dbo.MFAuditHistory
        where ID in
              (
                  select CTE.ID from CTE
              );
    end;

    set @rownr = @@rowcount;


    set @DebugText = N' Count ' + cast(isnull(@rownr, 0) as nvarchar(10));
    set @DebugText = @DefaultDebugText + @DebugText;

    if @Debug > 0
    begin
        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    end;

    --end of obids is not null
    -------------------------------------------------------------------------------------
    --Checked whether all data is updated. #1360
    ------------------------------------------------------------------------------------ 
    --EXEC ('update '+ @MFTableName +' set Process_ID=1 where id =2')
    set @ProcedureStep = 'Check updated data ';

    --   IF @UpdateMethod = 0 AND @Debug > 0
    --    BEGIN

    --    DECLARE @Sql NVARCHAR(1000) = N'
    --    IF EXISTS(
    --SELECT  1 FROM ' + @MFTableName + N' WHERE Process_ID=1)'


    --     RAISERROR(''Error: All data is not updated'', 10, 1, @ProcedureName, @ProcedureStep);
    --     END               
    --EXEC(@sql)
    --   END;    --end of update method 0

    set @ProcedureStep = 'Remove redundant items';

    -------------------------------------------------------------
    -- Remove redundant items from MFAuditHistory
    -------------------------------------------------------------

    set @ProcedureStep = 'Delete class objects';

    if @RetainDeletions = 0
    begin
        set @ProcedureStep = 'RetainDeletions = 0 ';
        set @Query
            = N'DELETE FROM ' + quotename(@MFTableName) + N' WHERE ' + quotename(@DeletedColumn) + N' is not null';
        set @Count = @@rowcount;
        set @DebugText = N' Removed ' + cast(isnull(@Count, 0) as varchar(10));
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        exec (@Query);
    end;
    --end of retain deletions

    set @ProcedureStep = 'Set update Status';
    set @Count = null;
    set @Query = N'SELECT @rowcount = COUNT(isnull(id,0)) FROM ' + quotename(@TableName) + N' WHERE process_id = 4';

    exec sys.sp_executesql @Query, N'@rowcount int output', @Count output;

    if (@Count <> 0)
    begin
        set @return_value = 4;
    end;

    if @Debug > 9
        raiserror('Proc: %s Step: %s ReturnValue %i Completed ', 10, 1, @ProcedureName, @ProcedureStep, @return_value);

    -------------------------------------------------------------
    -- Check if precedence is set and update records with synchronise errors
    -------------------------------------------------------------
    if @SyncPrecedence is not null
       and @SynchErrCount > 0
    begin
        exec dbo.spMFUpdateSynchronizeError @TableName = @MFTableName
                                          , @Update_ID = @Update_IDOut
                                          , @RetainDeletions = @RetainDeletions
                                          , @ProcessBatch_ID = @ProcessBatch_ID
                                          , @Debug = @Debug;

    end;

    -- end of sync precedence
    -------------------------------------------------------------
    -- Finalise logging
    -------------------------------------------------------------
    declare @MessageSwitch smallint;

    set @MessageSwitch = case
                             when @return_value = 1
                                  and @SynchErrCount = 0
                                  and @ErrorInfoCount = 0 then
                                 1
                             when @return_value = 1
                                  and
                                  (
                                      @SynchErrCount = 1
                                      or @ErrorInfoCount = 1
                                  ) then
                                 2
                             when @return_value <> 1
                                  and @SynchErrCount = 1
                                  and @ErrorInfoCount = 3 then
                                 3
                             when @return_value <> 1
                                  and @ErrorInfoCount > 0 then
                                 4
                             else
                                 -1
                         end;
    set @ProcedureStep = 'Updating Table - Finalise ';
    set @LogType = N'Message';
    set @LogText
        = case
              when @MessageSwitch = 1 then
                  N'Update ' + @MFTableName + N':Update Method ' + cast(@UpdateMethod as varchar(10))
              when @MessageSwitch = 2 then
                  N'Update ' + @MFTableName + N':Update Method ' + cast(@UpdateMethod as varchar(10))
                  + N' Partial Completed '
              when @MessageSwitch = 3 then
                  N'Update ' + @MFTableName + N'with sycnronisation errors: process_id = 2 '
              when @MessageSwitch = 4 then
                  N'Update ' + @MFTableName + N'with MFiles errors: process_id = 3 '
          end;
    set @LogStatus = case
                         when @MessageSwitch = 1 then
                             N'Completed'
                         when @MessageSwitch = 2 then
                             N'Partial'
                         when @MessageSwitch in ( 3, 4 ) then
                             N'Errors'
                     end;

    update dbo.MFUpdateHistory
    set UpdateStatus = @LogStatus
    where Id = @Update_ID;

    -------------------------------------------------------------
    -- output completion message
    -------------------------------------------------------------
    exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID
                                                      -- int
                                   , @ProcessType = @ProcessType
                                   , @LogText = @LogText
                                                      -- nvarchar(4000)
                                   , @LogStatus = @LogStatus
                                                      -- nvarchar(50)
                                   , @debug = @Debug; -- tinyint

    exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID
                                         , @Update_ID = @Update_ID
                                         , @LogText = @LogText
                                         , @LogType = @LogType
                                         , @LogStatus = @LogStatus
                                         , @StartTime = @StartTime
                                         , @MFTableName = @MFTableName
                                         , @ColumnName = @LogColumnName
                                         , @ColumnValue = @LogColumnValue
                                         , @LogProcedureName = @ProcedureName
                                         , @LogProcedureStep = @ProcedureStep
                                         , @debug = @Debug;


    return @return_value; --For More information refer Process Table      
end try
begin catch
    --IF @idoc3 IS NOT NULL
    --    EXEC sys.sp_xml_removedocument @idoc3;

    if @@trancount <> 0
    begin
        rollback transaction;
    end;

    set nocount on;

    update dbo.MFUpdateHistory
    set UpdateStatus = 'failed'
    where Id = @Update_ID;

    insert into dbo.MFLog
    (
        SPName
      , ErrorNumber
      , ErrorMessage
      , ErrorProcedure
      , ProcedureStep
      , ErrorState
      , ErrorSeverity
      , Update_ID
      , ErrorLine
    )
    values
    ('spMFUpdateTable', error_number(), error_message(), error_procedure(), @ProcedureStep, error_state()
   , error_severity(), @Update_ID, error_line());

    if @Debug > 9
    begin
        select error_number()    as ErrorNumber
             , error_message()   as ErrorMessage
             , error_procedure() as ErrorProcedure
             , @ProcedureStep    as ProcedureStep
             , error_state()     as ErrorState
             , error_severity()  as ErrorSeverity
             , error_line()      as ErrorLine;
    end;

    set nocount off;

    return -1; --For More information refer Process Table
end catch;
go