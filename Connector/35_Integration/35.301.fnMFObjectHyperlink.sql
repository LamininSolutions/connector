SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFObjectHyperlink]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'fnMFObjectHyperlink', -- nvarchar(100)
    @Object_Release = '4.3.09.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
MODIFICATIONS

*/

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFObjectHyperlink'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFObjectHyperlink]
END	
GO

CREATE FUNCTION fnMFObjectHyperlink (
    --Add the parameters for the function here
	@MFTableName NVARCHAR(100)
	,@MFObject_MFID INT	
	,@ObjectGUID	   NVARCHAR(50)
	,@HyperLinkType INT = 1 
	)
RETURNS NVARCHAR(250)
AS
/*rST**************************************************************************

===================
fnMFObjectHyperlink
===================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(100) (required)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFObject\_MFID int (required)
    the objid column in the class table
  @ObjectGUID nvarchar(50) (required)
    the GUID column in the class table
  @HyperLinkType int
    Defaults to type 1
    1 - desktop show
    2 - Web link
    3 - desktop view
    4 - desktop open
    5 - desktop show metadata
    6 - desktop edit

Purpose
=======

Use this function in a select statement to have a M-Files Object Hyperlink with different settings

Examples
========

.. code:: sql

   --desktop - show (option 1)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],1) from [dbo].[MFAccount] AS mc

   --web (option 2)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],2) from [dbo].[MFAccount] AS mc

   --desktop - view (option 3)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],3) from [dbo].[MFAccount] AS mc

   --desktop open (option 4)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],4) from [dbo].[MFAccount] AS mc

   --desktop - show metadata (option 5)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],5) from [dbo].[MFAccount] AS mc

   --desktop - edit (option 6)
   select [mc].[name_or_Title] AS Account, [dbo].[fnMFObjectHyperlink]('MFAccount',mc.[objid],mc.[guid],6) from [dbo].[MFAccount] AS mc

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

	--SELECT OBJECT GUID
	--SELECT @ParmDefinition = N'@retvalOUT NVARCHAR(100) OUTPUT';
	--SELECT @SelectQuery = 'SELECT @retvalOUT = GUID FROM ['+@MFTableName+'] WHERE ObjID = '+CAST(@MFObject_MFID AS NVARCHAR(20))+''
	--EXEC Sp_executesql
	--     @SelectQuery
     --     ,@ParmDefinition
	--     ,@retvalOUT = @ObjectGUID OUTPUT;

	/*------------------------------------------------------------------------------------------------------------
    m-files://show/9C2A4835-6C05-4503-8B46-0BCFD78A021E/287-411?object=BE1C9AB2-0BCE-46A0-987F-A0CB03185F17
    https://mfiles.com/Default.aspx?#CE7643CB-C9BB-4536-8187-707DB78EAF2A/object/0/513/latest
    ------------------------------------------------------------------------------------------------------------*/
	/*
	public link
	https://cloud.lamininsolutions.com/SharedLinks.aspx?accesskey=d13c4b71ebd80911ce09310d2cfd429456c420993f8d5289d4da1c5f2fd61e9b&VaultGUID=312E44F6-AE4B-4F5E-8784-9527260A5743
	https://cloud.lamininsolutions.com/SharedLinks.aspx?accesskey=ec02f6e0be6b00b4a4180a736472324042811bb852d312815940a600a23d2240&VaultGUID=312E44F6-AE4B-4F5E-8784-9527260A5743


	*/

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
				THEN 'm-files://show/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID
            WHEN @HyperLinkType = 2
				THEN @ServerURL + '/Default.aspx?#' + @VaultGUID + '/object/' + CAST(@ObjectType AS VARCHAR(5)) + '/' + CAST(@MFObject_MFID AS VARCHAR(20)) + '/latest'
			WHEN @HyperLinkType = 3
				THEN 'm-files://view/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID
			WHEN @HyperLinkType = 4
				THEN 'm-files://open/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID
			WHEN @HyperLinkType = 5
				THEN 'm-files://showmetadata/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID
			WHEN @HyperLinkType = 6
				THEN 'm-files://edit/' + @VaultGUID + '/' + CAST(@ObjectType AS VARCHAR(5)) + '-' + CAST(@MFObject_MFID AS VARCHAR(20)) + '?object=' + @ObjectGUID
			END;
	
	RETURN @Hyperlink;
END;
go


