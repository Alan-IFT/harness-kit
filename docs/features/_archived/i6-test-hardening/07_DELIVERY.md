# 07 — Delivery · i6-test-hardening (T-005)

PM-authored. Mode: **full** 7-stage pipeline. Release target: **v0.18.1** (patch).

## Outcome

Delivered. Closes the two non-blocking observations left by T-004 (i6-semantic-guard, v0.18.0):

1. **PS-side structural lockstep** now matches the bash side at full **2×2 verbatim per-entry
   × 4-field** coverage. A typo in any of `verify_all.ps1` entries `#1` / `#3-9` / `#11-13`'s
   `reason` / `exclude` / `gap` fields is now caught on every run — not only by the
   cross-shell behavioral parity assertion (which catches matcher-output divergence) but by
   the structural lockstep itself (which catches metadata divergence).
2. **AC-8 permanent corpus fixture** in place. The v0.18.0 inline-injection probe is
   replaced by 19 permanent assertions in each shell: 7 file-exempt positive + 3 file-exempt
   negative + 1 dir-exempt + 7 combined-exempt + 1 AC-14 negative-regression.

## Versioning

| File | v0.18.0 | v0.18.1 |
|---|---|---|
| `.claude-plugin/plugin.json` | 0.18.0 | 0.18.1 |
| `.claude-plugin/marketplace.json` | 0.18.0 | 0.18.1 |
| `README.md` badge | 0.18.0 | 0.18.1 |
| `README.zh-CN.md` badge | 0.18.0 | 0.18.1 |
| `CHANGELOG.md` | — | new v0.18.1 entry |
| `README.md` / `.zh-CN.md` Roadmap row | — | new v0.18.1 row |
| `AI-GUIDE.md` | at v0.18.0 | **unchanged** (per AC-19) |
| `docs/dev-map.md` | at v0.18.0 | **unchanged** (per AC-19) |

`AI-GUIDE.md` and `docs/dev-map.md` freshness stamps are intentionally left at `at v0.18.0`
per design AC-19 — they describe the `verify_all` 30-check gate and the gap-tolerant I.6
matcher, both unchanged. Bumping those stamps would falsely imply a substantive change.

## Verify_all

Final delivery run results:

| Shell | Result |
|---|---|
| `bash scripts/verify_all.sh` | **PASS: 30 / WARN: 0 / FAIL: 0** |
| `pwsh -NoProfile -File scripts/verify_all.ps1` | **PASS: 30 / WARN: 0 / FAIL: 0** |

`test-verify-i6`:

| Shell | Result |
|---|---|
| `bash scripts/test-verify-i6.sh` | **PASS: 56 / FAIL: 0** (3-run stable) |
| `pwsh -NoProfile -File scripts/test-verify-i6.ps1` | **PASS: 56 / FAIL: 0** (3-run stable) |

`baseline.json` `test_verify_i6_ps_assertions` and `test_verify_i6_bash_assertions` both
bumped from 35/34 to **56/56**.

## Files touched (full diff)

```
.claude-plugin/marketplace.json                     |  2 +-
.claude-plugin/plugin.json                          |  2 +-
CHANGELOG.md                                        | 41 ++++++++++++++++
README.md                                           |  4 +-
README.zh-CN.md                                     |  4 +-
docs/features/i6-test-hardening/01_*..07_*.md       |  (new task folder, archived next)
docs/tasks.md                                       | row added (T-005)
scripts/baseline.json                               |  4 +-
scripts/test-verify-i6.ps1                          | +384 / -23 net +361
scripts/test-verify-i6.sh                           | +350 / -44 net +306
```

`scripts/verify_all.{ps1,sh}` are **byte-identical** to v0.18.0 (mutation cycle in QA
reverted cleanly).

## Known limitations / deferred work (recorded for future tasks)

- **MINOR — `local -n` portability** (`scripts/test-verify-i6.sh:499-500`). Bash 4.3+ floor;
  works on Git-bash (Windows ≥5.x) and modern Linux ≥4.4, would error on macOS default
  `/usr/bin/env bash` 3.2. The repo's de-facto target does not include macOS-default-shell,
  so this is non-blocking. Future maintenance pass should either add a one-line floor
  comment or refactor to inline expansion.
- **OUT-OF-SCOPE — `docs/manual-e2e-test.md:3`** still says `v0.17.4`. Per design §3, this
  was NOT touched in T-005. PM ships it as a separate trivial doc-consistency follow-up
  commit AFTER T-005 (per the user's original request).
- **OUT-OF-SCOPE — `architecture.html:326`** says `v0.17.4`. User explicitly declared this
  out of scope ("该文件本身带 v0.5/v0.6 snapshot caveat 并明确把刷新延后到 v0.18+ roadmap，
  按设计契约这次不动"). Honored — not touched.
- **OUT-OF-SCOPE — NLP / embedding-grade semantic matcher.** User explicitly declared this
  out ("远超本次"); design §3.2 of T-004 documents the threat-model trade-off (unintentional
  copy-paste drift, not active adversary). Not re-opened.

## Pipeline performance — for the supervisor's later analysis

- Rollbacks: **1** — Stage 3 Gate Review round 1 returned CHANGES REQUIRED on §9 of the
  design (wrong baseline 32/32 cited vs actual 35/34). PM applied the §9 patch directly
  (Option (b): empirical-equality contract) under user-delegated authority. Round 2 GR
  approved without further blockers; one in-cycle residual m-5 (§11 stale `PASS: 58`)
  was PM-patched in the same round.
- Stage doc sizes (lines): 01 = 558, 02 = 504, 03 = 250, 04 = 116, 05 = 141, 06 = 292,
  07 = (this file, ~120). 01 and 02 marginally over the 500 soft cap; archive-task at
  delivery will not compact (cap is WARN, not FAIL); they will live archived as-is.
- Insight-index unchanged at task end (per AC-19; no new insight surfaced).

## Insight

(No new insight — the T-005 implementation surfaced no surprise that warrants a new
`.harness/insight-index.md` line. The known insights L7/L17/L19/L20/L23/L24/L26/L27/L29
were all anticipated by design and successfully navigated. The closest candidate for a
new insight is the bash `local -n` portability concern, but that is a documented
known-limitation rather than a hard-won truth and lives in this 07 doc + CHANGELOG
Notes.)

## Delivery checklist

- [x] All 20 ACs satisfied (CR coverage matrix in `05_CODE_REVIEW.md`).
- [x] QA's 12-mutation adversarial cycle: all 12 detected, working tree clean post-cycle.
- [x] `verify_all` 30/30 PASS in both shells.
- [x] `test-verify-i6` 56/0 PASS in both shells, 3-run stable, monotonic over baseline.
- [x] `baseline.json` assertion counts updated.
- [x] `CHANGELOG.md` entry written.
- [x] Version stamps (4 G.3 sites) all match at `0.18.1`.
- [x] No edits to `scripts/verify_all.{ps1,sh}` (design §2 enforcement).
- [x] No edits to `architecture.html`, `docs/manual-e2e-test.md`, templates, `sync-self`,
      distributed skills (design §3 + user-declared out-of-scope).
- [ ] `archive-task` to be run by PM at the next step (after this doc commits to disk).
- [ ] tasks.md row to transition `delivery → done` after archive-task.
- [ ] Trivial follow-up commit for `docs/manual-e2e-test.md:3` v0.17.4 → v0.18.0 (sic —
      shipping the doc-consistency fix to match the freshness stamps' policy; will land in
      a separate commit AFTER this task's commits).
