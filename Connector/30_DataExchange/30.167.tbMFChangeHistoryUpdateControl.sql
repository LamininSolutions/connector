/*rST**************************************************************************

==================================
MFObjectChangeHistoryUpdateControl
==================================

Columns
=======

ID int (primarykey, not null)
MFTableName (String)
-  class table Name
ColumnNames (string)
-  columnName of property to be included
-  add multiple rows for multiple properties to be included for a class table

Additional info
===============

This table contains the class table name and the property columnname for each change record to be updated.  The class table name must correspond with MFClass and the columnname must correspond with MFProperty for the specific property.

The records in this table must be added and maintained manually. spMFUpdateObjectChangeHistory is dependent on valid records in this table to function.

Used By
=======

- spMFUpdateObjectChangeHistory
- spMFUpdateAllIncludedInAppTables


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-11-04  LC         Create Table
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectChangeHistoryUpdateControl]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectChangeHistoryUpdateControl', -- nvarchar(100)
    @Object_Release = '4.4.13.54', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFObjectChangeHistoryUpdateControl'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';


CREATE TABLE MFObjectChangeHistoryUpdateControl
(ID INT IDENTITY ,
    MFTableName NVARCHAR(200) NOT null,
    ColumnNames NVARCHAR(4000) NOT NULL
)


ALTER TABLE [dbo].[MFObjectChangeHistoryUpdateControl] ADD CONSTRAINT [PK__MFObjectChangeHistoryUpdateControl_ID] PRIMARY KEY CLUSTERED  ([ID])


END

GO

