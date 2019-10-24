SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFCapitalizeFirstLetter]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFCapitalizeFirstLetter', -- nvarchar(100)
    @Object_Release = '2.1.1.12', -- varchar(50)
    @UpdateFlag = 2 -- smallint
gO
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFCapitalizeFirstLetter'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFCapitalizeFirstLetter]
END	
GO

CREATE FUNCTION [dbo].[fnMFCapitalizeFirstLetter] (@String VARCHAR(250) --STRING NEED TO FORMAT
)
RETURNS VARCHAR(200)
AS
/*rST**************************************************************************

=========================
fnMFCapitalizeFirstLetter
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @String varchar(250)
    Input string to concat words and capitalize first letter of each word

Purpose
=======

Used to capitalize first letter of each word and concatenate it

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2014-09-13  DEV2       Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      -----------------------------
      --DECLARE VARIABLES
      -----------------------------
      DECLARE @Index         INT
              ,@ResultString VARCHAR(250)

      SET @Index = 1
      SET @ResultString = ''

      -------------------------------------------
      --RUN THE LOOP UNTIL END OF THE STRING
      -------------------------------------------
      WHILE ( @Index < Len(@String) + 1 )
        BEGIN
            IF ( @Index = 1 ) --FIRST LETTER OF THE STRING
              BEGIN
                  -------------------------------------------
                  --MAKE THE FIRST LETTER CAPITAL
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Upper(Substring(@String, @Index, 1))
                  -------------------------------------------
                  -------------------------------------------
                  SET @Index = @Index + 1 --increase the index
              END
            --------------------------------------------------------------------------------------
            -- IF THE PREVIOUS CHARACTER IS SPACE OR '-' OR NEXT CHARACTER IS '-'
            --------------------------------------------------------------------------------------
            ELSE IF ( ( Substring(@String, @Index - 1, 1) = ' '
                    OR Substring(@String, @Index - 1, 1) = '-'
                    OR Substring(@String, @Index + 1, 1) = '-' )
                 AND @Index + 1 <> Len(@String) )
              BEGIN
                  -------------------------------------------
                  --MAKE THE LETTER CAPITAL
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Upper(Substring(@String, @Index, 1))
                  SET @Index = @Index + 1 --increase the index
              END
            ELSE -- all others
              BEGIN
                  -------------------------------------------
                  -- MAKE THE LETTER LOWER CASE
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Lower(Substring(@String, @Index, 1))
                  ----------------------------------
                  --INCERASE THE INDEX
                  ----------------------------------
                  SET @Index = @Index + 1
              END
        END --END OF THE LOOP
      --------------------------------------------
      -- ANY ERROR OCCUR RETURN THE SEND STRING
      --------------------------------------------
      IF ( @@ERROR <> 0 )
        BEGIN
            SET @ResultString = @String
        END

      DECLARE @expres AS VARCHAR(50) = '%[~,@,#,$,%,&,/,\,^,'',+,<,>,:,;,?,",*,(,),.,!,-]%'

      WHILE Patindex(@expres, @ResultString) > 0
        SET @ResultString = Replace(@ResultString, Substring(@ResultString, Patindex(@expres, @ResultString), 1), '')

      --------------------------------------------------
      -- IF NO ERROR FOUND RETURN THE NEW STRING
      --------------------------------------------------
      RETURN @ResultString
  END
  go

