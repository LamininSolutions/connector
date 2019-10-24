
     DECLARE @lastModifiedColumn NVARCHAR(100)
	 DECLARE @lastModifiedByColumn NVARCHAR(100)
	 DECLARE @ClassColumn NVARCHAR(100)
	  DECLARE @CreateColumn NVARCHAR(100)
	   DECLARE @CreatedByColumn NVARCHAR(100)

	SELECT @lastModifiedColumn = [mp].[ColumnName] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 21 --'Last Modified'
	
	SELECT @lastModifiedByColumn = [mp].[ColumnName] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 23 --'Last Modified By'

	SELECT @ClassColumn = [mp].[Name] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 100 --'Class'

	SELECT @CreateColumn = [mp].[Name] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 20 --'Created'

	SELECT @CreatedByColumn = [mp].[ColumnName] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 25 --'Created By'
		
--	SELECT * FROM mfproperty WHERE mfid < 100
