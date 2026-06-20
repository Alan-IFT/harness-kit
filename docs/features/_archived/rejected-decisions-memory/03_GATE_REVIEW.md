# 03 — Gate Review · T-09 rejected-decisions-memory

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY · 02 READY. Mirrors the T-02 CONTEXT.md dual-purpose pattern. Verify-don't-trust against live files.

## Audit checklist (8 dimensions) — all PASS. No FAIL.

## Six dispatch checks — all CONFIRMED
1. **Single-source habit:** canonical read/append prose ONCE in 25-decision-policy.md (loads at decide-points); RA step 7 + SA step 5 are pointer-only ("per 25-decision-policy.md"); 15-skill-authoring telemetry entry → pointer. No two-place divergence.
2. **Placeholder-free seed:** plain prose + HTML comment + 1 example stub, zero `{{...}}` (auto-covered by test-init.sh:204 scan); D.2 stays 7; body differs from dogfood (AC-3).
3. **test-init assertion symmetric** (both shells, after the CONTEXT.md present-assertion at sh:140/ps1:172); baseline reconcile = bookkeeping (verify_all reads only verify_all_checks; test_init_* reconciled from captured run, not hand-typed — insight 2026-06-04).
4. **Version 0.39.0→0.40.0** across 4 stamps + CHANGELOG [0.40.0]; no count token touched; no new check.
5. **I.6 self-trip:** 14 banned anchors (verify_all.sh:521-536 = CLAUDE.md gen/compose, scaffolding-only, 全程中文); seed topics (telemetry/issue-tracker/to-prd/triage/skill families) avoid all; both new files non-exempt + in scan scope. AI-GUIDE 111→~116 ≤200.
6. **Memory-layer distinctness:** 4th distinct kind (declined options) vs truths/autonomy/glossary; soft size = header note, NOT a gate; insight-index not overloaded.

## Findings (3 WARN, non-blocking, pre-answered)
- **F-1:** RA doc says "15 skills" 3× but the LIVE count is **16** (Glob skills/*/SKILL.md = 16; AI-GUIDE:7 "16 skills"). The DESIGN carries the correct 16 and makes NO count flip, so the stale "15" never reaches an edit. **Dev condition: make no count edits; do NOT "correct" any 16/32 string toward 15.**
- **F-2:** README `test--init-308/308` badge tracks the PS total (308), `test_init_bash_no_python3_assertions`=273 is a different number. Reconcile both baseline fields + the badge from CAPTURED runs in their respective shells; don't hand-type "311".
- **F-3:** keep the rule-15 telemetry line a PURE pointer (name the decline, point to the file for the why) to avoid future drift; AC-8 (not two *different* reasons) is met today.

## Verdict
**APPROVED FOR DEVELOPMENT.** Conditions: (1) live skill count is 16 — no count edits; (2) reconcile test-init badge + both baseline test_init_* fields from captured runs, not hand-typed; (3) run verify_all both shells → 32/32 with both new files in I.6 scope before done. No route-back.
