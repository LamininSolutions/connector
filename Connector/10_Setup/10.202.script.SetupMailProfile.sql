

GO

/*
Create mail profile result
select * from mfsettings

{varAppDB}						DatabaseName (new or existing)
{varEmailProfile}
*/

USE [{varAppDB}]

GO


declare @Result_Message nvarchar(200);

declare @EDIT_MAILPROFILE_PROP nvarchar(128);

Select @EDIT_MAILPROFILE_PROP = CAST(ISNULL(value,'{varEmailProfile}') AS NVARCHAR(100)) FROM mfsettings WHERE name = 'SupportEMailProfile';

if exists (select 1 from [msdb].[dbo].[sysmail_account] as [a])
begin
    set @Result_Message = 'Database Mail Installed';
    

  
  IF 
    (
        select count(*)
        from [msdb].[dbo].[sysmail_account]                  as [a]
            inner join [msdb].[dbo].[sysmail_profileaccount] as [pa]
                on [a].[account_id] = [pa].[account_id]
            inner join [msdb].[dbo].[sysmail_profile]        as [p]
                on [pa].[profile_id] = [p].[profile_id]
    ) = 0
    begin

        -- Create a Database Mail profile
        execute [msdb].[dbo].[sysmail_add_profile_sp] @profile_name = @EDIT_MAILPROFILE_PROP
                                                    , @description = 'Profile for MFSQLConnector.';

    end;

end;
else
begin

    set @Result_Message = 'Database Mail is not installed on the SQL Server';
end;

GO
