# 05 — Code Review · test-supervisor-stamps (T-008)

> Stage 5. Independent read-only audit of 04 against 02 (§4 G.4 table, §5.1 ledger) + 03 conditions. Every claim verified at file:line. Persisted by PM (CR is read-only).

## Files reviewed
verify_all.ps1 (G.4 623-682, Summary/tripwire 684-714) / verify_all.sh (G.4 656-752, tripwire 754-777); test-supervisor.ps1 (413-435) / .sh (374-395); the 8 bumped docs + baseline.json; I.4 blocks + insight-index.md + archive-task.ps1 (negative controls: historical Roadmap/CHANGELOG/HTML rows).

## Focus 1 — G.4 correctness (both shells): CORRECT
- **Count status-independent + exact.** PS `$report.Count + 1` (ps1:643); bash `${#report[@]} + 1` (sh:673). Neither uses PASS count. `Step`/`step` append AFTER body (ps1:22-29 / sh:24), and G.4 reads the tally BEFORE its own terminal `step` call → `+1` accounts for G.4, no double-count. **Empirically proven by the SH run:** 31 PASS + 1 WARN = 32 steps, G.4 derived 32 and PASSed (a PASS-based count would have derived 31 and FAILed every doc).
- **G.4 is genuinely LAST** before Summary in both (ps1:682→684; sh:752→754); nothing appends after.
- **Pin-comment present both shells** (ps1:630-636 / sh:663-669), verbatim "G.4 MUST remain LAST / insert above". **Summary tripwire** (ps1:695-698 / sh:763-767) FAILs if `$report[-1].id != "G.4"` (`%%|*` extraction correct vs `id|name|status`). Stronger than required.
- **All 11 patterns match target + don't over-match** (verified vs live + historical negative controls): README `\(\d+ checks\)` matches `(32 checks)` not the bare Roadmap rows (256-268); zh `（\d+ 项检查）` matches `（32 项检查）` not bare zh rows (258-270); `"verify_all_checks": \d+` only in baseline.json:10; two badge patterns; AI-GUIDE/dev-map/40-locations/manual-e2e `\d+ checks at v…`; dev-map:133 `runs all \d+ checks \(at v…\)`; AI-GUIDE:36 `\d+/\d+ at v…`. Backtick-free (L19); PS/Bash 1:1 ordered (L13); version via plugin.json with loud FAIL if empty (mirrors G.3).

## Focus 2 — 8 removed / 3 kept (both shells): CORRECT, symmetric
3 structural asserts remain (`auxiliary.*supervisor` ps1:416-418/sh:377-379; harness-status row 429-431/390-392; canonical-7 glob 432-435/393-395); the 8 version/count asserts gone, replaced by an identical NOTE. Text-matched (plugin/marketplace transposition moot). Nothing else disturbed. Zero release-tracking literals remain.

## Focus 3 — 11 bumps to 32: ALL CORRECT, no historical bleed
Every live line reads 32 (AI-GUIDE:36 `32/32`,:69; dev-map:60,133; 40-locations:25 normalized items→checks; README:5,:159; README.zh:5,:159 `（32 项检查）` 30→32 double-jump; manual-e2e:3; baseline.json:10). No exempt claim bumped: CHANGELOG/Roadmap rows (EN+zh), tasks.md:21,22 `31/31 PASS`, system-overview.html ×4 + walkthrough.html:717, MIGRATION all unchanged. CHANGELOG `[0.20.0]` present → G.4 sub-check PASSes.

## Focus 4 — manual-e2e:3 self-tally + baseline.json:13,14: CORRECT
manual-e2e:3 = `ps1 49 / .sh 45` matches the captured post-removal run + baseline.json:13/:14. Legitimate machine-twin sync (§5.1 same metric class, §9-R6 mandate), gate-safe (no script reads these keys). (baseline.json:11,12 test_init 251/213 vs manual-e2e 227/191 = PRE-EXISTING unrelated drift, correctly left alone.)

## Focus 5 — I.4 cross-shell WARN: out-of-scope-but-real (recommend follow-up)
- **(a) Genuine PS/Bash divergence (L13 class).** insight-index.md is 32 physical lines (header 1-9 + 23 bullets). I.4 caps `>30` TOTAL lines. bash `wc -l` (sh:419) = 32 → WARN (CORRECT — file really is over cap). PS `Measure-Object -Line` (ps1:398) under-counts → PASS (WRONG, silently passes an over-cap file). **bash is right.**
- **(b) Pre-existing, NOT T-008.** T-008 touched none of insight-index.md / I.4 blocks / archive-task. Separate latent root cause: `archive-task.ps1:71` rotates on DATA lines only (`^\s*-\s+` → 23) while I.4 caps TOTAL lines (~32) — different quantities, so the index sits permanently over the cap while archive-task never rotates.
- **(c) In-scope? NO** — insight-index.md isn't a T-008 file; the design never scopes it. Dev's leave-and-flag is correct.
- **Verdict: out-of-scope-but-real → follow-up.** Two items for backlog: (1) L13 symmetry fix (PS under-counts); (2) align I.4 cap with archive-task's rotation metric so the WARN drives rotation.

## Focus 6 — scope discipline: CLEAN
settings.json untouched; no relocation; HTML/CHANGELOG/MIGRATION/Roadmap unchanged; only expected files (2 verify_all, 2 test-supervisor, 8 docs, baseline.json) edited; no upstream-doc edits.

## Findings
- **BLOCKER:** none. **MAJOR:** none.
- **MINOR [SYMMETRY]** verify_all I.4 PS-vs-bash count divergence (ps1:398 vs sh:419) — pre-existing, out of T-008 scope, recommend follow-up (the focus-5 adjudication). Not a T-008 defect, does not block.
- **NIT [MAINT]** G.4 load-bearing test is whole-file substring (ps1:666/sh:732), not line-anchored — safe today (every expected string uniquely shaped) but a future prose `(32 checks)` elsewhere would satisfy the wrong line. No action.
- **NIT [STYLE]** baseline.json:11,12 test_init (251/213) vs manual-e2e:3 (227/191) — pre-existing unrelated drift, noted so it's not mistaken for a T-008 regression.

## Verdict
G.4 correctly implemented both shells (status-independent `+1`, genuinely last, binding pin-comment, working tripwire); all 11 claims at 32 with no historical bleed (verified vs negative controls); 8/3 split symmetric + text-matched; R6 self-tally recount + baseline.json:13,14 sync legitimate + gate-safe. The lone real finding (I.4 PS/bash divergence) is pre-existing and out of scope.

**CODE REVIEW VERDICT: APPROVED** — G.4 sound and symmetric, all 11 claims at 32 with no historical bleed, asserts split correctly; only finding (I.4 PS/bash count divergence) is pre-existing + out of scope → recommend follow-up.
