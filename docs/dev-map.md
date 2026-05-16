# Dev Map — Harness Kit repo

> Where things live and the conventions to follow when changing them. (v0.6 layout)

## Top-level layout

```
harness-kit/
├── skills/                              ← Distributed skills (the product)
│   ├── harness-init/
│   │   ├── SKILL.md                    ← Skill entry point
│   │   └── templates/                  ← Project templates (SOURCE OF TRUTH for distribution)
│   │       ├── common/                 ← Shared assets all projects get
│   │       │   ├── .harness/agents/    ← 7 agent definitions (tool-agnostic SOT)
│   │       │   ├── .harness/rules/00-core.md.tmpl  ← base rule fragments
│   │       │   ├── .claude/settings.json.tmpl       ← Claude Code binding glue
│   │       │   ├── docs/workflow.md
│   │       │   ├── docs/dev-map.md.tmpl
│   │       │   ├── docs/tasks.md.tmpl
│   │       │   ├── docs/spec/README.md
│   │       │   ├── scripts/harness-sync.{ps1,sh}    ← Binding sync (distributed)
│   │       │   └── evals/golden-tasks.md.tmpl
│   │       ├── fullstack/              ← Fullstack-only overlays
│   │       │   ├── .harness/rules/50-fullstack.md
│   │       │   ├── .harness/skills/{build,test,verify}/SKILL.md.tmpl
│   │       │   └── scripts/verify_all.{ps1,sh}.tmpl
│   │       └── backend/                ← Backend-only overlays
│   │           ├── .harness/rules/50-backend.md
│   │           ├── .harness/skills/{build,test,verify}/SKILL.md.tmpl
│   │           └── scripts/verify_all.{ps1,sh}.tmpl
│   ├── harness-adopt/SKILL.md          ← Existing-project adoption (scaffolding-only in 0.1)
│   ├── harness-verify/SKILL.md         ← Run verify_all
│   └── harness-status/SKILL.md         ← Show Harness health
│
├── .harness/                            ← THIS repo's tool-agnostic SOT (dogfood)
│   ├── agents/                         ← byte-copy of templates/common/.harness/agents/
│   └── rules/                          ← repo-specific rule fragments
│       ├── 00-core.md
│       ├── 10-self-consistency.md
│       ├── 20-documentation.md
│       ├── 30-engineering.md
│       └── 40-locations.md
│
├── .claude/                             ← Generated (Claude Code binding)
│   └── agents/                         ← from .harness/agents/ via harness-sync
│
├── CLAUDE.md                            ← Generated from .harness/rules/*.md by harness-sync
│
├── docs/
│   ├── getting-started.md              ← User onboarding
│   ├── concepts.md                     ← Why each piece exists
│   ├── workflow.md                     ← 7-stage pipeline
│   ├── dev-map.md                      ← This file
│   ├── spec/                           ← Project SPECs
│   └── features/                       ← Per-task documents
│
├── scripts/
│   ├── verify_all.{ps1,sh}             ← Total verification (tooling project flavor)
│   ├── harness-sync.{ps1,sh}           ← Layer 2: .harness/ → .claude/ + CLAUDE.md
│   ├── sync-self.{ps1,sh}              ← Layer 1: templates/common/ → repo SOT
│   ├── test-init.{ps1,sh}              ← Init+sync regression on EMPTY dir (86 assertions)
│   ├── test-real-project.{ps1,sh}      ← Integration regression on REAL fixture (64 assertions)
│   └── baseline.json                   ← Test/asset baseline
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

Layer 1 (sync-self): templates/common/ → repo SOT (.harness/, scripts/harness-sync)
Layer 2 (harness-sync): repo SOT (.harness/) → repo binding (.claude/, CLAUDE.md)

Both layers are checked by `scripts/verify_all` and FAIL on drift.

## Where features live

| Feature area | Files | Notes |
|---|---|---|
| Skill: harness-init | `skills/harness-init/SKILL.md` + `templates/` | Templates are SOT for distribution |
| Skill: harness-adopt | `skills/harness-adopt/SKILL.md` | Scaffolding-only in 0.1 |
| Skill: harness-verify | `skills/harness-verify/SKILL.md` | Invokes scripts/verify_all |
| Skill: harness-status | `skills/harness-status/SKILL.md` | Read-only inspection |
| Project templates | `skills/harness-init/templates/` | `common/` + `fullstack/` + `backend/` |
| Agent role contracts | `templates/common/.harness/agents/*.md` | 7 files, byte-copied to repo `.harness/agents/` via sync-self |
| Distributed binding sync | `templates/common/scripts/harness-sync.{ps1,sh}` | Byte-copied to repo `scripts/` via sync-self |
| Repo rules (multi-file) | `.harness/rules/*.md` | Composed into `CLAUDE.md` by harness-sync |
| Documentation | `docs/`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md` | Keep tone consistent |
| Installation | `install.ps1`, `install.sh` | Symmetric; if you change one, change the other |

## Reusable utilities

| Need | Existing | File |
|---|---|---|
| Layer 1 sync (templates → repo SOT) | `sync-self` | Run before commit if you edited `templates/common/.harness/agents/` or `templates/common/scripts/harness-sync.*` |
| Layer 2 sync (repo SOT → binding) | `harness-sync` | Run before commit if you edited `.harness/agents/` or `.harness/rules/` |
| Total verification | `verify_all` | Single source of truth for "is the repo healthy" — runs both `--check` modes implicitly |
| Init regression | `test-init` | Simulates full init + sync in temp dir; 86 assertions |

## Patterns to follow

- **Source of truth principle**: edit `.harness/`, never the generated `.claude/` or `CLAUDE.md`.
- **Templates are SOT for distribution**: edit `skills/harness-init/templates/common/.harness/`, run `sync-self`, then `harness-sync` for the dogfooded copy. (verify_all enforces both.)
- **Symmetric scripts**: every `.ps1` has a matching `.sh`. Behavior must match.
- **Template placeholders**: only the five documented in `skills/harness-init/SKILL.md`:
  `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`, `{{ENABLE_HOOK}}`.
- **Markdown style**: ATX headings, ordered lists for sequences, tables for matrices, fenced code with language tag.
- **Rule fragments**: name them `NN-topic.md` where NN is a 2-digit sort prefix. The fragments are composed by filename order. Use 00-19 for core, 20-49 for cross-cutting topics, 50-79 for project-type overlays, 80+ for project-specific.

## Patterns to avoid

- Editing `CLAUDE.md` or `.claude/agents/*.md` directly. They're generated; your changes get blown away on the next sync. Edit `.harness/` and run sync.
- Editing `.harness/agents/*.md` in this repo without also editing `templates/common/.harness/agents/*.md`. verify_all step E.1 FAILs.
- Adding a new template placeholder without documenting it in `harness-init/SKILL.md`.
- Letting `install.ps1` and `install.sh` (or any other paired scripts) drift in behavior. F.1 FAILs.
- Committing files from `参考/`. They're third-party content; `.gitignore` excludes them.
