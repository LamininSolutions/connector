
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfSynchronizeWorkFlowSateColumnChange]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spmfSynchronizeWorkFlowSateColumnChange', -- nvarchar(100)
    @Object_Release = '4.3.9.49', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spmfSynchronizeWorkFlowSateColumnChange'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
 --if the routine exists this stub creation step is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkFlowSateColumnChange]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


Alter PROCEDURE [dbo].[spMFSynchronizeWorkFlowSateColumnChange]
@TableName Nvarchar(200)=null,
@ProcessBatch_id INT           = NULL OUTPUT,
@Debug           INT           = 0
AS

/*rST**************************************************************************

=======================================
spMFSynchronizeWorkFlowSateColumnChange
=======================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

The purpose of this procedure is to synchronize workflow state name change in M-Files into the reference table

Examples
========

.. code:: sql

    exec spMFSynchronizeWorkFlowSateColumnChange 'MFCustomer'


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-27  LC         Add documentation
2019-06-10  LC         fix bug in name of procedure for error trapping 
2018-03-01  DEV2       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


begin

			BEGIN TRY
			SET NOCOUNT ON;
			-----------------------------------------------------
			--DECLARE VARIABLES FOR LOGGING
			-----------------------------------------------------
			--used on MFProcessBatchDetail;
			DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
			DECLARE @DebugText AS NVARCHAR(256) = '';
			DECLARE @LogTypeDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
			DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
			DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
			DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
			DECLARE @ProcessType NVARCHAR(50) = 'Object History';
			DECLARE @LogType AS NVARCHAR(50) = 'Status';
			DECLARE @LogText AS NVARCHAR(4000) = 'Get History Initiated';
			DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
			DECLARE @Status AS NVARCHAR(128) = NULL;
			DECLARE @Validation_ID INT = NULL;
			DECLARE @StartTime AS DATETIME = GETUTCDATE();
			DECLARE @RunTime AS DECIMAL(18, 4) = 0;
			DECLARE @Update_IDOut int;
			DECLARE @error AS INT = 0;
			DECLARE @rowcount AS INT = 0;
			DECLARE @return_value AS INT;
			DECLARE @RC INT;
			DECLARE @Update_ID INT;
			DECLARE @ProcedureName sysname = 'spmfSynchronizeWorkFlowSateColumnChange';
			DECLARE @ProcedureStep sysname = 'Start';
			
			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			 --IF @TableName IS NOT NULL
			 --Begin
			 --  Update MFClass set IncludeInApp=1 where TableName=@TableName
			 --End

			DECLARE @Username NVARCHAR(2000);
			DECLARE @VaultName NVARCHAR(2000);

			SELECT TOP 1
			 @Username  = [MFVaultSettings].[Username],
			 @VaultName = [MFVaultSettings].[VaultName]
			FROM
			 [dbo].[MFVaultSettings];



			INSERT INTO [dbo].[MFUpdateHistory]
			(
			 [Username],
			 [VaultName],
			 [UpdateMethod]
			)
			VALUES
			(
			 @Username, @VaultName, -1
			);

			SELECT
			@Update_ID = @@IDENTITY;

			SELECT
			@Update_IDOut = @Update_ID;

			SET @ProcessType = @ProcedureName;
			SET @LogText = @ProcedureName + ' Started ';
			SET @LogStatus = 'Initiate';
			SET @StartTime = GETUTCDATE();
			set @ProcessBatch_ID=0
			EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_id OUTPUT,
			@ProcessType = @ProcessType,
			@LogType = @LogType,
			@LogText = @LogText,
			@LogStatus = @LogStatus,
			@debug = @Debug;


			 SET @ProcedureStep = 'GeT ValueListItems along with where IsNameUpdate=1 ';

            

		Create table #WorkflowStateNameChange
				(
				   ID int identity(1,1),
				   WorkflowID int,
				   WorkflowMFID int,
				   WorkflowStateMFID int,
				   Name Nvarchar(200)

				)

				insert into #WorkflowStateNameChange 
				select  
					 WF.ID,
					 WF.MFID,
					 WS.MFID,
					 WS.Name 
				from 
					 MFWorkflowState WS inner join 
					 MFWorkflow WF 
				on 
					 WS.MFWorkflowID=WF.ID 
				where 
					 WS.IsNameUpdate=1

			 IF @Debug > 0
                BEGIN
                    PRINT @ProcedureStep;
					select * from #WorkflowStateNameChange
                END
				  
			

			 DECLARE 
			  @NameChangeCounter INT=1
		     ,@MaxRows int
		     ,@WFID INT
		     ,@WFMFID INT
		     ,@WSMFID INT
			 ,@Name NVARCHAR(200)
		

			Select @MaxRows=MAX(ID) from #WorkflowStateNameChange 

				   
			EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
			        @ProcessBatch_ID = @ProcessBatch_id,
					@LogType = @LogTypeDetail,
					@LogText = @LogTextDetail,
					@LogStatus = @LogStatusDetail,
					@StartTime = @StartTime,
					@MFTableName = @TableName,
					@Validation_ID = @Validation_ID,
					@ColumnName = @LogColumnName,
					@ColumnValue = @LogColumnValue,
					@Update_ID = @Update_ID,
					@LogProcedureName = @ProcedureName,
					@LogProcedureStep = @ProcedureStep,
					@debug = @Debug;


			While @NameChangeCounter <= @MaxRows
				Begin
					Select 
					@WFID=WorkflowID
					,@WFMFID=WorkflowMFID
					,@WSMFID=WorkflowStateMFID
					,@Name=Name 
					from 
					#WorkflowStateNameChange 
					where 
					ID=@NameChangeCounter

					Create Table #tables
					(
					TBLID int identity (1,1),
					TBLName Nvarchar(250)
					)
					Insert into #tables Select TableName from MFClass where MFWorkflow_ID=@WFID
					Select * from #tables
		 
		

					DECLARE @TblCounter INT=1
					,@TblMaxRow INT
					,@TblName Nvarchar(250)
		 
					SELECT @TblMaxRow=max(TBLID) from #tables

					While @TblCounter <= @TblMaxRow
					Begin
			   
					Select @TblName=TBLName from #tables where TBLID=@TblCounter
				 
					print @TblName

					IF Exists( Select top 1 * from INFORMATION_SCHEMA.TABLES where TABLE_NAME=@TblName)
					Begin
					   
					DECLARE @Sql NVARCHAR(MAX)
					SET @Sql ='Update '+ @TblName + ' SET ' + SUBSTRING('Workflow_State_ID',1,LEN('Workflow_State_ID')-3) + '='''+@Name+ ''' where '+ @TblName+'.Workflow_State_ID='+cast(@WSMFID as VARCHAR(20))

					print @Sql

					exec (@Sql)

					End
					SET @TblCounter=@TblCounter+1
               
				 drop table #tables

		   Update MFWorkflowState set IsNameUpdate=0 where MFID=@WSMFID

		   SET @NameChangeCounter= @NameChangeCounter+1
   End

				
			End
			
		 
		 

			
			drop table #WorkflowStateNameChange
	End Try
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
			, @MFTableName = @TableName
			, @Validation_ID = @Validation_ID
			, @ColumnName = NULL
			, @ColumnValue = NULL
			, @Update_ID = @Update_ID
			, @LogProcedureName = @ProcedureName
			, @LogProcedureStep = @ProcedureStep
			, @debug = 0

			RETURN -1
	END CATCH
End