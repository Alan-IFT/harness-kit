# 02 — Solution Design — T-20 `harvest-wrapped-insight`

> Contract portion. Option comparisons, the reuse audit, risks, evidence citations, the corpus
> census, the `K-62` / `K-67` arguments and the measurement narrative are in `02_RATIONALE.md`.

Mode: `full`. Human channel: deferred; the PM's seven rulings and the gate's `R-1`…`R-5` are adopted
unaltered. `K-n` are stable labels; a gap is a withdrawn identifier, never a missing row, and
withdrawn identifiers are not reused (`K-24`, `K-25`, `K-27`, `K-43`…`K-46`).

## A. Gate-finding dispositions

| Finding | Disposition |
|---|---|
| `G-1` FAIL | closed upstream. §C implements the contract's classification order as **three passes**, so the footer pass can only demote an *unaccounted* line (`K-2`, `K-62`) |
| `G-2` FAIL | `K-26`: `I.4` derives both its figures from one `INSIGHT-SCAN` over one file; the `grep -c` cap arm is removed. The frozen predicate survives as a **driver-side** oracle (`K-61`), never as a second count inside a shipped check. The upstream "G-2 dissolves" claim is false as stated — `K-67` |
| `G-3` FAIL | `K-7` derives the index header block **through** an HTML comment open at the first entry-start line; `K-64` states the consequence; no template file is edited; `AC-16` is the fixture |
| `G-4` / `G-5` WARN | accepted: §H, `K-43`…`K-46`, ledger 10-15 and `AC-10` withdrawn, `K-47` re-swept for orphans. `G-5`'s third leg (`05-insight-index.md.tmpl:5,29,48`) is ledger 25, independent of `B-16` |
| `G-6` WARN | closed upstream; `K-20`, `K-35`, `K-65` and `AC-9` follow the bash / PowerShell split |
| `G-7` WARN | `K-65` pins `AC-4`'s admissible fixture class and one concrete fixture |
| `G-8` WARN | ledger 26 and 27; `K-47` no longer lists `AI-GUIDE.md:79` or either `70-doc-size` twin as unaffected |
| `G-9` / `X-4` | `K-66`: `CONTEXT.md` corrected to present-true statements and entered as ledger 28 |
| `G-10` WARN | closed upstream; ledger 23 corrects `.harness/insight-index.md:3` |
| `G-11` MINOR | `K-34`'s case set rebuilt around `AC-13`, `AC-14`, `AC-16`; `K-61` is what a post-break-ignorable rule fails |
| `G-12` MINOR | `K-30` recounted from the artifacts: **eight** `sync-self` pairs; `F.1` names **two** test drivers and omits **five** recent ones — the precedent is recency, not kind |
| `G-13` MINOR | `K-63` designs `BC-23` |
| `X-5` | `AC-13` and `AC-14` are driver cases in `K-34`, each stating what the rejected reading does |

## C. INSIGHT-SCAN — the single entry-boundary algorithm (normative)

(§B, the definitions delta, is folded in here; the letter is not reused.) Every term of `01_REQUIREMENT_ANALYSIS.md`
"Definitions" is carried unchanged; this design adds two, both local to the algorithm — **comment state**, a
per-line boolean (`K-7`), and the **raw-marker count**, `grep -c '^[[:space:]]*-[[:space:]]'` over a whole file —
the pre-change quantity, used only as a test-driver oracle (`K-61`) and computed by no shipped check.

**K-1** — One algorithm, `INSIGHT-SCAN`, classifies lines for harvest, for reading the stored index,
for deriving the index header block, and for `I.4`. Specified once here, implemented once per file —
four implementations (`archive-task.{sh,ps1}`, `verify_all.{sh,ps1}`), no shared source (§M.1);
`K-67` states what that leaves to test rather than to construction. **K-2** — input: a mode
(`section` or `index`) and an ordered line list, normalised per `K-4`, with 1-based **file** offsets
retained for diagnostics. Classification is three passes, in this order.

*Pass A — header block* (mode `index` only): `K-7`, yielding `h`, the offset of the header block's
last line (`h = 0` when there is none).

*Pass B — kinds*: walk `i = 1..n` carrying `in_entry` and `seen_entry`, both false at entry. The
first matching rule assigns the kind and nothing else does:

1. mode `index` and `i ≤ h`; or mode `section` and `seen_entry` is false and the line is not an
   entry-start line → **ignorable**; `in_entry := false`.
2. line is blank (`^[[:space:]]*$`) → **ignorable**; `in_entry := false`.
3. line matches the entry-start predicate → **entry-start**; opens a new entry; `in_entry := true`;
   `seen_entry := true`.
4. `in_entry` is true → **continuation**; appended in order to the open entry.
5. otherwise → **unaccounted**.

*Pass C — terminal footer* (mode `section` only): let `e` be the offset of the last line of the last
entry pass B produced; with no entry there is no terminal footer. Let `f` be the smallest offset
greater than `e` whose line is a thematic break; if none exists there is no terminal footer.
Otherwise every line from `f` to the end of the list becomes **ignorable**, and the count of those
lines is reported as its own figure (`B-5`). **K-62** — pass C can only ever change a line's kind from
**unaccounted** to **ignorable** (proof: the rationale's pass-split section), so it never makes an
entry-start or continuation line ignorable, anywhere in any file — `B-3`'s binding property. Pass A is
not in its scope: a header-block line matching the predicate **is** ignorable (`K-64`, `B-19`, `AC-16`).

**K-3** — The entry-start predicate is `^[[:space:]]*-[[:space:]]` in every bash / grep / awk context
and `^\s*-\s+` in every PowerShell context. Neither is changed by this task; both are the forms
already at `verify_all.sh:463`, `verify_all.ps1:450`, `archive-task.sh:51,69,94` and
`archive-task.ps1:52,71,93`. No implementation may introduce a third spelling. **K-4** — every line
is normalised **before** classification and before any write, by removing all trailing whitespace and
leaving leading whitespace untouched, which discharges `BC-8` and `BC-9` (`OQ-5`) in both shells.

**K-5** — `INSIGHT-SCAN` is total: every line receives exactly one kind, depending only on the line,
the mode and state accumulated from earlier lines (pass C excepted, which depends only on `e` and the
break offsets after it). **K-6** — in mode `section` the input is the lines strictly between a
section heading and that section's terminator — the next **eligible** `^##[[:space:]]` line, or EOF.
The terminator *predicate* is byte-identical to the one `archive-task.sh:51` uses today; what is
**not** unchanged is a line's **eligibility** to be tested against it, which `K-71` makes conditional
on fence state, so a `##` line inside a fenced block neither terminates nor opens. In mode `index`
the input is the whole file, with no terminator and no fence state (`K-71`).
**K-8** — the modes differ in exactly two clauses: pass A runs only for `index`, pass C only for
`section`; pass B rules 2-5, the predicate and the normalisation are identical, so a section and an
index classify the same wrapped entry identically (`B-10`). `B-20`'s closing inference is false for
blank lines and is not carried here: a rewrite emits header ‖ retained ‖ harvested and a blank line is
ignorable (pass B rule 2), belonging to no entry, so what holds is that **no entry-start line and no
continuation line** is dropped by a rewrite except the entries rotation moves out, while blank lines
between stored entries are not re-emitted (`QA-3`, measured). Pass C not running for `index` is the
other half: no index line is demoted to ignorable by a terminal footer, so a stray line there stays
unaccounted and refuses (`K-16`).

**K-71 — section discovery (mode `section`).** One walk of the whole delivery document locates every
section; there is no first-heading search. Every **eligible** line matching
`^##[[:space:]]+Insights?[[:space:]]*$` opens a section, and every section found is scanned and its
entries and counts accumulated in document order — the pre-change awk re-armed on every such heading,
so this is `B-11` held, not an extension of it. A line is **ineligible** while it lies inside a
**CommonMark** fenced code block — opened by a run of ≥3 backticks or tildes at indentation ≤3, closed
only by a run of the same character, at least as long, with nothing after it — so a heading inside a
fence is neither opener nor terminator. Fence state is tracked **once**, by that one walk, and governs opener and
terminator together; tracking it for one alone is what cuts a live section short (`02_RATIONALE.md`
"Fence-aware discovery"). A fence still open at EOF is reported and **refuses at exit 3** through the
existing `unaccounted > 0` machinery (`K-15`) — no new refusal condition, no new `I.4` arm. Every
heading skipped for being quoted is counted and **printed** as `Quoted headings: N`, on every
terminating path: the report is a **precondition** of the fence rule, not decoration, so the rule and
the report are adopted or refused together. Fence awareness stops at discovery — pass B is
**unchanged**, so a fenced line inside a section is a continuation when an entry is open and
unaccounted otherwise, never ignorable (same rationale section). Mode `index` carries no fence state,
deliberately: there a fence line is a continuation, preserved verbatim through rotation, or
unaccounted, which refuses — never dropped — so "fenced content is documentation" stays confined to
the human-authored delivery document.

**K-7 — header block derivation (pass A).** Walk `i = 1..n` carrying `comment_state`, false at entry.
If `comment_state` is false and the line is an entry-start line, the header block is lines `1..i-1`
and the walk stops. Otherwise update `comment_state` by scanning the line left to right for the
**literal** tokens `<!--` and `-->` in occurrence order, the first setting it true and the second
false — fixed strings, never a regex (`K-41`) — and continue. If no line stops the walk the header
block is the whole file. It is emitted verbatim in file order and **never** derived by filtering the
file for non-entry lines, which is the hoisting defect (`B-8`, `archive-task.sh:94`).

**K-64 (`B-19`, `BC-24` — closes `G-3`)** — under `K-7` the shipped
`…/templates/common/.harness/insight-index.md.tmpl` (comment open at `:7`, entry-start-shaped example
at `:8`, close at `:9` — `F-4`) yields a header block of `:1-9`, **0** entries and **0** unaccounted
lines, so no rotation can carry `-->` out of an index whose header block is that content. No template
file is edited — the artifact at risk is the index **already on disk** in a generated project (`N-4`).
**K-61 — the raw-marker oracle (driver-side only)** — for any index whose header block contains no
entry-start-shaped line, the raw-marker count equals `INSIGHT-SCAN`'s entry count.
`test-archive-task.sh` asserts that equality on every index fixture of that class and the one
designed inequality — raw = entries + 1 — on `AC-16`'s fixture; the rejected post-break-ignorable
rule fails the equality on `AC-14`'s fixture, which is what makes `AC-3`'s third leg discriminating.

**K-67 — what `AC-3`'s agreement rests on (`R-5`, `G-2`).** Constructional only for the frozen predicate
(`K-3`) and one `INSIGHT-SCAN` per check and per run (`K-26`, `K-18`, `B-6`); by test for the two **bash**
implementations (`AC-3`, `AC-13`, `AC-14`, `AC-16`, `K-61`); by **operator run only** for the two
PowerShell ones (`B-13`, `B-18`, `AC-9` item 17) — priced in the rationale's `K-1` / `K-67` section. This
design does **not** claim the state machines agree by construction, and it records the upstream claim that
the two counts "can differ only on a file that refuses" as **false**: the shipped `insight-index.md.tmpl`
shape (`K-64`) differs with no refusal.

## D. Module decomposition and public API

### D.1 `.harness/scripts/archive-task.sh` (edit) and its `templates/common/` mirror

**K-9** — The awk pipeline at `:49-51` is replaced by: read the delivery file into a line array
preserving 1-based file line numbers, locate every section per `K-71` / `K-6`, run `INSIGHT-SCAN` mode
`section` over each. The result is an ordered list of **entries**, each an ordered list of lines; write
order is entries in source order, lines within an entry in source order. **K-10** — the index read at `:65-70`
is replaced by `INSIGHT-SCAN` mode `index` over the whole file, yielding the header block, the stored
entries and the index's unaccounted lines. **K-11** — the header derivation at `:94` is replaced by
`K-7`'s header block, emitted verbatim and first; `grep -vE` over the whole file is removed (`B-8`).

**K-12** — Rotation operates on entries (`B-6`). `total_after = stored + harvested`; when
`total_after > 30`, `rotate_count = min(total_after - 30, stored)` — the clamp is `BC-14` and removes
the unbound-expansion abort at `:77-79`. A rotated entry contributes all of its lines to
`insight-history.md` in order and none to the rewritten index (`B-7`). **K-13** — every line written
to the index or the history file uses `printf '%s\n'`, never `echo` and never a command substitution,
and the header block is written by iterating its array; the history file's block form is unchanged
(the `# Insight history …` creation line, `\n## Rotated <date>\n\n`, one line per rotated line).

**K-14** — Classification and the `K-15` / `K-16` checks complete **before** any mkdir, touch, write,
append or move; `--dry-run` shares that prefix verbatim, so `B-12` holds without a parallel path.
**K-15** — on `unaccounted > 0` in the delivery section: one diagnostic line per unaccounted line to
stderr, each naming the delivery document path, the 1-based line number in that document and the
line's text; then exit **3**. Nothing is created, written, appended or moved (`B-4`, `AC-2`).
**K-16 (`D-1`, beyond the letter of `B-4`; gate-ratified `R-3`)** — on `unaccounted > 0` in the
**insight index**, the same diagnostic shape naming the index path, exit 3 before any write. It cannot
fire on T-20's own delivery: the live `.harness/insight-index.md` classifies clean (`F-3`).

**K-17** — Exit codes: `0` success; `1` the pre-existing refusal family (usage, task directory
absent, already archived, delivery present but unreadable — `BC-19`); `3` the `K-15` / `K-16`
refusal. `2` is reserved by this repo's `PreToolUse` guard convention. **K-19** — no flag bypasses
either refusal (`OQ-7`).
**K-18** — The echo prints every line of every harvested entry, indented, in write order (`B-5`). The
script then prints one tally line carrying entries harvested, continuation lines harvested, ignorable
lines skipped **with the terminal-footer line count as its own figure**, and unaccounted lines; plus
one line carrying the index's entry count after the run. The tally is printed on **every**
terminating path, including the refusal, so `AC-3`'s comparison is available on a refusing run.

**K-63 (`BC-23` — closes `G-13`)** — The `[[ "$DRY_RUN" == false ]] && touch "$insight_index"`
AND-list at `archive-task.sh:62` becomes an `if` / `then` / `fi`, and the `touch` moves into the
write phase (`K-14`). A missing index classifies as an empty line list — empty header block, 0
entries, 0 unaccounted (`BC-10`); the warning is still printed; a real run creates the file, a
`--dry-run` writes nothing, and **both exit 0**. This is the one stated exception to `B-11 (bash)`,
a status rather than file content, and `B-18` is unchanged because the twin already exits 0 (`F-11`).
The driver **captures** the pre-change status from the extracted script rather than asserting a
predicted value (insight L12).

### D.2 `.harness/scripts/archive-task.ps1` (edit) and its `templates/common/` mirror

**K-20** — Structurally parallel to D.1: same step order, names, exit codes and counts. Its output
floor is `B-18`, not `B-11` — byte-identity against the post-change **bash** output for identical
input, with exactly three permitted differences from pre-change PowerShell output (LF with no BOM,
leading whitespace preserved, trailing whitespace stripped). Green-by-symmetry (`N-3`). **K-21** —
sections are located by walking the **line array** from `Get-Content -Path <file>`, not
`Get-Content -Raw` + `-match` + `-split "`n"`; `Get-Content` strips both `\n` and `\r\n` terminators,
removing the CR residue `.Trim()` currently hides (`archive-task.ps1:52`). Trailing whitespace is
removed with `.TrimEnd()`; `.Trim()` is forbidden anywhere in the harvest path.

**K-22 (gate-ratified `R-4`)** — Index and history writes use `[System.IO.File]::WriteAllText` /
`::AppendAllText` with `[System.Text.UTF8Encoding]::new($false)`, over a string built as
`(<array> -join "`n") + "`n"`, the empty-array case writing the empty string. `Set-Content` /
`Add-Content` are forbidden on these two files (`archive-task.ps1:87,89,90,95,99`): they emit
`[Environment]::NewLine`, the divergence `B-13` / `N-2` forbids.
**K-23 — three construct bans, insight L11 / L14** (`K-24` and `K-25` are withdrawn into it):
(a) every binary `-join` is fully parenthesised before it meets any `+`, and every multi-part message
is built with `-f` (`archive-task.ps1:94` is the shape being replaced); (b) new variables carry an
`at` prefix (`$atLines`, `$atKind`, `$atEntries`, `$atHeader`, `$atUnaccounted`) and the script
assigns no `$Matches`, `$input`, `$args`, `$error`, `$host` or `$Is*` name; (c) every introduced
string literal is single-quoted unless interpolation is required, and none is built by double-quote
concatenation.

### D.3 `verify_all` `I.4` — bash `:461-471`, PowerShell `:448-456`

**K-26 (closes `G-2`)** — `I.4` keeps its check id and exactly **one executed** `step` / `Step` call
per run; the total stays **32** (`B-14`, out-of-scope 4). Body: absent index → PASS, as today;
otherwise run `INSIGHT-SCAN` mode `index` **once** and derive both figures from that one
classification — the cap figure is the entry count, the second is the unaccounted count. WARN when
entries > 30 **or** unaccounted > 0, naming both counts and the 1-based line number of the first
unaccounted line. The `grep -c` / `Where-Object … .Count` cap arm at `verify_all.sh:463` /
`verify_all.ps1:450` is **removed**: it is a second notion of "entry" inside one check.
**K-68** — `I.4`'s label and message name the quantity the check counts: both twins move to
`insight-index.md ≤30 insight entries` / `insight-index.md <=30 insight entries`, each file keeping
its own `≤` / `<=` characters, and `$n evidence lines` becomes `$n entries`. No assertion tally and no
check count moves with it; that is measured, not assumed (`F-9`).

**K-28** — The bash arm reads with `mapfile -t` and classifies with bash's `[[ =~ ]]` ERE engine.
Every regex is held in a variable and left **unquoted** at the match site, per the hazard
`verify_all.sh:645-648` documents for `I.6`; same obligation inside `archive-task.sh`. **K-29** — a
WARN from `I.4` fails the gate: `verify_all` exits 1 on `warns > 0` (insight L22).

### D.4 `.harness/scripts/test-archive-task.{sh,ps1}` (new pair)

**K-30** — Location `.harness/scripts/`; the pair is **not** added to `sync-self`'s mirror set and **not**
to `verify_all` `F.1`. The counts behind that are `F-5`; the precedent is **recency, not kind**.

**K-31** — Invocation `bash .harness/scripts/test-archive-task.sh [archive-task-path]`, defaulting to
`$repo_root/.harness/scripts/archive-task.sh` (shape reused from `test-guard-rm.sh`); the optional path
is what lets `AC-4` drive the **committed pre-change** script extracted from git. **K-33** — the driver
ends with a `PASS: <n>` / `FAIL: <n>` summary block and exits non-zero when `FAIL > 0`; a run
terminating without that block is a failure of the driver, not a pass (insight L12).

**K-32** — Each case runs against a fresh sandbox repo root under `mktemp -d` containing
`.harness/scripts/`, `.harness/insight-index.md`, `docs/features/<slug>/07_DELIVERY.md` and
`docs/features/_archived/`. The script under test is **copied into the sandbox's `.harness/scripts/`**
first, because `archive-task` derives its repo root two levels up from its own location
(`archive-task.sh:27`). No case writes under the real repository; `AC-15` reads the archived corpus
read-only and classifies it in the sandbox.

**K-34** — The case set, one case per row, each with an explicit expected value:

| Case | Covers | Assertion |
|---|---|---|
| wrapped harvest | `AC-1`, `B-2` | index bytes equal the expected content; the `· evidence:` pointer on a continuation line is present |
| unaccounted delivery line | `AC-2`, `B-4`, `BC-5`, `BC-6` | exit 3; stderr names document, 1-based line number and text; index, history and task dir byte-identical and mtime-unmoved |
| **break then entry, delivery** | `AC-13`, `BC-21`, `X-5` | exit 3 naming the `---` line's 1-based number and text; the tally reports the post-break entry-start line and its continuation as **content**, never ignorable; all three artifacts byte-identical. *Rejected reading*: exits 0, drops both lines, no diagnostic |
| **break then entry, index** | `AC-14`, `BC-21`, `X-5` | the run refuses (exit 3) before writing; `cmp` the index against its pre-run bytes; `I.4` non-PASS; `K-61` equality holds (raw 2 = entries 2). *Rejected reading*: the run proceeds, the rewrite deletes both lines, `I.4` PASSes, `K-61` fails (raw 2, entries 1) |
| **shipped-template header** | `AC-16`, `BC-24`, `B-19` | index fixture whose header block is `insight-index.md.tmpl`'s nine lines; drive harvest **and** rotation; `cmp` the header-block region; grep the history file for `-->` and for the example line → 0 hits each; assert `K-61`'s designed inequality |
| terminal-footer corpus | `AC-15`, `BC-20` | all 34 archived `## Insight` sections yield 0 unaccounted and exit 0; the 3 footer sections report their footer line count as its own figure; tally transcribed from the captured run |
| break abutting an entry | `BC-22` | classified continuation; harvested with its entry; preserved verbatim |
| preamble shapes | `BC-3`, `BC-4` | preamble-only → 0 entries, exit 0, index not written, 0 unaccounted; preamble+entries → entries harvested, preamble counted ignorable |
| entry-start in continuation position | `BC-7` | 2 entries reported; `K-61` equality holds over the post-run index |
| CRLF document | `BC-8` | no `\r` byte in the written index |
| whitespace | `BC-9` | trailing whitespace absent, leading whitespace byte-preserved |
| cap boundaries | `BC-12`, `BC-13` | 30 → no rotation; 31 → exactly one entry rotated, oldest first |
| over-clamp | `BC-14` | completes, exit 0, no unbound-variable abort, every stored entry rotated |
| stored wrapped entry | `B-7`, `B-8`, `B-10` | header block byte-identical and still first; the rotated entry's every line in history, zero left in the index |
| index unaccounted | `K-16` | exit 3 naming the index path; nothing written |
| dry run | `B-12` | same counts and same exit status as the real run; no file created or modified |
| dry run, missing index | `BC-23` | post-change exit 0, nothing written; the pre-change status captured from the extracted script, never predicted |
| agreement | `AC-3` | `archive-task`'s reported post-run index entry count equals `I.4`'s entry count, over (i) the wrapped-entry rotation result and (ii) the `AC-14` fixture |
| regression floor | `AC-4` | `K-65`'s pinned fixtures, append **and** rotation paths, against the git-extracted pre-change script; `cmp` index and history |
| `I.4` non-vacuity | `AC-7` | `K-36` |

**K-35** — `AC-4`'s pre-change scripts are extracted from git to a scratch path and driven through
`K-31`'s argument; the comparison is `cmp` against the produced files. No figure in this task's
documents may be derived arithmetically (insight L12). `AC-4` is bash-only; the PowerShell side is
`B-18`, measured by `AC-9`'s item 17.
**K-65 (`AC-4`'s admissible fixture class — closes `G-7`)** — the pre/post divergences the class must
exclude are measured in `F-10`. An `AC-4` fixture is admissible only when all
seven hold: (1) the index has at least one line that is not an entry-start line; (2) no blank line
sits between the header block's last non-blank line and the first entry-start line, and no
non-entry-start line sits **after** the first entry-start line; (3) the index ends with a newline
(`K-58`); (4) the header block contains no entry-start-shaped line (that shape is `AC-16`'s, where
pre and post differ by design); (5) every harvested line is a single physical line with no trailing
whitespace and the delivery document is LF-only; (6) the section carries no unaccounted line;
(7) the index exists (a missing index is `K-63`, asserted rather than compared). Pinned fixture: an
index whose **first** line is `# Insight Index — fixture` and whose second and later lines are
entry-start lines, each one physical line ending in a non-space character, the file ending in exactly
one newline; and a delivery document whose section is the heading, one blank line, then
single-physical-line entries. Append path: 5 stored, 2 harvested. Rotation: 30 stored, 2 harvested.

**K-36** — `AC-7` is proven by mutating an artifact, never by inspecting a pattern, and the mutation
is an **insertion** so it cannot remove another assertion's container (insight L28): append a blank
line and one line of ordinary prose, carrying no `I.6` banned anchor, to a copy of
`.harness/insight-index.md`. Primary mechanism: a sandbox `verify_all.sh` run asserting on the
`[I.4]` line of its stdout and ignoring every other check; a run whose stdout carries no `[I.4]` line
fails the row. Fallback: a transient in-place mutation of the real index, then removal and a `cmp`
against a pre-mutation copy, which keeps `AC-11` true. QA records which mechanism was used.
**K-37** — `baseline.json` gains exactly one numeric key, `test_archive_task_bash_assertions`,
transcribed from the executed bash run, plus a `_qa_note_t20` key; there is deliberately **no**
`test_archive_task_ps_assertions` key (`pwsh` is absent on this host — `_qa_note_t17`'s phantom-key
trap), and no case is conditional on any host capability, so the key needs no qualifier.

## E. Interface contracts

**K-38** — The CLI is unchanged: `--task <slug>` / `-Task <slug>`, `--dry-run` / `-DryRun`; no flag
is added (`K-19`). **K-39** — stdout carries the echo, the rotation notice, the tally and the step-4
report; the `K-15` / `K-16` diagnostics go to **stderr**, so callers parsing stdout are unaffected in
the success case except for the two added tally lines. **K-40** — no file format changes; a
pre-change index, history file and delivery document are all valid inputs, with no migration step,
flag or state (`N-1`).

## F. Flow

```
archive-task --task <slug>
  ├─ resolve paths; refuse (exit 1): no task dir │ already archived │ delivery unreadable
  ├─ read 07_DELIVERY.md → lines (1-based offsets kept); locate every ## Insight section (K-6, K-71)
  │    └─ INSIGHT-SCAN each section → entries, counts, unaccounted[], accumulated in document order
  ├─ read insight-index.md (absent ⇒ empty list, K-63); INSIGHT-SCAN index
  │    └─ header block (K-7), stored entries, unaccounted[]
  ├─ print echo + tally (K-18)
  ├─ if either unaccounted[] is non-empty → diagnostics to stderr, exit 3   ◄── before any write
  ├─ total_after = stored + harvested (entries, not lines)
  │    ├─ > 30 → rotate min(total_after-30, stored) entries (all lines) → insight-history.md;
  │    │         rewrite index = header ‖ retained ‖ harvested
  │    └─ ≤ 30 → create index if absent; append harvested entries (all lines)
  ├─ move docs/features/<slug>/ → docs/features/_archived/<slug>/ ; report
```

`--dry-run` shares every step through the tally, writes nothing, and returns the real run's exit
status (`B-12`, `BC-23`, `K-14`).

## G. Matcher register — which tool evaluates what (insight L31)

**K-41** — `[ \t]` must not appear inside any bracket expression introduced by this change, in either
shell. The only whitespace spellings permitted are `[[:space:]]` in bash / grep / awk contexts and
`\s` in PowerShell / .NET contexts. `K-7`'s HTML comment tokens are fixed strings in both twins,
registered with no regex engine at all.

| Matcher | Evaluated by | Where | Status |
|---|---|---|---|
| `^[[:space:]]*-[[:space:]]` | GNU grep (BRE) | `test-archive-task.sh` oracle (`K-61`) | text unchanged; **moves out of** `verify_all.sh:463` |
| `^[[:space:]]*-[[:space:]]` | bash `[[ =~ ]]` (POSIX ERE) | `INSIGHT-SCAN` in `archive-task.sh`, `verify_all.sh` `I.4` | new evaluation site, same text |
| `^\s*-\s+` | .NET regex | `verify_all.ps1` `I.4`, `archive-task.ps1` | text unchanged |
| `^##[[:space:]]+Insights?[[:space:]]*$` | awk (ERE) → **bash `[[ =~ ]]`** | `archive-task.sh:51` → new scan | **tool changes**; confirm equivalence with a fixture whose heading separator is a literal tab |
| `^##[[:space:]]` (section terminator) | awk → bash `[[ =~ ]]` | same | same obligation |
| `^[[:space:]]*$` / `^\s*$` | bash `[[ =~ ]]` / .NET | pass B rule 2 | new |
| `^[[:space:]]{0,3}(-{3,}\|\*{3,}\|_{3,})[[:space:]]*$` | bash `[[ =~ ]]` | pass C | new |
| `^\s{0,3}(-{3,}\|\*{3,}\|_{3,})\s*$` | .NET | pass C | new |
| `<!--`, `-->` | fixed-string scan (no engine) | `K-7` pass A, both twins | new |

**K-42** — Known bound, record-only: `[[:space:]]` (C locale, ASCII) against .NET `\s` (Unicode); the
divergence exists today at `verify_all.sh:463` vs `.ps1:450` and is not introduced, widened or repaired.

## H. Withdrawn

§H (`B-16`, the six template `F.4` edits, `K-43`…`K-46`, ledger rows 10-15, `AC-10`) is withdrawn per
gate `R-2` / `X-3`: the defect is pre-existing and carried by out-of-scope 11(a) and its follow-up row,
and the six files are recorded in `K-47` as inspected and deliberately unchanged.

## I. Change ledger

| # | File | Change | Why | Lockstep |
|---|---|---|---|---|
| 1 | `.harness/scripts/archive-task.sh` | edit — D.1, incl. its `:59` comment | `B-1`…`B-12`, `B-19`, `B-20`, `BC-*` | 3 |
| 2 | `.harness/scripts/archive-task.ps1` | edit — D.2, incl. its `:12`, `:61` comments | `B-13`, `B-18`, `N-2`, `N-3` | 4 |
| 3 | `skills/harness-init/templates/common/.harness/scripts/archive-task.sh` | edit — byte-identical to 1 | `B-15`, `E.1` | 1 |
| 4 | `skills/harness-init/templates/common/.harness/scripts/archive-task.ps1` | edit — byte-identical to 2 | `B-15`, `E.1` | 2 |
| 5 | `.harness/scripts/verify_all.sh` | edit — `I.4` `:461-471` | `B-6`, `B-14`, `K-26`, `K-68` | 6 |
| 6 | `.harness/scripts/verify_all.ps1` | edit — `I.4` `:448-456` | `B-6`, `B-14`, `K-26`, `K-68` | 5 |
| 7 | `.harness/scripts/test-archive-task.sh` | **new** — D.4 | `AC-1`…`AC-4`, `AC-13`…`AC-16` | 8, 9 |
| 8 | `.harness/scripts/test-archive-task.ps1` | **new** — symmetric twin | `N-3`, `AC-9` | 7 |
| 9 | `.harness/scripts/baseline.json` | edit — one numeric key + `_qa_note_t20` | `K-37`, `AC-9` | 7 |
| 10-15 | — | **withdrawn** (§H); identifiers not reused | — | — |
| 16 | `agents/pm-orchestrator.md:219-221` | edit — drop the false "silently dropped" clause; keep the one-physical-line preference | `B-17` | 17 |
| 17 | `agents/developer.md:64` | edit — drop "A wrapped bullet loses its continuation lines when harvested" | `B-17` | 16 |
| 18 | `docs/dev-map.md` | edit — one new scripts-tree row for `test-archive-task.{ps1,sh}` | discovery surface | — |
| 19 | `.harness/rejected-decisions.md` | append — three records (`K-48`) | decision policy | — |
| 20 | `CHANGELOG.md` + release stamps | PM/delivery — `K-49` | release convention, `G.3` | each other |
| 21 | `docs/tasks.md` | PM — this task's row **and** the out-of-scope-11 follow-up row (`X-3`) | routing | — |
| 22 | `.harness/insight-index.md` | append, **by `archive-task` at stage 7 only** | `OQ-6` supersession | — |
| 23 | `.harness/insight-index.md:3` (header block) | edit — cap sentence from lines to entries | `B-17`, `G-10` | — |
| 24 | `agents/pm-orchestrator.md:61` | edit — cap stated in entries | `B-17` | — |
| 25 | `.harness/rules/05-insight-index.md:5,25` **and** its twin `…/templates/common/.harness/rules/05-insight-index.md.tmpl:5,29,48` | edit — cap and rotation stated in entries | `B-17`, `G-5` third leg | each other |
| 26 | `.harness/rules/70-doc-size.md:28,152` **and** its twin `…/templates/common/.harness/rules/70-doc-size.md.tmpl:27,151` | edit — caps-table row and "Harvests `## Insight` lines" | `B-17`, `G-8` | each other |
| 27 | `AI-GUIDE.md:37,79`, its twin `…/templates/common/AI-GUIDE.md.tmpl:35`, and `docs/concepts.md:168` | edit — cap and ">30 lines" stated in entries | `G-8`, `K-69` | each other |
| 28 | `CONTEXT.md:95-111` | edit — `K-66` | `X-4`, `G-9` | — |

**K-69** — Row 27 satisfies `B-17`'s **predicate** but sits outside its **enumeration** (agent
contracts, rule fragments and their template twins, the index header block); it is included for the
reason the rationale's prose sweep gives, and the gate may strike it without touching another row.

**K-47** — Prose surfaces inspected and deliberately **not** changed, in four classes, each file
enumerated with its line numbers in `02_RATIONALE.md` "Prose sweep" (insight L34): the "one physical
line" authoring preference (six files, retained by out-of-scope 5); sentences describing harvest
without a quantity, true before and after (eight files); the six template
`verify_all.{sh,ps1}.tmpl` `F.4` blocks (out-of-scope 11(a)); and history-bearing files
(`CHANGELOG.md`, `docs/tasks.md` completed rows). Named here because it is **the `G-3` file**:
`…/templates/common/.harness/insight-index.md.tmpl:3,8` is not edited — out-of-scope 11(b) owns both
its defects and `B-19` is discharged inside the algorithm by `K-7` / `K-64`, the only route that also
reaches a generated project's on-disk index (`F-6`); out-of-scope 11's accepted asymmetry.

**K-48** — Three records are appended to `.harness/rejected-decisions.md`, each one concept with
decision, why and origin: (a) a bypass flag for the `K-15` / `K-16` refusal — declined (`OQ-7`);
(b) an `I.6` banned-phrase entry enforcing `B-17` — declined, measured in `F-8`; (c) a shared
`insight-parse.{sh,ps1}` module — declined per §M.1. **K-49** — release stamping is PM-owned and
moves as one set or `G.3` fails: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
both README version badges, and `CHANGELOG.md`; this design does not choose the version number.

**K-66 (`X-4` / `G-9`)** — `CONTEXT.md:95-111` is corrected in place, not reverted, and entered as
ledger row 28: `Entry-start line` drops the "so the three agree" clause and names its four consumers;
`Insight entry` drops the present-tense behavioural claim and states the definition only; and
`Closer block` is **replaced** by `Terminal footer` with
`_Avoid_: closer block, trailer, tail block, end matter`. Every remaining sentence is present-true
before this task ships; rollback is `git checkout` of the same file (`K-54`).

## J. Migration, rollout, distribution

**K-50** — No data migration, no feature flag, no state (`N-1`). **K-54** — rollback is
`git checkout` of the ledger's files; nothing stateful is created outside the repo, nothing deleted.

**K-51 (`N-4`)** — The harvester fix reaches new projects through the `templates/common/` overlay
(ledger 3, 4) and **already-generated** projects through `/harness-upgrade`, whose `refresh_set` names
both `archive-task` copies while excluding `verify_all` and refreshing no rule fragment (`F-6`), so the
template halves of ledger rows 25-27 reach new projects only; no `/harness-upgrade` change is made
here. `B-19` is what makes the un-refreshed on-disk index safe: `K-64` closes it inside the algorithm
`refresh_set` **does** carry.

**K-52** — Edit order, so no intermediate state is worse than HEAD: (1) `archive-task.sh` complete —
harvest, index read, header derivation, rotation clamp, `K-63` — as one change; (2)
`archive-task.ps1` mirrored; (3) `sync-self.sh` to promote both; (4) `verify_all.{sh,ps1}` `I.4`;
(5) the driver pair; (6) prose rows 16-18 and 23-28; (7) `baseline.json` from the captured run, last.
**K-53** — T-20's own stage-7 archive is the first live exercise of both paths at a full index: the
PM runs `archive-task --dry-run` first, compares the echoed lines against the `## Insight` section,
then runs it for real. `AC-12` keeps this task's own insights unwrapped until `AC-1` passes.

## K. Verification plan

**K-55** — `AC-1`…`AC-4` and `AC-13`…`AC-16` are discharged by the `K-34` rows that name them, owned
by the developer and re-run by QA, except `AC-3` and `AC-15`, which QA owns. The rest: **AC-5** a
captured `bash .harness/scripts/verify_all.sh` run plus a grep of every published `32` literal (QA);
**AC-6** a captured `bash .harness/scripts/sync-self.sh --check` run (developer); **AC-7** the `K-36`
mutation (QA); **AC-8** a post-archive entry count over the index plus a grep of the history file
(PM at stage 7); **AC-9** inspection of `baseline.json` `_qa_note_t20`, items 1-16 unread and
unmoved (gate); **AC-11** a diff of `.harness/insight-index.md` against its pre-task state, read per
line kind (QA); **AC-12** inspection of this task's stage docs (gate).

**K-56 (`AC-9`)** — The standing operator PowerShell list ends at **item 16** (`baseline.json`
`_qa_note_t16`, items 12-16; un-numbered T-13 / T-17 obligations in `_qa_note_t13` / `_qa_note_t17`).
This task adds exactly **one** item, numbered **17**, in a **new** `_qa_note_t20` key; no existing
item is renumbered, reconciled, re-read or edited. Item 17 covers, as one item: `[Parser]::ParseFile`
over both `archive-task.ps1` copies, `test-archive-task.ps1` and `verify_all.ps1`; a
`pwsh -File .harness/scripts/test-archive-task.ps1` run reproducing `AC-1`, `AC-2`, `AC-3` and
`AC-13` and reaching its summary block; `B-18`'s byte-identity comparison of the PowerShell index and
history output against the post-change **bash** output on the same fixture (LF-only, BOM-free); and
confirmation that no `$Is*` automatic is assigned and no binary `-join` sits unparenthesised beside
a `+`. Only then may a PowerShell tally be recorded, transcribed from that run.

## L. Known bounds — record-only, none blocking

**K-57** — `BC-7` is accepted and visible: a continuation line beginning with a `- ` marker becomes
its own entry, raising the reported entry count and `I.4`'s count identically. **K-58** — if the
index does not end with a newline the append path concatenates the first harvested line onto the last
stored line; pre-existing, not repaired, because normalising it would break `AC-4`'s floor.
**K-59** — `K-42`'s ASCII-vs-Unicode whitespace divergence between the twins. **K-60** — when
harvested entries alone exceed the cap, `BC-14` leaves the index above 30 entries and `I.4` WARNs:
the defense-in-depth arm, not a regression. **K-70** — in a **generated** project the cap check is
`F.4`, which counts physical lines (out-of-scope 11(a)), so `K-26`'s one-count property holds for the
dogfood `I.4` and not for `F.4` until the follow-up ships; `B-19` bounds this to "no new corruption".

## M. Out-of-scope clarifications

Beyond the eleven items in `01_REQUIREMENT_ANALYSIS.md`, this design does not cover: (1) extracting
`INSIGHT-SCAN` into a shared `insight-parse.{sh,ps1}` module — `verify_all` would then depend at gate
time on a mirrored script `E.1` checks, and a missing-module fallback is a second predicate
(`K-48c`; its cost is `K-67`'s second claim); (2) any edit to the six template `F.4` checks or to
`insight-index.md.tmpl` (out-of-scope 11; §H); (3) an `I.6` banned-phrase entry for `B-17` (`K-48b`);
(4) adding `archive-task` or `test-archive-task` to `F.1` or to `sync-self`'s mirror set (`K-30`);
(5) changing `verify_all`'s check count, any check id, or any published `32` literal; (6) repairing
`K-58`'s trailing-newline concatenation or `K-42`'s whitespace-class divergence; (7)
`docs/proposals/frontier-gaps-2026-07.md` — not read, cited, edited or committed in either round.

## N. Open-question dispositions

**OQ-1** blank line terminates an entry — adopted, pass B rule 2. **OQ-2** non-zero exit before any
mutation plus the `I.4` second layer — adopted, `K-14` / `K-15` / `K-26`, extended to the index by
`K-16`. **OQ-3** template cap repair — **withdrawn** by gate ruling: §H, out-of-scope 11(a) and the
follow-up row (ledger 21). **OQ-4** a new driver pair — adopted, §D.4; not mirrored, not in `F.1`
(`K-30`), one baseline key (`K-37`). **OQ-5** strip trailing, preserve leading — adopted, `K-4`.
**OQ-6** supersede rather than edit the partly-false insight line — adopted, ledger 22, written by
`archive-task` itself. **OQ-7** no bypass flag — adopted, `K-19`, recorded at `K-48a`.

## O. Partition assignment

Not applicable: single-Developer mode; `.harness/agents/dev-*.md` returned no matches.

## P. Verdict

`READY`. Every §F condition this stage owns is discharged: `X-2` by `K-26` / `K-61` / `K-67` (`G-2`)
and `K-7` / `K-64` (`G-3`); `X-3`'s design half by §H and `K-47`; `X-4` by `K-66` and ledger 28;
`X-5` by `K-34`'s `AC-13` / `AC-14` rows; `G-5`…`G-13` by §A. One upstream claim is contradicted
rather than absorbed (`K-67`): `G-2` does not dissolve; it is closed by design.
