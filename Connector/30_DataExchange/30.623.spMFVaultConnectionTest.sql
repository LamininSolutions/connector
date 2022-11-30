PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFVaultConnectionTest]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFVaultConnectionTest' -- nvarchar(100)
                                    ,@Object_Release = '4.10.30.74'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*

Add license check into connection test
Add check and update MFVersion if invalid
add is silent option

*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFVaultConnectionTest' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFVaultConnectionTest]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFVaultConnectionTest]
    @IsSilent INT = 0
   ,@MessageOut NVARCHAR(250) = NULL OUTPUT
   ,@ProcessBatch_id INT = NULL OUTPUT
   , @Debug INT = 0
AS

/*rST**************************************************************************

=======================
spMFVaultConnectionTest
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsSilent
    - Default = 0 : the procedure will display the result
    - Set to 1 if the connection test is used as part of a procedure.
  @MessageOut Output
    - Show the result of the test

Purpose
=======

Procedure to perform a test on the vault connection

Additional Info
===============

Performs a variety of tests when executed. These tests include

#. Validate login credentials

#. Validate the M-Files version for the assemblies

#. Validate license

Examples
========

.. code:: sql

    DECLARE @MessageOut NVARCHAR(250);
    EXEC dbo.spMFVaultConnectionTest @IsSilent = 0,
    @MessageOut = @MessageOut OUTPUT

----

.. code:: sql

   EXEC dbo.spMFVaultConnectionTest

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-11-25  LC         Add logging and improve messaging
2021-12-20  LC         Add guid to result set
2020-03-29  LC         Add documentation 
2020-02-08  LC         Fix bug for check license validation
2016-08-15  DEV1       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;
    -------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'schema.procname';
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

        DECLARE @MFTableName AS NVARCHAR(128) = ''
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Check vault connection')


    DECLARE @Return_Value INT;
    DECLARE @Guid NVARCHAR(128);
    DECLARE @vaultsettings NVARCHAR(4000)
           ,@ReturnVal     NVARCHAR(MAX);

    SELECT @vaultsettings = [dbo].[FnMFVaultSettings]();
    SELECT @Guid =CAST(value AS NVARCHAR(128)) FROM mfsettings WHERE name = 'VaultGUID'

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
		  , @Validation_ID = null
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = null
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0



    BEGIN TRY
        DECLARE @IsUpToDate BIT
               ,@RC         INT;

        EXEC @RC = [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

        IF @RC < 0
        BEGIN
            SET @MessageOut = 'Unable to Connect';
		--	SELECT @MessageOut

            RAISERROR('Error:  %s - Check MFlog or email for error detail', 16, 1, @MessageOut)
			RETURN;
        END;

        --SELECT @rc, @IsUpToDate

        -------------------------------------------------------------
        -- validate MFiles version
        -------------------------------------------------------------
   --     EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion];

        -------------------------------------------------------------
        -- validate login
        -------------------------------------------------------------

        --EXEC [dbo].[spMFGetUserAccounts] @VaultSettings = @vaultsettings -- nvarchar(4000)
        --                                ,@returnVal = @ReturnVal OUTPUT; -- nvarchar(max)
        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,[mvs].[Password] AS [EncryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
                  ,@Guid AS VaultGUID
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            SET @MessageOut = 'Successfully connected to vault';

            SELECT @MessageOut AS [OutputMessage];
        END;

        SET @Return_Value = 1;
    END TRY
    BEGIN CATCH
        SET @MessageOut = ERROR_MESSAGE();

        IF @IsSilent = 0
            SELECT @MessageOut AS [OutputMessage];

        DECLARE @EncrytedPassword NVARCHAR(100);

        SELECT TOP 1
               @EncrytedPassword = [mvs].[Password]
        FROM [dbo].[MFVaultSettings] AS [mvs];

        DECLARE @DecryptedPassword NVARCHAR(100);

        EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @EncrytedPassword          -- nvarchar(2000)
                                ,@DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,@DecryptedPassword AS [DecryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            PRINT ERROR_MESSAGE();
        END;
    END CATCH;

   -- DECLARE @messageOut NVARCHAR(50)

    SET @MessageOut = 'Unable to validate license'


    BEGIN
        BEGIN TRY

        EXEC @return_value= dbo.spMFCheckLicenseStatus @InternalProcedureName = N'spmfGetclass',             
                                @ProcedureName = N'spMFVaultConnectionTest',                       
                                @ProcedureStep = 'Validate License:',                      
                                @ExpiryNotification = 0,                    
                                @IsLicenseUpdate = 1,                    
                                @ProcessBatch_id = @ProcessBatch_id,
                                @Debug = 0                                 
 
     
   
   SELECT @MessageOut = CASE WHEN @Return_Value = 1 -- module exist in license; 
          THEN 'Validated License'
          WHEN @Return_Value = 2 --with no date if license expired
         THEN 'Invalid license date'
         WHEN @Return_Value = 3 --module does not exist in license
         THEN 'Procedure not included in license'
         WHEN @Return_Value = 4 --module does not exist in license
         THEN 'no license exist (no date returned)'
         ELSE @MessageOut
           END         


            --   SELECT @Return_Value;
            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];

		-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Status'
			  , @LogText = @MessageOut
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
			  , @LogText = @MessageOut
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = null
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = null
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

            RETURN 1;
        END TRY
        BEGIN CATCH
            SET @MessageOut = 'Invalid License: ' + ERROR_MESSAGE();

            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];
        END CATCH;
    END;
END;
