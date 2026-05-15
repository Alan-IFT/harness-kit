# Getting Started

This guide walks you from "I just discovered Harness Engineering" to "I'm shipping features through it".

## Prerequisites

- [Claude Code](https://docs.claude.com/claude-code) installed and authenticated
- Git
- A project (or an empty folder if starting fresh)
- PowerShell 7+ (Windows) or Bash (macOS / Linux)

## 1. Install the skills

```powershell
# Windows
git clone https://github.com/<your>/harness-engineering ~/harness-engineering
& ~/harness-engineering/install.ps1
```

```bash
# macOS / Linux
git clone https://github.com/<your>/harness-engineering ~/harness-engineering
~/harness-engineering/install.sh
```

This drops four skills into `~/.claude/skills/`:

- `harness-init`
- `harness-adopt`
- `harness-verify`
- `harness-status`

Verify with `/help` inside Claude Code — you should see them listed.

## 2. Bootstrap your project

### New project (empty folder)

```
cd /path/to/empty/folder
claude   # start Claude Code
> /harness-init
```

Answer the three questions (type, stack, verify hook). The skill generates:

- `.claude/agents/` — 7 sub-agents
- `.claude/skills/` — build, test, verify
- `.claude/settings.json` — permissions + optional hooks
- `CLAUDE.md` — project rules
- `docs/` — workflow, spec folder, dev-map, task board
- `scripts/verify_all.{ps1,sh}` — total verification
- `scripts/baseline.json` — test count baseline (starts at zero)
- `evals/golden-tasks.md` — regression task set

### Existing project (already has code)

```
cd /path/to/existing/project
claude
> /harness-adopt
```

The skill scans your repo, detects stack, extracts conventions from `README` / `CONTRIBUTING` / lint configs, and writes a **plan** (`.harness-adopt/PLAN.md`). Review it, then confirm to apply.

## 3. Your first task

In Claude Code, give the PM Orchestrator a task:

```
Take this task: Add a CSV export button to the orders list page.
```

The PM will:
1. Create `docs/features/csv-export-orders/`.
2. Read `docs/tasks.md` for related history.
3. Dispatch the Requirement Analyst.
4. Dispatch each subsequent stage in order, checking gate criteria.
5. At the end, write `07_DELIVERY.md` and update `docs/tasks.md`.

You typically only need to:
- Answer ambiguity questions when the analyst asks.
- Review at Gate (stage 3) and Code Review (stage 5).
- Confirm any production-risky action.

## 4. Daily workflow

| You want to... | Do this |
|---|---|
| Start a new feature or bug fix | Tell PM Orchestrator: "Take this task: ..." |
| Check verify is still green | `/harness-verify` |
| See current Harness health | `/harness-status` |
| Add a new project-wide rule | Edit `CLAUDE.md`; add a verify_all check if possible |
| Add a repeatable operation | Add a skill under `.claude/skills/<name>/SKILL.md` |
| Update what files exist where | Edit `docs/dev-map.md` (the developer agent does this for you) |
| Run regression after Harness changes | Re-run tasks in `evals/golden-tasks.md` |

## 5. When AI makes a mistake

The Harness philosophy: **don't retry; fix the rail**.

| The mistake | Where to fix it |
|---|---|
| AI used a forbidden API / style | Add a rule in `CLAUDE.md`; add a check in `verify_all` |
| AI forgot a step (e.g. lint before commit) | Add a skill `.claude/skills/<name>/SKILL.md` |
| Two agents stepped on each other | Edit `.claude/agents/<agent>.md` to tighten the contract |
| AI lacks an external capability | Add an MCP server, register it in `.claude/settings.json` |
| A whole stage of work was missed | Add a new agent and update `docs/workflow.md` |

This way mistakes ratchet up the Harness instead of repeating.

## 6. What you shouldn't expect this to do

- **Replace your testing**. It verifies tests run; you still write meaningful ones.
- **Replace code review for security-critical code**. Use `/security-review` skill or human review.
- **Decide whether to ship**. The pipeline produces a verdict; you decide.
- **Operate production**. Anything destructive is HITL by design.

## 7. Next reading

- `docs/workflow.md` — full 7-stage pipeline detail
- `docs/concepts.md` — why each piece exists
- `architecture.html` — visual architecture overview (open in browser)
- `CHANGELOG.md` — what's in this release

## Troubleshooting

**Skill not found in Claude Code.**
Check `~/.claude/skills/harness-init/SKILL.md` exists. Restart Claude Code if you installed it mid-session.

**verify_all says PowerShell can't run scripts.**
On Windows you may need `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

**The PM keeps rolling back to the analyst.**
Probably an ambiguous requirement. Read the analyst's questions and answer them — the loop ends when nothing is ambiguous.

**Generated CLAUDE.md doesn't match my style.**
Edit it. The template is a starting point; the project owns the rules.
