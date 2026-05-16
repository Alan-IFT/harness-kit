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

Ask **five questions** in a single `AskUserQuestion` call:

1. **Project type** — options:
   - `Fullstack (frontend + backend + DB)` — copies fullstack overlay (partition agents, fullstack rules, verify_all preset for Node/web stacks).
   - `Backend / API service` — copies backend overlay (api/services/db partitions, backend rules, multi-stack verify_all).
   - `Other / Generic` — **for everything else** (CLI tool, library, mobile, ML pipeline, embedded, etc.). Only common assets are copied; no project-type overlay. You and the AI will refine `.harness/rules/00-core.md` and `verify_all` to fit your project. **v0.10 will make this path AI-native: AI analyzes your project description and generates a custom overlay automatically.**
2. **Primary language / framework stack** — free text via "Other" option (e.g. "Next.js + NestJS + Postgres", "FastAPI + Postgres", "Rust CLI tool", "PyTorch training pipeline").
3. **Enable verify_all hook on Stop event?** — options:
   - `Yes (recommended)` — runs verify after every major change
   - `No, manual only`
4. **Developer partitioning** — options depend on Q1:

   For **Fullstack**:
   - `Partitioned (recommended) — dev-frontend / dev-backend / dev-db agents` — better focus, cleaner reviews, cross-area tasks via Architect partition assignment
   - `Single developer — one agent for all code` — simpler, fewer agents, fine for small projects

   For **Backend** (v0.5+):
   - `Partitioned (recommended) — dev-api / dev-services / dev-db agents` — three-layer split (HTTP boundary / business logic / persistence), supports clean coordination per Architect's design
   - `Single developer — one agent for all code` — fine for small/flat backend projects without a layered architecture

   For **Other / Generic**:
   - Skip this question. Defaults to single developer. The PM or the user can ask AI later to "add partition agents for X" — AI will create custom `.harness/agents/dev-*.md` based on the actual project layout. **v0.10 will offer this analysis as an init-time step automatically.**

5. **Project output language** — this is a **project-wide policy**, not just doc language. Options:
   - `English (default)` — **All AI output in this project will be in English**. That includes: chat replies, agent-to-agent hand-offs, every per-task document (`01_REQUIREMENT_ANALYSIS.md` through `07_DELIVERY.md`, `PM_LOG.md`), updates to `tasks.md` / `dev-map.md`, error messages, status reports. Even if the user writes in another language, AI responds in English.
   - `中文 (Chinese)` — **项目内 AI 全程使用中文输出**。包括：对话回复、agent 间交接、所有任务阶段文档、tasks.md / dev-map.md 更新、错误消息、状态报告。即使用户用其他语言提问，AI 也用中文回答。
   - The policy is enforced by an "Output language" section at the top of CLAUDE.md. Agents read CLAUDE.md and follow the rule.
   - Agent definitions and verify_all scripts stay in English regardless (LLM reads English fine, file count manageable). Only output is constrained.

### 3. Locate the template directory

Templates live alongside this skill:

- `<skill-root>/templates/common/` — shared assets (7 agents in `.harness/agents/`,
  rule fragments in `.harness/rules/`, harness-sync scripts, docs, evals).
- `<skill-root>/templates/fullstack/` — fullstack-specific overlays.
- `<skill-root>/templates/backend/` — backend-specific overlays.
- `<skill-root>/templates/i18n/<lang>/` — translation overlays (currently `zh` is provided). Mirror the directory structure of `common/` and `<project-type>/`; files inside override their English counterparts.

If the skill is installed under `~/.claude/skills/harness-init/`, the templates are at `~/.claude/skills/harness-init/templates/`. Use `Glob` to discover the actual path.

### 4. Copy template files

Copy in this order (later layer overwrites earlier):

1. Everything under `templates/common/` → target root.
2. Everything under `templates/<project-type>/` → target root.
   - Fullstack overlay adds `.harness/rules/50-fullstack.md`, `.harness/skills/{build,test,verify}/SKILL.md.tmpl`, `scripts/verify_all.{ps1,sh}.tmpl`, **and** `.harness/agents/dev-{frontend,backend,db}.md.tmpl` (partition agents).
   - Backend overlay adds `.harness/rules/50-backend.md` etc.
   - **Other / Generic**: skip this step. No overlay applied. The project gets only `common/` content. After init, the PM or the user can ask AI to "look at the project and propose what rules / partition agents / verify_all checks should apply" — AI reads existing code (or the user's description), then generates `.harness/rules/50-project.md`, optional `.harness/agents/dev-*.md`, and customizes `verify_all` accordingly.
3. **If Q5 ≠ English**, apply the language overlay:
   - Copy everything under `templates/i18n/<lang>/common/` → target root (overwrites the English files).
   - Copy everything under `templates/i18n/<lang>/<project-type>/` → target root.
   - The `zh` overlay translates: `00-core.md.tmpl`, `50-fullstack.md` or `50-backend.md`, `docs/workflow.md`, `docs/dev-map.md.tmpl`, `docs/tasks.md.tmpl`, `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`.
   - Files **not** in the overlay (agent prompts, skills/build|test|verify SKILL.md, scripts) stay in English. This is intentional: LLM reads English fine, file count stays manageable.

Files ending in `.tmpl` need placeholder substitution (step 5). Drop the `.tmpl` suffix on write.

**After copy, apply the partitioning choice** (from Q4):

- If user picked **partitioned mode**: keep all partition agents AND keep the
  generic `developer.md`. The generic one stays as a fallback for tasks the
  architect can't cleanly assign to one partition.
- If user picked **single mode**: delete the project-type-specific partition
  agents from `.harness/agents/`:
  - Fullstack: `dev-frontend.md`, `dev-backend.md`, `dev-db.md`
  - Backend: `dev-api.md`, `dev-services.md`, `dev-db.md`
  - Only the generic `developer.md` remains.

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
| `{{PARTITIONED}}` | `true` or `false` from Q4 (default `false` if Q4 was skipped) |
| `{{LANG}}` | `en` (default) or `zh` from Q5 |

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
