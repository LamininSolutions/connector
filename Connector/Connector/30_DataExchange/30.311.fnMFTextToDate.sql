GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFTextToDate]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFTextToDate', -- nvarchar(100)
    @Object_Release = '4.4.13.53', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFTextToDate'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].fnMFTextToDate
END	
GO

CREATE FUNCTION [dbo].fnMFTextToDate
(    
      @TextDate NVARCHAR(40),
      @Character CHAR 
--      @Format VARCHAR(10) = 'M/D/YYYY'
)
      RETURNS  datetime
AS
/*rST**************************************************************************

==============
fnMFTextToDate
==============

Return
  - 1 = Success
  - 0 = Error
Parameters
  @TextDate NVARCHAR(25)
    Date in text format e.g. 1/13/2009
  @Character char
    Delimiter, i.e. '/'

Purpose
=======

Convert date in text format with different date layouts to datetime

Examples
========

.. code:: sql

    SELECT dbo.fnMFTextToDate('1/13/2009','/')
    Select dbo.fnMFTextToDate('1/13/2009 05:04:22.007','/')
    Select dbo.fnMFTextToDate('1/13/2009 05:04:22.007 a.m.','/')
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-25  LC         Expand function to include other formats for general use
2019-09-10  LC         Create function for use in licensing
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN

       DECLARE @Day VARCHAR(2), @Month VARCHAR(2), @Year VARCHAR(4), @Date datetime
       DECLARE @parselist AS TABLE (id INT, listitem VARCHAR(4))

IF LEN(@TextDate) < 11
Begin

--SELECT 'Short form date'

       INSERT INTO @parselist
       (
           [id]
          ,[listitem]
       )
       SELECT id, listitem FROM [dbo].[fnMFParseDelimitedString](@TextDate,@Character) AS [fmpds]
       SELECT @Day = listitem FROM @parselist AS [p] WHERE id = 2
       SELECT @month =  listitem FROM @parselist AS [p] WHERE id = 1
       SELECT @Year =  listitem FROM @parselist AS [p] WHERE id = 3

       SELECT @Date = CONVERT(DATE,@year+'-'+@month+'-'+@day)
 
      END --text is date on '01/01/2009'
IF ISDATE(@TextDate) = 0 AND (CHARINDEX('a',@TextDate,11) = 0 and CHARINDEX('p',@TextDate,11) = 0)
BEGIN 

--SELECT 'Text is date'

       SELECT @Date = CONVERT(DATETIME,@TextDate,105)

END --include time 

IF ISDATE(@TextDate) = 0 AND (CHARINDEX('a',@TextDate,11) > 0 OR CHARINDEX('p',@TextDate,11) > 0)
BEGIN 

--SELECT 'Text is not date'

IF CHARINDEX('a',@TextDate,11) > 0
Select @TextDate = REPLACE(@TextDate,'a.','AM');
IF CHARINDEX('p',@TextDate,11) > 0
Select @TextDate = REPLACE(@TextDate,'p.','PM');

SELECT @TextDate = REPLACE(@TextDate,'m.','')
       SELECT @Date = CONVERT(DATEtime2,@TextDate,105)

END --include time 
 --       SELECT @DateTime
      RETURN @Date
 END 
 GO

