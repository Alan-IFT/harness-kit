# 01 — Requirement Analysis · T-18 `stage-contract-split`

- **Task**: T-18 `stage-contract-split`
- **Mode**: `full` (dispatched from a `/harness-stream` drain, **deferred-human mode**)
- **Verdict**: **READY** (see §12 — every ambiguity carries a binding `Recommended:` answer)

---

## 1. Goal

Split every pipeline stage's output document into a **stage contract** (the binding portion a
downstream stage consumes) and a **stage rationale** (the reasoning portion the gate and the
reviewers consume), move round and rollback history into the **routing log**, and make each
downstream stage's agent contract consume the contract portion alone — so that pre-written
implementation text, accumulated changelogs, and restated summaries have no location in the
structure rather than merely being discouraged.

---

## 2. Measured problem — my own sampling

### 2.1 What I sampled and why

I measured all 40 documents in the five archived folders by line count (exact, via a whole-file
line match), then read **section headings** for all five `02_SOLUTION_DESIGN.md` and for the
T-17 stage-1/3/4 docs, then read **only the passages the heading scan flagged** — the largest
design (T-16, 1657 lines), the design the operator inspected (T-15, 1152 lines), and the gate
report that ruled on document size (T-17). I did not read 40 documents end to end. Contract
membership in §3 is derived from **cross-reference counts** (which upstream identifier a
downstream document actually cites), not from reading each document's prose.

### 2.2 Volume (lines, measured)

| Task | 01 | 02 | 03 | 04 | 05 | 06 | 07 | PM_LOG | Total |
|---|---|---|---|---|---|---|---|---|---|
| T-13 `hook-truth-spec` | 454 | 499 | 275 | 500 | 356 | 500 | 92 | 236 | 2912 |
| T-14 `hook-truth-status` | 439 | 820 | 305 | 500\* | 338 | 1289 | 154 | 283 | 4128 |
| T-15 `hook-truth-verify-scope` | 254 | 1152 | 243 | 903 | 196 | 647 | 225 | 436 | 4056 |
| T-16 `hook-truth-derivation` | 331 | 1657 | 267 | 493 | 458 | 965 | 111 | 57 | 4339 |
| T-17 `guard-cmd-chain` | 514 | 768 | 475 | 1304 | 660 | 885 | 230 | 660 | 5496 |

\* T-14's stage-4 document is named `04_IMPLEMENTATION.md`, not `04_DEVELOPMENT.md`
(`docs/features/_archived/hook-truth-status/04_IMPLEMENTATION.md`). T-12 did the same
(`docs/features/_archived/resilient-hooks/04_IMPLEMENTATION.md`). Every agent contract that
consumes stage 4 names `04_DEVELOPMENT.md`, so an agent following its own workflow literally
finds no file. This is in scope (§5 FR-8).

### 2.3 Ingest amplification (lines a stage must read under today's contracts)

Computed from §2.2 and the agents' stated input lists (stage 2 reads 01; stage 3 reads 01+02;
stage 4 reads 01+02+03; stage 5 reads 01+02+04; stage 6 reads 01+02+04+05):

| Task | S2 | S3 | S4 | S5 | S6 | **Total ingest** | Lines written 01–05 | Amplification |
|---|---|---|---|---|---|---|---|---|
| T-15 | 254 | 1406 | 1649 | 2309 | 2505 | **8123** | 2748 | 2.96× |
| T-16 | 331 | 1988 | 2255 | 2481 | 2939 | **9994** | 3206 | 3.12× |
| T-17 | 514 | 1282 | 1757 | 2586 | 3246 | **9385** | 3721 | 2.52× |

Cost grows with the square of stage count because every stage re-reads every predecessor in full.

### 2.4 The three defect classes, located

1. **Pre-written implementation literals.** `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:126-160`
   and `:166-240` carry the finished bash and PowerShell bodies for one `verify_all` check,
   including an 11-line comment destined verbatim for the script. The string `TRACKED CONTENT ONLY`
   now exists in exactly three files: that archived design plus `.harness/scripts/verify_all.sh`
   and `.harness/scripts/verify_all.ps1`. The design's copy is archived and therefore
   stale-by-construction the first time either script's comment is edited.
2. **Accumulated round history inside the operative design.**
   `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:1053`, `:1075`, `:1110` are three
   consecutive round changelogs occupying lines 1053–1152 (100 lines, 8.7% of the document).
   `_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md:1281` and `:1523` occupy 375 of 1657
   lines (22.6%). One of them is **deliberately false as current state**:
   `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:1146` records that §16 is "deliberately
   left saying 'the two accepted deviations'" after QA found a third, and
   `_archived/hook-truth-verify-scope/PM_LOG.md:87-89` blesses that as correct freeze discipline.
   The consequence is a downstream reader taking a false statement from the operative document.
3. **No structural marker separating binding input from reasoning.** Both defect classes above sit
   under `##` headings identical in kind to the binding sections. Two prior stage agents diagnosed
   this independently: `_archived/guard-cmd-chain/03_GATE_REVIEW.md:352` rules the round-2 changelog
   "a stage-transition artifact … dead weight for the Developer and for the archive", and
   `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:982-987` states that "a design that
   survives three review rounds will exceed the per-stage cap on changelog weight alone" and that
   extending compaction to multi-round stage docs "is a rule-fragment change and thus its own task".
   **T-18 is that task.**

### 2.5 Prior art already in the repo

`_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:956-968` defines a body/appendix split
for mandated verbatim evidence: the body stays under cap and cites evidence by step id; a trailing
appendix carries the runs and is exempt from the "reference, don't paste" rule; the document header
declares the split. That ruling was scoped to one task. This task generalises the same shape from
"evidence" to "everything a downstream stage does not consume".

---

## 3. Per-stage consumption — what the successor actually used

Derived from cross-reference counts across the five folders. "Cited" means the downstream document
names the upstream identifier or section. Counts are per-file occurrence counts.

| Producer → consumer | Consumed (cited and acted on) | Evidence | Read past (never cited downstream) |
|---|---|---|---|
| **1 → 2** (RA → SA) | Acceptance criteria, functional requirements, in-scope items, boundary conditions, out-of-scope list, open questions + their `Recommended:` answers | `AC-` in `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md` ×32, `FR-` ×18, `OQ-` ×11; `_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md` `AC-` ×25, `OQ-` ×16 | The RA's evidence narrative (`_archived/hook-truth-verify-scope/01_REQUIREMENT_ANALYSIS.md:11-84`, the ASSESS-FIRST section — 74 of 254 lines), the Related-tasks section |
| **2 → 3** (SA → GR) | Everything, by design — dimensions 3 (reuse correctness) and 4 (risk coverage) audit the reasoning itself | `Reuse audit` appears in 47 archived files and in **only** `02_*` and `03_*` — never in `04`/`05`/`06` | — (the gate is the legitimate rationale consumer) |
| **3 → 4** (GR → Dev) | The consolidated binding-conditions list; the pre-answered developer questions | `_archived/guard-cmd-chain/04_DEVELOPMENT.md:387` "Gate conditions C-1 … C-15 — per-condition disposition"; `_archived/guard-cmd-chain/03_GATE_REVIEW.md:441` "R2.11 — Consolidated conditions (authoritative; supersedes round-1 C-1…C-9)" | The 8-dimension audit narrative, the per-finding routing prose, the round-1 finding index |
| **2 → 4** (SA → Dev) | Architecture summary, module decomposition / interfaces, data model, change ledger, migration + edit-sequence constraints, verification plan, named residuals that must travel | T-15 `04` cites design §1, §3/§3.1/§3.2, §4, §8, §9, §11/§11.1; T-16 `04` cites §3.6, §11, §16.1; T-17 `04` cites §9.1, §10.2, §11 — **3–9 sections of 12–20** | Reuse audit, risk analysis, autonomous-decision log, round changelogs, the evidence-budget essay (`_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:916-988`, 73 lines, cited by no downstream document) |
| **1,2,4 → 5** (→ CR) | Acceptance-criteria list (walked line by line), design interfaces + change ledger + verification plan, dev's files-changed / design-drift / per-AC evidence | `_archived/hook-truth-verify-scope/05_CODE_REVIEW.md` cites `AC-` ×23, `FR-` ×15, design §3.1/§3.2/§3.3, §7, §8.1/§8.2, §9, §10.1, §11/§11.1 | The dev document's per-round narrative; `OQ-` drops to ×3 (T-15) and ×0 (T-16) |
| **1,2,4,5 → 6** (→ QA) | Acceptance criteria, boundary conditions, NFRs, the design's verification plan and interfaces, CR findings, the dev's claims (as falsification targets) | `AC-` ×45 in `_archived/hook-truth-derivation/06_TEST_REPORT.md`, ×32 in T-15 and T-17; T-15 `06` cites design §11.0–§11.3, §3.x, §4, §5, §6, §9, §12 | Risk analysis, reuse audit, round changelogs |
| **→ 7** (→ PM) | Verdicts, defect counts, residuals that were marked as travelling, `## Insight` lines | `_archived/hook-truth-derivation/05_CODE_REVIEW.md:207` tracks "§16.1 RES-1 named and travelling … must reach `07_DELIVERY.md`" | Everything else |

**Two findings that bound the contract:**

- `OQ-` identifiers are consumed by stage 2 (×11–16) and stage 3 (×3–10) and then collapse to ×0–5
  across stages 4–6. The **question and its candidates** are rationale; the **answer, restated as a
  binding statement**, is contract.
- Round changelogs have exactly two real consumers, and both re-derive rather than trust them:
  `_archived/hook-truth-derivation/03_GATE_REVIEW.md:9` records that §18's closure claims "were
  **not** accepted as evidence. Every one of F-1 … F-11 was re-verified against the real files",
  and `_archived/hook-truth-verify-scope/PM_LOG.md:288` records PM verifying each claim at the
  location the changelog named. Both consumers already read the routing log.

---

## 4. The central tension, and its resolution

**Too narrow** loses information a downstream stage genuinely needs, which surfaces as rollbacks
caused by missing context. **Too broad** shrinks nothing.

Resolution, from §3 rather than from first principles:

1. The union of what stages 4, 5 and 6 cited across five tasks is a **closed, small set**:
   acceptance criteria, functional requirements, boundary conditions, out-of-scope boundaries,
   interfaces and shapes, change ledger, frozen/decoy list, verification obligations, binding
   conditions, travelling residuals, verdict. Nothing outside that set was cited by any of the
   fifteen downstream-stage documents sampled.
2. Two sections are cited by stage 3 and by nothing after it (reuse audit, risk analysis) — they
   are the gate's input, so they belong to rationale, which the gate reads by default.
3. The one class where narrowing is genuinely dangerous is **byte-form specification** — T-16's
   whole subject was that exact bytes are the requirement. The boundary rule therefore carries an
   explicit row for it: verbatim bytes stay in the contract when byte-identity is itself the
   acceptance criterion, and live in exactly one place with every other mention citing it.
4. The residual narrowing risk is handled by the **trigger**, not by widening: every downstream
   stage retains a named, enumerated set of conditions under which it reads the rationale. The
   information is not deleted; its default read is.

---

## 5. In-scope behaviors

**FR-1 — Two portions, defined.** Every stage that produces a stage doc produces a **stage contract**
portion and, when non-empty, a **stage rationale** portion. The contract portion is the original
binding text addressed directly to its consumers; it is not a distilled copy of a fuller body.

**FR-2 — A total boundary rule.** One boundary rule classifies each unit of stage-doc content into
exactly one destination: `contract`, `rationale`, `routing log`, or `no home`. The rule is a
first-match-wins table with a stated default row, so every content class — including classes not
enumerated — has a defined destination. The classification unit is the smallest self-contained
block: one statement, one table row, one fenced block, one paragraph.

**FR-3 — Typed contract sections.** Each contract section declares a row or statement shape. The
contract schema contains no free-prose section. Content that fits no declared shape is not contract.

**FR-4 — Contract-only consumption.** Each downstream stage's agent contract states that its inputs
are the upstream **contract** portions, and enumerates the triggers on which it reads a rationale
portion. The gate-reviewer reads both portions by default, because auditing the reasoning is its
stated job (dimensions 3, 4 and 7 of its audit).

**FR-5 — Round history lives in the routing log.** A stage document carries no changelog, round
record, or superseded-finding section. A stage agent that completes a rework round returns the
round record to the PM, and the PM records it in the routing log. A stage document states current
state only; a statement that was true in an earlier round and is false now is corrected in place.

**FR-6 — Implementation literals have no location.** Where byte-identity is **not** an acceptance
criterion, neither portion of a stage doc carries a body destined verbatim for a shipped artifact
(source code, comment prose, or document prose). The contract carries the constraint the artifact
satisfies; the stage that owns the artifact authors the bytes. Where byte-identity **is** an
acceptance criterion, the byte-form appears once, in the contract, and every other mention cites it.

**FR-7 — Restatements have no location.** A section whose content is a summary or paraphrase of
another section of the same document is not written. This extends the standing decline of the
per-document summary header (§11 R-3).

**FR-8 — One canonical filename per stage.** Each stage's output filename is single-valued and
declared in one place. Every agent contract, skill, and template that names a stage-doc filename
names the same one.

**FR-9 — Portion boundary is declared in the document.** A stage document declares which portion it
is and where its counterpart lives, so a reader that opens one file knows the other exists.

**FR-10 — The change is demonstrated.** The task produces a reconstruction of one archived task
folder under the new structure, with the before/after line counts of what each downstream stage
must read.

**FR-11 — Retired-surface provenance is enumerated.** Every sentence in a shipped agent contract,
skill, rule fragment, or template that names a stage-doc section or filename this task retires or
renames is enumerated in the change ledger.

---

## 6. Out of scope

1. Removing, merging, or reordering pipeline stages.
2. Relaxing any gate, including the gate-review stage and `verify_all`.
3. Adding or removing any `verify_all` check — the count stays 32.
4. Parallelising stages.
5. A per-document summary header of any kind (declined; §11 R-3).
6. Editing archived task folders under `docs/features/_archived/` — they are frozen history. The
   FR-10 reconstruction is written as a new artifact inside this task's own folder.
7. The insight-harvester wrapped-bullet truncation defect (T-20).
8. Changing the numeric caps in the documentation-size policy.
9. `docs/proposals/frontier-gaps-2026-07.md` — not a requirement source, not read, not edited.

---

## 7. Boundary conditions

**BC-1 — Totality.** The boundary rule assigns a destination to every content unit. The final row
is a default (`otherwise → rationale`) reachable by any unit no earlier row matches.

**BC-2 — Precedence.** Rows are evaluated top to bottom, first match wins, and the rule states this.
A unit that is simultaneously a binding statement and a round record classifies as contract —
current state — with the fact of the change going to the routing log.

**BC-3 — Empty rationale.** A stage whose work produced no reasoning worth recording writes no
rationale artifact. Absence of a rationale portion is a valid state, not a missing input.

**BC-4 — Empty contract.** A stage that produces no binding output for any successor still writes a
contract portion carrying at minimum its verdict.

**BC-5 — Missing counterpart.** A downstream stage that finds a contract portion absent reports
`BLOCKED ON UPSTREAM`. A downstream stage that finds a **rationale** portion absent proceeds — the
rationale is a soft dependency, never a precondition.

**BC-6 — Trigger fires but rationale is absent.** The stage records that it reached for the
rationale and found none, and proceeds; it does not block and does not fabricate.

**BC-7 — Archive.** `.harness/scripts/archive-task` moves the whole task directory
(`archive-task.sh:111`, `mv "$task_dir"`) and reads exactly one filename, `07_DELIVERY.md`
(`archive-task.sh:45`). Additional per-stage files are therefore archive-safe without changing the
archiver.

**BC-8 — Verification gate neutrality.** `verify_all`'s `I.*` group measures no file under
`docs/features/` (`verify_all.sh:487-538` covers only `SUPERVISION_REPORT.md`; `:603` exempts the
whole `docs/features/` subtree from `I.6`). New files in a task folder change no check result.

**BC-9 — Agent-file size ceiling.** Every agent definition stays at or under 300 lines. Current
occupancy: `pm-orchestrator` 250, `supervisor` 285, `solution-architect` 144, `code-reviewer` 139,
`qa-tester` 132, `developer` 103, `gate-reviewer` 88, `requirement-analyst` 77. A change that would
exceed the ceiling condenses existing text rather than appending.

**BC-10 — Rule-fragment ceiling.** Every rule fragment stays at or under 200 lines. `verify_all`
exits non-zero on any WARN, so a breach fails the release gate.

**BC-11 — Routing-log growth.** Absorbing round history raises routing-log volume. The routing log
stays at or under its 500-line cap using the existing PM-owned compaction pattern; no new cap and
no new mechanism is introduced.

**BC-12 — Modes.** `plan` mode produces the same contract/rationale shape as `full`. `explore` mode
produces a contract portion only. `goal` mode's iterative stage-4/6 loop produces one contract per
iteration and records iteration history in the routing log.

**BC-13 — Resumption.** A `plan`-mode task resumed weeks later by `/harness` starts the developer
from contract portions alone; the contract is self-sufficient for that hand-off.

**BC-14 — In-flight tasks.** Tasks whose folders already exist under the old single-document shape
are readable by the updated agent contracts: a stage that finds no separate contract portion treats
the whole existing document as the contract.

---

## 8. Acceptance criteria

Each criterion is labelled **[S] structural** (the unwanted output has no location) or
**[B] behavioural** (an agent's stated behaviour changed).

**AC-1 [S] — The boundary rule is total and deterministic.** The rule enumerates content classes
with a first-match-wins precedence statement and a terminal default row. Verification: a
classification probe of at least 20 content units drawn from the five archived folders — including
at least three units belonging to no enumerated class — yields exactly one destination per unit,
and two independent classifications of the same probe set agree on every unit.

**AC-2 [S] — The contract schema admits no blob.** Every contract section declares a row or
statement shape, and no section's shape is free prose. Verification: the 115-line pre-written
implementation block at
`_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:126-240` is classified under the new rule
and lands on `no home`; the reconstruction (AC-9) shows the constraint statement that replaces it.

**AC-3 [S] — No changelog section exists.** The stage-doc schema for every stage contains no
changelog, round-record, or superseded-finding section, and the routing log's contract states that
round and rollback history is recorded there. Verification: the T-15 and T-16 round changelogs
(`_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:1053-1152`;
`_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md:1281-1657`) each classify to `routing log`
under AC-1's probe.

**AC-4 [B] — Every downstream stage consumes contracts.** Each of the agent contracts for stages 2,
3, 4, 5, 6 and 7 names its inputs as contract portions and lists its rationale triggers by name.
Verification: read each agent's input list; a stage whose input list still names a whole stage
document without qualification fails this criterion.

**AC-5 [B] — The gate keeps its full view.** The gate-reviewer's contract reads both portions of
stages 1 and 2 by default, and its 8 audit dimensions are unchanged in number and in wording of
their questions.

**AC-6 [S] — No stage removed, no gate relaxed.** The pipeline has 7 stages, the same verdict
vocabulary, the same rollback routing table, and `verify_all` reports 32 checks with 0 WARN and
0 FAIL.

**AC-7 [S] — One filename per stage.** Exactly one filename is declared for each stage, and every
shipped agent contract, skill, rule fragment, and template that names a stage-doc filename names
that one. Verification: a repo-wide sweep for stage-4 filename tokens outside
`docs/features/_archived/` returns a single distinct name.

**AC-8 [S] — Provenance is enumerated.** Every sentence in a shipped surface that names a retired
or renamed stage-doc section or filename appears in the change ledger. Verification: a post-change
sweep for the retired tokens outside `docs/features/_archived/` returns zero hits not present in
the ledger.

**AC-9 [B] — Demonstrated reduction.** The task publishes a reconstruction of one archived task
folder under the new structure, and reports, for stages 4, 5 and 6, the lines each must read before
and after. The reduction for stage 4 on the chosen folder is **at least 30%**. Baseline figures come
from §2.3. Verification: the reconstruction lists each moved or dropped section with its measured
line span, and the arithmetic reconciles with §2.2's totals.

**AC-10 [S] — Size ceilings hold.** Every agent definition is at or under 300 lines, every rule
fragment at or under 200 lines, and this document and every other stage doc of this task is at or
under 500 lines.

**AC-11 [S] — Single-sourced boundary rule.** The boundary rule's normative text exists in exactly
one location; every other surface references it by name and restates no part of it. Verification: a
sweep for the rule's distinctive tokens returns one authoring site and N pointer sites.

**AC-12 [B] — Degradation.** With a rationale portion deleted, a downstream stage completes its work
and records the absence (BC-5, BC-6). With a contract portion deleted, the same stage returns
`BLOCKED ON UPSTREAM`.

**AC-13 [S] — Backwards compatibility.** An existing task folder in the pre-change single-document
shape is consumed without error by the updated agent contracts (BC-14).

**AC-14 [S] — Cross-shell and template parity.** If the change touches any script or template pair,
both members change in lockstep. If the change creates a PowerShell surface, the standing operator
PowerShell list — currently **sixteen** numbered items, four marked security — gains the new items;
the existing sixteen are not reconciled or renumbered.

---

## 9. Non-functional requirements

**NFR-1 — Context budget.** The intended effect is measured in lines a stage must ingest, per
§2.3's method. AC-9's ≥30% for stage 4 is the binding figure.

**NFR-2 — No new resident mechanism.** The change adds no hook, no script, no gate check, and no
per-run cost. Enforcement comes from the artifact split, the typed schema, and the dispatch input
lists.

**NFR-3 — Distribution reach.** The change reaches both this repo's dogfood pipeline and every
generated project. The framework agents are plugin-native and edited directly; rule fragments are
bespoke per repo and are not synchronised by `sync-self`; skills and templates have sync steps.
Any surface chosen to host normative text is reachable by a generated project.

**NFR-4 — Freeze.** No `verify_all` check, no version stamp, and no count claim changes as a side
effect.

---

## 10. Related tasks

- **T-05 `durable-brief`** (`docs/features/_archived/durable-brief/01_REQUIREMENT_ANALYSIS.md`) —
  established the forward-only / backward-evidence boundary and the single-source discipline for a
  cross-agent rule. This task's boundary rule inherits both.
- **T-15 `hook-truth-verify-scope`** — authored the body/appendix evidence split (§2.5) and named
  the round-changelog accretion problem as its own future task.
- **T-16 `hook-truth-derivation`** — the largest design; established that retiring a documented
  surface leaves provenance sentences no gate reads (FR-11, AC-8).
- **T-17 `guard-cmd-chain`** — its gate ruled the round changelog dead weight and verified that no
  gate check measures stage-doc size (BC-8).
- **T-09 `rejected-decisions-memory`** — established that a rule earns its keep only when its
  read-trigger sits where the decision happens; FR-4's triggers follow that.
- **T-16 (v0.27) `i18n-special-drift-guard`** — the standing "eliminate by design rather than add a
  guard" precedent this task's framing follows.

---

## 11. Rejected alternatives

**R-1 — Three prohibitions ("do not pre-write literals", "move changelogs out", "do not invent
constraints").** Rejected before dispatch. A prohibition depends on compliance and has nothing
enforcing it; a stage could emit the same 110 KB document without violating any structure. Recorded
here so the design does not regress to it.

**R-2 — A per-document summary header.** Declined (standing). A summary is a copy of the body that
must be hand-kept in sync with it — the exact duplication class the last five tasks eliminated. The
corollary is binding on this task: the contract is the **original, addressed directly**, never a
distilled copy of a fuller body.

**R-3 — A new `verify_all` check (an `I.8` stage-doc size or schema guard).** Out of scope by the
count freeze (§6.3), and rejected on principle: this repo's standing line is that a better design
beats another guard. Recorded as a candidate follow-up pool row, not adopted here.

**R-4 — A single file with an in-document delimiter between the two portions.** Rejected: an agent
that opens the file reads both portions, so the ingest cost is unchanged and the enforcement is
back to compliance. The split has to be at the artifact boundary to change what a dispatch delivers.

**R-5 — Deleting round history.** Rejected: it has two real consumers (the gate on a re-review, and
the PM), evidenced in §3. It moves to the routing log, which both already read.

**R-6 — Retroactively restructuring the archived folders.** Rejected: archived documents are frozen
history and rewriting them destroys the evidence this analysis rests on.

---

## 12. Open questions (deferred-human mode — each carries a binding `Recommended:` answer)

**OQ-1 — Artifact shape of the rationale portion.**
(a) One sibling file per stage, created only when non-empty. (b) One per-task rationale file shared
by all stages. (c) An appendix inside the same file below a delimiter.
**Recommended: (a).** (c) is R-4. (b) creates a multi-writer file across seven agents, which is the
concurrency hazard the routing log's single-writer rule already avoids. (a) keeps single-writer
ownership, keeps `BC-3` cheap (no file when there is nothing to say), and is archive-safe by BC-7.

**OQ-2 — Where the boundary rule's normative text lives.**
(a) A new rule fragment. (b) Inside one framework agent, referenced by the others. (c) Split between
a rule fragment (dogfood) and an agent (distributed).
**Recommended: (b), hosted in the agent whose stage authors the most classified content, with all
other agents referencing it by name and restating none of it.** Rationale: rule fragments are not
distributed to generated projects (`sync-self` excludes `.harness/rules/`), so (a) fails NFR-3 and
(c) creates the two-copy drift the T-05 insight warns about. `pm-orchestrator` has only 50 spare
lines against the 300-line ceiling, so the architect selects a host with the headroom.

**OQ-3 — Whether the gate reads rationale for stages beyond 1 and 2.**
(a) Gate reads rationale of 1 and 2 only. (b) Gate reads all rationale.
**Recommended: (a).** The gate runs before stage 4; stages 4–6 have produced nothing at that point.

**OQ-4 — Rationale triggers for the developer.**
(a) Only on a stated deviation (`DESIGN DRIFT`) or a contract ambiguity. (b) Also before starting.
**Recommended: (a).** §3 shows the developer cited 3–9 of 12–20 design sections and none of the
rationale-class ones across three tasks; a default read reintroduces the full ingest.

**OQ-5 — The canonical stage-4 filename.**
(a) `04_DEVELOPMENT.md`. (b) `04_IMPLEMENTATION.md`.
**Recommended: (a).** Six shipped agent contracts and the PM stage table already name it; (b)
appears in two archived folders only, and archived folders are frozen (§6.6).

**OQ-6 — Which archived folder the AC-9 reconstruction uses.**
(a) T-15 `hook-truth-verify-scope`. (b) T-16 `hook-truth-derivation`. (c) T-17 `guard-cmd-chain`.
**Recommended: (a).** It is the folder the operator inspected, it carries all three defect classes
in one document, and §2.4 already measures its section spans, so the reconstruction's arithmetic is
checkable against numbers produced before the design existed.

**OQ-7 — Routing-log growth from absorbed round history.**
(a) Reuse the existing PM-owned compaction pattern unchanged. (b) Raise the routing-log cap.
(c) Add a separate round-history file.
**Recommended: (a).** (b) trades one bloat surface for another; (c) adds a file whose only consumer
already reads the routing log.

**OQ-8 — Whether contract portions of stages 5 and 6 are worth splitting.**
(a) Split all seven stages uniformly. (b) Split only stages 1–4, since stages 5–6 have at most one
downstream consumer.
**Recommended: (a).** §2.2 shows stage 6 is the single largest document in three of five tasks
(1289, 965, 885 lines) and stage 5 reaches 660; stage 7 and the archive consume both. Uniformity
also keeps the boundary rule single-valued, which AC-1's totality requirement depends on.

**OQ-9 — Whether this task edits the documentation-size rule fragment.**
(a) Yes — the fragment gains the contract/rationale distinction and the round-history destination.
(b) No — the agents carry it entirely.
**Recommended: (a) for this repo's dogfood fragment, with the normative text single-sourced per
OQ-2 and the fragment referencing it.** The fragment is the surface that already loads at the
"am I about to paste this" decision point (T-09's read-trigger insight), and it stays at or under
200 lines (BC-10).

---

## 13. Verdict

**READY.**

Every ambiguity in §12 carries a binding `Recommended:` answer under deferred-human mode; none of
them requires a human decision to specify the work. No question in §12 is a red line under
`.harness/rules/25-decision-policy.md`: no safety-critical action, no irreversible change, no
capability gap. The architect adopts each `Recommended:` answer unless it overrides with a stated
reason.
