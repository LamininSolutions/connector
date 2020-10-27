/*rST**************************************************************************

============
MFPublicLink
============

Columns
=======

Id int (primarykey, not null)
  SQL Primary Key
ObjectID int
  - ObjID column of the Record
  - Use the combination of objid and class_ID to join this record to the class table
ClassID int
  Class_ID of the Record
ExpiryDate datetime
  Expiredate used in Access Key
AccessKey nvarchar(4000)
  Unique key generated by M-Files using the Assembly
Link nvarchar(4000)
  Constructed link
HtmlLink nvarchar(4000)
  HTML constructed link to be used in emails. The name of the document is used as the friendly name of the link
DateCreated datetime
  Date item was created
DateModified datetime
  Date item was last udated

Used By
=======

- spMFCreatePublicSharedLink

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
2016-04-10  LC         Create table
==========  =========  ========================================================

**rST*************************************************************************/

go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFPublicLink]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFPublicLink', -- nvarchar(100)
    @Object_Release = '3.1.1.34', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFPublicLink'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        
		CREATE TABLE [dbo].[MFPublicLink]
		(
			[Id] [int] IDENTITY(1,1) NOT NULL,
			[ObjectID] [int] NULL,
			[ClassID] [int] NULL,
			[ExpiryDate] [datetime] NULL,
			[AccessKey] [nvarchar](4000) NULL,
			[Link] [nvarchar](4000) NULL,
			[HtmlLink] [nvarchar](4000) NULL,
			[DateCreated] [datetime] NULL,
			[DateModified] [datetime] NULL
	)

        ALTER TABLE [dbo].[MFPublicLink] ADD CONSTRAINT [PK__MFPublicLink_ID] PRIMARY KEY CLUSTERED  ([Id])


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';