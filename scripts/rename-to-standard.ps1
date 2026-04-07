<#
.SYNOPSIS
Proposes or applies conservative filename normalization to the K6 standard.

.DESCRIPTION
Scans files in a target path and proposes filenames using this pattern:
  YYYY-MM-DD_Area_Item_Descriptor_v01.ext

The script defaults to dry-run behavior. It only renames files when -Apply is
explicitly supplied. Existing compliant filenames are skipped. If the script
cannot infer a date or approved Area value with sufficient confidence, it marks
the item for ManualReview instead of guessing.

.PARAMETER Path
Root path to scan for files.

.PARAMETER Apply
Actually perform renames. Without this switch, the script reports proposals
only and does not change any files.

.PARAMETER UseToday
Use today's date when no date can be inferred from the filename.

.PARAMETER Recurse
Scan files recursively beneath -Path.

.PARAMETER ReportPath
Optional CSV output path. Defaults to a timestamped CSV in the current
directory.

.EXAMPLE
.\scripts\rename-to-standard.ps1 -Path C:\Data\00_INBOX

Dry-run the files directly in C:\Data\00_INBOX.

.EXAMPLE
.\scripts\rename-to-standard.ps1 -Path C:\Data\00_INBOX -Recurse -UseToday -ReportPath .\rename-report.csv

Generate rename proposals recursively and use today's date when none can be
inferred.

.EXAMPLE
.\scripts\rename-to-standard.ps1 -Path C:\Data\00_INBOX -Recurse -Apply

Apply approved rename proposals recursively. Conflicts and uncertain items are
still left unchanged.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [switch]$UseToday,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [string]$ReportPath = (Join-Path -Path (Get-Location) -ChildPath ("rename-report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ApprovedAreas = @('Teaching', 'InsightEdu', 'Studio', 'Systems', 'Personal')
$ApprovedAreaMap = @{
    'teaching'   = 'Teaching'
    'insightedu' = 'InsightEdu'
    'studio'     = 'Studio'
    'systems'    = 'Systems'
    'personal'   = 'Personal'
}

$CompliantPattern = '^\d{4}-\d{2}-\d{2}_(Teaching|InsightEdu|Studio|Systems|Personal)_[A-Za-z0-9-]+_[A-Za-z0-9-]+_v\d{2}$'

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host $Message
}

function Convert-ToSlug {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    # Normalize human-entered names into conservative filename-safe segments.
    $normalized = $Value -replace '[ _]+', '-'
    $normalized = $normalized -replace '[^A-Za-z0-9-]', '-'
    $normalized = $normalized -replace '-{2,}', '-'
    $normalized = $normalized.Trim('-')

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $null
    }

    return $normalized
}

function Get-InferredArea {
    param(
        [Parameter(Mandatory)]
        [string]$FullPath,

        [Parameter(Mandatory)]
        [string]$BaseName
    )

    # Check both the full path and the filename so simple folder-based sorting
    # conventions can assist classification.
    $candidates = @($FullPath, $BaseName)
    foreach ($candidate in $candidates) {
        $lowerValue = $candidate.ToLowerInvariant()
        foreach ($key in $ApprovedAreaMap.Keys) {
            if ($lowerValue -match "(^|[^a-z])$key([^a-z]|$)") {
                return $ApprovedAreaMap[$key]
            }
        }
    }

    return $null
}

function Get-InferredDate {
    param(
        [Parameter(Mandatory)]
        [string]$BaseName,

        [Parameter(Mandatory)]
        [bool]$AllowTodayFallback
    )

    # Only infer a date when an obvious YYYY-MM-DD style sequence exists.
    if ($BaseName -match '(?<year>20\d{2})[-_\.]?(?<month>\d{2})[-_\.]?(?<day>\d{2})') {
        try {
            return (Get-Date -Year $Matches.year -Month $Matches.month -Day $Matches.day).ToString('yyyy-MM-dd')
        }
        catch {
            return $null
        }
    }

    if ($AllowTodayFallback) {
        return (Get-Date).ToString('yyyy-MM-dd')
    }

    return $null
}

function Get-ItemAndDescriptor {
    param(
        [Parameter(Mandatory)]
        [string]$BaseName,

        [Parameter(Mandatory)]
        [string]$Area
    )

    # Remove parts already accounted for elsewhere in the standard filename.
    $working = $BaseName

    $working = $working -replace '^(20\d{2})[-_\.]?(0[1-9]|1[0-2])[-_\.]?([0-2]\d|3[0-1])', ''
    $working = $working -replace "(?i)\b$([regex]::Escape($Area))\b", ''
    $working = $working -replace '(?i)\bv\d{1,2}\b', ''
    $working = $working -replace '[\._]+', ' '
    $working = $working -replace '\s+', ' '
    $working = $working.Trim()

    if ([string]::IsNullOrWhiteSpace($working)) {
        return $null
    }

    # Keep the heuristic conservative: if there are not enough meaningful
    # segments to split into Item and Descriptor, require manual review.
    $segments = $working -split '[- ]+' | Where-Object { $_ }
    if ($segments.Count -lt 2) {
        return $null
    }

    $itemCount = if ($segments.Count -ge 4) { 2 } else { 1 }
    $item = Convert-ToSlug -Value (($segments | Select-Object -First $itemCount) -join '-')
    $descriptor = Convert-ToSlug -Value (($segments | Select-Object -Skip $itemCount) -join '-')

    if ([string]::IsNullOrWhiteSpace($item) -or [string]::IsNullOrWhiteSpace($descriptor)) {
        return $null
    }

    return [pscustomobject]@{
        Item       = $item
        Descriptor = $descriptor
    }
}

if (-not (Test-Path -LiteralPath $Path)) {
    throw "The path does not exist: $Path"
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
Write-Log "Scan path: $resolvedPath"
Write-Log ("Mode: {0}" -f ($(if ($Apply) { 'apply' } else { 'dry-run' })))

$childParams = @{
    LiteralPath = $resolvedPath
    File        = $true
}

if ($Recurse) {
    $childParams['Recurse'] = $true
}

$files = Get-ChildItem @childParams
$results = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    $baseName = $file.BaseName
    $extension = $file.Extension
    $status = 'Skipped'
    $reason = ''
    $proposedName = ''

    # Existing compliant names are reported but never touched.
    if ($baseName -match $CompliantPattern) {
        $status = 'AlreadyCompliant'
        $reason = 'Filename already matches the approved pattern.'
    }
    else {
        $area = Get-InferredArea -FullPath $file.FullName -BaseName $baseName
        if (-not $area) {
            $status = 'ManualReview'
            $reason = 'Approved Area could not be inferred from the file path or name.'
        }
        else {
            $dateValue = Get-InferredDate -BaseName $baseName -AllowTodayFallback $UseToday.IsPresent
            if (-not $dateValue) {
                $status = 'ManualReview'
                $reason = 'Date could not be inferred and -UseToday was not supplied.'
            }
            else {
                $nameParts = Get-ItemAndDescriptor -BaseName $baseName -Area $area
                if (-not $nameParts) {
                    $status = 'ManualReview'
                    $reason = 'Item and Descriptor could not be derived conservatively.'
                }
                else {
                    $proposedName = '{0}_{1}_{2}_{3}_v01{4}' -f $dateValue, $area, $nameParts.Item, $nameParts.Descriptor, $extension
                    $targetPath = Join-Path -Path $file.DirectoryName -ChildPath $proposedName

                    if ($file.Name -eq $proposedName) {
                        $status = 'AlreadyCompliant'
                        $reason = 'Filename is already compliant after normalization.'
                    }
                    elseif (Test-Path -LiteralPath $targetPath) {
                        $status = 'Conflict'
                        $reason = 'A file with the proposed target name already exists.'
                    }
                    elseif ($Apply) {
                        Rename-Item -LiteralPath $file.FullName -NewName $proposedName
                        $status = 'Renamed'
                        $reason = 'Rename applied successfully.'
                    }
                    else {
                        $status = 'Proposed'
                        $reason = 'Dry-run only. Rename not applied.'
                    }
                }
            }
        }
    }

    if (-not $proposedName) {
        $proposedName = $file.Name
    }

    $results.Add([pscustomobject]@{
        OriginalPath = $file.FullName
        OriginalName = $file.Name
        ProposedName = $proposedName
        Status       = $status
        Reason       = $reason
    })

    Write-Log ("[{0}] {1} -> {2}" -f $status, $file.Name, $proposedName)
}

$reportDirectory = Split-Path -Path $ReportPath -Parent
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    $null = New-Item -ItemType Directory -Path $reportDirectory -Force
}

$results | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
Write-Log "CSV report written to: $ReportPath"
Write-Log ("Processed files: {0}" -f $results.Count)
