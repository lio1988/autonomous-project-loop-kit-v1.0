[CmdletBinding()]
param(
    [string]$RepoRoot = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$backlogPath = Join-Path $repo "PROJECT_BACKLOG.json"
$statePath = Join-Path $repo ".loop\run-state.json"
$finalPath = Join-Path $repo ".loop\FINAL-COMPLETION.json"

if (-not (Test-Path -LiteralPath $backlogPath)) {
    throw "Missing PROJECT_BACKLOG.json."
}

$backlog = Get-Content -LiteralPath $backlogPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
$groups = @($backlog.tasks | Group-Object status | Sort-Object Name)

Write-Host "Project: $($backlog.project_name)"
Write-Host "Goal: $($backlog.project_goal)"
Write-Host ""
Write-Host "Task counts:"
foreach ($group in $groups) {
    Write-Host ("  {0,-12} {1,4}" -f $group.Name, $group.Count)
}

if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
    Write-Host ""
    Write-Host "Run ID: $($state.run_id)"
    Write-Host "Branch: $($state.branch)"
    Write-Host "Iteration: $($state.iteration)"
    Write-Host "Phase: $($state.phase)"
    Write-Host "Last task: $($state.last_task_id)"
    Write-Host "Last provider: $($state.last_provider)"
    Write-Host "Completion confirmations: $($state.completion_confirmations)"
}
else {
    Write-Host ""
    Write-Host "No active or resumable run state."
}

$next = @(
    $backlog.tasks |
    Where-Object { @("READY","PENDING","RETRY","BLOCKED","IN_PROGRESS") -contains [string]$_.status } |
    Sort-Object @{Expression={[int]$_.priority}}, @{Expression={[string]$_.id}}
) | Select-Object -First 10

if (@($next).Count -gt 0) {
    Write-Host ""
    Write-Host "Open tasks:"
    foreach ($task in $next) {
        Write-Host ("  [{0}] {1} — {2}" -f $task.status, $task.id, $task.title)
    }
}

if (Test-Path -LiteralPath $finalPath) {
    Write-Host ""
    Write-Host "FINAL COMPLETION RECEIPT EXISTS"
    Write-Host $finalPath
}
