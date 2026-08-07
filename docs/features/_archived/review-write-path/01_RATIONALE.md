# 01 — Rationale: review-write-path (T-23)

> Rationale portion for `01_REQUIREMENT_ANALYSIS.md`. Non-binding.

---

## R1 — The three directions, argued

### R1.1 What the read-only invariant actually protects

The behavioral intent asks that this be established before the requirement takes a position. Read
extensionally from the contracts themselves, the invariant forbids:

- editing `01_REQUIREMENT_ANALYSIS.md` or `02_SOLUTION_DESIGN.md` (`agents/gate-reviewer.md:74`);
- proposing a fix rather than flagging a problem (`agents/gate-reviewer.md:78`);
- writing code (`agents/code-reviewer.md:87`);
- editing "any document" (`agents/code-reviewer.md:88`);
- and, framed from the caller's side, "downstream cannot edit upstream documents"
  (`agents/pm-orchestrator.md:15`).

The **purpose** these share is independence: a verifier must not be able to make the work it judges
pass by changing it. Under that purpose, authoring one's own verdict document is outside the
protected set — the report *is* the judgment, not the work under judgment. Only the code reviewer's
Hard rule 2 reads otherwise, and it does so by a formulation ("any document") broad enough to
contradict its own `## What you produce` section. That contradiction is internal to one file and
exists whether or not the tool grant changes, which is why R-8 states it separately from R-1 … R-7.

So: authoring the stage-3/stage-5 document is **inside** what the invariant permits and **outside**
what it forbids. That finding removes the objection "a reviewer must never write anything" but does
not settle OQ-1, because the question is not what the invariant permits — it is what *enforces* it.

### R1.2 Direction 1 — grant the reviewers a write capability

For:
- Removes the indirection entirely; the role named as author is the role that writes. R-1 … R-6 all
  collapse to one sentence each in the reviewers' own contracts, and the orchestrator needs no
  change at all — which matters, because the orchestrator's contract is the file with six lines of
  headroom (E-15).
- Matches the standing direction at E-19: makes the loss-of-record failure impossible rather than
  forbidding it.
- A precedent exists: the supervisor is described as observer-only and holds `Write` (E-18).

Against:
- **No tool grant in this runtime is path-scoped.** A `Write` grant permits creating or overwriting
  any path the role names, so the grant that lets the gate reviewer write `03_GATE_REVIEW.md` also
  lets it overwrite `02_SOLUTION_DESIGN.md`. Today the tool list makes that impossible; afterwards
  only prose forbids it. This is the trade the intent flags as "a write grant scoped by intention
  rather than by tooling is a weaker guarantee".
- The precedent at E-18 is weaker than it looks in exactly this respect: `agents/supervisor.md:283`
  claims editing upstream docs is "forbidden by tools whitelist anyway", and that claim is not true
  of a `Write` grant. The precedent therefore demonstrates the repo *accepting* prose confinement,
  and simultaneously demonstrates that the acceptance came with a false statement about why it was
  safe. Cited as support for direction 1, it argues both ways.
- Nothing gates it: E-17 establishes that no check reads an agent's `tools:` line, so a later
  widening of a review role's grant would land unobserved.

### R1.3 Direction 2 — name the duty in the orchestrator's contract

For:
- Preserves tool-level enforcement of the invariant for both review roles — the guarantee is
  unchanged, not restated.
- Sites the obligation where §0.4 requires it: in the file the writing role actually loads.
- Repairs the observed failures directly. E-10 and E-11 happened because the transcriber had no
  statement of the schema it was transcribing into; the orchestrator's contract is where such a
  statement is readable at write time.

Against:
- Costs lines in the one file that has almost none (294 of 300, E-15), so it must condense within
  the file rather than append — real work, and work that touches prose other stages depend on.
- Leaves an indirection: a future reader of the gate reviewer's contract still has to follow a
  pointer to learn who writes the file that contract names as its output. R-3 exists to bound this —
  the author's contract must name the writing role, so the pointer is one hop and explicit.

### R1.4 Direction 3 — consistency with no capability change

This is not in fact a separate destination. "All three describe the same arrangement" requires the
arrangement to name a writer; with the capabilities unchanged the writer is the orchestrator; and by
§0.4 the orchestrator must be told in its own contract. Direction 3 therefore *contains* direction 2
and adds the reviewer-side work: the parenthetical at `agents/gate-reviewer.md:36-37` becomes a
plain statement, the code reviewer gains the equivalent, and the code reviewer's Hard rule 2 is
reconciled with its own schema section.

That is the argument for treating 2 and 3 as one recommended resolution rather than as rivals: the
minimal *sufficient* change is direction 3, and direction 2 is its orchestrator-side half. Calling
them separate options would let the task ship half of a sufficient change.

### R1.5 Why the recommendation lands where it does

Two standing directions collide. E-19 prefers structure over prohibition, which favors direction 1.
B-6 says direction 1 buys structural enforcement of the *duty* by surrendering structural
enforcement of the *invariant*. The tie-break is what each guarantee is worth:

- The duty's failure mode is a lost stage record — loud in retrospect, recoverable, and now
  falsifiable by AC-8/AC-9 on every future run.
- The invariant's failure mode is a verifier that can silently amend the work it judges — the
  failure the two stages exist to prevent, and one no artifact in this repository would show.

An asymmetric-consequence argument favors keeping the harder guarantee on the invariant. Hence the
recommendation. It is a recommendation, not a requirement: the architect is handed the exact
overturning condition in OQ-1, and E-18 is the evidence that would carry it.

### R1.6 A fourth framing, considered and not proposed

Splitting the write so the author returns a body and a *mechanism* persists it — a script, a hook,
a template — was considered and set aside before it reached the contract. It adds a distributed
surface and a check-shaped obligation to a task whose constraints forbid both, and it solves nothing
the arrangement's prose does not, since the transcription is already verbatim. Recorded here so the
negative is visible rather than absent.

---

## R2 — Candidate answers for OQ-1

- **(a)** Add `Write` to `tools:` on both review roles; delete the parenthetical; leave the
  orchestrator's contract untouched.
- **(b)** Add `Write` to both roles *and* state the confinement in prose under R-7, accepting that
  the confinement is no longer tool-enforced.
- **(c)** Change no capability; state the transcription duty in the orchestrator's contract and make
  both reviewer contracts state the same arrangement plainly. ← **recommended**
- **(d)** Change no capability; state the duty in a rule fragment both roles already read. Rejected
  ahead of the contract: E-21 means an installed project may never receive it, and E-20 records the
  same class of failure for normative text sited where a reader cannot reach it.

Selecting argument: R1.5.

## R3 — Candidate answers for OQ-2 (size / truncation clause)

- **(a)** Specify a maximum returned-body size and a chunking protocol for oversized returns.
- **(b)** State that the author returns the complete body and the writer transcribes verbatim, with
  no size clause at all.
- **(c)** Name the existing 500-line per-stage-document cap as the size contract, and route a
  non-intact arrival through the missing-contract-portion path that already exists. ← **recommended**

Selecting argument: (a) invents a mechanism for a failure no evidence in this repository records;
(b) leaves the failure unnamed, which is the shape of defect this task exists to close; (c) reuses
two mechanisms that already exist and adds none.

## R4 — Candidate answers for OQ-3 (where the statement lives)

- **(a)** In the plugin-native agent contracts. ← **recommended**
- **(b)** In `.harness/rules/70-doc-size.md` plus its template twin.
- **(c)** Split: the invariant in a rule fragment, the duty in the orchestrator's contract.

Selecting argument: (b) and (c) both cross the refresh gap at E-21 — an installed project that never
refreshes its rule fragments would run reconciled agents against an unreconciled rule. (a) has no
such gap because the plugin ships the agents. E-20's decline does not bite, because under the
recommended OQ-1 resolution no role reads another role's contract: each of the three states its own
half.

## R5 — Candidate answers for OQ-4 (supervisor) and OQ-5 (blocked verdicts)

OQ-4:
- **(a)** Repair `agents/supervisor.md:283` in this task — one line, same defect class.
- **(b)** Record it as a residual for its own row. ← **recommended**

Selecting argument: the behavioral intent names three contracts and the supervisor is not one of
them; the file is at 287 of 300 lines; and the repair's correct wording depends on the formulation
R-7 produces, which does not exist yet. Deferring costs one queued row and buys a one-line
follow-up instead of a re-derivation.

OQ-5:
- **(a)** Every declared verdict, including `BLOCKED ON …` forms, is written into the stage
  document; `BLOCKED ON MODE UNCLEAR` is a routing event recorded in `PM_LOG.md` only.
  ← **recommended**
- **(b)** A blocked review leaves no stage document; the block is recorded in `PM_LOG.md`.
- **(c)** A blocked review leaves a stub carrying only the verdict line.

Selecting argument: (b) contradicts the resume path at E-13, which keys "run gate review" on the
document's absence — a blocked-and-therefore-absent gate document would read as a never-run gate.
(c) invents a fourth document shape. (a) matches what the vocabularies already declare: every
`BLOCKED ON …` form appears in the gate reviewer's own `## Verdict` section, i.e. inside the
document's schema, whereas `BLOCKED ON MODE UNCLEAR` is instructed as a *stop* before the review.

---

## R6 — What the QA stage must not accept as evidence

AC-3 is satisfiable by prose alone: three files can be made to read consistently while the behavior
they describe never runs. The captured failures make the distinction concrete — under the
pre-change arrangement the produced gate document lacked its mandated opening line and carried a
round-record section, and **both** defects are invisible to any reading of the contracts, which were
correct about what the document must contain. Only an inspection of a produced file catches them.
That is why AC-8 is written against the produced artifact and why its falsifier is named from a
real, archived run rather than constructed.

A second trap, from E-22: the lockstep criterion AC-5 must re-derive its site list rather than
consume §0's. §0 enumerated the sites a stage-1 read found; a search run at implementation time is
the only thing that catches a site added between now and then, and prose sites fail silently because
no gate reads prose.

---

## R7 — Method and reading notes

Read in full: `agents/gate-reviewer.md`, `agents/code-reviewer.md`, `agents/pm-orchestrator.md`,
`.harness/rules/70-doc-size.md`, `AI-GUIDE.md`, `CONTEXT.md`, `.harness/insight-index.md`,
`docs/tasks.md`, `docs/features/_supervision/entropy-2026-08-02.md`.
Read in part: `agents/supervisor.md` (frontmatter, hard rules, entropy lens, tail),
`agents/qa-tester.md` (frontmatter, workflow step 1), `.harness/rejected-decisions.md` (index plus
records 128–200), `.harness/scripts/verify_all.sh` (C.2/D.1/D.3/E.2–E.4/I.3 regions),
`.harness/rules/60-tool-handoff.md` (reviewer-referencing lines), the T-22 archive
(`PM_LOG.md` stage-3 and stage-5 blocks, `03_GATE_REVIEW.md` head, header grep across the folder).

Not read: the `.ps1` twins, `CHANGELOG.md`, the HTML documents, the archived corpora of tasks other
than T-22, `docs/proposals/*` (out of scope; the operator-obligation count of 25 is taken from
EP-002's own arithmetic rather than re-derived, since re-deriving it is EP-002's row, not this one).

No glossary term was coined or sharpened; `CONTEXT.md` already carries **Stage doc**, **Stage
contract**, **Rationale sibling**, **Routing log** and **Verdict**, and this document uses them as
defined. The words *writer* and *author* are used in §2 as an explicit local distinction rather than
as new domain terms — if the architect's arrangement makes the distinction permanent, that is the
point at which a `CONTEXT.md` entry earns its lines.

Decline filter: `.harness/rejected-decisions.md` read in full at the index level; three records bear
on this task (`stage-bloat-prohibitions-only`, `boundary-rule-in-agent-file`,
`upgrade-rule-content-refresh`) and are cited as E-19 … E-21. None of the 24 records declines this
task's premise; no record was re-litigated.
