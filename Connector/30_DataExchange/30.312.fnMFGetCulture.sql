GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[FnMFGetCulture]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'FnMFGetCulture', -- nvarchar(100)
    @Object_Release = '2.10.32.76', -- varchar(50)
    @UpdateFlag = 2 -- smallint


go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'FnMFGetCulture'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[FnMFGetCulture]
END	
GO
 
create FUNCTION dbo.FnMFGetCulture ()
RETURNS VARCHAR(10)
AS
/*rST**************************************************************************

=================
FnMFGetCulture
=================

Return
  Culture of local database as short string

Purpose
=======

Used to return the culture code for use in Formatting

Examples
========

.. code:: sql

    Declare @Culture nvarchar(10)
	SET @Culture = fnMFGetCulture()

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-05-27  LC         Expand function to deal with us anomolies
2022-11-18  LC         Initial Version
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      DECLARE @Culture VARCHAR(10), @language NVARCHAR(100)

      select @culture = CASE WHEN [s].[alias] LIKE '%english%' then 'en-' + SUBSTRING(s.name,1,2)
                         ELSE SUBSTRING(s.name,1,2) END    
    from syslanguages s
    where s.name = @@language;
 
      RETURN @Culture
  END
  
  GO


  