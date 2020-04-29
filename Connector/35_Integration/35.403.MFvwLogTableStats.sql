
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwLogTableStats]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwLogTableStats', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwLogTableStats'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW dbo.MFvwLogTableStats
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2016-5

-- Description:	Summary of AuditHistory by Flag and Class
-- Revision History:  
-- YYYYMMDD Author - Description 
-- =============================================
*/		
ALTER VIEW dbo.MFvwLogTableStats
AS

/*rST**************************************************************************

=================
MFvwLogTableStats
=================

Purpose
=======

To view the log tables with the record count and the earliest date of a log entry

Activate the agent **Delete History** to delete the old records in the log tables.

Examples
========

.. code:: sql

   Select * from MFvwLogTableStats

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-27  LC         Add documentation
==========  =========  ========================================================

**rST*************************************************************************/


SELECT  'MFAuditHistory' AS TableName, COUNT(*) AS RecordCount, EarliestDate = MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
UNION ALL 
SELECT  'MFUpdateHistory' AS TableName, COUNT(*) AS RecordCount, EarliestDate = MIN([mah].[CreatedAt]) FROM [dbo].[MFUpdateHistory] AS [mah]
UNION ALL
SELECT  'MFLog' AS TableName, COUNT(*) AS RecordCount, EarliestDate = MIN([mah].[CreateDate]) FROM [dbo].[MFLog] AS [mah]
UNION ALL
SELECT  'MFProcessBatch' AS TableName, COUNT(*) AS RecordCount, EarliestDate = MIN([mah].[CreatedOn]) FROM [dbo].[MFProcessBatch] AS [mah]
UNION ALL
SELECT  'MFProcessBatchDetail' AS TableName, COUNT(*) AS RecordCount, EarliestDate = MIN([mah].[CreatedOn]) FROM [dbo].[MFProcessBatchDetail] AS [mah]
