/*rST**************************************************************************

=============
MFUserAccount
=============

Columns
=======

UserID int (primarykey, not null)
  M-Files internal ID for user
LoginName nvarchar(250)
  Name user sign in with
InternalUser bit
  - 1 = Internal user
  - 0 = External user
Enabled bit
  1 = enabled
Deleted bit
  1 = deleted in M-Files

Indexes
=======

idx\_MFUserAccount\_User\_id
  - UserID

Additional Info
===============

The table include only user accounts that is related to the specific vault. 

The vaultroles column show three different types of roles
#. Full control of vault
#. Default roles when no special roles are select
#. Various roles when any special roles are selected. This column does not show the individual special roles of the user

Use spMFSynchronizeSpecificMetadata to update the login account or user
account tables after making changes in M-Files.

Updating is from M-Files to SQL only.  Updating from SQL to M-Files is
currently not allowed.

Relation
========

The MFID on the MFLoginAccount is related to UserID on MFUserAccount

.. code:: sql

         SELECT * FROM [dbo].[MFLoginAccount] AS [mla]
         LEFT JOIN [dbo].[MFUserAccount] AS [mua]
         ON mla.mfid = mua.[UserID]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-11-30  LC         Fix incorrect default value and upgrade to include vault roles
2023-06-30  LC         Add vaultroles column
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
GO
-- ** Required
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserAccount]';
-- ** Required
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserAccount', -- nvarchar(100)
    @Object_Release = '4.10.32.76', -- varchar(50)
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
              [Deleted] bit              
              CONSTRAINT [DF_MFUserAccount_Deleted] DEFAULT ( (0) )
                NULL 
              CONSTRAINT [PK_MFUserAccount] PRIMARY KEY CLUSTERED
                ( [UserID] ASC ) ,
            );

        PRINT SPACE(10) + '... Table: created';
    END;
else


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

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.columns AS c WHERE c.TABLE_NAME = 'MFUserAccount' AND Column_Name = 'VaultRoles')
    BEGIN
        PRINT SPACE(10) + '... Add Column: VaultRoles';
ALTER TABLE dbo.MFUserAccount
add VaultRoles nvarchar(100) null ;
END

