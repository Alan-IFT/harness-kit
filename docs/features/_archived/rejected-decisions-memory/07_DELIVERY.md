# Delivery Summary — rejected-decisions-memory (T-09)

- **Task:** T-09 / `rejected-decisions-memory` — generalize the ad-hoc "Deliberately not adopted" pattern into a lightweight rejected-decisions memory that prevents re-litigating declined requests/approaches.
- **Mode:** full (7 stages) · **Depends on:** — (independent) · Tier-3 wave (⑨).
- **Stages traversed:** 1 RA → 2 SA → 3 Gate → 4 Dev → 5 CR → 6 QA → 7 Delivery (all this run)
- **Rollbacks:** 0
- **Final verify_all result:** **PASS 32/0/0 (Bash, ×3 stable)**, I.6 with both new files in scan scope, G.3 @0.40.0, G.4 [0.40.0], check count unchanged at 32. test-init.sh 273→276 (+3). verify_all.ps1 / test-init.ps1 operator-pending (PS denied; expect 32/0/0 + 311).
- **Version:** 0.39.0 → **0.40.0** (minor; new always-present template asset). NO count flip (16 skills / 8 framework agents / 32 checks held).
- **Baseline changes:** `test_init_bash_no_python3_assertions` 273 → 276 (captured). `test_init_ps_assertions` (308) + both README `test--init` badges left for PM's captured PS run.

## Files changed (2 new + 14 edited)
- **New:** `.harness/rejected-decisions.md` (dogfood — tight header + 9 seed records: 1 deferred [design-it-twice] + 8 declined [ask-matt-router, issue-tracker-dedup, to-prd, triage, skill-usage-telemetry, + 3 grouped non-fit skill families]); `skills/harness-init/templates/common/.harness/rejected-decisions.md` (generic placeholder-free seed).
- **Edited:** `.harness/rules/25-decision-policy.md` (canonical read/append bullet — single source), `agents/requirement-analyst.md` + `agents/solution-architect.md` (SOFT pointer lines), `.harness/rules/15-skill-authoring.md` (telemetry rationale → pure pointer), `AI-GUIDE.md` (4th memory-layer line), `docs/dev-map.md` (row + tree line), `.harness/scripts/test-init.{ps1,sh}` (symmetric seed assertion), `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` + `README.md` + `README.zh-CN.md` (version 0.40.0), `CHANGELOG.md` ([0.40.0]), `.harness/scripts/baseline.json` (bash test_init field).

## Quality trail
- RA (01): recommended a dedicated FILE over a convention (the convention already existed in 15-skill-authoring and had failed — invisible at non-skill-authoring decide-points).
- Gate (03): APPROVED — 8/8 + 6 checks; F-1 caught the RA doc's stale "15 skills" (design carries correct 16, no count flip → safe); conditions C1-C3.
- Code Review (05): APPROVED WITH NOTES — both axes (Standards/Spec) clean, 0 CRIT/MAJOR/MINOR, 2 NIT (design-licensed).
- QA (06): APPROVED FOR DELIVERY — 0 defects; mutation proved the seed assertion non-vacuous (276→273/3→276); I.6 clean on both new files; no count flip; dogfood ≠ seed.

## Outstanding risks / Next steps for user
- Operator-pending (PS deny): `verify_all.ps1` (32/0/0) + `test-init.ps1` (~311) → reconcile `test_init_ps_assertions` + both README `test--init-308%2F308` badges from the captured PS total.

## Insight

- 2026-06-20 · Institutional "we decided NOT to do X" memory captured only as a CONVENTION inside one rule file (this repo's prior "Deliberately not adopted" section in `15-skill-authoring.md`) silently FAILS its one job: it is invisible at every decide-point except the one where it happens to live, so it never gets read when an unrelated decision is being made. The fix that works is a named memory-layer FILE (a 4th kind alongside truths / autonomy-principles / glossary) with its read+append trigger single-sourced in the rule that ALREADY loads at the decide-point (`25-decision-policy.md`), other agents pointing at it (never restating). Generalizes: a memory only earns its keep if its read-trigger is wired to where the relevant decision happens, not merely documented somewhere. · evidence: T-09, .harness/rejected-decisions.md + 25-decision-policy.md read/append bullet
