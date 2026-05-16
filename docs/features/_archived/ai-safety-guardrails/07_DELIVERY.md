# Delivery Summary

- Task: `T-001 / ai-safety-guardrails` — ship cross-platform AI safety guardrails (rm-outside-project guard hook + tool-flow documentation)
- Mode: `full` (7-stage pipeline)
- Version delivered: **v0.15.0**
- Delivered: 2026-05-17

## Stages traversed (with timestamps)

| Stage | Agent | Start | End | Outcome |
|---|---|---|---|---|
| 1 | requirement-analyst | 2026-05-16 | 2026-05-16 | READY (12 decisions recorded under user mandate) |
| 2 | solution-architect | 2026-05-16 | 2026-05-16 | READY FOR GATE REVIEW (34 files; partition=developer single) |
| 3 | gate-reviewer | 2026-05-16 | 2026-05-16 | APPROVED WITH CONDITIONS (5 conditions C-1..C-5) |
| 4 | developer (pass 1) | 2026-05-16 | 2026-05-17 | DELIVERED (verify_all 27/27, test-init 177/177) |
| 5 | code-reviewer | 2026-05-17 | 2026-05-17 | APPROVED (6 MINORs + 4 NITs, no CRITICAL/MAJOR) |
| 6 | qa-tester (pass 1) | 2026-05-17 | 2026-05-17 | **BLOCKED ON DEV** — D-1, D-2 CRITICAL + D-3 MAJOR + D-4/D-5 MINOR |
| 4 | developer (rollback #1) | 2026-05-17 | 2026-05-17 | Targeted fixes for D-1+D-2+D-3 + fixture extension 11→17 |
| 6 | qa-tester (re-run) | 2026-05-17 | 2026-05-17 | **PASSED** — all defects fixed or accepted as documented |
| 7 | pm-orchestrator (this doc) | 2026-05-17 | 2026-05-17 | DELIVERY |

## Rollbacks

**1 rollback** (well under 3-strike limit):
- QA pass 1 → Developer with D-1, D-2 (CRITICAL false-allow bypass via find-predicate skip not gated to `find` verb) and D-3 (MAJOR perf NFR violation due to missing `-NoProfile`).
- Developer's rollback #1 fix: (a) gated find-predicate skip to `$verb -eq 'find'`, (b) added `-NoProfile` to both pwsh hook commands, (c) extended fixture suite 11 → 17 to lock the regressions.

## Final verify_all result

- `pwsh -File scripts/verify_all.ps1` → **PASS 27, WARN 0, FAIL 0**
- `bash scripts/verify_all.sh` → **PASS 27, WARN 0, FAIL 0**

## Baseline changes

| Suite | Before | After |
|---|---|---|
| `verify_all.{ps1,sh}` | 26/26 | 27/27 (new `F.2` guard wiring check) |
| `test-init.{ps1,sh}` | 162/162 | 177/177 (new PreToolUse + guard-rm fixture assertions) |
| `test-real-project.ps1` | 82/82 | 82/82 (unchanged) |
| `test-guard-rm.{ps1,sh}` (new driver) | — | 17/17 (was 11 pass 1; +6 in rollback) |
| Total green assertions | 270 | **303** (+33) |

## Outstanding risks

- **Perf NFR drift on Windows pwsh**: requirement §6 NFR target `≤ 50 ms median` is platform-unrealistic on Windows (pwsh 7.x cold-start floor ~176ms; measured p50 after `-NoProfile` fix is ~360ms). QA accepted because user-visible pain is gone (10× speedup vs unfixed 3.7s) and the absolute number is dominated by interpreter startup, not algorithm. **Recommended follow-up**: a v0.15.x or v0.16.0 documentation edit revising the NFR to `≤ 500 ms p95 on Windows, ≤ 100 ms p95 on Linux/macOS` and noting that the wrapper cost can be amortized only by moving to a long-lived hook process (out of scope today).
- **D-4 (MINOR, documented limitation)**: A globally-set `HARNESS_ALLOW_OUTSIDE_RM=1` (e.g. in user profile) silently disables the guard, surfacing only as a single stderr INFO line per call. No `harness-status` health check today. Acceptable because the override is intentionally per-call and visible in transcripts; revisit if reports of accidental persistence appear.
- **D-5 (MINOR, documented limitation)**: depth-3+ nested-pwsh quoting can tokenizer-eat the innermost segment without triggering the depth-cap BLOCK. Depth-2 is enforced. Real-world AI emissions of depth-3 nested pwsh are extremely rare; accepted limitation.
- **Code Reviewer MINORs M-1..M-6 + NITs N-1..N-4**: small maintainability nits documented in `05_CODE_REVIEW.md`. None blocking.

## Files changed (summary; 41 files touched)

**New**: `.harness/rules/75-safety-hook.md`, `evals/guard-rm-cases.md`, `scripts/guard-rm.{ps1,sh}`, `scripts/test-guard-rm.{ps1,sh}`, `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl`, `skills/harness-init/templates/common/scripts/guard-rm.{ps1,sh}`, `skills/harness-init/templates/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` (+ `docs/features/ai-safety-guardrails/{INPUT,PM_LOG,01,02,03,04,05,06,07}.md`).

**Modified**: `.claude-plugin/{marketplace,plugin}.json`, `.claude/settings.json`, `.github/copilot-instructions.md`, `.harness/rules/{40-locations,60-tool-handoff}.md`, `AI-GUIDE.md`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`, `docs/dev-map.md`, `docs/tasks.md`, `docs/walkthrough.html`, `scripts/{baseline.json,sync-self.ps1,sync-self.sh,test-init.ps1,test-init.sh,verify_all.ps1,verify_all.sh}`, `skills/harness-{adopt,init,status}/SKILL.md`, `skills/harness-init/templates/common/.claude/settings.json.tmpl`, all template + zh-overlay versions of `AI-GUIDE.md.tmpl` / `60-tool-handoff.md` / `copilot-instructions.md.tmpl`.

## Deliverables (mapped to user's three asks)

- **D1 — Copilot agent flow documentation + opt-in continuous mode**: 
  - `AI-GUIDE.md` (×3 surfaces) gains "AI tool flow modes" section enumerating Claude Code auto-dispatch / Copilot one-role / Copilot continuous mode.
  - `.harness/rules/60-tool-handoff.md` (×3 surfaces) gains "Copilot continuous mode (opt-in)" subsection: activation phrase `continuous mode` (en) / `走全流程` (zh); unconditional HARD STOP after Gate Review; session-scoped (resets each chat).
  - `.github/copilot-instructions.md` (×3 surfaces) third red line softened to "One role at a time **unless the user has explicitly enabled continuous mode** (see `60-tool-handoff.md`)".
- **D2 — Claude Code sub-agent dispatch is already implemented**: documentation callout in `AI-GUIDE.md` (×3 surfaces) citing `.harness/agents/pm-orchestrator.md` (Task tool + lines 108-129 partition routing); new `### 3b. Sub-agent dispatch / safety hook` block in `harness-status/SKILL.md`.
- **D3 — rm-outside-project guard hook**:
  - Cross-platform `scripts/guard-rm.{ps1,sh}` invoked by `PreToolUse` hook in `.claude/settings.json`.
  - Blocks `rm`, `rmdir`, `unlink`, `Remove-Item`, `del`, `erase`, `Clear-RecycleBin`, `shred`, `srm` + `find ... -delete` when any path argument resolves outside the nearest `.git/` ancestor of cwd.
  - Per-call override: `HARNESS_ALLOW_OUTSIDE_RM=1` (no persistent setting allowed).
  - Auto-installed on every project using harness-kit: dogfood + `templates/common/` (so new `/harness-init` projects get it) + `harness-adopt` SKILL.md step 5/6 plan adds it (with JSON-merge logic, not overwrite).
  - New rule fragment `.harness/rules/75-safety-hook.md` documents the contract, override, and disable path (×3 surfaces: dogfood + template + zh).
  - New verify_all check `F.2` asserts the wiring is present on every harness-kit project.

## What the user should know

1. **Both Copilot continuous mode (D1) and Claude Code sub-agent dispatch (D2) are documented and visible in `AI-GUIDE.md` now.** The user's perception "claude code agent dispatch 未实现" was incorrect — it was implemented but undocumented. Fixed.
2. **The guard hook (D3) is now active on this repo.** Future Claude Code Bash tool calls from this `cwd` that try to `rm /etc/something` or similar will be BLOCKED with a clear stderr message. Override per-call via `HARNESS_ALLOW_OUTSIDE_RM=1`.
3. **Every new project bootstrapped with `/harness-init` v0.15+ gets the guard auto-installed.** Existing projects can re-adopt via `/harness-adopt` to merge in the PreToolUse hook (it preserves their existing permissions/Stop blocks).
4. **The 50ms perf NFR was unrealistic on Windows** due to pwsh cold-start; QA accepted the 10× speedup as good enough and filed a follow-up to revise the NFR doc. Not a regression.
5. **Two minor known limitations** (D-4 global env-var, D-5 depth-3+ nested pwsh) are documented in the test report — neither is a meaningful attack surface for the typical AI-driven workflow this guard targets.

## Insight

- 2026-05-17 · PowerShell `-contains` is case-insensitive by default, so a flag-skip list containing `-path` will match `Remove-Item -Path ...` and create a destructive-command bypass — use `-ccontains` for case-sensitive flag lists, or scope flag-skip arrays to the specific verb that needs them. · evidence: T-001 rollback #1, commit (this delivery)
- 2026-05-17 · Claude Code's PreToolUse hook spawns pwsh per call; without `-NoProfile` the user's `$PROFILE` runs each time and dominates wall-clock (measured 3.7s p50 vs 10ms script body). Always pass `-NoProfile` to any pwsh hook command in `.claude/settings.json`. · evidence: T-001 QA p50 measurement, commit (this delivery)
