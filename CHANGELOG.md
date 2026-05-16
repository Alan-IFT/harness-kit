# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
