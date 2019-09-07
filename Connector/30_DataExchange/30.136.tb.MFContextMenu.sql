/*rST**************************************************************************

=============
MFContextMenu
=============

Columns
=======

+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
| Key                                           | Name                   | Data Type       | Max Length (Bytes)   | Nullability    | Identity   | Default   |
+===============================================+========================+=================+======================+================+============+===========+
|  Cluster Primary Key PK\_MFContextMenu: ID    | ID                     | int             | 4                    | NOT NULL       | 1 - 1      |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | ActionName             | varchar(250)    | 250                  | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | Action                 | varchar(1000)   | 1000                 | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | ActionType             | int             | 4                    | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | Message                | varchar(500)    | 500                  | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | SortOrder              | int             | 4                    | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | ParentID               | int             | 4                    | NULL allowed   |            | ((0))     |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | IsProcessRunning       | bit             | 1                    | NULL allowed   |            | ((0))     |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | ISAsync                | bit             | 1                    | NULL allowed   |            | ((0))     |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | UserGroupID            | int             | 4                    | NULL allowed   |            | ((1))     |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | Last\_Executed\_By     | int             | 4                    | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | Last\_Executed\_Date   | datetime        | 8                    | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+
|                                               | ActionUser\_ID         | int             | 4                    | NULL allowed   |            |           |
+-----------------------------------------------+------------------------+-----------------+----------------------+----------------+------------+-----------+

Indexes
=======

+-----------------------------------------------+---------------------+---------------+----------+
| Key                                           | Name                | Key Columns   | Unique   |
+===============================================+=====================+===============+==========+
|  Cluster Primary Key PK\_MFContextMenu: ID    | PK\_MFContextMenu   | ID            | YES      |
+-----------------------------------------------+---------------------+---------------+----------+

Used By
=======

- spMFContextMenuActionItem
- spMFContextMenuHeadingItem
- spmfGetAction
- spMFGetContextMenu
- spMFGetContextMenuID
- spMfGetProcessStatus
- spMFProcessBatch\_EMail
- spMFUpdateCurrentUserIDForAction
- spMFUpdateLastExecutedBy


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

GO


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-09
	Database: 
	Description: Connect menu table 
	Used to set the menu items for the specific application


  USAGE:

  Select * from [dbo].[MFContextMenu]

   DROP TABLE MFContextMenu 
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFContextMenu]';

GO

EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'MFContextMenu', -- nvarchar(100)
    @Object_Release = '3.2.1.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*
MODIFICATIONS

2017-7-16	lc	Set Default user group to 1 (All internal users)
2017-8-22	lc	add columns Last_Excecuted_by, Last_Executed_Date, ActionUser_ID

*/
SET NOCOUNT ON 

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFContextMenu'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN


	CREATE TABLE [dbo].[MFContextMenu](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ActionName] [varchar](250) NULL,
		[Action] [varchar](1000) NULL,
		[ActionType] [int] NULL,
		[Message] [varchar](500) NULL,
		[SortOrder] [int] NULL,
	    [ParentID] [int] NULL DEFAULT (0),
		IsProcessRunning bit default(0),
		ISAsync BIT DEFAULT(0),
		[UserGroupID] [int] DEFAULT (1),
		Last_Executed_By INT null,
		Last_Executed_Date DATETIME null,
		ActionUser_ID INT null

		
	 CONSTRAINT [PK_MFContextMenu] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

END

/*
Modification of ContextMenu table / Migration required for all installations prior to Rel 3.2.1.27
*/

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'UserGroupID' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add [UserGroupID] [int] DEFAULT (1)

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'IsProcessRunning' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add IsProcessRunning bit default(0)

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'ISAsync' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add ISAsync BIT DEFAULT(0)

/*
Modification of ContextMenu table / Migration required for all installations prior to Rel 3.2.1.38
*/

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'Last_Executed_By' AND [c].[TABLE_NAME] = 'MFContextMenu')
Alter table MFCONTEXTMENU ADD Last_Executed_By INT;

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'Last_Executed_Date' AND [c].[TABLE_NAME] = 'MFContextMenu')
Alter table MFCONTEXTMENU ADD Last_Executed_Date DATETIME

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'ActionUser_ID' AND [c].[TABLE_NAME] = 'MFContextMenu')
ALTER TABLE MFCONTEXTmENU ADD  ActionUser_ID INT 


GO

