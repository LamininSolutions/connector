
go

print space(5) + quotename(@@servername) + '.' + quotename(db_name()) + '.[dbo].[spMFUpdateExplorerFileToMFiles]';
go

set nocount on;

exec setup.spMFSQLObjectsControl @SchemaName = N'dbo'
                               , @ObjectName = N'spMFUpdateExplorerFileToMFiles'
                               -- nvarchar(100)
                               , @Object_Release = '4.10.32.76'
                               -- varchar(50)
                               , @UpdateFlag = 2;
-- smallint
go

if exists
(
    select 1
    from INFORMATION_SCHEMA.ROUTINES
    where ROUTINE_NAME = 'spMFUpdateExplorerFileToMFiles' --name of procedure
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
create procedure dbo.spMFUpdateExplorerFileToMFiles
as
select 'created, but not implemented yet.';
--just anything will do
go

-- the following section will be always executed
set noexec off;
go

alter procedure dbo.spMFUpdateExplorerFileToMFiles
    @FileName nvarchar(1000)
  , @FileLocation nvarchar(1000)
  , @MFTableName nvarchar(100)
  , @SQLID int
  , @IsFileDelete bit = 0
  , @RetainDeletions bit = 0
  , @IsDocumentCollection bit = 0
  , @ResetToSingleFile bit = 0
  , @ProcessBatch_id int = null output
  , @Debug int = 0
as
/*rST**************************************************************************

==============================
spMFUpdateExplorerFileToMFiles
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @FileName nvarchar(256)
    Name of file
  @FileLocation nvarchar(256)
    UNC path or Fully qualified path to file
  @MFTableName nvarchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @SQLID int
    the ID column on the class table
  @IsFileDelete bit (optional)
    - Default = 0
    - 1 = the file should be deleted in folder
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_id int (output)
    Output ID in MFProcessBatch for logging the process
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

MFSQL Connector file import provides the capability of attaching a file to a object in a class table.

Additional Info
===============

This functionality will:

- Add the file to an object.  If the object exist as a multidocument object with no files attached, the file will be added to the multidocument object and converted to a single file object.  If the files already exist for the object, the file will be added to the collection.
- The object must pre-exist in the class table. The class table metadata will be applied to object when adding the file. This procedure will add a new object from the class table, or update an existing object in M-Files using the class table metadata.
- The source file will optionally be deleted from the source folder.

The procedure will not automatically change a multifile document to a single file document. To set an object to a single file object the column 'Single_File' can be set to 1 after the file has been added.

Warnings
========

The procedure use the ID in the class table and not the objid column to reference the object.  This allows for referencing an record which does not yet exist in M-Files.

Examples
========

.. code:: sql

    DECLARE @ProcessBatch_id INT;
    DECLARE @FileLocation NVARCHAR(256) = 'C:\Share\Fileimport\2\'
    DECLARE @FileName NVARCHAR(100) = 'CV - Tommy Hart.docx'
    DECLARE @TableName NVARCHAR(256) = 'MFOtherDocument'
    DECLARE @SQLID INT = 1

    EXEC [dbo].[spMFUpdateExplorerFileToMFiles]
        @FileName = @FileName
       ,@FileLocation = @FileLocation
       ,@SQLID = @SQLID
       ,@MFTableName = @TableName
       ,@ProcessBatch_id = @ProcessBatch_id OUTPUT
       ,@Debug = 0
       ,@IsFileDelete = 0

    SELECT * from [dbo].[MFFileImport] AS [mfi]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-05-19  LC         Resolve issue with updating changed file
2023-03-28  LC         Allow option to set object to set object to single file
2023-03-27  LC         Improve logic for validation
2023-01-23  lc         Fix bug setting single file to 1 when count > 1
2022-12-07  LC         Improve logging messages
2022-09-02  LC         Update to include RetainDeletions and DocumentCollections
2021-08-03  LC         Fix truncate string bug
2021-05-21  LC         improve handling of files on network drive
2020-12-31  LC         Improve error handling in procedure
2020-12-31  LC         Update datetime handling in mffileexport
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
begin
    begin try
        set nocount on;

        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
        declare @DefaultDebugText as nvarchar(256) = N'Proc: %s Step: %s';
        declare @DebugText as nvarchar(256) = N'';
        declare @LogTypeDetail as nvarchar(max) = N'';
        declare @LogTextDetail as nvarchar(max) = N'';
        declare @LogTextAccumulated as nvarchar(max) = N'';
        declare @LogStatusDetail as nvarchar(50) = null;
        declare @LogColumnName as nvarchar(128) = null;
        declare @LogColumnValue as nvarchar(256) = null;
        declare @ProcessType nvarchar(50) = N'Import File';
        declare @LogType as nvarchar(50) = N'Status';
        declare @LogText as nvarchar(4000) = N'File Import Initiated';
        declare @LogStatus as nvarchar(50) = N'Started';
        declare @Status as nvarchar(128) = null;
        declare @Validation_ID int = null;
        declare @StartTime as datetime = getutcdate();
        declare @RunTime as decimal(18, 4) = 0;
        declare @Update_IDOut int;
        declare @error as int = 0;
        declare @rowcount as int = 0;
        declare @return_value as int;
        declare @RC int;
        declare @Update_ID int;
        declare @ProcedureName sysname = 'spMFUpdateExplorerFileToMFiles';
        declare @ProcedureStep sysname = 'Start';

        ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
        ----------------------------------------------------------------------
        declare @Username nvarchar(2000);
        declare @VaultName nvarchar(2000);

        select top 1
               @Username  = Username
             , @VaultName = VaultName
        from dbo.MFVaultSettings;

        insert into dbo.MFUpdateHistory
        (
            Username
          , VaultName
          , UpdateMethod
        )
        values
        (@Username, @VaultName, -1);

        select @Update_ID = @@identity;

        select @Update_IDOut = @Update_ID;

        set @ProcessType = N'Import File';
        set @LogText = N' Started ';
        set @LogStatus = N'Initiate';
        set @StartTime = getutcdate();
        set @LogTypeDetail = N'Debug';
        set @LogStatusDetail = N'In Progress';


        execute @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id output
                                                , @ProcessType = @ProcessType
                                                , @LogType = 'Info'
                                                , @LogText = @LogText
                                                , @LogStatus = @LogStatus
                                                , @debug = 0;

        execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id
                                                                , @LogType = @LogTypeDetail
                                                                , @LogText = @LogText
                                                                , @LogStatus = @LogStatusDetail
                                                                , @StartTime = @StartTime
                                                                , @MFTableName = @MFTableName
                                                                , @Validation_ID = @Validation_ID
                                                                , @ColumnName = @LogColumnName
                                                                , @ColumnValue = @LogColumnValue
                                                                , @Update_ID = @Update_ID
                                                                , @LogProcedureName = @ProcedureName
                                                                , @LogProcedureStep = @ProcedureStep
                                                                , @debug = 0;

        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        ----------------------------------------
        --DECLARE VARIABLES
        ----------------------------------------
        declare @TargetClassMFID int;
        declare @ObjectTypeID int;
        declare @VaultSettings nvarchar(max);
        declare @XML nvarchar(max);
        --     DECLARE @Counter INT;
        declare @MaxRowID int;
        declare @ObjIDs nvarchar(4000);
        declare @Objid int;
        declare @Sql nvarchar(max);
        declare @Params nvarchar(max);
        declare @Count int;
        declare @FileID nvarchar(250);
        declare @ParmDefinition nvarchar(500);
        declare @XMLOut        xml
              , @ObjectVersion int;
        declare @Start int;
        declare @End int;
        declare @length int;
        declare @SearchTerm nvarchar(50) = N'System.';

        set @ProcedureStep = 'Checking Target class ';
        set @DebugText = N'';
        set @DebugText = @DefaultDebugText + @DebugText;

        if @Debug > 0
        begin
            raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        end;

        if exists (select top 1 * from dbo.MFClass where TableName = @MFTableName)
        begin
            set @LogTextDetail = @MFTableName + N' is valid table';

            execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id
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
                                                                    , @debug = 0;

            select @TargetClassMFID = MC.MFID
                 , @ObjectTypeID    = OT.MFID
            from dbo.MFClass                MC
                inner join dbo.MFObjectType OT
                    on MC.MFObjectType_ID = OT.ID
            where MC.TableName = @MFTableName;

            ------------------------------------------------
            --Getting Vault Settings
            ------------------------------------------------
            set @DebugText = N'';
            set @DebugText = @DefaultDebugText + @DebugText;
            set @ProcedureStep = 'Getting Vault credentials ';

            if @Debug > 0
            begin
                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            end;

            select @VaultSettings = dbo.FnMFVaultSettings();

            declare @TempFile varchar(100);
            declare @Single_File int;
            declare @FileCount int;
            declare @Process_ID int;
            declare @isNewObject int;


            -------------------------------------------------------------
            -- license check
            -------------------------------------------------------------


            exec dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFUpdateExplorerFileToMFiles'
                                          , @ProcedureName = @ProcedureName
                                          , @ProcedureStep = @ProcedureStep
                                          , @ProcessBatch_id = @ProcessBatch_id
                                          , @Debug = 0;

            -------------------------------------------------------------
            -- Get objid for record
            -------------------------------------------------------------         
            set @ProcedureStep = ' Validate object exist in table';

            set @Count = 0;
            set @Objid = null;

            set @Sql = N'select @Count = count(*) from ' + quotename(@MFTableName) + N' as t where id = @SQLID ';

            exec sys.sp_executesql @Sql
                                 , N'@count int output, @sqlid int'
                                 , @Count output
                                 , @SQLID;

            if @Count <> 1
            begin

                set @DebugText = N' id %i not found for ' + @MFTableName;
                set @DebugText = @DefaultDebugText + @DebugText;

                raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SQLID);

                raiserror(@DebugText, 16, 1, @ProcedureName, @ProcedureStep, @SQLID);
            end;
            if @Count > 0
            begin
                --print @SQL;

                set @ProcedureStep = 'Get latest version ';

                set @Params = N'@ObjID INT output,  @SQLID int, @ObjectVersion int output, @Process_ID int output ';

                set @Sql
                    = N'Select @ObjID = case when isnull(Objid,0) < 1 then null else objid end,  @Process_id = Process_id  
                    FROM ' + quotename(@MFTableName) + N' WHERE ID = ' + cast(@SQLID as varchar(10)) + N' ';

                exec sys.sp_executesql @Sql
                                     , @Params
                                     , @Objid output
                                     , @SQLID
                                     , @ObjectVersion output
                                     , @Process_ID output;

                if isnull(@Objid, 0) > 0 --objrct in MF
                begin

                    select @ObjIDs = cast(@Objid as varchar(4000));


                    --      SELECT @Objid AS '@ObjId';
                    set @DebugText = N' Objids ' + coalesce(@ObjIDs, 'null');
                    set @DebugText = @DefaultDebugText + @DebugText;
                    set @ProcedureStep = ' Objids for update';

                    if @Debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                    -------------------------------------------------------------
                    -- get latest version of object
                    -------------------------------------------------------------
                    ;

                    if
                    (
                        select top 1
                               mah.MFVersion
                        from dbo.MFAuditHistory as mah
                        where mah.ObjID = @Objid
                              and mah.Class = @TargetClassMFID
                              and mah.StatusFlag = 0
                    ) <> @ObjectVersion
                    begin
                        set @ProcedureStep = ' reset process_ID and Update from MF';
                        set @Params = N'@sqlid int';
                        set @Sql = N'UPDATE ' + quotename(@MFTableName) + N' SET [Process_ID] = 0 WHERE id = @sqlid';

                        exec sys.sp_executesql @Sql, @Params, @Objid;


                        exec dbo.spMFUpdateTable @MFTableName = @MFTableName
                                               , @UpdateMethod = 1
                                               , @ObjIDs = @Objid
                                               , @Update_IDOut = @Update_IDOut output
                                               , @ProcessBatch_ID = @ProcessBatch_id
                                               , @RetainDeletions = @RetainDeletions
                                               , @IsDocumentCollection = @IsDocumentCollection
                                               , @Debug = @Debug;

                        if @Process_ID <> 0
                        begin
                            set @Params = N'@sqlid int, @process_ID int';
                            set @Sql
                                = N'UPDATE ' + quotename(@MFTableName)
                                  + N' SET [Process_ID] = @Process_ID WHERE id = @sqlid';

                            exec sys.sp_executesql @Sql, @Params, @Objid, @Process_ID;
                        end;

                    end; -- version is different

                end; -- object exist in MF and need updating

                if isnull(@Objid, 0) <= 0
                begin
                    set @ProcedureStep = 'Create new object';

                    set @DebugText = N' Objids ' + coalesce(@ObjIDs, 'null');
                    set @DebugText = @DefaultDebugText + @DebugText;

                    set @isNewObject = 1;

                    if @Debug > 0
                    begin
                        raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    end;

                    set @ProcedureStep = ' reset process_ID and create new object';
                    set @Params = N'@sqlid int';
                    set @Sql = N'UPDATE ' + quotename(@MFTableName) + N' SET [Process_ID] = 1 WHERE id = @sqlid';

                    exec sys.sp_executesql @Sql, @Params, @Objid;

                    set @DebugText = N' ';
                    set @DebugText = @DefaultDebugText + @DebugText;

                    exec dbo.spMFUpdateTable @MFTableName = @MFTableName
                                           , @UpdateMethod = 0
                                           , @ObjIDs = null
                                           , @Update_IDOut = @Update_IDOut output
                                           , @ProcessBatch_ID = @ProcessBatch_id
                                           , @RetainDeletions = @RetainDeletions
                                           , @IsDocumentCollection = @IsDocumentCollection
                                           , @Debug = @Debug;

                end;





                declare @CreateColumn       nvarchar(100)
                      , @LastModifiedColumn nvarchar(100)
                      , @CreateDate         datetime
                      , @lastModified       datetime;

                select @CreateColumn = ColumnName
                from dbo.MFProperty
                where MFID = 20;

                select @LastModifiedColumn = ColumnName
                from dbo.MFProperty
                where MFID = 21;



                set @ProcedureStep = ' Update variables';
                set @Params
                    = N'@SQLID int, @Objid int output,@ObjectVersion int output, @CreateDate datetime output, @lastModified datetime output
                    , @Single_file int output, @FileCount int output ';
                set @Sql
                    = N' SELECT @Objid = objid,  @ObjectVersion = MFVersion, @CreateDate = ' + quotename(@CreateColumn)
                      + N'
                        , @lastModified = ' + quotename(@LastModifiedColumn)
                      + N' 
                    ,@Single_file = Single_file, @FileCount = Filecount 
                        from ' + quotename(@MFTableName) + N' where id = @SQLid;';

                --                            PRINT @Sql;
                exec sys.sp_executesql @Sql
                                     , @Params
                                     , @SQLID
                                     , @Objid output
                                     , @ObjectVersion output
                                     , @CreateDate output
                                     , @lastModified output
                                     , @Single_File output
                                     , @FileCount output;

                if @Debug > 0
                begin
                    select @Objid         as Objid
                         , @ObjIDs        as Objids
                         , @ObjectVersion as Version
                         , @CreateDate    as CreateDate
                         , @lastModified  as LastModified
                         , @Single_File   as single_file
                         , @FileCount     as filecount;
                end;


                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;
                -----------------------------------------------------
                --Creating the xml 
                ----------------------------------------------------
                declare @Query nvarchar(max);

                set @ProcedureStep = 'Prepare ColumnValue pair';

                declare @ColumnValuePair table
                (
                    ColunmName nvarchar(200)
                  , ColumnValue nvarchar(4000)
                  , Required bit ---Added for checking Required property for table
                );

                declare @TableWhereClause varchar(1000)
                      , @tempTableName    varchar(1000)
                      , @XMLFile          xml;

                set @TableWhereClause = 'y.ID = ' + cast(@SQLID as varchar(20));
                --+'  

                --IF @Debug > 0
                --    PRINT @TableWhereClause;

                ----------------------------------------------------------------------------------------------------------
                --Generate query to get column values as row value
                ----------------------------------------------------------------------------------------------------------
                set @ProcedureStep = 'Prepare query';

                select @Query
                    = stuff(
                      (
                          select ' UNION ' + 'SELECT ''' + COLUMN_NAME + ''' as name, CONVERT(VARCHAR(max),['
                                 + COLUMN_NAME + ']) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                 + isnull('  WHERE ' + @TableWhereClause, '')
                          from INFORMATION_SCHEMA.COLUMNS
                          where TABLE_NAME = @MFTableName
                          for xml path('')
                      )
                    , 1
                    , 7
                    , ''
                           );

                --IF @Debug > 0
                --    PRINT @Query;
                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                -----------------------------------------------------
                --List of columns to exclude
                -----------------------------------------------------
                set @ProcedureStep = 'Prepare exclusion list';

                declare @ExcludeList as table
                (
                    ColumnName varchar(100)
                );

                insert into @ExcludeList
                (
                    ColumnName
                )
                select mp.ColumnName
                from dbo.MFProperty as mp
                where mp.MFID in ( 21, 23, 25, 27 );

                -----------------------------------------------------
                --Insert to values INTo temp table
                -----------------------------------------------------
                --               PRINT @Query;
                set @ProcedureStep = 'Execute query';

                delete from @ColumnValuePair;

                insert into @ColumnValuePair
                exec (@Query);

                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                    select 'afterinsert'
                         , *
                    from @ColumnValuePair as cvp;
                end;

                ---------------------------------------------------------------
                ---- update single file where new object
                ---------------------------------------------------------------
                --   set @ProcedureStep = 'Update single file object';

                --   update @ColumnValuePair
                --   set ColumnValue = '1'
                --   where ColunmName = 'Single_File' and @isNewObject = 1 

                -------------------------------------------------------------
                -- remove exclusions
                -------------------------------------------------------------

                set @ProcedureStep = 'Remove exclusions';

                delete from @ColumnValuePair
                where ColunmName in
                      (
                          select el.ColumnName from @ExcludeList as el
                      );

                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                ----------------------	 Add for checking Required property--------------------------------------------
                set @ProcedureStep = 'Check for required properties';

                update CVP
                set CVP.Required = CP.Required
                from @ColumnValuePair              CVP
                    inner join dbo.MFProperty      P
                        on CVP.ColunmName = P.ColumnName
                    inner join dbo.MFClassProperty CP
                        on P.ID = CP.MFProperty_ID
                    inner join dbo.MFClass         C
                        on CP.MFClass_ID = C.ID
                where C.TableName = @MFTableName;

                update @ColumnValuePair
                set ColumnValue = 'ZZZ'
                where Required = 1
                      and ColumnValue is null;

                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    select *
                    from @ColumnValuePair as cvp;

                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                ------------------	 Add for checking Required property------------------------------------
                set @ProcedureStep = 'Convert datatime';

                delete from @ColumnValuePair
                where ColumnValue is null;

                update cp
                set cp.ColumnValue = convert(datetime, cast(cp.ColumnValue as nvarchar(100)))
                from @ColumnValuePair                     as cp
                    inner join INFORMATION_SCHEMA.COLUMNS as c
                        on c.COLUMN_NAME = cp.ColunmName
                where c.DATA_TYPE = 'datetime'
                      and cp.ColumnValue is not null;

                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                --           SELECT @Objid AS [ObjID];
                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                set @ProcedureStep = 'Creating XML';
                -----------------------------------------------------
                --Generate xml file -- 
                -----------------------------------------------------
                --SELECT *
                --FROM @ColumnValuePair;
                set @XMLFile =
                (
                    select @ObjectTypeID  as [Object/@id]
                         , @SQLID         as [Object/@sqlID]
                         , @Objid         as [Object/@objID]
                         , @ObjectVersion as [Object/@objVesrion]
                         , 0              as [Object/@DisplayID]
                         , (
                               select
                                   (
                                       select top 1
                                              tmp.ColumnValue
                                       from @ColumnValuePair         as tmp
                                           inner join dbo.MFProperty as mfp
                                               on mfp.ColumnName = tmp.ColunmName
                                       where mfp.MFID = 100
                                   ) as [class/@id]
                                 , (
                                       select mfp.MFID as [property/@id]
                                            , (
                                                  select MFTypeID from dbo.MFDataType where ID = mfp.MFDataType_ID
                                              )        as [property/@dataType]
                                            , case
                                                  when tmp.ColumnValue = 'ZZZ' then
                                                      null
                                                  else
                                                      tmp.ColumnValue
                                              end      as 'property' ----Added case statement for checking Required property
                                       from @ColumnValuePair         as tmp
                                           inner join dbo.MFProperty as mfp
                                               on mfp.ColumnName = tmp.ColunmName
                                       where mfp.MFID <> 100
                                             and tmp.ColumnValue is not null --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                       for xml path(''), type
                                   ) as class
                               for xml path(''), type
                           )              as Object
                    for xml path(''), root('form')
                );
                set @XMLFile =
                (
                    select @XMLFile.query('/form/*')
                );
                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                    select @XMLFile as XMLFileForImport;
                end;

                set @ProcedureStep = 'Prepare XML out';
                set @Sql = N'';
                ;

                -------------------------------------------------------------------
                --Importing File into M-Files using Connector
                -------------------------------------------------------------------
                set @ProcedureStep = 'Importing file';

                declare @XMLStr   nvarchar(max)
                      , @Result   nvarchar(max)
                      , @ErrorMsg nvarchar(max);

                set @XMLStr = N'<form>' + cast(@XMLFile as nvarchar(max)) + N'</form>';
                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                    select @FileName as filename;

                    --              SELECT CAST(@XML AS XML) AS '@XML Length';
                    select @XMLStr as '@XMLStr';

                    select @FileLocation as filelocation;
                end;

                begin try

                exec dbo.spMFSynchronizeFileToMFilesInternal @VaultSettings
                                                           , @FileName
                                                           , @XMLStr
                                                           , @FileLocation
                                                           , @Result out
                                                           , @ErrorMsg out
                                                           , @IsFileDelete;

            end try
            begin catch

            set @Result = coalesce(@Result,' spMFSynchronizeFileToMFilesInternal failed') + isnull(@ErrorMsg,' - no error message')
                                       
                                       SET @LogTypeDetail = 'Status';
                                       SET @LogStatusDetail = 'Error';
                                       SET @LogTextDetail = ' Filename ' + @FileName + ' : ' + @Result
                                       SET @LogColumnName = '';
                                       SET @LogColumnValue = '';
            
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

            end catch
            


                if @Debug > 0
                begin
                    select cast(@Result as xml) as Result;

                    select len(@ErrorMsg) as errorlength
                         , @ErrorMsg      as errormsg;
                end;


                set @LogTypeDetail = N'Status';
                set @LogStatusDetail = N'Imported';
                set @LogTextDetail
                    = N' ' + isnull(@FileName, 'No File') + N'; ' + isnull(@FileLocation, 'No location') + N'; '
                      + isnull(@ErrorMsg,'');
                set @LogColumnName = N'Objid ';
                set @LogColumnValue = cast(@Objid as varchar(10));

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id
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

     set @ProcedureStep = 'Error reporting';
                -------------------------------------------------------------
                -- Set error message
                -------------------------------------------------------------
                begin
                    select @Start = case
                                        when charindex(@SearchTerm, @ErrorMsg, 1) > 0 then
                                            charindex(@SearchTerm, @ErrorMsg, 1) + len(@SearchTerm)
                                        else
                                            1
                                    end;

                    select @End = case
                                      when charindex(@SearchTerm, @ErrorMsg, @Start) < 50 then
                                          100
                                      else
                                          charindex(@SearchTerm, @ErrorMsg, @Start)
                                  end;

                    select @Start = isnull(@Start, 1)

                    select @length = isnull(@End, 50) - @Start;

                    select @ErrorMsg =  substring(isnull(@ErrorMsg,'No error message'), @Start, @length);
                end;

                 
                set @DebugText = N' %s';
                set @DebugText = @DefaultDebugText + @DebugText;

                 if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@ErrorMsg);

                    select @start start, @length length;

                end;

                -------------------------------------------------------------
                -- update log
                -------------------------------------------------------------
      
 set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;
                set @ProcedureStep = 'Insert result in MFFileImport table';

           

                declare @ResultXml xml;

                set @ResultXml = cast(@Result as xml);

                     if @Debug > 0
                begin
                select @ResultXml as FileImportResult;
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                create table #TempFileDetails
                (
                    FileName nvarchar(200)
                  , FileUniqueRef varchar(100)
                  , MFCreated datetime
                  , MFLastModified datetime
                  , ObjID int
                  , ObjVer int
                  , FileObjectID int
                  , FileCheckSum nvarchar(max)
                  , ImportError nvarchar(4000)
                );

                if isnull(@Result,'') > '' 
                begin            

                insert into #TempFileDetails
                (
                    FileName
                  , FileUniqueRef
                  , MFCreated
                  , MFLastModified
                  , ObjID
                  , ObjVer
                  , FileObjectID
                  , FileCheckSum
                  , ImportError
                )
               
                 select t.c.value('(@FileName)[1]', 'NVARCHAR(200)')     as FileName
                     , coalesce(@FileLocation, null)
                     --          ,[t].[c].[value](''(@FileUniqueRef)[1]'', ''VARCHAR(100)'') AS [FileUniqueRef]
                     , t.c.value('(@MFCreated)[1]', 'datetime')         as MFCreated
                     , t.c.value('(@MFLastModified)[1]', 'datetime')    as MFLastModified
                     , t.c.value('(@ObjID)[1]', 'INT')                  as ObjID
                     , t.c.value('(@ObjVer)[1]', 'INT')                 as ObjVer
                     , t.c.value('(@FileObjectID)[1]', 'INT')           as FileObjectID
                     , t.c.value('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') as FileCheckSum
                     , case
                           when len(@ErrorMsg) = 0 and not exists(select objid from dbo.MFFileImport as mfi where objid = t.c.value('(@ObjID)[1]', 'INT') and mfi.FileName = t.c.value('(@FileName)[1]', 'NVARCHAR(200)')) 
                           then
                               'Success'
when len(@ErrorMsg) = 0 and exists(select objid from dbo.MFFileImport as mfi where objid = t.c.value('(@ObjID)[1]', 'INT') and mfi.FileName = t.c.value('(@FileName)[1]', 'NVARCHAR(200)')) 
then 'file already exists'
                           else
                               @ErrorMsg
                       end                                              as ImportError
                from @ResultXml.nodes('/form/Object') as t(c);
               
end

 if isnull(@Result,'') = '' 
                begin         

                insert into #TempFileDetails
                (
                    FileName
                  , FileUniqueRef
             --     , MFCreated
             --     , MFLastModified
                  , ObjID
                  , ObjVer
            --      , FileObjectID
            --      , FileCheckSum
                  , ImportError
                )
                Select @FileName, @FileLocation, @Objid
                  , @ObjectVersion
                  , ImportError = @ErrorMsg
    End           


                if @Debug > 0
                begin
                    select *
                    from #TempFileDetails as tfd
                    where tfd.ObjID = @Objid;
                end;

                set @ProcedureStep = 'Update / insert record in MFFileImport';

                merge into dbo.MFFileImport t

                using 

                ( select substring([FileName], 1, 100) [Filename]
                         , FileUniqueRef
                         , getutcdate() createdOn
                         , @MFTableName SourceName
                         , @TargetClassMFID TargetClassID
                         , getutcdate()  MFCreated
                         ,  getutcdate()  MFLastModified
                         , ObjID
                         , ObjVer Version
                         , FileObjectID
                         , FileCheckSum
                         , ImportError
                    from #TempFileDetails
                    ) as s
                    on  s.FileUniqueRef = t.FileUniqueRef
                               and s.FileName = t.FileName
                               and s.ObjID = t.ObjID
                               and s.FileObjectID = t.FileObjectID
                when matched then update
                Set
                
                       t.ObjID = s.ObjID
                      , t.Version = s.Version
                      , t.fileObjectID = s.fileObjectID
                      , t.fileCheckSum = s.fileCheckSum
                      , t.ImportError = s.ImportError
                when not matched then insert
                (    FileName
                      , FileUniqueRef
                      , CreatedOn
                      , SourceName
                      , TargetClassID
                      , MFCreated
                      , MFLastModified
                      , ObjID
                      , Version
                      , FileObjectID
                      , FileCheckSum
                      , ImportError)
                values
                    ( s.FileName
                      , s.FileUniqueRef
                      , s.CreatedOn
                      , s.SourceName
                      , s.TargetClassID
                      , s.MFCreated
                      , s.MFLastModified
                      , s.ObjID
                      , s.Version
                      , s.FileObjectID
                      , s.FileCheckSum
                      , s.ImportError)
                      ;

                drop table #TempFileDetails;

                if
                (
                    select object_id(@tempTableName)
                ) is not null
                    exec ('Drop table ' + @TempFile);

                set @ProcedureStep = 'update from M-Files';
                set @Sql = N' Synchronizing records  from M-files to the target ' + @MFTableName;

                execute @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id
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
                                                                        , @debug = 0;

                -------------------------------------------------------------------
                --Synchronizing target Object from M-Files
                -------------------------------------------------------------------
                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;
                set @ProcedureStep = 'Synchronizing target Object from M-Files';

                set @ObjIDs = cast(@Objid as nvarchar(100));

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                if @ObjIDs is not null
                begin
                    exec dbo.spMFUpdateTable @MFTableName = @MFTableName
                                           , @UpdateMethod = 1
                                           , @ObjIDs = @ObjIDs
                                           , @Update_IDOut = @Update_IDOut output
                                           , @ProcessBatch_ID = @ProcessBatch_id
                                           , @Debug = 0;

                end;

                if @ResetToSingleFile = 1 and len(@ErrorMsg) = 0

                begin

                set @DebugText = N'';
                set @DebugText = @DefaultDebugText + @DebugText;
                set @ProcedureStep = 'Reset object to single';

                set @ObjIDs = cast(@Objid as nvarchar(100));

                if @Debug > 0
                begin
                    raiserror(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                end;

                    set @Sql
                        = N'
                    UPDATE mc
SET mc.Single_File = 1, mc.Process_ID = 1
FROM ' +            quotename(@MFTableName)
                          + N' AS mc
WHERE ISNULL(mc.FileCount,0) = 1 AND Single_File = 0 AND Objid = @objid;';

                    exec sys.sp_executesql @Sql, N'@objid int', @Objid;

                    exec dbo.spMFUpdateTable @MFTableName = @MFTableName
                                           , @UpdateMethod = 0
                                           , @ObjIDs = @ObjIDs
                                           , @Update_IDOut = @Update_IDOut output
                                           , @ProcessBatch_ID = @ProcessBatch_id;
                end; --reset to single

            end; --SQLID is valid
        end; -- sql id does not exist



    end try
    begin catch
        set @StartTime = getutcdate();
        set @LogStatus = N'Failed w/SQL Error';
        set @LogTextDetail = error_message();
        set @ErrorMsg = error_message();

        -------------------------------------------------------------
        -- Set error message
        -------------------------------------------------------------
        begin
            select @Start = case
                                when charindex(@SearchTerm, @ErrorMsg, 1) > 0 then
                                    charindex(@SearchTerm, @ErrorMsg, 1) + len(@SearchTerm)
                                else
                                    1
                            end;

            select @End = case
                              when charindex(@SearchTerm, @ErrorMsg, @Start) < 50 then
                                  50
                              else
                                  charindex(@SearchTerm, @ErrorMsg, @Start)
                          end;

            select @length = @End - @Start;

            select @ErrorMsg = substring(@ErrorMsg, isnull(@Start, 1), isnull(@length, 1));
        end;

        -------------------------------------------------------------
        -- update error in table
        -------------------------------------------------------------
        if exists
        (
            select top 1
                   *
            from dbo.MFFileImport
            where FileUniqueRef = @FileID
                  and TargetClassID = @TargetClassMFID
        )
        begin
            update FI
            set FI.FileName = @FileName
              , FI.FileUniqueRef = @FileLocation
              , FI.MFCreated = FI.MFCreated
              , FI.MFLastModified = getdate()
              , FI.ObjID = @Objid
              , FI.Version = @ObjectVersion
              , FI.FileObjectID = null
              , FI.FileCheckSum = null
              , FI.ImportError = @ErrorMsg
            from dbo.MFFileImport FI
            where FI.ObjID = @Objid
                  and FI.FileName = @FileName
                  and FI.FileUniqueRef = @FileLocation;
        --INNER JOIN [#TempFileDetails] [FD]
        --    ON [FI].[FileUniqueRef] = [FD].[FileUniqueRef];
        end;
        else
        begin
            insert into dbo.MFFileImport
            (
                FileName
              , FileUniqueRef
              , CreatedOn
              , SourceName
              , TargetClassID
              , MFCreated
              , MFLastModified
              , ObjID
              , ImportError
            )
            values
            (@FileName, @FileLocation, getdate(), @MFTableName, @TargetClassMFID, null, null, @Objid, @ErrorMsg);
        end;

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

        set @ProcedureStep = 'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        exec dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id output
                                       , @ProcessType = @ProcessType
                                       , @LogType = N'Error'
                                       , @LogText = @LogTextDetail
                                       , @LogStatus = @LogStatus
                                       , @debug = 0;

        set @StartTime = getutcdate();

        exec dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id
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