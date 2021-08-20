

GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwTableID]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwTableID', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwTableID'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW dbo.MFvwTableID
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
		
ALTER VIEW dbo.MFvwTableID
AS

/*rST**************************************************************************

============
MFvwTableID
============

Purpose
=======

Internally used view to regulate unique table names, used with fnMFVariableTableName

Examples
========

.. code:: sql

    Select * from MFvwTableID
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-27  LC         Add documentation
2018-08-15  LC         Create view
==========  =========  ========================================================

**rST*************************************************************************/


select newid() as new_id


GO
