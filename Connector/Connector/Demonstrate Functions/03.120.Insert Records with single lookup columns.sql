
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
RECORDS WITH VALUELIST ITEMS - SINGLE LOOKUP
when a record is inserted from a external source it may be to add new valuelist items before the record can be added

*/

--the external source staging table should have an additional column for the MFID of each lookup column.

-- STEP 1 - determine if the new lookup value already exsit, add MFID in staging table MFID column, count number of missing items
--use spMFCreateValueListLookupView to create new lookup view

--example of code for single lookup with no owner
	UPDATE [Source]
	SET	   [Source].[MFCountry_ID] = [MF].[MFID_ValueListItems]
	FROM   [Custom].[stageMFCustomer] [Source]
	INNER JOIN [dbo].[vwMFCountry] [MF] ON [MF].[Name_ValueListItems] = [Source].[Country]
										   AND [MF].[Deleted] = 0
	WHERE  [Source].[MFCountry_ID] IS NULL
		   AND [Source].[Country] IS NOT NULL

	DECLARE @Missing_Country_ID INT
	SELECT @Missing_Country_ID = COUNT(DISTINCT [Source].[Country])
	FROM   [Custom].[stageMFCustomer] [Source]
	WHERE  [Source].[MFCountry_ID] IS NULL
		   AND [Source].[Country] IS NOT NULL



-- example of single lookup with owner - state/province by country

	UPDATE [Source]
	SET	   [Source].[MFState_Province_ID] = [MF].[MFID_ValueListItems]
	FROM   [Custom].[stageMFCustomer] [Source]
	INNER JOIN [dbo].[MFvwValueList_StateProvince] [MF] ON [MF].[Name_ValueListItems] = [Source].[BILL_STATE]
														   AND [MF].[OwnerName_ValueListItems] = [Source].[BILL_COUNTRY]
														   AND [MF].[Deleted] = 0
	WHERE  [Source].[MFState_Province_ID] IS NULL
		   AND [Source].[BILL_STATE] IS NOT NULL

	DECLARE @Missing_State_Province_ID INT
	SELECT @Missing_State_Province_ID = COUNT(DISTINCT
												 ISNULL([Source].[BILL_COUNTRY], '') + ISNULL([Source].[BILL_STATE], '')
											 )
	FROM   [Custom].[stageMFCustomer] [Source]
	WHERE  [Source].[MFState_Province_ID] IS NULL
		   AND [Source].[BILL_STATE] IS NOT NULL

--STEP 2 - if step 1 show that it does not exist, then refresh valuelist items if users are allowed to add items in M-Files. Test again to confirm that the 
--item was not already created by the user since the last sync.


--Process Missing Value List Items
	IF (   @Missing_Country_ID > 0
		   OR @Missing_State_Province_ID > 0
	   )
	BEGIN
		--Refresh from M-Files 
		--and update value list to see if anything still missing
		--add missing values to M-Files
		EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'ValueListItems'
												   , @Debug = @debug
												   , @IsUpdate = 0 --M-Files to MFSQL


		--STEP 3 If not exists - then add a new valuelist item.

		IF @Missing_Country_ID > 0
			BEGIN

				UPDATE [Source]
				SET	   [Source].[MFCountry_ID] = [MF].[MFID_ValueListItems]
				FROM   [Custom].[stageMFCustomer_FutNew] [Source]
				INNER JOIN [dbo].[MFvwValueList_Country] [MF] ON [MF].[Name_ValueListItems] = [Source].[BILL_COUNTRY]
																 AND [MF].[Deleted] = 0
				WHERE  [Source].[MFCountry_ID] IS NULL
					   AND [Source].[BILL_COUNTRY] IS NOT NULL

				SELECT @Missing_Country_ID = COUNT(DISTINCT [Source].[BILL_COUNTRY])
				FROM   [Custom].[stageMFCustomer_FutNew] [Source]
				WHERE  [Source].[MFCountry_ID] IS NULL
					   AND [Source].[BILL_COUNTRY] IS NOT NULL

				IF @Missing_Country_ID > 0
					BEGIN
						-- add missing value list items
						INSERT [dbo].[MFValueListItems] (	[Name]
														  , [MFValueListID]
														  , [OwnerID]
														  , [Process_ID]
														)
							   SELECT DISTINCT [BILL_COUNTRY]
									, [MFVL].[ID]
									, 0
									, 1
							   FROM	  [Custom].[stageMFCustomer_FutNew]
							   CROSS JOIN (	  SELECT [ID]
												   , [Name]
												   , [MFID]
											  FROM	 [dbo].[MFValueList]
											  WHERE	 [Name] = 'Country'
										  ) [MFVL]
							   WHERE  [MFCountry_ID] IS NULL
									  AND [BILL_COUNTRY] IS NOT NULL

					END --IF @Missing_Country_ID > 0
			END --IF @Missing_Country_ID > 0

		--STEP 4 perform step 1 - 3 for all lookup columns to create all the new valuelist items, then process update.

		--STEP 5  get new valuelist item id's to use for inserting new record.


		--Write back to M-Files any missing values
		--update staging with newly created IDs
		IF EXISTS (	  SELECT 1
					  FROM	 [dbo].[MFValueListItems]
					  WHERE	 [Process_ID] <> 0
							 AND [Deleted] = 0
				  )
			BEGIN
				-- At least one value list item needs to be updated					
				EXEC [dbo].[spMFSynchronizeValueListItemsToMFiles] @debug

				IF @Missing_Country_ID > 0
					BEGIN
						UPDATE [Source]
						SET	   [Source].[MFCountry_ID] = [MF].[MFID_ValueListItems]
						FROM   [Custom].[stageMFCustomer_FutNew] [Source]
						INNER JOIN [dbo].[MFvwValueList_Country] [MF] ON [MF].[Name_ValueListItems] = [Source].[BILL_COUNTRY]
																		 AND [MF].[Deleted] = 0
						WHERE  [Source].[MFCountry_ID] IS NULL
							   AND [Source].[BILL_COUNTRY] IS NOT NULL
					END --IF @Missing_Country_ID > 0

				IF @Missing_State_Province_ID > 0
					BEGIN
						UPDATE [Source]
						SET	   [Source].[MFState_Province_ID] = [MF].[MFID_ValueListItems]
						FROM   [Custom].[stageMFCustomer_FutNew] [Source]
						INNER JOIN [dbo].[MFvwValueList_StateProvince] [MF] ON [MF].[Name_ValueListItems] = [Source].[BILL_STATE]
																			   AND [MF].[OwnerName_ValueListItems] = [Source].[BILL_COUNTRY]
																			   AND [MF].[Deleted] = 0
						WHERE  [Source].[MFState_Province_ID] IS NULL
							   AND [Source].[BILL_STATE] IS NOT NULL

					END --IF @Missing_State_Province_ID > 0

			END --IF EXISTS (	  SELECT 1  FROM	 [dbo].[MFValueListItems]  WHERE	 [Process_ID] <> 0 AND [Deleted] = 0

	END --IF (   @Missing_Country_ID > 0   OR @Missing_State_Province_ID > 0   )