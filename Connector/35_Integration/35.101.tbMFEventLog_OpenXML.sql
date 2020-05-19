/*rST**************************************************************************

==================
MFEventLog_OpenXML
==================

Columns
=======

Id int (primarykey, not null)
  SQL primary key
XMLData xml
  Event log data
LoadedDateTime datetime
  Time of saving event log

Additional Info
===============

The event log is XML format in the MFEventLog_OpenXML table by executing the spMFGetMFilesLog procedure.

Used By
=======

- spMFGetMfilesLog


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFEventLog_OpenXML]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFEventLog_OpenXML', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFEventLog_OpenXML'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE MFEventLog_OpenXML
		(
		Id INT IDENTITY,
		XMLData XML,
		LoadedDateTime DATETIME
		)

ALTER TABLE [dbo].[MFEventLog_OpenXML] ADD CONSTRAINT [PK__MFEventLog_OpenXML_ID] PRIMARY KEY CLUSTERED  ([Id])



        PRINT SPACE(10) + '... Table: created';
END


ELSE
    PRINT SPACE(10) + '... Table: exists';

