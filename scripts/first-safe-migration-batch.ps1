<#
.SYNOPSIS
Performs the first safe K6 migration batch into the canonical C:\Data structure.

.DESCRIPTION
This script handles a deliberately narrow migration batch for the K6 rollout.
It moves only a small set of known-safe items into the canonical C:\Data tree:

1. C:\Users\jnipl\OneDrive\Documents\PowerShell
   -> C:\Data\50_SYSTEM\Scripts\PowerShell

2. C:\Users\jnipl\OneDrive\Documents\WindowsPowerShell
   -> C:\Data\50_SYSTEM\Config_Backups\WindowsPowerShell

3. C:\Users\jnipl\Downloads\WinBox_Windows
   -> C:\Data\50_SYSTEM\Installers\WinBox_Windows

4. Top-level audio files from C:\Users\jnipl\Downloads
   -> C:\Data\30_MEDIA\Audio\Raw

The script defaults to dry-run mode and prints a WhatIf-style preview even when
no changes are applied. Use -Apply to perform the actual moves.

If this batch has already been completed on the machine, the script may now
serve primarily as a verification aid and historical record of the approved
first migration scope.

This script does not rename files, does not recurse into Downloads for audio
collection, does not move Resolve, Blackmagic, or ATEM folders, and does not
touch ambiguous archive files.

.PARAMETER Apply
Perform the real move operations. Without this switch, the script only previews
what would happen and writes a report.

.EXAMPLE
.\scripts\first-safe-migration-batch.ps1

Preview the first safe migration batch without changing any files.

.EXAMPLE
.\scripts\first-safe-migration-batch.ps1 -Apply

Run the approved first migration batch and move the eligible items.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = 'C:\Users\jnipl\projects\k6-organization'
$DataRoot = 'C:\Data'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ReportPath = Join-Path -Path $RepoRoot -ChildPath ("migration-report-{0}.csv" -f $Timestamp)

$AudioExtensions = @('.mp3', '.flac', '.wav', '.aiff', '.m4a')
$Results = New-Object System.Collections.Generic.List[object]

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message
}

function Add-Result {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [string]$ItemType,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Reason
    )

    $Results.Add([pscustomobject]@{
        SourcePath      = $SourcePath
        DestinationPath = $DestinationPath
        ItemType        = $ItemType
        Action          = $Action
        Status          = $Status
        Reason          = $Reason
    })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Write-Log "[exists ] Destination folder: $Path"
        return
    }

    if (-not $Apply) {
        Write-Log "[planned] WhatIf: create destination folder $Path"
        return
    }

    $null = New-Item -ItemType Directory -Path $Path -Force
    Write-Log "[created] Destination folder: $Path"
}

function Invoke-DirectoryMove {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $parentDestination = Split-Path -Path $DestinationPath -Parent
    $itemType = 'Directory'
    $action = 'Move'

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Log "[missing] $SourcePath"
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'MissingSource' -Reason 'Source directory does not exist.'
        return
    }

    Ensure-Directory -Path $parentDestination

    if (Test-Path -LiteralPath $DestinationPath) {
        Write-Log "[conflict] $DestinationPath"
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Conflict' -Reason 'Destination directory already exists. Source left unchanged.'
        return
    }

    if ($Apply) {
        Write-Log "[moved ] $SourcePath -> $DestinationPath"
        Move-Item -LiteralPath $SourcePath -Destination $DestinationPath
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Moved' -Reason 'Directory moved successfully.'
        return
    }

    Write-Log "[planned] WhatIf: move directory $SourcePath -> $DestinationPath"
    Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Planned' -Reason 'Dry-run preview only. Directory not moved.'
}

function Invoke-AudioMove {
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot,

        [Parameter(Mandatory)]
        [string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        Write-Log "[missing] $SourceRoot"
        Add-Result -SourcePath $SourceRoot -DestinationPath $DestinationRoot -ItemType 'Directory' -Action 'Scan' -Status 'MissingSource' -Reason 'Source Downloads folder does not exist.'
        return
    }

    Ensure-Directory -Path $DestinationRoot

    # Only inspect the top level of Downloads. This intentionally does not
    # recurse into subdirectories or touch folder-based app data.
    $files = Get-ChildItem -LiteralPath $SourceRoot -File |
        Where-Object { $_.Extension.ToLowerInvariant() -in $AudioExtensions }

    if (-not $files) {
        Write-Log '[skipped] No eligible top-level audio files found in Downloads.'
        Add-Result -SourcePath $SourceRoot -DestinationPath $DestinationRoot -ItemType 'File' -Action 'Move' -Status 'Skipped' -Reason 'No eligible top-level audio files matched the approved extensions.'
        return
    }

    foreach ($file in $files) {
        $destinationPath = Join-Path -Path $DestinationRoot -ChildPath $file.Name

        if (Test-Path -LiteralPath $destinationPath) {
            Write-Log "[conflict] $destinationPath"
            Add-Result -SourcePath $file.FullName -DestinationPath $destinationPath -ItemType 'File' -Action 'Move' -Status 'Conflict' -Reason 'Destination file already exists. Source left unchanged.'
            continue
        }

        if ($Apply) {
            Write-Log "[moved ] $($file.FullName) -> $destinationPath"
            Move-Item -LiteralPath $file.FullName -Destination $destinationPath
            Add-Result -SourcePath $file.FullName -DestinationPath $destinationPath -ItemType 'File' -Action 'Move' -Status 'Moved' -Reason 'Audio file moved successfully.'
            continue
        }

        Write-Log "[planned] WhatIf: move file $($file.FullName) -> $destinationPath"
        Add-Result -SourcePath $file.FullName -DestinationPath $destinationPath -ItemType 'File' -Action 'Move' -Status 'Planned' -Reason 'Dry-run preview only. File not moved.'
    }
}

Write-Log ("Mode: {0}" -f $(if ($Apply) { 'apply' } else { 'dry-run' }))
Write-Log "Report path: $ReportPath"
Write-Log 'Starting first safe migration batch...'

# Approved directory moves only. Resolve, Blackmagic, and ATEM folders are
# intentionally excluded from this first migration script.
Invoke-DirectoryMove -SourcePath 'C:\Users\jnipl\OneDrive\Documents\PowerShell' -DestinationPath (Join-Path -Path $DataRoot -ChildPath '50_SYSTEM\Scripts\PowerShell')
Invoke-DirectoryMove -SourcePath 'C:\Users\jnipl\OneDrive\Documents\WindowsPowerShell' -DestinationPath (Join-Path -Path $DataRoot -ChildPath '50_SYSTEM\Config_Backups\WindowsPowerShell')
Invoke-DirectoryMove -SourcePath 'C:\Users\jnipl\Downloads\WinBox_Windows' -DestinationPath (Join-Path -Path $DataRoot -ChildPath '50_SYSTEM\Installers\WinBox_Windows')

# Approved top-level audio file move only. No recursion, no zips, and no
# directory moves from Downloads beyond the explicitly approved WinBox folder.
Invoke-AudioMove -SourceRoot 'C:\Users\jnipl\Downloads' -DestinationRoot (Join-Path -Path $DataRoot -ChildPath '30_MEDIA\Audio\Raw')

$Results | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
Write-Log "CSV report written to: $ReportPath"
Write-Log ("Recorded operations: {0}" -f $Results.Count)
Write-Log 'Migration batch complete.'
