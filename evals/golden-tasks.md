# Golden Tasks — Regression set for Harness Kit itself

> Manual regression checks. Re-run these after any change to:
> - `skills/*/SKILL.md`
> - `skills/harness-init/templates/`
> - `.claude/agents/*.md`
> - `docs/workflow.md`
> - `scripts/verify_all.*`

Personal-project scale — keep this list short and focused. If you need more, you're scaling up.

## Tasks

### Golden #0 — Integration on real project shape (`test-real-project`)

**Automated** — run [`scripts/test-real-project.ps1`](../scripts/test-real-project.ps1) or `.sh`.

```powershell
.\scripts\test-real-project.ps1
```

```bash
./scripts/test-real-project.sh
```

Overlays templates onto `tests/fixtures/todo-fullstack/` and `tests/fixtures/todo-backend/`
(real project shapes with `package.json`/`pyproject.toml`, source, tests, .gitignore) and
asserts the overlay doesn't damage existing files and produces a working Harness layout.

**Expected**: `PASS: 64 / FAIL: 0`. This complements Golden #1/#2 (which run on empty dirs)
by catching integration bugs that only show up on non-empty projects.

### Golden #1 & #2 — harness-init creates clean fullstack & backend skeletons

**Automated** — run [`scripts/test-init.ps1`](../scripts/test-init.ps1) (Windows) or
[`scripts/test-init.sh`](../scripts/test-init.sh) (Unix). The script:

- Creates a temp dir.
- Simulates `/harness-init`: copies common + project-type templates, substitutes
  the 5 placeholders, applies `.append` overlay to CLAUDE.md, removes `.tmpl`/`.append` suffixes.
- Runs ~32 assertions per project type (64 total).
- Cleans up.

```powershell
# Run both project types (default)
.\scripts\test-init.ps1

# Or a single type
.\scripts\test-init.ps1 -Type fullstack
.\scripts\test-init.ps1 -Type backend

# Keep the temp dir for manual inspection
.\scripts\test-init.ps1 -KeepTemp
```

```bash
./scripts/test-init.sh
./scripts/test-init.sh --type fullstack
./scripts/test-init.sh --keep
```

**Expected**: `PASS: 64 / FAIL: 0`. Exits non-zero on any failure.

Verifies (per type): all 7 agents copied, 3 stack skills (build/test/verify), settings.json,
CLAUDE.md with overlay, docs (workflow/dev-map/tasks/spec), evals, verify_all cross-platform,
placeholder substitution worked, no `.tmpl`/`.append` leaked.

### Golden #3 — verify_all FAILs if root .claude/agents/ drifts from templates (manual)

**Setup**:
1. Edit `.claude/agents/developer.md` and add a junk line.
2. Run `pwsh -File scripts/verify_all.ps1`.

**Expected**: `E.4 Self-template consistency` step FAIL with a diff message.

**Cleanup**:
```powershell
.\scripts\sync-self.ps1
```

### Golden #4 — install.ps1 dry-run shows the plan without writing (manual)

**How to run**:
```powershell
.\install.ps1 -DryRun
```

**Expected**: lists 4 skills, prints `[dry-run] Would copy ...` lines, exits cleanly. No file is created at `~/.claude/skills/`.

### Golden #5 — install.ps1 and install.sh produce identical layouts (manual)

Run each on a fresh `--dry-run` and diff their reported plans. Differences should be only OS-specific (path separators, etc.), not skill names or behaviors.

---

## History

| Date | What changed | Goldens re-run | Result |
|---|---|---|---|
| 2026-05-15 | Initial release (v0.1.0) | #1, #2 via test-init.ps1 | 64/64 PASS |
| 2026-05-15 | v0.2.0 + v0.3.0 + integration tests | #0 via test-real-project; #1, #2 via test-init | 64+86 PASS |
