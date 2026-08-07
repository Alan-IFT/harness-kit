# PM Log — T-23 `review-write-path`

- Mode: **full** (stages 1-7)
- Dispatched from: `/harness-stream` drain (deferred-human mode: defer, do not ask)
- Origin: entropy finding **EP-001**, `docs/features/_supervision/entropy-2026-08-02.md`
- Started: 2026-08-02

## Pre-dispatch checks

- `.harness/intervention.md` — **absent** (no pending intervention) at task start.
- `.harness/agents/dev-*.md` — **none found** → single-Developer mode (`harness-kit:developer`).
- `.harness/insight-index.md` — read. Applicable entries surfaced to downstream dispatches:
  - 2026-08-02 · the two review roles are declared `Read, Glob, Grep` with no `Write` tool, so
    `gate-reviewer`/`code-reviewer` cannot create the stage documents their contracts name; the
    orchestrator must transcribe verbatim; latent while both contracts name an unproducible output
    (evidence: T-22, three PM-persisted documents).
  - 2026-08-01 · `verify_all` exits 1 on `warns > 0` — a WARN is a hard release gate, not advisory
    (the 300-line agent cap and 200-line rule cap are therefore blocking).
  - 2026-08-01 · a contract that inherits a schema **by reference** silently drops instructions
    rendered inside the schema example rather than stated as a numbered rule (T-18 QA-12).
  - 2026-08-01 · retiring/relocating a duplicated statement is not finished when the primary site
    is rewired — prose citations of it are a lockstep surface no gate reads (T-16).
- Related historical tasks: **T-22** (`stage-model-tiering`) — the run in which this fired;
  **T-18** (`stage-contract-split`) — introduced the contract/rationale sibling that EP-001's
  "written only when non-empty" clause refers to.

## Stage ledger

| Stage | Agent | Round | Verdict | Decision |
|---|---|---|---|---|
| 1 | requirement-analyst | 1 | **READY** (5 OQs, all with `Recommended:`, none blocking) | **Advance to stage 2.** |

### Stage 1 → 2 decision

`01_REQUIREMENT_ANALYSIS.md` + `01_RATIONALE.md` written by the analyst itself (it holds `Write`).
R-1 … R-12 are stated capability-neutral so all three candidate directions remain satisfiable;
AC-8/AC-9/AC-10 are the QA-owned adversarial set and AC-8 is the criterion that separates "the
contracts now read consistently" from "the arrangement holds when a review stage runs".

Two findings beyond EP-001's own text, both measured on the T-22 archive, carried forward to the
architect: the transcribed `03_GATE_REVIEW.md` lacks the `> Contract portion.` opening line its own
schema mandates (E-10), and carries a `## Round 2` section the orchestrator's own contract tells it
to route back (E-11). Plus E-8: `code-reviewer.md`'s hard rule 2 contradicts its own
`## What you produce` section, independent of tooling.

**PM ruling on OQ-1 escalation.** OQ-1 (which direction) is a design-direction judgment that would
normally be a decide-point. It is **not** escalated: the dispatching brief pre-authorised it verbatim
("Weigh both; do not assume the first is right because it is simpler … a well-argued minimal change
is a better outcome than a large one") and requires the chosen direction plus its reasoning in the
return summary. The architect decides it on evidence; the gate adjudicates. No `NEEDS-HUMAN`.

- `.harness/intervention.md` re-checked after stage 1 — **absent**.

| 2 | solution-architect | 1 | **READY** (26 ledger rows + 16 no-change dispositions) | **Advance to stage 3.** |

### Stage 2 → 3 decision

`02_SOLUTION_DESIGN.md` + `02_RATIONALE.md` written by the architect itself.

**OQ-1 decided: direction 2 + 3 jointly — no capability changes.** The reviewers stay
`Read, Glob, Grep` and become the *authors*; the PM becomes the named *writer*. The architect tested
the analyst's two-conjunct override condition and published the result: conjunct 1 (the invariant's
protected set is exactly {upstream stage docs, code and tests under review}, so authoring one's own
report is outside it) **holds**; conjunct 2 (a prose statement is no weaker than the tool list)
**fails**, and E-18 is what fails it — the repo's only live prose confinement
(`agents/supervisor.md:283`) ships with a false statement of its own basis. A conjunction with one
false conjunct does not fire, so the grant was declined. Strongest counter-case published against
itself at `02_RATIONALE.md` §R1.3.

Architect finding beyond the requirement: a main-session PM driven by `/harness` or `/harness-plan`
never loads `agents/pm-orchestrator.md`, so direction 2 alone re-creates the §0.4 failure one level
up. Resolved in-band (G8/K8: the author's final message ends with the target paths, naming paths
only so G1/K1 stay the unique answer to "who writes" and AC-10's mutation stays clean).

Also: the audit set S1 ∪ S2 is **insufficient** — `docs/workflow.md:18` attributes a write verb to
"a stage" generically and contains neither filename nor role name; only S4 finds it, and its
template twin is kept in lockstep by nothing.

**PM note carried to the gate:** the architect performed two live production edits during stage 2
(`CONTEXT.md` glossary terms, `.harness/rejected-decisions.md` decline records — ledger rows
L-25/L-26, both marked `owner: architect`, `done at stage 2`). PM does not rule on whether that is
within the architect's scope — the gate is asked to adjudicate it explicitly.

- `.harness/intervention.md` re-checked after stage 2 — **absent**.

| 3 | gate-reviewer | 1 | **BLOCKED ON DESIGN** — 2 CRITICAL, 2 MAJOR, 4 MINOR, 3 CLEARED | **Rollback #1 → solution-architect (round 2).** |

### Stage 3 round 1 — PM transcription record

The gate holds `tools: Read, Glob, Grep` and has no `Write`. It returned both portions in its final
message; **PM wrote `03_GATE_REVIEW.md` and `03_RATIONALE.md` verbatim, authoring no part.** Both
returned bodies were checked against the declared opening lines at `agents/gate-reviewer.md:14-15`
and `:33` before writing — both matched, all five declared contract sections present, no round or
changelog section — so no route-back on schema grounds. This is the very behaviour the task is
reconciling; it is recorded here as the round's provenance rather than inside either document.

### Stage 3 → 2 rollback decision

Routing per the rollback table: **gate finds design gap → solution-architect**. The gate adjudicated
OQ-1 independently and **upheld** the decline of the write grant (`03_RATIONALE.md` §R1, four-point
case for the grant, three-point rebuttal) — so the block is on completeness of the chosen direction,
not on the choice. The architect is not being asked to reopen OQ-1.

Architect-owned conditions carried into round 2: **C-1** (G-1 CRITICAL — the AC-10 uniqueness
constraint is unsatisfiable: P3 is required to be the only statement naming who writes, while P7,
G3/G4 and K3/K4 all name the PM as writer, so the mutation leaves AC-1/AC-2 answered), **C-2**
(G-2 CRITICAL — a dispatched stage loads the plugin **cache** build, not the working tree, so an
edit to `agents/*.md` does not govern a run and AC-8/AC-9 carry an undischargeable precondition),
**C-3** (G-3 — R1 × R2 never compose: on the main-session-PM path P5/P6 are never loaded, so the
fidelity mitigation is absent exactly where the writer is), **C-6** (if the direction changes, the
already-applied `reviewer-write-grant` record and `CONTEXT.md` terms must be revised in the same
round — it does not change, so this is a no-op, but stated).

Developer-owned conditions deferred to stage 4: **C-4** (AC-5 publication total over the four
surfaces G-4 names), **C-5** (live `wc -l` before and after — the gate had no shell).

**G-8 CLEARED — PM's stage-2 scope question answered.** The gate ruled the architect's live edits to
`CONTEXT.md` and `.harness/rejected-decisions.md` squarely inside its own contract
(`agents/solution-architect.md:70` directs both), correctly shaped, and correctly carried as ledger
rows so the Developer does not duplicate them. No remedy.

### PM decision on the AC-8 acceptance-bar question — deferred, not decided

`03_RATIONALE.md` §R7 frames a candidate `NEEDS-HUMAN` ask: *does AC-8 require a dispatch under a
released build carrying the edited contracts, or is a controlled reproduction an acceptable
substitute?* Consulted `.harness/rules/25-decision-policy.md` (Mode 2) and
`.harness/decision-rubric.md` at this decide-point.

PM does **not** decide it and does **not** escalate it yet. Reasoning: the gate routed C-2 to the
architect as its owner, and the architect has not yet had its round. Escalating before the owning
stage has attempted a resolution would spend the operator's attention on a question that may not
survive the round. The architect is therefore instructed to resolve C-2 **and to state explicitly
whether its resolution requires a human bar ruling**. If it does, PM escalates
`BLOCKED: NEEDS-HUMAN` with the gate's verbatim ask. PM will not substitute a weaker bar to avoid
blocking — the dispatching brief's constraint ("testing whether the reconciled arrangement actually
holds when a review stage runs — not just whether the contracts now read consistently") is an
explicit user constraint, and quietly letting AC-8 decay into AC-3 would engage red line #4.

- `.harness/intervention.md` re-checked after stage 3 round 1 — **absent**.

| 2 | solution-architect | 2 | **READY** (rework; `02` now 499 lines, `02_RATIONALE` 348 — both under the 500 cap) | **Re-gate (stage 3 round 2).** |

### Stage 2 round 2 — round record (returned by the architect, written here per contract)

`round 2 · solution-architect · design rework` — corrected in place, no `## Round N` section added.

| what changed | why | finding |
|---|---|---|
| D-3's "P3 must be the only statement that names who writes" replaced by a scoped **write-act uniqueness rule** (a write-act statement names the actor *and* applies a write verb to one of the four declared stage-doc paths; exactly one per contract = P3/G1/K1). P7, G3/G4, K3/K4 rewritten as **anaphors** ("the same duty", "the same transcription"); `PM_LOG.md` explicitly out of scope. AC-10 restated as three per-file mutations with the **expected residue** published. New DEV-2 makes it grep-checkable. | the old constraint was unsatisfiable against statements the same design mandates; uniqueness is now true by construction, keeping R-5/R-6 | C-1 / G-1 |
| New **D-8** states which build a dispatched stage loads (version-scoped plugin cache from the published repo, O-1…O-5) and the four-link propagation chain; migration item 1 corrected to "**it does not take effect for the next dispatched stage**"; new risk R8; AC-8 re-specified as a 7-step **controlled-reproduction protocol**; DEV-1 hands the empirical build question to a `Bash` stage. | migration item 1 was false; AC-8/AC-9 carried an undischargeable precondition | C-2 / G-2 |
| G8/K8 now carry **fidelity constraints** alongside the target paths (verbatim / complete / add-nothing, replace-don't-append, return-don't-truncate) while still naming no role; R2 composed with R1; residual **RES-1** names what the header cannot enforce. | on the main-session-PM path P5/P6 are never loaded — the T-22 failure exactly | C-3 / G-3 |
| S1∪S2 headline corrected — the *file* is found (`:10`, `:12`); what is missed is **line 18**. Insufficiency is at line granularity. | the headline overstated the claim the section exists to record | G-5 |
| C2's authority moved from `:274-275` (inside the subsection `goal` mode skips) to `:181-182`; C1 re-justified as **not** a row-10 restatement — the fold is content-preserving by obligation, including the `harness-kit:developer` none-branch target. New DEV-3 requires the before/after text. | both justifications were wrong; the outcomes are safe | G-6 |
| B-4's third case handled by a **bracket check** (body must begin with the declared opening line *and* end with its `## Verdict` line; every header-named path must have a portion present). Interior loss named as **RES-2** with its bound. | tail truncation preserving the opening line passed P6 undetected | G-7 |
| G-10 recorded at D-8 + RES-4 + `02_RATIONALE.md` §R8, with a stated recommendation **not** to route back to the analyst. | §0.4 is incomplete, not falsified — no R-*/B-*/AC-*/ledger row changes | G-10 |
| C-4's four surfaces **plus a fifth found this round** (`_ai-native-prompt.md:22-23`) added to "files deliberately not changed"; C-5 + new DEV-1/2/3 collected in a Developer-owned conditions section. | AC-5's ledger must be total | C-4, C-5 / G-4 |
| C-6 confirmed a **no-op** in one line; `reviewer-write-grant` and the two `CONTEXT.md` terms unrevised. | OQ-1 upheld by the gate; direction not reopened | C-6 / G-8 |

### PM ruling on the deferred AC-8 escalation — NOT escalated, and why

The architect resolved C-2 without requesting a human ruling and published the determination as a
labelled line (`02_SOLUTION_DESIGN.md` §"AC-8 — the acceptance bar, resolved": *Human bar ruling
required: NO*). PM ratifies **deferring the escalation to the gate's round-2 adjudication** rather
than escalating now, on this reasoning:

- The decisive fact is structural, not preferential: stage 6 runs **before** delivery, `archive-task`,
  commit, release and plugin update, so under the released-build reading AC-8 is unsatisfiable **by
  construction for every task in this repo that edits an agent contract**. That is an *unexecutable*
  bar, not a stricter one — it would demand verification after delivery.
- The substitute is behavioural, not prose: a real sub-agent runs a review stage under the
  post-change contract text, returns a body, the PM writes it, and QA observes **the bytes** —
  including (d) byte-identity between produced file and returned body, which is the P5
  authors-no-part property. That satisfies the operator's wording ("actually holds when a review
  stage runs") in substance; AC-3 is the prose-satisfiable criterion and is separate.
- It carries a **must-fail differential control** on the authentic 0.44.0 pre-change artifact, so a
  pass cannot be produced by anything other than the contract text — the T-16 lesson that a fixture
  producing the expected verdict is not evidence unless the rejected rule actually fails it.
- The one link genuinely not exercised — the plugin **loader** path — is published as **RES-3**
  rather than quietly absorbed, so nothing decays into "the contracts read consistently".

Red line #4 is therefore not engaged: the operator's constraint is met in substance and the residual
is named. Under Mode 2 this is covered by the rubric's "sound software engineering — correctness,
real tests, honest reporting" and "verify before declaring done". **The gate is nonetheless asked to
adjudicate the bar explicitly in round 2; if the gate rules a human ruling is required, PM escalates
`BLOCKED: NEEDS-HUMAN` and stops.** PM has not substituted its own judgment for the gate's.

### PM obligations created by the round-2 design (noted so they are not missed)

- **AC-8/AC-9 require a PM act.** `agents/qa-tester.md:4` grants no `Task`, so the probe dispatch
  belongs to the PM at the stage-5 → stage-6 boundary; QA owns the observation and the verdict. If
  the PM skips it, QA is bound to report AC-8 **NOT EXECUTED** and the task is not deliverable.
- Probe artifacts must be written **outside the repo working tree** so the AC-6 32/0/0 tally and the
  freeze evidence cannot be perturbed. PM will use the session scratchpad.

- `.harness/intervention.md` re-checked after stage 2 round 2 — **absent**.

| 3 | gate-reviewer | 2 | **APPROVED WITH CONDITIONS** (8 findings cleared, 8 new MINOR, C-1/C-2/C-3/C-6 met) | **Advance to stage 4.** |

### Stage 3 round 2 — round record (returned by the gate, written here per contract)

`round 2 · re-gated the reworked 02/02R in place: verdict moved BLOCKED ON DESIGN → APPROVED WITH
CONDITIONS; G-1, G-2, G-3, G-4, G-5, G-6, G-7, G-10 cleared after independent re-verification, G-9
downgraded to open-pending-C-5 after my own round-1 line count failed to reproduce, eight new
findings recorded (G-12 … G-19), conditions C-1/C-2/C-3/C-6 marked met, C-4/C-5 carried, C-7 … C-10
added; ruled explicitly that the controlled-reproduction protocol satisfies the operator's AC-8 bar
and no human ruling is required · why: the write-act uniqueness rule survives a fresh paper mutation
in all three files, D-8's propagation chain re-verified against marketplace.json/plugin cache, the
must-fail control artifact opened and confirmed to must-fail, and the released-build reading of AC-8
is unexecutable by construction before delivery rather than merely stricter · findings: G-1, G-2,
G-3, G-4, G-5, G-6, G-7, G-9, G-10, G-12 … G-19`

PM transcribed both portions verbatim, **correcting the round-1 documents in place** — same paths,
content replaced, no appended round section. Both returned bodies checked against their declared
opening lines before writing; both matched.

### PM ruling — the AC-8 escalation is now closed, not escalated

The gate ruled explicitly (`03_RATIONALE.md` §R7): the controlled-reproduction protocol **satisfies
the operator's stated bar; no human ruling is required.** It published the case *for* escalating and
why it loses, and verified rather than accepted the architect's premise — it opened the 0.44.0
control artifact and confirmed it declares no opening line and none of the five schema section
names, so the control **must** fail. Decisive for PM: the architect did not weaken the criterion to
fit an executable shape — it **added** observables (d) and (e), a must-fail control, a variant-B arm
and a prompt-contamination prohibition, none of which `01`'s AC-8 required. A resolution stricter on
every axis except the one that cannot execute is not a downgrade, and red line #4 is not engaged.
PM therefore does **not** return `BLOCKED: NEEDS-HUMAN`. Recorded as a Mode-2 autonomous call:
*point* — whether the AC-8 acceptance bar needed a human ruling; *options* — escalate and stop /
accept controlled reproduction; *choice* — accept, with RES-3 naming the loader path as uncovered;
*rubric basis* — "sound software engineering — correctness, real tests, honest reporting" and
"verify before declaring done", neither irreversible (the reversal is one line) nor rubric-uncovered.

### PM routing ruling on G-10

The gate accepted the architect's recommendation **not** to route back to the requirement-analyst,
and the routing decision is PM's. **PM accepts it.** G-10 (a callee may run a pre-schema build of
its *own* contract — a second mechanism `01` §0.4 does not cover) falsifies no R-*, B-*, AC-* or
ledger row, and §0.4's operative conclusion survives because both mechanisms point at the same
remedy. It is a cross-task truth, not a requirement statement, so its home is the stage-7 insight
harvest (RES-4), not an analyst round. Routing back would spend a full stage to add one sentence to
an evidence section of a document already verdicted READY.

### Rollback ledger to date

| # | Stage rolled back | Cause | Consecutive at that stage |
|---|---|---|---|
| 1 | 2 (solution-architect) | gate r1 `BLOCKED ON DESIGN` — G-1, G-2 CRITICAL | 1 |

Stage 2 has been rolled back **once**. The three-consecutive-rollback stop (Hard rule 3) is not
engaged. Noted for the record because the gate flagged the T-18 oscillation lesson.

- `.harness/intervention.md` re-checked after stage 3 round 2 — **absent**.

| 4 | developer | 1 | **READY FOR REVIEW** — `verify_all` **PASS 32 / WARN 0 / FAIL 0**, exit 0 | **Advance to stage 5.** |

### Stage 4 → 5 decision

Stage gate satisfied: stage 4 shows `verify_all` PASSED, quoted from the run and identical to the
pre-change baseline (same 32 check identifiers, no script in the change set). Six files changed —
the three agent contracts, the distributed `AI-GUIDE.md.tmpl`, and both `workflow.md` twins.

Conditions discharged, with three corrections the developer made **against inherited figures**:

- **C-5** — base was **293, not 294**. Three of four inherited counts were high by one
  (`supervisor`'s 287 matched only by coincidence). Final `296 / 125 / 177 / 287`, all under the
  300 cap, I.3 PASS. Also C1 frees **5** net lines, not 6 — `:140` and `:146` are the paragraph's
  two separator blanks and one must survive the fold. The two errors happened to cancel. This is
  exactly why the gate withdrew its own 294 as unmeasured and made C-5 load-bearing.
- **DEV-1 confirms D-8 and sharpens it.** All 8 cache agents are **byte-identical to `HEAD`**, and
  `HEAD` *is* the v0.44.0 release commit — so the gap is **not** a lagging publish, it is entirely
  uncommitted working-tree state; the `0.46.0` claim lives only in two dirty JSON files. Link 1
  (commit) is the unstarted one. No contradiction with D-8; AC-8 stays the controlled reproduction.
  Every negative came from a live command, never a carried snapshot.
- **C-4 needed a correction before it could be discharged.** `02`'s **S1 as literally written
  returns nothing under any `.harness/` path** — `rg` skips dot-directories — so it silently dropped
  all six `dev-*.md.tmpl` files, both `60-tool-handoff.md` copies, `00-core.md.tmpl`,
  `_ai-native-prompt.md` and `70-doc-size.md.tmpl`: precisely the ⊕ rows C-4 exists to cover, while
  still returning enough to look complete. Re-run with `--hidden`; publication is total.
- **DEV-2 / C-10** — exactly one write-act statement per file (P3, G1, K1); all 17 path-token hits
  classified. P8's marker was authored as a bare pointer, so the reword conditional never fired.

**Two deviations carried to stage 5, one needing a reviewer ruling:**

- **DESIGN DRIFT 1 (K7) — the mandatory fence re-read bit, against the design's prediction.** After
  K2, `agents/code-reviewer.md` contradicted itself: the schema says the body "begins with" the
  `> Contract portion.` marker, but its own worked example opened with `# Code Review` and put the
  marker third — so a stage-5 body written as its own contract demonstrates would trip P6(a) and be
  routed back unwritten. The developer deleted the H1 from inside the fence (2 lines). This is the
  T-18 QA-12 class exactly: an instruction rendered *inside* a schema example rather than stated as
  a rule. **PM routes the ruling to the code reviewer** — it changes the shape of every future
  `05_CODE_REVIEW.md`; if stage 5 prefers relaxing the bracket to "carries" instead, that is a
  route-back to the architect, not a developer edit.
- **DESIGN DRIFT 2 (trivial).** C2's `:236` specificity ("append a one-line entry referencing this
  folder") that G-12 flagged as lost was folded into step 9 in place at zero line cost.
- Noted out-of-scope: the same schema/example mismatch appears in `agents/developer.md` and probably
  the analyst/architect/QA contracts. Untouched; wants its own queued row if DRIFT 1 is upheld.

- `.harness/intervention.md` re-checked after stage 4 — **absent**.

| 5 | code-reviewer | 1 | **APPROVED** (3 MINOR + 3 NIT per axis, no CRITICAL/MAJOR) | **Advance to stage 6.** |

### Stage 5 round 1 — PM transcription record

Code reviewer holds no `Write`. It returned both portions **under a K8 fidelity header** — the new
arrangement's own in-band mechanism, working on its first live use. PM wrote `05_CODE_REVIEW.md`
and `05_RATIONALE.md` verbatim, authoring no part; both bodies checked against their declared
opening lines first.

**DRIFT 1 ruled: UPHELD.** Deleting the H1 is correct; `begins with` stands; **no route-back to the
architect.** Decisive argument (`05_RATIONALE.md` §B): a `carries` predicate is satisfiable by a
*quotation*, and `agents/code-reviewer.md:122` is itself a quoted marker inside a fence — so
relaxing the bracket would re-open G-7 for the price of a cosmetic. The reviewer also found a
**fourth** site the relaxation would have had to edit (`CONTEXT.md:54-58`'s `Returned body` term)
and **corrected the developer's scope claim**: `agents/developer.md` is *not* in the class (it
carries no fenced example). Queued row for the operator: settle H1-vs-marker ordering once across
all seven contracts (`agents/qa-tester.md:15` vs `:92-93` is a live contract-internal contradiction;
stages 1/2 produce H1-first artifacts).

### Stage 5 → 6 boundary — AC-8 / AC-9 probe EXECUTED by PM

`agents/qa-tester.md:4` grants QA no `Task`, so the design assigns the dispatch to the PM. Executed
in full; QA owns the observation and verdict. All artifacts outside the working tree (**C-8** met) —
scratch root `…/scratchpad/ac8/`. Nothing was written under the repo by any probe arm; no probe
touched this `PM_LOG.md`.

**C-7 — probe type published: `general-purpose`** for all five dispatches. Chosen precisely because
it carries **no competing build** of either contract under test; `harness-kit:gate-reviewer` /
`harness-kit:pm-orchestrator` would have loaded the 0.44.0 cache build and turned the differential
control into a partial no-op.

| arm | contract text supplied | result |
|---|---|---|
| author, post-change | working-tree `agents/gate-reviewer.md`, verbatim + precedence line | body opens with the declared marker, carries **all five** declared sections, **no** round section (round record returned separately), G8 header emitted |
| author, control | authentic `0.44.0` cache build, verbatim + precedence line | body opens `# 03 — Gate Review …`, sections `## 1. Audit checklist` … `## 4. Verdict`, **no** `## Binding conditions`, no marker anywhere |
| writer A (holds shipped P-block) | — | 3 pre-write checks PASS → wrote verbatim; round 2 **replaced in place**, 2-line delta by diff, round record → `PM_LOG.md` only, nothing added |
| writer B (**no P-block — the T-22 main-session-PM shape**) | — | wrote **byte-identical** (`cmp` clean, sha256 `fd5ff7f0…`, 81 lines/17693 bytes); round 2 replaced not appended; `grep 'round 2'` on the document returns **0**; round record → `PM_LOG.md` only |
| writer, control body | holds shipped P-block | **routed back, wrote nothing** — checks 1 and 2 failed; repaired nothing |

**The differential control must-failed, as required.** Variant B is the load-bearing arm: a writer
whose *only* fidelity information was the reviewer's in-band header persisted the body byte-identical
and added nothing — the C-3 composition test passing on the exact path T-22 failed on.

**C-11 does not fire.** Both writers independently applied the **verdict-token** reading of the
terminal bracket and both independently flagged G-20's two-way readability rather than silently
reinterpreting. **No compliant body was routed back**, so the gate's `BLOCKED ON DESIGN` trigger is
not met. Per C-11's own wording a pass here is *not* evidence of unambiguity — it travels as a
residual.

**Confound PM flags to QA, unresolved by PM.** The post-change author arm reported that its
`tools: Read, Glob, Grep` line was violated because it held a shell, and raised it as a finding
against the design's "only the tool list is self-enforcing" premise. PM's observation, offered as
evidence not as a ruling: that arm was dispatched as `general-purpose` with a contract **pasted as
prompt text**, and pasted frontmatter is inert — it is not a tool grant. QA must adjudicate whether
this is a real property of the runtime or an artifact of the reproduction method **before** it can
become an insight. This is the T-16 class: a fixture producing a striking result is not evidence
until the alternative explanation is excluded.

- `.harness/intervention.md` re-checked after stage 5 and after the probe — **absent** both times.

| 6 | qa-tester | 1 | **PASS — APPROVED FOR DELIVERY** (7 defects, 0 BLOCKER/CRITICAL/MAJOR) | **Advance to stage 7.** |
| 7 | (PM) | — | **DELIVERED** | `07_DELIVERY.md` written; `docs/tasks.md` updated; `archive-task` run. |

### Stage 6 → 7 decision

Stage gate satisfied: stages 5 and 6 both PASS. QA re-ran `verify_all` itself — **PASS 32 / WARN 0 /
FAIL 0, exit 0**, four runs, identifier sequence byte-stable (md5 `3c71cadb914686c248a60ec4d9e71a28`)
and equal to the developer's, closing RES-A. AC-7 by live `wc -l` over all eight contracts, max 296.

**AC-8 PASS on (a)–(c)**, the independent schema-absolute observables. QA added corroboration
stronger than the design specified: variants A and B are **byte-identical to each other**
(`3f1aac85…`) despite holding different instruction sets — non-self-referential evidence that does
not depend on (d), which C-9 required be recorded as captured by the party under test. (e) reported
**NOT MEASURED** per C-12, never as passed. AC-10 re-cut on working copies: 1 write-act statement per
shipped file → **0** in every mutant, with CR-5's corrected residue.

**QA adjudicated the confound against the claim.** G-25 is an **artifact of the reproduction method**:
15 stage-3/5 documents across ≥13 genuine dispatches record read-only tooling, **zero** counter-
instances, and the cache build a real dispatch loads declares the same grant — so both conditions ran
under the same `tools:` line and differed only in dispatch type. The strong claim was kept out of
permanent memory; only the narrow corollary (a contract delivered as *text* carries no tool
enforcement) survives, filed as QA-4. QA also named what would reverse it. This is the T-16 discipline
applied correctly, and PM's counter-observation was tested rather than accepted.

**C-11 did not fire** — both writers took the verdict-token reading, no compliant body was routed
back. QA nonetheless built a reproducer showing the heading reading fails **5/5** on every conforming
document in the repo, so the residual is quantified rather than asserted. **QA-7: RES-4 fired a fourth
time** — QA's own loaded contract is the 0.44.0 build, which would have made its report open
`# Test Report` with no marker line: the exact E-10 shape this task exists to prevent, observed from
inside the stage that measures it.

**RES-D closed positively.** A scoped `git diff --stat` is path-level only here (HEAD is v0.44.0, so
the hunks carry T-18…T-22 — the whole `docs/workflow.md` paragraph holding A3 is a T-18 addition and
A3's edit inside it is invisible). Footprint established by wording fingerprint: 6 files for this
task's wording, exactly 2 twins for A3/A4. **The dirty set was never read as evidence** — the T-22
lesson applied. QA left zero footprint; `baseline.json` sha256-identical.

### Stage 7 — delivery

Composed `07_DELIVERY.md` (`## Summary` / `## Insight` / `## Verdict`, per the working-tree schema —
`07` declares no opening marker line, so `# Delivery Summary` is correct and is *not* in the
H1-vs-marker class the code reviewer scoped). Four insights harvested, each wrapped-multi-line (the
harvester preserves continuation lines and counts a wrapped bullet as one entry).

**Entropy-watch cadence deliberately NOT run** — the dispatching `/harness-stream` drain owns that
boundary and instructed the PM not to run it. No `entropy-cadence` call was made from this task.

### Final rollback ledger

| # | Stage | Cause | Consecutive at that stage |
|---|---|---|---|
| 1 | 2 (solution-architect) | gate r1 `BLOCKED ON DESIGN` — G-1 (unsatisfiable AC-10 uniqueness constraint), G-2 (dispatched stages load the plugin-cache build) | 1 |

One rollback total. Hard rule 3 never approached. No `BLOCKED: NEEDS-HUMAN` was returned: the one
candidate escalation (the AC-8 acceptance bar) was resolved on structural facts by the architect and
**independently adjudicated by the gate**, which published the case for escalating and why it loses.
PM deferred rather than pre-empting, and ratified only after the gate ruled.
