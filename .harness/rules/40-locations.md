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
| Project repo navigation | `docs/dev-map.md` |
| Total verification | `scripts/verify_all.{ps1,sh}` |
| Binding sync (`.harness/agents/` + `.harness/skills/` → `.claude/`) | `scripts/harness-sync.{ps1,sh}` |
| Repo-self sync (`templates/` → `.harness/`) | `scripts/sync-self.{ps1,sh}` |
| Init regression | `scripts/test-init.{ps1,sh}` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |

## Verify before declaring done

`scripts/verify_all` checks (26 items at v0.14, all must PASS — count grows with releases):

- No secrets / committed env files
- `参考/` not tracked
- Required scaffolding present (README, LICENSE, CHANGELOG, CONTRIBUTING, installers)
- All 9 skills present with valid frontmatter
- All 7 template agents present
- Placeholder whitelist enforced (5 allowed)
- `.harness/agents/` matches `templates/common/.harness/agents/` (Layer 1)
- `.claude/agents/` + `.claude/skills/` match `.harness/` (Layer 2 binding)
- AI-GUIDE.md ↔ `.harness/rules/*.md` indexed both directions (no drift)
- Project rules / docs / evals present
- Script pairs (.ps1 + .sh) for verify_all / harness-sync / sync-self / test-init / test-real-project
- README and CHANGELOG reference all skills
- Version stamps consistent across `plugin.json` / `marketplace.json` / both README badges (G.3, v0.14.x+; FAIL on drift)
- `.harness/intervention.md` not tracked (ephemeral file; v0.13+)
- Document size soft caps (I.1-I.5, v0.14+; WARN-level)

Run after every change; do not skip.
