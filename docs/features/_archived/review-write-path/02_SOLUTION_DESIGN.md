# 02 — Solution Design: review-write-path (T-23)

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

Stages 3 and 5 keep their tool-enforced read-only declaration and gain a **named writer**. The two
review agents remain the **authors** of `03_GATE_REVIEW.md` / `05_CODE_REVIEW.md` and their rationale
siblings; the PM Orchestrator becomes the **writer** that creates the bytes at the declared path,
verbatim, authoring no part. No tool grant changes, no check is added, no file is created on any
distributed surface. The change is three agent contracts stating the same arrangement, plus a
corrected attribution on the one distributed template and the one in-repo sentence that assert
otherwise. A second, in-band statement — the author's final message ends with a header naming the
target paths **and the fidelity constraints on reproducing the body** — makes the arrangement reach
a PM that never loaded the orchestrator contract.

## OQ-1 — decision

**Direction 2 + 3, jointly (rationale candidate (c)): change no capability; state the transcription
duty in `agents/pm-orchestrator.md` and make both reviewer contracts state the same arrangement
plainly.** Directions 1(a) and 1(b) — granting the two review roles `Write` — are **declined**.

`01`'s OQ-1 hands the architect a **two-conjunct** override condition. Conjunct 1 (the protected set
is exactly {upstream stage documents, code and tests under review}) **holds**, read extensionally
from `agents/gate-reviewer.md:74,78`, `agents/code-reviewer.md:87-88`, `agents/pm-orchestrator.md:15`.
Conjunct 2 (a prose statement is no weaker than the tool list) **fails**: only the tool list is
self-enforcing, and `agents/supervisor.md:283` is this repo's one live instance of prose confinement
and mis-states its own basis. The override does not fire. Full argument, including the strongest
case against this choice: `02_RATIONALE.md` §R1. Declines recorded at
`.harness/rejected-decisions.md` (`reviewer-write-grant`, `persist-duty-in-mode-skills`).

**C-6 is a no-op.** The gate adjudicated OQ-1 independently (`03_RATIONALE.md` §R1) and upheld the
decline. Direction unchanged this round, so the `reviewer-write-grant` record and the two
`CONTEXT.md` terms stand exactly as written; nothing about them is revised.

## D-1 · The arrangement

**For stages 3 and 5, the review agent is the author and the PM Orchestrator is the writer.** The
author produces the complete document body and returns it in its final message; the writer creates
or overwrites the bytes at the declared path exactly as returned, authoring no part. Capabilities
unchanged: the two reviewers keep `tools: Read, Glob, Grep`; `pm-orchestrator` keeps
`Read, Write, Edit, Glob, Grep, TodoWrite, Task`.

## D-2 · Role × act table (the arrangement, resolved for AC-3)

| Act | Stage 3 | Stage 5 |
|---|---|---|
| Author the document body (contract portion) | gate-reviewer | code-reviewer |
| Author the rationale portion, when non-empty | gate-reviewer | code-reviewer |
| Emit the target-path + fidelity header at the end of the final message | gate-reviewer | code-reviewer |
| Check the returned body's brackets before writing anything | pm-orchestrator | pm-orchestrator |
| Create `03_GATE_REVIEW.md` / `05_CODE_REVIEW.md`, and `03_RATIONALE.md` / `05_RATIONALE.md` when a rationale portion was returned | pm-orchestrator | pm-orchestrator |
| Correct the document in place on round N ≥ 2 (author the corrected body) | gate-reviewer | code-reviewer |
| Overwrite the path on round N ≥ 2 | pm-orchestrator | pm-orchestrator |
| Record the round (`round N · what changed · why · which finding id`) in `PM_LOG.md` | pm-orchestrator | pm-orchestrator |
| Modify upstream stage docs, code/tests under review, project config | nobody | nobody |

Every cell has exactly one owner; no cell is empty; no contract may contradict a cell.

## Affected modules

- `agents/pm-orchestrator.md` — writer's contract; gains the transcription duty (capped: 294/300).
- `agents/gate-reviewer.md` (114 lines) / `agents/code-reviewer.md` (167 lines) — author contracts.
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` — distributed false attribution (`:51`, `:53`).
- `docs/workflow.md` + `skills/harness-init/templates/common/docs/workflow.md` — one generic
  write-verb sentence (`:18` in each); hand-maintained twins.
- `CONTEXT.md` (two glossary terms) and `.harness/rejected-decisions.md` (two decline records) —
  both completed at stage 2.

No new module. No new file anywhere. `agents/supervisor.md` is **not** touched (OQ-4).

## D-3 · `agents/pm-orchestrator.md` — the writer's duty

The Developer authors the wording; this design states constraints, not bytes (the
`## Stage-doc boundary rule` sends a verbatim prose body for a shipped artifact to *no home*).
Insert **one block immediately after the stage-table paragraph that ends at `:42`**, so a reader of
the stage table meets the duty in the same screen.

| id | The block must state | Satisfies |
|---|---|---|
| P1 | Stages 3 and 5 are named explicitly, and their agents hold no write capability. | R-1, E-1 |
| P2 | Each returns its complete document body in its final message — the contract portion, plus the rationale portion when it is non-empty — under a header naming the target path of each portion present. | R-4 |
| P3 | **You write that body verbatim** to `docs/features/<task-slug>/03_GATE_REVIEW.md` / `05_CODE_REVIEW.md`, and a returned rationale portion to `03_RATIONALE.md` / `05_RATIONALE.md`. | R-2, R-4, AC-2 |
| P4 | No rationale portion returned ⇒ no sibling file exists; the file's absence means none was written. | R-6, B-1 |
| P5 | That transcription adds nothing and repairs nothing: no heading, no summary, no round-record or changelog section, no completion of a body. | R-4, R-10, B-2 |
| P6 | Three conditions make a return non-intact, checked before anything is written: (a) the contract body does not begin with that document's declared opening line; (b) it does not end with its `## Verdict` line; (c) the header names a target path for which no portion is present, or the author reports it could not return whole. On any of them **nothing is written at all** — the round routes back to that reviewer and the reason is recorded in `PM_LOG.md`. | B-4, B-11, AC-8 |
| P7 | On round N ≥ 2 the same duty covers the same path: the content there is replaced, never appended to; the round record still reaches `PM_LOG.md` only. | R-5, B-2, AC-9 |
| P8 | Rows 3 and 5 of the stage table at `:26-34` carry a marker sending a reader of the table alone to this block. | E-7, AC-2 |

### The write-act uniqueness rule (C-1)

The previous round required P3 to be "the only statement in this file that names who writes the
stage-3 / stage-5 documents", which is unsatisfiable against P7, G3/G4 and K3/K4 that the same
design mandates. It is replaced by a scoped, mechanically checkable rule under which AC-10 and
R-5/R-6 both hold:

> **A *write-act statement* is a sentence that both (i) names or addresses the acting role and
> (ii) applies a create / write / overwrite / replace verb to one of the four declared stage-doc
> paths (`03_GATE_REVIEW.md`, `03_RATIONALE.md`, `05_CODE_REVIEW.md`, `05_RATIONALE.md`).**
> Each of the three contracts contains **exactly one**: **P3**, **G1**, **K1**. Every other
> statement bearing on those paths is either **anaphoric** — referring back to it ("that
> transcription", "the same duty") without re-naming an actor — or a **constraint on the act**,
> phrased without re-applying a write verb to the path.

Three consequences, all binding. **(1)** `PM_LOG.md` is **outside scope**: the sentences naming the
PM as its writer (`pm-orchestrator.md:84-88`, `gate-reviewer.md:30`, `code-reviewer.md:32`) name a
different path and act, are needed by R-5/B-2, predate this change, are not edited, and do not
answer AC-1/AC-2. **(2)** R-5 and R-6 are satisfied by the **arrangement**, not by one sentence:
P3/G1/K1 name the role and the anaphors (P7, G3, G4, K3, K4) attach the round-N ≥ 2 and
rationale-sibling cases to it — deleting an anaphor loses a case, deleting the antecedent loses the
role. **(3)** DEV-2 makes it checkable: grep each file for the four path tokens and classify every
hit as *the* write-act statement, an anaphor, or a constraint — exactly one of the first per file.

**Line budget (B-9, AC-7).** Live count: **294**. P8 costs 0 net lines — it edits two existing table
cells. Two condensations inside the same file free 9 net lines:

| id | Site | Change | Why it is not a loss |
|---|---|---|---|
| C1 | `agents/pm-orchestrator.md:140-146` | delete the fenced detection pseudo-block and fold its two branches into the sentence ending at `:139` | **Not** a boundary-rule row-10 deletion, and the previous round's justification was wrong: the fence is *not* a restatement of `:137-139`. `:137-139` says what partition agents are and where they live; the fence adds the branch outcomes, and the none-branch dispatch target `harness-kit:developer` appears nowhere else in `:133-146`. The fold is therefore **content-preserving by obligation** — both branch outcomes must appear in the folded sentence, including the literal `harness-kit:developer` target for the none branch and "dispatch the project-local `dev-*` agents" for the found branch. This clause is load-bearing; the Developer publishes the before/after text. |
| C2 | `agents/pm-orchestrator.md:235-237` | delete the two trailing "Then update `docs/tasks.md`… / Then run `archive-task`…" sentences and one blank line | `:236` restates step 9 at `:181`, `:237` restates step 10 at `:182`, and `:237` mis-cites it as "step 9". The surviving **mode-independent** carrier of the ordering is `:181-182` — *not* `:274-275`, which sits inside `### Entropy watch at delivery (… full mode only)` and which `:241-242` orders `goal` mode to skip entirely. |

Measured sites: C1 is 7 physical lines (`:140` blank, `:141` fence open, `:142-144` body, `:145`
fence close, `:146` blank), C2 is 3 (`:235` blank, `:236`, `:237`) — gross 10, net 9 after the one
line the C1 fold costs. The block **must state all of P1–P7**, targets **≤ 9 lines** and may reach
**12** (294 − 9 + 12 = 297). Post-change the file must measure **≤ 297** by a live `wc -l`, 294
being the target; both counts published in `04_DEVELOPMENT.md` (C-5). If the wording cannot fit 12,
the Developer condenses further inside this file and publishes the site — never appending past the
cap, never dropping a P-item, never moving text to another file.

## D-4 · `agents/gate-reviewer.md` — the stage-3 author's contract

| id | Site | Constraint | Satisfies |
|---|---|---|---|
| G1 | head of `## What you produce` (before `:14`) | The file's **one write-act statement**: you hold no write capability; you return the complete body of both portions in your final message and **the PM Orchestrator writes them** to the declared paths, verbatim, authoring no part. Unconditional — no `if you have no Write tool` clause. | R-2, R-3, AC-1 |
| G2 | `:14-16` | Keep the declared opening line's characters exactly as they stand (its identity is AC-8(a); this design cites it, never re-quotes it). Add that the body you return **is the complete file content, begins with that line and ends with the `## Verdict` line**. | R-10, AC-8(a), B-4 |
| G3 | `:29-30` | Reword **anaphorically**: on a re-review round you return the **corrected complete body**, and the same transcription applies to the same path — its content is replaced, never appended to. Do not re-name the acting role here. The existing round-record sentence ("return the round record … to the PM; the PM writes it into `PM_LOG.md`") is unchanged: `PM_LOG.md` is outside the uniqueness rule's scope. | R-5, B-2 |
| G4 | `:32-33` | Reword **anaphorically**: the rationale portion, when non-empty, is returned in the same message and transcribed to `03_RATIONALE.md` under the same arrangement; its absence means none was written. Keep "written only when non-empty". Do not re-name the acting role here. | R-6, B-1 |
| G5 | `:36-37` | **Delete** the parenthetical. Its content is superseded by G1, and its condition (`if you have no Write tool`) is fixed by `:4` in the same file. | E-5 |
| G6 | `:74` (Hard rule 1) | State the invariant **extensionally**: you do not modify the upstream stage documents, the source code and tests under review, or project configuration — and note that your tool declaration enforces this, rather than resting on the rule alone. Narrow "you do not author" to "you do not author the work you judge", so it stops denying authorship of your own report. | R-7, R-3 |
| G7 | `:57` | State the consequence of each verdict class: every verdict in the declared vocabulary, including each `BLOCKED ON …` form, is written into the document; `BLOCKED ON MODE UNCLEAR` fires before the review runs and produces **no** stage document, only a `PM_LOG.md` record. | B-3, OQ-5 |
| G8 | end of `## What you produce` | End your final message with a header, then the body. The header states: each declared target path **for which content follows**; that what follows is the complete file content for each, to be reproduced exactly, adding and removing nothing; that on a re-review round the content at the path is replaced rather than appended to; and that a body that arrives incomplete is returned to its author rather than written as a partial file. The header **names no role** — G1 stays the file's one write-act statement. | R-2 (in-band), B-4, B-5, C-3 |

**G1 is the sentence AC-10 mutates for AC-1 at stage 3.** Budget: 114 → ≈ 130 lines; cap 300.

**Why G8 carries fidelity and not only paths (C-3).** On R2's path — a main-session PM, which
`skills/harness/SKILL.md:29` contemplates — P5 and P6 are not in context, so R1's mitigation is
absent exactly where R2 says the writer will be; that intersection *is* the T-22 failure (E-10,
E-11). The header therefore carries fidelity and still names no role, satisfying C-1 and C-3 at
once. Two binding limits on the duplication with P3/P5/P6: the header restates **fidelity** only and
must **not** restate the **schema** (section list, headings), which stays in `## What you produce`;
and where header and contract diverge, the contract is authoritative. Residual RES-1; argument in
`02_RATIONALE.md` §R3.

## D-5 · `agents/code-reviewer.md` — the stage-5 author's contract

| id | Site | Constraint | Satisfies |
|---|---|---|---|
| K1 | head of `## What you produce` (before `:14`) | The G1 statement, for `05_CODE_REVIEW.md` / `05_RATIONALE.md`. This file's one write-act statement; it carries no equivalent today. | R-2, R-3, E-6, AC-1 |
| K2 | `:14-16` | As G2, for the stage-5 opening line and its `## Verdict` line. | R-10, AC-8(a), B-4 |
| K3 | `:31-32` | As G3 (anaphoric; `PM_LOG.md` sentence unchanged). | R-5, B-2 |
| K4 | `:36-39` | As G4 (anaphoric), for `05_RATIONALE.md`. | R-6, B-1 |
| K5 | `:88` (Hard rule 2) | Replace "You do not edit any document. Read-only." with the same extensional statement as G6. It must give the same answer as `## What you produce` to "does this role modify its own stage document" — **no: it authors the body, the PM writes it**. | R-7, R-8, E-8, AC-4 |
| K6 | `:95` (workflow step 1) | State that `BLOCKED ON UPSTREAM` is a routing event returned before the review runs and produces no stage document — symmetric with G7. | B-3, OQ-5 |
| K7 | `:108-152` (`## Review document format`) | Re-read the fenced example after K1–K4 and confirm it still matches the schema: it must still show the opening line at `:111`, must end with `## Verdict`, and must gain no round or changelog section. No content change is expected; the check is mandatory because an instruction that lives only inside a schema example is silently dropped by a by-reference reader (T-18 QA-12). | R-10 |
| K8 | end of `## What you produce` | As G8. | R-2 (in-band), B-4, C-3 |

**K1 is the sentence AC-10 mutates for AC-1 at stage 5.** Budget: 167 → ≈ 185 lines; cap 300.

## D-6 · Distributed and in-repo authorship attributions

| id | Site | Constraint |
|---|---|---|
| A1 | `skills/harness-init/templates/common/AI-GUIDE.md.tmpl:51` | The line must not say the gate reviewer **writes** `03_GATE_REVIEW.md`. It names the role as the document's producer and the PM as its writer, in one line, with no net line change. |
| A2 | same file `:53` | As A1, for the code reviewer and `05_CODE_REVIEW.md`. |
| A3 | `docs/workflow.md:18` | "A stage may also **write** an optional sibling rationale portion" quantifies over all seven stages and is false for 3 and 5. The sentence must attribute production rather than writing (or carry the exception). Minimal change; no net line change. |
| A4 | `skills/harness-init/templates/common/docs/workflow.md:18` | Identical change to A3. These two files are byte-identical twins that **no script and no check keeps in lockstep** — `sync-self` mirrors only the eight script pairs, and `verify_all` E.5 checks presence only. Both must be edited in the same round. |

Lines `:49`, `:50`, `:52`, `:54` of that template's agent list keep "writes" — analyst, architect,
developer and QA all hold `Write` (verified across `agents/*.md`).

## D-7 · Glossary and decline records (completed at stage 2)

| id | Site | What |
|---|---|---|
| X1 | `CONTEXT.md` | Two terms the arrangement makes permanent: **Returned body**, **Stage-doc transcription** — with `_Avoid_` synonym lists, in the established entry shape. |
| X2 | `.harness/rejected-decisions.md` | Two records: `reviewer-write-grant` (declined) and `persist-duty-in-mode-skills` (declined). |

Both are written and stand unrevised this round (C-6 is a no-op); they carry ledger rows so the gate
can verify them and the Developer does not re-apply them.

## D-8 · Which build of `agents/*.md` a dispatched stage loads (C-2)

**Observed at this stage** (by `Read` / `Glob` only — this role has no shell):

| id | Observation | Basis |
|---|---|---|
| O-1 | Exactly one plugin-cache build tree exists and its path is **version-scoped**: `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/`, with its own `agents/` and `.claude-plugin/plugin.json`. | glob over `~/.claude/plugins/**` |
| O-2 | The gate's own loaded contract was character-identical to that tree's `agents/gate-reviewer.md:14-32` and materially different from the working tree's `:12-40`. | `03_RATIONALE.md` §R2 |
| O-3 | The marketplace entry's source is `{"source": "github", "repo": "Alan-IFT/harness-kit"}` — the cache is populated from the **published GitHub repository**, not from this working tree. | `.claude-plugin/marketplace.json:12-15` |
| O-4 | Working-tree `plugin.json:4` and `marketplace.json:17` declare `0.46.0`; the newest release commit is `cb0ed57 feat(v0.44.0)`; both files are modified in the dispatch-time `git status`; the cache's only version dir is `0.44.0`. | those files + the dispatch-carried status |
| O-5 | No `.claude/agents/` and no `.harness/agents/` exist here, so no local override can shadow the plugin build. | glob returns nothing for both |

**The statement C-2 asks for.** A dispatched `harness-kit:<name>` stage loads
`~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/<installed-version>/agents/<name>.md`
— a snapshot of the published repository at that version. **Editing `agents/*.md` in this working
tree does not change what any dispatched stage loads.** What makes edited text govern a run is a
four-link chain, none of it in this task's change set: commit → push → the marketplace entry
publishing the new version → `/plugin` update (creating a new version-scoped cache dir) → a new
session. This is a property of the **distribution channel**, invariant across every change this repo
has made to `agents/*.md`, not of this design; migration item 1 is corrected accordingly. The
*cause* of the version gap (dirty tree, pinned cache, or both) needs a shell and is handed over as
**DEV-1**, not assumed here.

**G-10 belongs here.** `01` §0.4 attributes E-10 to the transcriber never having been told the
schema; this run evidences a **second, independent mechanism** — the authoring agent itself running
a pre-schema build of its own contract, so even a correctly-instructed writer receives a body
authored against an older schema. The covering statement is "a callee may not load the *current*
build of its own contract": an **addition** to §0.4, not a contradiction, falsifying no R-* or B-*,
changing no ledger row and leaving every design item above unaffected. **Recommendation: no
route-back to the analyst** — harvest it as a stage-7 insight (`02_RATIONALE.md` §R8); the PM
decides. Carried as RES-4.

## Change ledger

Re-derived by repository-wide search (next section), not inherited from `01`'s §0.

| # | File | Site | Change | Reason | Owner |
|---|---|---|---|---|---|
| L-1 | `agents/pm-orchestrator.md` | `:26-34` rows 3, 5 | mark both rows (P8) | stage table attributes both documents to the reviewers and states no persist duty | dev |
| L-2 | `agents/pm-orchestrator.md` | after `:42` | insert the transcription block (P1–P7), ≤ 12 lines | the writer must learn its duty from the file it loads | dev |
| L-3 | `agents/pm-orchestrator.md` | `:140-146` | delete fence, fold into `:139` (C1), both branch outcomes preserved | frees 6 net lines inside the capped file | dev |
| L-4 | `agents/pm-orchestrator.md` | `:235-237` | delete duplicated tail (C2) | frees 3 lines; also removes a wrong cross-reference | dev |
| L-5 | `agents/gate-reviewer.md` | head of `## What you produce` | insert G1 | AC-1 answerer for stage 3; the file's one write-act statement | dev |
| L-6 | `agents/gate-reviewer.md` | `:14-16` | G2 | body completeness: opening line **and** `## Verdict` line | dev |
| L-7 | `agents/gate-reviewer.md` | `:29-30` | G3 (anaphoric) | round N ≥ 2 attaches to G1's act | dev |
| L-8 | `agents/gate-reviewer.md` | `:32-33` | G4 (anaphoric) | rationale sibling attaches to G1's act | dev |
| L-9 | `agents/gate-reviewer.md` | `:36-37` | delete parenthetical (G5) | conditional on a fact `:4` already fixes | dev |
| L-10 | `agents/gate-reviewer.md` | `:74` | G6 | extensional invariant + internal consistency | dev |
| L-11 | `agents/gate-reviewer.md` | `:57` | G7 | blocked-verdict artifact rule | dev |
| L-12 | `agents/gate-reviewer.md` | end of `## What you produce` | G8 | in-band paths **+ fidelity** (C-3 carrier) | dev |
| L-13 | `agents/code-reviewer.md` | head of `## What you produce` | K1 | AC-1 answerer for stage 5; no equivalent exists today | dev |
| L-14 | `agents/code-reviewer.md` | `:14-16` | K2 | as L-6 | dev |
| L-15 | `agents/code-reviewer.md` | `:31-32` | K3 | as L-7 | dev |
| L-16 | `agents/code-reviewer.md` | `:36-39` | K4 | as L-8 | dev |
| L-17 | `agents/code-reviewer.md` | `:88` | K5 | Hard rule 2 contradicts its own schema section | dev |
| L-18 | `agents/code-reviewer.md` | `:95` | K6 | `BLOCKED ON UPSTREAM` artifact rule | dev |
| L-19 | `agents/code-reviewer.md` | `:108-152` | K7 (verify; no content change expected) | fenced schema example must still match | dev |
| L-20 | `agents/code-reviewer.md` | end of `## What you produce` | K8 | as L-12 | dev |
| L-21/22 | `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` | `:51`, `:53` | A1, A2 | distributed false attribution, both lines | dev |
| L-23 | `docs/workflow.md` | `:18` | A3 | generic write verb, false for stages 3 and 5 | dev |
| L-24 | `skills/harness-init/templates/common/docs/workflow.md` | `:18` | A4 | twin of L-23; nothing keeps them in lockstep | dev |
| L-25 | `CONTEXT.md` | `## Language` | X1 (**done at stage 2**) | the writer/author distinction becomes permanent | architect |
| L-26 | `.harness/rejected-decisions.md` | append | X2 (**done at stage 2**) | two deliberate declines | architect |

**Files deliberately not changed**, each with its reason. Rows marked ⊕ close C-4 (G-4's totality
gap): each carries an audited string, none needs an edit, and AC-5 requires the disposition anyway.

| File | Site | Why unchanged |
|---|---|---|
| `agents/supervisor.md` | `:4`, `:9`, `:283`; `:97`, `:99` | OQ-4 / RES-5: recorded as a residual, not repaired here; the formulation the follow-up applies is **G6/K5**. `:97`/`:99` are the stage-doc validity table — required headings and minimum lines, no authorship attributed. |
| `AI-GUIDE.md` (dogfood) | `:50-51` | carries the arrow chain only; it has no per-agent "writes `0N_*.md`" list to correct |
| `skills/harness/SKILL.md` `:36`,`:38`; `skills/harness-plan/SKILL.md` `:3`,`:32`,`:52-58`; `skills/harness-explore/SKILL.md` `:82` | as listed | "Output: `03_GATE_REVIEW.md`" names the **stage's** output, which the arrangement preserves, and `harness-explore:82` names the Gate Reviewer's job; no writing verb is attributed anywhere in the three |
| `.harness/rules/60-tool-handoff.md` `:32-33`,`:122-127`; `.harness/rules/70-doc-size.md` `:39`,`:109-112` | as listed | a read list and a resume rule (`:122` forbids **editing** a document authored by an upstream agent, which a verbatim transcription authoring no part does not do), plus two **passive** statements attributing no role. Editing a rule fragment would create the E-21 refresh dependency B-7 warns against. |
| ⊕ `…/templates/common/.harness/rules/70-doc-size.md.tmpl` `:38`; `00-core.md.tmpl` `:15`; `_ai-native-prompt.md` `:22-23` | as listed | distributed twins / enumerations: same passive phrasing as the in-repo original, a filename set, and a `RESERVED_NAMES` list. The `70-doc-size` twin is the highest-risk omission of the set — R5 below is about exactly this hand-maintained-twin class — so it is recorded as checked, not missed. (`_ai-native-prompt.md` was found by S2 this round and is not among the gate's four; added for totality.) |
| ⊕ `…/templates/common/.harness/rules/60-tool-handoff.md` | `:32-33`, `:122` | distributed twin of the in-repo `.harness/rules/60-tool-handoff.md` row; read list + resume rule, no authorship attributed. (The gate cited `:34`/`:122`; measured this round as `:32-33`/`:122`. The Developer re-derives live line numbers under AC-5.) |
| ⊕ `skills/harness-init/templates/{backend,fullstack}/.harness/agents/dev-*.md.tmpl` (6 files) | `dev-db:48`, `dev-api:48`, `dev-services:49`, `dev-backend:44`, `dev-db:46`, `dev-frontend:49` | each names `03_GATE_REVIEW.md` in a stage-4 **read list**; no writing or authoring verb, and the arrangement does not change what stage 4 reads |
| ⊕ `skills/harness-supervise/fixtures/{sample-task,sample-task-three-rollbacks}/PM_LOG.md` | `sample-task:29,:43`, `three-rollbacks:29` | test fixtures recording "Output: `03_GATE_REVIEW.md`" for a stage; naming a stage's output stays true under D-1, and editing a fixture would change what the supervisor tests without changing what it tests *for* |
| ⊕ `docs/tasks.md` | `:15`, `:29` | historical task-ledger rows. `:15` is the T-22 row, which records this very defect as an out-of-band finding — it is the evidence trail, not an attribution to repair. Ledger rows are never rewritten. |
| ⊕ `CHANGELOG.md` | `:43` and every earlier hit; **and no new entry** | a released record: historical entries describe what a version did at the time and are never rewritten, and `:43` (the `[0.46.0]` section) describes T-18's read-contract change, attributing no write act for the two documents. No entry is added either — T-21 and T-22 in this same drain added none, `[0.46.0]` is a cut release, and no version claim moves (G.4 asserts version consistency with `plugin.json`). Class-level disposition: no `CHANGELOG.md` line is edited by this task. |
| `docs/dev-map.md` `:132`; `.harness/insight-index.md` `:54-61` | as listed | both passive / historical; the T-22 insight entry stays true under D-1 and entries are not rewritten |
| `agents/{requirement-analyst,solution-architect,developer,qa-tester}.md` | rationale-portion lines; upstream-input lists naming the two filenames | the first are passive and all four roles hold `Write`; the second are read lists with no authorship attributed |
| `docs/*.html`, `README.md`, `README.zh-CN.md`, `docs/concepts.md` | pipeline diagrams and role tables | searched; none attributes a writing or authoring verb to either document |
| `docs/features/_archived/stage-model-tiering/`; `.harness/scripts/*` | — | out of scope §3.4; and no script reads an agent's `tools:` line or an authorship attribution — check count stays 32 |

## Audit-set derivation (R-9 / AC-5)

The Developer **re-runs** these searches at implementation time and reconciles the result against the
ledger above, publishing both. A site added between stage 2 and stage 4 is caught only by the re-run.

| # | Search | What it is for |
|---|---|---|
| S1 | `rg -n '03_GATE_REVIEW\|05_CODE_REVIEW' -g '!docs/features/_archived/**'` | the two filenames |
| S2 | `rg -n 'gate-reviewer\|code-reviewer\|Gate Reviewer\|Code Reviewer' -g '!docs/features/_archived/**'` | the two role names |
| S3 | `rg -ni '(writes\|write\|written\|authors\|produces)[^.]{0,60}(03_GATE_REVIEW\|05_CODE_REVIEW)'` | write verbs bound to the two filenames |
| S4 | `rg -n '0N_RATIONALE\|rationale portion\|rationale sibling' -g '!docs/features/**'` | generic statements quantified over all stages |
| S5 | `rg -n 'tools: ' agents/` | proof that no tool grant moved (AC-11 companion) |

**S1 ∪ S2 is not the audit set, and the reason is finer than the previous round stated.** Measured:
S1 returns `docs/workflow.md:10` and `:12`; S2 returns `:10` — the *file* is found. What neither
returns is **line 18**, the sentence that has to change, which attributes a write verb to "a stage"
generically and names neither filename nor role. A file-level hit is not a site: a Developer working
from S1 ∪ S2 opens the file, finds two true sentences, and has no reason to keep reading. Only S4
returns `:18`. **The insufficiency is at line granularity, not file granularity**; the audit set is
the union of S1…S4.

## Sequence / flow

```
PM ──dispatch(harness-kit:gate-reviewer)──▶ gate-reviewer
                                             │ reads 01,01R,02,02R,AI-GUIDE,rules,insight-index
                                             │ runs the 8-dimension audit; composes the body:
                                             │   contract  (opens with the declared line,
                                             │              ends with the ## Verdict line)
                                             │   rationale (only if non-empty)
                                             ▼
PM ◀─ final message: header (paths + fidelity) + body ─┘        (G8)
 │
 ├─ P6 bracket check, before anything is written — (a) no declared opening line /
 │     (b) no terminal `## Verdict` line / (c) header names a path with no portion present,
 │     or an author-reported partial return
 │     └─▶ write nothing; route the round back to gate-reviewer; record the reason in PM_LOG.md
 │
 ├─ round 1  ─▶ Write  docs/features/<slug>/03_GATE_REVIEW.md   (verbatim, nothing added)
 │             └▶ Write docs/features/<slug>/03_RATIONALE.md    only if a rationale portion came back
 │
 └─ round N≥2 ─▶ overwrite the same path with the newly returned body (no appended section)
                 └▶ append `round N · what changed · why · which finding id` to PM_LOG.md
```

Stage 5 is identical with `code-reviewer`, `05_CODE_REVIEW.md`, `05_RATIONALE.md`. In plan mode the
stage-3 write is the pipeline's terminal act (B-5); the same P3/P6 path runs. **Two writer shapes,
one flow:** a dispatched sub-agent PM holds P1–P8 *and* the G8 header; a main-session PM
(`skills/harness/SKILL.md:29`) holds the header only — which is why it carries fidelity. Both must
produce the same bytes; AC-8 tests both.

## Data model changes

None. No schema, no table, no index, no state file, no new key in `baseline.json`.

## API contracts

The only interface that changes is the **review agent's final message**, by being specified rather
than assumed:

- **Request** — unchanged: the PM dispatch prompt naming the upstream contract files, the mode, and
  the consumer's own rationale-trigger list.
- **Response** — a final message ending with a header that names each declared target path for which
  content follows and states the fidelity constraints (verbatim, complete, add and remove nothing;
  replace rather than append on a re-review round; return an incomplete body instead of writing it),
  followed by the complete file content of each portion. The contract portion begins with its
  declared opening line and ends with its `## Verdict` line; the rationale portion is present only
  when non-empty.
- **Error envelope** — three non-intact conditions, checked before any byte is written (P6): missing
  opening line; missing terminal `## Verdict` line; a header-named path with no portion present, or
  an author-reported partial return. The response to each is a route-back to the same reviewer,
  never a partial write. Size contract: the existing 500-line per-stage-document cap
  (`.harness/rules/70-doc-size.md:31`); no new size or chunking mechanism (OQ-2).
- **Status equivalents** — every verdict in a role's declared vocabulary, including each
  `BLOCKED ON …` form, produces a document. `BLOCKED ON MODE UNCLEAR` (stage 3) and
  `BLOCKED ON UPSTREAM` (stage 5) fire before the review runs and produce a `PM_LOG.md` record only
  (OQ-5).

## Risks and mitigations

| # | Risk | Mitigation (binding) |
|---|---|---|
| R1 | The PM writes the file but reshapes it — the T-22 failure, which produced a document missing its opening line and carrying a `## Round 2` section. | P5 forbids authoring any part; P6 makes a body without its declared opening line or without its terminal `## Verdict` line a route-back rather than a write; G2/K2 make both brackets part of what the author returns. AC-8 measures the produced file, not the contracts. |
| R2 | The writing PM is a main-session agent driven by `/harness` or `/harness-plan` that never loads `agents/pm-orchestrator.md`, so P3–P7 never reach it. | **R1 × R2 composed (C-3):** the G8/K8 header carries the target paths *and* the fidelity constraints, in-band with the payload, so the verbatim/complete/replace-don't-append/return-don't-truncate rules arrive on the R2 path too. AC-8 variant B exercises exactly this shape. Restating P3 in the four mode skills was declined (duplication + ingest cost; `.harness/rejected-decisions.md` `persist-duty-in-mode-skills`). Residual: RES-1. |
| R3 | The condensation frees fewer lines than the block needs, and `agents/pm-orchestrator.md` crosses 300 — a WARN, which `verify_all` exits **1** on. It is a hard release gate. | C1 + C2 free 9 net (10 gross) for a block whose target is ≤ 9 and whose affordable ceiling is 12; the file ceiling is restated as ≤ 297 **measured**; C-5 / AC-7 require a live `wc -l` before and after, published in `04_DEVELOPMENT.md`. Never infer the count. |
| R4 | A prose attribution site is missed, so the repo ships two arrangements — the T-16 failure class, invisible because no gate reads prose. | The audit set is re-derived by S1…S4 at implementation time; the insufficiency of S1 ∪ S2 is named at **line** granularity so the Developer does not stop at a file-level hit. AC-5 requires publishing the derived list, each disposition, and the search; C-4 makes the disposition total over the surfaces G-4 named. |
| R5 | The two `workflow.md` copies drift, because nothing keeps them in lockstep. | A3 and A4 are separate ledger rows on the same round; L-24 states that no script or check pairs them. The same class is why the four ⊕ template-twin rows are dispositioned explicitly rather than left silent. |
| R6 | K5's rewrite of Hard rule 2 weakens the read-only statement into something that reads like permission to edit. | K5 is bound to the **extensional** form: it enumerates the protected set and states that the tool declaration enforces it. AC-4 requires the hard rules and `## What you produce` to return the same answer, and AC-3's table to have no contradicted cell. |
| R7 | A later task widens a reviewer's `tools:` line and nothing notices (no check reads it). | Out of scope by R-11 (no new check). Mitigated in-contract: G6/K5 state that the tool declaration is what enforces the invariant, so a widening contradicts a sentence in the same file. S5 gives the Developer and QA a one-line proof that no grant moved in *this* task. |
| R8 | **Rollout staleness (G-2).** The edited contracts do not govern any dispatched stage until the change is committed, released and the plugin updated, so a reader could believe the fix is live when it is not — and could mistake a stale-build behaviour for a design defect. | D-8 states the four-link propagation chain and migration item 1 carries it. DEV-1 hands the empirical confirmation to the Developer's shell. AC-8's protocol supplies the post-change text explicitly rather than assuming the loader delivers it, and uses the authentic **pre-change** text (the 0.44.0 cache copy) as its differential control. Residual: RES-3. |

### Named residuals

| id | Residual | Bound |
|---|---|---|
| RES-1 | The in-band header **instructs**; it does not enforce. A main-session PM that ignores it can still reshape or truncate a body, and no check detects it (no verification check reads a stage document's opening line). | Detected by AC-8 variant B at stage 6, and thereafter only by a human reading the artifact. Not closable without a capability change, which is declined (`reviewer-write-grant`) — this is the half of the direction `03_RATIONALE.md` §R1 says the design must either close or name. It is named here. |
| RES-2 | **Interior** truncation (G-7). A loss strictly between the opening line and the `## Verdict` line, that preserves every header-named portion, passes P6's bracket check. | Any lost *section heading* is caught by AC-8(b) at stage 6; a loss inside a section that preserves all headings is undetectable at write time. A write-time section-list check was considered and not proposed (it would copy the two schemas into the PM's contract, which is duplication in a capped file — `02_RATIONALE.md` §R4). |
| RES-3 | The plugin **loader path** is not exercised by anything in this task. AC-8 measures whether the arrangement holds when a review stage runs; it does not measure whether a released build carries the edited text. | Discharged after release by a one-line check that the new version-scoped cache dir carries the edited `agents/*.md`. Named here so it is not mistaken for something stage 6 covered. |
| RES-4 | **G-10.** `01` §0.4's mechanism for E-10 is incomplete: a callee may also run a pre-schema build of *its own* contract. Unrepaired here; no route-back recommended (see D-8). | Recorded for stage-7 insight harvest. It changes no requirement statement and no ledger row. |
| RES-5 | **OQ-4.** `agents/supervisor.md:283`'s identical mis-attribution is not repaired. | Its own queued row; the formulation to apply is G6/K5. |

## Migration / rollout plan

1. No data to migrate, no runtime state; the change is contract text. **It does not take effect for
   the next dispatched stage 3 / stage 5** — per D-8, a dispatched stage loads the version-scoped
   plugin-cache build, so the edit governs a run only after commit → push → the marketplace entry
   publishing the new version → `/plugin` update → a new session. Archived tasks are unaffected.
2. **Backwards compatibility.** An installed project generated before this change keeps running: the
   three contracts are plugin-native and ship with the plugin (OQ-3), so no `.harness/rules/*`
   refresh is required and the E-21 gap is not crossed. No normative text lands in a rule fragment,
   so no degradation clause is needed beyond the two already carried (`gate-reviewer.md:39-40`,
   `code-reviewer.md:33-34`) — those stay. On item 1's chain, an installed project receives this like
   any other agent-contract change; the latency is not made worse.
3. **Ordering.** `agents/*.md` first (L-1…L-20), then the attribution sites (L-21…L-24), then the
   audit re-derivation (S1…S4) as the reconciliation step, then `verify_all`.
4. **Rollback.** `git checkout` of the touched files. Nothing is created, so nothing is orphaned.
5. **Feature flag.** None. A flag would mean two arrangements coexisting, which is the defect.
6. **PowerShell.** No `.ps1` surface is created, so the standing operator-obligation list stays at
   **25 (17 numbered plus 8 un-numbered)**, untouched and un-renumbered (AC-12). RES-3's post-release
   cache check is deliberately **not** added to it — EP-002 owns that ledger and is out of scope; it
   is carried here and in `07_DELIVERY.md` instead.
7. **Check count.** 32 before, 32 after, no identifier renamed (AC-11). No script is edited.

## Developer-owned conditions carried forward

| id | Condition | Published in |
|---|---|---|
| C-4 | The AC-5 publication is **total** over every derived site, including the ⊕ rows added to the "files deliberately not changed" table above. No site is left without a stated disposition. | `04_DEVELOPMENT.md` |
| C-5 | Every line count is established by a live `wc -l` **before and after**, for all four agent files touched or cited. Never inferred from line numbering. | `04_DEVELOPMENT.md` |
| DEV-1 | Establish from a shell which build governs a dispatched stage, and publish the commands and their output: `git status --porcelain agents/ .claude-plugin/`, `git log -1 --oneline`, `ls -1 ~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/`, and a diff of the cache copy against the working-tree copy of `agents/gate-reviewer.md`. **If the observation contradicts D-8** — i.e. the cache already carries the working-tree text — say so, and AC-8 reverts to a direct live dispatch with no probe. | `04_DEVELOPMENT.md` |
| DEV-2 | Publish the write-act classification required by the uniqueness rule: for each of the three contracts, every hit on the four declared path tokens, classified as *the* write-act statement / anaphor / constraint. Exactly one write-act statement per file. | `04_DEVELOPMENT.md` |
| DEV-3 | Publish the C1 fold's before/after text, showing that both branch outcomes survive — including the literal `harness-kit:developer` dispatch target for the none branch. | `04_DEVELOPMENT.md` |

## What QA must be able to do

### AC-8 — the acceptance bar, resolved

**Human bar ruling required: NO.** The gate's ask — *"does AC-8 require a dispatch under a released
build carrying the edited contracts, or is a controlled reproduction an acceptable substitute?"* —
is resolvable on D-8's facts and is resolved as **controlled reproduction**. Decisive: stage 6 runs
before delivery, `archive-task`, commit, release and plugin update, so under the released-build
reading AC-8 is unsatisfiable **by construction** for every task in this repo that edits an agent
contract — not a stricter bar but an unexecutable one, demanding verification after delivery. The
substitution is exactly one link (contract text delivered by prompt, not by the plugin loader);
author, body, writer, write and inspected bytes are the production path, and the uncovered link is
RES-3. Full argument, and what would reverse it: `02_RATIONALE.md` §R7.

### AC-8 — protocol (binding)

One act here needs the `Task` tool, which `agents/qa-tester.md:4` does not grant, so the **dispatch
is executed by the PM at the stage-5 → stage-6 boundary** and QA owns the observation and verdict.
Probe artifacts live **outside the repository working tree** (a scratch directory), so `verify_all`'s
document scans and the 32/0/0 tally cannot be perturbed; the only in-repo files touched are this
task's own `01`/`02`, read-only, as the probe's upstream input.

| step | act | actor |
|---|---|---|
| 1 | Dispatch a sub-agent whose prompt carries the **post-change working-tree text of `agents/gate-reviewer.md`, verbatim**, with an explicit precedence line: *this text supersedes any version of this contract already in your context*. The prompt must **not** restate the opening line, the section list, or the no-round-section rule — those must come from the contract text, or the test measures the prompt. | PM |
| 2 | **Variant A (sub-agent-PM shape).** The writer applies the post-change P-block text, supplied verbatim. Write to a scratch path. | PM |
| 3 | **Variant B (main-session-PM shape, R2's path).** Repeat with a writer whose only fidelity information is the returned message itself — no P-block. This is the C-3 composition test. | PM |
| 4 | **Differential control.** Repeat step 1 with the authentic **pre-change** contract text — the 0.44.0 cache copy at `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/agents/gate-reviewer.md`, which is the real pre-change artifact, not a reconstruction. | PM |
| 5 | Hand QA the absolute paths of: each produced file, and each sub-agent's returned body as returned. | PM |
| 6 | Observe on the **bytes**: (a) line 1 is the declared opening line quoted at `agents/gate-reviewer.md:14-15`; (b) every declared section heading of that schema is present; (c) no `## Round N`, changelog, or superseded-finding section; (d) the file is byte-identical to the returned body (P5 authors-no-part); (e) the returned message ended with the G8 header. | QA |
| 7 | **Verdict rules.** Variants A and B must both pass (a)–(e). The control at step 4 **must fail** on (a) — if it passes, the observable is not caused by the contract text and QA reports AC-8 as **NOT EXECUTED**, never as passed. If the PM did not run steps 1–5, QA reports AC-8 as **NOT EXECUTED** and the task is not deliverable. The falsifier of record remains the T-22 artifact, which fails (a) and (c). | QA |

### AC-9 — protocol

Drive a second round against the same probe: return a corrected body for the same path; observe that
the content is replaced, that no round section was appended, and that the round record went to
`PM_LOG.md` only. Run it in variant B too — replace-don't-append is a header constraint, and R2's
path is where it is most likely to be lost.

### AC-10 — the load-bearing sentences, named

Three mutations, one per file, each deleting that file's single **write-act statement** and re-running
the AC-1/AC-2 read. The expected residue is stated so the judgement is not free-form:

| Question | Sentence deleted | Expected residue | Why the question is unanswered |
|---|---|---|---|
| AC-2 | **P3** in `agents/pm-orchestrator.md` | P1 (the reviewers hold no write capability), P2 (they return a body), P4–P7 (all anaphoric to a deleted antecedent), P8's marker pointing at a block with no duty in it | The file establishes that a body arrives and that its author cannot write it, and states **no disposition for it**. The obligation is unstated; the survivors constrain an act the file no longer establishes. |
| AC-1, stage 3 | **G1** in `agents/gate-reviewer.md` | G2 (body completeness), G3/G4 (anaphoric, no role named), G8's header (paths + fidelity, no role by construction) | No sentence names a role in connection with `03_GATE_REVIEW.md` / `03_RATIONALE.md`. The `PM_LOG.md` sentence at `:30` names the PM for a different path and a different act, and does not answer "who writes the stage document". |
| AC-1, stage 5 | **K1** in `agents/code-reviewer.md` | same construction | same |

DEV-2's published classification is what makes this mutation mechanical rather than a reading.

## Partition assignment

No `.harness/agents/dev-*.md` exists here (glob returns nothing; confirmed in `PM_LOG.md`
pre-dispatch checks and by the gate's Q-1), so stage 4 runs in **single-Developer mode** —
`harness-kit:developer` owns every ledger row marked `dev`. No partition split, no dispatch order,
no parallelism.

## Out-of-scope clarifications

This design does **not** cover: EP-002 and EP-003; which stages exist or what any review stage judges
(the 8 gate dimensions, 6 review dimensions, two axes, severity levels and verdict vocabularies are
unchanged in number and wording); `docs/proposals/*.md` and `docs/features/_supervision/*.md`;
retrofitting the T-22 archive; the supervisor's analogous mis-attribution (OQ-4 residual); any new
check, gate, script or state file; a `.harness/agents/` copy of any framework agent;
`/harness-upgrade` gaining a rule-fragment refresh; any tool-grant change to any role; and the
**release and plugin-update acts** that make the edited contracts govern a dispatched stage (D-8,
RES-3) — this task edits the source, it does not ship it.

## Open questions — resolutions adopted

| OQ | Resolution | Deviation from `01`'s recommendation |
|---|---|---|
| OQ-1 | Direction 2 + 3 jointly — candidate (c). Capabilities unchanged. Upheld by the gate's independent adjudication (`03_RATIONALE.md` §R1); not reopened this round. | none; the two-conjunct override was tested and did not fire |
| OQ-2 | No new size or truncation mechanism. The 500-line per-stage-document cap is the size contract; a non-intact arrival routes back via P6, whose bracket check reuses the schemas' own first and last lines rather than adding a protocol. | none |
| OQ-3 | The statement lives in the plugin-native agent contracts, plus in-band in the author's return message (G8/K8) so a skill-driven PM is also reached. | extended: the in-band half is new, carries fidelity as well as paths (C-3), and is why `.harness/rules/*` still needs no change |
| OQ-4 | Not repaired here; residual RES-5, naming **G6/K5** as the formulation the follow-up applies. | none |
| OQ-5 | Every declared verdict produces a document; `BLOCKED ON MODE UNCLEAR` and `BLOCKED ON UPSTREAM` produce a `PM_LOG.md` record only. | extended: `01` named only the gate's pre-review stop; the code reviewer has the same shape at `:95` |

## Verdict

**READY.**

C-1: resolved by the write-act uniqueness rule — satisfiable simultaneously with P7, G3/G4, K3/K4,
and mechanically checkable (DEV-2). C-2: resolved on D-8's facts, acceptance bar settled as a
controlled reproduction whose differential control makes it falsifiable — **no human ruling is
required** — with the loader question handed to a shell-holding stage as DEV-1 rather than asserted.
C-3: fidelity moved into the G8/K8 header, RES-1 naming what remains. C-6: no-op. G-5, G-6, G-7
corrected or bounded in place; G-10 recorded at D-8/RES-4 with a recommendation not to route back;
C-4 and C-5 carried to stage 4. No blocking gap in `01_REQUIREMENT_ANALYSIS.md` was found.
