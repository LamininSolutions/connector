
/*

Example to demonstrate the use of searching of objects from SQL 

a) search for text in name or title
b) search for text in a specific property

*/
--Created on: 2019-05-08 

-------------------------------------------------------------
-- Searching for text in the name or title of any object in any class
-------------------------------------------------------------

--Option 1:  channel search result to a temporary table.  this allows for searches to be recorded.  Note the temporary tables has a limited life span as it will auto delete when the user disconnects from SQL. the entry in the search log will not be removed.

DECLARE @XMLOutPut XML
       ,@TableName VARCHAR(200);

EXEC [dbo].[spMFSearchForObject] @ClassID = 78                  -- the class MFID: this can be obtained from select Name, MFID from MFClass
                                ,@SearchText = 'A'              -- any text value, this can be a part text. It does not cater for wildcards
                                ,@Count = 5                     -- used to restrict the number of search result returns.
                                ,@Debug = 0
                                ,@OutputType = 1                -- set to 1 to channel output to a table
                                ,@XMLOutPut = @XMLOutPut OUTPUT -- is null  
                                ,@TableName = @TableName OUTPUT;

-- used in subsequent processing to process the search result.                 
--show temp table name
SELECT @TableName AS [TableName];

--view search result
SELECT *
FROM [dbo].[MFSearchLog] AS [msl];
GO

--Option 2: channel search result to a XML record.  This is usefull if a specific property must be extracted out of the search result.

DECLARE @XMLOutPut XML
       ,@TableName VARCHAR(200);

EXEC [dbo].[spMFSearchForObject] @ClassID = 78                  -- the class MFID: this can be obtained from select Name, MFID from MFClass
                                ,@SearchText = 'A'              -- any text value, this can be a part text. It does not cater for wildcards
                                ,@Count = 5                     -- used to restrict the number of search result returns.
                                ,@Debug = 0
                                ,@OutputType = 0                -- set to 0 to channel output to XML
                                ,@XMLOutPut = @XMLOutPut OUTPUT --used in subsequent processing 
                                ,@TableName = @TableName OUTPUT;

--is null

--view XML record
SELECT @XMLOutPut AS [XMLOutput];

--get entire XML by record

--as XML
SELECT [T].[N].[query]('.')
FROM @XMLOutPut.[nodes]('/form/Object') AS [T]([N]);

--as a table
SELECT [t].[c].[value]('(../@objectId)[1]', 'INT')             AS [objectId]
      ,[t].[c].[value]('(@propertyId)[1]', 'INT')              AS [propertyId]
      ,[mp].[Name]                                             AS [propertyName]
      ,[t].[c].[value]('(@propertyValue)[1]', 'NVARCHAR(100)') AS [propertyValue]
FROM @XMLOutPut.[nodes]('/form/Object/properties') AS [t]([c])
    INNER JOIN [dbo].[MFProperty]                  AS [mp]
        ON [mp].[MFID] = [t].[c].[value]('(@propertyId)[1]', 'INT');
GO

-------------------------------------------------------------
-- Search for text in a specific property
-------------------------------------------------------------

/*
note when a value is searched for a valuelist property, you need to specify the MFID of the valuelist item to search.
*/

DECLARE @XMLOutPut XML
       ,@TableName VARCHAR(200);

EXEC [dbo].[spMFSearchForObjectbyPropertyValues] @ClassID = 78                  -- the class MFID 
                                                ,@PropertyIds = '1090'          --comma delimited list of property MFID's to search
                                                ,@PropertyValues = '1'          -- comma delimited list of text values to search.  Note the Property IDs are paired with the search values.
                                                ,@Count = 5                     -- int
                                                ,@OutputType = 0                -- int
                                                ,@XMLOutPut = @XMLOutPut OUTPUT -- xml
                                                ,@TableName = @TableName OUTPUT;

                                                                                -- varchar(200)

--view XML record
SELECT @XMLOutPut AS [XMLOutput];

--get entire XML by record

--as XML
SELECT [T].[N].[query]('.')
FROM @XMLOutPut.[nodes]('/form/Object') AS [T]([N]);

--as a table
SELECT [t].[c].[value]('(../@objectId)[1]', 'INT')             AS [objectId]
      ,[t].[c].[value]('(@propertyId)[1]', 'INT')              AS [propertyId]
      ,[mp].[Name]                                             AS [propertyName]
      ,[t].[c].[value]('(@propertyValue)[1]', 'NVARCHAR(100)') AS [propertyValue]
FROM @XMLOutPut.[nodes]('/form/Object/properties') AS [t]([c])
    INNER JOIN [dbo].[MFProperty]                  AS [mp]
        ON [mp].[MFID] = [t].[c].[value]('(@propertyId)[1]', 'INT');
