# 01 — Requirement Analysis · ai-native-init (T-002)

Mode: `full` · Stage: 1/7 · Author: Requirement Analyst · Date: 2026-05-19

## Goal

Replace the placeholder-stub `50-<type>.md` produced by `/harness-init` (and the equivalent extracted-conventions fragment produced by `/harness-adopt`) with a tailored, AI-authored rule fragment grounded in the user's actual stack description and any existing files in the target directory, and optionally emit custom partition-agent definitions derived from the real repo layout — **opt-in by default**, so v0.15 behavior remains the fallback path.

## User stories

1. As a developer running `/harness-init` on a fresh `Rust + Axum + sqlx` project I describe in Q2, I get a `50-<project>.md` whose Build/Test/Verify section lists `cargo build` / `cargo test` / `cargo clippy` (not `<your build command>` placeholders) and a Project-structure section that names `src/main.rs` and `migrations/`, so I can start work without first hand-editing the stub.
2. As a developer running `/harness-adopt` on a polyrepo with `apps/payments/`, `apps/ingest/`, `apps/mobile-ios/`, I am offered partition agents `dev-payments`, `dev-ingest`, `dev-mobile-ios` with owned-path globs matching those directories, and can accept, reject, or rename each one before any file is written.
3. As a cautious user who distrusts AI-generated content, I can answer "No, keep the static stub" in the init question and get exactly the v0.15.1 behavior — no AI pass, no surprise edits.
4. As a maintainer reviewing the generated `50-<project>.md` a week later, every fact in the file is traceable to either the user's free-text answer or a cited path in the repo (e.g. `# Source: package.json scripts.test`), so I can verify nothing was hallucinated.

## In-scope behaviors

1. Adding an opt-in AI-customization step to `/harness-init` that runs **after** the static templates are copied (step 5 in `skills/harness-init/SKILL.md`) and **before** placeholder substitution finalizes the `.tmpl` files.
2. Adding the symmetric opt-in step to `/harness-adopt`'s rule-extraction phase (step 4 in `skills/harness-adopt/SKILL.md`), producing the same AI-authored fragment alongside the keyword-extracted `80-existing-conventions.md` draft.
3. The AI customization step reads at most: the user's Q2 stack string, the target directory's top-level files (one level deep, file names only) for `/harness-init`, and the existing reconnaissance profile (step-2 output) for `/harness-adopt`.
4. The AI customization step writes exactly one file: `.harness/rules/50-<project-slug>.md` (slug = sanitized basename of cwd), replacing the static `50-<type>.md` if and only if the user confirmed opt-in.
5. The AI customization step has the option to also write `.harness/agents/dev-<name>.md` files for partitions when the user answers "yes" to a separate partition-suggestion sub-question. Each file is presented as a draft for explicit accept/reject before being written.
6. The generated `50-<project-slug>.md` honors the 200-line soft cap from `.harness/rules/70-doc-size.md`.
7. The generated `50-<project-slug>.md` keeps the same section headings as the existing `50-generic.md.tmpl` (When to read · Build / test / verify · Project structure · Stack-specific conventions · Partitioning · Stack-specific verify_all checks) so downstream agents reading it find the structure they expect.
8. Every claim in the generated fragment that is not user-supplied free text is annotated with a `<!-- source: <path> -->` HTML comment naming the file the AI inferred it from (e.g. `<!-- source: Cargo.toml -->`), or `<!-- source: user-q2 -->` for the stack string.
9. The opt-in question is added as **Q6** in `/harness-init` and as part of the existing step-3 questionnaire in `/harness-adopt`. Default answer is `No (static template only)` so the legacy path is the no-action default.
10. `verify_all` is extended with a new check that asserts: if any `.harness/rules/50-*.md` file exists, the placeholder whitelist (D.2) still passes (i.e. AI did not leave un-substituted `{{...}}` markers).
11. `scripts/test-init.{ps1,sh}` gets a new fixture that exercises the AI-native path with a mocked AI response, asserting steps 4-10 above hold.

## Out-of-scope

- Supervisor agent observing pipeline progress (separate task T-003 per roadmap).
- AI-generated edits to `.harness/agents/` for any of the 7 *pipeline* agents (RA / SA / Gate / Dev / Reviewer / QA / PM) — those stay byte-identical with `templates/common/.harness/agents/` per the Layer-1 self-consistency rule.
- AI-generated edits to existing rule fragments other than `50-*.md`. No touching `00-core.md`, `05-insight-index.md`, etc.
- Deep code analysis (parsing AST, reading every file in the repo). Limit is top-level file enumeration plus a handful of named files (`README.md`, `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`).
- A new `/harness-init-ai` skill. AI-native is a *step inside* the existing two skills, not a third skill (decision rationale in Open questions below).
- Re-running AI customization on an already-initialized project. Once `50-<project-slug>.md` exists, the user edits it by hand or asks an agent in a regular `/harness` task.
- Internationalization of AI-generated content beyond what the user's Q5 language policy already enforces.

## Boundary conditions

- **Empty target directory** (`/harness-init` happy path): AI has nothing beyond Q2 stack string. Output must still be valid Markdown with all required sections; sections it cannot fill MUST contain the same `<your build command>`-style placeholders the static stub uses today.
- **Target directory has >500 top-level entries**: AI enumeration is capped at 100 entries; the rest are summarized as `... (N more)` in the prompt. No file content is read for these.
- **AI call fails / times out / returns malformed Markdown**: the static `50-<type>.md` template is used as a fallback; init does not abort. A line is appended to `PM_LOG.md` (or, for adopt, to `.harness-adopt/CONFLICTS.md`) noting the fallback.
- **User selects opt-in but AI returns content >200 lines**: the file is written and `verify_all`'s I.* WARN fires; user is told once at end-of-init.
- **User selects opt-in but AI proposes zero partition agents**: that is the expected outcome for small repos; no error.
- **User selects opt-in AND proposes partition names that collide with the 7 pipeline agents** (e.g. `dev-developer` or `dev-pm`): names matching the reserved set `{pm-orchestrator, requirement-analyst, solution-architect, gate-reviewer, developer, code-reviewer, qa-tester}` are rejected before being shown to the user.
- **`PROJECT_TYPE` was `fullstack` or `backend`**: AI customization replaces only the `50-<type>.md` content; the partition-agent question (Q4 in init) still ships its static `dev-frontend/backend/db` (or `dev-api/services/db`) agents. AI-suggested partitions are *additive* in that case and named differently to avoid collision.

## Acceptance criteria

| AC | Tied to | Verifiable via |
|---|---|---|
| AC-1 | FR-1, FR-9 | `scripts/test-init.{ps1,sh}` runs with mocked AI response and finds `.harness/rules/50-<slug>.md` whose content does NOT contain the literal string `<your build command>` when AI succeeds |
| AC-2 | FR-3 | Same test asserts AI prompt was constructed from ≤100 enumerated entries plus the named manifest-file contents only |
| AC-3 | FR-4 | Test asserts opt-in path overwrites `50-<type>.md` and opt-out path leaves byte-identical static stub |
| AC-4 | FR-5, FR-7 | Test mocks AI returning two partition proposals; asserts files `dev-payments.md` and `dev-ingest.md` are written ONLY after a second `AskUserQuestion` accept |
| AC-5 | FR-6 | `verify_all`'s I.3 (`.harness/rules/*.md` size cap) shows PASS for the test-fixture-generated file |
| AC-6 | FR-7 | Generated file passes a regex check confirming all six required section headings are present in order |
| AC-7 | FR-8 | Every `## ` or `### ` section whose content is non-template includes at least one `<!-- source: ... -->` comment |
| AC-8 | FR-10 | `verify_all` D.2 PASS on the generated file (no leaked `{{...}}` placeholders) |
| AC-9 | FR-11 | New test-init assertions count is reflected in `docs/manual-e2e-test.md` per insight-index entry on doc resync |
| AC-10 | Backward compat | A test-init run with all five existing questions answered identically to v0.15.1 (i.e. AI customization opt-out) produces byte-identical output to v0.15.1 |
| AC-11 | NFR-fallback | A test-init run where the AI mock returns an error string produces the static stub fallback AND a logged note, and exits 0 |
| AC-12 | Whole task | `scripts/verify_all` PASSes (target ≥29/29 checks: 28 existing + at least 1 new check for AI-output sanity) |

## Non-functional requirements

- **NFR-UX-1**: The opt-in question wording names a concrete tradeoff ("AI reads your stack description and top-level filenames to draft a tailored rule file; takes ~10s; you can edit before commit. Skip for fastest, most predictable init.") so the user can choose informed.
- **NFR-UX-2**: After AI generation, the user sees a 5-line summary of what was written (file path, line count, partition count, source-citation count) before init finishes.
- **NFR-Safety-1**: AI generation is not granted any tool access beyond Read on the named manifest files. No Bash, no Write to files other than `50-<project-slug>.md` and the accepted `dev-*.md` drafts.
- **NFR-Safety-2**: The AI prompt explicitly forbids inventing build/test commands not derivable from the stack string or a read manifest. The agent contract enforces "if you don't know, write the placeholder, do not guess."
- **NFR-Compat-1**: A project initialized at v0.15.1 must continue to work without modification at v0.16; the opt-in question is additive.
- **NFR-Compat-2**: A project initialized at v0.16 with AI-native opt-out must be byte-identical to a v0.15.1 init for the same inputs (AC-10).
- **NFR-DocSize**: All AI-generated rule and agent files honor `70-doc-size.md` caps (200 lines for rules, 300 for agents).
- **NFR-Determinism-relaxed**: AI output is non-deterministic; tests use a mocked AI step. Acceptance is about *shape* (sections present, sources cited, caps honored), not exact wording.

## Related historical tasks

- T-001 / ai-safety-guardrails (`docs/features/_archived/ai-safety-guardrails/`) — established the precedent that new init-time wiring (guard-rm hook) ships via `.claude/settings.json` with `{{...}}` substitution and a `verify_all` F.* check. AI-native init reuses the same pattern for any new placeholders.
- T-000 / initial-bootstrap — established the `templates/common/` + `templates/<type>/` overlay model that AI-native must remain compatible with.
- v0.12.0 (Generic project type) — introduced `50-generic.md.tmpl` as the explicit "we will fill this in later" placeholder. AI-native is the "fill it in now, automatically" follow-through; the template author already wrote partitioning instructions in `templates/generic/.harness/rules/50-generic.md.tmpl` lines 42-54 anticipating this.
- v0.14.0 (Document size policy) — introduced the caps AI generation must respect.

## Risks

1. **Hallucination risk**: AI invents a build command (`cargo make build`) that does not exist in the user's project. Mitigated by FR-8 (source citations required) and NFR-Safety-2 (explicit "don't guess" instruction). Residual risk lives in `cargo test` style well-known defaults — acceptable because reverting is trivial.
2. **Repo-scan cost on huge directories**: enumerate cap of 100 entries (boundary condition) + named-manifest-only read keeps the worst case to ~10 file reads.
3. **Placeholder-whitelist drift** (per insight-index 2026-05-16 line): if AI ever emits a `{{...}}` it didn't substitute, `verify_all` D.2 would FAIL. AC-8 catches this; the AI prompt explicitly forbids emitting `{{...}}` literals.
4. **Edit-tool false-success risk** (per insight-index 2026-05-16 line): the implementation must re-Read the generated file before declaring success.
5. **One-sided assertion drift** (per insight-index 2026-05-16 line): test-init's new assertions must check both "opt-in produces customized output" AND "opt-out produces static output". AC-3 + AC-10 already pair these.
6. **AI substitutes `{{STACK}}` early and breaks placeholder substitution**: AI runs *after* template copy but *before* final placeholder pass in init step 5, so substitution still applies normally. Tests must verify.
7. **Partition-agent name collisions** with reserved pipeline-agent names: handled by FR-5 boundary condition.
8. **Long-term-maintainability risk**: AI-generated `50-*.md` may diverge stylistically from the hand-authored templates, making future global edits harder. Mitigated by FR-7 (section structure mandated identical) and the `<!-- source: -->` annotation discipline.

## Insight-index entries to honor

(verbatim from PM_LOG `## Insight-index entries possibly relevant to this task`)

- 2026-05-16 · Edit tool occasionally reports SUCCESS without applying the change — re-Read or Grep to verify.
- 2026-05-16 · Any new `{{...}}` placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails.
- 2026-05-16 · Releases shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values.
- 2026-05-16 · One-sided assertions hide bidirectional drift; when asserting set-membership in templates, write the inverse check too.

These translate into concrete requirements: FR-10 (placeholder whitelist sanity), AC-3+AC-10 (bidirectional opt-in/opt-out assertions), AC-9 (doc resync touchpoints), and NFR-Safety-2 (re-Read after Write is an implementation rule).

## Backwards compatibility

`v0.16` MUST NOT break v0.15 init behavior. Rationale:

- The user's directive included "long-term maintainable" and "software-engineering-standard"; silently changing what users have invoked dozens of times violates both.
- The v0.15.1 static-stub path remains the default answer to the new Q6 in init and the equivalent toggle in adopt — selecting "No" yields the v0.15.1 outcome exactly (AC-10).
- The new placeholder file name `50-<project-slug>.md` does NOT replace `50-fullstack.md` / `50-backend.md` / `50-generic.md.tmpl` in the `templates/` tree — those stay byte-identical for the opt-out path.
- New verify_all check is additive; existing 28 checks remain.

## Open questions (analyst-decided where the user authorized "your call")

1. **Skill placement**: Add AI-native to `/harness-init` only, `/harness-adopt` only, both, or a new skill?
   - Candidates: (a) init-only, (b) adopt-only, (c) both, (d) new `/harness-init-ai` skill.
   - `[ANALYST-DECIDED: (c) both · rationale: init covers greenfield where Q2 stack string is the seed; adopt covers existing code where reconnaissance findings are the seed. A new skill triples the menu and contradicts UX-first; embedding into both skills keeps the entry point as users already know it.]`

2. **Default of the new Q6 in init / equivalent in adopt**: opt-in or opt-out by default?
   - Candidates: (a) opt-out default (legacy preserved), (b) opt-in default (showcase the feature).
   - `[ANALYST-DECIDED: (a) opt-out default · rationale: a non-trivial AI step inserted into a user flow that today is deterministic violates "long-term maintainable" if defaulted on. v0.16 release notes promote the opt-in; users self-select.]`

3. **Where does the AI customization step physically live in code**: inside the skill's prompt instructions, or as a sub-agent in `.harness/agents/`?
   - Candidates: (a) inline in `skills/harness-init/SKILL.md` (the orchestrator AI does it directly), (b) a new sub-agent `init-customizer` in `.harness/agents/` and `templates/common/.harness/agents/`, (c) a callable section in an existing agent.
   - `[ANALYST-DECIDED: (a) inline · rationale: the work is one-shot per init, no pipeline gates apply, and adding an 8th agent inflates the always-loaded count. The skill prompt directs the model performing init to do the read+draft+confirm steps.]` — **Architect may override** if (b) yields better testability.

4. **Naming of the generated file**: `50-<project-slug>.md` vs replacing `50-<type>.md` in-place?
   - Candidates: (a) `50-<project-slug>.md` (new name, original stub deleted), (b) overwrite `50-<type>.md` in place, (c) keep `50-<type>.md` AND add `55-<project>.md`.
   - `[ANALYST-DECIDED: (a) replace with project-slug name · rationale: AI-GUIDE.md's bidirectional `verify_all` E.4b check already indexes whatever rule files exist; a project-named file makes the AI provenance obvious; option (c) doubles content and risks contradictions.]` — **Architect to confirm AI-GUIDE.md indexing remains coherent.**

5. **AI access scope during the customization step**: read-only-manifests vs Glob-the-whole-repo?
   - Candidates: (a) read named manifests only, (b) Glob top-level + read manifests, (c) Glob recursively.
   - `[ANALYST-DECIDED: (b) Glob top-level + named manifests · rationale: matches `/harness-adopt`'s existing reconnaissance behavior so the two paths converge; bounds cost; matches Boundary-condition 2.]`

6. **Source-citation format**: HTML comment, frontmatter block, or trailing footnotes?
   - Candidates: (a) `<!-- source: path -->` inline HTML comment after each generated paragraph, (b) YAML frontmatter listing all sources, (c) `## Sources` section at file end.
   - `[ANALYST-DECIDED: (a) inline HTML comment · rationale: comments render invisible in Markdown viewers but preserve provenance for agents reading the raw file. Frontmatter conflicts with the skill template convention. End-section gets out of sync.]`

## Verdict

`READY` — open questions resolved under user-granted analyst authority; each decision is surfaced so the Solution Architect can override with explicit rationale at stage 2.
