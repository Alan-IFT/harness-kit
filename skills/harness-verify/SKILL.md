---
name: harness-verify
description: Run the project's total verification (scripts/verify_all). Use when any agent claims a task is done. Returns PASS / WARN / FAIL with structured report.
allowed-tools: Bash, PowerShell, Read, Write
---

# /harness-verify

Single command to invoke `scripts/verify_all` and capture the result.

## Procedure

1. Detect OS:
   - Windows → `pwsh -File scripts/verify_all.ps1`
   - Unix-like → `bash scripts/verify_all.sh`
2. If neither script exists → tell user the project isn't Harness-initialized; suggest `/harness-init` or `/harness-adopt`.
3. Capture stdout + stderr.
4. Parse exit code:
   - `0` → PASS
   - `1` → WARN
   - `2` → FAIL
5. If a task folder is active (`docs/features/<slug>/` exists with stages in progress), append the report to that task's `04_DEVELOPMENT.md`.
6. Print summary to the user:

```
verify_all: PASS
  - 12 checks: 11 PASS, 1 WARN, 0 FAIL
  - History appended: scripts/verification_history.log
```

or on failure:

```
verify_all: FAIL (2 failures)
  - B.3 Unit tests pass — 3 tests failed (see scripts/last_run.log)
  - E.3 Agent definitions present — qa-tester.md missing

Recommendation: route back to the developer / fix the missing agent.
```

## Options

- `--quick` skip slow checks (e2e). Forwarded to the underlying script.

## Hard rules

- Never modify `scripts/verify_all.*` to bypass a check.
- Never delete tests to make this pass.
- On WARN, the task may proceed but warnings must be logged.
- On FAIL, the task is not done. Do not declare delivery.
