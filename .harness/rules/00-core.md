# Harness Engineering — Project Rules (self-dogfood)

> This repo **uses its own Harness setup**. The same 7-agent pipeline that we ship to users
> governs work on this repo. If we can't develop this repo with it, we shouldn't ship it.

## Project type

**Tooling / Skills library** — not fullstack, not backend. It distributes Claude Code skills
and project templates. Build / test characteristics:

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
