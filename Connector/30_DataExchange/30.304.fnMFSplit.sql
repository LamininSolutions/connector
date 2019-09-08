SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplit]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplit', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplit'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
	CREATE FUNCTION [dbo].[fnMFSplit] ( )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(50)
      )
       WITH EXECUTE AS CALLER
AS
    BEGIN
		INSERT @tblList( [ListItem] )
		VALUES  ( 'not implemented' )
        RETURN 
    END
	GO
SET NOEXEC OFF
	GO
alter FUNCTION [dbo].[fnMFSplit] (@PropertyIDs     VARCHAR(MAX)
                               ,@PropertyValues VARCHAR(MAX)
                               ,@Delimiter      CHAR(1))
RETURNS @temptable TABLE (
  PropertyID    VARCHAR(MAX),
  PropertyValue VARCHAR(MAX))
AS
/*rST**************************************************************************

=========
fnMFSplit
=========

Return
  - 1 = Success
  - -1 = Error
Parameters
  @PropertyIDs varchar(max)
    Multiple property id's separated by ',' ie: 1,2,3
  @PropertyValues varchar(max)
    Multiple property values's separated by ',' ie: a,b,c
  @Delimiter char
    Delimiter, i.e. ','

Purpose
=======

Converts a delimited list into a table

Examples
========

.. code:: sql

    SELECT * FROM dbo.fnMFSplit('1,2,3','a,b,c',',')

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2014-09-13  AC         Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      DECLARE @idx   INT
              ,@idx1 INT
      DECLARE @slice   VARCHAR(8000)
              ,@slice1 VARCHAR(8000)

      SELECT @idx = 1

      IF Len(@PropertyIDs) < 1
          OR @PropertyIDs IS NULL
        RETURN

      WHILE @idx != 0
        BEGIN
            SET @idx = Charindex(@Delimiter, @PropertyIDs)

            IF @idx != 0
              SET @slice = LEFT(@PropertyIDs, @idx - 1)
            ELSE
              SET @slice = @PropertyIDs

            SET @idx1 = Charindex(@Delimiter, @PropertyValues)

            IF @idx1 != 0
              SET @slice1 = LEFT(@PropertyValues, @idx1 - 1)
            ELSE
              SET @slice1 = @PropertyValues

            IF ( Len(@slice) > 0 )
              INSERT INTO @temptable
                          (PropertyID,
                           PropertyValue)
              VALUES      ( @slice,
                            @slice1 )

            SET @PropertyIDs = RIGHT(@PropertyIDs, Len(@PropertyIDs) - @idx)
            SET @PropertyValues = RIGHT(@PropertyValues, Len(@PropertyValues) - @idx1)

            IF Len(@PropertyIDs) = 0
              BREAK
        END

      RETURN
  END;
  go
  
