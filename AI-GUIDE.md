# AI-GUIDE — harness-kit project index

> harness-kit is a Claude Code plugin (Claude-native). Any AI tool reads this **before starting a task**.

## Project

This is **harness-kit** itself — a Claude Code Plugin that distributes 17 skills + templates for AI-driven development under the Harness Engineering methodology. The repo **dogfoods** its own design: the same canonical 7-agent pipeline (plus the v0.17+ auxiliary supervisor) that we ship to users governs work here.

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
- **`.harness/rules/70-doc-size.md`** (**when adding or reviewing long-lived docs, when writing any section of a stage doc, or when `verify_all` flags an `I.*` WARN**): soft caps on AI-GUIDE / rules / agents / insight-index / tasks.md / per-task docs; "reference don't paste" + PM_LOG compaction + always-archive discipline + the stage-doc contract/rationale boundary rule
- **`.harness/rules/75-safety-hook.md`** (**when running, observing, or disabling the destructive-command guardrail**): `PreToolUse` hook on Bash tool calls; blocks destructive commands targeting paths outside the `.git/` ancestor of cwd; override `HARNESS_ALLOW_OUTSIDE_RM=1`.
- **`.harness/rules/80-settings-schema.md`** (**before editing `.claude/settings.json` or its `.tmpl`**): consult upstream schema via context7/WebFetch first; `verify_all` J.1 catches invalid `hooks` keys and non-canonical `$schema` URL — both real bugs we've shipped.

**Memory layer**:
- **`.harness/insight-index.md`** — ≤30 evidence-backed entries of project-specific facts (an entry is one bullet plus any lines wrapped under it). Read at task start; append at task end (only with evidence). Never edit other people's entries.
- **`.harness/decision-rubric.md`** — the operator-authored principles the AI decides by under Mode 2 (see `25-decision-policy.md`). Read at every escalate-or-decide point; the operator edits it to widen / narrow autonomy.
- **`CONTEXT.md`** (repo root) — the project's domain glossary: tight definitions + `_Avoid_` synonyms for project-specific terms. Read it when naming modules/files/symbols or writing a requirement/design so naming stays canonical; maintain it inline when you coin or sharpen a term. Absent is fine — it is a convenience, not a gate.
- **`.harness/rejected-decisions.md`** — deliberately-declined requests/approaches + why (the fourth memory kind: declined options, distinct from truths / autonomy principles / glossary). Read it at a non-trivial decide-point before proposing a new approach/feature; append a record when something is deliberately declined. The habit is governed by `25-decision-policy.md`. Absent is fine — a convenience, not a gate.
- **`.harness/operator-obligations.md`** — the release-gating **operator obligations** (the fifth memory kind: outstanding human duties). Each entry carries one step a human operator must perform on a host this repo's agents cannot reach — almost all of it PowerShell — with its artifacts, pass observable, security marking, origin and discharge record. Not on any always-read path: read it before a release tag, and append a new obligation there with the next unused id — never into `.harness/scripts/baseline.json`, which pins numeric baselines only.

Before declaring any task complete, run `.harness/scripts/verify_all` and confirm all PASS checks are green (35/35; check count grows with releases) — this is the gate, not a rule fragment.

If you add a new fragment to `.harness/rules/`, append a line above with its filename, a 1-line description, and the trigger condition.

## Agents (Claude Code Task tool)

The **7 framework agents (+ supervisor)** are provided by the harness-kit plugin as `harness-kit:<name>` (top-level `agents/*.md` is the single source — edit there directly, no sync). Only project-specific **partition `dev-*` agents** live in `.harness/agents/` (none in this repo). Read a contract on demand when assuming or dispatching to a role.

- `harness-kit:pm-orchestrator` — takes new tasks, routes
- `harness-kit:requirement-analyst` → `harness-kit:solution-architect` → `harness-kit:gate-reviewer` → `harness-kit:developer` → `harness-kit:code-reviewer` → `harness-kit:qa-tester`

**Claude Code sub-agent dispatch — already implemented.** PM Orchestrator uses Claude Code's `Task` tool to spawn each downstream role in its own context; see `agents/pm-orchestrator.md` for the exact contract and the dispatch call sites (generics dispatched as `harness-kit:<name>`; partition `dev-*` are project-local). Non-Claude tools have no equivalent dispatch API and — since the framework agents are plugin-native (`harness-kit:<name>`), not materialized locally — are not currently first-class for the framework agents.

## AI tool flow modes

The framework agents are **plugin-native** (`harness-kit:<name>`, auto-discovered by Claude Code). Since v0.30 they are **not** materialized into a project's local `.harness/agents/`, so the canonical pipeline runs on Claude Code:

- **Claude Code automatic sub-agent dispatch** (the supported flow): PM Orchestrator hands off through stages 1 → 7 via the `Task` tool; no user intervention required between stages.
- **Non-Claude tools (Copilot / Cursor) — not currently first-class for the framework agents**: the framework agents are plugin-provided to Claude Code and aren't available as local files, so the old "read `.harness/agents/<role>.md` and play the role manually" flow no longer works for the framework roles. A generated project still gives these tools the rules, skills, and project-specific partition `dev-*` agents they can read; the multi-stage framework pipeline is a Claude Code feature. See `.harness/rules/60-tool-handoff.md` for what state lives in files and how to hand off.

## Project documents

- `docs/workflow.md` — full 7-stage pipeline definition
- `docs/dev-map.md` — where each part of this repo lives
- `docs/concepts.md` — why each piece exists
- `docs/getting-started.md` — quick onboarding for contributors
- `docs/walkthrough.html` — full user-flow demo (HTML)
- `architecture.html` — visualized architecture and evolution
- `docs/project-overview.html` — project identity, usage scenarios, version milestones (HTML, v0.17.0 snapshot)

## Scripts (the moving parts)

Every script's header states its own contract. This is the index, not a restatement.

- `verify_all.{ps1,sh}` — total verification (35 checks). **Must PASS before declaring done.**
- `guard-rm.{ps1,sh}` — destructive-command `PreToolUse` guard. **fail-CLOSED**; see `.harness/rules/75-safety-hook.md`.
- `hook-spec.{ps1,sh}` — the single source for `(hook tool x target OS) -> command byte-form`, plus each tool's event, matcher and fail-open/closed semantics. Pure; no I/O.
- `install-hooks.{ps1,sh}` — installs `.git/hooks/pre-commit`; bootstraps a missing `.claude/settings.local.json` from `hook-spec` only when nothing is wired. Never overwrites an existing file.
- `harness-sync.{ps1,sh}` — copy `.harness/agents/` + `.harness/skills/` into `.claude/`.
- `sync-self.{ps1,sh}` — hold this repo dogfood scripts byte-identical with `templates/common/`. Does **not** sync `.harness/rules/` — those are bespoke per repo.
- `archive-task.{ps1,sh}` — archive a completed task: harvest its `## Insight` section into `.harness/insight-index.md`, rotate past 30 entries into `docs/features/_archived/insight-history.md`, move the stage docs.
- `doc-query.js` — return the UNITS of a document that answer a question, never the document: `--in memory|stage|rules` for a term, `--for <role> --task <slug>` for the stage-contract sections addressed to a role. A term search spends at most 32 KB and reports the units it did not print; a finished task is searchable by its `07_DELIVERY.md` until `--task <slug>` or `--archived` opens the rest of it.
- `stage-schema.js` — which section of which stage contract each role reads (`--map`), whether a task's stage documents use only their declared sections (`--lint`), and whether the table still matches the authoring contracts (`--check`, `verify_all` D.6).
- `task-state.js` — the per-task ledger (`.harness/state/<slug>.json`): stage, rollback counts, verdicts. PM writes; everyone else reads.
- `capability-audit.js` — cross-check what each agent contract instructs against what its `tools:` line grants (`verify_all` D.4).
- `test-*.{ps1,sh}` — one regression driver per subject; run `bash .harness/scripts/test-<name>.sh`.
- `entropy-cadence`, `ambient-prompt`, `ambient-reset`, `language-policy`, `upgrade-project`, `migrate-scripts-layout` — support the like-named skills.

**TypeScript**: every `.js` above is implemented in `src/*.ts` and compiled to
`.harness/scripts/` and committed; where a `.sh` / `.ps1` still stands beside one it is a
two-line launcher holding no logic. After editing `src/`, run `npm run build`, then
`npm test` (270 unit tests), then copy any changed `.js` into
`skills/harness-init/templates/common/.harness/scripts/` for the ones that ship. See
`docs/proposals/v2-ts-migration.md`.

## Workflow entry — pick the right mode

Every mode is a skill, and Claude Code already carries all 17 skill descriptions in the
session prompt — each with its own English and Chinese triggers and its "NOT /other-skill"
disambiguation. Restating them here was a second copy that nothing kept in sync. Describe
the work and the right skill is selected; `/harness` is the full 7-stage pipeline and the
rest narrow it (`-plan` stages 1-3 only, `-explore` research, `-goal` a Dev+QA loop,
`-batch` / `-stream` a task pool, `-grill` a pre-pipeline interview).

Trivial work — a typo, a comment, a single-line dependency bump — takes no skill: edit
directly, then run `.harness/scripts/verify_all`.

Declare-done gate (**all non-trivial modes**): `.harness/scripts/verify_all` PASS + (if
7-stage or goal) QA's `06_TEST_REPORT.md` has an `## Adversarial tests` section.

## Editing rules

- To change a rule: edit the relevant `.harness/rules/*.md` fragment. **No sync needed.** AI tools follow the reference from this file.
- To change a **framework** agent: edit the plugin-native `agents/<name>.md` (top-level) directly — no sync (Claude Code auto-discovers `harness-kit:<name>`). To change a **skill** or a **partition** `dev-*` agent: edit `.harness/skills/<name>/SKILL.md` or `.harness/agents/dev-<name>.md`, then run `.harness/scripts/harness-sync` so `.claude/` picks it up. A Stop hook runs `harness-sync` automatically at session end; a project generated by `/harness-init` ships that hook in its committed `.claude/settings.json`, while this repo keeps its own wiring machine-local — `/harness-status` §0 "Effective hook source" reports which file a given project actually loads it from.
- To change a template: edit `skills/harness-init/templates/common/` (or `<type>/` overlay), then run `.harness/scripts/sync-self` to update this repo's dogfood, then `harness-sync`.

No regeneration of `AI-GUIDE.md`, `CLAUDE.md`, or `.github/copilot-instructions.md`. They reference `.harness/`; updates flow by reference.
