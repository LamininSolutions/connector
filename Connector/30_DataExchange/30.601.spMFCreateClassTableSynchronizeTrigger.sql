

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateClassTableSynchronizeTrigger]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateClassTableSynchronizeTrigger', -- nvarchar(100)
    @Object_Release = '2.0.2.5', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-03
	Database: 
	Description: Procedure to create triggers for syncronisation on class tables
	This procedure is excecuted when the Table is being created.
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

  EXEC [spMFCreateClassTableSynchronizeTrigger]   @TableName = 'MFContactPerson'

  EXEC [spMFCreateClassTableSynchronizeTrigger]   @TableName = 'MFSoftwareOther'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFCreateClassTableSynchronizeTrigger'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCreateClassTableSynchronizeTrigger]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

Alter PROCEDURE spMFCreateClassTableSynchronizeTrigger @TableName sysname, @Debug BIT = 0
As

DECLARE @SQL NVARCHAR(MAX)
--DECLARE @tableName sysname = 'MFContactPerson'

IF EXISTS(SELECT * FROM sys.objects WHERE name = 't'+@TableName +'Synchronize')
BEGIN


SET @SQL = N'
DROP TRIGGER t'+ @TableName +'Synchronize'
	EXEC sp_executeSQL @SQL
	IF @debug > 0
	PRINT 'Trigger dropped';
	END
;


SET @SQL = N'CREATE TRIGGER [dbo].[t'+@TableName +'Synchronize] ON '+QUOTENAME(@TableName)+ '
    AFTER insert, UPDATE 
AS
    /*------------------------------------------------------------------------------------------------
	Author: System Generated, Laminin Solutions
	Description: Trigger immediate update of M-Files					
				 Executed when ever [process_id] is 1

				 This Trigger is automatically created when spMFCreateTable is run
------------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  update MFCustomer set Process_id = 1 where id = 1
    
-----------------------------------------------------------------------------------------------*/
    DECLARE @result INT ,
        @Process_id INT,
		@IncludeInApp smallint;

		 DECLARE @type CHAR(1);
      IF EXISTS ( SELECT    *
                  FROM      inserted )
         IF EXISTS ( SELECT *
                     FROM   deleted )
            SET @type = ''U'';
         ELSE
            SET @type = ''I'';
      ELSE
         SET @type = ''D'';


SELECT @IncludeInApp = [MFClass].[IncludeInApp] FROM MFClass WHERE [MFClass].[TableName] = ''' + @TableName + '''

if @Type = ''U''
Begin
    IF UPDATE(process_id) AND @IncludeInApp = 2
        BEGIN
            IF ( SELECT COUNT(*)
                 FROM  '+QUOTENAME(@TableName)+'
                 WHERE  process_id = 1
               ) > 0
                BEGIN
                    EXEC spmfclassTableSynchronize  @TableName = ' + @TableName + ';
                END;                               
        END;
end

if @Type = ''I''
Begin
    IF @IncludeInApp = 2
        BEGIN
            IF ( SELECT COUNT(*)
                 FROM  '+QUOTENAME(@TableName)+'
                 WHERE  process_id = 1
               ) > 0
                BEGIN
                    EXEC spmfclassTableSynchronize  @TableName = ' + @TableName + ';
                END;                               
        END;
end;

'
		--SELECT @SQL

IF @debug > 0
SELECT @SQL;

		EXEC sp_executeSQL @SQL


Go


