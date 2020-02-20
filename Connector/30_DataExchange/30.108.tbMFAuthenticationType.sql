/*rST**************************************************************************

====================
MFAuthenticationType
====================

Columns
=======

ID int (primarykey, not null)
  fixme description
AuthenticationType varchar(250)
  fixme description
AuthenticationTypeValue varchar(20)
  fixme description

Used By
=======

- MFVaultSettings
- MFvwVaultSettings
- spMFVaultConnectionTest
- FnMFVaultSettings


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuthenticationType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuthenticationType', -- nvarchar(100)
    @Object_Release = '3.1.0.24', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Authentication Type Lookup 
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
  Select * from MFAuthenticationType
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAuthenticationType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFAuthenticationType
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[AuthenticationType] [varchar](250) NULL,
		        [AuthenticationTypeValue] [varchar](20) NULL,
			   CONSTRAINT [PK_MFAuthenticationType] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
       
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Unknown','0')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Current Windows User','1')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Specific Windows User','2')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('M-Files User','3')

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		



