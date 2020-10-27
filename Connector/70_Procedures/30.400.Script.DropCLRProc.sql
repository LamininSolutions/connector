

/*
Script to drop all the CLR tables 
Execute before updating Assemblies
*/

/*
MODIFICAITONS TO SCRIPT

version 3.1.2.38	LC	add spMFGetFilesInternal
version 3.1.2.38 ADD spMFGetHistory
test that all the clr procedures have been dropped
version 4.8.24.65  prevent assemblies to be deleted if

*/

IF (SELECT OBJECT_ID('dbo.spMFConnectionTestInternal')) IS null
--EXEC spmfupdateassemblies @MfilesVersion = @MFilesVersion;
RAISERROR('CLR assemblies are not available',10,1);

SET NOCOUNT ON;

    DECLARE @ProcList AS TABLE
    (
        [id] INT IDENTITY
       ,[procname] NVARCHAR(100)
       ,[Schemaname] NVARCHAR(100)
       ,[SchemaID] INT
    );

    DECLARE @ID INT = 1;
    DECLARE @ProcName NVARCHAR(100);
    DECLARE @SchemaName NVARCHAR(100);
    DECLARE @SchemaID INT;
    DECLARE @SQL NVARCHAR(MAX);

    INSERT INTO @ProcList
    (
        [procname]
       ,[Schemaname]
       ,[SchemaID]
    )
    SELECT [so].[name] AS [procname]
          ,[ss].[name] AS [schemaname]
          ,[so].[schema_id]
    FROM [sys].[objects]           [so]
        INNER JOIN [sys].[schemas] [ss]
            ON [ss].[schema_id] = [so].[schema_id]
    WHERE [type] = 'PC'
          AND [so].[name] LIKE 'spMF%';

    WHILE @ID IS NOT NULL
    BEGIN
        SELECT @ProcName   = [pl].[procname]
              ,@SchemaName = [pl].[Schemaname]
              ,@SchemaID   = [pl].[SchemaID]
        FROM @ProcList AS [pl]
        WHERE [pl].[id] = @ID;

        IF EXISTS
        (
            SELECT *
            FROM [sys].[objects]
            WHERE [name] = @ProcName
                  AND [schema_id] = @SchemaID
        )
        BEGIN
            PRINT 'Dropping Procedure: ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ProcName);

            SET @SQL = N'DROP PROCEDURE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ProcName);

            EXEC (@SQL);
        END;

        SET @ID =
        (
            SELECT MIN([pl].[id]) FROM @ProcList AS [pl] WHERE [pl].[id] > @ID
        );
    END;
