---
name: harness-init
description: Bootstrap a new project with the full Harness Engineering skeleton — tool-agnostic .harness/ source-of-truth layer plus the Claude Code binding (.claude/ + CLAUDE.md). Use this when starting a fresh fullstack or backend project that wants AI-driven development from day one.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-init

Bootstrap a new project with the complete Harness skeleton, so that Claude Code can run
the 7-agent pipeline (PM → Analyst → Architect → Gate → Developer → Reviewer → QA)
out of the box.

The skeleton uses a **two-layer model**:

- `.harness/` is the tool-agnostic source of truth (agents, rules, skills).
- `.claude/agents/` and `.claude/skills/` are regenerated from `.harness/agents/` and
  `.harness/skills/` via `.harness/scripts/harness-sync`.
- `CLAUDE.md` and `.github/copilot-instructions.md` are ~15-line static stubs
  written once during init; they point at `AI-GUIDE.md`, which indexes
  `.harness/rules/*.md` by reference (since v0.10 rules are not composed).
  This keeps project knowledge separate from the IDE binding — you can edit `.harness/`
  with any tool, then sync to whatever binding your team uses.

## When to invoke

- New empty project repo
- Greenfield directory where you want AI-driven development to start

For **existing** projects with code, use `/harness-adopt` instead.

## Procedure

Follow these steps strictly. Use `TodoWrite` to track them.

### 1. Confirm the target directory

The current working directory is the target. Confirm with the user:

> "I'll initialize Harness in `<cwd>`. Proceed? (yes / change directory)"

If the directory already contains `.harness/`, `.claude/agents/`, or `CLAUDE.md`,
**stop and tell the user** — running this would overwrite existing files. Suggest
they back up or run `/harness-adopt`.

### 2. Gather project info via `AskUserQuestion`

Ask **six questions** in a single `AskUserQuestion` call:

1. **Project type** — options. The choice determines `PROJECT_TYPE` placeholder and which overlay is copied.
   - `Fullstack (frontend + backend + DB)` — `PROJECT_TYPE=fullstack`; copies fullstack overlay (partition agents, fullstack rules, verify_all preset for Node/web stacks).
   - `Backend / API service` — `PROJECT_TYPE=backend`; copies backend overlay (api/services/db partitions, backend rules, multi-stack verify_all).
   - `Generic (CLI / library / mobile / ML / embedded / etc.)` — `PROJECT_TYPE=generic`; copies generic overlay (`50-generic.md` stub for project-specific rules + a generic `verify_all` you customize for your actual build/test commands). No partition agents by default. The AI fills in `50-generic.md` based on your Q2 stack description and any existing code in the target directory.
2. **Primary language / framework stack** — free text via "Other" option (e.g. "Next.js + NestJS + Postgres", "FastAPI + Postgres", "Rust CLI tool", "PyTorch training pipeline").
3. **Install auto-sync hooks?** — options:
   - `Yes (recommended)` — installs **both** the Claude Code Stop hook (in `.claude/settings.json`) **and** the git pre-commit hook (via `.harness/scripts/install-hooks.{ps1,sh}`). Stop hook keeps `CLAUDE.md` + `.github/copilot-instructions.md` fresh while you work in Claude Code. Pre-commit hook is the tool-agnostic backstop — blocks any commit (Claude Code, Copilot, Cursor, hand-edits) that includes drifted generated artifacts.
   - `No, manual only` — you run `.harness/scripts/harness-sync` yourself after `.harness/` edits. `verify_all` will still catch drift after the fact, but you lose the auto-fresh guarantee.
4. **Developer partitioning** — options depend on Q1:

   For **Fullstack**:
   - `Partitioned (recommended) — dev-frontend / dev-backend / dev-db agents` — better focus, cleaner reviews, cross-area tasks via Architect partition assignment
   - `Single developer — one agent for all code` — simpler, fewer agents, fine for small projects

   For **Backend** (v0.5+):
   - `Partitioned (recommended) — dev-api / dev-services / dev-db agents` — three-layer split (HTTP boundary / business logic / persistence), supports clean coordination per Architect's design
   - `Single developer — one agent for all code` — fine for small/flat backend projects without a layered architecture

   For **Generic**:
   - Skip this question. Defaults to single developer. After init, the AI can be asked to "add partition agents for X" — it will create custom `.harness/agents/dev-*.md` based on the actual project layout. See `.harness/rules/50-generic.md` for the documented partitioning procedure.

5. **Project output language** — this is a **project-wide policy**, not just doc language. Options:
   - `English (default)` — **All AI output in this project will be in English**. That includes: chat replies, agent-to-agent hand-offs, every per-task document (`01_REQUIREMENT_ANALYSIS.md` through `07_DELIVERY.md`, `PM_LOG.md`), updates to `tasks.md` / `dev-map.md`, error messages, status reports. Even if the user writes in another language, AI responds in English.
   - `中文 (Chinese)` — **按消费者分流**：面向人的产出（对话回复、错误消息、状态/进度报告、给用户的交付总结、README 及人读文档）用**中文**；面向下游 agent/LLM 的产出（01–07 阶段文档、PM_LOG、tasks.md/dev-map/insight-index 台账、agent/rule/AI-GUIDE/CLAUDE 编辑、代码注释、commit message）用**英文**。即使用户用其他语言提问，对话回复仍用中文。
   - The policy is enforced by an "Output language" section at the top of CLAUDE.md. Agents read CLAUDE.md and follow the rule.
   - Agent definitions and verify_all scripts stay in English regardless (LLM reads English fine, file count manageable). Only output is constrained.

6. **AI customization of `50-<project>.md` rule fragment (v0.16+)** — opt-in. Default: `No (static template only)`.
   - `No (default) — keep static stub` — copies the static `50-<type>.md` template unchanged (byte-identical to v0.15.1 behavior). Fastest, most predictable init. The user/AI can edit the stub later by hand.
   - `Yes — let AI draft a tailored 50-<project-slug>.md` — after the static templates are copied (step 4) and placeholders are substituted (step 5), the skill runs an inline AI customization step (5b) that: (a) reads the user's Q2 stack string, the target directory's top-level filenames (Glob `*`, capped at 100 entries), and the contents of any of these manifest files if present (`package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `README.md`, each capped at 50 KB); (b) drafts `.harness/rules/50-<project-slug>.md` whose six section headings match the static stub but whose body is grounded in the inputs above (every non-template section carries an inline `<!-- source: ... -->` HTML comment with the file or tag the claim came from); (c) optionally proposes one or more `.harness/agents/dev-<name>.md` partition drafts that the user accepts / renames / rejects individually before any file is written.
   - Tradeoff: ~10s extra in init; AI output is non-deterministic (mitigated by mandatory source citations and a fall-back to the static stub if the four invariants fail — see step 5b.5). The user can always edit the file after init.
   - Reserved-name guard: partition names matching the seven pipeline-agent names (`pm-orchestrator`, `requirement-analyst`, `solution-architect`, `gate-reviewer`, `developer`, `code-reviewer`, `qa-tester`) are silently dropped before the Accept prompt.

### 3. Locate the template directory

Templates live alongside this skill:

- `<skill-root>/templates/common/` — shared assets (7 agents in `.harness/agents/`,
  rule fragments in `.harness/rules/`, harness-sync scripts, docs, evals).
- `<skill-root>/templates/fullstack/` — fullstack-specific overlays.
- `<skill-root>/templates/backend/` — backend-specific overlays.
- `<skill-root>/templates/generic/` — generic project overlay (single `50-generic.md` stub).
- `<skill-root>/templates/i18n/<lang>/` — translation overlays (currently `zh` is provided). Mirror the directory structure of `common/` and `<project-type>/`; files inside override their English counterparts.

If the skill is installed under `~/.claude/skills/harness-init/`, the templates are at `~/.claude/skills/harness-init/templates/`. Use `Glob` to discover the actual path.

### 4. Copy template files

Copy in this order (later layer overwrites earlier):

1. Everything under `templates/common/` → target root.
2. Everything under `templates/<project-type>/` → target root.
   - Fullstack overlay adds `.harness/rules/50-fullstack.md`, `.harness/skills/{build,test,verify}/SKILL.md.tmpl`, `.harness/scripts/verify_all.{ps1,sh}.tmpl`, **and** `.harness/agents/dev-{frontend,backend,db}.md.tmpl` (partition agents).
   - Backend overlay adds `.harness/rules/50-backend.md` etc.
   - **Generic** overlay adds `.harness/rules/50-generic.md` (a near-empty stub the user/AI fills in based on the actual stack). No partition agents. No project-type-specific `verify_all` template — the project gets the generic `verify_all` from `common/` (TODO: ship a `verify_all.tmpl` in `generic/` once the common one has stack-agnostic skeleton).
3. **If Q5 ≠ English**, apply the language overlay:
   - Copy everything under `templates/i18n/<lang>/common/` → target root (overwrites the English files).
   - Copy everything under `templates/i18n/<lang>/<project-type>/` → target root.
   - The `zh` overlay carries only the **human-facing files** a generated zh project should read in Chinese: `docs/spec/README.md` and `evals/golden-tasks.md.tmpl`. The three policy-carrying surfaces (`.harness/rules/00-core.md`, `CLAUDE.md`, `.github/copilot-instructions.md`) are **no longer overlaid** — they are laid down in English by step 4.1 and then have their Chinese consumer-split output-language policy injected by step 4.4 (composition, not duplication; T-016). Per the output-language policy, every AI-facing framework file (`AI-GUIDE.md`, the other rule fragments, the type `50-*.md`, `.harness/insight-index.md`, `docs/workflow.md`, `docs/dev-map.md`, `docs/tasks.md`) is NOT in the zh overlay and therefore falls through to its English `common/`/type version.
   - Files **not** in the overlay (agent prompts, skills/build|test|verify SKILL.md, scripts, **and the AI-facing framework files just listed**) stay in English. This is intentional — it is the mechanism that anglicizes AI-facing scaffolding: LLM reads English fine, the framework internals stay consistent, and the file count stays manageable.

### 4.4 Inject the output-language policy (only if Q5 = 中文)

For a `zh` project, the English `common/` `.harness/rules/00-core.md`, `CLAUDE.md`, and
`.github/copilot-instructions.md` were laid down by step 4.1 and are still English. Convert their
policy region to the canonical Chinese policy by running the **already-distributed** helper against the
project root (it was copied into `.harness/scripts/` by step 4.1):

```powershell
pwsh -NoProfile -File .harness/scripts/language-policy.ps1 -TemplateRoot <template-root> -Lang zh   # Windows
# or
bash .harness/scripts/language-policy.sh --template-root <template-root> --lang zh                  # macOS/Linux
```

`<template-root>` is the resolved plugin/skill root discovered in step 3 — the directory that **contains**
`skills/harness-init/templates` (i.e. the same value `/harness-language` passes; NOT the `templates`
directory itself). The helper:
- reads the single-source snippet `skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl`
  (the canonical zh policy section + line),
- rewrites the `## Output language (project-wide)` section in `.harness/rules/00-core.md` to the Chinese
  `## 输出语言（按消费者分流）` section (REWRITE-SECTION),
- rewrites the `Output language: **English**.` line in `CLAUDE.md` + copilot to the Chinese policy line
  (REWRITE-LINE),
- leaves every other byte untouched.

Run this **before** step 5 placeholder substitution (the policy section/line carry no `{{...}}` tokens, so
order is not load-bearing for them, but running pre-substitution matches the helper reading clean template
bytes). The helper writes timestamped `.bak-*` files; **delete the `*.bak-*` files it creates** after the
run (they are an artifact of the rewrite path, not wanted in a fresh init tree). Then proceed to step 5. The
result is byte-for-byte the tree the old i18n/zh overlay produced — composition replaces the deleted SPECIAL files.

Files ending in `.tmpl` need placeholder substitution (step 5). Drop the `.tmpl` suffix on write.

**After copy, apply the partitioning choice** (from Q4):

- If user picked **partitioned mode**: keep all partition agents AND keep the
  generic `developer.md`. The generic one stays as a fallback for tasks the
  architect can't cleanly assign to one partition.
- If user picked **single mode**: delete the project-type-specific partition
  agents from `.harness/agents/`:
  - Fullstack: `dev-frontend.md`, `dev-backend.md`, `dev-db.md`
  - Backend: `dev-api.md`, `dev-services.md`, `dev-db.md`
  - Only the generic `developer.md` remains.

Note: templates/common contains:
- `.harness/` (the source of truth content)
- `.claude/settings.json.tmpl` (Claude Code binding glue — permissions + hooks)
- `AI-GUIDE.md.tmpl` (tool-agnostic entry, indexes `.harness/rules/`)
- `CLAUDE.md.tmpl` (~15-line bootstrap stub pointing at `AI-GUIDE.md`)
- `.github/copilot-instructions.md.tmpl` (same stub for Copilot, with `applyTo: "**"` frontmatter)

`CLAUDE.md.tmpl` and `.github/copilot-instructions.md.tmpl` are copied to their
final paths during init; their **body is static** and never regenerated —
they're stubs. (The one exception: for a `zh` project, step 4.4 rewrites *only*
the top `Output language` policy line in each, leaving the body untouched.)
The full ruleset stays in `.harness/rules/*.md`; `AI-GUIDE.md` references those
fragments with "when to read" descriptions so AI tools can lazy-load only what
they need (progressive disclosure, like Claude Code's own skill system).

### 5. Substitute placeholders

Replace these placeholders in any `.tmpl` file:

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | basename of the target directory |
| `{{PROJECT_TYPE}}` | `fullstack`, `backend`, or `generic` |
| `{{STACK}}` | user's free-text answer to Q2 |
| `{{TODAY}}` | today's date in `YYYY-MM-DD` |
| `{{ENABLE_HOOK}}` | `true` or `false` from Q3 |
| `{{PARTITIONED}}` | `true` or `false` from Q4 (default `false` if Q4 was skipped) |
| `{{LANG}}` | `en` (default) or `zh` from Q5 |
| `{{SYNC_COMMAND}}` | OS-detected harness-sync invocation for the Stop hook. **Windows** → `pwsh -NoProfile -File .harness/scripts/harness-sync.ps1`. **macOS / Linux** → `bash .harness/scripts/harness-sync.sh`. Detect via `$IsWindows` (PowerShell) or `[[ "$OSTYPE" == "msys"* \|\| "$OSTYPE" == "cygwin"* \|\| "$OSTYPE" == "win32" ]]` (bash). Used only in `.claude/settings.json`. The Windows `-NoProfile` flag avoids loading the user's `$PROFILE` on every hook invocation (measured 3-4s → 10ms in QA 06_TEST_REPORT.md D-3). |
| `{{GUARD_COMMAND}}` | OS-detected guard-rm invocation for the PreToolUse hook (destructive-command safety, v0.15+). **Windows** → `pwsh -NoProfile -File .harness/scripts/guard-rm.ps1`. **macOS / Linux** → `bash .harness/scripts/guard-rm.sh`. Mirror the same OS detection used for `{{SYNC_COMMAND}}`. Used only in `.claude/settings.json`. See `.harness/rules/75-safety-hook.md` for the contract. The Windows `-NoProfile` flag is essential here — without it, every Bash tool call eats the user's `$PROFILE` startup cost (NFR-Perf was violated in QA testing; see 06_TEST_REPORT.md D-3). |

### 5b. AI customization (opt-in, v0.16+)

This step runs **only if Q6 = `Yes`**. If Q6 = `No`, skip to step 6 — the static
`50-<type>.md` copied by step 4 is the final rule file.

The step is **inline** — the orchestrator model executing this skill performs
the draft itself; no separate Bash call, no MCP, no new tool surface. The
canonical drafting prompt is shipped at `.harness/rules/_ai-native-prompt.md`
(copied to the user project by step 4); the skill quotes the four invariants
from that file when invoking the model.

#### 5b.1 — Slug sanitization

Compute the project slug from the cwd basename. The slug MUST match
`^[a-z0-9][a-z0-9-]{0,40}$`. Sanitizer (in order):

1. Lowercase the basename.
2. Replace every character not in `[a-z0-9]` with `-`.
3. Collapse runs of `-` into a single `-`; strip leading/trailing `-`.
4. Truncate to 40 characters.
5. If the result starts with a digit, prefix with `p-` (so `2025-app` → `p-2025-app`).
6. If the result is empty after sanitization, fall back to the static stub path
   (log a one-line note to the user) and SKIP the rest of step 5b.

#### 5b.2 — Gather inputs

- The user's Q2 stack string.
- `Glob *` in the target directory; cap the list at 100 entries; the overflow
  is summarized as a single `... (N more)` line in the prompt.
- For each of these manifest files **if present**, Read the first 50 KB:
  `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`,
  `pom.xml`, `README.md`. Skip silently if absent.

#### 5b.3 — Build the AI prompt

Quote the contract from `.harness/rules/_ai-native-prompt.md` (copied into the
user project at step 4). The prompt names exactly: `PROJECT_NAME`, `PROJECT_TYPE`,
`STACK`, `TOP_LEVEL`, `MANIFESTS`, and `RESERVED_NAMES`. Output contract: a
single JSON object `{ "rule_md": "...", "partition_agents": [{ "name": ..., "body": ...}] }`.
`partition_agents` MAY be `[]`.

#### 5b.4 — Mock short-circuit (`HARNESS_AI_NATIVE_MOCK`)

If the environment variable `HARNESS_AI_NATIVE_MOCK` is set and points at a
readable file, use that file's content as the AI response **instead of calling
the model**. Used by `.harness/scripts/test-init.{ps1,sh}` to exercise this flow without
a live LLM call. A shipped fixture lives at
`.harness/scripts/ai-native-mock.json` (copied from `templates/common/scripts/`) for
users who want to dry-run the AI-native path locally.

On parse error of the mock file, fall through to the fallback path (5b.5) — this
also exercises the fallback branch in tests.

#### 5b.5 — Validate the four invariants

Parse the response as JSON. Then validate the `rule_md` body against four
invariants. ANY failure ⇒ fall back to the static `50-<type>.md` stub and log
one line to PM_LOG.md (or stdout if no task slug) explaining which invariant
failed; continue at step 6.

1. **All six required headings present in order** (regex per line, top-to-bottom):
   `## When to read`, `## Build / test / verify`, `## Project structure`,
   `## Stack-specific conventions`, `## Partitioning`,
   `## Stack-specific verify_all checks`.
2. **No `{{...}}` literals** — regex `\{\{[A-Z_]+\}\}` over the body MUST match
   zero. This protects `verify_all` D.2 on the user's first run.
3. **Line count ≤200** — soft cap; over the cap, write the file anyway but
   surface a one-time warning that I.2 will WARN on next verify_all.
4. **No reserved partition names** — drop any `partition_agents[i]` whose
   `name` is in `{pm-orchestrator, requirement-analyst, solution-architect,
   gate-reviewer, developer, code-reviewer, qa-tester}`. Continue with the
   remainder (an empty `partition_agents` list is acceptable).

Quoted from `.harness/rules/_ai-native-prompt.md`:

> If you cannot satisfy all four, the skill drops your output and falls back
> to the static `50-<PROJECT_TYPE>.md` stub. Do not try to be clever; the safe
> default beats a malformed customization.

#### 5b.6 — Write `.harness/rules/50-<slug>.md`

Use the Write tool to create `.harness/rules/50-<slug>.md` containing the
validated `rule_md` body. After Write, **re-Read the file with `Get-Content -Raw`**
and compare byte-for-byte to the string passed to Write. On mismatch, retry
the Write once; on a second mismatch, fall back to the static stub (per
insight-index line 10 on Edit-tool false-success).

#### 5b.7 — Delete the static stub `50-<type>.md`

The AI-authored file fully replaces the static stub. Use the Delete operation
on `.harness/rules/50-<PROJECT_TYPE>.md` (which step 4 copied). On Windows
`Remove-Item`; on Unix `rm`. The `_ai-native-prompt.md` reference file stays
in place.

#### 5b.8 — Update `AI-GUIDE.md` index entry

The freshly-copied `AI-GUIDE.md` has a line of the form:

```
- **`.harness/rules/50-<PROJECT_TYPE>.md`** (**when touching code**): ...
```

Replace `50-<PROJECT_TYPE>.md` with `50-<slug>.md` in that line (a single Edit
on `AI-GUIDE.md`). After the Edit, **re-Read AI-GUIDE.md** and confirm the line
now references `50-<slug>.md`. This keeps `verify_all` E.4b (AI-GUIDE ↔ rules
bidirectional index) green on the user's first run.

#### 5b.9 — Partition agent Accept / Rename / Reject loop

For each item in `partition_agents`:

1. After the reserved-name filter from 5b.5, present the proposed name and the
   first ~10 lines of the body to the user via `AskUserQuestion`:
   "Accept this draft as `.harness/agents/<name>.md`? [Accept / Rename / Reject]".
2. **Accept** → write `.harness/agents/<name>.md` with the body; re-Read to confirm.
3. **Rename** → take user input via a follow-up `AskUserQuestion`; verify the new
   name does not collide with `RESERVED_NAMES` and does not duplicate another
   accepted partition. Write the file with the new `name:` substituted.
4. **Reject** → skip; do not write.

Mock-test override: if `HARNESS_AI_NATIVE_PARTITION_DECISION` is set in the env
(values: `accept` / `reject`), apply that decision to every partition without
asking. Used by test-init only.

#### 5b.10 — 5-line summary to user (NFR-UX-2)

Print:

```
AI-native customization summary
  File written:        .harness/rules/50-<slug>.md (<N> lines)
  Source citations:    <M> annotations across <K> sections
  Partitions accepted: <P> / <Q> proposed
  Fallback fired:      <Yes|No>
```

### 6. Run the initial binding sync

After all files are in place, run the binding sync to copy `.harness/agents/`
and `.harness/skills/` into the Claude-Code-required `.claude/` paths:

```powershell
pwsh -File .harness/scripts/harness-sync.ps1     # Windows
bash .harness/scripts/harness-sync.sh            # Unix
```

**v0.10 scope (much narrower than v0.9.x)**: `harness-sync` only copies
`.harness/agents/` → `.claude/agents/` and `.harness/skills/` → `.claude/skills/`.
It does **not** generate `CLAUDE.md` or `.github/copilot-instructions.md` —
those are static stubs written once during init (step 4) and never regenerated.
`AI-GUIDE.md` indexes `.harness/rules/` by reference; rules updates flow
automatically by reference, not by re-composition.

From now on:
- To change a rule: edit `.harness/rules/<file>.md`. **No sync needed.** AI tools
  follow the reference from `AI-GUIDE.md`.
- To change an agent or skill: edit `.harness/agents/<file>.md` or
  `.harness/skills/<name>/SKILL.md`, then re-run `harness-sync` to update
  `.claude/`. The Stop hook + pre-commit hook auto-handle this if installed.

### 7. Initialize git if needed

If the target is not a git repo (`.git/` does not exist), `git init -b main`.

### 8. Install the git pre-commit hook (if Q3 = Yes)

If the user answered Q3 = `Yes (recommended)`, run the hook installer
right after `git init`:

```powershell
pwsh -File .harness/scripts/install-hooks.ps1   # Windows
bash .harness/scripts/install-hooks.sh          # macOS / Linux
```

This writes `.git/hooks/pre-commit` which runs `harness-sync --check`
before every commit. Drift between `.harness/` and the generated files
(`CLAUDE.md`, `.github/copilot-instructions.md`) becomes a hard block,
regardless of which AI tool (Claude Code, Copilot, Cursor) or human did
the edit. Catches the case where Claude Code's Stop hook didn't fire
because the user was working in a different tool.

If Q3 = `No, manual only`, skip this step. The Stop hook in
`.claude/settings.json` is also unconditionally written by the template
(it does no harm if Claude Code is never used); only the pre-commit hook
is conditional on Q3.

**Note on the safety guard (v0.15+)**: `.harness/scripts/guard-rm.{ps1,sh}` is shipped
via the `templates/common/.harness/scripts/` copy in step 4, and the PreToolUse hook in
`.claude/settings.json` is wired with `{{GUARD_COMMAND}}` substituted in step 5.
No separate installer step is needed — the guard is always on after init. The
disable path is documented in `.harness/rules/75-safety-hook.md`.

### 9. Write the initial SPEC stub

Create `docs/spec/README.md` if missing (the template usually provides one).

### 10. Initialize baseline

Create `.harness/scripts/baseline.json` with empty defaults:

```json
{
  "version": 1,
  "created": "{{TODAY}}",
  "test_count": 0,
  "passing_count": 0,
  "warnings_baseline": 0,
  "notes": "Baseline starts at zero. Run verify_all and let it populate after the first successful task."
}
```

### 11. Summary report to user

Print a structured summary:

```
✅ Harness initialized in <path>

Source of truth (edit these, never .claude/):
  .harness/
    agents/       (7 sub-agents — synced to .claude/agents/ by harness-sync)
    rules/        (rule fragments — referenced by AI-GUIDE.md, NOT composed)
    skills/       (build, test, verify procedures — synced to .claude/skills/)
  AI-GUIDE.md     (tool-agnostic entry; indexes .harness/rules/ with "when to read")

Init-time artifacts (touch only to fix the AI-GUIDE.md pointer):
  CLAUDE.md                            (~15-line stub pointing at AI-GUIDE.md)
  .github/copilot-instructions.md      (~15-line stub pointing at AI-GUIDE.md)

Regenerated by harness-sync (never hand-edit):
  .claude/agents/
  .claude/skills/

Direct binding glue (safe to edit by hand):
  .claude/settings.json

Project documentation (tool-agnostic, edit freely):
  docs/
    workflow.md   (7-stage pipeline definition)
    spec/         (write requirements here)
    dev-map.md    (development navigation)
    tasks.md      (task board)

Scripts:
  .harness/scripts/
    verify_all.{ps1,sh}    — total verification gate
    harness-sync.{ps1,sh}  — binding sync (.harness/agents + .harness/skills → .claude/)
    guard-rm.{ps1,sh}      — destructive-command safety hook (PreToolUse; v0.15+)
    baseline.json
  evals/golden-tasks.md    — regression task set

Next steps:
  1. Read CLAUDE.md (the bootstrap stub) and customize .harness/rules/ if anything
     is off. Rule edits take effect by reference via AI-GUIDE.md — no sync needed.
  2. Write your first feature in docs/spec/.
  3. In Claude Code, start a task by asking PM Orchestrator to take it:
     "Take this task: <description>"
     The PM dispatches through the 7-stage pipeline.

Estimated time to first delivered feature: 30 min – 1 hour depending on scope.
```

## Anti-patterns

- **Do not** overwrite existing `.harness/`, `.claude/`, or `CLAUDE.md` without explicit user confirmation.
- **Do not** hand-edit the synced `.claude/agents/` or `.claude/skills/`. Edit `.harness/` and re-sync. `CLAUDE.md` is a static stub — leave its `AI-GUIDE.md` pointer intact.
- **Do not** install npm packages or modify the user's shell config.
- **Do not** run `verify_all` during init (no project code yet).
- **Do not** modify files outside the target directory.
- **Do not** re-create the deleted i18n/zh policy-carrying files; the zh policy is single-sourced and injected (step 4.4).

## Failure handling

- If template files are missing → tell the user the skill is broken, ask them to reinstall.
- If user aborts at any AskUserQuestion → leave the target untouched, no partial state.
- If file write fails (permission, disk full) → list which files made it and which didn't, do not retry blindly.
- If `harness-sync` fails after copy → report the error; the user can re-run it manually after fixing whatever blocked it.
