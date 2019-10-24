/*
Run this script on:

        The a NEW MFSQL Manager Database to install ASP Security Provider


*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

PRINT SPACE(5) + 'ASPNET SECURITY RPOVIDER FOR MFSQL MANAGER ' + QUOTENAME(DB_NAME()) + ' - '
    + QUOTENAME(@@SERVERNAME);

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


if not exists (select 1 from sys.database_principals where name like'aspnet%' and Type = 'R')
Begin
IF @@ERROR <> 0 SET NOEXEC ON

PRINT N'Creating role aspnet_Membership_FullAccess'


CREATE ROLE [aspnet_Membership_FullAccess]
AUTHORIZATION [dbo]

IF @@ERROR <> 0 SET NOEXEC ON

CREATE ROLE [aspnet_Membership_BasicAccess]
AUTHORIZATION [dbo]

PRINT N'Creating role aspnet_Membership_ReportingAccess'

CREATE ROLE [aspnet_Membership_ReportingAccess]
AUTHORIZATION [dbo]

PRINT N'Creating role aspnet_Roles_FullAccess'

CREATE ROLE [aspnet_Roles_FullAccess]
AUTHORIZATION [dbo]


PRINT N'Creating role aspnet_Roles_BasicAccess'

CREATE ROLE [aspnet_Roles_BasicAccess]
AUTHORIZATION [dbo]


PRINT N'Creating role aspnet_Roles_ReportingAccess'

CREATE ROLE [aspnet_Roles_ReportingAccess]
AUTHORIZATION [dbo]



PRINT N'Altering members of role aspnet_Membership_BasicAccess'

EXEC sp_addrolemember N'aspnet_Membership_BasicAccess', N'aspnet_Membership_FullAccess'


PRINT N'Altering members of role aspnet_Membership_ReportingAccess'

EXEC sp_addrolemember N'aspnet_Membership_ReportingAccess', N'aspnet_Membership_FullAccess'


PRINT N'Altering members of role aspnet_Roles_BasicAccess'

EXEC sp_addrolemember N'aspnet_Roles_BasicAccess', N'aspnet_Roles_FullAccess'


PRINT N'Altering members of role aspnet_Roles_ReportingAccess'

EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess', N'aspnet_Roles_FullAccess'


END
ELSE
Begin

PRINT SPACE(10) + N'...ASPNET Roles already exists'

END

IF @@ERROR <> 0 SET NOEXEC ON
GO
BEGIN TRANSACTION
GO



IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_SchemaVersions')
BEGIN

PRINT N'Creating [dbo].[aspnet_SchemaVersions]'

CREATE TABLE [dbo].[aspnet_SchemaVersions]
(
[Feature] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[CompatibleSchemaVersion] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[IsCurrentVersion] [bit] NOT NULL
)

PRINT N'Creating primary key [PK__aspnet_S__5A1E6BC1503E7E3B] on [dbo].[aspnet_SchemaVersions]'

ALTER TABLE [dbo].[aspnet_SchemaVersions] ADD CONSTRAINT [PK__aspnet_S__5A1E6BC1503E7E3B] PRIMARY KEY CLUSTERED  ([Feature], [CompatibleSchemaVersion])

END
ELSE
PRINT SPACE(10) + N'...ASPNET Tables already exists'

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_RegisterSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: aspnet_RegisterSchemaVersion updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:aspnet_RegisterSchemaVersion create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE[dbo].[aspnet_RegisterSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_RegisterSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_RegisterSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128),
    @IsCurrentVersion          bit,
    @RemoveIncompatibleSchema  bit
AS
BEGIN
    IF( @RemoveIncompatibleSchema = 1 )
    BEGIN
        DELETE FROM dbo.aspnet_SchemaVersions WHERE Feature = LOWER( @Feature ) collate database_default
    END
    ELSE
    BEGIN
        IF( @IsCurrentVersion = 1 )
        BEGIN
            UPDATE dbo.aspnet_SchemaVersions
            SET IsCurrentVersion = 0
            WHERE Feature = LOWER( @Feature ) collate database_default
        END
    END

    INSERT  dbo.aspnet_SchemaVersions( Feature, CompatibleSchemaVersion, IsCurrentVersion )
    VALUES( LOWER( @Feature ), @CompatibleSchemaVersion, @IsCurrentVersion )
END
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_CheckSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_CheckSchemaVersion] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_CheckSchemaVersion] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_CheckSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_CheckSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_CheckSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128)
AS
BEGIN
    IF (EXISTS( SELECT  *
                FROM    dbo.aspnet_SchemaVersions
                WHERE   Feature = LOWER( @Feature ) collate database_default AND
                        CompatibleSchemaVersion = @CompatibleSchemaVersion ))
        RETURN 0

    RETURN 1
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_Applications')
BEGIN

PRINT N'Creating [dbo].[aspnet_Applications]'

CREATE TABLE [dbo].[aspnet_Applications]
(
[ApplicationName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredApplicationName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[ApplicationId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Ap__Appli__145C0A3F] DEFAULT (newid()),
[Description] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Applications_Index] on [dbo].[aspnet_Applications]'

CREATE CLUSTERED INDEX [aspnet_Applications_Index] ON [dbo].[aspnet_Applications] ([LoweredApplicationName])


PRINT N'Adding constraints to [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [UQ__aspnet_A__309103317CF8590C] UNIQUE NONCLUSTERED  ([ApplicationName])


PRINT N'Adding constraints to [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [UQ__aspnet_A__17477DE4768CAD81] UNIQUE NONCLUSTERED  ([LoweredApplicationName])

PRINT N'Creating primary key [PK__aspnet_A__C93A4C98519285D6] on [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [PK__aspnet_A__C93A4C98519285D6] PRIMARY KEY NONCLUSTERED  ([ApplicationId])

PRINT N'Creating [dbo].[aspnet_Applications_CreateApplication]'

END
ELSE
PRINT SPACE(10) + '...ASPNET Table [aspnet_Applications] exsits'
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Applications_CreateApplication'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Applications_CreateApplication] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Applications_CreateApplication] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Applications_CreateApplication]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_Applications_CreateApplication]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Applications_CreateApplication]
    @ApplicationName      nvarchar(256),
    @ApplicationId        uniqueidentifier OUTPUT
AS
BEGIN
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName

    IF(@ApplicationId IS NULL)
    BEGIN
        DECLARE @TranStarted   bit
        SET @TranStarted = 0

        IF( @@TRANCOUNT = 0 )
        BEGIN
	        BEGIN TRANSACTION
	        SET @TranStarted = 1
        END
        ELSE
    	    SET @TranStarted = 0

        SELECT  @ApplicationId = ApplicationId
        FROM dbo.aspnet_Applications WITH (UPDLOCK, HOLDLOCK)
        WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName

        IF(@ApplicationId IS NULL)
        BEGIN
            SELECT  @ApplicationId = NEWID()
            INSERT  dbo.aspnet_Applications (ApplicationId, ApplicationName, LoweredApplicationName)
            VALUES  (@ApplicationId, @ApplicationName, LOWER(@ApplicationName))
        END


        IF( @TranStarted = 1 )
        BEGIN
            IF(@@ERROR = 0)
            BEGIN
	        SET @TranStarted = 0
	        COMMIT TRANSACTION
            END
            ELSE
            BEGIN
                SET @TranStarted = 0
                ROLLBACK TRANSACTION
            END
        END
    END
END
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'aspnet_UnRegisterSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_UnRegisterSchemaVersion] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UnRegisterSchemaVersion] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UnRegisterSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_UnRegisterSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

Alter PROCEDURE [dbo].[aspnet_UnRegisterSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128)
AS
BEGIN
    DELETE FROM dbo.aspnet_SchemaVersions
        WHERE   Feature = LOWER(@Feature) collate database_default AND @CompatibleSchemaVersion = CompatibleSchemaVersion
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_Users')
BEGIN

PRINT N'Creating [dbo].[aspnet_Users]'

CREATE TABLE [dbo].[aspnet_Users]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Us__UserI__182C9B23] DEFAULT (newid()),
[UserName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredUserName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[MobileAlias] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__aspnet_Us__Mobil__1920BF5C] DEFAULT (NULL),
[IsAnonymous] [bit] NOT NULL CONSTRAINT [DF__aspnet_Us__IsAno__1A14E395] DEFAULT ((0)),
[LastActivityDate] [datetime] NOT NULL
)

PRINT N'Creating index [aspnet_Users_Index] on [dbo].[aspnet_Users]'

CREATE UNIQUE CLUSTERED INDEX [aspnet_Users_Index] ON [dbo].[aspnet_Users] ([ApplicationId], [LoweredUserName])

PRINT N'Creating index [aspnet_Users_Index2] on [dbo].[aspnet_Users]'

CREATE NONCLUSTERED INDEX [aspnet_Users_Index2] ON [dbo].[aspnet_Users] ([ApplicationId], [LastActivityDate])

PRINT N'Creating primary key [PK__aspnet_U__1788CC4DF64A6C1A] on [dbo].[aspnet_Users]'

ALTER TABLE [dbo].[aspnet_Users] ADD CONSTRAINT [PK__aspnet_U__1788CC4DF64A6C1A] PRIMARY KEY NONCLUSTERED  ([UserId])

END

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Users_CreateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_Users_CreateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Users_CreateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Users_CreateUser]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[dbo].[aspnet_Users_CreateUser]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Users_CreateUser]
    @ApplicationId    uniqueidentifier,
    @UserName         nvarchar(256),
    @IsUserAnonymous  bit,
    @LastActivityDate DATETIME,
    @UserId           uniqueidentifier OUTPUT
AS
BEGIN
    IF( @UserId IS NULL )
        SELECT @UserId = NEWID()
    ELSE
    BEGIN
        IF( EXISTS( SELECT UserId FROM dbo.aspnet_Users
                    WHERE @UserId = UserId ) )
            RETURN -1
    END

    INSERT dbo.aspnet_Users (ApplicationId, UserId, UserName, LoweredUserName, IsAnonymous, LastActivityDate)
    VALUES (@ApplicationId, @UserId, @UserName, LOWER(@UserName), @IsUserAnonymous, @LastActivityDate)

    RETURN 0
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] LIKE 'aspnet_UsersInRoles')
BEGIN

PRINT N'Creating [dbo].[aspnet_UsersInRoles]'

CREATE TABLE [dbo].[aspnet_UsersInRoles]
(
[UserId] [uniqueidentifier] NOT NULL,
[RoleId] [uniqueidentifier] NOT NULL
)

PRINT N'Creating primary key [PK__aspnet_U__AF2760AD06FC699F] on [dbo].[aspnet_UsersInRoles]'

ALTER TABLE [dbo].[aspnet_UsersInRoles] ADD CONSTRAINT [PK__aspnet_U__AF2760AD06FC699F] PRIMARY KEY CLUSTERED  ([UserId], [RoleId])


PRINT N'Creating index [aspnet_UsersInRoles_index] on [dbo].[aspnet_UsersInRoles]'

CREATE NONCLUSTERED INDEX [aspnet_UsersInRoles_index] ON [dbo].[aspnet_UsersInRoles] ([RoleId])

PRINT N'Creating [dbo].[aspnet_Membership]'

CREATE TABLE [dbo].[aspnet_Membership]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[Password] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[PasswordFormat] [int] NOT NULL CONSTRAINT [DF__aspnet_Me__Passw__29572725] DEFAULT ((0)),
[PasswordSalt] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[MobilePIN] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[Email] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[LoweredEmail] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[PasswordQuestion] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[PasswordAnswer] [nvarchar] (128) COLLATE Latin1_General_CI_AS NULL,
[IsApproved] [bit] NOT NULL,
[IsLockedOut] [bit] NOT NULL,
[CreateDate] [datetime] NOT NULL,
[LastLoginDate] [datetime] NOT NULL,
[LastPasswordChangedDate] [datetime] NOT NULL,
[LastLockoutDate] [datetime] NOT NULL,
[FailedPasswordAttemptCount] [int] NOT NULL,
[FailedPasswordAttemptWindowStart] [datetime] NOT NULL,
[FailedPasswordAnswerAttemptCount] [int] NOT NULL,
[FailedPasswordAnswerAttemptWindowStart] [datetime] NOT NULL,
[Comment] [ntext] COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Membership_index] on [dbo].[aspnet_Membership]'

CREATE CLUSTERED INDEX [aspnet_Membership_index] ON [dbo].[aspnet_Membership] ([ApplicationId], [LoweredEmail])

PRINT N'Creating primary key [PK__aspnet_M__1788CC4D988350DB] on [dbo].[aspnet_Membership]'

ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [PK__aspnet_M__1788CC4D988350DB] PRIMARY KEY NONCLUSTERED  ([UserId])

END

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Users_DeleteUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_Users_DeleteUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure: [aspnet_Users_DeleteUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Users_DeleteUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Users_DeleteUser]'

-- the following section will be always executed
SET NOEXEC OFF;
GO

Alter PROCEDURE [dbo].[aspnet_Users_DeleteUser]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @TablesToDeleteFrom int,
    @NumTablesDeletedFrom int OUTPUT
AS
BEGIN
    DECLARE @UserId               uniqueidentifier
    SELECT  @UserId               = NULL
    SELECT  @NumTablesDeletedFrom = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
	SET @TranStarted = 0

    DECLARE @ErrorCode   int
    DECLARE @RowCount    int

    SET @ErrorCode = 0
    SET @RowCount  = 0

    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a
    WHERE   u.LoweredUserName       = LOWER(@UserName)
        AND u.ApplicationId         = a.ApplicationId
        AND LOWER(@ApplicationName) = a.LoweredApplicationName

    IF (@UserId IS NULL)
    BEGIN
        GOTO Cleanup
    END

    -- Delete from Membership table if (@TablesToDeleteFrom & 1) is set
    IF ((@TablesToDeleteFrom & 1) <> 0 AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_MembershipUsers') AND (type = 'V'))))
    BEGIN
        DELETE FROM dbo.aspnet_Membership WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
               @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_UsersInRoles table if (@TablesToDeleteFrom & 2) is set
    IF ((@TablesToDeleteFrom & 2) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_UsersInRoles') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_UsersInRoles WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_Profile table if (@TablesToDeleteFrom & 4) is set
    IF ((@TablesToDeleteFrom & 4) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Profiles') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_Profile WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_PersonalizationPerUser table if (@TablesToDeleteFrom & 8) is set
    IF ((@TablesToDeleteFrom & 8) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_WebPartState_User') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_PersonalizationPerUser WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_Users table if (@TablesToDeleteFrom & 1,2,4 & 8) are all set
    IF ((@TablesToDeleteFrom & 1) <> 0 AND
        (@TablesToDeleteFrom & 2) <> 0 AND
        (@TablesToDeleteFrom & 4) <> 0 AND
        (@TablesToDeleteFrom & 8) <> 0 AND
        (EXISTS (SELECT UserId FROM dbo.aspnet_Users WHERE @UserId = UserId)))
    BEGIN
        DELETE FROM dbo.aspnet_Users WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    IF( @TranStarted = 1 )
    BEGIN
	    SET @TranStarted = 0
	    COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:
    SET @NumTablesDeletedFrom = 0

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
	    ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END

GO


IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] LIKE 'aspnet_Roles')
BEGIN

PRINT N'Creating [dbo].[aspnet_Roles]'


CREATE TABLE [dbo].[aspnet_Roles]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[RoleId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Ro__RoleI__3D5E1FD2] DEFAULT (newid()),
[RoleName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredRoleName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[Description] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Roles_index1] on [dbo].[aspnet_Roles]'

CREATE UNIQUE CLUSTERED INDEX [aspnet_Roles_index1] ON [dbo].[aspnet_Roles] ([ApplicationId], [LoweredRoleName])

PRINT N'Creating primary key [PK__aspnet_R__8AFACE1B36FD1B86] on [dbo].[aspnet_Roles]'

ALTER TABLE [dbo].[aspnet_Roles] ADD CONSTRAINT [PK__aspnet_R__8AFACE1B36FD1B86] PRIMARY KEY NONCLUSTERED  ([RoleId])

PRINT(N'Add constraints to [dbo].[aspnet_UsersInRoles]')
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])


END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_AnyDataInTables'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_AnyDataInTables] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_AnyDataInTables] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_AnyDataInTables]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_AnyDataInTables]'
-- the following section will be always executed
SET NOEXEC OFF;
GO



Alter PROCEDURE [dbo].[aspnet_AnyDataInTables]
    @TablesToCheck int
AS
BEGIN
    -- Check Membership table if (@TablesToCheck & 1) is set
    IF ((@TablesToCheck & 1) <> 0 AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_MembershipUsers') AND (type = 'V'))))
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Membership))
        BEGIN
            SELECT N'aspnet_Membership'
            RETURN
        END
    END

    -- Check aspnet_Roles table if (@TablesToCheck & 2) is set
    IF ((@TablesToCheck & 2) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Roles') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 RoleId FROM dbo.aspnet_Roles))
        BEGIN
            SELECT N'aspnet_Roles'
            RETURN
        END
    END

    -- Check aspnet_Profile table if (@TablesToCheck & 4) is set
    IF ((@TablesToCheck & 4) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Profiles') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Profile))
        BEGIN
            SELECT N'aspnet_Profile'
            RETURN
        END
    END

    -- Check aspnet_PersonalizationPerUser table if (@TablesToCheck & 8) is set
    IF ((@TablesToCheck & 8) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_WebPartState_User') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_PersonalizationPerUser))
        BEGIN
            SELECT N'aspnet_PersonalizationPerUser'
            RETURN
        END
    END

    -- Check aspnet_PersonalizationPerUser table if (@TablesToCheck & 16) is set
    IF ((@TablesToCheck & 16) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'aspnet_WebEvent_LogEvent') AND (type = 'P'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 * FROM dbo.aspnet_WebEvent_Events))
        BEGIN
            SELECT N'aspnet_WebEvent_Events'
            RETURN
        END
    END

    -- Check aspnet_Users table if (@TablesToCheck & 1,2,4 & 8) are all set
    IF ((@TablesToCheck & 1) <> 0 AND
        (@TablesToCheck & 2) <> 0 AND
        (@TablesToCheck & 4) <> 0 AND
        (@TablesToCheck & 8) <> 0 AND
        (@TablesToCheck & 32) <> 0 AND
        (@TablesToCheck & 128) <> 0 AND
        (@TablesToCheck & 256) <> 0 AND
        (@TablesToCheck & 512) <> 0 AND
        (@TablesToCheck & 1024) <> 0)
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Users))
        BEGIN
            SELECT N'aspnet_Users'
            RETURN
        END
        IF (EXISTS(SELECT TOP 1 ApplicationId FROM dbo.aspnet_Applications))
        BEGIN
            SELECT N'aspnet_Applications'
            RETURN
        END
    END
END
GO



IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Applications'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Applications Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Applications Created'
GO
CREATE VIEW vw_aspnet_Applications
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_Applications]
  AS 
  SELECT [ApplicationName], [LoweredApplicationName], [ApplicationId], [Description]
  FROM [dbo].[aspnet_Applications]

  GO
  IF EXISTS ( SELECT  1
              FROM    INFORMATION_SCHEMA.[VIEWS]
              WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Users'
                      AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Users Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Users Created'
GO
  CREATE VIEW vw_aspnet_Users
  AS
  
  
         SELECT   [Column1] = 'UNDER CONSTRUCTION';
  	GO
  SET NOEXEC OFF;
  	GO	
  
  ALTER VIEW [dbo].[vw_aspnet_Users]
  AS SELECT [ApplicationId], [UserId], [UserName], [LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]
  FROM [dbo].[aspnet_Users]

GO
  



IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_CreateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_CreateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_CreateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Membership_CreateUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_CreateUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Membership_CreateUser]
    @ApplicationName                        nvarchar(256),
    @UserName                               nvarchar(256),
    @Password                               nvarchar(128),
    @PasswordSalt                           nvarchar(128),
    @Email                                  nvarchar(256),
    @PasswordQuestion                       nvarchar(256),
    @PasswordAnswer                         nvarchar(128),
    @IsApproved                             bit,
    @CurrentTimeUtc                         datetime,
    @CreateDate                             datetime = NULL,
    @UniqueEmail                            int      = 0,
    @PasswordFormat                         int      = 0,
    @UserId                                 uniqueidentifier OUTPUT
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL

    DECLARE @NewUserId uniqueidentifier
    SELECT @NewUserId = NULL

    DECLARE @IsLockedOut bit
    SET @IsLockedOut = 0

    DECLARE @LastLockoutDate  datetime
    SET @LastLockoutDate = CONVERT( datetime, '17540101', 112 )

    DECLARE @FailedPasswordAttemptCount int
    SET @FailedPasswordAttemptCount = 0

    DECLARE @FailedPasswordAttemptWindowStart  datetime
    SET @FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 )

    DECLARE @FailedPasswordAnswerAttemptCount int
    SET @FailedPasswordAnswerAttemptCount = 0

    DECLARE @FailedPasswordAnswerAttemptWindowStart  datetime
    SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )

    DECLARE @NewUserCreated bit
    DECLARE @ReturnValue   int
    SET @ReturnValue = 0

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    EXEC dbo.aspnet_Applications_CreateApplication @ApplicationName, @ApplicationId OUTPUT

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    SET @CreateDate = @CurrentTimeUtc

    SELECT  @NewUserId = UserId FROM dbo.aspnet_Users WHERE LOWER(@UserName) = LoweredUserName AND @ApplicationId = ApplicationId
    IF ( @NewUserId IS NULL )
    BEGIN
        SET @NewUserId = @UserId
        EXEC @ReturnValue = dbo.aspnet_Users_CreateUser @ApplicationId, @UserName, 0, @CreateDate, @NewUserId OUTPUT
        SET @NewUserCreated = 1
    END
    ELSE
    BEGIN
        SET @NewUserCreated = 0
        IF( @NewUserId <> @UserId AND @UserId IS NOT NULL )
        BEGIN
            SET @ErrorCode = 6
            GOTO Cleanup
        END
    END

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @ReturnValue = -1 )
    BEGIN
        SET @ErrorCode = 10
        GOTO Cleanup
    END

    IF ( EXISTS ( SELECT UserId
                  FROM   dbo.aspnet_Membership
                  WHERE  @NewUserId = UserId ) )
    BEGIN
        SET @ErrorCode = 6
        GOTO Cleanup
    END

    SET @UserId = @NewUserId

    IF (@UniqueEmail = 1)
    BEGIN
        IF (EXISTS (SELECT *
                    FROM  dbo.aspnet_Membership m WITH ( UPDLOCK, HOLDLOCK )
                    WHERE ApplicationId = @ApplicationId AND LoweredEmail = LOWER(@Email)))
        BEGIN
            SET @ErrorCode = 7
            GOTO Cleanup
        END
    END

    IF (@NewUserCreated = 0)
    BEGIN
        UPDATE dbo.aspnet_Users
        SET    LastActivityDate = @CreateDate
        WHERE  @UserId = UserId
        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    INSERT INTO dbo.aspnet_Membership
                ( ApplicationId,
                  UserId,
                  Password,
                  PasswordSalt,
                  Email,
                  LoweredEmail,
                  PasswordQuestion,
                  PasswordAnswer,
                  PasswordFormat,
                  IsApproved,
                  IsLockedOut,
                  CreateDate,
                  LastLoginDate,
                  LastPasswordChangedDate,
                  LastLockoutDate,
                  FailedPasswordAttemptCount,
                  FailedPasswordAttemptWindowStart,
                  FailedPasswordAnswerAttemptCount,
                  FailedPasswordAnswerAttemptWindowStart )
         VALUES ( @ApplicationId,
                  @UserId,
                  @Password,
                  @PasswordSalt,
                  @Email,
                  LOWER(@Email),
                  @PasswordQuestion,
                  @PasswordAnswer,
                  @PasswordFormat,
                  @IsApproved,
                  @IsLockedOut,
                  @CreateDate,
                  @CreateDate,
                  @CreateDate,
                  @LastLockoutDate,
                  @FailedPasswordAttemptCount,
                  @FailedPasswordAttemptWindowStart,
                  @FailedPasswordAnswerAttemptCount,
                  @FailedPasswordAnswerAttemptWindowStart )

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
	    SET @TranStarted = 0
	    COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByName'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByName] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByName] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByName]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByName]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetUserByName]
    @ApplicationName      nvarchar(256),
    @UserName             nvarchar(256),
    @CurrentTimeUtc       datetime,
    @UpdateLastActivity   bit = 0
AS
BEGIN
    DECLARE @UserId uniqueidentifier

    IF (@UpdateLastActivity = 1)
    BEGIN
        -- select user ID from aspnet_users table
        SELECT TOP 1 @UserId = u.UserId
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE    LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                LOWER(@UserName) = u.LoweredUserName AND u.UserId = m.UserId

        IF (@@ROWCOUNT = 0) -- Username not found
            RETURN -1

        UPDATE   dbo.aspnet_Users
        SET      LastActivityDate = @CurrentTimeUtc
        WHERE    @UserId = UserId

        SELECT m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
                m.CreateDate, m.LastLoginDate, u.LastActivityDate, m.LastPasswordChangedDate,
                u.UserId, m.IsLockedOut, m.LastLockoutDate
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE  @UserId = u.UserId AND u.UserId = m.UserId 
    END
    ELSE
    BEGIN
        SELECT TOP 1 m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
                m.CreateDate, m.LastLoginDate, u.LastActivityDate, m.LastPasswordChangedDate,
                u.UserId, m.IsLockedOut,m.LastLockoutDate
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE    LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                LOWER(@UserName) = u.LoweredUserName AND u.UserId = m.UserId

        IF (@@ROWCOUNT = 0) -- Username not found
            RETURN -1
    END

    RETURN 0
END
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByUserId'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByUserId] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByUserId] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByUserId]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByUserId]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_GetUserByUserId]
    @UserId               uniqueidentifier,
    @CurrentTimeUtc       datetime,
    @UpdateLastActivity   bit = 0
AS
BEGIN
    IF ( @UpdateLastActivity = 1 )
    BEGIN
        UPDATE   dbo.aspnet_Users
        SET      LastActivityDate = @CurrentTimeUtc
        FROM     dbo.aspnet_Users
        WHERE    @UserId = UserId

        IF ( @@ROWCOUNT = 0 ) -- User ID not found
            RETURN -1
    END

    SELECT  m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate, m.LastLoginDate, u.LastActivityDate,
            m.LastPasswordChangedDate, u.UserName, m.IsLockedOut,
            m.LastLockoutDate
    FROM    dbo.aspnet_Users u, dbo.aspnet_Membership m
    WHERE   @UserId = u.UserId AND u.UserId = m.UserId

    IF ( @@ROWCOUNT = 0 ) -- User ID not found
       RETURN -1

    RETURN 0
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByEmail'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByEmail] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByEmail] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByEmail]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByEmail]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Membership_GetUserByEmail]
    @ApplicationName  nvarchar(256),
    @Email            nvarchar(256)
AS
BEGIN
    IF( @Email IS NULL )
        SELECT  u.UserName
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                u.UserId = m.UserId AND
                m.LoweredEmail IS NULL
    ELSE
        SELECT  u.UserName
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                u.UserId = m.UserId AND
                LOWER(@Email) = m.LoweredEmail

    IF (@@rowcount = 0)
        RETURN(1)
    RETURN(0)
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetPasswordWithFormat'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetPasswordWithFormat] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetPasswordWithFormat] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetPasswordWithFormat]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetPasswordWithFormat]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_GetPasswordWithFormat]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @UpdateLastLoginActivityDate    bit,
    @CurrentTimeUtc                 datetime
AS
BEGIN
    DECLARE @IsLockedOut                        bit
    DECLARE @UserId                             uniqueidentifier
    DECLARE @Password                           nvarchar(128)
    DECLARE @PasswordSalt                       nvarchar(128)
    DECLARE @PasswordFormat                     int
    DECLARE @FailedPasswordAttemptCount         int
    DECLARE @FailedPasswordAnswerAttemptCount   int
    DECLARE @IsApproved                         bit
    DECLARE @LastActivityDate                   datetime
    DECLARE @LastLoginDate                      datetime

    SELECT  @UserId          = NULL

    SELECT  @UserId = u.UserId, @IsLockedOut = m.IsLockedOut, @Password=Password, @PasswordFormat=PasswordFormat,
            @PasswordSalt=PasswordSalt, @FailedPasswordAttemptCount=FailedPasswordAttemptCount,
		    @FailedPasswordAnswerAttemptCount=FailedPasswordAnswerAttemptCount, @IsApproved=IsApproved,
            @LastActivityDate = LastActivityDate, @LastLoginDate = LastLoginDate
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF (@UserId IS NULL)
        RETURN 1

    IF (@IsLockedOut = 1)
        RETURN 99

    SELECT   @Password, @PasswordFormat, @PasswordSalt, @FailedPasswordAttemptCount,
             @FailedPasswordAnswerAttemptCount, @IsApproved, @LastLoginDate, @LastActivityDate

    IF (@UpdateLastLoginActivityDate = 1 AND @IsApproved = 1)
    BEGIN
        UPDATE  dbo.aspnet_Membership
        SET     LastLoginDate = @CurrentTimeUtc
        WHERE   UserId = @UserId

        UPDATE  dbo.aspnet_Users
        SET     LastActivityDate = @CurrentTimeUtc
        WHERE   @UserId = UserId
    END


    RETURN 0
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UpdateUserInfo'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UpdateUserInfo] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UpdateUserInfo] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_UpdateUserInfo]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UpdateUserInfo]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_UpdateUserInfo]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @IsPasswordCorrect              bit,
    @UpdateLastLoginActivityDate    bit,
    @MaxInvalidPasswordAttempts     int,
    @PasswordAttemptWindow          int,
    @CurrentTimeUtc                 datetime,
    @LastLoginDate                  datetime,
    @LastActivityDate               datetime
AS
BEGIN
    DECLARE @UserId                                 uniqueidentifier
    DECLARE @IsApproved                             bit
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId,
            @IsApproved = m.IsApproved,
            @IsLockedOut = m.IsLockedOut,
            @LastLockoutDate = m.LastLockoutDate,
            @FailedPasswordAttemptCount = m.FailedPasswordAttemptCount,
            @FailedPasswordAttemptWindowStart = m.FailedPasswordAttemptWindowStart,
            @FailedPasswordAnswerAttemptCount = m.FailedPasswordAnswerAttemptCount,
            @FailedPasswordAnswerAttemptWindowStart = m.FailedPasswordAnswerAttemptWindowStart
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m WITH ( UPDLOCK )
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF ( @@rowcount = 0 )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    IF( @IsLockedOut = 1 )
    BEGIN
        GOTO Cleanup
    END

    IF( @IsPasswordCorrect = 0 )
    BEGIN
        IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAttemptWindowStart ) )
        BEGIN
            SET @FailedPasswordAttemptWindowStart = @CurrentTimeUtc
            SET @FailedPasswordAttemptCount = 1
        END
        ELSE
        BEGIN
            SET @FailedPasswordAttemptWindowStart = @CurrentTimeUtc
            SET @FailedPasswordAttemptCount = @FailedPasswordAttemptCount + 1
        END

        BEGIN
            IF( @FailedPasswordAttemptCount >= @MaxInvalidPasswordAttempts )
            BEGIN
                SET @IsLockedOut = 1
                SET @LastLockoutDate = @CurrentTimeUtc
            END
        END
    END
    ELSE
    BEGIN
        IF( @FailedPasswordAttemptCount > 0 OR @FailedPasswordAnswerAttemptCount > 0 )
        BEGIN
            SET @FailedPasswordAttemptCount = 0
            SET @FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            SET @FailedPasswordAnswerAttemptCount = 0
            SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            SET @LastLockoutDate = CONVERT( datetime, '17540101', 112 )
        END
    END

    IF( @UpdateLastLoginActivityDate = 1 )
    BEGIN
        UPDATE  dbo.aspnet_Users
        SET     LastActivityDate = @LastActivityDate
        WHERE   @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END

        UPDATE  dbo.aspnet_Membership
        SET     LastLoginDate = @LastLoginDate
        WHERE   UserId = @UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END


    UPDATE dbo.aspnet_Membership
    SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
        FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
        FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
        FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
        FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
    WHERE @UserId = UserId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetPassword]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


GO
ALTER PROCEDURE [dbo].[aspnet_Membership_GetPassword]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @MaxInvalidPasswordAttempts     int,
    @PasswordAttemptWindow          int,
    @CurrentTimeUtc                 datetime,
    @PasswordAnswer                 nvarchar(128) = NULL
AS
BEGIN
    DECLARE @UserId                                 uniqueidentifier
    DECLARE @PasswordFormat                         int
    DECLARE @Password                               nvarchar(128)
    DECLARE @passAns                                nvarchar(128)
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId,
            @Password = m.Password,
            @passAns = m.PasswordAnswer,
            @PasswordFormat = m.PasswordFormat,
            @IsLockedOut = m.IsLockedOut,
            @LastLockoutDate = m.LastLockoutDate,
            @FailedPasswordAttemptCount = m.FailedPasswordAttemptCount,
            @FailedPasswordAttemptWindowStart = m.FailedPasswordAttemptWindowStart,
            @FailedPasswordAnswerAttemptCount = m.FailedPasswordAnswerAttemptCount,
            @FailedPasswordAnswerAttemptWindowStart = m.FailedPasswordAnswerAttemptWindowStart
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m WITH ( UPDLOCK )
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF ( @@rowcount = 0 )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    IF( @IsLockedOut = 1 )
    BEGIN
        SET @ErrorCode = 99
        GOTO Cleanup
    END

    IF ( NOT( @PasswordAnswer IS NULL ) )
    BEGIN
        IF( ( @passAns IS NULL ) OR ( LOWER( @passAns ) <> LOWER( @PasswordAnswer ) ) )
        BEGIN
            IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAnswerAttemptWindowStart ) )
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = 1
            END
            ELSE
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount + 1
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
            END

            BEGIN
                IF( @FailedPasswordAnswerAttemptCount >= @MaxInvalidPasswordAttempts )
                BEGIN
                    SET @IsLockedOut = 1
                    SET @LastLockoutDate = @CurrentTimeUtc
                END
            END

            SET @ErrorCode = 3
        END
        ELSE
        BEGIN
            IF( @FailedPasswordAnswerAttemptCount > 0 )
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = 0
                SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            END
        END

        UPDATE dbo.aspnet_Membership
        SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
            FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
            FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
            FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
            FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
        WHERE @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    IF( @ErrorCode = 0 )
        SELECT @Password, @PasswordFormat

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_SetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_SetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_SetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_SetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_SetPassword]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_SetPassword]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @NewPassword      nvarchar(128),
    @PasswordSalt     nvarchar(128),
    @CurrentTimeUtc   datetime,
    @PasswordFormat   int = 0
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF (@UserId IS NULL)
        RETURN(1)

    UPDATE dbo.aspnet_Membership
    SET Password = @NewPassword, PasswordFormat = @PasswordFormat, PasswordSalt = @PasswordSalt,
        LastPasswordChangedDate = @CurrentTimeUtc
    WHERE @UserId = UserId
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_ResetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_ResetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_ResetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_ResetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_ResetPassword]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_ResetPassword]
    @ApplicationName             nvarchar(256),
    @UserName                    nvarchar(256),
    @NewPassword                 nvarchar(128),
    @MaxInvalidPasswordAttempts  int,
    @PasswordAttemptWindow       int,
    @PasswordSalt                nvarchar(128),
    @CurrentTimeUtc              datetime,
    @PasswordFormat              int = 0,
    @PasswordAnswer              nvarchar(128) = NULL
AS
BEGIN
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @UserId                                 uniqueidentifier
    SET     @UserId = NULL

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF ( @UserId IS NULL )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    SELECT @IsLockedOut = IsLockedOut,
           @LastLockoutDate = LastLockoutDate,
           @FailedPasswordAttemptCount = FailedPasswordAttemptCount,
           @FailedPasswordAttemptWindowStart = FailedPasswordAttemptWindowStart,
           @FailedPasswordAnswerAttemptCount = FailedPasswordAnswerAttemptCount,
           @FailedPasswordAnswerAttemptWindowStart = FailedPasswordAnswerAttemptWindowStart
    FROM dbo.aspnet_Membership WITH ( UPDLOCK )
    WHERE @UserId = UserId

    IF( @IsLockedOut = 1 )
    BEGIN
        SET @ErrorCode = 99
        GOTO Cleanup
    END

    UPDATE dbo.aspnet_Membership
    SET    Password = @NewPassword,
           LastPasswordChangedDate = @CurrentTimeUtc,
           PasswordFormat = @PasswordFormat,
           PasswordSalt = @PasswordSalt
    WHERE  @UserId = UserId AND
           ( ( @PasswordAnswer IS NULL ) OR ( LOWER( PasswordAnswer ) = LOWER( @PasswordAnswer ) ) )

    IF ( @@ROWCOUNT = 0 )
        BEGIN
            IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAnswerAttemptWindowStart ) )
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = 1
            END
            ELSE
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount + 1
            END

            BEGIN
                IF( @FailedPasswordAnswerAttemptCount >= @MaxInvalidPasswordAttempts )
                BEGIN
                    SET @IsLockedOut = 1
                    SET @LastLockoutDate = @CurrentTimeUtc
                END
            END

            SET @ErrorCode = 3
        END
    ELSE
        BEGIN
            IF( @FailedPasswordAnswerAttemptCount > 0 )
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = 0
                SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            END
        END

    IF( NOT ( @PasswordAnswer IS NULL ) )
    BEGIN
        UPDATE dbo.aspnet_Membership
        SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
            FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
            FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
            FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
            FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
        WHERE @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UnlockUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UnlockUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UnlockUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Membership_UnlockUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UnlockUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_UnlockUser]
    @ApplicationName                         nvarchar(256),
    @UserName                                nvarchar(256)
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF ( @UserId IS NULL )
        RETURN 1

    UPDATE dbo.aspnet_Membership
    SET IsLockedOut = 0,
        FailedPasswordAttemptCount = 0,
        FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 ),
        FailedPasswordAnswerAttemptCount = 0,
        FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 ),
        LastLockoutDate = CONVERT( datetime, '17540101', 112 )
    WHERE @UserId = UserId

    RETURN 0
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UpdateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UpdateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UpdateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE   [dbo].[aspnet_Membership_UpdateUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UpdateUser]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_UpdateUser]
    @ApplicationName      nvarchar(256),
    @UserName             nvarchar(256),
    @Email                nvarchar(256),
    @Comment              ntext,
    @IsApproved           bit,
    @LastLoginDate        datetime,
    @LastActivityDate     datetime,
    @UniqueEmail          int,
    @CurrentTimeUtc       datetime
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId, @ApplicationId = a.ApplicationId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF (@UserId IS NULL)
        RETURN(1)

    IF (@UniqueEmail = 1)
    BEGIN
        IF (EXISTS (SELECT *
                    FROM  dbo.aspnet_Membership WITH (UPDLOCK, HOLDLOCK)
                    WHERE ApplicationId = @ApplicationId  AND @UserId <> UserId AND LoweredEmail = LOWER(@Email)))
        BEGIN
            RETURN(7)
        END
    END

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
	SET @TranStarted = 0

    UPDATE dbo.aspnet_Users WITH (ROWLOCK)
    SET
         LastActivityDate = @LastActivityDate
    WHERE
       @UserId = UserId

    IF( @@ERROR <> 0 )
        GOTO Cleanup

    UPDATE dbo.aspnet_Membership WITH (ROWLOCK)
    SET
         Email            = @Email,
         LoweredEmail     = LOWER(@Email),
         Comment          = @Comment,
         IsApproved       = @IsApproved,
         LastLoginDate    = @LastLoginDate
    WHERE
       @UserId = UserId

    IF( @@ERROR <> 0 )
        GOTO Cleanup

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN -1
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_ChangePasswordQuestionAndAnswer'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_ChangePasswordQuestionAndAnswer] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_ChangePasswordQuestionAndAnswer] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]
    @ApplicationName       nvarchar(256),
    @UserName              nvarchar(256),
    @NewPasswordQuestion   nvarchar(256),
    @NewPasswordAnswer     nvarchar(128)
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Membership m, dbo.aspnet_Users u, dbo.aspnet_Applications a
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId
    IF (@UserId IS NULL)
    BEGIN
        RETURN(1)
    END

    UPDATE dbo.aspnet_Membership
    SET    PasswordQuestion = @NewPasswordQuestion, PasswordAnswer = @NewPasswordAnswer
    WHERE  UserId=@UserId
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetAllUsers'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetAllUsers] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetAllUsers] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetAllUsers]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetAllUsers]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetAllUsers]
    @ApplicationName       nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0


    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    INSERT INTO #PageIndexForUsers (UserId)
    SELECT u.UserId
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u
    WHERE  u.ApplicationId = @ApplicationId AND u.UserId = m.UserId
    ORDER BY u.UserName

    SELECT @TotalRecords = @@ROWCOUNT

    SELECT u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY u.UserName
    RETURN @TotalRecords
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetNumberOfUsersOnline'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetNumberOfUsersOnline] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetNumberOfUsersOnline] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetNumberOfUsersOnline]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetNumberOfUsersOnline]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetNumberOfUsersOnline]
    @ApplicationName            nvarchar(256),
    @MinutesSinceLastInActive   int,
    @CurrentTimeUtc             datetime
AS
BEGIN
    DECLARE @DateActive datetime
    SELECT  @DateActive = DATEADD(minute,  -(@MinutesSinceLastInActive), @CurrentTimeUtc)

    DECLARE @NumOnline int
    SELECT  @NumOnline = COUNT(*)
    FROM    dbo.aspnet_Users u WITH(NOLOCK),
            dbo.aspnet_Applications a WITH(NOLOCK),
            dbo.aspnet_Membership m WITH(NOLOCK)
    WHERE   u.ApplicationId = a.ApplicationId                  AND
            LastActivityDate > @DateActive                     AND
            a.LoweredApplicationName = LOWER(@ApplicationName) AND
            u.UserId = m.UserId
    RETURN(@NumOnline)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_FindUsersByName'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_FindUsersByName] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_FindUsersByName] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_FindUsersByName]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_FindUsersByName]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_FindUsersByName]
    @ApplicationName       nvarchar(256),
    @UserNameToMatch       nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0

    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    INSERT INTO #PageIndexForUsers (UserId)
        SELECT u.UserId
        FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND u.LoweredUserName LIKE LOWER(@UserNameToMatch)
        ORDER BY u.UserName


    SELECT  u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY u.UserName

    SELECT  @TotalRecords = COUNT(*)
    FROM    #PageIndexForUsers
    RETURN @TotalRecords
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_FindUsersByEmail'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_FindUsersByEmail] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_FindUsersByEmail] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE   [dbo].[aspnet_Membership_FindUsersByEmail]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO
PRINT N'Creating [dbo].[aspnet_Membership_FindUsersByEmail]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_FindUsersByEmail]
    @ApplicationName       nvarchar(256),
    @EmailToMatch          nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0

    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    IF( @EmailToMatch IS NULL )
        INSERT INTO #PageIndexForUsers (UserId)
            SELECT u.UserId
            FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
            WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND m.Email IS NULL
            ORDER BY m.LoweredEmail
    ELSE
        INSERT INTO #PageIndexForUsers (UserId)
            SELECT u.UserId
            FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
            WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND m.LoweredEmail LIKE LOWER(@EmailToMatch)
            ORDER BY m.LoweredEmail

    SELECT  u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY m.LoweredEmail

    SELECT  @TotalRecords = COUNT(*)
    FROM    #PageIndexForUsers
    RETURN @TotalRecords
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_MembershipUsers'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_MembershipUsers Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_MembershipUsers Created'
GO
CREATE VIEW vw_aspnet_MembershipUsers
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_MembershipUsers]
  AS SELECT members.[UserId],
            members.[PasswordFormat],
            members.[MobilePIN],
            members.[Email],
            members.[LoweredEmail],
            members.[PasswordQuestion],
            members.[PasswordAnswer],
            members.[IsApproved],
            members.[IsLockedOut],
            members.[CreateDate],
            members.[LastLoginDate],
            members.[LastPasswordChangedDate],
            members.[LastLockoutDate],
            members.[FailedPasswordAttemptCount],
            members.[FailedPasswordAttemptWindowStart],
            members.[FailedPasswordAnswerAttemptCount],
            members.[FailedPasswordAnswerAttemptWindowStart],
            members.[Comment],
            users.[ApplicationId],
            users.[UserName],
            users.[MobileAlias],
            users.[IsAnonymous],
            users.[LastActivityDate]
  FROM [dbo].[aspnet_Membership] members INNER JOIN [dbo].[aspnet_Users] users
      ON members.[UserId] = users.[UserId]
  

GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_IsUserInRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_IsUserInRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_IsUserInRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [aspnet_UsersInRoles_IsUserInRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_IsUserInRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_IsUserInRole]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(2)
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    DECLARE @RoleId uniqueidentifier
    SELECT  @RoleId = NULL

    SELECT  @UserId = UserId
    FROM    dbo.aspnet_Users
    WHERE   LoweredUserName = LOWER(@UserName) AND ApplicationId = @ApplicationId

    IF (@UserId IS NULL)
        RETURN(2)

    SELECT  @RoleId = RoleId
    FROM    dbo.aspnet_Roles
    WHERE   LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId

    IF (@RoleId IS NULL)
        RETURN(3)

    IF (EXISTS( SELECT * FROM dbo.aspnet_UsersInRoles WHERE  UserId = @UserId AND RoleId = @RoleId))
        RETURN(1)
    ELSE
        RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_GetRolesForUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_GetRolesForUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_GetRolesForUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_GetRolesForUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_GetRolesForUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_GetRolesForUser]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL

    SELECT  @UserId = UserId
    FROM    dbo.aspnet_Users
    WHERE   LoweredUserName = LOWER(@UserName) AND ApplicationId = @ApplicationId

    IF (@UserId IS NULL)
        RETURN(1)

    SELECT r.RoleName
    FROM   dbo.aspnet_Roles r, dbo.aspnet_UsersInRoles ur
    WHERE  r.RoleId = ur.RoleId AND r.ApplicationId = @ApplicationId AND ur.UserId = @UserId
    ORDER BY r.RoleName
    RETURN (0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_CreateRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_CreateRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_CreateRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_CreateRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_CreateRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_CreateRole]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
        BEGIN TRANSACTION
        SET @TranStarted = 1
    END
    ELSE
        SET @TranStarted = 0

    EXEC dbo.aspnet_Applications_CreateApplication @ApplicationName, @ApplicationId OUTPUT

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF (EXISTS(SELECT RoleId FROM dbo.aspnet_Roles WHERE LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId))
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    INSERT INTO dbo.aspnet_Roles
                (ApplicationId, RoleName, LoweredRoleName)
         VALUES (@ApplicationId, @RoleName, LOWER(@RoleName))

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        COMMIT TRANSACTION
    END

    RETURN(0)

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_DeleteRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_DeleteRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_DeleteRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_DeleteRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_DeleteRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_DeleteRole]
    @ApplicationName            nvarchar(256),
    @RoleName                   nvarchar(256),
    @DeleteOnlyIfRoleIsEmpty    bit
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
        BEGIN TRANSACTION
        SET @TranStarted = 1
    END
    ELSE
        SET @TranStarted = 0

    DECLARE @RoleId   uniqueidentifier
    SELECT  @RoleId = NULL
    SELECT  @RoleId = RoleId FROM dbo.aspnet_Roles WHERE LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId

    IF (@RoleId IS NULL)
    BEGIN
        SELECT @ErrorCode = 1
        GOTO Cleanup
    END
    IF (@DeleteOnlyIfRoleIsEmpty <> 0)
    BEGIN
        IF (EXISTS (SELECT RoleId FROM dbo.aspnet_UsersInRoles  WHERE @RoleId = RoleId))
        BEGIN
            SELECT @ErrorCode = 2
            GOTO Cleanup
        END
    END


    DELETE FROM dbo.aspnet_UsersInRoles  WHERE @RoleId = RoleId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    DELETE FROM dbo.aspnet_Roles WHERE @RoleId = RoleId  AND ApplicationId = @ApplicationId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        COMMIT TRANSACTION
    END

    RETURN(0)

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_RoleExists'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_RoleExists] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_RoleExists] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Roles_RoleExists]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_RoleExists]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_RoleExists]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(0)
    IF (EXISTS (SELECT RoleName FROM dbo.aspnet_Roles WHERE LOWER(@RoleName) = LoweredRoleName AND ApplicationId = @ApplicationId ))
        RETURN(1)
    ELSE
        RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_AddUsersToRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_AddUsersToRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_AddUsersToRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_AddUsersToRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_AddUsersToRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_AddUsersToRoles]
	@ApplicationName  nvarchar(256),
	@UserNames		  nvarchar(4000),
	@RoleNames		  nvarchar(4000),
	@CurrentTimeUtc   datetime
AS
BEGIN
	DECLARE @AppId uniqueidentifier
	SELECT  @AppId = NULL
	SELECT  @AppId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName collate database_default
	IF (@AppId IS NULL)
		RETURN(2)
	DECLARE @TranStarted   int
	SET @TranStarted = 0

	IF( @@TRANCOUNT = 0 )
	BEGIN
		BEGIN TRANSACTION
		SET @TranStarted = 1
	END

	DECLARE @tbNames	table(Name nvarchar(256) NOT NULL PRIMARY KEY)
	DECLARE @tbRoles	table(RoleId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @tbUsers	table(UserId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @Num		int
	DECLARE @Pos		int
	DECLARE @NextPos	int
	DECLARE @Name		nvarchar(256)

	SET @Num = 0
	SET @Pos = 1
	WHILE(@Pos <= LEN(@RoleNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @RoleNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@RoleNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@RoleNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbRoles
	  SELECT RoleId
	  FROM   dbo.aspnet_Roles ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredRoleName AND ar.ApplicationId = @AppId

	IF (@@ROWCOUNT <> @Num)
	BEGIN
		SELECT TOP 1 Name
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT ar.LoweredRoleName FROM dbo.aspnet_Roles ar,  @tbRoles r WHERE r.RoleId = ar.RoleId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(2)
	END

	DELETE FROM @tbNames WHERE 1=1
	SET @Num = 0
	SET @Pos = 1

	WHILE(@Pos <= LEN(@UserNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @UserNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@UserNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@UserNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbUsers
	  SELECT UserId
	  FROM   dbo.aspnet_Users ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredUserName AND ar.ApplicationId = @AppId

	IF (@@ROWCOUNT <> @Num)
	BEGIN
		DELETE FROM @tbNames
		WHERE LOWER(Name)  collate database_default IN (SELECT LoweredUserName FROM dbo.aspnet_Users au,  @tbUsers u WHERE au.UserId = u.UserId)

		INSERT dbo.aspnet_Users (ApplicationId, UserId, UserName, LoweredUserName, IsAnonymous, LastActivityDate)
		  SELECT @AppId, NEWID(), Name, LOWER(Name) collate database_default, 0, @CurrentTimeUtc
		  FROM   @tbNames

		INSERT INTO @tbUsers
		  SELECT  UserId
		  FROM	dbo.aspnet_Users au, @tbNames t
		  WHERE   LOWER(t.Name) collate database_default = au.LoweredUserName AND au.ApplicationId = @AppId
	END

	IF (EXISTS (SELECT * FROM dbo.aspnet_UsersInRoles ur, @tbUsers tu, @tbRoles tr WHERE tu.UserId = ur.UserId AND tr.RoleId = ur.RoleId))
	BEGIN
		SELECT TOP 1 UserName, RoleName
		FROM		 dbo.aspnet_UsersInRoles ur, @tbUsers tu, @tbRoles tr, aspnet_Users u, aspnet_Roles r
		WHERE		u.UserId = tu.UserId AND r.RoleId = tr.RoleId AND tu.UserId = ur.UserId AND tr.RoleId = ur.RoleId

		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(3)
	END

	INSERT INTO dbo.aspnet_UsersInRoles (UserId, RoleId)
	SELECT UserId, RoleId
	FROM @tbUsers, @tbRoles

	IF( @TranStarted = 1 )
		COMMIT TRANSACTION
	RETURN(0)
END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_RemoveUsersFromRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_RemoveUsersFromRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_RemoveUsersFromRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]
	@ApplicationName  nvarchar(256),
	@UserNames		  nvarchar(4000),
	@RoleNames		  nvarchar(4000)
AS
BEGIN
	DECLARE @AppId uniqueidentifier
	SELECT  @AppId = NULL
	SELECT  @AppId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	IF (@AppId IS NULL)
		RETURN(2)


	DECLARE @TranStarted   bit
	SET @TranStarted = 0

	IF( @@TRANCOUNT = 0 )
	BEGIN
		BEGIN TRANSACTION
		SET @TranStarted = 1
	END

	DECLARE @tbNames  table(Name nvarchar(256) NOT NULL PRIMARY KEY)
	DECLARE @tbRoles  table(RoleId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @tbUsers  table(UserId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @Num	  int
	DECLARE @Pos	  int
	DECLARE @NextPos  int
	DECLARE @Name	  nvarchar(256)
	DECLARE @CountAll int
	DECLARE @CountU	  int
	DECLARE @CountR	  int


	SET @Num = 0
	SET @Pos = 1
	WHILE(@Pos <= LEN(@RoleNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @RoleNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@RoleNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@RoleNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbRoles
	  SELECT RoleId
	  FROM   dbo.aspnet_Roles ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredRoleName AND ar.ApplicationId = @AppId
	SELECT @CountR = @@ROWCOUNT

	IF (@CountR <> @Num)
	BEGIN
		SELECT TOP 1 N'', Name
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT ar.LoweredRoleName FROM dbo.aspnet_Roles ar,  @tbRoles r WHERE r.RoleId = ar.RoleId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(2)
	END


	DELETE FROM @tbNames WHERE 1=1
	SET @Num = 0
	SET @Pos = 1


	WHILE(@Pos <= LEN(@UserNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @UserNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@UserNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@UserNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbUsers
	  SELECT UserId
	  FROM   dbo.aspnet_Users ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredUserName AND ar.ApplicationId = @AppId

	SELECT @CountU = @@ROWCOUNT
	IF (@CountU <> @Num)
	BEGIN
		SELECT TOP 1 Name, N''
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT au.LoweredUserName FROM dbo.aspnet_Users au,  @tbUsers u WHERE u.UserId = au.UserId)

		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(1)
	END

	SELECT  @CountAll = COUNT(*)
	FROM	dbo.aspnet_UsersInRoles ur, @tbUsers u, @tbRoles r
	WHERE   ur.UserId = u.UserId AND ur.RoleId = r.RoleId

	IF (@CountAll <> @CountU * @CountR)
	BEGIN
		SELECT TOP 1 UserName, RoleName
		FROM		 @tbUsers tu, @tbRoles tr, dbo.aspnet_Users u, dbo.aspnet_Roles r
		WHERE		 u.UserId = tu.UserId AND r.RoleId = tr.RoleId AND
					 tu.UserId NOT IN (SELECT ur.UserId FROM dbo.aspnet_UsersInRoles ur WHERE ur.RoleId = tr.RoleId) AND
					 tr.RoleId NOT IN (SELECT ur.RoleId FROM dbo.aspnet_UsersInRoles ur WHERE ur.UserId = tu.UserId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(3)
	END

	DELETE FROM dbo.aspnet_UsersInRoles
	WHERE UserId IN (SELECT UserId FROM @tbUsers)
	  AND RoleId IN (SELECT RoleId FROM @tbRoles)
	IF( @TranStarted = 1 )
		COMMIT TRANSACTION
	RETURN(0)
END
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_GetUsersInRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_GetUsersInRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_GetUsersInRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UsersInRoles_GetUsersInRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_GetUsersInRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_GetUsersInRoles]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
     DECLARE @RoleId uniqueidentifier
     SELECT  @RoleId = NULL

     SELECT  @RoleId = RoleId
     FROM    dbo.aspnet_Roles
     WHERE   LOWER(@RoleName) collate database_default = LoweredRoleName AND ApplicationId = @ApplicationId

     IF (@RoleId IS NULL)
         RETURN(1)

    SELECT u.UserName
    FROM   dbo.aspnet_Users u, dbo.aspnet_UsersInRoles ur
    WHERE  u.UserId = ur.UserId AND @RoleId = ur.RoleId AND u.ApplicationId = @ApplicationId
    ORDER BY u.UserName
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_FindUsersInRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_FindUsersInRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_FindUsersInRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UsersInRoles_FindUsersInRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_FindUsersInRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_FindUsersInRole]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256),
    @UserNameToMatch  nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
     DECLARE @RoleId uniqueidentifier
     SELECT  @RoleId = NULL

     SELECT  @RoleId = RoleId
     FROM    dbo.aspnet_Roles
     WHERE   LOWER(@RoleName) collate database_default = LoweredRoleName AND ApplicationId = @ApplicationId

     IF (@RoleId IS NULL)
         RETURN(1)

    SELECT u.UserName
    FROM   dbo.aspnet_Users u, dbo.aspnet_UsersInRoles ur
    WHERE  u.UserId = ur.UserId AND @RoleId = ur.RoleId AND u.ApplicationId = @ApplicationId AND LoweredUserName LIKE LOWER(@UserNameToMatch) collate database_default
    ORDER BY u.UserName
    RETURN(0)
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_GetAllRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_GetAllRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_GetAllRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_GetAllRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_GetAllRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_GetAllRoles] 
    @ApplicationName nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN
    SELECT RoleName
    FROM   dbo.aspnet_Roles WHERE ApplicationId = @ApplicationId
    ORDER BY RoleName
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Roles'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Roles Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Roles Created'
GO
CREATE VIEW vw_aspnet_Roles
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_Roles]
  AS SELECT [ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]
  FROM [dbo].[aspnet_Roles]
  
  GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_UsersInRoles'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_UsersInRoles Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_UsersInRoles Created'
GO
CREATE VIEW vw_aspnet_UsersInRoles
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_UsersInRoles]
  AS SELECT [UserId], [RoleId]
  FROM [dbo].[aspnet_UsersInRoles]


GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Setup_RemoveAllRoleMembers'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:aspnet_Setup_RemoveAllRoleMembers updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:aspnet_Setup_RemoveAllRoleMembers create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Setup_RemoveAllRoleMembers]
AS
    SELECT  'created, but not implemented yet.'
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Setup_RemoveAllRoleMembers]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Setup_RemoveAllRoleMembers]
    @name   sysname
AS
BEGIN
    CREATE TABLE #aspnet_RoleMembers
    (
        Group_name      sysname,
        Group_id        smallint,
        Users_in_group  sysname,
        User_id         smallint
    )

    INSERT INTO #aspnet_RoleMembers
    EXEC sp_helpuser @name

    DECLARE @user_id smallint
    DECLARE @cmd nvarchar(500)
    DECLARE c1 cursor FORWARD_ONLY FOR
        SELECT User_id FROM #aspnet_RoleMembers

    OPEN c1

    FETCH c1 INTO @user_id
    WHILE (@@fetch_status = 0)
    BEGIN
        SET @cmd = 'EXEC sp_droprolemember ' + '''' + @name + ''', ''' + USER_NAME(@user_id) + ''''
        EXEC (@cmd)
        FETCH c1 INTO @user_id
    END

    CLOSE c1
    DEALLOCATE c1
END
GO
PRINT N'Adding foreign keys to [dbo].[aspnet_Membership]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Me__Appli__276EDEB3')
BEGIN
PRINT N'foreign key [FK__aspnet_Me__Appli__276EDEB3] for [dbo].[aspnet_Membership] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key [FK__aspnet_Me__Appli__276EDEB3] to [dbo].[aspnet_Membership]'
ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [FK__aspnet_Me__Appli__276EDEB3] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

SET NOEXEC OFF

IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Me__UserI__286302EC')
BEGIN
PRINT N'foreign key FK__aspnet_Me__UserI__286302EC for [dbo].[aspnet_Membership] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Me__UserI__286302EC to [dbo].[aspnet_Membership]'
ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [FK__aspnet_Me__UserI__286302EC] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

SET NOEXEC OFF
PRINT N'Adding foreign keys to [dbo].[aspnet_Roles]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Ro__Appli__3C69FB99')
BEGIN
PRINT N'foreign key FK__aspnet_Ro__Appli__3C69FB99 for [dbo].[aspnet_Roles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Ro__Appli__3C69FB99 to [dbo].[aspnet_Roles]'
ALTER TABLE [dbo].[aspnet_Roles] ADD CONSTRAINT [FK__aspnet_Ro__Appli__3C69FB99] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

SET NOEXEC OFF
PRINT N'Adding foreign keys to [dbo].[aspnet_Users]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__Appli__173876EA')
BEGIN
PRINT N'foreign key FK__aspnet_Us__Appli__173876EA for [dbo].[aspnet_Roles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Us__Appli__173876EA to [dbo].[aspnet_Roles]'

ALTER TABLE [dbo].[aspnet_Users] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__Appli__173876EA] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO


SET NOEXEC OFF

PRINT N'Adding foreign keys to [dbo].[aspnet_UsersInRoles]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__UserI__403A8C7D')
BEGIN
PRINT N'foreign key FK__aspnet_Ro__Appli__403A8C7D for [dbo].[aspnet_UsersInRoles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Ro__Appli__403A8C7D to [dbo].[aspnet_UsersInRoles]'
ALTER TABLE [dbo].[aspnet_UsersInRoles] ADD CONSTRAINT [FK__aspnet_Us__UserI__403A8C7D] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])

END
GO

SET NOEXEC OFF
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__RoleI__412EB0B6')
BEGIN
PRINT N'foreign key FK__aspnet_Us__RoleI__412EB0B6 for [dbo].[aspnet_UsersInRoles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Us__RoleI__412EB0B6 to [dbo].[aspnet_UsersInRoles]'
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])

END
GO

SET NOEXEC OFF



PRINT N'Altering permissions on  [dbo].[aspnet_CheckSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer] TO [aspnet_Membership_FullAccess]
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_CreateUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_CreateUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_FindUsersByEmail]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_FindUsersByEmail] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_FindUsersByName]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_FindUsersByName] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetAllUsers]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetAllUsers] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetNumberOfUsersOnline]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetNumberOfUsersOnline] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetNumberOfUsersOnline] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetPasswordWithFormat]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetPasswordWithFormat] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetPassword] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByEmail]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByEmail] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByEmail] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByName]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByName] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByName] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByUserId]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByUserId] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByUserId] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_ResetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_ResetPassword] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_SetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_SetPassword] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UnlockUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UnlockUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UpdateUserInfo]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UpdateUserInfo] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UpdateUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UpdateUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_RegisterSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_CreateRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_CreateRole] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_DeleteRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_DeleteRole] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_GetAllRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_GetAllRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_RoleExists]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_RoleExists] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UnRegisterSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_AddUsersToRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_AddUsersToRoles] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_FindUsersInRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_FindUsersInRole] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_GetRolesForUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetRolesForUser] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetRolesForUser] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_GetUsersInRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetUsersInRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_IsUserInRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_IsUserInRole] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_IsUserInRole] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Users_DeleteUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Users_DeleteUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Applications]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Applications] TO [aspnet_Membership_ReportingAccess]
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Applications] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_MembershipUsers]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_MembershipUsers] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Roles]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Roles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_UsersInRoles]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_UsersInRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Users]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Users] TO [aspnet_Membership_ReportingAccess]
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Users] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
COMMIT TRANSACTION
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
DECLARE @Success AS BIT
SET @Success = 1
SET NOEXEC OFF
IF (@Success = 1) PRINT 'The ASPNET installation succeeded'
ELSE BEGIN
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	PRINT 'The ASPNET installation update failed'
END
GO
/*
Run this script on:

        The a NEW MFSQL Manager Database to install ASP Security Provider


*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO

PRINT SPACE(5) + 'ASPNET SECURITY RPOVIDER FOR MFSQL MANAGER ' + QUOTENAME(DB_NAME()) + ' - '
    + QUOTENAME(@@SERVERNAME);

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


if not exists (select 1 from sys.database_principals where name like'aspnet%' and Type = 'R')
Begin
IF @@ERROR <> 0 SET NOEXEC ON

PRINT N'Creating role aspnet_Membership_FullAccess'


CREATE ROLE [aspnet_Membership_FullAccess]
AUTHORIZATION [dbo]

IF @@ERROR <> 0 SET NOEXEC ON

CREATE ROLE [aspnet_Membership_BasicAccess]
AUTHORIZATION [dbo]

PRINT N'Creating role aspnet_Membership_ReportingAccess'

CREATE ROLE [aspnet_Membership_ReportingAccess]
AUTHORIZATION [dbo]

PRINT N'Creating role aspnet_Roles_FullAccess'

CREATE ROLE [aspnet_Roles_FullAccess]
AUTHORIZATION [dbo]


PRINT N'Creating role aspnet_Roles_BasicAccess'

CREATE ROLE [aspnet_Roles_BasicAccess]
AUTHORIZATION [dbo]


PRINT N'Creating role aspnet_Roles_ReportingAccess'

CREATE ROLE [aspnet_Roles_ReportingAccess]
AUTHORIZATION [dbo]



PRINT N'Altering members of role aspnet_Membership_BasicAccess'

EXEC sp_addrolemember N'aspnet_Membership_BasicAccess', N'aspnet_Membership_FullAccess'


PRINT N'Altering members of role aspnet_Membership_ReportingAccess'

EXEC sp_addrolemember N'aspnet_Membership_ReportingAccess', N'aspnet_Membership_FullAccess'


PRINT N'Altering members of role aspnet_Roles_BasicAccess'

EXEC sp_addrolemember N'aspnet_Roles_BasicAccess', N'aspnet_Roles_FullAccess'


PRINT N'Altering members of role aspnet_Roles_ReportingAccess'

EXEC sp_addrolemember N'aspnet_Roles_ReportingAccess', N'aspnet_Roles_FullAccess'


END
ELSE
Begin

PRINT SPACE(10) + N'...ASPNET Roles already exists'

END

IF @@ERROR <> 0 SET NOEXEC ON
GO
BEGIN TRANSACTION
GO



IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_SchemaVersions')
BEGIN

PRINT N'Creating [dbo].[aspnet_SchemaVersions]'

CREATE TABLE [dbo].[aspnet_SchemaVersions]
(
[Feature] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[CompatibleSchemaVersion] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[IsCurrentVersion] [bit] NOT NULL
)

PRINT N'Creating primary key [PK__aspnet_S__5A1E6BC1503E7E3B] on [dbo].[aspnet_SchemaVersions]'

ALTER TABLE [dbo].[aspnet_SchemaVersions] ADD CONSTRAINT [PK__aspnet_S__5A1E6BC1503E7E3B] PRIMARY KEY CLUSTERED  ([Feature], [CompatibleSchemaVersion])

END
ELSE
PRINT SPACE(10) + N'...ASPNET Tables already exists'

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_RegisterSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: aspnet_RegisterSchemaVersion updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:aspnet_RegisterSchemaVersion create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE[dbo].[aspnet_RegisterSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_RegisterSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_RegisterSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128),
    @IsCurrentVersion          bit,
    @RemoveIncompatibleSchema  bit
AS
BEGIN
    IF( @RemoveIncompatibleSchema = 1 )
    BEGIN
        DELETE FROM dbo.aspnet_SchemaVersions WHERE Feature = LOWER( @Feature ) collate database_default
    END
    ELSE
    BEGIN
        IF( @IsCurrentVersion = 1 )
        BEGIN
            UPDATE dbo.aspnet_SchemaVersions
            SET IsCurrentVersion = 0
            WHERE Feature = LOWER( @Feature ) collate database_default
        END
    END

    INSERT  dbo.aspnet_SchemaVersions( Feature, CompatibleSchemaVersion, IsCurrentVersion )
    VALUES( LOWER( @Feature ), @CompatibleSchemaVersion, @IsCurrentVersion )
END
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_CheckSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_CheckSchemaVersion] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_CheckSchemaVersion] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_CheckSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_CheckSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_CheckSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128)
AS
BEGIN
    IF (EXISTS( SELECT  *
                FROM    dbo.aspnet_SchemaVersions
                WHERE   Feature = LOWER( @Feature ) collate database_default AND
                        CompatibleSchemaVersion = @CompatibleSchemaVersion ))
        RETURN 0

    RETURN 1
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_Applications')
BEGIN

PRINT N'Creating [dbo].[aspnet_Applications]'

CREATE TABLE [dbo].[aspnet_Applications]
(
[ApplicationName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredApplicationName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[ApplicationId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Ap__Appli__145C0A3F] DEFAULT (newid()),
[Description] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Applications_Index] on [dbo].[aspnet_Applications]'

CREATE CLUSTERED INDEX [aspnet_Applications_Index] ON [dbo].[aspnet_Applications] ([LoweredApplicationName])


PRINT N'Adding constraints to [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [UQ__aspnet_A__309103317CF8590C] UNIQUE NONCLUSTERED  ([ApplicationName])


PRINT N'Adding constraints to [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [UQ__aspnet_A__17477DE4768CAD81] UNIQUE NONCLUSTERED  ([LoweredApplicationName])

PRINT N'Creating primary key [PK__aspnet_A__C93A4C98519285D6] on [dbo].[aspnet_Applications]'

ALTER TABLE [dbo].[aspnet_Applications] ADD CONSTRAINT [PK__aspnet_A__C93A4C98519285D6] PRIMARY KEY NONCLUSTERED  ([ApplicationId])

PRINT N'Creating [dbo].[aspnet_Applications_CreateApplication]'

END
ELSE
PRINT SPACE(10) + '...ASPNET Table [aspnet_Applications] exsits'
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Applications_CreateApplication'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Applications_CreateApplication] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Applications_CreateApplication] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Applications_CreateApplication]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_Applications_CreateApplication]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Applications_CreateApplication]
    @ApplicationName      nvarchar(256),
    @ApplicationId        uniqueidentifier OUTPUT
AS
BEGIN
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName

    IF(@ApplicationId IS NULL)
    BEGIN
        DECLARE @TranStarted   bit
        SET @TranStarted = 0

        IF( @@TRANCOUNT = 0 )
        BEGIN
	        BEGIN TRANSACTION
	        SET @TranStarted = 1
        END
        ELSE
    	    SET @TranStarted = 0

        SELECT  @ApplicationId = ApplicationId
        FROM dbo.aspnet_Applications WITH (UPDLOCK, HOLDLOCK)
        WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName

        IF(@ApplicationId IS NULL)
        BEGIN
            SELECT  @ApplicationId = NEWID()
            INSERT  dbo.aspnet_Applications (ApplicationId, ApplicationName, LoweredApplicationName)
            VALUES  (@ApplicationId, @ApplicationName, LOWER(@ApplicationName))
        END


        IF( @TranStarted = 1 )
        BEGIN
            IF(@@ERROR = 0)
            BEGIN
	        SET @TranStarted = 0
	        COMMIT TRANSACTION
            END
            ELSE
            BEGIN
                SET @TranStarted = 0
                ROLLBACK TRANSACTION
            END
        END
    END
END
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'aspnet_UnRegisterSchemaVersion'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_UnRegisterSchemaVersion] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UnRegisterSchemaVersion] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UnRegisterSchemaVersion]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[aspnet_UnRegisterSchemaVersion]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

Alter PROCEDURE [dbo].[aspnet_UnRegisterSchemaVersion]
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128)
AS
BEGIN
    DELETE FROM dbo.aspnet_SchemaVersions
        WHERE   Feature = LOWER(@Feature) collate database_default AND @CompatibleSchemaVersion = CompatibleSchemaVersion
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] = 'aspnet_Users')
BEGIN

PRINT N'Creating [dbo].[aspnet_Users]'

CREATE TABLE [dbo].[aspnet_Users]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Us__UserI__182C9B23] DEFAULT (newid()),
[UserName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredUserName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[MobileAlias] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__aspnet_Us__Mobil__1920BF5C] DEFAULT (NULL),
[IsAnonymous] [bit] NOT NULL CONSTRAINT [DF__aspnet_Us__IsAno__1A14E395] DEFAULT ((0)),
[LastActivityDate] [datetime] NOT NULL
)

PRINT N'Creating index [aspnet_Users_Index] on [dbo].[aspnet_Users]'

CREATE UNIQUE CLUSTERED INDEX [aspnet_Users_Index] ON [dbo].[aspnet_Users] ([ApplicationId], [LoweredUserName])

PRINT N'Creating index [aspnet_Users_Index2] on [dbo].[aspnet_Users]'

CREATE NONCLUSTERED INDEX [aspnet_Users_Index2] ON [dbo].[aspnet_Users] ([ApplicationId], [LastActivityDate])

PRINT N'Creating primary key [PK__aspnet_U__1788CC4DF64A6C1A] on [dbo].[aspnet_Users]'

ALTER TABLE [dbo].[aspnet_Users] ADD CONSTRAINT [PK__aspnet_U__1788CC4DF64A6C1A] PRIMARY KEY NONCLUSTERED  ([UserId])

END

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Users_CreateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_Users_CreateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Users_CreateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Users_CreateUser]
AS
    SELECT  'created, but not implemented yet.';
	PRINT N'Creating [dbo].[dbo].[aspnet_Users_CreateUser]'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Users_CreateUser]
    @ApplicationId    uniqueidentifier,
    @UserName         nvarchar(256),
    @IsUserAnonymous  bit,
    @LastActivityDate DATETIME,
    @UserId           uniqueidentifier OUTPUT
AS
BEGIN
    IF( @UserId IS NULL )
        SELECT @UserId = NEWID()
    ELSE
    BEGIN
        IF( EXISTS( SELECT UserId FROM dbo.aspnet_Users
                    WHERE @UserId = UserId ) )
            RETURN -1
    END

    INSERT dbo.aspnet_Users (ApplicationId, UserId, UserName, LoweredUserName, IsAnonymous, LastActivityDate)
    VALUES (@ApplicationId, @UserId, @UserName, LOWER(@UserName), @IsUserAnonymous, @LastActivityDate)

    RETURN 0
END
GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] LIKE 'aspnet_UsersInRoles')
BEGIN

PRINT N'Creating [dbo].[aspnet_UsersInRoles]'

CREATE TABLE [dbo].[aspnet_UsersInRoles]
(
[UserId] [uniqueidentifier] NOT NULL,
[RoleId] [uniqueidentifier] NOT NULL
)

PRINT N'Creating primary key [PK__aspnet_U__AF2760AD06FC699F] on [dbo].[aspnet_UsersInRoles]'

ALTER TABLE [dbo].[aspnet_UsersInRoles] ADD CONSTRAINT [PK__aspnet_U__AF2760AD06FC699F] PRIMARY KEY CLUSTERED  ([UserId], [RoleId])


PRINT N'Creating index [aspnet_UsersInRoles_index] on [dbo].[aspnet_UsersInRoles]'

CREATE NONCLUSTERED INDEX [aspnet_UsersInRoles_index] ON [dbo].[aspnet_UsersInRoles] ([RoleId])

PRINT N'Creating [dbo].[aspnet_Membership]'

CREATE TABLE [dbo].[aspnet_Membership]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[Password] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[PasswordFormat] [int] NOT NULL CONSTRAINT [DF__aspnet_Me__Passw__29572725] DEFAULT ((0)),
[PasswordSalt] [nvarchar] (128) COLLATE Latin1_General_CI_AS NOT NULL,
[MobilePIN] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[Email] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[LoweredEmail] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[PasswordQuestion] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[PasswordAnswer] [nvarchar] (128) COLLATE Latin1_General_CI_AS NULL,
[IsApproved] [bit] NOT NULL,
[IsLockedOut] [bit] NOT NULL,
[CreateDate] [datetime] NOT NULL,
[LastLoginDate] [datetime] NOT NULL,
[LastPasswordChangedDate] [datetime] NOT NULL,
[LastLockoutDate] [datetime] NOT NULL,
[FailedPasswordAttemptCount] [int] NOT NULL,
[FailedPasswordAttemptWindowStart] [datetime] NOT NULL,
[FailedPasswordAnswerAttemptCount] [int] NOT NULL,
[FailedPasswordAnswerAttemptWindowStart] [datetime] NOT NULL,
[Comment] [ntext] COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Membership_index] on [dbo].[aspnet_Membership]'

CREATE CLUSTERED INDEX [aspnet_Membership_index] ON [dbo].[aspnet_Membership] ([ApplicationId], [LoweredEmail])

PRINT N'Creating primary key [PK__aspnet_M__1788CC4D988350DB] on [dbo].[aspnet_Membership]'

ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [PK__aspnet_M__1788CC4D988350DB] PRIMARY KEY NONCLUSTERED  ([UserId])

END

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Users_DeleteUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures: [aspnet_Users_DeleteUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure: [aspnet_Users_DeleteUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Users_DeleteUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Users_DeleteUser]'

-- the following section will be always executed
SET NOEXEC OFF;
GO

Alter PROCEDURE [dbo].[aspnet_Users_DeleteUser]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @TablesToDeleteFrom int,
    @NumTablesDeletedFrom int OUTPUT
AS
BEGIN
    DECLARE @UserId               uniqueidentifier
    SELECT  @UserId               = NULL
    SELECT  @NumTablesDeletedFrom = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
	SET @TranStarted = 0

    DECLARE @ErrorCode   int
    DECLARE @RowCount    int

    SET @ErrorCode = 0
    SET @RowCount  = 0

    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a
    WHERE   u.LoweredUserName       = LOWER(@UserName)
        AND u.ApplicationId         = a.ApplicationId
        AND LOWER(@ApplicationName) = a.LoweredApplicationName

    IF (@UserId IS NULL)
    BEGIN
        GOTO Cleanup
    END

    -- Delete from Membership table if (@TablesToDeleteFrom & 1) is set
    IF ((@TablesToDeleteFrom & 1) <> 0 AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_MembershipUsers') AND (type = 'V'))))
    BEGIN
        DELETE FROM dbo.aspnet_Membership WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
               @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_UsersInRoles table if (@TablesToDeleteFrom & 2) is set
    IF ((@TablesToDeleteFrom & 2) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_UsersInRoles') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_UsersInRoles WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_Profile table if (@TablesToDeleteFrom & 4) is set
    IF ((@TablesToDeleteFrom & 4) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Profiles') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_Profile WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_PersonalizationPerUser table if (@TablesToDeleteFrom & 8) is set
    IF ((@TablesToDeleteFrom & 8) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_WebPartState_User') AND (type = 'V'))) )
    BEGIN
        DELETE FROM dbo.aspnet_PersonalizationPerUser WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    -- Delete from aspnet_Users table if (@TablesToDeleteFrom & 1,2,4 & 8) are all set
    IF ((@TablesToDeleteFrom & 1) <> 0 AND
        (@TablesToDeleteFrom & 2) <> 0 AND
        (@TablesToDeleteFrom & 4) <> 0 AND
        (@TablesToDeleteFrom & 8) <> 0 AND
        (EXISTS (SELECT UserId FROM dbo.aspnet_Users WHERE @UserId = UserId)))
    BEGIN
        DELETE FROM dbo.aspnet_Users WHERE @UserId = UserId

        SELECT @ErrorCode = @@ERROR,
                @RowCount = @@ROWCOUNT

        IF( @ErrorCode <> 0 )
            GOTO Cleanup

        IF (@RowCount <> 0)
            SELECT  @NumTablesDeletedFrom = @NumTablesDeletedFrom + 1
    END

    IF( @TranStarted = 1 )
    BEGIN
	    SET @TranStarted = 0
	    COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:
    SET @NumTablesDeletedFrom = 0

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
	    ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END

GO


IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[TABLES] AS [t] WHERE [t].[TABLE_NAME] LIKE 'aspnet_Roles')
BEGIN

PRINT N'Creating [dbo].[aspnet_Roles]'


CREATE TABLE [dbo].[aspnet_Roles]
(
[ApplicationId] [uniqueidentifier] NOT NULL,
[RoleId] [uniqueidentifier] NOT NULL CONSTRAINT [DF__aspnet_Ro__RoleI__3D5E1FD2] DEFAULT (newid()),
[RoleName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[LoweredRoleName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[Description] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL
)

PRINT N'Creating index [aspnet_Roles_index1] on [dbo].[aspnet_Roles]'

CREATE UNIQUE CLUSTERED INDEX [aspnet_Roles_index1] ON [dbo].[aspnet_Roles] ([ApplicationId], [LoweredRoleName])

PRINT N'Creating primary key [PK__aspnet_R__8AFACE1B36FD1B86] on [dbo].[aspnet_Roles]'

ALTER TABLE [dbo].[aspnet_Roles] ADD CONSTRAINT [PK__aspnet_R__8AFACE1B36FD1B86] PRIMARY KEY NONCLUSTERED  ([RoleId])

PRINT(N'Add constraints to [dbo].[aspnet_UsersInRoles]')
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])


END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_AnyDataInTables'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_AnyDataInTables] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_AnyDataInTables] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_AnyDataInTables]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_AnyDataInTables]'
-- the following section will be always executed
SET NOEXEC OFF;
GO



Alter PROCEDURE [dbo].[aspnet_AnyDataInTables]
    @TablesToCheck int
AS
BEGIN
    -- Check Membership table if (@TablesToCheck & 1) is set
    IF ((@TablesToCheck & 1) <> 0 AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_MembershipUsers') AND (type = 'V'))))
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Membership))
        BEGIN
            SELECT N'aspnet_Membership'
            RETURN
        END
    END

    -- Check aspnet_Roles table if (@TablesToCheck & 2) is set
    IF ((@TablesToCheck & 2) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Roles') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 RoleId FROM dbo.aspnet_Roles))
        BEGIN
            SELECT N'aspnet_Roles'
            RETURN
        END
    END

    -- Check aspnet_Profile table if (@TablesToCheck & 4) is set
    IF ((@TablesToCheck & 4) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_Profiles') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Profile))
        BEGIN
            SELECT N'aspnet_Profile'
            RETURN
        END
    END

    -- Check aspnet_PersonalizationPerUser table if (@TablesToCheck & 8) is set
    IF ((@TablesToCheck & 8) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'vw_aspnet_WebPartState_User') AND (type = 'V'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_PersonalizationPerUser))
        BEGIN
            SELECT N'aspnet_PersonalizationPerUser'
            RETURN
        END
    END

    -- Check aspnet_PersonalizationPerUser table if (@TablesToCheck & 16) is set
    IF ((@TablesToCheck & 16) <> 0  AND
        (EXISTS (SELECT name FROM sys.objects WHERE (name = N'aspnet_WebEvent_LogEvent') AND (type = 'P'))) )
    BEGIN
        IF (EXISTS(SELECT TOP 1 * FROM dbo.aspnet_WebEvent_Events))
        BEGIN
            SELECT N'aspnet_WebEvent_Events'
            RETURN
        END
    END

    -- Check aspnet_Users table if (@TablesToCheck & 1,2,4 & 8) are all set
    IF ((@TablesToCheck & 1) <> 0 AND
        (@TablesToCheck & 2) <> 0 AND
        (@TablesToCheck & 4) <> 0 AND
        (@TablesToCheck & 8) <> 0 AND
        (@TablesToCheck & 32) <> 0 AND
        (@TablesToCheck & 128) <> 0 AND
        (@TablesToCheck & 256) <> 0 AND
        (@TablesToCheck & 512) <> 0 AND
        (@TablesToCheck & 1024) <> 0)
    BEGIN
        IF (EXISTS(SELECT TOP 1 UserId FROM dbo.aspnet_Users))
        BEGIN
            SELECT N'aspnet_Users'
            RETURN
        END
        IF (EXISTS(SELECT TOP 1 ApplicationId FROM dbo.aspnet_Applications))
        BEGIN
            SELECT N'aspnet_Applications'
            RETURN
        END
    END
END
GO



IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Applications'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Applications Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Applications Created'
GO
CREATE VIEW vw_aspnet_Applications
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_Applications]
  AS 
  SELECT [ApplicationName], [LoweredApplicationName], [ApplicationId], [Description]
  FROM [dbo].[aspnet_Applications]

  GO
  IF EXISTS ( SELECT  1
              FROM    INFORMATION_SCHEMA.[VIEWS]
              WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Users'
                      AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Users Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Users Created'
GO
  CREATE VIEW vw_aspnet_Users
  AS
  
  
         SELECT   [Column1] = 'UNDER CONSTRUCTION';
  	GO
  SET NOEXEC OFF;
  	GO	
  
  ALTER VIEW [dbo].[vw_aspnet_Users]
  AS SELECT [ApplicationId], [UserId], [UserName], [LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]
  FROM [dbo].[aspnet_Users]

GO
  



IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_CreateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_CreateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_CreateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Membership_CreateUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_CreateUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Membership_CreateUser]
    @ApplicationName                        nvarchar(256),
    @UserName                               nvarchar(256),
    @Password                               nvarchar(128),
    @PasswordSalt                           nvarchar(128),
    @Email                                  nvarchar(256),
    @PasswordQuestion                       nvarchar(256),
    @PasswordAnswer                         nvarchar(128),
    @IsApproved                             bit,
    @CurrentTimeUtc                         datetime,
    @CreateDate                             datetime = NULL,
    @UniqueEmail                            int      = 0,
    @PasswordFormat                         int      = 0,
    @UserId                                 uniqueidentifier OUTPUT
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL

    DECLARE @NewUserId uniqueidentifier
    SELECT @NewUserId = NULL

    DECLARE @IsLockedOut bit
    SET @IsLockedOut = 0

    DECLARE @LastLockoutDate  datetime
    SET @LastLockoutDate = CONVERT( datetime, '17540101', 112 )

    DECLARE @FailedPasswordAttemptCount int
    SET @FailedPasswordAttemptCount = 0

    DECLARE @FailedPasswordAttemptWindowStart  datetime
    SET @FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 )

    DECLARE @FailedPasswordAnswerAttemptCount int
    SET @FailedPasswordAnswerAttemptCount = 0

    DECLARE @FailedPasswordAnswerAttemptWindowStart  datetime
    SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )

    DECLARE @NewUserCreated bit
    DECLARE @ReturnValue   int
    SET @ReturnValue = 0

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    EXEC dbo.aspnet_Applications_CreateApplication @ApplicationName, @ApplicationId OUTPUT

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    SET @CreateDate = @CurrentTimeUtc

    SELECT  @NewUserId = UserId FROM dbo.aspnet_Users WHERE LOWER(@UserName) = LoweredUserName AND @ApplicationId = ApplicationId
    IF ( @NewUserId IS NULL )
    BEGIN
        SET @NewUserId = @UserId
        EXEC @ReturnValue = dbo.aspnet_Users_CreateUser @ApplicationId, @UserName, 0, @CreateDate, @NewUserId OUTPUT
        SET @NewUserCreated = 1
    END
    ELSE
    BEGIN
        SET @NewUserCreated = 0
        IF( @NewUserId <> @UserId AND @UserId IS NOT NULL )
        BEGIN
            SET @ErrorCode = 6
            GOTO Cleanup
        END
    END

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @ReturnValue = -1 )
    BEGIN
        SET @ErrorCode = 10
        GOTO Cleanup
    END

    IF ( EXISTS ( SELECT UserId
                  FROM   dbo.aspnet_Membership
                  WHERE  @NewUserId = UserId ) )
    BEGIN
        SET @ErrorCode = 6
        GOTO Cleanup
    END

    SET @UserId = @NewUserId

    IF (@UniqueEmail = 1)
    BEGIN
        IF (EXISTS (SELECT *
                    FROM  dbo.aspnet_Membership m WITH ( UPDLOCK, HOLDLOCK )
                    WHERE ApplicationId = @ApplicationId AND LoweredEmail = LOWER(@Email)))
        BEGIN
            SET @ErrorCode = 7
            GOTO Cleanup
        END
    END

    IF (@NewUserCreated = 0)
    BEGIN
        UPDATE dbo.aspnet_Users
        SET    LastActivityDate = @CreateDate
        WHERE  @UserId = UserId
        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    INSERT INTO dbo.aspnet_Membership
                ( ApplicationId,
                  UserId,
                  Password,
                  PasswordSalt,
                  Email,
                  LoweredEmail,
                  PasswordQuestion,
                  PasswordAnswer,
                  PasswordFormat,
                  IsApproved,
                  IsLockedOut,
                  CreateDate,
                  LastLoginDate,
                  LastPasswordChangedDate,
                  LastLockoutDate,
                  FailedPasswordAttemptCount,
                  FailedPasswordAttemptWindowStart,
                  FailedPasswordAnswerAttemptCount,
                  FailedPasswordAnswerAttemptWindowStart )
         VALUES ( @ApplicationId,
                  @UserId,
                  @Password,
                  @PasswordSalt,
                  @Email,
                  LOWER(@Email),
                  @PasswordQuestion,
                  @PasswordAnswer,
                  @PasswordFormat,
                  @IsApproved,
                  @IsLockedOut,
                  @CreateDate,
                  @CreateDate,
                  @CreateDate,
                  @LastLockoutDate,
                  @FailedPasswordAttemptCount,
                  @FailedPasswordAttemptWindowStart,
                  @FailedPasswordAnswerAttemptCount,
                  @FailedPasswordAnswerAttemptWindowStart )

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
	    SET @TranStarted = 0
	    COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByName'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByName] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByName] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByName]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByName]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetUserByName]
    @ApplicationName      nvarchar(256),
    @UserName             nvarchar(256),
    @CurrentTimeUtc       datetime,
    @UpdateLastActivity   bit = 0
AS
BEGIN
    DECLARE @UserId uniqueidentifier

    IF (@UpdateLastActivity = 1)
    BEGIN
        -- select user ID from aspnet_users table
        SELECT TOP 1 @UserId = u.UserId
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE    LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                LOWER(@UserName) = u.LoweredUserName AND u.UserId = m.UserId

        IF (@@ROWCOUNT = 0) -- Username not found
            RETURN -1

        UPDATE   dbo.aspnet_Users
        SET      LastActivityDate = @CurrentTimeUtc
        WHERE    @UserId = UserId

        SELECT m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
                m.CreateDate, m.LastLoginDate, u.LastActivityDate, m.LastPasswordChangedDate,
                u.UserId, m.IsLockedOut, m.LastLockoutDate
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE  @UserId = u.UserId AND u.UserId = m.UserId 
    END
    ELSE
    BEGIN
        SELECT TOP 1 m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
                m.CreateDate, m.LastLoginDate, u.LastActivityDate, m.LastPasswordChangedDate,
                u.UserId, m.IsLockedOut,m.LastLockoutDate
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE    LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                LOWER(@UserName) = u.LoweredUserName AND u.UserId = m.UserId

        IF (@@ROWCOUNT = 0) -- Username not found
            RETURN -1
    END

    RETURN 0
END
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByUserId'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByUserId] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByUserId] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByUserId]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByUserId]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_GetUserByUserId]
    @UserId               uniqueidentifier,
    @CurrentTimeUtc       datetime,
    @UpdateLastActivity   bit = 0
AS
BEGIN
    IF ( @UpdateLastActivity = 1 )
    BEGIN
        UPDATE   dbo.aspnet_Users
        SET      LastActivityDate = @CurrentTimeUtc
        FROM     dbo.aspnet_Users
        WHERE    @UserId = UserId

        IF ( @@ROWCOUNT = 0 ) -- User ID not found
            RETURN -1
    END

    SELECT  m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate, m.LastLoginDate, u.LastActivityDate,
            m.LastPasswordChangedDate, u.UserName, m.IsLockedOut,
            m.LastLockoutDate
    FROM    dbo.aspnet_Users u, dbo.aspnet_Membership m
    WHERE   @UserId = u.UserId AND u.UserId = m.UserId

    IF ( @@ROWCOUNT = 0 ) -- User ID not found
       RETURN -1

    RETURN 0
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetUserByEmail'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetUserByEmail] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetUserByEmail] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetUserByEmail]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetUserByEmail]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [dbo].[aspnet_Membership_GetUserByEmail]
    @ApplicationName  nvarchar(256),
    @Email            nvarchar(256)
AS
BEGIN
    IF( @Email IS NULL )
        SELECT  u.UserName
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                u.UserId = m.UserId AND
                m.LoweredEmail IS NULL
    ELSE
        SELECT  u.UserName
        FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
                u.ApplicationId = a.ApplicationId    AND
                u.UserId = m.UserId AND
                LOWER(@Email) = m.LoweredEmail

    IF (@@rowcount = 0)
        RETURN(1)
    RETURN(0)
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetPasswordWithFormat'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetPasswordWithFormat] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetPasswordWithFormat] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetPasswordWithFormat]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetPasswordWithFormat]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_GetPasswordWithFormat]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @UpdateLastLoginActivityDate    bit,
    @CurrentTimeUtc                 datetime
AS
BEGIN
    DECLARE @IsLockedOut                        bit
    DECLARE @UserId                             uniqueidentifier
    DECLARE @Password                           nvarchar(128)
    DECLARE @PasswordSalt                       nvarchar(128)
    DECLARE @PasswordFormat                     int
    DECLARE @FailedPasswordAttemptCount         int
    DECLARE @FailedPasswordAnswerAttemptCount   int
    DECLARE @IsApproved                         bit
    DECLARE @LastActivityDate                   datetime
    DECLARE @LastLoginDate                      datetime

    SELECT  @UserId          = NULL

    SELECT  @UserId = u.UserId, @IsLockedOut = m.IsLockedOut, @Password=Password, @PasswordFormat=PasswordFormat,
            @PasswordSalt=PasswordSalt, @FailedPasswordAttemptCount=FailedPasswordAttemptCount,
		    @FailedPasswordAnswerAttemptCount=FailedPasswordAnswerAttemptCount, @IsApproved=IsApproved,
            @LastActivityDate = LastActivityDate, @LastLoginDate = LastLoginDate
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF (@UserId IS NULL)
        RETURN 1

    IF (@IsLockedOut = 1)
        RETURN 99

    SELECT   @Password, @PasswordFormat, @PasswordSalt, @FailedPasswordAttemptCount,
             @FailedPasswordAnswerAttemptCount, @IsApproved, @LastLoginDate, @LastActivityDate

    IF (@UpdateLastLoginActivityDate = 1 AND @IsApproved = 1)
    BEGIN
        UPDATE  dbo.aspnet_Membership
        SET     LastLoginDate = @CurrentTimeUtc
        WHERE   UserId = @UserId

        UPDATE  dbo.aspnet_Users
        SET     LastActivityDate = @CurrentTimeUtc
        WHERE   @UserId = UserId
    END


    RETURN 0
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UpdateUserInfo'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UpdateUserInfo] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UpdateUserInfo] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_UpdateUserInfo]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UpdateUserInfo]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_UpdateUserInfo]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @IsPasswordCorrect              bit,
    @UpdateLastLoginActivityDate    bit,
    @MaxInvalidPasswordAttempts     int,
    @PasswordAttemptWindow          int,
    @CurrentTimeUtc                 datetime,
    @LastLoginDate                  datetime,
    @LastActivityDate               datetime
AS
BEGIN
    DECLARE @UserId                                 uniqueidentifier
    DECLARE @IsApproved                             bit
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId,
            @IsApproved = m.IsApproved,
            @IsLockedOut = m.IsLockedOut,
            @LastLockoutDate = m.LastLockoutDate,
            @FailedPasswordAttemptCount = m.FailedPasswordAttemptCount,
            @FailedPasswordAttemptWindowStart = m.FailedPasswordAttemptWindowStart,
            @FailedPasswordAnswerAttemptCount = m.FailedPasswordAnswerAttemptCount,
            @FailedPasswordAnswerAttemptWindowStart = m.FailedPasswordAnswerAttemptWindowStart
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m WITH ( UPDLOCK )
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF ( @@rowcount = 0 )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    IF( @IsLockedOut = 1 )
    BEGIN
        GOTO Cleanup
    END

    IF( @IsPasswordCorrect = 0 )
    BEGIN
        IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAttemptWindowStart ) )
        BEGIN
            SET @FailedPasswordAttemptWindowStart = @CurrentTimeUtc
            SET @FailedPasswordAttemptCount = 1
        END
        ELSE
        BEGIN
            SET @FailedPasswordAttemptWindowStart = @CurrentTimeUtc
            SET @FailedPasswordAttemptCount = @FailedPasswordAttemptCount + 1
        END

        BEGIN
            IF( @FailedPasswordAttemptCount >= @MaxInvalidPasswordAttempts )
            BEGIN
                SET @IsLockedOut = 1
                SET @LastLockoutDate = @CurrentTimeUtc
            END
        END
    END
    ELSE
    BEGIN
        IF( @FailedPasswordAttemptCount > 0 OR @FailedPasswordAnswerAttemptCount > 0 )
        BEGIN
            SET @FailedPasswordAttemptCount = 0
            SET @FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            SET @FailedPasswordAnswerAttemptCount = 0
            SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            SET @LastLockoutDate = CONVERT( datetime, '17540101', 112 )
        END
    END

    IF( @UpdateLastLoginActivityDate = 1 )
    BEGIN
        UPDATE  dbo.aspnet_Users
        SET     LastActivityDate = @LastActivityDate
        WHERE   @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END

        UPDATE  dbo.aspnet_Membership
        SET     LastLoginDate = @LastLoginDate
        WHERE   UserId = @UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END


    UPDATE dbo.aspnet_Membership
    SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
        FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
        FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
        FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
        FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
    WHERE @UserId = UserId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetPassword]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


GO
ALTER PROCEDURE [dbo].[aspnet_Membership_GetPassword]
    @ApplicationName                nvarchar(256),
    @UserName                       nvarchar(256),
    @MaxInvalidPasswordAttempts     int,
    @PasswordAttemptWindow          int,
    @CurrentTimeUtc                 datetime,
    @PasswordAnswer                 nvarchar(128) = NULL
AS
BEGIN
    DECLARE @UserId                                 uniqueidentifier
    DECLARE @PasswordFormat                         int
    DECLARE @Password                               nvarchar(128)
    DECLARE @passAns                                nvarchar(128)
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId,
            @Password = m.Password,
            @passAns = m.PasswordAnswer,
            @PasswordFormat = m.PasswordFormat,
            @IsLockedOut = m.IsLockedOut,
            @LastLockoutDate = m.LastLockoutDate,
            @FailedPasswordAttemptCount = m.FailedPasswordAttemptCount,
            @FailedPasswordAttemptWindowStart = m.FailedPasswordAttemptWindowStart,
            @FailedPasswordAnswerAttemptCount = m.FailedPasswordAnswerAttemptCount,
            @FailedPasswordAnswerAttemptWindowStart = m.FailedPasswordAnswerAttemptWindowStart
    FROM    dbo.aspnet_Applications a, dbo.aspnet_Users u, dbo.aspnet_Membership m WITH ( UPDLOCK )
    WHERE   LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.ApplicationId = a.ApplicationId    AND
            u.UserId = m.UserId AND
            LOWER(@UserName) = u.LoweredUserName

    IF ( @@rowcount = 0 )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    IF( @IsLockedOut = 1 )
    BEGIN
        SET @ErrorCode = 99
        GOTO Cleanup
    END

    IF ( NOT( @PasswordAnswer IS NULL ) )
    BEGIN
        IF( ( @passAns IS NULL ) OR ( LOWER( @passAns ) <> LOWER( @PasswordAnswer ) ) )
        BEGIN
            IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAnswerAttemptWindowStart ) )
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = 1
            END
            ELSE
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount + 1
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
            END

            BEGIN
                IF( @FailedPasswordAnswerAttemptCount >= @MaxInvalidPasswordAttempts )
                BEGIN
                    SET @IsLockedOut = 1
                    SET @LastLockoutDate = @CurrentTimeUtc
                END
            END

            SET @ErrorCode = 3
        END
        ELSE
        BEGIN
            IF( @FailedPasswordAnswerAttemptCount > 0 )
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = 0
                SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            END
        END

        UPDATE dbo.aspnet_Membership
        SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
            FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
            FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
            FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
            FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
        WHERE @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    IF( @ErrorCode = 0 )
        SELECT @Password, @PasswordFormat

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_SetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_SetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_SetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_SetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_SetPassword]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_SetPassword]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @NewPassword      nvarchar(128),
    @PasswordSalt     nvarchar(128),
    @CurrentTimeUtc   datetime,
    @PasswordFormat   int = 0
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF (@UserId IS NULL)
        RETURN(1)

    UPDATE dbo.aspnet_Membership
    SET Password = @NewPassword, PasswordFormat = @PasswordFormat, PasswordSalt = @PasswordSalt,
        LastPasswordChangedDate = @CurrentTimeUtc
    WHERE @UserId = UserId
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_ResetPassword'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_ResetPassword] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_ResetPassword] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_ResetPassword]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_ResetPassword]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_ResetPassword]
    @ApplicationName             nvarchar(256),
    @UserName                    nvarchar(256),
    @NewPassword                 nvarchar(128),
    @MaxInvalidPasswordAttempts  int,
    @PasswordAttemptWindow       int,
    @PasswordSalt                nvarchar(128),
    @CurrentTimeUtc              datetime,
    @PasswordFormat              int = 0,
    @PasswordAnswer              nvarchar(128) = NULL
AS
BEGIN
    DECLARE @IsLockedOut                            bit
    DECLARE @LastLockoutDate                        datetime
    DECLARE @FailedPasswordAttemptCount             int
    DECLARE @FailedPasswordAttemptWindowStart       datetime
    DECLARE @FailedPasswordAnswerAttemptCount       int
    DECLARE @FailedPasswordAnswerAttemptWindowStart datetime

    DECLARE @UserId                                 uniqueidentifier
    SET     @UserId = NULL

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
    	SET @TranStarted = 0

    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF ( @UserId IS NULL )
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    SELECT @IsLockedOut = IsLockedOut,
           @LastLockoutDate = LastLockoutDate,
           @FailedPasswordAttemptCount = FailedPasswordAttemptCount,
           @FailedPasswordAttemptWindowStart = FailedPasswordAttemptWindowStart,
           @FailedPasswordAnswerAttemptCount = FailedPasswordAnswerAttemptCount,
           @FailedPasswordAnswerAttemptWindowStart = FailedPasswordAnswerAttemptWindowStart
    FROM dbo.aspnet_Membership WITH ( UPDLOCK )
    WHERE @UserId = UserId

    IF( @IsLockedOut = 1 )
    BEGIN
        SET @ErrorCode = 99
        GOTO Cleanup
    END

    UPDATE dbo.aspnet_Membership
    SET    Password = @NewPassword,
           LastPasswordChangedDate = @CurrentTimeUtc,
           PasswordFormat = @PasswordFormat,
           PasswordSalt = @PasswordSalt
    WHERE  @UserId = UserId AND
           ( ( @PasswordAnswer IS NULL ) OR ( LOWER( PasswordAnswer ) = LOWER( @PasswordAnswer ) ) )

    IF ( @@ROWCOUNT = 0 )
        BEGIN
            IF( @CurrentTimeUtc > DATEADD( minute, @PasswordAttemptWindow, @FailedPasswordAnswerAttemptWindowStart ) )
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = 1
            END
            ELSE
            BEGIN
                SET @FailedPasswordAnswerAttemptWindowStart = @CurrentTimeUtc
                SET @FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount + 1
            END

            BEGIN
                IF( @FailedPasswordAnswerAttemptCount >= @MaxInvalidPasswordAttempts )
                BEGIN
                    SET @IsLockedOut = 1
                    SET @LastLockoutDate = @CurrentTimeUtc
                END
            END

            SET @ErrorCode = 3
        END
    ELSE
        BEGIN
            IF( @FailedPasswordAnswerAttemptCount > 0 )
            BEGIN
                SET @FailedPasswordAnswerAttemptCount = 0
                SET @FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 )
            END
        END

    IF( NOT ( @PasswordAnswer IS NULL ) )
    BEGIN
        UPDATE dbo.aspnet_Membership
        SET IsLockedOut = @IsLockedOut, LastLockoutDate = @LastLockoutDate,
            FailedPasswordAttemptCount = @FailedPasswordAttemptCount,
            FailedPasswordAttemptWindowStart = @FailedPasswordAttemptWindowStart,
            FailedPasswordAnswerAttemptCount = @FailedPasswordAnswerAttemptCount,
            FailedPasswordAnswerAttemptWindowStart = @FailedPasswordAnswerAttemptWindowStart
        WHERE @UserId = UserId

        IF( @@ERROR <> 0 )
        BEGIN
            SET @ErrorCode = -1
            GOTO Cleanup
        END
    END

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN @ErrorCode

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UnlockUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UnlockUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UnlockUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Membership_UnlockUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UnlockUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_UnlockUser]
    @ApplicationName                         nvarchar(256),
    @UserName                                nvarchar(256)
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF ( @UserId IS NULL )
        RETURN 1

    UPDATE dbo.aspnet_Membership
    SET IsLockedOut = 0,
        FailedPasswordAttemptCount = 0,
        FailedPasswordAttemptWindowStart = CONVERT( datetime, '17540101', 112 ),
        FailedPasswordAnswerAttemptCount = 0,
        FailedPasswordAnswerAttemptWindowStart = CONVERT( datetime, '17540101', 112 ),
        LastLockoutDate = CONVERT( datetime, '17540101', 112 )
    WHERE @UserId = UserId

    RETURN 0
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_UpdateUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_UpdateUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_UpdateUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE   [dbo].[aspnet_Membership_UpdateUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_UpdateUser]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_UpdateUser]
    @ApplicationName      nvarchar(256),
    @UserName             nvarchar(256),
    @Email                nvarchar(256),
    @Comment              ntext,
    @IsApproved           bit,
    @LastLoginDate        datetime,
    @LastActivityDate     datetime,
    @UniqueEmail          int,
    @CurrentTimeUtc       datetime
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId, @ApplicationId = a.ApplicationId
    FROM    dbo.aspnet_Users u, dbo.aspnet_Applications a, dbo.aspnet_Membership m
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId

    IF (@UserId IS NULL)
        RETURN(1)

    IF (@UniqueEmail = 1)
    BEGIN
        IF (EXISTS (SELECT *
                    FROM  dbo.aspnet_Membership WITH (UPDLOCK, HOLDLOCK)
                    WHERE ApplicationId = @ApplicationId  AND @UserId <> UserId AND LoweredEmail = LOWER(@Email)))
        BEGIN
            RETURN(7)
        END
    END

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
	    BEGIN TRANSACTION
	    SET @TranStarted = 1
    END
    ELSE
	SET @TranStarted = 0

    UPDATE dbo.aspnet_Users WITH (ROWLOCK)
    SET
         LastActivityDate = @LastActivityDate
    WHERE
       @UserId = UserId

    IF( @@ERROR <> 0 )
        GOTO Cleanup

    UPDATE dbo.aspnet_Membership WITH (ROWLOCK)
    SET
         Email            = @Email,
         LoweredEmail     = LOWER(@Email),
         Comment          = @Comment,
         IsApproved       = @IsApproved,
         LastLoginDate    = @LastLoginDate
    WHERE
       @UserId = UserId

    IF( @@ERROR <> 0 )
        GOTO Cleanup

    IF( @TranStarted = 1 )
    BEGIN
	SET @TranStarted = 0
	COMMIT TRANSACTION
    END

    RETURN 0

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
    	ROLLBACK TRANSACTION
    END

    RETURN -1
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_ChangePasswordQuestionAndAnswer'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_ChangePasswordQuestionAndAnswer] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_ChangePasswordQuestionAndAnswer] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]
    @ApplicationName       nvarchar(256),
    @UserName              nvarchar(256),
    @NewPasswordQuestion   nvarchar(256),
    @NewPasswordAnswer     nvarchar(128)
AS
BEGIN
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    SELECT  @UserId = u.UserId
    FROM    dbo.aspnet_Membership m, dbo.aspnet_Users u, dbo.aspnet_Applications a
    WHERE   LoweredUserName = LOWER(@UserName) AND
            u.ApplicationId = a.ApplicationId  AND
            LOWER(@ApplicationName) = a.LoweredApplicationName AND
            u.UserId = m.UserId
    IF (@UserId IS NULL)
    BEGIN
        RETURN(1)
    END

    UPDATE dbo.aspnet_Membership
    SET    PasswordQuestion = @NewPasswordQuestion, PasswordAnswer = @NewPasswordAnswer
    WHERE  UserId=@UserId
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetAllUsers'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetAllUsers] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetAllUsers] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetAllUsers]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetAllUsers]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetAllUsers]
    @ApplicationName       nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0


    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    INSERT INTO #PageIndexForUsers (UserId)
    SELECT u.UserId
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u
    WHERE  u.ApplicationId = @ApplicationId AND u.UserId = m.UserId
    ORDER BY u.UserName

    SELECT @TotalRecords = @@ROWCOUNT

    SELECT u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY u.UserName
    RETURN @TotalRecords
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_GetNumberOfUsersOnline'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_GetNumberOfUsersOnline] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_GetNumberOfUsersOnline] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_GetNumberOfUsersOnline]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_GetNumberOfUsersOnline]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_GetNumberOfUsersOnline]
    @ApplicationName            nvarchar(256),
    @MinutesSinceLastInActive   int,
    @CurrentTimeUtc             datetime
AS
BEGIN
    DECLARE @DateActive datetime
    SELECT  @DateActive = DATEADD(minute,  -(@MinutesSinceLastInActive), @CurrentTimeUtc)

    DECLARE @NumOnline int
    SELECT  @NumOnline = COUNT(*)
    FROM    dbo.aspnet_Users u WITH(NOLOCK),
            dbo.aspnet_Applications a WITH(NOLOCK),
            dbo.aspnet_Membership m WITH(NOLOCK)
    WHERE   u.ApplicationId = a.ApplicationId                  AND
            LastActivityDate > @DateActive                     AND
            a.LoweredApplicationName = LOWER(@ApplicationName) AND
            u.UserId = m.UserId
    RETURN(@NumOnline)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_FindUsersByName'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_FindUsersByName] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_FindUsersByName] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Membership_FindUsersByName]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Membership_FindUsersByName]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_Membership_FindUsersByName]
    @ApplicationName       nvarchar(256),
    @UserNameToMatch       nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0

    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    INSERT INTO #PageIndexForUsers (UserId)
        SELECT u.UserId
        FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
        WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND u.LoweredUserName LIKE LOWER(@UserNameToMatch)
        ORDER BY u.UserName


    SELECT  u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY u.UserName

    SELECT  @TotalRecords = COUNT(*)
    FROM    #PageIndexForUsers
    RETURN @TotalRecords
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Membership_FindUsersByEmail'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Membership_FindUsersByEmail] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Membership_FindUsersByEmail] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE   [dbo].[aspnet_Membership_FindUsersByEmail]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO
PRINT N'Creating [dbo].[aspnet_Membership_FindUsersByEmail]'

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Membership_FindUsersByEmail]
    @ApplicationName       nvarchar(256),
    @EmailToMatch          nvarchar(256),
    @PageIndex             int,
    @PageSize              int
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN 0

    -- Set the page bounds
    DECLARE @PageLowerBound int
    DECLARE @PageUpperBound int
    DECLARE @TotalRecords   int
    SET @PageLowerBound = @PageSize * @PageIndex
    SET @PageUpperBound = @PageSize - 1 + @PageLowerBound

    -- Create a temp table TO store the select results
    CREATE TABLE #PageIndexForUsers
    (
        IndexId int IDENTITY (0, 1) NOT NULL,
        UserId uniqueidentifier
    )

    -- Insert into our temp table
    IF( @EmailToMatch IS NULL )
        INSERT INTO #PageIndexForUsers (UserId)
            SELECT u.UserId
            FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
            WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND m.Email IS NULL
            ORDER BY m.LoweredEmail
    ELSE
        INSERT INTO #PageIndexForUsers (UserId)
            SELECT u.UserId
            FROM   dbo.aspnet_Users u, dbo.aspnet_Membership m
            WHERE  u.ApplicationId = @ApplicationId AND m.UserId = u.UserId AND m.LoweredEmail LIKE LOWER(@EmailToMatch)
            ORDER BY m.LoweredEmail

    SELECT  u.UserName, m.Email, m.PasswordQuestion, m.Comment, m.IsApproved,
            m.CreateDate,
            m.LastLoginDate,
            u.LastActivityDate,
            m.LastPasswordChangedDate,
            u.UserId, m.IsLockedOut,
            m.LastLockoutDate
    FROM   dbo.aspnet_Membership m, dbo.aspnet_Users u, #PageIndexForUsers p
    WHERE  u.UserId = p.UserId AND u.UserId = m.UserId AND
           p.IndexId >= @PageLowerBound AND p.IndexId <= @PageUpperBound
    ORDER BY m.LoweredEmail

    SELECT  @TotalRecords = COUNT(*)
    FROM    #PageIndexForUsers
    RETURN @TotalRecords
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_MembershipUsers'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_MembershipUsers Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_MembershipUsers Created'
GO
CREATE VIEW vw_aspnet_MembershipUsers
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_MembershipUsers]
  AS SELECT members.[UserId],
            members.[PasswordFormat],
            members.[MobilePIN],
            members.[Email],
            members.[LoweredEmail],
            members.[PasswordQuestion],
            members.[PasswordAnswer],
            members.[IsApproved],
            members.[IsLockedOut],
            members.[CreateDate],
            members.[LastLoginDate],
            members.[LastPasswordChangedDate],
            members.[LastLockoutDate],
            members.[FailedPasswordAttemptCount],
            members.[FailedPasswordAttemptWindowStart],
            members.[FailedPasswordAnswerAttemptCount],
            members.[FailedPasswordAnswerAttemptWindowStart],
            members.[Comment],
            users.[ApplicationId],
            users.[UserName],
            users.[MobileAlias],
            users.[IsAnonymous],
            users.[LastActivityDate]
  FROM [dbo].[aspnet_Membership] members INNER JOIN [dbo].[aspnet_Users] users
      ON members.[UserId] = users.[UserId]
  

GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_IsUserInRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_IsUserInRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_IsUserInRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [aspnet_UsersInRoles_IsUserInRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_IsUserInRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_IsUserInRole]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(2)
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL
    DECLARE @RoleId uniqueidentifier
    SELECT  @RoleId = NULL

    SELECT  @UserId = UserId
    FROM    dbo.aspnet_Users
    WHERE   LoweredUserName = LOWER(@UserName) AND ApplicationId = @ApplicationId

    IF (@UserId IS NULL)
        RETURN(2)

    SELECT  @RoleId = RoleId
    FROM    dbo.aspnet_Roles
    WHERE   LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId

    IF (@RoleId IS NULL)
        RETURN(3)

    IF (EXISTS( SELECT * FROM dbo.aspnet_UsersInRoles WHERE  UserId = @UserId AND RoleId = @RoleId))
        RETURN(1)
    ELSE
        RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_GetRolesForUser'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_GetRolesForUser] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_GetRolesForUser] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_GetRolesForUser]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_GetRolesForUser]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_GetRolesForUser]
    @ApplicationName  nvarchar(256),
    @UserName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
    DECLARE @UserId uniqueidentifier
    SELECT  @UserId = NULL

    SELECT  @UserId = UserId
    FROM    dbo.aspnet_Users
    WHERE   LoweredUserName = LOWER(@UserName) AND ApplicationId = @ApplicationId

    IF (@UserId IS NULL)
        RETURN(1)

    SELECT r.RoleName
    FROM   dbo.aspnet_Roles r, dbo.aspnet_UsersInRoles ur
    WHERE  r.RoleId = ur.RoleId AND r.ApplicationId = @ApplicationId AND ur.UserId = @UserId
    ORDER BY r.RoleName
    RETURN (0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_CreateRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_CreateRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_CreateRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_CreateRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_CreateRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_CreateRole]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
        BEGIN TRANSACTION
        SET @TranStarted = 1
    END
    ELSE
        SET @TranStarted = 0

    EXEC dbo.aspnet_Applications_CreateApplication @ApplicationName, @ApplicationId OUTPUT

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF (EXISTS(SELECT RoleId FROM dbo.aspnet_Roles WHERE LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId))
    BEGIN
        SET @ErrorCode = 1
        GOTO Cleanup
    END

    INSERT INTO dbo.aspnet_Roles
                (ApplicationId, RoleName, LoweredRoleName)
         VALUES (@ApplicationId, @RoleName, LOWER(@RoleName))

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        COMMIT TRANSACTION
    END

    RETURN(0)

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode

END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_DeleteRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_DeleteRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_DeleteRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_DeleteRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_DeleteRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_DeleteRole]
    @ApplicationName            nvarchar(256),
    @RoleName                   nvarchar(256),
    @DeleteOnlyIfRoleIsEmpty    bit
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)

    DECLARE @ErrorCode     int
    SET @ErrorCode = 0

    DECLARE @TranStarted   bit
    SET @TranStarted = 0

    IF( @@TRANCOUNT = 0 )
    BEGIN
        BEGIN TRANSACTION
        SET @TranStarted = 1
    END
    ELSE
        SET @TranStarted = 0

    DECLARE @RoleId   uniqueidentifier
    SELECT  @RoleId = NULL
    SELECT  @RoleId = RoleId FROM dbo.aspnet_Roles WHERE LoweredRoleName = LOWER(@RoleName) AND ApplicationId = @ApplicationId

    IF (@RoleId IS NULL)
    BEGIN
        SELECT @ErrorCode = 1
        GOTO Cleanup
    END
    IF (@DeleteOnlyIfRoleIsEmpty <> 0)
    BEGIN
        IF (EXISTS (SELECT RoleId FROM dbo.aspnet_UsersInRoles  WHERE @RoleId = RoleId))
        BEGIN
            SELECT @ErrorCode = 2
            GOTO Cleanup
        END
    END


    DELETE FROM dbo.aspnet_UsersInRoles  WHERE @RoleId = RoleId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    DELETE FROM dbo.aspnet_Roles WHERE @RoleId = RoleId  AND ApplicationId = @ApplicationId

    IF( @@ERROR <> 0 )
    BEGIN
        SET @ErrorCode = -1
        GOTO Cleanup
    END

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        COMMIT TRANSACTION
    END

    RETURN(0)

Cleanup:

    IF( @TranStarted = 1 )
    BEGIN
        SET @TranStarted = 0
        ROLLBACK TRANSACTION
    END

    RETURN @ErrorCode
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_RoleExists'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_RoleExists] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_RoleExists] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_Roles_RoleExists]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_RoleExists]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_RoleExists]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(0)
    IF (EXISTS (SELECT RoleName FROM dbo.aspnet_Roles WHERE LOWER(@RoleName) = LoweredRoleName AND ApplicationId = @ApplicationId ))
        RETURN(1)
    ELSE
        RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_AddUsersToRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_AddUsersToRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_AddUsersToRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_AddUsersToRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_AddUsersToRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_AddUsersToRoles]
	@ApplicationName  nvarchar(256),
	@UserNames		  nvarchar(4000),
	@RoleNames		  nvarchar(4000),
	@CurrentTimeUtc   datetime
AS
BEGIN
	DECLARE @AppId uniqueidentifier
	SELECT  @AppId = NULL
	SELECT  @AppId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName collate database_default
	IF (@AppId IS NULL)
		RETURN(2)
	DECLARE @TranStarted   int
	SET @TranStarted = 0

	IF( @@TRANCOUNT = 0 )
	BEGIN
		BEGIN TRANSACTION
		SET @TranStarted = 1
	END

	DECLARE @tbNames	table(Name nvarchar(256) NOT NULL PRIMARY KEY)
	DECLARE @tbRoles	table(RoleId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @tbUsers	table(UserId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @Num		int
	DECLARE @Pos		int
	DECLARE @NextPos	int
	DECLARE @Name		nvarchar(256)

	SET @Num = 0
	SET @Pos = 1
	WHILE(@Pos <= LEN(@RoleNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @RoleNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@RoleNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@RoleNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbRoles
	  SELECT RoleId
	  FROM   dbo.aspnet_Roles ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredRoleName AND ar.ApplicationId = @AppId

	IF (@@ROWCOUNT <> @Num)
	BEGIN
		SELECT TOP 1 Name
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT ar.LoweredRoleName FROM dbo.aspnet_Roles ar,  @tbRoles r WHERE r.RoleId = ar.RoleId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(2)
	END

	DELETE FROM @tbNames WHERE 1=1
	SET @Num = 0
	SET @Pos = 1

	WHILE(@Pos <= LEN(@UserNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @UserNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@UserNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@UserNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbUsers
	  SELECT UserId
	  FROM   dbo.aspnet_Users ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredUserName AND ar.ApplicationId = @AppId

	IF (@@ROWCOUNT <> @Num)
	BEGIN
		DELETE FROM @tbNames
		WHERE LOWER(Name)  collate database_default IN (SELECT LoweredUserName FROM dbo.aspnet_Users au,  @tbUsers u WHERE au.UserId = u.UserId)

		INSERT dbo.aspnet_Users (ApplicationId, UserId, UserName, LoweredUserName, IsAnonymous, LastActivityDate)
		  SELECT @AppId, NEWID(), Name, LOWER(Name) collate database_default, 0, @CurrentTimeUtc
		  FROM   @tbNames

		INSERT INTO @tbUsers
		  SELECT  UserId
		  FROM	dbo.aspnet_Users au, @tbNames t
		  WHERE   LOWER(t.Name) collate database_default = au.LoweredUserName AND au.ApplicationId = @AppId
	END

	IF (EXISTS (SELECT * FROM dbo.aspnet_UsersInRoles ur, @tbUsers tu, @tbRoles tr WHERE tu.UserId = ur.UserId AND tr.RoleId = ur.RoleId))
	BEGIN
		SELECT TOP 1 UserName, RoleName
		FROM		 dbo.aspnet_UsersInRoles ur, @tbUsers tu, @tbRoles tr, aspnet_Users u, aspnet_Roles r
		WHERE		u.UserId = tu.UserId AND r.RoleId = tr.RoleId AND tu.UserId = ur.UserId AND tr.RoleId = ur.RoleId

		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(3)
	END

	INSERT INTO dbo.aspnet_UsersInRoles (UserId, RoleId)
	SELECT UserId, RoleId
	FROM @tbUsers, @tbRoles

	IF( @TranStarted = 1 )
		COMMIT TRANSACTION
	RETURN(0)
END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_RemoveUsersFromRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_RemoveUsersFromRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_RemoveUsersFromRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]
	@ApplicationName  nvarchar(256),
	@UserNames		  nvarchar(4000),
	@RoleNames		  nvarchar(4000)
AS
BEGIN
	DECLARE @AppId uniqueidentifier
	SELECT  @AppId = NULL
	SELECT  @AppId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	IF (@AppId IS NULL)
		RETURN(2)


	DECLARE @TranStarted   bit
	SET @TranStarted = 0

	IF( @@TRANCOUNT = 0 )
	BEGIN
		BEGIN TRANSACTION
		SET @TranStarted = 1
	END

	DECLARE @tbNames  table(Name nvarchar(256) NOT NULL PRIMARY KEY)
	DECLARE @tbRoles  table(RoleId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @tbUsers  table(UserId uniqueidentifier NOT NULL PRIMARY KEY)
	DECLARE @Num	  int
	DECLARE @Pos	  int
	DECLARE @NextPos  int
	DECLARE @Name	  nvarchar(256)
	DECLARE @CountAll int
	DECLARE @CountU	  int
	DECLARE @CountR	  int


	SET @Num = 0
	SET @Pos = 1
	WHILE(@Pos <= LEN(@RoleNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @RoleNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@RoleNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@RoleNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbRoles
	  SELECT RoleId
	  FROM   dbo.aspnet_Roles ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredRoleName AND ar.ApplicationId = @AppId
	SELECT @CountR = @@ROWCOUNT

	IF (@CountR <> @Num)
	BEGIN
		SELECT TOP 1 N'', Name
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT ar.LoweredRoleName FROM dbo.aspnet_Roles ar,  @tbRoles r WHERE r.RoleId = ar.RoleId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(2)
	END


	DELETE FROM @tbNames WHERE 1=1
	SET @Num = 0
	SET @Pos = 1


	WHILE(@Pos <= LEN(@UserNames))
	BEGIN
		SELECT @NextPos = CHARINDEX(N',', @UserNames,  @Pos)
		IF (@NextPos = 0 OR @NextPos IS NULL)
			SELECT @NextPos = LEN(@UserNames) + 1
		SELECT @Name = RTRIM(LTRIM(SUBSTRING(@UserNames, @Pos, @NextPos - @Pos)))
		SELECT @Pos = @NextPos+1

		INSERT INTO @tbNames VALUES (@Name)
		SET @Num = @Num + 1
	END

	INSERT INTO @tbUsers
	  SELECT UserId
	  FROM   dbo.aspnet_Users ar, @tbNames t
	  WHERE  LOWER(t.Name) collate database_default = ar.LoweredUserName AND ar.ApplicationId = @AppId

	SELECT @CountU = @@ROWCOUNT
	IF (@CountU <> @Num)
	BEGIN
		SELECT TOP 1 Name, N''
		FROM   @tbNames
		WHERE  LOWER(Name) collate database_default NOT IN (SELECT au.LoweredUserName FROM dbo.aspnet_Users au,  @tbUsers u WHERE u.UserId = au.UserId)

		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(1)
	END

	SELECT  @CountAll = COUNT(*)
	FROM	dbo.aspnet_UsersInRoles ur, @tbUsers u, @tbRoles r
	WHERE   ur.UserId = u.UserId AND ur.RoleId = r.RoleId

	IF (@CountAll <> @CountU * @CountR)
	BEGIN
		SELECT TOP 1 UserName, RoleName
		FROM		 @tbUsers tu, @tbRoles tr, dbo.aspnet_Users u, dbo.aspnet_Roles r
		WHERE		 u.UserId = tu.UserId AND r.RoleId = tr.RoleId AND
					 tu.UserId NOT IN (SELECT ur.UserId FROM dbo.aspnet_UsersInRoles ur WHERE ur.RoleId = tr.RoleId) AND
					 tr.RoleId NOT IN (SELECT ur.RoleId FROM dbo.aspnet_UsersInRoles ur WHERE ur.UserId = tu.UserId)
		IF( @TranStarted = 1 )
			ROLLBACK TRANSACTION
		RETURN(3)
	END

	DELETE FROM dbo.aspnet_UsersInRoles
	WHERE UserId IN (SELECT UserId FROM @tbUsers)
	  AND RoleId IN (SELECT RoleId FROM @tbRoles)
	IF( @TranStarted = 1 )
		COMMIT TRANSACTION
	RETURN(0)
END
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_GetUsersInRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_GetUsersInRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_GetUsersInRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UsersInRoles_GetUsersInRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_GetUsersInRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_GetUsersInRoles]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
     DECLARE @RoleId uniqueidentifier
     SELECT  @RoleId = NULL

     SELECT  @RoleId = RoleId
     FROM    dbo.aspnet_Roles
     WHERE   LOWER(@RoleName) collate database_default = LoweredRoleName AND ApplicationId = @ApplicationId

     IF (@RoleId IS NULL)
         RETURN(1)

    SELECT u.UserName
    FROM   dbo.aspnet_Users u, dbo.aspnet_UsersInRoles ur
    WHERE  u.UserId = ur.UserId AND @RoleId = ur.RoleId AND u.ApplicationId = @ApplicationId
    ORDER BY u.UserName
    RETURN(0)
END
GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_UsersInRoles_FindUsersInRole'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_UsersInRoles_FindUsersInRole] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_UsersInRoles_FindUsersInRole] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[aspnet_UsersInRoles_FindUsersInRole]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_UsersInRoles_FindUsersInRole]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_UsersInRoles_FindUsersInRole]
    @ApplicationName  nvarchar(256),
    @RoleName         nvarchar(256),
    @UserNameToMatch  nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN(1)
     DECLARE @RoleId uniqueidentifier
     SELECT  @RoleId = NULL

     SELECT  @RoleId = RoleId
     FROM    dbo.aspnet_Roles
     WHERE   LOWER(@RoleName) collate database_default = LoweredRoleName AND ApplicationId = @ApplicationId

     IF (@RoleId IS NULL)
         RETURN(1)

    SELECT u.UserName
    FROM   dbo.aspnet_Users u, dbo.aspnet_UsersInRoles ur
    WHERE  u.UserId = ur.UserId AND @RoleId = ur.RoleId AND u.ApplicationId = @ApplicationId AND LoweredUserName LIKE LOWER(@UserNameToMatch) collate database_default
    ORDER BY u.UserName
    RETURN(0)
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Roles_GetAllRoles'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:[aspnet_Roles_GetAllRoles] updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:[aspnet_Roles_GetAllRoles] create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Roles_GetAllRoles]
AS
    SELECT  'created, but not implemented yet.';
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Roles_GetAllRoles]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Roles_GetAllRoles] 
    @ApplicationName nvarchar(256)
AS
BEGIN
    DECLARE @ApplicationId uniqueidentifier
    SELECT  @ApplicationId = NULL
    SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) collate database_default = LoweredApplicationName
    IF (@ApplicationId IS NULL)
        RETURN
    SELECT RoleName
    FROM   dbo.aspnet_Roles WHERE ApplicationId = @ApplicationId
    ORDER BY RoleName
END
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_Roles'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
  BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Roles Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_Roles Created'
GO
CREATE VIEW vw_aspnet_Roles
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_Roles]
  AS SELECT [ApplicationId], [RoleId], [RoleName], [LoweredRoleName], [Description]
  FROM [dbo].[aspnet_Roles]
  
  GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vw_aspnet_UsersInRoles'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    
	PRINT SPACE(10) + N'...ASPNET View vw_aspnet_UsersInRoles Altered'
	SET NOEXEC on
 END
 ELSE
 PRINT SPACE(10) + N'...ASPNET View vw_aspnet_UsersInRoles Created'
GO
CREATE VIEW vw_aspnet_UsersInRoles
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	

ALTER VIEW [dbo].[vw_aspnet_UsersInRoles]
  AS SELECT [UserId], [RoleId]
  FROM [dbo].[aspnet_UsersInRoles]


GO
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME LIKE 'aspnet_Setup_RemoveAllRoleMembers'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...ASPNET Stored Procedures:aspnet_Setup_RemoveAllRoleMembers updated';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + 'ASNET Stored Procedure:aspnet_Setup_RemoveAllRoleMembers create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE  [dbo].[aspnet_Setup_RemoveAllRoleMembers]
AS
    SELECT  'created, but not implemented yet.'
	
--just anything will do

GO

PRINT N'Creating [dbo].[aspnet_Setup_RemoveAllRoleMembers]'
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[aspnet_Setup_RemoveAllRoleMembers]
    @name   sysname
AS
BEGIN
    CREATE TABLE #aspnet_RoleMembers
    (
        Group_name      sysname,
        Group_id        smallint,
        Users_in_group  sysname,
        User_id         smallint
    )

    INSERT INTO #aspnet_RoleMembers
    EXEC sp_helpuser @name

    DECLARE @user_id smallint
    DECLARE @cmd nvarchar(500)
    DECLARE c1 cursor FORWARD_ONLY FOR
        SELECT User_id FROM #aspnet_RoleMembers

    OPEN c1

    FETCH c1 INTO @user_id
    WHILE (@@fetch_status = 0)
    BEGIN
        SET @cmd = 'EXEC sp_droprolemember ' + '''' + @name + ''', ''' + USER_NAME(@user_id) + ''''
        EXEC (@cmd)
        FETCH c1 INTO @user_id
    END

    CLOSE c1
    DEALLOCATE c1
END
GO
PRINT N'Adding foreign keys to [dbo].[aspnet_Membership]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Me__Appli__276EDEB3')
BEGIN
PRINT N'foreign key [FK__aspnet_Me__Appli__276EDEB3] for [dbo].[aspnet_Membership] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key [FK__aspnet_Me__Appli__276EDEB3] to [dbo].[aspnet_Membership]'
ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [FK__aspnet_Me__Appli__276EDEB3] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

SET NOEXEC OFF

IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Me__UserI__286302EC')
BEGIN
PRINT N'foreign key FK__aspnet_Me__UserI__286302EC for [dbo].[aspnet_Membership] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Me__UserI__286302EC to [dbo].[aspnet_Membership]'
ALTER TABLE [dbo].[aspnet_Membership] ADD CONSTRAINT [FK__aspnet_Me__UserI__286302EC] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

SET NOEXEC OFF
PRINT N'Adding foreign keys to [dbo].[aspnet_Roles]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Ro__Appli__3C69FB99')
BEGIN
PRINT N'foreign key FK__aspnet_Ro__Appli__3C69FB99 for [dbo].[aspnet_Roles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Ro__Appli__3C69FB99 to [dbo].[aspnet_Roles]'
ALTER TABLE [dbo].[aspnet_Roles] ADD CONSTRAINT [FK__aspnet_Ro__Appli__3C69FB99] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

SET NOEXEC OFF
PRINT N'Adding foreign keys to [dbo].[aspnet_Users]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__Appli__173876EA')
BEGIN
PRINT N'foreign key FK__aspnet_Us__Appli__173876EA for [dbo].[aspnet_Roles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Us__Appli__173876EA to [dbo].[aspnet_Roles]'

ALTER TABLE [dbo].[aspnet_Users] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__Appli__173876EA] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO


SET NOEXEC OFF

PRINT N'Adding foreign keys to [dbo].[aspnet_UsersInRoles]'
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__UserI__403A8C7D')
BEGIN
PRINT N'foreign key FK__aspnet_Ro__Appli__403A8C7D for [dbo].[aspnet_UsersInRoles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Ro__Appli__403A8C7D to [dbo].[aspnet_UsersInRoles]'
ALTER TABLE [dbo].[aspnet_UsersInRoles] ADD CONSTRAINT [FK__aspnet_Us__UserI__403A8C7D] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])

END
GO

SET NOEXEC OFF
IF EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]  AS [t] WHERE [t].[CONSTRAINT_NAME] = 'FK__aspnet_Us__RoleI__412EB0B6')
BEGIN
PRINT N'foreign key FK__aspnet_Us__RoleI__412EB0B6 for [dbo].[aspnet_UsersInRoles] exists'
SET NOEXEC ON 
END
ELSE
begin
PRINT N'Adding foreign key FK__aspnet_Us__RoleI__412EB0B6 to [dbo].[aspnet_UsersInRoles]'
ALTER TABLE [dbo].[aspnet_UsersInRoles] WITH CHECK  ADD CONSTRAINT [FK__aspnet_Us__RoleI__412EB0B6] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])

END
GO

SET NOEXEC OFF



PRINT N'Altering permissions on  [dbo].[aspnet_CheckSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_CheckSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_ChangePasswordQuestionAndAnswer] TO [aspnet_Membership_FullAccess]
GO

IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_CreateUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_CreateUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_FindUsersByEmail]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_FindUsersByEmail] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_FindUsersByName]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_FindUsersByName] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetAllUsers]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetAllUsers] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetNumberOfUsersOnline]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetNumberOfUsersOnline] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetNumberOfUsersOnline] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetPasswordWithFormat]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetPasswordWithFormat] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetPassword] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByEmail]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByEmail] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByEmail] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByName]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByName] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByName] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_GetUserByUserId]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByUserId] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_GetUserByUserId] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_ResetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_ResetPassword] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_SetPassword]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_SetPassword] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UnlockUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UnlockUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UpdateUserInfo]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UpdateUserInfo] TO [aspnet_Membership_BasicAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Membership_UpdateUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Membership_UpdateUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_RegisterSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_RegisterSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_CreateRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_CreateRole] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_DeleteRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_DeleteRole] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_GetAllRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_GetAllRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Roles_RoleExists]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Roles_RoleExists] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UnRegisterSchemaVersion]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Membership_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Membership_ReportingAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UnRegisterSchemaVersion] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_AddUsersToRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_AddUsersToRoles] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_FindUsersInRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_FindUsersInRole] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_GetRolesForUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetRolesForUser] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetRolesForUser] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_GetUsersInRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_GetUsersInRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_IsUserInRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_IsUserInRole] TO [aspnet_Roles_BasicAccess]
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_IsUserInRole] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_UsersInRoles_RemoveUsersFromRoles] TO [aspnet_Roles_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[aspnet_Users_DeleteUser]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_Users_DeleteUser] TO [aspnet_Membership_FullAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Applications]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Applications] TO [aspnet_Membership_ReportingAccess]
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Applications] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_MembershipUsers]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_MembershipUsers] TO [aspnet_Membership_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Roles]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Roles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_UsersInRoles]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_UsersInRoles] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
PRINT N'Altering permissions on  [dbo].[vw_aspnet_Users]'
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Users] TO [aspnet_Membership_ReportingAccess]
GO
GRANT SELECT ON  [dbo].[vw_aspnet_Users] TO [aspnet_Roles_ReportingAccess]
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
COMMIT TRANSACTION
GO
IF @@ERROR <> 0 SET NOEXEC ON
GO
DECLARE @Success AS BIT
SET @Success = 1
SET NOEXEC OFF
IF (@Success = 1) PRINT 'The ASPNET installation succeeded'
ELSE BEGIN
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	PRINT 'The ASPNET installation update failed'
END
GO
