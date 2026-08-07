# 03 — Gate Review — T-20 `harvest-wrapped-insight`

> Contract portion. The re-derivations (the `K-62` proof, the `K-7` walk trace, the corpus census
> under the new rule, the `K-61` arithmetic, the `set -e` analysis and the Definitions totality
> audit) are in `03_RATIONALE.md`.

Mode: `full`. Human channel: deferred — this stage defers, does not ask.

Identifiers (`R-n`, `G-n`, `C-n`, `X-n`) are stable labels and continue across rounds: a finding id
is never reused for a different finding. Ids not listed below are discharged and are not restated
(`.harness/rules/70-doc-size.md`).

## A. Rulings the PM requested by name

**A-1 — the terminal-footer rule is sound and minimal. RATIFIED.** `K-62`'s safety property was
re-derived from pass B rather than accepted: because pass B ends the last entry at `e` only when the
line after `e` is blank or absent, and because no entry-start line can exist after `e` without
contradicting "last entry", `in_entry` is false for every offset `> e` and every such line is blank
or falls to rule 5. Pass C touches only offsets `≥ f > e`. So pass C demotes **unaccounted →
ignorable** and nothing else. The property is structural, not a convention an implementer honours.
The 0-of-34 floor was re-measured under the **new** rule, not carried forward: the three corpus
sections were re-read line by line, and each footer break falls after the last entry's last line
(`supervisor-agent:121 → 123`, `ai-native-init:118 → 120`, `i6-semantic-guard:94 → 96`). The other
31 are unaffected because the terminal-footer clause is strictly narrower than the declined one and
the original no-widening census — which would have surfaced any earlier break as unaccounted —
found none. `C-10`.

**A-2 — `G-2` is closed by design, and the closure creates no new *behavioural* divergence.
RATIFIED with one text finding.** Removing the `grep -c` arm moves no `step` call
(`verify_all.sh:461-471` holds three textual `step "I.4"` calls and executes exactly one; that is
unchanged), and `G.4` derives its count as `${#report[@]} + 1` from the live record array
(`verify_all.sh:752`, tripwire `:846-850`) — a label, message or body edit cannot move it. `K-61`'s
oracle is sound: the raw-marker count and the classified entry count can differ only where the
header block holds an entry-start-shaped line, so the equality holds on `AC-14`'s fixture (raw 2 =
entries 2) and fails under the rejected rule (raw 2, entries 1). What the closure **does** leave
behind is a text divergence upstream: `AC-3`'s third leg, unamended, states a comparison `K-26` has
made non-discriminating. See `G-15`.

**A-3 — the template regression is closed. RATIFIED.** `K-7`'s walk was traced against
`skills/harness-init/templates/common/.harness/insight-index.md.tmpl` (9 lines, read this round):
`:7` sets `comment_state` true, `:8` is skipped by the entry-start test *because* the state is true
and carries neither token, `:9` closes, the walk reaches EOF and the header block is `:1-9`. 0
entries, 0 unaccounted, `-->` unrotatable. Adversarially: a marker inside an entry is never scanned
(the walk stops at the first entry-start line outside a comment); `<!-- x --> <!--` and `--> <!--`
both end open under the token-type reading; a second `<!--` inside an open comment is idempotent.
All three on-disk states of a generated project's index were checked and all are safe (`C-13`).
Two residues: the unclosed-comment case is mis-stated (`G-17`) and `K-7`'s token wording is
ambiguous enough to admit an unsound reading (`Q-2`).

**A-4 — `K-67`'s partition is complete in its three legs; its first leg is over-strong, and its
PowerShell leg is stated at the right strength but scoped too narrowly.** The "one figure per scan
per check" half is genuinely constructional and was verified. The "frozen predicate" half is
**maintained, not constructional**: `K-3` is a prohibition, the predicate's textual occurrences grow
from four to about seven post-change, and no `verify_all` check compares them — see `G-20`. The
PowerShell leg is correctly stated as operator-run-only (`N-3` holds; `_qa_note_t16` confirms the
list ends at item 16), but item 17 omits `AC-14` and `AC-16` — the two fixtures that prove this
round's closed FAILs, in the shell where `G-3`'s damage lands. See `G-19`.

**A-5 — `X-3`, `X-4`, `X-5` and `G-5`…`G-13`: all discharged**, each verified against the artifact
rather than the round record. `B-16` / `AC-10` appear in both documents only as explicit withdrawals
— no orphaned *use* anywhere (`C-11`). Out-of-scope 11(a)/(b) names the six `F.4` blocks and
`insight-index.md.tmpl:3,8` by path and line, precise enough to act on (`G-23` records one nit).
`CONTEXT.md:95-111` was re-read: it now carries `Terminal footer`, names four consumers, and every
sentence in the ledgered region is present-true today (`C-12`). `AC-13` / `AC-14` are in `K-34` with
the rejected reading's effect stated per row. `G-12` was recounted **from the artifacts, not from the
new count**: `sync-self.sh:62-93` carries mappings 2-9 = **eight** pairs, corroborated by
`AI-GUIDE.md:76` and `docs/dev-map.md:183`; `verify_all.sh:284` names `test-init` and
`test-real-project` and omits `test-supervisor`, `test-verify-i6`, `test-language`,
`test-harness-upgrade`, `test-guard-rm` = **five**, corroborated by the driver glob (`C-14`).

**A-6 — ledger row 27 (`K-69`): KEEP, do not sever.** `G-8` named `AI-GUIDE.md:79` by id, so
striking the row reopens the finding it was created to close. `AI-GUIDE.md:37` and
`docs/concepts.md:168` state the counted quantity in the same way the enumerated surfaces do, and
`AI-GUIDE.md` is this repo's always-on entry document — leaving two false sentences there is insight
L34's exact failure. All four sites were opened and carry the cited text. The twin pairing is also
correct rather than incomplete: `AI-GUIDE.md.tmpl` has **no** counterpart to `:79` (its harvest
sentence at `:87` carries no quantity), which is why row 27 names `tmpl:35` alone. Severability was
re-checked: no other row names those four files.

**A-7 — the new round-2 surface.** `K-68` is free: no driver asserts on `I.4`'s label or message
(`test-init.sh:699-701` matches the rule fragment, not the check; `test-real-project` has no match),
`G.4` counts records not strings, and the `I.6` banned list (`verify_all.sh:566-581`) contains no
phrase touched by "entries" (`C-15`). `K-63` is sound in both readings: moving `touch` out of the
`then`-block removes the `set -e` interaction, and even a literal inner `if`/`fi` returns 0 when its
condition is false, so `--dry-run` against a missing index exits 0 either way (`C-16`). But
`archive-task.sh` runs under `set -euo pipefail` while `verify_all.sh` runs under `set -uo pipefail`
only, and the new state machine lands in the `-e` script — see `G-24` and `Q-3`.

## B. Audit — eight dimensions

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | WARN | Every in-scope behavior is testable, every `BC-1`…`BC-24` carries a required behavior, and `BC-20`…`BC-24` close round 1's gaps; but the "Classification order" consequence asserts a universal the contract's own `Header block` definition falsifies (`G-14`), and `AC-3`'s third leg states a comparison the design has made non-discriminating (`G-15`). |
| 2 | Design completeness | WARN | `INSIGHT-SCAN` covers every in-scope behavior; the three-pass split makes `B-3`'s ordering structural (`K-62` re-derived), `K-7` closes `G-3` inside the algorithm on the only route that reaches a generated project's on-disk index, and `K-26` leaves one notion of "entry" per check. Two gaps: pass B implements no `##`-heading rule (`G-16`) and the unclosed-comment outcome is mis-stated (`G-17`). |
| 3 | Reuse correctness | PASS | Every cited symbol was re-opened this round and found at the cited line: `verify_all.sh:284,461-471,566-581,752,846-850`; `verify_all.ps1:448-456`; `archive-task.sh:27,46,51,59,62,65-70,77-79,85-91,94,102-106`; `archive-task.ps1:10,12,52,61,62-67,71,87,89,90,93,94,95,99`; `sync-self.sh:58-93`; `upgrade-project.sh:184,188-196,230,234-242`; `baseline.json:10,23-24,26`; `test-init.sh:699-701`; `test-guard-rm.sh:4-8,15,262-272`; `AI-GUIDE.md:37,74,76,79`; `docs/dev-map.md:101,183`; 21 files in `templates/common/.harness/scripts/`, none a `test-*` driver. No claimed symbol is absent; two citation slips move no conclusion (`G-22`). |
| 4 | Risk coverage | WARN | `R1`…`R13` name the real families, `R6` is now aimed at the correct absorption direction and `R12`/`R13` are new and well-placed; but `R12`'s stated outcome is false against the algorithm (`G-17`), and no row covers `set -euo pipefail` interaction with the new counters and regex sites in a script that already carries two such aborts (`E-9`, `F-11`) — `G-24`. |
| 5 | Migration safety | PASS | No data migration, no feature flag, no state; `K-54`'s rollback is `git checkout` of ledger files. Both distribution paths re-verified: `refresh_set` at `upgrade-project.sh:234-242` carries both `archive-task` copies and `verify_all.{ps1,sh}` is excluded per the `:184`/`:230` invariant. `B-19` was checked against all three states a generated project's on-disk index can be in — never rotated, already rotated by the pre-change script, appended-but-not-rotated — and `K-7` is safe in each (`C-13`). |
| 6 | Boundary handling | WARN | `BC-1`…`BC-24` each have a stated behavior and a `K-34` row; `BC-14`'s clamp closes `archive-task.sh:77-79`, `BC-23` closes `:62`, and `BC-20`…`BC-22` pin the footer edges including the safe direction for an abutting break. Two unenumerated boundaries: a delivery document with no final newline (`G-18`) and a heading line inside a section or index (`G-16`). |
| 7 | Test feasibility | WARN | Every acceptance criterion has a mechanism; `AC-13`, `AC-14` and `AC-16` genuinely discriminate (the `K-61` arithmetic was re-derived, not accepted); `AC-15`'s 0-of-34 was re-measured under the new rule; `AC-7`'s insertion-mutation still avoids the L28 container trap; `K-65`'s admissible class was checked against the live index and holds there, so `AC-4`'s floor is exercisable on a realistic shape (`C-17`). But `AC-3`'s third leg as written is not the comparison the design performs (`G-15`) and `AC-9`'s item 17 omits two fixtures (`G-19`). |
| 8 | Out-of-scope clarity | PASS | The eleven contract exclusions and §M's seven are explicit and mutually consistent; `B-16` / `AC-10` are withdrawn with zero orphaned use in either document; out-of-scope 11(a)/(b) carries file-and-line precision for the follow-up and states its one accepted asymmetry; `docs/proposals/frontier-gaps-2026-07.md` appears only as an exclusion, in no ledger row, and was not opened by this stage; the check count stays 32, verified three ways (`C-18`). |

## C. Findings

Severity: **FAIL** blocks; **WARN** must be dispositioned; **MINOR** is recorded.

**G-14 — WARN — a binding property in the requirement contract is false, and is asserted twice.**
Owner: `01_REQUIREMENT_ANALYSIS.md` "Classification order" (the consequence sentence) and
`01_RATIONALE.md:190-192`. The contract defines **Entry-start line** as a *predicate match*, then
states as "a binding property in its own right" that "no entry-start line and no continuation line is
ever ignorable, at any position in any file". Clause 1 precedes clause 3, so a predicate-matching
line inside the index header block **is** ignorable — which is exactly what the same document's
`Header block` definition, `BC-24` and `B-19` require, and exactly what `K-64` implements on
`insight-index.md.tmpl:8`. `01_RATIONALE.md:190-192` restates the same claim in its derived form
("…agree on every file that classifies clean, and disagree only on a file that refuses"), which
`K-67` explicitly records as **false**. The design is right and the contract was not corrected to
match. Concrete harm: a developer who encodes the universal as a driver assertion turns `AC-16` —
the fixture that closes `G-3` — red. `K-62`'s own restatement of the universal inherits the same
over-reach; its proof supports only the pass-C-scoped form.

**G-15 — WARN — `AC-3`'s third leg states a comparison `K-26` has made non-discriminating.** Owner:
`01_REQUIREMENT_ANALYSIS.md` `AC-3`. It requires that on `AC-14`'s fixture "a rule that made
post-break lines ignorable makes the two counts differ". Under `K-26` both `archive-task`'s count and
`I.4`'s count derive from one `INSIGHT-SCAN` over one file, so the rejected rule moves **both** to 1
and they agree — the criterion as written is falsified by the closure of `G-2`. `02_RATIONALE.md`
"Why the `AC-3` count comparison still discriminates" names this collision and resolves it with
`K-61`'s driver-side oracle, and `K-34`'s `AC-14` row implements the sound version. The sound
version exists only downstream; the criterion the developer and QA are handed still names the
unsound one, and §A of the design records no disposition against `AC-3`.

**G-16 — WARN — the contract's `##`-heading exclusion has no counterpart in pass B.** Owner:
`02_SOLUTION_DESIGN.md` §C pass B, against `01_REQUIREMENT_ANALYSIS.md` "Continuation line". The
definition excludes "a `##` heading" from being a continuation; pass B has rules for header block,
blank, entry-start, `in_entry` and otherwise, and no rule for a heading. In **mode `index`** there is
no terminator at all (`K-6`), so a `##` line following an entry is classified **continuation** by the
design and **unaccounted** by the contract — the design silently absorbs it into an entry and
rotation would carry it into the history file, where the contract would refuse. In **mode `section`**
the terminator is `^##[[:space:]]` (unchanged, out-of-scope 10), so a `### Subheading` line does not
terminate the section and reaches pass B, where the same divergence applies. Neither container is
enumerated in `BC-1`…`BC-24` and neither has a `K-34` row.

**G-17 — WARN — `R12`'s stated outcome for an unclosed HTML comment is false against the
algorithm.** Owner: `02_RATIONALE.md` `R12`, and `02_SOLUTION_DESIGN.md` `K-7` / `K-26` for the
missing disposition. `R12` says an unclosed comment "makes the whole file header block, which yields
0 entries and 0 unaccounted — refusing to harvest rather than corrupting". It does not refuse:
`K-15` and `K-16` fire on `unaccounted > 0`, and there are none. What actually happens to an index
carrying one unbalanced `<!--` before its first entry: `K-7`'s walk never stops, the header block is
the whole file, `INSIGHT-SCAN` reports 0 stored entries, `total_after` cannot exceed 30 so rotation
never fires, the append path writes the harvested lines *after* the unterminated marker, and `I.4`
reports 0 entries and PASSes. The index then grows without bound with every line commented out and
both gates green. Pre-change this is impossible — `grep -E` is comment-blind. This is a
silent-failure mode the change **introduces**, in the file the task exists to protect, reached by a
different input than `G-3`, and no `B-*`, `BC-*` or `K-*` disposes of it.

**G-18 — WARN — no boundary condition covers a delivery document with no final newline, and the
read mechanism is unstated.** Owner: `01_REQUIREMENT_ANALYSIS.md` boundary conditions and
`02_SOLUTION_DESIGN.md` `K-9`. `K-9` says "read the delivery file into a line array preserving 1-based
file line numbers" without naming the mechanism. The idiom already in the script
(`while IFS= read -r line`, `archive-task.sh:49-51,67-70`) **drops an unterminated final line**. If a
`07_DELIVERY.md` ends without a trailing newline and its last line is a continuation line, the fix
silently discards it — the exact defect under repair, reintroduced by the read rather than by the
filter, at exit 0 and with a tally that reports it as absent rather than as unaccounted. `K-58`
records the analogous *index* hazard and `K-65`(3) excludes it from `AC-4`; the delivery side is
unstated in both documents and has no `K-34` row.

**G-19 — WARN — operator item 17 omits the two fixtures that prove this round's closed FAILs.**
Owner: `01_REQUIREMENT_ANALYSIS.md` `AC-9` and `02_SOLUTION_DESIGN.md` `K-56`. Both enumerate item
17's run as reproducing `AC-1`, `AC-2`, `AC-3` and `AC-13` plus `B-18`'s byte-identity comparison.
`AC-14` (the index discriminator, closing `G-1`) and `AC-16` (the shipped-template header, closing
`G-3`) are absent. `G-3`'s damage lands in **generated projects**, whose `verify_all` and
`archive-task` run under PowerShell on Windows more often than under bash; `K-67` concedes the
PowerShell state machines are proven by that run and nothing else. So the one shell where the
regression matters most is the one whose evidence set omits its regression test. The numbering is
otherwise correct: `_qa_note_t16` confirms the standing list ends at 16.

**G-20 — MINOR — `K-67`'s first leg still over-claims.** Owner: `02_SOLUTION_DESIGN.md` `K-67`. Its
"one figure per scan per check" half is constructional and was verified. Its "the predicate is
frozen" half is not: `K-3` is a **prohibition** ("no implementation may introduce a third
spelling"), the predicate's textual occurrences rise from four pre-change sites to roughly seven
post-change (both `archive-task` twins, both `verify_all` `I.4` arms, the `K-61` oracle in
`test-archive-task.sh`, its PowerShell twin), and no `verify_all` check compares them. This is the
same class as `R-5`, one level down: what is frozen is the *text*, by rule; what grows is the number
of places a typo can land, unread by any gate. The honest partition would place the predicate's
cross-site identity in the second leg, with the bash pair covered by `K-61` and the PowerShell pair
by item 17.

**G-21 — MINOR — §G's thematic-break pattern carries markdown escapes that break verbatim
transcription.** Owner: `02_SOLUTION_DESIGN.md` §G. The two footer rows read
`^[[:space:]]{0,3}(-{3,}\|\*{3,}\|_{3,})[[:space:]]*$` and its `\s` twin — the `\|` is the table
cell's pipe escape, not part of the pattern. Copied verbatim into bash `[[ =~ ]]` the alternation
becomes a literal `|` and no thematic break ever matches, so pass C never fires. The authoritative
form is `01_REQUIREMENT_ANALYSIS.md`'s `Thematic break` definition, which is outside a table and
correct. Self-detecting (`AC-15` turns red), but it is precisely the L31 register's purpose to
prevent this.

**G-22 — MINOR — two citation slips, no conclusion moved.** Owner: `02_SOLUTION_DESIGN.md` `K-51`
and `K-47`. `K-51` cites `upgrade-project.sh:193,237` as `refresh_set`; `:193` is the `known` array
and `refresh_set` is `:234-242` (the two are bound by the invariant at `:184`/`:230`, so the
conclusion holds). `K-47` cites `skills/harness/SKILL.md:33,40,42`; `:40` carries no hit for any
term in the stage's own sweep pattern, while `:33` and `:42` do and are correctly classified. L12's
class, in a task whose `AC-4` bans derived figures.

**G-23 — MINOR — two enumeration residues.** Owner: `02_RATIONALE.md` "Prose sweep". Out-of-scope
11(a)'s file list leaves two PowerShell ranges open as `backend/…:278-…` and `fullstack/…:258-…`,
which the follow-up task will have to re-derive. Separately, `CONTEXT.md:91` ("An evidence-backed,
hard-won project truth recorded as **one line** in the insight index") sits four lines above ledger
row 28's region, is outside the ledger, and matches none of the sweep's patterns — the sweep looks
for "one physical line", not "one line". It is defensible as the retained authoring preference
(out-of-scope 5) but it now reads against `CONTEXT.md:101-104`'s `Insight entry` in the same file.

**G-24 — MINOR — a `set -e` hazard the new code lands in.** Owner: none; recorded for the developer.
`archive-task.sh:9` is `set -euo pipefail`; `verify_all.sh:3` is `set -uo pipefail` with **no `-e`**.
The state machine, its counters and its `[[ =~ ]]` sites go into both. In the `-e` script,
`(( n++ ))` returns the *old* value and so exits the script when `n` is 0 — the idiom `verify_all.sh:21`
uses safely is fatal in `archive-task.sh`. The same applies to a bare `[[ =~ ]]` or an AND-list as
the last command of a function or branch. This script has already produced two aborts of this family
(`E-9` at `:77-79` under `set -u`, `F-11` at `:62` under `set -e`); the third is available.

## D. Confirmations — checks that passed, stated positively

**C-10** — The 0-of-34 floor holds under the **new** rule, re-measured rather than carried forward.
34 of 41 archived `07_DELIVERY.md` carry a bare `## Insight` heading; exactly three sections contain
a thematic break, all three after the last entry's last line, all three yielding a fully ignorable
footer. `guard-cmd-chain`'s seven breaks all sit before its `## Insight` heading at `:223`.

**C-11** — `B-16` and `AC-10` are withdrawn without residue. Every occurrence in
`01_REQUIREMENT_ANALYSIS.md` and `02_SOLUTION_DESIGN.md` is an explicit withdrawal statement; no
behavior, criterion, ledger row, §M item or `K-*` depends on either. The withdrawn-identifier
convention is stated in both documents and the gaps (`K-24`, `K-25`, `K-27`, `K-43`…`K-46`, rows
10-15) are declared.

**C-12** — `CONTEXT.md:95-111` is now correct and ledgered. `Entry-start line` names four consumers
and its claim is present-true today at `archive-task.sh:51,69,94` and `verify_all.sh:463`;
`Terminal footer` replaces `Closer block` with the declined term moved into `_Avoid_`, resolving the
name collision the analyst flagged; the round-1 present-tense behavioural claim is gone. Ledger row
28 covers the region.

**C-13** — `B-19` holds in all three states a generated project's on-disk index can be in. Never
rotated (template shape, header `:1-9`, comment closed); already rotated by the pre-change script
(the example line left as a garbage entry in history, header `:1-8`, comment closed, no
entry-shaped line remaining); appended but not rotated (header `:1-9`, entries after). `K-7`'s walk
stops correctly in each and no rotation can carry `-->` out.

**C-14** — `G-12`'s recount is correct, verified from the artifacts and not from the new figure.
Eight `sync-self` pairs (`sync-self.sh:62-93`, mappings 2-9), corroborated at `AI-GUIDE.md:76` and
`docs/dev-map.md:183`; `F.1` at `verify_all.sh:284` names two test drivers and omits five, the five
confirmed present by glob. `templates/common/.harness/scripts/` holds 21 files, none a `test-*`
driver, so a dogfood-only driver pair remains consistent with every peer.

**C-15** — `K-68` moves nothing. No driver asserts on `I.4`'s label or message; `G.4` derives its
count from `${#report[@]}` and not from any string; the `I.6` banned list at `verify_all.sh:566-581`
holds only CLAUDE.md-composition phrases, none containing "entries", "lines" or "insight"; and the
two twins already differ in the `≤` / `<=` character, which `K-68` preserves.

**C-16** — `K-63` is sound under both readings. Moving `touch` into the write phase leaves the
`then`-block ending in an `echo` (status 0); and even the literal reading that keeps an inner
`if [[ "$DRY_RUN" == false ]]; then touch; fi` at `:62` exits 0, because an `if` whose condition is
false and which has no `else` returns 0. The pre-change status is **captured**, not predicted.

**C-17** — `K-65`'s admissible class is not artificial. The live `.harness/insight-index.md`
satisfies conditions (1), (2), (4) and (7) as it stands — header `:1-8` with an interior blank at
`:6` that command substitution preserves, no blank between `:8` and `:9`, no non-entry line after
`:9`, no entry-shaped line in the header — so `AC-4`'s floor is exercisable on a realistic index
shape, not only on the pinned synthetic one.

**C-18** — No new `verify_all` check; the count stays 32. `K-26` adds no `step` / `Step` call, the
`G.4` tripwire at `verify_all.sh:846-850` is untouched, no ledger row touches a published `32`
literal, and `baseline.json:10` reads `"verify_all_checks": 32`. `AC-5` remains reachable on the
live artifact: under `K-26` the dogfood index yields entries 30, unaccounted 0 → PASS, the same
verdict `grep -c` gives today.

**C-19** — `docs/proposals/frontier-gaps-2026-07.md` stays out. It appears in `01`'s out-of-scope 2
and `02`'s §M.7 only, in no ledger row, and this stage did not open it in either round.

**C-20** — The `K-61` oracle's precondition is exact. The raw-marker count can exceed the classified
entry count only through a header-block entry-shaped line: pass B rule 3 precedes rule 4 so no
predicate-matching line is ever a continuation (`BC-7`), pass C does not run for `index` so none is
ever demoted, and a trailing `\r` does not affect the match. `AC-16`'s designed inequality (raw =
entries + 1) follows from the template carrying exactly one such line.

## E. Predicted developer questions — pre-answered

**Q-1 — "The contract says no entry-start line is ever ignorable, but `K-64` makes
`insight-index.md.tmpl:8` ignorable. Which wins?"** `K-64` wins, and it is the intended behaviour —
`BC-24`, `B-19` and `AC-16` all require it. The contract's universal is over-reaching (`G-14`) and
`X-6` corrects it. Implement the header-block clause first, as pass A / pass B rule 1 specify. Do
**not** encode "no entry-start-shaped line is ever ignorable" as a driver assertion; encode
`K-61`'s precondition-scoped form instead.

**Q-2 — "`K-7` says the first token sets the state true and the second false. Does the second
occurrence of `<!--` set it false?"** No. The reading is by **token type**: every `<!--` sets true,
every `-->` sets false, applied in left-to-right occurrence order within the line. `02_RATIONALE.md`
`R12` disambiguates by example (`<!-- x --> <!--` ends open; `--> <!--` ends open). The other reading
is unsound and `K-7`'s contract wording admits it — state the token-type reading in `04` explicitly.

**Q-3 — "Can I use `((count++))` for the tally counters?"** Not in `archive-task.sh`. It runs under
`set -euo pipefail` (`:9`); `(( n++ ))` evaluates to the *old* value, so it returns status 1 at
`n == 0` and kills the run. Use `n=$((n+1))` or `(( ++n ))`. The same trap applies to a bare
`[[ =~ ]]` or an AND-list as the last command of a function or branch. `verify_all.sh` has no `-e`
(`:3`), which is why `((warns++))` at `:21` is safe there and would not be safe here.

**Q-4 — "How do I read the delivery file into the line array?"** Use `mapfile -t`, or a
`while IFS= read -r line || [[ -n "$line" ]]` loop. The bare `while read` idiom already in the script
drops a final line with no terminating newline, which for a wrapped entry is a silent continuation
loss — the defect under repair (`G-18`, `X-9`).

**Q-5 — "Which comparison does `AC-3` actually want?"** `K-61`'s: the driver-side raw-marker count
against `INSIGHT-SCAN`'s classified entry count, equality on every index whose header block holds no
entry-shaped line and the designed inequality on `AC-16`'s. The `archive-task`-versus-`I.4`
comparison is still worth running but it measures a different thing — agreement between the two bash
implementations of the state machine — and it cannot discriminate the rejected rule. Read `AC-3`
through `K-61` and `K-34`'s `AC-14` row, not literally (`G-15`, `X-7`).

**Q-6 — "Do I still add `test-archive-task` to `F.1`, `sync-self`, `AI-GUIDE.md` or
`40-locations.md`?"** No to all four; `C-14` re-verified the precedent this round, and `K-30`'s
recount is correct. `docs/dev-map.md` does carry a row for every driver, which is why ledger row 18
is correct and sufficient.

**Q-7 — "Does a `---` line immediately after the last bullet start the footer?"** No — with no blank
line between, it is a **continuation** (`BC-22`) and is harvested verbatim into the index. If a
`**Verdict**:` line then follows after a blank, there is no thematic break left after the last
entry's last line, so no terminal footer exists and the verdict line is unaccounted → refusal. Both
halves are intended and both are loud; do not "fix" the first by reordering pass C.

## F. Binding conditions

**X-6 (analyst-owned; before stage 4 is dispatched)** — the universal in
`01_REQUIREMENT_ANALYSIS.md` "Classification order" and its restatement at `01_RATIONALE.md:190-192`
are qualified to exclude the header block, or withdrawn. Checkable: no sentence in `01_*` asserts
that a predicate-matching line is never ignorable without a header-block qualifier, and `K-62`'s
restatement is scoped to pass C. Changes no behaviour; does not require re-gating.

**X-7 (analyst-owned; before stage 4 is dispatched)** — `AC-3`'s third leg names the comparison the
design actually performs (`K-61`'s raw-marker oracle against the classified entry count), not "the
two counts". Checkable: `AC-3` and `K-34`'s `AC-14` row describe the same comparison.

**X-8 (developer; verified by code review)** — the treatment of a `##` / `###` heading line inside a
section and inside the index is stated in `04_IMPLEMENTATION.md` and pinned by a `test-archive-task`
row in **both** modes. Checkable: the row exists, its expected value is explicit, and it matches
whichever of `01`'s `Continuation line` or `02`'s pass B the developer implements.

**X-9 (developer; verified by code review)** — the delivery-document read preserves an unterminated
final line, and a driver row asserts it with a fixture whose last line is a continuation line and
whose file has no trailing newline. Checkable: the read mechanism is `mapfile -t` or a
`|| [[ -n "$line" ]]` loop, and the row is present and green.

**X-10 (developer; verified by code review)** — the unclosed-comment case is measured, not argued.
Either `R12`'s stated outcome is made true against the artifact, or the case is dispositioned as a
stated known bound with a driver row recording the measured behaviour. Checkable: a
`test-archive-task` row drives an index carrying one unbalanced `<!--` and asserts `archive-task`'s
exit status, the tally, and `I.4`'s verdict over the result.

**X-11 (PM / QA-owned)** — operator item 17 in `_qa_note_t20` reproduces `AC-14` and `AC-16` in
addition to `AC-1`, `AC-2`, `AC-3` and `AC-13`. Checkable: the key's text names both. Items 1-16 stay
unrenumbered and unread.

**X-12 (developer; verified by code review)** — no `set -e`-fatal construct is introduced into
`archive-task.{sh}`: no `(( x++ ))` as a standalone statement, no bare `[[ =~ ]]` or `&&` AND-list as
the last command of a function body or of an `if` / `else` branch. Checkable by reading the diff;
the anti-regression evidence is that `--dry-run` against a missing index and a zero-count harvest
both reach step 4.

## G. Verdict

`APPROVED WITH CONDITIONS`

0 FAIL, 6 WARN, 5 MINOR, 11 positive confirmations, 7 binding conditions (`X-6`…`X-12`).

All three round-1 FAILs are closed against the artifact, not against the round record: `G-1` by a
pass split whose safety property was re-derived from pass B rather than accepted, with the 0-of-34
floor re-measured under the new rule; `G-2` by one scan per check, with `K-61`'s oracle verified to
discriminate and the check count verified unmoved; `G-3` by a comment-aware walk traced line by line
over the shipped template and stress-tested against unbalanced, nested and in-entry markers. Every
round-1 WARN and MINOR is discharged, including the two counts of `G-12`, which were re-counted from
`sync-self.sh` and `verify_all.sh` directly rather than from the design's new figure.

The six remaining WARNs share one property: none is a behavioural defect and none requires the
design to move. Four (`G-16`, `G-17`, `G-18`, and `G-24`'s hazard) are closed by measurement the
developer performs anyway; two (`G-14`, `G-15`) are one-clause text corrections to
`01_REQUIREMENT_ANALYSIS.md` that change no requirement and no design. That is why this is a
conditional approval rather than a block — but `X-6` and `X-7` are **analyst-owned** and a downstream
agent may not discharge them, so the PM must obtain those two corrections before dispatching stage 4.
They do not need to return through solution-architect and they do not need re-gating.

`AC-9` (items 1-16 unread and unmoved) and `AC-12` (this task's own insights unwrapped) are
gate-owned and both hold as of this round: the standing list ends at item 16 per `_qa_note_t16`, and
this task's stage documents carry no `## Insight` section yet.
