[CmdletBinding()]
param(
    [string]$RepoRoot = $PSScriptRoot,
    [string]$ConfigPath = "loop.config.json",
    [switch]$BacklogOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Ok([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Read-Json([string]$Path) {
    Assert-Ok (Test-Path -LiteralPath $Path) "Missing file: $Path"
    try { Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100 }
    catch { throw "Invalid JSON in ${Path}: $($_.Exception.Message)" }
}
function Assert-NoCycles($Backlog) {
    $map=@{}; foreach($t in @($Backlog.tasks)){$map[[string]$t.id]=$t}
    $visiting=@{}; $visited=@{}
    function Visit([string]$Id) {
        if($visited.ContainsKey($Id)){return}
        if($visiting.ContainsKey($Id)){throw "Dependency cycle at '$Id'."}
        $visiting[$Id]=$true
        foreach($dep in @($map[$Id].dependencies)){
            Assert-Ok $map.ContainsKey([string]$dep) "Task '$Id' depends on missing '$dep'."
            Visit ([string]$dep)
        }
        $visiting.Remove($Id); $visited[$Id]=$true
    }
    foreach($id in $map.Keys){Visit $id}
}

Assert-Ok ($PSVersionTable.PSVersion.Major -ge 7) "PowerShell 7+ required."
$repo=(Resolve-Path -LiteralPath $RepoRoot).Path
$backlog=Read-Json (Join-Path $repo "PROJECT_BACKLOG.json")
Assert-Ok ([string]$backlog.schema_version -eq "1.0") "Unsupported backlog schema."
Assert-Ok (@($backlog.tasks).Count -gt 0) "Backlog is empty."

$ids=@{}; $valid=@("PENDING","READY","IN_PROGRESS","DONE","RETRY","BLOCKED","WAIVED")
foreach($task in @($backlog.tasks)){
    $id=[string]$task.id
    Assert-Ok (-not [string]::IsNullOrWhiteSpace($id)) "Task without ID."
    Assert-Ok (-not $ids.ContainsKey($id)) "Duplicate task ID: $id"
    $ids[$id]=$true
    Assert-Ok ($valid -contains [string]$task.status) "Invalid status on '$id'."
    Assert-Ok ([int]$task.max_attempts -ge 1) "Invalid max_attempts on '$id'."
    Assert-Ok ([int]$task.attempts -ge 0) "Invalid attempts on '$id'."
    Assert-Ok (@($task.acceptance_criteria).Count -gt 0) "No acceptance criteria on '$id'."
}
Assert-NoCycles $backlog

if($BacklogOnly){
    Write-Host "Backlog validation: PASS ($(@($backlog.tasks).Count) tasks)"
    exit 0
}

$config=Read-Json (Join-Path $repo $ConfigPath)
Assert-Ok ([string]$config.schema_version -eq "1.0") "Unsupported config schema."
Assert-Ok (@($config.provider_sequence).Count -gt 0) "provider_sequence is empty."
Assert-Ok (@($config.audit_provider_sequence).Count -gt 0) "audit_provider_sequence is empty."
Assert-Ok ([int]$config.completion_confirmation_runs -ge 1) "completion_confirmation_runs must be >= 1."

foreach($file in @(
    "LOOPS.md","run-loop.ps1","stop-loop.ps1",
    ".agent-loop\loop-lib.ps1",".agent-loop\set-loop-status.ps1",
    ".agent-loop\prompts\implementer.md",".agent-loop\prompts\auditor.md"
)){
    Assert-Ok (Test-Path -LiteralPath (Join-Path $repo $file)) "Missing required file: $file"
}

Assert-Ok ($null -ne (Get-Command git -ErrorAction SilentlyContinue)) "Git not found."
Push-Location $repo
try {
    & git rev-parse --is-inside-work-tree *> $null
    Assert-Ok ($LASTEXITCODE -eq 0) "Not a Git repository."
    & git rev-parse HEAD *> $null
    Assert-Ok ($LASTEXITCODE -eq 0) "Repository needs at least one commit."
} finally { Pop-Location }

$providers=@($config.provider_sequence)+@($config.audit_provider_sequence)|Select-Object -Unique
foreach($provider in $providers){
    if($provider -eq "custom"){
        Assert-Ok ([bool]$config.provider_options.custom.enabled) "Custom provider selected but disabled."
        $cmd=[string]$config.provider_options.custom.command
    } else {
        $options=$config.provider_options.$provider
        Assert-Ok ($null -ne $options) "Missing provider config: $provider"
        $cmd=[string]$options.command
    }
    Assert-Ok ($null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)) "Provider command '$cmd' not found."
}

Write-Host "Loop validation: PASS"
Write-Host "Tasks: $(@($backlog.tasks).Count)"
Write-Host "Providers: $(@($config.provider_sequence)-join ', ')"
