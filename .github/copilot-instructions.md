---
applyTo: "**"
---
> ⚠️ **GENERATED FILE — DO NOT EDIT DIRECTLY**
>
> Source of truth: `.harness/rules/*.md` (composed in filename order)
> After editing the source, run `scripts/harness-sync.ps1` (or `.sh`) to regenerate.
> `verify_all` will FAIL if this file drifts from the source.

<!-- generated marker: keep in sync with harness-sync output -->
# Harness Kit — Project Rules (self-dogfood)

> This repo **uses its own Harness setup**. The same 7-agent pipeline that we ship to users
> governs work on this repo. If we can't develop this repo with it, we shouldn't ship it.
>
> "Harness Engineering" remains the name of the methodology this project implements; the project
> itself is called **Harness Kit** (the distribution of skills + templates).

## Project type

**Tooling / Skills library + Claude Code Plugin** — not fullstack, not backend. It distributes
Claude Code skills and project templates. Build / test characteristics:

- Primary "code" is Markdown (Skill definitions, agent definitions, docs).
- Secondary code is PowerShell + Bash scripts (verify_all, install scripts).
- Templates under `skills/harness-init/templates/` are the **source of truth** for distributed assets.

## How development flows

Every non-trivial change → 7-agent pipeline (see [`docs/workflow.md`](docs/workflow.md)).

For this repo specifically, "non-trivial" means:
- New skill or template
- Change to any agent definition
- Change to verify_all or its checks
- Change to workflow or rules

Trivial (single typo, comment update, dependency bump): direct edit + `scripts/verify_all`.

## When in doubt

- Read `docs/concepts.md` to understand why a piece exists.
- Read `docs/workflow.md` for stage transitions.
- If a rule conflicts with the situation, stop and ask the user — don't improvise.

## Self-template consistency (red lines)

This repo dogfoods two layers of consistency:

### Layer 1: templates ↔ this repo

1. **The source of truth for the 7 agents and `harness-sync` scripts is `skills/harness-init/templates/common/`.**
2. The root `.harness/agents/` and `scripts/harness-sync.{ps1,sh}` are **byte-identical copies**.
3. If you change one, run `scripts/sync-self.{ps1,sh}` before commit.
4. `verify_all` step `E.1` checks this and FAILs on drift.

### Layer 2: .harness ↔ .claude (the binding)

5. **The source of truth for project-level Claude Code assets is `.harness/`** (agents, rules).
6. `.claude/agents/` and `CLAUDE.md` are **generated** from `.harness/` via `scripts/harness-sync.{ps1,sh}`.
7. **Never hand-edit** `.claude/agents/*.md` or `CLAUDE.md`. Edit `.harness/` and run sync.
8. `verify_all` step `E.4` and `E.5` check `.harness/ ↔ .claude/` and `.harness/rules/ ↔ CLAUDE.md` and FAIL on drift.

## Template integrity

9. **Every `.tmpl` file** must have its placeholders documented in `skills/harness-init/SKILL.md`.
10. Don't introduce a placeholder that the SKILL doesn't substitute.
11. Test the init flow after any template change via `scripts/test-init.{ps1,sh}`.

## Documentation rules

12. **README, CHANGELOG, docs/getting-started, docs/concepts** stay in sync with the actual code.
13. If you add a skill, document it in README's "Quick start" and CHANGELOG.
14. No documentation made-up examples; show real, runnable commands.
15. If you change a rule, also update any `docs/*.md` that referenced it.

## Software engineering basics

16. Commit messages in imperative mood, ≤72 char subject, body explains the why.
17. PR-able diffs: each commit is a coherent unit; don't bundle unrelated changes.
18. No commit of files in `参考/` (private reference folder, in `.gitignore`).
19. No commit of secrets, `.env`, or local user paths.
20. PowerShell and Bash scripts are symmetric — if you change one, change the other.

## What lives where

| Need | Look at |
|---|---|
| Distributed skills | `skills/<name>/SKILL.md` |
| Project templates (distribution source of truth) | `skills/harness-init/templates/` |
| Agent role definitions (this repo's source of truth) | `.harness/agents/` |
| Rule source files (this repo's source of truth) | `.harness/rules/` |
| Generated CLAUDE.md (do not edit) | `CLAUDE.md` |
| Generated .claude/ (do not edit) | `.claude/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Project repo navigation | `docs/dev-map.md` |
| Total verification | `scripts/verify_all.{ps1,sh}` |
| Binding sync (`.harness/` → `.claude/` + `CLAUDE.md`) | `scripts/harness-sync.{ps1,sh}` |
| Repo-self sync (`templates/` → `.harness/`) | `scripts/sync-self.{ps1,sh}` |
| Init regression | `scripts/test-init.{ps1,sh}` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |

## Verify before declaring done

`scripts/verify_all` checks (15+ items, all must PASS):

- No secrets / committed env files
- `参考/` not tracked
- Required scaffolding present (README, LICENSE, CHANGELOG, CONTRIBUTING, installers)
- All 4 skills present with valid frontmatter
- All 7 template agents present
- Placeholder whitelist enforced (5 allowed)
- `.harness/agents/` matches `templates/common/.harness/agents/` (Layer 1)
- `.claude/agents/` matches `.harness/agents/` (Layer 2 binding)
- `CLAUDE.md` matches `.harness/rules/*.md` composed (Layer 2 binding)
- Project rules / docs present
- evals/golden-tasks.md present
- Script pairs (.ps1 + .sh) for verify_all / harness-sync / sync-self / test-init
- README and CHANGELOG reference all skills

Run after every change; do not skip.

## Tool handoff (Claude Code ↔ GitHub Copilot)

This project may be developed across multiple AI tools — typically Claude Code as
the primary, with Copilot as a fallback when Claude Code hits rate limits or
when a contributor uses a different IDE. Any AI agent reading this — Claude
Code's PM Orchestrator, a Claude Code sub-agent, or GitHub Copilot — must
follow this protocol to keep work continuous across tool switches.

### Core principle

**All task state lives in files, not in chat session memory.** The complete
recoverable state of any in-flight task is:

- `docs/tasks.md` — the task board: which tasks exist, what stage each is at.
- `docs/features/<task-slug>/` — per-task documents 01–07 plus `PM_LOG.md`.
- `.harness/agents/*.md` — role contracts each agent must obey.
- `.harness/rules/*.md` (this file lives here) — project-wide rules.

Anything not in these files **is not state** — it's chat noise. When you
hand off, persist what matters to these files; when you resume, read these
files first.

### How to resume a task (any AI tool, after a context switch)

When the user says "continue task T-XXX" or "what's in progress":

1. Read `docs/tasks.md`. Find the row with `stage` ≠ `done` (most recently
   started, if multiple).
2. Read `docs/features/<task-slug>/PM_LOG.md` — the last entry tells you which
   agent should act next and any pending blockers.
3. Read every existing stage document in order: `01_REQUIREMENT_ANALYSIS.md`,
   `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`
   (or `04a_DEVELOPMENT_<partition>.md` for partitioned mode),
   `05_CODE_REVIEW.md`, `06_TEST_REPORT.md`. Skip any that don't exist —
   that's the stage you're at or before.
4. Determine the role to assume:
   - If using Claude Code: PM Orchestrator (yourself if you're the PM) reads
     the partition assignment from `02_SOLUTION_DESIGN.md` and dispatches the
     correct sub-agent via the Task tool. Sub-agents don't enter resume mode
     directly — PM routes them.
   - If using Copilot or another tool without sub-agent dispatch: read the
     role file `.harness/agents/<role>.md` for the agent that should be next
     (per step 2's PM_LOG entry). **Assume that role personally.** Follow its
     contract precisely — read what it reads, write what it writes, respect
     the partition rule if any.
5. Produce the next stage's document (or continue the current stage's
   document if you're mid-stage). Write it to `docs/features/<task-slug>/`.
6. Append one line to `PM_LOG.md`: timestamp · agent name · "completed
   stage X, next stage Y handled by Z agent".
7. Update `docs/tasks.md`'s `stage` field for this task.

### How to hand off mid-task

When you (any AI) reach a stopping point — rate limit imminent, user
switching IDE, end of session:

1. Finish the current stage if possible. If not, write a `PARTIAL.md` in
   `docs/features/<task-slug>/` describing exactly where you stopped and
   what the next agent should do.
2. Append the final `PM_LOG.md` entry: timestamp · "handoff at stage X · next
   action: Y by agent Z".
3. Make sure `docs/tasks.md` `stage` column is current.
4. If verify_all needs to be re-run after a partial change, note that in the
   PM_LOG entry.

### Tool-specific notes

- **Claude Code**: PM Orchestrator is the routing agent. It reads PM_LOG,
  dispatches sub-agents. The full 7-stage pipeline is native. The Stop hook
  in `.claude/settings.json` auto-runs `scripts/harness-sync` at session
  end, so `.harness/` edits flow to `CLAUDE.md` + `.github/copilot-instructions.md`
  without user intervention.
- **GitHub Copilot**: No sub-agent dispatch. You (Copilot) play whichever
  role the protocol points you to. **One role at a time.** When you finish
  your stage, stop and ask the user to "switch to next agent" — do not
  silently move on as a different role. Cross-stage handoffs go through the
  user (who'll usually switch back to Claude Code for PM routing, or
  manually tell you to assume the next role).

### Doc-sync responsibility when not on Claude Code

The Stop hook above is **Claude-Code-specific** — it does NOT fire for
Copilot, Cursor, or hand-edits. If you (Copilot or any non-Claude-Code AI)
edit any file under `.harness/`, you have two equally valid ways to keep
`CLAUDE.md` and `.github/copilot-instructions.md` from going stale:

1. **Run sync before declaring your turn done.** Execute
   `pwsh -File scripts/harness-sync.ps1` (Windows) or
   `bash scripts/harness-sync.sh` (macOS / Linux) immediately after the edit.
   Then stage the regenerated `CLAUDE.md` / `.github/copilot-instructions.md`
   along with your `.harness/` change.
2. **Let the git pre-commit hook catch it.** If `scripts/install-hooks.{ps1,sh}`
   was run during init, `.git/hooks/pre-commit` runs `harness-sync --check`
   and blocks any commit with drift. You'll see a clear error telling you
   to run sync.

The pre-commit hook is the tool-agnostic backstop — it catches any tool,
any human. The "run sync before done" rule is the gentler, faster path
and keeps the working tree always consistent during the session.

Hand-edits to generated files (`CLAUDE.md`, `.github/copilot-instructions.md`,
`.claude/agents/*.md`, `.claude/skills/*/SKILL.md`) are **always wrong** —
they get clobbered by the next sync. Edit `.harness/` and sync.

### Hard rules across all tools

- Never edit `docs/features/<task>/01–07` documents authored by an upstream
  agent. If you (current agent) need them changed, write a blocker in
  PM_LOG and stop — the original author re-does it.
- Never skip a stage on resume. If `03_GATE_REVIEW.md` is missing but
  `02_SOLUTION_DESIGN.md` exists, you (or PM) must run Gate Review before
  development.
- Never declare a task done without `07_DELIVERY.md` and a final
  `verify_all` PASS.
- The "Output language" rule above applies during resume too. If the
  project is Chinese, even Copilot continues in Chinese.
