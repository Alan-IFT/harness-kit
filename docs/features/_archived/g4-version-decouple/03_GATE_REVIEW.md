# 03 — Gate Review · g4-version-decouple (T-010)

> Stage 3. Verdict vocabulary: APPROVED FOR DEVELOPMENT / CHANGES REQUIRED / REJECTED. Upstream 01=READY, 02=READY. Read-only; every load-bearing claim verified against live code. Persisted by PM (GR read-only).

## 1. Audit checklist (all PASS)
| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | AC-1..AC-5 each have a concrete oracle (read-line/mutation/fixture/grep/both-shells). |
| 2 | Design completeness | PASS | §5 gives exact new shape+expect for all 6 rows BOTH shells; §6 exact new prose; §7 what stays byte-identical. No decision left to dev. |
| 3 | Reuse correctness | PASS | `$report.Count+1` tally, CHANGELOG `[$version]` check, extract_json_version/ConvertFrom-Json, tripwire all exist as cited + correctly classified. |
| 4 | Risk coverage | PASS | R-1 (loose→AC-2), R-2 (false-match), R-3 (asymmetry), R-4 (leftover 7th), R-5 (dead-code), R-6 (tally), R-7 (row-4 paren) cover the real risks. |
| 5 | Migration safety | PASS | No data migration; partial revert safe (count gating never removed); no templates/**/verify_all (fan-out non-issue). |
| 6 | Boundary handling | PASS | partial-removal grep, shape-still-matches, count-stays-32, CHANGELOG-absent FAIL branch, missing-claim-file branch all covered. |
| 7 | Test feasibility | PASS | QA a/b/c/d map 1:1 to AC-2/3/4/5+1 with exact mutation values + expected FAIL strings. |
| 8 | Out-of-scope clarity | PASS | G.3 stamps, CHANGELOG heading, count value, row additions, rows 6-9/11, history/HTML all fenced off. |

## 2. Crux adjudication
**AC-2 (count drift still FAILs) — VERIFIED all 6 rows both shells.** Each new `expect` keeps count `32` + a count-adjacent discriminator; a `32→31` doc drift → `.Contains()`/`==*..*` false → FAIL:
| Row | File | new expect | 32→31 |
|---|---|---|---|
| 1 | AI-GUIDE:36 | `32/32` | FAIL |
| 2 | AI-GUIDE:69 | `32 checks` | FAIL |
| 3 | dev-map:60 | `32 checks` | FAIL |
| 4 | dev-map:133 | `runs all 32 checks` | FAIL |
| 5 | 40-locations:25 | `(32 checks` | FAIL |
| 10 | manual-e2e:3 | `32 checks` | FAIL |
None degrades to a count-less loose match. T-008's count↔tally coupling intact.

**No historical/HTML false-match — VERIFIED.** Match order confirmed in live code: PS:666 `if ($raw.Contains($c.expect)) { continue }` runs BEFORE the shape ERE at :667; sh:732 `[[ == *"$g4_expect"* ]] && continue` before grep at :733. Independently grepped all `*.html` + CHANGELOG for the new literals (`32/32`, `32 checks`, `(32 checks`, `runs all 32 checks`, `（32 项检查）`, `32%2F32`) → zero HTML hits, zero count-only CHANGELOG hits (history carries OLD values 19/26/30/31 and/or `at vX`). No vacuous pass.

**Exhaustiveness (AC-4) — VERIFIED set closed at 6.** Own greps (`checks? at v`, `\d/\d+ at v`, `项检查…v`, `at v0.21.1`, `%2F` badge) → exactly the 6 edited claims, no 7th live claim with a version token. All other `at v0.21.1` = CHANGELOG history / HTML snapshots / `docs/features/**` stage docs. Must re-run §8 grep post-edit → zero (QA test c).

**Row-4 paren (R-7) — VERIFIED.** dev-map:133 live `runs all 32 checks (at v0.21.1) including …`; design removes the WHOLE ` (at v0.21.1)` parenthetical, collapse to one space → `runs all 32 checks including …`; new expect/shape match cleanly, no orphan `()`/double-space.

**`$version` not dead / CHANGELOG retained — VERIFIED.** `$version` (PS:639) / `g4_version` (sh:670) + the `-not`/`-z` guard kept because the CHANGELOG `[$version]` check (PS:676, sh:742) still consumes it. Rows 6-9,11 (badges/`(32 checks)`/`（32 项检查）`/baseline `"verify_all_checks": 32`) + tripwire byte-identical.

**Tally integrity — VERIFIED.** No Step/step added/removed/reordered; edits inside the existing `$claims`/`g4_shapes`+`g4_expects` arrays; `$report.Count+1`=32; G.4 still last; 11 rows.

**PS/Bash symmetry (R-3) — VERIFIED.** §5.2 PS / §5.3 sh mirror the same 6 logical rows (PS idx 1-5,10 / sh 0-based 0-4,9), count-only matching identical. QA test (d) diffs both.

**Net strictly-better (D4) — VERIFIED.** Stamps→G.3; CHANGELOG entry→G.4 (still reads `$version`); only the redundant prose `at vX` deleted, and the count it sat next to stays gated against the live tally. The v0.21.2 bump turning green without touching the 6 prose claims is the AC-3 self-proof.

## 3. Findings
NONE. No WARN, no FAIL across all 8 dimensions + 8 dispatch questions.

## 4. Verdict
The crux (would any count-only row stop catching a 32→31 drift?) is NO for all 6 rows in both shells — every new `expect` retains the count + a discriminator. No false-match (short-circuit ordering verified in live code + independent grep). Exhaustiveness independently confirmed (6, no 7th). Row-4 paren, `$version` retention, tally, symmetry, strictly-better all verified.

**GATE VERDICT: APPROVED FOR DEVELOPMENT** — design sound, AC-2 count-coupling provably survives on all 6 rows both shells, no false-match, exhaustiveness confirmed; no conditions.
