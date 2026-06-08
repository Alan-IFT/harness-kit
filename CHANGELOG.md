# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.24.0] - 2026-06-08

### Changed — consumer-split output-language policy for `{{LANG}}=zh` projects (T-013)

A `中文`-init project's output-language rule is no longer the blunt "everything in Chinese". It is now **split by consumer**: human-facing output (chat replies, error messages, status/progress reports, delivery summaries, README and human docs) stays **Chinese**; AI-facing work products (the 7-stage per-task documents, PM_LOG, the tasks.md / dev-map / insight-index ledgers, agent / rule / AI-GUIDE / CLAUDE edits, code comments, commit messages) are now **English** — the LLM reads English fine and it stays consistent with the English framework internals. Conversational replies remain Chinese. The English (`{{LANG}}=en`) path is unchanged (single language, no split). No new placeholder; already-generated projects are not migrated.

- **Rewrote the zh policy text** in the i18n/zh overlay: `00-core.md.tmpl` "输出语言" section (now two explicit ZH/EN consumer lists), the `CLAUDE.md.tmpl` + `.github/copilot-instructions.md.tmpl` top "输出语言" line (one-line split summary pointing at `00-core.md`), `skills/harness-init/SKILL.md` Q5 `中文` option, `README.md` + `README.zh-CN.md` language-policy sections, and `docs/manual-e2e-test.md` Q5 expectation. Also corrected SKILL.md step-4.3's stale zh-overlay file list.
- **I.6 retired-claim guard** gains a `全程~中文` banned-line (the retired "everything in Chinese" phrasing) in `verify_all.{ps1,sh}` + the `test-verify-i6.{ps1,sh}` copies (`I6ExpectedEntryCount` 13→14); the new split text contains no "全程" so it cannot self-trip.
- **First test-init language assertion**: a symmetric `test_zh_overlay` / `Test-ZhOverlay` block (PS + Bash, no-python3-tolerant pure greps) on a fresh zh-overlay fixture asserts the ZH list marker and the EN list marker are present and the retired `全程` phrasing is absent.
- **I.6 exempt list** gains `docs/project-overview.html` (a frozen v0.17.0 archived snapshot that honestly records the old "全程中文" wording) across all four lockstep sites — same exemption class as `architecture.html` / `docs/walkthrough.html`.
- Version 0.23.0 → 0.24.0 (plugin.json, marketplace.json, both README badges). Skill count stays 13; `verify_all` stays 32 checks.

### Added — ambient chat-driven stream mode (`/harness-stream`, no new skill)

Minimal "start once, then just keep typing" mode layered onto the existing `/harness-stream` skill — no new skill, no new `verify_all` lettered check, no version/count bump. You enter ambient mode once, then every ordinary chat message is a turn in which the AI folds any requirement into a single default pool and drains it through the pipeline until empty. No `/loop`, no pool-id, no re-invocation.

- **No-arg default pool.** Invoking `/harness-stream` with no pool-id resolves to `docs/batches/default/BATCH_PLAN.md`, auto-created from `docs/batches/_template/BATCH_PLAN.md` with an empty task table when absent. (A typo'd *named* pool still errors loudly — only the no-arg path auto-creates.)
- **Ambient flag (gated, session-scoped).** A transient, gitignored flag file `.harness/ambient.flag` gates the heartbeat — presence = ambient ON, absence = ambient OFF (normal chat). **Enter** simply by invoking `/harness-stream` with no pool-id — that action writes the flag, **no keyword to remember**. **Exit is automatic:** a `SessionStart` hook clears the flag at the start of every new session, so ambient is session-scoped and never silently carries over; delete the flag (or tell the AI to stop) to exit mid-session, and re-invoke `/harness-stream` to resume.
- **UserPromptSubmit heartbeat hook.** New `ambient-prompt.{ps1,sh}` script pair (dogfood `.harness/scripts/` + template `skills/harness-init/templates/common/.harness/scripts/`). On every user turn it checks the flag: absent → prints nothing (no-op); present → prints an ingest+drain instruction block that Claude Code injects as added turn context. The hook only instructs (Claude is the worker), never does the work, and always exits 0 (never blocks a turn). Repo root via the `.git`-ancestor walk (not depth-sensitive `$PSScriptRoot` arithmetic).
- **SessionStart reset hook.** New `ambient-reset.{ps1,sh}` script pair (dogfood + template) deletes `.harness/ambient.flag` at the start of every new session, making ambient mode **session-scoped** — so there is no "off" keyword to remember and a stale flag never silently re-enters ambient mode in a later, unrelated session. Same `.git`-walk root resolution and always-exit-0 fail-open contract as `ambient-prompt`.
- **Template settings wiring (two hooks).** `settings.json.tmpl` registers `UserPromptSubmit` → `ambient-prompt.ps1` and `SessionStart` → `ambient-reset.ps1`, both `pwsh -NoProfile` (the `-NoProfile` flag is mandatory so `$PROFILE` does not run per hook), a root `_ambient_hook` doc key documenting the non-Windows `bash` swaps, canonical `$schema`, and no doc keys inside `hooks` (J.1-clean). The dogfood `.claude/settings.json` change is **proposed, not applied** (propose-only red line, enforced both by convention and the harness safety layer) — the exact block is in the delivery doc.
- **Serial only, resume free.** One task at a time (parallel-stream stays deferred); the default pool file is the only persistent state, so a partially-drained pool resumes on the next message.
- `verify_all` F.1 pair list gains `ambient-prompt` and `ambient-reset` (existence symmetry; not a lettered check). `UserPromptSubmit` and `SessionStart` are both already in the J.1 hook-event enum. Stays 32 checks; no version/count claim changes. Docs: harness-stream SKILL.md "Ambient mode" section, README EN+zh, dev-map, AI-GUIDE, `.gitignore`.

### Docs — parallel-stream design decision (deferred, no code)

Captured a vetted, adversarially-reviewed design for parallel task dispatch on top of the v0.22.0 stream (`docs/parallel-stream-design.html`) and the decision to **defer building it**: the serial stream plus the existing intra-task partition parallelism already cover the "queue many tasks, AI schedules, I watch results" need with the best UX and the smallest maintained surface. **Model B** (same-tree partition, no branches/merges) is the on-demand path, to be built only when a genuinely-decoupled task batch makes the Amdahl math pay off; **Model A** (worktree real-parallel) is shelved (risk > benefit — gitignored-env provisioning, Windows junctions needing admin, a per-task branch/commit change to the harness flow, and merge livelock that would require a dedicated scheduler / integration-coordinator tier). Revisit triggers are recorded in the design doc and the Roadmap. Docs-only; no skill or code change; `verify_all` stays 32 checks.

## [0.23.0] - 2026-06-08

Minor release. Adds the **upgrade an old project** entry point — a new
`/harness-kit:harness-upgrade` Setup skill that brings an already-initialized but
**stale** harness project up to the current plugin layout, non-destructively,
idempotently, with a dry-run preview, then proven with a green `verify_all`. This is
the automated successor to the manual `MIGRATION.md` steps and the self-bootstrapping
complement to `migrate-scripts-layout` (it no longer requires the migration helper to
already be present in the old project).

### Why

A project initialized with an older harness-kit version is stuck on the pre-`.harness/scripts/`
layout: harness-owned scripts under top-level `scripts/`, a pre-commit hook pointing at
the old path, settings referencing the old path, and an old `verify_all`. Relocating the
scripts is not enough — a relocated-but-not-refreshed depth-sensitive script keeps its
pre-T-007 one-up repo-root derivation and silently resolves the **wrong** root (insight
L31). `/harness-upgrade` fixes the whole class in one command.

### Added — `/harness-kit:harness-upgrade` skill + `upgrade-project.{ps1,sh}` helper

- New `skills/harness-upgrade/SKILL.md` — the judgment layer (cache + version discovery
  with a `CLAUDE_PLUGIN_ROOT`-optional glob fallback chain, project-type detect-then-ASK
  via `AskUserQuestion`, plan/confirm/apply, the verify_all-HALT confirm, final report).
- New `upgrade-project.{ps1,sh}` deterministic helper (template `templates/common/.harness/scripts/`
  + dogfood mirror via `sync-self`). One self-contained transform: S1 relocate the known
  set (git-mv-preserving, SKIP-unless-`--force`), S2 **content-refresh** the depth-sensitive
  scripts from the current template (the L31 fix — relocation alone keeps stale one-up root
  derivation), S3 raw-text settings rewire (never re-serialized; preserves `_*` doc keys),
  S4 stock-vs-custom pre-commit hook (re)install (non-stock hook surfaced as a conflict,
  never overwritten), S5 regenerate `verify_all` from the type `.tmpl`. Machine-readable
  pipe-delimited stdout (`PLAN`/`RESULT`/`GAP`/`CONFLICT`/`SUMMARY`) and a 0/1/2/3 exit-code
  contract so the AI branches deterministically. Dry-run, idempotent (byte-identical → NOOP).
- **B.* preservation**: the six `verify_all.*.tmpl` files gain inert `HARNESS:B-CUSTOM:BEGIN`/`END`
  delimiter comments (literal ASCII, valid in both shells, no `{{...}}` → no D.2 change). On
  refresh, a cleanly-delimited customized block is **spliced verbatim** into the regenerated
  file; a customized block with no markers **halts** for explicit `--force`; always writes a
  `.bak`. Never silently loses a user's build/test/lint checks.

### Changed — skill registration: 12 → 13 skills

- `verify_all.{ps1,sh}` C.1 / G.1 / G.2 hardcoded skill arrays each gain `harness-upgrade`,
  and the three step descriptions update from "12 skills" to "13 skills" — in BOTH shells.
  F.1 pair list gains `upgrade-project` (existence symmetry; name-only, zero count impact).
- `sync-self.{ps1,sh}` mirror set gains the `upgrade-project` pair (E.1 enforces byte-identity).
- `README.md` / `README.zh-CN.md`: version badge `0.22.0` → `0.23.0`; `12 skills` → `13 skills`
  / `twelve` → `thirteen` / `12 个` → `13 个`; new `/harness-kit:harness-upgrade` bullet under
  **Setup skills** (NOT a 7th task shape — "six task shapes" stays six); new `0.23.0` Roadmap row.
- `AI-GUIDE.md`: `12 skills` → `13 skills`; sync-self prose `4 script pairs` → `6 script pairs`
  (now also lists migrate-scripts-layout + upgrade-project); new "Upgrade an old project" row
  in the Workflow-entry table.
- `docs/getting-started.md`: `twelve` → `thirteen` + new Setup bullet. `docs/manual-e2e-test.md`:
  `twelve`/`12 skills` → `thirteen`/`13 skills` + `harness-upgrade` added to the enumerations.
  `docs/dev-map.md`: skills inventory + helper + test registered; `4 mirrored script pairs` prose
  corrected to 6. `.harness/rules/40-locations.md`: `All 12 skills` → `All 13 skills`.

### Notes

- The skill name `harness-upgrade` appears in this CHANGELOG entry so `verify_all` G.2
  (CHANGELOG references all 13 skills) PASSes after the C.1 list grows to 13.
- **No new `verify_all` lettered check** — adding a skill is version-worthy (skill count
  12 → 13) but the check count stays **32** (a new skill needs no new `Step`; the helper pair
  is covered by E.1 byte-identity + F.1 existence). So the `(32 checks)` / `32/32` claims do
  not move. New regression `test-harness-upgrade.{ps1,sh}` exercises the helper against
  synthetic old-fixtures (relocation, root-derivation, settings rewire, hook conflict, B.*
  splice/halt, dry-run, idempotence, non-CC project, no-harness halt).
- Version stamps bumped together (`G.3`): `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, both README badges → `0.23.0`.

## [0.22.0] - 2026-06-06

Minor release. Adds the **streaming / living-pool** entry point — a new `/harness-kit:harness-stream` skill that drains a continuously-growable task pool through the full 7-stage pipeline, re-reading the pool every iteration so tasks added mid-run are planned and executed without re-invoking. Closes the "I think of new work while a run is in flight and don't want to wait for the session to end before queuing it" friction that `/harness-batch`'s frozen-plan + fail-stop design deliberately does not serve.

### Why

`/harness-batch` parses `BATCH_PLAN.md` once at start, builds a topological order, and loops over that frozen list — and stops the whole batch on the first hard failure (by design: a known list, fail-fast). That is the wrong shape for the "I only propose requirements and watch results, and I keep discovering new ones" workflow: you cannot add a task to a running batch (the anti-pattern is explicitly stop-update-re-invoke), and one task's failure halts everything. Stream is the sibling for the open-ended, keep-it-topped-up case.

### Added — `/harness-kit:harness-stream <pool-id>` skill

- New `skills/harness-stream/SKILL.md`. Drains `docs/batches/<pool-id>/BATCH_PLAN.md` (same pool format as batch, so a batch can graduate into a stream) one task at a time through `pm-orchestrator` via the `Task` tool — never bypassing pm-orchestrator, never running tasks in parallel, exactly like batch.
- **Living pool**: the loop re-reads `BATCH_PLAN.md` at the top of every iteration, so `pending` rows appended mid-run join the topological frontier on the next pass. Two input channels documented with honest timing: the **file channel** (append a row / drop an `ADD` intervention) lands on the next task boundary even in a single continuous run; the **chat channel** lands at the next iteration (queued until the current turn ends), made prompt by running under the `/loop` driver. Chat-supplied requirements are mirrored into the pool so the run stays resumable and the pool is the single source of truth.
- **Best-effort completion** (the core contrast with batch): a `FAILED`/`BLOCKED` task is marked, its dependents are marked `blocked`, and the stream **continues** to the next ready task. The hard-safety stops are preserved identically to batch — a `verify_all` FAIL after a task (poisoned baseline), an `intervention.md` STOP, or a safety-hook block all halt the stream. Resumable: fix the cause and re-invoke `/harness-stream <pool-id>` to drain only the unfinished rows.
- Stream artifacts `STREAM_LOG.md` / `STREAM_REPORT.md` live alongside the pool in `docs/batches/<pool-id>/`.

### Added — `ADD <slug> — <goal>` intervention keyword (pool-scoped)

- `.harness/rules/65-intervention.md` and the `/harness-kit:harness-intervene` skill gain an `ADD <slug> — <goal>` keyword: append/upsert a `pending` task row into the active `/harness-stream` pool, consumed by the stream loop between tasks. It is **stream-only** — a `/harness-batch` plan is frozen, so batch rejects `ADD` and points the user at `/harness-stream` (or update-the-plan-and-re-invoke); a plain single-task PM with no pool treats `ADD` as a `NOTE` and surfaces that the task was not queued. `ADD` is the only intervention keyword whose argument is a task slug rather than a stage number.

### Changed — skill registration: 11 → 12 skills

- `verify_all.{ps1,sh}` C.1 / G.1 / G.2 hardcoded skill arrays each gain `harness-stream`, and the three step descriptions update from "11 skills" to "12 skills" — in BOTH shells (F.1 symmetry).
- `README.md`: version badge `0.21.2` → `0.22.0`; `11 skills` → `12 skills`, `eleven AI skills` → `twelve AI skills`, `five task shapes` → `six task shapes`; new `/harness-kit:harness-stream` bullet under "Pipeline skills"; new `0.22.0` Roadmap row.
- `README.zh-CN.md`: symmetric Chinese edits — badge, `11 个 skills` → `12 个 skills`, `11 个 AI skill` → `12 个 AI skill`, `5 种任务形态` → `6 种任务形态`, new Chinese bullet, new `0.22.0` Roadmap row.
- `AI-GUIDE.md`: `11 skills` → `12 skills`; new "Stream (living pool)" row in the Workflow-entry table.
- `docs/manual-e2e-test.md`: `all 11 skills` → `all 12 skills` and `harness-stream` added to the enumerated skill list. `docs/dev-map.md`: `harness-stream` registered in the skills inventory.

### Notes

- The skill name `harness-stream` is included in this CHANGELOG entry so `verify_all` G.2 (CHANGELOG references all 12 skills) PASSes after the C.1 list grows to 12.
- No new `verify_all` check; the gate count stays at **32** (both shells). Stream reuses batch's per-task `verify_all` regression gate.
- Version stamps bumped together (`G.3`): `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, both README badges → `0.22.0`.

## [0.21.2] - 2026-06-06

Decoupled the prose verify_all count claims from the version: `G.4` now validates them count-only (against the live check tally), so a count-unchanged release no longer has to bump a version token in 6 docs. Version consistency stays gated by `G.3` (plugin/marketplace/README badges) + the `G.4` CHANGELOG-entry check. No check added (count stays 32).

## [0.21.1] - 2026-06-05

Patch release. Fixed the `verify_all` I.4 insight-index cap to count evidence (data) lines instead of total physical lines, identically in both shells — resolving a PS/bash cross-shell divergence (bash WARNed on the 9-line header while PS passed) and aligning I.4 with archive-task's existing rotation metric and the documented "≤30 evidence-backed lines" intent. Reconciled the baseline.json / manual-e2e-test `test_init` counts to a captured run. No check added (count stays 32).

## [0.21.0] - 2026-06-05

Minor release. Hardened the supervisor regression against version-stamp drift: removed 8 hardcoded `v0.17.1`/`30`-checks fan-out asserts from `test-supervisor.{ps1,sh}` (silently red since v0.17), and added a new standing `verify_all` **G.4** meta-check that derives the version from `plugin.json` and the check count from the live step tally and validates all doc count/version claims — so this drift class now fails at the gate instead of rotting unnoticed. verify_all check count 31 → 32.

## [0.20.0] - 2026-06-04

Minor release. **Relocates all harness-owned scripts from `scripts/` to `.harness/scripts/`** so they no longer collide with a user project's own `scripts/` directory, and ships a migration helper for existing projects. No behavioral change to the pipeline or any skill — this is a layout/packaging change with full path-reference and self-check fan-out.

### Why

When harness-kit was overlaid onto a real project, its operational scripts (`verify_all`, `harness-sync`, `guard-rm`, `archive-task`, the test drivers, …) landed in the project's top-level `scripts/` directory — the exact place a typical project keeps its OWN build/deploy/CI scripts. Two source-of-truth trees collided in one folder, making it ambiguous which `scripts/foo.sh` belonged to whom and risking accidental clobber on the next overlay. Moving every harness script under `.harness/scripts/` puts them inside the namespace the toolkit already owns (`.harness/`), leaving the project's `scripts/` untouched.

### Changed — script location: `scripts/` → `.harness/scripts/`

- All 23 tracked harness scripts (`verify_all`, `harness-sync`, `sync-self`, `install-hooks`, `archive-task`, `guard-rm`, `test-init`, `test-real-project`, `test-supervisor`, `test-verify-i6`, `test-guard-rm` — each `.ps1` + `.sh` — plus `baseline.json`) `git mv`'d from `scripts/` to `.harness/scripts/`. The distribution templates (`templates/common/.harness/scripts/` + the 3 stack `verify_all.{ps1,sh}.tmpl` overlays) moved in the same shape.
- Every live path constant / self-check / sync mapping retargeted in BOTH shells, including each script's repo-root derivation (now two directory levels up, not one). Hook wiring updated in the `settings.json.tmpl` and proposed for the propose-only dogfood `.claude/settings.json`. `verify_all` self-checks (A.1 / E.1 / E.2 / F.1 / F.2 / I.6 exempt list / history-append path) updated in both shells.
- Contributor docs (`AI-GUIDE.md`, `README.md`, `README.zh-CN.md`, `CONTRIBUTING.md`, `docs/getting-started.md`, `docs/concepts.md`, `docs/manual-e2e-test.md`, `docs/dev-map.md`, all `.harness/rules/*.md`, all `skills/**/SKILL.md`) swept to the new path, and `MIGRATION.md` gained a top "Upgrading to the `.harness/scripts/` layout" section.

### Added — `migrate-scripts-layout.{ps1,sh}` helper

- New `.harness/scripts/migrate-scripts-layout.{ps1,sh}` (+ template copy). Idempotent migration for existing projects: moves the known harness scripts from `scripts/` to `.harness/scripts/`, rewrites `scripts/harness-sync.` / `scripts/guard-rm.` references in `.claude/settings.json` (and its `_doc_sync_hook` doc string), writes a timestamped `.bak`, supports `-DryRun` / `-Force`, and is a no-op (no `.bak`, no write) when the project is already migrated. Does NOT touch a project's own non-harness `scripts/` files. Regression-covered by the `test-init` migrate fixture in both shells.

### Changed — Version stamps: 0.19.0 → 0.20.0

- `.claude-plugin/plugin.json`: `"version": "0.19.0"` → `"version": "0.20.0"`.
- `.claude-plugin/marketplace.json`: `plugins[0].version` `"0.19.0"` → `"0.20.0"`.
- `README.md`: version badge `0.19.0` → `0.20.0`; new `0.20.0` Roadmap row.
- `README.zh-CN.md`: version badge `0.19.0` → `0.20.0`; new `0.20.0` Roadmap row.

### Notes

- No new `verify_all` check; the gate count stays at **31** (both shells). The relocation is enforced by the existing F.1 / F.2 pair-existence + wiring checks now pointing at `.harness/scripts/`.
- No skill added or removed; the 11-skill set (`harness`, `harness-init`, `harness-adopt`, `harness-verify`, `harness-status`, `harness-plan`, `harness-explore`, `harness-goal`, `harness-intervene`, `harness-supervise`, `harness-batch`) is unchanged.
- The dogfood `.claude/settings.json` hook paths are proposed-only (CLAUDE.md red line); the user applies the path diff (or runs `migrate-scripts-layout`) so the live Stop / PreToolUse hooks resolve correctly.

## [0.19.0] - 2026-05-23

Minor release. Adds the **batch-mode** entry point — a new `/harness-kit:harness-batch` skill that runs a list of tasks through the full 7-stage pipeline sequentially, each task in its own sub-agent context, stopping only on strong failure signals. Closes the "user has T-01…T-NN and must invoke `/harness` N times by hand" friction documented in the v0.18.x backlog.

### Why

Before v0.19.0, the only way to run multiple tasks (from a `/harness-plan` decomposition, an accumulated bug list, a post-checkup `verify_all` WARN sweep, or an external Linear / Jira import) was to type `/harness` once per task. Each invocation re-loaded `AI-GUIDE.md`, re-read `.harness/insight-index.md`, re-checked `intervention.md` — repeated user-presence cost, repeated cross-task setup waste, and a real risk of context bloat if N tasks ran back-to-back in a single session without sub-agent isolation.

The user explicitly chose "fully autonomous, stop only on strong signals" over per-task supervision; rejected "new program-manager agent on top of pm-orchestrator" (方案 B, would have required 3-level Task-tool nesting); rejected "extend `/harness` to take multiple tasks" (方案 C, would have bloated pm-orchestrator's single responsibility). The chosen approach (方案 A) is a thin skill that sits **strictly above** `pm-orchestrator` and dispatches each task into its own `Task` sub-agent — so the batch orchestrator's own context grows by ~one summary line per task, not by N × full stage docs.

### Added — `/harness-kit:harness-batch` skill

- New `skills/harness-batch/SKILL.md` (~180 lines). Frontmatter declares `Task` in `allowed-tools` (mandatory for sub-agent dispatch). Body covers: when to invoke, when not to, required input, the 7-step procedure (argument validation → pre-flight `verify_all` baseline + `insight-index` read + intervention check → parse `BATCH_PLAN.md` → per-task loop → strong-signal stop conditions → soft-signal NOTE/SKIP handling → terminal `BATCH_REPORT.md`), hard rules, anti-patterns, cost note.
- Strong-signal stop policy: any of `verify_all` FAIL, dispatched `pm-orchestrator` returns `FAILED`, 3 same-stage rollbacks reported, `.harness/intervention.md` STOP between tasks, safety-hook block. On stop, the skill writes `BATCH_REPORT.md` with stop reason and per-task status.
- Soft-signal policy: `NOTE` attaches to the next task's dispatch prompt; `SKIP <task-id>` skips that task; `REDIRECT` is rejected (REDIRECT is for stages, not tasks).
- Resume semantics: `Status: done` skips; otherwise re-evaluate by checking for `07_DELIVERY.md` with `DELIVERED` verdict (primary) or `Final verify_all result: PASS` line (secondary, format-tolerance per Gate Review finding F-7).

### Added — `docs/batches/` directory

- `docs/batches/README.md` — lifecycle explainer (≤80 lines) covering folder layout, the `BATCH_PLAN.md` / `BATCH_LOG.md` / `BATCH_REPORT.md` triple, a worked 3-task example, and a link back to the skill for the full procedure.
- `docs/batches/_template/BATCH_PLAN.md` — copy-paste template. Users copy the folder to `docs/batches/<their-batch-id>/`, fill in the task table (columns `ID | Slug | Goal | Mode | Depends on | Status`), and invoke `/harness-kit:harness-batch <their-batch-id>`.

### Added — task folder

- `docs/features/harness-batch-skill/` holds the 7 stage docs for T-006 (01_REQUIREMENT_ANALYSIS.md through 07_DELIVERY.md). Archived to `docs/features/_archived/harness-batch-skill/` at delivery via `scripts/archive-task`.

### Changed — `verify_all` skill-count assertions: 10 → 11

- `scripts/verify_all.sh` C.1 / G.1 / G.2 hardcoded skill arrays each grow by one entry (`harness-batch`); the corresponding step descriptions update from "All 10 skills" / "all 10 skills" to "All 11 skills" / "all 11 skills".
- `scripts/verify_all.ps1` C.1 / G.1 / G.2 mirror the bash edits (per F.1 script-symmetry rule). All six locations (3 arrays × 2 shells) updated in the same change.
- No new `verify_all` check added; check count stays at 31. The skill count delta is enforced by the existing C.1 / G.1 / G.2 assertions.

### Changed — Version stamps: 0.18.2 → 0.19.0

- `.claude-plugin/plugin.json`: `"version": "0.18.2"` → `"version": "0.19.0"`.
- `.claude-plugin/marketplace.json`: `plugins[0].version` `"0.18.2"` → `"0.19.0"`.
- `README.md`: version badge `0.18.2` → `0.19.0`; skill-count phrasing `10 skills` → `11 skills`, `ten AI skills` → `eleven AI skills`, `four task shapes` → `five task shapes`; new `/harness-kit:harness-batch` bullet under "Pipeline skills"; new `0.19.0` Roadmap row; `0.19+` planned row → `0.20+`.
- `README.zh-CN.md`: version badge `0.18.2` → `0.19.0`; `10 个 skills` → `11 个 skills` / `10 个 AI skill` → `11 个 AI skill`; `4 种任务形态` → `5 种任务形态`; new Chinese bullet for `/harness-kit:harness-batch`; new `0.19.0` Roadmap row; `0.19+` planned row → `0.20+`.
- `AI-GUIDE.md`: new row in the Workflow-entry table for `/harness-batch` (English + 中文 triggers).

### Notes

- The skill name `harness-batch` is included in this CHANGELOG entry so `verify_all` G.2 (CHANGELOG references all 11 skills) PASSes after the C.1 list grows to 11.
- No agent-contract change (no new `.harness/agents/*.md`); `pm-orchestrator` is reused unchanged.
- No template changes (`templates/common/` not touched); skills ship via the Claude Code Plugin manifest `plugin.json` `"skills": "./skills/"` field, so the new skill folder is auto-discovered by the plugin loader on install.
- No new `.harness/rules/` fragment; the skill operates entirely on existing patterns (`05-insight-index.md`, `65-intervention.md`, `archive-task`).
- Sequential only in v0.19.0. Parallel batch dispatch is deferred to v0.20+ once sequential stability is proven against real batches.

## [0.18.2] - 2026-05-23

Patch release. Fixes a recurring class of `.claude/settings.json` schema-validation bugs (the second one in two consecutive releases) and adds a `verify_all` gate so the class cannot recur silently.

### Why

`.claude/settings.json` broke editor-side schema validation twice in two consecutive minor releases. Both bugs shared the same shape — a tiny textual edit passed `JSON.parse` but failed schema validation, and no `verify_all` check existed to catch it. The writer's editor showed only a subtle squiggle; the file loaded at runtime fine for the writer's session; the next contributor inherited a broken file with no signal.

- **v0.17.2** — doc keys (`_doc_sync_hook`, `_guard_hook`) lived inside `hooks`, but the upstream schema declares `hooks` as `additionalProperties: false`. Fix moved them to root (`additionalProperties: true`).
- **v0.18.2** — `$schema` URL omitted the `.json` suffix (`https://json.schemastore.org/claude-code-settings`). The non-suffix form 301-redirects to a URL serving `application/octet-stream`, which VS Code / JetBrains silently refuse to load. The whole file flagged invalid even though JSON parsed.

### Fixed — `$schema` URL canonical form

- **`.claude/settings.json`** (dogfood): `$schema` `https://json.schemastore.org/claude-code-settings` → `https://json.schemastore.org/claude-code-settings.json`. Canonical URL serves `application/json; charset=utf-8` per the v0.17.2 verification methodology.
- **`skills/harness-init/templates/common/.claude/settings.json.tmpl`** (every project from `/harness-init` and `/harness-adopt`): same one-character relocation. Propagates to every new project on next install.

### Added — `verify_all` J.1 settings.json schema integrity (PS + bash twin)

- New check **J.1** parses both `.claude/settings.json` and the `.tmpl` (no `jq` / `python3` dependency — pure shell + grep so it runs on Git-for-Windows MSYS), and FAILs when:
  1. The file does not parse as JSON.
  2. `$schema` is present but not exactly the canonical `https://json.schemastore.org/claude-code-settings.json`.
  3. Any key inside the top-level `hooks` object is not in the upstream hook event enum (29 valid events as of 2026-05-23: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, … — full list in `scripts/verify_all.ps1` `$validHookEvents` and `scripts/verify_all.sh` `j1_valid_hook_events`, kept in lockstep).
- Catches **both** historical bugs at the gate: the v0.17.2 wrong-key-placement class FAILs on rule (3); the v0.18.2 wrong-URL-form class FAILs on rule (2). Future bugs of either shape will be caught before commit.

### Added — `.harness/rules/80-settings-schema.md`

- New rule fragment documenting the editing contract: **before** editing `.claude/settings.json` or its `.tmpl`, consult the upstream schema via the `context7` MCP tool (or `WebFetch` against `https://www.schemastore.org/claude-code-settings.json` as fallback) — never recall the schema shape from memory or training data. Triggered on edits to either file.
- Wired into `AI-GUIDE.md` rule index.

### Changed — `verify_all` check count: 30 → 31

- `scripts/baseline.json`: `verify_all_checks` 30 → 31, `last_verify` → `2026-05-23`.
- Live freshness stamps bumped from `at v0.18.1` / `at v0.18.0` → `at v0.18.2`: `AI-GUIDE.md` (2 places), `docs/dev-map.md`, `docs/manual-e2e-test.md`, `docs/walkthrough.html` sample output.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.18.1` → `0.18.2`.
- `README.md` / `README.zh-CN.md`: version badge `0.18.1` → `0.18.2`; verify_all badge `30/30` → `31/31`; new `0.18.2` Roadmap row.

### Notes

- No functional change to existing hooks or permissions. Both settings.json files remain byte-equivalent in their `hooks` / `permissions` blocks; only `$schema` value changed.
- Insight added to `.harness/insight-index.md` recording the recurrence pattern (class: "small edit passes JSON-parse but breaks schema validation; verify_all gate must validate URL + key positions, not just parse").

## [0.18.1] - 2026-05-23

Patch release. Closes the two non-blocking observations left by v0.18.0 (the I.6 gap-tolerant retired-claim guard): (a) the PS-side `test-verify-i6` structural lockstep was weaker than the bash side — it only checked entry count + entry #10's `exclude=@('.claude/')` clause, so a typo in any of entries #1 / #3–9 / #11–13's `reason` / `exclude` / `gap` fields in `scripts/verify_all.ps1` would slip past PS lockstep; (b) AC-8 (`CHANGELOG.md` file-exempt + `docs/features/_archived/` dir-exempt preserved) had no permanent corpus fixture — the v0.18.0 QA validated it via an inline injection probe that did not survive into the regression set. This release adds the missing coverage in both shells; no `verify_all` behavior change.

### Changed — `scripts/test-verify-i6.{ps1,sh}` structural lockstep is now symmetric and full-field

- **Full 2×2 lockstep matrix.** Each driver now does **verbatim per-entry × 4-field (`anchors` / `reason` / `exclude` / `gap`) comparison** of BOTH `verify_all.sh`'s `i6_banned` AND `verify_all.ps1`'s `$banned` against the driver's own canonical copy. No cell of the (driver × live) matrix is "count-only" or "entry #10 only" any longer. New helpers in each shell: a single `<empty>` sentinel (`$script:I6_EMPTY` / `I6_EMPTY`), `Format-I6Field` / `i6_format_field` for empty-value normalization across the bash record `||` form and the PS `$null` / `@()` form, and `Test-I6FieldEq` / `i6_field_eq` as the **only** new comparator (uses `-ceq` in PS / `[[ == ]]` literal in bash — insight L7/L17/L20/L23 hardening).
- **New parser projections.** `Get-ShI6BannedRecords` (PS) walks `verify_all.sh`'s `i6_banned=(...)` block in pure PS text (no `bash` shell-out) and decodes `\`` → `` ` `` for entries #2 / #6 / #8 (insight L19 backtick hazard); `extract_ps_banned_records` (bash) walks `verify_all.ps1`'s `$banned = @(...)` hashtable array with sed anchored on the literal keywords (`anchors = @(`, `reason = `, `exclude = @(`, `gap = `), failing closed (length ≠ 4) on a future line-wrap.
- **`I6ExpectedEntryCount` named constant.** Single source of truth for "13 entries" per driver (`$script:I6ExpectedEntryCount` / `i6_expected_entry_count`). Bumping to 14 in a future task = 4 edits (live PS + live bash + each driver's canonical) instead of 10+ hand-edits.
- **Exempt-FILE + exempt-DIR lockstep is now element-wise.** Each driver hard-codes a canonical `$i6ExemptFiles` / `i6_exempt_files` array (7 paths: `CHANGELOG.md`, `architecture.html`, `docs/walkthrough.html`, `scripts/verify_all.{ps1,sh}`, `scripts/test-verify-i6.{ps1,sh}`) and asserts `verify_all.{ps1,sh}`'s actual `$exempt` / `i6_exempt_files` arrays match element-by-element. The exempt-dir lockstep was upgraded from "contains `docs/features/`" to full element-wise equality against `($i6ExemptDirs = "docs/features/", "参考/")`. The old "entry #10 carries `exclude=@('.claude/')`" bespoke row is removed in both shells — subsumed by the new per-field comparison.

### Added — AC-8 permanent corpus fixture (file-level + dir-level exemption)

- New `Test-I6FileExempt` (PS, uses `-ccontains` — mandatory case-sensitive variant) / `i6_file_exempt` (bash, uses `[[ == ]]` literal) predicate symmetric to the existing `Test-I6DirExempt` / `i6_dir_exempt`. New combined predicate `Test-I6Exempt` / `i6_exempt` mirrors the live `verify_all`'s skip order (file-exempt OR dir-exempt → skip).
- New Assertion 7 block in each driver: 7 file-exempt positive assertions (one per canonical exempt path), 3 file-exempt negative assertions (`README.md`, `docs/concepts.md`, `scripts/harness-sync.sh`), 1 combined-exempt assertion on the synthetic dir-exempt path `docs/features/some-task/03_GATE_REVIEW.md`, 7 combined-exempt assertions on each canonical exempt-file path, plus 1 AC-14 negative-regression assertion on a fresh physical fixture `fx-ac14-nonexempt.md` (banned content at a non-exempt path) that MUST hit — guards against a future bug that makes the exemption predicate return `true` for all paths.

### Changed — Assertion counts

- `scripts/test-verify-i6.ps1`: **35 → 56** assertions (`+21`).
- `scripts/test-verify-i6.sh`:  **34 → 56** assertions (`+22`); PS == bash now (empirical-equality contract — see `docs/features/_archived/i6-test-hardening/02_SOLUTION_DESIGN.md` §9). Old PS-vs-bash split-count delta of 1 closed.
- `scripts/baseline.json` `test_verify_i6_ps_assertions` and `test_verify_i6_bash_assertions` both bumped to 56.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.18.0` → `0.18.1`.
- `README.md` / `README.zh-CN.md`: version badge `0.18.0` → `0.18.1`; new `0.18.1` Roadmap row.

### Notes

- `verify_all` unchanged at 30 checks — a regression-driver-only release, no `verify_all` byte change. `scripts/verify_all.{ps1,sh}` are byte-identical to v0.18.0 (mutation cycle in QA reverted cleanly).
- `AI-GUIDE.md` / `docs/dev-map.md` freshness stamps intentionally left at `at v0.18.0` per the task's design AC-19 — they describe `verify_all`'s 30-check gate and the gap-tolerant matcher, both unchanged; bumping the stamp would falsely imply a substantive change.
- One known portability limitation (deferred to a future maintenance pass): `scripts/test-verify-i6.sh:499-500` uses bash 4.3+ `local -n` namerefs; works on Git-bash (Windows ≥5.x) and modern Linux ≥4.4 but would error on macOS default `/usr/bin/env bash` 3.2. Not in T-005 scope; recorded as Code Review's only MINOR finding.
- `test-init` (227 PS / 191 bash-no-python3), `test-real-project` (82/82), `test-supervisor` (57 PS / 53 bash-no-python3) all unaffected — no test asserts on the I.6 regression-driver internals.

## [0.18.0] - 2026-05-23

Minor release. Upgrades the `verify_all` **I.6 retired-claim guard** from literal-substring matching to a **gap-tolerant ordered-anchor scan**. The v0.15.1 / v0.17.4 sweeps repeatedly found that a retired claim survives by being *re-phrased* — the same wrong idea with a word inserted between the banned tokens (`composed` … `into` … `` `CLAUDE.md` ``). A literal-substring guard cannot catch that. I.6 now matches on an ordered list of plain-text anchors within a bounded gap, so paraphrased resurgences are caught too. No new `verify_all` check — the count stays **30**.

### Changed — I.6 is now a gap-tolerant ordered-anchor scan

- **`scripts/verify_all.ps1`** / **`scripts/verify_all.sh`** — the I.6 block is rewritten in both shells. Each banned entry is now an ordered list of literal **anchor** tokens; a file hits when all anchors appear in order on one line within a bounded **gap** (default 40 chars, per-entry overridable). Every entry may carry literal **`exclude`** tokens — if any appears anywhere on the matched *line* (line-scoped), the match is rejected, so accurate negated prose (`rules are NOT composed into CLAUDE.md`) does not FAIL. The 13-entry banned list is migrated 1:1 — same reasons, only the matching shape changes. Anchors stay plain text; the script escapes every regex metacharacter, so authoring a new entry is still a one-line edit.
- **I.6 exempt-dir widened** — from `docs/features/_archived/` to the whole **`docs/features/`** subtree, in both scripts. Per-task stage docs must quote retired claims to design and review the guard; widening the exemption removes a fragile commit-ordering dependency (a task's own stage docs would otherwise fail its own gate).
- The bash line-scoped exclude uses `shopt -s nocasematch` + `[[ == *glob* ]]` (a case-insensitive literal substring test) rather than `grep -F -i` — the GNU grep 3.0 shipped with Git-for-Windows MSYS aborts (SIGABRT) on `-F -i` combined. Behaviorally identical to the PowerShell `String.IndexOf(...,OrdinalIgnoreCase)` twin.

### Added — `scripts/test-verify-i6.{ps1,sh}`

- New cross-shell regression pair for the I.6 matcher, modeled on `test-supervisor.{ps1,sh}`. Runs a fixture corpus (one file per banned entry plus gap-boundary, negation, historical-narration, metacharacter/Unicode, multiline, and empty-file cases) in an isolated temp dir, and asserts: per-fixture hit/no-hit behavior, cross-shell parity, structural lockstep against the live `verify_all` 13-entry list, no-stderr on metacharacter fixtures, gap-boundary, and the F-1/F-2/F-4/Rev-4 regression cases. Repo-bespoke — `sync-self` does not mirror it.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.17.4` → `0.18.0`.
- `README.md` / `README.zh-CN.md`: version badge `0.17.4` → `0.18.0`; new `0.18.0` Roadmap row.
- `AI-GUIDE.md`, `docs/dev-map.md`, `.harness/rules/40-locations.md`: I.6 description updated to "gap-tolerant"; `at v0.17.4` freshness stamps → `at v0.18.0` (check count unchanged at 30).

### Notes

- `verify_all` unchanged at 30 checks — a matcher upgrade, no check added or removed.
- `test-init` / `test-real-project` / `test-supervisor` unaffected — no test asserts on the I.6 matcher internals.

## [0.17.4] - 2026-05-22

Patch release. A documentation-freshness sweep: the v0.10 progressive-disclosure rework turned `CLAUDE.md` / `.github/copilot-instructions.md` into static stubs and narrowed `harness-sync` to copy only `.harness/agents/` + `.harness/skills/` → `.claude/`. The v0.15.1 cleanup caught most of the resulting drift, but a residual set of live docs and inline comments still described the pre-v0.10 behavior. v0.17.3 fixed the same mislabel class in the bootstrap *stubs*; this release finishes the job in the *rule templates, scripts, and prose docs*. No feature change, no `verify_all` check added or removed — stays at 30.

### Fixed — residual pre-v0.10 wording in live docs and comments

The retired claim took three shapes: (a) `harness-sync` described as flowing edits into `CLAUDE.md` / `copilot-instructions.md`; (b) `CLAUDE.md` (and the rule-fragment banner) labeled "generated"; (c) "edit a rule, then re-run sync" — since v0.10 rules take effect by reference via `AI-GUIDE.md`, no sync step. None of these tripped the `verify_all` I.6 literal-substring guard (the surviving phrasings sat between the banned literals), which is why they outlived v0.15.1.

- **`skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl`** + **`.../i18n/zh/common/.harness/rules/00-core.md.tmpl`** — the rendered `00-core.md` is itself a source rule fragment, but its header banner claimed the file was "generated from `.harness/rules/*.md`". Banner rewritten to describe a source-of-truth fragment. Red-line bullet 7 ("edit `.harness/`, not `.claude/` or `CLAUDE.md` — the latter two are generated") re-split to match the v0.17.3 bootstrap wording: `.claude/agents/`+`skills/` are synced, `CLAUDE.md` is a static stub, `.claude/settings.json` is live hand-editable config. "What lives where" table corrected. Language-change instruction no longer tells the user to run `harness-sync`.
- **`skills/harness-init/templates/common/.claude/settings.json.tmpl`** — `_comment` no longer claims the Stop hook flows `.harness/` edits to `CLAUDE.md`; now states `.harness/agents/` + `.harness/skills/` → `.claude/`.
- **`skills/harness-init/templates/fullstack/.harness/agents/dev-frontend.md.tmpl`** — "`CLAUDE.md` (generated)" → "`CLAUDE.md` (and the `AI-GUIDE.md` it points to)".
- **`skills/harness-init/SKILL.md`**, **`skills/harness-adopt/SKILL.md`** — dropped the "(generated)" label on `CLAUDE.md`; init "Next steps" no longer tells the user to re-sync after rule edits.
- **`README.md`** / **`README.zh-CN.md`** — "In ~30 seconds" file list, the repository-layout box, and the design-principles list all corrected: `CLAUDE.md` / `copilot-instructions.md` are bootstrap stubs, `.claude/agents/`+`skills/` are the synced bindings. (The English layout box still said "Generated; do not edit" — the Chinese one had already been fixed; they now match.) "Dogfooded" paragraph no longer claims `.harness/rules/` produces this repo's `CLAUDE.md`.
- **`docs/getting-started.md`**, **`CONTRIBUTING.md`** — repo-layout comment and the Layer-2 description corrected to the agents+skills-only sync scope.
- **`scripts/verify_all.ps1`** / **`scripts/verify_all.sh`** — the I.6 exemption *comment* drifted from the actual exempt array (`.ps1` named `MIGRATION.md` as exempt though it is not; `.sh` omitted `architecture.html` / `walkthrough.html` though they are). Comments reconciled with code — no behavior change.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.17.3` → `0.17.4`.
- `README.md` / `README.zh-CN.md`: version badge `0.17.3` → `0.17.4`; new `0.17.4` Roadmap row.
- `AI-GUIDE.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `architecture.html`: `at v0.17.3` freshness stamps → `at v0.17.4` (counts unchanged).

### Notes

- `verify_all` unchanged at 30 checks — a doc-wording fix, no check added or removed. The I.6 exemption array itself was not changed (only its comment); `MIGRATION.md` remains scanned and still passes (its old/new comparisons phrase around the banned literals).
- `test-init` (227 PS / 191 Bash-no-python3), `test-real-project` (82/82), `test-supervisor` (57 PS / 53 Bash-no-python3) all unaffected — no test asserts on the corrected prose.
- The dogfood `.claude/settings.json` `_doc_sync_hook` string carried the same stale wording. It is red-line-protected (self-modification classifier + `CLAUDE.md` red line), so it is corrected by hand outside the pipeline.

## [0.17.3] - 2026-05-22

Patch release. Completes the v0.17.2 `settings.json`-correctness theme by fixing the bootstrap red line that *mislabeled* `.claude/`. The `CLAUDE.md` / `.github/copilot-instructions.md` red line called `.claude/` a "generated or static" file — but `.claude/settings.json` is neither: it is the agent's live, hand-maintained startup config (permissions + hooks). That wrong category label is exactly what made the v0.17.2 fix awkward to reason about. No feature change, no `verify_all` check added or removed — stays at 30.

### Fixed — bootstrap red line mislabeled `.claude/` as "generated or static"

`.claude/` holds two distinct things, neither of which is "static": `settings.json` is the agent's *live* startup config (changes need human review — the self-modification classifier guards it), and `agents/`+`skills/` are *sync-generated* copies of `.harness/` (edits belong in the `.harness/` source). The single red-line bullet was split in two so each protected path carries its real rationale; `CLAUDE.md` and `.github/copilot-instructions.md` keep the accurate "static stub" label.

- **`skills/harness-init/templates/common/CLAUDE.md.tmpl`**, **`.../common/.github/copilot-instructions.md.tmpl`**, **`.../i18n/zh/common/CLAUDE.md.tmpl`**, **`.../i18n/zh/common/.github/copilot-instructions.md.tmpl`** — red-line bullet split: one bullet for `.claude/` (live config + sync-generated, with the correct "propose, don't hand-edit" / "edit the `.harness/` source" rationale), one for the genuine static stubs. Propagates to every newly created or adopted project via `/harness-init` and `/harness-adopt`.
- **`CLAUDE.md`**, **`.github/copilot-instructions.md`** (this repo's dogfood files) — same split. Applied by hand: both are red-line-protected against AI edits, so they cannot be auto-fixed by the pipeline.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.17.2` → `0.17.3`.
- `README.md` / `README.zh-CN.md`: version badge `0.17.2` → `0.17.3`; new `0.17.3` Roadmap row.
- `AI-GUIDE.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `architecture.html`: `at v0.17.2` freshness stamps → `at v0.17.3` (counts unchanged).

### Notes

- `verify_all` unchanged at 30 checks — a doc-wording fix, no check added or removed.
- `test-init` (227 PS / 191 Bash-no-python3), `test-real-project` (82/82), `test-supervisor` (57 PS / 53 Bash-no-python3) all unaffected — no test asserts on the bootstrap red-line text.

## [0.17.2] - 2026-05-22

Patch release. Fixes a JSON-schema-validity bug in the generated `.claude/settings.json`: two documentation keys were placed *inside* the `hooks` object, which the official Claude Code settings schema declares `additionalProperties: false`. No feature change, no `verify_all` check added or removed — stays at 30. No runtime behavior change either — Claude Code tolerates unknown keys at load time, so the bug surfaced only as editor / schema-validator errors (red squiggles in VS Code).

### Fixed — `.claude/settings.json` failed schema validation (doc keys inside the strict `hooks` object)

The official schema (`json.schemastore.org/claude-code-settings`, verified via context7/WebFetch) declares the **root** object `additionalProperties: true` but the **`hooks`** object `additionalProperties: false` — `hooks` accepts *only* real hook-event names (`Stop`, `PreToolUse`, …). harness-kit embedded two documentation strings, `_doc_sync_hook` and `_guard_hook`, as keys *inside* `hooks`, so every generated `settings.json` failed validation.

- **`skills/harness-init/templates/common/.claude/settings.json.tmpl`** — `_doc_sync_hook` and `_guard_hook` relocated from inside `hooks` to the root object, where `_*`-prefixed documentation keys are schema-valid. The hook entries themselves (`Stop`, `PreToolUse`) are byte-unchanged. This is the root cause: the single template is consumed by both `/harness-init` and `/harness-adopt`, so the fix propagates to every newly created or adopted project.
- **`.claude/settings.json`** (this repo's dogfood file) — same relocation. Applied by hand: the file is guarded against AI edits by the self-modification classifier and the `CLAUDE.md` red line, so it cannot be auto-fixed by the pipeline.

`test-init`'s settings.json assertions (JSON-parse, `hooks.PreToolUse[0].matcher == "Bash"`, guard-rm command) are unaffected — none of them touch the relocated keys.

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.17.1` → `0.17.2` (G.3 keeps these in sync with the README badges).
- `README.md` / `README.zh-CN.md`: version badge `0.17.1` → `0.17.2`; new `0.17.2` Roadmap row.
- `AI-GUIDE.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `architecture.html`: `at v0.17.1` freshness stamps → `at v0.17.2` (counts unchanged).
- `scripts/baseline.json`: `last_verify` → `2026-05-22`. `verify_all_checks` unchanged at 30.

### Notes on regression surface

- `verify_all` unchanged at 30 checks — the fix is a JSON-key relocation, no check added or removed.
- `test-init` unchanged at 227 PS / 191 Bash-no-python3; `test-real-project` 82/82; `test-supervisor` 57 PS / 53 Bash-no-python3.

## [0.17.1] - 2026-05-21

Patch release. Sweeps the two MINOR adversarial findings that v0.17.0 explicitly deferred (see v0.17.0 "Known limitations — deferred to v0.17.1"). No feature change, no new `verify_all` check, no agent-contract behavior change — `verify_all` stays at 30 checks. Reproducers: `docs/features/_archived/supervisor-agent/06_TEST_REPORT.md` ADV-8 (BUG-2) and ADV-7 (BUG-3).

### Fixed — BUG-2: I.7 active-row slug match was substring-based (both shells)

The `verify_all` I.7 guard decided whether a `SUPERVISION_REPORT.md`'s slug was an *active* task by substring-matching the slug against `docs/tasks.md`. A slug `foo` was therefore matched by an Active row for `foo-extra` — a latent false-positive WARN for any adopter whose task slugs share a prefix (`auth` / `auth-v2`).

- **`scripts/verify_all.ps1`** I.7 — active-row filter changed from `$_ -match [regex]::Escape($slug)` to a column-anchored `$_ -match "\|\s*$([regex]::Escape($slug))\s*\|"`. The slug must now occupy a full pipe-delimited table cell.
- **`scripts/verify_all.sh`** I.7 — active-row filter changed from `grep -F -- "$slug"` to `grep -E -- "\|[[:space:]]*${slug}[[:space:]]*\|"`. Cross-shell symmetric with the PS twin.
- **`scripts/test-supervisor.{ps1,sh}`** — new `BUG-2` regression block (3 assertions per shell): slug `foo` does NOT match a `foo-extra` row, DOES match its own column-anchored row, and does NOT match a slug substring inside a path cell. Counts: PS 54 → 57, Bash-no-python3 50 → 53.

### Fixed — BUG-3: `supervisor.md` boundary-table doc-drift on cross-task N=0

`.harness/agents/supervisor.md` said *"Cross-task `N=0` or `N>archived-count` → Clamp to `[1, archived-count]`"* — when `archived-count` is 0 that clamp is mathematically undefined, and it disagreed with the authoritative behavior in `skills/harness-supervise/SKILL.md:129` (*one-line `Verdict: HEALTHY` + INFO "no archived tasks"*). No runtime impact (the SKILL.md path is the one that executes); doc-only drift.

- **`.harness/agents/supervisor.md`** (+ byte-identical `skills/harness-init/templates/common/.harness/agents/supervisor.md` mirror) — the one ambiguous row is split into two: `N=0` / `archived-count == 0` → one-line `Verdict: HEALTHY` + INFO "no archived tasks" (consistent with the skill's boundary table); `N > archived-count` (with `archived-count >= 1`) → clamp `N` down to `archived-count` and INFO-log it. supervisor.md: 255 → 256 lines (still well under the 300 cap).
- `.claude/agents/supervisor.md` updated via `harness-sync` (Layer-2 binding).

### Changed — Version stamps

- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`: `0.17.0` → `0.17.1` (G.3 keeps these in sync with the README badges).
- `README.md` / `README.zh-CN.md`: version badge `0.17.0` → `0.17.1`; new `0.17.1` Roadmap row.
- `AI-GUIDE.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `architecture.html`: `at v0.17.0` freshness stamps → `at v0.17.1`; test-supervisor assertion counts `54/50` → `57/53`.
- `scripts/baseline.json`: `test_supervisor_ps_assertions` 54 → 57, `test_supervisor_bash_no_python3_assertions` 50 → 53, `last_verify` → `2026-05-21`. `verify_all_checks` unchanged at 30.

### Notes on regression surface

- `verify_all` unchanged at 30 checks (I.7 internals tightened, no check added or removed). On a clean repo I.7 stays vacuously PASS — no `SUPERVISION_REPORT.md` files exist.
- `test-init` unchanged at 227 PS / 191 Bash-no-python3.
- `test-real-project` unchanged at 82/82.
- `test-supervisor` 54 → 57 PS / 50 → 53 Bash-no-python3 (BUG-2 regression block).

## [0.17.0] - 2026-05-19

The first **observer-only** release. A new auxiliary agent (`.harness/agents/supervisor.md`) and a manually-invoked skill (`/harness-kit:harness-supervise`) read an in-flight or archived 7-stage task folder, detect a fixed catalog of anti-patterns, and emit a single `SUPERVISION_REPORT.md` for human review. The supervisor is **not** part of the canonical 7-stage routing; it is purely informational and never modifies upstream documents, dispatches sub-agents, or routes the pipeline. The PM Orchestrator contract is unchanged — running `/harness` end-to-end produces stage docs byte-identical to v0.16.0 whether the supervisor is invoked or not (AC-10).

### Added — Supervisor agent + `/harness-supervise` skill (manual-invocation only)

- **`.harness/agents/supervisor.md`** — new auxiliary agent contract (≤300 lines, currently 255). Declares the severity scheme (`INFO`/`WARN`/`ALERT`), the five anti-pattern detectors with explicit thresholds (AP-1 same-stage rollback rate, AP-1b cross-stage rollback tally, AP-2 stage-doc thinness, AP-3 missing intervention checks, AP-4 missing archive call), the fixed report schema (last non-blank line MUST match `^Verdict: (HEALTHY|WATCH|INTERVENE)$`), and the read-only / write-one-file constraints. `tools: Read, Write, Glob, Grep` — `Edit`, `Bash`, `PowerShell`, `Task`, `AskUserQuestion` are physically excluded per NFR-4. Byte-identical mirror at `skills/harness-init/templates/common/.harness/agents/supervisor.md` (covered by `sync-self`'s `dir-of-md` mapping; no script edit needed).
- **`skills/harness-supervise/SKILL.md`** — new skill. Three argument shapes: `<task-slug>` (single task), `--recent <N>` (last N archived tasks), `--all` (every archived task). `allowed-tools: Read, Write, Glob, Grep` (NFR-4 enforced). Includes the `HARNESS_SUPERVISOR_MOCK` env-var pattern for CI / dry-run, the report-write protocol (one Write call + re-Read verification per insight-index L10), and the boundary conditions (missing task folder, malformed PM_LOG, mock-fallback, doc-size cap).
- **`skills/harness-supervise/fixtures/sample-task/`** — committed HEALTHY-baseline fixture (PM_LOG with zero rollbacks, 6 stage-to-stage intervention checks, all seven stage docs above AP-2 minimums). Used by `test-supervisor` AC-4.
- **`skills/harness-supervise/fixtures/sample-task-three-rollbacks/PM_LOG.md`** — committed ALERT-path fixture (3 same-stage rollbacks at Stage 5). Used by `test-supervisor` AC-5.
- **`skills/harness-supervise/fixtures/supervisor-mock.json`** — canned `SUPERVISION_REPORT.md` body. Loaded by the skill when `HARNESS_SUPERVISOR_MOCK` env var points at it; bypasses live detection for CI.
- **`scripts/test-supervisor.{ps1,sh}`** — new symmetric test driver covering AC-1..AC-7 plus the I.7 contract in-process emulation. Bash side gates the JSON-validation assertion on `python3` availability (mirrors `test-init.sh:198-201` pattern). Counts: 54 PS / 50 Bash-no-python3 assertions (BUG-1 rollback round 2 added the lowercase + mixed-case negative-fixture assertions; bash gains 1 explicit mirror).
- **`scripts/verify_all.{ps1,sh}` I.7 — Ignored INTERVENE supervision reports (WARN)** — passive guard. Globs every `docs/features/<slug>/SUPERVISION_REPORT.md` (not `_archived/`, not `_supervision/`), reads the last 5 non-blank lines, regex-matches `^Verdict: (HEALTHY|WATCH|INTERVENE)$`, and WARNs if `INTERVENE` appears AND the slug's row in `docs/tasks.md` is not Completed/Archived AND the file mtime is >48h ago. Severity is WARN, not FAIL — the supervisor IS the deep check; `I.7` just notices when one of its alerts was forgotten. Total `verify_all` checks: 29 → 30.

### Anti-pattern thresholds (declared in `supervisor.md`)

- **AP-1 same-stage rollback rate**: 0–1 → no finding · 2 → WARN · ≥3 → ALERT (matches PM hard-stop threshold).
- **AP-1b cross-stage rollback tally**: 0–1 → no finding · 2 → INFO · 3 → WARN · ≥4 → ALERT. Orthogonal to AP-1; T-002 (1 rollback at Stage 5 + 1 at Stage 6 — different stages) emits AP-1b INFO and no AP-1 finding → `Verdict: HEALTHY` (binding interpretation of AC-6 per gate-finding F-1).
- **AP-2 stage-doc thinness**: per-stage required headings + per-stage minimum line count (RA 30 · Arch 40 · Gate 20 · Dev 30 · CR 20 · QA 30 · Delivery 15). Missing heading OR under minimum → WARN; both → ALERT.
- **AP-3 missing intervention checks**: 1–2 missing → WARN · ≥3 → ALERT · PM_LOG absent/malformed → INFO only (prevents T-000-style false positives). **Audit operates on stage-to-stage transitions only**; round-to-round events within a single stage are explicitly NOT audited (gate-finding F-4).
- **AP-4 missing archive call**: single ALERT severity. Fires when `docs/tasks.md` marks task Completed AND stage docs still live under `docs/features/<slug>/` (not `_archived/<slug>/`).

### Three architect decisions (recorded in `docs/features/supervisor-agent/02_SOLUTION_DESIGN.md` §3)

- **A-1 Two-layer fixture**: real task-folder fixtures at `skills/harness-supervise/fixtures/sample-task/` and `.../sample-task-three-rollbacks/` exercise the AP-1..AP-4 detectors on synthetic Markdown; a separate `supervisor-mock.json` covers the AI-dispatch-free path for CI. Separating "fixture" from "mock" lets each be tested independently.
- **A-2 Inline execution by the orchestrator AI**: the skill prompt embeds a "read this file, behave like supervisor.md" instruction rather than a `Task`-tool dispatch — matches NFR-4 (no `Task` in `allowed-tools`) and keeps the skill tool-agnostic across Claude Code / Copilot / Cursor.
- **A-3 Fixed report schema with the verdict as the last non-blank line**: lets `I.7` use a 5-line tail + one-line regex instead of a full Markdown parse; six required sections in fixed order (Summary, Findings, Anti-pattern detail, Cross-references, Methodology notes, Verdict).

### Four Gate-Review round-1 findings resolved (round 2 APPROVED)

- **F-1 (blocker, AC-6 arithmetic)** — added AP-1b cross-stage tally so T-002 archived (1 rollback at Stage 5 + 1 at Stage 6) deterministically yields AP-1b INFO + `Verdict: HEALTHY` rather than the impossible-under-AP-1 "AP-1 WARN" the requirement originally asserted. Binding interpretation note in §16 of the design.
- **F-2 (clarification)** — `skills/harness-status/SKILL.md:24` fix format pinned: add a new row `| Supervisor (auxiliary) | .claude/agents/supervisor.md | ? |` rather than widening the existing `{pm,req,sol,gate,dev,review,qa}*` glob. The canonical-7 glob's purpose is unchanged.
- **F-3 (doc fan-out)** — `AI-GUIDE.md:14` phrasing bumped from `7 agent role contracts` to `7 canonical agents + 1 auxiliary (supervisor)` alongside the line-35 / line-67 check-count bumps and the standard CHANGELOG / README / dev-map / manual-e2e-test / walkthrough / architecture sweep (insight L21).
- **F-4 (AP-3 ambiguity)** — `supervisor.md` AP-3 contract explicitly states audit operates on stage-to-stage transitions only; round-to-round events within a single stage never count as a missing intervention check.

### Changed — Version stamps and surface-count claims

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: `0.16.0` → `0.17.0` (G.3 keeps these in sync).
- `README.md` / `README.zh-CN.md` badges: `version-0.16.0` → `0.17.0`, `verify_all-29/29` → `30/30`. Skill count `9` → `10` in the intro line, the AI skill list, and the regression-testing layer count.
- `AI-GUIDE.md`: `29/29 at v0.16.0` → `30/30 at v0.17.0`; line 14 phrasing bumped to `7 canonical agents + 1 auxiliary (supervisor)`; scripts entry now mentions `I.7 ignored-INTERVENE-report guard` and the new `test-supervisor.{ps1,sh}` driver.
- `docs/dev-map.md`: verify_all comment `29 checks at v0.16.0` → `30 checks at v0.17.0`; scripts/ tree gains a `test-supervisor.{ps1,sh}` row and an `agents/supervisor.md` note.
- `docs/manual-e2e-test.md`: assertion count statement bumped (verify_all 30; test-supervisor ~47); skill-count copy `9` → `10`; slash-command list extended with `/harness-supervise`.
- `docs/walkthrough.html`: sample `/harness-verify` output `29 checks: 29 PASS` → `30 checks: 30 PASS`.
- `architecture.html`: 文档时效说明 banner `v0.16.0 / 29 个 verify_all 检查` → `v0.17.0 / 30 个 verify_all 检查`.
- `.harness/rules/40-locations.md`: verify_all check enumeration bumped to 30 items at v0.17.0; new bullet listing `I.7`; supervisor + harness-supervise rows added.
- `skills/harness-status/SKILL.md`: new asset-list row `Supervisor (auxiliary) | .claude/agents/supervisor.md | ?` added below the canonical-7 row (per F-2); the `{pm,req,sol,gate,dev,review,qa}*.md` glob is NOT widened (asset table includes auxiliary; "7-stage pipeline" wording elsewhere stays).
- `scripts/verify_all.{ps1,sh}` skill-set checks C.1 / G.1 / G.2 updated from 9 → 10 to include `harness-supervise`.

### Notes on regression surface

- `verify_all` 29 → 30 (one new WARN-severity check, I.7). On a clean repo, I.7 is vacuously true (no `SUPERVISION_REPORT.md` files exist yet); it fires only when users actually run `/harness-supervise` and then ignore the resulting INTERVENE verdict for >48h.
- `test-init` unchanged at 227 PASS — additive change, no regression.
- `test-supervisor` new: 54 PS / 50 Bash-no-python3 (one python3-gated JSON-validation assertion fires when python3 is present, raising bash count to 51).
- `test-real-project` unchanged at 82/82.
- No agent contract or pipeline-stage behavior changed. Supervisor is an auxiliary agent file (8th file in `.harness/agents/`) but **not** part of the canonical 7-stage routing — the "7 agents" wording in `harness-status` SKILL.md, the 7-agent pipeline phrasing in README, and the workflow.md stage table are intentionally untouched.

### Backwards compatibility (AC-10 binding)

A v0.16.0 user upgrading to v0.17.0 who never types `/harness-supervise` sees zero behavior change. The skill is on-demand only; the agent file is never loaded unless the skill is invoked. PM Orchestrator's contract is unchanged (it has no awareness of `supervisor.md`). The 9 prior distributed skills are unchanged. The 7-stage pipeline runs the same shape whether the supervisor exists or not.

### Rollback round 2 — BUG-1 fix (I.7 PS case-sensitivity)

Stage-5 QA's adversarial probe (`06_TEST_REPORT.md` ADV-1) found that `scripts/verify_all.ps1`'s I.7 verdict-line regex used PowerShell's default `-match` operator, which is **case-insensitive** — so a malformed `verdict: intervene` (lowercase) would falsely trigger I.7 WARN even though the Q-1 / Architect §15 issue 1 binding decision pinned the schema to UPPERCASE-only. The bash twin at `verify_all.sh:462` correctly used case-sensitive `=~` already, so this was a cross-shell asymmetry. Same insight class as T-002's BUG-2 (PS `-notin` case-insensitivity → use `-cnotin` / `-cmatch`).

- **`scripts/verify_all.ps1:439`** — `-match` → `-cmatch` (one-character fix) with a four-line comment block citing the Q-1 decision, the bash-twin reference (`verify_all.sh:462`), and insight-index L20 (PS case-sensitivity discipline).
- **`scripts/test-supervisor.ps1`** — `Get-VerdictFromReport` helper also bumped to `-cmatch` for consistency with the production code path; added two new negative-fixture assertions in the I.7 contract block: lowercase `verdict: intervene` and mixed-case `Verdict: Intervene` must both fail to parse as a verdict. PS test count: 52 → 54.
- **`scripts/test-supervisor.sh`** — added one explicit lowercase-`verdict:` negative-fixture assertion for cross-shell symmetry (bash's `=~` is already case-sensitive, so the assertion is implicit; making it explicit pins the contract under future shell refactors). Bash-no-python3 count: 49 → 50.

Verification: `verify_all.ps1` 30/0/0 PASS (unchanged); `test-supervisor.ps1` 54/0 PASS (+2); `test-supervisor.sh` 50/0 PASS (+1).

### Known limitations — deferred to v0.17.1

Two adversarial findings from `06_TEST_REPORT.md` are intentionally deferred to a patch release to keep the v0.17.0 rollback round narrow:

- **BUG-2 (MINOR) — I.7 active-row slug match is substring-based on both shells.** `scripts/verify_all.ps1:441` (`[regex]::Escape($slug)`) and `scripts/verify_all.sh:476` (`grep -F -- "$slug"`) flag a report as "active" when ANY row in `docs/tasks.md` contains the slug as a substring — so a slug `foo` is matched by an Active row for `foo-extra`, raising a spurious WARN. Latent footgun for adopters whose task slugs share prefixes (e.g. `auth` / `auth-v2`). Fix queued for v0.17.1: column-anchored match (`\|\s*<slug>\s*\|` PS; `grep -E "\|[[:space:]]*<slug>[[:space:]]*\|"` bash). Reproducer: `06_TEST_REPORT.md` ADV-8.
- **BUG-3 (MINOR) — `supervisor.md` boundary table doc-drift on cross-task N=0.** `.harness/agents/supervisor.md:230` says *"Clamp to `[1, archived-count]`; INFO-log the clamp"* — when `archived-count` is 0 this clamp is mathematically undefined. `skills/harness-supervise/SKILL.md:129` has the authoritative behavior (*"one-line `Verdict: HEALTHY` + INFO 'no archived tasks'"*); the agent contract just has a less-clear edge-case note. No runtime impact (SKILL.md path wins); doc-only drift. Fix queued for v0.17.1: rewrite the boundary row to split the N=0 case from the N>archived-count case. Reproducer: `06_TEST_REPORT.md` ADV-7.

Both are MINOR and do not block v0.17.0 ship. v0.17.1 will sweep both in a single patch.

## [0.16.0] - 2026-05-19

The first **AI-native** release. `/harness-init` and `/harness-adopt` gain a Q6 opt-in step that lets the orchestrator model draft a tailored `.harness/rules/50-<project-slug>.md` (and optional `dev-*` partition agents) grounded in the user's Q2 stack description, the target directory's top-level filenames, and the contents of named manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.) — replacing the previous static-stub-only path. Opt-out remains the default and produces byte-identical v0.15.1 output (AC-10). A new `verify_all` check (`D.3`) keeps the new file shape honest.

### Added — AI customization step in `/harness-init` and `/harness-adopt` (opt-in)

- **`skills/harness-init/SKILL.md` step 5b "AI customization (opt-in)"** — runs between the existing template-copy step 5 and the binding-sync step 6. New Q6 in the AskUserQuestion batch (default `No`). When `Yes`: enumerate top-level files (capped at 100), read any of seven named manifests (capped at 50 KB each), draft a JSON `{ "rule_md": ..., "partition_agents": [...] }`, validate four invariants, write `.harness/rules/50-<slug>.md` (slug sanitized to `^[a-z0-9][a-z0-9-]{0,40}$`), delete the static `50-<type>.md` stub, Edit `AI-GUIDE.md` to swap the index line, and run the partition-agent Accept / Rename / Reject loop.
- **`skills/harness-adopt/SKILL.md` step 4b "AI rule synthesis (opt-in)"** — symmetric to init step 5b but seeded from this skill's step-2 reconnaissance profile; writes the draft to `.harness-adopt/PROPOSED_RULES/50-<slug>.md` so the user can review before approving the plan in step 5.
- **`skills/harness-init/templates/common/.harness/rules/_ai-native-prompt.md`** — canonical drafting prompt shipped into every user project. Documents the input contract (`PROJECT_NAME`, `PROJECT_TYPE`, `STACK`, `TOP_LEVEL`, `MANIFESTS`, `RESERVED_NAMES`), the JSON output contract, the four invariants (six required headings in order, zero `{{...}}` literals, ≤200 lines, no reserved partition names), the per-section source-citation rule (every non-template `## ` or `### ` section MUST have ≥1 `<!-- source: ... -->` annotation with a tag from a small allowed set), and the "don't guess" rule. Leading `_` flags it as documentation rather than a numerically-ordered rule fragment; it is indexed in `AI-GUIDE.md.tmpl` under the "reference only" trigger so `verify_all` E.4b stays happy.
- **`skills/harness-init/templates/common/scripts/ai-native-mock.json`** — shipped mock fixture (`rule_md` + `partition_agents`) for `HARNESS_AI_NATIVE_MOCK`. Used by `scripts/test-init.{ps1,sh}` to exercise the opt-in flow without a live LLM call. Also useful for users who want to dry-run the AI-native path locally after init.
- **`scripts/verify_all.{ps1,sh}` D.3 — AI-generated 50-*.md sanity (FAIL)** — for every `.harness/rules/50-*.md` file: asserts all six required headings present in order, zero `{{...}}` literals, and (per Gate Finding G) **every non-template `##` or `###` section has ≥1 `<!-- source: <tag> -->` annotation** with `<tag>` from the allowed set (`user-q2`, `top-level-glob`, `package.json`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `go.mod`, `pom.xml`, `README.md`). Per-section enforcement (not file-global) keeps D.3 aligned with AC-7 in the requirement.
- **`AI-GUIDE.md.tmpl` conditional index line** (both English and Chinese overlays) — annotated with `<!-- ai-native-init: ... -->` so the skill's step 5b.8 can find and rewrite the line when Q6 = Yes. The template still ships with the legacy `50-{{PROJECT_TYPE}}.md` reference; opt-out is byte-identical to v0.15.1.

### Three architect decisions (recorded in `docs/features/ai-native-init/02_SOLUTION_DESIGN.md` §3)

- **A1 Direct prompt by orchestrator AI** (not a new sub-agent, not a Bash call to a CLI, no MCP) — keeps the skill tool-agnostic; the same skill text runs under Claude Code, Copilot, or Cursor.
- **A2 Four-invariant detector with deterministic fallback to the static stub** — sections present, no `{{...}}`, line cap 200, no reserved names. Single fail-fast check; keeps the failure mode predictable.
- **A3 Env-var-controlled canned-response file (`HARNESS_AI_NATIVE_MOCK`)** for tests — avoids needing a real LLM in CI; the fixture is also useful for user dry-runs. Bash tests gate on `python3` availability (parallel to the existing `init_have_python` guard-rm assertion gate).

### Four Gate-Review dev-time conditions honored (`docs/features/ai-native-init/03_GATE_REVIEW.md`)

- **Finding A** — `templates/i18n/zh/common/AI-GUIDE.md.tmpl` exists and got the conditional-marker comment treatment, parallel to the English overlay. The design's "likely does NOT have its own AI-GUIDE.md.tmpl" assumption was wrong; the gate caught it.
- **Finding D** — both `AI-GUIDE.md:35` ("28/28 at v0.15.1") AND `AI-GUIDE.md:67` ("28 checks at v0.15.1") bumped to v0.16.0 / 29. Same sweep covered `README.md` (badges + "Three layers of regression testing"), `README.zh-CN.md`, `docs/dev-map.md` (3 lines), `docs/walkthrough.html`, `architecture.html`, `MIGRATION.md`, and `.harness/rules/40-locations.md`.
- **Finding F** — every Write/Edit in this delivery was followed by a re-Read or Grep verification before moving on (per insight-index line 10 on Edit-tool false-success).
- **Finding G** — D.3 implementation is per-section, not file-global. Two adversarial fragments confirmed the check FAILs on missing-source / leaked-placeholder rules and PASSes on well-formed ones.

### Two Gate cosmetic findings (B + C) annotated

Inline `<!-- gate-finding-B -->` / `<!-- gate-finding-C -->` HTML comments in `02_SOLUTION_DESIGN.md` at the cited lines explain the two off-by-N citation mis-pointers (Decision Q2 rationale and §7 skeleton-match claim respectively). The design body is intentionally not rewritten — Gate Reviewer is read-only by contract.

### Changed — Version stamps and surface-count claims

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: `0.15.1` → `0.16.0` (G.3 keeps these in sync).
- `README.md` / `README.zh-CN.md` badges: `version-0.15.1` → `0.16.0`, `verify_all-28/28` → `29/29`, `test-init-177/177` → `227/227` (post-rollback-2: includes the AC-10 byte-compare assertion AND the two shell-agnostic BUG-2 placeholder-regex regression assertions). Roadmap row for v0.16.0 added; `0.16+ planned` → `0.17+ planned`.
- `AI-GUIDE.md`: `28/28 at v0.15.1` → `29/29 at v0.16.0`; scripts entry now mentions `D.3 AI-generated 50-*.md sanity`.
- `docs/dev-map.md`: verify_all comment `28 checks at v0.15.1` → `29 checks at v0.16.0`; test-init `177 assertions at v0.15` → `227 PS / 191 Bash-no-python3 at v0.16.0` (rollback round 1 +3 byte-compare; rollback round 2 +2 BUG-2 regex regression; full surface is 227 on both shells when python3 is present).
- `docs/walkthrough.html`: sample `/harness-verify` output `28 checks: 28 PASS` → `29 checks: 29 PASS`.
- `architecture.html`: 文档时效说明 banner v0.15.1 / 27 checks / 177 assertions → v0.16.0 / 29 / 227 (PS) / 191 (Bash without python3).
- `MIGRATION.md`: `verify_all now has 28 checks (...)` updated to 29 with the D.3 entry appended.
- `.harness/rules/40-locations.md`: verify_all check enumeration bumped to 29 items at v0.16.0; new bullet for D.3.
- `docs/manual-e2e-test.md`: assertion count updated to reflect the new test-init total (measured post-implementation).

### Notes on regression surface

- `verify_all` 28 → 29 (one new FAIL-severity check, D.3). Dogfood repo has no `.harness/rules/50-*.md` files so D.3 is vacuously true here; the check fires on user projects that opt in to AI-native at init time.
- `test-init.ps1` 177 → 227 PASS (the bash twin reports 191 here because Windows ships a Microsoft Store python3 stub that fails the `init_have_python` probe and the python-gated subset of the new AI-native block is conditional, same pattern as the existing guard-rm assertion gate; on Linux/macOS both shells run the full 227-assertion surface. The AC-10 byte-compare (rollback round 1, +3) and the two BUG-2 placeholder-regex assertions (rollback round 2, +2) are python3-free so they run on every host).
- `test-real-project` unchanged at 82/82.
- No agent contract or pipeline-stage behavior changed. AI-native is a step *inside* two skills, not a new stage in the 7-agent pipeline.

### Rollback round 2 — BUG-2 placeholder-regex broadening (QA finding)

QA's `06_TEST_REPORT.md` flagged one MAJOR bug in the v0.16.0 safety net: the D.2 + D.3 unsubstituted-placeholder regex `\{\{[A-Z_]+\}\}` did NOT match whitespace-padded variants (`{{ PROJECT_NAME }}`) or lowercase variants (`{{project_name}}`). An AI emitting either form would slip past both gates, leaving a placeholder-looking literal in a user-facing rule file — exactly the failure mode D.3 was added to prevent. Fix: regex broadened to `\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}` in both `scripts/verify_all.ps1` (D.2 ~L101 and D.3 ~L136) and `scripts/verify_all.sh` (D.2 ~L82 and D.3 ~L111). The allowlist still constrains which forms are legal in D.2 — every existing `.tmpl` placeholder is still in the strict `{{UPPER_CASE}}` form, so the broadening is purely safety-tightening, not behavior-changing. Added two in-process unit-test assertions to `test-init.{ps1,sh}` that exercise both variants (single-shot, not per-project-type). Adversarial fragments with `{{ PROJECT_NAME }}` and `{{project_name}}` confirmed in both shells that D.3 now FAILs deterministically.

### Known limitations — deferred to v0.16.1

- **BUG-1 (reserved-name filter shell asymmetry, MINOR)** — QA's `06_TEST_REPORT.md` also flagged that the PowerShell and Bash test-init paths exercise the reserved-name partition filter at slightly different scope: the PS path uses an inline `Where-Object` check against the literal `developer` name; the Bash path simulates via a python3 helper that exits the gate cleanly when the stub probe fails. The happy path (a valid mock with no reserved-name collision) is correct in both shells; the bug surfaces only when an AI proposes a partition named after one of the seven core agents (`pm-orchestrator`, `requirement-analyst`, `solution-architect`, `gate-reviewer`, `developer`, `code-reviewer`, `qa-tester`). Defense-in-depth rationale for deferral: the canonical drafting prompt (`_ai-native-prompt.md`) already instructs the AI to never use reserved names, and the validator filter is a second line of defense that activates only when the prompt is ignored — which is itself an edge case. Tracked for v0.16.1.
- **Five MINOR coverage gaps in `06_TEST_REPORT.md`** also deferred to v0.16.1; this release prioritized closing BUG-2 (the user-facing safety-net hole) over additional coverage.



A patch release that closes a long-standing documentation-drift class. v0.10 (Oct 2025) changed `CLAUDE.md` from a composed file into a static stub, but several user-facing documents and one template kept describing the old composition model. v0.13 / v0.14 then shipped without bumping README surface numbers. This release runs the cleanup to ground (~14 files) and adds a verify-time guard (`I.6`) that FAILs if the retired claims ever resurface.

### Added — `verify_all I.6`: retired-claim phrase guard (FAIL on resurgence)

Scans every git-tracked file (except a small history exemption list: `CHANGELOG.md`, `architecture.html`, `docs/walkthrough.html`, `scripts/verify_all.*`, `docs/features/_archived/`, `参考/`) for any of 13 banned literal substrings that used to be accurate but were retired by a documented architectural change. Two retirement classes are covered:

- **v0.10 composition retirement** — phrases like `Composed into CLAUDE.md`, `composed by filename order`, `composition order in CLAUDE.md`, `regenerates CLAUDE.md`, `regenerated CLAUDE.md`, `.harness/ → CLAUDE.md`, `Generated from .harness/rules`, plus their Chinese variants (`harness-sync 生成 CLAUDE.md`, `harness-sync 合成 CLAUDE.md`, `重新生成的 CLAUDE.md`).
- **v0.3 adopt-automation retirement** — phrase `scaffolding-only` (the harness-adopt skill has been fully automated since v0.3 but the old "scaffolding-only" framing kept showing up in docs).

The check uses literal substring matching, not regex — easier to reason about, no false-positive surprises from creative quoting. Each entry has a `phrase|reason` pair so the FAIL message tells the reader both what's wrong and why. To extend it, add a line to the banned list in both `verify_all.ps1` and `verify_all.sh`. To retire an entry (because the underlying claim became accurate again), remove the line rather than adding a file-level exception. Drift-tested both ways: temporarily injecting `composed by filename order` into a non-exempt file produces a deterministic FAIL naming the file; restoring brings it back to 28/28 PASS.

verify_all goes from 27 → 28 checks total.

### Fixed — Stale v0.5/v0.6-era references in `architecture.html` and `docs/walkthrough.html`

These two visual essays were frozen at v0.5/v0.6 but described their content as "current state". Pragmatic fix rather than full rewrite:

- **`architecture.html`** — added a yellow "文档时效说明" banner directly under the page header pointing readers at `README.md` roadmap / `CHANGELOG.md` / `AI-GUIDE.md` for current state and explicitly noting that v0.10 changed `CLAUDE.md` to a stub; fixed the three lines that described current behavior wrong (the `/harness-init` skill card, the `harness-sync` comment in the v0.4.1 file tree, and the "Two-layer consistency" panel); the "code vs AI" responsibility table row about composition retitled to describe the actual current sync surface plus a footnote about v0.10's retirement.
- **`docs/walkthrough.html`** — the single line claiming `harness-sync` generates `.claude/agents + .claude/skills + CLAUDE.md` corrected to describe only the agents+skills sync (with the CLAUDE.md stub being written once at init); sample `/harness-verify` output updated `27 checks: 27 PASS` → `28 checks: 28 PASS`.
- Both files are added to `I.6`'s exemption list because they're labeled v0.5/v0.6 snapshots — if a future contributor removes that label and starts treating them as current docs, the exemption should be revisited.

A full v0.16-era refresh of both visual essays is queued on the roadmap but out of scope for this patch.

### Fixed — `MIGRATION.md` table entry and troubleshooting

The v0.1 → v0.2 migration table had only two columns; the "After (v0.2)" column was no longer the current state since v0.10. Added a third "Refinement (v0.10+)" column documenting that:

- Rule edits no longer need `harness-sync` (rules are referenced by `AI-GUIDE.md`, not composed).
- `verify_all` now has 28 checks (up from the v0.2-era count it implied).
- The troubleshooting entry "My CLAUDE.md edits keep disappearing" was relabeled as `(v0.2–v0.9 behavior)` with a v0.10+ correction noting CLAUDE.md edits now persist (but the right place to encode rules is still `.harness/rules/*.md`).

### Fixed — `tests/fixtures/README.md` integration-test step description

Step 3 ("Run the project's own `scripts/harness-sync` to generate `.claude/` + `CLAUDE.md`") corrected to describe only `.claude/agents/` and `.claude/skills/` being populated (with an explicit note about the v0.10 CLAUDE.md retirement) — the integration test itself was already correct; only the prose description had drifted.

### Fixed — `.harness/rules/40-locations.md` verify-check enumeration

`verify_all` check count `27 items at v0.15` → `28 items at v0.15.1`; new bullet listing `I.6` so the rule file and the script stay in sync (per insight 2026-05-16 about bidirectional assertion drift).

### Changed — Version stamps and surface-count claims

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: `0.15.0` → `0.15.1` (kept in sync by `verify_all G.3`).
- `README.md` / `README.zh-CN.md` badges: `version-0.15.0` → `0.15.1`, `verify_all-27/27` → `28/28`. "Three layers of regression testing" updated to `28 checks`.
- `AI-GUIDE.md`: `27/27 at v0.15` → `28/28 at v0.15.1`, scripts entry now mentions `I.6 retired-claim phrase guard`.
- `docs/dev-map.md` + `docs/walkthrough.html`: `27 checks at v0.15` → `28 checks at v0.15.1`.

No behavioral change to any agent contract, template, or skill — pure documentation + verification surface alignment.

### Fixed — Stale v0.9-era composition references in user-facing docs and templates

The v0.10 progressive-disclosure rework changed `CLAUDE.md` from a generated composition of `.harness/rules/*.md` into a ~15-line static stub pointing at `AI-GUIDE.md`. The architectural change shipped, but several user-facing documents and one template kept claiming "harness-sync regenerates CLAUDE.md" or "rules are composed by filename order". A new user reading any of these would build a wrong mental model and waste time looking for behavior that does not exist.

- **`docs/getting-started.md`** — install section now leads with the recommended Plugin Marketplace path (`/plugin marketplace add Alan-IFT/harness-kit`) and shows the actual `Alan-IFT/harness-kit` URL instead of the `<your>/harness-kit` placeholder; project-layout box clarifies `CLAUDE.md` as a "~15-line stub pointing at AI-GUIDE.md (written once at init)" and `.claude/agents` / `.claude/skills` as the only paths regenerated by `harness-sync`; the obsolete "in v0.1.x/0.2.x, adopt is *scaffolding-only*" note removed (automated adopt has shipped since v0.3); the "To change a project rule" workflow rewritten to drop the now-bogus `pwsh scripts/harness-sync.ps1 # Regenerate CLAUDE.md` step (rules are not regenerated; AI-GUIDE.md indexes them by reference); troubleshooting "verify_all step E.4 fails: Binding drift" updated to the actual current check name (`E.2`); "Generated CLAUDE.md doesn't match my style" troubleshooting rewritten ("composition is by filename order" → "fragments are referenced, not composed").
- **`docs/dev-map.md`** — layout block: `harness-adopt (scaffolding-only in 0.1)` → `(automated apply since v0.3)`; the missing 5 skills (`harness`, `harness-plan`, `harness-explore`, `harness-goal`, `harness-intervene`) added to the layout (only 4 of 9 were listed); `CLAUDE.md ← Generated from .harness/rules/*.md by harness-sync` → `~15-line stub pointing at AI-GUIDE.md (NOT regenerated)`; "Two layers of consistency" section now correctly says Layer 2 syncs `.harness/{agents,skills}` only, with an explicit "Since v0.10, neither layer regenerates CLAUDE.md" note; Repo-rules row in the feature matrix `Composed into CLAUDE.md by harness-sync` → `Referenced (not composed)`; Layer 2 sync trigger `.harness/agents/ or .harness/rules/` → `.harness/agents/ or .harness/skills/. Rule edits do NOT require sync`; `test-init 86 assertions` → `177 assertions at v0.15`; rule-fragment naming convention now flags that the `NN-` prefix is a sort convention, not a composition order; obsolete "Editing CLAUDE.md … blown away on the next sync" anti-pattern updated.
- **`docs/concepts.md`** — "The big picture (v0.2)" → "The big picture (v0.10)" with the new diagram showing `AI-GUIDE.md` as the entry and `CLAUDE.md` / `.github/copilot-instructions.md` as stubs; "Why CLAUDE.md is generated, not hand-edited" section retitled and rewritten to "Why rule fragments are referenced, not composed (v0.10 progressive disclosure)" explaining the persistent-ruleset token budget delta (~3500 → ~250 tokens) that drove the redesign; "Why does verify_all check binding consistency" updated to mention step `E.4b` (AI-GUIDE.md ↔ rules bidirectional index drift).
- **`README.md` / `README.zh-CN.md`** — `harness-sync.{ps1,sh} .harness/ → CLAUDE.md + .github/copilot-instructions.md` corrected to `.harness/agents + .harness/skills → .claude/ (CLAUDE.md is a static stub since v0.10)`; the Chinese README layout box also gains an `AI-GUIDE.md` line and the `CLAUDE.md` description rewrites the wrong "生成（不要编辑）" claim into "~15 行 stub，指向 AI-GUIDE.md（init 时一次性生成，不重新合成）".
- **`CONTRIBUTING.md`** — the "5 documented placeholders" count corrected to 7 (`{{SYNC_COMMAND}}` from v0.9 and `{{GUARD_COMMAND}}` from v0.15 had never been added to the contribution-guide enumeration); "Filename order determines composition order in CLAUDE.md" updated to "numeric prefix is a sort convention only — since v0.10, fragments are not composed into CLAUDE.md".
- **`.harness/rules/10-self-consistency.md`** (dogfood) — Layer 2 contract: `.claude/agents/ and CLAUDE.md are generated from .harness/ via scripts/harness-sync` corrected to `.claude/agents/ and .claude/skills/ are regenerated from .harness/agents/ and .harness/skills/`; new clause 8 explains `CLAUDE.md` is a stub since v0.10; clause 9 references the actual verify_all check names (`E.2` for byte-identity and `E.4b` for AI-GUIDE drift).
- **`.harness/rules/60-tool-handoff.md`** (dogfood) and **`skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md`** (template — what `/harness-init` ships) — non-Claude-Code handoff procedure: stop telling users to "stage the regenerated `CLAUDE.md` / `.github/copilot-instructions.md`" (those files are not regenerated); the sync handoff scope narrowed to `.harness/agents/` / `.harness/skills/`; new paragraph explains that rule fragments are referenced by AI-GUIDE.md and require an AI-GUIDE.md index entry (verify_all step E.4b enforces this).
- **`skills/harness-init/templates/i18n/zh/common/.harness/rules/60-tool-handoff.md`** — same correction in Chinese for the Chinese init path.
- **`skills/harness-init/SKILL.md`** — the two-layer model paragraph clarified that `CLAUDE.md` is a one-time stub, not regenerated; the final summary report shipped to every new user reorganized so "Source of truth (edit these)" / "Init-time artifacts (touch only to fix the AI-GUIDE.md pointer)" / "Regenerated by harness-sync (never hand-edit)" / "Direct binding glue (safe to edit)" are four explicit groups instead of the previous misleading "Generated (do not edit — re-run harness-sync)" lump that included `CLAUDE.md`.
- **`skills/harness-adopt/SKILL.md`** — file-actions list adds an explicit AI-GUIDE.md line and clarifies that `CLAUDE.md` / `.github/copilot-instructions.md` are one-time stubs (not regenerated by harness-sync); "Next steps" guidance for the user no longer instructs them to "run scripts/harness-sync after" editing rules (sync is only needed for agent/skill edits since v0.10).

No code change. verify_all 27/27 PASS, 0 WARN, 0 FAIL after the sweep. test-init still at 177/177 (no template assertion surface changes).

Why bother with such a comprehensive sweep instead of just patching the worst offender: per the insight-index entry from 2026-05-16, "Releases shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values" — v0.10's architectural change had the same drift pattern, just six months older and across more files. A surgical fix of only the most-read file would leave the half-truth alive in seven other places; eventually a future contributor reads one of them and rebuilds the wrong mental model. Closing all touchpoints at once breaks the pattern.

What's deliberately not in this pass: `architecture.html` and `docs/walkthrough.html` (Chinese visual essays — major rewrites with low day-to-day onboarding impact since most users read the .md docs first) and `MIGRATION.md` (historical doc about the v0.1 → v0.5 transition, where the composition model was still current). These can be picked up separately if the visual essays get a refresh.

### Fixed — Documentation drift after v0.13/v0.14 releases

Both v0.13.0 (mid-task intervention) and v0.14.0 (document size policy) shipped without updating user-facing surface numbers. This pass re-syncs every place readers see counts or version stamps, so README / docs / AI-GUIDE reflect what the code actually does today.

- **`README.md` / `README.zh-CN.md`** — badges (`version-0.12.2` → `0.14.0`, `verify_all-19/19` → `26/26`, `test-init-108/108` → `159/159`, `integration-78/78` → `82/82`); "4/eight skills" → "9/nine skills"; regression-testing counts (19/108/78 → 26/159/82); roadmap rows for 0.13.0 (intervention) and 0.14.0 (doc size) added; `0.13+ planned` → `0.15+ planned`.
- **`AI-GUIDE.md`** — "distributes 4 skills" → "9 skills"; verify gate "19/19 PASS" → "all checks PASS (26/26 at v0.14)"; "(19 checks)" → "(26 checks at v0.14, including I.1-I.5 doc-size WARN guards)".
- **`docs/getting-started.md`** — installer drop list now enumerates all 9 skills grouped by Pipeline / Setup / Operations; init question count "three" → "five" with the actual 5 questions.
- **`docs/manual-e2e-test.md`** — dry-run / install / `/help` discovery expectations all expanded from 4 to 9 skills with full names; init flow updated to 5 questions (project type / stack / verify hook / partitioning / language); `ls -la` "expected at minimum" gained `AI-GUIDE.md`; the stale "CLAUDE.md starts with `<!-- THIS FILE IS GENERATED -->`" claim (removed by the v0.10 stub layout) corrected to reference the AI-GUIDE-pointing stub.
- **`docs/walkthrough.html`** — sample `/harness-verify` output count `19 checks: 19 PASS` → `26 checks: 26 PASS`.
- **`evals/golden-tasks.md`** — Golden #4 expectation "lists 4 skills" → "lists 9 skills".
- **`.harness/rules/40-locations.md`** — verify check enumeration: "(15+ items) / All 4 skills" → "(26 items at v0.14) / All 9 skills"; replaced stale "`CLAUDE.md` matches `.harness/rules/*.md` composed (Layer 2 binding)" line (composition removed in v0.10) with the current AI-GUIDE.md ↔ rules drift check + intervention.md + doc-size soft-cap entries; "Binding sync" target description scoped down to `.harness/agents/` + `.harness/skills/` (rules don't sync since v0.10).

No source-code, agent contract, or template behavior changed — pure doc / rule-fragment alignment. verify_all 26/26 PASS, 0 WARN, 0 FAIL after the sweep.

### Added — `verify_all G.3`: version-stamp consistency check (FAIL on drift)

The doc-resync above was reactive — drift had already happened. G.3 is the preventive layer: every `verify_all` run cross-checks `version` across the four authoritative stamps and FAILs (not WARN) if any of them disagree.

- **`scripts/verify_all.{ps1,sh}`** — new `G.3` step. Extracts version from `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, the `version-X.Y.Z-` shields.io badge in `README.md`, and the same badge in `README.zh-CN.md`. All four must match the same `X.Y.Z`. The FAIL message lists every stamp's value plus the actionable hint "bump all four together when cutting a release", so the failure mode is self-fixing.
- Drift-tested in both languages: temporarily mutating any one stamp produces a deterministic FAIL with the offending file named.
- **PS verify_all `F.2` removed** — was a literal duplicate of `B.2` (both checked `install.ps1` + `install.sh` exist). Bash never had F.2, so PS reported 27 / Bash reported 26 even though they tested the same facts. Deduplicating PS lands both at 26 checks total — same number you see in the README badge.
- **`.harness/rules/40-locations.md`** — bullet added enumerating G.3's contract.
- **`.harness/insight-index.md`** — new entry recording the v0.13/v0.14 drift class and that G.3 closes the version vector but skill-count / check-count claims still need manual sync (no programmatic source-of-truth for those counts).

Why FAIL not WARN: a version mismatch is never "expected drift" — it always means either (a) pre-release state that shouldn't be in main or (b) someone forgot to update a README badge. Both want a hard stop, not a soft hint.

What G.3 does NOT cover (still manual at release time): skill count claims (`"9 skills"` text), `verify_all (26 checks)` claim, test-init / test-real-project assertion counts. Adding programmatic checks for those would either require running the tests inside `verify_all` (too heavy) or pinning every count in a JSON sidecar (premature). Catching the version drift is the highest-leverage single lever; the rest is release-checklist discipline.

### Fixed — Template AI-GUIDE missing `65-intervention.md` + `70-doc-size.md` index entries

Latent shipping defect: a fresh `/harness-init` produced a project where `.harness/rules/` contained `65-intervention.md` (and, for the Chinese path, also `70-doc-size.md`), but `AI-GUIDE.md` did not index them. The user-project's own `verify_all E.5` ("AI-GUIDE.md indexes every .harness/rules/*.md") would FAIL on the very first run after init — a broken first-run experience.

Root cause: `test-init.{ps1,sh}` only asserted that the `50-<type>.md` overlay was indexed (one specific file), not the "every rule file is indexed" inverse. So when v0.13 added `65-intervention.md` and v0.14 added `70-doc-size.md` (zh template never picked up either; English template picked up only 70), the regression suite stayed green while the user-facing template silently rotted.

- **`skills/harness-init/templates/common/AI-GUIDE.md.tmpl`** — added the `65-intervention.md` index line (between 60-tool-handoff and 70-doc-size) and the two missing modes-table rows ("Trivial" + "Mid-task redirect" pointing at `/harness-intervene`).
- **`skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl`** — added Chinese index lines for **both** `65-intervention.md` and `70-doc-size.md` (it was missing both) and the same two modes-table rows in Chinese.
- **`scripts/test-init.{ps1,sh}`** — new assertion "AI-GUIDE.md indexes every .harness/rules/*.md file (matches user-project verify_all E.5)". Walks the rules dir after init and FAILs naming any rule file not referenced in AI-GUIDE.md. This is the inverse of the existing "indexes project-type overlay" check and would have caught the v0.13/v0.14 omissions immediately. Drift-tested both ways: removing the 65-intervention line from the template produces 3 FAILs (one per project type) naming `65-intervention.md`; restoring brings it back to 162 PASS.
- **`README.md` / `README.zh-CN.md`** — test-init badge `159/159` → `162/162` (the +3 reflects the new assertion running once per project type).

Why test the inverse rather than running `verify_all` post-init: the user-project `verify_all` has many checks (build tooling, baselines, etc.) that depend on stack-specific state. Running it inside `test-init` would either be flaky or require heavy fixture setup. A targeted inverse-of-E.5 check buys 90% of the safety for ~10 lines of code per shell.

## [0.15.0] - 2026-05-16

### Added — AI safety guardrails (D1 + D2 + D3)

Ship one cohesive set of guardrails for harness-kit and every project that installs it. Three coordinated deliverables under one minor version bump:

**D3 — Destructive-command guardrail hook (the real feature)**

- **`scripts/guard-rm.{ps1,sh}`** (new, cross-platform pair) — a `PreToolUse` hook script that intercepts every Claude Code Bash tool call and blocks the call when ANY destructive verb (`rm` / `rmdir` / `unlink` / `Remove-Item` / `del` / `erase` / `Clear-RecycleBin` / `shred` / `srm` / `find … -delete`) targets a path that resolves OUTSIDE the nearest `.git/` ancestor of cwd. Nested `pwsh -c "<cmd>"` / `powershell -Command "<cmd>"` are re-tokenized and the same rules apply (max depth 2; deeper nesting → BLOCK with parse-failure message). Inside-repo deletions (`rm -rf node_modules`, `rm -rf build/`) are allowed by design.
- **Override**: `HARNESS_ALLOW_OUTSIDE_RM=1` set for a single bash invocation (or `$env:HARNESS_ALLOW_OUTSIDE_RM=1` in PowerShell). Per-call and visible — cannot be persisted in any committed file.
- **`.claude/settings.json`** (dogfood) + **`skills/harness-init/templates/common/.claude/settings.json.tmpl`** — new `hooks.PreToolUse[]` block with `matcher: "Bash"` pointing at the guard. Template uses the new `{{GUARD_COMMAND}}` placeholder (Windows → `pwsh -File scripts/guard-rm.ps1`; macOS/Linux → `bash scripts/guard-rm.sh`).
- **`.harness/rules/75-safety-hook.md`** (new dogfood + template + zh overlay) — contract, override path, disable path, failure modes, boundaries.
- **`scripts/sync-self.{ps1,sh}`** — guard-rm pair added to the mirror set (4 script pairs total: harness-sync, install-hooks, archive-task, guard-rm).
- **`scripts/verify_all.{ps1,sh}` F.2** (new check, FAIL-level) — asserts both guard scripts exist in dogfood AND in `templates/common/scripts/`; `.claude/settings.json` JSON-parses, has `hooks.PreToolUse[0].matcher == "Bash"`, and the command references `guard-rm.{ps1,sh}`; template `.claude/settings.json.tmpl` contains `{{GUARD_COMMAND}}` + `PreToolUse`. Brings the total from 26 → 27 checks.
- **`scripts/test-init.{ps1,sh}`** — five new assertions per project type (3 types × 5 = +15) covering guard-rm script presence and PreToolUse wiring in the rendered fixture. test-init pass count: 162 → 177.
- **`scripts/test-guard-rm.{ps1,sh}`** + **`evals/guard-rm-cases.md`** — fixture-driven driver exercising 11 input/expected pairs (BLOCK / ALLOW + override). NOT added to `verify_all` (out of scope v0.15); runs on demand.
- **`skills/harness-init/SKILL.md`** — step 5 placeholder table adds `{{GUARD_COMMAND}}`; step 8 mentions the always-on guard; step 11 output references `scripts/guard-rm.{ps1,sh}`.
- **`skills/harness-adopt/SKILL.md`** — step 5 plan lists the new files; step 6 specifies the JSON-merge logic for `.claude/settings.json` (preserve existing keys; append PreToolUse if absent; flag conflict if a matcher==`Bash` entry already exists pointing elsewhere).
- **`skills/harness-status/SKILL.md`** — three new required-asset rows; new `### 3b. Sub-agent dispatch / safety hook` block; health score denominator 11 → 12 with `+1` for installed-and-wired guard.

**D1 — Copilot continuous mode (opt-in)**

- **`AI-GUIDE.md`** (dogfood + en template + zh template) — new "AI tool flow modes" section enumerating the three supported flows.
- **`.harness/rules/60-tool-handoff.md`** (dogfood + en template + zh template) — new "Copilot continuous mode (opt-in)" subsection: activation phrase `continuous mode` (English) or `走全流程` (Chinese), self-dispatch through stages 1 → 2 → 3, **HARD STOP after Gate Review regardless of verdict**, reset at every chat-session boundary.
- **`.github/copilot-instructions.md`** (dogfood + en template + zh template) — third red line amended: "One role at a time **unless the user has explicitly enabled continuous mode** (see `60-tool-handoff.md`)".

**D2 — Claude Code sub-agent dispatch documentation callout**

- **`AI-GUIDE.md`** (dogfood + en template + zh template) — new one-paragraph "Claude Code sub-agent dispatch — already implemented" callout under the existing Agents section, citing `.harness/agents/pm-orchestrator.md` line 4 + lines ~108-129 as evidence.
- **`skills/harness-status/SKILL.md`** — new `Sub-agent dispatch: enabled (Claude Code via Task tool) | n/a (other tools)` line in §3b.

### Changed

- **`AI-GUIDE.md`** (dogfood) — check-count claims `26/26` → `27/27` (lines 34 + 56), and `+ 4 script pairs (harness-sync, install-hooks, archive-task)` corrected to `+ 4 script pairs (harness-sync, install-hooks, archive-task, guard-rm)` (the count was already wrong pre-v0.15 — listed 3, said 4; adding guard-rm makes both accurate).
- **`.harness/rules/40-locations.md`** — `26 items at v0.14` → `27 items at v0.15`; `Placeholder whitelist enforced (5 allowed)` → `(7 allowed)` (was already off — actual count was 6 pre-v0.15; adding `{{GUARD_COMMAND}}` makes it 7); new F.2 line.
- **`scripts/verify_all.{ps1,sh}` D.2** — `{{GUARD_COMMAND}}` added to both whitelists (per insight 2026-05-16: any new placeholder must be added to BOTH or D.2 fails).

### Synced

- `scripts/sync-self.{ps1,sh}` mirrored `scripts/guard-rm.{ps1,sh}` from `templates/common/scripts/` to dogfood (byte-identity per E.1 gate).

### Notes on backwards compatibility

- Dogfood (this repo): `.claude/settings.json` gains the `PreToolUse` block additively; `Stop` and `permissions` are untouched.
- Existing `/harness-init` users (pre-v0.15 projects): not auto-migrated; re-run `/harness-adopt` to get the guard (merge prompt preserves existing settings).
- New `/harness-init` users (v0.15+): get the guard automatically; no opt-in question.
- `harness-sync` scope is unchanged — it does NOT touch `.claude/settings.json` (intentional carve-out; settings.json is per-project, lifecycle differs).

## [0.14.0] - 2026-05-16

### Added — Document size policy (long-term context-bloat guardrail)

Long-running Harness projects accumulate per-task documents (stage docs, PM_LOG, insights, tasks ledger). Without explicit caps, those files grow until AI tools start burning context budget reading bloated context that doesn't earn its tokens. v0.14 ships the policy + the soft-enforcement layer.

#### What's new

- **`.harness/rules/70-doc-size.md`** — new rule fragment defining:
  - **Numeric caps** for 8 document classes: `AI-GUIDE.md` (200), `CLAUDE.md` (50), `.harness/rules/*.md` (200 each), `.harness/agents/*.md` (300 each), `.harness/insight-index.md` (30), `docs/tasks.md` (300), per-task `PM_LOG.md` (500), per-task stage docs (`0[1-7]_*.md`, 500 each).
  - **Process discipline**: "reference, don't paste" (cite `path:line` instead of pasting code blocks), `PM_LOG.md` compaction at the cap, `docs/tasks.md` Completed-row rotation, and the **#1 guardrail**: always run `scripts/archive-task --task <slug>` after every completed `full` / `goal` task.
  - **Adversarial check** to ask before writing: "would a future AI reader need this in the next 10 min?"
- **`scripts/verify_all` `I.1-I.5`** (this repo) and **`F.1-F.6`** (user-project templates: fullstack, backend, generic) — WARN-level size checks that flag overflow files with line counts, pointing at the cap and remediation step from rule 70. WARN not FAIL: soft guidance, no hard block, escalation possible in a later release.
- **PM Orchestrator** (`.harness/agents/pm-orchestrator.md` + template) gained a `## Document size discipline (v0.14+)` section enforcing two operational rules: PM_LOG compaction at the cap, and unconditional archive-task on completion.

#### Why these caps

- AI tools reread always-on files (AI-GUIDE, rules, agents, tasks.md, insight-index) every task — bloat there multiplies across all tasks.
- Per-task files (`PM_LOG`, stage docs) are bounded if archived; the policy makes archival explicit responsibility.
- The "reference, don't paste" rule attacks the most common bloat vector in stage docs: agents pasting 16-line snippets when one `path:line` would do.

#### Why WARN, not FAIL

Hard FAIL would block all CI for a project that's accumulated 200+ tasks. Soft WARN gives signal without breaking. After dogfooding the cap for a few releases, individual checks can graduate to FAIL.

### Changed

- **`AI-GUIDE.md`** (dogfood + template) indexes `.harness/rules/70-doc-size.md` with its trigger condition.
- **`scripts/verify_all.{ps1,sh}`** (this repo) — added I.1-I.5 size WARN block before Summary.
- **`skills/harness-init/templates/{fullstack,backend,generic}/scripts/verify_all.{ps1,sh}.tmpl`** — all 6 user-project templates received the F.1-F.6 WARN block.

### Synced

- `scripts/sync-self.{ps1,sh}` carried the pm-orchestrator update from `templates/common/` to dogfood (byte-identical agents per E.1 gate).

### Upgrade notes

- Existing projects on v0.13 get the new rule + checks on next `git pull` of the plugin marketplace. No migration needed.
- First `verify_all` run after upgrade may show new WARN lines for files you already exceeded — none break the build. Apply rule 70 to bring them under cap when convenient.
- `.harness/rules/70-doc-size.md` is **not** auto-installed into existing projects (rules aren't synced post-init). Re-run `/harness-init` only for new projects; for existing projects, manually copy the rule file from the marketplace if you want size-policy reference in your project. The `F.*` checks in your project's `verify_all` work standalone — the rule file just explains them.

## [0.13.0] - 2026-05-16

### Added — Mid-task intervention protocol (`/harness-intervene`)

First **new capability** on top of the v0.11/0.12 contract baseline. Real usage of the 7-stage pipeline surfaced no blocking bugs, so we're opening the surface again — starting with a universal "soft Ctrl-C" for long autonomous runs.

#### What's new

- **`.harness/intervention.md`** — a single-shot signal file the human (or another AI tool session) can drop to redirect, pause, or annotate an in-flight 7-stage task. PM reads it at every stage boundary, logs the consumption into `PM_LOG.md`, then deletes it. Presence = "unread intervention", absence = "no pending message".
- **`/harness-kit:harness-intervene`** — new skill that writes the intervention file with the right first-line keyword (`STOP` / `REDIRECT <stage>` / `SKIP <stage>` / `NOTE`). Refuses to overwrite an existing unread intervention without confirmation.
- **`.harness/rules/65-intervention.md`** — protocol contract: who writes, who reads, how PM consumes, what's forbidden (rules / insights / bug reports belong elsewhere).
- **PM Orchestrator** updated (both dogfood `.harness/agents/pm-orchestrator.md` and `templates/common/.harness/agents/pm-orchestrator.md`):
  - New `## Mid-task intervention (v0.13+)` section explaining the read points, consumption protocol, and prohibition on agents writing the file themselves.
  - New workflow step 3 (check intervention immediately after PM_LOG.md creation) and updated step 8 (re-check after every stage completion before deciding next route).
- **`.gitignore`** entry for `.harness/intervention.md` (dogfood). The init template instructs new projects to add the same line.
- **`verify_all` E.7** — WARN (not FAIL) if `.harness/intervention.md` is tracked by git (it's supposed to be ephemeral and gitignored).

#### Why intervention before AI-native init

Both were on the v0.13 candidate list. Picked intervention because:
- Universal benefit (every long task across every project type / mode), vs. one-time init.
- Addresses a real "AI long-run runaway" UX pain proactively.
- Simple protocol (one file, four keywords) vs. AI-output-as-config (init).
- AI-native init can wait for evidence that the current static-stub Generic path is the bottleneck.

#### Read points (PM Orchestrator)

1. Immediately after `PM_LOG.md` is created, before stage 1 dispatch.
2. After every stage completion, before routing decision.
3. At the start of every iteration in `goal` mode.

#### Keyword vocabulary

| Keyword | Effect |
|---|---|
| `STOP` | Halt the pipeline, surface to user. No auto-resume. |
| `REDIRECT <stage>` | Override stage's brief. If past it, route back as rollback. |
| `SKIP <stage>` | Skip stage 5 (code-review) or 6 (QA) with logged rationale. **Skipping stage 3 (gate-review) is forbidden.** |
| `NOTE` | Acknowledge, attach to next dispatch's prompt, continue. |

Stage numbers reference `pm-orchestrator.md` (`01` … `07`).

### Changed

- **`AI-GUIDE.md`** — indexes new rule fragment `.harness/rules/65-intervention.md`; new mode row in the workflow-entry table ("Mid-task redirect → `/harness-intervene`").
- **`install.{ps1,sh}`** — `harness-intervene` added to skill list (8 → 9 skills).
- **`scripts/verify_all.{ps1,sh}`** — skill count checks bumped to 9 across C.1, G.1, G.2. New E.7 check (intervention.md tracking warning).
- **`README.md` / `README.zh-CN.md`** — `harness-intervene` listed under operations skills.

### Synced

- `templates/common/.harness/agents/pm-orchestrator.md` mirrored with dogfood version (sync-self gate maintained).
- `templates/common/.harness/rules/65-intervention.md.tmpl` provides the protocol fragment for newly-init projects.

### Tests

- verify_all: PASS (with new E.7).
- test-init: PASS.
- test-real-project: PASS.

### Upgrade notes

- No breaking changes. Existing pipelines work without any modification.
- If you don't write `.harness/intervention.md`, nothing changes — PM's check is a quick `Test-Path` that costs almost nothing.
- Add `.harness/intervention.md` to `.gitignore` for any project that runs the v0.13+ pipeline.
- `/harness-intervene` is opt-in; you can write the file by hand if preferred.

## [0.12.2] - 2026-05-16

### Fixed — Requirement Analyst / Solution Architect / Gate Reviewer agent contracts now match v0.11+ feature surface

v0.12.1 closed the gap for PM Orchestrator + Developer + Code Reviewer, but explicitly punted on the other three agents ("polish pass later if needed"). v0.12.2 finishes the job — now **all 7 agent contracts** know about v0.11+ features (modes, AI-GUIDE.md indirection, insight-index).

#### Changed agents

**`requirement-analyst.md`**:
- New workflow steps 2 & 3: read `AI-GUIDE.md` (project entry) → follow its index to load relevant `.harness/rules/*.md` fragments; read `.harness/insight-index.md` — an insight about stack quirks may constrain in-scope behaviors.
- New `## Mode-specific output` section: full / plan / explore / goal each have different output expectations. **Explore mode gets the LIGHT variant** — Question + Success criteria + Candidates, no acceptance criteria. This was promised by `/harness-explore` SKILL.md but never enforced in the RA contract.

**`solution-architect.md`**:
- New workflow steps 2 & 3: read `AI-GUIDE.md` and relevant rule fragments; read `.harness/insight-index.md` for stack-quirk constraints that affect design (e.g. an insight about an SDK returning `null` instead of throwing affects error-handling design).
- New `## Mode-specific note` section: structure of `02_SOLUTION_DESIGN.md` is the same across modes, but in **plan mode** the design must be complete enough to hand off — possibly to a future session days/weeks later. Cite file paths absolutely; be explicit about assumptions.

**`gate-reviewer.md`**:
- New workflow steps 3 & 4: read `AI-GUIDE.md` + rules (design must comply with active rules); read `.harness/insight-index.md` — does any entry contradict an assumption in the design? If yes, that's a finding.
- **`What you produce` → Verdict** completely restructured by mode:
  - **Full mode** verdict vocabulary (unchanged): `APPROVED` / `APPROVED WITH CONDITIONS` / `BLOCKED ON REQUIREMENT` / `BLOCKED ON DESIGN`
  - **Plan mode** verdict vocabulary (NEW): `APPROVED FOR DEVELOPMENT` (resume hook for `/harness` continuation) / `CHANGES REQUIRED` / `REJECTED`
  - The exact verdict string is the PM's signal for next action — using the wrong vocabulary in plan mode breaks the resume path.

### Synced

`.harness/agents/{requirement-analyst,solution-architect,gate-reviewer}.md` in this repo (dogfood) updated via `sync-self`. `.claude/agents/*.md` re-generated via `harness-sync`.

### Tests

- verify_all: 20/20 PASS.
- test-init: 159/159 PASS.
- test-real-project: 82/82 PASS.

Same as v0.12.1: no new assertions because this is an internal-prompt contract fix. The test suites can't introspect agent prompt behavior.

### v0.11+ agent contract debt — fully closed

All 7 agents are now v0.11+ aware:
- `pm-orchestrator` (v0.12.1): modes, insight-index, archive-task
- `requirement-analyst` (v0.12.2): modes, AI-GUIDE.md, insight-index, light-variant for explore
- `solution-architect` (v0.12.2): AI-GUIDE.md, insight-index, plan-mode hand-off discipline
- `gate-reviewer` (v0.12.2): AI-GUIDE.md, insight-index, mode-specific verdict vocabulary
- `developer` (v0.12.1): AI-GUIDE.md, insight-index, `## Insight to surface` reporting
- `code-reviewer` (v0.12.1): AI-GUIDE.md / rules references
- `qa-tester` (v0.11.0): adversarial verification contract

## [0.12.1] - 2026-05-16

### Fixed — Agent role contracts now match the v0.11+ feature surface

Audit revealed that the SKILL.md files I shipped in v0.11.0/v0.12.0 (three modes, insight-index, archive-task, AI-GUIDE.md indirection) updated the **outer surface** of the system, but the `.harness/agents/*.md` **role contracts** — the actual prompts each agent runs under — were largely still operating on v0.10 assumptions. This is silent rot: features that look shipped but don't actually take effect in real use.

#### Changed agents

**`pm-orchestrator.md`** — substantial update:
- **New `## Task modes (v0.11+)` section**: lists the 4 modes (full / plan / explore / goal), which stages each runs, and the rule that PM must respect the user's chosen mode (not silently switch to full pipeline).
- **New `## Cross-task memory` section**: PM must read `.harness/insight-index.md` at task start and surface applicable entries to downstream agents in dispatch prompts.
- **"How to start a task" workflow** restructured:
  - Step 1 now records mode in the initial input
  - Step 3 (new) reads insight-index
  - Step 6 dispatches stages **according to the mode**
  - Step 9 (new) runs `scripts/archive-task --task <slug>` after delivery (always for full/goal; optional for plan/explore)
- **`## What to write at delivery` updated**: 07_DELIVERY.md format now includes a `Mode:` field and an optional `## Insight` section (with explicit "do not write filler" guidance referencing the 05-insight-index.md contract).
- **Resume rule for partial tasks**: if a previous `/harness-plan` run produced 01-03 with `APPROVED` GR verdict, PM now skips stages 1-3 on `/harness` continuation.

**`developer.md`** — moderate update:
- Hard rule #6 now references `AI-GUIDE.md` + `.harness/rules/*.md` (not `CLAUDE.md`, which is now a stub since v0.10) AND `.harness/insight-index.md`.
- Workflow step 2 reads `AI-GUIDE.md` and follows its index; step 9 (new) flags "Insight to surface" if implementation uncovered a non-obvious project truth — PM will consolidate into 07_DELIVERY.md.
- 04_DEVELOPMENT.md template now has an optional `## Insight to surface` section.
- "What good looks like" references AI-GUIDE.md / rules instead of CLAUDE.md.

**`code-reviewer.md`** — minor:
- "What bad looks like" anti-pattern reference fixed (CLAUDE.md → AI-GUIDE.md / `.harness/rules/`).

Other agents (`requirement-analyst`, `solution-architect`, `gate-reviewer`, `qa-tester`) were already either updated in v0.11.0 (qa-tester with adversarial contract) or didn't have outdated CLAUDE.md references. They'll get a polish pass later if real usage reveals gaps.

### Propagated via sync-self

`.harness/agents/{pm-orchestrator,developer,code-reviewer}.md` in this repo (dogfood) updated to match the new template files. `.claude/agents/*.md` re-generated by harness-sync.

### Tests

- verify_all: 20/20 PASS.
- test-init: 159/159 PASS.
- test-real-project: 82/82 PASS.

No new assertions added — this patch fixes the agents' **internal contracts**, not the externally observable file layout that the test suites verify. Real coverage of "does PM actually respect modes" requires running the system end-to-end, which is a separate dogfood concern.

## [0.12.0] - 2026-05-16

### Added — Generic project type is now a first-class overlay

The v0.11.2 CHANGELOG explicitly listed "Known issue: the Other / Generic project type's `AI-GUIDE.md.tmpl` references `50-generic.md` but the SKILL.md doesn't write that file at init — first verify_all FAILs." v0.12.0 closes that gap by **promoting "Generic" from a stop-gap option to a first-class overlay parallel to fullstack and backend**.

#### Concretely

- **New: `templates/generic/`** overlay directory, parallel to `templates/fullstack/` and `templates/backend/`. Contains:
  - `.harness/rules/50-generic.md.tmpl` — project-specific rules stub with explicit "fill these in" guidance for build/test/lint commands, project structure conventions, stack-specific patterns, and optional partition setup
  - `scripts/verify_all.ps1.tmpl` and `scripts/verify_all.sh.tmpl` — minimal stack-agnostic verify_all skeleton with A.* hygiene checks + B.* placeholder steps (with examples for Rust / Python / Go / .NET / Java / mobile at the bottom of the file) + E.* Harness structure checks (including the v0.10 stub-references-AI-GUIDE and v0.11.2 AI-GUIDE-indexes-rules consistency checks)
- **New: `templates/i18n/zh/generic/`** with Chinese counterparts of the above.
- **`harness-init` SKILL.md updates**:
  - Q1 option renamed from "Other / Generic" to **"Generic"** with clean PROJECT_TYPE value `generic`
  - Step 4 (Copy template files) now covers Generic alongside fullstack/backend — overlay always copied, no special-casing
  - Placeholder table updated: `PROJECT_TYPE` valid values now `fullstack` / `backend` / `generic`
  - Q4 partitioning skip rule now points to the documented partition setup procedure in `50-generic.md`

#### Test coverage

- `scripts/test-init.{ps1,sh}` now accepts `--type generic` (and the new default is `all`, which exercises **all three** project types in one run).
- Generic test scenario: simulates init for a "Rust CLI tool" project, asserts:
  - 7 common agents present (no partition agents — correctly)
  - `.harness/rules/50-generic.md` exists and PROJECT_NAME substituted
  - Skills directory absent (correctly — generic ships no `.harness/skills/`)
  - `scripts/verify_all.{ps1,sh}` present with PROJECT_NAME / STACK substituted
  - AI-GUIDE.md references `50-generic.md` correctly
- test-init: **116 → 159 PASS** (+43 new assertions for generic). Total assertion count across all 3 test suites is now 261 (was 218).

### Changed

- README.md and README.zh-CN.md: removed "Not yet supported" hedging; explicit that Generic is a first-class overlay. Quickstart Q1 description updated. Roadmap row added for 0.12.0.

### Tests

- verify_all: 20/20 PASS.
- test-init: **159/159 PASS** (was 116/116).
- test-real-project: 82/82 PASS.

### Closed

- v0.11.2 known issue ("Other-Generic projects' first verify_all run fails E.5/D.5"). Resolved by shipping the missing `50-generic.md` and a real `verify_all` template.

## [0.11.2] - 2026-05-16

### Added — verify_all check: `AI-GUIDE.md` ↔ `.harness/rules/` consistency

v0.10 introduced `AI-GUIDE.md` as the tool-agnostic index referencing `.harness/rules/*.md` fragments. v0.11.0 added a new fragment (`05-insight-index.md`) and I almost forgot to update AI-GUIDE.md's index — caught only because I was tracing through what to edit. This is exactly the "AI attention decay" failure the reference articles warn about: relying on memory to keep two documents in sync is unsustainable.

`verify_all` now has a bidirectional consistency check (`E.4b` in the dogfood; `E.5` / `D.5` in per-project fullstack/backend templates):

- **Forward**: every `.harness/rules/*.md` file on disk MUST be referenced in `AI-GUIDE.md` (otherwise AI tools following AI-GUIDE.md miss the rule entirely).
- **Reverse**: every `.harness/rules/<name>.md` reference in `AI-GUIDE.md` MUST point to an existing file (otherwise AI follows a broken pointer).

The check is "verification, not generation" — consistent with the v0.10 philosophy of "AI-GUIDE.md and CLAUDE.md are NOT regenerated; they're authored. We just catch drift."

A failed check tells the user / AI exactly which file is missing from which side, so the fix is mechanical (add or remove one line).

### Changed

- `scripts/verify_all.{ps1,sh}`: new `E.4b` check (dogfood). Total dogfood checks: 19 → 20.
- `templates/fullstack/scripts/verify_all.{ps1,sh}.tmpl`: new `E.5` check; the previous `E.5` (adversarial tests in test reports) renumbered to `E.6`.
- `templates/backend/scripts/verify_all.{ps1,sh}.tmpl`: new `D.5` check; the previous `D.5` (adversarial tests) renumbered to `D.6`.

### Tests

- verify_all: 20/20 PASS (was 19/19; one new check added).
- test-init: 116/116 PASS.
- test-real-project: 82/82 PASS.

### Known issue (not fixed in this patch)

The "Other / Generic" project type's `AI-GUIDE.md.tmpl` still references `50-{{PROJECT_TYPE}}.md` (which substitutes to e.g. `50-generic.md`), but the SKILL.md doesn't currently write that file to disk during init for Other-Generic. So an Other-Generic user's first `verify_all` run would fail E.5/D.5 with "AI-GUIDE.md references non-existent: .harness/rules/50-generic.md". Will be addressed in v0.12 alongside the broader Other-Generic improvements (AI-native init).

## [0.11.1] - 2026-05-16

### Fixed — Symmetric mode skills; `/harness` skill was referenced but did not exist

v0.11.0 shipped `/harness-plan`, `/harness-explore`, `/harness-goal` and updated docs / AI-GUIDE to talk about four parallel "task shape" modes. But the SKILL.md cross-references in those three skills referenced `/harness` as the full-pipeline counterpart — and **`/harness` did not exist as a skill**; the full 7-stage was only invocable via natural language to the PM Orchestrator. Documentation / reality gap.

Fix: added `skills/harness/SKILL.md`, making the 4 mode skills symmetric. The new skill explicitly documents the canonical 7-stage flow with the v0.11 contracts (insight-index read at start, adversarial QA, archive-task at end). It also adds explicit "resume from partial run" logic for the `/harness-plan` → `/harness` continuation path.

### Added — Chinese trigger words in the mode-selection table

`AI-GUIDE.md` (both dogfood and template; en + zh i18n) decision-tree table now lists both English and Chinese trigger phrases per mode. The main Claude Code agent (and any other AI tool reading AI-GUIDE.md) can match Chinese user input ("能不能...", "先别动手", "持续优化到...") directly to the right mode, not just English. Earlier versions implicitly assumed English keyword matching.

### Changed

- `skills/` count: 7 → 8 (added `/harness`).
- `install.{ps1,sh}`: skill list updated, print order restructured to put pipeline skills first, then setup, then operations.
- `scripts/verify_all.{ps1,sh}` C.1 / G.1 / G.2: "All 7 skills" → "All 8 skills".
- README.md and README.zh-CN.md: skill section now has 3 groups (Pipeline / Setup / Operations) with `/harness` at the top.

### Tests

- verify_all: 19/19 PASS.
- test-init: 116/116 PASS.
- test-real-project: 82/82 PASS.

## [0.11.0] - 2026-05-16

### Added — Three execution modes + adversarial verification + cross-task insight index

User pointed me at **lsdefine/GenericAgent** to mine borrowable ideas. After surveying GenericAgent's design (a self-evolving Python agent framework with L0–L4 memory, supervisor-via-files protocol, Plan/Task/Goal modes, and an "adversarial independent verification" stage in its plan SOP), three patterns map cleanly onto harness-kit's "less code, more docs" + "Claude Code ecosystem first" philosophy. v0.11 lands those three.

User also confirmed no backwards-compat needed (the project is still in testing), so **`/harness-migrate` (v0.10 only) has been removed** as dead code — bringing the skill count from 5 → 4, plus 3 new modes → 7 total.

#### 1. Three execution modes — `/harness-plan`, `/harness-explore`, `/harness-goal`

The full 7-stage pipeline is ceremonial for many real-world tasks (research, design-only review, "keep improving" loops). GenericAgent's Plan/Task/Goal triad gave a clean abstraction. Mapped to harness-kit:

- **`/harness-kit:harness-plan`** — design-only mode. Runs RA + SA + GR (stages 1-3) and stops with a verdict. ~30-40% of full-pipeline cost. Use to vet a design before committing engineering time. Skill defines verdict types (`APPROVED FOR DEVELOPMENT` / `CHANGES REQUIRED` / `REJECTED`) and how the partial 01-03 docs can be resumed by `/harness` later.
- **`/harness-kit:harness-explore`** — research / feasibility mode. Light RA + a `findings.md` with citations. No design, no code. Use for "can we even do X?" type questions. ~15-20% of full-pipeline cost. Skill explicitly forbids implementing the answer (switch to `/harness-plan` if you want to).
- **`/harness-kit:harness-goal`** — open-ended Dev + QA loop bounded by a measurable success criterion and a budget (max iterations or max minutes). Use for "keep improving until coverage > 80%" / "reduce verify_all warnings to 0" type tasks. Each iteration's Developer dispatch receives only the 3 most recent iterations' history to bound context growth (GenericAgent-style budget discipline). Final QA must include the adversarial section (see #2).

These are skill markdown files only — no new runtime code, no new harness-sync logic. They route through the existing PM Orchestrator + Task tool infrastructure.

#### 2. Adversarial verification (the highest-ROI borrow from GenericAgent)

GenericAgent's `verify_sop.md` has three iron rules: "must really run (with tool output)", "no tool evidence = skipped", and "cannot rely on the implementer's tests (they may share mock assumptions with the bug)". This contractual adversarial mindset is exactly what harness-kit's QA stage was missing — the v0.10 QA tester read from `04_DEVELOPMENT.md` and inherited the developer's cognitive biases.

Changes:
- `templates/common/.harness/agents/qa-tester.md` adds an **"Adversarial mindset (core principle)"** section with three iron rules: no-tool-evidence-no-claim / independent-reproducer-not-dev's-test / one-predicted-failure-per-AC. Test report format now includes a **REQUIRED `## Adversarial tests`** section with hypothesis + reproducer + tool output per acceptance criterion.
- `templates/{fullstack,backend}/scripts/verify_all.{ps1,sh}.tmpl` adds a new step (`E.5` / `D.5`) that fails if any `06_TEST_REPORT.md` under `docs/features/` is missing the `## Adversarial tests` section. Verification now contractually enforces the discipline.
- Dogfood: `.harness/agents/qa-tester.md` propagated via `sync-self`.

#### 3. Cross-task insight index (`.harness/insight-index.md`) + `scripts/archive-task`

Long-running projects accumulate hard-won truths ("this column is TIMESTAMPTZ", "this SDK silently returns null") that every new task otherwise re-discovers. GenericAgent's L1 `global_mem_insight.txt` is a ≤30-line indexed memory; we adopt the same idea as a markdown file.

New files:
- `templates/common/.harness/rules/05-insight-index.md.tmpl` — the contract for what counts as insight, when to read it, when to write it, and the "adversarial test" for writing (if a reasonable person could derive it in <10 min from the codebase, it's not insight). Trigger condition: "at the start of any task that involves design or implementation decisions."
- `templates/common/.harness/insight-index.md.tmpl` — the data file itself, starts empty with a 1-line header.
- `templates/i18n/zh/common/` — Chinese versions of both.
- `templates/common/scripts/archive-task.{ps1,sh}` — at task completion, harvests `## Insight` section bullets from `07_DELIVERY.md` into `.harness/insight-index.md`, moves the 7 stage docs to `docs/features/_archived/<task>/`, and rotates the oldest insights to `docs/features/_archived/insight-history.md` if the index would exceed 30 lines. Never deletes; only moves and appends.
- `sync-self.{ps1,sh}` mappings extended to keep the archive-task scripts byte-identical between `templates/common/scripts/` and the dogfood's `scripts/`.

Dogfood: `.harness/rules/05-insight-index.md` and `.harness/insight-index.md` created for this repo. The insight-index seeded with three real truths from v0.9.x / v0.10.0 development (the Edit-tool-silent-success bug, the placeholder-whitelist gotcha, the sync-self-doesn't-cover-rules gotcha).

`AI-GUIDE.md` (both dogfood and template) updated to reference the new rule fragment, the insight-index data file, the three new modes, and the `archive-task` script.

### Removed

- `/harness-migrate` skill (was v0.10-only). The project isn't in production use yet; the migrate skill was dead code. Brings skill count from 5 → 4 setup/ops skills + 3 new modes = 7 total.

### Changed

- `install.{ps1,sh}` — skill list updated (remove migrate, add 3 modes).
- `scripts/verify_all.{ps1,sh}` C.1 / G.1 / G.2 — now check "All 7 skills".
- README.md and README.zh-CN.md — restructured skill section into Setup / Operations / Modes; roadmap updated.

### Tests

- test-init: 116/116 PASS (unchanged from v0.10.0 — new templates pass the existing assertions).
- test-real-project: 82/82 PASS (same).
- verify_all: 19/19 PASS.

### Explicitly NOT borrowed from GenericAgent

- **9 atomic tools + `code_run` fallback** — overlaps with Claude Code's native tool surface; reinventing would violate "don't reinvent platform mechanisms."
- **Self-evolution / auto-skill-crystallization** — would require auto-writes to `.harness/rules/`, violating "truth source is not auto-modified."
- **Python runtime** — violates "lightweight, markdown + dual-shell scripts only, zero runtime dependency."

The borrow surface was the **discipline** (adversarial verification, insight tiering, mode separation), not the implementation.

## [0.10.0] - 2026-05-16

### Added — Progressive-disclosure layout (`AI-GUIDE.md` entry + stub CLAUDE.md / copilot-instructions.md)

User pushed back on the v0.9.x architecture: even with all the auto-sync infrastructure, the project was still maintaining two near-identical generated documents (`CLAUDE.md` and `.github/copilot-instructions.md`, each ~250 lines) and burning Claude Code's persistent system-prompt context on the full ruleset every session — regardless of whether the user was filing a typo or building a feature.

The right architectural answer, after reading the 4 reference articles in `参考/`, is the same pattern Claude Code itself uses for skills: **progressive disclosure**. A small always-loaded stub points at a slightly larger on-demand index, which in turn points at modular rule fragments AI tools load only when relevant.

#### New layout

```
.harness/rules/*.md      ← SOT, modular fragments (UNCHANGED from v0.9.x)
       ↑
       │  referenced by
       │
AI-GUIDE.md              ← NEW: ~50-line tool-agnostic index with "when to read" triggers
       ↑
       │  pointed at by
       │
CLAUDE.md                            ← REPLACED: ~15-line bootstrap stub (was: ~250-line generated)
.github/copilot-instructions.md     ← REPLACED: same stub with applyTo frontmatter
```

#### What changed

- **`AI-GUIDE.md`** (new file, root): tool-agnostic entry. Indexes `.harness/rules/`, `.harness/agents/`, `.harness/skills/` with a 1-line description and "when to read" trigger for each. AI tools follow the index and lazy-load only the relevant fragments — like Claude Code's skill system.
- **`CLAUDE.md`**: was a generated ~250-line file composed from `.harness/rules/`. Now a static ~15-line stub: output language + 3 hard red lines + "read `AI-GUIDE.md` first". Written once at init, never regenerated.
- **`.github/copilot-instructions.md`**: same transformation. Static stub with `applyTo: "**"` frontmatter for Copilot.
- **`harness-sync.{ps1,sh}`**: scope reduced ~60%. No more composing CLAUDE.md or copilot-instructions.md from rule fragments. Only copies `.harness/agents/` → `.claude/agents/` and `.harness/skills/` → `.claude/skills/` (still needed because Claude Code requires those paths).
- **`install-hooks` pre-commit hook**: error message updated to reflect the narrower drift scope (agents/skills only, not rules).
- **`verify_all` E.4**: replaced the "generated artifacts present" check with "bootstrap files present and stubs reference `AI-GUIDE.md`" check.
- **`harness-init` SKILL.md**: Step 4 (copy templates) now copies `AI-GUIDE.md.tmpl`, `CLAUDE.md.tmpl`, and `.github/copilot-instructions.md.tmpl` (new template files). Step 6 (run binding sync) reflects the narrower scope.

#### Context budget improvement

| Scenario | v0.9.x persistent tokens | v0.10 persistent tokens | Saving |
|---|---|---|---|
| Single-turn small question | ~3500 | ~250 | 92% |
| Feature implementation (function + test) | ~3500 | ~1500 | 57% |
| Complex cross-stage task | ~3500 | ~4500 | -28% (but loaded fragments are all relevant) |
| **Weighted average** | **~3500** | **~1500–2000** | **~50%** |

Plus: v0.9.x's CLAUDE.md was in the system prompt every turn. v0.10's `AI-GUIDE.md` and fragments load once per session (then sit in cached conversation history).

#### New skill: `/harness-migrate`

`skills/harness-migrate/SKILL.md` — one-shot migration for v0.9.x projects:
1. Backs up `CLAUDE.md`, `.github/copilot-instructions.md`, and the scripts to `.harness-migrate-backup/`.
2. Writes the new `AI-GUIDE.md` (project info extracted from the old `CLAUDE.md` header).
3. Overwrites `CLAUDE.md` and `.github/copilot-instructions.md` with the new stubs.
4. Updates `harness-sync` / `install-hooks` / `verify_all` from the v0.10 templates.
5. Runs the new `verify_all` to confirm.

#### Migration path for v0.9.x users

Either:
- Run `/harness-kit:harness-migrate` (recommended — one shot, auto-backup, ~10 seconds)
- Or follow the manual steps in `skills/harness-migrate/SKILL.md`

`.harness/rules/`, `.harness/agents/`, `.harness/skills/` are **unchanged** — only the bootstrap surface and scripts change.

### Tests

- test-init: 116/116 PASS (added AI-GUIDE.md + stub assertions, removed obsolete "GENERATED FILE" + "overlay marker" assertions)
- test-real-project: 82/82 PASS (same pattern)
- verify_all: 19/19 PASS

### Breaking changes

This is a breaking change for users developing inside an existing v0.9.x harness-bound project who hand-edit `CLAUDE.md`. After migration, `CLAUDE.md` is a stub — edits to it will not survive future syncs (well, the stub doesn't get regenerated, but edits there violate the "do not edit static files" red line and should go into `.harness/rules/` instead).

Users who only edit `.harness/rules/` directly (the documented path since v0.2) are **unaffected**: their workflow now produces less context bloat with no other change.

## [0.9.2] - 2026-05-16

### Added — Tool-agnostic git pre-commit hook (closes the Copilot doc-drift gap)

User flagged the obvious gap in v0.9.0/0.9.1's "auto-sync via Stop hook" design: **the Stop hook only fires for Claude Code.** A user developing through GitHub Copilot (or Cursor, or hand-editing `.harness/`) would not trigger the hook, so `CLAUDE.md` and `.github/copilot-instructions.md` could go stale until someone next opened Claude Code.

`verify_all` would eventually catch the drift, but only when manually run — not on every workflow boundary. The fix needs a tool-agnostic enforcement point.

#### Solution: `scripts/install-hooks.{ps1,sh}` + git pre-commit hook

New scripts install `.git/hooks/pre-commit` that runs `harness-sync --check`. Any commit with `.harness/` ↔ generated drift gets blocked with a clear error pointing the user (or their AI) to the fix command. This catches:

- GitHub Copilot edits to `.harness/`
- Cursor edits to `.harness/`
- Manual edits in any IDE
- A misbehaving Claude Code session whose Stop hook didn't fire
- A `git commit --amend` that pulled in stale generated files

Plus the "Doc-sync responsibility when not on Claude Code" section was added to `.harness/rules/60-tool-handoff.md` (en + zh + dogfood). It explicitly tells non-Claude-Code AIs: "you have no Stop hook; either run sync before declaring done, or let the pre-commit hook block you."

#### Q3 reframed

`harness-init` Q3 was previously "Enable verify_all hook on Stop event?" — misleading, since the Stop hook actually runs `harness-sync`, not `verify_all`. v0.9.2 rewrites it as "Install auto-sync hooks?" with two options: `Yes (recommended)` installs both the Stop hook and the pre-commit hook; `No, manual only` keeps the Stop hook present (it's harmless if Claude Code isn't used) but skips the pre-commit hook.

A new init step 8 ("Install the git pre-commit hook") runs `install-hooks` automatically if Q3 = Yes.

### Changed

- `skills/harness-init/templates/common/scripts/install-hooks.{ps1,sh}` — new files; static, no template substitution needed.
- `scripts/sync-self.{ps1,sh}` — mapping list extended to keep install-hooks scripts in sync between `templates/common/scripts/` and the dogfood's `scripts/`.
- `skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md` — new "Doc-sync responsibility when not on Claude Code" section explains the Copilot Stop-hook gap and the two ways to handle it.
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` — Chinese translation of the same section.
- `.harness/rules/60-tool-handoff.md` — dogfood update.
- `skills/harness-init/SKILL.md` — Q3 reframed; new Step 8 (install pre-commit hook); steps 8–10 renumbered to 9–11.
- Dogfood: this repo now has `.git/hooks/pre-commit` installed (ran `scripts/install-hooks.ps1` once).

### Tests

- test-init: 108/108 PASS.
- test-real-project: 78/78 PASS.
- verify_all: 19/19 PASS.

## [0.9.1] - 2026-05-16

### Fixed — OS-aware Stop hook command (no more manual edit on macOS/Linux)

v0.9.0 shipped `templates/common/.claude/settings.json.tmpl` with a hardcoded `pwsh -File scripts/harness-sync.ps1` Stop-hook command and a comment telling non-Windows users to change it to `bash scripts/harness-sync.sh`. That's manual friction the init flow should eliminate.

v0.9.1 introduces a new `{{SYNC_COMMAND}}` placeholder. At init time, the AI detects the OS and substitutes:

- **Windows** → `pwsh -File scripts/harness-sync.ps1`
- **macOS / Linux** → `bash scripts/harness-sync.sh`

So the Stop hook just works after init, on any platform, no hand-edit required.

### Changed

- `skills/harness-init/templates/common/.claude/settings.json.tmpl` — `pwsh -File ...` replaced with `{{SYNC_COMMAND}}`; the doc comment now explains the substitution happened at init.
- `skills/harness-init/SKILL.md` — `{{SYNC_COMMAND}}` added to the placeholder table with OS-detection logic (Windows vs Unix-like).
- `scripts/verify_all.{ps1,sh}` — `{{SYNC_COMMAND}}` added to the placeholder whitelist so D.2 doesn't flag the new tag as unknown.
- `scripts/test-init.{ps1,sh}` and `scripts/test-real-project.{ps1,sh}` — substitute `{{SYNC_COMMAND}}` per OS so the regression suites verify the new placeholder gets resolved correctly.

### Tests

- test-init: 108/108 PASS.
- test-real-project: 78/78 PASS.
- verify_all: 19/19 PASS.

## [0.9.0] - 2026-05-16

### Added — Auto-sync via Stop hook, "Other / Generic" project type

Triggered by user reflection on the v0.8.x state:
1. "Theoretically I shouldn't have to edit any docs — humans should only describe requirements in chat; never edit docs or code by hand."
2. "The project should apply to all tech stacks, not just fullstack and backend."
3. "Developer partitioning should be analyzed from actual project state, not preset constraints — presets lose the flexibility and precision AI-driven analysis would give."

This release takes the **low-risk, high-value subset** of those reflections; v0.10 will land full AI-native init.

#### 1. Auto-sync via Stop hook (eliminates the "forgot to sync" friction)

`templates/common/.claude/settings.json.tmpl` now ships with a `Stop` hook that runs `pwsh -File scripts/harness-sync.ps1` at the end of every Claude Code session. So:

- You edit `.harness/rules/*.md` (or ask AI to).
- Session ends → harness-sync runs → `CLAUDE.md` and `.github/copilot-instructions.md` regenerate.
- No manual command. No "I forgot to sync." `verify_all` still catches drift if the hook didn't fire.

On macOS/Linux without PowerShell Core (`pwsh`), users change the command to `bash scripts/harness-sync.sh`. A `_doc_sync_hook` comment in the settings explains both paths.

Permissions added: `Bash(pwsh:*)` and `Bash(bash scripts/harness-sync.sh:*)`.

Hard rule #7 in `.harness/rules/00-core.md` updated to reflect that manual sync is rarely needed. **New hard rule #8** ("Prefer asking the AI to edit `.harness/` rather than editing it yourself") makes the AI-driven editing path explicit, with examples.

#### 2. "Other / Generic" project type

`harness-init` Q1 (project type) now has **three options** instead of two:
- `Fullstack (frontend + backend + DB)` — copies fullstack overlay
- `Backend / API service` — copies backend overlay
- `Other / Generic` — **for everything else** (CLI tool, library, mobile, ML pipeline, embedded, etc.). Only common assets copied; no project-type overlay. Q4 (partitioning) is skipped — defaults to single developer. After init, the PM or the user can ask AI to "look at the project and propose what rules / partition agents / verify_all checks should apply" — AI reads existing code (or the user's description), then generates `.harness/rules/50-project.md`, optional `.harness/agents/dev-*.md`, and customizes `verify_all`.

This makes the project usable for any stack today, without waiting for v0.10. The trade-off: Generic projects don't get a pre-tuned `verify_all` — the user (or AI on the user's request) wires up build/test/lint commands once.

#### 3. Roadmap signal: v0.10 = AI-native init

`SKILL.md` Q1 and Q4 explicitly call out that v0.10 will analyze the user's project (description + existing code if any) and **generate a custom overlay automatically** — no preset selection from a fixed list of project types, no preset partition shape.

### Changed

- `skills/harness-init/SKILL.md` — Q1, Q4, Step 4 (Copy template files) updated for the three-option flow.
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` — Stop hook + `pwsh` / `bash` permissions added.
- `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl` — rule #7 updated, rule #8 added.
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` — Chinese counterpart updated to match.
- Dogfood: this repo's `.claude/settings.json`, `CLAUDE.md`, and `.harness/rules/00-core.md` regenerated via `sync-self` + `harness-sync`.

### Tests

- test-init: 108/108 PASS.
- test-real-project: 78/78 PASS.
- verify_all: 19/19 PASS.

## [0.8.1] - 2026-05-16

### Fixed — Visible "GENERATED FILE" warning on synced artifacts

Triggered by user feedback: "do I have to maintain CLAUDE.md and `.github/copilot-instructions.md` in parallel?"

The answer was **no, already since v0.2 there's only one source of truth (`.harness/rules/`) and `harness-sync` generates both files**. But the previous warning was an **HTML comment** (`<!-- generated -->`) which is invisible in rendered Markdown (GitHub previews, IDE viewers). Easy to miss → easy to accidentally edit the generated file → drift gets caught by verify_all but only later.

Fix: warning is now a Markdown **blockquote with ⚠️ emoji**, visible everywhere:

```markdown
> ⚠️ **GENERATED FILE — DO NOT EDIT DIRECTLY**
>
> Source of truth: `.harness/rules/*.md` (composed in filename order)
> After editing the source, run `scripts/harness-sync.ps1` (or `.sh`) to regenerate.
> `verify_all` will FAIL if this file drifts from the source.
```

Appears at the top of both `CLAUDE.md` and `.github/copilot-instructions.md`. The HTML comment is kept below it as a sentinel for tooling.

### Changed

- `scripts/harness-sync.{ps1,sh}` (in templates) emit the new visible warning.
- `test-init` assertion updated to match the new marker text ("GENERATED FILE" instead of the old "THIS FILE IS GENERATED").
- Dogfood: this repo's CLAUDE.md and .github/copilot-instructions.md regenerated with the visible warning.

### Tests

- test-init: 108/108 PASS.
- test-real-project: 78/78 PASS.
- verify_all: 19/19 PASS.

### Architectural clarification

To recap the source-of-truth model in this project (for future readers who hit the same question):

```
.harness/rules/*.md        ← YOU EDIT THIS (single source of truth)
    │
    │  harness-sync.ps1/.sh generates ↓
    │
    ├──> CLAUDE.md                            (Claude Code reads this fixed name)
    └──> .github/copilot-instructions.md      (Copilot reads this fixed name)
```

Both target filenames are fixed by the respective tools (Claude Code mandates `CLAUDE.md`, Copilot mandates `.github/copilot-instructions.md`). We cannot make them read the same file — but we can keep them perfectly in sync from a single source. That's the whole point of the binding layer.

## [0.8.0] - 2026-05-16

### Added — Tool handoff protocol (Claude Code ↔ Copilot)

Direct response to a real workflow: developer hits Claude Code's 5-hour limit mid-task; wants to continue in GitHub Copilot; later switches back to Claude Code when the quota refreshes — without losing context.

New rule fragment `.harness/rules/60-tool-handoff.md` (synced into both `CLAUDE.md` and `.github/copilot-instructions.md`) defines the cross-tool protocol:

**Core principle**: all task state lives in **files**, not in chat memory. The recoverable state is `docs/tasks.md` + `docs/features/<task>/01..07_*.md` + `PM_LOG.md` + `.harness/agents/*.md` + `.harness/rules/*.md`.

### How a handoff works in practice

1. **In Claude Code** — Task is in flight, e.g. `dev-backend` working on stage 4. User about to hit rate limit. Whoever's working writes a `PARTIAL.md` if mid-stage, appends a `PM_LOG.md` line "handoff at stage X · next: Y by agent Z", ensures `docs/tasks.md` stage is current.
2. **Switch to Copilot in VS Code** — User says "continue task T-001". Copilot reads `.github/copilot-instructions.md` → finds the tool-handoff protocol → reads `docs/tasks.md` → finds the in-flight task → reads `PM_LOG.md` last entry → reads existing 01..06 docs → reads `.harness/agents/<next-role>.md` → **assumes that role personally** → produces next stage's doc → updates `tasks.md` and `PM_LOG.md`. **One role at a time** — Copilot does not auto-route to a different role; user does that.
3. **Switch back to Claude Code** — PM Orchestrator reads same state files → resumes routing.

### Hard rules across all tools (also in the new fragment)

- All AI tools read `docs/tasks.md` and `PM_LOG.md` first when "resume" is requested.
- Sub-agent stages cannot be skipped on resume. If Gate Review document is missing, do that before Development.
- No agent edits upstream documents (Reviewer never edits the requirement, etc.) — this constraint survives tool switches.
- The "Output language" policy (v0.7.0) carries through — a Chinese project gets Chinese output from both Claude Code and Copilot in resume mode too.

### Copilot-specific note

Copilot has no sub-agent dispatch. When it finishes its current stage in resume mode, it **stops and asks the user** rather than silently moving to another role. Cross-stage routing goes through the user (who'll typically switch back to Claude Code or manually tell Copilot to assume the next role). This is intentional — preserves the "one agent, one job" discipline even when sub-agent infrastructure isn't available.

### Tests

- verify_all: 19/19 still PASS (no script changes, just a new rule file going through sync).
- test-init: 108/108 still PASS.
- test-real-project: 78/78 still PASS.
- Dogfood: this repo now has `.harness/rules/60-tool-handoff.md`, and the generated `CLAUDE.md` + `.github/copilot-instructions.md` include the protocol.

### Out of scope (future)

- Automatic `/harness-handoff` skill to generate a "handoff brief" — for v0.9 if user demand surfaces.
- Automatic `/harness-resume` skill to streamline the manual "continue task T-XXX" prompt — same.

## [0.7.1] - 2026-05-16

### Added — GitHub Copilot co-existence (minimal binding)

A user using **GitHub Copilot in the same repo as Claude Code** now gets project rules automatically. `harness-sync` (the binding layer) now emits two artifacts from a single `.harness/rules/` source:

  - `CLAUDE.md`  (Claude Code reads at session start)
  - `.github/copilot-instructions.md`  (Copilot reads as project-wide custom instructions)

Both files share the same composed rules body; only the frontmatter differs (Copilot requires `applyTo: "**"` per its schema). The "Output language" policy from v0.7.0 therefore applies to both tools — pick zh in init, both Claude Code and Copilot output Chinese.

### What this enables

Same repo, two contributors:
  - Alice uses Claude Code → reads CLAUDE.md + has access to 7-agent pipeline
  - Bob uses VS Code + GitHub Copilot → reads .github/copilot-instructions.md (same rules)

Both pick up the project's hard rules, conventions, and output-language policy.

### What this does NOT enable (Phase 2 candidates)

- **7-agent pipeline in Copilot**: Copilot has `.agent.md` + `handoffs` (different schema). The Claude Code sub-agents are not mirrored as Copilot custom agents in v0.7.1. Copilot users get rules-level guidance but no automatic 7-stage flow.
- **Skills mirror**: `.claude/skills/` content is not yet mirrored to Copilot prompt files (`.prompt.md`).
- **Agent role files**: `.harness/agents/*.md` stay Claude Code-specific in v0.7.1.

These are well-defined future work, deferred until real user demand surfaces.

### Tests

- test-init: 104 → 108 assertions (+4: copilot-instructions.md presence + frontmatter for both fullstack/backend).
- test-real-project: 76 → 78 (+2 similar).
- verify_all: 19/19 still PASS.
- harness-sync now also emits .github/copilot-instructions.md in this repo (dogfood).

### Upgrading

Existing v0.7.0 (or earlier) projects: just re-run `scripts/harness-sync.{ps1,sh}` after updating the script (or after re-installing harness-kit plugin). It auto-creates `.github/copilot-instructions.md` from existing `.harness/rules/`.

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
