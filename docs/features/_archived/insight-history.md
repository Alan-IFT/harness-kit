# Insight history (rotated from .harness/insight-index.md)


## Rotated 2026-06-08

- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
- 2026-05-16 · Edit tool occasionally reports SUCCESS without applying the change — re-Read or Grep to verify. · evidence: v0.9.1 verify_all whitelist edit (commit 336e029); v0.10.0 60-tool-handoff.md template edit (commit 31fb520)

## Rotated 2026-06-08

- 2026-05-16 · Any new `{{...}}` placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails. · evidence: v0.9.1 SYNC_COMMAND addition
- 2026-05-16 · `sync-self` only syncs `.harness/agents/` + 4 specific scripts (harness-sync, install-hooks, archive-task) — NOT `.harness/rules/`. So dogfood rules are bespoke and template rules need separate edits when both change. · evidence: v0.9.0 onward

## Rotated 2026-06-09

- 2026-05-16 · `declare -a foo` under `set -u` in bash crashes when `${#foo[@]}` is read with zero elements; use `foo=()` instead. Latent bug existed in `sync-self.sh` + `harness-sync.sh` from inception until v0.13.0 — PS verify_all hid it because it ran the .ps1 version. · evidence: v0.13.0 commit d9db0a4
- 2026-05-16 · Releases (v0.13.0, v0.14.0) shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values; no check forced the bump. G.3 now catches plugin/marketplace/README version drift at FAIL, but skill-count and check-count claims still need manual sync. · evidence: commit e71d620 (doc resync) + follow-up G.3 addition

## Rotated 2026-06-09

- 2026-05-16 · One-sided assertions hide bidirectional drift: test-init asserted "50-<type>.md is indexed in AI-GUIDE" but not the inverse "every rule file is indexed". When v0.13/v0.14 added new rule files, the user-project verify_all E.5 would have FAILed on first init-run, but our regression suite stayed green. When asserting set-membership in templates, write the inverse check too. · evidence: AI-GUIDE template missing 65-intervention + 70-doc-size (zh) for 1-2 releases
- 2026-05-17 · PowerShell `-contains` is case-insensitive by default, so a flag-skip list containing `-path` will match `Remove-Item -Path ...` and create a destructive-command bypass — use `-ccontains` for case-sensitive flag lists, or scope flag-skip arrays to the specific verb that needs them. · evidence: T-001 rollback #1, commit (this delivery)

## Rotated 2026-06-09

- 2026-05-17 · Claude Code's PreToolUse hook spawns pwsh per call; without `-NoProfile` the user's `$PROFILE` runs each time and dominates wall-clock (measured 3.7s p50 vs 10ms script body). Always pass `-NoProfile` to any pwsh hook command in `.claude/settings.json`. · evidence: T-001 QA p50 measurement, commit (this delivery)

## Rotated 2026-06-10

- 2026-05-19 · An architectural retirement (e.g. v0.10 stopped composing CLAUDE.md from rules) can leave stale claims scattered across 8+ files (docs / templates / README / CONTRIBUTING) for many releases — code matches reality but docs lie. CHANGELOG entries describing the retirement do not protect against future contributors copy-pasting old phrasings. A literal-substring banned-phrase guard in `verify_all` (I.6 at v0.15.1, ~50 lines/shell, with a small history exemption list for CHANGELOG / _archived/ / labeled-snapshot HTMLs) closes the recurrence vector with negligible ongoing cost — add a line when retiring a claim, remove the line when the claim becomes accurate again. · evidence: v0.15.1 doc-resync, this delivery

## Rotated 2026-06-11

- 2026-05-19 · PowerShell here-doc and array-of-hashtable literals: backtick is the PS escape char inside double-quoted strings, so `"foo `CLAUDE.md`"` is a parser error. Use single quotes for any string containing literal backticks: `'foo `CLAUDE.md`'`. Affects banned-phrase / drift-detection arrays where you want to match literal markdown code spans. · evidence: I.6 first run, this delivery
- 2026-05-19 · PowerShell `-notin` (default operator) is case-INSENSITIVE; the symmetric case-sensitive variant is `-cnotin`. A D.2-style whitelist check that uses `-notin` will silently let `{{stack}}` through if `{{STACK}}` is in the whitelist. Same bug class as v0.15.0's `-contains` rollback. Always use `-cnotin` / `-ccontains` for case-sensitive placeholder / flag whitelists. · evidence: T-002 round-2 rollback, .harness/scripts/verify_all.ps1:101 (post-fix)
