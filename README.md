# Harness Kit

**English** · [简体中文](README.zh-CN.md)

![version](https://img.shields.io/badge/version-0.14.0-blue) ![verify_all](https://img.shields.io/badge/verify__all-26%2F26-brightgreen) ![test-init](https://img.shields.io/badge/test--init-162%2F162-brightgreen) ![integration](https://img.shields.io/badge/integration-82%2F82-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Harness Engineering toolkit for Claude Code** — a Claude Code Plugin (9 skills + project templates) that brings disciplined AI-driven development to fullstack and backend projects.
>
> **Goal**: humans only do "describe the requirement" and "step in when AI can't"; everything else — 7-agent pipeline, verify gates, structured documents — runs automatically.

## What's inside

This is a Claude Code Plugin packaging that gives any project nine AI skills:

**Pipeline skills** (four task shapes; the AI picks the right one from your natural-language description)
- `/harness-kit:harness` — full 7-stage pipeline (RA → SA → GR → Dev → CR → QA → Delivery). Use for real feature / bug / refactor work.
- `/harness-kit:harness-plan` — design-only mode: runs RA + SA + GR, stops with a verdict before any code is written. Use to vet a design.
- `/harness-kit:harness-explore` — research / feasibility mode: light RA + a `findings.md` with citations. No design, no code. Use for "can we even do X?"
- `/harness-kit:harness-goal` — open-ended Dev + QA loop bounded by a measurable success criterion and a budget. Use for "keep improving until coverage > 80%" type tasks.

**Setup skills**
- `/harness-kit:harness-init` — bootstrap Harness skeleton in a new project (asks 5 questions, generates `.harness/` + `.claude/` + `AI-GUIDE.md` + stub CLAUDE.md / copilot-instructions.md in ~30s)
- `/harness-kit:harness-adopt` — non-invasively add Harness to an existing project (detects stack, extracts conventions, prompts before applying)

**Operations skills**
- `/harness-kit:harness-verify` — run total verification (compile + test + rule scan + baseline diff)
- `/harness-kit:harness-status` — health snapshot (which assets present, baseline, last verify, active tasks)
- `/harness-kit:harness-intervene` — soft Ctrl-C for an in-flight pipeline: drop a `STOP` / `REDIRECT` / `SKIP` / `NOTE` signal that the PM consumes at the next stage boundary

After init, every non-trivial task flows through a **7-agent pipeline**: PM Orchestrator → Requirement Analyst → Solution Architect → Gate Reviewer → Developer (or partition `dev-*`) → Code Reviewer → QA Tester → Delivery.

## Who this is for

- Any project that benefits from disciplined AI-driven development. **First-class presets** exist for **fullstack** (frontend + backend + DB) and **backend** (API service). Other stacks (CLI, library, mobile, ML pipeline, embedded, WPF/Unity/desktop, pure frontend) use the **Other / Generic** path — `.harness/` skeleton ships out of the box; the PM and AI tailor rules / partition agents / `verify_all` to your project on first use.
- Uses **Claude Code** as the primary AI dev tool (GitHub Copilot supported as fallback / co-existence).
- Wants AI to handle the disciplined parts (requirements, design, code, review, test, docs) while you focus on direction.

## Install

### Option 1 — Claude Code Plugin Marketplace (recommended)

Inside any Claude Code session:

```
/plugin marketplace add Alan-IFT/harness-kit
/plugin install harness-kit@harness-kit-marketplace
```

Official, versioned, auditable. Skills appear namespaced as `/harness-kit:harness-init`, etc.

### Option 2 — One-line curl / PowerShell

For users not on Plugin system, or for global skills install:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.sh | sh
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.ps1 | iex
```

Self-contained: the script clones the repo into a temp dir and copies skills into `~/.claude/skills/`. Skills then callable as `/harness-init`, etc. (no namespace).

### Option 3 — Local clone (dev mode)

```bash
git clone https://github.com/Alan-IFT/harness-kit ~/harness-kit
~/harness-kit/install.sh                  # or install.ps1
~/harness-kit/install.sh --project .      # project-local install
~/harness-kit/install.sh --dry-run        # preview only
~/harness-kit/install.sh --uninstall      # remove
```

## Quick start

```bash
mkdir my-app && cd my-app
claude
```

In Claude Code:

```
/harness-kit:harness-init
```

Five questions (`AskUserQuestion` popup):
1. Project type — Fullstack / Backend / Generic (CLI, library, mobile, ML, embedded, etc.) — three first-class overlays
2. Stack — free text (e.g. "Next.js + NestJS + Postgres", "Rust CLI tool", "PyTorch training pipeline")
3. Enable `verify_all` Stop hook — Yes / No
4. Developer partitioning — Partitioned (default) / Single (skipped for Generic — defaults to single, AI suggests partitions later if project grows)
5. Project output language — English (default) / 中文

In ~30 seconds your project has:
- `.harness/` (tool-agnostic source of truth: agents, rules, skills)
- `.claude/` (generated Claude Code binding)
- `.github/copilot-instructions.md` (generated Copilot binding)
- `CLAUDE.md` (generated, the rules Claude Code reads)
- `docs/` (workflow, dev-map, tasks, spec)
- `scripts/` (verify_all, harness-sync, baseline)
- `evals/` (golden regression tasks)

Now describe a task:

```
Take this task: Add a CSV export button to the orders page.
```

PM Orchestrator picks it up, routes through 7 stages, produces 6 stage documents under `docs/features/<slug>/`, writes code, runs verify_all, hands you a finished feature.

## Key features

### Tool-agnostic source of truth (v0.10 — progressive disclosure)

```
.harness/rules/*.md     ← edit this (single source of truth, modular fragments)
       ↑
       │  referenced by
       │
AI-GUIDE.md             ← tool-agnostic entry (~50-line index with "when to read" descriptions)
       ↑
       │  pointed at by
       │
CLAUDE.md                            (~15-line bootstrap stub; Claude Code reads)
.github/copilot-instructions.md      (~15-line bootstrap stub; Copilot reads)
```

You edit one place: `.harness/rules/`. The stubs and AI-GUIDE.md reference it; no regeneration needed. AI tools follow the references and **lazy-load only the fragments they need** — same pattern as Claude Code's own skill system.

**Context budget**: persistent always-loaded ruleset drops from ~3500 tokens (v0.9.x full CLAUDE.md) to ~250 tokens (v0.10 stub). On small interactions (~92% saving), AI doesn't even read `AI-GUIDE.md`. On bigger tasks, it reads `AI-GUIDE.md` once + the 1-3 fragments whose "when to read" matches — typically ~50% saving vs v0.9.x.

`harness-sync` still exists but only copies `.harness/agents/` and `.harness/skills/` to `.claude/` (Claude Code requires those paths). Rules don't sync. The git pre-commit hook (from `scripts/install-hooks`) keeps `.claude/` in lockstep with `.harness/` for users on Copilot, Cursor, or hand-edits — tool-agnostic.

### Project-wide language policy

A Chinese team picks `中文` at init — every AI output across the project is in Chinese: chat replies, agent hand-offs, per-task documents, status reports, error messages. Even if you write in another language, AI responds in Chinese. The policy is enforced via a top-level `Output language` section in CLAUDE.md.

English projects work the same way: nothing leaks in another language.

### Developer partitioning

Fullstack: `dev-frontend` / `dev-backend` / `dev-db` agents, each with owned-paths glob. The Solution Architect produces a partition assignment table; PM dispatches in dependency order (db → backend → frontend by default). Out-of-partition changes raise `BLOCKED ON PARTITION` and PM routes properly.

Backend: same idea, three layers — `dev-api` / `dev-services` / `dev-db`.

Single developer mode available for small projects.

### Cross-tool handoff (Claude Code ↔ Copilot)

Hit Claude Code's rate limit mid-task? Switch to GitHub Copilot in VS Code and keep going. Switch back when quota refreshes. All task state lives in files (`docs/tasks.md`, `docs/features/<task>/`, `PM_LOG.md`), not in chat memory — so resume is just reading those files. Both tools' bindings include `.harness/rules/60-tool-handoff.md` which defines the resume protocol.

### Three layers of regression testing

- `verify_all` (26 checks) — repo health
- `test-init` (162 assertions) — init template logic on empty dirs
- `test-real-project` (82 assertions) — overlay onto real fixtures (todo-fullstack, todo-backend)

Every commit must pass all three. `test-init` and `test-real-project` exercise the generated project's structure end-to-end with no network needed.

### Dogfooded

This repo is itself developed under Harness Kit. The same 7-agent pipeline that ships to users governs work here. The same `.harness/rules/` source produces this repo's `CLAUDE.md` and `.github/copilot-instructions.md`. If we can't develop this repo with it, we shouldn't ship it.

## Repository layout

```
harness-kit/
├── skills/                       Claude Code Skills (the product)
│   ├── harness-init/             Bootstrap skill + templates
│   │   └── templates/
│   │       ├── common/           Shared assets (7 agents, base rules, docs, evals)
│   │       ├── fullstack/        Fullstack overlay (partition agents, overlay rules)
│   │       ├── backend/          Backend overlay
│   │       └── i18n/zh/          Chinese translation overlay
│   ├── harness-adopt/
│   ├── harness-verify/
│   └── harness-status/
│
├── .claude-plugin/               Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
│
├── .harness/                     This repo's SOT (dogfood)
│   ├── agents/                   Byte-copy of templates/common/.harness/agents/
│   └── rules/                    Project-specific rule fragments
├── .claude/                      Generated; do not edit
├── CLAUDE.md                     Generated; do not edit
├── .github/copilot-instructions.md  Generated; do not edit
│
├── scripts/
│   ├── verify_all.{ps1,sh}       Total verification
│   ├── harness-sync.{ps1,sh}     .harness/ → CLAUDE.md + .github/copilot-instructions.md
│   ├── sync-self.{ps1,sh}        templates/common/ → repo SOT
│   ├── test-init.{ps1,sh}        Init regression
│   └── test-real-project.{ps1,sh}  Integration regression
│
├── tests/fixtures/               Minimal real-shape projects for integration
│
├── docs/
│   ├── getting-started.md
│   ├── concepts.md
│   ├── workflow.md
│   ├── dev-map.md
│   ├── walkthrough.html          Visual walkthrough
│   └── manual-e2e-test.md
│
├── architecture.html             Visual architecture overview
├── install.ps1 / install.sh      One-line installers
├── README.md (this file)
├── README.zh-CN.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── MIGRATION.md                  v0.1.x → v0.5+ upgrade
└── LICENSE                       MIT
```

## Documentation

Open these in a browser for the best experience:

- **[architecture.html](architecture.html)** — visualized architecture, design decisions, evolution history
- **[docs/walkthrough.html](docs/walkthrough.html)** — full user flow walked through with a real todo-list example, every stage shown

Markdown docs:

- [docs/getting-started.md](docs/getting-started.md) — quick onboarding
- [docs/concepts.md](docs/concepts.md) — why each piece exists
- [docs/workflow.md](docs/workflow.md) — full 7-agent pipeline
- [docs/manual-e2e-test.md](docs/manual-e2e-test.md) — manual end-to-end test checklist
- [CONTRIBUTING.md](CONTRIBUTING.md) — development workflow for contributors
- [MIGRATION.md](MIGRATION.md) — upgrade path for older harness-engineering projects

## Roadmap

| Version | Status | Highlights |
|---|---|---|
| 0.1.0 | done | MVP: 4 skills, 7 agents, dogfood |
| 0.2.0 | done | Tool-agnostic `.harness/` SOT layer |
| 0.3.0 | done | `/harness-adopt` automated apply |
| 0.4.x | done | Fullstack Developer partitioning |
| 0.5.0 | done | Backend Developer partitioning |
| 0.6.x | done | Project renamed to harness-kit; plugin marketplace packaging |
| 0.7.x | done | i18n (en/zh) + project-wide output-language policy; Copilot rules binding |
| 0.8.x | done | Cross-tool handoff protocol; visible generated-file warnings |
| 0.9.x | done | Auto-sync via Stop hook + OS-aware `{{SYNC_COMMAND}}` + tool-agnostic git pre-commit hook; "Other / Generic" project type |
| 0.10.0 | done | **Progressive-disclosure layout**: `AI-GUIDE.md` entry + stub CLAUDE.md / copilot-instructions.md; rules no longer composed (~50% context-budget reduction) |
| 0.11.x | done | **Three execution modes** + **adversarial verification** + **cross-task insight index** (from lsdefine/GenericAgent borrows) + symmetric `/harness` skill + AI-GUIDE.md ↔ rules drift check |
| 0.12.0 | done | **Generic project type** is now a first-class overlay (parallel to fullstack/backend) — closes the Other-Generic gap. New `templates/generic/` with `50-generic.md` rule stub + minimal `verify_all` skeleton. Test-init now exercises 3 project types (+33 assertions). |
| 0.13.0 | done | **Mid-task intervention protocol** (`/harness-kit:harness-intervene`): single-shot `.harness/intervention.md` signal file (STOP / REDIRECT / SKIP / NOTE) that PM consumes at every stage boundary. First user-facing addition since v0.12. |
| 0.14.0 | done | **Document size policy**: numeric caps for 8 document classes (rules / agents / per-task docs / insight-index / tasks.md) + WARN-level size checks in `verify_all` (I.1-I.5 here, F.1-F.6 in user-project templates). "Reference, don't paste" + always-archive-task discipline. |
| 0.15+ | planned | True **AI-native init** (AI analyzes user description + existing code, generates custom 50-*.md and partition agents); supervisor agent observing pipeline progress |

## Design principles

1. **Don't reinvent platform mechanisms** — Sandbox, Hooks, Sub-agents, MCP, Memory are Claude Code's job
2. **Mechanism vs content** — platform gives mechanism, this repo gives content
3. **Tool-agnostic SOT vs binding layer** — `.harness/` is truth; `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` are generated
4. **Evolutionary delivery** — MVP → Hardening → Scale, not big-bang
5. **Baseline only goes up** — test counts, rule coverage never regress silently
6. **Finder doesn't fix** — Reviewer can't edit code, Gate can't edit requirements
7. **Downstream can't edit upstream** — only propose rollback via PM
8. **PM only routes** — never makes professional judgments

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs and issues welcome.

## License

[MIT](LICENSE)
