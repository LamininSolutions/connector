GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[cardconf].[spMFCardPropertyJson]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'cardconf',   @ObjectName = N'spMFCardPropertyJson', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint



/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: Procedure to produce the Json script for groups and properties on the metadata card

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

select * from [CardConf].[MFCardRules] AS [mcr]
exec cardconf.spMFCardPropertyJson @Rule_ID = 14, @Debug = 1

-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCardPropertyJson'--name of procedure
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
CREATE PROCEDURE cardconf.spMFCardPropertyJson
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC CardConf.spMFCardPropertyJson (@Rule_ID INT, @Debug SMALLINT = 0)
AS
    BEGIN

        SET NOCOUNT ON;	
		
		IF (SELECT  TOP 1 [mcr].[RuleType] FROM [CardConf].[MFCardRules] AS [mcr] WHERE rule_Id = @Rule_ID) = 'Behaviour'
		begin


        DECLARE @Output NVARCHAR(MAX) ,
            @Delimiter NVARCHAR(50) = ',' ,
            @InnerDelimiter NVARCHAR(5) = '     ,' ,
            @Groups NVARCHAR(MAX);

        CREATE TABLE #MFGroups
            (
              id INT IDENTITY
                     PRIMARY KEY ,
              RuleName VARCHAR(100) ,
              cardgroup VARCHAR(100) ,
              Title VARCHAR(100) ,
              IsCollapsible BIT ,
              IsCollapsedByDefault BIT ,
              HasHeader BIT ,
              IsDefault BIT ,
              [Priority] INT
            );

        INSERT  INTO [#MFGroups]
                ( [RuleName] ,
                  [cardgroup] ,
                  [Title] ,
                  [IsCollapsible] ,
                  [IsCollapsedByDefault] ,
                  [HasHeader] ,
                  [IsDefault] ,
                  [Priority]
	            )
                SELECT DISTINCT
                        mcr.[RuleName] ,
                        mg.[GroupName] AS cardgroup ,
                        mg.[Title] ,
                        mg.[IsCollapsible] ,
                        mg.[IsCollapsedByDefault] ,
                        mg.[HasHeader] ,
                        mg.[IsDefault] ,
                        mg.[Priority]
                FROM    [CardConf].[MFCardRules] AS [mcr]
                        INNER JOIN [CardConf].[MFCardProperties] AS [mp] ON [mp].[Rule_ID] = [mcr].[Rule_ID]
                        INNER JOIN [CardConf].[MFGroups] AS [mg] ON [mg].[Group_ID] = [mp].[Group_ID]
                WHERE   mcr.Rule_ID = @Rule_ID;
            WITH    cte_jsonlabels
                      AS ( SELECT   mcp.RuleName ,
                                    cardgroup ,
                                    label = '"Title": ' ,
                                    value = QUOTENAME(Title, '"')
                           FROM     #MFGroups AS mcp
                           UNION ALL
                           SELECT   RuleName ,
                                    cardgroup ,
                                    label = '"IsCollapsible": ' ,
                                    value = CASE WHEN IsCollapsible = 1
                                                 THEN 'true'
                                                 ELSE 'false'
                                            END
                           FROM     #MFGroups
                           UNION ALL
                           SELECT   RuleName ,
                                    cardgroup ,
                                    label = '"IsCollapsedByDefault": ' ,
                                    value = CASE WHEN IsCollapsedByDefault = 1
                                                 THEN 'true'
                                                 ELSE 'false'
                                            END
                           FROM     #MFGroups
                           UNION ALL
                           SELECT   RuleName ,
                                    cardgroup ,
                                    label = '"HasHeader": ' ,
                                    value = CASE WHEN HasHeader = 1
                                                 THEN 'true'
                                                 ELSE 'false'
                                            END
                           FROM     #MFGroups
                           UNION ALL
                           SELECT   RuleName ,
                                    cardgroup ,
                                    label = '"IsDefault": ' ,
                                    value = CASE WHEN IsDefault = 1
                                                 THEN 'true'
                                                 ELSE 'false'
                                            END
                           FROM     #MFGroups
                           UNION ALL
                           SELECT   RuleName ,
                                    cardgroup ,
                                    label = '"Priority": ' ,
                                    value = CAST([Priority] AS VARCHAR(5))
                           FROM     #MFGroups
                         )
            --SELECT * FROM cte_jsonlabels

SELECT  @Groups = '' + ' "Groups": {  ' + CHAR(10)
        + STUFF((SELECT @Delimiter + QUOTENAME([mcp].[cardgroup], '"') + ': '
                        + '{ ' + CHAR(10)
                        + STUFF((SELECT @Delimiter + cte_jsonlabels.label
                                        + cte_jsonlabels.value + CHAR(10)
                                 FROM   cte_jsonlabels
                                 WHERE  mcp.[cardgroup] = [cte_jsonlabels].cardgroup
                        FOR     XML PATH('') ,
                                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1,
                                '') + '}'
                 FROM   #MFGroups AS [mcp]
                 ORDER BY mcp.[Priority]
        FOR     XML PATH('') ,
                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1,
                '') + '}';

--PRINT @Groups


        DECLARE @Properties NVARCHAR(MAX);

        CREATE TABLE #MFProperties
            (
              id INT IDENTITY
                     PRIMARY KEY ,
              RuleName VARCHAR(100) ,
              PropertyAlias VARCHAR(100) ,
              cardgroup VARCHAR(100) ,
              tooltip VARCHAR(100) ,
			  Label VARCHAR(100),
              [description] VARCHAR(100) ,
              [Priority] INT ,
              SetValue VARCHAR(100) ,
              IsAdditional BIT ,
              IsRequired BIT ,
              IsHidden BIT
            );
        INSERT  INTO [#MFProperties]
                ( [RuleName] ,
                  [PropertyAlias] ,
                  [cardgroup] ,
                  tooltip ,
				  Label,
                  [description] ,
                  [Priority] ,
                  SetValue ,
                  IsAdditional ,
                  IsRequired ,
                  IsHidden 
                )
                SELECT  [mcr].RuleName ,
                        mp2.[Alias] AS PropertyAlias ,
                        mg.[GroupName] AS cardgroup ,
                        mp.[ToolTip] ,
						mp.Label,
                        mp.[Description] ,
                        mp.[Priority] ,
                        mp.[SetValue] ,
                        mp.[IsAdditional] ,
                        [mp].[IsRequired] ,
                        [mp].[IsHidden]
                FROM    [CardConf].[MFCardProperties] AS [mp]
                        INNER JOIN [dbo].[MFProperty] AS [mp2] ON [mp2].[MFID] = mp.[Property_MFID]
                        INNER JOIN [CardConf].[MFGroups] AS [mg] ON [mg].[Group_ID] = [mp].[Group_ID]
                        INNER JOIN [CardConf].[MFCardRules] AS [mcr] ON [mcr].[Rule_ID] = [mp].[Rule_ID]
                WHERE   mcr.Rule_ID = @Rule_ID;

IF @debug = 1
SELECT * FROM [#MFProperties] AS [mp];

        WITH    cte_jsonlabels
                  AS ( SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"Group": ' ,
                                value = QUOTENAME(cardgroup,'"')
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"Tooltip": ' ,
                                value = QUOTENAME(tooltip,'"')
                       FROM     #MFProperties
					    UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"Label": ' ,
                                value = QUOTENAME([label],'"')
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"Description": ' ,
                                value = QUOTENAME([description],'"')
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"Priority": ' ,
                                value = CAST([Priority] AS VARCHAR(15))
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"SetValue": ' ,
                                value = QUOTENAME([SetValue],'"')
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"IsAdditional": ' ,
                                value = CASE WHEN IsAdditional = 1 THEN 'true'
                                             ELSE NULL
                                        END
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"IsRequired": ' ,
                                value = CASE WHEN [IsRequired] = 1 THEN 'true'
                                             ELSE NULL
                                        END
                       FROM     #MFProperties
                       UNION ALL
                       SELECT   RuleName ,
                                PropertyAlias ,
                                label = '"IsHidden": ' ,
                                value = CASE WHEN IsHidden = 1 THEN 'true'
                                             ELSE NULL
                                        END
                       FROM     #MFProperties
                     )


SELECT  @Properties = '' + ' "Properties": {  ' + CHAR(10)
        + STUFF((SELECT @Delimiter + QUOTENAME([mcp].[PropertyAlias], '"')
                        + ': ' + CHAR(10) +  '{ ' 
                        + STUFF((SELECT @Delimiter + cte_jsonlabels.label
                                        + cte_jsonlabels.value
                                        + CHAR(10)
                                 FROM   cte_jsonlabels
                                 WHERE  PropertyAlias = mcp.PropertyAlias
                        FOR     XML PATH('') ,
                                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1,
                                '') + '}'
                 FROM   #MFProperties mcp
                 ORDER BY id
        FOR     XML PATH('') ,
                    TYPE
						).[value]('.', 'nvarchar(max)'), LEN(@Delimiter), 1,
                '') + '}';



        UPDATE  [mcr]
        SET     [mcr].[RuleJson] ='{ ' + @Groups +','+ CHAR(10) + @Properties + '}'
        FROM    [CardConf].[MFCardRules] AS [mcr]
        WHERE   [mcr].[Rule_ID] = @Rule_ID;

		SET @Properties = '{ ' + @Groups +','+ CHAR(10) + @Properties + '}'
		        PRINT @Properties;
        DROP TABLE [#MFGroups];
        DROP TABLE [#MFProperties];
    END;
		END;
		
		GO
									