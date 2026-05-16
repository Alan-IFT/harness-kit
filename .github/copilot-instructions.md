---
applyTo: "**"
---
<!-- THIS FILE IS GENERATED FROM .harness/rules/ — DO NOT EDIT DIRECTLY -->
<!-- Edit .harness/rules/*.md and run scripts/harness-sync.ps1 -->
# Harness Kit — Project Rules (self-dogfood)

> This repo **uses its own Harness setup**. The same 7-agent pipeline that we ship to users
> governs work on this repo. If we can't develop this repo with it, we shouldn't ship it.
>
> "Harness Engineering" remains the name of the methodology this project implements; the project
> itself is called **Harness Kit** (the distribution of skills + templates).

## Project type

**Tooling / Skills library + Claude Code Plugin** — not fullstack, not backend. It distributes
Claude Code skills and project templates. Build / test characteristics:

- Primary "code" is Markdown (Skill definitions, agent definitions, docs).
- Secondary code is PowerShell + Bash scripts (verify_all, install scripts).
- Templates under `skills/harness-init/templates/` are the **source of truth** for distributed assets.

## How development flows

Every non-trivial change → 7-agent pipeline (see [`docs/workflow.md`](docs/workflow.md)).

For this repo specifically, "non-trivial" means:
- New skill or template
- Change to any agent definition
- Change to verify_all or its checks
- Change to workflow or rules

Trivial (single typo, comment update, dependency bump): direct edit + `scripts/verify_all`.

## When in doubt

- Read `docs/concepts.md` to understand why a piece exists.
- Read `docs/workflow.md` for stage transitions.
- If a rule conflicts with the situation, stop and ask the user — don't improvise.

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

## Documentation rules

12. **README, CHANGELOG, docs/getting-started, docs/concepts** stay in sync with the actual code.
13. If you add a skill, document it in README's "Quick start" and CHANGELOG.
14. No documentation made-up examples; show real, runnable commands.
15. If you change a rule, also update any `docs/*.md` that referenced it.

## Software engineering basics

16. Commit messages in imperative mood, ≤72 char subject, body explains the why.
17. PR-able diffs: each commit is a coherent unit; don't bundle unrelated changes.
18. No commit of files in `参考/` (private reference folder, in `.gitignore`).
19. No commit of secrets, `.env`, or local user paths.
20. PowerShell and Bash scripts are symmetric — if you change one, change the other.

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
