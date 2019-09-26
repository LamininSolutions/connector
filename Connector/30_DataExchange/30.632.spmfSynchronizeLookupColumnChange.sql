
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfSynchronizeLookupColumnChange]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spmfSynchronizeLookupColumnChange', -- nvarchar(100)
    @Object_Release = '4.3.8.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spmfSynchronizeLookupColumnChange'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spmfSynchronizeLookupColumnChange]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


Alter PROCEDURE [dbo].[spmfSynchronizeLookupColumnChange]
@TableName Nvarchar(200)=null,
@ProcessBatch_id INT           = NULL OUTPUT,
@Debug           INT           = 0
As
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize ValueListItems name change in M-Files into the reference table  
  											
  **
  ** Author:			DEV2
  ** Date:				01-03-2018
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
 2019-06-10		LC			Fix bug with updating multi lookup values
  ******************************************************************************/ 
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
			DECLARE @ProcedureName sysname = 'spmfSynchronizeLookupColumnChange';
			DECLARE @ProcedureStep sysname = 'Start';
			
			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			 IF @TableName IS NOT NULL
			 Begin
			   Update MFClass set IncludeInApp=1 where TableName=@TableName
			 End

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

            

			Create table #TempChangeValueListItems
			(
			 ID int identity(1,1),
			 ColumnName Nvarchar(100),
			 ValueListItemMFID int,
			 ValueListID int,
			 Name nvarchar(150)
			)

			insert into #TempChangeValueListItems

			select
			  MP.ColumnName as ColumnName,
			  MFVLI.MFID as ValueListItemMFID,
			  MFVLI.MFValueListID as ValueListID,
			  MFVLI.Name 
			from 
			 MFProperty MP  inner join MFValueList MVL 
			on 
			  MP.MFValueList_ID=MVL.ID inner join  MFValueListItems MFVLI 
			on 
			  MVL.ID=  MFVLI.MFValueListID 
			where 
			  MP.MFDataType_ID in (8,9) and
			  MFVLI.IsNameUpdate=1

			 IF @Debug > 0
                BEGIN
                    PRINT @ProcedureStep;
					select * from #TempChangeValueListItems
                END
				  
			DECLARE  
			@PropCounter int,
			@MaxPropCount int,
			@ColumnName nvarchar(100),
			@MFValueListItemMFID NVARCHAR(4000), 
			@Name nvarchar(150),
			@MFValueListID int

			SET @PropCounter=1

			select 
			 @MaxPropCount=max(ID) 
			from 
			 #TempChangeValueListItems 

				   
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


			While @PropCounter <= @MaxPropCount
				Begin
					   Select 
						@ColumnName=ColumnName,
						@MFValueListItemMFID=ValueListItemMFID,
						@Name=Name ,
						@MFValueListID=ValueListID
					   from 
						#TempChangeValueListItems
					   Where 
						ID=@PropCounter


			           Create Table #TempTables
						(
						  ID int identity(1,1),
						  TableName nvarchar(100)
						)


						SET @ProcedureStep = 'GeT Table names  Which containing the Property='+ @ColumnName;

			           insert into #TempTables
					   Select 
						C.TABLE_NAME 
					   from 
						INFORMATION_SCHEMA.COLUMNS C 
						where 
						C.COLUMN_NAME=@ColumnName and 
						C.TABLE_NAME in ( Select TableName from MFClass where IncludeInApp=1)


						 IF @Debug > 0
							BEGIN
								PRINT @ProcedureStep;
								select @ColumnName as PropertyName,TableName from #TempTables
							END


                       DECLARE 
						@TableCounter int,
						@MaxTableCount int ,
						@TBLName NVARCHAR(100)

			           SET @TableCounter =1 

					   Select 
						@MaxTableCount=max(ID) 
					   from 
						#TempTables 

					if @MaxTableCount>0
			         Begin
					    While @TableCounter <= @MaxTableCount
							Begin
							  
							  set @ProcedureStep ='updating the changed lookup value for column '+@ColumnName + ' of table ' + @TBLName

							   IF @Debug > 0
									BEGIN
										PRINT @ProcedureStep;
									END
									        
							EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
									@ProcessBatch_ID = @ProcessBatch_id,
									@LogType = @LogTypeDetail,
									@LogText = @LogTextDetail,
									@LogStatus = @LogStatusDetail,
									@StartTime = @StartTime,
									@MFTableName = @TBLName,
									@Validation_ID = @Validation_ID,
									@ColumnName = @LogColumnName,
									@ColumnValue = @LogColumnValue,
									@Update_ID = @Update_ID,
									@LogProcedureName = @ProcedureName,
									@LogProcedureStep = @ProcedureStep,
									@debug = @Debug;

									Select @TBLName=TableName from #TempTables where ID=@TableCounter
											
									DECLARE @Sql NVARCHAR(max)	 
									SET @Sql= 'Update '+ @TBLName + ' Set '+ SUBSTRING(@ColumnName,1,LEN(@ColumnName)-3)
												+'='''+@Name +''' where '+ @ColumnName +' = '''+ cast(@MFValueListItemMFID as nvarchar(4000)) + ''''

								--	print @sql
									exec (@Sql)
									set @TableCounter=@TableCounter+1
							End
			          End

				drop table #TempTables

				

				set @PropCounter=@PropCounter+1
			End

			update 
				   MVLI
				set 
				  MVLI.IsNameUpdate=0 
				from 
				  MFValueListItems MVLI inner join #TempChangeValueListItems T on MVLI.MFID=T.ValueListItemMFID and MVLI.MFValueListID=T.ValueListID
				where 
				  MVLI.IsNameUpdate=1
				
				  

			drop table #TempChangeValueListItems
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
END

GO