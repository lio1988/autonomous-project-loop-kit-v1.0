# Autonomous Project Loop Kit

A repository-local outer loop for completing large software projects through a sequence of fresh coding-agent sessions.

The agent process may end after every iteration. `run-loop.ps1` remains the conductor: it reloads durable state, selects the next bounded task, invokes a fresh agent, verifies the result, records a receipt, and continues until the project is verified complete or safely blocked.

## Core properties

- Fresh agent context per iteration
- Durable task, progress, and receipt files
- Deterministic task selection from `PROJECT_BACKLOG.json`
- Runner-side verification commands
- Completion audits after the backlog is exhausted
- Explicit `CONTINUE`, `RETRY`, `BLOCKED`, and `COMPLETE` states
- Dedicated local loop branch by default
- No automatic push, pull request, or merge
- Protected control-plane files
- Path allowlists and denylists per task
- Time, iteration, retry, and stall limits
- Explicit provider/model recording
- Codex CLI, Claude Code, Cursor CLI, and custom adapters
- Idempotent integration with `AGENTS.md`, `CLAUDE.md`, Cursor rules, and `.gitignore`

## Requirements

- PowerShell 7+ (`pwsh`)
- Git
- At least one authenticated coding-agent CLI
- A Git repository with at least one commit

## Install

Extract the ZIP outside the target repository, then run:

```powershell
pwsh -NoProfile -File .\install-loop.ps1 `
  -TargetRepo "C:\path\to\your-project"
```

The installer backs up existing files, adds managed pointer blocks to `AGENTS.md` and `CLAUDE.md`, adds a Cursor rule, and does not overwrite an existing config/backlog unless `-Force` is supplied.

Review and commit the installed infrastructure before starting.

## Configure

Edit:

- `loop.config.json`
- `PROJECT_BACKLOG.json`
- project-specific additions to `LOOPS.md`

The default backlog starts with a planning-only bootstrap task. The first agent may inspect the repository and create a bounded completion backlog, but it may not edit source code during bootstrap.

## Validate and run

```powershell
pwsh -NoProfile -File .\validate-loop.ps1
pwsh -NoProfile -File .\run-loop.ps1 -DryRun
pwsh -NoProfile -File .\run-loop.ps1 -Provider codex
```

Other providers:

```powershell
pwsh -NoProfile -File .\run-loop.ps1 -Provider claude
pwsh -NoProfile -File .\run-loop.ps1 -Provider cursor
```

## Stop safely

```powershell
pwsh -NoProfile -File .\stop-loop.ps1
```

The runner checks `.loop/STOP` before each new invocation. Restarting `run-loop.ps1` resumes from durable state.

## Work iteration

1. Acquire a single-process lock.
2. Create a dedicated branch if the current branch is protected.
3. Select the highest-priority ready task whose dependencies are done.
4. Write `.loop/selected-task.json` and `.loop/current-prompt.md`.
5. Invoke one fresh coding-agent process.
6. The agent performs exactly one selected task.
7. The agent writes `.loop/status.json`.
8. The runner validates status, task identity, Git HEAD, control-plane integrity, path policy, `git diff --check`, and task verification commands.
9. Only the runner marks the task `DONE`.
10. Save logs, a receipt, a patch, and copies of changed files.
11. Start the next fresh agent.

## Completion protocol

An agent cannot finish the project merely by saying “complete.”

When no required tasks remain, the runner enters completion-audit mode. A fresh audit agent must inspect the project without changing project files. The runner then requires:

- all required tasks `DONE` or explicitly `WAIVED`,
- global completion commands passing,
- no workspace changes during audit,
- the configured number of consecutive completion confirmations,
- a stable workspace fingerprint.

A failed audit becomes a remediation task. A real ambiguity becomes `BLOCKED`.

## Provider notes

- **Codex:** non-interactive `codex exec` with explicit sandbox.
- **Claude:** print mode (`claude -p`); unattended permissions must be configured. Unsafe permission skipping is off by default.
- **Cursor:** headless print mode; implementation uses `--force`, audit omits it.
- **Custom:** explicit command adapter; disabled by default.

## Safety defaults

The kit blocks or refuses:

- concurrent runners,
- protected-branch work without a dedicated branch,
- malformed/missing status,
- source edits during completion audit,
- changes outside task scope,
- changes to protected paths,
- agent-created commits,
- automatic push/merge,
- completion with unfinished tasks,
- completion without objective verification evidence,
- repeated failures beyond configured limits.

## Runtime state

Mutable state is under `.loop/`:

```text
.loop/ACTIVE
.loop/run-state.json
.loop/status.json
.loop/selected-task.json
.loop/current-prompt.md
.loop/progress.md
.loop/logs/
.loop/receipts/
.loop/checkpoints/
```

## Self-test

```powershell
pwsh -NoProfile -File .\tests\self-test.ps1
```

This uses a mock provider and does not call an AI service.

## License

MIT.
