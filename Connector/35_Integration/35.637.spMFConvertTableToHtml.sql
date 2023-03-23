PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFConvertTableToHtml]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFConvertTableToHtml' -- nvarchar(100)
  , @Object_Release = '4.9.26.67'
  , @UpdateFlag = 2

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFConvertTableToHtml' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFConvertTableToHtml]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER  PROCEDURE [dbo].[spMFConvertTableToHtml](
      @SqlQuery AS NVARCHAR(4000)          
      ,@TableBody AS NVARCHAR(Max) OUTPUT
      ,@ProcessBatch_ID INT	  = NULL OUTPUT
	  , @Debug			 SMALLINT = 0     
)
AS 
/*rST**************************************************************************

======================
spMFConvertTableToHtml
======================

Return
1 = Success
-1 = Error

Parameters
==========

@SqlQuery 
  - The table select query to be converted
@TableBody OUTPUT
  - Output in html format
@ProcessBatch_ID (optional, output)
  - Referencing the ID of the ProcessBatch logging table
@Debug (optional)
  - Default = 0
  - 1 = Standard Debug Mode

Purpose
=======

Returns a HTML formatted text for a given select statement.

Additional info
===============

This procedure is useful to export the result of a select statement of a view or table for inclusion in an email, report or another result.

Past the content of the HTML outout variable to into a text file with extension .htm and open with a browser to view the result.


Examples
========

.. code:: sql

    DECLARE @Html AS VARCHAR(MAX)
    EXECUTE spMFConvertTableToHtml ' SELECT  * FROM MFclass ',@Html OUTPUT
    SELECT @Html

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-26  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = null
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Table to HTML')

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
	
		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFConvertTableToHtml';
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
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

                SET @ProcedureStep = 'set custom variables'
 
         DECLARE @Html AS VARCHAR(MAX) = ''
         DECLARE @Command AS VARCHAR(8000) = ''
         DECLARE @Header AS NVARCHAR(MAX) = ''
         DECLARE @Column AS NVARCHAR(MAX) = ''
         DECLARE @Query AS NVARCHAR(MAX)
         DECLARE @Css AS VARCHAR(MAX) = '
            <style type="text/css">

            table.gridtable {
                font-family: verdana,arial,sans-serif;
                font-size:11px;
                color:#666666;
                border-width: 1px;
                border-color: #666666;
                border-collapse: collapse;
            }

            table.gridtable th {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #666666;
                background-color: #666666;
            }

            table.gridtable td {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #666666;
                background-color: #ffffff;
            }

            </style>
            '
BEGIN

SET @ProcedureStep = 'insert table into ##columns'

      SET @Query = 'SELECT * INTO ##columns FROM ( ' + @SqlQuery + ') Temp'
  
  IF @debug > 0
  SELECT @Query;
  
  EXECUTE(@Query)



    SELECT @Column = @Column + 'ISNULL( CONVERT( VARCHAR(MAX),' + QUOTENAME(name ) + ',1)  ,'' '')' + ' AS TD , '
       --SELECT @Column = @Column + QUOTENAME(name) + ' AS TD, '

      FROM tempdb.SYs.columns
      WHERE object_id = OBJECT_ID('tempdb..##columns')
    
      SET  @Column = LEFT(@Column,LEN(@Column)-1)

      SET @ProcedureStep = 'Compile HTML for columns and rows'

      SELECT @Header = @Header + '<TH>' +  name + '</TH>'
      FROM tempdb.SYs.columns
      WHERE object_id = OBJECT_ID('tempdb..##columns')
    
      SET @Header = '<TR>' + @Header  + '</TR>'
    
      SET @Query = 'SET  @Html = (SELECT ' + @Column + ' FROM ( ' + @SqlQuery + ') AS TR
       FOR XML AUTO ,ROOT(''TABLE''), ELEMENTS)'

 -- SELECT @query      

      EXECUTE SP_EXECUTESQL @Query,N'@Html VARCHAR(MAX) OUTPUT',@Html OUTPUT

--SELECT @Html, @Css,@Html
--SELECT '<TABLE  class="gridtable">' + @Header

      SET  @Html = @Css + REPLACE(@Html,'<TABLE>' ,'<TABLE  class="gridtable">' + @Header)

     DROP TABLE ##columns


     -------------------------------------------------------------
			SET @DebugText = 'HTML body'
			Set @DebugText = @DefaultDebugText + @DebugText
			
			IF @debug > 0
				BEGIN 
                SELECT @html
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

     SELECT @TableBody = @Html
   
END

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
			  , @LogType = N'Debug'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
			  , @LogText = @ProcessType
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


