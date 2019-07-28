PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreateAllMFTables]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateAllMFTables', -- nvarchar(100)
    @Object_Release = '2.0.2.4', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-03
	Database: 
	Description: Create all Class Tables where Included in App is 1 or 2
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
  EXEC [spMFCreateAllMFTables] 1  
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCreateAllMFTables'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFCreateAllMFTables]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCreateAllMFTables] @Debug SMALLINT = 0
AS
    BEGIN
        IF @Debug > 0
            SELECT  Name
            FROM    MFClass
            WHERE   IncludeInApp IN ( 1, 2 );

        DECLARE @tableName VARCHAR(MAX);
        DECLARE tbCursor CURSOR
        FOR
            SELECT  TableName
            FROM    MFClass
            WHERE   IncludeInApp IN ( 1, 2 );
        OPEN tbCursor;
        FETCH NEXT FROM tbCursor INTO @tableName;

        WHILE ( @@FETCH_STATUS = 0 )
            BEGIN

                IF @Debug > 0
                    SELECT  @tableName;

                DECLARE @ActualMFTable VARCHAR(MAX);  
                SET @ActualMFTable = @tableName;

                IF NOT EXISTS ( SELECT  *
                                FROM    INFORMATION_SCHEMA.TABLES
                                WHERE   TABLE_NAME = @ActualMFTable )
                    BEGIN
                        IF @Debug > 0
                            SELECT  @tableName AS 'Table created';
                        DECLARE @ClassTableName VARCHAR(100);

                        SELECT  @ClassTableName = Name
                        FROM    MFClass
                        WHERE   [MFClass].[TableName] = @tableName;

                        EXEC spMFCreateTable @ClassTableName;

                    END;


                FETCH NEXT FROM tbCursor INTO @tableName;

            END;
        CLOSE tbCursor;
        DEALLOCATE tbCursor;

		RETURN 1
    END;


GO

