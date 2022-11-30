
/*
Script to drop all the CLR tables 
Execute before updating Assemblies
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
    DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFUpdateAssemblies';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';  

    
        SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'drop all the CLR tables  ';

         IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



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
