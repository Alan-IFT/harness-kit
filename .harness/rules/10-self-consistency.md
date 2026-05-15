## Self-template consistency (red lines)

This repo dogfoods two layers of consistency:

### Layer 1: templates ↔ this repo

1. **The source of truth for the 7 agents and `harness-sync` scripts is `skills/harness-init/templates/common/`.**
2. The root `.harness/agents/` and `scripts/harness-sync.{ps1,sh}` are **byte-identical copies**.
3. If you change one, run `scripts/sync-self.{ps1,sh}` before commit.
4. `verify_all` step `E.1` checks this and FAILs on drift.

### Layer 2: .harness ↔ .claude (the binding)

5. **The source of truth for project-level Claude Code assets is `.harness/`** (agents, rules).
6. `.claude/agents/` and `CLAUDE.md` are **generated** from `.harness/` via `scripts/harness-sync.{ps1,sh}`.
7. **Never hand-edit** `.claude/agents/*.md` or `CLAUDE.md`. Edit `.harness/` and run sync.
8. `verify_all` step `E.4` and `E.5` check `.harness/ ↔ .claude/` and `.harness/rules/ ↔ CLAUDE.md` and FAIL on drift.

## Template integrity

9. **Every `.tmpl` file** must have its placeholders documented in `skills/harness-init/SKILL.md`.
10. Don't introduce a placeholder that the SKILL doesn't substitute.
11. Test the init flow after any template change via `scripts/test-init.{ps1,sh}`.
