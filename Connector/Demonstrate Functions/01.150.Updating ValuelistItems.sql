/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*

UPDATING VALUELIST ITEMS FROM MFSQL CONNECTOR
*/

--SYNC VALUELIST ITEMS

	TRUNCATE TABLE [dbo].[MFValueListItems]

	SELECT *
	FROM   [dbo].[MFValueListItems]

	EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'ValuelistItems'

	--or

	EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'ValuelistItem' -- varchar(100)
											   , @ItemName = 'Country'


	SELECT *
	FROM   [MFvwCountry]

--CHNAGING THE NAME OF VALUELIST ITEM (name, DisplayID)

	UPDATE [mvli]
	SET	   [Process_ID] = 1
		 , [mvli].[Name] = 'United Kingdom'
		 , [DisplayID] = '3'
	--select vc.*
	FROM   [MFValuelistitems] [mvli]
--	INNER JOIN [vwMFCountry] [vc] ON [vc].[AppRef_ValueListItems] = [mvli].[appref]
	WHERE  [mvli].[AppRef] = '2#154#3'

--INSERT NEW VALUE LIST ITEM (note only name process_id and valuelist id is required)
--display_id must be unique, if not set it will default to the mfid

	DECLARE @Valuelist_ID INT
	SELECT @Valuelist_ID = [id]
	FROM   [dbo].[MFValueList]
	WHERE  [name] = 'Country'

	INSERT INTO [MFValueListItems] (   [Name]
									 , [Process_ID]
									 , [DisplayID]
									 , [MFValueListID]
								   )
	VALUES ( 'Russia', 1, 'RU', @Valuelist_ID )


	INSERT INTO [MFValueListItems] (   [Name]
									 , [Process_ID]
									 , [MFValueListID]
								   )
	VALUES ( 'Argentina', 1, @Valuelist_ID )


--DELETE VALUELIST ITEM (note that the procedure will delete the valuelist item only and not the related objects)
--the record will not be deleted from the table, however, the deleted column will be set to 1.

	SELECT *
	FROM   [MFvwCountry]

	UPDATE [mvli]
	SET	   [Process_ID] = 2
	--select *
	FROM   [MFValuelistitems] [mvli]
	WHERE  [mvli].[AppRef] = '2#154#9'


--PROCESS UPDATE
	EXEC [spMFSynchronizeValueListItemsToMFiles]

	SELECT *
	FROM   [MFvwCountry]


