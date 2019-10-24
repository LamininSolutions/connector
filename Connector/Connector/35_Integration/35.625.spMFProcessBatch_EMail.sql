PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatch_EMail]';
GO

SET NOCOUNT ON;
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFProcessBatch_EMail', -- nvarchar(100)
    @Object_Release = '3.1.4.41',            -- varchar(50)
    @UpdateFlag = 2                          -- smallint
;
GO
/*------------------------------------------------------------------------------------------------
	Author: Arnie Cilliers, Laminin Solutions
	Create date: 2017-22
	Database: 
	Description: To email MFProcessBatch and MFPRocessBatch_Detail along with error checking results from spMFCreateTableStats 

	PARAMETERS:
			@ProcessBatch_ID:				Required - ProcessBatch ID to report on
			@RecipientEmail:				Optional - If not provided will look for MFSettings setting Name= DefaultAREmailRecipients
			@RecipientFromMFSettingName:	Optional - if provided the setting will be looked up from MFSettings and added to the provided RecipientEmail if it too was provided.
			@ContextMenu_ID:				Optional - future use. Will lookup recipient e-mail based on UserId of Context Menu [Last Executed By]
			@DetailLevel:					Optional - Default(0) - Summary Only
															   1  - Include MFProcessBatchDetail for LogTypes in @LogTypes
															   2
															   -1 - Lookup DetailLevel from MFSettings																   										  		 		
			@LogTypes:						Optional - If provided along with DetailLevel=2, the LogTypes provided in CSV format will be included in the e-mail 

------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-10-03		LC			Add parameter for Detaillevel, but not yet activate.  Add selection of ContextMenu user as email address.
	2017-11-24		LC			Fix issue with getting name of MFContextMenu user
	2017-12-28		lc			allow for messages with detail from ProcessBatchDetail
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

USAGE:	EXEC spMFProcessBatch_EMail 
			  @@Debug = 1
  
-----------------------------------------------------------------------------------------------*/
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

               
				    EXEC [dbo].[spMFResultMessageForUI]
                        @Processbatch_ID = @ProcessBatch_ID,
                        @GetEmailContent = 1,
						@DetailLevel = @DetailLevel,
                        @EMailHTMLBodyOUT = @EMAIL_BODY OUTPUT;



                    SET @Step = 'Send';
                    SET @ProcedureStep = 'EXEC msdb.dbo.Sp_send_dbmail';

                    --------------------------------------
                    --EXECUTE Sp_send_dbmail TO SEND MAIL
                    ---------------------------------------
                    IF @Debug > 0
                        SELECT
                            @EMAIL_BODY;



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
