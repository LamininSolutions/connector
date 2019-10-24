The setup of the SQL script publisher include the following depended files:

SQLPublisher.ps1 - this is the main App. Right click and run with powershell or use SQLPublishScripts_AppName.bat file to setup and run the app
\XML\Sample_Setup.xml - this file contains the setup for automatic processing of the publishing.  If the file specified in the run parameters does not exist, then a empty XML will be created to start off the configuration.  Use the XML to setup all the parameters for the publishing.
Each group of files to be published requires a XML.  
 
xxx.ini - these are ini files with a list of scripts to be processed. The folder for the INI files are specified in the XML.

To setup:
Open xml file:
Update header information (source & Application) - this is for information only
Version: a sub folder will be created for the version. The text of the version will be added to the end of published files.

For each folder to be included in processes
Create/Update an element 'ScriptFolder' setting the name of the folder (without a '\')
Setting UseFolderINI to False will automatically result in all the sql files in the folder to be included in the published script in sort order. DO NOT include the extension (e.g. ini)
If UserFolderINI is set to True then also provide the name of the ini file containing the listing of the scripts to be included as the FolderINI. DO NOT include the extension (e.g. ini)
Provide the name of the ini file containing the list of hotfix files if applicable. 

Update the basefolders to set the application folder structure.
ScriptRootFolder must include the full path, including the drive letter.  This is the root folder containing all the sub folders to be included in the scripting.
INIFolder is where all the ini files are saved related to the specific XML.  Use a subfolder of the base folder
PublishToFolder is the sub folder where the published files will be placed.  Note that it will have a futher subfolder for each version.  the version sub folder is automatically created.

Update to Procedures to dynamically compile a procedure from a list of snippets. The procedure will be added to a destination folder which in turn will be included in the main publishing process.
Compiling the procedure will run prior to publishing
Name = folder name for the snippets
ProcedureFilename = name of destination procedure file
DestinationFolder = folder for the procedure from where it can be included in the publishing
UseFolderINI = set to True to include compiling the procedure
FolderINI = is the ini to set the sequence of the snippets to be included 





