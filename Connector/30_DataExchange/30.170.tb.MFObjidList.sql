

/*rST**************************************************************************

===========
MFObjidList
===========

Description
===========

MFObjidlist is a serialised list of objids used in spmfUpdateMFilestoMFSQL

Columns
=======

Objid int (primarykey, not null)

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-01-25  LC         Table designed
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFObjidList]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjidList', -- nvarchar(100)
    @Object_Release = '4.9.28.73', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
Table is used for a serialised list of ids
*/

IF EXISTS (SELECT name FROM sys.tables WHERE name='MFObjidList' AND SCHEMA_NAME(schema_id)='dbo')
Begin
DROP TABLE MFObjidList;
END

Begin

	PRINT SPACE(10) + '... Table: created and populated'

    SET NOCOUNT ON;

   CREATE TABLE MFObjidList
   (objid INT)
CREATE unique INDEX idx_MFObjidlist ON MFObjidlist(Objid);

  IF
                            (
                                SELECT OBJECT_ID('tempdb..#list')
                            ) IS NOT NULL
                                DROP TABLE #list;

                                ;

                            WITH x1
                                AS (SELECT TOP 2000
                                           object_id
                                    FROM sys.all_columns)
                            
                            SELECT id = IDENTITY(INT, 1, 1)
                            INTO #list
                            FROM x1 a,
                                 x1 b;

                          INSERT INTO MFObjidList
                          (objid)
                          SELECT id FROM #list AS l

END

GO

