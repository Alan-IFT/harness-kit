# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Integration test infrastructure**. `scripts/test-real-project.{ps1,sh}` now overlays harness-init templates onto two fixture projects (`tests/fixtures/todo-fullstack/`, `tests/fixtures/todo-backend/`), runs the embedded `harness-sync`, and asserts that:
  - Existing fixture files (source, tests, package.json / pyproject.toml, .gitignore) are byte-identical after overlay (nothing clobbered).
  - All Harness SOT + generated artifacts are present.
  - `harness-sync --check` is clean.
  - 64 assertions per full run; both fixtures PASS.
- `tests/fixtures/{todo-fullstack,todo-backend}/` minimal real-shape projects (no dependencies) as permanent regression assets.
- `verify_all` step `F.1` now requires the new script pair; step `H.1` new — checks fixture presence.

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
