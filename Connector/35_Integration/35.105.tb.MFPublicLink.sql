/*rST**************************************************************************

============
MFPublicLink
============

Columns
=======

Id int (primarykey, not null)
  fixme description
ObjectID int
  fixme description
ClassID int
  fixme description
ExpiryDate datetime
  fixme description
AccessKey nvarchar(4000)
  fixme description
Link nvarchar(4000)
  fixme description
HtmlLink nvarchar(4000)
  fixme description
DateCreated datetime
  fixme description
DateModified datetime
  fixme description

Used By
=======

- spMFCreatePublicSharedLink


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
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
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: MFiles Public Share Link
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFPublicLink
  
-----------------------------------------------------------------------------------------------*/


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
			[DateModified] [datetime] NULL,
		PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]



        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';