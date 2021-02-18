PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'dbo.[spMFSendHTMLBodyEmail]';
GO

SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFSendHTMLBodyEmail' -- nvarchar(100)
  , @Object_Release = '4.9.25.67'
  , @UpdateFlag = 2

GO

SET NOCOUNT ON;

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSendHTMLBodyEmail' --name of procedure
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
CREATE PROCEDURE dbo.spMFSendHTMLBodyEmail
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFSendHTMLBodyEmail
(
    -- Add the parameters for the function here
    @Body NVARCHAR(MAX),
    @MessageTitle NVARCHAR(258),
    @FromEmail NVARCHAR(258),
    @ToEmail NVARCHAR(258),
    @CCEmail NVARCHAR(258),
    @Mailitem_ID INT OUTPUT,
    @ProcessBatch_ID INT = NULL output,
    @Debug INT = 0
)
AS

/*rST***************************************************************************

=====================
spMFSendHTMLBodyEmail
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
   @Body 
     Body must be in HTML format
   @MessageTitle 
     Subject of email
   @FromEmail 
     email address for sender
   @ToEmail 
     email address of recipient. Delimited with ';' if multiples
   @CCEmail 
     email address of CC recipients. Delimited with ';' if multiples 
   @Mailitem_ID  output
     msdb database mail id
   @ProcessBatch_ID 
     will record processing in MFProcessBatch
   @Debug 
       Default = 0
       1 = Standard Debug Mode

Purpose
=======

This procedure will send a single email with a body is formatted in HTML format using msdb database mail manager

Additional Info
===============

The @body param must include the full body in HTML format, the following is the bare bones.

.. code:: HTML

    <html>
    <head> </head>
    <body> </body>
    </html>

Prerequisites
=============

msdb Database mail need to be activiated and configured.

Examples
========

.. code:: sql

    DECLARE @Mailitem_ID INT;
    DECLARE @Body NVARCHAR(MAX) = '<html>  <head>   <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />   <style type="text/css">    div {line-height: 100%;}      body {-webkit-text-size-adjust:none;-ms-text-size-adjust:none;margin:0;padding:0;}     body, #body_style {min-height:1000px;font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;}    p {margin:0; padding:0; margin-bottom:0;}    h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}      table {     border-collapse: collapse;          border: 1px solid #3399FF;          font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;          color: black;        padding:5;        border-spacing:1;        border:0;       }    table caption {font-weight: bold;color: blue;}    table td, table th, table tr,table caption { border: 1px solid #eaeaea;border-collapse:collapse;vertical-align: top; }    table th {font-weight: bold;font-variant: small-caps;background-color: blue;color: white;vertical-align: bottom;}   </style>  </head><body><div class=greeting><p>Hi </p><br></div><div class=content><p> This is the body </p><br></div><div class=signature><p> yours sincerely Me </p><br></div><div class=footer><p>Company details</p></div></body></html>'
    EXEC dbo.spMFSendHTMLBodyEmail @Body = ,
    @MessageTitle = 'test',
    @FromEmail = 'support@lamininsolutions.com',
    @ToEmail = 'support@lamininsolutions.com',
    @CCEmail = 'support@lamininsolutions.com',
    @Mailitem_ID = @Mailitem_ID OUTPUT,
    @ProcessBatch_ID = null,
    @Debug = 1
    SELECT @Mailitem_ID

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-29  LC         Updated to allow for setting profile in MFEmailTemplate
2021-01-26  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @MFTableName AS NVARCHAR(128) = NULL;
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Send Email');

-------------------------------------------------------------
-- CONSTATNS: MFSQL Global 
-------------------------------------------------------------
DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
DECLARE @Process_ID_1_Update TINYINT = 1;
DECLARE @Process_ID_6_ObjIDs TINYINT = 6; --marks records for refresh from M-Files by objID vs. in bulk
DECLARE @Process_ID_9_BatchUpdate TINYINT = 9; --marks records previously set as 1 to 9 and update in batches of 250
DECLARE @Process_ID_Delete_ObjIDs INT = -1; --marks records for deletion
DECLARE @Process_ID_2_SyncError TINYINT = 2;
DECLARE @ProcessBatchSize INT = 250;

-------------------------------------------------------------
-- VARIABLES: MFSQL Processing
-------------------------------------------------------------
DECLARE @Update_ID INT;
DECLARE @MFLastModified DATETIME;
DECLARE @Validation_ID INT;

-------------------------------------------------------------
-- VARIABLES: T-SQL Processing
-------------------------------------------------------------
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT = 0;
DECLARE @error AS INT = 0;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFSendHTMLBodyEmail';
DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = N'Status';
DECLARE @LogText AS NVARCHAR(4000) = N'';
DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
DECLARE @count INT = 0;
DECLARE @Now AS DATETIME = GETDATE();
DECLARE @StartTime AS DATETIME = GETUTCDATE();
DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

-------------------------------------------------------------
-- VARIABLES: DYNAMIC SQL
-------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @sqlParam NVARCHAR(MAX) = N'';

-------------------------------------------------------------
-- VARIABLES: CUSTOM
-------------------------------------------------------------
DECLARE @Message  NVARCHAR(4000),
    @ErrorMessage NVARCHAR(4000),
    @ec           INT,
    @Stage        NVARCHAR(256),
    @Step         NVARCHAR(256);

-------------------------------------------------------------
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = N'Start Logging';
SET @LogText = N'Processing ' + @ProcedureName;

EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @ProcessType = @ProcessType,
    @LogType = N'Status',
    @LogText = @LogText,
    @LogStatus = N'In Progress',
    @debug = @Debug;

EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
    @LogType = N'Debug',
    @LogText = @ProcessType,
    @LogStatus = N'Started',
    @StartTime = @StartTime,
    @MFTableName = @MFTableName,
    @Validation_ID = @Validation_ID,
    @ColumnName = NULL,
    @ColumnValue = NULL,
    @Update_ID = @Update_ID,
    @LogProcedureName = @ProcedureName,
    @LogProcedureStep = @ProcedureStep,
    @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
    @debug = 0;

-------------------------------------------------------------
-- BEGIN PROCESS
-------------------------------------------------------------
BEGIN TRY
    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    -------------------------------------------------------------
    -- Setup body
    -------------------------------------------------------------
    -- Construct and Return @MessageForHTMLOUT
    DECLARE @EMailHTMLBodyOUT NVARCHAR(MAX);

    SET @EMailHTMLBodyOUT = @Body;

    ------------------------------------------------------
    -- ignore if email is not setup
    ------------------------------------------------------
    IF
    (
        SELECT COUNT(*) FROM msdb.dbo.sysmail_profile AS sp
    ) > 0
    BEGIN

        --############################## Get DBMail Profile ##############################
        SET @ProcedureStep = N'Get Email Profile';

        DECLARE @EMAIL_PROFILE VARCHAR(255);
        DECLARE @ReturnValue INT;

        SELECT @EMAIL_PROFILE = Emailprofile FROM dbo.MFEmailTemplate AS met
      
        EXEC @ReturnValue = dbo.spMFValidateEmailProfile @emailProfile = @EMAIL_PROFILE OUTPUT, 
            @debug = @Debug;                                                                    -- 

        IF @ReturnValue = 1
        BEGIN

            --		SELECT @EMAIL_PROFILE
            SELECT @EMAIL_PROFILE = CONVERT(VARCHAR(50), Value)
            FROM dbo.MFSettings
            WHERE Name = 'SupportEMailProfile';
        END;

        --############################## Get From, ReplyTo & CC ##############################
        SET @ProcedureStep = N'Get Email Address';

        DECLARE @EMAIL_FROM_ADDR VARCHAR(255),
            @EMAIL_REPLYTO_ADDR  VARCHAR(255),
            @EMAIL_CC_ADDR       VARCHAR(255),
            @EMAIL_TO_ADDR       VARCHAR(255);

        SELECT @EMAIL_FROM_ADDR = a.email_address
        FROM msdb.dbo.sysmail_account                  AS a
            INNER JOIN msdb.dbo.sysmail_profileaccount AS pa
                ON a.account_id = pa.account_id
            INNER JOIN msdb.dbo.sysmail_profile        AS p
                ON pa.profile_id = p.profile_id
        WHERE p.name = @EMAIL_PROFILE
              AND pa.sequence_number = 1;

        --############################## Get Recipients ##############################
        SET @ProcedureStep = N'Get Email Recipients';

        DECLARE @RecipientFromMFSetting NVARCHAR(258);
        DECLARE @RecipientFromContextMenu NVARCHAR(258);

        SET @EMAIL_TO_ADDR = @ToEmail;

        IF @Debug > 0
            SELECT @EMAIL_TO_ADDR;

        --############################## Get Subject ##############################
        SET @ProcedureStep = N'Get Email Subject';

        DECLARE @EMAIL_SUBJECT VARCHAR(255);

        SELECT @EMAIL_SUBJECT = @MessageTitle;

        --############################## Get Body ##############################	
        SET @ProcedureStep = N'Get Email Body';

        DECLARE @EMAIL_BODY NVARCHAR(MAX);

        SELECT @EMAIL_BODY = @Body;

        SET @Step = N'Send';
        SET @ProcedureStep = N'EXEC msdb.dbo.Sp_send_dbmail';

        --------------------------------------
        --EXECUTE Sp_send_dbmail TO SEND MAIL
        ---------------------------------------
        IF @Debug > 0
            SELECT @EMAIL_BODY;

        EXEC msdb.dbo.sp_send_dbmail @profile_name = @EMAIL_PROFILE,
            @recipients = @EMAIL_TO_ADDR, --, @copy_recipients = @EMAIL_CC_ADDR
            @subject = @EMAIL_SUBJECT,
            @body = @EMAIL_BODY,
            @body_format = 'HTML',
            @mailitem_id = @Mailitem_ID OUTPUT;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';
        SET @LogStatus = N'Completed';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
            @ProcessType = @ProcessType,
            @LogType = N'Message',
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = N'Debug',
            @LogText = @ProcessType,
            @LogStatus = @LogStatus,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = NULL,
            @ColumnValue = NULL,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = 0;

        RETURN 1;
    END; -- mail not setup
    ELSE
    BEGIN
        RAISERROR('First setup msdb mail manager then try again', 10, 1);
    END;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();
    SET @LogStatus = N'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO dbo.MFLog
    (
        SPName,
        ErrorNumber,
        ErrorMessage,
        ErrorProcedure,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ProcedureStep
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
        @ProcedureStep);

    SET @ProcedureStep = N'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = N'Error',
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatus,
        @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = N'Error',
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatus,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = NULL,
        @ColumnValue = NULL,
        @Update_ID = @Update_ID,
        @LogProcedureName = @ProcedureName,
        @LogProcedureStep = @ProcedureStep,
        @debug = 0;

    RETURN -1;
END CATCH;
GO