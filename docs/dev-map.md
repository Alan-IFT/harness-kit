# Dev Map — Harness Kit repo

> Where things live and the conventions to follow when changing them.

## Top-level layout

```
harness-kit/
├── skills/                              ← Distributed skills (the product)
│   ├── harness-init/
│   │   ├── SKILL.md                    ← Skill entry point
│   │   └── templates/                  ← Project templates (SOURCE OF TRUTH for distribution)
│   │       ├── common/                 ← Shared assets all projects get
│   │       │   ├── .harness/agents/    ← 7 agent definitions (tool-agnostic SOT)
│   │       │   ├── .harness/rules/00-core.md.tmpl       ← base rule fragments
│   │       │   ├── .harness/rules/25-decision-policy.md ← shipped decision policy (v0.28+; GENERIC, Active mode defaults to 1)
│   │       │   ├── .harness/decision-rubric.md          ← shipped rubric (v0.28+; GENERIC universal-default Preset, empty Custom — NOT operator personal prefs)
│   │       │   ├── .harness/rules/_ai-native-prompt.md  ← canonical AI-customization prompt (v0.16+; reference only, indexed by AI-GUIDE.md)
│   │       │   ├── .claude/settings.json.tmpl          ← Claude Code binding glue
│   │       │   ├── docs/workflow.md
│   │       │   ├── docs/dev-map.md.tmpl
│   │       │   ├── docs/tasks.md.tmpl
│   │       │   ├── docs/spec/README.md
│   │       │   ├── .harness/scripts/harness-sync.{ps1,sh}    ← Binding sync (distributed)
│   │       │   ├── .harness/scripts/migrate-scripts-layout.{ps1,sh} ← One-shot scripts/ → .harness/scripts/ upgrade (T-007)
│   │       │   ├── .harness/scripts/upgrade-project.{ps1,sh}    ← /harness-upgrade mechanical layer (T-012)
│   │       │   ├── .harness/scripts/language-policy.{ps1,sh}    ← /harness-language mechanical layer (T-014): heading-anchored policy-section + line rewrite; zh source = i18n/zh/_policy snippet (T-016), en source = common/ inline; also drives zh-init composition (init step 4.4)
│   │       │   ├── .harness/scripts/ai-native-mock.json     ← Mock AI response for HARNESS_AI_NATIVE_MOCK (v0.16+; test & dry-run)
│   │       │   └── evals/golden-tasks.md.tmpl
│   │       ├── fullstack/              ← Fullstack-only overlays
│   │       │   ├── .harness/rules/50-fullstack.md
│   │       │   ├── .harness/skills/{build,test,verify}/SKILL.md.tmpl
│   │       │   └── .harness/scripts/verify_all.{ps1,sh}.tmpl
│   │       ├── backend/                ← Backend-only overlays
│   │       │   ├── .harness/rules/50-backend.md
│   │       │   ├── .harness/skills/{build,test,verify}/SKILL.md.tmpl
│   │       │   └── .harness/scripts/verify_all.{ps1,sh}.tmpl
│   │       └── i18n/zh/                 ← Chinese language overlay
│   │           ├── common/docs/spec/README.md          ← human-facing (KEEP-ZH)
│   │           ├── common/evals/golden-tasks.md.tmpl   ← human-facing (KEEP-ZH)
│   │           └── _policy/output-language.zh.md.tmpl  ← single-source zh policy (T-016); NOT overlaid — read by language-policy.{ps1,sh}; zh init COMPOSES (lay English common/ + inject this policy)
│   ├── harness-adopt/SKILL.md          ← Existing-project adoption (automated apply since v0.3)
│   ├── harness-upgrade/SKILL.md        ← Upgrade an already-initialized but stale project to the current layout (v0.23+); judgment layer, drives upgrade-project.{ps1,sh}
│   ├── harness-language/SKILL.md       ← Set / switch (en<->zh) / refresh a project's output-language policy (v0.25+); judgment layer, drives language-policy.{ps1,sh}
│   ├── harness-decision-mode/SKILL.md  ← Switch the decision/escalation MODE 1/2/3 (v0.28+); surgical single-line Active-mode rewrite of .harness/rules/25-decision-policy.md + Mode-3 custom-rubric capture; no helper script (direct Edit)
│   ├── harness-verify/SKILL.md         ← Run verify_all
│   ├── harness-status/SKILL.md         ← Show Harness health
│   ├── harness-plan/SKILL.md           ← Stages 1-3 only (design-only)
│   ├── harness-explore/SKILL.md        ← Research / feasibility mode
│   ├── harness-goal/SKILL.md           ← Dev + QA loop bounded by criterion + budget
│   ├── harness/SKILL.md                ← Full 7-stage pipeline
│   ├── harness-intervene/SKILL.md      ← Soft Ctrl-C for an in-flight pipeline
│   ├── harness-supervise/SKILL.md      ← Observer-only auxiliary skill (v0.17+); emits SUPERVISION_REPORT.md
│   ├── harness-batch/SKILL.md          ← Batch mode (v0.19+); runs T-01...T-NN via pm-orchestrator sub-agents from docs/batches/<batch-id>/BATCH_PLAN.md
│   └── harness-stream/SKILL.md         ← Stream / living-pool mode (v0.22+); re-reads BATCH_PLAN.md each iteration, best-effort, picks up mid-run additions
│
├── .harness/                            ← THIS repo's tool-agnostic SOT (dogfood)
│   ├── agents/                         ← byte-copy of templates/common/.harness/agents/
│   │                                      (7 canonical + 1 auxiliary supervisor.md at v0.17+)
│   ├── rules/                          ← repo-specific rule fragments
│   │   ├── 00-core.md
│   │   ├── 05-insight-index.md
│   │   ├── 10-self-consistency.md
│   │   ├── 15-skill-authoring.md       ← Skill/agent authoring quality bar
│   │   ├── 20-documentation.md
│   │   ├── 25-decision-policy.md        ← Decision/escalation policy: Mode 1/2/3 + red lines (v0.28+; dogfood Active mode 2)
│   │   ├── 30-engineering.md
│   │   ├── 40-locations.md
│   │   ├── 60-tool-handoff.md
│   │   ├── 65-intervention.md
│   │   ├── 70-doc-size.md
│   │   ├── 75-safety-hook.md           ← Destructive-command guard (v0.15+)
│   │   └── 80-settings-schema.md       ← settings.json schema integrity (v0.18+)
│   ├── decision-rubric.md              ← Memory layer: principles the AI decides by (Preset=Mode 2 / Custom=Mode 3); read at every escalate-or-decide point (v0.28+)
│   └── scripts/                        ← All harness-owned scripts (relocated from scripts/ in T-007)
│       ├── verify_all.{ps1,sh}         ← Total verification (32 checks)
│       ├── harness-sync.{ps1,sh}       ← Layer 2: .harness/agents + .harness/skills → .claude/
│       ├── sync-self.{ps1,sh}          ← Layer 1: templates/common/ → repo SOT
│       ├── migrate-scripts-layout.{ps1,sh} ← One-shot scripts/ → .harness/scripts/ upgrade (T-007)
│       ├── upgrade-project.{ps1,sh}    ← /harness-upgrade mechanical layer (v0.23+): relocate + content-refresh + settings rewire + hook + verify_all regenerate
│       ├── language-policy.{ps1,sh}    ← /harness-language mechanical layer (v0.25+): heading-anchored policy-section + one-line policy rewrite, .bak, NOOP on byte-identity, en<->zh byte-identical round-trip
│       ├── test-init.{ps1,sh}          ← Init+sync regression on EMPTY dir
│       ├── test-harness-upgrade.{ps1,sh} ← /harness-upgrade regression (v0.23+): synthetic old-fixtures, root-derivation, B.* splice/halt, hook conflict, idempotence
│       ├── test-language.{ps1,sh}      ← /harness-language regression (v0.25+): en<->zh switch, idempotent refresh, dry-run, byte-identical zh->en->zh round-trip, missing-copilot, hand-mangled-heading conflict
│       ├── test-supervisor.{ps1,sh}    ← Supervisor agent + /harness-supervise skill regression
│       ├── test-verify-i6.{ps1,sh}     ← verify_all I.6 gap-tolerant matcher regression (v0.18+)
│       ├── test-real-project.{ps1,sh}  ← Integration regression on REAL fixture
│       ├── install-hooks.{ps1,sh}      ← One-shot git pre-commit installer
│       ├── archive-task.{ps1,sh}       ← Insight-harvest + stage-doc archive
│       ├── guard-rm.{ps1,sh}           ← Destructive-command PreToolUse guard (v0.15+)
│       ├── ambient-prompt.{ps1,sh}     ← Ambient-stream UserPromptSubmit heartbeat hook (flag-gated by .harness/ambient.flag)
│       ├── ambient-reset.{ps1,sh}      ← Ambient-stream SessionStart hook: clears .harness/ambient.flag each new session (session-scoped)
│       ├── test-guard-rm.{ps1,sh}      ← Driver for evals/guard-rm-cases.md (on-demand)
│       └── baseline.json               ← Test/asset baseline
│
├── .claude/                             ← Claude Code binding (regenerated by harness-sync)
│   ├── agents/                         ← from .harness/agents/
│   └── skills/                         ← from .harness/skills/
│
├── AI-GUIDE.md                          ← Tool-agnostic entry; indexes .harness/rules/
├── CLAUDE.md                            ← ~15-line stub pointing at AI-GUIDE.md (NOT regenerated)
│
├── docs/
│   ├── getting-started.md              ← User onboarding
│   ├── concepts.md                     ← Why each piece exists
│   ├── workflow.md                     ← 7-stage pipeline
│   ├── dev-map.md                      ← This file
│   ├── spec/                           ← Project SPECs
│   ├── features/                       ← Per-task documents
│   └── batches/                        ← Batch-mode artifacts (v0.19+): per-batch BATCH_PLAN.md / BATCH_LOG.md / BATCH_REPORT.md; _template/ for copy-paste; default/ is the no-arg ambient-stream pool (auto-created)
│
├── tests/
│   └── fixtures/                       ← Minimal real-shape projects for integration tests
│       ├── todo-fullstack/             ← Node + TS + node:test
│       └── todo-backend/               ← Python + pytest
│
├── architecture.html                    ← Visual architecture overview
├── install.ps1 / install.sh             ← One-command installer
├── README.md / LICENSE / CHANGELOG.md / CONTRIBUTING.md
├── .gitattributes / .gitignore
└── 参考/                                  ← (gitignored) reference articles
```

## Two layers of consistency

Layer 1 (sync-self): templates/common/ → repo SOT (.harness/agents/ + 7 script pairs)
Layer 2 (harness-sync): repo SOT (.harness/agents/ + .harness/skills/) → .claude/

Since v0.10, `CLAUDE.md` is a static stub pointing at `AI-GUIDE.md` — neither layer
touches it after init. Rules are referenced lazily by AI tools, not composed.

Both layers are checked by `.harness/scripts/verify_all` and FAIL on drift.

## Where features live

| Feature area | Files | Notes |
|---|---|---|
| Skill: harness-init | `skills/harness-init/SKILL.md` + `templates/` | Templates are SOT for distribution |
| Skill: harness-adopt | `skills/harness-adopt/SKILL.md` | Fully automated repo adoption since v0.3 |
| Skill: harness-verify | `skills/harness-verify/SKILL.md` | Invokes .harness/scripts/verify_all |
| Skill: harness-status | `skills/harness-status/SKILL.md` | Read-only inspection |
| Skill: harness-language | `skills/harness-language/SKILL.md` + `language-policy.{ps1,sh}` | Set / switch / refresh output-language policy (v0.25+); judgment in SKILL, mechanical in the helper pair |
| Project templates | `skills/harness-init/templates/` | `common/` + `fullstack/` + `backend/` |
| Agent role contracts | `templates/common/.harness/agents/*.md` | 7 canonical + 1 auxiliary (supervisor, v0.17+), byte-copied to repo `.harness/agents/` via sync-self |
| Distributed binding sync | `templates/common/.harness/scripts/harness-sync.{ps1,sh}` | Byte-copied to repo `.harness/scripts/` via sync-self |
| Repo rules (multi-file) | `.harness/rules/*.md` | Referenced (not composed) — AI-GUIDE.md indexes them, AI lazy-loads on demand |
| Documentation | `docs/`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md` | Keep tone consistent |
| Installation | `install.ps1`, `install.sh` | Symmetric; if you change one, change the other |

## Reusable utilities

| Need | Existing | File |
|---|---|---|
| Layer 1 sync (templates → repo SOT) | `sync-self` | Run before commit if you edited `templates/common/.harness/agents/` or one of the 7 mirrored script pairs (`harness-sync`, `install-hooks`, `archive-task`, `guard-rm`, `migrate-scripts-layout`, `upgrade-project`, `language-policy`) |
| Layer 2 sync (repo SOT → binding) | `harness-sync` | Run before commit if you edited `.harness/agents/` or `.harness/skills/`. Rule edits do NOT require sync — they're referenced, not copied. |
| Total verification | `verify_all` | Single source of truth for "is the repo healthy" — runs all 32 checks including both `--check` modes |
| Init regression | `test-init` | Simulates full init + sync in temp dir (275 assertions on PS / 237 Bash without python3; covers AI-native opt-in/opt-out bidirectional cases × 3 project types, the AC-10 byte-compare pass, and the BUG-2 placeholder-regex regression — see `.harness/scripts/baseline.json` for the live counts) |

## Patterns to follow

- **Source of truth principle**: edit `.harness/`, never the generated `.claude/`. `CLAUDE.md` is a stub written once at init; leave the AI-GUIDE.md pointer intact.
- **Templates are SOT for distribution**: edit `skills/harness-init/templates/common/.harness/`, run `sync-self`, then `harness-sync` for the dogfooded copy. (verify_all enforces both.)
- **Symmetric scripts**: every `.ps1` has a matching `.sh`. Behavior must match.
- **Template placeholders**: only the seven documented in `skills/harness-init/SKILL.md`:
  `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`, `{{ENABLE_HOOK}}`,
  `{{SYNC_COMMAND}}`, `{{GUARD_COMMAND}}`. Any new placeholder MUST also be added to
  the D.2 whitelist in BOTH `.harness/scripts/verify_all.ps1` AND `.harness/scripts/verify_all.sh`.
- **Markdown style**: ATX headings, ordered lists for sequences, tables for matrices, fenced code with language tag.
- **Rule fragments**: name them `NN-topic.md` where NN is a 2-digit sort prefix; the prefix only governs lexical sort order in directory listings (AI tools lazy-load fragments individually, not by composition). Use 00-19 for core, 20-49 for cross-cutting topics, 50-79 for project-type overlays, 80+ for project-specific.

## Patterns to avoid

- Editing `.claude/agents/*.md` or `.claude/skills/*` directly. They're regenerated by `harness-sync`; your changes get blown away on the next sync. Edit `.harness/` and run sync.
- Editing `.harness/agents/*.md` in this repo without also editing `templates/common/.harness/agents/*.md`. verify_all step E.1 FAILs.
- Adding a new template placeholder without documenting it in `harness-init/SKILL.md`.
- Letting `install.ps1` and `install.sh` (or any other paired scripts) drift in behavior. F.1 FAILs.
- Committing files from `参考/`. They're third-party content; `.gitignore` excludes them.
