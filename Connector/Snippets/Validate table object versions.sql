
DECLARE @MFTableName NVARCHAR(100) = 'MFDrawing'
DECLARE @SessionID INT
DECLARE @SQL NVARCHAR(MAX), @Params NVARCHAR(MAX)
DECLARE @rowCount int


EXEC dbo.spMFClassTableStats @ClassTableName = @MFTableName, -- nvarchar(128)
                             @Flag = 0,             -- int
                             @WithReset = 0,        -- int
                             @IncludeOutput = 1,    -- int
                             @Debug = 0             -- smallint

							 SELECT @SessionID = SessionID FROM ##spMFClassTableStats

SET @Params = N'@rowCount int output, @SessionID int'
SET @SQL = N'
SELECT @rowCount = count(*) FROM dbo.MFAuditHistory AS mah 
INNER JOIN ' + @MFTableName + '  AS md
ON md.ObjID = mah.ObjID
WHERE mah.SessionID = @SessionID AND md.MFVersion <> mah.MFVersion'

EXEC sp_executeSQL @Stmt = @SQL, @Param = @Params, @Rowcount = @RowCount OUTPUT, @SessionID = @SessionID

SELECT @rowCount


