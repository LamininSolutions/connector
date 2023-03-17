SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFParseDelimitedString]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFParseDelimitedString', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFParseDelimitedString'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
CREATE FUNCTION [dbo].[fnMFParseDelimitedString] ( )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(1000)
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
ALTER FUNCTION [dbo].[fnMFParseDelimitedString]
      (
        @List VARCHAR(MAX)
      , @Delimeter CHAR(1)
      )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(1000)
      )
AS

/*rST**************************************************************************

========================
fnMFParseDelimitedString
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @List varchar(max)
    Delimited list to convert to key value pair tabl
  @Delimeter char
    Delimiter, i.e. ','

Purpose
=======

Converts a delimited list into a table.

Examples
========

.. code:: sql

    SELECT * FROM dbo.fnMFParseDelimitedString('A,B,C',',')

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2017-12-17  LC         Increase size of listitem to ensure that it will catr for longer names
2014-09-13  AC         Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

    BEGIN

        DECLARE @ListItem VARCHAR(1000)
        DECLARE @StartPos INT
              , @Length INT
        WHILE LEN(@List) > 0
              BEGIN
                    SET @StartPos = CHARINDEX(@Delimeter, @List)
                    IF @StartPos < 0
                       SET @StartPos = 0
                    SET @Length = LEN(@List) - @StartPos - 1
                    IF @Length < 0
                       SET @Length = 0
                    IF @StartPos > 0
                       BEGIN
                             SET @ListItem = SUBSTRING(@List, 1, @StartPos - 1)
                             SET @List = SUBSTRING(@List, @StartPos + 1, LEN(@List) - @StartPos)
                       END
                    ELSE
                       BEGIN
                             SET @ListItem = @List
                             SET @List = ''
                       END
                    INSERT  @tblList
                            ( ListItem )
                    VALUES  ( @ListItem )
              END

        RETURN 
    END
	go
	
