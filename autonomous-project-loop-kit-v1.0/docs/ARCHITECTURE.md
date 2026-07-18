# Architecture

```text
AGENTS.md / CLAUDE.md / Cursor rule
                ↓
             LOOPS.md
                ↓
          run-loop.ps1
                ↓
         PROJECT_BACKLOG.json
                ↓
       fresh provider invocation
                ↓
          .loop/status.json
                ↓
      runner-owned verification
                ↓
     receipt + checkpoint + next task
```

The agent writes project artifacts and one terminal status. The runner owns task selection, attempts, task completion, path checks, control-plane restoration, verification, completion audits, and final completion.

Every provider call is a fresh process. Continuity lives in files and Git state rather than a single context window.

The default checkpoint strategy does not commit. It saves a binary patch, copies of changed/new files, deleted-file list, logs, status, backlog snapshot, and receipt.
