SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplitString]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplitString', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplitString'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFSplitString]
END	
GO

CREATE FUNCTION [dbo].[fnMFSplitString]
(    
      @Input NVARCHAR(MAX),
      @Character CHAR(1)
)
RETURNS @Output TABLE (
      Item NVARCHAR(1000)
)
AS
/*rST**************************************************************************

===============
fnMFSplitString
===============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Input nvarchar(max)
    Multiple column Name's separated by ',' ie: 1,2,3
  @Character char
    Delimiter, i.e. ','

Purpose
=======

Used to Converts a delimited list into a table

Examples
========

.. code:: sql

    SELECT * FROM dbo.fnSplitString('a,b,c',',')

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2015-05-14  DEV2       Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
      DECLARE @StartIndex INT, @EndIndex INT
 
      SET @StartIndex = 1
      IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @Character
      BEGIN
            SET @Input = @Input + @Character
      END
 
      WHILE CHARINDEX(@Character, @Input) > 0
      BEGIN
            SET @EndIndex = CHARINDEX(@Character, @Input)
           
            INSERT INTO @Output(Item)
            SELECT SUBSTRING(@Input, @StartIndex, @EndIndex - 1)
           
            SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))
      END
 
      RETURN
END

GO
