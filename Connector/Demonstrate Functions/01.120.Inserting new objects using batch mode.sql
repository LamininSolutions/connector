/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
INSERTING NEW RECORDS IN CLASS TABLE USING BATCH UPDATE
note that all the standard columns commented out is optional in the insert statement or is not required when inserting a new record

*/

--Review target table
select * from MFCustomer

--view the lookup values
	SELECT [mvli].*
	FROM   [MFValueListItems] [mvli]
	INNER JOIN [MFValueList] [mvl] ON [mvli].[MFValueListID] = [mvl].[id]
	WHERE  [mvli].[Name] = 'United Kingdom'
		   AND [mvl].[Name] = 'Country'

--set variable to lookup
--EXEC FROM HERE
	DECLARE @Country_ID INT

	SELECT @Country_ID = [mvli].[mfid]
	FROM   [MFValueListItems] [mvli]
	INNER JOIN [MFValueList] [mvl] ON [mvli].[MFValueListID] = [mvl].[id]
	WHERE  [mvli].[Name] = 'United Kingdom'
		   AND [mvl].[Name] = 'Country'

--Note that the commented out items in the list below does not have to be set to insert a new object into the class

	INSERT INTO [dbo].[MFCustomer] (
									   --GUID , --automatically inserted
									   --MX_User_ID , --optional, special use
									   [Address_Line_1]
									 , [Address_Line_2]
									 , [City]
									 --Class , -- not need to update lables of lookup tables
									 --Class_ID , -- if not specified will default to class of table
									 --Country , -- not need to update lables of lookup tables
									 , [Country_ID]
									 --Created , --automatically inserted
									 --Created_by ,--automatically inserted
									 --Created_by_ID ,--automatically inserted
									 , [Customer_Name]
									 --MF_Last_Modified ,--automatically inserted
									 --MF_Last_Modified_By ,--automatically inserted
									 --MF_Last_Modified_By_ID ,--automatically inserted
									 --   Name_Or_Title , --default if auto naming is used
									 --Single_File , --automatically inserted
									 --State ,  -- not need to update lables of lookup tables
									 --State_ID , -- optional depending on class rules
									 , [Stateprovince]
									 , [Telephone_Number]
									 , [Web_Site]
									 --Workflow , -- not need to update lables of lookup tables
									 --Workflow_ID ,-- optional depending on class rules
									-- , [PostalCode]
									 --LastModified ,--automatically inserted
									 , [Process_ID]
								   --ObjID ,--automatically inserted
								   --ExternalID ,--optional, default to ObjID
								   --MFVersion ,--automatically inserted
								   --Deleted ,--automatically inserted
								   --Update_ID--automatically inserted
								   )
	VALUES ( 'Building'
		   , 'Street Name'
		   , 'London'
		   , @Country_ID
		   , 'ABC Customer_2'
		   , 'Hampshire'
		   , '090987098'
		   , 'www.abccompany.com'
		   , 1 --process_ID
		   )

--EXEC TO HEAR

-- UPDATE INSERTED RECORDS FROM SQL INTO M-FILES
	EXEC [spMFUpdateTable] 'MFCustomer'
					 , 0

--CHECK TABLE
	SELECT *
	FROM   [mfcustomer]



