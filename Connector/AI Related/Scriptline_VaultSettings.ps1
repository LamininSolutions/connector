


# Block for declaring the script parameters.
Param()

# Your code goes here.



$MFVaultInstall_Dir = $env:LOCALAPPDATA + "\MFSQL Vault Install\"
$Filename = "VaultSettings.xml"

if (!(Test-Path $MFVaultInstall_Dir -PathType Container)) {
    


set-location $MFVaultInstall_Dir 

[xml]$XmlDocument = Get-Content -Path $Filename -encoding UTF8
#$XmlDocument.XMLFILE.VaultSettingItem| Format-Table -AutoSize 
AI_SetMsiProperty EDIT_VAULTNAME_PROP $XmlDocument.XMLFILE.VaultSettingItem.VaultName 
AI_SetMsiProperty EDIT_PORT_PROP $XmlDocument.XMLFILE.VaultSettingItem.PortNumber 
AI_SetMsiProperty EDIT_MFAUTHTYPE_PROP $XmlDocument.XMLFILE.VaultSettingItem.AuthenticationType 
AI_SetMsiProperty EDIT_PROTOCOL_PROP $XmlDocument.XMLFILE.VaultSettingItem.Protocol 
AI_SetMsiProperty EDIT_MFUSERNAME_PROP $XmlDocument.XMLFILE.VaultSettingItem.UserName 
AI_SetMsiProperty EDIT_MFPASSWORD_PROP $XmlDocument.XMLFILE.VaultSettingItem.Password 
AI_SetMsiProperty USERDOMAIN $XmlDocument.XMLFILE.VaultSettingItem.Domain 
AI_SetMsiProperty EDIT_GUID_PROP $XmlDocument.XMLFILE.VaultSettingItem.GUID 
AI_SetMsiProperty EDIT_NETWORKADDRESS_PROP $XmlDocument.XMLFILE.VaultSettingItem.Server

Del Application.*
Del ContentPackage.*
Del IMLApplication.*
}

$key = Get-ItemProperty "Registry::HKEY_CURRENT_USER\Software\RegisteredApplications" -Name "M-Files Desktop"
$MFVersion = $Key.'M-Files Desktop'.Replace("SOFTWARE\Motive\M-Files\","" )
$MFVersion = $MFVersion.Replace("\Client\Capabilities","" )

AI_SetMsiProperty EDIT_MFVERSION_PROP $MFVersion.toString()