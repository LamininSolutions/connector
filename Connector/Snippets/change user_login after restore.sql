
sp_change_users_login @Action = 'Report'

EXEC sp_change_users_login @Action = 'Auto_Fix', @UserNamePattern = 'MFSQLConnect'

