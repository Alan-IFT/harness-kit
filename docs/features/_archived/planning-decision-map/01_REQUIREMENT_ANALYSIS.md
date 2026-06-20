# 01 — Requirement Analysis: planning-decision-map (T-10)

> Mode: **full** · Task type: **ASSESS-FIRST / decline-if-redundant** · deferred-human: defer, do not ask.
> Primary deliverable: an honest **overlap-vs-value assessment**, not a feature spec.

---

## 0. Assessment (lead) — overlap vs value

### 0.1 What the candidate is

mattpocock/skills' `decision-mapping` (his `in-progress/` = an **unshipped draft**) builds a single
compact git-tracked Markdown "decision map" of numbered investigation **tickets** (Research / Prototype /
Discuss), each with `Blocked by:` edges, sized to one ~100k-token agent session. A **frontier** is
advanced one ticket at a time; everything beyond it is **fog of war**. The whole map is loaded into every
session (bootstrap vs resume), and it is parallelism-aware. It targets the phase where a loose idea
"requires more than one agent session to turn into a plan" — i.e. resolving open **questions** until the
path is clear enough to implement, then it hands off to `/to-prd` or direct implementation.

### 0.2 Concept-by-concept mapping onto the LIVE harness (specific)

| decision-mapping concept | Harness equivalent (live, evidenced) | Verdict |
|---|---|---|
| The map file (one compact git-tracked Markdown, loaded as context) | `docs/batches/<id>/BATCH_PLAN.md` — one git-tracked Markdown pool, re-read every iteration (`skills/harness-stream/SKILL.md:34-39`, "Re-read the pool every iteration" hard rule :184) | **covered** |
| Numbered ticket (a unit of work, its own section) | A BATCH_PLAN **row** `ID \| Slug \| Goal \| Mode \| Depends on \| Status` (`docs/batches/_template/BATCH_PLAN.md:9-13`) | **covered** |
| `Blocked by: #N` edges | `Depends on` column = "row B uses an artifact row A produces" (`skills/harness-plan/SKILL.md:48`, `_template:26`) | **covered** |
| "frontier" advanced one node at a time | The **topological frontier** built from `Depends on`, drained one task per pass (`skills/harness-stream/SKILL.md:39,116-122`) — same word, same mechanic | **covered (same vocabulary)** |
| "fog of war" beyond the frontier (map deliberately incomplete) | The **append-only-friendly** pool: rows you have not written yet are the fog; the stream plans new `pending` rows into the frontier as you add them (`skills/harness-stream/SKILL.md:39-49`) | **covered (mechanic; term not yet surfaced in prose)** |
| Ticket sized to one ~100k-token session | **Smart zone** — size a task to ~one ~120k-token reasoning window, split before the model degrades (`skills/harness-plan/SKILL.md:43-48`, shipped T-06) | **covered** |
| Ticket type **Research** | `/harness-explore` — research/feasibility, findings.md with citations (`skills/harness-explore/SKILL.md:3,8-18`); also `Mode: explore` per row | **covered** |
| Ticket type **Prototype** (test a hypothesis with throwaway code) | `/harness-explore`'s throwaway-probe allowance (`skills/harness-explore/SKILL.md:37,81`) | **covered** |
| Ticket type **Discuss** (the default; uses `/grilling`+`/domain-modelling`) | `/harness-grill` — relentless one-question-at-a-time alignment interview that **walks the design tree resolving decisions one by one** and self-answers from the codebase (`skills/harness-grill/SKILL.md:22-72`) | **covered** |
| Bootstrap (surface open decisions, write the map) | `/harness-grill` interview → emits an aligned brief to `docs/features/<slug>/INPUT.md` (`skills/harness-grill/SKILL.md:86-107`); brief then seeds pool rows | **covered** |
| Resume (load whole map, resolve one ticket, add discovered tickets) | Stream **resume semantics** — a row whose `07_DELIVERY.md` is DELIVERED is skipped, every other row is re-evaluated and runnable; new rows added mid-run are planned next pass (`skills/harness-stream/SKILL.md:120,184`) | **covered** |
| Parallelism-aware (other agents edit the map) | The pool is the single source of truth, re-read every iteration; stream is serial by design (`skills/harness-stream/SKILL.md:184,189`) — a deliberate *narrower* choice, not a gap | **covered (narrower by design)** |
| Skip the map when grilling finds no fog ("nothing to do but implement") | `/harness-grill` "When NOT to invoke" → go straight to `/harness` when the requirement is already clear (`skills/harness-grill/SKILL.md:38-46`) | **covered** |
| Hand off when the path is clear (`/to-prd` / implement) | Brief → `/harness`, `/harness-plan`, or drop the slug into a `/harness-stream` pool (`skills/harness-grill/SKILL.md:111-114`). (`/to-prd` itself already **declined** — `.harness/rejected-decisions.md` "to-prd".) | **covered** |

Every concept maps. The vocabulary (**frontier**, **fog of war**) is already this repo's vocabulary
(`frontier` is live in harness-stream; `fog of war` is the same mechanic under the append-only pool).

### 0.3 The candidate genuinely-NEW delta — and why it is already owned

The honest prior (from the INPUT) names the only candidate delta: a **pre-task investigation map for the
loose-idea phase BEFORE BATCH_PLAN rows exist** — where open **QUESTIONS** (not tasks) are resolved one at
a time to push back the fog until the idea is decomposable into a pool.

That phase is **already owned**, by two complementary surfaces shipped before this task:

1. **`/harness-grill`** (T-03) IS the multi-question, one-at-a-time, design-tree-walking resolver for the
   loose-idea phase. Its description verbatim: "walks the design tree … resolving dependencies between
   decisions one by one" and "the 'I'm not sure I've said what I actually want yet' front-end that PRECEDES
   `/harness`, `/harness-plan`, and `/harness-explore`" (`skills/harness-grill/SKILL.md:3-16,58-59`). That
   is decision-mapping's **Discuss** ticket loop and its **bootstrap** step, already shipped — including the
   "no fog → just implement" skip (`:38-46`) and the multi-session resumability via its written brief.
2. **`/harness-explore`** (pre-existing) owns the **Research** and **Prototype** ticket kinds for the same
   loose-idea phase: "Can we even do X?" with cited findings and throwaway probes
   (`skills/harness-explore/SKILL.md:3,8-18,37,81`).

The hand-off chain the draft wants — **loose idea → resolve open questions one at a time → decompose into a
sequenced plan** — is therefore already the live chain **grill/explore → BATCH_PLAN pool (frontier) →
pipeline**, using the same frontier/fog mechanics. Per-question state across multiple sessions lives in the
grill brief (`INPUT.md`) and in `pending` pool rows; the "map loaded into every session" property is the
pool's "re-read every iteration" invariant.

### 0.4 The decision-policy precedent (this batch already declined the siblings)

`.harness/rejected-decisions.md` already records the directly-adjacent declines from this same
mattpocock-adoption batch: **`to-prd`** (decision-mapping's own hand-off target — declined as redundant
weight on this repo's pipeline intake) and **`design-it-twice`** (deferred). `decision-mapping` is the
upstream sibling that *feeds* `to-prd`; declining the consumer while building the producer would be
incoherent. Adopting a heavyweight decision-mapping skill would also reproduce exactly the duplication this
batch has consistently declined (ask-matt-router, issue-tracker-dedup, triage) — a parallel map-file format
competing with BATCH_PLAN.

### 0.5 Recommendation: **DECLINE** (record in `.harness/rejected-decisions.md`)

Building a `decision-mapping` skill (or a parallel map format, or a new section restating the frontier/fog
flow) would duplicate live surfaces with **zero genuinely-new capability**: the map=pool, ticket=row,
blocked_by=Depends-on, frontier=topological-frontier, fog=append-only-pool, session-sizing=smart-zone,
Research/Prototype=`/harness-explore`, Discuss/bootstrap=`/harness-grill`, resume=stream-resume. The
loose-idea→open-questions→decompose phase the draft targets is owned by `/harness-grill` (questions) and
`/harness-explore` (research/prototype), handing off into the BATCH_PLAN frontier. This is the
[[feedback_design_over_guards]] / lightweight outcome: a decline keeps the surface area flat instead of
accreting a duplicate. A decline is a valid, preferred delivery — the assessment + a `rejected-decisions.md`
record IS the work product.

**Considered but rejected — MINIMAL (a short "loose-idea→questions→decompose" note in `/harness-explore`
or `/harness-plan`):** rejected because it is **not a gap** — `/harness-grill`'s description already states
that flow ("walks the design tree … resolving dependencies between decisions one by one … PRECEDES
/harness/-plan/-explore"), and `/harness-explore`'s "Recommended next step" already lands on
"`/harness-plan` with approach X" (`:57-58`). A new note would restate covered ground and risk introducing a
**competing term set**, which the INPUT explicitly warns against. If a future user is observed unable to
find the loose-idea entry point, the smallest fix would be a one-line pointer in the AI-GUIDE "Workflow
entry" table — but that is speculative; not now.

---

## 1. Goal

Decide whether mattpocock/skills' (unshipped) `decision-mapping` offers any capability the live harness
pool/frontier/stream + `/harness-grill` + `/harness-explore` do not already provide, and either scope only
that delta or formally decline it.

## 2. In-scope behaviors (this task's deliverable, given the DECLINE verdict)

1. Produce a concept-by-concept overlap table mapping every `decision-mapping` concept (map file, ticket,
   blocked_by, frontier, fog of war, Research/Prototype/Discuss, session-sizing, bootstrap, resume,
   parallelism, skip-the-map) onto its live harness equivalent with a file-path citation per row (§0.2).
2. Identify the single candidate genuinely-new delta (pre-task investigation map for the loose-idea phase)
   and show, with citations, that it is already owned by `/harness-grill` + `/harness-explore` (§0.3).
3. Emit a recommendation of **DECLINE** with a one-paragraph rationale and the MINIMAL alternative
   explicitly considered-and-rejected (§0.5).
4. Append one `## decision-mapping` record to `.harness/rejected-decisions.md` stating decision=declined,
   the redundancy reason, and origin (mattpocock-adoption batch T-10), closing the loop with the existing
   `to-prd` / `design-it-twice` records.

## 3. Out-of-scope (regardless of verdict — from INPUT, restated as binding)

1. A new heavyweight `decision-mapping` skill duplicating the pool.
2. A second map-file format competing with `BATCH_PLAN.md`.
3. A new `verify_all` check.
4. Importing his `in-progress/` draft verbatim.
5. (Given DECLINE) any edit to `/harness-explore`, `/harness-plan`, `/harness-grill`, or any new prose
   section/term — the recommendation is decline, not MINIMAL.
6. A version bump (a decline touches only the assessment doc + `rejected-decisions.md`, neither of which is
   a distributed/versioned surface; counts stay 16 skills / 8 agents / 32 checks).

## 4. Boundary conditions

1. **`rejected-decisions.md` already has a `decision-mapping` record** (collision): one record per concept —
   append origin to the existing record, do not create a second (file convention `:7-10`). Verified absent
   at analysis time: the file holds design-it-twice / ask-matt-router / issue-tracker-dedup / to-prd /
   triage / skill-usage-telemetry / two skill-family records, no `decision-mapping`.
2. **File-size discipline:** `.harness/rejected-decisions.md` soft self-discipline is "~one screen" with no
   gate (`:9-10`); one added record stays within it.
3. **I.6 retired-claim guard:** the assessment introduces no banned anchor (INPUT note); "fog of war" /
   "frontier" / "decision map" are not on the I.6 banned list — confirm no banned ordered-anchor sequence
   is written verbatim.
4. **Empty/absent inputs:** the mattpocock draft path is read-only and present; if a referenced live skill
   file were absent the mapping row would read "absent" rather than fabricate an equivalent (none were
   absent).
5. **deferred-human mode:** no interactive asks; any residual ambiguity is recorded, not asked. None
   remain (see §8).

## 5. Acceptance criteria (verifiable; scoped to the DECLINE deliverable)

1. **AC-1 (mapping completeness):** every `decision-mapping` concept enumerated in the INPUT scope-guidance
   list appears as a row in §0.2 with a live harness equivalent and a `file:line` citation. Verify by
   cross-checking the INPUT list against the table — 13/13 rows present.
2. **AC-2 (delta honesty):** the document states the single candidate delta (loose-idea pre-task map) and
   cites the two live surfaces (`/harness-grill`, `/harness-explore`) that own it, with line refs. Verify
   §0.3 names both with citations.
3. **AC-3 (clear verdict):** the document recommends exactly one of DECLINE / MINIMAL, with a
   one-paragraph rationale and the alternative explicitly considered-and-rejected. Verify §0.5 + §9.
4. **AC-4 (memory record):** after this task, `.harness/rejected-decisions.md` contains a `## decision-mapping`
   record with `Decision: declined`, a redundancy reason, and an origin line. Verify by reading the file
   post-edit (grep `decision-mapping`).
5. **AC-5 (no duplicate built):** no new skill, no second map format, no new `verify_all` check, no
   `/harness-*` SKILL edit, no version/count flip is introduced by this task. Verify `verify_all` stays
   32/32 and `git status` shows only the assessment doc + `rejected-decisions.md` changed.
6. **AC-6 (I.6 clean):** `verify_all` I.6 PASSes over the new doc (no banned anchor). Verify via `verify_all`.

## 6. Non-functional requirements

- **Anti-bloat (material):** the deliverable must not grow distributed surface area — a decline is selected
  precisely to hold surface area flat ([[feedback_design_over_guards]], lightweight). No resident hook, no
  new gate.

## 7. Related tasks

- **T-09 `rejected-decisions-memory`** (`docs/features/_archived/rejected-decisions-memory/`) — created the
  `.harness/rejected-decisions.md` memory this task writes into; this is the loop-closing consumer.
- **T-06 `vertical-slices`** (`docs/features/_archived/vertical-slices/`) — shipped the smart-zone +
  vertical-slice decomposition discipline that subsumes decision-mapping's "ticket sized to one session".
- **T-03 `harness-grill`** (`docs/features/_archived/harness-grill/`) — the one-question-at-a-time
  loose-idea alignment front-end that owns the "Discuss/bootstrap" surface.
- **T-07 `sa-design-vocab`** (`docs/features/_archived/sa-design-vocab/`) — recorded `design-it-twice` as
  deferred in `rejected-decisions.md`; same batch, same memory file.
- **Prior `to-prd` / `triage` / `ask-matt-router` declines** (`.harness/rejected-decisions.md`) — the
  adjacent mattpocock-adoption declines this record sits beside.
- **T-021 `stream-auto-decompose` / T-022 `stream-defer-human`** (`docs/features/_archived/`) — established
  the live triage→pool→frontier mechanics cited in §0.2.

## 8. Open questions for user

None. Under deferred-human mode any ambiguity is recorded, not asked; the assessment is decidable entirely
from the live repo + the read-only draft, and no decision was reserved to the human (the decline is the
preset-rubric autonomy outcome, logged here and in `rejected-decisions.md`).

## 9. Verdict

**READY — recommendation: DECLINE.** A decline is a valid, preferred delivery for an assessment task. The
deliverable is this assessment + a `## decision-mapping` record appended to `.harness/rejected-decisions.md`.
No skill, no map format, no check, no version/count change. Every `decision-mapping` concept maps 1:1 onto a
live harness surface, and the only candidate delta (the loose-idea pre-task phase) is already owned by
`/harness-grill` (questions) + `/harness-explore` (research/prototype) handing into the BATCH_PLAN frontier.
