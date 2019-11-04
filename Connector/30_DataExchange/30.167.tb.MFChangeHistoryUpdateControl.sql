/*rST**************************************************************************

==================================
MFObjectChangeHistoryUpdateControl
==================================

Columns
=======

ID int (primarykey, not null)
MFTableName (String)
	class table Name
ColumnNames (string)

Used By
=======

- spMFUpdateTableinBatches


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
(ID INT IDENTITY PRIMARY KEY ,
    MFTableName NVARCHAR(200) NOT null,
    ColumnNames NVARCHAR(4000) NOT NULL
)

END

GO

