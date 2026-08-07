> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

# Test Report — stage-model-tiering (T-22)

Mode: **full** · deferred-human: defer, do not ask. Upstream: `01` §5 (AC-1…AC-8), `02` §10.2
(seven items, item 1 **as corrected by RES-8**), `05_CODE_REVIEW.md` rounds 1–2
(RES-1, RES-2, RES-3′, RES-4, RES-5, RES-6, RES-7, RES-8, RES-9, CR-10).

This task ships as a **DECLINE**: the whole production change is `.harness/rejected-decisions.md`
**+23 −0** (255→278 lines, 23→24 records). There is therefore no feature to exercise. The two
things under test are (a) a **freeze proof** and (b) an **argument that became permanent memory**.
Every measurement below was produced by my own commands on this host; nothing is inherited from
`04_RATIONALE.md`. Full transcripts: `06_RATIONALE.md`.

**Tree state actually observed (RES-7).** `HEAD = cb0ed57`, all eight `agents/*.md` still
uncommitted with unchanged content (`288/130`, per file `40/13 · 27/39 · 41/16 · 47/4 · 33/9 ·
45/21 · 51/26 · 4/2`). M-b's control is therefore reproducible **today**; RES-7's collapse
condition has not fired. RES-5 stands: any future freeze argument leaning on `agents/` being clean
is wrong while this wave stays uncommitted.

## Test plan

| acceptance criterion | test case(s) | file |
|---|---|---|
| AC-1 · band + confidence grade + named non-derivable step | read `01` §0.1: A-5 = `6.7% – 45%`, grade `LOW`; A-4 names cache-read/write share as not derivable **with** the reason (no per-call context measurement exists) | `01_REQUIREMENT_ANALYSIS.md:20-32` |
| AC-2 · saving from share + addressable set, not a price ratio | re-derived `f = a(1−r)/[c_d + c_o(1−S)/S]` from `02_RATIONALE.md` §R2.4 inputs, all 16 cells; projection for the recommendation = **zero** | `06_RATIONALE.md` §Q4; `arith.py` |
| AC-3 · eight roles, each with positive-evidence basis | grep of `01` §0.3 rows: all eight role tokens present exactly once, each row carries a cited basis | `06_RATIONALE.md` §Q7 |
| AC-4 · propagation vs dogfood-only + reason | read `01` §0.4; independently re-attacked Finding D four ways (§Adversarial AC-4) | `06_RATIONALE.md` §Q5 |
| AC-5 · exactly one `## stage-model-tiering` record | `grep -c '^## stage-model-tiering$'` = 1; case-insensitive sweep + any-level heading sweep | `06_RATIONALE.md` §Q1 |
| AC-6 · no agent edited, no skill, no check, no version/count change | FZ-1…FZ-5 re-measured at an independent capture **S-C**; six-mutation discrimination suite; **new** whole-tree write scan over all 499 tracked files | `06_RATIONALE.md` §Q2, §Q3 |
| AC-7 · PASS 32 / WARN 0 / FAIL 0, exit 0 | `bash .harness/scripts/verify_all.sh; echo $?` ×4, asserting on the summary line **and** `$?` (C-5) | `06_RATIONALE.md` §Q6 |
| AC-8 · every OQ has recommended answer + blocking classification | read `01` §8: OQ-1…OQ-5, five `**Recommended:**`, four `NON-BLOCKING`, OQ-4 scoped "BLOCKING for the filing only, not for this task" | `01_REQUIREMENT_ANALYSIS.md:215-248` |

No automated test was added and none is admissible: `01` §3.3 bars adding a `verify_all` check
(count stays 32) and the record file has no parser. The standing test surface is `verify_all`,
which I ran four times.

## Adversarial tests

One independent reproducer per acceptance criterion, each with the failure I predicted **before**
running it. Verdict rests on whether the implementation survived these, not on the developer's runs.

| AC | hypothesis ("I expect failure when…") | reproducer | outcome (≤5 lines of cited output) |
|---|---|---|---|
| AC-6 | `02` §10.2 item 1 run literally reports the freeze proof failing — FZ-1 cannot see a scratch-dir copy (**RES-8**). Under a fixture where it *can* see the mutation, FZ-1's ` M` form still will not fire for a content edit. | I built my own M-b from scratch: `git init` in scratchpad, the eight `git show cb0ed57:agents/*.md` blobs as HEAD, the eight live files copied in; then `printf 'model: haiku\n' >> agents/developer.md`. | **Survived / measurement confirmed.** Control = mutated = 8 × ` M`, byte-identical (`md5 83cf075e…` both). FZ-1 ` M` **does NOT fire** — exactly as RES-8 states and `02`'s "each must fire" does not. |
| AC-6 | The M-b control is a replay, not a measurement — I expected the per-file split to differ from the live tree under a fresh `git init` (no local `.gitattributes`, `core.autocrlf`, `diff.algorithm`). | `git -C <scratch> diff --numstat -- agents/` vs `git -C <repo> diff --numstat -- agents/`, compared **per file** (RES-3′: a total-only match does not validate). | **Survived.** Both print `40/13 27/39 41/16 47/4 33/9 45/21 51/26 4/2`, total `ins=288 del=130`. Eight independent agreements. Fixture validated. |
| AC-6 | FZ-1′ moves by +23 (the 156/0→179/0 reading). *Not re-run* — RES-3′ rules that falsifier spent. I predicted **+1**, and that FZ-1′'s +1 is too small to be a floor on its sensitivity. | Same M-b, post-mutation `git diff --numstat -- agents/`. | **Survived, exactly.** `28 39 agents/developer.md`, all other rows unchanged, total `ins=289 del=130`. FZ-1′ fires by +1. |
| AC-6 | The `??` leg is **silently dead** on the real tree — a `.gitignore`/`info/exclude`/`status.showUntrackedFiles` rule suppressing untracked `agents/*.md` (**RES-9**, the half the reviewer could not close). | `git check-ignore -v agents/sneaky.md`; `git config status.showUntrackedFiles`; `.git/info/exclude`; `core.excludesFile`. Then M5 in M-b. | **Survived — RES-9 CLOSED.** `check-ignore exit=1` (not ignored), `showUntrackedFiles` **unset**, `info/exclude` = 6 lines, **all comments**, no global excludesFile. M5 → `?? agents/sneaky.md`. |
| AC-6 | **Which member of the admissible class does no row instantiate?** I predicted a line-count-preserving in-place edit of a line *already inside a changed hunk* defeats FZ-1, FZ-1′ **and** FZ-5 simultaneously (CR-13 asserts this; nobody ran it). | M-b, edit `developer.md:16` (an added line) `3. **The` → `3. **Th3`, no line added or removed. | **HYPOTHESIS CONFIRMED — see QA-3.** `wc -l 91` (unchanged), status ` M` (unchanged), numstat `27 39` **bit-for-bit unchanged**; only FZ-2 fires (`a7fabb1c…` → `ab32d2e9…`). |
| AC-6 | FZ-1′ is *uniformly* blind to in-place edits (the strong form of the above). | Same, but on a **context** line identical to `H0` (`## Hard rules` → `## Hard rul3s`). | **Refuted — the blindness is bounded.** numstat `27 39` → `28 40`. FZ-1′ fires for context-line edits; the blind class is precisely *in-hunk, line-count-preserving*. |
| AC-6 | RES-1's residual (b) is real as stated: an **edit-and-revert** inside `[S-A, S-B]` escapes every predicate. | M-b: append then truncate, once **with** mtime restored and once **without**. | **Partly refuted — see QA-2.** With mtime restored: nothing fires. Without: mtime moves to `T0 + 7 914 s`, **FZ-3 fires**. Residual (b) requires mtime restoration; as written it over-states. |
| AC-6 | The eight-file glob is the whole freeze surface — I expected some *other* file in AC-6's scope (a skill, a script, `plugin.json`) to carry a T-22 write that the agents-only proof would miss. | **New leg nobody ran:** `git ls-files -z \| xargs -0 stat -c '%Y %n' \| awk '$1 >= T_dispatch'` over all **499** tracked files. | **Survived, decisively.** Exactly **4** hits: `BATCH_PLAN.md`, `STREAM_LOG.md` (both 13:30:45Z = the dispatch write), `docs/tasks.md` 13:32:02Z (PM lifecycle), `.harness/rejected-decisions.md` 14:54:52Z. **No `agents/`, no `skills/`, no `.harness/scripts/`, no `.claude-plugin/`, no `CHANGELOG.md`.** 0 untracked creations outside the task folder. |
| AC-5 | A near-miss heading exists — different level, casing or indentation — that `grep -c '^## …$'` misses. | `grep -inE '^\s*#{1,6}\s*.*stage.?model.?tiering'` over the whole file, plus a case-insensitive whole-file sweep. | **Survived.** One heading (`:257`). The only other hits are `:276`/`:278`, both mid-line inside `Origin`. Records 23 → 24; file 278 lines; 255 + 1 + 22 = 278. |
| AC-5 / D-1 / C-2 | Two stages verified character identity **by reading**; I expected a sub-glyph difference (`—`/`–`, `≥`, `…`, NBSP) that eyes cannot see. | `cmp` + `sha256sum` of `sed -n '108,129p' 02_SOLUTION_DESIGN.md` against `sed -n '257,278p' .harness/rejected-decisions.md`. | **Survived.** `IDENTICAL (cmp)`; both digest `072fe7404e85121a…`. Fences confirmed at `02:107`/`:130`. |
| AC-5 / D-3 | Item 4: a lever marking generalises — "reasoning-effort" sits in the same clause as "declined". A line-level grep *does* fire (both markings share the `Decision` line). | Clause-level split of the `Decision` line on `;`. | **Survived.** clause 0 = `model-swap lever **declined**` (no `deferred`); clause 1 = `reasoning-effort lever **deferred** (not now)` (no `declined`). `reasoning-effort` occurs **once** in `Decision`+`Why`. |
| AC-5 / D-10 | The append reflowed a neighbouring record — I expected a deletion or a moved anchor. | `git diff --numstat`, deleted-line count, `\ No newline` count, `sha256(head -255)`, and re-resolution of every `02` §12 line citation. | **Survived.** `179 0`; deleted lines `0`; no-newline markers `0`; `head -255` digest `fbdf6db11ef80da0…`; `:12-17,:73-90,:191-199,:201-222,:219-220,:254,:255` all resolve to the cited content. |
| AC-7 | A WARN is hiding behind a green summary, or the exit code disagrees with the printed line (C-5). | `bash .harness/scripts/verify_all.sh; echo $?` ×4, asserting both. Exit semantics read live (RES-6). | **Survived.** `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`, four times. `verify_all.sh:932` `exit 2`, `:933` `exit 1`, `:934` `exit 0` — **932-934 is exact**; `934` is the file's last line. |
| AC-1 / AC-2 | **Item 7, CRITICAL if it misses.** The record's `0.02–0.83` / `0.6%–44%` headline does not reproduce from `02_RATIONALE.md` §R2.4. | Independent re-derivation in `arith.py` of both endpoints, all nine §R2.4(a) cells, all four §R2.4(b) corners, `c_d = 0.358p + 0.803(1−p)`, and the FL-3 line shares. | **Survived, exactly.** Low `0.1492/8.656716 = 0.017235`, `/3.0 = 0.5745%` → **0.6%**. High `0.2984/0.358 = 0.83352`, `/1.9 = 43.8695%` → **44%**, `/3.0 = 27.784%` → **27.8%**. All 16 cells and `a = 1512/4051 = 0.3732` reproduce. |
| AC-2 | The rollback series the denominators rest on does not reproduce (FL-9's n=6 → n=10 move). | Recount `STREAM_LOG.md` `:53-70` and `:72-86` from the live file. | **Survived.** n=6 `[4,3,4,1,2,4]` sum 18 mean **3.0**; n=10 `[1,0,0,0,4,3,4,1,2,4]` sum 19 mean **1.9**. `:86` (T-20) carries no count, as FL-9 states. |
| AC-2 | **Item 7's second charge.** The universal negative at `:265` is false, and an instrument exists that would detect an 11%–44% change. G-12's target `STREAM_LOG.md:53` is the *weakest* counterexample; I expected a stronger one. | Swept `PM_LOG.md` in all eleven tasks of the n=10 window + T-20 for rollback-to-stage attribution; then a power calculation from the live series variance. | **SPLIT — see QA-1.** The universal negative is **FALSIFIED**: 19/19 rollbacks are attributed to an originating stage in `PM_LOG.md`, two under an explicit `### Rollback ledger` heading. The **decline survives**: no instrument aggregates them, and detection needs ≈30 tasks/arm (α-only) to ≈61 (80% power) against a ten-task history. |
| AC-3 / AC-4 | **Finding D is breakable** — a consumer *can* override a plugin agent (local `.claude/agents/`, `harness-sync`, a settings key, a `model` override). This is the decline's strongest leg. | Four attacks: repo-wide `.claude/agents` search; `sync-self.sh` mappings; `.claude/settings.json` + `plugin.json` key inspection; `harness-sync` shadowing path. | **Survived all four.** `.claude/agents/` does not exist; `sync-self.sh:58-60` records agent mappings **removed at v0.30.0**; no `model`/`agents`/`reasoning*` key in `settings.json` or `plugin.json` (`"skills": "./skills/"` only); a consumer-planted `.harness/agents/solution-architect.md` syncs to a **bare-named** sibling the PM never dispatches (`agents/pm-orchestrator.md:136,143` dispatch `harness-kit:<name>`). |
| AC-8 | An open question is classified BLOCKING and unresolved at the verdict. | Read `01` §8 and §9. | **Survived.** OQ-1/2/3/5 `NON-BLOCKING`; OQ-4 "**BLOCKING for the filing only, not for this task**", filing operator-reserved; §9 states no BLOCKING question remains. |

**What I tried to break and could not, and why it held.** The freeze proof's independent legs are
**FZ-2 and FZ-3** (RES-2 honoured — FZ-1′ is corroboration subsumed by FZ-2, and contributes nothing
to stages 0–3). I attacked them with six distinct mutation classes rather than the one `02` names.
FZ-2 fired on every content change including the class that defeats all three other predicates;
FZ-3 fired on every write, including an edit-and-revert. They held because they are the only two
predicates that do not depend on git's *diff accounting*, which is what the other three share and
what the in-hunk class exploits.

## Boundary tests added

- Mutation M1 · one-line `model: haiku` append (the exact declined change) — FZ-2 / FZ-3 / FZ-5 / FZ-1′ fire; FZ-1 ` M` does not.
- Mutation M2a · **in-hunk, line-count-preserving** in-place edit — only FZ-2 fires. New; no upstream row instantiates it.
- Mutation M2b · **context-line** in-place edit (class boundary for M2a) — FZ-1′ fires (`27/39` → `28/40`).
- Mutation M3 · single-line deletion — FZ-5 `91`→`90`, FZ-1′ `27/39`→`26/39`.
- Mutation M4 · edit-and-revert, **with** and **without** mtime restoration — nothing fires / FZ-3 fires.
- Mutation M5 · new untracked `agents/sneaky.md` — FZ-1 `??` fires; FZ-1′ does **not** (untracked contributes no diff); FZ-2/FZ-5 glob returns 9.
- Mutation M7 · whole-file deletion — FZ-1 prints ` D agents/developer.md`; FZ-2/FZ-5 glob returns 7.
- Empty/absent-input boundary · `.git/info/exclude` with zero effective patterns; `status.showUntrackedFiles` **unset** (default `normal`); `core.excludesFile` unset.
- Unicode/glyph boundary · byte-level `cmp` of the 22-line record covers `—`, `–`, `≥`, `…` and every `**` span, which a read-based check cannot.
- Trailing-newline boundary · file ends `0x0a`; `\ No newline at end of file` count 0, so D-9's tolerance clause is unneeded.
- Whole-tree boundary · 499 tracked + 83 untracked paths scanned for a post-dispatch write, not just the eight-file glob.

## verify_all result

```
total checks: 32 (31 printed [X.n] report lines + G.4 itself, verify_all.sh:824-826)
pass: 32
fail: 0
warn: 0
exit code: 0            (asserted separately from the summary line — C-5)
runs: 4                 (all four identical)
new tests added: 0      (01 §3.3 bars adding a check; count stays 32)
baseline updated: no    (baseline.json verify_all_checks = 32, unchanged; no driver
                         assertion count moved; baseline is preserved, never lowered)
```

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| **QA-1** | **MAJOR** *(non-blocking; no rollback requested — see disposition)* | `grep -inE 'rollback' docs/features/_archived/*/PM_LOG.md`. Every rollback-bearing task in the n=10 window attributes each rollback to its originating stage — `hook-truth-spec:53` "ROLLBACK #1 → stage 2 (solution-architect)"; `stage-contract-split:111` "**Rollback ledger**: #1 gate→architect (design gap), #2 reviewer→developer…"; `guard-cmd-chain:648` "### Rollback ledger (final)" (4 rows, Route + Trigger); `hook-truth-status:27,31,34`; `hook-truth-verify-scope:373`; `hook-truth-derivation:45,49`; `harvest-wrapped-insight:46,116,188`; `entropy-watch:14`. **19/19 rollbacks attributed.** The record's universal negative is therefore false as written. It is **falsified more strongly than G-12 anticipated**: the gate weighed one prose note (`STREAM_LOG.md:53`) and ruled it survivable; the actual counterexample is a repeated, sectioned, whole-history record. **The decline survives** — no instrument aggregates the ledgers, they carry three incompatible shapes across the window, no pre-change baseline exists, and detection of the compound corner needs ≈30 tasks/arm at α-only / ≈61 at 80% power against a ten-task history. So `02`'s *instrument* form (`:39`, `:494`) holds; the record inherited the *attribution* form, which does not. | `.harness/rejected-decisions.md:265`; same wording upstream at `02_SOLUTION_DESIGN.md:57`, `02_RATIONALE.md:148` |
| **QA-2** | MINOR | Append then truncate in M-b, twice. With `touch -d @<orig>`: sha, mtime, `wc -l`, numstat and porcelain all equal the control — nothing fires. Without: mtime lands at `T0 + 7 914 s`, so **FZ-3 fires**. RES-1's residual (b) as written ("an edit-and-revert inside `[S-A, S-B]`") therefore over-states the uncovered class; the true form is "an edit-and-revert **that also restored the mtime**". The over-statement errs **against** the author, so the residual is narrower than the record's own account of it. | `05_CODE_REVIEW.md:87` (RES-1); `04_DEVELOPMENT.md:146-148` |
| **QA-3** | NIT *(upward: converts an asserted claim into a measured one)* | M2a above. An in-hunk, line-count-preserving edit leaves FZ-1 ` M`, FZ-1′ (`27 39`) and FZ-5 (`91`) **all** unchanged; only FZ-2's digest moves. Consequences: (i) CR-13's blind-spot claim is now measured, not argued; (ii) inside `[S-A, S-B]` this class reduces the freeze proof to **one** content predicate; (iii) RES-1's residual (a) gains a constructive existence proof — the "line-count-preserving, non-`model:`" edit it hypothesises is realisable in three seconds. Costs the proof nothing (FZ-2 fires), but no row in `04_RATIONALE.md` §R6 instantiates it. | `04_RATIONALE.md:424-431`; `05_CODE_REVIEW.md:186` (CR-13) |
| **QA-4** | NIT *(CR-10 measured and confirmed)* | Two mutation classes (M1, M2a) both leave `git status --porcelain -- agents/` byte-identical. So `04_DEVELOPMENT.md:204`'s "**Every** predicate has been shown to fire on a mutation under the method its own row declares" is inaccurate. **Accurate form, recorded here as the authoritative measurement:** *every predicate except FZ-1's ` M` form fires; FZ-1's ` M` form does not fire on any content edit, and that non-firing is itself the measured result — corroborated on real data by FZ-4's null.* | `04_DEVELOPMENT.md:204` |
| **QA-5** | NIT | The design's and record's "≈30 attributed tasks" to resolve the compound corner is the α-only (≈50 % power) per-arm `n`; from the live series (`n=10`, var 2.690, sd 1.640) 80 % power needs **≈61 per arm**. The error runs **against** the author — the instrument gap is larger than claimed — so it strengthens the decline. No action. | `02_SOLUTION_DESIGN.md:58`; `02_RATIONALE.md:149-150` |
| **QA-6** | NIT *(out of scope — reported, not filed against T-22)* | `docs/tasks.md`'s active row still reads `T-22 \| stage-model-tiering \| 1 — requirement analysis` at stage 6. Same defect class `guard-cmd-chain/PM_LOG.md:645-646` recorded for T-17 ("stale at stage 6 — caught by the capture step, not by me"). `docs/tasks.md` is explicitly out of this stage's scope; PM/stage 7 owns it. | `docs/tasks.md:9` |

**QA-1 disposition (deferred-human: defer, do not ask).** I do **not** request a rollback.
Repairing `:265` means re-opening §6, which C-2/D-1 freeze and which only stage 2 may change,
costing a full 2→3→4→5→6 round for one clause while changing nothing built — the
`BATCH_PLAN.md:46` zero-yield shape, and the same reasoning the reviewer applied to DR-1 and DR-4.
The operative claim (no *instrument*, so the payoff cannot be verified) is intact and independently
re-verified here, and the design already carries the defensible wording at `02:39` and `02:494`.
Reserved for the operator; travels as **RES-QA1** so the archive carries the counter-evidence and a
future reader who checks `PM_LOG.md` meets the correction rather than concluding the record was
careless. Recommended repair, if §6 is ever legitimately re-opened: replace "attributes a rollback
to the stage that caused it" with "**measures a per-stage rollback rate**".

**Pre-ruled and deliberately not filed.** All seven items in the dispatch's do-not-file list were
checked and none is filed: the archived `Origin` path (D-4/RK-3); FZ-4's null; the `44%`/`0.02`/
`0.83` roundings; "The effort lever is deferred rather than declined" (the token `reasoning-effort`
occurs **once** in `Decision`+`Why`, on the `Decision` line, correctly clause-separated); `01`
§2.6's qualitative single-digit component; `02_RATIONALE.md` §R4.1's out-of-scope worked example;
G-11's `T-13`/`T-013`. **RES-6 honoured:** `verify_all.sh:932-934` is the correct citation and I
have re-read it live; the `933-935` numbers are not propagated anywhere in this document.

## Stability

- `verify_all.sh` run **4×**: `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0` every time. No flakes.
- The M-b fixture was rebuilt from `cb0ed57` blobs and re-measured across **seven** mutation states with a control reset before each; every control returned to `288/130` per file and `8 × ' M'`. Deterministic.
- The M-a digest `3ada48b29cf07985…` reproduced from my independently constructed fixture, matching `04_RATIONALE.md:426`. CR-14 correctly rules this **not required** — the reproducible claim is FIRES / does-not-fire — but it did reproduce, giving a third independent pin. FZ-3's mutated epoch did **not** reproduce (`+7 865 s` vs the reported `+4 596 s`) and correctly should not: it is wall-clock-specific. CR-14's principle generalises to FZ-3.
- No perf NFR is stated for this task, so perspective 5 is not engaged.

**Zero footprint.** Both scratch trees removed. Post-run: agents roll-up digest
`31ff7e778c3ba958…` (unchanged), `8 × ' M'` with no `??` and no ` D`, `wc -l` total **1376**,
`.harness/rejected-decisions.md` 278 lines with record digest `072fe7404e85121a…`, tracked files
written since `T_dispatch` still **4**. No `agents/*.md`, no upstream stage document, no
`verify_all` check, no `docs/proposals/`, no version, no `docs/tasks.md`, no `BATCH_PLAN.md`, and
no line of `04_RATIONALE.md` (which sits at exactly 500/500) was written by this stage.

## Verdict

APPROVED FOR DELIVERY (0 BLOCKER, 0 CRITICAL, 1 MAJOR non-blocking, 1 MINOR, 4 NIT)
