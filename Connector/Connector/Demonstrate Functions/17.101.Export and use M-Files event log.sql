
/*
Exporting and analysing the M-Files event log

*/

-------------------------------------------------------------
-- Export the event log
-------------------------------------------------------------

EXEC [dbo].[spMFGetMfilesLog] @IsClearMfilesLog = 0 -- bit  select 1 to delete the log in M-Files
                             ,@Debug = 0;

                                                    -- small

-------------------------------------------------------------
-- Review the result
-------------------------------------------------------------

--record of each export in XML format
SELECT *
FROM [dbo].[MFEventLog_OpenXML];

--listing of each exported event
SELECT *
FROM [dbo].[MFilesEvents] AS [mfe];

SELECT MAX(id) FROM [dbo].[MFilesEvents] AS [mfe]
 

-------------------------------------------------------------
-- Analyse the events using XML queries
-------------------------------------------------------------

--show object that is not system objects
SELECT [me].[ID]
      ,[me].[Category]
      ,[me].[CausedByUser]
      ,[me].[TimeStamp] 
      ,[me].[Events].[value]('(/event/data/objectversion/title)[1]', 'varchar(100)')              AS [NameOrTitle]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype/@id)[1]', 'varchar(100)') AS [ObjectType_ID]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)')     AS [ObjectType]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')       AS [Objid]
FROM [dbo].[MFilesEvents] [me]
WHERE [me].[Category] <> 'System';

--show files downloaded
SELECT [me].[ID]
      ,[me].[Category]
      ,[me].[CausedByUser]
      ,[me].[TimeStamp]
      ,[me].[Events].[value]('(/event/data/objectversion/title)[1]', 'varchar(100)')              AS [NameOrTitle]
      ,[me].[Events].[value]('(/event/data/filename)[1]', 'varchar(100)')                         AS [FileName]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype/@id)[1]', 'varchar(100)') AS [ObjectType_ID]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)')     AS [ObjectType]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')       AS [Objid]
FROM [dbo].[MFilesEvents] [me]
WHERE [me].[Category] = 'FileAccess';

-- show public files downloaded
SELECT [me].[ID]
      ,[me].[TimeStamp]   AS [Timestamp]
      ,[me].[Events].[value]('(/event/data/objectversion/title)[1]', 'varchar(100)')          AS [NameOrTitle]
      ,[me].[Events].[value]('(/event/data/filename)[1]', 'varchar(100)')                     AS [FileName]
      ,[me].[Events].[value]('(/event/data/ipaddress)[1]', 'varchar(100)')                    AS [IPAddress]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)') AS [ObjectType]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')   AS [Objid]
      ,[me].[Events].[value]('(/event/data/objectversion/objver/version)[1]', 'varchar(100)') AS [Version]
      ,[me].[Events]
FROM [dbo].[MFilesEvents] [me]
WHERE [me].[Type] = 'File downloaded via public link';

--Performance of a process

;

WITH [cte]
AS (SELECT [me].[ID]
          ,[me].[TimeStamp]
          ,[me].[Events].[value]('(/event/data/objectversion/title)[1]', 'varchar(100)')          AS [NameOrTitle]
          ,[me].[Events].[value]('(/event/data/filename)[1]', 'varchar(100)')                     AS [FileName]
          ,[me].[Events].[value]('(/event/data/ipaddress)[1]', 'varchar(100)')                    AS [IPAddress]
          ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)') AS [ObjectType]
          ,[me].[Events].[value]('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')   AS [Objid]
          ,[me].[Events].[value]('(/event/data/objectversion/objver/version)[1]', 'varchar(100)') AS [Version]
          ,[me].[Events]
    FROM [dbo].[MFilesEvents] [me]
    WHERE [me].[Category] = 'NewObject')
    ,[CTE2]
AS (SELECT [cte].[Objid]
          ,[cte].[NameOrTitle]
          ,LEAD([cte].[TimeStamp]) OVER (ORDER BY [cte].[ID]) [ProcessEnd]
          ,LAG([cte].[TimeStamp]) OVER (ORDER BY [cte].[ID])  [ProcessStart]
    FROM [cte])
SELECT [CTE2].[Objid]
      ,[CTE2].[NameOrTitle]
      ,[CTE2].[ProcessStart]
      ,[CTE2].[ProcessEnd]
	  ,DATEDIFF(MILLISECOND,CONVERT(DATETIME, SUBSTRING([CTE2].[ProcessStart],1,22)),CONVERT(DATETIME, SUBSTRING([CTE2].[ProcessEnd],1,22))) AS Diff
FROM [CTE2];
GO

-- show number of object created in a particular timeframe

WITH [cte]
AS (
SELECT [me].[ID]
          ,CONVERT(DATETIME, SUBSTRING([me].[TimeStamp],1,22)) AS EventDate
          ,[me].[Events].[value]('(/event/data/objectversion/title)[1]', 'varchar(100)')          AS [NameOrTitle]      
          ,[me].[Events].[value]('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)') AS [ObjectType]
          ,[me].[Events].[value]('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')   AS [Objid]
          ,[me].[Events].[value]('(/event/data/objectversion/objver/version)[1]', 'varchar(100)') AS [Version]
    FROM [dbo].[MFilesEvents] [me]
    WHERE [me].[Category] = 'NewObject'
	)
   SELECT ObjectType, MIN(EventDate) AS fromDate ,MAX(Eventdate) AS ToDate, COUNT(*) AS RecCount FROM [cte]
--   WHERE EventDate BETWEEN 
   GROUP BY ObjectType
