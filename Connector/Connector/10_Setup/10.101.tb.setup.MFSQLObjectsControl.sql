SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Description: MFSQLObjectsColtrol have a listing of all the objects included in the MFSQL Connector
	 as standard application objects and the release version of the specific object
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
  Select * from setup.MFSQLObjectsControl
  
-----------------------------------------------------------------------------------------------*/
--DROP TABLE settings

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[setup].[MFSQLObjectsControl]';

GO

/*
CREATE TABLE IF NOT EXIST
*/
IF NOT EXISTS ( SELECT  object_id
                FROM    sys.objects
				INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                WHERE   objects.name = 'MFSQLObjectsControl' AND s.name = 'setup' )
    BEGIN

        CREATE TABLE Setup.MFSQLObjectsControl
            (
              id INT IDENTITY ,
              [Schema] VARCHAR(100) ,
              Name VARCHAR(100) NOT NULL ,
              [object_id] INT NULL ,
              Release VARCHAR(50) NULL ,
              [Type] VARCHAR(10) NULL ,
              Modify_Date DATETIME NULL
                                   DEFAULT GETDATE(),
				Module int
            );

        PRINT SPACE(10) + '... Table: created';

        IF NOT EXISTS ( SELECT  object_id
                        FROM    sys.indexes
                        WHERE   name = N'idx_MFSQLObjectsControl_name' )
            BEGIN
                PRINT SPACE(10) + '... Index: idx_MFSQLObjectsControl_name';
                CREATE NONCLUSTERED INDEX idx_MFSQLObjectsControl_name ON Setup.MFSQLObjectsControl(Name);

            END;
    END; 

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.COLUMN_NAME = 'Module' AND c.TABLE_NAME = 'MFSQLObjectsControl')
Begin
ALTER TABLE setup.MFSQLObjectsControl
ADD Module INT DEFAULT((0))
END



	go

