# Stream Report — default pool

> Run: 2026-06-19 → 2026-06-20 · Driver: continuous (single-turn, file-channel) · adoption batch from github.com/mattpocock/skills
> Exit: **NORMAL — pool fully drained (two waves).** Wave 1 (T-02..T-07) 6/6 DELIVERED; Wave 2 / Tier-3 (T-08..T-10) 2 DELIVERED + 1 correctly DECLINED. 0 rollbacks, 0 failed, 0 blocked. No hard stop fired.

## Tasks

| ID | Slug | Verdict | Version | Docs |
|---|---|---|---|---|
| T-02 | context-glossary | DELIVERED (0 rollbacks) | v0.34.0 | `docs/features/_archived/context-glossary/` |
| T-03 | harness-grill | DELIVERED (0 rollbacks) | v0.35.0 | `docs/features/_archived/harness-grill/` |
| T-04 | skill-authoring-vocab | DELIVERED (0 rollbacks) | (no bump — dogfood rule) | `docs/features/_archived/skill-authoring-vocab/` |
| T-05 | durable-brief | DELIVERED (0 rollbacks) | v0.36.0 | `docs/features/_archived/durable-brief/` |
| T-06 | vertical-slices | DELIVERED (0 rollbacks) | v0.37.0 | `docs/features/_archived/vertical-slices/` |
| T-07 | sa-design-vocab | DELIVERED (0 rollbacks) | v0.38.0 | `docs/features/_archived/sa-design-vocab/` |
| T-08 | two-axis-review | DELIVERED (0 rollbacks) | v0.39.0 | `docs/features/_archived/two-axis-review/` |
| T-09 | rejected-decisions-memory | DELIVERED (0 rollbacks) | v0.40.0 | `docs/features/_archived/rejected-decisions-memory/` |
| T-10 | planning-decision-map | **DECLINED (no build)** — assess-first; redundant with pool/frontier/grill/explore | (none) | `docs/features/_archived/planning-decision-map/` |
| T-11a | entropy-watch | DELIVERED (1 design rollback) — anti-entropy watch CORE (17th skill /harness-deflate + supervisor entropy lens + cadence pair + stream surface) | v0.41.0 | `docs/features/_archived/entropy-watch/` |
| T-11b | entropy-watch-harness | DELIVERED (0 rollbacks) — /harness single-task delivery surface (both surfaces auto-remind) | v0.42.0 | `docs/features/_archived/entropy-watch-harness/` |
| T-11c | entropy-watch-persist | DELIVERED (0 rollbacks) — decline-filter (declined findings don't re-litigate); standalone store DECLINED as overkill | v0.43.0 | `docs/features/_archived/entropy-watch-persist/` |

## Aggregate
- delivered: **11** · declined (assess-first, correct): **1** · failed: 0 · blocked: 0 · skipped: 0 · (T-01 was a prior run, untouched)
- rollbacks: **1** across all 12 tasks (T-11a design rollback — Gate caught supervisor I.3 breach + a false F.1 claim; SA round 2 fixed; everything else first-pass)
- **operator-directed feature shipped:** anti-entropy watch (T-11a/b/c) — machine reminds (cadenced, both `/harness` + `/harness-stream`) → user authorizes → machine executes; declined findings filtered. New 17th skill `/harness-deflate`. Versions 0.40.0 → 0.41.0 → 0.42.0 → 0.43.0.
- final verify_all: **PASS 32/0/0 (Bash)** after every task + every post-archive re-run; check count held at 32 throughout (no new guard accreted — honors feedback_design_over_guards)
- versions shipped: 0.33.0 → 0.40.0 (T-04 + T-10 added no bump — non-distributed dogfood rule / no-build decline). Skill count 15 → 16 (only the new /harness-grill).
- insights harvested: 3 (T-03 skill-count decoy-set discipline; T-05 forward-brief vs backward-evidence boundary; T-09 institutional-memory needs a read-trigger wired to the decide-point), each rotated to keep insight-index ≤30.
- T-10 is the loop-closer: the first real use of the T-09 rejected-decisions memory (a `## decision-mapping` decline record), and a demonstration that the assess-first pattern correctly refuses a redundant "cool" feature.

## What shipped (mattpocock/skills adoption ①–⑥)
- ① `CONTEXT.md` domain-glossary memory layer (dogfood + template seed) wired as a SOFT dependency into RA/SA.
- ② `/harness-grill` interview front-end (16th skill) + RA "recommend an answer per Open Question" rule.
- ③ 15-skill-authoring.md enriched with 7 named handles (leading word, completion criterion, premature completion, no-op test, sediment/sprawl, single source of truth, user/model-invoked load lens).
- ④ Agent-brief durability discipline → RA Hard rule 6 + pm-orchestrator dispatch contract (forward-ban / backward-evidence-exempt).
- ⑤ Tracer-bullet vertical-slice + smart-zone task-decomposition discipline (single-sourced in harness-plan, referenced by batch/stream/template).
- ⑥ solution-architect optional deep-module design-vocabulary lens.

## Standing follow-up (operator-pending — capability-gated, NOT regressions)
The runtime denies PowerShell to both the main agent and sub-agents. Every task verified green on Bash (verify_all.sh 32/0/0); the PS twins were edited symmetrically (or not at all) and are green-by-symmetry but unconfirmed. Before the next release tag, on a Windows shell:
1. `verify_all.ps1` → confirm 32/32.
2. `test-init.ps1` → capture total; reconcile `baseline.json test_init_ps_assertions` (currently 308) + both README `test--init-308%2F308` badges (T-02 follow-up). `test-init.sh` is already 273.
3. `test-real-project.ps1` → confirm 90.

## Notes
- Runtime: sub-agents have no `Task` tool and no PowerShell (Bash works). PM shell ran in the main thread; each of the ~42 stage executions ran as its own isolated sub-agent; PM ran the Bash gates + reconciled baselines.
- Not committed — left in the working tree per the repo's "commit only when asked" rule (on `main`).
- Research artifacts (outside the repo): plan `c:\Programs\_research\mattpocock-adoption-plan.html`; source clone `c:\Programs\_research\mattpocock-skills\`.
