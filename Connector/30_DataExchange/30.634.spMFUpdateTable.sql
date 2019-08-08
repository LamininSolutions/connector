
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTable]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateTable'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.4.11.52'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTable' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateTable]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateTable]
(
    @MFTableName NVARCHAR(200)
   ,@UpdateMethod INT               --0=Update from SQL to MF only; 
                                    --1=Update new records from MF; 
                                    --2=initialisation 
   ,@UserId NVARCHAR(200) = NULL    --null for all user update
   ,@MFModifiedDate DATETIME = NULL --NULL to select all records
   ,@ObjIDs NVARCHAR(MAX) = NULL
   ,@Update_IDOut INT = NULL OUTPUT
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@SyncErrorFlag BIT = 0          -- note this parameter is auto set by the operation 
   ,@RetainDeletions BIT = 0
                                    --   ,@UpdateMetadata BIT = 0
   ,@Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

spMFUpdateTable
===============

Return
  - 1 = Success
  - 0 = Partial (some records failed to be inserted)
  - -1 = Error
Parameters
  @MFTableName
	Valid Class TableName as a string ; Required
    Pass the class table name, e.g.: 'MFCustomer'
  @Updatemethod
    Options: 0, 1 ; Required
		- 0 = update from SQL to M-Files
		- 1 = update from M-Files to SQL
  @User_ID
	Default = 0, optional
    User_Id from MX_User_Id column
	This is NOT the M-Files user.  It is used to set and apply a user_id for a third party system. An example is where updates from a third party system must be filtered by the third party user (e.g. placing an order)
  @MFLastModified
	Default = 0, optional
    Get objects from M-Files that has been modified in M-files later than this date.
  @ObjIDs
	Default = null, optional
    ObjID's of records (separated by comma) e.g. : '10005,13203'
	Restricted to 4000 charactes including the commas
  @Update_IDOut
	Optional
    Output parameter 
	Output id of the record in MFUpdateHistory logging the update ; Also added to the record in the Update_ID column on the class table
  @ProcessBatch_ID
	Optional
    Output parameter
	Referencing the ID of the ProcessBatch logging table
  @SyncErrorFlag
    Default = 0 ; Optional
	This parameter is automatically set by spMFUpdateSynchronizeError when synchronization routine is called.
  @RetainDeletions
    Default = 0 ; Optional
	Set to 1 to keep deleted items in M-Files in the SQL table shown as deleted = 1
  @Debug
    - Default = 0 ; Optional
    - 1 = Standard Debug Mode
	- 101 = Advanced Debug Mode


							   
**rST*************************************************************************/
DECLARE @Update_ID    INT
       ,@return_value INT = 1;

BEGIN TRY
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

    IF EXISTS
    (
        SELECT 1
        FROM [sys].[objects]
        WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND [type] IN ( N'U' )
    )
    BEGIN
        -----------------------------------------------------
        --GET LOGIN CREDENTIALS
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Security Variables';

        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
               @Username  = [Username]
              ,@VaultName = [VaultName]
        FROM [dbo].[MFVaultSettings];

        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        -------------------------------------------------------------
        -- Check connection to vault
        -------------------------------------------------------------
        DECLARE @IsUpToDate INT;

        SET @ProcedureStep = 'Connection test: ';

        EXEC @return_value = [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

        IF @return_value < 0
		        BEGIN
            SET @DebugText = 'Connection failed %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep,@return_value);
        END;

        -------------------------------------------------------------
        -- Set process type
        -------------------------------------------------------------
        SELECT @ProcessType = CASE
                                  WHEN @UpdateMethod = 0 THEN
                                      'UpdateMFiles'
                                  ELSE
                                      'UpdateSQL'
                              END;

        -------------------------------------------------------------
        --	Create Update_id for process start 
        -------------------------------------------------------------
        SET @ProcedureStep = 'set Update_ID';
        SET @StartTime = GETUTCDATE();

        INSERT INTO [dbo].[MFUpdateHistory]
        (
            [Username]
           ,[VaultName]
           ,[UpdateMethod]
        )
        VALUES
        (@Username, @VaultName, @UpdateMethod);

        SELECT @Update_ID = @@Identity;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcedureStep = 'Start ';
        SET @StartTime = GETUTCDATE();
        SET @ProcessType = @ProcedureName;
        SET @LogType = 'Status';
        SET @LogStatus = 'Started';
        SET @LogText = 'Update using Update_ID: ' + CAST(@Update_ID AS VARCHAR(10));

        IF @Debug > 9
        BEGIN
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                                               ,@ProcessType = @ProcessType
                                                               ,@LogType = @LogType
                                                               ,@LogText = @LogText
                                                               ,@LogStatus = @LogStatus
                                                               ,@debug = @Debug;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + 'Update_ID %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_ID);
        END;

        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFCreateObjectInternal
        ------------------------------------------------------------------
        EXEC [dbo].[spMFCheckLicenseStatus] 'spMFCreateObjectInternal'
                                           ,@ProcedureName
                                           ,@ProcedureStep;

        -----------------------------------------------------
        --Determine if any filter have been applied
        --if no filters applied then full refresh, else apply filters
        -----------------------------------------------------
        DECLARE @IsFullUpdate BIT;

        SELECT @IsFullUpdate = CASE
                                   WHEN @UserId IS NULL
                                        AND @MFModifiedDate IS NULL
                                        AND @ObjIDs IS NULL THEN
                                       1
                                   ELSE
                                       0
                               END;

        -----------------------------------------------------
        --Convert @UserId to UNIQUEIDENTIFIER type
        -----------------------------------------------------
        SET @UserId = CONVERT(UNIQUEIDENTIFIER, @UserId);
        -----------------------------------------------------
        --Get Table_ID 
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Table ID';
        SET @TableName = @MFTableName;

        SELECT @Table_ID = [object_id]
        FROM [sys].[objects]
        WHERE [name] = @MFTableName;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + 'Table: %s';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
        END;

        -----------------------------------------------------
        --Get Object Type Id
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Object Type and Class';

        SELECT @ObjectIdRef = [MFObjectType_ID]
        FROM [dbo].[MFClass]
        WHERE [TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        SELECT @ObjectId = [MFID]
        FROM [dbo].[MFObjectType]
        WHERE [ID] = @ObjectIdRef;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + ' ObjectType: %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
        END;

        -----------------------------------------------------
        --Set class id
        -----------------------------------------------------
        SELECT @ClassId = [MFID]
        FROM [dbo].[MFClass]
        WHERE [TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + ' Class: %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
        END;

        SET @ProcedureStep = 'Prepare Table ';
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Debug';
        SET @LogTextDetail = 'For UpdateMethod ' + CAST(@UpdateMethod AS VARCHAR(10));
        SET @LogColumnName = 'UpdateMethod';
        SET @LogColumnValue = CAST(@UpdateMethod AS VARCHAR(10));

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

        -----------------------------------------------------
        --SELECT THE ROW DETAILS DEPENDS ON UPDATE METHOD INPUT
        -----------------------------------------------------
        SET @StartTime = GETUTCDATE();

        -------------------------------------------------------------
        --Delete records if @Retained records set to 0
        -------------------------------------------------------------
        IF @UpdateMethod = 1
           AND @RetainDeletions = 0
        BEGIN
            SET @Query = N'Delete from ' + QUOTENAME(@MFTableName) + ' Where deleted = 1';

            EXEC (@Query);
        END;

        -- end if delete records;

        -------------------------------------------------------------
        -- PROCESS UPDATEMETHOD = 0
        -------------------------------------------------------------
        IF @UpdateMethod = 0 --- processing of process_ID = 1
        BEGIN
            DECLARE @Count          NVARCHAR(10)
                   ,@SelectQuery    NVARCHAR(MAX)    --query snippet to count records
                   ,@vquery         AS NVARCHAR(MAX) --query snippet for filter
                   ,@ParmDefinition NVARCHAR(500);

            -------------------------------------------------------------
            -- Get localisation names for standard properties
            -------------------------------------------------------------
            DECLARE @Columnname NVARCHAR(100);
            DECLARE @lastModifiedColumn NVARCHAR(100);
            DECLARE @ClassPropName NVARCHAR(100);

            SELECT @Columnname = [ColumnName]
            FROM [dbo].[MFProperty]
            WHERE [MFID] = 0;

            SELECT @lastModifiedColumn = [mp].[ColumnName]
            FROM [dbo].[MFProperty] AS [mp]
            WHERE [mp].[MFID] = 21; --'Last Modified'

            SELECT @ClassPropName = [mp].[ColumnName]
            FROM [dbo].[MFProperty] AS [mp]
            WHERE [mp].[MFID] = 100;

            -------------------------------------------------------------
            -- PROCESS FULL UPDATE FOR UPDATE METHOD 0
            -------------------------------------------------------------		

            -------------------------------------------------------------
            -- START BUILDING OF SELECT QUERY FOR FILTER
            -------------------------------------------------------------
            -------------------------------------------------------------
            -- Set select query snippet to count records
            -------------------------------------------------------------
            SET @ParmDefinition = N'@retvalOUT int OUTPUT';
            SET @SelectQuery = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName + '] WHERE ';
            -------------------------------------------------------------
            -- Get column for name or title and set to 'Auto' if left blank
            -------------------------------------------------------------
            SET @Query = N'UPDATE ' + @MFTableName + '
					SET ' + @Columnname + ' = ''Auto''
					WHERE ' + @Columnname + ' IS NULL AND process_id = 1';

            --		PRINT @SQL
            EXEC (@Query);

            -------------------------------------------------------------
            -- create filter query for update method 0
            -------------------------------------------------------------       
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'filter snippet for Updatemethod 0';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            IF @SyncErrorFlag = 1
            BEGIN
                SET @vquery = ' Process_ID = 2  ';
            END;
            ELSE
            BEGIN
                SET @vquery = ' Process_ID = 1 ';
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
                        = @vquery + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs + ','','',''))';

                    IF @Debug > 9
                    BEGIN
                        SELECT @ObjIDs;
                    END;
                END;

                IF @Debug > 100
                    SELECT @vquery;
            END; -- end of setting up filter : is full update

            SET @SelectQuery = @SelectQuery + @vquery;

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 10
                    SELECT @SelectQuery AS [Select records for update];
            END;

            -------------------------------------------------------------
            -- create filter select snippet
            -------------------------------------------------------------
            EXEC [sys].[sp_executesql] @SelectQuery
                                      ,@ParmDefinition
                                      ,@retvalOUT = @Count OUTPUT;

            -------------------------------------------------------------
            -- Set class ID if not included
            -------------------------------------------------------------
            SET @ProcedureStep = 'Set class ID where null';
            SET @Params = N'@ClassID int';
            SET @Query
                = N'UPDATE t
					SET t.' + @ClassPropName + ' = @ClassId
					FROM ' + QUOTENAME(@MFTableName) + ' t WHERE t.process_ID = 1 AND (' + @ClassPropName
                  + ' IS NULL or ' + @ClassPropName + '= -1) AND t.Deleted != 1';

            EXEC [sys].[sp_executesql] @stmt = @Query
                                      ,@Param = @Params
                                      ,@Classid = @ClassId;

            -------------------------------------------------------------
            -- log number of records to be updated
            -------------------------------------------------------------
            SET @StartTime = GETUTCDATE();
            SET @DebugText = 'Count of records i%';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Start Processing UpdateMethod 0';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Count filtered records with process_id = 1 ';
            SET @LogStatusDetail = 'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'process_ID';
            SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));

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

            --------------------------------------------------------------------------------------------
            --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
            --------------------------------------------------------------------------------------------
            IF (@Count > '0' AND @UpdateMethod = 0)
            BEGIN
                DECLARE @vsql    AS NVARCHAR(MAX)
                       ,@XMLFile XML
                       ,@XML     NVARCHAR(MAX);

                SET @FullXml = NULL;
                --	-------------------------------------------------------------
                --	-- anchor list of objects to be updated
                --	-------------------------------------------------------------
                --	    SET @Query = '';
                --		  Declare    @ObjectsToUpdate VARCHAR(100)

                --      SET @ProcedureStep = 'Filtered objects to update';
                --      SELECT @ObjectsToUpdate = [dbo].[fnMFVariableTableName]('##UpdateList', DEFAULT);

                -- SET @Query = 'SELECT * INTO '+ @ObjectsToUpdate +' FROM 
                --  (SELECT ID from '                       + QUOTENAME(@MFTableName) + ' where 
                --' + @vquery + ' )list ';

                --IF @Debug > 0
                --SELECT @Query AS FilteredRecordsQuery;

                --EXEC (@Query)

                -------------------------------------------------------------
                -- start column value pair for update method 0
                -------------------------------------------------------------
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Create Column Value Pair';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                CREATE TABLE [#ColumnValuePair]
                (
                    [Id] INT
                   ,[objID] INT
                   ,[ObjVersion] INT
                   ,[ExternalID] NVARCHAR(100)
                   ,[ColumnName] NVARCHAR(200)
                   ,[ColumnValue] NVARCHAR(4000)
                   ,[Required] INT
                   ,[MFID] INT
                   ,[DataType] INT
                );

                CREATE INDEX [IDX_ColumnValuePair_ColumnName]
                ON [#ColumnValuePair] ([ColumnName]);

                DECLARE @colsUnpivot AS NVARCHAR(MAX)
                       ,@colsPivot   AS NVARCHAR(MAX)
                       ,@DeleteQuery AS NVARCHAR(MAX)
                       ,@rownr       INT
                       ,@Datatypes   NVARCHAR(100);

                -------------------------------------------------------------
                -- prepare column value pair query based on data types
                -------------------------------------------------------------
                SET @Query = '';

                DECLARE @DatatypeTable AS TABLE
                (
                    [id] INT IDENTITY
                   ,[Datatypes] NVARCHAR(20)
                   ,[Type_Ids] NVARCHAR(100)
                );

                INSERT INTO @DatatypeTable
                (
                    [Datatypes]
                   ,[Type_Ids]
                )
                VALUES
                (   N'Float' -- Datatypes - nvarchar(20)
                   ,N'3'     -- Type_Ids - nvarchar(100)
                    )
               ,('Integer', '2,8,10')
               ,('Text', '1')
               ,('MultiText', '12')
               ,('MultiLookup', '9')
               ,('Time', '5')
               ,('DateTime', '6')
               ,('Date', '4')
               ,('Bit', '7');

                SET @rownr = 1;
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'loop through Columns';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                WHILE @rownr IS NOT NULL
                BEGIN
                    SELECT @Datatypes = [dt].[Type_Ids]
                    FROM @DatatypeTable AS [dt]
                    WHERE [dt].[id] = @rownr;

                    SET @DebugText = 'DataTypes %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Create Column Value Pair';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Datatypes);
                    END;

                    SELECT @colsUnpivot
                        = STUFF(
                          (
                              SELECT ',' + QUOTENAME([C].[name])
                              FROM [sys].[columns]              AS [C]
                                  INNER JOIN [dbo].[MFProperty] AS [mp]
                                      ON [mp].[ColumnName] = [C].[name]
                              WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                    AND ISNULL([mp].[MFID], -1) NOT IN ( - 1, 20, 21, 23, 25 )
                                    AND [mp].[ColumnName] <> 'Deleted'
                                    AND [mp].[MFDataType_ID] IN (
                                                                    SELECT [ListItem] FROM [dbo].[fnMFParseDelimitedString](
                                                                                                                               @Datatypes
                                                                                                                              ,','
                                                                                                                           )
                                                                )
                              FOR XML PATH('')
                          )
                         ,1
                         ,1
                         ,''
                               );

                    IF @Debug > 0
                        SELECT @colsUnpivot AS 'columns';

                    IF @colsUnpivot IS NOT NULL
                    BEGIN
                        SET @Query
                            = @Query
                              + 'Union All
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '                       + QUOTENAME(@MFTableName)
                              + ' t
        unpivot
        (
          value for name in ('       + @colsUnpivot + ')
        ) unpiv
		where 
		'                            + @vquery + ' ';
                    END;

                    SELECT @rownr =
                    (
                        SELECT MIN([dt].[id])
                        FROM @DatatypeTable AS [dt]
                        WHERE [dt].[id] > @rownr
                    );
                END;

                SET @DeleteQuery
                    = N'Union All Select ID, Objid, MFversion, ExternalID, ''Deleted'' as ColumnName, cast(isnull(Deleted,0) as nvarchar(4000))  as Value from '
                      + QUOTENAME(@MFTableName) + ' t where ' + @vquery + ' ';

                --SELECT @DeleteQuery AS deletequery
                SELECT @Query = SUBSTRING(@Query, 11, 8000) + @DeleteQuery;

                IF @Debug > 100
                    PRINT @Query;

                -------------------------------------------------------------
                -- insert into column value pair
                -------------------------------------------------------------
                SELECT @Query
                    = 'INSERT INTO  #ColumnValuePair

SELECT ID,ObjID,MFVersion,ExternalID,ColumnName,Value,NULL,null,null from 
(' +                @Query + ') list';

                IF @Debug = 100
                BEGIN
                    SELECT @Query AS 'ColumnValue pair query';
                END;

                EXEC (@Query);

                -------------------------------------------------------------
                -- Validate class and proerty requirements
                -------------------------------------------------------------
                IF @IsUpToDate = 0
                BEGIN
                    EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Property';

                    EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'class';

                    WITH [cte]
                    AS (SELECT [mfms].[Property]
                        FROM [dbo].[MFvwMetadataStructure] AS [mfms]
                        WHERE [mfms].[TableName] = @MFTableName
                              AND [mfms].[Property_MFID] NOT IN ( 20, 21, 23, 25 )
                              AND [mfms].[Required] = 1
                        EXCEPT
                        (SELECT [mp].[Name]
                         FROM [#ColumnValuePair]           AS [cvp]
                             INNER JOIN [dbo].[MFProperty] [mp]
                                 ON [cvp].[ColumnName] = [mp].[ColumnName]))
                    INSERT INTO [#ColumnValuePair]
                    (
                        [Id]
                       ,[objID]
                       ,[ObjVersion]
                       ,[ExternalID]
                       ,[ColumnName]
                       ,[ColumnValue]
                       ,[Required]
                       ,[MFID]
                       ,[DataType]
                    )
                    SELECT [cvp].[Id]
                          ,[cvp].[objID]
                          ,[cvp].[ObjVersion]
                          ,[cvp].[ExternalID]
                          ,[mp].[ColumnName]
                          ,'ZZZ'
                          ,1
                          ,[mp].[MFID]
                          ,[mp].[MFDataType_ID]
                    FROM [#ColumnValuePair] AS [cvp]
                        CROSS APPLY [cte]
                        INNER JOIN [dbo].[MFProperty] AS [mp]
                            ON [cte].[Property] = [mp].[Name]
                    GROUP BY [cvp].[Id]
                            ,[cvp].[objID]
                            ,[cvp].[ObjVersion]
                            ,[cvp].[ExternalID]
                            ,[mp].[ColumnName]
                            ,[mp].[MFDataType_ID]
                            ,[mp].[MFID];
                END;

                -------------------------------------------------------------
                -- check for required data missing
                -------------------------------------------------------------
                IF
                (
                    SELECT COUNT(*)
                    FROM [#ColumnValuePair] AS [cvp]
                    WHERE [cvp].[ColumnValue] = 'ZZZ'
                          AND [cvp].[Required] = 1
                ) > 0
                BEGIN
                    DECLARE @missingColumns NVARCHAR(4000);

                    SELECT @missingColumns = STUFF((
                                                       SELECT ',' + [cvp].[ColumnName]
                                                       FROM [#ColumnValuePair] AS [cvp]
                                                       WHERE [cvp].[ColumnValue] = 'ZZZ'
                                                             AND [cvp].[Required] = 1
                                                       FOR XML PATH('')
                                                   )
                                                  ,1
                                                  ,1
                                                  ,''
                                                  );

                    SET @DebugText = ' in columns: ' + @missingColumns;
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Required data missing';

                    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- update column value pair properties
                -------------------------------------------------------------
                UPDATE [CVP]
                SET [CVP].[Required] = CASE
                                           WHEN [c2].[is_nullable] = 1 THEN
                                               0
                                           ELSE
                                               1
                                       END
                   ,[CVP].[ColumnValue] = CASE
                                              WHEN ISNULL([CVP].[ColumnValue], '-1') = '-1'
                                                   AND [c2].[is_nullable] = 0 THEN
                                                  'ZZZ'
                                              ELSE
                                                  [CVP].[ColumnValue]
                                          END
                --SELECT p.name, p.mfid,cp.required
                FROM [#ColumnValuePair]        [CVP]
                    INNER JOIN [sys].[columns] AS [c2]
                        ON [CVP].[ColumnName] = [c2].[name]
                WHERE [c2].[object_id] = OBJECT_ID(@MFTableName);

                UPDATE [cvp]
                SET [cvp].[MFID] = [mp].[MFID]
                   ,[cvp].[DataType] = [mdt].[MFTypeID]
                   ,[cvp].[ColumnValue] = CASE
                                              WHEN [mp].[MFID] = 27
                                                   AND [cvp].[ColumnValue] = '0' THEN
                                                  'ZZZ'
                                              ELSE
                                                  [cvp].[ColumnValue]
                                          END
                FROM [#ColumnValuePair]           AS [cvp]
                    INNER JOIN [dbo].[MFProperty] AS [mp]
                        ON [cvp].[ColumnName] = [mp].[ColumnName]
                    INNER JOIN [dbo].[MFDataType] AS [mdt]
                        ON [mp].[MFDataType_ID] = [mdt].[ID];

                -------------------------------------------------------------
                -- END of preparating column value pair
                -------------------------------------------------------------
                SELECT @Count = COUNT(*)
                FROM [#ColumnValuePair] AS [cvp];

                SET @ProcedureStep = 'ColumnValue Pair ';
                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'Properties for update ';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'Properties';
                SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));
                SET @DebugText = 'Column Value Pair: %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                END;

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

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Creating XML for Process_ID = 1';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -----------------------------------------------------
                --Generate xml file -- 
                -----------------------------------------------------
                SET @XMLFile =
                (
                    SELECT @ObjectId          AS [Object/@id]
                          ,[cvp].[Id]         AS [Object/@sqlID]
                          ,[cvp].[objID]      AS [Object/@objID]
                          ,[cvp].[ObjVersion] AS [Object/@objVesrion]
                          ,[cvp].[ExternalID] AS [Object/@DisplayID] --Added For Task #988
                                                                     --     ( SELECT
                                                                     --       @ClassId AS 'class/@id' ,
                          ,(
                               SELECT
                                   (
                                       SELECT TOP 1
                                              [tmp1].[ColumnValue]
                                       FROM [#ColumnValuePair] AS [tmp1]
                                       WHERE [tmp1].[MFID] = 100
                                   ) AS [class/@id]
                                  ,(
                                       SELECT [tmp].[MFID]     AS [property/@id]
                                             ,[tmp].[DataType] AS [property/@dataType]
                                             ,CASE
                                                  WHEN [tmp].[ColumnValue] = 'ZZZ' THEN
                                                      NULL
                                                  ELSE
                                                      [tmp].[ColumnValue]
                                              END              AS 'property' ----Added case statement for checking Required property
                                       FROM [#ColumnValuePair] AS [tmp]
                                       WHERE [tmp].[MFID] <> 100
                                             AND [tmp].[ColumnValue] IS NOT NULL
                                             AND [tmp].[Id] = [cvp].[Id]
                                       GROUP BY [tmp].[Id]
                                               ,[tmp].[MFID]
                                               ,[tmp].[DataType]
                                               ,[tmp].[ColumnValue]
                                       ORDER BY [tmp].[Id]
                                       --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                       FOR XML PATH(''), TYPE
                                   ) AS [class]
                               FOR XML PATH(''), TYPE
                           )                  AS [Object]
                    FROM [#ColumnValuePair] AS [cvp]
                    GROUP BY [cvp].[Id]
                            ,[cvp].[objID]
                            ,[cvp].[ObjVersion]
                            ,[cvp].[ExternalID]
                    ORDER BY [cvp].[Id]
                    FOR XML PATH(''), ROOT('form')
                );
                SET @XMLFile =
                (
                    SELECT @XMLFile.[query]('/form/*')
                );

                --------------------------------------------------------------------------------------------------
                IF @Debug > 100
                    SELECT @XMLFile AS [@XMLFile];

                SET @FullXml
                    = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

                IF @Debug > 100
                BEGIN
                    SELECT *
                    FROM [#ColumnValuePair] AS [cvp];
                END;

                SET @ProcedureStep = 'Get Full Xml';

                IF @Debug > 9
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                --Count records for ProcessBatchDetail
                SET @ParmDefinition = N'@Count int output';
                SET @Query = N'
					SELECT @Count = COUNT(*) FROM ' + @MFTableName + ' WHERE process_ID = 1';

                EXEC [sys].[sp_executesql] @stmt = @Query
                                          ,@param = @ParmDefinition
                                          ,@Count = @Count OUTPUT;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records for Updated method 0 ';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'process_ID = 1';
                SET @LogColumnValue = CAST(@Count AS VARCHAR(5));

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

                IF EXISTS (SELECT (OBJECT_ID('tempdb..#ColumnValuePair')))
                    DROP TABLE [#ColumnValuePair];
            END; -- end count > 0 and update method = 0
        END;

        -- End If Updatemethod = 0

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
        --create XML for @UpdateMethod !=0 (0=Update from SQL to MF only)
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

            -------------------------------------------------------------
            -- for full update updatemethod 1
            -------------------------------------------------------------
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

            -------------------------------------------------------------
            -- for filtered update update method 0
            -------------------------------------------------------------
            IF @IsFullUpdate = 0
            BEGIN
                SET @ProcedureStep = ' Prepare query for filters ';
                SET @DebugText = ' Filtered Update ';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- Sync error flag snippet
                -------------------------------------------------------------
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

                -------------------------------------------------------------
                -- Filter snippet
                -------------------------------------------------------------
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

                --end filters 
                -------------------------------------------------------------
                -- Compile XML query from snippets
                -------------------------------------------------------------
                SET @CreateXmlQuery = @CreateXmlQuery + ' FOR XML PATH(''''),ROOT(''form''))';

                IF @Debug > 9
                    SELECT @CreateXmlQuery AS [@CreateXmlQuery];

                SET @Params = N'@ObjVerXMLForUpdate XML OUTPUT';

                EXEC [sys].[sp_executesql] @CreateXmlQuery
                                          ,@Params
                                          ,@ObjVerXMLForUpdate OUTPUT;

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                -------------------------------------------------------------
                -- validate Objids
                -------------------------------------------------------------
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

                    IF ISNULL(@SyncErrorFlag, 0) = 0 -- exclude routine when sync flag = 1 is processed
                    BEGIN
                        EXEC [dbo].[spMFGetMissingobjectIds] @ObjIDs
                                                            ,@MFTableName
                                                            ,@missing = @objects OUTPUT;

                        SET @DebugText = ' sync flag 0:  Missing objects %s ';
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
                            SET @objects = @ObjIDs;
                            SET @DebugText = ' SyncFlag 1: Missing objects %s ';
                            SET @DebugText = @DefaultDebugText + @DebugText;

                            IF @Debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objects);
                            END;
                        END;
                    END;

                    SET @missingXML = @objects;

                    IF @Debug > 9
                        SELECT @missingXML AS [@missingXML];

                    -------------------------------------------------------------
                    -- set objverXML for update XML
                    -------------------------------------------------------------
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

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                -------------------------------------------------------------
                -- Set the objectver detail XML
                -------------------------------------------------------------
                SET @ProcedureStep = 'ObjverDetails for Update';

                -------------------------------------------------------------
                -- count detail items
                -------------------------------------------------------------
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

                SET @ProcedureStep = 'Set input XML parameters';
                SET @ObjVerXmlString = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
                SET @ObjIDsForUpdate = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
            END;
        END;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT @XML             AS [XML]
                      ,@ObjVerXmlString AS [ObjVerXmlString]
                      ,@ObjIDsForUpdate AS [@ObjIDsForUpdate]
                      ,@UpdateMethod    AS [UpdateMethod];
        END;

        -------------------------------------------------------------
        -- Get property MFIDs
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get property MFIDs';

        SELECT @MFIDs = @MFIDs + CAST(ISNULL([MFP].[MFID], '') AS NVARCHAR(10)) + ','
        FROM [INFORMATION_SCHEMA].[COLUMNS] AS [CLM]
            LEFT JOIN [dbo].[MFProperty]    AS [MFP]
                ON [MFP].[ColumnName] = [CLM].[COLUMN_NAME]
        WHERE [CLM].[TABLE_NAME] = @MFTableName;

        SELECT @MFIDs = LEFT(@MFIDs, LEN(@MFIDs) - 1); -- Remove last ','

        IF @Debug > 10
        BEGIN
            SELECT @MFIDs AS [List of Properties];
        END;

        SET @ProcedureStep = 'Update MFUpdateHistory';

        UPDATE [dbo].[MFUpdateHistory]
        SET [ObjectDetails] = @XML
           ,[ObjectVerDetails] = @ObjVerXmlString
        WHERE [Id] = @Update_ID;

        IF @Debug > 9
            RAISERROR(
                         'Proc: %s Step: %s ObjectVerDetails Count: %i'
                        ,10
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,@objVerDetails_Count
                     );

        -----------------------------------------------------
        --Process Wrapper Method
        -----------------------------------------------------
        SET @ProcedureStep = 'CLR Update in MFiles';
        SET @StartTime = GETUTCDATE();

        --IF @Debug > 99
        --BEGIN
        --    SELECT CAST(@XML AS NVARCHAR(MAX))
        --          ,CAST(@ObjVerXmlString AS NVARCHAR(MAX))
        --          ,CAST(@MFIDs AS NVARCHAR(MAX))
        --          ,CAST(@MFModifiedDate AS NVARCHAR(MAX))
        --          ,CAST(@ObjIDsForUpdate AS NVARCHAR(MAX));
        --END;

        ------------------------Added for checking required property null-------------------------------	
        EXECUTE @return_value = [dbo].[spMFCreateObjectInternal] @VaultSettings
                                                                ,@XML
                                                                ,@ObjVerXmlString
                                                                ,@MFIDs
                                                                ,@UpdateMethod
                                                                ,@MFModifiedDate
                                                                ,@ObjIDsForUpdate
                                                                ,@XmlOUT OUTPUT
                                                                ,@NewObjectXml OUTPUT
                                                                ,@SynchErrorObj OUTPUT  --Added new paramater
                                                                ,@DeletedObjects OUTPUT --Added new paramater
                                                                ,@ErrorInfo OUTPUT;

        IF @NewObjectXml = ''
            SET @NewObjectXml = NULL;

        IF @Debug > 10
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 10, 1, @ProcedureName, @ProcedureStep, @ErrorInfo);
        END;

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'Wrapper turnaround';
        SET @LogStatusDetail = 'Assembly';
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

        DECLARE @idoc2 INT;
        DECLARE @idoc3 INT;
        DECLARE @DeletedXML XML;

        SET @ProcedureStep = 'CLR Update in MFiles';

        -------------------------------------------------------------
        -- 
        -------------------------------------------------------------
        IF @Debug > 100
        BEGIN
            SELECT @DeletedObjects AS [DeletedObjects];

            SELECT @NewObjectXml AS [NewObjectXml];
        END;

        EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @NewObjectXml;

        IF @DeletedObjects IS NULL
        BEGIN

            --          --	EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @NewObjectXml;
            SET @DeletedXML = NULL;
        --(
        --    SELECT *
        --    FROM
        --    (
        --        SELECT [objectID]
        --        FROM
        --            OPENXML(@idoc2, '/form/Object/properties', 1)
        --            WITH
        --            (
        --                [objectID] INT '../@objectId'
        --               ,[propertyId] INT '@propertyId'
        --            )
        --        WHERE [propertyId] = 27
        --    ) AS [objVers]
        --    FOR XML AUTO
        --);
        END;
        ELSE
        BEGIN
            EXEC [sys].[sp_xml_preparedocument] @idoc3 OUTPUT, @DeletedObjects;

            SET @DeletedXML =
            (
                SELECT *
                FROM
                (
                    SELECT [objectID]
                    FROM
                        OPENXML(@idoc3, 'form/objVers', 1) WITH ([objectID] INT '@objectID')
                ) AS [objVers]
                FOR XML AUTO
            );
        END;

        IF @Debug > 100
            SELECT @DeletedXML AS [DeletedXML];

        -------------------------------------------------------------
        -- Remove records returned from M-Files that is not part of the class
        -------------------------------------------------------------

        -------------------------------------------------------------
        -- Update SQL
        -------------------------------------------------------------
        SET @StartTime = GETUTCDATE();

        IF (@Update_ID > 0)
            UPDATE [dbo].[MFUpdateHistory]
            SET [NewOrUpdatedObjectVer] = @XmlOUT
               ,[NewOrUpdatedObjectDetails] = @NewObjectXml
               ,[SynchronizationError] = @SynchErrorObj
               ,[DeletedObjectVer] = @DeletedXML
               ,[MFError] = @ErrorInfo
            WHERE [Id] = @Update_ID;

        DECLARE @NewOrUpdatedObjectDetails_Count INT
               ,@NewOrUpdateObjectXml            XML;

        SET @ProcedureStep = 'Prepare XML for update into SQL';
        SET @NewOrUpdateObjectXml = CAST(@NewObjectXml AS XML);

        SELECT @NewOrUpdatedObjectDetails_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewOrUpdateObjectXml.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'XML NewOrUpdatedObjectDetails returned';
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectDetails_Count AS VARCHAR(10));
        SET @LogColumnName = 'NewOrUpdatedObjectDetails';

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

        DECLARE @NewOrUpdatedObjectVer_Count INT
               ,@NewOrUpdateObjectVerXml     XML;

        SET @NewOrUpdateObjectVerXml = CAST(@XmlOUT AS XML);

        SELECT @NewOrUpdatedObjectVer_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewOrUpdateObjectVerXml.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'ObjVer returned';
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectVer_Count AS VARCHAR(10));
        SET @LogColumnName = 'NewOrUpdatedObjectVer';

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

        DECLARE @IDoc INT;

        --         SET @ProcedureName = 'SpmfUpdateTable';
        --    SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
        --        SET @StartTime = GETUTCDATE();
        CREATE TABLE [#ObjVer]
        (
            [ID] INT
           ,[ObjID] INT
           ,[MFVersion] INT
           ,[GUID] NVARCHAR(100)
           ,[FileCount] INT ---- Added for task 106
        );

        DECLARE @NewXML XML;

        SET @NewXML = CAST(@XmlOUT AS XML);

        DECLARE @NewObjVerDetails_Count INT;

        SELECT @NewObjVerDetails_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewXML.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        INSERT INTO [#ObjVer]
        (
            [MFVersion]
           ,[ObjID]
           ,[ID]
           ,[GUID]
           ,[FileCount]
        )
        SELECT [t].[c].[value]('(@objVersion)[1]', 'INT')           AS [MFVersion]
              ,[t].[c].[value]('(@objectId)[1]', 'INT')             AS [ObjID]
              ,[t].[c].[value]('(@ID)[1]', 'INT')                   AS [ID]
              ,[t].[c].[value]('(@objectGUID)[1]', 'NVARCHAR(100)') AS [GUID]
              ,[t].[c].[value]('(@FileCount)[1]', 'INT')            AS [FileCount] -- Added for task 106
        FROM @NewXML.[nodes]('/form/Object') AS [t]([c]);

        SET @Count = @@RowCount;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT *
                FROM [#ObjVer];
        END;

        DECLARE @UpdateQuery NVARCHAR(MAX);

        SET @UpdateQuery
            = '	UPDATE ['    + @MFTableName + ']
					SET [' + @MFTableName + '].ObjID = #ObjVer.ObjID
					,['    + @MFTableName + '].MFVersion = #ObjVer.MFVersion
					,['    + @MFTableName + '].GUID = #ObjVer.GUID
					,['    + @MFTableName
              + '].FileCount = #ObjVer.FileCount     ---- Added for task 106
					,Process_ID = 0
					,Deleted = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE [' + @MFTableName + '].ID = #ObjVer.ID';

        EXEC (@UpdateQuery);

        SET @ProcedureStep = 'Update Records in ' + @MFTableName + '';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnName = 'NewObjVerDetails';
        SET @LogColumnValue = CAST(@NewObjVerDetails_Count AS VARCHAR(10));

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

        DROP TABLE [#ObjVer];

        ----------------------------------------------------------------------------------------------------------
        --Update Process_ID to 2 when synch error occcurs--
        ----------------------------------------------------------------------------------------------------------
        SET @ProcedureStep = 'when synch error occurs';
        SET @StartTime = GETUTCDATE();

        ----------------------------------------------------------------------------------------------------------
        --Create an internal representation of the XML document. 
        ---------------------------------------------------------------------------------------------------------                
        CREATE TABLE [#SynchErrObjVer]
        (
            [ID] INT
           ,[ObjID] INT
           ,[MFVersion] INT
        );

        IF @Debug > 9
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

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
            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s Count %i ', 10, 1, @ProcedureName, @ProcedureStep, @SynchErrCount);

                PRINT 'Synchronisation error';

                IF @Debug > 10
                    SELECT *
                    FROM [#SynchErrObjVer];
            END;

            SET @LogTypeDetail = 'User';
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Error';
            SET @Validation_ID = 2;
            SET @LogColumnName = 'Synch Errors';
            SET @LogColumnValue = ISNULL(CAST(@SynchErrCount AS VARCHAR(10)), 0);

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

            -------------------------------------------------------------------------------------
            -- UPDATE THE SYNCHRONIZE ERROR
            -------------------------------------------------------------------------------------
            DECLARE @SynchErrUpdateQuery NVARCHAR(MAX);

            SET @DebugText = ' Update sync errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @SynchErrUpdateQuery
                = '	UPDATE ['    + @MFTableName + ']
					SET ['             + @MFTableName + '].ObjID = #SynchErrObjVer.ObjID	,[' + @MFTableName
                  + '].MFVersion = #SynchErrObjVer.MFVersion
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '     + CAST(@Update_ID AS VARCHAR(15)) + '
					FROM #SynchErrObjVer
					WHERE ['           + @MFTableName + '].ID = #SynchErrObjVer.ID';

            EXEC (@SynchErrUpdateQuery);

            ------------------------------------------------------
            -- LOGGING THE ERROR
            ------------------------------------------------------
            SET @DebugText = 'log errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            ------------------------------------------------------
            --Getting @SyncPrecedence from MFClasss table for @TableName
            --IF NULL THEN insert error in error log 
            ------------------------------------------------------
            DECLARE @SyncPrecedence INT;

            SELECT @SyncPrecedence = [SynchPrecedence]
            FROM [dbo].[MFClass]
            WHERE [TableName] = @TableName;

            IF @SyncPrecedence IS NULL
            BEGIN
                INSERT INTO [dbo].[MFLog]
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
                    SELECT 'Synchronization error occured while updating ObjID : ' + CAST([ObjID] AS NVARCHAR(10))
                           + ' Version : ' + CAST([MFVersion] AS NVARCHAR(10)) + '' AS [ErrorMessage]
                          ,@Update_ID                                               AS [Update_ID]
                          ,@TableName                                               AS [ErrorProcedure]
                          ,''                                                       AS [ExternalID]
                          ,'Synchronization Error'                                  AS [ProcedureStep]
                          ,'spMFUpdateTable'                                        AS [SPName]
                    FROM [#SynchErrObjVer]
                ) AS [vl];
            END;
        END;

        DROP TABLE [#SynchErrObjVer];

        -------------------------------------------------------------
        --Logging error details
        -------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Perform checking for SQL Errors ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        CREATE TABLE [#ErrorInfo]
        (
            [ObjID] INT
           ,[SqlID] INT
           ,[ExternalID] NVARCHAR(100)
           ,[ErrorMessage] NVARCHAR(MAX)
        );

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
            IF @Debug > 10
            BEGIN
                SELECT *
                FROM [#ErrorInfo];
            END;

            SET @DebugText = 'SQL Error logging errors found ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
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
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Error';
            SET @Validation_ID = 3;
            SET @LogColumnName = 'M-Files errors';
            SET @LogColumnValue = ISNULL(CAST(@ErrorInfoCount AS VARCHAR(10)), 0);

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

            INSERT INTO [dbo].[MFLog]
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

        ------------------------------------------------------------------
        SET @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));
        -------------------------------------------------------------------------------------
        -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
        -------------------------------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureName = 'spMFUpdateTableInternal';
        SET @ProcedureStep = 'Update property details from M-Files ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @StartTime = GETUTCDATE();

        IF (
               @NewObjectXml != '<form />'
               OR @NewObjectXml <> ''
               OR @NewObjectXml <> NULL
           )
        BEGIN
            IF @Debug > 10
                SELECT @NewObjectXml AS [@NewObjectXml before updateobjectinternal];

            EXEC @return_value = [dbo].[spMFUpdateTableInternal] @MFTableName
                                                                ,@NewObjectXml
                                                                ,@Update_ID
                                                                ,@Debug = @Debug
                                                                ,@SyncErrorFlag = @SyncErrorFlag;

            IF @return_value <> 1
                RAISERROR('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
        END;

		-------------------------------------------------------------
		-- Update MFaudithistory for all updated records
		-------------------------------------------------------------
	
	
		DECLARE @ObjectType INT
		SELECT @ObjectType = mot.MFID
		FROM MFclass mc
		INNER JOIN [dbo].[MFObjectType] AS [mot]
		ON mc.[MFObjectType_ID] = mot.[ID]
		WHERE mc.MFID = @ClassId
	
		SET @ParmDefinition = N'@Update_ID int, @ClassID int'
		SET @SelectQuery = N'
		UPDATE mah
		SET [mah].[StatusFlag] = 0,  StatusName = ''Identical'', [mah].[MFVersion] = mlv.[MFVersion], recID = mlv.id
		FROM '+ QUOTENAME(@MFTableName) + ' AS [mlv]
		INNER JOIN MFAuditHistory AS [mah]
		ON mlv.[ObjID] = mah.[ObjID] AND mah.[Class] = @ClassId
		WHERE [mlv].[Update_ID] = @Update_ID ;
		

		
		'

		
		EXEC sp_executeSQL @Stmt = @SelectQuery, @Params = @ParmDefinition, @ClassID = @ClassID, @Update_id = @Update_ID

			SET @ParmDefinition = N'@Update_ID int, @ClassID int,@ObjectType int'
		SET @SelectQuery = N'

		INSERT INTO [dbo].[MFAuditHistory]
		(
		    [RecID]
		   ,[SessionID]
		   ,[TranDate]
		   ,[ObjectType]
		   ,[Class]
		   ,[ObjID]
		   ,[MFVersion]
		   ,[StatusFlag]
		   ,[StatusName]
		)
		SELECT t.id, 0,GETDATE(), @ObjectType, @ClassId,t.[Objid],t.[MFVersion],0,''Identifical''
		FROM '+ QUOTENAME(@MFTableName) + ' AS [t]
		left JOIN MFAuditHistory AS [mah]
		ON t.[ObjID] = mah.[ObjID] AND mah.[Class] = @ClassId
		WHERE [t].[Update_ID] = @Update_ID AND mah.id IS null
		;'


		EXEC sp_executeSQL @Stmt = @SelectQuery, @Params = @ParmDefinition, @ClassID = @ClassID, @Update_id = @Update_ID, @ObjectType = @ObjectType

		-------------------------------------------------------------
		-- remove items from MFAuditHistory where items are not in class table after update
		-- this section will change when the result set for Audit History changes
		-------------------------------------------------------------

		IF @ObjIDs IS NOT NULL
        BEGIN 
		;
WITH CTE AS
(
SELECT mah.id, [mah].[ObjID] FROM [dbo].[MFAuditHistory] AS [mah]
INNER JOIN [dbo].[fnMFParseDelimitedString](@ObjIDs,',') AS [fmpds]
ON [fmpds].[ListItem] = [mah].[ObjID]
WHERE [mah].[Class] = @ClassId AND [mah].[StatusFlag] = 5
)
DELETE FROM [dbo].[MFAuditHistory]
WHERE id IN (SELECT id FROM CTE)
		END
        


        -------------------------------------------------------------------------------------
        --Checked whether all data is updated. #1360
        ------------------------------------------------------------------------------------ 
        --EXEC ('update '+ @MFTableName +' set Process_ID=1 where id =2')
        IF @UpdateMethod = 0
        BEGIN
            DECLARE @Sql NVARCHAR(1000) = 'SELECT @C = COUNT(*) FROM ' + @MFTableName + ' WHERE Process_ID=1';
            DECLARE @CountUpdated AS INT = 0;

            EXEC [sys].[sp_executesql] @Sql
                                      ,N'@C INT OUTPUT'
                                      ,@C = @CountUpdated OUTPUT;

			IF (@CountUpdated > 0) 
			SELECT @return_value = 3;

            IF (@CountUpdated > 0) AND @Debug > 0
            BEGIN
                RAISERROR('Error: All data is not updated', 10, 1, @ProcedureName, @ProcedureStep);

            END;
        END;

        --END of task #1360
        SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';
        -------------------------------------------------------------------------------------
        --Update deleted column if record is deleled from M Files
        ------------------------------------------------------------------------------------               
        SET @StartTime = GETUTCDATE();

        IF @DeletedXML IS NOT NULL
        BEGIN
            CREATE TABLE [#DeletedRecordId]
            (
                [ID] INT
            );

            INSERT INTO [#DeletedRecordId]
            (
                [ID]
            )
            SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ID]
            FROM @DeletedXML.[nodes]('objVers') AS [t]([c]);

            SET @Count = CAST(@@RowCount AS VARCHAR(10));

            IF @Debug > 9
            BEGIN
                SELECT 'Deleted' AS [Deletions]
                      ,[ID]
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

            IF @Debug > 100
            BEGIN
                SELECT *
                FROM [#DeletedRecordId] AS [dri];

                SELECT @DeletedRecordQuery;
            END;

            EXEC (@DeletedRecordQuery);

            SET @Count = CAST(@@RowCount AS VARCHAR(10));
            SET @ProcedureStep = 'Deleted records';
            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Deletions';
            SET @LogStatusDetail = 'InProgress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'Deletions';
            SET @LogColumnValue = ISNULL(CAST(@Count AS VARCHAR(10)), 0);

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

            IF @UpdateMethod = 1
               AND @RetainDeletions = 0
            BEGIN
                SET @Query = N'Delete from ' + QUOTENAME(@MFTableName) + ' Where deleted = 1';

                EXEC (@Query);
            END;

            DROP TABLE [#DeletedRecordId];
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
                     'Proc: %s Step: %s ReturnValue %i ProcessCompleted '
                    ,10
                    ,1
                    ,@ProcedureName
                    ,@ProcedureStep
                    ,@return_value
                 );

    -------------------------------------------------------------
    -- Check if precedence is set and update records with synchronise errors
    -------------------------------------------------------------
    IF @SyncPrecedence IS NOT NULL
    BEGIN
        EXEC [dbo].[spMFUpdateSynchronizeError] @TableName = @MFTableName           -- varchar(100)
                                               ,@Update_ID = @Update_IDOut          -- int
                                               ,@ProcessBatch_ID = @ProcessBatch_ID -- int
                                               ,@Debug = 0;                         -- int
    END;

    -------------------------------------------------------------
    -- Finalise logging
    -------------------------------------------------------------
    IF @return_value = 1
    BEGIN
        SET @ProcedureStep = 'Updating Table ';
        SET @LogType = 'Debug';
        SET @LogText = 'Update ' + @TableName + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
        SET @LogStatus = N'Completed';

        UPDATE [dbo].[MFUpdateHistory]
        SET [UpdateStatus] = 'completed'
        --             [SynchronizationError] = @SynchErrorXML
        WHERE [Id] = @Update_ID;

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                            ,@LogType = @LogType
                                                              -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        SET @LogTypeDetail = @LogType;
        SET @LogTextDetail = @LogText;
        SET @LogStatusDetail = @LogStatus;
        SET @Validation_ID = NULL;
        SET @LogColumnName = NULL;
        SET @LogColumnValue = NULL;

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

        RETURN 1; --For More information refer Process Table
    END;
    ELSE
    BEGIN
        UPDATE [dbo].[MFUpdateHistory]
        SET [UpdateStatus] = 'partial'
        WHERE [Id] = @Update_ID;

        SET @LogStatus = N'Partial Successful';
        SET @LogText = N'Partial Completed';
        SET @LogType = 'Status';

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

    --    RETURN 0; --For More information refer Process Table
    END;

    IF @SynchErrCount > 0
    BEGIN
        SET @LogStatus = N'Errors';
        SET @LogText = @ProcedureStep + 'with sycnronisation errors: ' + @TableName + ':Return Value 2 ';
        SET @LogType = 'Status';

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

    --          RETURN 0;
    END;

    --      ELSE
    BEGIN
        IF @ErrorInfoCount > 0
            SET @LogStatus = N'Partial Successful';

        SET @LogText = @LogText + ':' + @ProcedureStep + 'with M-Files errors: ' + @TableName + 'Return Value 3';
        SET @LogType = CASE
                           WHEN @MFTableName = 'MFUserMessages' THEN
                               'Status'
                           ELSE
                               'Message'
                       END;

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                            ,@ProcessType = @ProcessType
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

        RETURN 0;
    END;
END TRY
BEGIN CATCH
    IF @@TranCount <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    SET NOCOUNT ON;

    UPDATE [dbo].[MFUpdateHistory]
    SET [UpdateStatus] = 'failed'
    WHERE [Id] = @Update_ID;

    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ProcedureStep]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[Update_ID]
       ,[ErrorLine]
    )
    VALUES
    ('spMFUpdateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE()
    ,ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

    IF @Debug > 9
    BEGIN
        SELECT ERROR_NUMBER()    AS [ErrorNumber]
              ,ERROR_MESSAGE()   AS [ErrorMessage]
              ,ERROR_PROCEDURE() AS [ErrorProcedure]
              ,@ProcedureStep    AS [ProcedureStep]
              ,ERROR_STATE()     AS [ErrorState]
              ,ERROR_SEVERITY()  AS [ErrorSeverity]
              ,ERROR_LINE()      AS [ErrorLine];
    END;

    SET NOCOUNT OFF;

    RETURN -1; --For More information refer Process Table
END CATCH;
GO


/*rST**************************************************************************


Purpose
=======
This procedure get and push data between M-Files and SQL based on a number of filters.  It is very likely that this procedure will be built into your application or own procedures as part of the process of creating, updating, inserting records from your application.
	
When calling this procedure in a query or via another procedure it will perform the update in batch mode on all the rows with a valid process_id.

When the requirements for transactional mode has been met and a record is updated/inserted in the class table with process_id = 1, a trigger will automatically fire spMFUpdateTable to update SQL to M-Files.
	
A number of procedures is included in the Connector that use this procedure including:
	- spMFUpdateMFilesToSQL
	- spMFUpdateTablewithLastModifiedDate
	- spMFUpdateTableinBatches
	- spMFUpdateAllIncludedInAppTables
	- spMFUpdateItembyItem
							   
Prerequisits
============
	From M-Files to SQL 
	===================
	Process_id must be 0. All other rows are ignored.
	
	
	From SQL to M-Files - batch mode
	================================
	Process_id must be 1 for rows to be updated or added to M-Files
	
	From SQL to M-Files - transactional mode
	========================================
	Set IncludedInApp Column = 2 in MFClass for the required class
	
Warnings
========

Examples
--------

.. code:: sql

    DECLARE @return_value int

    EXEC    @return_value = [dbo].[spMFUpdateTable]
            @MFTableName = N'MFCustomerContact',
            @UpdateMethod = 1,
            @UserId = NULL,
            @MFModifiedDate = null,
            @update_IDOut = null,
            @ObjIDs = NULL,
            @ProcessBatch_ID = null,
            @SyncErrorFlag = 0,
            @RetainDeletions = 0,
            @Debug = 0

    SELECT  'Return Value' = @return_value

    GO

Execute the core procedure with all parameters

----

.. code:: sql

    DECLARE @return_value int
    DECLARE @update_ID INT, @processBatchID int

    EXEC @return_value = [dbo].[spMFUpdateTable]
         @MFTableName = N'YourTableName', -- nvarchar(128)
         @UpdateMethod = 1, -- int
         @Update_IDOut = @update_ID output, -- int
         @ProcessBatch_ID = @processBatchID output

    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @processBatchID

    SELECT  'Return Value' = @return_value

    GO

Update from and to M-Files with all optional parameters set to default.

----

.. code:: sql

    --From M-Files to SQL
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 1
    --or
    EXEC spMFupdateTable 'MFCustomer',1

    --From SQL to M-Files
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 0
    --or
    EXEC spMFupdateTable 'MFCustomer',0

Update from and to M-Files with all optional parameters set to default.

Changelog
---------

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2015-04-08  Dev 2      deleting property value from M-Files (Task 57)
2015-04-16  Dev 2      Adding update table details to MFUpdateHistory table
2015-04-23  Dev 2      Removing Last modified & Last modified by from Update data
2015-06-24  Dev 2      Skip the object failed to update in M-Files
2015-06-30  Dev 2      New error Tracing and Return Value as LeRoux instruction
2015-07-18  Dev 2      New parameter add in spMFCreateObjectInternal
2016-02-22  LC         Improve debugging information; Remove is_template message when updatemethod = 1
2016-03-10  Dev 2      Input variable @FromCreateDate  changed to @MFModifiedDate
2016-03-10  Dev 2      New input variable added (@ObjIDs)
2016-08-18  lc         add defaults to parameters
2016-08-20  LC         add Update_ID as output paramter
2016-08-22  LC         Update settings index
2016-08-22  lc         change objids to NVARCHAR(4000)
2016-09-21  lc         Removed @UserName,@Password,@NetworkAddress and @VaultName parameters and fectch it as comma separated list in @VaultSettings parameter dbo.fnMFVaultSettings() function
2016-10-10  lc         Change of name of settings table
2107-05-12  lc         Set processbatchdetail column detail
2017-06-22  LC         add ability to modify external_id
2017-07-03  lc         modify objids filter to include ids not in sql
2017-07-06  LC         add update of filecount column in class table
2017-08-22  Dev2       add sync error correction
2017-08-23  Dev2       add exclude null properties from update
2017-10-01  LC         fix bug with length of fields
2017-11-03  Dve2       Added code to check required property has value or not
2018-04-04  Dev2       Added Licensing module validation code.
2018-05-16  LC         Fix conversion of float to nvarchar
2018-06-26  LC         Improve reporting of return values
2018-08-01  LC         New parameter @RetainDeletions to allow for auto removal of deletions Default = NO
2018-08-01  lc         Fix deletions of record bug
2018-08-23  LC         Fix bug with presedence = 1
2018-10-20  LC         Set Deleted to != 1 instead of = 0 to ensure new records where deleted is not set is taken INSERT
2018-10-24  LC         resolve bug when objids filter is used with only one object
2018-10-30  LC         removing cursor method for update method 0 and reducing update time by 100%
2018-11-05  LC         include new parapameter to validate class and property structure
2018-12-06  LC         fix bug t.objid not found
2018-12-18  LC         validate that all records have been updated, raise error if not
2019-01-03  LC         fix bug for updating time property
2019-01-13  LC         fix bug for uniqueidentifyer type columns (e.g. guid)
2019-05-19  LC         terminate early if connection cannot be established
2019-06-17  LC         UPdate MFaudithistory with changes
2019-07-13  LC         Add working that not all records have been updated
2019-07-26  LC         Update removing of redundant items form AuditHistory
==========  =========  ========================================================

**rST*************************************************************************/
