# Delivery Summary — entropy-watch / T-11a

- **Task:** T-11a / `entropy-watch` — the thinnest end-to-end slice of the anti-entropy watch: machine **reminds** (auto, cadenced, at the stream pool-drain boundary) → user **authorizes** → machine **executes** the deepening refactor.
- **Mode:** full (7 stages) · **Depends on:** — · First slice of the operator-directed anti-entropy feature (T-11b/T-11c follow).
- **Stages traversed:** 1 RA → 2 SA → 3 Gate (BLOCKED → rework) → 2 SA(r2) → 3 Gate(r2 APPROVED) → 4 Dev → 5 CR → 6 QA → 7 Delivery.
- **Rollbacks:** 1 (design — Gate caught the supervisor I.3-cap breach + the false "F.1 auto-extends" claim; both fixed in SA round 2). First rollback of the whole adoption effort — the gate working as intended.
- **Final verify_all result:** **PASS 32/0/0 (Bash)** — C.1/G.1/G.2 "17 skills", F.1 includes entropy-cadence, G.3 0.41.0, G.4 [0.41.0], I.3 supervisor 279 ≤ 300. test-init.sh 276, test-supervisor.sh 45 (unchanged). verify_all.ps1 / test-init.ps1 / entropy-cadence.ps1 operator-pending (PS denied).
- **Version:** 0.40.0 → **0.41.0** (minor; new 17th skill). Skill count 16 → **17**. Agents 8, checks 32 unchanged (no new gate).

## Files changed (20)
- **New:** `skills/harness-deflate/SKILL.md` (17th skill — delegator: scan→supervisor, execute→/harness-goal; `allowed-tools: Read, Glob, Grep, Task`, no Edit/Bash → cannot refactor without authorization); `skills/harness-deflate/references/entropy-scan.md` (single-source scan grammar/schema); `.harness/scripts/entropy-cadence.{ps1,sh}` (shared cadence pair — `check`/`delivered`/`swept`, N=5 once per shell, fail-open → NOT-DUE exit 0, .git-walk root, raw-byte UTF-8).
- **Edited:** `agents/supervisor.md` (concise entropy lens stub + pointer; Hard-rule #1 scoped read-only entropy exception; 279 lines), `skills/harness-stream/SKILL.md` (pool-drain `## Entropy watch` surface, cadence-gated, non-blocking, after `## Needs your input`), `.gitignore` (+ entropy-watch.state), `verify_all.{ps1,sh}` (C.1/G.1/G.2 16→17 arrays+labels + F.1 entropy-cadence), README.md/README.zh-CN.md/CHANGELOG/AI-GUIDE/getting-started/manual-e2e/40-locations/dev-map (16→17 fan-out), plugin.json/marketplace.json (0.41.0).

## How it works (the operator's logic, realized)
machine reminds → user authorizes → machine executes:
1. **Remind (auto, cadenced):** when a `/harness-stream` pool drains, if a sweep is due (≥5 delivered since last sweep, or first session drain), the read-only supervisor entropy lens scans the whole codebase and a `## Entropy watch` section is appended to STREAM_REPORT.md + the exit message — pointing out WHERE (shallow modules / seam leakage / deepening candidates, each with a strength badge). Non-blocking. No reliance on human memory.
2. **Authorize:** you invoke `/harness-deflate` (or pick from the watch) — it presents findings and waits for your explicit pick; it can never refactor on its own (no Edit/Bash).
3. **Execute:** the chosen deepening is handed to `/harness-goal` to refactor to verify_all green.

## Quality trail
- Gate round 1 BLOCKED (supervisor I.3 cap + F.1-allowlist claim) → SA round 2 fixed (lens detail → references/, F.1 explicit edits, Hard-rule exception) → Gate round 2 APPROVED.
- CR: APPROVED WITH NOTES — both axes (Standards/Spec) CLEAN; 0 CRIT/MAJOR, 1 MINOR (description when-NOT lacks /harness-plan; body table has it — non-blocking), 2 NIT.
- QA: APPROVED FOR DELIVERY — 0 defects; cadence boundary (≥5 inclusive) + fail-open (corrupt/empty/absent → NOT-DUE exit 0, self-heals) + load-bearing mutations (delete entropy-cadence.sh → F.1 FAIL; remove README harness-deflate mention → G.1 FAIL) all confirmed; observer boundary held; decoys frozen.

## Outstanding / Next
- **Follow-up slices (queued):** T-11b (add the `/harness` single-task delivery surface calling the same shared cadence check — completes the operator's "both harness and stream") and T-11c (findings persistence: open findings re-surface, declined ones → rejected-decisions, no re-litigation).
- Operator-pending (PS deny): run verify_all.ps1 (32/0/0) / test-init.ps1 (314) / test-supervisor.ps1 (49) + entropy-cadence.ps1 smoke on Windows.
- The 1 MINOR (add /harness-plan to the harness-deflate description's when-NOT) is a trivial optional polish.

## Insight

- 2026-06-20 · A `verify_all` gate that checks ARTIFACT PRESENCE (F.1 "both .ps1+.sh exist"; G.1/G.2 "README/CHANGELOG mention each skill name") is load-bearing only against a missing ARTIFACT, NOT against a stale entry in the gate's own hardcoded name array — removing a name from the array (with the file/mention still present) silently PASSES. So a mutation test that proves such a gate is real must mutate the ARTIFACT (delete the script / remove the README mention), not the array. Corollary for fan-out tasks: the array edit and the artifact must both be done, but only the artifact side is gate-protected — the array side relies on review. · evidence: T-11a QA mutations A/B, verify_all.{sh,ps1} F.1 + G.1
