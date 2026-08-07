# 04 — Development Rationale — T-20 `harvest-wrapped-insight`

> Rationale portion. The binding record is `04_DEVELOPMENT.md`; this file carries the option
> comparisons, the measurement narrative and the captured runs behind it. Read on a named trigger —
> one of which is *a disputed tally*, which is why this file must never lag its contract half.

**State: round 4, current.** Round 3 left this file at round-2 text: it stated `152` and `70/82` as
current beside a contract document and a baseline that said `181` and `82/99`, in three places and
including a cluster enumeration wrong by 17 rows (`CR-9`, MAJOR). Every figure below is now
transcribed from a **round-4** run and every superseded figure is labelled with the round that
produced it. The current figures are **186 / 0** and **84 / 102**; `152` / `70/82` are round 1-2 and
`181` / `82/99` are round 3, and neither appears here unlabelled. The repo has paid for this shape
before — `baseline.json`'s `_qa_note_t13` records T-12's archived `278/0` figure being carried into
`docs/features/_archived/` unmarked and needing retroactive annotation — and these documents archive
at stage 7.

## Why the contract's heading rule and not the design's pass B (`X-8`, drift `D-1`)

Both readings satisfy `X-8`, which says the row must match "whichever of `01`'s `Continuation line`
or `02`'s pass B the developer implements". They differ in one observable and the difference is not
symmetric.

Under the design's pass B a `##` or `###` line following an entry has no rule of its own, so it falls
to rule 4 and becomes a **continuation**. In mode `index` there is no section terminator at all, so
the line is absorbed into the entry and, when that entry rotates, is written into
`insight-history.md` — a heading migrating into a history file, at exit 0, with a tally that reports
it as content the operator asked for. In mode `section` a `### Subheading` does not terminate the
section (the terminator is `^##[[:space:]]`, out-of-scope 10) and reaches the same rule.

Under the contract's `Continuation line` the same line is unaccounted, which reaches `K-15` / `K-16`
and refuses at exit 3 with a diagnostic naming the line. The loud outcome is strictly the safer one
for a change whose whole purpose is that nothing is lost quietly, and gate `G-16` reads the design's
outcome as the hazard rather than the intent.

The predicate is `^#{2,6}[[:space:]]`, i.e. `##` and deeper, not `#`. Two reasons. The contract says
"a `##` heading" and `X-8` says "a `##` / `###` heading line", so `##`-and-deeper is the enumerated
family. And a single `#` at column 0 inside an insight section is a plausible authored artefact that
would otherwise have become a refusal with no requirement behind it; measured against the archived
corpus the wider predicate was not needed — see the corpus census below.

The heading also clears `in_entry`. The alternative (leave the entry open, so the lines after the
heading continue it) was rejected because the run refuses either way, and clearing `in_entry` turns
every following orphan into its own diagnostic instead of hiding them inside an entry the operator
will never write.

## Why `R12` was made true rather than dispositioned (`X-10`, drift `D-2`)

`X-10` allows either. Dispositioning it would have shipped a documented silent-corruption mode into
generated projects: `K-7`'s walk never stops, the header block becomes the whole file,
`INSIGHT-SCAN` reports 0 stored entries, `total_after` can never exceed 30 so rotation never fires,
the append path writes the harvested lines *after* the unterminated marker, and `I.4` reports 0
entries and PASSes. The index then grows without bound with every line commented out and both gates
green. That is worse than the defect this task repairs, and it is reachable by a single mistyped
`-->` in a file the shipped template teaches users to edit by hand.

Three shapes of fix were considered.

1. A dedicated refusal condition (`unterminated_comment != 0`) alongside `unaccounted > 0`. Rejected:
   it is a second predicate in exactly the place the design spent `K-26` removing one, and it would
   have to be added to `I.4` as well.
2. Setting `h = 0` when the comment is open, so pass B classifies the whole file normally. Rejected:
   it produces a flood of diagnostics (the title line, every prose line of the header) and it makes
   the commented example bullet an *entry*, which is the `G-3` regression re-opened by a different
   door.
3. Reporting the **opening `<!--` line** as unaccounted while leaving `K-7`'s header derivation
   exactly as specified. Adopted. One line changes kind, the existing `unaccounted > 0` predicate
   carries both the refusal and the `I.4` WARN with no new arm, and classification stays total —
   that line's single kind is `U`. Because the run always refuses when it fires, the header block is
   never emitted on such a run, so the fact that pass A also spans that line has no observable
   effect.

The diagnostic wording differs from the ordinary one (`unterminated HTML comment opened here:` rather
than `unaccounted line:`) because "unaccounted line" is misleading for a line that is, structurally,
fine — what is broken is the file's comment balance.

## The ugrep measurement (insight 1)

Round 1 of the driver asserted `BC-9` with `grep -cP '[ \t]+$' … 2>/dev/null || echo 0` and went red
with `expected [0] got [0\n0]`. Measured rather than reasoned:

```
$ command -v grep ; grep --version | head -1
grep
ugrep 7.5.0 x86_64-pc-linux-gnu +sse2; -P:pcre2jit; …
$ grep -cP '[ \t]+$' w.txt ; echo "status=$?"
0
status=1
```

Two independent facts compose into a wrong value rather than a missing one. `grep -c` prints its
count and exits **1** when the count is zero, which is the documented contract; and the `|| echo 0`
fallback therefore fires on the *success* path, appending a second `0`. The `-P` engine is a red
herring — the same shape occurs with any counting `grep`. The fix is `grep -c '[[:space:]]$' … ||
true`: a POSIX bracket expression both greps read identically, and `|| true` preserves the printed
count instead of adding to it. Every other `grep` in the driver was re-read under the same rule; the
`K-61` oracle already used `[[:space:]]` and `|| true` and was unaffected.

## The `step()` asymmetry (insight 2, drift `D-4`)

`verify_all.sh:17-25`:

```
        WARN) echo "[$id] $name ... WARN"; ((warns++)) ;;
        FAIL) echo "[$id] $name ... FAIL"; [[ -n "$detail" ]] && echo "      $detail"; ((errors++)) ;;
```

The `WARN` arm never renders `$detail`. `verify_all.ps1`'s `Step` runs the scriptblock first, so a
`Write-Host … -NoNewline` inside the block lands on the `[I.4]` line before the verdict — the detail
is printed. So `K-26`'s "WARN … naming both counts and the 1-based line number of the first
unaccounted line" was satisfied in PowerShell and unsatisfied in bash by the same design text, and
the only symptom was a driver row asserting a correct implementation and failing.

Editing `step()` was rejected: it changes the rendered output of every WARN check in the file, it is
outside ledger row 5, and no baseline exists for the WARN output shape. Echoing the detail from
inside the `I.4` block after the `step` call is local, reproduces the `FAIL` indentation, and leaves
`step` byte-unchanged.

## `AC-4`'s fixture and why the floor holds

`K-65`'s seven conditions were satisfied literally: index line 1 is `# Insight Index — fixture` (a
non-entry line), no blank sits between it and the first entry-start line, every entry is one physical
line ending in a non-space character, the file ends in exactly one newline, the header block holds no
entry-start-shaped line, the section carries no unaccounted line and the index exists.

The two remaining pre/post divergence risks were checked against the artefact rather than argued.
Pre-change rotation emits `echo "$header"` after a `grep -vE` command substitution, which strips
trailing newlines; post-change emits the pass-A header array with `printf '%s\n'` per line. On this
fixture the header is one non-blank line, so the two agree. Pre-change appends the raw awk-filtered
bullet lines; post-change appends normalised lines, so any trailing whitespace would diverge —
`K-65`(5) excludes it and the fixture has none.

### The block as it stands: three legs, ten rows (round 3 added the third; round-4 capture)

Round 2's version of this section described **two** legs and transcribed three `PASS` lines. That
was the shape `QA-1` slipped through: both legs instantiated **one** member of `K-65`'s admissible
class, and every member they instantiated was single-section, so the floor was verified by its
fixture rather than by its class. Round 3 added a third leg that drives the **multi-section** fixture
— a second, structurally different member of the same class — through the same extracted script.

Captured, all three legs, round 4:

```
$ bash .harness/scripts/test-archive-task.sh
--- AC-4 (bash) — regression floor against the git-extracted PRE-CHANGE script
  PASS  AC-4 pre-change script extracted from git
  PASS  AC-4 append: post-change exit status matches pre-change
  PASS  AC-4 append: index byte-identical to pre-change output
  PASS  AC-4 append: neither run created a history file
  PASS  AC-4 rotation: post-change exit status matches pre-change
  PASS  AC-4 rotation: index byte-identical to pre-change output
  PASS  AC-4 rotation: history byte-identical to pre-change output
  PASS  AC-4 multi-section: post-change exit status matches pre-change
  PASS  AC-4 multi-section: index byte-identical to pre-change output (B-11)
  PASS  AC-4 multi-section: the pre-change reference really harvested BOTH entries
```

The tenth row exists so the ninth cannot degenerate. In the anti-revert run the driver copies the
script under test into **both** sandboxes, so a byte-identity comparison between "pre" and "post"
would be a comparison of a script with itself and could never fail; the tenth row asserts that the
pre-change reference **did** harvest both entries, which is what makes the ninth a floor rather than
a tautology. This is why all ten `AC-4` rows are green in the anti-revert column and are disclosed as
such rather than counted as coverage.

The pre-change script is extracted with `git show HEAD:.harness/scripts/archive-task.sh` into a
scratch path and driven through the driver's own sandbox, i.e. through the same fixtures in the same
order on the same day (the `## Rotated <date>` line is date-stamped, so the two runs must share a
day; they share a second). `HEAD` has not moved across rounds 3 and 4: sha256
`f43f549924cc0f0ae885868b5b1577774753d02eb83e0a2d840440897a74f281`, re-computed this round.

## Corpus census (`AC-15`) re-measured under the implemented rule

Walked read-only over `docs/features/_archived/*/07_DELIVERY.md`, each copied into a sandbox and
classified with `--dry-run`:

- 41 archived delivery documents, **34** carrying a bare `## Insight` / `## Insights` heading, none
  carrying two
- **34** classified with 0 unaccounted lines and exit 0; **0** dirty
- **3** whose terminal-footer figure is non-zero — `ai-native-init` (3), `i6-semantic-guard` (2),
  `supervisor-agent` (3)

These are the three sections gate `C-10` names, and the figures corroborate the gate's re-measurement
independently. The `D-1` heading predicate was chosen partly on this census: no archived section
carries a `##`-or-deeper heading after its first bullet, so the rule costs nothing on the real corpus
while pinning the hazard.

Re-measured again in round 4, read-only in a sandbox, with an independent walker:
`CENSUS: total=41 clean=34 dirty=0 footer_bearing=3 no_heading=7`. Unmoved, as it must be —
`archive-task.sh` is byte-unchanged this round and no archived document was touched.

## The 41-document **fence** census — the evidence behind a one-clause claim

`04_DEVELOPMENT.md` asserted, in a single clause and with no trace anywhere, that every fenced block
in the archived corpus is balanced and sits before its `## Insight` heading. That claim is what
licenses making the section *terminator* fence-aware without moving any archived document's
classification, so it is the `F-6`-equivalent evidence for `D-7` and it needed to be written down
(`CR-9`). Swept again this round, independently, over all 41
`docs/features/_archived/*/07_DELIVERY.md`: every line matching a `{3,}` run of backticks or tildes
at indentation ≤3, plus every `^## +Insights? *$`.

| document | fence lines | count even | `## Insight` at | any `##` inside a fence | open at EOF |
|---|---|---|---|---|---|
| `ai-native-init` | 28, 33, 54, 76, 79, 82 | yes (6) | 112 | none | no |
| `ambient-stream` | 34, 38, 42, 44 | yes (4) | 56 | none | no |
| `supervisor-agent` | 28, 33, 55, 80 | yes (4) | 115 | none | no |
| `guard-cmd-chain` | 72, 78 | yes (2) | 223 | none | no |
| `hook-truth-status` | 73, 77 | yes (2) | 150 | none | no |
| `i6-semantic-guard` | 60, 75 | yes (2) | 89 | none | no |
| `i6-test-hardening` | 56, 67 | yes (2) | 101 | none | no |
| the other 34 | none | — | 27 have a heading, 7 do not | — | — |

Aggregates from the same run: **7** documents carry fences, **22** fence lines in total, the set of
marker characters seen is exactly `` {`} `` (**no tilde anywhere in the corpus**), the set of marker
lengths seen is exactly `{3}`, and the set of info strings seen is exactly `{'', 'json'}`.

Four consequences, each following from a column above rather than from an argument. No opener is
disqualified (an info string of `''` or `json` holds no backtick, so `archive-task.sh:261` opens
every one) and every closer is a closer (same character, same length, blank info, so `:264-265`
closes each). **No fence is open at any `## Insight` heading** — every fence line precedes its
document's heading, the nearest approach being `ai-native-init` at `:82` against a heading at `:112`
— so no archived heading is reclassified as quoted and `h_quoted` is 0 on all 41. And **no fence is
open at EOF**, so the `D-7`(iii) refusal cannot fire on any archived document; no `##` line falls
inside any fence, so no section boundary moves.

That is why the `AC-15` census of `34 / 0 / 3` cannot have moved under the fence-aware walk, and the
re-measurement above confirms it did not. It is also the honest scope of the claim: this is evidence
about the archived corpus, i.e. about the document *class* `07_DELIVERY.md` belongs to. It is not
evidence about a document an author writes tomorrow — those shapes are enumerated in the bounds
table and, where they refuse, they refuse loudly.

## Why fence awareness is scoped to section discovery and not to pass B

Three options existed. The shipped one is (a), and the comparison is the reason, not a preference.

- **(a) shipped — pass B is unchanged and classifies fenced lines normally**: continuation when an
  entry is open, unaccounted otherwise. No line is ever silently dropped; the worst case is a loud
  refusal at exit 3 naming the line.
- **(b) fenced lines become `ignorable`** — they would be absorbed into the aggregate `ignorable
  lines` figure and dropped. That is precisely the terminal-footer channel (`BC-20` / `QA-5`), which
  QA reproduced as a live smuggling channel this round, and here it would be **worse than** that
  channel: a wrapped entry whose continuation lines straddle a fence would be written to the index
  with its middle removed — silent *corruption of a stored entry*, not merely loss of an unstored
  one. Rejected.
- **(c) fenced lines become forced continuations** — identical to (a) whenever an entry is open, and
  undefined when none is, which is the only case in which (a) and (c) differ at all. It buys nothing
  except converting (a)'s loud refusal into a silent absorption with no entry to hold the content.
  Rejected.

So (a) is the only option that cannot produce the exit-0-with-lost-content shape this task exists to
remove. The cost of (a) is a real one and is now stated rather than glossed: because discovery is
fence-aware and pass B is not, **whether a fence inside the section is absorbed or refused is decided
by its adjacency to the entry above it**, not by its fencedness — measured below.

## The published bounds, measured: the shapes that refuse

Round 3 published five bounds under the claim that all were measured that round. Three were stated
more favourably than the artifact supports (`CR-12` and the bound-4 `NIT`) and one was not measured
at all (`CR-13`). Every shape below was run in round 4 against the promoted script in a sandbox; the
tally and diagnostic lines are transcribed.

> The transcripts below are verbatim, which means they carry column-0 `#`-prefixed lines **inside**
> fenced blocks — bound 2b's own shape. That is safe here and only here: `archive-task` reads
> `07_DELIVERY.md` and nothing else, so no stage document but the delivery document is ever scanned.
> For **this task's** `07_DELIVERY.md` the live mitigation is one line: keep every fenced example
> **above** the `## Insight` heading. The `qa1b` fixture proves that shape works, the corpus census
> above shows all 41 archived documents already have it, and `K-53`'s mandated
> dry-run-then-compare backstops it either way.

**Bound 2a — a fence inside the section with a blank line before it refuses.** The pinned `qa1d`
fixture has the fence directly abutting the entry, which is why round 3's bound read as it did. Put
the conventional blank line in and pass B has already closed the entry
(`archive-task.sh:143-145` clears `in_entry` on a blank), so the fence opener has nothing to
continue, misses the preamble clause at `:150` and falls to `:167`:

```
### fence inside the section, BLANK LINE before it  -> exit 3
Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 3
archive-task: refusing to harvest — 3 unclassifiable line(s); nothing written.
  ...07_DELIVERY.md:7: unaccounted line: ```json
  ...07_DELIVERY.md:8: unaccounted line: {"a": 1}
  ...07_DELIVERY.md:9: unaccounted line: ```
```

**Bound 2b — a fence inside the section holding a column-0 `##` line refuses, and that is a change
against round 2.** Discovery keeps the quoted heading *inside* the section (it is inside a fence, so
it is neither opener nor terminator) and counts it in `h_quoted`; pass B then tests it at column 0
against `D-1`'s heading rule and makes it unaccounted:

```
### fence inside the section holding a column-0 ## line  -> exit 3
Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 2
Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested
archive-task: refusing to harvest — 2 unclassifiable line(s); nothing written.
  ...07_DELIVERY.md:7: unaccounted line: ## Insight
  ...07_DELIVERY.md:8: unaccounted line: ```
```

Round 2's discovery was fence-unaware, so that same line matched `RE_SECTION_END` and simply *ended*
the section there: the closing fence was never seen and the run exited 0 with the section silently
truncated. The new outcome is the better one, but it is a behaviour change on a plausible shape and
no round-3 bound declared it. **Provenance, stated precisely:** the exit-3 outcome above is captured;
the round-2 exit-0 outcome is a **hand trace** through the round-2 discovery loop and cannot be
re-run, because the round-2 script exists in no commit (`HEAD` is the pre-change script and the T-20
work is uncommitted). Indentation decides the whole case — `^#{2,6}[[:space:]]` is column-anchored,
so the same example indented by any amount is a continuation and the run exits 0.

**Bound 3a — the HTML-comment bound has the same phrasing defect.** `-->` is a continuation only
when it abuts the entry:

```
### ## Insight inside an HTML comment, --> directly under the entry  -> exit 0
Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0

### the same document with a BLANK LINE before the -->        -> exit 3
Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 1
archive-task: refusing to harvest — 1 unclassifiable line(s); nothing written.
  ...07_DELIVERY.md:8: unaccounted line: -->
```

**Bound 4 — "indented 4+ spaces" understated its own skip.** Any indentation ≥1 fails `^##`.
Measured at **one** space: `entries 0`, exit 0, no `Quoted headings:` line. The direction is
harmless, but the number implied that 1-3 spaces would be harvested, which is false in both twins and
in the pre-change awk.

**Bound 5 — the `Quoted headings: 2` figure is fixture-specific, not a property of the shape.** A
`~~~` run does not close a ` ``` ` fence, so the fence reaches EOF open and the run refuses, naming
the opener. The count on the report line is simply how many matching headings that fence happened to
hide — and the line is absent when it hid none:

```
ONE quoted heading inside the fence  -> exit 3
Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 1
Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested
  ...07_DELIVERY.md:3: unterminated code fence opened here: ```
```

The same document with **no** quoted heading inside the fence produces the identical tally and the
identical diagnostic with **no `Quoted headings:` line at all** (it is conditional on a non-zero
count), and `qa1c` reports `2` because `qa1c` quotes two headings. Round 3 published that `2` as if
the shape determined it.

## The tilde branch (`CR-13`) and why one fixture closes it

`RE_FENCE` accepts `` `{3,} `` **or** `~{3,}` and the branches differ: a backtick opener's info string
may hold no backtick (`archive-task.sh:261`, `.ps1:296`), a tilde opener's is unrestricted. Until
round 4 **no fixture in either driver contained a tilde at all**, so bound 5 was published as measured
while resting on no row, and the tilde half of the third new state machine this task has shipped was
pinned by nothing — the previous two each shipped a defect a later stage found (`G-1`, `G-17`).

One fixture closes it because the three tilde-only paths are observable through a single document,
each with a different failure mode:

| path exercised | how the fixture would fail if the path were wrong |
|---|---|
| tilde **opener** whose info string contains a backtick | the opener would not open, the quoted `## Insight` inside would become the section, and the tally would read `entries 2` with the documentation bullet in the index |
| **mismatched** closer — a ` ``` ` run inside a `~~~` fence | it would close the tilde fence, the following `## Insight` would open a second section, and the quoted bullet would reach the index |
| tilde **closer** | the fence would still be open at EOF and the run would refuse at exit 3 with nothing written |

The fixture is the `qa1b` shape rewritten with tildes, which is also the realistic shape: the reason
anyone reaches for a `~~~` fence is that the block they are quoting already contains a backtick
fence. Measured, round 4, five rows per twin:

```
--- QA-1 / CR-13 — the TILDE fence branch: opener with a backtick info string, mismatched ``` inside, tilde closer
  PASS  CR-13 tilde fence exit status (the ~~~ closer really closed it)
  PASS  CR-13 tilde fence tally is the REAL section's
  PASS  CR-13 the real section's entry reaches the index
  PASS  CR-13 the tilde-quoted documentation example does not reach the index
  PASS  CR-13 the heading quoted inside a TILDE fence is reported, not silent
```

Against the pre-change script those five split **2 green / 3 red** (captured, not predicted): rows 1
and 3 are green because that script exits 0 and harvests the real bullet regardless of fences, and
rows 2, 4 and 5 are red because it prints no tally line, writes the tilde-quoted documentation bullet
into the index, and prints no `Quoted headings:` line. So the case is non-vacuous in the only sense
that matters — it discriminates against the script it exists to detect. `L26` holds over it: no row
can only be green.

## Anti-revert evidence — current at 186 rows, 84 / 102

The **186**-row driver, driven against the committed pre-change script (round-4 capture):

```
$ bash .harness/scripts/test-archive-task.sh <scratch>/pre-archive-task.sh
  archive-task under test: <scratch>/pre-archive-task.sh
  PASS: 84
  FAIL: 102
```

102 red rows, captured, not derived, and reproduced with an **identical FAIL label set** on a second
run. Where they cluster, counted off that run's stderr rather than described:

| cluster | red rows | what it covers |
|---|---|---|
| `QA-1` (five round-3 fenced/multi-section cases) | 17 | multi-section harvest, the fenced heading, the unterminated-fence refusal, the residual and the bound |
| `X-8` | 8 | the `##`/`###` heading rule, both modes |
| `BC-14` | 6 | the rotation clamp |
| `AC-2` | 6 | refusal before any write, mtime unmoved |
| `AC-14` | 6 | break-then-entry in the **index** |
| `AC-1`, `AC-13`, `AC-16` | 5 each | wrapped harvest; break-then-entry in the delivery section; the shipped template header block |
| `X-10`, `K-16` | 4 each | the unterminated-comment refusal; the exit-3 refusal predicate |
| `CR-13` (round-4 tilde case) | 3 | the tally line, the tilde-quoted example reaching the index, the absent `Quoted headings:` line |
| `BC-6`, `AC-15` | 3 each | the terminal-footer figure; the three corpus rows |
| `X-9`, `B-7`, `AC-3`, `BC-7/8/9/10/13/19/22` (2 each) and `§G`, `B-10`, `BC-1/2/3/4/12` (1 each) | 27 | the no-final-newline read, history rotation, the one-file-one-count property, the boundary cases and the long tail |
| **total** | **102** | matches the `FAIL: 102` line and the 102 labels under the `Failures:` header |

The 84 green rows are dominated by `AC-4` (10, green **by construction** — the anti-revert run drives
the extracted script in both sandboxes, disclosed above) and by `QA-1` (9) plus `CR-13` (2), where the
pre-change awk is the **correct** reference: it re-armed its flag on every matching heading, so it
harvests both sections and it does exit 0. The remainder are the boundary rows whose behaviour the
change deliberately preserves (`B-12` 6, `BC-16`/`BC-23` 4 each, and so on).

### Round history — none of these is current except the last row

| round | driver rows | anti-revert split | delta |
|---|---|---|---|
| 1-2 | 152 | **70 / 82** | the original capture |
| 3 | 181 | **82 / 99** | +29 rows for `QA-1`, splitting 12 green / 17 red |
| **4** | **186** | **84 / 102** | +5 rows for `CR-13`, splitting **2 green / 3 red** |

Round 3's 29 rows split 12/17 because on the *multi-section* fixture the pre-change awk is the
correct reference, so those rows are byte-identity rows against it rather than new coverage. Round
4's 5 rows split 2/3 for the same kind of reason and it was measured, not predicted: the pre-change
script **exits 0** and **does** harvest the real insight even from the tilde document (a fence is not
a bullet, so it never mattered to it), which greens two rows; it prints no tally line, it writes the
tilde-quoted documentation bullet into the index, and it prints no `Quoted headings:` line, which
reds three.

### Why the split is corroborated at the label level and never by totals

Round 2's lesson, applied rather than restated: a total can stay put while coverage moves. On the
round-4 runs — 186 post-PASS labels, all unique; 84 pre-PASS + 102 pre-FAIL = 186, all unique;
`comm` between the post-PASS set and the pre union **empty in both directions**; pre-PASS ∩ pre-FAIL
**empty**; and the pre-change run's stderr `Failures:` header followed by exactly **102** label lines,
counted with `awk '/^Failures:/{f=1;next} f{n++}'` — which is `CR-8` applied, since counting the
header as a failure is exactly the error `CR-8` caught.

## Why the two anti-vacuity rows are load-bearing (measured, not argued)

Both were proven by mutation in a scratch root holding a copy of the repo's scripts and of the
archived corpus. Nothing under the real repository was written to.

**`X-9`'s fixture-integrity row.** The fixture's defining property is its *absent* final newline, so
the guard must be able to see that property come back. Giving the fixture a trailing `\n` and
re-running:

- with the row in its current form (`tail -c 1 … | wc -l`, expected `0`) → **FAIL**, and the other
  three `X-9` rows stay green — which is exactly the silent-coverage-loss the row exists to stop
- with the row in the `tr -d '\n' | tr -dc '\n'` form, same mutated fixture → **PASS**

Same fixture, same run, opposite verdicts: the first filter deletes the only byte the second could
keep, so that pipeline's range is the one-element set `{""}` and its expected value is `""`.

**`AC-15`'s relaxed corpus rows.** A `>=` row that cannot be false is the same defect wearing a
floor. Three mutations of the scratch corpus:

| mutation | `clean` / `dirty` / `footer` | rows |
|---|---|---|
| remove one clean section | 33 / 0 / 2 | `>= 34` **red**, `>= 3` **red** |
| make one section unaccounted (`###` after its first bullet) | 33 / 1 / 3 | `>= 34` **red**, `dirty == 0` **red** |
| add a 35th clean section (simulating this task's own `AC-8` archive) | 35 / 0 / 3 | all three **green** |

`corpus_clean` sits exactly on its floor, so the floor is one section away from red in the direction
that matters and unbounded in the direction that only grows.

That relaxation initially *did* cost anti-revert coverage, and the run caught it: against the
pre-change script the split moved 70/82 → 71/81, because that script prints no tally line at all,
`${line##*terminal footer }` on an empty string returns the empty string unchanged, and every
unmeasured section was therefore counted as footer-bearing — handing `>= 3` a spurious green against
the very script it exists to detect. Both twins now parse the tally strictly (bash: a guarded
expansion plus a `^[0-9]+$` test; PS: `-gt 0` against its `-1` sentinel). With that in place the
split went back to **70/82** — *a round-2 figure over the then-152-row set, superseded; the current
split is 84/102* — and the red-row *label set* against the pre-change script was identical to the
pre-relaxation one: no coverage lost, verified by diffing the two failure lists rather than by
comparing totals. All three `AC-15` rows are still red against the pre-change script on the round-4
run.

## What was deliberately not done

`F.1`, `sync-self`, `AI-GUIDE.md`'s driver list and `.harness/rules/40-locations.md` were left alone
per gate `Q-6`; `C-14`'s recount (eight `sync-self` pairs, `F.1` naming two drivers and omitting
five, 21 template scripts and none a `test-*`) was re-checked against the artefacts before deciding.
`skills/harness-init/templates/common/.harness/insight-index.md.tmpl` was read (for the `AC-16`
fixture) and **not edited** — out-of-scope 11(b). `docs/proposals/frontier-gaps-2026-07.md` was
neither opened nor cited. `CONTEXT.md` was read and needed no edit: ledger row 28's text is already
present, exactly as gate `C-12` records.
