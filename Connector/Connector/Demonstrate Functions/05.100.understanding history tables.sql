
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/
/*
Understanding history records

*/
-- show stats for all history table
EXEC [spMFLogTableStats]

--deleting history
EXEC [dbo].[spMFDeleteHistory] @DeleteBeforeDate = '2017-01-08 04:52:03' 
--Setup scheduled agent to delete history on a regular basis

--Update history show record of each object update to and from M-Files in XML format.  This is the result of the spmfupdatetable 
SELECT TOP 10 * FROM [dbo].[MFUpdateHistory] AS [muh] ORDER BY id DESC
--use show history to get listing of individual items
EXEC [dbo].[spMFUpdateHistoryShow]
    @Update_ID = 1238,
    @IsSummary = 1, -- show summary
    @UpdateColumn = 0,
    @Debug = 0

	EXEC [dbo].[spMFUpdateHistoryShow]
    @Update_ID = 1238,
    @IsSummary = 0,
    @UpdateColumn = 3, --show content of specific column
    @Debug = 0

-- Errorlog show all system errors
SELECT TOP 10 * FROM mflog ORDER BY logid DESC

--spmfaudithistory show to the object versions as a result of the spmfaudittable procedure
SELECT TOP 100 * FROM [dbo].[MFAuditHistory] AS [mah]

--show summary of specific session
SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas] WHERE sessionID = 1	






