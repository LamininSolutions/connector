




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
(@MFilesVersion NVARCHAR(100) = NULL
,@Debug INT = 0
)
    
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

Update assemblies when M-Files version changes

Additional Info
===============

This procedure is compiled during installation. The procedure can only be used in the specific database.

Use the @MFilesVersion parameter to reset the MFVersion in MFSettings.  This allows for using this procedure to fix an erroneous version in the MFSettings table

It will use the MFversion in the MFsettings table to drop all CLR procedures, reload all the CLR assemblies, and reload all the CLR Procedures

Examples
========

To update the assemblies based on the MFVersion in MFSettings

.. code:: sql

    Exec spMFUpdateAssemblies

------

To update the assemblies with a different MFVersion or manually update the assemblies

.. code:: sql

    Exec spMFUpdateAssemblies @MFilesVersion = '19.8.8082.5'

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-10-07  LC         add spMFGetFilesInternal, spMFGetHistory
2021-04-01  LC         Get master db owner and set DB to default owner
2020-11-10  LC         test that all the clr procedures have been dropped
2020-11-10  LC         prevent assemblies to be deleted 
2020-10-27  LC         Refine error messages and logging
2019-09-27  LC         Add MFilesVersion parameter with default
2019-01-11  LC         IF version in mfsettings is different from installer then use installer add parameter to set MFVersion
2019-01-09	LC         Add additional controls to validate MFversion, exist when not exist.
2018-09-27  LC         Add control to check and update M-Files version. This is to allow for the CLR script to be able to be executed without running the app.
2017-07-25  LC	       ADD SETTING TO SET OWNER TO SA
2017-05-04  DevTeam2   Added new parameter DeleteWithDestroy
2016-09-26  DevTeam2   Removed vault settings parameters and pass them as comma separated string in VaultSettings parameter.
2016-03-10  LC         Created
==========  =========  ========================================================

**rST*************************************************************************/

Begin Try