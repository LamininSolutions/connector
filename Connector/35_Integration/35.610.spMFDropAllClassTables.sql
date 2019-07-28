PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFDropAllClassTables]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFDropAllClassTables', -- nvarchar(100)
    @Object_Release = '2.0.2.4', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-06
	Database: 
	Description: Drop all Class Tables where Included in App is specified
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
  debug mode
  EXEC [spMFDropAllClassTables] 1, 0  
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDropAllClassTables'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFDropAllClassTables]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFDropAllClassTables] @IncludeInApp int, @Debug SMALLINT = 0
AS
    BEGIN
	SET NOCOUNT ON 
        IF @Debug = 1
            SELECT  Name
            FROM    MFClass
            WHERE   IncludeInApp = @IncludeInApp;

        DECLARE @tableName VARCHAR(MAX);
        DECLARE tbCursor CURSOR
        FOR
            SELECT  TableName
            FROM    MFClass
            WHERE   IncludeInApp = @IncludeInApp;
        OPEN tbCursor;
        FETCH NEXT FROM tbCursor INTO @tableName;

        WHILE ( @@FETCH_STATUS = 0 )
            BEGIN

                IF @Debug = 1
                    SELECT  @tableName;

                DECLARE @ActualMFTable VARCHAR(MAX);  
                SET @ActualMFTable = @tableName;

                IF EXISTS ( SELECT  *
                                FROM    INFORMATION_SCHEMA.TABLES
                                WHERE   TABLE_NAME = @ActualMFTable )
                    BEGIN
								IF @debug = 1
                            PRINT   'Table dropped:' +  @tableName ;

                        DECLARE @ClassTableName VARCHAR(100), @Query NVARCHAR(100);

                        SET @Query = N'Drop Table ' + @TableName;
						EXEC sp_executeSQL @Query

                    END;


                FETCH NEXT FROM tbCursor INTO @tableName;

            END;
        CLOSE tbCursor;
        DEALLOCATE tbCursor;


    END;

	RETURN 1

GO

