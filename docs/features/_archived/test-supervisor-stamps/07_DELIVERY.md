# Delivery Summary — test-supervisor-stamps (T-008)

- **Task:** Kill the version/count-stamp drift class in `test-supervisor.{ps1,sh}` (8 fan-out asserts hardcoding `v0.17.1`/`30`, silently red since ~v0.17) — not with a band-aid literal bump, but by removing the misplaced asserts and adding a standing gate that derives the values from the source of truth.
- **Mode:** full (7-stage)
- **Version:** v0.20.0 → **v0.21.0** (minor — adds a new standing verify_all check; count 31 → 32)
- **Stages traversed:** RA (01, no user bounce) → SA (02, **2 rollbacks** for incomplete count-claim sweep) → Gate (03, APPROVED after re-review #2) → Dev (04) → CR (05, APPROVED) → QA (06, PASS) → Delivery (this) + v0.21.0 ship bump.
- **Rollbacks:** 2, both at stage 2 (design). Gate re-scans found the design's count-claim sweep kept missing scattered claims — F-1 (`40-locations.md` "items"), F-2 (`README.zh-CN.md:5` badge), F-5 (`baseline.json:10` JSON field), and the SA self-caught F-7 (`README.zh-CN.md:159` `（30 项检查）`, already a release stale). Converged at an **exhaustive 11-claim / 8-file ledger** before any code was written. The whack-a-mole *was the evidence* that a standing gate (G.4) is the right fix.
- **Final verify_all:** PS **32/32 PASS** (0 WARN, 0 FAIL); SH **31 PASS + 1 WARN + 0 FAIL** — the lone WARN is the pre-existing I.4 insight-index cross-shell divergence (see Outstanding §1), NOT a T-008 change. 0 FAIL both shells; G.3 + the new G.4 PASS in both.
- **What shipped:**
  - Removed 8 version/count fan-out asserts from `test-supervisor.{ps1,sh}` (7 of 8 were already failing — empirically confirming the premise); kept the 3 version-agnostic structural asserts.
  - Added a new standing **G.4** meta-check to `verify_all.{ps1,sh}` (the LAST check, with a pin-comment + Summary tripwire): derives the version from `plugin.json` and the count from the live recorded-step tally (`$report.Count + 1`, status-independent), then validates all 11 doc count/version claims + the CHANGELOG `[version]` heading. The drift class now FAILs at the gate instead of rotting unobserved.
  - Bumped all 11 count claims 31→32 and, at ship, their version token to v0.21.0 (G.4 self-enforced completeness); recounted the test-supervisor self-tally (PS 49 / SH 45) from real runs.
- **Baseline changes:** verify_all check count 31 → **32** (G.4). test-supervisor: PS 57→49 / SH 53→45 asserts (8 removed). No new FAIL.
- **Files changed:** `verify_all.{ps1,sh}` (G.4), `test-supervisor.{ps1,sh}` (−8 asserts), 8 doc/count-claim files (AI-GUIDE, dev-map, 40-locations, README×2, manual-e2e-test, baseline.json), `plugin.json` + `marketplace.json` + CHANGELOG (v0.21.0 ship).
- **Next steps for user:** see Outstanding — three pre-existing items surfaced (not caused by T-008) that are good small follow-ups.

## Outstanding (pre-existing, surfaced during T-008 — NOT introduced here)

1. **I.4 cross-shell divergence + insight-index over-cap + archive-task never rotates.** `insight-index.md` is >30 physical lines, so bash verify_all I.4 correctly WARNs while PS `Measure-Object -Line` under-counts and silently PASSes (an L13-class asymmetry; bash is right). Root cause: `archive-task` rotates on *data*-line count (~23) while I.4 caps *total* lines (~32), so the index sits permanently over cap and never auto-rotates. Recommended follow-up: align the two thresholds + fix the PS/bash count symmetry + rotate the current overflow to `insight-history.md`.
2. **`baseline.json:11,12` test_init counts (251/213) disagree with `manual-e2e-test.md:3` (227/191)** — a separate pre-existing drift; reconcile in the same follow-up.

## Insight

- 2026-06-05 · A "N checks/items at vX" count claim is pinned to the version in which the count became true, so adding a verify_all check is inherently a version-worthy change: shipping a 32nd check while leaving the claims at the already-released v0.20.0 (which shipped 31) makes that version's identity self-contradictory. The whole 7-stage pipeline missed this until PM delivery — count/version claims need a version bump, not just a count bump. The new G.4 gate now enforces claim↔plugin.json version consistency, so a future count change that forgets the version bump FAILs at the gate. · evidence: T-008, v0.21.0 ship bump + verify_all G.4
