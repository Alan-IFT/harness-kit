# 05 — Code Review · T-11b entropy-watch-harness

> Stage 5 (Code Reviewer). Mode: full. deferred-human: defer. Read-only; persisted by PM.
> Two-axis lens (Standards / Spec). Scope: T-11b's 9 attributable files (T-11a + stream bookkeeping co-mingled in tree → excluded). Upstream 01/02/03(F-1/F-2)/04.

## Findings
- CRITICAL / MAJOR / MINOR: none.
- NIT [STYLE]: pm-orchestrator:198 guard sentence is dense (correct, load-bearing); CHANGELOG [0.42.0] adds a 5th bullet documenting the F-1 edit (accurate, in-scope). Neither blocks.

## Requirement coverage (AC-1…AC-7) — all ✅
AC-1 below-threshold → no scan/section, delivery unchanged (pm-orchestrator:213-214). AC-2 ≥N → one scan + `## Entropy watch` + swept (:216-229). AC-3 plain check, NO --first-of-session (:210-211; grep confirms only negation). AC-4 non-blocking/fail-open, verdict never changes (:202-204, :226-227). AC-5 DRY — call-seq in pm-orchestrator ONLY; harness SKILL 0 `entropy-cadence` occurrences (pointer :40); scan via references/entropy-scan.md not restated. AC-6 0.42.0 ×4 + counts 17/8/32 unchanged + no new check. AC-7 unified shared counter/state (dev-map "called by stream AND /harness").

## Gate conditions (F-1/F-2) — ✅
F-1: supervisor names /harness delivery as 3rd entropy dispatcher in all 3 "invoked only via…" spots (L23/L134/L137-138); 280 ≤300. F-2: dev-map "(and later /harness)" dropped (L174 "AND /harness"; no "later" remains).

## Design fidelity (02 §6a/§6b/§6c) — PASS, zero drift
Subsection inserted between archive-task para and "When to stop"; guard first sentence; 3-step seq; before-archive ordering; SKILL one pointer; CHANGELOG [0.42.0] above [0.41.0] (counts descriptive-unchanged); 0.42.0 ×4 (no stale 0.41.0); README line-5 version-token only (32/314/90 intact); no count flip; no new script/skill/state/check; pm-orchestrator 250 ≤300; scan single-sourced.

## 6 dimensions
Logic: branch logic sound, boundaries match RA §4 (fail-open no-op / DUE scan-once+swept / missing-artifact omit-but-swept / goal-guard skip); no off-by-one (N in script). Requirement/Design fidelity: full. Performance: n/a (3 cheap CLI calls at a terminal boundary, scan gated behind DUE). Security: n/a (supervisor stays observer Read/Write/Glob/Grep; entropy widens READ only). Maintainability: DRY headline (one home + pointer + single-sourced scan/cadence; inline "(referencing line only)" resists drift; F-1/F-2 swept stale enumerations).

## Cross-cutting
I.6 clean (ordinary md, exempt stage docs); entropy-cadence pair NOT touched → cross-shell n/a.

## Per-axis status
- **Standards: PASS** (caps 250/280≤300; 17/8/32 unchanged; 0.42.0 ×4 + CHANGELOG; DRY; I.6 clean; cadence untouched; no new script/skill/state/check).
- **Spec: PASS** (7 ACs + F-1/F-2 + §6a/b/c verbatim, zero drift).

## Verdict
**APPROVED** — 0 CRIT/MAJOR/MINOR, 2 NIT (preference). Both axes PASS. Pure non-blocking fail-open wiring of the cadenced entropy watch into /harness stage-7, one home + one pointer, scan/cadence reused, goal guarded out (first sentence), F-1/F-2 folded in, 0.42.0 ×4 + CHANGELOG, no count flip, no new gate. PS verify_all.ps1 operator-pending. Proceed to QA.
