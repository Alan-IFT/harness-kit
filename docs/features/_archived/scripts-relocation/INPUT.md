# Task Input — scripts-relocation (T-007)

## User request (verbatim, zh)

> 当前存在一个问题，会把脚本放在用户项目的 scripts 目录下，与用户本身自有的脚本混在一起，不方便管理。

## Goal (one line)

Relocate all harness-kit-owned operational scripts out of the user project's `scripts/` root into a dedicated `.harness/scripts/` namespace, so they no longer collide with the user's own scripts.

## Pre-decided constraints (user-confirmed before pipeline start)

1. **Target location**: ALL harness scripts move into `.harness/scripts/` — *including `verify_all` itself*. The canonical entry changes from `scripts/verify_all` → `.harness/scripts/verify_all`.
2. **Scope**: both (a) this dogfood repo's own `scripts/`, and (b) the distributed templates under `skills/harness-init/templates/**/scripts/` that `/harness-init` and `/harness-adopt` install into user projects.
3. **Execution vehicle**: full `/harness` 7-stage pipeline (user explicitly chose Gate-Review-gated execution over plan-only or direct-edit).

## Measured blast radius (from PM pre-flight)

- ~750 repo-wide `scripts/<name>` path references across `skills/*.md`, `.harness/rules/*.md`, `AI-GUIDE.md`, `docs/` — must distinguish live docs from `docs/features/_archived/**` (historical, do NOT rewrite).
- Distributed template scripts: `skills/harness-init/templates/common/scripts/` + `backend|fullstack|generic` stack overlays' `verify_all.*.tmpl`.
- Hook wiring: `.claude/settings.json` Stop hook (`scripts/harness-sync.ps1`) + PreToolUse hook (`scripts/guard-rm.ps1`), AND template `skills/harness-init/templates/common/.claude/settings.json.tmpl`. Stale paths → user-project safety guard silently fails.
- `verify_all`'s own self-checks: it validates "script pairs (.ps1+.sh) exist under `scripts/`" (40-locations §37) — must be retargeted to `.harness/scripts/`.
- `sync-self` syncs 4 script pairs (harness-sync, install-hooks, archive-task, guard-rm) byte-identical with templates — path assumptions inside.
- This repo's own `scripts/` (dogfood) + test scripts (test-init, test-real-project, test-supervisor, test-verify-i6) that reference script locations.

## Acceptance criteria

- AC-1: After `/harness-init`, a fresh user project has harness scripts under `.harness/scripts/`, and the user's `scripts/` root is left untouched (ideally harness no longer requires a `scripts/` dir at all).
- AC-2: All hooks resolve to the new paths (guard-rm PreToolUse block + harness-sync Stop sync both still fire).
- AC-3: `verify_all` (at whatever its new invocation path is) runs green / PASS.
- AC-4: Backward-compat for already-initialized user projects is addressed (migration helper, compat shim, or documented manual step) — Solution Architect decides, Gate Reviewer vets.

## Out of scope

- Renaming the scripts themselves (only relocating the directory).
- Changing script behavior/logic beyond path constants required by the move.
