
/*
Testing get internal history
*/
--Created on: 2019-09-05 
DECLARE @VaultSettings nvarchar(400) = [dbo].[FnMFVaultSettings]()
DECLARE @Result NVARCHAR(MAX);
DECLARE @objectType INT 
DECLARE @MFTableName NVARCHAR(200) = 'MFSQL_Release_53'
DECLARE @Process_ID INT = 5
DECLARE @SQL nvarchar(MAX)
DECLARE @Params nvarchar(MAX) = N'@Process_ID int'
DECLARE @Idoc int
DECLARE @ColumnNames NVARCHAR(MAX) = 'MFSQL_Message'
DECLARE @PropertyIDs NVARCHAR(MAX)


SELECT @objectType = mot.mfid FROM [dbo].[MFObjectType] AS [mot]
INNER JOIN [dbo].[MFClass] AS [mc]
ON mc.[MFObjectType_ID] = mot.id
 WHERE [mc].[TableName] = @MFTableName

 SET @SQL = N'UPDATE '+@MFTableName+ '
 SET [Process_ID] = @Process_ID
 WHERE 1 = 1'

 EXEC sp_executeSQL @SQL, @Params, @process_ID
-------------------------------------------------------------
-- get object ids
-------------------------------------------------------------
        DECLARE @ObjIDs NVARCHAR(MAX);
                DECLARE @VQuery NVARCHAR(4000)
               ,@Filter NVARCHAR(4000);

        
        SET @Filter = 'where  Process_ID=' + CONVERT(VARCHAR(10), @Process_id);
        
        IF (SELECT OBJECT_ID('tempdb..#TempObjIDs')) IS NOT NULL
        DROP TABLE #TempObjids;

        CREATE TABLE [#TempObjIDs]
        (
            [ObjIDS] NVARCHAR(MAX)
        );

        SET @VQuery
            = 'insert into #TempObjIDs(ObjIDS)  select STUFF(( SELECT '',''
											  , CAST([ObjID] AS VARCHAR(10))
										 FROM  ' + @MFTableName + '
										  ' + @Filter
              + '
									   FOR
										 XML PATH('''')
									   ), 1, 1, '''') ';

        EXEC (@VQuery);

        SELECT @ObjIDs = [ObjIDS]
        FROM [#TempObjIDs];
 
 SELECT @ObjIDs
 SELECT LEN([toid].[ObjIDS]) FROM [#TempObjIDs] AS [toid]

 -------------------------------------------------------------
 -- GEt property ids
 -------------------------------------------------------------
        IF (SELECT OBJECT_ID('tempdb..#TempProperty')) IS NOT NULL
        DROP TABLE #TempProperty;
         CREATE TABLE [#TempProperty]
        (
            [ID] INT IDENTITY(1, 1)
           ,[ColumnName] NVARCHAR(200)
           ,[IsValidProperty] BIT
        );

        INSERT INTO [#TempProperty]
        (
            [ColumnName]
        )
        SELECT [ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',');

        DECLARE @Counter  INT
               ,@MaxRowID INT;

        SELECT @MaxRowID = MAX([ID])
        FROM [#TempProperty];

        SET @Counter = 1;

        WHILE @Counter <= @MaxRowID
        BEGIN
            DECLARE @PropertyName NVARCHAR(200);

            SELECT @PropertyName = [ColumnName]
            FROM [#TempProperty]
            WHERE [ID] = @Counter;

            IF EXISTS
            (
                SELECT TOP 1
                       *
                FROM [dbo].[MFProperty] WITH (NOLOCK)
                WHERE [ColumnName] = @PropertyName
            )
            BEGIN
                UPDATE [#TempProperty]
                SET [IsValidProperty] = 1
                WHERE [ID] = @Counter;
            END;
            ELSE
            BEGIN
                SET @PropertyName = @PropertyName + '_ID';

                IF EXISTS
                (
                    SELECT TOP 1
                           *
                    FROM [dbo].[MFProperty] WITH (NOLOCK)
                    WHERE [ColumnName] = @PropertyName
                )
                BEGIN
                    UPDATE [#TempProperty]
                    SET [IsValidProperty] = 1
                       ,[ColumnName] = @PropertyName
                    WHERE [ID] = @Counter;
                END;
                ELSE
                BEGIN
                    DECLARE @ErrorMsg NVARCHAR(1000);

                    SELECT @ErrorMsg = 'Invalid columnName ' + @PropertyName + ' provided';

                END;
            END;

            SET @Counter = @Counter + 1;
        END;

        SET @ColumnNames = '';

        SELECT @ColumnNames = COALESCE(@ColumnNames + ',', '') + [ColumnName]
        FROM [#TempProperty];

        SELECT @PropertyIDs = COALESCE(@PropertyIDs + ',', '') + CAST([MFID] AS VARCHAR(20))
        FROM [dbo].[MFProperty] WITH (NOLOCK)
        WHERE [ColumnName] IN (
                                  SELECT [ListItem] FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',')
                              );

IF (@objids IS NOT  NULL AND @PropertyIDs IS NOT NULL)
Begin
EXEC [dbo].[spMFGetHistoryInternal] @VaultSettings = @VaultSettings -- nvarchar(4000)
                                   ,@ObjectType = @objectType    -- nvarchar(10)
                                   ,@ObjIDs = @ObjIDs        -- nvarchar(max)
                                   ,@PropertyIDs = @PropertyIDs   -- nvarchar(4000)
                                   ,@SearchString = 'update test'  -- nvarchar(4000)
                                   ,@IsFullHistory = 0 -- nvarchar(4)
                                   ,@NumberOfDays = null  -- nvarchar(4)
                                   ,@StartDate = null    -- nvarchar(20)
                                   ,@Result = @Result OUTPUT                               -- nvarchar(max)

                                   SELECT CAST(@result AS xml) AS FullHistory 

        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @Result;

          SELECT [ObjectType]
              ,[ClassID]
              ,[ObjID]
              ,[Version]
              ,[LastModifiedUTC]
              ,[LastModifiedBy_ID]
              ,[Property_ID]
              ,[Property_Value]
              ,GETDATE()
        FROM
            OPENXML(@Idoc, '/form/Object/Property', 1)
            WITH
            (
                [ObjectType] INT '../@ObjectType'
               ,[ClassID] INT '../@ClassID'
               ,[ObjID] INT '../@ObjID'
               ,[Version] INT '../@Version'
               --      , [LastModifiedUTC] NVARCHAR(30) '../@LastModifiedUTC'
               ,[LastModifiedUTC] NVARCHAR(100) '../@CheckInTimeStamp'
               ,[LastModifiedBy_ID] INT '../@LastModifiedBy_ID'
               ,[Property_ID] INT '@Property_ID'
               ,[Property_Value] NVARCHAR(300) '@Property_Value'
            );



        EXEC [sys].[sp_xml_removedocument] @Idoc;

        END
        ELSE 
        RAISERROR('invalid selection',16,1);
