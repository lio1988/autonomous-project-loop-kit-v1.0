# Validation record

Package version: 1.0.0

Completed before packaging:

- All JSON files parsed successfully.
- Example configuration and backlog files validated against the included JSON Schemas.
- Every PowerShell file parsed with a PowerShell tree-sitter grammar with no syntax-error nodes.
- Managed integration markers were checked.
- Required package files were checked.
- ZIP integrity is checked during packaging.

Not executed in the artifact-building environment:

- The PowerShell mock-provider end-to-end self-test, because that environment did not provide a `pwsh` runtime.

Run the included end-to-end test on the target Windows machine before using a real provider:

```powershell
pwsh -NoProfile -File .\tests\self-test.ps1
```

Then run one or two supervised real-provider iterations before an unattended run.
