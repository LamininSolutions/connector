
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFAddCommentForObjects]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFAddCommentForObjects',
                                 -- nvarchar(100)
                                 @Object_Release = '3.1.5.41',
                                 -- varchar(50)
                                 @UpdateFlag = 2;
-- smallint
GO

/*
MODIFICATIONS

*/

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFAddCommentForObjects' --name of procedure
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
CREATE PROCEDURE dbo.spMFAddCommentForObjects
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE dbo.spMFAddCommentForObjects
    @MFTableName NVARCHAR(250) = 'MFPicture',
    @Process_id INT = 1,
    @Comment NVARCHAR(1000),
    @Debug SMALLINT = 0
AS
BEGIN


    BEGIN TRY
        DECLARE @Update_ID INT,
                @ProcessBatch_ID INT,
                @return_value INT = 1;


        DECLARE @Id INT,
                @UpdateMethod INT = 0,
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
                @ProcedureName sysname = 'spmfAddCommentForObjects',
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
                @ExternalID NVARCHAR(120);

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


        IF EXISTS
        (
            SELECT *
            FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
                  AND type IN ( N'U' )
        )
        BEGIN
            -----------------------------------------------------
            --GET LOGIN CREDENTIALS
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Security Variables';

            DECLARE @Username NVARCHAR(2000);
            DECLARE @VaultName NVARCHAR(2000);

            SELECT TOP 1
                   @Username = Username,
                   @VaultName = VaultName
            FROM dbo.MFVaultSettings;

            SELECT @VaultSettings = dbo.FnMFVaultSettings();

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s Vault: %s', 10, 1, @ProcedureName, @ProcedureStep, @VaultName);

                SELECT @VaultSettings;
            END;

            SET @StartTime = GETUTCDATE();
            /*
	Create ids for process start
	*/
            SET @ProcedureStep = 'Get Update_ID';

            SELECT @ProcessType = CASE
                                      WHEN @UpdateMethod = 0 THEN
                                          'UpdateMFiles'
                                      ELSE
                                          'UpdateSQL'
                                  END;

            INSERT INTO dbo.MFUpdateHistory
            (
                Username,
                VaultName,
                UpdateMethod
            )
            VALUES
            (@Username, @VaultName, -1);

            SELECT @Update_ID = @@IDENTITY;




            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText + 'ProcessBatch_ID %i: Update_ID %i';
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID, @Update_ID);
            END;

            SET @ProcedureStep = 'Start ProcessBatch';
            SET @StartTime = GETUTCDATE();
            SET @ProcessType = @ProcedureName;
            SET @LogType = 'Status';
            SET @LogStatus = 'Started';
            SET @LogText = 'Update using Update_ID: ' + CAST(@Update_ID AS VARCHAR(10));

            EXECUTE @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                                @ProcessType = @ProcessType,
                                                                @LogType = @LogType,
                                                                @LogText = @LogText,
                                                                @LogStatus = @LogStatus,
                                                                @debug = @Debug;

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText;
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -----------------------------------------------------
            --Determine if any filter have been applied
            --if no filters applied then full refresh, else apply filters
            -----------------------------------------------------
            DECLARE @IsFullUpdate BIT;


            -----------------------------------------------------
            --Convert @UserId to UNIQUEIDENTIFIER type
            -----------------------------------------------------
            --SET @UserId = CONVERT(UNIQUEIDENTIFIER, @UserId);
            -----------------------------------------------------
            --To Get Table_ID 
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Table ID';
            SET @TableName = @MFTableName;
            SET @TableName = REPLACE(@TableName, '_', ' ');

            SELECT @Table_ID = object_id
            FROM sys.objects
            WHERE name = @TableName;

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText + 'Table: %s';
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
            END;

            -----------------------------------------------------
            --Set Object Type Id
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Object Type and Class';

            SELECT @ObjectIdRef = MFObjectType_ID
            FROM dbo.MFClass
            WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

            SELECT @ObjectId = MFID
            FROM dbo.MFObjectType
            WHERE ID = @ObjectIdRef;

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText + 'ObjectType: %i';
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
            END;

            -----------------------------------------------------
            --Set class id
            -----------------------------------------------------
            SELECT @ClassId = MFID
            FROM dbo.MFClass
            WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText + 'Class: %i';
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
            END;

            SET @ProcedureStep = 'Prepare Table';
            SET @LogTypeDetail = 'Status';
            SET @LogStatusDetail = 'Start';
            SET @LogTextDetail = 'For UpdateMethod ' + CAST(@UpdateMethod AS VARCHAR(10));
            SET @LogColumnName = '';
            SET @LogColumnValue = '';

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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


            SELECT @MFIDs = @MFIDs + CAST(ISNULL(MFP.MFID, '') AS NVARCHAR(10)) + ','
            FROM INFORMATION_SCHEMA.COLUMNS CLM
                LEFT JOIN dbo.MFProperty MFP
                    ON MFP.ColumnName = CLM.COLUMN_NAME
            WHERE CLM.TABLE_NAME = @MFTableName;

            SELECT @MFIDs = LEFT(@MFIDs, LEN(@MFIDs) - 1); -- Remove last ','


            --    IF @UpdateMethod = 0 --- processing of process_ID = 1
            BEGIN

                DECLARE @Count NVARCHAR(10),
                        @SelectQuery NVARCHAR(MAX),
                        @ParmDefinition NVARCHAR(500);

                SET @SelectQuery
                    = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName + '] WHERE Process_ID = '
                      + CAST(@Process_id AS NVARCHAR(20)) + ' AND Deleted = 0';






            END;

            SET @ParmDefinition = N'@retvalOUT int OUTPUT';

            --IF @Debug > 9

            EXEC sys.sp_executesql @SelectQuery,
                                   @ParmDefinition,
                                   @retvalOUT = @Count OUTPUT;


            BEGIN
                DECLARE @ClassPropName NVARCHAR(100);
                SELECT @ClassPropName = mp.ColumnName
                FROM dbo.MFProperty AS mp
                WHERE mp.MFID = 100;

                SET @Params = N'@ClassID int';
                SET @Query
                    = N'UPDATE t
					SET t.' + @ClassPropName + ' = @ClassId
					FROM ' + QUOTENAME(@MFTableName) + ' t WHERE t.process_ID = ' + CAST(@Process_id AS NVARCHAR(20))
                      + ' AND (' + @ClassPropName + ' IS NULL or ' + @ClassPropName + '= -1) AND t.Deleted = 0';

                EXEC sys.sp_executesql @stmt = @Query,
                                       @Param = @Params,
                                       @Classid = @ClassId;
            END;






            ----------------------------------------------------------------------------------------------------------
            --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
            ----------------------------------------------------------------------------------------------------------
            --SET @StartTime = GETUTCDATE();

            IF (@Count > 0 AND @UpdateMethod != 1)
            BEGIN
                DECLARE @GetDetailsCursor AS CURSOR;
                DECLARE @CursorQuery NVARCHAR(200),
                        @vsql AS NVARCHAR(MAX),
                        @vquery AS NVARCHAR(MAX);

                --SET @ProcedureStep = 'Cursor Condition';
                -----------------------------------------------------
                --Creating Dynamic CURSOR With input Table name
                -----------------------------------------------------

                SET @vquery
                    = 'SELECT ID,ObjID,MFVersion,ExternalID from [' + @MFTableName + '] WHERE Process_ID = '
                      + CAST(@Process_id AS NVARCHAR(20)) + ' AND Deleted = 0';




                --IF ( @ObjIDs IS NOT NULL )
                --                                             BEGIN
                --                                                   SET @vquery = @vquery
                --                                                      + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString('''
                --                                                       + @ObjIDs + ','','',''))';
                --                                             END;


                SET @vsql = 'SET @cursor = cursor forward_only static FOR ' + @vquery + ' OPEN @cursor;';

                --                                      

                EXEC sys.sp_executesql @vsql,
                                       N'@cursor cursor output',
                                       @GetDetailsCursor OUTPUT;

                -- SET @ProcedureStep = 'Fetch next';

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
                        ColunmName NVARCHAR(200),
                        ColumnValue NVARCHAR(4000)
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
                              SELECT ' UNION ' + 'SELECT ''' + COLUMN_NAME + ''' as name, CONVERT(VARCHAR(max),['
                                     + COLUMN_NAME + ']) as value FROM [' + @MFTableName + '] y'
                                     + ISNULL('  WHERE ' + @TableWhereClause, '')
                              FROM INFORMATION_SCHEMA.COLUMNS
                              WHERE TABLE_NAME = @MFTableName
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
                        ColumnName VARCHAR(100)
                    );
                    INSERT INTO @ExcludeList
                    (
                        ColumnName
                    )
                    SELECT mp.ColumnName
                    FROM dbo.MFProperty AS mp
                    WHERE mp.MFID IN ( 20, 21, 23, 25 ); --Last Modified, Last Modified by, Created, Created by


                    -----------------------------------------------------
                    --Insert to values INTo temp table
                    -----------------------------------------------------
                    INSERT INTO @ColumnValuePair
                    EXEC (@Query);

                    DELETE FROM @ColumnValuePair
                    WHERE ColunmName IN (
                                            SELECT el.ColumnName FROM @ExcludeList AS el
                                        );

                    SET @ProcedureStep = 'Delete Blank Columns';



                    UPDATE cp
                    SET cp.ColumnValue = CONVERT(DATE, CAST(cp.ColumnValue AS NVARCHAR(100)))
                    FROM @ColumnValuePair cp
                        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
                            ON c.COLUMN_NAME = cp.ColunmName
                    WHERE c.DATA_TYPE = 'datetime'
                          AND cp.ColumnValue IS NOT NULL;


                    INSERT INTO @ColumnValuePair
                    (
                        ColunmName,
                        ColumnValue
                    )
                    VALUES
                    ('Comment', @Comment);

                    SET @ProcedureStep = 'Creating XML for Process_ID = 1';
                    -----------------------------------------------------
                    --Generate xml file -- 
                    -----------------------------------------------------
                    SET @XMLFile =
                    (
                        SELECT @ObjectId AS 'Object/@id',
                               @Id AS 'Object/@sqlID',
                               @objID AS 'Object/@objID',
                               @ObjVersion AS 'Object/@objVesrion',
                               @ExternalID AS 'Object/@DisplayID', --Added For Task #988



                               (
                                   SELECT
                                       (
                                           SELECT TOP 1
                                                  tmp.ColumnValue
                                           FROM @ColumnValuePair tmp
                                               INNER JOIN dbo.MFProperty mfp
                                                   ON mfp.ColumnName = tmp.ColunmName
                                           WHERE mfp.MFID = 100
                                       ) AS 'class/@id',
                                       (
                                           SELECT mfp.MFID AS 'property/@id',
                                                  (
                                                      SELECT MFTypeID FROM dbo.MFDataType WHERE ID = mfp.MFDataType_ID
                                                  ) AS 'property/@dataType',
                                                  tmp.ColumnValue AS 'property'
                                           FROM @ColumnValuePair tmp
                                               INNER JOIN dbo.MFProperty mfp
                                                   ON mfp.ColumnName = tmp.ColunmName
                                           WHERE mfp.MFID <> 100
                                                 AND tmp.ColumnValue IS NOT NULL --- excluding duplicate class


                                           FOR XML PATH(''), TYPE
                                       ) AS 'class'
                                   FOR XML PATH(''), TYPE
                               ) AS 'Object'
                        FOR XML PATH(''), ROOT('form')
                    );
                    SET @XMLFile =
                    (
                        SELECT @XMLFile.query('/form/*')
                    );



                    DELETE FROM @ColumnValuePair
                    WHERE ColunmName IS NOT NULL;



                    --------------------------------------------------------------------------------------------------


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

            SET @ProcedureStep = 'Get Full Xml';



            -----------------------------------------------------
            --IF Null Creating XML with ObjectTypeID and ClassId
            -----------------------------------------------------
            IF (@FullXml IS NULL)
            BEGIN
                SET @FullXml =
                (
                    SELECT @ObjectId AS 'Object/@id',
                           @Id AS 'Object/@sqlID',
                           @objID AS 'Object/@objID',
                           @ObjVersion AS 'Object/@objVesrion',
                           @ExternalID AS 'Object/@DisplayID', --Added for Task #988
                           (
                               SELECT @ClassId AS 'class/@id' FOR XML PATH(''), TYPE
                           ) AS 'Object'
                    FOR XML PATH(''), ROOT('form')
                );
                SET @FullXml =
                (
                    SELECT @FullXml.query('/form/*')
                );
            END;


            SET @XML = '<form>' + (CAST(@FullXml AS NVARCHAR(MAX))) + '</form>';


            UPDATE dbo.MFUpdateHistory
            SET ObjectDetails = @XML
            --,[MFUpdateHistory].[ObjectVerDetails] = @ObjVerXmlString
            WHERE Id = @Update_ID;


			-----------------------------------------------------------------
	           -- Checking module access for CLR procdure  spMFGetObjectType
            ------------------------------------------------------------------
              EXEC [dbo].[spMFCheckLicenseStatus] 
			       'spMFCreateObjectInternal'
				   ,@ProcedureName
				   ,@ProcedureStep



            --------------------------------------------------------------------
            --create XML if @UpdateMethod !=0 (0=Update from SQL to MF only)
            -----------------------------------------------------
            SET @StartTime = GETUTCDATE();

            EXECUTE @return_value = dbo.spMFCreateObjectInternal @VaultSettings,
                                                                 @XML,
                                                                 NULL,
                                                                 @MFIDs,
                                                                 0,
                                                                 NULL,
                                                                 @ObjIDsForUpdate,
                                                                 @XmlOUT OUTPUT,
                                                                 @NewObjectXml OUTPUT,
                                                                 @SynchErrorObj OUTPUT,  --Added new paramater
                                                                 @DeletedObjects OUTPUT, --Added new paramater
                                                                 @ErrorInfo OUTPUT;

            --select @XmlOUT as '@XmlOUT'
            --select @NewObjectXml as '@NewObjectXml'
            --                  select @SynchErrorObj as '@SynchErrorObj' --Added new paramater
            --                  select @DeletedObjects as '@DeletedObjects' --Added new paramater
            --                  select @ErrorInfo as '@ErrorInfo';


            -- select  @XmlOUT 
            --                  select @NewObjectXml 
            IF @Debug > 10
            BEGIN
                RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 10, 1, @ProcedureName, @ProcedureStep, @ErrorInfo);
            END;



            IF (@Update_ID > 0)
                UPDATE dbo.MFUpdateHistory
                SET NewOrUpdatedObjectVer = @XmlOUT,
                    NewOrUpdatedObjectDetails = @NewObjectXml,
                    SynchronizationError = @SynchErrorObj,
                    DeletedObjectVer = @DeletedObjects,
                    MFError = @ErrorInfo
                WHERE Id = @Update_ID;

            DECLARE @NewOrUpdatedObjectDetails_Count INT,
                    @NewOrUpdateObjectXml XML;

            SET @NewOrUpdateObjectXml = CAST(@NewObjectXml AS XML);

            SELECT @NewOrUpdatedObjectDetails_Count = COUNT(o.objectid)
            FROM
            (
                SELECT t1.c1.value('(@objectId)[1]', 'INT') objectid
                FROM @NewOrUpdateObjectXml.nodes('/form/Object') AS t1(c1)
            ) AS o;



            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'XML ObjDetails returned';
            SET @LogStatusDetail = 'Output';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = CAST(@NewOrUpdatedObjectDetails_Count AS VARCHAR(10));
            SET @LogColumnName = 'MFUpdateHistory: NewOrUpdatedObjectDetails';


            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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


            DECLARE @NewOrUpdatedObjectVer_Count INT,
                    @NewOrUpdateObjectVerXml XML;

            SET @NewOrUpdateObjectVerXml = CAST(@XmlOUT AS XML);

            SELECT @NewOrUpdatedObjectVer_Count = COUNT(o.objectid)
            FROM
            (
                SELECT t1.c1.value('(@objectId)[1]', 'INT') objectid
                FROM @NewOrUpdateObjectVerXml.nodes('/form/Object') AS t1(c1)
            ) AS o;




            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'ObjVer returned';
            SET @LogStatusDetail = 'Output';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = CAST(@NewOrUpdatedObjectVer_Count AS VARCHAR(10));
            SET @LogColumnName = 'NewOrUpdatedObjectVer';


            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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



            DECLARE @IDoc INT;

            SET @ProcedureName = 'spMFAddCommentForObjects';
            SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
            SET @StartTime = GETUTCDATE();

            CREATE TABLE #ObjVer
            (
                ID INT,
                ObjID INT,
                MFVersion INT,
                GUID NVARCHAR(100),
                FileCount INT ---- Added for task 106
            );

            DECLARE @NewXML XML;

            SET @NewXML = CAST(@XmlOUT AS XML);

            DECLARE @NewObjVerDetails_Count INT;

            SELECT @NewObjVerDetails_Count = COUNT(o.objectid)
            FROM
            (
                SELECT t1.c1.value('(@objectId)[1]', 'INT') objectid
                FROM @NewXML.nodes('/form/Object') AS t1(c1)
            ) AS o;

            INSERT INTO #ObjVer
            (
                MFVersion,
                ObjID,
                ID,
                GUID,
                FileCount
            )
            SELECT t.c.value('(@objVersion)[1]', 'INT') AS MFVersion,
                   t.c.value('(@objectId)[1]', 'INT') AS ObjID,
                   t.c.value('(@ID)[1]', 'INT') AS ID,
                   t.c.value('(@objectGUID)[1]', 'NVARCHAR(100)') AS GUID,
                   t.c.value('(@FileCount)[1]', 'INT') AS FileCount -- Added for task 106
            FROM @NewXML.nodes('/form/Object') AS t(c);

            SET @Count = @@ROWCOUNT;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 10
                    SELECT *
                    FROM #ObjVer;
            END;

            DECLARE @UpdateQuery NVARCHAR(MAX);

            SET @UpdateQuery
                = '	UPDATE ['    + @MFTableName + ']
					SET ['     + @MFTableName + '].ObjID = #ObjVer.ObjID
					,['        + @MFTableName + '].MFVersion = #ObjVer.MFVersion
					,['        + @MFTableName + '].GUID = #ObjVer.GUID
					,['        + @MFTableName
                  + '].FileCount = #ObjVer.FileCount     ---- Added for task 106
					,Process_ID = 0
					,Deleted = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE ['   + @MFTableName + '].ID = #ObjVer.ID';

            EXEC (@UpdateQuery);
            SET @ProcedureStep = 'Update Records in ' + @MFTableName + '';

            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Output';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'NewObjVerDetails';
            SET @LogColumnValue = CAST(@NewObjVerDetails_Count AS VARCHAR(10));

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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


            DROP TABLE #ObjVer;

            ----------------------------------------------------------------------------------------------------------
            --Update Process_ID to 2 when synch error occcurs--
            ----------------------------------------------------------------------------------------------------------
            SET @ProcedureStep = 'Updating MFTable with Process_ID = 2,if any synch error occurs';
            SET @StartTime = GETUTCDATE();

            ----------------------------------------------------------------------------------------------------------
            --Create an internal representation of the XML document. 
            ---------------------------------------------------------------------------------------------------------                
            CREATE TABLE #SynchErrObjVer
            (
                ID INT,
                ObjID INT,
                MFVersion INT
            );

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------
            ----Inserting the Xml details into temp Table
            -----------------------------------------------------
            DECLARE @SynchErrorXML XML;

            SET @SynchErrorXML = CAST(@SynchErrorObj AS XML);

            INSERT INTO #SynchErrObjVer
            (
                MFVersion,
                ObjID,
                ID
            )
            SELECT t.c.value('(@objVersion)[1]', 'INT') AS MFVersion,
                   t.c.value('(@objectId)[1]', 'INT') AS ObjID,
                   t.c.value('(@ID)[1]', 'INT') AS ID
            FROM @SynchErrorXML.nodes('/form/Object') AS t(c);

            SELECT @SynchErrCount = COUNT(*)
            FROM #SynchErrObjVer;

            IF @SynchErrCount > 0
            BEGIN
                IF @Debug > 9
                BEGIN
                    RAISERROR(
                                 'Proc: %s Step: %s SyncronisationErrors %i ',
                                 10,
                                 1,
                                 @ProcedureName,
                                 @ProcedureStep,
                                 @SynchErrCount
                             );

                    PRINT 'Synchronisation error';

                    IF @Debug > 10
                        SELECT *
                        FROM #SynchErrObjVer;
                END;

                SET @ProcedureStep = 'Syncronisation Errors ';
                SET @LogTypeDetail = 'User';
                SET @LogTextDetail = @ProcedureStep + ' in ' + @MFTableName + '';
                SET @LogStatusDetail = 'Error';
                SET @Validation_ID = 2;
                SET @LogColumnName = 'Count of errors';
                SET @LogColumnValue = ISNULL(CAST(@SynchErrCount AS VARCHAR(10)), 0);

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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


                -------------------------------------------------------------------------------------
                -- UPDATE THE SYNCHRONIZE ERROR
                -------------------------------------------------------------------------------------
                DECLARE @SynchErrUpdateQuery NVARCHAR(MAX);

                SET @SynchErrUpdateQuery
                    = '	UPDATE ['    + @MFTableName + ']
					SET ['                 + @MFTableName + '].ObjID = #SynchErrObjVer.ObjID	,[' + @MFTableName
                      + '].MFVersion = #SynchErrObjVer.MFVersion
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '         + CAST(@Update_ID AS VARCHAR(15))
                      + '
					FROM #SynchErrObjVer
					WHERE ['               + @MFTableName + '].ID = #SynchErrObjVer.ID';

                EXEC (@SynchErrUpdateQuery);

                ------------------------------------------------------
                -- LOGGING THE ERROR
                ------------------------------------------------------
                SELECT @ProcedureStep = 'Update MFUpdateLog for Sync error objects';

                IF @Debug > 9
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                ----------------------------------------------------------------
                --Inserting Synch Error Details into MFLog
                ----------------------------------------------------------------
                INSERT INTO dbo.MFLog
                (
                    ErrorMessage,
                    Update_ID,
                    ErrorProcedure,
                    ExternalID,
                    ProcedureStep,
                    SPName
                )
                SELECT *
                FROM
                (
                    SELECT 'Synchronization error occured while updating ObjID : ' + CAST(ObjID AS NVARCHAR(10))
                           + ' Version : ' + CAST(MFVersion AS NVARCHAR(10)) + '' AS ErrorMessage,
                           @Update_ID AS Update_ID,
                           @TableName AS ErrorProcedure,
                           '' AS ExternalID,
                           'Synchronization Error' AS ProcedureStep,
                           'spMFUpdateTable' AS SPName
                    FROM #SynchErrObjVer
                ) vl;
            END;

            DROP TABLE #SynchErrObjVer;

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            -------------------------------------------------------------
            --Logging error details
            -------------------------------------------------------------
            CREATE TABLE #ErrorInfo
            (
                ObjID INT,
                SqlID INT,
                ExternalID NVARCHAR(100),
                ErrorMessage NVARCHAR(MAX)
            );

            SELECT @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';

            DECLARE @ErrorInfoXML XML;

            SELECT @ErrorInfoXML = CAST(@ErrorInfo AS XML);

            INSERT INTO #ErrorInfo
            (
                ObjID,
                SqlID,
                ExternalID,
                ErrorMessage
            )
            SELECT t.c.value('(@objID)[1]', 'INT') AS objID,
                   t.c.value('(@sqlID)[1]', 'INT') AS SqlID,
                   t.c.value('(@externalID)[1]', 'NVARCHAR(100)') AS ExternalID,
                   t.c.value('(@ErrorMessage)[1]', 'NVARCHAR(MAX)') AS ErrorMessage
            FROM @ErrorInfoXML.nodes('/form/errorInfo') AS t(c);

            SELECT @ErrorInfoCount = COUNT(*)
            FROM #ErrorInfo;



            IF @ErrorInfoCount > 0
            BEGIN
                IF @Debug > 10
                BEGIN
                    SELECT *
                    FROM #ErrorInfo;
                END;

                SELECT @MFErrorUpdateQuery
                    = 'UPDATE [' + @MFTableName
                      + ']
									   SET Process_ID = 3
									   FROM #ErrorInfo err
									   WHERE err.SqlID = [' + @MFTableName + '].ID';

                EXEC (@MFErrorUpdateQuery);

                SET @ProcedureStep = 'M-Files Errors ';
                SET @LogTypeDetail = 'User';
                SET @LogTextDetail = @ProcedureStep + ' in ' + @MFTableName + '';
                SET @LogStatusDetail = 'Error';
                SET @Validation_ID = 3;
                SET @LogColumnName = 'Count of errors';
                SET @LogColumnValue = ISNULL(CAST(@ErrorInfoCount AS VARCHAR(10)), 0);

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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


                INSERT INTO dbo.MFLog
                (
                    ErrorMessage,
                    Update_ID,
                    ErrorProcedure,
                    ExternalID,
                    ProcedureStep,
                    SPName
                )
                SELECT 'ObjID : ' + CAST(ISNULL(ObjID, '') AS NVARCHAR(100)) + ',' + 'SQL ID : '
                       + CAST(ISNULL(SqlID, '') AS NVARCHAR(100)) + ',' + ErrorMessage AS ErrorMessage,
                       @Update_ID,
                       @TableName AS ErrorProcedure,
                       ExternalID,
                       'Error While inserting/Updating in M-Files' AS ProcedureStep,
                       'spMFUpdateTable' AS spname
                FROM #ErrorInfo;
            END;

            DROP TABLE #ErrorInfo;

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);


            SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';
            -------------------------------------------------------------------------------------
            --Update deleted column if record is deleled from M Files
            ------------------------------------------------------------------------------------               
            SET @StartTime = GETUTCDATE();

            CREATE TABLE #DeletedRecordId
            (
                ID INT
            );

            --INSERT INTO #DeletedRecordId
            DECLARE @DeletedXML XML;

            SET @DeletedXML = CAST(@DeletedObjects AS XML);

            INSERT INTO #DeletedRecordId
            (
                ID
            )
            SELECT t.c.value('(@objectID)[1]', 'INT') AS ID
            FROM @DeletedXML.nodes('/form/objVers') AS t(c);

            SET @Count = @@ROWCOUNT;

            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 10
                    SELECT *
                    FROM #DeletedRecordId;
            END;

            -------------------------------------------------------------------------------------
            --UPDATE THE DELETED RECORD 
            -------------------------------------------------------------------------------------
            DECLARE @DeletedRecordQuery NVARCHAR(MAX);

            SET @DeletedRecordQuery
                = '	UPDATE [' + @MFTableName + ']
											SET [' + @MFTableName
                  + '].Deleted = 1					
												,Process_ID = 0
												,LastModified = GETDATE()
											FROM #DeletedRecordId
											WHERE [' + @MFTableName + '].ObjID = #DeletedRecordId.ID';

            --select @DeletedRecordQuery
            EXEC (@DeletedRecordQuery);

            SET @ProcedureStep = 'Deleted records';
            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'In ' + @MFTableName + '';
            SET @LogStatusDetail = 'Output';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'Count of deletions';
            SET @LogColumnValue = ISNULL(CAST(@Count AS VARCHAR(10)), 0);

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            DROP TABLE #DeletedRecordId;

            ------------------------------------------------------------------
            SET @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));
            -------------------------------------------------------------------------------------
            -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
            -------------------------------------------------------------------------------------
            SET @StartTime = GETUTCDATE();

            IF (@NewObjectXml != '<form />')
            BEGIN
                SET @ProcedureName = 'spMFUpdateTableInternal';
                SET @ProcedureStep = 'Update property details from M-Files ';

                IF @Debug > 9
                BEGIN
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                    IF @Debug > 10
                        SELECT @NewObjectXml AS '@NewObjectXml before updateobjectinternal';
                END;

                EXEC @return_value = dbo.spMFUpdateTableInternal @MFTableName,
                                                                 @NewObjectXml,
                                                                 @Update_ID,
                                                                 @Debug = @Debug,
                                                                 @SyncErrorFlag = 0;

                IF @return_value <> 1
                    RAISERROR('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
            END;


        END;
        ELSE
        BEGIN
            SELECT 'Check the table Name Entered';
        END;

        --          SET NOCOUNT OFF;
        --COMMIT TRANSACTION
        SET @ProcedureName = 'spMFUpdateTable';
        SET @ProcedureStep = 'Set update Status';

        IF @Debug > 9
            RAISERROR(
                         'Proc: %s Step: %s ReturnValue %i ProcessCompleted ',
                         10,
                         1,
                         @ProcedureName,
                         @ProcedureStep,
                         @return_value
                     );

        SET @ProcedureStep = 'Updating Table ';
        SET @LogType = 'Status';
        SET @LogText = 'Class Table: ' + @TableName + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
        SET @LogStatus = N'Completed';

        IF @return_value = 1
        BEGIN
            UPDATE dbo.MFUpdateHistory
            SET UpdateStatus = 'completed',
                SynchronizationError = @SynchErrorXML
            WHERE Id = @Update_ID;


            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                              -- int
                                             @LogType = @LogType,
                                                              -- nvarchar(50)
                                             @LogText = @LogText,
                                                              -- nvarchar(4000)
                                             @LogStatus = @LogStatus,
                                                              -- nvarchar(50)
                                             @debug = @Debug; -- tinyint

            SET @LogTypeDetail = @LogType;
            SET @LogTextDetail = @LogText;
            SET @LogStatusDetail = @LogStatus;
            SET @Validation_ID = NULL;
            SET @LogColumnName = NULL;
            SET @LogColumnValue = NULL;

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            RETURN 1; --For More information refer Process Table
        END;
        ELSE
        BEGIN
            UPDATE dbo.MFUpdateHistory
            SET UpdateStatus = 'partial'
            WHERE Id = @Update_ID;

            SET @LogStatus = N'Partial Successful';
            SET @LogText = N'Partial Completed';

            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                             @LogText = @LogText,
                                                              -- nvarchar(4000)
                                             @LogStatus = @LogStatus,
                                                              -- nvarchar(50)
                                             @debug = @Debug; -- tinyint

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                   @Update_ID = @Update_ID,
                                                   @LogText = @LogText,
                                                   @LogType = @LogType,
                                                   @LogStatus = @LogStatus,
                                                   @StartTime = @StartTime,
                                                   @MFTableName = @MFTableName,
                                                   @ColumnName = @LogColumnName,
                                                   @ColumnValue = @LogColumnValue,
                                                   @LogProcedureName = @ProcedureName,
                                                   @LogProcedureStep = @ProcedureStep,
                                                   @debug = @Debug;

            RETURN 1; --For More information refer Process Table
        END;

        IF @SynchErrCount > 0
        BEGIN
            SET @LogStatus = N'Errors';
            SET @LogText = @ProcedureStep + 'with sycnronisation errors: ' + @TableName + ':Return Value 2 ';

            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                             @LogText = @LogText,
                                                              -- nvarchar(4000)
                                             @LogStatus = @LogStatus,
                                                              -- nvarchar(50)
                                             @debug = @Debug; -- tinyint

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                   @Update_ID = @Update_ID,
                                                   @LogText = @LogText,
                                                   @LogType = @LogType,
                                                   @LogStatus = @LogStatus,
                                                   @StartTime = @StartTime,
                                                   @MFTableName = @MFTableName,
                                                   @ColumnName = @LogColumnName,
                                                   @ColumnValue = @LogColumnValue,
                                                   @LogProcedureName = @ProcedureName,
                                                   @LogProcedureStep = @ProcedureStep,
                                                   @debug = @Debug;

            RETURN 2;
        END;
        ELSE
        BEGIN
            IF @ErrorInfoCount > 0
                SET @LogStatus = N'Partial Successful';
            SET @LogText = @LogText + ':' + @ProcedureStep + 'with M-Files errors: ' + @TableName + 'Return Value 3';

            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                              -- int
                                             @ProcessType = @ProcessType,
                                             @LogText = @LogText,
                                                              -- nvarchar(4000)
                                             @LogStatus = @LogStatus,
                                                              -- nvarchar(50)
                                             @debug = @Debug; -- tinyint

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                   @Update_ID = @Update_ID,
                                                   @LogText = @LogText,
                                                   @LogType = @LogType,
                                                   @LogStatus = @LogStatus,
                                                   @StartTime = @StartTime,
                                                   @MFTableName = @MFTableName,
                                                   @ColumnName = @LogColumnName,
                                                   @ColumnValue = @LogColumnValue,
                                                   @LogProcedureName = @ProcedureName,
                                                   @LogProcedureStep = @ProcedureStep,
                                                   @debug = @Debug;

            RETURN 3;
        END;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        SET NOCOUNT ON;

        UPDATE dbo.MFUpdateHistory
        SET UpdateStatus = 'failed'
        WHERE Id = @Update_ID;

        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ProcedureStep,
            ErrorState,
            ErrorSeverity,
            Update_ID,
            ErrorLine
        )
        VALUES
        ('spMFUpdateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
         ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

        IF @Debug > 9
        BEGIN
            SELECT ERROR_NUMBER() AS ErrorNumber,
                   ERROR_MESSAGE() AS ErrorMessage,
                   ERROR_PROCEDURE() AS ErrorProcedure,
                   @ProcedureStep AS ProcedureStep,
                   ERROR_STATE() AS ErrorState,
                   ERROR_SEVERITY() AS ErrorSeverity,
                   ERROR_LINE() AS ErrorLine;
        END;

        SET NOCOUNT OFF;

        RETURN -1; --For More information refer Process Table
    END CATCH;
END;





