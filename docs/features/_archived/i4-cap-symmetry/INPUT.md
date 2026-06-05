# Task Input — i4-cap-symmetry (T-009)

## Origin
Surfaced during T-007/T-008 and deferred as a clean separate task (user approved running it: "继续"). Three related pre-existing maintenance-debt items in the verify_all/baseline count hygiene.

## Problem 1 (primary) — I.4 measures the wrong thing, asymmetrically across shells
- `verify_all.ps1:398` I.4 counts **total physical lines** via `Get-Content | Measure-Object -Line` (lands ~30 → PASS in this env).
- `verify_all.sh:419` I.4 counts **total physical lines** via `wc -l` (= 33 → WARN).
- `archive-task.ps1:71` rotation counts only **insight DATA lines** via `^\s*-\s+` (= 23 → does NOT rotate, since 23 < 30).
- The documented intent (AI-GUIDE.md:34 "≤30 **evidence-backed lines** of project-specific facts"; rule `.harness/rules/05-insight-index.md`) is the DATA-line count, NOT total physical lines (the file has ~9 header lines + the insight bullets).

Consequences:
- **Cross-shell divergence (L13 class):** same file, PS PASS vs bash WARN — the two shells don't count identically.
- **The WARN is a false alarm:** the file has only 23 evidence lines (< 30 intended cap); it's the 9-line header being counted that pushes total over 30.
- **archive-task never rotates** at the I.4 threshold because the two use different metrics — so the WARN can never be cleared by the auto-rotation it points the user at ("archive-task auto-rotates").

## Problem 2 (related) — baseline.json test_init counts disagree with manual-e2e-test
- `.harness/scripts/baseline.json:11,12` `test_init_*` = 251/213.
- `docs/manual-e2e-test.md:3` test-init = 227/191.
One is stale. (Note: T-007 reported test-init PS 251 / SH 213 from a real run, so baseline.json may be current and manual-e2e-test stale — but DO NOT assume; capture from a real run.)

## Goal (one line)
Make the insight-index size cap measure the documented "evidence/data lines" consistently in BOTH shells AND consistently with archive-task's rotation metric, so I.4 is symmetric, truthful, and its WARN (when it fires) is actually clearable by the rotation it advertises; and reconcile the baseline.json ↔ manual-e2e-test test_init counts from a real run.

## Design crux for SA (NOT pre-decided)
1. **What does the cap measure — total physical lines or insight DATA lines?** The documented intent points to DATA lines (≤30 evidence-backed). Candidate fix: change I.4 (both shells) to count `^\s*-\s+` data lines (same regex archive-task uses), so I.4 + archive-task + the rule all agree, and PS/bash become symmetric. SA confirms/decides; weigh against the alternative (keep total-line cap but make archive-task rotate on total lines — tighter, but penalizes the fixed header).
2. **Does the current file need rotation NOW?** With the data-line metric, the file is at 23 < 30 → no rotation needed, WARN clears. With a total-line metric, it'd need trimming. The SA's choice in (1) determines this.
3. **Cross-shell symmetry:** whatever metric is chosen, PS and bash must compute it identically (insight L13/L20 — PS `Measure-Object` vs bash `wc -l`/`grep -c` must agree).
4. **baseline.json vs manual-e2e-test:** which is canonical, and should one DERIVE from the other (or from a real run) to stop future drift? (Same spirit as G.4 — but scope-bound; don't over-build.)

## Acceptance criteria (refine in stage 1)
- AC-1: `verify_all.ps1` AND `.sh` produce the SAME I.4 verdict on the SAME insight-index.md (no cross-shell divergence), and I.4 measures the documented metric.
- AC-2: With the current 23-evidence-line file, I.4 PASSes in both shells (the false WARN is gone), OR — if the SA chooses a total-line metric — the file is rotated to satisfy it and archive-task's rotation trigger matches the I.4 cap.
- AC-3: I.4's threshold and archive-task's rotation threshold measure the SAME quantity (so the WARN, when it fires, is clearable by archive-task as the message claims).
- AC-4: baseline.json:11,12 and manual-e2e-test.md:3 test_init counts agree, set from a captured real run.
- AC-5: verify_all 32/32 PASS in BOTH shells (the SH I.4 WARN resolved → SH back to all-PASS / RC 0), 0 FAIL. No new check added (so count stays 32; if the SA adds a check, justify + bump per the G.4 lesson).
- AC-6: PS/Bash symmetry across all edits (L13).

## Out of scope
- The G.4 mechanism (done in T-008).
- Broad refactor of archive-task beyond the rotation-metric alignment.
- Changing the numeric cap value (30) unless the SA shows it's wrong; this task fixes WHAT is measured, not the limit.
