if exists (
    select * from tempdb.dbo.sysobjects o
    where o.xtype in ('U')
  and o.id = object_id(N'tempdb..#MFContextMenu'))

  DROP TABLE #ContextMenu

  GO

if exists (
    select * from tempdb.dbo.sysobjects o
    where o.xtype in ('U')
  and o.id = object_id(N'tempdb..#MFContextMenu_Backup'))

  DROP TABLE #ContextMenu_Backup

   SELECT * INTO #ContextMenu_Backup FROM MFContextMenu

GO


CREATE TABLE #MFContextMenu
    (
      [ID] [INT] IDENTITY(1, 1)
                 NOT NULL ,
      [ActionName] [VARCHAR](250) NULL ,
      [Action] [VARCHAR](1000) NULL ,
      [ActionType] [INT] NULL ,
      [Message] [VARCHAR](500) NULL ,
      [SortOrder] [INT] NULL ,
      [ParentID] [INT] NULL ,
      [IsProcessRunning] [BIT] NULL ,
      [ISAsync] [BIT] NULL,
	  [UserGroupID] [int] NULL
    );


/*
Insert Menu headings
*/


DECLARE @Heading_1_ID INT;
DECLARE @Heading_2_ID INT;
DECLARE @Heading_3_ID INT;
DECLARE @Heading_4_ID INT;
DECLARE @Heading_5_ID INT;


INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [ActionType] ,
          [SortOrder] ,
          [ParentID]
        )
		
VALUES  ( 'Synchronous Actions' -- Name of heading
          ,
          0 -- set to 0 for task bar menu
          ,
          1 -- this is the sort order for the menu groups. mulitple heading order of display
          ,
          0 -- always set to 0
        );

SET @Heading_1_ID = @@IDENTITY;

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [ActionType] ,
          [SortOrder] ,
          [ParentID]
        )
VALUES  ( 'Asynchronous Actions' -- Name of heading
          ,
          0 -- set to 0 for task bar menu
          ,
          2 -- this is the sort order for the menu groups. mulitple heading order of display
          ,
          0 -- always set to 0
        );

SET @Heading_2_ID = @@IDENTITY;

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [ActionType] ,
          [SortOrder] ,
          [ParentID]
        )
VALUES  ( 'Web Sites' -- Name of heading
          ,
          0 -- set to 0 for task bar menu
          ,
          3 -- this is the sort order for the menu groups
          ,
          0 -- always set to 0
        );SET @Heading_3_ID = @@IDENTITY;

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [ActionType] ,
          [SortOrder] ,
          [ParentID]
        )
VALUES  ( 'Synchronous Object Actions' -- Name of heading
          ,
          3 -- set to 3 to object action
          ,
          1 -- this is the sort order for the menu groups. mulitple heading order of display
          ,
          0 -- always set to 0
        );

SET @Heading_4_ID = @@IDENTITY;

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [ActionType] ,
          [SortOrder] ,
          [ParentID]
        )
VALUES  ( 'Asynchronous Object Actions' -- Name of heading
          ,
          3 -- set to 3 to object action
          ,
          2 -- this is the sort order for the menu groups. mulitple heading order of display
          ,
          0 -- always set to 0
        );

SET @Heading_5_ID = @@IDENTITY;


INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [Message] ,
          [SortOrder] ,
          [ParentID]
		 )
VALUES  ( 'Google website ActionType 2' ,
          'http://google.com' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          2 -- Action Type for website
          ,
          'Access to website' ,
          1 -- this is the sort order for the menu items in the group
          ,
          @Heading_3_ID -- this is the record ID of the group heading for this item
		
        );

		INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [Message] ,
          [SortOrder] ,
          [ParentID] ,
          [ISAsync]
        )
VALUES  ( 'Action Type 1 Sync' ,
          'custom.DoCMAction' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          1 -- Action without object parameters
          ,
          'Action the custom.DoCMAction Procedure syncronously with feedback message' ,
          1 -- this is the sort order for the menu items in the group
          ,
          @Heading_1_ID -- this is the record ID of the group heading for this item
          ,
          0 -- process will be synchronous
        );

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [Message] ,
          [SortOrder] ,
          [ParentID] ,
          [ISAsync]
        )
VALUES  ( 'Action Type 1 Async' ,
          'Custom.DoCMAsyncAction' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          1 -- action without object parameters
          ,
          'Action the custom.DoCMAction procedure Asyncronously - Feedback in Table MFUserMessages and with email message' ,
          1 -- this is the sort order for the menu items in the group
          ,
          @Heading_2_ID -- this is the record ID of the group heading for this item
          ,
          1 -- process will be asynchronous
        );

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [Message] ,
          [SortOrder] ,
          [ParentID] ,
          [ISAsync]
        )

VALUES  ( 'Sync action Type 3 for selected Object ' ,
          'Custom.CMDoObjectAction' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          3 -- Object related action
          ,
          'Action the Custom.DoObjectAction procedure Synchronously - with feedback message' ,
          1 -- this is the sort order for the menu items in the group
          ,
          @Heading_4_ID -- this is the record ID of the group heading for this item
          ,
          0 -- process will be synchronous
        );

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [Message] ,
          [SortOrder] ,
          [ParentID] ,
          [ISAsync]
        )VALUES  ( 'Async action Type 3 for selected Object' ,
          'Custom.CMDoObjectAction' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          3 -- Object related action
          ,
          'Action Custom.DoObjectAction procedure for the selected Object Asyncronously - Feedback in Table MFUserMessages and with email message' ,
          2 -- this is the sort order for the menu items in the group
          ,
          @Heading_5_ID -- this is the record ID of the group heading for this item
          ,
          1 -- process will be asynchronous
        );

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [ISAsync]
        )

VALUES  ( 'StateAction1' ,
          'custom.DoCMAction' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          4 -- Action type 4: Workflow State action 
          ,
          1 -- process will be asynchronous
        );

INSERT  INTO #MFContextMenu
        ( [ActionName] ,
          [Action] ,
          [ActionType] ,
          [ISAsync]
        )
VALUES  ( 'StateAction2' ,
          'Custom.CMDoObjectActionForWorkFlowState' -- name of the procedure to be executed, in the case of Action Type 2 the URL of the website is used.
          ,
          5 -- Action type 5: Workflow State action with object details
          ,
          1 -- process will be asynchronous
        );

		
DECLARE @DefaultUserGroup NVARCHAR(10), @SQL NVARCHAR(MAX)

SELECT @DefaultUserGroup = 1

MERGE INTO dbo.MFContextMenu t
--[ActionName],[Action], [ActionType], [Message],[SortOrder],[ParentID],IsProcessRunning ,ISAsync ,[UserGroupID]
USING #MFContextMenu s
ON t.ActionName = s.ActionName 
WHEN MATCHED THEN
    UPDATE SET t.Action = s.Action ,
               t.ActionType = s.ActionType ,
               t.Message = s.Message ,
               t.SortOrder = s.SortOrder ,
               t.ParentID = s.ParentID ,
               t.IsProcessRunning = s.IsProcessRunning ,
               t.ISAsync = s.ISAsync,
			   t.UserGroupID = @DefaultUserGroup
WHEN NOT MATCHED THEN
    INSERT
    VALUES ( s.ActionName ,
             s.Action ,
             s.ActionType ,
             s.Message ,
             s.SortOrder ,
             s.ParentID ,
             s.IsProcessRunning ,
             s.ISAsync,
			 @DefaultUserGroup,
			 NULL,NULL,NULL
           );


UPDATE MFContextMenu 
SET ParentID = ISNULL((SELECT id FROM dbo.MFContextMenu AS MCM WHERE mcm.ActionName =  'Web Sites'),@Heading_3_ID)
WHERE MFContextMenu.ActionName = 'Google website ActionType 2'

UPDATE MFContextMenu 
SET ParentID = (SELECT ISNULL(id,@Heading_1_ID) FROM dbo.MFContextMenu AS MCM WHERE mcm.ActionName =  'Synchronous Actions')
WHERE MFContextMenu.ActionName = 'Action Type 1 Sync'

UPDATE MFContextMenu 
SET ParentID = (SELECT ISNULL(id,@Heading_2_ID) FROM dbo.MFContextMenu AS MCM WHERE mcm.ActionName =  'Asynchronous Actions')
WHERE MFContextMenu.ActionName = 'Action Type 1 Async'


UPDATE MFContextMenu 
SET ParentID = (SELECT ISNULL(id,@Heading_4_ID) FROM dbo.MFContextMenu AS MCM WHERE mcm.ActionName =  'Synchronous Object Actions')
WHERE MFContextMenu.ActionName = 'Sync action Type 3 for selected Object'


UPDATE MFContextMenu 
SET ParentID = (SELECT ISNULL(id,@Heading_5_ID) FROM dbo.MFContextMenu AS MCM WHERE mcm.ActionName =  'Asynchronous Object Actions')
WHERE MFContextMenu.ActionName = 'Async action Type 3 for selected Object'



DROP TABLE #MFContextMenu;