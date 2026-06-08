# Insight history (rotated from .harness/insight-index.md)


## Rotated 2026-06-08

- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
- 2026-05-16 · Edit tool occasionally reports SUCCESS without applying the change — re-Read or Grep to verify. · evidence: v0.9.1 verify_all whitelist edit (commit 336e029); v0.10.0 60-tool-handoff.md template edit (commit 31fb520)

## Rotated 2026-06-08

- 2026-05-16 · Any new `{{...}}` placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails. · evidence: v0.9.1 SYNC_COMMAND addition
- 2026-05-16 · `sync-self` only syncs `.harness/agents/` + 4 specific scripts (harness-sync, install-hooks, archive-task) — NOT `.harness/rules/`. So dogfood rules are bespoke and template rules need separate edits when both change. · evidence: v0.9.0 onward
