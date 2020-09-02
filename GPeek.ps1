<#
.SYNOPSIS
    Retrieve GPO display name from backup GUID folder name

.DESCRIPTION
    GPO backups are stored in folders with a GUID naming convention,
    which makes it difficult to determine what folder a specific GPO
    is stored in if there are many backups.

    GPeek.ps1 recursively searches thru the root GPO backup folder
    for a GPO $BACKUPXML file and creates a custom object that
    represents a backed up GPO path, ID, and display name, and 
    writes what it finds to the console. GPeek.json file defines
    the root backup path (modify as required). GPeek.json must be in
    the same folder as GPeek.ps1.

.PARAMETER PathGPOBackup
    Specify literal path to GPOBackup root folder

.EXAMPLE
    Get-BackupGPOName -PathGPOBackup C:\GPOExport

    The folder C:\GPOExport will be recursively searched for a GPO
    backup.xml file, which will be parsed for GPO information.
#>

$BACKUPXML="backup.xml"
function Get-BackupGPOName {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(mandatory=$false)]
        [string] 
        $PathGPOBackup=""
    )

    $prevErrorView = $ErrorView
    $ErrorView = "ConciseView"

    # Assign GPO backup path via parameter or JSON configuruation file
    If (-not(Test-Path $PathGPOBackup)) {
        ($PathGPOBackup=(Get-Content .\GPeek.json | ConvertFrom-Json).rootPathGPO) | Out-Null
    }
    # Recursively search GPO backup path for $BACKUPXML
    $backupXmlFilePath=Get-ChildItem -LiteralPath $pathGPOBackup -Include $BACKUPXML -Recurse
        
    If (-not $backupXmlFilePath.Exists) {
        "$BACKUPXML not found : $([char]27)[38;2;255;0;0m ☹ `n"
    }
    
    # Initialize array to store custom objects
    $gpoTable=@()

    $backupXmlFilePath | ForEach-Object {
        
        #Initialize custom object to store GPO information
        $customObject = [PSCustomObject] @{
            "GPOBackupPath" = ""
            "GPOGuid"       = ""
            "GPODisplayName" = ""
        }
            
        # Parse GPO $BACKUPXML file using XML methods
        $xml=[xml](Get-Content $PSItem)
        $gpoBackupPath=$PSItem.Directory.FullName
        $gpoGuid= $xml.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.ID.'#cdata-section'
        $gpoDisplayName=$xml.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.DisplayName.'#cdata-section'
        
        # Add GPO backup information to custom object
        $customObject.GPOBackupPath=$gpoBackupPath
        $customObject.GPOGuid=$gpoGuid
        $customObject.GPODisplayName=$gpoDisplayName

        # Update index into custom object for next GPO information
        $gpoTable+=$customObject
        
        # Add NoteProperty to custom object to reference entries by index number
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
    # Ensure output text color is white
    "$([char]27)[38;2;255;255;255m"    
    Write-Output $gpoTable | Select-Object Index, GPOBackupPath, GPOGuid, GPODisplayName
    $gpoTable=$null
    $customObject=$null
    $ErrorView = $prevErrorView
}