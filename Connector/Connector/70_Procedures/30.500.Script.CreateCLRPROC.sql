
--THIS COLLECTION OF PROCEDURES CREATE ALL THE CLR PROCEDURES

/*
MODIFICATIONS TO COLLECTION
version 3.1.2.38 ADD spMFGetFilesInternal
version 3.1.2.38 ADD spMFGetHistory
version 3.1.5.41 ADD spMFSynchronizeFileToMFilesInternal

*/
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
    2017-05-04      DevTeam2    Added new parameter @DeleteWithDestroy

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDeleteObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFDeleteObjectInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFDeleteObjectInternal]
    @VaultSettings NVARCHAR(4000) ,
    @ObjectTypeId INT ,
    @objectId INT ,	
	@DeleteWithDestroy bit,
	@ObjectVersion INT,
    @Output NVARCHAR(2000) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[DeleteObject];
')



-- -------------------------------------------------------- 
-- sp.spMFEncrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFEncrypt]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFEncrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFEncrypt'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFEncrypt]
		
    END;
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFEncrypt]
@Password NVARCHAR (2000), @EcryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Encrypt]
')

  
 
-- -------------------------------------------------------- 
-- sp.spMFGetClass.sql 
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetClass]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFGetClass', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault setting parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetClass'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetClass];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX) OUTPUT ,
    @ClassPptXML NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFClasses];
	')








  
 
-- -------------------------------------------------------- 
-- sp.spMFGetLoginAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetLoginAccounts]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetLoginAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameters.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetLoginAccounts'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetLoginAccounts];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetLoginAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLoginAccounts];
	');





  
 
-- -------------------------------------------------------- 
-- sp.spMFGetDataExportInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetDataExportInternal]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDataExportInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetDataExportInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetDataExportInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetDataExportInternal]
    @VaultSettings NVARCHAR(4000) ,
    @ExportDatasetName NVARCHAR(2000) ,
    @IsExported BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ExportDataSet];
');








  
 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectType.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectType]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		        DESCRIPTION
	YYYY-MM-DD		{Author}	       {Comment}
	2016-09-26      DevTeam2(Rheal)    Removed Vault settings parametes and passed them as comma
									   separated string single parameter @VaultSettings
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetObjectType'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetObjectType];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetObjectTypes];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectVersInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectVersInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectVersInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: Kishore
	Create date: 2016-6-20
	Database: 
	Description: CLR procedure to get all the object version of the class
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-21      DevTeam2    Remove parameters @Username,@Password,@NetworkAddress,@VaultName and fetch 
			        (Rheal)     these parameters in single parameters as comma separate vaules.

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetObjectVersInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFGetObjectVersInternal]
		
    END;
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetObjectVersInternal]
	@VaultSettings [nvarchar](4000),
	@ClassID [int],
	@dtModifieDateTime [datetime],
	@MFIDs [nvarchar](4000),
	@ObjverXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetOnlyObjectVersions]
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFGetProperty.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetProperty]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings and pass them as comma separated string 
	                            in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetProperty'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetProperty];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetProperty]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetProperties];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetUserAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetUserAccounts]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetUserAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetUserAccounts'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetUserAccounts];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetUserAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetUserAccounts];
');






  
 
-- -------------------------------------------------------- 
-- sp.spMFGetValueList.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueList]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetValueList', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetValueList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetValueList];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
 EXEC (N'    
CREATE PROCEDURE [dbo].[spMFGetValueList]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueLists];
');










  
 
-- -------------------------------------------------------- 
-- sp.spMFGetValueListItems.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueListItems]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetValueListItems', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-26-09      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetValueListItems'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetValueListItems];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetValueListItems]
    @VaultSettings NVARCHAR(4000) ,
    @valueListId NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueListItems];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlow.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlow]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlow'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlow];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
    

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFWorkflow];
');










  
 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlowState]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated 
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlowState];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];

');

  
 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectByPropertyValuesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectByPropertyValuesInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObjectByPropertyValuesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated string in
	                            @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSearchForObjectByPropertyValuesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSearchForObjectByPropertyValuesInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFSearchForObjectByPropertyValuesInternal]
    @VaultSettings NVARCHAR(2000) ,
    @ClassId INT ,
    @PropertyIDs NVARCHAR(2000) ,
    @PropertyValues NVARCHAR(2000) ,
    @Count INT ,
	@isEqual INT,
    @ResultXml NVARCHAR(MAX) OUTPUT ,
    @isFound BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SearchForObjectByProperties];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectInternal]';


SET NOCOUNT on
  EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSearchForObjectInternal', -- nvarchar(100)
      @Object_Release = '2.1.1.0', -- varchar(50)
      @UpdateFlag = 2 -- smallint

 ;

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26     DevTeam2    Removed vault settings parameters and pass them as comma separated
	                           string in @VaultSettings parameters.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSearchForObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFSearchForObjectInternal]
		
    END;
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFSearchForObjectInternal]
	@VaultSettings [NVARCHAR](4000),
	@ClassId [INT],
	@SearchText [NVARCHAR](2000),
	@Count [INT],
	@ResultXml [NVARCHAR](MAX) OUTPUT,
	@isFound [BIT] OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SearchForObject]
 '); 
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateClass.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateClass]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateClass', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update class alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateClass'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateClass];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateClass';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateClassAliasInMFiles];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateProperty.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateProperty]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update property alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateProperty'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateProperty];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateProperty';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateProperty]
    @VaultSettings NVARCHAR(4000) ,
    @PropXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdatePropertyAliasInMFiles];
');



  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateObjectType.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateObjectType]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update objecttype alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateObjectType'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateObjectType];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateObjectType';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateObjectTypeAliasInMFiles];
');




  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdatevalueList.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdatevalueList]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdatevalueList', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update objecttype alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdatevalueList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdatevalueList];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdatevalueList';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdatevalueList]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateValueListAliasInMFiles];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlow.sql 
-- -------------------------------------------------------- 



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlow]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateWorkFlow'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateWorkFlow];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateWorkFlow';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtAliasInMFiles];
');

  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlowState]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateWorkFlowState];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtStateAliasInMFiles];
');









PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())  + '.[dbo].[spMFGetWorkFlowState]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated 
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlowState];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];
');






  
 
-- -------------------------------------------------------- 
-- sp.spMFCreateObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreateObjectInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateObjectInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	20016-09-21     DevTeam2    Removed @Username, @Password, @NetworkAddress and @VaultName and
	                Rheal       fetch this vault settings from dbo.FnMFVaultSettings() as comma 
					            separate string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCreateObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFCreateObjectInternal]
		
    END;
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
 EXEC (N'    
CREATE PROCEDURE [dbo].[spMFCreateObjectInternal]
	@VaultSettings [nvarchar](4000),
	@XmlFile [nvarchar](max),
	@objVerXmlIn [nvarchar](max),
	@MFIDs [nvarchar](2000),
	@UpdateMethod [int],
	@dtModifieDateTime [datetime],
	@sLsOfID [nvarchar](max),
	@ObjVerXmlOut [nvarchar](max) OUTPUT,
	@NewObjectXml [nvarchar](max) OUTPUT,
	@SynchErrorObjects [nvarchar](max) OUTPUT,
	@DeletedObjVerXML [nvarchar](max) OUTPUT,
	@ErrorXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[CreateNewObject]
');



    
 
-- -------------------------------------------------------- 
-- sp.spMFGetMFilesVersionInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spmfGetMFilesVersionInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spmfGetMFilesVersionInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfGetMFilesVersionInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spmfGetMFilesVersionInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spmfGetMFilesVersionInternal';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spmfGetMFilesVersionInternal]
    @VaultSettings NVARCHAR(4000) ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesVersion];
');
  
 
-- -------------------------------------------------------- 
-- sp.spMFDecrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFDecrypt]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFDecrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDecrypt'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFDecrypt]
		
    END;
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
     


EXEC (N'
CREATE PROCEDURE [dbo].[spMFDecrypt]
@EncryptedPassword NVARCHAR (2000), @DecryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Decrypt]
');
  
 
-- -------------------------------------------------------- 
-- sp.spMFSynchronizeValueListItemsToMFilesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeValueListItemsToMFilesInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSynchronizeValueListItemsToMFilesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2016-10
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueListItemsToMFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSynchronizeValueListItemsToMFilesInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


EXEC (N'
Create Procedure dbo.spMFSynchronizeValueListItemsToMFilesInternal
@VaultSettings [nvarchar](4000),
@XmlFile [nvarchar](max),
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SynchValueListItems]
');



-- -------------------------------------------------------- 
-- sp.spMFCreatePublicSharedLinkInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreatePublicSharedLinkInternal]';

  
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFCreatePublicSharedLinkInternal', -- nvarchar(100)
    @Object_Release = '3.1.1.34', -- varchar(50)
    @UpdateFlag = 2 -- smallint


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCreatePublicSharedLinkInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFCreatePublicSharedLinkInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFCreatePublicSharedLinkInternal]
    @VaultSettings NVARCHAR(max) ,
    @XML nvarchar(max) ,
    @OutputXml NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetPublicSharedLink];
');




-- -------------------------------------------------------- 
-- sp.spMFGetMFilesLogInternal
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMFilesLogInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetMFilesLogInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2017-01
	Database: 
	Description: CLR procedure to Get M-Files Log
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMFilesLogInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetMFilesLogInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


EXEC (N'
Create Procedure dbo.spMFGetMFilesLogInternal
@VaultSettings [nvarchar](4000),
@IsClearMFileLog bit,
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesEventLog]
');

-- -------------------------------------------------------- 
-- sp.spMFGetMFilesLogInternal
-- --------------------------------------------------------   


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetFilesInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetFilesInternal', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2017-07
	Database: 
	Description: CLR procedure to Get M-Files files
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetFilesInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


EXEC (N'
Create Procedure dbo.spMFGetFilesInternal
@VaultSettings [nvarchar](4000) ,
@ClassID nvarchar(10),
@ObjID nvarchar(20),
@ObjType nvarchar(10),
@ObjVersion nvarchar(10),
@FilePath nvarchar(max),
@IncludeDocID nvarchar(4),
@FileExport  nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetFiles]
');



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetHistoryInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetHistoryInternal', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetHistoryInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetHistoryInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
Create Procedure dbo.spMFGetHistoryInternal  
@VaultSettings [nvarchar](4000) ,
@ObjectType  nvarchar(10),
@ObjIDs nvarchar(max),
@PropertyIDs  nvarchar(4000),
@SearchString nvarchar(4000),
@IsFullHistory  nvarchar(4),
@NumberOfDays   nvarchar(4),
@StartDate   nvarchar(20),
@Result nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetHistory]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeFileToMFilesInternal]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeFileToMFilesInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.42', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Import blob file into M-files
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeFileToMFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSynchronizeFileToMFilesInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	
EXEC (N'	 
Create Procedure dbo.spMFSynchronizeFileToMFilesInternal  
@VaultSettings [nvarchar](4000) ,
@FileName  nvarchar(MAX),
@XMLFile nvarchar(MAX),
@FilePath nvarchar(MAX),
@Result nvarchar(max) Output,
@ErrorMsg nvarchar(max) Output,
@IsFileDelete INT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[Importfile]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFValidateModule]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFValidateModule', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Validate module and license
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFValidateModule'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFValidateModule];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'	 
CREATE PROCEDURE [dbo].[spMFValidateModule]
	@VaultSettings [nvarchar](2000),
	@ModuleID [nvarchar](20),
	@Status [nvarchar](20) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ValidateModule]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMetadataStructureVersionIDInternal]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMetadataStructureVersionIDInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Get latest Metadata structure version ID
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMetadataStructureVersionIDInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetMetadataStructureVersionIDInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
EXEC (N'	 
CREATE PROCEDURE [dbo].[spMFGetMetadataStructureVersionIDInternal]
	@VaultSettings [nvarchar](4000),
	@Result nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMetadataStructureVersionID]
');



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetUnManagedObjectDetails', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: ,DevTeam2 Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Get UnManaged object Details
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetUnManagedObjectDetails'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetUnManagedObjectDetails];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetUnManagedObjectDetails]
	@ExternalRepositoryObjectID [NVARCHAR](MAX),
	@VaultSettings [nvarchar](4000),
	@Result [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetUnManagedObjectDetails]
');



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDeletedObjectsInternal', -- nvarchar(100)
    @Object_Release = '4.3.10.49', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: ,DevTeam2 Laminin Solutions
	Create date: 2019-07
	Database: 
	Description: CLR procedure to Get deleted object Details
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetDeletedObjectsInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetDeletedObjectsInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetDeletedObjectsInternal]
	@VaultSettings [nvarchar](4000),
	@ClassID [int],
	@LastModifiedDate [DateTime],
	@outputXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetDeletedObjects]
');







