
alter PROCEDURE [spMFExportFiles]
(
    @TableName NVARCHAR(128),
    @RootFolder NVARCHAR(128) = 'C:\',
    @PathProperty_L1 NVARCHAR(128) = 'Class',
    @PathProperty_L2 NVARCHAR(128) = NULL,
    @PathProperty_L3 NVARCHAR(128) = NULL,
    @IncludeDocID BIT = 1,
    @Process_id INT = 1,
    @Debug INT = 0
)
AS
BEGIN
    BEGIN TRY

	SET NOCOUNT ON
    
        -----------------------------------------------------
        --DECLARE LOCAL VARIABLE
        ----------------------------------------------------

        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @ClassID INT;
        DECLARE @ObjType INT;
        DECLARE @FilePath NVARCHAR(1000);
        DECLARE @FileExport NVARCHAR(MAX);
        DECLARE @ClassName NVARCHAR(128);
        DECLARE @OjectTypeName NVARCHAR(128);
        DECLARE @ID INT;
        DECLARE @ObjID INT;
        DECLARE @MFVersion INT;
        DECLARE @SingleFile BIT;
        DECLARE @Name_Or_Tile NVARCHAR(250);
        DECLARE @IncludeDocIDTemp BIT;
        DECLARE @MFClassFilePath NVARCHAR(200);
        DECLARE @ProcedureName sysname = 'spMFExportFiles';
        DECLARE @ProcedureStep sysname = 'Start';
		DECLARE @PathProperty_ColValL1 NVARCHAR(128) = NULL
        DECLARE @PathProperty_ColValL2 NVARCHAR(128) = NULL
        DECLARE @PathProperty_ColValL3 NVARCHAR(128) = NULL


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
        DECLARE @ProcessType NVARCHAR(50);
        DECLARE @LogType AS NVARCHAR(50) = 'Status';
        DECLARE @LogText AS NVARCHAR(4000) = '';
        DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
        DECLARE @Status AS NVARCHAR(128) = NULL;
        DECLARE @Validation_ID INT = NULL;
        DECLARE @StartTime AS DATETIME;
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;

        DECLARE @error AS INT = 0;
        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT;
        DECLARE @RC INT;
        DECLARE @ProcessBatch_ID INT = NULL;
        DECLARE @Update_ID INT;
		DECLARE @IsIncludePropertyPath bit=0
		Declare @IsValidProperty_L1 bit
		Declare @IsValidProperty_L2 bit
		Declare @IsValidPrperty_L3 bit

        ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
        ----------------------------------------------------------------------


        SET @ProcessType = @ProcedureName;
        SET @LogType = 'Status';
        SET @LogText = @ProcedureStep + ' | ';
        SET @LogStatus = 'Initiate';


        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                      @ProcessType = @ProcessType,
                                                      @LogType = @LogType,
                                                      @LogText = @LogText,
                                                      @LogStatus = @LogStatus,
                                                      @debug = @Debug;



        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        SET @ProcedureStep = 'Getting ClassID, ObjectID, ClassName and ObjectName by @TableName';

        IF @Debug = 1
        BEGIN
            PRINT 'Getting ClassID, ObjectID, ClassName and ObjectName by @TableName';
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @ClassID = ISNULL([CL].[MFID], 0),
               @ObjType = [OT].[MFID],
               @ClassName = [CL].[Name],
               @OjectTypeName = [OT].[Name],
               @MFClassFilePath = ISNULL([CL].[FilePath], '')
        FROM [MFClass] AS [CL]
            INNER JOIN [MFObjectType] AS [OT]
                ON [CL].[MFObjectType_ID] = [OT].[ID]
                   AND [CL].[TableName] = @TableName;

        IF @ClassID != 0
        BEGIN

            IF @Debug = 1
            BEGIN
                SELECT @ClassID AS [ClassID],
                       @ClassName AS [ClassName],
                       @ObjType AS [ObjectTypeID],
                       @OjectTypeName AS [ObjectName];
            END;

            SET @ProcedureStep = 'Calculating File download path';

            IF @Debug = 1
            BEGIN

                RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
            END;



            ------------------------------------------------------------------------------------------------
            --Creating File path
            -------------------------------------------------------------------------------------------------
				--        IF @PathProperty_L1 IS NULL
				--           OR @PathProperty_L1 = ''
				--           OR @PathProperty_L1 = 'Class'
				--        BEGIN
				--            SET @PathProperty_L1 = @ClassName;
             
				--        END;

							--IF @debug = 1
						 --  SELECT @PathProperty_L1 AS [PathProperty_L1];

				--        IF @PathProperty_L2 IS NULL
				--           OR @PathProperty_L2 = ''
				--        BEGIN
				--            SET @PathProperty_L2 = @OjectTypeName;
                
				--        END;

			

				--        IF @PathProperty_L3 IS NULL
				--           OR @PathProperty_L3 = ''
				--        BEGIN
				--            SET @PathProperty_L3 = CONVERT(VARCHAR(10), GETDATE(), 105);
           
				--        END;


			--if @PathProperty_L3 Is not Null
			--IF  EXISTS
   --         (
   --             SELECT [COLUMN_NAME]
   --             FROM [INFORMATION_SCHEMA].[COLUMNS]
   --             WHERE [TABLE_NAME] = @TableName
   --                   AND [COLUMN_NAME] = @PathProperty_L3
   --         )
			--begin
			    
			--	 if @PathProperty_L2 is not null
			--	  begin

				      
			--		   		IF  EXISTS
			--				(
			--					SELECT [COLUMN_NAME]
			--					FROM [INFORMATION_SCHEMA].[COLUMNS]
			--					WHERE [TABLE_NAME] = @TableName
			--						  AND [COLUMN_NAME] = @PathProperty_L2
			--				)
			--			Begin

						     
			--				 if @PathProperty_L1 is not Null
			--				   Begin

			--				      		IF  EXISTS
			--									(
			--										SELECT [COLUMN_NAME]
			--										FROM [INFORMATION_SCHEMA].[COLUMNS]
			--										WHERE [TABLE_NAME] = @TableName
			--											  AND [COLUMN_NAME] = @PathProperty_L2
			--									)
			--								Begin

			--											Set @IsIncludePropertyPath=1
			--								End

			--				   End

			--			End
				     
			--	  End
			--End


			if @PathProperty_L1 Is not Null
			begin
			IF  EXISTS
            (
                SELECT [COLUMN_NAME]
                FROM [INFORMATION_SCHEMA].[COLUMNS]
                WHERE [TABLE_NAME] = @TableName
                      AND [COLUMN_NAME] = @PathProperty_L1
            )
				begin
				     set @IsValidProperty_L1=1
				end
			end


			if @PathProperty_L2 Is not Null
			begin
			IF  EXISTS
            (
                SELECT [COLUMN_NAME]
                FROM [INFORMATION_SCHEMA].[COLUMNS]
                WHERE [TABLE_NAME] = @TableName
                      AND [COLUMN_NAME] = @PathProperty_L2
            )
				begin
				     set @IsValidProperty_L2=1
				end
			end


			if @PathProperty_L3 Is not Null
			begin
			IF  EXISTS
            (
                SELECT [COLUMN_NAME]
            FROM [INFORMATION_SCHEMA].[COLUMNS]
                WHERE [TABLE_NAME] = @TableName
                      AND [COLUMN_NAME] = @PathProperty_L3
            )
				begin
				     set @IsValidPrperty_L3=1
				end
			end






			if @IsValidProperty_L1=1 or  @IsValidProperty_L2=1 or @IsValidPrperty_L3=1 
             begin
			    set @IsIncludePropertyPath=1
			  end


			IF @debug = 1
			     SELECT @PathProperty_L3 AS [PathProperty_L3];

            IF @MFClassFilePath != ''
               OR @MFClassFilePath IS NOT NULL
            BEGIN

     --           PRINT 'I am here';
                SET @FilePath = @RootFolder + @MFClassFilePath + '\';
            END;
			select @FilePath

            --SET @FilePath = @FilePath + @PathProperty_L1 + '\' + @PathProperty_L2 + '\' + @PathProperty_L3 + '\';


            SELECT @ProcedureStep = 'Fetching records from ' + @TableName + ' to download document.';


            IF NOT EXISTS
            (
                SELECT [COLUMN_NAME]
                FROM [INFORMATION_SCHEMA].[COLUMNS]
                WHERE [TABLE_NAME] = @TableName
                      AND [COLUMN_NAME] = 'FileCount'
            )
            BEGIN
                EXEC ('alter table ' + @TableName + ' add FileCount int CONSTRAINT DK_FileCount_' + @TableName + ' DEFAULT 0 WITH VALUES');
            END;


            IF @Debug = 1
            BEGIN
                SELECT @FilePath AS FileDownloadPath;
            --    PRINT 'Fetching records from ' + @TableName + ' to download document.';
                RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

            END;
            -----------------------------------------------------------------------------
            --Creating the cursor and cursor query.
            -----------------------------------------------------------------------------


            DECLARE @GetDetailsCursor AS CURSOR;
            DECLARE @CursorQuery NVARCHAR(200),
					@process_ID_text VARCHAR(5),
                    @vsql AS NVARCHAR(MAX),
                    @vquery AS NVARCHAR(MAX);

			SET @process_id_text = CAST(@process_id AS varchar(5))

            
			if @IsIncludePropertyPath =1 
			 
			 begin
			     --SET @vquery= 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0) as Single_File,isnull(Name_Or_Title,'''') as Name_Or_Title, 
				    --          isnull('+ @PathProperty_L1+ ', '''') as PathProperty_L1, isnull('+@PathProperty_L2+','''') as PathProperty_L2, isnull('+@PathProperty_L3 +','''') as PathProperty_L3 from [' + @TableName
        --          + '] WHERE Process_ID = '+ @Process_id_text +'    AND Deleted = 0';


				     SET @vquery= 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0) as Single_File,isnull(Name_Or_Title,'''') as Name_Or_Title'
					 
				
				          if @IsValidProperty_L1=1
						   begin
						     set @vquery= @vquery+  ', isnull('+ @PathProperty_L1+ ', '''') as PathProperty_L1'
						   end
						   else
						     begin
							    set @vquery= @vquery+  ', '''' as PathProperty_L1'
							 End

						   if @IsValidProperty_L2=1
						   begin
						     set @vquery= @vquery+  ', isnull('+ @PathProperty_L2 + ', '''') as PathProperty_L2'
						   end
						   else
						     begin
							    set @vquery= @vquery+  ', '''' as PathProperty_L2'
							 End


						   if @IsValidPrperty_L3=1
						   begin
						     set @vquery= @vquery+  ', isnull('+ @PathProperty_L3+ ', '''') as PathProperty_L3'
						   end
						   else
						     begin
							    set @vquery= @vquery+  ', '''' as PathProperty_L3'
							 End

				           set @vquery= @vquery+ ' from [' + @TableName+ '] WHERE Process_ID = '+ @Process_id_text +'    AND Deleted = 0'

				  print @vquery
			 End
		  else

		   Begin

		   print 'test'
		      SET @vquery          
                = 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0) as Single_File,isnull(Name_Or_Title,'''') as Name_Or_Title,'''' as PathProperty_L1, '''' as  PathProperty_L2, '''' as PathProperty_L3  from [' + @TableName
                  + '] WHERE Process_ID = '+ @Process_id_text +'    AND Deleted = 0';
				   print @vquery
		   End
			  
			--SET @vquery
   --             = 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0),isnull(Name_Or_Title,'''') from [' + @TableName
   --               + '] WHERE Process_ID = '+ @Process_id_text +'    AND Deleted = 0';


            SET @vsql = 'SET @cursor = cursor forward_only static FOR ' + @vquery + ' OPEN @cursor;';
    
                 print @vsql

		    EXEC [sys].[sp_executesql] @vsql,
                                       N'@cursor cursor output',
                                       @GetDetailsCursor OUTPUT;

            FETCH NEXT FROM @GetDetailsCursor
            INTO @ID,
                 @ObjID,
                 @MFVersion,
                 @SingleFile,
                 @Name_Or_Tile,
				 @PathProperty_ColValL1,
				 @PathProperty_ColValL2,
				 @PathProperty_ColValL3;

            WHILE (@@FETCH_STATUS = 0)
            BEGIN

			
                SELECT @ProcedureStep = 'Started downloadig Files for  objectID: ' + CAST(@ObjID AS VARCHAR(10));
                IF @Debug = 1
                BEGIN
                    PRINT 'Started downloadig Files for  objectID=' + CAST(@ObjID AS VARCHAR(10));
                    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                DECLARE @TempFilePath NVARCHAR(MAX);
				SET @TempFilePath = @FilePath;

				if @IsIncludePropertyPath =1 
				begin
					--SET @TempFilePath = @TempFilePath+@PathProperty_ColValL1+'\'+@PathProperty_ColValL2+'\'+@PathProperty_ColValL3+'\';

					if @PathProperty_ColValL1 is not null or @PathProperty_ColValL1 !=''
					 SET @TempFilePath = @TempFilePath+cast(@PathProperty_ColValL1 as nvarchar(200))+'\'

					 if @PathProperty_ColValL2 is not null or @PathProperty_ColValL2 !=''
					 SET @TempFilePath = @TempFilePath+cast(@PathProperty_ColValL2 as nvarchar(200))+'\'

					 if @PathProperty_ColValL3 is not null or @PathProperty_ColValL3 !=''
					 SET @TempFilePath = @TempFilePath+cast(@PathProperty_ColValL3 as nvarchar(200))+'\'

				End
				print 'testing1'

                IF @SingleFile = 0
                BEGIN
                    IF @IncludeDocID = 1
                    BEGIN
                        SELECT @TempFilePath
                            = @TempFilePath + '\' + REPLACE(REPLACE(@Name_Or_Tile, ':', '{3}'), '/', '{2}') + ' (ID '
                              + CAST(@ObjID AS VARCHAR(10)) + ')\';
                        SET @IncludeDocIDTemp = 0;
                    END;
                    ELSE
                    BEGIN
                        SELECT @TempFilePath
                            = @TempFilePath + '\' + REPLACE(REPLACE(@Name_Or_Tile, ':', '{3}'), '/', '{2}') + '\';
                        SET @IncludeDocIDTemp = 0;
                    END;

                print 'testing2'
				    IF @Debug = 1
                    BEGIN
                        SET @ProcedureStep = 'Calculate multi-file document path';
                        PRINT 'MultiFile document';
                        PRINT @TempFilePath;
                        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
                        SELECT @TempFilePath AS [MultiFileDownloadPath];
                    END;
                END;
                ELSE
                BEGIN
                    SET @IncludeDocIDTemp = @IncludeDocID;
                END;
				print @TempFilePath
				print 'testing3'
                -------------------------------------------------------------------
                --- Calling  the CLR StoredProcedure to Download file for @ObJID
                -------------------------------------------------------------------
				select @VaultSettings
				select @ClassID
				select @ObjID
				select @MFVersion
				select @TempFilePath
				select @IncludeDocIDTemp
			

			  Select @VaultSettings as VaulSettings
			  select @ClassID as ClassID
			  select @ObjID as ObjID
			  Select @ObjType as ObjType
			  select @MFVersion as MFVersion
			  select @TempFilePath as TempFilePath
			  select @IncludeDocIDTemp as IncludeDocIDTemp

                EXEC [spMFGetFilesInternal] @VaultSettings,
                                            @ClassID,
                                            @ObjID,
                                            @ObjType,
                                            @MFVersion,
                                            @TempFilePath,
                                            @IncludeDocIDTemp,
                                            @FileExport OUT;



											select  @FileExport
												print 'testing4'

                IF @Debug = 1
                BEGIN
                    PRINT @TempFilePath;
                    PRINT 'Reseting the Process_ID column';
                END;

                DECLARE @XmlOut XML;
                SET @XmlOut = @FileExport;

                EXEC ('Update ' + @TableName + ' set Process_ID=0 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');

                CREATE TABLE [#temp]
                (
                    [FileName] NVARCHAR(400),
                    [ClassID] INT,
                    [ObjID] INT,
                    [ObjType] INT,
                    [Version] INT,
                    [FileCheckSum] NVARCHAR(1000),
                    [FileCount] INT
                );
                INSERT INTO [#temp]
                (
                    [FileName],
                    [ClassID],
                    [ObjID],
                    [ObjType],
                    [Version],
                    [FileCheckSum],
                    [FileCount]
                )
                SELECT [t].[c].[value]('(@FileName)[1]', 'NVARCHAR(400)') AS [FileName],
                       [t].[c].[value]('(@ClassID)[1]', 'INT') AS [ClassID],
                       [t].[c].[value]('(@ObjID)[1]', 'INT') AS [ObjID],
                       [t].[c].[value]('(@ObjType)[1]', 'INT') AS [ObjType],
                       [t].[c].[value]('(@Version)[1]', 'INT') AS [Version],
                       [t].[c].[value]('(@FileCheckSum)[1]', 'nvarchar(1000)') AS [FileCheckSum],
                       [t].[c].[value]('(@FileCount)[1]', 'INT') AS [FileCount]
                FROM @XmlOut.[nodes]('/Files/FileItem') AS [t]([c]);

				select * from #temp

                EXEC ('Update  MFT  set MFT.FileCount= t.FileCount
									From ' + @TableName + ' MFT inner join #temp t
									on MFT.ObjID=t.ObjID 
									where MFT.ObjID=cast(' + @ObjID + 'as varchar(10))');

                DROP TABLE [#temp];

                FETCH NEXT FROM @GetDetailsCursor
                INTO @ID,
                     @ObjID,
                     @MFVersion,
                     @SingleFile,
                     @Name_Or_Tile,
					 @PathProperty_ColValL1,
				     @PathProperty_ColValL2,
				     @PathProperty_ColValL3;
            END;

            CLOSE @GetDetailsCursor;
            DEALLOCATE @GetDetailsCursor;



            SET @StartTime = GETUTCDATE();

            SET @LogTypeDetail = 'Download files';
            SET @LogTextDetail = @ProcedureName;
            SET @LogStatusDetail = 'Completed';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = '';
            SET @LogColumnValue = '';

            EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
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

        END;
        ELSE
        BEGIN
            PRINT 'Please check the ClassName';
        END;
    END TRY
    BEGIN CATCH

        EXEC ('Update ' + @TableName + ' set Process_ID=3 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');

        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ProcedureStep],
            [ErrorState],
            [ErrorSeverity],
            [Update_ID],
            [ErrorLine]
        )
        VALUES
        ('spMFUpdateTable',
         ERROR_NUMBER(),
         ERROR_MESSAGE(),
         ERROR_PROCEDURE(),
         'Test',
         ERROR_STATE(),
         ERROR_SEVERITY(),
         @Update_ID,
         ERROR_LINE()
        );

        SET NOCOUNT OFF;
    END CATCH;
END;

