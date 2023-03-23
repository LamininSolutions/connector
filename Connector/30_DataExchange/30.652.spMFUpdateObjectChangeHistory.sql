PRINT SPACE (5) + QUOTENAME (@@ServerName) + '.' + QUOTENAME (DB_NAME ()) + '.[dbo].[spMFUpdateObjectChangeHistory]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateObjectChangeHistory', -- nvarchar(100)
    @Object_Release = '4.10.30.75',
    @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateObjectChangeHistory' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE (10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE (10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateObjectChangeHistory
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateObjectChangeHistory
(
    @MFTableName NVARCHAR(200) = NULL,
    @WithClassTableUpdate INT = 0,
    @Objids NVARCHAR(MAX) = NULL,
    @IsFullHistory INT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS

/*rST**************************************************************************

=============================
spMFUpdateObjectChangeHistory
=============================

Return
  - 1 = Success
  - -1 = Error

  @MFTableName nvarchar(200)
  Class table name to be updated
  If null then all class tables in MFObjectChangeHistoryUpdateControl table is included.

  @WithClassTableUpdate int
  - Default = 0 (No)
  - The expectation is that the update history will run just after the class table was updated 

  @Objids nvarchar(4000)
  - comma delimited list of objids to be included 
  - if null then all objids for the class is included
  - can only be used in conjunction with a specific class table.

  @IsFullHistory int
   - default = 0 (no).  The history will be updated from the last transaction date for the property of the class
   - if set the full history then all the versions will be updated with a start date from 2020-01-01

  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To process change history for a single or all class tables and properties as set in the MFObjectChangeHistoryUpdateControl table. 

Additional Info
===============

The procedure allows for three modes of operation:
  - specific objects defined as a comma delimited string of objid's. This only applies to a single table. 
  - pre selected objects, by setting the process_id on the class to 5 prior to running this procedure. All the properties specified in the control table will be updated.
  - for all objects in the class, by not setting the process_id in the class and setting @objids to null. All the properties specified in the control table will be updated.

For each mode there are various options available:
  - For all tables specified in the control table MFObjectChangeHistoryUpdateControl by setting @MFTableName to null
  - For a specific table
  - to perform a class table update at the same time by setting @WithClassTableUpdate to 1

Finally the update can be done incrementally or in full by setting @IsFullHistory.  

Update MFObjectChangeHistoryUpdatecontrol for each class and property to be included in the update. Use separate rows for for each property to be included. A class may have multiple rows if multiple properties are to be processed for the tables.

The routine is designed to get the last updated date for the property and the class from the MFObjectChangeHistory table. The next update will only update records after this date.

Delete the records for the class and the property to reset the records in the table MFObjectChangeHistory or to force updates prior to the last update date

This procedure is included in spMFUpdateMFilesToSQL and spMFUpdateAllIncludedInAppTables routines.  This allows for scheduling these procedures in an agent or another procedure to ensure that all the updates in the App is included.  

spMFUpdateObjectChangeHistory can be run on its own, either by calling it using the Context menu Actions, or any other method.

Prerequisites
=============

The table MFObjectChangeHistoryUpdatecontrol must be updated before this procedure will work.

This procedures is dependent on the object being present and up to date in the class table.

Include this procedure in an agent to schedule the update.

This procedure use a process_id = 5 internally.  Using 5 as a process id for other purposes may interfere with this procedure.

Examples
========

To insert the values in the control table.

.. code:: sql

	INSERT INTO dbo.MFObjectChangeHistoryUpdateControl
	(
		MFTableName,
		ColumnNames
	)
	VALUES
	(   N'MFCustomer', 
		N'State_ID'  
		),
	(   N'MFPurchaseInvoice', 
		N'State_ID'  
		)

updating a class table for specific objids

.. code:: sql

    exec spMFUpdateObjectChangeHistory @MFTableName = 'MFCustomer', @WithClassTableUpdate = 1, @ObjIDs = '1,2,3', @Debug = 0

----updating all class tables with full update (including updating the class table)

.. code:: sql

    exec spMFUpdateObjectChangeHistory @MFTableName = null, @WithClassTableUpdate = 1, @ObjIDs = null,  @IsFullHistory = 1, @Debug = 0

    or

    exec spMFUpdateObjectChangeHistory 
    @WithClassTableUpdate = 0,
     @IsFullHistory = 0,
    @Debug = 0

    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-03-21  LC         Remove debugging code
2022-11-30  LC         resolve issue with updates by objid
2021-12-22  LC         Update logging to monitor performance
2021-12-22  LC         Set default for withtableupdate to 0
2021-10-18  LC         The procedure is fundamentally rewritten
2021-04-02  LC         Add parameter for IsFullHistory
2020-06-26  LC         added additional exception management
2020-05-06  LC         Validate the column in control table
2020-03-06  LC         Add MFTableName and objids - run per table
2019-11-04  LC         Create procedure

==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

BEGIN
    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL (@ProcessType, 'Change History Update');

    -------------------------------------------------------------
    -- CONSTATNS: MFSQL Global 
    -------------------------------------------------------------
    --DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
    --DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
    --DECLARE @Process_ID_1_Update TINYINT = 1;
    --DECLARE @Process_ID_6_ObjIDs TINYINT = 6; --marks records for refresh from M-Files by objID vs. in bulk
    --DECLARE @Process_ID_9_BatchUpdate TINYINT = 9; --marks records previously set as 1 to 9 and update in batches of 250
    --DECLARE @Process_ID_Delete_ObjIDs INT = -1; --marks records for deletion
    --DECLARE @Process_ID_2_SyncError TINYINT = 2;
    --DECLARE @ProcessBatchSize INT = 250;

    -------------------------------------------------------------
    -- VARIABLES: MFSQL Processing
    -------------------------------------------------------------
    DECLARE @Update_ID INT;
    --DECLARE @MFLastModified DATETIME;
    DECLARE @Validation_ID INT;

    -------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    --DECLARE @error AS INT = 0;

    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFUpdateObjectChangeHistory';
    DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    --DECLARE @Msg AS NVARCHAR(256) = N'';
    --DECLARE @MsgSeverityInfo AS TINYINT = 10;
    --DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
    --DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

    -------------------------------------------------------------
    -- VARIABLES: LOGGING
    -------------------------------------------------------------
    DECLARE @LogType AS NVARCHAR(50) = N'Status';
    DECLARE @LogText AS NVARCHAR(4000) = N'';
    DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
    DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
    DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
    DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @Batchcount INT = 0;
    --DECLARE @Now AS DATETIME = GETDATE();
    DECLARE @StartTime AS DATETIME = GETUTCDATE ();
    --DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
    --DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

    -------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParams NVARCHAR(MAX) = N'';

    -------------------------------------------------------------
    -- Variable custom
    -------------------------------------------------------------   
    --DECLARE @params NVARCHAR(MAX);
    --DECLARE @Process_ID INT = 5;
    DECLARE @ColumnNames NVARCHAR(4000);
    DECLARE @RC INT;
    DECLARE @NumberOFDays INT;
    DECLARE @StartDate DATETIME; --= DATEADD(DAY,-1,GETDATE())
    DECLARE @ID INT;
    DECLARE @MFID INT;
    DECLARE @ObjectType_ID INT;
    DECLARE @Property_IDs NVARCHAR(MAX);
    DECLARE @MFLastModifiedDateColumn NVARCHAR(100);
    DECLARE @VaultSettings NVARCHAR(4000);
    DECLARE @Idoc INT;
    DECLARE @Criteria VARCHAR(258);
    --DECLARE @BatchSize INT = 500;
    DECLARE @MinBatchRow INT;
    DECLARE @MaxBatchrow INT;
    DECLARE @FromObjid INT;
    DECLARE @ToObjid INT;
    DECLARE @propertyIDString NVARCHAR(100);
    DECLARE @Result NVARCHAR(MAX);

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = N'Start Logging';
    SET @LogText = N'Processing ' + @ProcedureName;

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = N'Status',
        @LogText = @LogText,
        @LogStatus = N'In Progress',
        @debug = @Debug;

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = N'Debug',
        @LogText = @ProcessType,
        @LogStatus = N'Started',
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = NULL,
        @ColumnValue = NULL,
        @Update_ID = @Update_ID,
        @LogProcedureName = @ProcedureName,
        @LogProcedureStep = @ProcedureStep,
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
        @debug = 0;

    BEGIN TRY
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Setup environment';

        IF @Debug > 0
        BEGIN
            RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- get last modified date column
        -------------------------------------------------------------
        SELECT @MFLastModifiedDateColumn = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 21;

        --last modified

        -- validate requirements
        IF @Objids IS NOT NULL
           AND @MFTableName IS NULL
        BEGIN
            SET @DebugText = N' Set a table when objids are specified';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Invalid parameter combination';

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        --objids not null

        ----------------------------------------------------------------------
        --initialise entry in UpdateHistory
        ----------------------------------------------------------------------
        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP (1)
            @Username  = Username,
            @VaultName = VaultName
        FROM dbo.MFVaultSettings
        ORDER BY ID;

        --get vault settings
        SELECT @VaultSettings = dbo.FnMFVaultSettings ();

        IF @Debug = 1
        BEGIN
            SELECT @VaultSettings = dbo.FnMFVaultSettings ();
        END;

        -------------------------------------------------------------
        -- Create table update list
        -------------------------------------------------------------
        DECLARE @UpdateList AS TABLE
        (
            ID INT IDENTITY,
            MFID INT,
            MFTableName NVARCHAR(200),
            ColumnNames NVARCHAR(MAX),
            PropertyIDs NVARCHAR(MAX)
        );

        INSERT INTO @UpdateList
        (
            MFID,
            MFTableName,
            ColumnNames,
            PropertyIDs
        )
        SELECT mc.MFID,
            mochuc.MFTableName,
            STUFF (
            (
                SELECT DISTINCT
                    ',' + fmpds.ListItem
                FROM dbo.MFObjectChangeHistoryUpdateControl                             AS mochuc2
                    CROSS APPLY dbo.fnMFParseDelimitedString (mochuc2.ColumnNames, ',') AS fmpds
                    INNER JOIN dbo.MFProperty AS mp
                        ON fmpds.ListItem = mp.ColumnName
                WHERE mochuc2.MFTableName = mochuc.MFTableName
                FOR XML PATH ('')
            ),
                      1,
                      1,
                      ''
                  ),
            STUFF (
            (
                SELECT DISTINCT
                    ',' + CAST(mp.MFID AS VARCHAR(10))
                FROM dbo.MFObjectChangeHistoryUpdateControl                         AS htu
                    CROSS APPLY dbo.fnMFParseDelimitedString (htu.ColumnNames, ',') AS fmpds
                    INNER JOIN dbo.MFProperty mp
                        ON fmpds.ListItem = mp.ColumnName
                WHERE htu.MFTableName = mochuc.MFTableName
                FOR XML PATH ('')
            ),
                      1,
                      1,
                      ''
                  )
        FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
            INNER JOIN dbo.MFClass                  AS mc
                ON mochuc.MFTableName = mc.TableName
        WHERE mochuc.MFTableName = mochuc.MFTableName
              AND
              (
                  mochuc.MFTableName = @MFTableName
                  OR @MFTableName IS NULL
              )
        GROUP BY mc.MFID,
            mochuc.MFTableName,
            mochuc.ColumnNames;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Updatelist';

        IF @Debug > 0
        BEGIN
            SELECT 'Updatelist',
                *
            FROM @UpdateList AS ul;

            RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- Validate columns in control table
        -------------------------------------------------------------
        SET @ProcedureStep = N'Get column last update date';

        DECLARE @LastUpdateDatetable AS TABLE
        (
            ClassID INT,
            PropertyID INT,
            lastupdatedate DATETIME
        );

        INSERT INTO @LastUpdateDatetable
        (
            ClassID,
            PropertyID,
            lastupdatedate
        )
        SELECT DISTINCT
            mc.MFID,
            fmpds.ListItem,
            '2000-01-01'
        FROM @UpdateList                                                   AS ul
            CROSS APPLY dbo.fnMFParseDelimitedString (ul.PropertyIDs, ',') AS fmpds
            INNER JOIN dbo.MFClass mc
                ON ul.MFTableName = mc.TableName;

        WITH cte
        AS (SELECT moch.Class_ID,
                moch.Property_ID,
                MAX (moch.LastModifiedUtc) lastupdatedate
            FROM dbo.MFObjectChangeHistory AS moch
            --            WHERE moch.Class_ID = @classID
            GROUP BY moch.Property_ID,
                moch.Class_ID)
        UPDATE lud
        SET lud.lastupdatedate = CASE
                                     WHEN @IsFullHistory = 1 THEN
                                         '2000-01-01'
                                     ELSE
                                         cte.lastupdatedate
                                 END
        FROM @LastUpdateDatetable AS lud
            INNER JOIN cte
                ON lud.PropertyID = cte.Property_ID
                   AND lud.ClassID = cte.Class_ID;

        IF @Debug > 0
        BEGIN
            SELECT 'MFObjectChangeHistoryUpdateControl',
                mochuc.ID,
                mochuc.MFTableName,
                mochuc.ColumnNames
            FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc;

            SELECT 'LastUpdateDatetable',
                *
            FROM @LastUpdateDatetable;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -- anchor objects to update
        SELECT @ID = MIN (htu.ID)
        FROM @UpdateList AS htu;

        -------------------------------------------------------------
        -- Loop through tables
        -------------------------------------------------------------
        WHILE @ID IS NOT NULL
        BEGIN
            SET @DebugText = N' %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Begin Loop through tables ';

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ID);
            END;

            -------------------------------------------------------------
            -- Get table details
            -------------------------------------------------------------
            SET @ProcedureStep = N'Get Table variables:  ';

            DECLARE @classID INT;

            SELECT @MFID       = mc.MFID,
                @ObjectType_ID = ot.MFID,
                @classID       = htu.MFID,
                @MFTableName   = htu.MFTableName,
                @ColumnNames   = htu.ColumnNames,
                @Property_IDs  = htu.PropertyIDs
            FROM @UpdateList                AS htu
                INNER JOIN dbo.MFClass      AS mc
                    ON mc.MFID = htu.MFID
                INNER JOIN dbo.MFObjectType ot
                    ON mc.MFObjectType_ID = ot.ID
            WHERE htu.ID = @ID;

            IF @Property_IDs IS NULL
            BEGIN
                SET @DebugText = N':Invalid Column in dbo.MFObjectChangeHistoryUpdateControl ';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Validate columns for history  ';

                RAISERROR (@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- Reset variables
            -------------------------------------------------------------
            SET @DebugText = N' Table: ' + @MFTableName + N' Columns: ' + @ColumnNames;
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- Update table
            -------------------------------------------------------------
            SET @DebugText = N' %s';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Create temp Objid Table';

            IF @Debug > 0
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @classID);

            IF
            (
                SELECT OBJECT_ID ('tempdb..#ObjidTable')
            ) IS NULL
            BEGIN
                CREATE TABLE #ObjidTable
                (
                    TempTable_ID INT IDENTITY PRIMARY KEY,
                    classID INT,
                    Objid INT,
                    lastModifiedUTC DATETIME
                );
            END;

            --method 1 : set objids
            IF @Objids IS NOT NULL
            BEGIN
                INSERT INTO #ObjidTable
                (
                    classID,
                    Objid
                )
                SELECT @classID,
                    fmpds.ListItem
                FROM dbo.fnMFParseDelimitedString (@Objids, ',') AS fmpds;

                SET @rowcount = @@RowCount;
                SET @DebugText = N'count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'set objids ';

                IF @Debug > 0
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
            END;

            SET @sql
                = N'Select @RowCount = COUNT(process_id) FROM ' + QUOTENAME (@MFTableName)
                  + N't
WHERE process_id = 5;';

            EXEC sys.sp_executesql @sql, N'@RowCount int output', @rowcount;

            --method 2  set by process_ID = 5
            IF @Objids IS NULL
               AND @rowcount > 0
            BEGIN
                SET @sql = N'SELECT @ClassID, Objid FROM 
                    ' + QUOTENAME (@MFTableName) + N't
WHERE process_id = 5 order by t.objid;';

                INSERT INTO #ObjidTable
                (
                    classID,
                    Objid
                )
                EXEC sys.sp_executesql @sql, N'@ClassID int', @classID;

                SET @rowcount = @@RowCount;
                SET @DebugText = N'count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'set by process_id ';

                IF @Debug > 0
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
            END;

            IF @Objids IS NULL
               AND @rowcount = 0
            BEGIN
                SET @sql = N'SELECT @ClassID, Objid FROM 
                    ' + QUOTENAME (@MFTableName) + N't order by t.objid;';

                INSERT INTO #ObjidTable
                (
                    classID,
                    Objid
                )
                EXEC sys.sp_executesql @sql, N'@ClassID int', @classID;

                SET @rowcount = @@RowCount;
                SET @DebugText = N'count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'all object included ';
            END;

            SET @DebugText = N' %s';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Class ';

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @MFTableName);
            END;

            --reset process_id = 5 to 0
            SET @sql = N'UPDATE t
Set process_id = 0 
FROM ' +    QUOTENAME (@MFTableName) + N't
inner join #objidTable ot
on t.objid = ot.objid
where process_ID = 5;';

            EXEC (@sql);

            -------------------------------------------------------------
            -- with class table updates
            -------------------------------------------------------------
            IF @WithClassTableUpdate = 1
            BEGIN
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Update class Table included';

                IF @Debug > 0
                BEGIN
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                DECLARE @MFLastUpdateDate SMALLDATETIME;

                EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName, -- nvarchar(128)
                    @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,             -- smalldatetime
                    @UpdateTypeID = 1,                                        -- tinyint
                    @Update_IDOut = @Update_ID OUTPUT,                        -- int
                    @ProcessBatch_ID = @ProcessBatch_ID,                      -- int
                    @debug = 0;                                               -- tinyint

                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Class Table update completed';

                IF @Debug > 0
                BEGIN
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

            -- end withclass table update

            -------------------------------------------------------------
            -- update temp table with last modified date
            -------------------------------------------------------------
            SET @sql
                = N'  UPDATE ot
            SET ot.lastModifiedUTC = t.' + QUOTENAME (@MFLastModifiedDateColumn)
                  + N'
            FROM #ObjidTable AS ot
            INNER JOIN ' + QUOTENAME (@MFTableName)
                  + N' t
            ON ot.Objid = t.objid AND ot.classID = @classid ';

            EXEC sys.sp_executesql @sql, N'@Classid int', @classID;

            IF @Debug > 100
                SELECT 'objidtable',
                    *
                FROM #ObjidTable AS ot;

            --begin loop for each property
            DECLARE @Prop_ID       INT,
                @propertyForUpdate VARCHAR(100);

            SELECT @Prop_ID = MIN (lud.PropertyID)
            FROM @LastUpdateDatetable     AS lud
                INNER JOIN dbo.MFProperty AS mp
                    ON lud.PropertyID = mp.MFID
                       AND lud.ClassID = @classID
            WHERE lud.PropertyID IS NOT NULL;

            SET @DebugText = N' for prop mfid %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Column loop started ';

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Prop_ID);
            END;

            WHILE @Prop_ID IS NOT NULL
            BEGIN
                SELECT @propertyForUpdate = mp.ColumnName,
                    @StartDate            = lud.lastupdatedate
                FROM @LastUpdateDatetable     AS lud
                    INNER JOIN dbo.MFProperty AS mp
                        ON lud.PropertyID = mp.MFID
                WHERE mp.MFID = @Prop_ID
                      AND lud.ClassID = @classID;

                SELECT @StartDate = lud.lastupdatedate
                FROM @LastUpdateDatetable AS lud
                WHERE lud.ClassID = @classID
                      AND lud.PropertyID = @Prop_ID;

                SET @ProcedureStep = N'Prepare objects ';
                SET @DebugText
                    = N' for Property ' + @propertyForUpdate + N': start date ' + CAST(@StartDate AS NVARCHAR(30));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @FromObjid = MIN (toid.Objid),
                    @ToObjid      = MAX (toid.Objid),
                    @MaxBatchrow  = MAX (toid.TempTable_ID)
                FROM #ObjidTable AS toid;

                -------------------------------------------------------------
                -- Get history
                -------------------------------------------------------------
                SELECT @propertyIDString = CAST(@Prop_ID AS NVARCHAR(10));

                IF @Debug > 0
                BEGIN
                    SELECT @MFTableName   AS tablename,
                        @FromObjid        fromobjid,
                        @ToObjid          Toobjid,
                        @MaxBatchrow      AS MaxTempTable_ID,
                        @propertyIDString AS Property,
                        @StartDate        AS Startdate;
                END;

                -------------------------------------------------------------
                -- Get objids - in batch mode
                -------------------------------------------------------------
                SELECT @MinBatchRow = 1,
                    @MaxBatchrow    = MAX (toid.TempTable_ID)
                FROM #ObjidTable AS toid;

                SET @Batchcount = 0;

                --start of main loop
                WHILE @MinBatchRow IS NOT NULL
                BEGIN -- batching objids
                    SET @Batchcount = @Batchcount + 1;

                    IF @Debug > 0
                        SELECT 
                        @Batchcount AS CurrentBatchnr,
                        @MFTableName AS tablename,
                            @FromObjid      fromobjid,
                            @ToObjid        Toobjid,
                            @MinBatchRow    AS nextBatchStart,
                            @MaxBatchrow    AS LastBatcchRow
;
                    WITH cte
                    AS (SELECT TOP (500)
                            toid.Objid
                        FROM #ObjidTable AS toid
                        WHERE toid.TempTable_ID >= @MinBatchRow
                              AND toid.classID = @classID
                              AND toid.lastModifiedUTC >= @StartDate
                        ORDER BY toid.TempTable_ID)
                    SELECT @Objids = STUFF (
                                     (
                                         SELECT ',' + CAST(cte.Objid AS VARCHAR(10))
                                         FROM cte
                                         ORDER BY cte.Objid
                                         FOR XML PATH ('')
                                     ),
                                               1,
                                               1,
                                               ''
                                           );

                    SELECT @FromObjid = MIN (fmpds.ListItem),
                        @ToObjid      = MAX (fmpds.ListItem),
                        @rowcount     = COUNT (fmpds.ListItem)
                    FROM dbo.fnMFParseDelimitedString (@Objids, ',') AS fmpds;

                    IF @Debug > 0
                    BEGIN
                        SELECT COUNT (*) batchcount
                        FROM dbo.fnMFParseDelimitedString (@Objids, ',') AS fmpds;

                        SELECT @FromObjid AS FromObjid,
                            @ToObjid      AS ToObjid,
                            @rowcount     AS TotalRows;
                    END;

                    IF @Debug > 100
                        SELECT 'objids',
                            *
                        FROM dbo.fnMFParseDelimitedString (@Objids, ',') AS fmpds;

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Get history with spMFGetHistoryInternal';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    ---------------------------------------------------------------------
                    --Calling spMFGetHistoryInternal  procedure to objects history
                    ----------------------------------------------------------------------
                    SET @ProcedureStep = N'Set criteria ';
                    SET @Criteria = CASE
                                        WHEN @IsFullHistory = 1 THEN
                                            ' Full History '
                                        WHEN @IsFullHistory = 0
                                             AND @NumberOFDays > 0 THEN
                                            ' For Number of days: ' + CAST(@NumberOFDays AS VARCHAR(5)) + ''
                                        WHEN @IsFullHistory = 0
                                             AND
                                             (
                                                 @NumberOFDays < 0
                                                 OR @NumberOFDays IS NULL
                                             )
                                             AND @StartDate <> '2000-01-01' THEN
                                            ' From date: ' + CAST((CONVERT (DATE, @StartDate)) AS VARCHAR(25)) + ''
                                        ELSE
                                            ' No Criteria'
                                    END;

                    IF @rowcount > 0 -- objects to update
                    BEGIN
                        INSERT INTO dbo.MFUpdateHistory
                        (
                            Username,
                            VaultName,
                            UpdateMethod
                        )
                        VALUES
                        (@Username, @VaultName, 11);

                        SELECT @Update_ID = @@Identity;

                        DECLARE @XML AS XML;

                        SET @XML = '<form>' +
                                   (
                                       SELECT fmpds.ListItem AS objid
                                       FROM dbo.fnMFParseDelimitedString (@Objids, ',') AS fmpds
                                       FOR XML PATH ('object')
                                   ) + '</form>';

                        IF @Debug > 0
                            SELECT @XML AS ObjectVerDetails,
                                @Objids AS objids;

                        UPDATE dbo.MFUpdateHistory
                        SET ObjectVerDetails = @XML,
                            ObjectDetails = CAST('<form><Object Class="' + CAST(@classID AS NVARCHAR(10))
                                                 + '" PropertyID="' + CAST(@Prop_ID AS NVARCHAR(10)) + '"/></form>' AS XML)
                        WHERE Id = @Update_ID;

                        -------------------------------------------------------------
                        -- Check connection to vault
                        -------------------------------------------------------------
                        SET @ProcedureStep = N'Connection test: ';

                        EXEC @return_value = dbo.spMFConnectionTest;

                        IF @return_value <> 1
                        BEGIN
                            SET @DebugText = N'Connection failed ';
                            SET @DebugText = @DefaultDebugText + @DebugText;

                            RAISERROR (@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                        END;

                        SET @StartTime = GETUTCDATE ();
                        SET @ProcedureStep = N'wrapper';

                        IF @return_value = 1
                        BEGIN
                            EXEC @return_value = dbo.spMFGetHistoryInternal @VaultSettings = @VaultSettings,
                                @ObjectType = @ObjectType_ID,
                                @ObjIDs = @Objids,
                                @PropertyIDs = @propertyIDString,
                                @SearchString = NULL,
                                @IsFullHistory = @IsFullHistory,
                                @NumberOfDays = @NumberOFDays,
                                @StartDate = @StartDate,
                                @Result = @Result OUTPUT;

                            UPDATE dbo.MFUpdateHistory
                            SET NewOrUpdatedObjectVer = CAST(@Result AS XML),
                                UpdateStatus = 'Completed'
                            WHERE Id = @Update_ID;

                            SET @LogTypeDetail = N'Status';
                            SET @LogStatusDetail = N' Assembly';
                            SET @LogTextDetail = N'spMFGetHistoryInternal';
                            SET @LogColumnName = N'';
                            SET @LogColumnValue = N'';

                            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                @LogType = @LogTypeDetail,
                                @LogText = @LogTextDetail,
                                @LogStatus = @LogStatusDetail,
                                @StartTime = @StartTime,
                                @MFTableName = @MFTableName,
                                @Validation_ID = @Validation_ID,
                                @ColumnName = @LogColumnName,
                                @ColumnValue = @LogColumnValue,
                                @Update_ID = @Update_ID,
                                @LogProcedureName = @ProcedureName,
                                @LogProcedureStep = @ProcedureStep,
                                @debug = @Debug;

                            IF @Debug > 0
                            BEGIN
                                SELECT CAST(@Result AS XML) AS ResultsAsXML;
                            END;

                            IF @return_value <> 1
                            BEGIN
                                SET @DebugText
                                    = N': spMFGetHistory failed return value ' + CAST(@return_value AS VARCHAR(5));
                                SET @DebugText = @DefaultDebugText + @DebugText;

                                RAISERROR (@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                            END;

                            --ifdebug

                            --IF (@Update_ID > 0)
                            --    UPDATE dbo.MFUpdateHistory
                            --    SET NewOrUpdatedObjectVer = @Result
                            --    WHERE Id = @Update_ID;
                            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @Result;

                            SET @DebugText = N'';
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'Wrapper performed';

                            IF @Debug > 0
                            BEGIN
                                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

                            SET @ProcedureStep = N'Creating temp table #Temp_ObjectHistory';

                            SELECT @rowcount = COUNT (*)
                            FROM
                            (SELECT fmss.Item FROM dbo.fnMFSplitString (@Objids, ',') AS fmss ) list;

                            SET @LogTypeDetail = N'Debug';
                            SET @LogStatusDetail = N'Column: ' + CAST(@Prop_ID AS NVARCHAR(10));
                            SET @LogTextDetail
                                = N'Batch ' + CAST(@Batchcount AS NVARCHAR(10)) + +N'; Criteria:  ' + @Criteria;
                            SET @LogColumnName = N'Object Count';
                            SET @LogColumnValue = CAST(ISNULL (@rowcount, 0) AS VARCHAR(5));
                            SET @StartTime = GETUTCDATE ();

                            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                @LogType = @LogTypeDetail,
                                @LogText = @LogTextDetail,
                                @LogStatus = @LogStatusDetail,
                                @StartTime = @StartTime,
                                @MFTableName = @MFTableName,
                                @Validation_ID = @Validation_ID,
                                @ColumnName = @LogColumnName,
                                @ColumnValue = @LogColumnValue,
                                @Update_ID = @Update_ID,
                                @LogProcedureName = @ProcedureName,
                                @LogProcedureStep = @ProcedureStep,
                                @debug = @Debug;

                            ----------------------------------------------------------------------------------
                            --Creating temp table #Temp_ObjectHistory for storing object history xml records
                            --------------------------------------------------------------------------------
                            IF
                            (
                                SELECT OBJECT_ID ('tempdb..#Temp_ObjectHistory')
                            ) IS NOT NULL
                                DROP TABLE #Temp_ObjectHistory;

                            CREATE TABLE #Temp_ObjectHistory
                            (
                                RowNr INT IDENTITY,
                                ObjectType_ID INT,
                                Class_ID INT,
                                ObjID INT,
                                MFVersion INT,
                                LastModifiedUTC NVARCHAR(100),
                                -- LastModifiedUTC DATETIME,
                                MFLastModifiedBy_ID INT,
                                Property_ID INT,
                                Property_Value NVARCHAR(300),
                                CreatedOn DATETIME
                            );

                            INSERT INTO #Temp_ObjectHistory
                            (
                                ObjectType_ID,
                                Class_ID,
                                ObjID,
                                MFVersion,
                                LastModifiedUTC,
                                MFLastModifiedBy_ID,
                                Property_ID,
                                Property_Value,
                                CreatedOn
                            )
                            SELECT ObjectType,
                                ClassID,
                                ObjID,
                                Version,
                                LastModifiedUTC,
                                LastModifiedBy_ID,
                                Property_ID,
                                Property_Value,
                                GETDATE ()
                            FROM
                                OPENXML (@Idoc, '/form/Object', 1)
                                WITH
                                (
                                    ObjectType INT '@ObjectType',
                                    ClassID INT '@ClassID',
                                    ObjID INT '@ObjID',
                                    Version INT '@Version',
                                    --      , [LastModifiedUTC] NVARCHAR(30) '../@LastModifiedUTC'
                                    LastModifiedUTC NVARCHAR (100) '@CheckInTimeStamp',
                                    --        LastModifiedUTC Datetime '../@CheckInTimeStamp',
                                    LastModifiedBy_ID INT '@LastModifiedBy_ID',
                                    Property_ID INT '@Property_ID',
                                    Property_Value NVARCHAR (300) '@Property_Value'
                                )
                            WHERE '@Property_ID' IS NOT NULL;

                            SET @rowcount = @@RowCount;
                            SET @DebugText = @MFTableName + N' ;records updated: ' + CAST(@rowcount AS VARCHAR(10));
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'Change history  ';

                            IF @Debug > 0
                            BEGIN
                                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

                            IF @Debug > 0
                                SELECT *
                                FROM #Temp_ObjectHistory AS toh;

                            IF @Idoc IS NOT NULL
                                EXEC sys.sp_xml_removedocument @Idoc;

                            ----------------------------------------------------------------------------------
                            --Merge/Inserting records into the MFObjectChangeHistory from Temp_ObjectHistory
                            --------------------------------------------------------------------------------
                            SET @ProcedureStep = N'Update MFObjectChangeHistory';

                            BEGIN TRAN;

                            INSERT INTO dbo.MFObjectChangeHistory
                            (
                                ObjectType_ID,
                                Class_ID,
                                ObjID,
                                MFVersion,
                                LastModifiedUtc,
                                MFLastModifiedBy_ID,
                                Property_ID,
                                Property_Value,
                                CreatedOn
                            )
                            SELECT s.ObjectType_ID,
                                s.Class_ID,
                                s.ObjID,
                                s.MFVersion,
                                CONVERT (DATETIME, s.LastModifiedUTC),
                                s.MFLastModifiedBy_ID,
                                s.Property_ID,
                                s.Property_Value,
                                s.CreatedOn
                            FROM #Temp_ObjectHistory                AS s
                                LEFT JOIN dbo.MFObjectChangeHistory t
                                    ON t.ObjectType_ID = s.ObjectType_ID
                                       AND t.Class_ID = s.Class_ID
                                       AND t.ObjID = s.ObjID
                                       AND t.MFVersion = s.MFVersion
                                       AND t.Property_ID = s.Property_ID
                            WHERE t.ID IS NULL
                                  AND s.Property_ID IS NOT NULL;

                            SET @rowcount = @@RowCount;

                            COMMIT TRAN;

                            SET @DebugText = N' %i';
                            SET @DebugText = @DefaultDebugText + @DebugText;
                            SET @ProcedureStep = N'New records in history table';

                            IF @Debug > 0
                            BEGIN
                                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                            END;

                            SET @LogTypeDetail = N'Debug';
                            SET @LogStatusDetail = N'Column: ' + CAST(ISNULL (@Prop_ID, 0) AS VARCHAR(10));
                            SET @LogTextDetail = @ProcedureStep;
                            SET @LogColumnName = N' Count ';
                            SET @LogColumnValue = CAST(ISNULL (@rowcount, 0) AS VARCHAR(5));
                            SET @StartTime = GETUTCDATE ();

                            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                @LogType = @LogTypeDetail,
                                @LogText = @LogTextDetail,
                                @LogStatus = @LogStatusDetail,
                                @StartTime = @StartTime,
                                @MFTableName = @MFTableName,
                                @Validation_ID = @Validation_ID,
                                @ColumnName = @LogColumnName,
                                @ColumnValue = @LogColumnValue,
                                @Update_ID = @Update_ID,
                                @LogProcedureName = @ProcedureName,
                                @LogProcedureStep = @ProcedureStep,
                                @debug = @Debug;
                        END; --if connection test is valid
                    END; --if rowcount for objids > 0
                    ;

                    WITH cte
                    AS (SELECT TOP (500)
                            toid.TempTable_ID
                        FROM #ObjidTable AS toid
                        WHERE toid.TempTable_ID > @MinBatchRow
                              AND toid.classID = @classID
                        ORDER BY toid.TempTable_ID)
                    SELECT @MinBatchRow = CASE
                                              WHEN @MinBatchRow < @MaxBatchrow THEN
                                                  MAX (cte.TempTable_ID)
                                              ELSE
                                                  NULL
                                          END
                    FROM cte;

                    SET @DebugText = N'batch %i FromRow %i class %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Next ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR (
                                      @DebugText,
                                      10,
                                      1,
                                      @ProcedureName,
                                      @ProcedureStep,
                                      @Batchcount,
                                      @MinBatchRow,
                                      @classID
                                  );
                    END;
                END; --main loop

                SET @Batchcount = 0;

                SELECT @Prop_ID =
                (
                    SELECT MIN (lud.PropertyID)
                    FROM @LastUpdateDatetable AS lud
                    WHERE lud.PropertyID > @Prop_ID
                          AND lud.ClassID = @classID
                          AND lud.PropertyID IS NOT NULL
                );

                SET @DebugText = N' %i class %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Next Property ';

                IF @Debug > 0
                BEGIN
                    RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Prop_ID, @classID);
                END;
            END; -- inner loop on columns

            SELECT @ID =
            (
                SELECT MIN (htu.ID)
                FROM @UpdateList AS htu
                WHERE htu.ID > @ID
                      AND htu.MFID > @classID
            );

            --SELECT MIN (lud.PropertyID)
            --FROM @LastUpdateDatetable  AS lud
            --    INNER JOIN @UpdateList htu
            --        ON lud.ClassID = htu.MFID;

            SELECT @classID = htu.MFID
            FROM @UpdateList htu
            WHERE htu.ID = @ID;

            SET @DebugText = N' %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Next Class ';

            IF @Debug > 0
            BEGIN
                RAISERROR (@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @classID);
            END;

            IF
            (
                SELECT OBJECT_ID ('Tempdb..#objidTable')
            ) IS NOT NULL
                DROP TABLE #ObjidTable;

            SET @Objids = NULL;
            SET @FromObjid = NULL;
            SET @ToObjid = NULL;
        END;

        -- end loop through tables
        ---      END; --end if ChangeHistoryUpdatecontrol exist

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';
        SET @LogStatus = N'Completed';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
            @ProcessType = @ProcessType,
            @LogType = N'Debug',
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE ();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = N'Debug',
            @LogText = @ProcessType,
            @LogStatus = @LogStatus,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = NULL,
            @ColumnValue = NULL,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = 0;

        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @StartTime = GETUTCDATE ();
        SET @LogStatus = N'Failed w/SQL Error';
        SET @LogTextDetail = ERROR_MESSAGE ();

        --------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        --------------------------------------------------
        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ErrorState,
            ErrorSeverity,
            ErrorLine,
            ProcedureStep
        )
        VALUES
        (@ProcedureName, ERROR_NUMBER (), ERROR_MESSAGE (), ERROR_PROCEDURE (), ERROR_STATE (), ERROR_SEVERITY (),
            ERROR_LINE (), @ProcedureStep);

        SET @ProcedureStep = N'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = N'Error',
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE ();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = N'Error',
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatus,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = NULL,
            @ColumnValue = NULL,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = 0;

        RETURN -1;
    END CATCH;
END;
GO