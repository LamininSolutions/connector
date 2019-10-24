
select * FROM [dbo].[vw_aspnet_Applications] AS [vaa]
SELECT * FROM [dbo].[aspnet_Applications] AS [aa]
SELECT * FROM [dbo].[aspnet_Roles] AS [ar]
SELECT * FROM [dbo].[aspnet_Users] AS [au]
SELECT * FROM [dbo].[vw_aspnet_Users] AS [vau]
SELECT [aa].[ApplicationName],[ar].[RoleName],[au].[UserName] FROM [dbo].[vw_aspnet_UsersInRoles] AS [vauir]
INNER JOIN [dbo].[aspnet_Roles] AS [ar]
ON ar.[RoleId] = vauir.[RoleId]
INNER JOIN [dbo].[aspnet_Users] AS [au]
ON au.[UserId] = vauir.[UserId]
INNER JOIN [dbo].[aspnet_Applications] AS [aa]
ON aa.[ApplicationId] = ar.[ApplicationId]

SELECT * FROM [dbo].[vw_aspnet_MembershipUsers] AS [vamu]
SELECT * FROM [dbo].[aspnet_Membership] AS [am]
DELETE FROM [dbo].[aspnet_Users] WHERE userid = '9B7684AB-A2BA-4846-8D54-767ACAA17C83'
DELETE FROM [dbo].[aspnet_Membership] WHERE userid = '1CFD5C3B-841B-4447-8508-83A0D05E9BF2'
DELETE FROM [dbo].[aspnet_UsersInRoles] WHERE userid = '9B7684AB-A2BA-4846-8D54-767ACAA17C83'
DELETE FROM [dbo].[aspnet_Roles] WHERE [RoleId] = 'EAFDCD0D-3696-428A-AED2-B1D3C64C73D4'
DECLARE @Return_Value int
EXEC @Return_Value = [dbo].[aspnet_Roles_RoleExists]
    @ApplicationName = '/LSMarketing',
    @RoleName = 'CRM'
SELECT @Return_Value

EXEC [dbo].[aspnet_Roles_DeleteRole]
    @ApplicationName = '/LSCRM',
    @RoleName = 'CRM',
    @DeleteOnlyIfRoleIsEmpty = 1


	EXEC [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]
	    @ApplicationName ='/' ,
	    @UserNames = 'test',
	    @RoleNames = 'Administrators,CRM,MFSQL'

DECLARE @CurrentTimeUtc DATETIME
SET @CurrentTimeUtc = GETUTCDATE()
EXEC [dbo].[aspnet_Membership_SetPassword]
    @ApplicationName = '/LS_MFSQLManager',
    @UserName = 'Leroux',
    @NewPassword = 'ItIsMyDay01#',
    @PasswordSalt = 'lUtH1cTdBRillIMTKh/ULA==',
    @CurrentTimeUtc = @CurrentTimeUtc,
    @PasswordFormat = 1

	SELECT convert(NVARCHAR(25),GETUTCDATE(),1)


EXEC [dbo].[aspnet_UsersInRoles_GetRolesForUser]
    @ApplicationName = '/',
    @UserName = 'lcilliers'

	EXEC [dbo].[aspnet_UsersInRoles_AddUsersToRoles]
	    @ApplicationName = '/LS_MFSQLManager',
	    @UserNames = 'leroux',
	    @RoleNames = 'Administrators',
	    @CurrentTimeUtc = '2017-09-13 16:30:00'
	
EXEC [dbo].[aspnet_Roles_CreateRole]
    @ApplicationName = '/LSMarketing',
    @RoleName = 'CRM'

EXEC [dbo].[aspnet_Membership_GetAllUsers]
    @ApplicationName = '/Marketing',
    @PageIndex = 10,
    @PageSize = 100

	DECLARE @NumTablesDeletedFrom INT;
	EXEC [dbo].[aspnet_Users_DeleteUser]
	    @ApplicationName = '/' ,
	    @UserName = 'lcilliers',
		@TablesToDeleteFrom = 10,
	    @NumTablesDeletedFrom = @NumTablesDeletedFrom OUTPUT
	SELECT @NumTablesDeletedFrom

EXEC [dbo].[aspnet_UsersInRoles_IsUserInRole]
    @ApplicationName = '/LSMarketing',
    @UserName = 'leroux',
    @RoleName = 'Administrators'

	