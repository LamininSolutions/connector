
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFExportFiles]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFGetHistory',
    -- nvarchar(100)
    @Object_Release = '4.1.5.41',
    -- varchar(50)
    @UpdateFlag = 2;

--select STUFF(( SELECT ','
--  , CAST([ObjID] AS VARCHAR(10))
--FROM   MFOtherDocument
-- FOR
--XML PATH('')
-- ), 1, 1, '')
-- smallint
GO

/*
MODIFICATIONS
Add ability to show updates in MFUpdateHistory
Fix bug with lastmodifiedUTC date.
*/

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINES].[ROUTINE_NAME] = 'spMFGetHistory' --name of procedure
            AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
            AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo'
    )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';

        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


CREATE PROCEDURE [dbo].[spMFGetHistory]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [spMFGetHistory]
    (
        @MFTableName     NVARCHAR(128),
        @Process_id      INT           = 0,
        @ColumnNames     NVARCHAR(4000),
        --	@SearchString nvarchar(4000),
        @IsFullHistory   BIT,
        @NumberOFDays    INT           = -1,
        @StartDate       DATETIME      = '1901-01-10',
   --     @Update_ID       INT           = NULL OUTPUT,
        @ProcessBatch_id INT           = NULL OUTPUT,
        @Debug           INT           = 0
    )
AS
    BEGIN

        BEGIN TRY

            SET NOCOUNT ON;
            -----------------------------------------------------
            --DECLARE LOCAL VARIABLE
            ----------------------------------------------------

            DECLARE @VaultSettings NVARCHAR(4000);
            DECLARE @PropertyIDs NVARCHAR(4000);
            DECLARE @ObjIDs NVARCHAR(MAX);
            DECLARE @ObjectType INT;
            DECLARE @ProcedureName sysname = 'spMFGetHistory';
            DECLARE @ProcedureStep sysname = 'Start';
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

            ----------------------------------------------------------------------
            --GET Vault LOGIN CREDENTIALS
            ----------------------------------------------------------------------


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

            EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
                @ProcessType = @ProcessType,
                @LogType = @LogType,
                @LogText = @LogText,
                @LogStatus = @LogStatus,
                @debug = @Debug;


            SET @ProcedureStep = 'GET Vault LOGIN CREDENTIALS';

            IF @Debug = 1
                BEGIN
                    PRINT @ProcedureStep;
                END;

            SELECT
                @VaultSettings = [dbo].[FnMFVaultSettings]();

            IF @Debug = 1
                BEGIN
                    SELECT
                        @VaultSettings = [dbo].[FnMFVaultSettings]();
                END;


            ----------------------------------------------------------------------
            --GET PropertyIDS as comma separated string  
            ----------------------------------------------------------------------
            SET @ProcedureStep = 'Get PropertyIDS';
            SET @LogTypeDetail = 'Message'
            SET @LogStatusDetail = 'Started';
            SET @StartTime = GETUTCDATE();


			Create table #TempProperty
			(
			   ID int identity(1,1),
			   ColumnName nvarchar(200),
			   IsValidProperty bit
			)

			insert into #TempProperty(ColumnName) select [ListItem] FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',')
			DECLARE @Counter int, @MaxRowID int
			select @MaxRowID=max(ID) from #TempProperty
			set @Counter =1
			while @Counter<= @MaxRowID
			 Begin
			    
				Declare @PropertyName nvarchar(200)
				select @PropertyName=ColumnName from #TempProperty where ID=@Counter
				  if exists  (Select top 1 * from MFProperty with (nolock) where ColumnName=@PropertyName)
					  Begin
					     Update #TempProperty set IsValidProperty=1 where ID=@Counter
					  End
			      else
					  Begin
					    set @PropertyName=@PropertyName+'_ID'
						if exists (Select top 1 * from MFProperty with (nolock) where ColumnName=@PropertyName)
							 begin

							 
								  Update #TempProperty set IsValidProperty=1 , ColumnName=@PropertyName where ID=@Counter
							 End
						 else
							 begin
							       Declare @ErrorMsg nvarchar(1000)
								   select @ErrorMsg='Invalid columnName '+ @PropertyName+' provided'

								          RAISERROR (
											'Proc: %s Step: %s ErrorInfo %s '
											,16
											,1
											,'spmfGetHistory'
											,'Validating property column name'
											, @ErrorMsg
						                     );
							
							 end

					  End


				set @Counter=@Counter +1
			 End


			  set @ColumnNames=''
			  select @ColumnNames=COALESCE(@ColumnNames+',','') + ColumnName from #TempProperty
			

                SELECT
                @PropertyIDs = COALESCE(@PropertyIDs + ',', '') + CAST([MFID] AS VARCHAR(20))
            FROM
                [dbo].[MFProperty] with (nolock)
            WHERE
                [ColumnName] IN (
                                    SELECT
                                        [ListItem]
                                    FROM
                                        [dbo].[fnMFParseDelimitedString](@ColumnNames, ',')
                                );

			SELECT @rowcount = COUNT(*)
                                    FROM
                                        [dbo].[fnMFParseDelimitedString](@ColumnNames, ',')

			SET @LogTextDetail = 'Columns: ' + @ColumnNames;
            SET @LogColumnName = 'Count of columns';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));


            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            ----------------------------------------------------------------------
            --GET ObjectType of Table
            ----------------------------------------------------------------------


            SET @ProcedureStep = 'GET ObjectType of class table ' + @MFTableName;

            SELECT
                @ObjectType = [OT].[MFID]
            FROM
                [MFClass]          AS [CLS]
                INNER JOIN
                    [MFObjectType] AS [OT]
                        ON [CLS].[MFObjectType_ID] = [OT].[ID]
            WHERE
                [CLS].[TableName] = @MFTableName;

            IF @Debug = 1
                BEGIN
                    SELECT
                        @ObjectType AS [ObjectType];
                END;
            ---------------------------------------------------------------------
            --GET Comma separated ObjIDS for Getting the History        
            ----------------------------------------------------------------------

            SET @ProcedureStep = 'ObjIDS for History ';
            IF @Debug = 1
                BEGIN
                    PRINT @ProcedureStep;
                END;

            SET @StartTime = GETUTCDATE();

            DECLARE
                @VQuery NVARCHAR(4000),
                @Filter NVARCHAR(4000);

            SET @Filter = 'where  Process_ID=' + CONVERT(VARCHAR(10), @Process_id);

            CREATE TABLE [#TempObjIDs] ([ObjIDS] NVARCHAR(MAX));

            SET @VQuery
                = 'insert into #TempObjIDs(ObjIDS)  select STUFF(( SELECT '',''
											  , CAST([ObjID] AS VARCHAR(10))
										 FROM  ' + @MFTableName + '
										  ' + @Filter
                  + '
									   FOR
										 XML PATH('''')
									   ), 1, 1, '''') ';

            EXEC (@VQuery);

            SELECT
                @ObjIDs = [ObjIDS]
            FROM
                [#TempObjIDs];

			Select @rowcount = COUNT(*) FROM [#TempObjIDs] AS [toid]
			
            SET @LogTypeDetail = 'Message';
            SET @LogStatusDetail = 'Completed';
            SET @LogTextDetail
                = 'ObjIDS for History'
            SET @LogColumnName = 'Objids count';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));
            
            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            IF @Debug = 1
                BEGIN
                    SELECT
                        @ObjIDs AS [ObjIDS];
                END;

            ---------------------------------------------------------------------
            --Calling spMFGetHistoryInternal  procedure to objects history
            ----------------------------------------------------------------------
            DECLARE @Result NVARCHAR(MAX);
            DECLARE @Idoc INT;

            --select @VaultSettings as 'VaultSettings'
            --select @ObjectType as 'ObjectType'
            --select @ObjIDs as 'ObjIDs'
            --select @PropertyIDs as 'PropertyIDs'

            SET @ProcedureStep = 'Calling spMFGetHistoryInternal';

			DECLARE @Criteria VARCHAR(258)
			SET @Criteria = CASE 
			WHEN @IsFullHistory = 1 THEN 'Full History ' 
			WHEN @IsFullHistory = 0 AND @NumberOFDays > 0 THEN 'For Number of days: ' + CAST(@NumberOFDays as varchar(5)) + ''
			when @IsFullHistory = 0 AND @NumberOFDays < 0 AND @StartDate <> '1901-01-10' 
			THEN 'From date: ' + CAST((Convert(DATE,@StartDate)) AS VARCHAR(25))  + ''
			ELSE 'No Criteria' 
			END

			DECLARE @Params NVARCHAR(MAX)
			SET @VQuery = N'SELECT @rowcount = COUNT(*) FROM ' + @MFTableName + ' where process_ID = ' +CAST(@process_ID AS VARCHAR(5)) + ''
			SET @Params = N'@RowCount int output'
			EXEC sp_executeSQL @VQuery, @Params, @RowCount = @Rowcount output

            SET @LogTypeDetail = 'Message';
            SET @LogStatusDetail = 'Completed';
            SET @LogTextDetail = 'Criteria:  '+ @Criteria    ;
            SET @LogColumnName = 'Object Count';
            SET @LogColumnValue = CAST(@Rowcount AS VARCHAR(5));
            SET @StartTime = GETUTCDATE();

            /*
select @VaultSettings as 'VaultSettings'
select @ObjectType as 'ObjectType'
select @ObjIDs as 'ObjIDs'
Select @PropertyIDs as 'PropertyIDs'
--select @SearchString as 'SearchString'
select @IsFullHistory as 'IsFullHistory'
select @NumberOFDays as 'NumberOFDays'
select @StartDate as 'StartDate'
*/

  
	 UPDATE [dbo].[MFUpdateHistory]
            SET [MFUpdateHistory].[ObjectDetails] = @ObjIDs
               ,[MFUpdateHistory].[ObjectVerDetails] =@PropertyIDs

            WHERE [MFUpdateHistory].[Id] = @Update_ID;
  
            DECLARE @SearchString NVARCHAR(4000) = NULL; -- note that ability to use a search criteria is not yet active.

			-----------------------------------------------------------------
	         -- Checking module access for CLR procdure  spMFGetHistoryInternal
           ------------------------------------------------------------------
              EXEC [dbo].[spMFCheckLicenseStatus] 
			    'spMFGetHistoryInternal'
				,@ProcedureName
				,@ProcedureStep

            EXEC [spMFGetHistoryInternal]
                @VaultSettings,
                @ObjectType,
                @ObjIDs,
                @PropertyIDs,
                @SearchString,
                @IsFullHistory,
                @NumberOFDays,
                @StartDate,
                @Result OUT;


            IF @Debug = 1
                BEGIN
                    SELECT
                        CAST(@Result AS XML) AS [HistoryXML];
                END;

				 IF ( @Update_ID > 0 )
                              UPDATE    [dbo].[MFUpdateHistory]
                              SET       [MFUpdateHistory].[NewOrUpdatedObjectVer] = @Result
                              WHERE     [MFUpdateHistory].[Id] = @Update_ID;


            EXEC [sp_xml_preparedocument]
                @Idoc OUTPUT,
                @Result;

				EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            ----------------------------------------------------------------------------------
            --Creating temp table #Temp_ObjectHistory for storing object history xml records
            --------------------------------------------------------------------------------
            SET @ProcedureStep = 'Creating temp table #Temp_ObjectHistory';

            CREATE TABLE [#Temp_ObjectHistory]
                (
                    [RowNr]               INT IDENTITY,
                    [ObjectType_ID]       INT,
                    [Class_ID]            INT,
                    [ObjID]               INT,
                    [MFVersion]           INT,
                    [LastModifiedUTC]     nVARCHAR(30),
                    [MFLastModifiedBy_ID] INT,
                    [Property_ID]         INT,
                    [Property_Value]      NVARCHAR(300),
                    [CreatedOn]           DATETIME
                );

            INSERT INTO [#Temp_ObjectHistory]
                (
                    [ObjectType_ID],
                    [Class_ID],
                    [ObjID],
                    [MFVersion],
                    [LastModifiedUTC],
                    [MFLastModifiedBy_ID],
                    [Property_ID],
                    [Property_Value],
                    [CreatedOn]
                )
                        SELECT
                            [ObjectType],
                            [ClassID],
                            [ObjID],
                            [Version],
                            [LastModifiedUTC],
                            [LastModifiedBy_ID],
                            [Property_ID],
                            [Property_Value],
                            GETDATE()
                        FROM
                            OPENXML(@Idoc, '/form/Object/Property', 1)
                                WITH
                                    (
                                        [ObjectType] INT '../@ObjectType',
                                        [ClassID] INT '../@ClassID',
                                        [ObjID] INT '../@ObjID',
                                        [Version] INT '../@Version',
                               --         [LastModifiedUTC] NVARCHAR(30) '../@LastModifiedUTC',
							     [LastModifiedUTC] NVARCHAR(30) '../@CheckInTimeStamp',
                                        [LastModifiedBy_ID] INT '../@LastModifiedBy_ID',
                                        [Property_ID] INT '@Property_ID',
                                        [Property_Value] NVARCHAR(300) '@Property_Value'
                                    );

            ----------------------------------------------------------------------------------
            --Merge/Inserting records into the MFObjectChangeHistory from Temp_ObjectHistory
            --------------------------------------------------------------------------------

            SET @ProcedureStep = 'Update MFObjectChangeHistory';
			DECLARE @BeforeCount int
			SELECT @BeforeCount = COUNT(*) FROM  MFObjectChangeHistory

            MERGE INTO [dbo].[MFObjectChangeHistory] AS [t]
            USING
                (
                    SELECT
                        *
                    FROM
                        [#Temp_ObjectHistory] AS [toh]
                ) AS [s]
            ON [t].[ObjectType_ID] = [s].[ObjectType_ID]
               AND [t].[Class_ID] = [s].[Class_ID]
               AND [t].[ObjID] = [s].[ObjID]
               AND [t].[MFVersion] = [s].[MFVersion]
               AND [t].[Property_ID] = [s].[Property_ID]
            WHEN NOT MATCHED BY TARGET
                THEN INSERT
                         (
                             [ObjectType_ID],
                             [Class_ID],
                             [ObjID],
                             [MFVersion],
                             [LastModifiedUTC],
                             [MFLastModifiedBy_ID],
                             [Property_ID],
                             [Property_Value],
                             [CreatedOn]
                         )
                     VALUES
                         (
                             [s].[ObjectType_ID],
                             [s].[Class_ID],
                             [s].[ObjID],
                             [s].[MFVersion],
                             --CASE
                             --    WHEN [s].[LastModifiedUTC] = '1/1/1601 12:00:00 AM'
                             --        THEN NULL
                             --    ELSE
                             --        CAST([s].[LastModifiedUTC] AS DATETIME2)
                             --END, 
							 CAST([s].[LastModifiedUTC] AS DATETIME),                          
                             [s].[MFLastModifiedBy_ID],
                             [s].[Property_ID],
                             [s].[Property_Value],
                             [s].[CreatedOn]
                         );

            -------------------------------------------------------------
            -- Delete duplicate change records
            -------------------------------------------------------------
            DELETE
            [MFObjectChangeHistory]
            WHERE
                [ID] IN (
                            SELECT
                                [toh].[ID]
                            FROM [#Temp_ObjectHistory] AS [toh2]
							INNER JOIN 
                                [dbo].[MFObjectChangeHistory]     AS [toh]
								  ON [toh].[ObjID] = toh2.[ObjID]
                                           AND [toh].[Class_ID] = toh2.[Class_ID]
                                           AND [toh].[Property_ID] = toh2.[Property_ID]
										   AND toh.[MFVersion] = toh2.[MFVersion]
                                INNER JOIN
                                    [dbo].[MFObjectChangeHistory] AS [moch]
                                        ON [toh].[ObjID] = [moch].[ObjID]
                                           AND [toh].[Class_ID] = [moch].[Class_ID]
                                           AND [toh].[Property_ID] = [moch].[Property_ID]
                                           AND [toh].[Property_Value] = [moch].[Property_Value]
                            WHERE
                                [toh].[MFVersion] = [moch].[MFVersion] + 1
                       );
		
		SET @Rowcount = (SELECT COUNT(*) FROM [dbo].[MFObjectChangeHistory] AS [moch]) - @BeforeCount
            -------------------------------------------------------------
            -- Reset process_ID
            -------------------------------------------------------------
            SET @VQuery = N'
					UPDATE ' + @MFTableName + '
					SET Process_ID = 0 WHERE process_ID = ' + CAST(@Process_id AS VARCHAR(5)) + '';
            EXEC (@VQuery);

            --truncate table MFObjectChangeHistory
            DROP TABLE [#Temp_ObjectHistory];
            DROP TABLE [#TempObjIDs];

			SET @ProcessType = @ProcedureName;
            SET @LogText = @ProcedureName + ' Ended ';
            SET @LogStatus = 'Completed';
            SET @StartTime = GETUTCDATE();

            EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_id,
                @ProcessType = @ProcessType,
                @LogType = @LogType,
                @LogText = @LogText,
                @LogStatus = @LogStatus,
                @debug = @Debug;

            SET @LogTypeDetail = 'Message';
            SET @LogTextDetail = 'History inserted in MFObjectChangeHistory';
            SET @LogStatusDetail = 'Completed';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = 'New History';
            SET @LogColumnValue = CAST(@Rowcount AS VARCHAR(5));

            EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;


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
