
/*

*/
--Created on: 2019-02-15 


--EXEC [dbo].[spMFClassTableColumns]
SELECT DISTINCT tableName, ColumnName, c.[IS_NULLABLE], mcc.column_DataType,mcc.length, mcc.* FROM ##spmfclasstablecolumns mcc
INNER JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c]
ON mcc.COLUMNname = c.[COLUMN_NAME] AND mcc.tablename = c.[TABLE_NAME]
 WHERE required = 0
AND c.[IS_NULLABLE] = 'NO'
AND mcc.includedInApp = 1
AND columnType IN ('Metadata Card Property','Additional Property')
ORDER BY [mcc].[TABLENAME]

ALTER TABLE MFContactMarketing
ALTER column First_Name NVARCHAR(200) NULL
