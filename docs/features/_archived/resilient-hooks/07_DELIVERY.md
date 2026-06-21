# 07 — Delivery · T-12 `resilient-hooks` (v0.44.0)

**Verdict: DELIVERED**
**Final verify_all result: PASS (32/0/0, Bash)**

## What shipped

A real consumer bug fix: the per-turn `Stop hook error: bash: .harness/scripts/harness-sync.sh: No such file or directory` is eliminated by design, not patched.

### Slice A — resilient lifecycle hooks (fail-open + cwd-anchored)

The harness convenience hooks (Stop/harness-sync, UserPromptSubmit/ambient-prompt, SessionStart/ambient-reset) now use a **split-anchor** command form: a runtime `cd "$CLAUDE_PROJECT_DIR"` / `Set-Location` anchor (cwd-independent — survives launch from a subdirectory) plus a presence guard so a missing/unreachable script **no-ops silently (exit 0, no stderr)** instead of erroring every turn.

- Unix convenience: `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/<name>.sh ] && exec bash .harness/scripts/<name>.sh || exit 0'`
- Windows convenience: `pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/<name>.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/<name>.ps1 }; exit 0"`

The **guard-rm** PreToolUse hook stays **fail-CLOSED** (the safety non-negotiable): SAME `$CLAUDE_PROJECT_DIR` anchor for cwd-robustness but **NO `|| exit 0`** — a missing/unreachable guard produces a non-zero exit, never silently allows a destructive command.

Applied to: the distributed template `settings.json.tmpl` + the `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` derivation in harness-init / harness-adopt; the dogfood settings; and a `/harness-upgrade` + `migrate-scripts-layout` **repair path** (S3.2) that rewrites EXISTING projects' brittle hooks to the resilient form (idempotent, target-gated, `.bak`-backed).

### Slice B — stop distributing dogfood hooks

This repo's root `.claude/settings.json` is now **hook-less** (`hooks: {}`); the dev/dogfood hooks moved to gitignored `.claude/settings.local.json` (the correct, never-distributed home). `.gitignore` now ignores `settings.local.json` explicitly (the pre-existing `*.local` did NOT cover it). verify_all **F.2** reads the guard-rm evidence from settings.local.json with a settings.json fallback; **J.1** adds settings.local.json as a schema target.

## Why this is the design fix, not a guard

The root cause was a brittle relative-path hook with no existence guard (T-020 only ensured the script *lands*; it never made the hook itself resilient — so it did nothing for pre-v0.31.0 projects, subdir launches, or any later disappearance). The hook now **degrades gracefully by construction**. No new verify_all check was added (honors feedback_design_over_guards) — check count held at 32.

## The load-bearing decision (OQ-3)

The E.4b/D.4b hook↔script congruence scans extract the script path with an ERE whose boundary class is `["' =]` (no `/`) and check existence cwd-relative. A `$CLAUDE_PROJECT_DIR/`-prefixed path would be **invisible** to that scan (silent T-020 regression). The chosen `cd`-anchor + space-preceded **bare** `.harness/scripts/<name>.<ext>` token keeps the existing ERE + `[[ -f ]]` working unchanged → the 6 E.4b/D.4b templates are **0-edit verify-only**. Gate hand-traced this true on both shells.

## Verification

- `verify_all.sh` **32 / 0 / 0** (final PM gate + dev + QA, all green).
- Bash regression suite (QA): test-init.sh 278/0 · test-harness-upgrade.sh 89/0 (incl. new Fixture Z fail-closed mutation probe) · test-real-project.sh 90/0 · test-supervisor.sh 45/0 · test-language.sh 39/0 · test-verify-i6.sh 58/0.
- QA validated the 4 user-observable behaviors with real Bash repros: (1) absent Stop script → rc=0, no stderr (control: brittle form still gives the exact consumer error at rc=127); (2) subdir launch → anchored resolve + run; (3) guard-rm fail-CLOSED both present (rc=2 BLOCKED) and absent (rc=127); (4) empty-`$CLAUDE_PROJECT_DIR` → guard still runs / fails non-zero, never silently skipped.
- AC-5 fail-closed runtime mutation now codified as **Fixture Z** (deletes guard-rm, asserts non-zero) — closes the CR's "no codified mutation probe" nit.
- Version 0.44.0 fan-out consistent (plugin.json, marketplace.json, both READMEs, CHANGELOG `## [0.44.0]`). No count flip (skills 17 / agents 8 / checks 32).

## Operator-pending (PowerShell denied to agents — green-by-symmetry, NOT executed)

Run on a Windows shell before the next release tag: `verify_all.ps1` (expect 32/0/0), `test-init.ps1`, `test-harness-upgrade.ps1` (expect +3 for Fixture Z, then bump `test_harness_upgrade_ps_assertions` in baseline.json), `test-real-project.ps1`. Spot-check `Get-ResilientCmd` exact bytes + `.Replace()` literal substitution keeping `& pwsh`/`$env:` intact.

## Pipeline trail

01 RA READY → 02 SA READY → 03 Gate APPROVED-WITH-CONDITIONS (C1–C4) → 04 Dev IMPLEMENTED (32/0/0) → 05 CR APPROVED-WITH-NITS → post-CR fidelity fix (3 brittle-fixture sites → resilient; AC-7 fully met) → 06 QA PASS (Fixture Z added).

## Insight

- 2026-06-21 · bash 5.2 enables `patsub_replacement` BY DEFAULT, so in `${var//needle/repl}` an unescaped `&` in the REPLACEMENT expands to the matched text — silently corrupting any dogfood string substitution whose replacement contains a literal `&` (here the resilient hook JSON's `& pwsh -NoProfile -File ...` collapsed the `&` into the needle text, producing invalid hook JSON in real upgrades). PowerShell `.Replace()` is ordinal-literal and unaffected, so the corruption is bash-only and invisible to a within-PS check — another member of the cross-shell-parity family. Fix: a split-on-needle + concatenate literal-replace helper (`str_replace_all` / `ti_replace_all`) instead of `${var//}` for any value that may contain `&` (or escape `&`→`\&` in the replacement). · evidence: T-12 dev + 05_CODE_REVIEW adjudication, upgrade-project.sh / migrate-scripts-layout.sh str_replace_all + test-init.sh ti_replace_all
