GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwAuditSummary]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwAuditSummary', -- nvarchar(100)
    @Object_Release = '4.3.10.49', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwAuditSummary'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[MFvwAuditSummary]
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

Modifications

2019-06-17	LC		Add class name to as column, remove session id
*/		
ALTER VIEW [dbo].[MFvwAuditSummary]
AS

/*rST**************************************************************************

================
MFvwAuditSummary
================

Purpose
=======

To view a summary of AuditHistory by Flag and Class

Examples
========

.. code:: sql

    Select * from MFAuditHistory

----

show audit history for a specific class

.. code:: sql

    Select ah.*, mc.name from MFAuditHistory ah
    inner join MFClass mc
    on ah.Class = mc.mfid
    Where mc.name = 'Customer'
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-03-27  LC         Add object type in view to catch collections
2020-03-27  LC         Add documentation
==========  =========  ========================================================

**rST*************************************************************************/


SELECT TOP 1000  mot.mfid AS ObjectType_ID, mot.name AS ObjectType, mc.name  AS Class, mc.mfid AS Class_ID,  [mc].[TableName], mah.[StatusName], mah.[StatusFlag], COUNT(*) AS [Count]

FROM [dbo].[MFAuditHistory] AS [mah]
INNER JOIN [dbo].[MFClass] AS [mc]
ON mc.mfid = mah.[Class] 
INNER JOIN dbo.MFObjectType AS mot
ON mah.ObjectType = mot.mfid

GROUP BY mot.mfid, mot.name, mc.name, mc.mfid, mah.[StatusName], [mc].[TableName], mah.[StatusFlag]
ORDER BY mc.name DESC


GO

