
/*
align valuelist items where names of valuelist items have changed
*/


--workflows & valuelists to evaluate

CREATE TABLE #Alllookups ( ColumnName NVARCHAR(100), Valuelist_ID INT, Valuelist NVARCHAR(100), ValuelistItem_MFID INT, ValuelistItem NVARCHAR(100),TableName NVARCHAR(100))
INSERT INTO [#Alllookups]
    (
        [ColumnName],
        [Valuelist_ID],
        [Valuelist],
		ValuelistItem_MFID,
		ValuelistItem,
        [TableName]

    )

Select distinct COLUMN_NAME,mvl.ID,mvl.Name AS Valuelist, mvli.mfid AS ValuelistItem_MFID, MVLI.name AS Valuelist, [c].[TABLE_NAME] from INFORMATION_SCHEMA.COLUMNS c
inner join MFProperty mp
on mp.ColumnName = c.COLUMN_NAME
inner join MFClassProperty mcp
on  mcp.MFProperty_ID = mp.id
inner join MFValueList mvl
on mvl.ID = mp.MFValueList_ID
INNER JOIN [dbo].[MFValueListItems] AS [mvli]
ON mvli.[MFValueListID] = mvl.id
where TABLE_NAME in ( 
Select TableName from MFClass where IncludeInApp is not null)
and mp.MFDataType_ID in (8,9)
and mp.MFID > 1000

SELECT al.*, mc.objid FROM [#Alllookups] al
INNER JOIN mfcustomer mc
ON mc.Country_ID = al.[ValuelistItem_MFID]
WHERE mc.Country <> al.[ValuelistItem]

DROP TABLE [#Alllookups]

/*

SELECT DISTINCT
        [mw].[MFID],
        [mw].[Name],
        [c].[TABLE_NAME]
FROM
        [INFORMATION_SCHEMA].[COLUMNS] AS [c]
    INNER JOIN
        [MFProperty]                   AS [mp]
            ON [mp].[ColumnName] = [c].[COLUMN_NAME]
    INNER JOIN
        [MFClassProperty]              AS [mcp]
            ON [mcp].[MFProperty_ID] = [mp].[ID]
    INNER JOIN
        [MFClass]                      AS [mc]
            ON [mc].[ID] = [mcp].[MFClass_ID]
    INNER JOIN
        [MFWorkflow]                   AS [mw]
            ON [mw].[ID] = [mc].[MFWorkflow_ID]
WHERE
        [TABLE_NAME] IN (
                            SELECT
                                [TableName]
                            FROM
                                [MFClass]
                            WHERE
                                [IncludeInApp] IS NOT NULL
                        )
        AND [mp].[MFDataType_ID] IN (
                                        8, 9
                                    )
        AND [mp].[MFID] > 1000;

		*/