
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwObjectTypeSummary]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'MFvwObjectTypeSummary' -- nvarchar(100)
                                    ,@Object_Release = '4.7.21.61'           -- varchar(50)
                                    ,@UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[VIEWS]
    WHERE [TABLE_NAME] = 'MFvwObjectTypeSummary'
          AND [TABLE_SCHEMA] = 'dbo'
)
BEGIN
    SET NOEXEC ON;
END;
GO

CREATE VIEW [dbo].[MFvwObjectTypeSummary]
AS
SELECT [Column1] = 'UNDER CONSTRUCTION';
GO

SET NOEXEC OFF;
GO

/*rST**************************************************************************

=====================
MFvwObjectTypeSummary
=====================

Purpose
=======

The view shows a summary of MFAuditHistory with the intent to get the number of objects in a class

Additional Info
===============

Use exec spMFObjectTypeUpdateClassIndex to process the data for either an individual or all classes in the vault

Only objects that have an lastmodified date after 2000-01-01 will be included.


Examples
========

.. code:: sql

   Select * from MFvwObjectTypeSummary order by class

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-08-27  LC         Repoint view to MFAuditHistory table and add columns
2019-04-11  LC         Extend view
2018-07-12  LC         Create view
==========  =========  ========================================================

**rST*************************************************************************/

ALTER VIEW [dbo].[MFvwObjectTypeSummary]
AS
WITH [cte]
AS (
   SELECT [mottco].[ObjectType]
         ,[mottco].[Class]
         ,COUNT(*)                    [RecordCount]
         ,MAX([mottco].[Objid]) [MaximumObjid]
		 ,MAX(mottco.TranDate) AS lastUpdated
         ,(SELECT COUNT(*) FROM MFAuditHistory h WHERE h.StatusFlag = 4 AND h.class = mottco.class) AS TotalDeleted
   FROM [dbo].[MFAuditHistory] AS [mottco]
   GROUP BY [mottco].[ObjectType]
           ,[mottco].[Class]),
		   CTE2 as
(SELECT [mc].[Name]  AS [Class]
      ,[mot].[Name] AS [ObjectType]
      ,[cte].[RecordCount]
      ,[cte].[MaximumObjid]
	  ,cte.TotalDeleted
      ,CASE WHEN ISNULL([mc].[IncludeInApp],0) > 0 THEN 1 ELSE 0 END AS IncludedInApp
	  ,cte.lastUpdated
FROM [cte]
    INNER JOIN [dbo].[MFClass]      AS [mc]
        ON [cte].[Class] = [mc].[MFID]
    INNER JOIN [dbo].[MFObjectType] AS [mot]
        ON [cte].[ObjectType] = [mot].MFID)

		SELECT * FROM cte2 

		
GO