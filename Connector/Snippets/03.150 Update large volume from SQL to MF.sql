
/*
ILLUSTRATION OF USING SPMFUPDATEMFILESTOSQL PROC TO BATCH UPDATING OF OBJECTS
IT USES A M-Object called Test with 4000 records added to it using another sample procedure.
*/
SELECT COUNT(*)
FROM [dbo].[MFTest] AS [mt];

--TRUNCATE TABLE [dbo].[MFTest]


--from MF to SQL - using a full refresh (updatetypeID = 0)
-- to perform an incremental update use updateTypeid = 1
--note that this procedure has an extra step of performing a table audit to capture any missing items; it also use a batch update process based on the objid

DECLARE @MFLastUpdateDate SMALLDATETIME,
        @Update_IDOut INT,
        @ProcessBatch_ID INT;
EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = N'MFTest',                     -- nvarchar(128)
                                     @MFLastUpdateDate = @MFLastUpdateDate OUTPUT, -- smalldatetime
                                     @UpdateTypeID = 0,                            -- tinyint
                                     @Update_IDOut = @Update_IDOut OUTPUT,         -- int
                                     @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,   -- int
                                     @debug = 0;                                   -- tinyint

SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID;

GO


--When large quantities of data must be update it is useful to build a batching process around SPMFUpdateTable.

--FROM SQL TO MF using a batch process to control the updates into MF

UPDATE [dbo].[MFTest]
SET process_id = 1
WHERE process_id = 10

DECLARE @BatchSize INT = 500,
		@BatchestoRun INT = 3,
        @RowCount INT ,
        @BatchCounter INT = 1,

        @ProcessBatch_ID INT = 0,
        @UpdateID INT,
        @SQL NVARCHAR(MAX),
		@Params NVARCHAR(MAX),
        @TableName NVARCHAR(100) = 'MFTest';

EXEC (N' 
UPDATE ' + @TableName + ' 
SET process_id = 10
WHERE process_id = 1')

SELECT @RowCount = @@ROWCOUNT
SELECT @RowCount AS [Rows in Batch]

WHILE @RowCount > 0 AND @BatchCounter < @BatchestoRun
BEGIN


    SET @SQL = N' 
	update sa
set process_ID = 1

from ' + QUOTENAME(@TableName) + ' sa 
inner join (

select top ' + CAST(@BatchSize AS VARCHAR(5)) + ' * from ' + QUOTENAME(@TableName) + ' where process_ID  = 10) sa2
on sa.id = sa2.id';

--PRINT @SQL

    EXEC (@SQL);

	SET @Params = '@Rowcount int output'
    SET @SQL = N'
select @Rowcount = count(*) from ' + QUOTENAME(@TableName) + ' where process_id = 10';

--PRINT @SQL

EXEC sp_executeSQL @stmt = @SQL, @param = @Params, @Rowcount = @rowcount OUTPUT

SELECT @RowCount AS [RowCount];

    EXEC [dbo].[spMFUpdateTable] @MFTableName = @TableName,
                                 @UpdateMethod = 0,
                                 @Update_IDOut = @UpdateID OUTPUT,
                                 @ProcessBatch_ID = @ProcessBatch_ID OUTPUT;

    SELECT @BatchCounter AS [Counter], @BatchSize AS [Batch Size],
           @UpdateID AS [UpdateID];

    SET @BatchCounter = @BatchCounter + 1;

END;



SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
SELECT * FROM [dbo].[MFTest] AS [mt]




