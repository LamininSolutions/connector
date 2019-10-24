



/*
Purpose:  to remove deleted records from all class tables included in App

*/

DECLARE
	@Tablename NVARCHAR(100), @Rowid INT, @SQL NVARCHAR(MAX);

EXEC [dbo].[spMFClassTableStats] @IncludeOutput = 1;

DECLARE @Tablelist AS TABLE
	(
		[id]		INT IDENTITY
	  , [Tablename] NVARCHAR(100)
	);

INSERT INTO @Tablelist ( [Tablename] )
			SELECT	[Tablename] FROM [##spMFClassTableStats] WHERE	[deleted] > 0;

SET @Rowid = 1;

WHILE ( SELECT	COUNT([id])FROM @Tablelist AS [t] ) > 0
	BEGIN
		SELECT	@Tablename = [Tablename] FROM	@Tablelist AS [t] WHERE [id] = @Rowid;

		SET @SQL = N'
DELETE FROM ' + QUOTENAME(@Tablename) + ' WHERE deleted > 0';
		EXEC ( @SQL );

		SELECT	[Tablename] FROM @Tablelist AS [t] WHERE [id] = @Rowid;

		DELETE	FROM @Tablelist WHERE	[id] = @Rowid;
		SELECT	@Rowid = ( SELECT TOP 1 [id] FROM	@Tablelist AS [t] WHERE [id] > @Rowid );


	END;
