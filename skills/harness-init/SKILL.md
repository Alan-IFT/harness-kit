---
name: harness-init
description: Bootstrap a new project with the full Harness Engineering skeleton - 7 sub-agents, CLAUDE.md rules, workflow definition, verify_all script, dev-map, task board, and evals. Use this when starting a fresh fullstack or backend project that wants AI-driven development from day one.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-init

Bootstrap a new project with the complete Harness skeleton, so that Claude Code can run
the 7-agent pipeline (PM → Analyst → Architect → Gate → Developer → Reviewer → QA)
out of the box.

## When to invoke

- New empty project repo
- Greenfield directory where you want AI-driven development to start

For **existing** projects with code, use `/harness-adopt` instead.

## Procedure

Follow these steps strictly. Use `TodoWrite` to track them.

### 1. Confirm the target directory

The current working directory is the target. Confirm with the user:

> "I'll initialize Harness in `<cwd>`. Proceed? (yes / change directory)"

If the directory already contains `.claude/agents/` or `CLAUDE.md`, **stop and tell the user** — running this would overwrite existing files. Suggest they back up or run `/harness-adopt`.

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

- `<skill-root>/templates/common/` — shared assets (7 agents, workflow, dev-map, tasks, CLAUDE.md base, evals)
- `<skill-root>/templates/fullstack/` — fullstack-specific overlays
- `<skill-root>/templates/backend/` — backend-specific overlays

If the skill is installed under `~/.claude/skills/harness-init/`, the templates are at `~/.claude/skills/harness-init/templates/`. Use `Glob` to discover the actual path.

### 4. Copy template files

Copy in this order (later layer overrides earlier):

1. Everything under `templates/common/` → target root.
2. Everything under `templates/<project-type>/` → target root.

Files ending in `.tmpl` need placeholder substitution (see step 5). Drop the `.tmpl` suffix on write.

### 5. Substitute placeholders

Replace these placeholders in any `.tmpl` file:

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | basename of the target directory |
| `{{PROJECT_TYPE}}` | `fullstack` or `backend` |
| `{{STACK}}` | user's free-text answer to Q2 |
| `{{TODAY}}` | today's date in `YYYY-MM-DD` |
| `{{ENABLE_HOOK}}` | `true` or `false` from Q3 |

### 6. Initialize git if needed

If the target is not a git repo (`.git/` does not exist), `git init -b main`.

### 7. Write the initial SPEC stub

Create `docs/spec/README.md` with a stub:

```markdown
# Project SPEC

This folder holds the source-of-truth requirements for the project.
Each major feature gets its own SPEC document; the 7-agent pipeline reads from here.

## How to use

When you have a new feature idea, write a rough description here (or paste a chat),
then invoke the `requirement-analyst` agent to refine it into a structured requirement.
```

### 8. Initialize baseline

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

### 9. Summary report to user

Print a structured summary:

```
✅ Harness initialized in <path>

Created:
  .claude/
    agents/       (7 sub-agents)
    skills/       (build, test, verify)
    settings.json
  CLAUDE.md       (project rules; please edit for your stack)
  docs/
    workflow.md   (7-stage pipeline definition)
    spec/         (write requirements here)
    dev-map.md    (development navigation - update as you build)
    tasks.md      (task board - PM maintains this)
  scripts/
    verify_all.ps1 + verify_all.sh
    baseline.json
  evals/
    golden-tasks.md (regression task set)

Next steps:
  1. Read and customize CLAUDE.md for your stack.
  2. Write your first feature in docs/spec/.
  3. In Claude Code, start a task by asking PM Orchestrator to take it:
     "Take this task: <description>"
     The PM will dispatch through the 7-stage pipeline.

Estimated time to first delivered feature: 30 min – 1 hour depending on scope.
```

## Anti-patterns

- **Do not** overwrite existing `.claude/` or `CLAUDE.md` without explicit user confirmation.
- **Do not** install npm packages or modify the user's shell config.
- **Do not** run the verify_all script during init (no project code yet).
- **Do not** modify files outside the target directory.

## Failure handling

- If template files are missing → tell the user the skill is broken, ask them to reinstall.
- If user aborts at any AskUserQuestion → leave the target untouched, no partial state.
- If file write fails (permission, disk full) → list which files made it and which didn't, do not retry blindly.
