
/*
Run this script once as the first step
*/

IF 
			 EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFModule'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

DROP TABLE MFModule

END


IF 
			 EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLicenseModule'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

DROP TABLE MFLicenseModule

END

