# Contributing

Thanks for considering a contribution. This document covers how the repo is structured,
how to make changes that don't break the system, and how to verify your change.

> This repo dogfoods its own Harness. Non-trivial changes should flow through the
> 7-agent pipeline ([docs/workflow.md](docs/workflow.md)). Trivial changes (typos,
> single-line tweaks) can go direct — but must still pass `scripts/verify_all`.

## Setup

```bash
# Clone
git clone <repo-url>
cd harness-kit

# Run verify_all to confirm a clean baseline
pwsh -File scripts/verify_all.ps1     # Windows
bash scripts/verify_all.sh            # Unix
```

Expected output: 18 PASS / 0 WARN / 0 FAIL.

## Two-layer model (v0.2+)

This repo uses two layers of consistency:

```
[Layer 1: sync-self]                 [Layer 2: harness-sync]
templates/common/  ─────────────►   .harness/  ─────────────►   .claude/ + CLAUDE.md
  (distribution SOT)                  (repo SOT)                  (binding artifacts;
                                                                   never hand-edit)
```

- **Layer 1 (sync-self)** keeps `templates/common/.harness/agents/` and
  `templates/common/scripts/harness-sync.{ps1,sh}` byte-identical with the repo's
  `.harness/agents/` and `scripts/harness-sync.{ps1,sh}` copies. Verifies that what
  we ship to users matches what we use ourselves.
- **Layer 2 (harness-sync)** generates `.claude/agents/`, `.claude/skills/`, and
  `CLAUDE.md` from `.harness/`. The same script ships to user projects so the
  binding contract is reusable.

`verify_all` enforces both layers (E.1 + E.2) and FAILs on drift. Run sync before commit.

## What to edit, what NOT to edit

| Layer | Edit | Never edit (generated) |
|---|---|---|
| Layer 1 (distribution SOT) | `skills/harness-init/templates/common/.harness/` and `templates/common/scripts/` | — |
| Layer 2 (repo SOT, dogfooded) | `.harness/agents/` and `.harness/rules/` | `.claude/agents/`, `CLAUDE.md` |

After editing Layer 1:

```powershell
.\scripts\sync-self.ps1               # Layer 1 → Layer 2
.\scripts\harness-sync.ps1            # Layer 2 → bindings
```

After editing Layer 2 only (just changing repo behavior, not the distributed template):

```powershell
.\scripts\harness-sync.ps1
```

`verify_all` calls both `sync-self --check` and `harness-sync --check` internally, so
forgetting either will get caught.

## Adding or changing a skill

Each skill lives in `skills/<name>/`:

```
skills/<name>/
├── SKILL.md          # frontmatter (name, description, allowed-tools) + instructions
└── (optional)        # templates/, lib/, etc.
```

Rules for skills:

1. **Frontmatter is mandatory.** Must have `name:` and `description:`. verify_all checks this.
2. **`description` is what Claude Code uses to decide when to invoke.** Be specific about *when to use* and *when not to use*. First sentence is the most important.
3. **`allowed-tools` is the strictest necessary subset.** Don't grant Bash if Read is enough.
4. **Test it** by running it in Claude Code at least once before committing. For init/template flows, also extend `scripts/test-init.{ps1,sh}`.

After adding a skill:

- Update `README.md` "Quick start" section.
- Update `CHANGELOG.md` under `[Unreleased]`.
- Update `install.ps1` and `install.sh` skills array.
- verify_all checks all of the above; will FAIL on missing.

## Adding a project type template

Project types live under `skills/harness-init/templates/<type>/`:

- `.harness/rules/50-<type>.md` — overlay rules appended to the generated CLAUDE.md.
- `.harness/skills/{build,test,verify}/SKILL.md.tmpl` — stack-specific procedures.
- `scripts/verify_all.{ps1,sh}.tmpl` — type-specific verification.

Rules:

1. **Only the 7 documented placeholders are allowed**:
   `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`, `{{ENABLE_HOOK}}`,
   `{{SYNC_COMMAND}}`, `{{GUARD_COMMAND}}`. verify_all step `D.2` enforces this
   whitelist — and any new placeholder MUST be added to BOTH `verify_all.ps1` AND
   `verify_all.sh` whitelists or the check fails.
2. **Extend `scripts/test-init.{ps1,sh}`** with a `test_type` call for the new type.
3. **Add a section** in `docs/dev-map.md` under the templates layout.
4. **Update CHANGELOG** under `[Unreleased]`.
5. **Rule fragment naming**: use `NN-name.md` with 50–79 for project-type overlays. The numeric prefix is a sort convention only — since v0.10, fragments are not composed into CLAUDE.md; `AI-GUIDE.md` indexes them and AI tools lazy-load on demand.

## Changing an agent definition

Edit `skills/harness-init/templates/common/.harness/agents/<agent>.md`. Then:

```bash
./scripts/sync-self.sh        # Layer 1 → Layer 2
./scripts/harness-sync.sh     # Layer 2 → bindings (regenerates this repo's .claude/agents/)
./scripts/verify_all.sh       # confirm E.1 and E.2 pass
```

Re-run `test-init.{ps1,sh}` if you changed the agent's declared frontmatter or core
contract — the regression captures the role of each agent in the generated project.

## Commit messages

Format (Conventional Commits):

```
type(scope): one-line summary in imperative mood (≤72 chars)

Body, wrapped at ~72 chars, explaining the WHY. The diff already shows
WHAT changed.
```

`type` is one of:

- `feat`     — new feature
- `fix`      — bug fix
- `docs`     — documentation only
- `chore`    — scaffolding, deps, build housekeeping
- `test`     — adding or changing tests
- `refactor` — code change that's neither fix nor feature
- `style`    — formatting only

Reference relevant issues / tasks. Group related changes; don't bundle.

## Running verify_all before commit

Every commit should leave `verify_all` green. Run it locally:

```powershell
pwsh -File scripts/verify_all.ps1
```

Exit 0 = ready to commit. Exit 1 (warnings) = your call. Exit 2 (failures) = fix first.

## Releases

We follow [SemVer](https://semver.org/) and [Keep a Changelog](https://keepachangelog.com/).

- Move `[Unreleased]` entries to a new `[x.y.z] - YYYY-MM-DD` section.
- Tag: `git tag -a v0.x.y -m "Release v0.x.y"`.
- Push: `git push --follow-tags`.

## Questions

- Open an issue.
- For design discussions, see `architecture.html` (open in browser) and `docs/concepts.md`.
- For the 7-agent pipeline philosophy, see `docs/workflow.md`.
