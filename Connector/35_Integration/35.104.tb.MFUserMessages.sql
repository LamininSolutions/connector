PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserMessages]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserMessages', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-03
	Database: 
	Description: Table for user messages 
	Used to set store the user messages generated by the MFProcessBatch Table
	

 
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-06-26		Arnie		-	Change field size for Message to NVARCHAR(4000)
		
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from [dbo].[MFUserMessages]

   DROP TABLE MFUserMessages 
-----------------------------------------------------------------------------------------------*/
GO
IF NOT EXISTS (	  SELECT [name]
				  FROM	 [sys].[tables]
				  WHERE	 [name] = 'MFUserMessages'
						 AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN


		CREATE TABLE [dbo].[MFUserMessages]
			(
				[ID] [INT] IDENTITY(1, 1) NOT NULL
			  , [ProcessBatch_ID] INT NULL
			  , [ClassTable] NVARCHAR(100)
			  , [OriginatingUser_ID] INT NULL
			  , [ItemCount] INT NULL
			  , [Created_on] DATETIME
					DEFAULT GETDATE() NOT NULL
			  , [Message] [NVARCHAR](4000) NULL
			)

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO
IF EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFUserMessages'
		AND [COLUMN_NAME] = 'Message'
		AND [CHARACTER_MAXIMUM_LENGTH] <> 4000
		)
BEGIN
	ALTER TABLE [dbo].[MFUserMessages] ALTER COLUMN [Message] NVARCHAR(4000)
	PRINT SPACE(10) + '... Column Message: updated column length to NVARCHAR(4000)';
END

GO