# 05 — Code Review Rationale — T-20 `harvest-wrapped-insight`

> Rationale portion of `05_CODE_REVIEW.md`. Read on a named trigger: a disputed severity, a disputed
> tally, or a re-derivation of one of the traces below. Round-4 state. Round 3's derivations that
> round 4 superseded (the 181-row recount, the 12/17 split derivation, the round-3 fence census table)
> are retired — the census is now carried by `04_RATIONALE.md:190-228`, which reproduces it
> independently, and the row counts are re-derived from zero in §1.

## 1. The 186-row recount, from zero (`L12`)

Round 3 recounted 152 + 29 by carrying round 2's 152 as given. This round recounts the whole file, so
the result independently checks 181 and 152 as well.

One assertion-helper call that *fires* = one row. Helpers: `ok`, `no`, `eq`, `has`, `hasnot`,
`files_eq` (`test-archive-task.sh:51-58`).

| term | value | derivation |
|---|---|---|
| line-start call sites | **187** | `eq` 93 + `has` 49 + `hasnot` 10 + `files_eq` 20 + `ok`/`no` 15 |
| − multi-line `if/else` pairs | **−7** | `:186/188` (AC-2), `:246/248` (AC-13), `:385/387` and `:391/393` (AC-15), `:525/527` (BC-12), `:742/744` (BC-23), `:1073/1075` (AC-4 extraction) — 2 sites, 1 row each |
| + `AC-4` leg loop | **+2** | `for legname in append rotation` at `:1090-1109` holds 4 sites (`:1100`, `:1101`, `:1104`, `:1107`) and fires **3 rows per iteration × 2** = 6 |
| + one-line `if … then ok; else no` | **+4** | `:250` (AC-13 task dir), `:606` (K-16 task dir), `:717` (B-12 dry-run), `:822` (BC-10 index created) — these start with `if`, so they are invisible to a line-start count and are the term a naive recount drops |
| **total** | **186** | matches `baseline.json:24` |

`AC-4` is 10 rows (1 extraction + 2 legs × 3 + 3 multi-section), matching the transcript at
`04_RATIONALE.md:143-155` row for row. `BC-19` (`:804-805`, 2 rows) fires except as root; the captured
run was uid 1000, stated in `_qa_note_t20`. 186 − 5 (`CR-13`) = **181** and 181 − 29 = **152**, so
this recount corroborates all three round figures rather than only the current one.

## 2. `qa1f` traced against `archive-task.sh:255-293`

Fixture, 0-based after `mapfile`: line `4` is a tilde-run opener whose info string contains a
backtick; `5` is `## Insight`; `7` the documentation bullet; `9` and `11` are backtick runs; `12` is
the tilde closer; `14` is `## Insight`; `16` the real bullet; `18` is `## Verdict`.

| i | branch taken | state after |
|---|---|---|
| 4 | `RE_FENCE` matches; `fence_char` empty; `:261` — the marker's first character is a tilde, **first disjunct true**, so the info string is never consulted | fence tilde, len 3, at 4 — **unrestricted-info path** |
| 5 | inside fence → `:275` `RE_SECTION_HEAD` matches | `h_quoted = 1` |
| 9, 11 | `RE_FENCE` matches; `:264` character test backtick ≠ tilde → **not a closer**; `continue` | state intact — **mismatched-closer path** |
| 12 | `:264-266` — same char, len 3 ≥ 3, info blank → closes | fence cleared — **tilde-closer path** |
| 14 | `:278` opens a section | `cur_lo = 15` |
| 18 | `RE_SECTION_END` with `cur_lo ≥ 0` → `:282-283` | `SEC = [15,17]` |

`fence_at = -1` at EOF, so `:290-293` does not fire. `insight_scan section 15 17`: blank `I`, entry
`E`, blank `I` → `entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted
lines 0`; `h_quoted = 1` prints at `:348-350`; 1 stored + 1 harvested ≤ 30 → append; exit 0.
**All five asserted values reproduce exactly.**

Each path is discriminating, which is what `CR-13` actually asked for: collapse the `:261` disjunct
(apply the backtick restriction to both branches) and the opener does not open, the heading at 5
becomes the section and the tally reads `entries 2`; drop the character test at `:264` and line 9
closes the fence, so line 14 misparses and the quoted bullet reaches the index; break the closer and
the fence is open at EOF and the run refuses at exit 3.

Anti-revert derivation against the pre-change awk (flag armed on a matching heading, cleared on any
other `##` heading, bullet lines emitted while armed): it is fence-blind, so line 5 arms the flag and
line 7 is harvested; line 14 re-arms and line 16 is harvested; line 18 disarms. It exits 0 and writes
both bullets. Therefore **row 1 green** (exit 0), **row 3 green** (real bullet present), **row 2 red**
(no tally line), **row 4 red** (documentation bullet present), **row 5 red** (no `Quoted headings:`
line) — **2 green / 3 red**, agreeing with the capture on every row *and* on the reason.
82 + 2 = 84, 99 + 3 = 102, 84 + 102 = 186.

## 3. The two new bound transcripts, re-derived by hand

Both reproduce exactly, which corroborates the captured figures without a run.

**Bound 2a** — entry, blank, then a 3-line fence, then `## Verdict`. Discovery opens and closes the
fence, so the section is unbroken and the fence lines stay inside it. Pass B: the blank at `:143-145`
clears `in_entry`; the three fence lines are not blank, not entries, not `RE_HEADING`, and
`seen_entry == 1` so the `:150` preamble clause does not catch them → they fall to `:167` → `U`.
Result `entries 1, continuation 0, ignorable 3, unaccounted 3`, exit 3, three named lines. **Matches
`04_RATIONALE.md:274-281`.**

**Bound 2b** — entry, then an abutting fence whose body is a column-0 `## Insight`, then `## Verdict`.
Discovery: the fence opens, the quoted heading is inside it so it is neither opener nor terminator and
increments `h_quoted`, the fence closes, `## Verdict` terminates. Pass B: the opening fence line
abuts the entry so `in_entry == 1` → `C`; the quoted heading matches `RE_HEADING` at `:158-160` → `U`,
clearing `in_entry`; the closing fence line then has no open entry → `U`. Result `entries 1,
continuation 1, ignorable 2, unaccounted 2` plus `Quoted headings: 1`. **Matches `04_RATIONALE.md:288-295`.**

The two together are the general statement `K-71` now carries: **adjacency to the entry, not
fencedness, decides between absorption and refusal** — which is exactly what `CR-12` said the round-3
bounds hid.

## 4. `K-71` against the code, clause by clause

The direction that drifts most easily is design catching up to code, so every clause was mapped.

| `K-71` clause | shipped site | verdict |
|---|---|---|
| one walk of the whole document; no first-heading search | `:255-285` | ✅ |
| every eligible `^##[[:space:]]+Insights?[[:space:]]*$` opens a section | `:62`, `:278` | ✅ |
| every section scanned, counts accumulated in document order | `:294-305` | ✅ |
| ineligible while inside a CommonMark fence: ≥3 backticks or tildes at indent ≤3 | `:67`, `:257` | ✅ |
| closed only by the same character, at least as long, nothing after it | `:264-266` | ✅ |
| a heading inside a fence is neither opener nor terminator | `:270-277` skips before `:278` and `:282` | ✅ |
| fence state tracked **once**, governing opener and terminator together | one `fence_char`, read at `:270` before both | ✅ — and this is the clause that matters: tracking one alone cuts a live section short |
| open at EOF → reported, refuses via the existing `unaccounted > 0` machinery, no new arm | `:290-293` → `:336` → `:353-357` | ✅ |
| every quoted heading counted and **printed**, on every terminating path | `:275`, `:348-350` — above the `:353` refusal block | ✅ verified, not assumed |
| pass B unchanged: fenced line is continuation when an entry is open, unaccounted otherwise, never ignorable | `:161-167`; `K-62` at `:182` keeps pass C from demoting | ✅ |
| mode `index` carries no fence state, deliberately | `insight_scan` has no fence variable | ✅ |

The PS twin is statement-for-statement parallel at `:288-334` with no divergence; the only
engine-level difference is the pre-existing `\s` vs `[[:space:]]` class, declared in both matcher
registers and recorded as a NIT since round 3.

One gap, recorded as a NIT rather than a finding: `K-71` spells out the opener and closer clauses but
leaves the backtick-info restriction (`:261`) to the emphasised word **CommonMark**. That is the one
clause where the two branches differ and the one `CR-13` found untested — correct by reference, worth
a half-sentence only if `02` is reopened for another reason.

## 5. Why `CR-9` closed rather than partially closed

The test applied was not "did the three cited sites change" but "**is any superseded figure readable
as current anywhere in the stage-4 pair or the baseline note**". Sweeping `152`, `181`, `70/82`,
`82/99` and bare `70`/`99` across all three artifacts returns nine sites, and every one is inside a
round-history table, a `State: round 4` preamble, an explicit SUPERSEDED clause, or an
`evidence: T-20 dev round 2` insight tag. The one that mattered most is `_qa_note_t20`, because the
baseline note is what an operator reads years later with no pipeline around it: it now carries the
round marker **inline**, in the same sentence, rather than ~600 words above the correction.

That is the shape `baseline.json:27`'s `_qa_note_t13` records the repo already paying for once, and it
is why the severity was MAJOR rather than MINOR in round 3 — a judgement the developer did not
contest and the PM did not soften. Recorded here because the calibration is the reusable part: a wrong
figure in a routing log is MINOR when the owning stage's own documents are right; the same figure in
the owning stage's own document, unmarked, is MAJOR, because nothing in the record flags it.
