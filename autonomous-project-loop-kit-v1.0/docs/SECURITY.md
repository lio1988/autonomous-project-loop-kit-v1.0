# Security model

The runner detects and blocks policy violations, but it cannot fully contain a local agent launched with unrestricted host access.

Recommended:

1. Dedicated loop branch.
2. Clean starting tree.
3. No secrets in the repository.
4. Narrow provider sandbox/allowed tools.
5. No Git credentials exposed to the agent process.
6. No automatic push/merge.
7. Human review before publishing.

Provider guidance:

- Codex: `workspace-write`, never `danger-full-access` for normal use.
- Claude: project-level allowed tools; keep unsafe permission skipping off.
- Cursor: `--force` applies edits, so use a dedicated branch.
- Custom: command and arguments are trusted configuration.

Control files are backed up and unauthorized edits restored. Secret files are not copied into runtime backups.
