---
name: harness-init
description: Bootstrap a new project with the full Harness Engineering skeleton — tool-agnostic .harness/ source-of-truth layer plus the Claude Code binding (.claude/ + CLAUDE.md). Use this when starting a fresh fullstack or backend project that wants AI-driven development from day one.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-init

Bootstrap a new project with the complete Harness skeleton, so that Claude Code can run
the 7-agent pipeline (PM → Analyst → Architect → Gate → Developer → Reviewer → QA)
out of the box.

The skeleton uses a **two-layer model**:

- `.harness/` is the tool-agnostic source of truth (agents, rules, skills).
- `.claude/` and `CLAUDE.md` are generated from `.harness/` via `scripts/harness-sync`.
  This keeps project knowledge separate from the IDE binding — you can edit `.harness/`
  with any tool, then sync to whatever binding your team uses.

## When to invoke

- New empty project repo
- Greenfield directory where you want AI-driven development to start

For **existing** projects with code, use `/harness-adopt` instead.

## Procedure

Follow these steps strictly. Use `TodoWrite` to track them.

### 1. Confirm the target directory

The current working directory is the target. Confirm with the user:

> "I'll initialize Harness in `<cwd>`. Proceed? (yes / change directory)"

If the directory already contains `.harness/`, `.claude/agents/`, or `CLAUDE.md`,
**stop and tell the user** — running this would overwrite existing files. Suggest
they back up or run `/harness-adopt`.

### 2. Gather project info via `AskUserQuestion`

Ask three questions in a single `AskUserQuestion` call:

1. **Project type** — options:
   - `Fullstack (frontend + backend + DB)`
   - `Backend / API service`
2. **Primary language / framework stack** — free text via "Other" option (e.g. "Next.js + NestJS + Postgres" or "FastAPI + Postgres").
3. **Enable verify_all hook on Stop event?** — options:
   - `Yes (recommended)` — runs verify after every major change
   - `No, manual only`

### 3. Locate the template directory

Templates live alongside this skill:

- `<skill-root>/templates/common/` — shared assets (7 agents in `.harness/agents/`,
  rule fragments in `.harness/rules/`, harness-sync scripts, docs, evals).
- `<skill-root>/templates/fullstack/` — fullstack-specific overlays.
- `<skill-root>/templates/backend/` — backend-specific overlays.

If the skill is installed under `~/.claude/skills/harness-init/`, the templates are at `~/.claude/skills/harness-init/templates/`. Use `Glob` to discover the actual path.

### 4. Copy template files

Copy in this order (later layer adds to earlier; overlays do not overwrite common):

1. Everything under `templates/common/` → target root.
2. Everything under `templates/<project-type>/` → target root.
   - Fullstack overlay adds `.harness/rules/50-fullstack.md`, `.harness/skills/{build,test,verify}/SKILL.md.tmpl`, `scripts/verify_all.{ps1,sh}.tmpl`.
   - Backend overlay adds `.harness/rules/50-backend.md` etc.

Files ending in `.tmpl` need placeholder substitution (step 5). Drop the `.tmpl` suffix on write.

Note: templates/common contains both `.harness/` (the source of truth content) and
`.claude/settings.json.tmpl` (Claude Code binding glue — permissions and hooks).
The latter is copied directly to `.claude/settings.json` and is **not** routed
through `.harness/` (it's Claude Code-specific, no benefit to abstracting).

### 5. Substitute placeholders

Replace these placeholders in any `.tmpl` file:

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | basename of the target directory |
| `{{PROJECT_TYPE}}` | `fullstack` or `backend` |
| `{{STACK}}` | user's free-text answer to Q2 |
| `{{TODAY}}` | today's date in `YYYY-MM-DD` |
| `{{ENABLE_HOOK}}` | `true` or `false` from Q3 |

### 6. Run the initial binding sync

After all files are in place, run the binding sync to generate `.claude/agents/`,
`.claude/skills/`, and `CLAUDE.md` from `.harness/`:

```powershell
pwsh -File scripts/harness-sync.ps1     # Windows
bash scripts/harness-sync.sh            # Unix
```

This is what makes the skeleton actually usable by Claude Code. From now on, the
user edits `.harness/` and runs `harness-sync` (or `/harness-verify`, which calls
it transitively); they never hand-edit `.claude/` or `CLAUDE.md`.

### 7. Initialize git if needed

If the target is not a git repo (`.git/` does not exist), `git init -b main`.

### 8. Write the initial SPEC stub

Create `docs/spec/README.md` if missing (the template usually provides one).

### 9. Initialize baseline

Create `scripts/baseline.json` with empty defaults:

```json
{
  "version": 1,
  "created": "{{TODAY}}",
  "test_count": 0,
  "passing_count": 0,
  "warnings_baseline": 0,
  "notes": "Baseline starts at zero. Run verify_all and let it populate after the first successful task."
}
```

### 10. Summary report to user

Print a structured summary:

```
✅ Harness initialized in <path>

Source of truth (edit these, never .claude/ or CLAUDE.md):
  .harness/
    agents/       (7 sub-agents)
    rules/        (rule fragments; composed into CLAUDE.md by harness-sync)
    skills/       (build, test, verify procedures)

Generated (do not edit — re-run harness-sync after editing .harness/):
  .claude/agents/
  .claude/skills/
  .claude/settings.json   (direct binding artifact; safe to edit)
  CLAUDE.md

Project documentation (tool-agnostic, edit freely):
  docs/
    workflow.md   (7-stage pipeline definition)
    spec/         (write requirements here)
    dev-map.md    (development navigation)
    tasks.md      (task board)

Scripts:
  scripts/
    verify_all.{ps1,sh}    — total verification gate
    harness-sync.{ps1,sh}  — binding sync (.harness/ → .claude/ + CLAUDE.md)
    baseline.json
  evals/golden-tasks.md    — regression task set

Next steps:
  1. Read CLAUDE.md (generated) and customize .harness/rules/ if anything is off.
     After edits: run scripts/harness-sync to regenerate.
  2. Write your first feature in docs/spec/.
  3. In Claude Code, start a task by asking PM Orchestrator to take it:
     "Take this task: <description>"
     The PM dispatches through the 7-stage pipeline.

Estimated time to first delivered feature: 30 min – 1 hour depending on scope.
```

## Anti-patterns

- **Do not** overwrite existing `.harness/`, `.claude/`, or `CLAUDE.md` without explicit user confirmation.
- **Do not** edit the generated `.claude/agents/` or `CLAUDE.md`. Always edit `.harness/` and re-sync.
- **Do not** install npm packages or modify the user's shell config.
- **Do not** run `verify_all` during init (no project code yet).
- **Do not** modify files outside the target directory.

## Failure handling

- If template files are missing → tell the user the skill is broken, ask them to reinstall.
- If user aborts at any AskUserQuestion → leave the target untouched, no partial state.
- If file write fails (permission, disk full) → list which files made it and which didn't, do not retry blindly.
- If `harness-sync` fails after copy → report the error; the user can re-run it manually after fixing whatever blocked it.
