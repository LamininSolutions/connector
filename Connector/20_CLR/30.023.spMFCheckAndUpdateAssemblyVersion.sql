
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckAssemblyVersion]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFCheckAndUpdateAssemblyVersion',
    -- nvarchar(100)
    @Object_Release = '4.10.32.76',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFCheckAndUPdateAssemblyVersion' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFCheckAndUpdateAssemblyVersion
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFCheckAndUpdateAssemblyVersion
(@processBatch_ID int = null
,@Debug INT = 0)
AS
/*rST**************************************************************************

=================================
spMFCheckAndUpdateAssemblyVersion
=================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

The purpose of this procedure is to check  M-Files Version and update the assemblies.

Additional Info
===============

This procedure is normally used in a SQL Agent or powershell utility to schedule to check at least once day.  It can also be run manually at any time, especially after a M-Files upgrade on the SQL server.

This procedure calls spMFGetMFilesAssemblyVersion that will return the M-Files Desktop version on the SQL server.

An entry is made in the table MFupdateHistory when a version change is detected or an error is found.

Take into account the time diffence between M-Files automatically upgrading and the scheduled time for the job as any procedures using the assemblies in this time gap will is likely to fail.

Warnings
========

When the MFversion could not be found the procedure will not attempt to upgrade the assemblies. This will cause the connector to fail.

Examples
========
.. code:: sql

    EXEC spMFCheckAndUpdateAssemblyVersion @debug = 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-06-28  LC         Fix bug with assembly version
2023-05-30  LC         Add additional logging to track process results
2022-11-03  LC         Include validation that assemblies are in place
2021-12-16  LC         Fix bug to stop continious updates when no change took place
2021-08-11  LC         Improve control when version could not be found
2020-10-27  LC         Improve error message
2019-08-30  JC         Added documentation
2019-07-25  LC         Add more debug and error trapping, fix issue to prevent update
2019-05-19  LC         Fix bug - insert null value in MFsettings not allowed
2018-09-27  LC         Change procedure to work with Release 4 scripts
2016-12-28  DEV2       Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;
    	-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = null
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Check and update assemblies')


    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFCheckAndUpdateAssemblyVersion';
    DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @Msg AS NVARCHAR(256) = N'';
    -------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @MFLastModified DATETIME
		DECLARE @Validation_ID int
	
    		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = @processType + ' Started';
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
		  , @LogText = @LogText
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



 DECLARE  @LsMFilesVersion NVARCHAR(100)
    BEGIN TRY
        ---------------------------------------------
        DECLARE @IsVersionMisMatch BIT = 0,
            @MFilesVersion         VARCHAR(100),
            @MFilesOldVersion      VARCHAR(100),
            @Username              NVARCHAR(2000),
            @RC                    INT,
            @VaultName             NVARCHAR(2000);

        SELECT TOP 1
            @Username  = Username,
            @VaultName = VaultName
        FROM dbo.MFVaultSettings;
  
 IF NOT EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfGetLocalMFilesVersionInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN

            SET @DebugText = N' Missing Assembly for getting version';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'updater assembly for allowing to get MFversion ';

EXEC (N'
CREATE PROCEDURE [dbo].[spmfGetLocalMFilesVersionInternal]
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLocalMFilesVersion];
');


        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        
                                
                                   SET @LogTypeDetail = 'Status';
                                   SET @LogStatusDetail = '';
                                   SET @LogTextDetail = @Debugtext
                                   SET @LogColumnName = '';
                                   SET @LogColumnValue = '';
        
                                   EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
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

END

        SELECT @MFilesOldVersion = CAST(Value AS VARCHAR(100))
        FROM dbo.MFSettings
        WHERE Name = 'MFVersion';

            SET @DebugText = N' Is missmatch %i new MFVersion %s version in MFsetting %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'get MFversion and check missmatch ';

        EXEC @RC = dbo.spMFGetMFilesAssemblyVersion @IsVersionMisMatch OUTPUT,
            @MFilesVersion OUTPUT, @Debug = @debug;

        SET @MFilesVersion = COALESCE(@MFilesVersion, 'Unable to get version');

            UPDATE dbo.MFSettings
            SET Value = ISNULL(@MFilesVersion, 'No version found')
            WHERE Name = 'MFVersion';

        DECLARE @Mismatch NVARCHAR(10);

        SET @Mismatch = CASE
                            WHEN @IsVersionMisMatch = 1 THEN
                                'Yes'
                            ELSE
                                'No'
                        END;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Mismatch, @MFilesVersion,@MFilesOldVersion);
        END;

        
                                   SET @ProcedureStep = '';
                                   SET @LogTypeDetail = 'Status';
                                   SET @LogStatusDetail = '';
                                   SET @LogTextDetail = 'Old version ' + @MFilesOldVersion + ' new Version ' + @MFilesVersion + ' is Mismatch ' + cast(@mismatch as varchar(10))
                                   SET @LogColumnName = '';
                                   SET @LogColumnValue = '';
        
                                   EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
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

        IF NOT EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfConnectionTestInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' ) AND @IsVersionMisMatch = 0
    BEGIN

        SET @DebugText = N' no mismatch but missing assemblies';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Update Assemblies ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        
                                   SET @ProcedureStep = '';
                                   SET @LogTypeDetail = 'Status';
                                   SET @LogStatusDetail = '';
                                   SET @LogTextDetail = @DebugText
                                   SET @LogColumnName = '';
                                   SET @LogColumnValue = '';
        
                                   EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
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

         EXECUTE spmfGetLocalMFilesVersionInternal
                                              @LsMFilesVersion OUTPUT;

       SET @DebugText = N' new version %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Get new version ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@LsMFilesVersion);
        END;

        EXEC dbo.spMFUpdateAssemblies @LsMFilesVersion;

           set @Msg = ' Version changed from '+ ISNULL(@MFilesVersion,'No version found') + ' to ' + @LsMFilesVersion


end

        IF @MFilesOldVersion = 'No version found' OR @MFilesVersion = 'No version found'
        SET @IsVersionMisMatch = 1;

        IF @IsVersionMisMatch = 1
           AND @MFilesVersion <> @MFilesOldVersion 
        BEGIN
            
           SET @ProcedureStep =  'GET new version'

                  IF NOT EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfGetLocalMFilesVersionInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN

EXEC (N'
CREATE PROCEDURE [dbo].[spmfGetLocalMFilesVersionInternal]
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLocalMFilesVersion];
');


       SET @DebugText = N' new version %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Get new version for Update Assemblies';

         EXECUTE spmfGetLocalMFilesVersionInternal
                                              @LsMFilesVersion OUTPUT;

                                                      IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@LsMFilesVersion);
        END;

        EXEC dbo.spMFUpdateAssemblies @LsMFilesVersion;

       
                                  SET @ProcedureStep = '';
                                  SET @LogTypeDetail = 'Status';
                                  SET @LogStatusDetail = '';
                                  SET @LogTextDetail = ' Update Assemblies'
                                  SET @LogColumnName = '';
                                  SET @LogColumnValue = '';
       
                                  EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
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

END

  
            INSERT INTO dbo.MFUpdateHistory
            (
                Username,
                VaultName,
                UpdateMethod,
                ObjectDetails,
                UpdateStatus
            )
            VALUES
            (@Username, @VaultName, -1, 'New MFversion '+@MFilesVersion,'Updated');

            SELECT @Update_ID = @@Identity;

            --set @MFLocation= @MFLocation+'\CLPROC.Sql'
            DECLARE 
                @DBName       VARCHAR(250),
                @DBServerName VARCHAR(250);

            SELECT @DBServerName = @@ServerName;

            SELECT @DBName = DB_NAME();

  
            --	Select @ScriptFilePath=cast(Value as varchar(250)) from MFSettings where Name='AssemblyInstallPath'
          IF ISNULL(@MFilesVersion,'No version found') <> 'No version found'
          EXEC dbo.spMFUpdateAssemblies @MFilesVersion;

      set     @MSG = 'Assemblies updated'
        END;

        	-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
            set @LogText = isnull(@Msg, 'nochange')
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
			  , @LogText = @logtext
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
        SET @ProcedureStep = N'Catch matching version error ';

        UPDATE dbo.MFSettings
        SET Value = ISNULL(@MFilesOldVersion,'No version found')
        WHERE Name = 'MFVersion';

          INSERT INTO dbo.MFUpdateHistory
            (
                Username,
                VaultName,
                UpdateMethod,
                ObjectDetails,
                UpdateStatus
            )
            VALUES
            (@Username, @VaultName, -1, 'Version Update Error '+@MFilesVersion,'Error');


        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ProcedureStep,
            ErrorState,
            ErrorSeverity,
            Update_ID,
            ErrorLine
        )
        VALUES
        ('spMFCheckAndUpdateAssemblyVersion', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep,
            ERROR_STATE(), ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

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

    END CATCH;
END;
GO