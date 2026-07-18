# Provider adapters

Routing is explicit. The runner does not silently substitute providers.

```json
{
  "provider_sequence": ["claude", "codex"],
  "audit_provider_sequence": ["codex", "claude"]
}
```

Receipts record configured provider and model.

## Codex

Uses `codex exec` with explicit sandbox, JSON event output, and optional ephemeral sessions.

## Claude Code

Uses `claude -p` JSON print mode. Configure unattended tool permissions in project settings or `allowed_tools`. Unsafe permission skipping is disabled by default.

## Cursor CLI

Uses headless print mode. Implementation and audit use `--force` so the agent can write `.loop/status.json`; audit-time project changes are detected and restored.

## Custom

Enable `provider_options.custom`, provide command and argument arrays, and ensure the process reads `.loop/current-prompt.md` and writes `.loop/status.json`.
