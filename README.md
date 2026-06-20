# Harness Kit

**English** · [简体中文](README.zh-CN.md)

![version](https://img.shields.io/badge/version-0.43.0-blue) ![verify_all](https://img.shields.io/badge/verify__all-32%2F32-brightgreen) ![test-init](https://img.shields.io/badge/test--init-314%2F314-brightgreen) ![integration](https://img.shields.io/badge/integration-90%2F90-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Harness Engineering toolkit for Claude Code** — a Claude Code Plugin (17 skills + 8 framework agents + project templates) that brings disciplined AI-driven development to fullstack and backend projects. **Claude-native** (the framework agents ship as plugin agents — no per-project copy).
>
> **Goal**: humans only do "describe the requirement" and "step in when AI can't"; everything else — 7-agent pipeline, verify gates, structured documents — runs automatically.

_**v0.34–0.40 adoption wave**: absorbed the transferable strengths of [mattpocock/skills](https://github.com/mattpocock/skills) — domain glossary, requirement grilling, durable briefs, two-axis review, rejected-decisions memory, and more. The only new command is the **optional** `/harness-grill`; every other gain is internal to the existing agents/rules — same workflow, nothing new to learn._

## What's inside

This is a Claude Code Plugin packaging that gives any project seventeen AI skills:

**Pipeline skills** (six task shapes the AI picks from your natural-language description, plus a pre-pipeline aligner)
- `/harness-kit:harness-grill` — runs **before** the pipeline to align the requirement: a relentless one-question-at-a-time interview (a recommended answer per question, self-answers from the codebase where it can, reads `CONTEXT.md` if present) that emits an aligned brief to `docs/features/<slug>/INPUT.md` and stops. Use when you're not sure you've said what you actually want yet — then hand the brief to `/harness` or a `/harness-stream` pool.
- `/harness-kit:harness` — full 7-stage pipeline (RA → SA → GR → Dev → CR → QA → Delivery). Use for real feature / bug / refactor work.
- `/harness-kit:harness-plan` — design-only mode: runs RA + SA + GR, stops with a verdict before any code is written. Use to vet a design.
- `/harness-kit:harness-explore` — research / feasibility mode: light RA + a `findings.md` with citations. No design, no code. Use for "can we even do X?"
- `/harness-kit:harness-goal` — open-ended Dev + QA loop bounded by a measurable success criterion and a budget. Use for "keep improving until coverage > 80%" type tasks.
- `/harness-kit:harness-batch` — runs `T-01…T-NN` sequentially through pm-orchestrator, each task in its own sub-agent context. Stops on strong signals (`verify_all` FAIL, pm-orchestrator FAIL, intervention STOP, safety hook block). Use for `/harness-plan` decompositions, accumulated backlogs, post-checkup sweeps, or imported task lists — instead of invoking `/harness` N times.
- `/harness-kit:harness-stream` — like batch, but the task pool stays **alive**: it re-reads `BATCH_PLAN.md` every iteration, so tasks you add mid-run (in chat or by appending to the pool / an `ADD` intervention) get planned and executed without re-invoking. **Best-effort** completion (a failed task is marked and skipped, the stream keeps going) with the same hard-safety stops as batch. A task that needs human input (clarification, a human-reserved decision, or authorization for a safety-critical action) is **deferred** (a distinct `needs-human` status — set aside, its dependents blocked) and surfaced together at stream end in `STREAM_REPORT.md`'s `## Needs your input` section, so the stream never sits stopped waiting on you. Use when you want to fire requirements as they occur to you and only watch results. Complex multi-part requirements are auto-decomposed at ingest into dependency-staged sub-task rows (simple ones stay one row; rows you author — `ADD` / hand-written — run as-written). **Ambient mode:** just invoke with **no pool-id** — a default pool (`docs/batches/default/`) is auto-created and a `UserPromptSubmit` hook (gated by `.harness/ambient.flag`) makes every chat message a heartbeat that folds requirements into the pool and drains it; no `/loop`, no re-invocation, no keyword. It is session-scoped — a `SessionStart` hook auto-clears the flag each new session, so re-invoke `/harness-stream` to resume.

**Setup skills**
- `/harness-kit:harness-init` — bootstrap Harness skeleton in a new project (asks 6 questions, generates `.harness/` + `.claude/` + `AI-GUIDE.md` + stub CLAUDE.md / copilot-instructions.md in ~30s)
- `/harness-kit:harness-adopt` — non-invasively add Harness to an existing project (detects stack, extracts conventions, prompts before applying)
- `/harness-kit:harness-upgrade` — bring an already-initialized but **stale** project up to the current plugin layout (relocate scripts to `.harness/scripts/`, content-refresh depth-sensitive scripts for correct root derivation, re-install the pre-commit hook, rewire settings, regenerate `verify_all` while preserving your B.* checks — dry-run preview, idempotent, proven with a green `verify_all`)
- `/harness-kit:harness-language` — set, switch (English ↔ Chinese), or refresh a project's output-language policy by surgically rewriting only the three policy surfaces (`.harness/rules/00-core.md` section + `CLAUDE.md` line + `.github/copilot-instructions.md` line) to the target language's current canonical text. Self-bootstraps the text from the plugin templates (so an old project can pull a refreshed policy), non-destructive, idempotent, dry-run preview, `.bak` per file.

**Operations skills**
- `/harness-kit:harness-verify` — run total verification (compile + test + rule scan + baseline diff)
- `/harness-kit:harness-status` — health snapshot (which assets present, baseline, last verify, active tasks)
- `/harness-kit:harness-intervene` — soft Ctrl-C for an in-flight pipeline: drop a `STOP` / `REDIRECT` / `SKIP` / `NOTE` signal that the PM consumes at the next stage boundary
- `/harness-kit:harness-supervise` — observer-only auxiliary skill (v0.17+): reads an in-flight or archived task folder and emits a `SUPERVISION_REPORT.md` flagging anti-patterns (rollback rate, stage-doc thinness, missing intervention checks, missing archive call) with `INFO`/`WARN`/`ALERT` severity and a final `HEALTHY`/`WATCH`/`INTERVENE` verdict
- `/harness-kit:harness-decision-mode` — set or switch a project's decision/escalation **mode**: Mode 1 (human decides, the default), Mode 2 (AI decides per the preset rubric), or Mode 3 (AI decides per your custom rubric). Surgically rewrites only the "Active mode" line of `.harness/rules/25-decision-policy.md`; on a first Mode-3 switch it collects your custom decision prompts. Non-destructive, idempotent, clean-git gated
- `/harness-kit:harness-deflate` — holistic **anti-entropy sweep** (v0.41+): scans the WHOLE codebase (not one task) via the read-only supervisor entropy lens for accumulated structural rot — shallow modules, cross-seam leakage, coupling clusters, deepening candidates — presents each finding with WHERE + a `Strong`/`Worth exploring`/`Speculative` strength badge, and on your **explicit authorization** hands the chosen deepening to `/harness-goal` to refactor it to `verify_all` green. Machine reminds, you authorize, machine executes — it never refactors without authorization. `/harness-stream` also surfaces the same sweep automatically on a due cadence boundary (`## Entropy watch`, non-blocking)

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

Six questions (`AskUserQuestion` popup):
1. Project type — Fullstack / Backend / Generic (CLI, library, mobile, ML, embedded, etc.) — three first-class overlays
2. Stack — free text (e.g. "Next.js + NestJS + Postgres", "Rust CLI tool", "PyTorch training pipeline")
3. Enable `verify_all` Stop hook — Yes / No
4. Developer partitioning — Partitioned (default) / Single (skipped for Generic — defaults to single, AI suggests partitions later if project grows)
5. Project output language — English (default) / 中文
6. AI customization of the `50-<project>.md` rule fragment — opt-in (default: No, static template only)

In ~30 seconds your project has:
- the 7 framework agents (+ supervisor) available as `harness-kit:<name>` from the plugin — **not copied into the project**
- `.harness/` (project source of truth: rules, skills, and any partition `dev-*` agents)
- `.claude/` (Claude Code binding: `agents/` partition `dev-*` + `skills/` synced from `.harness/`, plus `settings.json`)
- `.github/copilot-instructions.md` (Copilot bootstrap stub)
- `CLAUDE.md` (bootstrap stub Claude Code reads — points at `AI-GUIDE.md`)
- `docs/` (workflow, dev-map, tasks, spec)
- `.harness/scripts/` (verify_all, harness-sync, baseline)
- `evals/` (golden regression tasks)

Now describe a task:

```
Take this task: Add a CSV export button to the orders page.
```

PM Orchestrator picks it up, routes through 7 stages, produces 6 stage documents under `docs/features/<slug>/`, writes code, runs verify_all, hands you a finished feature.

## Key features

### Rule source of truth (v0.10 — progressive disclosure)

```
.harness/rules/*.md     ← edit this (single source of truth, modular fragments)
       ↑
       │  referenced by
       │
AI-GUIDE.md             ← Claude-native-by-default entry (~50-line index with "when to read" descriptions)
       ↑
       │  pointed at by
       │
CLAUDE.md                            (~15-line bootstrap stub; Claude Code reads)
.github/copilot-instructions.md      (~15-line bootstrap stub; Copilot reads)
```

You edit one place: `.harness/rules/`. The stubs and AI-GUIDE.md reference it; no regeneration needed. AI tools follow the references and **lazy-load only the fragments they need** — same pattern as Claude Code's own skill system.

**Context budget**: persistent always-loaded ruleset drops from ~3500 tokens (v0.9.x full CLAUDE.md) to ~250 tokens (v0.10 stub). On small interactions (~92% saving), AI doesn't even read `AI-GUIDE.md`. On bigger tasks, it reads `AI-GUIDE.md` once + the 1-3 fragments whose "when to read" matches — typically ~50% saving vs v0.9.x.

Since v0.30 the framework agents are **plugin-provided** (`harness-kit:<name>`) — not copied into your project. `harness-sync` still copies `.harness/agents/` (partition `dev-*` only) and `.harness/skills/` to `.claude/` (Claude Code requires those paths). Rules don't sync. The git pre-commit hook (from `.harness/scripts/install-hooks`) keeps `.claude/` in lockstep with `.harness/` for users on Copilot, Cursor, or hand-edits.

### Project-wide language policy

A Chinese team picks `中文` at init — output is **split by consumer**: human-facing output (chat replies, status reports, error messages, delivery summaries, README and human docs) is in **Chinese**; AI-facing work products (the 7-stage per-task documents, PM_LOG, the tasks.md / dev-map / insight-index ledgers, agent / rule / AI-GUIDE / CLAUDE edits, code comments, commit messages) are in **English** — the LLM reads English fine and it stays consistent with the English framework internals. Even if you write in another language, chat replies stay Chinese. The split is defined in the project's `.harness/rules/00-core.md` "输出语言" section.

English projects have a single language — everything is English, no split.

### Developer partitioning

Fullstack: `dev-frontend` / `dev-backend` / `dev-db` agents, each with owned-paths glob. The Solution Architect produces a partition assignment table; PM dispatches in dependency order (db → backend → frontend by default). Out-of-partition changes raise `BLOCKED ON PARTITION` and PM routes properly.

Backend: same idea, three layers — `dev-api` / `dev-services` / `dev-db`.

Single developer mode available for small projects.

### Cross-tool handoff (Claude Code ↔ Copilot)

Hit Claude Code's rate limit mid-task? Switch to GitHub Copilot in VS Code and keep going. Switch back when quota refreshes. All task state lives in files (`docs/tasks.md`, `docs/features/<task>/`, `PM_LOG.md`), not in chat memory — so resume is just reading those files. Both tools' bindings include `.harness/rules/60-tool-handoff.md` which defines the resume protocol.

### Three layers of regression testing

- `verify_all` (32 checks) — repo health
- `test-init` — init template logic on empty dirs across the 3 project types, plus the migrate-layout block, the zh-overlay consumer-split policy assertions, the v0.30 generic-agents-absent assertions, and the BUG-2 placeholder-regex regression (counts moved at the v0.30 agent cutover; see `.harness/scripts/baseline.json` for the live counts)
- `test-real-project` (90 assertions) — overlay onto real fixtures (todo-fullstack, todo-backend), incl. running the generated type `verify_all` on healthy + dangling-hook states (v0.31)

Every commit must pass all three. `test-init` and `test-real-project` exercise the generated project's structure end-to-end with no network needed.

### Dogfooded

This repo is itself developed under Harness Kit. The same 7-agent pipeline that ships to users (as the `harness-kit:<name>` plugin agents) governs work here, off the same rules / skills source of truth that init writes into a new project. If we can't develop this repo with it, we shouldn't ship it.

## Repository layout

```
harness-kit/
├── skills/                       Claude Code Skills (the product)
│   ├── harness-init/             Bootstrap skill + templates
│   │   └── templates/
│   │       ├── common/           Shared assets (base rules, docs, evals; framework agents NOT here since v0.30)
│   │       ├── fullstack/        Fullstack overlay (partition dev-* agents, overlay rules)
│   │       ├── backend/          Backend overlay
│   │       └── i18n/zh/          Chinese translation overlay
│   ├── harness-adopt/
│   ├── harness-verify/
│   └── harness-status/
│
├── agents/                       Plugin-native framework agents (v0.30+): 7 canonical + supervisor
│                                 (auto-discovered, dispatched harness-kit:<name>; single source)
├── .claude-plugin/               Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
│
├── .harness/                     This repo's project SOT (dogfood)
│   ├── agents/                   Partition dev-* agents only (empty in this repo; framework agents → top-level agents/)
│   ├── rules/                    Project-specific rule fragments
│   └── scripts/                  verify_all, harness-sync, sync-self, test-init, … (relocated here in v0.20)
├── .claude/                      Claude Code binding (agents/ partition dev-* + skills/ synced from .harness/)
├── CLAUDE.md                     ~15-line stub pointing at AI-GUIDE.md (written once at init)
├── .github/copilot-instructions.md  ~15-line stub pointing at AI-GUIDE.md
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
| 0.18.0 | done | **I.6 gap-tolerant retired-claim guard**: the `verify_all` I.6 phrase guard upgrades from literal-substring matching to a gap-tolerant ordered-anchor scan — each banned entry is a list of plain-text anchors that must appear in order on one line within a bounded gap, with optional line-scoped `exclude` tokens so accurate negated prose does not FAIL. I.6 exempt-dir widened to the whole `docs/features/` subtree. New `.harness/scripts/test-verify-i6.{ps1,sh}` regression pair. No new check; `verify_all` stays 30. |
| 0.18.1 | done | **`test-verify-i6` hardening**: structural-lockstep upgraded to a full 2×2 (`test-verify-i6.{ps1,sh}` × `verify_all.{ps1,sh}`) verbatim per-entry × 4-field (anchors / reason / exclude / gap) comparison — closes the v0.18.0 leftover where the PS-side only checked entry count + entry #10's `.claude/` exclude. New file-exempt predicate symmetric to the existing dir-exempt one, plus element-wise lockstep on the I.6 exempt-file (`CHANGELOG.md`, `architecture.html`, …) and exempt-dir lists. AC-8 (`CHANGELOG.md` / `_archived/` exemption) now has a permanent corpus fixture instead of the v0.18.0 inline-injection probe. Assertion counts: 35→56 (PS), 34→56 (bash); `verify_all` stays 30. |
| 0.18.2 | done | **`settings.json` schema-validation guard (J.1)**: the `$schema` URL in the dogfood + template `.claude/settings.json` was missing the `.json` suffix, so the 301-redirect target served `application/octet-stream` and many editors silently rejected the schema — file flagged invalid even though JSON parsed. Canonical URL restored. New `verify_all` J.1 check parses both files (repo + `.tmpl`), enforces the canonical `$schema`, and rejects any key inside `hooks` that is not in the upstream event enum — catches both v0.17.2 (wrong key placement) and v0.18.2 (wrong URL form) classes at the gate. New rule fragment `.harness/rules/80-settings-schema.md` documents the "consult upstream schema via context7 before editing" workflow. `verify_all` 30 → 31 checks. |
| 0.19.0 | done | **Batch mode**: new `/harness-kit:harness-batch <batch-id>` skill runs a list of tasks (`T-01…T-NN` in `docs/batches/<batch-id>/BATCH_PLAN.md`) sequentially through `pm-orchestrator`, dispatched via the `Task` tool so each task gets its own sub-agent context and the batch orchestrator never accumulates more than per-task summaries. Strong-signal-only stop policy (`verify_all` FAIL, pm-orchestrator FAIL, 3 same-stage rollbacks, `intervention.md` STOP, safety hook block). Resumable: re-invoking with the same batch-id skips tasks whose `07_DELIVERY.md` is `DELIVERED`. New `docs/batches/` directory with lifecycle README and `_template/BATCH_PLAN.md`. `verify_all` skill count 10 → 11 (C.1 / G.1 / G.2 in both shells). |
| 0.20.0 | done | **Scripts relocation**: all harness-owned scripts moved from `scripts/` to `.harness/scripts/` so they no longer collide with a user project's own `scripts/` directory. New idempotent `.harness/scripts/migrate-scripts-layout.{ps1,sh}` helper migrates existing projects (timestamped `.bak`, `-DryRun`/`-Force`, surgical path rewrite). All live path references, hook wiring (template + propose-only dogfood settings), `verify_all` self-checks (both shells), and contributor docs + `MIGRATION.md` updated in lockstep. `verify_all` stays 31 checks. |
| 0.22.0 | done | **Streaming / living-pool mode**: new `/harness-kit:harness-stream <pool-id>` skill drains a continuously-growable pool (`docs/batches/<pool-id>/BATCH_PLAN.md`) one task at a time, re-reading the pool each iteration so mid-run additions (chat / pool append / `ADD` intervention) are planned without re-invoking. **Best-effort** completion (failed task marked + skipped, stream continues) vs batch's fail-stop; same hard-safety stops (`verify_all` FAIL / `STOP` / safety hook). New `ADD <slug> — <goal>` intervention keyword (pool-scoped). `verify_all` skill count 11 → 12. |
| 0.23.0 | done | **Upgrade an old project**: new `/harness-kit:harness-upgrade` Setup skill brings an already-initialized but stale project up to the current plugin layout — relocates scripts to `.harness/scripts/`, **content-refreshes** the depth-sensitive scripts from the current template (fixes the relocated-but-stale one-up root derivation), re-installs the pre-commit hook, rewires `.claude/settings.json` (raw-text, never re-serialized), and regenerates `verify_all` from the type template while preserving the user's B.* checks via `HARNESS:B-CUSTOM` delimiters (verbatim splice, or halt-for-confirm). One deterministic helper `upgrade-project.{ps1,sh}` (dry-run, idempotent, exit-code contract); the six `verify_all` templates gain inert B.* markers. `verify_all` skill count 12 → 13 (check count stays 32). |
| 0.30.0 | done | **Agents cutover (redesign Leg 1 complete)**: the 7 framework agents (+ supervisor) ship **plugin-native** (top-level `agents/`, dispatched `harness-kit:<name>`) — projects no longer copy them, eliminating the agent duplication/drift class entirely. Pipeline dispatch switched to `harness-kit:<name>` across all skills; partition `dev-*` agents stay project-local. `sync-self` drops the agent mirror; `verify_all` D.1/E.3/E.4/I.3 repointed to `agents/`. `verify_all` stays 32 checks, skills stay 15. |
| 0.31.0 | done | **Hook↔script congruence (dangling-hook class eliminated)**: every flow's settings rewire is now presence-gated and every flow ends with a hook↔script congruence assertion — a wired hook command can no longer silently reference a missing script. `migrate-scripts-layout` + `upgrade-project` gain a terminal scan with new exit code `4`; `upgrade-project` also repairs wired literal `{{...}}` placeholder tokens to the OS-picked command and re-lands the ambient hook pair. `/harness-status` reports per-event hook congruence; type `verify_all` templates gain an `E.4b`/`D.4b` dangling-hook FAIL row and the v0.30-correct agents-layout row. Ambient hooks are OS-picked at init (`{{AMBIENT_PROMPT_COMMAND}}`/`{{AMBIENT_RESET_COMMAND}}`). `verify_all` stays 32 checks, skills stay 15. |
| 0.32.0 | done | **Stream ingest triage / auto-decomposition**: /harness-stream (chat-under-/loop + ambient) triages each normalized requirement — a complex multi-part requirement becomes N dependency-staged pool rows (shared slug prefix + Notes provenance line, real deps only, Mode per row), a simple one stays 1 row; hard rule amended to the union-equivalence invariant (derive by partitioning one user requirement; never invent or drop scope; user-authored rows never split). Ambient hook block updated in 4-file lockstep. No schema change; `verify_all` stays 32 checks, skills stay 15. |
| 0.33.0 | done | **Stream defer-human**: /harness-stream defers a task that needs human input (clarification, a human-reserved decision, or safety-critical-action authorization) instead of sitting stopped — a new distinct `needs-human` status sets the row aside, blocks only its `Depends on` descendants, and the stream keeps draining everything runnable. pm-orchestrator returns a self-identifying `BLOCKED: NEEDS-HUMAN — …` verdict under a stream (new dispatch signal `deferred-human mode: defer, do not ask`) and never auto-decides a human-reserved point to dodge blocking (new Hard rule). All asks aggregate into a FIRST `## Needs your input` section of `STREAM_REPORT.md` and the exit message leads with the digest. The three hard-safety stops (verify_all FAIL / STOP / guard-rm block) are unchanged; `AskUserQuestion` removed from the skill's allowed-tools. No schema change; `verify_all` stays 32 checks, skills stay 15. |
| 0.20+ | planned | Supervisor auto-dispatch by PM at user-configurable stage boundaries (once false-positive budget is proven against ≥10 real tasks). **Parallel stream dispatch — deferred** after a vetted, adversarially-reviewed design ([docs/parallel-stream-design.html](docs/parallel-stream-design.html)): serial stream + the existing intra-task partition parallelism cover the need today; **Model B** (same-tree partition, no merges) is the on-demand path once a genuinely-decoupled task batch makes the Amdahl math pay off; **Model A** (worktree real-parallel) is shelved (risk > benefit — env provisioning, Windows-junction, per-task branch/commit, merge livelock needing a scheduler/coordinator tier). |

## Design principles

1. **Don't reinvent platform mechanisms** — Sandbox, Hooks, Sub-agents, MCP, Memory are Claude Code's job
2. **Mechanism vs content** — platform gives mechanism, this repo gives content
3. **Claude-native by default** — framework agents ship as plugin agents (`harness-kit:<name>`); `.harness/` is the project's rule/skill/partition-agent truth; `.claude/agents/` (partition `dev-*`) + `.claude/skills/` are synced bindings; `CLAUDE.md` + `.github/copilot-instructions.md` are static bootstrap stubs.
4. **Evolutionary delivery** — MVP → Hardening → Scale, not big-bang
5. **Baseline only goes up** — test counts, rule coverage never regress silently
6. **Finder doesn't fix** — Reviewer can't edit code, Gate can't edit requirements
7. **Downstream can't edit upstream** — only propose rollback via PM
8. **PM only routes** — never makes professional judgments

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs and issues welcome.

## License

[MIT](LICENSE)
