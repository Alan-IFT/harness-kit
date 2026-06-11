# 01 — Requirement Analysis: sync-hook-dangling-ref (T-020)

Mode: full · Analyst: requirement-analyst · Date: 2026-06-11
Input: `docs/features/sync-hook-dangling-ref/INPUT.md` (verbatim user report + normalized goal)

## 1. Goal

A consumer project generated/maintained by harness-kit must never end any plugin flow with a
`.claude/settings.json` hook whose command references a script that does not exist in the project
(observed symptom: Stop hook fires `bash: .harness/scripts/harness-sync.sh: No such file or directory`
on every turn); already-broken projects get a first-class diagnose + repair path.

## 2. Root-cause analysis (verified, file:line evidence)

The reported state requires two facts simultaneously: (i) `.claude/settings.json` Stop hook command =
`bash .harness/scripts/harness-sync.sh`, (ii) no file at `.harness/scripts/harness-sync.sh`. Each
candidate flow was checked against current sources for whether it can produce both.

### RC-1 — `migrate-scripts-layout` rewires settings without verifying the target landed — CONFIRMED-POSSIBLE (exact symptom match)

- Per-file move is silently skipped when the source is absent: `[[ -f "$src" ]] || continue`
  (`skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh:64`); the move
  itself is unchecked under `set -uo pipefail` — **no `-e`** (`:21`), so a failed `git mv`/`mv` (`:76-81`)
  does not stop the run.
- The settings rewire then runs **unconditionally** on the raw text — `sed 's|scripts/harness-sync\.|...|'`
  (`:94-113`) — with no check that `.harness/scripts/harness-sync.{ps1,sh}` exists. PS twin identical:
  `migrate-scripts-layout.ps1:93-104`.
- Net: a pre-relocation project whose `scripts/harness-sync.sh` is missing (or whose move failed) ends
  with hook = `bash .harness/scripts/harness-sync.sh` and no file — byte-for-byte the reported error.
  The helper ships in every project and is the documented post-v0.20 migration path (CHANGELOG v0.20.0
  / v0.24 notes: "the user applies the path diff (or runs migrate-scripts-layout)").
- Note: T-007's own requirement doc named the stale-path/atomicity hazard
  (`docs/features/_archived/scripts-relocation/01_REQUIREMENT_ANALYSIS.md:37,58`) but the shipped
  helper enforces no move↔rewire congruence.

### RC-2 — `/harness-init` generation is prose-driven with no post-copy congruence invariant — CONFIRMED-POSSIBLE (by construction)

- Init wires the Stop hook **unconditionally**, even when the user answers Q3 = "No, manual only"
  (`skills/harness-init/SKILL.md:374-377`: "The Stop hook ... is also unconditionally written by the
  template"). The scripts are *supposed* to arrive via "Copy everything under `templates/common/`"
  (`SKILL.md:101-103`), which includes `harness-sync.{ps1,sh}` (verified present in
  `templates/common/.harness/scripts/`).
- But the copy is executed by a model following prose, not a deterministic script: a partial copy
  (e.g. a glob copy that misses dot-directories, an aborted run, a permission failure) violates no
  enforced invariant. Failure handling is best-effort reporting (`SKILL.md:467-472`), the skill
  explicitly forbids running verify_all at init time (`SKILL.md:463`), and no step asserts "every hook
  command in the written settings.json resolves to an existing file".
- `{{SYNC_COMMAND}}` is OS-picked at init (`SKILL.md:187`) — a macOS/Linux/WSL init yields exactly the
  bash variant seen in the user's error.

### RC-3 — `/harness-adopt` under-specifies the Stop hook command and has no end-state invariant — CONFIRMED-POSSIBLE (spec gap)

- Adopt's plan does include both `.claude/settings.json` and `.harness/scripts/harness-sync.{ps1,sh}`
  (`skills/harness-adopt/SKILL.md:189,192`), so a faithful apply is congruent.
- However `{{SYNC_COMMAND}}` appears **nowhere** in `harness-adopt/SKILL.md`: the apply-time
  substitution table (`:295-303`) lists only `PROJECT_NAME / PROJECT_TYPE / STACK / TODAY / ENABLE_HOOK`,
  and the settings special-case (`:242-264`) covers only the PreToolUse/guard-rm merge. The Stop hook
  command an adopting AI writes is improvised (wrong-OS variant, or the literal `{{SYNC_COMMAND}}`).
- Same structural weakness as RC-2: the per-file apply loop (`:234-240`) has no terminal
  "hook targets exist" assertion; merge mode never reconciles an existing Stop hook.

### RC-4 — `/harness-upgrade` (`upgrade-project.{ps1,sh}`): a *successful* run self-heals; only failure paths can dangle — CONFIRMED-POSSIBLE (narrow)

- S2 content-refresh copies `harness-sync.{ps1,sh}` from the current template **even when absent in the
  project** (`templates/common/.harness/scripts/upgrade-project.sh:136-159`, counts as `n_added`), and S3
  rewires settings only after S2 (`:161-182`). So a completed run repairs the missing-script state —
  the existing de-facto repair path.
- Residual dangle windows: `set -uo pipefail` without `-e` (`:22`) means a failed S2 `cp` (`:157`) is
  not detected and S3 still rewires; `[[ -f "$tmpl_file" ]] || continue` (`:144`) silently skips a
  script absent from the template while S3 rewires regardless. No post-run congruence assertion exists.

### RC-5 — v0.30.0 agents-cutover removed the sync script or the hook — RULED-OUT (as direct producer)

- Post-cutover, `templates/common/.harness/scripts/harness-sync.{ps1,sh}` still ship (verified by
  listing) and `settings.json.tmpl:37-47` still wires the Stop hook via `{{SYNC_COMMAND}}`
  (CHANGELOG.md:25 confirms only the *agents* copy was retired).
- Hook purpose post-v0.30: a single-developer project has no `.harness/agents/`, but `.harness/skills/`
  (build/test/verify) still syncs — `harness-sync.sh` guards the agents dir with `[[ -d ]]` (`:32`) and
  unconditionally syncs skills (`:74-96`). Therefore the Stop-sync hook **retains a purpose in all
  project shapes**; "remove the hook for single-dev projects" is not a valid fix direction. For a
  partitioned project the agents sync also remains load-bearing.

### RC-6 — Plugin-version skew (cache updates, project `.harness/` stays old) — RULED-OUT as standalone producer; CONFIRMED as amplifier

- A cache update touches nothing inside the project, so skew alone cannot create the dangling
  reference. But skew is the precondition for RC-1/RC-4 (new-plugin helpers run against old layouts),
  and skew already left the **shipped diagnosis surface stale**: all three type `verify_all` templates
  still FAIL-check "All 7 agents in `.harness/agents/`" (generic `verify_all.sh.tmpl:70`, fullstack
  `:166`, backend `:181` — a fresh v0.30 plugin-native project fails its own gate), and
  `/harness-status` still lists "All 7 agents | `.claude/agents/...`" as a required asset
  (`skills/harness-status/SKILL.md:24`). A diagnosis surface that mis-reports healthy v0.30 projects
  cannot be trusted to report this defect class.

### RC-7 — Out-of-band damage (user/AI deletes `.harness/scripts/`, ignore rules, partial clone) — UNVERIFIABLE-EXTERNAL

- Cannot be prevented by generation-flow design; must be covered by the diagnosis + repair surfaces
  regardless of producing flow.

### Sibling instance in the same class (recorded, adjudication → stage 2)

The `UserPromptSubmit`/`SessionStart` ambient hooks are hard-coded to `pwsh`
(`settings.json.tmpl:64,74`) with no OS-pick — on a macOS/Linux machine without pwsh these two wired
hooks fail every turn/session by construction (the template `_ambient_hook` comment `:6` acknowledges
manual swapping). Same class: wired hook whose command cannot run. Diagnosis MUST cover it (FR-D2);
whether the OS-pick fix lands in this task is OQ-3.

## 3. In-scope functional requirements

### Prevention by construction (no flow may end dangling)

- **FR-P1.** At the end of each of the four flows (`/harness-init` apply, `/harness-adopt` apply,
  `/harness-upgrade` apply, `migrate-scripts-layout` run), every `hooks.*[].hooks[].command` in
  `.claude/settings.json` that references a `.harness/scripts/*` (or legacy `scripts/*`) path resolves
  to an existing file — or the flow terminates with an explicit, user-visible error/conflict naming the
  hook event, the command, and the missing path. Silent danglement is never a reachable end state.
- **FR-P2.** `migrate-scripts-layout.{ps1,sh}`: the settings rewire of a given script-path prefix is
  conditioned on (or ordered after, with verification) that script actually being present at
  `.harness/scripts/` — covering both "source never existed" and "move failed" (RC-1). Mechanism is
  SA's choice; the testable contract is FR-P1 applied to this helper.
- **FR-P3.** `upgrade-project.{ps1,sh}`: S3 settings rewire must not complete with a dangling target
  when S2 failed or the template lacked the script (RC-4); a post-run congruence assertion (or
  equivalent ordering guarantee) makes the failure explicit (non-zero exit + CONFLICT/GAP record).
- **FR-P4.** `/harness-init` and `/harness-adopt` SKILL procedures gain a mandatory terminal
  congruence step: before the flow reports success, assert FR-P1's invariant and report any violation
  as a flow failure (not a note). For adopt, the Stop-hook command specification gap is closed:
  `{{SYNC_COMMAND}}` substitution (OS-picked, same rule as init `SKILL.md:187`) is explicitly specified.
- **FR-P5.** The Stop-sync hook stays wired for all project shapes (single-developer included) — its
  post-v0.30 purpose is `.harness/skills/` (plus partition `dev-*` agents where present), per RC-5
  evidence. No requirement to conditionalize the hook on partitioning.

### Diagnosis surface

- **FR-D1.** `/harness-status` reports, for the Stop/sync hook, a congruence state computed the same
  way it already does for guard-rm (`skills/harness-status/SKILL.md:61-77`): `enabled` /
  `not wired` / `scripts missing` (wiring present, target file absent) — naming the exact command and
  missing path, with the concrete fix command.
- **FR-D2.** The same congruence check covers **every** hook entry in `.claude/settings.json`
  (Stop, PreToolUse, UserPromptSubmit, SessionStart): any command referencing a project-relative script
  that does not exist is reported. (Interpreter availability — e.g. `pwsh` absent on the OS — is
  reported at minimum for the ambient hooks per the sibling-instance note; depth is OQ-3.)
- **FR-D3.** The diagnosis surfaces consulted for this class are v0.30-accurate: the stale
  "All 7 agents" assertions in `/harness-status` (`SKILL.md:24`) and in the three shipped type
  `verify_all` templates (E.3/D.3 rows cited in RC-6) must not mis-report a healthy plugin-native
  project while this task's checks are added. (Bounding of how much template refresh lands here vs. a
  follow-up task is OQ-4; the minimum is: the rows this task touches/ships are accurate.)
- **FR-D4.** The consumer project's own `verify_all` detects the dangling-hook state as a FAIL with an
  actionable fix line. (Today E.4 FAILs on a missing canonical `harness-sync` file — generic
  `verify_all.sh.tmpl:72-76`, `verify_all.ps1.tmpl:113-115` — but nothing checks that the *wired hook
  command* is congruent; a hook pointing at the legacy `scripts/` path passes E.4 while erroring every
  turn.)

### Repair surface

- **FR-R1.** `/harness-upgrade` is the documented repair path for an already-broken project: running it
  on a project in the dangling state ends with the wired hook command resolving to an existing,
  current-template script (S2 already provides the re-landing mechanics, `upgrade-project.sh:136-159`),
  and the run's report states what was repaired.
- **FR-R2.** Repair is idempotent: a second run on the repaired project is a clean no-op.
- **FR-R3.** Repair preserves the existing `.claude/settings.json` editing contract: raw-text surgical
  edit, never re-serialized, `_*` doc keys and key order preserved, timestamped `.bak` on change
  (per `upgrade-project` hard rules and rule 80).
- **FR-R4.** Repair handles the cross-OS variant case at minimum by diagnosis (FR-D2 flags a hook whose
  interpreter/variant cannot run on the current OS); whether repair re-picks the OS variant is OQ-5.
- **FR-R5.** A project with no `.harness/` at all is routed to `/harness-adopt` (existing
  `upgrade-project.sh:74-77` precondition stands); repair does not fabricate a harness setup.

## 4. Out of scope

- A general overhaul of template staleness beyond what FR-D3 requires (the full v0.30 template-docs
  refresh is its own follow-up; only diagnosis-accuracy rows are pulled in here, per OQ-4 bounding).
- Redesigning the sync mechanism itself (plugin-hosted hooks, removing harness-sync, redesign Legs 2/3).
- Removing or conditionalizing the Stop-sync hook for single-developer projects (ruled out by RC-5).
- Non-Claude tools (Copilot/Cursor) — no Stop-hook equivalent exists there.
- Downgrade paths, network calls, package installs, CI edits.
- Auto-repair triggered silently at hook-fire time (masks breakage; conflicts with design-over-guards
  and with the explicit-confirmation contract of `/harness-upgrade`).
- The v0.1.x → v0.2.0 `CLAUDE.md` migration (already out of scope for `/harness-upgrade` v1).

## 5. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| B1 | `.claude/settings.json` absent | diagnosis: "not wired"; migrate: existing exit-1 stands (`migrate-scripts-layout.sh:39-43`); upgrade: existing SKIP record stands (`upgrade-project.sh:163-164`) |
| B2 | settings present, `hooks` key absent / no Stop entry | diagnosis: "not wired", not a crash; repair does not invent a hook without the flow's normal confirmation |
| B3 | Hook points at legacy `scripts/harness-sync.*` and the file exists there | diagnosis: stale-path state (works today only if file kept); repair = relocate + rewire congruently |
| B4 | Hook points at `.harness/scripts/harness-sync.sh`, only the `.ps1` exists (or vice versa) | diagnosis: per-variant congruence (the wired variant is what matters); repair lands both shells (template pair) |
| B5 | `.harness/` exists, `.harness/scripts/` empty | repair re-lands scripts from template (RC-4 S2 semantics); prevention asserts before success |
| B6 | `.harness/` absent entirely | route to `/harness-adopt` (FR-R5) |
| B7 | Hook command is the unsubstituted literal `{{SYNC_COMMAND}}` (RC-3 improvisation failure) | diagnosis flags as dangling/malformed; repair rewires to the OS-picked command |
| B8 | settings.json with CRLF line endings / read-only file / `cp`-mv failure mid-flow | rewire still byte-safe (no re-serialize); failures surface explicitly, never silent (FR-P1/P3) |
| B9 | Dry-run modes | dry-run never modifies; plan output includes the congruence findings |
| B10 | Second run of any repair/migration on a healthy project | true no-op (no `.bak`, no write) — existing fixed-point property preserved |
| B11 | Single-developer v0.30 project (no `.harness/agents/`) | Stop hook runs green (skills-only sync, `harness-sync.sh:32` guard); diagnosis reports healthy |
| B12 | Non-git project | migrate/upgrade behavior per existing contracts (mv fallback / precondition halt) — congruence invariant still holds |

## 6. Non-functional requirements

- **NFR-1 Cross-shell parity.** Every touched `.ps1`/`.sh` pair stays behavior- and (where files are
  generated) byte-parity equivalent; the known parity trap families apply (insight-index 2026-06-08
  entries: trailing-newline writes, `-cmatch`/case-sensitivity, `arr=()` under `set -u`).
- **NFR-2 settings.json schema integrity (rule 80).** Any settings edit keeps the file valid against
  the upstream schema; `verify_all` J.1 must stay green; consult the upstream schema before editing —
  never from memory.
- **NFR-3 Template ↔ dogfood self-consistency (rule 10).** `migrate-scripts-layout` and
  `upgrade-project` are in the `sync-self` mirror set — every edit lands in both
  `templates/common/.harness/scripts/` and this repo's `.harness/scripts/`, byte-identical.
- **NFR-4 Gate stays green.** `.harness/scripts/verify_all` 32/32 PASS both shells before done. If a
  new dogfood check is added, the G.4 count/version discipline applies (insight 2026-06-05).
- **NFR-5 Regression coverage.** `test-init` / `test-real-project` (and any helper-specific driver)
  cover the new invariants; reported tallies are pasted from captured runs (insight 2026-06-04).
- **NFR-6 Dogfood red line.** This repo's own `.claude/settings.json` is propose-only (CLAUDE.md red
  line); any dogfood wiring change is proposed for the user to apply.

## 7. Related tasks (links, not re-description)

- **T-007 scripts-relocation** — created `migrate-scripts-layout` + the relocation that makes RC-1
  possible; its own RA named the stale-path hazard (`docs/features/_archived/scripts-relocation/`).
- **T-012 harness-upgrade-skill** — `upgrade-project` helper, the de-facto repair mechanics + the
  settings raw-text-edit contract (`docs/features/_archived/harness-upgrade-skill/`).
- **T-019 agents-cutover** — v0.30 plugin-native context; source of the RC-6 diagnosis-surface skew
  (`docs/features/_archived/agents-cutover/`).
- **T-011 ambient-stream** — shipped the pwsh-hardcoded ambient hooks (sibling instance)
  (`docs/features/_archived/ambient-stream/`).
- **T-001 ai-safety-guardrails** — `/harness-status` §3b guard-rm congruence reporting, the exact
  pattern FR-D1 extends (`docs/features/_archived/ai-safety-guardrails/`).

## 8. Assumptions (Mode 2 — decided, not blocked; user may override)

- **A1.** The user's failing project's exact provenance is unrecoverable from here; requirements are
  written flow-agnostic so diagnosis/repair cover every enumerated producing state (RC-1..RC-4, RC-7).
  The bash-variant detail is consistent with a macOS/Linux/WSL-initialized project or an improvised
  adopt-time command (RC-3).
- **A2.** The Stop-sync hook is kept for all project shapes (evidence in RC-5); fixing congruence, not
  removing the hook, is the requirement.
- **A3.** Repair runs under explicit user confirmation (consistent with `/harness-upgrade` gating);
  no silent auto-fix at hook-fire time.
- **A4.** Diagnosis covers all four hook events (cheap, same mechanism); prevention work is scoped to
  the four flows + the sync/guard commands. Ambient-hook OS-pick is recorded but adjudicated by SA (OQ-3).
- **A5.** Per the orchestrator prior and `design-over-guards`, the requirement is stated as surfaces to
  extend (`/harness-status`, `/harness-upgrade`, generation atomicity) — a new command is only
  justified if SA shows these surfaces cannot host FR-D*/FR-R* (OQ-1).

## 9. Open questions for stage 2 (Solution Architect adjudicates; none block design start)

1. **`/harness-doctor` vs extend existing surfaces.** Evidence gathered favors extension: `/harness-status`
   §3b already implements the exact congruence-state pattern for guard-rm; `upgrade-project` S2 already
   re-lands missing scripts (repair semantics exist); a new command would duplicate both and grow the
   skill count without new capability. Candidates: (a) extend status+upgrade (+atomic generation) —
   orchestrator prior; (b) add `/harness-doctor` as a thin alias over the same mechanics; (c) full new
   check+repair command. SA decides with evidence; default (a).
2. **Prevention mechanism per flow**: (a) verify-target-then-rewire ordering inside the helpers;
   (b) terminal post-flow congruence assertion; (c) both. Default: per-helper ordering for the
   deterministic helpers (RC-1/RC-4) + terminal assertion for the prose-driven flows (RC-2/RC-3).
3. **Ambient hooks OS-pick** (`settings.json.tmpl:64,74` hard-coded pwsh): fix in this task (same class,
   two-line template change + placeholder) or defer to its own task? Default: include in diagnosis
   (FR-D2) unconditionally; template OS-pick inclusion is SA's call against scope guard.
4. **Bounding FR-D3**: fix the stale E.3/D.3 "All 7 agents" rows in the three shipped type `verify_all`
   templates and the `/harness-status` asset rows here, or split to a follow-up? Default: fix the rows
   that make the diagnosis surfaces lie about v0.30 projects (status rows + the three E.3/D.3 rows);
   anything wider is a follow-up task.
5. **Cross-OS repair**: should repair re-pick `{{SYNC_COMMAND}}`'s OS variant when the wired variant's
   interpreter is unavailable (project moved between OSes), or only diagnose? Default: diagnose +
   print the swap instruction; no silent rewrite of a user-edited command.
6. **Consumer-side congruence check placement** (FR-D4): extend the shipped type `verify_all` E.4/D.4
   row vs. a new row — interacts with the per-type template count and B-CUSTOM splice logic. SA decides.

## 10. Acceptance criteria (mechanically verifiable by QA, stage 6)

- **AC-1 (RC-1 fixture).** Fixture: pre-relocation project, settings hook = `bash scripts/harness-sync.sh`,
  NO `scripts/harness-sync.sh` on disk. Run `migrate-scripts-layout.{ps1,sh}`. Assert end state: either
  settings does NOT reference a nonexistent `.harness/scripts/harness-sync.sh`, or the script exists at
  the referenced path — and the run printed an explicit warning/conflict naming the path. Both shells.
- **AC-2 (RC-4 fixture).** Fixture: project with settings present and `.harness/scripts/` missing
  `harness-sync.*`. Run `upgrade-project` (apply). Assert: wired Stop-hook command's target file exists
  and `bash`/`pwsh` invocation of the wired command from the project root exits 0. Re-run → no-op
  (no new `.bak`, no write). Both shells.
- **AC-3 (diagnosis).** Fixture: hook wired to `.harness/scripts/harness-sync.sh`, file absent. The
  `/harness-status` procedure (per its updated SKILL text) yields a report containing the dangling state,
  the exact command string, and the missing path; on a healthy v0.30 single-developer fixture (no
  `.harness/agents/`) the same report shows the sync hook healthy and does NOT flag missing framework
  agents (FR-D3).
- **AC-4 (consumer verify_all).** On the dangling fixture, the regenerated type `verify_all` reports a
  FAIL row naming the hook→script incongruence with a fix command; on the healthy v0.30 fixture it
  reports 0 FAIL for the agents/E.3-class rows this task touches. Verified on at least one type template
  in both shells.
- **AC-5 (init/adopt invariant).** `test-init` (and the adopt path via `test-real-project` or a targeted
  probe) asserts post-flow: every `.harness/scripts/*` path referenced by any `hooks.*` command in the
  generated `.claude/settings.json` exists on disk, and the settings file contains no `{{...}}` literal.
  Mutation probe: delete `harness-sync.sh` from the generated tree mid-flow (or simulate a skipped copy)
  → the flow's terminal congruence step reports failure (non-success), not silence.
- **AC-6 (settings integrity).** After every rewire performed in AC-1/AC-2: file JSON-parses, `$schema`
  is the canonical URL, all `hooks` keys are valid event names (J.1-class assertions), `_*` doc keys and
  key order preserved, `.bak` written exactly when content changed.
- **AC-7 (parity + mirrors).** Each touched `.ps1`/`.sh` pair produces byte-identical generated output on
  the same fixture (cmp across shells); `sync-self --check` (or byte-compare) confirms template ↔ dogfood
  mirror identity for `migrate-scripts-layout` and `upgrade-project`.
- **AC-8 (gate).** Dogfood `.harness/scripts/verify_all` 32/32 PASS both shells (or N/N with the G.4
  version/count discipline satisfied if the count changes); `test-init`, `test-real-project` green with
  captured tallies pasted into the stage docs.

## 11. Verdict

**READY** (READY-FOR-DESIGN). No user-blocking ambiguity under Mode 2: all open questions are stage-2
design adjudications with recorded defaults; assumptions A1–A5 are explicit and overridable. No red
lines triggered (dogfood `.claude/settings.json` changes remain propose-only per NFR-6).
