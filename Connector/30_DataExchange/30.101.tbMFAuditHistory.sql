/*rST**************************************************************************

==============
MFAuditHistory
==============

Columns
=======

ID int (primarykey, not null)
  identity int for records in the table
RecID int
  the id of the record in the class table. if null then the record was not yet in the table when the session was processed
SessionID int
   sequential number for the session. Each update for a specific class is regarded as a session. Only records that was updated/inserted show toe latest session id 
TranDate datetime
  date that the session was processed
ObjectType int
  MFID of the ObjectType of the class
Class int
  MFID of the Class
ObjID int
  Objid of the record from the Objver of the object in M-Files
MFVersion smallint
  the version from the Objver when the object was processed
StatusFlag smallint
  the status flag integer is between 1 and 7
StatusName varchar(100)
  Description of status
UpdateFlag int
  this is the update status of spmfupdatetable when Flag spmfupdateitembyitem is processed

Indexes
=======

idx\_AuditHistory\_ObjType\_ObjID
  - ObjectType
  - ObjID
  
idx\_AuditHistory\_Class\_Objid
  - Class
  - ObjID
  
idx\_AuditHistory\_Class\_StatusFlag
  - Class
  - StatusFlag

Additional Info
===============

The status flag indicates:
 - 0 the record MFversion in M-Files and SQL is identical Flag
 - 1 the record MFversion in M-Files is higher than SQL. This indicates a need for updating from Mfiles to SQL 
 - 2 the SQL version is later than the M-Files version (usually signalling a syncronisation error) 
 - 3 the record in SQL is flagged as deleted in SQL and does not exist in M-Files
 - 4 the record is not in M-Files and the record flag in SQL is not deleted. This usually indicate that the routine for deleting records have not yet been processed.
 - 5 when there is no record in SQL for an objver in M-Files. This usually indicate that the records was created in M-Files and that the update routine has not yet been run. This may indicate a need for updating from Mfiles to SQL Note that all templates in M-Files will also show as statusflag 5 as templates are not inserted into SQL. Execute spmfUpdateTable to move the template objects to statusflag 6. 
 - 6 the Record is a template. This status flag is update by spmfUpdateTable.
 - 7 The record in SQL is marked as deleted but the record exist in M-Files (likely to have been undeleted.

Note that the records in this table is not automatically deleted. It is
recommended that agent is used to delete old records in the table if
they are no longer required.

The following procedures do updates to this table
- :doc:`/procedures/spMFTableAudit/` 
- :doc:`/procedures/spMFObjectTypeUpdateClassIndex/`
- :doc:`/procedures/spMFUpdateTable/`

The following special views relate to this table
- :doc:`/views/MFvwObjectTypeSummary/`
- :doc:`/views/MFvwAuditSummary/`

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-07-12  LC         Increase size of mfversion column to int
2020-09-02  LC         Add unique index objectype, class, objid
2020-04-16  LC         Add index Class_StatusFlag
2020-03-18  LC         Change name of index Class_Objid
2019-09-07  JC         Added documentation
2016-05-01  DEV2       Create Table 
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuditHistory]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuditHistory', -- nvarchar(100)
    @Object_Release = '4.10.32.77', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAuditHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

CREATE TABLE MFAuditHistory
(ID INT IDENTITY ,
RecID INT,
SessionID INT,
TranDate DATETIME,
ObjectType INT,
Class INT,
[ObjID] INT,
MFVersion int,
StatusFlag SMALLINT,
StatusName VARCHAR(100),
UpdateFlag int
)

ALTER TABLE [dbo].[MFAuditHistory] ADD CONSTRAINT [PK__MFAuditHIstory_ID] PRIMARY KEY CLUSTERED  ([ID])


END


BEGIN
 
 PRINT SPACE(10)+ 'Update Indexes';

 IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_AuditHistory_ObjType_ObjID'
)
CREATE INDEX idx_AuditHistory_ObjType_ObjID ON MFAuditHistory(ObjectType, [ObjID]);


 IF EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_AuditHistory_Class_Objid'
)
DROP INDEX idx_AuditHistory_Class_Objid ON dbo.MFAuditHistory;


 IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_AuditHistory_ObjType_Class_Objid'
)
CREATE UNIQUE INDEX idx_AuditHistory_ObjType_Class_Objid ON MFAuditHistory(ObjectType, Class, [ObjID]);

 IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_AuditHistory_Class_StatusFlag'
)
CREATE INDEX idx_AuditHistory_Class_StatusFlag ON MFAuditHistory(Class, StatusFlag);


if exists (select 1 from INFORMATION_SCHEMA.columns where COLUMN_NAME = 'MFversion' and TABLE_NAME = 'MFAuditHistory' and DATA_TYPE = 'smallint')
alter table MFAuditHistory
alter column MFVersion int;

end


GO


