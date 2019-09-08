SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFVariableTableName]';
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'fnMFVariableTableName', -- nvarchar(100)
                                 @Object_Release = '3.1.5.41',            -- varchar(50)
                                 @UpdateFlag = 2;                        -- smallint
GO

/*
MODIFICATIONS
2018-02-28	lc	Include an alternative method of setting the file name based on unique identifyer. this is controlled by using a flag.
*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'fnMFVariableTableName' --name of procedire
          AND ROUTINE_TYPE = 'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    DROP FUNCTION dbo.fnMFVariableTableName;
END;
GO


-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2016-05-15
-- Description:	Create Unique Table Name
-- =============================================
/*
	Sample:
	SELECT  [dbo].[fnMFVariableTableName]( 'tmpTest','1')
*/
-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2016-05-15
-- Description:	Create Unique Table Name
-- =============================================
CREATE FUNCTION fnMFVariableTableName
(
    -- Add the parameters for the function here
    @TablePrefix NVARCHAR(100),
    @TableSuffix NVARCHAR(20) = NULL
)
RETURNS NVARCHAR(100)
AS
/*rST**************************************************************************

=====================
fnMFVariableTableName
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TablePrefix nvarchar(100)
    fixme description
  @TableSuffix nvarchar(20)
    fixme description


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    -- Declare the return variable here
    DECLARE @TableName NVARCHAR(100);

    DECLARE @Flag BIT = 1;

    -- Add the T-SQL statements to compute the return value here

    -- Variable that will contain the name of the table

    IF @Flag = 0
    BEGIN
        SELECT @TableName = @TablePrefix + '_' + ISNULL(@TableSuffix, CONVERT(CHAR(12), GETDATE(), 14));

        -- Table cannot be created with the character  ":"  in it
        -- The following while loop strips off the colon
        DECLARE @pos INT;
        SELECT @pos = CHARINDEX(':', @TableName);

        WHILE @pos > 0
        BEGIN
            SELECT @TableName = SUBSTRING(@TableName, 1, @pos - 1) + SUBSTRING(@TableName, @pos + 1, 30 - @pos);
            SELECT @pos = CHARINDEX(':', @TableName);
        END;
    END;


    IF @Flag = 1
    BEGIN
        DECLARE @TableGUID UNIQUEIDENTIFIER;


        SELECT @TableGUID = new_id
        FROM dbo.MFvwTableID;

		SELECT @TableSuffix = REPLACE(CAST(@TableGUID AS VARCHAR(50)),'-','')

        SELECT @TableName = @TablePrefix + '_' + @TableSuffix ;
    END;

    -- Return the result of the function
    RETURN @TableName;

END;

GO
