
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].spMFClassTableColumns';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFClassTableColumns',
    -- nvarchar(100)
    @Object_Release = '4.8.24.66',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFClassTableColumns' --name of procedure
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
CREATE PROCEDURE dbo.spMFClassTableColumns
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFClassTableColumns
(
    @ErrorsOnly BIT = 1,
    @IsSilent BIT = 0,
    @MFTableName NVARCHAR(200) = NULL,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=====================
spMFClassTableColumns
=====================

Return
  - 1 = Success
  - 0 = Partial (some records failed to be inserted)
  - -1 = Error
Parameters
  @ErrorsOnly bit
    returns a summary of properties with errors
    default is set to 1
  @IsSilent bit
    if set to 1 then no result will be shown
    default is set to 0 (no)
  @MFTableName 
    Result is shown for only specific table
    Default is all tables are shown
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

This special procedure analyses the M-Files classes and show types of columns and any potential anomalies between the metadata structure and the columns for the table in SQL.

The result is useful in trouble shooting.  It is also used internally during the synchronize metadata routines to trap errors.

Additional Info
===============

The report include some columns  to extract and compare data and other columns to interpret or report a status.  Each row represents a property / Class relationship. A listing by class would show all the properties applied on the class, both defined on the metadata card and added ad hoc to the class.  Filtered by property it will show all the classes where the property has been applied to.

Key result columns in report:

ColumnType
  Show the type of usage of the property:

  - Additional property
  - Lookup label
  - M-Files system (related to metadata class)
  - Excluded from M-Files (not related to M-Files properties)
  - MFSQL system property (used for SQL processes)
  - Not used (M-Files property not used in SQL)
Additional Property
  Property column is on class table, but the property is not included in the metadata configuration
Lookup type
  Show if the lookup property relates to a valuelist, another class table, or workflow
Column DataType Error
  Show if there is a miss match between the SQL column data type definition and M-Files data type definition.
Missing Columns
  Show properties on the metadata table that is not included in the class table
Missing Table
  Slow classes defined as included in property but the class table is missing
Redundant table
  Show if class table exist but it is not included in app in class table

The listing will identify the columns added to the table related to Additional properties.

The procedure combines the data from various dimensions including:

- MFProperty + MFClass + MFClassProperty for the M-Files property and class usage
- InformationSchema + MFDataType to compare the structure with the deployment of the structure in SQL

The following design considerations are supported by this result set:

- The use of ad hoc properties on classes.

Examples
========

Without setting any parameters and using defaults. This will only return a result for columns with errors

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] 

Set @ErrorsOnly to No. This will return a the full result

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] @ErrorsOnly = 0

Set @ErrorsOnly to No and a specific table. This will return a the full result for a specific table

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] @ErrorsOnly = 0, @mftableName = 'MFCustomer'

When using the procedure in other routines then set @IsSilent to yes to suppress the result. The global temporary table can then be used in the result

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] @IsSilent = 1
    SELECT * FROM ##spMFClassTableColumns where property_MFID = 27 

The view can also be used to review the class table columns.  Note this view is only up to date after the procedure was executed.

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] @IsSilent = 1
    Select * from MFvwClassTableColumns

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-12-10  LC         update result to improve usage of the procedure
2020-12-10  LC         add new parameters to aid trouble shooting
2020-09-08  LC         Set single lookup column to error when not int
2020-01-24  LC         Fix multitext column showing false error
2019-11-18  LC         Fix bug on column width for multi lookup properties
2019-08-30  JC         Added documentation
2019-08-29  LC         Add predefined or automatic column
2019-06-07  LC         Add error for lookup column label with incorrect length
2019-03-25  LC         Add error checking for text columns that is not varchar 200
2019-01-19  LC         Change datatype from bit to smallint for error columns
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    IF
    (
        SELECT ISNULL(OBJECT_ID('tempdb..##spMFClassTableColumns'), 0)
    ) > 0
        DROP TABLE ##spMFClassTableColumns;

    --SELECT * FROM [dbo].[MFvwClassTableColumns] AS [mfctc]
    DECLARE @IsUpToDate BIT;

    EXEC dbo.spMFGetMetadataStructureVersionID @IsUpToDate = @IsUpToDate OUTPUT; -- bit

    IF @IsUpToDate = 0
    BEGIN
        EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'Property'; -- varchar(100)

        EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'Class'; -- varchar(100)
    END;

    CREATE TABLE ##spMFClassTableColumns
    (
        id INT IDENTITY,
        ColumnType NVARCHAR(100),
        Class NVARCHAR(200),
        TableName NVARCHAR(200),
        Property NVARCHAR(100),
        Property_MFID INT,
        ColumnName NVARCHAR(100),
        AdditionalProperty BIT,
        IncludedInApp BIT,
        Required BIT,
        PredefinedOrAutomatic BIT,
        LookupType NVARCHAR(100),
        MFdataType_ID INT,
        MFDataType NVARCHAR(100),
        Column_DataType NVARCHAR(100),
        Length INT,
        ColumnDataTypeError SMALLINT,
        MissingColumn SMALLINT,
        MissingTable SMALLINT,
        RedundantTable SMALLINT
    );

    INSERT INTO ##spMFClassTableColumns
    (
        Property,
        Property_MFID,
        ColumnName,
        Class,
        TableName,
        IncludedInApp,
        Required,
        PredefinedOrAutomatic,
        LookupType,
        MFdataType_ID,
        MFDataType,
        AdditionalProperty
    )
    SELECT mp2.Name property,
        mp2.MFID,
        mp2.ColumnName,
        mc2.Name    AS class,
        mc2.TableName,
        mc2.IncludeInApp,
        mcp2.Required,
        mp2.PredefinedOrAutomatic,
        CASE
            WHEN mvl.RealObjectType = 1
                 AND mdt.MFTypeID IN ( 9, 10 ) THEN
                'ClassTable_' + mvl.Name
            WHEN mvl.RealObjectType = 0
                 AND mvl.Name NOT IN ( 'class', 'Workflow', 'Workflow State' )
                 AND mdt.MFTypeID IN ( 9, 10 ) THEN
                'Table_MFValuelist_' + mvl.Name
        END,
        mdt.MFTypeID,
        mdt.Name,
        0
    --select *
    FROM dbo.MFProperty                AS mp2
        INNER JOIN dbo.MFClassProperty AS mcp2
            ON mcp2.MFProperty_ID = mp2.ID
        INNER JOIN dbo.MFClass         AS mc2
            ON mc2.ID = mcp2.MFClass_ID
        INNER JOIN dbo.MFDataType      AS mdt
            ON mdt.ID = mp2.MFDataType_ID
        INNER JOIN dbo.MFValueList     AS mvl
            ON mvl.ID = mp2.MFValueList_ID
    --		WHERE mc2.name = 'Customer';
    ;

    MERGE INTO ##spMFClassTableColumns t
    USING
    (
        SELECT sc.name      AS ColumnName,
            sc.max_length   AS length,
            sc.is_nullable,
            st.name         AS TableName,
            t.name          AS Column_DataType,
            mc.Name         AS class,
            mc.IncludeInApp AS IncludedInApp
        FROM sys.columns           sc
            INNER JOIN sys.tables  st
                ON st.object_id = sc.object_id
            INNER JOIN dbo.MFClass AS mc
                ON mc.TableName = st.name
            INNER JOIN sys.types   AS t
                ON sc.user_type_id = t.user_type_id
    --              WHERE sc.name = 'Mfiles_Edition_ID'
    ) s
    ON s.ColumnName = t.columnName
       AND s.TableName = t.TableName
    WHEN MATCHED THEN
        UPDATE SET t.column_DataType = s.Column_DataType,
            t.length = s.length,
            t.IncludedInApp = s.IncludedInApp
    WHEN NOT MATCHED THEN
        INSERT
        (
            TableName,
            columnName,
            column_DataType,
            length,
            Class,
            IncludedInApp
        )
        VALUES
        (s.TableName, s.ColumnName, s.Column_DataType, s.length, s.class, s.IncludedInApp);

    UPDATE ##spMFClassTableColumns
    SET Property = mp.Name,
        Property_MFID = mp.MFID,
        MFdataType_ID = mdt.MFTypeID,
        MFDataType = mdt.Name,
        Required = 0,
        LookupType = CASE
                         WHEN mp.MFID = 100 THEN
                             'Table_MFClass'
                         WHEN mp.MFID = 38 THEN
                             'Table_MFWorkflow'
                         WHEN mp.MFID = 39 THEN
                             'Table_MFWorkflowState'
                     END
    FROM ##spMFClassTableColumns  AS pc
        INNER JOIN dbo.MFProperty AS mp
            ON pc.columnName = mp.ColumnName
        INNER JOIN dbo.MFDataType mdt
            ON mp.MFDataType_ID = mdt.ID
    WHERE pc.Property IS NULL;

    UPDATE ##spMFClassTableColumns
    SET AdditionalProperty = CASE
                                 WHEN pc.Property IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                                     0
                                 WHEN pc.columnName IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount', 'Deleted',
                                                           'Update_ID'
                                                       ) THEN
                                     0
                                 WHEN SUBSTRING(pc.columnName, 1, 2) = 'MX' THEN
                                     0
                                 WHEN pc.Property_MFID > 101
                                      AND pc.AdditionalProperty IS NULL THEN
                                     1
                             END
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.AdditionalProperty IS NULL;

    UPDATE ##spMFClassTableColumns
    SET ColumnType = CASE
                         WHEN IncludedInApp IS NULL
                              AND column_DataType IS NULL THEN
                             'Not used'
                         WHEN Property_MFID > 100
                              AND AdditionalProperty = 0 THEN
                             'Metadata Card Property'
                         WHEN AdditionalProperty = 1 THEN
                             'Additional Property'
                         WHEN Property_MFID < 101 THEN
                             'MFSystem Property'
                         WHEN columnName IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                             'MFSystem Property'
                         WHEN columnName IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount', 'Deleted', 'Update_ID' ) THEN
                             'MFSQL System Property'
                         WHEN SUBSTRING(columnName, 1, 2) = 'MX' THEN
                             'Excluded from MF'
                         WHEN Property IS NULL
                              AND IncludedInApp = 1
                              AND ColumnType IS NULL THEN
                             'Lookup Lable Column'
                     END;

    WITH cte
    AS (SELECT REPLACE(columnName, '_ID', '') AS columnname,
            ColumnType,
            Property,
            Property_MFID,
            LookupType,
            MFDataType,
            MFdataType_ID
        FROM ##spMFClassTableColumns
        WHERE MFdataType_ID IN ( 9, 10 )
              AND columnname LIKE '%_ID')
    UPDATE c
    SET c.ColumnType = 'Lookup Lable Column',
        c.LookupType = cte.LookupType,
        c.Property = cte.Property,
        c.Property_MFID = cte.Property_MFID,
        c.MFDataType = cte.MFDataType,
        c.MFdataType_ID = cte.MFdataType_ID
    --SELECT *
    FROM cte
        INNER JOIN ##spMFClassTableColumns c
            ON cte.columnname = c.columnName
    WHERE c.Property_MFID IS NULL;

    UPDATE ##spMFClassTableColumns
    SET MissingColumn = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.IncludedInApp IS NOT NULL
          AND pc.column_DataType IS NULL;

    UPDATE ##spMFClassTableColumns
    SET RedundantTable = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.IncludedInApp IS NULL
          AND pc.column_DataType IS NOT NULL;

    UPDATE ##spMFClassTableColumns
    SET MissingTable = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.IncludedInApp IS NOT NULL
          AND pc.column_DataType IS NULL
          AND pc.MissingColumn IS NULL;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 1 )
          AND pc.length <> 200
          AND pc.IncludedInApp = 1;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 10 )
          AND pc.length <> 8000
          AND pc.IncludedInApp IS NOT NULL;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 13 )
          AND pc.length <> -1
          AND pc.IncludedInApp IS NOT NULL;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    -- SELECT *
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 9 )
          AND pc.column_DataType <> 'int'
          AND pc.IncludedInApp IS NOT NULL
          AND pc.ColumnType <> 'Lookup Lable Column';

    IF @ErrorsOnly = 1
       AND @IsSilent = 0
    BEGIN
        SELECT pc.TableName,
            pc.ColumnName,
            pc.ColumnType,
            pc.ColumnDataTypeError,
            pc.MissingColumn,
            pc.MissingTable,
            pc.RedundantTable,
            pc.Class,
            pc.Property,
            pc.Property_MFID,
            pc.AdditionalProperty,
            pc.IncludedInApp,
            pc.Required,
            pc.PredefinedOrAutomatic,
            pc.LookupType,
            pc.MFdataType_ID,
            pc.MFDataType,
            pc.column_DataType,
            pc.length
        FROM ##spMFClassTableColumns AS pc
        WHERE pc.TableName = @MFTableName
              OR @MFTableName IS NULL
                 AND
                 (
                     pc.ColumnDataTypeError IS NOT NULL
                     OR pc.MissingColumn IS NOT NULL
                     OR pc.MissingTable IS NOT NULL
                     OR pc.RedundantTable IS NOT NULL
                 )
        ORDER BY pc.TableName,
            pc.columnName;
    END;

    IF @ErrorsOnly = 0
       AND @IsSilent = 0
        SELECT pc.TableName,
            pc.ColumnName,
            pc.ColumnType,
            pc.ColumnDataTypeError,
            pc.MissingColumn,
            pc.MissingTable,
            pc.RedundantTable,
            pc.Class,
            pc.Property,
            pc.Property_MFID,
            pc.AdditionalProperty,
            pc.IncludedInApp,
            pc.Required,
            pc.PredefinedOrAutomatic,
            pc.LookupType,
            pc.MFdataType_ID,
            pc.MFDataType,
            pc.column_DataType,
            pc.length

        FROM ##spMFClassTableColumns AS pc
        WHERE pc.TableName = @MFTableName
              OR @MFTableName IS NULL
        ORDER BY pc.TableName,
            pc.columnName;
END;
GO