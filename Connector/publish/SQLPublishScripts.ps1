

Param([parameter(Mandatory=$true)][string]$SetupXML,[bool]$IsDetailLogging = $False)

#powershell will combine all the sql scripts in the folders set in the $dirList into a single file
#per folder and save it into the folder publishToFolder + nameVersion using the naming
#of dirList item + nameVersion as the name of the file

#check if setup file provided

If ($SetupXML -eq $null)
{ write-host 'Invalid file parapmeter'
exit}
write ("############################################################")
write ("Setup file : {0}" -f $SetupXML)

# region Include required library files
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {	
    . ("$ScriptDirectory\Publishing_Functions.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    get-location
    exit
}
#endregion

#region setup all other parameters from settings files
Try {
$AppPath = Get-RootPath 
write ("Root path : {0}" -f $AppPath)

$Filename = Get-SetupFilePath $AppPath $SetupXML 
write ("Setup File location : {0}" -f $Filename)
}
Catch
{ Write-Host "Unable to find XML"
exit
}

##setup application settings
$ApplicationSettings = Get-ApplicationSettings $Filename

##Start logging
$Logging = Get-LoggingFolders $AppPath $ApplicationSettings.LogFolder 
$ErrorLog = $Logging[0]
$ProcessLog = $Logging[1]

#$Add folders

$PublishPath = add-customfolder $AppPath $ApplicationSettings.publishToFolder
$PublishPathVersion = add-customfolder $AppPath ($ApplicationSettings.publishToFolder + "\" + $ApplicationSettings.nameVersion)
$INIFolderPath = add-customfolder $AppPath $ApplicationSettings.INIFolder


$FileSourceRoot = $ApplicationSettings.rootFolder

write ("Script file root location : {0}" -f $FileSourceRoot)
write ("Publishing location : {0}" -f $PublishPathVersion)
write ("INI input files location : {0}\{1}" -f ($AppPath,$ApplicationSEttings.INIFolder))
write ("")
 

##compile procedures from scripts

$ProcedureList = Get-ProcFolderSettings $Filename

#Write-Host $filename

invoke-CLRProcCompiler $ProcedureList.Name $AppPath $FileSourceRoot $PublishPath $PublishPathVersion

##create sql scripts from folder list

$Scriptfolders = Get-ScriptFolderSettings $Filename

invoke-scriptcompiler $scriptFolders.Name $AppPath $FileSourceRoot $PublishPath $PublishPathVersion

exit
