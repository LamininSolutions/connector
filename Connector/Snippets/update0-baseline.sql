  
  DECLARE
  @MFTableName NVARCHAR(200) = 'MFLarge_Volume',
    @UpdateMethod INT = 1,               --0=Update from SQL to MF only; 
                                     --1=Update new records from MF; 
                                     --2=initialisation 
    @UserId NVARCHAR(200) = NULL,    --null for all user update
    @MFModifiedDate DATETIME = NULL, --NULL to select all records
    @ObjIDs NVARCHAR(MAX) = NULL,
    @Update_IDOut INT = NULL ,
    @ProcessBatch_ID INT = NULL ,
    @SyncErrorFlag BIT = 0,          -- note this parameter is auto set by the operation 
    @RetainDeletions BIT = 0,
    @Debug SMALLINT = 101


	DECLARE @Update_ID INT,
            @return_value INT = 1;

--    BEGIN TRY
        --BEGIN TRANSACTION
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        -----------------------------------------------------
        --DECLARE LOCAL VARIABLE
        -----------------------------------------------------
        DECLARE @Id INT,
                @objID INT,
                @ObjectIdRef INT,
                @ObjVersion INT,
                @VaultSettings NVARCHAR(4000),
                @TableName NVARCHAR(1000),
                @XmlOUT NVARCHAR(MAX),
                @NewObjectXml NVARCHAR(MAX),
                @ObjIDsForUpdate NVARCHAR(MAX),
                @FullXml XML,
                @SynchErrorObj NVARCHAR(MAX),  --Declared new paramater
                @DeletedObjects NVARCHAR(MAX), --Declared new paramater
                @ProcedureName sysname = 'spMFUpdateTable',
                @ProcedureStep sysname = 'Start',
                @ObjectId INT,
                @ClassId INT,
                @Table_ID INT,
                @ErrorInfo NVARCHAR(MAX),
                @Query NVARCHAR(MAX),
                @Params NVARCHAR(MAX),
                @SynchErrCount INT,
                @ErrorInfoCount INT,
                @MFErrorUpdateQuery NVARCHAR(1500),
                @MFIDs NVARCHAR(2500) = '',
                @ExternalID NVARCHAR(200);

        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
        DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = '';
        DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
        DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
        DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
        DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
        DECLARE @ProcessType NVARCHAR(50);
        DECLARE @LogType AS NVARCHAR(50) = 'Status';
        DECLARE @LogText AS NVARCHAR(4000) = '';
        DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
        DECLARE @Status AS NVARCHAR(128) = NULL;
        DECLARE @Validation_ID INT = NULL;
        DECLARE @StartTime AS DATETIME;
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;

  DECLARE @IsFullUpdate BIT;
            SELECT @IsFullUpdate = CASE
                                       WHEN @UserId IS NULL
                                            AND @MFModifiedDate IS NULL
                                            AND @ObjIDs IS NULL THEN
                                           1
                                       ELSE
                                           0
                                   END;

          -- PROCESS FULL UPDATE FOR UPDATE METHOD 0
                -------------------------------------------------------------
                DECLARE @lastModifiedColumn NVARCHAR(100);

                DECLARE @Count NVARCHAR(10),
                        @SelectQuery NVARCHAR(MAX),
                        @ParmDefinition NVARCHAR(500);
    
                SELECT @lastModifiedColumn = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [mp].[MFID] = 21; --'Last Modified'


                IF @IsFullUpdate = 0
                BEGIN

                    SET @ProcedureStep = 'Filter Records for process_ID 1';

                    IF (@MFModifiedDate IS NOT NULL)
                    BEGIN
                        SET @SelectQuery
                            = @SelectQuery + ' AND ' + QUOTENAME(@lastModifiedColumn) + ' > = '''
                              + CONVERT(NVARCHAR(50), @MFModifiedDate) + '''';
                    END;

                    IF (@UserId IS NOT NULL)
                    BEGIN
                        SET @SelectQuery
                            = @SelectQuery + ' AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + '''';
                    END;

                    --IF @Debug > 9
                    --   BEGIN
                    --         SELECT @ObjIDs;
                    --         IF @Debug > 10
                    --            SELECT  *
                    --            FROM    [dbo].[fnMFSplitString](@ObjIDs, ',');
                    --   END;

                    IF (@ObjIDs IS NOT NULL)
                    BEGIN
                        SET @SelectQuery
                            = @SelectQuery + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs
                              + ','','',''))';
                    END;

                END;


                SET @ParmDefinition = N'@retvalOUT int OUTPUT';

                IF @Debug > 9
                BEGIN
                    SET @DebugText = @DefaultDebugText;
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                    IF @Debug > 10
                        SELECT @SelectQuery AS [Select records for update];
                END;

                EXEC [sys].[sp_executesql] @SelectQuery,
                                           @ParmDefinition,
                                           @retvalOUT = @Count OUTPUT;


                BEGIN
                    DECLARE @ClassPropName NVARCHAR(100);
                    SELECT @ClassPropName = [mp].[ColumnName]
                    FROM [dbo].[MFProperty] AS [mp]
                    WHERE [mp].[MFID] = 100;

                    SET @Params = N'@ClassID int';
                    SET @Query
                        = N'UPDATE t
					SET t.' + @ClassPropName + ' = @ClassId
					FROM ' + QUOTENAME(@MFTableName) + ' t WHERE t.process_ID = 1 AND (' + @ClassPropName
                          + ' IS NULL or ' + @ClassPropName + '= -1) AND t.Deleted != 1';

                    EXEC [sys].[sp_executesql] @stmt = @Query,
                                               @Param = @Params,
                                               @Classid = @ClassId;
                END;

/*
                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'Count of process_ID 1 records ' + CAST(@Count AS NVARCHAR(256));
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'process_ID 1';
                SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                                                                              @LogType = @LogTypeDetail,
                                                                              @LogText = @LogTextDetail,
                                                                              @LogStatus = @LogStatusDetail,
                                                                              @StartTime = @StartTime,
                                                                              @MFTableName = @MFTableName,
                                                                              @Validation_ID = @Validation_ID,
                                                                              @ColumnName = @LogColumnName,
                                                                              @ColumnValue = @LogColumnValue,
                                                                              @Update_ID = @Update_ID,
                                                                              @LogProcedureName = @ProcedureName,
                                                                              @LogProcedureStep = @ProcedureStep,
                                                                              @debug = @Debug;

																			  */

               ----------------------------------------------------------------------------------------------------------
                --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
                ----------------------------------------------------------------------------------------------------------
                --SET @StartTime = GETUTCDATE();

                --SET @DebugText = 'Count of records i%';
                --SET @DebugText = @DefaultDebugText + @DebugText;
                --SET @ProcedureStep = 'Start cursor Processing UpdateMethod 0';

                --IF @Debug > 0
                --BEGIN
                --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                --END;


                --IF (@Count > '0' AND @UpdateMethod != 1)
                BEGIN
                    DECLARE @GetDetailsCursor AS CURSOR;
                    DECLARE @CursorQuery NVARCHAR(200),
                            @vsql AS NVARCHAR(MAX),
                            @vquery AS NVARCHAR(MAX);

                    SET @ProcedureStep = 'Cursor Condition';
                    -----------------------------------------------------
                    --Creating Dynamic CURSOR With input Table name
                    -----------------------------------------------------
                    IF @SyncErrorFlag = 1
                    BEGIN
                        SET @vquery
                            = 'SELECT ID,ObjID,MFVersion,ExternalID from [' + @MFTableName
                              + '] WHERE Process_ID = 2 AND Deleted != 1';
                    END;
                    ELSE
                    BEGIN
                        SET @vquery
                            = 'SELECT ID,ObjID,MFVersion,ExternalID from [' + @MFTableName
                              + '] WHERE Process_ID = 1 AND Deleted != 1';
                    END;


                    IF @IsFullUpdate = 0
                    BEGIN

                        IF (@UserId IS NOT NULL)
                        BEGIN
                            SET @vquery = @vquery + 'AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + '''';
                        END;

                        IF (@MFModifiedDate IS NOT NULL)
                        BEGIN
                            SET @vquery
                                = @vquery + ' AND ' + QUOTENAME(@lastModifiedColumn) + ' > = '''
                                  + CONVERT(NVARCHAR(50), @MFModifiedDate) + '''';
                        END;

                        IF (@ObjIDs IS NOT NULL)
                        BEGIN
                            SET @vquery
                                = @vquery + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs
                                  + ','','',''))';
                        END;
                    END;


                    SET @vsql = 'SET @cursor = cursor forward_only static FOR ' + @vquery + ' OPEN @cursor;';

                    IF @Debug > 9
                    BEGIN
                        RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
                        IF @Debug > 10
                            SELECT 'Cursor Condition: ' + CAST(@vquery AS NVARCHAR(4000));
                    END;

                    EXEC [sys].[sp_executesql] @vsql,
                                               N'@cursor cursor output',
                                               @GetDetailsCursor OUTPUT;

                    SET @ProcedureStep = 'Fetch next';

                    -----------------------------------------------------
                    --CURSOR
                    -----------------------------------------------------
                    FETCH NEXT FROM @GetDetailsCursor
                    INTO @Id,
                         @objID,
                         @ObjVersion,
                         @ExternalID;

                    WHILE (@@FETCH_STATUS = 0)
                    BEGIN
                        DECLARE @ColumnValuePair TABLE
                        (
                            [ColunmName] NVARCHAR(200),
                            [ColumnValue] NVARCHAR(4000),
                            [Required] BIT ---Added for checking Required property for table
                        );
                        DECLARE @TableWhereClause VARCHAR(1000),
                                @tempTableName VARCHAR(1000),
                                @XMLFile XML;

                        SET @ProcedureStep = 'Convert Values to Column Value Table';
                        SET @TableWhereClause = 'y.ID=' + CONVERT(NVARCHAR(100), @Id);

                        ----------------------------------------------------------------------------------------------------------
                        --Generate query to get column values as row value
                        ----------------------------------------------------------------------------------------------------------
                        SELECT @Query
                            = STUFF(
                              (
                                  SELECT CASE
                                             WHEN [DATA_TYPE] = 'Float' THEN
                                                 ' UNION ' + 'SELECT ''' + [COLUMN_NAME]
                                                 + ''' as name,  CONVERT(VARCHAR(max), cast([y].[' + [COLUMN_NAME]
                                                 + '] as MONEY),2 ) as value, 0  as Required FROM [' + @MFTableName
                                                 + '] y' + ISNULL('  WHERE ' + @TableWhereClause, '')
                                             ELSE
                                                 ' UNION ' + 'SELECT ''' + [COLUMN_NAME]
                                                 + ''' as name,  CONVERT(VARCHAR(max)  ,[' + [COLUMN_NAME]
                                                 + '] ) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                                 + ISNULL('  WHERE ' + @TableWhereClause, '')
                                         END
                                  --SELECT ' UNION ' + 'SELECT ''' + COLUMN_NAME + ''' as name, CONVERT(VARCHAR(max),['
                                  --       + COLUMN_NAME + ']) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                  --       + ISNULL('  WHERE ' + @TableWhereClause, '')
                                  FROM [INFORMATION_SCHEMA].[COLUMNS]
                                  WHERE [TABLE_NAME] = @MFTableName
                                  FOR XML PATH('')
                              ),
                              1,
                              7,
                              ''
                                   );
                        -----------------------------------------------------
                        --List of columns to exclude
                        -----------------------------------------------------
                        DECLARE @ExcludeList AS TABLE
                        (
                            [ColumnName] VARCHAR(100)
                        );
                        INSERT INTO @ExcludeList
                        (
                            [ColumnName]
                        )
                        SELECT [mp].[ColumnName]
                        FROM [dbo].[MFProperty] AS [mp]
                        WHERE [mp].[MFID] IN ( 20, 21, 23, 25 ); --Last Modified, Last Modified by, Created, Created by


                        -----------------------------------------------------
                        --Insert to values INTo temp table
                        -----------------------------------------------------
                        INSERT INTO @ColumnValuePair
                        EXEC (@Query);

                        DELETE FROM @ColumnValuePair
                        WHERE [ColunmName] IN (
                                                  SELECT [el].[ColumnName] FROM @ExcludeList AS [el]
                                              );


                        ----------------------	 Add for checking Required property--------------------------------------------

                        UPDATE [CVP]
                        SET [CVP].[Required] = [CP].[Required]
                        FROM @ColumnValuePair [CVP]
                            INNER JOIN [dbo].[MFProperty] [P]
                                ON [CVP].[ColunmName] = [P].[ColumnName]
                            INNER JOIN [dbo].[MFClassProperty] [CP]
                                ON [P].[ID] = [CP].[MFProperty_ID]
                            INNER JOIN [dbo].[MFClass] [C]
                                ON [CP].[MFClass_ID] = [C].[ID]
                        WHERE [C].[TableName] = @TableName;



                        UPDATE @ColumnValuePair
                        SET [ColumnValue] = 'ZZZ'
                        WHERE [Required] = 1
                              AND [ColumnValue] IS NULL;

                        ------------------	 Add for checking Required property------------------------------------
                        SET @ProcedureStep = 'Delete Blank Columns';

                        --DELETE FROM @ColumnValuePair
                        --WHERE  ColumnValue IS NULL

                        UPDATE [cp]
                        SET [cp].[ColumnValue] = CONVERT(DATE, CAST([cp].[ColumnValue] AS NVARCHAR(100)))
                        FROM @ColumnValuePair AS [cp]
                            INNER JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                                ON [c].[COLUMN_NAME] = [cp].[ColunmName]
                        WHERE [c].[DATA_TYPE] = 'datetime'
                              AND [cp].[ColumnValue] IS NOT NULL;


                        SET @ProcedureStep = 'Creating XML for Process_ID = 1';
                        -----------------------------------------------------
                        --Generate xml file -- 
                        -----------------------------------------------------
                        SET @XMLFile =
                        (
                            SELECT @ObjectId AS [Object/@id],
                                   @Id AS [Object/@sqlID],
                                   @objID AS [Object/@objID],
                                   @ObjVersion AS [Object/@objVesrion],
                                   @ExternalID AS [Object/@DisplayID], --Added For Task #988
                                                                       --( SELECT
                                                                       --  @ClassId AS 'class/@id' ,
                                   (
                                       SELECT
                                           (
                                               SELECT TOP 1
                                                      [tmp].[ColumnValue]
                                               FROM @ColumnValuePair AS [tmp]
                                                   INNER JOIN [dbo].[MFProperty] AS [mfp]
                                                       ON [mfp].[ColumnName] = [tmp].[ColunmName]
                                               WHERE [mfp].[MFID] = 100
                                           ) AS [class/@id],
                                           (
                                               SELECT [mfp].[MFID] AS [property/@id],
                                                      (
                                                          SELECT [MFTypeID]
                                                          FROM [dbo].[MFDataType]
                                                          WHERE [ID] = [mfp].[MFDataType_ID]
                                                      ) AS [property/@dataType],
                                                      CASE
                                                          WHEN [tmp].[ColumnValue] = 'ZZZ' THEN
                                                              NULL
                                                          ELSE
                                                              [tmp].[ColumnValue]
                                                      END AS 'property' ----Added case statement for checking Required property
                                               FROM @ColumnValuePair AS [tmp]
                                                   INNER JOIN [dbo].[MFProperty] AS [mfp]
                                                       ON [mfp].[ColumnName] = [tmp].[ColunmName]
                                               WHERE [mfp].[MFID] <> 100
                                                     AND [tmp].[ColumnValue] IS NOT NULL --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                               FOR XML PATH(''), TYPE
                                           ) AS [class]
                                       FOR XML PATH(''), TYPE
                                   ) AS [Object]
                            FOR XML PATH(''), ROOT('form')
                        );
                        SET @XMLFile =
                        (
                            SELECT @XMLFile.[query]('/form/*')
                        );




                        IF @Debug > 10
                            SELECT 'ColumnValuePair' AS [ColumnValuePair],
                                   *
                            FROM @ColumnValuePair AS [cvp];

                        DELETE FROM @ColumnValuePair
                        WHERE [ColunmName] IS NOT NULL;



                        --------------------------------------------------------------------------------------------------
                        IF @Debug > 10
                            SELECT @XMLFile AS [@XMLFile];

                        SET @FullXml
                            = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

                        FETCH NEXT FROM @GetDetailsCursor
                        INTO @Id,
                             @objID,
                             @ObjVersion,
                             @ExternalID;
                    END;

                    CLOSE @GetDetailsCursor;

                    DEALLOCATE @GetDetailsCursor;
                END;

                DECLARE @XML NVARCHAR(MAX);

				SELECT @XML

                SET @ProcedureStep = 'Get Full Xml';

                IF @Debug > 9
				
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep)


/*

                --Count records for ProcessBatchDetail
                SET @ParmDefinition = N'@Count int output';
                SET @Query = N'
					SELECT @Count = COUNT(*) FROM ' + @MFTableName + ' WHERE process_ID = 1';

                EXEC [sys].[sp_executesql] @stmt = @Query,
                                           @param = @ParmDefinition,
                                           @Count = @Count OUTPUT;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records for Updated method 0 ';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'process_ID = 1';
                SET @LogColumnValue = CAST(@Count AS VARCHAR(5));

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                                                                              @LogType = @LogTypeDetail,
                                                                              @LogText = @LogTextDetail,
                                                                              @LogStatus = @LogStatusDetail,
                                                                              @StartTime = @StartTime,
                                                                              @MFTableName = @MFTableName,
                                                                              @Validation_ID = @Validation_ID,
                                                                              @ColumnName = @LogColumnName,
                                                                              @ColumnValue = @LogColumnValue,
                                                                              @Update_ID = @Update_ID,
                                                                              @LogProcedureName = @ProcedureName,
                                                                              @LogProcedureStep = @ProcedureStep,
                                                                              @debug = @Debug;

																			  */
    

