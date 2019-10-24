


/*
Create mail profile
*/


DECLARE @Result_Message NVARCHAR(200)

IF EXISTS (	  SELECT 1
			  FROM	 [msdb].[dbo].[sysmail_account] [a]
		  )
	BEGIN
		SET @Result_Message = 'Database Mail Installed'

		DECLARE @mailprofile sysname = '{varEmailProfile}'
		IF NOT EXISTS (	  SELECT [p].[name]
						  FROM	 [msdb].[dbo].[sysmail_account] [a]
						  INNER JOIN [msdb].[dbo].[sysmail_profileaccount] [pa] ON [a].[account_id] = [pa].[account_id]
						  INNER JOIN [msdb].[dbo].[sysmail_profile] [p] ON [pa].[profile_id] = [p].[profile_id]
						  WHERE	 [p].[name] = @mailprofile
					  )
			BEGIN

				-- Create a Database Mail profile
				EXECUTE [msdb].[dbo].[sysmail_add_profile_sp] @profile_name = @mailprofile
															, @description = 'Profile for MFSQLConnector.';

			END

	END
ELSE
	BEGIN

		SET @Result_Message = 'Database Mail is not installed on the SQL Server'
	END

SELECT @Result_Message AS [Result_Message]


GO


