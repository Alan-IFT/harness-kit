# 03 — Gate Review · i6-semantic-guard (T-004 · v0.18.0)

Mode: **full**. Inputs: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY).
Reviewer scrutinized every checkable claim by independently grepping the live repo.

## Audit checklist

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | 11 ACs concrete and testable; boundary conditions enumerated; no untestable criterion. |
| 2 | Design completeness | **FAIL** | §6 AC-4 analysis omits the task's own stage docs and its mitigation does not cover `00-core.md.tmpl:7`. |
| 3 | Reuse correctness | PASS | `step`/`Step`, the I.6 scan loop + exempt arrays, `[regex]::Escape` (`verify_all.ps1:450`), `test-supervisor` harness — all verified to exist and be reusable as cited. |
| 4 | Risk coverage | WARN | R-1..R-7 are the right risks, but R-1 is presented as resolved when two live files defeat the mitigation. |
| 5 | Migration safety | PASS | Verify-time check, no data migration / flag; correctly stated. |
| 6 | Boundary handling | PASS | Empty/binary/no-git/degenerate/cross-line/metachar/delimiter-collision all designed; backtracking bounded. |
| 7 | Test feasibility | PASS | Every AC maps to a named fixture with explicit expected verdict. |
| 8 | Out-of-scope clarity | PASS | 30-check count, no new dep, exempt membership unchanged; new test pair correctly needs no `sync-self`. |

## Findings

### F-1 (FAIL) — `00-core.md.tmpl:7` is an uncaught live hit

Entry #2 = anchors `Composed`~`into`~`` `CLAUDE.md` `` with the design's final `gap=20` +
`exclude=('not','no longer','referenced')`. Verified live text at
`skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl:7`:
`...rules are referenced, not composed into ` + "`CLAUDE.md`" + `)`. The
`composed`→`into`→`` `CLAUDE.md` `` gaps are ~1 char each, so the regex matches. The
matched span is `composed into ` + "`CLAUDE.md`" + ` — and the `exclude` guard is
**span-scoped** in both shells (design §3.2/§3.3/§3.4). The words `referenced`/`not`
sit *before* `composed`, outside the span, so `exclude` does not fire. `gap=20` only
saves `concepts.md:104` (binding sub-gap ~22); it cannot save a ~1-char gap. The design
lists this file in its §4.1 table yet §5's claim that "`referenced` covers
`00-core.md.tmpl:7`" is wrong. This file is tracked, non-exempt → I.6 FAILs → AC-4 broken.

### F-2 (FAIL) — the task's own committed stage docs become live hits

I.6 scans `git ls-files`. The repo is green today only because `01_REQUIREMENT_ANALYSIS.md`
/ `02_SOLUTION_DESIGN.md` are still untracked working-tree files. When v0.18.0 ships, the
pipeline commits the stage docs into `docs/features/i6-semantic-guard/` — not `_archived/`,
not exempt — and they get scanned. They contain literal banned phrases: `regenerates
CLAUDE.md` at `01:10,20,107,238` and `02:73,141,142,351,487`; `scaffolding-only` at
`01:83` and `02:117,141,212,347`; plus many gap-tolerant near-misses. **The commit
shipping I.6 v0.18.0 fails its own I.6 gate.** The design's §6 never accounts for the
self-referential scan and has no mechanism for it. §9's rollout runs verify_all (step 4)
*before* archival, so "docs get archived later" does not save it as currently sequenced.

### F-3 (WARN) — §6 residual set is hand-waved

§6 says "any other capital-S occurrence the case-fold newly catches" without enumerating.
GR grepped `[Ss]caffolding-only`: the only non-exempt capital-S occurrence is
`docs/dev-map.md:113` (the known R-2 line). The residual is exactly one file — the design
should state this definitively rather than leave it for the developer to re-derive.

## Non-findings — independently confirmed correct

- The `regenerate[sd]` family (#5–#8) verb-first ordering genuinely protects
  `10-self-consistency.md:17` and `tests/fixtures/README.md:23` (both put `CLAUDE.md`
  first — verified).
- Entries #4 and #9 have only exempt-file occurrences.
- `concepts.md:104` is correctly cleared by `gap=20` (binding sub-gap `composed`→`into`
  ~22 chars, not the 35 the design measured — same conclusion, different arithmetic).
- Insights L19/L23/L24/L12 are addressed in substance, not name-dropped.
- The ERE vs .NET parity argument is sound for all 13 entries.
- The new `test-verify-i6` temp-dir fixtures correctly do not trip I.6 (outside `git ls-files`).
- The PM's R-2 decision (option a, edit `dev-map.md:113`) is technically correct — concur.

## Predicted developer questions (pre-answered)

1. Span-scoped or line-scoped `exclude`? — currently span-scoped; root of F-1.
2. Will the shipping commit fail verify_all? — yes today (F-2); the architect must supply a mechanism.
3. Which entry catches AC-1/AC-2? — entry #5 (gap 40), not #2 — an F-1 change to #2 won't regress AC-1/AC-2.
4. `~`/`|` delimiter collision? — R-7 covers it; no current entry contains either.
5. Do the temp fixtures trip I.6? — no, they live outside `git ls-files`.

## Verdict

**CHANGES REQUIRED** — route back to **solution-architect**.

The matcher, the 13-entry migration, the parity argument, boundary handling, and the
test-driver design are sound. But AC-4 / in-scope item 11 ("repo stays green") is the
load-bearing claim and is not met: F-1 leaves a live non-exempt file hitting entry #2,
and F-2 means the shipping commit fails its own gate. The architect must revise the
design to (a) genuinely clear `00-core.md.tmpl:7` without weakening AC-3's
false-positive guarantee, and (b) provide and prove a mechanism for the self-referential
stage-doc scan — including whether that needs an exempt-dir membership change (formally
extend scope) or a §9 rollout-ordering change. F-3 should be resolved by enumerating
the residual set definitively.

---

# Re-review (Rev 2) — 2026-05-22

Re-review of `02_SOLUTION_DESIGN.md` rev 2 (§14 rework) against F-1, F-2, F-3.

## F-1 — line-scoped `exclude` — PARTIALLY CLOSED
`00-core.md.tmpl:7` is genuinely cleared by line-scoped exclude (`not`/`referenced`
on the line). Mechanism (bash `grep -F -i -q` over the full line; PS `IndexOf`
OrdinalIgnoreCase over `$line`) is sound and symmetric. AC-3 still holds (its fixture
exercises the `regenerated` family #7/#8, no `exclude`). No new live false-negative
from line-scoping. **But `concepts.md:104` is NOT cleared — see F-4.**

## F-4 (NEW FAIL) — `concepts.md:104` uncaught; the rework's `v0.2` claim is false
The design (§4.1, §6, §14, R-1) asserts `concepts.md:104` is cleared by adding `v0.2`
to entry #2's `exclude`, stating "`v0.2` is on the matched line". It is not:
- `concepts.md:103` contains `v0.2` but no `Composed` anchor.
- `concepts.md:104` (`composed `.harness/rules/*.md` into a single `CLAUDE.md`...`)
  is where all three of #2's anchors land — and carries none of `v0.2`/`not`/
  `no longer`/`referenced`.
Entry #2 matches a span wholly within line 104; line-scoped exclude tests line 104,
where every exclude token is absent → `concepts.md:104` still hits #2. Tracked,
non-exempt → I.6 FAILs → AC-4 broken. The rework REMOVED the `gap=20` override (which
the prior revision confirmed DID clear this file) and substituted a token that does
not exist on the matched line. `fx-historical.md` masks the bug by putting `v0.2` and
the anchors on one line, which the real file splits across 103/104.

## F-2 — exempt-dir widened to `docs/features/` — CLOSED. Confirmed.
Both scripts updated (§2, §3.6); prefix-match subsumes `_archived/`; scope sections
§1/§3.6/§9/§10/§12 consistent; §7.2 adds a fixture. Verified.

## F-3 — residual set — CLOSED. Confirmed.
§6 now states the closed list definitively: only `docs/dev-map.md:113`.

## Doc size — nit
`02_SOLUTION_DESIGN.md` is 501 lines vs the rule-70 soft cap of 500. WARN-level, not
a blocker; trim opportunistically during the F-4 rework.

## Verdict: CHANGES REQUIRED — route back to solution-architect
F-2 and F-3 genuinely closed. F-1's mechanism is sound. But the rework introduced F-4:
`concepts.md:104` still hits entry #2 because the `v0.2` exclude token is on a
different line than the match. The architect must re-resolve `concepts.md:104` against
the actual line-104 content, correct the false "`v0.2` is on the matched line"
statements, and replace `fx-historical.md` with a fixture reproducing the real
two-line layout.

---

# Re-review (Rev 3) — 2026-05-23

Narrow re-review of `02_SOLUTION_DESIGN.md` rev 3 against the single open finding F-4
plus a fresh F-5 sweep. F-1/F-2/F-3 GR-confirmed closed in Rev 2 — not re-examined.
All char counts counted against the live repo.

## F-4 — `concepts.md:104` uncaught — CLOSED. Confirmed.
Entry #2 = `gap=20` + line-scoped `exclude=('not','no longer','referenced')`; `v0.2`
token dropped. Verified live:
- `concepts.md:104` — `composed`→`into` sub-gap = 23 chars (` ` + backtick +
  `.harness/rules/*.md` + backtick + ` `). 23 > 20 → `gap=20` breaks the chain. Line
  carries no exclude token, so `gap=20` (not exclude) clears it. Correct.
- Four negation files (`00-core.md.tmpl:7`, `getting-started.md:132`,
  `CONTRIBUTING.md:111`, `harness-sync.ps1:8` + its `skills/` twin) — each has ~1-char
  anchor sub-gaps (entry matches the line) and carries `not`/`no longer`/`referenced`
  on the line (line-scoped exclude suppresses). §6 char-count table accurate.
- Both mechanisms genuinely necessary — neither alone clears all five.
- All stale `v0.2`-clears-`concepts.md` statements removed from §4.1/§5/§6/§8 R-1/§14.
- `fx-historical.md` fixture now reproduces the real two-line layout, expects NO hit,
  tests the `gap=20` path specifically (no exclude token on the anchor line).

## F-5 sweep — none found.
`gap=20` on #2 does not regress real-bypass detection: `composed into the static stub
`CLAUDE.md`` has sub-gaps 1 and 17, both ≤ 20 → still hits. `gap=20` suppresses only
21–40-char inter-anchor distances, which in the live tree occur solely in the
`concepts.md:104` historical parenthetical. AC-1/AC-2 hit entry #5 (gap 40) — untouched.

## Doc size — non-blocking nit.
~519 lines vs the rule-70 soft 500-line cap. Soft WARN-level cap; PM accepted the
overrun; trimming further would delete load-bearing char-count proofs. Noted only.

## Verdict: APPROVED FOR DEVELOPMENT
F-4 genuinely closed; no F-5. The matcher, 13-entry migration, parity argument,
boundary handling, and test-driver design were GR-confirmed sound in prior passes and
are unchanged. Development may proceed.

---

# Focused Re-review #3 (Rev-4) — 2026-05-23

Narrow re-review of the entry-#10 `exclude=.claude/` fix only. Rest of design
GR-confirmed sound across passes 1-3.

1. **`exclude=.claude/` clears both README lines — CONFIRMED.** Live `README.md:196`
   and `README.zh-CN.md:198` both carry the literal `.claude/`; line-scoped exclude
   fires for both.
2. **Genuine false claim still caught — CONFIRMED.** A real `.harness/ → CLAUDE.md`
   claim asserts the target IS CLAUDE.md and would not co-occur with `.claude/` (the
   contradictory correct target) on one line. `fx-meta-arrow.md` still expects HIT.
   No over-suppression.
3. **Hit set bounded — CONFIRMED.** verify_all found exactly 3 hits; #10's exclude
   clears the 2 README lines; `dev-map.md:113` remains (R-2 in-commit fix). Entry #9
   has zero live non-exempt hits (only `CHANGELOG.md` exempt + `docs/features/`
   exempt-dir). I.6 = PASS 30/30 post-commit.
4. **§7.2 `fx-arrow-accurate.md` — CONFIRMED** added, reproduces the README line,
   expects NO hit; §7.3 assertion #6 includes it.
5. **§3.3 grep note — CONFIRMED** records `shopt -s nocasematch` + `[[ == *glob* ]]`
   substitution for `grep -F -i` (Git-for-Windows GNU grep 3.0 SIGABRT).
6. **No new defect** — single additive `exclude` token on one entry, reusing the
   existing line-scoped exclude mechanism. Live scripts still hold pre-rev-4 entry
   #10 — correct, the developer deferred the script edit pending this approval.

## Verdict: APPROVED FOR DEVELOPMENT
The rev-4 fix is correct, minimal, and regression-protected. The earlier
`BLOCKED ON DESIGN` is resolved. Development may resume.
