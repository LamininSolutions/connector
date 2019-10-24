PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFObjectTypeUpdateClassIndex]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFObjectTypeUpdateClassIndex' -- nvarchar(100)
                                    ,@Object_Release = '4.2.7.47'                    -- varchar(50)
                                    ,@UpdateFlag = 2;                                -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Description: Performs Insert Update for ObjectTypeClassIndex table.  only classes included in app will be updated. 
	 
	Use xxxx procedure to dinamically build a view on all the related class tables.
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-11-23		lc			localization of MF-LastModified and MFLastModified by
	2018-12-15		lc			bug with last modified date; add option to set objecttype
	2018-13-21		LC			add feature to get reference of all objects in Vault
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFObjectTypeUpdateClassIndex]   @Debug = 0
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFObjectTypeUpdateClassIndex' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFObjectTypeUpdateClassIndex]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFObjectTypeUpdateClassIndex]
    @IsAllTables BIT = 0
   ,@Debug SMALLINT = 0
AS
SET NOCOUNT ON;

BEGIN
    DECLARE @result        INT
           ,@ClassName     NVARCHAR(100)
           ,@TableName     NVARCHAR(100)
           ,@id            INT
           ,@schema        NVARCHAR(5)  = 'dbo'
           ,@SQL           NVARCHAR(MAX)
           ,@ObjectType    VARCHAR(100)
           ,@ObjectTypeID  INT
           ,@ProcessStep   sysname      = 'START'
           ,@ProcedureName sysname      = 'spMFObjectTypeUpdateClassIndex';

    --SELECT * FROM [dbo].[MFClass] AS [mc]
    --SELECT * FROM [dbo].[MFObjectType] AS [mot]
    IF @Debug > 0
    BEGIN
        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
    END;

    -------------------------------------------------------------
    --	Set all tables to be included
    -------------------------------------------------------------
    IF @IsAllTables = 1
        UPDATE [dbo].[MFClass]
        SET [IncludeInApp] = 10
        WHERE [IncludeInApp] IS NULL;

    -------------------------------------------------------------
    -- Get objvers
    -------------------------------------------------------------
    DECLARE @RowID INT = 1;
    DECLARE @outPutXML NVARCHAR(MAX);
    DECLARE @Idoc INT;
    DECLARE @Class_ID INT;

    WHILE @RowID IS NOT NULL
    BEGIN
        SELECT @id           = [mc].[ID]
              ,@Class_ID     = [mc].[MFID]
              ,@ClassName    = [mc].[Name]
              ,@TableName    = [mc].[TableName]
              ,@ObjectTypeID = [mot].[MFID]
        FROM [dbo].[MFClass]                [mc]
            INNER JOIN [dbo].[MFObjectType] AS [mot]
                ON [mc].[MFObjectType_ID] = [mot].[ID]
        WHERE [mc].[ID] = @RowID
              AND [mc].[IncludeInApp] IS NOT NULL;



        IF @id IS NOT NULL
        BEGIN
            EXEC [dbo].[spMFGetObjectvers] @TableName = @TableName         -- nvarchar(100)
                                          ,@dtModifiedDate = NULL          -- datetime
                                          ,@MFIDs = NULL                   -- nvarchar(4000)
                                          ,@outPutXML = @outPutXML OUTPUT; -- nvarchar(max)

            EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;

            MERGE INTO [dbo].[MFObjectTypeToClassObject] [t]
            USING
            (
                SELECT [xmlfile].[objId]
                      ,[xmlfile].[MFVersion]
                      ,[xmlfile].[GUID]
                      ,[xmlfile].[ObjectType_ID]
                FROM
                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        [objId] INT './@objectID'
                       ,[MFVersion] INT './@version'
                       ,[GUID] NVARCHAR(100) './@objectGUID'
                       ,[ObjectType_ID] INT './@objectType'
                    ) [xmlfile]
            ) [s]
            ON [t].[ObjectType_ID] = [s].[ObjectType_ID]
               AND [t].[Object_MFID] = [s].[objId]
			   AND t.[Class_ID] = @Class_ID
            WHEN NOT MATCHED THEN
                INSERT
                (
                    [ObjectType_ID]
                   ,[Class_ID]
                   ,[Object_MFID]
                )
                VALUES
                ([s].[ObjectType_ID], @Class_ID, [s].[objId]);

            EXEC [sys].[sp_xml_removedocument] @Idoc;
        END;

        SET @RowID =
        (
            SELECT MIN([mc].[ID])
            FROM [dbo].[MFClass] [mc]
            WHERE [mc].[ID] > @RowID
                  AND [mc].[IncludeInApp] IS NOT NULL
        );
    END;

    /****************************Get all class and object type tables to be included*/
    DECLARE [CursorTable] CURSOR LOCAL FAST_FORWARD FOR
    SELECT [mc].[MFID]
          ,[mc].[Name]
          ,[mc].[TableName]
          ,[mot].MFID AS [MFObjectType_ID]
    FROM [dbo].[MFClass] AS [mc]
	INNER JOIN [dbo].[MFObjectType] AS [mot]
	ON mc.[MFObjectType_ID] = mot.id
    WHERE [mc].[IncludeInApp] IS NOT NULL
    ORDER BY [mc].[ID] ASC;

    -------------------------------------------------------------
    -- update object table using TableAudit with all objects
    -------------------------------------------------------------
    OPEN [CursorTable];

    FETCH NEXT FROM [CursorTable]
    INTO @id
        ,@ClassName
        ,@TableName
        ,@ObjectTypeID;

    WHILE @@Fetch_Status = 0
    BEGIN
        IF @Debug > 0
        BEGIN
            SELECT @id
                  ,@ClassName
                  ,@TableName
                  ,@ObjectTypeID;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [INFORMATION_SCHEMA].[TABLES]
            WHERE [TABLE_NAME] = @TableName
                  AND [TABLE_SCHEMA] = @schema
        )
        BEGIN
            BEGIN
                DECLARE @lastModifiedColumn NVARCHAR(100);

                SELECT @lastModifiedColumn = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [mp].[MFID] = 21; --'Last Modified'

                DECLARE @lastModifiedColumnBy NVARCHAR(100);

                SELECT @lastModifiedColumnBy = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [mp].[MFID] = 23; --'Last Modified By'

                SET @ProcessStep = 'Merge Table ' + @ClassName;

                IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
                END;

                SET @SQL
                    = N'

DECLARE @ClassID INT;
SELECT  @ClassID = MFID
FROM    MFClass
WHERE   [MFClass].[TableName] = ''' + @TableName
                      + ''';

MERGE INTO MFObjectTypeToClassObject AS T
USING
    ( SELECT    mot.mfid as [MFObjectType_ID] ,
                mc.MFID ,
                ct.[ObjID] ,
                ct.' + QUOTENAME(@lastModifiedColumnBy) + ' ,
                ct.' + QUOTENAME(@lastModifiedColumn) + ' ,
                ct.[Deleted]
      FROM      [dbo].' + QUOTENAME(@TableName)
                      + ' ct
                INNER JOIN MFClass mc ON [mc].[MFID] = ct.[Class_ID]
				INNER JOIN [dbo].[MFObjectType] AS [mot]
	ON mc.[MFObjectType_ID] = mot.id
    ) AS S
ON T.[ObjectType_ID] = S.[MFObjectType_ID]
    AND [T].[Class_ID] = S.[MFID]
    AND T.[Object_MFID] = S.[ObjID]
WHEN NOT MATCHED THEN
    INSERT ( [ObjectType_ID] ,
             [Class_ID] ,
             [Object_MFID] ,
             [Object_LastModifiedBy] ,
             [Object_LastModified] ,
             [Object_Deleted]
           )
    VALUES ( S.[MFObjectType_ID] ,
             S.MFID ,
             S.[ObjID] ,
             S.' + QUOTENAME(@lastModifiedColumnBy) + ' ,
             S.' + QUOTENAME(@lastModifiedColumn)
                      + ' ,
             S.[Deleted]
           )
WHEN MATCHED THEN
    UPDATE SET 
               T.[Object_LastModifiedBy] = S.' + QUOTENAME(@lastModifiedColumnBy)
                      + ' ,
               T.[Object_LastModified] = S.' + QUOTENAME(@lastModifiedColumn)
                      + ' ,
               T.[Object_Deleted] = S.[Deleted]
;'    ;

                                   IF @Debug <> 0
                                       PRINT  @SQL;
                EXEC [sys].[sp_executesql] @SQL;
            END;
        END;

        FETCH NEXT FROM [CursorTable]
        INTO @id
            ,@ClassName
            ,@TableName
            ,@ObjectTypeID;
    END;

    CLOSE [CursorTable];
    DEALLOCATE [CursorTable];
END;

SET @ProcessStep = 'END';

IF @Debug > 0
BEGIN
    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
	END
    -------------------------------------------------------------
    --	ReSet all tables to be included
    -------------------------------------------------------------
    IF @IsAllTables = 1
        UPDATE [dbo].[MFClass]
        SET [IncludeInApp] = NULL
        WHERE [IncludeInApp] = 10;
--SELECT  *
--    FROM    [dbo].[MFObjectTypeToClassObject] AS [mottco];

GO