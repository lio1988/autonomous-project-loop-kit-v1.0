# Customization checklist

Before an unattended run:

1. Replace project-name placeholders.
2. Review/replace the bootstrap backlog.
3. Add objective verification commands to every implementation task.
4. Add complete global completion commands.
5. Tighten protected paths.
6. Set exact model IDs when reproducibility matters.
7. Configure Claude tool permissions if used.
8. Set iteration, runtime, and retry budgets.
9. Add project-specific completion conditions to `LOOPS.md`.
10. Validate and commit the infrastructure.
11. Run supervised iterations before an overnight run.

Example:

```json
{
  "global_completion_commands": [
    "python -m pytest -q",
    "git diff --check"
  ]
}
```

For a deliberately unbounded run, set `max_iterations` and `max_total_hours` to `0`; do not disable the failure, policy, approval, or stop-sentinel safeguards.
