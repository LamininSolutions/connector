
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFRemoveAdditionalProperties]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFRemoveAdditionalProperties' -- nvarchar(100)
  , @Object_Release = '4.9.25.67'
  , @UpdateFlag = 2

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFRemoveAdditionalProperties' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFRemoveAdditionalProperties]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFRemoveAdditionalProperties]
	(   @MFTableName NVARCHAR(200),
        @Columns NVARCHAR(4000) = NULL,
		@ProcessBatch_ID INT	  = NULL OUTPUT,
	   @Debug			 SMALLINT = 0
	)
AS
/*rST**************************************************************************

==============================
spMFRemoveAdditionalProperties
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Columns
    - default = null.  
    - If set to null then all columns with no data in that is not included in the metadatacard will be removed.
    - Set @Columns to a comma delimited string to validate and remove specific columns
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

M-Files allows for properties to be added to the metadata card as additional properties. Sometimes these properties becomes redundant.  The Connector will automatically create columns for properties when they are used. Over time this may add many columns on the class table that is no longer used or relevant.  This procedure will allow for identifying the empty columns, validated that they are no longer included in the metadata card specification and remove them.

Additional Info
===============

By default the column will only be removed if all data has been removed.  Property columns where property MFID < 1000 is ignored.

do a normal update from SQL to MF by setting the data in unwanted columns to null, and set the process_id = 1 to remove the data in unwanted columns.

When @Column is null then all additional property columns with null data will be removed.

To remove columns where the property MFID < 1000 the column must be specified e.g. @Columns = 'Is_Template'

Examples
========

deleting additional columns where all data is null

.. code:: sql

    DECLARE @ProcessBatch_ID1 INT;

    EXEC dbo.spMFRemoveAdditionalProperties @MFTableName = 'MFOtherDocument',
    @ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT,
    @Debug = 1

----------------------------

Deleting specified columns

.. code:: sql

    DECLARE @ProcessBatch_ID1 INT;

    EXEC dbo.spMFRemoveAdditionalProperties @MFTableName = 'MFOtherDocument',
    @columns = 'Is_Template',
    @ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT,
    @Debug = 1
   
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------

2020-12-19  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
		SET NOCOUNT ON;

        BEGIN -- parameters
		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
	
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Remove additional properties')

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
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFRemoveAdditionalProperties';
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
        -- Custom variables
        -------------------------------------------------------------
DECLARE @id INT = 1;
DECLARE @columnname NVARCHAR(100);
DECLARE @Status INT;

END -- end parameters
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
			Set @Procedurestep = 'Update table'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

  -------------------------------------------------------------
  -- update table
  -------------------------------------------------------------              
  DECLARE @MFLastUpdateDate SMALLDATETIME
  
  EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,
      @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,
      @UpdateTypeID = 1,   
      @WithStats = 0,
      @Update_IDOut = @Update_ID OUTPUT,
      @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
      @debug = 0

  -------------------------------------------------------------
  -- validate column list
  -------------------------------------------------------------
  
IF
(
    SELECT OBJECT_ID('tempdb..#Columnlist')
) IS NOT NULL
    DROP TABLE #Columnlist;

CREATE TABLE #Columnlist
(
    id INT IDENTITY PRIMARY KEY,
    columnname NVARCHAR(100),
    Datatype INT,
    ColumnType NVARCHAR(100),
    Status INT DEFAULT(9)
);

IF @Debug > 0
SELECT @Columns AS columns;


IF @Columns IS NULL 
BEGIN -- @column is null

-------------------------------------------------------------
-- Remove all empty columns with property id's > 1000
-------------------------------------------------------------
  SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Validate column list'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

EXEC dbo.spMFClassTableColumns @ErrorsOnly = 0,
    @IsSilent = 1,
    @MFTableName = @MFTableName,
    @Debug = 0

INSERT INTO #Columnlist
(
    columnname,
    Datatype,
    ColumnType,
    Status
)
SELECT cc.Columnname,cc.MFdataType_ID , cc.ColumnType,
 CASE WHEN cc.ColumnType = 'Additional Property' THEN 2
    ELSE 1
    END
FROM ##spMFclassTableColumns cc WHERE TableName = @MFTableName

UPDATE c2
SET STATUS = 2
FROM #Columnlist AS c
INNER JOIN #Columnlist AS c2
ON c2.columnname = SUBSTRING(c.columnname,1, LEN(c.columnname)-3)
WHERE C.Status = 2

IF @debug > 0
SELECT * FROM #Columnlist AS c WHERE status > 1;

 Set @Procedurestep = 'Drop columns loop'
WHILE @id IS NOT NULL
BEGIN
 
    SELECT @columnname = t.columnname,    
        @Status   = t.status
    FROM #Columnlist AS t
    WHERE t.id = @id;

    SET @sqlParam = N'@count int output, @Status int'
    SET @sql = N'
    SELECT @count = COUNT(*) FROM '+ QUOTENAME(@MFTableName) + ' AS t
    WHERE ' + quotename(@columnname) + ' IS NOT NULL and @Status > 1;'

    --IF @debug > 0
    --PRINT @SQL;

    EXEC sp_executeSQL @SQL, @sqlParam, @count = @count OUTPUT,  @status = @Status;

    UPDATE l 
    SET status = CASE WHEN @count = 0 THEN 3 ELSE status end 
    FROM #columnlist l WHERE columnname = @Columnname AND status > 1

    SET @count = @@RowCount
    -------------------------------------------------------------
    -- Remove columns
    -------------------------------------------------------------
    IF EXISTS (SELECT columnname FROM #Columnlist AS c WHERE Status = 3 AND c.columnname = @columnname)
    Begin
    SET @SQL = N'
    ALTER TABLE ' + QUOTENAME(@MFTableName) + '
    DROP COLUMN ' + QUOTENAME(@Columnname) + ';'

    EXEC(@SQL)

    Set @DebugText = 'Column Dropped : ' + @columnname
    Set @DebugText = @DefaultDebugText + @DebugText
   
    IF @debug > 0
    	Begin
    		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
    	END
    END

    SELECT @id = (SELECT MIN(id) FROM #Columnlist AS t WHERE id >@id)
END -- end loop;

if @debug > 0
SELECT * FROM #Columnlist AS c WHERE STATUS > 1;

END -- remove empty columns

IF @Columns IS NOT NULL
BEGIN -- @Column is specified

INSERT INTO #Columnlist
(
    columnname,
    Status
)
SELECT fmpds.ListItem, 2  FROM dbo.fnMFParseDelimitedString(@Columns,',') AS fmpds

 SET @DebugText = @Columns
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Validate specified columns: '
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

IF @debug > 0
SELECT * FROM #Columnlist AS c WHERE status > 1;

 Set @Procedurestep = 'Drop specified columns loop'
WHILE @id IS NOT NULL
BEGIN -- BEGIN  LOOP
 
    SELECT @columnname = t.columnname,    
        @Status   = t.status
    FROM #Columnlist AS t
    WHERE t.id = @id;

    SET @sqlParam = N'@count int output, @Status int'
    SET @sql = N'
    SELECT @count = COUNT(*) FROM '+ QUOTENAME(@MFTableName) + ' AS t
    WHERE ' + quotename(@columnname) + ' IS NOT NULL and @Status > 1;'

    --IF @debug > 0
    --PRINT @SQL;

    EXEC sp_executeSQL @SQL, @sqlParam, @count = @count OUTPUT,  @status = @Status;

    UPDATE l 
    SET status = CASE WHEN @count = 0 THEN 3 ELSE status end 
    FROM #columnlist l WHERE columnname = @Columnname AND status > 1

    SET @count = @@RowCount
    -------------------------------------------------------------
    -- Remove columns
    -------------------------------------------------------------
    IF EXISTS (SELECT columnname FROM #Columnlist AS c WHERE Status = 3 AND c.columnname = @columnname)
    Begin
    SET @SQL = N'
    ALTER TABLE ' + QUOTENAME(@MFTableName) + '
    DROP COLUMN ' + QUOTENAME(@Columnname) + ';'

    EXEC(@SQL)

    Set @DebugText = 'Column Dropped : ' + @columnname
    Set @DebugText = @DefaultDebugText + @DebugText
   
    IF @debug > 0
    	Begin
    		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
    	END
    END

    SELECT @id = (SELECT MIN(id) FROM #Columnlist AS t WHERE id >@id)

    END -- end loop

END -- @columns is specified

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
			  , @LogType = N'Message'
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

