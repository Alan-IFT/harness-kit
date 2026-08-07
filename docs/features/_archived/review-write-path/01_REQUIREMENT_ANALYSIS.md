# 01 — Requirement Analysis: review-write-path (T-23)

> Contract portion. Mode: **full** · deferred-human: defer, do not ask ·
> Rationale sibling: `01_RATIONALE.md` (option arguments, open-question candidate answers,
> the argument selecting among them).
> Origin: **EP-001** in `docs/features/_supervision/entropy-2026-08-02.md` (sweep-authored input,
> read-only). Primary deliverable: **one consistent arrangement** for how the stage-3 and stage-5
> documents come to exist, stated in every contract that implements it.

---

## 0. Established facts (backward-looking evidence)

Path-and-line citations in this section are **evidence of what was found**, per the analyst's
EVIDENCE-citation exemption. No requirement statement below §0 anchors to a path or a line.

### 0.1 The defect as it stands

| id | Established fact | Evidence |
|---|---|---|
| E-1 | Both review roles declare `tools: Read, Glob, Grep` — no `Write`, no `Edit`. | `agents/gate-reviewer.md:4`, `agents/code-reviewer.md:4` |
| E-2 | Both `## What you produce` sections open by naming a stage document as the role's output. | `agents/gate-reviewer.md:14`, `agents/code-reviewer.md:14` |
| E-3 | Both instruct the role to correct that document **in place** on a re-review round. | `agents/gate-reviewer.md:29-30`, `agents/code-reviewer.md:31-32` |
| E-4 | Both describe a `0N_RATIONALE.md` sibling "written only when non-empty". | `agents/gate-reviewer.md:32-33`, `agents/code-reviewer.md:36-39` |
| E-5 | The reconciliation exists in exactly one of the three contracts, as a parenthetical, and is conditioned on a fact (`if you have no Write tool`) that the same file's own frontmatter already fixes. | `agents/gate-reviewer.md:36-37` vs `:4` |
| E-6 | The code reviewer's contract carries no equivalent clause anywhere. | whole-file read of `agents/code-reviewer.md`; no match |
| E-7 | The orchestrator's stage table attributes both documents to the two reviewers, and its contract states a persist duty only for the round record into `PM_LOG.md`. | `agents/pm-orchestrator.md:30,32` vs `:84-88` |
| E-8 | The code reviewer's Hard rule 2 — "You do not edit any document. Read-only." — contradicts its own `## What you produce` instruction to correct that document in place. This contradiction is internal to one file and independent of tooling. | `agents/code-reviewer.md:88` vs `:31-32` |

### 0.2 It has already fired

| id | Established fact | Evidence |
|---|---|---|
| E-9 | During T-22 the orchestrator transcribed three documents on the reviewers' behalf and recorded the reason. | `docs/features/_archived/stage-model-tiering/PM_LOG.md:130-135,339`; provenance note at `…/03_GATE_REVIEW.md:3-9` |
| E-10 | The transcribed gate document carries **no** `> Contract portion.` opening line, which its own schema mandates. All four documents written by their nominal authors carry one (`01:3`, `02:3`, `04:3`, `06:1`); the transcribed code review carries a shortened variant (`05:3`). | grep for `Contract portion` across `docs/features/_archived/stage-model-tiering/` |
| E-11 | The transcribed gate document carries a `## Round 2 — re-gate` section — the exact section shape the orchestrator's own contract instructs it to route back to the authoring agent, and which the boundary rule sends to `PM_LOG.md`. | `…/03_GATE_REVIEW.md:216`; `agents/pm-orchestrator.md:84-88`; `.harness/rules/70-doc-size.md:109-112` |
| E-12 | A **distributed** template asserts the reviewers "write" these documents, so the false attribution reaches every generated project. | `skills/harness-init/templates/common/AI-GUIDE.md.tmpl:51,53` |
| E-13 | Downstream consumers treat the file's presence as the normal post-stage state, and a resume path keys on its absence. | `.harness/rules/60-tool-handoff.md:32-33,125-127`; `skills/harness/SKILL.md:36,38`; `skills/harness-plan/SKILL.md:32` |
| E-14 | Recorded as a cross-task truth, latent for as long as both contracts name an output they cannot produce. | `.harness/insight-index.md:54-61` |

### 0.3 Constraints measured at dispatch

| id | Established fact | Evidence |
|---|---|---|
| E-15 | Live line counts against the 300-line agent cap: `pm-orchestrator` **294**, `supervisor` **287**, `code-reviewer` **167**, `gate-reviewer` **114**. | full reads of each file; cap at `.harness/rules/70-doc-size.md:27`, enforced by `verify_all.sh:447` (I.3) |
| E-16 | A WARN is not status-neutral — `verify_all` exits 1 on `warns > 0`, so the cap is a hard release gate. | `.harness/insight-index.md:14` |
| E-17 | No verification check reads an agent's `tools:` frontmatter. D.1 checks presence of the seven agent files; I.3 checks line count. Changing a tool grant is gated by nothing today. | `verify_all.sh:71-77`, `:447` |
| E-18 | A write-holding observer role already ships: the supervisor declares `Read, Write, Glob, Grep`, is described as "observer-only … writes exactly one report file", and asserts that editing upstream docs is "forbidden by tools whitelist anyway" — an assertion its own tool list does not carry, since `Write` overwrites an existing path. | `agents/supervisor.md:4,9,283` |
| E-19 | Standing decline: prefer a design that makes the failure impossible over a patch that forbids it ("a prohibition depends on compliance and has nothing enforcing it"). | `.harness/rejected-decisions.md:137-146` |
| E-20 | Standing decline: an agent contract is not a home for normative text **other** agents must read, because plugin-native agents have no project-relative path. | `.harness/rejected-decisions.md:148-160` |
| E-21 | Standing decline: `/harness-upgrade` does not refresh `.harness/rules/*` fragments, so an installed project can lag a rule-fragment change indefinitely; the accepted mitigation is a per-agent degradation clause. | `.harness/rejected-decisions.md:162-174` |
| E-22 | Retiring or relocating a duplicated statement is not finished when the primary site is rewired — prose citations are a lockstep surface and fail silently, because no gate reads prose. | `.harness/insight-index.md:26` |

### 0.4 One fact that constrains the design space without collapsing it

**A caller never loads the callee's contract.** A stage agent's contract is loaded into that agent's
own context when it is dispatched; the dispatching role does not read it. Therefore an obligation
discharged by role X cannot be learned by X from a document only role Y reads. This is why E-5 —
the single existing reconciliation, sited in the *callee's* file — does not reach the role that
performs the write, and it is the mechanism behind E-10 and E-11: the transcriber was never told
what the schema required.

This fact narrows *where* the duty can live. It does not decide *whether* a duty exists — under an
arrangement in which the reviewers write their own documents, no transcription duty exists at all.

---

## 1. Goal

The three contracts that implement stage-3 and stage-5 document production describe **one**
arrangement for how those documents come to exist, the role that performs each write possesses the
capability to perform it, and the arrangement is stated in a document that role reads at the time it
acts.

---

## 2. In-scope behaviors

Each statement below is binding and capability-neutral: it is satisfiable by granting the review
roles a write capability, by naming a transcription duty in the orchestrator's contract, or by any
third arrangement that meets all of them.

**R-1 · One named writer per stage.** For each of stage 3 and stage 5 the arrangement names exactly
one role as the **writer** — the role that causes the bytes to exist at the declared path — and
exactly one role as the **author** — the role that produces the document's content. Writer and
author are the same role, or two named roles.

**R-2 · The writer is told, in a document the writer reads.** The writer's obligation is stated in
a document that role loads at the time it performs the write. A statement of the writer's duty
sited only in another role's contract does not satisfy this.

**R-3 · The author's contract names the arrangement.** The author's `## What you produce` section
does not name an act that the arrangement assigns to a different role without naming that role.

**R-4 · Transcription is specified when writer ≠ author.** Where writer and author differ, the
arrangement states: what the author returns (the complete document body — the contract portion,
plus the rationale portion when it is non-empty), that the writer transcribes it verbatim, and that
the writer authors no part of it.

**R-5 · Re-review rounds have a named owner.** The arrangement names the role that corrects an
existing stage document in place on round N ≥ 2, and that role's capability covers modifying an
existing file at that path.

**R-6 · The rationale sibling has a named owner.** The arrangement names the role that creates
`03_RATIONALE.md` / `05_RATIONALE.md` when the rationale portion is non-empty, and states that the
file's absence means none was written.

**R-7 · The read-only invariant is stated extensionally.** Every statement in the three contracts
that asserts a read-only property of a review role names the set of objects that role does not
modify — upstream stage documents, the source code and tests under review, project configuration —
rather than resting on the tool declaration alone.

**R-8 · The code reviewer's contract is internally consistent.** Its hard rules and its
`## What you produce` section give the same answer to: does the code reviewer modify its own stage
document?

**R-9 · Every authorship attribution agrees.** Every statement in this repository and in the
distributed templates that attributes an authoring or writing verb for the stage-3 or stage-5
document to a role agrees with the arrangement. The audit set is the one enumerated in §0.2 and
§0.3, re-derived by the implementing stage rather than inherited from this list.

**R-10 · Schema conformance is independent of who writes.** The produced stage document carries its
declared opening line and its declared sections, and carries no round-record, changelog or
superseded-finding section, whichever role performs the write.

**R-11 · The check count is unchanged.** No verification check is added, removed, or renumbered.
The count stays 32.

**R-12 · No second copy of the framework agents.** The change edits the plugin-native top-level
agent contracts directly. No `.harness/agents/` copy of a framework agent is created or proposed.

---

## 3. Out-of-scope

1. **EP-002** (the standing operator-obligation ledger squatting in the baseline pin file) and
   **EP-003** (the check count closed by a hand-enumerated allowlist) — separate queued rows.
2. Changing which stages exist, which stages run in which mode, or what any review stage is asked to
   judge: the 8 gate dimensions, the 6 review dimensions, the two review axes, the severity levels,
   and every verdict vocabulary stay as they are.
3. `docs/proposals/*.md` (operator-authored) and `docs/features/_supervision/*.md` (sweep-authored).
   The sweep artifact is input; neither is edited.
4. Retrofitting the T-22 archived documents. E-10 and E-11 are evidence, not a repair target.
5. The tool grants of the requirement-analyst, solution-architect, developer, qa-tester and
   pm-orchestrator roles.
6. The supervisor's analogous claim recorded as E-18. It is a third instance of the same reasoning
   pattern in a non-pipeline role; it is recorded here and dispositioned in OQ-4, not repaired by
   default.
7. Any new verification check, gate, script, or state file.
8. `/harness-upgrade` gaining a rule-fragment refresh path (declined, E-21).

---

## 4. Boundary conditions

**B-1 · Empty rationale.** The author has nothing for the rationale portion: no rationale sibling
file exists, and its absence is a normal state for every downstream reader.

**B-2 · Round N ≥ 2.** The stage document is corrected in place to current state. The round record
— `round N · what changed · why · which finding id` — reaches `PM_LOG.md` and does not reach the
stage document. This holds under every arrangement, including one where the writer is not the
author.

**B-3 · Blocked verdicts.** A verdict drawn from a review role's declared vocabulary — including
every `BLOCKED ON …` form in that vocabulary — is written into the stage document. The
`BLOCKED ON MODE UNCLEAR` stop, which fires before the review runs, is recorded in `PM_LOG.md`
and produces no stage document.

**B-4 · Oversized or truncated return.** The existing 500-line per-stage-document cap is the size
contract for a returned body. A return that does not reach the writer intact is a failure the
arrangement names and surfaces; it is never resolved by writing a partial document silently.

**B-5 · Plan mode.** Stage 3 is the terminal stage and its verdict is the user's deliverable. The
document exists at the declared path when the pipeline stops there.

**B-6 · A write capability is not path-scoped.** In this runtime a `Write` grant creates or
overwrites any path the role names; no tool grant confines a role to one file. Any confinement the
arrangement claims is therefore a prose statement, and the arrangement states it as one rather than
attributing it to the tool list. E-18 is the live instance of that mis-attribution.

**B-7 · An installed project on an older rule set.** The arrangement does not require a
`.harness/rules/*` section that a project generated before this change lacks; where it references
one, the referencing contract carries a degradation clause of the shape both reviewer contracts
already use ("apply the schema as written and proceed; do not block").

**B-8 · Non-Claude tools.** The framework agents are plugin-native and are not first-class outside
Claude Code. The arrangement introduces no dependency on a capability those tools lack that the
pipeline does not already have.

**B-9 · Line budget.** The orchestrator's contract has six lines of headroom under the 300-line cap
and the cap is a hard release gate (E-15, E-16). Lines added to a capped file are offset within
that same file; the count is measured before and after by a live run, not inferred.

**B-10 · Concurrency.** One review round for one task has one writer at one time; the pipeline runs
stages serially and partitioned development is the only parallel case, which does not touch stage 3
or stage 5. The arrangement introduces no second concurrent writer of a stage document.

**B-11 · Missing document downstream.** A stage that finds a required upstream contract portion
absent routes back to the stage that owes it. This behavior is unchanged, and the arrangement does
not make absence a normal outcome of a completed review stage.

**B-12 · Null / empty content.** A review that produces zero findings still produces the document,
with each declared section present and an explicit clean statement where the schema requires one.

---

## 5. Acceptance criteria

| id | Criterion | Class | Verification |
|---|---|---|---|
| AC-1 | Reading one review role's contract end to end yields the name of the role that writes that stage's document, with no clause conditioned on a fact stated elsewhere in the same file. | contract-readable | Read each reviewer contract; record the answering sentence. |
| AC-2 | Reading the orchestrator's contract end to end yields the orchestrator's obligation for stages 3 and 5 — either the transcription duty, or the statement that those stages write their own documents. | contract-readable | Read the orchestrator contract; record the answering sentence. |
| AC-3 | A three-way walk of the reviewer, reviewer and orchestrator contracts produces a role × act table over {create the document, correct it in place, create the rationale sibling, record the round} with exactly one owner per cell and no empty cell and no contradicted cell. | contract-consistency | Build the table from the three files; publish it. |
| AC-4 | The code reviewer's hard rules and its `## What you produce` section return the same answer to "does this role modify its own stage document". | contract-consistency | Read both sections; state the shared answer. |
| AC-5 | Every in-repo and distributed statement attributing an authoring or writing verb for the stage-3 or stage-5 document agrees with the arrangement. The audit set is re-derived by a repository-wide search for the two filenames plus the two role names, not inherited from §0. | lockstep | Publish the derived site list, each site's disposition, and the search that produced it. |
| AC-6 | `.harness/scripts/verify_all` reports PASS 32 / WARN 0 / FAIL 0 and exits 0, with the count read from the run. | gate | Run it; quote the tally line. |
| AC-7 | Every capped file the change touches is at or under its cap, with the count measured before and after by a live line count. The orchestrator's contract is ≤ 300 lines. | gate | `wc -l` before and after; publish both. |
| AC-8 | **Adversarial (QA-owned).** A review stage runs live under the reconciled contracts and the resulting file at the declared path carries (a) the declared opening line, (b) every declared section heading, and (c) no round-record, changelog, or superseded-finding section. Measured on the produced file, never on the contract text. | behavioral | Dispatch a real review stage on a real task; inspect the produced file. Falsifier of record: under the pre-change arrangement this test fails on (a) and on (c) — E-10 and E-11 are the captured failures. |
| AC-9 | **Adversarial (QA-owned).** A second round on the same task produces a document corrected in place — the same path, no appended round section — and a round record in `PM_LOG.md`. | behavioral | Drive a second round; diff the document across rounds; read `PM_LOG.md`. |
| AC-10 | **Adversarial (QA-owned).** Deleting the single sentence that carries the write duty makes the arrangement underspecified: a reader of the mutated contract set cannot answer AC-1 or AC-2. The sentence is load-bearing, not decorative. | mutation | Mutate a working copy; re-run the AC-1/AC-2 reads; record the unanswered question by name. |
| AC-11 | The verification check count is 32 before and 32 after, and no check identifier changed. | gate | Compare the check identifiers emitted by the run before and after. |
| AC-12 | No `.ps1` surface is created. If one is created, the standing operator-obligation list grows by appended items only, its existing numbering untouched, and its stated total moves from 25 to 25 + n. | operator | Inspect the change set for `.ps1` paths; if none, state that the list stays at 25 (17 numbered plus 8 un-numbered) unchanged. |

AC-8, AC-9 and AC-10 are the section the QA stage renders under `## Adversarial tests`. AC-8 is the
criterion that distinguishes "the three contracts now read consistently" from "the arrangement holds
when a review stage runs" — the former is AC-3 and is satisfiable by prose alone; only AC-8 fails if
the arrangement is correct on paper and absent in behavior.

---

## 6. Non-functional requirements

- **Compatibility (material).** A project generated before this change continues to run its pipeline
  without a rule-fragment refresh (E-21, B-7). Any statement placed in a rule fragment carries a
  degradation clause in the contract that depends on it.
- **Distributed-surface flatness (material).** No new file on any distributed surface, no new check,
  no new script, no new state file. The repo's precedent is to close a defect class without inflating
  the check count.
- **Ingest cost (material).** The change does not increase what any stage reads at dispatch time
  beyond the file that stage already loads — the property T-18 bought and this task does not spend.
- **Cross-shell parity (conditional).** Material only if the change creates a `.ps1` surface; see
  AC-12. PowerShell is not executable on this host, so any such surface ships green-by-symmetry and
  is added to the standing operator list without renumbering it.

---

## 7. Related tasks

- **T-22 `stage-model-tiering`** — `docs/features/_archived/stage-model-tiering/`. The live firing of
  this defect (E-9 … E-11) and the source of the insight-index entry that names it.
- **T-18 `stage-contract-split`** — `docs/features/_archived/stage-contract-split/`. Authored the
  `## What you produce` schemas, the in-place-correction rule and the rationale sibling — the three
  instructions the review roles cannot execute. Also the origin of the declines at E-20 and E-21.
- **T-19 `agents-cutover`** — `docs/features/_archived/agents-cutover/`. Made the framework agents
  plugin-native; the reason R-12 forbids a second copy and the reason E-20's decline exists.
- **T-11a `entropy-watch`** — `docs/features/_archived/entropy-watch/`. Added the supervisor's scoped
  read-only exception; the precedent at E-18 for a role that holds `Write` while declaring an
  observer invariant in prose.
- **T-05 `durable-brief`** — `docs/features/_archived/durable-brief/`. The precedent for stating a
  discipline once in the owning contract and referencing it by name from the orchestrator — the
  reference-don't-restate pattern, and the source of the EVIDENCE-citation exemption §0 uses.
- **T-16 `hook-truth-derivation`** — `docs/features/hook-truth-derivation/`. The source of E-22: four
  prose citations of a retired symbol survived the rewiring because no gate reads prose. R-9 and AC-5
  exist because of it.
- **T-15 `hook-truth-verify-scope`** — `docs/features/_archived/hook-truth-verify-scope/`. The
  ASSESS-FIRST corollary: a sibling row that makes a failure *repairable* does not make the
  arrangement correct. Relevant to any resolution that leaves the duty implicit and relies on the
  orchestrator noticing.

---

## 8. Open questions for user

Candidate answers and the argument selecting among them are in `01_RATIONALE.md` §R1–§R5. Each
question carries a `Recommended:` answer, which the architect adopts unless it overrides it with
evidence. **None of the five blocks stage 2** — every one has a recommended resolution that is
actionable as written, and each names what a human ruling would change.

1. **OQ-1 · Which direction reconciles the arrangement: grant the two review roles a write
   capability, or name the transcription duty in the orchestrator's contract, or a third arrangement
   that changes no capability?** The requirement does not force one — R-1 … R-10 are satisfiable by
   all three. Two facts bear decisively and point in opposite directions: no tool grant in this
   runtime is path-scoped (B-6), so a write grant converts the *only* structurally-enforced guarantee
   of reviewer independence into prose; and this repo's standing direction prefers a design that makes
   a failure impossible over one that forbids it (E-19), which favors a grant.
   **Recommended:** preserve the tool-enforced read-only invariant and site the write duty in the
   contract of the role that performs the write — direction 2, with direction 3's discipline applied
   to the two reviewer contracts so all three describe the same arrangement rather than one describing
   it parenthetically. The decisive leg is B-6 read together with §0.4: a write grant buys structural
   enforcement of the *duty* only by surrendering structural enforcement of the *invariant*, and the
   invariant is what the two stages exist for. The architect overrides this if it establishes that the
   invariant's protected set is exactly {upstream stage documents, code and tests under review} and
   that a prose statement of that set is no weaker than today's tool-list statement — E-18 is the
   evidence that this repo already relies on exactly such a prose confinement elsewhere.

2. **OQ-2 · Does the transcription hand-off need a size or truncation clause of its own?**
   **Recommended:** no new mechanism — the existing 500-line per-stage-document cap is the size
   contract (B-4), and a return that does not arrive intact surfaces as the missing-contract-portion
   route-back that already exists (B-11). A human ruling is needed only if truncation is observed in
   practice, which no evidence in this repository records.

3. **OQ-3 · Where does the single statement of the arrangement live so that an installed project on
   an older rule set still gets it?**
   **Recommended:** inside the plugin-native agent contracts themselves. They update with the plugin,
   each of the three roles loads its own contract at dispatch, and under the recommended resolution of
   OQ-1 no role needs to read another role's contract — so E-20's decline does not apply. A rule
   fragment would reach installed projects only through a refresh path that was declined (E-21).

4. **OQ-4 · Is the supervisor's identical mis-attribution (E-18) repaired in this task?**
   **Recommended:** no — recorded as a residual for its own queued row. The behavioral intent names
   the two review stages, the supervisor is not a pipeline stage, and its contract is at 287 of 300
   lines. If the chosen direction produces a reusable formulation of the read-only invariant under
   R-7, the residual records that formulation by name so the follow-up row is a one-line application
   rather than a re-derivation.

5. **OQ-5 · When a review role returns a blocked verdict, does a stage document exist?**
   **Recommended:** yes for every verdict in the role's declared vocabulary, including the
   `BLOCKED ON …` forms — the verdict is the stage's product and the record must survive the round.
   No for `BLOCKED ON MODE UNCLEAR`, which fires before the review runs and is a routing event, not a
   review result (B-3). A human ruling changes this only if the operator wants a blocked gate to leave
   no artifact, which contradicts the resume path at E-13.

---

## 9. Verdict

**READY.**

Five open questions are recorded; each carries a `Recommended:` answer that is actionable as
written, and none blocks stage 2. The design tension named in OQ-1 is deliberately left open at the
requirement level: R-1 … R-10 are stated so that a write grant, an orchestrator duty, or a
capability-neutral third arrangement can each satisfy them, and §0 carries the evidence the
architect needs to choose. The one thing the requirement does force is §0.4 — the writer must learn
its duty from a document the writer reads — and that constraint is neutral between the directions.
