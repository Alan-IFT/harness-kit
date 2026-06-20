# Delivery Summary — harness-grill (T-03)

- **Task:** T-03 / `harness-grill` — add a `/harness-grill` main-loop interview skill (one question at a time, recommended answer per question, explore-codebase-to-self-answer, reads CONTEXT.md, emits an aligned brief to a feature `INPUT.md`) + a standing "recommend an answer per Open Question" rule on the requirement-analyst.
- **Mode:** full (7 stages) · **Depends on:** T-02 (DELIVERED).
- **Stages traversed:** 1 RA → 2 SA → 3 Gate → 4 Dev → 5 CR → 6 QA → 7 Delivery (all this run)
- **Rollbacks:** 0
- **Final verify_all result:** **PASS 32/0/0 (Bash, ×3 stable)**, count unchanged at 32. verify_all.ps1 = operator-pending (PowerShell denied to both main agent and sub-agents); arrays+labels were edited symmetrically to the Bash twin → green-by-symmetry.
- **Baseline changes:** none — grill is a plugin skill (top-level `skills/`), not a template asset. test-init.sh 273/0, test-real-project.sh 90/0 unchanged.
- **Version:** 0.34.0 → **0.35.0** (minor; new 16th skill). Skill count 15 → 16.

## Files changed (17: 2 new + 15 edited)
- **New:** `skills/harness-grill/SKILL.md` (the interview skill); `docs/features/harness-grill/04_DEVELOPMENT.md`.
- **Edited:** `agents/requirement-analyst.md` (standing recommended-answer rule + Hard-rule-1 strip-list reconcile), `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md` (`[0.35.0]`), `AI-GUIDE.md` (Workflow row + skill index, 110 lines), `docs/getting-started.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `docs/dev-map.md`, `.harness/scripts/verify_all.sh` + `.ps1` (C.1/G.1/G.2 arrays + 15→16 labels, both shells), `install.sh` + `install.ps1` (soft help-text).

## Quality trail
- Gate (03): APPROVED FOR DEVELOPMENT — fan-out ledger independently grep-verified COMPLETE + line-exact; SA's load-bearing corrections (hardcoded name arrays, not directory-derived; installers directory-derived) verified true; 3 WARN dev-conditions C1-C4.
- Code Review (05): APPROVED — 0 BLOCKER/MAJOR/MINOR, 1 NIT; 15→16 fan-out complete in both directions; decoys frozen; both shells symmetric; strip-list coherent.
- QA (06): PASS — 0 defects; mutation A (remove README grill bullet → G.1 FAIL) + mutation B (remove CHANGELOG harness-grill → G.2 FAIL) proved the gates load-bearing for grill specifically; both restored to 32/0/0; decoys confirmed frozen.

## Outstanding risks / Next steps for user (operator-pending — capability-gated, NOT defects)
PowerShell is denied in this runtime. Before the next release tag, on a Windows shell:
1. `.harness/scripts/verify_all.ps1` → confirm 32/32 (the .ps1 C.1/G.1/G.2 arrays+labels were edited symmetrically to the green Bash twin).
2. `.harness/scripts/test-init.ps1` → confirm green (expected 308; capture, don't assume).
3. `.harness/scripts/test-real-project.ps1` → confirm 90.

This is the standing PS-deny follow-up bundle (same pattern as T-02 / T-016 / T-018), not a regression.

## Insight

- 2026-06-19 · A skill-count fan-out (`N → N+1`) has a DO-NOT-TOUCH **decoy set that grows with project history** and must be enumerated explicitly by the Architect, then mutation-tested BOTH directions by QA (a missed live flip AND a wrongly-flipped frozen claim are equal-severity bugs). Beyond the known live surfaces, the frozen decoys are: historical `## [x.y.z]` CHANGELOG entries, `docs/tasks.md` append-only delivery rows, archived proposal HTML under `docs/proposals/`, `.harness/insight-index.md` lines describing past states, and the `harness-status` "14 required assets" HEALTH denominator (not a skill count). Also: verify_all C.1/G.1/G.2 are HARDCODED name arrays in BOTH shells (NOT directory-derived) — a 15→16 change needs the array element added AND the label flipped in each, or the gate silently under-enforces. Generalizes the T-008/T-018 count-ledger discipline. · evidence: T-03, verify_all.{sh,ps1} C.1/G.1/G.2 + QA mutations A/B
