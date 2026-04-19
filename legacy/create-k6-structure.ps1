<#
.SYNOPSIS
Creates the canonical GMKTec K6 folder structure.

.DESCRIPTION
Creates the approved folder tree under C:\Data by default, or under an
alternate root path when -Root is supplied. The script is safe to run
multiple times, does not delete content, and reports whether each folder
was created or already existed.

It also creates a starter project template at:
  <Root>\10_PROJECTS\_TEMPLATE_PROJECT

.PARAMETER Root
Root path for the managed data tree. Defaults to C:\Data.

.EXAMPLE
.\scripts\create-k6-structure.ps1

Creates the canonical structure under C:\Data.

.EXAMPLE
.\scripts\create-k6-structure.ps1 -Root D:\Data

Creates the canonical structure under D:\Data.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = 'C:\Data'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TopLevelFolders = @(
    '00_INBOX',
    '10_PROJECTS',
    '20_OPERATIONS',
    '25_PERSONAL',
    '30_MEDIA',
    '40_REFERENCE',
    '50_SYSTEM',
    '90_ARCHIVE'
)

$PersonalSubfolders = @(
    '01_Family',
    '02_Finance',
    '03_Property',
    '04_Travel',
    '05_Health_Admin',
    '06_Legal_and_ID',
    '07_Personal_Admin',
    '08_Warranties_and_Receipts',
    '09_Personal_Projects',
    '99_Archive'
)

$ProjectTemplateSubfolders = @(
    '01_ADMIN',
    '02_SOURCE',
    '03_WORKING',
    '04_OUTPUT',
    '05_REFERENCE',
    '99_ARCHIVE'
)

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Write-Log "[exists ] $Path"
        return
    }

    $null = New-Item -ItemType Directory -Path $Path -Force
    Write-Log "[created] $Path"
}

Write-Log "Target root: $Root"
Write-Log 'Creating canonical folder structure...'

# Create the managed root first so child paths can be joined safely.
Ensure-Directory -Path $Root

# Build the approved top-level structure exactly as defined in the standard.
foreach ($folder in $TopLevelFolders) {
    Ensure-Directory -Path (Join-Path -Path $Root -ChildPath $folder)
}

$personalRoot = Join-Path -Path $Root -ChildPath '25_PERSONAL'
# Personal records have a fixed subfolder model and should be created
# consistently across machines.
foreach ($folder in $PersonalSubfolders) {
    Ensure-Directory -Path (Join-Path -Path $personalRoot -ChildPath $folder)
}

$templateRoot = Join-Path -Path (Join-Path -Path $Root -ChildPath '10_PROJECTS') -ChildPath '_TEMPLATE_PROJECT'
Ensure-Directory -Path $templateRoot

# Seed a reusable project template so new projects start from the same model.
foreach ($folder in $ProjectTemplateSubfolders) {
    Ensure-Directory -Path (Join-Path -Path $templateRoot -ChildPath $folder)
}

Write-Log 'Structure creation complete.'
Write-Log 'No existing files were overwritten or deleted.'
