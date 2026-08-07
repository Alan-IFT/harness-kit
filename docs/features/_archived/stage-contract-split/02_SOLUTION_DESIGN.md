# 02 — Solution Design · T-18 `stage-contract-split`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

- **Mode**: `full` (dispatched from a `/harness-stream` drain, deferred-human mode)
- **Upstream**: `01_REQUIREMENT_ANALYSIS.md` **READY** (481L) · `03` **APPROVED WITH CONDITIONS**
  (C-1…C-12 bind) · `04` **READY FOR REVIEW** · `05` **APPROVED** · `06` **CHANGES REQUIRED**
  (QA-7/QA-8 MAJOR — published as travelling residuals under the operator's ruling, §13; QA-12 → developer)
- **Schema gap (boundary-rule row 5, per gate Q-9)**: this front-matter block fits no declared stage-2
  shape; "upstream `06` returned CHANGES REQUIRED" is a statement stage 4 must verify, so it is
  contract. Ledger row owed: none — T-18's own folder is not retrofitted (§14).
- **Verdict**: **READY** (§17). Round history lives in `PM_LOG.md`, not here (FR-5, on itself).

---

## 0. Premises (independently derived; upheld by gate G-1/G-2/G-3)

**P-1 — rule fragments DO reach generated projects**, via the `/harness-init` template overlay
(`skills/harness-init/templates/common/.harness/rules/`, 8 files incl. `70-doc-size.md.tmpl`), not via `sync-self` (`sync-self.sh:58-93`
maps 8 script pairs only; `AI-GUIDE.md:76` states the omission deliberately). The fragment arrives as a **hand-maintained twin**, and only
at `/harness-init` — never at `/harness-upgrade` (`skills/harness-upgrade/SKILL.md:231`); that gap is R8's residual.

**P-2 — BC-8 holds in both shells.** `I.1`–`I.5` measure `AI-GUIDE.md`, `.harness/rules/*.md`, `agents/*.md`,
`.harness/insight-index.md`, `docs/tasks.md` (`verify_all.sh:421-483`; `.ps1:410-466`); `I.7` reads one verdict + mtime under
`docs/features/` and no size or schema (`sh:485-544`); `I.6` exempts the subtree (`sh:603`). **No check in either shell measures
the size or schema of anything under `docs/features/`.** `archive-task.sh:111` moves the whole directory — BC-7 confirmed.

---

## 1. Architecture summary

Each stage's existing document (`01_REQUIREMENT_ANALYSIS.md` … `07_DELIVERY.md`) **becomes the contract portion** — same filename, every
section carrying a declared row or statement shape. Reasoning moves to a new optional sibling `0N_RATIONALE.md`, written only when non-empty;
round and rollback history moves to `PM_LOG.md`; each downstream agent's input list names the contract files and enumerates the triggers on
which it opens a rationale. Enforcement rests on three structures: **(a) the artifact boundary** — a dispatch naming `02_SOLUTION_DESIGN.md`
delivers only the contract; **(b) the typed schema plus an ordered classification unit** — a 115-line pre-written bash body, and a quoted
normative paragraph, are each **one** unit fitting no declared shape and no rationale shape, so neither has a location; **(c) the dispatch
input list**. Both bodies (b) removes are multi-line: the guarantee is structural for multi-line forms and compliance below that (§13). No
script changes, no `verify_all` check added or removed (stays 32), no new hook, no new resident cost.

---

## 2. The boundary rule (normative; single-sourced in `.harness/rules/70-doc-size.md`)

**What E1/E2 change this round — nothing else in the shipped section moves.** (1) Replace the `**Classification unit.**` paragraph at
`70-doc-size.md:45-49` with the ordered ladder + "Not units" + "Verbatim byte-form" below. (2) Replace table rows 2, 5 and 6 with the rows
below. The destination paragraph (`:35-43`), "Headings", "Precedence", rows 1/3/4/7–14, the row-4 bound (`:76-82`) and the agreement
paragraph (`:84-89`) stay byte-identical. Everything else in §2 — the row-4 note, the worked walks, BF-1 and the `01`/BC/FR pointers in the
agreement paragraph — is reviewer commentary and does **not** ship: what ships is self-contained and names no section of this document and
no gate finding (Q-8).

**Classification unit — apply in order; the first step that matches names the unit.**

1. **Declared shape.** Inside a section whose shape the authoring agent's `## What you produce`
   schema declares, the shape's own unit is the unit: one table row, one `**K-n** —` statement line,
   one `key: value` line, the `> Contract portion.` header line. Sub-parts are never classified
   separately.
2. **Fenced block.** A fenced block is one unit, fence lines included, however long.
3. **Blockquote.** An unbroken `>` run is one unit, however many sentences it contains.
4. **Table row.** Each body row of a table is one unit.
5. **List item.** Each top-level list item, together with its nested sub-items, is one unit.
6. **Sentence.** Otherwise the unit is one sentence ending at top level. **A paragraph is never a
   unit**: when its sentences reach different destinations the paragraph splits and each sentence is
   written at its own destination.

**Not units.** Markdown structure that carries no content — a heading, a blank line, a horizontal
rule, a table header row, a fence's language tag — is not classified.

**Verbatim byte-form.** A unit is *destined verbatim* when the document offers it as the characters
to be transcribed into a shipped artifact: introduced by "replace X with", "insert", "exactly" or
"verbatim", or presented as a quotation or fence of that artifact's text. A statement of **what the
artifact must satisfy** is not a byte-form, however normative — the byte-form is the transcription,
the constraint is the requirement.

**Headings.** A heading is not itself classified; it travels with the units it contains. When a
section's units split across destinations, the **section splits**: the heading is written in each
destination receiving ≥1 unit, and the rationale copy opens with a one-line pointer to the contract
copy.

**Precedence.** Rows are evaluated **top to bottom; first match wins**. Redundancy between rows is
harmless; a hole is not — row 14 is terminal and reachable by any unit.

| # | If the unit is… | Destination |
|---|---|---|
| 1 | under a heading a **shipped mechanism reads** — `## Adversarial tests` in `06_TEST_REPORT.md`, `## Insight` in `07_DELIVERY.md` | **contract**, in that exact file; heading bytes frozen |
| 2 | a unit fitting a **declared shape** of the contract schema for the stage that authors it, **and not destined verbatim for a shipped artifact** (if it is, rows 3, 4 and 9 decide it) | **contract** |
| 3 | an exact byte-form whose **character identity is itself an acceptance criterion** | **contract**, written **once**; every other mention cites it |
| 4 | **normative text a shipped artifact must carry**, where no statement of the constraint is both *strictly shorter* than the text **and** satisfiable by *more than one* artifact | **contract**, once, under `## Byte-form specification`, **with the test's result stated in the row** |
| 5 | a **binding statement** any later stage, the operator, or the release gate must satisfy, obey, verify, or not touch, that fits no declared shape (a *statement* is one sentence; a fenced block or a blockquote is never a statement) | **contract** — and the schema lacks a section: name the gap in the change ledger |
| 6 | the **answer** to a resolved question, restated as a binding statement — row 5's definition applies: one sentence, and a fenced block or a blockquote is never a statement | **contract**, in the stage's resolved-question section — and the schema lacks one: name the gap in the change ledger |
| 7 | an excerpt of **≤5 lines** cited as proof inside a contract row | **contract** |
| 8 | a record of what changed between rounds of this stage, a superseded finding, a rollback cause, or any claim about an earlier draft of this document | **routing log** (`PM_LOG.md`) |
| 9 | a body of characters destined **verbatim** for a shipped artifact — source code, comment prose, or document prose — and rows 3/4 did not match | **no home**; write instead, under row 5, the constraint the artifact must satisfy |
| 10 | a summary or paraphrase of another unit **in the same document** | **no home** |
| 11 | a question's text beyond one line, its candidate options, or the argument that selected among them | **rationale** |
| 12 | an argument, option comparison, reuse finding, risk statement, measurement narrative, or evidence citation supporting a unit classified by rows 1–7 | **rationale** |
| 13 | a captured tool run, transcript, or excerpt **longer than 5 lines** | **rationale** |
| 14 | **otherwise** | **rationale** (terminal default) |

**Row 4's bound is unchanged** and ships at `.harness/rules/70-doc-size.md:76-82` in the C-9 / D-2
wording: both conjuncts quantify over *statements of the constraint*, never over the body; for any
body of source code such a statement exists, so row 4 never matches source code. The "measured blast
radius: zero units" clause is **not** part of the rule and is not shipped (gate F-19).

**What the ordered unit buys — and where it stops.** Steps 2 and 3 make a fence and a quotation **one** unit each, so a multi-sentence
byte-form can no longer be read as a run of statements; step 6 makes a bare paragraph a run of sentences, so a mixed paragraph splits instead
of routing whole. Row 2's exclusion keeps a **multi-line** byte-form out of every `stmt`-shaped section, so `## Byte-form specification` is
reachable **only** through rows 3/4 by the rule's own text — no longer solely by `agents/solution-architect.md:24` (C-7 is belt, this is
braces). It does **not** reach a byte-form that fits on one line inside a declared row's cell: §13's published residual **RES-QA7**.

**Worked walks — the three units round 2 could not decide, and one it could.** First match wins, so
row 10 beats row 12 for a claim about this document's own content.

| Unit (live archived bytes) | Step | Walk | Destination |
|---|---|---|---|
| `_archived/stream-defer-human/02:94` — two-sentence blockquote under "replace `SKILL.md:76` with:" | 3 | r1 no; r2 **excluded** (verbatim); r3 no; r4 no (a shorter multi-satisfiable statement exists); r5 no (blockquote); r6-8 no | **row 9 → `no home`**; the constraint is written under row 5 |
| `_archived/stream-defer-human/02:98` — one-sentence blockquote, same framing | 3 | identical walk; the one-sentence property is now irrelevant | **row 9 → `no home`** |
| `_archived/hook-truth-verify-scope/02:236-239` — a three-sentence paragraph | 6 | s1 "Hand-off completeness is itself a required property" → r5; s2 "§3.1 and §3.2 give full bodies…" (a claim about this document) → r10; s3 "…do not degrade this section to a diff when implementing" → r5 | **splits**: contract, `no home`, contract — one destination each |
| `_archived/lang-policy-split/02:67-91` — fenced CJK replacement block | 2 | r1 no; r2 excluded; r3 no; r4 no; r5 no (fence) | **row 9 → `no home`** (unchanged from round 2) |

**Row-4 record for §2 itself** (inline because T-18's own folder is not retrofitted — §14): `BF-1 | 70-doc-size.md ## Stage-doc boundary
rule + E2 twin | this §2's unit ladder, byte-form definition and 14-row table | row 4 | test: no shorter statement exists and exactly one
artifact satisfies it | discharges FR-2, AC-1, AC-11`.

**Rule ↔ schema agreement is by construction.** Row 2 makes every declared shape contract, so the table and a stage schema cannot give
opposite answers for a declared section — except for a byte-form, which row 2 hands to rows 3/4/9. Row 5 carries no "named later stage"
qualifier, so a cap constraint naming no stage (`01` BC-9, BC-10) is contract. **BC-2**: a unit that is both binding and a round record hits
row 2/5 before row 8 — it lands in the contract as **current state**, and the *fact that it changed* hits row 8. **FR-7**: row 10 is why no
per-document summary header can exist.

---

## 3. Contract schema per stage (typed; every section declares a shape)

**`stmt`** = one single-sentence statement per line, imperative, no hedging. **`kv`** = `key: value` per line. **`row`** = a table row with
the named columns. Every schema ends with: *a unit that fits no declared shape here is classified by the boundary rule — if row 5 or row 6
matches it, this schema has a gap and the gap is reported in the change ledger.* **(kept)** = the heading already exists in a shipped
surface; **(new)** = it does not and the ledger creates it. Every contract opens with the FR-9 header line, which is itself a declared shape
(unit-ladder step 1).

**Every declared shape below is line-shaped** — a `stmt` line, a `kv` line, a table row — so a body needing more than one line has no
container to hide in anywhere in the schema. That property, not the rule table alone, is what carries AC-2, and it is also what fixes where
§13's structural half stops. Stated here once; §13 grades against it.

| Stage / file | Sections, in order, each with its shape |
|---|---|
| **1** `01_REQUIREMENT_ANALYSIS.md` | `## Goal` **(kept)** `stmt`×1 · `## In-scope behaviors` **(kept)** `stmt` — `**FR-n** — <binding statement>.` ≤3 sentences · `## Out of scope` **(kept)** `stmt`, numbered, one line each · `## Boundary conditions` **(kept)** `stmt` — `**BC-n** — <condition> → <required behaviour>.` · `## Acceptance criteria` **(kept)** `row` — `id \| criterion \| class [S]/[B] \| verification` · `## Non-functional requirements` **(kept)** `stmt`, each carrying a number or a named artifact · `## Resolved questions` (**renames** `## Open questions for user`) `row` — `id \| question (one line) \| binding answer`, with candidates + argument → `01_RATIONALE.md` · `## Verdict` **(kept)** one line, closed vocabulary |
| **2** `02_SOLUTION_DESIGN.md` | `## Architecture summary` **(kept)** `stmt`×≤3: what changes, what does not, where the seam is · `## Change ledger` (**renames** `Affected modules` + `Module decomposition`) `row` — `id \| absolute path \| new/edit \| what changes \| partition`, **total** over every touched file · `## Interfaces` (**renames** `Data model changes` + `API contracts` + `Sequence / flow`) `row` — `id \| surface \| shape (signature/route/table/heading) \| invariant` · `## Constraints` `stmt` — `**K-n** — <binding statement the implementer must satisfy>.`, the stage-2 **residual** home for row-5 units, shape test "one imperative sentence naming an actor and an obligation" · `## Byte-form specification` `row` — `id \| artifact \| exact byte-form \| boundary-rule row matched \| test result`, **present only when row 3 or row 4 matched** · `## Frozen set` `row` — `path \| why frozen` · `## Migration & edit sequence` (**renames** `Migration / rollout plan`) `row` — `order \| edit ids \| precondition \| rollback`, audited by gate dimension 5 · `## Out of scope` (**renames** `Out-of-scope clarifications`) `stmt`, one line each, audited by gate dimension 8 · `## Verification plan` `row` — `step id \| what is run/measured \| expected observable \| AC` · `## Residuals travelling` `row` — `id \| statement \| must reach <stage/doc>` · `## Partition assignment` **(kept)** existing table, required when `.harness/agents/dev-*.md` exist · `## Verdict` **(kept)** one line |
| **3** `03_GATE_REVIEW.md` | `## Dimension audit` `row`×8 — `# \| dimension \| PASS/WARN/FAIL \| one-sentence reason` · `## Findings` **(kept)** `row` — `id \| severity \| owning upstream doc+section \| one-sentence finding` · `## Binding conditions` `row` — `id \| condition \| owner stage \| discharged by` (authoritative; superseded rounds corrected in place) · `## Pre-answered developer questions` `row` — `id \| question \| answer` · `## Verdict` **(kept)** one line, mode-appropriate vocabulary |
| **4** `04_DEVELOPMENT.md` | `## Summary` **(kept)** `stmt`×≤3 · `## Files changed` **(kept)** `row` — `path \| what changed \| ledger id` · `## verify_all result` **(kept)** `kv` — baseline / after / delta · `## Design drift` **(kept)** `row` — `id \| design item \| what was done instead \| why`, `None.` when empty · `## Condition disposition` `row` — `gate condition id \| disposition \| evidence` · `## Open issues for review` **(kept)** `stmt` · `## Dev-map updates` **(kept)** `stmt` · `## Insight to surface` **(kept)** one **physical** line per insight (T-15 harvester constraint) · `## Verdict` **(kept)** one line |
| **5** `05_CODE_REVIEW.md` | `## Files reviewed` **(kept)** one path per line · `## Findings` **(kept)** `row` — `id \| severity \| axis \| file:line \| finding` · `## Requirement coverage check` **(kept)** existing `row` · `## Design fidelity check` **(kept)** existing `row` · `## Axis status` **(kept)** `stmt`×2, one per axis, explicit clean result required · `## Residuals travelling` `row` — `id \| statement \| must reach` · `## Verdict` **(kept)** one line |
| **6** `06_TEST_REPORT.md` | `## Test plan` **(kept)** existing `row` · `## Adversarial tests` **(kept — byte-frozen)** existing `row`, evidence column carrying a ≤5-line excerpt (row 7) with full runs → `06_RATIONALE.md` · `## Boundary tests added` **(kept)** `stmt` · `## verify_all result` **(kept)** `kv` · `## Defects found` **(kept)** `row` — `id \| severity \| reproducer \| file:line` · `## Stability` **(kept)** `stmt` · `## Verdict` **(kept)** one line |
| **7** `07_DELIVERY.md` | `## Summary` **(new — E29)** `kv`, the existing eight-field list that today sits under `# Delivery Summary` with no `##` heading · `## Insight` **(kept — byte-frozen)** one **physical** line per insight · `## Entropy watch` **(kept)** existing conditional section · `## Verdict` **(new — E29)** one line: `DELIVERED`, or the blocked/failed token the run reached |

**Two headings are byte-frozen and may never move to a rationale** (row 1), because a mechanism reads
them: `## Adversarial tests` in `06_TEST_REPORT.md` is grepped by **three** template `verify_all`
pairs (`generic` `E.6` `sh.tmpl:151` / `ps1.tmpl:179`; `fullstack` `E.6` `:247` / `:217`; `backend`
`D.6` `:262` / `:237` — `common` ships no pair), and `## Insight` in `07_DELIVERY.md` is harvested by
`archive-task.sh:51` / `.ps1:49`.

**Stage 7 is the one schema whose headings do not exist yet.** `agents/pm-orchestrator.md:190`
declares the shapes but its authoring template at `:196-224` opens `# Delivery Summary` with the `kv`
fields directly beneath — no `## Summary`, no `## Verdict`; **40 of 40** archived deliveries carry
neither, so `agents/supervisor.md:101` (AP-2) WARNs on every delivery the template has ever produced.
E29 adds the two headings; the thresholds at `agents/supervisor.md:93-101` are **not** touched (C-11).

**Re-audit against all seven schemas.** Every section above is a declared shape, therefore contract by row 2 — unless the **unit itself** is a
byte-form, which rows 3/4/9 decide; a byte-form nested inside a declared row's cell is not reached and stays contract (**RES-QA7**, §13). The
four classes the gate found misrouting resolve as: `## Insight to surface` / `## Insight` → row 1/2 → contract (closing the `archive-task`
false-green); `## Dev-map updates` → row 2; `## Out of scope` → declared at **both** stages 1 and 2 → contract at both; `## Resolved
questions` → the **row** is the unit (ladder step 1), so question and binding answer are not split, while candidates and argument are separate
units → row 11. Gate dimension 5 has `## Migration & edit sequence`, dimension 8 has `## Out of scope`, and dimensions 3/4 have the rationale
the gate reads by default.

---

## 4. The rationale artifact and the routing log

**Filename**: `0N_RATIONALE.md`, N = stage number, in the same task folder, **created only when
non-empty** (BC-3). One writer per file — the stage that owns N (why OQ-1(b) is not used).

**Collision audit.** It matches none of: `find … -name '06_TEST_REPORT.md'` (E.6/D.6), `find docs/features -maxdepth 3 -name
SUPERVISION_REPORT.md` (I.7), `archive-task`'s `07_DELIVERY.md` read, or supervisor AP-2's seven exact filenames
(`agents/supervisor.md:95-101`). It **does** match `70-doc-size.md:31`'s `0[1-7]_*.md` cap pattern (desired: inherits the 500-line cap) and
`agents/supervisor.md:236`'s read glob (**not** desired — E10 excludes `*_RATIONALE.md` there). `archive-task` moves the whole directory, so
no archiver change is needed.

**Header (FR-9).** Every contract opens with `> Contract portion. Rationale: 0N_RATIONALE.md (absent
= none written).`; every rationale with `> Rationale portion for <contract filename>. Non-binding.`

**Round history (FR-5).** No schema in §3 contains a changelog, round-record or superseded-finding section. On completing a rework round the
stage agent returns a **round record** in its final message to the PM — `round N · what changed · why · which finding id` — and the PM writes
it into `PM_LOG.md`; the stage document is corrected **in place** to current state. Routing-log growth is absorbed by the existing PM-owned
compaction pattern (`70-doc-size.md` Rule 2), unchanged.

---

## 5. Rationale triggers (FR-4) — total table

| Consumer | Reads by default | Opens a rationale only when… | Which rationale |
|---|---|---|---|
| 2 solution-architect | `01` | T2.1 a contract statement it must design to is ambiguous or self-contradictory; T2.2 it is about to override a `## Resolved questions` answer; T2.3 it is about to return `BLOCKED ON UPSTREAM`; **T2.4 it is on a rework round** (reads `03` + the gate's per-finding reasoning) | `01_RATIONALE.md`, `03_RATIONALE.md` (T2.4) |
| 3 gate-reviewer | `01`, `02`, **and `01_RATIONALE.md` + `02_RATIONALE.md`** | — (both portions are its default input; dimensions 3, 4, 7 audit the reasoning) | — |
| 4 developer **and every partition `dev-*` agent** | `01`, `02`, `03` | T4.1 about to record `DESIGN DRIFT`; T4.2 a contract row is ambiguous or contradicts another; T4.3 about to write `BLOCKED ON DESIGN`; T4.4 reworking after CR/QA defects | `02_RATIONALE.md`, `01_RATIONALE.md` (T4.2 on an AC), `05`/`06_RATIONALE.md` (T4.4) |
| 5 code-reviewer | `01`, `02`, `04` | T5.1 a design-fidelity finding turns on *why* the design chose a shape; T5.2 adjudicating a dev-recorded `DESIGN DRIFT`; T5.3 about to raise a reuse-correctness or risk finding; **T5.4 a contract row it must act on cites an identifier (`R-n`, `OQ-n`, a finding id) that no contract portion defines** | `02_RATIONALE.md` (T5.1, T5.3), `04_RATIONALE.md` (T5.2), the stage owning the identifier (T5.4) |
| 6 qa-tester | `01`, `02`, `04`, `05` | T6.1 an AC's verification step is under-specified; T6.2 reproducing a developer-claimed measurement; T6.3 a CR finding it must re-test is not self-contained | `02`, `04`, `05_RATIONALE.md` respectively |
| 7 pm-orchestrator | all contracts + `PM_LOG.md` | T7.1 composing `BLOCKED: NEEDS-HUMAN` and no contract carries the reason; T7.2 composing `07_DELIVERY.md`'s entropy/insight rows from a QA dispute; **T7.3 a contract row it must act on cites an identifier (`R-n`, `OQ-n`, a finding id) that no contract portion defines** (T5.4's wording, verbatim) | the stage that blocked; `06_RATIONALE.md`; the stage owning the identifier (T7.3) |
| supervisor | all contracts + `PM_LOG.md` | never — AP-2 audits contracts only; a missing rationale is never a thinness signal | — |
| **any consumer, otherwise** | — | **no trigger fires → the rationale is not read** | — |

**The remaining asymmetry is deliberate (QA-5, decided).** Stages 2, 4 and 6 author *against* a contract, so an ambiguous contract stops
their work and they must read the reasoning. Stages 5 and 7 audit or compose what already exists, and a reviewer that resolves an ambiguity
by reading the rationale **hides** the defect it should raise as a finding — so no "ambiguous contract" trigger is added there. An
**unresolvable identifier** is a different class: not an ambiguity to report but a row that cannot be read at all (measured instance:
`_archived/hook-truth-derivation/05_CODE_REVIEW.md:458` carries a bare `R-1`, a rationale-resident design risk id, into `07_DELIVERY.md`).
T5.4/T7.3 are therefore added, worded identically in both agents.

**BC-5**: contract absent → `BLOCKED ON UPSTREAM` (PM's form: route back to the stage that owes it);
rationale absent → proceed (soft dependency). **BC-6**: trigger fires and rationale absent → record one
line ("reached for `0N_RATIONALE.md` under T<x>; absent; proceeded") and continue; never block, never
fabricate. **`07_RATIONALE.md` has no in-pipeline consumer** — archive/operator material only.

---

## 6. Change ledger — exact edits

`Lines` = measured `wc -l` after the last edit, or a projection for a row not yet executed. The
developer re-measures every listed file with `wc -l`, before and after (V-6).

| # | File (absolute, under `/home/alan/Programs/harness-kit/`) | Lines | What changes |
|---|---|---|---|
| E1 | `.harness/rules/70-doc-size.md` | 156 → ~170 | **Hosts §2** as `## Stage-doc boundary rule`. Round-3 corrections: replace the one-paragraph unit definition with §2's **six-step ordered ladder** + the "Not units" clause + the "Verbatim byte-form" definition; row 2 gains the byte-form exclusion; row 5 gains "or a blockquote"; row 6 gains row 5's definition, a destination and the ledger-gap instruction. Everything else stays byte-identical, including row 4's C-9 wording at `:76-82`. Cap 200 ✓ · **Contingency**: if >200, split to `.harness/rules/71-stage-contract.md` + its `AI-GUIDE.md` index entry (`E.4b` requires it) |
| E2 | `skills/harness-init/templates/common/.harness/rules/70-doc-size.md.tmpl` | 155 → ~169 | Same edit, byte-identical to E1; the pair's five pre-existing divergences (V-4) stay untouched, and the inserted section keeps **zero** internal divergence |
| E3 | `agents/requirement-analyst.md` | 101 | Stage-1 schema; `## Open questions for user` → `## Resolved questions`; FR-9 header; rationale-portion pointer naming `70-doc-size.md` **by name, restating none of it**; degradation clause (R8); no-changelog hard rule |
| E4 | `agents/solution-architect.md` | 169 | Stage-2 schema incl. `## Migration & edit sequence` + `## Out of scope`; hard rule 6 (**never coin a stage-doc filename**, stated by class); `## Reuse audit` + `## Risk analysis` → rationale; steps 1/7/8/9/10 re-pointed; T2.1–T2.4; degradation clause; `## Byte-form specification`'s two guards verbatim (C-7) |
| E5 | `agents/gate-reviewer.md` | 113 | Stage-3 schema; steps 1–2 → "read `01`, `02`, **and both rationale portions**"; the 8-dimension table **unchanged in number and wording** (AC-5) |
| E6 | `agents/developer.md` | 91 | Stage-4 schema (adds `## Condition disposition`); step 1 → contracts only; T4.1–T4.4; round records to PM; degradation clause |
| E7 | `agents/code-reviewer.md` | 166 → ~168 | Stage-5 schema; `## Findings` one typed table; `## Residuals travelling`; step 1 → contracts only; **T5.1–T5.4** (T5.4 is the round-3 addition, §5). Two axes + masking rule unchanged |
| E8 | `agents/qa-tester.md` | 156 | Stage-6 schema; `## Adversarial tests` byte-frozen and the example heading de-suffixed; "Paste actual tool output" → ≤5-line citation + `06_RATIONALE.md`; step 1 → contracts only; T6.1–T6.3 |
| E9 | `agents/pm-orchestrator.md` | 282 → ~284 | Dispatch prompts name the canonical filename + the consumer's trigger list, never "read the whole folder"; PM corrects an upstream ledger row naming a different one; round records into `PM_LOG.md`; the PM's own input list + **T7.1–T7.3** (T7.3 is the round-3 addition) |
| E29 | `agents/pm-orchestrator.md` (same file as E9) | +~5 → ~289 | **Round-3, from QA-4/QA-6.** Inside the fenced stage-7 authoring template at `:196-224`, insert `## Summary` between `# Delivery Summary` and the `kv` field list, and append `## Verdict` as the template's **last** section carrying one line (`DELIVERED`, or the blocked/failed token the run reached) — after the `## Insight` block, which stays omittable while `## Verdict` does not. These are the two headings AP-2 (`agents/supervisor.md:101`) requires and 40 of 40 archived deliveries lack. In the same sentence at `:190`, "**three** declared shapes" → "**four**". Do **not** touch `agents/supervisor.md:93-101` (C-11). Cap 300 · **Contingency**: if >295, condense the `## Document size discipline` block to 3 lines pointing at `70-doc-size.md` |
| E10 | `agents/supervisor.md` | 287 | AP-2 row 2 either/or headings; `:236` read glob excludes `*_RATIONALE.md`; one line: `0N_RATIONALE.md` is outside AP-2 and its absence is never a thinness signal. **No threshold value changes** |
| E11 | `.harness/rules/60-tool-handoff.md` | 131 | Resume step 3 → the numbered **contract** documents; rationale only on a trigger. **Retires the `04a_DEVELOPMENT_<partition>.md` clause** — no agent produces that name, so it is a phantom second stage-4 filename and AC-7 fails while it stands |
| E12 | `skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md` | 128 | Lockstep twin of E11 |
| E13/E14 | `docs/workflow.md` + `skills/harness-init/templates/common/docs/workflow.md` | +6 ea. | `:8-14` stage→file map gains the optional `0N_RATIONALE.md` sibling + the routing-log statement |
| E15/E16 | `AI-GUIDE.md` + `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` | 113 / ±0 | `:32` gains "+ the stage-doc contract/rationale boundary rule" **and its trigger gains "when writing any section of a stage doc"** |
| E17 | `CONTEXT.md` | 185 | 8 terms (`Stage contract`, `Stage rationale`, `Rationale sibling`, `Routing log`, `Boundary rule`, `Declared shape`, `No home`, and round 3's `Byte-form`) appended by the architect at coining time; **plus** `:33` "each stage reads the prior docs" → "…the prior stages' **contract portions**". Developer verifies presence only |
| E18 | `docs/dev-map.md` | +2 | "Per-task documents" gains the rationale sibling |
| E19 | `.harness/rejected-decisions.md` | 199 → 222 | `boundary-rule-in-agent-file`, `upgrade-rule-content-refresh`, `ambiguity-trigger-at-review-stages` **and** `byte-form-subpart-classification` (the declined forced closure of RES-QA7/RES-QA8, §13) present — all four appended by the architect at their decide-points. Developer verifies presence only |
| E20 | `CHANGELOG.md` | +6 | Append under the **existing** `## [0.46.0]`; create no version heading; touch no stamp (NFR-4). Name the retired stage-4 variant **by class**, never by token |
| E21 | `docs/features/stage-contract-split/AC9_RECONSTRUCTION.md` | 186 | The FR-10/AC-9 artifact (§11.2). New file in **this** task's folder; the archive is read-only |
| E22 | `skills/harness-goal/SKILL.md` | ±0 | `:68` "(accumulated dev log, one section per iteration)" → "(current-state contract; iteration history lives in `goal_state.json` + `PM_LOG.md`)" — as written it instructs the accretion FR-5 abolishes |
| E23 | `skills/harness-verify/SKILL.md` | ±0 | `:22` "append the report to that task's `04_DEVELOPMENT.md`" → "record the counts in `## verify_all result`; a full transcript goes to `04_RATIONALE.md`" |
| E24 | `skills/harness-init/templates/{fullstack,backend}/.harness/skills/verify/SKILL.md.tmpl` | ±0 ea. | Same correction, in the two generated-project verify skills |
| E25 | `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl` | ±0 | `:15`'s closed per-task enumeration gains ", and any `0N_RATIONALE.md` sibling" |
| E26/E27 | `skills/harness-init/SKILL.md:74` + `…/templates/i18n/zh/_policy/output-language.zh.md.tmpl:18` | ±0 ea. | Closed file enumeration → "every per-task document under `docs/features/<task>/`" (E27 in Chinese, matching its file) |
| E28 | The **six** partition stage-4 templates: `…/fullstack/.harness/agents/dev-{frontend,backend,db}.md.tmpl`, `…/backend/.harness/agents/dev-{api,services,db}.md.tmpl` | +8…+37 | Each gains a contract-portion input list, T4.1–T4.4 verbatim, the FR-9 header and the no-changelog rule. Three declare the stage-4 schema inline; three declare it **by reference** to a resolvable project-local source (D-3, gate C-10) |

**Closure.** These 29 rows cover **33 files** (E29 edits E9's file); no other file changes. **No script changes**: `verify_all.{sh,ps1}`,
`archive-task.{sh,ps1}`, `sync-self.{sh,ps1}`, `harness-sync`, `test-*` and `baseline.json` are untouched, so the check count stays **32**
(AC-6) and **no PowerShell surface is created** — the operator list stays at **sixteen** items, unrenumbered. The closure claim is
falsifiable by V-5 + V-10, whose token sets derive from §7's table.

---

## 7. Provenance sweep and decoy set

**FR-11 / AC-8.** This design **retires one filename token** (`04a_DEVELOPMENT_<partition>.md`) and
**renames eight shipped section names**. Every naming sentence in a shipped surface is below, each
inside an edit that rewrites it, so no unledgered provenance sentence survives.

| P | Shipped sentence naming a surface this task retires, renames or re-homes | Edit |
|---|---|---|
| P1 | `agents/solution-architect.md:17-25` — `Affected modules`, `Module decomposition`, `Data model changes`, `API contracts`, `Sequence / flow`, `Migration / rollout plan`, `Out-of-scope clarifications` | E4 |
| P2 | `agents/solution-architect.md:22-23` `Reuse audit` / `Risk analysis` as produced sections; `:47-50` step 7; `:53` step 10; `:69-79` reuse-audit format block; `:114` "Reuse audit is non-empty" | E4 — both become rationale sections; the format block is re-labelled as the rationale's shape |
| P3 | `agents/requirement-analyst.md:23` `## Open questions for user`; `:66` "Related historical tasks are linked" | E3 |
| P4 | `agents/gate-reviewer.md:40` "Is the reuse audit accurate?" (dimension 3) | **unchanged** — the gate reads the rationale by default, so AC-5's wording freeze holds |
| P5 | `agents/qa-tester.md:97` "Paste actual tool output for each" | E8 |
| P6 | `agents/supervisor.md:96` stage-2 headings; `:234` read glob | E10 |
| P7 | `.harness/rules/60-tool-handoff.md:31-34` + twin — "Read every existing stage document in order", incl. `04a_DEVELOPMENT_<partition>.md` | E11/E12 |
| P8 | `docs/workflow.md:8-14` + twin — stage→filename map | E13/E14 |
| P9 | `CONTEXT.md:33` — "each stage reads the prior docs" | E17 |
| P10 | `skills/harness-goal/SKILL.md:68`; `skills/harness-verify/SKILL.md:22` + two template twins | E22/E23/E24 |
| P11 | `templates/common/.harness/rules/00-core.md.tmpl:15`; `skills/harness-init/SKILL.md:74`; `templates/i18n/zh/_policy/output-language.zh.md.tmpl:18` | E25/E26/E27 |
| P12 | Six partition templates' input lists and `04_DEVELOPMENT.md` schemas | E28 |
| P13 | `agents/pm-orchestrator.md:190` — "`07_DELIVERY.md` is a contract portion with three declared shapes", and the `:196-224` template that omits two of them | E29 |

**Decoy set — DO NOT TOUCH (T-03 class; grows with project history).**

| D | Path | Why frozen |
|---|---|---|
| D1 | `.harness/insight-index.md` (all 30 lines) | past-state truths; `:16` names `04_IMPLEMENTATION.md` as history |
| D2 | `.harness/scripts/baseline.json` | frozen counts + `_qa_note_*` strings describing past states |
| D3 | `docs/features/_archived/**` (all 40+ folders) | frozen history; the evidence base of `01` §2 and of every walk in §2 |
| D4 | `CHANGELOG.md` historical `## [x.y.z]` entries | append-only; only the top section is appended to (E20) |
| D5 | `docs/tasks.md` Completed delivery rows | append-only |
| D6 | `docs/v0.11-changes.html`, `docs/walkthrough.html` (incl. `:595`), `docs/project-overview.html`, `architecture.html` | dated snapshots of past states |
| D7 | `skills/harness-supervise/fixtures/**` | test fixtures; E10's either/or edit exists so these stay valid |
| D8 | `docs/proposals/frontier-gaps-2026-07.md` | untracked operator backlog; out of scope by `01` §6.9 |
| D9 | `docs/batches/default/STREAM_LOG.md` | stream run log; append-only, PM-owned |
| D10 | the **three** template `verify_all` pairs' `E.6`/`D.6` blocks | read `## Adversarial tests`; the heading is byte-frozen instead |

---

## 8. Reuse audit

| Need | Existing code / pattern | File path | Decision |
|---|---|---|---|
| A cross-agent authoring rule loaded at the decision point | `70-doc-size.md`'s "When to read this" already fires before pasting into a stage doc | `.harness/rules/70-doc-size.md:13-18` | **Reuse as host** (T-09 read-trigger insight) |
| Body/appendix split for mandated verbatim evidence | T-15's evidence-budget ruling | `_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:956-968` | **Generalise** from "evidence" to "everything not consumed downstream" |
| Round-history storage | PM_LOG stage-transition sections + PM-owned compaction | `.harness/rules/70-doc-size.md` Rule 2; `agents/pm-orchestrator.md` | **Reuse unchanged** |
| Archive-safety for new per-task files | whole-directory move | `.harness/scripts/archive-task.sh:111` | **Reuse as-is**; no archiver change |
| A delivery verdict token for `## Verdict` (E29) | `DELIVERED` is already the primary resume key of both drivers | `skills/harness-stream/SKILL.md:67,126`; `skills/harness-batch/SKILL.md:51,81` | **Reuse the existing token** — E29 coins no vocabulary and makes the drivers' primary check land on a heading instead of loose prose |
| Single-source-then-reference discipline | requirement-analyst Hard rule 6 ← pm-orchestrator | `agents/requirement-analyst.md:33` | **Reuse the pattern**: one host, N by-name pointers |
| Distribution to generated projects | `/harness-init` template overlay | `skills/harness-init/templates/common/.harness/rules/` | **Reuse** (P-1) |
| Refreshing rules in *existing* projects | (none — `/harness-upgrade` excludes rule content) | `skills/harness-upgrade/SKILL.md:231` | **Declined**, recorded as `upgrade-rule-content-refresh`; degradation clause instead (R8) |
| A gate check for stage-doc schema | (none — none is added) | — | **Declined**: `01` §6.3 count freeze + R-3 |
| A per-document summary header | (none) | — | **Declined (standing)**: `stage-doc-summary-header` |

---

## 9. Risk analysis

| R | Risk | Mitigation |
|---|---|---|
| R1 | **Narrowing loses context and causes rollbacks.** | §12's derivation is from measured citations; every omitted class is reachable through a named trigger (§5), and QA's citation scan of nine downstream documents found no starved reference. BC-6 makes a missing rationale non-blocking. Falsifier: any T-20 rollback whose stated cause is "information absent from the contract" is an AC-12 defect and routes back to me. |
| R2 | **The rationale becomes the new dumping ground.** | Rows 9 and 10 send byte-forms and restatements to **`no home`**, not to rationale. The rationale inherits the 500-line cap by pattern. Residual: that cap is policy without a mechanism (P-2) — §13. |
| R3 | **`pm-orchestrator` or `supervisor` breaches the 300-line cap**; `verify_all` exits non-zero on any WARN. | Measured 282→~289 and 287, against named condensation contingencies (E29, E10). V-6 measures every agent with `wc -l` after the last edit. |
| R4 | **A template twin drifts** (E1/E2, E11/E12, E13/E14, E15/E16, E23/E24). | AC-14 lockstep; V-4 diffs each pair against the **five enumerated** pre-existing divergences and requires zero divergence inside the inserted section. `sync-self` does not cover these — the check is manual and listed. |
| R5 | **A byte-frozen heading is moved** and a generated project's gate breaks in a repo we do not run. | Row 1 + §3 mark both headings frozen with their readers cited; D10 freezes the three `E.6`/`D.6` blocks; V-3 greps both matchers in both shells. QA proved the matchers load-bearing by artifact mutation, so the freeze is not a vacuous check. |
| R6 | **A future stage emits an undeclared `## Round 2` heading anyway.** | Honest residual — §13. Detection is the gate (dimension 2), the code-reviewer's Standards axis, and the PM's route-back on a `## Round N` heading — all now citing a named rule. |
| R7 | **AC-9's ≥30 % is not met** on the T-15 folder. | E21 measures **37.7 %** span-by-span against the live archive, with every arguable attribution resolved toward contract. Under 30 % would be reported as a failure, not tuned. |
| R8 | **The installed base can never receive the rule fragment** while its plugin-native agents update automatically. | **Disposition, not inheritance**: (i) a `/harness-upgrade` rule-content refresh is **declined with reason** (`upgrade-rule-content-refresh` — a refresh clobbers bespoke per-repo fragments); (ii) every edited agent contract carries a **degradation clause**: if `70-doc-size.md` has no `## Stage-doc boundary rule` section, apply the agent's own `## What you produce` schema and proceed, do not block; (iii) E20's CHANGELOG entry states that existing projects pick the section up at re-init or by copying the fragment. Graded **Weak** in §13. |
| R9 | **The "destined verbatim" predicate is author-declared, so an architect can keep prose in the contract by not marking it as a byte-form.** | The unit ladder removes the two cheap evasions: a fence and a quotation are **one** unit each (steps 2/3), so the multi-sentence byte-form can no longer be read as separate statements, and row 2 no longer admits it into a `stmt` section. What remains is (a) prose written unmarked, sentence by sentence — for which the residual is a **reformat, not an escape**: each binding sentence reaches the contract through row 5 as a `**K-n**` constraint, which is the shape the contract wants and costs one line; and (b) a byte-form that fits on one line inside a declared row's cell, which is not reformatted at all (**RES-QA7**). Both are graded **compliance below one line** in §13, measured, not asserted. V-2 carries one unmarked-prose candidate. |
| R10 | **Scope is 33 files**, so a missed surface is likelier than in round 1. | V-5's sweep is derived from §7's P-table rather than a hand-picked token list and is path-scoped to shipped surfaces; V-10 independently sweeps stage-4 filename tokens. Any hit outside P1–P13 ∪ D1–D10 fails the criterion. QA re-ran both sweeps clean. |

---

## 10. Migration & edit sequence

| Order | Edits | Precondition | Rollback |
|---|---|---|---|
| 1 | E1 → E2 | capture the `verify_all` baseline first (C-1); E1's ladder and row edits are transcribed from §2 with no adaptation left to the developer | `git checkout --` |
| 2 | E7, E9, E29 (the round-3 agent edits; mutually independent) | E1 exists, so the pointers resolve; E29 and E9 touch one file — apply E9's trigger line and E29's template headings in one pass and measure `wc -l` once | `git checkout --` |
| 3 | E3…E6, E8, E10 (remaining agents) | as above | `git checkout --` |
| 4 | E11…E18, E22…E28 (prose + template surfaces) | agents' wording final, so the twins match | `git checkout --` |
| 5 | E19/E20 → E21 | all content edits done | `git checkout --` / delete the new file |

**Backwards compatibility is free (BC-14).** The contract keeps the existing filename, so a pre-change task folder is already a valid
contract portion with no rationale sibling — the BC-3 "absent = none written" state; no folder migration, archive untouched (D3). E29 adds
headings to a *template*, so the 40 archived deliveries stay unedited and AP-2 keeps WARNing on them exactly as it does today, with no
threshold moved. **In-flight**: T-18's own folder is not retrofitted; T-20 executes first under the new structure. **Rollback**: every edit is
prose in tracked Markdown — no data migration, no flag, no state. **No release action**: no version bump, stamp or `baseline.json` change.

---

## 11. Verification plan

### 11.1 Steps (developer executes V-1…V-12; QA re-derives V-1…V-5, V-10 and V-12 independently)

| Step | What is run / measured | Expected observable | AC |
|---|---|---|---|
| V-1 | `bash .harness/scripts/verify_all.sh` | `PASS: 32 / WARN: 0 / FAIL: 0`, exit 0, 32 step lines, identical to the pre-edit baseline | AC-6, AC-10 |
| V-2 | Classification probe against the **effective** rule — the shipped table **and** the §3 schema the unit would live in (C-5) — over ≥20 archived units, which **must** include: the four §2 worked walks, ≥3 units fitting no declared shape, ≥1 per class in §3's re-audit paragraph, ≥1 cap constraint naming no stage, ≥1 row-4 candidate that must be **rejected**, and ≥1 **unmarked** normative prose sentence (no fence, no quote, no "verbatim"); classified by the developer and independently by QA | exactly one destination per unit and no unit with two; the two classifications agree on every unit; the four worked walks reproduce §2's destinations; the undeclared units land on row 14; the insight/dev-map/out-of-scope/resolved units land on **contract**; the cap constraint lands on contract via row 5; the row-4 candidate lands on row 9. **Two published exceptions to "exactly one": the FR-9 header line (RES-QA8) and a one-line byte-form inside a declared row's cell (RES-QA7) — record them, do not tune the probe around them** | AC-1 |
| V-3 | `grep -n 'Adversarial tests' skills/harness-init/templates/{generic,fullstack,backend}/.harness/scripts/verify_all.{sh,ps1}.tmpl` and `grep -n 'Insights\?' .harness/scripts/archive-task.{sh,ps1}` | all eight matcher lines byte-identical to pre-change | AC-6, R5 |
| V-4 | `diff` each lockstep pair (E1/E2, E11/E12, E13/E14, E15/E16, E23/E24) | for the `70-doc-size` pair: **exactly the five pre-existing divergences** — L1 title `(harness-kit dogfood)`; the `I.*` this-repo sentence; `I.*`/`F.*`; `docs/concepts.md` vs "…or similar"; `30 evidence lines` vs `30 lines` — **and zero divergence inside the `## Stage-doc boundary rule` section**, ladder and amended rows included. Other pairs: identical in the changed region | AC-14 |
| V-5 | Provenance sweep over shipped surfaces only (`agents/ .harness/rules/ skills/ docs/*.md AI-GUIDE.md CONTEXT.md`, excluding D1–D10) for every retired/renamed token: `04_IMPLEMENTATION`, `04a_DEVELOPMENT`, `Affected modules`, `Module decomposition`, `Data model changes`, `API contracts`, `Sequence / flow`, `Migration / rollout`, `Out-of-scope clarifications`, `Reuse audit`, `Risk analysis`, `Open questions for user`, `File-level change set`, `accumulated dev log`, `Paste actual tool output`, `three declared shapes` | every hit is a P1–P13 row or a D1–D10 decoy; **zero unledgered hits** | AC-8 |
| V-6 | `wc -l` on all 8 `agents/*.md`, both `70-doc-size` files, `AI-GUIDE.md` + twin, before and after | every agent ≤300 (worst: `pm-orchestrator` after E9+E29, `supervisor` 287), every rule fragment ≤200, `AI-GUIDE.md` ≤200; both figures recorded (C-4) | AC-10, BC-9, BC-10 |
| V-7 | Read each downstream agent contract and list its stated inputs | no input list names a whole stage document without qualification; each names its trigger set (stage 5 shows **four**, stage 7 shows **three**); gate-reviewer names both portions of 1 and 2 | AC-4, AC-5 |
| V-8 | Degradation desk-check against the edited contracts | rationale deleted → stage proceeds and records the absence; contract deleted → `BLOCKED ON UPSTREAM`; boundary-rule section absent → agent applies its own schema and proceeds (R8) | AC-12, BC-5, BC-6 |
| V-9 | Backwards-compat probe: point the edited stage-4 contract at `docs/features/_archived/guard-cmd-chain/` (read-only) | contracts resolve; no rationale sibling; no error path taken | AC-13, BC-14 |
| V-10 | `grep -rn '04_DEVELOPMENT\|04a_DEVELOPMENT\|04_IMPLEMENTATION' --include='*.md' --include='*.tmpl' .` excluding `docs/features/` and D1–D10 | **exactly one distinct** stage-4 filename: `04_DEVELOPMENT.md` | AC-7 |
| V-11 | Read all **six** partition `dev-*.md.tmpl` contracts | each names contract portions as inputs and carries T4.1–T4.4; each declares the stage-4 schema inline **or** by reference to a resolvable project-local source | AC-4 |
| V-12 | Build the smallest schema-conforming `07_DELIVERY.md` from the **edited** template and count it; grep the template for `^## Summary` and `^## Verdict`; re-read `agents/supervisor.md:93-101` | both headings present, so AP-2's heading clause no longer fires on a conforming delivery; the minimum line count is re-measured and **published** whatever it is; `agents/supervisor.md:93-101` byte-unchanged (C-11); `agents/pm-orchestrator.md:190` reads "four" | AC-10, QA-4/QA-6, RES-1 |

QA additionally owns AC-2's probe: classify
`_archived/hook-truth-verify-scope/02_SOLUTION_DESIGN.md:126-240` under the effective rule, confirm it
lands on **`no home`** via row 9, and confirm E21 shows the `## Constraints` statement replacing it.

### 11.2 AC-9 measurement — the T-15 reconstruction

`E21` = `docs/features/stage-contract-split/AC9_RECONSTRUCTION.md`. **Method: whole-section attribution at `##`/`###` boundaries**, spans read
from the live archived files; every **mixed** section is listed with its per-line adjustment, so the residual attribution error is published,
and every arguable attribution is resolved **toward contract** because under-reporting is the only safe direction for a floor. Measured: `02`
1152L → contract **725** · `no home` 144 · rationale 183 · routing log 100; `01` 254L → contract **169**; `03` 243L → contract **134** ·
rationale 95 · routing log 14. **Stage-4 ingest 1649L → 169 + 725 + 134 = 1028L = 37.7 % reduction**, 7.7 points over the binding 30 %.
Stages 5 and 6 measure 52.9 % and 51.7 %.

**Stated limitation, published in E21.** The reconstruction is a **pure re-homing** of T-15's prose; it does not re-author, so the
reconstructed `02` contract is 725 lines — above the 500-line cap, and nothing measures that (P-2). The further reduction available from §3's
typed shapes is real but is **not** counted toward AC-9: counting it would need archived text rewritten, and the measurement would stop being falsifiable.

---

## 12. The central tension, resolved from `01` §3

**Too narrow → rollbacks from missing context. Too broad → nothing shrinks.** §3's schema is exactly the union of what stages 4/5/6 cited
across fifteen downstream documents, plus each stage's own outputs. Every excluded class is excluded on measurement (`Reuse audit` occurs in
47 archived files and **only** in `02_*`/`03_*`; `OQ-` runs ×11–16 at stage 2 and ×0–5 at stages 4–6) and goes to the rationale, which the
**gate reads by default**, so nothing audited stops being audited (AC-5). The one dangerous narrowing — byte-form specification — is held for
multi-line forms by rows 3/4 sitting **above** row 9 (below one line, RES-QA7), and the one measured starvation path (an identifier defined
only in a rationale) is closed by T5.4/T7.3.

---

## 13. Where enforcement rests on structure, and where on compliance

**The grade, stated in full: the guarantee is structural for multi-line forms, compliance for anything that fits on one line.** There is no
unqualified structural guarantee here, and a reading that comes away believing the guarantee is total is a misreading of this section. The
class this task was launched against — design documents embedding large verbatim blocks of implementation text, measured at 250–420 KB per
task — is the multi-line class, and it is now structurally homeless. What survives is single-line content inside a declared shape: a
different class, and not the one that was costing those bytes. QA's sizing of the class this bounds: **27 of 38** archived designs carry
blockquoted content plus the word "verbatim". §3's line-shaped-shapes property is what carries the half that does hold.

| Mechanism | Rests on | Honest strength |
|---|---|---|
| Rationale is not delivered unless a trigger fires | **artifact boundary** | **Strong.** A dispatch naming `02_SOLUTION_DESIGN.md` cannot deliver `02_RATIONALE.md`; there is no in-document delimiter to ignore. |
| A 115-line pre-written **fenced** body has no location | **typed schema** + unit ladder step 2 + rows 9/10 | **Strong for the multi-line form — verified, not argued.** QA walked the flagship block through all fourteen shipped rows independently and reached `no home`; row 4 cannot admit code (a shorter multi-satisfiable statement always exists); the one byte-carrying shape is gated on rows 3/4. |
| A **quoted** normative body (the 27-of-38 class) has no location | unit ladder step 3 + row 2's byte-form exclusion + rows 4/9 | **Strong for the multi-line quoted form.** Ladder step 3 makes the whole quotation one unit, so it cannot be read as a run of one-sentence statements — the exact ambiguity that produced two opposite classifications of the same bytes. Row 2's exclusion keeps it out of all ~18 `stmt`-shaped sections. Both disputed units walk to row 9. |
| A byte-form that **fits on one line** sitting in a cell of a declared shape — §6's ledger rows do this ten times | ladder step 1's "sub-parts are never classified separately" + row 2 testing the containing unit | **Compliance only — RES-QA7, published, not closed.** Step 1 makes the containing row the unit, so row 2's byte-form exclusion tests the container and never its contents, and row 4's never-matches-source-code bound is never reached. Below one line the rule is a **size filter on verbatim content, not a kind filter**. This is one of the two places the structural claim stops. |
| **Unmarked** normative prose — the same bytes written as ordinary sentences, no fence, no quote, no "verbatim" | the author's declaration that the unit is a byte-form | **Compliance — the other place the claim stops.** Nothing distinguishes an unmarked normative sentence from a binding constraint, so it reaches the contract through row 5 as a `**K-n**` statement. That is a **reformat, not an elimination** — QA's finding, and it stands. The cost is bounded (one sentence ≈ one line, in the shape the contract wants) and the rule is citable, which an opinion was not. It is not a structural guarantee and this row says so. |
| Row 6 cannot be used as a second door | row 6 inheriting row 5's statement definition | **Adequate.** The smuggle QA demonstrated (`**OQ-3's answer**:` + a 115-line fence) now fails row 6 on the same clause it fails row 5 on, and row 6 names a destination and the ledger-gap instruction so the author no longer picks a landing site. |
| This task can ship its own rule without breaching it | **row 4** | **Adequate, and declared.** Row 4's first conjunct is a judgement made by the party that benefits from it; there is no mechanism. It keeps the rule reviewable before it ships, at the cost of one named exception (BF-1). |
| Round history lives in `PM_LOG.md` | typed schema (no changelog section in any of the 7) + PM's return-channel duty + route-back on a `## Round N` heading | **Medium.** |
| Each downstream stage consumes contracts only | dispatch input list (PM prompt + each agent's step 1, incl. six partition templates) | **Medium-strong.** |
| One filename per stage | E4's architect hard rule + E9's PM backstop + V-10 | **Medium-strong.** The name originates in the **architect's design**, so E4 binds the originating actor and E9 keeps the backstop that caught it twice. Residual: three sites still list stage filenames; FR-8 is discharged as **single-valued**, with the PM's pipeline table named as the authority on disagreement. |
| AP-2 audits a delivery that can satisfy it | E29's two template headings | **Medium.** The headings become authorable; the 15-line minimum is measured, published (RES-1, V-12) and **not** tuned — a small delivery can still WARN for the correct reason, and that is the supervisor's call, not this design's. |
| The installed base receives the boundary rule | `/harness-init` only | **Weak for pre-T-18 projects, with a named disposition** (R8). Existing projects get the per-stage schema and triggers via plugin-native agents plus the degradation clause; the cross-stage table arrives at re-init or by hand-copy. |
| Stage docs stay ≤500 lines | **nothing** | **Compliance only.** P-2 proves no check in either shell measures anything under `docs/features/`. |
| An agent could still write an undeclared heading, or paste a 200-line transcript into its rationale | compliance, detected by gate dimension 2 and the code-reviewer's Standards axis | **Weak.** The schema says what a contract *is*; nothing prevents an extra heading. What changed is that a reviewer has a named, single-sourced rule to cite. |

`01` §11 R-3 (a new `I.8` schema check) would convert the last two rows to structural; out of scope by the count freeze, it stays a follow-up candidate.

### Residuals travelling

Both residuals below are **accepted with the corrected grade above** and travel; forcing them closed by a further design round is **declined**
and recorded in `.harness/rejected-decisions.md` under `byte-form-subpart-classification`. The reason is the ruling's: QA-7's corrective
requires the classification rule to see sub-parts, and "sub-parts are never classified separately" exists precisely to close QA-1's
determinism demand, so fixing one reopens the other; asking the structure to decide whether one line of characters is an interface shape or an
implementation literal is asking structure to perform a semantic judgement, and forced closure would buy the remaining few percent by
introducing misclassification — a worse defect than the one it closes. The honest boundary is better than a false total.

| id | statement | must reach |
|---|---|---|
| **RES-QA7** | **The same bytes with the same purpose reach opposite destinations depending on the markdown container they sit in.** §6's **E22** row (`docs/features/stage-contract-split/02_SOLUTION_DESIGN.md:252` — the ledger id is the stable key, the line number is not) offers the exact characters now standing at `skills/harness-goal/SKILL.md:68` and classifies as **contract**, carrying no `## Byte-form specification` entry and no row-4 test result; the same intent written as a blockquote (`docs/features/_archived/stream-defer-human/02_SOLUTION_DESIGN.md:94`) reaches **`no home`**. Nine sibling §6 rows are in the same shape, and the class includes source code. A change-ledger row must quote its target state — that is what a change ledger is for — so this is the boundary of the mechanism, not an oversight in it. | `07_DELIVERY.md` narrative, carrying the corrected grade verbatim; follow-up pool, merged with CR-12 / RES-7 and QA-9 |
| **RES-QA8** | **Two ladder steps name the FR-9 header line, with different destinations.** Step 1 enumerates `> Contract portion.` but triggers on section-membership while the line precedes every section; step 3 matches the same bytes as a `>` run, fuses the header with a persistence note (`03_GATE_REVIEW.md:3-4`, `05_CODE_REVIEW.md:3-5`), and row 5 then rejects that unit → row 14 → rationale. **Observed misroutes: 0** — all six contracts in this folder carry the header correctly — so what is defective is what the ladder *forces*, not what it produced. AC-1 is therefore met in outcome and unmet in the guarantee, and this design publishes that difference rather than resolving it. | `07_DELIVERY.md` narrative; follow-up pool |

---

## 14. Out-of-scope clarifications

This design does not: remove, merge, reorder or parallelise any stage; relax any gate; add or remove
any `verify_all` check; change any numeric size cap; change or tune any AP-2 threshold; add a summary
header of any kind; edit any archived folder or any of the 40 archived deliveries; touch
`docs/proposals/frontier-gaps-2026-07.md`; address the insight-harvester wrapped-bullet defect
(T-20); change any version stamp; create a PowerShell surface; extend `/harness-upgrade` to refresh
rule content (declined, R8); add an "ambiguous contract" rationale trigger at stages 5 and 7
(declined with reason, §5); force RES-QA7 / RES-QA8 closed by a further design round (declined by operator ruling, §13); or retrofit T-18's own folder.

---

## 15. Open-question dispositions

Adopted as recommended: **OQ-1(a)**, **OQ-3(a)**, **OQ-4(a)**, **OQ-5(a)**, **OQ-6(a)**, **OQ-7(a)**, **OQ-8(a)**, **OQ-9(a)**.

**D-1 — OQ-2 overridden from (b) to (a).** The boundary rule's normative text lives in `.harness/rules/70-doc-size.md` (+ its
`/harness-init` template twin), not inside a framework agent, because (i) fragments reach generated projects via the template overlay, not
via `sync-self` (P-1); (ii) a plugin-native `agents/*.md` has **no project-relative path** in a generated project, so the six non-hosting
agents could not read a rule they must **execute** at authoring time; (iii) `70-doc-size.md`'s read-trigger already fires at the decision
point. **AC-11**: exactly one authoring site per distribution channel, under the lockstep discipline this pair already runs (V-4); every
agent points at it **by name and restates no part of it**. Recorded as `boundary-rule-in-agent-file` (declined); its residual is R8, not a reason to reverse D-1.

---

## 16. Partition assignment

Single-Developer mode: `.harness/agents/dev-*.md` — **none exist in this repo** (`AI-GUIDE.md:15`; `Glob` returned no files).
All 29 ledger rows belong to the single `harness-kit:developer`; no dispatch order, no parallelism.
(The six `dev-*.md.tmpl` files in E28 are *templates shipped to generated projects*, not agents here.)

---

## 17. Verdict

**READY.**

Every FR maps to a ledger row: FR-1/FR-9 → §4 + E3–E9, E28; FR-2 → §2 + E1/E2; FR-3 → §3 + E29; FR-4 → §5 + E3–E10, E28; FR-5 → §4 + E9 +
E22; FR-6 → §2's unit ladder + rows 3/4/9; FR-7 → row 10; FR-8 → E4 + E9 + E11/E12; FR-10 → E21; FR-11 → §7. Every AC has a verification step
(§11.1–§11.2). The defects routed here are corrected in the rule text, not by relaxing a criterion: the ordered unit ladder, row 2's byte-form
exclusion, and row 6 inheriting row 5's definition with a destination and a gap instruction; the two stage-7 template headings are E29,
developer-owned, with `agents/supervisor.md:93-101` explicitly out of scope (C-11); the trigger asymmetry is decided in §5.

**§13 states the grade in full: the guarantee is structural for multi-line forms, compliance for anything that fits on one line.** No other
wording of the grade is authorised, here or in `07_DELIVERY.md`. QA-7 and QA-8 travel from §13 as **RES-QA7 / RES-QA8**, published rather than
forced closed; the forced-closure route is declined and recorded in `.harness/rejected-decisions.md` under
`byte-form-subpart-classification`. **AC-1 is met in outcome — 0 observed misroutes — and unmet in the guarantee**, and this verdict says so
instead of closing it. C-1…C-4, C-7, C-9…C-12 remain developer/QA-owned; C-5 and C-6 stay discharged. The one reserved decision — accept the
narrower guarantee or open a further design round — was the operator's, is recorded in `PM_LOG.md`, and is not re-opened here.
