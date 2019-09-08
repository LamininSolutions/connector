SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFMultiLookupUpsert]'
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFMultiLookupUpsert', -- nvarchar(100)
    @Object_Release = '4.1.5.43', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFMultiLookupUpsert'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].fnMFMultiLookupUpsert
END	
GO

CREATE FUNCTION [dbo].fnMFMultiLookupUpsert (@ItemList NVARCHAR(4000), @ChangeList NVARCHAR(4000),  @UpdateType SMALLINT = 1 )

RETURNS VARCHAR(4000)
AS
/*rST**************************************************************************

=====================
fnMFMultiLookupUpsert
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ItemList nvarchar(4000)
    fixme description
  @ChangeList nvarchar(4000)
    fixme description
  @UpdateType smallint
    fixme description


Purpose
=======

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
     
	 
	DECLARE @ListTable  AS TABLE ( Rowid INT IDENTITY NOT null, ID INT NOT null);
	DECLARE @TempTable AS TABLE ( Rowid INT IDENTITY NOT null, ID INT NOT null);
 -- 1 = add , -1 remove

	
 		IF @UpdateType = 1
	BEGIN

 INSERT INTO @TempTable
 (
     ID
 )

 SELECT listitem from [dbo].[fnMFParseDelimitedString](@ItemList,',') GROUP BY ListItem
UNION 
SELECT listitem from [dbo].[fnMFParseDelimitedString](@ChangeList,',') 

INSERT INTO @ListTable
(
    ID
)

SELECT id FROM @TempTable AS tt GROUP BY tt.ID


	END

	IF @UpdateType = -1
	BEGIN

	INSERT INTO @ListTable
 (
     ID
 )
	 SELECT listitem from [dbo].[fnMFParseDelimitedString](@ItemList,',') GROUP BY ListItem

    DELETE FROM @ListTable WHERE id IN (SELECT listitem from [dbo].[fnMFParseDelimitedString](@ChangeList,',') )

	END
	DECLARE @ReturnList NVARCHAR(4000)

	SELECT @ReturnList = COALESCE(@ReturnList + ',','') + CAST(id as NVARCHAR(10)) FROM @ListTable AS [lt]

  RETURN @ReturnList
  END
GO
