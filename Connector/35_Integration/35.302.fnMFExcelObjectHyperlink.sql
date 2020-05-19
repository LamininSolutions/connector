SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFExcelObjectHyperlink]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'fnMFExcelObjectHyperlink', -- nvarchar(100)
    @Object_Release = '4.6.7.58', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
MODIFICATIONS

*/

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFExcelObjectHyperlink'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFExcelObjectHyperlink]
END	
GO

CREATE FUNCTION fnMFExcelObjectHyperlink (
    --Add the parameters for the function here
	@MFTableName NVARCHAR(100)
	,@MFObject_MFID INT	
	,@ObjectGUID	   NVARCHAR(50)
	,@HyperLinkType INT = 1 
    ,@ReferenceColumn nvarchar(100)
	)
RETURNS NVARCHAR(250)
AS
/*rST**************************************************************************

========================
fnMFExcelObjectHyperlink
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFObject\_MFID int (required)
    the objid column in the class table
  @ObjectGUID nvarchar(50) (required)
    the GUID column in the class table
  @HyperLinkType int
    1 = Desktop show
    2 = Web App
  @ReferenceColumn nvarchar(100)
   the column in the class table to be used as the label for the link (e.g. name_or_title)

Purpose
=======

Show a M-Files Object Hyperlink specifically formatted as a link in a excel spreadsheet
Use this function in the select statement for a view that is used in excel.

Additional Info
===============

The reference column is used to set the display of the link in excel to show this column, instead of the link.

Examples
========

.. code:: sql

   --desktop - show (option 1)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],1) from [dbo].[MFAccount] AS mc

   --web (option 2)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],2) from [dbo].[MFAccount] AS mc


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-05-18  LC         Update documentation
2019-08-30  JC         Added documentation
2019-05-15  LC         Update options available
2017-09-05  LC         UPDATE BUG IN URL
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
	/*-------------------------------
    Declare the return variable here
    -------------------------------*/
	DECLARE @VaultGUID	   NVARCHAR(50)
		,@ServerURL	   NVARCHAR(200)
		,@ObjectType	   INT			
		,@Hyperlink	   NVARCHAR(250)
		,@SelectQuery	   NVARCHAR(200)
		,@ParmDefinition  NVARCHAR(500);
    
     --SELECT VAULT GUID
	SELECT @VaultGUID = CAST(value AS NVARCHAR(50))
	FROM [MFSettings] AS [s]
	WHERE NAME = 'VaultGUID' AND [s].[source_key] = 'MF_Default'

	 DECLARE @expres AS VARCHAR(50) = '%[{,}]%'

      WHILE Patindex(@expres, @VaultGUID) > 0
        SET @VaultGUID = Replace(@VaultGUID, Substring(@VaultGUID, Patindex(@expres, @VaultGUID), 1), '')

	--SELECT SERVER URL
	SELECT @ServerURL = CAST(value AS NVARCHAR(250))
	FROM [MFSettings] AS [s]
	WHERE NAME = 'ServerURL' AND [s].[source_key] = 'MF_Default'

	--SELECTING OBJECTTYPE ID
	SELECT @ObjectType = mot.mfid
	FROM [MFClass] AS [mc]
	INNER JOIN [MFObjectType] AS [mot] ON [mot].[ID] = [mc].[MFObjectType_ID]
	WHERE [mc].[TableName] = @MFTableName;

      WHILE Patindex(@expres, @ObjectGUID) > 0
        SET @ObjectGUID = Replace(@ObjectGUID, Substring(@ObjectGUID, Patindex(@expres, @ObjectGUID), 1), '')

	--CREATING HYPERLINK 
	SELECT @Hyperlink = CASE 
            			WHEN @HyperLinkType = 1 
				THEN '=Hyperlink("m-files://show/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID + '","'+  ISNULL(@ReferenceColumn,'Link') +'")'
            WHEN @HyperLinkType = 2
				THEN '=Hyperlink("' + @ServerURL + '/Default.aspx?#' + @VaultGUID + '/object/' + CAST(@ObjectType AS VARCHAR(5)) + '/' + CAST(@MFObject_MFID AS VARCHAR(20)) + '/latest' + '","'+  ISNULL(@ReferenceColumn,'Link') +'")'
			END;
	
	RETURN @Hyperlink;
END;
go


