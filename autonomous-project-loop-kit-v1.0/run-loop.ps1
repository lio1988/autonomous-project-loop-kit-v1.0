[CmdletBinding()]
param(
    [string]$ConfigPath = "loop.config.json",
    [ValidateSet("auto", "codex", "claude", "cursor", "custom")]
    [string]$Provider = "auto",
    [int]$MaxIterations = -1,
    [switch]$DryRun,
    [switch]$AllowDirtyStart,
    [switch]$BreakStaleLock,
    [switch]$ClearStop
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$libraryPath = Join-Path $repoRoot ".agent-loop\loop-lib.ps1"
if (-not (Test-Path -LiteralPath $libraryPath)) { throw "Missing loop library: $libraryPath" }

. $libraryPath

$providerOverride = if ($Provider -eq "auto") { "" } else { $Provider }

Invoke-AutonomousProjectLoop `
    -RepoRoot $repoRoot `
    -ConfigPath $ConfigPath `
    -ProviderOverride $providerOverride `
    -MaxIterationsOverride $MaxIterations `
    -DryRun:$DryRun `
    -AllowDirtyStart:$AllowDirtyStart `
    -BreakStaleLock:$BreakStaleLock `
    -ClearStop:$ClearStop
