
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableInternal]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTableInternal', -- nvarchar(100)
    @Object_Release = '4.9.27.68',            -- varchar(250)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateTableInternal' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateTableInternal
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateTableInternal
(
    @TableName NVARCHAR(128),
    @Xml NVARCHAR(MAX),
    @Update_ID INT,
    @Debug SMALLINT,
    @SyncErrorFlag BIT = 0
)
AS
/*rST**************************************************************************

=======================
spMFUpdateTableInternal
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName nvarchar(128)
    passed through by internal operation
  @Xml nvarchar(max)
    passed through by internal operation
  @Update\_ID int
    passed through by internal operation
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode
  @SyncErrorFlag bit
    - optional
    - set by internal operations


Purpose
=======

The purpose of this procedure is to update SQL class table with the result from M-Files

Additional Info
===============

This procedure is used internally only

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-04-14  LC         Fix timestamp datatype bug
2021-03-02  LC         Remove check for required workflows, check is included in spMFClassTableStats
2020-11-07  LC         Resolve issue with duplicate columns and multilookup datatype
2020-10-22  LC         set datetime conversion to 102 (ansi)
2020-10-22  LC         Required workflow check is only performed on updated objects
2020-09-23  LC         Remove rows from other classes for table update
2020-09-04  LC         split merge into parts per advice
2020-09-04  LC         move updating of audit history to smpfupdatetable
2020-08-26  LC         revise error checking for required workflows
2020-08-18  LC         replace column deleted flag with property 27 (deleted) datetime
2020-07-27  LC         Update to handle new status for deleted and checked out     
2020-06-20  LC         Fix bug with localisation error on workflow
2020-02-20  LC         Change assembly to system.culture time
2019-11-18  LC         Update time format to address localisation
2019-08-30  JC         Added documentation
2019-04-01  LC         Add process_id = 0 as condition
2018-12-17  LC         formatting of boolean property
2018-12-16  LC         prevent record from wrong class in class table
2018-10-02  LC         Fix localization bug on  missing quotename
2018-08-23  LC         Resolve sync error bug
2018-08-01  LC         Resolve deletions for filter objid
2018-07-03  LC         locatlisation for finish datetime
2018-06-22  LC         Localisation of workflow_id, name_or_Title property name
2017-11-29  LC         Fix Is Templatelist temp file to allow for multiple threads
2017-08-22  LC         Add synch error auto correction
2017-07-06  LC         Add updating of Filecount
17-04-2015  DEV 2      DATETIME column value convertion is changed
16-05-2015  DEV 2      Record Update/Insert logic is modified 
16-05-2015  DEV 2      (new logic : one record insert/update at a time and 
16-05-2015  DEV 2      skip the records which fails to insert/update)
25-05-2015  DEV 2      New input parameter added (@Update_ID)
25-05-2015  DEV 2      Adding @Update_ID & ExtrenalID into MFLog table
30-06-2015  DEV 2      Changed the return value to 4 if any record failed insert/Update
08-07-2015  DEV 2      Template object issue resolved
08-07-2015  DEV 2      BIT Column value resolved
22-2-2016   LC         Update Error logging, remove Is_template
10-8-2016   LC         update objid filter to fix bug
17-8-2016   LC         conversion of float columns for comma as decimal character
19-8-2016   LC         update to take account of class table name in foreign languages 
26-8-2016   LC         change usage of temptables to global variables and convert to multi user
10-11-2016  LC         fix bug for records with Null values in required fields
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    BEGIN TRY
        -----------------------------------------------------
        --DECLARE LOCAL VARIABLETempIsTemplatelist
        -----------------------------------------------------
        DECLARE @Idoc            INT,
            @ProcedureStep       sysname         = 'Start',
            @ProcedureName       sysname         = 'spMFUpdateTableInternal',
            @UpdateColumns       NVARCHAR(MAX),
            @UpdateQuery         AS NVARCHAR(MAX),
            @InsertQuery         AS NVARCHAR(MAX),
            @ColumnNames         NVARCHAR(MAX),
            @AlterQuery          NVARCHAR(MAX),
            @Columns             AS NVARCHAR(MAX),
            @Query               AS NVARCHAR(MAX),
            @Params              AS NVARCHAR(MAX),
            @ColumnForInsert     NVARCHAR(MAX),
            @TempInsertQuery     NVARCHAR(MAX),
            @TempUpdateQuery     NVARCHAR(MAX),
            @CustomErrorMessage  NVARCHAR(MAX),
            @ReturnVariable      INT             = 1,
            @ExternalID          NVARCHAR(100),
            @TempObjectList      VARCHAR(100),
            @TempExistingObjects VARCHAR(100),
            @TempNewObjects      VARCHAR(100),
            @TempIsTemplatelist  VARCHAR(100),
            @Name_or_Title       NVARCHAR(100),
            @class_ID int;

        SET @ProcedureStep = 'Drop temptables if exist';

        SELECT @TempObjectList = dbo.fnMFVariableTableName('##ObjectList', DEFAULT);

        SELECT @TempExistingObjects = dbo.fnMFVariableTableName('##ExistingObjects', DEFAULT);

        SELECT @TempNewObjects = dbo.fnMFVariableTableName('##TempNewObjects', DEFAULT);

        SELECT @TempIsTemplatelist = dbo.fnMFVariableTableName('##IsTemplateList', DEFAULT);

        SELECT @Name_or_Title = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 0;

        SELECT @class_ID = MFID FROM MFClass WHERE TableName = @TableName

          -------------------------------------------------------------
            -- deleted column
         -------------------------------------------------------------

    DECLARE @DeletedColumn NVARCHAR(100);

    SELECT @DeletedColumn = mp.ColumnName
    FROM dbo.MFProperty AS mp
    WHERE mp.MFID = 27;

         IF (SELECT object_id('tempdb..#properties')) IS NOT null
        BEGIN
            DROP TABLE #Properties;
        END;

        --Parse the Input XML
        EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @Xml;

        --------------------------------------------------------------------------------
        --Create Temp Table to Store the Data From XML
        --------------------------------------------------------------------------------
        CREATE TABLE #Properties
        (
            objId INT,
            MFVersion INT,
            Class_ID INT,
            GUID NVARCHAR(100),
            ExternalID NVARCHAR(100),
            FileCount INT, --Added for task 106
            propertyId INT NULL,
            propertyValue NVARCHAR(MAX) NULL,
            propertyName NVARCHAR(100) NULL,
            dataType NVARCHAR(100) NULL
        );

        SELECT @ProcedureStep = 'Inserting Values into #Properties from XML';

        IF @Debug > 9
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        ----------------------------------------
        --Insert XML data into Temp Table
        ----------------------------------------
        INSERT INTO #Properties
        (
            objId,
            MFVersion,
            GUID,
            ExternalID,
            FileCount, --Added for task 106
            propertyId,
            propertyValue,
            dataType
        )
        SELECT objId,
            MFVersion,
            GUID,
            ExternalID,
            FileCount, --Added for task 106
            propertyId,
            propertyValue,
            dataType
        FROM
            OPENXML(@Idoc, '/form/Object/properties', 1)
            WITH
            (
                objId INT '../@objectId',
                MFVersion INT '../@objVersion',
                GUID NVARCHAR(100) '../@objectGUID',
                ExternalID NVARCHAR(100) '../@DisplayID',
                FileCount INT '../@FileCount', --Added for task 106
                propertyId INT '@propertyId',
                propertyValue NVARCHAR(MAX) '@propertyValue',
                dataType NVARCHAR(1000) '@dataType',
                Status INT '../@Status'
            );

        --         WHERE [Status] = 1;
        IF @Idoc IS NOT NULL
            EXEC sys.sp_xml_removedocument @Idoc;

    -------------------------------------------------------------
    -- Elliminate items not in class
    -------------------------------------------------------------        
            update #Properties 
            SET class_id = p3.propertyValue
            FROM #Properties AS p
            INNER JOIN (SELECT p2.objId, p2.propertyValue from #Properties p2
            WHERE p2.propertyId = 100 AND dataType IS null
            GROUP BY p2.objId, p2.propertyValue) p3
            ON p3.objid = p.objid

            DELETE FROM #Properties WHERE class_id <> @class_ID

        SELECT @ProcedureStep = 'Updating Table column Name';

        IF @Debug > 9
        BEGIN
            SELECT 'List of properties from MF' AS Properties,
                *
            FROM #Properties;

            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF
        (
            SELECT COUNT(*) FROM #Properties AS p
        ) > 0
        BEGIN

            -------------------------------------------------------------
            -- localisation of date time for finish time
            -------------------------------------------------------------
            UPDATE p
            SET p.propertyValue = REPLACE(p.propertyValue, '.', ':')
            FROM #Properties AS p
            WHERE p.dataType IN ( 'MFDataTypeTimestamp', 'MFDataTypeDate', 'MFDatatypeTime' );

            ----------------------------------------------------------------
            --Update property name with column name from MFProperty Tbale
            ----------------------------------------------------------------
            UPDATE #Properties
            SET propertyName =
                (
                    SELECT ColumnName FROM dbo.MFProperty WHERE MFID = #Properties.propertyId
                );

            -------------------------------------------------------------------------------------------------
            --Update column name if the property datatype is MFDatatypeLookup or MFDatatypeMultiSelectLookup
            -------------------------------------------------------------------------------------------------
            UPDATE #Properties
            SET propertyName = CASE
                                   WHEN SUBSTRING(propertyName, LEN(propertyName) - 2, 3) = '_ID' THEN
                                       SUBSTRING(propertyName, 1, LEN(propertyName) - 3)
                                   ELSE
                                       SUBSTRING(propertyName, 1, LEN(propertyName) - 5)
                                       + REPLACE((SUBSTRING(propertyName, (LEN(propertyName) - 4), 5)), '_ID', '')
                               END
            WHERE dataType = 'MFDatatypeLookup'
                  OR dataType = 'MFDatatypeMultiSelectLookup';

            SELECT @ProcedureStep = 'Adding workflow column if not exists';

            IF @Debug > 9
            BEGIN
                SELECT 'updated columntypes',
                    *
                FROM #Properties;

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @ProcedureStep = 'Adding columns from MFTable which are not exists in #Properties';

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------
            --Select the existing columns from MFTable
            -------------------------------------------------
            INSERT INTO #Properties
            (
                propertyName
            )
            SELECT *
            FROM
            (
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = @TableName
                      AND COLUMN_NAME NOT LIKE 'ID'
                      AND COLUMN_NAME NOT LIKE 'LastModified'
                      AND COLUMN_NAME NOT LIKE 'Process_ID'
                      --        AND COLUMN_NAME NOT LIKE 'Deleted'
                      AND COLUMN_NAME NOT LIKE 'ObjID'
                      AND COLUMN_NAME NOT LIKE 'MFVersion'
                      AND COLUMN_NAME NOT LIKE 'MX_'
                      AND COLUMN_NAME NOT LIKE 'GUID'
                      AND COLUMN_NAME NOT LIKE 'ExternalID'
                      AND COLUMN_NAME NOT LIKE 'FileCount' --Added For Task 106
                      AND COLUMN_NAME NOT LIKE 'Update_ID'
                EXCEPT
                SELECT DISTINCT
                    (propertyName)
                FROM #Properties
            ) m;

            SELECT @ProcedureStep = 'PIVOT properties';

            IF @Debug > 9
            BEGIN
                SELECT '#Properties with new columns',
                    *
                FROM #Properties AS p;

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            --------------------------------------------------------------------------------
            --Selecting The Distinct PropertyName to Create The Columns
            --------------------------------------------------------------------------------
            SELECT @Columns = STUFF(
            (
                SELECT ',' + QUOTENAME(ppt.propertyName)
                FROM #Properties ppt
                GROUP BY ppt.propertyName
                ORDER BY ppt.propertyName
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'),
                                       1,
                                       1,
                                       ''
                                   );

            SELECT @ColumnNames = N'';

            SELECT @ProcedureStep = 'Select All column names from MFTable';

            IF @Debug > 9
            BEGIN
                SELECT @Columns AS 'Distinct Properties';

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            --------------------------------------------------------------------------------
            --Select Column Name Except 'ID','LastModified','Process_ID'
            --------------------------------------------------------------------------------
            SELECT @ColumnNames = @ColumnNames + QUOTENAME(COLUMN_NAME) + N','
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @TableName
                  AND COLUMN_NAME NOT LIKE 'ID'
                  AND COLUMN_NAME NOT LIKE 'LastModified'
                  AND COLUMN_NAME NOT LIKE 'Process_ID'
                  --        AND COLUMN_NAME NOT LIKE 'Deleted'
                  AND COLUMN_NAME NOT LIKE 'MX_%'
                  AND COLUMN_NAME NOT LIKE 'Update_ID';

            SELECT @ColumnNames = SUBSTRING(@ColumnNames, 0, LEN(@ColumnNames));

            SELECT @ProcedureStep = 'Inserting PIVOT Data into  @TempObjectList';

            ------------------------------------------------------------------------------------------------------------------------
            --Dynamic Query to Converting row into columns and inserting into [dbo].[tempobjectlist] USING PIVOT
            ------------------------------------------------------------------------------------------------------------------------
            SELECT @Query
                = N'SELECT *
						INTO ' + @TempObjectList
                  + N'
						FROM (
							SELECT objId
								,MFVersion
								,GUID
								,ExternalID
								,FileCount     --Added for task 106
								,' + @Columns
                  + N'
							FROM (
								SELECT objId
									,MFVersion
									,GUID
									,ExternalID
									,FileCount --Added for task 106
									,propertyName new_col
									,value
								FROM #Properties
								UNPIVOT(value FOR col IN (propertyValue)) un
								) src
							PIVOT(MAX(value) FOR new_col IN (' + @Columns + N')) p
							) PVT';

            EXECUTE sys.sp_executesql @Query;

            IF @Debug > 9
            BEGIN
                EXEC ('SELECT * from ' + @TempObjectList);

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            ----------------------------------------
            --Delete objects with Is Template = yes	; Update MFAuditHistory objid with SatusFlag = 6
            ----------------------------------------
            SELECT @ProcedureStep = 'Delete Template objects from objectlist ';

            IF
            (
                SELECT COUNT(o.name)
                FROM tempdb.sys.objects AS o
                WHERE o.name = @TempIsTemplatelist
            ) > 0
                EXEC (' DROP TABLE ' + @TempIsTemplatelist);

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            DECLARE @CLassID INT;

            SELECT @CLassID = MFID
            FROM dbo.MFClass
            WHERE TableName = @TableName;

            EXEC ('CREATE TABLE ' + @TempIsTemplatelist + ' ( Objid INT ) ');

            SET @Params = N'@Count int output';
            SET @Query
                = N'SELECT @Count = count(*)
		FROM  tempdb.sys.columns where object_ID = object_id(''tempdb..' + @TempObjectList
                  + N''')
		and Name = ''Is_Template''

If @Count > 0
begin
Insert into ' + @TempIsTemplatelist + N'
Select Objid
from ' +    @TempObjectList + N'
End		
		'   ;

            --   PRINT @Query;
            EXEC sys.sp_executesql @stmt = @Query,
                @param = @Params,
                @Count = @ReturnVariable OUTPUT;

            IF @ReturnVariable > 0
            BEGIN
                SET @Params = N'@ClassID int';
                SET @Query
                    = N'
                    UPDATE  mah
                    SET     [mah].[StatusFlag] = 6 ,
                            mah.[StatusName] = ''Template''
                    FROM    [dbo].[MFAuditHistory] AS [mah]
                            INNER JOIN ' + @TempIsTemplatelist
                      + N' temp ON [mah].[Class] =  @CLassID 
                                                              AND mah.[ObjID] = temp.[Objid];';

                EXEC sys.sp_executesql @stmt = @Query,
                    @param = @Params,
                    @ClassID = @CLassID;

                SET @Query = N' DELETE FROM ' + @TempObjectList + N' WHERE isnull(Is_Template,0) = 1';

                EXEC sys.sp_executesql @stmt = @Query;
            END;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s Delete Template', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------
            --Add additional columns to Class Table
            -------------------------------------------------
            SELECT @ProcedureStep = 'Add Additional columns to class table ';

            CREATE TABLE #Columns
            (
                propertyName NVARCHAR(100) NULL,
                dataType NVARCHAR(100) NULL
            );

            SET @Query
                = N'
INSERT INTO #Columns (PropertyName) SELECT * FROM (
SELECT Name AS PropertyName FROM tempdb.sys.columns 
			WHERE object_id = Object_id(''tempdb..' + @TempObjectList
                  + N''')
		EXCEPT
			SELECT COLUMN_NAME AS name
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = ''' + @TableName + N''') v';

            EXEC sys.sp_executesql @Query;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------
            --Updating property datatype
            -------------------------------------------------

             		declare @Columnname nvarchar(max)

		if (Select count(*)
		
				from #Columns
				inner join MFProperty mp
				on mp.ColumnName = #Columns.propertyName
				inner join MFDataType dt
				on dt.id = mp.MFDataType_ID
				where #Columns.propertyName = mp.ColumnName
				group by ColumnName
				having count(*) > 1
				)> 0
				
		              RAISERROR('Proc: %s Step: %s Duplicate columns, adhoc column conflict', 16, 1, @ProcedureName, @ProcedureStep);
  

				update #Columns
				set dataType = v.SQLdataType 

--Select v.columnName, v.SQLDataType 
from(
		Select mp.columnName, SQLDataType
		
				from #Columns c
				inner join MFProperty mp
				on mp.ColumnName = c.propertyName
				inner join MFDataType dt
				on dt.id = mp.MFDataType_ID
				where c.propertyName = mp.ColumnName
				union all
Select  substring(PropertyName,1,(len(mp.columnName)-3)) as Columnname
,SQLdataType = case when mfTypeID = 9 then 'NVARCHAR(100)' ELSE 'NVARCHAR(4000)' END
	
				from #Columns c
				inner join MFProperty mp
				on mp.ColumnName = c.propertyName
				inner join MFDataType dt
				on dt.id = mp.MFDataType_ID
				where c.propertyName = mp.ColumnName
				and dt.MFTypeID in (9,10)
		) v
		inner join #Columns
		on #Columns.propertyName = v.ColumnName
		where #Columns.propertyName = v.ColumnName


  /*          UPDATE #Columns
            SET dataType =
                (
                    SELECT SQLDataType
                    FROM dbo.MFDataType
                    WHERE ID IN
                          (
                              SELECT MFDataType_ID
                              FROM dbo.MFProperty
                              WHERE ColumnName = #Columns.propertyName
                          )
                );

            -------------------------------------------------------------------------
            ----Set dataype = NVARCHAR(100) for lookup and multiselect lookup values
            -------------------------------------------------------------------------
            UPDATE #Columns
            SET dataType = ISNULL(dataType, 'NVARCHAR(100)');
*/
            SELECT @AlterQuery = N'';

            ---------------------------------------------
            --Add new columns into MFTable
            ---------------------------------------------
            SELECT @AlterQuery
                = @AlterQuery + N'ALTER TABLE [' + @TableName + N'] Add [' + propertyName + N'] ' + dataType + N'  '
            FROM #Columns;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            EXEC sys.sp_executesql @AlterQuery;

            --------------------------------------------------------------------------------
            --Select Column Name Except 'ID','LastModified','Process_ID'
            --------------------------------------------------------------------------------
            SELECT @ProcedureStep = 'Prepare Column names for insert from class table';

            SELECT @ColumnNames = N'';

            SELECT @ColumnNames = @ColumnNames + QUOTENAME(COLUMN_NAME) + N','
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @TableName
                  AND COLUMN_NAME NOT LIKE 'ID'
                  AND COLUMN_NAME NOT LIKE 'LastModified'
                  AND COLUMN_NAME NOT LIKE 'Process_ID'
                  --    AND COLUMN_NAME NOT LIKE 'Deleted'
                  AND COLUMN_NAME NOT LIKE 'MX_%'
                  AND COLUMN_NAME NOT LIKE 'Update_ID';

            SELECT @ColumnNames = SUBSTRING(@ColumnNames, 0, LEN(@ColumnNames));

            IF @Debug > 9
            BEGIN
                --       SELECT  @ColumnNames AS 'Column Names';
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            --------------------------------------------------------------------------------
            --Get datatype of column for Insertion
            --------------------------------------------------------------------------------
            SELECT @ColumnForInsert = N'';

            SELECT @ProcedureStep = 'Get datatype of column';

            SELECT @ColumnForInsert
                = @ColumnForInsert
                  + CASE
                        WHEN DATA_TYPE = 'DATE' THEN
                            ' CONVERT(DATETIME, NULLIF(' + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),102) AS '
                            + QUOTENAME(COLUMN_NAME) + ','
                        WHEN DATA_TYPE = 'TIME' THEN
                            ' CONVERT(TIME(0), NULLIF(' + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),0) AS '
                            + QUOTENAME(COLUMN_NAME) + ','
                        WHEN DATA_TYPE = 'DATETIME' THEN
                            ' DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()),CONVERT(DATETIME, NULLIF('
                            + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),102 )) AS ' + QUOTENAME(COLUMN_NAME)
                            + ','
                        WHEN DATA_TYPE = 'BIT' THEN
                            'CASE WHEN ' + QUOTENAME(COLUMN_NAME) + ' = ''1'' THEN  CAST(''1'' AS BIT) WHEN '
                            + QUOTENAME(COLUMN_NAME) + ' = ''0'' THEN CAST(''0'' AS BIT)  ELSE 
						null END AS '                            + QUOTENAME(COLUMN_NAME) + ','
                        --      + QUOTENAME([COLUMN_NAME]) + ' END AS ' + QUOTENAME([COLUMN_NAME]) + ','
                        WHEN DATA_TYPE = 'NVARCHAR' THEN
                            ' CAST(NULLIF(' + QUOTENAME(COLUMN_NAME) + ','''') AS ' + DATA_TYPE + '('
                            + CASE
                                  WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN
                                      'MAX)) AS ' + QUOTENAME(COLUMN_NAME) + ','
                                  ELSE
                                      CAST(NULLIF(CHARACTER_MAXIMUM_LENGTH, '') AS NVARCHAR) + ')) AS '
                                      + QUOTENAME(COLUMN_NAME) + ','
                              END
                        WHEN DATA_TYPE = 'FLOAT' THEN
                            ' CAST(NULLIF(REPLACE(' + QUOTENAME(COLUMN_NAME) + ','','',''.''),'''') AS float) AS '
                            + QUOTENAME(COLUMN_NAME) + ','
                        ELSE
                            ' CAST(NULLIF(' + QUOTENAME(COLUMN_NAME) + ','''') AS ' + DATA_TYPE + ') AS '
                            + QUOTENAME(COLUMN_NAME) + ','
                    END
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @TableName
                  AND COLUMN_NAME NOT LIKE 'ID'
                  AND COLUMN_NAME NOT LIKE 'LastModified'
                  AND COLUMN_NAME NOT LIKE 'Process_ID'
                  --        AND COLUMN_NAME NOT LIKE 'Deleted'
                  AND COLUMN_NAME NOT LIKE 'MX_%'
                  AND COLUMN_NAME NOT LIKE 'Update_ID';

            ----------------------------------------
            --Remove the Last ','
            ----------------------------------------
            SELECT @ColumnForInsert = SUBSTRING(@ColumnForInsert, 0, LEN(@ColumnForInsert));

            IF @Debug > 9
            BEGIN
                SELECT @ColumnForInsert AS '@ColumnForInsert';

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @UpdateColumns = N'';

            ----------------------------------------
            --Add column values to data type
            ----------------------------------------
            SELECT @UpdateColumns
                = @UpdateColumns
                  + CASE
                        WHEN DATA_TYPE = 'DATE' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME)
                            + ' = CONVERT(DATETIME, NULLIF(t.' + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':')
                            + ',''''),102 ) ,'
                        WHEN DATA_TYPE = 'TIME' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME) + ' = CONVERT(TIME(0), NULLIF(t.'
                            + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),0)  ,'
                        WHEN DATA_TYPE = 'DATETIME' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME)
                            --+ ' = DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()), CONVERT(DATETIME,NULLIF(t.'
                            --+ REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),102 ))
                           + '=  CONVERT(DATETIME,NULLIF(t.'
                            + REPLACE(QUOTENAME(COLUMN_NAME), '.', ':') + ',''''),102 )
                            ,'
                        WHEN DATA_TYPE = 'BIT' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME) + ' =(CASE WHEN ' + 't.'
                            + QUOTENAME(COLUMN_NAME) + ' = ''1'' THEN  CAST(''1'' AS BIT)  WHEN t.'
                            + QUOTENAME(COLUMN_NAME) + ' = ''0'' THEN CAST(''0'' AS BIT)  
						ELSE NULL END ),'
                        --WHEN t.'
                        --                  + QUOTENAME([COLUMN_NAME]) + ' = ''""'' THEN CAST(''NULL'' AS BIT)  END )  ,'
                        WHEN DATA_TYPE = 'NVARCHAR' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME) + '=  CAST(NULLIF(t.'
                            + QUOTENAME(COLUMN_NAME) + ','''') AS ' + DATA_TYPE + '('
                            + CASE
                                  WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN
                                      CAST('MAX' AS NVARCHAR)
                                  ELSE
                                      CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR)
                              END + ')) ,'
                        WHEN DATA_TYPE = 'Float' THEN
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME) + '=  CAST(NULLIF(REPLACE(t.'
                            + QUOTENAME(COLUMN_NAME) + ','','',''.'')' + ','''') AS ' + DATA_TYPE + ') ,'
                        ELSE
                            '' + QUOTENAME(@TableName) + '.' + QUOTENAME(COLUMN_NAME) + '=  CAST(NULLIF(t.'
                            + QUOTENAME(COLUMN_NAME) + ','''') AS ' + DATA_TYPE + ') ,'
                    END
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @TableName
                  AND COLUMN_NAME NOT LIKE 'ID'
                  AND COLUMN_NAME NOT LIKE 'LastModified'
                  AND COLUMN_NAME NOT LIKE 'Process_ID'
                  --       AND COLUMN_NAME NOT LIKE 'Deleted'
                  AND COLUMN_NAME NOT LIKE 'MX_%'
                  AND COLUMN_NAME NOT LIKE 'Update_ID';

            ----------------------------------------
            --Remove the last ','
            ----------------------------------------
            SELECT @UpdateColumns = SUBSTRING(@UpdateColumns, 0, LEN(@UpdateColumns));

            SELECT @ProcedureStep = 'Create object columns';

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 10
                BEGIN
                    SELECT @UpdateColumns AS '@UpdateColumns';

                    SET @Query = N'	
					SELECT ''tempobjectlist'' as [TempObjectList],* FROM ' + @TempObjectList + N'';

                    EXEC (@Query);
                END;
            END;

            ----------------------------------------
            --prepare temp table for existing object
            ----------------------------------------
            SELECT @TempUpdateQuery
                = N'SELECT *
							   INTO ' + @TempExistingObjects + N'
							   FROM ' + @TempObjectList + N'
							   WHERE ' + @TempObjectList
                  + N'.[ObjID]  IN (
									   SELECT [ObjiD]
									   FROM [' + @TableName + N']
									   )';

            EXECUTE sys.sp_executesql @TempUpdateQuery;

            SELECT @ProcedureStep = 'Update existing objects';

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 9
                BEGIN
                    SET @Query = N'	
					SELECT ''tempExistingobjects'' as [tempExistingobjects],* FROM ' + @TempExistingObjects + N'';

                    EXEC (@Query);
                END;
            END;

            --------------------------------------------------------------------------------------------
            --Update existing records in Class Table and log the details of records which failed to update
            --------------------------------------------------------------------------------------------
            SELECT @ProcedureStep = 'Determine count of records to Update';

            SET @Params = N'@Count int output';
            SET @Query = N'SELECT @count = count(*)
		FROM  ' + @TempExistingObjects + N'';

            EXEC sys.sp_executesql @stmt = @Query,
                @param = @Params,
                @Count = @ReturnVariable OUTPUT;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s : %i', 10, 1, @ProcedureName, @ProcedureStep, @ReturnVariable);
            END;

            DECLARE @TableID INT;

            IF @ReturnVariable > 0
            BEGIN
                IF @Debug > 10
                BEGIN
                    SET @Query
                        = N'	
				SELECT  * FROM ' + QUOTENAME(@TableName) + N' ClassT INNER JOIN ' + @TempExistingObjects
                          + N' T  on ClassT.objid = T.Objid';

                    EXECUTE sys.sp_executesql @Query;
                END;

                --			SELECT @UpdateColumns = REPLACE(@UpdateColumns, '+@TempObjectList+', 't')
                IF @Debug > 10
                    SELECT @UpdateColumns;

                IF @SyncErrorFlag = 1
                BEGIN
                    SELECT @UpdateQuery
                        = N'
								UPDATE [' + @TableName + N']
									SET ' + @UpdateColumns + N',LastModified = GETDATE(),Update_ID = '
                          + CAST(@Update_ID AS NVARCHAR(100)) + N', Process_ID=0           
									FROM [' + @TableName + N'] INNER JOIN ' + @TempExistingObjects
                          + N' as t
									ON [' + @TableName
                          + N'].ObjID = 
                                t.[ObjID]  AND [' + @TableName + N'].Process_ID = 2';
                END;
                ELSE
                BEGIN
                    SELECT @UpdateQuery
                        = N'
								UPDATE [' + @TableName + N']
									SET ' + @UpdateColumns + N',LastModified = GETDATE(),Update_ID = '
                          + CAST(@Update_ID AS NVARCHAR(100)) + N'
									FROM [' + @TableName + N'] INNER JOIN ' + @TempExistingObjects
                          + N' as t
									ON [' + @TableName
                          + N'].ObjID = 
                                t.[ObjID]  AND [' + @TableName + N'].Process_ID = 0';
                END;

                ----------------------------------------
                --Executing Dynamic Query
                ----------------------------------------
                SELECT @ProcedureStep = 'Execute dynamic query';

                IF @Debug > 10
                BEGIN
                    SELECT @UpdateQuery AS '@UpdateQuery';
                END;

                EXEC sys.sp_executesql @stmt = @UpdateQuery;
            END;

            -------------------------------------------------------------
            -- Get class of table
            -------------------------------------------------------------       
            DECLARE @ClassColumnName NVARCHAR(100);

            SELECT @ClassColumnName = @TempObjectList + N'.' + ColumnName
            FROM dbo.MFProperty
            WHERE MFID = 100;

            --------------------------------------------------------------------------------
            --Dynamic Query to INSERT new Records into MFTable
            --------------------------------------------------------------------------------
            SELECT @ProcedureStep = 'Setup insert new objects Query';

            SELECT @TempInsertQuery
                = N'Select ' + @TempObjectList + N'.* INTO ' + @TempNewObjects + N'
			from '                    + @TempObjectList + N' left Join ' + QUOTENAME(@TableName) + N'
			ON '                      + QUOTENAME(@TableName) + N'.[ObjID] = ' + @TempObjectList + N'.[objid] WHERE '
                  + QUOTENAME(@TableName) + N'.objid IS null and ' + @ClassColumnName + N' = '
                  + CAST(@Class_ID AS NVARCHAR(100));

            IF @Debug > 9
            BEGIN
                SELECT @TempInsertQuery AS '@TempInsertQuery';

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            EXECUTE sys.sp_executesql @TempInsertQuery;

            SELECT @ProcedureStep = 'Determine count of records to insert';

            SET @Params = N'@Count int output';
            SET @Query = N'

SELECT @count = count(*)
		FROM  ' + @TempNewObjects + N'';

            --           PRINT @Query;
            EXEC sys.sp_executesql @stmt = @Query,
                @param = @Params,
                @Count = @ReturnVariable OUTPUT;

            IF @ReturnVariable > 0
                SELECT @ProcedureStep = 'Insert new Records';

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s : %i', 10, 1, @ProcedureName, @ProcedureStep, @ReturnVariable);
            END;

            BEGIN
                SELECT @ProcedureStep = 'Verify that all required fields have values';

                IF @Debug > 9
                BEGIN
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @ReturnVariable = COUNT(*)
                FROM INFORMATION_SCHEMA.COLUMNS AS c
                    LEFT JOIN #Properties       AS p
                        ON p.propertyName = REPLACE(c.COLUMN_NAME, '_ID', '')
                WHERE c.TABLE_NAME = @TableName
                      AND c.IS_NULLABLE = 'No'
                      AND c.COLUMN_NAME NOT IN ( 'ID' )
                      AND ISNULL(p.propertyValue, '') = ''
                      AND c.COLUMN_NAME <> @Name_or_Title;

                IF @Debug > 9
                BEGIN
                    RAISERROR(
                                 'Proc: %s Step: %s; Required properties without value %i',
                                 10,
                                 1,
                                 @ProcedureName,
                                 @ProcedureStep,
                                 @ReturnVariable
                             );
                END;

                --   IF @ReturnVariable > 0 
                BEGIN
                    DECLARE @propertyError VARCHAR(100);

                    SELECT TOP 1
                        @propertyError = p.propertyName
                    FROM INFORMATION_SCHEMA.COLUMNS AS c
                        INNER JOIN #Properties      AS p
                            ON p.propertyName = REPLACE(c.COLUMN_NAME, '_ID', '')
                    WHERE c.TABLE_NAME = @TableName
                          AND c.IS_NULLABLE = 'No'
                          AND c.COLUMN_NAME NOT IN ( 'ID' )
                          AND ISNULL(p.propertyValue, '') = ''
                          AND c.COLUMN_NAME <> @Name_or_Title;

                    IF ISNULL(@propertyError, '') <> ''
                        RAISERROR(
                                     'Proc: %s Step: %s Check Property %s in ClassTable is Null ',
                                     16,
                                     1,
                                     @ProcedureName,
                                     @ProcedureStep,
                                     @propertyError
                                 );
                END;

                SELECT @ProcedureStep = 'Insert validated records';

                --           BEGIN TRY

                SELECT @InsertQuery
                    = N'INSERT INTO [' + @TableName + N'] (' + @ColumnNames
                      + N'
										   ,Process_ID
										   ,LastModified
										   ,Update_ID 
										   )
										   SELECT *
										   FROM (
											   SELECT ' + @ColumnForInsert
                      + N'
												   ,0 AS Process_ID	
												   ,GETDATE() AS LastModified
												   ,' + CAST(@Update_ID AS NVARCHAR(100))
                      + N' AS Update_ID	
											   FROM ' + @TempNewObjects + N') t';

                SET @ProcedureStep = 'InsertQuery';

                IF @Debug > 9
                BEGIN
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                    SELECT @InsertQuery AS '@InsertQuery';
                END;
BEGIN TRAN
                EXECUTE sys.sp_executesql @InsertQuery;
                
COMMIT TRAN
                IF @Debug > 9
                BEGIN
                    SET @ProcedureStep = 'Query';
                    SET @Query
                        = N'	
				SELECT ''Inserted'' as inserted ,* FROM ' + QUOTENAME(@TableName) + N' ClassT INNER JOIN '
                          + @TempNewObjects + N' UpdT  on ClassT.objid = UpdT.Objid';

                    EXEC sys.sp_executesql @Query;

                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

              ----------------------------------------
            --Drop temporary tables
            ----------------------------------------
            SET @Params = N'@TableID int';
            SET @Query = N'
                        DELETE  ' + @TempObjectList + N'
                        WHERE   [ObjID] =  @TableID;';

            EXEC sys.sp_executesql @Query, @Params, @TableID;

            SET @Params = N'@TableID int';
            SET @Query = N'
                        DELETE  ' + @TempNewObjects + N'
                        WHERE   [ObjID] =  @TableID;';

            EXEC sys.sp_executesql @Query, @Params, @TableID;

            SET @Query
                = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempExistingObjects
                  + N''' )
                BEGIN
                    DROP TABLE ' + @TempExistingObjects + N';
                END ';

            EXEC (@Query);

            SET @Query
                = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempNewObjects
                  + N''' )
                BEGIN
                    DROP TABLE ' + @TempNewObjects + N';
                END ';

            EXEC (@Query);

            SET @Query
                = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempObjectList
                  + N''' )
                BEGIN
                    DROP TABLE ' + @TempObjectList + N';
                END ';

            EXEC (@Query);

            IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '##IsTemplateList')
            BEGIN
                DROP TABLE ##IsTemplateList;
            END;
        END; --if count of #properties > 0

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#Properties')
        BEGIN
            DROP TABLE #Properties;
        END;

        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempExistingObjects
              + N''' )
                BEGIN
                    DROP TABLE ' + @TempExistingObjects + N';
                END ';

        EXEC (@Query);

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempNewObjects
              + N''' )
                BEGIN
                    DROP TABLE ' + @TempNewObjects + N';
                END ';

        EXEC (@Query);

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempObjectList
              + N''' )
                BEGIN
                    DROP TABLE ' + @TempObjectList + N';
                END ';

        EXEC (@Query);

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '##IsTemplateList')
        BEGIN
            DROP TABLE ##IsTemplateList;
        END;

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#Properties')
        BEGIN
            DROP TABLE #Properties;
        END;

        IF @@TranCount <> 0
        BEGIN
            ROLLBACK TRAN;
        END;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        DECLARE @ErrorNumber INT;
        DECLARE @ErrorLine INT;
        DECLARE @ErrorProcedure NVARCHAR(128);
        DECLARE @OptionalMessage VARCHAR(MAX);

        SELECT @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity   = ERROR_SEVERITY(),
            @ErrorState      = ERROR_STATE(),
            @ErrorNumber     = ERROR_NUMBER(),
            @ErrorLine       = ERROR_LINE(),
            @ErrorProcedure  = ERROR_PROCEDURE();

        RAISERROR(   @ErrorMessage,
                                 -- Message text.
                     @ErrorSeverity,
                                 -- Severity.
                     @ErrorState -- State.
                 );

        --------------------------------------------------------------
        --INSERT ERROR DETAILS
        --------------------------------------------------------------
        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ProcedureStep,
            ErrorState,
            ErrorSeverity,
            ErrorLine,
            Update_ID
        )
        VALUES
        ('spMFUpdateTableInternal', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
            ERROR_SEVERITY(), ERROR_LINE(), @Update_ID);
    END CATCH;

    SET NOCOUNT OFF;
END;
GO