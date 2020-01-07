GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFLogTableStats]';
GO
SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFLogTableStats', -- nvarchar(100)
    @Object_Release = '3.1.1.36', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Listing of log Table stats
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFLogTableStats]  


  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFLogTableStats'--name of procedure
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
CREATE PROCEDURE spMFLogTableStats
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER  PROC spMFLogTableStats
AS


Begin

create table #TableSize (
Name varchar(255),
[rows] int,
reserved varchar(255),
data varchar(255),
index_size varchar(255),
unused varchar(255))

create table #ConvertedSizes (
Name varchar(255),
[rows] int,
reservedKb int,
dataKb int,
reservedIndexSize int,
reservedUnused int,
earliestDate datetime)


insert into #TableSize
EXEC sp_spaceused 'MFAuditHistory'
insert into #TableSize
EXEC sp_spaceused 'MFUpdateHistory'
insert into #TableSize
EXEC sp_spaceused 'MFLog'
insert into #TableSize
EXEC sp_spaceused  'MFProcessBatch'
insert into #TableSize
EXEC sp_spaceused 'MFProcessBatchDetail' 

insert into #ConvertedSizes (Name, [rows], reservedKb, dataKb, reservedIndexSize, reservedUnused)
select name, [rows],
SUBSTRING(reserved, 0, LEN(reserved)-2),
SUBSTRING(data, 0, LEN(data)-2),
SUBSTRING(index_size, 0, LEN(index_size)-2),
SUBSTRING(unused, 0, LEN(unused)-2)
from #TableSize


UPDATE #ConvertedSizes
SET earliestDate = (
SELECT  MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah])
WHERE NAME = 'MFAuditHistory'

UPDATE #ConvertedSizes
SET earliestDate = (
SELECT  MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah])
WHERE NAME = 'MFUpdateHistory'

UPDATE #ConvertedSizes
SET earliestDate = (
SELECT  MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah])
WHERE NAME = 'MFLog'

UPDATE #ConvertedSizes
SET earliestDate = (
SELECT  MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah])
WHERE NAME = 'MFProcessBatch' 

UPDATE #ConvertedSizes
SET earliestDate = (
SELECT  MIN([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah])
WHERE NAME = 'MFProcessBatchDetail' 

select * from #ConvertedSizes
order by reservedKb desc

drop table #TableSize
drop table #ConvertedSizes

END

GO
