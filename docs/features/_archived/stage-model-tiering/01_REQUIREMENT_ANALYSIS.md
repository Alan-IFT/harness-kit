# 01 — Requirement Analysis: stage-model-tiering (T-22)

> Contract portion. Mode: **full** · Task type: **ASSESS-FIRST / decline-if-not-worth-it** ·
> deferred-human: defer, do not ask. Rationale sibling: `01_RATIONALE.md` (derivations,
> option arguments, open-question candidates).
> Primary deliverable: an **evidence-based disposition** of per-agent model / reasoning-effort
> tiering, not a wiring spec.

---

## 0. Assessment (lead)

### 0.1 Finding A — the delegated share of spend

**The delegated share of spend is not derivable to a decision-grade point estimate from evidence
available in this repository. Confidence: LOW.**

What is established:

| Statement | Value | Confidence | Evidence |
|---|---|---|---|
| A-1 · Directly-attributed sub-agent **output** cost, as a share of this project's 30-day bill | **6.7%** ($36 of ≈$540) | MODERATE | `docs/batches/default/BATCH_PLAN.md:42` (report figures); `docs/proposals/cost-attribution-2026-08.md:45-54` (establishes the $36 is output-only) |
| A-2 · A-1 is a strict **floor** on the delegated share (delegated spend is at least its own output component) | ≥6.7% | HIGH | Arithmetic; the excluded components are non-negative |
| A-3 · Sub-agent share of this project's **output tokens** | ≈31% | LOW | Derived in `01_RATIONALE.md` §R1; rests on this project's component mix matching the three-project mix |
| A-4 · Sub-agent share of **cache-read + cache-write** traffic — the 78% of the bill that decides the answer | **not derivable** | — | Requires a per-call context measurement that exists nowhere; named as unscheduled in `docs/proposals/cost-attribution-2026-08.md:85-87` |
| A-5 · Published band for the delegated share of this project's bill | **6.7% – 45%**, best-supported 25–45% | LOW | Floor from A-2; upper end from A-3 under an equal-per-call-context assumption |

**A-4 is the finding, not a gap in the analysis.** The two structural effects that would resolve it
push in opposite directions — a stage sub-agent makes many tool calls per dispatch (raising its call
share above its output share), while the orchestrating loop carries a context that accumulates
monotonically across a whole task and is re-read on every one of its calls (raising its per-call
cache cost above a sub-agent's). Neither factor is measured anywhere.

**The report's ≈$36 per-agent figure is not reused as "what sub-agents cost."** It is a sub-agent
output-token attribution that excludes cached context; it is used here only as the floor A-1/A-2.

### 0.2 Finding B — the decision does not turn on Finding A

The break-even for the proposed change is **independent of the delegated share**, because both the
saving and the cost of the risk it takes scale with the same quantity. Derived in `01_RATIONALE.md`
§R2:

- Addressable share of a run (stages 1 and 2 only, after the exclusions in §0.3): **≤37.3%**,
  measured from T-20's per-stage written-document volume.
- Cost of one additional rollback round (a stage 4 → 5 → 6 re-run): **≈44.5%** of a run.
- Break-even: a downgrade of the two addressable roles pays only while it causes fewer than
  **≈0.34 additional rollbacks per task** — a **≈11% relative increase** against the observed mean
  of 3.0 rollbacks per task (range 1–4, n=6, `docs/batches/default/STREAM_LOG.md:72-86`).

**This project has no instrument that can detect an 11% change in rollback rate.** The observed
rollback series has a range of 1–4 over six samples; distinguishing a 3.0 mean from a 3.34 mean
against that variance needs dozens of tasks. Meanwhile the change is not detectable-then-reversible
per consumer (§0.4).

### 0.3 Finding C — the addressable role set is two roles, and both are excluded on positive evidence

| Role | Disposition | Basis |
|---|---|---|
| gate-reviewer, code-reviewer, qa-tester | **Excluded** | Dispatch constraint; positive evidence absent for any downgrade. Reinforced by `docs/proposals/cost-attribution-2026-08.md:73-76` |
| developer | **Excluded** | Writes production code; the origin of the defects the three verification roles caught. A downgrade here is the highest risk per dollar in the set |
| pm-orchestrator | **Excluded** | Owns rollback decisions, hard stops and the deferred-human escalation — judgment, not routing alone. A PM-authored defect is already on record (`docs/batches/default/BATCH_PLAN.md:46`: an invented constraint cost a full T-13 rollback, "pure process friction, zero yield"). Also subject to OQ-2 |
| supervisor | **Excluded** | Best structural candidate (observer-only, outside the pipeline, cannot cause a rollback) and tested as such — but it runs once per ≥5 delivered tasks, so its saving is a fraction of a percent, against the same irreversible distribution surface |
| requirement-analyst, solution-architect | **Addressable, and rejected** | The only two roles left. Their errors have the longest propagation path in this repo's recorded history (`.harness/insight-index.md`: an architect assumed a WARN was advisory; a design rule contradicted its own acceptance criterion; a design mis-predicted its own mutation outcome). They are the exact roles the break-even in §0.2 is most sensitive to |

### 0.4 Finding D — the distribution surface makes any wiring irreversible per consumer

The framework agents are **plugin-native**: `agents/*.md` is the single source, auto-discovered as
`harness-kit:<name>`, and since v0.30 is **not** materialized into a generated project
(`AI-GUIDE.md:13,48,57`). Consequences, both binding on any future proposal:

1. A tier set in this repo is not dogfood-only. It propagates to **every installed project** on the
   next plugin update, with no per-project override mechanism.
2. There is therefore no staged rollout, no per-project opt-out, and no A/B channel — the change
   reaches consumers whose stakes are unknown to this repo before any evidence about its effect
   could accumulate.

### 0.5 Recommendation: **DECLINE the model-swap lever; DEFER the reasoning-effort lever**

Nothing is wired. No `agents/*.md` file is edited. The deliverable is this assessment plus one
`## stage-model-tiering` record in `.harness/rejected-decisions.md`.

The saving on offer is single-digit percent of a bill whose dominant lever is context reduction,
which is already delivering ≈16% risk-free with more available
(`docs/proposals/cost-attribution-2026-08.md:56-63`). It is obtainable only from the two roles whose
errors propagate furthest, its payoff hinges on a rollback-rate delta this project cannot measure,
and the change cannot be withdrawn from a consumer once shipped. The reasoning-effort lever — the
one the dispatch prefers, because it keeps the capability ceiling — is **deferred** rather than
declined: it is not yet established that the agent definition format carries such a key (OQ-1), and
the measurement that would let its effect be verified rather than projected does not exist (OQ-4).

**What would falsify this decline** (stated because a "provably safe" argument is where the
counterexample hides — `.harness/insight-index.md`, guard-cmd-chain CR2-2). All three are re-surface
preconditions:

- **F-1** — a per-call context-volume measurement that resolves Finding A-4 to a point estimate, and
  which places the delegated share at the top of the published band or above.
- **F-2** — a rollback-attribution instrument with enough resolution to detect an ≈11% change in
  rollback rate per stage, run over ≥20 tasks, establishing a pre-change baseline.
- **F-3** — a per-project tier override, so a downgrade is reversible by the consumer that
  experiences it rather than only by the publisher.

---

## 1. Goal

Decide, on evidence, whether wiring per-agent model / reasoning-effort declarations onto the eight
framework agents is worth what it risks after T-18's context reduction, and either specify exactly
what to wire or decline it with the decline recorded.

## 2. In-scope behaviors (this task's deliverable, given the DECLINE verdict)

1. State the delegated share of spend as a band with an explicit confidence grade, name each
   derivation step, and name the step that is not derivable in-repo together with the reason (§0.1,
   `01_RATIONALE.md` §R1).
2. State a projected saving derived from that share and from the addressable role set — not from a
   bare model-price ratio — and state that the projection for the recommended disposition is **zero**
   (§0.2, `01_RATIONALE.md` §R2).
3. Apply a positive-evidence bar to every role: enumerate all eight, state each role's disposition,
   and give the evidence for each exclusion rather than citing absence of objection (§0.3).
4. State whether any wiring propagates to the `/harness-init` distribution surface or is dogfood-only,
   with the reason (§0.4: it necessarily propagates; dogfood-only is unavailable for framework agents).
5. Emit the verdict DECLINE for the model-swap lever and DEFER for the reasoning-effort lever, with
   named falsification conditions that are also the re-surface preconditions (§0.5).
6. Append one `## stage-model-tiering` record to `.harness/rejected-decisions.md` carrying: the
   concept handle, `declined` for the model-swap lever and `deferred` for the reasoning-effort lever
   marked as such, the substantive why (single-digit saving, addressable set limited to the two
   longest-propagation roles, unmeasurable break-even, no per-consumer reversibility), the three
   re-surface preconditions F-1/F-2/F-3, and the origin (T-22, this assessment).

## 3. Out-of-scope (binding under either verdict)

1. Editing any `agents/*.md` frontmatter or body — no `model:` key, no reasoning-effort key, no
   tools change.
2. Editing any file under `docs/proposals/` — operator-authored input, read-only.
3. Adding, removing, or renaming a `verify_all` check. The count stays 32.
4. Context reduction — delivered by T-18.
5. Changing which stages exist, changing a stage's tool set, or relaxing any gate.
6. Adding a per-project tier override mechanism (F-3 names it as a precondition for re-surfacing;
   building it is not this task).
7. Building the per-call context measurement (F-1) or the rollback-attribution instrument (F-2).
8. A version bump. A decline touches only this task's stage documents and the rejected-decisions
   memory, neither of which is a distributed or versioned surface; counts stay 17 skills / 8 agents /
   32 checks.
9. Filing new pool rows. A new task is scope expansion reserved to the operator (OQ-4).

## 4. Boundary conditions

1. **`.harness/rejected-decisions.md` already carries a `stage-model-tiering` record** — the file's
   convention is one record per concept, so the existing record gains this origin and no second
   record is created. Verified absent at analysis time: the file carries eighteen records, none named
   `stage-model-tiering`.
2. **A two-part decision in one record** — the record states `declined` for the model-swap lever and
   `deferred` for the reasoning-effort lever explicitly and separately, so a future reader cannot read
   the deferral as a blanket decline or the decline as a blanket deferral.
3. **File-size discipline** — the rejected-decisions file carries a "~one screen" soft self-discipline
   with no gate; one added record stays within it. Agent files are untouched, so the 300-line agent cap
   is not approached: the two files with least headroom carry 293 and 287 lines.
4. **`verify_all` WARN is a FAIL for this task.** The final run reports PASS 32 / WARN 0 / FAIL 0. A
   WARN exits non-zero and does not satisfy the gate.
5. **Freeze proof is not `git status`.** The working tree carries eight siblings' delivered-but-uncommitted
   changes, so "absent from the dirty set" proves nothing about the agent files. The agent files being
   untouched is established by their content and modification time being unchanged relative to this
   task's first write, not by cleanliness in git.
6. **`docs/features/` is exempt from the I.6 retired-claim guard**, so quoting a retired claim inside
   these stage documents does not fail the gate; the same text is not written into any non-exempt file.
7. **Absent inputs** — every input consulted was present. Where a live statement was absent or
   self-contradictory, it is recorded as an open question rather than resolved by assumption (OQ-1,
   OQ-2).
8. **deferred-human mode** — no interactive ask is issued. Every reserved point is recorded in §8
   with a recommended answer and a blocking classification.

## 5. Acceptance criteria

| id | Criterion | Verification |
|---|---|---|
| AC-1 | The document states the delegated share of spend as a band, with an explicit confidence grade, and names the one derivation step that is not derivable in-repo together with its reason. | Read §0.1: band and grade present in A-5; A-4 names the non-derivable step and the reason. |
| AC-2 | The projected saving for the recommended disposition is stated and is derived from the delegated share and the addressable role set, not from a bare model-price ratio. | Read §0.2 and `01_RATIONALE.md` §R2: the projection is zero for the recommendation, and the break-even derivation shows both terms scaling with the delegated share. |
| AC-3 | Every one of the eight framework roles carries a disposition with a positive-evidence basis; no exclusion rests on absence of objection. | Read §0.3: eight roles across six rows, each with a cited basis. |
| AC-4 | The document states whether any wiring propagates to generated projects or is dogfood-only, with a reason. | Read §0.4: it necessarily propagates; dogfood-only is unavailable because framework agents are plugin-native and not materialized. |
| AC-5 | After this task, `.harness/rejected-decisions.md` contains exactly one `## stage-model-tiering` record carrying both lever decisions, the substantive why, the F-1/F-2/F-3 preconditions, and the origin. | Read the file post-edit; confirm a single occurrence of the heading. |
| AC-6 | No `agents/*.md` file is edited, no skill is added or changed, no `verify_all` check is added or removed, and no version or count changes. | Compare the eight agent file line counts against the values recorded in §4.3 and confirm content unchanged; confirm the `verify_all` run reports 32 checks. |
| AC-7 | The final `.harness/scripts/verify_all` run on bash reports **PASS 32 / WARN 0 / FAIL 0**. | Run it; read the summary line. A WARN fails this criterion. |
| AC-8 | Every open question in §8 carries a recommended answer and a blocking classification, and no question classified BLOCKING remains unresolved at the verdict. | Read §8. |

## 6. Non-functional requirements

- **Anti-bloat (material).** The disposition holds distributed surface area flat: no new file on any
  distributed surface, no resident hook, no new gate. This is the lightweight / design-out-the-cause
  line in `.harness/decision-rubric.md`.
- **Irreversibility (material).** Any future wiring reaches every installed project with no
  per-consumer override; F-3 exists because reversibility is a precondition, not a nicety.

## 7. Related tasks

- **T-21 `stage-cost-attribution`** — `docs/proposals/cost-attribution-2026-08.md`. The measurement
  this assessment is built on and the reason the premise changed. Operator-authored, read-only.
- **T-18 `stage-contract-split`** — `docs/features/_archived/stage-contract-split/`. Delivered the
  context reduction that made tiering a secondary lever; its measured 37.7% stage-4 read reduction is
  the alternative this decline is weighed against.
- **T-10 `planning-decision-map`** — `docs/features/_archived/planning-decision-map/`. The live
  precedent for a DECLINE delivered as the work product, with no code and no version bump; its
  `## decision-mapping` record is the shape §2.6 follows.
- **T-11c `entropy-watch-persist`** — `docs/features/_archived/entropy-watch-persist/`. A prior
  scope-down to a decline recorded in the same memory file.
- **T-15 `hook-truth-verify-scope`** — `docs/features/_archived/hook-truth-verify-scope/`. The
  precedent that a sibling row making a failure repairable does not make an unsound change sound
  (ASSESS-FIRST corollary), and the source of the dirty-tree freeze-proof condition in §4.5.
- **T-20 `harvest-wrapped-insight`** — `docs/features/_archived/harvest-wrapped-insight/`. The
  per-stage document volumes measured in §0.2 come from this task's archived stage documents.

## 8. Open questions for user

Candidate answers and the argument selecting among them are in `01_RATIONALE.md` §R4.

1. **OQ-1 · Does the Claude Code agent definition frontmatter carry a reasoning-effort key, and under
   what name and value set?** Not verifiable from inside this repository — no agent file, rule,
   template or skill references one, and stage 1 has no network tool.
   **Recommended:** treat it as unverified; the solution-architect confirms it against the upstream
   schema before any future wiring is specified, following the consult-upstream-schema-first
   discipline this repo already applies to settings keys. **NON-BLOCKING** — the decline holds under
   both answers: if the key does not exist, the preferred lever is unavailable and only the riskier
   one remains; if it does exist, the break-even in §0.2 is unchanged.

2. **OQ-2 · Does a `model:` declaration on `pm-orchestrator` take effect during a `/harness-stream`
   drain?** Two live statements in this repository contradict each other: the stream skill dispatches
   `harness-kit:pm-orchestrator` through the `Task` tool "in its OWN context", while a carried
   runtime note states that sub-agents have no `Task` tool and the PM shell therefore runs in the main
   thread. Under the second reading a `model:` on the PM governs nothing in stream mode.
   **Recommended:** treat the stream skill as current and the carried note as stale, and correct the
   stale note under a separate row rather than inside this task (§3.9 bars filing it here).
   **NON-BLOCKING** — the PM is excluded on independent grounds in §0.3.

3. **OQ-3 · Does the decline record cover both levers, or only the model swap?**
   **Recommended:** one record covering both, with the model-swap lever marked `declined` and the
   reasoning-effort lever marked `deferred` — the file's convention is one record per concept, and
   splitting them would create two records for one decision. **NON-BLOCKING.**

4. **OQ-4 · Is the missing per-call context measurement (F-1) filed as a pool row now?** The
   cost-attribution proposal already names it as an unscheduled candidate, and it is the precondition
   that would let both context reduction and any future tiering be verified rather than projected.
   **Recommended:** file it, as a measurement-only row in the shape T-21 took. **BLOCKING for the
   filing only, not for this task** — filing a pool row is scope expansion reserved to the operator
   under the standing red lines, so this requirement records the recommendation and files nothing.

5. **OQ-5 · Does this decline take a CHANGELOG entry or a version bump?**
   **Recommended:** neither. No skill, agent, script, template or check changes, so the documentation
   rules' sync obligation is not triggered, and T-10's decline set the precedent of no version or
   count flip. **NON-BLOCKING.**

## 9. Verdict

**READY — recommendation: DECLINE the model-swap lever, DEFER the reasoning-effort lever.**

A decline is a valid and, here, the preferred delivery: the assessment plus a
`## stage-model-tiering` record in `.harness/rejected-decisions.md` **is** the work product. No agent
file is edited, no skill or check is added, and no version or count changes.

The delegated-share finding is published as a band of **6.7% – 45%** at **LOW confidence**, with its
decisive component — the sub-agent share of cache traffic — stated as **not derivable in-repo** and
the reason given. The decision does not rest on closing that gap: the break-even is independent of
the delegated share, sits at roughly **0.34 additional rollbacks per task (≈11% relative)**, and this
project carries no instrument able to detect a change that size — while the change itself would reach
every installed project with no per-consumer override. Projected saving for the recommended
disposition: **zero**, deliberately, against ≈16% already banked risk-free by context reduction.

No BLOCKING open question remains for this task. OQ-4's filing decision is reserved to the operator
and does not gate delivery.
