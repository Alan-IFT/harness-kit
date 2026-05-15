# Dev Map — Harness Engineering repo

> Where things live and the conventions to follow when changing them.

## Top-level layout

```
HarnessEngineering/
├── skills/                              ← Distributed skills (the product)
│   ├── harness-init/
│   │   ├── SKILL.md                    ← Skill entry point
│   │   └── templates/                  ← Project templates (SOURCE OF TRUTH)
│   │       ├── common/                 ← Shared assets all projects get
│   │       │   ├── .claude/agents/     ← 7 agent definitions
│   │       │   ├── .claude/settings.json.tmpl
│   │       │   ├── CLAUDE.md.tmpl
│   │       │   ├── docs/workflow.md
│   │       │   ├── docs/dev-map.md.tmpl
│   │       │   ├── docs/tasks.md.tmpl
│   │       │   ├── docs/spec/README.md
│   │       │   └── evals/golden-tasks.md.tmpl
│   │       ├── fullstack/              ← Fullstack-only overlays
│   │       │   ├── CLAUDE.md.append
│   │       │   ├── scripts/verify_all.{ps1,sh}.tmpl
│   │       │   └── .claude/skills/{build,test,verify}/SKILL.md.tmpl
│   │       └── backend/                ← Backend-only overlays
│   │           ├── CLAUDE.md.append
│   │           ├── scripts/verify_all.{ps1,sh}.tmpl
│   │           └── .claude/skills/{build,test,verify}/SKILL.md.tmpl
│   ├── harness-adopt/SKILL.md          ← Existing-project adoption
│   ├── harness-verify/SKILL.md         ← Run verify_all
│   └── harness-status/SKILL.md         ← Show Harness health
│
├── .claude/                             ← THIS repo's Harness assets (dogfood)
│   ├── agents/                         ← COPY of skills/harness-init/templates/common/.claude/agents/
│   └── skills/                         ← (none — this repo doesn't ship skills to itself)
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
│   ├── verify_all.ps1 / .sh            ← Total verification (tooling project flavor)
│   ├── sync-self.ps1 / .sh             ← Sync templates → root .claude/
│   ├── baseline.json                   ← Test/asset baseline
│   └── verification_history.log        ← Run history
│
├── architecture.html                    ← Visual architecture overview
├── install.ps1 / install.sh             ← One-command installer
├── README.md
├── LICENSE
├── CHANGELOG.md
└── 参考/                                  ← (gitignored) reference articles
```

## Where features live

| Feature area | Files | Notes |
|---|---|---|
| Skill: harness-init | `skills/harness-init/SKILL.md` + `templates/` | Templates are SOT |
| Skill: harness-adopt | `skills/harness-adopt/SKILL.md` | Pulls templates from harness-init |
| Skill: harness-verify | `skills/harness-verify/SKILL.md` | Just invokes scripts/verify_all |
| Skill: harness-status | `skills/harness-status/SKILL.md` | Read-only inspection |
| Project templates | `skills/harness-init/templates/` | `common/` + `fullstack/` + `backend/` |
| Agent role contracts | `skills/harness-init/templates/common/.claude/agents/*.md` | 7 files, must stay in sync with root .claude/ |
| Documentation | `docs/`, `README.md`, `CHANGELOG.md` | Keep tone consistent |
| Installation | `install.ps1`, `install.sh` | Symmetric; if you change one, change the other |

## Reusable utilities

| Need | Existing | File |
|---|---|---|
| Sync templates → root .claude/ | `scripts/sync-self.*` | Run before any commit that touches `.claude/agents/` |
| Total verification | `scripts/verify_all.*` | Single source of truth for "is the repo healthy" |

## Patterns to follow

- **Source of truth principle**: templates under `skills/harness-init/templates/common/` are SOT; root `.claude/agents/` is a derived copy.
- **Symmetric scripts**: every `.ps1` has a matching `.sh` (and vice versa). Behavior must match.
- **Template placeholders**: only the five documented in `skills/harness-init/SKILL.md`:
  `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`, `{{ENABLE_HOOK}}`.
- **Markdown style**: ATX headings, ordered lists for sequences, tables for matrices, fenced code with language tag.

## Patterns to avoid

- Editing `.claude/agents/*.md` at the root without updating `skills/harness-init/templates/common/.claude/agents/*.md`. verify_all will FAIL.
- Adding a new template placeholder without documenting it in `harness-init/SKILL.md`.
- Letting `install.ps1` and `install.sh` drift in behavior. If they diverge, they're a maintenance hazard.
- Committing files from `参考/`. They're third-party content; `.gitignore` excludes them.
