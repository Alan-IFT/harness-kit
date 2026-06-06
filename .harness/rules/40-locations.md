## What lives where

| Need | Look at |
|---|---|
| Distributed skills | `skills/<name>/SKILL.md` |
| Project templates (distribution source of truth) | `skills/harness-init/templates/` |
| Agent role definitions (this repo's source of truth) | `.harness/agents/` |
| Rule source files (this repo's source of truth) | `.harness/rules/` |
| Stub CLAUDE.md (do not edit; ~15 lines, references AI-GUIDE.md) | `CLAUDE.md` |
| Generated .claude/ (do not edit; synced from `.harness/agents/` + `.harness/skills/`) | `.claude/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Supervisor agent (auxiliary, v0.17+; not part of 7-stage routing) | `.harness/agents/supervisor.md` |
| Supervisor skill (manual invocation, v0.17+) | `skills/harness-supervise/SKILL.md` |
| Project repo navigation | `docs/dev-map.md` |
| Total verification | `.harness/scripts/verify_all.{ps1,sh}` |
| Binding sync (`.harness/agents/` + `.harness/skills/` → `.claude/`) | `.harness/scripts/harness-sync.{ps1,sh}` |
| Repo-self sync (`templates/` → `.harness/`) | `.harness/scripts/sync-self.{ps1,sh}` |
| Init regression | `.harness/scripts/test-init.{ps1,sh}` |
| Supervisor regression (v0.17+) | `.harness/scripts/test-supervisor.{ps1,sh}` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |

## Verify before declaring done

`.harness/scripts/verify_all` checks (32 checks, all must PASS — count grows with releases):

- No secrets / committed env files
- `参考/` not tracked
- Required scaffolding present (README, LICENSE, CHANGELOG, CONTRIBUTING, installers)
- All 12 skills present with valid frontmatter
- All 7 template agents present
- Placeholder whitelist enforced (7 allowed)
- `.harness/agents/` matches `templates/common/.harness/agents/` (Layer 1)
- `.claude/agents/` + `.claude/skills/` match `.harness/` (Layer 2 binding)
- AI-GUIDE.md ↔ `.harness/rules/*.md` indexed both directions (no drift)
- Project rules / docs / evals present
- Script pairs (.ps1 + .sh) for verify_all / harness-sync / sync-self / test-init / test-real-project
- Guard-rm scripts + `.claude/settings.json` PreToolUse wiring (F.2, v0.15+; FAIL if missing)
- README and CHANGELOG reference all skills
- Version stamps consistent across `plugin.json` / `marketplace.json` / both README badges (G.3, v0.14.x+; FAIL on drift)
- `.harness/intervention.md` not tracked (ephemeral file; v0.13+)
- Document size soft caps (I.1-I.5, v0.14+; WARN-level)
- Retired-claim phrase guard (I.6, v0.15.1+; gap-tolerant ordered-anchor scan since v0.18; FAIL if any banned phrase from past architectural retirements resurfaces in a live file)
- AI-generated `50-*.md` sanity (D.3, v0.16.0+; FAIL if a `50-*.md` rule fragment is missing any of the six required headings, leaks a `{{...}}` placeholder, or has a non-template `##`/`###` section without a `<!-- source: ... -->` annotation)
- Ignored INTERVENE supervision reports (I.7, v0.17.0+; WARN if a `docs/features/<slug>/SUPERVISION_REPORT.md` has `Verdict: INTERVENE` AND the slug is an active row in `docs/tasks.md` AND the file mtime is >48h old)

Run after every change; do not skip.
