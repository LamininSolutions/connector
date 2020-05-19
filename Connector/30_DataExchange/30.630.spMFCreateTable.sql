PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateTable]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFCreateTable', -- nvarchar(100)
    @Object_Release = '4.7.18.59',    -- varchar(2506
    @UpdateFlag = 2;

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFCreateTable' --name of procedure
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
CREATE PROCEDURE dbo.spMFCreateTable
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFCreateTable
(
    @ClassName NVARCHAR(128),
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

===============
spMFCreateTable
===============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ClassName nvarchar(128)
    - Valid Class Name as a string
    - Pass the class name, e.g.: 'Customer'
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To create table for a class with associate properties and other custom columns (like ID, GUID, MX\_User\_ID, MFID, ExternalID, MFVersion, FileCount, IsSingleFile, Update\_ID, and LastModified)
The column **IncludedInApp** in the MFCLass table is set to 1 for the created class table.

Additional Info
===============

Class tables are not added by the Connector on deployment. The class tables are added by the developer using the Connector for those M-Files classes that will be used in the application.

Table Name
----------

The name of the class table is defined in column TableName in the MFClass Table. The Connector will create a default name for all the tables. These names can be customised.

Column Name
-----------

The name of the column is defined in the MFProperty Table in **ColumnName**. These names can be customised.
Several special columns are automatically created:

- Metadata structure properties
- Standard or system properties
- Additional properties
- Columns for special purposes
- Non Connector columns

The column order also has a very specific order.

Property Column Definitions
---------------------------

The metadata structure property columns in the Class Table is defined in the MFClassProperty table.
Single and multi-lookup properties will have both a label column and a ID column, for example Customer and Customer_ID. The label column is incidental and does not have to be updated when changes are made. Only the ID have to be updated. The name column will be automatically refreshed from the metadata.
If the metadata is a required property as defined in the MFClassProperty table then the column will be created with a NOT NULL constraint.

MF Addidional Property
----------------------

M-Files allow the addition of ad-hoc properties. When a property is dropped from the metadata definition in M-Files and already have values on an object, then the property will retain its value.

When the Connector finds an additional property on an object, and it is not part of the metadata card, then a column will be added to the end of the Class Table with the columnname and datatype definitions as previously described.

Non Connector Columns
---------------------

It is possible to add columns to the class table that will be ignored by the Connector but is available for processing in the application. These columns must have a prefix of MX\_ (for example MX_SAGE_Code)

Notwithstanding the ability to add additional columns to the Connector tables following the convension above, it is recommended to create additional tables for custom applications that is cross referenced to the Connector tables rather than adding columns to Connector tables.

Special columns
---------------

=======================  ===============  ================================================================  ================
Column                   Description      Special application                                               Updateable
-----------------------  ---------------  ----------------------------------------------------------------  ----------------
Workflow_ID              MF Workflow_ID   Always include workflow ID when inserting or updating the state   Updatable
Workflow                 MF Workflow      For information only, not required to be updated                  From M-Files
Update_ID                SQL history log  ID of history log when record was last updated                    SQL only, Read only
State_ID                 MF State_ID      Used to update or insert a state                                  Updatable
State                    MF State         For information only, not required to be updated                  From M-Files
Process_ID               SQL process ID   Show status of process of record. Default value is 0              Flag
ObjID                    MF Internal ID   Leave blank when new records is created in SQL                    From M-Files
MX_User_ID               SQL User ID      External applications SQL user ID for the record                  SQL only
MFVersion                MF Version       Last MF Version                                                   From M-Files
MF_Last_Modified_By_ID   MF user id                                                                         From M-Files
MF_Last_Modified_By      MFuser name                                                                        From M-Files
MF_Last_Modified         last modified    M-Files last modified in UTC datetime format                      From M-Files
LastModified             last modified    When SQL last updated, SQL server Local time format               Default Getdate()
IsSingleFile             MF Single File   Show status of the Single File property in M-Files.               From M-Files, Updatable
ID                       Identity         Record id in SQL                                                  SQL Only
GUID                     MF object Guid   Used for creating ULR links to record                             From M-Files
FileCount                MF File Count    Count of files included in the object                             From M-Files
ExternalID               MF External ID   MF displayID, must be unique                                      Updatable
Deleted                  MF Deleted       Deletion Status of record in MF                                   From M-Files
Created                  MF Created date  In UTC datetime format                                            From M-Files
=======================  ===============  ================================================================  ================

Prerequisites
=============

Class name exist
MFClass table contains names of the valid classes

Warnings
========

Drop and recreate to reset a class table when the table name is customised in MFClass
When an additional property is added in M-Files to an object the column will automatically be added at the end of the table.

Examples
========

.. code:: sql

   EXEC spMFCreateTable 'Customer'

----

.. code:: sql

   DECLARE    @return_value int
   EXEC       @return_value = [dbo].[spMFCreateTable]
              @ClassName =  N'Customer'
   SELECT    'Return Value'  = @return_value
   GO


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2015-05-23  DEV2       Default column ExternalID added
2015-05-25  DEV2       Default column Update_ID added
2016-06-27  LC         Automatically add includeInApp if null
2016-08-18  LC         Add system columns with localized text names that is required for creating a new record
2016-09-10  LC         Set process_ID default to 1 and deleted default to 0 on creating new record
2016-10-02  LC         Update multi lookup columns to nvarchar(4000)
2016-10-13  DEV2       Added Single_File Column in Class table
2016-10-15  LC         Change Default of Single_file to 0
2017-07-06  LC         Add new default column for FileCount
2017-11-29  LC         Add error message of file does not exist or table already exist
2018-04-17  LC         Add condition to only create trigger on table if includedinApp is set to 2 (for transaction based tables.)
2018-10-30  LC         Add creating unique index on objid and externalid
2019-09-20  LC         allow for ID at end of name of a lookup property
2019-10-14  LC         Resolve multilookup table data type incorrectly set
2019-12-01  LC         Resolve where duplicate columns exist and removal of ID
2020-03-11  LC         Add check license
2020-03-18  LC         Add non clustered unique index for objid
2020-03-27  LC         Add MFSetting to allow optional create of indexes
2020-04-22  LC         Improve naming of constraints
2020-05-12  LC         Add index on Update_ID to improve performance
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -------------------------------------------------------------
        -- Local variable Declaration
        -------------------------------------------------------------
        DECLARE @Output    NVARCHAR(200),
            @ClassID       INT,
            @TableName     NVARCHAR(128),
            @dsql          NVARCHAR(MAX) = N'',
            @ConstColumn   NVARCHAR(MAX),
            @IDColumn      NVARCHAR(MAX),
            @Count         INT,
            @ProcedureName sysname       = 'spMFCreateTable',
            @ProcedureStep sysname       = 'Start';

        -------------------------------------------------------------
        --Check if the name exixsts in MFClass
        -------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM dbo.MFClass
            WHERE Name = @ClassName
                  AND Deleted = 0
        )
        BEGIN
            -------------------------------------------------------------
            -- Check license
            -------------------------------------------------------------
            ------------------------------------------------------
            --Validating Module for calling CLR Procedure
            ------------------------------------------------------
            EXEC dbo.spMFCheckLicenseStatus 'spMFCreateTable',
                'spMFCreateTable',
                'Create Table';

            -------------------------------------------------------------
            --SELECT PROPERTY NAME AND DATA TYPE
            -------------------------------------------------------------
            SET @ProcedureStep = 'SELECT PROPERTY NAME AND DATA TYPE';

            SELECT *
            INTO #Temp
            FROM
            (
                SELECT ColumnName,
                    MFDataType_ID,
                    ID
                FROM dbo.MFProperty
                WHERE ID IN
                      (
                          SELECT MFProperty_ID
                          FROM dbo.MFClassProperty
                          WHERE Deleted = 0
                                AND MFClass_ID =
                                (
                                    SELECT ID FROM dbo.MFClass WHERE Name = @ClassName AND Deleted = 0
                                )
                      )
            ) AS columnNameAndDataType;

            SELECT @ClassID = ID
            FROM dbo.MFClass
            WHERE Name = @ClassName
                  AND Deleted = 0;

            ALTER TABLE #Temp ADD PredefinedOrAutomatic BIT;

            IF @Debug = 1
            BEGIN
                SELECT *
                FROM #Temp AS t;

                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -----------------------------------------------------------------
            --Updating PredefinedOrAutomatic with values from MFClassProperty
            -----------------------------------------------------------------
            SET @ProcedureStep = 'Updating PredefinedOrAutomatic with values from MFClassProperty';

            UPDATE #Temp
            SET PredefinedOrAutomatic =
                (
                    SELECT Required
                    FROM dbo.MFClassProperty
                    WHERE MFProperty_ID = ID
                          AND MFClass_ID = @ClassID
                );

            -----------------------------------------------------------------------------
            --Checking if the required property is autocalculated 
            --     or predefined,if yes, Updating required = FALSE
            -----------------------------------------------------------------------------
            UPDATE #Temp
            SET PredefinedOrAutomatic =
                (
                    SELECT 1 ^ PredefinedOrAutomatic FROM dbo.MFProperty WHERE ID = #Temp.ID
                )
            WHERE PredefinedOrAutomatic = 1;

            IF @Debug = 1
                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------------------------------
            --CHANGE THE 'MFDataType_ID' COLUMN DATA TYPE TO 'NVARCHAR(250)'
            -----------------------------------------------------------------------------
            SET @ProcedureStep = 'CHANGE THE MFDataType_ID COLUMN DATA TYPE TO NVARCHAR(100)';

            ALTER TABLE #Temp DROP COLUMN ID;

            ALTER TABLE #Temp ALTER COLUMN MFDataType_ID NVARCHAR(250);

            SELECT @TableName = TableName
            FROM dbo.MFClass
            WHERE Name = @ClassName;

            IF @Debug = 1
                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------------------------------
            --Check If the table already Existing in DB or not
            -----------------------------------------------------------------------------
            SET @ProcedureStep = 'Check If the table already Existing in DB or not';

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.sysobjects
                WHERE id = OBJECT_ID(N'[dbo].[' + @TableName + ']')
                      AND OBJECTPROPERTY(id, N'IsUserTable') = 1
            )
            BEGIN
                INSERT INTO #Temp
                (
                    ColumnName,
                    MFDataType_ID,
                    PredefinedOrAutomatic
                )
                SELECT *
                FROM
                (
                    SELECT CASE
                               WHEN SUBSTRING(ColumnName, LEN(ColumnName) - 2, 3) = '_ID' THEN
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 3)
                               ELSE
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 5)
                                   + REPLACE((SUBSTRING(ColumnName, (LEN(ColumnName) - 4), 5)), '_ID', '')
                           END  AS ColumnName,
                        1       AS MFDataType_ID,
                        'False' AS PredefinedOrAutomatic
                    FROM #Temp
                    WHERE MFDataType_ID IN
                          (
                              SELECT ID FROM dbo.MFDataType WHERE MFTypeID IN ( 9 )
                          )
                ) AS n1
                UNION ALL
                SELECT *
                FROM
                (
                    SELECT CASE
                               WHEN SUBSTRING(ColumnName, LEN(ColumnName) - 2, 3) = '_ID' THEN
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 3)
                               ELSE
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 5)
                                   + REPLACE((SUBSTRING(ColumnName, (LEN(ColumnName) - 4), 5)), '_ID', '')
                           END  AS ColumnName,
                        9       AS MFDataType_ID,
                        'False' AS PredefinedOrAutomatic
                    FROM #Temp
                    WHERE MFDataType_ID IN
                          (
                              SELECT ID FROM dbo.MFDataType WHERE MFTypeID = 10
                          )
                ) AS n2;

                IF @Debug = 1
                BEGIN
                    SELECT *
                    FROM #Temp;

                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -----------------------------------------------------------------------------
                --CHANGE THE FKID WITH SQLDATATYPE
                -----------------------------------------------------------------------------
                UPDATE #Temp
                SET MFDataType_ID =
                    (
                        SELECT SQLDataType FROM dbo.MFDataType WHERE ID = MFDataType_ID
                    );

                -----------------------------------------------------------------------------
                --ALTERING THE #Temp TABLE COLUMN DATATYPE
                -----------------------------------------------------------------------------
                SET @ProcedureStep = 'ALTERING THE #Temp TABLE COLUMN DATATYPE';

                --		IF EXISTS(SELECT name FROM sys.columns WHERE [columns].[object_id] = OBJECT_ID('tempdb..#Temp') AND name = 'PredefinedOrAutomatic')						  
                ALTER TABLE #Temp ALTER COLUMN PredefinedOrAutomatic NVARCHAR(250);

                UPDATE #Temp
                SET PredefinedOrAutomatic = 'NULL'
                WHERE PredefinedOrAutomatic = '0';

                UPDATE #Temp
                --                 SET     PredefinedOrAutomatic = 'NOT NULL'
                SET PredefinedOrAutomatic = 'NULL'
                WHERE PredefinedOrAutomatic = '1';

                IF @Debug = 1
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

                -----------------------------------------------------------------------------
                --Add Additional Default columns in localised text
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'Add Additional Default columns in localised text';

                DECLARE @NameOrTitle   VARCHAR(100),
                    @classPropertyName VARCHAR(100),
                    @Workflow          VARCHAR(100),
                    @State             VARCHAR(100),
                    @SingleFile        VARCHAR(100),
                    @WorkflowName      VARCHAR(100);

                SELECT @NameOrTitle = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 0;

                SELECT @classPropertyName = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 100;

                SELECT @Workflow  = ColumnName,
                    @WorkflowName = Name
                FROM dbo.MFProperty
                WHERE MFID = 38;

                SELECT @State = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 39;

                ------Added By DevTeam2 For Task 937
                SELECT @SingleFile = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 22;

                -------------------------------------------------------------
                -- test duplicates
                -------------------------------------------------------------

                --SELECT @State =   CASE
                --                        WHEN
                --                        (
                --                            SELECT COUNT(*) FROM [#Temp] AS [t] WHERE [t].[ColumnName] = @State

                --                        ) > 0 THEN
                --                            @WorkflowName +'_' + @State
                --                        ELSE
                --                            @State
                --                    END

                ------Added By DevTeam2 For Task 937

                --					SELECT @NameOrTitle,@classPropertyName,@Workflow, @State
                INSERT INTO #Temp
                (
                    ColumnName,
                    MFDataType_ID,
                    PredefinedOrAutomatic
                )
                VALUES
                (@classPropertyName, 'INTEGER', 'NOT NULL'),
                (REPLACE(@classPropertyName, '_ID', ''), 'NVARCHAR(100)', 'NULL'),
                (@Workflow, 'INTEGER', 'NULL'),
                (REPLACE(@Workflow, '_ID', ''), 'NVARCHAR(100)', 'NULL'),
                (@State, 'INTEGER', 'NULL'),
                (REPLACE(@State, '_ID', ''), 'NVARCHAR(100)', 'NULL'),
                (@SingleFile, 'BIT', 'NOT NULL ');

                SET @ProcedureStep = 'Add Class and Name or title';

                ------Added By DevTeam2 For Task 937
                IF NOT EXISTS (SELECT * FROM #Temp AS t WHERE t.ColumnName = @NameOrTitle)
                BEGIN
                    INSERT INTO #Temp
                    (
                        ColumnName,
                        MFDataType_ID,
                        PredefinedOrAutomatic
                    )
                    VALUES
                    (@NameOrTitle, 'NVARCHAR(100)', 'NULL');
                END;

                IF @Debug = 1
                BEGIN
                    SELECT '#Temp',
                        *
                    FROM #Temp;

                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                /*************************************************************************
					  STEP Get id of of class column to set it up as default
					  NOTES
					  */
                DECLARE @ClassCustomName NVARCHAR(100),
                    @ClassMFID           INT;

                SELECT @ClassCustomName = Name
                FROM dbo.MFProperty
                WHERE MFID = 100;

                SELECT @ClassMFID = MFID
                FROM dbo.MFClass
                WHERE ID = @ClassID;

                -----------------------------------------------------------------------------
                --GENERATING THE DYNAMIC QUERY TO CREATE TABLE    
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'GENERATING THE DYNAMIC QUERY TO CREATE TABLE';

                SELECT @IDColumn
                    = N'[ID]  INT IDENTITY(1,1) NOT NULL ,[GUID] NVARCHAR(100),[MX_User_ID]  UNIQUEIDENTIFIER,';

                SELECT @dsql
                    = @dsql + QUOTENAME(ColumnName) + N' ' + MFDataType_ID + N' ' + PredefinedOrAutomatic + N','
                FROM #Temp
                ORDER BY ColumnName;

                SELECT @ConstColumn
                    = N'[LastModified]  DATETIME , ' + N'[Process_ID] INT, ' + N'[ObjID]			INT , '
                      + N'[ExternalID]			NVARCHAR(100) , '
                      + N'[MFVersion]		INT,[FileCount] int , [Deleted] BIT,[Update_ID] int , '; ---- Added for task 106 [FileCount]

                SELECT @dsql = @IDColumn + @dsql + @ConstColumn;

                SELECT @dsql
                    = N'CREATE TABLE ' + QUOTENAME(@TableName) + N' (' + LEFT(@dsql, LEN(@dsql) - 1)
                      + N'
								 CONSTRAINT pk_' + @TableName + N'ID PRIMARY KEY (ID))
									ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_Deleted_'
                      + @TableName + N']  DEFAULT 0 FOR [Deleted]
									ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_Process_id_'
                      + @TableName + N']  DEFAULT 1 FOR [Process_ID]
				    ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_FileCount_' + @TableName
                      + N']  DEFAULT 0 FOR [FileCount]
                       ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_LastModified_' + @TableName
                      + N']  DEFAULT GetDate() FOR [LastModified]
                        ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_'+@SingleFile+'_' + @TableName
                      + N']  DEFAULT 0 FOR '+QUOTENAME(@SingleFile)+'
				     ';

                ---------------------------------------------------------------------------
                --EXECUTE DYNAMIC QUERY TO CREATE TABLE
                -----------------------------------------------------------------------------
                IF @Debug = 1
                BEGIN
                    SELECT @dsql AS CreateTable;
                END;

                EXEC sys.sp_executesql @Stmt = @dsql;

                /*************************************************************************
         STEP alter table to set default for class
         NOTES
         */
                SET @ProcedureStep = 'Set default for Class_ID';

                DECLARE @Params NVARCHAR(100);

                SET @Params = N'@Tablename nvarchar(100)';

                --SELECT  @dsql = N'ALTER TABLE '
                --      + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Class_' + @TableName + '] DEFAULT('+ CAST(@ClassMFID AS VARCHAR(10)) +') FOR '
                --   + QUOTENAME(@ClassCustomName +'_ID') + '';
                SELECT @dsql
                    = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_Class_' + @TableName
                      + N'] DEFAULT(' + CAST(-1 AS VARCHAR(10)) + N') FOR ' + QUOTENAME(@ClassCustomName + '_ID') + N'';

                EXEC sys.sp_executesql @Stmt = @dsql,
                    @Param = @Params,
                    @Tablename = @TableName;

                IF @Debug = 1
                BEGIN
                    SELECT @dsql AS [Alter table for defaults];
                END;

                IF @Debug = 1
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

                -------------------------------------------------------------
                -- ADD standard Logging properties
                -------------------------------------------------------------
                SET @ProcedureStep = 'Add MFSQL_Message and MFSQL_Process_Batch columns';

                DECLARE @IsDetailLogging SMALLINT,
                    @SQL                 NVARCHAR(MAX);

                SELECT @IsDetailLogging = CAST(ISNULL(ms.Value, '0') AS INT)
                FROM dbo.MFSettings AS ms
                WHERE ms.Name = 'App_DetailLogging';

                IF @IsDetailLogging = 1
                    SELECT @Count = COUNT(*)
                    FROM dbo.MFProperty AS mp
                    WHERE mp.Name IN ( 'MFSQL_Message', 'MFSQL_Process_Batch' );

                IF @Count = 2
                BEGIN
                    BEGIN
                        SELECT @Count = COUNT(*)
                        FROM INFORMATION_SCHEMA.COLUMNS AS c
                        WHERE c.COLUMN_NAME = 'MFSQL_Message'
                              AND c.TABLE_NAME = @TableName;

                        IF @Count = 0
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + N'
Add MFSQL_Message nvarchar(max) null;';

                            EXEC (@SQL);
                        END; --columns does not exist on table

                        SELECT @Count = COUNT(*)
                        FROM INFORMATION_SCHEMA.COLUMNS AS c
                        WHERE c.COLUMN_NAME = 'MFSQL_Process_batch'
                              AND c.TABLE_NAME = @TableName;

                        IF @Count = 0
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + N'
Add  MFSQL_Process_batch int null;';

                            EXEC (@SQL);
                        END; --columns does not exist on table
                    END; --properties have been setup
                END;

                --Detail logging  = 1

                -------------------------------------------------------------
                -- Add indexes and foreign keys
                -------------------------------------------------------------
                DECLARE @CreateUniqueIndexes INT;

                SELECT @CreateUniqueIndexes = CAST(ISNULL(ms.Value, '0') AS INT)
                FROM dbo.MFSettings AS ms
                WHERE ms.Name = 'CreateUniqueClassIndexes';

                IF @CreateUniqueIndexes = 1
                BEGIN
                    SET @SQL
                        = N'


ALTER TABLE ' +     QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DF_' + @TableName
                          + N'_ObjID]  DEFAULT (IDENT_CURRENT(''' + @TableName + N''')*(-1)) FOR [ObjID]';

                    EXEC (@SQL);

                    SET @SQL
                        = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_Objid'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                          + N'''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + N'_Objid
ON dbo.' +          @TableName + N'(Objid);';

                    EXEC (@SQL);

                    -------------------------------------------------------------
                    -- Set index on objid
                    -------------------------------------------------------------

                    --select @SQL
                    --           EXEC (@SQL);
                    SET @SQL
                        = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_ExternalID'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                          + N'''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + N'_ExternalID
ON dbo.' +          @TableName + N'(ExternalID)
WHERE ExternalID IS NOT NULL;';

                    EXEC (@SQL);

                    SET @SQL
                        = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_Update_ID'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                          + N'''))
CREATE NONCLUSTERED INDEX IX_' + @TableName + N'_Update_ID
ON dbo.' +          @TableName + N'(Update_ID)
WHERE Update_ID IS NOT NULL;';

                    EXEC (@SQL);

                END;

                /*************************************************************************
STEP Add trigger to table
NOTES
*/
                IF
                (
                    SELECT IncludeInApp FROM dbo.MFClass WHERE TableName = @TableName
                ) = 2
                BEGIN
                    SET @ProcedureStep = 'Create Trigger for table';

                    EXEC dbo.spMFCreateClassTableSynchronizeTrigger @TableName;

                    IF @Debug = 1
                        RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Debug = 1
                    RAISERROR('Table %s Created', 10, 1, @TableName);

                IF (OBJECT_ID('tempdb..#Temp')) IS NOT NULL
                    DROP TABLE #Temp;
            END;
            ELSE
            BEGIN
                -----------------------------------------------------------------------------
                --SHOW ERROR MESSAGE
                -----------------------------------------------------------------------------
                IF @Debug = 1
                    RAISERROR('Table %s Already Exist', 10, 1, @TableName);

                IF (OBJECT_ID('tempdb..#Temp')) IS NOT NULL
                    DROP TABLE #Temp;
            END;
        END;
        ELSE
        BEGIN
            -----------------------------------------------------------------------------
            --SHOW ERROR MESSAGE
            -----------------------------------------------------------------------------
            RAISERROR('Entered Class Name does not Exists in MFClass Table', 10, 1, @ProcedureName, @ProcedureStep);

            IF (OBJECT_ID('tempdb..#Temp')) IS NOT NULL
                DROP TABLE #Temp;

            RETURN -1;
        END;

        -----------------------------------------------------------------------------
        --SET INCLUDEINAPP TO 1 IF NULL
        -----------------------------------------------------------------------------
        SET @ProcedureStep = 'SET INCLUDEINAPP TO 1 IF NULL';

        UPDATE mc
        SET mc.IncludeInApp = 1
        FROM dbo.MFClass AS mc
        WHERE @TableName = mc.TableName
              AND mc.IncludeInApp IS NULL;

        IF @Debug = 1
            RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

        RETURN 1;
    END TRY
    BEGIN CATCH
        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ErrorState,
            ErrorSeverity,
            ErrorLine
        )
        VALUES
        ('spMFCreateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE());

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        SELECT ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE()   AS ErrorMessage,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_STATE()     AS ErrorState,
            ERROR_SEVERITY()  AS ErrorSeverity,
            ERROR_LINE()      AS ErrorLine;

        RETURN 2;
    END CATCH;
END;
GO