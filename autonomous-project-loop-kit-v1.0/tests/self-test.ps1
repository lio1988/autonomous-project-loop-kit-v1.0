[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7 or newer is required."
}

$kitRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-loop-selftest-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
    Get-ChildItem -LiteralPath $kitRoot -Force |
        Where-Object { $_.Name -ne ".loop-install-backup" } |
        Copy-Item -Destination $tempRoot -Recurse -Force

    Copy-Item -LiteralPath (Join-Path $tempRoot "tests\loop.config.selftest.json") `
        -Destination (Join-Path $tempRoot "loop.config.json") -Force
    Copy-Item -LiteralPath (Join-Path $tempRoot "tests\PROJECT_BACKLOG.selftest.json") `
        -Destination (Join-Path $tempRoot "PROJECT_BACKLOG.json") -Force

    Push-Location $tempRoot
    try {
        & git init | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git init failed." }

        & git config user.email "loop-selftest@example.invalid"
        & git config user.name "Loop Self Test"
        & git add .
        & git commit -m "Initial self-test repository" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Initial test commit failed." }

        & pwsh -NoProfile -File .\run-loop.ps1 -Provider custom
        if ($LASTEXITCODE -ne 0) {
            throw "Runner self-test failed with exit code $LASTEXITCODE."
        }

        if (-not (Test-Path -LiteralPath ".loop\FINAL-COMPLETION.json")) {
            throw "Final completion receipt was not created."
        }

        $resultBacklog = Get-Content -LiteralPath "PROJECT_BACKLOG.json" -Raw -Encoding UTF8 |
            ConvertFrom-Json -Depth 100
        foreach ($item in @($resultBacklog.tasks)) {
            if ([string]$item.status -ne "DONE") {
                throw "Task $($item.id) was not marked DONE."
            }
        }

        $content = Get-Content -LiteralPath "sample.txt" -Raw -Encoding UTF8
        if ($content -notmatch "TEST-001" -or $content -notmatch "TEST-002") {
            throw "Mock tasks did not both update sample.txt."
        }

        Write-Host "SELF-TEST PASS"
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
