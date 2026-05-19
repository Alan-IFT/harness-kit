# 02 — Solution Design · supervisor-agent (T-003)

Mode: `full` · Stage: 2/7 · Author: Solution Architect · Date: 2026-05-19 · Target version: **v0.17.0** (next semver after T-002's v0.16.0; `CHANGELOG.md` will gain a `[0.17.0]` block; `.claude-plugin/plugin.json` + `marketplace.json` + README/zh-CN badges bump to `0.17.0` per `verify_all.ps1:332-354` G.3).

## 1. Overview

We add an **8th, observer-only** agent (`.harness/agents/supervisor.md`) and a manual-only skill (`skills/harness-supervise/SKILL.md`) that read an in-flight or archived 7-stage task folder and emit exactly one file: a single-task `SUPERVISION_REPORT.md` or a cross-task aggregate. The supervisor detects four anti-patterns (AP-1 rollback-rate, AP-2 stage-doc-thinness, AP-3 missing-intervention-checks, AP-4 missing-archive-call) with fixed thresholds declared in `supervisor.md` itself, classifies findings into three severities (`INFO`/`WARN`/`ALERT`), and emits a final `Verdict: HEALTHY | WATCH | INTERVENE`. The 7-stage pipeline, all existing agents, all existing rule fragments, and all 9 distributed skills are **untouched**; the supervisor is auxiliary and on-demand. `verify_all` grows 29 → 30 with one new passive guard (`I.7`) that WARNs when an `INTERVENE` report has been ignored for ≥48h on an active task. The mock-fixture pattern reuses T-002's `HARNESS_AI_NATIVE_MOCK` shape but with a supervisor-scoped env var (`HARNESS_SUPERVISOR_MOCK`). Test surface lives in a **new** `scripts/test-supervisor.{ps1,sh}` pair (rationale: §11), not folded into `test-init`. All changes are additive; AC-10 (running `/harness` end-to-end with supervisor present yields byte-identical stage docs to v0.16.0) is the binding back-compat assertion.

## 2. Architecture / Module decomposition

| Unit | Kind | Responsibility |
|---|---|---|
| `.harness/agents/supervisor.md` | new agent contract (dogfood) | Read-only-plus-one-write role contract; declares AP-1..AP-4 thresholds, severity vocabulary, report schema, `allowed-tools` whitelist |
| `skills/harness-init/templates/common/.harness/agents/supervisor.md` | new agent contract (template, byte-identical mirror) | Distribution copy; kept in sync by existing `sync-self.ps1:38-48` (`dir-of-md` mapping already syncs the whole `.harness/agents/` folder — no script edit needed) |
| `skills/harness-supervise/SKILL.md` | new skill | Single entry point with three arg shapes: `<task-slug>`, `--recent <N>`, `--all`. Dispatches the supervisor agent (or runs inline — see Decision A2) and surfaces the report path |
| `skills/harness-supervise/fixtures/sample-task/` | new test fixture (committed) | Minimal 7-stage task folder used by `test-supervisor` to verify AC-4 (2-rollback → WARN) and AC-5 (3-rollback → ALERT). Contents: `PM_LOG.md` with synthetic stage entries, plus stub `01_*.md`..`07_*.md` files |
| `skills/harness-supervise/fixtures/supervisor-mock.json` | new mock fixture | Canned report response loaded when `HARNESS_SUPERVISOR_MOCK=<path>` is set; shape mirrors T-002's `ai-native-mock.json` (per Decision A3) |
| `scripts/test-supervisor.{ps1,sh}` | new symmetric test runner | ~30 assertions covering AC-4..AC-7 + boundary conditions; FAIL on any |
| `scripts/verify_all.{ps1,sh}` `I.7` check | new check (passive guard) | Asserts: for every `docs/features/<slug>/SUPERVISION_REPORT.md` whose last line is `Verdict: INTERVENE`, the task is NOT marked active in `docs/tasks.md` OR the file mtime is <48h old. Severity: WARN |
| `docs/features/_supervision/` | new conventional folder | Cross-task reports live here (`cross-task-<ISO-date>.md`). `.gitignore` rule optional — analyst Q-6 leaves it to user preference; we recommend tracking |

No changes to: any of the 7 canonical agent files, any `.harness/rules/*.md` fragment, the existing 9 skills, `sync-self.{ps1,sh}` body (its `dir-of-md` mapping at `sync-self.ps1:39` already covers the new agent), `harness-sync.{ps1,sh}` body (same reason).

## 3. Decisions log

| # | Decision | Analyst-preferred | Architect-final | Rationale |
|---|---|---|---|---|
| Q-1 | Skill name `/harness-supervise` | verb-form | **Same** | Matches `/harness-verify`, `/harness-intervene`; confirmed by `skills/harness-*/SKILL.md` Glob — every distributed skill is verb-form |
| Q-2 | Invocation mode (manual-only) | manual-only | **Same — confirmed** | Auto-dispatch would require editing `pm-orchestrator.md` (`.harness/agents/pm-orchestrator.md:131-148` "How to start a task"), which violates AC-10's additive-only contract. v0.18+ can add a `pm-orchestrator.md` clause once false-positive budget is proven against ≥10 real tasks. Override declined |
| Q-3 | Severity scheme `INFO`/`WARN`/`ALERT` | 3-level | **Same** | Distinct from `verify_all`'s `PASS`/`WARN`/`FAIL` (the report describes process rot, not script failure); see `scripts/verify_all.ps1:22-35` for the existing palette we deliberately avoid colliding with |
| Q-4 | verify_all integration (1 check, WARN) | 1-check-WARN | **Same** | Slot is `I.7` under the doc-size/passive-guard group (see §10); follows the I.* convention (`verify_all.ps1:357-413` for the I.* family) |
| Q-5 | Always-loaded vs on-demand | on-demand | **Same** | Supervisor agent file lives in `.harness/agents/` but is NOT listed in `AI-GUIDE.md`'s agent line (`AI-GUIDE.md:43-46`); PM Orchestrator never reads it; only `/harness-supervise` references it. Zero context cost when unused |
| Q-6 | Cross-task storage (`_supervision/`) | separate folder | **Same** | `_archived/` is per-task scope (`scripts/archive-task.ps1` semantics); cross-task reports are project-scope. Separate folder avoids `archive-task` accidentally moving them |
| Q-7 | Anti-pattern catalog in agent file | agent-contract-declared | **Same** | Thresholds (`≥2` for WARN, `≥3` for ALERT) live in `supervisor.md` as a Markdown table. Adding AP-5 is one agent-file edit; no rule-fragment churn |
| **A-1** (architect) | Fixture shape for AC-7 | (not asked) | **Two-layer fixture**: real task-folder fixture at `skills/harness-supervise/fixtures/sample-task/` for AC-4/AC-5 (deterministic anti-pattern detection on synthetic inputs); separate `supervisor-mock.json` for AC-7 (bypasses any AI dispatch when env var set; emits canned report) | T-002 conflated "mock" with "fixture"; separating them lets AP-1..AP-4 logic be tested on real Markdown inputs (catches regex bugs) while still allowing CI to skip live LLM calls |
| **A-2** (architect) | Skill dispatch vs inline execution | (not asked) | **Inline execution by the orchestrator AI running the skill** (no `Task` tool dispatch, no sub-agent fan-out). The skill prompt embeds a "read this file, behave like the supervisor.md role" instruction | NFR-4 mandates the agent's `allowed-tools` exclude `Task`; symmetrically the skill should not need `Task` either. Inline keeps the skill tool-agnostic (Copilot/Cursor can play the supervisor role without programmatic dispatch). Matches T-002 Decision A1 |
| **A-3** (architect) | `SUPERVISION_REPORT.md` schema (header set fixed) | (not asked) | **Six required sections in fixed order** (see §7): `## Summary`, `## Findings`, `## Anti-pattern detail` (one subsection per AP-N triggered), `## Cross-references`, `## Methodology notes`, `## Verdict`. Last non-blank line of file MUST match `^Verdict: (HEALTHY\|WATCH\|INTERVENE)$` (drives the `I.7` regex without a parser) | Deterministic structure lets AC-6 snapshot-test on T-002 archived state; lets `I.7` use one-line regex over the file tail rather than full parse |
| **A-4** (architect) | `I.7` lookup path | (not asked) | The check Globs `docs/features/*/SUPERVISION_REPORT.md` (NOT `_archived/`), reads the last 5 lines via `Get-Content -Tail 5` / `tail -n 5`, regex-matches the verdict line, and cross-references the task slug against the active-row set in `docs/tasks.md`. mtime computed via `(Get-Item).LastWriteTime` / `stat -c %Y`. Threshold 48h is a constant in the script | Bounded read (5 lines, not full file); insight-index L11 (CHANGELOG fan-out) doesn't apply here because we're adding a check, not bumping a doc count; insight-index L13 (`-cnotin` case sensitivity) doesn't apply because we're regex-matching a fixed-case verdict word |

## 4. File-level change set

| Status | Path | Note |
|---|---|---|
| A | `.harness/agents/supervisor.md` | New agent contract; ≤300 lines (I.3 cap); declares AP-1..AP-4 thresholds + severity table + report schema + `allowed-tools` line |
| A | `skills/harness-init/templates/common/.harness/agents/supervisor.md` | Byte-identical mirror; covered by `sync-self.ps1` `dir-of-md` mapping at line 39 |
| A | `skills/harness-supervise/SKILL.md` | New skill; `allowed-tools: Read, Write, Glob, Grep` (no `Edit`, no `Bash`, no `Task`, no `AskUserQuestion` — NFR-4) |
| A | `skills/harness-supervise/fixtures/sample-task/PM_LOG.md` | Synthetic PM_LOG with 2 same-stage rollbacks (AC-4 trigger) |
| A | `skills/harness-supervise/fixtures/sample-task/01_REQUIREMENT_ANALYSIS.md` ... `07_DELIVERY.md` | Minimal stage docs (some intentionally thin to trigger AP-2 deterministically) |
| A | `skills/harness-supervise/fixtures/sample-task-three-rollbacks/PM_LOG.md` | Variant with 3 same-stage rollbacks (AC-5 trigger → ALERT) |
| A | `skills/harness-supervise/fixtures/supervisor-mock.json` | Canned report fixture for `HARNESS_SUPERVISOR_MOCK` |
| A | `scripts/test-supervisor.ps1` | New symmetric test runner; ~30 assertions; gated by Python3 absence on bash side same as `test-init.sh:198-249` pattern |
| A | `scripts/test-supervisor.sh` | Symmetric bash twin |
| M | `scripts/verify_all.ps1` | Add `I.7` between current `I.6` (line 415) and the summary block (line 472). ~30 PS lines following the I.* pattern |
| M | `scripts/verify_all.sh` | Symmetric `I.7` block |
| M | `AI-GUIDE.md` | Bump line 35 check count `29/29 at v0.16.0` → `30/30 at v0.17.0`; bump line 67 same; **bump line 14 phrasing `7 agent role contracts` → `7 canonical agents + 1 auxiliary (supervisor)`** (gate finding F-3); add 1-line entry under "Scripts" mentioning `test-supervisor.{ps1,sh}`. Do NOT add supervisor to the agent line (Q-5 keeps it off the always-loaded list) |
| M | `CHANGELOG.md` | Add `## [0.17.0] — 2026-05-…` block. Per insight L21, this file is in the fan-out checklist for any count sweep |
| M | `README.md` + `README.zh-CN.md` | Bump version badge to `0.17.0` (G.3 enforces); add roadmap-row close + brief v0.17.0 release row |
| M | `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` | Bump version to `0.17.0` (G.3 enforces) |
| M | `docs/manual-e2e-test.md` | Bump check-count 29 → 30; add one walkthrough step for `/harness-supervise <slug>` |
| M | `docs/walkthrough.html` | Add a labeled-snapshot section for v0.17.0 supervisor flow (keep prior v0.6 snapshot banner) |
| M | `architecture.html` | Add supervisor as an out-of-band observer node in the diagram |
| M | `docs/dev-map.md` | Update line 72 check-count `29 checks at v0.16.0` → `30 checks at v0.17.0`; add `test-supervisor` row to scripts table; add `supervisor.md` row to agents table noting "auxiliary, not in 7-stage routing" |
| M | `docs/tasks.md` | Add T-003 row with mode=full, status=Completed at delivery; PM does this in stage 7 |
| M | `.harness/insight-index.md` | Appended at delivery (stage 7) by `scripts/archive-task` from `07_DELIVERY.md ## Insight`; auto-rotates if >30 lines per I.4 |
| (unchanged) | `.harness/agents/{pm,req,sol,gate,dev,review,qa}*.md` (7 files) | Layer-1 self-consistency — supervisor is purely additive; PM contract gains nothing (Q-2 manual-only) |
| (unchanged) | `templates/common/.harness/agents/{pm,...}*.md` (7 files) | Same |
| (unchanged) | `.harness/rules/*.md` (10 fragments) | No new rule fragment; AP catalog lives in `supervisor.md` per Q-7 |
| (unchanged) | All 9 distributed skills (`skills/harness*/SKILL.md` minus the new one) | Additive — no edits |
| (unchanged) | `sync-self.{ps1,sh}` body | `dir-of-md` mapping at line 39 automatically picks up the new agent file |
| (unchanged) | `harness-sync.{ps1,sh}` body | Same; `.harness/agents/ → .claude/agents/` is whole-dir |
| (unchanged) | `scripts/archive-task.{ps1,sh}` | Archive scope = per-task; cross-task reports under `_supervision/` are NOT moved (decision Q-6) |
| M | `skills/harness-status/SKILL.md` (line 24) | **Add a new row** `\| Supervisor (auxiliary) \| .claude/agents/supervisor.md \| ? \|` immediately below the existing canonical-7 row (gate finding F-2). Do NOT widen the glob `{pm,req,sol,gate,dev,review,qa}*.md` — its purpose is to enumerate the canonical 7; supervisor is auxiliary and listed separately. The "7-stage pipeline" wording elsewhere in the file is unchanged |

## 5. Reuse audit

| Need | Existing code | File path / line | Decision |
|---|---|---|---|
| Read-only agent contract precedent | `gate-reviewer.md` `tools: Read, Glob, Grep` | `.harness/agents/gate-reviewer.md:4` | **Reuse the pattern**: supervisor declares `tools: Read, Write, Glob, Grep` (one extra: `Write` for the single report file). Justification: gate-reviewer proves a read-only agent works; supervisor is "read-only-plus-one-write" |
| Template-↔-dogfood byte-identity for agents | `sync-self` `dir-of-md` mapping | `scripts/sync-self.ps1:39` | **Reuse as-is**; no script edit. The whole-dir mapping picks up `supervisor.md` automatically. AC-2 byte-identity is verifiable by `scripts/sync-self.ps1 -Check` exactly like the 7 canonical agents |
| Mock-env-var test pattern | `HARNESS_AI_NATIVE_MOCK` (T-002) | `skills/harness-init/SKILL.md` step 5b.4 + `templates/common/scripts/ai-native-mock.json` | **Extend the pattern with a new env var** `HARNESS_SUPERVISOR_MOCK`; same load-file-as-canned-response semantics. Insight L22 (separate temp dirs for bidirectional cases) applies if `test-supervisor` does on/off cases — see §11 |
| Doc-size cap on the report | I.* doc-size guards | `verify_all.ps1:357-413` | **No new I.* size check** for the report — the 200-line cap (matching rule fragment cap, declared in §7 below) is enforced by the skill prompt and verified by `test-supervisor`'s post-conditions, not by `verify_all`. Rationale: the report lives under `docs/features/<slug>/` which is task-scoped, not project-scoped; archive-task moves it out |
| Task-folder discovery | `Glob("docs/features/*/PM_LOG.md")` pattern | implicit in `pm-orchestrator.md:131-148` | **Reuse**; supervisor Globs the same pattern to enumerate tasks (cross-task mode) or resolve a single slug |
| Active-task detection (for `I.7`) | `docs/tasks.md` row format | `docs/tasks.md` | **Reuse**; `I.7` regex-matches rows where status is not `Completed`/`Archived`. Boundary: if `docs/tasks.md` is malformed, `I.7` returns PASS (don't FAIL on upstream parse errors per insight L11 conservatism) |
| Per-stage minimum-content checklists | (none exist as data) | — | **New, declared in `supervisor.md` §AP-2**. The contract for each stage's required sections lives in each agent contract (`.harness/agents/*.md`); supervisor's AP-2 table summarizes them. Risk R-1 (false positives) is mitigated by NFR-6 (zero ALERT on T-000/T-001/T-002) |
| Bidirectional test discipline | T-002 round-1 M-3 fix (separate temp dirs) | `scripts/test-init.{ps1,sh}` near line 289/271 | **Reuse pattern**: AC-4 (2-rollback fixture) and AC-5 (3-rollback fixture) live in **separate** fixture folders, not one shared folder with edits between cases. Closes insight L22 |
| CHANGELOG fan-out discipline | Insight L21 | `CHANGELOG.md` | **Honor explicitly** in §4; CHANGELOG is in the fan-out alongside README + AI-GUIDE + manual-e2e-test + dev-map + walkthrough + architecture |

## 6. Detailed flow

### (a) Single-task supervise — `/harness-supervise <slug>`

1. Skill resolves `<slug>`: try `docs/features/<slug>/`; if absent, try `docs/features/_archived/<slug>/`; if neither exists → write nothing, print `BLOCKED — task folder not found`. Exit.
2. Skill reads `.harness/agents/supervisor.md` (the role contract) and adopts the role.
3. If `HARNESS_SUPERVISOR_MOCK` env var is set and the file at that path is readable → load it as the canned report, write it to the destination (step 6), exit.
4. Read the task folder's present files: `PM_LOG.md`, `0[1-7]_*.md` (each if present). Read `.harness/insight-index.md`, `docs/tasks.md`, `.harness/rules/65-intervention.md`, `.harness/rules/70-doc-size.md`. No other reads (NFR-2).
5. Run AP-1..AP-4 detectors (§8). Collect findings with severity.
6. Compose the report per §7 schema. Write to `docs/features/<slug>/SUPERVISION_REPORT.md` (or `docs/features/_archived/<slug>/SUPERVISION_REPORT.md` if archived). One Write call. Re-Read to confirm (insight L10).
7. Print 3-line summary to user: report path, verdict, finding count.

### (b) Cross-task `/harness-supervise --recent N`

1. Glob `docs/features/_archived/*/07_DELIVERY.md` sorted by mtime descending; take first N (clamp `[1, available]`; INFO-log the clamp).
2. For each task, read ONLY `07_DELIVERY.md` + `PM_LOG.md` (NFR-2 — not all 7 stage docs).
3. Run AP-1..AP-4 per-task; aggregate counts.
4. Emit cross-task patterns: any AP-N appearing in ≥3 of N tasks → ALERT-level aggregate row.
5. Write to `docs/features/_supervision/cross-task-<ISO-date>.md` (create folder if absent). Cap 300 lines.
6. The `--all` shape is identical with N = count of archived tasks.

### (c) Active vs archived resolution

- Active (`docs/features/<slug>/PM_LOG.md` exists AND no `07_DELIVERY.md` yet) → supervisor evaluates partial pipeline; missing stage docs are NOT findings unless `docs/tasks.md` marks them complete.
- Archived (`docs/features/_archived/<slug>/`) → all 7 stage docs expected; absence IS a finding (`AP-2-missing-stage-doc`, severity WARN).
- Path conflict (slug exists in both): prefer active; INFO-finding about the duplicate.

## 7. Data shapes / file contracts

### `SUPERVISION_REPORT.md` schema (single-task)

```markdown
# Supervision Report — <slug>

> Generated <ISO-timestamp> by /harness-supervise · supervisor.md v0.17.0
> Target: docs/features/<slug>/ (or _archived/<slug>/)

## Summary
- Task: <slug>
- Mode: full | plan | explore | goal
- Stages present: <list>
- Rollbacks observed: <count by stage>
- Findings: <N INFO, M WARN, K ALERT>

## Findings
| AP | Severity | Where | Detail |
|---|---|---|---|
| AP-1 | WARN | Stage 5 | 2 rollbacks at code-review (round 1, round 2) |
| AP-2 | INFO | Stage 3 | gate-review doc is 18 lines (cap 200 — well under, no concern) |

## Anti-pattern detail
### AP-1 rollback-rate
<one paragraph + bullet list of rollbacks with line citations into PM_LOG.md>

### AP-2 stage-doc-thinness
<per-stage table>

(AP-3 / AP-4 subsections present only if findings exist for them)

## Cross-references
- Rule fragments consulted: .harness/rules/65-intervention.md, .harness/rules/70-doc-size.md
- Insight-index entries possibly relevant: (file:line list)

## Methodology notes
<2-4 lines: what supervisor did and did not read; assumptions>

Verdict: HEALTHY | WATCH | INTERVENE
```

The verdict line is the **last non-blank line** of the file, exact format `Verdict: <WORD>`. `I.7` greps for it via `Get-Content -Tail 5` and a one-line regex `^Verdict: (HEALTHY|WATCH|INTERVENE)$`.

### Cross-task report layout

Same skeleton, except `## Summary` lists N tasks scanned; `## Findings` rows are aggregate (AP × count-of-tasks); cap is 300 lines.

### Mock fixture shape (`supervisor-mock.json`)

```json
{ "report_md": "# Supervision Report — sample-task\n\n## Summary\n...\n\nVerdict: WATCH\n" }
```

## 8. Anti-pattern detection logic

| AP | Rule | Implementation sketch | Severity ladder |
|---|---|---|---|
| **AP-1 rollback-rate (same-stage)** | Count regex matches in `PM_LOG.md` of pattern `^### Rollback consumed by .* \(round \d+\)$` or `^### Rollback consumed by .*$`, grouped by the preceding `### Stage <N>` header | Parse PM_LOG.md by line; track current stage from `### Stage <N>` headers; increment a per-stage rollback counter on each rollback line. Output per-stage counts | 0–1 → no finding · 2 → WARN · ≥3 → ALERT (matches `pm-orchestrator.md:16` "3 consecutive at same stage = hard stop") |
| **AP-1b rollback-rate (cross-stage tally)** | After the per-stage scan, sum all rollback events across the task regardless of stage. Orthogonal to AP-1: a task with 2 rollbacks in different stages emits AP-1b INFO but no AP-1 finding; a task with 2 same-stage rollbacks emits both AP-1 WARN and AP-1b INFO | Sum the values in the `$counts` map produced by the AP-1 loop; compare against the cross-stage ladder | 0–1 → no finding · **2 → INFO** (normal pipeline friction; e.g. T-002 with rollback at Stage 5 + Stage 6) · **3 → WARN** (project rot signal) · **≥4 → ALERT** (severe; warrants pausing pipeline) |
| **AP-2 stage-doc-thinness** | Per-stage required-section list (declared in `supervisor.md` table); for each stage doc present, check each required `## ` heading appears AND the file line count is ≥ stage-specific minimum (RA: 30, Arch: 40, GR: 20, Dev: 30, CR: 20, QA: 30, Delivery: 15) | For each `docs/features/<slug>/0N_*.md`: `Get-Content | Measure-Object -Line`; `Select-String "^## <required heading>"` for each required heading | Missing heading → WARN · line count below minimum → WARN · both → ALERT |
| **AP-3 missing-intervention-checks** | `PM_LOG.md` MUST contain a line matching `^### Intervention check between stages \d+→\d+$` (or `at task start`) between every pair of completed STAGE-TO-STAGE transitions. Per rule 65 read-points (`.harness/rules/65-intervention.md:16-22`) | Iterate stage-completion events in PM_LOG; assert an intervention-check line precedes each next-stage dispatch (**audit operates on stage-to-stage transitions only, e.g. `Stage 4 → Stage 5`; round-to-round events within a single stage, e.g. `Stage 5 round 1 → Stage 5 round 2`, are explicitly NOT audited and never count as a missing intervention check**) | 0 missing → no finding · 1-2 missing → WARN · ≥3 missing → ALERT · `PM_LOG.md` absent/malformed → INFO only (NFR-6, prevents T-000-like false positives) |
| **AP-4 missing-archive-call** | If `docs/tasks.md` row marks `<slug>` as Completed AND stage docs still live at `docs/features/<slug>/` (NOT `_archived/<slug>/`) | `Test-Path "docs/features/<slug>/01_*.md"` AND tasks.md row regex match → ALERT (rule 70 §Rule 4) | ALERT (single severity — this is the clearly-defined-by-rule case) |

Pseudo-code for the rollback counter (PowerShell shape — bash mirror analogous):

```
$stage = $null; $counts = @{}
Get-Content $pmLog | ForEach-Object {
    if ($_ -match '^### Stage (\d+)') { $stage = $Matches[1] }
    elseif ($_ -match '^### Rollback') { if ($stage) { $counts[$stage] = ($counts[$stage] | ForEach-Object {$_}) + 1 } }
}
# AP-1 (same-stage):   emit finding per stage where $counts[$stage] -ge 2
# AP-1b (cross-stage): $total = ($counts.Values | Measure-Object -Sum).Sum; emit by ladder above
```

## 9. Error handling / fallback

| Failure mode | Detection | Deterministic behavior |
|---|---|---|
| Task folder absent at both active + archived paths | `-not (Test-Path)` both | Print `BLOCKED — task folder not found: <slug>` to stdout; write no report; exit 0 (no script failure, user input issue) |
| `PM_LOG.md` malformed / unreadable | `Get-Content` throws OR no `### Stage` headers found | AP-1 + AP-3 emit `INFO — PM_LOG.md absent or unparseable` only; AP-2 + AP-4 still run | per NFR-6 |
| Report itself exceeds 200 lines | `(Get-Content $report).Count -gt 200` post-Write | Include a `(report truncated: 200-line cap hit)` warning in the `## Methodology notes` section; do NOT fail | matches I.2 cap philosophy (WARN-only) |
| `HARNESS_SUPERVISOR_MOCK` set but unreadable | `-not (Test-Path)` or `Get-Content` throws | Treat as if the env var is unset; fall back to live anti-pattern detection; log `[MOCK-FALLBACK] unreadable: <path>` to stdout | per T-002 A2 precedent |
| Cross-task mode finds 0 archived tasks | Glob returns empty | Write a one-line report `Verdict: HEALTHY` + INFO finding "no archived tasks"; exit 0 |
| Doc-size cap violation in the report itself | post-Write line count | The 200-line cap is enforced by the agent prompt (truncation rule in `supervisor.md`); if violated, `I.7` does NOT fire (it only cares about the verdict line); `test-supervisor` asserts the cap on the AC-6 snapshot |

## 10. verify_all impact

**Today**: 29 checks at v0.16.0 (`AI-GUIDE.md:35,67`, `docs/dev-map.md:72`).

**Added**:

| Check | What it asserts | Severity | Lives at |
|---|---|---|---|
| **I.7** "Ignored INTERVENE supervision reports" | For each file matching `docs/features/*/SUPERVISION_REPORT.md` (not `_archived/`): read last 5 lines (`Get-Content -Tail 5` / `tail -n 5`); if `Verdict: INTERVENE` appears AND the parent slug appears as an active row in `docs/tasks.md` AND file mtime > 48h ago → WARN with finding | **WARN** | Insert after current `I.6` (`verify_all.ps1:415-470`); symmetric bash block after current I.6 in `.sh` |

Lookup detail: PS uses `Get-ChildItem "docs/features/*/SUPERVISION_REPORT.md"` (Glob excludes `_archived/` because `_archived/` is one level deeper); bash uses `find docs/features -maxdepth 2 -name SUPERVISION_REPORT.md`. Active-row regex against `docs/tasks.md`: a row containing `<slug>` whose status column is not `Completed` or `Archived`.

**Target after v0.17.0**: **30 checks** (29 + I.7). Updates to `AI-GUIDE.md:35,67` and `docs/dev-map.md:72` and `docs/manual-e2e-test.md` must move together with this PR (insight L21 fan-out).

## 11. test surface impact

**Decision: new `scripts/test-supervisor.{ps1,sh}` pair** — NOT folded into `test-init`.

Rationale:
- `test-init` exercises greenfield init+sync on empty dirs; supervisor logic depends on populated task folders, which is a different fixture shape.
- Mixing would inflate `test-init`'s assertion count (currently 227 PS / 191 Bash) past a clean review boundary.
- T-002 precedent: when a feature has its own fixture surface, it gets its own runner (test-init covers init's own scope only).

**~30 assertions** (estimate; actual count finalized at delivery and reflected in `docs/manual-e2e-test.md` per insight L14):

| # | Assertion | AC |
|---|---|---|
| 1-2 | `supervisor.md` exists in both `.harness/agents/` and `templates/common/.harness/agents/`; byte-identical (sha256 compare) | AC-1, AC-2 |
| 3-4 | `supervisor.md` ≤300 lines; declares all 4 AP names and the 3 severity words | AC-1 |
| 5-7 | `harness-supervise/SKILL.md` exists; `allowed-tools` is a subset of `{Read, Write, Glob, Grep}` (regex assert NOT containing `Edit`, `Bash`, `PowerShell`, `Task`, `AskUserQuestion`); has three documented arg shapes | AC-3, NFR-4 |
| 8-10 | Running supervisor (in mock mode) on `fixtures/sample-task/` → `SUPERVISION_REPORT.md` exists, last line is `Verdict: WATCH`, AP-1 appears at WARN | AC-4 |
| 11-13 | Running on `fixtures/sample-task-three-rollbacks/` → `Verdict: INTERVENE`, AP-1 at ALERT, file in a **separate** temp dir from #8-10 (insight L22) | AC-5 |
| 14-17 | Snapshot test against T-002 archived (`docs/features/_archived/ai-native-init/`) → deterministic report (sha256 of normalized output equals committed snapshot); **AP-1 absent** (rollbacks were on different stages); **AP-1b INFO present** (2 total cross-stage rollbacks); AP-3/AP-4 absent; **`Verdict: HEALTHY`** (no WARN, no ALERT). This is the F-1-corrected interpretation of AC-6 — see §16 | AC-6, NFR-5 |
| 18-20 | `HARNESS_SUPERVISOR_MOCK=<fixture>` bypasses detection; canned report written verbatim | AC-7 |
| 21-22 | `HARNESS_SUPERVISOR_MOCK=<unreadable>` falls back to live detection (does NOT fail); stdout contains `[MOCK-FALLBACK]` | AC-7 boundary |
| 23-25 | `I.7` PS+Bash: with a stale `INTERVENE` report + active row → WARN; with `Verdict: HEALTHY` → PASS; with `INTERVENE` but archived → PASS | AC-8 |
| 26-27 | Cross-task mode N=0 clamps to 1 with INFO; N>count clamps with INFO | boundary |
| 28-30 | Backwards-compat: running `/harness` on a sandbox task with supervisor present produces stage docs byte-identical to a baseline run without supervisor (AC-10 byte-compare per T-002 round-2 M-2 precedent) | AC-10 |

Bash side gates on Python3 absence the same way `test-init.sh:198-249` does; PS path is unconditional.

## 12. Backwards-compat proof

AC-10 binds: with the supervisor present, running `/harness` produces stage docs byte-identical to v0.16.0.

**Files that change behavior**: zero. The supervisor is only activated by typing `/harness-supervise`. PM Orchestrator's contract (`.harness/agents/pm-orchestrator.md`) is **unchanged**; it has no awareness of `supervisor.md`. The 9 distributed skills (`/harness`, `/harness-plan`, etc.) are **unchanged**.

**Files that change content (additive only)**:
- `.harness/agents/supervisor.md` (new file — additive)
- `templates/common/.harness/agents/supervisor.md` (new file — additive)
- `verify_all.{ps1,sh}` (new check I.7 — additive; existing 29 checks untouched)
- Doc fan-out (README, AI-GUIDE, CHANGELOG, dev-map, manual-e2e-test, walkthrough, architecture) — count bumps + roadmap entry only

A v0.16.0 user upgrading to v0.17.0 who never types `/harness-supervise` sees zero behavior change. Verified by test-supervisor assertions #28-30.

## 13. Partition assignment

`N/A — single developer.` This repo has exactly seven agent files plus the new supervisor, no `dev-*.md` partition agents (Glob `.harness/agents/dev-*.md` → empty). All work goes to the generic `developer.md`.

## 14. Risks (design-level)

| Risk (from §Risks of 01) | Design countermeasure |
|---|---|
| **R-1 false-positive alerts** | NFR-6 zero-ALERT floor on T-000/T-001/T-002; AC-6 committed snapshot of T-002 archived state catches regressions; thresholds in `supervisor.md` are tunable in v0.17.x patch without semver bump |
| **R-2 token cost in cross-task mode** | NFR-2: cross-task reads only `07_DELIVERY.md` + `PM_LOG.md` per task; `--recent N` is the recommended path; `--all` documented but discouraged for N>20 |
| **R-3 stale anti-pattern definitions** | Q-7: thresholds in `supervisor.md` (single-file edit); committed AC-6 snapshot enforces stability; CHANGELOG documents any threshold change as a behavior bump |
| **R-4 supervisor becomes a routing actor** | NFR-4: `allowed-tools: Read, Write, Glob, Grep` — physically cannot dispatch (`Task` excluded), edit upstream (`Edit` excluded), run scripts (`Bash`/`PowerShell` excluded), prompt user (`AskUserQuestion` excluded). Verified by `test-supervisor` assertions #5-7 |
| **R-5 report-ignored anti-pattern** | I.7 makes ignored `INTERVENE` reports visible at every `verify_all` run after 48h |
| **R-6 sync drift** | `sync-self.ps1 -Check` already byte-compares `.harness/agents/` whole-dir (line 39); AC-2 closed by the existing mechanism |
| **Architect-added R-7**: Verdict-line regex brittleness in `I.7` | The schema (§7 A-3) mandates `Verdict: <WORD>` as the last non-blank line; agent prompt enforces; `test-supervisor` assertion #14-17 catches schema drift |
| **Architect-added R-8**: D.1 7-agent enumeration drift | D.1 (`verify_all.ps1:86-91`) is an existence check on 7 named files, not an exhaustive directory enumeration. Adding `supervisor.md` does NOT break D.1. Confirmed by reading the check. |
| **Accepted residual**: `harness-status` "7 agents" copy stays as-is | AC-11 asks the asset-count to go 7 → 8, but the "7-stage pipeline" phrasing in skill copy is not touched (Q-5/back-compat). One copy line edit in `skills/harness-status/SKILL.md` for the asset table only |

## 15. Open issues for Gate Reviewer

1. **Verdict-line regex case-sensitivity**: `I.7` uses a fixed-case regex `^Verdict: (HEALTHY\|WATCH\|INTERVENE)$`. Should we also accept lowercase / mixed-case? Architect recommends: NO — the schema is fixed-case (§7 A-3), agent prompt enforces, no need for tolerance. Flagged for Gate confirmation.
2. **`docs/features/_supervision/` gitignore stance**: Q-6 left this to user preference. Architect recommends: **track by default** (cross-task reports are evidence trails). Flagged for Gate confirmation.
3. **`harness-status` asset-table edit (AC-11)**: confirmed the change is to the asset list only, not the "7-stage pipeline" wording — but the exact `skills/harness-status/SKILL.md` line is `.claude/agents/{pm,req,sol,gate,dev,review,qa}*.md` at line 24; adding supervisor requires either expanding the glob or adding a second row. Architect recommends: add a second row `| Supervisor agent (auxiliary) | .claude/agents/supervisor.md | ? |`. Developer call.

None of the above block design approval.

## 16. Gate Findings Resolution (round 1 → round 2)

- **F-1 (BLOCKER) — AC-6 vs AP-1 same-stage threshold incompatibility**: §8 now declares **AP-1b cross-stage rollback tally** as an orthogonal sub-rule (INFO at 2 total / WARN at 3 total / ALERT at ≥4 total). AP-1 same-stage thresholds are unchanged. T-002 (1 rollback at Stage 5 + 1 at Stage 6) therefore produces **AP-1b INFO** and **no AP-1 finding**, yielding `Verdict: HEALTHY`. The 01 doc's AC-6 phrasing ("AP-1 WARN (2 rollbacks at stages 5 and 6)") cannot be edited by Architect; Developer must read AC-6 as **"AP-1b INFO (2 total rollbacks, different stages) — Verdict: HEALTHY"** and the committed T-002 snapshot fixture (§11 rows 14-17) asserts this corrected expectation. AC interpretation note recorded here is the binding contract for the snapshot.
- **F-2 (clarification) — `harness-status/SKILL.md:24` fix format**: §4 now mandates **adding a new row** `| Supervisor (auxiliary) | .claude/agents/supervisor.md | ? |` rather than widening the existing glob `{pm,req,sol,gate,dev,review,qa}*.md`. Rationale: the glob's purpose is to enumerate the canonical 7; supervisor is auxiliary and must remain visually separated. Developer has no remaining decision at code-write time.
- **F-3 (doc fan-out) — `AI-GUIDE.md:14` count bump**: §4 row for `AI-GUIDE.md` now explicitly bumps line 14 phrasing from `7 agent role contracts` to `7 canonical agents + 1 auxiliary (supervisor)`, alongside the line-35/line-67 check-count bumps already listed. Fan-out is now complete (README, CHANGELOG, AI-GUIDE lines 14/35/67, dev-map, manual-e2e-test, walkthrough, architecture).
- **F-4 (AP-3 ambiguity) — stage-vs-round-N**: §8 AP-3 row now contains an explicit parenthetical: *"audit operates on stage-to-stage transitions only, e.g. `Stage 4 → Stage 5`; round-to-round events within a single stage, e.g. `Stage 5 round 1 → Stage 5 round 2`, are explicitly NOT audited and never count as a missing intervention check."* Developer no longer has to resolve the ambiguity at code-write time; T-002 archived state (which has Stage-5 round-1 + Stage-5 round-2) correctly yields zero AP-3 findings.

No other scope changed. AP-1b is the only logic addition; F-2/F-3/F-4 are clarifications and doc fan-out tightening.

## 17. Verdict

`READY FOR GATE REVIEW (round 2)`
