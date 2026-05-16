---
name: harness-migrate
description: Migrate an existing v0.9.x harness-kit project to the v0.10 layout (AI-GUIDE.md + stub CLAUDE.md / copilot-instructions.md, no more rule composition). Use when a project was initialized with harness-init at v0.9.x or earlier and you want to adopt the v0.10 progressive-disclosure design.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-migrate

Migrate an existing harness-kit project from v0.9.x layout (rules composed into a large `CLAUDE.md`) to v0.10 layout (a thin `AI-GUIDE.md` index + minimal bootstrap stubs).

The benefit: persistent context-budget drops by ~90% for small interactions and ~50% on average; AI tools lazy-load only the rule fragments they need.

## When to invoke

- Project has a v0.9.x-style `CLAUDE.md` (200+ lines, generated from `.harness/rules/`)
- Project has matching `.github/copilot-instructions.md` (also generated)
- Project may or may not already have `AI-GUIDE.md`

For projects without any harness setup, use `/harness-init` instead.

## What changes

| Before (v0.9.x) | After (v0.10) |
|---|---|
| `CLAUDE.md` = full composed ruleset (~250 lines) | `CLAUDE.md` = ~15-line bootstrap stub |
| `.github/copilot-instructions.md` = full composed ruleset | Same stub with `applyTo: "**"` frontmatter |
| (no file) | `AI-GUIDE.md` = ~50-line index of `.harness/rules/` with "when to read" descriptions |
| `harness-sync` composes rules into CLAUDE.md + copilot-instructions.md | `harness-sync` only copies agents + skills to `.claude/` |
| `verify_all` checks rule-composition drift | `verify_all` checks bootstrap stubs reference `AI-GUIDE.md` |

`.harness/rules/`, `.harness/agents/`, `.harness/skills/` — all **unchanged**.

## Procedure

Follow these steps strictly. Use `TodoWrite` to track them.

### 1. Detect v0.9.x layout

Verify the project is a candidate for migration:

```powershell
Test-Path "CLAUDE.md"
Test-Path ".harness/rules"
(Get-Content CLAUDE.md -Raw) -match "GENERATED FILE"
```

If `CLAUDE.md` is missing, or it doesn't contain "GENERATED FILE", **stop** — this is either not a harness-kit project, or it's already migrated. Report to user.

If `AI-GUIDE.md` already exists, ask the user whether to overwrite or abort.

### 2. Read project info from existing CLAUDE.md

Extract project metadata from the existing `CLAUDE.md` by reading its header. v0.9.x `CLAUDE.md` starts with:

```markdown
# {{PROJECT_NAME}} — Project Rules
> Project type: **{{PROJECT_TYPE}}** · Stack: **{{STACK}}** · Initialized: {{TODAY}}
```

Parse out `PROJECT_NAME`, `PROJECT_TYPE`, `STACK`, `TODAY`. If parsing fails, ask the user.

Detect output language by looking for "Output language" text in `CLAUDE.md` — "English" or "中文".

### 3. Locate the v0.10 templates

Use the templates shipped with the user's installed harness-init skill:

```powershell
Glob "**/harness-init/templates/common/AI-GUIDE.md.tmpl"
```

If found under `~/.claude/skills/harness-init/templates/`, that's the source.

### 4. Backup the v0.9.x files

Before overwriting, copy current state into `.harness-migrate-backup/`:

```
.harness-migrate-backup/
  CLAUDE.md            (the v0.9.x generated file)
  copilot-instructions.md
  scripts/harness-sync.ps1
  scripts/harness-sync.sh
  scripts/install-hooks.ps1   (if exists)
  scripts/install-hooks.sh    (if exists)
  scripts/verify_all.ps1
  scripts/verify_all.sh
```

Add `.harness-migrate-backup/` to `.gitignore` if not already present.

### 5. Write the new bootstrap files

For each of:
- `AI-GUIDE.md.tmpl` → `AI-GUIDE.md`
- `CLAUDE.md.tmpl` → `CLAUDE.md` (overwrite)
- `.github/copilot-instructions.md.tmpl` → `.github/copilot-instructions.md` (overwrite)

Substitute placeholders: `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`.

If language was 中文, use `templates/i18n/zh/common/` overlay for the three files above.

### 6. Update the scripts to v0.10

Overwrite (with backup already in step 4):
- `scripts/harness-sync.ps1` ← from `templates/common/scripts/harness-sync.ps1`
- `scripts/harness-sync.sh` ← same
- `scripts/install-hooks.ps1` ← from `templates/common/scripts/install-hooks.ps1`
- `scripts/install-hooks.sh` ← same

Substitute `{{SYNC_COMMAND}}` in `.claude/settings.json` if it still has the v0.9.0/0.9.1 hardcoded `pwsh -File scripts/harness-sync.ps1` (no change needed if already v0.9.1+).

### 7. Run the new harness-sync and verify_all

```powershell
pwsh -File scripts/harness-sync.ps1
pwsh -File scripts/verify_all.ps1
```

If `verify_all` fails on `E.4` (bootstrap files reference AI-GUIDE.md), inspect the new stubs — they should mention `AI-GUIDE.md`. If they don't, re-copy from templates.

### 8. Summary report

Print:

```
✅ Migrated to v0.10 layout

Backup: .harness-migrate-backup/ (delete after verifying)
New bootstrap files:
  AI-GUIDE.md           (NEW — root-level tool-agnostic entry)
  CLAUDE.md             (REPLACED — ~15-line stub)
  .github/copilot-instructions.md  (REPLACED — same stub for Copilot)

Source of truth (unchanged):
  .harness/rules/*.md   (referenced from AI-GUIDE.md, no longer composed)
  .harness/agents/*.md  (still synced to .claude/agents/ by harness-sync)
  .harness/skills/*/    (still synced to .claude/skills/ by harness-sync)

Updated scripts:
  scripts/harness-sync.{ps1,sh}     (~70% smaller; only syncs agents + skills)
  scripts/install-hooks.{ps1,sh}    (updated pre-commit error message)
  scripts/verify_all.{ps1,sh}       (replaced E.4 check: bootstrap stubs)

verify_all status: <PASS/FAIL>

Next steps:
  1. Read the new AI-GUIDE.md to see how rules are now indexed.
  2. If you want to add a rule fragment, drop a .md into .harness/rules/ and
     append an index line to AI-GUIDE.md's "Rule fragments" section.
  3. Once verified, delete .harness-migrate-backup/ (or keep as a safety net).

Context budget improvement: persistent CLAUDE.md went from ~250 lines to ~15.
Per-session AI now loads AI-GUIDE.md once (~50 lines) and selectively reads
relevant .harness/rules/*.md fragments instead of all of them.
```

## Anti-patterns

- **Do not** delete `.harness-migrate-backup/` automatically — let the user verify first.
- **Do not** modify `.harness/rules/`, `.harness/agents/`, or `.harness/skills/` — they stay as-is.
- **Do not** run on a project that doesn't have `.harness/` — that's `/harness-init`.
- **Do not** prompt 5 questions like `/harness-init` — most info comes from the existing CLAUDE.md.

## Failure handling

- If templates aren't found → tell the user to install/update the harness-init skill first.
- If `CLAUDE.md` doesn't parse → ask the user for the missing fields.
- If file writes fail (permissions) → list which files made it; do not roll back the partial migration silently. The backup is the rollback path.
