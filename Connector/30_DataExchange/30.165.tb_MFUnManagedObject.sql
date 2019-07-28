SET NOCOUNT ON; 
GO
/*----------DevTeam 2, Laminin Solutions
	Create date: 2019-02
	Database: 
	Description: UnManaged Metadata 	
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
  Select * from MFUnManagedObject

  Alter table MFUnManagedObject
  

  
  DROP TABLE MFUnManagedObject
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUnmanagedObject]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUnmanagedObject', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUnmanagedObject'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

	CREATE TABLE [dbo].[MFUnmanagedObject]
	(
	 [ID] INT IDENTITY (1,1) NOT NULL
	,[Name_Or_Title] NVARCHAR(100)
	,[Remote_Vault_Guid]  NVARCHAR(100)
	,[Location_ID] NVARCHAR(250)
	,[Repository_ID] NVARCHAR(250)
	,[Status_Changed] DATETIME
	,[Created] DATETIME
	,[MF_Last_Modified] DATETIME CONSTRAINT [DF_MFUnmanagedObject_MF_Last_Modified] DEFAULT(GETDATE()) NOT NULL
	,Process_ID INT
	,Single_File BIT
	,Class_ID NVARCHAR(50) 
	,External_ObjectID INT

	CONSTRAINT [PK_MFUnmanagedObject] PRIMARY KEY CLUSTERED([ID] ASC)
	)
   
        

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################






GO





















