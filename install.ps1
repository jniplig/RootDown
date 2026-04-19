#Requires -Version 5.1
# RootDown bootstrap — Windows (PowerShell)

param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$DeployArgs
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonMinMajor = 3
$PythonMinMinor = 8

Write-Host "RootDown Bootstrap"
Write-Host "=================="
Write-Host ""

# ── Helpers ────────────────────────────────────────────────────────────────

function Write-Ok    { param($msg) Write-Host "[OK]    $msg" }
function Write-Info  { param($msg) Write-Host "[INFO]  $msg" }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-PythonVersion {
    param([string]$Cmd)
    $bin = Get-Command $Cmd -ErrorAction SilentlyContinue
    if (-not $bin) { return $null }
    try {
        $raw = & $Cmd --version 2>&1 | Select-Object -First 1
        if ($raw -match '(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -gt $PythonMinMajor -or
                ($major -eq $PythonMinMajor -and $minor -ge $PythonMinMinor)) {
                return @{ Cmd = $Cmd; Version = $raw.Trim() }
            }
        }
    } catch {}
    return $null
}

function Find-Python {
    foreach ($cmd in @('python', 'python3')) {
        $result = Test-PythonVersion $cmd
        if ($result) { return $result }
    }
    return $null
}

# ── Python check ───────────────────────────────────────────────────────────

$python = Find-Python

if ($python) {
    Write-Ok "Python confirmed: $($python.Version)"
} else {
    Write-Info "Python $PythonMinMajor.$PythonMinMinor+ not found. Attempting install via winget..."

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Err "winget not available. Install Python manually: https://www.python.org/downloads/"
        exit 1
    }

    try {
        winget install --id Python.Python.3 --silent --accept-package-agreements --accept-source-agreements
    } catch {
        Write-Err "winget install failed: $_"
        Write-Err "Install Python manually: https://www.python.org/downloads/"
        exit 1
    }

    # Refresh PATH so the new python is visible in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')

    $python = Find-Python
    if ($python) {
        Write-Ok "Python confirmed after install: $($python.Version)"
    } else {
        Write-Err "Python $PythonMinMajor.$PythonMinMinor+ still not found after install attempt."
        Write-Err "Install manually: https://www.python.org/downloads/"
        exit 1
    }
}

# ── Run deployer ───────────────────────────────────────────────────────────

Write-Host ""
Write-Info "Running RootDown deployer..."
Write-Host ""

$deployScript = Join-Path $ScriptDir "deploy.py"
& $python.Cmd $deployScript @DeployArgs
exit $LASTEXITCODE
