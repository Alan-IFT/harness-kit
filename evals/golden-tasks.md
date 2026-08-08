# Golden Tasks — Regression set for Harness Kit itself

> Manual regression checks. Re-run these after any change to:
> - `skills/*/SKILL.md`
> - `skills/harness-init/templates/`
> - `agents/*.md`
> - `docs/workflow.md`
> - `.harness/scripts/verify_all.sh`

Personal-project scale — keep this list short and focused. If you need more, you're scaling up.

**Linux / macOS only.** Windows support was removed: there is no `.ps1` twin of any script and
no `install.ps1`. A golden that existed only to compare the two shells' output went with them.

## Tasks

### Golden #0 — Integration on real project shape (`test-real-project`)

**Automated** — run [`.harness/scripts/test-real-project.sh`](../.harness/scripts/test-real-project.sh).

```bash
./.harness/scripts/test-real-project.sh
```

Overlays templates onto `tests/fixtures/todo-fullstack/` and `tests/fixtures/todo-backend/`
(real project shapes with `package.json`/`pyproject.toml`, source, tests, .gitignore) and
asserts the overlay doesn't damage existing files and produces a working Harness layout.

**Expected**: `PASS: 90 / FAIL: 0` (live count in `.harness/scripts/baseline.json`). This
complements Golden #1/#2 (which run on empty dirs) by catching integration bugs that only show
up on non-empty projects.

### Golden #1 & #2 — harness-init creates clean fullstack & backend skeletons

**Automated** — run [`.harness/scripts/test-init.sh`](../.harness/scripts/test-init.sh). The script:

- Creates a temp dir.
- Simulates `/harness-init`: copies common + project-type templates, substitutes
  the 5 placeholders, applies `.append` overlay to CLAUDE.md, removes `.tmpl`/`.append` suffixes.
- Runs the per-type assertion set for both project types.
- Cleans up.

```bash
./.harness/scripts/test-init.sh
./.harness/scripts/test-init.sh --type fullstack
./.harness/scripts/test-init.sh --keep
```

**Expected**: the `PASS: N / FAIL: 0` line, with `N` matching the pinned count in
`.harness/scripts/baseline.json`. Exits non-zero on any failure. The count is python3-sensitive
— the AI-native block is gated on it — so compare against the key that names your case.

Verifies (per type): all 7 agents copied, 3 stack skills (build/test/verify), settings.json,
CLAUDE.md with overlay, docs (workflow/dev-map/tasks/spec), evals, placeholder substitution
worked, no `.tmpl`/`.append` leaked.

### Golden #3 — verify_all FAILs if agents/ drifts from templates (manual)

**Setup**:
1. Edit `agents/developer.md` and add a junk line.
2. Run `bash .harness/scripts/verify_all.sh`.

**Expected**: the `E.*` self-template consistency step FAILs with a diff message.

**Cleanup**:
```bash
bash .harness/scripts/sync-self.sh
```

### Golden #4 — install.sh dry-run shows the plan without writing (manual)

**How to run**:
```bash
./install.sh --dry-run
```

**Expected**: lists the shipped skills, prints `[dry-run] Would copy ...` lines, exits cleanly.
No file is created at `~/.claude/skills/`.

---

## History

| Date | What changed | Goldens re-run | Result |
|---|---|---|---|
| 2026-05-15 | Initial release (v0.1.0) | #1, #2 via test-init | 64/64 PASS |
| 2026-05-15 | v0.2.0 + v0.3.0 + integration tests | #0 via test-real-project; #1, #2 via test-init | 64+86 PASS |
| 2026-08-08 | Windows support removed (v0.49.0) | goldens rewritten to the single shell; #5 retired | — |
