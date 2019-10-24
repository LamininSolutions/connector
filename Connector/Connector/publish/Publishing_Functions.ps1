

#Publish Scripts custom functions V2

#region Get root path
Function Get-RootPath()
{
 $RootPath = if ($psISE)
{
   Split-Path -Path $psISE.CurrentFile.FullPath        
}
else
{
 #  Get-Location
 $MyInvocation.PSScriptRoot
#	Split-Path -Path $MyInvocation.MyCommand.Definition 

#    $global:PSScriptRoot
}
return $RootPath 
}
#endregion

#region Setup file name
Function Get-SetupFilePath($RootPath, $SetupXML)
{

$Filename = join-Path -path (join-path -path $RootPath -childpath "XML") -childpath $SetupXML
if ($SetupXML -notlike "*.xml"){
	Write ("XML file name {0} is invalid" -f $SetupXML)
	exit
}
if (!(Test-Path $Filename -PathType Any)) {
	
add-SetupFile $SetupXML $RootPath
    Write-Host "New setup file : $FileName created"
	exit
	}
Return $Filename
}

#endregion

#region add setup file

Function add-SetupFile($Filename,$RootPath)
{


$ApplicationPath = join-Path -Path $MyInvocation.PSScriptRoot -childpath "XML"

$XMLDoc = new-Object System.Xml.XmlDocument

$XMLDoc = [XML]('<SQLPublish/>')
$Def = $XMLDoc.CreateElement('Publish')
$ScriptFolders = $XMLDoc.CreateElement('ScriptFolders')
$BaseFolders = $XMLDoc.CreateElement('BaseFolders')
$ProcFolders = $XMLDoc.CreateElement('Procedures')
$ScriptFolder = $XMLDoc.CreateElement('ScriptFolder')
$ScriptFolder1 = $XMLDoc.CreateElement('ScriptFolder')
$ProcFolder = $XMLDoc.CreateElement('Procedure')
$BaseFolder = $XMLDoc.CreateElement('BaseFolder')
$BaseFolder1 = $XMLDoc.CreateElement('BaseFolder')
$BaseFolder2 = $XMLDoc.CreateElement('BaseFolder')

$ScriptFolders.AppendChild($ScriptFolder) | Out-Null 
$ScriptFolders.AppendChild($ScriptFolder1) | Out-Null 
$BaseFolders.AppendChild($BaseFolder) | Out-Null
$BaseFolders.AppendChild($BaseFolder1) | Out-Null
$BaseFolders.AppendChild($BaseFolder2) | Out-Null
$ProcFolders.AppendChild($ProcFolder) | Out-Null

#$BaseFolders.AppendChild($BaseFolder) | Out-Null 


$Def.SetAttribute("Source","Laminin Solutions")
$Def.SetAttribute("Application","SQLPublishScript")
$Def.SetAttribute("Version","1.0")

$ScriptFolder.SetAttribute("Name","Folder1")
$ScriptFolder.SetAttribute("UseFolderINI","False")
$ScriptFolder.SetAttribute("HotFixINI","Folder1_Hotfix")
$ScriptFolder.SetAttribute("FolderINI","Folder1")

$ScriptFolders.AppendChild($ScriptFolder1) | Out-Null

$ScriptFolder1.SetAttribute("Name","Folder2")
$ScriptFolder1.SetAttribute("UseFolderINI","False")
$ScriptFolder1.SetAttribute("HotFixINI","Folder2_Hotfix")
$ScriptFolder1.SetAttribute("FolderINI","Folder2")

$BaseFolder.SetAttribute("Name","ScriptRootFolder")
$BaseFolder.SetAttribute("Location","E:\Development\TFS\LSApplications\Powershell_Apps\SQLPublishScripts\TestData")
$BaseFolder1.SetAttribute("Name","INIFolder")
$BaseFolder1.SetAttribute("Location","publish")
$BaseFolder2.SetAttribute("Name","PublishToFolder")
$BaseFolder2.SetAttribute("Location","Published")

$ProcFolder.SetAttribute("Name","Proc1")
$ProcFolder.SetAttribute("ProcedureFileName","ProcFile1")
$ProcFolder.SetAttribute("DestinationFolder","Folder1")
$ProcFolder.SetAttribute("UseFolderINI","True")
$ProcFolder.SetAttribute("FolderINI","Proc1")

#>
$XMLDoc.DocumentElement.AppendChild($Def) | Out-Null
$XMLDoc.DocumentElement.AppendChild($ScriptFolders) | Out-Null
$XMLDoc.DocumentElement.AppendChild($BaseFolders) | Out-Null
$XMLDoc.DocumentElement.AppendChild($ProcFolders) | Out-Null

#>

$ApplicationPath
$filePath = join-path -path $ApplicationPath -ChildPath $FileName
#>

$XMLDoc.Save($filePath)

write "New Setup file is created, update setup then run again"

}
#endregion

#region get application settings

Function Get-ApplicationSettings($Filename)
{

[xml]$XmlDocument = $null
[xml]$XmlDocument = Get-Content -Path "$Filename"


$ApplicationSettings = new-Object -TypeName psobject -Property 	@{"Application" = $XmlDocument.FileImporter.Definition.Application;
		"LogFolder" = $XmlDocument.FileImporter.Definition.LogFolder;
		"ApplicationPath" = $XmlDocument.FileImporter.Definition.ApplicationPath;
		"Root" = $XmlDocument.FileImporter.Folders.Folder.Root;
		"ShortName"= $XmlDocument.FileImporter.Folders.Folder.ShortName;
		"Server" = $XmlDocument.FileImporter.TargetDB.Server;
		"Database" = $XmlDocument.FileImporter.TargetDB.Database		 
}

	Return $ApplicationSettings
}
#endregion

#region get logging folders

Function Get-LoggingFolders($RootPath,$LogPath)
{

$AppPath = join-path -path $RootPath -ChildPath $LogPath 
if(-NOT(Test-Path -path "$AppPath" -PathType Container))
{new-Item  -path "$AppPath" -itemType Directory
}

##Logging
Try {
$ErrorLog  = join-path -Path $RootPath -childPath "$LogPath\ErrorLog.txt"
$ProcessLog  = join-path -Path $RootPath -childpath "$LogPath\ProcessLog.txt"

}
Catch
{Write-Host "Get Log folders fail: $LogPath $_"
}
if (Test-Path $ErrorLog ) {
   Clear-Content $ErrorLog
	}

if (Test-Path $ProcessLog ) {
   Clear-Content $ProcessLog
	}
	Return $ErrorLog,$ProcessLog
}
#endregion

#region add error log

Function Add-ErrorLog($ErrorMessage,$Error,$LogReference)
{
$ProcessDate = Get-Date
"$ProcessDate : $ErrorMessage $Error  " | Add-Content $Logging[0]
}
#endregion

#region add process log

Function Add-ProcessLog($ProcessMessage,[bool]$DetailLevel,$Path)
{

Try {

	$ProcessDate = Get-Date
	if($DetailLevel){
"$ProcessDate : $ProcessMessage" | Add-Content $Path
		}
}
Catch 
{Write-Host "Process Log fail: $ProcessMessage $Path $_"}

}
#endregion

#region get application settings

function get-ApplicationSettings($FileName)
{
[xml]$XmlDocument = $null
[xml]$XmlDocument = Get-Content -Path "$Filename"
$baseFolders = $XmlDocument.SQLPublish.BaseFolders.BaseFolder
#$baseFolders

$ApplicationSettings = new-Object -TypeName psobject -Property 	@{"Application" = $XmlDocument.SQLPublish.Publish.Application;
		"nameVersion" = $XmlDocument.SQLPublish.Publish.Version;
		"rootFolder" = ($baseFolders |where-Object {$_.Name -eq "ScriptRootFolder"}).Location;
		"publishToFolder" = ($baseFolders |where-Object {$_.Name -eq "PublishToFolder"}).location;
		"INIFolder"= ($baseFolders |where-Object {$_.Name -eq "INIFolder"}).location
}

	Return $ApplicationSettings

}

#endregion

#region get folder listings

function get-ScriptFolderSettings($FileName)
{[xml]$XmlDocument = $null
[xml]$XmlDocument = Get-Content -Path $FileName
$scriptFolders = $XmlDocument.SQLPublish.ScriptFolders.ScriptFolder
Return $scriptFolders
}

function get-ProcFolderSettings($FileName)
{[xml]$XmlDocument = $null
[xml]$XmlDocument = Get-Content -Path $FileName
$ProcedureSettings = $XmlDocument.SQLPublish.Procedures.Procedure       
Return $ProcedureSettings
}

#endregion

#region add folders

function add-customfolder($RootFolder, $SubFolder){

##Create root version folder if it does not exist

$FolderToCreate = join-path -path $rootFolder -childpath $SubFolder

#write ("Custom folder : {0}" -f $FolderToCreate)

#Create of not existing

if (!(Test-Path $FolderToCreate -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $FolderToCreate
	}
Return $FolderToCreate
}


#endregion

#region prepare scripts 

function invoke-scriptcompiler($Folderlist,$AppPath,$FileSourceRoot,$PublishPath,$PublishPathVersion)
{
 
$INIFolder = $ApplicationSettings.INIFolder
$nameVersion = $ApplicationSettings.nameVersion

write ("Publishing to version : {0}" -f $nameVersion)

Foreach($FolderItem in $FolderList)
{

write ("Publishing folder : {0}" -f $FolderItem)
#Prepare Folder Variable
$ScriptFolder = $scriptFolders | Where-Object {$_.Name -eq $FolderItem }

#Reset File for combining scripts
$fileCombined = $null
$Folder = $ScriptFolder.name

	## Publish scripts from a folder in sort order



if($scriptFolder.UseFolderINI -eq $False)
	{
	#get list of files from folder
write ("Publishing scripts in folder : {0}" -f $FolderItem)

	$AllFiles = $FileSourceRoot +"\" + $FolderItem +"\*.sql"

	$fileList = Get-ChildItem $AllFiles -Name | Sort 

	Foreach ($fileItem in $fileList)
		{
 
  $File = $FileSourceRoot +"\"+ $FolderItem + "\" + $fileItem

  write ("Add script : {0}" -f $FileItem)

		$fileContent = Get-Content -path $File
		$fileCombined = $fileCombined + $fileContent 

		}

	$MyPath = join-path -path $PublishPathVersion -childpath ($Folder + "_$nameVersion.sql")
#    $MyPath
	  write ("Output script : {0}" -f $MyPath)
      write "###########################################"
	#Set-Content -Value $fileCombined -encording UTF8 -Path $MyPath

	Set-Content -Value $fileCombined -Path $MyPath

	}

	## Prepare Scripts for hotfixes from ini files defined in setup
if($scriptFolder.HotfixINI -ne "" )
{
write ("Publishing scripts from HotFix INI for : {0}" -f $FolderItem)


#Get listfrom ini

$Mypath = $INIfolderPath +"\"+ $INIFolder + "\" + $scriptFolder.HotfixINI + ".ini"

if(-NOT(Test-Path -path "$MyPath" ))
{new-Item  -path "$MyPath" }

 $FileList = Get-Content -Path $MyPath
 $fileCombined = $null
    Foreach ($fileItem in $fileList)
		{
	   # $fileItem
		$MyPath = $FileSourceRoot +"\"+ $scriptFolder.name + "\" + $fileItem
	#Set-Location $Path
	#Get-Location
  write ("Add script : {0}" -f $FileItem)

		$fileContent = Get-Content -path "$MyPath" 
		$fileCombined = $fileCombined + $fileContent 
		}


#$MyPath = $rootFolder +"\"+ $publishToFolder + "\" +  $nameVersion + "\" +$scriptFolder.HotfixINI+"_" + "$nameVersion.sql"
	$MyPath = join-path -path $PublishPathVersion -childpath ($scriptFolder.HotfixINI+"_" + "$ameVersion.sql")

	  write ("Output script : {0}" -f $MyPath)
      write "###########################################"

Set-Content -Value $fileCombined -Encoding UTF8 -Path $MyPath
	}

## Publish script that is based on a list of files in an ini file defined in setup
if($scriptFolder.UseFolderINI -eq $True -and $scriptFolder.FolderINI -ne "" )
	{
	#Get ini file list
		
	 $FileList = $scriptFolders.FolderINI
write ("Publishing scripts from Folder INI {0} for {1}" -f ($scriptFolder.FolderINI,$FolderItem))

#	 $fileList
		$fileCombined = $null
		Foreach ($fileItem in $fileList)
		{
	    #$fileItem
			
 $fileCombined = $null
	#	$MyPath =  $FileSourceRoot +"\"+ $INIFolder + "\" + $scriptFolder.FolderINI + ".ini"
$MyPath = $INIfolderPath + "\" + $scriptFolder.FolderINI + ".ini"
		$fileList = Get-Content -path $MyPath 


		  Foreach ($fileItem in $fileList)
		{
	   # $fileItem
		$File =  $FileSourceRoot + "\" + $scriptFolder.name + "\" + $fileItem

write ("Add script : {0}" -f $File)

		$fileContent = Get-Content -path $File
		$fileCombined = $fileCombined + $fileContent 
		}
		 write ("Output script : {0}" -f $MyPath)
      write "###########################################"
		}

$MyPath = $PublishPathVersion + "\" + $scriptFolder.name  +"_" + "$nameVersion.sql"

Set-Content -Value $fileCombined -Encoding UTF8 -Path $MyPath

write ("Published successfully : {0}" -f $MyPath)
		  write "###########################################"
	}
}
}	



#endregion

#region compile CLR procedure

#the script compiler will generate a procedure from a collection of scripts and save the file into a folder to be including in the main scripts. This allows pre-compilation of scripts

function invoke-CLRProcCompiler($FolderList,$AppPath,$FileSourceRoot,$PublishPath,$PublishPathVersion)
{
$INIFolder = $ApplicationSettings.INIFolder
$nameVersion = $ApplicationSettings.nameVersion

write ("Generating CLR Procedures for : {0}" -f $FolderList)

	
Foreach($FolderItem in $FolderList)
{
	
write ("Add scripts from : {0}" -f $FolderItem)
#Prepare Folder Variable
$ProcedureSet = $ProcedureList | Where-Object {$_.Name -eq $FolderItem }

#Reset File for combining scripts
$fileCombined = $null
$DestinationFolder = $AppPath + "\" + $ProcedureSet.DestinationFolder
$ProcedureFileName  = $ProcedureSet.ProcedureFileName + ".sql"
Write-Host ("Procedure : {0}" -f $ProcedureFileName)
Write-Host ("Destination Folder {0}" -f $DestinationFolder)

	## Publish scripts from a folder in sort order

	$AllFiles = $FileSourceRoot +"\" + $FolderItem +"\*.sql"

	$fileList = Get-ChildItem $AllFiles -Name | Sort 

if($ProcedureSet.UseFolderINI -eq $False)
	{
write ("Excluding procedure {0}" -f $FolderItem)
	}

	###################################
## compile procedure based on a list of files in an ini file defined in setup

if($ProcedureSet.UseFolderINI -eq $True -and $ProcedureSet.FolderINI -ne "" )
	{
	#Get ini file list
		
	 $FileList = $ProcedureSet.FolderINI
write ("Compiling scripts from Folder INI {0} into procedure {1}" -f ($ProcedureSet.FolderINI,$ProcedureFileName))

 $fileCombined = $null
$Mypath = $AppPath +"\"+ $INIFolder + "\" + $ProcedureSet.FolderINI + ".ini"
	
if(Test-Path -path "$MyPath" )
{#new-Item -path "$MyPath" 
 $INIList = Get-Content -Path $MyPath
}
		   Foreach ($fileItem in $INIList)
		{
	   # $fileItem
		$MyPath = $FileSourceRoot +"\"+ $ProcedureSet.name + "\" +  $fileItem 
	#Set-Location $Path
	#Get-Location
  write ("Add script : {0}" -f $FileItem)

		$fileContent = Get-Content -path "$MyPath" 
		$fileCombined = $fileCombined + $fileContent 
		}

}
	
$MyPath = $FileSourceRoot + "\" + $ProcedureSet.DestinationFolder  +"\" + $ProcedureSet.ProcedureFileName + ".sql"

Set-Content -Value $fileCombined -Encoding UTF8 -Path $MyPath

write ("Procedure created successfully : {0}" -f $MyPath)
      write "###########################################"
	}
	}

#endregion
