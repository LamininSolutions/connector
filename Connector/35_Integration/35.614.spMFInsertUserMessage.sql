
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertUserMessage]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFInsertUserMessage' -- nvarchar(100)
                                    ,@Object_Release = '4.4.10.49'           -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFInsertUserMessage' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertUserMessage]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFInsertUserMessage]
    @ProcessBatch_ID INT = NULL
   ,@UserMessageEnabled INT = 0
   ,@Debug SMALLINT = 0
AS
/*rST**************************************************************************

=====================
spMFInsertUserMessage
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch\_ID int (optional)
    Referencing the ID of the ProcessBatch logging table
  @UserMessageEnabled int
    Set the user message enabled flag. 
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode


Purpose
=======

This procedure is used to insert an entry in the MFUserMessage table for the specified processbatch

Addition Info
=============

Enabling user messages are set in the MFSettings table. spMFProcessBatch trigger will use this setting to get the value for the @userMessageEnabled parameter.

Examples
========

exec spMFInsertUserMessage @processBatch_ID = 107, @userMessageEnabled = 1


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2019-01-03  LC         Fix bug related to column names
2018-11-15  LC         Add error logging; fix null value bug; check for duplicate messages per process batch
2018-07-25  LC         Resolve issue with workflow_state_id
2018-06-26  LC         Localise workflow and state
2018-05-18  LC         Add workflow and state
2018-04-28  LC         Add user message enabling
2018-04-20  LC         Update procedure for the new MFClass table for MFUserMessages
2018-04-18  LC         Set default for ProcessBatch_ID
2017-06-26  AC         Remove @ClassTable,  retrieve based on ProcessBatch_ID
2017-06-26  AC         Update call to spMFResultMessageForUI to read the message with carriage return instead of \n
2017-06-26  AC         Add ItemCount based on using new methods to generate RecordCount info message in MFProcessBatchDetail
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

BEGIN TRY

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @MFTableName AS NVARCHAR(128) = 'MFUserMessage';
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Create user message');

    -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFInsertUserMessage';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DebugText AS NVARCHAR(256) = '';
    DECLARE @DetailLoggingIsActive SMALLINT = 0;
    DECLARE @rowcount AS INT = 0;

    -------------------------------------------------------------
    -- VARIABLES: MFSQL Processing
    -------------------------------------------------------------
    DECLARE @Update_ID INT;
    DECLARE @Update_IDOut INT;
    DECLARE @MFLastModified DATETIME;
    DECLARE @MFLastUpdateDate DATETIME;
    DECLARE @Validation_ID INT;

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
    DECLARE @MessageForMFilesOUT NVARCHAR(4000)
           ,@ClassTable          NVARCHAR(100)
           ,@ItemCount           INT
           ,@RecordCount         INT
           ,@UserID              INT
           ,@ClassTableList      NVARCHAR(100)
           ,@MessageTitle        NVARCHAR(100)
           ,@Workflow_ID         INT
           ,@WorkflowState_id    INT;

    IF @UserMessageEnabled = 1
    BEGIN
        SELECT @WorkflowState_id = [mws].[MFID]
              ,@Workflow_ID      = [mw].[MFID]
        FROM [dbo].[MFWorkflowState]      AS [mws]
            INNER JOIN [dbo].[MFWorkflow] AS [mw]
                ON [mw].[ID] = [mws].[MFWorkflowID]
        WHERE [mws].[Alias] = 'wfs.MFSQL_New_Message';

        SET @DebugText = 'WorkflowState_ID %i Workflow_ID %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Get workflow MFIDs';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @WorkflowState_id, @Workflow_ID);
        END;

        EXEC [dbo].[spMFResultMessageForUI] @Processbatch_ID = @ProcessBatch_ID                -- int
                                                                                               --     @Detaillevel = 0,                                    -- int
                                                                                               --     @MessageOUT = @MessageOUT OUTPUT,                    -- nvarchar(4000)
                                           ,@MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT -- nvarchar(4000)
                                                                                               --     @GetEmailContent = NULL,                             -- bit
                                                                                               --     @EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT,        -- nvarchar(max)
                                           ,@RecordCount = @RecordCount OUTPUT                 -- int
                                           ,@UserID = @UserID OUTPUT                           -- int
                                           ,@ClassTableList = @ClassTableList OUTPUT           -- nvarchar(100)
                                           ,@MessageTitle = @MessageTitle OUTPUT
                                           ,@Debug = @Debug;                                   -- nvarchar(100)

        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Prepare Message ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        DECLARE @Workflow_name NVARCHAR(100);
        DECLARE @State_name NVARCHAR(100);
        DECLARE @Name_or_title_name NVARCHAR(100);
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @Params NVARCHAR(MAX);

        SELECT @Workflow_name = [ColumnName]
        FROM [dbo].[MFProperty]
        WHERE [MFID] = 38;

        SELECT @State_name = [ColumnName]
        FROM [dbo].[MFProperty]
        WHERE [MFID] = 39;

        SELECT @Name_or_title_name = [ColumnName]
        FROM [dbo].[MFProperty]
        WHERE [MFID] = 0;

	--	SELECT COUNT(*) FROM sys.columns WHERE [name] IN (@Workflow_name, @State_name, @Name_or_title_name) AND [object_id] = OBJECT_ID('..MFUserMessages')

		IF (SELECT COUNT(*) FROM sys.columns WHERE [name] IN (@Workflow_name, @State_name, @Name_or_title_name) AND [object_id] = OBJECT_ID('..MFUserMessages')) = 3
		Begin



        SET @Params
            = N'@MessageForMFilesOUT NVARCHAR(4000)
           ,@ProcessBatch_ID           INT
           ,@RecordCount         INT
           ,@UserID              INT
           ,@ClassTableList      NVARCHAR(100)
           ,@MessageTitle        NVARCHAR(100)
           ,@Workflow_ID         INT
           ,@WorkflowState_id    INT
'       ;
        SET @SQL
            = N'	
MERGE Into dbo.MFUserMessages t
USING (SELECT     ISNULL(@ClassTableList, '''') AS ClassTableList ,      
       ISNULL(@RecordCount, 0)  AS RecordCount,         
		@MessageForMFilesOUT AS MessageForMfilesOut,
       @ProcessBatch_ID  AS processBatch_ID,     
       @UserID AS UserID,              
	@Workflow_ID AS Workflow_ID,
		@WorkflowState_id AS WorkflowState_ID,
        ISNULL(@MessageTitle, '''') AS MessageTitle,
		Process_ID = 1) s 
		ON t.Mfsql_Process_Batch = s.processBatch_ID
		WHEN NOT MATCHED THEN insert
    (
        Mfsql_Class_Table,
        Mfsql_Count,
        Mfsql_Message,
        Mfsql_Process_Batch,
        Mfsql_User_ID,
		' + QUOTENAME(@Workflow_name) + ' ,
		' + QUOTENAME(@State_name) + ',
        ' + QUOTENAME(@Name_or_title_name)
              + ',
        Process_ID
    )
    VALUES
    (  s.ClassTableList,  
       RecordCount,         
       s.MessageForMFilesOUT,  
       s.ProcessBatch_ID,    
       s.UserID,              
	s.Workflow_ID, 
	s.WorkflowState_id, 
     s.MessageTitle,
	 s.Process_ID)
	 WHEN MATCHED THEN UPDATE Set
	 t.MFSQL_Class_Table = s.ClassTableList,
	 t.MFSQL_Count = s.RecordCount,
	 t.MFSQL_Message = s.MessageForMFilesOUT,
	 t.Name_or_title = s.Messagetitle,
	 t.process_ID = s.Process_ID
	 ;' ;

        IF @Debug > 0
        BEGIN
            SELECT ISNULL(@ClassTableList, '')      AS [ClassTableList]
                  ,ISNULL(@RecordCount, 0)          AS [RecordCount]
                  ,ISNULL(@MessageForMFilesOUT, '') AS [MessageForMfilesOut]
                  ,@ProcessBatch_ID                 AS [processBatch_ID]
                  ,@UserID                          AS [UserID]
                  ,@Workflow_ID                     AS [Workflow_ID]
                  ,@WorkflowState_id                AS [WorkflowState_ID]
                  ,ISNULL(@MessageTitle, '')        AS [MessageTitle]
                  ,[Process_ID]                     = 1;

            SELECT @SQL AS [SQL];
        END;

        EXEC [sys].[sp_executesql] @stmt = @SQL
                                  ,@param = @Params
                                  ,@ClassTableList = @ClassTableList
                                  ,@RecordCount = @RecordCount
                                  ,@MessageForMFilesOUT = @MessageForMFilesOUT
                                  ,@ProcessBatch_ID = @ProcessBatch_ID
                                  ,@UserID = @UserID
                                  ,@Workflow_ID = @Workflow_ID
                                  ,@WorkflowState_id = @WorkflowState_id
                                  ,@MessageTitle = @MessageTitle;

        UPDATE [dbo].[MFUserMessages]
        SET [Mfsql_Message] = @MessageForMFilesOUT
        WHERE [Mfsql_Process_Batch] = @ProcessBatch_ID;

        --        IF @Debug > 0
        --BEGIN
        --SELECT * FROM [dbo].[MFUserMessages] AS [mum] WHERE [mum].[Mfsql_Process_Batch] = @ProcessBatch_ID
        --END
        EXEC [dbo].[spMFUpdateTable] @MFTableName = N'MFUserMessages'     -- nvarchar(200)
                                    ,@UpdateMethod = 0
                                    ,@ProcessBatch_ID = @ProcessBatch_ID  -- int
                                    ,@Update_IDOut = @Update_IDOut OUTPUT --                @SyncErrorFlag = NULL,                      -- bit
                                    ,@Debug = 0;

                                                                          -- smallint

        --								        IF @Debug > 0
        --BEGIN

        --SELECT * FROM [dbo].[MFUserMessages] AS [mum] WHERE [mum].[Update_ID] = @Update_IDOut
        END -- columns exist
		ELSE 
		BEGIN
        Set @DebugText = 'Invalid columns in MFUserMessage Table'
        Set @DebugText = @DefaultDebugText + @DebugText
     
        
        --IF @debug > 0
        --	Begin
        --		RAISERROR(@DebugText,16,1,@ProcedureName,@ProcedureStep );
        --	END
        
		END
        RETURN 1;
    END;
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

    ---------------------------------------------------------------
    ---- Log Error
    ---------------------------------------------------------------   
    --EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
    --                                    ,@ProcessType = @ProcessType
    --                                    ,@LogType = N'Error'
    --                                    ,@LogText = @LogTextDetail
    --                                    ,@LogStatus = @LogStatus
    --                                    ,@debug = @Debug;

    --SET @StartTime = GETUTCDATE();

    --EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
    --                                          ,@LogType = N'Error'
    --                                          ,@LogText = @LogTextDetail
    --                                          ,@LogStatus = @LogStatus
    --                                          ,@StartTime = @StartTime
    --                                          ,@MFTableName = @MFTableName
    --                                          ,@Validation_ID = @Validation_ID
    --                                          ,@ColumnName = NULL
    --                                          ,@ColumnValue = NULL
    --                                          ,@Update_ID = @Update_ID
    --                                          ,@LogProcedureName = @ProcedureName
    --                                          ,@LogProcedureStep = @ProcedureStep
    --                                          ,@debug = 0;

    RETURN -1;
END CATCH;
GO
