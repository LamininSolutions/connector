 
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeUnManagedObject]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFSynchronizeUnManagedObject'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
 

  ********************************************************************************
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFSynchronizeUnManagedObject' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeUnManagedObject]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter Procedure spMFSynchronizeUnManagedObject
(
   @ExternalRepositoryObjectIDs NVARCHAR(MAX) 
  ,@TableName NVARCHAR(100)='MFUnmanagedObject'
  ,@Debug SMALLINT = 0
  ,@ProcessBatch_ID INT = NULL OUTPUT
) as /*******************************************************************************
  ** Desc:  

  
  ** Date:				27-03-2015
  ********************************************************************************
 
  ******************************************************************************/
Begin
  DECLARE @Update_ID    INT
  ,@return_value INT = 1;
	 --BEGIN TRANSACTION
BEGIN TRY
    SET NOCOUNT ON;

    SET XACT_ABORT ON

	DECLARE 
            @SynchErrorObj      NVARCHAR(MAX) --Declared new paramater
           ,@DeletedObjects     NVARCHAR(MAX) --Declared new paramater
           ,@ProcedureName      sysname        = 'spMFSynchronizeUnManagedObject'
           ,@ProcedureStep      sysname        = 'Start'
           ,@ObjectId           INT
           ,@ClassId            INT
           ,@Table_ID           INT
           ,@ErrorInfo          NVARCHAR(MAX)
           ,@Params             NVARCHAR(MAX)
           ,@SynchErrCount      INT
           ,@ErrorInfoCount     INT
           ,@MFErrorUpdateQuery NVARCHAR(1500)
		   ,@VaultSettings      NVARCHAR(4000)
          


	DECLARE @Idoc INT
				DECLARE @Result NVARCHAR(max)
				DECLARE @Query NVARCHAR(max)
				DECLARE @TempObjectList VARCHAR(100)
				DECLARE @TempExistingObjects VARCHAR(100)
				DECLARE @TempNewObjects VARCHAR(100)
				DECLARE @TempIsTemplatelist VARCHAR(100)
				DECLARE @Name_or_Title NVARCHAR(100)
				DECLARE @InsertQuery AS NVARCHAR(MAX)
				DECLARE @TempUpdateQuery AS NVARCHAR(MAX)
				DECLARE @XML xml
				DECLARE @TempInsertQuery NVARCHAR(max)
				DECLARE @UpdateQuery NVARCHAR(MAX)
				DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
			    DECLARE @DebugText AS NVARCHAR(256) = '';
				DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
			    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
				DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
				DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
				DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
				DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
				DECLARE @ProcessType NVARCHAR(50);
				DECLARE @LogType AS NVARCHAR(50) = 'Status';
				DECLARE @LogText AS NVARCHAR(4000) = '';
				DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
				DECLARE @Status AS NVARCHAR(128) = NULL;
				DECLARE @Validation_ID INT = NULL;
				DECLARE @StartTime AS DATETIME;
				DECLARE @RunTime AS DECIMAL(18, 4) = 0;
				DECLARE @Columns AS NVARCHAR(MAX)
			    DECLARE @ColumnNames NVARCHAR(MAX)
		        DECLARE @ColumnForInsert NVARCHAR(MAX)
				DECLARE @UpdateColumns NVARCHAR(MAX)
				DECLARE @ReturnVariable INT = 1

				SELECT @TempObjectList = [dbo].[fnMFVariableTableName]('##ObjectList', DEFAULT);
				SELECT @TempExistingObjects = [dbo].[fnMFVariableTableName]('##ExistingObjects', DEFAULT);
				SELECT @TempNewObjects = [dbo].[fnMFVariableTableName]('##TempNewObjects', DEFAULT);
				SELECT @TempIsTemplatelist = [dbo].[fnMFVariableTableName]('##IsTemplateList', DEFAULT);

				----------------------------------------------------
				--GET LOGIN CREDENTIALS
				-----------------------------------------------------
				SET @ProcedureStep = 'Get Security Variables';

				DECLARE @Username NVARCHAR(2000);
				DECLARE @VaultName NVARCHAR(2000);

				SELECT TOP 1
						@Username  = [Username]
						 ,@VaultName = [VaultName]
				FROM [dbo].[MFVaultSettings];

				SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();


				-------------------------------------------------------------
				-- Set process type
				-------------------------------------------------------------
				SELECT @ProcessType = 'UpdateSQL'

						-------------------------------------------------------------
				--	Create Update_id for process start 
				-------------------------------------------------------------
				SET @ProcedureStep = 'set Update_ID';
				SET @StartTime = GETUTCDATE();

				INSERT INTO [dbo].[MFUpdateHistory]
				(
					[Username]
				   ,[VaultName]
				   ,[UpdateMethod]
				)
				VALUES
				(@Username, @VaultName, 1);

				SELECT @Update_ID = @@Identity;


				
				SET @ProcedureStep = 'Start ';
				SET @StartTime = GETUTCDATE();
				SET @ProcessType = @ProcedureName;
				SET @LogType = 'Status';
				SET @LogStatus = 'Initiate';
				SET @LogText = 'Getting Unmanage object Details for ID''s From M-Files: ' + CAST(@ExternalRepositoryObjectIDs AS VARCHAR(200));

				IF @Debug > 0
				BEGIN
					RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
				END;

				EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
																	   ,@ProcessType = @ProcessType
																	   ,@LogType = @LogType
																	   ,@LogText = @LogText
																	   ,@LogStatus = @LogStatus
																	   ,@debug = @Debug;
              -- SELECT @Update_IDOut = @Update_ID;

			   
						-----------------------------------------------------------------
						-- Checking module access for CLR procdure  spMFCreateObjectInternal
						------------------------------------------------------------------
						--EXEC [dbo].[spMFCheckLicenseStatus] 'spMFCreateObjectInternal'
						--					,@ProcedureName
						--					,@ProcedureStep;

						SET @ProcedureStep = 'Prepare Table ';
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Debug';
        SET @LogTextDetail = 'Creating Property temp temp table from xML';
        SET @LogColumnName = '';
        SET @LogColumnValue = '';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @TableName
                                                                     ,@Validation_ID = NULL
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;


						exec spMFGetUnManagedObjectDetails 
						                           @ExternalRepositoryObjectIDs,
												   @VaultSettings,
												-- 'test,00Q184mbRi8=,localhost,Sample Vault,ncacn_ip_tcp,2266,3,',
												   @Result out

		
		   
				
		

				select @Xml=cast(@Result as xml)

				Create table #TemProp
				(
					[objId] INT,
					Properties_ID INT,
					Name NVARCHAR(250),
					DisplayValue NVARCHAR(1000),
					DataType NVARCHAR(100)
				)
			   EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @Xml;
				
						
				SELECT @ProcedureStep = 'Inserting Values into #TemProp from XML';

				IF @Debug > 0
				RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);


				----------------------------------------
				--Insert XML data into Temp Table
				----------------------------------------


							
				 INSERT into #TemProp
				 (
				    [objId],
				    [Properties_ID],
					[Name],
					[DisplayValue],
					[DataType]
				 ) 
				   SELECT  
				   [objId],
				   Properties_ID,
				   Name,
				   DisplayValue,
				   DataType
				   FROM    
				    OPENXML(@Idoc, '/Form/Object/Properties', 1)
				            WITH
				            (
				                [objId] INT '../@objectId',
				                [Properties_ID] INT '@ID',
				                [Name] NVARCHAR(4000) '@Name',
				                [DisplayValue] NVARCHAR(1000) '@DisplayValue',
								[DataType] NVARCHAR(100) '@DataType'
				            );

							SELECT @ProcedureStep = 'Updating Table column Name';
						
							IF @Debug > 0
							BEGIN
							  SELECT 'List of properties from MF' AS [Properties],
							*
							FROM [#TemProp];
							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							END;


							-------------------------------------------------------------
							-- localisation of date time for finish time
							-------------------------------------------------------------
							UPDATE [p]
							SET [p].[DisplayValue] = REPLACE([p].[DisplayValue], '.', ':')
							FROM [#TemProp] AS [p]
							WHERE [p].[dataType] IN ( 'MFDataTypeTimestamp', 'MFDataTypeDate' );

							----------------------------------------------------------------
							--Update property name with column name from MFProperty Tbale
							----------------------------------------------------------------

							UPDATE [#TemProp]
							SET [Name] =
							(
								SELECT [ColumnName]
								FROM [dbo].[MFProperty]
								WHERE [MFID] = [#TemProp].[Properties_ID] 
							);

							SELECT @ProcedureStep = 'Adding columns from MFTable which are not exists in #Properties';
							IF @Debug > 0
							BEGIN
								RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							END;


							------------------------------------------------
							--Select the existing columns from MFTable
							-------------------------------------------------
							INSERT INTO [#TemProp]
							(
								[Name]
							)
							SELECT *
							FROM
							(
								SELECT [COLUMN_NAME]
								FROM [INFORMATION_SCHEMA].[COLUMNS]
								WHERE [TABLE_NAME] = @TableName
										AND [COLUMN_NAME] NOT LIKE 'ID'
										AND [COLUMN_NAME] NOT LIKE 'LastModified'
										AND [COLUMN_NAME] NOT LIKE 'Process_ID'
										AND [COLUMN_NAME] NOT LIKE 'Deleted'
										AND [COLUMN_NAME] NOT LIKE 'ObjID'
										AND [COLUMN_NAME] NOT LIKE 'MFVersion'
										AND [COLUMN_NAME] NOT LIKE 'MX_'
										AND [COLUMN_NAME] NOT LIKE 'GUID'
										AND [COLUMN_NAME] NOT LIKE 'ExternalID'
										AND [COLUMN_NAME] NOT LIKE 'FileCount' --Added For Task 106
										AND [COLUMN_NAME] NOT LIKE 'Update_ID'
								EXCEPT
								SELECT DISTINCT
										([Name])
								FROM [#TemProp]
							) [m];


							SELECT @ProcedureStep = 'PIVOT';

							IF @Debug > 0
							BEGIN
							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							END;


		
							-------------------------------------------------------------------------------
								--Selecting The Distinct PropertyName to Create The Columns
							--------------------------------------------------------------------------------

		

							SELECT @Columns = STUFF(
							(
								SELECT ',' + QUOTENAME([ppt].[Name])
								FROM [#TemProp] [ppt]
								GROUP BY [ppt].[Name]
								ORDER BY [ppt].[Name]
								FOR XML PATH(''), TYPE
							).[value]('.', 'NVARCHAR(MAX)'),
							1   ,
							1   ,
							''
													);

							  
							SELECT @ColumnNames = '';


							SELECT @ProcedureStep = 'Select All column names from MFTable';

							IF @Debug > 0
							BEGIN
							SELECT @Columns AS 'Distinct Properties';
							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							END;


							--------------------------------------------------------------------------------
							--Select Column Name Except 'ID','LastModified','Process_ID'
							--------------------------------------------------------------------------------
							SELECT 
								@ColumnNames = @ColumnNames + QUOTENAME([COLUMN_NAME]) + ','
							FROM 
								[INFORMATION_SCHEMA].[COLUMNS]
							WHERE 
								[TABLE_NAME] = @TableName
								AND [COLUMN_NAME] NOT LIKE 'ID'
								AND [COLUMN_NAME] NOT LIKE 'LastModified'
								AND [COLUMN_NAME] NOT LIKE 'Process_ID'
								AND [COLUMN_NAME] NOT LIKE 'Deleted'
								AND [COLUMN_NAME] NOT LIKE 'MX_%'
								AND [COLUMN_NAME] NOT LIKE 'Update_ID'
								AND [COLUMN_NAME] NOT LIKE 'External_ObjectID%';

							SELECT @ColumnNames = SUBSTRING(@ColumnNames, 0, LEN(@ColumnNames));

							 SELECT @ProcedureStep = 'Inserting PIVOT Data into  @TempObjectList';

							------------------------------------------------------------------------------------------------------------------------
							--Dynamic Query to Converting row into columns and inserting into [dbo].[tempobjectlist] USING PIVOT
							------------------------------------------------------------------------------------------------------------------------
							SELECT @Query
								= 'SELECT *
											INTO ' + @TempObjectList
									+ '
											FROM (
													select
													objId,' + @Columns
									+ '
												FROM (
														SELECT
														objId, 
														Name new_col
														,value
													FROM 
														#TemProp
													UNPIVOT(value FOR col IN (DisplayValue)) as un
													) as src
												PIVOT(MAX(value) FOR new_col IN (' + @Columns + ')) p
												) PVT';

							--    print @Query
							EXECUTE [sys].[sp_executesql] @Query;


								IF @Debug > 0
								BEGIN
								RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
								END;

							---------------------------------------------------------
								--Add additional columns to Class Table
							-------------------------------------------------
							   SELECT @ProcedureStep = 'Add Additional columns to class table ';

							CREATE TABLE [#Columns]
							(
								[propertyName] [NVARCHAR](100) NULL,
								[dataType] [NVARCHAR](100) NULL
							);

							SET @Query
								= N'
									INSERT INTO #Columns (PropertyName) SELECT * FROM (
									SELECT Name AS PropertyName FROM tempdb.sys.columns 
									WHERE object_id = Object_id(''tempdb..' + @TempObjectList
									+ ''')
							EXCEPT
								SELECT COLUMN_NAME AS name
								FROM INFORMATION_SCHEMA.COLUMNS
								WHERE TABLE_NAME = ''' + @TableName + ''') v';

							EXEC [sys].[sp_executesql] @Query;

							IF @Debug > 0
							BEGIN

							RAISERROR('Proc: %s Step: %s Delete Template', 10, 1, @ProcedureName, @ProcedureStep);
							END;

							-------------------------------------------------
							--Updating property datatype
							-------------------------------------------------
							UPDATE [#Columns]
							SET [dataType] =
								(
									SELECT [SQLDataType]
									FROM [dbo].[MFDataType]
									WHERE [ID] IN (
														SELECT [MFDataType_ID]
														FROM [dbo].[MFProperty]
														WHERE [ColumnName] = [#Columns].[propertyName]
													)
								);

							-------------------------------------------------------------------------
							----Set dataype = NVARCHAR(100) for lookup and multiselect lookup values
							-------------------------------------------------------------------------
							UPDATE [#Columns]
							SET [dataType] = ISNULL([dataType], 'NVARCHAR(100)');

							DECLARE @AlterQuery NVARCHAR(MAX)
							SELECT @AlterQuery = '';

							---------------------------------------------
							--Add new columns into MFTable
							---------------------------------------------
							SELECT @AlterQuery
								= @AlterQuery + 'ALTER TABLE [' + @TableName + '] Add [' + [propertyName] + '] ' + [dataType] + '  '
							FROM [#Columns];

							IF @Debug > 0
							BEGIN
							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

							END;

							EXEC [sys].[sp_executesql] @AlterQuery;

							--------------------------------------------------------------------------------
							--Get datatype of column for Insertion
							--------------------------------------------------------------------------------
							SELECT @ColumnForInsert = '';
							 SELECT @ProcedureStep = 'Get datatype of column';

							SELECT @ColumnForInsert
								= @ColumnForInsert
									+ CASE
										WHEN [DATA_TYPE] = 'DATE' THEN
											' CONVERT(DATETIME, NULLIF(' + REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105) AS '
											+ QUOTENAME([COLUMN_NAME]) + ','
										WHEN [DATA_TYPE] = 'DATETIME' THEN
											' DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()),CONVERT(DATETIME, NULLIF('
											+ REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 )) AS ' + QUOTENAME([COLUMN_NAME])
											+ ','
										WHEN [DATA_TYPE] = 'BIT' THEN
											'CASE WHEN ' + QUOTENAME([COLUMN_NAME]) + ' = ''1'' THEN  CAST(''1'' AS BIT) WHEN '
											+ QUOTENAME([COLUMN_NAME]) + ' = ''0'' THEN CAST(''0'' AS BIT)  ELSE 
											null END AS ' + QUOTENAME([COLUMN_NAME]) + ','
									--      + QUOTENAME([COLUMN_NAME]) + ' END AS ' + QUOTENAME([COLUMN_NAME]) + ','
										WHEN [DATA_TYPE] = 'NVARCHAR' THEN
											' CAST(NULLIF(' + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + '('
											+ CASE
													WHEN [CHARACTER_MAXIMUM_LENGTH] = -1 THEN
														'MAX)) AS ' + QUOTENAME([COLUMN_NAME]) + ','
													ELSE
														CAST(NULLIF([CHARACTER_MAXIMUM_LENGTH], '') AS NVARCHAR) + ')) AS '
														+ QUOTENAME([COLUMN_NAME]) + ','
												END
										WHEN [DATA_TYPE] = 'FLOAT' THEN
											' CAST(NULLIF(REPLACE(' + QUOTENAME([COLUMN_NAME]) + ','','',''.''),'''') AS float) AS '
											+ QUOTENAME([COLUMN_NAME]) + ','
										ELSE
											' CAST(NULLIF(' + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + ') AS '
											+ QUOTENAME([COLUMN_NAME]) + ','
									END
							FROM 
								[INFORMATION_SCHEMA].[COLUMNS]
							WHERE 
							[TABLE_NAME] = @TableName
									AND [COLUMN_NAME] NOT LIKE 'ID'
									AND [COLUMN_NAME] NOT LIKE 'LastModified'
									AND [COLUMN_NAME] NOT LIKE 'Process_ID'
									AND [COLUMN_NAME] NOT LIKE 'Deleted'
									AND [COLUMN_NAME] NOT LIKE 'MX_%'
									AND [COLUMN_NAME] NOT LIKE 'Update_ID'
									AND [COLUMN_NAME] NOT LIKE 'External_ObjectID%';



 


						----------------------------------------
						--Remove the Last ','
						----------------------------------------
								SELECT @ColumnForInsert = SUBSTRING(@ColumnForInsert, 0, LEN(@ColumnForInsert));


								IF @Debug > 0
								BEGIN
								--          SELECT  @ColumnForInsert AS '@ColumnForInsert';
								RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
								END;

						----------------------------------------
						--Add column values to data type
						----------------------------------------

						set @UpdateColumns=''
						SELECT @UpdateColumns
							= @UpdateColumns
								+ CASE
									WHEN [DATA_TYPE] = 'DATE' THEN
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + ' = CONVERT(DATETIME, NULLIF(t.'
										+ REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 ) ,'
									WHEN [DATA_TYPE] = 'DATETIME' THEN
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME])
										+ ' = DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()), CONVERT(DATETIME,NULLIF(t.'
										+ REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 )),'
									WHEN [DATA_TYPE] = 'BIT' THEN
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + ' =(CASE WHEN ' + 't.'
										+ QUOTENAME([COLUMN_NAME]) + ' = 1 THEN  CAST(1 AS BIT)  WHEN t.'
										+ QUOTENAME([COLUMN_NAME]) + ' = 0 THEN CAST(0 AS BIT)  
										ELSE NULL END ),'
										--WHEN t.'
						--                  + QUOTENAME([COLUMN_NAME]) + ' = ''""'' THEN CAST(''NULL'' AS BIT)  END )  ,'
									WHEN [DATA_TYPE] = 'NVARCHAR' THEN
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(t.'
										+ QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + '('
										+ CASE
												WHEN [CHARACTER_MAXIMUM_LENGTH] = -1 THEN
													CAST('MAX' AS NVARCHAR)
												ELSE
													CAST([CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR)
											END + ')) ,'
									WHEN [DATA_TYPE] = 'Float' THEN
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(REPLACE(t.'
										+ QUOTENAME([COLUMN_NAME]) + ','','',''.'')' + ','''') AS ' + [DATA_TYPE] + ') ,'
									ELSE
										'' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(t.'
										+ QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + ') ,'
								END
						FROM [INFORMATION_SCHEMA].[COLUMNS]
						WHERE [TABLE_NAME] = @TableName
								AND [COLUMN_NAME] NOT LIKE 'ID'
								AND [COLUMN_NAME] NOT LIKE 'LastModified'
								AND [COLUMN_NAME] NOT LIKE 'Process_ID'
								AND [COLUMN_NAME] NOT LIKE 'Deleted'
								AND [COLUMN_NAME] NOT LIKE 'MX_%'
								AND [COLUMN_NAME] NOT LIKE 'Update_ID'
								AND [COLUMN_NAME] NOT LIKE 'External_ObjectID%';

			
						----------------------------------------
							--Remove the last ','
						----------------------------------------
						SELECT @UpdateColumns = SUBSTRING(@UpdateColumns, 0, LEN(@UpdateColumns));



							SELECT @ProcedureStep = 'Create object columns';

							IF @Debug > 0
							BEGIN

							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							IF @Debug > 0
							BEGIN
							SELECT @UpdateColumns AS '@UpdateColumns';
							SET @Query = N'	
							SELECT ''tempobjectlist'' as [TempObjectList],* FROM ' + @TempObjectList + '';
							EXEC (@Query);
							END;
							END;
		

						----------------------------------------
						--prepare temp table for existing object
						----------------------------------------
						SELECT @TempUpdateQuery
						= 'SELECT *
											INTO ' + @TempExistingObjects + '
											FROM ' + @TempObjectList + '
											WHERE ' + @TempObjectList
							+ '.[ObjID]  IN (
													SELECT [External_ObjectID]
													FROM [' + @TableName + ']
									   
													)';

						EXECUTE [sys].[sp_executesql] @TempUpdateQuery;


						SELECT @ProcedureStep = 'Update existing objects';

						IF @Debug > 0
						BEGIN

							RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
						IF @Debug > 0
						BEGIN
							SET @Query = N'	
							SELECT ''tempExistingobjects'' as [tempExistingobjects],* FROM ' + @TempExistingObjects + '';
							EXEC (@Query);
						END;
						END;


      --------------------------------------------------------------------------------------------
        --Update existing records in Class Table and log the details of records which failed to update
        --------------------------------------------------------------------------------------------
        SELECT @ProcedureStep = 'Determine count of records to Update';

		SET @Params = N'@Count int output';
        SET @Query = N'SELECT @count = count(*)
		FROM  ' + @TempExistingObjects + '';

        EXEC [sys].[sp_executesql] @stmt = @Query,
                                   @param = @Params,
                                   @Count = @ReturnVariable OUTPUT;

        IF @Debug > 0
        BEGIN
            RAISERROR('Proc: %s Step: %s : %i', 10, 1, @ProcedureName, @ProcedureStep, @ReturnVariable);
        END;

		SET @ProcedureStep = @ProcedureStep;
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Update';
        SET @LogTextDetail = 'UPdating existing records';
        SET @LogColumnName = '';
        SET @LogColumnValue = '';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @TableName
                                                                     ,@Validation_ID = NULL
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

						SELECT @UpdateQuery
							= '
										UPDATE [' + @TableName + ']
											SET ' + @UpdateColumns + ' ,External_ObjectID= t.[ObjID] 
											FROM [' + @TableName + '] INNER JOIN ' + @TempExistingObjects
								+ ' as t
											ON [' + @TableName + '].External_ObjectID = 
										t.[ObjID]  ; '



		     ----------------------------------------
            --Executing Dynamic Query
            ----------------------------------------

			EXEC [sys].[sp_executesql] @stmt = @UpdateQuery;

        SELECT @ProcedureStep = 'Setup insert new objects Query';
		SET @ProcedureStep = @ProcedureStep;
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Insert';
        SET @LogTextDetail = 'Inserting new records into the MFUnManagedObject table';
        SET @LogColumnName = '';
        SET @LogColumnValue = '';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @TableName
                                                                     ,@Validation_ID = NULL
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;




							SELECT @TempInsertQuery
							= N'Select ' + @TempObjectList + '.* INTO ' + @TempNewObjects + '
							from ' + @TempObjectList+' where ' + @TempObjectList +'.ObjID NOT IN (SELECT External_ObjectID from '+@TableName+')'

							IF @Debug > 0
							BEGIN
								SELECT  @TempInsertQuery AS '@TempInsertQuery';
								RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
							END;


								EXECUTE [sys].[sp_executesql] @TempInsertQuery;

								SELECT @ProcedureStep = 'Insert validated records';

							SELECT @InsertQuery
								= 'INSERT INTO [' + @TableName + ' ] (' + @ColumnNames
									+ ',Process_ID,External_ObjectID
										   
															)
															SELECT *
															FROM (
																SELECT ' + @ColumnForInsert+ ',0 as Process_ID,'+@TempNewObjects+'.[ObjID] as External_ObjectID
																											FROM ' + @TempNewObjects + ') t';
	
							IF @Debug > 0
							BEGIN
									RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
									SELECT @InsertQuery AS '@InsertQuery';
							END;
							
							 SELECT @ProcedureStep = 'Inserted Records';	
							EXECUTE [sys].[sp_executesql] @InsertQuery;
     
							IF @Debug > 0
							BEGIN
									SET @Query
									= N'	
									SELECT ''Inserted'' as inserted ,* FROM ' + QUOTENAME(@TableName) + ' ClassT INNER JOIN '
									+ @TempNewObjects + ' UpdT  on ClassT.objid = UpdT.Objid';

									EXEC [sys].[sp_executesql] @Query;

									RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
							END;

	 
							  SELECT @ProcedureStep = 'Setup insert new objects Query';
							  SET @ProcedureStep = @ProcedureStep;
							  SET @LogTypeDetail = 'Status';
							  SET @LogStatusDetail = 'Completed';
							  SET @LogTextDetail = 'Completed Process';
							  SET @LogColumnName = '';
							  SET @LogColumnValue = '';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @TableName
                                                                     ,@Validation_ID = NULL
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;


							drop table #TemProp

							drop table #Columns 
END TRY
Begin CATCH
     IF @@TranCount <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;


	print 'testing'
    SET NOCOUNT ON;
	 UPDATE [dbo].[MFUpdateHistory]
    SET [UpdateStatus] = 'failed'
    WHERE [Id] = @Update_ID;

    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ProcedureStep]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[Update_ID]
       ,[ErrorLine]
    )
    VALUES
    (@TableName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE()
    ,ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

    IF @Debug > 0
    BEGIN
        SELECT ERROR_NUMBER()    AS [ErrorNumber]
              ,ERROR_MESSAGE()   AS [ErrorMessage]
              ,ERROR_PROCEDURE() AS [ErrorProcedure]
              ,@ProcedureStep    AS [ProcedureStep]
              ,ERROR_STATE()     AS [ErrorState]
              ,ERROR_SEVERITY()  AS [ErrorSeverity]
              ,ERROR_LINE()      AS [ErrorLine];
    END;

    SET NOCOUNT OFF;

    RETURN -1

END CATCH
End	






