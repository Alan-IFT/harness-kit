# Core Concepts

This document explains **why** each Harness component exists, not just what it does.
For the "what", see [getting-started.md](getting-started.md).

## The big picture

```
Layer 1: Project assets (this repo provides templates)
  - SPEC / CLAUDE.md / 7 agents / workflow / verify_all / dev-map / tasks / evals
       ↓ runs on
Layer 0: Claude Code platform (already shipped, we don't rebuild)
  - Permission mode / sub-agents / Hooks / MCP / Memory / Skills / auto-compaction
```

**Layer 0 = mechanism. Layer 1 = content.** Claude Code gives you the engine; this repo gives you the rails.

## Why 7 agents and not 1?

A single Agent doing requirements + design + code + tests has structural problems:

| Single Agent symptom | Why it happens |
|---|---|
| Self-confirmation | The author of a design naturally defends it during review. |
| Context overload | One context window holding all stages dilutes attention. |
| No quality gate | A design defect rolls into code with no checkpoint. |
| No audit trail | Decisions are scattered through a single chat log. |

Splitting into 7 agents enforces **role separation** like a real team. Each role's job is narrow; each role's output is a document; transitions are governed.

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

If the PM gives technical opinions, the system regresses to "one big Agent". The PM is a router; specialist agents are specialists. This sounds bureaucratic but it's what makes the system maintainable: you can swap one agent without re-deciding everything.

## Why can't the downstream edit upstream?

If the Reviewer can fix the code, it's also auditing its own fix → quality regression. If the Gate can edit the requirement, the analyst's accountability evaporates. The fix is to route back via PM — the cost of one rollback is tiny compared to lost accountability.

## Why are Rule / Skill / Script three layers?

| Layer | What it is | Why separated |
|---|---|---|
| Rule (CLAUDE.md) | Soft constraints, natural language | AI reads it but may forget under long context. Good for principles. |
| Skill (.claude/skills) | Standard operating procedure | Codifies repeated actions so AI doesn't improvise. |
| Script (scripts/verify_all) | Hard gate | Machine-checkable. AI cannot "interpret it away". |

The progression is: write a rule, see if AI follows it; if not, encode it as a check.

## Why is verify_all a single entry point?

If checks are scattered (`npm run lint`, `npm test`, `npm run schema-check`, ...), agents will run some and skip others. A single command `scripts/verify_all` removes that choice. Done = this command exited 0.

## Why baseline only goes up?

If the test count can go down, an AI can "fix" a failing test by deleting it. Baseline-only-up makes that visible immediately. Test count drop = automatic FAIL.

## Why dev-map and task board?

AI doesn't know your codebase the way a human developer does. Two pieces of context bridge that gap:

- **dev-map** answers "where does X live, what's the convention here?" — read **before** writing code.
- **task board** answers "is this related to something we already did?" — read **before** designing.

Without them, AI reinvents wheels (dev-map missing) or contradicts past decisions (task board missing).

## Why golden tasks instead of full Eval pipeline?

For team/production scale, you need a real Eval Pipeline (component / trajectory / completion / e2e), in CI, with judges and metrics. For personal projects that's massively over-engineered.

The minimum viable version: 2-5 small representative tasks in `evals/golden-tasks.md`. After any change to `CLAUDE.md` / agents / workflow, re-run them. If they all still flow correctly → good enough.

## What's deliberately not in this design

| Missing | Why omitted |
|---|---|
| Vault / credential proxy | Personal projects use env vars + permission denylists. |
| Token budget tiers (green/yellow/red/melt) | Claude Code's auto-compaction + per-agent model assignment is enough. |
| OpenTelemetry / production trace system | Session transcript + verification_history.log suffices. |
| Multi-platform sync (Cursor / Copilot) | Single platform: Claude Code. |
| Multi-brain / multi-sandbox parallelism | Not supported by current platform primitives at MVP scope. |

These can be added later if scale demands. **Avoid premature scaffolding.**

## The evolution principle (most important)

> AI makes a mistake → don't retry, fix the rail.

Every mistake is a hint about a missing guardrail. The five categories:

| Mistake | Fix at level |
|---|---|
| Wrong style / pattern | Rule (CLAUDE.md) + Script (verify_all) |
| Forgot a step | Skill (.claude/skills) |
| Roles confused | Agent definition (.claude/agents) |
| Couldn't reach external capability | MCP server |
| Whole stage missing | New agent + workflow update |

Over time, your `verify_all` grows fatter and your need to manually correct shrinks. That's the system getting smarter — not the model.
