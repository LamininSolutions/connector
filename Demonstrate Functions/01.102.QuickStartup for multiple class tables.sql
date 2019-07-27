
/*
Quick startup 

synch metadata structure
create table
update table
show class table results
show tablestats
show error if exist
show Status of MFClass

*/

--edit list of classes to add class tables to your project and then run entire script


DECLARE @ClassList NVARCHAR(4000) = 'Customer,Contact Person,Document'

-- PRESS F5 TO EXECUTE SCRIPT

DECLARE @ClassTable AS TABLE (id INT IDENTITY, ClassName NVARCHAR(100), TableName NVARCHAR(100))
DECLARE @MFClassName NVARCHAR(100) ;
DECLARE @MFTableName NVARCHAR(100);
DECLARE @ProcessBatch_ID INT;
DECLARE @Query NVARCHAR(MAX);
DECLARE @Rownr INT;
DECLARE @Update_IDOut INT;
DECLARE @Return_Value SMALLINT;

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0,                               -- int
                                           @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                           @Debug = 0,                                 -- smallint
                                           @WithClassTableReset = 0;                   -- int

INSERT INTO @ClassTable
(
    [ClassName],
    [TableName]
)

SELECT mc.name, mc.[TableName] from [dbo].[fnMFParseDelimitedString](@ClassList,',') AS [fmpds]
INNER JOIN [dbo].[MFClass] AS [mc]
ON [fmpds].[ListItem] = mc.[Name]

SELECT * FROM @ClassTable AS [ct]

SET @Rownr = 1

WHILE @Rownr IS NOT null
BEGIN
SELECT @MFClassName = [ct].[ClassName] FROM @ClassTable AS [ct] WHERE id = @rownr
SET @Query = N'
EXEC [dbo].[spMFCreateTable] @ClassName = ' + QUOTENAME(@MFClassName) + ', -- nvarchar(128)
                             @Debug = 0;                 -- smallint'

EXEC (@Query)

Select @rownr = (SELECT MIN(id) FROM @ClassTable AS [ct] WHERE id > @Rownr)
END


SET @Rownr = 1

WHILE @Rownr IS NOT null
BEGIN
SELECT @MFTableName = [ct].[TableName] FROM @ClassTable AS [ct] WHERE id = @rownr

EXEC @Return_Value = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName,                -- nvarchar(200)
                                             @UpdateMethod = 1,                          -- int                                  
                                             @Update_IDOut = @Update_IDOut OUTPUT,       -- int
                                             @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                            @Debug = 0;                                -- smallint


SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;
SELECT @Return_Value AS 'Return_Value';

EXEC [dbo].[spMFClassTableStats] @ClassTableName = @MFTableName, -- nvarchar(128)
                                 @Flag = 0,                      -- int
                                 @WithReset = 0,                 -- int
                                 @IncludeOutput = 0,             -- int
                                 @Debug = 0;                     -- smallint

IF @Return_Value <> 1
    SELECT TOP 1
           [ml].[ErrorMessage],
           [ml].[CreateDate],*
    FROM [dbo].[MFLog] AS [ml]
    ORDER BY [ml].[LogID];
	
	EXEC (N'SELECT * FROM '+@MFTablename);

Select @rownr = (SELECT MIN(id) FROM @ClassTable AS [ct] WHERE id > @Rownr)
END

SELECT * FROM [dbo].[MFClass] AS [mc]

/*
EXEC [dbo].[spMFDropAllClassTables] @IncludeInApp = 1, -- int
                                    @Debug = 0         -- smallint
*/
GO
