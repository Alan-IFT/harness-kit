# 06 — Test Report — T-20 `harvest-wrapped-insight`

> Contract portion. Full command transcripts, the pre/post label-set derivation, the corpus walker
> source, the reference-parser source and the per-attack traces are in `06_RATIONALE.md`.

Mode: `full`. Human channel: deferred — nothing escalated, no `BLOCKED` condition raised.
**Round 2** (round 1 returned `CHANGES REQUIRED`, 1 MAJOR `QA-1` + 6 MINOR + 1 NIT). This document
is corrected in place to the current state of the tree; round-1 text that no longer holds has been
replaced, not annotated.

Identifiers: `QA-n` are defects, `AT-n` / `F-n` / `M-n` / `D-n` are adversarial reproducers. Every
figure below was produced by a run this stage executed on this host and transcribed from that run's
output; no figure is derived arithmetically (`L12`). **No PowerShell figure is reported** (`N-3`);
`pwsh` is absent.

Footprint: every reproducer ran in a `mktemp -d` sandbox under the QA scratch root with the script
under test copied in. `git status --porcelain` captured before and after the whole round-2 session is
**byte-identical** (99 lines both times, `diff` empty); `.harness/insight-index.md` sha256 is unmoved
(`03bfec098ef39318be394c5217022bbe77a4c35a979edb7fe511a2abc086a7ca`); `docs/features/_archived/`
still holds 42 entries and nothing under it was written; no `.tmp` residue. No shipped script was
modified. `docs/proposals/frontier-gaps-2026-07.md` was not opened.

## Reported figures, independently re-run

| claim | source of my figure | result |
|---|---|---|
| `test-archive-task.sh` **186 PASS / 0 FAIL** | `bash .harness/scripts/test-archive-task.sh`, run 3× | **confirmed 186 / 0**, exit 0; the three stdout captures are byte-identical (`cmp`) |
| anti-revert **84 PASS / 102 FAIL** | `git show HEAD:…/archive-task.sh` → scratch (sha256 `f43f549924cc…f281`, the developer's stated sha) → driver's `[archive-task-path]` arg | **confirmed 84 / 102**, exit 1 |
| the split is a partition of the same row set, not two totals | label sets, row by row: 186 post-PASS labels all unique; 84 pre-PASS + 102 pre-FAIL, all unique, `comm` **empty in both directions** against the post set; pre-PASS ∩ pre-FAIL **empty** | **corroborated at the artifact.** The developer's row-by-row claim holds |
| `CR-8` — count labels, not the header | `awk '/^Failures:/{f=1;next} f'` over the pre-change stderr | **102 label lines**, matching the summary. `CR-8` remains upheld |
| the developer's round decomposition (round 3: 29 rows, 12 green / 17 red; round 4: 5 rows, 2 green / 3 red) | label-level: 26 `QA-1` rows (9 pre-PASS / 17 pre-FAIL) + 5 `CR-13` tilde rows (2 pre-PASS / 3 pre-FAIL) | **corroborated**; 26 + 5 = the 31 the `_qa_note_t20` PS row-set figure names |
| `verify_all.sh` **32 / 0 / 0**, exit 0 | `bash .harness/scripts/verify_all.sh`, run 3× | **confirmed**, exit 0 all three times |
| check count 32 | counted **from the run**, not from `baseline.json`: `grep -cE '\.\.\. (PASS\|WARN\|FAIL)$'` | **confirmed 32** on each of the three runs |
| `sync-self.sh --check` in sync, mirrors `cmp`-identical | captured run, exit 0; plus `cmp` of both mirror pairs | **confirmed** — `In sync.`, and `archive-task.sh` / `archive-task.ps1` both IDENTICAL to their `skills/harness-init/templates/common/` mirrors |
| AC-15 corpus **41 / 34 clean / 0 dirty / 3 footer** | **my own** corpus walker (`06_RATIONALE.md` §2), unchanged from round 1, not the developer's driver | **confirmed**: 41 archived `07_DELIVERY.md` on disk; `matching_sections=34 clean=34 dirty=0 footer_bearing=3 no_heading=7`; the same 3 footer sections named |
| `baseline.json` `test_archive_task_bash_assertions` = **186** | read from the file, compared against my own captured run | **confirmed**; the key equals the figure the run printed |

`CR-7` honoured: `AC-3` leg (i) is read as *PASS + two counts*, never as a measured equality.

## Test plan

| Acceptance criterion | Independent reproducer | Outcome |
|---|---|---|
| AC-1 | `AT-12`, `D-E` — wrapped bullets, evidence pointers, 2- and 4-space indents | **PASS** — all lines, both pointers, leading whitespace byte-preserved |
| AC-2 | `AT-18` — unaccounted line with rotation pending (30-entry index) | **PASS** — exit 3, index byte- and mtime-identical, no history, no move, no `.tmp` |
| AC-3 | `AT-29` — 5 index fixtures; reported `entries after run` vs `I.4` over the produced file | **4/5 PASS, 1 DISAGREE** — unchanged, `QA-2` |
| AC-4 | driver against the git-extracted pre-change script; plus `b11.sh` and `M-1`…`M-5` pre/post `cmp` | **PASS at 84/102**, and **`QA-1`'s counterexample is gone** — see below |
| AC-5 | `verify_all` ×3 + check-count recount from the run | **PASS** 32/0/0, exit 0 |
| AC-6 | `sync-self.sh --check` + `cmp` of both mirrors | **PASS** |
| AC-7 | `AT-28` — insertion-only mutation of a **copy** of the live index, `I.4` from a real `verify_all` run | **PASS**, non-vacuous: `PASS → WARN → PASS` |
| AC-8 | PM, stage 7 — the round-1 prediction is **retired**, see the delivery answer below | ✅ hazard closed |
| AC-11 | `git show HEAD:` vs working tree, read per line kind | **PASS** — unchanged from round 1 |
| AC-13 | `AT-22` — break-then-entry, delivery | **PASS** — exit 3, `:7: unaccounted line: ---` |
| AC-14 | `AT-16`-shape + `I.4` | **PASS** — exit 3, index byte-identical, `I.4` WARN |
| AC-15 | my own corpus walker | **PASS** — 34/34 clean, 0 dirty, 3 footer-bearing |
| AC-16 | `AT-24` shapes A/B/C/D + `AT-15` | **PASS** on the shipped shape; `QA-4` unchanged |
| B-7/B-8/B-10 | `AT-13`, `AT-34` | **PASS** — rotates whole, no orphan, no reorder, header first and verbatim |
| **B-11** | **`b11.sh` (`AT-5`), `M-1`…`M-5`, `adv1` vs `adv1pre`** | **PASS — the round-1 failure is closed.** Pre and post now produce byte-identical indexes on the multi-section fixture and on five further multi-section shapes |
| B-12 | `AT-21` | **PASS** — dry-run writes nothing, same tallies, same status |
| B-13/B-18 | not run — `pwsh` absent | green-by-symmetry; operator item 17. I read `archive-task.ps1:284-334` and confirm the fence walk is structurally the twin of `archive-task.sh:253-293`; see `QA-11` for the two engine divergences I could read but not execute |
| BC-8/BC-9 | `AT-10`, `F-20` | **PASS** — CRLF stripped before section discovery, so a CRLF document's fences and headings are read correctly; tab separator honoured; LF-only output |
| BC-14 | `AT-19` | **PASS** — no unbound-variable abort, all 3 stored rotated |
| BC-19 | `AT-31` | **PASS** — `Delivery document not readable`, exit 1, nothing moved |

## Boundary tests added

None to the shipped suite. `test-archive-task.sh` is a shipped script and this stage was instructed
to modify none. The 20 new round-2 reproducers (`F-1`…`F-20`, `M-1`…`M-6`, `D-A`…`D-F`, plus the
differential fuzz) live in `06_RATIONALE.md` §9 with their exact fixtures and their sources in the QA
scratch root; the one driver-row gap they expose is named under `QA-9`.

## Adversarial tests

Round 2's mandate was to **break the new state machine**, which is the third section-discovery
implementation this task has shipped and the first two each shipped a defect a later stage found. 32
reproducers, all written by me from the contract and from CommonMark, **none** copied from
`04_DEVELOPMENT.md` or `test-archive-task.sh`. One hypothesis per row, written before the run.
Traces in `06_RATIONALE.md`.

### Round-1 defect re-verification (the three the brief named)

| # | Hypothesis ("I expect it to still fail when…") | Reproducer | Outcome |
|---|---|---|---|
| `AT-5` | a delivery doc has a **second** `## Insight` section | `qa-t20/b11.sh`, **my round-1 script re-run unmodified** (its `POST` is hard-coded to the live path) | **SURVIVED — `QA-1` CLOSED.** `RESULT: byte-identical (B-11 holds on this fixture)`. Round 1 printed `*** DIFFER *** … 8d7 < - harvested entry B` |
| `AT-9` | a `## Insight` inside a fenced block precedes the real one | `qa-t20/adv1.sh` re-run, diffed against the round-1 capture | **SURVIVED.** The only deltas in the whole 7 kB capture are the two `QA-1` rows flipping: the real insight now reaches the index, the documentation bullet and the bare ` ``` ` no longer do, and `Quoted headings: 1 …` is printed |
| **`L-2`** | **the live stage-7 shape with a fenced `## Insight` quoted first** | `qa-t20/live.sh` re-run against a **copy of the real 30-entry index** | **SURVIVED — the delivery hazard is closed.** `Harvested 2 … entries 2 … RC=0`, `REAL INSIGHT lines that reached the index: 2`. Round 1 read `0` |
| `L-1` | the well-formed stage-7 shape regressed | `qa-t20/live.sh` | **held** — rotate 4, header `:1-8` byte-identical, 4 continuation lines land, `I.4` PASS |

### Attacks on the new fence state machine

| # | Hypothesis ("I expect failure when…") | Reproducer | Outcome |
|---|---|---|---|
| `F-1` | a **tilde** fence hides a heading | `fence.sh` | **held** — 1 real entry, `Quoted headings: 1`, no doc example, exit 0 |
| `F-2` | opener ```` ```` ````, "closer" ` ``` ` (shorter) is accepted as a closer | `fence.sh` | **held** — CommonMark-correct: not a closer, fence open at EOF, **exit 3**, nothing written, dir not moved, both swallowed headings counted |
| `F-3` | opener ` ``` `, closer ```` ```` ```` (longer) is rejected | `fence.sh` | **held** — accepted as a closer, real entry harvested |
| `F-4` | a closer carrying an info string closes the fence | `fence.sh` | **held** — not a closer, exit 3 |
| `F-5` | a backtick opener whose info string holds a backtick opens a fence | `fence.sh` | **held** — CommonMark-correct: declines to open, so the following `## Insight` is a **real** heading; the resulting odd fence count is caught at exit 3. See `QA-12` for the diagnostic's line number |
| `F-6` | a ` ``` ` run closes an enclosing `~~~` fence | `fence.sh` | **held** — does not close it |
| `F-7a/b` | indent handling is wrong at the 3/4-space boundary | `fence.sh` | **held** — 3 spaces is a fence, 4 spaces is not, matching CommonMark |
| `F-8` | a fence inside a blockquote is treated as a fence | `fence.sh` | **held** — not a fence; the blockquoted bullet is not entry-shaped and reaches nothing |
| `F-16` | a TAB-indented fence diverges | `fence.sh` | **held functionally** — `[[:space:]]` accepts the tab so it is a fence; CommonMark would call it indented code. Both twins agree; record-only |
| `F-20` | a CRLF delivery document breaks fence or heading matching | `fence.sh` follow-up | **held** — `normalise_lines` runs *before* discovery, so CRLF fences, a trailing-space closer and the heading all match; index stays LF-only |
| `F-9` | the unterminated-fence refusal is over-broad | `fence.sh` — fence is the **last line**, after the whole Insight section, hiding nothing | **CONFIRMED OVER-BROAD** — exit 3 although the real entry was correctly harvested. **Errs loud**: nothing written, dir not moved, opening line named. `QA-10` |
| `F-10` | …even with no `## Insight` section at all | `fence.sh` | **CONFIRMED** — a document with zero insights and one unbalanced fence cannot be archived at all. Loud. `QA-10` |
| `F-11` | a whole `## Insight` section inside a fence is lost **silently** | `fence.sh` | **held as a *reported* bound** — 0 entries, exit 0, task archived, but `Quoted headings: 1 …` is printed. This is the developer's disclosed bound, and the report line is what makes it one |
| `F-12` | a fence hiding a `## Notes` **terminator** inside an open section loses content | `fence.sh` | **held** — exit 3, both hidden lines named. The uncounted terminator skip is therefore not a loss channel |
| `F-13`/`F-17`/`F-18`/`F-19` | a fence **inside** the section is mis-scanned | `fence.sh`, `fence2.sh` (both scripts) | **GOT THROUGH** — a **bullet inside the fence becomes a real index entry** and the fence markers are written into the index, exit 0, `unaccounted lines 0`, no `Quoted headings:`. Pre-change harvested the bullet too but wrote no fence marker. `QA-9` |
| `F-14`/`F-15` | `CR-12`'s two shapes do not actually refuse | `fence.sh` | **held** — fence after a blank line inside the section → exit 3; fence containing a column-0 `##` inside the section → exit 3, both lines named |
| `M-1`…`M-5` | multi-section arithmetic mis-tallies | `fence2.sh`, each run against **both** scripts | **held** — 3 sections (4 entries), adjacent headings, a heading as the last line of the file, an empty section between two real ones: every one exits 0 with the correct entries **and is byte-identical to the pre-change script** |
| `M-4` | a terminal footer in section 1 leaks into section 2 | `fence2.sh` | **held** — `terminal footer 4` charged to section 1 only; section 2's entry harvested normally |
| `M-6` | an unaccounted line in section 2 alone does not refuse | `fence2.sh` | **held** — exit 3 naming `:10`, nothing written. Pre-change exits 0 here; this is new coverage |
| `AT-F` | **the loss channel `Quoted headings:` exists to close is still open somewhere** | `fuzz2.sh` — randomized differential fuzz against `ref.py`, an **independent** CommonMark + contract reference parser I wrote; 4 seeds | **held.** `P1` no-loss, `P2` no-silence, `P3` unterminated-refuses: **0 violations in every seed** (338 / 279 / 279 / 285 documents carrying ≥1 real bullet). It did reproduce `QA-9` at 10 / 6 / 15 / 6 exit-0 runs per seed |

### Standing residuals — re-run to confirm the rewrite neither closed nor worsened them

`adv1`…`adv4` were re-executed and diffed against their round-1 captures. `adv3` and `adv4` are
**byte-identical**; `adv2` differs only in an mtime literal and one line number in a
`Permission denied` message; `adv1` differs **only** in the two `QA-1` rows above.

| # | residual | Outcome |
|---|---|---|
| `AT-17`/`AT-29` | `QA-2` — false `entries after run` on a no-final-newline index | **unchanged**: `entries 5 … after run 6` over a file holding 5; fixture 5 still `*** DISAGREE ***` |
| `AT-14` | `QA-3` — blank lines dropped by a rewrite | **unchanged**: 62 → 32 lines, no content lost |
| `AT-15`/`AT-24B` | `QA-4` — balanced comment absorbs stored entries | **unchanged**: raw 32, `entries 30`, `I.4` PASS |
| `AT-3`/`AT-23` | `QA-5` — terminal-footer smuggling | **unchanged**: content after a break discarded at exit 0 |
| `AT-4` | `QA-6` — `*`/numbered section discarded whole | **unchanged**: `entries 0 … unaccounted lines 0`, exit 0 |
| `AT-20` | `QA-7` — rotation is not transactional | **unchanged**: history gains the entry, index rewrite fails, retry duplicates |
| `AT-32` | `QA-8` — `--task ../../victim` accepted | **unchanged**, byte-identical to round 1 |

## Defects found

**`QA-1` — [MAJOR, round 1] — CLOSED.** Verified at the artifact by three independent routes: my
unmodified round-1 `b11.sh` now prints `byte-identical`; `adv1`'s `AT-5` and `AT-9` rows both flip;
and `L-2` against a copy of the live index recovers both real insights. `M-1`…`M-5` extend the
pre/post equality to five further multi-section shapes, and 17 of the 26 `QA-1` driver rows plus 3
of the 5 `CR-13` rows are red against the pre-change script, so the coverage is anti-revert rather
than self-consistent. **No routing item remains from round 1.**

**`QA-9` — [MINOR] A fenced code block *inside* the `## Insight` section that contains a bullet
turns that bullet into a real index entry and writes the fence markers into
`.harness/insight-index.md`, at exit 0 with `unaccounted lines 0` and no `Quoted headings:` line.**
Section discovery is fence-aware; `insight_scan` is not, and the two are only reconciled at the
section *boundary*. Inside a section (`archive-task.sh:143-167`) a fence marker is classified `I`
when no entry has been seen yet (`:150`) or `C` when one has (`:161`), and `RE_ENTRY` (`:146`) is
tested before anything else — so a bullet inside a fence is always `E`.
*Reproducers* (`06_RATIONALE.md` §9): `F-13`/`F-18`/`F-19` (fence before the first bullet),
`F-17`/`D-D` (fence directly under an entry). `D-D`, driven against a copy of the **live 30-entry
index**, is the sharp one:

```
Insight tally: entries 3, continuation lines 2, ignorable lines 1 (terminal footer 0), unaccounted lines 0
Rotating 3 old insight entry(ies) to insight-history.md          rc=0
REAL insights that reached the index : 2      fence markers in the index : 2
doc-example bullets in the index    : 1       archived? YES
```
Three consequences: a documentation bullet becomes a permanent insight; ` ``` ` / `~~~` lines become
permanent index content and later rotate into `insight-history.md`; and the inflated count evicts
**one more genuine stored insight** than the document warranted (`Rotating 3`, not 2).
*Bounds.* This is **not** silent content **loss** — nothing authored is discarded, `AC-11`'s rotation
property still holds, and the pre-change script harvested the same fenced bullet, so the entry set is
not a `B-11` regression. What is new is the fence-marker lines. It is also **discontinuous**: the
identical example refuses at exit 3 if it follows a blank line (`F-14`/`D-C`) and pollutes silently
if it directly follows an entry (`F-17`/`D-D`).
*Coverage gap.* The driver's `qa1d` row (`test-archive-task.sh:990-1013`) pins only a fenced body
holding **no** bullet, and its comment (`:986-989`) says fenced lines "are absorbed as continuation
lines of the preceding entry" — accurate for `{"a": 1}`, inaccurate for `- anything`. One driver row
with a bullet in the fenced body, and a one-sentence correction to that comment, would close it.
Record-only; **not** routed, because it neither loses content nor regresses `B-11`.

**`QA-10` — [MINOR, confirms `CR-14`] The unterminated-fence refusal is over-broad by construction,
and the over-broad class is non-empty and reachable.** Two reproducers where the open fence provably
hides nothing: `F-9`, where the fence is the **last line** of the document and the whole `## Insight`
section was already correctly harvested (`Harvested 1 insight entry(ies)` then exit 3); and `F-10`,
where the document has **no `## Insight` section at all** and still cannot be archived. On the
randomized fuzz the refusal fired on 253 / 338, 222 / 279, 210 / 279 and 229 / 285 documents — the
class is large. **It errs loud in every instance measured**: exit 3, index byte-identical, task
directory not moved, opening line named with its 1-based number. That is the right direction for a
refusal, and `CR-14`'s ruling stands as stated; recorded so the bound is measured, not assumed.

**`QA-11` — [NIT, pre-existing] Two `archive-task.ps1` / `archive-task.sh` engine divergences I can
read but not execute.** (a) PowerShell's `-match` is **case-insensitive**, so `$atLine -match
$atReSectionHead` opens a section on `## INSIGHT` or `## insight` where bash's `[[ =~ ]]` does not —
the same document harvests on Windows and silently harvests nothing on Linux. This is **not new**:
`git show HEAD:.harness/scripts/archive-task.ps1:49` used `-match` with the same pattern. (b) .NET
`\s` matches Unicode spaces (NBSP among them) where glibc `[[:space:]]` does not, so an
NBSP-indented fence is a fence only in the PowerShell twin. Both belong to operator item 17's
sweep, not to this task.

**`QA-12` — [NIT] The unterminated-fence diagnostic can name the wrong line.** In `F-5` the authoring
error is at `:3` (a backtick opener whose info string holds a backtick, correctly declined), but the
run reports `:6: unterminated code fence opened here:` — the *next* fence marker, which is where the
state machine genuinely opened. Correct by construction, misleading to an author. Record-only.

**`QA-2`, `QA-3`, `QA-4`, `QA-5`, `QA-6`, `QA-7`, `QA-8`** — all re-run, all **unchanged**; see the
residuals table. They remain record-only, pre-existing, or one-sentence prose corrections.

No BLOCKER, no CRITICAL, no MAJOR. `QA-9`…`QA-12` are new this round and none is a routing item.

## verify_all result

- Total tests: `test_archive_task_bash_assertions` 152 (round 1) → **186**, transcribed from my own run
- `verify_all`: PASS **32** / WARN **0** / FAIL **0**, exit **0** (3 identical runs)
- check count: **32**, counted from the run, unchanged
- `test-archive-task.sh`: **186 PASS / 0 FAIL**, exit 0 (3 runs, byte-identical stdout); **84 PASS /
  102 FAIL** against the git-extracted pre-change script, exit 1, label sets verified to partition
  the same 186 rows with `comm` empty in both directions
- New tests added by QA to the shipped suite: **0** (see *Boundary tests added*); 32 QA-owned
  reproducers and one randomized differential fuzz live in the scratch root
- Baseline updated: **no — and none is needed.** `test_archive_task_bash_assertions` already reads
  **186**, which is exactly the figure my own run printed. The `AC-15` corpus floors (`>= 34`,
  `>= 3`) are re-measured at exactly 34 and 3 and **must not** be raised when this task's own archive
  takes the corpus to 35

## Stability

- `test-archive-task.sh` ×3 → `PASS: 186 / FAIL: 0` every time; the three stdout captures are
  `cmp`-identical. No flake.
- `verify_all.sh` ×3 → `PASS: 32 / WARN: 0 / FAIL: 0`, exit 0 every time. No flake.
- `fence.sh` (the 16-case F-series) ×2 → identical modulo sandbox paths. No flake.
- Randomized fuzz over 4 seeds, 1181 documents in total across the four captured runs, 0 violations
  of all three properties in each. No flake.
- `git status --porcelain` identical before and after the whole session (99 lines, `diff` empty);
  index sha unmoved; `_archived/` still 42 entries. No footprint.

## Verdict

**APPROVED FOR DELIVERY** (0 BLOCKER, 0 CRITICAL, 0 MAJOR; 4 new MINOR/NIT record-only, 7 standing
residuals unchanged)

`QA-1` is genuinely closed, confirmed at the artifact by my own unmodified round-1 reproducer rather
than from the round record. The rewrite is not merely a patch over the `break`: on 1181 randomly
generated documents the implementation never once discarded a real insight at exit 0 without saying
so, never once failed to refuse an unterminated fence, and never once skipped a `## Insight` heading
without printing `Quoted headings:` — measured against a reference parser I wrote independently from
CommonMark and the contract. Multi-section arithmetic is byte-identical to the pre-change script on
every shape I could construct, so `B-11`'s floor is restored rather than merely asserted. All six
reported figures are confirmed from the artifacts that produced them, and the 84/102 split is
corroborated at the label level in both directions.

The two costs are disclosed and both point the safe way. The unterminated-fence refusal is
over-broad (`QA-10`) but refuses loudly and writes nothing. A fenced block *inside* the `## Insight`
section is still not understood by the entry scanner (`QA-9`) and either refuses or quietly adds a
manufactured entry — a bound worth one driver row and one corrected comment in a follow-up, not a
reason to hold delivery.

## Delivery answer for stage 7

**The round-1 hazard is closed.** Re-run against the fixed script, `L-2` — a delivery document that
quotes a `## Insight` heading inside a fenced block *before* the real section, driven against a copy
of the real 30-entry index — now harvests both real insights, writes no documentation bullet and no
fence marker, and prints `Quoted headings: 1 …`. Round 1's `REAL INSIGHT lines that reached the
index: 0` is now `2`.

**The developer's mitigation is sufficient but not necessary.** Measured on `D-A`…`D-F` against a
copy of the live index:

| shape | result |
|---|---|
| fenced example **above** the `## Insight` heading | **SAFE** — 2/2 real insights, 0 fence markers, 0 doc bullets, exit 0 |
| fenced example **below**, under a later `##` heading | **SAFE** — identical result. "Keep it above" is therefore not required |
| `` `## Insight` `` mentioned **inline** in prose | **SAFE** — inline backticks are not a fence |
| fenced example **inside** the section, after a blank line | **REFUSES**, exit 3, nothing written, task not archived |
| fenced example **inside** the section, directly under an entry | **UNSAFE and silent** — exit 0, a doc bullet becomes an insight, 2 fence markers land in the index, and one extra genuine entry is rotated out (`QA-9`) |

The rule your delivery document must follow is therefore **"no fenced code block anywhere inside the
`## Insight` section"** — above the heading or below it under a different `##` heading are both fine —
plus **every fence in the document must be balanced**, since one unterminated fence anywhere refuses
the whole archive at exit 3 (`QA-10`). `K-53`'s `--dry-run`-then-compare remains worth running, but
it is no longer the only thing standing between this task and losing its own insights.
