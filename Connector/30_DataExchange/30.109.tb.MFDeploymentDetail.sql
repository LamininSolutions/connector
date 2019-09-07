/*rST**************************************************************************

==================
MFDeploymentDetail
==================

Columns
=======

+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+
| Key                                                | Name               | Data Type       | Max Length (Bytes)   | Nullability    | Identity   |
+====================================================+====================+=================+======================+================+============+
|  Cluster Primary Key PK\_MFDeploymentDetail: ID    | ID                 | int             | 4                    | NOT NULL       | 1 - 1      |
+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+
|                                                    | LSWrapperVersion   | nvarchar(100)   | 200                  | NULL allowed   |            |
+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+
|                                                    | MFilesAPIVersion   | nvarchar(100)   | 200                  | NULL allowed   |            |
+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+
|                                                    | DeployedBy         | nvarchar(250)   | 500                  | NULL allowed   |            |
+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+
|                                                    | DeployedOn         | datetime        | 8                    | NULL allowed   |            |
+----------------------------------------------------+--------------------+-----------------+----------------------+----------------+------------+

Indexes
=======

+----------------------------------------------------+--------------------------+---------------+----------+
| Key                                                | Name                     | Key Columns   | Unique   |
+====================================================+==========================+===============+==========+
|  Cluster Primary Key PK\_MFDeploymentDetail: ID    | PK\_MFDeploymentDetail   | ID            | YES      |
+----------------------------------------------------+--------------------------+---------------+----------+

Used By
=======

- spMFDeploymentDetails


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
	Database: 
	Description: History of deployment runs	
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
  Select * from MFDeploymentDetail
  Drop table MFDeploymentDetail
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFDeploymentDetail]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFDeploymentDetail', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFDeploymentDetail'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFDeploymentDetail]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [LSWrapperVersion] NVARCHAR(100) NULL ,
              [MFilesAPIVersion] NVARCHAR(100) NULL ,
              [DeployedBy] NVARCHAR(250) NULL ,
              [DeployedOn] DATETIME NULL ,
              CONSTRAINT [PK_MFDeploymentDetail] PRIMARY KEY CLUSTERED
                ( [id] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO
