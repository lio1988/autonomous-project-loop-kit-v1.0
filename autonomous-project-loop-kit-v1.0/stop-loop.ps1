[CmdletBinding()]
param(
    [string]$RepoRoot = $PSScriptRoot,
    [string]$Reason = "Human requested a safe stop."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$loopDir = Join-Path $repo ".loop"
New-Item -ItemType Directory -Force -Path $loopDir | Out-Null
[ordered]@{
    requested_at_utc = [DateTime]::UtcNow.ToString("o")
    reason = $Reason
    requested_by = $env:USERNAME
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $loopDir "STOP") -Encoding utf8NoBOM
Write-Host "Stop requested. Runner will stop before the next agent invocation."
