SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Settings sets all the global parameters for the connector. Users can add additional settings for
	special applications but standard settings should not be changed or deleted.
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			Change primary key to include source_key
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from Settings
  
-----------------------------------------------------------------------------------------------*/
--DROP TABLE settings

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFSettings]';

GO

EXEC setup.spMFSQLObjectsControl @SchemaName = 'dbo',
@ObjectName = N'MFSettings', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
	


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFSettings'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE dbo.MFSettings
            (
              [id] [INT] IDENTITY(1, 1)
                         NOT NULL ,
              [source_key] [NVARCHAR](20) NULL ,
              [Name] [VARCHAR](50) NOT NULL ,
              [Description] [VARCHAR](500) NULL ,
              [Value] [SQL_VARIANT] NOT NULL ,
              [Enabled] [BIT] NOT NULL ,
              CONSTRAINT [PK_MFSettings] PRIMARY KEY CLUSTERED ( [id] ASC )
                WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,
                       IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON,
                       ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
				
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################


IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('dbo.MFSettings')
                        AND name = N'idx_MFSettings_name' ) 
	DROP INDEX idx_MFSettings_name ON dbo.MFSettings
	GO

        PRINT SPACE(10) + '... Index: idx_MFSettings_name';
        CREATE NONCLUSTERED INDEX idx_MFSettings_name ON dbo.MFSettings ([source_key],[name])
	GO
  IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFSettings')
                        AND name = N'idx_MFSettings_id' )
	DROP INDEX idx_MFSettings_id ON dbo.MFSettings
	GO
		PRINT SPACE(10) + '... Index: idx_MFSettings_id';
		CREATE NONCLUSTERED INDEX idx_MFSettings_id ON dbo.MFSettings (id)
	GO


	IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFSettings')
                        AND name = N'udx_MFSettings_name' )
  
	ALTER TABLE dbo.MFSettings
	DROP CONSTRAINT  udx_MFSettings_name 
	GO
    
		PRINT SPACE(10) + '... Index: udx_MFSettings_name';
		ALTER TABLE dbo.MFSettings
		ADD CONSTRAINT udx_MFSettings_name UNIQUE ([source_key],[name])
	go






