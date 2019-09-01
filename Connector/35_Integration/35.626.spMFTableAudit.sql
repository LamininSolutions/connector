PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTableAudit]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFTableAudit' -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.52'   -- varchar(50)
                                    ,@UpdateFlag = 2;                -- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  2016-8-22		lc			change objids to NVARCHAR(4000)
  2017-08-28	lc		change sequence of params
  2017-08-28	lc			add logging
  2017-08-28	lc		add param for update required
  2017-12-27	lc		remove incorrect error message
  2017-12-28	lc		change insert to merge on audit table, 
  2018-08-01	lc		resolve issue with having try catch in transaction processing
  2018-12-15	lc		add ability to get result for selected objids
  2019-4-11	LC			add validation table exists
  2019-4-11		lc		add large table protection
2019-4-11		LC		fix collection object type in table	
2019-5-18		LC		add additional exception for deleted in SQL but not deleted in MF
2019-6-22		LC		objid parameter not yet functional
2019-08-16		LC		fix bug for removing destroyed objects
  ---------------
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFTableAudit' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFTableAudit]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFTableAudit]
(
    @MFTableName NVARCHAR(128)
   ,@MFModifiedDate DATETIME = NULL    --NULL to select all records
   ,@ObjIDs NVARCHAR(4000) = NULL
   ,@SessionIDOut INT OUTPUT           -- output of session id
   ,@NewObjectXml NVARCHAR(MAX) OUTPUT -- return from M-Files
   ,@DeletedInSQL INT = 0 OUTPUT
   ,@UpdateRequired BIT = 0 OUTPUT     --1 is set when the result show a difference between MFiles and SQL  
   ,@OutofSync INT = 0 OUTPUT          -- > 0 eminent Sync Error when update from SQL to MF is processed
   ,@ProcessErrors INT = 0 OUTPUT      -- > 0 unfixed errors on table
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0                -- use 2 for listing of full tables during debugging
)
AS
/*rST**************************************************************************

==============
spMFTableAudit
==============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFModifiedDate datetime
    fixme description
  @ObjIDs nvarchar(4000)
    fixme description
  @SessionIDOut int (output)
    fixme description
  @NewObjectXml nvarchar(max) (output)
    fixme description
  @DeletedInSQL int (output)
    fixme description
  @UpdateRequired bit (output)
    fixme description
  @OutofSync int (output)
    fixme description
  @ProcessErrors int (output)
    fixme description
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
 /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Get all Records from MFiles for the selection
  **  					
  **
  ** Author:			leRoux Cilliers
  ** Date:				17-07-2016

  USAGE
  Declare @SessionIDOut int, @return_Value int, @NewXML nvarchar(max)
  exec @return_Value = spMFTableAudit 'MFOtherdocument' , null, null, 1, @SessionIDOut = @SessionIDOut output, @NewObjectXml = @NewXML output
  Select @SessionIDOut ,@return_Value, @NewXML


  ******************************************************************************/

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
------------------------------------------------------------- 
SET NOCOUNT ON;

DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = 'Table Audit';

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
DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFTableAudit';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
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
                                          ,@LogText = @LogText
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
                                          ,@debug = @Debug;

BEGIN TRY


    SET XACT_ABORT ON;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id              INT
           ,@objID           INT
           ,@ObjectIdRef     INT
           ,@ObjVersion      INT
           ,@XMLOut          NVARCHAR(MAX)
           ,@ObjIDsForUpdate NVARCHAR(MAX)
           ,@MinObjid        INT
           ,@MaxObjid        INT
           ,@DefaultDate     DATETIME       = '2000-01-01'
                                           --             @Output NVARCHAR(200) ,
           ,@FullXml         XML           --
           ,@SynchErrorObj   NVARCHAR(MAX) --Declared new paramater
           ,@DeletedObjects  NVARCHAR(MAX) --Declared new paramater
           ,@ObjectId        INT
           ,@ClassId         INT
           ,@ErrorInfo       NVARCHAR(MAX)
           ,@MFIDs           NVARCHAR(2500) = ''
           ,@RunTime         VARCHAR(20);
    DECLARE @Idoc INT;

    SET @StartTime = GETUTCDATE();

    IF EXISTS
    (
        SELECT *
        FROM [sys].[objects]
        WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND [type] IN ( N'U' )
    )
    BEGIN

        --        BEGIN TRAN [main];
        --IF @Debug > 0
        --BEGIN
        --    SET @RunTime = CONVERT(VARCHAR(20), GETDATE());

        --    RAISERROR('Proc: %s Step: %s Time: %s', 10, 1, @ProcedureName, @ProcedureStep, @RunTime);
        --END;

        -----------------------------------------------------
        --Set Object Type Id and class id
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Object Type and Class';

        SELECT @ObjectIdRef = [mc].[MFObjectType_ID]
              ,@ObjectId    = [ob].[MFID]
              ,@ClassId     = [mc].[MFID]
        FROM [dbo].[MFClass]                AS [mc]
            INNER JOIN [dbo].[MFObjectType] AS [ob]
                ON [ob].[ID] = [mc].[MFObjectType_ID]
        WHERE [mc].[TableName] = @MFTableName;

        SELECT @ObjectId = [MFID]
        FROM [dbo].[MFObjectType]
        WHERE [ID] = @ObjectIdRef;

        IF @Debug > 0
        BEGIN
            RAISERROR(
                         'Proc: %s Step: %s ObjectType: %i Class: %i'
                        ,10
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,@ObjectId
                        ,@ClassId
                     );

        --SELECT *
        --FROM [dbo].[MFClass]
        --WHERE [MFID] = @ClassId;
        END;

        --SET @DebugText = 'ObjectIDs for update %s';
        --SET @DebugText = @DefaultDebugText + @DebugText;
        --SET @ProcedureStep = '';

        --IF @Debug > 0
        --BEGIN
        --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDsForUpdate);
        --END;

		-------------------------------------------------------------
		-- Get class table name
		-------------------------------------------------------------
	DECLARE @ClassTableColumn NVARCHAR(100)
		SELECT @ClassTableColumn = [ColumnName] FROM MFproperty WHERE mfid = 100
        -----------------------------------------------------
        --Wrapper Method
        -----------------------------------------------------
        SET @ProcedureStep = 'Filters';

        SELECT @ObjIDsForUpdate = @ObjIDs;

        SET @DebugText = ':on objids %s ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDsForUpdate);
        END;

        SET @DefaultDate = CASE
                               WHEN @ObjIDs IS NOT NULL THEN
                                   @DefaultDate
                               WHEN @MFModifiedDate IS NULL THEN
                                   @DefaultDate
                               ELSE
                                   @MFModifiedDate
                           END;
        SET @DebugText = ' :on date ' + CAST(@DefaultDate AS NVARCHAR(30));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @ProcedureStep = 'Wrapper: getObjectvers ';

        EXEC @return_value = [dbo].[spMFGetObjectvers] @TableName = @MFTableName         -- nvarchar(max)
                                                      ,@dtModifiedDate = @DefaultDate    -- datetime
                                                      ,@MFIDs = @ObjIDs                  -- nvarchar(max)
                                                      ,@outPutXML = @NewObjectXml OUTPUT -- nvarchar(max)
                                                      ,@ProcessBatch_ID = @ProcessBatch_ID
                                                      ,@Debug = @Debug;

        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @NewObjectXml;

    
        BEGIN
            SET @ProcedureStep = 'Create Temp table';

            CREATE TABLE [#AllObjects]
            (
                [ID] INT
               ,[Class] INT
               ,[ObjectType] INT
               ,[ObjID] INT
               ,[MFVersion] INT
               ,[StatusFlag] SMALLINT
            );

            CREATE INDEX [idx_AllObjects_ObjID] ON [#AllObjects] ([ObjID]);
          
            SET @ProcedureStep = ' Insert items in Temp Table';

            WITH [cte]
            AS (SELECT [xmlfile].[objId]
                      ,[xmlfile].[MFVersion]
                      --       ,[xmlfile].[GUID]
                      ,[xmlfile].[ObjType]
                FROM
                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        [objId] INT './@objectID'
                       ,[MFVersion] INT './@version'
                       --         ,[GUID] NVARCHAR(100) './@objectGUID'
                       ,[ObjType] INT './@objectType'
                    ) [xmlfile])
            --SELECT *
            --INTO [#AllObjects]
            --FROM [cte];
            INSERT INTO [#AllObjects]
            (
                [Class]
               ,[ObjectType]
               ,[MFVersion]
               ,[ObjID]
            )
            SELECT @ClassId
                  ,[cte].[ObjType]
                  ,[cte].[MFVersion]
                  ,[cte].[objId]
            FROM [cte];

            EXEC [sys].[sp_xml_removedocument] @Idoc;

            SET @rowcount = @@RowCount;
            SET @ProcedureStep = 'Get Object Versions';
            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Objects from M-Files';
            SET @LogStatusDetail = 'Status';
            SET @LogColumnName = 'Objvers returned';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
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
                                                      ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
                                                      ,@debug = 0;

            IF @Debug > 0
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
                    SELECT 'PreFlag',*
                    FROM [#AllObjects] AS [ao];
			END

            DECLARE @Query     NVARCHAR(MAX)
                   ,@SessionID INT
                   ,@TranDate  DATETIME
                   ,@Params    NVARCHAR(MAX);

            SELECT @TranDate = GETDATE();

            SET @ProcedureStep = 'Get Session ID';

            -- check if MFAuditHistory has been initiated
            SELECT @count = COUNT(*)
            FROM [dbo].[MFAuditHistory] AS [mah];

            SELECT @SessionID = CASE
                                    WHEN @SessionIDOut IS NULL
                                         AND @count = 0 THEN
                                        1
                                    WHEN @SessionIDOut IS NULL
                                         AND @count > 0 THEN
            (
                SELECT MAX(ISNULL([SessionID], 0)) + 1 FROM [dbo].[MFAuditHistory]
            )
                                    ELSE
                                        @SessionIDOut
                                END;

            SET @DebugText = ' Session ID %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SessionID);
            END;

            -------------------------------------------------------------
            -- pre validations
            -------------------------------------------------------------
            /*

0 = identical : [ao].[MFVersion] = [t].[MFVersion] AND ISNULL([t].[deleted], 0) = 0
1 = MF IS Later : [ao].[MFVersion] > [t].[MFVersion] AND [t].[deleted] = 0 
2 = SQL is later : ao.[MFVersion] < ISNULL(t.[MFVersion],-1) 
3 = Deleted in MF : t.deleted = 1 and isnull(ao.MFversion,0) = 0
4 =  SQL to be Deleted : WHEN ao.[MFVersion]  IS NULL and isnull(t.deleted,0) = 0 and isnull(t.objid,0) > 0                                              
5 =  Not in SQL : N t.[MFVersion] is null and ao.[MFVersion] is not null                                                            
6 = Not yet process in SQL : t.id IS NOT NULL AND t.objid IS NULL


*/
            SET @ProcedureStep = ' set id and flags ';

            SELECT @Query
                = N'UPDATE ao
SET ao.[ID] = t.id
,StatusFlag = CASE WHEN [ao].[MFVersion] = ISNULL([t].[MFVersion],-1) AND ISNULL([t].[deleted], 0) = 0 THEN 0
WHEN [ao].[MFVersion] > ISNULL([t].[MFVersion],-1) AND [t].[deleted] = 0  THEN 1
WHEN ao.[MFVersion] < ISNULL(t.[MFVersion],-1) AND ISNULL(t.[objid],-1)	> 0 THEN 2
WHEN ISNULL(ao.MFVersion,0) = 0 THEN 4
WHEN ISNULL(t.id,0) = 0 AND ISNULL(t.[objid],0) = 0 THEN 5
WHEN ISNULL(t.id,0) > 0 AND ISNULL(t.[objid],0) = 0 THEN 5
END 
FROM [#AllObjects] AS [ao]
left JOIN ' +   QUOTENAME(@MFTableName) + ' t
ON ao.[objid] = t.[objid] ;';

      --           Print @Query;
            EXEC [sys].[sp_executesql] @Stmt = @Query;



            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

             SELECT 'Postflag',* FROM [#AllObjects] AS [ao]
            END;

			DECLARE @TotalObjver INT
			DECLARE @FilteredObjver INT
			DECLARE @ToUpdateObjver INT
			DECLARE @NotInAuditHistory int

			SELECT @TotalObjver = COUNT(*) FROM [dbo].[MFAuditHistory] AS [mah] WHERE [mah].[Class] = @ClassId
			SELECT @FilteredObjver = COUNT(*) FROM [#AllObjects] AS [ao]
			SELECT @ToUpdateObjver = COUNT(*) FROM [#AllObjects] AS [ao] WHERE [ao].[StatusFlag] IN (1,5)
			SELECT @NotInAuditHistory = COUNT(*) FROM [#AllObjects] AS [ao]
			LEFT JOIN [dbo].[MFAuditHistory] AS [mah]
			ON [mah].[Class] = [ao].[Class] AND [mah].[ObjID] = [ao].[ObjID]
			WHERE mah.[Objid] IS null

			                           SET @LogTypeDetail = 'Status';
			                           SET @LogStatusDetail = 'In progress';
			                           SET @LogTextDetail = 'MFAuditHistory: Total: '+ CAST(COALESCE(@TotalObjver,0) AS NVARCHAR(10)) + ' Filtered: ' + CAST(COALESCE(@FilteredObjver,0) AS NVARCHAR(10)) + ' To update: ' + CAST(COALESCE(@ToUpdateObjver,0) AS NVARCHAR(10))
			                           SET @LogColumnName = 'Objvers to update';
			                           SET @LogColumnValue = CAST(COALESCE(@ToUpdateObjver,0) AS NVARCHAR(10));
			
			                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
			                            @ProcessBatch_ID = @ProcessBatch_ID
			                          , @LogType = @LogTypeDetail
			                          , @LogText = @LogTextDetail
			                          , @LogStatus = @LogStatusDetail
			                          , @StartTime = @StartTime
			                          , @MFTableName = @MFTableName
			                          , @Validation_ID = @Validation_ID
			                          , @ColumnName = @LogColumnName
			                          , @ColumnValue = @LogColumnValue
			                          , @Update_ID = @Update_ID
			                          , @LogProcedureName = @ProcedureName
			                          , @LogProcedureStep = @ProcedureStep
			                          , @debug = @debug

            --Delete redundant objects in class table in SQL: this can only be applied when a full Audit is performed
            --7 = Marked deleted in SQL not deleted in MF : [t].[Deleted] = 1
            SET @ProcedureStep = 'Delete redudants in SQL';

            IF @DeletedInSQL = 1
            BEGIN
                SELECT @Query
                    = N'DELETE FROM ' + QUOTENAME(@MFTableName)
                      + '
WHERE id IN (
SELECT t.id
FROM [#AllObjects] AS [ao]
right JOIN '                    + QUOTENAME(@MFTableName) + ' t
ON ao.objid = t.objid 
WHERE ao.objid IS NULL) ;';

            --            SELECT @Query;
                EXEC [sys].[sp_executesql] @Query;


                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END; -- Delete from SQL

			-------------------------------------------------------------
			-- Process objversions to audit history
			-------------------------------------------------------------
			IF @ToUpdateObjver > 0 OR @NotInAuditHistory > 0
			BEGIN

            SET @ProcedureStep = 'Update records in Audit History';

			Set @DebugText = ' Count %i'
			Set @DebugText = @DefaultDebugText + @DebugText

	SELECT @rowcount = 	 COUNT(*) FROM [#AllObjects] AS [ao]	

			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@rowcount );
					

				END
			
			SELECT @ProcedureStep = 'Merge into MFAuditHistory'

            MERGE INTO [dbo].[MFAuditHistory] [targ]
            USING
            (
                SELECT [ao].[ID]
                      ,[ao].[ObjID]
                      ,[ao].[MFVersion]
                      ,[ao].[ObjectType] AS [ObjectID]
                      ,@SessionID        AS [SessionID]
                      ,@TranDate         AS [TranDate]
                      ,@ClassId          AS [Class]
                      ,[ao].[StatusFlag] AS [Statusflag]
                      ,CASE
                           WHEN [ao].[StatusFlag] = 0 THEN
                               'Identical'
                           WHEN [ao].[StatusFlag] = 1 THEN
                               'MF is later'
                           WHEN [ao].[StatusFlag] = 2 THEN
                               'SQL is later'
                           WHEN [ao].[StatusFlag] = 3 THEN
                               'Deleted in MF'
                           WHEN [ao].[StatusFlag] = 4 THEN
                               'SQL to be marked as deleted'
                           WHEN [ao].[StatusFlag] = 5 THEN
                               'Not in SQL'
                           WHEN [ao].[StatusFlag] = 6 THEN
                               'Not yet processed in SQL'
                       END               AS [StatusName]
                      ,CASE
                           WHEN [ao].[StatusFlag] <> 0 THEN
                               1
                           ELSE
                               0
                       END               [UpdateFlag]
                FROM [#AllObjects] AS [ao]
            ) AS [Src]
            ON [targ].[ObjID] = [Src].[ObjID]
               AND [targ].[Class] = [Src].[Class]
            WHEN NOT MATCHED THEN
                INSERT
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
                   ,[UpdateFlag]
                )
                VALUES
                ([Src].[ID], [Src].[SessionID], [Src].[TranDate], [Src].[ObjectID], [Src].[Class], [Src].[ObjID]
                ,[Src].[MFVersion], [Src].[Statusflag], [Src].[StatusName], 1)
            WHEN MATCHED THEN
                UPDATE SET [targ].[RecID] = [Src].[ID]
                          ,[targ].[SessionID] = [Src].[SessionID]
                          ,[targ].[TranDate] = [Src].[TranDate]
                          ,[targ].[ObjectType] = [Src].[ObjectID]
                          ,[targ].[MFVersion] = [Src].[MFVersion]
                          ,[targ].[StatusFlag] = [Src].[Statusflag]
                          ,[targ].[StatusName] = [Src].[StatusName]
                          ,[targ].[UpdateFlag] = [Src].[UpdateFlag];

						  	Set @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
     
	        IF @Debug > 0
            BEGIN
                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
            END;

			END --update items into MFaudithisitory

			-------------------------------------------------------------
			-- Remove from MFauditHistory where objids is not returned from MF
			-------------------------------------------------------------
	  SET @ProcedureStep = 'Delete from audit history';
	  		
			IF @MFIDs IS NOT NULL
            BEGIN
            
			WITH cte AS
            (
			SELECT [ListItem] AS [Objid] from [dbo].[fnMFParseDelimitedString](@MFIDs,',') fps
			LEFT JOIN [#AllObjects] AS [ao]
			ON fps.[ListItem] = ao.[ObjID]
			WHERE ao.objid IS null
			)
			DELETE FROM [dbo].[MFAuditHistory] 
			WHERE [Class] = @ClassId AND [Objid] IN (SELECT cte.[Objid] FROM cte)
			END

            -----------------------------------------------------------
     --        Delete from audit history where item no longer in class table and flag = 4
            -----------------------------------------------------------
          

            IF
            (
                SELECT ISNULL([IncludeInApp], 0)
                FROM [dbo].[MFClass]
                WHERE [TableName] = @MFTableName
            ) != 0
            BEGIN
                SET @sql
                    = N'
   Delete FROM [dbo].[MFAuditHistory]
						   WHERE id IN (SELECT mah.id from [dbo].[MFAuditHistory] mah
						   left JOIN ' + QUOTENAME(@MFTableName)
                      + ' AS [mlv]
						   ON mlv.objid = mah.[ObjID] AND mlv.'+@ClassTableColumn+' = mah.[Class]
						   WHERE mlv.id IS NULL) and isnull(StatusFlag,-1) = -1  ;';

                EXEC (@sql);
            END;




        -------------------------------------------------------------
        -- Set UpdateRequired
        -------------------------------------------------------------
        DECLARE @MFRecordCount INT
               ,@MFNotInSQL    INT
               ,@LaterInMF     INT
               ,@Process_id_1  INT
               ,@NewSQL        INT;

        --EXEC [dbo].[spMFClassTableStats] @ClassTableName = @MFTableName -- nvarchar(128)
        --                                ,@Flag = 0             -- int
        --                                ,@IncludeOutput = 1    -- int
        --                                ,@Debug = 0            -- smallint

        --SELECT @MFNotInSQL = MFNotInSQL, @OutofSync = SyncError, @ProcessErrors = MFError + SQLError, @Process_id_1 = Process_id_1  FROM ##spmfclasstablestats
        --WHERE TableName = @MFTableName
        SELECT @LaterInMF = COUNT(*)
        FROM [dbo].[MFAuditHistory] AS [mah]
        WHERE [mah].[SessionID] = @SessionIDOut
              AND [mah].[StatusFlag] = 1;

        SELECT @NewSQL = COUNT(*)
        FROM [dbo].[MFAuditHistory] AS [mah]
        WHERE [mah].[SessionID] = @SessionIDOut
              AND [mah].[StatusFlag] = 5;

        SELECT @UpdateRequired = CASE
                                     WHEN @LaterInMF > 0
                                          OR @MFNotInSQL > 0
                                          OR @Process_id_1 > 0
                                          OR @NewSQL > 0 THEN
                                         1
                                     ELSE
                                         0
                                 END;

        SET @Msg = 'Session: ' + CAST(@SessionIDOut AS VARCHAR(5));

        IF @UpdateRequired > 0
            SET @Msg = @Msg + ' | Update Required: ' + CAST(@UpdateRequired AS VARCHAR(5));

        IF @LaterInMF > 0
            SET @Msg = @Msg + ' | MF Updates : ' + CAST(@LaterInMF AS VARCHAR(5));

        IF @Process_id_1 > 0
            SET @Msg = @Msg + ' | SQL Updates : ' + CAST(@Process_id_1 AS VARCHAR(5));

        IF @Process_id_1 > 0
            SET @Msg = @Msg + ' | SQL New : ' + CAST(@NewSQL AS VARCHAR(5));


	EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Debug'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

        SET @StartTime = GETUTCDATE();
        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = @Msg;
        SET @LogStatusDetail = 'Status';
        SET @LogColumnName = 'Objects';
        SET @LogColumnValue = '';

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
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
                                                  ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
                                                  ,@debug = 0;

            --        COMMIT TRAN [main];
            DROP TABLE [#AllObjects];
        END; --nothing to update in AuditHistory
    END;
    ELSE
    BEGIN
        RAISERROR('Table does not exist', 10, 1);
    END;

   
    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = 'End';
    SET @LogStatus = 'Completed';
	SET @LogText = 'Completed ' + @ProcedureName;
	
	EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Debug'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

        SET @StartTime = GETUTCDATE();
        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail =  @LogText;
        SET @LogStatusDetail = 'Status';
        SET @LogColumnName = '';
        SET @LogColumnValue = '';

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
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
                                                  ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
                                                  ,@debug = 0;

    -------------------------------------------------------------
    -- Log End of Process
    ------------------------------------------------------------- 
    SELECT @SessionIDOut = @SessionID;

    IF @Debug > 0
        SELECT @SessionIDOut AS [SessionID];

    RETURN 1;
	 SET NOCOUNT OFF;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();
    SET @LogStatus = 'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

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