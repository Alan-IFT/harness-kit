# 02 — Solution Design: entropy-watch / T-11a

> Mode: **full** · Stage 2 (Solution Architect) · deferred-human mode: defer, do not ask.
> Upstream: `docs/features/entropy-watch/01_REQUIREMENT_ANALYSIS.md` — Verdict **READY** (slice decomposition T-11a/b/c + OQ defaults N=5 / `.harness/entropy-watch.state` / `/harness-goal`-execute accepted by PM).
> Scope: **T-11a only** — supervisor entropy lens + shared remind-if-due cadence check + cadence-state file + `/harness-stream` `## Entropy watch` surface + the thin new 17th skill + the authorize→execute hand-off + the COMPLETE 16→17 fan-out. T-11b (`/harness` stage-7 surface) and T-11c (findings persistence store) are explicitly deferred to their own slices.

## Overview

T-11a adds a **holistic, cadenced, observer-only entropy sweep** to the harness without introducing a new heavy engine, a new gate, or any blocking behavior. The change is additive across five seams: (1) the read-only `supervisor` agent gains an **Entropy lens** (a sixth detector family, EP-*, classifying with the T-07 deep-module vocabulary and emitting a fixed strength badge) — staying entirely inside its `Read, Write, Glob, Grep` boundary; (2) a single **shared "remind-if-due" cadence unit** is added as a `.{ps1,sh}` script pair `entropy-cadence.{ps1,sh}` under `.harness/scripts/` (joining the F.1 parity set), reading/writing the tiny fail-open `.harness/entropy-watch.state` file — so both `/harness-stream` (T-11a) and `/harness` (T-11b) invoke ONE definition of the due-logic and the threshold literal; (3) `/harness-stream` calls the cadence check at pool-drain and, when due, runs the entropy scan and surfaces an `## Entropy watch` section in `STREAM_REPORT.md` + an exit-message digest, mirroring the T-022 `## Needs your input` pattern; (4) a thin new 17th user-facing skill `harness-deflate` provides the manual entry point whose logic = run the supervisor entropy scan, present findings, and on explicit authorization hand a chosen finding to `/harness-goal` for the EXECUTE; (5) the authorize→execute hand-off is documented end-to-end and NEVER auto-runs. The whole feature is **non-blocking** (no new `verify_all` check, check count stays **32**) and ships under version bump **0.40.0 → 0.41.0** with the full 16→17 skill-count fan-out.

## Affected modules

| File | Disposition | What changes |
|---|---|---|
| `agents/supervisor.md` | edit | (a) Concise **Entropy-lens STUB** (~22 lines: what the lens is, EP-* family names, the one-write path, the scoped read-widening) + a **pointer** to the relocated detail; (b) a **scoped exception clause appended to Hard-rule #1** permitting read-only source reads in entropy mode. Detail (scan methodology + findings-artifact schema) lives in the sibling `references/entropy-scan.md` — see below. Projected post-edit count **≤300** (see §I.3 line-count projection) |
| `skills/harness-deflate/references/entropy-scan.md` | new | **Relocated lens DETAIL**: EP-1..EP-4 classification grammar table, deletion test, strength badge set, the full entropy-findings artifact schema, determinism + caps, the machine-readable `Entropy-verdict:` line spec. Pointed at by BOTH `supervisor.md` (stub) and `harness-deflate/SKILL.md` (the dispatch prompt) — one definition, two readers |
| `.harness/scripts/entropy-cadence.ps1` | new | Shared remind-if-due cadence unit (PowerShell half) |
| `.harness/scripts/entropy-cadence.sh` | new | Shared remind-if-due cadence unit (Bash half) — byte-symmetric behavior |
| `skills/harness-stream/SKILL.md` | edit | At pool-drain call the cadence check; when due run the scan + append `## Entropy watch` to STREAM_REPORT + lead exit message with the digest |
| `skills/harness-deflate/SKILL.md` | new | The 17th skill: manual scan → present findings → authorize → hand to `/harness-goal` |
| `README.md` | edit | Count 16→17, new skill bullet, version badge 0.40.0→0.41.0 |
| `README.zh-CN.md` | edit | Count 16→17 (`16 个`→`17 个`), new skill bullet, version badge |
| `CHANGELOG.md` | edit | New `## [0.41.0]` section above `[0.40.0]` |
| `AI-GUIDE.md` | edit | Count `16 skills`→`17 skills` (×2 occurrences), new Workflow-entry table row |
| `docs/getting-started.md` | edit | `sixteen skills`→`seventeen skills`, new skill bullet in the Pipeline/Operations list |
| `docs/manual-e2e-test.md` | edit | `sixteen`/`16 skills` count surfaces (lines 7, 34, 49) + skill enumerations (lines 36, 54, 62) |
| `.harness/rules/40-locations.md` | edit | "All 16 skills"→"All 17 skills"; add a "What lives where" row for the new skill |
| `docs/dev-map.md` | edit | New `harness-deflate/SKILL.md` line in the skills tree + a "Where features live" row + a reusable-utilities row for the cadence pair |
| `.claude-plugin/plugin.json` | edit | `version` 0.40.0→0.41.0 |
| `.claude-plugin/marketplace.json` | edit | `plugins[0].version` 0.40.0→0.41.0 |
| `.harness/scripts/verify_all.ps1` | edit | C.1/G.1/G.2 name arrays (+`harness-deflate`) + labels "16 skills"→"17 skills" (3 sites); **AND F.1 array (L270) +`"entropy-cadence"` + F.1 LABEL string (L269) +`entropy-cadence`** |
| `.harness/scripts/verify_all.sh` | edit | C.1/G.1/G.2 name arrays (+`harness-deflate`) + labels "16 skills"→"17 skills" (3 sites); **AND F.1 array (L284) +`entropy-cadence`** |

**Note on `.harness/skills/` mirror:** the dogfood ships skills at top-level `skills/<name>/`; the `.harness/skills/` Layer-2 mirror is empty in this repo (build/test/verify are template-only). The new skill is authored directly under `skills/harness-deflate/`; **no `harness-sync` is required** for this repo (consistent with T-03 / harness-grill).

## Module decomposition (new modules)

### 1. Supervisor Entropy lens — concise STUB in `agents/supervisor.md` + relocated DETAIL in `skills/harness-deflate/references/entropy-scan.md`

**Responsibility:** classify whole-codebase entropy using the T-07 deep-module vocabulary, name WHERE, attach a strength badge, run the deletion test — observer-only.

**I.3 relocation decision (Gate F-1).** Live `agents/supervisor.md` = **257 lines** (measured). The full inline lens block from the previous draft was ~66 lines → 257 + 66 ≈ **323 > the 300-line I.3 cap** (verify_all I.3 ps1 L381-393 / sh L402-414; rule 70 L26). **Decision: relocate the lens DETAIL** (the scan methodology + the findings-artifact schema) into a sibling reference file under the new skill folder — `skills/harness-deflate/references/entropy-scan.md` — and leave ONLY a concise stub + a pointer inside `supervisor.md`. Rationale for that home (over a `references/` note beside the agent or a rule fragment): the detail is read by exactly two consumers — the supervisor (when it adopts entropy mode) and the `harness-deflate` skill's Task-dispatch prompt — and the skill folder already exists in this slice, so the reference travels with the feature, gets I.6-scanned with the skill, and is the natural "compose, don't reconstruct" store (rule-15 P7). The supervisor stub and the skill dispatch prompt both *point at the same path*, so the methodology lives in exactly one place.

**1a. The concise STUB (inserted in `supervisor.md` after `## Anti-pattern catalog`, before `## Report schema`) — ~22 lines:**

```markdown
## Entropy lens (EP-*) — invoked only via /harness-deflate or a due /harness-stream drain

> A SEPARATE invocation mode from the per-task AP-* audit. It runs ONLY when dispatched
> in **entropy mode** by /harness-deflate or by /harness-stream at a due cadence boundary.
> The AP-* task-folder audit is unchanged and never triggers this lens.

**What it does (summary):** classify whole-codebase structural entropy with the T-07
deep-module vocabulary — **EP-1 shallow module · EP-2 cross-seam leakage · EP-3 coupling
cluster · EP-4 deepening candidate** — run the deletion test on each candidate, attach a
fixed strength badge (`Strong | Worth exploring | Speculative`), and write **exactly one**
artifact: `docs/features/_supervision/entropy-<ISO-date>.md` ending in the machine-readable
last line `Entropy-verdict: FINDINGS-PRESENT | CLEAN`.

**Read-set in entropy mode (scoped widening — see Hard-rule #1 exception):** you MAY
Glob/Grep/Read production source read-only to classify structure; you still write exactly
one file, still have NO Edit/Bash/PowerShell/Task, never refactor, never dispatch, never
edit an upstream doc. (AP-* mode keeps its narrow `.harness/`+task-folder whitelist.)

**Full method + artifact schema:** see `skills/harness-deflate/references/entropy-scan.md`
(EP classification grammar, deletion test, strength badge, the exact findings-artifact
schema, determinism + caps, the Entropy-verdict line spec). Follow it exactly in entropy mode.
```

**1b. The relocated DETAIL — new file `skills/harness-deflate/references/entropy-scan.md`** (the methodology + schema that used to be inline; pointed at by both the supervisor stub and the skill dispatch prompt):

```markdown
# Entropy scan reference (supervisor entropy lens + /harness-deflate)

## Classification grammar (T-07 vocabulary — use these terms exactly)
| Finding class | Signal |
|---|---|
| EP-1 shallow module | interface ≈ implementation (a thin pass-through; the interface is nearly as complex as what it hides) |
| EP-2 cross-seam leakage | a module's internals leak across its seam; callers depend on implementation detail |
| EP-3 coupling cluster | a knot of modules that must change together; no clean seam between them |
| EP-4 deepening candidate | a place where pulling complexity behind one deeper interface would raise leverage / locality |

## Deletion test (applied to every EP finding)
For each candidate: would deleting/inlining it CONCENTRATE complexity (signal — keep & deepen)
or merely MOVE it (no finding)? Record the verdict in one line per finding.

## Strength badge (fixed set — exactly one per finding)
`Strong` | `Worth exploring` | `Speculative`. (Distinct from AP severity INFO/WARN/ALERT
and from verify_all PASS/WARN/FAIL.)

## Entropy findings artifact (the one write)
Single-task-style path: `docs/features/_supervision/entropy-<ISO-date>.md` (create folder
if absent — same folder the cross-task report uses). Schema:

    # Entropy Watch — <ISO-timestamp>
    > by /harness-deflate (or /harness-stream drain) · supervisor.md entropy lens vX.Y.Z

    ## Findings
    | ID | Class | Where (file/module) | Strength | Deletion test |
    |---|---|---|---|---|
    | EP-001 | shallow module | path/to/file | Worth exploring | inlining moves complexity → minor |

    ## Detail
    ### EP-001 — <one paragraph: the friction, in T-07 terms>
    ...

    ## Methodology notes
    <what was/wasn't read; doc-cap note if hit>

    Entropy-verdict: FINDINGS-PRESENT | CLEAN

## Determinism + caps
The structured finding list (ID + class + Where + strength) is identical across runs over an
unchanged tree (NFR-6). Narrative prose may vary. The artifact obeys the ≤200-line
SUPERVISION_REPORT-class cap; on overflow emit `(entropy report truncated: 200-line cap hit)`
in Methodology notes — never silently drop findings.

## Entropy verdict line (machine-readable)
Last non-blank line, exact regex `^Entropy-verdict: (FINDINGS-PRESENT|CLEAN)$`. This lets an
automated reader (the stream surface) detect "findings present" without parsing the body.
(It is DISTINCT from the AP-* `Verdict: HEALTHY|WATCH|INTERVENE` line; an entropy-mode run
emits the Entropy-verdict line, not the AP verdict line.)
```

**1c. Coherence — scoped exception to Hard-rule #1 (Gate coherence note).** Live `supervisor.md` Hard-rule #1 (L22) currently states: *"You may NOT read production source code …"*. That is self-contradictory with the entropy-mode read-widening. **Edit Hard-rule #1 to append an explicit scoped exception clause** (no new rule number — extend rule #1 in place so the count of hard rules and the rule structure are unchanged):

```markdown
1. **Read-only-plus-one-write.** You may read the target task folder, `.harness/insight-index.md`,
   `docs/tasks.md`, `.harness/rules/65-intervention.md`, `.harness/rules/70-doc-size.md`. You may
   NOT read production source code, other tasks' folders (single-task mode), agent contracts, or
   any file outside this whitelist.
   **Exception — entropy mode only:** when dispatched in entropy mode (by `/harness-deflate` or a
   due `/harness-stream` drain), you MAY Glob/Grep/Read production source read-only to classify
   structure (see `## Entropy lens`). This widens READ scope ONLY; you still have no Edit/Bash/
   PowerShell/Task, still write exactly one artifact, never refactor, never dispatch. AP-* mode is
   unaffected and keeps the narrow whitelist above.
```

Mirror the same exception in the `## What "bad" looks like` bullet "Reading production code (out-of-scope…)" by appending "(except in entropy mode — see Hard-rule #1 exception)" so the two statements no longer contradict.

**I.3 line-count projection (Gate F-1, the load-bearing number).** Live = **257**. Edits to `supervisor.md`: stub block **+22** lines; Hard-rule #1 exception clause **+6** lines (the rule was 2 lines → 8 lines); the "bad" bullet parenthetical adds **+0** new lines (in-line append). The findings-artifact schema and the EP grammar tables — the bulk of the old +66 — move OUT to the reference file. **Projected `supervisor.md` = 257 + 22 + 6 = 285 lines ≤ 300.** Confirmed under the I.3 cap with ~15 lines of headroom. (The reference file `entropy-scan.md` is ~55 lines, well under any doc cap, and is NOT an agent so the I.3 agent-cap does not apply to it.)

**Boundary confirmation (AC-2):** the supervisor frontmatter stays `tools: Read, Write, Glob, Grep` — `Edit`/`Bash`/`PowerShell`/`Task`/`AskUserQuestion` remain physically excluded. The lens widens only the *read* scope (it may now Read production source in entropy mode, now made explicit as a Hard-rule #1 exception); it adds NO write/exec capability and still writes exactly one artifact. The observer boundary holds.

### 2. Shared remind-if-due cadence unit — `.harness/scripts/entropy-cadence.{ps1,sh}`

**Decision: script pair, NOT prose.** Rationale (per rule-15 P7 "store scripts; compose, don't reconstruct" + NFR-3 cross-shell parity): the unit does real logic — read a state file, fail-open on malformed/absent, increment-or-reset a counter, compute a due verdict from a threshold literal, write the file back with UTF-8/newline discipline (insights 2026-06-08 ×3, T-021). Prose-in-a-rule would force each of two callers (`/harness-stream` now, `/harness` in T-11b) to RE-IMPLEMENT the parse/threshold/fail-open in their own narrative — exactly the duplication AC-3 forbids. A script pair gives ONE definition both skills `call`, and the threshold literal `N=5` lives in exactly one place (one literal per shell half, kept byte-symmetric by NFR-3 parity review). This joins the F.1 script-pair parity set; it adds **no** new `verify_all` check (the count stays 32 — F.1 already iterates a curated set of pairs; adding `entropy-cadence` to that set extends an existing check's iteration list, it is not a new check row).

**F.1 is a HARDCODED allowlist, NOT a directory scan (Gate F-2 correction).** Measured: `verify_all.sh` F.1 (L282-288) and `verify_all.ps1` F.1 (L269-274) iterate a hand-curated 9-pair list (`verify_all, sync-self, harness-sync, test-init, test-real-project, ambient-prompt, ambient-reset, upgrade-project, language-policy`); the PS half ALSO repeats that list verbatim in its LABEL string (L269). It does **not** auto-discover pairs on disk (proof: `guard-rm`, `install-hooks`, `archive-task`, `migrate-scripts-layout` pairs exist on disk yet are deliberately absent from F.1). Therefore F.1 does **not** auto-extend — the developer MUST explicitly add `entropy-cadence` to the F.1 array in BOTH shells and to the PS-side label. These are explicit fan-out-ledger rows (see ledger rows 40-42 below). This is still NOT a new check (extending an array ≠ a new check row); the count stays **32**. Cross-shell *behavioral* parity of the new pair is enforced by NFR-3 review discipline (the byte-symmetry review), not by F.1 — F.1 only checks pair PRESENCE, not behavioral drift (Gate Finding 3).

**Public API (sub-command dispatch; identical contract in both shells):**

| Invocation | Effect | Output (stdout, one line) |
|---|---|---|
| `entropy-cadence check [--first-of-session]` | read state; compute due verdict; **no write** | `DUE` or `NOT-DUE` |
| `entropy-cadence delivered` | increment delivered-since-sweep counter by 1; write state | `count=<n>` |
| `entropy-cadence swept` | reset counter to 0; stamp last-sweep marker = now; write state | `reset` |

**Due logic (single source of truth — the ONLY place the threshold lives):**
```
N = 5                                  # the one threshold literal
due = (count >= N) OR (first_of_session AND count >= 1)
```
- `check --first-of-session` is passed by the stream on the FIRST drain of a session (behavior 13b). `/harness` (T-11b) will pass plain `check` (counter path only).
- `>= N` is inclusive (boundary row: counter == N is DUE).
- Both triggers firing on one drain still yields a single `DUE` → one scan (boundary row: no double-surfacing — the skill runs the scan once per due verdict).

**Fail-open contract (AC-8, boundary rows 1-2):**
- File absent → treat as `count=0`, no last-sweep → `check` returns `NOT-DUE` UNLESS `--first-of-session` and… (count is 0, so first-of-session alone is NOT due — first-of-session requires count ≥ 1; an absent file with zero deliveries is correctly not-due). `delivered` creates the file on first write.
- File malformed/unreadable → `check` returns `NOT-DUE` (fail-open, never crash); the next `delivered`/`swept` write self-heals. Mirrors the ambient-hook fail-open (always exit 0).
- The script NEVER exits non-zero on a state-file problem — a drain/delivery must never be blocked by cadence I/O.

### 3. `.harness/entropy-watch.state` file shape

A single tiny key=value record (gitignored, like `.harness/ambient.flag` / `.harness/intervention.md`):
```
delivered_since_sweep=3
last_sweep=2026-06-18T09:14:00Z
```
- Two lines, ASCII, LF newline, written UTF-8 (no BOM) by both shells (T-021 byte discipline).
- `last_sweep` may be empty/absent before the first sweep — absence is never an error.
- **No open-findings pointer in T-11a** (that is T-11c's `.harness/entropy-findings.md`); the state file holds only cadence in this slice. (The RA's OQ-2 mentions an open-findings pointer; deferring it keeps T-11a's state minimal and is a T-11c concern.)
- Add `.harness/entropy-watch.state` to `.gitignore` (alongside `ambient.flag`).

### 4. The 17th skill — `skills/harness-deflate/SKILL.md`

**Name decision: `harness-deflate`.** Rationale: "deflate" is a single vivid leading word (rule-15 vocabulary) for "push accumulated entropy back down" — it reads as the inverse of entropy/bloat and does not collide with `/harness-grill` (align requirement), `/harness-supervise` (per-task audit), or `/harness-goal` (the execute engine it delegates to). `harness-improve` was considered and rejected: too close to `/harness-goal`'s "keep improving until X" trigger surface and to the per-task review stages — it would muddy the when-NOT delta (rule-15 P1). `harness-deflate` is unambiguous as "the holistic anti-entropy sweep + authorize-execute entry".

**Responsibility:** thin orchestration only — it owns NO scan engine and NO refactor loop. It (a) dispatches the supervisor entropy lens, (b) presents the findings to the user, (c) on explicit authorization hands the chosen finding to `/harness-goal`. It is **user-invoked** (the operator's requested "新增功能").

**Frontmatter (rule-15 compliant — model-facing description, when-NOT delta):**
```yaml
---
name: harness-deflate
description: Holistic anti-entropy sweep. Scans the WHOLE codebase (not one task) for
  accumulated structural rot — shallow modules, cross-seam leakage, coupling clusters,
  deepening candidates (the deep-module vocabulary) — via the read-only supervisor entropy
  lens, presents each finding with WHERE + a Strong/Worth-exploring/Speculative strength
  badge, and on your explicit authorization hands the chosen deepening to /harness-goal to
  refactor it to verify_all green. Machine reminds, you authorize, machine executes — it
  NEVER refactors without authorization. Use when "clean up the codebase entropy", "what's
  rotting / where's the ball of mud", "do an anti-entropy sweep", "减熵巡检", "做一次反熵巡检",
  "整体看看哪里在腐化". NOT /harness-supervise (per-task pipeline-anti-pattern audit, not
  whole-codebase structure), NOT /harness-goal directly (that's the execute engine this skill
  drives — use this when you want the sweep+findings first), NOT /harness (a defined feature,
  not an open-ended deepening).
allowed-tools: Read, Glob, Grep, Task
---
```
Note `allowed-tools` excludes `Edit`/`Bash`/`PowerShell` from the skill itself — the skill never edits or runs the scan logic in-process; it dispatches the supervisor (scan) and `/harness-goal` (execute) via `Task`. The cadence script is invoked by the *stream* skill (which already has Bash/PowerShell), not by `harness-deflate` in T-11a (the manual sweep is always "due").

**Procedure (skill body, abbreviated):**
1. Adopt the supervisor entropy lens: dispatch `harness-kit:supervisor` via `Task` in entropy mode (the dispatch prompt names "entropy lens / EP-* / follow `skills/harness-deflate/references/entropy-scan.md` / write `docs/features/_supervision/entropy-<ISO-date>.md`"). The reference file is the SINGLE source of the scan methodology + artifact schema — the supervisor stub and this dispatch prompt both point at it (no duplication).
2. Read the findings artifact; present the findings table to the user (ID, class, Where, strength, deletion-test).
3. If `Entropy-verdict: CLEAN` → report "no entropy findings" and stop (no execute step).
4. **Authorize gate (AC-9):** ask the user which finding(s) to deflate (or "none"). NEVER proceed without an explicit pick. If the user declines a finding → (T-11c will record it to `rejected-decisions.md`; in T-11a, note the decline and do not execute).
5. **Execute (on authorization):** dispatch `/harness-goal` with goal = "land the EP-<id> deepening: <Where> — <one-line solution>" and success criterion = "`.harness/scripts/verify_all` is green AND the deepening described in EP-<id> is in place". `/harness-goal` runs the Dev+QA loop to green.
6. Report the outcome.

## Data model changes

None in the schema/DB sense (this repo has no DB). The only persisted state is the new flat `.harness/entropy-watch.state` file (§3) — two key=value lines, gitignored, fail-open. No `docs/tasks.md` header change, no `BATCH_PLAN.md` column change, no new `verify_all` column.

## API contracts

The "API" here is the cadence-script CLI contract (§2 table) and the supervisor entropy-mode artifact contract (§1). Both are spelled out above. Status/exit-code contract for `entropy-cadence`:
- `check` → exit 0 always; stdout `DUE`/`NOT-DUE`.
- `delivered`/`swept` → exit 0 on success; on a write failure, exit 0 with stderr note (fail-open — never block the caller). No non-zero exit path that could halt a drain or delivery.

## Sequence / flow

**A. Stream drain, cadence due (the headline T-11a loop):**
```
/harness-stream drains pool → (per delivered task) calls `entropy-cadence delivered`
   ... pool reaches drained-frontier ...
On exit (Procedure step 4 / "On stream completion"):
   call `entropy-cadence check [--first-of-session]`
     ├─ NOT-DUE → write STREAM_REPORT as today; no scan; no ## Entropy watch section
     └─ DUE →
          dispatch supervisor (entropy mode) via Task → writes entropy-<date>.md
          read Entropy-verdict line
          append `## Entropy watch` section to STREAM_REPORT.md (after `## Needs your input`)
          call `entropy-cadence swept`  (reset counter, stamp last-sweep)
          exit message leads with: needs-input digest (if any) THEN entropy digest
   Drain still exits NORMALLY (non-blocking — verdict unchanged).
```

**B. Manual sweep + authorize→execute (`/harness-deflate`):**
```
user runs /harness-deflate
  → dispatch supervisor (entropy mode) → entropy-<date>.md
  → present findings table
  → user authorizes EP-<id>   (NO authorization ⇒ STOP, zero edits — AC-9)
  → dispatch /harness-goal (goal = land EP-<id>; criterion = verify_all green)
  → /harness-goal Dev+QA loop → verify_all green → report
```

**Ordering rule (behavior 8 — distinct sections):** in `STREAM_REPORT.md` the `## Needs your input` section stays FIRST (T-022 invariant unchanged); `## Entropy watch` is appended AFTER it. The exit message leads with needs-input (if any), then the entropy one-line digest. The two are distinct sections; this fixed ordering satisfies "ordering between them is fixed by the design stage".

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Read-only codebase observer | `supervisor` agent (Read/Write/Glob/Grep, deterministic findings, one-write, doc-cap, machine-readable verdict line) | `agents/supervisor.md` | **Extend** with the EP-* entropy lens (not a new engine) — direct fulfillment of the INPUT reuse mandate |
| Deep-module vocabulary (shallow / seam / coupling / deepening + deletion test) | T-07 design vocabulary; reference clone | `docs/features/_archived/sa-design-vocab/`; `c:\Programs\_research\mattpocock-skills\skills\engineering\codebase-design/` | **Reuse** as the EP classification grammar |
| Recommendation-strength badge (`Strong`/`Worth exploring`/`Speculative`) | mattpocock `improve-codebase-architecture` SKILL | reference clone | **Reuse** the exact 3-value set |
| End-of-drain surfacing pattern (FIRST section + exit-message-leads-with-digest) | T-022 `## Needs your input` | `skills/harness-stream/SKILL.md` "On stream completion" | **Reuse the pattern**; add a distinct `## Entropy watch` section after it |
| Execute-to-green loop (Dev+QA, open-ended, criterion-bounded) | `/harness-goal` | `skills/harness-goal/SKILL.md` | **Reuse as-is** for the EXECUTE step (no new pipeline) |
| Tiny gitignored fail-open state file precedent | `.harness/ambient.flag`, `.harness/intervention.md` | `.harness/` + `.gitignore` | **Mirror the pattern** for `.harness/entropy-watch.state` |
| Cross-shell script-pair discipline (UTF-8/LF/threshold-in-one-place) | ambient-prompt/reset, guard-rm, F.1 set | `.harness/scripts/*.{ps1,sh}` | **Follow the pattern** for `entropy-cadence.{ps1,sh}` |
| Decline memory (T-11c) | `.harness/rejected-decisions.md` | `.harness/rejected-decisions.md` | **Defer to T-11c** (reuse target named, not wired in T-11a) |
| Skill-count fan-out ledger discipline (16→17, C.1/G.1/G.2 dual-shell, decoys) | T-03 harness-grill (15→16) | CHANGELOG `[0.36.0]` "Release fan-out" | **Reuse the ledger template** (§Fan-out ledger below) |
| Whole-codebase scan ENGINE (heavyweight, separate) | (none — and explicitly declined) | — | **Not built** — INPUT reuse mandate + out-of-scope 4; the supervisor lens covers it |

## Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| 1 | **Fan-out miss** — a 16→17 surface (esp. one of the 6 hardcoded C.1/G.1/G.2 array/label sites across 2 shells) is left at 16, OR a frozen decoy (CHANGELOG history, tasks.md rows, harness-status "14 assets", version-history table rows in README) is wrongly flipped. | The exhaustive ledger below lists every live site with current→target strings and every DO-NOT-TOUCH decoy. AC-11 has QA mutation-test both directions. verify_all C.1/G.1/G.2 FAIL loudly if a live array/label is missed. |
| 2 | **Supervisor read-set widening erodes the observer boundary.** | The lens adds READ scope only; frontmatter stays `Read, Write, Glob, Grep` (no Edit/Bash/Task). One write, no dispatch, no upstream edit — re-Read-to-verify retained. AC-2 word-boundary check over the contract confirms the excluded tools. The widened read is scoped to entropy mode; AP-* mode keeps its narrow whitelist. |
| 3 | **Cadence I/O blocks a drain/delivery** (malformed file crashes the script; non-zero exit halts the loop). | Fail-open contract (§2): `check` always returns `NOT-DUE` on any state problem, always exit 0; `delivered`/`swept` never non-zero on write failure. Mirrors the proven ambient-hook fail-open. Boundary rows 1-2 + AC-8 cover it. |
| 4 | **Cross-shell drift** between `entropy-cadence.ps1` and `.sh` (newline/encoding/threshold literal). | F.1 only checks pair **PRESENCE**, not behavioral drift (Gate Finding 3) — and F.1 is a hardcoded allowlist, so the pair must be EXPLICITLY added to it (ledger rows 40-42). Behavioral parity is enforced by **NFR-3 byte-symmetry review discipline**, not by a gate: UTF-8/LF per T-021; the `N=5` literal appears once per half and is a required parity-review checkpoint. AC-3 grep proves the threshold lives in one place per shell. |
| 5 | **Nag fatigue / double-surfacing** — scan runs too often, or both due-triggers fire and surface twice. | Cadence default N=5 (NFR-1); scan runs once per `DUE` verdict; `swept` resets immediately so the same boundary doesn't re-trigger; boundary rows (both-triggers, two-boundaries-one-session) covered. |
| 6 | **Auto-refactor without authorization** (the user's hardest red line). | The skill `allowed-tools` excludes Edit/Bash; the scan agent physically cannot refactor; the execute step is a SEPARATE explicit `/harness-goal` dispatch gated on an explicit user pick (AC-9). No code path reaches an edit without authorization. |
| 7 | **Determinism break** — re-running the scan over an unchanged tree yields a different structured finding list, making re-surfacing dishonest. | EP detectors are signal-rule-based (not mood-based), IDs stable per artifact/class/Where; the contract states the structured list is identical across runs (NFR-6, parity with supervisor NFR-5). |

## Migration / rollout plan

- **Backwards compatibility:** purely additive. Existing `/harness-stream` drains behave identically when cadence is NOT-DUE (the only added cost is one `entropy-cadence check` read on exit). No existing skill's verdict, schema, or column changes. The `/harness` surface is NOT touched in T-11a (T-11b adds it via the same shared check).
- **Feature flag:** none needed — cadence itself is the throttle; a project that never reaches N and never has a qualifying first-of-session drain simply never sees a scan. The state file is auto-created on first `delivered`.
- **Data migration:** none — `.harness/entropy-watch.state` is created on first write; absence is the valid initial state.
- **Rollout sequence (dispatch order below):** cadence script pair → supervisor lens → stream wiring → new skill → fan-out + version bump → verify_all green (PS operator-pending per deny rule).
- **Rollback:** revert is clean — delete the two new files (`entropy-cadence.*`, `harness-deflate/SKILL.md`), revert the additive sections in `supervisor.md` / `harness-stream`, and roll the fan-out back to 16 / 0.40.0. No persisted user data depends on the feature.

## The COMPLETE 16→17 fan-out ledger

> Live count is **16**; target **17**. Version **0.40.0 → 0.41.0**. New skill name **`harness-deflate`**. The skill add does NOT add a `verify_all` check (count stays **32**); the new `entropy-cadence.{ps1,sh}` pair joins **F.1** (an existing check's set) and likewise adds no check.
>
> **F.1 is a HARDCODED allowlist (Gate F-2) — it does NOT auto-extend.** Adding `entropy-cadence` to F.1 requires three EXPLICIT edits, captured as ledger rows **40-42** below: the PS array (L270), the PS label string (L269), and the SH array (L284). These are array/label edits, not a new check row — count stays **32**.

### LIVE surfaces to update

| # | File | Site | Current → Target |
|---|---|---|---|
| 1 | `README.md` | L7 banner | `16 skills + 8 framework agents` → `17 skills + 8 framework agents` |
| 2 | `README.md` | L15 | `gives any project sixteen AI skills` → `seventeen AI skills` |
| 3 | `README.md` | Pipeline skills list (after L24 `harness-stream` bullet) | **add** `- /harness-kit:harness-deflate — …` bullet |
| 4 | `README.md` | L5 version badge | `version-0.40.0-blue` → `version-0.41.0-blue` |
| 5 | `README.zh-CN.md` | L7 banner | `16 个 skills + 8 个框架 agent` → `17 个 skills + 8 个框架 agent` |
| 6 | `README.zh-CN.md` | L15 | `给任何项目装上 16 个 AI skill` → `17 个 AI skill` |
| 7 | `README.zh-CN.md` | 运维类 list (after L37 `harness-decision-mode` bullet) | **add** `- /harness-kit:harness-deflate — …` bullet |
| 8 | `README.zh-CN.md` | L5 version badge | `version-0.40.0-blue` → `version-0.41.0-blue` |
| 9 | `CHANGELOG.md` | top (above `## [0.40.0]` L8) | **add** new `## [0.41.0] - <date>` section: the entropy-watch T-11a feature + "skill count 16 → 17 (C.1/G.1/G.2 in both shells); version 0.40.0 → 0.41.0; verify_all stays 32 checks; new `entropy-cadence.{ps1,sh}` pair explicitly added to the F.1 hardcoded allowlist (PS array+label, SH array)" |
| 10 | `AI-GUIDE.md` | L7 | `distributes 16 skills + templates` → `17 skills + templates` |
| 11 | `AI-GUIDE.md` | "Workflow entry" table (after the `/harness-stream` row, ~L96) | **add** a row: Anti-entropy sweep / triggers / `/harness-deflate` |
| 12 | `docs/getting-started.md` | L36 | `Either path makes sixteen skills available` → `seventeen skills` |
| 13 | `docs/getting-started.md` | skill list (Pipeline or new Operations bullet) | **add** `harness-deflate` bullet |
| 14 | `docs/manual-e2e-test.md` | L7 | `load the sixteen skills` → `seventeen skills` |
| 15 | `docs/manual-e2e-test.md` | L34 | `prints "Would copy" for all 16 skills (…)` → `17 skills` + add `harness-deflate` to the paren list |
| 16 | `docs/manual-e2e-test.md` | L36 | enumeration — add `harness-deflate` |
| 17 | `docs/manual-e2e-test.md` | L49 | `prints "Installed" for all 16 skills` → `17 skills` |
| 18 | `docs/manual-e2e-test.md` | L54 | directory-listing enumeration — add `harness-deflate` |
| 19 | `docs/manual-e2e-test.md` | L62 | slash-command enumeration — add `/harness-deflate` |
| 20 | `.harness/rules/40-locations.md` | L31 | `All 16 skills present with valid frontmatter` → `All 17 skills present…` |
| 21 | `.harness/rules/40-locations.md` | "What lives where" table | **add** a row pointing at `skills/harness-deflate/SKILL.md` (anti-entropy sweep) |
| 22 | `docs/dev-map.md` | skills tree (~L58, after `harness-grill`) | **add** `harness-deflate/SKILL.md ← Anti-entropy sweep (v0.41+)` line |
| 23 | `docs/dev-map.md` | "Where features live" table | **add** a row for harness-deflate + entropy-cadence pair |
| 24 | `docs/dev-map.md` | "Reusable utilities" / scripts mention | **add** `entropy-cadence` (cadence check) to the script inventory + note F.1 membership |
| 25 | `.claude-plugin/plugin.json` | L4 `version` | `0.40.0` → `0.41.0` |
| 26 | `.claude-plugin/marketplace.json` | L17 `plugins[0].version` | `0.40.0` → `0.41.0` |
| 27 | `.harness/scripts/verify_all.ps1` | C.1 L68 label | `"All 16 skills present with SKILL.md"` → `"All 17 skills present with SKILL.md"` |
| 28 | `.harness/scripts/verify_all.ps1` | C.1 L69 array | append `, "harness-deflate"` |
| 29 | `.harness/scripts/verify_all.ps1` | G.1 L299 label | `"README references all 16 skills"` → `"…all 17 skills"` |
| 30 | `.harness/scripts/verify_all.ps1` | G.1 L301 array | append `, "harness-deflate"` |
| 31 | `.harness/scripts/verify_all.ps1` | G.2 L325 label | `"CHANGELOG mentions all 16 skills"` → `"…all 17 skills"` |
| 32 | `.harness/scripts/verify_all.ps1` | G.2 L327 array | append `, "harness-deflate"` |
| 33 | `.harness/scripts/verify_all.sh` | C.1 L56 array | append ` harness-deflate` |
| 34 | `.harness/scripts/verify_all.sh` | C.1 L59 label(s) | `"All 16 skills present"` → `"All 17 skills present"` (both PASS+FAIL label args) |
| 35 | `.harness/scripts/verify_all.sh` | G.1 L329 array | append ` harness-deflate` |
| 36 | `.harness/scripts/verify_all.sh` | G.1 L332 label | `"README references all 16 skills"` → `"…all 17 skills"` |
| 37 | `.harness/scripts/verify_all.sh` | G.2 L345 array | append ` harness-deflate` |
| 38 | `.harness/scripts/verify_all.sh` | G.2 L348 label | `"CHANGELOG references all 16 skills"` → `"…all 17 skills"` |
| 39 | `.gitignore` | ignore list | **add** `.harness/entropy-watch.state` (alongside `ambient.flag` / `intervention.md`) |
| 40 | `.harness/scripts/verify_all.ps1` | F.1 array L270 (hardcoded 9-pair allowlist) | append `, "entropy-cadence"` to the `@( … )` pair list |
| 41 | `.harness/scripts/verify_all.ps1` | F.1 LABEL string L269 (enumerates every pair by name) | append `, entropy-cadence` to the comma list before `"exist in both .ps1 and .sh"` |
| 42 | `.harness/scripts/verify_all.sh` | F.1 array L284 (hardcoded `for pair in …` allowlist) | append ` entropy-cadence` to the space-separated pair list |

**Fan-out file count: 17 files** (README.md, README.zh-CN.md, CHANGELOG.md, AI-GUIDE.md, getting-started.md, manual-e2e-test.md, 40-locations.md, dev-map.md, plugin.json, marketplace.json, verify_all.ps1, verify_all.sh, .gitignore) — the first 12 fan-out targets + .gitignore + the 4 produced/edited core files (supervisor.md, harness-stream/SKILL.md, entropy-cadence.ps1, entropy-cadence.sh, harness-deflate/SKILL.md). Counting only the **distinct files touched by the whole T-11a slice: 20 files** (13 fan-out/ledger files including .gitignore + supervisor.md + harness-stream SKILL.md + 2 cadence scripts + new skill SKILL.md + the new `references/entropy-scan.md` relocated-detail file). The **pure 16→17 ledger** spans **13 files** (rows 1-39 above collapse to README ×2, CHANGELOG, AI-GUIDE, getting-started, manual-e2e, 40-locations, dev-map, plugin.json, marketplace.json, verify_all ×2, .gitignore). Note: rows 40-42 (the F.1 explicit-add) touch verify_all ×2 — already counted in the ledger's verify_all entries, so no new file.

### DO-NOT-TOUCH decoys (must NOT flip to 17)

| Decoy | Where | Why frozen |
|---|---|---|
| Historical `## [x.y.z]` CHANGELOG entries (`[0.19.0]` "10→11", `[0.22.0]` "11→12", `[0.36.0]` "15→16", `[0.40.0]` "stays 16", etc.) | `CHANGELOG.md` body | Frozen history — those counts were correct at the time |
| `docs/tasks.md` delivery rows | `docs/tasks.md` | Frozen task-board history |
| README version-history table rows (L270-280: `0.18.1`..`0.33.0` "skills stay 15" / "11→12" etc.) | `README.md` / `README.zh-CN.md` | Frozen per-version history |
| `docs/proposals/*` HTML | `docs/proposals/` | Frozen design artifacts |
| `.harness/insight-index.md` historical lines | `.harness/insight-index.md` | Append-only memory; never rewrite past lines (≤30-line cap) |
| harness-status **"14 required assets"** / "+6 health points" denominator | `skills/harness-status/SKILL.md` L135 | DIFFERENT concept (health-asset denominator, not skill count) — NOT a skill count |
| `8 framework agents` count | README ×2 / AI-GUIDE | Agent count is unchanged (supervisor is extended, not added) — leave at 8 |
| `32 checks` / `32/32` badge | everywhere | Check count is unchanged — no new verify_all check |

## Out-of-scope clarifications (T-11a design boundaries)

- **NOT designed here (T-11b):** the `/harness` stage-7 delivery `## Entropy watch` surface. The shared `entropy-cadence` script is built reuse-ready (plain `check` sub-command, no first-of-session flag) so T-11b wires it in without re-defining the due-logic.
- **NOT designed here (T-11c):** the open-findings persistence store (`.harness/entropy-findings.md`), the decline→`rejected-decisions.md` wiring, and open/fixed/declined re-surfacing. T-11a's state file holds cadence only; the skill's authorize step names the T-11c reuse targets but does not persist findings across sweeps.
- **No new `verify_all` check / gate / guard** (out-of-scope 2; feedback_design_over_guards). The reminder is informational output, never a gate.
- **No visual HTML report** (out-of-scope 7) — the surfaces are the existing markdown STREAM_REPORT + the entropy artifact. The mattpocock HTML idea is a candidate follow-up, not committed.
- **No background/streaming scan, no every-drain scan, no cross-repo aggregation** (out-of-scope 5, 6, 8, 9).
- **No test-init seed asset.** `harness-deflate` is a top-level dogfood skill, not a template asset; `.harness/entropy-watch.state` is gitignored runtime state, not shipped. So **no test-init baseline reseed is required** (no new `.tmpl` under `skills/harness-init/templates/`, no shipped count change). The cadence script is dogfood-only in this slice (templating the entropy watch into generated projects is a future concern, not T-11a).

## Confirmations (per dispatch checklist)

- **Non-blocking / no new gate:** confirmed — the reminder never gates a drain or delivery; no new `verify_all` check; check count stays **32**.
- **No new check from the new skill:** confirmed (a skill adds to the C.1/G.1/G.2 name *arrays*, not a check row).
- **No new check from the cadence pair:** confirmed — `entropy-cadence.{ps1,sh}` joins the existing **F.1** script-pair parity set by THREE EXPLICIT ledger edits (rows 40-42: PS array L270, PS label L269, SH array L284). **F.1 is a hardcoded allowlist and does NOT auto-extend** (Gate F-2 correction — the earlier "F.1 auto-extends when a pair is added" claim was factually wrong and is retracted). Extending the allowlist array/label is not a new check row; the count stays **32**.
- **I.3 / I.6 / doc-size caps:** `agents/supervisor.md` is **257 lines live** (measured); the edit is now a **concise stub (+22) + a Hard-rule #1 exception clause (+6)** = **projected 285 lines ≤ 300** — the I.3 cap is met with ~15 lines of headroom (Gate F-1). The lens DETAIL (EP grammar + deletion test + strength badge + the full findings-artifact schema) is RELOCATED to `skills/harness-deflate/references/entropy-scan.md` (~55 lines, not an agent so the I.3 agent-cap does not apply; well under doc caps). The new SKILL.md and rule edits stay under their caps; no I.6 banned-phrase resurfacing in either new file; entropy artifact respects the ≤200-line SUPERVISION_REPORT cap with a truncation note.
- **No test-init seed needed:** confirmed (no shipped template asset in T-11a).
- **PS-deny:** confirmed — sub-agents cannot run PowerShell; the operator/PM runs the PS-side `verify_all` (PS may be operator-pending per the deny rule); the Bash-side verify_all is run by the developer/QA.
- **Cross-shell parity (NFR-3):** the cadence pair + the verify_all array/label flips must be byte-symmetric across `.ps1`/`.sh`; UTF-8/LF discipline (T-021).

## Partition assignment

`.harness/agents/` contains no `dev-*.md` files in this repo (single-Developer mode). Partition table omitted per contract.

## Dispatch order (single Developer, sequential)

1. `.harness/scripts/entropy-cadence.{ps1,sh}` + `.gitignore` entry (foundation; no deps).
2. `skills/harness-deflate/references/entropy-scan.md` — the relocated lens DETAIL (foundation for both the supervisor stub and the skill; no deps). Authored first so the supervisor stub's pointer resolves.
3. `agents/supervisor.md` — concise entropy-lens stub + Hard-rule #1 scoped exception (points at step 2's reference file; projected 285 lines ≤ 300).
4. `skills/harness-stream/SKILL.md` wiring (depends on 1 + 3).
5. `skills/harness-deflate/SKILL.md` (depends on 2 + 3 + reuses `/harness-goal`).
6. The 16→17 fan-out ledger + version bump + the F.1 explicit-add (rows 40-42) (depends on 5 existing — the array flips reference the new skill name; the F.1 rows add `entropy-cadence`).
7. `verify_all` green (Bash by dev; PS operator-pending).

## Verdict

**READY** (rework round 2 — Gate F-1 + F-2 + coherence note resolved).

Rework deltas applied: **F-1** — the lens DETAIL is relocated to `skills/harness-deflate/references/entropy-scan.md`, leaving a concise stub + pointer in `supervisor.md`; projected `supervisor.md` = **257 + 22 (stub) + 6 (Hard-rule #1 exception) = 285 ≤ 300** (I.3 met, ~15 lines headroom). **F-2** — F.1 is confirmed a hardcoded allowlist (not a directory scan); explicit ledger rows 40-42 add `entropy-cadence` to the PS array (L270), PS label (L269) and SH array (L284); the false "F.1 auto-extends" prose is retracted in §2 and §Confirmations; Risk #4 reworded (F.1 checks presence, not drift — parity rests on NFR-3 review). **Coherence** — `supervisor.md` Hard-rule #1 gains an explicit scoped exception permitting read-only source reads in entropy mode (and the matching "bad-looks-like" bullet is qualified), removing the self-contradiction.

Unchanged from the Gate-approved draft (no churn): the 16→17 fan-out ledger (rows 1-39, line-exact), the observer boundary (frontmatter still `Read, Write, Glob, Grep`), the reuse audit, non-blocking posture (no new verify_all check — count stays **32**, agents **8**), version **0.41.0**, cross-shell parity for entropy-cadence, and the harness-deflate skill (rule-15 compliant). Every T-11a behavior (1-8, 10-19, 25) still maps to a concrete file change with an exact contract; the authorize→execute hand-off never auto-runs. No upstream gap; not BLOCKED.
