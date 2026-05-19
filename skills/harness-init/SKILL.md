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
- `.claude/agents/` and `.claude/skills/` are regenerated from `.harness/agents/` and
  `.harness/skills/` via `scripts/harness-sync`.
- `CLAUDE.md` and `.github/copilot-instructions.md` are ~15-line static stubs
  written once during init; they point at `AI-GUIDE.md`, which indexes
  `.harness/rules/*.md` by reference (since v0.10 rules are not composed).
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

1. **Project type** — options. The choice determines `PROJECT_TYPE` placeholder and which overlay is copied.
   - `Fullstack (frontend + backend + DB)` — `PROJECT_TYPE=fullstack`; copies fullstack overlay (partition agents, fullstack rules, verify_all preset for Node/web stacks).
   - `Backend / API service` — `PROJECT_TYPE=backend`; copies backend overlay (api/services/db partitions, backend rules, multi-stack verify_all).
   - `Generic (CLI / library / mobile / ML / embedded / etc.)` — `PROJECT_TYPE=generic`; copies generic overlay (`50-generic.md` stub for project-specific rules + a generic `verify_all` you customize for your actual build/test commands). No partition agents by default. The AI fills in `50-generic.md` based on your Q2 stack description and any existing code in the target directory.
2. **Primary language / framework stack** — free text via "Other" option (e.g. "Next.js + NestJS + Postgres", "FastAPI + Postgres", "Rust CLI tool", "PyTorch training pipeline").
3. **Install auto-sync hooks?** — options:
   - `Yes (recommended)` — installs **both** the Claude Code Stop hook (in `.claude/settings.json`) **and** the git pre-commit hook (via `scripts/install-hooks.{ps1,sh}`). Stop hook keeps `CLAUDE.md` + `.github/copilot-instructions.md` fresh while you work in Claude Code. Pre-commit hook is the tool-agnostic backstop — blocks any commit (Claude Code, Copilot, Cursor, hand-edits) that includes drifted generated artifacts.
   - `No, manual only` — you run `scripts/harness-sync` yourself after `.harness/` edits. `verify_all` will still catch drift after the fact, but you lose the auto-fresh guarantee.
4. **Developer partitioning** — options depend on Q1:

   For **Fullstack**:
   - `Partitioned (recommended) — dev-frontend / dev-backend / dev-db agents` — better focus, cleaner reviews, cross-area tasks via Architect partition assignment
   - `Single developer — one agent for all code` — simpler, fewer agents, fine for small projects

   For **Backend** (v0.5+):
   - `Partitioned (recommended) — dev-api / dev-services / dev-db agents` — three-layer split (HTTP boundary / business logic / persistence), supports clean coordination per Architect's design
   - `Single developer — one agent for all code` — fine for small/flat backend projects without a layered architecture

   For **Generic**:
   - Skip this question. Defaults to single developer. After init, the AI can be asked to "add partition agents for X" — it will create custom `.harness/agents/dev-*.md` based on the actual project layout. See `.harness/rules/50-generic.md` for the documented partitioning procedure.

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
- `<skill-root>/templates/generic/` — generic project overlay (single `50-generic.md` stub).
- `<skill-root>/templates/i18n/<lang>/` — translation overlays (currently `zh` is provided). Mirror the directory structure of `common/` and `<project-type>/`; files inside override their English counterparts.

If the skill is installed under `~/.claude/skills/harness-init/`, the templates are at `~/.claude/skills/harness-init/templates/`. Use `Glob` to discover the actual path.

### 4. Copy template files

Copy in this order (later layer overwrites earlier):

1. Everything under `templates/common/` → target root.
2. Everything under `templates/<project-type>/` → target root.
   - Fullstack overlay adds `.harness/rules/50-fullstack.md`, `.harness/skills/{build,test,verify}/SKILL.md.tmpl`, `scripts/verify_all.{ps1,sh}.tmpl`, **and** `.harness/agents/dev-{frontend,backend,db}.md.tmpl` (partition agents).
   - Backend overlay adds `.harness/rules/50-backend.md` etc.
   - **Generic** overlay adds `.harness/rules/50-generic.md` (a near-empty stub the user/AI fills in based on the actual stack). No partition agents. No project-type-specific `verify_all` template — the project gets the generic `verify_all` from `common/` (TODO: ship a `verify_all.tmpl` in `generic/` once the common one has stack-agnostic skeleton).
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

Note: templates/common contains:
- `.harness/` (the source of truth content)
- `.claude/settings.json.tmpl` (Claude Code binding glue — permissions + hooks)
- `AI-GUIDE.md.tmpl` (tool-agnostic entry, indexes `.harness/rules/`)
- `CLAUDE.md.tmpl` (~15-line bootstrap stub pointing at `AI-GUIDE.md`)
- `.github/copilot-instructions.md.tmpl` (same stub for Copilot, with `applyTo: "**"` frontmatter)

`CLAUDE.md.tmpl` and `.github/copilot-instructions.md.tmpl` are copied to their
final paths during init and are **never regenerated** — they're static stubs.
The full ruleset stays in `.harness/rules/*.md`; `AI-GUIDE.md` references those
fragments with "when to read" descriptions so AI tools can lazy-load only what
they need (progressive disclosure, like Claude Code's own skill system).

### 5. Substitute placeholders

Replace these placeholders in any `.tmpl` file:

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | basename of the target directory |
| `{{PROJECT_TYPE}}` | `fullstack`, `backend`, or `generic` |
| `{{STACK}}` | user's free-text answer to Q2 |
| `{{TODAY}}` | today's date in `YYYY-MM-DD` |
| `{{ENABLE_HOOK}}` | `true` or `false` from Q3 |
| `{{PARTITIONED}}` | `true` or `false` from Q4 (default `false` if Q4 was skipped) |
| `{{LANG}}` | `en` (default) or `zh` from Q5 |
| `{{SYNC_COMMAND}}` | OS-detected harness-sync invocation for the Stop hook. **Windows** → `pwsh -NoProfile -File scripts/harness-sync.ps1`. **macOS / Linux** → `bash scripts/harness-sync.sh`. Detect via `$IsWindows` (PowerShell) or `[[ "$OSTYPE" == "msys"* \|\| "$OSTYPE" == "cygwin"* \|\| "$OSTYPE" == "win32" ]]` (bash). Used only in `.claude/settings.json`. The Windows `-NoProfile` flag avoids loading the user's `$PROFILE` on every hook invocation (measured 3-4s → 10ms in QA 06_TEST_REPORT.md D-3). |
| `{{GUARD_COMMAND}}` | OS-detected guard-rm invocation for the PreToolUse hook (destructive-command safety, v0.15+). **Windows** → `pwsh -NoProfile -File scripts/guard-rm.ps1`. **macOS / Linux** → `bash scripts/guard-rm.sh`. Mirror the same OS detection used for `{{SYNC_COMMAND}}`. Used only in `.claude/settings.json`. See `.harness/rules/75-safety-hook.md` for the contract. The Windows `-NoProfile` flag is essential here — without it, every Bash tool call eats the user's `$PROFILE` startup cost (NFR-Perf was violated in QA testing; see 06_TEST_REPORT.md D-3). |

### 6. Run the initial binding sync

After all files are in place, run the binding sync to copy `.harness/agents/`
and `.harness/skills/` into the Claude-Code-required `.claude/` paths:

```powershell
pwsh -File scripts/harness-sync.ps1     # Windows
bash scripts/harness-sync.sh            # Unix
```

**v0.10 scope (much narrower than v0.9.x)**: `harness-sync` only copies
`.harness/agents/` → `.claude/agents/` and `.harness/skills/` → `.claude/skills/`.
It does **not** generate `CLAUDE.md` or `.github/copilot-instructions.md` —
those are static stubs written once during init (step 4) and never regenerated.
`AI-GUIDE.md` indexes `.harness/rules/` by reference; rules updates flow
automatically by reference, not by re-composition.

From now on:
- To change a rule: edit `.harness/rules/<file>.md`. **No sync needed.** AI tools
  follow the reference from `AI-GUIDE.md`.
- To change an agent or skill: edit `.harness/agents/<file>.md` or
  `.harness/skills/<name>/SKILL.md`, then re-run `harness-sync` to update
  `.claude/`. The Stop hook + pre-commit hook auto-handle this if installed.

### 7. Initialize git if needed

If the target is not a git repo (`.git/` does not exist), `git init -b main`.

### 8. Install the git pre-commit hook (if Q3 = Yes)

If the user answered Q3 = `Yes (recommended)`, run the hook installer
right after `git init`:

```powershell
pwsh -File scripts/install-hooks.ps1   # Windows
bash scripts/install-hooks.sh          # macOS / Linux
```

This writes `.git/hooks/pre-commit` which runs `harness-sync --check`
before every commit. Drift between `.harness/` and the generated files
(`CLAUDE.md`, `.github/copilot-instructions.md`) becomes a hard block,
regardless of which AI tool (Claude Code, Copilot, Cursor) or human did
the edit. Catches the case where Claude Code's Stop hook didn't fire
because the user was working in a different tool.

If Q3 = `No, manual only`, skip this step. The Stop hook in
`.claude/settings.json` is also unconditionally written by the template
(it does no harm if Claude Code is never used); only the pre-commit hook
is conditional on Q3.

**Note on the safety guard (v0.15+)**: `scripts/guard-rm.{ps1,sh}` is shipped
via the `templates/common/scripts/` copy in step 4, and the PreToolUse hook in
`.claude/settings.json` is wired with `{{GUARD_COMMAND}}` substituted in step 5.
No separate installer step is needed — the guard is always on after init. The
disable path is documented in `.harness/rules/75-safety-hook.md`.

### 9. Write the initial SPEC stub

Create `docs/spec/README.md` if missing (the template usually provides one).

### 10. Initialize baseline

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

### 11. Summary report to user

Print a structured summary:

```
✅ Harness initialized in <path>

Source of truth (edit these, never .claude/):
  .harness/
    agents/       (7 sub-agents — synced to .claude/agents/ by harness-sync)
    rules/        (rule fragments — referenced by AI-GUIDE.md, NOT composed)
    skills/       (build, test, verify procedures — synced to .claude/skills/)
  AI-GUIDE.md     (tool-agnostic entry; indexes .harness/rules/ with "when to read")

Init-time artifacts (touch only to fix the AI-GUIDE.md pointer):
  CLAUDE.md                            (~15-line stub pointing at AI-GUIDE.md)
  .github/copilot-instructions.md      (~15-line stub pointing at AI-GUIDE.md)

Regenerated by harness-sync (never hand-edit):
  .claude/agents/
  .claude/skills/

Direct binding glue (safe to edit by hand):
  .claude/settings.json

Project documentation (tool-agnostic, edit freely):
  docs/
    workflow.md   (7-stage pipeline definition)
    spec/         (write requirements here)
    dev-map.md    (development navigation)
    tasks.md      (task board)

Scripts:
  scripts/
    verify_all.{ps1,sh}    — total verification gate
    harness-sync.{ps1,sh}  — binding sync (.harness/agents + .harness/skills → .claude/)
    guard-rm.{ps1,sh}      — destructive-command safety hook (PreToolUse; v0.15+)
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
