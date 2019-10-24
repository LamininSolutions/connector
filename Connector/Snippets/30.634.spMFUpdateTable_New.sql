
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTable]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateTable'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.2.7.46'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 08-04-2015  Dev 2	   deleting property value from M-Files (Task 57)
  ** 16-04-2015  Dev 2	   Adding update table details to MFUpdateHistory table
  ** 23-04-2015  Dev 2      Removing Last modified & Last modified by from Update data
  ** 24-06-2015  Dev 2	   Skip the object failed to update in M-Files
  ** 30-06-2015  Dev 2	   New error Tracing and Return Value as LeRoux instruction
  ** 18-07-2015  Dev 2	   New parameter add in spMFCreateObjectInternal
  ** 22-2-2016   LC        Improve debugging information; Remove is_template message when updatemethod = 1
  ** 10-03-2016  Dev 2	   Input variable @FromCreateDate  changed to @MFModifiedDate
  ** 10-03-2016  Dev 2	   New input variable added (@ObjIDs)

  18-8-2016 lc add defaults to parameters
  20-8-2016 LC add Update_ID as output paramter
  2016-8-22	LC	Update settings index
  2016-8-22	lc change objids to NVARCHAR(4000)
  2016-09-21  Removed @UserName,@Password,@NetworkAddress and @VaultName parameters and fectch it as comma separated list in @VaultSettings parameter 
              dbo.fnMFVaultSettings() function
  2016-10-10  Change of name of settings table
  2107-5-12		Set processbatchdetail column detail
2017-06-22	LC	add ability to modify external_id
2017-07-03  lc  modify objids filter to include ids not in sql
2017-07-06	LC	add update of filecount column in class table
2017-08-22	Dev2	add sync error correction
2017-08-23	Dev2	add exclude null properties from update
2017-10-1	LC		fix bug with length of fields
2017-11-03 Dve2     Added code to check required property has value or not
2018-04-04 Dev2     Added Licensing module validation code.
2018-5-16	LC		Fix conversion of float to nvarchar
2018-6-26	LC		Improve reporting of return values
2018-08-01	LC		New parameter @RetainDeletions to allow for auto removal of deletions Default = NO
2018-08-01 lc		Fix deletions of record bug
2018-08-23 LC		Fix bug with presedence = 1
2018-10-20 LC		Set Deleted to != 1 instead of = 0 to ensure new records where deleted is not set is taken INSERT 
2018-10-24 LC		resolve bug when objids filter is used with only one object
*/

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
   ,@Debug SMALLINT = 0
)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Change the class and update any property  of an object

  
  ** Date:				27-03-2015
  ********************************************************************************
 
  ******************************************************************************/
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
        SELECT *
        FROM [sys].[objects]
        WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND [type] IN ( N'U' )
    )

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

    EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                                           ,@ProcessType = @ProcessType
                                                           ,@LogType = @LogType
                                                           ,@LogText = @LogText
                                                           ,@LogStatus = @LogStatus
                                                           ,@debug = @Debug;

    IF @Debug > 9
    BEGIN
        SET @DebugText = @DefaultDebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
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
    --To Get Table_ID 
    -----------------------------------------------------
    SET @ProcedureStep = 'Get Table ID';
    SET @TableName = @MFTableName;

    --       SET @TableName = REPLACE(@TableName, '_', ' ');
    SELECT @Table_ID = [object_id]
    FROM [sys].[objects]
    WHERE [name] = @MFTableName;

    IF @Debug > 9
    BEGIN
        SET @DebugText = @DefaultDebugText + 'Table: %s';

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
    END;

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

    IF @ClassId IS NOT NULL
    BEGIN
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
        --SELECT THE ROW DETAILS DEPENDS ON USER INPUT
        -----------------------------------------------------
        SET @StartTime = GETUTCDATE();

        IF @UpdateMethod = 1
           AND @RetainDeletions = 0
        BEGIN
            SET @Query = N'Delete from ' + QUOTENAME(@MFTableName) + ' Where deleted = 1';

            EXEC (@Query);
        END;

        IF @UpdateMethod = 0 --- processing of process_ID = 1
        BEGIN
            DECLARE @Count          NVARCHAR(10)
                   ,@SelectQuery    NVARCHAR(MAX)
                   ,@ParmDefinition NVARCHAR(500);

            IF @SyncErrorFlag = 1
            BEGIN
                SET @SelectQuery
                    = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName
                      + '] WHERE Process_ID = 2 AND Deleted != 1';
            END;
            ELSE
            BEGIN
                SET @SelectQuery
                    = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName
                      + '] WHERE Process_ID = 1 AND Deleted != 1';
            END;

            -------------------------------------------------------------
            -- Get column for name or title and set to 'Auto' if left blank
            -------------------------------------------------------------
            DECLARE @Columnname NVARCHAR(100)
                   ,@SQL        NVARCHAR(MAX);

            SELECT @Columnname = [ColumnName]
            FROM [dbo].[MFProperty]
            WHERE [MFID] = 0;

            SET @SQL = N'UPDATE ' + @MFTableName + '
					SET ' + @Columnname + ' = ''Auto''
					WHERE ' + @Columnname + ' IS NULL AND process_id = 1';

            --		PRINT @SQL
            EXEC (@SQL);

            -------------------------------------------------------------
            -- PROCESS FULL UPDATE FOR UPDATE METHOD 0
            -------------------------------------------------------------
            DECLARE @lastModifiedColumn NVARCHAR(100);

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
                    SET @SelectQuery = @SelectQuery + ' AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + '''';
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

            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Count of process_ID 1 records ' + CAST(@Count AS NVARCHAR(256));
            SET @LogStatusDetail = 'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'process_ID 1';
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

            ----------------------------------------------------------------------------------------------------------
            --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
            ----------------------------------------------------------------------------------------------------------
            SET @StartTime = GETUTCDATE();
            SET @DebugText = 'Count of records i%';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Start cursor Processing UpdateMethod 0';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            IF (@Count > '0' AND @UpdateMethod != 1)
            BEGIN
                DECLARE @XML NVARCHAR(MAX);

                --START OF NEW SECTION

                --END;
                DECLARE @PerformanceMeasure FLOAT
                       ,@vsql               AS NVARCHAR(MAX)
                       ,@vquery             AS NVARCHAR(MAX)
                       ,@XMLFile            XML;

                IF @Debug = 100
                    SET @StartTime = GETDATE();
                    ;

                SET @FullXml = NULL;
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Set filters for Updatemethod 0';

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
                            = @vquery + ' AND t.ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs
                              + ','','',''))';
                    END;
                END;

                IF @Debug = 100
                    SELECT @vquery;

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
                       ,@colsPivot   AS NVARCHAR(MAX);

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 2, 3, 8 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                IF @Debug = 100
                    SELECT @colsUnpivot;

                SET @Query
                    = '
 select ID, Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS ColumnValue
        from ' + QUOTENAME(@MFTableName) + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where ' + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 1, 5, 9 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 4, 6 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 12 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 7 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @Query
                    = 'INSERT INTO  #ColumnValuePair

SELECT ID,ObjID,MFVersion,ExternalID,ColumnName,ColumnValue,NULL,null,null from 
(' +                @Query + ') list';

                IF @Debug = 100
                    SELECT @Query;

                EXEC (@Query);

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

                --SELECT *
                --FROM [#ColumnValuePair] AS [cvp];
                --                 UPDATE [cp]
                --SET [cp].[ColumnValue] = CASE
                --                             WHEN [cp].[ColumnValue] IS NULL THEN
                --                                 NULL
                --                             ELSE
                --                                 CONVERT(DATE, CAST([cp].[ColumnValue] AS NVARCHAR(100)))
                --                         END
                --FROM [#ColumnValuePair] AS [cp]
                --WHERE [cp].[DataType] = 7;
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
                IF @Debug = 100
                    SELECT @XMLFile AS [@XMLFile];

                SET @FullXml
                    = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

                IF @Debug = 100
                BEGIN
                    SELECT @FullXml;

                    SET @PerformanceMeasure = DATEDIFF(MILLISECOND, @StartTime, GETDATE());

                    SELECT @PerformanceMeasure AS [TempTableTotal];

                    SELECT *
                    FROM [#ColumnValuePair] AS [cvp];
                END;
            END;

            --END IF NEW SECTION
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

        END; -- End If Updatemethod = 0

   
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

                IF @Debug > 9
                    SELECT @ObjIDsForUpdate AS [@ObjIDsForUpdate];
            END;
        END;

        SET @ProcedureStep = 'Executing Wrapper Method';

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT @XML             AS [XML]
                      ,@ObjVerXmlString AS [ObjVerXmlString]
                      ,@UpdateMethod    AS [UpdateMethod];
        END;

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
        --Wrapper Method
        -----------------------------------------------------
        --                         SET @ProcedureName = 'Spmfcreateobjectinternal ';
        SET @ProcedureStep = 'CLR Update in MFiles';
        SET @StartTime = GETUTCDATE();

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            SELECT @ObjIDsForUpdate AS [@ObjIDsForUpdate];
        END;

        ------------------------Added for checking required property null-------------------------------		 
        IF @UpdateMethod = 0
        BEGIN
            DECLARE @Idoc1 INT;

            --Parse the Input XML
            EXEC [sys].[sp_xml_preparedocument] @Idoc1 OUTPUT, @XML;

            SELECT [objID]
                  ,[propertyId]
                  ,[property]
                  ,[dataType]
            INTO [#PropetyDefTemp]
            FROM
                OPENXML(@Idoc1, '/form/Object/class/property', 1)
                WITH
                (
                    [objID] VARCHAR(10) '/form/Object/@objID'
                   ,[propertyId] INT '@id'
                   ,[property] NVARCHAR(1000) 'text()'
                   ,[dataType] NVARCHAR(1000) '@dataType'
                );

            SELECT [Property_MFID]
            INTO [#RequiredPropTemp]
            FROM [dbo].[MFvwMetadataStructure]
            WHERE [TableName] = @MFTableName
                  AND [Required] = 1;

            IF EXISTS
            (
                SELECT TOP 1
                       [PDT].[propertyId]
                FROM [#PropetyDefTemp]             [PDT]
                    INNER JOIN [#RequiredPropTemp] [RPT]
                        ON [PDT].[propertyId] = [RPT].[Property_MFID]
                WHERE [PDT].[property] IS NULL
                      OR [PDT].[property] = N''
            )
            BEGIN
                DECLARE @RequiredPropertyName VARCHAR(100)
                       ,@ErrMsg               NVARCHAR(250);

                SELECT @RequiredPropertyName = STUFF((
                                                         SELECT ', ' + [P].[ColumnName]
                                                         FROM [#PropetyDefTemp]             [PDT]
                                                             INNER JOIN [#RequiredPropTemp] [RPT]
                                                                 ON [PDT].[propertyId] = [RPT].[Property_MFID]
                                                             INNER JOIN [dbo].[MFProperty]  [P]
                                                                 ON [PDT].[propertyId] = [P].[MFID]
                                                         WHERE [PDT].[property] IS NULL
                                                               OR [PDT].[property] = N''
                                                         FOR XML PATH('')
                                                     )
                                                    ,1
                                                    ,2
                                                    ,''
                                                    );

                SELECT @ErrMsg = 'Required property ' + @RequiredPropertyName + ' has null value';

                DROP TABLE [#PropetyDefTemp];
                DROP TABLE [#RequiredPropTemp];

                RAISERROR(
                             'Proc: %s Step: %s ErrorInfo %s '
                            ,16
                            ,1
                            ,'spmfUpdateTable'
                            ,'Checking for null for Required property'
                            ,@ErrMsg
                         );
            END;

            DROP TABLE [#PropetyDefTemp];
            DROP TABLE [#RequiredPropTemp];
        END;

        SET @StartTime = GETUTCDATE();

        IF @Debug = 99
        BEGIN
            SELECT CAST(@XML AS NVARCHAR(MAX))
                  ,CAST(@ObjVerXmlString AS NVARCHAR(MAX))
                  ,CAST(@MFIDs AS NVARCHAR(MAX))
                  ,CAST(@MFModifiedDate AS NVARCHAR(MAX))
                  ,CAST(@ObjIDsForUpdate AS NVARCHAR(MAX));
        END;

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
        DECLARE @DeletedXML XML;

        IF @Debug > 100
        BEGIN
            SELECT @DeletedObjects AS [DeletedObjects];

            SELECT @NewObjectXml AS [NewObjectXml];
        END;

        IF @DeletedObjects IS NULL
        BEGIN
            EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @NewObjectXml;

            SET @DeletedXML =
            (
                SELECT *
                FROM
                (
                    SELECT [objectID]
                    FROM
                        OPENXML(@idoc2, '/form/Object/properties', 1)
                        WITH
                        (
                            [objectID] INT '../@objectId'
                           ,[propertyId] INT '@propertyId'
                        )
                    WHERE [propertyId] = 27
                ) AS [objVers]
                FOR XML AUTO
            );
        END;
        ELSE
        BEGIN
            EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @DeletedObjects;

            SET @DeletedXML =
            (
                SELECT *
                FROM
                (
                    SELECT [objectID]
                    FROM
                        OPENXML(@idoc2, 'form/objVers', 1) WITH ([objectID] INT '@objectID')
                ) AS [objVers]
                FOR XML AUTO
            );
        END;

        IF @Debug > 100
            SELECT @DeletedXML AS [DeletedXML];

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

        IF (@NewObjectXml != '<form />')
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

        SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';
        -------------------------------------------------------------------------------------
        --Update deleted column if record is deleled from M Files
        ------------------------------------------------------------------------------------               
        SET @StartTime = GETUTCDATE();

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