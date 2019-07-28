GO
-- ** Required
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserAccount]';
-- ** Required
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserAccount', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: User Account M-Files Metdata data
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
  Select * from MFUserAccount
  
-----------------------------------------------------------------------------------------------*/

--** Only include USE statement if database will ALWAYS be guaranteed  to be the same, i.e. master, msdb, etc.
--USE [Database]


--** Use IF EXISTS syntax if table ALWAYS needs to be dropped before being recreated.
--** WARNING: this could cause loss of data

--** Optional
/*
   IF EXISTS (SELECT name FROM sys.tables WHERE name='MFUserAccount' AND SCHEMA_NAME(schema_id)='dbo')
   BEGIN
		DROP TABLE	dbo.MFUserAccount
		PRINT SPACE(10) + '... Table: dropped'
   END
   
*/  
--** Optional

--** Required
--** Use IF NOT EXISTS syntax if the table should ONLY be created the 1st time
--** This protects against accidential loss of data
IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFUserAccount]
            (
              [UserID] INT NOT NULL ,
              [LoginName] NVARCHAR(250) NULL ,
              [InternalUser] BIT NULL ,
              [Enabled] BIT NULL ,
              [Deleted] BIT
                CONSTRAINT [DF_MFUserAccount_Deleted] DEFAULT ( (0) )
                NULL ,
              CONSTRAINT [PK_MFUserAccount] PRIMARY KEY CLUSTERED
                ( [UserID] ASC ) ,
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFUserAccount')
                        AND name = N'idx_MFUserAccount_User_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFUserAccount_User_id';
        CREATE NONCLUSTERED INDEX idx_MFUserAccount_User_id ON dbo.MFUserAccount (UserID);
    END;

GO
