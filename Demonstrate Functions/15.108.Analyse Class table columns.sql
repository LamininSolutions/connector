
/*
From version 4.2.7.46

This special procedure analyses the M-Files classes and show types of columms and any potential anomolies between the metadata strcuture and the columns for the table in SQL

The listing will identify the columns added to the table related to Additional properties

*/

EXEC [dbo].[spMFClassTableColumns]  -- nvarchar(200)

--review result

SELECT * FROM ##spMFClassTableColumns ORDER BY ISNULL(INcludedInapp,0) desc,tableName, ColumnName

--Selecting from the results of the analysis
--note the procedure creates a temporary table as an output which can used to analyse the results further or to be used in related procedures

SELECT * FROM ##spMFClassTableColumns WHERE includedinApp IS NOT NULL AND Property = 'keywords'

SELECT * FROM ##spMFClassTableColumns WHERE additionalproperty = 1

		


							