--old


                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 2, 3, 8 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                IF @Debug = 100					
		            SELECT @colsUnpivot AS 'lookup columns';

                SET @Query
                    = '
 select ID, Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS ColumnValue
        from ' + QUOTENAME(@MFTableName) + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where ' + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 1, 5, 9 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                IF @Debug = 100					
		            SELECT @colsUnpivot AS 'text columns';

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 4, 6 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );
                IF @Debug = 100					
		            SELECT @colsUnpivot AS 'lookup columns';

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 12 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;

                SELECT @colsUnpivot = STUFF((
                                                SELECT ',' + QUOTENAME([C].[name])
                                                FROM [sys].[columns]              AS [C]
                                                    INNER JOIN [dbo].[MFProperty] AS [mp]
                                                        ON [mp].[ColumnName] = [C].[name]
                                                WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                                      AND ISNULL([mp].[MFID], -1) NOT IN ( -1, 20, 21, 23, 25 )
                                                      AND [mp].[MFDataType_ID] IN ( 7 )
                                                FOR XML PATH('')
                                            )
                                           ,1
                                           ,1
                                           ,''
                                           );

                SET @Query
                    = @Query
                      + ' Union All 
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '               + QUOTENAME(@MFTableName)
                      + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where '              + @vquery;


		--New

--SELECT * FROM [dbo].[MFDataType] AS [mdt]

DECLARE @colsUnpivot AS NVARCHAR(MAX)
       ,@colsPivot   AS NVARCHAR(MAX)
       ,@Query       NVARCHAR(MAX)   = ''
       ,@vQuery      NVARCHAR(MAX)   = 'process_ID =1'
	   ,@DeleteQuery AS NVARCHAR(MAX)
       ,@rownr       INT
       ,@Datatypes   NVARCHAR(100)
       ,@MFTableName NVARCHAR(200)   = 'MFInternalProject'
       ,@Debug       INT             = 100;

DECLARE @DatatypeTable AS TABLE
(
    [id] INT IDENTITY
   ,[Datatypes] NVARCHAR(20)
   ,[Type_Ids] NVARCHAR(100)
);

INSERT INTO @DatatypeTable
(
    [Datatypes]
   ,[Type_Ids]
)
VALUES
(   N'Float'    -- Datatypes - nvarchar(20)
   ,N'2,3,9,11' -- Type_Ids - nvarchar(100)
    )
,('Text', '1,6,10')
,('Date', '5,7')
,('Bit', '8');

SET @rownr = 1;

WHILE @rownr IS NOT NULL
BEGIN
    SELECT @Datatypes = [dt].[Type_Ids]
    FROM @DatatypeTable AS [dt]
    WHERE [dt].[id] = @rownr;

    SELECT @colsUnpivot
        = STUFF(
          (
              SELECT ',' + QUOTENAME([C].[name])
              FROM [sys].[columns]              AS [C]
                  INNER JOIN [dbo].[MFProperty] AS [mp]
                      ON [mp].[ColumnName] = [C].[name]
              WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                    AND ISNULL([mp].[MFID], -1) NOT IN ( - 1, 20, 21, 23, 25 )
                   and mp.ColumnName <> 'Deleted' 
					AND [mp].[MFDataType_ID] IN (
                                                    SELECT [ListItem] FROM [dbo].[fnMFParseDelimitedString](@Datatypes,',')
)
FOR XML PATH('')
          )
         ,1
         ,1
         ,''
);

    IF @Debug = 100
        SELECT @colsUnpivot AS 'columns';

		IF @colsUnpivot IS NOT NULL
        Begin
    SET @Query
        = @Query 
          + 'Union All
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '   + QUOTENAME(@MFTableName) + ' t
        unpivot
        (
          value for name in (' + @colsUnpivot + ')
        ) unpiv
		where 
		'  + @vQuery + ' '
		END

    SELECT @rownr =
    (
        SELECT MIN([dt].[id])
        FROM @DatatypeTable AS [dt]
        WHERE [dt].[id] > @rownr
    );
END;
SET @DeleteQuery = N'Union All Select ID, Objid, MFversion, ExternalID, ''Deleted'' as ColumnName, cast(isnull(Deleted,0) as nvarchar(4000))  as Value from '   + QUOTENAME(@MFTableName) + ' t where '+@vQuery + ' '
SELECT @DeleteQuery AS deletequery

SELECT @Query = SUBSTRING(@Query,11,8000) + @DeleteQuery 

	PRINT @Query

	EXEC sp_ExecuteSQL @Query
-------------------------------------------------------------
-- prepare column value pair query based on data types
-------------------------------------------------------------
