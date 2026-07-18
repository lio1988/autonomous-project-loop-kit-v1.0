# Prototype character

This package is a practical prototype of a repository-native autonomous project-completion protocol.

The individual ideas are not all new in isolation:

- fresh coding-agent sessions,
- Ralph-style task relays,
- file-based memory,
- CI verification,
- repository instruction files,
- external process loops.

The distinctive design is their combination into a small, provider-agnostic control plane with:

- conditional activation through standard agent instruction files,
- a general `LOOPS.md` contract,
- runner-owned task selection and completion,
- explicit status files rather than free-text completion claims,
- protection and restoration of the loop's own control files,
- per-iteration workspace-delta policy despite cumulative uncommitted work,
- no-push/no-merge/no-agent-commit defaults,
- completion audits by fresh agent sessions,
- stable workspace fingerprints across consecutive audits,
- local evidence receipts and recovery checkpoints.

It should be treated as an experimental engineering system until it has passed the included self-test and supervised trials in the target repository.
