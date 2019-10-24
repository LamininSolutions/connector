

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

-- using special functions in procedures

/*
Several functions are included for use the the core procedures. This functions are also handy for custom procedures.
*/

--TABLE BASED FUNCTIONS

--ParseDelimitedString


DECLARE @String NVARCHAR(1000)
SET @string = 'item1, item 2, item 3' 
select * from [dbo].[fnMFParseDelimitedString](@String,',') as [fmpds]

--this function is used is a cross apply to show all the items for a multilookup

SELECT * FROM [dbo].[MFCustomerOrder] AS [mco]
CROSS APPLY [dbo].[fnMFParseDelimitedString](OrderLine_ID,',') AS [fmpds]
INNER JOIN MFOrderLines mol
ON mol.objid = [fmpds].listitem

--Split 
--This function is specifically designed to parse a paired group of property ids, and there value.

select * from [dbo].[fnMFSplit]('0,1079','Name of object, Customer',',') as [fms]


--SplitPairedString
--This function is similar to Split, however it allows for including multi lookups as a inner delimited string

select * from [dbo].[fnMFSplitPairedStrings]('Customer_ID,Project_ID,Objid','12;36;78,7,10007',',',';') as [fmsps]

--SplitString
 -- this is similar to ParseDelimitedString

 select * from [dbo].[fnMFSplitString]('4,5,6,7,8,9,0',',') as [fmss]


 --SCALAR FUNCTIONS

 /*
The following functions could be used in some cases in custom procedures 
--CapitalizeFirstLetter
 --ReplaceSpecialCharacter
 --VaultSettings
 --VariableTableName

 */

 select [dbo].[fnMFCapitalizeFirstLetter]('this is my name')

 select [dbo].[fnMFReplaceSpecialCharacter]('t%his ,i*llus!trate it') -- note that the removal of special characters is focussed on removing characters that could interfere with the connector operations
 
 select [dbo].[FnMFVaultSettings]()

 select [dbo].[fnMFVariableTableName]('MFTable',replace(convert(varchar(15), getdate(),110),'-',''))

 --MultiLookupUpsert  (Refer to separate example of usage)

 --ObjectHyperlink (Refer to separate example of usage)


