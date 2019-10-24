
DECLARE @MFTableName     NVARCHAR(200) = 'MFLarge_Volume'
       ,@UpdateMethod    INT           = 1    --0=Update from SQL to MF only; 
                                              --1=Update new records from MF; 
                                              --2=initialisation 
       ,@UserId          NVARCHAR(200) = NULL --null for all user update
       ,@MFModifiedDate  DATETIME      = NULL --NULL to select all records
       ,@ObjIDs          NVARCHAR(MAX) = '15147'
       ,@Update_IDOut    INT           = NULL
       ,@ProcessBatch_ID INT           = NULL
       ,@SyncErrorFlag   BIT           = 0    -- note this parameter is auto set by the operation 
       ,@RetainDeletions BIT           = 0
       ,@Debug           SMALLINT      = 101;
DECLARE @Update_ID    INT
       ,@return_value INT = 1;

--    BEGIN TRY
--BEGIN TRANSACTION
SET NOCOUNT ON;

SET XACT_ABORT ON;

-----------------------------------------------------
--DECLARE LOCAL VARIABLE
-----------------------------------------------------
DECLARE @Id                 INT
       ,@objID              INT
       ,@ObjectIdRef        INT
       ,@ObjVersion         INT
       ,@VaultSettings      NVARCHAR(4000)
       ,@TableName          NVARCHAR(1000)
       ,@XmlOUT             NVARCHAR(MAX)
       ,@NewObjectXml       NVARCHAR(MAX)
       ,@ObjIDsForUpdate    NVARCHAR(MAX)
       ,@FullXml            XML
       ,@SynchErrorObj      NVARCHAR(MAX) --Declared new paramater
       ,@DeletedObjects     NVARCHAR(MAX) --Declared new paramater
       ,@ProcedureName      sysname        = 'spMFUpdateTable'
       ,@ProcedureStep      sysname        = 'Start'
       ,@ObjectId           INT
       ,@ClassId            INT
       ,@Table_ID           INT
       ,@ErrorInfo          NVARCHAR(MAX)
       ,@Query              NVARCHAR(MAX)
       ,@Params             NVARCHAR(MAX)
       ,@SynchErrCount      INT
       ,@ErrorInfoCount     INT
       ,@MFErrorUpdateQuery NVARCHAR(1500)
       ,@MFIDs              NVARCHAR(2500) = ''
       ,@ExternalID         NVARCHAR(200);

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
DECLARE @ParamDefinition NVARCHAR(500);
DECLARE @IsFullUpdate BIT;



-----------------------------------------------------
            --Set Object Type Id
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Object Type and Class';

            SELECT @ObjectIdRef = [MFObjectType_ID]
            FROM [dbo].[MFClass]
            WHERE [TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

            SELECT @ObjectId = [MFID]
            FROM [dbo].[MFObjectType]
            WHERE [ID] = @ObjectIdRef;



-- PROCESS FULL UPDATE FOR UPDATE METHOD 0
-------------------------------------------------------------
DECLARE @lastModifiedColumn NVARCHAR(100);
DECLARE @Count          NVARCHAR(10)
       ,@SelectQuery    NVARCHAR(MAX)
       ,@ParmDefinition NVARCHAR(500)
	   ,@XML NVARCHAR(MAX);

SELECT @lastModifiedColumn = [mp].[ColumnName]
FROM [dbo].[MFProperty] AS [mp]
WHERE [mp].[MFID] = 21; --'Last Modified'

    -----------------------------------------------------
    --Determine if any filter have been applied
    --if no filters applied then full refresh, else apply filters
    -----------------------------------------------------

    SELECT @IsFullUpdate = CASE
                               WHEN @UserId IS NULL
                                    AND @MFModifiedDate IS NULL
                                    AND @ObjIDs IS NULL THEN
                                   1
                               ELSE
                                   0
                           END;


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
        SET @SelectQuery = @SelectQuery + ' AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + '''';
    END;

    IF @Debug > 9
    BEGIN
        SELECT @ObjIDs;

        IF @Debug > 10
            SELECT *
            FROM [dbo].[fnMFSplitString](@ObjIDs, ',');
    END;

    IF (@ObjIDs IS NOT NULL)
    BEGIN
        SET @SelectQuery
            = @SelectQuery + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs + ','','',''))';
    END;

    IF @Debug > 9
    BEGIN
        SET @DebugText = @DefaultDebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

        IF @Debug > 10
            SELECT @SelectQuery AS [Select records for update];
    END;
END;

SET @ParmDefinition = N'@retvalOUT int OUTPUT';

EXEC [sys].[sp_executesql] @SelectQuery
                          ,@ParmDefinition
                          ,@retvalOUT = @Count OUTPUT;

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

    EXEC [sys].[sp_executesql] @stmt = @Query
                              ,@Param = @Params
                              ,@Classid = @ClassId;
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
DECLARE @PerformanceMeasure FLOAT;

SET @StartTime = GETDATE();

        -----------------------------------------------------
        --IF Null Creating XML with ObjectTypeID and ClassId
        -----------------------------------------------------
        IF (@FullXml IS NULL)
        BEGIN
            SET @FullXml =
            (
                SELECT @ObjectId   AS [Object/@id]
                      ,@Id         AS [Object/@sqlID]
                      ,@objID      AS [Object/@objID]
                      ,@ObjVersion AS [Object/@objVesrion]
                      ,@ExternalID AS [Object/@DisplayID] --Added for Task #988
                      ,(
                           SELECT @ClassId AS [class/@id] FOR XML PATH(''), TYPE
                       )           AS [Object]
                FOR XML PATH(''), ROOT('form')
            );
            SET @FullXml =
            (
                SELECT @FullXml.[query]('/form/*')
            );
        END;

        SET @XML = '<form>' + (CAST(@FullXml AS NVARCHAR(MAX))) + '</form>';

        --------------------------------------------------------------------
        --create XML if @UpdateMethod !=0 (0=Update from SQL to MF only)
        -----------------------------------------------------
        SET @StartTime = GETUTCDATE();

        IF (@UpdateMethod != 0)
        BEGIN
            SET @ProcedureStep = 'Xml for Process_ID = 0 ';

            DECLARE @ObjVerXML          XML
                   ,@ObjVerXMLForUpdate XML
                   ,@CreateXmlQuery     NVARCHAR(MAX);

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------
            --Create XML with All ObjVer Exists in SQL
            -----------------------------------------------------
            IF @IsFullUpdate = 1
            BEGIN
                SET @DebugText = ' Full Update';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SET @CreateXmlQuery
                    = 'SELECT @ObjVerXML = (
								SELECT ' + CAST(@ObjectId AS NVARCHAR(20))
                      + ' AS ''ObjectType/@id'' ,(
										SELECT objID ''objVers/@objectID''
											,MFVersion ''objVers/@version''
											,GUID ''objVers/@objectGUID''
										FROM [' + @MFTableName
                      + ']
										WHERE Process_ID = 0
										FOR XML PATH('''')
											,TYPE
										) AS ObjectType
								FOR XML PATH('''')
									,ROOT(''form'')
								)';

                EXEC [sys].[sp_executesql] @CreateXmlQuery
                                          ,N'@ObjVerXML XML OUTPUT'
                                          ,@ObjVerXML OUTPUT;

                DECLARE @ObjVerXmlString NVARCHAR(MAX);

                SET @ObjVerXmlString = CAST(@ObjVerXML AS NVARCHAR(MAX));

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXmlString AS [@ObjVerXmlString];
                END;
            END;

            IF @IsFullUpdate = 0
            BEGIN
                SET @ProcedureStep = ' Prepare query for filters ';
                SET @DebugText = ' Filtered Update ';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF (@SyncErrorFlag = 0)
                BEGIN
                    SET @CreateXmlQuery
                        = 'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + ']
													WHERE Process_ID = 0 ';
                END;
                ELSE
                BEGIN
                    SET @CreateXmlQuery
                        = 'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + ']
													WHERE Process_ID = 2 ';
                END;

                IF (@MFModifiedDate IS NOT NULL)
                BEGIN
                    SET @CreateXmlQuery
                        = @CreateXmlQuery + 'AND ' + QUOTENAME(@lastModifiedColumn) + ' > = '''
                          + CAST(@MFModifiedDate AS VARCHAR(MAX)) + ''' ';
                END;

                IF (@ObjIDs IS NOT NULL)
                BEGIN
                    SET @CreateXmlQuery
                        = @CreateXmlQuery + 'AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs
                          + ''','',''))';
                END;

                SET @CreateXmlQuery = @CreateXmlQuery + ' FOR XML PATH(''''),ROOT(''form''))';

                IF @Debug > 9
                    SELECT @CreateXmlQuery AS [@CreateXmlQuery];

                DECLARE @x NVARCHAR(1000);

                SET @x = N'@ObjVerXMLForUpdate XML OUTPUT';

                EXEC [sys].[sp_executesql] @CreateXmlQuery, @x, @ObjVerXMLForUpdate OUTPUT;

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                SET @ProcedureStep = 'Identify Object IDs ';

                IF @ObjIDs != ''
                BEGIN
                    SET @DebugText = 'Objids %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
                    END;

                    DECLARE @missingXML NVARCHAR(MAX); ---Bug 1098  VARCHAR(8000) to  VARCHAR(max) 
                    DECLARE @objects NVARCHAR(MAX);

                    SET @DebugText = 'Get missing objects ';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    IF ISNULL(@SyncErrorFlag, 0) = 0
                    BEGIN
                        SET @DebugText = ' Validate objects %s ';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
                        END;

                        EXEC [dbo].[spMFGetMissingobjectIds] @ObjIDs
                                                            ,@MFTableName
                                                            ,@missing = @objects OUTPUT;

                        SET @DebugText = ' Missing objects %s ';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objects);
                        END;
                    END;
                    ELSE
   
   
                    BEGIN
                        IF @SyncErrorFlag = 1
                        BEGIN
                            SET @DebugText = ' SyncFlag = 1 ';
                            SET @DebugText = @DefaultDebugText + @DebugText;

                            IF @Debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                            END;

                            SET @objects = @ObjIDs;
                        END;
                    END;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = '';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @missingXML = @objects;

                    IF @Debug > 9
                        SELECT @missingXML AS [@missingXML];

                    IF (@ObjVerXMLForUpdate IS NULL)
                    BEGIN
                        SET @ObjVerXMLForUpdate = '<form>' + CAST(@missingXML AS NVARCHAR(MAX)) + ' </form>';
                    END;
                    ELSE
                    BEGIN
                        SET @ObjVerXMLForUpdate
                            = REPLACE(CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX)), '</form>', @missingXML + '</form>');
                    END;
                END;
                ELSE
                BEGIN
                    SET @ObjVerXMLForUpdate = NULL;
                END;

                SET @ProcedureStep = 'ObjverDetails for Update';

                --select @ObjVerXMLForUpdate as '@ObjVerXMLForUpdate'
                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                DECLARE @objVerDetails_Count INT;

                SELECT @objVerDetails_Count = COUNT([o].[objectid])
                FROM
                (
                    SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
                    FROM @ObjVerXMLForUpdate.[nodes]('/form/Object') AS [t1]([c1])
                ) AS [o];

                SET @DebugText = 'Count of objects %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objVerDetails_Count);
                END;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records in ObjVerDetails for MFiles';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnValue = CAST(@objVerDetails_Count AS VARCHAR(10));
                SET @LogColumnName = 'ObjectVerDetails';

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                             ,@LogType = @LogTypeDetail
                                                                             ,@LogText = @LogTextDetail
                                                                             ,@LogStatus = @LogStatusDetail
                                                                             ,@StartTime = @StartTime
                                                                             ,@MFTableName = @MFTableName
                                                                             ,@Validation_ID = @Validation_ID
                                                                             ,@ColumnName = @LogColumnName
                                                                             ,@ColumnValue = @LogColumnValue
                                                                             ,@Update_ID = @Update_ID
                                                                             ,@LogProcedureName = @ProcedureName
                                                                             ,@LogProcedureStep = @ProcedureStep
                                                                             ,@debug = @Debug;

                SET @ObjVerXmlString = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
                SET @ObjIDsForUpdate = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
--measures

END
END


SET @PerformanceMeasure = DATEDIFF(MILLISECOND, @StartTime, GETDATE());

SELECT @PerformanceMeasure AS [Old method];

---------------------------------------start of temp table method