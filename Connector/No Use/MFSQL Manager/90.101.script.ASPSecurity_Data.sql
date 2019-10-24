
/*
Run this script after script.ASPSecurity on:

The new MFSQL Manager to add the initial users into ASP.net security tables

this script is used only for a new installation.

*/
		
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON
GO
SET DATEFORMAT YMD
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

IF NOT EXISTS(SELECT * FROM [dbo].[vw_aspnet_Users] AS [vau] WHERE [vau].[UserName] = 'user')
BEGIN

BEGIN TRANSACTION
-- Pointer used for text / image updates. This might not be needed, but is declared here just in case
DECLARE @pv binary(16)

PRINT(N'Drop constraints from [dbo].[aspnet_UsersInRoles]')
ALTER TABLE [dbo].[aspnet_UsersInRoles] DROP CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6]
ALTER TABLE [dbo].[aspnet_UsersInRoles] DROP CONSTRAINT [FK__aspnet_Us__UserI__403A8C7D]

PRINT(N'Drop constraints from [dbo].[aspnet_Membership]')
ALTER TABLE [dbo].[aspnet_Membership] DROP CONSTRAINT [FK__aspnet_Me__Appli__276EDEB3]
ALTER TABLE [dbo].[aspnet_Membership] DROP CONSTRAINT [FK__aspnet_Me__UserI__286302EC]

PRINT(N'Drop constraints from [dbo].[aspnet_Users]')
ALTER TABLE [dbo].[aspnet_Users] DROP CONSTRAINT [FK__aspnet_Us__Appli__173876EA]

PRINT(N'Drop constraints from [dbo].[aspnet_Roles]')
ALTER TABLE [dbo].[aspnet_Roles] DROP CONSTRAINT [FK__aspnet_Ro__Appli__3C69FB99]

PRINT(N'Add 1 row to [dbo].[aspnet_Applications]')
INSERT INTO [dbo].[aspnet_Applications] ([ApplicationId], [ApplicationName], [LoweredApplicationName], [Description]) VALUES ('f501e936-9481-43bc-b5a1-488fe2c98693', N'/', N'/', NULL)

PRINT(N'Add 3 rows to [dbo].[aspnet_SchemaVersions]')
INSERT INTO [dbo].[aspnet_SchemaVersions] ([Feature], [CompatibleSchemaVersion], [IsCurrentVersion]) VALUES (N'common', N'1', 1)
INSERT INTO [dbo].[aspnet_SchemaVersions] ([Feature], [CompatibleSchemaVersion], [IsCurrentVersion]) VALUES (N'membership', N'1', 1)
INSERT INTO [dbo].[aspnet_SchemaVersions] ([Feature], [CompatibleSchemaVersion], [IsCurrentVersion]) VALUES (N'role manager', N'1', 1)

PRINT(N'Add 2 rows to [dbo].[aspnet_Roles]')
INSERT INTO [dbo].[aspnet_Roles] ([RoleId], [ApplicationId], [RoleName], [LoweredRoleName], [Description]) VALUES ('1e5d6fca-1813-4114-8bbe-3bc5073d1c97', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'Administrators', N'administrators', NULL)
INSERT INTO [dbo].[aspnet_Roles] ([RoleId], [ApplicationId], [RoleName], [LoweredRoleName], [Description]) VALUES ('fe00e839-ed88-49f6-996b-93a4f474554f', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'Users', N'users', NULL)

PRINT(N'Add 2 rows to [dbo].[aspnet_Users]')
INSERT INTO [dbo].[aspnet_Users] ([UserId], [ApplicationId], [UserName], [LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]) VALUES ('852344e9-0825-489b-b4ce-740b1fc87846', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'user', N'user', NULL, 0, '2017-02-05 06:50:32.000')
INSERT INTO [dbo].[aspnet_Users] ([UserId], [ApplicationId], [UserName], [LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]) VALUES ('cd90f5a1-9928-465a-a4b5-968d0da0d1f3', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'admin', N'admin', NULL, 0, '2017-02-05 06:50:32.000')

PRINT(N'Add 2 rows to [dbo].[aspnet_Membership]')
INSERT INTO [dbo].[aspnet_Membership] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [MobilePIN], [Email], [LoweredEmail], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowStart], [Comment]) VALUES ('852344e9-0825-489b-b4ce-740b1fc87846', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'YNOpQndOAg0T3ccjKqMa6hPhiVA=', 1, N'uoIgDzwOpK2j9v1LGByAaQ==', NULL, N'user@LSConnect.com', N'user@lsconnect.com', N'ASP.NET', N'7SjKRj4+EIODg4aUxEyInlUzMj8=', 1, 0, '2017-02-05 06:50:32.000', '2017-02-05 06:50:32.000', '2017-02-05 06:50:32.000', '1754-01-01 00:00:00.000', 0, '1754-01-01 00:00:00.000', 0, '1754-01-01 00:00:00.000', NULL)
INSERT INTO [dbo].[aspnet_Membership] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [MobilePIN], [Email], [LoweredEmail], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowStart], [Comment]) VALUES ('cd90f5a1-9928-465a-a4b5-968d0da0d1f3', 'f501e936-9481-43bc-b5a1-488fe2c98693', N'V/nlLgb+3S8vTDlNy+iDZoOYOI8=', 1, N'6UH/26FIE/FTjPY72gUEGw==', NULL, N'admin@LSConnect.com', N'admin@lsconnect.com', N'ASP.NET', N'7kwchSuZH3oXjQY1w4SjPvA/Inc=', 1, 0, '2017-02-05 06:50:32.000', '2017-02-05 06:50:32.000', '2017-02-05 06:50:32.000', '1754-01-01 00:00:00.000', 0, '1754-01-01 00:00:00.000', 0, '1754-01-01 00:00:00.000', NULL)

PRINT(N'Add 3 rows to [dbo].[aspnet_UsersInRoles]')
INSERT INTO [dbo].[aspnet_UsersInRoles] ([UserId], [RoleId]) VALUES ('852344e9-0825-489b-b4ce-740b1fc87846', 'fe00e839-ed88-49f6-996b-93a4f474554f')
INSERT INTO [dbo].[aspnet_UsersInRoles] ([UserId], [RoleId]) VALUES ('cd90f5a1-9928-465a-a4b5-968d0da0d1f3', '1e5d6fca-1813-4114-8bbe-3bc5073d1c97')
INSERT INTO [dbo].[aspnet_UsersInRoles] ([UserId], [RoleId]) VALUES ('cd90f5a1-9928-465a-a4b5-968d0da0d1f3', 'fe00e839-ed88-49f6-996b-93a4f474554f')

PRINT(N'Add constraints to [dbo].[aspnet_UsersInRoles]')
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__UserI__403A8C7D] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])

PRINT(N'Add constraints to [dbo].[aspnet_Membership]')
ALTER TABLE [dbo].[aspnet_Membership] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Me__Appli__276EDEB3] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
ALTER TABLE [dbo].[aspnet_Membership] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Me__UserI__286302EC] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])

PRINT(N'Add constraints to [dbo].[aspnet_Users]')
ALTER TABLE [dbo].[aspnet_Users] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__Appli__173876EA] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])

PRINT(N'Add constraints to [dbo].[aspnet_Roles]')
ALTER TABLE [dbo].[aspnet_Roles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Ro__Appli__3C69FB99] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
COMMIT TRANSACTION
END


GO
