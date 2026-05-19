# PM_LOG — ai-native-init (T-002)

Task: Implement the v0.16+ roadmap item "True AI-native init" — let AI analyze the user's existing code / description and produce a custom `50-*.md` rule fragment (and optionally partition agents), instead of using only the static fullstack/backend/generic overlays.

Mode: full (7 stages)
Started: 2026-05-19
Invoker: user (via `/harness-kit:harness` with directive "按 roadmap 实现剩下的功能, you decide, all commits by you")

## Intervention check at task start
No `.harness/intervention.md` present.

## Insight-index entries possibly relevant to this task
- 2026-05-16 · Edit tool occasionally reports SUCCESS without applying the change — re-Read or Grep to verify. (affects template generation in Developer stage)
- 2026-05-16 · Any new `{{...}}` placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails. (likely relevant if we add new placeholders)
- 2026-05-16 · Releases shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values. (relevant for v0.16.0 doc resync)
- 2026-05-16 · One-sided assertions hide bidirectional drift; when asserting set-membership in templates, write the inverse check too. (relevant if we touch test-init)

## Stage log

### Stage 1 — Requirement Analyst (2026-05-19)
- Output: `01_REQUIREMENT_ANALYSIS.md` · 11 FRs, 12 ACs, 8 NFRs, 8 risks
- Verdict: READY
- 6 open questions resolved under analyst authority; biggest one (Q3 inline vs sub-agent) flagged for architect override
- Decisions analyst made for downstream: AI-native is opt-in (default OFF); embedded in both `/harness-init` (Q6) and `/harness-adopt`; produces `50-<project-slug>.md` (replaces static stub); inline source-citation HTML comments; v0.15 byte-identical fallback path required.
- PM action: advance to Stage 2 (Solution Architect).

### Intervention check between stages 1→2
No intervention file.

### Stage 2 — Solution Architect (2026-05-19)
- Output: `02_SOLUTION_DESIGN.md` · ~285 lines · 2 new files, 13 modified
- Architect-final on all 6 analyst-decided open questions (no overrides). Plus 3 architect-introduced decisions: A1 inline prompt (no separate AI call), A2 four-invariant detector, A3 env-var mock fixture (`HARNESS_AI_NATIVE_MOCK`).
- verify_all grows 28 → 29 (new D.3); test-init grows 177 → ~219 assertions.
- Two architect-added risks (R9 AI-GUIDE drift, R10 i18n/zh confirm).
- Verdict: READY FOR GATE REVIEW.

### Intervention check between stages 2→3
No intervention file.

### Stage 3 — Gate Reviewer (2026-05-19)
- Output: `03_GATE_REVIEW.md` (Gate Reviewer is read-only per contract; PM persisted the inline findings into the file)
- Verdict: **APPROVED FOR DEVELOPMENT**
- 8-dim audit: 6 PASS / 2 WARN / 0 FAIL.
- Dev-time conditions to honor (must): A (zh AI-GUIDE.md.tmpl edit is REQUIRED, not optional), D (AI-GUIDE.md:35 also bumps from 28→29), F (re-Read every Write/Edit per insight-line-10 discipline), G (D.3 per-section annotation check, not file-global).
- Cosmetic-only fixes: B, C (citation mis-pointers in design rationale).
- 19/21 citations validated; the 2 misses are non-load-bearing.
- PM action: advance to Stage 4 (Developer) carrying conditions A/D/F/G as a binding subtask list.

### Intervention check between stages 3→4
No intervention file.

### Stage 4 — Developer (2026-05-19)
- Output: `04_DEVELOPMENT.md`
- 19 files changed (2 added, 17 modified). All 4 binding Gate findings honored (A/D/F/G). Both cosmetic Findings B/C annotated in 02 as `<!-- gate-finding-* -->` comments without rewriting design body.
- PM-verified: `scripts/verify_all.ps1` → 29 PASS / 0 WARN / 0 FAIL.
- PM-verified: `scripts/test-init.ps1` → 222 PASS / 0 FAIL.
- Deviation from design: assertion count came in at 222 (PS) / 186 (Bash python3-gated) vs. design estimate ~219. Reason: assertions split for clearer failure messages. Counted and updated in `docs/manual-e2e-test.md`.
- Verdict: READY FOR REVIEW.

### Intervention check between stages 4→5
No intervention file.

### Stage 5 — Code Reviewer (2026-05-19, round 1)
- Output: `05_CODE_REVIEW.md` (persisted by PM from reviewer's inline findings)
- 6-dim audit: 4 PASS / 2 WARN / 0 FAIL.
- **Verdict: CHANGES REQUIRED** — 3 MAJOR blockers:
  - M-1: `CHANGELOG.md:45,47` say "219" instead of "222 PS / 186 Bash" (insight-index L14 violation in the release that claimed to sweep L14).
  - M-2: AC-10 "byte-identical to v0.15.1 with Q6=No" asserted only as `Test-Path`, not byte equality.
  - M-3: opt-out and opt-in assertions share temp dir; no discrete Q6=No end-state test.
- **PM decision: rollback to Stage 4 (Developer)** to fix M-1 (mandatory) and address M-2+M-3 (preferred: separate-dir byte-compare; acceptable: down-scope AC-10 claim with a documented `<!-- code-review-M-2/M-3 -->` annotation).
- Minor findings (R-1..R-4, N-1..N-2) may be deferred or rolled in inline at Dev's discretion.

### Rollback consumed by Developer (round 2)
- 9 files changed in rollback diff. New assertion count: 222 → 225 PS / 186 → 189 Bash-no-python3 (+3 byte-compare × 3 project types). verify_all unchanged at 29/29.
- M-1 fixed at `CHANGELOG.md:43,45,47,55`; canonical fan-out updated across README/AI-GUIDE/manual-e2e-test/dev-map/walkthrough/architecture.
- M-2 fixed: PS `[System.IO.File]::ReadAllBytes` per-byte loop, Bash `cmp -s` — both at `test-init.{ps1,sh}` near line 289/271.
- M-3 fixed: separate `optout_tmp` / `$optOutTmp` dir with isolated lifecycle.

### Stage 5 — Code Reviewer (round 2, 2026-05-19)
- Output: 05_CODE_REVIEW.md updated with round-2 audit section.
- Verdict: **APPROVED**.
- All 3 round-1 majors resolved; no regressions. One NIT (test-internal substitution duplication) noted, acceptable.
- PM action: advance to Stage 6 (QA Tester).

### Intervention check between stages 5→6
No intervention file.

### Stage 6 — QA Tester (round 1, 2026-05-19)
- Output: `06_TEST_REPORT.md` (155 lines).
- verify_all 29/29 PASS (×2, no debris). test-init 225/225 PASS (×3, no flakes).
- AC coverage: 10/12 strong, 2/12 partial-deferred (AC-2 + code-review R-1 = same gap).
- **2 MAJOR adversarial findings**:
  - BUG-1: Reserved-name filter asymmetric across shells (PS `-contains` case-insensitive; Bash Python `not in` case-sensitive). Defense-in-depth only; happy path unaffected.
  - BUG-2: D.2/D.3 placeholder regex `\{\{[A-Z_]+\}\}` does NOT match `{{ PROJECT_NAME }}` (whitespace-padded) or lowercase `{{project_name}}`. Verify_all would let such a leak through.
- QA's verdict: **APPROVED FOR DELIVERY** with v0.16.1 follow-up.
- **PM decision**: accept QA verdict for BUG-1 (defer to v0.16.1 — true asymmetry only matters in adversarial AI output). **Override on BUG-2**: fix in v0.16.0 because it undermines the safety claim we ship. One-line regex tightening in PS + Bash + the mock-fixture matching test in test-init. Single round-2 rollback to Developer with narrow scope.

### Rollback consumed by Developer (QA round 2)
- 12-file narrow-scope diff. D.2 + D.3 placeholder regex broadened to `\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}` (PS + Bash). PS `-notin` → `-cnotin` (case-sensitive) — in-spirit BUG-2 hardening discovered during dev's own adversarial test of the broadened regex.
- Counts: test-init 225 → **227** PS / 189 → **191** Bash-no-python3 (+2 BUG-2 regression assertions, single-shot not ×3-per-type).
- verify_all stable at 29/29.
- BUG-1 deferral documented in CHANGELOG "Known limitations" with rationale.

### Stage 6 — QA Tester (round 2 — BUG-2 verification, 2026-05-19)
- PM-verified directly: `verify_all` 29/29 PASS; `test-init` 227/227 PASS including the 2 new `[BUG-2]` regression assertions catching whitespace-padded and lowercase placeholder leaks.
- BUG-2: **CLOSED in v0.16.0**.
- BUG-1: **deferred to v0.16.1** with explicit CHANGELOG note + rationale.
- Verdict: **APPROVED FOR DELIVERY**.

### Intervention check between stages 6→7
No intervention file.

