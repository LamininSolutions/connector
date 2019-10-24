


DECLARE @sessionID smallINT 
DECLARE @MFTableName NVARCHAR(100) = 'MFTest'
DECLARE @Batchsize SMALLINT = 1000
DECLARE @NextBatchStart INT
DECLARE @Objids NVARCHAR(MAX)
DECLARE @MaxObjid INT
DECLARE @Objid INT
DECLARE @Debug SMALLINT = 1

DECLARE
    @SessionIDOut    INT,
    @NewObjectXml    NVARCHAR(MAX),
    @DeletedInSQL    INT,
    @UpdateRequired  BIT,
    @OutofSync       INT,
    @ProcessErrors   INT,
    @ProcessBatch_ID INT,
	@Update_IDOut INT;

EXEC [dbo].[spMFTableAudit]
    @MFTableName = @MFTableName,
    @SessionIDOut = @SessionID OUTPUT,
    @NewObjectXml = @NewObjectXml OUTPUT,
    @DeletedInSQL = @DeletedInSQL OUTPUT,
    @UpdateRequired = @UpdateRequired OUTPUT,
    @OutofSync = @OutofSync OUTPUT,
    @ProcessErrors = @ProcessErrors OUTPUT,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Debug = 0

SElect @NextBatchStart = MIN([mah].[ObjID]) FROM [dbo].[MFAuditHistory] AS [mah] WHERE sessionid = @sessionID 

SElect @MaxObjid = MAX([mah].[ObjID]) FROM [dbo].[MFAuditHistory] AS [mah] WHERE sessionid = @sessionID 

SET @objid = @NextBatchStart

--SELECT @NextBatchStart

WHILE @objid IS NOT null
BEGIN

--SELECT @NextBatchStart
--SELECT @NextBatchStart + @Batchsize

SELECT @Objids = COALESCE(@Objids + ',','' ) + CAST([mah].[ObjID] AS VARCHAR(20))   FROM [dbo].[MFAuditHistory] AS [mah] WHERE sessionid = @sessionID AND  statusflag = 5 AND [mah].[ObjID] BETWEEN @NextBatchStart and @NextBatchStart + @Batchsize
ORDER BY [mah].[ObjID] asc

IF @debug > 0
SELECT @Objids;


EXEC [dbo].[spMFUpdateTable]
    @MFTableName = @MFTableName,
    @UpdateMethod = 1,
    @ObjIDs = @Objids,
    @Update_IDOut = @Update_IDOut OUTPUT,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT

	IF @debug > 0
	SELECT @NextBatchStart AS Batchstart,* FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID;

SET @NextBatchStart = @NextBatchStart + @Batchsize
SET @Objids = null
SELECT @Objid = MAX([mah].[ObjID]) FROM [dbo].[MFAuditHistory] AS [mah] WHERE sessionid = @sessionID AND [mah].[ObjID] BETWEEN @NextBatchStart and @NextBatchStart + @Batchsize

END

