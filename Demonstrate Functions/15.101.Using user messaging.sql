
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
USER MESSAGING
*/
/*
--custom procedure is executed from the Context menu. example is executing it from SSMS, but it can also be executed from within M-Files.
*/
DECLARE
    @ProcessBatch_ID INT,
    @Output          NVARCHAR(1000);
EXEC [Custom].[DoCMAsyncAction]
    @ID = 20,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Output = @Output OUTPUT,
    @WriteToMFiles = 1,
    @Debug = 0;

SELECT
    @ProcessBatch_ID AS [ProcessBatch_ID];
SELECT
    @Output AS [outputmessage]; --output message is only produced with sync procedures

--Note that a user message was automatically created in table MFUserTable
SELECT
    *
FROM
    [dbo].[MFUserMessages] AS [mum]
WHERE
    [mum].[ProcessBatch_ID] = 1330;
--Update Class Table: Completed Class Name: Customer #Records: 1 #Updated: 1 Process Batch#: 1330 Started On: Aug 31 2017  7:59PM Duration: 00:00:01

--this automation is based on the executing spMFProcessBatch_Upsert with a processtype of 'Message'. A trigger in this the ProcessBatch Table inserts the message in the userMessage table.

EXEC [dbo].[spMFInsertUserMessage]
    @ProcessBatch_ID = 1330;

--the following procedure can be used to generate user messages for different layouts
DECLARE
    @MessageOUT          NVARCHAR(4000),
    @MessageForMFilesOUT NVARCHAR(4000),
    @EMailHTMLBodyOUT    NVARCHAR(MAX);
EXEC [dbo].[spMFResultMessageForUI]
    @Processbatch_ID = 1330,
    @MessageOUT = @MessageOUT OUTPUT,
    @MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT,
    @GetEmailContent = 1,
    @EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT;

SELECT
    @MessageOUT AS [MessageOUT];
-- 
/*
Update Class Table: Completed\nClass Name: Customer\n#Records: 1\n#Updated: 1\nProcess Batch#: 1330\nStarted On: Aug 31 2017  7:59PM\nDuration: 00:00:01
*/
SELECT
    @MessageForMFilesOUT AS [MessageForMFilesOUT];
/*
Update Class Table: Completed Class Name: Customer #Records: 1 #Updated: 1 Process Batch#: 1330 Started On: Aug 31 2017  7:59PM Duration: 00:00:01
*/
SELECT
    @EMailHTMLBodyOUT AS [EMailHTMLBodyOUT];
/*
<html>  <head>   <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />   <style type="text/css">    div {line-height: 100%;}      body {-webkit-text-size-adjust:none;-ms-text-size-adjust:none;margin:0;padding:0;}     body, #body_style {min-height:1000px;font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;}    p {margin:0; padding:0; margin-bottom:0;}    h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}      table {     border-collapse: collapse;          border: 1px solid #3399FF;          font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;          color: black;        padding:5;        border-spacing:1;        border:0;       }    table caption {font-weight: bold;color: blue;}    table td, table th, table tr,table caption { border: 1px solid #eaeaea;border-collapse:collapse;vertical-align: top; }    table th {font-weight: bold;font-variant: small-caps;background-color: blue;color: white;vertical-align: bottom;}   </style>  </head>     <body><div id="body_style" ><table><th>M-Files Vault: MFSQL_Samplevault_32138</th><tr><td>Update Class Table: Completed</td></tr><tr><td>Class Name: Customer</td></tr><tr><td>#Records: 1</td></tr><tr><td>#Updated: 1</td></tr><tr><td>Process Batch#: 1330</td></tr><tr><td>Started On: Aug 31 2017  7:59PM</td></tr><tr><td>Duration: 00:00:01</td></tr></table></div></body></html>
*/

/*
The email can be produced by applying the context menu and the processbatch_ID of the process.
*/
SELECT MAX([mpb].[ProcessBatch_ID]) AS ProcessBatch_ID FROM [dbo].[MFProcessBatch] AS [mpb] 


DECLARE @RecipientEmail NVARCHAR(100);
DECLARE @RecipientFromMFSettingName NVARCHAR(100);


DECLARE @ContextMenu_ID INT;
SELECT
    @ContextMenu_ID = [ID]
FROM
    [MFContextMenu]
WHERE
    [ActionName] = 'Action Type 1 Async';

SELECT
    @RecipientEmail = [mla].[EmailAddress]
FROM
    [dbo].[MFContextMenu]      AS [mcm]
    INNER JOIN
        [dbo].[MFLoginAccount] AS [mla]
            ON [mcm].[Last_Executed_By] = [mla].[MFID]
WHERE
    [mcm].[ID] = @ContextMenu_ID;

SELECT @RecipientFromMFSettingName = CAST([value] as nvarchar(100)) FROM [dbo].[MFSettings] AS [ms]
WHERE name = 'SupportEmailRecipient'


EXEC [dbo].[spMFProcessBatch_EMail]
    @ProcessBatch_ID = 1565,
    @RecipientEmail = @RecipientEmail,
    @RecipientFromMFSettingName = @RecipientFromMFSettingName,
    @ContextMenu_ID = @ContextMenu_ID,
    @Debug = 1;

--	SELECT TOP 2 * FROM msdb.[dbo].[sysmail_mailitems] AS [sm] ORDER BY [sm].[mailitem_id] desc

-------------------------------------------------------------
-- EXAMPLE PROCEDURE TO SEND ASYNC EMAIL
-- this example is dependend on MFSQL Context Menu with sample scripts being installed
-------------------------------------------------------------

DECLARE
    @ProcessBatch_ID INT,
    @Output          NVARCHAR(1000),
    @ID              INT;
SET @ID =
    (
        SELECT
            [ID]
        FROM
            [MFContextMenu] AS [cm]
        WHERE
            [Action] = 'custom.DoCMAsyncAction'
    );
EXEC [Custom].[DoCMAsyncAction]
    @ID = @ID,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
    @Output = @Output OUTPUT,                   -- nvarchar(1000)
    @WriteToMFiles = 1,                         -- bit
    @Debug = 0;                                 -- smallint

SELECT
    @Output;
SELECT
    *
FROM
    [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE
    [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;

GO

-------------------------------------------------------------
-- LOGGING AND MESSAGES - backtrack from MFSQL Process Batch in M-Files
-------------------------------------------------------------

SELECT
    [MFSQL_Process_Batch],
    [Update_ID],
    *
FROM
    [mfcustomer]
WHERE
    [mfsql_process_batch] IS NOT NULL;

-- Show UpdateHistory:  note the update_id and MFSQL_Process_Batch for a record from the above select and replace it in the parameter
-- Execute from here
DECLARE @Update_ID INT = 6;
DECLARE @ProcessBatch_ID INT = 19;

SELECT
    *
FROM
    [MFUpdateHistory]
WHERE
    [Id] = @Update_ID;

EXEC [dbo].[spMFUpdateHistoryShow]
    @Update_ID = @Update_ID, -- int
    @IsSummary = 1,          -- smallint
    @UpdateColumn = 0,       -- int
    @Debug = 0;              -- smallint

EXEC [dbo].[spMFUpdateHistoryShow]
    @Update_ID = @Update_ID, -- int
    @IsSummary = 0,          -- smallint
    @UpdateColumn = 7,       -- int
    @Debug = 0;              -- smallint

EXEC [dbo].[spMFUpdateHistoryShow]
    @Update_ID = @Update_ID, -- int
    @IsSummary = 0,          -- smallint
    @UpdateColumn = 3,       -- int
    @Debug = 0;              -- smallint

--show batch Process result

SELECT
    *
FROM
    [MFProcessBatch]
WHERE
    [ProcessBatch_ID] = @ProcessBatch_ID;

--show process batch detail

SELECT
    *
FROM
    [MFProcessBatchDetail]
WHERE
    [ProcessBatch_ID] = @ProcessBatch_ID;

--show process message for User

SELECT
    *
FROM
    [dbo].[MFUserMessages] AS [mum]
WHERE
    [ProcessBatch_ID] = 1143;

--End Here

/*
UPDATE Class Table: Completed 
Class Name: Customer 
#Records: 1 #Updated: 1 
Process Batch#: 1143 
Started On: Aug 24 2017  7:59PM Duration: 00:00:02
*/

GO

