
/*
SAMPLE CODE TO DEMONSTRATE SYNC PRECEDENCE
PRE-REQUISIT: 'OTHER DOCUMENT' CLASS TABLE EXISTS
*/
DECLARE
	@TableName		 NVARCHAR(100) = 'MFOtherDocument'
  , @SQL			 NVARCHAR(1000)
  ,@Params			NVARCHAR(1000)
  , @ChangeText		 NVARCHAR(100) = 'Test11'
  , @SynchPrecedence INT		   = 0; 
  -- null = no precedence, 0 = SQL precedence, 1 = M-Files precedence

--SET SYNC PRECEDENCE ON CLASS
UPDATE	[mc]
SET		[mc].[SynchPrecedence] = 0
FROM	[dbo].[MFClass] AS [mc]
WHERE	[MFID] = 1;
--REVIEW MFCLASS
SELECT
		[mc].[SynchPrecedence], *
FROM	[dbo].[MFClass] AS [mc]
WHERE	[TableName] = @TableName;

--SHOW PROCESS_ID OF OBJECT BEFORE UPDATE
SET @Params = N'@ChangeText NVARCHAR(100)'
SET @sql = N'
SELECT
		[mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM	' + @TableName + ' AS [mod]
WHERE	[ID] = 1;'
EXEC (@SQL)

--UPDATE OBJECT FORCING A SYNCRONIZATION ERROR
SET @sql = N'
UPDATE	[mfod]
SET
		[mfod].[Process_ID] = 1, [mfod].[Keywords] = @ChangeText, [MFVersion] = 1
FROM	' + @TableName + ' AS [mfod]
WHERE	[ID] = 1;
'
EXEC sp_executeSQL @SQL, @params , @ChangeText=@ChangeText

--SHOW PROCESS_ID OF OBJECT AFTER UPDATE OF OBJECT WITH SAMPLE CHANGES
SET @sql = N'
SELECT
		[mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM	' + @TableName + ' AS [mod]
WHERE	[ID] = 1;'
EXEC (@SQL)

--UPDATING OBJECT.  THIS WILL PRODUCE A SYNCRONIZATION ERROR
EXEC [dbo].[spMFUpdateTable]
	@MFTableName = N'MFOtherDocument'	-- nvarchar(128)
  , @UpdateMethod = 0;

--SHOW PROCESS_ID STATUS WITH SYNC ERROR
SET @sql = N'
SELECT
		[mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM	' + @TableName + ' AS [mod]
WHERE	[ID] = 1;'
EXEC (@SQL)

-- CHECK FOR SYNC ERROR AND AUTO CORRECT

EXEC [dbo].[spMFClassTableStats]
	@ClassTableName = @TableName, @IncludeOutput = 1;

IF	( SELECT	SUM([syncError])FROM   [##spMFClassTableStats] ) > 0
	EXEC [dbo].[spMFUpdateSynchronizeError]
		@TableName = @TableName -- varchar(250)
	  , @Debug = 0;				-- int

--SHOW PROCESS_ID STATUS AFTER CORRECTING SYNCRONISATION ERROR
SET @sql = N'
SELECT
		[mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM	' + @TableName + ' AS [mod]
WHERE	[ID] = 1;'
EXEC (@SQL)
