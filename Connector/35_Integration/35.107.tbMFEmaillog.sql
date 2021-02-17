

/*
CREATE EMAIL LOG TABLE




*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*rST**************************************************************************
==========
MFEmailLog
==========

Description
===========

This is a logging table to log emails sent. It is used in conjunction with spMPrepareTemplatedEmail

The log table have a row for each email sent showing if the email was send successfully.


Columns
=======

ID int identity NOT NULL
  row id
Document_ID int not null. 
  Defined in the custom.DoChannelEmail procedure and represents the unique reference to the specific object that drives the email.
Template_ID int NULL
  Id of template
msdb_mailitem_id int NULL
  id if msdb mail system 
Email_Date datetime NULL
  date if email
Email_Status nvarchar(100) NULL
  status of sending email
Body nvarchar(max) NULL
  body of email sent out
Recipient nvarchar(256) NULL
  recipient of email

The columns: Email_Date, Email_status, Body, Recipient are all inserted during processing to log the sending of the email.

Additional Info
===============

This table is useful when preventing a recipient to recieve multiple emails for the same template.
Delete the row if the same email must be resend to the recipient.
Delete from custom.emaillog where template_id = 1 and document_id = 30021

Drop table custom.emaillog

Used By
=======

spMFPrepareTemplatedEmail

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-26  LC         Table designed
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.MFEmailLog';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFEmailLog', -- nvarchar(100)
    @Object_Release = '4.9.25.67', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS (SELECT name FROM sys.tables WHERE name='MFEmailLog' AND SCHEMA_NAME(schema_id)='dbo')
 BEGIN

CREATE TABLE [dbo].[MFEmailLog](
	[ID] [int] identity NOT NULL,
	document_ID int not null,
    Template_ID int NULL,
	[msdb_mailitem_id] [int] NULL,
	[Email_Date] [datetime] NULL,
	[Email_Status] [nvarchar](100) NULL,
	[Body] [nvarchar](max) NULL,
	[Recipient] [nvarchar](256) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

END

GO

