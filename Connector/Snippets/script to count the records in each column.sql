


/*
Purpose:  to report records in each column for all class tables included in App

*/

DECLARE
	@Tablename NVARCHAR(100), @Rowid INT, @SQL NVARCHAR(MAX), @Column_name NVARCHAR(100);

EXEC [dbo].[spMFClassTableStats] @IncludeOutput = 1;

CREATE TABLE [#Tablelist]
	(
		[id]		  INT IDENTITY
	  , [Tablename]	  NVARCHAR(100)
	  , [Column_Name] NVARCHAR(100)
	  , [total]		  INT
	);

INSERT INTO [#Tablelist] ( [Tablename], [Column_Name] )
			SELECT
					[Tablename], [COLUMN_NAME]
			FROM	[##spMFClassTableStats]					  AS [t]
					INNER JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c] ON [t].[Tablename] = [c].[TABLE_NAME];

--			 SELECT * FROM #Tablelist AS [t]
SET @Rowid = 1;

WHILE ( SELECT	COUNT([id])FROM [#Tablelist] AS [t] WHERE	[id] > @Rowid ) > 0
	BEGIN
		SELECT
				@Tablename = [Tablename], @Column_name = [Column_Name]
		FROM	[#Tablelist] AS [t]
		WHERE	[id] = @Rowid;

		--		SELECT	[Tablename] FROM #Tablelist AS [t] WHERE [id] = @Rowid;

		SET @SQL = '
Update tl
Set Total = isnull(Total2,0)
--Select * from
From #Tablelist tl inner join 
(SELECT total2 , list.column_name, list.TableName  FROM (Select  COUNT(' + @Column_name + ') as total2 From '
				   + @Tablename + ' l  ) l1
inner join #Tablelist list ON list.tablename = ''' + @Tablename + ''' and list.column_name = ''' + @Column_name
				   + ''') list2 
on tl.column_name = list2.Column_name and tl.tableName = list2.tableName';


		PRINT @SQL;
		EXEC ( @SQL );

		--		DELETE	FROM #Tablelist WHERE	[id] = @Rowid;
		SELECT	@Rowid = ( SELECT TOP 1 [id] FROM	[#Tablelist] AS [t] WHERE	[id] > @Rowid );


	END;
SELECT	* FROM	[#Tablelist];
DROP TABLE [#Tablelist];
