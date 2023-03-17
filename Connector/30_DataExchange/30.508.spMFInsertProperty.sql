PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertProperty]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertProperty', -- nvarchar(100)
    @Object_Release = '4.10.30.75',       -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFInsertProperty' --name of procedure
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
CREATE PROCEDURE dbo.spMFInsertProperty
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFInsertProperty
(
    @Doc NVARCHAR(MAX),
    @isFullUpdate BIT,
    @Output NVARCHAR(50) OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

==================
spMFInsertProperty
==================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Doc nvarchar(max)
    input XML
  @isFullUpdate bit
    When set to 1 is update of all properties
  @Output nvarchar(50) (output)
    return message
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Insert Property details into MFProperty table. This procedure is used as part of the metadata structure update and is not used on its own.

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-03-17  LC         Move check for duplicate properties to start of process
2019-08-30  JC         Added documentation
2018-11-04  LC         Enhancement to deal with changes in datatype
2017-12-28  DEV2       Change join condition at #1162
2017-11-30  LC         Remove duplicate _ID from State_ID
2017-11-23  LC         Localization of last modifed columns
2017-09-11  LC         Update constraints
2017-08-22  LC         Improve logging
2017-08-22  LC         Fix bug with contstraints
2015-07-14  DEV2       MFValuelist_ID column Added in MFProperty
2015-05-27  DEV2       New logic for inserting details from M-Files as per LeRoux
2015-05-15  DEV2       Checking for duplicate ColumnName and auto renaming if exists
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    DECLARE @trancount INT;

    SET @trancount = @@TranCount;

    BEGIN TRY
        IF @trancount = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION spMFInsertProperty;

        SET NOCOUNT ON;

        DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = N'';

        -----------------------------------------------------------
        -- DECLARING LOCAL VARIABLE
        -----------------------------------------------------------
        DECLARE @IDoc      INT,
            @RowAdded      INT,
            @RowUpdated    INT,
            @ProcedureStep sysname = 'Start',
            @ProcedureName sysname = 'spMFInsertProperty',
            @XML           XML     = @Doc,
            @Return_Value  INT;

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @ProcedureStep = 'Create #Properties Table';

        ---------------------------------------------------
        --Check whether #Properties already exists or not
        ---------------------------------------------------
        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#Properties')
        BEGIN
            DROP TABLE #Properties;
        END;

        -----------------------------------------------------------
        --CREATING TEMPORARY TABLE TO STORE DATA FROM XML
        -----------------------------------------------------------
        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        CREATE TABLE #Properties
        (
            Name VARCHAR(100),
            Alias VARCHAR(100),
            MFID INT NOT NULL,
            MFDataType_ID VARCHAR(100),
            MFValueList_ID INT,
            PredefinedOrAutomatic BIT
        );

        IF @Debug > 0
        BEGIN
            SET @ProcedureStep = 'Inserting Values into #Properties';

            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF @Debug > 10
            SELECT @XML as PropertyXML;

        -----------------------------------------------------------
        --INSERTING DATA FROM XML TO TEMPORARY TABLE
        -----------------------------------------------------------
        INSERT INTO #Properties
        (
            Name,
            Alias,
            MFID,
            MFDataType_ID,
            MFValueList_ID,
            PredefinedOrAutomatic
        )
        SELECT t.c.value('(@Name)[1]', 'NVARCHAR(100)')       AS NAME,
            t.c.value('(@Alias)[1]', 'NVARCHAR(100)')         AS Alias,
            t.c.value('(@MFID)[1]', 'INT')                    AS MFID,
            t.c.value('(@MFDataType_ID)[1]', 'NVARCHAR(100)') AS MFDataType_ID,
            t.c.value('@valueListID[1]', 'INT')               AS MFValueList_ID,
            t.c.value('(@Predefined)[1]', 'BIT')              AS PredefinedOrAutomatic
        FROM @XML.nodes('/form/Property') AS t(c);

      
        IF @Debug > 0
            SELECT 'new properties',*
            FROM #Properties AS p;


        -------------------------------------------------------------
        -- check for conflict of column names
        -------------------------------------------------------------s
        SET @ProcedureStep = 'Column Naming conflicts';

        DECLARE @NamingConflict AS TABLE
        (
            MFID INT,
            Name NVARCHAR(100)
        );

        DECLARE @NamingConflictString AS NVARCHAR(400);

        ;
        with cte as
        (select 
                mp.Name, count(*) rcount
            FROM #Properties  AS mp
            group by mp.name
            having count(*) > 1
            )
        INSERT INTO @NamingConflict
        (
            MFID,
            Name
        )
        SELECT mp2.MFID,
            mp2.Name
        FROM #Properties AS mp2
            INNER JOIN cte
                ON cte.name = mp2.Name;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT 'duplicate properties' AS Conflict,
                *
            FROM @NamingConflict AS nc;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF
        (
            SELECT COUNT(mfid) FROM @NamingConflict AS nc
        ) > 0
        BEGIN
            ;
            SELECT @NamingConflictString = STUFF(
                                           (
                                               SELECT ',' + nc.Name + ' (' + CAST(nc.MFID AS VARCHAR(5)) + ')'
                                               FROM @NamingConflict AS nc
                                               FOR XML PATH('')
                                           ),
                                                    1,
                                                    1,
                                                    ''
                                                );

            SET @DebugText
                = N' properties: ' + @NamingConflictString
                  + N' must be renamed in M-Files to avoid duplication conflicts';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        -------------------------------------------------------------
        -- get current properties
        -------------------------------------------------------------
  SELECT @ProcedureStep = 'Store current MFProperty records int #CurrentMFProperty';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF EXISTS
        (
            SELECT name
            FROM sys.sysobjects
            WHERE name = '#CurrentMFProperty'
        )
        BEGIN
            DROP TABLE #CurrentMFProperty;
        END;

        ------------------------------------------------------
        --Store present records in MFProperty to #CurrentMFProperty
        ------------------------------------------------------
        SELECT mfc.ID,
            mfc.Name,
            mfc.Alias,
            mfc.MFID,
            mfc.ColumnName,
            mfc.MFDataType_ID,
            mfc.PredefinedOrAutomatic,
            mfc.ModifiedOn,
            mfc.CreatedOn,
            mfc.Deleted,
            mfc.MFValueList_ID
        INTO #CurrentMFProperty
        FROM
        (
            SELECT ID,
                Name,
                Alias,
                MFID,
                ColumnName,
                MFDataType_ID,
                PredefinedOrAutomatic,
                ModifiedOn,
                CreatedOn,
                Deleted,
                MFValueList_ID
            FROM dbo.MFProperty
        ) AS mfc;

        SELECT @ProcedureStep = 'DROP CONSTAINT FROM MFClassProperty';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        ------------------------------------------------------
        --Drop CONSTRAINT
        ------------------------------------------------------
        DECLARE @Constraint NVARCHAR(100),
            @SQL            NVARCHAR(MAX);

        DECLARE @ConstraintList AS TABLE
        (
            ConstraintName NVARCHAR(100)
        );

        INSERT INTO @ConstraintList
        (
            ConstraintName
        )
        SELECT OBJECT_NAME(object_id) AS ConstraintName
        FROM sys.objects
        WHERE type_desc LIKE 'FOREIGN_KEY_CONSTRAINT'
              AND OBJECT_NAME(parent_object_id) = 'MFClassProperty';

        WHILE EXISTS (SELECT * FROM @ConstraintList AS cl)
        BEGIN
            SELECT TOP 1
                @Constraint = cl.ConstraintName
            FROM @ConstraintList AS cl;

            SET @SQL = N' ALTER TABLE [MFClassProperty] DROP CONSTRAINT ' + @Constraint;

            EXEC (@SQL);

            DELETE FROM @ConstraintList
            WHERE ConstraintName = @Constraint;
        END;

        SELECT @ProcedureStep = 'Update MFClassProperty';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        ---------------------------------------------------------
        --Update the MFClassProperty.MFProperty_ID with MFProperty.MFID
        ---------------------------------------------------------
        --SELECT * FROM    MFClassProperty
        --                 INNER JOIN MFProperty ON MFProperty_ID = MFProperty.ID;
        UPDATE dbo.MFClassProperty
        SET MFProperty_ID = MFID
        FROM dbo.MFClassProperty
            INNER JOIN dbo.MFProperty
                ON MFProperty_ID = ID;

        SELECT @ProcedureStep = 'Delete records from MFProperty';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- validate changes to mfdatatype
        -------------------------------------------------------------
        SET @ProcedureStep = 'Validate datatype changes';

        DECLARE @RowCount INT;

        DECLARE @DataTypeChanges AS TABLE
        (
            MFID INT,
            MFTypeID INT
        );

        INSERT INTO @DataTypeChanges
        (
            MFID,
            MFTypeID
        )
        SELECT p.MFID,
            mdt.ID
        FROM #Properties              AS p
            INNER JOIN dbo.MFDataType AS mdt
                ON p.MFDataType_ID = mdt.Name
        WHERE MFID > 1000
        EXCEPT
        SELECT cmp.MFID,
            cmp.MFDataType_ID
        FROM #CurrentMFProperty AS cmp
        WHERE cmp.MFID > 1000;

        IF @Debug > 0
        BEGIN
            SELECT *
            FROM @DataTypeChanges AS dtc;
        --raiserror('Databatypes changed', 16,1 )
        END;

        ----------------------------------------------------
        --Delete records from MFProperty
        ----------------------------------------------------
        DELETE FROM dbo.MFProperty;

        SELECT @ProcedureStep = 'Update MFID with PK ID';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -----------------------------------------------------------
        --Selecting MFDataType ID Depending Upon Property DataType
        -----------------------------------------------------------
        UPDATE #Properties
        SET MFDataType_ID =
            (
                SELECT ID FROM dbo.MFDataType WHERE Name = #Properties.MFDataType_ID
            );

        ----Bug #1162
        UPDATE #Properties
        SET MFValueList_ID = MFV.ID
        FROM #Properties              AS tmp
            LEFT JOIN dbo.MFValueList AS MFV
                ON tmp.MFValueList_ID = MFV.MFID
                   AND MFV.Deleted = 0;

        SELECT @ProcedureStep = 'Insert Records into MFProperty';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF @Debug > 10
            SELECT *
            FROM #Properties AS p;

        ------------------------------------------------
        --Insert Records into MFProperty
        ------------------------------------------------
        CREATE TABLE #MFProperty01
        (
            Name VARCHAR(100),  --COLLATE Latin1_General_CI_AS
            Alias VARCHAR(100), --COLLATE Latin1_General_CI_AS NOT NULL
            MFID INT NOT NULL,
            ColumnName NVARCHAR(250),
            MFDataType_ID INT,
            MFValueList_ID INT,
            PredefinedOrAutomatic BIT,
            Deleted BIT
        );

        ------------------------------------------------
        --Insert New records into Temp table
        ------------------------------------------------
        INSERT INTO #MFProperty01
        (
            Name,
            Alias,
            MFID,
            ColumnName,
            MFDataType_ID,
            MFValueList_ID,
            PredefinedOrAutomatic,
            Deleted
        )
        SELECT *
        FROM
        (
            SELECT Name,
                Alias,
                MFID,
                CASE
                    WHEN
                    (
                        SELECT MFTypeID FROM dbo.MFDataType WHERE ID = MFDataType_ID
                    ) = 9 THEN
                        dbo.fnMFReplaceSpecialCharacter(Name) + '_ID'
                                                              --REMOVING SPECIAL CHARACTER AND IF DATATYPE IS MFLOOKUP,APPENDING '_ID' TO PROPERTY NAME
                    WHEN
                    (
                        SELECT MFTypeID FROM dbo.MFDataType WHERE ID = MFDataType_ID
                    ) = 10 THEN
                        dbo.fnMFReplaceSpecialCharacter(Name) + '_ID'
                                                              --REMOVING SPECIAL CHARACTER AND IF DATATYPE IS MFMULTISELECTLOOKUP,APPENDING '_ID' TO PROPERTY NAME
                    ELSE
                        dbo.fnMFReplaceSpecialCharacter(Name) --REMOVING SPECIAL CHARACTER AND 
                END                  AS ColumnName,
                MFDataType_ID,
                MFValueList_ID,
                PredefinedOrAutomatic,
                0                    AS Deleted
            FROM #Properties
        ) AS n;

        ------------------------------------------------
        --Check for Duplicate ColumnName,If duplicate 
        --values exists append auto numbering
        ------------------------------------------------
        WHILE
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT t.ColumnName
                FROM #MFProperty01 AS t
                GROUP BY t.ColumnName
                HAVING COUNT(t.ColumnName) > 1
            ) AS m
        ) > 0
        BEGIN
            SELECT *
            INTO #Duplicate
            FROM
            (
                SELECT mfp.MFID,
                    mfp.ColumnName,
                    ROW_NUMBER() OVER (PARTITION BY mfp.ColumnName ORDER BY mfp.MFID DESC) AS RowNumber
                FROM #MFProperty01 AS mfp
                WHERE mfp.ColumnName IN
                      (
                          SELECT t.ColumnName
                          FROM #MFProperty01 AS t
                          GROUP BY t.ColumnName
                          HAVING COUNT(t.ColumnName) > 1
                      )
            ) AS Duplicate;

            UPDATE mfp
            SET mfp.ColumnName = mfp.ColumnName + '0' + CAST(
                                                        (
                                                            SELECT MAX(RowNumber) - 1
                                                            FROM #Duplicate
                                                            WHERE ColumnName = mfp.ColumnName
                                                        ) AS NVARCHAR(10)) --APPEND NUMBER LIKE Property01
            FROM #MFProperty01        AS mfp
                INNER JOIN #Duplicate AS dp
                    ON mfp.MFID = dp.MFID
                       AND dp.RowNumber = 1; --SELECT FIRST PROPERTY

            DROP TABLE #Duplicate;
        END;

        ---------------------------------------------
        --Insert Records into MFProperty
        ---------------------------------------------
        INSERT INTO dbo.MFProperty
        (
            Name,
            Alias,
            MFID,
            ColumnName,
            MFDataType_ID,
            MFValueList_ID,
            PredefinedOrAutomatic,
            Deleted
        )
        SELECT *
        FROM
        (
            SELECT Name,
                Alias,
                MFID,
                ColumnName,
                MFDataType_ID,
                MFValueList_ID,
                PredefinedOrAutomatic,
                Deleted
            FROM #MFProperty01
        ) AS new;

        SELECT @Output = @@RowCount;

        SELECT @ProcedureStep = 'Update MFProperty with Data from old table';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        UPDATE dbo.MFProperty
        SET ColumnName = 'MF_' + ColumnName
        WHERE MFID = 21;

        UPDATE dbo.MFProperty
        SET ColumnName = 'MF_' + ColumnName
        WHERE MFID = 23;

        --		UPDATE	[MFProperty] SET [ColumnName] = ColumnName + '_ID' WHERE [MFID] = 39;
        SELECT @ProcedureStep = 'Update columnNames from previous';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        ---------------------------------------------------------------------
        --Update MFProperty with ColumnName from Old table
        ---------------------------------------------------------------------
        UPDATE dbo.MFProperty
        SET ColumnName = #CurrentMFProperty.ColumnName
        FROM dbo.MFProperty
            INNER JOIN #CurrentMFProperty
                ON MFProperty.Name = #CurrentMFProperty.Name;

        ------------------------------------------------
        --Check for Duplicate ColumnName,If duplicate 
        --values exists append auto numbering
        ------------------------------------------------
        SELECT @ProcedureStep = 'Check for duplicates';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        WHILE
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT t.ColumnName
                FROM dbo.MFProperty AS t
                GROUP BY t.ColumnName
                HAVING COUNT(t.ColumnName) > 1
            ) AS m
        ) > 0
        BEGIN
            SELECT *
            INTO #Duplicate01
            FROM
            (
                SELECT mfp.MFID,
                    mfp.ColumnName,
                    ROW_NUMBER() OVER (PARTITION BY mfp.ColumnName ORDER BY mfp.MFID DESC) AS RowNumber
                FROM dbo.MFProperty AS mfp
                WHERE mfp.ColumnName IN
                      (
                          SELECT t.ColumnName
                          FROM dbo.MFProperty AS t
                          GROUP BY t.ColumnName
                          HAVING COUNT(t.ColumnName) > 1
                      )
            ) AS Duplicate;

            UPDATE mfp
            SET mfp.ColumnName = CASE
                                     WHEN (ISNUMERIC(RIGHT(mfp.ColumnName, 1)) <> 0) THEN
                                         REPLACE(
                                                    mfp.ColumnName,
                                                    RIGHT(mfp.ColumnName, 1),
                                                    CAST(CAST(RIGHT(mfp.ColumnName, 1) AS INT) + 1 AS NVARCHAR(10))
                                                )
                                     ELSE
                                         mfp.ColumnName + '0' + CAST(
                                                                (
                                                                    SELECT MAX(RowNumber) - 1
                                                                    FROM #Duplicate01
                                                                    WHERE ColumnName = mfp.ColumnName
                                                                ) AS NVARCHAR(10)) --APPEND NUMBER LIKE Property01
                                 END
            FROM dbo.MFProperty         AS mfp
                INNER JOIN #Duplicate01 AS dp
                    ON mfp.MFID = dp.MFID
                       AND dp.RowNumber = 1; --SELECT FIRST PROPERTY

            DROP TABLE #Duplicate01;
        END;

        SELECT @ProcedureStep = 'Update MFCLassProperty with PK ID';;

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- check for conflict of column names
        -------------------------------------------------------------s
        --SET @ProcedureStep = 'Column Naming conflicts';

        --DECLARE @NamingConflict AS TABLE
        --(
        --    MFID INT,
        --    Name NVARCHAR(100)
        --);

        --DECLARE @NamingConflictString AS NVARCHAR(400);

        --WITH cte
        --AS (SELECT REPLACE(mp.Name, ' ', '_') ColumnName,
        --        mp.Name
        --    FROM dbo.MFProperty AS mp
        --    WHERE mp.MFDataType_ID IN ( 8, 9 )),
        --cte2
        --AS (SELECT REPLACE(mp.ColumnName, '_', ' ') AS name
        --    FROM dbo.MFProperty AS mp
        --    WHERE mp.ColumnName IN
        --          (
        --              SELECT cte.ColumnName FROM cte
        --          ))
        --INSERT INTO @NamingConflict
        --(
        --    MFID,
        --    Name
        --)
        --SELECT mp2.MFID,
        --    mp2.Name
        --FROM dbo.MFProperty AS mp2
        --    INNER JOIN cte2
        --        ON cte2.name = mp2.Name;

        --WITH cte
        --AS (SELECT mp.Name AS ColumnName,
        --        mp.Name
        --    FROM dbo.MFProperty AS mp
        --    WHERE mp.MFDataType_ID IN ( 8, 9 )),
        --cte2
        --AS (SELECT mp.ColumnName AS name
        --    FROM dbo.MFProperty AS mp
        --    WHERE mp.ColumnName IN
        --          (
        --              SELECT cte.ColumnName FROM cte
        --          ))
        --INSERT INTO @NamingConflict
        --(
        --    MFID,
        --    Name
        --)
        --SELECT mp2.MFID,
        --    mp2.Name
        --FROM dbo.MFProperty AS mp2
        --    INNER JOIN cte2
        --        ON cte2.name = mp2.Name;

        --SET @DebugText = N'';
        --SET @DebugText = @DefaultDebugText + @DebugText;

        --IF @Debug > 0
        --BEGIN
        --    SELECT 'conflict' AS Conflict,
        --        *
        --    FROM @NamingConflict AS nc;

        --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        --END;

        --IF
        --(
        --    SELECT COUNT(*) FROM @NamingConflict AS nc
        --) > 0
        --BEGIN
        --    ;
        --    SELECT @NamingConflictString = STUFF(
        --                                   (
        --                                       SELECT ',' + nc.Name + ' (' + CAST(nc.MFID AS VARCHAR(5)) + ')'
        --                                       FROM @NamingConflict AS nc
        --                                       FOR XML PATH('')
        --                                   ),
        --                                            1,
        --                                            1,
        --                                            ''
        --                                        );

        --    SET @DebugText
        --        = N' properties: ' + @NamingConflictString
        --          + N' must be renamed in M-Files to avoid duplication conflicts';
        --    SET @DebugText = @DefaultDebugText + @DebugText;

        --    IF @Debug > 0
        --    BEGIN
        --        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        --    END;
        --END;

        -----------------------------------------------------------
        --Delete the records of Property which not exists in new vault
        -----------------------------------------------------------
        DELETE FROM dbo.MFClassProperty
        WHERE MFProperty_ID NOT IN
              (
                  SELECT MFID FROM dbo.MFProperty
              );

        -----------------------------------------------------
        --Update MFClassProperty.MFclass_ID with MFProperty.ID
        -----------------------------------------------------
        UPDATE dbo.MFClassProperty
        SET MFProperty_ID = ID
        FROM dbo.MFClassProperty
            INNER JOIN dbo.MFProperty
                ON MFProperty_ID = MFID;

        SELECT @ProcedureStep = 'ADD CONSTRAINT';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            SELECT *
            FROM dbo.MFClassProperty     AS CP
                LEFT JOIN dbo.MFProperty AS mp
                    ON mp.ID = CP.MFProperty_ID;
        END;

        -------------------------------------------------------------
        -- update required in mfclass property
        -------------------------------------------------------------
        --------------------------------------------
        --	Add CONSTRAINT to [dbo].[MFClassProperty]
        --------------------------------------------
        BEGIN TRY
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Adding constraint for MFClassProperty';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;


            IF (SELECT OBJECT_ID('FK_MFClassProperty_MFClass_ID')) IS NULL
            BEGIN

            ALTER TABLE [dbo].[MFClassProperty]  WITH CHECK ADD  CONSTRAINT [FK_MFClassProperty_MFClass_ID] FOREIGN KEY([MFCLASS_ID])
REFERENCES [dbo].[MFClass] ([ID])

ALTER TABLE [dbo].[MFClassProperty] CHECK CONSTRAINT [FK_MFClassProperty_MFClass_ID]

                --ALTER TABLE dbo.MFClassProperty
                --ADD CONSTRAINT FK_MFClassProperty_MFClass_ID
                --    FOREIGN KEY (MFClass_ID)
                --    REFERENCES dbo.MFClass (ID);
            END;

            IF (SELECT OBJECT_ID('FK_MFClassProperty_MFProperty_ID', 'F')) IS NULL
            BEGIN
                --ALTER TABLE dbo.MFClassProperty
                --ADD CONSTRAINT FK_MFClassProperty_MFProperty_ID
                --    FOREIGN KEY (MFProperty_ID)
                --    REFERENCES dbo.MFProperty (ID);
ALTER TABLE [dbo].[MFClassProperty]  WITH CHECK ADD  CONSTRAINT [FK_MFClassProperty_MFProperty_ID] FOREIGN KEY([MFProperty_ID])
REFERENCES [dbo].[MFProperty] ([ID])

ALTER TABLE [dbo].[MFClassProperty] CHECK CONSTRAINT [FK_MFClassProperty_MFProperty_ID]



            END;
        END TRY
        BEGIN CATCH
            SET @Return_Value = 2;

            RAISERROR('Adding constraint FK_MFClassProperty_MFProperty could not be resolved', 16, 1);
        END CATCH;

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#Properties')
        BEGIN
            DROP TABLE #Properties;
        END;

        IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = '#CurrentMFProperty')
        BEGIN
            DROP TABLE #CurrentMFProperty;
        END;

        SET @Output = CAST(ISNULL(@RowAdded, 0) + ISNULL(@RowUpdated, 0) AS VARCHAR(100));

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            SELECT @Output AS output;
        END;

        SELECT @ProcedureStep = 'END Insert Properties';

        IF @Return_Value IS NULL
            SET @Return_Value = 1;

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s Return %i', 10, 1, @ProcedureName, @ProcedureStep, @Return_Value);
        END;

        IF @trancount = 0
            COMMIT;

        RETURN 1;

        SET NOCOUNT OFF;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
            ROLLBACK;

        IF XACT_STATE() = 1
           AND @trancount = 0
            ROLLBACK;

        IF XACT_STATE() = 1
           AND @trancount > 0
            ROLLBACK TRANSACTION spMFInsertProperty;

        SET NOCOUNT ON;

        IF @Debug > 0
        BEGIN
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
            ('spMFInsertProperty', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
                ERROR_LINE(), @ProcedureStep);
        END;

        DECLARE @ErrNum   INT           = ERROR_NUMBER(),
            @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE(),
            @ErrSeverity  INT           = ERROR_SEVERITY(),
            @ErrState     INT           = ERROR_STATE(),
            @ErrMessage   NVARCHAR(MAX) = ERROR_MESSAGE(),
            @ErrLine      INT           = ERROR_LINE();

        SET NOCOUNT OFF;

        RAISERROR(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);

        RETURN -1;
    END CATCH;
END;
GO