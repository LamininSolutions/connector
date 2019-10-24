
GO

/***************************************************************************
IMPORTANT : READ AND PERFORM ACTION BEFORE EXECUTING THE PREPARE SERVER SCRIPT
***************************************************************************/

/*
THIS SCRIPT HAS BEEN PREPARE TO ALLOW FOR THE AUTOMATION OF ALL THE INSTALLATION VARIABLES

2017-3-24-7h30

*/

/*


Find what:						Replace With:
{varAppDB}						DatabaseName (new or existing)
{varAuthType}					Options: SQL or WINDOWS
{varAppLogin_Name}				LoginName (e.g. MFSQLConnect)
{varAppLogin_Password}			Password (e.g. Connector)
{varAppName}					Name of MFSQLManager App (e.g. MFSQLManager)
{varAppDBRole}					AppDBRole (e.g. db_MFSQLConnect)				


*/

USE [master]

GO