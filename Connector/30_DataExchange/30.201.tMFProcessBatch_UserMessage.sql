PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'tMFProcessBatch_UserMessage';
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
(
    SELECT *
    FROM [sys].[objects]
    WHERE [type] = 'TR'
          AND [name] = 'tMFProcessBatch_UserMessage'
)
BEGIN
    DROP TRIGGER [dbo].[tMFProcessBatch_UserMessage];

    PRINT SPACE(10) + '...Trigger dropped and recreated';
END;
GO

CREATE TRIGGER [dbo].[tMFProcessBatch_UserMessage]
ON [dbo].[MFProcessBatch]
FOR UPDATE
AS
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-03
	Database: 
	Description: Create User Message in MFUserMessages table where LogType = Message
						
				 Executed when ever [LogType] is updated in [MFProcessBatch]
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2018-11-16		LC			Add test to check for @Usermessageenabled, remove @class param
	2018-11-16		LC			Add error trappaing and reporting
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  update MFProcessBatch set LogType = 'Message' where ProcessBatch_ID = 25
  select * from mfusermessages where MFSQL_Process_batch = 25
  
-----------------------------------------------------------------------------------------------*/
DECLARE @result             INT
       ,@LogType            NVARCHAR(100)
       ,@ProcessBatch_ID    INT
       ,@UserMessageEnabled INT;
DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.tMFProcessBatch_UserMessage';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) 
		DECLARE @LogTypeDetail AS NVARCHAR(50) 
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @StartTime AS DATETIME = GETUTCDATE();

IF UPDATE([LogType])
--BEGIN try
Begin
    SELECT @LogType         = [Inserted].[LogType]
          ,@ProcessBatch_ID = [Inserted].[ProcessBatch_ID]
    FROM [Inserted];

    IF @LogType = 'Message' OR @logtype = 'END'
    BEGIN
        SELECT @UserMessageEnabled = CAST(ISNULL([ms].[Value],0) AS INT)
        FROM [dbo].[MFSettings] AS [ms]
        WHERE [ms].[Name] = 'MFUserMessagesEnabled';

		IF @UserMessageEnabled =1
		Begin
        EXEC  [dbo].[spMFInsertUserMessage] @ProcessBatch_ID = @ProcessBatch_ID
                                                    ,@UserMessageEnabled = @UserMessageEnabled
                                                    ,@Debug = 0;
		        
       
		END --usermessageenabled = 1
    END; --logtype message
	END --logtype updated

GO