
/*
Script to update / set MFSettings 

MODIFIED
2917-6-15	AC	Add script to set default CSS for mail
2017-7-16	LC	Add script to update profile security
2018-9-27	LC	Update logic for mail profile and fix bug with incorrect variable
2019-1-26	LC	Prevent default profile to be created if profile already exists
2019-11-18  LC  remove setting the profile as default.  Companies may set another email as default
*/

SET NOCOUNT ON 
DECLARE @msg AS VARCHAR(250);
    DECLARE @EDIT_MAILPROFILE_PROP NVARCHAR(100) 

SET @msg = SPACE(5) + DB_NAME() + ': Update Profile';
RAISERROR('%s', 10, 1, @msg);

-- update mail profile security to include App User to allow for email to be sent using Context Menu

--SELECT * FROM [dbo].[MFSettings] AS [ms]
DECLARE @DBUser VARCHAR(100),
        @profile VARCHAR(100),
        @IsDefault BIT;
SELECT @DBUser = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'AppUser';

SELECT @EDIT_MAILPROFILE_PROP = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'SupportEMailProfile';

/*
Create mail profile - only when existing profile does not match settings
*/


IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysmail_account a) 
BEGIN
  
  DECLARE @Profiles AS TABLE (profiles NVARCHAR(100))

  

   INSERT INTO @Profiles
   (
       profiles
  
       )
        SELECT p.name
        FROM msdb.dbo.sysmail_profile p

	
		IF (SELECT COUNT(*) FROM @Profiles AS p2 WHERE p2.profiles= '{varEmailProfile}') = 0
		
    BEGIN


        -- Create a Database Mail profile
        EXECUTE msdb.dbo.sysmail_add_profile_sp @profile_name = '{varEmailProfile}',
                                                @description = 'Profile for MFSQLConnector.';
	
    END;

END;

/*

SELECT @IsDefault = sp.is_default
FROM msdb.dbo.sysmail_principalprofile AS sp
    LEFT JOIN msdb.sys.database_principals AS dp
        ON sp.principal_sid = dp.sid
WHERE dp.name = @DBUser;


IF @IsDefault = 0
BEGIN
    EXECUTE msdb.dbo.sysmail_add_principalprofile_sp @principal_name = @DBUser,
                                                     @profile_name = @profile,
                                                     @is_default = 1;
END;
*/
/*

Set Default Email CSS 
*/

SET NOCOUNT ON;

--DELETE [dbo].[MFSettings] WHERE name = 'DefaultEMailCSS'
DECLARE @DBName AS NVARCHAR(100),
        @EmailStyle AS VARCHAR(8000);

SELECT @DBName = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'App_Database';

IF DB_NAME() = @DBName
BEGIN
    SET @msg = SPACE(5) + DB_NAME() + ': MFSettings - Set Email Styling ';
    RAISERROR('%s', 10, 1, @msg);

    BEGIN
        SET NOCOUNT ON;

        SET @EmailStyle
            = N'
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<style type="text/css">
		div {line-height: 100%;}  
		body {-webkit-text-size-adjust:none;-ms-text-size-adjust:none;margin:0;padding:0;} 
		body, #body_style {min-height:1000px;font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;}
		p {margin:0; padding:0; margin-bottom:0;}
		h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}  
		table {		   border-collapse: collapse;
  						border: 1px solid #3399FF;
  						font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
  						color: black;
						padding:5;
						border-spacing:1;
						border:0;
					}
		table caption {font-weight: bold;color: blue;}
		table td, table th, table tr,table caption { border: 1px solid #eaeaea;border-collapse:collapse;vertical-align: top; }
		table th {font-weight: bold;font-variant: small-caps;background-color: blue;color: white;vertical-align: bottom;}
	</style>
</head>';


        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.MFSettings
            WHERE source_key = 'Email'
                  AND Name = 'DefaultEMailCSS'
        )
            INSERT dbo.MFSettings
            (
                source_key,
                Name,
                Description,
                Value,
                Enabled
            )
            VALUES
            (   N'Email',                                  -- source_key - nvarchar(20)
                'DefaultEMailCSS',                         -- Name - varchar(50)
                'CSS Style sheet used in email messaging', -- Description - varchar(500)
                @EmailStyle,                               -- Value - sql_variant
                1                                          -- Enabled - bit
                );


        SET NOCOUNT OFF;
    END;



END;

ELSE
BEGIN
    SET @msg = SPACE(5) + DB_NAME() + ': 30.902 script error';
    RAISERROR('%s', 10, 1, @msg);
END;

GO
