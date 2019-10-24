
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFModule]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFLicenseModule', -- nvarchar(100)
    @Object_Release = '3.1.5.42', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2
	Create date: 2018-03
	Database: 
	Description: MFMOdule Validation for licensing.
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2018-7-09		LC			Change name of table to to conflicts in class Table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFModule
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLicenseModule'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        
		CREATE TABLE [dbo].[MFLicenseModule]
		(
			[Id] [INT] IDENTITY(1,1) NOT NULL,
			[ModuleID] [NVARCHAR](10) NULL,
			[ExpiryDate] [DATETIME] NULL,
			[VaultName] [NVARCHAR](4000) NULL,
			LicenseErrorMessage nvarchar(250),
			ModuleErrorMessage nvarchar(250),
			LicenseKey NVARCHAR(250),
			[DateCreated] [DATETIME] NULL,
			[DateModified] [DATETIME] NULL,
		PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]



        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

	GO
