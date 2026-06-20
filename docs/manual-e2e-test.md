# Manual End-to-End Test Checklist

Automated regression (`.harness/scripts/test-init.ps1` at 287 assertions; `.harness/scripts/test-init.sh` at 249 when python3 is unavailable (e.g. Windows Microsoft Store stub) / 287 when present; `.harness/scripts/verify_all` at 32 checks; `.harness/scripts/test-supervisor.ps1` at 49 assertions / `.harness/scripts/test-supervisor.sh` at 45 (no-python3) covering the supervisor agent contract + AC-4..AC-7 + BUG-1 fixed-case Q-1 + BUG-2 column-anchored-slug negative fixtures; `.harness/scripts/test-verify-i6.{ps1,sh}` at 58/58 covering the I.6 gap-tolerant matcher + 2×2 structural lockstep + AC-8 permanent fixture; live counts in `.harness/scripts/baseline.json`) covers everything
that runs from a shell. But two things must be exercised in a real Claude Code
session to confirm the experience:

1. **Skill discovery** — does Claude Code actually load the seventeen skills?
2. **Skill interaction** — does `/harness-init` correctly call `AskUserQuestion`,
   substitute placeholders, run `harness-sync`, and leave a usable project?

This page is the manual checklist for that. Run it once after install / after
upgrading / before announcing a release.

> Time: ~15 minutes for the full checklist. Skip sections that don't apply.

## Prerequisites

- This repo cloned to `~/harness-kit` (or any path; remember it).
- Claude Code installed and authenticated.
- An empty scratch directory at hand.

## A. Install verification

### A.1 Dry-run install

```powershell
& ~/harness-kit/install.ps1 -DryRun
```

```bash
~/harness-kit/install.sh --dry-run
```

**Expected**: prints "Would copy" for all 17 skills (harness, harness-init,
harness-adopt, harness-upgrade, harness-language, harness-verify, harness-status, harness-plan, harness-explore,
harness-goal, harness-batch, harness-stream, harness-intervene, harness-supervise, harness-decision-mode, harness-grill, harness-deflate). Exits 0. **No file is created** under
`~/.claude/skills/`.

### A.2 Real install

```powershell
& ~/harness-kit/install.ps1
```

```bash
~/harness-kit/install.sh
```

**Expected**: prints "Installed" for all 17 skills. After completion, list them:

```powershell
Get-ChildItem ~/.claude/skills/ -Directory | Select-Object Name
# Should show: harness, harness-adopt, harness-batch, harness-decision-mode, harness-deflate, harness-explore, harness-goal,
# harness-grill, harness-init, harness-intervene, harness-language, harness-plan, harness-status, harness-stream, harness-supervise, harness-upgrade, harness-verify
```

### A.3 Claude Code sees them

Open Claude Code in any folder. Type `/help` or look at the slash command picker.
**Expected**: the seventeen `/harness-*` commands appear (`/harness`, `/harness-init`,
`/harness-adopt`, `/harness-upgrade`, `/harness-language`, `/harness-verify`, `/harness-status`, `/harness-plan`,
`/harness-explore`, `/harness-goal`, `/harness-batch`, `/harness-stream`, `/harness-intervene`, `/harness-supervise`, `/harness-decision-mode`, `/harness-grill`, `/harness-deflate`).

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
2. Claude asks **six** questions via the AskUserQuestion UI:
   - Project type (Fullstack / Backend / Generic)
   - Stack (free text)
   - Enable verify_all Stop hook (Yes / No)
   - Developer partitioning (Partitioned / Single — skipped for Generic)
   - Output language (English / 中文) — picking `中文` yields a **consumer-split** policy (human-facing output Chinese, AI-facing output English) in the generated `.harness/rules/00-core.md` "输出语言" section, not an "everything Chinese" policy.
   - AI customization of `50-<project>.md` (Yes / **No (default)**) — v0.16+. On Yes, the skill reads the stack string + top-level filenames + named manifests and drafts a tailored rule fragment with `<!-- source: ... -->` annotations; on No (default), the static `50-<type>.md` stub is used (byte-identical to v0.15.1).
3. Claude copies templates, substitutes placeholders, runs `harness-sync`.
4. Claude prints a summary listing source-of-truth vs generated artifacts.

### B.3 Inspect the result

Outside Claude Code, in the scratch folder:

```bash
ls -la
# Expected at minimum: .harness/  .claude/  CLAUDE.md  AI-GUIDE.md  scripts/  docs/  evals/
```

Check `.harness/` is the SOT:

```bash
ls .harness/agents/      # 7 agent files (pm-orchestrator.md, ... qa-tester.md)
ls .harness/rules/       # 00-core.md and 50-<type>.md
ls .harness/skills/      # build/, test/, verify/
```

Check `.claude/` is generated and `CLAUDE.md` is a stub pointing at `AI-GUIDE.md`:

```bash
ls .claude/agents/         # same 7 agent files (byte-identical to .harness/agents/)
cat CLAUDE.md | head -10   # ~15-line stub; first heading is "# <project> — bootstrap rules"
                           # and the body references AI-GUIDE.md + .harness/rules/*.md
cat AI-GUIDE.md | head -5  # the tool-agnostic entry, indexes every rule fragment
```

### B.4 Verify binding consistency

```bash
bash .harness/scripts/harness-sync.sh --check
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
