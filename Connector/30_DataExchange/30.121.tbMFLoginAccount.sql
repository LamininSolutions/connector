
/*rST**************************************************************************

==============
MFLoginAccount
==============

Columns
=======

ID int (primarykey, not null)
  SQL primary key
AccountName nvarchar(250) (not null)
  Full name of account (e.g. domain\username)
UserName nvarchar(250) (not null)
  Name user sign in with
MFID int
  M-Files internal ID for user
FullName nvarchar(250)
  Given full name in login account properties
AccountType nvarchar(250)
  M-Files or Windows account
DomainName nvarchar(250)
  Domain if windows user account type
EmailAddress nvarchar(250)
  Email in login account properties
LicenseType nvarchar(250)
  Named, concurrent, read only, none
Enabled bit
  1 = enabled
Deleted bit
  1 = deleted in M-Files

Additional Info
===============

The MFLoginAccount will only include objects related to the vault. It does not include all the login accounts on the server.

Relation
========

MFContextMenu columns Last_excecuted_by and ActionUser_ID  relates to MFID in this table

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
2019-09-07  JC         Added documentation
2017-08-22  LC         Add MFID as a column to the table
2016-02-20  LC         Create table
==========  =========  ========================================================

**rST*************************************************************************/
go
SET NOCOUNT ON; 
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLoginAccount]';


GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFLoginAccount', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLoginAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
  
        CREATE TABLE [dbo].[MFLoginAccount]
            (
              [ID] INT IDENTITY(1, 1),
              [AccountName] NVARCHAR(250) not NULL ,
              [UserName] NVARCHAR(250) NOT NULL ,
			  [MFID] INT NULL,
              [FullName] NVARCHAR(250) NULL ,
              [AccountType] NVARCHAR(250) NULL ,
              [DomainName] NVARCHAR(250) NULL ,
              [EmailAddress] NVARCHAR(250) NULL ,
              [LicenseType] NVARCHAR(250) NULL ,
              [Enabled] BIT NULL ,
              [Deleted] BIT
                CONSTRAINT [DF_MFLoginAccount_Deleted] DEFAULT ( (0) )
                NULL 

            );

ALTER TABLE [dbo].[MFLoginAccount] ADD CONSTRAINT [PK__MFLoginAccount_ID] PRIMARY KEY CLUSTERED  ([ID])


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';
	IF NOT EXISTS ( SELECT  name,c.[COLUMN_NAME]
                FROM    sys.tables st
				LEFT JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c]
				ON c.[TABLE_NAME] = st.[name]
                WHERE   name = 'MFLoginAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo'
						AND c.[COLUMN_NAME] = 'MFID'
						 )
	BEGIN
    Alter table MFLoginAccount Add MFID INT
     PRINT SPACE(10) + '... Column MFID added'
	 END


go
