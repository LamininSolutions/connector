SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFReplaceSpecialCharacter]'
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFReplaceSpecialCharacter', -- nvarchar(100)
    @Object_Release = '4.10.30.75', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
*/

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFReplaceSpecialCharacter'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFReplaceSpecialCharacter]
END	
GO

CREATE FUNCTION [dbo].[fnMFReplaceSpecialCharacter] (@ColumnName [NVARCHAR](2000))
RETURNS VARCHAR(2000)
AS
/*rST**************************************************************************

===========================
fnMFReplaceSpecialCharacter
===========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ColumnName nvarchar(2000)
    fixme description

Purpose
=======

Replace special characters

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-02-15  LC         add pipe sign to exclusions
2019-08-30  JC         Added documentation
2019-08-06  LC         Add brackets as exclusion
2017-12-03  LC         Fix bug of adding 2 underscores
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      -------------------------------------
      --Replace Special Characters
      -------------------------------------

	    DECLARE @expres AS NVARCHAR(100) = '[|~|@|#|$|%|&|/|\|,|^|+|<|>||:|;||?|"|*|(|)|]|-|.|!'
	DECLARE @patern NVARCHAR(5)
	DECLARE @charlist AS TABLE (id INT IDENTITY, Item NVARCHAR(5))
	DECLARE @ID INT = 1
	DECLARE @item NVARCHAR(5)

	INSERT INTO @charlist
	(
	    [Item]
	)
	SELECT item FROM [dbo].[fnMFSplitString](@expres,'|')

      WHILE @id IS NOT NULL
      BEGIN
      SELECT @item = Item,

	   @patern = '%['+Item + ']%' 
	  FROM @charlist AS [c] WHERE id = @ID
--	  SELECT @patern AS Patern, Patindex(@patern,@Columnname) AS patind
		 SET @ColumnName = Replace(@ColumnName, @item, '')
		SELECT @id = (SELECT MIN(Id) FROM @charlist AS [c] WHERE id > @id)

		END

      ----------------------------------         
      --Capitalize the First Letter
      ----------------------------------
      SET @ColumnName = dbo.fnMFCapitalizeFirstLetter(@ColumnName)
      ----------------------------------
      --Replace ' ' with '_'
      ----------------------------------
      SET @ColumnName = Replace(@ColumnName, '  ', '_') --two spaces
	  SET @ColumnName = Replace(@ColumnName, ' ', '_') --one space
      SET @ColumnName =replace(@ColumnName,'|','_') -- delimiter character
	

      RETURN @ColumnName
  END

GO
