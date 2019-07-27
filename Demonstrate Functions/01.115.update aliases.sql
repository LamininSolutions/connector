/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
show MFProperty and MFClass relationship
Show updating of aliases

*/

--STANDARD SELECT STATEMENT TO SHOW PROPERTIES FOR A CLASS

SELECT [MFProperty].*
      ,[MFClass].[Alias]
FROM [MFProperty]
    INNER JOIN [MFClassProperty]
        ON [MFProperty].[ID] = [MFClassProperty].[MFProperty_ID]
    INNER JOIN [MFClass]
        ON [MFClass].[ID] = [MFClassProperty].[MFClass_ID]
WHERE [MFClass].[Name] = 'customer';

--UPDATE STATEMENT TO SET ALIASES (EXAMPLE)

UPDATE [MFProperty]
SET [MFProperty].[Alias] = ISNULL([MFProperty].[Alias], '') + 'p.' + REPLACE([MFProperty].[Name], ' ', '')
FROM [MFProperty]
    INNER JOIN [MFClassProperty]
        ON [MFProperty].[ID] = [MFClassProperty].[MFProperty_ID]
    INNER JOIN [MFClass]
        ON [MFClass].[ID] = [MFClassProperty].[MFClass_ID]
WHERE [MFClass].[Name] = 'customer';

UPDATE [MFClass]
SET [Alias] = 'c.customer'
WHERE [Name] = 'Customer';

--PROCESSING CHANGES TO THE ALIASES

EXEC [spMFSynchronizeSpecificMetadata] @Metadata = 'Property'
                                      ,@IsUpdate = 1;
EXEC [spMFSynchronizeSpecificMetadata] @Metadata = 'Class', @IsUpdate = 1;

SELECT *
FROM [dbo].[MFvwMetadataStructure]
WHERE [Class_Alias] = 'c.customer'
ORDER BY [Class_Alias]
        ,[Property_alias];

--bulk update of aliases
--see next session

