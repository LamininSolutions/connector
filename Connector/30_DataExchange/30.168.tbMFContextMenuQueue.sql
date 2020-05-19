/*rST**************************************************************************

==================
MFContextMenuQueue
==================

The queue table is specifically designed to manage update calls from M-Files to SQL using context menu action type 5. Queue control should be put in place where users can update multiple objects in M-Files and a event handler with action type 5 fires multiple consecutive updates to SQL.

Columns
=======
The rows for this table is inserted from your custom contextmenu procedure

example xx illustrates how the functionality is built into the custom procedure.

Additional Info
===============

Indexes
=======

idx\_ContextMenuQueue\_ObjType\_ObjID
  - ObjectType
  - ObjID
idx\_ContextMenuQueue\_Class\_Objid
  - Class
  - ObjID

Foreign Keys
============

Uses
====

MFContextMenuQueue

Used By
=======

spmfUpdateContextMenuQueue
custom procedures

Examples
========

.. code:: sql

    Select * from MFContextMenuQueue

	SELECT mot.name AS objecttype, mc.name AS Class, mcmq.ObjectID,mcmq.ObjectVer 
    FROM dbo.MFContextMenuQueue AS mcmq
    INNER JOIN dbo.MFClass AS mc
    ON mcmq.classID = mc.MFID
    INNER JOIN dbo.MFObjectType AS mot
    ON mot.MFID = mcmq.ObjectType

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-04-22  LC         Add naming for primary key
2020-03-18  LC         Add indexes
2019-12-06  LC         Create Table
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFContextMenuQueue]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFContextMenuQueue', -- nvarchar(100)
    @Object_Release = '4.4.14.55', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

GO
IF NOT EXISTS (	  SELECT	[name]
				  FROM		[sys].[tables]
				  WHERE		[name] = 'MFContextMenuQueue'
							AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN
		CREATE  TABLE dbo.MFContextMenuQueue
(
    id INT IDENTITY,
    ContextMenu_ID INT NOT null,
    ObjectID INT ,
    ObjectType INT,
    ObjectVer INT,
    ClassID INT,
    Status INT,
	ProcessBatch_ID INT,
	UpdateID INT,
	UpdateCycle INT,
    CreatedOn DATETIME DEFAULT (GETDATE()),
	LastUpdated datetime DEFAULT (GETDATE())
);

ALTER TABLE [dbo].[MFContextMenuQueue] ADD CONSTRAINT [PK__MFContextMenuQueue_ID] PRIMARY KEY CLUSTERED  ([id])



CREATE INDEX idx_ContextMenuQueue_ObjType_ObjectID ON MFContextMenuQueue(ObjectType, [ObjectID])
CREATE INDEX idx_ContextMenuQueue_Class_ObjectID ON MFContextMenuQueue(ClassID, [ObjectID])

END

GO
