---
name: harness-status
description: Show the current Harness health of this project - which assets are present, the baseline state, the last verify result, and recent task progress. Use to get a quick snapshot.
allowed-tools: Read, Glob, Bash, PowerShell
---

# /harness-status

A one-page snapshot of Harness state in the current project.

## Procedure

Check each of these and report concisely:

### 1. Required assets

| Asset | Path | Present? |
|---|---|---|
| Project rules | `CLAUDE.md` | ? |
| Workflow definition | `docs/workflow.md` | ? |
| Task board | `docs/tasks.md` | ? |
| Dev map | `docs/dev-map.md` | ? |
| Spec folder | `docs/spec/` | ? |
| Build skill | `.claude/skills/build/SKILL.md` | ? |
| Test skill | `.claude/skills/test/SKILL.md` | ? |
| Verify skill | `.claude/skills/verify/SKILL.md` | ? |
| verify_all script | `.harness/scripts/verify_all.ps1` or `.sh` | ? |
| Baseline | `.harness/scripts/baseline.json` | ? |
| Golden tasks | `evals/golden-tasks.md` | ? |
| Guard-rm script (ps1) | `.harness/scripts/guard-rm.ps1` | ? |
| Guard-rm script (sh) | `.harness/scripts/guard-rm.sh` | ? |
| PreToolUse hook | `.claude/settings.json` (has `hooks.PreToolUse` array referencing guard-rm) | ? |

Note: the framework agents (7 + supervisor) are **plugin-provided** (`harness-kit:<name>`)
since v0.30 — they are not project files and are not checked here. Partitioned projects
only: `.harness/agents/dev-*.md` synced to `.claude/agents/` (report if present; absence
is healthy for a single-developer project).

### 2. Baseline state

If `.harness/scripts/baseline.json` exists, print:

```
Baseline:
  version:        1
  created:        2026-05-15
  test_count:     369
  passing_count:  369
  last_updated:   2026-06-01
```

### 3. Last verify result

If `.harness/scripts/verification_history.log` exists, show the most recent entry:

```
Last verify: 2026-06-01T14:32:11Z
  PASS: 11
  WARN: 1
  FAIL: 0
  Result: PASSED WITH WARNINGS
```

### 3b. Sub-agent dispatch / safety hook

```
Sub-agent dispatch:  enabled (Claude Code via Task tool) | n/a (other tools)
Safety hook:         enabled (guard-rm wired in PreToolUse) | DISABLED — .claude/settings.json has no PreToolUse for Bash | scripts missing
```

The "Sub-agent dispatch" line is constant — Claude Code is the only tool with
programmatic dispatch (`Task` tool). Other tools always show `n/a`. The
"Safety hook" value is computed by parsing `.claude/settings.json`:

- `enabled` if `hooks.PreToolUse[*].matcher == "Bash"` AND its first hook's
  `command` references `guard-rm.{ps1,sh}` AND both `.harness/scripts/guard-rm.ps1` and
  `.harness/scripts/guard-rm.sh` exist.
- `DISABLED — .claude/settings.json has no PreToolUse for Bash` if the array
  is absent or no Bash matcher exists.
- `scripts missing` if the wiring is present but the script files are gone.

### 3c. Hook ↔ script congruence (all events — T-020 / FR-D1, FR-D2)

For **every** `hooks.{Stop,PreToolUse,UserPromptSubmit,SessionStart}[].hooks[].command`
in `.claude/settings.json`, report one line per event:

```
Hook congruence:
  Stop:              ok | not wired | DANGLING — "<command>" -> missing <path> | MALFORMED — unsubstituted placeholder
  PreToolUse:        ok | not wired | DANGLING — ... | MALFORMED — ...
  UserPromptSubmit:  ok | not wired | DANGLING — ... | MALFORMED — ...
  SessionStart:      ok | not wired | DANGLING — ... | MALFORMED — ...
```

How to compute each state:

- Extract every script path in the command matching the left-bounded pattern
  `(^|["' =])(\.harness/)?scripts/<name>.(ps1|sh)` — the boundary means a custom
  command in a dirname merely *ending* in `scripts/` (e.g. `build-scripts/deploy.sh`)
  is never extracted, so user-custom hooks are not flagged.
- `ok` — every extracted path exists. `not wired` — settings absent, no `hooks` key,
  or no entry for the event (not a crash; report it plainly).
- `DANGLING` — a path is extracted but the file does not exist. Print the exact
  command string and the missing path. Fix line: `run /harness-upgrade to re-land
  current scripts and rewire hook paths`.
- `MALFORMED` — the command contains an unresolved `{{...}}` placeholder token.
  Fix line: `run /harness-upgrade` (it rewrites a wired literal token to the
  OS-picked command — an actual repair, not just a re-land).
- **Interpreter availability (WARN, not a failure):** if the command's first token
  (`pwsh` / `bash`) is not on PATH, add: `wired to <tok> but <tok> is unavailable on
  this OS — swap the command variant (see the _doc_sync_hook / _ambient_hook notes in
  settings.json)`. Never auto-rewrite a runnable, user-chosen variant.

§3b (guard-rm deep check) stays as-is; this section gives the Stop/sync hook and the
two ambient hooks the same tri-state vocabulary.

### 4. Active tasks

Read `docs/tasks.md` and list any task whose stage is not `done` or `delivery`:

```
Active tasks:
  T-007  csv-export-orders       stage=dev
  T-008  fix-login-redirect      stage=review
```

### 5. Recently completed (last 5)

From `docs/tasks.md`, list the last 5 `done` tasks with date.

### 6. Health score

Compute a quick score:

- All 14 required assets present → +6 health points
- Baseline exists and is recent (< 30 days) → +2
- Last verify PASS → +2
- No active tasks blocked > 3 days → +1
- PreToolUse guard hook installed and points at existing guard-rm scripts → +1
- Total possible: 12

Report as e.g. `Health: 10/12 — minor gaps in dev-map and evals.`

### 7. Suggestions

If anything is missing, list concrete next steps:

```
Recommendations:
  - docs/dev-map.md is missing; run /harness-init or write one manually.
  - Last verify was 14 days ago; run /harness-verify.
  - Task T-007 has been at 'dev' for 5 days; PM should check in.
```

If §3c reported any non-ok hook state (DANGLING / MALFORMED), always include:

```
  - A wired hook is dangling/malformed; run /harness-upgrade to re-land current
    scripts and rewire hook paths.
```

## Anti-patterns

- Don't run verify_all here; this is read-only status. Use `/harness-verify` if you want a fresh run.
- Don't suggest changes to assets; just report state and gaps.
- Don't fabricate counts if files are missing — report "missing", not "0".
