
SET NOCOUNT ON 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Property MFiles Metadata 	
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
  Select * from MFProperty
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProperty]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProperty', -- nvarchar(100)
    @Object_Release = '2.0.2.3', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProperty'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFProperty]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] VARCHAR(100) NOT NULL ,
              [MFID] INT NOT NULL ,
              [ColumnName] VARCHAR(100) NULL ,
              [MFDataType_ID] INT NULL ,
              [PredefinedOrAutomatic] BIT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFProperty__Modify] DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFProperty__Create] DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT NULL ,
              [MFValueList_ID] INT NULL ,
              CONSTRAINT [PK_MFProperty] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [FK_MFProperty_MFValueList] FOREIGN KEY ( [MFValueList_ID] ) REFERENCES [dbo].[MFValueList] ( [id] ) ,
              CONSTRAINT [TUC_MFProperty_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFProperty')
                        AND name = N'idx_MFProperty_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFProperty_MFID';
        CREATE NONCLUSTERED INDEX idx_MFProperty_MFID ON dbo.MFProperty (MFID);
    END;


--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Per MF DataTypes' )
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Per MF DataTypes', @level0type = N'SCHEMA',
        @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFProperty', @level2type = N'COLUMN',
        @level2name = N'MFDataType_ID';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents all the properties of the selected vault' )
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Represents all the properties of the selected vault',
        @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFProperty';

go
