SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplitPairedStrings]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplitPairedStrings', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplitPairedStrings'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
	CREATE FUNCTION [dbo].fnMFSplitPairedStrings ( )
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
/*
!~
=========================================================================================
OBJECT:        fnMFSplitPairedStrings
=========================================================================================
OBJECT TYPE:   Table Valued Function
========================================================================================
PARAMETERS:		@PropertyIDs    - multiple property id's separated by ',' ie: 1,2,3
				@PropertyValues - multiple property values's separated by ',' ie: a,b,c
				@Delimiter      - delimiter, i.e. ','
				@Delimiter_MultiLookup - second delimited used to split multilookop value, e.g. '#'
=========================================================================================
PURPOSE:    Converts a delimited list with two pairing columns into a table, caters for a value as a delimited list 
=========================================================================================
DESCRIPTION:  
=========================================================================================
NOTES:        
        SELECT * FROM dbo.fnMFSplitPairedStrings('1,2,3','a,b,c',',','#')      
=========================================================================================
HISTORY:
      09/13/2014 - Arnie Cilliers - Initial Version - QA
	  2017-12-21	leRoux Cilliers	Change name of function.  Allow for including multilookup value with multiDelimiter, change names of parameters


=========================================================================================
~!
*/
alter FUNCTION [dbo].[fnMFSplitPairedStrings] (@PairColumn1     VARCHAR(MAX)
                               ,@PairColumn2 VARCHAR(MAX)
                               ,@Delimiter      CHAR(1)
							   ,@Delimiter_MultiLookup CHAR(1))

RETURNS @temptable TABLE (
  PairColumn1    VARCHAR(MAX),
  PairColumn2 VARCHAR(MAX))
AS
/*rST**************************************************************************

======================
fnMFSplitPairedStrings
======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @PairColumn1 varchar(max)
    fixme description
  @PairColumn2 varchar(max)
    fixme description
  @Delimiter char
    fixme description
  @Delimiter\_MultiLookup char
    fixme description


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      DECLARE @idx   INT
              ,@idx1 INT
      DECLARE @slice   VARCHAR(8000)
              ,@slice1 VARCHAR(8000)

      SELECT @idx = 1

      IF Len(@PairColumn1) < 1
          OR @PairColumn1 IS NULL
        RETURN

      WHILE @idx != 0
        BEGIN
            SET @idx = Charindex(@Delimiter, @PairColumn1)

            IF @idx != 0
              SET @slice = LEFT(@PairColumn1, @idx - 1)
            ELSE
              SET @slice = @PairColumn1

            SET @idx1 = Charindex(@Delimiter, @PairColumn2)

            IF @idx1 != 0
              SET @slice1 = LEFT(@PairColumn2, @idx1 - 1)
            ELSE
              SET @slice1 = @PairColumn2
	  			 
			 SELECT @slice1 = REPLACE(@slice1,@Delimiter_MultiLookup,@Delimiter)

            IF ( Len(@slice) > 0 )
              INSERT INTO @temptable
                          (PairColumn1,
                          PairColumn2)
              VALUES      ( @slice,
                            @slice1 )

            SET @PairColumn1 = RIGHT(@PairColumn1, Len(@PairColumn1) - @idx)
            SET @PairColumn2 = RIGHT(@PairColumn2, Len(@PairColumn2) - @idx1)

            IF Len(@PairColumn1) = 0
              BREAK
        END

      RETURN
  END;
  go
  