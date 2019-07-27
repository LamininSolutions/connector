

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
Using the Hyperlink function with class tables

*/

--desktop - show (option 1)
select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],1) from [dbo].[MFAccount] AS mc

--desktop open (option 4)
select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],4) from [dbo].[MFAccount] AS mc

--desktop - view (option 3)

select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],3) from [dbo].[MFAccount] AS mc

--desktop - edit (option 6)

select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],6) from [dbo].[MFAccount] AS mc

--desktop - show metadata (option 5)

select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],5) from [dbo].[MFAccount] AS mc

--web (option 2)
select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],2) from [dbo].[MFAccount] AS mc






