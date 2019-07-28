/*
CHANGE HISTORY
--------------
2017-06-21	ArnieC		-	Add MessageForMFilesOUT as optional (default=null) to allow for usage in multi-line text property 
						-	Change @MessageOUT as optional (default = NULL)

2017-06-26	ArnieC		-	Remove @ClassTable, Class Table derived from ProcessBatch_ID
						-	Remove @RowCount, RowCount calculated from ProcessBatch_ID as part of 
						-	Add HTML Email Body Output 

2017-07-15 LerouxC		-	Allow for default message when no table is involved in the process (e.g metadata synchronisation)
2017-12-29 lC			-	Allow for message from processbatchdetail level
2018-5-20  lc				Modify result message for MFUserMessages
2018-11-15	lc				fix bug for MF message out
2018-11-18	lc				Fix count of records
2018-12-02	lc				Fix bug for returning more than one result in query
*/

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFResultMessageForUI]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFResultMessageForUI' -- nvarchar(100)
                                    ,@Object_Release = '4.2.7.46'            -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFResultMessageForUI' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFResultMessageForUI]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFResultMessageForUI]
(
    -- Add the parameters for the function here
    @Processbatch_ID INT
   ,@Detaillevel INT = 0
   ,@MessageOUT NVARCHAR(4000) = NULL OUTPUT
   ,@MessageForMFilesOUT NVARCHAR(4000) = NULL OUTPUT
   ,@GetEmailContent BIT = 0
   ,@EMailHTMLBodyOUT NVARCHAR(MAX) = NULL OUTPUT
   ,@RecordCount INT = 0 OUTPUT
   ,@UserID INT = NULL OUTPUT
   ,@ClassTableList NVARCHAR(100) = NULL OUTPUT
   ,@MessageTitle NVARCHAR(100) = NULL OUTPUT
   ,@Debug INT = 0
)
AS
/*******************************************************************************
  ** Desc:  Format Messages for output to Context Menu UI, Mulit-Line Text Property and/or HTML
  **		Message is based on MFProcessBatch if single class table and MFProcessBatchDetail if multiple class tables affected by ProcessBatch_ID
  **
  ** Parameters and acceptable values:
  **			@Processbatch_ID		  Required - Retrieve message content values from MFProcessBatch
  **			@MessageOUT:			  Optional - Return message formatted for display by Context Menu with non-asyncronous process (includes newline as \n)
  **			@MessageForMFilesOUT	  Optional - Return message formatted for use with multi-line text property or within e-mail content (includes newline CHAR(10))
  **			@GetEmailContent		  Optional - Set to 1 if intent is to use @EmailHTMLBodyOUT to construct the HTML Output for @Message
  **			@EMailHTMLBodyOUT		  Optional - If @GetEmailContent =1: Formats ProcessBatch.LogText as an HTML Message
  ******************************************************************************/
BEGIN
    -- Declare the return variable here
    DECLARE @Message      NVARCHAR(4000)
           ,@ErrorMessage NVARCHAR(4000)
           ,@SumDuration  DECIMAL(18, 4);

    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFResultMessageForUI';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';

    SELECT @SumDuration = SUM([mpbd].[DurationSeconds])
    FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
    WHERE [mpbd].[ProcessBatch_ID] = @Processbatch_ID;

    --   BEGIN

    -------------------------------------------------------------
    -- Default message
    -------------------------------------------------------------
    --SELECT @Message
    --    = CASE
    --          WHEN @Detaillevel = 0 THEN
    --(
    --    SELECT ISNULL([mpb].[ProcessType], '(process type unknown)') + ': '
    --           + ISNULL([mpb].[Status], '(status unknown)') + ' | ' + ISNULL([mpb].[LogText], '(null)') + ' | '
    --           + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
    --           + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)') + ' | '
    --           + 'Duration Seconds: ' + CONVERT(VARCHAR(25), @SumDuration)
    --    --+ CAST(RIGHT('0' + CAST(FLOOR((COALESCE([mpb].[DurationSeconds], 0) / 60) / 60) AS VARCHAR(8)), 2) + ':'
    --    --       + RIGHT('0' + CAST(FLOOR(COALESCE([mpb].[DurationSeconds], 0) / 60) AS VARCHAR(8)), 2) + ':' AS varchar(258))
    --    FROM [dbo].[MFProcessBatch] AS [mpb]
    --    WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID
    --)
    --          WHEN @Detaillevel = 1 THEN
    --(
    --    SELECT ISNULL([mpb].[ProcessType], '(process type unknown)') + ': '
    --           + ISNULL([mpbd].[Status], '(status unknown)') + ' | ' + ISNULL([mpbd].[LogText], '(null)') + ' | '
    --           + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
    --           + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)') + ' | '
    --           + 'Duration Seconds: ' + CONVERT(VARCHAR(25), [mpbd].[DurationSeconds]),
    --           --+ CAST(RIGHT('0' + CAST(FLOOR((COALESCE([mpbd].[DurationSeconds], 0) / 60) / 60) AS VARCHAR(8)), 2) + ':'
    --           --       + RIGHT('0' + CAST(FLOOR(COALESCE([mpbd].[DurationSeconds], 0) / 60) AS VARCHAR(8)), 2) + ':' AS varchar(258))
    --           [mpb].[ProcessType],
    --           [mpbd].*
    --    FROM [dbo].[MFProcessBatch] AS [mpb]
    --        INNER JOIN [dbo].[MFProcessBatchDetail] AS [mpbd]
    --            ON [mpbd].[ProcessBatch_ID] = [mpb].[ProcessBatch_ID]
    --    WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID
    --          AND [mpbd].[LogType] = 'Message'
    --          AND [mpbd].[MFTableName] <> 'MFUserMessages'
    --)
    --      END;

    -- END;
    DECLARE @ClassName NVARCHAR(100);
    DECLARE @ClassTable NVARCHAR(100);
    DECLARE @ClassTableCount INT = 1;
	DECLARE @ID INT;

    SET @ProcedureStep = 'Get class list';

    DECLARE @ClassTables AS TABLE
    (id int IDENTITY,
        [TableName] NVARCHAR(100)
    );

    INSERT @ClassTables
    ( 
        [TableName]
    )
    SELECT DISTINCT
           [MFTableName]
    FROM [dbo].[MFProcessBatchDetail]
    WHERE [ProcessBatch_ID] = @Processbatch_ID
          AND
          (
              [MFTableName] IS NOT NULL
              OR [MFTableName] NOT IN ( 'MFUserMessages', '' )
          );

    SET @ClassTableCount = @@RowCount;
    SET @DebugText = ' Count of class tables %i';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassTableCount);
    END;

    IF @ClassTableCount = 1
       AND @Detaillevel = 0
    BEGIN
        SET @ProcedureStep = 'Single class table';

        SELECT @ClassName  = [c].[Name]
              ,@ClassTable = [t].[TableName]
        FROM @ClassTables              AS [t]
            INNER JOIN [dbo].[MFClass] AS [c]
                ON [t].[TableName] = [c].[TableName];

        SELECT @Message
            = ISNULL([mpb].[ProcessType], '(process type unknown)') + ': ' + ISNULL([mpb].[Status], '(status unknown)')
              + ' | ' + 'Class Name: ' + ISNULL(@ClassName, '(null)') + ' | ' + ISNULL([mpb].[LogText], '(null)')
              + ' | ' + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
              + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)') + ' | '
              + 'Duration Seconds: ' + CONVERT(VARCHAR(25), [mpb].[DurationSeconds])
        --+ CAST(RIGHT('0' + CAST(FLOOR((COALESCE(@SumDuration, 0) / 60) / 60) AS VARCHAR(8)), 2)
        --       + ':'
        --       + RIGHT('0' + CAST(FLOOR(COALESCE([mpb].[DurationSeconds], 0) / 60) AS VARCHAR(8)), 2)
        --       + ':'
        --       + RIGHT('0' + CAST(FLOOR(COALESCE([mpb].[DurationSeconds], 0) % 60) AS VARCHAR(2)), 2) AS VARCHAR(10))
        FROM [dbo].[MFProcessBatch] AS [mpb]
        WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID;

        SET @DebugText = 'Message %s';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Message);
        END;
    END; --IF @ClassTableCount = 1

    IF @ClassTableCount <> 1
       AND @Detaillevel = 0
    BEGIN
        SET @ProcedureStep = 'Multiple Class tables';

		SET @DebugText = ' ClassTable count %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassTableCount);
        END;

        DECLARE @MessageByClassTable AS TABLE
        (
            [id] INT IDENTITY(1, 1) PRIMARY KEY
           ,[ProcessBatch_ID] INT
           ,[ClassTable] NVARCHAR(100)
           ,[LogText] NVARCHAR(4000)
           ,[LogStatus] NVARCHAR(50)
           ,[Duration] DECIMAL(18, 4)
           ,[RecCount] INT
        );

        SELECT @ID = MIN(ID)
        FROM @ClassTables;

        WHILE @ID IS NOT NULL
        BEGIN
            --IF @IncludeClassTableStats = 1
            --	BEGIN
            --		INSERT INTO @ClassStats
            --		EXEC [dbo].[spMFClassTableStats] @ClassTableName = @ClassTable
            --									   , @Debug = 0;

            --	END --	IF @IncludeClassTableStats = 1
         SELECT @ClassTable = TableName FROM @ClassTables AS [ct] WHERE id = @ID

		 SET @ProcedureStep = 'Compile message by ';

		SET @DebugText = ' ClassTable  %s';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassTable);
        END;

		    INSERT @MessageByClassTable
            (
                [ProcessBatch_ID]
               ,[ClassTable]
               ,[LogText]
               ,[LogStatus]
            --       ,[Duration]
            )
            SELECT [pbd].[ProcessBatch_ID]
                  ,[pbd].[MFTableName]
                  ,[pbd].[LogText]
                  ,[pbd].[Status]
            --      ,[pbd].[DurationSeconds]
            FROM [dbo].[MFProcessBatchDetail] AS [pbd]
            WHERE [pbd].[ProcessBatch_ID] = @Processbatch_ID
                  AND [pbd].[LogType] = 'Message'
                  AND [pbd].[MFTableName] = @ClassTable
                  AND @ClassTable NOT IN ( 'MFUserMessages', '' )
            ORDER BY [pbd].[MFTableName]
                    ,[pbd].[ProcessBatch_ID];

					 SET @ProcedureStep = 'Update Duration ';

		SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

            UPDATE @MessageByClassTable
            SET [Duration] =
                (
                    SELECT SUM([mpbd].[DurationSeconds])
                    FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
                    WHERE [mpbd].[ProcessBatch_ID] = @Processbatch_ID
                          AND [mpbd].[MFTableName] = @ClassTable
                )
            FROM @MessageByClassTable AS [mbct]
            WHERE [mbct].[ClassTable] = @ClassTable;

						 SET @ProcedureStep = 'Update Count ';

		SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

            UPDATE @MessageByClassTable
            SET [RecCount] =
                (
                    SELECT SUM(CAST([mpbd].[ColumnValue] AS INT))
                    FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
                    WHERE [mpbd].[MFTableName] = @ClassTable
                          AND [mpbd].[ColumnName] = 'NewOrUpdatedObjectDetails'
                          AND [mpbd].[ProcessBatch_ID] = @Processbatch_ID
                )
            FROM @MessageByClassTable AS [mbct]
            WHERE [mbct].[ClassTable] = @ClassTable;

            SELECT @ID = (SELECT MIN(ID)
            FROM @ClassTables
            WHERE ID > @ID);
        END; --WHILE @ClassTable IS NOT NULL

		if @debug > 0
		SELECT * FROM @MessageByClassTable AS [mbct]; 

SET @ProcedureStep = 'Format messages'
SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        DECLARE @DetailStatus   NVARCHAR(50)
               ,@DetailLogText  NVARCHAR(4000)
               ,@DetailDuration DECIMAL(18, 4);

        SELECT @Message
            = ISNULL([mpb].[ProcessType], '(process type unknown)') + ': ' + ISNULL([mpb].[Status], '(status unknown)')
              + ' | ' + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
              + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)')
        FROM [dbo].[MFProcessBatch] AS [mpb]
        WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID;

		
		IF @Debug > 0
		SELECT @Message AS MessageHeading;

        -- Build Extended Message to include class name
		SET @ID = Null
        SELECT @Id = MIN([id])
        FROM @MessageByClassTable;

        WHILE @Id IS NOT NULL
        BEGIN

            SELECT @ClassName = [c].[Name]
            FROM @MessageByClassTable      AS [t]
                INNER JOIN [dbo].[MFClass] AS [c]
                    ON [t].[ClassTable] = [c].[TableName]
            WHERE [t].[id] = @Id;

            SELECT @DetailStatus   = [LogStatus]
                  ,@DetailLogText  = [LogText]
                  ,@DetailDuration = [Duration]
                  ,@RecordCount    = [RecCount]
            FROM @MessageByClassTable
            WHERE [id] = @Id;

            SET @Message
                = @Message + ' |  | ' + 'Class Name: ' + ISNULL(@ClassName, '(null)') + ': '
                  + ISNULL(@DetailStatus, '(status unknown)') + ' | ' + ISNULL(@DetailLogText, '(null)') + ' | '
                  + 'Duration: ' + CONVERT(VARCHAR(25), @DetailDuration) + ' Count: '
                  + CAST(@RecordCount AS VARCHAR(10));

            --+ CAST(RIGHT('0' + CAST(FLOOR((COALESCE(@DetailDuration, 0) / 60) / 60) AS VARCHAR(8)), 2) + ':'
            --       + RIGHT('0' + CAST(FLOOR(COALESCE(@DetailDuration, 0) / 60) AS VARCHAR(8)), 2) + ':'
            --       + RIGHT('0' + CAST(FLOOR(COALESCE(@DetailDuration, 0) % 60) AS VARCHAR(2)), 2) AS VARCHAR(10));
            SELECT @Id = MIN([id])
            FROM @MessageByClassTable
            WHERE [id] > @Id
                  AND [ClassTable] NOT IN ( 'MFUserMessages', '' );
        END; --WHILE @Id IS NOT NULl

        SET @DebugText = 'Extended Message %s';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Message);
        END;
    END;

    --IF @ClassTableCount > 1
    SET @ProcedureStep = 'format message for message box';

    -- Return @MessageOUT
    SELECT @MessageOUT = REPLACE(@Message, ' | ', '\n');

    SET @DebugText = 'MessageOut %s';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @MessageOUT);
    END;

    SET @ProcedureStep = 'format message for M-files property';
    -- Return @MessageForMFilesOUT
    SET @MessageForMFilesOUT = REPLACE(@Message, ' | ', CHAR(10));
    SET @DebugText = 'MessageForMfilesOut %s';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @MessageForMFilesOUT);
    END;

    SET @ProcedureStep = 'Setup email';

    --Return HTML Email Body
    IF @GetEmailContent = 1
    BEGIN
        -- Construct and Return @MessageForHTMLOUT
        DECLARE @EMAIL_BODY NVARCHAR(MAX);

        SET @EMAIL_BODY = N'<html>';

        --Get CSS Style Sheet for Emails
        SELECT @EMAIL_BODY = @EMAIL_BODY + CAST([Value] AS VARCHAR(8000))
        FROM [dbo].[MFSettings]
        WHERE [source_key] = 'Email'
              AND [Name] = 'DefaultEMailCSS';

        DECLARE @MFVaultSetting_VaultName VARCHAR(100);

        SELECT @MFVaultSetting_VaultName = [VaultName]
        FROM [dbo].[MFVaultSettings];

        SET @EMAIL_BODY
            = @EMAIL_BODY + N'
			<body><div id="body_style" >' + '<table>' + '<th>' + 'M-Files Vault: ' + @MFVaultSetting_VaultName
              + '</th>' + '<tr><td>' + REPLACE(@Message, ' | ', '</td></tr><tr><td>') + '</td></tr>' + '</table>'
              + '</div></body></html>';
        SET @EMailHTMLBodyOUT = @EMAIL_BODY;
    END;

    SET @ProcedureStep = 'Set other output variables';

    SELECT @ClassTableList = COALESCE(@ClassTableList, '', ' ') + [mpbd].[TableName] + CHAR(10)
    FROM @ClassTables AS [mpbd]
    WHERE [mpbd].[TableName] NOT IN ( 'MFUserMessages', '' );

    SELECT @ClassTableList = SUBSTRING(@ClassTableList, 1, LEN(@ClassTableList) - 1);

    SELECT @RecordCount = SUM(CAST([mpbd].[ColumnValue] AS INT))
    FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
    WHERE [mpbd].[ProcessBatch_ID] = @Processbatch_ID
          AND [mpbd].[ColumnName] = 'NewOrUpdatedObjectDetails'
          AND [mpbd].[MFTableName] NOT IN ( 'MFUserMessages', '' );

    SELECT @MessageTitle = [mpb].[LogText] + ' ' + CAST([mpb].[CreatedOn] AS VARCHAR(25))
    FROM [dbo].[MFProcessBatch] AS [mpb]
    WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID;

    SELECT @UserID = [mua].[UserID]
    FROM [dbo].[MFUserAccount] AS [mua]
    WHERE [mua].[LoginName] =
    (
        SELECT [mvs].[Username] FROM [dbo].[MFVaultSettings] AS [mvs]
    );

    -- Return the result of the function
    RETURN 1;
END;
GO