---
name: harness-adopt
description: Adopt Harness Engineering into an existing project. Scans the repo, extracts conventions, proposes a plan, and (with user confirmation) applies it non-destructively. Use this when a project already has code but no Harness setup.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-adopt

Non-invasively add Harness to a project that already has code, tests, and CI.

> **Status: v0.3.0 — automated apply.** v0.1/0.2 wrote a plan and stopped; v0.3 confirms with
> the user and applies the plan. Existing files are never overwritten without explicit
> confirmation.

## When to invoke

- The project already has source code, tests, package manifests.
- You want the 7-agent workflow available but **don't want to rewrite anything**.

For empty projects, use `/harness-init` instead.

## Procedure

Use `TodoWrite` to track. Stages are gated: do not skip to apply without an
explicit user "yes" at stage 5.

### 1. Confirm target

Current working directory is the target. Confirm `.git/` exists. Stop if not.

If `.harness/`, `.claude/agents/`, or `CLAUDE.md` already exists, **ask the user**:

```
This project already has some Harness assets:
  - .harness/         (present | absent)
  - .claude/agents/   (present | absent)
  - CLAUDE.md         (present | absent)

What do you want to do?
  [A] Cancel - I'll back up and re-run
  [B] Merge - keep existing, add what's missing
  [C] Overwrite - replace conflicting files (destructive)
```

`A` → stop, no changes. `B` → step 6 (merge mode). `C` → step 6 (overwrite mode,
requires extra confirmation on each conflict).

### 2. Reconnaissance

Detect:

- **Languages / frameworks** by file presence:
  - `package.json` → Node ecosystem; look for `next`, `nest`, `vite`, `prisma`, `nuxt`
  - `pyproject.toml` / `requirements.txt` → Python; look for `fastapi`, `django`, `flask`
  - `go.mod` → Go
  - `Cargo.toml` → Rust
- **Test runner**: `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pytest.ini`, presence of `tests/`, `__tests__/`, `*.test.*`.
- **Database / migrations**: `prisma/`, `migrations/`, `alembic.ini`, `db/migrate/`.
- **CI**: `.github/workflows/*`, `.gitlab-ci.yml`, `.circleci/`.
- **Existing rules**: `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `.eslintrc*`, `.prettierrc*`, `pyproject.toml` `[tool.*]` sections.
- **Project type inference**:
  - Has `apps/web/` + `apps/api/` (or similar dual structure) → **fullstack**
  - Has only API-related deps and structure → **backend**
  - Otherwise → ask the user via `AskUserQuestion`.

Print the project profile:

```
Detected:
  Type:           [fullstack | backend]   (inferred — confirm)
  Languages:      [TypeScript, Python, ...]
  Frameworks:     [Next.js, NestJS, Prisma, ...]
  Test runners:   [Vitest, Playwright, ...]
  CI:             [GitHub Actions]
  Existing docs:  [README, CONTRIBUTING, docs/]
```

### 3. Ask user for confirmation of inferred values

Use `AskUserQuestion`:

1. **Confirm project type** (default: detected) — Fullstack / Backend / Other (abort).
2. **Stack description** (free text via "Other") — pre-fill with detected list.
3. **Enable verify_all hook** — Yes / No.
4. **Developer partitioning** — options depend on Q1:

   For **Fullstack**: Partitioned (default) / Single developer.
   - Partitioned: ships `dev-frontend`, `dev-backend`, `dev-db` agents alongside
     the generic `developer.md`.
   - Single developer: ships only generic `developer.md`.
   - Pre-fill: `apps/web/` + `apps/api/` (or similar dual structure) → recommend
     Partitioned. Flat structure → Single.

   For **Backend**: Partitioned (default) / Single developer.
   - Partitioned: ships `dev-api`, `dev-services`, `dev-db` agents alongside the
     generic `developer.md`.
   - Single developer: ships only generic `developer.md`.
   - Pre-fill: presence of `src/routes/` + `src/services/` + `migrations/`
     (or `src/controllers/` + `src/services/` + `src/repositories/`) → recommend
     Partitioned. Flat single-folder project → Single.

5. **Document language** — options:
   - `English (default)` — generated docs/rules/workflow in English.
   - `中文 (Chinese)` — 生成的文档、规则、workflow 用中文。
   - Pre-fill: detect existing README/CONTRIBUTING language; if dominantly Chinese,
     recommend Chinese. Agent prompts stay in English regardless.

6. **AI customization of `50-<project>.md` rule fragment (v0.16+)** — opt-in. Default: `No (static template only)`.
   - `No (default) — keep static stub` — the static `50-<type>.md` template is the rule fragment in the apply plan. Byte-identical to v0.15.1 adopt behavior.
   - `Yes — let AI draft a tailored 50-<project-slug>.md` — between step 4 (extract rule candidates) and step 5 (write plan), the skill runs step 4b: it seeds the same drafting prompt as `/harness-init`'s step 5b.3 from this skill's step-2 reconnaissance profile (already in memory: detected languages / frameworks / test runners / CI / existing docs), validates the AI output against the four invariants (`.harness/rules/_ai-native-prompt.md` documents them), and writes the proposed fragment to `.harness-adopt/PROPOSED_RULES/50-<project-slug>.md` for review. The plan template in step 5 mentions this fragment so the user sees it before "apply".
   - Tradeoff: same as `/harness-init` (~10s extra; non-deterministic output mitigated by source-citation discipline and a four-invariant validator that falls back to the static stub).
   - Reserved-name guard: partition names matching the seven pipeline-agent names are dropped before being shown to the user (same as `/harness-init`).

### 4. Extract rule candidates

Read existing convention files and extract rule candidates:

- From `README.md`: anything under headings like "Conventions", "Style", "Rules", "Guidelines".
- From `CONTRIBUTING.md`: anything under "Pull Request", "Code Style", "Commit Messages".
- From `.editorconfig`: indent, charset, line endings.
- From `.eslintrc*` / `.prettierrc*`: notable rules (but don't try to enumerate every rule).
- From `pyproject.toml` `[tool.ruff]`, `[tool.black]`: line length, exclusion patterns.

Write the draft to `.harness-adopt/CLAUDE.draft.md`. **Do not** yet move it to `.harness/rules/`.

### 4b. AI rule synthesis (opt-in, v0.16+)

This step runs **only if Q6 = `Yes`**. If Q6 = `No`, skip to step 5 — the static
`50-<type>.md` is the rule fragment in the apply plan, identical to v0.15.1.

This step is symmetric with `/harness-init`'s step 5b but **seeded from the
step-2 reconnaissance profile** instead of re-Globbing. The skill is otherwise
identical, including the four invariants and the slug sanitizer (see
`skills/harness-init/SKILL.md:5b.1`). Quote the prompt contract from the
shipped `templates/common/.harness/rules/_ai-native-prompt.md` (already present
in this repo even before adopt-apply — it ships with the skill, not the user
project).

Differences from init step 5b:

- **Slug source**: cwd basename (same sanitizer as init).
- **Inputs**: the reconnaissance profile (languages, frameworks, test runners,
  CI, existing docs) plus any manifest contents already read in step 2; no
  fresh Glob pass needed.
- **Output path** (not yet applied): `.harness-adopt/PROPOSED_RULES/50-<slug>.md`.
  The PROPOSED_RULES directory is created if absent.
- **Partition drafts** (if any, after the reserved-name filter): written to
  `.harness-adopt/PROPOSED_AGENTS/dev-<name>.md` — also a draft, not applied.
- **Mock short-circuit**: same `HARNESS_AI_NATIVE_MOCK` env var as init.
- **Re-Read after Write**: same discipline as init step 5b.6.

The plan template in step 5 gets a new bullet under "Files I will add (NEW)":

```
- .harness/rules/50-<slug>.md (AI-drafted; replaces the static 50-<type>.md.
  Review the draft at .harness-adopt/PROPOSED_RULES/50-<slug>.md before
  approving the plan.)
```

If any invariant fails, fall back: keep `.harness-adopt/PROPOSED_RULES/` empty
and log `[AI-FALLBACK]` reason to `.harness-adopt/CONFLICTS.md`. The plan template
omits the AI bullet and uses the static stub. The user is told once at end of
step 5.

When the user says "apply" in step 5, step 6 moves the proposed files into
`.harness/` (and `.harness/agents/` for accepted partitions) as part of the
normal apply flow.

### 5. Write the plan and ask user to confirm

Locate the harness-init templates (typically at `~/.claude/skills/harness-init/templates/`).
Write `.harness-adopt/PLAN.md`:

```markdown
# Adopt Plan

## Detected
<the profile from step 2>

## Files I will add (NEW)
- (the 7 generic framework agents are NOT copied — they are plugin-provided as harness-kit:<name>)
- .harness/agents/dev-*.md (3 partition agents, only if Q4=Partitioned):
  - Fullstack: dev-frontend, dev-backend, dev-db
  - Backend:   dev-api, dev-services, dev-db
- .harness/rules/00-core.md (rendered from CLAUDE.draft.md and templates/common/.harness/rules/00-core.md.tmpl with placeholders substituted)
- .harness/rules/50-<type>.md (overlay rules from templates/<type>/.harness/rules/)
- .harness/rules/75-safety-hook.md (destructive-command guardrail contract; v0.15+)
- .harness/skills/{build,test,verify}/SKILL.md (from templates/<type>/.harness/skills/, wired to your detected commands)
- .claude/settings.json (Claude Code binding glue from templates/common/.claude/settings.json.tmpl; includes the PreToolUse hook for guard-rm — merged in if your settings.json already exists, see "PreToolUse hook merge" below)
- AI-GUIDE.md (tool-agnostic index; references .harness/rules/ with "when to read" triggers)
- CLAUDE.md and .github/copilot-instructions.md (one-time ~15-line stubs pointing at AI-GUIDE.md; written once at adopt time, NOT regenerated by harness-sync)
- .harness/scripts/harness-sync.{ps1,sh}, .harness/scripts/verify_all.{ps1,sh}, .harness/scripts/baseline.json
- .harness/scripts/guard-rm.{ps1,sh} (cross-platform destructive-command guard; see .harness/rules/75-safety-hook.md)
- docs/workflow.md, docs/dev-map.md (with project structure auto-filled), docs/tasks.md, docs/spec/README.md
- evals/golden-tasks.md
- .claude/agents/ and .claude/skills/ (regenerated from .harness/{agents,skills} by harness-sync; never hand-edit)

## PreToolUse hook merge (.claude/settings.json — v0.15+)

If .claude/settings.json already exists in this project:
  - If it has NO `hooks.PreToolUse` array → ADD the guard-rm PreToolUse entry. No conflict.
  - If it HAS a `hooks.PreToolUse` array but no matcher==="Bash" entry pointing at .harness/scripts/guard-rm.* → APPEND a new matcher=="Bash" block. No conflict.
  - If it HAS a matcher==="Bash" entry pointing at something else → surface as a conflict; log to .harness-adopt/CONFLICTS.md; ask the user whether to merge (default), overwrite, or skip.

## Existing files I will NOT touch
- All your source code, tests, configs
- .github/workflows/* (you can wire verify_all into CI later; this skill does not)
- README.md, CONTRIBUTING.md, .editorconfig (extracted into the draft rules, but originals untouched)

## Conflicts noted (require your decision)
<list any actual collisions with existing .harness/, .claude/, CLAUDE.md>

## What you should do next
1. Review .harness-adopt/PLAN.md (this file).
2. Review .harness-adopt/CLAUDE.draft.md and edit if needed.
3. Reply "apply" to proceed, "abort" to cancel.
```

Show the plan summary to the user. Ask via `AskUserQuestion`:

```
Apply this plan? [yes / no / show full plan]
```

**If "no" or "abort"**: stop here. Leave `.harness-adopt/` for the user to review.
Tell the user: "Plan saved to .harness-adopt/. To re-run later: /harness-adopt".

**If "show full plan"**: print the contents of `.harness-adopt/PLAN.md` and ask again.

**If "yes" or "apply"**: proceed to step 6.

### 6. Apply

For each file in the plan:

- **Compute target path**.
- **If target does not exist**: write it.
- **If target exists and is byte-identical**: skip.
- **If target exists and differs and mode is "merge"**: skip (do not overwrite); log to a `.harness-adopt/CONFLICTS.md`.
- **If target exists and differs and mode is "overwrite"**: ask via `AskUserQuestion` for this specific file: "[file]: keep existing / overwrite". Honor user's choice.

**Special case — .claude/settings.json (PreToolUse merge, v0.15+):**

This file is treated differently than other "differs in merge mode" files
because the guard-rm PreToolUse block is additive and almost always safe to
merge:

- If target is absent: copy the template (with `{{GUARD_COMMAND}}` substituted); done.
- If target exists and is byte-identical to template: skip; done.
- If target exists and differs:
  - Parse existing as JSON.
  - If no `hooks.PreToolUse`: insert a fresh `PreToolUse` array with the
    matcher=="Bash" block pointing at `.harness/scripts/guard-rm.*`. Write back with
    stable JSON formatting (2-space indent, preserve key order).
  - If a `hooks.PreToolUse` array exists but no matcher=="Bash" entry
    pointing at `guard-rm.*`: prepend the new block. Write back.
  - If a matcher=="Bash" entry already exists (pointing somewhere else):
    log the conflict to `.harness-adopt/CONFLICTS.md` and DO NOT modify;
    surface the conflict in the final summary so the user can merge manually.

JSON-merge implementation note: PowerShell `ConvertFrom-Json` /
`ConvertTo-Json -Depth 10` works on Windows; bash side prefers `jq` if
available, otherwise falls back to template-replace heuristic (the file we
wrote at init has known shape, so this works in the common case).

**Partition handling** (Q4 from step 3):

- If Q4 = Partitioned: copy partition agents from
  `templates/<type>/.harness/agents/dev-*.md.tmpl` with placeholder substitution:
  - Fullstack: `dev-frontend`, `dev-backend`, `dev-db`
  - Backend:   `dev-api`, `dev-services`, `dev-db`
  The plugin `harness-kit:developer` remains available as fallback (not copied locally).
- If Q4 = Single developer: do NOT copy partition agents. Every role comes from the
  plugin (`harness-kit:<name>`); no local agents are added.

**Language handling** (Q5 from step 3):

- If Q5 = English (default): no further action. Copied files are already English.
- If Q5 = Chinese (zh): after the English copy in step 4 and 6, apply the language
  overlay — copy `templates/i18n/zh/common/` and `templates/i18n/zh/<type>/` over
  the target root, overwriting matching files. The overlay carries only the
  human-facing files:
  - `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`
  Then **inject** the Chinese output-language policy into the three policy-carrying
  surfaces (which stay English from the `common/` copy): run the already-distributed
  helper against the project root —
  `bash .harness/scripts/language-policy.sh --template-root <template-root> --lang zh`
  (or the `.ps1` form on Windows), where `<template-root>` is the directory that
  contains `skills/harness-init/templates`. It rewrites the `.harness/rules/00-core.md`
  policy section + the `CLAUDE.md` / `.github/copilot-instructions.md` policy line to
  Chinese, then delete the `*.bak-*` files it writes. (This composes the zh policy from
  the single-source snippet — the i18n/zh policy-carrying files no longer exist; T-016.)
  Agent prompts stay in English regardless of Q5.

Substitution rules (same as `/harness-init`):

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | basename of target directory |
| `{{PROJECT_TYPE}}` | from step 3 |
| `{{STACK}}` | from step 3 |
| `{{TODAY}}` | today's date `YYYY-MM-DD` |
| `{{ENABLE_HOOK}}` | from step 3 |

For `.harness/rules/00-core.md`: if `.harness-adopt/CLAUDE.draft.md` has content beyond
the template, append it as a new fragment `.harness/rules/80-existing-conventions.md` so
the user can review and reorganize later.

After all files written:

1. Run the binding sync (`.harness/scripts/harness-sync.ps1` or `.sh`).
2. Run `verify_all` once to capture baseline; write current test count to `.harness/scripts/baseline.json`. (If `verify_all` fails because of existing project issues, that's okay — capture the current state as baseline.)

### 7. Summary

Report to the user:

```
✅ Harness adopted into <path>

Files added:
  <list>

Files skipped (already existed, merge mode):
  <list>

Conflicts (require your attention):
  <list with reasons; see .harness-adopt/CONFLICTS.md>

Baseline captured:
  test_count: <N>
  warnings: <N>

Next steps:
  1. Review AI-GUIDE.md, the CLAUDE.md stub, and
     .harness/rules/80-existing-conventions.md (auto-extracted from your
     README/CONTRIBUTING/lint configs).
  2. Customize .harness/rules/ to match your project's actual conventions.
     Edit the fragments — AI tools follow them by reference from AI-GUIDE.md;
     no harness-sync needed for rule edits. (Sync is only needed if you edit
     .harness/agents/ or .harness/skills/.)
  3. Try a small task to validate: tell the PM Orchestrator "Take this task: ..."
  4. Optionally wire .harness/scripts/verify_all into your CI.
```

### 8. Cleanup

Leave `.harness-adopt/` in place — it's a record of what was decided. The user can
delete it (and may want to gitignore it). Add `.harness-adopt/` to a recommended
`.gitignore` snippet in the summary.

## Hard rules

- **No existing file is modified without explicit user confirmation.** Merge mode
  skips conflicts; overwrite mode prompts per file.
- **No silent overwrite** of `CLAUDE.md`, `.claude/`, or `.harness/`. Always confirm.
- **`verify_all` baselines the current state** — preserves what already works
  rather than starting from zero.
- **Do not run package install commands** (no `npm install` etc.). The adopt
  process must be safe to run on a stranger's codebase.
- **Do not modify CI files** (`.github/workflows/*` etc.). Adding verify_all to CI
  is the user's call.

## Anti-patterns

- Don't try to rewrite the user's CI to call verify_all without asking.
- Don't extract rules and then assert them — present as a draft fragment, user reviews.
- Don't generate `docs/dev-map.md` content from imagination; only from actual folder structure.
- Don't proceed past step 5 without an explicit "yes/apply".

## Limitations (v0.3.0)

- Stack-detection covers Node/Python/Go basics; exotic stacks may need manual edits.
- Rule extraction is keyword/heading-based, not semantic; expect to refine the draft.
- No deep code analysis; the dev-map seed is folder-only. Real reuse audit happens on first agent run.
- Conflict resolution is per-file binary (keep / overwrite). No 3-way merge.

## Roadmap

| Version | Capability |
|---|---|
| 0.3.0 | Reconnaissance + plan + automated apply with conflict gating |
| 0.4.1 | Partition Q4 (fullstack only) — copy `dev-frontend/backend/db` agents |
| **0.5.0** (current) | Backend partitioning (`dev-api/services/db`) symmetric with fullstack |
| 0.6.0 (planned) | Microservice-aware partitioning (per-service agents); three-way merge for `CLAUDE.md`; semantic rule extraction (AI instead of keyword) |
