# 05 — Code Review: ambient-stream

> Stage 5 · code-reviewer · mode: full · 2026-06-08
> Independent review — live files read, upstream not trusted blindly. Reviewer is read-only (Read/Glob/Grep); `verify_all` is run by the PM.

## VERDICT: APPROVED

No BLOCKER, no MAJOR, no MINOR. Two non-blocking NITs. Implementation faithfully matches the converged design and honors gate conditions C1-C5 and the propose-only red line.

## Files reviewed (live)

- `.harness/scripts/ambient-prompt.ps1` / `.sh`; template twins `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`
- `skills/harness-init/templates/common/.claude/settings.json.tmpl`
- `.claude/settings.json` (dogfood — confirmed UNMODIFIED)
- `.harness/scripts/verify_all.ps1` / `.sh` (F.1 + J.1 regions)
- `skills/harness-stream/SKILL.md`; `.gitignore`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `AI-GUIDE.md`, `docs/dev-map.md`
- Reference: `01`–`04` docs, `docs/batches/_template/BATCH_PLAN.md`, `guard-rm.ps1`

## Findings

### BLOCKER / MAJOR / MINOR
None.

### NIT
- [STYLE] `ambient-prompt.sh:24` — stdin drain `cat - >/dev/null 2>&1 || true`; `.ps1` uses try/catch around `ReadToEnd()`. Both never block, both fail-open. No action (recorded for symmetry transparency).
- [MAINT] `ambient-prompt.ps1:17-19` carries a pwsh-specific `-NoProfile` header comment the `.sh` omits. Intentional and correct — cross-shell twins are never byte-identical; C1 byte-identity is dogfood↔template *within the same shell*, which holds.

## Focus-area results

1. **Hook correctness — PASS.** Both scripts drain stdin without blocking; resolve repo root via `.git`-ancestor WALK (`.ps1:31-38` mirrors `guard-rm.ps1:40-43`; `.sh:28-35`), NOT `$PSScriptRoot`/`$0` depth arithmetic (insight L31); no-op with no stdout + `exit 0` when `.harness/ambient.flag` absent (`.ps1:39,43`; `.sh:36,40`); emit the identical instruction block when present (`.ps1:46-63`; `.sh:43-59`); ALWAYS `exit 0` (fail-open). `.ps1`/`.sh` logically equivalent: same gate, same emitted text (incl. the EN/zh "ambient off" reminder).
2. **C1 byte-identity — PASS.** dogfood↔template `.ps1` line-for-line identical; same for `.sh`; all four LF-only (no CRLF discrepancy).
3. **C2 — PASS.** Only `verify_all` change is the F.1 pair-list extension `ambient-prompt` in both shells (`.ps1:271`, `.sh:285` + step title). No check asserts the dogfood ambient hook. Exactly 32 `Step` calls; G.4 dynamic count = 32. Count unchanged.
4. **C3 / J.1 — PASS.** `settings.json.tmpl`: `UserPromptSubmit` is a `hooks` child (in both J.1 enums `.ps1:579`/`.sh:612`); command has `-NoProfile`; `$schema` canonical; `_ambient_hook` doc key at ROOT, never inside `hooks`.
5. **C4 doc sweep + no drift — PASS.** CHANGELOG `[Unreleased]` (not a bump); `[0.22.0]` intact. SKILL.md, README EN+zh, dev-map, AI-GUIDE updated. `baseline.json` still `"verify_all_checks": 32`; `12 skills` and `0.22.0` untouched.
6. **Red line — PASS.** Dogfood `.claude/settings.json` NOT modified (`hooks` = Stop + PreToolUse only). Change proposed in `04_DEVELOPMENT.md:33-59` only.
7. **Design fidelity — PASS.** SKILL.md "Ambient mode" matches `02_SOLUTION_DESIGN.md`: gated flag, enter/exit EN+zh, per-turn ingest→drain→stop, serial-only, ambient≠/loop, default-pool auto-create with empty table. No silent drift.

## Requirement coverage

AC-1..AC-10, AC-12 PASS; AC-13 N/A (no new placeholder — correct). **AC-11 (verify_all PASS on the user's shell) DEFERRED to the PM** — verified by PM: `verify_all.sh` PASS 32/0/0 (see `07_DELIVERY.md`).

## Open item routed to PM
- Run `verify_all` and treat its real Summary as the binding gate before Delivery. (Done by PM — `verify_all.sh` PASS 32/0/0.)
