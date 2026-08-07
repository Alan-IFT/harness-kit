# Development Record — stage-model-tiering (T-22)

> Contract portion. Rationale sibling: `04_RATIONALE.md` (the full S-A/S-B capture transcripts, the
> mutation test, the per-predicate arithmetic). Mode: **full** · deferred-human: defer, do not ask.
> Design contract: `02_SOLUTION_DESIGN.md` §6/§7/§8/§10/§11 and D-1…D-15. Gate conditions:
> `03_GATE_REVIEW.md` round 2 §9, C-1…C-5.

---

## Summary

This task is an ASSESS-FIRST assessment delivered as a **DECLINE**, so the entire production change
is one append: the frozen `## stage-model-tiering` record from `02_SOLUTION_DESIGN.md` §6, added
verbatim to the end of `.harness/rejected-decisions.md` (`+23 −0`, append-only, no reflow). The
record is byte-identical to §6 — it was extracted with `sed` from the design rather than retyped, so
character identity (D-1 / C-2) is a property of the method. The second deliverable is evidence: a
five-predicate freeze proof that no `agents/*.md` was edited, produced on a working tree carrying
eight siblings' uncommitted changes, and mutation-tested so it is shown to discriminate rather than
merely to pass. **One design premise failed on contact** — `agents/` is *not* outside the dirty set
— which invoked the designed contingency and moved the load onto FZ-2/FZ-3; see "Design drift".

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `.harness/rejected-decisions.md` | **The only production edit.** One `## stage-model-tiering` record appended at end of file (D-7), preceded by exactly one blank line, trailing newline preserved. 255 → 278 lines; 23 → 24 records. Bytes 1…255 unchanged, proven by digest (`fbdf6db1…f898` before and after, D-10). The appended 22 lines hash to `072fe740…5117`, identical to the extraction of `02_SOLUTION_DESIGN.md` lines 108–129 (C-2). | — (no change ledger defined for this task) |
| `docs/features/stage-model-tiering/04_DEVELOPMENT.md` | New — this file. | — |
| `docs/features/stage-model-tiering/04_RATIONALE.md` | New — capture transcripts, the `verify_all` listing, the mutation test. | — |

Nothing else was written. No `agents/*.md`, no `skills/`, no `.harness/scripts/*`, no
`docs/proposals/`, no `.claude-plugin/`, no `CHANGELOG.md`, no `README*.md`, no `docs/dev-map.md`,
no `CONTEXT.md`, no `docs/tasks.md`, no `BATCH_PLAN.md`.

## verify_all result

command: `bash .harness/scripts/verify_all.sh; echo "exit=$?"` — bash only; no PowerShell twin was
executed (V-6). Full 32-check listing: `04_RATIONALE.md` §R3.1.

- baseline (captured as A8, before the edit): **PASS 32 / WARN 0 / FAIL 0**, `exit=0`
- after changes: **PASS 32 / WARN 0 / FAIL 0**, `exit=0`
- delta: **0 new failures, 0 new warnings, check count unchanged at 32** — baseline preserved
- C-5 (both assertions agree): summary line reads `WARN: 0` **and** `echo $?` returned `0`;
  `verify_all.sh:933` exits 1 on `warns > 0`, so a WARN would have failed AC-7 — none occurred

**I.6 re-verified mechanically, and non-vacuously (V-4).** `.harness/rejected-decisions.md` is
returned by `git ls-files` (I.6's scan source) and appears in neither `i6_exempt_files` (8 entries,
`verify_all.sh:666-675`) nor `i6_exempt_dirs` (`docs/features/`, `参考/`, `:676-679`). The check
therefore ran **over the appended record text** and passed — it is not a PASS obtained by exemption.

**V-3 / E.1 unaffected.** `[E.1] … PASS` with `sync-self` never run (C-4).

## Freeze proof (AC-6) — outcome per predicate

Captures: **S-A** before the first write, **S-B** after the edit and after the final `verify_all`.
Full transcripts in `04_RATIONALE.md` §R1/§R3; arithmetic in §R5.
Anchors: `H0 = cb0ed57f5c390cbcbdc3c22c9c5e749125136204`, `T0 = 1785591621`
(`01_REQUIREMENT_ANALYSIS.md` mtime, 2026-08-01T13:40:21Z).

| id | Outcome | Evidence |
|---|---|---|
| **FZ-1** | **PARTLY DEGRADED — §8.2 contingency 1 invoked.** `git status --porcelain -- agents/` is **non-empty** at S-A (8 × ` M`) and identically non-empty at S-B. `git rev-parse HEAD` unchanged (`cb0ed57`). Path-scoped *emptiness* — and with it FZ-1's content-identity property for modified tracked files — is **not available on this tree**. Per §8.2: record the fact, FZ-2 carries the claim, do not stop. Recorded; not stopped. **Retained at full strength for the mode its Covers column names — a new untracked `agents/*.md`:** the output carried exactly eight ` M` lines and **no `??` entry** at both captures, and that leg is mutation-tested (an added `agents/sneaky.md` produces `?? agents/sneaky.md`, §R6). | `04_RATIONALE.md` §R1 A2, §R4, §R6 |
| **FZ-1′** | **PASS, and not an independent leg (added — DR-3).** `git diff --numstat -- agents/` = 288 insertions / 130 deletions at S-A and at S-B, per-file identical. Unlike `git status` it is content-sensitive inside an already-dirty file. It is nevertheless **subsumed by FZ-2** — equal digests imply equal numstat — and it spans only `[S-A, S-B]`, so it contributes **nothing** to the stages 0–3 interval FZ-1's failure vacated. Corroboration only; AC-6 does not rest on it. | §R3, §R5, §R6 |
| **FZ-2** | **PASS, 8/8.** All eight `sha256sum` digests identical S-A → S-B; roll-up `31ff7e77…8a5f` at both. Git-independent. With FZ-1 degraded this is the load-bearing predicate for the stage-4 interval. | §R1 A6, §R3 |
| **FZ-3** | **PASS, 8/8, against two anchors.** Every agent mtime is strictly less than `T0`, tightest margin **11 908 s** (`pm-orchestrator`, 3 h 18 m). Every one is also strictly less than **`T_dispatch` = 1785591045** — the T-22 dispatch boundary written at `docs/batches/default/STREAM_LOG.md:88` — tightest margin 11 332 s (3 h 08 m). No mtime is ≥ `T0`, so §8.2's contingency-2 NOTE does not arise. | §R5 |
| **FZ-4** | **NULL — the expected result** (§8.2, gate round 2 §10.5). `diff t22_s0.txt t22_s1.txt` produced no output; the dirty set is 101 entries at both captures and `.harness/rejected-decisions.md` was already ` M`. No difference was manufactured. | §R5 |
| **FZ-5** | **PASS, 8/8 exact.** `wc -l` equals §8.3's reference table with **zero** deltas — 166 / 91 / 113 / 293 / 156 / 101 / 169 / 287, total **1376**. D-13's ±1 tolerance was not invoked. Max 293 (`pm-orchestrator`, 7 under the I.3 cap), next 287 (`supervisor`, 13 under); D-12's confirmation of `01` §4.3 reproduces exactly. | §R1 A5, §R3 |

**C-1 — satisfied, and insufficient on its own.** `git log -1 --format=%cI` for `H0` is
`2026-06-21T15:00:19+08:00` (epoch 1782025219). The minimum mtime in A7b's task-folder scan is
1785591621. `H0` precedes it by **3 566 402 s ≈ 41.3 days**, and precedes `T_dispatch` by
3 565 826 s. The condition holds. But C-1 exists to underwrite D-15's transfer of stages 0–2
coverage onto FZ-1, and FZ-1's *other* premise failed, so meeting C-1 no longer delivers that
transfer. Recorded as required, and recorded as not sufficient by itself.

**C-3 — D-15's limitation, in D-15's own terms, plus what changed.** D-15 states that `stat` on
`01_REQUIREMENT_ANALYSIS.md` returns that file's **last** write, not the task's first (the earliest
artifact is `PM_LOG.md`), so an agent-file edit made during stage 1 before 01's final write would
still pass FZ-3; and that **retroactive coverage of stages 0–2 is carried by FZ-1, not FZ-3**. I do
not claim FZ-3 covers stages 1–3, and I confirm A7b's ordering directly: `PM_LOG.md`'s mtime
(1785595856) is the *latest* in the folder, not the earliest, exactly as D-15 predicts.

What must be added: **FZ-1 cannot carry that coverage on this tree**, because its premise (`agents/`
outside the dirty set) is false. So stages 0–3 are covered by neither FZ-1 nor D-15's reasoning as
written. They are covered instead by **FZ-3 read against `T_dispatch`**: all eight agent files were
last written ≥ 3 h 08 m *before* T-22 was dispatched, per an independent written record
(`STREAM_LOG.md:88`) rather than a filesystem attribute. Any write by any stage of this task would
have advanced an mtime past that boundary; none did. This is a strictly weaker guarantee than
content identity — it would not detect an edit that preserved or backdated the mtime — so it is
stated as weaker, not as a replacement. **AC-6's two independent legs are FZ-2 (content, `[S-A,
S-B]`) and FZ-3 (mtime, back to `T_dispatch`).** FZ-1′ and FZ-5 corroborate; neither adds an
independent interval. The residual this leaves is stated in `## Open issues for review` item 1.

**Non-vacuity (R-2 anticipated, not discharged).** Each predicate was mutation-tested with
`model: haiku` — the exact declined change — appended to a copy of `agents/developer.md`; **no file
under `agents/` was written.** FZ-2, FZ-3, FZ-5 and FZ-1′ each **fire**; FZ-1's `git status` form
**does not** fire for a content edit, and **does** fire for a new untracked file. FZ-1′ is measured
in a scratch git repository whose HEAD carries the eight `H0` agent files and whose work tree
carries the live ones, because measuring it on the real tree would require writing under `agents/`;
that scratch reproduces the real tree's control per-file exactly (288/130) before the mutation and
reads 289/130 after — **a +1 insertion, the true delta for a one-line append**. Table, method and
transcript in `04_RATIONALE.md` §R6. **Stage 6 must still reproduce this independently** — §11
requires QA's own reproducers. Three results QA should carry forward: (i) a `model:` key adds
exactly one line, which is exactly the delta D-13 tells the developer to forgive as a
trailing-newline artefact, so FZ-5 must never be quoted as an independent leg for this specific
mutation — FZ-2's digest is the discriminator D-13 names, and it is what separates them; (ii) FZ-1′
moves by **+1**, which is a real signal but the smallest one in the table, and it is invisible to
`git status`; (iii) FZ-1's blindness to content is demonstrated on real data rather than argued —
this task's own `+23`-line edit to an already-dirty file moved nothing in the porcelain output,
which is what FZ-4's null actually shows.

## Acceptance criteria touched at this stage

| id | State | Basis |
|---|---|---|
| AC-5 | **MET** | `grep -c '^## stage-model-tiering$'` = 1. `grep -in 'stage-model-tiering'` returns 257 (the heading), 276 and 278 (the handle and the archived path inside `Origin`) — no second heading at any level, casing or indentation. Record content is §6 verbatim, digest-verified. |
| AC-6 | **MET, with a named residual** | Freeze table above. Independent legs: **FZ-2** (8/8 digests) and **FZ-3** (8/8 mtimes vs `T0` and `T_dispatch`); FZ-5 and FZ-1′ corroborate without adding an interval; degraded FZ-1 still excludes a new untracked `agents/*.md` (no `??`). No skill added or changed, no `verify_all` check added or removed (32 at both runs), no version or count change. Residual: open issue 1. |
| AC-7 | **MET** | PASS 32 / WARN 0 / FAIL 0 **and** `exit=0`; both asserted, both agree (C-5). |
| AC-1…AC-4, AC-8 | Not this stage's | Read-verifications against `01`, performed by QA per §11. |

## Design drift

Four items; DR-1 is the substantive one. Argument for each: `04_RATIONALE.md` §R4/§R6.

| id | design item | what was done instead | why |
|---|---|---|---|
| **DR-1** `DESIGN DRIFT` | §8.2 FZ-1: *"Because `agents/` starts **outside** the dirty set, path-scoped emptiness is a content-identity statement against `H0`"* — asserted verified at `03_GATE_REVIEW.md` §3.1 and round 2 §3 | The premise is **false on this tree**. A2 at S-A returns **eight** modified agent files (288+/130− vs `H0`), mtimes 04:33–10:21 UTC on 2026-08-01. FZ-1 was recorded as degraded and the claim moved onto FZ-2/FZ-3, per §8.2 contingency 1. **No stop.** | The T-13…T-21 wave revised the agent contracts and never committed them. The gate's sort reasoning is correct (`agents/` does sort between `README.zh-CN.md` and `docs/`) but the snapshot it read is **elided at exactly that point** — the session-context `git status` block jumps from `README.zh-CN.md` straight to `docs/batches/default/BATCH_PLAN.md`. The gate labelled it *"Not a live check; A2 at S-A remains authoritative"*, which is why it cost nothing: §8.2 pre-wrote this branch, so this is a designed contingency firing, not a design gap. Flagged because three documents assert the opposite and stage 5 audits against D-1…D-15. `01` §4.5 declined to rely on dirty-set membership at all; §8's FZ-1 added a premise `01` had avoided. |
| **DR-2** `DESIGN DRIFT` | D-9: *"`git diff --stat` must show one file with `+23 -0`"* | Measured against **two** baselines and both reported. Against `H0` the file shows **`+179 −0`**; `+23 −0` is observable only against the **pre-edit working copy** (`git diff --no-index --numstat` → `23  0`; raw `diff` tally → added 23, removed 0). | The target file was **already dirty**, a fact the same design states under FZ-4, so D-9 and FZ-4 are inconsistent with each other. D-9's *substance* — append-only, 23 added, 0 deleted — holds; its stated *command* cannot produce its stated number on this tree. `git diff` vs `H0` reporting **0 deletions** across the whole wave corroborates append-only independently. The trailing-newline tolerance clause was not needed (`\ No newline at end of file` grep count 0). |
| **DR-3** additive | §8.2 specifies no replacement predicate when contingency 1 fires | Added **FZ-1′** = `git diff --numstat -- agents/`, S-A vs S-B | The contingency requires recording the degradation but does not say how to replace the lost strength. FZ-1′ removes nothing and changes no specified predicate. Flagged so the reviewer judges the addition rather than discovering it. It is **not** counted as an independent leg (see the FZ-1′ row above). |
| **DR-4** additive | §10.2 item 1 / R-2 assign the mutation test to stage 6, and prescribe one fixture — a scratch-directory copy — for all four predicates (`02:314-316`) | Run at stage 4 as well, and **split into two methods**: the scratch-directory copy for the filesystem predicates (FZ-2/FZ-3/FZ-5, exactly as written) and a scratch **git repository** for the git predicates (FZ-1/FZ-1′), whose control reproduces the real tree's output per file | Stage 5's substantive check is whether this document *supports* AC-6 or merely asserts it, and a predicate never observed to fail cannot support anything. The method split is forced: a path-scoped git command cannot see a file outside the work tree, so the prescribed fixture would make FZ-1's non-firing an artefact rather than a measurement, and the only alternative — mutating the real tree — is the change AC-6 forbids. Neither run discharges stage 6's obligation; §11's requirement of independent reproducers stands. See open issue 4. |

Non-drift, recorded for completeness: scratch paths were substituted for §8.1's `/tmp/t22_s0.txt` /
`/tmp/t22_s1.txt` (same commands, session scratchpad directory — `04_RATIONALE.md` §R1).

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| **C-1** — confirm `H0` predates the task | **SATISFIED, and recorded as insufficient on its own.** `H0` is 2026-06-21T15:00:19+08:00 (epoch 1782025219), preceding the earliest task-folder mtime by 3 566 402 s ≈ 41.3 days and `T_dispatch` by 3 565 826 s. C-1 existed to underwrite D-15's transfer of stages 0–2 coverage onto FZ-1; FZ-1's *other* premise failed (DR-1), so meeting C-1 no longer buys that transfer. | "C-1 — satisfied, and insufficient on its own" above; `04_RATIONALE.md` §R1 C-1, §R5 |
| **C-2** — §6 frozen, character-identical, do not edit | **SATISFIED by construction.** The record was extracted with `sed -n '108,129p'` from `02_SOLUTION_DESIGN.md` rather than retyped; `sha256(tail -n 22)` = `072fe740…5117` = `sha256(record.txt)`. No `§6` figure was altered. | `## Summary`; `## Files changed` row 1; `04_RATIONALE.md` §R2 |
| **C-3** — state D-15's limitation in D-15's own terms | **SATISFIED, plus the consequence D-15 could not know.** D-15's own terms are restated and A7b's ordering confirmed directly (`PM_LOG.md` carries the folder's *latest* mtime). Added: FZ-1 cannot carry stages 0–3 on this tree, so that interval is carried by FZ-3 read against `T_dispatch`, explicitly labelled weaker than content identity. | "C-3 — D-15's limitation…" above; `04_RATIONALE.md` §R1 A7b, §R5 |
| **C-4** — do not run `sync-self` | **SATISFIED.** Never invoked; `[E.1] … PASS` without it. | `## verify_all result`; `04_RATIONALE.md` §R7 V-3, §R8 |
| **C-5** — assert the summary line **and** the exit code | **SATISFIED, both asserted and agreeing.** `PASS 32 / WARN 0 / FAIL 0` and `exit=0`, at baseline and after the edit. | `## verify_all result`; listing at `04_RATIONALE.md` §R3.1 |

## Open issues for review

1. **AC-6 holds but is not airtight, and the residual is narrow rather than absent.** No surviving
   predicate covers (a) a content edit to an `agents/*.md` during stages 0–3 that also preserved or
   backdated the mtime, or (b) an edit-and-revert inside `[S-A, S-B]` — every predicate is
   endpoint-only. (a) is **narrowed, not closed**, by three independent in-record anchors that each
   reproduce exactly at S-A and S-B: `01` §4.3 (stage 1, two line counts), `02` §8.3 (stage 2, all
   eight line counts) and `03` round 2 §2 (stage 3, a live read finding no `model:` key in any of
   the eight). Together they force any such edit to have preserved **every** line count and to have
   introduced **no** `model:` key — i.e. to be a line-count-preserving, non-`model:` edit made in
   stage 0 or 1 with a backdated mtime. Stated rather than waved off because mtime backdating is
   demonstrated **inside this task** (`04_RATIONALE.md` §R6), so "no such operation occurred" is
   testimony, not a predicate.
2. **`02` §10.1's `verify_all.sh:932-934` citation for the exit semantics is EXACT — do not
   "correct" it.** Read live at stage 4: `932` `(( errors > 0 )) && exit 2`, `933`
   `(( warns > 0 )) && exit 1`, `934` `exit 0`. A WARN exits 1, as the design and gate state.
3. **Stage 6 should treat `03_GATE_REVIEW.md` §3.1's and round 2 §3's dirty-set claim as
   falsified**, not re-verify it against the same elided snapshot. The live command is
   `git status --porcelain -- agents/`.
4. **`02` §10.2 item 1 cannot be executed literally for FZ-1** — it says to run FZ-1 "against the
   mutated copy" in a scratch directory (`02:314-316`), but FZ-1 is `git status --porcelain --
   agents/`, which cannot see a file outside the work tree; run literally, FZ-1's row fails to fire
   for reasons unrelated to the predicate. Stage 6 must use a tree where the command can observe the
   mutation — the scratch git repository at `04_RATIONALE.md` §R6 method M-b is one such reading, and
   the only one found that does not require writing under `agents/`. Reported, not corrected: `02`
   is not this stage's to edit.
5. **The eight `agents/*.md` carry 288 insertions / 130 deletions of uncommitted work against
   `H0`.** Out of scope here and untouched by this task, but it means any future freeze argument in
   this repo that leans on `agents/` being clean will be wrong for as long as this wave stays
   uncommitted. Noted for whoever commits the wave.
6. **`.harness/insight-index.md` is at exactly 30 entries** (I.4 warns at `> 30`). Unchanged by this
   stage. R-3 already covers the stage-7 rotation; re-confirmed live so stage 7 does not have to.

## Dev-map updates

**None required.** No file was added, moved or removed from the project structure: the one
production change appends to an existing file, and the two new documents are per-task stage docs
under `docs/features/<slug>/`, which `docs/dev-map.md` does not enumerate per task.
`docs/dev-map.md:85` and `:172` already describe `.harness/rejected-decisions.md`, its role as the
fourth memory kind, and its "NOT byte-synced" property — all three still accurate after the append.

## Insight to surface

- A `git status` snapshot carried in an agent's session context is **elided** and cannot be used to
  prove a path is absent from the dirty set: it silently drops entries mid-list (the eight
  `agents/*.md` lines vanish between `README.zh-CN.md` and `docs/`), and two gate rounds certified
  `agents/` clean off it while the live `git status --porcelain -- agents/` returns eight modified
  files · evidence: `docs/features/stage-model-tiering/04_RATIONALE.md` §R4 vs
  `docs/features/stage-model-tiering/03_GATE_REVIEW.md` §3.1 and round 2 §3.

## Verdict

**READY FOR REVIEW.**

The single specified production change is in, byte-identical to the frozen §6 and append-only at
`+23 −0` against the correct baseline. `verify_all` is **PASS 32 / WARN 0 / FAIL 0, exit 0**, equal
to the baseline captured before the edit. AC-5, AC-6 and AC-7 are met. AC-6 rests on **two
independent legs, FZ-2 and FZ-3**, rather than on FZ-1, whose content-identity premise failed on
contact and whose failure is recorded rather than papered over; FZ-5 and FZ-1′ corroborate without
adding an interval, and degraded FZ-1 still excludes a new untracked `agents/*.md`. Every predicate
has been shown to fire on a mutation under the method its own row declares, so the proof
discriminates; the one residual class AC-6 does not cover is stated at open issue 1 rather than
asserted away. Two `DESIGN DRIFT` items are flagged above; neither changes what was built, and
neither required a design decision to be made at this stage.
