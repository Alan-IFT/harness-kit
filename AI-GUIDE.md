# AI-GUIDE — harness-kit project index

> Claude-native by default; `--portable` for tool-agnostic/offline use. Any AI tool reads this **before starting a task**.

## Project

This is **harness-kit** itself — a Claude Code Plugin that distributes 15 skills + templates for AI-driven development under the Harness Engineering methodology. The repo **dogfoods** its own design: the same canonical 7-agent pipeline (plus the v0.17+ auxiliary supervisor) that we ship to users governs work here.

Stack: Markdown (skills, agent definitions, docs) + PowerShell + Bash (verify_all, install, sync scripts).

## Source of truth (in this repo, version-controlled)

- `agents/*.md` — the 7 framework agents + 1 auxiliary (supervisor), shipped **plugin-native** (auto-discovered, dispatched as `harness-kit:<name>`); this is the single source — edit here directly (no sync)
- `.harness/rules/*.md` — rule fragments (project-specific dogfood rules)
- `.harness/agents/*.md` — **only** project-specific partition `dev-*` agents (empty in this repo; partition agents live under `skills/harness-init/templates/<type>/.harness/agents/dev-*.md.tmpl`)
- `skills/harness-init/templates/` — the distribution: what users get when they install the plugin

**Do not directly edit** `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` — they are tool-specific stubs or generated bindings.

## Rule fragments (read by "when to read")

- **`.harness/rules/00-core.md`** (**always**): this repo's identity (tooling library + Claude Code Plugin), how development flows, trivial vs non-trivial
- **`.harness/rules/05-insight-index.md`** (**at the start of design/implementation tasks**): how cross-task hard-won truths are captured in `.harness/insight-index.md`; read `insight-index.md` itself before deciding anything non-trivial
- **`.harness/rules/10-self-consistency.md`** (**when touching `templates/`, `.harness/`, or .harness/scripts/sync-self**): the two consistency layers (templates ↔ this repo, `.harness` ↔ `.claude`/`CLAUDE.md`)
- **`.harness/rules/15-skill-authoring.md`** (**when authoring or changing a skill or agent**): the quality bar for `skills/<name>/SKILL.md` + the framework `agents/*.md` (plugin-native) + partition `.harness/agents/dev-*.md` — model-facing descriptions, a Gotchas/anti-patterns surface, progressive disclosure, and what we deliberately don't do (distilled from Anthropic's "how we use skills")
- **`.harness/rules/20-documentation.md`** (**when touching README / CHANGELOG / docs**): doc-sync rules, what README must reference
- **`.harness/rules/25-decision-policy.md`** (**load when you would ask the user / call `AskUserQuestion`**): the decision & escalation policy — Mode 1 (human decides, default) vs Mode 2 (preset-rubric autonomy) vs Mode 3 (user-custom rubric) + the always-escalate red lines; switch with `/harness-decision-mode`. **This repo runs Mode 2 (balanced)** — decide per `.harness/decision-rubric.md` (Preset section), escalate the red lines, log each autonomous call. (This one-line flag is the only always-read part; the full policy + rubric load on-demand at a decision point.)
- **`.harness/rules/30-engineering.md`** (**before commits**): commit message conventions, file hygiene, no secrets, PS/Bash symmetry
- **`.harness/rules/40-locations.md`** (**when looking for "where does X live"**): file-location lookup table (read this if you'd otherwise guess a path)
- **`.harness/rules/60-tool-handoff.md`** (**when switching Claude Code ↔ Copilot or other tools**): state lives in files, doc-sync responsibility for non-Claude tools
- **`.harness/rules/65-intervention.md`** (**when running, observing, or redirecting any `/harness*` task**): `.harness/intervention.md` is a single-shot signal file (STOP / REDIRECT / SKIP / NOTE) that PM consumes at every stage boundary
- **`.harness/rules/70-doc-size.md`** (**when adding or reviewing long-lived docs, or when `verify_all` flags an `I.*` WARN**): soft caps on AI-GUIDE / rules / agents / insight-index / tasks.md / per-task docs; "reference don't paste" + PM_LOG compaction + always-archive discipline
- **`.harness/rules/75-safety-hook.md`** (**when running, observing, or disabling the destructive-command guardrail**): `PreToolUse` hook on Bash tool calls; blocks destructive commands targeting paths outside the `.git/` ancestor of cwd; override `HARNESS_ALLOW_OUTSIDE_RM=1`.
- **`.harness/rules/80-settings-schema.md`** (**before editing `.claude/settings.json` or its `.tmpl`**): consult upstream schema via context7/WebFetch first; `verify_all` J.1 catches invalid `hooks` keys and non-canonical `$schema` URL — both real bugs we've shipped.

**Memory layer**:
- **`.harness/insight-index.md`** — ≤30 evidence-backed lines of project-specific facts. Read at task start; append at task end (only with evidence). Never edit other people's lines.
- **`.harness/decision-rubric.md`** — the operator-authored principles the AI decides by under Mode 2 (see `25-decision-policy.md`). Read at every escalate-or-decide point; the operator edits it to widen / narrow autonomy.

Before declaring any task complete, run `.harness/scripts/verify_all` and confirm all PASS checks are green (32/32; check count grows with releases) — this is the gate, not a rule fragment.

If you add a new fragment to `.harness/rules/`, append a line above with its filename, a 1-line description, and the trigger condition.

## Agents (Claude Code Task tool / Copilot manual role-play)

The **7 framework agents (+ supervisor)** are provided by the harness-kit plugin as `harness-kit:<name>` (top-level `agents/*.md` is the single source — edit there directly, no sync). Only project-specific **partition `dev-*` agents** live in `.harness/agents/` (none in this repo). Read a contract on demand when assuming or dispatching to a role.

- `harness-kit:pm-orchestrator` — takes new tasks, routes
- `harness-kit:requirement-analyst` → `harness-kit:solution-architect` → `harness-kit:gate-reviewer` → `harness-kit:developer` → `harness-kit:code-reviewer` → `harness-kit:qa-tester`

**Claude Code sub-agent dispatch — already implemented.** PM Orchestrator uses Claude Code's `Task` tool to spawn each downstream role in its own context; see `agents/pm-orchestrator.md` for the exact contract and the dispatch call sites (generics dispatched as `harness-kit:<name>`; partition `dev-*` are project-local). Copilot and other tools have no equivalent API, so they fall back to one-role-at-a-time manual role-play (the user names the next role).

## AI tool flow modes

Three flows are supported, picked by the tool the user is in:

- **Claude Code automatic sub-agent dispatch** (default for Claude Code): PM Orchestrator hands off through stages 1 → 7 via the `Task` tool; no user intervention required between stages.
- **Copilot / Cursor manual one-role-at-a-time** (default for those tools): Copilot reads the framework agent contract from the plugin's `agents/<role>.md` (or a `--portable` local copy under `.harness/agents/`), plays exactly that role, stops at the stage boundary, asks the user to "switch to next agent". One stage per user turn.
- **Copilot opt-in continuous mode**: the user types the activation phrase `continuous mode` (English) or `走全流程` (Chinese) in a plain user turn; Copilot then self-dispatches through stages 1 → 2 → 3, **STOPs unconditionally after Gate Review** (regardless of verdict), and waits for the user's "continue" before proceeding to stages 4-7. Continuous mode resets at every chat-session boundary. See `.harness/rules/60-tool-handoff.md` for the activation contract.

## Project documents

- `docs/workflow.md` — full 7-stage pipeline definition
- `docs/dev-map.md` — where each part of this repo lives
- `docs/concepts.md` — why each piece exists
- `docs/getting-started.md` — quick onboarding for contributors
- `docs/walkthrough.html` — full user-flow demo (HTML)
- `architecture.html` — visualized architecture and evolution
- `docs/project-overview.html` — project identity, usage scenarios, version milestones (HTML, v0.17.0 snapshot)

## Scripts (the moving parts)

- `.harness/scripts/verify_all.{ps1,sh}` — total verification (32 checks, including I.1-I.5 doc-size WARN guards + F.2 guard-rm wiring + I.6 gap-tolerant retired-claim guard + I.7 ignored-INTERVENE-report guard + D.3 AI-generated 50-*.md sanity + J.1 settings.json schema integrity). **Must PASS before declaring done.**
- `.harness/scripts/harness-sync.{ps1,sh}` — copy `.harness/agents/` (partition `dev-*` only since v0.30; framework agents are plugin-provided) + `.harness/skills/` to `.claude/`. v0.10 narrow scope.
- `.harness/scripts/sync-self.{ps1,sh}` — keep this repo's 7 dogfood script pairs (harness-sync, install-hooks, archive-task, guard-rm, migrate-scripts-layout, upgrade-project, language-policy) byte-identical with `templates/common/`. **No longer mirrors agents** (framework agents are edited directly in the plugin-native top-level `agents/` since v0.30) and **does NOT sync `.harness/rules/` — those are bespoke per repo.**
- `.harness/scripts/install-hooks.{ps1,sh}` — one-shot installer for `.git/hooks/pre-commit` (runs `harness-sync --check`).
- `.harness/scripts/archive-task.{ps1,sh}` — archive a completed task: harvest `## Insight` section from 07_DELIVERY.md to `.harness/insight-index.md`, move 7 stage docs to `docs/features/_archived/<task>/`, rotate old insights to `docs/features/_archived/insight-history.md` if >30 lines.
- `.harness/scripts/test-init.{ps1,sh}` — regression for `/harness-init` on empty dirs.
- `.harness/scripts/test-real-project.{ps1,sh}` — regression overlaying templates on real fixtures.
- `.harness/scripts/test-supervisor.{ps1,sh}` — regression for the supervisor agent + `/harness-supervise` skill (v0.17+).
- `.harness/scripts/test-verify-i6.{ps1,sh}` — regression for the `verify_all` I.6 gap-tolerant retired-claim matcher (v0.18+).
- `.harness/scripts/ambient-prompt.{ps1,sh}` — `UserPromptSubmit` heartbeat hook for `/harness-stream` ambient mode (v0.22+). No-op unless `.harness/ambient.flag` exists; when present it injects an ingest+drain instruction. Pwsh command needs `-NoProfile`. Not in `sync-self`'s mirror set — dogfood + template copies are maintained in lockstep by hand.
- `.harness/scripts/ambient-reset.{ps1,sh}` — `SessionStart` hook for `/harness-stream` ambient mode: deletes `.harness/ambient.flag` at the start of every new session so ambient is session-scoped (no "off" keyword). Pwsh command needs `-NoProfile`. Not in `sync-self`'s mirror set — dogfood + template copies maintained in lockstep by hand.

## Workflow entry — pick the right mode

| Mode | Use when (English triggers) | Use when (中文触发) | Skill |
|---|---|---|---|
| Full 7-stage pipeline | "Add X" / "Fix bug Y" / "Refactor Z to ..." — real shipping work | "加一个 ..." / "修个 bug" / "重构成 ..." | `/harness` |
| Plan only (stages 1-3) | "Vet this design" / "evaluate the approach before coding" | "评审一下..." / "先别动手" / "设计上行不行" | `/harness-plan` |
| Explore / feasibility | "Can we do X?" / "Is library Y feasible?" — research | "能不能..." / "可行吗" / "调研一下" | `/harness-explore` |
| Goal loop (Dev + QA) | "Keep improving until X" / "iterate to N% coverage" | "持续优化到..." / "循环改进直到..." | `/harness-goal` |
| Batch (list of tasks) | "Run T-01...T-NN as a batch" / "batch the backlog" | "批量跑 T-01~T-09" / "把这批一起跑了" | `/harness-batch` |
| Stream (living pool) | "keep draining a pool I keep adding to" / "fire tasks at me as I think of them, just watch results" | "边开发边不断加任务" / "想到啥需求就丢进去，只看结果" | `/harness-stream` |
| Trivial | Typo, comment, single-line dependency bump | typo / 注释 / 改个变量名 | Direct edit + `.harness/scripts/verify_all` |
| Mid-task redirect | "stop the pipeline" / "tell dev to skip X" / "leave a note for QA" | "停一下" / "让 dev 别动 X" / "顺便告诉 QA…" | `/harness-intervene` |
| Upgrade an old project | "bring my old harness project up to date" / "the scripts are in the old `scripts/` layout" | "把旧的 harness 项目升级到最新" / "脚本还在旧的 scripts/ 目录" | `/harness-upgrade` |
| Set / switch / refresh project language | "make this project English" / "switch to Chinese output" / "refresh the language policy" | "切到中文输出" / "改成英文" / "刷新语言策略" | `/harness-language` |
| Switch decision/escalation mode | "let the AI decide on its own" / "make it ask me first" / "use my own decision rules" | "切换决策模式" / "让 AI 自己拿主意" / "改成人工决策" / "用我自己的决策规则" | `/harness-decision-mode` |

Declare-done gate (**all non-trivial modes**): `.harness/scripts/verify_all` PASS + (if 7-stage or goal) QA's `06_TEST_REPORT.md` has an `## Adversarial tests` section.

## Editing rules

- To change a rule: edit the relevant `.harness/rules/*.md` fragment. **No sync needed.** AI tools follow the reference from this file.
- To change a **framework** agent: edit the plugin-native `agents/<name>.md` (top-level) directly — no sync (Claude Code auto-discovers `harness-kit:<name>`). To change a **skill** or a **partition** `dev-*` agent: edit `.harness/skills/<name>/SKILL.md` or `.harness/agents/dev-<name>.md`, then run `.harness/scripts/harness-sync` so `.claude/` picks it up. The Stop hook in `.claude/settings.json` does this automatically at session end.
- To change a template: edit `skills/harness-init/templates/common/` (or `<type>/` overlay), then run `.harness/scripts/sync-self` to update this repo's dogfood, then `harness-sync`.

No regeneration of `AI-GUIDE.md`, `CLAUDE.md`, or `.github/copilot-instructions.md`. They reference `.harness/`; updates flow by reference.
