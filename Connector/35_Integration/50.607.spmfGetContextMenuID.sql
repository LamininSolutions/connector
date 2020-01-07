


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetContextMenuID]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetContextMenuID', -- nvarchar(100)
    @Object_Release = '3.2.1.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetContextMenuID'--name of procedure
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
CREATE PROCEDURE dbo.spMFGetContextMenuID
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER  Procedure spMFGetContextMenuID
@ActionType int,
@ActionName varchar(100),
@ID int Output

as 
Begin
Select @ID=ID from MFContextMenu where ActionType=@ActionType  
and ActionName=@ActionName
End


