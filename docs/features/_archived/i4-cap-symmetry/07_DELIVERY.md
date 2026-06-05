# Delivery Summary — i4-cap-symmetry (T-009)

- **Task:** Fix the insight-index size cap so it measures the documented "evidence/data lines" consistently in BOTH shells and consistently with archive-task's rotation metric — resolving the pre-existing I.4 cross-shell WARN/PASS split (surfaced during T-008) — and reconcile the baseline.json↔manual-e2e-test test_init drift.
- **Mode:** full (7-stage)
- **Version:** v0.21.0 → **v0.21.1** (patch — internal verify_all fix; check count UNCHANGED at 32)
- **Stages:** RA (01, no bounce) → SA (02) → Gate (03, APPROVED + 5 conditions) → Dev (04) → CR (05, APPROVED) → QA (06, PASS) → Delivery (this) + v0.21.1 ship bump. **0 rollbacks.**
- **Final verify_all:** **PS 32/32 PASS · SH 32/32 PASS — both 0 WARN, 0 FAIL.** The pre-existing SH I.4 WARN is resolved; both shells now agree (I.4 PASS, 25 evidence lines). G.3 + G.4 PASS in both.
- **What shipped:**
  - `verify_all` I.4 now counts insight-index **evidence/data lines** (`^\s*-\s+`) instead of total physical lines, via a regex-filtered match count that is byte-identical across shells (PS `@(Get-Content|Where{...}).Count`, bash `grep -c '^[[:space:]]*-[[:space:]]' …||true`) — immune to the `wc -l` vs `Measure-Object -Line` trailing-newline off-by-one that caused the split. Now aligned with archive-task's existing rotation metric and the AI-GUIDE "≤30 evidence-backed lines" intent.
  - Clarified the two repo rule fragments (`05-insight-index.md`, `70-doc-size.md`) to say "evidence lines" (the `.tmpl` user-project siblings deliberately left — separate F.4 surface).
  - Reconciled `baseline.json:11,12` ↔ `manual-e2e-test.md:3` test_init counts to a captured run (251/213; baseline.json was already canonical, manual-e2e corrected from stale 227/191).
- **Baseline changes:** no new check (count stays 32; G.4's tally undisturbed). The SH verify_all return code goes RC 1→RC 0 (the spurious WARN is gone).
- **QA highlight:** a 7-fixture cross-shell parity matrix (31→WARN, 30→PASS boundary, header-inflated→PASS, no-trailing-newline→agree, CRLF→agree, empty→PASS) — all byte-identical across shells; QA empirically proved the OLD metric diverged on the no-newline edge (bash `wc -l`=31 vs PS=32). 0 defects.
- **Files changed:** `verify_all.{ps1,sh}` (I.4), `.harness/rules/{05-insight-index,70-doc-size}.md`, `docs/manual-e2e-test.md`, `plugin.json` + `marketplace.json` + `README.md` + `README.zh-CN.md` + `AI-GUIDE.md` + `dev-map.md` + `40-locations.md` + `CHANGELOG.md` (v0.21.1 ship).

## Outstanding (minor, non-blocking)

1. **Count-claim version treadmill (design reflection, not a bug).** G.4 anchors each "N checks at vX" claim's version to the CURRENT `plugin.json` version, so even a patch that doesn't change the count must bump 6 claim versions in lockstep (G.4 enforces + names any miss, so it's guided, not error-prone — but it is per-release churn). A future improvement worth weighing: have G.4 validate only the COUNT for these claims (dropping the version token, or treating it as "first-appeared-in" rather than "current"). Out of scope here; flagged for consideration.
2. **CR NITs (pre-existing, OOS):** `insight-index.md:3` header blockquote still says "≤30 lines" (the index file itself, deliberately untouched); `dev-map.md:134` (version-pinned "at v0.16.0", historical) + `docs/project-overview.html:299` (visual snapshot) carry stale `227/191` — outside this task's reconcile scope.

## Insight

- 2026-06-05 · A document-size cap is only enforceable if its gate check, its auto-remediation, and its documented intent all count the SAME quantity. verify_all I.4 capped insight-index on TOTAL physical lines while archive-task rotated on insight DATA lines and the rule intent was "evidence lines" — so the WARN fired on the 9-line header yet the advertised auto-rotation could never clear it, and the two shells (`wc -l` vs PS `Measure-Object -Line`) even disagreed by one on a no-trailing-newline file. Fix: count the documented quantity (regex-filtered data-line match count, which counts records not newline separators → cross-shell stable) in the gate, the remediation, AND the rule wording. · evidence: T-009, verify_all I.4 + archive-task rotation alignment
