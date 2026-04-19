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

function Get-MatchedKeyword {
    param(
        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter(Mandatory)]
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($Value -match [regex]::Escape($keyword)) {
            return $keyword
        }
    }

    return $null
}

function New-ClassificationResult {
    param(
        [Parameter(Mandatory)]
        [string]$LikelyCategory,

        [Parameter(Mandatory)]
        [string]$SuggestedTopLevelFolder,

        [Parameter(Mandatory)]
        [string]$Notes
    )

    return @{
        LikelyCategory          = $LikelyCategory
        SuggestedTopLevelFolder = $SuggestedTopLevelFolder
        Notes                   = $Notes
    }
}

function Get-AuditClassification {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    $name = $Item.Name.ToLowerInvariant()
    $path = $Item.FullName.ToLowerInvariant()
    $extension = if ($Item.PSIsContainer) { '' } else { $Item.Extension.ToLowerInvariant() }
    $isDirectory = $Item.PSIsContainer

    # These heuristics are intentionally simple and conservative. When no rule
    # matches strongly, the script falls back to 00_INBOX for manual review.
    $mediaExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.svg', '.webp', '.mp4', '.mov', '.mkv', '.avi', '.mp3', '.wav', '.flac', '.m4a')
    $systemExtensions = @('.ps1', '.psm1', '.psd1', '.sh', '.bat', '.cmd', '.reg', '.ini', '.cfg', '.conf', '.json', '.yaml', '.yml', '.xml', '.log', '.inf', '.sys', '.drv', '.msi', '.exe')
    $referenceExtensions = @('.pdf', '.epub')
    $archiveExtensions = @('.zip', '.7z', '.rar', '.tar', '.gz')
    $shortcutExtensions = @('.lnk', '.url')

    # Keep the keyword sets explicit and readable. Directories are matched
    # against both the item name and full path before falling back to review.
    $systemKeywords = @(
        'powershell', 'windowspowershell', 'winbox', 'blackmagic', 'atem',
        'scripts', 'config', 'configs', 'backup', 'backups', 'drivers',
        'installers', 'export', 'exports', 'inventory', 'inventories',
        'profile', 'profiles', 'system', 'setup', 'tool', 'tools'
    )
    $mediaKeywords = @(
        'resolume', 'obs', 'audio', 'video', 'media', 'clips', 'recordings',
        'footage', 'samples', 'stems', 'photo', 'image', 'screenshot'
    )
    $personalKeywords = @(
        'family', 'finance', 'property', 'travel', 'passport', 'receipt',
        'receipts', 'warranty', 'warranties', 'id', 'legal', 'insurance',
        'bank', 'tax', 'visa', 'health', 'medical', 'identity', 'license'
    )
    $operationsKeywords = @(
        'template', 'templates', 'office templates', 'office-template',
        'recurring admin', 'admin', 'operations', 'invoice', 'policy',
        'process', 'procedure', 'meeting', 'school operations', 'curriculum',
        'attendance', 'schedule', 'forms', 'checklist'
    )
    $projectKeywords = @(
        'project', 'projects', 'client', 'proposal', 'deliverable', 'brief',
        'lesson', 'course', 'module', 'sprint', 'milestone', 'launch'
    )
    $referenceKeywords = @('manual', 'guide', 'reference', 'handbook', 'spec', 'datasheet')
    $historicalArchiveKeywords = @('archive', 'archived', 'old', 'historical', 'legacy', 'backup', 'backups')

    $nameSystemKeyword = Get-MatchedKeyword -Value $name -Keywords $systemKeywords
    $pathSystemKeyword = Get-MatchedKeyword -Value $path -Keywords $systemKeywords
    $nameMediaKeyword = Get-MatchedKeyword -Value $name -Keywords $mediaKeywords
    $pathMediaKeyword = Get-MatchedKeyword -Value $path -Keywords $mediaKeywords
    $namePersonalKeyword = Get-MatchedKeyword -Value $name -Keywords $personalKeywords
    $pathPersonalKeyword = Get-MatchedKeyword -Value $path -Keywords $personalKeywords
    $nameOperationsKeyword = Get-MatchedKeyword -Value $name -Keywords $operationsKeywords
    $pathOperationsKeyword = Get-MatchedKeyword -Value $path -Keywords $operationsKeywords
    $nameProjectKeyword = Get-MatchedKeyword -Value $name -Keywords $projectKeywords
    $pathProjectKeyword = Get-MatchedKeyword -Value $path -Keywords $projectKeywords
    $nameReferenceKeyword = Get-MatchedKeyword -Value $name -Keywords $referenceKeywords
    $pathHistoricalArchiveKeyword = Get-MatchedKeyword -Value $path -Keywords $historicalArchiveKeywords
    $nameHistoricalArchiveKeyword = Get-MatchedKeyword -Value $name -Keywords $historicalArchiveKeywords

    if ($isDirectory) {
        if ($nameSystemKeyword) {
            return New-ClassificationResult -LikelyCategory 'System or technical directory' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Matched directory keyword '{0}' in directory name." -f $nameSystemKeyword)
        }

        if ($pathSystemKeyword) {
            return New-ClassificationResult -LikelyCategory 'System or technical directory' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Matched path keyword '{0}' for a directory." -f $pathSystemKeyword)
        }

        if ($nameMediaKeyword) {
            return New-ClassificationResult -LikelyCategory 'Media or studio directory' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Matched directory keyword '{0}' in directory name." -f $nameMediaKeyword)
        }

        if ($pathMediaKeyword) {
            return New-ClassificationResult -LikelyCategory 'Media or studio directory' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Matched path keyword '{0}' for a directory." -f $pathMediaKeyword)
        }

        if ($namePersonalKeyword) {
            return New-ClassificationResult -LikelyCategory 'Personal records directory' -SuggestedTopLevelFolder '25_PERSONAL' -Notes ("Matched directory keyword '{0}' in directory name." -f $namePersonalKeyword)
        }

        if ($pathPersonalKeyword) {
            return New-ClassificationResult -LikelyCategory 'Personal records directory' -SuggestedTopLevelFolder '25_PERSONAL' -Notes ("Matched path keyword '{0}' for a directory." -f $pathPersonalKeyword)
        }

        if ($nameOperationsKeyword) {
            return New-ClassificationResult -LikelyCategory 'Operational directory' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes ("Matched directory keyword '{0}' in directory name." -f $nameOperationsKeyword)
        }

        if ($pathOperationsKeyword) {
            return New-ClassificationResult -LikelyCategory 'Operational directory' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes ("Matched path keyword '{0}' for a directory." -f $pathOperationsKeyword)
        }

        if ($nameProjectKeyword) {
            return New-ClassificationResult -LikelyCategory 'Project directory' -SuggestedTopLevelFolder '10_PROJECTS' -Notes ("Matched directory keyword '{0}' in directory name." -f $nameProjectKeyword)
        }

        if ($pathProjectKeyword) {
            return New-ClassificationResult -LikelyCategory 'Project directory' -SuggestedTopLevelFolder '10_PROJECTS' -Notes ("Matched path keyword '{0}' for a directory." -f $pathProjectKeyword)
        }

        if ($nameHistoricalArchiveKeyword) {
            return New-ClassificationResult -LikelyCategory 'Archived directory' -SuggestedTopLevelFolder '90_ARCHIVE' -Notes ("Matched directory keyword '{0}' in directory name." -f $nameHistoricalArchiveKeyword)
        }

        return New-ClassificationResult -LikelyCategory 'Needs review' -SuggestedTopLevelFolder '00_INBOX' -Notes 'Fallback review: no strong directory keyword matched.'
    }

    if ($shortcutExtensions -contains $extension) {
        if ($pathSystemKeyword -or $nameSystemKeyword) {
            $matchedKeyword = if ($nameSystemKeyword) { $nameSystemKeyword } else { $pathSystemKeyword }
            return New-ClassificationResult -LikelyCategory 'Shortcut or link to a technical location' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Shortcut rule: matched technical keyword '{0}'. Verify whether this belongs in system, reference, or operations." -f $matchedKeyword)
        }

        if ($pathOperationsKeyword -or $nameOperationsKeyword) {
            $matchedKeyword = if ($nameOperationsKeyword) { $nameOperationsKeyword } else { $pathOperationsKeyword }
            return New-ClassificationResult -LikelyCategory 'Shortcut or link to an operational location' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes ("Shortcut rule: matched operations keyword '{0}'. Verify whether this belongs in system, reference, or operations." -f $matchedKeyword)
        }

        if ($nameReferenceKeyword) {
            return New-ClassificationResult -LikelyCategory 'Shortcut or link to reference material' -SuggestedTopLevelFolder '40_REFERENCE' -Notes ("Shortcut rule: matched reference keyword '{0}'. Verify whether this belongs in system, reference, or operations." -f $nameReferenceKeyword)
        }

        return New-ClassificationResult -LikelyCategory 'Shortcut or link file' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes 'Shortcut rule: verify whether this belongs in system, reference, or operations.'
    }

    if ($archiveExtensions -contains $extension) {
        if ($nameMediaKeyword -or $pathMediaKeyword) {
            $matchedKeyword = if ($nameMediaKeyword) { $nameMediaKeyword } else { $pathMediaKeyword }
            return New-ClassificationResult -LikelyCategory 'Compressed media package' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Archive rule: matched media keyword '{0}' in archive name or path." -f $matchedKeyword)
        }

        if ($nameSystemKeyword -or $pathSystemKeyword) {
            $matchedKeyword = if ($nameSystemKeyword) { $nameSystemKeyword } else { $pathSystemKeyword }
            return New-ClassificationResult -LikelyCategory 'Compressed technical package' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Archive rule: matched technical keyword '{0}' in archive name or path." -f $matchedKeyword)
        }

        if ($nameHistoricalArchiveKeyword -or $pathHistoricalArchiveKeyword) {
            $matchedKeyword = if ($nameHistoricalArchiveKeyword) { $nameHistoricalArchiveKeyword } else { $pathHistoricalArchiveKeyword }
            return New-ClassificationResult -LikelyCategory 'Archived package or historical content' -SuggestedTopLevelFolder '90_ARCHIVE' -Notes ("Archive rule: matched archival keyword '{0}'." -f $matchedKeyword)
        }

        return New-ClassificationResult -LikelyCategory 'Compressed file requiring review' -SuggestedTopLevelFolder '00_INBOX' -Notes 'Archive rule: compressed file without a strong media, technical, or archival keyword match.'
    }

    if ($mediaExtensions -contains $extension) {
        return New-ClassificationResult -LikelyCategory 'Media asset' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Extension rule: matched media extension '{0}'." -f $extension)
    }

    if ($nameMediaKeyword) {
        return New-ClassificationResult -LikelyCategory 'Media or studio asset' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Matched file-name keyword '{0}'." -f $nameMediaKeyword)
    }

    if ($pathMediaKeyword) {
        return New-ClassificationResult -LikelyCategory 'Media or studio asset' -SuggestedTopLevelFolder '30_MEDIA' -Notes ("Matched path keyword '{0}' for a file." -f $pathMediaKeyword)
    }

    if ($systemExtensions -contains $extension) {
        return New-ClassificationResult -LikelyCategory 'System or technical asset' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Extension rule: matched technical extension '{0}'." -f $extension)
    }

    if ($nameSystemKeyword) {
        return New-ClassificationResult -LikelyCategory 'System or technical asset' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Matched file-name keyword '{0}'." -f $nameSystemKeyword)
    }

    if ($pathSystemKeyword) {
        return New-ClassificationResult -LikelyCategory 'System or technical asset' -SuggestedTopLevelFolder '50_SYSTEM' -Notes ("Matched path keyword '{0}' for a file." -f $pathSystemKeyword)
    }

    if ($namePersonalKeyword) {
        return New-ClassificationResult -LikelyCategory 'Personal record' -SuggestedTopLevelFolder '25_PERSONAL' -Notes ("Matched file-name keyword '{0}'." -f $namePersonalKeyword)
    }

    if ($pathPersonalKeyword) {
        return New-ClassificationResult -LikelyCategory 'Personal record' -SuggestedTopLevelFolder '25_PERSONAL' -Notes ("Matched path keyword '{0}' for a file." -f $pathPersonalKeyword)
    }

    if ($referenceExtensions -contains $extension) {
        return New-ClassificationResult -LikelyCategory 'Reference material' -SuggestedTopLevelFolder '40_REFERENCE' -Notes ("Extension rule: matched reference extension '{0}'." -f $extension)
    }

    if ($nameReferenceKeyword) {
        return New-ClassificationResult -LikelyCategory 'Reference material' -SuggestedTopLevelFolder '40_REFERENCE' -Notes ("Matched file-name keyword '{0}'." -f $nameReferenceKeyword)
    }

    if ($nameProjectKeyword) {
        return New-ClassificationResult -LikelyCategory 'Project material' -SuggestedTopLevelFolder '10_PROJECTS' -Notes ("Matched file-name keyword '{0}'." -f $nameProjectKeyword)
    }

    if ($pathProjectKeyword) {
        return New-ClassificationResult -LikelyCategory 'Project material' -SuggestedTopLevelFolder '10_PROJECTS' -Notes ("Matched path keyword '{0}' for a file." -f $pathProjectKeyword)
    }

    if ($nameOperationsKeyword) {
        return New-ClassificationResult -LikelyCategory 'Operational material' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes ("Matched file-name keyword '{0}'." -f $nameOperationsKeyword)
    }

    if ($pathOperationsKeyword) {
        return New-ClassificationResult -LikelyCategory 'Operational material' -SuggestedTopLevelFolder '20_OPERATIONS' -Notes ("Matched path keyword '{0}' for a file." -f $pathOperationsKeyword)
    }

    if ($nameHistoricalArchiveKeyword -or $pathHistoricalArchiveKeyword) {
        $matchedKeyword = if ($nameHistoricalArchiveKeyword) { $nameHistoricalArchiveKeyword } else { $pathHistoricalArchiveKeyword }
        return New-ClassificationResult -LikelyCategory 'Archived or historical material' -SuggestedTopLevelFolder '90_ARCHIVE' -Notes ("Path keyword: matched archival keyword '{0}'." -f $matchedKeyword)
    }

    return New-ClassificationResult -LikelyCategory 'Needs review' -SuggestedTopLevelFolder '00_INBOX' -Notes 'Fallback review: no strong file heuristic matched.'
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
