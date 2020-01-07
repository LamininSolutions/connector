PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateContextMenu]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFUpdateContextMenu', -- nvarchar(100)
    @Object_Release = '4.5.14.56', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go
/*
 Change history


*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateContextMenu'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
CREATE PROCEDURE [dbo].[spMFUpdateContextMenu]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do
go
-- the following section will be always executed
SET NOEXEC OFF;
go

alter Procedure [dbo].[spMFUpdateContextMenu]
@ID int,
@UserID int 
as 
Begin
    UPdate MFContextMenu set ActionUser_ID=@UserID, Last_Executed_By=@UserID, Last_Executed_Date=getdate() where ID=@ID
End
GO


