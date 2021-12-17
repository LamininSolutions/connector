
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFLogError_EMail]';
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFLogError_EMail', -- nvarchar(100)
    @Object_Release = '4.9.27.72', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 ;
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFLogError_EMail'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFLogError_EMail]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER PROC [dbo].[spMFLogError_EMail]
    @LogID INT ,
    @DebugFlag INT = 0
AS
    BEGIN

/*rST**************************************************************************

==================
spMFLogError_EMail
==================

Return
  - 1 = Success
  - -1 = Error

Parameters
  @LogID
    id of error log (MFLog) to include in email
  @DebugFlag
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To email MFLog error row, using a pre-formatted layout, to email address(es) specified in the MFSettings table with name SupportEmailRecipient.  

Example of error message: |image1|

The sending of the email is triggered on every entry in the MFLog table.


Warnings
========

The emails will only be sent if Database Mail has been setup and configured.

Examples
========

.. code:: sql

     EXEC spMFLogError_EMail 
              @Logid = 1
			  ,@DebugFlag = 1  

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-08-22  LC         Change name of procedure
2016-08-22  LC         Change settings index
2017-07-25	LC         Add deployed version to email
2018-11-22	LC         Add database to subject line
2021-11-17  LC         Increase email address field to 255 characters  

==========  =========  ========================================================

.. |image1| image:: Image_1.jpg

**rST*************************************************************************/

------------------------------------------------------
-- SET SESSION STATE
-------------------------------------------------------
        SET NOCOUNT ON;

------------------------------------------------------
-- DECLARE VARIABLES
------------------------------------------------------
        DECLARE @ec INT ,
            @rowcount INT ,
            @ProcedureName sysname ,
            @ProcedureStep sysname;
        DECLARE @ErrStep VARCHAR(255) ,
            @Stage VARCHAR(50) ,
            @Step VARCHAR(30);

------------------------------------------------------
-- DEFINE CONSTANTS
------------------------------------------------------
        SET @ProcedureName = '[dbo].[usp_MFLogError_EMail]';
        SET @ec = 0;
        SET @rowcount = 0;
        SET @Stage = 'Email';

        BEGIN TRY
            SET @Step = 'Prepare';

------------------------------------------------------
-- ignore if email is not setup
------------------------------------------------------

IF (SELECT COUNT(*) FROM msdb.[dbo].[sysmail_profile] AS [sp] ) > 0
Begin

	--############################## Get DBMail Profile ##############################
            SET @ProcedureStep = 'Get Email Profile';

            DECLARE @EMAIL_PROFILE VARCHAR(255);
			DECLARE @ReturnValue int

			EXEC @ReturnValue = [dbo].[spMFValidateEmailProfile] @emailProfile = @EMAIL_PROFILE output, -- varchar(100)
			    @debug = @DebugFlag -- smallint
			
			IF @ReturnValue = 1
			BEGIN
            
	--		SELECT @EMAIL_PROFILE

            SELECT  @EMAIL_PROFILE = CONVERT(VARCHAR(50), Value)
            FROM    [dbo].[MFSettings]
            WHERE   Name = 'SupportEMailProfile';	
			END
				

	--############################## Get From, ReplyTo & CC ##############################
            SET @ProcedureStep = 'Get Email Address';

            DECLARE @EMAIL_FROM_ADDR VARCHAR(255) ,
                @EMAIL_REPLYTO_ADDR VARCHAR(255) ,
                @EMAIL_CC_ADDR VARCHAR(255) ,
                @EMAIL_TO_ADDR VARCHAR(255);

            SELECT  @EMAIL_FROM_ADDR = a.email_address
            FROM    msdb.dbo.sysmail_account a
                    INNER JOIN msdb.dbo.sysmail_profileaccount pa ON a.account_id = pa.account_id
                    INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
            WHERE   p.name = @EMAIL_PROFILE
                    AND pa.sequence_number = 1;



            SET @EMAIL_TO_ADDR = ( SELECT   CONVERT(VARCHAR(255), Value)
                                   FROM     dbo.MFSettings
                                   WHERE    [Name] = 'SupportEmailRecipient' AND [source_key] = 'Email'
                                 );
	--############################## Get Subject ##############################
            SET @ProcedureStep = 'Get Email Subject';

            DECLARE @EMAIL_SUBJECT VARCHAR(255);
		
            SELECT  @EMAIL_SUBJECT = @@SERVERNAME + '.' + DB_NAME() + ': MFLog Error';

            SELECT  @EMAIL_SUBJECT = @EMAIL_SUBJECT + ' Log - ID:'
                    + CAST(@LogID AS VARCHAR(10))
            FROM    [dbo].MFLog l
            WHERE   [l].[LogID] = @LogID;

	--############################## Get Body ##############################	
            SET @ProcedureStep = 'Get Email Body';

            DECLARE @SPName NVARCHAR(MAX) ,
                @ErrorMessage NVARCHAR(MAX) ,
                @CreateDate VARCHAR(30) ,
                @ErrorProcedure VARCHAR(MAX) ,
                @ErrorStep NVARCHAR(MAX) ,
                @UpdateID VARCHAR(50) ,
                @ExternalID VARCHAR(50),
				@ProcVersion VARCHAR(50);

            SELECT  @SPName = [l].[SPName] ,
                    @ErrorMessage = [l].[ErrorMessage] ,
                    @CreateDate = ISNULL(CONVERT(VARCHAR(30), CreateDate, 100),
                                         '') ,
                    @ErrorProcedure = [l].[ErrorProcedure] ,
                    @ErrorStep = [l].[ProcedureStep] ,
                    @UpdateID = CAST(ISNULL([l].[Update_ID], 0) AS VARCHAR(50)) ,
                    @ExternalID = ISNULL([l].[ExternalID], '')
            FROM    [dbo].MFLog l
            WHERE   [l].[LogID] = @LogID;

			-- added TFS 1105 LC
			SELECT @ProcVersion = [moc].[Release] FROM setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Name] = @SPName

            DECLARE @EMAIL_BODY NVARCHAR(MAX) ,
                @EMAIL_MAILITEM_ID INT ,
                @UpdateStatus NVARCHAR(50);

            IF @DebugFlag <> 0
                SELECT  @EMAIL_PROFILE AS '@EMAIL_PROFILE' ,
                        @EMAIL_TO_ADDR AS '@EMAIL_TO_ADDR' ,
                        @EMAIL_SUBJECT AS '@EMAIL_SUBJECT'; 
            SELECT  @UpdateStatus = UpdateStatus
            FROM    MFUpdateHistory
            WHERE   id = CAST(@UpdateID AS INT);

	--Define StyleSheet
            SET @EMAIL_BODY = N'<html>
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<style type="text/css">
				div {line-height: 100%;}  
				body {-webkit-text-size-adjust:none; -ms-text-size-adjust:none;} 
				body {margin:0; padding:0;}
				table td {border-collapse:collapse;}    
				p {margin:0; padding:0; margin-bottom:0;}
				h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}  
				body, #body_style {
								min-height:1000px;
								font-family:Arial, Helvetica, sans-serif;
								font-size:12px;
								} 
				
			</style>
			</head>
			<body style="min-height:1000px;font-family:Arial, Helvetica, sans-serif; font-size:12px">
			<div  id="body_style" style="padding:15px">			';
	--Get Process Headers
            SET @ProcedureStep = 'Get Email Body: Process Summary';
            SET @EMAIL_BODY = '<div class="CSSTableGenerator" >
				<table cellpadding="5" cellspacing="1" border="1">
					<tr>
						<td width="20%">Log Error Date:</td>
						<td width="70%">' + ISNULL(@CreateDate, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Server Name:</td>
						<td width="70%">' + @@SERVERNAME + '</td>
					</tr>
					<tr>
						<td width="20%">Database:</td>
						<td width="70%">' + DB_NAME() + '</td>
					</tr>
					<tr>
						<td width="20%">SPName:</td>
						<td width="70%">' + ISNULL(@SPName, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Error Message:</td>
						<td width="70%">' + ISNULL(@ErrorMessage, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">Error Procedure:</td>
						<td width="70%">' + ISNULL(@ErrorProcedure, '')
                + '</td>
					</tr> 
					<tr>
						<td width="20%">Procedure Step:</td>
						<td width="70%">' + ISNULL(@ErrorStep, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">Update ID:</td>
						<td width="70%">' + ISNULL(@UpdateID, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">External ID:</td>
						<td width="70%">' + ISNULL(@ExternalID, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Update Status</td>
						<td width="70%">' + ISNULL(@UpdateStatus, '') + '</td>
					</tr>	
					<tr>
						<td width="20%">Procedure Version</td>
						<td width="70%">' + ISNULL(@ProcVersion, '') + '</td> 
					</tr>				
					</table> 
					 </div></div>
					 
			 </body>
			 </html>';
            SET @Step = 'Send';
            SET @ProcedureStep = 'EXEC msdb.dbo.Sp_send_dbmail';

	--------------------------------------
	--EXECUTE Sp_send_dbmail TO SEND MAIL
	---------------------------------------
     IF @DebugFlag > 0
	 SELECT @EMAIL_BODY



         BEGIN TRY
         
		    EXEC msdb.dbo.sp_send_dbmail @profile_name = @EMAIL_PROFILE,
                @recipients = @EMAIL_TO_ADDR	--, @copy_recipients = @EMAIL_CC_ADDR
                , @subject = @EMAIL_SUBJECT, @body = @EMAIL_BODY,
                @body_format = 'HTML',
                @mailitem_id = @EMAIL_MAILITEM_ID OUTPUT;

		
	
		END TRY

	
        
		BEGIN CATCH

		
		DECLARE @ErrorSeverity INT;
            DECLARE @ErrorState INT;
            DECLARE @ErrorNumber INT;
            DECLARE @ErrorLine INT;
            DECLARE @OptionalMessage VARCHAR(MAX);

            SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                    @ErrorSeverity = ERROR_SEVERITY() ,
                    @ErrorState = ERROR_STATE() ,
                    @ErrorNumber = ERROR_NUMBER() ,
                    @ErrorLine = ERROR_LINE() ,
                    @ErrorProcedure = ERROR_PROCEDURE();

		
            IF @DebugFlag > 0
                RAISERROR (
				'ERROR in %s at %s: %s'
				,16
				,1
				,@ErrorProcedure
				,@ProcedureStep
				,@ErrorMessage
				);

          RAISERROR (@ErrorMessage -- Message text.
			,@ErrorSeverity -- Severity.
			,@ErrorState -- State.
			);
		END CATCH
        
   
			

            RETURN 1;

			END
            ELSE 
			PRINT 'Database mail has not setup been setup. Complete the setup to receive notifications by email'
			RETURN 2;

        END TRY

        BEGIN CATCH
            --DECLARE @ErrorSeverity INT;
            --DECLARE @ErrorState INT;
            --DECLARE @ErrorNumber INT;
            --DECLARE @ErrorLine INT;
            --DECLARE @OptionalMessage VARCHAR(MAX);

            SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                    @ErrorSeverity = ERROR_SEVERITY() ,
                    @ErrorState = ERROR_STATE() ,
                    @ErrorNumber = ERROR_NUMBER() ,
                    @ErrorLine = ERROR_LINE() ,
                    @ErrorProcedure = ERROR_PROCEDURE();
			
                  
            RAISERROR (@ErrorMessage -- Message text.
			,@ErrorSeverity -- Severity.
			,@ErrorState -- State.
			);

            RETURN -1;
        END CATCH;

    END;

go
