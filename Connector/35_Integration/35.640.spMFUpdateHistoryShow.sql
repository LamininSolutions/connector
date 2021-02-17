
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateHistoryShow]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateHistoryShow', -- nvarchar(100)
    @Object_Release = '4.8.22.62',          -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateHistoryShow' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateHistoryShow
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateHistoryShow
(
    @Update_ID INT,
    @IsSummary SMALLINT = 1,
    @UpdateColumn INT = 0,
    @Debug SMALLINT = 0
) AS;

/*rST**************************************************************************

=====================
spMFUpdateHistoryShow
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Update_ID
    - id of the MFUpdateHistory table to be investigated
  @IsSummary
    Set to 1 to show summary report.  The columns for further inspection is obtained from this summary
  @UpdateColumn
    Set to the column number in the summary to show the detail of the column. Note that @IsSummary must be set to 0 for @UpdateColumn to have an effect
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To show the details of a specific update history record for updates using spmfupdatetable.  

The parameter 'IsSummary' = 1 will show a summary of each column in addition to the result for the selected column.  With IsSummary = 0 only the detail for the selected column will be shown.

The result is a join between the column data and the class table.  The first couple of columns has additional info for identification.

Additional Info
===============

Update column reference
 - UpdateColumn 0 = ObjectDetails: 
   - For UpdateMethod 1 : represent the objecttype and class, will always show 1 record
   - For UpdateMethod 0 : represents the objects in the class to be updated, will show the number of properties to be updated
 - UpdateColumn 1 = ObjectVerDetails:
   - For UpdateMethod 1 : represents the object ver in SQL to be compared with MF, will show the number of records to be updated
   - For UpdateMethod 0 : not used
 - UpdateColumn 2 = NewOrUpdatedObjectVer: 
   - For UpdateMethod 1 : Not used
   - For UpdateMethod 0 : represents the object ver in SQL to be updated in MF, will show the number of records to be updated
 - UpdateColumn 3 = NewOrUpdateObjectDetails: 
   - Represents the object ver details from MF to be updated in SQL, will show the number of properties to be updated

 - UpdateColumn 4 = SyncronisationErrors  (not yet implemented)
 - UpdateColumn 5 = MFError  (not yet implemented)
 - UpdateColumn 6 = DeletedObjects (not yet implemented)

Warning
=======

MFUpdatehistory has records for different types of operations.  This procedure is targeted and showing updates to and from M-Files using the spMFupdateTable procedure. Using it for rows in the MFupdateHistory for other types of updates will produce false results or through an  error.

Examples
========

.. code:: sql
    
    EXEC dbo.spMFUpdateHistoryShow @Update_ID = 30,
    @IsSummary = 1,
    @UpdateColumn = 3,
    @Debug = 0

    select * from mfupdatehistory where id = 30

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-01-10  LC         Create procedure
2017-06-09  Arnie      produce single result sets for easier usage 
2017-06-09  LC         Change options to print either summary or detail
2018-08-01  LC         Fix bug with showing deletions
2018-05-09  LC         Fix bug with column 1
2020-08-22  LC         Update for impact of new deleted column  
2021-02-03  LC         Rewrite the procedure to streamline and fix errors
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

BEGIN -- Declarations
    IF @Debug > 0
        SELECT *
        FROM dbo.MFUpdateHistory
        WHERE Id = @Update_ID;

    DECLARE @XML           XML,
        @XML1              XML,
        @XML2              XML,
        @XML3              XML,
        @XML4              XML,
        @XML5              XML,
        @XML6              XML,
        --    @XML7              XML,
        @Query             NVARCHAR(MAX),
        @Param             NVARCHAR(MAX),
        @UpdateDescription VARCHAR(100);
    DECLARE @RowCount INT;
    DECLARE @TableName sysname;
    DECLARE @UpdateMethod INT;
    DECLARE @Idoc INT;
END; -- end declarations

BEGIN -- setup Summary
    CREATE TABLE #Summary
    (
        UpdateColumn SMALLINT,
        ColumnName NVARCHAR(100),
        UpdateDescription NVARCHAR(100),
        UpdateMethod SMALLINT,
        RecCount INT,
        Class NVARCHAR(100),
        ObjectType NVARCHAR(100),
        TableName NVARCHAR(100)
    );

    INSERT INTO #Summary
    (
        UpdateColumn,
        ColumnName,
        UpdateDescription
    )
    VALUES
    (0, N'ObjectDetails', 'Object Details'),
    (1, N'ObjectVerDetails', 'Data from SQL to M-Files'),
    (2, N'NewOrUpdatedObjectVer', 'Object updated in M-Files'),
    (3, N'NewOrUpdateObjectDetails', 'Data From M-Files to SQL'),
    (4, N'SyncronisationErrors', 'SyncronisationErrors'),
    (5, N'MFError ', 'MFError'),
    (6, N'DeletedObjects', 'Deleted Objects');

    --(7, N'ObjectDetails', 'New Object from SQL');
    SELECT @UpdateDescription = UpdateDescription
    FROM #Summary
    WHERE UpdateColumn = @UpdateColumn;

    DECLARE @ClassPropName NVARCHAR(100);

    SELECT @ClassPropName = mp.ColumnName
    FROM dbo.MFProperty AS mp
    WHERE mp.MFID = 100;

    SELECT @XML       = muh.ObjectDetails,
        @XML1         = muh.ObjectVerDetails,
        @XML2         = muh.NewOrUpdatedObjectVer,
        @XML3         = muh.NewOrUpdatedObjectDetails,
        @XML4         = muh.SynchronizationError,
        @XML5         = muh.MFError,
        @XML6         = muh.DeletedObjectVer,
        --   @XML7         = muh.ObjectDetails,
        @UpdateMethod = muh.UpdateMethod
    FROM dbo.MFUpdateHistory AS muh
    WHERE muh.Id = @Update_ID;

    --IF @UpdateMethod = 0
    --    DELETE FROM #Summary
    --    WHERE UpdateColumn = 7;
    DECLARE @ClassDetails AS TABLE
    (
        ObjectType INT,
        Class INT,
        Updatemethod INT
    );

    INSERT INTO @ClassDetails
    SELECT t.c.value('Object[1]/@id', 'int')       AS ObjectType,
        t.c.value('Object[1]/class[1]/@id', 'int') AS Class,
        @UpdateMethod                              AS UpdateMethod
    FROM @XML.nodes('/form') AS t(c);

    IF @Debug > 0
        SELECT *
        FROM @ClassDetails;

    SELECT @TableName = TableName
    FROM @ClassDetails
        INNER JOIN dbo.MFClass
            ON MFID = Class;

    IF @Debug > 0
        SELECT @TableName AS TableName;

    UPDATE #Summary
    SET UpdateMethod = od.Updatemethod,
        Class = mc.Name,
        ObjectType = mo.Name,
        TableName = mc.TableName
    FROM #Summary
        CROSS JOIN @ClassDetails od
        INNER JOIN dbo.MFClass      mc
            ON mc.MFID = od.Class
        INNER JOIN dbo.MFObjectType mo
            ON mo.MFID = od.ObjectType;
END; --end setup summary

BEGIN -- setup temp tables
    IF
    (
        SELECT OBJECT_ID('tempdb..#ObjectID_1')
    ) IS NOT NULL
        DROP TABLE #ObjectID_1;

    CREATE TABLE #ObjectID_1
    (
        ObjectID INT,
        UpdateColumn INT
    );

    IF
    (
        SELECT OBJECT_ID('tempdb..#ObjectID_3')
    ) IS NOT NULL
        DROP TABLE #ObjectID_3;

    CREATE TABLE #ObjectID_3
    (
        objId INT,
        MFVersion INT,
        GUID NVARCHAR(100),
        ExternalID NVARCHAR(100),
        propertyId INT,
        propertyName NVARCHAR(100),
        propertyValue NVARCHAR(100),
        dataType NVARCHAR(100),
        UpdateColumn INT
    );
END;

--end setup temp tables

-------------------------------------------------------------
-- Object Details
-------------------------------------------------------------
BEGIN --Object Details
    IF @Debug > 0
    BEGIN
        SELECT @XML AS ObjectDetails;
    END;

    IF
    (
        SELECT s.UpdateMethod FROM #Summary AS s WHERE s.UpdateColumn = 0
    ) = 1
    BEGIN -- insert updatemethod 1
        INSERT INTO #ObjectID_1
        (
            ObjectID,
            UpdateColumn
        )
        SELECT t.c.value('(@Id)[1]', 'INT') objectid,
            0
        FROM @XML.nodes('/form/Object') AS t(c);

        SELECT @RowCount = @@RowCount;

        UPDATE s
        SET s.RecCount = @RowCount,
            s.UpdateDescription = CASE
                                      WHEN s.UpdateMethod = 1 THEN
                                          'Object Type Details'
                                      WHEN s.UpdateMethod = 0 THEN
                                          'Object Details'
                                  END
        FROM #Summary AS s
        WHERE s.UpdateColumn = 0;
    END;

    IF
    (
        SELECT s.UpdateMethod FROM #Summary AS s WHERE s.UpdateColumn = 0
    ) = 0
    BEGIN -- insert updatemethod 0
        INSERT INTO #ObjectID_3
        (
            objId,
            MFVersion,
            propertyId,
            propertyName,
            propertyValue,
            dataType,
            UpdateColumn
        )
        SELECT i.pd.value('../../@objID', 'int')     AS ObjectType,
            i.pd.value('../../@objVesrion', 'int')   AS Version,
            i.pd.value('@id', 'int')                 AS propertyId,
            mp.Name,
            i.pd.value('.', 'NVARCHAR(100)')         AS propertyValue,
            i.pd.value('@dataType', 'NVARCHAR(100)') AS dataType,
            0
        FROM @XML.nodes('/form/Object/class/property') AS i(pd)
            CROSS APPLY @XML.nodes('/form')            AS t2(c2)
            LEFT JOIN dbo.MFProperty mp
                ON mp.MFID = i.pd.value('@id', 'int');

        SET @RowCount = @@RowCount;

        UPDATE s
        SET s.RecCount = @RowCount,
            s.UpdateDescription = CASE
                                      WHEN s.UpdateMethod = 1 THEN
                                          'Object Type Details'
                                      WHEN s.UpdateMethod = 0 THEN
                                          'Property Details to MF'
                                  END
        FROM #Summary AS s
        WHERE s.UpdateColumn = 0;
    END; -- end updatemethod 0
END;

--end Object Details
-------------------------------------------------------------
-- ObjectVerDetails
-------------------------------------------------------------
BEGIN --  ObjectVerDetails
    IF
    (
        SELECT s.UpdateMethod FROM #Summary AS s WHERE s.UpdateColumn = 1
    ) = 1
    BEGIN -- updatemethod 1
        IF @Debug > 0
        BEGIN
            SELECT @XML1 AS ObjectVerDetails;
        END;

        INSERT INTO #ObjectID_3
        (
            objId,
            MFVersion,
            GUID,
            UpdateColumn
        )
        SELECT t.c.value('@objectID', 'int')         objid,
            t.c.value('@version', 'int')             MFVersion,
            t.c.value('@objectGUID', 'nvarchar(50)') GUID,
            1
        FROM @XML1.nodes('/form/ObjectType/objVers') AS t(c);

        SET @RowCount = @@RowCount;
    END; -- end updatemethod 1

    UPDATE #Summary
    SET RecCount = CASE
                       WHEN s.UpdateMethod = 1 THEN
                           @RowCount
                       WHEN s.UpdateMethod = 0 THEN
                           NULL
                   END,
        UpdateDescription = CASE
                                WHEN s.UpdateMethod = 1 THEN
                                    'Object Details'
                                WHEN s.UpdateMethod = 0 THEN
                                    'N/A'
                            END
    FROM #Summary AS s
    WHERE s.UpdateColumn = 1;
END; --end ObjectVerDetails

BEGIN -- NewOrUpdateobjVer @UpdateColumn = 2
    IF
    (
        SELECT s.UpdateMethod FROM #Summary AS s WHERE s.UpdateColumn = 1
    ) = 0
    BEGIN -- updatemethod 0 
        IF @Debug > 0
        BEGIN
            SELECT @XML2 AS NewOrUpdatedObjectVer;
        END;

        INSERT INTO #ObjectID_3
        (
            objId,
            MFVersion,
            GUID,
            UpdateColumn
        )
        SELECT t.c.value('@objectId', 'int')         objid,
            t.c.value('@objVersion', 'int')          MFVersion,
            t.c.value('@objectGUID', 'nvarchar(50)') GUID,
            2
        FROM @XML2.nodes('/form/Object') AS t(c);

        SET @RowCount = @@RowCount;
    END; --end updatemethod 0

    UPDATE #Summary
    SET RecCount = CASE
                       WHEN UpdateMethod = 1 THEN
                           NULL
                       WHEN UpdateMethod = 0 THEN
                           @RowCount
                   END,
        UpdateDescription = CASE
                                WHEN UpdateMethod = 0 THEN
                                    'Object version Details from SQL'
                                WHEN UpdateMethod = 1 THEN
                                    'N/A'
                            END
    WHERE UpdateColumn = 2;
END; -- end @UpdateColumn = 2

BEGIN -- NewOrUpdatedObjectDetails @UpdateColumn = 3
    IF @Debug > 0
    BEGIN
        SELECT @XML3 AS NewOrUpdatedObjectDetails;
    END;

    --  SET @ProcedureStep = 'Parse the Input XML';
    --Parse the Input XML
    EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @XML3;

    INSERT INTO #ObjectID_3
    (
        objId,
        MFVersion,
        GUID,
        ExternalID,
        propertyId,
        propertyName,
        propertyValue,
        dataType,
        UpdateColumn
    )
    SELECT x.objId,
        x.MFVersion,
        x.GUID,
        x.ExternalID,
        x.propertyId,
        mp.Name,
        x.propertyValue,
        x.dataType,
        3
    FROM
        OPENXML(@Idoc, '/form/Object/properties', 1)
        WITH
        (
            objId INT '../@objectId',
            MFVersion INT '../@objVersion',
            GUID NVARCHAR(100) '../@objectGUID',
            ExternalID NVARCHAR(100) '../@DisplayID',
            propertyId INT '@propertyId',
            propertyValue NVARCHAR(100) '@propertyValue',
            dataType NVARCHAR(100) '@dataType'
        )                        x
        LEFT JOIN dbo.MFProperty mp
            ON mp.MFID = x.propertyId;

    SET @RowCount = @@RowCount;

    IF @Idoc IS NOT NULL
        EXEC sys.sp_xml_removedocument @Idoc;

    UPDATE #Summary
    SET RecCount = @RowCount,
        UpdateDescription = 'Property Details from MF'
    WHERE UpdateColumn = 3;
END; -- end @UpdateColumn = 3

BEGIN -- SynchronizationError @UpdateColumn = 4 
    IF @Debug > 0
    BEGIN
        SELECT @XML4 AS SynchronizationError;
    END;

    INSERT INTO #ObjectID_1
    (
        ObjectID,
        UpdateColumn
    )
    SELECT t.c.value('(@objectId)[1]', 'INT') objectid,
        @UpdateColumn
    FROM @XML4.nodes('/form/Object') AS t(c);

    SET @RowCount = @@RowCount;

    UPDATE #Summary
    SET RecCount = @RowCount
    WHERE UpdateColumn = 4;
END;

-- @UpdateColumn = 5 
BEGIN
    IF @Debug > 0
    BEGIN
        SELECT @XML5 AS MFError;
    END;

    INSERT INTO #ObjectID_1
    (
        ObjectID,
        UpdateColumn
    )
    SELECT t.c.value('(@objID)[1]', 'INT') objectid,
        @UpdateColumn
    FROM @XML5.nodes('/form/errorInfo') AS t(c);

    SET @RowCount = @@RowCount;

    UPDATE #Summary
    SET RecCount = @RowCount
    WHERE UpdateColumn = 5;
END;

-- @UpdateColumn 6
BEGIN
    IF @Debug > 0
    BEGIN
        SELECT @XML6 AS DeletedObjectVer;
    END;

    CREATE TABLE #ObjectID_6
    (
        ObjId INT,
        Updatecolumn INT
    );

    INSERT INTO #ObjectID_6
    (
        ObjId,
        Updatecolumn
    )
    SELECT t.c.value('(@objectID)[1]', 'INT') objId,
        @UpdateColumn
    FROM @XML6.nodes('objVers') AS t(c);

    SET @RowCount = @@RowCount;

    UPDATE #Summary
    SET RecCount = @RowCount
    WHERE UpdateColumn = 6;
END;

IF @IsSummary = 1
BEGIN
    SELECT *
    FROM #Summary;
END;

IF @IsSummary = 0
BEGIN
    IF @Debug > 0
    begin
        SELECT *
        FROM #ObjectID_1 AS oi
        SELECT * FROM #ObjectID_3 AS oi
        end
        ;

    SET @Param = N'@UpdateColumn int';
    SET @Query
        = N'
							SELECT 
                             s.objectType, 
                            s.Tablename, 
                            s.ColumnName, 
                            UpdateDescription,  
                            ovd.*, t.* FROM #Summary s
                             cross apply #ObjectID_1  AS [ovd]	                           						
							left JOIN ' + QUOTENAME(@TableName)
          + N' t
							ON ovd.[ObjectID] = t.[ObjID]
							 where ovd.updatecolumn = @UpdateColumn
                             and s.UpdateColumn = @UpdateColumn
                             ';

    EXEC sys.sp_executesql @Query, @Param, @UpdateColumn = @UpdateColumn;
END;

--IF @UpdateColumn IN (1,3)
BEGIN
   SET @Param = N'@UpdateColumn int';
    SET @Query
        = N'
							SELECT 
                            s.objectType, 
                            s.Tablename, 
                            s.ColumnName, 
                            UpdateDescription,  
                            ovd.*, 
                            t.* 
                            FROM #Summary s
                            cross apply #ObjectID_3  AS [ovd]	                           
							INNER JOIN ' + QUOTENAME(@TableName)
          + N' t
							ON ovd.[ObjID] = t.[ObjID]
							 where ovd.updatecolumn = @UpdateColumn 
                             and s.UpdateColumn = @UpdateColumn';

    EXEC sys.sp_executesql @Query, @Param, @UpdateColumn = @UpdateColumn;
END;

--IF @IsSummary <> 1
--   AND @UpdateColumn = 3
--BEGIN
--    SELECT *
--    FROM #ObjectID_3 AS oi
--    WHERE oi.UpdateColumn = 3;
--END;

--IF @IsSummary = 0
--   AND @UpdateColumn = 7
--   AND
--   (
--       SELECT UpdateMethod FROM #Summary WHERE UpdateColumn = 0
--   ) = 0
--BEGIN
--    SELECT *
--    FROM #ObjectID_3
--        AS
--        oi
--    WHERE oi.UpdateColumn = 7
--    ORDER BY oi.objId,
--        oi.propertyId;
--END;

DROP TABLE #ObjectID_1;
DROP TABLE #ObjectID_3;
DROP TABLE #Summary;
GO