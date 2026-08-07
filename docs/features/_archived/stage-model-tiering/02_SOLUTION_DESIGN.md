# 02 — Solution Design: stage-model-tiering (T-22)

> Contract portion. Rationale: `02_RATIONALE.md` (derivations, the falsification narrative,
> option arguments, evidence citations). Mode: **full** · deferred-human: defer, do not ask.
> Upstream contract: `01_REQUIREMENT_ANALYSIS.md`; its rationale was opened under the named
> trigger in the dispatch (the §R1/§R2 derivations are the load-bearing claims this stage was
> asked to verify).
>
> **Round 2 (gate G-1…G-7, G-9).** Corrected: FL-2/4/7/9/10/11, §6's record, RK-6, §8's `T0`
> (D-15), §16 U-4/U-5 (+ §16.1). **The corrections move the published top of the surface toward
> BUILD** (13.9% → 44%); FL-10 gives the rate-free reasons the decline survives it. Sole
> authoritative parameterisation: `02_RATIONALE.md` §R2.4. Routing history: `PM_LOG.md`.

---

## 1. Architecture summary

Nothing executable changes. The system-level change is a **single append to one memory file**:
`.harness/rejected-decisions.md` gains one `## stage-model-tiering` record marking the model-swap
lever `declined` and the reasoning-effort lever `deferred`, so a future re-proposal finds the prior
decision instead of re-litigating it. No `agents/*.md` frontmatter, no skill, no script, no
template, no `verify_all` check, no version. The second deliverable is **evidence**, not code: a
freeze proof that the eight framework agent files were not touched, built on a working tree that
already carries eight siblings' uncommitted changes and so cannot argue from `git status`.

## 2. Falsification of the upstream analysis (this stage's primary work)

The dispatch required stage 1's arithmetic to be re-derived independently rather than inherited.
Each row below is a binding finding; the derivations are in `02_RATIONALE.md` §R1–§R4.

| id | Upstream claim under test | Verdict | Corrected statement |
|---|---|---|---|
| FL-1 | §0.2 / §R2.1 — "the break-even is **independent** of the delegated share, because both the saving and the risk cost scale with it" | **FALSIFIED as stated** | The algebra of `f = A(1−r)/C` is correct only under the unstated assumption that a rollback round costs **nothing outside the delegated set**. It costs orchestrator turns, which are main-loop. The honest form is `f = a(1−r) / [c_d + c_o·(1−S)/S]`; `S` cancels only when `c_o = 0` |
| FL-2 | FL-1's consequence for the recommendation | **DECLINE SURVIVES; the "strengthened everywhere" reading is REJECTED** | `f` is *monotonically increasing* in `S`, with supremum `a(1−r)/c_d` at `S→1`. That supremum sits below stage 1's `a(1−r)/0.445` **only while `c_d > 0.445`**, i.e. only while the gate-catch fraction `p < 0.80`. At the central `c_d = 0.58` the corrected bar is below stage 1's across the whole 6.7–45% band; at the `p = 1` corner (`c_d = 0.358`) it is **above** it — `0.417 > 0.335`, the counterexample FL-11 states. The correction lowers the bar over most of §R2.4's surface and raises it at one defensible corner. The decision does not turn on Finding A-4 because `S` is unmeasured *and* unmeasurable here (F-1), not because the inequality is universal |
| FL-3 | §R2.2 — `C ≈ 44.5%` (a rollback round = a stage 4→5→6 re-run) | **FALSIFIED** | A defect *originating* in stage 1 or 2 does not route to stage 4. `agents/pm-orchestrator.md:125-126,128,130` routes a requirement gap to stage 1 and a design gap or design drift to stage 2. The re-run is 2→3→4→5→6 (**80.3%**) when caught late, 2→3 (**35.8%**) when caught at the gate. 44.5% is only correct if ≈80% of induced defects are gate-caught, which this repo's insight history contradicts |
| FL-4 | §R2.3 — break-even `f ≈ 0.335` extra rollbacks/task (≈11% relative) | **REPRODUCED, then replaced by a surface** | Stage 1's number reproduces exactly from its own inputs; it is one cell, not the surface. The **single authoritative parameterisation is `02_RATIONALE.md` §R2.4**; this row quotes its endpoints and no other row in either document re-parameterises it. It spans `f = 0.017 … 0.834` extra rollbacks/task, **0.6% – 44% relative**: 0.6% at (`S = 0.067`, `k = 1`, `c_d = 0.58`, `1−r = 0.4`) against the n=6 mean of 3.0; 44% at the compound corner (`S→1`, `k = 0`, `p = 1` ⇒ `c_d = 0.358`, `1−r = 0.8`) against the n=10 mean of 1.9. Central (`S = 0.25`, `k = 0.25`) is `f = 0.147` ≈ 4.9%. No figure in this document may be quoted as "the break-even" without its cell |
| FL-5 | §R2.2 — `A ≤ 37.3%` and `C ≈ 44.5%` from T-20 document line volumes; the proxy under-counts stages 4/6 | **PM's bias reasoning VERIFIED** | Adding δ≥0 to stages 4 and 6 strictly decreases `A = 1512/(4051+δ)` and strictly increases `C = (1802+δ)/(4051+δ)`, so `f = A(1−r)/C` is **over-stated** by the proxy. The proxy error biases toward BUILD; the decline survives its own proxy |
| FL-6 | §0.1 A-2 — 6.7% is a strict floor on the delegated share | **HOLDS, and is loose** | The $36 attribution covers **six** roles; a delegated pm-orchestrator (OQ-2 reading (a)) and the supervisor are outside it, so the true floor is higher. A floor being loose cannot break the band's low end |
| FL-7 | §0.1 A-5 — 45% is the "defensible upper end" | **NOT a ceiling** | It is an argued judgement, not a bound. A structurally plausible call-mix (sub-agents making the large majority of calls, per §R1.2's own first bullet) exceeds it. **Non-material for an instrument reason, not an arithmetic one.** Round 1 argued that widening `S` "cannot lift the bar into detectable range", mixing stage 1's `c_d = 0.445` into a corrected model that uses 0.58 (central) or 0.358 (`p = 1`); that argument is withdrawn. Raising `S` *does* raise the bar — to `f = 0.257` at `c_d = 0.58`, `0.417` at `c_d = 0.358`, `0.834` in the compound (§R2.4). What makes `S` non-material is that **no rollback-attribution instrument exists at any resolution** (F-2), so no point on the `S` axis is measurable here |
| FL-8 | §0.4 — framework agents are plugin-native with no per-project override | **HOLDS** | Verified independently: `agents/*.md` is the single source (`AI-GUIDE.md:13,48,57`), `.claude/agents/` is **empty** in this repo, and the PM dispatches the namespaced `harness-kit:<name>` (`agents/pm-orchestrator.md:135-143`). A local `.claude/agents/<name>.md` would create a *bare-named sibling* the PM never dispatches — it cannot shadow a namespaced plugin agent. The only consumer-side lever is refusing the whole plugin update |
| FL-9 | §0.2 — "observed mean of 3.0 rollbacks per task (n=6)" | **HOLDS for the cited window; it is a selected sub-series** | `STREAM_LOG.md:72-86` gives 4/3/4/1/2/4 → mean exactly 3.0, range 1–4. But **`:53-70`** carries four earlier tasks at 1/0/0/0 (T-11a's 1 is at `:53`, not `:58` — round 1's range was short by one record, gate G-9); on n=10 the mean is 1.9 and every relative bar scales by ≈1.58×. Two precisions: the exclusion (pre-T-13 format, pre-contract-split era) is defensible but was not stated, and `:86` records T-20 with **no** rollback count at all, so the n=6 window is "tasks *with a recorded count*", not "tasks in the window". This is one of three adjustments in the BUILD direction, and it is the one that sets the compound corner's denominator |

**FL-10 · Net verdict of the falsification attempt.** The attempt **failed to overturn the
decline**. Three of stage 1's supporting claims are wrong (FL-1, FL-3, FL-7) and one is
under-stated (FL-6); three adjustments run in the **BUILD** direction (FL-5's proxy, FL-9's sample
selection, and the unsourced `1−r = 0.4` in §R2.3). Round 1 of this document tested those three one
at a time, found each survivable, and then published "0.6% – 13.9%" as **"the full parameter
surface"**. That label was wrong: it is the surface at *fixed* `1−r = 0.4` against a *fixed* n=6
base — two of the three BUILD adjustments held constant. Compounded at their most BUILD-favourable
defensible values simultaneously (`a = 0.373`, `1−r = 0.8`, `p = 1` ⇒ `c_d = 0.358`, `k = 0`,
`S→1`) the bar is `f = 0.834` extra rollbacks/task: **27.8%** against the n=6 mean, **43.9%**
against n=10. **Reported plainly because it moves toward BUILD: correcting this label multiplies
the published top of the surface by ≈3.**

The decline survives anyway, and the reasons are **rate-free** — they hold at every cell of §R2.4
including the compound corner: (i) no rollback-attribution instrument exists per originating stage
at **any** resolution, and the whole recorded history is ten tasks, so even a 0.83/task shift needs
≈30 attributed tasks to resolve — which is F-2 by definition, not a claim about the shift's size;
(ii) Finding C (the addressable set is the two longest-propagation roles) and Finding D (no
per-consumer reversibility) contain no rate parameter at all. **No rollback to stage 1 is
requested** — see §11 for the disposition of the upstream errors.

**FL-11 · The one thing that would have produced the opposite verdict.** Exactly the compound
above: `S ≈ 1` **and** `c_o = 0` **and** `p = 1` (every induced defect gate-caught, cheapest rework
shape) **and** a genuinely cheap tier at `1−r = 0.8`. `f = 0.834` (27.8% n=6 / 43.9% n=10) is a
delta a ≥20–30-task *attributed* baseline could resolve. Note the intermediate corner too: holding
`1−r = 0.4` and taking `p = 1` alone gives `f = 0.417 > 0.335`, which is the FL-2 counterexample —
i.e. stress-testing raised the bar above stage 1's here, it did not only lower it. The compound is
precisely F-1 + F-2 + F-3, so the re-surface preconditions discriminate rather than decorate.
(Round 1 never assembled the compound; the stage-3 gate did, and it is adopted here.)

## 3. Affected modules

| Path | Change | Note |
|---|---|---|
| `.harness/rejected-decisions.md` | **edit** — one appended record | The only production-surface file this task writes |
| `docs/features/stage-model-tiering/04_DEVELOPMENT.md` (+ `04_RATIONALE.md`) | new | Stage 4 |
| `docs/features/stage-model-tiering/05_CODE_REVIEW.md` | new | Stage 5 |
| `docs/features/stage-model-tiering/06_TEST_REPORT.md` (+ `06_RATIONALE.md`) | new | Stage 6 |
| `docs/features/stage-model-tiering/07_DELIVERY.md` | new | Stage 7 |
| `docs/features/stage-model-tiering/PM_LOG.md` | edit | PM-owned |

**Explicitly not touched:** all eight `agents/*.md`; every file under `skills/`; every
`.harness/scripts/*`; `docs/proposals/*`; `.claude-plugin/plugin.json`; `CHANGELOG.md`;
`README*.md`; `docs/dev-map.md`; `CONTEXT.md`.

## 4. Module decomposition

No new module. The one unit of new content is a memory record, specified byte-for-byte in §6.

## 5. Data model / API contracts

Not applicable — no schema, no route, no interface. Stated rather than omitted: this task adds no
callable surface, so there is nothing for a downstream consumer to bind to. The only "contract" is
the record's field shape, which the file's existing 23 records already define
(`- **Decision:**` / `- **Why:**` / `- **Origin:**`, exactly three fields).

## 6. Byte-form specification — the `## stage-model-tiering` record

**D-1 · Character identity is an acceptance criterion** (AC-5 reads this file post-edit), so the
text is written **once, here**; every other mention in any stage document cites this section
rather than restating it.

Append the following block verbatim to the **end** of `.harness/rejected-decisions.md`, preceded
by exactly one blank line, preserving the file's trailing newline:

```markdown
## stage-model-tiering
- **Decision:** model-swap lever **declined**; reasoning-effort lever **deferred** (not now) — two
  levers of one concept in one record; neither marking generalises to the other.
- **Why:** with six of the eight roles each excluded on positive evidence, the addressable set is
  requirement-analyst + solution-architect — the two roles whose errors propagate furthest here.
  Downgrading them pays only while it induces fewer than roughly 0.02–0.83 extra rollbacks per task
  (0.6%–44% relative, across the whole published surface); stress-testing moved that bar in **both**
  directions, and the decline holds at its most BUILD-favourable corner too, because nothing here
  attributes a rollback to the stage that caused it, at any resolution, across a ten-task history.
  The saving is a proportional discount on a bill that is 78% cache traffic; context reduction is
  the safer lever. The agents are also plugin-native: a tier set here reaches every installed
  project on the next plugin update with no per-project override, so it can be neither trialled nor
  withdrawn per consumer. The effort lever is deferred rather than declined because it keeps the
  capability ceiling, but its key spelling, value set and plugin-native applicability are
  unconfirmed upstream. Re-surface only with all three of **F-1** a per-call context-volume
  measurement putting the delegated share at the top of the published 6.7–45% band, **F-2** a
  rollback-attribution instrument resolving that surface per originating stage (sub-1% at its low
  end, so a ≥20-task baseline is a floor, not a sufficiency), and **F-3** a per-project tier
  override, making a downgrade reversible by the consumer that experiences it.
- **Origin:** T-22 `stage-model-tiering`. It overrides `docs/batches/default/BATCH_PLAN.md:37`
  ("**Wire** the per-agent model and reasoning-effort declarations…") and qualifies `:41`; both are
  quoted and answered at `docs/features/_archived/stage-model-tiering/02_SOLUTION_DESIGN.md` §16.1.
```

Binding properties of that text, each with the reason it is that way:

- **D-2 · Three fields, not four.** All 23 existing records carry exactly `Decision` / `Why` /
  `Origin`; the re-surface preconditions are folded into `Why`, matching the two existing records
  that do the same (`byte-form-subpart-classification:219-220`,
  `shared-insight-parse-module:254`). Do not promote F-1/F-2/F-3 to a fourth field.
- **D-3 · Both lever markings appear in the `Decision` line and are separated.** OQ-3's failure
  mode is a future reader taking one marking as blanket; the trailing clause forbids that reading
  explicitly.
- **D-4 · The `Origin` path is the ARCHIVED path**, which does not exist until stage 7 runs
  `archive-task`. This is deliberate: the two existing records that cite a stage document
  (`decision-mapping:89-90` → `docs/features/planning-decision-map/…`,
  `byte-form-subpart-classification:219` → `docs/features/stage-contract-split/…`) both cite the
  **pre-archive** path and both are **now dangling**, because those tasks were archived. Writing
  the post-archive path is the only spelling that is correct at rest. Stage 6 must not file this
  as a defect; stage 7 confirms the path resolves after the archive (§9 residual R-1).
- **D-5 · No banned phrase.** `.harness/rejected-decisions.md` is **not** in `I.6`'s exempt set
  (`verify_all.sh:666-679` exempts only CHANGELOG, three HTML docs, the two `verify_all` twins and
  the two `test-verify-i6` twins, plus the `docs/features/` and `参考/` subtrees), and the scan
  source is `git ls-files` (`:742`), which includes it. The **round-2** text was re-checked against
  all 14 banned anchor sets at `verify_all.sh:641-654`. The record names no bootstrap-stub file, no
  adoption skill, no `compos*`/`regenerat*`/`Generated-from` token and no Chinese, so no anchor set
  completes within its gap budget. Zero matches. (This bullet paraphrases the anchors rather than
  quoting them: `docs/features/` is I.6-exempt, but T-13's delivery-stage self-trip shows quoted
  anchors travel.) V-4 re-checks mechanically rather than trusting this note.
- **D-6 · Length: 22 lines** (1 heading + 2 `Decision` + 16 `Why` + 3 `Origin`) — **equal to** the
  file's longest existing record (`byte-form-subpart-classification`, 201-222; median 9) rather
  than exceeding it as round 1 did at 24; width follows the file's ≈99-column wrap. That budget is
  what forces `Origin` to *cite* `BATCH_PLAN.md:37`/`:41` and delegate the verbatim quotation and
  rebuttal to §16.1 — the move `byte-form-subpart-classification:219` already makes when it points
  at a design section. All seven elements `01_REQUIREMENT_ANALYSIS.md` §2.6 mandates are present
  (handle, two markings, four why-components, three preconditions, origin). D-11: no compaction.

## 7. Insertion point and ordering

- **D-7 · Append at end of file**, after `## shared-insight-parse-module` (currently the last
  record, ending at line 255).
- **D-8 · Reason.** The file is append-ordered by origin task (mattpocock batch → T-11c → T-15 →
  T-16 → T-18 → T-20), and T-22 is the newest origin. The single out-of-order record
  (`hook-spec-raw-query`, T-16, at line 191 between two T-18 records) shows the ordering is a
  convention rather than a rule, so appending is both conventional and the least surprising.
- **D-9 · Append-only diff.** The edit must add lines and delete none. `git diff --stat` must show
  one file with `+23 -0` (23 = 22 record lines + 1 blank separator). If the diff instead shows
  `-1/+24` with a "\ No newline at end of file" marker, that is the trailing-newline artefact and
  is acceptable **only** if the removed line is byte-identical to the last line of
  `shared-insight-parse-module`'s `Origin` field.
- **D-10 · No reflow.** Do not rewrap, reorder, renumber or "tidy" any of the 23 existing records.
  A reflow would make the freeze/diff argument in §8 unreadable for the code reviewer.
- **D-11 · No compaction.** The file's header carries a "~one screen" soft self-discipline with no
  gate. The file is already 255 lines / 23 records, so that discipline is already exceeded and one
  appended record does not newly breach it. Compacting merged or obsolete records is real work
  requiring per-record judgement, is not in `01_REQUIREMENT_ANALYSIS.md` §2, and would destroy the
  append-only diff property in D-9. Not done here; recorded as a standing observation, not a task.

## 8. Freeze proof method (AC-6)

`git status` cleanliness is unavailable — the tree carries eight siblings' uncommitted changes, and
a dirty-set **difference** is separately known to be insufficient because it is blind to a content
edit inside an already-dirty file (`.harness/insight-index.md`, T-15 S0-vs-S11 entry). The sound
substitute is the difference **plus** per-file mtime ordering against a fixed anchor `T0` (D-15
states exactly what that anchor is and is not). This design specifies five predicates; each covers
a failure mode the others do not.

### 8.1 What the developer captures, and when

**Capture S-A — immediately before the first write of stage 4, before touching any file:**

| # | Command | Purpose |
|---|---|---|
| A1 | `git rev-parse HEAD` | pin the comparison commit `H0` |
| A2 | `git status --porcelain -- agents/` | expected **empty** — establishes `agents/` is outside the dirty set |
| A3 | `git status --porcelain > /tmp/t22_s0.txt; wc -l < /tmp/t22_s0.txt` | the whole dirty set, for the difference half |
| A4 | `for f in agents/*.md; do stat -c '%n %Y %s' "$f"; done` | mtime + size per agent file |
| A5 | `wc -l agents/*.md` | the eight line counts + total |
| A6 | `sha256sum agents/*.md` | eight content digests |
| A7 | `stat -c '%Y' docs/features/stage-model-tiering/01_REQUIREMENT_ANALYSIS.md` | `T0` — that file's **last** write. Not the task's first write; see D-15 |
| A7b | `stat -c '%n %Y' docs/features/stage-model-tiering/*.md` | record every stage document's mtime, so `min` over the folder is on the record too (D-15) |
| A8 | `bash .harness/scripts/verify_all.sh; echo "exit=$?"` | the baseline run |

**Capture S-B — after the edit and after the final `verify_all`:** repeat A1–A6 and A8 into
`/tmp/t22_s1.txt` equivalents.

### 8.2 The five predicates

| id | Predicate | Covers | Expected |
|---|---|---|---|
| FZ-1 | `git status --porcelain -- agents/` is empty at S-A **and** S-B, and `git rev-parse HEAD` is unchanged | any tracked edit, plus any new untracked file under `agents/` | empty / equal. Because `agents/` starts **outside** the dirty set, path-scoped emptiness is a content-identity statement against `H0`, not a difference argument |
| FZ-2 | The eight `sha256sum` digests are identical at S-A and S-B | edits, independent of git; survives a HEAD move | 8/8 equal |
| FZ-3 | Every agent file's mtime is **strictly less than** `T0` (A7) | the window ending at `T0` — stage 3 and the tail of stage 2. It does **not** retroactively cover stages 1–2 in full; see D-15 | 8/8 earlier than `T0` |
| FZ-4 | `diff /tmp/t22_s0.txt /tmp/t22_s1.txt` | the dirty-set difference half | **no change** — `.harness/rejected-decisions.md` is *already* dirty, so its entry does not move. A null result here is the expected result, not a broken check; FZ-4 is recorded for completeness and is the weakest of the five |
| FZ-5 | `wc -l agents/*.md` equals the reference table in §8.3 at S-A and S-B | the AC-6 line-count comparison, and the I.3 cap claim | equal, and every value ≤ 300 |

**Contingencies, so the developer never blocks on a benign reading:**

- If A2 is **non-empty** (an agent file is already dirty from a sibling change), FZ-1 degrades to a
  difference argument and is no longer sufficient on its own. Record the fact; **FZ-2 then carries
  the claim** (FZ-3 only bounds the recent window — D-15). Do not stop.
- If any mtime is **≥ `T0`** while FZ-1 and FZ-2 hold, the file was *touched* without content
  change (a checkout, a `sync-self` pass). Record it as a NOTE with the observed timestamps; the
  content identity carries AC-6. Do not stop. Do not "fix" the mtime.

**D-15 · What FZ-3 does and does not cover** (gate G-6). `stat` on `01_REQUIREMENT_ANALYSIS.md`
returns that file's **last** write, not the task's first (the earliest artifact is `PM_LOG.md`), so
an agent-file edit made during stage 1 before 01's final write would still pass FZ-3.
**Retroactive coverage of stages 0–2 is carried by FZ-1, not FZ-3** — FZ-1 is a content-identity
statement against an unmoved `H0` over the whole interval since that commit, which strictly
contains the task. `T0` stays as specified (a single fixed number, not one that shifts as stage 4
writes); A7b records `min(mtime)` over the task folder as the tighter anchor. The developer states
this limitation in `04_DEVELOPMENT.md` rather than claiming FZ-3 covers stages 1–3.

### 8.3 Reference line counts (AC-6 comparison values)

Measured at stage 2 on 2026-08-01 by a line-count scan of `/home/alan/Programs/harness-kit/agents/`:

| File | Lines | Headroom to the I.3 300-line cap |
|---|---:|---:|
| `agents/pm-orchestrator.md` | 293 | 7 |
| `agents/supervisor.md` | 287 | 13 |
| `agents/solution-architect.md` | 169 | 131 |
| `agents/code-reviewer.md` | 166 | 134 |
| `agents/qa-tester.md` | 156 | 144 |
| `agents/gate-reviewer.md` | 113 | 187 |
| `agents/requirement-analyst.md` | 101 | 199 |
| `agents/developer.md` | 91 | 209 |
| **Total** | **1376** | — |

- **D-12 ·** `01_REQUIREMENT_ANALYSIS.md` §4.3's "the two files with least headroom carry 293 and
  287 lines" is **confirmed exactly** (`pm-orchestrator` 293, `supervisor` 287).
- **D-13 · ±1 tolerance, once.** These counts come from a line scan; `wc -l` reads one lower for a
  file lacking a trailing newline. The developer records the `wc -l` values as authoritative and
  treats a single-line delta on any file as a trailing-newline artefact rather than an edit —
  **provided FZ-2's digest is unchanged**, which is the discriminator. The I.3 claim is robust to
  the artefact either way.
- **D-14 · The cap is not the reason for the decline.** A `model:` frontmatter key adds **one**
  line per file → 294 max, still under 300. Neither the record nor any stage document may imply
  that the 300-line cap constrained this decision.

## 9. Sequence / flow

```
stage 4 developer
  ├─ capture S-A (A1…A8)                        ← before any write
  ├─ append §6 byte-form to .harness/rejected-decisions.md   ← the ONLY production edit
  ├─ run verify_all.sh; record summary AND `echo $?`
  ├─ capture S-B; evaluate FZ-1…FZ-5
  └─ write 04_DEVELOPMENT.md (+ 04_RATIONALE.md for the full captures)

stage 5 code-reviewer  — audits the diff and the evidence, not the decision
stage 6 qa-tester      — independently re-derives the freeze proof, mutation-tests it,
                         and attacks the analysis (§10)
stage 7 delivery       — archive-task; confirm R-1; no version, no CHANGELOG
```

**Residuals carried out of this stage:**

- **R-1 (stage 7)** — after `archive-task` runs, confirm the `Origin` path in the record resolves
  to a file that exists **and that the file still carries a `### 16.1` heading** (D-4). The record
  delegates its rebuttal to that anchor, so a resolving path with a renumbered section is a
  half-failure and must be reported as one.
- **R-2 (stage 6)** — the freeze method must be shown to *discriminate*, not merely to pass (§10.2).
- **R-3 (stage 7)** — `.harness/insight-index.md` sits at exactly 30 entries, which is the `I.4`
  cap (`verify_all.sh:529` warns at `> 30`). Any insight harvested by this task rotates the oldest
  out automatically; that is expected behaviour, not a defect.

## 10. Verification plan

### 10.1 Gate expectations

| id | Expectation | How |
|---|---|---|
| V-1 | `bash .harness/scripts/verify_all.sh` reports **PASS 32 / WARN 0 / FAIL 0** and **exits 0** | run it; assert on `echo $?` as well as the summary. `verify_all.sh:932-934` exits 2 on any FAIL and **1 on any WARN** — a WARN is a FAIL for this task (AC-7) |
| V-2 | The check count stays **32** | G.4 derives it as `${#report[@]} + 1` (`verify_all.sh:824-826`) and cross-checks every doc claim. Adding a check is out of scope (`01` §3.3) |
| V-3 | `E.1` stays PASS despite editing a file under `.harness/` | `E.1` runs `sync-self.sh --check` (`verify_all.sh:194`), whose mappings cover the 8 script pairs only — there is no mapping for `.harness/rejected-decisions.md` (`docs/dev-map.md:172`: "NOT byte-synced"). Verified by inspection; the developer confirms it in the post-edit run |
| V-4 | `I.6` stays PASS on the edited file | D-5; the record contains none of the 14 banned anchor sequences |
| V-5 | `I.3` stays PASS | §8.3; nothing under `agents/` is written |
| V-6 | No PowerShell twin runs | Nothing changes in any `.ps1`; PS is not executable by agents on this host (standing hazard). `F.1` symmetry is unaffected |

### 10.2 What QA should adversarially attack

Ordered by expected yield. The standing rule applies: **a fixture that produces the expected
verdict is not evidence that it discriminates.**

1. **The freeze proof's discriminating power (R-2, highest value).** Copy `agents/developer.md`
   into a scratch directory, append a `model: <tier>` line, and run FZ-1, FZ-2, FZ-3 and FZ-5
   against the mutated copy. Each must **fire**. A freeze proof that has never been shown to fail
   is a green-and-vacuous check — this is the same class as the T-16 `[T-16][A]` oracle and the
   T-15 unanchored-`grep` finding.
2. **AC-5 exactness.** `grep -c '^## stage-model-tiering$'` = 1, and `grep -in 'stage-model-tiering'`
   over the whole file returns no second heading at a different level, casing or indentation.
3. **AC-7 by exit code, not by text.** Run `verify_all.sh; echo $?`. Asserting only on the printed
   `WARN: 0` line would miss an exit-code regression; the gate is the exit code.
4. **The two-lever wording (D-3).** Assert the record does **not** contain "reasoning-effort" within
   the same clause as "declined", nor "model-swap" within the same clause as "deferred". This is
   the exact misreading OQ-3 exists to prevent. **Scope the check to the `Decision` and `Why`
   fields**: `Origin` quotes `BATCH_PLAN.md:37`, whose text contains "reasoning-effort", and a
   whole-record grep would fire on the quotation. That is a quoted source, not a lever marking.
5. **Required elements by grep.** `F-1`, `F-2`, `F-3`, `declined`, `deferred`, `Origin`, `T-22` all
   present in the record's line range.
6. **Append-only.** `git diff -- .harness/rejected-decisions.md` shows zero deletions (D-9's
   tolerance is the only exception, and it must be justified by byte-equality).
7. **The analysis itself** (PM's standing position that a decline deserves adversarial scrutiny).
   The record's headline is reproducible from **one** table, `02_RATIONALE.md` §R2.4; reproduce
   both endpoints from `f = a(1−r)/[c_d + c_o·(1−S)/S]` with `a = 0.373`. Low: `1−r = 0.4`,
   `c_d = 0.58`, `k = c_o/c_d = 1`, `S = 0.067` → `0.1492/(0.58 × 14.925) = 0.017`, `/3.0 = 0.57%`
   → the record's **0.6%**. High: `1−r = 0.8`, `c_d = 0.358` (`p = 1`), `k = 0`, `S→1` →
   `0.2984/0.358 = 0.834`, `/1.9 = 43.9%` → the record's **44%** (`/3.0 = 27.8%` at n=6). A
   mismatch is CRITICAL against §6, not a NOTE — the record is frozen memory. Then attack FL-11:
   construct a parameter combination that puts the break-even in *detectable* range **and** name an
   instrument in this repo that would detect it. The bar already reaches 44%, so "the number is
   large" is not the finding; an instrument would be, and it would be CRITICAL.

## 11. What each remaining stage actually does

No stage is empty. PM's standing position — the analysis behind a decline deserves adversarial
scrutiny — is supported by the shape of this task, not merely asserted.

| Stage | Concrete work | Why it is not empty |
|---|---|---|
| 4 developer | The §6 append; the S-A/S-B captures; two `verify_all` runs; `04_DEVELOPMENT.md` + `04_RATIONALE.md` | The freeze proof is produced here or nowhere — stage 5 has no `Bash` mandate to capture S-A retroactively, and `T0`-anchored mtimes must be read before more writes land |
| 5 code-reviewer | Audit the diff against D-1…D-15: append-only, no reflow, three-field shape, both markings present and separated, the archived-path forward reference flagged not "fixed", the record's factual claims matching §2 and §6 of this document, and — the substantive one — whether `04_DEVELOPMENT.md`'s freeze section **supports** AC-6 or merely asserts it | The recurring defect class here is an evidence section that restates the claim instead of exhibiting the capture. That is exactly what a reviewer catches |
| 6 qa-tester | §10.2, all seven items, with independent reproducers (not the developer's captures) and a `## Adversarial tests` row per acceptance criterion | Items 1 and 7 are real adversarial work: one mutation-tests the proof method, the other attacks the decision's arithmetic. AC-1…AC-4 and AC-8 are read-verifications of `01`, which QA performs against the document rather than against code |
| 7 delivery | Archive; confirm R-1; assert no version bump, no CHANGELOG entry, counts unchanged (17 skills / 8 agents / 32 checks); consolidate the insight (R-3) | The archive is what makes D-4's path correct and what harvests the insight |

**Partition assignment:** not applicable — `.harness/agents/dev-*.md` is empty (verified by glob;
`AI-GUIDE.md:15`), so stage 4 runs in single-Developer mode and dispatches `harness-kit:developer`
(`agents/pm-orchestrator.md:142-143`).

## 12. Reuse audit

| Need | Existing code / artefact | Path | Decision |
|---|---|---|---|
| Declined-option memory | The rejected-decisions file, 23 records, three-field shape | `.harness/rejected-decisions.md` | **Reuse as-is** — append one record; no new file, no new format |
| Precedent for a decline as the whole deliverable | T-10 `planning-decision-map` (`## decision-mapping`, no code, no version bump) | `.harness/rejected-decisions.md:73-90` | Reuse the shape; **do not** reuse its pre-archive `Origin` path (D-4) |
| Precedent for one record carrying a two-part decision | `## byte-form-subpart-classification` | `.harness/rejected-decisions.md:201-222` | Reuse — it is the model for D-2/D-3 |
| Precedent for a `deferred` (not-now) marking | `## design-it-twice`, `## hook-spec-raw-query` | `.harness/rejected-decisions.md:12-17,191-199` | Reuse the `deferred (not now)` wording |
| Freeze proof on a dirty tree | The T-15 insight entry (dirty-set difference **plus** mtime ordering) | `.harness/insight-index.md` (2026-08-01 T-15 entry) | **Reuse the method**; §8 instantiates it and adds FZ-2's digest as a git-independent third leg |
| Rollback routing evidence (FL-3) | The PM's own rollback-target table | `agents/pm-orchestrator.md:125-130` | Reuse as evidence — it is a normative statement, stronger than an inferred convention |
| Gate semantics (WARN = fail) | `verify_all.sh:932-934` | — | Reuse; no new check (`01` §3.3) |
| A per-project agent override surface (F-3's future shape) | Partition `dev-*` agents are project-local and synced to `.claude/` | `.harness/agents/dev-*.md`, `agents/pm-orchestrator.md:135-145` | **Not built here.** Named in the record as the existing precedent for what F-3 would extend |
| Glossary terms | `CONTEXT.md` | repo root | **No change.** This task creates no module, file or symbol to name; "delegated share" and "break-even" are analysis vocabulary local to an archived assessment, and seeding them would add terms the pipeline never uses. Recorded as a deliberate call, not an omission |
| A second rejected-decisions record for options declined *by this design* | — | — | **Not filed.** Nothing declined in §6–§8 is a concept-level decline (adding a `verify_all` freeze check is already barred by `01` §3.3; splitting the record is resolved by OQ-3). A second record would also contradict AC-5's "exactly one" |

## 13. Risk analysis

| id | Risk | Mitigation |
|---|---|---|
| RK-1 | The freeze proof passes vacuously — the predicates would also pass on an edited file, so AC-6 is asserted rather than proven | §10.2 item 1 makes stage 6 mutate a scratch copy and show each predicate fires. This is R-2 and it is the single highest-value QA item |
| RK-2 | A `verify_all` **WARN** is read as advisory and the task is declared done at exit 1 | V-1 requires asserting on `echo $?`, and the insight index carries the recorded instance of an architect assuming the opposite (`verify_all.sh:932-934`) |
| RK-3 | The developer "fixes" D-4's forward path reference to the pre-archive path, reproducing the two dangling citations already in the file | D-4 states the reason inline; §11 tells stage 6 not to file it; R-1 makes stage 7 verify it after the archive |
| RK-4 | The record is edited into the file by a rewrite that reflows neighbouring records, making the append-only diff unreadable and the freeze argument unauditable | D-9 + D-10 pin the diff shape; stage 5's first check is `+N -0` |
| RK-5 | The record's `Why` drifts from `01`'s §2.6 element list during rework rounds, so AC-5 passes on the heading but fails on content | §6 is the single byte-form site (D-1); every other document cites it. Stage 5 checks §6 against `01` §2.6 element by element |
| RK-6 | The corrected break-even in §2 is read as *overturning* the decline, and a future reader re-opens tiering on the strength of "the analyst was wrong" | **Not mitigated by claiming the corrections are one-directional — they are not** (FL-2, FL-10, FL-11: the compound corner triples the published top). Mitigated instead by the two rate-free legs: FL-10 states that no rollback-attribution instrument exists at any resolution, and that Findings C and D carry no rate parameter. The record carries the same both-directions sentence plus "nothing here attributes a rollback to the stage that caused it", so what survives the archive is the argument that actually holds |
| RK-9 | A number in §6 traces to no derivation, or `Origin` mis-describes the source it cites — the round-1 defect class (gate G-2, G-3) | Every §6 figure now comes from one table (`02_RATIONALE.md` §R2.4) and §10.2 item 7 makes QA reproduce all four endpoints arithmetically, as a CRITICAL. `Origin` cites only `BATCH_PLAN.md:37`/`:41`, both quoted verbatim in §16.1 and both re-read in place at stage 2 round 2; the round-1 `cost-attribution-2026-08.md:81-84` claim is withdrawn (§16 U-5) |
| RK-7 | `.harness/rejected-decisions.md` is inside `.harness/`, and an over-cautious developer runs `sync-self` "to be safe", perturbing the eight mirrored script pairs | V-3 records that no mapping exists; the design forbids running any sync script — the edit needs none |
| RK-8 | The record trips `I.6`, which does scan this file | D-5 checked the record text against all 14 banned anchor sequences; V-4 re-checks it mechanically |

## 14. Migration / rollout plan

No migration. Backwards compatibility is total: the file is human-and-agent-read prose with no
parser (the only mechanical readers of `.harness/` memory files are `archive-task` and `verify_all`
`I.4`, both scoped to `.harness/insight-index.md`). Rollback is deleting the appended block —
which is why D-9's append-only property matters operationally, not just aesthetically. No feature
flag, no staged rollout, no distributed-surface change: the plugin ships `skills/` and `agents/`,
and this task writes to neither.

## 15. Out-of-scope clarifications

This design does **not** cover, and no downstream stage may add: any `agents/*.md` edit of any kind
(the declined change itself); a `verify_all` check for the freeze property; a per-project tier
override (F-3 names it as a precondition, not as work); the F-1 context measurement or the F-2
rollback-attribution instrument; a pool row for either (operator-reserved, OQ-4); a version bump or
CHANGELOG entry; compaction of `.harness/rejected-decisions.md`; any edit to `docs/proposals/`; and
any correction to `01_REQUIREMENT_ANALYSIS.md`, which this stage may not edit.

**On CHANGELOG / version (OQ-5, confirmed):** `.harness/rules/20-documentation.md` ties the
obligation to adding a skill (rule 13), to keeping README/CHANGELOG/getting-started/concepts in
sync with **actual code** (rule 12), and to updating docs that reference a changed **rule**
(rule 15). No skill, no code and no rule changes here, so no obligation fires. T-10 is the live
precedent for a decline with no version or count flip.

## 16. Findings on the upstream contract (reported, not corrected — this stage may not edit `01`)

| id | Observation | Material? | Disposition |
|---|---|---|---|
| U-1 | §4.1's bolded heading ("`.harness/rejected-decisions.md` **already carries** a `stage-model-tiering` record") asserts the opposite of its own body ("Verified absent … none named `stage-model-tiering`") | **No — cosmetic** | What gets built is fixed unambiguously by §2.6 ("Append one … record") and AC-5 ("contains exactly one"), which agree with the body and with each other. No reader of §2.6 + AC-5 could build anything else. The bolded lead is a mis-instantiated statement of the file's general one-record-per-concept convention. **Not a rollback trigger**; worth a one-line correction only if PM is rolling back for another reason |
| U-2 | §4.1 states the file "carries eighteen records" | **No — but it is wrong.** The file carries **23** records (`^## ` headings at lines 12…245 of a 255-line file) | The count appears in no acceptance criterion and no build instruction, and the material claim in the same sentence (no `stage-model-tiering` record exists) is correct — independently re-verified. Reported because it is the second factual error in one paragraph |
| U-3 | §4.3's "one added record stays within [the ~one-screen discipline]" | **No** | The discipline is already exceeded (255 lines, 23 records) and no gate enforces it. The design does not lean on the claim; D-6 and D-11 handle length explicitly instead |
| U-4 | §0.2 / §R2.1's independence claim and §R2.2's `C = 44.5%` | **No — for what gets built** | FL-1/FL-3 falsify them. Round 1 added "both corrections move the break-even **down**"; that is true of FL-1 (`c_o > 0` always lowers `f`) but **not** of FL-3, which lowers `f` at the central `c_d = 0.58` and raises it at `c_d = 0.358` (`p = 1`) — same over-claim as G-4, withdrawn here too. It stays immaterial for a reason that does not need the direction: every binding statement in §2.6 and every acceptance criterion is rate-free. Corrected model recorded in `02_RATIONALE.md` §R2.4 |
| U-5 | Neither §0.5 nor §7 engages the operator-authored statements that say to build this: `BATCH_PLAN.md:37` and `:41`. **Round 1 of this document mis-identified the target** as `docs/proposals/cost-attribution-2026-08.md:81-84` and claimed to "supersede" it | **Yes — for the record's content, not for the verdict** | That claim is **withdrawn** (gate G-3(b)): read in place, `:81-84` is a *priority* correction inside a "Recommended disposition" list of pool rows, reinforced by `:72` ("then **consider** tiering"); it took no position the decline contradicts. What the decline actually overrides is `BATCH_PLAN.md:37` (imperative, `in-progress`); `:41` it does not contradict but qualifies. Both are quoted verbatim and answered in **§16.1** below, which the record's `Origin` now cites. No rollback needed — `01` is archived alongside this document, so the rebuttal travels with the assessment |

**None of U-1…U-5 changes what is built.** No rollback to stage 1 is requested.

### 16.1 The operator statements this decline overrides or qualifies, quoted and answered

A future reader must see the contrary operator position **and** its rebuttal without leaving the
shipped artifacts. The record's length discipline (D-6) does not fit a rebuttal, so it cites this
section and this section carries it.

**O-1 · The pool row itself** — `docs/batches/default/BATCH_PLAN.md:37`, status `in-progress`:

> "**Wire** the per-agent model and reasoning-effort declarations that the agent definition format
> already supports but this project has never set, so a role runs at the depth its work needs
> instead of every role inheriting the top tier — with the tier for each role justified by T-21's
> attribution and by that role's demonstrated defect-catching record, and with the three
> verification roles held at full depth unless evidence says otherwise."

**Answer.** The row is imperative and this task does not do what it says. It is overridden by its
**own two conditions**, both of which came back against it. (i) *"justified by T-21's attribution"*
— T-21 returned `docs/proposals/cost-attribution-2026-08.md`, which found 78% of spend is cache
traffic and ruled tiering "a proportional discount … not a structural fix" (`:65-70`). The operator
made the row conditional on exactly that answer: `BATCH_PLAN.md:42` — *"The answer determines
whether model tiering is a 7% lever or a majority one. **Do not skip to T-22.**"* It was a 7% lever.
(ii) *"justified by … that role's demonstrated defect-catching record"*, with *"the three
verification roles held at full depth unless evidence says otherwise"* — applied role by role
(Finding C) that bar leaves requirement-analyst + solution-architect as the only addressable pair,
and their errors have the longest propagation distance in the repo. **The row's own evidence bar,
honestly applied, empties the addressable set.** Independently, Finding D (FL-8) shows the wiring
cannot be trialled or withdrawn per consumer — which the row pre-dates and did not weigh.

**O-2 · The wave note** — `docs/batches/default/BATCH_PLAN.md:41`:

> "The capability is already supported by the agent definition format — this is unused wiring, not
> a missing mechanism."

**Answer.** True as stated and not in dispute. It is a statement about the *mechanism's
availability*, not a finding that the wiring should carry a value — "a switch exists" is not "the
switch should be flipped". Two qualifications it could not carry: for the **model** lever,
availability is exactly what makes Finding D bite (available *plugin-wide*, no per-project override
— `.claude/agents/` empty, every dispatch namespaced `harness-kit:<name>`, FL-8); for the **effort**
lever the premise is not fully verified — key spelling, value set and applicability to a
plugin-native `agents/*.md` file are unconfirmed upstream (OQ-1), hence `deferred`, not `declined`.

**Standing, not conflict.** The decline is the commissioned answer, not a unilateral override: the
dispatch is recorded assess-first at `docs/batches/default/STREAM_LOG.md:88`, its brief
pre-authorised *"recommend DECLINE and build nothing … Record the decline in the rejected-decisions
memory so it is not re-litigated"*, and `BATCH_PLAN.md:42` (operator-authored) made the row
conditional. Full quotation and provenance: `PM_LOG.md`, "PM ruling on HR-1"; grounds in
`02_RATIONALE.md` §R6. **Closing the row is the operator's act, not this task's** — §15 bars
editing `docs/proposals/` and filing pool rows, and `:37` stays `in-progress`.

## 17. Open questions — dispositions

| id | Disposition |
|---|---|
| OQ-1 · reasoning-effort key | **Partially closed.** PM's runtime datum establishes that model, reasoning effort and tools come from an agent's definition on two named surfaces (`.claude/agents/*.md` frontmatter, SDK `agents`). It does **not** establish the key's spelling, its value set, its effect size, or that it is honoured for a **plugin-native** agent auto-discovered from top-level `agents/` — which is neither surface the datum names. Under `.harness/rules/80-settings-schema.md`'s consult-upstream-first discipline (written after two shipped bugs from recalled keys) the remainder needs a schema read this stage cannot perform (no network tool). **Disposition unchanged: DEFER.** The deferral never rested only on existence — F-1/F-2 and Finding D bind the effort lever identically, and §2's corrected break-even is knob-agnostic (`f` tracks the capability delta, not which key produces it). §6's wording is written to be correct under this partial closure: it claims the *name, value set and plugin-native applicability* are unconfirmed, not that no key exists |
| OQ-2 · does `model:` on the PM bind in stream mode | **Non-blocking for role selection, but load-bearing for FL-1.** The contradiction stands (`skills/harness-stream/SKILL.md:122` vs `docs/batches/default/BATCH_PLAN.md:58`). Under the second reading the PM shell is main-loop, which is precisely the `c_o > 0` term that breaks the independence claim; under the first reading a non-delegated remainder still exists (the drain shell, `verify_all` runs, operator turns), so `c_o > 0` either way and FL-1 does not depend on resolving it. Correcting the stale note remains a separate row |
| OQ-3 · one record or two | **One**, per D-2/D-3. Confirmed against the file's stated convention and the `byte-form-subpart-classification` precedent |
| OQ-4 · file the F-1 measurement row | Unchanged: recommended on substance, **operator-reserved**, filed by nobody in this task |
| OQ-5 · CHANGELOG / version | **Neither**, confirmed against `.harness/rules/20-documentation.md` rules 12/13/15 — see §15 |

## 18. Verdict

**READY.**

The falsification required by the dispatch was carried out and **failed to overturn the decline**:
three of stage 1's supporting claims are wrong (FL-1 independence, FL-3 rollback cost, FL-7 the
band ceiling). **The corrections do not all move the same way** — round 1 said they did, and that
was the gate's central finding. The published surface is `f = 0.017 … 0.834` extra rollbacks/task,
**0.6% – 44%** relative (`02_RATIONALE.md` §R2.4, the one authoritative parameterisation), whose
top end is ≈3× what round 1 published.

The decline stands on the two legs that carry it at **every** cell of that surface: no
rollback-attribution instrument exists here at any resolution over a ten-task history (F-2), and
Findings C and D contain no rate parameter. Finding D is confirmed independently (FL-8). Narrower
and more honest than "every correction lowers the bar" — and it is what the record now says.

No rollback is requested. Five findings against `01` are reported in §16; none changes what is
built. U-5's substantive content is quoted and answered in §16.1, which the record's `Origin` cites.
