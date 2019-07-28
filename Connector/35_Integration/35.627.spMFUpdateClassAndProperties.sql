PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateClassAndProperties]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateClassAndProperties' -- nvarchar(100)
                                    ,@Object_Release = '3.1.4.41'                  -- varchar(50)
                                    ,@UpdateFlag = 2;                              -- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 01-07-2015  DEV 2	   error tracing logic updated
  ** 01-07-2015  Dev 2	   Skip the object failed to update in M-Files
  ** 02-07-2015  Dev 2	   Bug Fixed : Adding New Property
  ** 02-07-2015  Dev 2	   @PropertyIDs can be property ID or ColumnName
  ** 18-07-2015  Dev 2	   New parameter add in spMFCreateObjectInternal
  2016-8-22		LC			Update settings index
  ** 21-09-2016 Dev Team2   Removed @Username, @Password, @NetworkAddress,@VaultName and fetch default vault setting as commo separated in @VaultSettings
                            Parameter.
2017-7-25		lc			Replace Settings with MFVaultSettings for getting username and vaultname
2017-11-23		lc			Localization of properties
2017-12-20		LC			Set a default value for propertids and propertyValues; add parameters for UpdateID, and ProcessBatchID, Change naming conversion of Column related parameters, use MFUpdateTAble to process object in new class.
2018-04-04      Dev 2       Added License module validation code.
2018-04-22		AC			REsolve issue with "Conversion failed when converting the nvarchar value 'DELETE FROM {} WHERE OBJId = {} AND ' to data type int 
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateClassAndProperties' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateClassAndProperties]
AS
SELECT 'created, but not implemented yet.'; --just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateClassAndProperties]
(
    @MFTableName NVARCHAR(128)
   ,@ObjectID INT
   ,@NewClassId INT = NULL
   ,@ColumnNames NVARCHAR(1000) = NULL
   ,@ColumnValues NVARCHAR(1000) = NULL
   ,@Update_IDOUT INT = NULL OUTPUT
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0 -- debug will detail all the stages and results
)
AS
/*
USAGE

EXEC [dbo].[spMFUpdateClassAndProperties] @MFTableName = N'MFOtherHrdocument', -- nvarchar(128)
    @ObjectID = 71, -- int
    @NewClassId = 1, -- int
    @ColumnNames = N'Name_or_Title', -- nvarchar(100)
    @ColumnValues = N'Area map of chicago.jpg', -- nvarchar(1000)
    @Debug = 0 -- smallint

*/

/*******************************************************************************
  ** Desc:  The purpose of this procedure is to Change the class and update any property  of an object
  **  
  ** Version: 1.0.0.6
  **
  ** Author:			Thejus T V
  ** Date:				27-03-2015
 
  ******************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Change Class and Properties');

-------------------------------------------------------------
-- CONSTATNS: MFSQL Global 
-------------------------------------------------------------
DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
DECLARE @Process_ID_1_Update TINYINT = 1;
DECLARE @Process_ID_6_ObjIDs TINYINT = 6; --marks records for refresh from M-Files by objID vs. in bulk
DECLARE @Process_ID_9_BatchUpdate TINYINT = 9; --marks records previously set as 1 to 9 and update in batches of 250
DECLARE @Process_ID_Delete_ObjIDs INT = -1; --marks records for deletion
DECLARE @Process_ID_2_SyncError TINYINT = 2;
DECLARE @ProcessBatchSize INT = 250;

-------------------------------------------------------------
-- VARIABLES: MFSQL Processing
-------------------------------------------------------------
DECLARE @Update_ID INT;
DECLARE @MFLastModified DATETIME;
DECLARE @Validation_ID INT;

-------------------------------------------------------------
-- VARIABLES: T-SQL Processing
-------------------------------------------------------------
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT = 0;
DECLARE @error AS INT = 0;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFUpdateClassAndProperties';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = @DefaultDebugText;
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = 'Status';
DECLARE @LogText AS NVARCHAR(4000) = '';
DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
DECLARE @count INT = 0;
DECLARE @Now AS DATETIME = GETDATE();
DECLARE @StartTime AS DATETIME = GETUTCDATE();
DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

-------------------------------------------------------------
-- VARIABLES: DYNAMIC SQL
-------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @sqlParam NVARCHAR(MAX) = N'';

-------------------------------------------------------------
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = 'Start Logging';
SET @LogText = 'Processing ' + @ProcedureName;

EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                    ,@ProcessType = @ProcessType
                                    ,@LogType = N'Status'
                                    ,@LogText = @LogText
                                    ,@LogStatus = N'In Progress'
                                    ,@debug = @Debug;

EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                          ,@LogType = N'Debug'
                                          ,@LogText = @ProcessType
                                          ,@LogStatus = N'Started'
                                          ,@StartTime = @StartTime
                                          ,@MFTableName = @MFTableName
                                          ,@Validation_ID = @Validation_ID
                                          ,@ColumnName = NULL
                                          ,@ColumnValue = NULL
                                          ,@Update_ID = @Update_ID
                                          ,@LogProcedureName = @ProcedureName
                                          ,@LogProcedureStep = @ProcedureStep
                                          ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
                                          ,@debug = 0;

BEGIN TRY
    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    ------------------------------------------------------
    -- DEFINE CONSTANTS
    ------------------------------------------------------
    DECLARE @ErrStep VARCHAR(255)
           ,@Output  NVARCHAR(MAX);
    ------------------------------------------------------
    -- GET CLASS VARIABLES
    ------------------------------------------------------
    DECLARE @Id                  INT
           ,@objID               INT
           ,@ObjectIdRef         INT
           ,@ObjVersion          INT
           ,@VaultSettings       NVARCHAR(4000)
           ,@TableName           NVARCHAR(1000)
           ,@XmlOUT              NVARCHAR(MAX)
           ,@NewObjectXml        NVARCHAR(MAX)
           ,@FullXml             XML
           ,@SynchErrorObj       NVARCHAR(MAX) --Declared new paramater
           ,@DeletedObjects      NVARCHAR(MAX) --Declared new paramater
           ,@TABLE_ID            INT
           ,@RowExistQuery       NVARCHAR(100)
           ,@Definition          NVARCHAR(100)
           ,@ObjectTypeId        INT
           ,@ClassId             INT
           ,@Responce            NVARCHAR(MAX)
           ,@TableWhereClause    VARCHAR(1000)
           ,@Query               VARCHAR(MAX)
           ,@tempTableName       VARCHAR(1000)
           ,@XMLFile             XML
           ,@RecordDetailsQuery  NVARCHAR(500)
           ,@ObjIdOut            NVARCHAR(50)
           ,@ObjVerOut           NVARCHAR(50)
           ,@XML                 NVARCHAR(MAX)
           ,@ObjVerXML           XML
           ,@CreateXmlQuery      NVARCHAR(MAX)
           ,@SynchErrUpdateQuery NVARCHAR(MAX)
           ,@ParmDefinition      NVARCHAR(500)
           ,@UpdateQuery         NVARCHAR(1000)
           ,@NewXML              XML
           ,@ErrorInfo           NVARCHAR(MAX)
           ,@SynchErrCount       INT
           ,@ErrorInfoCount      INT
           ,@MFErrorUpdateQuery  NVARCHAR(1500)
           ,@MFIDs               NVARCHAR(2500) = '';

    SET @ProcedureStep = 'Table Exists';

    IF EXISTS
    (
        SELECT *
        FROM [sys].[objects]
        WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND [type] IN ( N'U' )
    )
    BEGIN
        SELECT @ProcedureStep = 'Get Security Variables';

        ------------------------------------------------------
        -- GET LOGIN CREDENTIALS
        ------------------------------------------------------		
        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        IF @Debug > 0
        BEGIN
            SELECT @VaultSettings;
        END;

        ------------------------------------------------------
        -- Does Objid exsit in source table
        ------------------------------------------------------			
        SET @ProcedureStep = 'Check Objid exists';

        SELECT @RowExistQuery
            = 'SELECT @retvalOUT  = COUNT(ID) FROM ' + @MFTableName + ' WHERE objID ='
              + CAST(@ObjectID AS NVARCHAR(10));

        SELECT @Definition = N'@retvalOUT int OUTPUT';

        EXEC [sp_executesql] @RowExistQuery
                            ,@Definition
                            ,@retvalOUT = @count OUTPUT;

        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Check ObjectID';
        SET @LogTextDetail = 'Objid: ' + CAST(@ObjectID AS VARCHAR(10));
        SET @LogColumnName = 'Objects';
        SET @LogColumnValue = CAST(@count AS VARCHAR(5));

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

        RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

        IF (@count = 1)
        BEGIN --object exists

            ------------------------------------------------------
            --To Get Table Name
            ------------------------------------------------------
            SELECT @ProcedureStep = 'Reset Table name';

            SELECT @TableName = @MFTableName;

            SELECT @TableName = REPLACE(@TableName, '_', ' ');

            SELECT @TABLE_ID = [object_id]
            FROM [sys].[objects]
            WHERE [name] = @TableName;

            IF @Debug > 0
            BEGIN
                SELECT @TableName AS [TableName of class];

                RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);
            END;

            ------------------------------------------------------
            --Set Object Type Id
            ------------------------------------------------------
            SELECT @ProcedureStep = 'Get Object Type and Class';

            -------------------------------------------------------------
            -- Is class change
            -------------------------------------------------------------
            SET @ProcedureStep = 'Class or Columname exist';

            IF @ClassId IS NOT NULL
               OR @ColumnNames IS NOT NULL
            BEGIN

                ------------------------------------------------------
                --Set class id
                ------------------------------------------------------
                SELECT @ObjectTypeId = [mo].[MFID]
                      ,@ClassId      = ISNULL(@NewClassId, [mc].[MFID])
                FROM [dbo].[MFClass]                AS [mc]
                    INNER JOIN [dbo].[MFObjectType] AS [mo]
                        ON [mc].[MFObjectType_ID] = [mo].[ID]
                WHERE [mc].[TableName] = @MFTableName;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                    SELECT @ObjectTypeId AS [Object Type]
                          ,@ClassId      AS [Class];
                END;

-------------------------------------------------------------
-- Update object from MF
-------------------------------------------------------------
DECLARE @objids NVARCHAR(20)
SET @objids = cast(@ObjectID as NVARCHAR(20))
EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName
                            ,@UpdateMethod = @UpdateMethod_1_MFilesToMFSQL                           
                            ,@ObjIDs = @objids
                            ,@Update_IDOut = @Update_IDOut OUTPUT
                            ,@ProcessBatch_ID = @ProcessBatch_ID 
                            ,@Debug = @Debug

-------------------------------------------------------------
-- 
-------------------------------------------------------------

                DECLARE @ColumnValuePair TABLE
                (
                    [ColumnName] NVARCHAR(1000)
                   ,[ColumnValue] NVARCHAR(1000)
                );

                SELECT @ProcedureStep = 'Convert Values to Column Value Table';

                SELECT @TableWhereClause = 'y.ObjID=' + CONVERT(NVARCHAR(50), @ObjectID);

                ------------------------------------------------------
                --Retieving the object details
                ------------------------------------------------------
                SELECT @RecordDetailsQuery
                    = 'SELECT @objID = [OBJID] ,@ObjVersion = [MFVersion] FROM ' + @MFTableName + ' WHERE [objID] = '
                      + CAST(@ObjectID AS NVARCHAR(20)) + '';

                SELECT @ObjIdOut = N'@objID int OUTPUT,@ObjVersion int OUTPUT';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                    SELECT @RecordDetailsQuery AS [RecordDetailsQuery];
                END;

                EXEC [sp_executesql] @RecordDetailsQuery
                                    ,@ObjIdOut
                                    ,@objID = @objID OUTPUT
                                    ,@ObjVersion = @ObjVersion OUTPUT;

                ---------------------------------------------------------------------------
                ----Generate query to get column values as row value
                --------------------------------------------------------------------------- 
                SET @ProcedureStep = 'Generate Query';

                SELECT @Query
                    = STUFF(
                      (
                          SELECT ' UNION ' + 'SELECT ''' + [COLUMN_NAME] + ''' as name, CONVERT(VARCHAR(max),['
                                 + [COLUMN_NAME] + ']) as value FROM ' + @MFTableName + ' y'
                                 + ISNULL('  WHERE ' + @TableWhereClause, '')
                          FROM [INFORMATION_SCHEMA].[COLUMNS]
                          WHERE [TABLE_NAME] = @MFTableName
                          FOR XML PATH('')
                      )
                     ,1
                     ,7
                     ,''
                           );

                ------------------------------------------------------
                ----Insert to values INTo temp table
                ------------------------------------------------------
                INSERT INTO @ColumnValuePair
                EXEC (@Query);

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                    SELECT *
                    FROM @ColumnValuePair AS [cvp];
                END;

                SELECT @ProcedureStep = 'Add new columns';

                ------------------------------------------------------
                -- CONVERTING COMMA SEPARATED VALUES INTO TABLE
                ------------------------------------------------------
                DECLARE @NewPropertyValues_Table TABLE
                (
                    [ColumnName] NVARCHAR(1000)
                   ,[ColumnValue] NVARCHAR(1000)
                );

                ----------------------------------------------------------
                -- INSERT THE COMMA SEPARATED VALUES INTO TABLE
                ----------------------------------------------------------
                INSERT INTO @NewPropertyValues_Table
                SELECT [cvp].[PairColumn1]
                      ,[cvp].[PairColumn2]
                FROM [dbo].[fnMFSplitPairedStrings](@ColumnNames, @ColumnValues, ',', ';') AS [cvp];

              

                --UPDATE @NewPropertyValues_Table
                --SET [ColumnName] = [mfp].[MFID]
                --FROM @NewPropertyValues_Table AS [new]
                --    INNER JOIN [MFProperty]   AS [mfp]
                --        ON [mfp].[ColumnName] = [new].[ColumnName];

                --UPDATE @NewPropertyValues_Table
                --SET [ColumnName] = [mfp].[ColumnName]
                --FROM @NewPropertyValues_Table AS [new]
                --    INNER JOIN [MFProperty]   AS [mfp]
                --        ON [mfp].[MFID] = [new].[ColumnName];

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                    SELECT *
                    FROM @NewPropertyValues_Table;
                END;

                SELECT @ProcedureStep = 'Inserting values from @NewPropertyValues_Table into @ColumnValuePair';

                --------------------------------------------------------
                --INSERT THE NEW PROPERTY DETAILS
                --------------------------------------------------------
                UPDATE [Clm]
                SET [Clm].[ColumnValue] = [New].[ColumnValue]
                FROM @NewPropertyValues_Table   AS [New]
                    INNER JOIN @ColumnValuePair AS [Clm]
                        ON [Clm].[ColumnName] = [New].[ColumnName];

                INSERT INTO @ColumnValuePair
                SELECT [ColumnName]
                      ,[ColumnValue]
                FROM @NewPropertyValues_Table
                WHERE [ColumnName] NOT IN (
                                              SELECT [ColumnName] FROM @ColumnValuePair
                                          );

                DECLARE @lastModifiedColumn NVARCHAR(100);
                DECLARE @lastModifiedByColumn NVARCHAR(100);
                DECLARE @ClassColumn NVARCHAR(100);
                DECLARE @CreateColumn NVARCHAR(100);
                DECLARE @CreatedByColumn NVARCHAR(100);

                SELECT @lastModifiedColumn = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [MFID] = 21; --'Last Modified'

                SELECT @lastModifiedByColumn = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [MFID] = 23; --'Last Modified By'

                SELECT @ClassColumn = [mp].[Name]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [MFID] = 100; --'Class'

                SELECT @CreateColumn = [mp].[Name]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [MFID] = 20; --'Created'

                SELECT @CreatedByColumn = [mp].[ColumnName]
                FROM [dbo].[MFProperty] AS [mp]
                WHERE [MFID] = 25;

                --'Created By'

                --	SELECT * FROM mfproperty WHERE mfid < 100
                DELETE FROM @ColumnValuePair
                WHERE [ColumnName] IN ( @ClassColumn, @ClassColumn + '_ID', @lastModifiedColumn, @lastModifiedByColumn
                                       ,@CreateColumn, @CreatedByColumn
                                      );

                IF @Debug > 0
				Begin
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                SELECT [ColumnName]
                      ,[ColumnValue]
                FROM @ColumnValuePair;

				END

                ------------------------------------------------------
                -- CREATING XML
                ------------------------------------------------------
                SELECT @ProcedureStep = 'Generate XML File';

                SELECT @XMLFile
                    =
                (
                    SELECT @ObjectTypeId AS [Object/@id]
                          ,@Id           AS [Object/@sqlID]
                          ,@objID        AS [Object/@objID]
                          ,@ObjVersion   AS [Object/@objVesrion]
                          ,(
                               SELECT @ClassId AS [class/@id]
                                     ,(
                                          SELECT [mfp].[MFID]        AS [property/@id]
                                                ,(
                                                     SELECT [MFTypeID] FROM [MFDataType] WHERE [ID] = [mfp].[MFDataType_ID]
                                                 )                   AS [property/@dataType]
                                                ,[tmp].[ColumnValue] AS [property]
                                          FROM @ColumnValuePair       AS [tmp]
                                              INNER JOIN [MFProperty] AS [mfp]
                                                  ON [mfp].[ColumnName] = [tmp].[ColumnName]
                                          FOR XML PATH(''), TYPE
                                      )        AS [class]
                               FOR XML PATH(''), TYPE
                           )             AS [Object]
                    FOR XML PATH(''), ROOT('form')
                );

                SELECT @XMLFile =
                (
                    SELECT @XMLFile.[query]('/form/*')
                );

                DELETE FROM @ColumnValuePair;

                --------------------------------------------------------------------------------------------------
                SELECT @FullXml
                    = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

                SELECT @XML = '<form>' + (CAST(@FullXml AS NVARCHAR(MAX))) + '</form>';

                DECLARE @objVerDetails_Count INT;

                IF @Debug > 0
				 BEGIN
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

               
                    SELECT @XML AS [XML File for update];
                END;

                SELECT @ProcedureStep = 'Wrapper Method spMFCreateObjectInternal ';

                IF @Debug > 0
                BEGIN
                    SELECT CAST(@XML AS XML);
                END;

                SELECT @MFIDs = @MFIDs + CAST(ISNULL([MFP].[MFID], '') AS NVARCHAR(10)) + ','
                FROM [INFORMATION_SCHEMA].[COLUMNS] AS [CLM]
                    LEFT JOIN [MFProperty]          AS [MFP]
                        ON [MFP].[ColumnName] = [CLM].[COLUMN_NAME]
                WHERE [TABLE_NAME] = @MFTableName;

                SELECT @MFIDs = LEFT(@MFIDs, LEN(@MFIDs) - 1); -- Remove last ','

                IF @Debug > 0
                BEGIN
                    SELECT @MFIDs AS [List of Properties];
                END;

                DECLARE @Username NVARCHAR(2000);
                DECLARE @VaultName NVARCHAR(2000);

                SELECT @Username  = [mvs].[Username]
                      ,@VaultName = [mvs].[VaultName]
                FROM [dbo].[MFVaultSettings] AS [mvs];

                INSERT INTO [MFUpdateHistory]
                (
                    [Username]
                   ,[VaultName]
                   ,[UpdateMethod]
                   ,[ObjectDetails]
                   ,[ObjectVerDetails]
                )
                VALUES
                (@Username, @VaultName, 0, @XML, NULL);

                SET @Update_ID = @@Identity;
                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records in ObjVerDetails for MFiles';
                SET @LogStatusDetail = 'Output';
                SET @Validation_ID = NULL;
                SET @LogColumnValue = '';
                SET @LogColumnName = 'MFUpdateHistory: ObjectVerDetails';

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

							-----------------------------------------------------------------
							-- Checking module access for CLR procdure  spMFCreateObjectInternal
						   ------------------------------------------------------------------
                           EXEC [dbo].[spMFCheckLicenseStatus] 
						        'spMFCreateObjectInternal'
								,@ProcedureName
								,@ProcedureStep

                ------------------------------------------------------
                -- CALLING WRAPPER METHOD
                ------------------------------------------------------
                EXECUTE [spMFCreateObjectInternal] @VaultSettings
                                                  ,@XML
                                                  ,NULL
                                                  ,@MFIDs
                                                  ,0
                                                  ,NULL
                                                  ,NULL
                                                  ,@XmlOUT OUTPUT
                                                  ,@NewObjectXml OUTPUT
                                                  ,@SynchErrorObj OUTPUT  --Added new paramater
                                                  ,@DeletedObjects OUTPUT --Added new paramater	
                                                  ,@ErrorInfo OUTPUT;

                IF @Debug > 0
                BEGIN
                    RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 10, 1, @ProcedureName, @ProcedureStep, @ErrorInfo);                  
                END;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'Wrapper turnaround';
                SET @LogStatusDetail = 'Output';
                SET @Validation_ID = NULL;
                SET @LogColumnValue = '';
                SET @LogColumnName = '';

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

                IF (@Update_ID > 0)
                    UPDATE [MFUpdateHistory]
                    SET [NewOrUpdatedObjectVer] = @XmlOUT
                       ,[NewOrUpdatedObjectDetails] = @NewObjectXml
                       ,[SynchronizationError] = @SynchErrorObj
                       ,[DeletedObjectVer] = @DeletedObjects
                       ,[MFError] = @ErrorInfo
                    WHERE [Id] = @Update_ID;

                DECLARE @IDoc INT;

                CREATE TABLE [#ObjVer]
                (
                    [ID] INT
                   ,[ObjID] INT
                   ,[MFVersion] INT
                   ,[GUID] NVARCHAR(100)
                );

                SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
                SET @NewXML = CAST(@XmlOUT AS XML);

                IF @Debug > 10
                    SELECT @NewXML AS [newxml];

                INSERT INTO [#ObjVer]
                (
                    [MFVersion]
                   ,[ObjID]
                   ,[ID]
                   ,[GUID]
                )
                SELECT [t].[c].[value]('(@objVersion)[1]', 'INT')           AS [MFVersion]
                      ,[t].[c].[value]('(@objectId)[1]', 'INT')             AS [ObjID]
                      ,[t].[c].[value]('(@ID)[1]', 'INT')                   AS [ID]
                      ,[t].[c].[value]('(@objectGUID)[1]', 'NVARCHAR(100)') AS [GUID]
                FROM @NewXML.[nodes]('/form/Object') AS [t]([c]);

                IF @Debug > 0
                BEGIN
                    SELECT *
                    FROM [#ObjVer];
                END;

                SET @UpdateQuery
                    = '	UPDATE ['    + @MFTableName + ']
					SET ['         + @MFTableName + '].ObjID = #ObjVer.ObjID
					,['            + @MFTableName + '].MFVersion = #ObjVer.MFVersion
					,['            + @MFTableName
                      + '].GUID = #ObjVer.GUID
					,Process_ID = 0
					,Deleted = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE ['       + @MFTableName + '].ID = #ObjVer.ID';

                EXEC (@UpdateQuery);

                DROP TABLE [#ObjVer];

                ----------------------------------------------------------------------------------------------------------
                --Update Process_ID to 2 when synch error occcurs--
                ----------------------------------------------------------------------------------------------------------
                SET @ProcedureStep = 'Updating MFTable with Process_ID = 2,if any synch error occurs';

                ----------------------------------------------------------------------------------------------------------
                --Create an internal representation of the XML document. 
                ---------------------------------------------------------------------------------------------------------                
                CREATE TABLE [#SynchErrObjVer]
                (
                    [ID] INT
                   ,[ObjID] INT
                   ,[MFVersion] INT
                );

                -----------------------------------------------------
                ----Inserting the Xml details into temp Table
                -----------------------------------------------------
                DECLARE @SynchErrorXML XML;

                SET @SynchErrorXML = CAST(@SynchErrorObj AS XML);

                INSERT INTO [#SynchErrObjVer]
                (
                    [MFVersion]
                   ,[ObjID]
                   ,[ID]
                )
                SELECT [t].[c].[value]('(@objVersion)[1]', 'INT') AS [MFVersion]
                      ,[t].[c].[value]('(@objectId)[1]', 'INT')   AS [ObjID]
                      ,[t].[c].[value]('(@ID)[1]', 'INT')         AS [ID]
                FROM @SynchErrorXML.[nodes]('/form/Object') AS [t]([c]);

                SELECT @SynchErrCount = COUNT(*)
                FROM [#SynchErrObjVer];

                IF @SynchErrCount > 0
                BEGIN
                    IF @Debug > 0
                    BEGIN
                        PRINT 'Synchronisation error';

                        SELECT *
                        FROM [#SynchErrObjVer];
                    END;

                    -------------------------------------------------------------------------------------
                    -- UPDATE THE SYNCHRONIZE ERROR
                    ------------------------------------------------------------------------------------
                    SET @SynchErrUpdateQuery
                        = '	UPDATE ['    + @MFTableName
                          + ']
					SET Process_ID = 2
					,LastModified = GETDATE()
					FROM #SynchErrObjVer
					WHERE ['                   + @MFTableName + '].ObjID = #SynchErrObjVer.ObjID';

                    EXEC (@SynchErrUpdateQuery);

                    ------------------------------------------------------
                    -- LOGGING THE ERROR
                    ------------------------------------------------------
                    SELECT @ProcedureStep = 'Update MFUpdateLog for Sync error objects';

                    ----------------------------------------------------------------
                    --Inserting Synch Error Details into MFLog
                    ----------------------------------------------------------------
                    INSERT INTO [MFLog]
                    (
                        [ErrorMessage]
                       ,[Update_ID]
                       ,[ErrorProcedure]
                       ,[ExternalID]
                       ,[ProcedureStep]
                       ,[SPName]
                    )
                    SELECT *
                    FROM
                    (
                        SELECT 'Synchronization error occured while updating ObjID : '
                               + CAST([#SynchErrObjVer].[ObjID] AS NVARCHAR(10)) + ' Version : '
                               + CAST([#SynchErrObjVer].[MFVersion] AS NVARCHAR(10)) + '' AS [ErrorMessage]
                              ,@Update_ID                                                 AS [Update_ID]
                              ,@TableName                                                 AS [ErrorProcedure]
                              ,''                                                         AS [ExternalID]
                              ,'Synchronization Error'                                    AS [ProcedureStep]
                              ,'spMFUpdateTable'                                          AS [SPName]
                        FROM [#SynchErrObjVer]
                    ) AS [vl];
                END;

                DROP TABLE [#SynchErrObjVer];

                -------------------------------------------------------------
                --Logging error details
                -------------------------------------------------------------
                CREATE TABLE [#ErrorInfo]
                (
                    [ObjID] INT
                   ,[SqlID] INT
                   ,[ExternalID] NVARCHAR(100)
                   ,[ErrorMessage] NVARCHAR(MAX)
                );

                SELECT @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';

                DECLARE @ErrorInfoXML XML;

                SELECT @ErrorInfoXML = CAST(@ErrorInfo AS XML);

                INSERT INTO [#ErrorInfo]
                (
                    [ObjID]
                   ,[SqlID]
                   ,[ExternalID]
                   ,[ErrorMessage]
                )
                SELECT [t].[c].[value]('(@objID)[1]', 'INT')                  AS [objID]
                      ,[t].[c].[value]('(@sqlID)[1]', 'INT')                  AS [SqlID]
                      ,[t].[c].[value]('(@externalID)[1]', 'NVARCHAR(100)')   AS [ExternalID]
                      ,[t].[c].[value]('(@ErrorMessage)[1]', 'NVARCHAR(MAX)') AS [ErrorMessage]
                FROM @ErrorInfoXML.[nodes]('/form/errorInfo') AS [t]([c]);

                SELECT @ErrorInfoCount = COUNT(*)
                FROM [#ErrorInfo];

                IF @ErrorInfoCount > 0
                BEGIN
                    IF @Debug > 0
                    BEGIN
                        SELECT *
                        FROM [#ErrorInfo];
                    END;

                    SELECT @MFErrorUpdateQuery
                        = 'UPDATE [' + @MFTableName
                          + ']
									   SET Process_ID = 3
									   FROM #ErrorInfo err
									   WHERE err.SqlID = [' + @MFTableName + '].ID';

                    EXEC (@MFErrorUpdateQuery);

                    INSERT INTO [MFLog]
                    (
                        [ErrorMessage]
                       ,[Update_ID]
                       ,[ErrorProcedure]
                       ,[ExternalID]
                       ,[ProcedureStep]
                       ,[SPName]
                    )
                    SELECT 'ObjID : ' + CAST(ISNULL([ObjID], '') AS NVARCHAR(100)) + ',' + 'SQL ID : '
                           + CAST(ISNULL([SqlID], '') AS NVARCHAR(100)) + ',' + [ErrorMessage] AS [ErrorMessage]
                          ,@Update_ID
                          ,@TableName                                                          AS [ErrorProcedure]
                          ,[ExternalID]
                          ,'Error While inserting/Updating in M-Files'                         AS [ProcedureStep]
                          ,'spMFUpdateTable'                                                   AS [spname]
                    FROM [#ErrorInfo];
                END;

                DROP TABLE [#ErrorInfo];

                SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';

                -------------------------------------------------------------------------------------
                --Update deleted column if record is deleled from M Files
                ------------------------------------------------------------------------------------               
                CREATE TABLE [#DeletedRecordId]
                (
                    [ID] INT
                );

                --INSERT INTO #DeletedRecordId
                DECLARE @DeletedXML XML;

                SET @DeletedXML = CAST(@DeletedObjects AS XML);

                INSERT INTO [#DeletedRecordId]
                (
                    [ID]
                )
                SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ID]
                FROM @DeletedXML.[nodes]('/form/objVers') AS [t]([c]);

                IF @Debug > 0
                BEGIN
                   

                    SELECT id AS DeletedRecord
                    FROM [#DeletedRecordId];
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

                DROP TABLE [#DeletedRecordId];

                --------------------------------------------
                -- DELETING THE RECORD FROM CURRENT MFTABLE 
                --------------------------------------------
                IF (@NewObjectXml IS NOT NULL)
                BEGIN
                    SELECT @ProcedureStep = 'Delete Row from MFTable';

                    DECLARE @DeleteQuery NVARCHAR(100);

                    SELECT @DeleteQuery
                        = 'DELETE FROM [' + @MFTableName + '] WHERE OBJId =' + CAST(@ObjectID AS NVARCHAR(10)) + ' AND ' + CAST(@ClassID AS NVARCHAR(10))+ ' != ' + CAST(@NewClassID AS NVARCHAR(10));

  IF @Debug > 0
				Begin
                    RAISERROR(@DebugText, @MsgSeverityInfo, 1, @ProcedureName, @ProcedureStep);

                SELECT @DeleteQuery AS DeleteQuery

				END


                    EXEC [sp_executesql] @DeleteQuery;
                END;

                --------------------------------
                -- INSERTING RECORD INTO MFTABLE
                --------------------------------
                IF @NewClassId IS NOT NULL 
                BEGIN
                    SELECT @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));

                    SELECT @ProcedureStep = 'Select Table Name from NEW CLASS';

                    SELECT @TableName = [TableName]
                    FROM [MFClass]
                    WHERE [MFID] = @NewClassId;

                    -------------------------------------------------------------------------------------
                    -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
                    -------------------------------------------------------------------------------------
                    SET @StartTime = GETUTCDATE();

                    IF (@NewObjectXml != '<form />')
                    BEGIN
                        SET @ProcedureName = 'spMFUpdateTableInternal';
                        SET @ProcedureStep = 'Update property details from M-Files in new Class Table ';

                        IF @Debug > 9
                        BEGIN
                            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                            IF @Debug > 10
                                SELECT @NewObjectXml AS [@NewObjectXml before updateobjectinternal];
                        END;

                        EXEC @return_value = [dbo].[spMFUpdateTableInternal] @MFTableName
                                                                            ,@NewObjectXml
                                                                            ,@Update_ID
                                                                            ,@Debug = @Debug;
						END -- if ClassID is not null
                        --        ,@SyncErrorFlag = @SyncErrorFlag;
                        IF @return_value <> 1
                            RAISERROR('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @LogTypeDetail = 'Status';
                    SET @LogStatusDetail = 'In progress';
                    SET @LogTextDetail = 'Insert record for table ' + @MFTableName;
                    SET @LogColumnName = '';
                    SET @LogColumnValue = '';

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

                    IF (@return_value = 1)
                    BEGIN
                        UPDATE [MFUpdateHistory]
                        SET [UpdateStatus] = 'completed'
                        WHERE [Id] = @Update_ID;
                    END;
                    ELSE
                    BEGIN
                        UPDATE [MFUpdateHistory]
                        SET [UpdateStatus] = 'partial'
                        WHERE [Id] = @Update_ID;
                    END;

                    IF @SynchErrCount > 0
                        RETURN 2; --Synchronization Error
                    ELSE IF @ErrorInfoCount > 0
                        RETURN 3; --MFError
                END; -- @ClassID is not null or @ColumnNames is not null
                ELSE
                BEGIN
				Set @DebugText = ''
				Set @DebugText = @DefaultDebugText + @DebugText
				Set @Procedurestep = ''
				
				IF @debug > 0
					Begin
						RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
					END
				
                   SET @DebugText = ''
                    SET @ProcedureStep = 'Missing Parameters ';
                    SET @LogStatus = 'Error';
                    SET @LogTextDetail = 'Either ClassID or ColumnNames or both must be used ';
					 SET @DebugText = @DefaultDebugText + @DebugText;

                    RAISERROR(@DebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep);
                END;
            END; --Object exists
            ELSE
            BEGIN
			SET @DebugText = ''
                SET @DebugText = @DefaultDebugText + @DebugText;
				SET @ProcedureStep = 'Incorrect Object ';
                SET @LogStatus = 'Error';
                SET @LogTextDetail = 'Object ID is invalid ';

                RAISERROR(@DebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep);
            END; -- end else
        END; -- Table exists
        ELSE
        BEGIN
		SET @DebugText = ''
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Check Tablename ';
            SET @LogStatus = 'Error';
            SET @LogTextDetail = 'Tablename does not exist';

            RAISERROR(@DebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep);
        END; --end else
  

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = 'End';

    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   
    SET @LogStatus = 'Completed';

    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Message'
                                        ,@LogText = @LogText
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Message'
                                              ,@LogText = @ProcessType
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

    SET @Update_IDOUT = @Update_ID;

    RETURN 1;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[ErrorLine]
       ,[ProcedureStep]
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE()
    ,@ProcedureStep);

    SET @ProcedureStep = 'Catch Error';
    SET @LogTextDetail = ERROR_MESSAGE();
    SET @LogStatus = 'Not Updated';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Error'
                                        ,@LogText = @LogTextDetail
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Error'
                                              ,@LogText = @LogTextDetail
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

    RETURN -1;
END CATCH;
GO