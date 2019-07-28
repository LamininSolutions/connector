SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFReplaceSpecialCharacter]'
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFReplaceSpecialCharacter', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
2017-12-03	LC fix bug of adding 2 underscores
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
  BEGIN
      -------------------------------------
      --Replace Special Characters
      -------------------------------------
      DECLARE @expres AS VARCHAR(50) = '%[~,@,#,$,%,&,/,\,^,+,<,>,'',:,;,?,",*,(,),.,!,-]%'

      WHILE Patindex(@expres, @ColumnName) > 0
        SET @ColumnName = Replace(@ColumnName, Substring(@ColumnName, Patindex(@expres, @ColumnName), 1), '')

      ----------------------------------         
      --Capitalize the First Letter
      ----------------------------------
      SET @ColumnName = dbo.fnMFCapitalizeFirstLetter(@ColumnName)
      ----------------------------------
      --Replace ' ' with '_'
      ----------------------------------
      SET @ColumnName = Replace(@ColumnName, '  ', '_') --two spaces
	  SET @ColumnName = Replace(@ColumnName, ' ', '_') --one space

	

      RETURN @ColumnName
  END

GO
