
/*
BUG FIX for version 3.1.2.38
targeted to all  existing installations before 3.1.2.38

/*


*/



/*
RESET ALL CLASS TABLES INCLUDED IN APP MFLASTMODOFIFIED DATE TO LOCAL TIME

Version 38 introduced a change where MFLstModifiedDate column is changed for UTC to Local time.  
The dates in this class tables will only change automatically if a version change takes place in M-Files
It is therefore necessary to change all the dates of all the tables that is included in the application

The following migration script will run through all the tables included in app where included in app is not null and reset the MFLastModified date from UTC to Local time

if the table was updated / changed after the date of the installation of version .38 then the table will be excluded to avoid this routine being applied to class tables after version .38 is installed
*/

PRINT 'MFWORKFLOWSTATE TABLE - change varchar size';

SET NOCOUNT ON;

SELECT *
FROM [setup].[MFSQLObjectsControl] AS [moc]
WHERE [moc].[Release] = '3.1.2.38'
      AND [Name] = 'spMFUpdateTableInternal';

DECLARE @Vers38InstallDate DATETIME;

SELECT @Vers38InstallDate = [moc].[Modify_Date]
FROM [setup].[MFSQLObjectsControl] AS [moc]
WHERE [moc].[Release] = '3.1.2.38'
      AND [Name] = 'spMFUpdateTableInternal';

SELECT @Vers38InstallDate;

IF @Vers38InstallDate IS NOT NULL
BEGIN
    SELECT [mc].[Name_Or_Title],
           [mc].[MF_Last_Modified],
           [mc].[Created],
           [mc].[LastModified]
    FROM [dbo].[MFCustomer] AS [mc]
    WHERE [mc].[LastModified] < @Vers38InstallDate;
    PRINT 'MFLastModified and Created dates will be reset for all class tables included in app';
END;
ELSE
BEGIN
    PRINT 'Install version .38 and then run this script';
END;

DECLARE @Return_LastModified DATETIME,
        @Update_IDOut INT,
        @ProcessBatch_ID INT;
EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1,                                  -- int
                                                 @Return_LastModified = @Return_LastModified OUTPUT, -- datetime
                                                 @TableName = 'MFCustomer',                                  -- sysname
                                                 @Update_IDOut = @Update_IDOut OUTPUT,               -- int
                                                 @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,         -- int
                                                 @debug = 0                                          -- smallint


SELECT [mc].[Name_Or_Title], [mc].[MF_Last_Modified], [mc].[Created], [mc].[LastModified], [mc].[MFVersion] FROM [dbo].[MFCustomer] AS [mc]


SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC [dbo].[spMFClassTableStats] @ClassTableName = N'', -- nvarchar(128)
                                 @Flag = 0,             -- int
                                 @Debug = 0             -- smallint

EXEC [dbo].[spMFCreateTable] @ClassName = N'Customer', -- nvarchar(128)
                             @Debug = 0        -- smallint

DECLARE @Update_IDOut1 INT,
        @ProcessBatch_ID1 INT;
EXEC [dbo].[spMFUpdateTable] @MFTableName = N'MFcustomer',                          -- nvarchar(128)
                             @UpdateMethod = 1

SELECT [mc].[Name_Or_Title], [mc].[MF_Last_Modified], [mc].[Created], [mc].[LastModified], [mc].[MFVersion] FROM [dbo].[MFCustomer] AS [mc]

