
/*
Procedure to send bulk emails with attachements
*/

SELECT * FROM [dbo].[MFClass] AS [mc]


EXEC [dbo].[spMFCreateTable]
    @ClassName = 'Contact Person',
    @Debug = 0

	EXEC spmfupdatetable 'MFContactPerson',1

	SELECT * FROM mfcontactperson

SELECT * FROM [dbo].[MFSalesInvoice] AS [msi]



SELECT * FROM [dbo].[MFCustomer] AS [mc]

DECLARE @ViewName NVARCHAR(128) 
DECLARE @Process_ID INT
DECLARE @ProcessBatch_ID INT

DECLARE @filenames NVARCHAR(1000)
DECLARE @FileLocation NVARCHAR(100)
DECLARE @Recipients NVARCHAR(128)

DECLARE @ProfileName NVARCHAR(128)

DECLARE @subject NVARCHAR(128)

DECLARE @body NVARCHAR(128)
DECLARE @file_attachments NVARCHAR(2000)

SET @file_attachments = @FileLocation + '\'+ @filenames


USE msdb
EXEC sp_send_dbmail 
  @profile_name=@ProfileName,
  @recipients=@Recipients,
  @subject=@subject,
  @body=@body,
  @file_attachments=@body

GO

-- End T-SQL