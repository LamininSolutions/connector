/*rST**************************************************************************

============
MFilesEvents
============

Columns
=======

ID 
  Event ID - Primary key
Type 
  Event Type
Category
  Event Category
Timestamp
  Time of event in text format
CausesByUser
  Login Name of user
LoadDate
  Date when event was added to this table
Events
  Details of event in XML format
   
Indexes
=======

idx\_MfilesEvents\_Type
  - Type

  idx\_MfilesEvents\_Category
  - Category

Additional Info
===============

The xml schema of the events will differ for each type and category of events 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-05-06  LC         Add indexes
2019-09-07  JC         Added documentation
2017-05-01  DEV2       Create Table 
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFilesEvents]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFilesEvents', -- nvarchar(100)
    @Object_Release = '4.7.19.59', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

DECLARE @nullable VARCHAR(10)
SELECT @nullable = c.IS_NULLABLE  FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.TABLE_NAME = 'MFilesEvents' AND c.COLUMN_NAME = 'ID'
IF @nullable = 'YES'
BEGIN
 PRINT SPACE(10)+ 'Table Altered';

ALTER TABLE dbo.MFilesEvents 
ALTER COLUMN id Int NOT NULL

END
GO

IF (SELECT c.IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.TABLE_NAME = 'MFilesEvents' AND c.COLUMN_NAME = 'ID') = 'NO' AND NOT EXISTS(SELECT * from sys.objects AS o WHERE type = 'PK' AND o.[parent_object_id] = OBJECT_ID('MFilesEvents'))
Begin

ALTER TABLE [dbo].[MFilesEvents] ADD  CONSTRAINT [PK__MFilesEvents_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,  IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFilesEvents'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

 
CREATE table MFilesEvents ( ID        INT NOT null
,                         [Type]       NVARCHAR(100)
,                         [Category]   NVARCHAR(100)
,                         [TimeStamp]  NVARCHAR(100)
,                         CausedByUser NVARCHAR(100)
,                         LoadDate     DATETIME
,                         [Events]       xml )

ALTER TABLE [dbo].MFilesEvents ADD CONSTRAINT [PK__MFilesEvents_ID] PRIMARY KEY CLUSTERED  ([Id])

END

IF EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFilesEvents'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )



BEGIN
 
 PRINT SPACE(10)+ 'Update Indexes';

 IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_MFilesEvents_Type'
)
CREATE INDEX idx_MFilesEvents_Type ON MFilesEvents(Type);


 IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_MFilesEvents_Category'
)
CREATE INDEX idx_MFilesEvents_Category ON MFilesEvents(Category);


END


GO

