GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-09
	Database: 
	Description: MFSyncMethods data list the various specific metadata synchronizaion methods, This table is used in the MFSQL Manager.
  
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from setup.MFSyncMethods; 
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[setup].[MFSyncMethods]';

GO

EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'setup',   @ObjectName = N'MFSyncMethods', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint



IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFSyncMethods'
                        AND SCHEMA_NAME(schema_id) = 'setup' )
    BEGIN
        CREATE TABLE setup.MFSyncMethods
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(50) NOT NULL ,
              
              CONSTRAINT [PK_MFSyncMethods] PRIMARY KEY CLUSTERED ( [ID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--DATA #########################################################################################################################3#######



PRINT SPACE(10) + 'INSERTING DATA INTO TABLE: MFSyncMethods ';



IF (SELECT COUNT(*) FROM setup.[MFSyncMethods] ) = 0
BEGIN
SET IDENTITY_INSERT [Setup].[MFSyncMethods] ON; 
INSERT  [setup].[MFSyncMethods]
        ( id, [Name] )
VALUES  ( 1, N'All')
		,(2,'Class')
		,(3,'Property')
		,(4,'ValueList')
		,(5,'ValueListItems')
		,(6,'Workflow')
		,(7,'States')
		,(8,'ObjectType')
		,(9,'LoginAccount')
		,(10,'UserAccount')

SET IDENTITY_INSERT [Setup].[MFSyncMethods] OFF;

PRINT SPACE(10) + 'INSERTING DATA COMPLETED: [MFSyncMethods] ';
END

GO

