PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFUpdateMFilesToMFSQL]';

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateMFilesToMFSQL' -- nvarchar(100)
                                    ,@Object_Release = '4.4.13.53'            -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint



IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateMFilesToMFSQL' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateMFilesToMFSQL]
AS
BEGIN
    SELECT 'created, but not implemented yet.'; --just anything will do
END;
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateMFilesToMFSQL]
(
    @MFTableName NVARCHAR(128)
   ,@MFLastUpdateDate SMALLDATETIME = NULL OUTPUT
   ,@UpdateTypeID TINYINT = 1
   ,@MaxObjects INT = 200000
   ,@Update_IDOut INT = NULL OUTPUT
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@debug TINYINT = 0
)
AS
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

Examples
========

.. code:: sql

    --Full Update from MF to SQL

    DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

    EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable'               -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
                                    ,@UpdateTypeID = 0                            -- tinyint
                                    ,@Update_IDOut = @Update_IDOut OUTPUT         -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT   -- int
                                    ,@debug = 0;                                  -- tinyint

    SELECT @MFLastUpdateDate AS [LastModifiedDate];

    DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut     INT
       ,@ProcessBatch_ID  INT;

    EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'YourTable'               -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
                                    ,@UpdateTypeID = 1                            -- tinyint
                                    ,@Update_IDOut = @Update_IDOut OUTPUT         -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT   -- int
                                    ,@debug = 0;                                  -- tinyint

    SELECT @MFLastUpdateDate;


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
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
2017-06-08  AC         ProcessBatch_ID not passed into spMFAuditTable
2016-08-11  AC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFUpdateMFilesToMFSQL';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Set Variables';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';

    --used on MFProcessBatch;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType AS NVARCHAR(50) = 'Status';
    DECLARE @LogText AS NVARCHAR(4000) = '';
    DECLARE @LogStatus AS NVARCHAR(50) = 'Started';

    --used on MFProcessBatchDetail;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = 'Debug';
    DECLARE @LogTextDetail AS NVARCHAR(4000) = @ProcedureStep;
    DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
    DECLARE @EndTime DATETIME;
    DECLARE @StartTime DATETIME;
    DECLARE @StartTime_Total DATETIME = GETUTCDATE();
    DECLARE @Validation_ID INT;
    DECLARE @LogColumnName NVARCHAR(128);
    DECLARE @LogColumnValue NVARCHAR(256);
    DECLARE @RunTime AS DECIMAL(18, 4) = 0;
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    DECLARE @error AS INT = 0;
    DECLARE @output NVARCHAR(200);
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    -------------------------------------------------------------
    -- Global Constants
    -------------------------------------------------------------
    DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
    DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
    DECLARE @UpdateType_0_FullRefresh TINYINT = 0;
    DECLARE @UpdateType_1_Incremental TINYINT = 1;
    DECLARE @UpdateType_2_Deletes TINYINT = 2;
    DECLARE @MFLastModifiedDate DATETIME;
    DECLARE @DeletedInSQL   INT
           ,@UpdateRequired BIT
           ,@OutofSync      INT
           ,@ProcessErrors  INT
           ,@Class_ID       INT
           ,@DefaultToObjid INT = 200000;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[MFClass] WHERE [TableName] = @MFTableName)
        BEGIN
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Start procedure';

            IF @debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- Get/Validate ProcessBatch_ID
            SET @ProcedureStep = 'Initialise M-Files to MFSQL';

            EXEC @return_value = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                                                ,@ProcessType = 'UpdateMFilesToMFSQL'
                                                                ,@LogText = @ProcedureStep
                                                                ,@LogStatus = 'Started'
                                                                ,@debug = @debug;

            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = 'Status';
            SET @LogTextDetail = CASE
                                     WHEN @UpdateTypeID = 0 THEN
                                         'UpdateType full refresh'
                                     ELSE
                                         'UpdateType incremental refresh'
                                 END;
            SET @LogStatusDetail = 'Started';
            SET @LogColumnName = '';
            SET @LogColumnValue = '';

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                      ,@LogType = @LogTypeDetail
                                                      ,@LogText = @LogTextDetail
                                                      ,@LogStatus = @LogStatusDetail
                                                      ,@StartTime = @StartTime
                                                      ,@MFTableName = @MFTableName
                                                      ,@ColumnName = @LogColumnName
                                                      ,@ColumnValue = @LogColumnValue
                                                      ,@LogProcedureName = @ProcedureName
                                                      ,@LogProcedureStep = @ProcedureStep
                                                      ,@debug = @debug;

            /*************************************************************************************
	REFRESH M-FILES --> MFSQL	 (Process Codes: M2E2M | M2E | E2M2E | E2M ) --All Process Codes
*************************************************************************************/
            -------------------------------------------------------------
            -- Get column for last modified
            -------------------------------------------------------------
            DECLARE @lastModifiedColumn NVARCHAR(100);

            SELECT @lastModifiedColumn = [mp].[ColumnName]
            FROM [dbo].[MFProperty] AS [mp]
            WHERE [mp].[MFID] = 21;

            --'Last Modified'

            -------------------------------------------------------------
            -- Get last modified date
            -------------------------------------------------------------
            SET @ProcedureStep = 'Get last update date';
            SET @sqlParam = N'@MFLastModifiedDate Datetime output';
            SET @sql
                = N'
SELECT @MFLastModifiedDate = (SELECT MAX(' + QUOTENAME(@lastModifiedColumn) + ') FROM ' + QUOTENAME(@MFTableName)
                  + ' );';

            EXEC [sys].[sp_executesql] @Stmt = @sql
                                      ,@Params = @sqlParam
                                      ,@MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

            SET @MFLastModifiedDate = CASE
                                          WHEN @UpdateTypeID = @UpdateType_2_Deletes THEN
                                              NULL
                                          ELSE
                                              ISNULL(DATEADD(DAY, -1, @MFLastModifiedDate), '2000-01-01')
                                      END;
            SET @DebugText = 'Filter Date: ' + CAST(@MFLastModifiedDate AS NVARCHAR(100));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- Determine the overall size of the object type index
            -------------------------------------------------------------
            DECLARE @NewObjectXml NVARCHAR(MAX);
            DECLARE @StatusFlag_1_MFilesIsNewer TINYINT = 1;
            DECLARE @StatusFlag_5_NotInMFSQL TINYINT = 5;
			DECLARE @StatusFlag_6_NotInMFSQL TINYINT = 6;


            -------------------------------------------------------------
            -- Get class id
            -------------------------------------------------------------
            SELECT @Class_ID = [mc].[MFID]
            FROM [dbo].[MFClass] AS [mc]
            WHERE [mc].[TableName] = @MFTableName;

            -------------------------------------------------------------
            -- Reset errors 3 and 4
            -------------------------------------------------------------
            SET @ProcedureStep = 'Reset errors 3 and 4';
            SET @sql = N'UPDATE [t]
                    SET process_ID = 0
                    FROM [dbo].' + QUOTENAME(@MFTableName) + ' AS t WHERE [t].[Process_ID] IN (3,4)';

            EXEC (@sql);

            -------------------------------------------------------------
            -- FULL REFRESH
            -------------------------------------------------------------
            BEGIN
                DECLARE @MFAuditHistorySessionID INT = NULL;

                IF @UpdateTypeID = (@UpdateType_0_FullRefresh)
                   --AND
                   --(
                   --    SELECT COUNT(*)
                   --    FROM [dbo].[MFAuditHistory] AS [mah]
                   --    WHERE [mah].[Class] = @Class_ID
                   --) = 0
                BEGIN
                    SET @StartTime = GETUTCDATE();
                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Start full refresh';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    -------------------------------------------------------------
                    -- o/s switch to batch when the class table is too large
                    -------------------------------------------------------------  
                    DECLARE @Tobjid INT;

                    SELECT @Tobjid = MAX([mah].[ObjID])
                    FROM [dbo].[MFAuditHistory] AS [mah]
                    WHERE [mah].[Class] = @Class_ID;

                    IF @Tobjid IS NULL
                    BEGIN
                        EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = @MFTableName -- nvarchar(100)
                                                            ,@FromObjid = 1              -- int
                                                            ,@ToObjid = @DefaultToObjid  -- int
                                                            ,@WithStats = 0              -- bit
                                                            ,@ProcessBatch_ID = @ProcessBatch_ID
                                                            ,@Debug = @debug;            -- int
     END
	 ELSE 
	 BEGIN
     
	  EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = @MFTableName -- nvarchar(100)
                                                            ,@FromObjid = 1              -- int
                                                            ,@ToObjid = @Tobjid  -- int
                                                            ,@WithStats = 0              -- bit
                                                            ,@ProcessBatch_ID = @ProcessBatch_ID
                                                            ,@Debug = @debug;            -- int


END

                        SET @ProcedureStep = 'Get Object Versions with Batch Audit';
                        SET @StartTime = GETUTCDATE();
                        SET @LogTypeDetail = 'Status';
                        SET @LogTextDetail = ' Batch Audit Max Object: ' + CAST(@DefaultToObjid AS VARCHAR(30));
                        SET @LogStatusDetail = 'In progress';
                        SET @LogColumnName = '';
                        SET @LogColumnValue = '';

                        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                  ,@LogType = @LogTypeDetail
                                                                  ,@LogText = @LogTextDetail
                                                                  ,@LogStatus = @LogStatusDetail
                                                                  ,@StartTime = @StartTime
                                                                  ,@MFTableName = @MFTableName
                                                                  ,@ColumnName = @LogColumnName
                                                                  ,@ColumnValue = @LogColumnValue
                                                                  ,@LogProcedureName = @ProcedureName
                                                                  ,@LogProcedureStep = @ProcedureStep
                                                                  ,@debug = @debug;
               

                    -------------------------------------------------------------
                    -- class table update in batches
                    -------------------------------------------------------------

                    SET @Tobjid = ISNULL(@Tobjid, 0) + 500;
                    SET @DebugText = 'Max Objid %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Set Max objid';

                    IF @debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Tobjid);
                    END;

                    SET @ProcedureStep = 'class table update in batches';
                    SET @LogTypeDetail = 'Debug';
                    SET @LogTextDetail = ' Start Update in batches: Max objid ' + CAST(@Tobjid AS NVARCHAR(256));
                    SET @LogColumnName = '';
                    SET @LogColumnValue = '';

                    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              ,@LogType = @LogTypeDetail
                                                              ,@LogText = @LogTextDetail
                                                              ,@LogStatus = @LogStatusDetail
                                                              ,@StartTime = @StartTime
                                                              ,@MFTableName = @MFTableName
                                                              ,@ColumnName = @LogColumnName
                                                              ,@ColumnValue = @LogColumnValue
                                                              ,@LogProcedureName = @ProcedureName
                                                              ,@LogProcedureStep = @ProcedureStep
                                                              ,@debug = @debug;

                    EXEC @return_value = [dbo].[spMFUpdateTableinBatches] @MFTableName = @MFTableName -- nvarchar(100)
                                                                         ,@UpdateMethod = 1           -- int
                                                                         ,@WithTableAudit =1         -- int
                                                                         ,@FromObjid = 1              -- bigint
                                                                         ,@ToObjid = @Tobjid          -- bigint
                                                                         ,@WithStats = 0              -- bit
                                                                         ,@ProcessBatch_ID = @ProcessBatch_ID
                                                                         ,@Debug = @debug;            -- int

                    SET @error = @@Error;
                    SET @LogStatusDetail = CASE
                                               WHEN
                                               (
                                                   @error <> 0
                                                   OR @return_value = -1
                                               ) THEN
                                                   'Failed'
                                               WHEN @return_value IN ( 1, 0 ) THEN
                                                   'Complete'
                                               ELSE
                                                   'Exception'
                                           END;
                    SET @LogTypeDetail = 'Debug';
                    SET @LogTextDetail = ' Batch updates completed ';
                    SET @LogColumnName = '';
                    SET @LogColumnValue = '';

                    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              ,@LogType = @LogTypeDetail
                                                              ,@LogText = @LogTextDetail
                                                              ,@LogStatus = @LogStatusDetail
                                                              ,@StartTime = @StartTime
                                                              ,@MFTableName = @MFTableName
                                                              ,@ColumnName = @LogColumnName
                                                              ,@ColumnValue = @LogColumnValue
                                                              ,@LogProcedureName = @ProcedureName
                                                              ,@LogProcedureStep = @ProcedureStep
                                                              ,@debug = @debug;
                END; -- full update with no audit details

				-------------------------------------------------------------
                -- Incremental update
                -------------------------------------------------------------
                IF (
                       @UpdateTypeID = (@UpdateType_0_FullRefresh)
                       AND
                       (
                           SELECT COUNT(*)
                           FROM [dbo].[MFAuditHistory] AS [mah]
                           WHERE [mah].[Class] = @Class_ID
                       ) > 0
                   )
                   OR (@UpdateTypeID IN ( @UpdateType_1_Incremental, @UpdateType_2_Deletes ))
                BEGIN

                    -------------------------------------------------------------
                    -- perform table audit on with date filter
                    -------------------------------------------------------------
                    DECLARE @SessionIDOut INT;

                    IF @debug > 0
                        SELECT @MFLastModifiedDate AS [last_modified_date];

                    SET @ProcedureStep = 'Get Filtered Object Versions';
                    SET @StartTime = GETUTCDATE();
                    SET @LogTypeDetail = 'Status';
                    SET @LogTextDetail
                        = ' Last modified: ' + CAST(CONVERT(DATETIME, @MFLastModifiedDate, 105) AS VARCHAR(30));
                    SET @LogStatusDetail = 'In progress';
                    SET @LogColumnName = '';
                    SET @LogColumnValue = '';

                    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              ,@LogType = @LogTypeDetail
                                                              ,@LogText = @LogTextDetail
                                                              ,@LogStatus = @LogStatusDetail
                                                              ,@StartTime = @StartTime
                                                              ,@MFTableName = @MFTableName
                                                              ,@ColumnName = @LogColumnName
                                                              ,@ColumnValue = @LogColumnValue
                                                              ,@LogProcedureName = @ProcedureName
                                                              ,@LogProcedureStep = @ProcedureStep
                                                              ,@debug = @debug;

                    EXEC [dbo].[spMFTableAudit] @MFTableName = @MFTableName                -- nvarchar(128)
                                               ,@MFModifiedDate = @MFLastModifiedDate      -- datetime
                                               ,@ObjIDs = NULL                             -- nvarchar(4000)
                                               ,@SessionIDOut = @SessionIDOut              -- int
                                               ,@NewObjectXml = @NewObjectXml OUTPUT       -- nvarchar(max)
                                               ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
                                               ,@UpdateRequired = @UpdateRequired OUTPUT   -- bit
                                               ,@OutofSync = @OutofSync OUTPUT             -- int
                                               ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
                                               ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                               ,@Debug = @debug;                           -- smallint
                END;

                SELECT @Tobjid = MAX([mah].[ObjID])
                FROM [dbo].[MFAuditHistory] AS [mah]
                WHERE [mah].[Class] = @Class_ID;

                SET @Tobjid = ISNULL(@Tobjid, 0) + 500;
                SET @DebugText = 'Max Objid %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Update M-Files';

                IF @debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Tobjid);
                END;


             

                    SELECT @rowcount = COUNT(*)
                    FROM [dbo].[MFAuditHistory]
                    WHERE [Class] = @Class_ID
                          AND [StatusFlag] IN ( @StatusFlag_1_MFilesIsNewer,4, @StatusFlag_5_NotInMFSQL,@StatusFlag_6_NotInMFSQL )
                          AND [ObjectType] <> 9;

                        SET @LogColumnName = 'Status flag 1,4, 5 and 6:  ';
                        SET @LogColumnValue = CAST(@rowcount AS NVARCHAR(256));
                        SET @LogStatusDetail = CASE
                                                   WHEN
                                                   (
                                                       @error <> 0
                                                       OR @return_value = -1
                                                   ) THEN
                                                       'Failed'
                                                   WHEN @return_value IN ( 1, 0 ) THEN
                                                       'Completed'
                                                   ELSE
                                                       'Exception'
                                               END;
                        SET @LogTextDetail = ' Object Versions update start';

                        EXEC @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                                  ,@LogType = @LogTypeDetail
                                                                                  ,@LogText = @LogTextDetail
                                                                                  ,@LogStatus = @LogStatusDetail
                                                                                  ,@StartTime = @StartTime
                                                                                  ,@MFTableName = @MFTableName
                                                                                  ,@ColumnName = @LogColumnName
                                                                                  ,@ColumnValue = @LogColumnValue
                                                                                  ,@LogProcedureName = @ProcedureName
                                                                                  ,@LogProcedureStep = @ProcedureStep
                                                                                  ,@debug = @debug;
				
				-------------------------------------------------------------
				-- object versions updated
				-------------------------------------------------------------

				-------------------------------------------------------------
				-- Get list of objects to update
				-------------------------------------------------------------
				    IF @rowcount > 0
                    BEGIN

                        SET @ProcedureStep = 'Create Class table objid list';



                        IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
                            DROP TABLE [#ObjIdList];

                        CREATE TABLE [#ObjIdList]
                        (
                            [ObjId] INT
                        );

                        INSERT [#ObjIdList]
                        (
                            [ObjId]
                        )
                        SELECT [ObjID]
                        FROM [dbo].[MFAuditHistory]
                        WHERE  [StatusFlag] IN ( @StatusFlag_1_MFilesIsNewer, 4, @StatusFlag_5_NotInMFSQL,@StatusFlag_6_NotInMFSQL ) AND [Class] = @Class_ID;

                        SET @rowcount = @@RowCount;

                        IF @debug > 9
                        BEGIN
						SELECT * FROM [#ObjIdList] AS [oil]
                            SET @DebugText = @DefaultDebugText + ' %i Object list record(s) ';

                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                        END;

                        -------------------------------------------------------------
                        -- Group object list
                        -------------------------------------------------------------
                        SET @ProcedureStep = 'Group ObjID Lists';

                        IF OBJECT_ID('tempdb..#ObjIdGroups') IS NOT NULL
                            DROP TABLE [#ObjIdGroups];

                        CREATE TABLE [#ObjIdGroups]
                        (
                            [GroupNumber] INT PRIMARY KEY
                           ,[ObjIds] NVARCHAR(4000)
                        );

                        INSERT [#ObjIdGroups]
                        (
                            [GroupNumber]
                           ,[ObjIds]
                        )
                        EXEC [dbo].[spMFUpdateTable_ObjIds_GetGroupedList] @Debug = @debug;

                        SET @rowcount = @@RowCount;

                        IF @debug > 9
                        BEGIN
                            SET @DebugText = @DefaultDebugText + ' %d group(s) ';

                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                        END;

                        --Loop through Groups of ObjIDs
                        DECLARE @CurrentGroup    INT
                               ,@ObjIds_toUpdate NVARCHAR(4000);

                        SELECT @CurrentGroup = MIN([GroupNumber])
                        FROM [#ObjIdGroups];

                        WHILE @CurrentGroup IS NOT NULL
                        BEGIN
                            SELECT @ObjIds_toUpdate = [ObjIds]
                            FROM [#ObjIdGroups]
                            WHERE [GroupNumber] = @CurrentGroup;

                            SET @ProcedureStep = 'spMFUpdateTable UpdateMethod 1';
                            SET @StartTime = GETUTCDATE();
                            SET @LogTextDetail = ' for Group# ' + ISNULL(CAST(@CurrentGroup AS VARCHAR(20)), '(null)');
                            SET @LogStatusDetail = 'Started';
                            SET @LogColumnName = 'Group# ' + ISNULL(CAST(@CurrentGroup AS VARCHAR(20)), '(null)');
                            SET @LogColumnValue =
                            (
                                SELECT CAST(COUNT(*) AS VARCHAR(10))FROM [#ObjIdList] AS [oil]
                            );

                            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                      ,@LogType = @LogTypeDetail
                                                                      ,@LogText = @LogTextDetail
                                                                      ,@LogStatus = @LogStatusDetail
                                                                      ,@StartTime = @StartTime
                                                                      ,@MFTableName = @MFTableName
                                                                      ,@ColumnName = @LogColumnName
                                                                      ,@ColumnValue = @LogColumnValue
                                                                      ,@LogProcedureName = @ProcedureName
                                                                      ,@LogProcedureStep = @ProcedureStep
                                                                      ,@debug = @debug;

                            IF @debug > 9
                            BEGIN
                                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

                            SET @StartTime = GETUTCDATE();

                            EXEC @return_value = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName
                                                                        ,@UpdateMethod = @UpdateMethod_1_MFilesToMFSQL --M-Files to MFSQL
                                                                        ,@UserId = NULL
                                                                        ,@MFModifiedDate = NULL
                                                                        ,@ObjIDs = @ObjIds_toUpdate                    -- CSV List
                                                                        ,@Update_IDOut = @Update_IDOut OUTPUT
                                                                        ,@ProcessBatch_ID = @ProcessBatch_ID
                                                                        ,@Debug = @debug;

                            SET @error = @@Error;
                            SET @LogStatusDetail = CASE
                                                       WHEN
                                                       (
                                                           @error <> 0
                                                           OR @return_value = -1
                                                       ) THEN
                                                           'Failed'
                                                       WHEN @return_value IN ( 1, 0 ) THEN
                                                           'Completed'
                                                       ELSE
                                                           'Exception'
                                                   END;
                            SET @LogText = 'Return Value: ' + CAST(@return_value AS NVARCHAR(256));
                            SET @LogColumnName = 'MFUpdate_ID ';
                            SET @LogColumnValue = CAST(@Update_IDOut AS NVARCHAR(256));

                            EXEC @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                                      ,@LogType = @LogTypeDetail
                                                                                      ,@LogText = @LogTextDetail
                                                                                      ,@LogStatus = @LogStatusDetail
                                                                                      ,@StartTime = @StartTime
                                                                                      ,@MFTableName = @MFTableName
                                                                                      ,@ColumnName = @LogColumnName
                                                                                      ,@ColumnValue = @LogColumnValue
                                                                                      ,@LogProcedureName = @ProcedureName
                                                                                      ,@LogProcedureStep = @ProcedureStep
                                                                                      ,@debug = @debug;

                            SELECT @CurrentGroup = MIN([GroupNumber])
                            FROM [#ObjIdGroups]
                            WHERE [GroupNumber] > @CurrentGroup;
                        END; --WHILE @CurrentGroup IS NOT NULL	

			
                    END;
                    ELSE
                    BEGIN
                        SET @LogTypeDetail = 'Status';
                        SET @LogStatusDetail = 'In progress';
                        SET @LogTextDetail = 'Nothing to update';
                        SET @LogColumnName = '';
                        SET @LogColumnValue = '';

                        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                                     ,@LogType = @LogTypeDetail
                                                                                     ,@LogText = @LogTextDetail
                                                                                     ,@LogStatus = @LogStatusDetail
                                                                                     ,@StartTime = @StartTime
                                                                                     ,@MFTableName = @MFTableName
                                                                                     ,@Validation_ID = @Validation_ID
                                                                                     ,@ColumnName = @LogColumnName
                                                                                     ,@ColumnValue = @LogColumnValue
                                                                                     ,@Update_ID = @Update_IDOut
                                                                                     ,@LogProcedureName = @ProcedureName
                                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                                     ,@debug = @debug;
                    END; --IF EXISTS(SELECT 1 FROM dbo.MFAuditHistory WHERE SessionId = @SessionID AND StatusFlag IN(1,5)) record count to update > 0

				-------------------------------------------------------------
						-- Remove deletions
				-------------------------------------------------------------

						SET @ProcedureStep = 'Remove deletions'

						EXEC [dbo].[spMFGetDeletedObjects] @MFTableName = @MFTableName      -- nvarchar(200)
						                                  ,@LastModifiedDate = '2000-01-01' -- datetime
						                                  ,@RemoveDeleted = 1    -- bit
						                                  ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT                -- int
						                                  ,@Debug = 0            -- smallint
						
                -------------------------------------------------------------
                -- Get last update date
                -------------------------------------------------------------
                SET @ProcedureStep = 'Get update date for output';
                SET @sqlParam = N'@MFLastModifiedDate Datetime output';
                SET @sql
                    = N'
SELECT @MFLastModifiedDate = (SELECT MAX(' + QUOTENAME(@lastModifiedColumn) + ') FROM ' + QUOTENAME(@MFTableName)
                      + ' );';

                EXEC [sys].[sp_executesql] @Stmt = @sql
                                          ,@Params = @sqlParam
                                          ,@MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

                SET @MFLastUpdateDate = @MFLastModifiedDate;

                -------------------------------------------------------------
                -- end logging
                -------------------------------------------------------------s
                SET @error = @@Error;
                SET @ProcessType = 'Update Tables';
                SET @LogType = 'Debug';
                SET @LogStatusDetail = CASE
                                           WHEN (@error <> 0) THEN
                                               'Failed'
                                           ELSE
                                               'Completed'
                                       END;
                SET @ProcedureStep = 'finalisation';
                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'MF Last Modified: ' + CONVERT(VARCHAR(20), @MFLastUpdateDate, 120);
                --		SET @LogStatusDetail = 'Completed'
                SET @LogColumnName = @MFTableName;
                SET @LogColumnValue = '';
                SET @LogText = 'Update : ' + @MFTableName + ':Update Type ' + CASE
                                                                                  WHEN @UpdateTypeID = 1 THEN
                                                                                      'Incremental'
                                                                                  ELSE
                                                                                      'Full'
                                                                              END;
                SET @LogStatus = 'Completed';
                SET @LogStatusDetail = 'Completed';

                EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                      -- int
                                                    ,@ProcessType = @ProcessType
                                                    ,@LogText = @LogText
                                                    ,@LogType = @LogType
                                                                      -- nvarchar(4000)
                                                    ,@LogStatus = @LogStatus
                                                                      -- nvarchar(50)
                                                    ,@debug = @debug; -- tinyint

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                             ,@LogType = @LogTypeDetail
                                                                             ,@LogText = @LogTextDetail
                                                                             ,@LogStatus = @LogStatusDetail
                                                                             ,@StartTime = @StartTime
                                                                             ,@MFTableName = @MFTableName
                                                                             ,@Validation_ID = @Validation_ID
                                                                             ,@ColumnName = @LogColumnName
                                                                             ,@ColumnValue = @LogColumnValue
                                                                             ,@Update_ID = @Update_IDOut
                                                                             ,@LogProcedureName = @ProcedureName
                                                                             ,@LogProcedureStep = @ProcedureStep
                                                                             --        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
                                                                             ,@debug = @debug;
            END; --REFRESH M-FILES --> MFSQL

            SET NOCOUNT OFF;

            RETURN 1;
        END;
        ELSE
        BEGIN
            SET @ProcedureStep = 'Validate Class Table';

            RAISERROR('Invalid Table Name', 16, 1);
        END;
    END TRY
    BEGIN CATCH
        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName]
           ,[ProcedureStep]
           ,[ErrorNumber]
           ,[ErrorMessage]
           ,[ErrorProcedure]
           ,[ErrorState]
           ,[ErrorSeverity]
           ,[ErrorLine]
        )
        VALUES
        (@ProcedureName, @ProcedureStep, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE()
        ,ERROR_SEVERITY(), ERROR_LINE());

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        SELECT ERROR_NUMBER()    AS [ErrorNumber]
              ,ERROR_MESSAGE()   AS [ErrorMessage]
              ,ERROR_PROCEDURE() AS [ErrorProcedure]
              ,ERROR_STATE()     AS [ErrorState]
              ,ERROR_SEVERITY()  AS [ErrorSeverity]
              ,ERROR_LINE()      AS [ErrorLine]
              ,@ProcedureName    AS [ProcedureName]
              ,@ProcedureStep    AS [ProcedureStep];

        RETURN -1;
    END CATCH;
END;
GO
