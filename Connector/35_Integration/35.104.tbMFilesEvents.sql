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
    @Object_Release = '4.7.18.58', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFilesEvents'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

 
IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFilesEvents'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

CREATE table MFilesEvents ( ID        INT NOT null
,                         [Type]       NVARCHAR(100)
,                         [Category]   NVARCHAR(100)
,                         [TimeStamp]  NVARCHAR(100)
,                         CausedByUser NVARCHAR(100)
,                         loaddate     DATETIME
,                         [Events]       xml )

ALTER TABLE [dbo].MFilesEvents ADD CONSTRAINT [PK__MFilesEvents_ID] PRIMARY KEY CLUSTERED  ([Id])

END


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

