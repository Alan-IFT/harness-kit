# Harness Kit

**English** · [简体中文](README.zh-CN.md)

![version](https://img.shields.io/badge/version-0.19.0-blue) ![verify_all](https://img.shields.io/badge/verify__all-31%2F31-brightgreen) ![test-init](https://img.shields.io/badge/test--init-227%2F227-brightgreen) ![integration](https://img.shields.io/badge/integration-82%2F82-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Harness Engineering toolkit for Claude Code** — a Claude Code Plugin (11 skills + project templates) that brings disciplined AI-driven development to fullstack and backend projects.
>
> **Goal**: humans only do "describe the requirement" and "step in when AI can't"; everything else — 7-agent pipeline, verify gates, structured documents — runs automatically.

## What's inside

This is a Claude Code Plugin packaging that gives any project eleven AI skills:

**Pipeline skills** (five task shapes; the AI picks the right one from your natural-language description)
- `/harness-kit:harness` — full 7-stage pipeline (RA → SA → GR → Dev → CR → QA → Delivery). Use for real feature / bug / refactor work.
- `/harness-kit:harness-plan` — design-only mode: runs RA + SA + GR, stops with a verdict before any code is written. Use to vet a design.
- `/harness-kit:harness-explore` — research / feasibility mode: light RA + a `findings.md` with citations. No design, no code. Use for "can we even do X?"
- `/harness-kit:harness-goal` — open-ended Dev + QA loop bounded by a measurable success criterion and a budget. Use for "keep improving until coverage > 80%" type tasks.
- `/harness-kit:harness-batch` — runs `T-01…T-NN` sequentially through pm-orchestrator, each task in its own sub-agent context. Stops on strong signals (`verify_all` FAIL, pm-orchestrator FAIL, intervention STOP, safety hook block). Use for `/harness-plan` decompositions, accumulated backlogs, post-checkup sweeps, or imported task lists — instead of invoking `/harness` N times.

**Setup skills**
- `/harness-kit:harness-init` — bootstrap Harness skeleton in a new project (asks 5 questions, generates `.harness/` + `.claude/` + `AI-GUIDE.md` + stub CLAUDE.md / copilot-instructions.md in ~30s)
- `/harness-kit:harness-adopt` — non-invasively add Harness to an existing project (detects stack, extracts conventions, prompts before applying)

**Operations skills**
- `/harness-kit:harness-verify` — run total verification (compile + test + rule scan + baseline diff)
- `/harness-kit:harness-status` — health snapshot (which assets present, baseline, last verify, active tasks)
- `/harness-kit:harness-intervene` — soft Ctrl-C for an in-flight pipeline: drop a `STOP` / `REDIRECT` / `SKIP` / `NOTE` signal that the PM consumes at the next stage boundary
- `/harness-kit:harness-supervise` — observer-only auxiliary skill (v0.17+): reads an in-flight or archived task folder and emits a `SUPERVISION_REPORT.md` flagging anti-patterns (rollback rate, stage-doc thinness, missing intervention checks, missing archive call) with `INFO`/`WARN`/`ALERT` severity and a final `HEALTHY`/`WATCH`/`INTERVENE` verdict

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
- `.claude/` (Claude Code binding: `agents/` + `skills/` synced from `.harness/`, plus `settings.json`)
- `.github/copilot-instructions.md` (Copilot bootstrap stub)
- `CLAUDE.md` (bootstrap stub Claude Code reads — points at `AI-GUIDE.md`)
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

- `verify_all` (31 checks) — repo health
- `test-init` (227 assertions on PowerShell; 191 on Bash without python3) — init template logic on empty dirs (3 project types × 75 PS / 63 Bash, plus 2 shell-agnostic BUG-2 placeholder-regex regression assertions)
- `test-real-project` (82 assertions) — overlay onto real fixtures (todo-fullstack, todo-backend)

Every commit must pass all three. `test-init` and `test-real-project` exercise the generated project's structure end-to-end with no network needed.

### Dogfooded

This repo is itself developed under Harness Kit. The same 7-agent pipeline that ships to users governs work here, off the same `.harness/` source of truth (agents / rules / skills) that init writes into a new project. If we can't develop this repo with it, we shouldn't ship it.

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
├── .claude/                      Claude Code binding (agents/ + skills/ synced from .harness/)
├── CLAUDE.md                     ~15-line stub pointing at AI-GUIDE.md (written once at init)
├── .github/copilot-instructions.md  ~15-line stub pointing at AI-GUIDE.md
│
├── scripts/
│   ├── verify_all.{ps1,sh}       Total verification
│   ├── harness-sync.{ps1,sh}     .harness/agents + .harness/skills → .claude/ (CLAUDE.md is a static stub since v0.10)
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
| 0.15.0 | done | **AI safety guardrails**: cross-platform `guard-rm.{ps1,sh}` PreToolUse hook blocks destructive commands (`rm` / `Remove-Item` / `find -delete` / nested `pwsh -c`) targeting paths outside the project root; per-call override via `HARNESS_ALLOW_OUTSIDE_RM=1`. New `.harness/rules/75-safety-hook.md`. Plus D1+D2 docs: AI tool flow modes (Claude Code auto-dispatch / Copilot manual / Copilot opt-in "continuous mode" with HARD STOP after Gate Review) and an explicit Claude-Code-sub-agent-dispatch callout. verify_all 26 → 27 (new F.2). |
| 0.15.1 | done | **Documentation-drift cleanup + I.6 retired-claim guard**: closes the v0.10 composition-retirement drift class across 14 files (docs / templates / dogfood rules / Chinese overlay), and adds a literal-substring banned-phrase guard in `verify_all` (FAIL if any retired claim resurfaces). verify_all 27 → 28 (new I.6). |
| 0.16.0 | done | **AI-native init / adopt**: opt-in `/harness-init` Q6 and `/harness-adopt` Q6 ask whether to let AI draft a tailored `.harness/rules/50-<project-slug>.md` (and optional `dev-*` partition agents) grounded in the user's Q2 stack string plus top-level filenames + named manifest contents. Static-stub fallback if the four invariants fail (sections, no `{{...}}`, ≤200 lines, no reserved partition names). Inline source citations (`<!-- source: ... -->`). Mock fixture for test/dry-run via `HARNESS_AI_NATIVE_MOCK`. verify_all 28 → 29 (new D.3 per-section sanity check). |
| 0.17.0 | done | **Supervisor agent + `/harness-supervise` skill**: observer-only auxiliary agent reads an in-flight or archived 7-stage task folder, detects 4 anti-patterns (AP-1 same-stage rollback rate, AP-1b cross-stage rollback tally, AP-2 stage-doc thinness, AP-3 missing intervention checks, AP-4 missing archive call) with fixed thresholds, classifies findings INFO/WARN/ALERT, emits one `SUPERVISION_REPORT.md` per invocation with a final `Verdict: HEALTHY | WATCH | INTERVENE`. Manual-invocation only (not part of the canonical 7-stage routing); `allowed-tools` whitelist physically excludes `Edit`/`Bash`/`PowerShell`/`Task`/`AskUserQuestion`. New `verify_all I.7` passive guard WARNs when an `INTERVENE` report has been ignored >48h on an active task. verify_all 29 → 30. |
| 0.17.1 | done | **Patch sweep**: BUG-2 (I.7 active-row slug match column-anchored on both shells — no more `foo` / `foo-extra` substring collision) + BUG-3 (`supervisor.md` boundary-table doc-drift on cross-task N=0 reconciled with `harness-supervise` SKILL.md). No feature change; `verify_all` stays 30 checks. |
| 0.17.2 | done | **`settings.json` schema fix**: the Claude Code settings schema declares the `hooks` object `additionalProperties: false` — only real hook-event names are valid keys. harness-kit embedded `_doc_sync_hook` / `_guard_hook` documentation strings *inside* `hooks`, so every generated `.claude/settings.json` failed schema validation. Both keys moved to the root object (`additionalProperties: true`, where `_*` doc keys are valid). No functional change; `verify_all` stays 30 checks. |
| 0.17.3 | done | **Bootstrap red-line wording fix**: the `CLAUDE.md` / `copilot-instructions.md` red line mislabeled `.claude/` as a "generated or static" file. `.claude/settings.json` is neither — it is the agent's live, hand-maintained startup config. The bullet was split: one for `.claude/` (live config + sync-generated `agents/`/`skills/`, with the correct rationale), one for the genuine static stubs. Fixed in 4 templates + 2 dogfood files. No feature change; `verify_all` stays 30 checks. |
| 0.17.4 | done | **v0.10 doc-drift cleanup**: swept the residual pre-v0.10 wording out of live docs/comments — `harness-sync` no longer described as regenerating `CLAUDE.md` / `copilot-instructions.md`, and `CLAUDE.md` is no longer mislabeled "generated". Touched the `00-core.md` rule templates (EN + ZH), `settings.json` templates, `dev-frontend` template, README layout boxes, getting-started, CONTRIBUTING, the two init/adopt skills, and reconciled the `verify_all` I.6 exemption comments. No feature change; `verify_all` stays 30 checks. |
| 0.18.0 | done | **I.6 gap-tolerant retired-claim guard**: the `verify_all` I.6 phrase guard upgrades from literal-substring matching to a gap-tolerant ordered-anchor scan — each banned entry is a list of plain-text anchors that must appear in order on one line within a bounded gap, with optional line-scoped `exclude` tokens so accurate negated prose does not FAIL. I.6 exempt-dir widened to the whole `docs/features/` subtree. New `scripts/test-verify-i6.{ps1,sh}` regression pair. No new check; `verify_all` stays 30. |
| 0.18.1 | done | **`test-verify-i6` hardening**: structural-lockstep upgraded to a full 2×2 (`test-verify-i6.{ps1,sh}` × `verify_all.{ps1,sh}`) verbatim per-entry × 4-field (anchors / reason / exclude / gap) comparison — closes the v0.18.0 leftover where the PS-side only checked entry count + entry #10's `.claude/` exclude. New file-exempt predicate symmetric to the existing dir-exempt one, plus element-wise lockstep on the I.6 exempt-file (`CHANGELOG.md`, `architecture.html`, …) and exempt-dir lists. AC-8 (`CHANGELOG.md` / `_archived/` exemption) now has a permanent corpus fixture instead of the v0.18.0 inline-injection probe. Assertion counts: 35→56 (PS), 34→56 (bash); `verify_all` stays 30. |
| 0.18.2 | done | **`settings.json` schema-validation guard (J.1)**: the `$schema` URL in the dogfood + template `.claude/settings.json` was missing the `.json` suffix, so the 301-redirect target served `application/octet-stream` and many editors silently rejected the schema — file flagged invalid even though JSON parsed. Canonical URL restored. New `verify_all` J.1 check parses both files (repo + `.tmpl`), enforces the canonical `$schema`, and rejects any key inside `hooks` that is not in the upstream event enum — catches both v0.17.2 (wrong key placement) and v0.18.2 (wrong URL form) classes at the gate. New rule fragment `.harness/rules/80-settings-schema.md` documents the "consult upstream schema via context7 before editing" workflow. `verify_all` 30 → 31 checks. |
| 0.19.0 | done | **Batch mode**: new `/harness-kit:harness-batch <batch-id>` skill runs a list of tasks (`T-01…T-NN` in `docs/batches/<batch-id>/BATCH_PLAN.md`) sequentially through `pm-orchestrator`, dispatched via the `Task` tool so each task gets its own sub-agent context and the batch orchestrator never accumulates more than per-task summaries. Strong-signal-only stop policy (`verify_all` FAIL, pm-orchestrator FAIL, 3 same-stage rollbacks, `intervention.md` STOP, safety hook block). Resumable: re-invoking with the same batch-id skips tasks whose `07_DELIVERY.md` is `DELIVERED`. New `docs/batches/` directory with lifecycle README and `_template/BATCH_PLAN.md`. `verify_all` skill count 10 → 11 (C.1 / G.1 / G.2 in both shells). |
| 0.20+ | planned | Supervisor auto-dispatch by PM at user-configurable stage boundaries (once false-positive budget is proven against ≥10 real tasks); parallel batch dispatch once sequential batch stability is proven. |

## Design principles

1. **Don't reinvent platform mechanisms** — Sandbox, Hooks, Sub-agents, MCP, Memory are Claude Code's job
2. **Mechanism vs content** — platform gives mechanism, this repo gives content
3. **Tool-agnostic SOT vs binding layer** — `.harness/` is truth; `.claude/agents/` + `.claude/skills/` are synced bindings; `CLAUDE.md` + `.github/copilot-instructions.md` are static bootstrap stubs
4. **Evolutionary delivery** — MVP → Hardening → Scale, not big-bang
5. **Baseline only goes up** — test counts, rule coverage never regress silently
6. **Finder doesn't fix** — Reviewer can't edit code, Gate can't edit requirements
7. **Downstream can't edit upstream** — only propose rollback via PM
8. **PM only routes** — never makes professional judgments

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs and issues welcome.

## License

[MIT](LICENSE)
