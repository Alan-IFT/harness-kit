# 06 — Test Report · context-glossary (T-02)

**Mode:** full · **Stage:** 6 (QA Tester) · **Date:** 2026-06-19
**Upstream:** 01/02/03/04/05 = READY/READY/APPROVED FOR DEVELOPMENT/READY FOR REVIEW/APPROVED WITH NOTES.
**deferred-human:** defer, do not ask. Bash available in this sub-agent; PowerShell denied → PS runs marked operator-pending (NOT fabricated).
**Verdict source of truth:** what the implementation survived under adversarial probes + the three gate runs, not the diff.

---

## Test plan

| Acceptance criterion | Test case(s) / probe | Evidence |
|---|---|---|
| AC-1 root `CONTEXT.md` exists, `#` title + 1-2 sentence desc + ≥3 term entries (bold + def + `_Avoid_`) | independent count of `^\*\*` headers vs `^_Avoid_:` lines; head -1 title | 13 bold-term headers, 13 `_Avoid_:` lines, title `# Harness Kit` — PASS |
| AC-2 every term is harness-kit-specific (behavior-3 set), no general-programming concepts; no file-path-as-definition | read term list; grep for file-path-as-definition-body | 13 terms all from candidate set (frontier/pool/ambient/partition agent/stage doc/verdict/insight/rollback/dogfood/template overlay/soft/hard dep/gate); no path used as a definition — PASS |
| AC-3 generic seed present, placeholder-free, NOT byte-copy of dogfood | `grep -rE '\{\{[A-Z_]+\}\}'` (empty); `diff -q` dogfood vs seed (differ); test-init's own "no unresolved placeholders anywhere" assertion | no double-brace token; files DIFFER; scan PASS — PASS |
| AC-4 `requirement-analyst.md` SOFT-dep ref (read-if-present + lazy-maintain + graceful degrade, no setup pointer, no `BLOCKED`) | read Workflow step 7; HARD-dep phrasing scan | step 7 ends "just proceed — it is a convenience, never a precondition"; no setup pointer, no BLOCKED-on-absent — PASS |
| AC-5 `solution-architect.md` analogous SOFT-dep ref | read Workflow step 5 | step 5 ends "just proceed — it never blocks the design" — PASS |
| AC-6 AI-GUIDE Memory-layer has exactly one new `CONTEXT.md` bullet; file ≤200 lines | read AI-GUIDE:39; `wc -l` | one bullet at line 39 (matches insight-index/decision-rubric shape); 109 lines (≤200) + I.1 gate PASS — PASS |
| AC-7 dev-map location entry (root dogfood + seed path) | read dev-map:150 | "Where features live" row records both paths — PASS |
| AC-8 `verify_all` PASSes, check count unchanged at 32 | `verify_all.sh` ×2 | 32 PASS / 0 WARN / 0 FAIL (twice); G.3/G.4/I.1/I.3/I.6 green; count 32 — PASS (Bash). PS = operator-pending |
| AC-9 test-init + test-real-project PASS; baseline reconciled from captured run | `test-init.sh` ×2, `test-real-project.sh` ×2; baseline.json read | test-init 273/0 (Bash field baseline=273, matches capture); test-real-project 90/0 (baseline 90/90 unchanged) — PASS (Bash). PS test-init capture + `test_init_ps_assertions` reconcile = operator-pending |
| AC-10 no I.6 banned-anchor phrase in any added/edited file | verify_all I.6 (authoritative exhaustive scan) + manual review of 14 live anchors | I.6 PASS; all 14 anchors concern retired CLAUDE.md/composition/zh-language claims, none about glossaries — PASS |

---

## Boundary tests added / exercised

This task ships no runtime code (static markdown + agent prose + one index line + one test-init
assertion pair), so the QA contribution is **adversarial probes against the existing suite**, not new
unit-test files. The load-bearing new test is the developer's seed-present assertion (both shells);
QA's job is to prove it is real (see mutation test below) and that absence degrades gracefully.

- **Seed absent (mutation):** seed renamed away → test-init.sh drops to 270/3 (only the 3 seed-present
  assertions fail; all 270 others pass) → restored → 273/0. Proves (a) the assertion is non-vacuous and
  (b) CONTEXT.md absence breaks nothing else.
- **Placeholder boundary:** `\{\{[A-Z_]+\}\}` and broader `\{\{[^}]*\}\}` over both files → empty.
- **Byte-identity boundary:** `diff -q` dogfood vs seed → differ (AC-3).
- **Graceful-degradation boundary:** RA/SA prose contains no setup pointer / no BLOCKED-on-absent /
  no precondition language; absence is explicitly "a convenience" / "never blocks the design".
- **Doc-size caps:** AI-GUIDE 109 ≤200 (I.1); RA 74, SA 122, both ≤300 (I.3); all gate-green.
- **Version-stamp boundary:** 0.34.0 across plugin.json, marketplace.json, both README badges,
  CHANGELOG `[0.34.0]` heading; no stale 0.33.0 in the stamp set (history-table rows correctly retain 0.33.0).
- **Stability:** verify_all ×2, test-init ×2, test-real-project ×2, plus the mutation cycle — no flakes.

---

## Adversarial tests (one predicted-failure probe per concern)

For each, the hypothesis ("I expect failure when…") was written before running. Verdict is based on
whether the implementation **survived**, with actual tool output.

| # | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote this) | Outcome (with tool output) |
|---|---|---|---|
| AC-3 / load-bearing | the new seed-present assertion is vacuous — passes whether or not the seed exists | rename `templates/common/CONTEXT.md` away, re-run `test-init.sh`, then restore | **Survived (assertion is real).** With seed gone: `PASS: 270 / FAIL: 3` — 3× `FAIL CONTEXT.md seed present (generic glossary)` (one per project type). Restored: `PASS: 273 / FAIL: 0`. The assertion fires exactly when the seed is absent — non-vacuous. |
| AC-3 | the seed trips test-init's `\{\{[A-Z_]+\}\}` placeholder scan | `grep -rEn '\{\{[A-Z_]+\}\}' CONTEXT.md templates/common/CONTEXT.md` and the broader `\{\{[^}]*\}\}` | **Survived.** "OK: no double-brace UPPER_SNAKE placeholder"; "OK: no double-brace token at all". test-init's own "no unresolved placeholders anywhere" assertion also PASS. |
| AC-3 | the seed is a byte-copy of the dogfood (a generated project would ship harness-kit's vocabulary) | `diff -q CONTEXT.md templates/common/CONTEXT.md` | **Survived.** "OK: dogfood and seed DIFFER". Dogfood = `# Harness Kit` (13 real terms, 80 lines); seed = `# {Your Project}` (generic stubs, 20 lines). |
| AC-4/AC-5 | the wiring makes CONTEXT.md a precondition (setup pointer or BLOCKED-on-absent) → HARD dependency | per-pattern scan: `run setup/init first`, `setup first`, `BLOCKED`, `must run/create/provision`, near the CONTEXT lines | **Survived.** No match on `run...first` / `setup first` / `BLOCKED` / `must run/create/provision`. The only `precondition`/`requires?` hits are inside "never a precondition" (the graceful-degradation negation) — false positives, confirmed by reading the lines. Prose is correct SOFT wiring. |
| Boundary 1 | a project with no CONTEXT.md is broken by the new agent steps | mutation test reuse: with seed absent, do the OTHER 270 test-init assertions still pass? | **Survived.** Only the 3 seed-present assertions failed; all 270 remaining assertions passed → absence breaks nothing else. |
| AC-10 / I.6 | a new definition (rollback/verdict/insight/dogfood) reproduces an I.6 banned anchor → I.6 FAIL | run verify_all I.6 (exhaustive scan over non-exempt files incl CONTEXT.md/agents/AI-GUIDE/dev-map) + read the 14 live anchors | **Survived.** I.6 PASS. All 14 anchors concern retired CLAUDE.md/composition/zh-"全程中文" claims; none concern glossaries/domain-terms/CONTEXT.md → no collision possible. |
| AC-6 doc cap | the AI-GUIDE bullet pushes AI-GUIDE over 200 lines | `wc -l AI-GUIDE.md` + verify_all I.1 | **Survived.** 109 lines; I.1 PASS. |
| AC-8 version | a version stamp was missed (G.3) or CHANGELOG heading omitted (G.4) | grep 0.34.0 across stamp set; grep `## [0.34.0]`; verify_all G.3/G.4 | **Survived.** 0.34.0 in plugin.json/marketplace.json/both README badges; `## [0.34.0] - 2026-06-19` present; G.3 + G.4 PASS. |

---

## verify_all / test-init / test-real-project result (Bash side)

- **verify_all.sh:** `PASS: 32 · WARN: 0 · FAIL: 0` (run twice, identical). Check count unchanged at 32.
- **test-init.sh:** `PASS: 273 · FAIL: 0` (run twice, identical). Was 270 pre-task; +3 = new seed-present
  assertion × 3 project types. Bash baseline field `test_init_bash_no_python3_assertions: 273` matches the
  captured run.
- **test-real-project.sh:** `PASS: 90 · FAIL: 0` (run twice, identical). Baseline 90/90 unchanged (driver
  has no per-asset count; seed rides the overlay).
- New tests added by QA: 0 new files (probes only; the developer's symmetric seed-present assertion is the
  load-bearing addition, validated as non-vacuous).
- Baseline updated by QA: no change required — Bash field already correctly reconciled to 273 by developer;
  PS field (308) and both README `test--init-` badges are the operator-pending bundle.

---

## Defects found

**None.** 0 BLOCKER, 0 CRITICAL, 0 MAJOR, 0 MINOR.

The two code-review MINOR notes are confirmed non-defects:
- The 13-vs-"aim 8-12" term count is within design spirit (all sanctioned terms, file 80 lines, NFR-2 intact).
- The stale-prose note in 04_DEVELOPMENT.md (baseline field was in fact reconciled to 273) is a doc-accuracy
  observation, not a behavior defect; file state is correct.

---

## Stability

- `verify_all.sh` ran 2× → 32/0/0 both times. ✅
- `test-init.sh` ran 2× (plus the mutation cycle 270/3 → restored 273/0) → 273/0 both clean times. ✅
- `test-real-project.sh` ran 2× → 90/0 both times. ✅
- No flakes observed in the new seed-present assertion across all runs.

---

## Operator-pending (capability-gated, NOT defects)

PowerShell is denied to this sub-agent; these are the F-1 bundle already flagged by developer + reviewer.
Do not treat as defects — they are honest deferrals, not undone work:

1. **`verify_all.ps1`** → confirm 32/32 (Bash side green; G.3/G.4 are cross-shell-symmetric).
2. **`test-init.ps1`** → capture total, then reconcile `baseline.json` `test_init_ps_assertions` (currently 308)
   from the captured run. Expected to move by +3 (seed-present × 3 project types) → likely ~311, but MUST be
   captured, not assumed.
3. **`test-real-project.ps1`** → capture total (expected 90, unchanged).
4. **Both README `test--init-308%2F308` badges** (README.md:5, README.zh-CN.md:5) → update to the captured
   `test-init.ps1` total. No gate catches these (G.3 = `version-`, G.4 = `verify__all-`), so they must reflect
   the real captured number.

---

## Verdict

**PASS WITH NOTES.**

All 10 acceptance criteria verified on the Bash side with tool evidence; every adversarial probe survived,
including the load-bearing mutation test that proves the seed-present assertion is non-vacuous. verify_all
32/0/0, test-init 273/0, test-real-project 90/0, all stable across repeated runs. Zero defects of any severity.

The "WITH NOTES" qualifier reflects only the capability-gated PowerShell-side bundle (PS verify_all/test-init/
test-real-project captures + `test_init_ps_assertions` reconcile + the two README `test--init-` badges), which
this runtime cannot execute and which must not be fabricated. The Bash side is fully green and the gates
(G.3/G.4/F.1) are cross-shell-symmetric, so the PS side is expected to mirror — but it is operator-pending,
not QA-confirmed. No route-back to developer or requirement-analyst.
