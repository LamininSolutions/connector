
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeploymentDetails]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFDeploymentDetails' -- nvarchar(100)
  , @Object_Release = '4.10.32.76'
  , @UpdateFlag = 2

GO
IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFDeploymentDetails' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFDeploymentDetails]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFDeploymentDetails]
	(   @Type int  = 0
	,	@ProcessBatch_ID INT	  = NULL OUTPUT
	  , @Debug			 SMALLINT = 0
	)
AS
/*rST**************************************************************************

=====================
spMFDeploymentDetails
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Int (optional)
    used as input variable to set the type of update message
     0 - default message
     -1 - Failed
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Print deployment details

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-06-26  Lc         Improve logging
2021-09-11  LC         Add parameter to set type of update
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

	BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = ''
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'insert deployment details')

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
		DECLARE @Update_IDOut INT
		DECLARE @MFLastModified DATETIME
		DECLARE @MFLastUpdateDate Datetime
		DECLARE @Validation_ID int
	
		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFDeploymentDetails';
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


		-------------------------------------------------------------
		-- INTIALIZE PROCESS BATCH
		-------------------------------------------------------------
		SET @ProcedureStep = 'Start Logging'

		SET @LogText = 'Processing ' + @ProcedureName

		EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
		  , @ProcessType = @ProcessType
		  , @LogType = N'Status'
		  , @LogText = @LogText
		  , @LogStatus = N'In Progress'
		  , @debug = @Debug


		EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
		  , @LogType = N'Debug'
		  , @LogText = @ProcessType
		  , @LogStatus = N'Started'
		  , @StartTime = @StartTime
		  , @MFTableName = @MFTableName
		  , @Validation_ID = @Validation_ID
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = @Update_ID
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'prepare insert'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

				
BEGIN

SET NOCOUNT ON;
	
DECLARE @rc INT ,
    @DBName VARCHAR(100),
	@ConnectorVersion varchar(50);

SELECT  @DBName = CAST(Value AS VARCHAR(100))
FROM    MFSettings
WHERE   Name = 'App_Database';


	DECLARE @expres NVARCHAR(10) = '|'
    DECLARE @patern NVARCHAR(20)
	DECLARE @charlist AS TABLE (id INT IDENTITY, release varchar(20), C1 VARCHAR(20), c2 VARCHAR(20), c3 VARCHAR(20), c4 VARCHAR(20))
	DECLARE @ID INT = 1

    INSERT INTO @charlist
    (
        release
    )
    SELECT REPLACE(Release,'.',@expres) FROM setup.MFSQLObjectsControl AS moc
    WHERE release IS NOT null
    GROUP BY Release

    WHILE @id IS not NULL
    Begin

  SELECT @patern = Release FROM @charlist AS c where id = @id
 --  INSERT INTO @itemlist
 ;WITH cte AS
 (
 SELECT @patern Release,  item FROM dbo.fnMFSplitstring(@patern,@expres) AS fmss
 ), cte2 as
 (SELECT cte.*, col = ROW_NUMBER() OVER (PARTITION BY Release ORDER BY release )
 FROM cte)
 UPDATE cl
    SET c1 =  (SELECT item FROM CTE2 il WHERE col = 1 AND il.release = CTE2.Release)
    , c2 = (SELECT item FROM CTE2 il WHERE col = 2 AND il.release = CTE2.Release)
    , c3 = (SELECT item FROM CTE2 il WHERE col = 3 AND il.release = CTE2.Release)
    , c4 = (SELECT item FROM CTE2 il WHERE col = 4 AND il.release = CTE2.Release)
    FROM @Charlist cl
    INNER JOIN cte2
    ON cl.release = cte2.Release
    WHERE cl.id = @id

    SELECT @id = (SELECT MIN(id) FROM @charlist AS c where id > @id)
    end

    DECLARE @iC1 INT,@iC2 INT,@iC3 INT,@iC4 INT
    SELECT @iC1 = MAX(CAST(C1 AS INT)),@iC2 = MAX(CAST(C2 AS INT)),@iC3 = MAX(CAST(C3 AS INT)),@iC4 = MAX(CAST(C4 AS INT)) FROM @charlist


SELECT @ConnectorVersion = CAST(@iC1 AS VARCHAR(3))+'.'+CAST(@iC2 AS VARCHAR(3))+'.'+CAST(@iC3 AS VARCHAR(3))+'.'+CAST(@iC4 AS VARCHAR(3))

    BEGIN
        SET @msg = SPACE(5) + DB_NAME() + ': Update Version log';
        RAISERROR('%s',10,1,@msg); 

        BEGIN
            SET NOCOUNT ON;

            DECLARE @MFVersion VARCHAR(50);
            SELECT  @MFVersion = CAST(Value AS VARCHAR(50))
            FROM    dbo.MFSettings
            WHERE   Name = 'MFVersion';

                  
            INSERT  INTO MFDeploymentDetail
                    ( LSWrapperVersion ,
                      MFilesAPIVersion ,
                      DeployedBy ,
                      DeployedOn
				    )
            VALUES  ( 
            CASE WHEN @Type = 0 THEN ''
            WHEN @Type = -1 THEN 'Failed '
            END + 
            'Wrapper ' + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                            'VersionMajor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionMinor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionBuild') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionRevision') AS NVARCHAR(3))

			+ ' / Procedures ' + @ConnectorVersion  ,
                      CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                            'VersionMajor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionMinor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionBuild') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionRevision') AS NVARCHAR(3))
                      + ' :' + @MFVersion ,
                      SYSTEM_USER ,
                      GETDATE()
                    );

            PRINT 'Deployed version details :' + CHAR(13)
                + 'Assembly Name : LSConnectMFilesAPIWrapper  Version :'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionMajor') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionMinor') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionBuild') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionRevision') AS NVARCHAR(3))
										+ ' / ' + 'MFSQLConnector ' + @ConnectorVersion + 
                + CHAR(13) + 'Assembly Name : Interop.MFilesAPI  Version :'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionMajor') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionMinor') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionBuild') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionRevision') AS NVARCHAR(3))
                + ' :' + @MFVersion + CHAR(13) + 'Deployed by "' + SYSTEM_USER
                + '" On ' + CAST(GETDATE() AS NVARCHAR(50));
                                  
                          

            SET NOCOUNT OFF;
        END;



    END;

	END

			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
            set @LogTextDetail = 'MFilesVersion ' + @MFVersion  + ' MFSQLConnector ' + @ConnectorVersion 
            set @LogText = @LogText + @LogTextDetail
			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Message'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
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
			RETURN 1
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




    

GO

