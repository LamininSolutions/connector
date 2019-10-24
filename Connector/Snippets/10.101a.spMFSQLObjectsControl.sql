
GO

SET NOCOUNT ON; 
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Setup.spMFSQLObjectsControl';

GO
SET NOCOUNT ON; 


/*

------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific release of Object
------------------------------------------------------------------------------------------------

/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  for updating a specific object
  EXEC setup.spMFSQLObjectsControl 'spMFUpdateConnectorObjects', '2.0.2.6',  2, 1

  select * from setup.MFSQLObjectsControl

  for validation
  EXEC setup.spMFSQLObjectsControl @UpdateFlag = 3
  
  select * from sys.objects
-----------------------------------------------------------------------------------------------*/

-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSQLObjectsControl'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'setup' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [Setup].[spMFSQLObjectsControl]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC Setup.spMFSQLObjectsControl
    (
      @SchemaName NVARCHAR(128) = NULL ,
      @ObjectName NVARCHAR(128) = NULL ,
      @Object_Release VARCHAR(50) = NULL ,
      @UpdateFlag SMALLINT = 1 ,
      @debug SMALLINT = 0
    )

--@Updateflags   2 Update Object; 3 Validate
AS
    DECLARE @Query NVARCHAR(MAX) ,
        @Param NVARCHAR(MAX);
    BEGIN

  
        IF @UpdateFlag = 2
            BEGIN


                SELECT  @Query = N'
MERGE INTO setup.[MFSQLObjectsControl] t

USING (SELECT ''' + @SchemaName + ''' AS [Schema],''' + @ObjectName
                        + ''' AS Name, ''' + @Object_Release
                        + ''' AS Release) s 
ON (t.name = s.name and t.[Schema] = s.[Schema])
WHEN MATCHED THEN 
UPDATE 
SET t.Release = s.Release, t.[Modify_Date] = GETDATE()
WHEN NOT MATCHED BY TARGET THEN 
INSERT ([Schema], [Name],[Release],[Modify_Date])
VALUES
(s.[Schema], s.[name], s.[Release],GETDATE())
;
';
                IF @debug <> 0
                    SELECT  @Query;

                EXEC sp_executesql @Query;

            END;

        IF @UpdateFlag = 3
            BEGIN
                PRINT 'Connector Object Validation';

                DECLARE @ObjectList AS TABLE
                    (
                      [Schema] NVARCHAR(128) ,
                      Name NVARCHAR(128)
                    );

                INSERT  INTO @ObjectList
                        ( [Schema] ,
                          [Name]
                        )
                        
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'MF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'spMF%'
                        UNION ALL
--SELECT s.[name],objects.Name, [objects].[object_id], type, [objects].[modify_date] FROM sys.objects
--INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id] WHERE [objects].[name] like 'tMF%'
--UNION ALL
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%';

                IF @debug > 0
                    BEGIN
                        SELECT  *
                        FROM    @ObjectList AS [ol];
                        SELECT  *
                        FROM    Setup.[MFSQLObjectsControl] AS [moc];
                    END;

                SELECT  ol.[Schema] ,
                        ol.Name ,
                        [mco].[Modify_Date] 'Object has no Release'
                FROM    @ObjectList AS [ol]
                        LEFT JOIN Setup.[MFSQLObjectsControl] AS [mco] ON ol.[Name] = [mco].[Name]
                                                              AND ol.[Schema] = [mco].[Schema]
                WHERE   mco.[Release] IS NULL;


            END;


    END;  


GO

EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'Setup', -- nvarchar(128)
    @ObjectName = N'spMFSQLObjectsControl', -- nvarchar(128)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2, -- smallint
    @debug = 0;
 -- smallint

GO