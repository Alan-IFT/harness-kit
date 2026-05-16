# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
