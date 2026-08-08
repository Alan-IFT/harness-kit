# PM Log — T-24 operator-obligation-home

- Mode: `full` (7 stages)
- Dispatched from: `/harness-stream` drain (deferred-human mode: defer, do not ask)
- Origin: entropy finding **EP-002**, `docs/features/_supervision/entropy-2026-08-02.md` (Strong)
- Gate baseline captured before dispatch: `verify_all` bash **PASS 32 / WARN 0 / FAIL 0**

## Task start (2026-08-02)

Intervention check #0 (before stage 1): `.harness/intervention.md` **absent** — nothing to consume.

Read at task start:
- `AI-GUIDE.md`, `.harness/insight-index.md` (30 entries), `.harness/rules/70-doc-size.md`,
  `.harness/decision-rubric.md` (Mode 2 active), `.harness/rejected-decisions.md` (headings + the
  four records nearest this concept), `docs/tasks.md`, `docs/features/_supervision/entropy-2026-08-02.md`,
  `.harness/scripts/baseline.json`, `docs/proposals/operator-powershell-checklist.md`.

Related historical tasks (from `docs/tasks.md`):
- **T-23 review-write-path** — the immediately preceding row; also an entropy finding (EP-001),
  also closed by *relocating a statement to one home* rather than adding capability. Precedent for
  the shape this row is asked to take.
- **T-16 / T-13 / T-12 / T-20** — the four-row hook-wiring wave that eliminated hand-synchronised
  byte-form copies by giving the fact one home (`hook-spec`). The brief names this wave as the
  precedent to follow.
- **T-11c entropy-watch-persist** — declined a standalone open/fixed findings store
  (`.harness/rejected-decisions.md#entropy-findings-store`). Directly adjacent to this task's
  question 2 (completion state) and must be read before answering it.

Insight-index entries surfaced to downstream dispatches:
- 2026-08-01 · `verify_all` exits 1 on `warns > 0` — the 200-line rule-fragment cap is a hard
  release gate, not advisory.
- 2026-08-02 · `rg` skips dot-directories by default — any "the audit set is total" claim must
  state which form of the search produced it; `--hidden` is not optional here.
- 2026-08-02 · A dispatched sub-agent loads the version-scoped plugin cache, not the working-tree
  `agents/*.md`.
- 2026-08-02 · A `git status` snapshot in session context is elided mid-list; a negative taken off
  it is unsound.
- 2026-08-01 · `archive-task`'s harvester preserves wrapped bullets (superseding entry) — multi-line
  insight entries are safe.

## Stage ledger

| # | Stage | Agent | Dispatched | Outcome |
|---|---|---|---|---|
| 1 | Requirement analysis | `harness-kit:requirement-analyst` | 2026-08-02 | **READY** — R-1…R-17, AC-1…AC-13, OQ-1…OQ-8 (none blocking), 5 residuals |
| 2 | Solution design | `harness-kit:solution-architect` | 2026-08-02 | **DESIGN COMPLETE** — all 8 OQs ruled, 25-row transcription map, 7 new residuals |
| 3 | Gate review r1 | `harness-kit:gate-reviewer` | 2026-08-02 | **BLOCKED ON DESIGN** — 2 FAIL, 3 MAJOR, 4 WARN, 6 INFO, 1 deferred needs-human; 10 binding conditions |
| 1r2 | Requirement rework | `harness-kit:requirement-analyst` | 2026-08-02 | **READY** — 12 in-place corrections, total re-derived independently at 25, RES-6 added |
| 2r2 | Design rework | `harness-kit:solution-architect` | 2026-08-02 | **READY** — eight re-issued from the enumerating source; contract 512 → **510** (did not grow) |
| 3r2 | Gate re-review | `harness-kit:gate-reviewer` | 2026-08-02 | **APPROVED FOR DEVELOPMENT** — conditional on BC-8…BC-18; 1 MAJOR + 5 WARN + 8 INFO, no FAIL |
| 4 | Development | `harness-kit:developer` | 2026-08-02 | dispatched (single-developer mode) |

### Stage 1 record

Intervention check #1 (after stage 1): `.harness/intervention.md` **absent**.

Outcome: **advance to stage 2.** No rollback. Verdict READY; all eight open questions carry
actionable `Recommended:` answers and the analyst certifies none blocks design.

Load-bearing correction the analyst made to the dispatch brief (E-4/E-5): **obligations 1–11 are
not in `baseline.json` at all.** Items 1–10 live in `_archived/guard-cmd-chain/04_DEVELOPMENT.md`
across three round sections; item 11 is only *named* in
`_archived/hook-truth-verify-scope/07_DELIVERY.md:122`. So the set is assembled today from **five**
documents, not one file — which strengthens rather than weakens the finding. It also exposes a
**third** error in the drifted convenience index that the index does not know about: its origin
table attributes "1–11 (established)" to `_qa_note_t12`, which contains no numbered list.

Files the analyst wrote: `01_REQUIREMENT_ANALYSIS.md`, `01_RATIONALE.md`, plus three inline term
additions to `CONTEXT.md` (Operator obligation / Obligation ledger / Discharge) — permitted by
`AI-GUIDE.md`'s "maintain it inline when you coin or sharpen a term".

PM routing note: the analyst has no shell, so every execution claim was correctly deferred
(RES-1…RES-5). Those travel to stages 4 and 6, not to the architect.

### Stage 2 record

Intervention check #2 (after stage 2): `.harness/intervention.md` **absent**.

Outcome: **advance to stage 3.** No rollback; the architect did not return `BLOCKED ON REQUIREMENTS`.

Rulings: OQ-1…OQ-8 all **adopted**, three of them with the analyst's argument corrected rather than
inherited — OQ-2 split into two registers (ids 1–17 must stay **bare integers** because archived
citations of those are ordinal; only the eight take an origin prefix), OQ-5 gained a repair the
analyst missed (excising `_qa_note_t20`'s span orphans the antecedent of its kept trailing
sentence), and OQ-8's decisive leg was **replaced** because the analyst's version ("the predicate
does not exist") is falsifiable in one line; the architect measured the imperative-verb candidate
and showed the kept kind-2 text is lexically imperative too.

Design surfaces: ledger at `.harness/operator-obligations.md` (seven field lines per entry, no
table — transcribed text contains `|`); count command `grep -c '^- Id: '`; `baseline.json` edits all
intra-line so the file stays 31 lines; `agents/pm-orchestrator.md` **byte-unchanged at 296/300** by
design, and the architect states a PM line would be a rollback to stage 2, not a developer call.

Two developer traps now binding in the contract: **K-22** (`baseline.json` is *already* dirty in the
working tree, so `git show HEAD:` is not AC-8's reference — copy the file aside before the first
edit) and **K-10** (in the `guard-cmd-chain` archive, "item 11" means that task's design residual,
not operator obligation 11).

Disclosed by the architect against its own interest: the contract is **512 lines** against
`70-doc-size.md`'s 500-line per-stage-doc policy — policy without a mechanism (no `I.*` check
measures `docs/features/`). Recorded here; the gate rules on it, not the PM.

PM note on stage 3 dispatch: `gate-reviewer` is declared `Read, Glob, Grep` and **has no `Write`
tool** (insight 2026-08-02; the T-23 fix that names the PM as writer is edited in the working tree
but governs no run until commit → publish, since a dispatched sub-agent loads the version-scoped
plugin cache). The PM therefore transcribes the gate's returned body **verbatim** into
`03_GATE_REVIEW.md` and authors no part of it.

### Stage 3 record — gate round 1: BLOCKED ON DESIGN

Intervention check #3 (after stage 3): `.harness/intervention.md` **absent**.

Both returned bodies persisted verbatim by the PM: `03_GATE_REVIEW.md` and `03_RATIONALE.md`. PM
authored no part of either.

**The decisive finding (G-1, FAIL) came from a source neither upstream document consulted.** The
design derived the eight T-13 obligations from `_qa_note_t13` — but T-13's own delivery
(`_archived/hook-truth-spec/07_DELIVERY.md:72`) calls that note a **mirror** of an explicitly
numbered 1–8 enumeration at `_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289`, and **the mirror
dropped archive item 5** (AC-10 cross-shell byte-identity of the generated `settings.local.json` and
pre-commit hook) while splitting archive item 3's reconcile tail into the vacated ordinal. The count
stayed at eight because a split compensated for a drop — which is why the architect's
self-corroboration argument was *valid on a false premise*, and why the drifted convenience index
could not have caught it either. Shipping as designed would have made the ledger the authoritative
home of a set missing a member, converting a recoverable drift into the record.

#### Rollback routing (rollback #1)

Findings split across two upstream owners, and a downstream stage cannot edit an upstream document,
so the analyst is dispatched first and the architect second:

- → **requirement-analyst** (`01`): **G-2** (E-6/AC-3 name five sources; there is a sixth, and AC-3
  as written is structurally incapable of detecting G-1), **G-6** (R-1 is false on delivery day
  because §3.2 + AC-13 pin a live document that restates obligation content), plus R-2's premise
  that the eight live "inside one note value".
- → **solution-architect** (`02`): **G-1**, **G-3**, **G-4**, **G-5**, **G-7**, **G-8**, **G-9**,
  **G-10** and binding conditions BC-1, BC-3…BC-7.

Neither stage has been rolled back before; the 3-strike limit is not in view.

#### G-11 — the deferred needs-human point: PM ruling, not escalated

The gate deferred a verbatim operator question: is the dropped byte-identity obligation still in
force? Under `.harness/rules/25-decision-policy.md` (Mode 2) the two branches are **not
symmetric**:

- Answering **"no"** would retire an obligation. That is red line 1 (irreversible) and red line 3
  (scope expansion beyond the dispatch, whose out-of-scope reserves even *discharging* to the
  operator). It is genuinely human-reserved and this pipeline will not take it.
- Answering **"yes"** takes no reserved decision at all. It preserves the status quo, and it is
  what the tree already says: `_archived/hook-truth-spec/04_DEVELOPMENT.md:452-453` records
  "Items 1, 2, 4, 5, 7 are unchanged and still binding." Nothing ever adjudicated the omission —
  `_qa_note_t20` records the T-13 obligations were "NOT renumbered, reconciled, re-read or edited".

**Ruling: this row retires nothing.** The obligation is carried as in force; per the gate's own
arithmetic the total stays **25** (the reconcile clause folds back into ordinal 3). The delivery
must surface to the operator that the note which travels to them has not carried this obligation
since T-13, so the operator can retire it later with the evidence in hand.

This is deliberately **not** Hard-rule-6 auto-deciding to avoid a block. The reserved act
(retirement) is not being taken — it is being preserved and, for the first time, made visible.
Blocking the row instead would leave the obligation invisible, which is a loss in precisely the
dimension the row exists to close. Rubric basis: prime directive 2 (sound engineering, honest
reporting) and "Design out the root cause" — plus red lines 1 and 3, which is why the *other* branch
is untouchable rather than merely disfavoured. Recorded here for the operator's review-after.

### Stage 1 round 2 record — READY

Intervention check #4: `.harness/intervention.md` **absent**.

Twelve in-place corrections. E-6 now states the set is **seven source spans across four files**, not
five documents. E-28/E-29 added as new ids appended out of sequence **on purpose** — renumbering
E-1…E-27 would break citations `02` and `03` have already made. AC-3 re-stated to compare against
each of the seven spans with a per-ordinal **matches / differs / silent** verdict, and to declare
that "a comparison performed against a mirror does not discharge this criterion."

Two things the analyst did beyond the finding, both correct:

1. **R-4 widened to "a mirror never narrows an enumeration"** — where an obligation is stated by
   more than one source the entry carries the **union**. Without this, correcting G-2 by simply
   switching source would have caused the *reverse* loss: the widening clause and the KNOWN BOUNDS
   text exist **only** in the mirror. That generalises G-3's defect shape at requirement level.
2. **R-6 re-stated** so the eight keep the ordinals their *enumerating* source assigns, and
   restoring an ordinal the mirror vacated is explicitly **not** a renumbering. Under the mirror,
   ordinal 5 held item 3's tail; "keep those ordinals" would have frozen the loss.

R-1 re-scoped to satisfy G-6 by **authority and permission** rather than by absence of every copy:
the ledger is the only document a reader is sent to for the current set, no document this task may
edit restates obligation content, and the one live document outside that permission is named in the
delivery as the remaining restatement with removal recorded as an operator action.

Total independently re-derived: 10 + 1 + 5 + 1 = **17 global; 17 + 8 = 25.** BC-2's condition is
met; R-2 and AC-4 are not re-opened.

**The observation the PM is carrying forward to QA:** the count is identical under both readings —
the mirror's drop was compensated by a split — so **no count-based check can ever detect this class
of loss.** AC-3's per-ordinal verdict, not AC-4's arithmetic, is the criterion that now bears the
weight. This goes into the stage-6 dispatch verbatim.

New residual **RES-6**: E-6's source set is derived by reading and explicitly **not** certified
total; G-2 is standing proof that a source set declared closed can be short by one, so the analyst
declined to re-make the totality claim. Re-derivation hidden-inclusive is owned by a stage with a
shell.

### Stage 2 round 2 record — READY

Intervention check #5: `.harness/intervention.md` **absent**.

Ten in-place corrections. §4 restructured around **enumerating sources**: new **S-F** =
`_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289` (+`:444-453`), with `_qa_note_t13` demoted to
*contributing mirror*. New §4.1 re-issues the eight, each row carrying the S-F span, the per-ordinal
mirror verdict, and a fifth column for text **only the mirror carries** (the R-4 union, which is what
stops the correction causing the reverse loss).

Per-ordinal verdict: **no ordinal matches token-for-token — seven narrowed, one silent.**
`T13-5` is the recovered obligation.

Three architect moves worth recording:

- **K-46** — a *count-free falsifier*. S-F `:452-453`'s partition sentence ("Items 1, 2, 4, 5, 7 are
  unchanged") is total under S-F and **self-contradictory under the mirror**, because item 3's
  widening *is* the reconcile target the mirror holds at ordinal 5. This answers the PM's carried
  observation directly: something non-arithmetic had to bear the weight, and now something does.
- **K-45** — the widening lead-in is classified R-12 **kind 3** (left byte-unchanged) on a positive
  match, realised as a **two-span excision** with the clause surviving between them. That discharges
  BC-3 without inventing a fourth disposition.
- **K-4a** — `- Last discharged:` = `never` | `<date> against <40-hex HEAD sha>[+dirty]`, with B-6
  reduced to an executable `git diff --quiet <sha> HEAD -- <field-3 paths>`. BC-5 discharged.

Two corrections the architect made **against the gate**, both in the direction of more work for
itself:

1. **G-10 was short by one** — id 7 (`_archived/guard-cmd-chain/04_DEVELOPMENT.md:491-492`) also
   carries a check count, so §12.5 discloses **four** ungated restatement sites, not three.
2. **K-9 / RES-D4 corrected** — individual ordinals of the eight *are* cited, but only from **inside
   S-F**. This strengthens R-6: those four citations resolve only under S-F's numbering, so restoring
   S-F's ordinals *repairs* references the mirror's numbering breaks.

BC-7 met: contract **510 lines**, two fewer than round 1, with every new key, the new §4.1 table,
V-14/V-15, §12.5 and four new residuals absorbed by moving argument into `02_RATIONALE.md`
(§R-transcription withdrawn). BC-8 met: `agents/pm-orchestrator.md` untouched at 296/300, and the
architect states explicitly that it does not believe a PM line is needed.

Routing: back to the **gate** for re-review (round 2), not forward to development — stage 3 must
produce an explicit PASS before stage 4 under the stage-gate rule, and this is the first gate round
that will see either corrected document.

### Stage 3 round 2 record — APPROVED FOR DEVELOPMENT

Intervention check #6: `.harness/intervention.md` **absent**.

Both round-2 bodies persisted verbatim by the PM, **replacing** the round-1 content at
`03_GATE_REVIEW.md` and `03_RATIONALE.md` (the gate's own instruction: replace, never append). PM
authored no part of either.

Closure: both round-1 FAILs (G-1, G-2), all three MAJORs (G-3…G-5), all four WARNs (G-6…G-10) and
all five INFOs (G-12…G-16) closed. BC-1…BC-7 discharged; BC-8/BC-9/BC-10 remain in force on stages
4/6/7. The gate **re-derived the eight-row map independently** from S-F and from the mirror without
consulting §4.1, and confirms it correct on every ordinal, span and mirror-only body — and confirms
the R-4 union loses nothing that exists only in the mirror, which was the reverse-loss risk.

**Both corrections the architect made against the gate are confirmed**, and the gate withdrew its
own round-1 §B row on K-9 as wrong. The gate also found a *third* ordinal citation neither upstream
stage had (S-F `:241`, "operator item 4"), which is the strongest because it pins the **mirror's**
ordinal 4 and is what fixes K-46's premise.

Fourteen new findings, **no FAIL**: 1 MAJOR (H-1), 5 WARN (H-2…H-6), 8 INFO. The gate converted all
of them into binding conditions BC-11…BC-18 rather than routing back, on the stated ground that a
third design round "would be spent relabelling two subscripts and adding one citation, which is the
oscillation this repository's own insight index says to recognise rather than to fund."

**PM concurs and advances.** The stage gate is satisfied: stage 3 has produced an explicit
`APPROVED FOR DEVELOPMENT`. Rollback ledger for this task: stage 1 ×1, stage 2 ×1, gate rounds ×2 —
no stage is near the three-consecutive-rollback stop.

Two conditions carry an explicit **rollback-to-stage-1** branch, and the PM is carrying them into
the stage-4 dispatch verbatim rather than letting the developer resolve them:

- **BC-11 / H-1** — `hook-truth-spec/07_DELIVERY.md:76` amends the "32 `Assert` calls" figure the map
  transcribes into three entries (the source has **29**, one inside a four-tool loop, yielding 32
  runtime rows). Neither `07_DELIVERY.md` nor `06_TEST_REPORT.md` is among E-6's seven spans, so
  AC-3/AC-5 quantify over a set that cannot detect it — the structural shape of G-2, recurring one
  level down. If it cannot be discharged by transcription, that is a rollback to stage 1.
- **BC-14 / H-4** — AC-1's tracked-live-tree clause is unsatisfiable as written, because fingerprint
  tokens are drawn *from* the tracked archive by construction. If the scope cannot exclude
  `docs/features/_archived/` on §3.3's ground, AC-1 cannot pass and it is a rollback to stage 1,
  **not** a developer judgement.
- **BC-15 / H-5** — `agents/pm-orchestrator.md` may measure **297**, not the 296 that AC-10 and V-12
  hard-code, on a file no stage touched. The condition exists so that nobody edits the file to make
  an integer match. PM restates: that file is **not to be touched**, and if `wc -l` disagrees with
  296 the *criterion* is corrected in the report, never the file.

Partition detection for stage 4: `.harness/agents/dev-*.md` → **no files**. Single-developer mode;
dispatching the plugin agent `harness-kit:developer`.

### Coordinator message (2026-08-02) — G-11 ruling ratified; stage 4 resumed

The first stage-4 dispatch was interrupted before the developer ran; **no production file had been
written**, so this is a resume, not a rollback. Intervention check #7: `.harness/intervention.md`
**absent** (this message arrived through the coordinator channel, not the signal file).

**The G-11 ruling is ratified by the coordinator**, who verified it independently before answering:
the enumerating source carries *AC-10 cross-shell byte-identity* at position 5, the `_qa_note_t13`
mirror contains the strings `AC-10` and `byte-identic` **zero times**, and the same source states
items 1, 2, 4, 5 and 7 are "unchanged and still binding". Carried in force; total stays **25**; this
row retires nothing. The coordinator confirms the escalation was correctly withheld, because the
only non-conservative answer would have retired a live obligation.

**Delivery instruction (stage 7, PM-owned).** The finding must reach `07_DELIVERY.md` in its
sharpest form, stated plainly: *the count stayed at 8 because a split compensated for a drop, so no
count-based check could ever have caught it.* Deriving the eight from the enumerating source is
therefore not a nicety — it is the only shape that would have detected it. Carried into the stage-4
dispatch as well, so `04_DEVELOPMENT.md` records it at the point of transcription.

**Constraints restated by the coordinator, unchanged:** no new verification check, count stays
**32** — and the coordinator supplies a new piece of evidence *for* that line: a count-based gate
would have passed this very defect. `agents/pm-orchestrator.md` at 296/300 with the gate exiting
non-zero on any WARN; if a writer duty needed lines there, condense in-file rather than append.
**PM note:** the design routes the writer duty to `agents/qa-tester.md` alone and touches
`pm-orchestrator.md` not at all, so no line is needed there — BC-8 and BC-15 stand as written, and
the gate's measured 297-vs-296 discrepancy is resolved in the *report*, never by editing the file.

**Scope change to record: `docs/proposals/operator-powershell-checklist.md` has been annotated by
the coordinator** with the same correction, so the operator-facing copy is not left carrying the
error. It remains **out of scope for every pipeline stage to edit**. Consequence for verification:
AC-13 requires that document be neither edited nor deleted *by this task* — a post-dispatch mtime or
content change on it is the **operator's** act, not a pipeline breach, and QA must not read it as
one. If the design supersedes that document, the delivery says so and leaves the disposition to the
operator.

Everything else stands: `verify_all` green at stage 7 (baseline **PASS 32 / WARN 0 / FAIL 0**,
unchanged — nothing has run against the tree); QA needs an `## Adversarial tests` section that tries
to construct the **next** obligation and sees where it naturally lands; wrapped insight bullets are
safe; `docs/features/_supervision/*.md` stays read-only.
