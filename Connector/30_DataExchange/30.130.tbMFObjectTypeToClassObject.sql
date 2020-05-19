/*rST**************************************************************************

=========================
MFObjectTypeToClassObject
=========================

Description:Object Type to Class Object Table 
This is a special table for indexing all the class tables included in app accross all object types.
This table is updated using the spMFObjectTypeUpdateClassIndex procedure

Columns
=======

ID int (not null)
  ID
ObjectType\_ID int (primarykey, not null)
  Object_Type
Class\_ID int (primarykey, not null)
  Class
Object\_MFID int (primarykey, not null)
  Object
Object\_LastModifiedBy varchar(100)
  Table last modified by
Object\_LastModified datetime
  Table last modified
Object\_Deleted bit
  is Object deleted

Used By
=======

- MFvwObjectTypeSummary
- spMFObjectTypeUpdateClassIndex


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: {Database}
	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from 
  
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectTypeToClassObject]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectTypeToClassObject', -- nvarchar(100)
    @Object_Release = '2.0.2.4', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  name
            FROM    sys.tables
            WHERE   name = 'MFObjectTypeToClassObject'
                    AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

        IF EXISTS ( SELECT  *
                    FROM    sys.foreign_keys
                    WHERE   parent_object_id = OBJECT_ID(N'dbo.MFObjectTypeToClassObject') )
            BEGIN
                ALTER TABLE MFObjectTypeToClassObject
                DROP CONSTRAINT FK_ObjectTypeToClassIndex_Class_ID, FK_ObjectTypeToClassIndex_ObjectType_ID;
            END;

        DROP TABLE MFObjectTypeToClassObject;
    END;

CREATE TABLE [dbo].[MFObjectTypeToClassObject]
    (
      [ID] INT IDENTITY(1, 1)
               NOT NULL ,
      ObjectType_ID INT NOT NULL ,
      Class_ID INT NOT NULL ,
      Object_MFID INT NOT null ,
      Object_LastModifiedBy VARCHAR(100) ,
      Object_LastModified DATETIME ,
      Object_Deleted BIT ,
      CONSTRAINT [PK_MFObjectTypeToClassObject] PRIMARY KEY ( [ObjectType_ID],[Class_ID],[Object_MFID] ) 
     
    );


CREATE NONCLUSTERED INDEX [FKIX_MFObjectTypeToClassObject_Class_ID] ON [dbo].[MFObjectTypeToClassObject] ([Class_ID])
GO
CREATE NONCLUSTERED INDEX [FKIX_MFObjectTypeToClassObject_ObjectType_ID] ON [dbo].[MFObjectTypeToClassObject] ([ObjectType_ID])
GO

GO

PRINT SPACE(10) + '... Table: created';

GO
