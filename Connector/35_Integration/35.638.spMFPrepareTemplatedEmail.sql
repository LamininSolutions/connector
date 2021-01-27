PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFPrepareTemplatedEmail]';
GO

SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFPrepareTemplatedEmail' -- nvarchar(100)
  , @Object_Release = '4.9.26.67'
  , @UpdateFlag = 2

GO

SET NOCOUNT ON;

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFPrepareTemplatedEmail' --name of procedure
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
CREATE PROCEDURE dbo.spMFPrepareTemplatedEmail
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFPrepareTemplatedEmail
(
    @RecipientEmail NVARCHAR(128),
    @Document_ID INT,
    @IncludeTable BIT = 0,
    @Template_ID INT,
    @processbatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=========================
spMFPrepareTemplatedEmail
=========================

Return
- 1 = Success
- -1 = Error
Parameters
   @RecipientEmail NVARCHAR(128)
    - email of recipient
   @Document_ID int
    - identity of related object such as objid
   @IncludeTable 
    - default = 0
    - if set to 1 then the email prepare will expect table to be added
   @Template_ID INT
    - id of the related template
   @ProcessBatch_ID (optional, output)
    - Referencing the ID of the ProcessBatch logging table
   @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To customise the body of the email for each recipient and send the email.

The procedure will compile the email based on the columns in the email Template table for the object identified by the Document_ID and send it using spMFSendHTMLBodyEmail.

This procedure may have to be customised for your specific application and use.

Additional Info
===============

Set IncludeTable parameter to 1 and then customise the procedure to include the designated table in the code MODIFY THIS SECTION FOR SELECTION OF THE TABLE

If the placeholder of the body is defined as '{head}' then it would use the default CSS defined in MFSettings as the email head.

Two placeholders have been defined as examples : '{firstname}, {user}'. The use of the placeholders are optional.  Additional placeholders can be defined following the same pattern as these two placeholders.

Examples
========

.. code:: sql

    exec dbo.spMFPrepareTemplatedEmail 
    @RecipientEmail = '',
    @Document_ID = 90001,
    @IncludeTable = 0,
    @Template_ID = 1,
    @Debug = 0

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------

2020-01-26  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @MFTableName AS NVARCHAR(128) = NULL;
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Prepare Email');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFPrepareTemplatedEmail';
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
    DECLARE @Subject NVARCHAR(256);
    DECLARE @Body NVARCHAR(MAX);
    DECLARE @FromEmail NVARCHAR(128);
    DECLARE @CCmail NVARCHAR(128);
    DECLARE @TablePlaceholder NVARCHAR(10);
    DECLARE @TableBody NVARCHAR(MAX);
    DECLARE @Placeholder NVARCHAR(MAX);
    DECLARE @mailItem_ID INT;

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = N'Start Logging';
    SET @LogText = N'Processing ' + @ProcedureName;

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @processbatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = N'Status',
        @LogText = @LogText,
        @LogStatus = N'In Progress',
        @debug = @Debug;

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @processbatch_ID,
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

    BEGIN TRY
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @ProcedureStep = 'GetBody from template'
        BEGIN
            SELECT @TablePlaceholder = CASE
                                           WHEN @IncludeTable = 1 THEN
                                               '{Table}'
                                           ELSE
                                               ''
                                       END;

            SELECT @FromEmail = et.FromEmail,
                @CCmail       = et.CCEmail,
                @Subject      = et.Subject,
                @Body
                              = N'<html>' + COALESCE(et.Head_HTML, '') + N'<body>' + COALESCE(et.Greeting_HTML, '')
                                + COALESCE(et.MainBody_HTML, '') + COALESCE(@TablePlaceholder, '')
                                + COALESCE(et.Signature_HTML, '') + COALESCE(et.Footer_HTML, '') + N'</body> </html>'
            FROM dbo.MFEmailTemplate AS et
            WHERE et.ID = @Template_ID;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
         SELECT @FromEmail AS FromEmail,
                    @CCmail AS CCMail,
                    @Subject AS MailSubject,
                    @Body AS Body;
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;
           
           SET @ProcedureStep = 'Insert table'

            IF @IncludeTable = 1
            BEGIN
                IF
                (
                    SELECT OBJECT_ID('tempdb..##Report')
                ) IS NOT NULL
                    DROP TABLE ##Report;

                --MODIFY THIS SECTION FOR SELECTION OF THE TABLE
                SELECT *
                INTO ##Report
                FROM dbo.MFClass
                WHERE name = 'Document';
                -- END OF MODIFICATION

                EXECUTE dbo.spMFConvertTableToHtml 'Select * from ##Report',
                    @TableBody OUTPUT;

                SELECT @Body = REPLACE(@Body, '{Table}', @TableBody);

               SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
         SELECT @Body AS BodywithTable;
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

            END;

               SET @ProcedureStep = 'Replace placeholders'
           
            SET @Placeholder = NULL;

            --head

            IF @Body LIKE '%{head}%'
            BEGIN
                SELECT @Placeholder = CAST(Value AS NVARCHAR(MAX))
                FROM dbo.MFSettings
                WHERE Name = 'DefaultEMailCSS';

                SELECT @Body = REPLACE(@Body, '{head}', @Placeholder);
            END;

            --CUSTOM PLACE HOLDERS

            -- Greeting first name
            IF @Body LIKE '%{FirstName}%'
            BEGIN
                SET @Placeholder = NULL;

                --MODIFY THIS SECTION TO GET THE VALUE OF THE PLACE HOLDER
                SELECT @Placeholder = COALESCE(@Placeholder, 'john'); --replace this with logic to get firstname

                --END OF MODIFICATION

                SELECT @Body = REPLACE(@Body, '{FirstName}', @Placeholder);
             
            END;
            -- from user place holder
            IF @Body LIKE '%{User}%'
            BEGIN
                SET @Placeholder = NULL;

                --MODIFY THIS SECTION TO GET THE VALUE OF THE PLACE HOLDER
                SELECT @Placeholder = COALESCE(@Placeholder, 'MFSQL Support'); --replace this with logic to get user
                --END OF MODIFICATION

                SELECT @Body = REPLACE(@Body, '{User}', @Placeholder);

               
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
         SELECT @Body AS BodywithPlaceholders;
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

            END;

            SET @ProcedureStep = 'insert into maillog for mail preparation'

            MERGE INTO dbo.MFEmailLog t
            USING
            (
                SELECT Document_ID = @Document_ID,
                    Template_ID    = @Template_ID,
                    Email_Date     = GETDATE(),
                    Email_status   = 'Prepared',
                    Body           = @Body,
                    Recipient      = @RecipientEmail
            ) s
            ON t.document_ID = s.Document_ID
            WHEN NOT MATCHED THEN
                INSERT
                (
                    Document_ID,
                    Template_ID,
                    Email_Date,
                    Email_status,
                    Body,
                    Recipient
                )
                VALUES
                (s.Document_ID, s.Template_ID, s.Email_Date, s.Email_status, s.Body, s.Recipient)
            WHEN MATCHED THEN
                UPDATE SET Email_Date = s.Email_Date,
                    Email_Status = s.Email_status,
                    Body = s.Body,
                    Recipient = s.Recipient;

SET @ProcedureStep = 'Send email'

            EXEC dbo.spMFSendHTMLBodyEmail @Body,
                @Subject,
                @FromEmail,
                @RecipientEmail,
                @CCmail,
                @mailItem_ID OUTPUT;

         SET @DebugText = N'Mail sent id : %i' ;
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
         
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@mailItem_ID);
        END;

        SET @ProcedureStep = 'Update log table with outcome'

            UPDATE dbo.MFEmailLog
            SET msdb_mailitem_id = @mailItem_ID,
                email_status = 'Sent'
            WHERE document_id = @Document_ID
                  AND Template_ID = @Template_ID;
        END;

         SET @DebugText = N'Mail log entry for document_id %i' ;
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
         SELECT * FROM dbo.MFEmailLog WHERE Document_ID = @document_ID;
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@Document_ID);
        END;


        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';
        SET @LogStatus = N'Completed';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @processbatch_ID,
            @ProcessType = @ProcessType,
            @LogType = N'debug',
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @processbatch_ID,
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
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE(), @ProcedureStep);

        SET @ProcedureStep = N'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @processbatch_ID OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = N'Error',
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @processbatch_ID,
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
END;
GO