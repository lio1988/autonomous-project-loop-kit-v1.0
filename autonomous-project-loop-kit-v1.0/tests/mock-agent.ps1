[CmdletBinding()]
param(
    [ValidateSet("implement", "audit")]
    [string]$Role = "implement"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$statusHelper = Join-Path $repo ".agent-loop\set-loop-status.ps1"

if ($Role -eq "audit") {
    & pwsh -NoProfile -File $statusHelper `
        -Status COMPLETE `
        -TaskId "GLOBAL-AUDIT" `
        -Summary "Mock completion audit passed." `
        -TestStatus PASS `
        -CommandsRun @("mock-audit")
    exit $LASTEXITCODE
}

$taskPath = Join-Path $repo ".loop\selected-task.json"
$task = Get-Content -LiteralPath $taskPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
$samplePath = Join-Path $repo "sample.txt"
Add-Content -LiteralPath $samplePath -Value ([string]$task.id) -Encoding utf8NoBOM

& pwsh -NoProfile -File $statusHelper `
    -Status CONTINUE `
    -TaskId ([string]$task.id) `
    -Summary "Mock task completed." `
    -TestStatus PASS `
    -CommandsRun @("mock")
exit $LASTEXITCODE
