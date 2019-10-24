
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableinBatches]';
GO

SET NOCOUNT ON;

GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 15/12/2018
	Database:
	Description: Procedure to update class table in batches

Updating a large number of records from a specific class in MF to SQL in batches 

it is advisable to process updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure
It will also keep the size of the dataset for transfer within the limits of 8000 bites.

	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

	updated version 2018-12-15

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTableinBatches' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE [dbo].[spMFUpdateTableinBatches]
AS
SELECT 'created, but not implemented yet.';

GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFUpdateTableinBatches]  
@MFTableName NVARCHAR(100)
,@maxObjid INT = 10000
,@BatchestoRun INT = 5 -- use this setting limit the iterations for testing.  To process all records set to a factor of the highest objid / batchsize
,@MinObjid INT = 1 -- the starting objid of the update
,@WithStats BIT = 1 -- set to 0 to suppress display messages
,@Debug int = 0 --
AS
SET NOCOUNT ON;

BEGIN
-- Debug params
DECLARE @DebugText nvarchar(100);
DECLARE @DefaultDebugText nvarchar(100);
DECLARE @Procedurestep nvarchar(100);
DECLARE @ProcedureName nvarchar(100) = 'dbo.spMFUpdateTableinBatches';
Set @Procedurestep = 'Start'

  --BEGIN  
Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END
	
	--<Begin Proc>--
	Set @Procedurestep = ''
	
	--
END;
GO

SET NOCOUNT ON;

--set the following parameters



DECLARE @BatchSize    INT      -- sizes is restricted by objid length.

SELECT @BatchSize = 4000 / (LEN(@maxObjid) + 1);

--other parameters 
DECLARE @StartRow        INT
       ,@MaxRow          INT
       ,@RecCount        INT
       ,@BatchCount      INT           = 1
       ,@ProcessBatch_ID INT
       ,@UpdateID        INT
       ,@SQL             NVARCHAR(MAX)
       ,@Params          NVARCHAR(MAX)
       ,@StartTime       DATETIME
       ,@ProcessingTime  INT
       ,@objids          NVARCHAR(4000)
       ,@Message         NVARCHAR(100)
       ,@Update_IDOut    INT;

--start
SET @StartRow = @MinObjid;
SET @MaxRow = @StartRow + (@BatchSize * @BatchestoRun);
SET @Params = N'@Objids nvarchar(4000) output';

--while loop
WHILE @StartRow < @MaxRow
BEGIN
    SET @StartTime = GETDATE();
    SET @objids = NULL;
    SET @Message = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

    RAISERROR(@Message, 10, 1);

    IF OBJECT_ID('Tempdb..##ObjidTable') > 0
        DROP TABLE [##ObjidTable];

    SET @SQL
        = N'(SELECT TOP ' + CAST(@BatchSize AS VARCHAR(5)) + ' identity(int,' + CAST(@StartRow AS VARCHAR(20))
          + ',1) AS objid into ##ObjidTable FROM sys.[columns] AS [c])
'   ;

    --SELECT @SQL
    EXEC (@SQL);

    --SELECT *
    --FROM [##ObjidTable] AS [ot];
    SELECT @objids = STUFF((
                               SELECT ',' + CAST([Objid] AS NVARCHAR(20))
                               FROM [##ObjidTable]
                               FOR XML PATH('')
                           )
                          ,1
                          ,1
                          ,''
                          )
    FROM [##ObjidTable] AS [ot];

    --	SELECT MAX(objid) FROM ##ObjidTable
    SELECT @objids = COALESCE(@objids, '0');

    DECLARE @outPutXML NVARCHAR(MAX);

    EXEC [dbo].[spMFGetObjectvers] @TableName = @MFTableName       -- nvarchar(100)
                                  ,@dtModifiedDate = NULL          -- datetime
                                  ,@MFIDs = @objids                -- nvarchar(4000)
                                  ,@outPutXML = @outPutXML OUTPUT; -- nvarchar(max)

    DECLARE @NewXML XML;

    SET @NewXML = CAST(@outPutXML AS XML);

    --   SELECT @NewXML;

    --SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ObjID]
    --   FROM @NewXML.[nodes]('/form/objVers') AS [t]([c])
    --INNER JOIN ##ObjidTable ot
    --ON [t].[c].[value]('(@objectID)[1]', 'INT') = ot.objid
    DECLARE @objidlist AS TABLE
    (
        [Objid] INT
    );

    DELETE FROM @objidlist;

    INSERT INTO @objidlist
    (
        [Objid]
    )
    SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ObjID]
    FROM @NewXML.[nodes]('/form/objVers') AS [t]([c])
        INNER JOIN [##ObjidTable]         [ot]
            ON [t].[c].[value]('(@objectID)[1]', 'INT') = [ot].[objid];

	SET @objids = null
    SELECT @objids = STUFF((
                               SELECT ',' + CAST([o].[Objid] AS NVARCHAR(20))
                               FROM @objidlist AS [o]
                               FOR XML PATH('')
                           )
                          ,1
                          ,1
                          ,''
                          )
    FROM @objidlist AS [o2];


    IF @objids IS NOT NULL
    BEGIN
        EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName          -- nvarchar(200)
                                    ,@UpdateMethod = 1                    -- int
                                    ,@ObjIDs = @objids                    -- nvarchar(max)
                                    ,@Update_IDOut = @Update_IDOut OUTPUT -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID; -- int

        SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
        SET @Params = '@RecCount int output';
        SET @SQL
            = 'SELECT @RecCount = COUNT(*) FROM ' + @MFTableName + ' where update_ID ='
              + CAST(@Update_IDOut AS VARCHAR(10)) + '';

        EXEC [sys].[sp_executesql] @SQL, @Params, @RecCount OUTPUT;

        SET @Message
            = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
              + CAST(@ProcessingTime / 100 AS VARCHAR(10)) + ' From Object ID: ' + CAST(@StartRow AS VARCHAR(10))
              + ' Processed: ' + CAST(@RecCount AS VARCHAR(10));

        RAISERROR(@Message, 10, 1);
    END;

    SET @BatchCount = @BatchCount + 1;
    SET @StartRow = @StartRow + @BatchSize;
END;
GO