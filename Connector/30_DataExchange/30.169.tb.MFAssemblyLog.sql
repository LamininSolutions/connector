/*rST**************************************************************************

=============
MFAssemblyLog
=============

Columns
=======

LogID int (primarykey, not null)
  Log id
SPName nvarchar(max)
  Store procedure name
ProcessBatch_ID
  ID of the related Batch process from MFProcessBatch
CLRMethod
  Method called by Store procedure.  A store procedure could have multiple CLR Methods
CLRSubMethod
  sub method in CLR method
SystemTimestamp
  timestamp of system in assembly
methodStepDetail
  method sub step description
ErrorNumber int
  Assembly error number
ErrorMessage
  Assembly error description
ErrorState nvarchar(max)
  Assembly error state
ErrorSeverity int
  Assembly error severity
ErrorLine int
  Row number of error
CreatedOn datetime
  Datetime of row entry

Indexes
=======


Usage
=====


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------

2022-01-04  LC        Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
go
SET NOCOUNT ON; 
GO


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAssemblyLog]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAssemblyLog', -- nvarchar(100)
    @Object_Release = '4.9.28.73', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAssemblyLog'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
  
        CREATE TABLE [dbo].[MFAssemblyLog]
            (
              [LogID] INT IDENTITY(1, 1)
                          NOT NULL ,
              [SPName] NVARCHAR(100) NULL ,
              [ProcessBatch_ID] INT NULL ,
              [CLRMethod] NVARCHAR(100) NULL ,
              [CLRSubMethod] NVARCHAR(100) NULL ,
              SystemTimestamp DATETIME null,
              [methodStepDetail] NVARCHAR(max) NULL ,
              [ErrorNumber] INT NULL ,
              [ErrorMessage] NVARCHAR(MAX) NULL ,           
              [ErrorState] NVARCHAR(MAX) NULL ,
              [ErrorSeverity] INT NULL ,
              [ErrorLine] INT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF_MFLog_CreatedOn]
                DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFAssemblyLog] PRIMARY KEY CLUSTERED ( [LogID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    BEGIN

        PRINT SPACE(10) + '... Table: exists';
    END;

--FOREIGN KEYS #############################################################################################################################



--INDEXES #############################################################################################################################


--TRIGGERS ################################################################################################################################

--SECURITY ################################################################################################################################

GO


