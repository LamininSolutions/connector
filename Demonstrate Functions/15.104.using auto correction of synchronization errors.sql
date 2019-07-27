

	-------------------------------------------------------------
    -- SYNCRONIZATION ERRORS
    -------------------------------------------------------------

	  
/*
SAMPLE CODE TO DEMONSTRATE SYNC PRECEDENCE
select * from mfotherdocument where process_id = 2

*/

--exec from here to show the progression through all the sample steps.  

--setup variables for example
DECLARE
    @TableName       NVARCHAR(100) = 'MFOtherDocument',
	@ClassName		NVARCHAR(100),
	@TableMFID		INT,
    @SQL             NVARCHAR(1000),
    @Params          NVARCHAR(1000),
    @ChangeText      NVARCHAR(100) = 'Test11',
    @SynchPrecedence INT           = 1,
	@TestID			INT 

SELECT @ClassName = [name], @TableMFID = mfid FROM mfclass WHERE tablename = @tablename
SET @SQL = N'SELECT @TestID = MIN(id) FROM ' + @TableName
SET @Params = N'@TestID int output'
EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID output
 
 SELECT  @TestID AS TESTID

-- create the test table if not exists
IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = @TableName)
Begin
EXEC [dbo].[spMFCreateTable]
    @ClassName = @ClassName,
    @Debug = 0
END
EXEC spmfupdatetable @Tablename,1


-- null = no precedence, 0 = SQL precedence, 1 = M-Files precedence

--SET SYNC PRECEDENCE ON CLASS

UPDATE
    [mc]
SET
    [mc].[SynchPrecedence] = @SynchPrecedence  --SQL takes presence
FROM
    [dbo].[MFClass] AS [mc]
WHERE
    [MFID] = @TableMFID
   ;
--REVIEW MFCLASS
SELECT
    [mc].[SynchPrecedence],
    *
FROM
    [dbo].[MFClass] AS [mc]
WHERE
    [TableName] = @TableName;

--SHOW PROCESS_ID OF OBJECT BEFORE UPDATE
SET @Params = N'@ChangeText NVARCHAR(100),@TestID int';
SET @SQL = N'
SELECT ''BeforeUpdate'' as [BeforeUpdate],
        [mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM    ' + @TableName + ' AS [mod]
WHERE   [ID] = @TestID;';
EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID, @ChangeText = @ChangeText;

--UPDATE OBJECT FORCING A SYNCRONIZATION ERROR
SET @Params = N'@ChangeText NVARCHAR(100),@TestID int';
SET @SQL
    = N'
UPDATE  [mfod]
SET
        [mfod].[Process_ID] = 1, [mfod].[Keywords] = @ChangeText, [MFVersion] = 1
FROM    ' + @TableName + ' AS [mfod]
WHERE   [ID] = @TestID;
';
EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID, @ChangeText = @ChangeText;

--SHOW PROCESS_ID OF OBJECT AFTER UPDATE OF OBJECT WITH SAMPLE CHANGES
SET @SQL = N'
SELECT ''ForcedSync Error'' as [Sync ErrorForced],
        [mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM    ' + @TableName + ' AS [mod]
WHERE   [ID] = @TestID;';

EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID, @ChangeText = @ChangeText;

--UPDATING OBJECT.  THIS WILL PRODUCE A SYNCRONIZATION ERROR
DECLARE @Update_ID int

EXEC [dbo].[spMFUpdateTable]
    @MFTableName = @TableName, -- nvarchar(128)
	@Update_IDOut = @update_ID OUTPUT,
    @UpdateMethod = 0;

--SHOW PROCESS_ID STATUS WITH SYNC ERROR
SET @SQL = N'
SELECT  ''ForcedSync Error'' as [Sync ErrorForced],
        [mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM    ' + @TableName + ' AS [mod]
WHERE   [ID] = @TestID;';

EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID, @ChangeText = @ChangeText;

-- CHECK FOR SYNC ERROR AND AUTO CORRECT -- this is the part of the procedure to be included in your custom procedure

EXEC [dbo].[spMFClassTableStats]
    @ClassTableName = @TableName,
    @IncludeOutput = 1;
	SELECT * FROM ##spMFClassTableStats
IF
    (
        SELECT
            [syncError]
        FROM
            [##spMFClassTableStats] WHERE tablename = @Tablename
    ) > 0
    EXEC [dbo].[spMFUpdateSynchronizeError]
        @TableName = @TableName, -- varchar(250)
		@Update_ID = @Update_ID,
        @Debug = 0;              -- int


--SHOW PROCESS_ID STATUS AFTER CORRECTING SYNCRONISATION ERROR
SET @SQL = N'
SELECT ''After error'' as [Error corrected],
        [mod].[Process_ID], [mod].[MFVersion], [mod].[Keywords], *
FROM    ' + @TableName + ' AS [mod]
WHERE   [ID] = @TestID;';

EXEC sp_executeSQL @SQL, @Params, @TestID = @TestID, @ChangeText = @ChangeText;

GO

--Exec to here

