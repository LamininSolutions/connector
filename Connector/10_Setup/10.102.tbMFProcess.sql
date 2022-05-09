SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Create Process Table	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-9-1		LC			Change table to MFProcess, extend use of table to be included in logging
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from Process; Process data describe the keys used as the process_id in the class tables.
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProcess]';

GO

EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'MFProcess', -- nvarchar(100)
    @Object_Release = '4.9.29.73', -- varchar(50)
    @UpdateFlag = 2 -- smallint



IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProcess'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE MFProcess
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(50) NOT NULL ,
              [Description] VARCHAR(1000) NULL ,
              [ModifiedOn] VARCHAR(40)
                CONSTRAINT [DEF_MFProcess_ModifiedOn] DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFProcess] PRIMARY KEY CLUSTERED ( [ID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFProcess')
                        AND name = N'idx_MFProcess_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_Process_id';
        CREATE NONCLUSTERED INDEX idx_MFProcess_id ON dbo.MFProcess (ID);
    END;

--DATA #########################################################################################################################3#######
/* Example1:
	DELETE Process
	INSERT Process VALUE(...)

   Example2:
	INSERT Process
	....
 	FROM Process trg
	WHERE NOT EXISTS(Select 1 from Process src where src.id = trg.id)
*/

PRINT SPACE(10) + 'INSERTING DATA INTO TABLE: MFProcess ';

SET IDENTITY_INSERT [dbo].[MFProcess] ON; 

DELETE  FROM [dbo].[MFProcess]
WHERE   ID IN ( 0, 1, 2, 3, 4,10,11,12,13 );

INSERT  [dbo].[MFProcess]
        ( [ID], [Name], [Description], [ModifiedOn] )
VALUES  ( 1, N'From M-Files', N'Set by Connector to show record updated from M-Files',
          GETDATE() ),
        ( 0, N'To M-Files', N'Set by user to show record to be updated to M-Files',
          GETDATE() ),
        ( 2, N'SyncronisationError',
          N'Set by Connector to show Syncronisation errors', GETDATE() ),
        ( 3, N'MFError', N'Set by Connector to show record with MFiles error',
          GETDATE() ),
        ( 4, N'SQLError', N'Set by Connector to show record with SQL error',
          GETDATE() ),
          ( 10, N'Object Version', N'Set in procedure to get latest Object Version',
          GETDATE() ),
          ( 11, N'Version Change', N'Set in procedure to get object change history ',
          GETDATE() ),
          ( 12, N'Delete/Destroy', N'Set in procedure to Delete or Destroy object',
          GETDATE() ),
          ( 13, N'Undelete', N'Set in procedure to Undelete an object',
          GETDATE() );

SET IDENTITY_INSERT [dbo].[MFProcess] OFF;

PRINT SPACE(10) + 'INSERTING DATA COMPLETED: Process ';

--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql
/* Example: 
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Process TO public
*/
GO

