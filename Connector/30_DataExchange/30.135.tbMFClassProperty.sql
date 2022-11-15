/*rST**************************************************************************

===============
MFClassProperty
===============

Columns
=======

MFClass\_ID int (primarykey, not null)
  ID column of MFClass
MFProperty\_ID int (primarykey, not null)
  ID column of MFProperty
Required bit (not null)
  If the property is required on the class
RetainIfNull bit 
  If set to 1 then property is additional property then property will be added to metadata card if null
IsAdditional bit
  Updated by system to indicate that property is not on defined on the structure as part of the class

Additional Info
===============

This table is used to index the relationship of Properties with Classes as defined on the metadata card.

The column **Required** show if the property is required on the metadata card in M-files. If the property is required then the column in the class table will be created with a NOT NULL constraint.

All of the columns defined in the MFClassProperty Table for the specified class will be included in the Class Table with the data types defined above

MFClassProperty are used by spMFCreateTable when new MF Class Tables are created. This table maps the properties to specific classes as defined in the the metadata structure.

The ID's on this table refers to the SQL ID on the MFClass and MFProperty tables. It does not refer to the MFID on these tables.

The Required column in this table exposes the required properties in M-Files to SQL and can be used to validate data input in special applications to avoid errors when the record is updated in M-Files.

Indexes
=======

idx\_MFClassProperty\_Property\_ID
  - MFProperty\_ID


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-06  LC         add RetainIfNull and IsAdditional
2020-04-22  LC         create constraints when table is created
2019-09-07  JC         Added documentation
2016-02-10  LC         Create table
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFClassProperty]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', -- nvarchar(128)
 @ObjectName = N'MFClassProperty', -- nvarchar(100)
    @Object_Release = '4.10.30.74', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFClassProperty'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFClassProperty]
            (
              [MFClass_ID] INT NOT NULL ,
              [MFProperty_ID] INT NOT NULL ,
              [Required] BIT NOT NULL ,
              RetainIfNull BIT DEFAULT(0),
              IsAdditional BIT DEFAULT(0)
			  
              CONSTRAINT [PK_MFClassProperty] PRIMARY KEY CLUSTERED
                ( [MFClass_ID] ASC, [MFProperty_ID] ASC ) 

              
            );

 ALTER TABLE [dbo].[MFClassProperty] ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass] ([ID])

ALTER TABLE [dbo].[MFClassProperty] ADD CONSTRAINT [FK_MFClassProperty_MFProperty_ID] FOREIGN KEY ([MFProperty_ID]) REFERENCES [dbo].[MFProperty] ([ID])

        PRINT SPACE(10) + '... Table: created';
    END;

ELSE
Begin
   IF NOT exists(SELECT c.object_ID FROM sys.columns c
   INNER JOIN sys.tables t
   ON c.object_id = t.object_id
   WHERE c.name = 'RetainIfNull' AND t.name = 'MFclassProperty')
   BEGIN
   ALTER TABLE MFClassProperty
   ADD RetainIfNull BIT DEFAULT(0)
   END
    IF NOT exists(SELECT c.object_ID FROM sys.columns c
   INNER JOIN sys.tables t
   ON c.object_id = t.object_id
   WHERE c.name = 'IsAdditional' AND t.name = 'MFclassProperty')
   BEGIN
   ALTER TABLE MFClassProperty
   ADD IsAdditional BIT DEFAULT(0)
   END
   
   PRINT SPACE(10) + '...  Table: Updated';
   END

      PRINT SPACE(10) + '...  Table: Exists';


--INDEXES #############################################################################################################################

-- Foreign Keys


-- Permissions

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFClassProperty')
                        AND name = N'idx_MFClassProperty_Property_ID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFClassProperty_Property_ID';
        CREATE NONCLUSTERED INDEX idx_MFClassProperty_Property_ID ON dbo.MFClassProperty (MFProperty_ID);
    END;

GO

DECLARE @dbrole NVARCHAR(50)
SELECT @dbrole = CAST(value AS NVARCHAR(100)) FROM mfsettings WHERE name = 'AppUserRole'



	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (ID) ON [dbo].[MFClass] '+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (ID) ON [dbo].[MFClass] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (ID) ON [dbo].[MFProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (ID) ON [dbo].[MFProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (MFClass_ID) ON [dbo].[MFClassProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (MFClass_ID) ON [dbo].[MFClassProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (MFProperty_ID) ON [dbo].[MFClassProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (MFProperty_ID) ON [dbo].[MFClassProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )



