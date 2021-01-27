SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFMultiLookupUpsert]';
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'fnMFMultiLookupUpsert', -- nvarchar(100)
                                 @Object_Release = '4.6.15.56',           -- varchar(50)
                                 @UpdateFlag = 2;                        -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'fnMFMultiLookupUpsert' --name of procedire
          AND ROUTINE_TYPE = 'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    DROP FUNCTION dbo.fnMFMultiLookupUpsert;
END;
GO

CREATE FUNCTION dbo.fnMFMultiLookupUpsert
(
    @ItemList NVARCHAR(4000),
    @ChangeList NVARCHAR(4000),
    @UpdateType SMALLINT = 1
)
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
    comma delimited list of items to add or remove
  @ChangeList nvarchar(4000)
    list to be changed
  @UpdateType smallint
    default = 1 - Add items in @itemlist to @ChangeList
    set to -1 to remove items in @itemlist from @changelist

Purpose
=======

This function is useful when changing the members of a multi lookup property. For example change a list "21,35,707" to "35,30"

Examples
========

.. code:: sql

    --update type 1 : add item in @listitem to @changelist 
    DECLARE @listItem NVARCHAR(4000)
    DECLARE @Changelist NVARCHAR(4000)

    SET @ListItem = '4'
    SET @Changelist = '3,5,8'

   SELECT dbo.fnMFMultiLookupUpsert(@listitem,@Changelist,1)

   GO
   --update type -1 : delete item in @listitem from @changelist
   DECLARE @listItem NVARCHAR(4000)
   DECLARE @Changelist NVARCHAR(4000)

   SET @ListItem = '4'
   SET @Changelist = '4,3,5,8'

   SELECT dbo.fnMFMultiLookupUpsert(@listitem,@Changelist,-1)
   GO

   --this returns the @changelist as the updatetype is not 1 or -1
   DECLARE @listItem NVARCHAR(4000)
   DECLARE @Changelist NVARCHAR(4000)

   SET @ListItem = '6'
   SET @Changelist = '4,3,5,8'

   SELECT dbo.fnMFMultiLookupUpsert(@listitem,@Changelist,0)

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-02-20  LC         Fix bug with delete
2020-02-20  LC         Add script to return changelist of type <> 1 or -1
2020-02-20  LC         Update documentation
2019-08-30  JC         Added documentation
2018-06-28  LC         Create function
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN


    DECLARE @ListTable AS TABLE
    (
        Rowid INT IDENTITY NOT NULL,
        ID INT NOT NULL
    );
    DECLARE @TempTable AS TABLE
    (
        Rowid INT IDENTITY NOT NULL,
        ID INT NOT NULL
    );
    -- 1 = add , -1 remove


    IF @UpdateType = 1
    BEGIN

        INSERT INTO @TempTable
        (
            ID
        )
        SELECT ListItem
        FROM dbo.fnMFParseDelimitedString(@ItemList, ',')
        GROUP BY ListItem
        UNION
        SELECT ListItem
        FROM dbo.fnMFParseDelimitedString(@ChangeList, ',');

        INSERT INTO @ListTable
        (
            ID
        )
        SELECT tt.ID
        FROM @TempTable AS tt
        GROUP BY tt.ID;


    END;

    IF @UpdateType = -1
    BEGIN

        INSERT INTO @ListTable
        (
            ID
        )
        SELECT ListItem
        FROM dbo.fnMFParseDelimitedString(@ChangeList, ',')
        GROUP BY ListItem;

        DELETE FROM @ListTable
        WHERE ID IN
              (
                  SELECT ListItem FROM dbo.fnMFParseDelimitedString(@ItemList, ',')
              );

    END;


    DECLARE @ReturnList NVARCHAR(4000);

    IF @Updatetype NOT IN (1,-1)
    Begin
   Select @ReturnList = @ChangeList
   END
   ELSE
   Begin

    SELECT @ReturnList = COALESCE(@ReturnList + ',', '') + CAST(lt.ID AS NVARCHAR(10))
    FROM @ListTable AS lt;
    END
    RETURN @ReturnList;
END;
GO
