# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-05-16

### Added — Project-wide language policy (English / 中文)

`/harness-init` and `/harness-adopt` now ask a fifth question: **Project output language**.

The answer is **not just doc language** — it's a project-wide enforcement of which language all AI output uses. Specifically, the choice affects:

- Replies to the user in chat
- Agent-to-agent hand-offs
- Every per-task document (`01_REQUIREMENT_ANALYSIS.md` through `07_DELIVERY.md`, `PM_LOG.md`)
- Updates to `tasks.md` / `dev-map.md`
- Error messages and status reports
- Even when the user writes in another language, AI responds in the configured project language

Enforcement: a new **"Output language"** section at the top of generated `CLAUDE.md`. Agents read CLAUDE.md and follow the rule.

### Files added

- `templates/common/.harness/rules/00-core.md.tmpl` — top-level "Output language: English" callout (default).
- `templates/i18n/zh/` — Chinese translation overlay covering the 7 most user-facing files:
  - `common/.harness/rules/00-core.md.tmpl` (output language: 中文; rest translated)
  - `common/docs/workflow.md` (7-stage pipeline)
  - `common/docs/dev-map.md.tmpl`
  - `common/docs/tasks.md.tmpl`
  - `common/docs/spec/README.md`
  - `common/evals/golden-tasks.md.tmpl`
  - `fullstack/.harness/rules/50-fullstack.md`
  - `backend/.harness/rules/50-backend.md`

### Not translated (intentional, Phase 1 scope)

Agent prompts (`.harness/agents/*.md`) stay in English. LLM reads English equally well; file size stays manageable. The "Output language" CLAUDE.md rule binds *output* without forcing the agent definitions to be translated. Future phases may translate agents if user demand surfaces.

Skills (`.harness/skills/{build,test,verify}/SKILL.md`) and scripts also stay English-only.

### Changed

- `harness-init` SKILL.md: Q5 added with explicit project-wide language semantics.
- `harness-adopt` SKILL.md: Q5 added; pre-fill recommends Chinese when existing README/CONTRIBUTING is dominantly Chinese.
- `templates/common/.harness/rules/00-core.md.tmpl`: added top "Output language" section before "How this project is developed".
- New `{{LANG}}` placeholder available (`en` default, `zh` when Chinese selected).

### Tests

- test-init: still 104/104 PASS (English default unchanged).
- test-real-project: still 76/76 PASS.
- verify_all (this repo): still 19/19 PASS.
- Not yet added: an i18n=zh assertion to test-init. Will add when first issue surfaces.

### Upgrading existing v0.6.x projects

The new "Output language" rule only applies to newly initialized projects. Existing projects (like `TodoList`) keep their v0.6.x CLAUDE.md without the rule — AI will continue to use whatever language it picks up from context.

To upgrade an existing project:
1. Edit `.harness/rules/00-core.md`, add an "## Output language" section (copy from the v0.7 template) declaring the desired language.
2. Run `scripts/harness-sync` to regenerate `CLAUDE.md`.
3. New sessions will follow the new rule.

## [0.6.4] - 2026-05-16

### Fixed

- **Generated-project `verify_all` no longer reports silent PASSes**. v0.6.3 and earlier had B.1/B.2/B.3 (and similar steps in backend templates) return PASS when their prerequisite (e.g. `package.json`) didn't exist — confusingly identical to a real PASS. The script now distinguishes PASS / WARN / FAIL / **SKIP**, where SKIP means the check's prerequisite is absent and the check didn't run. SKIPs do not affect exit code. First user feedback after end-to-end test on `C:\Programs\TodoList` flagged this.
- **D.1 "OpenAPI / tRPC schema present" no longer WARNs on empty projects**. Now SKIPs when no source code (`src/` / `apps/` / `packages/`) exists. Only WARNs on real projects that have code but lack a schema.
- **E.4 step name no longer renders as garbled glyphs on Windows console**. Replaced the Unicode `→` arrow with ASCII `->` in step labels (the binding-direction arrow). Same fix applied to backend's `D.4`.
- B.2 Lint now SKIPs when no eslint config exists (previously could FAIL).
- B.3 Unit tests now SKIPs when `package.json` has no `test` script (previously could FAIL).
- B.4 Test count vs baseline now SKIPs while baseline is at zero (just-initialized state).
- A.1/A.2/A.3 now SKIP when the project isn't a git repo (previously would error).
- Backend C.1 migrations check SKIPs when there's no migrations directory.

### Added

- Summary line now shows SKIP count alongside PASS/WARN/FAIL.
- verification_history.log entries include skip count for trend analysis.

### Tests

- test-init: still 104/104 PASS (template-copy logic unchanged).
- test-real-project: still 76/76 PASS.
- verify_all (this repo): still 19/19 PASS.

### Upgrading

Existing initialized projects (like `TodoList`) keep their v0.6.3 verify_all. To pick up the v0.6.4 polish: copy the new `scripts/verify_all.{ps1,sh}` from the harness-kit repo (or re-init in a sibling folder and selectively port). No data loss either way.

## [0.6.0] - 2026-05-15

### Changed

- **Project renamed: "Harness Engineering for Claude Code" → "Harness Kit"** (or just `harness-kit` in code/URL contexts). The methodology is still called Harness Engineering; the *project that distributes a toolkit implementing it* is now called Harness Kit. Branding references updated across README, CHANGELOG, CONTRIBUTING, MIGRATION, architecture.html, walkthrough.html, getting-started, concepts, dev-map, install scripts. References to the methodology and to the four source articles ("OpenAI Harness Engineering", "Harness Engineering 如何工程化落地", etc.) are unchanged — those are about the methodology, not this project.

### Added

- **Claude Code Plugin packaging**. `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` make this repo installable through Claude Code's native plugin marketplace, which is the recommended path going forward:
  ```
  /plugin marketplace add Alan-IFT/harness-kit
  /plugin install harness-kit@harness-kit-marketplace
  ```
  After install, skills are namespaced: `/harness-kit:harness-init`, `/harness-kit:harness-adopt`, etc.
- **One-line install for the legacy path** (direct copy to `~/.claude/skills/`). install.{ps1,sh} now auto-detect whether they're running from a cloned repo or from `curl | sh`; in the latter case they git-clone the repo into a temp dir and copy from there. No more `git clone first, then run install`.
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.sh | sh
  ```
  ```powershell
  iwr -useb https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.ps1 | iex
  ```
- README install section now leads with the Plugin path, lists curl/iwr one-liner as method 2, and clone-and-run as method 3 (dev mode).

### Migration from 0.5.x

No behavior changes for already-installed users. The repo's old name (`harness-engineering`) is referenced in some places — these will resolve to either the new repo URL or a redirect once the repo is renamed on GitHub. If you cloned `~/harness-engineering` previously, it keeps working; no rename forced.

## [0.5.0] - 2026-05-15

### Added

- **Backend Developer partitioning** (symmetric with v0.4 fullstack partitioning):
  - Three new partition agents under `templates/backend/.harness/agents/`:
    `dev-api.md.tmpl` (route handlers / contracts / middleware),
    `dev-services.md.tmpl` (business logic / domain / orchestration),
    `dev-db.md.tmpl` (schema / migrations / ORM / repositories).
  - Each has explicit `Owned paths (glob)` plus partition rules — out-of-scope
    changes raise `BLOCKED ON PARTITION`.
  - The Architect's `Partition assignment` table now applies to backend projects
    too. Default dispatch order: dev-db → dev-services → dev-api.
- **`harness-init` Q4 now offered for backend projects** (was fullstack-only). Choices:
  Partitioned (recommended) vs Single developer. Single-mode opt-out works identically
  to fullstack.
- **`harness-adopt` Q4 mirrors init for backend**, with pre-fill suggestion based on
  detected layout (presence of `src/routes/` + `src/services/` + `migrations/` —
  or controller/service/repository pattern — recommends Partitioned).
- `50-backend.md` documents the partition system at the rule level.

### Tests

- `test-init`: 98 → **104** assertions (+6 backend partition checks). Both fullstack
  and backend projects now produce 3 partition agents under partitioned mode.
- `test-real-project`: 70 → **76** assertions (+6).
- `verify_all`: 19/19 unchanged (new files inherit existing checks).

### Resolves user feedback #2 fully

v0.4 covered fullstack partitioning. v0.5 covers backend symmetrically. Both
project types now have project-shape-aware Developer agents instead of a single
generic developer for all code.

### Out of scope (deferred)

- Microservice-specific partitioning (per-service `dev-<svc>` agents). Needs more
  thought about how to dynamically generate per-service agents from project structure.
  Currently a single-monolith-with-layers default. → v0.6 or later.
- Semantic rule extraction in `harness-adopt` (currently keyword-based). → v0.6.

## [0.4.1] - 2026-05-15

### Fixed

- **`/harness-adopt` now asks the partition question** (Q4) for fullstack projects, matching what `/harness-init` does. v0.4.0 only upgraded `harness-init`; `harness-adopt` was left in single-developer mode regardless of project layout — a consistency gap. v0.4.1 closes it: adopt detects fullstack layout (typically `apps/web/` + `apps/api/`), pre-fills Partitioned as the recommendation, copies the three `dev-*` partition agents when chosen, and copies only the generic `developer.md` when single mode is chosen.
- Adopt's plan output and roadmap section updated to reference partition agents.

### Changed

- `architecture.html` brought current with v0.4 (was stale at v0.3).

## [0.4.0] - 2026-05-15

### Added

- **Developer partitioning for fullstack projects** (resolves the original feedback that "single Developer doesn't fit real project structure"):
  - Three new partition agents shipped in `templates/fullstack/.harness/agents/`: `dev-frontend.md.tmpl` (UI/pages/components), `dev-backend.md.tmpl` (API/services), `dev-db.md.tmpl` (schema/migrations).
  - Each partition has explicit `Owned paths (glob)` declaring which file patterns it may touch. Out-of-scope changes raise `BLOCKED ON PARTITION` and are coordinated by PM rather than reached across.
  - Generic `developer.md` is preserved as a fallback for ambiguous tasks. `verify_all` does not require partitions to exist.
- **PM Orchestrator gains partition routing logic** in stage 4. It detects `.harness/agents/dev-*.md` files at start of dispatch; if found, partitioned mode is engaged; if not, single Developer mode preserves v0.3 behavior. Default dispatch order is dependency-derived (db → backend → frontend), strictly sequential unless the Architect marks partitions independent.
- **Solution Architect must produce a `Partition assignment` section** in `02_SOLUTION_DESIGN.md` when partition agents exist. Table form: file / partition / new-or-edit / dependency. Plus an explicit dispatch order and parallelism note.
- **harness-init asks a new question Q4** (only for fullstack): `Partitioned (recommended)` vs `Single developer`. New placeholder `{{PARTITIONED}}` available for templates (currently unused; reserved).
- **Single mode opt-out**: if user picks single Developer mode, init deletes the partition agents after copy, leaving only the generic `developer.md`.
- **50-fullstack rule fragment** documents the partition system at the rule level.

### Tests

- `test-init` now asserts: fullstack init produces all three partition agents (`dev-frontend/backend/db`) with placeholders substituted; backend init does NOT produce them. Total: 86 → 98 assertions.
- `test-real-project` asserts the same on fixture overlays. Total: 64 → 70 assertions.
- `verify_all` still 19/19 (no schema change; the new files inherit existing checks via templates).

### Out of scope (deferred)

- Backend partitioning (per-service `dev-<svc>` agents for microservices, or layer-based for monoliths). v0.5.
- `harness-adopt` partition detection. v0.5.
- True parallel partition dispatch (multi-brain-multi-sandbox). Future, depends on platform.

## [0.3.0] - 2026-05-15

### Added

- **`/harness-adopt` now applies the plan**, not just writes it. After reconnaissance (detect stack, extract conventions, propose additions) the skill asks an explicit "apply?" confirmation, then writes files non-destructively. Existing files are never overwritten without explicit per-file confirmation in overwrite mode; merge mode skips conflicts.
- Conflict modes (cancel / merge / overwrite) when target already has `.harness/`, `.claude/`, or `CLAUDE.md`.
- Auto-extraction of rule candidates from `README`, `CONTRIBUTING`, `.editorconfig`, lint configs into `.harness-adopt/CLAUDE.draft.md` for user review before adoption.
- Project type inference from folder shape (e.g. `apps/web/` + `apps/api/` → fullstack) with user confirmation.
- Baseline capture: `verify_all` is run after adopt to seed `scripts/baseline.json` with the project's current state — existing tests preserved, not reset to zero.
- Extracted existing conventions land in `.harness/rules/80-existing-conventions.md` for user review and reorganization.

### Changed

- `harness-adopt` SKILL.md substantially rewritten: 8 procedural steps with explicit gating, hard rules (no silent overwrite, no `npm install` on stranger codebases, no CI modification), anti-patterns, and roadmap.
- `README.md` and `CHANGELOG.md` mark `harness-adopt` as `✅` (fully functional) instead of `⚠️ scaffolding-only`.

### Roadmap shift

- v0.4 will add Developer-agent partitioning (per-folder `dev-*` agents during `harness-adopt` and `harness-init`).
- v0.5 will add 3-way merge for `CLAUDE.md` and overlapping overlays, plus deeper rule extraction (semantic, not just heading-based).

## [0.2.0] - 2026-05-15

### Added

- **Tool-agnostic `.harness/` layer.** Project knowledge (agents, rule fragments, skills) now lives in `.harness/`, decoupled from `.claude/`. The `.claude/` folder and `CLAUDE.md` are *generated* from `.harness/` by `scripts/harness-sync`. Effect: editing a single source of truth regardless of which IDE/tool you eventually point at the project.
- **`scripts/harness-sync.{ps1,sh}`** — binding sync for the Claude Code target. Reads `.harness/agents/`, `.harness/rules/`, `.harness/skills/` and writes `.claude/agents/`, `.claude/skills/`, and a composed `CLAUDE.md`. `--check` mode reports drift without writing.
- **Two-layer self-consistency model.** `sync-self` keeps `templates/common/` ↔ this repo's `.harness/` and `scripts/harness-sync.*` byte-identical (Layer 1). `harness-sync` keeps `.harness/` ↔ `.claude/` + `CLAUDE.md` byte-identical (Layer 2). `verify_all` checks both layers and FAILs on drift.
- **Rule fragments instead of monolithic CLAUDE.md.** Templates now ship `.harness/rules/00-core.md.tmpl` (base) and overlays ship `.harness/rules/50-<type>.md`. `harness-sync` composes them by filename order. Replaces the old `.append` mechanism cleanly.
- **`harness-sync --check` integrated into generated-project verify_all** (fullstack + backend templates, both `.ps1` and `.sh`). User projects fail verification if they edit `.harness/` but forget to sync.
- 86 regression assertions per full `test-init` run (43 per project type) — up from 64 in 0.1.0 — now covering binding sync end-to-end.

### Changed

- `templates/common/CLAUDE.md.tmpl` → `templates/common/.harness/rules/00-core.md.tmpl` (`git mv`, history preserved).
- `templates/fullstack/CLAUDE.md.append` → `templates/fullstack/.harness/rules/50-fullstack.md` (`git mv`).
- `templates/backend/CLAUDE.md.append` → `templates/backend/.harness/rules/50-backend.md` (`git mv`).
- `templates/<type>/.claude/skills/{build,test,verify}/SKILL.md.tmpl` → `templates/<type>/.harness/skills/...` (`git mv`).
- `templates/common/.claude/agents/` → `templates/common/.harness/agents/` (`git mv`).
- `harness-init` SKILL.md updated with the two-layer model, new step 6 (run `harness-sync` after copy), and explicit "edit `.harness/`, never `.claude/`" guidance.
- `sync-self.{ps1,sh}` extended to keep `scripts/harness-sync.*` in sync between templates and repo root (previously only synced agents).
- `verify_all` (this repo): 15 → 18 PASS. New checks for Layer 1, Layer 2, rule sources, generated artifacts, and `harness-sync.*` pair symmetry.
- `docs/dev-map.md` rewritten to reflect the v0.2 layout and dual-layer dogfood model.

### Migration from 0.1.x

For projects that were initialized with v0.1.x, see `MIGRATION.md` (TBD — manual at the moment: move `.claude/agents/` content to `.harness/agents/`, split `CLAUDE.md` into `.harness/rules/`, copy in the new `scripts/harness-sync.{ps1,sh}` from this repo, run sync). v0.3 will ship an automated upgrade Skill.

## [0.1.0] - 2026-05-15

### Added

- Initial release as Claude Code Skills package.
- Four skills:
  - `harness-init`: bootstrap new project with full Harness skeleton (7 agents, CLAUDE.md, workflow, verify_all, evals).
  - `harness-adopt`: **scaffolding-only in 0.1.0** — reconnoiters the repo and writes `.harness-adopt/PLAN.md` for manual application. Automated apply shipped in 0.3.0.
  - `harness-verify`: run the project's verify_all script and report PASS/WARN/FAIL.
  - `harness-status`: show current Harness asset health.
- Project type templates: fullstack and backend.
- Cross-platform verify_all scripts in PowerShell and Bash.
- 7 sub-agent definitions with role contracts: PM Orchestrator, Requirement Analyst, Solution Architect, Gate Reviewer, Developer, Code Reviewer, QA Tester.
- workflow.md defining the 7-stage pipeline with rollback rules.
- Architecture design document as interactive HTML.
- One-command install scripts for Windows (PowerShell) and Unix (Bash).
- Documentation: getting-started, workflow detail, concept reference, CONTRIBUTING.
- `.gitattributes` for cross-platform line endings.
- Automated `test-init.{ps1,sh}` regression (64 assertions in 0.1.0; 86 in 0.2.0).

### Design Decisions

- Built **on top of** Claude Code rather than reinventing platform primitives.
- Removed for personal/small-team use: Vault credential store, complex Token Budget tiers, production-grade Eval pipeline, OpenTelemetry tracing.
- Single-platform support: Claude Code only.
- Project types limited to fullstack and backend.

## Legend

- `Added` — new features
- `Changed` — changes to existing functionality
- `Deprecated` — soon-to-be removed features
- `Removed` — removed features
- `Fixed` — bug fixes
- `Security` — security fixes
