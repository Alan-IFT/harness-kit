# 01 — Rationale: stage-model-tiering (T-22)

> Rationale portion. Contract: `01_REQUIREMENT_ANALYSIS.md` (same folder). This file carries the
> derivations, option arguments, measurement narrative, evidence citations and open-question
> candidates that the contract's binding statements rest on. Read by the gate by default; other
> stages read it only on their own named triggers.

---

## R1 — Deriving the delegated share (contract §0.1)

### R1.1 The inputs, and what each one actually measures

| id | Input | What it measures | Source |
|---|---|---|---|
| E-1 | 30-day, three-project bill $1570.15; 10,456 calls; ≈10,420 on the top tier, $0.18 across 21 calls on the cheap tier | Total spend, all projects, all work — pipeline and interactive alike | `docs/proposals/cost-attribution-2026-08.md:19-30`, `docs/batches/default/BATCH_PLAN.md:41` |
| E-2 | Component split: cache read 43.3%, cache write 35.1%, output 21.5%, uncached input 0.1% | How the total decomposes by priced component | `docs/proposals/cost-attribution-2026-08.md:19-26` |
| E-3 | Per-call averages: 127,993 cache-read tokens, 1,272 output tokens | Averaged over **all** 10,456 calls, main loop and sub-agents mixed | `docs/proposals/cost-attribution-2026-08.md:36-40` |
| E-4 | harness-kit project total ≈$540; the six framework roles ≈$36 within it | The report's per-agent attribution | `docs/batches/default/BATCH_PLAN.md:42` |
| E-5 | The $36 is sub-agent **output** and excludes the cached context each sub-agent reads per call; 1.5M observed sub-agent tokens × the output rate ≈ $37.5 reconciles it | What E-4's per-agent number is, and is not | `docs/proposals/cost-attribution-2026-08.md:45-54` |
| E-6 | Directly observed sub-agent token counts across five preceding rows: 200k / 248k / 350k / 267k / 297k | Sub-agent output volume, observed live in the stream; not recorded in any repo file | `docs/batches/default/BATCH_PLAN.md:42` |

E-5 is the trap the dispatch named explicitly, and it is why E-4's $36 is used below only as a floor.
E-6 is not independently re-derivable in-repo: `docs/batches/default/STREAM_LOG.md` records verdicts,
`verify_all` tallies and rollback counts per task, but no token figures.

### R1.2 The derivation, step by step, with the failure point marked

**Step 1 — sub-agent output tokens.** $36 ÷ the output rate ($25.00 / 1M, E-2's basis) ≈ **1.44M
output tokens** attributed to the six framework roles over the window. This corroborates E-6
independently (1.5M observed), which is the one place two sources agree.

**Step 2 — the floor.** $36 of ≈$540 = **6.7%** of this project's bill is directly-attributed
sub-agent output cost. Delegated spend is that plus its cache components, both non-negative, so 6.7%
is a strict floor. This is contract A-1/A-2. It is the only number in the derivation that requires no
assumption beyond the report's per-agent attribution being complete for the six roles.

**Step 3 — sub-agent share of this project's output tokens.** This project is $540 / $1570 = 34.4% of
the bill. **Assumption (weak):** this project's component mix matches the three-project mix in E-2.
Then this project's output cost ≈ 0.344 × $332.50 ≈ $114, and the sub-agent share of project output
is 36 / 114 ≈ **31%**. Contract A-3, LOW confidence — the assumption is weak because this project's
work mix is known to differ: the operator's own interactive debugging, the PowerShell twin runs that
agents cannot execute here, and T-21's direct measurement are all main-loop work concentrated in this
project.

**Step 4 — output share → total-cost share. THIS STEP FAILS.** 78% of the bill is cache traffic, and
cache cost is (calls × context volume per call). Converting a share of output tokens into a share of
cache traffic needs the sub-agent per-call context volume and the sub-agent call count. Neither is
measured. Two structural effects act on it in opposite directions:

- **Raises the sub-agent share:** a stage sub-agent performs many tool calls per dispatch (reads,
  greps, writes, and for stages 4 and 6 test-driver runs), while the orchestrating loop performs a
  handful of routing calls per stage. Sub-agents plausibly make the large majority of calls.
- **Lowers the sub-agent share:** a sub-agent's context is fresh at dispatch and grows only within its
  own turn sequence, while the orchestrating loop's context accumulates monotonically across the whole
  task — every stage's return summary lands in it — and is re-read at that accumulated size on every
  one of its calls. E-3's 127,993-token per-call average is consistent with a small number of very
  heavy accumulating contexts as much as with a large number of moderate ones.

Nothing in the repository discriminates between these. The proposal itself names the missing
instrument: "nothing currently measures per-call context volume … The 128K figure came from dividing
an external report by a call count" (`docs/proposals/cost-attribution-2026-08.md:85-87`).

**Step 5 — the published bound.** Floor 6.7% (step 2). Upper end: if sub-agent calls carried the same
per-call context and per-call output as the average call, output share would equal call share would
equal cache share, giving ≈31%; allowing for sub-agent calls that read heavily and emit little (the
gate reviewer and code reviewer are exactly this shape) pushes the defensible upper end to ≈45%.
Above that requires an assumption no evidence supports. Contract A-5: **6.7% – 45%, best-supported
25–45%, LOW confidence.** The band spans a factor of ≈7.

### R1.3 Why this is published as a bound rather than a number

Manufacturing a point estimate here would have been the easy path and the wrong one. The dispatch
asked for the delegated share because it is the upper bound on the entire benefit; a fabricated
midpoint would have been carried forward by every later stage as though it were measured, and the
verdict would have inherited a confidence the evidence does not support. The insight index's standing
lesson applies directly: a claim asserted rather than discharged is where the counterexample hides
(`.harness/insight-index.md`, guard-cmd-chain CR2-2).

---

## R2 — The break-even derivation (contract §0.2)

### R2.1 Why the delegated share cancels

Let `S` be the delegated share of the bill, `A` the addressable roles' share of a delegated run,
`r` the cheaper tier's input rate divided by the current tier's input rate, and `f` the additional
rollbacks per task the downgrade causes.

- Saving per task = `S × A × (1 − r)`.
- Cost per additional rollback = `S × C`, where `C` is one rollback round's share of a run.
- Break-even: `S × A × (1 − r) = f × S × C`  →  **`f = A(1 − r) / C`**.

`S` cancels. This is the reason contract §0.2 states that the decision does not turn on Finding A —
and it is why an honest "not derivable" was allowed to stand rather than being papered over with a
number the recommendation would then have appeared to depend on.

### R2.2 Measuring `A` and `C` from in-repo evidence

T-20 (`docs/features/_archived/harvest-wrapped-insight/`) is the only complete task archived under the
post-T-18 contract/rationale structure, so its per-stage written-document volume is the closest
available proxy for per-stage work. Line counts, contract plus rationale per stage:

| Stage | Contract | Rationale | Total |
|---|---:|---:|---:|
| 1 requirement-analyst | 324 | 372 | 696 |
| 2 solution-architect | 500 | 316 | 816 |
| 3 gate-reviewer | 386 | 250 | 636 |
| 4 developer | 240 | 485 | 725 |
| 5 code-reviewer | 306 | 127 | 433 |
| 6 qa-tester | 269 | 375 | 644 |
| 7 delivery | 101 | — | 101 |
| **Total (stage docs)** | | | **4051** |
| `PM_LOG.md` (orchestrator-authored) | | | 415 |

- `A` = stages 1 + 2 = 1512 / 4051 = **37.3%**. Treated as a **ceiling**, because written-document
  lines under-count stages 4 and 6 severely: the developer also edits code and runs `verify_all`
  repeatedly, and T-20's QA stage authored a 186-case test driver — none of which appears in a stage
  document's line count. A realistic `A` is nearer 25%.
- `C` = stages 4 + 5 + 6 = 1802 / 4051 = **44.5%**. A rollback returns the task to stage 4 and the
  re-run traverses 4 → 5 → 6.

### R2.3 The result

With `A = 0.373` (the ceiling) and `1 − r = 0.4` (a downgrade to a tier at 0.6× the current input
rate — the shape of the currently-published mid tier; the exact ratio is deliberately not recalled
here, matching the proposal's own discipline of reading rates rather than recalling them):

`f = 0.373 × 0.4 / 0.445 = ` **0.335 additional rollbacks per task.**

Observed rollback counts, `docs/batches/default/STREAM_LOG.md:72-86`: T-13 = 4, T-14 = 3, T-17 = 4,
T-15 = 1, T-16 = 2, T-18 = 3 + 1 escalation = 4. Mean **3.0**, range 1–4, n = 6. So the break-even is
a **≈11% relative increase** in rollback rate. At the more realistic `A = 0.25` it tightens to `f =
0.225`, a **≈7.5%** relative increase.

### R2.4 Why an 11% bar is the decline argument rather than a comfortable margin

An 11% bar is not obviously unclearable — downgrading the requirement analyst and the solution
architect might well cost less than that. The problem is that the claim is **undecidable with the
instruments this project has**. Against a series with range 1–4 and n = 6, separating a 3.0 mean from
a 3.34 mean needs dozens of tasks at minimum, and this project delivers on the order of one task per
few hours in bursts, with the mix of task kinds varying enormously between them. There is no A/B
channel, no rollback attribution per originating stage, and — per contract §0.4 — no way to run the
downgrade on the dogfood repo alone while consumers stay on the current tier.

This is precisely a red-line-6 shape under `.harness/rules/25-decision-policy.md`: a choice assessed
and found genuinely uncertain, with material downside. Under Mode 2 the resolution is to escalate or
to take the conservative side; the dispatch pre-authorized the conservative side as a legitimate
deliverable, so the requirement takes it and records the falsification conditions rather than
deferring the whole task to the human.

---

## R3 — Roles considered and why each was excluded (contract §0.3)

### R3.1 The best structural candidate was tested, not skipped

The supervisor is the strongest downgrade candidate on structure and it was evaluated on its merits
rather than dismissed with the others. It is observer-only (`Read, Write, Glob, Grep`), sits outside
the 7-stage routing, writes exactly one artifact, and cannot cause a rollback because nothing
downstream consumes its output without operator authorization. A downgrade there cannot corrupt a
pipeline run.

It was rejected on two independent grounds. First, magnitude: it runs once per ≥5 delivered tasks, so
even a 40% cut on its line is a fraction of a percent of the bill — below the noise in the delegated
share itself. Second, fit: its actual job is an entropy scan judging where a codebase is rotting,
which is a deep-judgment task, not a mechanical one; the roles that are cheap to downgrade and the
roles that are mechanical are not the same set here.

### R3.2 pm-orchestrator: "never makes professional judgments" is not the whole contract

The PM's own description says it makes routing decisions only, which reads as the ideal downgrade
target. Its contract says otherwise: it owns rollback decisions, the three-consecutive-rollbacks stop,
hard stops on retries and dependencies, and the deferred-human escalation that decides whether a
question reaches the operator at all. The repo has a recorded PM-authored defect of exactly the class
a downgrade would make more likely — a T-13 rollback that originated in a constraint the dispatching
PM invented rather than one traceable to a rule, which the developer then honoured, omitting
anti-revert coverage (`docs/batches/default/BATCH_PLAN.md:46`, "pure process friction, zero yield").
That is positive evidence against, not absence of objection.

### R3.3 The two addressable roles, and the shape of their failure mode

Requirement analyst and solution architect are what remain. The argument against downgrading them is
not that they never err — it is that their errors are the most expensive kind this repo records,
because they are discovered downstream after later stages have built on them. Three entries in
`.harness/insight-index.md` are exactly this: an architect who assumed a `verify_all` WARN was
advisory when it is a hard release gate; a design rule that contradicted its own acceptance criterion
and had to be corrected against the criterion; and a design that mis-predicted the token count its own
anti-vacuity mutation would emit, with the check-level prediction staying right, "which is exactly
what makes the mis-prediction easy to miss". Each cost a rework round — the very quantity `f` in R2.

### R3.4 The verification roles

No positive evidence for downgrading gate-reviewer, code-reviewer or qa-tester was found, and none was
sought by proxy. The dispatch's constraint and the proposal's independent conclusion
(`docs/proposals/cost-attribution-2026-08.md:73-76`) agree, and the insight index's contents are
overwhelmingly findings those three roles raised. The bar is a positive case; there is none.

---

## R4 — Open-question candidates and the argument selecting among them

**OQ-1 · reasoning-effort key.** Candidates: (a) the key exists and stage 2 confirms its name and
value set against the upstream schema before specifying anything; (b) the key does not exist, so only
the model-swap lever is available; (c) treat the dispatch's assertion that it exists as established
and specify wiring against it. (c) is rejected outright — this repo has a standing rule to consult the
upstream schema rather than recall it, written after shipping two real bugs from recalled settings
keys, and stage 1 has no network tool with which to check. Between (a) and (b): the honest state is
unverified, so (a) is recommended, and the classification is NON-BLOCKING because the contract's
recommendation is stable under both. Under (b) the preferred lever simply does not exist and the
remaining lever is the riskier one — which strengthens the decline. Under (a) the R2 break-even is
unchanged, because `f` depends on capability delta and not on which knob produces it.

**OQ-2 · whether `model:` on the PM binds in stream mode.** Candidates: (a) `skills/harness-stream/SKILL.md:122`
is current — the PM is dispatched through the `Task` tool in its own context, so a `model:` on it
binds; (b) `docs/batches/default/BATCH_PLAN.md:58` is current — sub-agents have no `Task` tool, the PM
shell runs in the main thread, and a `model:` on it binds nothing during a stream drain. The two are
in direct contradiction and both are live text in the repository today. (a) is recommended because the
skill is the executable instruction that the drain actually follows and the note is explicitly marked
as carried from T-01 (2026-06), several plugin versions back; also `agents/pm-orchestrator.md:4`
declares `Task` in its tool list, which under reading (b) would be dead frontmatter. Recommending (a)
does not resolve it — a stale note that contradicts a live skill is a defect worth correcting, and
correcting it belongs to a row of its own rather than to this task, which is barred from filing rows.
NON-BLOCKING because the PM is excluded on the independent grounds in R3.2 either way.

**OQ-3 · one record or two.** Candidates: (a) one `## stage-model-tiering` record stating `declined`
for the model swap and `deferred` for reasoning effort; (b) two records, one per lever; (c) a single
blanket `declined`. (b) violates the file's own stated convention of one record per concept and would
leave a future reader unsure which record a re-proposal matches. (c) is dishonest about the deferral —
the reasoning-effort lever is not rejected on its merits, it is unevaluable until OQ-1 and F-1 resolve,
and the file explicitly supports a `deferred` marking for exactly that. (a) recommended. The
`byte-form-subpart-classification` record is the precedent for a single record carrying a nuanced,
two-part decision.

**OQ-4 · filing the measurement row.** Candidates: (a) file a measurement-only pool row for the
per-call context instrument (F-1), in the shape T-21 took; (b) do not file it, leaving the proposal's
note as the only record. (a) is recommended on substance — it is the precondition for verifying
context reduction as well as for re-opening tiering, and the proposal already names it. It is
nonetheless classified BLOCKING-for-the-filing-only, because inventing a new task is scope expansion
under the standing red lines and is reserved to the operator. The requirement records the
recommendation and files nothing, so this task is not gated on it.

**OQ-5 · CHANGELOG / version.** Candidates: (a) neither; (b) a CHANGELOG line without a version bump;
(c) a version bump. The documentation rules tie CHANGELOG obligations to adding a skill and to keeping
docs in sync with actual code; a decline changes no code, no skill, no script, no template and no
check, so nothing falls out of sync. T-10 delivered a decline with no version or count flip and that
stands as the precedent. (a) recommended. (b) is harmless but would place a line in a distributed,
versioned surface describing a change that did not happen.

---

## R5 — What was deliberately not done, and why

**No number was manufactured for the sub-agent share of cache traffic.** It would have filled the slot
the dispatch named, and every downstream stage would have consumed it as measured. The dispatch
asked for confidence to be stated plainly and for an honest "not measurable from inside the repo" to
change the recommendation rather than be papered over; contract A-4 does exactly that, and R2.1 shows
why the recommendation survives the gap.

**The build outcome was not selected because building is visible progress.** The addressable set was
narrowed by evidence, one role at a time, and the best structural candidate (R3.1) was evaluated on
its merits before being rejected on magnitude and fit.

**The decline was not selected because it is cheaper.** The break-even bar it fails is ≈11%, not
≈300% — this is a close call on magnitude, and the contract says so. What decides it is not the size
of the saving but that the payoff hinges on a quantity no instrument here can measure, on a surface
with no per-consumer reversibility. F-1/F-2/F-3 are written as falsification conditions rather than as
a permanent verdict precisely because the arithmetic could come out the other way once those
instruments exist.
