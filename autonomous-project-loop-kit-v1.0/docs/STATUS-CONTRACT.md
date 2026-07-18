# Status contract

```powershell
pwsh -NoProfile -File .\.agent-loop\set-loop-status.ps1 `
  -Status CONTINUE `
  -TaskId "TASK-001" `
  -Summary "Implemented and tested the selected task." `
  -TestStatus PASS `
  -CommandsRun @("pytest tests/unit/test_x.py -q") `
  -NextAction "Runner should verify and continue."
```

- `CONTINUE`: task ready for runner verification.
- `RETRY`: another bounded attempt is reasonable.
- `BLOCKED`: human/external input required.
- `COMPLETE`: only completion audit, task ID `GLOBAL-AUDIT`.
