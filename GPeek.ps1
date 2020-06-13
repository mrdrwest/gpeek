<#
.SYNOPSIS
    When backing up Group Policy Objects (GPO) using the Group Policy
    Management Console (GPMC), it creates a folder name using a Globally
    Unique Identifier (GUID) that does not represent the Active Directory (AD)
    GUID ID for the GPO. GPeek.ps21 creates a custom object that represents a
    GPO's backup path, GUID ID, and GPO display name. 

.DESCRIPTION
    List GPO backup as an objecgt with a friendly name
#>

$gpoTable=@()
$ADGPOGUID="GPOGuid"

$pathGPOBackup=(Get-Content .\GPeek.json | ConvertFrom-Json).pathGPO
(Get-ChildItem $pathGPOBackup -Include backup.xml -Recurse) | ForEach-Object {
    #Initialize custom object to store GPO information
    $customObject = [PSCustomObject] @{
        "GPOBackupPath" = ""
        "GPOGuid"       = ""
        "GPODisplayName" = ""
    }

    $xml=[xml](Get-Content $PSItem)
    $gpoBackupPath=$PSItem.Directory.FullName
    $gpoGuid= $xml.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.ID.'#cdata-section'
    $gpoDisplayName=$xml.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.DisplayName.'#cdata-section'

    #Add GPO backup information to custom object
    $customObject.GPOBackupPath=$gpoBackupPath
    $customObject.GPOGuid=$gpoGuid
    $customObject.GPODisplayName=$gpoDisplayName

    #Update index into custom object for next GPO information
    $gpoTable+=$customObject

    #add NoteProperty to custom object to reference entries by index number
    $gpoTable | ForEach-Object {
        $param=@{
            "InputObject" = $PSItem
            "Name"        = "Index"
            "Value"       = $idx++
            "MemberType"  = "NoteProperty"
        }
        Add-Member @param
    }
    Write-Output $gpoTable | Select-Object Index, GPOBackupPath, GPOGuid, GPODisplayName
}