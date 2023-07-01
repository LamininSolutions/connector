PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateTable]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFCreateTable', -- nvarchar(100)
                                 @Object_Release = '4.10.32.76',   -- varchar(2506
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
2023-06-06  LC         resolve bug for excluding some columns on create
2023-04-19  LC         improve handling of lookup columns to handle duplicate property names
2022-12-01  LC         improve handling of mfsql properties and indexes
2022-12-01  LC         improve debugging and logging
2022-09-07  LC         remove unique index on externalid
2022-09-07  LC         revamp and simplify procedure
2022-09-07  LC         update after changes to classproperty table to add IsAdditional
2022-01-04  LC         update app detail logging to include assembly logging
2021-01-22  LC         set default schema to dbo
2020-11-21  LC         Fix bug with unique index on objid
2020-08-18  LC         replace deleted column flag with property 27 (deleted)
2020-05-12  LC         Add index on Update_ID to improve performance
2020-04-22  LC         Improve naming of constraints
2020-03-27  LC         Add MFSetting to allow optional create of indexes
2020-03-18  LC         Add non clustered unique index for objid
2020-03-11  LC         Add check license
2019-12-01  LC         Resolve where duplicate columns exist and removal of ID
2019-10-14  LC         Resolve multilookup table data type incorrectly set
2019-09-20  LC         allow for ID at end of name of a lookup property
2018-10-30  LC         Add creating unique index on objid and externalid
2018-04-17  LC         Add condition to only create trigger on table if includedinApp is set to 2 (for transaction based tables.)
2017-11-29  LC         Add error message of file does not exist or table already exist
2017-07-06  LC         Add new default column for FileCount
2016-10-15  LC         Change Default of Single_file to 0
2016-10-13  DEV2       Added Single_File Column in Class table
2016-10-02  LC         Update multi lookup columns to nvarchar(4000)
2016-09-10  LC         Set process_ID default to 1 and deleted default to 0 on creating new record
2016-08-18  LC         Add system columns with localized text names that is required for creating a new record
2016-06-27  LC         Automatically add includeInApp if null
2015-05-25  DEV2       Default column Update_ID added
2015-05-23  DEV2       Default column ExternalID added
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -------------------------------------------------------------
        -- Local variable Declaration
        -------------------------------------------------------------
        DECLARE @Output NVARCHAR(200),
                @ClassID INT,
                @TableName NVARCHAR(128),
                @dsql NVARCHAR(MAX) = N'',
                @ConstColumn NVARCHAR(MAX),
                @IDColumn NVARCHAR(MAX),
                @Count INT,
                @ProcedureName sysname = 'spMFCreateTable',
                @ProcedureStep sysname = 'Start',
                 @ClassCustomName NVARCHAR(100),
                        @ClassMFID INT,
                        @SQLDatatype_10 NVARCHAR(100),
                        @SQLDatatype_9 NVARCHAR(100),
                        @SQLDatatype_10_ID int,
                        @SQLDatatype_9_ID INT;
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = N''
		DECLARE @Msg AS NVARCHAR(256) = N''
        declare @delimiter nvarchar(10) = N'_ID'; -- Delimiter for MF Type ID 9 and 10
        declare @delimiterIndex int;

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

               /*************************************************************************
					  STEP Get id of of class column to set it up as default
					  NOTES
					  */

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

            SELECT @SQLDatatype_10 = mdt.SQLDataType, @SQLDatatype_10_ID = mdt.ID FROM dbo.MFDataType AS mdt
            WHERE mdt.MFTypeID = 10

            SELECT @SQLDatatype_9 = N'NVARCHAR(100)', @SQLDatatype_9_ID = mdt.ID FROM dbo.MFDataType AS mdt
            WHERE mdt.MFTypeID = 9
               
               SELECT @ClassCustomName = Name
                FROM dbo.MFProperty
                WHERE MFID = 100;

                  SELECT @ClassID = ID, @TableName = TableName,@ClassMFID = MFID
            FROM dbo.MFClass
            WHERE Name = @ClassName
                  AND Deleted = 0;

            SET @DebugText = N'class %s table %s'
			Set @DebugText = @DefaultDebugText + @DebugText

			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@ClassName, @TableName );
				END

 
 -------------------------------------------------------------
            --SELECT PROPERTY NAME AND DATA TYPE
            -------------------------------------------------------------
            SET @ProcedureStep = 'Select property and datatype';


            IF (SELECT OBJECT_ID('tempdb..#temp')) IS NOT NULL
            DROP TABLE #temp;

            CREATE TABLE #temp
            (ColumnName NVARCHAR(128) PRIMARY KEY
            ,MFDataType_ID NVARCHAR(250)
            ,SQLDataType NVARCHAR(100)
            ,ID INT
            ,PredefinedOrAutomatic NVARCHAR(100)
            )

            INSERT INTO #temp
            (ColumnName,
              MFDataType_ID,
              SQLDataType,
              ID,
              PredefinedOrAutomatic
              )
           
                SELECT DISTINCT mp.ColumnName,
                       CAST(mp.MFDataType_ID AS VARCHAR(10)),
                       mdt.SQLDataType,
                       mp.ID,
                       'NULL'
               FROM dbo.MFProperty mp
                INNER JOIN dbo.MFClassProperty AS mcp
                ON mcp.MFProperty_ID = mp.id 
                INNER JOIN dbo.MFClass AS mc
                ON mcp.MFClass_ID = mc.ID
                INNER JOIN dbo.MFDataType AS mdt
                ON mdt.id = mp.MFDataType_ID
                WHERE mp.Deleted = 0
     --            AND ISNULL(mcp.IsAdditional,0) = 0
                 AND mc.id = @Classid               

	SET @DebugText = N'#Temp table count %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                SELECT '#temp',t.*,mdt.SQLDataType
                FROM #Temp AS t
                INNER JOIN dbo.MFDataType AS mdt
                ON t.MFDataType_ID = mdt.ID

                SELECT @count = COUNT(*) FROM #temp AS t

				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@count );
				END
      
            END;

            -----------------------------------------------------------------
            --Updating PredefinedOrAutomatic with values from MFClassProperty
            -----------------------------------------------------------------
            SET @ProcedureStep = 'Adding lookup columns';

                  
                INSERT INTO #Temp
                (
                    ColumnName,
                    MFDataType_ID,
                    SQLDataType,
                    PredefinedOrAutomatic
                )
                SELECT *
                FROM
                (
                    SELECT CASE
                               WHEN SUBSTRING(ColumnName, LEN(ColumnName) - 2, 3) = @delimiter THEN
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 3)
                               ELSE
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 5)
                                   + REPLACE((SUBSTRING(ColumnName, (LEN(ColumnName) - 4), 5)), @delimiter, '')
                           END AS ColumnName,
                           @SQLDatatype_9_ID AS MFDataType_ID,
                            SQLDatatype =  @SQLDatatype_9 ,

                           'NULL' AS PredefinedOrAutomatic
                    FROM #Temp
                    WHERE MFDataType_ID = (
                              SELECT ID FROM dbo.MFDataType WHERE MFTypeID = 9
                          )
                ) AS n1
                UNION ALL
                SELECT *
                FROM
                (
                    SELECT CASE
                               WHEN SUBSTRING(ColumnName, LEN(ColumnName) - 2, 3) = @delimiter THEN
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 3)
                               ELSE
                                   SUBSTRING(ColumnName, 1, LEN(ColumnName) - 5)
                                   + REPLACE((SUBSTRING(ColumnName, (LEN(ColumnName) - 4), 5)), @delimiter, '')
                           END AS ColumnName,
                           @SQLDatatype_10_id AS MFDataType_ID,
                           SQLDatatype =  @SQLDatatype_10  ,
                           'NULL' AS PredefinedOrAutomatic
                    FROM #Temp
                    WHERE MFDataType_ID = 
                          (
                              SELECT id FROM dbo.MFDataType WHERE MFTypeID = 10
                          )
                ) AS n2;

             SET @DebugText = N'#Temp table count %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                SELECT '#temp - lookups',t.*,mdt.SQLDataType
                FROM #Temp AS t
                INNER JOIN dbo.MFDataType AS mdt
                ON t.MFDataType_ID = mdt.ID
                WHERE t.MFDataType_ID IN (9,10)

                SELECT @count = COUNT(*) FROM #temp AS t

				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@count );
				END
      
      --      END;

          
                -----------------------------------------------------------------------------
                --Add Additional Default columns in localised text
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'Variables for Default columns in localised text';

                DECLARE @NameOrTitle VARCHAR(100),
                        @classPropertyName VARCHAR(100),
                        @Workflow VARCHAR(100),
                        @State VARCHAR(100),
                        @SingleFile VARCHAR(100),
                        @WorkflowName VARCHAR(100),
                        @Deleted VARCHAR(100);

                SELECT @NameOrTitle = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 0;

                SELECT @classPropertyName = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 100;

                SELECT @Workflow = ColumnName,
                       @WorkflowName = Name
                FROM dbo.MFProperty
                WHERE MFID = 38;

                SELECT @State = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 39;

                SELECT @SingleFile = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 22;

                SELECT @Deleted = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 27;
   
  
                -----------------------------------------------------------------------------
                --GENERATING THE DYNAMIC QUERY TO CREATE TABLE    
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'dynamic create table query';

                SELECT @IDColumn
                    = N'[ID]  INT IDENTITY(1,1) NOT NULL ,[GUID] NVARCHAR(100),[MX_User_ID]  UNIQUEIDENTIFIER,';

                SELECT @dsql
                    = @dsql + QUOTENAME(ColumnName) + N' ' + sqlDataType + N' ' + PredefinedOrAutomatic + N','
                FROM #Temp
                ORDER BY ColumnName;

                SELECT @ConstColumn
                    = N'[LastModified]  DATETIME , ' + N'[Process_ID] INT, ' + N'[ObjID] INT, '
                      + N'[ExternalID]			NVARCHAR(100) , '
                      + N'[MFVersion]		INT,[FileCount] int , [Update_ID] int , '; ---- Added for task 106 [FileCount]

                SELECT @dsql = @IDColumn + @dsql + @ConstColumn;

                SELECT @dsql
                    = N'CREATE TABLE dbo.' + QUOTENAME(@TableName) + N' (' + LEFT(@dsql, LEN(@dsql) - 1)
                      + N'
								 CONSTRAINT pk_' + @TableName + N'ID PRIMARY KEY (ID))' +
                    N'
									ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_Process_id_'
                      + @TableName + N']  DEFAULT 1 FOR [Process_ID]
				    ALTER TABLE dbo.' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_FileCount_' + @TableName
                      + N']  DEFAULT 0 FOR [FileCount]
                       ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_LastModified_' + @TableName
                      + N']  DEFAULT GetDate() FOR [LastModified]
                        ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_' + @SingleFile + N'_'
                      + @TableName + N']  DEFAULT 0 FOR ' + QUOTENAME(@SingleFile) + N'
				     ';

                ---------------------------------------------------------------------------
                --EXECUTE DYNAMIC QUERY TO CREATE TABLE
                -----------------------------------------------------------------------------

            SET @DebugText = N''
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS CreateTable;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep);    
            END;
                EXEC sys.sp_executesql @Stmt = @dsql;

          /*************************************************************************
        Alter table
         */
                SET @ProcedureStep = 'default constraint for Class_ID';

                DECLARE @Params NVARCHAR(100);

                SET @Params = N'@Tablename nvarchar(100)';

                SELECT @dsql
                    = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DK_Class_' + @TableName
                      + N'] DEFAULT(' + CAST(-1 AS VARCHAR(10)) + N') FOR ' + QUOTENAME(@ClassCustomName + '_ID') + N'';

            SET @DebugText = N''
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS Class_Constraint;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep);    
            END;

                EXEC sys.sp_executesql @Stmt = @dsql,
                                       @Param = @Params,
                                       @Tablename = @TableName;

                -------------------------------------------------------------
                -- ADD standard Logging properties
                -------------------------------------------------------------
                SET @ProcedureStep = 'Add MFSQL_Message column';

                DECLARE @IsDetailLogging SMALLINT,
                        @SQL NVARCHAR(MAX);

                SELECT @IsDetailLogging = CAST(ISNULL(ms.Value, '0') AS INT)
                FROM dbo.MFSettings AS ms
                WHERE ms.Name = 'App_DetailLogging';

                SET @count = 0
                IF (@IsDetailLogging > 0 AND EXISTS(
                    SELECT mp.MFID
                    FROM dbo.MFProperty AS mp
                    WHERE mp.Name =  'MFSQL_Message')
                    AND NOT EXISTS( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS AS c
                        WHERE c.COLUMN_NAME = 'MFSQL_Message'
                              AND c.TABLE_NAME = @TableName))
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + N'
Add MFSQL_Message nvarchar(max) null;';

                            EXEC (@SQL);
                            SET @count = 1
                        END
                       
 
            SET @DebugText = N'Added %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS AddMFSQLMessage;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Count);    
            END;
 SET @ProcedureStep = 'Add MFSQL_Process_Batch column';
 SET @Count = 0
                         IF (@IsDetailLogging > 0 AND EXISTS(
                    SELECT mp.MFID
                    FROM dbo.MFProperty AS mp
                    WHERE mp.Name = 'MFSQL_Process_Batch'
                    AND NOT EXISTS( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS AS c
                        WHERE c.COLUMN_NAME = 'MFSQL_Process_Batch'
                              AND c.TABLE_NAME = @TableName)))
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + N'
Add  MFSQL_Process_batch int nul;';


                            EXEC (@SQL);
                            SET @count = 1
                        END

           SET @DebugText = N'Added %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS AddMFSQLProcessBatch;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Count);    
            END;

                -------------------------------------------------------------
                -- Add indexes and foreign keys
                -------------------------------------------------------------
                DECLARE @CreateUniqueIndexes INT;

                SELECT @CreateUniqueIndexes = CAST(ISNULL(ms.Value, '0') AS INT)
                FROM dbo.MFSettings AS ms
                WHERE ms.Name = 'CreateUniqueClassIndexes';

                IF @CreateUniqueIndexes = 1
                BEGIN
 
 SET @ProcedureStep = 'Index for objid'
                    SET @SQL
                        = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_Objid'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                          + N'''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + N'_Objid
ON dbo.' +          @TableName + N'(Objid) WHERE Objid is not null;';


                  SET @DebugText = N'Added %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS Index_Objid;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Count);    
            END;


                    EXEC (@SQL);

 SET @ProcedureStep = 'Index for ExternalID'

                    SET @SQL
                        = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_ExternalID'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                          + N'''))
CREATE NONCLUSTERED INDEX IX_' + @TableName + N'_ExternalID
ON dbo.' +          @TableName + N'(ExternalID)
WHERE ExternalID IS NOT NULL;';

                      SET @DebugText = N'Added %i'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
                  SELECT @dsql AS Index_External_ID;
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Count);    
            END;

                    EXEC (@SQL);

 
                END; -- create indexes

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

                               SET @DebugText = N' Include in App = 2 '
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN        
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep);    
            END;

                END;--end includeinapp = 2
              

                IF (OBJECT_ID('tempdb..#Temp')) IS NOT NULL
                    DROP TABLE #Temp;
         
         END; -- table exists
            ELSE
            BEGIN
                -----------------------------------------------------------------------------
                --SHOW ERROR MESSAGE
                -----------------------------------------------------------------------------
                 SET @DebugText = N' Table already exists'
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN           
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep);    
            END;

 

            -----------------------------------------------------------------------------
            --SHOW ERROR MESSAGE
            -----------------------------------------------------------------------------
    --        RAISERROR('Entered Class Name does not Exists in MFClass Table', 10, 1, @ProcedureName, @ProcedureStep);

            RETURN -1;
        END;

        -----------------------------------------------------------------------------
        --SET INCLUDEINAPP TO 1 IF NULL
        -----------------------------------------------------------------------------
        SET @ProcedureStep = 'Set Included in App if null';

        UPDATE mc
        SET mc.IncludeInApp = 1
        FROM dbo.MFClass AS mc
        WHERE @TableName = mc.TableName
              AND mc.IncludeInApp IS NULL;

                         SET @DebugText = N''
			Set @DebugText = @DefaultDebugText + @DebugText
            
           IF @Debug > 0
            BEGIN
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep);    
            END;      

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
               ERROR_MESSAGE() AS ErrorMessage,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_STATE() AS ErrorState,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_LINE() AS ErrorLine;

        RETURN 2;
    END CATCH;
END;
GO