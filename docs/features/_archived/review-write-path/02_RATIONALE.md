# 02 — Rationale: review-write-path (T-23)

> Rationale portion for `02_SOLUTION_DESIGN.md`. Non-binding.

---

## R1 — OQ-1 adjudicated

The gate re-adjudicated this question independently, assembled a four-point case *for* the write
grant and a three-point rebuttal, and upheld the decline (`03_RATIONALE.md` §R1). The direction is
not reopened, and the two production artifacts it produced — `.harness/rejected-decisions.md`'s
`reviewer-write-grant` record and `CONTEXT.md`'s two terms — stand unrevised (C-6 is a no-op). The
one thing I take from the gate's rebuttal is not a change of direction but a change of obligation:
it rules that a grant would have made E-10/E-11 *impossible* where this direction makes them
*forbidden*, by clauses the design's own R2 concedes the writing PM may never load, and that the
design must either close that half or name it. It now does both — the header carries fidelity
(§R3 below, D-4 G8), and what the header cannot enforce is named as RES-1.

### R1.1 What the invariant protects, established before deciding

Read extensionally from the three contracts rather than from their labels, the read-only invariant
forbids: editing `01_REQUIREMENT_ANALYSIS.md` or `02_SOLUTION_DESIGN.md`
(`agents/gate-reviewer.md:74`); proposing a fix instead of flagging a problem (`:78`); writing code
(`agents/code-reviewer.md:87`); editing "any document" (`:88`); and, from the caller's side,
"downstream cannot edit upstream documents" (`agents/pm-orchestrator.md:15`).

The shared purpose is **independence**: a verifier must not be able to make the work it judges pass
by changing it. Authoring one's own verdict document is outside that set — the report *is* the
judgment, not the work under judgment. Only `code-reviewer.md:88`'s "any document" reads otherwise,
and it does so by a formulation broad enough to contradict its own `## What you produce` section.
I reached the same conclusion as `01_RATIONALE.md` §R1.1 by an independent read, and it is what
lets the design tell the two roles to author their own reports without a carve-out.

This settles what the invariant *permits*. It does not settle OQ-1, because OQ-1 is about what
*enforces* it.

### R1.2 The override condition was a conjunction, and one conjunct fails

`01`'s OQ-1 hands the architect an explicit overturning condition with two conjuncts. Conjunct 1
holds (§R1.1). Conjunct 2 — "a prose statement of that set is no weaker than today's tool-list
statement" — fails, and the evidence offered *for* it is what defeats it:

- `agents/supervisor.md:283` asserts that editing upstream docs is "forbidden by tools whitelist
  anyway". Its own frontmatter is `Read, Write, Glob, Grep` (`:4`), and `Write` creates or
  overwrites any path the role names. So this repo's single live instance of prose confinement
  ships with a **false statement of why it is safe**. Cited as precedent for a grant, it argues
  against one: it shows what the pattern decays into within one release.
- Nothing gates either statement — no check reads an agent's `tools:` line; `verify_all.sh:71-77`
  checks the seven agent files exist and `:447` checks their line count. But the tool list is
  *self-enforcing* at runtime whether or not a check reads it, and a prose sentence is not. The two
  are not equally weak; they are weak in different ways, and only one of them still holds when
  nobody is reading.

So the override does not fire.

### R1.3 The strongest case against the choice I made

Stated at full strength, because it is real:

1. **E-19 is the repo's standing direction and it points the other way.** "A prohibition depends on
   compliance and has nothing enforcing it" (`.harness/rejected-decisions.md:137-146`). Granting
   `Write` makes the record-loss failure *structurally impossible* — there is no transcription to
   omit. Direction 2+3 leaves a duty that depends on the PM complying.
2. **Direction 1 costs nothing in the file that has almost nothing.** `agents/pm-orchestrator.md` is
   at 294 of 300. Direction 2+3 must condense prose other stages depend on in order to afford nine
   lines; that condensation is itself a change with its own risk.
3. **Direction 1 makes the existing prose true for free.** Every "gate-reviewer writes
   `03_GATE_REVIEW.md`" sentence in the repo and in the distributed template becomes accurate with
   zero edits, and no future mention can drift. Direction 2+3 must find and fix those sites now
   (R-9/AC-5) and leaves a permanent prose-lockstep surface that no gate reads — the exact failure
   class T-16 recorded (`.harness/insight-index.md:26`).
4. **The seam disappears rather than being owned.** The entropy scan's own deletion test names
   "widen the two tool grants (removing the seam)" as one of two admissible deepenings
   (`docs/features/_supervision/entropy-2026-08-02.md:40-43`). Deleting a seam is normally the
   better outcome than assigning it an owner.

### R1.4 Why it loses anyway

- **Against (1): E-19 applied symmetrically does not favour a grant.** A grant does not reduce the
  number of compliance-dependent prohibitions; it swaps one for another. It removes a duty whose
  failure is *visible on the produced artifact* — and, after this task, falsifiable by AC-8 and AC-9
  on every future run — and creates an invariant whose failure produces **no artifact at all**. A
  verifier that quietly amends the design it is judging leaves nothing behind for anyone to inspect.
  E-19 prefers structure over prohibition; direction 2+3 *keeps* the structure that already exists
  and converts the remaining prohibition into something measurable. Direction 1 does the reverse.
- **Against (2): the cost is bounded and was budgeted.** B-9 anticipated it and two condensations
  cover it exactly (C1, C2 in the design). Both remove text that the boundary rule's row 10 already
  classifies as a restatement, and one of them removes a wrong cross-reference as a side effect.
- **Against (3): direction 1 has its own prose ledger, and it is not smaller.** R-7 would still
  require every read-only assertion in the three contracts to be restated extensionally — precisely
  because the tool list would no longer say it. That is `gate-reviewer.md:74`, `code-reviewer.md:87-88`
  and `pm-orchestrator.md:15`, plus the now-false parenthetical at `gate-reviewer.md:36-37`. The
  attribution sites that become "free" are traded for invariant sites that become mandatory.
- **Against (4): the seam is not deleted, it is relocated into an unobservable place.** After a
  grant, the question "may this role write outside its own report?" still exists; it simply has no
  answer anyone can check. The deletion test rewards concentrating complexity behind an interface,
  not moving it somewhere with no interface at all.

The tie-break is asymmetry of consequence. The duty's failure mode is a lost or malformed stage
record: loud in retrospect, recoverable, and now falsifiable. The invariant's failure mode is a
silent amendment of the work under judgment: the exact thing the two stages exist to prevent, and
one that no artifact in this repository would ever show. Keep the harder guarantee on the invariant.

### R1.5 What direction 3 contributed beyond direction 2

`01_RATIONALE.md` §R1.4 argues that 3 contains 2. I agree, and found one thing 2 alone does not
cover.

`skills/harness/SKILL.md:29` and `skills/harness-plan/SKILL.md:26` both say the PM Orchestrator is
"**you**, if you're the PM, **or** a dispatched sub-agent". When the main session plays PM directly,
the document it has loaded is the skill — not `agents/pm-orchestrator.md`. Under direction 2 alone,
P3 would sit in a file that writer never opens, which is §0.4's failure re-created one level up.

Three fixes were available:

- **(i) Restate the duty in each mode skill.** Four copies of one sentence (`/harness`,
  `/harness-plan`, `/harness-stream`, `/harness-batch`), all hand-kept in sync, all adding ingest
  cost at dispatch — against the NFR that this task does not spend what T-18 bought. Declined and
  recorded (`.harness/rejected-decisions.md`, `persist-duty-in-mode-skills`).
- **(ii) Point each mode skill at `agents/pm-orchestrator.md`.** The precedent exists
  (`skills/harness/SKILL.md:40` does exactly this for the entropy watch), but in a *generated*
  project a plugin-native agent has no project-relative path, which is the E-20 decline. A pointer
  to a file the reader cannot open is worse than no pointer.
- **(iii) Put the target paths in the author's return message.** ← adopted (G8/K8). The instruction
  travels **in-band with the payload**, so it reaches every caller — sub-agent PM, main-session PM,
  or a future caller that does not exist yet — without any of them having read anything extra.

(iii) is the one that generalises. It is also the closest this design gets to E-19's preference:
the writer cannot hold the body without also holding the statement of where it goes.

The path line is deliberately worded to name **paths only, never the writing role**, so that G1/K1
remain the unique answer to "who writes" and AC-10's mutation stays clean. That is a constraint on
the Developer's wording, not a stylistic note.

## R2 — Reuse audit

| Need | Existing code / text | Path | Decision |
|---|---|---|---|
| A statement of the transcription arrangement | the parenthetical "(You are read-only: if you have no `Write` tool, return both portions… and the PM persists them verbatim.)" | `agents/gate-reviewer.md:36-37` | **Reuse the content, relocate and de-condition it** (G1/G5). It is already the right sentence in the wrong place, wrapped in a condition the same file's `:4` decides. |
| The same statement for stage 5 | (none found — whole-file read of `agents/code-reviewer.md`, no match) | — | New text justified: E-6. It is a copy of G1 with the stage-5 filenames. |
| Round-record handling on re-review | "**Round records.**" block — stage agent returns the record, PM writes it to `PM_LOG.md`, document corrected in place | `agents/pm-orchestrator.md:84-88` | **Reuse as-is.** P7 is an extension of the same block's subject, not a new mechanism; the boundary rule states the same thing passively at `.harness/rules/70-doc-size.md:109-112` and needs no edit. |
| Route-back on a missing/incomplete upstream portion | "A missing **contract** portion is different: route back to the stage that owes it." | `agents/pm-orchestrator.md:82` | **Reuse as-is.** P6 routes a non-intact *return* down the same path rather than inventing an error mode (OQ-2). |
| A size contract for a returned body | 500-line per-stage-document cap | `.harness/rules/70-doc-size.md:31` | **Reuse as-is.** No chunking protocol, no new clause. |
| A degradation clause for an older installed project | "**If `.harness/rules/70-doc-size.md` has no `## Stage-doc boundary rule` section**… apply the schema above as written and proceed. Do not block." | `agents/gate-reviewer.md:39-40`, `agents/code-reviewer.md:33-34` | **Reuse as-is, unchanged.** The design adds nothing to a rule fragment, so no new degradation clause is needed (B-7). |
| A "reference, don't restate" pattern for the orchestrator | the T-05 pattern, live at `skills/harness/SKILL.md:40` for the entropy watch | `agents/pm-orchestrator.md` | **Considered, not used for the duty itself** — see R1.5(ii): the pointer target has no project-relative path in a generated project (E-20). |
| A declared-shape home for the new statements | `## What you produce` schema sections | all three contracts | **Reuse as-is**; every new statement lands in an existing section. No new heading in any agent file. |
| A mechanism to gate authorship attributions | (none found — no check reads prose; `verify_all` G.4 gates count claims only, by a hand-enumerated allowlist) | `.harness/scripts/verify_all.sh:809-878` | **No new mechanism** (R-11). Handled by the S1…S4 re-derivation and AC-5 instead. Extending G.4's allowlist to prose would be EP-003's row, not this one. |

Nothing in `docs/dev-map.md` describes a module that does most of this; the change is contract text
only, which is why the audit is about sentences rather than functions.

## R3 — Risk arguments (the design's table carries the binding mitigations)

- **On R1 (the PM reshapes the body).** T-22 is the measured instance: the transcribed gate document
  lacks the `> Contract portion.` line its own schema mandates and carries a `## Round 2 — re-gate`
  section the orchestrator's own contract routes back. Both are invisible to any reading of the
  contracts — the contracts were *correct* about what the document must contain. That is why AC-8 is
  written against the produced artifact and why the design makes the opening line part of what the
  author returns (G2/K2) rather than something the writer is trusted to prepend.
- **On R3 (the line budget).** The count is not inferred anywhere in this design: 294 / 287 / 167 /
  114 are the last line numbers of full reads of the four files, matching E-15's measured values.
  The Developer still publishes a live `wc -l` before and after, because a `WARN` here exits 1
  (`.harness/insight-index.md:14`) and an architect has previously assumed otherwise.
- **On R4 (a missed attribution site).** The S1∪S2-insufficiency is not hypothetical: I ran both and
  neither returned `docs/workflow.md:18`, whose sentence — "A stage may also **write** an optional
  sibling rationale portion" — quantifies over all seven stages and contains neither filename nor
  role name. S4 found it, and its byte-identical twin in the template overlay, which no script
  mirrors and no check compares. This is the T-16 class (`.harness/insight-index.md:26`) reproduced
  exactly, and it is the reason AC-5 forbids inheriting §0's list.
- **On R1 × R2 (why the header now carries fidelity).** The two risks were separately mitigated and
  never composed. Composed, they say: the mitigation for reshaping lives in a file the writer may not
  have. The previous round bound the in-band line to "paths only, never the writing role" for a
  reason that survives — it keeps G1/K1 the unique answer to "who writes", which AC-10 needs. But
  *paths only* was a stronger restriction than that reason requires: fidelity constraints name no
  role. So the header now carries verbatim/complete/add-nothing, replace-don't-append, and
  return-don't-truncate, and still names no role. This is the only carrier on the main-session-PM
  path, and it is why AC-8 has a variant B: a test that only ever exercises the sub-agent-PM shape
  would pass while the composition failure it was written for stayed live.
- **On B-4's third case (the bracket check).** A tail truncation that preserves the opening line and
  that the author cannot report was previously undetected. The fix costs no new protocol because both
  schemas already end with `## Verdict` — so "begins with the declared opening line and ends with the
  `## Verdict` line" is a bracket built entirely from facts the contracts already state. The header's
  path list closes the remaining tail case: if it names `03_RATIONALE.md` and no rationale portion
  follows, the mismatch is visible without knowing whether a rationale was ever intended, which is
  what made a lost rationale previously indistinguishable from B-1's empty one. Interior loss remains
  open and is bounded as RES-2 rather than papered over.
- **On R8 (rollout staleness).** The design cannot make the edit govern a run; that takes a release
  and a plugin update. What it can do is stop *claiming* it does, publish the propagation chain, and
  make the stage-6 test independent of the loader by supplying the contract text explicitly. The
  differential control is the part that matters: without a run that must fail, "we dispatched an
  agent and got a good file" is unfalsifiable, because a good file is also what a well-behaved agent
  produces from a stale contract plus a helpful prompt.
- **On R7 (a later tool-grant widening).** Out of scope by R-11, and honestly unmitigated at the
  mechanical level. The in-contract mitigation is weak but real: after G6/K5 a widening of the
  `tools:` line contradicts a sentence in the same file, which a reviewer reading that file will
  see. EP-003's derive-the-site-set direction is the shape a real gate would take, and belongs to
  its own row.

## R4 — Fourth framings considered and not proposed

- **Restating AC-10's mutation target as a set of sentences.** The gate offered this as one of two
  ways out of C-1 and deliberately did not choose. Rejected: `01`'s AC-10 says "the single sentence
  that carries the write duty", and an architect may not edit `01`. Reading the criterion as "the
  single sentence *in each contract*" is already what the previous round's three-row table did and is
  the only reading under which AC-1 (per reviewer contract) and AC-2 (orchestrator contract) can both
  be reachable by one criterion. So the fix belongs on the design's side of the boundary: make the
  uniqueness true by construction instead of asserting it, which is what the write-act rule does.
- **Dropping the uniqueness clause entirely and letting G3/G4/K3/K4 corroborate.** This is the other
  way out, and it is the one that quietly fails: AC-10 would then pass at stage 2 on paper and fail
  at stage 6 when a mutation leaves the question answered. The late-rollback shape the gate exists to
  prevent.
- **A write-time section-list check in the PM's contract** (the writer verifies every declared
  heading is present before writing). It would close RES-2, and it is rejected on two counts: it
  copies both reviewers' schemas into a file with three lines of headroom, and it puts the schema in
  two places, so a schema change would silently desynchronise the check — the exact lockstep class
  R-9 exists to fight. The bracket check gets most of the coverage for two clauses and no duplication.
- **Adding the post-release cache check to the standing operator-obligation list.** RES-3 is a real
  post-delivery act, but that ledger is EP-002's row and out of scope, and AC-12 fixes the list at 25
  un-renumbered. Carried in the design and in `07_DELIVERY.md` instead.
- **A script or hook that persists the returned body.** Adds a distributed surface and a
  check-shaped obligation to a task whose NFRs forbid both, and solves nothing the prose does not,
  since the transcription is verbatim. (`01_RATIONALE.md` §R1.6 set it aside for the same reason;
  re-screened here and agreed.)
- **A path-scoped write grant.** Not available in this runtime — B-6 is a property of the tool
  system, not of the contracts. Recorded so the absence is visible rather than assumed.
- **Repairing `agents/supervisor.md:283` opportunistically.** One line, same defect class, and the
  file is at 287 of 300. Declined per OQ-4: the correct wording depends on the formulation R-7
  produces, which now exists as G6/K5, so the follow-up row becomes a one-line application instead
  of a re-derivation. Naming the formulation is the whole value of deferring it.
- **A `CHANGELOG.md` entry in this task.** T-21 and T-22 in the same drain added none; `[0.46.0]` is
  a cut release and no version claim moves. Adding one would either edit a released section or
  introduce a version bump whose claim sites G.4 gates across eleven documents — cost with no
  benefit to this change.

## R5 — Glossary work

Two terms were coined and written into `CONTEXT.md`, because D-1 makes the writer/author
distinction permanent rather than local to this task (the point `01_RATIONALE.md` §R7 named as the
threshold): **Returned body** and **Stage-doc transcription**. The existing entries **Stage doc**,
**Stage contract**, **Stage rationale**, **Rationale sibling**, **Routing log**, **Verdict** and
**Gate** are used as defined and were not altered.

## R6 — Method and reading notes

Read in full: `agents/gate-reviewer.md`, `agents/code-reviewer.md`, `agents/pm-orchestrator.md`,
`AI-GUIDE.md`, `CONTEXT.md`, `.harness/rules/70-doc-size.md`, `.harness/rules/20-documentation.md`,
`.harness/insight-index.md`, `docs/features/_supervision/entropy-2026-08-02.md`,
`01_REQUIREMENT_ANALYSIS.md`, `01_RATIONALE.md`, `PM_LOG.md`.
Read in part: `agents/supervisor.md` (`:88-107`), `docs/workflow.md` (`:1-50`) and its template twin,
`skills/harness/SKILL.md` (`:24-53`), `skills/harness-plan/SKILL.md` (`:24-63`),
`skills/harness-init/templates/common/AI-GUIDE.md.tmpl` (`:40-64`),
`.harness/rules/60-tool-handoff.md` (`:20-49`, `:115-132`), `.harness/rules/25-decision-policy.md`
(decline-habit lines), `.harness/rejected-decisions.md` (`:125-204`),
`.harness/scripts/verify_all.sh` (D.1, I.3, I.6, G.4 regions), `docs/dev-map.md` (structure +
lockstep tables), `CHANGELOG.md` (head + attribution greps), `.claude-plugin/plugin.json`.
Not read in full: the `.ps1` twins (no `.ps1` surface is created), the archived corpora other than
the T-22 references already carried by `01`, the HTML documents beyond a write-verb grep,
`docs/proposals/*` (out of scope).

Line counts (294 / 287 / 167 / 114) come from full reads whose last numbered line is the count, and
they match the values E-15 measured. This stage has no shell; AC-7 assigns the live `wc -l` to the
Developer, and AC-6/AC-11 assign the `verify_all` tally to the stage that can run it — the T-18
RES-4 discipline of handing an execution-requiring claim to the stage that can execute it, rather
than letting the gap decay into an assumption.

Decline filter: `.harness/rejected-decisions.md` read at the index level plus records 125-204. Three
records bear on this task and are honoured rather than re-litigated —
`stage-bloat-prohibitions-only` (E-19, argued against in R1.4 rather than ignored),
`boundary-rule-in-agent-file` (E-20, which is why R1.5(ii) was rejected), and
`upgrade-rule-content-refresh` (E-21, which is why no statement lands in a rule fragment). Two new
records were appended: `reviewer-write-grant` and `persist-duty-in-mode-skills`.

Read additionally in the rework round: `03_GATE_REVIEW.md` and `03_RATIONALE.md` in full;
`skills/harness/SKILL.md` in full (the R2 path); `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`; the plugin cache tree by glob;
`agents/pm-orchestrator.md` `:1-50`, `:76-150`, `:175-189`, `:230-279`; `agents/gate-reviewer.md`
`:1-45`; `agents/code-reviewer.md` `:10-41`; the four G-4 surfaces by search
(`templates/common/.harness/rules/*`, the six `dev-*.md.tmpl`, the two supervise fixtures,
`docs/tasks.md`, `CHANGELOG.md`); and `tools:` across `agents/*.md`, which is what surfaced that
`qa-tester` has no `Task` grant and therefore cannot itself run AC-8's dispatch.

## R7 — the acceptance bar, and why I did not escalate it

The gate framed the AC-8 bar as a human question and said so honestly: it is a bar question, not a
fact question, and under deferred-human mode the gate could not ask it. I was told to resolve it on
the facts if I can, to escalate if I cannot, and to do neither for the wrong reason. The reasoning,
stated so a human can overturn it cheaply if they disagree:

The tempting frame is "strict bar (released build) versus lenient bar (reproduction)". That frame is
wrong, and noticing why is the whole argument. Stage 6 runs before delivery, before `archive-task`,
before the commit, before the release and before the plugin update. So under the released-build
reading, AC-8 is not *hard* — it is **unsatisfiable at the time it is asked**, for every task in this
repository that edits an agent contract, forever. A criterion that no member of its own class can
ever meet is not a high standard; it is a criterion that will be quietly downgraded on first contact,
which is precisely the decay `01`'s closing paragraph warns against ("it must not be allowed to decay
into AC-3, which prose alone satisfies").

So the real choice is between a reproduction and returning AC-8 upstream as unachievable. Returning
it upstream deletes the one criterion that separates "the contracts read consistently" from "the
arrangement holds when a review stage runs" — the distinction the operator's own wording makes the
point of the adversarial section. That is the worse outcome by a clear margin.

What makes the reproduction a real test rather than a courtesy:

1. **The substitution is exactly one link.** Contract text arrives by prompt instead of by the plugin
   loader. Author, body, writer, write, and inspected bytes are all the production path. The loader
   is a packaging property; it is named as RES-3 rather than silently absorbed.
2. **It has a control that must fail.** The authentic pre-change contract is on disk at the 0.44.0
   cache path — not a reconstruction, the real artifact. Run through the same protocol it must fail
   observable (a). If it passes, the protocol is measuring the prompt and QA is required to report
   NOT EXECUTED. Without that arm, "we dispatched and got a good file" proves nothing.
3. **The prompt is forbidden from carrying the answer.** No restatement of the opening line, the
   section list, or the no-round-section rule. The observable must be caused by the contract text.
4. **It is stricter than the naive live reading on the dimension that matters.** A live dispatch
   exercises whichever writer shape happens to run. The protocol runs both, and variant B — writer
   holding only the returned message — is the composition C-3 is about and the shape T-22 actually
   failed in. It also carries an ambiguity the released case does not have (two versions of the same
   contract in one context, resolved by an explicit precedence line), so its failure modes are a
   superset, not a subset.
5. **Its failure is loud.** If the PM skips the probe, QA reports NOT EXECUTED and the task is not
   deliverable. There is no path on which AC-8 silently becomes AC-3.

The one act I could not place inside QA is the dispatch itself: `agents/qa-tester.md:4` grants no
`Task`. Rather than weaken the observable to fit the role, the design splits it — PM performs the
act it already performs on every stage, QA owns the observation and the verdict. Probe artifacts
live outside the working tree so the AC-6 tally cannot be perturbed by the test that proves AC-8.

**If the operator disagrees**, the reversal is one line: AC-8 waits for a post-release, new-session
re-run, and stage 6 reports it as deferred rather than passed. I did not queue that as an ask,
because on the facts above the reproduction is the stronger of the two executable options and the
released-build reading is not executable at all.

## R8 — G-10, and why it is not a route-back

`01` §0.4 says a caller never loads the callee's contract, and attributes E-10 to the transcriber
never having been told the schema. This run adds a second mechanism: the *authoring* agent ran a
pre-schema build of its own contract, so the body it composed was authored against an older schema
before any transcription happened. The covering statement is broader than §0.4's — "a callee may not
load the current build of its own contract."

I do not recommend routing back to the analyst. §0.4 is not falsified; it is incomplete in a way that
changes no requirement statement, no boundary condition, no acceptance criterion and no ledger row —
and §0.4's own operative conclusion ("this narrows where the duty can live") survives untouched,
because both mechanisms point at the same remedy. The design carries the fact where it bears (D-8,
RES-4) and recommends harvesting it as an insight at stage 7, where a cross-task truth belongs. The
PM decides; a route-back would spend a full analyst round to add a sentence that changes nothing
downstream of it.
