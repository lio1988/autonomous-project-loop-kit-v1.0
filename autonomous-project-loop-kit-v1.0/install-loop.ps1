[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TargetRepo,
    [switch]$Force,
    [switch]$IncludeGeminiPointer
)

Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
if($PSVersionTable.PSVersion.Major -lt 7){throw "PowerShell 7+ required."}

$source=(Resolve-Path -LiteralPath $PSScriptRoot).Path
$target=(Resolve-Path -LiteralPath $TargetRepo).Path
$stamp=[DateTime]::UtcNow.ToString("yyyyMMdd-HHmmss")
$backup=Join-Path $target ".loop-install-backup\$stamp"
New-Item -ItemType Directory -Force -Path $backup|Out-Null

function Backup([string]$Rel){
    $src=Join-Path $target $Rel
    if(-not(Test-Path -LiteralPath $src)){return}
    $dst=Join-Path $backup $Rel
    $parent=Split-Path -Parent $dst
    if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
}
function Copy-Payload([string]$Rel,[bool]$Preserve=$false){
    $src=Join-Path $source $Rel
    $dst=Join-Path $target $Rel

    if(-not(Test-Path -LiteralPath $src)){throw "Package file missing: $Rel"}

    # When the kit is already located in the target repository, there is
    # nothing to copy. Managed integration blocks are still installed below.
    if([System.IO.Path]::GetFullPath($src) -eq [System.IO.Path]::GetFullPath($dst)){
        Write-Host "Already in place: $Rel"
        return
    }

    if((Test-Path -LiteralPath $dst)-and $Preserve -and -not $Force){
        $newPath="$dst.loop-kit-new"
        if(Test-Path -LiteralPath $src -PathType Container){
            if(Test-Path -LiteralPath $newPath){Remove-Item -LiteralPath $newPath -Recurse -Force}
            New-Item -ItemType Directory -Force -Path $newPath|Out-Null
            Get-ChildItem -LiteralPath $src -Force | Copy-Item -Destination $newPath -Recurse -Force
        } else {
            Copy-Item -LiteralPath $src -Destination $newPath -Force
        }
        Write-Warning "Preserved $Rel; wrote $Rel.loop-kit-new"
        return
    }

    if(Test-Path -LiteralPath $dst){Backup $Rel}

    if(Test-Path -LiteralPath $src -PathType Container){
        New-Item -ItemType Directory -Force -Path $dst|Out-Null
        Get-ChildItem -LiteralPath $src -Force | Copy-Item -Destination $dst -Recurse -Force
    } else {
        $parent=Split-Path -Parent $dst
        if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }

    Write-Host "Installed $Rel"
}
function Set-Block([string]$Rel,[string]$Block,[string]$Start,[string]$End){
    $path=Join-Path $target $Rel; Backup $Rel
    $content=if(Test-Path -LiteralPath $path){Get-Content -LiteralPath $path -Raw -Encoding UTF8}else{""}
    $pattern="(?s)$([regex]::Escape($Start)).*?$([regex]::Escape($End))"
    if($content -match $pattern){$new=[regex]::Replace($content,$pattern,$Block)}
    else{$new=($content.TrimEnd()+"`r`n`r`n"+$Block).TrimStart()}
    $parent=Split-Path -Parent $path
    if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
    Set-Content -LiteralPath $path -Value ($new.TrimEnd()+"`r`n") -Encoding utf8NoBOM
}

foreach($item in @(
    "run-loop.ps1","validate-loop.ps1","stop-loop.ps1","get-loop-status.ps1","reset-loop-runtime.ps1",
    "README_GR.md","QUICKSTART.md","docs",".agent-loop"
)){Copy-Payload $item}

# Preserve repository-specific policy and state files unless -Force is explicit.
Copy-Payload "LOOPS.md" $true
Copy-Payload "loop.config.json" $true
Copy-Payload "PROJECT_BACKLOG.json" $true
Copy-Payload "PROJECT_PROGRESS.md" $true

# Initialize only the tracked placeholders under .loop; never replace runtime state.
Copy-Payload ".loop\README.md" $true
Copy-Payload ".loop\.gitkeep" $true
$runtimeProgress = Join-Path $target ".loop\progress.md"
if(-not(Test-Path -LiteralPath $runtimeProgress)){
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $runtimeProgress)|Out-Null
    Set-Content -LiteralPath $runtimeProgress -Value "# Runtime Progress`r`n" -Encoding utf8NoBOM
}

$agents=Get-Content (Join-Path $source ".agent-loop\integration\AGENTS.block.md") -Raw
$claude=Get-Content (Join-Path $source ".agent-loop\integration\CLAUDE.block.md") -Raw
Set-Block "AGENTS.md" $agents.Trim() "<!-- BEGIN AUTONOMOUS PROJECT LOOP -->" "<!-- END AUTONOMOUS PROJECT LOOP -->"
Set-Block "CLAUDE.md" $claude.Trim() "<!-- BEGIN AUTONOMOUS PROJECT LOOP -->" "<!-- END AUTONOMOUS PROJECT LOOP -->"

$cursorRel=".cursor\rules\autonomous-project-loop.mdc"
Backup $cursorRel
$cursorDst=Join-Path $target $cursorRel
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $cursorDst)|Out-Null
Copy-Item (Join-Path $source ".agent-loop\integration\cursor-rule.mdc") $cursorDst -Force

if($IncludeGeminiPointer){
    $gemini=Get-Content (Join-Path $source ".agent-loop\integration\GEMINI.block.md") -Raw
    Set-Block "GEMINI.md" $gemini.Trim() "<!-- BEGIN AUTONOMOUS PROJECT LOOP -->" "<!-- END AUTONOMOUS PROJECT LOOP -->"
}

$ignore=@"
# BEGIN AUTONOMOUS PROJECT LOOP
.loop/*
!.loop/README.md
!.loop/.gitkeep
.loop-install-backup/
.loop-archive/
# END AUTONOMOUS PROJECT LOOP
"@
Set-Block ".gitignore" $ignore.Trim() "# BEGIN AUTONOMOUS PROJECT LOOP" "# END AUTONOMOUS PROJECT LOOP"

Write-Host ""
Write-Host "Installation complete. Backups: $backup"
Write-Host "Next: review config/backlog, validate, commit infrastructure, then dry-run."
