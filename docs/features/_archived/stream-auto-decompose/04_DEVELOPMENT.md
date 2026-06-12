# Development Record — stream-auto-decompose (T-021)

> Mode: full · Developer: developer · Date: 2026-06-12
> Inputs: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (READY) · `03_GATE_REVIEW.md` (APPROVED FOR DEVELOPMENT, conditions C-1..C-4)

## Summary

`/harness-stream` gains ingest-time triage/auto-decomposition: a new single-sourced `## Ingest triage (one row or many)` section in the stream SKILL, binding pointers from both ingest channels, the amended union-invariant hard rule, a 4-file lockstep update of the ambient hook's emitted instruction block, and the full doc fan-out + version bump to 0.32.0. Text-only change; zero executable logic, zero schema change.

## Files changed

- `skills/harness-stream/SKILL.md` (153 → **175** lines) — six design edits:
  - §3.1 new `## Ingest triage (one row or many)` section inserted between the ambient section and `## Procedure` (now lines 84-103). Design text applied **verbatim modulo line-wrap** (the design's own allowance): one physical line per paragraph/bullet, matching the file's existing style. All contract terms intact: applies-to scope, the general never-re-triage clause (F-4 wording verbatim), both conjunctive criteria, three NOT-complex counter-examples, slug+Notes provenance, union invariant, real-deps-only, Mode per row, fixed point, per-row de-dup, announce, and the simple-requirement 1:1 fallback.
  - §3.2 Procedure 3a (line 115): "normalize it into `pending` row(s) per "Ingest triage" above — one row, or N decomposed rows when the triage test fires (assign `ID`/`Slug`/`Goal`/`Mode`/`Depends on` per row)"; rest of sentence unchanged.
  - §3.3 `ADD` bullet (line 116): appended `(user-authored: honored verbatim as ONE row, never triaged)`.
  - §3.4 ambient step 1 (line 76): design text verbatim — "per "Ingest triage" below — one `pending` row, or N decomposed rows when the triage test fires (`Mode` per row, default `full`)"; `Mode=full` wording retired.
  - §3.5 hard rule (line 162): design text verbatim, joined to one physical line (file style). Contains "union of the derived Goals must equal the original requirement — no invented scope, no dropped scope", "Work the user did not ask for is never added", "rows the user authored (`ADD` lines, hand-written pool rows) are never split or rewritten".
  - §3.6 description (line 3) trigger sentence inserted; Anti-patterns (line 171) new fan-out/ADD bullet; Cost (line 175) N × 7-stage sentence appended.
- `.harness/scripts/ambient-prompt.ps1` (lines 52-57) — emitted step 1 replaced with the design §4 block verbatim (4 → 6 lines).
- `.harness/scripts/ambient-prompt.sh` (lines 49-54) — same.
- `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.ps1` — same (byte-identical to dogfood ps1).
- `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.sh` — same (byte-identical to dogfood sh).
- `README.md` — badge `version-0.32.0-blue` (line 5); stream bullet sentence before "**Ambient mode:**" (line 21); new 0.32.0 roadmap row after the 0.31.0 row (line 275).
- `README.zh-CN.md` — badge (line 5); zh mirror of the bullet sentence (line 21); zh 0.32.0 roadmap row (line 277).
- `CHANGELOG.md` — new `## [0.32.0] - 2026-06-12` section (lines 8-19) with the design-specified heading, SKILL/hard-rule/hook/docs bullets, and the closing version-bump line.
- `.claude-plugin/plugin.json:4` — `"version": "0.32.0"`.
- `.claude-plugin/marketplace.json:17` — `"version": "0.32.0"`.
- `docs/batches/README.md:33` — triage sentence inserted after "New work enters a running stream…".

NOT touched (per design CHECK-ONLY + dispatch): `.harness/rules/25-decision-policy.md`, `AI-GUIDE.md`, `skills/harness-intervene/SKILL.md`, `.harness/rules/65-intervention.md`, `skills/harness-batch/SKILL.md`, `docs/harness-stream.html`, any test driver, `verify_all.{ps1,sh}`, any `*.html`. (`docs/tasks.md` shows modified in `git status` — that is the PM's ledger edit, present before this dispatch.)

## Binding conditions

- **C-1 (single-sourced criteria)** — criteria exist exactly once (SKILL `## Ingest triage`). Both consumers carry binding pointers: Procedure 3a "per "Ingest triage" above", ambient step 1 "per "Ingest triage" below". No "see also" phrasing; no duplication.
- **C-2 (verbatim trio + general never-re-triage)** — hard rule carries the union invariant, "Work the user did not ask for is never added", and "never split or rewritten" verbatim; §3.1 first paragraph keeps the F-4 general clause verbatim: "…and an existing row is never re-triaged" (subject: any existing row; triage's only input is the message being normalized).
- **C-3 (≤ 198 lines)** — final count **175 lines** (`wc -l`). No wording trimmed at all: the budget was met by re-wrapping the drafted block to the file's one-line-per-paragraph style, which the design explicitly sanctions ("Developer applies verbatim modulo line-wrap"). Every contract term ships verbatim; QA's §12.7 assert holds without re-baseline.
- **C-4 (4-file lockstep)** — all four carriers edited identically; +2 emitted lines (15 → 17); no `{{` token in any of the four (grep count 0); native EOL preserved (all four were LF before and after — `file` shows no CRLF, `cmp` pairs pass); dogfood↔template byte-identical per extension; ps1↔sh emitted block CR-stripped identical.

## verify_all result

- Baseline (bash, pre-change): **PASS 32 / WARN 0 / FAIL 0**
- After changes (bash): **PASS 32 / WARN 0 / FAIL 0**
- After changes (pwsh): **PASS 32 / WARN 0 / FAIL 0**
- Delta: 0 new failures; G.3 (badges), G.4 (`[0.32.0]` heading ↔ plugin.json), I.6 all green on real runs.

## Other verification captured (real runs, this sandbox)

- `bash .harness/scripts/test-init.sh` → **PASS 270 / FAIL 0**; `pwsh .harness/scripts/test-init.ps1` → **PASS 308 / FAIL 0** (no driver edits; placeholder scan green).
- Hook parity: `cmp` dogfood↔template → byte-identical (both extensions); `diff` of CR-stripped emitted blocks ps1↔sh → identical; block is 17 lines (was 15, +2 per NFR-1).
- Live hook execution in an **isolated temp root** (`.git` marker + flag + script copies, per Gate F-1 — flag never created in this repo): `echo '{}' |` sh hook → exit 0, emits the new 17-line block; dogfood vs template runtime output identical. (pwsh hook execution left to QA's probe; ps1 text identity proven statically.)
- Stale-claim greps (AC-7): `normalize it into a \`pending\` row` → 0 live hits; `Mode=full` in the 4 hooks + SKILL → 0 hits.

## Design drift (if any)

No semantic drift. Two presentation-level notes for the reviewer (not flagged `DESIGN DRIFT` — both are inside the design's stated latitude):
1. §3.1/§3.5 line-wrap differs from the design's drafted 40-line block — text verbatim, re-wrapped to the file's long-line style (design: "verbatim modulo line-wrap"). This is also what resolves Gate F-2 without trimming.
2. §3.3 parenthetical placed before the bullet's final period ("…delete the intervention file, continue (user-authored: …).") rather than dangling after it; CHANGELOG bullets expand the design's topic list in house style (CHANGELOG wording unconstrained per design §5).

## Open issues for review

None.

## Dev-map updates

None — no files/modules added, moved, or removed (`docs/dev-map.md:57,96` already cover both touched surfaces).

## Verdict

READY FOR REVIEW
