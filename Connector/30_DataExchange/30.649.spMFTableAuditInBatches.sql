PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTableAuditinBatches]';
GO

SET NOCOUNT ON;
GO

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFTableAuditinBatches' -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.52'            -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 15/12/2018
	Database:


	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION


------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFTableAuditinBatches' --name of procedure
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

CREATE PROCEDURE [dbo].[spMFTableAuditinBatches]
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFTableAuditinBatches]
(
    @MFTableName NVARCHAR(100)
   ,@FromObjid INT = 1 -- the starting objid of the update
   ,@ToObjid INT = 10000
   ,@WithStats BIT = 1 -- set to 0 to suppress display messages
   ,@ProcessBatch_ID INT = NULL
   ,@Debug INT = 0     --
)
AS
SET NOCOUNT ON;
/*rST**************************************************************************

=======================
spMFTableAuditinBatches
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @FromObjid
    - Ususally from 1 but the update can start at any objid
  @ToObjid
    - The default is 10000, set to the highest objid of the Object Type
  @WithStats
    - Set to 1 to show update statistics in the SSMS results window
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure to update class table in batches

Additional Info
===============

Updating a large number of records from a specific class in MF to SQL in batches 

it is advisable to process updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure
It will also keep the size of the dataset for transfer within the limits of 8000 bites.

Examples
========

.. code:: sql

    EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'YourTable' -- nvarchar(100)
                                    ,@FromObjid = 1             -- int
                                    ,@ToObjid = 555000          -- int
                                    ,@WithStats = 1             -- bit
                                    ,@Debug = 0;                -- int

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-27  LC         add documentation
2019-08-05  LC         add process logging
2019-08-17  LC         Add routine to remove destroyed objects from class table
2018-12-10  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    -- Debug params
    DECLARE @DebugText NVARCHAR(100) = '';
    DECLARE @DefaultDebugText NVARCHAR(100) = 'Proc: %s Step: %s';;
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = 'dbo.spMFTableAuditinBatches';

    SET @Procedurestep = 'Start';
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
    END;

    --<Begin Proc>--

    --set the parameters

    -------------------------------------------------------------
    -- calculate batch size
    -------------------------------------------------------------
    DECLARE @BatchSize INT;
    -- sizes is restricted by objid length.

    --other parameters 
    DECLARE @StartRow       INT
           ,@MaxRow         INT
           ,@RecCount       INT
           ,@BatchCount     INT          = 1
           ,@BatchesToRun   INT
           ,@ObjIdCount     INT
           ,@UpdateID       INT
           ,@SQL            NVARCHAR(MAX)
           ,@Params         NVARCHAR(MAX)
           ,@StartTime      DATETIME
           ,@ProcessingTime INT
           ,@objids         NVARCHAR(MAX)
           ,@Message        NVARCHAR(100)
           ,@Update_IDOut   INT
           ,@Session_ID     INT;

    ------------------------------------------------------------
    -- VARIABLES: LOGGING
    -------------------------------------------------------------
    DECLARE @LogType AS NVARCHAR(50) = 'Status';
    DECLARE @LogText AS NVARCHAR(4000) = '';
    DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
    DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System';
    DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
    DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @count INT = 0;
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Audit Batch Update');
    SET @Procedurestep = 'Start Logging';
    SET @LogText = 'Processing ' + @ProcedureName;

    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Status'
                                        ,@LogText = @LogText
                                        ,@LogStatus = N'In Progress'
                                        ,@debug = @Debug;

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Debug'
                                              ,@LogText = @ProcessType
                                              ,@LogStatus = N'Started'
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = NULL
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = NULL
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @Procedurestep
                                              ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT
                                              ,@debug = 0;

    -------------------------------------------------------------
    -- GET SESSION
    -------------------------------------------------------------

    -------------------------------------------------------------
    -- Batch size
    -------------------------------------------------------------
    BEGIN
        SET @StartRow = @FromObjid;
        SET @MaxRow = @ToObjid;

        SELECT @RecCount = @ToObjid;

        SELECT @BatchSize = 500;

        SELECT @ObjIdCount = @BatchSize;

        SELECT @BatchesToRun = CASE
                                   WHEN @RecCount < @BatchCount THEN
                                       1
                                   ELSE
                                       @RecCount / @BatchSize + 1
                               END;

        SET @DebugText = ' From Objid %i To Objid %i with BatchSize %i and batches to run %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @Procedurestep = 'Input parameters';

        IF @Debug > 0
        BEGIN
            RAISERROR(
                         @DebugText
                        ,10
                        ,1
                        ,@ProcedureName
                        ,@Procedurestep
                        ,@FromObjid
                        ,@RecCount
                        ,@BatchSize
                        ,@BatchesToRun
                     );
        END;

        -------------------------------------------------------------
        -- Get list of id's in numeric sequence
        -------------------------------------------------------------
        DECLARE @TempobjectList NVARCHAR(250);

        SELECT @TempobjectList = [dbo].[fnMFVariableTableName]('##ObjidTable', DEFAULT);

        --IF(   SELECT OBJECT_ID('Tempdb..##ObjidTable'))>0

        --   DROP TABLE [##ObjidTable];
        SET @SQL
            = N'SELECT TOP (' + CAST(@ToObjid AS VARCHAR(12))
              + ')
                   [objid] = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY [s1].[object_id]))
            INTO ' + QUOTENAME(@TempobjectList)
              + '
            FROM [sys].[all_objects]           AS [s1]
                CROSS JOIN [sys].[all_objects] AS [s2]
            OPTION (MAXDOP 1);
			
			   CREATE UNIQUE CLUSTERED INDEX [n]
            ON '   + QUOTENAME(@TempobjectList) + '  ([objid])
			';

        --          IF @debug > 0     SELECT @SQL AS SQL;
        EXEC (@SQL);

        IF @Debug > 0
        BEGIN
            SET @SQL = N'Select count(*) as TempObjectList from ' + QUOTENAME(@TempobjectList) + '';

            EXEC (@SQL);
        END;

        --while loop
        WHILE @StartRow < @ToObjid
        BEGIN

            --SET @ObjIdCount = CASE
            --                                WHEN @BatchesToRun = 1 THEN
            --                                    @RecCount % @BatchSize
            --                                ELSE
            --                                    @ObjIdCount
            --                            END;
            SET @MaxRow = @StartRow + @BatchSize;
            SET @StartTime = GETDATE();
            SET @objids = NULL;
            SET @Message
                = 'Audit Batch: ' + CAST(ISNULL(@BatchCount, 1) AS VARCHAR(10)) + ' Started: '
                  + CAST(@StartTime AS VARCHAR(30));

            --IF @WithStats = 1
            --    RAISERROR(@Message, 10, 1) WITH NOWAIT;
            SET @DebugText = ' Start Row ' + CAST(ISNULL(@StartRow, 'null') AS VARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @Procedurestep = 'Batch Loop';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
            END;

            -------------------------------------------------------------
            -- validate objectvers of id (eliminate ids that is not part of class)
            -------------------------------------------------------------

            --INSERT INTO @TableAuditList
            --  (
            --      [Objid]
            --  )
            --  SELECT [o].[n]
            --  FROM [#Objids] AS [o]
            --  WHERE [o].[n]
            --  BETWEEN @FromObjid AND @ToObjid;
            SET @Params = N'@objids nvarchar(max) output, @startrow int, @Maxrow int';
            SET @SQL
                = N' SELECT @objids = STUFF((
                                       SELECT '','' + CAST(ot2.[Objid] AS NVARCHAR(20))
                                       FROM ' + QUOTENAME(@TempobjectList)
                  + ' ot2
									   WHERE ot2.objid BETWEEN @StartRow AND @Maxrow
									   order by ot2.objid asc
                                       FOR XML PATH('''')
                                   )
                                  ,1
                                  ,1
                                  ,''''
                                  )
            FROM ' + QUOTENAME(@TempobjectList) + ' AS [ot]			
			ORDER BY ot.[objid];';

            --IF @Debug > 0
            --PRINT @SQL;
            EXEC [sys].[sp_executesql] @Stmt = @SQL
                                      ,@Param = @Params
                                      ,@objids = @objids OUTPUT
                                      ,@Startrow = @StartRow
                                      ,@MaxRow = @MaxRow;

            DECLARE @Maxitems INT
                   ,@rcount   INT;

            SELECT @Maxitems = MAX([fmpds].[ListItem])
                  ,@rcount   = COUNT(*)
            FROM [dbo].[fnMFParseDelimitedString](@objids, ',') AS [fmpds];

            SET @DebugText = ' Max Objid %i Batchcount %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @Procedurestep = 'Prepare objids ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @Maxitems, @rcount);
            END;

            -------------------------------------------------------------
            -- perform table audit on selected ID's
            -------------------------------------------------------------
            DECLARE @SessionIDOut   INT
                   ,@NewObjectXml   NVARCHAR(MAX)
                   ,@DeletedInSQL   INT
                   ,@UpdateRequired BIT
                   ,@OutofSync      INT
                   ,@ProcessErrors  INT;

            EXEC [dbo].[spMFTableAudit] @MFTableName = @MFTableName                -- nvarchar(128)
                                       ,@MFModifiedDate = NULL                     -- datetime
                                       ,@ObjIDs = @objids                          -- nvarchar(4000)
                                       ,@SessionIDOut = @Session_ID                -- int
                                       ,@NewObjectXml = @NewObjectXml OUTPUT       -- nvarchar(max)
                                       ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
                                       ,@UpdateRequired = @UpdateRequired OUTPUT   -- bit
                                       ,@OutofSync = @OutofSync OUTPUT             -- int
                                       ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
                                       ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                       ,@Debug = @Debug;

            -- smallint

            -------------------------------------------------------------
            -- Temporary table of audit result
            -------------------------------------------------------------

            IF
            (
                SELECT OBJECT_ID('tempdb..#MFTableObjlist')
            ) IS NOT NULL
                DROP TABLE [#MFTableObjlist];

            CREATE TABLE [#MFTableObjlist]
            (
                [Objid] INT
               ,[AH_objid] INT
            );

            SET @Params = N'@StartRow int, @MaxRow int';
            SET @SQL = N'
INSERT INTO #MFTableObjlist
(
    [Objid]
)
SELECT [Objid] FROM ' + QUOTENAME(@MFTableName) + ' WHERE [Objid] BETWEEN @StartRow AND @MaxRow';

            EXEC [sys].[sp_executesql] @SQL, @Params, @StartRow, @MaxRow;

            --SELECT 'FromTable', * FROM [#MFTableObjlist] AS [mto]

            -------------------------------------------------------------
            -- Match audit table with class table for the batch
            -------------------------------------------------------------
            SET @Procedurestep = 'Match objids ';

            DECLARE @Idoc INT;

            EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @NewObjectXml;

            WITH [cte]
            AS (SELECT [xmlfile].[AH_objId]
                FROM
                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        [AH_objId] INT './@objectID'
                    ) [xmlfile])
            MERGE INTO [#MFTableObjlist] [t]
            USING
            (SELECT [cte].[AH_objId] FROM [cte]) [s]
            ON [t].[Objid] = [s].[AH_objId]
            WHEN MATCHED THEN
                UPDATE SET [t].[AH_objid] = [s].[AH_objId]
            WHEN NOT MATCHED THEN
                INSERT
                (
                    [AH_objid]
                )
                VALUES
                ([s].[AH_objId]);

            EXEC [sys].[sp_xml_removedocument] @Idoc;

            -------------------------------------------------------------
            -- Remove non existend objects from class table
            -------------------------------------------------------------
            SET @Procedurestep = 'Remove objids from class table ';

            SET @SQL
                = N'DELETE FROM ' + QUOTENAME(@MFTableName)
                  + ' where objid IN (SELECT mto.objid FROM [#MFTableObjlist] AS [mto] WHERE [mto].[AH_objid] IS null);';
	 
            EXEC [sys].[sp_executesql] @SQL;

            SELECT @RecCount = COUNT(*)
            FROM [#MFTableObjlist] AS [mto]
            WHERE [mto].[AH_objid] IS NULL;

            SET @DebugText = ' Objects Removed from class table %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @RecCount);
            END;

            -------------------------------------------------------------
            -- count records updated in audit table
            -------------------------------------------------------------
            SELECT @RecCount = COUNT(*)
            FROM [#MFTableObjlist] AS [mto]
            WHERE [mto].[AH_objid] IS NOT NULL;

            SET @DebugText = ' Objects from MF %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @Procedurestep = 'Table audit count ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @RecCount);
            END;

            IF
            (
                SELECT OBJECT_ID('tempdb..#MFTableObjlist')
            ) IS NOT NULL
                DROP TABLE [#MFTableObjlist];

            -------------------------------------------------------------
            -- performance message
            -------------------------------------------------------------
            SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
            SET @Message
                = 'Audit Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing time (s) : '
                  + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' From Object ID: ' + CAST(@StartRow AS VARCHAR(10))
                  + ' Processed: ' + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));

            IF @WithStats = 1
                RAISERROR(@Message, 10, 1) WITH NOWAIT;

            SET @BatchCount = @BatchCount + 1;
            SET @BatchesToRun = @BatchesToRun - 1;

            --        SELECT @BatchesToRun AS [BatchestoRun];

            --         SELECT @BatchSize AS [batchsize];
            SET @StartRow = CASE
                                WHEN @StartRow > @ToObjid THEN
                                    NULL
                                ELSE
                                    @StartRow + @BatchSize + 1
                            END;

            IF
            (
                SELECT OBJECT_ID('tempdb..#MFTableObjlist')
            ) IS NOT NULL
                DROP TABLE [#MFTableObjlist];
        END;
    END;
END;
GO