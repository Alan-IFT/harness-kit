## What lives where

| Need | Look at |
|---|---|
| Distributed skills | `skills/<name>/SKILL.md` |
| Project templates (distribution source of truth) | `skills/harness-init/templates/` |
| Agent role definitions (this repo's source of truth) | `.harness/agents/` |
| Rule source files (this repo's source of truth) | `.harness/rules/` |
| Generated CLAUDE.md (do not edit) | `CLAUDE.md` |
| Generated .claude/ (do not edit) | `.claude/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Project repo navigation | `docs/dev-map.md` |
| Total verification | `scripts/verify_all.{ps1,sh}` |
| Binding sync (`.harness/` → `.claude/` + `CLAUDE.md`) | `scripts/harness-sync.{ps1,sh}` |
| Repo-self sync (`templates/` → `.harness/`) | `scripts/sync-self.{ps1,sh}` |
| Init regression | `scripts/test-init.{ps1,sh}` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |

## Verify before declaring done

`scripts/verify_all` checks (15+ items, all must PASS):

- No secrets / committed env files
- `参考/` not tracked
- Required scaffolding present (README, LICENSE, CHANGELOG, CONTRIBUTING, installers)
- All 4 skills present with valid frontmatter
- All 7 template agents present
- Placeholder whitelist enforced (5 allowed)
- `.harness/agents/` matches `templates/common/.harness/agents/` (Layer 1)
- `.claude/agents/` matches `.harness/agents/` (Layer 2 binding)
- `CLAUDE.md` matches `.harness/rules/*.md` composed (Layer 2 binding)
- Project rules / docs present
- evals/golden-tasks.md present
- Script pairs (.ps1 + .sh) for verify_all / harness-sync / sync-self / test-init
- README and CHANGELOG reference all skills

Run after every change; do not skip.
