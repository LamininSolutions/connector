
/*
Updating from SQL to M-Files
illustration on how to deal with a auto number, and using the auto number in a calculated field

The class table in our illustration has two properties
Autonumber : Integer set to simple autonumbering
Calculated: Text property with autocalculation AUTO + Auto number

The key is that both properties must be included in the record when inserting / updating the record. both columns can have dummy values.

*/
--Created on: 2019-08-29 

--get records

EXEC [dbo].[spMFUpdateTable] 'MFMyDocn', 1;

--view results
SELECT *
FROM [dbo].[MFMydocn];

--First iteration
INSERT INTO [dbo].[MFMydocn]
(
    [Autonumber]
   ,[Calculated]
   ,[Name_Or_Title]
   ,[Process_ID]
)
VALUES
(0, 'auto', 'First record', 1);

EXEC [dbo].[spMFUpdateTable] 'MFMyDocn', 0;

SELECT *
FROM [dbo].[MFMydocn];

--Second iteration
INSERT INTO [dbo].[MFMydocn]
(
    [Autonumber]
   ,[Calculated]
   ,[Name_Or_Title]
   ,[Process_ID]
)
VALUES
(0, 'auto', 'First record', 1);

EXEC [dbo].[spMFUpdateTable] 'MFMyDocn', 0;

--Update to title (non related to auto number)

UPDATE mm
SET [mm].[Process_ID] = 1, [mm].[Name_Or_Title] = 'Updated record'
FROM [dbo].[MFMydocn] AS [mm]
WHERE id = 1

EXEC [dbo].[spMFUpdateTable] 'MFMyDocn', 0;

