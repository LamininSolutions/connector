GO


/*
script to run update of M-files version validation 



IF EXISTS(
select name FROM sys.[assemblies] AS [a] WHERE name = 'Interop.MFilesAPI') AND exists(SELECT 1 FROM mfsettings)
BEGIN

EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion] @ScriptFilePath = 

END
*/
GO
