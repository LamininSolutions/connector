

GO

/*
Create mail profile result

{varAppDB}						DatabaseName (new or existing)
{varEmailProfile}
*/

USE {varAppDB}

GO


declare @Result_Message nvarchar(200);

declare @EDIT_MAILPROFILE_PROP nvarchar(128);

set @EDIT_MAILPROFILE_PROP = '{varEmailProfile}';

if exists (select 1 from [msdb].[dbo].[sysmail_account] as [a])
begin
    set @Result_Message = 'Database Mail Installed';


    if not exists
    (
        select [p].[name]
        from [msdb].[dbo].[sysmail_account]                  as [a]
            inner join [msdb].[dbo].[sysmail_profileaccount] as [pa]
                on [a].[account_id] = [pa].[account_id]
            inner join [msdb].[dbo].[sysmail_profile]        as [p]
                on [pa].[profile_id] = [p].[profile_id]
        where [p].[name] = @EDIT_MAILPROFILE_PROP
    )
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
