# 05 — Code Review Rationale: stage-model-tiering (T-22)

> Rationale portion for `05_CODE_REVIEW.md`. Non-binding.
> Opened under T5.2 (adjudicating two developer-recorded `DESIGN DRIFT` items) and T5.3.
>
> **Provenance note (PM Orchestrator).** Transcribed verbatim from the code-reviewer's
> returned report; the agent has no `Write` tool. See the note atop `05_CODE_REVIEW.md`.

---

## 1. CR-1 — how the FZ-1′ mutation row's numbers were traced, and every reading I excluded

`04_RATIONALE.md:367-369` declares one method for all five rows: `agents/developer.md` copied to a
scratch directory, mtime pinned back, `model: haiku` appended, "**No file under `agents/` was
written**". FZ-1′ is defined at `02_SOLUTION_DESIGN.md` §8.2's contingency and at
`04_DEVELOPMENT.md:111` as `git diff --numstat -- agents/`.

Candidate readings of `control 156/0` → `mutated 179/0`:

| # | Reading | Predicted values | Excluded because |
|---|---|---|---|
| a | `git diff --numstat -- agents/` on the real tree, mutation applied | 288/130 → 289/130 | Neither cell matches; delta is +23, not +1 |
| b | Same command with the scratch copy in place | unchanged 288/130 | A scratch file outside the work tree is untracked; the path-scoped command cannot see it, and the developer states no `agents/` file was written |
| c | `git diff --no-index --numstat control mutated` | 1/0 | Delta +23 ≠ +1 |
| d | `git diff --no-index --numstat /dev/null <file>` | 91/0 → 92/0 | `agents/developer.md` is 91 lines (capture A5) |
| e | Numstat of `.harness/rejected-decisions.md` before and after this task's own append | **156/0 → 179/0** | **Matches exactly.** `:190` records 179/0 post-append; the append added 23 lines; `04_DEVELOPMENT.md:187-189` records 0 deletions for the file across the whole wave, so 179 − 23 = 156 with 0 deletions is forced |

Reading (e) is the only one that reproduces both cells, both zeros and the delta. `156` also happens
to equal `agents/qa-tester.md`'s line count, which I note only to dismiss: 179 corresponds to no
agent file, and coincidence cannot explain the exact 23 offset.

**The charitable and probably correct account** is that the developer used this task's own edit as
the FZ-1′ demonstration — which is defensible, and is consistent with `04_DEVELOPMENT.md:148-150`
and `04_RATIONALE.md:339-342` both citing this task's `+23`-line edit as the real-data demonstrator
for the FZ-1/FZ-1′ pair. The defect is that a second experiment was placed inside a table that
commits every row to one declared method, with no provenance note, and given a `FIRES ✔` verdict.
Stage 6 is charged with reproducing this independently and will either fail to reproduce it or
mis-attribute it.

**Why MAJOR and not MINOR.** RK-1 names vacuous freeze predicates as the task's top risk; §10.2
item 1 is the highest-value QA item; and the repo's standing truth is that a verification never
observed to fail may be vacuous. An unreproducible cell in exactly that table is the defect class
this pipeline rolled stage 2 back for at G-2 ("a number that traces to no derivation"). The fix is
local — relabel the row with its true provenance, or re-run FZ-1′ under the stated method and report
the real +1 — and belongs in the same round as CR-4/CR-5/CR-6.

**Why not CRITICAL, and why no rollback to stage 2.** AC-6 does not depend on FZ-1′. FZ-2 carries
`[S-A, S-B]` and is genuinely mutation-tested — its control digest `a7fabb1c…9152` matches capture
A6 line-for-line, and FZ-3's and FZ-5's controls match A4 and A5. FZ-1′ is in any case subsumed by
FZ-2 (equal digests imply equal numstat), so removing the row costs the proof nothing.

**Falsifier, stated as required.** If a documented command over `agents/` produces 156/0 for a
control derived from `agents/developer.md`, CR-1 is wrong and I withdraw it. I could not construct
one, and the developer's own "no file under `agents/` was written" excludes the only route I can
imagine.

## 2. Arithmetic I re-derived rather than inherited

Every epoch in the freeze proof converts correctly, which materially raises my confidence in the
captures even where I cannot re-run them:

- `T_dispatch = 1785591045` ⇒ 2026-08-01T13:30:45Z. Cross-check: 2026-01-01T00:00:00Z = 1767225600;
  212 days to Aug 1 = 18 316 800; sum 1785542400; + 48 645 s = 1785591045. ✔ And
  `STREAM_LOG.md:88` reads verbatim `2026-08-01T13:30:45Z · T-22 · dispatching pm-orchestrator ·
  slug=stage-model-tiering · mode=full · ASSESS-FIRST …`, which I read in place.
- `T0 = 1785591621` ⇒ 13:40:21Z; `T0 − T_dispatch` = 576 s = 9 m 36 s. ✔
- `H0_date = 1782025219` ⇒ 2026-06-21T07:00:19Z = 15:00:19+08:00, matching the commit line. ✔
  `T0 − H0_date` = 3 566 402 s = 41.28 d, as claimed (C-1). ✔
- Tightest FZ-3 margins: `1785591621 − 1785579713 = 11 908` (3 h 18 m 28 s) and
  `1785591045 − 1785579713 = 11 332` (3 h 08 m 52 s). ✔ Both as reported.
- Mutation FZ-3: `1785596217 − 1785591621 = 4 596`. ✔

## 3. Is `T_dispatch` a sound anchor?

Yes, for this purpose, and the developer qualified it honestly at `04_RATIONALE.md:134-135` ("a
written record of when T-22 began, not a filesystem attribute, so it cannot be perturbed by a later
touch").

It trades one exposure for another: an mtime can be backdated by `touch`, a log line cannot; a log
line can be edited, an mtime cannot be edited without leaving an mtime. For the specific question
"did any stage of this task write an agent file", the anchor must survive `touch`, so `T_dispatch`
is the better of the two. It is also the **only** anchor available — A7b shows `PM_LOG.md`, the
task's earliest-created artifact, carrying the folder's *latest* mtime, so no filesystem fact marks
the task's start. Independent corroboration: the gate verified `STREAM_LOG.md:88` verbatim at round
2 §1 (G-3(a)) before stage 4 ran, so the line is attested by a document written earlier than the
one relying on it.

## 4. The admissible class, and which members no predicate instantiates

Per the T-20 truth — a regression floor is verified by the class it covers, never the fixture it
runs — I enumerated the class "an `agents/*.md` file was edited by T-22":

| member | covered by | mutation-tested? |
|---|---|---|
| M1 · content edit during `[S-A, S-B]` | FZ-2 | yes, cleanly |
| M2 · content edit during `[T_dispatch, S-A]`, mtime advanced | FZ-3 vs `T_dispatch` | yes |
| M3 · content edit during `[T_dispatch, S-A]`, mtime preserved or backdated | **nothing** | — |
| M4 · edit-and-revert inside `[S-A, S-B]` | **nothing** (all predicates are endpoint-only) | — |
| M5 · new untracked `agents/*.md` | degraded FZ-1 (`??` absent) + FZ-2/FZ-5's eight-file glob | not tested |
| M6 · new non-`.md` file under `agents/` | degraded FZ-1 only; outside AC-6's wording anyway | not tested |

M3 is the member FZ-1 would have covered and now does not, and it is where the drift actually bites.
It is narrowed by evidence already in the record that the developer under-uses: `01` §4.3's stage-1
line counts (293/287) and `02` §8.3's stage-2 counts (all eight) both reproduce exactly at S-A/S-B
via FZ-5, so any M3 edit must have preserved every line count; and the gate's stage-3 live read
(round 2 §2: "not one declares `model:`") excludes the specific declined mutation over stages 0–3.
The uncovered residual is therefore a line-count-preserving, non-`model:` content edit made in stage
0 or 1 with a backdated mtime. That is narrow enough that AC-6 holds — but it is not nothing, and it
should be stated rather than described as airtight, which is why RES-1 travels. M4 was already
conceded in the design's own terms at gate round 2 §3 ("it proves net identity, not the absence of
an edit-and-revert").

**Caveat on the gate's stage-3 read.** I treat it as corroboration, not proof: the same document was
wrong once about a live check (its §3.1 dirty-set claim, read off an elided snapshot). Its round-2 §2
says "I checked that directly" and §3.3 says "re-verified this round rather than inherited", which is
the stronger form, but the failure mode is identical in shape.

## 5. Why DRIFT 1 does not route back to stage 2

Four reasons, in decreasing weight:

1. **§8.2 contingency 1 is the design's own instruction for this exact branch** and says "Do not
   stop." A contingency firing is the design working, not the design failing.
2. **A rollback cannot manufacture the missing evidence.** FZ-1's strength was a content-identity
   statement over `[H0, S-A]`. S-A has passed; no pre-task baseline of `git diff -- agents/` was ever
   captured, and none can be reconstructed now. A redesigned FZ-1 would produce the same S-A/S-B
   numbers the developer already has.
3. **Nothing built changes.** The production surface is 23 appended lines that were frozen at §6 and
   are byte-identical to it.
4. **The upstream defect is already recorded loudly** — as a `DESIGN DRIFT` item, as open issue 2,
   and as the `## Insight to surface` bullet, which is the artifact that survives the archive and
   which states the transferable lesson correctly.

The cost of a rollback here is the `BATCH_PLAN.md:46` shape: process friction against zero change in
the artifact. What is owed instead is precision about the residual, which RES-1 carries.

## 6. Why CR-3 (D-9) is MINOR and not design drift requiring a round

The design's D-9 and its own FZ-4 contradict each other about whether `.harness/rejected-decisions.md`
is dirty; `+23 −0` against `HEAD` is unobtainable for a file already carrying 156 uncommitted
insertions. The developer measured both baselines and disclosed the inconsistency rather than
quietly reporting the number that looked right — which is the behaviour hard rule 7 asks for.

I checked whether the `+23` figure is load-bearing anywhere downstream before ruling: §10.2 item 6
asks QA only for **zero deletions**, which is satisfied against `HEAD` (179/0), and stage 7 consumes
neither figure. **Falsifier:** if any downstream contract row requires reproducing `+23 −0` against
`HEAD` specifically, this becomes MAJOR and the design row needs correcting before archive. I found
no such row.

## 7. Dimensions with nothing to report

Performance (dimension 4) and security (dimension 5) are vacuous for this change and I say so rather
than padding: the artifact is 23 lines of human-read prose appended to a memory file with no parser,
no runtime consumer, no input, no credential and no execution path. `verify_all` wall-clock is
unaffected (I.6's per-entry regex hoisting at `verify_all.sh:680-684` is unrelated to file length at
this scale). Logic correctness (dimension 1) attaches entirely to the freeze proof's predicate logic
and is reported under CR-1/CR-2 and §4 above.
