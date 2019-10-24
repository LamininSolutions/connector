
/*
Script to create valuelist lookup views used by MFSQL Manager
*/



EXEC dbo.spMFCreateValueListLookupView @ValueListName = N'User Group', -- nvarchar(128)
    @ViewName = N'vwMF_UserGroup', -- nvarchar(128)
    @Debug = 0 -- smallint

GO


