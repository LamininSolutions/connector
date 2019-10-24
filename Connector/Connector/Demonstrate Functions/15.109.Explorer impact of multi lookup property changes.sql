
/*
Example to illustrate and test change datatype of lookup
*/
--Created on: 2019-06-08 

-------------------------------------------------------------
-- create test object in M-Files with a multi lookup and single lookup then update metadata
-------------------------------------------------------------

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFDropAndUpdateMetadata];
GO

-------------------------------------------------------------
-- Test object class table
-------------------------------------------------------------

DROP TABLE [mfmftest];

EXEC [dbo].[spMFCreateTable] 'MFTest';

EXEC [dbo].[spMFUpdateTable] 'MFMFTest', 1;

SELECT *
FROM [MFMFTest];

-------------------------------------------------------------
-- Check datatypes in SQL
-------------------------------------------------------------
EXEC [dbo].[spMFClassTableColumns];

SELECT *
FROM [##spMFClassTablecolumns]
WHERE [class] = 'MFTest'
ORDER BY [columnname];

-------------------------------------------------------------
-- add single lookup item to multi lookup property; ensure there is no other objects in the same class with multi items for this property
-------------------------------------------------------------
EXEC [dbo].[spMFUpdateTable] 'MFMFTest', 1;

SELECT *
FROM [MFMFTest];

EXEC [dbo].[spMFClassTableColumns];

SELECT *
FROM [##spMFClassTablecolumns]
WHERE [class] = 'MFTest'
ORDER BY [columnname];

-------------------------------------------------------------
-- change the datatype to multi lookup and add another item to the property
-------------------------------------------------------------
EXEC [dbo].[spMFUpdateTable] 'MFMFTest', 1;

SELECT *
FROM [MFMFTest];

EXEC [dbo].[spMFClassTableColumns];

SELECT *
FROM [##spMFClassTablecolumns]
WHERE [class] = 'MFTest'
ORDER BY [columnname];

--the result should be an error
SELECT *
FROM [dbo].[MFLog]
ORDER BY [LogID] DESC;

--Conversion failed when converting the nvarchar value '5,2' to data type int.

-------------------------------------------------------------
-- update metadata strcuture with column reset
-------------------------------------------------------------
DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0
                                      ,@WithClassTableReset = 0
                                      ,@WithColumnReset = 1
                                      ,@IsStructureOnly = 0
                                      ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                      ,@Debug = 0;
GO

--check the result
EXEC [dbo].[spMFClassTableColumns];

SELECT *
FROM [##spMFClassTablecolumns]
WHERE [class] = 'MFTest'
ORDER BY [columnname];
