# 04 — Development Record — T-20 `harvest-wrapped-insight`

> Contract portion. Option comparisons, the measurement narrative, captured run excerpts and
> evidence citations are in `04_RATIONALE.md`.

Mode: `full`. Human channel: deferred — nothing was escalated; no `BLOCKED` condition arose.

Round 4 (this revision) is a **document-correction** round on code review's single MAJOR (`CR-9`),
carrying exactly one code change with it: the tilde fixture `CR-13` asked for, added to both drivers.
**No shipped script changed** — `archive-task.{sh,ps1}`, `verify_all.{sh,ps1}` and both template
mirrors are byte-unchanged from round 3, so every anchor cited in `05_CODE_REVIEW.md` is still live.
Round 3 was the fix round that closed QA's single MAJOR, `QA-1`.

**Every figure in this document is transcribed from a run executed in round 4**, and every superseded
figure carries its round marker: **152 / 70 / 82** are round 1-2, **181 / 82 / 99** are round 3,
**186 / 84 / 102** are current. `04_RATIONALE.md` carries the captured runs behind them and is
current at the same figures.

## Summary

`INSIGHT-SCAN` is implemented four times as the design requires — both `archive-task` twins and both
`verify_all` `I.4` arms — so harvest, rotation and the cap check now share one entry boundary in
which an entry is a bullet line plus every line wrapped under it.

A line the scan cannot classify is reported to stderr with its file, 1-based line number and text and
the run exits 3 before any create, write, append or move; `--dry-run` reproduces the same
classification, the same tally and the same status.

Round 3 closes `QA-1`: harvest scanned only the **first** `## Insight` heading and `break`ed, so every
later section was discarded at exit 0 with `unaccounted lines 0` — a *new* silent-content-loss path,
in both twins, inside `K-65`'s own admissible class, i.e. the exact defect class this task exists to
remove. Section discovery now walks the whole delivery document once, harvests **every** matching
heading, treats a heading inside a **fenced code block** as not a heading, **refuses** at exit 3 on a
fence left open at EOF, and **prints** a `Quoted headings: N …` line naming every matching heading it
skipped for being quoted.

Round 4 adds no behaviour. It pins the **tilde** half of the fence state machine, which round 3 left
code-correct and instantiated by no fixture (`CR-13`): every fixture in both drivers used backticks,
although `RE_FENCE` accepts `~{3,}` and the tilde branch is not a copy of the backtick branch — a
tilde opener's info string is unrestricted, where a backtick opener's may hold no backtick.

A new dogfood-only driver pair `test-archive-task.{sh,ps1}` pins the behaviour: the bash half runs
**PASS 186 / FAIL 0** against the promoted script and **PASS 84 / FAIL 102** against the committed
pre-change script.

The `AC-15` corpus rows are a **floor**, not an equality (`corpus_dirty == 0` is the hard row;
`>= 34` clean and `>= 3` terminal-footer are the measured floors), because the corpus they walk is
the live `docs/features/_archived/` tree and this task's own stage-7 archive grows it.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `.harness/scripts/archive-task.sh` | rewritten around `INSIGHT-SCAN` (three passes, mode `section` / `index`), `mapfile -t` reads, entry-based rotation with the `BC-14` clamp, header block emitted from pass A, exit-3 refusal, per-run tally, `K-63` write-phase `touch`. **Round 3 (`QA-1`)**: `RE_FENCE` added; the single-heading `break` replaced by a whole-document, fence-aware section walk building `SEC_LO[]`/`SEC_HI[]`; the section scan accumulates over every section; a fence open at EOF is reported and refuses; `h_quoted` + the `Quoted headings:` line | 1 |
| `.harness/scripts/archive-task.ps1` | structurally parallel twin: `Get-NormalisedLines` / `Invoke-InsightScan` / `Write-InsightFile`, `[System.IO.File]::WriteAllText` + `AppendAllText` with `UTF8Encoding($false)` over a fully parenthesised LF `-join` plus a trailing LF, `.TrimEnd()` only (never `.Trim()`), `at`-prefixed variables. **Round 3 (`QA-1`)**: the same walk, statement for statement — `$atReFence` (backticks literal because PS does not process a backtick inside a single-quoted string), `$atSecLo`/`$atSecHi` lists, accumulation loop, `$atHQuoted` | 2 |
| `skills/harness-init/templates/common/.harness/scripts/archive-task.sh` | byte-identical mirror of row 1 | 3 |
| `skills/harness-init/templates/common/.harness/scripts/archive-task.ps1` | byte-identical mirror of row 2 | 4 |
| `.harness/scripts/verify_all.sh` | `I.4` body replaced by one `INSIGHT-SCAN` mode `index`; `grep -c` cap arm removed; WARN on `entries > 30` **or** `unaccounted > 0`; label/message moved to entries; detail echoed (see `D-4`) | 5 |
| `.harness/scripts/verify_all.ps1` | same for the `I.4` `Step` block; `Where-Object … .Count` cap arm removed | 6 |
| `.harness/scripts/test-archive-task.sh` | **new** — 186 assertions (152 in round 2 + **29** in round 3 for `QA-1`: five case groups covering multi-section harvest, a fenced heading, an unterminated fence, the fence-inside-the-section residual and the wholly-fenced-section bound, plus a third `AC-4` pre/post leg driving the multi-section fixture through the git-extracted pre-change script; + **5** in round 4 for `CR-13`: one case, the `qa1f` fixture, exercising the tilde opener with a backtick in its info string, a backtick run inside a tilde fence that must **not** close it, and the tilde closer); optional `[archive-task-path]` argument. `AC-15`'s two corpus rows are floors over a growing corpus; the `X-9` fixture-integrity row is a byte test (`tail -c 1 \| wc -l`); `I.4` verdict rows anchor on the `[I.4]` line through `i4_head()`, never on `grep -A1`'s two-line window; the corpus tally line is parsed strictly, so an absent tally is not a measurement | 7 |
| `.harness/scripts/test-archive-task.ps1` | **new** — symmetric twin, case for case, green-by-symmetry (`N-3`); gained the same 26 `QA-1` rows in round 3 and the same 5 `CR-13` tilde rows in round 4, so its fenced-block row set is **31** (the `AC-4` leg is bash-only by design). Exactly two cases are bash-only and both by nature: `AC-4` (pre/post floor, `B-11`) and `BC-19` (`chmod 000`, unix-only). `AC-7` is present here too | 8 |
| `.harness/scripts/baseline.json` | `test_archive_task_bash_assertions: **186**` (152 → 181 → 186) + `_qa_note_t20` (operator item 17), which states the `AC-15` corpus floor and why it must not be re-baselined upward. Round 3 rewrote the anti-revert sentences to the then-captured 82/99, recorded the label-set corroboration and the pre-change sha256, and widened operator item 17(b) to require the `QA-1` cases under PowerShell. **Round 4** re-transcribed every figure from this round's runs (186, 84/102, 102 label lines), turned the anti-revert paragraph into a round-marked history so no superseded split reads as current (`CR-10`(c)), replaced item 17(b)'s "all four round-3 cases" with an enumerated **six**-case list whose count and list agree (`CR-10`(b)), and added the round-4 tilde case to it | 9 |
| `agents/pm-orchestrator.md` | `## Insight` section note: "silently dropped" clause replaced by the harvested-whole / refuse-at-exit-3 statement | 16 |
| `agents/developer.md` | `## Insight to surface` row: same correction | 17 |
| `docs/dev-map.md` | new `test-archive-task.{ps1,sh}` scripts-tree row; `archive-task` row annotated with the entry boundary. Both rows say **v0.46** — T-20 delivers into the existing unreleased `0.46.0` (`.claude-plugin/plugin.json:4`), the version T-16/T-17/T-18 also delivered into; no version is stamped by this task | 18 |
| `.harness/rejected-decisions.md` | three appended records: `insight-refusal-bypass-flag`, `insight-prose-i6-banned-phrase`, `shared-insight-parse-module` | 19 |
| `.harness/insight-index.md` | header block `:3` cap sentence stated in entries; **no entry line touched** (`AC-11`) | 23 |
| `agents/pm-orchestrator.md` | `:61` cap stated in entries | 24 |
| `.harness/rules/05-insight-index.md` + `…/templates/common/.harness/rules/05-insight-index.md.tmpl` | cap and rotation stated in entries | 25 |
| `.harness/rules/70-doc-size.md` + `…/templates/common/.harness/rules/70-doc-size.md.tmpl` | caps-table row and the "Harvests `## Insight` lines" bullet | 26 |
| `AI-GUIDE.md`, `…/templates/common/AI-GUIDE.md.tmpl`, `docs/concepts.md` | cap and ">30 lines" stated in entries | 27 |
| `CONTEXT.md` | **not touched** — ledger 28 (`K-66`) was already applied upstream and verified by gate `C-12`; the region reads as `K-66` specifies | 28 |

Ledger rows 20, 21 and 22 are PM-owned and are not this stage's work.

## verify_all result

- baseline (round 4, captured before the first round-4 edit): `verify_all` **32/0/0** exit 0; `test-archive-task.sh` **181/0** exit 0; pre-change split **82/99** exit 1 — i.e. round 3's reported figures reproduced exactly before anything was touched
- after all changes (`bash .harness/scripts/verify_all.sh`): PASS 32 / WARN 0 / FAIL 0, **exit 0**, 32 `[id]` lines counted in the run's own output
- delta: 0 new failures, 0 new warnings, check count unchanged at 32 — no `step` call was added or removed in any round, and round 4 touched no `verify_all` file at all
- `bash .harness/scripts/sync-self.sh --check`: `In sync.`, exit 0 (`AC-6`). `cmp` of both mirror pairs is byte-identical. Round 4 changed **no** mirrored file: `test-archive-task.*` is in neither mirror set nor `F.1` (`K-30`), so the mirror set is green because it did not move, not because it was re-synced
- `bash .harness/scripts/test-archive-task.sh`: **PASS 186 / FAIL 0**, exit 0 (3 identical runs; 152/0 in round 2, 181/0 in round 3)
- `bash .harness/scripts/test-archive-task.sh <git-extracted pre-change archive-task.sh>` (sha256 `f43f5499…74f281`, unchanged — `HEAD` did not move): **PASS 84 / FAIL 102**, exit 1 (2 identical runs, identical FAIL label sets). 102 of the 186 rows are load-bearing anti-revert coverage, captured from that run, never derived. Round history, each captured on its own run: round 1-2 **70/82** over 152 rows; round 3 **82/99** over 181 rows (its 29 rows split 12 green / 17 red); round 4 **84/102** over 186 rows — the 5 `CR-13` rows split **2 green / 3 red**. Green: the pre-change script exits 0 and does harvest the real entry. Red: it prints no tally line, it writes the tilde-quoted documentation bullet into the index, and it prints no `Quoted headings:` line
- **the split is corroborated at the label level, not by totals** (round 2's lesson: a total can stay put while coverage moves). 186 post-PASS labels, all unique; 84 pre-PASS + 102 pre-FAIL = 186, all unique; `comm` between the two sets **empty in both directions**; pre-PASS ∩ pre-FAIL **empty**. The pre-change stderr `Failures:` header is followed by exactly **102** label lines — counted with `awk '/^Failures:/{f=1;next} f{n++}'`, which is `CR-8`'s correction applied rather than restated. The two anti-revert runs produced **identical FAIL label sets**, diffed row by row, not compared as totals
- `AC-15` corpus census, **re-measured in round 4** read-only in a sandbox with an independent walker (the driver rows themselves state only floors): `CENSUS: total=41 clean=34 dirty=0 footer_bearing=3 no_heading=7` — unmoved from round 3, and both floors still sit **exactly** on the measurement. It cannot have moved: `archive-task.sh` is byte-unchanged this round and no archived document was touched
- the **41-document fence census** — which round 3 asserted in a single clause with no trace anywhere (`CR-9`) — was performed again this round, independently, and its per-document table is now in `04_RATIONALE.md`: all 41 `docs/features/_archived/*/07_DELIVERY.md` were swept for a `{3,}`-run of backticks or tildes at indentation ≤3. 7 documents carry fences, 22 fence lines in total, **every** marker a backtick run of **exactly 3**, every per-document count **even**, every info string `''` or `json` (so no opener is disqualified by the no-backtick-in-info rule and every closer's info is blank), **no** `##` line inside any fence, **no** fence open at EOF, and **every** fence line before its document's `## Insight` heading. So no archived document changes classification under the fence-aware walk
- the two anti-vacuity rows are proven load-bearing **by mutation**, in a scratch root, never by argument: flipping the `X-9` fixture to end with a newline turns its integrity row red (and only that row), and mutating the scratch corpus turns the `AC-15` floors red in both directions that matter. Full traces in `04_RATIONALE.md`
- no PowerShell figure is reported: `command -v pwsh` fails on this host, so all four `.ps1` edits and the `.ps1` driver are green-by-symmetry only (`N-3`). Static discipline was re-swept instead: no `$Is*` assignment, no `Set-Content`/`Add-Content`, no unparenthesised binary `-join` beside a `+`, no line-continuation backtick carrying trailing whitespace, no comment ending in a backtick, and delimiter depth returning to 0 with string literals and comments stripped

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| `D-1` `DESIGN DRIFT` | §C pass B has five rules and no heading rule; the contract's `Continuation line` excludes a `##` heading | pass B gains a rule between the section-preamble clause and the `in_entry` clause: a **heading line** — predicate `^#{2,6}[[:space:]]` in bash, `^#{2,6}\s` in .NET — is **unaccounted**, never a continuation, in **both** modes, and it clears `in_entry` | `X-8` requires one of the two readings to be implemented and stated. The contract's reading was chosen because the design's silently absorbs a heading into an entry and rotation then carries it into `insight-history.md` (gate `G-16`); the contract's refuses loudly instead. `##` and deeper only: a single `#` stays a continuation, so nothing in the archived corpus moves |
| `D-2` `DESIGN DRIFT` | `K-7` derives the header block through an open comment and stops there; no `B-*`, `BC-*` or `K-*` disposes of a comment still open at EOF | when pass A reaches EOF in mode `index` with comment state true, the **opening `<!--` line is reported as unaccounted** (kind `U`, its own diagnostic wording), so `K-16` refuses at exit 3 and `I.4` WARNs | `X-10` requires the case to be measured. Making `R12`'s stated outcome true was preferred to dispositioning it, because the alternative leaves an index that grows without bound with every line commented out and both gates green. Reusing the existing `unaccounted > 0` predicate means no new refusal condition and no new `I.4` arm |
| `D-3` | `K-18` — "one tally line … plus one line carrying the index's entry count after the run" | two lines: `Insight tally: entries N, continuation lines N, ignorable lines N (terminal footer N), unaccounted lines N` and `Index tally: entries N, unaccounted lines N, entries after run N` | the index's own unaccounted count has no home in `K-18`'s single line, and `K-16` needs it visible on the refusing run. Both lines print on every terminating path, refusal included |
| `D-4` | `K-26` / `B-14` — `I.4`'s non-PASS "names both counts and the 1-based line number of the first unaccounted line" | the bash `I.4` block **echoes its own detail line** after calling `step`; `step()` itself is untouched | `verify_all.sh:21` prints a detail line for `FAIL` only, never for `WARN`, so the message `step` receives is never rendered in bash. Editing `step()` would change the output shape of every WARN check and is outside ledger row 5. The PowerShell twin already prints its detail inline |
| `D-5` | `BC-19` — "delivery document present but unreadable → exit non-zero before any write"; no mechanism named | explicit `[[ -f … && ! -r … ]]` test → message + exit 1, before the read | `set -e` on a failed redirect would exit 1 too, but with no diagnostic; the driver row asserts the message |
| `D-6` | `K-63` — the `touch` moves into the write phase | the write phase creates a missing index **unconditionally** on a real run, not only when entries were harvested | matches pre-change behaviour (`archive-task.sh:60-62` created it on every real run) and `K-63`'s "a real run creates the file"; a 0-entry harvest against a missing index therefore still leaves an empty index behind |
| `D-7` `DESIGN DRIFT` (round 3, `QA-1`) | §C and `K-6` describe **one** section, located by the first matching heading and closed by the terminator `archive-task.sh:51` uses today; no `B-*`, `BC-*` or `K-*` row disposes of a document with two matching headings or with one inside a fenced block | section discovery is now a **whole-document, fence-aware walk**: (i) **every** `^##\s+Insights?\s*$` opens a section and all of them are scanned and accumulated; (ii) a heading inside a fenced code block is neither an opener nor a terminator — fence state is tracked once, for both, so they can never disagree about where a section is; (iii) a fence still **open at EOF** is reported (`… : unterminated code fence opened here: …`) and refuses at exit 3; (iv) every matching heading skipped for being quoted is **counted and printed** as `Quoted headings: N '## Insight' heading(s) inside a code fence were not harvested` | (i) is not a new feature, it is the repair of a regression: the pre-change awk re-armed `flag` on **every** matching heading, so the `break` broke `B-11` *inside* `K-65`'s admissible class and broke user requirements 2 and 4. (ii) is required because this task's own delivery document quotes the heading — QA reproduced, against a copy of the live 30-entry index, a run that harvested a documentation example plus a bare fence, rotated a real entry into history, lost every real insight and exited 0 with `I.4` PASS. (iii) exists because fence tracking otherwise *opens* a loss channel of its own (an unclosed fence hides every later heading); it reuses `D-2`'s `unaccounted`/exit-3 machinery, so no new refusal condition and no new `I.4` arm. (iv) exists because otherwise "we ignored a heading" would be inferable only from an entry that never arrived — which is precisely the shape this task exists to remove |

**Round 4 adds no drift.** No shipped script moved; the only change is a driver fixture, and
`test-archive-task.*` is disposed of by `K-30`.

Two corrections to the `D-7` row above, kept here rather than rewritten into it so the round-3 record
stands as written. (a) Code review adjudicated `D-7` **ACCEPTED in all four items, with no re-gate**;
the only thing owed is a prose correction to `02_SOLUTION_DESIGN.md`'s `K-6` (`CR-11`), which is
architect-owned and outside this stage. (b) The row's "(ii) is required because …" overstates: **(i)
alone restores pre-change behaviour**, so fence-aware discovery is not a repair *prerequisite* — it
over-harvests without it rather than losing content. What makes (ii) landable is (iv): without the
`Quoted headings:` line, (ii) is a narrowing whose effect is inferable only from an entry that never
arrived. (ii) and (iv) stand or fall together, and they shipped together.

## Condition disposition

| id | disposition | evidence |
|---|---|---|
| `X-8` | **discharged.** The contract's `Continuation line` is implemented, not the design's pass B — see `D-1`. Pinned in both modes with explicit expected values: section row asserts exit 3, the diagnostic `:6: unaccounted line: ### Subheading inside the section`, and the tally `Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 1`; index row asserts exit 3, the diagnostic `insight-index.md:4: unaccounted line: ## Stray heading in the index`, the tally `Index tally: entries 1, unaccounted lines 1, entries after run 1`, and byte-identity of the index | `test-archive-task.sh` banner `X-8 — a ## / ### heading line, in BOTH modes, is UNACCOUNTED`, 8 assertions, all green post-change and all 8 red against the pre-change script |
| `X-9` | **discharged.** The delivery read is `mapfile -t LINES < "$delivery_file"` (`archive-task.sh`), `@(Get-Content -Path $deliveryFile)` in the twin — both keep an unterminated final line. The `while IFS= read -r` idiom is gone from the script entirely | driver banner `X-9`, fixture whose last line is `  its continuation · evidence: z:3` with no trailing newline: asserts the fixture really lacks the newline **as a byte test** (`tail -c 1 \| wc -l` in bash, last byte `-ne 10` in the twin — both have range `{yes, no}`), exit 0, tally `continuation lines 1`, and that the line reaches the index verbatim as the last index line. 2 of its 4 rows are red against the pre-change script; the fixture-integrity row is proven load-bearing by mutation (`04_RATIONALE.md`) |
| `X-10` | **discharged by making `R12`'s outcome true**, not by dispositioning it — see `D-2`. Measured, not argued | driver banner `X-10`: index with one unbalanced `<!--`; asserts **exit 3**, the diagnostic `insight-index.md:3: unterminated HTML comment opened here: <!-- Append new insights below, one per line. Format:`, the **tally** `Index tally: entries 0, unaccounted lines 1, entries after run 0`, byte-identity of the index, and **`I.4`'s verdict** over the same file: `WARN` naming `0 entries, 1 unaccounted line(s), first at line 3`. 4 of its 6 rows are red against the pre-change script |
| `X-11` | **discharged.** `baseline.json` gains `_qa_note_t20`, whose operator **item 17** names `AC-1`, `AC-2`, `AC-3`, `AC-13`, **`AC-14`** and **`AC-16`**, plus the parse sweep, the `B-18` byte-identity comparison and the `$Is*` / `-join` / `Set-Content` construct checks. Items 1-16 were not renumbered, reconciled, re-read or edited; `_qa_note_t13`, `_qa_note_t16`, `_qa_note_t17` and `_qa_note_t12` are byte-unchanged | `.harness/scripts/baseline.json`; the only edit is the insertion of two keys after `test_guard_rm_bash_assertions` |
| `X-12` | **discharged.** No `(( x++ ))` standalone statement, no bare `[[ =~ ]]` statement, and no `&&` AND-list as the last command of a function body or of an `if` / `else` branch was introduced. Every counter is `n=$((n+1))`; every test sits inside an `if`; all three functions end in `return 0`. The `&&` occurrences are all inside `if` conditions, inside `(( … ))` arithmetic, or in the pre-existing `repo_root=` command substitution | static audit over the diff plus the two named anti-regression runs: `--dry-run` against a missing index reaches step 4 (`[DRY RUN] No files written.`, exit 0) and a zero-count harvest reaches step 4 (`Archived task: bc1`, exit 0), both asserted as driver rows |

`X-6` and `X-7` are analyst-owned and were already discharged in round 3 of `01_REQUIREMENT_ANALYSIS.md`; this stage read the corrected text and implemented against it.

## Open issues for review

### What still gets through (round 4) — stated bounds, none silent by inference

Every row below was measured on the promoted script, in a sandbox, **in round 4** — the runs are
transcribed in `04_RATIONALE.md`. Round 3's version of this table stated bounds 2, 3 and 5 more
favourably than the artifact supports (`CR-12`, and the bound-4 `NIT`); the corrections are marked
**⚠ round-3 text was wrong** so the delta is visible rather than quietly overwritten.

Each row is still either an **add** to the index or a **loud refusal**; none reproduces the
exit-0-with-discarded-content shape of `QA-1`. Refusal means exit 3, index byte-identical, nothing
written, and one diagnostic naming the exact line.

| # | shape | measured behaviour (round 4) | why it is a bound and not a defect |
|---|---|---|---|
| 1 | a section lying **entirely** inside a fence | `entries 0`, exit 0, **plus** `Quoted headings: 1 …` | quoted content is documentation by the new rule; the run names the heading it skipped, so nothing is inferable only from a missing entry. Pinned by driver case `QA-1 bound` (4 rows) |
| 2 | a fence **inside** the section, **directly abutting** the entry above it | absorbed as **continuation** lines of that entry (`continuation lines 3` on the pinned fixture) and they reach the index verbatim | fence awareness is scoped to section *discovery*; pass B is unchanged. Making pass B fence-aware would make fenced lines **ignorable**, i.e. would *create* a discard channel — option comparison in `04_RATIONALE.md`. Pinned by `QA-1 residual` (3 rows) |
| 2a | ⚠ **round-3 text was wrong**: the same fence with a **blank line before it** (the conventional Markdown shape) | **refuses at exit 3** — the blank closed the entry, so the three fence lines are `unaccounted lines 3`, each named. Captured | adjacency to the entry, not fencedness, decides. Loud, writes nothing. **Unpinned by any row**; the driver's own comment at the `QA-1 residual` case says "(or refused if no entry is open)" and round 3's published bound did not |
| 2b | ⚠ **round-3 text was wrong, and this is a behaviour change**: a fence inside the section whose body holds a **column-0 `##`** line | **refuses at exit 3** (`unaccounted lines 2`, `Quoted headings: 1`). Round 2's fence-unaware discovery let that line match `RE_SECTION_END` and **truncated the section at exit 0** | the new outcome is strictly better — a loud refusal naming the line, versus silent truncation — but it is a change on a plausible shape (quoting Markdown, `## Insight` included, inside a fence *within* the insight section) and no round-3 bound declared it. The round-4 outcome (exit 3) is **captured**; round 2's outcome (exit 0, truncated) is a **hand trace** and is marked as one, because round 2's script exists in no commit and cannot be re-run |
| 3 | a `## Insight` inside an **HTML comment** in the delivery document, closing `-->` **directly abutting** the entry | harvested normally; the `-->` is absorbed as a continuation line, exit 0. Captured | comment state is `index`-mode only (`K-7`). Over-harvest, never loss; harvested lines are echoed before the write, so `K-53`'s dry-run-then-compare sees them |
| 3a | ⚠ **round-3 text was wrong**: the same document with a **blank line before the `-->`** | **refuses at exit 3**, `unaccounted line: -->` named. Captured | identical root cause to 2a — a continuation needs an open entry. Same phrasing defect, same correction |
| 4 | a `> ## Insight` inside a **blockquote**, or a heading indented by **1 or more** spaces | not a section, not counted as quoted, no notice, exit 0. Captured at **one** space | ⚠ round 3 said "4+ spaces", which implies 1-3 would be harvested; any indentation ≥1 fails `^##` in both twins and in the pre-change awk. `^##` anchoring is unchanged from that awk, so this is outside the regression class. A future task that wants it should extend `h_quoted` |
| 5 | `~~~` after an opening ` ``` ` | does **not** close it, so the fence is open at EOF and the run **refuses at exit 3**, naming the opener. Captured, and now **pinned in the other direction**: `CR-13`'s `qa1f` fixture has a ` ``` ` run inside a `~~~` fence that must not close it | the closer must match the opener's character and length, per CommonMark. ⚠ round 3 published `Quoted headings: 2` as if it were a property of the shape; it is the count of matching headings that happen to be inside that fence — measured **2** on `qa1c`, **1** on a one-heading variant, and the line is **absent** when the fence hides none |
| 6 | everything in `QA-3`…`QA-8` | unchanged since round 2, re-confirmed in round 4 | see the dispositions below |

Bound 5's tilde branch is now instantiated: `RE_FENCE` / `$atReFence` accept `~{3,}` and a tilde
opener's info string is unrestricted where a backtick opener's may hold no backtick, and until round 4
**no fixture in either driver used a tilde at all** (`CR-13`). The `qa1f` case exercises the tilde
opener with a backtick in its info string, the mismatched closer and the tilde closer in one document,
and it discriminates in all three directions — if the opener failed to open, the quoted heading would
become the section and the tally would read `entries 2`; if the closer failed to close, the run would
refuse at exit 3.

### QA residual dispositions (round 3, unchanged in round 4) — nothing taken, with a reason each

`QA-1` is fixed. None of `QA-2`…`QA-8` lives in the code round 3 touched (delivery-section
discovery), round 4 touched no shipped code at all, and each needs a decision this stage is not
allowed to make:

- **`QA-2`** (`entries after run` can state a number the produced file contradicts, via the
  no-final-newline glue) — the repair is in the **append** path. The glue is `K-58`, a design-stated
  known bound; re-scanning the written file to derive the figure changes what `D-3`'s line *means*.
  Cannot fire on the live index (it ends in a newline and the run takes the rewrite path). **Left**,
  with QA's own two candidate fixes recorded.
- **`QA-3`** (`B-20`'s "no line is dropped" is false for blank lines, 62→32) — a **prose correction
  to `02_SOLUTION_DESIGN.md`**, which is read-only to this stage. **Left** for the architect.
- **`QA-4`** (a balanced comment opened in the header and closed after stored entries absorbs them) —
  this is `K-7`/`K-64` generalising exactly as specified, and `B-19`/`BC-24` (the shipped
  `insight-index.md.tmpl` example line) **require** it. No data loss. **Left**; narrowing it is a
  design change with a driver row that would go red.
- **`QA-5`** (terminal-footer channel; the footer figure counts blank lines, so it does not say how
  many *content* lines were dropped) — designed `BC-20`, the non-wedging floor, byte-identical to
  pre-change. **Left**, but note this round establishes the precedent QA asked for: `Quoted
  headings:` is exactly the "report what you skipped as its own figure" shape, and a later task can
  copy it for the footer.
- **`QA-6`** (a `*`- or `1.`-bulleted section is discarded whole) — `BC-3` by the letter, pre-change
  identical; widening the entry marker set changes `RE_ENTRY` in four places and moves the `K-61`
  oracle. **Left**.
- **`QA-7`** (rotation is not transactional) — explicitly out-of-scope 7. **Left**.
- **`QA-8`** (`--task ../../victim` traverses) — pre-existing, byte-identical in the pre-change
  script, outside every ledger row; a path guard has its own blast radius on legitimate slugs.
  **Left**.

`CONTEXT.md:91` still reads "recorded as **one line** in the insight index", which now sits four lines above an `Insight entry` definition that allows continuation lines. Gate `G-23` records it as defensible under out-of-scope 5 (the retained authoring preference) and it is outside every ledger row, so it was left alone.

`I.4`'s numeric detail is only assertable from the PowerShell twin's output shape without `D-4`'s echo; with the echo both shells name the counts, but they name them in different places (PS inline on the `[I.4]` line, bash on the following line). Operator item 17 states this so the two are not mistaken for a divergence.

The `K-61` raw-marker oracle is specified as GNU grep BRE; on this host `grep` resolves to ugrep 7.5.0. `[[:space:]]` is read identically by both, and the oracle's value is corroborated by `archive-task`'s own reported entry count in every row that uses it, but a QA re-run on a GNU-grep host is the honest confirmation.

`archive-task.sh` still takes `"$2"` for `--task` with no guard, so `--task` with no value aborts under `set -u` rather than printing the usage line. Pre-existing, unchanged, and outside every ledger row.

Three NITs against the **shipped** scripts are recorded and **none of the three was taken in round 4**. Their **current** anchors, re-read this round (round 3 moved every `archive-task.sh` anchor and the round-3 record still cited the round-2 ones — `CR-10`(a)):

- `archive-task.sh:328-330` and `:205` — `"${arr[@]}"` on legitimately-empty arrays: safe on bash ≥ 4.4, aborts under `set -u` on 4.2/4.3, and the 4.4 floor still has no header clause beside the `set -e` block at `:52-56`
- `archive-task.sh:394-395` — `.harness/insight-index.md.tmp` residue left by an interrupted rewrite
- `verify_all.sh:535` — the provably-unused 4th argument to `step`

Code review round 3 recorded that two of the three deferral grounds had expired, since round 3 shifted every `archive-task.sh` anchor anyway. That is correct, and it is **not** the ground for deferring them again. The round-4 ground is narrower and specific to this round: round 4 is a document-correction return whose one authorised code change is the `CR-13` driver fixture, and `archive-task.sh` is in the **mirror set**. Taking either `archive-task.sh` NIT would move a shipped, mirrored file, shift every anchor below it for a third time — including the anchors this very round is correcting, and every anchor cited in `05_CODE_REVIEW.md`, which is read-only to me — and re-open the byte-identity and construct sweeps, to buy a comment and a `trap`. That is precisely the round expansion the PM's stop rule forbids. `verify_all.sh:535` is unmoved and its original deferral stands unchanged. All three belong to whichever task next opens those files for a reason of its own; the `.tmp` residue is the only one with any behaviour attached and it should be taken with a `trap`, not inline.

`AC-15`'s floors are floors, so the driver alone no longer reports the corpus census; the census figures live in `_qa_note_t20` and in `04_RATIONALE.md`, and an operator wanting the current numbers must read them off an instrumented run.

## Dev-map updates

`docs/dev-map.md` gains one scripts-tree row for `test-archive-task.{ps1,sh}` describing its case set, its optional path argument and the fact that it is in neither `sync-self`'s mirror set nor `verify_all` `F.1` — per gate `Q-6`, `F.1`, `sync-self`, `AI-GUIDE.md`'s driver list and `40-locations.md` were **not** touched.

`docs/dev-map.md`'s existing `archive-task.{ps1,sh}` row is annotated with the entry boundary and the exit-3 refusal, because the row previously described only "Insight-harvest + stage-doc archive".

Round 3 extends both rows: the `archive-task` row now states that **every** `## Insight` section is
harvested, that a heading inside a fenced code block is not a heading, and that a fence left open at
EOF refuses; the `test-archive-task` row names the multi-section + fenced-heading coverage.

Round 4 changes **one** dev-map word: `docs/dev-map.md:107`'s fenced-heading clause now reads
"(QA-1, backtick AND tilde fences)", because the driver's case set gained the tilde fixture and that
row is the place the case set is advertised. No file was added, moved or removed in either round, so
no other dev-map line changes and no new module, folder or mirrored pair exists.

## Insight to surface

- 2026-08-01 · A counting `grep` guarded by `|| fallback` manufactures a WRONG value rather than a missing one when the tool disagrees about the pattern: this host's `grep` is ugrep 7.5.0, `grep -cP '[ \t]+$'` prints `0` AND exits non-zero there, so `$(grep -cP … || echo 0)` yields the two-line string `0\n0` and an equality assertion against `0` fails with a diagnostic that looks like a real defect in the code under test. The L31 lesson generalises past matcher semantics to the exit-status contract: `grep -c` already exits 1 on zero matches, so `|| fallback` is redundant when the tool works and corrupting when it does not. · evidence: T-20 dev round 1, `test-archive-task.sh` BC-9 row `expected [0] got [0\n0]`, fixed to `grep -c '[[:space:]]$' … || true`
- 2026-08-01 · Relaxing a test row from `== N` to `>= N` to stop it going stale over a growing corpus can silently destroy its anti-revert coverage, because the value the row reads is often parsed out of the output of the script under test and the OLD script's output degrades to garbage rather than to a small number: here `${line##*terminal footer }` on the pre-change script's absent tally line returns the whole (empty) string unchanged, every unmeasured section was then counted as footer-bearing, and `>= 3` went GREEN against the exact script it exists to detect while `== 3` had been red. Relaxing an assertion therefore needs the pre-change run re-measured, and a parse that distinguishes "no measurement" from "a measurement of zero". · evidence: T-20 dev round 2, `test-archive-task.sh` AC-15 split moved 70/82 → 71/81 on the relaxation and back to 70/82 once both twins parsed the tally strictly
- 2026-08-01 · `verify_all.sh`'s `step()` renders a check's detail string for `FAIL` only and silently discards it for `WARN` (`verify_all.sh:21-22`), while the PowerShell twin's `Step` prints the detail inline before the verdict — so any check whose WARN message IS its value (a line number, a count, a file name) is mute in bash and loud in PowerShell, and a design that says "WARN naming both counts and the line number" is unmet in one shell with no gate able to see it. The asymmetry lives in the reporting helper, not in any check, so it is invisible when reading the check you are writing. · evidence: T-20, `verify_all.sh:17-25` vs `verify_all.ps1:19-37`, found when a driver row asserting `I.4`'s detail went red against a correct implementation

- 2026-08-01 · Replacing a *scanner* with a *parser* silently narrows the input class it accepts, and the narrowing is invisible in the diff because the old code's leniency was an accident of its shape: awk's `flag=1` on every matching heading was not a decision to support multi-section documents, it was what a streaming one-pass filter does for free, so re-expressing it as "find the section, then scan it" dropped a property nobody had written down and no `AC`/`BC`/`K` row disposed of. The regression floor that caught it is not a test of the new behaviour but a **byte-identity comparison against the old script on a fixture in the class the design itself declared admissible** — which is why the anti-revert leg has to run the *same* fixtures as the feature legs, not a separate curated set. · evidence: T-20 `QA-1`; the `break` at `archive-task.sh:235-239` **as that file stood in dev round 2** (removed in round 3, so the anchor is historical and resolves to nothing today) vs `git show HEAD:.harness/scripts/archive-task.sh:52` (`/^##[[:space:]]+Insights?/{flag=1; next}`); closed by `test-archive-task.sh` case `AC-4 multi-section`
- 2026-08-01 · A tool that reads Markdown *about itself* must treat fenced blocks as opaque, because the one document guaranteed to quote the tool's own trigger syntax is the delivery document of the task that changed it — here the harvester read the quoted `## Insight` example as the real section, wrote a documentation bullet and a bare ` ``` ` fence into the index, rotated a real entry into history, lost every genuine insight, and exited 0 with `I.4` still PASSing. The corollary is that skipping a quoted trigger must be **printed**, not just done: without a `Quoted headings: N` line the new rule is a second silent-discard channel wearing the fix's clothes. · evidence: T-20 `QA-1` delivery variant / QA's `L-2` against a copy of the live 30-entry index; `archive-task.sh` `RE_FENCE` + `h_quoted`

**Round 4 adds no sixth line, and that is a decision rather than an omission.** The round's own
finding — that *adjacency to the entry*, not fencedness, decides between exit 0 and exit 3 for a
fence inside the insight section — is a bound of this tool, not a transferable project truth, and it
is now stated where a reader of this task will meet it (bounds 2/2a/2b above) and where the operator
will (`_qa_note_t20`). The index is at its 30-entry cap and every line added here competes for it;
five is the honest count for this task.

## Verdict

READY FOR REVIEW
