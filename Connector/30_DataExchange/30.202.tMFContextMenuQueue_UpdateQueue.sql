PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'tMFContextMenuQueue_UpdateQueue';
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
(
    SELECT *
    FROM [sys].[objects]
    WHERE [type] = 'TR'
          AND [name] = 'tMFContextMenuQueue_UpdateQueue'
)
BEGIN
    DROP TRIGGER [dbo].[tMFContextMenuQueue_UpdateQueue];

    PRINT SPACE(10) + '...Trigger dropped and recreated';
END;
GO

CREATE TRIGGER dbo.tMFContextMenuQueue_UpdateQueue 
   ON  dbo.MFContextMenuQueue 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ID INT = 0
	SELECT TOP 1 @id=id FROM inserted WHERE Status <> 1
	IF @ID > 0
	BEGIN

    EXEC dbo.spMFUpdateContextMenuQueue @id
  END
END
GO
