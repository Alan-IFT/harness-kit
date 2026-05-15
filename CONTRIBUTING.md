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
cd HarnessEngineering

# Run verify_all to confirm a clean baseline
pwsh -File scripts/verify_all.ps1     # Windows
bash scripts/verify_all.sh            # Unix
```

Expected output: 15 PASS / 0 WARN / 0 FAIL.

## Source-of-truth principle

The **canonical** location for the 7 agent definitions is:

```
skills/harness-init/templates/common/.claude/agents/*.md
```

The root `.claude/agents/*.md` is a **byte-identical copy** so this repo can
dogfood itself. If you edit one, run `sync-self` before committing:

```powershell
.\scripts\sync-self.ps1     # syncs source-of-truth → root copy
.\scripts\sync-self.ps1 -Check   # report drift, no writes
```

```bash
./scripts/sync-self.sh
./scripts/sync-self.sh --check
```

`verify_all` step `E.1` will FAIL if the two ever drift.

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
4. **Test it** by running it in Claude Code at least once before committing. For init/template flows, also add coverage to `scripts/test-init.{ps1,sh}`.

After adding a skill:

- Update `README.md` "Quick start" section.
- Update `CHANGELOG.md` under `[Unreleased]`.
- Update `install.ps1` and `install.sh` `$skills`/`skills` array.
- verify_all checks all of the above; will FAIL on missing.

## Adding a project type template

Project types live under `skills/harness-init/templates/<type>/`:

- `CLAUDE.md.append` — appended to the common CLAUDE.md.
- `scripts/verify_all.{ps1,sh}.tmpl` — type-specific verification.
- `.claude/skills/{build,test,verify}/SKILL.md.tmpl` — stack-specific procedures.

Rules:

1. **Only the 5 documented placeholders are allowed**:
   `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{STACK}}`, `{{TODAY}}`, `{{ENABLE_HOOK}}`.
   verify_all step `D.2` enforces this whitelist.
2. **Extend `scripts/test-init.{ps1,sh}`** with a `test_type` call for the new type.
3. **Add a section** in `docs/dev-map.md` under "Top-level layout" → `templates/`.
4. **Update CHANGELOG** under `[Unreleased]`.

## Changing an agent definition

Edit `skills/harness-init/templates/common/.claude/agents/<agent>.md`. Then:

```bash
./scripts/sync-self.sh    # propagate to root .claude/agents/
./scripts/verify_all.sh   # confirm E.1 passes
```

Re-run golden tasks #1 and #2 via `test-init.{ps1,sh}` if you changed the agent's
declared frontmatter or core contract — the regression captures the role of each
agent in the generated project.

## Commit messages

Format:

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
