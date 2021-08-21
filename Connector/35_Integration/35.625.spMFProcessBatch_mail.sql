PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatch_EMail]';
GO

SET NOCOUNT ON;
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFProcessBatch_EMail', -- nvarchar(100)
    @Object_Release = '4.9.26.68',            -- varchar(50)
    @UpdateFlag = 2                          -- smallint
;
GO

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFProcessBatch_EMail' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFProcessBatch_EMail]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROC [dbo].[spMFProcessBatch_EMail]
    @ProcessBatch_ID            INT,
    @RecipientEmail             NVARCHAR(258) = NULL,
    @RecipientFromMFSettingName NVARCHAR(258) = NULL,
    @ContextMenu_ID             INT           = NULL, --Future use once [Last_Executed_by] has been added to MFContextMenu
    @DetailLevel                INT           = 0,
	@LogTypes				NVARCHAR(258) = 'Message',
    @Debug                      INT           = 0
AS

/*rST**************************************************************************

======================
spMFProcessBatch_Mail
======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch_ID (Required)
    - Referencing the ID of :doc:`/tables/tbMFProcessBatch` to be included in the email
  @RecipientEmail (Optional)
    - If not provided will look for MFSettings setting Name = 'SupportEMailProfile'
  @RecipientFromMFSettingName (Optional)
    - if provided the setting will be looked up from MFSettings and added to the provided RecipientEmail if it too was provided.
  @ContextMenu_ID (Optional)
    - Will lookup recipient e-mail based on UserId of Context Menu [Last Executed By]
  @DetailLevel (Optional)
    - Default(0) - Summary Only
    - 1 Include MFProcessBatchDetail for LogTypes in @LogTypes
  @LogTypes (Optional)
    - If provided along with DetailLevel=2, the LogTypes provided in CSV format will be included in the e-mail 
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To email MFProcessBatch and MFPRocessBatch_Detail along with error checking results from spMFCreateTableStats

Additional Info
===============

This procedures calls :doc:`/procedures/spMFResultMessageForUI`. The latter procedure formats the email body.

Setting the Detail level to 1 and defining the logTypes to 'Status' show extended details for processing.

Prerequisites
=============

When DetailLevel is set to 1 then logtype need to be specified.

Examples
========

Show the Records in MFProcessBatch and MFProcessBatchDetail 

.. code:: sql

    SELECT * FROM dbo.MFProcessBatch AS mpb
    INNER JOIN dbo.MFProcessBatchDetail AS mpbd
    ON mpbd.ProcessBatch_ID = mpb.ProcessBatch_ID
    WHERE mpb.ProcessBatch_ID = 3

Email with summary detail sent to email defined in MFSettings SupportEMailProfile

.. code:: sql

    EXEC spMFProcessBatch_EMail 
    @ProcessBatch_id = 191,
	@Debug = 0

Email with more detail on the processing steps

.. code:: sql

    EXEC spMFProcessBatch_EMail 
    @ProcessBatch_id = 191,
    @DetailLevel = 1,
    @Logtypes = 'Status',
	@Debug = 0
  
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-02-25  LC         Showing processbatch detail with 
2017-12-28  LC         Allow for messages with detail from ProcessBatchDetail
2017-11-24  LC         Fix issue with getting name of MFContextMenu user
2017-10-03  LC         Add parameter for Detaillevel, but not yet activate.  Add selection of ContextMenu user as email address.
2017-02-01  AC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

    BEGIN

        --** Stored Proc Content

        ------------------------------------------------------
        -- SET SESSION STATE
        -------------------------------------------------------
        SET NOCOUNT ON;

        ------------------------------------------------------
        -- DECLARE VARIABLES
        ------------------------------------------------------
        DECLARE
            @ec            INT,
            @rowcount      INT,
            @ProcedureName sysname,
            @ProcedureStep sysname;

        DECLARE
            @ErrorSeverity   INT,
            @ErrorState      INT,
            @ErrorNumber     INT,
            @ErrorLine       INT,
            @ErrorMessage    NVARCHAR(500),
            @ErrorProcedure  NVARCHAR(128),
            @OptionalMessage VARCHAR(MAX);

        DECLARE
            @ErrStep VARCHAR(255),
            @Stage   VARCHAR(50),
            @Step    VARCHAR(30);

        ------------------------------------------------------
        -- DEFINE CONSTANTS
        ------------------------------------------------------
        SET @ProcedureName = '[dbo].[spMFProcessBatch_EMail]';
        SET @ec = 0;
        SET @rowcount = 0;
        SET @Stage = 'Email';

        BEGIN TRY
            SET @Step = 'Prepare';

            ------------------------------------------------------
            -- ignore if email is not setup
            ------------------------------------------------------

            IF
                (
                    SELECT
                        COUNT(*)
                    FROM
                        [msdb].[dbo].[sysmail_profile] AS [sp]
                ) > 0
                BEGIN

                    --############################## Get DBMail Profile ##############################
                    SET @ProcedureStep = 'Get Email Profile';

                    DECLARE @EMAIL_PROFILE VARCHAR(255);
                    DECLARE @ReturnValue INT;

                    EXEC @ReturnValue = [dbo].[spMFValidateEmailProfile]
                        @emailProfile = @EMAIL_PROFILE OUTPUT, -- varchar(100)
                        @debug = @Debug;                       -- smallint

                    IF @ReturnValue = 1
                        BEGIN

                            --		SELECT @EMAIL_PROFILE

                            SELECT
                                @EMAIL_PROFILE = CONVERT(VARCHAR(50), [Value])
                            FROM
                                [dbo].[MFSettings]
                            WHERE
                                [Name] = 'SupportEMailProfile';
                        END;


                    --############################## Get From, ReplyTo & CC ##############################
                    SET @ProcedureStep = 'Get Email Address';

                    DECLARE
                        @EMAIL_FROM_ADDR    VARCHAR(255),
                        @EMAIL_REPLYTO_ADDR VARCHAR(255),
                        @EMAIL_CC_ADDR      VARCHAR(255),
                        @EMAIL_TO_ADDR      VARCHAR(255);

                    SELECT
                        @EMAIL_FROM_ADDR = [a].[email_address]
                    FROM
                        [msdb].[dbo].[sysmail_account]            AS [a]
                        INNER JOIN
                            [msdb].[dbo].[sysmail_profileaccount] AS [pa]
                                ON [a].[account_id] = [pa].[account_id]
                        INNER JOIN
                            [msdb].[dbo].[sysmail_profile]        AS [p]
                                ON [pa].[profile_id] = [p].[profile_id]
                    WHERE
                        [p].[name] = @EMAIL_PROFILE
                        AND [pa].[sequence_number] = 1;


                    --############################## Get Recipients ##############################
                    SET @ProcedureStep = 'Get Email Recipients';

                    DECLARE @RecipientFromMFSetting NVARCHAR(258);
                    DECLARE @RecipientFromContextMenu NVARCHAR(258);


                    IF @RecipientFromMFSettingName IS NOT NULL
                        SELECT
                            @RecipientFromMFSetting = CONVERT(VARCHAR(258), [Value])
                        FROM
                            [dbo].[MFSettings]
                        WHERE
                            [Name] = @RecipientFromMFSettingName;

                    -- To be implemented when [Last_Executed_by] has been added to MFContextMenu
                    IF @ContextMenu_ID IS NOT NULL
                        SELECT
                            @RecipientFromContextMenu = [dbo].[MFLoginAccount].[EmailAddress]
                        FROM
                            [dbo].[MFContextMenu]
                            INNER JOIN
                                [dbo].[MFUserAccount] AS [mua]
                                    ON [mua].[UserID] = [MFContextMenu].[Last_Executed_By]
                            INNER JOIN
                                [dbo].[MFLoginAccount]
                                    ON [mua].[LoginName] = [MFLoginAccount].[UserName]
                        WHERE
                            [MFContextMenu].[ID] = @ContextMenu_ID;


                    SET @EMAIL_TO_ADDR = CASE
                                             WHEN @RecipientEmail IS NOT NULL
                                                 THEN @RecipientEmail
                                             ELSE
                                                 ''
                                         END + CASE
                                                   WHEN @RecipientFromMFSetting IS NOT NULL
                                                       THEN ';' + @RecipientFromMFSetting
                                                   ELSE
                                                       ''
                                               END + CASE
                                                         WHEN @RecipientFromContextMenu IS NOT NULL
                                                             THEN ';' + @RecipientFromContextMenu
                                                         ELSE
                                                             ''
                                                     END;

                    IF @Debug > 0
                        SELECT
                            @EMAIL_TO_ADDR;

                    IF ISNULL(@EMAIL_TO_ADDR, '') = ''
                        SELECT
                            @EMAIL_TO_ADDR = CONVERT(VARCHAR(100), [Value])
                        FROM
                            [dbo].[MFSettings]
                        WHERE
                            [Name] = 'SupportEmailRecipient'
                            AND [source_key] = 'Email';
          
		            IF @Debug > 0
                        SELECT
                            @EMAIL_TO_ADDR;

                    IF LEFT(@EMAIL_TO_ADDR, 1) = ';'
                        SET @EMAIL_TO_ADDR = SUBSTRING(@EMAIL_TO_ADDR, 2, LEN(@EMAIL_TO_ADDR));


                    --############################## Get Subject ##############################
                    SET @ProcedureStep = 'Get Email Subject';

                    DECLARE @EMAIL_SUBJECT VARCHAR(255);

                    SELECT
                        @EMAIL_SUBJECT
                        = 'MFSQL: ' + ISNULL([mpb].[ProcessType], '(process type unknown)') + ' | '
                          + ISNULL([mpb].[Status], '(status unknown)') + ' | Process Batch - ID '
                          + CAST(@ProcessBatch_ID AS VARCHAR(10))
                    FROM
                        [dbo].[MFProcessBatch] AS [mpb]
                    WHERE
                        [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

                    --############################## Get Body ##############################	
                    SET @ProcedureStep = 'Get Email Body';
                    DECLARE @EMAIL_BODY NVARCHAR(MAX);

              IF @DetailLevel = 0
              Begin
				    EXEC [dbo].[spMFResultMessageForUI]
                        @Processbatch_ID = @ProcessBatch_ID,
                        @GetEmailContent = 1,
						@DetailLevel = @DetailLevel,
                        @EMailHTMLBodyOUT = @EMAIL_BODY OUTPUT;

                END
                IF @DetailLevel = 1
                BEGIN
                
                 EXEC [dbo].[spMFResultMessageForUI]
                        @Processbatch_ID = @ProcessBatch_ID,
                        @GetEmailContent = 1,
						@DetailLevel = 0,
                        @EMailHTMLBodyOUT = @EMAIL_BODY OUTPUT;


DECLARE @TableBody   NVARCHAR(MAX),
    @SQLquery NVARCHAR(MAX) 
    
  SET @SQLquery =  N' 
SELECT
       mpbd.ProcessBatchDetail_ID,
       mpbd.LogType,
       mpbd.ProcedureRef,
       mpbd.LogText,
       mpbd.Status,
       mpbd.DurationSeconds,
       mpbd.CreatedOn,
       mpbd.MFTableName,
       mpbd.ColumnName,
       mpbd.ColumnValue
       FROM dbo.MFProcessBatch AS mpb
INNER JOIN dbo.MFProcessBatchDetail AS mpbd
ON mpbd.ProcessBatch_ID = mpb.ProcessBatch_ID
WHERE mpb.ProcessBatch_ID = '+ CAST(@ProcessBatch_ID AS VARCHAR(10))+ ' AND (mpbd.logtype = '''+@Logtypes+''')    
    '

EXEC dbo.spMFConvertTableToHtml @SqlQuery = @SqlQuery,
    @TableBody = @TableBody OUTPUT,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Debug = 1

    SELECT @EMAIL_BODY = @EMAIL_BODY + '<BR>' + @TableBody

                END


                    SET @Step = 'Send';
                    SET @ProcedureStep = 'EXEC msdb.dbo.Sp_send_dbmail';

                    --------------------------------------
                    --EXECUTE Sp_send_dbmail TO SEND MAIL
                    ---------------------------------------
                    IF @Debug > 0
                        SELECT
                            @EMAIL_BODY AS Body;



                    BEGIN TRY

                        EXEC [msdb].[dbo].[sp_send_dbmail]
                            @profile_name = @EMAIL_PROFILE,
                            @recipients = @EMAIL_TO_ADDR, --, @copy_recipients = @EMAIL_CC_ADDR
                            @subject = @EMAIL_SUBJECT,
                            @body = @EMAIL_BODY,
                            @body_format = 'HTML';

                    END TRY
                    BEGIN CATCH

                        SELECT
                            @ErrorMessage   = ERROR_MESSAGE(),
                            @ErrorSeverity  = ERROR_SEVERITY(),
                            @ErrorState     = ERROR_STATE(),
                            @ErrorNumber    = ERROR_NUMBER(),
                            @ErrorLine      = ERROR_LINE(),
                            @ErrorProcedure = ERROR_PROCEDURE();


                        IF @Debug > 0
                            RAISERROR('ERROR in %s at %s: %s', 16, 1, @ErrorProcedure, @ProcedureStep, @ErrorMessage);

                        INSERT INTO [MFLog]
                            (
                                [SPName],
                                [ErrorNumber],
                                [ErrorMessage],
                                [ErrorProcedure],
                                [ErrorState],
                                [ErrorSeverity],
                                [ErrorLine],
                                [ProcedureStep]
                            )
                        VALUES
                            (
                                @ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(),
                                ERROR_SEVERITY(), ERROR_LINE(), @ProcedureStep
                            );

                        RAISERROR(   @ErrorMessage,  -- Message text.
                                     @ErrorSeverity, -- Severity.
                                     @ErrorState     -- State.
                                 );
                    END CATCH;




                    RETURN 1;

                END; --IF	(	SELECT COUNT(*)	FROM   [msdb].[dbo].[sysmail_profile] AS [sp]) > 0
            ELSE
                PRINT 'Database mail has not setup been setup. Complete the setup to receive notifications by email';
            RETURN 2;

        END TRY
        BEGIN CATCH


            SELECT
                @ErrorMessage   = ERROR_MESSAGE(),
                @ErrorSeverity  = ERROR_SEVERITY(),
                @ErrorState     = ERROR_STATE(),
                @ErrorNumber    = ERROR_NUMBER(),
                @ErrorLine      = ERROR_LINE(),
                @ErrorProcedure = ERROR_PROCEDURE();


            RAISERROR(   @ErrorMessage,  -- Message text.
                         @ErrorSeverity, -- Severity.
                         @ErrorState     -- State.
                     );

            RETURN -1;
        END CATCH;

    END;

GO
