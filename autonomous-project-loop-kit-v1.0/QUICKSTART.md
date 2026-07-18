# Quick Start

```powershell
pwsh -NoProfile -File .\install-loop.ps1 -TargetRepo "C:\path\to\repo"
cd C:\path\to\repo
notepad .\loop.config.json
notepad .\PROJECT_BACKLOG.json
pwsh -NoProfile -File .\validate-loop.ps1
pwsh -NoProfile -File .\run-loop.ps1 -DryRun
pwsh -NoProfile -File .\run-loop.ps1 -Provider codex
```

Stop:

```powershell
pwsh -NoProfile -File .\stop-loop.ps1
```

Check status:

```powershell
pwsh -NoProfile -File .\get-loop-status.ps1
```
