/*rST**************************************************************************

==================
MFEventLog_OpenXML
==================

Columns
=======

Id int (primarykey, not null)
  fixme description
XMLData xml
  fixme description
LoadedDateTime datetime
  fixme description

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
/*------------------------------------------------------------------------------------------------
	Author: DEvTeam2, Laminin Solutions
	Create date: 2017-01
	Database: 
	Description: MFiles Event Log
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
  Select * from MFEventLog_OpenXML
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFEventLog_OpenXML'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE MFEventLog_OpenXML
		(
		Id INT IDENTITY PRIMARY KEY,
		XMLData XML,
		LoadedDateTime DATETIME
		)

--	DROP TABLE MFilesEvents
CREATE table MFilesEvents ( ID           INT
,                         [Type]       NVARCHAR(100)
,                         [Category]   NVARCHAR(100)
,                         [TimeStamp]  NVARCHAR(100)
,                         CausedByUser NVARCHAR(100)
,                         loaddate     DATETIME
,                         Events       xml )

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

