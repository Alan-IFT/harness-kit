# 03 — Gate Review · i4-cap-symmetry (T-009)

> Stage 3. Verdict vocabulary: APPROVED FOR DEVELOPMENT / CHANGES REQUIRED / REJECTED. Upstream 01=READY, 02=READY. Read-only; every load-bearing claim verified against live code. Persisted by PM (GR is read-only).

## 1. Audit checklist
| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | In-scope behaviors numeric/verdict-testable; cross-shell parity pinned by AC-1/3/6. |
| 2 | Design completeness | PASS | Every behavior maps to a named edit with read-confirmed line numbers; D1-D4 resolved. |
| 3 | Reuse correctness | PASS | Both reused regexes verified verbatim at archive-task.ps1:71 / .sh:69; `||true` + `PASS:` capture tails confirmed. |
| 4 | Risk coverage | PASS | R1-R6 cover the real hazards; none missed. |
| 5 | Migration safety | PASS | Pure logic substitution, contract unchanged, each edit revertible. |
| 6 | Boundary handling | PASS | missing/empty/no-trailing-newline/CRLF/at-cap/leading-ws all designed. |
| 7 | Test feasibility | PASS | Every AC mechanically testable; QA fixture plan (31/30/no-newline/CRLF/empty) sound. |
| 8 | Out-of-scope clarity | WARN | Scope explicit, but the `.tmpl` F.4 cap-wording siblings (intentionally stay "30 lines") are under-stated (F-2). |

## 2. Crux verification
**D3 — byte-identical count: VERIFIED SOUND.** PS `^\s*-\s+` and bash `^[[:space:]]*-[[:space:]]` are membership-equivalent (both `^`-anchored, leading ws, literal `-`, ≥1 ws; the `\s+` vs single-`[[:space:]]`-then-contains difference is membership-irrelevant for real `- <date>` lines). A regex-filtered **match count** counts matching records, NOT newline separators → immune to the `wc -l` vs `Measure-Object` trailing-newline/CRLF off-by-one. Live Grep `^\s*-\s+` = 25 = archive-task's rotation count over the same file. PS `@(...)` wrapper mandatory + correct (forces array `.Count`). 
**D1/D2: VERIFIED.** Live insight-index = 25 data lines (Grep) < 30 → WARN clears with no rotation. archive-task already uses this exact metric (ps1:71 / sh:69) → I.4 and rotation finally agree. Lowest blast radius.
**R5 — I.4 description NOT test-pinned: rename SAFE.** Repo grep for `insight-index.md ≤30 lines`/`<=30 lines`/`I.4` across test-*.{ps1,sh}: no test asserts the description (only `.tmpl` F.4 strings + archived history). Full rename clear.
**Doc-sync (AC-7): SAFE.** I.6 banned list (verify_all.ps1:487-501) = all CLAUDE.md-composition phrases, none contain "lines"/"evidence"/"30". E.4b = rule *path* index (wording edits don't touch paths). E.5 = presence only. "lines"→"evidence lines" trips none.
**D4: SOUND.** Live drift confirmed (baseline.json:11,12=251/213; manual-e2e:3=227/191). Design mandates a FRESH captured run (not guessing either stale pair); `PASS:` capture points exist (test-init.ps1:642 / .sh:545). baseline.json canonical, correct manual-e2e to the run — minimal sound choice.
**Scope+count: VERIFIED.** No new Step/step → tally stays 32, G.4's `+1` undisturbed, no claim/version re-bump cascade.

## 3. Findings (all WARN/cosmetic — none block)
- **F-1 (C-1)** — 02 §3 D3/§6 R6 claim verify_all.sh uses `set -euo pipefail`; live `verify_all.sh:3` is `set -uo pipefail` (NO `-e`). `|| true` is therefore not abort-required, but KEEP it (mirrors archive-task.sh:69, yields clean `0`). Rationale text wrong; prescribed code right.
- **F-2 (C-3)** — `.tmpl` cap-wording siblings under-stated: `templates/common/.harness/rules/05-insight-index.md.tmpl`, `70-doc-size.md.tmpl`, `i18n/zh/common/.harness/rules/05-insight-index.md.tmpl` carry "30 lines" for the user-project F.4 check. OUT OF SCOPE — do NOT edit (would pull in F.4 surface + tests). Edit only the 2 repo dogfood rules.
- **F-3 (info)** — live file grown to 34 total / still 25 data since design; D2 conclusion unaffected — confirms the total-line metric's fragility.
- **F-4 (cosmetic)** — 02 §3 D3 `.Count`/`.Length` gloss imprecise; prescribed code `@(...).Count` correct regardless.
No FAIL.

## 4. Conditions for development (dev-time guards; none block start)
- **C-1:** Keep `|| true` on bash `grep -c`; ignore the design's wrong `set -e` premise (live is `set -uo pipefail`). Do not remove `|| true`.
- **C-2:** Before renaming the I.4 description, run the repo grep for the literal — confirmed not test-pinned, proceed.
- **C-3:** Do NOT edit the 3 user-project `.tmpl` cap siblings (OOS F.4). Edit only `.harness/rules/05-insight-index.md` + `70-doc-size.md`.
- **C-4:** Capture `test-init.{ps1,sh}` `PASS:` integers from a FRESH run; paste verbatim; set baseline.json:11/:12 + manual-e2e:3 to them. Do not reuse 251/213 or 227/191.
- **C-5:** Run verify_all in BOTH shells after the wording edits → confirm 32/32 PASS (proves I.6/E.4b/E.5 untripped).

## 5. Verdict
Design sound, fully grounded, lowest-blast-radius. Every load-bearing claim verified against live code. The only defects are two imprecise explanatory sentences + one under-stated scope boundary — all non-blocking, captured as conditions.

**GATE VERDICT: APPROVED FOR DEVELOPMENT** (with 5 dev-time conditions C-1..C-5) — design verified sound against live code; no requirement ambiguity, no design gap, no FAIL.
