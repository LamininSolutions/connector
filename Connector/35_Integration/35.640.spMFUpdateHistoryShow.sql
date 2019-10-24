
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateHistoryShow]';
GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFUpdateHistoryShow', -- nvarchar(100)
                                     @Object_Release = '4.1.5.43',           -- varchar(50)
                                     @UpdateFlag = 2;
-- smallint
GO


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-01
	Database: 
	Description: Show the records of an update id
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
    2017-06-09      Arnie       Move @Debug as last parameter
    2017-06-09      Arnie       Change logic to produce single result sets for easier usage in other procs; Change SELECT to PRINT for information message 
	2017-06-09		LC			Change options to print either summary or detail
	2018-08-01		LC			Fix bug with showing deletions
	2018-05-9		LC			Fix bug with column 1
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFUpdateHistoryShow] @Debug = 1, @Update_ID = 9372, @UpdateColumn = 2
  UpdateColumn 1 = ObjecVerDetails: Data from SQL to QML
  UpdateColumn 2 = NewOrUpdateObjectDetails: Data From M-Files to SQL
  UpdateColumn 3 = NewOrUpdatedObjectVer: Objects to be updated in M-Files
  UpdateColumn 4 = SyncronisationErrors  (no object currently showing
  UpdateColumn 5 = MFError  (no object currently showing
  UpdateColumn 6 = DeletedObjects
  UpdateColumn 7 = ObjectDetails = ObjectType & class & properities of new object  (updatemethod = 0)

  exec spmfupdateHistoryShow 9366, 1, 0, 0
  Select * from MFupdatehistory where updatemethod = 0
  select * from mfupdatehistory where id = 9366
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateHistoryShow' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateHistoryShow]
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFUpdateHistoryShow]
(
    @Update_ID INT,
    @IsSummary SMALLINT = 1,
    @UpdateColumn INT = 0,
    @Debug SMALLINT = 0
) AS;

SET NOCOUNT ON;

IF @Debug > 0
    SELECT *
    FROM [dbo].[MFUpdateHistory]
    WHERE [Id] = @Update_ID;

DECLARE @XML XML,
        @XML1 XML,
        @XML2 XML,
        @XML3 XML,
        @XML4 XML,
        @XML5 XML,
        @XML6 XML,
        @XML7 XML,
        @Query NVARCHAR(MAX),
        @Param NVARCHAR(MAX),
        @UpdateDescription VARCHAR(100);
DECLARE @RowCount INT;
DECLARE @TableName sysname;
DECLARE @UpdateMethod INT;
DECLARE @Idoc INT;


CREATE TABLE [#Summary]
(
    [UpdateColumn] SMALLINT,
    [ColumnName] NVARCHAR(100),
    [UpdateDescription] NVARCHAR(100),
    [UpdateMethod] SMALLINT,
    [RecCount] INT,
    [Class] NVARCHAR(100),
    [ObjectType] NVARCHAR(100),
    [TableName] NVARCHAR(100)
);
INSERT INTO [#Summary]
(
    [UpdateColumn],
    [ColumnName],
    [UpdateDescription]
)
VALUES
(0, N'ObjectDetails', 'Object Details'),
(1, N'ObjectVerDetails', 'Data from SQL to M-Files'),
(2, N'NewOrUpdatedObjectVer', 'Object updated in M-Files'),
(3, N'NewOrUpdateObjectDetails', 'Data From M-Files to SQL'),
(4, N'SyncronisationErrors', 'SyncronisationErrors'),
(5, N'MFError ', 'MFError'),
(6, N'DeletedObjects', 'Deleted Objects'),
(7, N'ObjectDetails', 'New Object from SQL');

SELECT @UpdateDescription = [UpdateDescription]
FROM [#Summary]
WHERE [UpdateColumn] = @UpdateColumn;


DECLARE @ClassPropName NVARCHAR(100);
SELECT @ClassPropName = [mp].[ColumnName]
FROM [dbo].[MFProperty] AS [mp]
WHERE [mp].[MFID] = 100;

SELECT @XML = [muh].[ObjectDetails],
       @XML1 = [muh].[ObjectVerDetails],
       @XML2 = [muh].[NewOrUpdatedObjectVer],
       @XML3 = [muh].[NewOrUpdatedObjectDetails],
       @XML4 = [muh].[SynchronizationError],
       @XML5 = [muh].[MFError],
       @XML6 = [muh].[DeletedObjectVer],
       @XML7 = [muh].[ObjectDetails],
       @UpdateMethod = [muh].[UpdateMethod]
FROM [dbo].[MFUpdateHistory] AS [muh]
WHERE [muh].[Id] = @Update_ID;

IF @UpdateMethod = 0
    DELETE FROM [#Summary]
    WHERE [UpdateColumn] = 7;

DECLARE @ObjectDetails AS TABLE
(
    [ObjectType] INT,
    [Class] INT,
    [Updatemethod] INT
);
INSERT INTO @ObjectDetails
SELECT [t].[c].[value]('Object[1]/@id', 'int') AS [ObjectType],
       [t].[c].[value]('Object[1]/class[1]/@id', 'int') AS [Class],
       @UpdateMethod AS [UpdateMethod]
FROM @XML.[nodes]('/form') AS [t]([c]);

IF @Debug > 0
    SELECT '@ObjectDetails' AS [ObjectDetails],
           *
    FROM @ObjectDetails;

SELECT @TableName = [TableName]
FROM @ObjectDetails
    INNER JOIN [dbo].[MFClass]
        ON [MFID] = [Class];

IF @Debug > 0
    SELECT @TableName AS [TableName];


UPDATE [#Summary]
SET [UpdateMethod] = [od].[Updatemethod],
    [Class] = [mc].[Name],
    [ObjectType] = [mo].[Name],
    [TableName] = [mc].[TableName]
FROM [#Summary]
    CROSS JOIN @ObjectDetails [od]
    INNER JOIN [dbo].[MFClass] [mc]
        ON [mc].[MFID] = [od].[Class]
    INNER JOIN [dbo].[MFObjectType] [mo]
        ON [mo].[MFID] = [od].[ObjectType];
--WHERE #Summary.UpdateColummn = 0;


--  @UpdateColumn = 1

BEGIN


    IF @Debug > 0
    BEGIN
        SELECT @XML1 AS [ObjectVerDetails];
    END;

    CREATE TABLE [#ObjectID_1]
    (
        [ObjectID] INT,
        [UpdateColumn] INT
    );
    INSERT INTO [#ObjectID_1]
    (
        [ObjectID],
        [UpdateColumn]
    )
    SELECT [t].[c].[value]('@objectID', 'int') [id],
           @UpdateColumn
    FROM @XML1.[nodes]('/form/objVers') AS [t]([c]);

    SET @RowCount = @@ROWCOUNT;
    UPDATE [#Summary]
    SET [RecCount] = @RowCount
    WHERE [UpdateColumn] = 1;


END;

-- @UpdateColumn = 2

BEGIN


    IF @Debug > 0
    BEGIN
        SELECT @XML2 AS [NewOrUpdatedObjectVer];
    END;

    INSERT INTO [#ObjectID_1]
    (
        [ObjectID],
        [UpdateColumn]
    )
    SELECT [t].[c].[value]('(@objectId)[1]', 'int') [objectid],
           @UpdateColumn
    FROM @XML2.[nodes]('/form/Object') AS [t]([c]);

    SET @RowCount = @@ROWCOUNT;
    UPDATE [#Summary]
    SET [RecCount] = @RowCount
    WHERE [UpdateColumn] = 2;

END;

-- @UpdateColumn = 3

BEGIN



    BEGIN



        IF @Debug > 0
        BEGIN

            SELECT @XML3 AS [NewOrUpdatedObjectDetails];
        END;
        --  SET @ProcedureStep = 'Parse the Input XML';
        --Parse the Input XML


        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @XML3;

        CREATE TABLE [#ObjectID_3]
        (
            [objId] INT,
            [MFVersion] INT,
            [GUID] NVARCHAR(100),
            [ExternalID] NVARCHAR(100),
            [propertyId] INT,
            [propertyName] NVARCHAR(100),
            [propertyValue] NVARCHAR(100),
            [dataType] NVARCHAR(100),
            [UpdateColumn] INT
        );

        INSERT INTO [#ObjectID_3]
        (
            [objId],
            [MFVersion],
            [GUID],
            [ExternalID],
            [propertyId],
            [propertyName],
            [propertyValue],
            [dataType],
            [UpdateColumn]
        )
        SELECT [x].[objId],
               [x].[MFVersion],
               [x].[GUID],
               [x].[ExternalID],
               [x].[propertyId],
               [mp].[Name],
               [x].[propertyValue],
               [x].[dataType],
               3
        FROM
            OPENXML(@Idoc, '/form/Object/properties', 1)
            WITH
            (
                [objId] INT '../@objectId',
                [MFVersion] INT '../@objVersion',
                [GUID] NVARCHAR(100) '../@objectGUID',
                [ExternalID] NVARCHAR(100) '../@DisplayID',
                [propertyId] INT '@propertyId',
                [propertyValue] NVARCHAR(100) '@propertyValue',
                [dataType] NVARCHAR(100) '@dataType'
            ) [x]
            LEFT JOIN [dbo].[MFProperty] [mp]
                ON [mp].[MFID] = [x].[propertyId];


        SET @RowCount = @@ROWCOUNT;
        UPDATE [#Summary]
        SET [RecCount] = @RowCount
        WHERE [UpdateColumn] = 3;



    END;

END;



-- @UpdateColumn = 4 
BEGIN



    IF @Debug > 0
    BEGIN
        SELECT @XML4 AS [SynchronizationError];
    END;

    INSERT INTO [#ObjectID_1]
    (
        [ObjectID],
        [UpdateColumn]
    )
    SELECT [t].[c].[value]('(@objectId)[1]', 'INT') [objectid],
           @UpdateColumn
    FROM @XML4.[nodes]('/form/Object') AS [t]([c]);

    SET @RowCount = @@ROWCOUNT;
    UPDATE [#Summary]
    SET [RecCount] = @RowCount
    WHERE [UpdateColumn] = 4;

END;

-- @UpdateColumn = 5 

BEGIN


    IF @Debug > 0
    BEGIN
        SELECT @XML5 AS [MFError];
    END;

    INSERT INTO [#ObjectID_1]
    (
        [ObjectID],
        [UpdateColumn]
    )
    SELECT [t].[c].[value]('(@objID)[1]', 'INT') [objectid],
           @UpdateColumn
    FROM @XML5.[nodes]('/form/errorInfo') AS [t]([c]);

    SET @RowCount = @@ROWCOUNT;
    UPDATE [#Summary]
    SET [RecCount] = @RowCount
    WHERE [UpdateColumn] = 5;

END;

-- @UpdateColumn 6

BEGIN


    IF @Debug > 0
    BEGIN
        SELECT @XML6 AS [DeletedObjectVer];
    END;

    CREATE TABLE [#ObjectID_6]
    (
        [ObjId] INT,
        [Updatecolumn] INT
    );


    INSERT INTO [#ObjectID_6]
    (
        [ObjId],
        [Updatecolumn]
    )
    SELECT [t].[c].[value]('(@objectID)[1]', 'INT') [objId],
           @UpdateColumn
    FROM @XML6.[nodes]('objVers') AS [t]([c]);

    SET @RowCount = @@ROWCOUNT;
    UPDATE [#Summary]
    SET [RecCount] = @RowCount
    WHERE [UpdateColumn] = 6;


END;

-- @UpdateColumn = 7

BEGIN

    IF @Debug > 0
    BEGIN

        SELECT @XML7 AS [ObjectDetails];
    END;

    IF @UpdateMethod = 1
    BEGIN

        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @XML7;

        INSERT INTO [#ObjectID_3]
        (
            [objId],
            [MFVersion],
            [propertyId],
            [propertyName],
            [propertyValue],
            [dataType],
            [UpdateColumn]
        )
        SELECT [i].[pd].[value]('../../@objID', 'int') AS [ObjectType],
               [i].[pd].[value]('../../@objVesrion', 'int') AS [Version],
               [i].[pd].[value]('@id', 'int') AS [propertyId],
               [mp].[Name],
               [i].[pd].[value]('.', 'NVARCHAR(100)') AS [propertyValue],
               [i].[pd].[value]('@dataType', 'NVARCHAR(100)') AS [dataType],
               7
        FROM @XML7.[nodes]('/form/Object/class/property') AS [i]([pd])
            CROSS APPLY @XML7.[nodes]('/form') AS [t2]([c2])
            LEFT JOIN [dbo].[MFProperty] [mp]
                ON [mp].[MFID] = [i].[pd].[value]('@id', 'int');

        Select @RowCount = COUNT(*) FROM  [#ObjectID_3]
        UPDATE [#Summary]
        SET [RecCount] = @RowCount
        WHERE [UpdateColumn] = 7;

        IF @Debug > 0
        BEGIN
            SELECT @RowCount AS [UpdateColumn_7];
            SELECT *
            FROM [#ObjectID_3] AS [oi];
        END;

    END;


END;

IF @IsSummary = 1
BEGIN
    SELECT *
    FROM [#Summary];
END;

IF @IsSummary = 0
   AND @UpdateColumn IN ( 1, 2, 4, 5 )
BEGIN

    IF @Debug > 0
        SELECT *
        FROM [#ObjectID_1] AS [oi];

    SET @Param = '@UpdateColumn int';
    SET @Query
        = N'
							SELECT c.TableName,  t.* FROM #ObjectID_1  AS [ovd]						
							INNER JOIN ' + QUOTENAME(@TableName)
          + ' t
							ON ovd.[ObjectID] = t.[ObjID]
							inner join MFClass c
							on c.mfid = t.' + @ClassPropName + ' where ovd.updatecolumn = @UpdateColumn ';

    EXEC [sys].[sp_executesql] @Query, @Param, @UpdateColumn = @UpdateColumn;

END;

IF @IsSummary = 0
   AND @UpdateColumn = 6
BEGIN


    SELECT *
    FROM [#ObjectID_6] AS [oi];


END;


IF @IsSummary = 0
   AND @UpdateColumn = 7
BEGIN

    IF @Debug > 0
        SELECT *
        FROM [#ObjectID_1] AS [oi];

    SET @Param = '@UpdateColumn int';
    SET @Query
        = N'
							SELECT c.TableName,  t.* FROM #ObjectID_1  AS [ovd]						
							INNER JOIN ' + QUOTENAME(@TableName)
          + ' t
							ON ovd.[ObjectID] = t.[ID]
							inner join MFClass c
							on c.mfid = t.' + @ClassPropName + ' where ovd.updatecolumn = @UpdateColumn ';

    IF @Debug > 0
        PRINT @Query;

    EXEC [sys].[sp_executesql] @Query, @Param, @UpdateColumn = @UpdateColumn;
END;

IF @IsSummary <> 1
   AND @UpdateColumn = 3
BEGIN

    SELECT *
    FROM [#ObjectID_3] AS [oi]
    WHERE [oi].[UpdateColumn] = 3;

END;

IF @IsSummary = 0
   AND @UpdateColumn = 7
   AND
   (
       SELECT [UpdateMethod] FROM [#Summary] WHERE [UpdateColumn] = 0
   ) = 0
BEGIN

    SELECT *
    FROM [#ObjectID_3]
        AS
        [oi]
    WHERE [oi].[UpdateColumn] = 7
    ORDER BY [oi].[objId],
             [oi].[propertyId];

END;
DROP TABLE [#ObjectID_1];
DROP TABLE [#ObjectID_3];
DROP TABLE [#Summary];



GO
