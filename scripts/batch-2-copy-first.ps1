<#
.SYNOPSIS
Performs the first safe Batch 2 copy-first operations for workflow-sensitive media folders.

.DESCRIPTION
This script copies only the approved Batch 2 folders into the canonical
C:\Data structure. It is intentionally narrow, copy-only, and non-destructive.

Approved operations:

1. C:\Users\jnipl\OneDrive\Documents\ATEM Autosave\2026-04-05
   -> C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM\ATEM_Autosave\2026-04-05

2. C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Preferences
   -> C:\Data\50_SYSTEM\Config_Backups\Resolume\Preferences

3. C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Presets
   -> C:\Data\50_SYSTEM\Config_Backups\Resolume\Presets

4. C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Fixture Library
   -> C:\Data\50_SYSTEM\Config_Backups\Resolume\Fixture_Library

5. C:\Users\jnipl\OneDrive\Documents\Resolume Wire\Preferences
   -> C:\Data\50_SYSTEM\Config_Backups\Resolume_Wire\Preferences

6. C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Compositions
   -> C:\Data\10_PROJECTS\Studio\Resolume_Shows

The script defaults to dry-run mode. Use -Apply to perform real copies.
It never moves, renames, or deletes anything.

.PARAMETER Apply
Perform the real copy operations. Without this switch, the script only prints
planned actions and writes a CSV report.

.PARAMETER ReportPath
Optional report path. If omitted, the script writes a CSV report in the repo
root named batch-2-copy-report-<timestamp>.csv.

.EXAMPLE
.\scripts\batch-2-copy-first.ps1

Preview the approved Batch 2 copy operations without changing any files.

.EXAMPLE
.\scripts\batch-2-copy-first.ps1 -Apply

Perform the approved Batch 2 copy operations and write the default report.

.EXAMPLE
.\scripts\batch-2-copy-first.ps1 -ReportPath .\batch-2-copy-report.csv

Preview the approved copy operations and write the report to a custom path.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [string]$ReportPath = (Join-Path -Path 'C:\Users\jnipl\projects\k6-organization' -ChildPath ("batch-2-copy-report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Results = New-Object System.Collections.Generic.List[object]

$ApprovedOperations = @(
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\ATEM Autosave\2026-04-05'
        DestinationPath = 'C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM\ATEM_Autosave\2026-04-05'
    },
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Preferences'
        DestinationPath = 'C:\Data\50_SYSTEM\Config_Backups\Resolume\Preferences'
    },
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Presets'
        DestinationPath = 'C:\Data\50_SYSTEM\Config_Backups\Resolume\Presets'
    },
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Fixture Library'
        DestinationPath = 'C:\Data\50_SYSTEM\Config_Backups\Resolume\Fixture_Library'
    },
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\Resolume Wire\Preferences'
        DestinationPath = 'C:\Data\50_SYSTEM\Config_Backups\Resolume_Wire\Preferences'
    },
    @{
        SourcePath      = 'C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Compositions'
        DestinationPath = 'C:\Data\10_PROJECTS\Studio\Resolume_Shows'
    }
)

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
        Write-Log "[exists ] Destination parent folder: $Path"
        return
    }

    if (-not $Apply) {
        Write-Log "[planned] WhatIf: create destination parent folder $Path"
        return
    }

    $null = New-Item -ItemType Directory -Path $Path -Force
    Write-Log "[created] Destination parent folder: $Path"
}

function Invoke-ApprovedCopy {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $itemType = 'Directory'
    $action = 'Copy'
    $destinationParent = Split-Path -Path $DestinationPath -Parent

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Log "[missing] $SourcePath"
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'MissingSource' -Reason 'Source directory does not exist.'
        return
    }

    Ensure-Directory -Path $destinationParent

    if (Test-Path -LiteralPath $DestinationPath) {
        Write-Log "[conflict] $DestinationPath"
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Conflict' -Reason 'Destination directory already exists. Source left unchanged.'
        return
    }

    if (-not $Apply) {
        Write-Log "[planned] WhatIf: copy directory $SourcePath -> $DestinationPath"
        Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Planned' -Reason 'Dry-run preview only. Directory not copied.'
        return
    }

    # Copy-Item is used here because the operation is directory-to-directory,
    # should preserve contents, and must not overwrite an existing destination.
    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Recurse
    Write-Log "[copied ] $SourcePath -> $DestinationPath"
    Add-Result -SourcePath $SourcePath -DestinationPath $DestinationPath -ItemType $itemType -Action $action -Status 'Copied' -Reason 'Directory copied successfully.'
}

Write-Log ("Mode: {0}" -f $(if ($Apply) { 'apply' } else { 'dry-run' }))
Write-Log "Report path: $ReportPath"
Write-Log 'Starting Batch 2 copy-first operations...'

foreach ($operation in $ApprovedOperations) {
    Invoke-ApprovedCopy -SourcePath $operation.SourcePath -DestinationPath $operation.DestinationPath
}

$reportDirectory = Split-Path -Path $ReportPath -Parent
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    if ($Apply) {
        $null = New-Item -ItemType Directory -Path $reportDirectory -Force
    }
}

$Results | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
Write-Log "CSV report written to: $ReportPath"
Write-Log ("Recorded operations: {0}" -f $Results.Count)
Write-Log 'Batch 2 copy-first operations complete.'
