/*rST**************************************************************************

=====
MFLog
=====

Columns
=======

LogID int (primarykey, not null)
  Log id
SPName nvarchar(max)
  Store procedure name
Update\_ID int
  Update_ID from MFUpdateHistory
ExternalID nvarchar(50)
  not used
ErrorNumber int
  SQL Error number
ErrorMessage nvarchar(max)
  SQL Error description
ErrorProcedure nvarchar(max)
  Name of procedure with error
ProcedureStep nvarchar(max)
  Procedure step
ErrorState nvarchar(max)
  SQL Error state
ErrorSeverity int
  SQL Error severity
ErrorLine int
  Procedure line reference
CreateDate datetime
  Date of error

Indexes
=======

idx\_MFLog\_id
  - LogID

Usage
=====

SQL errors when a procedure runs will update MFLog table with details of the error.  If Database Mail have been setup the entry in the table will trigger sending an email to the support address in the MFSettings table.

The records in the MFLog table will only show the last 90 days of errors if the agent to delete log history is running.

Errors can be back tracked from this table

To get support send an email to support@lamininsolutions.com and include the following:

   - screenshot of the error
   - details of the actual error from the MFlog table. Copy and past the result of the query below to your email to show the full text

..code:: sql

SELECT TOP 5 ErrorMessage, CreateDate FROM MFlog ORDER BY logid desc

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-11-23  LC         Remove duplicate index on ID
2021-04-08  LC         Update documentation
2019-09-07  JC         Added documentation
2016-01-30  DEV        Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
go
SET NOCOUNT ON; 
GO


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLog]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFLog', -- nvarchar(100)
    @Object_Release = '4.9.27.72', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLog'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
  
        CREATE TABLE [dbo].[MFLog]
            (
              [LogID] INT IDENTITY(1, 1)
                          NOT NULL ,
              [SPName] NVARCHAR(MAX) NULL ,
              [Update_ID] INT NULL ,
              [ExternalID] NVARCHAR(50) NULL ,
              [ErrorNumber] INT NULL ,
              [ErrorMessage] NVARCHAR(MAX) NULL ,
              [ErrorProcedure] NVARCHAR(MAX) NULL ,
              [ProcedureStep] NVARCHAR(MAX) NULL ,
              [ErrorState] NVARCHAR(MAX) NULL ,
              [ErrorSeverity] INT NULL ,
              [ErrorLine] INT NULL ,
              [CreateDate] DATETIME
                CONSTRAINT [DF_MFLog_CreateDate]
                DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFLog] PRIMARY KEY CLUSTERED ( [LogID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    BEGIN

        PRINT SPACE(10) + '... Table: exists';
    END;

--FOREIGN KEYS #############################################################################################################################

--IF NOT EXISTS ( SELECT  *
--                FROM    sys.foreign_keys
--                WHERE   parent_object_id = OBJECT_ID('MFLog')
--                        AND name = N'FK_MFLog_Update_ID' )
--    BEGIN
--        PRINT SPACE(10) + '... Constraint: FK_MFLog_Update_ID';
--        ALTER TABLE dbo.MFLog ADD 
--        CONSTRAINT FK_MFLog_Update_ID FOREIGN KEY (Update_ID)
--        REFERENCES dbo.MFUpdateHistory(Id)
--        ON DELETE NO ACTION;

--    END;

--INDEXES #############################################################################################################################

--IF NOT EXISTS ( SELECT  *
--                FROM    sys.indexes
--                WHERE   object_id = OBJECT_ID('MFLog')
--                        AND name = N'idx_MFLog_id' )
--    BEGIN
--        PRINT SPACE(10) + '... Index: idx_MFLog_id';
--        CREATE NONCLUSTERED INDEX idx_MFLog_id ON dbo.MFLog ([LogID]);
--    END;

--TRIGGERS #########################################################################################################################3#######


-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2015-06-4
-- Description:	Trigger to send email on new error log
-- =============================================

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLog]: Trigger tMF_OnError_SendEmail';
GO

IF EXISTS ( SELECT  *
                FROM    sys.objects
                WHERE   [type] = 'TR'
                        AND [name] = 'tMF_OnError_SendEmail' )
    BEGIN
        
		DROP TRIGGER tMF_OnError_SendEmail

        PRINT SPACE(10) + '...Trigger dropped.';
    END;

 PRINT SPACE(10) + '...Trigger Created.';

 GO

 
Create TRIGGER [dbo].[tMF_OnError_SendEmail] ON [dbo].[MFLog]
    AFTER INSERT
AS
    BEGIN
	;
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

SET NOCOUNT ON 
	        
        DECLARE @MFLog_ID INT;
        SELECT  @MFLog_ID = [Inserted].[LogID]
        FROM    [Inserted];

		DECLARE @EmailProfile NVARCHAR(128), @rc INT

		SELECT @EmailProfile = CAST(value AS NVARCHAR(100)) FROM MFSettings WHERE name = 'SupportEMailProfile'

		EXEC @rc = [dbo].[spMFValidateEmailProfile]
		    @emailProfile = @EmailProfile
		
		IF @rc = 1
        EXEC dbo.spMFLogError_EMail @LogID = @MFLog_ID, @DebugFlag = 0;


    END;


--SECURITY #########################################################################################################################3#######

GO


