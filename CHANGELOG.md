# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-15

### Added

- Initial release as Claude Code Skills package.
- Four skills:
  - `harness-init`: bootstrap new project with full Harness skeleton (7 agents, CLAUDE.md, workflow, verify_all, evals).
  - `harness-adopt`: scaffold for adopting Harness in existing projects (stub, scans repo and proposes config).
  - `harness-verify`: run the project's verify_all script and report PASS/WARN/FAIL.
  - `harness-status`: show current Harness asset health (which files present, baseline state, last verify result).
- Project type templates: fullstack (Next.js / NestJS / Postgres style) and backend (FastAPI / NestJS / Gin style).
- Cross-platform verify_all scripts in PowerShell and Bash.
- 7 sub-agent definitions with role contracts: PM Orchestrator, Requirement Analyst, Solution Architect, Gate Reviewer, Developer, Code Reviewer, QA Tester.
- workflow.md defining the 7-stage pipeline with rollback rules.
- Architecture design document as interactive HTML (`architecture.html`).
- One-command install scripts for Windows (PowerShell) and Unix (Bash).
- Documentation: getting-started, workflow detail, concept reference.

### Design Decisions

- Built **on top of** Claude Code (Sub-agents / Hooks / MCP / Memory) rather than reinventing them.
- Removed for personal/small-team use: Vault credential store, complex Token Budget tiers, production-grade Eval pipeline, OpenTelemetry tracing.
- Single-platform support: Claude Code only. Cursor / Copilot sync removed.
- Project types limited to fullstack and backend; others (WPF / Unity / pure frontend / ML pipelines) deliberately out of scope.

## Legend

- `Added` — new features
- `Changed` — changes to existing functionality
- `Deprecated` — soon-to-be removed features
- `Removed` — removed features
- `Fixed` — bug fixes
- `Security` — security fixes
