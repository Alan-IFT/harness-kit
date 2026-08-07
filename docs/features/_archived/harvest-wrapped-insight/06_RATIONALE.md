# 06 — Rationale — T-20 `harvest-wrapped-insight`

> Sibling of `06_TEST_REPORT.md`. Command transcripts, derivations and reproducer sources.
> The contract portion — plan, `## Adversarial tests`, defects, verdict — is in the report.
> Corrected in place to **round 2**. Round-1 sections that no longer describe the tree have been
> replaced; §3 now records how `QA-1` was verified *closed* rather than how it was found.

## §0 Host and tool register (`L31`)

```
GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
ugrep 7.5.0 x86_64-pc-linux-gnu +sse2; -P:pcre2jit
GNU Awk 5.2.1
Python 3 (round 2 only, for ref.py — an oracle, never a shipped artifact)
```

Matchers I used, registered with the tool that evaluated them:

| matcher | evaluated by | used for |
|---|---|---|
| `^[[:space:]]*-[[:space:]]` | ugrep 7.5.0 (`grep -c`) | raw-marker oracle. Every counting call is `\|\| true`, never `\|\| echo 0` |
| `^##[[:space:]]+Insights?[[:space:]]*$` | ugrep (`grep -cE` / `-qE`) | corpus heading census |
| `^[[:space:]]{0,3}(\`{3,}\|~{3,})` | ugrep `-cE` / `-qE` | round-2 fence-marker-in-index oracle |
| `\.\.\. (PASS\|WARN\|FAIL)$` | ugrep `-cE` | check-count recount |
| `^[0-9]+$`, `^\[[A-Za-z]+\.[0-9]+\]` | bash `[[ =~ ]]`, ugrep `-oE` | tally parsing, id extraction |
| `-F -x -e` | ugrep | fixed-line membership. **`-e` is mandatory here**: every index entry begins with `-`, and without `-e` ugrep reports `invalid option`. Same family as `L31` |
| `^ {0,3}(\`{3,}\|~{3,})(.*)$` etc. | **Python 3 `re`** in `ref.py` | the independent reference parser; deliberately a *different engine* from the ERE under test |

`[[:space:]]` is read identically by ugrep 7.5.0 and by bash 5.2's ERE engine on these fixtures; no
`[ \t]` bracket expression appears in anything I wrote.

## §1 The reported-figure re-runs (round 2)

```
$ bash .harness/scripts/test-archive-task.sh            (×3)
  === test-archive-task summary ===
    PASS: 186
    FAIL: 0                                   exit 0
$ cmp r2_drv1.out r2_drv2.out ; cmp r2_drv1.out r2_drv3.out     -> both silent
```

```
$ git show HEAD:.harness/scripts/archive-task.sh > pre.sh
  sha256 f43f549924cc0f0ae885868b5b1577774753d02eb83e0a2d840440897a74f281
$ bash .harness/scripts/test-archive-task.sh pre.sh
    PASS: 84
    FAIL: 102                                 exit 1
```

`CR-8` re-settled at the artifact — count the labels, not the header:
```
$ awk '/^Failures:/{f=1;next} f' r2_pre.err | grep -c .        -> 102
```

The label-set partition, row by row, which is the instrument rather than the totals:
```
post_all  (186 rows)   total=186  unique=186      post FAIL count = 0
pre_pass               total= 84  unique= 84
pre_fail (from stderr) total=102  unique=102
pre_all = pre_pass + pre_fail   total=186  unique=186
comm -23 post_all pre_all  -> 0 lines      (nothing only in post)
comm -13 post_all pre_all  -> 0 lines      (nothing only in pre)
comm -12 pre_pass pre_fail -> 0 lines      (disjoint)
```
The two runs exercise the identical 186-row set. The developer's per-round decomposition also holds
at the label level:
```
QA-1-labelled rows in post_all      : 26      of which pre-change PASSES:  9   (pre-FAILS 17)
CR-13/tilde-labelled rows           :  5      of which pre-change PASSES:  2   (pre-FAILS  3)
```
26 + 5 is the 31-row `QA-1` set `_qa_note_t20` names for the PowerShell twin. The nine green `QA-1`
rows are the multi-section ones, where the pre-change awk is the *correct* reference — exactly as
the note says.

```
$ bash .harness/scripts/verify_all.sh          (×3)   exit 0 each time
    PASS: 32   WARN: 0   FAIL: 0
$ grep -cE '\.\.\. (PASS|WARN|FAIL)$' r2_va{1,2,3}.out   -> 32 / 32 / 32
```
Counted *from the run*, not from `baseline.json`; the `32` literal was never the evidence.

```
$ bash .harness/scripts/sync-self.sh --check   -> In sync.        exit 0
$ cmp .harness/scripts/archive-task.sh  skills/…/common/.harness/scripts/archive-task.sh   -> IDENTICAL
$ cmp .harness/scripts/archive-task.ps1 skills/…/common/.harness/scripts/archive-task.ps1  -> IDENTICAL
  (test-archive-task.{sh,ps1} have no template mirror, by design)
$ grep '"test_archive_task_bash_assertions"' .harness/scripts/baseline.json   -> 186
```

## §2 `AC-15` — my own corpus walker, re-run unchanged

`qa-t20/qa_corpus.sh` copies `archive-task.sh` into a `mktemp -d` sandbox, copies each archived
`07_DELIVERY.md` in one at a time, drives `--dry-run`, and parses the tally with a `sed -n` whose
empty result is distinguishable from `0`. An unparseable or absent tally is classified **dirty**,
never clean.

```
QA CENSUS: matching_sections=34 clean=34 dirty=0 footer_bearing=3 no_heading=7
FOOTER(3) docs/features/_archived/ai-native-init/
FOOTER(2) docs/features/_archived/i6-semantic-guard/
FOOTER(3) docs/features/_archived/supervisor-agent/

$ find docs/features/_archived -name 07_DELIVERY.md | wc -l    -> 41
```
Identical to round 1 and landing on the developer's `41 / 34 / 0 / 3` exactly. Read-only: the corpus
files are copied out, never written.

The heading census that produced round-1's `QA-1` still explains why the corpus cannot see it:
```
$ for f in docs/features/_archived/*/07_DELIVERY.md; do grep -cE '^##[[:space:]]+Insights?[[:space:]]*$' "$f"; done | sort | uniq -c
      7 0
     34 1
```
No archived document carries two matching headings. `AC-15` is a floor over a corpus that structurally
cannot exercise the defect — which is why `QA-1` needed the constructed fixtures, and why the 26+5
driver rows matter more than the corpus figure.

## §3 `QA-1` — verified CLOSED at the artifact

The strongest available evidence is my **round-1 script, re-run unmodified**. `qa-t20/b11.sh`
hard-codes `POST=/home/alan/Programs/harness-kit/.harness/scripts/archive-task.sh`, so re-running it
reads whatever the tree currently holds; the fixture is untouched and still satisfies `K-65`'s seven
admissibility conditions.

```
round 1                                    round 2 (same script, same fixture)
pre rc=0 ; post rc=0                       pre rc=0 ; post rc=0
--- POST index ---                         --- POST index ---
  … - harvested entry A                      … - harvested entry A
                                             … - harvested entry B
RESULT: *** DIFFER *** (B-11 counterexample)   RESULT: byte-identical (B-11 holds on this fixture)
8d7
< - harvested entry B
```

`adv1.sh`, also re-run unmodified and diffed against the round-1 capture, isolates the change to
exactly the two `QA-1` rows in a 7 kB transcript (paths and dates normalised):

```
AT-5   round 1: Harvested 1 …  entries 1        round 2: Harvested 2 …  entries 2, continuation 1
                                                         + "- SECOND-SECTION insight · evidence: b:2"
                                                         + "  its continuation · evidence: b:3"
AT-9   round 1: index gained "- an example bullet that is documentation, not an insight" and "```"
       round 2: index gained "- the REAL insight · evidence: a:1"
                and stdout gained "Quoted headings: 1 '## Insight' heading(s) inside a code fence
                were not harvested"
```

`L-2`, the live stage-7 shape, driven against a **copy** of the real 30-entry index:
```
round 1                                          round 2
Harvested 1 insight entry(ies)                   Harvested 2 insight entry(ies)
entries 1, continuation lines 1, … unacc 0       entries 2, continuation lines 0, … unacc 0
RC=0                                             RC=0
REAL INSIGHT lines that reached the index: 0     REAL INSIGHT lines that reached the index: 2
```

`M-1`…`M-5` (`fence2.sh`) extend the pre/post equality beyond the single pinned fixture. Each is run
against **both** scripts and the resulting index tails compared:
```
M-1 three ## Insight sections            post: - A one|- B one|- B two|- C one   pre: identical
M-2 adjacent headings (empty first)      post: - A one                           pre: identical
M-3 heading as the LAST line of the file post: - A one                           pre: identical
M-4 terminal footer in section 1         post: - A one|- B one                   pre: identical
    (post tally: terminal footer 4, charged to section 1; section 2 unaffected)
M-5 empty section between two real ones  post: - A one|- C one                   pre: identical
M-6 '### stray heading' in section 2     post: rc=3, ':10: unaccounted line'     pre: rc=0  <- new coverage
```

The empty-range algebra is exercised rather than argued: `M-2` and `M-3` both drive
`insight_scan section lo hi` with `hi < lo` (adjacent headings push `SEC_HI = i-1 = cur_lo-1`; a
trailing heading pushes `SEC_LO = d_n`), and neither aborts under `set -u` nor mis-tallies.

## §4 Round-2 attacks on the new fence state machine

`fence.sh` (16 cases) and `fence2.sh` (9 cases). Selected transcripts; full output in the scratch
root.

**The CommonMark closer rules, all four exercised:**
```
F-2  opener ```` , closer ```     -> rc=3  "…:3: unterminated code fence opened here: ```` markdown"
                                     Quoted headings: 2   (both headings swallowed, both counted)
F-3  opener ``` , closer ````     -> rc=0  entries 1, the real entry only
F-4  closer carries "end"         -> rc=3  unterminated
F-5  opener ``` js `x`            -> declines to open (info string holds a backtick), so the
                                     following ## Insight is a REAL heading; the later ``` then
                                     opens a fence that never closes -> rc=3, 2 unaccounted
F-6  ~~~ outer, ``` inner         -> rc=0  inner does not close outer
F-7a 3-space indent               -> is a fence      F-7b 4-space indent -> is not
F-8  "> ```"                      -> not a fence (blockquote prefix)
F-16 tab indent                   -> IS a fence (bash [[:space:]] accepts tab); both twins agree
F-20 CRLF doc, closer with trailing spaces -> held; normalise_lines runs BEFORE discovery
```

**The over-broad refusal (`CR-14` / `QA-10`), two witnesses where the fence hides nothing:**
```
F-9  fence is the LAST line, after the whole section had already been harvested
     Harvested 1 insight entry(ies) …  entries 1 … unaccounted lines 1
     rc=3   "…:9: unterminated code fence opened here: ```"
     -- task dir moved? NO      index byte-identical
F-10 document has NO ## Insight section at all, one unbalanced fence
     entries 0 … unaccounted lines 1
     rc=3   "…:5: unterminated code fence opened here: ````"
     -- task dir moved? NO
```

**The `Quoted headings:` loss channel, probed from both sides:**
```
F-11 the WHOLE section lies inside a fence
     Insight tally: entries 0, … unaccounted lines 0
     Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested
     rc=0, task archived        <- the disclosed bound; the report line is what makes it one
F-12 a fence hides a '## Notes' TERMINATOR inside an open section
     rc=3  ":7: unaccounted line: ## Notes"   ":8: unaccounted line: ```"
```
`F-12` is the one that settles the design question. A hidden `##` **terminator** is *not* counted by
`h_quoted` (only `RE_SECTION_HEAD` is), so it is skipped without a report — but it cannot lose
content, because a fence can only ever *extend* a section, never truncate one, and any hidden
column-0 `##` inside the extended range is classified `U` and refuses. The counted case and the
uncounted case are therefore both closed, by different mechanisms.

The structural argument behind that, checked against the source: the open site
(`archive-task.sh:278`) and the count site (`:275`) test **the same variable** `RE_SECTION_HEAD` in
two mutually exclusive branches of one `if`, selected by one fence-state variable evaluated once per
line. A heading that would have opened a section is therefore counted whenever it is skipped, and no
line can match both `RE_FENCE` and `RE_SECTION_HEAD`.

**`CR-12`'s two shapes, both confirmed to refuse:**
```
F-14 fence after a BLANK line inside the section   -> rc=3  ":7: unaccounted line: ```"
F-15 fence containing a column-0 ## in the section -> rc=3  ":7: unaccounted line: ## Insight"
                                                             ":8: unaccounted line: ```"
     (F-15 also prints Quoted headings: 1 — counted AND refused)
```

**`QA-9`, the in-section fence, against both scripts:**
```
F-17  fence directly under an entry, containing a bullet
   POST rc=0  entries 2, continuation lines 2, … unaccounted lines 0
        index+: - REAL one | ``` | - doc example bullet | ```
   PRE  rc=0
        index+: - REAL one | - doc example bullet
F-18  fence BEFORE the first bullet ("```sh" + bullet + prose)
   POST index+: - doc example bullet | some prose | ``` | - REAL one
   PRE  index+: - doc example bullet | - REAL one
F-19  tilde variant
   POST index+: - doc example bullet | ``` | ~~~ | - REAL one
   PRE  index+: - doc example bullet | - REAL one
```
The bullet reaches the index in **both** scripts, so the entry set is not a `B-11` regression; the
fence-marker lines are new. Classification path in the source: `:146` tests `RE_ENTRY` before
anything else, so a bullet inside a fence is always `E`; `:150` makes the fence marker `I` when no
entry has been seen yet and `:161` makes it `C` once one has.

`D-D` is the same defect measured against a copy of the **live** index, where the extra entry also
costs a rotation slot:
```
Insight tally: entries 3, continuation lines 2, ignorable lines 1 (terminal footer 0), unaccounted lines 0
Rotating 3 old insight entry(ies) to insight-history.md      rc=0
REAL insights that reached the index : 2      fence markers in the index : 2
doc-example bullets in the index    : 1       archived? YES
```
compared with `D-A` / `D-B` / `D-E` / `D-F`, all of which read
`REAL 2 / fence markers 0 / doc bullets 0`, and `D-C`, which reads `rc=3 … archived? NO`.

## §5 The differential fuzz (`AT-F`) — `ref.py` and `fuzz2.sh`

`ref.py` is an **independent** implementation of the same contract, written from the CommonMark fence
rules and the T-20 section-discovery text, in a different language and a different regex engine from
the artifact under test. It emits `ENTRY <line>` for every entry-start line it places inside a
`## Insight` section, `QUOTED` for every `## Insight` heading it skips for lying inside a fence, and
`BALANCED` / `UNTERMINATED`.

`fuzz2.sh` generates random delivery documents from a 9-symbol grammar (both heading kinds, `REAL`
bullets, `DOCEX` bullets, prose, blanks, and six fence spellings including ```` ```` ````,
```` ```markdown ````, `~~~ has \`backtick\` in info` and a 3-space-indented fence), runs
`archive-task.sh` on each, and asserts three properties against `ref.py`:

- **P1 (no loss)** — every reference entry must reach `.harness/insight-index.md` on an exit-0 run.
- **P2 (no silence)** — a reference `QUOTED` on an exit-0 run must be accompanied by a
  `Quoted headings:` line.
- **P3 (refusal)** — a reference `UNTERMINATED` must produce exit 3.

```
seed 20260801  N=500  338 docs with >=1 REAL bullet   exit0  85  exit3 253   P1 0  P2 0  P3 0   inj 10
seed 7         N=400  279 docs                        exit0  57  exit3 222   P1 0  P2 0  P3 0   inj  6
seed 1234      N=400  279 docs                        exit0  69  exit3 210   P1 0  P2 0  P3 0   inj 15
seed 99991     N=400  285 docs                        exit0  56  exit3 229   P1 0  P2 0  P3 0   inj  6
```
`inj` counts exit-0 runs whose index gained a fence marker or a fenced `DOCEX` bullet — i.e. the fuzz
independently rediscovers `QA-9` at roughly one exit-0 run in eight, and finds nothing else.

Two harness bugs of my own were found and fixed before these figures were taken, and both are worth
recording because either would have manufactured a false result: (1) the first draft reused one
sandbox and did not delete `docs/features/_archived/t` between trials, so 264 of 400 runs exited 1
with `Task already archived` and the property checks never ran; (2) the first oracle counted *all*
`REAL` bullets in the document, including ones authored outside any section, and reported three
"violations" that were nothing of the kind. Only after replacing the oracle with `ref.py` did the
property become the one I actually wanted to test. A fuzz whose harness is wrong is a green light
that means nothing.

## §6 Standing residuals — re-run and diffed

```
$ for a in adv1 adv2 adv3 adv4; do bash qa-t20/$a.sh > r2_$a.out 2>&1; done
$ diff <(norm qa-t20/$a.out) <(norm r2_$a.out)          # paths and dates normalised
adv3: IDENTICAL to round 1
adv4: IDENTICAL to round 1
adv2: 2 lines differ — an index mtime literal, and "archive-task.sh: line 346" -> "line 401"
      in the QA-7 Permission-denied message (the script grew; the failure is the same one)
adv1: differs ONLY in the AT-5 and AT-9 blocks (§3)
```
Spot-confirmed positively rather than by absence of diff:
```
QA-2  AT-17  "Index tally: entries 5, unaccounted lines 0, entries after run 6"  over a file holding 5
      AT-29  fixture 5 (no final newline)  reported=[7] I.4=[6] raw=[6]  *** DISAGREE ***
             fixture 3 (commented header)  reported=[30] I.4=[30] raw=[31] AGREE  (K-61's designed inequality)
QA-4  AT-15  raw 32, "Index tally: entries 30", I.4 PASS, ALPHA/BETA still present
QA-5  AT-3   content after a break discarded at exit 0, signalled only as "terminal footer N"
QA-6  AT-4   "entries 0, continuation lines 0, ignorable lines 3 … unaccounted lines 0"  rc=0
QA-7  AT-20  history gains the rotated entry, index rewrite fails, retry duplicates
QA-8  AT-32  dry run prints the traversing mv
```

## §7 `AC-7`, `AC-11`

Unchanged from round 1 and not re-derived. `AC-7` used `K-36`'s **primary** mechanism (a sandbox
`verify_all.sh` over an insertion-mutated **copy** of the live index, never the fallback), giving
`PASS → WARN (30 entries, 1 unaccounted line(s), first at line 40) → PASS`. `AC-11` was read per line
kind against `git show HEAD:.harness/insight-index.md`: header `:3` only, entry region a pure
rotation, 27 removed lines all present in `insight-history.md` and 0 still in the index. The live
index sha is unmoved across both rounds, so neither reading has decayed.

## §8 What I could not test

`pwsh` is absent (`command -v pwsh` fails), so `archive-task.ps1`, `verify_all.ps1`'s `I.4` arm and
`test-archive-task.ps1` are unexecuted and **no PowerShell tally, parse result or run outcome is
reported** (`N-3`). I did read `archive-task.ps1:284-334` and confirm the fence walk is the
structural twin of `archive-task.sh:253-293` — same open/close predicates, same
backtick-info-string exclusion, same `$atHQuoted` counter, same unterminated-at-EOF diagnostic. That
is a code read and is labelled as one. `QA-11` records the two engine-level divergences that reading
exposed (`-match` case-insensitivity; .NET `\s` vs glibc `[[:space:]]`), both of which belong to
operator item 17's sweep and neither of which is new in this task.

`baseline.json` was **not edited**. `test_archive_task_bash_assertions: 186` already equals the
figure my own run printed; there is nothing to raise and nothing to lower. The `AC-15` corpus floors
(`>= 34`, `>= 3`) are re-measured at exactly 34 and 3 and must not be re-baselined upward when this
task's own archive takes the corpus to 35 — `_qa_note_t20` already says so and my census corroborates
it.

## §9 Reproducer inventory

Round-1 reproducers remain under the QA scratch root
`/tmp/claude-1000/-home-alan-Programs-harness-kit/18df63fc-e073-421d-b231-b393671e0e4d/scratchpad/qa-t20/`;
round-2 reproducers sit one level up in the same scratch root. All outside the repository.

| file | covers |
|---|---|
| `qa-t20/qa_corpus.sh` | `AC-15` census, independent of the developer's driver |
| `qa-t20/i4.sh` | runs the real `verify_all.sh` over an arbitrary index and prints its `[I.4]` lines |
| `qa-t20/adv1.sh` … `adv4.sh` | `AT-3`…`AT-34`, the standing residuals; re-run in round 2 and diffed |
| `qa-t20/b11.sh` | the `QA-1` / `B-11` fixture — **re-run unmodified in round 2**, now byte-identical |
| `qa-t20/live.sh` | `L-1` and `L-2`, the stage-7 simulation and its (now closed) hazard |
| `lib.sh` | round-2 sandbox helper: builds a minimal repo tree with a 3-entry index |
| `fence.sh` | `F-1`…`F-16` + `F-20` — the fence state machine, 16 cases, run twice for determinism |
| `fence2.sh` | `F-17`…`F-19` and `M-1`…`M-6`, each run against **both** the post- and pre-change scripts |
| `delivery.sh` | `D-A`…`D-F` — which shapes of `07_DELIVERY.md` are safe, against a copy of the live index |
| `ref.py` | the independent CommonMark + contract reference parser used as the fuzz oracle |
| `fuzz2.sh` | `AT-F` — the randomized differential fuzz, properties `P1`/`P2`/`P3` |
| `fuzz.sh` | the superseded first fuzz draft, kept as the record of the two harness bugs in §5 |

Each builds its own `mktemp -d` root under the scratch sandbox and copies the script under test into
it, because `archive-task` derives its repo root two levels up from its own location. Footprint
verification for the whole round: `git status --porcelain` diffed before/after (empty), index sha256
unchanged, `docs/features/_archived/` still 42 entries, no `.tmp` residue.
