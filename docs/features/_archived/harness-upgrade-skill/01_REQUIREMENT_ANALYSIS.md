# 01 — Requirement Analysis: `/harness-upgrade` skill (T-012)

> Stage 1 (Requirement Analyst). Mode: **full**. Inputs are read-only.
> No INPUT.md file existed in the task folder; the verbatim request was supplied
> by the PM in the dispatch prompt and is treated as the read-only request of record.

## 1. Goal

Provide a single self-bootstrapping command, `/harness-upgrade`, that brings a
project initialized with an older harness-kit version up to the current plugin
version's layout and script contents, non-destructively, idempotently, and with a
dry-run preview, then proves the result with a green `verify_all`.

## 2. In-scope behaviors

Each behavior is numbered and testable. "The skill" = the `/harness-upgrade` skill
(plus any helper script the Architect introduces). Behaviors describe WHAT, not HOW.

1. **B-1 Target confirmation.** The skill runs against the current working
   directory. It halts with a user-facing message and changes nothing if the cwd
   is not a git repository (`.git/` absent) or has no harness setup at all (no
   `.claude/settings.json` AND no `.harness/` AND no top-level `scripts/harness-sync.*`).
2. **B-2 Gap detection (diagnose-before-act).** Before any change, the skill
   reports which of these gap conditions are present:
   (a) pre-T-007 layout — harness-owned scripts under top-level `scripts/` rather
   than `.harness/scripts/`;
   (b) missing migration helper — `migrate-scripts-layout.{ps1,sh}` absent from the
   project;
   (c) stale script CONTENT — one or more harness-owned scripts differ from the
   current-plugin template equivalent;
   (d) stale git hook path — `.git/hooks/pre-commit` references the old
   `scripts/harness-sync.*` path (or is absent);
   (e) stale settings hook paths — `.claude/settings.json` Stop / PreToolUse
   commands reference the old `scripts/` path.
3. **B-3 Self-bootstrap of the helper.** The skill places the current-plugin
   `migrate-scripts-layout.{ps1,sh}` (and any other helper it needs) into the
   project from the plugin template cache. The skill MUST NOT assume
   `migrate-scripts-layout.*` already exists in the project (the chicken-and-egg
   case is the primary motivation).
4. **B-4 Relocation.** The skill performs (or invokes) the `scripts/` →
   `.harness/scripts/` relocation for the known harness-owned script set, using
   the same known-set + git-mv-preserving semantics as the existing
   `migrate-scripts-layout` helper. Custom `scripts/<user>` files are never moved.
5. **B-5 Pre-commit hook re-install.** The skill re-installs `.git/hooks/pre-commit`
   so it points at `.harness/scripts/harness-sync.*`, using the current-plugin
   `install-hooks.{ps1,sh}`. After upgrade the hook hard-references the new path,
   not the removed old path.
6. **B-6 `verify_all` content refresh.** The skill replaces / updates the project's
   `verify_all.{ps1,sh}` with the current-plugin logic, performing the type-specific
   `.tmpl` placeholder substitution (`{{PROJECT_NAME}}`, `{{STACK}}`, `{{TODAY}}` at
   minimum; only placeholders the current template actually contains). The refresh
   strategy (full-regenerate vs merge-in) is governed by OQ-3.
7. **B-7 Settings hook-path rewire.** The skill rewires the `scripts/` →
   `.harness/scripts/` command paths in `.claude/settings.json` (Stop + PreToolUse +
   permissions.allow + doc strings), preserving file shape and documentation keys
   (the existing helper's surgical raw-text replace already does this — the skill
   reuses that behavior, it does not re-serialize the JSON).
8. **B-8 Final gate.** After all changes, the skill runs `verify_all` and reports
   its PASS/WARN/FAIL summary to the user. A non-zero `verify_all` after upgrade is
   surfaced explicitly (it is not silently swallowed).
9. **B-9 Dry-run preview.** The skill supports a dry-run mode that prints the
   complete plan (every gap, every file it would add/move/rewrite/rewire) and
   changes nothing on disk.
10. **B-10 Idempotence.** Running the skill a second time on an
    already-upgraded project performs no destructive change and reports
    "already current / nothing to do" for the parts already at target.
11. **B-11 Cross-platform parity.** Every script-layer artifact the skill creates
    or refreshes exists as a symmetric PowerShell + Bash pair with equivalent
    behavior (hard project rule; see NFR-1).
12. **B-12 Root-derivation correctness (insight L31).** After relocation, every
    relocated/refreshed harness-owned script resolves the repo root correctly from
    its new `.harness/scripts/` depth (two-up), not the pre-T-007 one-up. The skill
    does not leave a script whose root derivation is stale for its new location.
13. **B-13 Version targeting.** The skill targets the current installed plugin
    version, discovered from the plugin cache (`.claude-plugin/plugin.json`
    `version`), and reports the project's detected starting state and the target
    version in its plan.

## 3. Out-of-scope (this iteration)

- **OOS-1** Adopting harness into a project that has NO harness setup at all — that
  is `/harness-adopt`'s job. `/harness-upgrade` is "has harness, but old".
- **OOS-2** A general semantic merge of user-customized rule fragments
  (`.harness/rules/50-*.md`, `80-*.md`). The skill does not rewrite hand-authored
  rule content.
- **OOS-3** Migrating the v0.1.x → v0.2.0 layout transition (the manual
  `CLAUDE.md` → `.harness/rules/` split documented in `MIGRATION.md` lines 37-265),
  UNLESS OQ-6 resolves to include it. Default scope (see OQ-6) is the
  post-v0.2 path (T-007 relocation + content refresh), not the v0.1 split.
- **OOS-4** Upgrading agents / skills / rules CONTENT (not just scripts), UNLESS
  OQ-5 resolves to include it. Default: scripts + hooks + settings + verify_all
  only; agents/skills/rules content deferred.
- **OOS-5** Running package-manager installs or modifying CI files (carried over
  from `/harness-adopt`'s safety stance).
- **OOS-6** Downgrade (newer project → older plugin). Out of scope.
- **OOS-7** Editing harness-kit's own dogfood tree as the upgrade target. This task
  BUILDS the skill (source under `.harness/skills/` + `skills/harness-init/templates/`);
  it does not run the upgrade on this repo.

## 4. Boundary conditions

| # | Condition | Required handling |
|---|---|---|
| BC-1 | cwd is not a git repo | Halt, no changes, clear message (B-1). |
| BC-2 | cwd has no harness setup at all | Halt; point user to `/harness-adopt` (B-1, OOS-1). |
| BC-3 | Project already fully current | Report "nothing to do", exit success (B-10). |
| BC-4 | `migrate-scripts-layout.*` absent from project | Bootstrap it from cache before relocation (B-3) — must not error on absence. |
| BC-5 | Plugin template cache not found / unresolvable | Halt with an actionable message; change nothing. |
| BC-6 | `.git/hooks/pre-commit` absent entirely | Treat as a gap (B-2d); install fresh (B-5). |
| BC-7 | `.git/hooks/pre-commit` was hand-customized by the user (not the harness stock hook) | See OQ-7 — default is to detect a non-stock hook, NOT overwrite it, and surface it as a conflict. |
| BC-8 | `verify_all.*` was hand-customized by the user (B.* checks filled in) | The refresh must not silently discard user B.* customizations — governed by OQ-3. |
| BC-9 | Project type/stack not recoverable from any artifact | See OQ-4 — default is to ask the user; never guess the type for substitution. |
| BC-10 | Working tree is dirty (uncommitted changes) | See OQ-8 — default is to refuse and ask the user to commit first (preserves rollback). |
| BC-11 | `.claude/settings.json` already migrated (paths already `.harness/`) | Settings rewire is a no-op fixed point (existing helper already guarantees this). |
| BC-12 | A relocation target already exists at `.harness/scripts/<name>` | Honor the existing helper's SKIP-unless-Force semantics; do not clobber without an explicit force/overwrite decision. |
| BC-13 | Mixed state (some scripts relocated, some not; some stale, some current) | Each gap is handled independently; partial prior progress does not break the run (B-10 idempotence applies per-artifact). |
| BC-14 | `verify_all.*` is absent entirely (e.g. older project that lost it) | Treat as a content gap; generate fresh from the type template. |
| BC-15 | Project is not a Claude-Code project (no `.claude/settings.json`) but has `.harness/scripts/` | See OQ-9 — default is to still refresh scripts + hooks and skip the settings rewire with a logged note. |

## 5. Acceptance criteria

Numbered for QA. Each is observable/testable. "Old fixture" = a synthetic project
reproducing the pre-T-007 state (scripts under `scripts/`, no migration helper,
pre-commit pointing at `scripts/harness-sync.*`, an old short `verify_all`).

- **AC-1** Given an old fixture, running `/harness-upgrade` (real, not dry-run)
  ends with the harness-owned scripts present under `.harness/scripts/` and absent
  from top-level `scripts/`, while any non-harness `scripts/<custom>` file is
  untouched.
- **AC-2** After AC-1, `.git/hooks/pre-commit` exists and references
  `.harness/scripts/harness-sync.*` (not `scripts/harness-sync.*`); a commit
  triggers the drift check (it does not silently skip).
- **AC-3** After AC-1, `.claude/settings.json` Stop + PreToolUse + permissions.allow
  command paths reference `.harness/scripts/`, the file still parses as JSON, and
  its non-`hooks` documentation keys are preserved (existing helper behavior is
  retained).
- **AC-4** After AC-1, `verify_all.{ps1,sh}` contains the current-plugin check set
  (verifiable by presence of at least one check id that did not exist in the old
  fixture's `verify_all`), with no unsubstituted `{{...}}` placeholder remaining in
  the rendered file.
- **AC-5** After AC-1, every relocated/refreshed harness-owned script resolves the
  repo root correctly from `.harness/scripts/` (two-up): invoking each script from
  the project root succeeds in finding the repo root (no "file not found / wrong
  path" failure attributable to one-up derivation). (Directly tests insight L31.)
- **AC-6** Running `/harness-upgrade` a second time on the AC-1 result reports
  "already current / nothing to do" (or per-artifact equivalent) and makes zero
  file-content changes (verifiable by a clean `git status` / unchanged file hashes
  for harness-owned files).
- **AC-7** Running `/harness-upgrade` in dry-run mode on the old fixture prints the
  full plan and leaves the fixture byte-for-byte unchanged.
- **AC-8** After a real run on the old fixture, the skill runs `verify_all` and
  reports its PASS/WARN/FAIL summary; a green result is the success signal, and a
  non-green result is surfaced verbatim (not hidden).
- **AC-9** The skill self-bootstraps: on a fixture that has NO
  `migrate-scripts-layout.*`, the upgrade still completes (proves B-3 — no
  dependency on the helper pre-existing).
- **AC-10** Every script-layer artifact the skill adds/refreshes is a PowerShell +
  Bash pair, and the upgrade produces equivalent end-state when driven from either
  shell on a fresh copy of the same fixture (cross-shell parity matrix).
- **AC-11** Running `/harness-upgrade` on a project with no harness setup at all
  halts without changes and directs the user to `/harness-adopt` (BC-2 / OOS-1).
- **AC-12** The skill detects and reports the project's starting state and the
  target plugin version (from `.claude-plugin/plugin.json`) in its plan (B-13).
- **AC-13** (Conditional on OQ-3 resolution) If "merge-in" is chosen: an old
  fixture whose `verify_all` has a user-authored B.* check retains that B.* check
  after refresh. If "full-regenerate" is chosen: the skill warns the user that B.*
  customizations are reset to template TODOs before applying. (QA verifies whichever
  branch OQ-3 selects.)
- **AC-14** The new skill is shipped through BOTH source-of-truth surfaces and
  passes `verify_all` on THIS repo: the skill source under `.harness/skills/<name>/`
  (synced to `.claude/skills/`), its distributed copy under `skills/<name>/`, and —
  if the Architect adds a helper script or a new placeholder — the corresponding
  template + dogfood + D.2 whitelist obligations (see "Downstream obligations").
- **AC-15** Skill count and any check/placeholder/version claims are updated
  consistently across `plugin.json`, `marketplace.json`, README badges, AI-GUIDE.md,
  getting-started, and CHANGELOG, such that `verify_all` G.3/G.4 PASS (adding a
  12th→13th skill is a version-worthy change — insight L33).

## 6. Non-functional requirements (only the material ones)

- **NFR-1 Cross-platform parity (hard rule).** PowerShell + Bash symmetry for every
  script-layer artifact; the two shells produce equivalent end states. Enforced by
  `verify_all` script-pair checks and the AC-10 parity matrix.
- **NFR-2 Non-destructive / recoverable.** No harness-owned file content is lost.
  Settings edits write a timestamped `.bak` (existing helper behavior). Git history
  preserves relocated content via `git mv`. The guaranteed-recovery mechanism is
  OQ-2 (backup vs git-clean-tree precondition vs both).
- **NFR-3 Safe on a stranger's repo.** No package installs, no CI edits, no network
  calls, no destructive operations outside the project tree (consistent with the
  guard-rm safety layer and `/harness-adopt`'s stance).
- **NFR-4 Idempotent.** Re-running is safe and converges to a fixed point (B-10).

## 7. Related tasks

- **T-007 / scripts-relocation** (`docs/features/_archived/scripts-relocation/`) —
  introduced `.harness/scripts/` layout + the `migrate-scripts-layout.{ps1,sh}`
  helper this skill orchestrates and bootstraps. Source of insight L31
  (root-derivation depth). Read its delivery before design.
- **T-006 / harness-batch-skill** (`docs/features/_archived/harness-batch-skill/`) —
  most recent "add a new skill" task; precedent for the skill-count / README /
  AI-GUIDE / CHANGELOG fan-out (insight L33 family).
- **T-002 / ai-native-init** (`docs/features/_archived/ai-native-init/`) — precedent
  for the `.tmpl` placeholder + D.2 whitelist discipline (insights L11, L20).
- **`/harness-adopt`** (`skills/harness-adopt/SKILL.md`) — the sibling skill; its
  non-destructive plan/confirm/apply structure, template-cache discovery, and
  settings.json merge handling are the closest design precedent. `/harness-upgrade`
  is its complement (old-harness vs no-harness).
- **`MIGRATION.md`** — the manual upgrade guide this skill automates/supersedes;
  it already advertises `/harness-upgrade` as "planned v0.3" (lines 43-45).

## 8. Open questions for user

Each has a recommended **default** marked as **ASSUMPTION** so the Architect/Gate can
challenge it. Per the agent contract, the presence of these makes the verdict
`BLOCKED ON USER`.

- **OQ-1 — Skill alone, or skill + new helper script?**
  The project's own principle is mechanical/deterministic → script; judgment/semantic
  → AI. The relocation + settings rewire + hook install are already deterministic
  scripts; the gap-diagnosis, type detection, and verify_all merge involve judgment.
  - (a) **Skill orchestrates existing scripts only** (`migrate-scripts-layout`,
    `install-hooks`) + AI does diagnosis/type-detect/verify_all refresh inline.
  - (b) **Skill + one new deterministic helper** (`upgrade-project.{ps1,sh}`) that
    wraps relocation + hook install + settings rewire; AI does only the judgment
    parts (gap report, type detect, verify_all merge decision).
  - **ASSUMPTION / default: (b)** — a single deterministic helper makes idempotence,
    dry-run, and cross-shell parity testable as a unit, and keeps the AI layer to
    genuine judgment. Confirm.

- **OQ-2 — Backup / rollback guarantee for "non-destructive".**
  - (a) Require a clean git working tree as a precondition; rollback = `git reset`.
  - (b) Write timestamped `.bak` files for every modified file; no git precondition.
  - (c) Both: require clean tree AND write `.bak` for non-git-tracked edits (e.g.
    `.git/hooks/pre-commit`, `.claude/settings.json`).
  - **ASSUMPTION / default: (c)** — git covers tracked files (relocation, verify_all),
    `.bak` covers the two untracked surfaces (hook, settings). This is the strongest
    "non-destructive" claim and matches the existing helper's `.bak`-on-settings
    behavior. Confirm. (Interacts with BC-10.)

- **OQ-3 — `verify_all` refresh thoroughness (the fiddliest trade-off).**
  - (a) **Full regenerate** from the type `.tmpl` with placeholder substitution —
    simplest, deterministic, but RESETS any user-authored B.* build/test/lint checks
    to template TODOs.
  - (b) **Merge-in only the new check sections** — preserves user B.* customizations
    but requires judgment to splice (AI layer), is harder to make idempotent, and
    risks partial merges.
  - **ASSUMPTION / default: (a) full regenerate WITH a loud pre-warning + `.bak` of
    the old verify_all**, because (i) the generic/template `verify_all` already tells
    users to add B.* on the first task, so most upgraded projects' B.* are still TODO
    stubs; (ii) full-regenerate is the only fully-deterministic, idempotent,
    parity-testable option; (iii) the `.bak` lets a user re-apply their B.* by hand.
    Confirm — this is a real UX trade-off and the user may prefer (b).

- **OQ-4 — How is the project's type/stack detected for the refresh?**
  Init does NOT persist `PROJECT_TYPE` anywhere as a stored value (it is a
  substitution-time placeholder only). It IS recoverable from two artifacts: the
  `.harness/rules/50-<type>.md` filename, and the `=== verify_all (<type>) ===`
  header line in the existing script.
  - (a) Infer from `50-<type>.md` filename (fullstack/backend/generic).
  - (b) Infer from the old `verify_all`'s `=== verify_all (<type>) ===` header.
  - (c) Re-run `/harness-adopt`-style reconnaissance to infer type.
  - (d) Always ask the user via `AskUserQuestion`, pre-filled with (a)/(b) inference.
  - **ASSUMPTION / default: (d) ask, pre-filled from (a) then (b)**; never silently
    guess the type for substitution (BC-9). For `generic`, `{{STACK}}` is free-text
    and must come from the user (it cannot be reliably recovered). Confirm.

- **OQ-5 — Are agents / skills / rules CONTENT in scope for v1?**
  The motivating incident is scripts + hooks + settings + verify_all. Agent/skill
  content also goes stale across versions, but refreshing it is a different problem
  (harness-sync already regenerates `.claude/` from `.harness/`, but `.harness/agents`
  themselves are init-time snapshots).
  - (a) v1 = scripts + hooks + settings + verify_all ONLY; agents/skills/rules
    deferred to a later version.
  - (b) v1 also refreshes `.harness/agents/*.md` from the current templates
    (rules/skills excluded as bespoke).
  - **ASSUMPTION / default: (a)** — scope v1 to the incident; defer agent/skill/rule
    content. Confirm. (This is OOS-4.)

- **OQ-6 — Lowest source version the upgrade supports.**
  - (a) Post-v0.2 only (T-007 relocation + content refresh); v0.1.x projects keep
    using the manual `MIGRATION.md` steps.
  - (b) Also automate the v0.1.x → v0.2.0 `CLAUDE.md` → `.harness/rules/` split
    (the judgment-heavy Step 4 in `MIGRATION.md`).
  - **ASSUMPTION / default: (a)** — the v0.1 split needs semantic judgment and is
    rare; automating it materially enlarges v1. Confirm. (This is OOS-3.)

- **OQ-7 — A hand-customized (non-stock) `.git/hooks/pre-commit`.**
  - (a) Detect non-stock content; do NOT overwrite; surface as a conflict for the
    user to merge.
  - (b) Always overwrite with the current stock hook (`.bak` the old one first).
  - **ASSUMPTION / default: (a)** — non-destructive stance; only re-install when the
    hook is the harness stock hook or is absent. Confirm. (BC-7.)

- **OQ-8 — Dirty working tree precondition.**
  - (a) Refuse to run on a dirty tree; ask the user to commit/stash first.
  - (b) Run anyway; rely on `.bak` files for recovery.
  - **ASSUMPTION / default: (a)** — refusing on a dirty tree preserves the clean
    `git reset` rollback path and matches `MIGRATION.md`'s "clean tree first"
    guidance. Confirm. (BC-10; interacts with OQ-2.)

- **OQ-9 — Non-Claude-Code projects (no `.claude/settings.json`).**
  - (a) Still refresh scripts + hooks + verify_all; skip the settings rewire with a
    logged note.
  - (b) Treat absence of `.claude/settings.json` as "not a harness project" and halt.
  - **ASSUMPTION / default: (a)** — the `.harness/` layer is tool-agnostic; a
    Copilot/Cursor project can have `.harness/` without `.claude/settings.json`.
    Confirm. (BC-15.)

- **OQ-10 — Skill name and version slot.**
  - (a) `/harness-upgrade` (the name `MIGRATION.md` already advertises), shipped as
    the next minor (v0.23.0).
  - (b) A different name / version slot.
  - **ASSUMPTION / default: (a)** — match the long-advertised name; ship as the next
    minor. Confirm.

## 9. Downstream obligations (flagged per insights L11/L30/L31/L33/L35)

These are NOT design decisions; they are constraints the Architect MUST honor and
the Gate MUST check, surfaced now so they are not discovered late.

- **DO-1 (L31, T-007).** Any relocated/refreshed script must derive repo root as
  two-up from `.harness/scripts/`. A path-string find/replace is insufficient — the
  root derivation is a separate correctness concern. Captured as AC-5.
- **DO-2 (L11/L20).** If the Architect introduces ANY new `{{...}}` placeholder in a
  `.tmpl`, it MUST be added to BOTH `verify_all.ps1` AND `verify_all.sh` D.2
  whitelist (currently 7 placeholders), using case-sensitive `-cnotin`. If the skill
  only reuses existing placeholders, no D.2 change is needed.
- **DO-3 (L30/L35).** Any change to `.claude/settings.json` shape must be validated
  against the upstream schema (consult via context7/WebFetch first; `verify_all` J.1
  gates it). The existing helper's raw-text rewire does NOT change shape, so reusing
  it is safe; a new approach that re-serializes would re-trigger this obligation.
- **DO-4 (L33/L34).** Shipping a new skill changes the skill count (12 → 13). That
  is version-worthy: `plugin.json` / `marketplace.json` / README badges / AI-GUIDE.md
  / getting-started / CHANGELOG must move in lockstep so G.3/G.4 PASS. If the skill
  adds a new `verify_all` check, the check-count claim moves too (and is also
  version-worthy). Captured as AC-15.
- **DO-5 (L36, same-file claim uniqueness).** If any new count/version claim is added
  to a doc that already carries a similar claim, the new claim's `expect` literal
  must be file-unique (the T-010 trap).
- **DO-6 (red lines).** Source edits go in `.harness/` (skill source under
  `.harness/skills/`) and `skills/harness-init/templates/` (helper template, if any),
  then `sync-self` (for the template→dogfood mirror) and `harness-sync` (for the
  `.harness/skills/` → `.claude/skills/` binding). Do NOT propose hand-editing
  `.claude/`, `CLAUDE.md`, or `.github/copilot-instructions.md` as the design.
- **DO-7 (L27, MSYS grep / bash discovery on Windows).** Any new bash script must
  avoid `grep -F -i` (SIGABRT on Git-for-Windows MSYS); use `shopt -s nocasematch`.
- **DO-8 (L13, bash arrays under `set -u`).** Any new bash array uses `arr=()`, never
  `declare -a arr`; loop variables for file paths are named `<thing>_file`.

## 10. Verdict

**BLOCKED ON USER.**

Ten open questions (OQ-1 .. OQ-10) carry recommended defaults but materially shape
the skill's scope and behavior (especially OQ-3 verify_all refresh strategy, OQ-1
script-vs-AI boundary, OQ-5 agent/skill content scope, and OQ-6 lowest supported
version). Per the agent contract, the verdict cannot be `READY` while open questions
remain. If the user accepts all ten ASSUMPTION defaults verbatim, the PM can flip
this to `READY` and advance to the Solution Architect with the defaults as the
agreed baseline.
