---
name: harness-status
description: Show the current Harness health of this project - which assets are present, the baseline state, the last verify result, and recent task progress. Use to get a quick snapshot.
allowed-tools: Read, Glob, Bash, PowerShell
---

# /harness-status

A one-page snapshot of Harness state in the current project.

## Procedure

Check each of these and report concisely:

### 0. Effective hook source

Resolve this **once per run, before §1**. Every hook-related verdict in this report
(§1's guard row, §3b, §3c, §6's guard point, §7's fix line) reads this one result and
**never re-reads a settings path for itself**. Candidates, in precedence order:

1. `C1 = .claude/settings.local.json` (machine-local settings)
2. `C2 = .claude/settings.json` (committed settings)

**Step 0.1 — state of each candidate** (first match wins):

| state | Condition |
|---|---|
| `absent` | Nothing at the path — `Read` reports not-found, or `.claude/` does not exist at all |
| `unreadable` | The path exists but: it is not a regular file, or `Read` fails for any other reason, or the content does not parse as a JSON object (whitespace-stripped it must start `{`, end `}`, and parse), or it parses but a top-level `hooks` key is present whose value is **not** a JSON object (`[]`, a string, a number, `true`, `null`) |
| `empty` | Parses, and either there is no top-level `hooks` key, or `hooks` is an object with **zero** keys |
| `present` | Parses, and `hooks` is an object with **≥ 1** key |

`"hooks": {"PreToolUse": []}` is `present` — the object has a key. That is the same
predicate `.harness/scripts/install-hooks` uses for "this project already has hooks",
and the consequence is honest and reportable: that file becomes the source, §3b reports
`WIRING ABSENT`, §3c reports every event `not wired`. This table is deliberately
**stricter** than the installer's probe on two classes (a path that is not a regular
file, and a byte-broken file that merely starts `{` and ends `}` — both `unreadable`
here); where they differ, this table wins.

The four states are **total and disjoint**: `empty` and `present` are reachable only
once `hooks` is known to be absent or an object, so every candidate lands on exactly
one state. A wrong-typed `hooks` is `unreadable`, never `empty` — the installer's probe
also calls that shape unparseable, and calling it `empty` would let a healthy guard
verdict print over a settings file Claude Code loads but cannot use.

**Step 0.2 — unknown outranks everything.** `UNKNOWN_FILES` = the candidates whose
state is `unreadable`. If it is non-empty: `MACHINE_STATE = unknown`, the guard verdict
**may not be `installed and wired` and earns no health point** regardless of what the
other candidate says, and every hook line carries the not-certified qualifier.
Resolution still continues (Step 0.3) so §3c can report what the readable file wires.

**Step 0.3 — resolve.** The **first** candidate whose state is `present`, in precedence
order, is `SOURCE` (`SOURCE_KIND` = `machine-local` for C1, `committed` for C2).
`OTHER_DECLARES` = true when the other candidate is also `present`.
`MACHINE_STATE = installed`, unless Step 0.2 already set `unknown`.

**Step 0.4 — no source (the machine dimension).** If no candidate is `present` and
`UNKNOWN_FILES` is empty, then `SOURCE = none`, `SOURCE_KIND = none`, and:

| C1 state | `MACHINE_STATE` | What it means |
|---|---|---|
| `absent` | `never-installed` | This clone has no lifecycle hooks installed on this machine. **Not** the guard having been switched off |
| `empty` | `opt-out` | A machine-local file is present with `<shape>` (`no "hooks" key` or `"hooks": {}`) — the documented persistent opt-out (`.harness/rules/75-safety-hook.md`) |

A C1 that exists with no `hooks` key at all is `opt-out`, not `never-installed`:
`install-hooks` keys on file **presence** alone and will not re-arm it. Name the shape
you actually saw.

**Step 0.5 — print exactly one line per run:**

```
Hook source:  <path> (machine-local settings)                  — committed .claude/settings.json declares no lifecycle hooks
Hook source:  <path> (machine-local settings)                  — .claude/settings.json ALSO declares lifecycle hooks; verdicts below come from the machine-local file only
Hook source:  .claude/settings.json (committed settings)       — no machine-local settings file declares hooks
Hook source:  none — consulted .claude/settings.local.json (<state>) and .claude/settings.json (<state>)
Hook source:  UNKNOWN — <file> exists but could not be read or parsed; hook verdicts below are not certified
```

Every form names at least one path; the `none` form names both consulted paths. Cost:
at most two file reads, no repository scan, no writes.

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
| PreToolUse hook | effective hook source (§0), `hooks.PreToolUse` entry referencing `guard-rm` | ? |

Name the file §0 resolved when printing that last row. It is **present** exactly when
§3b's decision table selects row 5, 6, 7 or 8 (a guard-referencing `PreToolUse` entry
was found in the effective hook source), and **not present** in rows 1-4. That is
deliberately weaker than the health point §6 awards, which needs row 8: the row answers
"is the wiring declared here?", the point answers "does the wiring resolve to a real
script?" — state both questions next to the row so a reader never has to infer the
difference. A dangling guard therefore shows this row present while §3b prints
`WIRING DANGLING` and awards no `+1`. The row count stays **14**.

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
Safety hook:         <the one verdict line the table below selects>
```

The "Sub-agent dispatch" line is constant — Claude Code is the only tool with
programmatic dispatch (`Task` tool). Other tools always show `n/a`. The
"Safety hook" value is computed from **§0's `SOURCE`**, never from a hardcoded path.

**Detection and extraction are two different tests — do not conflate them.**

- **Detection.** A *guard entry* is an entry under `SOURCE`'s
  `hooks.PreToolUse[*].hooks[*]` whose `command` contains the literal substring
  `guard-rm.ps1` or `guard-rm.sh`, **regardless of its matcher**. `K` = how many such
  entries exist; when `K ≥ 2`, `GUARD_ENTRY` is the **first in document order**.
- **Extraction.** From `GUARD_ENTRY.command` alone: `PATHS` = every path the §3c
  left-bounded pattern extracts (that pattern is name-agnostic, so a chained command
  yields one member per referenced script); `GUARD_PATHS` = the subset of `PATHS` whose
  name is exactly `guard-rm`, i.e. ending `scripts/guard-rm.ps1` or `scripts/guard-rm.sh`.

**Verdict — first match wins:**

| # | Condition | `Safety hook:` value | Point |
|---|---|---|---|
| 1 | `UNKNOWN_FILES` non-empty (§0 Step 0.2) | `UNKNOWN — <file> could not be read or parsed; guard state undetermined` | no |
| 2 | `SOURCE = none` and `MACHINE_STATE = never-installed` | `NOT INSTALLED ON THIS MACHINE — no lifecycle hooks in .claude/settings.local.json (absent) or .claude/settings.json` | no |
| 3 | `SOURCE = none` and `MACHINE_STATE = opt-out` | `HOOKS OFF (machine-local opt-out) — .claude/settings.local.json is present with <shape>; the documented persistent opt-out` | no |
| 4 | `K = 0` | `WIRING ABSENT — <SOURCE> declares no PreToolUse entry referencing guard-rm` | no |
| 5 | `GUARD_ENTRY.command` carries an unresolved `{{…}}` token | `WIRING DANGLING — MALFORMED: <SOURCE> wires "<command>" -> unresolved placeholder <token>` | no |
| 6 | `GUARD_PATHS = ∅` | `WIRING DANGLING — <SOURCE> wires "<command>" -> no extractable scripts/guard-rm.{sh,ps1} path in this command` | no |
| 7 | `GUARD_PATHS ≠ ∅` and **any** member of `PATHS` is missing on disk | `WIRING DANGLING — <SOURCE> wires "<command>" -> missing <path>`, or with more than one missing `… -> missing <path1>, <path2> (<k> of <n> extracted paths missing)` | no |
| 8 | `GUARD_PATHS ≠ ∅` and **every** member of `PATHS` exists on disk | `installed and wired (guard-rm in PreToolUse of <SOURCE>; matcher "<m>")`, and when `|PATHS| > 1` the form `installed and wired (guard-rm in PreToolUse of <SOURCE>; matcher "<m>"; all <n> extracted paths exist)` | **+1** |

Rows 7 and 8 quantify over the **whole** of `PATHS`, and row 8 additionally requires
`GUARD_PATHS ≠ ∅`. That is what makes the verdict agent-independent:

- A chained command with one missing link lands on row 7 **deterministically** — no
  reading of row 8 is defensible. It is the same "every extracted path exists"
  quantifier §3c already applies, so §3b and §3c can never disagree about one command.
- Detection alone can never buy the health point: a command that merely *mentions*
  `guard-rm.sh` in a non-extractable position while wiring some different, existing
  script yields `GUARD_PATHS = ∅` and lands on row 6.
- The shipped guard form carries no `|| exit 0` fallback, so a non-zero exit from
  **any** link makes the fail-closed `PreToolUse` hook block the Bash tool call.
  Reporting that healthy is the worse defect direction; row 7 catches it.

Row 6 is deliberate, not a bug: a guard whose path cannot be verified (an absolute or
otherwise non-left-bounded form) is never reported healthy, and never gets a wrong
"missing file" claim either. Print the command verbatim plus row 6's own clause so a
project with a legitimately custom guard path reads an accurate sentence. Do not invent
a fourth state, and do not "pick the healthiest entry" when `K ≥ 2` — that is judgment.

**Adjuncts — printed in rows 5-8 only**, immediately under the verdict line. Rows 1-4
have no `GUARD_ENTRY` to describe (row 4's own line already says there is none), so
they print no adjunct at all:

```
  guard entries matched:  1
  guard entries matched:  <K> — first in document order evaluated (from <SOURCE>)
  matcher:  "<m>"
  matcher:  "<m>" — non-canonical matcher
  interpreter:  <tok> (on PATH)
  interpreter:  <tok> — NOT on PATH; the guard is <semantics>, so this BLOCKS Bash tool calls rather than silently disarming the guard
```

- `<m>` is the verbatim `matcher` of `GUARD_ENTRY`'s containing block, or `(absent)`
  when that block has no `matcher` key. Flag it non-canonical when it is not exactly
  the spec's answer (`hook-spec matcher guard-rm` → `Bash`). A guard-referencing entry
  is **never** downgraded to `WIRING ABSENT` because of its matcher.
- `<tok>` is the command's literal first token (`sh` / `bash` / `pwsh`). Interpreter
  availability is an adjunct, never a row selector — it never changes which row fired.
  Never propose rewriting a runnable, user-chosen command variant.
- `<semantics>` is `hook-spec semantics guard-rm` (§3c query `N+3`) — `fail-closed`.
  Under §3c's fallback, use the literal `fail-closed` and point at
  `.harness/rules/75-safety-hook.md` rather than restating why.

**Cross-file note.** In rows 4-7, if the *non-effective* candidate declares a
guard-referencing `PreToolUse` entry, add: "`<other file>` also declares a PreToolUse
entry referencing guard-rm; this report's verdicts come from the effective hook source
only (§0)." Make no claim about how Claude Code merges settings files — report where
**you** looked.

The fix line for any non-healthy row is §7's, keyed on §0's **result** with first match
wins — row 1 (`UNKNOWN_FILES` non-empty) therefore takes §7's `MACHINE_STATE = unknown`
line, never a `SOURCE_KIND` line, even when a candidate still resolved. A repair that
cannot reach the file you just named is worse than none.

### 3c. Hook ↔ script congruence (all events — T-020 / FR-D1, FR-D2)

The rows come from the **hook wiring spec**, not from this document. Invoke the twin of
the shell you are yourself using (`Bash` → `.harness/scripts/hook-spec.sh`,
`PowerShell` → `.harness/scripts/hook-spec.ps1`) and never capture one shell's stdout
from the other:

| # | Query | Consumer |
|---|---|---|
| 1 | `hook-spec tools` | the id list and this section's row order |
| 2..N+1 | `hook-spec event <id>` (one per id) | each row's event name |
| N+2 | `hook-spec matcher guard-rm` | §3b's canonical-matcher comparison |
| N+3 | `hook-spec semantics guard-rm` | §3b's `<semantics>` clause |

That is `N+3` invocations — **7** for today's four ids. Never invoke
`command <tool> <os>` and never byte-compare a wired command against the spec: a
project legitimately carrying another host's byte-form, or a working user-customized
command, is not broken, and this report is read-only anyway.

**The spec is a soft dependency.** If the twin is absent, **or any** query exits
non-zero, **or any** query returns empty stdout, **or** you have no shell at all,
abandon the spec answer **entirely** — never mix partial spec output into the
fallback — and enumerate `Stop`, `PreToolUse`, `UserPromptSubmit`, `SessionStart`, in
that order, labelled as a fallback. The fallback carries event **names only**; it is
not a second hand-maintained id → event/matcher/semantics table.

For each enumerated event, read `SOURCE`'s (§0) `hooks.<Event>[].hooks[].command` and
report one line per event:

```
Hook congruence (from <SOURCE>):
Hook congruence (from <SOURCE>) — (fallback enumeration — hook wiring spec unavailable):
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
- **Resilient command form (v0.44+, T-12).** A healthy hook command is now anchored
  (`cd "$CLAUDE_PROJECT_DIR"` / `Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR`)
  and fail-open (convenience hooks end `… || exit 0` / `…; exit 0`) or fail-closed
  (guard-rm has the anchor but NO `exit 0` fallback). This anchor does NOT change the
  extractable token: the bare space-preceded `.harness/scripts/<name>.<ext>` still
  appears (after `[ -f ` / `Test-Path -LiteralPath ` and after `exec bash` / `-File`),
  so the same left-bounded pattern parses it and the existence check is unchanged. A
  resilient healthy project computes to `ok`; the anchor never makes a dangling script
  look present.
- `ok` — every extracted path exists. `not wired` — no entry for this event **in the
  effective hook source** (not a crash; report it plainly). When `SOURCE = none`, every
  row is `not wired` and §0's machine-dimension line — never a bare list — is the
  explanation.
- `DANGLING` — a path is extracted but the file does not exist. Print the exact
  command string and the missing path. Fix line: §7's table, keyed on §0's result with
  first match wins. When that selects `SOURCE_KIND = committed` it is `run
  /harness-upgrade to re-land current scripts and rewire hook paths`; do **not** print
  it for machine-local wiring, which the upgrade helper cannot reach.
- `MALFORMED` — the command contains an unresolved `{{...}}` placeholder token.
  Same §7 fix line; for committed wiring `/harness-upgrade` is an actual repair here
  (it rewrites a wired literal token to the OS-picked command), not just a re-land.
- **Interpreter availability (WARN, not a failure):** if the command's first token
  (`pwsh` / `bash`) is not on PATH, add: `wired to <tok> but <tok> is unavailable on
  this OS — swap the command variant (see the _doc_sync_hook / _ambient_hook notes in
  settings.json)`. Never auto-rewrite a runnable, user-chosen variant.

§3b applies a deeper check to the guard entry of the **same** `SOURCE`; this section
gives the Stop/sync hook and the two ambient hooks the same tri-state vocabulary.

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
- Guard hook **installed and wired** — §3b row 8, i.e. every path extracted from the
  guard command exists and at least one of them is the `guard-rm` script. The *other*
  shell twin is not required (the two twin rows above already report that) → +1
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

If §3b or §3c reported any non-healthy hook state, the fix line is **conditional on
§0's result**, and **first match wins** — exactly one line, in this row order. The
report never prints a repair that cannot reach the file it named:

| §0 result | Fix line to print |
|---|---|
| `MACHINE_STATE = unknown` | `inspect <file> — it is loaded by Claude Code but this report could not parse it` |
| `MACHINE_STATE = never-installed` | `.harness/scripts/install-hooks` **when** `.harness/scripts/install-hooks.sh` or `.ps1` exists in this project; otherwise the ordinary missing-asset instruction, `run /harness-adopt or /harness-upgrade` |
| `MACHINE_STATE = opt-out` | none — print `documented persistent opt-out; no action` |
| `SOURCE_KIND = committed` | `run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json` |
| `SOURCE_KIND = machine-local` and `OTHER_DECLARES = false` | `rm .claude/settings.local.json && .harness/scripts/install-hooks — the upgrade helper rewrites only the committed file, and the installer never overwrites an existing machine-local file` |
| `SOURCE_KIND = machine-local` and `OTHER_DECLARES = true` | `rm .claude/settings.local.json — .claude/settings.json already declares lifecycle hooks, so removing the machine-local file re-resolves this report (and Claude Code) to the committed wiring. Do NOT chain the installer: it exits early with "Committed settings already declares lifecycle hooks - no machine-local file created" and writes nothing. If the committed wiring is itself stale, run /harness-upgrade after the removal.` |

The `MACHINE_STATE` rows come **first** because Step 0.2 lets resolution continue: an
unparseable candidate can coexist with a `SOURCE_KIND`, and only the `unknown` line
points at the file the report named as unparseable — `/harness-upgrade` rewrites a
different file and cannot reach it. `never-installed` and `opt-out` imply
`SOURCE_KIND = none`, so they never contend with a `SOURCE_KIND` row; the ordering is
load-bearing for `unknown` alone.

## Anti-patterns

- Don't run verify_all here; this is read-only status. Use `/harness-verify` if you want a fresh run.
- Don't suggest changes to assets; just report state and gaps.
- Don't fabricate counts if files are missing — report "missing", not "0".
- Don't re-read `.claude/settings.json` or `.claude/settings.local.json` anywhere in §1,
  §3b, §3c, §6 or §7 — every hook verdict reads §0's result and names the file §0
  resolved. Re-inlining a settings path in one of those sections is exactly the defect
  §0 exists to prevent, and it is what made this report call a live guard disabled.
- Don't report a guard healthy on a wiring you could not verify (rows 1-7). A dead
  guard reported healthy is the severe direction; a live guard reported unverifiable is
  merely noisy.
- Don't auto-repair, and don't propose rewriting a runnable, user-chosen command
  variant. Name the fix; never perform it.
