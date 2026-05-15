# Core Concepts

This document explains **why** each Harness component exists, not just what it does.
For the "what", see [getting-started.md](getting-started.md).

## The big picture (v0.2)

```
Layer 2: Project tool-agnostic SOT      (this repo provides templates)
  .harness/{agents, rules, skills}

       ↓ harness-sync (binding)

Layer 1: Claude Code binding artifacts  (generated; do not hand-edit)
  .claude/{agents, skills, settings.json} + CLAUDE.md

       ↓ runs on

Layer 0: Claude Code platform           (already shipped, we don't rebuild)
  Permission / sub-agents / Hooks / MCP / Memory / Skills / auto-compaction
```

**Layer 0 = mechanism. Layer 1 = generated binding artifacts. Layer 2 = your content.**
Claude Code provides the engine. We provide the rails. You write the content.

The split between Layer 1 and Layer 2 (introduced in v0.2) is what lets project
knowledge survive when you switch IDEs or add a Cursor binding later. Edit Layer 2;
Layer 1 regenerates.

## Why a tool-agnostic source-of-truth layer?

If your agent definitions, rules, and skills live directly inside `.claude/`, they're
**tied to Claude Code**. The day you want to:

- run the same project rules through Cursor or Copilot
- contribute the project to a team where some use other IDEs
- migrate a vendor lock-in
- treat project knowledge as a first-class asset alongside code

…you're in trouble. Migrating means rewriting.

Putting them in `.harness/` and generating `.claude/` from it means:

- The knowledge is **stored once**, in a tool-agnostic form.
- Each tool gets its **own binding generator** (we only ship Claude Code today; Cursor would be a future addition).
- The binding artifacts are reproducible — wipe `.claude/` and re-run sync.
- Diffs in `.claude/` show what *binding* changed, not what *content* changed.

## Why 7 agents and not 1?

A single agent doing requirements + design + code + tests has structural problems:

| Single agent symptom | Why it happens |
|---|---|
| Self-confirmation | The author of a design naturally defends it during review. |
| Context overload | One context window holding all stages dilutes attention. |
| No quality gate | A design defect rolls into code with no checkpoint. |
| No audit trail | Decisions are scattered through a single chat log. |

Splitting into 7 agents enforces **role separation** like a real team. Each role's
job is narrow; each role's output is a document; transitions are governed.

## Why these 7?

| Agent | Solves the problem of... |
|---|---|
| Requirement Analyst | Vague request being implemented before it's understood. |
| Solution Architect | Design decisions being made by whoever happened to code first. |
| Gate Reviewer | Defects reaching development that should've been caught in design. |
| Developer | (always existed) |
| Code Reviewer | Author-blindness; missing acceptance criteria. |
| QA Tester | "It compiles, ship it" without verifying user-visible behavior. |
| PM Orchestrator | Free-form Agent chat with no routing discipline. |

## Why doesn't the PM make professional decisions?

If the PM gives technical opinions, the system regresses to "one big agent". The PM
is a router; specialist agents are specialists. This sounds bureaucratic but it's what
makes the system maintainable: you can swap one agent without re-deciding everything.

## Why can't the downstream edit upstream?

If the Reviewer can fix the code, it's also auditing its own fix → quality regression.
If the Gate can edit the requirement, the analyst's accountability evaporates. The fix
is to route back via PM — the cost of one rollback is tiny compared to lost accountability.

## Why are Rule / Skill / Script three layers?

| Layer | What it is | Where it lives | Why separated |
|---|---|---|---|
| Rule | Soft constraints, natural language | `.harness/rules/*.md` | AI reads it but may forget under long context. Good for principles. |
| Skill | Standard operating procedure | `.harness/skills/<name>/SKILL.md` | Codifies repeated actions so AI doesn't improvise. |
| Script | Hard gate | `scripts/verify_all.{ps1,sh}` | Machine-checkable. AI cannot "interpret it away". |

The progression is: write a rule, see if AI follows it; if not, encode it as a check.

## Why CLAUDE.md is generated, not hand-edited

`CLAUDE.md` is what Claude Code actually reads at session start. But it's also what
**users want to author and maintain**. Two competing pressures:

- Author-friendly: short, organized by topic, easy to edit.
- Tool-friendly: a single file at the project root with a fixed name.

The v0.2 answer: author multiple short fragments in `.harness/rules/NN-topic.md`,
and let `harness-sync` compose them into `CLAUDE.md`. Best of both: human edits the
fragments; tool sees the assembled file.

The filename prefix (`00-` < `99-`) determines composition order. Convention:

- `00-19`: core / always-applicable
- `20-49`: cross-cutting topics (security, perf, testing)
- `50-79`: project-type overlays (fullstack-specific, backend-specific)
- `80-99`: project-specific custom rules

## Why is verify_all a single entry point?

If checks are scattered (`npm run lint`, `npm test`, `npm run schema-check`, ...),
agents will run some and skip others. A single command `scripts/verify_all` removes
that choice. Done = this command exited 0.

## Why does verify_all check binding consistency?

`harness-sync` is the bridge between Layer 2 (your content) and Layer 1 (generated
binding). If a user edits `.harness/` but forgets to sync, Claude Code sees stale
content in `.claude/` and behaves wrong. Adding `harness-sync --check` to `verify_all`
means **a forgotten sync becomes a failed verify**, caught immediately.

## Why baseline only goes up?

If the test count can go down, an AI can "fix" a failing test by deleting it.
Baseline-only-up makes that visible immediately. Test count drop = automatic FAIL.

## Why dev-map and task board?

AI doesn't know your codebase the way a human developer does. Two pieces of context
bridge that gap:

- **dev-map** answers "where does X live, what's the convention here?" — read **before** writing code.
- **task board** answers "is this related to something we already did?" — read **before** designing.

Without them, AI reinvents wheels (dev-map missing) or contradicts past decisions (task board missing).

## Why golden tasks instead of full Eval pipeline?

For team/production scale, you need a real Eval Pipeline (component / trajectory /
completion / e2e), in CI, with judges and metrics. For personal projects that's
massively over-engineered.

The minimum viable version: 2-5 small representative tasks in `evals/golden-tasks.md`.
After any change to `.harness/` or `templates/`, re-run them via `scripts/test-init.{ps1,sh}`
for init regression, or by manually invoking PM on a representative task.

## What's deliberately not in this design

| Missing | Why omitted |
|---|---|
| Vault / credential proxy | Personal projects use env vars + permission denylists. |
| Token budget tiers (green/yellow/red/melt) | Claude Code's auto-compaction + per-agent model assignment is enough. |
| OpenTelemetry / production trace system | Session transcript + verification_history.log suffices. |
| Multi-platform binding (Cursor / Copilot) | The `.harness/` layer makes future bindings straightforward, but only Claude Code ships today. |
| Multi-brain / multi-sandbox parallelism | Not supported by current platform primitives at MVP scope. |

These can be added later if scale demands. **Avoid premature scaffolding.**

## The evolution principle (most important)

> AI makes a mistake → don't retry, fix the rail.

Every mistake is a hint about a missing guardrail. The five categories:

| Mistake | Fix at level |
|---|---|
| Wrong style / pattern | Rule (`.harness/rules/`) + Script (verify_all) |
| Forgot a step | Skill (`.harness/skills/`) |
| Roles confused | Agent definition (`.harness/agents/`) |
| Couldn't reach external capability | MCP server |
| Whole stage missing | New agent + workflow update |

Over time, your `verify_all` grows fatter and your need to manually correct shrinks.
That's the system getting smarter — not the model.
