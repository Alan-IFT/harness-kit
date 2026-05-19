# 02 — Solution Design · ai-native-init (T-002)

Mode: `full` · Stage: 2/7 · Author: Solution Architect · Date: 2026-05-19 · Target version: **v0.16.0** (`README.md:256`)

## 1. Overview

We add an **opt-in AI customization step** to both `/harness-init` and `/harness-adopt` that, after the static template overlay is copied but before the run finishes, drafts a tailored `.harness/rules/50-<project-slug>.md` (and optionally one or more `.harness/agents/dev-<name>.md` files for generic projects) grounded in the user's Q2 stack string plus a bounded read of the target directory (top-level Glob + a fixed list of named manifest files). The static `50-fullstack.md` / `50-backend.md` / `50-generic.md.tmpl` templates are **unchanged**; the AI step writes a *new* file `50-<project-slug>.md` and deletes the static stub that would otherwise sit beside it, but only when the user opts in. Opt-out is the default and produces a byte-identical v0.15.1 result (AC-3, AC-10). The work is inline in the two skill prompts (no new sub-agent), behind a single new env-var-controlled mock hook for tests. Two existing verify_all checks gain one new sibling (`D.3 — AI-generated 50-*.md sanity`); the placeholder whitelist (D.2) and AI-GUIDE indexing checks (E.4b) already cover the rest. The new file is added vs. the static stub (`50-<type>.md`) only when opt-in; the seven pipeline agent files stay byte-identical with `templates/common/.harness/agents/` per the Layer-1 self-consistency rule (`.harness/rules/10-self-consistency.md`).

## 2. Architecture / Module decomposition

| Unit | Kind | Responsibility |
|---|---|---|
| `skills/harness-init/SKILL.md` step 5b "AI customization (opt-in)" | new skill section | After template copy + placeholder substitution, ask Q6, run the AI draft, write `50-<project-slug>.md`, optionally write `dev-*.md` drafts |
| `skills/harness-adopt/SKILL.md` step 4b "AI rule synthesis (opt-in)" | new skill section | Symmetric to init step 5b but seeded from step-2 reconnaissance profile |
| `skills/harness-init/templates/common/.harness/rules/_ai-native-prompt.md` | new template fragment | Canonical prompt the skill hands to the model (lists required sections, citation format, "don't guess" rules). Copied into project as a reference; not loaded at runtime |
| `skills/harness-init/templates/common/scripts/ai-native-mock.json` | new test fixture (template) | Canned AI response the test harness loads when `HARNESS_AI_NATIVE_MOCK=1`. Shipped in templates so user-projects can also dry-run |
| `scripts/test-init.ps1` + `scripts/test-init.sh` AI-native block | extended test runner | Two new test cases per project type: opt-in (mock returns shaped Markdown) + opt-out (no AI invoked) |
| `scripts/verify_all.{ps1,sh}` check `D.3` | new verify check | Asserts every `.harness/rules/50-*.md` present in repo: (a) has the 6 required section headings, (b) contains at least one `<!-- source: ... -->` annotation, (c) contains zero `{{...}}` literals |
| `.harness/rules/50-<slug>.md` produced at init/adopt time | runtime artifact | The actual customized rule fragment; lives in the user's project, not in this repo |

No new `.harness/agents/*.md` for the AI step itself (analyst Q3 decision retained — see decision log).

## 3. Decisions log

| # | Decision | Analyst-preferred | Architect-final | Rationale |
|---|---|---|---|---|
| Q1 | Skill placement | Both `/harness-init` and `/harness-adopt` | **Same** | Confirmed by Glob audit: both skills already share `templates/common/` and have a clear "after copy / before finalize" cut point (init step 5, adopt step 4). Splitting would duplicate the prompt and citation format. |
| Q2 | Default of new Q6 | Opt-out (legacy default) | **Same** | NFR-Compat-2 (`01_REQUIREMENT_ANALYSIS.md:73`) requires byte-identical v0.15.1 output when opt-out chosen; opt-in default would silently break the bidirectional test in `scripts/test-init.ps1:230-249`. <!-- gate-finding-B: actual bidirectional E.5 test is at test-init.ps1:195-205; lines 230-249 are the placeholder-leak block. Rationale stands; cosmetic mis-citation. --> |
| Q3 | AI step lives inline vs. sub-agent | Inline in SKILL.md (analyst flagged for override) | **Inline confirmed** | Sub-agent would (a) require new `.harness/agents/init-customizer.md` in `templates/common/.harness/agents/` which makes `D.1` count grow from 7 → 8 and breaks `sync-self`'s 7-agent assumption (`scripts/verify_all.ps1:88`); (b) inflate the always-loaded agent count contrary to `.harness/rules/70-doc-size.md`. Testability concern is met by `HARNESS_AI_NATIVE_MOCK` env var (see §10). |
| Q4 | Filename `50-<slug>.md` vs. overwrite `50-<type>.md` | New file with project slug | **Same — confirmed coherent with E.4b** | AI-GUIDE.md template (`skills/harness-init/templates/common/AI-GUIDE.md.tmpl:23`) currently hard-codes `50-{{PROJECT_TYPE}}.md`. **Change required**: replace that line with `50-{{PROJECT_NAME}}.md` (when opt-in) or keep `50-{{PROJECT_TYPE}}.md` (opt-out). Since both `{{PROJECT_NAME}}` and `{{PROJECT_TYPE}}` are already in the whitelist (`verify_all.ps1:94`), no new placeholder is introduced. The skill writes the correct one of the two AI-GUIDE.md lines during step 5. |
| Q5 | AI access scope | Glob top-level + named manifests | **Same** | Matches `/harness-adopt` step-2 reconnaissance (`skills/harness-adopt/SKILL.md:51-65`); reusing the same enumeration cap (100 entries; boundary condition `01_REQUIREMENT_ANALYSIS.md:43`) avoids divergent behavior between the two paths. |
| Q6 | Citation format | Inline `<!-- source: path -->` HTML comments | **Same** | Renders invisible in viewers, preserves provenance for downstream agents, doesn't conflict with the skill template's section structure. Verified by re-reading `templates/fullstack/.harness/rules/50-fullstack.md`: no existing comment convention to collide with. |
| A1 | How is the AI invoked? | (not asked) | **Direct prompt by the orchestrator AI executing the skill** (no separate `Bash` call to a CLI, no MCP) | The skill is already executing inside the AI tool; asking the same model to draft 50-100 lines of Markdown is one in-context completion, not a tool call. Keeps the skill tool-agnostic (Claude Code, Copilot, Cursor all run skills the same way). No new dependency. |
| A2 | Error handling on AI failure | (analyst said "fallback to static stub + log") | **Same, plus deterministic detector**: skill checks four invariants post-generation (sections present, no `{{...}}`, line count, no reserved partition names). Failing any invariant triggers fallback. | Single fail-fast detector keeps the skill prompt short and the failure mode predictable. Verified by D.3 check post-init. |
| A3 | Mocking strategy for tests | (not asked) | **Env-var-controlled canned-response file**: skill reads `HARNESS_AI_NATIVE_MOCK` env var; if set to a path, the skill substitutes that file's content for the AI completion. test-init sets it to `skills/harness-init/templates/common/scripts/ai-native-mock.json` (shipped fixture). | Avoids needing a real LLM call in CI; the fixture is also useful for users who want to dry-run. JSON because the fixture includes both the `50-*.md` body and an array of partition-agent drafts. |

## 4. File-level change set

| Status | Path | Note |
|---|---|---|
| M | `skills/harness-init/SKILL.md` | Add Q6 to step 2; add step 5b "AI customization (opt-in)"; document mock env var; bump `allowed-tools` comment if needed (no actual tool changes) |
| M | `skills/harness-adopt/SKILL.md` | Add Q6 equivalent to step 3 question list; add step 4b "AI rule synthesis (opt-in)" between current step 4 and step 5; update the `## Files I will add` section in step 5's plan template to mention `50-<slug>.md` conditionally |
| A | `skills/harness-init/templates/common/.harness/rules/_ai-native-prompt.md` | Canonical AI prompt as a shipped reference (the skill quotes from it; users can read it after init to understand what the AI saw) |
| A | `skills/harness-init/templates/common/scripts/ai-native-mock.json` | Canned mock response for `HARNESS_AI_NATIVE_MOCK`: `{ "rule_md": "...", "partition_agents": [{"name":"dev-payments","body":"..."}] }` |
| M | `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` | Replace hard-coded `50-{{PROJECT_TYPE}}.md` index line with a conditional: skill writes either `50-{{PROJECT_TYPE}}.md` (opt-out) or `50-{{PROJECT_NAME}}.md` (opt-in). Implementation = skill runs an Edit on the freshly-copied AI-GUIDE.md after Q6 is answered |
| M | `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` (if it exists; check during dev — see Open issues) | Same conditional line as English version |
| M | `scripts/verify_all.ps1` | Add `D.3` check (see §9); update `Step "I.2"` to include the new file naturally (it already globs `.harness/rules/*.md`) |
| M | `scripts/verify_all.sh` | Symmetric `D.3` |
| M | `scripts/test-init.ps1` | Add `Test-Type-AINative` variant per project type: one opt-in case (mock fixture) + one opt-out case (bidirectional, AC-3 + AC-10). Asserts AC-1, AC-2, AC-4-AC-8, AC-11 |
| M | `scripts/test-init.sh` | Symmetric Bash variant. Skip if `python3` absent (matches existing `init_have_python` gate) |
| M | `docs/manual-e2e-test.md` | Bump assertion count per insight-index line 14 ("Releases shipped feature code + CHANGELOG but left … manual-e2e-test counts at pre-release values") |
| M | `README.md` line 256 | Flip "0.16+ planned" → mark v0.16.0 done; add a short v0.16.0 row mirroring v0.15.x format |
| M | `README.zh-CN.md` | Mirror README.md change |
| M | `CHANGELOG.md` | Add `## [0.16.0] — 2026-05-…` entry |
| M | `.claude-plugin/plugin.json` | Bump version → `0.16.0` (G.3 enforces) |
| M | `.claude-plugin/marketplace.json` | Bump version → `0.16.0` |
| M | `AI-GUIDE.md` (this repo, dogfood) | Update line 67 check-count from "28 checks at v0.15.1" → "29 checks at v0.16.0" |
| M | `.harness/insight-index.md` | Append v0.16.0 lesson(s) from this delivery; archive-task auto-rotates if >30 lines |

**Files explicitly NOT touched** (validated):
- `.harness/agents/*.md` (all 7) — Layer-1 self-consistency
- `templates/common/.harness/agents/*.md` (all 7) — same
- `templates/fullstack/.harness/rules/50-fullstack.md` — unchanged (used in opt-out path)
- `templates/backend/.harness/rules/50-backend.md` — unchanged
- `templates/generic/.harness/rules/50-generic.md.tmpl` — unchanged
- `templates/i18n/zh/{fullstack,backend,generic}/.harness/rules/50-*` — unchanged
- `scripts/guard-rm.{ps1,sh}` and `templates/common/scripts/guard-rm.*` — unrelated
- `scripts/harness-sync.{ps1,sh}` — AI step writes directly to `.harness/`, no sync changes

## 5. Reuse audit

| Need | Existing code | File path / line | Decision |
|---|---|---|---|
| Top-level directory enumeration | `/harness-adopt` reconnaissance | `skills/harness-adopt/SKILL.md:51-65` | **Reuse pattern as-is**; init skill copies the same Glob list (`package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `README.md`) |
| Template overlay copy + `.tmpl` placeholder substitution | init step 4 + step 5 | `skills/harness-init/SKILL.md:90-145` | **Reuse**; AI customization runs AFTER step 5, so the file it writes is plain `.md` (no `.tmpl` suffix), no substitution involved |
| `AskUserQuestion` multi-question batch | init Q1-Q5 + adopt Q1-Q5 | `skills/harness-init/SKILL.md:46-75` | **Extend** to include Q6 in the same single call (no extra dialog turn) |
| Placeholder-whitelist guard | D.2 | `scripts/verify_all.ps1:93-107`, `verify_all.sh:74-84` | **Reuse as-is**; AI output is post-substitution plain Markdown, must not introduce new `{{...}}`. D.3 is additive |
| AI-GUIDE.md ↔ rules bidirectional check | E.4b | `verify_all.ps1:141-173`, `verify_all.sh:126-152` | **Reuse as-is**; skill MUST update AI-GUIDE.md to reference the new filename in the same write (otherwise E.4b FAILs on first user-project verify_all run) |
| Doc-size caps (200 lines for rules) | I.2 | `verify_all.ps1:284-296`, `verify_all.sh:282-294` | **Reuse as-is**; AI prompt instructs ≤200 lines (NFR-DocSize, `01_REQUIREMENT_ANALYSIS.md:75`). If AI overshoots, I.2 WARNs |
| Bidirectional test-init pattern | "AI-GUIDE.md indexes every rule" | `scripts/test-init.ps1:195-205`, `test-init.sh:158-167` | **Extend**: add inverse assertion that on opt-out, `50-<type>.md` (static) is the indexed name, and on opt-in, `50-<slug>.md` is the indexed name. Closes insight-index line 15 (one-sided assertion drift) |
| Reserved partition-agent name collision detection | Implicit in `D.1` 7-agent list | `verify_all.ps1:88` (the array) | **Reuse the array as the source of truth**; AI prompt + skill post-check both consume the same list of seven reserved names |
| Per-task PM_LOG note logging | adopt's `.harness-adopt/CONFLICTS.md` | `skills/harness-adopt/SKILL.md:190` | **Reuse pattern**; init logs fallback to `docs/features/<task>/PM_LOG.md` if running inside a `/harness` task, otherwise to `.harness-adopt/CONFLICTS.md` for adopt or stdout for greenfield init |
| Edit-tool-false-success mitigation | re-Read after Write rule | `.harness/insight-index.md:10` | **Reuse**; the skill prompt MUST instruct re-Read after writing `50-<slug>.md` before declaring success |

## 6. Detailed flow

### Happy path — `/harness-init` AI-native opt-in

1. Steps 1-5 run unchanged (confirm cwd, AskUserQuestion Q1-Q5, locate templates, copy `templates/common/` then `templates/<type>/` with `.tmpl` substitution).
2. **New step 5b.1**: `AskUserQuestion` Q6 = "AI customization (reads your stack description + top-level filenames to draft a tailored rule file; ~10s; you can edit before commit. Default: No, keep static stub)". Default answer `No`.
3. **If No**: skip to step 6. Static `50-<type>.md` is the final rule file. Done.
4. **If Yes (5b.2)**: Enumerate `Glob(*)` capped at 100 entries; Read each of the seven named manifest files if present (file size cap: 50 KB each — small safety bound; not in requirements but standard).
5. **5b.3**: Compose the AI prompt (see §7 transport). The prompt includes Q2 stack string, the enumerated entry list, and the contents of any manifest read. Output contract: a JSON object `{ "rule_md": "...", "partition_agents": [{"name": "dev-...", "body": "..."}] }` where `partition_agents` may be empty.
6. **5b.4**: If `HARNESS_AI_NATIVE_MOCK` is set to a readable path, the skill loads that file as the AI response instead of calling the model. Otherwise the orchestrator AI executes the prompt inline.
7. **5b.5**: Validate the AI response against the four invariants (sections, `{{...}}`, line cap 200, reserved names). On any failure → fall back to static `50-<type>.md`, log to `PM_LOG.md` (or stdout if no task slug), continue at step 6.
8. **5b.6**: Write `.harness/rules/50-<project-slug>.md` (slug = sanitized basename of cwd, must match `/^[a-z0-9][a-z0-9-]{0,40}$/`); re-Read to confirm bytes match.
9. **5b.7**: Delete `.harness/rules/50-<type>.md` (the static stub copied in step 4). The AI-authored file fully replaces it.
10. **5b.8**: Update `AI-GUIDE.md` (already copied with `{{PROJECT_NAME}}` substituted): replace the line `- **`.harness/rules/50-<type>.md`** ...` with the project-slug filename. One Edit, then re-Read.
11. **5b.9**: For each partition-agent draft, `AskUserQuestion` "Accept this draft as `.harness/agents/dev-<name>.md`? [Accept / Rename / Reject]". On Accept, write the file (reject names matching the seven reserved names). On Rename, take user input.
12. **5b.10**: Emit the 5-line summary (NFR-UX-2): file path, line count, partition count, source-citation count, fallback-fired flag (0/1).
13. Steps 6-11 (harness-sync, git init, hooks, baseline, summary) run unchanged.

### Happy path — `/harness-adopt` AI-native opt-in

1. Step 1 (target confirm), step 2 (reconnaissance — already produces the profile + manifest reads we need) run unchanged.
2. Step 3 `AskUserQuestion` gains Q6 (same wording as init).
3. Step 4 (extract rule candidates) runs unchanged, producing `.harness-adopt/CLAUDE.draft.md`.
4. **New step 4b**: If Q6 = Yes, run the same prompt assembly as init step 5b.3, but seed it from the step-2 reconnaissance profile (already in memory) instead of re-Globbing. Validate, write `50-<slug>.md` to `.harness-adopt/PROPOSED_RULES/50-<slug>.md` (proposed, not yet applied — adopt's apply phase is gated by the user "yes/apply" at step 5).
5. Step 5 plan template gets a new bullet: "AI-customized `.harness/rules/50-<slug>.md` (will replace the static stub)". User reviews; on "apply", step 6 moves it to `.harness/rules/`.
6. Step 6 applies. Partition drafts (if any) go to `.harness/agents/dev-*.md` with the same Accept/Rename/Reject loop as init.

## 7. Data shapes / file contracts

### Generated `50-<project-slug>.md` — required structure

Section list in order (matches `templates/fullstack/.harness/rules/50-fullstack.md` skeleton): <!-- gate-finding-C: actual structural match is with `templates/generic/.harness/rules/50-generic.md.tmpl`, not 50-fullstack.md. Cosmetic mis-citation; the mandate itself (six fixed headings) is internally consistent. -->

```markdown
# 50 — Project-specific rules ({{PROJECT_NAME}})

> Generated {{TODAY}} by AI customization step. Provenance via `<!-- source: ... -->`.

## When to read
<!-- source: user-q2 -->
…

## Build / test / verify
<!-- source: package.json -->  (or Cargo.toml / pyproject.toml / user-q2)
- Build: `<command>`
- Test: `<command>`
- Lint / typecheck: `<command>`

## Project structure
<!-- source: top-level-glob -->
- …

## Stack-specific conventions
<!-- source: user-q2 -->
- …

## Partitioning
<!-- source: top-level-glob -->
- (block describing detected or proposed partitions, or "single developer")

## Stack-specific verify_all checks
<!-- source: package.json -->
- (optional bullets)
```

Required headings (regex-checked by D.3 + AC-6): `^## When to read`, `^## Build / test / verify`, `^## Project structure`, `^## Stack-specific conventions`, `^## Partitioning`, `^## Stack-specific verify_all checks`.

### Source annotation format

`<!-- source: <tag> -->` where `<tag>` is one of: `user-q2`, `top-level-glob`, or a literal repo-relative path (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`, `README.md`, `requirements.txt`). Any other tag = AI invention = D.3 FAIL.

### Mock fixture shape (`scripts/ai-native-mock.json`)

```json
{
  "rule_md": "# 50 — Project-specific rules (test-project)\n\n## When to read\n...",
  "partition_agents": [
    { "name": "dev-payments", "body": "---\nname: dev-payments\n..." }
  ]
}
```

The skill loads this when `HARNESS_AI_NATIVE_MOCK` points at a readable file; on parse error, fallback path triggers (testing the fallback itself).

### AI prompt (transport)

The orchestrator AI receives a prompt that is the verbatim content of `templates/common/.harness/rules/_ai-native-prompt.md` (shipped as a reference, also embedded in the skill) with these variables filled at runtime:

```
PROJECT_NAME: <slug>
PROJECT_TYPE: <fullstack|backend|generic>
STACK: <Q2 free text>
TOP_LEVEL: <≤100 newline-separated names>
MANIFESTS: <name + first 50 KB body each, separated by --- markers>
```

Output: a JSON object as shown above. No streaming, no tool calls during the AI step (NFR-Safety-1).

## 8. Error handling / fallback

| Failure mode | Detection | Deterministic behavior |
|---|---|---|
| AI returns malformed JSON | `JSON.parse` throws (or PowerShell `ConvertFrom-Json` errors) | Fall back to static `50-<type>.md`; log `[AI-FALLBACK] parse error` to `PM_LOG.md` or stdout; continue init |
| AI returns valid JSON but `rule_md` missing required heading | Regex check against six required headings | Fall back; log `[AI-FALLBACK] missing heading: <name>` |
| AI emits `{{...}}` literal | Regex `\{\{[A-Z_]+\}\}` over `rule_md` | Fall back; log `[AI-FALLBACK] leaked placeholder`; this also protects D.2 |
| AI emits >200 lines | `(rule_md -split "`n").Length -gt 200` | Write the file (NFR-DocSize is WARN-only); print one-time end-of-init warning telling user I.2 will WARN |
| AI proposes partition name in reserved set | String compare to the seven-name array | Drop that partition silently; if all were dropped, the partition_agents list is empty (acceptable per boundary condition) |
| Skill writes the file but re-Read shows different bytes | Compare `Get-Content -Raw` to the string just written | Retry once; on second mismatch, fall back to static stub (per insight-index line 10) |
| `HARNESS_AI_NATIVE_MOCK` set but file unreadable | Test-Path / -f check | Treat as AI failure → fallback path; this lets tests exercise the fallback branch |

All fallback paths exit init/adopt with status 0 (AC-11) and leave the static stub in place.

## 9. verify_all impact

**Today**: 28 checks at v0.15.1 (per `AI-GUIDE.md:67`).

**Added**:

| Check | What it asserts | Severity |
|---|---|---|
| `D.3` "AI-generated 50-*.md sanity" | For each `.harness/rules/50-*.md` file, regex-assert all six headings present in order; assert ≥1 `<!-- source: ... -->` annotation; assert zero `{{...}}` placeholders | FAIL |

**Modified**:
- None. D.2 (placeholder whitelist), E.4b (AI-GUIDE indexing), I.2 (rule-file size), I.6 (retired-claim guard) already cover what the new file needs. No new placeholder is introduced (decision Q4).

**Target after v0.16.0**: **29 checks** (28 + D.3). The `AI-GUIDE.md:67` and `README.md` "checks at" claims must be bumped together (G.3 enforces version stamp consistency but not check-count claims; manual sync per insight-index line 14).

## 10. test-init impact

**Today**: 177 assertions across 3 project types (`scripts/test-init.ps1`, `test-init.sh`; per AI-GUIDE references — actual count to be re-counted post-implementation, see Open issues).

**Added per project type** (×3 = ×3 + maybe an i18n×zh pass later):

| # | Assertion | Tied to AC |
|---|---|---|
| 1 | Opt-out path: `.harness/rules/50-<type>.md` exists, byte-equals static template (AC-3, AC-10 bidirectional half A) | AC-3, AC-10 |
| 2 | Opt-out path: `50-<slug>.md` does NOT exist (bidirectional half B) | AC-10 |
| 3 | Opt-in path: `50-<slug>.md` exists | AC-1 |
| 4 | Opt-in path: `50-<type>.md` does NOT exist (replaced) | AC-3 |
| 5 | Opt-in path: file contains NONE of the literal placeholder phrases (`<your build command>`, `<your test command>`, `<your linter>`) | AC-1 |
| 6 | Opt-in path: all six required headings present in order | AC-6 |
| 7 | Opt-in path: ≥1 `<!-- source: -->` annotation | AC-7 |
| 8 | Opt-in path: AI-GUIDE.md references `50-<slug>.md` (not `50-<type>.md`) | AC-8 / E.4b |
| 9 | Opt-in path: zero `{{...}}` literals | AC-8 / D.2 |
| 10 | Opt-in path: file line count ≤200 (PASS) or, with overflow fixture, I.2 WARN as expected | AC-5 |
| 11 | Mock-error path (`HARNESS_AI_NATIVE_MOCK` points at garbage file): static stub remains, init exits 0 | AC-11 |
| 12 | Partition acceptance: with mock fixture proposing `dev-payments`, file is NOT written without the second Accept (achieved by setting `HARNESS_AI_NATIVE_PARTITION_DECISION=reject`) | AC-4 |
| 13 | Partition acceptance: with `=accept`, `.harness/agents/dev-payments.md` IS written | AC-4 |
| 14 | Reserved-name collision: mock proposes `dev-developer`; assert NOT written, dropped silently | Boundary FR-5 |

**Mocking strategy** (decision A3): the skill reads `HARNESS_AI_NATIVE_MOCK` env var; if set to a path, the file's content is used as the AI response. The test sets `$env:HARNESS_AI_NATIVE_MOCK = "<tempdir>/scripts/ai-native-mock.json"` before invoking the simulated skill flow. The fixture is shipped under `templates/common/scripts/` so users can also dry-run AI-native locally with `HARNESS_AI_NATIVE_MOCK=scripts/ai-native-mock.json` after init.

The bash side gates on `python3` availability (same pattern as existing PreToolUse assertions, `test-init.sh:198-249`). Headings count grep falls back to plain `grep -c`.

**Estimate**: ~14 new assertions × 3 project types = 42 new assertions → **177 → ~219**.

## 11. Backwards-compat proof

AC-3 binds: opt-out path must overwrite nothing. AC-10 binds: a v0.16 init with all five existing answers + Q6=No must produce byte-identical output to v0.15.1.

**Specific inputs the bidirectional test passes with**:
- Project type ∈ {fullstack, backend, generic}
- Stack: existing fixture values (`Next.js + NestJS + Postgres`, `FastAPI + Postgres`, `Rust CLI tool`)
- Q3 (hooks): `false` (current default)
- Q4 (partitioning): partitioned for fullstack/backend, single for generic (current defaults)
- Q5 (language): `en`
- **Q6 (new): `No`** → static template path, identical to v0.15.1

The proof reduces to assertion #1 + #2 in §10. Both must pass for AC-10.

## 12. Partition assignment

`Partition assignment: N/A — single developer (this repo has only the generic `.harness/agents/developer.md`; no `dev-*.md` files in this project).` Confirmed via Glob: `.harness/agents/` lists exactly 7 files (pm-orchestrator, requirement-analyst, solution-architect, gate-reviewer, developer, code-reviewer, qa-tester).

## 13. Risks (design-level)

| Risk (from §Risks of 01) | Design countermeasure |
|---|---|
| R1 Hallucination | Prompt + D.3 enforcement; source-citation discipline; `<your X command>` placeholders if AI doesn't know |
| R2 Repo-scan cost | Enumerate cap 100 entries + named-manifest-only read + 50 KB per-manifest cap (architect-added) |
| R3 Placeholder whitelist drift | D.2 unchanged; AI prompt explicitly forbids `{{...}}` (NFR-Safety-2); D.3 also checks |
| R4 Edit-tool false success | Skill re-Reads after each Write; on bytes mismatch, retry once then fall back (architect-added) |
| R5 One-sided assertion drift | test-init §10 assertions #1+#2 explicitly bidirectional |
| R6 AI substitutes `{{STACK}}` early | Out of order by construction: AI step is 5b, placeholder substitution is 5; AI output is plain Markdown only (no `.tmpl` involvement) |
| R7 Partition name collision | Reserved-name array shared with `D.1`; reject before user sees |
| R8 Long-term maintainability divergence | Mandated section structure (D.3) keeps shape uniform |
| **R9 (architect-added)** AI-GUIDE.md not updated to reference `50-<slug>.md` | Skill writes both files in the same step 5b sequence; re-Read after AI-GUIDE Edit; E.4b catches any miss on next `verify_all` |
| **R10 (architect-added)** i18n/zh AI-GUIDE.md.tmpl drift if it exists | Open issue: dev must Glob `templates/i18n/zh/common/AI-GUIDE.md.tmpl` first to confirm presence; if present, apply the same change. Surface in dev plan |
| **Accepted residual**: AI may invent a plausible build command (e.g. `pnpm test` when project actually uses `npm test`) | Accepted; mitigated by source-citation requirement (user can see `<!-- source: user-q2 -->` and override). NFR-Safety-2 in the prompt is mitigation, not elimination |

## 14. Open issues for Gate Reviewer

1. `templates/i18n/zh/common/AI-GUIDE.md.tmpl` — confirm presence/absence in current tree (Glob shows zh overlay translates a defined list at `skills/harness-init/SKILL.md:99-102`, AI-GUIDE.md is NOT listed there, so the zh overlay likely does NOT have its own AI-GUIDE.md.tmpl, but Developer should Glob to confirm before declaring done).
2. Exact v0.16.0 CHANGELOG wording — left for Developer / Gate.
3. test-init total assertion count after this change — must be measured post-implementation and reflected in `docs/manual-e2e-test.md` per insight-index line 14.

None of the above block design approval.

## 15. Verdict

`READY FOR GATE REVIEW`
