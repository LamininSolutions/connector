SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Description: MFSQLObjectsColtrol have a listing of all the objects included in the MFSQL Connector
	 as standard application objects and the release version of the specific object
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from setup.MFSQLObjectsControl
  
-----------------------------------------------------------------------------------------------*/
--DROP TABLE settings

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[setup].[MFSQLObjectsControl]';

GO

/*
CREATE TABLE IF NOT EXIST
*/
IF NOT EXISTS ( SELECT  object_id
                FROM    sys.objects
				INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                WHERE   objects.name = 'MFSQLObjectsControl' AND s.name = 'setup' )
    BEGIN

        CREATE TABLE Setup.MFSQLObjectsControl
            (
              id INT IDENTITY ,
              [Schema] VARCHAR(100) ,
              Name VARCHAR(100) NOT NULL ,
              [object_id] INT NULL ,
              Release VARCHAR(50) NULL ,
              [Type] VARCHAR(10) NULL ,
              Modify_Date DATETIME NULL
                                   DEFAULT GETDATE()
            );

        PRINT SPACE(10) + '... Table: created';

        IF NOT EXISTS ( SELECT  object_id
                        FROM    sys.indexes
                        WHERE   name = N'idx_MFSQLObjectsControl_name' )
            BEGIN
                PRINT SPACE(10) + '... Index: idx_MFSQLObjectsControl_name';
                CREATE NONCLUSTERED INDEX idx_MFSQLObjectsControl_name ON Setup.MFSQLObjectsControl(Name);

            END;
    END; 

	   PRINT SPACE(10) + '... MFSQLObjectsControl Initialised';

              TRUNCATE TABLE Setup.[MFSQLObjectsControl];

                INSERT  INTO Setup.[MFSQLObjectsControl]
                        ( [Schema] ,
                          [Name] ,
                          [object_id] ,
                          [Type] ,
                          [Modify_Date]
                        )
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] = 'Process'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] = 'Settings'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'MF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'spMF%'
--UNION ALL
--SELECT s.[name],objects.Name, [objects].[object_id], type, [objects].[modify_date] FROM sys.objects
--INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id] WHERE [objects].[name] like 'tMF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%';



DECLARE @ProcRelease VARCHAR(100) = '2.0.2.7'
IF NOT EXISTS ( SELECT  Name
                FROM    Setup.[MFSQLObjectsControl]
                WHERE   [Schema] = 'setup'
                        AND Name = 'MFSQLObjectsControl' )
    BEGIN
        INSERT  INTO Setup.[MFSQLObjectsControl]
                ( [Schema] ,
                  [Name] ,
                  [object_id] ,
                  [Release] ,
                  [Type] ,
                  [Modify_Date]
                )
        VALUES  ( 'setup' , -- Schema - varchar(100)
                  'spMFSQLObjectsControl' , -- Name - varchar(100)
                  0 , -- object_id - int
                   @ProcRelease, -- Release - varchar(50)
                  'P' , -- Type - varchar(10)
                  GETDATE()  -- Modify_Date - datetime
                );
    END;
ELSE
    BEGIN
        UPDATE  moc
        SET      
                [moc].[Release] = @ProcRelease,
				moc.[Modify_Date] = GETDATE()
     
	    FROM    Setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Schema] = N'setup' and
                [moc].[Name] = N'MFSQLObjectsControl' ;
    END;



	go

