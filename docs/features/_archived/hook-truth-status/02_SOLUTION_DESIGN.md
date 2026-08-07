# 02 — Solution Design · T-14 `hook-truth-status`

**Mode**: `full` · **Stage**: 2 (solution-architect) · **Date**: 2026-07-31
**Round**: **2** (revised in place after `03_GATE_REVIEW.md` returned `BLOCKED ON DESIGN`; rollback #1).
Per-finding delta for the gate's re-review is in **§14**. Round-2 edits are marked *(round 2, F-n)* inline.
**Binding input**: `docs/features/hook-truth-status/01_REQUIREMENT_ANALYSIS.md` (verdict `READY`) — unchanged;
the gate found **no requirement gap**, so no rollback to requirement-analyst was requested in either round.
**deferred-human mode**: defer, do not ask — no `AskUserQuestion` was called; every OQ-1…OQ-10 `Recommended:`
answer is adopted as binding. No conflict with any recommendation was found, so no rollback is requested.
**Developer mode**: **single developer** — `.harness/agents/` carries no `dev-*.md` partition agent
(`AI-GUIDE.md:15`), so no Partition assignment section applies; §11 states this formally.
**Gate expectation**: `.harness/scripts/verify_all` bash **PASS 32 / WARN 0 / FAIL 0**, check count **32**.

---

## 1. Architecture summary

The health report (`skills/harness-status/SKILL.md`) currently derives four hook-related outputs — the
required-asset guard row (§1), the guard verdict (§3b), the per-event congruence table (§3c) and the guard
health point (§6) — each from its own inline mention of the hardcoded path `.claude/settings.json`. This
design inserts **one new resolution step, §0 "Effective hook source"**, that answers a single question
("which settings file do this run's hook verdicts come from, and what is its state?") and makes all four
outputs read that one answer instead of a path literal. §0 also owns the machine dimension (never installed /
persistent opt-out / unreadable), which no section owns today, and §3c's *enumeration* of lifecycle events
moves from the report's prose to an invocation of the already-shipped hook wiring spec
(`.harness/scripts/hook-spec.{sh,ps1}`) with a labelled fallback. Nothing executable changes: the health
report is a **skill document** — instructions an agent follows with `Read` / `Glob` / `Bash` — so §0 is a
documented procedure with pinned output strings, not a function. **No gate check is added** (check count stays
32); the duplication is removed by composition over an existing runtime tool, the pattern insight
2026-06-09 records for T-016.

---

## 2. Affected modules

| Path | Nature of change |
|---|---|
| `skills/harness-status/SKILL.md` | The only behavioral edit. New §0; §1 guard row, §3b, §3c, §6, §7, Anti-patterns rewritten to read §0. |
| `CHANGELOG.md` | New subsection under the existing unreleased `## [0.45.0]` heading (OQ-6a), or a new `## [0.46.0]` heading under the OQ-6 tripwire (§9). |
| `docs/features/hook-truth-status/0[3-7]_*.md` | Stage docs produced by later stages (not this task's product edits). |
| `docs/tasks.md` | Delivery row appended at stage 7 (append-only; not a stage-4 edit). |

Everything else in the repo is **out** — see the complete edit ledger in §7.3, including the frozen decoy set.

---

## 3. Module decomposition

### 3.1 New module: `§0 Effective hook source` (in `skills/harness-status/SKILL.md`)

**Responsibility**: resolve, once per report run, (a) the **effective hook source** — the one settings file the
run's hook verdicts are computed from — and (b) the machine-dimension facts about the two candidate locations.

**Public API** (what every other section may consume — nothing else):

| Name | Type | Meaning |
|---|---|---|
| `SOURCE` | path or `none` | The effective hook source path, or `none` when no candidate declares hooks |
| `SOURCE_KIND` | `machine-local` \| `committed` \| `none` | Which candidate won; drives the FR-8 fix line |
| `HOOKS_JSON` | object | The `hooks` object read from `SOURCE` (empty when `SOURCE = none`) |
| `UNKNOWN_FILES` | list of paths | Candidates that exist but could not be read/parsed (FR-14) |
| `OTHER_DECLARES` | bool | The non-winning candidate also declares a non-empty hooks object (FR-4) |
| `MACHINE_STATE` | `installed` \| `never-installed` \| `opt-out` \| `unknown` | The machine dimension (FR-12/FR-13/FR-14) |

**Depth check (deletion test)**: delete §0 and the precedence + parse + empty/absent discrimination reappears
in four call sites (§1 row, §3b, §3c, §6/§7) — exactly the duplication that produced this defect. Two real
adapters sit at the seam (machine-local, committed), so the seam is real, not hypothetical. Consumers cross
the interface above and nothing else; no consumer re-reads a settings path directly. That prohibition is the
single most important reviewable property of this change.

**Procedure (deterministic; step order is the contract)**

Let `<root>` be the project root (the report's cwd). Candidates, **in precedence order**:

1. `C1 = <root>/.claude/settings.local.json` (machine-local settings)
2. `C2 = <root>/.claude/settings.json` (committed settings)

**Step 0.1 — state of each candidate.** For each candidate compute `state ∈ {absent, unreadable, empty,
present}` by exactly this test. Relationship to `install-hooks.sh:54-94 settings_hook_state` (restated
precisely — **round 2, F-4**): this table deliberately borrows that function's **four-state vocabulary** (its
third state is spelled `unparseable`; `unreadable` here is the same slot, widened) and its **empty/present
boundary for well-formed files** — for any file that parses as a JSON object, report and installer return the
same state, so they agree on "does this project have hooks". On two input classes the table is **deliberately
stricter than the installer**, because B-7 requires it:

| Input class | `settings_hook_state` | This table | Why the divergence is required |
|---|---|---|---|
| Path exists but is **not a regular file** | `present` (`install-hooks.sh:74-76`, reads nothing) | `unreadable` | B-7 names non-regular files explicitly; the installer's answer is a fail-safe *write suppressor*, not a truth claim |
| File starts `{`, ends `}`, but is **byte-broken JSON** | `empty` or `present` (byte probe only, `:78-93`; it never parses) | `unreadable` | B-7 requires "does not parse structurally" ⇒ `unknown`, no health point |

The design therefore does **not** claim the two can never disagree — it claims they never disagree about a
well-formed file, and that where they do disagree the report is the stricter of the two, which is the
NFR-1-safe direction. **A Developer must follow the table below, not the installer's source**; the table wins
any conflict.

| state | Condition (first match wins) |
|---|---|
| `absent` | Nothing at the path — `Read` reports not-found, or `.claude/` itself does not exist (B-6) |
| `unreadable` | The path exists but: is not a regular file, or `Read` fails for any other reason, or the content does not parse as a JSON object (after whitespace strip it must start `{` and end `}` and parse) (B-7) |
| `empty` | Parses, and either there is no top-level `hooks` key, or `hooks` is an object with **zero keys** |
| `present` | Parses, and `hooks` is an object with **≥ 1 key** |

Tie rule, stated because it is the one judgment call: `"hooks": {"PreToolUse": []}` is **`present`** (the
object has a key). Reason: it matches the installer's byte-level probe (`install-hooks.sh:63-65` — the first
non-whitespace byte after `{` decides), so the installer's "this project already has hooks" and the report's
"this file is the effective hook source" are the same predicate. The consequence is honest and reportable:
that file becomes `SOURCE`, §3b reports *wiring absent*, §3c reports every event `not wired`.

**Step 0.2 — unknown precedence (FR-14 gates FR-5).** `UNKNOWN_FILES` = every candidate whose state is
`unreadable`. If `UNKNOWN_FILES` is non-empty:

- `MACHINE_STATE = unknown`;
- the report prints the unknown line naming every file in `UNKNOWN_FILES`;
- **the guard verdict may not be `installed and wired` and earns no health point**, regardless of what the
  other candidate says;
- resolution still continues (Step 0.3) so §3c can report what the readable file wires, but every hook line
  carries the not-certified qualifier.

*Interpretation note D-1 (no deviation intended).* FR-5 says the guard verdict is "exactly one of three"
states; FR-14 requires a distinct, non-healthy, no-point "hook state unknown" outcome. This design reads
FR-14 as a **precondition gate on FR-5**: the FR-5 triple is exhaustive *within* the resolved-source branch,
and `UNKNOWN` preempts it. AC-4 (three states distinguishable) is unaffected — its three probes never carry
an unreadable candidate.

**Step 0.3 — resolve.** Among candidates whose state is `present`, in precedence order, the **first** one is
`SOURCE` (`SOURCE_KIND = machine-local` for C1, `committed` for C2); `OTHER_DECLARES = true` when the other
candidate is also `present` (FR-4). `MACHINE_STATE = installed` (unless Step 0.2 set `unknown`).

**Step 0.4 — no source (machine dimension).** If no candidate is `present` and `UNKNOWN_FILES` is empty:
`SOURCE = none`, `SOURCE_KIND = none`, and

| C1 state | `MACHINE_STATE` | Line the report prints |
|---|---|---|
| `absent` | `never-installed` | FR-12 sentence + the OQ-10a fix line |
| `empty` | `opt-out` | FR-13 sentence, naming the actual shape (`no "hooks" key` or `"hooks": {}`) verbatim |

Rationale for folding "C1 present with **no** `hooks` key at all" into `opt-out` rather than
`never-installed`: FR-12's discriminator is *file absence*, and the operative fact behind the opt-out is that
`install-hooks` keys on **presence alone** and will not re-arm (`install-hooks.sh:156-161`,
`.harness/rules/75-safety-hook.md:107-110`). The printed shape keeps the report honest about which of the two
shapes it saw.

**Step 0.5 — print.** Exactly one `Hook source:` line per run, per §5.1.

**Cost (NFR-4)**: at most two file reads. No repository scan. No write of any kind (FR-19).

### 3.2 New module: `§3c enumeration via the hook wiring spec` (soft dependency)

**Responsibility**: obtain the set of hook ids and, per id, its event name (and, for the guard id only, its
matcher and fail-open/fail-closed semantics) from `.harness/scripts/hook-spec.{sh,ps1}` rather than from the
report's prose (FR-16, AC-8).

**Query plan (pinned; this is the whole coupling)**

| # | Query | Consumer |
|---|---|---|
| 1 | `hook-spec tools` | the id list and the **row order** of §3c |
| 2..N+1 | `hook-spec event <id>` (one per id) | the event name of each §3c row |
| N+2 | `hook-spec matcher guard-rm` | §3b's canonical-matcher comparison (FR-9) |
| N+3 | `hook-spec semantics guard-rm` | §3b's fail-closed consequence sentence (FR-10) |

`command <tool> <os>` is **never** invoked and no wired command is byte-compared against the spec (OQ-3a);
`hostos` is not needed. With today's four ids that is 7 invocations.

*Deviation D-2 — **ACCEPTED DEVIATION from NFR-4's literal wording** (round 2, F-6; round 1 wrongly filed this
as "no deviation intended").* NFR-4 caps the spec at "at most one hook wiring spec invocation per hook id plus
one for the id list" = `1 + N` = **5** invocations for today's four ids. This design invokes `1 + N + 2` =
**7**: the two extra are `matcher guard-rm` and `semantics guard-rm`.

- **Why the breach is unavoidable**: FR-9 obliges a canonical-matcher comparison and FR-10 obliges the
  fail-closed consequence sentence, and insight 2026-06-20 forbids the report restating a fact the spec and
  `.harness/rules/75-safety-hook.md` own. `hook-spec.sh:117-124` offers no combined query, and changing the
  spec is out of scope (§3.4). Every alternative — restating the two facts in the report's prose, or dropping
  them — violates a binding FR or a standing insight.
- **Why it is safe**: the excess is a **constant +2**, independent of `N`; NFR-4's stated purpose ("bounded
  cost … no repository-wide scan is introduced") is fully preserved.
- **Disposition**: recorded here as an accepted deviation, **not** waived silently. The RA wording is to be
  corrected at archive time — `01_REQUIREMENT_ANALYSIS.md` NFR-4 should read "…plus a constant number of
  guard-specific queries" — and the Solution Architect **cannot** make that edit (hard rule: the architect does
  not edit the requirement document). The Developer states the **actual** invocation count (`N+3`, = 7 today)
  in `04_IMPLEMENTATION.md` so QA can assert it rather than recompute it.

**Shell rule (B-17)**: the report invokes the twin of the shell it is itself using — the `Bash` tool ⇒
`.harness/scripts/hook-spec.sh`, the `PowerShell` tool ⇒ `.harness/scripts/hook-spec.ps1`. Never capture one
shell's stdout from the other (`hook-spec.sh:9-16`).

**Fallback (B-15 / B-16 / B-18)**: if the twin is absent, **or any** query in the plan exits non-zero, **or
any** query returns empty stdout, **or** shell execution is unavailable to the running agent, the report
abandons the spec answer entirely (never mixes partial spec output with fallback) and enumerates the four
lifecycle event names it names today — `Stop`, `PreToolUse`, `UserPromptSubmit`, `SessionStart`, in that
order — with the label `(fallback enumeration — hook wiring spec unavailable)`. FR-9/FR-10 then use the
literal canonical matcher `Bash` and the sentence "the guard is fail-closed (see
`.harness/rules/75-safety-hook.md`)".

*AC-8 boundary*: the fallback lists **event names only**. It does not carry an id → event/matcher/semantics
table, so the report still contains no second hand-maintained copy of those facts — which is what AC-8
forbids and what FR-16 explicitly permits as the fallback.

### 3.3 Rewritten: `§3b` guard verdict

**Guard-entry detection vs path extraction — two different tests, do not conflate:**

- **Detection** (FR-5, B-8/B-9/B-10): a guard entry is an entry under `SOURCE`'s `hooks.PreToolUse[*].hooks[*]`
  whose `command` contains the literal substring `guard-rm.ps1` or `guard-rm.sh`, **regardless of matcher**.
  Let `K` = the number of such entries. When `K ≥ 2`, the **first in document order** is `GUARD_ENTRY` and the
  report states `K` (B-9 — pinned string in §5.2). When `K = 0`, row 4 applies.
- **Extraction** (FR-11, B-11, B-19): paths are pulled from `GUARD_ENTRY.command` with the report's existing
  left-bounded pattern — unchanged bytes, see the pin below — so the old-layout `scripts/guard-rm.sh` still
  resolves and `build-scripts/deploy.sh` still never does.

**Byte-form pin for the extraction pattern (round 2, F-5).** The pattern **ships byte-identical to the live
line** `skills/harness-status/SKILL.md:98`, whose text is:

```
(^|["' =])(\.harness/)?scripts/<name>.(ps1|sh)
```

— note the **unescaped** `.` before `(ps1|sh)`. The Developer **copies that line, does not retype it**, and
does not "fix" the dot: escaping it would be a semantically harmless but gratuitous byte change to a surface
§3.4 declares byte-preserved, and this design has audited the unescaped form as the shipping one. (Round 1 of
this document rendered it as `\.` in prose; that rendering was a transcription artifact, never a change
request.)

**The extracted sets (round 2, F-1 — this is the determinism fix).** From `GUARD_ENTRY.command`:

- `PATHS` = the ordered set of **all** paths the left-bounded pattern extracts — the pattern is
  **name-agnostic**, so a chained command yields one entry per referenced script, not one per guard.
- `GUARD_PATHS` = the subset of `PATHS` whose `<name>` is exactly `guard-rm`, i.e. the path ends
  `scripts/guard-rm.ps1` or `scripts/guard-rm.sh`.

Both are computed from `GUARD_ENTRY.command` alone. Note the consequence, which is intended: a command
referencing an **absolute** or otherwise non-left-bounded guard path (`bash /opt/hooks/guard-rm.sh`) yields
`GUARD_PATHS = ∅` and lands on row 6 — reported honestly as unverifiable, never as healthy and never as a
wrong "missing file" claim.

**Verdict decision table (first match wins — this ordering is the determinism guarantee for FR-18):**

| # | Condition | Verdict | Health point |
|---|---|---|---|
| 1 | `UNKNOWN_FILES` non-empty (Step 0.2) | `UNKNOWN` | no |
| 2 | `SOURCE = none` and `MACHINE_STATE = never-installed` | `NOT INSTALLED ON THIS MACHINE` | no |
| 3 | `SOURCE = none` and `MACHINE_STATE = opt-out` | `HOOKS OFF (machine-local opt-out)` | no |
| 4 | `K = 0` — no guard entry detected in `SOURCE` | `WIRING ABSENT` | no |
| 5 | `GUARD_ENTRY.command` contains an unresolved `{{…}}` token | `WIRING DANGLING` + `MALFORMED` qualifier (B-12) | no |
| 6 | `GUARD_PATHS = ∅` (no extractable `guard-rm.(ps1\|sh)` path, whether or not other paths were extracted) | `WIRING DANGLING` + "no extractable `scripts/guard-rm.{sh,ps1}` path in this command" | no |
| 7 | `GUARD_PATHS ≠ ∅` and **any** member of `PATHS` does not exist on disk | `WIRING DANGLING` + **every** missing path listed | no |
| 8 | `GUARD_PATHS ≠ ∅` and **every** member of `PATHS` exists on disk | `INSTALLED AND WIRED` | **+1** |

**Why the quantifiers (F-1, and why row 8 is the only healthy row).** Rows 7 and 8 range over the **whole
set** `PATHS`, and row 8 additionally requires `GUARD_PATHS ≠ ∅`. Three properties follow, each of which the
round-1 singular phrasing failed to guarantee:

1. **No multiplicity ambiguity (FR-18).** For a chained command such as
   `sh -c 'cd "$CLAUDE_PROJECT_DIR" && bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'`
   with `guard-rm.sh` deleted, `PATHS` has two members, one missing ⇒ **row 7, deterministically**. No agent
   can defensibly read row 8. This is the same "**every** extracted path exists" quantifier §3c already uses
   (`skills/harness-status/SKILL.md:110`), so §3b and §3c can no longer disagree about the same command.
2. **No false-green on a non-guard path (NFR-1).** A command that merely *mentions* `guard-rm.sh` (in a
   comment, an `echo`, a wrapper argument) while wiring some different, existing script satisfies detection
   but yields `GUARD_PATHS = ∅` ⇒ **row 6**, never row 8. Detection alone can no longer buy a health point.
3. **The existence test ranges over all of `PATHS`, not only over `GUARD_PATHS`.** A guard entry whose command
   chains a *second*, missing script still fails as a whole: the shipped guard form carries no `|| exit 0`
   fallback (`.claude/settings.local.json:22`, `hook-spec.sh:108-109`), so a non-zero from **any** link makes
   the fail-closed `PreToolUse` hook block the Bash tool call. Reporting that healthy would be the exact NFR-1
   hard-reject direction. Row 7 catches it. (This is strictly the safer quantifier: it can only move a verdict
   from healthy to dangling, never the reverse, and FR-11 is respected because `GUARD_PATHS ≠ ∅` remains the
   *guard-specific* precondition for reaching rows 7-8 at all.)

Row 6 exists because NFR-1 ranks a false-green as the more severe defect: a guard whose path cannot be
verified is never reported healthy. It prints the command verbatim and says *why* nothing guard-shaped was
extracted, so a project with a legitimately custom guard path reads an accurate sentence rather than a wrong
"missing file" claim. Rows 5-7 all satisfy FR-7 (evidence printed, never healthy, no point).

**Effect on AC-1 (unchanged).** On this repository `GUARD_ENTRY.command` is
`sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`
(`.claude/settings.local.json:22`): `PATHS` = { `.harness/scripts/guard-rm.sh` } (one member, space-preceded ⇒
left bound satisfied), `GUARD_PATHS` = the same single member, and the file exists ⇒ **row 8**, byte-identical
output to round 1's expectation. `K = 1`, so the B-9 multiplicity adjunct prints its `K = 1` form.

**Always-printed adjuncts** (in every row except 1-3; each has a pinned string in §5.2):

- **Multiplicity (FR-9, B-9)** — *round 2, F-7*: print `K`, the number of guard-referencing `PreToolUse`
  entries found in `SOURCE`, and, when `K ≥ 2`, that the first in document order was the one evaluated.
  Printed in rows 5-8 (in row 4, `K = 0` is already the row's own meaning). Pinned string: §5.2 (b).
- **Matcher (FR-9, B-10)**: print `GUARD_ENTRY`'s containing block's `matcher` value verbatim (or `(absent)`);
  if it is not exactly the spec's canonical answer (`Bash`), append `— non-canonical matcher`. A
  guard-referencing entry is never downgraded to *wiring absent* because of its matcher.
- **Interpreter (FR-10, B-14)** — *round 2, F-7, now with a pinned string*: the command's first token
  (`pwsh` / `bash` / `sh` — note `sh` must be added; the current text names only `pwsh` / `bash` while the
  shipped unix form starts with `sh`). If it is not on PATH, print it **with its consequence**: the guard is
  fail-closed, so an unavailable interpreter *blocks* Bash tool calls rather than silently disarming the
  guard. The guard verdict row itself is **unchanged** by interpreter availability (B-14) — this is an
  adjunct, never a row selector. Never propose rewriting a runnable, user-chosen command variant. Pinned
  string: §5.2 (c).
- **Cross-file note**: when the verdict is row 4 (or rows 5-7) and the *non-effective* candidate declares a
  guard-referencing PreToolUse entry, add: "`<other file>` also declares a PreToolUse entry referencing
  guard-rm; this report's verdicts come from the effective hook source only (§0)." No claim is made about
  how Claude Code merges settings files — the report reports where **it** looked.
- **Fix line (FR-8)**: per §5.3.

### 3.4 Rewritten: `§3c` per-event congruence

Unchanged: the state vocabulary `ok` / `not wired` / `DANGLING` / `MALFORMED`, the left-bounded extraction
pattern, the resilient-command-form note, the interpreter WARN (NFR-2 — `/harness-upgrade`'s repair trigger,
`skills/harness-upgrade/SKILL.md:29-33`, keeps its tokens). Changed: rows are read from `SOURCE` (§0) and
the section names it; the row set comes from §3.2's enumeration; `not wired` now means "no entry for this
event **in the effective hook source**", and when `SOURCE = none` every row is `not wired` with §0's
machine-dimension line as the explanation rather than a bare list.

### 3.5 Rewritten: `§1` guard asset row, `§6` health point, `§7` recommendations

- **§1**: the `PreToolUse hook` row's path cell becomes location-agnostic — "effective hook source (§0),
  `hooks.PreToolUse` entry referencing `guard-rm`" — and the report names the resolved file when printing the
  row (FR-17). **The row count stays 14 and the row is not added or removed.**
- **§1, `Present?` predicate (round 2, F-2 — pinned so no agent has to judge)**: the row is **present exactly
  when §3.3 selects row 5, 6, 7 or 8** (i.e. `SOURCE` exists and `K ≥ 1` — a guard-referencing `PreToolUse`
  entry was found in the effective hook source, FR-17's own condition), and **not present in rows 1-4**
  (`UNKNOWN`, never-installed, opt-out, `WIRING ABSENT`). This predicate is **deliberately weaker** than the
  `+1` health point, which §6 restricts to row 8 alone: a *dangling* guard shows the asset row **present**
  (and so can still feed §6's `All 14 required assets present → +6`) while §3b simultaneously prints
  `WIRING DANGLING` and awards **no** `+1`. That is not a contradiction — the asset row answers "is the wiring
  declared here?", the point answers "does the wiring resolve to a real script?" — and the report states the
  two questions in those words next to the row so a reader is never left inferring it. Neither the row count
  (**14**) nor the denominator (**12**) moves.
- **§6**: the `+1` bullet reads "guard hook *installed and wired* per §3b row 8" (i.e. the extracted script
  exists — OQ-4a, **not** "both twins exist"). Denominator **12** and "All 14 required assets" are unchanged
  frozen counts (insight 2026-06-19: the 14 is a HEALTH denominator, not a skill count).
- **§7**: the blanket `run /harness-upgrade` recommendation becomes conditional on `SOURCE_KIND` (§5.3);
  `MACHINE_STATE = never-installed` emits the installer line; `MACHINE_STATE = opt-out` emits **no**
  recommendation beyond "documented opt-out — no action"; `MACHINE_STATE = unknown` emits "inspect
  `<file>`".

---

## 4. Data model changes

**None.** No schema, no table, no settings-file shape, no new persisted artifact. `.harness/scripts/baseline.json`
is **not** modified (see §7.3); the health report writes nothing (FR-19).

---

## 5. API contracts (the pinned output strings)

These are the strings QA asserts against. Slots in `<…>` are substituted; everything else is literal. The
Developer authors the surrounding prose; these lines are the contract.

### 5.1 `Hook source:` line (§0) — exactly one per run

```
Hook source:  <path> (machine-local settings)                  — committed .claude/settings.json declares no lifecycle hooks
Hook source:  <path> (machine-local settings)                  — .claude/settings.json ALSO declares lifecycle hooks; verdicts below come from the machine-local file only
Hook source:  .claude/settings.json (committed settings)       — no machine-local settings file declares hooks
Hook source:  none — consulted .claude/settings.local.json (<state>) and .claude/settings.json (<state>)
Hook source:  UNKNOWN — <file> exists but could not be read or parsed; hook verdicts below are not certified
```

Required tokens: the words `machine-local settings` / `committed settings` / `none` / `UNKNOWN`, and **every
line names at least one path** (FR-2; the `none` form names both consulted paths).

### 5.2 `Safety hook:` value (§3b) — one of

**(a) The verdict line** — exactly one per run, keyed to the §3.3 row that fired:

```
installed and wired (guard-rm in PreToolUse of <SOURCE>; matcher "<m>")                                      [row 8, |PATHS| = 1]
installed and wired (guard-rm in PreToolUse of <SOURCE>; matcher "<m>"; all <n> extracted paths exist)        [row 8, |PATHS| > 1]
WIRING DANGLING — <SOURCE> wires "<command>" -> missing <path>                                                [row 7, 1 missing]
WIRING DANGLING — <SOURCE> wires "<command>" -> missing <path1>, <path2> (<k> of <n> extracted paths missing) [row 7, >1 missing]
WIRING DANGLING — MALFORMED: <SOURCE> wires "<command>" -> unresolved placeholder <token>                     [row 5]
WIRING DANGLING — <SOURCE> wires "<command>" -> no extractable scripts/guard-rm.{sh,ps1} path in this command [row 6]
WIRING ABSENT — <SOURCE> declares no PreToolUse entry referencing guard-rm                                    [row 4]
NOT INSTALLED ON THIS MACHINE — no lifecycle hooks in .claude/settings.local.json (absent) or .claude/settings.json
HOOKS OFF (machine-local opt-out) — .claude/settings.local.json is present with <shape>; the documented persistent opt-out
UNKNOWN — <file> could not be read or parsed; guard state undetermined
```

Round-2 notes (F-1, F-5): the row-8 and row-7 forms now carry the **set** quantifier of §3.3. The single-path
forms (`|PATHS| = 1`, one missing) are byte-identical to round 1, so AC-1's expected P-1 output does not move
— this repository has exactly one extracted path. Row 6's string changed from "no `.harness/scripts/` path
found" to "no extractable `scripts/guard-rm.{sh,ps1}` path", because row 6's condition is now
`GUARD_PATHS = ∅`, not `PATHS = ∅`; the old wording would be a false statement when a non-guard path *was*
extracted.

**(b) Multiplicity adjunct (B-9, FR-9)** — printed in rows 5-8, immediately under the verdict line:

```
  guard entries matched:  1
  guard entries matched:  <K> — first in document order evaluated (from <SOURCE>)                             [K >= 2]
```

**(c) Interpreter adjunct (B-14, FR-10)** — printed in rows 5-8, immediately under (b):

```
  interpreter:  <tok> (on PATH)
  interpreter:  <tok> — NOT on PATH; the guard is fail-closed, so this BLOCKS Bash tool calls rather than silently disarming the guard
```

`<tok>` is the command's literal first token (`sh` on this repository, `pwsh` / `bash` elsewhere). The
unavailable form never proposes a command rewrite (FR-10) and never changes which §3.3 row fired (B-14).

**Retired string (OQ-9a)**: `DISABLED — .claude/settings.json has no PreToolUse for Bash` is deleted from the
skill and **no I.6 banned-phrase entry is added** for it (the I.6 list is a four-file lockstep with a pinned
entry count in a second driver pair — insight 2026-06-08 — and this string has exactly one live occurrence,
in the file this task rewrites).

The `Sub-agent dispatch:` line above it is unchanged.

### 5.3 Fix lines (FR-8) — reachability is the whole point

| `SOURCE_KIND` (+ condition) | Fix line the report prints |
|---|---|
| `committed` | `run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json` |
| `machine-local` **and** `OTHER_DECLARES = false` | `rm .claude/settings.local.json && .harness/scripts/install-hooks — the upgrade helper rewrites only the committed file, and the installer never overwrites an existing machine-local file` |
| `machine-local` **and** `OTHER_DECLARES = true` *(round 2, F-3)* | `rm .claude/settings.local.json — .claude/settings.json already declares lifecycle hooks, so removing the machine-local file re-resolves this report (and Claude Code) to the committed wiring. Do NOT chain the installer: it exits early with "Committed settings already declares lifecycle hooks - no machine-local file created" and writes nothing. If the committed wiring is itself stale, run /harness-upgrade after the removal.` |
| `none`, `MACHINE_STATE = never-installed` | `.harness/scripts/install-hooks` **when** `.harness/scripts/install-hooks.sh` or `.ps1` exists in the project; otherwise the report's existing missing-asset instruction (`run /harness-adopt or /harness-upgrade`) — OQ-10a |
| `none`, `MACHINE_STATE = opt-out` | none — print "documented persistent opt-out; no action" |
| `unknown` | `inspect <file> — it is loaded by Claude Code but this report could not parse it` |

Evidence for the asymmetry: `upgrade-project.sh:248-251` operates on `.claude/settings.json` only;
`install-hooks.sh:159-162` returns early on an existing machine-local file; `install-hooks.sh:38` documents
the removal command.

**Evidence for the fourth row (round 2, F-3)**: `install-hooks.sh:152-155` is the *first* bootstrap decision
and it keys on the **committed** file — `if [ "$committed_state" = "present" ]` ⇒ print
`Committed settings already declares lifecycle hooks - no machine-local file created` and `exit 0`. So in the
B-3 / FR-4 arrangement (both files declare hooks) the round-1 `rm … && install-hooks` line would perform the
removal and then **no-op**, and its printed rationale ("the installer never overwrites an existing
machine-local file") would be describing a branch that never executes. The removal alone *is* the complete
repair there, because the committed file then wins §0's precedence. FR-8 is absolute — the report never
prints a fix instruction that cannot reach the file it named — so the two `machine-local` branches are keyed
on `OTHER_DECLARES`, which §0 already computes and hands over as part of its six-field interface. No new
input is needed. Probe: **P-10b**.

### 5.4 `Hook congruence:` block (§3c)

Header gains the source and, when applicable, the fallback label:

```
Hook congruence (from <SOURCE>):
Hook congruence (from <SOURCE>) — (fallback enumeration — hook wiring spec unavailable):
  <Event>:  ok | not wired | DANGLING — "<command>" -> missing <path> | MALFORMED — unsubstituted placeholder
```

Row order = the spec's `tools` order, or the fallback order in §3.2. Token spellings `ok` / `not wired` /
`DANGLING` / `MALFORMED` are byte-preserved (NFR-2).

---

## 6. Flow

```
/harness-status run
      │
      ├─ §0  resolve effective hook source ────────────────────────────────┐
      │      read .claude/settings.local.json  → state                     │  ≤2 file reads
      │      read .claude/settings.json        → state                     │  no writes
      │      unknown-precedence → resolve → machine dimension → print line │
      │                                                                     ▼
      │                       { SOURCE, SOURCE_KIND, HOOKS_JSON, UNKNOWN_FILES, OTHER_DECLARES, MACHINE_STATE }
      │                                     │            │            │
      ├─ §1  guard asset row  ◄─────────────┘            │            │   (names SOURCE; 14 rows unchanged)
      ├─ §3b guard verdict    ◄──────────────────────────┘            │   (decision table §3.3 + fix line §5.3)
      │        └─ hook-spec matcher/semantics guard-rm (soft) ───────►│
      ├─ §3c congruence       ◄───────────────────────────────────────┘   (rows from hook-spec tools/event, or fallback)
      ├─ §6  health point     ◄─ §3b row 8 only
      └─ §7  recommendations  ◄─ SOURCE_KIND + MACHINE_STATE
```

Worked trace on **this repository** (the AC-1/AC-2 expectation):
`C1 = .claude/settings.local.json` parses, `hooks` has 4 keys ⇒ `present` ⇒ `SOURCE`, `SOURCE_KIND =
machine-local`. `C2 = .claude/settings.json` parses with `"hooks": {}` ⇒ `empty` ⇒ `OTHER_DECLARES = false`.
Detection finds `guard-rm.sh` in the PreToolUse command (`.claude/settings.local.json:22`); extraction yields
`.harness/scripts/guard-rm.sh` (space-preceded, matches the left bound); the file exists ⇒ **row 8,
`installed and wired`, +1**. Matcher `"Bash"` = canonical. First token `sh`, on PATH. §3c: 4 rows, all `ok`.

---

## 7. Reuse audit

### 7.1 What this design reuses instead of inventing

| Need | Existing code / doc | File path | Decision |
|---|---|---|---|
| Precedence "machine-local first, committed fallback" | F.2's `f2_hooks_file` selection | `.harness/scripts/verify_all.sh:303-308` (PS twin mirrors) | **Reuse the shape**, not the code. Divergence stated below. |
| Four-state settings probe (`absent`/`unreadable`/`empty`/`present`) | `settings_hook_state` | `.harness/scripts/install-hooks.sh:54-94` | Reuse the **vocabulary** (its `unparseable` slot is spelled `unreadable` here) and the **empty/present boundary for well-formed files**, so report and installer share one predicate on every file that parses. **Deliberately stricter on two classes B-7 mandates** — non-regular files and byte-broken-but-`{…}` files — see the §3.1 Step 0.1 divergence table (round 2, F-4). Not "verbatim", and *not* "can never disagree". Script untouched. |
| Hook id / event / matcher / semantics enumeration | hook wiring spec CLI | `.harness/scripts/hook-spec.sh:18-32,120` (+ `.ps1` twin) | Invoke as a soft dependency (OQ-3a). No spec change. |
| Script-path extraction from a hook command | left-bounded pattern | `skills/harness-status/SKILL.md:97-99` | Reuse **byte-identical to the live line 98** (unescaped `.` before `(ps1\|sh)` — copy, do not retype; round 2, F-5). Preserves B-11 and B-19 by construction. What §3.3 adds is not a pattern change but a **quantifier over the set it already returns** (F-1). |
| Tri-state hook vocabulary + repair trigger | `ok`/`not wired`/`DANGLING`/`MALFORMED` | `skills/harness-status/SKILL.md:89-121`, consumer `skills/harness-upgrade/SKILL.md:29-33` | Preserve byte-for-byte (NFR-2). |
| "guard is fail-closed" statement | rule fragment + spec | `.harness/rules/75-safety-hook.md`, `hook-spec semantics guard-rm` | **Reference by name, never restate** (insight 2026-06-20). |
| Machine-local repair path facts | installer early-return + doc lines | `.harness/scripts/install-hooks.sh:38,156-161`; `.harness/rules/75-safety-hook.md:95-110` | Reuse as the FR-8 fix line; docs untouched. |
| Committed-file repair path fact | upgrade helper's settings target | `.harness/scripts/upgrade-project.sh:248-251` | Reuse as the FR-8 fix line. |
| Fallback event list | existing §3c skeleton | `skills/harness-status/SKILL.md:84-92` | Reuse as the B-15 fallback; no new list authored. |
| Avoiding a new guard check | composition-over-accretion precedent | insight 2026-06-09 (T-016) | Applied: check count stays 32 (NFR-3). |

**Stated divergence from F.2** (deliberate, and it is *why* T-15 exists): F.2 selects the machine-local file
when it contains the substring `"PreToolUse"`; §0 selects it when it declares a **non-empty hooks object**.
§0's predicate is the broader and more honest one (a machine-local file wiring only `Stop` still wins the
precedence, and the guard is then correctly reported *wiring absent*). **F.2 is not touched by this task** —
narrowing it is T-15, deliberately chained behind this row.

### 7.2 New code justified

No new script, no new dependency, no new library, no new service. The single new artifact is a section inside
an existing skill document. The one *runtime* dependency the report gains — `hook-spec` — already ships
(`.harness/scripts/hook-spec.{sh,ps1}`, distributed twin at
`skills/harness-init/templates/common/.harness/scripts/hook-spec.{sh,ps1}`) and is consumed as a **soft
dependency** with a working fallback, so it adds no precondition for any project.

### 7.3 Complete edit ledger

**IN — files the delivery may change**

| # | Path | Change | Reason it is in |
|---|---|---|---|
| 1 | `skills/harness-status/SKILL.md` | new §0; rewrite §1 guard row, §3b, §3c header + source sentence, §6 bullet, §7 conditionals, Anti-patterns | The defect lives here (FR-1…FR-19) |
| 2 | `CHANGELOG.md` | new subsection under the existing unreleased `## [0.45.0]` heading (OQ-6a) — or the tripwire branch in §9 | FR-20 + AC-12 (G.4 requires a heading for the manifest version) |
| 3 | `docs/features/hook-truth-status/*` | stage docs | Pipeline artifacts |
| 4 | `docs/tasks.md` | one appended delivery row **at stage 7** | Append-only board convention; not a stage-4 edit |

**OUT — with the reason each site is excluded**

| Path | Why out |
|---|---|
| `CONTEXT.md` | Already carries **effective hook source** and **health report** (`CONTEXT.md:84-93`), added by the requirement stage, and this design coins no new term and sharpens none. Editing it would be churn. |
| `AI-GUIDE.md` | Contains no statement about where the health report reads hook wiring; its skill index is trigger-level only. Adding the precedence there would restate a nuance single-sourced in the skill (insight 2026-06-20). |
| `docs/dev-map.md` | Its two harness-status entries (`:50`, `:163`) say "Show Harness health" / "Read-only inspection" — no hook-source claim, so nothing is falsified. |
| `.harness/rules/75-safety-hook.md` (+ its `.tmpl` twin) | Describes the guard's own wiring, override and disable path, and already carries the T-12 relocation note and the T-13 persistent-opt-out section. It makes no claim about the health report, so FR-20 does not reach it; §3b **points at it** instead. |
| `.harness/scripts/verify_all.{sh,ps1}` F.2 | **T-15 owns it.** Touching it here would move the gate's guard semantics under the wrong task. |
| `.harness/scripts/verify_all.{sh,ps1}` I.6 list | OQ-9a: no retired-claim entry added (four-file lockstep + `I6ExpectedEntryCount` in `test-verify-i6.{ps1,sh}` — insight 2026-06-08). |
| `.harness/scripts/test-supervisor.{sh,ps1}` | OQ-7a: no assertion added. Edited **only** if a delivered row edit changes what an existing assertion matches — then updated to the new expected state, never deleted (AC-10). §10 gives the escalation rule if that happens. |
| `.harness/scripts/hook-spec.{sh,ps1}`, `install-hooks.{sh,ps1}`, `.claude/settings*.json`, `settings.json.tmpl` | Out of scope §3.3/§3.4; AC-11 requires the delivery to change no hook behavior. |
| `upgrade-project.*`, `migrate-scripts-layout.*`, `skills/harness-init/SKILL.md`, `skills/harness-adopt/SKILL.md` | The four command-derivation flows are **T-16**. |
| `skills/harness-upgrade/SKILL.md` | Consumes `DANGLING`/`MALFORMED`, which this design preserves verbatim; nothing to update (NFR-2). |
| `README.md`, `README.zh-CN.md` | Their harness-status lines (`:34`) describe the snapshot's topics, not the hook source; badges are frozen (§3.10). |
| `docs/manual-e2e-test.md` | Its section D expectation names assets/baseline/verify/tasks/score — no hook-source claim. |
| `.harness/rejected-decisions.md` | The declines here (no new gate check, no I.6 entry, no byte-comparison against the spec) are already **binding OQ answers recorded in `01_REQUIREMENT_ANALYSIS.md`**, which archives with the task; AC-11 pins the delivery's file set and this memory file is not in it. Recording the same decline twice would duplicate a nuance. |
| Template distribution of this skill | **None exists** — harness-status is plugin-provided; `skills/harness-init/templates/**/skills/` holds only `build`/`test`/`verify` SKILL templates (verified by glob). No twin to keep in lockstep. |
| `.claude/skills/` | Empty in this repo (verified); nothing to sync. |
| `docs/proposals/frontier-gaps-2026-07.md` | Untracked operator backlog — not edited, not referenced, not committed (Out-of-scope §3.9). |

**Frozen decoys — DO NOT TOUCH** (per insight 2026-06-19, enumerated explicitly):

| Decoy | Why it must not move |
|---|---|
| `CHANGELOG.md:86` (`harness-status §3c`, v0.44.0), `:368` (v0.31.0), `:924,938,947,1160,1171` | Historical entries describing past states |
| `docs/tasks.md:30,43` and every other historical row | Append-only history |
| `.harness/insight-index.md:26` (the structural-pin line) | Describes a past state; a *new* line may be appended at delivery per `.harness/rules/05-insight-index.md` |
| `.harness/scripts/baseline.json:11` `test_init_ps_assertions: 316` and the README test-init badge | Frozen pending the standing operator PowerShell run (Out-of-scope §3.10, NFR-5) |
| harness-status "**All 14 required assets**" and "Total possible: **12**" | HEALTH denominators, not skill counts — they do not move in this task |
| `docs/walkthrough.html`, `architecture.html`, `docs/project-overview.html` | Archived snapshots |
| `docs/features/_archived/**` | History |
| `.harness/scripts/verify_all.{sh,ps1}` C.1/G.1/G.2 skill-name arrays | Skill count 17 unchanged |

**Structurally-pinned surface (must survive byte-identical)** — `skills/harness-status/SKILL.md:34-37`, the
"the framework agents (7 + supervisor) are **plugin-provided**" note. `test-supervisor.sh:394-396` /
`test-supervisor.ps1:435-437` match `\(7 \+ supervisor\).*plugin-provided` **on one line**, so the note must
not be re-wrapped, re-worded, or split. The second assertion (`test-supervisor.sh:397-399`) requires
`{pm,req,sol,gate,dev,review,qa}*` to stay **absent** — do not reintroduce it.

---

## 8. Risk analysis

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R-1 | A reflow of `SKILL.md:34-37` while editing the neighbouring §1 table silently breaks two `test-supervisor` assertions with no fan-out list naming the coupling (insight 2026-06-11, T-020 dev round 1) | High | The pinned surface is enumerated in §7.3; the Developer edits only the row's Path/Present cells; `test-supervisor.sh` is a **mandatory** post-edit run (§10), expected `PASS: 45 / FAIL: 0` from `baseline.json:16` |
| R-2 | A false-green: a healthy verdict computed while the file Claude Code actually loads is unparseable | **Hard reject (NFR-1)** | Step 0.2 gives `UNKNOWN` precedence over the FR-5 triple; rows 5-7 of §3.3 make every unverifiable wiring non-healthy; QA probe **P-11** asserts it (round 1 mis-cited this as "F9") |
| R-2b *(round 2, F-1)* | A false-green by **quantifier**: a multi-path guard command with one missing script, or a command that merely mentions `guard-rm` while wiring something else, reported `INSTALLED AND WIRED` on a guard that cannot run | **Hard reject (NFR-1)** + FR-18 ambiguity | §3.3 defines `PATHS` / `GUARD_PATHS` and quantifies rows 7-8 over the whole set: row 8 requires **all** of `PATHS` to exist **and** `GUARD_PATHS ≠ ∅`. Probes **P-6b** (multiplicity) and **P-6c** (mention-only) assert both directions; a row-8 result in either is a delivery-blocking defect |
| R-3 | The fix line points at a repair that cannot reach the named file (blanket `/harness-upgrade` for machine-local wiring) | High — it is a *wrong* instruction, worse than none | §5.3 keys the fix on `SOURCE_KIND`; AC-7 checks both directions against captured outputs |
| R-4 | The OQ-6 version state changes between design and delivery (0.45.0 gets committed/tagged), so folding into 0.45.0 leaves G.4 without a heading for the manifest version | Medium | §9 gives both branches with an explicit, checkable tripwire test the Developer runs at delivery time |
| R-5 | Spec coupling makes the report error out on a project generated before `hook-spec` shipped, or on an agent without Bash | Medium | Soft dependency: any non-zero exit, empty answer, missing twin, or absent shell ⇒ whole-answer fallback, labelled (B-15/B-16/B-18); AC-8 probes it |
| R-6 | Partial spec output silently mixed with fallback (an empty answer treated as valid) | Medium | §3.2 requires abandoning the **entire** spec answer on any failed query — never per-query mixing (B-16) |
| R-7 | The skill grows into an un-followable wall of prose, and the next editor re-inlines a settings path | Medium | One §0 with a six-field interface; every other section **points at §0 by name** and no section re-reads a settings path — an explicit Anti-pattern line makes this reviewable |
| R-8 | QA fixtures leak into the repo tree and break AC-11 | Medium | §10 mandates fixtures in a scratch directory outside the repo; AC-11 is checked with `git status --porcelain` |
| R-9 | A new phrase in the rewritten skill trips the I.6 retired-claim guard | Low | The 14 I.6 entries (`verify_all.sh:531-546`) concern CLAUDE.md composition / adopt / zh-policy; none has a settings-or-hooks anchor. The mandatory `verify_all` run is the check |
| R-10 | `.harness/insight-index.md` is at its 30-line cap, so the delivery's insight cannot land | Low | `.harness/scripts/archive-task` auto-rotates at archive time (`.harness/rules/70-doc-size.md:27`); no manual edit |
| R-11 | Whole-report precedence (OQ-1a) reports *wiring absent* on a project whose committed file wires the guard while a machine-local file wires only `Stop` | Low, by design | The cross-file note in §3.3 names the other file's guard entry, so the reader is never misled; the alternative (union) is exactly the unverifiable verdict OQ-1 rejects |

---

## 9. Migration / rollout plan

**Backwards compatibility**: total. No settings file, hook script, installer, template or gate check is
modified (AC-11); no project's hook behavior changes (NFR-2). Consumers of the report's vocabulary keep the
`DANGLING` / `MALFORMED` tokens. Projects with the committed-settings arrangement (`/harness-init` /
`/harness-adopt` output) resolve to `.claude/settings.json` and produce today's verdicts (FR-3, AC-3).

**Feature flag**: none — a documentation-level behavior correction has no runtime toggle, and a flag would
leave the false verdict reachable.

**Data migration**: none (§4).

**Version treatment — OQ-6, with the tripwire the PM made binding.** At the start of delivery the Developer
runs this exact test:

```
git log --oneline -1            # is the 0.45.0 delivery committed?
git tag --list 'v0.45.0*'       # is it tagged?
grep -n '"version"' .claude-plugin/plugin.json
```

- **Branch A (expected — 0.45.0 still unreleased in the working tree, i.e. HEAD is `cb0ed57 feat(v0.44.0)…`
  and no `v0.45.0` tag exists)**: OQ-6a. Add a new `### Fixed — hook-truth-status (T-14): …` subsection under
  the existing `## [0.45.0] - 2026-07-31` heading (`CHANGELOG.md:8`). **Move no version stamp.** G.3 and G.4
  stay green because the manifest still reads `0.45.0` and a heading for it exists.
- **Branch B (tripwire fires — 0.45.0 is committed *and* tagged)**: OQ-6b. Bump all four stamps together —
  `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, the `README.md` version badge, the
  `README.zh-CN.md` version badge (the exact set G.3 compares, `verify_all.sh:373-377`) — from `0.45.0` to
  `0.46.0`, and add a new `## [0.46.0] - <date>` CHANGELOG heading carrying this task's entry. **Do not touch
  the README test-init badge or `baseline.json:11`** — those are frozen for a different reason (§3.10) and
  are not version stamps. Verify with a `verify_all` run: G.3 + G.4 must both PASS.

The check count is **32** in both branches: no gate check is added, removed or narrowed, so the G.4
count claims (`AI-GUIDE.md`, `docs/dev-map.md` ×2, `.harness/rules/40-locations.md`, both README badges,
`docs/manual-e2e-test.md`, `baseline.json`) do not move.

**Rollback**: `git checkout -- skills/harness-status/SKILL.md CHANGELOG.md` restores the pre-task state.
Nothing stateful is created, so rollback is complete and free.

**PowerShell (NFR-5)**: **this design touches no `.ps1` file.** No item is added to the standing operator
PowerShell verification list in `.harness/scripts/baseline.json:23`, and no PowerShell verification is
claimed. The only `.ps1` files *related* to this change are `test-supervisor.ps1:435-440`, which assert on
the edited document; the design deliberately preserves both matched conditions, so the PS twin needs no edit.
If a delivered edit did change a matched condition, that is a scope change — see §10's escalation rule.

---

## 10. Verification strategy (what Developer and QA execute)

### 10.1 Developer (stage 4) — mandatory, tallies pasted from the run that produced them (NFR-6)

0. **BEFORE the first edit (round 2, gate Q-4 — AC-11 is otherwise unfalsifiable)**: run
   `git status --porcelain` and paste the output into `04_IMPLEMENTATION.md` under a heading
   `## Pre-edit tree baseline`. The tree already carries T-13's delivered-but-uncommitted changes
   (`01_REQUIREMENT_ANALYSIS.md:6`), so AC-11 is the **delta** between this baseline and the post-edit run of
   step 5 — not the post-edit listing itself. Skipping step 0 makes AC-11 unverifiable, and QA is instructed
   to report it as such rather than pass it.
1. Edit `skills/harness-status/SKILL.md` only (plus the §9 CHANGELOG branch).
2. `bash .harness/scripts/verify_all.sh` → paste the full summary. **Expect PASS 32 / WARN 0 / FAIL 0.**
3. `bash .harness/scripts/test-supervisor.sh` → paste the summary. **Expect `PASS: 45 / FAIL: 0`**
   (`baseline.json:16`, `test_supervisor_bash_no_python3_assertions`). This run is mandatory *because* the
   §1 row edit is a structurally-pinned touchpoint (insight 2026-06-11), not because a failure is expected.
4. Self-execute the new §0 → §3b → §3c procedure against this repository and paste the transcript into
   `04_IMPLEMENTATION.md` (this is the raw material for AC-1/AC-2; QA re-captures independently).
5. `git status --porcelain` → paste; **the delta against step 0's baseline** must list only the §7.3 IN set.
   T-13's pre-existing uncommitted entries appear in both listings and are expected tree state, not delivery
   changes.
5b. **Never hand-edit `.harness/insight-index.md` (round 2, gate §5 addition).** The index sits at **exactly
   30** evidence lines and I.4 WARNs above 30 (`verify_all.sh` I.4; `archive-task.sh:59,74-104` rotates when
   `total_after > 30`). A hand-appended line turns AC-9's `WARN 0` into `WARN 1` and fails the gate. The
   delivery insight goes into `07_DELIVERY.md`'s `## Insight` section and lands **only** via
   `.harness/scripts/archive-task`, which rotates. This binds Developer **and** QA.
6. **Escalation rule**: if either `test-supervisor` assertion changes match state, **stop and report to PM**
   before editing any driver — updating both shells' assertions would put a `.ps1` in the delivery and add an
   operator PowerShell item, which is a scope change this design deliberately excludes (§9, AC-10).
7. Do **not** run or modify `test-init` / `test-real-project` — neither references this skill (verified:
   `harness-status` appears in `.harness/scripts/` only in `verify_all.{sh,ps1}` name arrays and
   `test-supervisor.{sh,ps1}`).

### 10.2 QA (stage 6) — the executable probe protocol

**Probe definition**: "run the procedure against root `R`" = execute §0 Steps 0.1-0.5, then §3.3's decision
table, then §3.4, reading `R/.claude/settings.local.json`, `R/.claude/settings.json`,
`R/.harness/scripts/…`. Fixtures live in a **scratch directory outside the repository** (never inside the
tree — AC-11). Each probe's transcript is captured verbatim in `06_TEST_REPORT.md`.

| Probe | Fixture | Asserts |
|---|---|---|
| P-1 | this repository, as-is | AC-1: `installed and wired`, source named `.claude/settings.local.json` |
| P-2 | this repository, as-is | AC-2: four congruence rows, all `ok`, same source named |
| P-3 | committed settings wire the guard, **no** machine-local file, guard script present | AC-3 / FR-3 / B-1: `installed and wired`, source `.claude/settings.json` |
| P-4 | guard wired in machine-local, script present | B-2: `installed and wired`, machine-local named |
| P-5 | both files declare non-empty hooks | B-3 / FR-4: machine-local wins **and** the "ALSO declares" note appears |
| P-6 | guard wired (single-path command), script **deleted** | AC-4 dangling: command string + missing path printed, not healthy, no point; §5.2 (a) row-7 single-missing form |
| **P-6b** *(round 2, F-1)* | guard entry wires a **chained** command — `sh -c 'cd "$CLAUDE_PROJECT_DIR" && bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'` — with `guard-rm.sh` **deleted** and `harness-sync.sh` **present** | §3.3 row **7** and nothing else: `\|PATHS\| = 2`, one missing, verdict `WIRING DANGLING` listing `guard-rm.sh`, **not** `INSTALLED AND WIRED`, **no** `+1`. Then flip: restore `guard-rm.sh`, delete `harness-sync.sh` ⇒ **still row 7** (the *other* member missing also blocks the fail-closed command). Then restore both ⇒ row **8** with the `all 2 extracted paths exist` form |
| **P-6c** *(round 2, F-1)* | guard entry whose command **mentions** `guard-rm.sh` only in a non-extractable position (e.g. `sh -c 'echo checking guard-rm.sh; bash .harness/scripts/harness-sync.sh'`, `harness-sync.sh` present) | Detection fires (`K = 1`) but `GUARD_PATHS = ∅` ⇒ §3.3 row **6**, `WIRING DANGLING — … no extractable scripts/guard-rm.{sh,ps1} path in this command`, **no** `+1`. This is the false-green NFR-1 forbids; a row-8 result here is a hard reject |
| P-7 | `PreToolUse` present, no entry referencing guard-rm | AC-4 absent / B-8 |
| P-8 | neither declares hooks, machine-local **absent** (and a variant with no `.claude/` at all) | AC-5 / B-4 / B-6: never-installed sentence + installer fix; the retired "switched off" string absent |
| P-9 | machine-local present with `{"hooks":{}}` | AC-6 / B-5: opt-out sentence, **differs from P-8's** |
| P-10 | P-6 with wiring in machine-local vs in committed (in both, the *other* file declares no hooks) | AC-7: the two fix lines differ per §5.3 rows 1-2 |
| **P-10b** *(round 2, F-3)* | dangling guard wired in machine-local **while the committed file also declares a non-empty hooks object** (B-3 / FR-4 arrangement) | §5.3 row 3 fires: the printed fix is `rm .claude/settings.local.json` **alone**, and the string `&& .harness/scripts/install-hooks` **does not appear**. Assert both the presence of the new line and the absence of the old one — the finding was a *wrong* instruction, so absence is the load-bearing half |
| P-11 | machine-local is truncated/invalid JSON, committed wires a healthy guard | B-7 / FR-14 / R-2: `UNKNOWN`, no health point, no healthy claim |
| P-12 | guard matcher `*` / absent / compound | B-10: wired + matcher printed verbatim + non-canonical flag |
| P-13 | guard command `… bash {{SCRIPTS_DIR}}/guard-rm.sh` | B-12: MALFORMED, non-healthy |
| P-14 | guard command `bash scripts/guard-rm.sh` (old layout), file present | B-11: extracted and healthy |
| P-15 | a hook command under `build-scripts/deploy.sh` | B-19: not extracted, not flagged |
| P-16 | `.ps1` twin wired while only `.sh` exists | B-13: verdict follows the referenced path (OQ-4a) |
| P-17 | fixture root **without** `.harness/scripts/hook-spec.sh` | AC-8 / B-15: run completes, enumeration labelled fallback |
| P-18 | spec present but stubbed to exit 2 for `event` | B-16: same fallback; empty answer never treated as valid |
| P-19 | procedure executed with no shell available (file reads only) | B-18: §0 and all three FR-5 states still produced. **Disclosure (round 2, gate audit item 7)**: this probe rests on QA *not* using Bash, which no mechanism enforces. It is reported as a **discipline-based** probe with the tool list actually used pasted alongside — never as a mechanical pass |
| **P-20** *(round 2, F-7 / B-9)* | `SOURCE` declares **two** `PreToolUse` entries both referencing `guard-rm` (e.g. different matchers), both scripts present | §5.2 (b) `K >= 2` form prints, naming `2` and stating the first in document order was evaluated; the verdict comes from the **first** entry. Flip the two entries' order and confirm the evaluated entry follows document order, not content |
| **P-21** *(round 2, F-7 / B-14)* | guard command whose first token is an interpreter **not on PATH** on the probing host (e.g. a `pwsh …` command form on a unix host without pwsh), guard script present | §5.2 (c) unavailable form prints **with** the fail-closed consequence clause; the §3.3 row is **unchanged** by it (still row 8 if the path exists, per B-14); no command-rewrite proposal appears anywhere in the output |

**Mutation discipline (both directions, per insight 2026-06-19)**: for P-3/P-4/P-6/P-6b/P-8/P-9, flip exactly
one input at a time (delete the guard script; delete the *chained* script; empty the hooks object; remove the
machine-local file) and confirm the verdict flips to the expected neighbour **and** that no unrelated line
changes. A probe that cannot be made to fail is reported as vacuous, not as a pass.

**Fixture teardown is guard-blocked — plan for it (round 2, gate Q-3)**: `guard-rm.sh` resolves `$repoRoot`
from the nearest `.git/` ancestor of **cwd** (`.harness/rules/75-safety-hook.md:58-62`), so with cwd inside
this repository **every destructive verb aimed at a scratch path outside it is BLOCKED — fail-closed, by
design**. Both fixture teardown and P-6/P-6b's "delete the guard script" mutation therefore need
`HARNESS_ALLOW_OUTSIDE_RM=1` prepended to **that single call** (`guard-rm.sh:60-61`, which emits an auditable
stderr INFO line). QA **must not** "fix", disable, unwire or work around the guard to make a probe run —
doing so is an NFR-1 violation and a delivery-blocking event, not a test-harness detail. The override lines
are pasted into `06_TEST_REPORT.md` alongside the probe they enabled.

**Whole-repo checks**: AC-9 `bash .harness/scripts/verify_all.sh` (PASS 32 / WARN 0 / FAIL 0, check count 32,
14 asset rows, denominator 12); AC-10 `bash .harness/scripts/test-supervisor.sh` (45/0, assertion count
unchanged); AC-11 `git status --porcelain` **delta against §10.1 step 0's pre-edit baseline** vs the §7.3 IN
set; AC-12 G.4 green + a CHANGELOG heading for the manifest's version.

**AC-9's `WARN 0` has one non-obvious dependency (round 2, gate §5 addition)**: `.harness/insight-index.md`
holds **exactly 30** evidence lines and I.4 WARNs above 30. The delivery insight must land through
`.harness/scripts/archive-task` (which rotates at `total_after > 30`, `archive-task.sh:74-104`), never by
hand. If QA sees `WARN 1` on I.4, the first thing to check is whether a line was hand-appended to that index —
the fix is to revert the hand-edit, not to raise the cap.

**Determinism check for FR-18/AC-1**: two different agents (or one agent twice, in separate contexts)
executing P-1 and P-3 must produce the same verdict tokens and the same named source. Any step that required
judgment is a design defect and is reported as such.

---

## 11. Partition assignment

**Single-developer mode.** `.harness/agents/` contains no `dev-*.md` partition agent in this repository
(`AI-GUIDE.md:15`: partition agents live only in the init templates), so no partition table and no
inter-partition dispatch order apply. All edits in §7.3's IN set are the single Developer's.

---

## 12. Out-of-scope clarifications (design boundaries)

This design does **not** cover, and the Developer must not implement:

1. Narrowing `verify_all` F.2 to repository-answerable assertions — **T-15**.
2. Re-pointing the four command-derivation flows at the hook wiring spec — **T-16**.
3. Any change to a hook script's runtime behavior, to `hook-spec`, to `install-hooks`, or to the settings
   template (§3.3/§3.4 of the requirement).
4. Any new `verify_all` check, any new I.6 banned phrase, any new `test-supervisor` assertion (NFR-3, OQ-7a,
   OQ-9a). **Check count stays 32.**
5. Consulting `~/.claude/settings.json`, enterprise settings, or any location outside the project (OQ-8a).
6. Byte-comparing a wired command against `hook-spec command …` (OQ-3a) — the report never proposes rewriting
   a runnable command.
7. Auto-repair of any kind: the report names a fix and never performs one (FR-19).
8. Reconciling `baseline.json:11` `test_init_ps_assertions` or either README badge tied to it (§3.10).
9. Moving this repository's hooks back into the committed settings file (§3.7).
10. `docs/proposals/frontier-gaps-2026-07.md` — untracked, unreferenced, uncommitted.
11. **The three stale T-12 hook-location claims the gate found (gate F-8)** — `AI-GUIDE.md:110`,
    `docs/getting-started.md:180-182` and `.harness/rules/60-tool-handoff.md:72-74` each still say the Stop
    hook lives in `.claude/settings.json`, false in this repository since T-12. **Explicitly out of scope for
    T-14**, on the gate's own reasoning: none of them describes *where the health report reads hook wiring
    from*, so FR-20 does not reach them, and widening the §7.3 edit ledger to cover them would break AC-11's
    file-set assertion and drag two red-line-adjacent surfaces into a task that touches neither. PM is
    surfacing them to the stream as a backlog candidate. The Developer **must not** edit these three files.

---

## 13. Verdict

**READY** *(round 2 — all seven gate findings closed in place; see §14 for the per-finding delta)*

Every FR (FR-1…FR-20) maps to a named section: FR-1/FR-2 → §3.1 + §5.1; FR-3 → §3.1 Step 0.3 + P-3;
FR-4 → §3.1 Step 0.3 + §5.1 + P-5; FR-5…FR-7 → §3.3 decision table rows 4-8 (**now quantified over `PATHS` /
`GUARD_PATHS`**); FR-8 → §5.3 (**now four branches, keyed on `SOURCE_KIND` × `OTHER_DECLARES`**);
FR-9/FR-10 → §3.3 adjuncts + §5.2 (b)/(c) pinned strings + P-20/P-21; FR-11 → §3.3 extraction + OQ-4a in §3.5;
FR-12/FR-13 → §3.1 Step 0.4 + §5.2 (a); FR-14 → §3.1 Step 0.2; FR-15/FR-16 → §3.2 + §3.4 + §5.4; FR-17 → §3.5
(**`Present?` predicate now pinned**); FR-18 → the first-match-wins tables, the set quantifiers, and §10.2's
determinism check; FR-19 → §4 + §12.7; FR-20 → §7.3. All 20 boundary conditions B-1…B-20 now have a probe
**and** an explicit rule, except B-17 and B-20, which are rules only for stated reasons (B-17: shell-twin
selection is not probeable from a single shell — NFR-5; B-20: "read normally", §0 makes no tracked/untracked
claim and proposes no `.gitignore` change).

All ten OQ recommendations are adopted verbatim. **Two reading notes, now correctly labelled**: D-1 (FR-14 as
a precondition gate on FR-5) is an interpretation the gate adjudicated FAITHFUL and **accepted** — retained
unchanged; D-2 (NFR-4's invocation budget) is an **accepted, recorded deviation** from that NFR's literal
wording, `1+N+2` = 7 against a stated `1+N` = 5, with the RA wording to be corrected at archive time by an
agent permitted to edit it. Neither weakens the guard.

No new dependency, no new gate check, no new I.6 entry, no new `test-supervisor` assertion, no `.ps1`
touched, no frozen count moved. Check count stays **32**.

---

## 14. Round 2 — gate findings closed

Delta-review map. Every row cites the section that changed; sections not listed here are unchanged from
round 1 and were confirmed sound by the gate (§1's V-1…V-20, audit dimensions 1, 4, 5, 8).

| Finding | Severity | What changed | Where |
|---|---|---|---|
| **F-1** | **FAIL (blocking)** | §3.3 now defines two sets from `GUARD_ENTRY.command` — `PATHS` (all left-bounded extractions) and `GUARD_PATHS` (those whose `<name>` is `guard-rm`) — and restates the last three rows with quantifiers: **row 6** = `GUARD_PATHS = ∅`; **row 7** = `GUARD_PATHS ≠ ∅` ∧ **any** member of `PATHS` missing (every missing path printed); **row 8** = **all** of `PATHS` exist **and** `GUARD_PATHS ≠ ∅`. Three named consequences are spelled out (multiplicity determinism, no mention-only false-green, chained-script fail-closed). Matching §5.2 (a) strings added for the multi-path row-7 and row-8 forms and for row 6's corrected wording. Probes **P-6b** (chained command, three-way mutation) and **P-6c** (mention-only decoy) added; risk **R-2b** added | §3.3 (detection/extraction + table + rationale), §5.2 (a), §10.2 P-6b/P-6c, §8 R-2b |
| **F-2** | WARN | §3.5 pins the §1 guard row's `Present?` predicate: present **exactly** in §3.3 rows 5-8 (`SOURCE` exists ∧ `K ≥ 1` — FR-17's own condition), not present in rows 1-4. Its deliberate asymmetry with the row-8-only `+1` is stated, together with the reason the two answer different questions, so §6's `All 14 required assets present → +6` interacts with it without an unaided judgment call. Row count **14** and denominator **12** restated as frozen | §3.5 |
| **F-3** | WARN | §5.3 gains a fourth row: `SOURCE_KIND = machine-local ∧ OTHER_DECLARES = true` ⇒ `rm .claude/settings.local.json` **alone**, explicitly instructing *not* to chain the installer, with the `install-hooks.sh:152-155` early-exit quoted as the evidence. The `OTHER_DECLARES = false` branch keeps round 1's line. Probe **P-10b** added, asserting both the new line's presence **and** the old line's absence. (Also corrected the stale `install-hooks.sh:156-161` citation to `:159-162`) | §5.3, §10.2 P-10b |
| **F-4** | WARN | The "verbatim reuse / can never disagree" claim is **withdrawn** and replaced by a precise statement plus a two-row divergence table: same vocabulary (installer's `unparseable` = this design's `unreadable`) and same empty/present boundary **for well-formed files**; deliberately **stricter** on non-regular files (`install-hooks.sh:74-76` → `present`) and byte-broken-but-`{…}` files (`:78-93`, byte probe, never parses) — both `unreadable` here **because B-7 requires it**. An explicit conflict-resolution rule is added: the Step 0.1 table wins over the installer's source. Behavior is unchanged from round 1 | §3.1 Step 0.1, §7.1 row 2 |
| **F-5** | WARN | The shipping byte-form is now pinned explicitly: **the live text of `skills/harness-status/SKILL.md:98`**, with the **unescaped** `.` before `(ps1\|sh)`. The Developer copies the line and must not "fix" the dot; round 1's `\.` rendering is identified as a transcription artifact, not a change request | §3.3 (byte-form pin), §7.1 row 4 |
| **F-6** | WARN (relabel) | D-2 is relabelled from "no deviation intended" to **ACCEPTED DEVIATION from NFR-4's literal wording** (`1+N+2` = 7 vs stated `1+N` = 5), with why it is unavoidable (FR-9/FR-10 + no combined `hook-spec` query + spec out of scope), why it is safe (constant `+2`, NFR-4's stated purpose preserved), and its disposition: RA wording corrected **at archive time** by an agent permitted to edit the requirement — the architect cannot. Developer states the actual count `N+3` in `04_IMPLEMENTATION.md` | §3.2 D-2, §13 |
| **F-7** | WARN | Both rules gain pinned strings **and** probes: §5.2 **(b)** multiplicity adjunct (`guard entries matched: 1` / `<K> — first in document order evaluated`) with probe **P-20**; §5.2 **(c)** interpreter adjunct, both the on-PATH and the NOT-on-PATH form, the latter carrying the fail-closed consequence clause, with probe **P-21** that also asserts the §3.3 row is unchanged by interpreter availability (B-14). Nothing is left rule-only | §3.3 adjuncts, §5.2 (b)/(c), §10.2 P-20/P-21 |
| **F-8** | INFO (not routed) | Recorded as an explicit **out-of-scope** item with the gate's own reason (the three files make no claim about where the health report reads hook wiring, so FR-20 does not reach them; widening the ledger would break AC-11). Developer must not edit them; PM carries them to the stream as a backlog candidate | §12.11 |

**Gate additions folded in (not findings, but real holes):**

| Addition | Where |
|---|---|
| AC-9's `WARN 0` depends on the delivery insight landing via `archive-task`; the index is at exactly 30 lines and I.4 WARNs above 30 — never hand-edit it. Binds Developer **and** QA, with the "revert the hand-edit, don't raise the cap" instruction | §10.1 step 5b, §10.2 whole-repo checks |
| AC-11 needs a **pre-edit** `git status --porcelain` baseline in `04_IMPLEMENTATION.md`; the criterion is the delta, because the tree already carries T-13's uncommitted changes | §10.1 step 0 (new), step 5 |
| QA fixture teardown outside the repo is **blocked by the fail-closed guard** — needs `HARNESS_ALLOW_OUTSIDE_RM=1` on that specific call, pasted into the test report; "fixing" the guard is a delivery-blocking NFR-1 violation | §10.2 (new teardown paragraph) |
| P-19 is discipline-based and mechanically unenforceable — disclosed as such with the tool list used, never reported as a mechanical pass | §10.2 P-19 |

**Unchanged and still binding** (re-affirmed, not re-derived): all ten RA `Recommended:` answers; **D-1's
reading accepted**; check count **32** with no new `verify_all` check, no new I.6 entry, no new
`test-supervisor` assertion; no `.ps1` touched; F.2 untouched (T-15); the four derivation flows untouched
(T-16); the structural pin at `skills/harness-status/SKILL.md:34-37` stays a single unbroken line matching
`\(7 \+ supervisor\).*plugin-provided` with `{pm,req,sol,gate,dev,review,qa}*` absent from the file; **OQ-6
Branch A is the expected branch** (no `v0.45.0` tag, manifest reads `0.45.0`) with §9's tripwire retained;
`docs/proposals/frontier-gaps-2026-07.md` untouched, unreferenced, uncommitted.

No round-2 change adds a dependency, a gate check, a script, or a `.ps1` file. Every change is confined to
this design document; the delivery's edit ledger (§7.3) is byte-identical to round 1.
