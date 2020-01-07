




PRINT space(10) + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateAssemblies]'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFUpdateAssemblies', -- nvarchar(100)
    @Object_Release = '4.4.13.53', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux
	
	Description:  
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
  {An example of how the code would be used}
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFUpdateAssemblies'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    SET NOEXEC ON
GO
	PRINT SPACE(10) + '...creating a stub'
GO
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateAssemblies]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO
ALTER PROC [dbo].[spMFUpdateAssemblies]
(@MFilesVersion NVARCHAR(100) = null)
    
AS 


/*rST**************************************************************************

====================
spMFUpdateAssemblies
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFilesVersion 
    - Default is null
    - if the @MFilesVersion is null, it will use the value in MFSettings, else it will reset MFSettings with the value
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Update assemblies when version changes

Additional Info
===============

This procedure is compiled during installation with inserts relating the to specific database

Use the @MFilesVersion parameter to reset the MFVersion in MFSettings.  This allows for using this procedure to fix an erroneous version in the MFSettings Table

It will use the MFversion in the MFsettings table to drop all CLR procedures, reload all the CLR assemblies, and reload all the CLR Procedures

Examples
========

.. code:: sql

    To update the assemblies based on the MFVersion in MFSettings
    Exec spMFUpdateAssemblies

    To update the assemblies with a different MFVersion

.. code:: sql

    Exec spMFUpdateAssemblies @MFilesVersion '19.8.8082.5'

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-27  LC         Add MFilesVersion parameter with default
2019-03-10  LC         Created
==========  =========  ========================================================

**rST*************************************************************************/

Begin Try