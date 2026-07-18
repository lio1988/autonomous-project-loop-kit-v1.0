[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [string]$RepoRoot = $PSScriptRoot,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$loopDir = Join-Path $repo ".loop"
$lockPath = Join-Path $loopDir "runner.lock"

if (-not (Test-Path -LiteralPath $loopDir)) {
    Write-Host "No .loop runtime directory exists."
    exit 0
}

if (Test-Path -LiteralPath $lockPath) {
    try {
        $lock = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
        $process = Get-Process -Id ([int]$lock.pid) -ErrorAction SilentlyContinue
        if ($null -ne $process) {
            throw "A loop runner is active with PID $($lock.pid). Stop it before resetting runtime state."
        }
    }
    catch {
        if (-not $Force) {
            throw "A runner lock exists and could not be proven stale. Use -Force only after checking that no runner is active."
        }
    }
}

$timestamp = [DateTime]::UtcNow.ToString("yyyyMMdd-HHmmss")
$archiveRoot = Join-Path $repo ".loop-archive\$timestamp"

if (-not $Force -and -not $PSCmdlet.ShouldProcess($loopDir, "Archive and reset loop runtime state")) {
    return
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archiveRoot) | Out-Null
Move-Item -LiteralPath $loopDir -Destination $archiveRoot
New-Item -ItemType Directory -Force -Path $loopDir | Out-Null

$readmeSource = Join-Path $archiveRoot "README.md"
if (Test-Path -LiteralPath $readmeSource) {
    Copy-Item -LiteralPath $readmeSource -Destination (Join-Path $loopDir "README.md") -Force
}
else {
    Set-Content -LiteralPath (Join-Path $loopDir "README.md") `
        -Value "# Loop runtime directory`r`n" -Encoding utf8NoBOM
}

New-Item -ItemType File -Force -Path (Join-Path $loopDir ".gitkeep") | Out-Null
Set-Content -LiteralPath (Join-Path $loopDir "progress.md") `
    -Value "# Runtime Progress`r`n" -Encoding utf8NoBOM

Write-Host "Loop runtime archived to: $archiveRoot"
Write-Host "Backlog task statuses were not changed."
Write-Host "Review PROJECT_BACKLOG.json before starting a new run."
