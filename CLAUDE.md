# Harness Engineering — Project Rules (self-dogfood)

> This repo **uses its own Harness setup**. The same 7-agent pipeline that we ship to users
> governs work on this repo. If we can't develop this repo with it, we shouldn't ship it.

## Project type

**Tooling / Skills library** — not fullstack, not backend. It distributes Claude Code skills
and project templates. Build / test characteristics:

- Primary "code" is Markdown (Skill definitions, agent definitions, docs).
- Secondary code is PowerShell + Bash scripts (verify_all, install scripts).
- Templates (`.tmpl`, `.append`) under `skills/harness-init/templates/` are the **source of truth** for distributed assets.

## How development flows

Every non-trivial change → 7-agent pipeline (see [`docs/workflow.md`](docs/workflow.md)).

For this repo specifically, "non-trivial" means:
- New skill or template
- Change to any agent definition
- Change to verify_all or its checks
- Change to workflow or rules

Trivial (single typo, comment update, dependency bump): direct edit + `scripts/verify_all`.

## Hard rules (red lines)

### Self-template consistency
1. **The source of truth for the 7 agents is `skills/harness-init/templates/common/.claude/agents/`.**
2. The root `.claude/agents/` (used to dogfood this repo) is a **byte-identical copy**.
3. If you change one, you **must** sync to the other before commit. Use `scripts/sync-self.ps1` / `.sh`.
4. `verify_all` checks consistency and FAILs on drift.

### Template integrity
5. **Every `.tmpl` file** must have its placeholders documented in `skills/harness-init/SKILL.md`.
6. Don't introduce a placeholder that the SKILL doesn't substitute.
7. Test the init flow on a scratch folder after any template change (golden task #1).

### Documentation
8. **README, CHANGELOG, docs/getting-started, docs/concepts** stay in sync with the actual code.
9. If you add a skill, document it in README's "Quick start" and CHANGELOG.
10. No documentation made-up examples; show real, runnable commands.

### Software engineering basics
11. Commit messages in imperative mood, ≤72 char subject, optional body explains the why.
12. PR-able diffs: each commit is a coherent unit; don't bundle unrelated changes.
13. No commit of files in `参考/` (it's a private reference folder, in `.gitignore`).
14. No commit of secrets, `.env`, or local user paths.

## What lives where

| Need | Look at |
|---|---|
| Distributed skills | `skills/<name>/SKILL.md` |
| Project templates (source of truth) | `skills/harness-init/templates/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Agent role definitions | `.claude/agents/` (copies from templates) |
| Sync templates → root | `scripts/sync-self.ps1` / `.sh` |
| Total verification | `scripts/verify_all.ps1` / `.sh` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |

## Verify before declaring done

`scripts/verify_all` checks:

- Markdown: lint, broken internal links
- Shell scripts: shellcheck-style sanity
- Templates: all referenced placeholders are valid
- **Self-template consistency**: root `.claude/agents/` matches `skills/harness-init/templates/common/.claude/agents/`
- Required files present (README, LICENSE, CHANGELOG, install scripts)
- No secrets / env files committed

Run after every change; do not skip.

## When in doubt

- Read `docs/concepts.md` to understand why a piece exists.
- Read `docs/workflow.md` for stage transitions.
- If a rule conflicts with the situation, stop and ask the user — don't improvise.
