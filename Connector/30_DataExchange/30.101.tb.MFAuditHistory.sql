/*rST**************************************************************************

==============
MFAuditHistory
==============

Columns
=======

ID int (primarykey, not null)
  fixme description
RecID int
  fixme description
SessionID int
  fixme description
TranDate datetime
  fixme description
ObjectType int
  fixme description
Class int
  fixme description
ObjID int
  fixme description
MFVersion smallint
  fixme description
StatusFlag smallint
  fixme description
StatusName varchar(100)
  fixme description
UpdateFlag int
  fixme description

Indexes
=======

idx\_AuditHistory\_ObjType\_ObjID
  - ObjectType
  - ObjID
idx\_AuditHistory\_Class\_Flag
  - Class
  - ObjID

Used By
=======

- MFvwAuditSummary
- MFvwLogTableStats
- spMFClassTableStats
- spMFDeleteHistory
- spMFLogTableStats
- spMFTableAudit
- spMFUpdateItemByItem
- spMFUpdateMFilesToMFSQL
- spMFUpdateTable
- spMFUpdateTableinBatches


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-05
	Database: 
	Description: Audit history of comparison between M-Files and SQL
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
  Select * from MFAuditHistory
  drop table mfaudithistory
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuditHistory]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuditHistory', -- nvarchar(100)
    @Object_Release = '2.0.2.5', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAuditHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

CREATE TABLE MFAuditHistory
(ID INT IDENTITY PRIMARY KEY ,
RecID INT,
SessionID INT,
TranDate DATETIME,
ObjectType INT,
Class INT,
[ObjID] INT,
MFVersion smallint,
StatusFlag SMALLINT,
StatusName VARCHAR(100),
UpdateFlag int
)

CREATE INDEX idx_AuditHistory_ObjType_ObjID ON MFAuditHistory(ObjectType, [ObjID])
CREATE INDEX idx_AuditHistory_Class_Flag ON MFAuditHistory(Class, [ObjID])

END

GO

