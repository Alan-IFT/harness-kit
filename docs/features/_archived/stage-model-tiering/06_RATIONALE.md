> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Full tool runs whose ≤5-line excerpts the contract cites, the measurement narrative, and the
material `70-doc-size.md` row 13 sends here. Every command below was executed by me on this host
during stage 6; nothing is transcribed from `04_RATIONALE.md`.

Anchors used throughout: `H0 = cb0ed57`, `T0 = 1785591621` (= `01_REQUIREMENT_ANALYSIS.md` mtime,
verified independently), `T_dispatch = 1785591045` (`STREAM_LOG.md:88`).

---

## Q1. AC-5, D-1/C-2, D-9/D-10 — the record itself

```
$ grep -c '^## stage-model-tiering$' .harness/rejected-decisions.md   → 1
$ grep -in 'stage-model-tiering' .harness/rejected-decisions.md
257:## stage-model-tiering
276:- **Origin:** T-22 `stage-model-tiering`. It overrides `docs/batches/default/BATCH_PLAN.md:37`
278:  quoted and answered at `docs/features/_archived/stage-model-tiering/02_SOLUTION_DESIGN.md` §16.1.
$ grep -inE '^\s*#{1,6}\s*.*stage.?model.?tiering' .harness/rejected-decisions.md
257:## stage-model-tiering
$ grep -c '^## ' .harness/rejected-decisions.md   → 24        (23 → 24 records)
$ wc -l .harness/rejected-decisions.md            → 278        (255 + 1 + 22)
$ sed -n '255p'  → - **Origin:** T-20 `harvest-wrapped-insight` (design §M.1 / `K-48c`, gate `K-67`).
$ line 256       → (empty)                                    D-7 arithmetic intact
$ tail -c 1 | xxd → 00000000: 0a                              trailing newline preserved
```

**Character identity, mechanically (D-1 / C-2).** Two prior stages verified this by reading; I
verified it byte-for-byte, which is the check a read cannot make (NBSP, `—` vs `–`, `…`, `≥`):

```
$ sed -n '108,129p' 02_SOLUTION_DESIGN.md > design.txt     (fences confirmed at :107 / :130)
$ sed -n '257,278p' .harness/rejected-decisions.md > live.txt
$ wc -l → 22 / 22 ;  cmp -s → IDENTICAL (cmp)
$ sha256sum design.txt live.txt
072fe7404e85121aa72b6942455740079ea770395970043cf05b5ba23f4c5117  design.txt
072fe7404e85121aa72b6942455740079ea770395970043cf05b5ba23f4c5117  live.txt
```

The digest matches the one `04_DEVELOPMENT.md:26` reports, but the finding does not depend on
that: `cmp` against the design's own §6 block closes the chain independently of any digest.

**Append-only / no reflow (D-9 / D-10).**

```
$ git diff --numstat -- .harness/rejected-decisions.md         → 179  0
$ git diff -- ... | grep -c '^-[^-]'                           → 0     (zero deletions)
$ git diff -- ... | grep -c '\\ No newline at end of file'     → 0     (D-9 tolerance unneeded)
$ head -n 255 .harness/rejected-decisions.md | sha256sum
fbdf6db11ef80da023a31b2a53ede36ed41d509e0e20b4507987e177c30af898
$ tail -n 22 .harness/rejected-decisions.md | sha256sum        → 072fe740…5117
```

The `179 0` is against `H0`, not against the pre-edit working copy — DR-2's disclosure is correct,
and CR-3's ruling (substance verified, stated command measures the wrong baseline) reproduces.
Zero deletions against `H0` proves no committed line was removed or altered. To cover the residue
— a reflow of a line that is *itself* an uncommitted insertion, invisible to that measure — I
re-resolved every pre-edit line citation `02` §12 and D-2 make (`:12-17`, `:73-90`, `:191-199`,
`:201-222`, `:219-220`, `:254`, `:255`); all resolve to the cited content in the post-edit file.
That is the reviewer's D-10 corroboration, re-run rather than inherited.

**Item 4 / D-3, clause level.** A line-level grep is the wrong instrument here: both markings share
the `Decision` line by design, so `grep 'reasoning-effort' | grep 'declined'` fires on a compliant
record. Splitting on the `;` the design relies on:

```
clause 0 : - **Decision:** model-swap lever **declined**
           reasoning-effort=False | declined=True  | model-swap=True  | deferred=False
clause 1 : reasoning-effort lever **deferred** (not now) — two
           reasoning-effort=True  | declined=False | model-swap=False | deferred=True
```

`reasoning-effort` occurs exactly once inside `Decision`+`Why` (the `Decision` line); the `Why`'s
"The effort lever is deferred rather than declined" at record line 13 uses "effort lever", not the
token item 4 tests. Pre-ruled at gate round 2 §10.2 and confirmed not to be a violation on the
mechanical evidence as well as the ruling.

**Item 5, required elements.** `F-1` 1 · `F-2` 1 · `F-3` 1 · `declined` 2 · `deferred` 2 ·
`Origin` 1 · `T-22` 1 · `stage-model-tiering` 3 — all present in the record's 22 lines.

---

## Q2. The freeze proof — my own M-b, built from scratch

`02` §10.2 item 1 is defective (RES-8/CR-11) and I did not run it literally. I built my own
fixture rather than reusing the developer's, so the control is an independent measurement:

```
for f in <the eight names>; do git -C <repo> show cb0ed57:agents/$f.md > <scratch>/repo/agents/$f.md; done
git -C <scratch>/repo init -q ; add agents ; commit -m "H0 blobs"
cp <repo>/agents/*.md <scratch>/repo/agents/          # live work tree over H0 index
```

**Control — validated per file (RES-3′ insists on this; a total-only match does not validate).**

| file | live tree | M-b scratch |
|---|---|---|
| `code-reviewer.md` | 40/13 | 40/13 |
| `developer.md` | 27/39 | 27/39 |
| `gate-reviewer.md` | 41/16 | 41/16 |
| `pm-orchestrator.md` | 47/4 | 47/4 |
| `qa-tester.md` | 33/9 | 33/9 |
| `requirement-analyst.md` | 45/21 | 45/21 |
| `solution-architect.md` | 51/26 | 51/26 |
| `supervisor.md` | 4/2 | 4/2 |
| **total** | **288/130** | **288/130** |

Eight independent agreements. A fresh `git init` inherits no local `.gitattributes`,
`core.autocrlf` or `diff.algorithm`, so any configuration difference that changed hunk accounting
would have broken at least one row. None did. The `git status --porcelain -- agents/` control is
`8 × ' M'`, `?? count = 0`, matching the live tree.

**Mutation results — seven states, one control reset before each.**

| # | mutation | FZ-1 ` M` | FZ-1 `??` | FZ-1′ numstat | FZ-2 sha | FZ-3 mtime | FZ-5 `wc -l` |
|---|---|---|---|---|---|---|---|
| M1 | append `model: haiku` | 8 × ` M` — **no fire** | none | 289/130 (`28 39`) **fires** | `a7fabb1c…`→`3ada48b2…` **fires** | +7 865 s past `T0` **fires** | 91→92 **fires** |
| M2a | in-hunk, line-count-preserving edit | ` M` — **no fire** | none | `27 39` — **no fire** | `a7fabb1c…`→`ab32d2e9…` **fires** | fires | 91 — **no fire** |
| M2b | context-line edit (class boundary) | ` M` — no fire | none | `27 39`→`28 40` **fires** | fires | fires | 91 — no fire |
| M3 | delete one line | ` M` — no fire | none | `26 39` **fires** | fires | fires | 91→90 **fires** |
| M4a | edit-and-revert, mtime restored | no fire | none | `27 39` no fire | **no fire** | **no fire** | no fire |
| M4b | edit-and-revert, mtime not restored | no fire | none | no fire | no fire | `T0`+7 914 s **fires** | no fire |
| M5 | new untracked `agents/sneaky.md` | 8 × ` M` unchanged | `?? agents/sneaky.md` **fires** | 288/130 — **no fire** | glob 9 ≠ 8 **fires** | n/a | glob 9 **fires** |
| M7 | delete `agents/developer.md` | ` D agents/developer.md` **fires** | — | fires | glob 7 ≠ 8 **fires** | n/a | glob 7 **fires** |

Raw excerpts for the two rows the contract turns on:

```
### M1, FZ-1 ' M' form — control and mutated are byte-identical
$ git -C <scratch>/repo status --porcelain -- agents/ | md5sum
83cf075ed527ba91d596b8bc80f05668   (both before and after the append)

### M1, FZ-1'
40 13 agents/code-reviewer.md   /   28 39 agents/developer.md   / … ins=289 del=130

### M2a, the class no upstream row instantiates
OLD: '3. **The rationale portion** — `docs/features/<task-slug>/04_RATIONALE.md`, …'
NEW: '3. **Th3 rationale portion** — …'
wc -l 91 | status ' M' | numstat '27  39' | sha a7fabb1c74bf5568 → ab32d2e9d48bf6a7
```

**Why M2a matters.** The standing rule is that a fixture producing the expected verdict is not
evidence that it discriminates (T-16 QA D-1), and the sharper question is which members of the
admissible class no row instantiates (T-20 QA-1). `04_RATIONALE.md` §R6 instantiates exactly two
members — a one-line append and an untracked file. The admissible class is "any edit to an
`agents/*.md`", and its most evasive member is the in-hunk, line-count-preserving edit: it defeats
`git status`, `git diff --numstat` **and** `wc -l` simultaneously, because all three are functions
of git's diff accounting or of line count, and it changes neither. Only the content digest sees it.
This is why RES-2's ruling — that AC-6's independent legs are FZ-2 and FZ-3 — is not a formality:
under M2a, FZ-2 is the *only* content predicate left standing inside `[S-A, S-B]`.

**Why the mutated hexes are and are not reproducible (CR-14).** `3ada48b29cf07985…` reproduced from
my fixture because `printf 'model: haiku\n'` on a file with a trailing newline is fully determined.
FZ-3's mutated epoch did **not** reproduce (`+7 865 s` past `T0` here vs `+4 596 s` reported) and
must not: it is the wall-clock of the run. Judged as CR-14 directs — FIRES / does-not-fire — every
row of `04_RATIONALE.md`'s table is confirmed, including the `✘`.

**RES-9, closed.**

```
$ git check-ignore -v agents/sneaky.md          → (no output), exit=1  → not ignored
$ git config status.showUntrackedFiles          → (unset), exit=1      → default 'normal'
$ git config --get core.excludesFile            → (unset), exit=1
$ wc -l .git/info/exclude                       → 6, every non-comment line empty
```

Combined with the reviewer's read of `.gitignore` (61 lines, no pattern matching `agents/*.md`),
all three suppression channels are excluded on the **real** tree, so M-b's `??` result transports.

---

## Q3. An independent freeze leg nobody ran — the whole-tree write scan

Every predicate in `02` §8 is scoped to the eight-file glob. AC-6 is wider than that: it also
claims no skill changed, no `verify_all` check was added or removed, and no version or count moved.
Those three sub-claims rested on the developer's word plus `[G.3]`/`[G.4]` passing. A single
command covers all of them:

```
$ git ls-files -z | xargs -0 stat -c '%Y %n' | awk '$1 >= 1785591045' | sort -n
2026-08-01T13:30:45Z docs/batches/default/BATCH_PLAN.md
2026-08-01T13:30:45Z docs/batches/default/STREAM_LOG.md
2026-08-01T13:32:02Z docs/tasks.md
2026-08-01T14:54:52Z .harness/rejected-decisions.md
$ git ls-files | wc -l → 499        # 4 of 499 tracked files written since dispatch
```

The first two are the dispatch write itself (`STREAM_LOG.md:88` is that line); the third is the PM
lifecycle row (and is stale — QA-6); the fourth is the single production edit, at 14:54:52Z, inside
stage 4. **No `agents/`, no `skills/`, no `.harness/scripts/`, no `.claude-plugin/plugin.json`, no
`CHANGELOG.md`, no `README*`, no `docs/dev-map.md`, no `CONTEXT.md`, no `docs/proposals/`.**

The untracked half (`--untracked-files=all`, 83 paths) returns only this task's own stage documents
since dispatch, and their mtimes give an independent stage timeline: `01` 13:40:21Z (= `T0`, so
`T0`'s provenance is confirmed rather than inherited), `01_RATIONALE` 13:41:58Z, `02` 14:36:22Z,
`03` 14:50:37Z, `05_RATIONALE` 15:17:20Z, `04_RATIONALE` 15:29:18Z, `04_DEVELOPMENT` 15:29:28Z,
`05_CODE_REVIEW` 15:42:07Z, `PM_LOG` 15:42:32Z. Note `05_RATIONALE` predates the round-2 `04`
edits, consistent with the reviewer's statement that round 2 supersedes `05_RATIONALE.md` §4's
"M5 · not tested" row without rewriting that file.

This leg shares FZ-3's limitation — an mtime can be backdated — but it is the only leg that covers
AC-6's **non-agent** clauses at all, and it covers them over the whole tree rather than a glob.

**S-C, my own capture, against `04_RATIONALE.md` §R5's table:**

```
mismatches: 0 / 8            (all eight mtimes reproduce exactly)
tightest margin to T0:        11 908 s   (pm-orchestrator)
tightest margin to T_dispatch: 11 332 s
roll-up sha256 of the eight:  31ff7e778c3ba958…      (= the reported value)
wc -l total:                  1376                   (= §8.3 exactly, zero deltas)
```

FZ-5's eight values are `166 / 91 / 113 / 293 / 156 / 101 / 169 / 287`; max 293 is 7 under the I.3
cap, next 287 is 13 under, so D-12's confirmation of `01` §4.3 reproduces. RES-1's three narrowing
anchors all hold at S-C: `01` §4.3's two counts, `02` §8.3's eight, and `03` round 2 §2's live read
— `grep -inE '^\s*model\s*:' agents/*.md` and `grep -in 'reasoning.effort\|reasoningEffort'` both
return **nothing**. The residual (a) class is therefore still "line-count-preserving, non-`model:`,
backdated, stage 0 or 1" — and QA-3 shows that class is realisable, so the narrowing is real but
the residual is not vacuous. Residual (b) is narrower than RES-1 states (QA-2).

---

## Q4. Item 7 — the record's arithmetic, re-derived

`f = a(1−r)/[c_d + c_o·(1−S)/S]`, `a = 0.373`, `k = c_o/c_d`.

```
LOW   a(1-r) = 0.373 × 0.4 = 0.1492
      denom  = 0.58 × (1 + 0.933/0.067) = 8.656716
      f      = 0.017235      /3.0 = 0.5745 %   → the record's 0.6 %
HIGH  a(1-r) = 0.373 × 0.8 = 0.2984
      f      = 0.2984/0.358 = 0.833520
                             /1.9 = 43.8695 %  → the record's 44 %
                             /3.0 = 27.784  %  → 27.8 %
```

All nine §R2.4(a) cells reproduce (`0.257/0.197/0.116 · 0.257/0.147/0.064 · 0.257/0.057/0.017`,
percentages `8.6/6.6/3.9 · 8.6/4.9/2.1 · 8.6/1.9/0.6`), as do all four §R2.4(b) corners
(`0.257 → 8.6 %/13.5 %`, `0.417 → 13.9 %/21.9 %`, `0.514 → 17.1 %/27.1 %`,
`0.834 → 27.8 %/43.9 %`) and `c_d = 0.358p + 0.803(1−p)` at `p = 0.804 → 0.4452`,
`0.5 → 0.5805`, `0.33 → 0.6562`, `1.0 → 0.358`. **No mismatch. Item 7's CRITICAL does not fire.**

I also re-derived the inputs rather than accepting them, since a reproduction from the design's own
row would be circular: from T-20's volumes and total 4051, `1452/4051 = 0.358`, `1948/4051 = 0.481`,
`3254/4051 = 0.803`, `3950/4051 = 0.975`, `1802/4051 = 0.445`, and `a = 1512/4051 = 0.3732 → 0.373`.
The rollback series recounted from `STREAM_LOG.md`: n=6 `[4,3,4,1,2,4]` sum 18 mean **3.0**; n=10
adds `:53-70`'s `[1,0,0,0]` → sum 19 mean **1.9**. `:86` (T-20) carries no count, exactly as FL-9
states. Every denominator the record's percentages use is therefore independently pinned.

**Item 7's second charge — is there an instrument?** Power, from the live n=10 series
(mean 1.9, population variance 2.690, sd 1.640), two-arm comparison, tasks per arm:

| shift | α-only (≈50 % power) | 80 % power |
|---|---:|---:|
| low corner `f = 0.017` | ≈69 570 | ≈142 142 |
| compound corner `f = 0.834` | **≈30** | **≈61** |

The record's/design's "≈30 attributed tasks" is the α-only figure (QA-5: 80 % power needs ≈61 per
arm, so the gap is larger than claimed — the error runs against the author). Against a **ten-task**
history with no pre-change baseline, no arm of any size exists. **No instrument in this repo would
detect an 11 %-to-44 % change in rollback rate**, and the CRITICAL the design attaches to naming one
does not fire.

**But the universal negative is falsified (QA-1).** G-12 pointed at `STREAM_LOG.md:53` — "T-11a ·
DELIVERED v0.41.0 (**1 design rollback** — Gate caught supervisor I.3 breach…)" — as the single
prose counterexample and ruled it survivable. I swept the archive instead:

| task | rollbacks | `PM_LOG.md` attribution | to stage 1/2 |
|---|---:|---|---:|
| T-11a | 1 | `:14` "BLOCKED ON DESIGN → rollback to SA" | 1 |
| T-11b / T-11c / T-12 | 0 / 0 / 0 | — | 0 |
| T-13 | 4 | `:53,117,132,182,207` "ROLLBACK #n → stage 2 (solution-architect)" / "→ stage 4 (developer)", each with a cause rationale | 1 |
| T-14 | 3 | `:27,31,34` stage table: "ROLLBACK → stage 2 / → stage 4 / → stage 4" | 1 |
| T-17 | 4 | `:648` `### Rollback ledger (final)` — 4 rows, `Route \| Trigger` | 2 |
| T-15 | 1 | `:54,373` "1 CRITICAL + 4 MAJOR route to SA → rollback to stage 2" | 1 |
| T-16 | 2 | `:45,49` "ROLLBACK 1 → stage 2 (solution-architect)", "ROLLBACK 2 → stage 4" | 1 |
| T-18 | 3+1 | `:111` `**Rollback ledger**: #1 gate→architect (design gap), #2 reviewer→developer (implementation omission), #3 QA→architect (normative-text defect)` | 2 |
| *(T-20, no count in `STREAM_LOG`)* | 3 | `:46,116,188` "→ Rollback 1: stage 3 → stage 1", "stage 5 → stage 4", "stage 6 → stage 4" | 1 |

**19 of 19 rollbacks in the ten-task window carry an originating-stage attribution**, two tasks
under an explicit `### Rollback ledger` heading, and the attribution is causal rather than merely
positional — the PM's routing table assigns the target *by origin*, and each entry states the cause
("design gap", "implementation omission", "normative-text defect"). Roughly 9 of the 19 attribute
to stage 1 or 2, the addressable pair.

So `.harness/rejected-decisions.md:265`'s "nothing here attributes a rollback to the stage that
caused it, at any resolution" is **false**, and false against a far larger counterexample than the
gate weighed. What is true is the *instrument* form, which the design also carries at
`02_SOLUTION_DESIGN.md:39` and `:494`: the ledgers use three incompatible shapes across the window
(free prose, a stage table, a named section), nothing aggregates them, `STREAM_LOG`'s only
structured field (`rollbacks=N`) carries **no** stage, no pre-change baseline exists, and n=10 is
below the ≈30–61 per arm the compound corner needs. The decline's leg survives in the form that
does the work; the record inherited the form that does not.

**The decline's other legs, attacked.** Findings C and D carry no rate parameter — confirmed by
reading: C is role-set reasoning over positive evidence, D is a distribution-surface fact. Finding
D specifically survived four attacks: `.claude/agents/` **does not exist** in this repo;
`sync-self.sh:58-60` records that agent mappings were **removed at v0.30.0** because the framework
agents are plugin-native; neither `.claude/settings.json` (keys: `$schema`, `_comment`,
`_hooks_moved`, `permissions`, `hooks`) nor `.claude-plugin/plugin.json` (`"skills": "./skills/"`,
no `agents` key) carries a `model`, `agents` or `reasoning*` key; and the one shadowing path that
exists — a consumer planting `.harness/agents/solution-architect.md`, which `harness-sync` copies
to `.claude/agents/` — produces a **bare-named** agent, while every framework dispatch is
namespaced `harness-kit:<name>` (`agents/pm-orchestrator.md:136,143`). The named, unclosed residual
is the same one OQ-1 already owns: whether some upstream Claude Code setting could override an
agent's declared model globally is not verifiable in-repo. Even if it could, it would be a global
switch, not the per-agent, per-project override F-3 names, so Finding D does not weaken.

---

## Q5. `verify_all`, exit semantics, and the baseline

```
$ bash .harness/scripts/verify_all.sh ; echo "exit=$?"
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
  PASS: 32   WARN: 0   FAIL: 0
exit=0
```

Four runs, identical. Check ids printed: `A.1 A.2 B.1 B.2 C.1 C.2 D.1 D.2 D.3 E.1 E.2 E.3 E.4 E.5
E.6 E.7 F.1 F.2 G.1 H.1 G.2 G.3 I.1 I.2 I.3 I.4 I.5 I.7 I.6 J.1 G.4` = 31 report lines, and
`verify_all.sh:824-826` derives `g4_count=$(( ${#report[@]} + 1 ))` = **32**, matching the summary.
The count is therefore read from the run, not from a document claim (V-2).

**RES-6, verified live.** `awk 'NR>=931 && NR<=934'`:

```
931:
932: (( errors > 0 )) && exit 2
933: (( warns > 0 )) && exit 1
934: exit 0
```

`wc -l verify_all.sh` = 934, so `:934` is the file's last line and `933-935` cannot be right.
`02` §10.1 / gate C-5's `932-934` is exact. A WARN exits 1, so C-5's conjunction (summary line
**and** `$?`) is the correct assertion and both agree.

**RES-4, re-run against the final insight wording.** The `## Insight to surface` bullet at
`04_DEVELOPMENT.md:187-192` was checked against all 14 `i6_banned` anchor sets
(`verify_all.sh:640-655`). Following D-5's own discipline I **paraphrase rather than quote** the
anchors here, because T-13's delivery-stage self-trip showed quoted anchors travel: the bullet's
match count is **zero** for every first token in the list — the adoption-skill token, all four
composition variants, all four regeneration variants, the generated-from-rules token, the
`.harness/`-to-stub token, and all four CJK sets; CJK character count is also zero. No anchor set
can complete. Stage 7 must re-run this against the **final consolidated** `07_DELIVERY.md` wording,
which may differ, and C-4 additionally forbids carrying any banned-anchor text into
`.harness/insight-index.md`, which is **not** exempt.

**Baseline.** `.harness/scripts/baseline.json` reads `verify_all_checks: 32`, unchanged, and no
driver assertion count moved (`test_guard_rm_bash_assertions` 87, `test_archive_task_bash_assertions`
186, `test_init_bash_no_python3_assertions` 355, …). No test was added, because `01` §3.3 bars
adding a `verify_all` check and the record file has no parser to test. **Baseline is preserved and
was not lowered.** Nothing to update; recorded so a later reader does not read the absence of a
baseline edit as an omission.

---

## Q6. AC-1…AC-4 and AC-8 — read-verification against `01`

These four are document properties, not code properties; `02` §11 assigns them to QA as reads.

- **AC-1** — `01` §0.1 table: A-5 publishes `6.7 % – 45 %` with grade **LOW** explicitly in the
  Confidence column; A-4 names the non-derivable step (sub-agent share of cache-read + cache-write
  traffic, "the 78 % of the bill that decides the answer") **and** the reason (it requires a
  per-call context measurement that exists nowhere, `cost-attribution-2026-08.md:85-87`). Both
  halves present. ✅
- **AC-2** — §0.2 derives the break-even from the addressable share (`≤37.3 %`, from document
  volumes) and the rollback cost, not from a model price ratio; the projection for the recommended
  disposition is **zero** (§0.5, §9). The re-derivation in Q4 confirms both terms are functions of
  the delegated share and the addressable set. ✅
- **AC-3** — §0.3's six rows cover all eight roles, each token appearing exactly once, each with a
  cited positive-evidence basis (dispatch constraint + `cost-attribution:73-76`; "writes production
  code"; `BATCH_PLAN.md:46`'s T-13 rollback; the once-per-≥5-tasks cadence;
  `.harness/insight-index.md`'s propagation record). No exclusion rests on absence of objection. ✅
- **AC-4** — §0.4 states it **necessarily propagates** and gives the reason (plugin-native, single
  source, not materialized since v0.30, `AI-GUIDE.md:13,48,57`), and states dogfood-only is
  unavailable. Independently re-attacked in Q4; held. ✅
- **AC-8** — §8 carries OQ-1…OQ-5, five `**Recommended:**` answers, four `NON-BLOCKING`, and OQ-4
  classified "**BLOCKING for the filing only, not for this task**" with the filing operator-reserved
  under the standing red lines. §9 states no BLOCKING question remains. ✅

---

## Q7. Residual dispositions and what travels

| id | disposition at stage 6 |
|---|---|
| RES-1 | Verified. The three narrowing anchors all reproduce at S-C; residual (a) stands and is now shown **realisable** (QA-3). Residual (b) is narrower than stated (QA-2). The mtime-backdating caveat is right: I used the technique myself in M4a, so "no such operation occurred" remains testimony. |
| RES-2 | Honoured. Nothing in `06_TEST_REPORT.md` counts FZ-1′ as an independent leg; M5 re-confirms FZ-1′ is blind to an untracked file, and M2a re-confirms FZ-2 subsumes it. AC-6's independent legs are **FZ-2 and FZ-3**, plus the whole-tree scan in Q3 for AC-6's non-agent clauses. |
| RES-3′ | Discharged. Control validated per file; mutated `289/130` with `28 39 agents/developer.md`. The 156/0 hypothesis was **not** re-run. M-a rows judged FIRES / does-not-fire per CR-14. |
| RES-4 | Re-run against the final insight wording — zero matches. Stage 7 re-runs against `07_DELIVERY.md`. |
| RES-5 / RES-7 | Tree state stated: `HEAD = cb0ed57`, eight files uncommitted at 288/130 per file unchanged. M-b remains reproducible today; RES-7's collapse condition has not fired. RES-5 endorsed and carried to stage 7. |
| RES-6 | Verified live; `933-935` not propagated. |
| RES-8 | Executed as corrected. FZ-1 ` M` does not fire (twice, on two mutation classes); FZ-1 `??` fires. `02:314-316` is wrong on the first regardless of fixture, and `02` §10.2 item 1 was **not** run literally. |
| RES-9 | **Closed.** Both shell-only checks run; all three suppression channels excluded. |
| CR-10 | Measured and confirmed (QA-4); the accurate form is recorded in the contract. |
| **RES-QA1** *(new, → `07_DELIVERY.md`)* | The record's `:265` universal negative is falsified by the `PM_LOG.md` rollback ledgers; the decline survives on the *instrument* form the design carries at `02:39`/`:494`. Delivery must carry the counter-evidence so a future reader who checks meets the correction, not a careless-looking record. Reserved for the operator; no rollback requested. |
