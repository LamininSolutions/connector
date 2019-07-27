
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/


/*
Create public shared link

*/

exec [dbo].[spMFCreateTable] @ClassName = N'Other Document' -- nvarchar(128)
                           , @Debug = 0       -- smallint

exec [dbo].[spMFUpdateTable] @MFTableName = N'MFOtherDocument'                                              -- nvarchar(200)
                           , @UpdateMethod = 1                                               -- int
                          

--Update a record where singlefile = 1 and set process_ID = 1

update [od]
set [od].[Process_ID] = 1
FROM   [MFOtherDocument] od where [Single_File] = 1 


--check settings,  the server URL and Vault Guid must be correct
SELECT * FROM [dbo].[MFSettings] AS [ms]

--updating MFSettings for the dependent settings if needed
EXEC [spMFSettingsForVaultUpdate] @ServerURL = 'http://mfdemosrv01:8080'
								, @VaultGUID = 'E0A4DF9A-043F-463E-8E55-0556C00B61D0'


DECLARE @Expiredate DATETIME = DATEADD(m, 1, GETDATE()) -- set expiredate to 1 month from today
EXEC [spMFCreatePublicSharedLink] @Tablename = 'MFOtherDocument'
								, @Expirydate = @Expiredate
								, @processID = 1

SELECT *
FROM   [MFPublicLink]

/*

http://LSUK-APP03.LSUSA.LOCAL/SharedLinks.aspx?accesskey=fd69f8b5e1a02a567ebd164dfea337b3fe2b92d3296df3d698bf6d2354cba983&VaultGUID={3E2585FF-ED4F-4EEF-888D-B7AD475195B9}


*/

--show links for a specific Project
SELECT [mod].[Project], mod.[Name_Or_Title], mpl.link AS FileURL FROM [dbo].[MFOtherDocument] AS [mod]
INNER JOIN [dbo].[MFPublicLink] AS [mpl]
ON [mod].objid=mpl.[ObjectID] AND mod.class_ID = mpl.[ClassID]
WHERE [mod].[Project] = 'Office Design'

