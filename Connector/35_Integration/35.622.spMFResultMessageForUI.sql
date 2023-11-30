PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFResultMessageForUI]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFResultMessageForUI' -- nvarchar(100)
                                    ,@Object_Release = '4.10.30.74'            -- varchar(50)
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
/*rST**************************************************************************

======================
spMFResultMessageForUI
======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Processbatch\_ID int
    The process batch ID to base the message on
  @Detaillevel int
    - Default 0
    - the default will include only MFProcessBatch columns
    - set to 1 will include MFProcessBatchDetail columns
  @MessageOUT nvarchar(4000) (output)
    - Formatted with /n as new line token
  @MessageForMFilesOUT nvarchar(4000) (output)
    - Formatted with CHAR(10) as new line character
  @GetEmailContent bit (optional)
    - Default = 0
    - 1 = format EMailHTMLBodyOUT as HTML message 
  @EMailHTMLBodyOUT nvarchar(max) (output)
    - Formatted as HTML table using the stylesheet as defined by DefaultEMailCSS in MFSettings.
  @RecordCount int (output)
    fixme description
  @UserID int (output)
    fixme description
  @ClassTableList nvarchar(100) (output)
    fixme description
  @MessageTitle nvarchar(100) (output)
    fixme description
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Format process messages based on logging in MFProcessBatch and MFProcessBatch_Detail for output in different formats for use as a return message in the Context Menu UI, as a Multi-Line Text output or HTML format for inclusion in emails.

Additional Info
===============

The content of the output is defined by:
  - the ProcessBatch ID
  - if Detail level is set to 1 then the ProcessBatchDetail will be included

The procedure will format the output in three different formats:
  - Multiline text
  - for display in M-Files
  - in HTML format
  - if GetEmailContent is set to 0 (default) then HTML formatting will be ignored


When a single class table is part of a ProcessBatch_ID the message will be based on MFProcessBatch.LogText and Duration.

When multiple class tables are part of a ProcessBatch_ID the message will look at MFProcessBatch_Detail where LogType='Message' to compile a stacked message based on the LogText detail and the detail duration.

Regardless of what you include in the LogText the resulting message will always include the following elements:

.. code:: text

    [ProcessType]: [Status]
    Class Name: [Class Name]
    [LogText] -- with new lines based on ' | ' token in text
    Process Batch#: [ProcessBatch_ID]
    Started On: [CreatedOn]
    Duration: [DurationSeconds] --formatted as 00:00:00

The HTML Message is formatted as a table including a header row with the elements above formatted in HTML

Add ' | ' (includes spaces both sides of pipe (I) sign) to indicate a new-line token in the message

Add ' | | ' in LogText to indicate two new lines, creating a spacer line in the resulting message

Example: #Records: 2 | #Updated: 1 | #Added: 1

Use with spMFLogProcessSummaryForClassTable to generate LogText based on various counts in the process.

Prerequisites
=============

Is dependent on the deploying detail logging and requires MFProcessBatch id as input in solution.

Warnings
========

This procedure to be used as part of an overall messaging and logging solution. It will typically be called as part of a context menu,  or by the spMFProcessBatch_Email procedure to notify a user of outcome of a process.

Examples
========

Get formatted output for a processbatch id

.. code:: sql

    DECLARE @MessageOUT NVARCHAR(4000)
           ,@MessageForMFilesOUT NVARCHAR(4000)
           ,@EMailHTMLBodyOUT NVARCHAR(MAX);

    EXEC [dbo].[spMFResultMessageForUI] @Processbatch_ID = 3   
              ,@MessageOUT = @MessageOUT OUTPUT
              ,@MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT
              ,@GetEmailContent = 1
              ,@EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT

              Select @MessageOUT standardOutput, @MessageForMFilesOUT MFilesFormat, @EmailHTMLBodyOut EmailOutput

Get formatted output for Processbatch and ProcessBatchDetail

.. code:: sql

    DECLARE @MessageOUT NVARCHAR(4000)
           ,@MessageForMFilesOUT NVARCHAR(4000)
           ,@EMailHTMLBodyOUT NVARCHAR(MAX);

    EXEC [dbo].[spMFResultMessageForUI] @Processbatch_ID = 191
              ,@Detaillevel = 1     
              ,@MessageOUT = @MessageOUT OUTPUT
              ,@MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT
              ,@GetEmailContent = 1
              ,@EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT

              Select @MessageOUT standardOutput, @MessageForMFilesOUT MFilesFormat, @EmailHTMLBodyOut EmailOutput

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-05-31  LC         Fix bug with duration being null
2021-08-25  LC         Resolve bug with null count
2021-02-26  LC         Fix issue with duration
2019-08-30  JC         Added documentation
2018-12-02  LC         Fix bug for returning more than one result in query
2018-11-18  LC         Fix count of records
2018-11-15  LC         Fix bug for MF message out
2018-05-20  LC         Modify result message for MFUserMessages
2017-12-29  LC         Allow for message from processbatchdetail level
2017-07-15  LC         Allow for default message when no table is involved in the process (e.g metadata synchronisation)
2017-06-26  AC         Add HTML Email Body Output
2017-06-26  AC         Remove @RowCount, RowCount calculated from ProcessBatch_ID as part of
2017-06-26  AC         Remove @ClassTable, Class Table derived from ProcessBatch_ID
2017-06-21  AC         Change @MessageOUT as optional (default = NULL)
2017-06-21  AC         Add MessageForMFilesOUT as optional (default=null) to allow for usage in multi-line text property
==========  =========  ========================================================

**rST*************************************************************************/

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
      
   SELECT @SumDuration = CASE WHEN @SumDuration IS NULL THEN 
   (SELECT TOP 1 mpb.DurationSeconds FROM dbo.MFProcessBatch AS mpb WHERE [ProcessBatch_ID] = @Processbatch_ID )
   ELSE @SumDuration
   END
   

        BEGIN -- default message

    -------------------------------------------------------------
    -- Default message
    -------------------------------------------------------------
    SELECT @Message
        = CASE
              WHEN @Detaillevel = 0 THEN
    (
        SELECT ISNULL([mpb].[ProcessType], '(process type unknown)') + ': '
               + ISNULL([mpb].[Status], '(status unknown)') + ' | ' + ISNULL([mpb].[LogText], '(null)') + ' | '
               + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
               + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)') + ' | '
               + 'Duration Seconds: ' + CONVERT(VARCHAR(25), @SumDuration)
        + CAST(RIGHT('0' + CAST(FLOOR((COALESCE([mpb].[DurationSeconds], 0) / 60) / 60) AS VARCHAR(8)), 2) + ':'
               + RIGHT('0' + CAST(FLOOR(COALESCE([mpb].[DurationSeconds], 0) / 60) AS VARCHAR(8)), 2) + ':' AS varchar(258))
        FROM [dbo].[MFProcessBatch] AS [mpb]
        WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID
    )
              WHEN @Detaillevel = 1 THEN
    (
        SELECT ISNULL([mpb].[ProcessType], '(process type unknown)') + ': '
               + ISNULL([mpbd].[Status], '(status unknown)') + ' | ' + ISNULL([mpbd].[LogText], '(null)') + ' | '
               + 'Process Batch#: ' + ISNULL(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)), '(null)') + ' | '
               + 'Started On: ' + ISNULL(CONVERT(VARCHAR(30), [mpb].[CreatedOn]), '(null)') + ' | '
                    + 'Duration Seconds: ' + CONVERT(VARCHAR(25), @SumDuration)             
                      + CAST(RIGHT('0' + CAST(FLOOR((COALESCE([mpb].[DurationSeconds], 0) / 60) / 60) AS VARCHAR(8)), 2) + ':'
               + RIGHT('0' + CAST(FLOOR(COALESCE([mpb].[DurationSeconds], 0) / 60) AS VARCHAR(8)), 2) + ':' AS varchar(258))
        FROM [dbo].[MFProcessBatch] AS [mpb]
            INNER JOIN [dbo].[MFProcessBatchDetail] AS [mpbd]
                ON [mpbd].[ProcessBatch_ID] = [mpb].[ProcessBatch_ID]
        WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID
              AND [mpbd].[LogType] = 'Message'
             AND ([mpbd].[MFTableName] <> 'MFUserMessages' OR [mpbd].[MFTableName] IS NULL)
    )
          END --end case
     END; -- end default message

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
       
        FROM [dbo].[MFProcessBatch] AS [mpb]
        WHERE [mpb].[ProcessBatch_ID] = @Processbatch_ID;

        SET @DebugText = 'Message %s';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Message);
        END;
    END; --IF @ClassTableCount = 1

    IF @ClassTableCount > 1
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

			IF @debug > 0
			 SELECT @DetailStatus   as [LogStatus]
                  ,@DetailLogText  as [LogText]
                  ,@DetailDuration as [Duration]
                  ,@RecordCount    as [RecCount];

            SET @Message
                = @Message + ' |  | ' + 'Class Name: ' + ISNULL(@ClassName, '(null)') + ': '
                  + ISNULL(@DetailStatus, '(status unknown)') + ' | ' + ISNULL(@DetailLogText, '(null)') + ' | '
                  + 'Duration: ' + CONVERT(VARCHAR(25), @DetailDuration) + ' Count: '
                  + CAST(ISNULL(@RecordCount,0) AS VARCHAR(10));

				  IF @debug > 0
				  SELECT @message AS '@Message'

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
