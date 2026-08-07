# Stream Report — default pool

> Newest run first. Earlier runs are retained below.

---

# Run 2026-07-31 → 2026-08-02 · hook-truth + efficiency + cost waves

> Driver: ambient (chat-heartbeat) · Pool drained: 0 pending, 0 in-progress.
> Final gate: `verify_all` **PASS 32 / WARN 0 / FAIL 0**, green at every task boundary.
> **Nothing committed** — the working tree carries nine rows of delivered changes.

## Needs your input

**Pipeline-deferred items: none.** No row ended `needs-human`, and no ingest ambiguity was
recorded. One escalation was raised and resolved inside the run (see item 2).

**Items that require you, because I cannot do them:**

### 1. PowerShell verification — 25 obligations, 4 security-relevant · BLOCKS A RELEASE

`pwsh` is not installed on this host and no agent here can execute PowerShell. Every `.ps1`
across nine delivered rows is **green-by-symmetry only**. A prior release shipped two
PowerShell files that were both parse-broken and runtime-broken on Windows; only an operator
run caught them.

Two of the security-relevant items verify that the destructive-command guard actually blocks
on Windows. If that is broken, every Windows user of the published plugin has a guard that
silently does nothing.

Consolidated checklist: `docs/proposals/operator-powershell-checklist.md` — **read its drift
warning first** (see EP-002 below for why).

### 2. An escalation I resolved under your standing authorization

T-18 returned `BLOCKED: NEEDS-HUMAN` on an acceptance-bar question: accept a measured but
narrower structural guarantee, or spend a fourth design round widening it. You had authorized
me to decide, so I did — **accept**, on three grounds: the corrective for one finding directly
contradicted the clause that closed a CRITICAL (so a fourth round was not convergent); the
class the task was launched against *is* structurally closed; and the surviving class needs
semantic judgement that structure cannot supply without introducing misclassification.

I required four things in exchange, all delivered: the grade corrected in QA's exact words,
the residual published unsoftened, the phenomenon harvested as its own insight, and the real
MINOR discharged. **If you would rather rule on acceptance-bar questions yourself, say so and
I will revert to escalating them.**

### 3. Two decisions that are yours

- **Whether to commit.** Nine rows of delivered work sit uncommitted on `main`.
- **Whether to act on the entropy findings.** Machine reminds, you authorize — nothing was refactored.

## Entropy watch

Cadence due (8 deliveries against threshold 5). Artifact:
`docs/features/_supervision/entropy-2026-08-02.md` — **`Entropy-verdict: FINDINGS-PRESENT`**,
3 findings, 0 suppressed by the decline filter.

| ID | Class | Strength | Where |
|---|---|---|---|
| EP-001 | cross-seam leakage | **Strong** | `agents/{gate-reviewer,code-reviewer,pm-orchestrator}.md` |
| EP-002 | deepening candidate | **Strong** | `.harness/scripts/baseline.json` |
| EP-003 | cross-seam leakage | Worth exploring | `verify_all.sh` G.4 |

**EP-001 — the review agents cannot write their own output.** Both declare `Read, Glob, Grep`
yet their contracts name a file they must author. The reconciliation exists in exactly one of
the three contracts that implement it, as a parenthetical; the agent that performs the write
carries no mention of the duty. Fired live this run — three T-22 documents were transcribed
by the orchestrator.

**EP-002 — and it caught me.** The checklist I wrote hours earlier had **already drifted**
from `baseline.json`: 17 obligations reported where there are **25**, because I read
`_qa_note_t13`'s local indices as global item numbers and silently dropped 8. One day, two
homes, 8 of 25 apart. Counts corrected and a drift warning added — but the correction is not
the lesson. **A second home for a fact drifts from the first no matter how careful the copy
is.** Same defect class the hook-truth wave spent four rows eliminating, reproduced by the
operator who had just finished eliminating it.

**EP-003 — a twelfth restatement outside the gate.** `CONTRIBUTING.md:22` states the check
count but sits in no `g4_files` entry. No live drift; the finding is that G.4 closes by
enumeration rather than construction.

**Screened out as healthy** (deletion test applied): the hook-spec consolidation is a genuine
deep module, the rewritten guard is depth rather than sprawl, and the contract/rationale split
propagated correctly to every consumer checked.

Deepening is opt-in via `/harness-deflate`. The stream never refactors.

## Per-task results

| ID | Slug | Verdict | Rollbacks | Folder |
|---|---|---|---|---|
| T-13 | hook-truth-spec | DELIVERED | 4 | `_archived/hook-truth-spec/` |
| T-14 | hook-truth-status | DELIVERED | 3 | `_archived/hook-truth-status/` |
| T-15 | hook-truth-verify-scope | DELIVERED (assessed, proceeded) | 1 | `_archived/hook-truth-verify-scope/` |
| T-16 | hook-truth-derivation | DELIVERED | 2 | `_archived/hook-truth-derivation/` |
| T-17 | guard-cmd-chain | DELIVERED | 4 | `_archived/guard-cmd-chain/` |
| T-18 | stage-contract-split | DELIVERED | 3 + 1 escalation | `_archived/stage-contract-split/` |
| T-19 | stage-summary-header | **SKIPPED** — superseded before dispatch | — | (none) |
| T-20 | harvest-wrapped-insight | DELIVERED | — | `_archived/harvest-wrapped-insight/` |
| T-21 | stage-cost-attribution | **DONE — measured directly, no pipeline run** | — | `docs/proposals/cost-attribution-2026-08.md` |
| T-22 | stage-model-tiering | **DELIVERED as DECLINE — nothing wired** | — | `_archived/stage-model-tiering/` |

**Aggregate:** 8 delivered · 1 skipped · 1 declined · 0 failed · 0 blocked · 0 needs-human.
~3M sub-agent tokens. Gate green at every boundary; no hard stop fired.

### What the wave achieved

- **Zero hand-synchronised copies of the hook byte-form remain in any hook-writing path.** A
  mutation in the spec propagates to all four derivation flows with no edits; the idiom scan
  went 16 non-comment hits → 0.
- **A reproduced guard bypass is closed.** `echo hi && rm -rf <outside>` and siblings now
  block; the regression driver went 17 → 87 rows and is pinned. The residual is published,
  not buried.
- **Stage-4 context down 37.7%** (stages 5/6: 52.9% / 51.7%), measured span-by-span on a real
  archived task, published at the smallest of three successive measurements.
- **Two gates were found to have been lying.** F.2's template assertion was vacuous since it
  was written — deleting the entire hook block still passed. The health report declared the
  guard disabled while it was demonstrably blocking.
- **A silent data-corruption defect in the memory layer is fixed**, and the fix proved itself
  on its own delivery twice.

### Cost structure — the finding that redirected the wave

From `docs/proposals/cost-attribution-2026-08.md`, reconciled against the real bill to 1.6%:

**78% of spend is cache traffic, not model intelligence** — cache reads 43.3%, writes 35.1%,
output 21.5%. Each call reads ~128,000 tokens of cached context and produces ~1,272 tokens of
output: a 100:1 ratio.

This is why T-22 declined. Model tiering is a proportional discount on a bill whose size is
set by context volume, and it is the only lever that can make the pipeline worse at its job.

## Recommended follow-ups (none scheduled — the stream does not invent rows)

| # | Item | Why |
|---|---|---|
| 1 | EP-001 — give the review agents a write path, or name the persist duty in the orchestrator's contract | An obligation exists only as a parenthetical in one of three contracts |
| 2 | EP-002 — give the PowerShell obligations a real home | 25 release-gating items as prose in a machine-read JSON file; a second home drifted within a day |
| 3 | Per-call context measurement (T-22's F-1) | Context reduction is *projected*, not verified — nothing in-repo measures it |
| 4 | T-17's residual bypass surface | Published and precise: the verb is missed when not at token 0 (`> /tmp/log rm -rf <outside>`) |
| 5 | O(n²) scan in the guard | Any length cap must fail **closed** |
| 6 | `70-doc-size.md:27` stale path label | Caps `.harness/agents/*.md`; agents live at `agents/*.md`. Not rot — just wrong |

## Notes

- **Two infrastructure faults hit this run**, neither a defect in the work: an API 403 and an
  intermittently unavailable tool classifier. T-16 lost two resume attempts. The fix that
  worked — persist each stage's artifact **immediately on return** rather than batching writes
  to the end — is unprompted evidence for the stage-checkpointing gap recorded in
  `docs/proposals/frontier-gaps-2026-07.md`.
- **Every rollback was raised by a downstream stage doing real verification**, not by a stage
  accepting an upstream claim. One caught a round-2 fix that opened a new hole while closing
  another. One QA stage predicted its own delivery document would trip a defect it had just
  found — and was right.
- `docs/proposals/*.md` are operator-authored and were excluded from every task's scope.

---

# Run 2026-06-19 → 2026-06-20 · mattpocock/skills adoption batch

> Driver: continuous (single-turn, file-channel) · adoption batch from github.com/mattpocock/skills
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
