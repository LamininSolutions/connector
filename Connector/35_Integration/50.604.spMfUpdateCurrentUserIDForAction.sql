


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateCurrentUserIDForAction]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFUpdateCurrentUserIDForAction', -- nvarchar(100)
    @Object_Release = '3.2.1.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateCurrentUserIDForAction'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateCurrentUserIDForAction
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateCurrentUserIDForAction
@UserID int,
@Action varchar(150)
as 
Begin

    Update MFContextMenu set ActionUser_ID=@UserID where Action=@Action
END

GO
