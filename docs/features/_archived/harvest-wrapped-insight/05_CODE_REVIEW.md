# 05 — Code Review — T-20 `harvest-wrapped-insight`

> Contract portion. The hand re-derivations (the 186-row recount from scratch, the `qa1f` trace, the
> bound-transcript re-derivations, the `K-71`/code clause map) are in `05_RATIONALE.md`.

Mode: `full`. Human channel: deferred — nothing was escalated.

Identifiers (`CR-n`) are stable labels; a gap is a withdrawn id. Severity: **CRITICAL** blocks;
**MAJOR** must be fixed before merge; **MINOR** recorded; **NIT** preference.

Round 4 is a **verification round** on round 3's `CHANGES REQUESTED` (1 MAJOR, 6 MINOR). Three agents
worked in parallel on disjoint files. Every finding is confirmed closed **at the artifact** below, or
said not to be.

## The developer's no-shipped-change claim, verified

Round 2 made this claim and it held; round 3 made the opposite claim and every anchor moved. So it is
checked, not accepted. **The claim is true.** `archive-task.sh` is 426 lines with the fence walk at
`:255-293`, the backtick-info rule at `:261`, the closer at `:264-266`, the EOF refusal at `:290-293`,
pass B's blank/preamble/heading/fall-through at `:143-145`/`:150`/`:158-160`/`:167`, the tally trio at
`:347-351`, the write-phase marker at `:363` and the three deferred-NIT sites at `:328-330`, `:205`,
`:394-395` — **every anchor round 3 cited resolves to the same statement it cited**. `archive-task.ps1`
holds `$atReFence` at `:63`, `$atHQuoted` at `:257`, the walk at `:288-326` and the report at
`:394-395`. Both `templates/common/` mirrors are line-identical to their repo copies across the whole
changed range (`:240-306` bash, `:60-63` PS). `verify_all.sh`'s `I.4` is unmoved at `:472-545`, its
`step` call still at `:535` with the same four arguments. Nothing routes differently.

**One anchor class did move, and it is mine.** The `qa1f` case was inserted at `test-archive-task.sh:1015-1066`,
so every driver anchor **below 1015** shifted ~+53. Round 3's citations of `AC-4` (`:1016-1086`),
`AC-7` (`:1089-1099`) and `AC-3` leg (i) (`:1102-1115`) are stale; the table below is re-anchored.
Everything at or above `:1013` — including all five `QA-1` blocks and the `AC-15` corpus block — is
byte-unmoved. No developer document cites a driver line number, so nothing of theirs went stale.

## Files reviewed

- `.harness/scripts/archive-task.{sh,ps1}` and both `templates/common/` mirrors — re-read at every
  cited anchor, plus the full bash file
- `.harness/scripts/test-archive-task.sh` (full, 1182 lines) and `.harness/scripts/test-archive-task.ps1`
  (the `qa1f` case in full; banner set unchanged elsewhere)
- `.harness/scripts/verify_all.sh:466-545` and its full `step`-id enumeration; `verify_all.ps1:448-497`
- `.harness/scripts/baseline.json` (`:24`, `_qa_note_t20` in full)
- `02_SOLUTION_DESIGN.md` (`K-5`…`K-8`, **`K-71`**, `K-61`…`K-67`, §D.1, §F); `01_REQUIREMENT_ANALYSIS.md:143-149`;
  `01_RATIONALE.md:184-188,327`; `04_DEVELOPMENT.md`, `04_RATIONALE.md` (both full); `PM_LOG.md`;
  `docs/dev-map.md:101,107`
- **Not opened**: `docs/proposals/frontier-gaps-2026-07.md`

## Round-3 findings — disposition

| id | sev | status |
|---|---|---|
| `CR-9` | MAJOR | **CLOSED** — verified below |
| `CR-10` | MINOR | **CLOSED** (a), (b) and (c) |
| `CR-11` | MINOR | **CLOSED** by the architect; `K-71` verified against the code |
| `CR-12` | MINOR | **CLOSED**; the hand-trace labelling is the honest form |
| `CR-13` | MINOR | **CLOSED**; `qa1f` exercises all three tilde paths in both twins |
| `CR-14` | MINOR | unchanged — **accepted as shipped**, recorded; no work owed |
| `CR-15` | MINOR | **CLOSED** — `PM_LOG.md` 673 → **383** lines, inside the 500 cap |
| `CR-7` | MINOR | **carried**, unchanged; re-anchored to `test-archive-task.sh:1155-1168` |
| bound-4 NIT | NIT | **CLOSED** — the table now reads "1 or more" with the ⚠ delta marked |
| index-mode-asymmetry NIT | NIT | **CLOSED** — `K-71`'s closing sentence states it as deliberate |
| 3 deferred shipped NITs | NIT | deferred again on **new** ground; the ground holds (below) |

### `CR-9` — closed, and checked properly because it was the MAJOR

I swept `04_RATIONALE.md`, `04_DEVELOPMENT.md` and `_qa_note_t20` for every occurrence of `152`,
`181`, `70/82`, `82/99` and bare `70`/`99`. **Every one sits inside an explicit round marker or a
SUPERSEDED clause.** The three round-3 sites are individually repaired: the anti-revert section is
re-transcribed at `186`/`84/102` with a round-history table (`04_RATIONALE.md:378-426`); "back to
70/82" now reads "*a round-2 figure over the then-152-row set, superseded; the current split is
84/102*" (`:471`); and the `AC-4` block is three legs and ten transcribed `PASS` lines (`:132-168`).
`_qa_note_t20` carries the same discipline inline ("a ROUND-2 figure … SUPERSEDED: the current split
is 84/102"), and item 17(b)'s enumerated list is now **six** cases against a stated count of six.

The fix also delivered the part of `CR-9` that was not a number: the 41-document **fence** census,
which round 3 asserted in one clause with no trace, is now a per-document table with aggregates
(`04_RATIONALE.md:190-228`). The developer re-ran it independently and reproduced `05_RATIONALE.md`
§3 exactly — marker-character set `` {`} ``, length set `{3}`, info set `{'', 'json'}`, none open at
EOF, every fence before its heading. **Two independently-executed censuses agreeing is what turns
`CR-14`'s blast radius from a claim into a measurement**, and it is the strongest single artifact
this round produced.

### `CR-13` — closed; the fixture is not a one-path fixture

Traced line by line through `archive-task.sh:255-293` (`05_RATIONALE.md` §2). The `qa1f` document
exercises all three tilde-only paths, each with a distinct failure mode:

| path | site | how the fixture fails if the path is wrong |
|---|---|---|
| tilde **opener**, info string holding a backtick | `:261` first disjunct | the opener would not open, the quoted heading at fixture line 6 would become the section, tally reads `entries 2` and the documentation bullet reaches the index |
| **mismatched** closer (a backtick run inside a tilde fence) | `:264` character test | it would close the fence, the second `## Insight` would be misparsed and the quoted bullet would reach the index |
| tilde **closer** | `:264-266` | the fence would be open at EOF, `:290-293` fires, exit 3 with nothing written |

My hand-trace of the fixture yields `entries 1, continuation lines 0, ignorable lines 2 (terminal
footer 0), unaccounted lines 0`, `Quoted headings: 1`, exit 0 — **byte-identical to the five asserted
values**. The PS twin's fixture is element-for-element identical to the bash heredoc (19 lines) and
its five assertion labels are string-identical, so the label-set instrument still works across twins.
Both fixtures are single-quoted / quoted-heredoc, so neither shell processes the embedded backticks.

### `CR-12` — closed, and the hand-trace labelling is the honest form, not a hedge

The bounds table is now nine rows with three ⚠-marked corrections (`2a`, `2b`, `3a`), the bound-4
number fixed, and bound 5's `Quoted headings: 2` demoted from a property of the shape to a count of
that fixture. **I re-derived the two new transcripts against pass B by hand and both reproduce
exactly** — bound 2a's `entries 1, continuation 0, ignorable 3, unaccounted 3` and bound 2b's
`entries 1, continuation 1, ignorable 2, unaccounted 2` are each the unique answer the shipped code
gives on the fixture shown (`05_RATIONALE.md` §3). That is a second route to the captured figures
that needs no run.

**Ruling on the labelling.** Round 2's silent exit-0 truncation is marked a **hand trace** because
round 2's script exists in no commit — `HEAD` is the pre-change script and the T-20 work is
uncommitted. That is a true and checkable statement of why it cannot be captured, it names the
mechanism (`RE_SECTION_END` matching the quoted heading), and my own `05_RATIONALE.md` §5 derived the
same outcome independently in round 3. A hedge would be stating the outcome with no provenance, or
labelling it "measured" beside the genuinely-captured exit-3 half. Reconstructing round 2's discovery
into a scratch script would have produced a *weaker* artifact — a script re-created from a document —
wearing the stronger word "captured". **The labelling is correct and I want it on the record as the
form to copy.**

### `CR-11` — closed; `K-71` describes the shipped behaviour, not an idealisation

This is the direction that drifts most easily — design catching up to code — so `K-71` was checked
clause by clause against `archive-task.sh` (map in `05_RATIONALE.md` §4). All ten clauses hold,
including the three that are easy to get subtly wrong: fence state tracked **once** governing opener
*and* terminator (one `fence_char`, read at `:270`, `:278` and `:282`); the EOF refusal reusing the
existing `unaccounted > 0` machinery with no new arm (`:290-293` → `:336`); and `Quoted headings:`
printing on **every** terminating path, refusal included (`:348-350` sits above the `:353` refusal
block — verified, not assumed). `K-6`'s terminator sentence now separates the *predicate* (unchanged)
from a line's *eligibility* (not), which is exactly the distinction round 3 asked for. `K-71` also
states the pass-B scoping and the deliberate index-mode asymmetry, closing a round-3 NIT.

### The three deferred shipped NITs — the new ground holds

Round 3 recorded that two of the three round-2 deferral grounds had expired. The developer did not
re-use the expired ground; it stated a narrower, round-specific one: round 4 is a document-correction
return whose single authorised code change is a driver fixture, and `archive-task.sh` is **mirrored**,
so taking either NIT would move a shipped file, shift every anchor a third time — including the
anchors `CR-10`(a) is correcting and every anchor in this read-only document — and re-open the
byte-identity and construct sweeps, to buy a comment and a `trap`. **Accepted.** It is a real,
specific, bounded cost against a cosmetic gain, and it is the round-expansion the PM's stop rule
exists to prevent. It is also explicitly *not* permanent: the developer routes all three to whichever
task next opens those files, and flags that the `.tmp` residue is the only one with behaviour attached
and should be taken with a `trap`. That is the right disposition.

## Findings

### CRITICAL

None.

### MAJOR

None. `CR-9` is closed at all three sites and at the baseline note.

### MINOR

None new. `CR-14` (unterminated-fence refusal broader than it needs to be) and `CR-7` (`AC-3` leg (i)
is indirect) stand as **carried records with no work owed** — both were adjudicated accepted in
earlier rounds and neither moved this round.

### NIT

- **[TEST] bound 5's own published direction is captured but pinned by no driver row.** `qa1f` pins
  the **mirror image** — a backtick run failing to close a tilde fence — while the published bound is
  a tilde run failing to close a backtick fence. That direction is captured in a sandbox transcript
  (`04_RATIONALE.md:329-334`) but has no row. This is **not a re-open of `CR-13`**: `CR-13` asked for
  the tilde opener, the tilde closer and the unrestricted-info path in one fixture and got exactly
  that. Both directions exercise the *same single character comparison* (`archive-task.sh:264` /
  `.ps1:301`), which is symmetric in the character in both engines, so no divergence between them is
  constructible. Record-only; the natural row for a later task that widens the fence rule.
- **[MAINT] `02_SOLUTION_DESIGN.md` ends with a trailing blank line at `:501`**, so `wc -l` reads 501
  against the 500-line cap in `.harness/rules/70-doc-size.md`. The architect's count of 500 is right
  about content. One byte.
- **[DESIGN] `K-71` leaves the backtick-info restriction to the word "CommonMark".** It spells the
  opener and closer clauses out but not the one clause where the two branches differ — a backtick
  opener's info string may hold no backtick, a tilde opener's is unrestricted — which is precisely the
  clause `CR-13` found untested. Covered by reference and correct as written; worth a half-sentence if
  `02` is ever reopened for another reason. Not worth reopening it for.
- **[MAINT] carried, unchanged:** the three deferred shipped NITs above; `archive-task.ps1:63`'s
  `\s{0,3}` vs `.sh:67`'s `[[:space:]]{0,3}` (pre-existing engine class, declared in both matcher
  registers); `Quoted headings:` printing *between* the two tally lines (no consumer reads by
  position — all match by prefix).
- **[RECORD] carry-forward, PM, stage 7** — `CHANGELOG.md`'s `[0.46.0]` section still carries no T-20
  entry (ledger row 21) and there is still no `[0.47.0]` heading. Unchanged from rounds 2 and 3.

## Tallies

| figure | status |
|---|---|
| `test-archive-task.sh` **186 / 0** | **independently recounted from scratch, and it lands exactly.** 187 line-start assertion call sites − 7 multi-line `if/else` pairs + 2 (the `AC-4` leg loop's 4 sites fire 6 times) + 4 one-line `if … then ok; else no` rows = **186**. Method and per-site enumeration in `05_RATIONALE.md` §1. This is a stronger corroboration than round 3's, which carried 152 by reference; recounting the whole file from zero also retro-corroborates 181 and 152. The **run** is dev-reported |
| anti-revert **84 / 102** (was 82/99) | **corroborated by derivation.** I traced each of the 5 new rows against the pre-change awk's semantics: rows 1 and 3 green (that script exits 0 and harvests the real bullet — fences never mattered to it), rows 2, 4 and 5 red (no tally line; it writes the tilde-quoted documentation bullet; no `Quoted headings:` line) — **2 green / 3 red**, agreeing row for row and reason for reason with the capture. 82+2 = **84**, 99+3 = **102**, and 84+102 = **186** closes against my own recount. Honest limit: the brief stated the split before I traced it, so this is a corroboration of *which rows and why*, not a blind prediction |
| the 5 new rows' **measured** provenance | correct call. The split was captured rather than predicted, and the developer says so; a prediction here would have been easy and worth less |
| `verify_all` **32 / 0 / 0**, check count **32** | **independently enumerated.** 67 `step` call sites resolve to **32 distinct ids** — 31 `X.n` ids plus `E.4b` at `:255-257`. `I.4` is byte-unmoved at `:472-545`; round 4 touched no `verify_all` file. The run is dev-reported |
| `AC-15` **41 / 34 / 0 / 3** | **corroborated structurally.** `archive-task.sh` is byte-unchanged (verified above) and no archived document was touched, so the census cannot have moved; the developer re-measured it anyway with an independent walker. Both floors still sit exactly on the measurement (`:384-393`) |
| `baseline.json` 181 → **186** | **verified at `:24`**; `_qa_note_t20` re-transcribed to this round's figures with round markers throughout |
| the 41-document fence census | **two independent executions agreeing** — mine (round 3) and the developer's (round 4) — on marker set, length set, info set, evenness, EOF state and heading precedence |
| bound transcripts 2a / 2b | **re-derived by hand against pass B; both reproduce exactly.** `05_RATIONALE.md` §3 |
| mirror byte-identity | **line-identity verified** across the changed range in both twins; `cmp` and `sync-self --check` are dev-reported. Same read-only limit as every prior round |
| label-set corroboration, the runs themselves, everything PowerShell | **not agent-reproducible; named rather than blessed.** `comm`/`awk` label sets, the three 186/0 runs, the two 84/102 runs, `cmp`, `sync-self --check`, and the whole `.ps1` surface (operator item 17) |
| `docs/proposals/frontier-gaps-2026-07.md` | **not opened by this stage**; in no round-4 changed-file list. I cannot verify its git state without `Bash` |

## Requirement coverage check

Re-anchored where the `qa1f` insertion moved a driver anchor (marked **↻**).

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `archive-task.sh:161-166` + `:299-303`; `test-archive-task.sh:137-145`; PS `:170-174`, `:342-346` | ✅ |
| AC-2 | `archive-task.sh:336` + `:353-357`, both above the `:363` write-phase marker; driver `:175-189` | ✅ |
| AC-3 | ↻ leg (i) `test-archive-task.sh:1155-1168`; leg (ii) + `K-61` oracle `:277-298`; one `INSIGHT-SCAN` per check at `verify_all.sh:472-542` | ✅ (leg (i) indirect — `CR-7`, carried) |
| AC-4 / B-11 | ↻ `test-archive-task.sh:1069-1139` — three legs, ten rows; the multi-section fixture at `:1115-1137` with `:1136` asserting the pre-change reference really harvested both entries | ✅ |
| AC-5 | 32 distinct `step` ids enumerated; `baseline.json:10` reads 32; `I.4` unmoved | ✅ |
| AC-6 | both mirror pairs line-identical across the changed range; `sync-self --check` dev-reported; round 4 moved no mirrored file | ✅ |
| AC-7 | ↻ `test-archive-task.sh:1142-1152` — insertion-only mutation (`:1149`) of a copy of the live artifact, PASS→WARN with the named count, anchored via `i4_head()` | ✅ |
| AC-8 | PM, stage 7. Unaffected — the corpus census cannot move | ⏳ PM |
| AC-9 | `baseline.json:24,25` — one numeric key at **186**, no PS key, item 17(b) enumerates **six** cases against a stated six | ✅ **miscount closed** |
| AC-11 | `.harness/insight-index.md:3` still the only header-block edit | ✅ |
| AC-12 | `04_DEVELOPMENT.md:224-229` — five insights, each one physical line; round 4 adds none **with a stated reason** (`:231-236`), which is the right call against `.harness/rules/05-insight-index.md` at a full index | ✅ |
| AC-13 | `test-archive-task.sh:216-250` | ✅ |
| AC-14 | `test-archive-task.sh:253-298` | ✅ |
| AC-15 | `test-archive-task.sh:338-394` / `.ps1:391-443` — hard row `dirty == 0` at `:389`, floors `>= 34` / `>= 3` at `:384`/`:390`, strict tally parse at `:359-374` | ✅ |
| AC-16 | `test-archive-task.sh:302-335` | ✅ |
| B-7 / B-8 | `archive-task.sh:376-395`; driver `:563-586` | ✅ |
| B-13 / B-18 | `Write-InsightFile` unchanged; PS driver pins the index half in-driver | ✅ by construction; operator item 17 owns the run |
| B-17 | no superseded-quantity sentence anywhere in the stage-4 pair or the baseline note | ✅ **and this is the round's central property** |
| **B-20** | `01_REQUIREMENT_ANALYSIS.md:143-149` — the false blank-line clause replaced by the true property *and its consequence*, citing `QA-3` / `AT-14`'s measured 62 → 32 | ✅ **`QA-3` closed at its origin** |
| user req. 2 | every discard path is printed (`:348-350`) or refuses (`:290-293`); `K-71` now makes the report a stated **precondition** of the fence rule | ✅ |
| user req. 4 | pinned byte-for-byte against the pre-change script at ↻ `:1134` | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| `K-1`/`K-2` — one algorithm, four implementations, three passes | byte-unchanged this round | ✅ |
| `K-3` — frozen entry-start predicate, two spellings | `archive-task.sh:58`, `.ps1:52`, `verify_all.sh:473`, `.ps1:457`, driver oracle `:86` | ✅ |
| `K-4` — normalise before classification, before any write, before discovery | `:239`, `:321` | ✅ |
| `K-5` — totality | preserved; the fence-open line is reported outside the scan, so no line is double-kinded | ✅ |
| **`K-6` — predicate unchanged, eligibility conditional** | `02:74-79` now says exactly that; matches `:257-285` | ✅ **drift prose closed** |
| **`K-71` — section discovery (new, normative)** | all ten clauses verified against `archive-task.sh:255-293` and `.ps1:288-334` — `05_RATIONALE.md` §4 | ✅ **design now leads the code** |
| `K-7` / `K-64` — header block through an open comment | untouched; index mode fence-unaware **by stated design**, not by omission | ✅ |
| `K-8` — mode differences, and `B-20`'s inference | `02:80-88` states the true blank-line property; `01` now agrees | ✅ |
| `K-16` / `K-19` — refuse at exit 3 on `unaccounted > 0`, no bypass | the fence refusal reuses the predicate; no new arm, no flag | ✅ |
| `K-18` — tally lines | `D-3`'s two lines plus a third conditional line; neither tally line's shape moved | ✅ with `D-7`(iv) |
| `K-30` — driver in neither mirror set nor `F.1` | `test-archive-task.*` absent from `templates/`; `dev-map.md:107` says so | ✅ |
| `K-61`, `K-62`, `K-63`, `K-65`, `K-67` | re-verified at their current anchors | ✅ |
| `D-1`…`D-6` | unchanged, all ACCEPTED on their round-1 bases | ✅ |
| `D-7` | **ACCEPTED** (round 3 ruling, all four items, no re-gate); the owed prose is now delivered | ✅ **closed out** |
| `docs/dev-map.md:101,107` | `:107` now names "backtick AND tilde fences"; both rows read **v0.46**, no `v0.47` forward-reference | ✅ |

## Standing-hazard sweep

| hazard | result |
|---|---|
| **L12** — reported tallies | **clean.** 186 recounted from zero; 84/102 derived to the row; 32 enumerated; 34/0/3 structural; two bound transcripts hand-reproduced. What I cannot run is named in the Tallies table rather than blessed |
| **L26** — anti-vacuity over the 5 new rows | **clean.** Two exact-string equalities on computed values, one positive `has` on index content, one `hasnot` that is **red against the pre-change script** (it writes that bullet), one `has` on a line the pre-change script never prints. 3 of 5 discriminate against the script they exist to detect; no row can only be green |
| **L28** — deleting a container | `qa1f` is a fresh file in a fresh sandbox; `AC-7`'s mutation is still insertion-only (`:1149`) |
| **L31** — counting `grep`, `[ \t]` | **clean over every changed line.** The new rows add no `grep` at all; `sec_line`/`idx_line` keep `\|\| true` (`:80-81`); no `[ \t]` anywhere in either twin |
| **L11 / L14** — PowerShell | **re-swept over the new PS case.** No `$Is*` assignment (`$atQa1fIdx`, `$atRoot`, `$atExit`, `$atOut` — all `at`-prefixed); no `Set-Content`/`Add-Content`; no `-join`; no line-continuation backtick; no comment ending in a backtick. Every fixture line is **single-quoted**, with a comment at `:1033-1034` stating why — which is the one thing that had to be right, since the fixture's whole point is embedded backticks. Apostrophes doubled. Whole-file parse remains **unproven**: operator item 17 |
| **L22** — WARN is a hard gate failure | honoured; the live index still classifies clean → `I.4` PASS |
| **L34** — provenance prose | `v0.46` in `dev-map.md:101,107` and `baseline.json:25`; no `v0.47` reintroduced |
| mirror set / check count | intact; **32**, unmoved |
| doc-size caps | **no blocking breach.** `PM_LOG.md` 673 → **383** (`CR-15` closed); all seven stage docs inside 500; `02` is one trailing blank line over by `wc -l` (NIT); `04_RATIONALE.md` at 486 and flagged by the PM as a stage-7 "reference, don't paste" carry-forward |

## Axis status

- **Standards-conformance:** **no findings at MINOR or above; worst = NIT.** The round's one code
  change is a five-row fixture that is anti-vacuous, engine-clean in both shells, and quoted correctly
  in the one place quoting decides the outcome. `L26`, `L28`, `L31`, `L11`/`L14`, `L22` and `L34` are
  all clean over the changed surface; the mirror set and check count did not move and I verified that
  rather than accepting it; `CR-15`'s cap breach is closed by a real compaction (673 → 383), not by a
  waiver. The record discipline that produced the round-3 MAJOR is now applied consistently: every
  superseded figure in three documents carries its round, and the developer chose the harder honest
  label ("hand trace") where the easy one was available. Four NITs remain, all record- or
  preference-level, none owed to anyone.
- **Spec/design-fidelity:** **no findings at MINOR or above; worst = NIT**, with `CR-14` and `CR-7`
  carried as adjudicated-accepted records that owe no work. All 15 reviewable acceptance criteria are
  implemented and located at re-verified anchors; `B-20` is now true at its origin, so the requirement
  contract, the design and the measured behaviour agree for the first time in this task; `K-6`'s drift
  prose is corrected and `K-71` states the shipped discovery rule normatively — verified clause by
  clause against both twins, including the three clauses most likely to have been idealised. `D-7`
  closes out ACCEPTED with its owed documentation delivered. The five published bounds now state their
  refusing shapes, and the two new ones reproduce exactly when re-derived by hand.

## Verdict

**APPROVED WITH NITS (0 CRITICAL, 0 MAJOR, 0 new MINOR, 4 NIT)**

Plainly: **nothing remains that should block delivery.**

All seven round-3 findings are closed at the artifact, including the MAJOR, and two round-3 NITs
closed with them. The developer's no-shipped-change claim is true and I checked it rather than took
it. The two headline figures corroborate by routes the developer did not use — 186 by a from-zero
recount of the driver, 84/102 by tracing the five new rows against the pre-change awk — and they close
arithmetically against each other. `K-71` is the artifact I was most prepared to find drifted, and it
does not: it describes what the code does, in the terms the round-3 ruling used, including the
`Quoted headings:` report as a **precondition** of the fence rule rather than decoration.

Two things I want on the record rather than folded into a tally. The **two independently-executed
fence censuses agreeing** is the evidence that makes `CR-14`'s accepted breadth a measurement instead
of a claim; a stage that re-runs an upstream stage's evidence by its own route, and finds the same
thing, is doing the job the pipeline exists to do. And the **hand-trace label** on round 2's silent
truncation is the correct disposition of an unrunnable claim — it would have been cheaper to
reconstruct a script and call the result "captured", and that would have been worse evidence wearing
a better word.

Remaining to the PM at stage 7: the `CHANGELOG.md` entry (ledger 21), `AC-8`, and the standing
mitigation — keep every fenced example **above** the `## Insight` heading in `07_DELIVERY.md`.
