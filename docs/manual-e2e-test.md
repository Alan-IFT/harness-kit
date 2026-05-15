# Manual End-to-End Test Checklist

Automated regression (`scripts/test-init`, `scripts/verify_all`) covers everything
that runs from a shell. But two things must be exercised in a real Claude Code
session to confirm the experience:

1. **Skill discovery** — does Claude Code actually load the four skills?
2. **Skill interaction** — does `/harness-init` correctly call `AskUserQuestion`,
   substitute placeholders, run `harness-sync`, and leave a usable project?

This page is the manual checklist for that. Run it once after install / after
upgrading / before announcing a release.

> Time: ~15 minutes for the full checklist. Skip sections that don't apply.

## Prerequisites

- This repo cloned to `~/harness-engineering` (or any path; remember it).
- Claude Code installed and authenticated.
- An empty scratch directory at hand.

## A. Install verification

### A.1 Dry-run install

```powershell
& ~/harness-engineering/install.ps1 -DryRun
```

```bash
~/harness-engineering/install.sh --dry-run
```

**Expected**: prints "Would copy" for all 4 skills (harness-init, harness-adopt,
harness-verify, harness-status). Exits 0. **No file is created** under
`~/.claude/skills/`.

### A.2 Real install

```powershell
& ~/harness-engineering/install.ps1
```

```bash
~/harness-engineering/install.sh
```

**Expected**: prints "Installed" for all 4 skills. After completion, list them:

```powershell
Get-ChildItem ~/.claude/skills/ -Directory | Select-Object Name
# Should show: harness-adopt, harness-init, harness-status, harness-verify
```

### A.3 Claude Code sees them

Open Claude Code in any folder. Type `/help` or look at the slash command picker.
**Expected**: the four `/harness-*` commands appear.

If they don't appear: restart Claude Code; if still missing, check that
`~/.claude/skills/harness-init/SKILL.md` exists and has valid frontmatter
(`name:` and `description:`).

## B. /harness-init in a new project

### B.1 Set up a scratch folder

```powershell
$scratch = "$env:TEMP\harness-e2e-$(Get-Random)"
New-Item -ItemType Directory -Path $scratch -Force
cd $scratch
claude
```

```bash
scratch="/tmp/harness-e2e-$$"
mkdir -p "$scratch" && cd "$scratch"
claude
```

### B.2 Run init

In Claude Code:

```
/harness-init
```

**Expected flow**:

1. Claude confirms the target directory.
2. Claude asks **three** questions via the AskUserQuestion UI:
   - Project type (Fullstack / Backend)
   - Stack (free text)
   - Enable verify_all hook (Yes / No)
3. Claude copies templates, substitutes placeholders, runs `harness-sync`.
4. Claude prints a summary listing source-of-truth vs generated artifacts.

### B.3 Inspect the result

Outside Claude Code, in the scratch folder:

```bash
ls -la
# Expected at minimum: .harness/  .claude/  CLAUDE.md  scripts/  docs/  evals/
```

Check `.harness/` is the SOT:

```bash
ls .harness/agents/      # 7 agent files (pm-orchestrator.md, ... qa-tester.md)
ls .harness/rules/       # 00-core.md and 50-<type>.md
ls .harness/skills/      # build/, test/, verify/
```

Check `.claude/` is generated:

```bash
ls .claude/agents/       # same 7 agent files (byte-identical to .harness/agents/)
cat CLAUDE.md | head -5  # starts with "<!-- THIS FILE IS GENERATED ... -->"
```

### B.4 Verify binding consistency

```bash
bash scripts/harness-sync.sh --check
# Expected: "In sync."
```

### B.5 Try a small task

In the Claude Code session (still in the scratch folder):

```
Take this task: Add a constant DEMO = "hello" to a new file src/config.ts.
```

**Expected**:

- PM Orchestrator routes to Requirement Analyst.
- Each stage produces a doc under `docs/features/<slug>/`.
- Developer creates `src/config.ts` and (for non-trivial flow) updates dev-map.
- Final stage: PM writes `07_DELIVERY.md`, updates `docs/tasks.md`.

If the flow stalls or rolls back, note where — that's a defect to fix.

### B.6 Cleanup

```bash
rm -rf "$scratch"
```

## C. /harness-verify

In the scratch folder (after B):

```
/harness-verify
```

**Expected**: PASS / WARN / FAIL summary. For a freshly-init'd project with no
actual code, `verify_all` will likely have WARN or FAIL on build/test steps (no
package.json yet). That's expected; structural checks (E.* steps) should PASS.

## D. /harness-status

```
/harness-status
```

**Expected**: snapshot listing which Harness assets are present, baseline state,
last verify result, active tasks (should show the one from B.5 if you ran it),
and a health score.

## E. /harness-adopt on an existing project (v0.3+ automated apply)

1. `cd` into any existing project with code (e.g. a real repo, ideally one you
   don't mind a *.harness-adopt/* folder appearing in for the test).
2. `/harness-adopt`
3. **Expected reconnaissance phase**:
   - Lists detected languages / frameworks / test runners / CI / existing docs.
   - Asks via AskUserQuestion to confirm: project type, stack, enable verify hook.
4. **Expected plan phase**:
   - Writes `.harness-adopt/PLAN.md` and `.harness-adopt/CLAUDE.draft.md`.
   - Asks "Apply this plan? [yes / no / show full plan]".
5. Pick "no" the first time and review the plan. Then re-run and pick "yes":
   - All new files appear in `.harness/`, `.claude/`, `scripts/`, `docs/`, `evals/`.
   - **No existing source code, tests, or configs are modified.**
   - If your project already had `CLAUDE.md` or `.harness/`: merge mode skips
     conflicts, overwrite mode prompts per-file.
   - `harness-sync` runs automatically; `verify_all` runs to capture baseline.
6. Inspect `.harness-adopt/CONFLICTS.md` (if it exists) and decide on conflicts.
7. Try a task to validate.
8. Cleanup: optionally delete `.harness-adopt/` and add it to `.gitignore`.

## F. Sign-off

| Section | Status | Notes |
|---|---|---|
| A.1 dry-run install | ☐ |  |
| A.2 real install | ☐ |  |
| A.3 skills appear in Claude Code | ☐ |  |
| B.1-B.6 init + first task | ☐ |  |
| C verify | ☐ |  |
| D status | ☐ |  |
| E adopt plan | ☐ |  |

When all checked: the release is verified end-to-end. Tag and announce.

If any section failed: file an issue with section letter + reproduction; do not
ship.
