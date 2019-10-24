
SET NOCOUNT ON; 
GO
/*
Metadata Card Configuration
Schema: CardConf

Tables: 
MFConditions
MFGroups
MFProperties
MFMetadataCard



	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-12

*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Cardconf.MFConditions';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'Cardconf', @ObjectName = N'MFConditions', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFConditions'
                        AND SCHEMA_NAME(schema_id) = 'Cardconf' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';


CREATE TABLE Cardconf.MFConditions
(Condition_ID INT IDENTITY primary KEY,	
Rule_ID int,
Class_Aliases nvarchar(400), --- as comma delimited string of all the classes to include in condition
PropertyAliases NVARCHAR(4000), --- as comma delimited string of all the Properties to include in condition
PropertyValues NVARCHAR(4000) -- as comma delimited string of the objid's or QUIDs of the objects in same sequence as property aliases.
)

END

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Cardconf.MFGroups';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'Cardconf', @ObjectName = N'MFGroups', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFGroups'
                        AND SCHEMA_NAME(schema_id) = 'Cardconf' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';


--DROP TABLE cardconf.MFGroups
CREATE TABLE cardconf.MFGroups
(Group_ID INT IDENTITY PRIMARY KEY
,GroupName NVARCHAR(128) NOT NULL
,Title NVARCHAR(128) NULL
,IsCollapsible BIT null
,IsCollapsedByDefault BIT NULL
,HasHeader BIT null
,IsDefault BIT null
,IsActive BIT DEFAULT 1
,[Priority] INT null
)

END

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Cardconf.MFCardProperties';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'Cardconf', @ObjectName = N'MFCardProperties', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFCardProperties'
                        AND SCHEMA_NAME(schema_id) = 'Cardconf' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

CREATE TABLE [Cardconf].[MFCardProperties](
	[Property_ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	Rule_ID INT NOT NULL,
	Group_ID INT NULL,
	Property_MFID INT NOT NULL,
	[ToolTip] nvarchar(128) NULL,
	[Description] nvarchar(128) NULL,
	[Label] nvarchar(128) NULL,
	[Priority] int NULL,
	[SetValue] nvarchar(128) NULL,
	SetValue_Content NVARCHAR(128) NULL, -- A user-defined value or a GUID
	SetValue_IsForced BIT NULL,
	SetValue_UseCurrentTime BIT NULL,
	SetValue_UseCurrentDate BIT NULL,
	SetValue_DateDelta INT NULL,
	Operator_Type NVARCHAR(50) NULL, --- is; isNot; hasAny; hasAll
	Operator_Value NVARCHAR(128) NULL, -- values as id or quid comma delimited
	[IsAdditional] bit NULL,
	[IsRequired] bit null,
	[IsHidden] bit null,
	IsActive BIT DEFAULT 1
) ON [PRIMARY]


END

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Cardconf.MFCardRules';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'Cardconf', @ObjectName = N'MFCardRules', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFCardRules'
                        AND SCHEMA_NAME(schema_id) = 'Cardconf' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

--DROP TABLE cardconf.MFCardRules

CREATE TABLE cardconf.MFCardRules
(Rule_ID INT IDENTITY PRIMARY KEY 
,RuleType NVARCHAR(25) NOT NULL -- Condition; Behaviour
,Class_MFID INT NOT null
,RuleName NVARCHAR(128) NOT NULL
,[Description] NVARCHAR(128) NULL
,LevelUpRule_ID int NULL
,[RulePriority] INT NOT null
,RuleCondition_ID int NULL
,IsActive BIT DEFAULT 1
,RuleJson NVARCHAR(MAX)
)

END

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Cardconf.MFMetadatacard';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'Cardconf', @ObjectName = N'MFMetadatacard', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFMetadatacard'
                        AND SCHEMA_NAME(schema_id) = 'Cardconf' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';


CREATE TABLE [CardConf].[MFMetadatacard] 
	( Card_ID INT IDENTITY PRIMARY key,
	Rule_ID int NOT NULL,
	Card_Description NVARCHAR(128) NOT NULL,
	Element_Group NVARCHAR(128) NULL,
	Element NVARCHAR(128) NULL,
	Element_Item NVARCHAR(128) NULL,
	Value NVARCHAR(128) NULL
) ON [PRIMARY]


END

GO

