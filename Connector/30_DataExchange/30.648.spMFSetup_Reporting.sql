

/*
Reporting setup

input: classes include in reporting

validate connection
synchronise metadata
create class tables
refresh data
create all lookup views
create custom update procedure
create menu item in context menu
create update button
create view
create sample table view
create joins view


*/
GO


PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSetup_Reporting]';
GO

SET NOCOUNT ON;
GO


EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFSetup_Reporting', -- nvarchar(100)
                                 @Object_Release = '4.10.29.74',
                                 @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSetup_Reporting' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE dbo.spMFSetup_Reporting
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFSetup_Reporting
    @Classes NVARCHAR(400),
    @Debug INT = 0
AS


/*rST**************************************************************************

===================
spMFSetup_Reporting
===================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Classes
    - Valid Class Names as a comma delimited string
    - e.g.: 'Customer, Purchase Invoice'
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Custom script to prepare database for reporting

Additional Info
===============


The following will be automatically executed in sequence

- test Connection
- Update Metadata structure
- create class tables
- create all related lookups
- create menu items in Context menu

On completion login to vault and action update reporting data to update class tables from M-Files to SQL

Alternatively use spMFUpdateTable to pull records into class table

Warnings
========

The procedure is useful to create a limited number of classes for reporting (max 10) at a time.

Examples
========

.. code:: sql

    EXEC [spMFSetup_Reporting] @Classes = 'Customer, Drawing'
                                ,@Debug = 0   -- int

.. code:: sql

    SELECT * FROM MFContextMenu

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-03-17  LC         add additional automated functionality
2022-01-26  Lc         Fix valuelist creation
2019-09-27  LC         Adjust to setup context menu group for access
2019-05-17  LC         Set security for menu to MFSQLConnector group
2019-04-10  LC         Adjust to allow for context menu configuration in different languages
2019-01-31  LC         Fix bug for spmfDropandUpdateTable parameter
2018-11-12  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

BEGIN
    -- Debug params
    DECLARE @DebugText NVARCHAR(100);
    DECLARE @DefaultDebugText NVARCHAR(100) = N'Proc: %s Step: %s';
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = N'spMFSetup_Reporting';

    SET @Procedurestep = N'Start';

    --Other Variables
    DECLARE @ProcessBatch_ID INT;
    DECLARE @className NVARCHAR(100);
    ------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    DECLARE @error AS INT = 0;

    -------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    --BEGIN  
    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;


    PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'Script to setup reporting for classes '
          + @Classes;

    RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);


    -------------------------------------------------------------
    -- Custom params
    -------------------------------------------------------------
    DECLARE @MessageOUt NVARCHAR(100);

    --<Begin Proc>--
    SET @Procedurestep = N'Connection Test';

    --
    -------------------------------------------------------------
    -- connection test	
    -------------------------------------------------------------
    EXEC @return_value = dbo.spMFVaultConnectionTest @MessageOut = @MessageOUt OUTPUT; -- nvarchar(100)

    IF @return_value <> 1
    BEGIN
        SET @DebugText = N' Unable To connect to Vault - Routine aborted';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep);
    END;
    ELSE
    BEGIN
        SET @DebugText = N' :Connected to vault ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

    END;

    -------------------------------------------------------------
    -- Update Metadata
    -------------------------------------------------------------
    SET @Procedurestep = N'Synchronize metadata';

    IF
    (
        SELECT COUNT(*)FROM dbo.MFClass
    ) = 0
    BEGIN
        EXEC @return_value = dbo.spMFSynchronizeMetadata @Debug = 0,                                 -- smallint
                                                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT; -- int
    END;
    ELSE
    BEGIN
        EXEC @return_value = dbo.spMFDropAndUpdateMetadata @IsResetAll = 0,                            -- smallint
                                                           @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                                           @Debug = 0,                                 -- smallint
                                                           @WithClassTableReset = 0,                   -- smallint
                                                           @IsStructureOnly = 1;                       -- smallint
    END;

    IF @return_value <> 1
    BEGIN
        SET @DebugText = N' Unable to update metadata - Routine aborted';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep);
    END;
    ELSE
    BEGIN
        SET @DebugText = N' :Successfully updated Metadata';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
    END;
END;

-------------------------------------------------------------
-- Create tables
-------------------------------------------------------------
SET @Procedurestep = N'Create Class tables ';

DECLARE @ClassList AS TABLE
(
    id INT IDENTITY,
    Item NVARCHAR(100)
);

INSERT INTO @ClassList
(
    Item
)
SELECT LTRIM(fmpds.ListItem)
FROM dbo.fnMFParseDelimitedString(@Classes, ',') AS fmpds;

-------------------------------------------------------------
-- validate classes entered
------------------------------------------------------------
DECLARE @ErrorClasses NVARCHAR(100);

SELECT @ErrorClasses = STUFF(
                       (
                           SELECT ', ' + cl.Item
                           FROM @ClassList AS cl
                               LEFT JOIN dbo.MFClass AS mc
                                   ON mc.Name = cl.Item
                           WHERE mc.Name IS NULL
                           FOR XML PATH('')
                       ),
                       1,
                       1,
                       ''
                            );

--						SELECT @ErrorClasses

IF @ErrorClasses IS NOT NULL
BEGIN
    SET @DebugText = N' Unable to find classes: %s. reenter parameter and try again - Routine aborted';
    SET @DebugText = @DefaultDebugText + @DebugText;

    RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep, @ErrorClasses);
END;

IF
(
    SELECT COUNT(*)FROM @ClassList
) > 0
AND @ErrorClasses IS NULL
BEGIN
    SET @rowcount = 1;

    WHILE @rowcount IS NOT NULL
    BEGIN
        SELECT @className = Item
        FROM @ClassList
        WHERE id = @rowcount;

        EXEC @return_value = dbo.spMFCreateTable @className;

        IF @return_value = 1
        BEGIN
            SET @DebugText = N' :Successfully created Table for %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @className);
        END;
        ELSE
        BEGIN
            SET @DebugText = N' :Unable to create Table for %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @className);
        END;

        SELECT @rowcount =
        (
            SELECT MIN(l.id)FROM @ClassList AS l WHERE l.id > @rowcount
        );
    END;

    -------------------------------------------------------------
    -- lookups to create
    -------------------------------------------------------------
    DECLARE @Valuelists AS TABLE
    (
        id INT IDENTITY,
        Name NVARCHAR(100)
    );

    DECLARE @ValuelistName NVARCHAR(100);
    DECLARE @ViewName NVARCHAR(100);

    EXEC dbo.spMFClassTableColumns @ErrorsOnly = 0, @IsSilent = 1;

    INSERT INTO @Valuelists
    (
        Name
    )
    SELECT REPLACE(lookupType, 'Valuelist_', '')
    FROM ##spMFClassTableColumns
    WHERE class IN
          (
              SELECT Item FROM @ClassList
          )
          AND SUBSTRING(lookupType, 1, 9) = 'Valuelist'
    GROUP BY lookupType;

    IF
    (
        SELECT COUNT(*)FROM @Valuelists
    ) > 0
    BEGIN
        SET @rowcount = 1;

        WHILE @rowcount IS NOT NULL
        BEGIN
            SELECT @ValuelistName = Name
            FROM @Valuelists
            WHERE id = @rowcount;

            SET @ViewName = N'vw' + @ValuelistName;

            EXEC dbo.spMFCreateValueListLookupView @ValueListName = @ValuelistName, -- nvarchar(128)
                                                   @ViewName = @ViewName,           -- nvarchar(128)
                                                   @Schema = 'Custom',              -- nvarchar(20)
                                                   @Debug = 0;                      -- smallint

            SET @DebugText = N' :Successfully created View for Valuelist %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @ValuelistName);

            SELECT @rowcount =
            (
                SELECT MIN(l.id)FROM @Valuelists AS l WHERE l.id > @rowcount
            );
        END;

        -------------------------------------------------------------
        -- setup MFContextmenu
        -------------------------------------------------------------
        SET @Procedurestep = N'Create MFContextmenu records';
        DECLARE @UserGroup NVARCHAR(100),
                @Usergroup_ID INT;
        SET @UserGroup = N'ContextMenu';

        SELECT TOP 1
               @Usergroup_ID = ug.UserGroupID
        FROM dbo.MFVaultSettings AS mvs
            INNER JOIN dbo.MFLoginAccount AS mla
                ON mvs.Username = mla.UserName
            CROSS APPLY
        (
            SELECT mfug.UserGroupID
            FROM dbo.MFvwUserGroup AS mfug
            WHERE mfug.Name = @UserGroup
        ) ug;



        EXEC dbo.spMFContextMenuHeadingItem @MenuName = 'Update Tables', -- nvarchar(100)
                                            @PriorMenu = NULL,           -- nvarchar(100)
                                            @IsObjectContextMenu = 0,    -- bit
                                            @IsRemove = 0,               -- bit
                                            @UserGroup = @UserGroup,     -- nvarchar(100)
                                            @Debug = 0;                  -- int

        EXEC dbo.spMFContextMenuActionItem @ActionName = 'Update Reporting Data',                -- nvarchar(100)
                                           @ProcedureName = 'custom.DoUpdateReportingData',      -- nvarchar(100)
                                           @Description = 'Updating all tables included in App', -- nvarchar(200)
                                           @RelatedMenu = 'Update Tables',                       -- nvarchar(100)
                                           @IsRemove = 0,                                        -- bit
                                           @IsObjectContext = 0,                                 -- bit
                                           @IsWeblink = 0,                                       -- bit
                                           @IsAsynchronous = 1,                                  -- bit
                                           @IsStateAction = 0,                                   -- bit
                                           @PriorAction = NULL,                                  -- nvarchar(100)
                                           @UserGroup = @UserGroup,                              -- nvarchar(100)
                                           @Debug = 0;                                           -- int

        SET @DebugText = N' :Successfully created menu item for updating tables';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

        -------------------------------------------------------------
        -- Validate usergroup
        -------------------------------------------------------------
        UPDATE mcm
        SET mcm.UserGroupID = @Usergroup_ID
        FROM dbo.MFContextMenu AS mcm
        WHERE ISNULL(mcm.UserGroupID, 1) = 1;
        -------------------------------------------------------------
        -- Reset messaging to allow for messages to be be produced in app
        -------------------------------------------------------------
        SET @Procedurestep = N'enable User Messages';
        UPDATE dbo.MFSettings
        SET Value = '1'
        WHERE Name = 'App_DetailLogging';

        UPDATE dbo.MFSettings
        SET Value = '1'
        WHERE Name = 'MFUserMessagesEnabled';



        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

        -------------------------------------------------------------
        -- update tables
        -------------------------------------------------------------

        SET @Procedurestep = N'Update all tables';

        EXEC dbo.spMFUpdateAllncludedInAppTables @UpdateMethod = 1,
                                                 @RemoveDeleted = 1,
                                                 @IsIncremental = 0,
                                                 @RetainDeletions = 0,
                                                 @SendClassErrorReport = 0,
                                                 @ProcessBatch_ID = @ProcessBatch_ID,
                                                 @Debug = 0;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

        -------------------------------------------------------------
        -- show table result
        -------------------------------------------------------------

        --list TOP 10 OF every table

        DECLARE @mfid INT;
        DECLARE @MFTableName NVARCHAR(100);

        SELECT @mfid = MIN(MFID)
        FROM dbo.MFClass
        WHERE IncludeInApp IS NOT NULL;

        WHILE @mfid IS NOT NULL
        BEGIN
            SELECT @MFTableName = TableName
            FROM dbo.MFClass
            WHERE MFID = @mfid;

            SELECT 'Top 10 rows for ' + @MFTableName AS TableName;
            SET @sql = 'SELECT TOP 10 * FROM ' + @MFTableName;

            IF
            (
                SELECT OBJECT_ID(@MFTableName)
            ) IS NOT NULL
            BEGIN
                EXEC (@sql);
            END;
            ELSE
                SELECT 'Table ' + @MFTableName + ' does not exist. Class table to be created first';


            SELECT @mfid =
            (
                SELECT MIN(MFID)FROM dbo.MFClass WHERE MFID > @mfid AND IncludeInApp is NOT null
            );
        END;

        -------------------------------------------------------------
        -- create custom view
        -------------------------------------------------------------


        -------------------------------------------------------------
        -- processs class table stats
        -------------------------------------------------------------
        SET @Procedurestep = N'Show class table stats';

        SELECT 'Show Class Tables statistics'

        EXEC dbo.spMFClassTableStats;


        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

    END;
END;
GO