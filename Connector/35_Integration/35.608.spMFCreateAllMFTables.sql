PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreateAllMFTables]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateAllMFTables', -- nvarchar(100)
    @Object_Release = '4.4.13.53', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
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

ALTER PROCEDURE [dbo].[spMFCreateAllMFTables] 
@IncludedInApp INT = 1,
@Debug SMALLINT = 0
AS
/*rST**************************************************************************

=====================
spMFCreateAllMFTables
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IncludedInApp int 
    Default = 1
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Create all Class Tables for IncludedinApp = 1 by default, or as set in the @IncludedInApp parameter 

Examples
========

.. code:: sql

    EXEC [spMFCreateAllMFTables]

-----
    or

.. code:: sql

     UPDATE mc
     SET [mc].[IncludeInApp] = 4
     FROM MFclass mc
     INNER JOIN MFObjectType mo
     ON [mo].[ID] = [mc].[MFObjectType_ID]
     WHERE mo.name = 'Document' AND [mc].[IncludeInApp] IS NULL

    EXEC [spMFCreateAllMFTables] = 4

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-26  LC         Add parameter to allow for setting up custom list for creating tables
2019-08-30  JC         Added documentation
2016-04-01  DEV2       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

    BEGIN
        IF @Debug > 0
            SELECT  Name
            FROM    MFClass
            WHERE   IncludeInApp = @IncludedInApp;

        DECLARE @tableName VARCHAR(MAX);
        DECLARE tbCursor CURSOR
        FOR
            SELECT  TableName
            FROM    MFClass
            WHERE   IncludeInApp = @IncludedInApp;
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

