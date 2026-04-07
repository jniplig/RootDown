<#
.SYNOPSIS
Audits likely source folders and suggests destination categories in the K6 model.

.DESCRIPTION
Scans files and folders from common user locations and optional additional
paths, then exports a CSV report with conservative category suggestions. This
script never moves, renames, or deletes anything. It is intended to support
planning and review before migration into the canonical C:\Data structure.

.PARAMETER IncludeDesktop
Include the current user's Desktop in the scan set.

.PARAMETER IncludeDownloads
Include the current user's Downloads in the scan set.

.PARAMETER IncludeDocuments
Include the current user's Documents in the scan set.

.PARAMETER AdditionalPath
One or more additional paths to include in the audit.

.PARAMETER Recurse
Scan recursively under each selected root.

.PARAMETER ReportPath
Optional CSV output path. Defaults to a timestamped CSV in the current
directory.

.EXAMPLE
.\scripts\audit-k6-tree.ps1

Audit Desktop, Downloads, and Documents using default behavior.

.EXAMPLE
.\scripts\audit-k6-tree.ps1 -IncludeDocuments -AdditionalPath C:\Exports -ReportPath .\audit.csv

Audit Documents and C:\Exports only, writing the results to audit.csv.

.EXAMPLE
.\scripts\audit-k6-tree.ps1 -IncludeDownloads -Recurse

Audit Downloads recursively.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$IncludeDesktop,

    [Parameter()]
    [switch]$IncludeDownloads,

    [Parameter()]
    [switch]$IncludeDocuments,

    [Parameter()]
    [string[]]$AdditionalPath,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [string]$ReportPath = (Join-Path -Path (Get-Location) -ChildPath ("audit-report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
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

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message
}

function Get-KeywordMatch {
    param(
        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter(Mandatory)]
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($Value -match [regex]::Escape($keyword)) {
            return $true
        }
    }

    return $false
}

function Get-AuditClassification {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    $name = $Item.Name.ToLowerInvariant()
    $path = $Item.FullName.ToLowerInvariant()
    $extension = if ($Item.PSIsContainer) { '' } else { $Item.Extension.ToLowerInvariant() }

    # These heuristics are intentionally simple and conservative. When no rule
    # matches strongly, the script falls back to 00_INBOX for manual review.
    $mediaExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.svg', '.webp', '.mp4', '.mov', '.mkv', '.avi', '.mp3', '.wav', '.flac', '.m4a')
    $systemExtensions = @('.ps1', '.psm1', '.psd1', '.sh', '.bat', '.cmd', '.reg', '.ini', '.cfg', '.conf', '.json', '.yaml', '.yml', '.xml', '.log', '.inf', '.sys', '.drv', '.msi', '.exe')
    $referenceExtensions = @('.pdf', '.epub')
    $archiveExtensions = @('.zip', '.7z', '.rar', '.tar', '.gz')

    if ($mediaExtensions -contains $extension -or (Get-KeywordMatch -Value $name -Keywords @('photo', 'image', 'video', 'audio', 'media', 'recording', 'screenshot'))) {
        return @{
            LikelyCategory          = 'Media asset'
            SuggestedTopLevelFolder = '30_MEDIA'
            Notes                   = 'Matched media extension or media-related keyword.'
        }
    }

    if ($systemExtensions -contains $extension -or (Get-KeywordMatch -Value $path -Keywords @('script', 'config', 'export', 'inventory', 'installer', 'driver', 'backup', 'system', 'setup'))) {
        return @{
            LikelyCategory          = 'System or technical asset'
            SuggestedTopLevelFolder = '50_SYSTEM'
            Notes                   = 'Matched script, configuration, export, installer, or technical keyword.'
        }
    }

    if ((Get-KeywordMatch -Value $path -Keywords @('finance', 'bank', 'tax', 'property', 'travel', 'passport', 'visa', 'family', 'receipt', 'warranty', 'insurance', 'medical', 'health', 'legal', 'identity', 'license'))) {
        return @{
            LikelyCategory          = 'Personal record'
            SuggestedTopLevelFolder = '25_PERSONAL'
            Notes                   = 'Matched personal administration keyword.'
        }
    }

    if ($referenceExtensions -contains $extension -or (Get-KeywordMatch -Value $name -Keywords @('manual', 'guide', 'reference', 'handbook', 'spec', 'datasheet'))) {
        return @{
            LikelyCategory          = 'Reference material'
            SuggestedTopLevelFolder = '40_REFERENCE'
            Notes                   = 'Matched reference-like extension or keyword.'
        }
    }

    if ($archiveExtensions -contains $extension -or (Get-KeywordMatch -Value $path -Keywords @('archive', 'old', 'historical', 'legacy'))) {
        return @{
            LikelyCategory          = 'Archived package or historical content'
            SuggestedTopLevelFolder = '90_ARCHIVE'
            Notes                   = 'Matched compressed archive or archive-related keyword.'
        }
    }

    if (Get-KeywordMatch -Value $path -Keywords @('project', 'client', 'proposal', 'deliverable', 'brief', 'lesson', 'course')) {
        return @{
            LikelyCategory          = 'Project material'
            SuggestedTopLevelFolder = '10_PROJECTS'
            Notes                   = 'Matched project-oriented keyword.'
        }
    }

    if (Get-KeywordMatch -Value $path -Keywords @('operations', 'admin', 'invoice', 'policy', 'process', 'procedure', 'meeting')) {
        return @{
            LikelyCategory          = 'Operational material'
            SuggestedTopLevelFolder = '20_OPERATIONS'
            Notes                   = 'Matched operations-related keyword.'
        }
    }

    return @{
        LikelyCategory          = 'Needs review'
        SuggestedTopLevelFolder = '00_INBOX'
        Notes                   = 'No strong heuristic match. Review manually.'
    }
}

$selectedRoots = New-Object System.Collections.Generic.List[string]
$defaultRootsRequested = -not $IncludeDesktop.IsPresent -and -not $IncludeDownloads.IsPresent -and -not $IncludeDocuments.IsPresent

if ($defaultRootsRequested -or $IncludeDesktop) {
    $selectedRoots.Add([Environment]::GetFolderPath('Desktop'))
}

if ($defaultRootsRequested -or $IncludeDownloads) {
    $selectedRoots.Add((Join-Path -Path $HOME -ChildPath 'Downloads'))
}

if ($defaultRootsRequested -or $IncludeDocuments) {
    $selectedRoots.Add([Environment]::GetFolderPath('MyDocuments'))
}

if ($AdditionalPath) {
    foreach ($path in $AdditionalPath) {
        $selectedRoots.Add($path)
    }
}

$scanRoots = $selectedRoots |
    Where-Object { $_ -and $_.Trim() } |
    Sort-Object -Unique

if (-not $scanRoots) {
    throw 'No scan roots were resolved.'
}

Write-Log 'Audit scan roots:'
foreach ($root in $scanRoots) {
    Write-Log "  $root"
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($root in $scanRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Log "[skipped] Missing path: $root"
        continue
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $root).Path
    Write-Log "[scan   ] $resolvedRoot"

    # Audit only. The script inspects file system metadata and suggests likely
    # destinations but does not perform any move or rename operation.
    $items = if ($Recurse) {
        Get-ChildItem -LiteralPath $resolvedRoot -Force -Recurse
    }
    else {
        Get-ChildItem -LiteralPath $resolvedRoot -Force
    }

    foreach ($item in $items) {
        $classification = Get-AuditClassification -Item $item
        $results.Add([pscustomobject]@{
            FullPath                 = $item.FullName
            ItemType                 = $(if ($item.PSIsContainer) { 'Directory' } else { 'File' })
            SizeBytes                = $(if ($item.PSIsContainer) { 0 } else { $item.Length })
            LastModified             = $item.LastWriteTime.ToString('s')
            LikelyCategory           = $classification.LikelyCategory
            SuggestedTopLevelFolder  = $classification.SuggestedTopLevelFolder
            Notes                    = $classification.Notes
        })
    }
}

$invalidSuggestions = $results | Where-Object { $_.SuggestedTopLevelFolder -notin $TopLevelFolders }
if ($invalidSuggestions) {
    throw 'One or more audit records produced an invalid top-level folder suggestion.'
}

$reportDirectory = Split-Path -Path $ReportPath -Parent
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    $null = New-Item -ItemType Directory -Path $reportDirectory -Force
}

$results | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
Write-Log "CSV report written to: $ReportPath"
Write-Log ("Audited items: {0}" -f $results.Count)
Write-Log 'Audit complete. No items were moved, renamed, or deleted.'
