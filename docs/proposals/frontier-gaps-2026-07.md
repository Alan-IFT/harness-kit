# Frontier gap assessment — 2026-07 industry reading

> Status: **backlog only — nothing scheduled.** Recorded 2026-07-31 at the operator's
> request ("write it all to backlog, don't queue it"). No pool rows were created.
> Promote an item by copying its "Row sketch" into `docs/batches/default/BATCH_PLAN.md`.

## Source material

Five Chinese-language engineering articles (2026-07-20 → 2026-07-30), read in full
including figures:

| Date | Title | Author | What it contributes here |
|---|---|---|---|
| 07-20 | AI 代码生成率 94%：我们用一个 Skill 跑通需求开发全流程 | 企业微信团队 | Three-tier project knowledge base; red-line YAML single source; sentinel-file success criterion |
| 07-21 | 从 Vibe Coding 到 AI 原生研发团队 | masoncai | Rules/Skills split; code-rot skills with separated duties; token-thrift practices |
| 07-24 | 腾讯 WorkBuddy 实践：如何把 Agent 做成可用产品 | Anne | Five-layer harness model; feedforward/feedback control; autonomy-by-risk ceiling |
| 07-28 | Loop Engineering 已死？一文带你了解 Graph Engineering | lukiexing | Five-layer evolution map; verifier-as-node; reality-anchor warning; multi-agent cost data |
| 07-30 | AI Coding 的下一站，不是更会写代码，而是更懂团队 | QQ 浏览器平台团队 | Team-experience pipeline: Review / Dedup / Merge three-layer governance, with measured outcomes |

## Positioning conclusion (read this before the gaps)

The 07-28 article lays out a five-layer progression — Prompt → Context → **Harness** →
Loop → Graph — and argues the industry's centre of gravity has moved to the outer two.

This project is named after layer three but already operates at four and five:
`/harness-goal` is a Loop; `pm-orchestrator` driving seven staged roles is the
Orchestrator-Workers topology wrapped around a Pipeline, two of the three canonical
shapes that article names.

More importantly, the warnings those articles treat as hard-won are already satisfied
here. This matters because it bounds the work: the gaps below are refinements, not a
rebuild.

| Warning from the reading | Where this project already satisfies it |
|---|---|
| "The biggest misconception — the model as both athlete and referee" | gate-reviewer / code-reviewer / qa-tester each run in their own sub-agent context |
| "If no node touches reality, it's a more elaborate hallucination machine" | `verify_all` is a reality anchor: exit codes, real test runs |
| "Model judgement on the nodes, code reliability on the edges" | the gate is code, not a model verdict |
| "The role graph must change slowly and stay auditable" | `guard-rm` guardrail + the decision-policy modes |
| "Judge success by an artifact on disk, never by stdout" | resume semantics read `07_DELIVERY.md` |
| "Separate the scanner from the fixer" | supervisor scans observer-only; `/harness-goal` executes only on authorization |

Live corroboration, same day this was written: during T-13 the QA stage's mutation
testing caught a degradation case (`r-6`) that the code-review stage had missed.
Independent verifier nodes are not a theoretical benefit here.

---

## Gap 1 — the insight index is the two-step pipeline the 07-30 article proved fails

**Strength: strong. Highest recommended.**

### Evidence

The 07-30 article instrumented 1,236 real development sessions. Their initial design was
`report conversation → extract experience → store`. Roughly **90% of what it produced was
garbage** — measured, not opined, against "does recall change agent behaviour for the
better". They enumerate nine garbage classes (fabricated constraints, generic common
sense, conversation summaries, one-off cases, personal preference, missing context, mixed
granularity, non-actionable, insufficient evidence) and were forced to evolve a three-layer
governance chain: **Review → Dedup → Merge**.

### Current state here

`archive-task` harvests the `## Insight` section of `07_DELIVERY.md` straight into
`.harness/insight-index.md`. That is exactly the two-step chain. There is no quality gate,
no candidate dedup, and no reconciliation against history.

Three consequences, each already observable rather than hypothetical:

1. **Contradictions have nowhere to go — one surfaced today.** During T-13 the pipeline
   found that a test tally recorded in the T-12 archive could not have been produced by a
   real run. The 07-30 design has a dedicated `contradict` action (flag it, route to human
   adjudication, never auto-suppress) precisely because a conflict between old and new
   understanding is itself valuable signal. The rule here is *"Never edit other people's
   lines"* — so a line that has been disproven stays, and keeps misleading readers.
2. **Rotation is by age, not by value.** The cap is enforced by rotating the oldest data
   lines out. The article names silent growth as an open problem; rotating by age is worse
   than growth, because it can evict a high-value old truth while retaining a low-value
   recent one. Nothing observes whether a given line was ever recalled or acted on.
3. **Evidence citations rot.** Index lines cite concrete symbols and script paths as proof.
   The article's worked example: an experience asserted a method that did not exist; the
   agent followed it, failed to compile, and — critically — **doubted itself rather than
   the experience**, then retried in a loop. Their fix was source exploration as a factual
   check inside Review.

### Row sketch (if promoted)

- Add a quality gate between the delivery doc and the index, with the rejection classes
  named explicitly so the decision is auditable rather than a vibe.
- Add a reconcile step with four outcomes — create / update / skip / contradict — where
  `contradict` marks the conflict for a human instead of silently overwriting.
- Give each index line a recall/erosion signal so eviction can consider value, and add a
  cheap existence check for the symbols an evidence citation names.

Likely splits into 2–3 rows; the gate and the reconcile step are independently verifiable.

---

## Gap 2 — the project map has no middle tier and no drift detection

**Strength: strong for generated user projects, moderate for this repo.**

### Evidence

The 07-20 article's three-tier pyramid: **L1 overview** (under 5 KB, preloaded every
time) / **L2 per-module** (file-level register, loaded on demand) / **L3 semantic bridge**
(design-token → engineering-API mapping). They report compressing context from roughly
10M tokens to ~30K — a 300× reduction — and note the same artifact made human onboarding
faster, not just agent work.

The load-bearing half is not the tiers, it is `check_project_wiki_stale.py`: a SHA
baseline cache per file, a three-colour triage list, and a **pre-commit hook that blocks
the commit** when the map has drifted from the code. They state that project added 200+
files and 1000+ changes in six months and that manual upkeep would have collapsed.

### Current state here

There is a single-tier `docs/dev-map.md` and a `CONTEXT.md` glossary that covers roughly
the L3 role. The L2 per-module register is absent.

The sharper problem is that the pre-commit hook only checks `.harness/` ↔ `.claude/`
synchronisation. **Nothing detects documentation-versus-code drift.** The map is
maintained by discipline alone.

This gap bites generated user projects harder than it bites this repository, because a
generated project inherits only the single-tier map template.

### Row sketch (if promoted)

- A drift sensor keyed on content hashes that reports added / removed / substantially
  changed sources against what the map claims, wired into the existing commit-time check
  as a blocking signal.
- Only then consider the L2 tier itself — the sensor is what makes any tier survivable,
  and it is useful even against today's single-tier map.

Order matters: build the sensor first. A richer map without drift detection decays faster
than a thin one.

---

## Gap 3 — recovery is task-level, so a long interrupted task loses its stage work

**Strength: moderate. Cheapest of the four.**

### Evidence

The 07-28 article singles out durable execution as the capability a single loop can never
provide: a state snapshot at each super-step, enabling human-in-the-loop pause, time-travel
replay, and — the relevant one — **restart from the last successful step rather than from
the beginning**. It also describes pending writes, so a failure in one step does not
discard the successful outputs of its siblings.

### Current state here

Resume semantics are task-level: a row counts as done when its `07_DELIVERY.md` parses as
delivered, otherwise the whole row is runnable again.

T-13 was interrupted this session after roughly 2.8 hours, having completed stages 1
through 6. It was recovered by resuming the orchestrator's own transcript — **a capability
of the host runtime, not of this project.** In a fresh session, that work would have had
to be reconstructed by hand from `PM_LOG.md`.

The materials for a fix already exist: `PM_LOG.md` plus the numbered stage documents *are*
the checkpoints. What is missing is an explicit resume-from-stage semantic that reads them.

### Row sketch (if promoted)

- Define a stage-level completion signal derivable from artifacts already on disk, and
  teach the orchestrator's entry path to skip completed stages rather than restart the row.
- Keep it read-only over existing artifacts — no new state store. (See the standing
  principle in the rejected-decisions memory: a producer that re-derives its outputs
  deterministically does not need a persistence layer.)

---

## Gap 4 — no risk-based triage; every non-trivial task pays the full price

**Strength: worth exploring. I am not advocating this one.**

### Evidence

Anthropic figures quoted in the 07-28 article: multi-agent systems consume roughly **15×**
the tokens of a plain exchange, and token volume alone explains about **80%** of
performance variance. Their guidance is that multi-agent is only worth it where task value
covers that cost. The 07-24 article is more direct, proposing an **autonomy ceiling that
falls as risk rises**: high for throwaway scripts and internal tooling, medium for public
APIs and cross-system changes, low for core business logic.

### Current state here

Every non-trivial task runs the full seven stages. Mode selection exists but is a human
choice at invocation, not risk-based routing.

Concrete cost data from this session: T-13 — adding one script pair and extending an
installer — consumed roughly 2.8 hours and 200K+ tokens across stages 1–6 and had not
reached delivery.

### Why I am not advocating it

The strict pipeline *is* this project's value proposition; adding a bypass lane is the
kind of change that erodes the thing being sold. The same articles that supply the cost
data also insist on preferring the simplest arrangement that works — which argues against
adding triage machinery as much as it argues against paying full cost. If this is ever
taken up, the honest framing is a deliberate trade, not an optimisation.

---

## Deliberately not adopted

Recorded here so these are not re-litigated. Consider appending the durable ones to
`.harness/rejected-decisions.md` if they come up again.

| Idea from the reading | Why not |
|---|---|
| Fan-out / fan-in (diamond) parallel topology | Serial execution is a deliberate invariant that avoids concurrent edits to the same files; going parallel would require per-agent workspace isolation. Complexity is not repaid. |
| Adversarial verification by majority vote (N skeptics per finding) | Roughly 3× verification cost. T-13 showed a single QA stage doing mutation testing already caught what code review missed. Revisit only if a real escape occurs. |
| Runtime / visual verification (simulator install, screenshot diffing) | Domain-specific to mobile UI work. This is a general-purpose framework; the analogue is already covered by the gate. |
| MCP / plugin packaging as a distribution unit | Already the case — this ships as a plugin. |

## How to promote an item

Copy the row sketch into `docs/batches/default/BATCH_PLAN.md` as one or more `pending`
rows, with `Depends on` chained only where one row genuinely consumes another's output.
Gap 2's sensor should precede any expansion of the map tiers; Gap 1's quality gate should
precede its reconcile step. Gaps 1, 2 and 3 are mutually independent.
