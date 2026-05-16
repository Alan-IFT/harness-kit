# AI-GUIDE — harness-kit project index

> Tool-agnostic entry. Any AI tool (Claude Code, GitHub Copilot, Cursor, …) reads this **before starting a task**.

## Project

This is **harness-kit** itself — a Claude Code Plugin that distributes 4 skills + templates for AI-driven development under the Harness Engineering methodology. The repo **dogfoods** its own design: the same 7-agent pipeline that we ship to users governs work here.

Stack: Markdown (skills, agent definitions, docs) + PowerShell + Bash (verify_all, install, sync scripts).

## Source of truth (in this repo, version-controlled)

- `.harness/rules/*.md` — rule fragments (project-specific dogfood rules)
- `.harness/agents/*.md` — 7 agent role contracts (byte-identical to `templates/common/.harness/agents/`)
- `skills/harness-init/templates/` — the distribution: what users get when they install the plugin

**Do not directly edit** `.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md` — they are tool-specific stubs or generated bindings.

## Rule fragments (read by "when to read")

- **`.harness/rules/00-core.md`** (**always**): this repo's identity (tooling library + Claude Code Plugin), how development flows, trivial vs non-trivial
- **`.harness/rules/05-insight-index.md`** (**at the start of design/implementation tasks**): how cross-task hard-won truths are captured in `.harness/insight-index.md`; read `insight-index.md` itself before deciding anything non-trivial
- **`.harness/rules/10-self-consistency.md`** (**when touching `templates/`, `.harness/`, or scripts/sync-self**): the two consistency layers (templates ↔ this repo, `.harness` ↔ `.claude`/`CLAUDE.md`)
- **`.harness/rules/20-documentation.md`** (**when touching README / CHANGELOG / docs**): doc-sync rules, what README must reference
- **`.harness/rules/30-engineering.md`** (**before commits**): commit message conventions, file hygiene, no secrets, PS/Bash symmetry
- **`.harness/rules/40-locations.md`** (**when looking for "where does X live"**): file-location lookup table (read this if you'd otherwise guess a path)
- **`.harness/rules/60-tool-handoff.md`** (**when switching Claude Code ↔ Copilot or other tools**): state lives in files, doc-sync responsibility for non-Claude tools
- **`.harness/rules/65-intervention.md`** (**when running, observing, or redirecting any `/harness*` task**): `.harness/intervention.md` is a single-shot signal file (STOP / REDIRECT / SKIP / NOTE) that PM consumes at every stage boundary
- **`.harness/rules/70-doc-size.md`** (**when adding or reviewing long-lived docs, or when `verify_all` flags an `I.*` WARN**): soft caps on AI-GUIDE / rules / agents / insight-index / tasks.md / per-task docs; "reference don't paste" + PM_LOG compaction + always-archive discipline

**Memory layer**:
- **`.harness/insight-index.md`** — ≤30 evidence-backed lines of project-specific facts. Read at task start; append at task end (only with evidence). Never edit other people's lines.

Before declaring any task complete, run `scripts/verify_all` and confirm 19/19 PASS — this is the gate, not a rule fragment.

If you add a new fragment to `.harness/rules/`, append a line above with its filename, a 1-line description, and the trigger condition.

## Agents (Claude Code Task tool / Copilot manual role-play)

Full contracts in `.harness/agents/<name>.md`. Read on demand when assuming or dispatching to a role.

- `pm-orchestrator` — takes new tasks, routes
- `requirement-analyst` → `solution-architect` → `gate-reviewer` → `developer` → `code-reviewer` → `qa-tester`

## Project documents

- `docs/workflow.md` — full 7-stage pipeline definition
- `docs/dev-map.md` — where each part of this repo lives
- `docs/concepts.md` — why each piece exists
- `docs/getting-started.md` — quick onboarding for contributors
- `docs/walkthrough.html` — full user-flow demo (HTML)
- `architecture.html` — visualized architecture and evolution

## Scripts (the moving parts)

- `scripts/verify_all.{ps1,sh}` — total verification (19 checks). **Must PASS before declaring done.**
- `scripts/harness-sync.{ps1,sh}` — copy `.harness/agents/` + `.harness/skills/` to `.claude/`. v0.10 narrow scope.
- `scripts/sync-self.{ps1,sh}` — keep this repo's dogfood `.harness/agents/` + 4 script pairs (harness-sync, install-hooks, archive-task) byte-identical with `templates/common/`. **Does NOT sync `.harness/rules/` — those are bespoke per repo.**
- `scripts/install-hooks.{ps1,sh}` — one-shot installer for `.git/hooks/pre-commit` (runs `harness-sync --check`).
- `scripts/archive-task.{ps1,sh}` — archive a completed task: harvest `## Insight` section from 07_DELIVERY.md to `.harness/insight-index.md`, move 7 stage docs to `docs/features/_archived/<task>/`, rotate old insights to `docs/features/_archived/insight-history.md` if >30 lines.
- `scripts/test-init.{ps1,sh}` — regression for `/harness-init` on empty dirs.
- `scripts/test-real-project.{ps1,sh}` — regression overlaying templates on real fixtures.

## Workflow entry — pick the right mode

| Mode | Use when (English triggers) | Use when (中文触发) | Skill |
|---|---|---|---|
| Full 7-stage pipeline | "Add X" / "Fix bug Y" / "Refactor Z to ..." — real shipping work | "加一个 ..." / "修个 bug" / "重构成 ..." | `/harness` |
| Plan only (stages 1-3) | "Vet this design" / "evaluate the approach before coding" | "评审一下..." / "先别动手" / "设计上行不行" | `/harness-plan` |
| Explore / feasibility | "Can we do X?" / "Is library Y feasible?" — research | "能不能..." / "可行吗" / "调研一下" | `/harness-explore` |
| Goal loop (Dev + QA) | "Keep improving until X" / "iterate to N% coverage" | "持续优化到..." / "循环改进直到..." | `/harness-goal` |
| Trivial | Typo, comment, single-line dependency bump | typo / 注释 / 改个变量名 | Direct edit + `scripts/verify_all` |
| Mid-task redirect | "stop the pipeline" / "tell dev to skip X" / "leave a note for QA" | "停一下" / "让 dev 别动 X" / "顺便告诉 QA…" | `/harness-intervene` |

Declare-done gate (**all non-trivial modes**): `scripts/verify_all` PASS + (if 7-stage or goal) QA's `06_TEST_REPORT.md` has an `## Adversarial tests` section.

## Editing rules

- To change a rule: edit the relevant `.harness/rules/*.md` fragment. **No sync needed.** AI tools follow the reference from this file.
- To change an agent or skill: edit `.harness/agents/<name>.md` (or `.harness/skills/<name>/SKILL.md`), then run `scripts/harness-sync` so `.claude/` picks it up. The Stop hook in `.claude/settings.json` does this automatically at session end.
- To change a template: edit `skills/harness-init/templates/common/` (or `<type>/` overlay), then run `scripts/sync-self` to update this repo's dogfood, then `harness-sync`.

No regeneration of `AI-GUIDE.md`, `CLAUDE.md`, or `.github/copilot-instructions.md`. They reference `.harness/`; updates flow by reference.
