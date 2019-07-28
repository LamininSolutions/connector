
/*
Example to send emails with attachements
*/

DECLARE
--@MFTableName NVARCHAR(100), -- this is the class table with the attachement
@subject NVARCHAR(128) = 'Test Attachment',
@body NVARCHAR(128) = 'Your Invoice',
@Process_ID INT = 1, -- filter the attachements to be sent by email
@ProcessBatch_ID INT = NULL,
@Debug SMALLINT = 1


DECLARE @filenames NVARCHAR(1000)
DECLARE @FileLocation NVARCHAR(100)
DECLARE @Recipients NVARCHAR(128)
DECLARE @ProfileName NVARCHAR(128) 
DECLARE @ID int
SELECT @ProfileName = CAST(value AS NVARCHAR(100)) FROM mfsettings WHERE name = 'SupportEmailProfile'

	-------------------------------------------------------------
    -- Create attachments
    -------------------------------------------------------------
UPDATE si
	SET [Process_ID] = @Process_ID
	FROM  mfsalesinvoice si
	 WHERE [FileCount] > 0 AND [Document_Date] = '2007-03-01'
	
EXEC [dbo].[spMFExportFiles]
    @TableName = 'MFSalesInvoice',
    @PathProperty_L1 = null,
    @PathProperty_L2 = null,
    @PathProperty_L3 = null,
    @IncludeDocID = 0,
    @Process_id = @Process_ID,
    @ProcessBatch_ID = @ProcessBatch_ID,
    @Debug = 0

		-------------------------------------------------------------
	    -- Prepare emaillist
	    -------------------------------------------------------------
CREATE TABLE #TempEmailList
(id INT IDENTITY, Recipients NVARCHAR(250), FileLocation NVARCHAR(4000))

INSERT INTO [#TempEmailList]
    (
        [Recipients],
        [FileLocation]
    )

SELECT 
   
	
	[mcp].[Email_Address]  ,
	
    [mefh].[FileExportRoot] + CASE
                                  WHEN [mefh].[SubFolder_1]  != ''
                                      THEN [mefh].[SubFolder_1] + '\'
                                  ELSE
                                      ''
                              END + CASE
                                        WHEN [mefh].[SubFolder_2] != ''
                                            THEN [mefh].[SubFolder_2] + '\'
                                        ELSE
                                            ''
                                    END + CASE
                                              WHEN [mefh].[SubFolder_3] != ''
                                                  THEN [mefh].[SubFolder_3] + '\'
                                              ELSE
                                                  ''
                                          END + [mefh].[FileName]
--, [mefh].*
FROM
[dbo].[MFContactPerson] AS [mcp]
INNER JOIN [dbo].[MFCustomer] AS [mc]
ON mcp.[Owner_Customer_ID] = mc.objid
INNER JOIN [dbo].[MFSalesInvoice]          AS [msi]
ON msi.[Customer_ID] = mc.objid
    inner JOIN
        [dbo].[MFExportFileHistory] AS [mefh]
            ON [msi].[ObjID] = [mefh].[ObjID]
               AND [mefh].[ClassID] = [msi].[Class_ID]
			   WHERE [mcp].[Email_Address] IS NOT NULL
 
 IF @Debug > 0
 Begin
 UPDATE [#TempEmailList]
 SET [Recipients] = 'support@lamininsolutions.com'
 WHERE [Recipients] <>  'Support@lamininsolutions.com' 
 end

 	-------------------------------------------------------------
     -- Send emails
     ------------------------------------------------------------- 
WHILE EXISTS(SELECT id FROM [#TempEmailList] AS [tel]) 	 
BEGIN
SELECT @ID = MIN(ID) FROM [#TempEmailList] AS [tel]             
SELECT @Recipients = recipients, @FileLocation = [tel].[FileLocation] FROM [#TempEmailList] AS [tel]
WHERE id = @ID
EXEC msdb..sp_send_dbmail 
  @profile_name=@ProfileName,
  @recipients=@Recipients,
  @subject=@subject,
  @body=@body,
  @file_attachments=@FileLocation

DELETE FROM [#TempEmailList] WHERE id = @ID

END

DROP table [#TempEmailList]
GO

