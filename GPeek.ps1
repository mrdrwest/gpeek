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

#Initialize array to store custom objects
$gpoTable=@()
$pathGPOBackup=(Get-Content .\GPeek.json | ConvertFrom-Json).pathGPO

#Recursively read GPO backup path
(Get-ChildItem $pathGPOBackup -Include backup.xml -Recurse) | ForEach-Object {
    #Initialize custom object to store GPO information
    $customObject = [PSCustomObject] @{
        "GPOBackupPath" = ""
        "GPOGuid"       = ""
        "GPODisplayName" = ""
    }

    #Parse GPO backup.xml file using XML methods
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
    $idx=0
    $gpoTable | ForEach-Object {
        Add-Member `
            -InputObject $PSItem `
            -Name Index `
            -Value $idx `
            -MemberType NoteProperty `
            -Force
    $idx++    
    }
}    
Write-Output $gpoTable | Select-Object Index, GPOBackupPath, GPOGuid, GPODisplayName
$gpoTable=$null
$customObject=$null
