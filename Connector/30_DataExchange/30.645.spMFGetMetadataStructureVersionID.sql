PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetMetadataStructureVersionID]';
GO
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMetadataStructureVersionID', -- nvarchar(100)
    @Object_Release = '4.9.28.73', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

/*
2018-11-22	LC	Fix bug in showing incorrect message
2019-05-19	LC	Add catch try block
2022-01-03  LC  Add return of guid
*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFGetMetadataStructureVersionID'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetMetadataStructureVersionID]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO



ALTER Procedure spMFGetMetadataStructureVersionID
@IsUpToDate bit=0 Output
as 

SET NOCOUNT ON

	-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFGetMetadataStructureVersionID';
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

BEGIN TRY	
SET @ProcedureStep = 'Validate connection'
				DECLARE @VaultSettings NVARCHAR(MAX)
				DECLARE @LatestMetadataVersionID INT
				DECLARE @LastMetadataStructureID INT
				DECLARE @OutPUT NVARCHAR(MAX)
                DECLARE @ValidGuid NVARCHAR(50)

				Select @VaultSettings=dbo.FnMFVaultSettings()


				EXEC spMFGetMetadataStructureVersionIDInternal
				     @VaultSettings,
					 @OutPUT OUTPUT,
                     @ValidGuid = @ValidGuid output
                   

				set @LatestMetadataVersionID=Cast(@OutPUT as INT)
                 
				Select 
				 @LastMetadataStructureID=cast(ISNULL(Value,0) as INT) 
				from 
				 MFSettings 
				where 
				 source_key='MF_Default' 
				 and 
				 Name='LastMetadataStructureID'

                 IF @ValidGuid <> ''
                 BEGIN
                 
                 Update 
						 MFSettings 
						Set 
						 Value=@ValidGuid 
						where  
						 source_key='MF_Default' 
						 and 
						 Name='VaultGUID'
 End

				 IF @LatestMetadataVersionID = @LastMetadataStructureID
				  Begin
				     Set @IsUpToDate=1
				  End
				 ELSE
				  Begin
						Update 
						 MFSettings 
						Set 
						 Value=@LatestMetadataVersionID 
						where  
						 source_key='MF_Default' 
						 and 
						 Name='LastMetadataStructureID'

						 SeT @IsUpToDate=0
				  End


	END TRY
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


		

			RETURN -1
		END CATCH


GO
