# 03 — Rationale — T-20 `harvest-wrapped-insight`

Rationale portion for `03_GATE_REVIEW.md`. Every claim is backed by a path and a line opened during
this round; nothing is carried forward from round 1 without re-reading. This stage has no `Bash`
tool, so every figure below is a count over file reads or content searches, each re-derivable in one
command, and each is marked with the tool that evaluated it (insight L31).

## How `K-62` was verified rather than accepted (`A-1`)

`K-62` is the load-bearing safety property of the whole round, so it was re-derived from pass B's
rules rather than read as a claim.

Let `e` be the offset of the last line of the last entry pass B produces. Consider line `e+1`. Pass B
rule 1 cannot apply: `seen_entry` is true. Rule 3 cannot apply: an entry-start line there would open
a later entry and contradict "last". Rule 4 cannot apply: it would classify `e+1` as a continuation
and contradict "`e` is the entry's last line". So line `e+1` is blank (rule 2) or does not exist —
and rule 2 sets `in_entry := false`. For every offset beyond that, rule 3 is unavailable for the same
reason, so no entry-start line ever re-opens an entry and `in_entry` can never become true again.
Therefore every line at an offset greater than `e` is blank (rule 2, already ignorable) or falls to
rule 5 (unaccounted). Pass C selects `f > e` and rewrites offsets `f..n`, all of which are in that
set. The demotion is **unaccounted → ignorable** and nothing else.

Two corollaries worth recording. The worst available implementation error in pass C is computing `f`
too late, which refuses a footer that should have been ignored — loud, not silent. And the property
is a property of *pass C only*: pass A makes header-block lines ignorable regardless of their shape,
which is what `G-14` is about.

## The census, re-measured under the new rule (`A-1`, `C-10`)

Round 1 established 41 archived `07_DELIVERY.md`, 34 with a bare `## Insight` heading, 3 carrying 5
unaccounted lines under the no-widening Definitions. That census was performed under a *different*
rule, so it was not reused as a verdict.

The terminal-footer rule is strictly narrower than the declined closer-block rule, so it can only
turn previously-ignorable lines back into unaccounted ones. The single input class that could do so
is a thematic break lying **before** the last entry's last line. Under the original no-widening
Definitions such a break would itself have counted as unaccounted and would have appeared in the
round-1 census. It did not, which bounds the search — and the bound was then checked directly rather
than argued.

A content search (ripgrep, so `\t` is a tab and `[ ]` is a space — the pattern is registered with its
evaluating tool per L31) for `^[ ]{0,3}(-{3,}|\*{3,}|_{3,})[ \t]*$` over all 41 files returns **10**
hits in **4** files:

- `i6-semantic-guard/07_DELIVERY.md:96` — section `:89`, preamble `:91`, entries `:93-94`, blank
  `:95`, break `:96`, terminated by `## Delivery-stage addendum` at `:98`. `e = 94`, `f = 96`.
- `supervisor-agent/07_DELIVERY.md:123` — section `:115`, preamble `:117`, entries `:119-121`, blank
  `:122`, break `:123`, blank `:124`, `**Verdict**:` `:125`, EOF `:126`. `e = 121`, `f = 123`.
- `ai-native-init/07_DELIVERY.md:120` — section `:112`, preamble `:114`, entries `:116-118`, blank
  `:119`, break `:120`, blank `:121`, `**Verdict**:` `:122`, EOF `:123`. `e = 118`, `f = 120`.
- `guard-cmd-chain/07_DELIVERY.md:9,39,68,105,170,198,221` — **all seven precede** the `## Insight`
  heading at `:223`, so none is inside a section.

All three in-section breaks satisfy `f > e`, so each yields a terminal footer covering the remainder
of its section and each section reports 0 unaccounted lines. The floor is 0 of 34 under the new rule.
All three sections were re-read in full this round; the entries are single physical lines, so `e` is
unambiguous in each.

One record-only bound surfaced by the re-measurement: the contract's `Thematic break` is a purely
lexical predicate, so a setext-style heading underline (`---` directly under a text line) would also
match. In all three corpus files a blank line precedes the break, so all three are genuine thematic
breaks; and under `BC-22` an abutting `---` is a continuation, which is the safe direction.

## The `K-7` walk, traced (`A-3`, `C-13`)

`skills/harness-init/templates/common/.harness/insight-index.md.tmpl` was read in full: 9 lines,
`:7` = `<!-- Append new insights below, one per line. Format:`, `:8` =
`- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>`, `:9` = `-->`.

Trace: `:1-6` — state false, no entry-start match, no token. `:7` — state false, not an entry-start
line, scan finds `<!--` → state true. `:8` — state true, so the entry-start test is skipped; the line
carries neither token (`<one-sentence fact>` is `<o…`, not `<!--`; nothing in it forms `-->`) → state
stays true. `:9` — state true, entry-start test skipped, scan finds `-->` → state false. EOF with no
line having stopped the walk → header block is `:1-9`. Entries 0, unaccounted 0, `-->` unrotatable.
`K-64` is exact.

The dogfood file was traced too: `.harness/insight-index.md:7` opens the comment, `:8` is `-->` and
closes it with no example line between, `:9` is the first entry-start line with state false → header
block `:1-8`, entries `:9-38` = **30**, no continuation, no unaccounted line. So `F-3` holds, `K-16`
cannot fire on T-20's own archive, and `I.4` under `K-26` returns the same verdict it returns today.

Adversarial cases run against the walk:

- **Marker inside an entry.** Never reached — the walk stops at the first entry-start line outside a
  comment, before that line's own tokens are scanned. An entry containing `<!--` or `-->` is inert.
- **Both tokens on one line.** `<!-- x --> <!--` ends open, `--> <!--` ends open, under the
  token-type reading. The contract wording ("the first setting it true and the second false") also
  admits an occurrence-order reading under which `--> <!--` would end *closed*; that reading is
  unsound and is `Q-2`.
- **Nested opens.** A second `<!--` inside an open comment is idempotent under the token-type
  reading, so `<!-- a <!-- b -->` ends closed. No nesting depth is needed.
- **Unbalanced open.** This is the case `R12` gets wrong; see below.
- **Three on-disk index states in a generated project.** Never rotated: header `:1-9`, safe.
  Already rotated pre-change: `grep -vE` emitted `:1-7` and `:9` together and rotated `:8` away as a
  garbage entry, so the surviving header is comment-closed with no entry-shaped line and the walk
  stops at the first real entry. Appended but not rotated: header `:1-9`, entries after. All safe.

## Why `R12`'s stated outcome is false (`G-17`)

`R12` says an unclosed comment yields "0 entries and 0 unaccounted — refusing to harvest rather than
corrupting". The first clause is right; the second does not follow from any rule in the design.

`K-15` and `K-16` are the only refusals and both are conditioned on `unaccounted > 0`. With the whole
file classified as header block there are no unaccounted lines, so neither fires. `K-12`'s
`total_after = stored + harvested` is then `0 + harvested`, which cannot exceed 30 for any realistic
delivery, so the rotation branch is never taken and the append path at the flow's `≤ 30` arm writes
the harvested entries to the end of the file — inside the still-open comment. `K-26`'s `I.4` derives
its cap figure from the same scan, so it reports 0 entries and PASSes. Every subsequent run repeats
this.

Pre-change the same input is harmless: `archive-task.sh:69` and `verify_all.sh:463` are comment-blind
`grep`s and count the bullets regardless. So this is a failure mode the change **introduces**, and it
is introduced by the state machine added to close `G-3` — which is exactly the scrutiny the closer
block received in round 1 and the reason this stage looked for it.

Reachability is modest: it needs an unbalanced `<!--` in the header region of an index. The header is
hand-authored prose and both shipped headers contain a balanced `<!--`, so dropping a `-->` during an
edit is the realistic path. The gate does not propose the resolution; `X-10` requires the behaviour to
be measured and either fixed or dispositioned, because a stated outcome that is false against the
artifact is worse than a stated known bound.

## The Definitions totality audit (`G-14`, `G-16`)

T-14's lesson says that when one non-total rule is found, every other rule in the same document is
audited. Each Definitions term was checked against the design's passes:

- **Section** ↔ `K-6`: the contract says "the next `##` heading", the design pins
  `^##[[:space:]]` — the current, unchanged matcher (`archive-task.sh:51`, out-of-scope 10). A
  `### Sub` line therefore does not terminate and reaches pass B. Loose wording; the design is right.
- **Entry-start line** ↔ `K-3`: identical text at both spellings. ✔
- **Continuation line** ↔ pass B rule 4: the contract excludes "a `##` heading"; pass B has **no**
  heading rule. In mode `index` there is no terminator at all, so a heading after an entry is a
  continuation to the design and unaccounted to the contract. In mode `section` the same divergence
  reaches `###`. This is `G-16` and it is the one genuine totality gap.
- **Insight entry** ↔ pass B's open-entry accumulation. ✔
- **Header block** ↔ `K-7`: they agree, including the undefined-looking case where no entry-start
  line exists outside a comment — the contract's "extended forward through the end of any HTML
  comment that is open" runs to EOF, which is `K-7`'s whole-file result. ✔
- **Thematic break** ↔ pass C and the §G register: the contract's form is correct ERE; §G's table
  cells carry `\|` pipe escapes (`G-21`). ✔ with a transcription hazard.
- **Terminal footer** ↔ pass C: identical, including "no entry ⇒ no footer" and the index exclusion. ✔
- **Ignorable / Unaccounted** ↔ pass B rules 1, 2, 5 and pass C. ✔

The classification-order clauses map one-to-one onto pass B rules 1-5 plus pass C, including the
design's added "and the line is not an entry-start line" on the section arm of rule 1, which is
equivalent to the contract's "precedes the section's first entry-start line". What does **not**
survive the audit is the consequence sentence appended to the order: it quantifies over "any position
in any file", while clause 1 precedes clause 3 and the same document's `Header block` definition
explicitly contemplates an entry-start line inside the header block. `K-67` records the derived form
of the same claim as false; the contract form was never corrected. That is `G-14`.

## Why `AC-3`'s third leg no longer describes the design (`G-15`)

Round 1's `G-2` was that `I.4` held two notions of "entry". `K-26` closes it by deriving both figures
from one scan. The side effect is arithmetic: over `AC-14`'s fixture (header, entry, blank, `---`,
blank, entry-start + continuation) the rejected post-break-ignorable rule moves `archive-task`'s
count **and** `I.4`'s count to 1 together. They agree, so `AC-3`'s literal demand — "a rule that made
post-break lines ignorable makes the two counts differ" — is falsified by the closure of `G-2`.

`K-61` is the sound substitute and it was checked, not accepted. The raw-marker count over that
fixture is 2 under every rule, because the continuation line does not match the entry-start predicate
and the `---` line does not either. The classified entry count is 2 under the adopted rule and 1
under the rejected one, so a driver-side equality assertion turns red exactly on the rejected rule.
The oracle's precondition ("no entry-start-shaped line in the header block") is exact: pass B rule 3
precedes rule 4 so a predicate-matching line is never a continuation, pass C does not run for `index`
so none is ever demoted, and a trailing `\r` does not change the match. The one designed inequality
is `AC-16`'s, raw = entries + 1, from the template's single example line — and asserting it *is* the
`G-3` regression test.

The refusal does not block the measurement: `K-18` prints the tally on every terminating path,
including the `K-16` refusal that `AC-14`'s fixture triggers.

So the mechanism is sound and only the criterion's text is stale. `X-7` is one clause.

## The `set -e` boundary between the two scripts (`G-24`)

`archive-task.sh:9` is `set -euo pipefail`. `verify_all.sh:3` is `set -uo pipefail` — **no `-e`**.
The same state machine goes into both, and the idiom that is safe in one is fatal in the other:
`verify_all.sh:21` uses `((warns++))` inside `step`, which is safe there and would exit
`archive-task.sh` the first time a counter increments from 0, because `(( n++ ))` evaluates to the
*old* value and returns status 1 on zero.

This is not hypothetical for this script. `E-9` found `archive-task.sh:77-79` aborting under `set -u`
on an unbound expansion; `F-11` found `:62` aborting under `set -e` because an AND-list is the last
command of a `then`-block — the same construct class, in a 131-line file, twice. The new code adds
counters, `[[ =~ ]]` sites and a function boundary, so the third instance is available. `X-12` makes
it checkable by reading the diff.

`K-63`'s fix was checked for the same interaction and is safe under both readings: with `touch` moved
to the write phase the `then`-block ends in an `echo`; and even if an inner
`if [[ "$DRY_RUN" == false ]]; then touch …; fi` is kept at `:62`, an `if` whose condition is false
and which has no `else` returns 0.

## `K-68`, measured against every consumer (`C-15`)

`I.4`'s label and message were traced to every reader:

- `verify_all.sh:461,465,467,470` and `verify_all.ps1:448,453` — the strings themselves.
- `G.4` at `verify_all.sh:752` derives `g4_count=$(( ${#report[@]} + 1 ))` from the record array, and
  the tripwire at `:846-850` compares the last record's **id**. Neither reads a label.
- `test-init.sh:699-701` matches `insight-index` only over `.harness/rules/05-insight-index.md`'s
  language; `test-init.ps1:801-803` is its twin; `test-real-project.{sh,ps1}` has no match at all.
- `I.6`'s banned list at `verify_all.sh:566-581` is fourteen CLAUDE.md-composition phrases; none
  contains "entries", "lines", "evidence" or "insight", so a re-wording trips nothing. (The archived
  `i4-cap-symmetry` gate made the same check for the previous rename.)
- A repo-wide search for `evidence lines` outside `docs/features/_archived/**` returns only
  `AI-GUIDE.md:37` (ledger 27), `.harness/rules/70-doc-size.md:28` (ledger 26),
  `AI-GUIDE.md.tmpl:35` (ledger 27), and the history-bearing `CHANGELOG.md:771` / `docs/tasks.md:45`
  that `K-47` correctly excludes.

So `K-68` moves no assertion tally and no check count, and `R9`'s "measured, not assumed" is honest.

## Ledger row 27, and why it is kept (`A-6`)

Every cited line was opened: `AI-GUIDE.md:37` ("≤30 evidence-backed lines"), `:79` ("rotate old
insights … if >30 lines"), `AI-GUIDE.md.tmpl:35` (the `:37` twin), `docs/concepts.md:168` ("capped at
30 lines"). All four state the quantity `B-6` changes. The twin pairing is also right rather than
incomplete: `AI-GUIDE.md.tmpl` carries **no** counterpart to `:79` — its harvest sentence at `:87`
states no quantity and is correctly in `K-47`'s unchanged class. Severability was checked and holds:
no other ledger row names those four files. Keeping the row costs four one-sentence edits; striking
it reopens `G-8` and leaves two false sentences in this repo's always-on entry document, which is
insight L34's exact failure.

The rest of the prose ledger was verified line by line: `agents/pm-orchestrator.md:61,219-221`,
`agents/developer.md:64`, `.harness/rules/05-insight-index.md:5,25`,
`05-insight-index.md.tmpl:5,29,48`, `.harness/rules/70-doc-size.md:28,152` and its `.tmpl:27,151`,
`.harness/insight-index.md:3`, `archive-task.sh:59`, `archive-task.ps1:12,61`. Every cited line
carries the cited text.

## Measurement narrative

This stage executed nothing; every figure is a count over file reads or content searches. The counts
made this round, each re-derivable in one command: 41 archived delivery documents (glob); 34 with a
matching heading (ripgrep, `^##[ \t]+Insights?[ \t]*$`); 10 thematic-break hits in 4 files (ripgrep,
pattern above), of which 3 lie inside a section; 8 `sync-self` mappings, read as mappings 2-9 at
`sync-self.sh:62-93`; 5 drivers omitted from `F.1`, obtained by differencing `verify_all.sh:284`
against a glob of `.harness/scripts/test-*`; 21 files in
`templates/common/.harness/scripts/` (glob); 9 lines in `insight-index.md.tmpl` and 38 in
`.harness/insight-index.md` (full reads); 30 entries at `.harness/insight-index.md:9-38` (full read,
not a `grep -c`, per L26 — the file documents its own format at `:7`).

Every matcher used above was registered with its evaluating tool: the corpus searches were evaluated
by ripgrep, not by this host's interactive ugrep and not by the GNU grep the scripts receive, so no
conclusion here depends on a `[ \t]` bracket expression's meaning (L31). No figure was obtained by
arithmetic over another figure (L12), and every tally was cross-checked against a second artifact
where one exists — the 8-pair count against `AI-GUIDE.md:76` and `docs/dev-map.md:183`, the 32-check
count against `baseline.json:10` and `AI-GUIDE.md:74`, the operator list's endpoint against
`baseline.json` `_qa_note_t16`.

`docs/proposals/frontier-gaps-2026-07.md` was not opened in either round.
