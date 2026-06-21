# Code Review — T-12 `resilient-hooks` (v0.44.0)

> Persisted by PM from the read-only code-reviewer's return (code-reviewer has no Write tool). Two-axis review (Standards-conformance + Spec/design-fidelity as separate lenses).

## Files reviewed (read in full or in the load-bearing sections)

- `.claude\settings.json` (committed dogfood — hooks stripped)
- `.claude\settings.local.json` (NEW gitignored dogfood hooks)
- `.gitignore`
- `skills\harness-init\templates\common\.claude\settings.json.tmpl`
- `skills\harness-init\SKILL.md` (step-5 derivation table)
- `skills\harness-adopt\SKILL.md` (step-6 table)
- `.harness\scripts\upgrade-project.sh` + `.ps1` (repo + template-common)
- `.harness\scripts\migrate-scripts-layout.sh` + `.ps1` (repo + template-common)
- `.harness\scripts\verify_all.sh` (F.2 + J.1)
- `.harness\scripts\test-init.sh` + `.ps1` (literals + `test_migrate` + `Test-ZhOverlay`)
- `.harness\scripts\test-harness-upgrade.sh` (Fixtures A/H/I/P/M + `t20_pick`)
- `.harness\scripts\test-real-project.sh` + `.ps1`
- `.claude-plugin\plugin.json`, `marketplace.json`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[MAINT] `test-real-project.sh:42-51` and `test-real-project.ps1:111-114` — brittle `*_COMMAND` substitution at a live authoring site.** Both shells of the "real project" integration test substitute the four `{{...}}_COMMAND` placeholders with the OLD brittle form (`pwsh -File .harness/scripts/harness-sync.ps1` / `bash .harness/scripts/harness-sync.sh`), NOT the resilient form. This is not an OLD-form fixture meant to be upgraded — it builds the fixture's *final* settings that the test then treats as a healthy distributed project. Result: the integration test that is supposed to dogfood "a project built from the distributed templates" no longer reflects the form `harness-init` actually produces. It does not fail any gate (the test only checks token-congruence + file preservation, never the resilient form), which is exactly why it slipped through the bash-only run. Recommend switching these to the resilient literals (reuse the `test-init.{sh,ps1}` literal block).

- **[MAINT] `test-init.ps1:713-716` (`Test-ZhOverlay`) — brittle `*_COMMAND` substitution.** Same class as above: the zh-overlay i18n test substitutes the brittle form. Benign for that test's purpose (it validates language-policy composition, not hooks) but inconsistent with the resilient literals used everywhere else in the same file (105-113, 588-589).

- **[REQ-FIDELITY] `04_IMPLEMENTATION.md` AC-7 self-report is inaccurate.** The dev wrote "no surviving brittle convenience form for the authoring sites (the only bare-brittle literals remaining are the OLD-form FIXTURES and the S3.2 needles)." That is false — the three sites above are live substitution authoring sites producing brittle hooks, not OLD-form fixtures. AC-7's own wording ("a grep over the authoring sites shows no surviving brittle form for the convenience hooks") is therefore not fully met. The product is unaffected; the gap is in test fidelity + the accuracy of the claim.

### NIT

- **[STYLE] `README.md:5` / `README.zh-CN.md:5` — `test-init-314/314` badge vs dev-reported `test-init.sh 278/0`.** The badge number (314) differs from the bash run count (278). This is likely a pre-existing aggregate convention (sum across types/shells) and was not introduced by this task, but it is worth a glance on the operator's PS run to confirm it is not stale.

- **[TEST] AC-5 has no codified runtime mutation probe.** The fail-closed safety invariant is asserted *structurally* (no `exit 0` on guard-rm command lines, in Fixture A `test-harness-upgrade.sh:189` and `test_migrate` `test-init.sh:599`) and is guaranteed by construction. The dev claims AC-5 was "runtime-verified: missing guard-rm → rc=127" but no committed test deletes guard-rm and asserts a destructive call is blocked. The structural assertion + design construction make this safe; codifying the mutation would be a strengthening, not a fix.

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 fail-open (missing convenience → rc=0, no stderr) | resilient_cmd convenience form `... \|\| exit 0`; `settings.local.json:8` | PASS |
| AC-2 anchor (subdir launch resolves) | `cd "$CLAUDE_PROJECT_DIR"` / `Set-Location`; Fixture H real-run probe `test-harness-upgrade.sh:367` | PASS |
| AC-3 both OSes exact strings | `resilient_cmd`/`Get-ResilientCmd` both shells; matches design §3.5 byte-for-byte | PASS |
| AC-4 ambient parity | ambient-prompt/-reset same fail-open form; `settings.local.json:14,17` | PASS |
| AC-5 guard-rm fail-CLOSED | guard form has NO `\|\| exit 0`/`exit 0` (all 4 forms); `settings.local.json:11`; asserts `test-harness-upgrade.sh:189`, `test-init.sh:599` | PASS |
| AC-6 template resilient + J.1 | `.tmpl` placeholders intact; J.1 targets incl. settings.local.json `verify_all.sh:657` | PASS |
| AC-7 derivation lockstep | init step-5 + adopt step-6 + upgrade/migrate `ph_cmd`/S3.2 all resilient | MINOR (3 test-fixture authoring sites still brittle) |
| AC-8 repair (brittle→resilient) | S3.2 upgrade + migrate; Fixture A/H resilient asserts `:186,:360` | PASS |
| AC-9 B1/B2 move | `settings.json:21` `hooks: {}` + `_hooks_moved`; `settings.local.json` carries 4 | PASS |
| AC-10 gitignore | `.gitignore:60` `.claude/settings.local.json` | PASS |
| AC-11 verify_all unaffected | F.2 fallback `verify_all.sh:303-321`; J.1 target add | PASS |
| AC-12 ripple (token still parseable) | space-bounded `.harness/scripts/<tool>.<ext>` preserved in all forms; ERE unchanged | PASS |
| AC-13 gate 32/32 | verify_all.sh 32/0/0 (PS operator-pending) | PASS (bash) / pending (PS) |
| AC-14 count/version | 0.44.0 fan-out consistent; no count flip | PASS |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| `cd`/`Set-Location` anchor shape (NOT `$CLAUDE_PROJECT_DIR/`-prefix) — §3.2 | All forms use the split-anchor shape | PASS |
| Convenience fail-open `\|\| exit 0` / `; exit 0` — §3.3 | Confirmed both shells | PASS |
| guard-rm fail-CLOSED, no fallback, no `-EA SilentlyContinue` on its Set-Location — §3.4 | Confirmed all 4 forms | PASS |
| JSON-escaped literals byte-match §3.5 | settings.local.json + test literals + script output all match | PASS |
| S3.2 brittle→resilient adapter, target-gated, idempotent (double-quote-bounded needle) — §4.3 | upgrade.sh:326-345, migrate.sh:180-197, both PS twins | PASS |
| C1 8-file byte-identity (sync-self / E.1) | upgrade.sh, migrate.ps1 pairs confirmed identical by full read; dev reports E.1 PASS | PASS |
| `-NoProfile` retained on every pwsh hook (NFR-Perf) | outer `-Command` + inner `-File` both carry it | PASS |
| F.2 settings.local.json fallback — §8-[5]/R5 | verify_all.sh:303-321 | PASS |
| **NEW helper `str_replace_all` (not in design)** | ampersand-safe; applied at every `&`-bearing build site | PASS (defect-prevention) |

## The two dev-flagged adjudications

### 1. Empty-`$CLAUDE_PROJECT_DIR` drift — SAFE (both halves)

The dev observed `cd ""` stays in cwd and succeeds on his bash (vs OQ-2a's "fails" assumption). Adjudication, traced for all four code paths:

- **Convenience (bash):** if `cd ""` succeeds → runs harness-sync against cwd; if it fails → `|| exit 0`. Either way exit 0, fail-open preserved, never points at FS root. SAFE.
- **Convenience (pwsh):** `Set-Location -LiteralPath '' -EA SilentlyContinue` no-ops or stays put; `; exit 0` terminator guarantees exit 0. SAFE.
- **guard-rm (bash):** `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`. If `cd ""` succeeds → `&&` proceeds → **guard-rm RUNS** (relative to cwd; blocks/allows correctly, or exits 127 if absent). If `cd ""` fails → `&&` short-circuits → `sh -c` exits non-zero → **fail-closed**. In neither branch is the guard silently skipped. SAFE.
- **guard-rm (pwsh):** `pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"`. `-Command` runs under default `$ErrorActionPreference=Continue`, so `Set-Location -LiteralPath ''` emits a non-terminating error and execution **continues** to `; & pwsh -File guard-rm.ps1`, which RUNS (the guard's own exit code governs; 127-equivalent if the file is missing → fail-closed). The guard is never silently skipped. SAFE.

**Conclusion:** the drift only affects the degenerate empty-var case of the *convenience* hooks (they may run against cwd instead of no-op'ing — harmless, harness-sync is cwd-robust and the path is fail-open regardless). The fail-CLOSED guard half is intact in both shells: empty-var can never make guard-rm silently NOT run. No safety regression. The dev's "no code change, flag for awareness" decision is correct.

### 2. `str_replace_all` ampersand-safe helper — CORRECT and applied at EVERY site

The helper (`upgrade-project.sh:124`, `migrate-scripts-layout.sh:138`, `ti_replace_all` `test-init.sh:65`) splits on the needle and concatenates via plain expansion (`out="$out${rest%%"$needle"*}$repl"`), so `$repl` — which contains the literal `& pwsh` — is never subject to `${var//}`'s `&`-means-matched-text rule. The logic is correct (verbatim literal replace, neither needle nor repl treated as a pattern).

Coverage of every `&`-bearing-JSON build site:
- **upgrade-project.sh:** S3.0 placeholder repair (`:284`) and S3.2 brittle→resilient (`:341`) both call `str_replace_all`. ✅
- **migrate-scripts-layout.sh:** S3.2 (`:194`) calls `str_replace_all`. ✅
- **test-init.sh:** all four `{{...}}_COMMAND` substitutions (`:92-95`) call `ti_replace_all`. ✅
- **PS twins (upgrade.ps1 `:288,:339`, migrate.ps1 `:137,:169`):** use `.Replace()`, ordinal-literal — ampersand-safe by construction. ✅
- A grep for residual `${var//}` usage in all four bash scripts returns only comment references — no live `${//}` substitution of an `&`-bearing value remains anywhere. ✅

**Conclusion:** no missed site; no corrupted-hook-JSON risk in real upgrades. The helper is a legitimate defect-prevention addition.

## Specific confirmations requested

- **C1 byte-identity (8 files):** confirmed by full-read comparison for `upgrade-project.sh` (repo == template-common) and `migrate-scripts-layout.ps1` (repo == template-common, identical 269 lines); `resilient_cmd`/`Get-ResilientCmd`/S3.2 bodies identical across all pairs by grep. Dev reports `sync-self --check` = "In sync." and E.1 PASS. C1 holds (PS execution operator-pending).
- **C4 F.2 still fails-closed on a truly-missing guard:** the script-presence loop (`verify_all.sh:292-296`) is unchanged — a missing `guard-rm.{ps1,sh}` file still appends `missing:...` → F.2 FAIL. The settings.local.json fallback only redirects *where the PreToolUse wiring is read from*; it did NOT weaken the missing-guard detection. C4 intact.
- **guard-rm has NO `|| exit 0` in any of its 4 forms:** confirmed. The only `guard-rm` + `exit 0` co-occurrences are in comments and in test assertions that verify the absence; never in an actual guard command string.
- **No count-flip:** skills 17 / agents 8 / checks 32 unchanged (AI-GUIDE.md:74 still "32 checks"; no new check added).
- **Version 0.44.0 consistent:** plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5, CHANGELOG.md:8 (`## [0.44.0] - 2026-06-21`). No stray active 0.43.0.
- **No line-cap breach observed** in the reviewed files.

## Guard-rm fail-closed safety: INTACT.

The single non-negotiable (NFR-Safety) holds in all four forms and across the degenerate empty-`$CLAUDE_PROJECT_DIR` case in both shells.

## Verdict

**APPROVED-WITH-NITS**

No CRITICAL, no MAJOR. The shipped product (the resilient hook strings, the repair path, the dogfood relocation, the gate wiring) is correct and faithful to the design on both axes. The fail-CLOSED safety guarantee for guard-rm is verified intact, including under the empty-var drift the dev honestly flagged. Both dev-flagged items adjudicate as SAFE/CORRECT.

The only blemishes are MINOR test-fidelity gaps: three test-fixture substitution sites (`test-real-project.sh`/`.ps1`, `test-init.ps1` `Test-ZhOverlay`) still author the brittle command form, which makes the dev's AC-7 self-report inaccurate and slightly weakens the "real project" integration test's dogfooding value. None affect the product or any gate. Recommend (non-blocking) switching those three sites to the resilient literals, and confirming the operator-pending PowerShell run before merge per repo convention.

**Routing note for PM:** the three brittle-fixture sites are MINOR and may be merged-then-fixed or fixed-now at PM discretion; they are not a blocker. The PS-run confirmation is the only true pre-merge gate item still open.
