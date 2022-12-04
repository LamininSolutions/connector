PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDropAndUpdateMetadata]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFDropAndUpdateMetadata', -- nvarchar(100)
                                 @Object_Release = '4.10.30.74',              -- varchar(50)
                                 @UpdateFlag = 2;
-- smallint
GO

/*
MODIFICATIONS
*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFDropAndUpdateMetadata' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFDropAndUpdateMetadata
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFDropAndUpdateMetadata
    @IsResetAll SMALLINT = 0,
    @WithClassTableReset SMALLINT = 0,
    @WithColumnReset SMALLINT = 0,
    @IsStructureOnly SMALLINT = 1,
    @RetainDeletions BIT = 0,
    @IsDocumentCollection BIT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
AS
/*rST**************************************************************************

=========================
spMFDropAndUpdateMetadata
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsResetAll smallint (optional)
    - Default = 0
    - 1 = Reset to default values
  @WithClassTableReset smallint (optional)
    - Default = 0
    - 1 = reset all class tables included in App
  @WithColumnReset smallint (optional)
    - Default = 0
    - 1 = automatically reset column datatypes where datatypes changed
  @IsStructureOnly smallint (optional)
    - Default = 0
    - 1 = include updating of all valuelist items or only main structure elements
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To drop and update metadata for usage when creating multiple iterations of metadata and table changes during development.

Additional Info
===============

This procedure will only run if metadata structure changes were made. It is therefore useful to add this procedure as a scheduled agent, or as part of key procedures to keep the structure aligned.

Using this procedure will not overwrite custom settings in the structure tables. The custom columns include: 

================  ====================
Table             Customisable columns
================  ====================
MFClass           IncludedInApp
MFClass           TableName
MFClass           FileExportFolder
MFClass           SynchPresendence
MFProperty        ColumnName
MFValuelistItems  AppRef
MFValuelistItems  Owner_AppRef
================  ====================

This procedure can also be used to reset all the metadata, but retain
the custom settings in the Tables when the default is used or @ISResetAll = 0.

Set @ISResetAll = 1 only when custom settings in SQL should be reset to the defaults.  The following custom settings in the metadata tables. 

Setting the parameter @WithClassTableReset = 1 will drop and recreate all class tables where IncludeInApp = 1.  This is particularly usefull during testing or development to reset the class tables. This parameter is set to 0 by default.

Setting the parameter @WithColumnReset = 1 will force the synchronisation to add missing properties to class tables.  This is particularly handy when a property is added to multiple classes on the metadata cards and requires pull through to the class tables in SQL.  It will also change single lookup to multi lookup columns or visa versa.  This parameter is set to 0 by default.

Use :doc:`/procedures/spMFClassTableColumns/` to review the application and status of properties and columns on class tables.

By default this procedure will not be triggered if only valuelist items have been added in M-Files or no metadata changes have taken place.  To force this procedure to run, set the @IsStructureOnly = 0 to force an update in this scenario. 

Warnings
========

Do no run other procedures (such as spmfupdatetable) while any syncrhonisation of metadata is in progress.

The runtime of this procedure has increased, especially for large complex vaults. This is due to the extended validation checks performed during the procedure.

Not all metadata changes increases the GetMetadataStructureVersionID in M-Files. Changes to valuelist items does not set a version change for metadata changes.

The default options is not appropriate when valuelist items must be included in the update. There are several other methods to achieve the update of valuelist items rapidly, for instance :doc:`/procedures/spMFSynchronizeSpecificMetadata/`

Examples
========

Standard use without any parameters. This will retain all custom settings and only run if changes in M-Files have been detected.

.. code:: sql

     EXEC spMFDropAndUpdateMetadata

Running the procedure with default settings and no structure metadata change has taken place will exit very rapidly.

.. code:: sql

    DECLARE @ProcessBatch_ID INT;
    EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0          
                                          ,@WithClassTableReset = 0 
                                          ,@WithColumnReset = 0     
                                          ,@IsStructureOnly = 1     
                                          ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT 
                                          ,@Debug = 0 

----

To force an update of metadata when only valuelist items have changed or no metadata change has taken place, set the @IsStructureOnly = 0.

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]
               @IsStructureOnly = 0

----

The parameter @IsResetAll will remove all custom settings in SQL and reset the metadata structure to the vault.  This include removing all the class tables. This should only be used as a tool during prototyping and testing use cases.

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]
               @IsResetAll = 1

---

To reset columns when data types have changed, set the @WithColumnReset = 1

.. code:: sql

    EXEC [dbo].[spMFDropAndUpdateMetadata]              
              ,@WithColumnReset = 1
              ,@IsStructureOnly = 0
              

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-09-30  LC         Update documentation regarding column fixes
2020-09-08  LC         Add fixing column errors in datatype 9
2019-08-30  JC         Added documentation
2019-08-27  LC         If exist table then drop, avoid sql error when table not exist
2019-08-06  LC         Change of metadata return value, remove if statement
2019-06-07  LC         Fix bug of not setting lookup table label column with correct type
2019-03-25  LC         Fix bug to update when change has taken place and all defaults are specified
2019-01-20  LC         Add prevent deleting data if license invalid
2019-01-19  LC         Add new feature to fix class table columns for changed properties
2018-11-02  LC         Add new feature to auto create columns for new properties added to class tables
2018-09-01  LC         Add switch to destinguish between structure only on including valuelist items
2018-06-28  LC         Add additional columns to user specific columns fileexportfolder, syncpreference
2017-06-20  LC         Fix begin tran bug
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

DECLARE @ProcedureStep VARCHAR(100) = 'start',
        @ProcedureName NVARCHAR(128) = N'spMFDropAndUpdateMetadata';
DECLARE @RC INT;
DECLARE @ProcessType NVARCHAR(50) = N'Metadata Sync';
DECLARE @LogType NVARCHAR(50);
DECLARE @LogText NVARCHAR(4000);
DECLARE @LogStatus NVARCHAR(50);
DECLARE @MFTableName NVARCHAR(128);
DECLARE @Update_ID INT;
DECLARE @LogProcedureName NVARCHAR(128);
DECLARE @LogProcedureStep NVARCHAR(128);
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

---------------------------------------------
-- ACCESS CREDENTIALS FROM Setting TABLE
---------------------------------------------

--used on MFProcessBatchDetail;
DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
DECLARE @EndTime DATETIME;
DECLARE @StartTime DATETIME;
DECLARE @StartTime_Total DATETIME = GETUTCDATE();
DECLARE @Validation_ID INT;
DECLARE @LogColumnName NVARCHAR(128);
DECLARE @LogColumnValue NVARCHAR(256);
DECLARE @error AS INT = 0;
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT;

--Custom declarations
DECLARE @Datatype INT;
DECLARE @Property NVARCHAR(100);
DECLARE @rownr INT;
DECLARE @IsUpToDate BIT;
DECLARE @Count INT;
DECLARE @Length INT;
DECLARE @SQLDataType NVARCHAR(100);
DECLARE @MFDatatype_ID INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @rowID INT;
DECLARE @MaxID INT;
DECLARE @ColumnName VARCHAR(100);

BEGIN TRY

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = 'Start Logging';
    SET @LogText = N'Processing ';

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcedureName,
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
                                           @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT;

    -------------------------------------------------------------
    -- Validate license
    -------------------------------------------------------------
    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'validate lisense';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    DECLARE @VaultSettings NVARCHAR(4000);

    SELECT @VaultSettings = dbo.FnMFVaultSettings();

    EXEC @return_value = dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFGetClass', -- nvarchar(500)
                                                    @ProcedureName = @ProcedureName,         -- nvarchar(500)
                                                    @ProcedureStep = @ProcedureStep,
                                                    @ProcessBatch_ID = @processbatch_ID;

    SET @DebugText = N'License Return %s';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = '';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @return_value);
    END;

    -------------------------------------------------------------
    -- Get up to date status
    -------------------------------------------------------------
    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Get Structure Version ID';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    EXEC dbo.spMFGetMetadataStructureVersionID @IsUpToDate OUTPUT;

    SELECT @IsUpToDate = CASE
                             WHEN @IsResetAll = 1 THEN
                                 0
                             ELSE
                                 @IsUpToDate
                         END;
    -------------------------------------------------------------
    -- if Full refresh
    -------------------------------------------------------------


    IF (
           @IsUpToDate = 0
           AND @IsStructureOnly = 0
       )
       OR
       (
           @IsUpToDate = 1
           AND @IsStructureOnly = 0
       )
       OR
       (
           @IsUpToDate = 0
           AND @IsStructureOnly = 1
       )
       OR @IsResetAll = 1
    BEGIN

        SET @DebugText = N' Full refresh';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Refresh started ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



        -------------------------------------------------------------
        -- License is valid - continue
        -------------------------------------------------------------			
        --    IF @return_value = 0 -- license validation returns 0 if correct

        SELECT @ProcedureStep = 'setup temp tables';

        -------------------------------------------------------------
        -- setup temp tables
        -------------------------------------------------------------
   
   
   IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#MFClassTemp')
        BEGIN
            DROP TABLE #MFClassTemp;
        END;

        IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = '#MFPropertyTemp')
        BEGIN
            DROP TABLE #MFPropertyTemp;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM sys.sysobjects
            WHERE name = '#MFValuelistItemsTemp'
        )
        BEGIN
            DROP TABLE #MFValuelistItemsTemp;
        END;


        IF EXISTS
        (
            SELECT *
            FROM sys.sysobjects
            WHERE name = '#MFWorkflowStateTemp'
        )
        BEGIN
            DROP TABLE #MFWorkflowStateTemp;
        END;

          SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
 
        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



        -------------------------------------------------------------
        -- Populate temp tables
        -------------------------------------------------------------
        SET @ProcedureStep = 'Populate temp tables ';

        --Insert Current MFClass table data into temp table
        SELECT *
        INTO #MFClassTemp
        FROM
        (SELECT * FROM dbo.MFClass) AS cls;

        --Insert current MFProperty table data into temp table
        SELECT *
        INTO #MFPropertyTemp
        FROM
        (SELECT * FROM dbo.MFProperty) AS ppt;

        --Insert current MFProperty table data into temp table
        SELECT *
        INTO #MFValuelistItemsTemp
        FROM
        (SELECT * FROM dbo.MFValueListItems) AS ppt;

        SELECT *
        INTO #MFWorkflowStateTemp
        FROM
        (SELECT * FROM dbo.MFWorkflowState) AS WST;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT *
            FROM #MFClassTemp AS mct;

            SELECT *
            FROM #MFPropertyTemp AS mpt;

            SELECT *
            FROM #MFValuelistItemsTemp AS mvit;

            SELECT *
            FROM #MFWorkflowStateTemp AS mwst;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- delete data from main tables
        -------------------------------------------------------------
        SET @ProcedureStep = 'Delete existing tables';

        IF
        (
            SELECT COUNT(*) FROM #MFClassTemp AS mct
        ) > 0
        BEGIN
            DELETE FROM dbo.MFClassProperty
            WHERE MFClass_ID > 0;

            DELETE FROM dbo.MFClass
            WHERE ID > -99;

            DELETE FROM dbo.MFProperty
            WHERE ID > -99;

            DELETE FROM dbo.MFValueListItems
            WHERE ID > -99;

            DELETE FROM dbo.MFValueList
            WHERE ID > -99;

            DELETE FROM dbo.MFWorkflowState
            WHERE ID > -99;

            DELETE FROM dbo.MFWorkflow
            WHERE ID > -99;

            DELETE FROM dbo.MFObjectType
            WHERE ID > -99;

            DELETE FROM dbo.MFLoginAccount
            WHERE ID > -99;

            DELETE FROM dbo.MFUserAccount
            WHERE UserID > -99;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        --delete if count(*) #classTable > 0
        -------------------------------------------------------------
        -- get new data
        -------------------------------------------------------------
        SET @ProcedureStep = 'Start new Synchronization';
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --Synchronize metadata
        EXEC @return_value = dbo.spMFSynchronizeMetadata @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                         @Debug = @Debug;

        SET @ProcedureName = N'spMFDropAndUpdateMetadata';

        IF @Debug > 0
        BEGIN
            SELECT *
            FROM dbo.MFClass;

            SELECT *
            FROM dbo.MFProperty;
        END;

        SET @DebugText = N' Reset %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @IsResetAll);
        END;

        -------------------------------------------------------------
        -- update custom settings from previous data
        -------------------------------------------------------------
        --IF synchronize is success
        IF (@return_value = 1 AND @IsResetAll = 0)
        BEGIN
            SET @ProcedureStep = 'Update with no reset';

            UPDATE dbo.MFClass
            SET TableName = #MFClassTemp.TableName,
                IncludeInApp = #MFClassTemp.IncludeInApp,
                FileExportFolder = #MFClassTemp.FileExportFolder,
                SynchPrecedence = #MFClassTemp.SynchPrecedence
            FROM dbo.MFClass
                INNER JOIN #MFClassTemp
                    ON MFClass.MFID = #MFClassTemp.MFID
                       AND MFClass.Name = #MFClassTemp.Name;

            UPDATE dbo.MFProperty
            SET ColumnName = tmp.ColumnName
            FROM dbo.MFProperty AS mfp
                INNER JOIN #MFPropertyTemp AS tmp
                    ON mfp.MFID = tmp.MFID
                       AND mfp.Name = tmp.Name;

            UPDATE dbo.MFValueListItems
            SET AppRef = tmp.AppRef,
                Owner_AppRef = tmp.Owner_AppRef
            FROM dbo.MFValueListItems AS mfp
                INNER JOIN #MFValuelistItemsTemp AS tmp
                    ON mfp.MFID = tmp.MFID
                       AND mfp.Name = tmp.Name;

            UPDATE dbo.MFWorkflowState
            SET IsNameUpdate = 1
            FROM dbo.MFWorkflowState AS mfws
                INNER JOIN #MFWorkflowStateTemp AS tmp
                    ON mfws.MFID = tmp.MFID
                       AND mfws.Name != tmp.Name;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        -- update old data
        -------------------------------------------------------------
        -- Class table reset
        -------------------------------------------------------------	
        IF @WithClassTableReset = 1
        BEGIN
            SET @ProcedureStep = 'Class table reset';

            DECLARE @ErrMsg VARCHAR(200);

            SET @ErrMsg = 'datatype of property has changed';

            --RAISERROR(
            --             'Proc: %s Step: %s ErrorInfo %s '
            --            ,16
            --            ,1
            --            ,'spMFDropAndUpdateMetadata'
            --            ,'datatype of property has changed, tables or columns must be reset'
            --            ,@ErrMsg
            --         );
            CREATE TABLE #TempTableName
            (
                ID INT IDENTITY(1, 1),
                TableName VARCHAR(100)
            );

            INSERT INTO #TempTableName
            SELECT DISTINCT
                   TableName
            FROM dbo.MFClass
            WHERE IncludeInApp IS NOT NULL;

            DECLARE @TCounter INT,
                    @TMaxID INT,
                    @TableName VARCHAR(100);

            SELECT @TMaxID = MAX(ID)
            FROM #TempTableName;

            SET @TCounter = 1;

            WHILE @TCounter <= @TMaxID
            BEGIN
                DECLARE @ClassName VARCHAR(100);

                SELECT @TableName = TableName
                FROM #TempTableName
                WHERE ID = @TCounter;

                SELECT @ClassName = Name
                FROM dbo.MFClass
                WHERE TableName = @TableName;

                IF EXISTS
                (
                    SELECT K_Table = FK.TABLE_NAME,
                           FK_Column = CU.COLUMN_NAME,
                           PK_Table = PK.TABLE_NAME,
                           PK_Column = PT.COLUMN_NAME,
                           Constraint_Name = C.CONSTRAINT_NAME
                    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
                        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK
                            ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK
                            ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU
                            ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
                        INNER JOIN
                        (
                            SELECT i1.TABLE_NAME,
                                   i2.COLUMN_NAME
                            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
                                INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2
                                    ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
                            WHERE i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
                        ) PT
                            ON PT.TABLE_NAME = PK.TABLE_NAME
                    WHERE PK.TABLE_NAME = @TableName
                )
                BEGIN
                    SET @ErrMsg = 'Can not drop table ' + +'due to the foreign key';

                    RAISERROR(
                                 'Proc: %s Step: %s ErrorInfo %s ',
                                 16,
                                 1,
                                 'spMFDropAndUpdateMetadata',
                                 'Foreign key reference',
                                 @ErrMsg
                             );
                END;
                ELSE
                BEGIN

                    IF
                    (
                        SELECT OBJECT_ID(@TableName)
                    ) IS NOT NULL
                    BEGIN
                        EXEC ('Drop table ' + @TableName);

                        PRINT 'Drop table ' + @TableName;
                    END;

                    EXEC dbo.spMFCreateTable @ClassName;

                    PRINT 'Created table' + @TableName;
                    PRINT 'Synchronizing table ' + @TableName;

EXEC dbo.spMFUpdateTable @MFTableName = @Tablename,
                         @UpdateMethod = 1,
                         @ProcessBatch_ID = @ProcessBatch_ID,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug



                END;

                SET @TCounter = @TCounter + 1;
            END;

            DROP TABLE #TempTableName;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        --class table reset

        -------------------------------------------------------------
        -- perform validations
        -------------------------------------------------------------
        IF @WithColumnReset = 1
        BEGIN

            EXEC dbo.spMFClassTableColumns;

            SELECT 
            @Count =
                 (SUM(ISNULL(ColumnDataTypeError, 0)) + SUM(ISNULL(missingColumn, 0)) + SUM(ISNULL(MissingTable, 0))
                   + SUM(ISNULL(RedundantTable, 0))
                  )
            FROM ##spmfclasstablecolumns;

            IF @Count > 0
            BEGIN
                SET @DebugText = N' Count of errors %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Perform validations';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                END;

                -------------------------------------------------------------
                -- Data type errors
                -------------------------------------------------------------
                SET @Count = 0;

                SELECT @Count = SUM(ISNULL(ColumnDataTypeError, 0))
                FROM ##spmfclasstablecolumns;

                IF @Count > 0
                BEGIN
                    SET @DebugText = N' %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Data Type Error ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    END;
                END;

                BEGIN
                    -------------------------------------------------------------
                    -- Resolve Class table column errors
                    -------------------------------------------------------------					;
                    SET @rowID =
                    (
                        SELECT MIN(id) FROM ##spMFClassTableColumns WHERE ColumnDataTypeError = 1
                    );

                    WHILE @rowID IS NOT NULL
                    BEGIN
                        SELECT @TableName = TableName,
                               @ColumnName = ColumnName,
                               @MFDatatype_ID = MFDatatype_ID
                        FROM ##spMFClassTableColumns
                        WHERE id = @rowID;

                        SELECT @SQLDataType = mdt.SQLDataType
                        FROM dbo.MFDataType AS mdt
                        WHERE mdt.MFTypeID = @MFDatatype_ID;

                        --				SELECT * FROM dbo.MFDataType AS mdt

                        SET @DebugText = N'';
                        SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = 'Datatype error in 1,9,10,13 in column %s';

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep, @ColumnName);
                        END;

                        --	SELECT @TableName,@columnName,@SQLDataType
                        IF @MFDatatype_ID IN ( 1, 9, 10, 13 )
                        BEGIN TRY
                            SET @SQL
                                = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ALTER COLUMN ' + QUOTENAME(@ColumnName)
                                  + N' ' + @SQLDataType + N';';
                            IF @Debug = 0
                                SELECT @SQL;

                            EXEC (@SQL);

                        END TRY
                        BEGIN CATCH
                            RAISERROR('Unable to change column %s in Table %s', 16, 1, @ColumnName, @TableName);
                        END CATCH;

                        SELECT @rowID =
                        (
                            SELECT MIN(id)
                            FROM ##spMFClassTableColumns
                            WHERE id > @rowID
                                  AND ColumnDataTypeError = 1
                        );
                    END; --end loop column reset
                END;

                --end WithcolumnReset

                -------------------------------------------------------------
                -- resolve missing column
                -------------------------------------------------------------
                SET @Count = 0;

                SELECT @Count = SUM(ISNULL(missingColumn, 0))
                FROM ##spmfclasstablecolumns;

                IF @Count > 0
                BEGIN
                    SET @DebugText = N' %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Missing Column Error ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    END;

                    /*
check table before update and auto create any columns
--check existence of table
*/
                    SET @rownr =
                    (
                        SELECT MIN(id) FROM ##spMFClassTableColumns WHERE MissingColumn = 1
                    );

                    WHILE @rownr IS NOT NULL
                    BEGIN
                        SELECT @MFTableName = mc.Tablename,
                               @SQLDataType = mdt.SQLDataType,
                               @ColumnName = mc.ColumnName,
                               @Datatype = mc.MFDatatype_ID,
                               @Property = mc.Property
                        FROM ##spMFclassTableColumns mc
                            INNER JOIN dbo.MFDataType AS mdt
                                ON mc.MFDatatype_ID = mdt.MFTypeID
                        WHERE mc.ID = @rownr;

                        IF @Datatype = 9
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + N' Add ' + QUOTENAME(@ColumnName)
                                  + N' Nvarchar(100);';

                            EXEC sys.sp_executesql @SQL;

                            PRINT '##### ' + @Property + ' property as column ' + QUOTENAME(@ColumnName)
                                  + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;
                        ELSE IF @Datatype = 10
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + N' Add ' + QUOTENAME(@ColumnName)
                                  + N' Nvarchar(4000);';

                            EXEC sys.sp_executesql @SQL;

                            PRINT '##### ' + @Property + ' property as column ' + QUOTENAME(@ColumnName)
                                  + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;
                        ELSE
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + N' Add ' + @ColumnName + N' '
                                  + @SQLDataType + N';';

                            EXEC sys.sp_executesql @SQL;

                            PRINT '##### ' + @ColumnName + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;

                        SELECT @rownr =
                        (
                            SELECT MIN(mc.id)
                            FROM ##spMFClassTableColumns mc
                            WHERE MissingColumn = 1
                                  AND mc.id > @rownr
                        );
                    END; -- end of loop
                END; -- End of mising columns

            -------------------------------------------------------------
            -- resolve missing table
            -------------------------------------------------------------

            -------------------------------------------------------------
            -- resolve redundant table
            -------------------------------------------------------------


            --check for any adhoc columns with no data, remove columns
            --check and update indexes and foreign keys
            END; --Validations
        END; -- column reset


        SET @DebugText = N' %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Drop temp tables ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        END;

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#MFClassTemp')
        BEGIN
            DROP TABLE #MFClassTemp;
        END;

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#MFPropertyTemp')
        BEGIN
            DROP TABLE #MFPropertyTemp;
        END;

        IF EXISTS
        (
            SELECT *
            FROM sys.sysobjects
            WHERE name = '#MFValueListitemTemp'
        )
        BEGIN
            DROP TABLE #MFValueListitemTemp;
        END;

 
        SET NOCOUNT OFF;

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        SET @LogStatus = N'Completed';
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'End of process';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                         @ProcessType = @ProcedureName,
                                         @LogType = N'Message',
                                         @LogText = @LogText,
                                         @LogStatus = @LogStatus,
                                         @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                               @LogType = N'Message',
                                               @LogText = @ProcessType,
                                               @LogStatus = @LogStatus,
                                               @StartTime = @StartTime,
                                               @MFTableName = @MFTableName,
                                               @Validation_ID = @Validation_ID,
                                               @ColumnName = '',
                                               @ColumnValue = '',
                                               @Update_ID = @Update_ID,
                                               @LogProcedureName = @ProcedureName,
                                               @LogProcedureStep = @ProcedureStep,
                                               @debug = 0;





    END; -- is updatetodate and istructure only
    ELSE
    BEGIN
        PRINT '###############################';
        PRINT 'Metadata structure is up to date';
    END; --else: no processing, upto date
    RETURN 1;
END TRY
BEGIN CATCH
    IF @@TranCount > 0
        ROLLBACK;

    SET @StartTime = GETUTCDATE();
    SET @LogStatus = N'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

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
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
     @ProcedureStep);

    SET @ProcedureStep = 'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Error',
                                     @LogText = @LogTextDetail,
                                     @LogStatus = @LogStatus,
                                     @debug = @Debug;

    SET @StartTime = GETUTCDATE();

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
GO
