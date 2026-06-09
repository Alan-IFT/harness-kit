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
