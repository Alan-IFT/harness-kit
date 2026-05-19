# PM_LOG — supervisor-agent (T-003)

Task: Implement the v0.16+ roadmap item "supervisor agent observing pipeline progress" — a new agent role + skill that observes a running 7-stage pipeline and flags anti-patterns (rollback loops, stalled stages, low-quality stage outputs).

Mode: full (7 stages)
Started: 2026-05-19 (immediately after T-002 / v0.16.0 ship)
Invoker: user (via `/harness-kit:harness` with directive "按 roadmap 实现剩下的功能, you decide, all commits by you")
Target version: v0.17.0 (next semver after T-002's v0.16.0)

## Intervention check at task start
No `.harness/intervention.md` present.

## Insight-index entries possibly relevant
- 2026-05-19 · PowerShell `-notin` is case-INSENSITIVE; use `-cnotin`. (likely irrelevant for an observer agent unless it does string-matching on stage doc contents)
- 2026-05-19 · CHANGELOG.md must be in the explicit fan-out of any version/count sweep. (relevant: v0.17.0 release will need the same discipline)
- 2026-05-19 · Bidirectional opt-in/opt-out test cases must use separate temp dirs. (relevant if the supervisor's test surface includes opt-in/opt-out semantics)
- 2026-05-16 · Releases shipped feature code but left README badges / getting-started skill list at pre-release values. (relevant for v0.17.0 doc resync)
- 2026-05-16 · One-sided assertions hide bidirectional drift. (relevant: any new check we add must have an inverse)

## Design context (carried from T-002 finish)

The 7-stage pipeline has a known anti-pattern surface:
- Same stage rolled back N times (PM hard-stops at 3, but lower thresholds may warrant warnings)
- Stage docs that pass their stage's verdict but are below quality threshold (e.g. RA writes 5 lines and calls it READY)
- PM_LOG.md missing intervention checks between stages
- Pipeline that ran but skipped archive-task at the end
- Insight section in 07_DELIVERY that is filler ("we learned to test more")

The supervisor agent's value proposition: catch these BEFORE they accumulate into project-wide rot.

## Stage log

### Stage 1 — Requirement Analyst (2026-05-19)
- Output: `01_REQUIREMENT_ANALYSIS.md` · 10 FRs, 11 ACs, 6 NFRs, 6 risks, 7 open questions all analyst-decided.
- Verdict: READY.
- Key analyst decisions: skill name `harness-supervise`; manual-invocation only (no PM auto-dispatch in v0.17.0); 3-level severity INFO/WARN/ALERT; on-demand agent (not always-loaded); 1 new verify_all check (passive guard for ignored INTERVENE reports); cross-task reports at `docs/features/_supervision/`; 4 anti-patterns (AP-1 rollback-rate, AP-2 stage-doc-thinness, AP-3 missing-intervention-checks, AP-4 missing-archive-call).
- Q-2 (invocation mode) flagged for architect override consideration; analyst chose manual-only for additive backwards compat.

### Intervention check between stages 1→2
No intervention file.

### Stage 2 — Solution Architect (2026-05-19)
- Output: `02_SOLUTION_DESIGN.md` · 283 lines (under 300 cap).
- 9 new files / ~11 modified files. Honored all 7 analyst Q's; added 3 architect decisions.
- Biggest architect call: A-3 — fixed `SUPERVISION_REPORT.md` schema with `Verdict: <WORD>` as mandatory last non-blank line. Enables I.7 to be a 5-line regex check, not a parser.
- Risk-acceptance: R-1 (false-positive alerts) — accepted residual; thresholds tunable in v0.17.x patches.
- verify_all 29 → 30 (new I.7). Adds `scripts/test-supervisor.{ps1,sh}` as a NEW test driver (not a test-init extension).
- Verdict: READY FOR GATE REVIEW.

### Intervention check between stages 2→3
No intervention file.

### Stage 3 — Gate Reviewer (round 1, 2026-05-19)
- Output: `03_GATE_REVIEW.md` (persisted by PM from reviewer's inline findings).
- 8-dim: 5 PASS / 3 WARN / 0 FAIL.
- Citation accuracy: 20/20 substantively correct.
- Verdict: **CHANGES REQUIRED**.
- **F-1 (blocker)**: AC-6 vs AP-1 arithmetic mismatch on T-002 snapshot — T-002 had 1 rollback at Stage 5 + 1 at Stage 6 (different stages), so AP-1's same-stage rule produces 0 findings, not WARN.
- F-2/F-3/F-4: doc fan-out + AP-3 clarification (non-blocking but should land in the rollback).
- **PM decision**: rollback to Stage 2 (Architect) with narrow scope to (a) add AP-1b cross-stage rollback tally + rewrite AC-6 to use it, (b) clarify AP-3 contract on round-to-round events, (c) add `AI-GUIDE.md:14` to §4 fan-out and pick the `harness-status/SKILL.md:24` fix format.

### Rollback consumed by Architect (round 2)
- 7 edits across 6 locations in 02_SOLUTION_DESIGN.md (now 295 lines, under cap).
- F-1 fix: AP-1b cross-stage tally added (2=INFO / 3=WARN / ≥4=ALERT); §11 AC-6 + §16 confirm T-002 trace yields HEALTHY.
- F-2 fix: §4 explicit "add new row, do NOT widen glob" format.
- F-3 fix: §4 AI-GUIDE.md line 14 phrasing bump named explicitly.
- F-4 fix: §8 AP-3 explicit stage-to-stage-only parenthetical.

### Stage 3 — Gate Reviewer (round 2, 2026-05-19)
- Output: 03_GATE_REVIEW.md round-2 section appended.
- Verdict: **APPROVED FOR DEVELOPMENT**.
- All 4 round-1 findings fixed; no scope creep; no regressions.

### Intervention check between stages 3→4
No intervention file.

### Stage 4 — Developer (2026-05-19)
- Output: `04_DEVELOPMENT.md`.
- 22 files (8 new + 14 modified). All 4 Gate findings (F-1..F-4) honored at named file:line.
- PM-verified: verify_all 30/30 PASS (PS + Bash); test-supervisor 52/52 PS; test-init still 227/227 (no regression).
- In-scope minor superset: fixed latent bash bug in `verify_all.sh` where I.7 `while IFS= read -r report` loop variable clobbered the global `step()` audit-log array; symptom was summary counter off by 1. Fix: rename loop variable to `report_file`; switch `declare -a report` → `report=()` per existing insight on bash `set -u` semantics. Defensible inclusion (the design's PASS-30 summary was only achievable with the fix).
- Insight to surface at delivery: bash `while read` loop variable name collision with globally-mutated array silently clobbers via scalar→array coercion.
- Verdict: READY FOR REVIEW.

### Intervention check between stages 4→5
No intervention file.

### Stage 5 — Code Reviewer (2026-05-19)
- Output: 05_CODE_REVIEW.md.
- 6-dim: 6 PASS / 0 WARN / 0 FAIL.
- **Verdict: APPROVED** — 0 BLOCKER, 0 MAJOR, 4 MINOR, 3 NIT.
- MINOR findings (slug-substring collision risk, emulator brittleness on out-of-order stages, dev report off-by-one, missing 2-rollback fixture) are v0.17.x patch material, not v0.17.0 blockers.
- All 4 Gate findings F-1..F-4 verified at named locations. NFR-4 safety boundary verified at both agent + skill frontmatter.
- PM action: advance to Stage 6 (QA Tester).

### Intervention check between stages 5→6
No intervention file.

### Stage 6 — QA Tester (round 1, 2026-05-19)
- Output: 06_TEST_REPORT.md.
- verify_all 30/30 PASS; test-supervisor 52/52 PS; test-init 227/227 (no regression).
- **3 bugs found**:
  - BUG-1 (MAJOR): `verify_all.ps1:435` uses `-match` (case-insensitive); lowercase `verdict: intervene` falsely triggers I.7 WARN. Directly violates Q-1 fixed-case binding decision + insight L11 (`-cmatch`/`-cnotin`).
  - BUG-2 (MINOR): I.7 slug substring match — `foo` matches `foo-extra`. Code Review noted this too.
  - BUG-3 (NIT): doc-drift between supervisor.md:230 and SKILL.md:129 on N=0 clamp behavior.
- QA verdict: APPROVED FOR DELIVERY with 3 patches for v0.17.x.
- **PM decision**: same call as T-002 BUG-2 — fix BUG-1 in v0.17.0 because it violates a binding Architect decision and is the same class of insight; defer BUG-2 + BUG-3 to v0.17.1.

### Rollback consumed by Developer (QA round 2)
- 8-file narrow scope. `verify_all.ps1:439` `-match` → `-cmatch` + comment citing insight discipline. Helper `Get-VerdictFromReport` in test-supervisor.ps1 also `-cmatch` for emulator/production symmetry. +2 negative-fixture assertions (lowercase + mixed-case → don't trigger).
- Counts: test-supervisor 52→54 PS / 49→50 Bash. verify_all stable at 30/30.
- BUG-2 + BUG-3 documented in CHANGELOG "Known limitations" with rationale (slug-substring collision risk + N=0 doc-drift).

### Stage 6 — QA Tester (round 2 — BUG-1 verification, 2026-05-19)
- PM-verified directly: verify_all 30/30 PASS; test-supervisor 54/54 PASS including the 2 new BUG-1 negative-fixture assertions.
- BUG-1: **CLOSED in v0.17.0**.
- BUG-2 + BUG-3: **deferred to v0.17.1** with explicit CHANGELOG notes + rationale.
- Verdict: **APPROVED FOR DELIVERY**.

### Intervention check between stages 6→7
No intervention file.

