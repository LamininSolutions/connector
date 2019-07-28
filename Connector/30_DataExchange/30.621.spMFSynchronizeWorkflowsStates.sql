PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeWorkflowsStates]';
GO


SET NOCOUNT ON;
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeWorkflowsStates', -- nvarchar(100)
    @Object_Release = '4.2.7.46',                    -- varchar(50)
    @UpdateFlag = 2;                                 -- smallint
-- smallint

GO

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFSynchronizeWorkflowsStates' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkflowsStates]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeWorkflowsStates]
    (
        @VaultSettings [NVARCHAR](4000),
        @Debug         SMALLINT,
        @Out           [NVARCHAR](MAX) OUTPUT,
        @IsUpdate      SMALLINT        = 0
    )
AS
    /*******************************************************************************
** Desc:  The purpose of this procedure is to synchronize M-File WORKFLOW STATE details  
**  
** Date:				27-03-2015
********************************************************************************
** Change History
********************************************************************************
** Date        Author     Description
** ----------  ---------  -----------------------------------------------------
** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                          Comma separated string in @VaultSettings parmeter.
   2018-04-04  DevTeam2   Added License module validation code 
   2018-11-15	LC			remove logging 
******************************************************************************/
    -- ==============================================
    
	BEGIN
        SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = 'ClassTable'
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Sync Workflow States')

		-------------------------------------------------------------
		-- CONSTATNS: MFSQL Global 
		-------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
		DECLARE @Process_ID_1_Update TINYINT = 1
		DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
		DECLARE @Process_ID_9_BatchUpdate TINYINT = 9 --marks records previously set as 1 to 9 and update in batches of 250
		DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
		DECLARE @Process_ID_2_SyncError TINYINT = 2
		DECLARE @ProcessBatchSize INT = 250

		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @MFLastModified DATETIME
		DECLARE @Validation_ID int
		DECLARE @ProcessBatch_ID int

		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFSynchronizeWorkflowsStates';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


	
        DECLARE
            @Xml           [NVARCHAR](MAX),
            @Output        INT

        IF @Debug = 1
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
  
  BEGIN TRY
       
	   CREATE TABLE #TempMFWorkflowState
	   (ID INT, Name NVARCHAR(100), Alias NVARCHAR(100), MFID INT, MFWorkflowID INT)
        ---------------------------------------------------
        --  LOCAL VARIABLE DECLARATION
        ---------------------------------------------------
        --  if( @IsUpdate =1)
        -- Begin
        INSERT INTO [#TempMFWorkflowState]
            (
                [ID],
                [Name],
                [Alias],
                [MFID],
                [MFWorkflowID]
            )
       
		SELECT
            [MFWFS].[ID],
            [MFWFS].[Name],
            [MFWFS].[Alias],
            [MFWFS].[MFID],
            [MFWF].[MFID] AS [MFWorkflowID]
       
        FROM
            [MFWorkflowState] AS [MFWFS]
            INNER JOIN
                [MFWorkflow]  AS [MFWF]
                    ON [MFWFS].[MFWorkflowID] = [MFWF].[ID]
        WHERE
            [MFWF].[Deleted] = 0;

	    --	 End
    DECLARE @WorkflowID INT;

        

		-----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetWorkFlowState
        ------------------------------------------------------------------
        EXEC [dbo].[spMFCheckLicenseStatus] 
		                                    'spMFGetWorkFlowState'
											,@ProcedureName
											,@ProcedureStep



        DECLARE [InsertWorkflowsStatesCursor] CURSOR LOCAL FOR
            -----------------------------------------------------
            --Select WorkflowID From WorkflowsToInclude  Table
            -----------------------------------------------------
            SELECT
                [MFID]
            FROM
                [MFWorkflow];


        OPEN [InsertWorkflowsStatesCursor];
        SET @ProcedureStep = 'Open cursor update 0';
        
           
	    SET @ProcedureStep = 'Workfow start ';
		SET @DebugText = @DefaultDebugText + 'Workflow :%d ' 

        IF @Debug = 1
            RAISERROR(@Debugtext, 10, 1, @ProcedureName, @ProcedureStep,@WorkflowID);


        ------------------------------------------------------------
        --Select The WorkflowID into declared variable '@WorkflowID'
        ------------------------------------------------------------
        FETCH NEXT FROM [InsertWorkflowsStatesCursor]
        INTO
            @WorkflowID;


        WHILE @@FETCH_STATUS = 0
            BEGIN
                -------------------------------------------------------------------
                --Declare new variable to store the outPut of 'GetMFValueListItems'
                -------------------------------------------------------------------

                ------------------------------------------------------------------------------------
                --Execute 'GetMFWorkFlowState' to get the all WorkflowsStates details in xml format
                ------------------------------------------------------------------------------------
				IF @debug = 1
				SELECT ID,mfid FROM [dbo].[MFWorkflow] AS [mw] WHERE MFID = @WorkflowID AND [mw].[Deleted] = 0;

                EXEC [spMFGetWorkFlowState]
                    @VaultSettings,
                    @WorkflowID,
                    @Xml OUTPUT;

					
                SET @ProcedureStep = 'GetWorkflowStates Returned from wrapper';

                IF @Debug = 1
				begin
				SELECT CAST(@Xml AS XML)
					
                    RAISERROR('%s : Step %s for Workflow_ID: %i', 10, 1, @ProcedureName, @ProcedureStep, @WorkflowID);

				END



                ----------------------------------------------------------------------------------------------------------
                --Execute 'InsertMFWorkFlowState' to insert all property Details into 'MFValueListItems' Table
                ----------------------------------------------------------------------------------------------------------

                EXEC [spMFInsertWorkflowState]
                    @Xml,
                    @Output OUTPUT,
                    @Debug;


                SET @ProcedureStep = 'Exec spMFInsertWorkflowStates';

                IF @Debug = 1
                    RAISERROR('%s : Step %s Output: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);
                ------------------------------------------------------------------
                --      Select The Next WorkflowID into declared variable '@WorkflowID'
                ------------------------------------------------------------------
                FETCH NEXT FROM [InsertWorkflowsStatesCursor]
                INTO
                    @WorkflowID;
            END;

        -----------------------------------------------------
        --Close the Cursor
        -----------------------------------------------------
        CLOSE [InsertWorkflowsStatesCursor];

        -----------------------------------------------------
        --Deallocate the Cursor
        -----------------------------------------------------
        DEALLOCATE [InsertWorkflowsStatesCursor];
        IF (@IsUpdate = 1)
            BEGIN
                SET @ProcedureStep = 'Update workflow and states';
                IF @Debug = 1
                    RAISERROR('%s : Step %s workflow id: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);

                DECLARE @WorkFlowStateXML NVARCHAR(MAX);
                SET @WorkFlowStateXML =
                    (
                        SELECT
                            ISNULL([TMFWFS].[ID], 0)           AS [WorkFlowStateDetails/@ID],
                            ISNULL([TMFWFS].[Name], '')        AS [WorkFlowStateDetails/@Name],
                            ISNULL([TMFWFS].[Alias], '')       AS [WorkFlowStateDetails/@Alias],
                            ISNULL([TMFWFS].[MFID], 0)         AS [WorkFlowStateDetails/@MFID],
                            ISNULL([TMFWFS].[MFWorkflowID], 0) AS [WorkFlowStateDetails/@MFWorkflowID]
                        FROM
                            [MFWorkflowState]          AS [MFWFS]
                            INNER JOIN
                                [#TempMFWorkflowState] AS [TMFWFS]
                                    ON [MFWFS].[MFID] = [TMFWFS].[MFID]
                                       AND
                                           (
                                               [MFWFS].[Name] != [TMFWFS].[Name]
                                               OR [MFWFS].[Alias] != [TMFWFS].[Alias]
                                           )
                        FOR XML PATH(''), ROOT('WorkFlowState')
                    );


                -----------------------------------------------------------------
	              -- Checking module access for CLR procdure  spMFUpdateWorkFlowState
                ------------------------------------------------------------------
                 EXEC [dbo].[spMFCheckLicenseStatus] 
		                                    'spMFUpdateWorkFlowState'
											,@ProcedureName
											,@ProcedureStep

                DECLARE @Outpout1 NVARCHAR(MAX);
                EXEC [spMFUpdateWorkFlowState]
                    @VaultSettings,
                    @WorkFlowStateXML,
                    @Outpout1 OUT;
                SET @ProcedureStep = 'Update MFWorkflowstate with results';
                IF @Debug = 1
                    RAISERROR('%s : Step %s Output: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);

                UPDATE
                    [MFWFS]
                SET
                    [MFWFS].[Name] = [TMFWFS].[Name],
                    [MFWFS].[Alias] = [TMFWFS].[Alias]
                FROM
                    [MFWorkflowState]          AS [MFWFS]
                    INNER JOIN
                        [#TempMFWorkflowState] AS [TMFWFS]
                            ON [MFWFS].[MFID] = [TMFWFS].[MFID];

                DROP TABLE [#TempMFWorkflowState];
            END;

        IF (@Output > 0)
            SET @Out = 'All WorkFlowState are Updated';
        ELSE
            SET @Out = 'All WorkFlowState are upto date';

        SET NOCOUNT OFF;
    
		

	RETURN 1
	END try
BEGIN CATCH

				SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH


END

GO

    