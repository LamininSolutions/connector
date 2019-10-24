


/*
Setup MFSQL Connector for reporting

The following will be automatically executed in sequence

test Connection
Update Metadata structure
create class tables
create all related lookups
create menu items in Context menu

on completion login to vault and action update reporting data to update class tables from M-Files to SQL
*/

--Excecute installation proc. Include all the classes to included in reporting as a comma delimited list.

EXEC [spMFSetup_Reporting] @Classes = 'Customer, Drawing' 
                                ,@Debug = 0   -- int


				