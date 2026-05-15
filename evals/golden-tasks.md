# Golden Tasks — Regression set for Harness Engineering itself

> Manual regression checks. Re-run these after any change to:
> - `skills/*/SKILL.md`
> - `skills/harness-init/templates/`
> - `.claude/agents/*.md`
> - `docs/workflow.md`
> - `scripts/verify_all.*`

Personal-project scale — keep this list short and focused. If you need more, you're scaling up.

## Tasks

### Golden #1 — harness-init creates a clean fullstack skeleton

**How to run**:
```powershell
$tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "harness-test-$(Get-Random)") -Force
Push-Location $tmp
# In a fresh Claude Code session:
#   /harness-init   (type=fullstack, stack=Next.js+NestJS, hook=No)
Pop-Location
Remove-Item -Recurse -Force $tmp
```

**Expected**:
- `.claude/agents/` has all 7 files.
- `CLAUDE.md` exists with the fullstack overlay sections.
- `scripts/verify_all.ps1` and `.sh` both exist.
- `scripts/baseline.json` exists with zero counts.
- `docs/workflow.md`, `dev-map.md`, `tasks.md`, `spec/README.md`, `evals/golden-tasks.md` exist.
- No `.tmpl` or `.append` files leaked into the result.

### Golden #2 — harness-init creates a clean backend skeleton

Same as #1 but `type=backend`, `stack=FastAPI+Postgres`. CLAUDE.md should have the backend overlay.

### Golden #3 — verify_all FAILs if root .claude/agents/ drifts from templates

**Setup**:
1. Edit `.claude/agents/developer.md` and add a junk line.
2. Run `pwsh -File scripts/verify_all.ps1`.

**Expected**: `E.4 Self-template consistency` step FAIL with a diff message.

**Cleanup**:
```powershell
.\scripts\sync-self.ps1
```

### Golden #4 — install.ps1 dry-run shows the plan without writing

**How to run**:
```powershell
.\install.ps1 -DryRun
```

**Expected**: lists 4 skills, prints `[dry-run] Would copy ...` lines, exits cleanly. No file is created at `~/.claude/skills/`.

### Golden #5 — install.ps1 and install.sh produce identical layouts

Run each on a fresh `--dry-run` and diff their reported plans. Differences should be only OS-specific (path separators, etc.), not skill names or behaviors.

---

## History

| Date | What changed | Goldens re-run | Result |
|---|---|---|---|
| 2026-05-15 | Initial release | #1–#5 (manual) | Pending |
