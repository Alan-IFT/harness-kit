# 06 — Test Report · test-supervisor-stamps (T-008)

> Stage 6. End-to-end + adversarial QA. Every tally below is from a captured run (L32). Git-bash = `C:\Program Files\Git\bin\bash.exe`. All adversarial mutations reverted; tree byte-identical to pre-QA baseline (per-file git-hash verified).

## Mechanical verification (AC → command → real result)

| AC | Command | Result |
|---|---|---|
| AC-1 | `pwsh verify_all.ps1` | **32/32 PASS · 0 WARN · 0 FAIL · RC 0**; G.4 present, LAST, PASS |
| AC-5 | `bash verify_all.sh` (clean) | **31 PASS · 1 WARN(I.4) · 0 FAIL · RC 1**; G.4 LAST, PASS. WARN is ONLY I.4 (`insight-index.md ≤30`), pre-existing |
| AC-1 | `pwsh test-supervisor.ps1` | **49 PASS / 0 FAIL · RC 0**; 3 structural fan-out asserts run, 8 stamp asserts gone |
| AC-2 | `bash test-supervisor.sh` | **45 PASS / 0 FAIL · RC 0**; same 3 structural asserts, symmetric |
| AC-3 | grep `0\.17\.1|0\.20\.0|vX.Y.Z|version-N|%2F|N checks` over both `test-supervisor.{ps1,sh}` | **0 hits in any assert.** Only matches are in file-header/BUG-2/NOTE comments — not release-tracking asserts |

I.4 WARN ≠ T-008 regression: T-008 touched none of insight-index.md / I.4 blocks / archive-task (verified vs the 12-file diff). Pre-existing PS/bash divergence per 05 Focus-5. baseline.json `test_init` 251/213 vs manual-e2e 227/191 = pre-existing unrelated drift; T-008 diff touches only `verify_all_checks` (31→32) + `test_supervisor_*` (57/53→49/45). No script reads those keys.

## Adversarial tests (REQUIRED — ≥1 per AC, independent reproducers, I tried to BREAK G.4)

| AC | Hypothesis ("expect failure when…") | Reproducer (I wrote/ran) | Outcome |
|---|---|---|---|
| AC-4a | version bump breaks test-supervisor | bump plugin.json `0.20.0→0.21.0`, run both test-supervisors | **Survived** — PS 49/0, SH 45/0 still GREEN (zero version dep = the core fix) |
| AC-4b/AC-6 | G.4 doesn't catch version drift | same bump, run verify_all both shells | **G.4 FAILed** both shells, identical list: AI-GUIDE×2, dev-map×2, 40-loc, manual-e2e all stale `v0.20.0`, + missing `[0.21.0]` CHANGELOG. PS RC=2 (G.3+G.4), SH RC=2 (G.4). Cross-shell symmetric |
| AC-6 | a count claim drifts unnoticed (7 of 11) | per-file `32→31`, run verify_all.ps1, revert | **G.4 FAILed naming each**: README:159 `(31 checks)`; README:5 `verify__all-31%2F31`; README.zh:159 `（31 项检查）`(F-7); baseline.json:10 `"verify_all_checks": 31`(F-5, substring, no JSON parse); AI-GUIDE:36 `31/31`; 40-loc:25 `(31 checks at v…`(F-1); dev-map:133 `runs all 31 checks (at v…)`(F-1b) |
| AC-6 neg | G.4 false-bumps historical rows | mutate README:260 `stays 99 checks` + README.zh:262 `仍 99 项检查`, run verify_all.ps1 | **Survived** — G.4 still PASS 32/32/0. Parenthesized/full-width patterns ignore bare history (F-3/F-7 discriminator holds) |
| AC-6 trip | a check added after G.4 miscounts silently | insert dummy `Step "Z.9"` after G.4, run verify_all.ps1 | **TRIPWIRE FAILed**: `G.4 is not the last recorded check (last='Z.9')`, RC=2 — mechanical backstop for the pin-comment works |
| AC-1/2 | kept structural assert is vacuous | widen canonical-7 glob to `…,supervisor` in SKILL.md, run test-supervisor.ps1 | **Caught** — `(not widened)` assert FAILed (48/1, RC=1). Structural asserts still meaningful |
| §4.1 | missing plugin.json passes silently | `mv plugin.json` aside, run verify_all.ps1 | **G.4 FAILed loudly**: `Cannot find path …plugin.json` (not silent), RC=2 |

Evidence pasted live above is from real tool output. **plugin.json restored to hash `de68738…`; verify_all.ps1 to `daedc06…`; SKILL.md to `b33454e…`; all 7 count-claim files to baseline hashes** after each probe.

## Regressions
- **G.4 broke nothing.** Baseline preserved: PS 31→32 (G.4 added), SH 31+1WARN→31+1WARN (G.4 added, status-independent count derived 32 from 31 PASS + 1 WARN — proves R4 anti-flicker). Test count UP (verify_all 31→32; baseline.json updated to 32 already by dev).
- **Stability:** test-supervisor.ps1 ×3 = 49/0 every run; verify_all.ps1 ×3 = 32/0/0 every run. No flakes. SH deterministic across 2 runs (only deterministic I.4 WARN).
- **Pre-existing, NOT T-008 (do not fix here):** (1) I.4 PS/bash WARN divergence (05 Focus-5); (2) baseline.json `test_init` vs manual-e2e drift (05 NIT). Both predate T-008 — spot-confirmed against the 12-file diff.

## verify_all result
- Total checks: 31 → **32** (G.4 added). PS **32 PASS / 0 WARN / 0 FAIL**. SH **31 PASS / 1 WARN(I.4) / 0 FAIL**. New gated checks: 1 (G.4). Baseline.json: already at 32 (dev), no QA edit needed. New tests added by QA: 0 production tests (G.4 is the standing gate; I added 7+ throwaway adversarial probes, all reverted).

## Final clean-tree confirmation
`git status` matches the pre-QA baseline exactly (12 modified + `docs/features/test-supervisor-stamps/` + `docs/system-overview.html` untracked). `git diff --stat` identical (215 ins / 64 del, same 12 files). All 11 probe-target files verified at baseline git-hash. verify_all back to baseline (PS 32/32, SH 31+1WARN). Zero residue.

## Verdict
The count/version doc-claim drift class is **dead at the gate**: test-supervisor carries zero release-tracking literals (survives a version bump green), and G.4 is demonstrably load-bearing — it FAILs on every version drift and on each of the 11 count claims individually, ignores historical rows, fails loudly on missing source, and its tripwire catches a misplaced check. All 6 ACs verified by independent reproducer.

**APPROVED FOR DELIVERY**
