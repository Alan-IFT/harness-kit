---
name: harness-adopt
description: Adopt Harness Engineering into an existing project. Scans the repo, extracts conventions, proposes a Harness skeleton without overwriting existing code. Use for projects that already have code but no Harness setup.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-adopt

Non-invasively add Harness to a project that already has code, tests, and CI.

## When to invoke

- The project already has source code, tests, package manifests.
- You want the 7-agent workflow available but **don't want to rewrite anything**.

For empty projects, use `/harness-init` instead.

## Procedure

### 1. Confirm target

Current working directory is the target. Confirm `.git/` exists. Stop if not.

If `.claude/agents/` or `CLAUDE.md` already exists, **stop and ask**:
- "Overwrite, merge, or abort?"

### 2. Reconnaissance phase (dry-run by default)

Detect:

- **Languages / frameworks**: presence of `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `tsconfig.json`, `next.config.*`, `nest-cli.json`, `prisma/`, `alembic.ini`, `manage.py`, etc.
- **Test framework**: `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pytest.ini`, `go test`, `tests/`, `__tests__/`.
- **CI**: `.github/workflows/*`, `.gitlab-ci.yml`, `.circleci/`.
- **Existing rules**: `README.md`, `CONTRIBUTING.md`, `.editorconfig`, `.eslintrc*`, `.prettierrc*`, `pyproject.toml [tool.*]`.
- **Existing docs**: `docs/`, `ADR/`.

Output a project profile:

```
Detected:
  Type:           [fullstack | backend]
  Languages:      [TypeScript, Python, ...]
  Frameworks:     [Next.js, NestJS, Prisma, ...]
  Test runners:   [Vitest, Playwright, ...]
  CI:             [GitHub Actions]
  Existing docs:  [README, CONTRIBUTING, docs/]
```

### 3. Propose rule extraction

Read the existing `README.md`, `CONTRIBUTING.md`, `.editorconfig`, and lint configs. Extract candidate rules:

- Coding style hard rules (e.g. "always use named exports")
- Commit message conventions
- Branch naming
- PR / review conventions
- Existing build/test commands

Present as a draft `.harness-adopt/CLAUDE.draft.md` — **do not** write `CLAUDE.md` directly yet.

### 4. Propose Harness assets (still dry-run)

Write proposed file list to `.harness-adopt/PLAN.md`:

```
Proposed additions:
  + CLAUDE.md             (from .harness-adopt/CLAUDE.draft.md, you should review)
  + .claude/agents/*.md   (7 agents, standard templates)
  + .claude/skills/*.md   (build/test/verify, wired to your existing commands)
  + .claude/settings.json (permissions calibrated to your stack)
  + docs/workflow.md      (7-stage pipeline definition)
  + docs/dev-map.md       (initial draft from your folder structure)
  + docs/tasks.md         (empty task board)
  + scripts/verify_all.*  (wraps your existing build/test commands)
  + scripts/baseline.json (will capture current test count after first run)
  + evals/golden-tasks.md (template; you fill in)

No existing file is modified or deleted.

Conflicts noted:
  - You already have .github/workflows/ci.yml. Harness verify_all is independent;
    keep both. Optional: call verify_all from CI later.
  - You have CONTRIBUTING.md. Harness draft CLAUDE.md references it; not overwriting.
```

### 5. Generate dev-map draft

Crawl the source folder structure (one level deep on top dirs, summarize):

```markdown
# Dev Map (auto-generated draft — review and edit)

## Folder layout
- `apps/web/` — Next.js frontend
- `apps/api/` — NestJS backend
- `packages/shared/` — shared types
- `prisma/` — DB schema and migrations

## Where features live (TODO: confirm)
- User-facing pages: `apps/web/app/`
- API routes: `apps/api/src/modules/`
- DB models: `prisma/schema.prisma`

## Reusable utilities (TODO: list known ones)
```

### 6. Ask user to confirm

Print the plan summary and ask:

```
Apply the plan above? [yes / no / show diff]
```

If yes → execute step 7. If no → leave `.harness-adopt/` for review and stop.

### 7. Apply

Copy files into place using the same template logic as `/harness-init` (substitute `{{PROJECT_NAME}}`, `{{STACK}}`, `{{TODAY}}`). Source templates from the installed skill (`~/.claude/skills/harness-init/templates/`).

After copying:
- Run `scripts/verify_all` once to capture **current** state into baseline.
- Print success report identical to harness-init's step 9.

## Hard rules

- **No existing file is modified or deleted.** Only additions.
- **No silent overwrite** of `CLAUDE.md` or `.claude/`. Always confirm with user.
- **Verify-all baselines current state**, not zero — preserves what already works.

## Anti-patterns

- Don't try to rewrite the user's CI to call verify_all without asking.
- Don't extract rules and then assert them — present as a draft, user reviews.
- Don't generate dev-map from imagination; only from actual folder structure.

## Limitations of this v0.1.0

- Stack-detection covers Node/Python/Go basics; exotic stacks may need manual edits.
- Rule extraction is keyword-based, not semantic; expect to refine the draft.
- No deep code analysis; reuse audit will come on first agent run.
