


GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwObjectChangeHistory]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwObjectChangeHistory', -- nvarchar(100)
    @Object_Release = '4.8.24.65', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwObjectChangeHistory'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].MFvwObjectChangeHistory
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
	
ALTER VIEW [dbo].MFvwObjectChangeHistory
AS

/*rST**************************************************************************

=======================
MFvwObjectChangeHistory
=======================

Purpose
=======

To view the changes of an object by property with details of the display value

Examples
========

.. code:: sql

    Select * from MFvwObjectChangeHistory
    ORDER BY TableName, ObjID,
    Property_ID;

----

show the change history for a specific object in a table

.. code:: sql

    Select * from MFvwObjectChangeHistory where TableName = 'MFCustomer' and objid = 134
    ORDER BY Property_ID;
    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-10-13  LC         New view
==========  =========  ========================================================

**rST*************************************************************************/



SELECT mc.TableName,
moch.ObjID,
    mp.Name  AS property,
    mp.MFID  AS Property_ID,
    moch.MFVersion,
    moch.LastModifiedUtc,
    moch.Property_Value,
    CASE
        WHEN mdt.MFTypeID = 9
             AND mp.MFID IN ( 23, 25 ) THEN
        (
            SELECT mua.UserName
            FROM dbo.MFLoginAccount AS mua
            WHERE mua.MFID = moch.Property_Value
        )
        WHEN mdt.MFTypeID = 9
             AND mp.MFID = 38 THEN
        (
            SELECT mua.Name
            FROM dbo.MFWorkflow AS mua
            WHERE mua.MFID = moch.Property_Value
        )
        WHEN mdt.MFTypeID = 9
             AND mp.MFID = 39 THEN
        (
            SELECT mua.Name
            FROM dbo.MFWorkflowState AS mua
            WHERE mua.MFID = moch.Property_Value
        )
        WHEN mdt.MFTypeID = 9
             AND mp.MFID = 100 THEN
        (
            SELECT mua.Name
            FROM dbo.MFClass AS mua
            WHERE mua.MFID = moch.Property_Value
        )
        WHEN mdt.MFTypeID IN ( 9 )
             AND mp.MFID NOT IN ( 23, 25, 38, 39, 100, 101 ) THEN
        (
            SELECT mua.Name
            FROM dbo.MFValueListItems      AS mua
                INNER JOIN dbo.MFValueList mvl
                    ON mua.MFValueListID = mvl.ID
            WHERE mua.MFID = moch.Property_Value
                  AND mvl.ID = mp.MFValueList_ID
        )
        WHEN mdt.MFTypeID IN ( 10 )
             AND CHARINDEX(',',moch.Property_Value, 0) = 0 THEN
        (
            SELECT mua.Name
            FROM dbo.MFValueListItems      AS mua
                INNER JOIN dbo.MFValueList mvl
                    ON mua.MFValueListID = mvl.ID
            WHERE mua.MFID = moch.Property_Value
                  AND mvl.ID = mp.MFValueList_ID
        )
        WHEN mdt.MFTypeID = 10 
             AND CHARINDEX(',',moch.Property_Value, 0) > 0 THEN
        (
            SELECT STUFF((SELECT '; ' + mua.Name
            FROM dbo.fnMFParseDelimitedString(moch.Property_Value, ',') AS fmpds
                INNER JOIN dbo.MFValueListItems                         AS mua
                    ON fmpds.ListItem = mua.MFID
                INNER JOIN dbo.MFValueList                              mvl
                    ON mua.MFValueListID = mvl.ID
            WHERE mua.MFID = fmpds.ListItem
                  AND mvl.ID = mp.MFValueList_ID
            FOR XML PATH('')),1,1,'')
        )
        ELSE
            moch.Property_Value
    END      Display_value,
    mdt.Name AS datattype,
    mdt.MFTypeID
FROM dbo.MFObjectChangeHistory AS moch
    INNER JOIN dbo.MFClass     AS mc
        ON moch.Class_ID = mc.MFID
    INNER JOIN dbo.MFProperty  AS mp
        ON moch.Property_ID = mp.MFID
    INNER JOIN dbo.MFDataType  AS mdt
        ON mp.MFDataType_ID = mdt.ID
;

GO

