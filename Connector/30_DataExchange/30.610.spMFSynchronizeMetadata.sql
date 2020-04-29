GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeMetadata]';
GO
 
/*------------------------------------------------------------------------------------------------
	Author: Thejus T V
	Create date: 27-03-2015
    Desc:  The purpose of this procedure is to synchronize M-File Meta data  
															
------------------------------------------------------------------------------------------------*/


SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeMetadata'
  , -- nvarchar(100)
    @Object_Release = '4.2.7.46'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeMetadata'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeMetadata]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFSynchronizeMetadata]
     @ProcessBatch_ID INT = NULL OUTPUT 
    ,@Debug SMALLINT = 0

AS

/*rST**************************************************************************

=======================
spMFSynchronizeMetadata
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======
To pull M-Files Metadata during initialisation of MFSQL Connector

Prerequisites
=============
Vault connection is valid

Warnings
========
Custom settings in the metadata structure tables such as tablename and columnname will not be retained

Examples
========

.. code:: sql

    EXEC [dbo].[spMFSynchronizeMetadata]

----

.. code:: sql

    DECLARE @return_value int
    EXEC    @return_value = [dbo].[spMFSynchronizeMetadata]
            @Debug = 0
    SELECT  'Return Value' = @return_value
    GO

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2018-11-15  LC         Fix processbatch_ID logging
2018-07-25  LC         Auto create MFUserMessages
2018-04-30  LC         Add to MFUserMessage
2017-08-22  LC         Improve logging
2017-08-22  LC         Change processBatch_ID to output param
2016-09-26  DEV2       Removed Vaultsettings parametes and pass them as comma separated string in @VaultSettings parameter
2016-08-22  LC         Change settings index
2015-05-25  DEV2       UserAccount and Login account is added
==========  =========  ========================================================

**rST*************************************************************************/

      BEGIN
            SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
            DECLARE @VaultSettings NVARCHAR(4000)
                  , @ProcedureStep sysname = 'START';


            DECLARE @RC INT;
            DECLARE @ProcessType NVARCHAR(50) = 'Metadata Sync';
            DECLARE @LogType NVARCHAR(50);
            DECLARE @LogText NVARCHAR(4000);
            DECLARE @LogStatus NVARCHAR(50);
            DECLARE @ProcedureName VARCHAR(100) = 'spMFSynchronizeMetadata';
            DECLARE @MFTableName NVARCHAR(128);
            DECLARE @Update_ID INT;
            DECLARE @LogProcedureName NVARCHAR(128);
            DECLARE @LogProcedureStep NVARCHAR(128);

      ---------------------------------------------
      -- ACCESS CREDENTIALS FROM Setting TABLE
      ---------------------------------------------

--used on MFProcessBatchDetail;
            DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
            DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
            DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
            DECLARE @EndTime DATETIME
            DECLARE @StartTime DATETIME
            DECLARE @StartTime_Total DATETIME = GETUTCDATE()
            DECLARE @Validation_ID INT
            DECLARE @LogColumnName NVARCHAR(128)
            DECLARE @LogColumnValue NVARCHAR(256)
        

            DECLARE @error AS INT = 0;
            DECLARE @rowcount AS INT = 0;
            DECLARE @return_value AS INT;
            SELECT  @VaultSettings = [dbo].[FnMFVaultSettings]()
        

            BEGIN

                  SET @ProcessType = @ProcedureName
                  SET @LogType = 'Status';
                  SET @LogText = @ProcedureStep + ' | ';
                  SET @LogStatus = 'Initiate';
 
 
                  EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                  , @ProcessType = @ProcessType
                  , @LogType = @LogType
                  , @LogText = @LogText
                  , @LogStatus = @LogStatus
                  , @debug = @debug;
 
 
                  BEGIN TRY
              ---------------------------------------------
              --DECLARE LOCAL VARIABLE
              --------------------------------------------- 
                        DECLARE @ResponseMFObject NVARCHAR(2000)
                              , @ResponseProperties NVARCHAR(2000)
                              , @ResponseValueList NVARCHAR(2000)
                              , @ResponseValuelistItems NVARCHAR(2000)
                              , @ResponseWorkflow NVARCHAR(2000)
                              , @ResponseWorkflowStates NVARCHAR(2000)
                              , @ResponseLoginAccount NVARCHAR(2000)
                              , @ResponseUserAccount NVARCHAR(2000)
                              , @ResponseMFClass NVARCHAR(2000)
                              , @Response NVARCHAR(2000)
                              , @SPName NVARCHAR(100);
		    ---------------------------------------------
              --SYNCHRONIZE Login Accounts
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Login Accounts'
                              , @SPName = 'spMFSynchronizeLoginAccount';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeLoginAccount]
                            @VaultSettings
                          , @Debug
                          , @ResponseLoginAccount OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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

   
		   ---------------------------------------------
              --SYNCHRONIZE Login Accounts
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing User Accounts'
                              , @SPName = 'spMFSynchronizeUserAccount';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeUserAccount]
                            @VaultSettings
                          , @Debug
                          , @ResponseUserAccount OUTPUT;

                        SET @StartTime = GETUTCDATE();


                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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
              ---------------------------------------------
              --SYNCHRONIZE OBJECT TYPES
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ObjectType'
                              , @SPName = 'spMFSynchronizeObjectType';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeObjectType]
                            @VaultSettings
                          , @Debug
                          , @ResponseMFObject OUTPUT;              

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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
            
              ---------------------------------------------
              --SYNCHRONIZE VALUE LIST
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ValueList'
                              , @SPName = 'spMFSynchronizeValueList';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeValueList]
                            @VaultSettings
                          , @Debug
                          , @ResponseValueList OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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

            
              ---------------------------------------------
              --SYNCHRONIZE VALUELIST ITEMS
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ValueList Items'
                              , @SPName = 'spMFSynchronizeValueListItems';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeValueListItems]
                            @VaultSettings
                          , @Debug
                          , @ResponseValuelistItems OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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

            
  
              ---------------------------------------------
              --SYNCHRONIZE WORKFLOW
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing workflow'
                              , @SPName = 'spMFSynchronizeWorkflow';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeWorkflow]
                            @VaultSettings
                          , @Debug
                          , @ResponseWorkflow OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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


              ---------------------------------------------
              --SYNCHRONIZE WORKFLOW STATES
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Workflow states'
                              , @SPName = 'spMFSynchronizeWorkflowsStates';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeWorkflowsStates]
                            @VaultSettings
                          , @Debug
                          , @ResponseWorkflowStates OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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
   		    ---------------------------------------------
              --SYNCHRONIZE PROEPRTY
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Properties'
                              , @SPName = 'spMFSynchronizeProperties';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeProperties]
                            @VaultSettings
                          , @Debug
                          , @ResponseProperties OUTPUT;
  
                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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
         
              ---------------------------------------------
              --SYNCHRONIZE Class
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Class'
                              , @SPName = 'spMFSynchronizeClasses';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeClasses]
                            @VaultSettings
                          , @Debug
                          , @ResponseMFClass OUTPUT;
                    SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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
         
   

-------------------------------------------------------------
-- Create MFUSerMessage Table
-------------------------------------------------------------


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserMessages'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
						BEGIN                   					

	EXEC [dbo].[spMFCreateTable] @ClassName = 'User Messages', -- nvarchar(128)
	                             @Debug = 0      -- smallint
	

	END




                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
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


                        SET @LogText = 'Processing ' + @ProcedureName + ' completed'
                        SET @LogStatus = 'Completed'
  
                        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText					  
                          , @LogStatus = @LogStatus
                          , @debug = @debug
 
                        SELECT  @ProcedureStep = 'Synchronizing metadata completed' 
                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        RETURN 1
                  END TRY 

                  BEGIN CATCH
                        SET NOCOUNT ON;

                        SET @error = @@ERROR
                        SET @LogStatusDetail = CASE WHEN ( @error <> 0
                                                           OR @return_value = -1
                                                         ) THEN 'Failed'
                                                    WHEN @return_value IN ( 1, 0 ) THEN 'Complete'
                                                    ELSE 'Exception'
                                               END
								
                        SET @LogTextDetail = @ProcedureStep + ' | Return Value: ' + CAST(@return_value AS NVARCHAR(256))
                        SET @LogColumnName = ''
                        SET @LogColumnValue = ''
                        SET @StartTime = GETUTCDATE();

                        EXEC [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = 'System'
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug;

                        SET @LogStatusDetail = NULL
                        SET @LogTextDetail = NULL
                        SET @LogColumnName = NULL
                        SET @LogColumnValue = NULL
                        SET @error = NULL	


                        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText
                          , @LogStatus = @LogStatus
                          , @debug = @debug

                        INSERT  INTO [dbo].[MFLog]
                                ( [SPName]
                                , [ProcedureStep]
                                , [ErrorNumber]
                                , [ErrorMessage]
                                , [ErrorProcedure]
                                , [ErrorState]
                                , [ErrorSeverity]
                                , [ErrorLine]
                                )
                        VALUES  ( @SPName
                                , @ProcedureStep
                                , ERROR_NUMBER()
                                , ERROR_MESSAGE()
                                , ERROR_PROCEDURE()
                                , ERROR_STATE()
                                , ERROR_SEVERITY()
                                , ERROR_LINE()
                                );

                        SET NOCOUNT OFF;

                        RETURN -1;
                  END CATCH;
            END;
      END;


GO
