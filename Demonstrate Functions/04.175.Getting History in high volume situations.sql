




DECLARE @LastUpdateUTC	 DATETIME
DECLARE @LastUpdate	 DATETIME
DECLARE @classID INT
DECLARE @TimeDiff float
SELECT @ClassID = MFID FROM mfclass WHERE [TableName] = 'MFPurchaseInvoice'
SELECT @TimeDiff = DATEDIFF(HOUR,GETUTCDATE(),GETDATE())

SELECT @TimeDiff

SELECT @LastUpdateUTC = MAX([moch].[LastModifiedUtc]) FROM [dbo].[MFObjectChangeHistory] AS [moch] WHERE [moch].[Class_ID] = @classID

SELECT @LastUpdateUTC

SET @LastUpdate = DATEADD(HOUR,@TimeDiff,@LastUpdateUTC)

SELECT @LastUpdate

DECLARE @Update_IDOut INT,
        @ProcessBatch_ID1 INT;
EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFPurchaseInvoice',     -- nvarchar(200)
                             @UpdateMethod = 1,    -- int
                             @MFModifiedDate = @LastUpdate,  -- datetime
							 @Update_IDOut = @Update_IDOut output

SELECT @Update_IDOut

UPDATE [mp]
SET [mp].[Process_ID] = 5
FROM MFPurchaseInvoice mp WHERE [Update_ID] = @Update_IDOut
DECLARE @ProcessBatch_id INT;

EXEC [dbo].[spMFGetHistory] @MFTableName = 'MFPurchaseInvoice',   -- nvarchar(128)
                            @Process_id = 5,    -- int
                            @ColumnNames = 'Workflow_State',   -- nvarchar(4000)
							@StartDate =@LastUpdateUTC,
                            @IsFullHistory = NULL
						
SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch] WHERE [moch].[LastModifiedUtc] > @LastUpdateUTC

SELECT * FROM [dbo].[MFUpdateHistory] AS [muh] WHERE ID >= @Update_IDOut


