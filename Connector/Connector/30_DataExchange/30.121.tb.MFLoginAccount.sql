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

Used By
=======

- spMFDropAndUpdateMetadata
- spMfGetProcessStatus
- spMFInsertLoginAccount
- spMFProcessBatch\_EMail
- spMFSetup\_Reporting


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
go
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Login Accounts for Vault	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-8-22		LC			Add MFID as a column to the table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFLoginAccount
  
-----------------------------------------------------------------------------------------------*/



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
              [ID] INT IDENTITY(1, 1)
                       NOT NULL PRIMARY KEY ,
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
