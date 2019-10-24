GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[cardconf].[spMFMetadatacardJson]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'cardconf',   @ObjectName = N'spMFMetadatacardJson', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint



/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: process metadata card json
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-12-10		lc			Add to MFSQLConnector
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

 
SELECT * FROM cardconf.[MFMetadatacard] AS [mcg]

cardconf.spMFMetadatacardJson 'MFVendor_Properties'

-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFMetadatacardJson'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'cardconf' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE cardconf.spMFMetadatacardJson
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


alter proc cardconf.spMFMetadatacardJson (@RuleName nvarchar(128))
as

Begin

SET NOCOUNT ON

--DECLARE @RuleName nvarchar(128) = 'MFVendor_Properties'

DECLARE @Output NVARCHAR(MAX) ,
    @Delimiter NVARCHAR(50) = ',' ,
	@InnerDelimiter nvarchar(5) = '     ,',
    @metadatacard NVARCHAR(MAX)

 with cte_jsonlabels as 
(Select mcp.Rulename, Element = '"Description"', label = '"Contents": ', value = QUOTENAME([description],'"')  from [cardconf].MFmetadatacard AS mcp 
union all
Select rulename,Element = '"Theme"', label = '"DescriptionField": ', value =   from [cardconf].MFmetadatacard AS mcp 
union all
Select rulename,Element = '"Description"', label = '"IsCollapsedByDefault": ', value = CASE WHEN IsCollapsedByDefault = 1 THEN 'true' ELSE 'false' END from [cardconf].MFGroups
union all
Select rulename,cardgroup, label = '"HasHeader": ', value = CASE WHEN HasHeader = 1 THEN 'true' ELSE 'false' END  from [cardconf].MFGroups
union all
Select rulename,cardgroup, label = '"IsDefault": ', value = CASE WHEN IsDefault = 1 THEN 'true' ELSE 'false' END  from [cardconf].MFGroups
union all
Select rulename,cardgroup, label = '"Priority": ', value =  CAST([Priority] AS VARCHAR(5))   from [cardconf].MFGroups
)
--SELECT * FROM cte_jsonlabels

SELECT  @metadatacard = '' + ' "MetadataCard": {  ' + CHAR(10)
        + STUFF((SELECT @Delimiter + QUOTENAME([mcp].[CardGroup], '"')  + ': ' 
		 + '{ ' + char(10) 
		 + STUFF((SELECT @Delimiter + cte_jsonLabels.label  + cte_jsonLabels.value + CHAR(10) 
             FROM   cte_jsonlabels 
                 WHERE  mcp.[CardGroup] = [cte_jsonlabels].cardgroup          
        FOR     XML PATH('') ,
                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1, '')              
		+ '}'
                 FROM   [cardconf].[MFGroups] AS [mcp]
                 WHERE  mcp.Rulename = @RuleName
                 ORDER BY mcp.[Priority]
        FOR     XML PATH('') ,
                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1, '') + '}'

--cte_jsonlabels.RuleName = @RuleName AND 

--PRINT @metadatacard

END

Go