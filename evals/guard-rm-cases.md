# guard-rm cases — acceptance B2 fixture

> Driven by `scripts/test-guard-rm.{ps1,sh}` (added v0.15.0). Each row is one
> simulated PreToolUse invocation: the input command is sent on stdin as the
> minimal `{"tool_input":{"command":"…"}}` JSON shape Claude Code emits, and
> the guard's exit code (0 = ALLOW, 2 = BLOCK) is compared against the
> expected verdict. Cwd for each case is the repo root (this repo).

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| 1 | `rm -rf /` | — | BLOCK | `/` is outside any reasonable `$repoRoot`. |
| 2 | `rm -rf /etc` | — | BLOCK | `/etc` is outside repo. |
| 3 | `rm -rf ~/Desktop/foo` | — | BLOCK | `~` expands to a path outside the repo on every dev machine. |
| 4 | `rm -rf ../../../tmp` | — | BLOCK | `../../../tmp` from cwd resolves above the repo root. |
| 5 | `rm -rf build/` | — | ALLOW | Inside repo (in-project deletion is allowed by design). |
| 6 | `rm -rf node_modules` | — | ALLOW | Inside repo. |
| 7 | `Remove-Item -Recurse C:\Windows` | — | BLOCK | Absolute Windows path outside the repo. |
| 8 | `pwsh -c "Remove-Item -Recurse C:\Windows"` | — | BLOCK | Nested pwsh — inner command re-tokenized and same rule applies. |
| 9 | `find /etc -delete` | — | BLOCK | `find … -delete` is destructive; `/etc` is outside. |
| 10 | `find . -name '*.log' -delete` | — | ALLOW | `find . …` resolves under cwd (inside repo). |
| 11 | `rm -rf /etc/foo` | `HARNESS_ALLOW_OUTSIDE_RM=1` | ALLOW | Override env var bypasses the guard. |
| 12 | `Remove-Item -Path C:\Windows -Recurse` | — | BLOCK | Regression for D-1 (PS `-Path` named param previously matched find-predicate `-path` case-insensitively and skipped the path arg). |
| 13 | `rm -name /etc/passwd` | — | BLOCK | Regression for D-2 (find-predicate skip was applied to every verb, not just `find`). |
| 14 | `rm -path /etc -delete` | — | BLOCK | Combined verb+predicate confusion — even with both `-path` and `-delete` flags, `/etc` is still walked as a path token. |
| 15 | `rm -type f /etc/x` | — | BLOCK | Same root cause as D-2 — `-type` was in the find-predicate list and trick `f` into being skipped. |
| 16 | `rm -mtime +0 /etc/x` | — | BLOCK | Same root cause — `-mtime` skip used to consume `+0`, letting `/etc/x` slip past. |
| 17 | `find /tmp -name '*.log' -delete` | — | BLOCK | `find … -delete` outside repo — the `find`-vs-`rm` gating must still block `/tmp` paths under the `find` branch. |

## Notes for the driver

- The driver MUST set cwd to the harness-kit repo root before each invocation
  (the guard walks `.git/` ancestors of cwd).
- The driver MUST clear `HARNESS_ALLOW_OUTSIDE_RM` from the environment
  between cases unless the row specifies it.
- Exit codes are the contract: 0 = allowed, 2 = blocked. The stderr message
  is informational; the driver does not assert on its exact content (those
  asserts would lock in formatting and slow down future tweaks).
