
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].spMFClassTableColumns';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFClassTableColumns',
    -- nvarchar(100)
    @Object_Release = '4.10.30.74',
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

It will also identify properties that is not used in any class tables, which is handy when trying to remove redundant properties from the vault.

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
2022-09-27  LC         update following change of additional property approach
2021-10-08  LC         Fix missing table not identying if table deleted
2021-09-30  LC         fix bug on multilookup data type change error 
2021-01-31  LC         update to allow for multi language default columns
2020-12-31  LC         rework logic to show column types
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

    DECLARE @IsUpToDate BIT;

    EXEC dbo.spMFGetMetadataStructureVersionID @IsUpToDate = @IsUpToDate OUTPUT; -- bit

    IF @IsUpToDate = 0
    BEGIN
        EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'Property'; -- varchar(100)

        EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'Class'; -- varchar(100)
    END;
   
DECLARE @SpecialColumns AS TABLE (Name NVARCHAR(200), ColType NVARCHAR(100))
INSERT INTO @SpecialColumns
(
    Name,ColType
)
VALUES
( 'ID','MFSQL Column')
,('GUID', 'MF Internal ')
,('MX_User_ID','MFSQL Column')
,('LastModified','MFSQL Column')
,('Process_ID','MFSQL Column')
,('ObjID', 'MF Internal ')
,('ExternalID', 'MF Internal ')
,('MFVersion', 'MF Internal ')
,('FileCount', 'MF Internal ')
,('Update_ID','MFSQL Column')


INSERT INTO @SpecialColumns
(
    Name,ColType
)

SELECT columnname, 'MF Internal' FROM dbo.MFProperty AS mp WHERE mfid < 1000

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
        IsAdditional BIT,
        RetainIfNull BIT,
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
        IsAdditional,
        RetainIfNull,
        IncludedInApp,
        Required,
        PredefinedOrAutomatic,
 --       MFdataType_ID,
        MFDataType,
        MFdataType_ID,
        Column_DataType,
        AdditionalProperty,
        LookupType
    )
    SELECT mfms.Property,
          mfms.Property_MFID,
           mfms.ColumnName,
           mfms.Class,
           mfms.TableName,
           mfms.IsAdditional,
           mfms.RetainIfNull,
           mfms.IncludeInApp,
           mfms.Required,
           mfms.PredefinedOrAutomatic,
           mfms.MFDataType,
           mfms.MFTypeID,
           mfms.SQLDataType,         
           0,
             CASE
                                              WHEN mfms.IsObjectType = 1
                                                   AND mfms.MFTypeID IN ( 9, 10 ) THEN
                                                  'ClassTable_' + mfms.Valuelist
                                              WHEN mfms.IsObjectType = 0
                                                   AND mfms.Property_MFID NOT IN ( 39, 38 )
                                                   AND mfms.MFTypeID IN ( 9, 10 ) THEN
                                                  'Valuelist_' + mfms.Valuelist
                                              WHEN mfms.IsObjectType = 0
                                                   AND mfms.Property_MFID IN ( 39, 38 )
                                                   AND mfms.MFTypeID IN ( 9, 10 ) THEN
                                                  'Workflow_' + mfms.Valuelist
                                          END
--SELECT *
           FROM dbo.MFvwMetadataStructure AS mfms

UPDATE cts
SET cts.ColumnType = CASE WHEN IncludedInApp = 1 THEN  'Metadata Card' ELSE 'Not Used' END
, class = CASE 
WHEN class IS NULL AND sc.NAME IS NOT NULL THEN 'All class tables'
WHEN class IS NULL AND sc.NAME IS null THEN 'No class table' ELSE class END
, tableName = CASE 

WHEN mc.tablename IS NULL AND IncludedInApp IS NULL AND sc.NAME IS NOT NULL THEN 'All Class tables'
WHEN mc.tablename IS NULL AND IncludedInApp IS NULL AND sc.NAME IS null THEN 'Not used in class' ELSE mc.TableName end
--SELECT property, property_mfid, * 
FROM ##spMFClasstablecolumns cts
left JOIN dbo.MFProperty AS mp
ON mp.mfid = cts.property_mfid
left JOIN mfclass mc
ON cts.tablename= mc.tablename
left JOIN dbo.MFClassProperty AS mcp
ON mp.id = mcp.MFProperty_ID AND mcp.MFClass_ID = mc.id
LEFT JOIN @SpecialColumns sc
ON mp.ColumnName = sc.NAME


UPDATE cts
SET cts.Length = c.CHARACTER_MAXIMUM_LENGTH
--SELECT * 
FROM ##spMFClassTableColumns cts
INNER JOIN INFORMATION_SCHEMA.Columns AS c
ON cts.ColumnName = c.COLUMN_NAME AND cts.TableName = c.TABLE_NAME

;
WITH cte AS
(
SELECT ColumnType = NULL,
    class = mc.Name,
    mc.TableName,
    Property = mp.Name,
    Property_MFID = mp.MFID,
    ColumnName = c.COLUMN_NAME,
    AdditionalProperty =1,
      cts.IsAdditional,
    cts.RetainIfNull,
    IncludedInApp=1,
    Required = NULL,
    PredefinedOrAutomatic = NULL,
    LookupType = NULL,
    MFdataType_ID = mdt.MFTypeID,
    MFDataType= mdt.Name,
    Column_DataType= c.DATA_TYPE,
    Length = c.CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS       AS c
    INNER JOIN dbo.MFClass            mc
        ON c.TABLE_NAME = mc.TableName
    LEFT JOIN dbo.MFProperty          mp
        ON c.COLUMN_NAME = mp.ColumnName
    LEFT JOIN dbo.MFDataType          AS mdt
        ON mp.MFDataType_ID = mdt.ID
    LEFT JOIN ##spMFClassTableColumns cts
        ON cts.ColumnName = c.COLUMN_NAME
           AND cts.TableName = c.TABLE_NAME
WHERE cts.id IS NULL
)
INSERT INTO ##spMFClassTableColumns
(
    ColumnType,
    Class,
    TableName,
    Property,
    Property_MFID,
    ColumnName,
    AdditionalProperty,
    IsAdditional,
    RetainIfNull,
    IncludedInApp,
    Required,
    PredefinedOrAutomatic,
    LookupType,
    MFdataType_ID,
    MFDataType,
    Column_DataType,
    Length

)
SELECT cte.ColumnType,
       cte.class,
       cte.TableName,
       cte.Property,
       cte.Property_MFID,
       cte.ColumnName,
       cte.AdditionalProperty,
         cte.IsAdditional,
    cte.RetainIfNull,
       cte.IncludedInApp,
       cte.Required,
       cte.PredefinedOrAutomatic,
       cte.LookupType,
       cte.MFdataType_ID,
       cte.MFDataType,
       cte.Column_DataType,
       cte.Length FROM cte;

           ;
    WITH cte AS
    (
    SELECT DISTINCT cts.Property_MFID, Property, ColumnType,Columnname, LookupType, PredefinedOrAutomatic FROM ##spMFClasstablecolumns cts 
    
    WHERE mfdatatype_ID IN( 9,10)

    )
    UPDATE cts
    SET ColumnType = 'Lookup Label'
    ,cts.Property = cte.Property
    ,cts.Property_MFID = cte.Property_MFID
    ,cts.LookupType = cte.LookupType
    ,cts.Required = 0
    ,cts.PredefinedOrAutomatic = cte.PredefinedOrAutomatic
 --   SELECT cts.*   
    FROM ##spMFClasstablecolumns cts 
    INNER JOIN cte
    ON cts.columnname = SUBSTRING(cte.ColumnName,1,LEN(cte.ColumnName)-3) 
    WHERE cts.property_MFID IS NULL

    UPDATE cts
    SET ColumnType = mc.ColType
    FROM ##spMFClasstablecolumns cts
    INNER JOIN @SpecialColumns  mc
    ON cts.ColumnName = mc.name

    --catch all
  UPDATE cts
   SET ColumnType = 'Additional Property', cts.AdditionalProperty = 1
  FROM ##spMFClasstablecolumns cts 
  WHERE ColumnType IS NULL AND Property_MFID IS NOT null

    UPDATE ##spMFClassTableColumns
    SET MissingColumn = 1
    FROM ##spMFClassTableColumns AS pc
    LEFT JOIN INFORMATION_SCHEMA.Columns AS t
    ON pc.ColumnName = t.COLUMN_NAME AND pc.TableName = t.TABLE_NAME
    WHERE pc.IncludedInApp IS NOT NULL
      AND t.COLUMN_NAME IS null
          AND pc.MissingColumn IS NULL;

    UPDATE ##spMFClassTableColumns
    SET RedundantTable = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.IncludedInApp IS NULL
          AND pc.columnType NOT IN ( 'Not used', 'MF Internal');

    UPDATE ##spMFClassTableColumns
    SET MissingTable = 1
    FROM ##spMFClassTableColumns AS pc
    LEFT JOIN INFORMATION_SCHEMA.TABLES AS t
    ON pc.TableName = t.TABLE_NAME
    WHERE pc.IncludedInApp IS NOT NULL
      AND t.TABLE_NAME IS null
          AND pc.MissingTable IS NULL;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 1 )
          AND pc.[length] <> 100
          AND pc.IncludedInApp = 1;

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 10 )
          AND pc.[length] <> 4000
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
          AND pc.column_DataType NOT IN( 'int','INTEGER')
          AND pc.IncludedInApp IS NOT NULL
     --     AND pc.ColumnType <> 'Lookup Lable Column';

    UPDATE ##spMFClassTableColumns
    SET ColumnDataTypeError = 1
    -- SELECT *
    FROM ##spMFClassTableColumns AS pc
    WHERE pc.MFdataType_ID IN ( 10 )
          AND pc.[length] IS null
          AND pc.IncludedInApp IS NOT NULL

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
        WHERE
     --pc.TableName = @MFTableName
         --     OR @MFTableName IS NULL
                 --AND
                 --(
                     pc.ColumnDataTypeError IS NOT NULL
                     OR pc.MissingColumn IS NOT NULL
                     OR pc.MissingTable IS NOT NULL
                     OR pc.RedundantTable IS NOT NULL
                 --)
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
            pc.IsAdditional,
            pc.RetainIfNull,
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