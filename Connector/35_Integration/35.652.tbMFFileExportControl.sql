

/*rST**************************************************************************

===================
MFFileExportControl
===================

Columns
=======

MFID int  not null
  MFID of the Class


Lastmodified datetime
  Show date and time of last  processing entry 

Additional Info
===============

The MFFileExportControl table is used to setup a multi class export of files and monitor the progress of the export.

Used By
=======

- spMFFileExportMultiClass

The following script will add/Update all classes into the table and set them by default to be inactive

INSERT dbo.MFFileExportControl 
(mfid, active)
select mfid, active from (select class as mfid, active = 0 from MFauditHistory h group by class) s
WHERE NOT EXISTS (SELECT MFID FROM dbo.MFFileExportControl t2 WHERE s.mfid = t2.mfid); 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-02-22  LC         Table created
==========  =========  ========================================================

**rST*************************************************************************/
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFFileExportControl]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFFileExportControl', -- nvarchar(100)
    @Object_Release = '4.10.30.75', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

--drop table MFFileExportControl

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFFileExportControl'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN


CREATE TABLE [dbo].[MFFileExportControl]
    (
      [MFID] INT  NOT NULL 
      ,ObjectType int not null
     ,PathProperty_L1 NVARCHAR(128) NULL
    ,PathProperty_L2 NVARCHAR(128)  NULL
    ,PathProperty_L3 NVARCHAR(128)  null
    ,Active bit default(1)
    ,TotalObjects bigint
    ,TotalFiles bigint
    ,TotalSize bigint
      ,LastModified datetime     
        CONSTRAINT [dbo_MFFileExportControl]
        PRIMARY KEY CLUSTERED ( [MFID] ASC )
    )


END
GO


