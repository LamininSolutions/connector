


/*
Getting ready from reporting

*/

--identify all the class tables to be included in reports

SELECT * FROM mfclass

--set Include in App for all required tables 

UPDATE MFClass
SET IncludeInApp = 1
WHERE Name IN ('Contact Person','Customer','Customer Project','Sales Invoice')

--validate
Select TableName from MFClass where IncludeInApp = 1

--auto create all the class tables
EXEC spMFCreateAllMFTables 

--pull from MF for all class tables (	WARNING - THIS MAY BE LONG RUNNING IF THERE ARE MANY RECORDS IN THE TABLE)

exec spMFUpdateAllncludedInAppTables @UpdateMethod = 1

--check table stats

exec spMFClassTableStats


  GO
