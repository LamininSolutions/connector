
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateHistoryShow]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateHistoryShow', -- nvarchar(100)
    @Object_Release = '4.9.27.72',          -- varchar(50)
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
    @UpdateColumn INT = null,
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

The significance of the update column depends on the update method
  - 0 : Objects in class updated from SQL to MF
  - 1 : Objects in class updated from MF to SQL
  - 10: Object versions updated in audit history
  - 11: Object Change versions update in objectChange History

Update column reference
 - UpdateColumn 0 = ObjectDetails: 
   - UpdateMethod 1,10 : represent the objecttype and class, will always show 1 record
   - UpdateMethod 0 : represents the objects in the class to be updated, will show the number of properties to be updated
   - UpdateMethod 11 : class id and property id for changes
 - UpdateColumn 1 = ObjectVerDetails:
   - UpdateMethod 1,11 : represents the object ver in SQL to be compared with MF, will show the number of records to be updated
   - UpdateMethod 0,10 : not used
 - UpdateColumn 2 = NewOrUpdatedObjectVer: 
   - UpdateMethod 1 : Not used
   - UpdateMethod 0,10 : represents the object ver in SQL to be updated in MF, will show the number of records to be updated
   - UpdateMethod 11 :represents the objectversions returned from MF
 - UpdateColumn 3 = NewOrUpdateObjectDetails: 
   - UpdateMethod 0,1 : Represents the object ver details from MF to be updated in SQL, will show the number of properties to be updated

 - UpdateColumn 4 = SyncronisationErrors  (not yet implemented)
 - UpdateColumn 5 = MFError  (not yet implemented)
 - UpdateColumn 6 = DeletedObjects (not yet implemented)

Warning
=======

MFUpdatehistory has records for different types of operations.  This procedure is targeted and showing updates to and from M-Files using the spMFupdateTable, spMFTableAudit and spMFUpdateObjectChange procedure. 

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
2021-12-24  LC         Sset default for updatecolumn to null
2021-12-22  LC         Add Audit History and Object Change history show records
2021-12-13  LC         Remove redundant temp table from printing
2021-02-03  LC         Rewrite the procedure to streamline and fix errors
2020-08-22  LC         Update for impact of new deleted column
2018-05-09  LC         Fix bug with column 1
2018-08-01  LC         Fix bug with showing deletions
2017-06-09  LC         Change options to print either summary or detail
2017-06-09  Arnie      produce single result sets for easier usage
2016-01-10  LC         Create procedure
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
        DECLARE @Class_ID INT;
        DECLARE @Class NVARCHAR(100);
        DECLARE @ObjectType NVARCHAR(100);

    DECLARE @RowCount INT;
    DECLARE @TableName sysname;
    DECLARE @UpdateMethod INT;
    DECLARE @Idoc INT;
END; -- end declarations

IF (SELECT OBJECT_ID('temdb..#summary')) IS NOT NULL
DROP TABLE #summary;

BEGIN -- setup Summary
    CREATE TABLE #Summary
    (
        UpdateColumn SMALLINT,
        UpdateType NVARCHAR(100),
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
    (0, N'ObjectDetails', 'Object Type Details'),
    (1, N'ObjectVerDetails', 'Data from SQL to M-Files'),
    (2, N'NewOrUpdatedObjectVer', 'Object updated in M-Files'),
    (3, N'NewOrUpdateObjectDetails', 'Data From M-Files to SQL'),
    (4, N'SyncronisationErrors', 'SyncronisationErrors'),
    (5, N'MFError ', 'MFError'),
    (6, N'DeletedObjects', 'Deleted Objects');

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

    SET @Class_ID = CASE WHEN @UpdateMethod IN (0,1) THEN 
     (SELECT t.c.value('Object[1]/class[1]/@id', 'int') AS Class
    FROM @XML.nodes('/form') AS t(c)) 
    WHEN  @UpdateMethod IN (10) THEN 
    (SELECT t.c.value('ObjectType[1]/@ClassID', 'int') AS Class
    FROM @XML.nodes('/form') AS t(c)) 
     WHEN  @UpdateMethod IN (11) THEN 
    (SELECT t.c.value('Object[1]/@Class', 'int') AS Class
    FROM @XML.nodes('/form') AS t(c)) 
    ELSE
    null
    END
    ;
 
    SELECT @TableName = mc.TableName, @ObjectType = ot.Name, @class = mc.name
    FROM dbo.MFClass mc INNER JOIN MFObjectType ot ON ot.ID = mc.MFObjectType_ID WHERE mc.mfid = @Class_ID
    
     IF @Debug > 0
     select @Class_ID Classid, @ObjectType ObjectType,@TableName AS TableName;

    UPDATE #Summary
    SET UpdateType = CASE WHEN @UpdateMethod = 0 THEN 'Objects From SQL to MF'
    WHEN @UpdateMethod = 1 THEN 'Objects From MF to SQL'
    WHEN @UpdateMethod = 10 THEN 'Object Versions From MF'
    WHEN @UpdateMethod = 11 THEN 'Object Change History'
    ELSE NULL
    END,
    UpdateMethod = @UpdateMethod,
        Class = @Class ,
        ObjectType = @ObjectType,
        TableName = @TableName
    WHERE 1 = 1
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
BEGIN --Object Details column 0
    IF @Debug > 0
    BEGIN
        SELECT @XML AS ObjectDetails, @UpdateMethod AS UpdateMethod;
    END;

    IF
    @UpdateMethod = 0
    BEGIN 
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
                                      WHEN s.UpdateMethod in (1,10,11) THEN
                                          'Object Type Details'
                                      WHEN s.UpdateMethod = 0 THEN
                                          'Objects to update'
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
BEGIN --  ObjectVerDetails Col 1
        IF @Debug > 0
        BEGIN
            SELECT @XML1 AS ObjectVerDetails;
        END;

    IF
    @updateMethod = 1
    BEGIN -- updatemethod 1
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
        FROM @XML1.nodes('/form/objVers') AS t(c);

        SET @RowCount = @@RowCount;
    END; -- end updatemethod 1

    IF
    @updateMethod = 11
    BEGIN -- updatemethod 11
        INSERT INTO #ObjectID_3
        (
            objId,
            updatecolumn
        )
        SELECT t.c.value('@objid', 'int')         objid,
        1
           
        FROM @XML1.nodes('/form/object') AS t(c);

        SET @RowCount = @@RowCount;
    END; -- end updatemethod 11

    UPDATE #Summary
    SET RecCount = CASE
                       WHEN s.UpdateMethod in (1,11) THEN
                           @RowCount
                       WHEN s.UpdateMethod in (0,10) THEN
                           NULL
                   END,
        UpdateDescription = CASE
                                WHEN s.UpdateMethod in (1,11) THEN
                                    'Objects to update'
                                WHEN s.UpdateMethod in (0,10) THEN
                                    'N/A'
                            END
    FROM #Summary AS s
    WHERE s.UpdateColumn = 1;
END; --end ObjectVerDetails

BEGIN -- NewOrUpdateobjVer @UpdateColumn = 2
  IF @Debug > 0
        BEGIN
            SELECT @XML2 AS NewOrUpdatedObjectVer;
        END;
    IF
    @UpdateMethod = 0
    BEGIN -- updatemethod 0 

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

     IF
    @UpdateMethod = 10
    BEGIN -- updatemethod 10 

        INSERT INTO #ObjectID_3
        (
            objId,
            MFVersion,
            GUID,
            UpdateColumn
        )
        SELECT t.c.value('@objectID', 'int')         objid,
            t.c.value('@version', 'int')          MFVersion,
            t.c.value('@objectGUID', 'nvarchar(50)') GUID,
            2
        FROM @XML2.nodes('/form/objVers') AS t(c);

        SET @RowCount = @@RowCount;
    END; --end updatemethod 10

         IF
    @UpdateMethod = 11
    BEGIN -- updatemethod 11 

        INSERT INTO #ObjectID_3
        (
            objId,
           MFVersion,
   --         GUID,
            UpdateColumn
        )
        SELECT t.c.value('@ObjID', 'int')         objid,
            t.c.value('@Version', 'int')          MFVersion,
  --          t.c.value('@objectGUID', 'nvarchar(50)') GUID,
            2
        FROM @XML2.nodes('/form/Object') AS t(c);

        SET @RowCount = @@RowCount;
    END; --end updatemethod 11

    UPDATE #Summary
    SET RecCount = CASE
                       WHEN UpdateMethod = 1 THEN
                           NULL
                       WHEN UpdateMethod in (0,10,11) THEN
                           @RowCount
                   END,
        UpdateDescription = CASE
                                WHEN UpdateMethod = 0 THEN
                                    'Objects from SQL'
                                WHEN UpdateMethod = 10 THEN
                                    'Object versions from MF'
                                WHEN UpdateMethod = 11 THEN
                                    'Object Change versions from MF'
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

    IF @UpdateMethod IN (0,1) 
    begin
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
    SET RecCount = CASE WHEN @updateMethod IN (0,1) THEN @RowCount
    ELSE NULL END ,
        UpdateDescription = CASE WHEN @updateMethod IN (0,1) THEN 'Property Details from MF'
        ELSE 'N/A' END 
    WHERE UpdateColumn = 3;

END -- updatdate method 0,1
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

IF @UpdateColumn IS NOT null
BEGIN
    IF @Debug > 0
    begin
        SELECT *
        FROM #ObjectID_1 AS oi
        SELECT * FROM #ObjectID_3 AS oi
        end
        ;
/*

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


*/
-------------------------------------------------------------
-- Output of detail
-------------------------------------------------------------

IF @UpdateColumn = 3 AND @updateMethod IN (0,1)
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


IF  @UpdateColumn = 1
BEGIN
    SELECT oi.objId,
           oi.MFVersion,
           oi.GUID
    FROM #ObjectID_3 AS oi
    WHERE oi.UpdateColumn = 1
    GROUP BY oi.objId,
           oi.MFVersion,
           oi.GUID;
END;


IF  @UpdateColumn = 2
BEGIN
    SELECT oi.objId,
           oi.MFVersion,
           oi.GUID           
    FROM #ObjectID_3 AS oi
    WHERE oi.UpdateColumn = @UpdateColumn;

END;

IF @UpdateColumn = 7
   AND
   (
       SELECT UpdateMethod FROM #Summary WHERE UpdateColumn = 0
   ) = 0
BEGIN
    SELECT *
    FROM #ObjectID_3
        AS
        oi
    WHERE oi.UpdateColumn = 7
    ORDER BY oi.objId,
        oi.propertyId;
END;

--DROP TABLE #ObjectID_1;
--DROP TABLE #ObjectID_3;
--DROP TABLE #Summary;

END;
GO