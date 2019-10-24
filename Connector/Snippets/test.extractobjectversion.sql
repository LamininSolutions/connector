
/*

*/
--Created on: 2019-06-13 
DECLARE @RowID INT = 1;
DECLARE @outPutXML NVARCHAR(MAX);
DECLARE @Idoc INT;
DECLARE @Return_Result INT;
DECLARE @Class_ID INT;
DECLARE @result        INT
       ,@ClassName     NVARCHAR(100)
       ,@TableName     NVARCHAR(100) = 'MFMiscInvoice'
       ,@id            INT
       ,@schema        NVARCHAR(5)   = 'dbo'
       ,@SQL           NVARCHAR(MAX)
       ,@ObjectType    VARCHAR(100)
       ,@ObjectTypeID  INT
       ,@ProcessStep   sysname       = 'START'
       ,@ProcedureName sysname       = 'spMFObjectTypeUpdateClassIndex'
       ,@StartTime     DATETIME
       ,@Msg           NVARCHAR(400);

SET @StartTime = GETUTCDATE();

SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

SET @ProcessStep = 'Get ObjectVer from MF';

RAISERROR('%s : Start long running %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;

EXEC [dbo].[spMFGetObjectvers] @TableName = @TableName         -- nvarchar(100)
                              ,@dtModifiedDate = NULL          -- datetime
                              ,@MFIDs = null                  -- nvarchar(4000)
                              ,@outPutXML = @outPutXML OUTPUT; -- nvarchar(max)

SELECT CAST(@outPutXML AS XML)

EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;

SET @StartTime = GETUTCDATE();

SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

RAISERROR('%s : End %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;

IF
(
    SELECT OBJECT_ID('temp..#XMLObjverList')
) > 0
    DROP TABLE [#XMLObjverList];

SET @ProcessStep = 'Create XML extract';
SET @StartTime = GETUTCDATE();

SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

RAISERROR('%s : Start %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;

BEGIN TRY
    ;
    WITH [cte]
    AS (SELECT [xmlfile].[objId]
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
            ) [xmlfile])
    SELECT *
    INTO [#XMLObjVerList]
    FROM [cte];

	EXEC [sys].[sp_xml_removedocument] @Idoc;

	SELECT * FROM [#XMLObjVerList] AS [xovl]

    SET @StartTime = GETUTCDATE();

    SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

    RAISERROR('%s : End %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;
END TRY
BEGIN CATCH
    RAISERROR('Error with getting ObjverData', 16, 1);
END CATCH;



SET @ProcessStep = 'Merge into MFObjectTypeclassObject';
SET @StartTime = GETUTCDATE();

SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

RAISERROR('%s : Start %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;

BEGIN TRY



INSERT INTO  [dbo].[MFObjectTypeToClassObject] 
([ObjectType_ID],[Class_ID],[Object_MFID])
SELECT @ObjectTypeID, @Class_ID, [xovl].[objId]

FROM [#XMLObjVerList] AS [xovl]
left JOIN [dbo].[MFObjectTypeToClassObject] [t]
ON [xovl].[objId] = t.[Object_MFID] AND t.[Class_ID] = @Class_ID
WHERE t.[Object_MFID] IS NULL 

DELETE FROM [dbo].[MFObjectTypeToClassObject] 
WHERE id IN  (SELECT [t].[ID]
 FROM [#XMLObjVerList] AS [xovl]
right JOIN [dbo].[MFObjectTypeToClassObject] [t]
ON [xovl].[objId] = t.[Object_MFID] AND t.[Class_ID] = @Class_ID
WHERE [xovl].objid IS NULL) 

/*
    MERGE INTO [dbo].[MFObjectTypeToClassObject] [t]
    USING
    (
        SELECT [xmlfile].[objId]
              ,[xmlfile].[MFVersion]
              ,[xmlfile].[GUID]
              ,[xmlfile].[ObjectType_ID]
        FROM [#XMLObjVerList] [xmlfile]
        WHERE [xmlfile].[objId] IS NOT NULL
    ) [s]
    ON [t].[ObjectType_ID] = [s].[ObjectType_ID]
       AND [t].[Object_MFID] = [s].[objId]
       AND [t].[Class_ID] = @Class_ID
    WHEN NOT MATCHED THEN
        INSERT
        (
            [ObjectType_ID]
           ,[Class_ID]
           ,[Object_MFID]
        )
        VALUES
        ([s].[ObjectType_ID], @Class_ID, [s].[objId]);

*/

    SET @StartTime = GETUTCDATE();

    SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

    RAISERROR('%s : End %s', 10, 1, @Msg, @ProcessStep) WITH NOWAIT;
END TRY
BEGIN CATCH
    RAISERROR('Error with updating table', 16, 1);
END CATCH;

SET @StartTime = GETUTCDATE();

SELECT @Msg = CONVERT(NVARCHAR(25), @StartTime);

RAISERROR('%s : Completee %s', 10, 1, @Msg, @ProcedureName) WITH NOWAIT;

SELECT *
FROM [dbo].[MFObjectTypeToClassObject];