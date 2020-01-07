
/*rST**************************************************************************

==============
MFUserMessages
==============

Description
===========

The MFUserMessages is a standard class table automatically created on installation of the package.  The table is used to update user messages automatically when the system is configured for this functionality.

Refer to `user messages <https://doc.lamininsolutions.com/mfsql-connector/mfsql-integration-connector/user-messages/index.html>`_ for more detail

Columns
=======

   MFSQL Class Table   
   MFSQL Count         
   MFSQL Message       
   MFSQL Process Batch
   MFSQL User         
   Name or title      


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
2017-10-10  LC         Create functionality
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserMessages]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserMessages', -- nvarchar(100)
    @Object_Release = '4.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserMessages'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
						BEGIN
                        
						DROP TABLE MFUserMessages;

						END;

    BEGIN

CREATE TABLE [dbo].[MFUserMessages](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[GUID] [NVARCHAR](100) NULL,
	[MX_User_ID] [UNIQUEIDENTIFIER] NULL,
	[Class] [NVARCHAR](100) NULL,
	[Class_ID] [INT] NOT NULL,
	[Created] [DATETIME] NULL,
	[Created_by] [NVARCHAR](100) NULL,
	[Created_by_ID] [INT] NULL,
	[MF_Last_Modified] [DATETIME] NULL,
	[MF_Last_Modified_by] [NVARCHAR](100) NULL,
	[MF_Last_Modified_by_ID] [INT] NULL,
	[Mfsql_Class_Table] [NVARCHAR](100) NULL,
	[Mfsql_Count] INT NULL,
	[Mfsql_Message] [NVARCHAR](4000) NULL,
	[Mfsql_Process_Batch] [INT] NULL,
	[Mfsql_User] [NVARCHAR](100) NULL,
	[Mfsql_User_ID] [INT] NULL,
	[Name_Or_Title] [NVARCHAR](100) NULL,
	[Single_File] [BIT] NOT NULL,
	[Workflow] [NVARCHAR](100) NULL,
	[Workflow_ID] [INT] NULL,
	[State] [NVARCHAR](100) NULL,
	[State_ID] [INT] NULL,
	[LastModified] [DATETIME] NULL,
	[Process_ID] [INT] NULL,
	[ObjID] [INT] NULL,
	[ExternalID] [NVARCHAR](100) NULL,
	[MFVersion] [INT] NULL,
	[FileCount] [INT] NULL,
	[Deleted] [BIT] NULL,
	[Update_ID] [INT] NULL,
 CONSTRAINT [pk_MFUserMessagesID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Class_MFUserMessages]  DEFAULT ((-1)) FOR [Class_ID]


ALTER TABLE [dbo].[MFUserMessages] ADD  DEFAULT ((0)) FOR [Single_File]


ALTER TABLE [dbo].[MFUserMessages] ADD  DEFAULT (GETDATE()) FOR [LastModified]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Process_id_MFUserMessages]  DEFAULT ((1)) FOR [Process_ID]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_FileCount_MFUserMessages]  DEFAULT ((0)) FOR [FileCount]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Deleted_MFUserMessages]  DEFAULT ((0)) FOR [Deleted]


END

GO

