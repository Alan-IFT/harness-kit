# 01 — Requirement Analysis · scripts-relocation (T-007)

> Mode: **full** (7-stage, Gate-gated). Stage 1 of 7. Read-only inputs: `INPUT.md`, user request.
> This document defines *what* and *acceptance*; it does NOT design the *how* (stage 2 = Solution Architect).

## 1. Goal

Move every harness-kit-owned operational script out of the `scripts/` root — in both this dogfood repo and the distributed templates — into a dedicated `.harness/scripts/` namespace, so harness scripts no longer share a directory with a user project's own scripts.

## 2. In-scope behaviors

All numbered items are directory-relocation + the path-constant edits that relocation forces. No renames, no logic changes.

1. **R1 — Dogfood script files relocate.** Every file currently under this repo's `scripts/` moves to `.harness/scripts/`, keeping its filename. Confirmed inventory (24 entries) from `scripts/`: `verify_all.{ps1,sh}`, `harness-sync.{ps1,sh}`, `sync-self.{ps1,sh}`, `install-hooks.{ps1,sh}`, `archive-task.{ps1,sh}`, `guard-rm.{ps1,sh}`, `test-init.{ps1,sh}`, `test-real-project.{ps1,sh}`, `test-supervisor.{ps1,sh}`, `test-verify-i6.{ps1,sh}`, `test-guard-rm.{ps1,sh}`, plus data files `baseline.json`, `verification_history.log`. (`ai-native-mock.json` lives only under `templates/common/scripts/`, not repo `scripts/`.) The exact disposition of the two data files is open question Q6.
2. **R2 — Template script files relocate.** Under `skills/harness-init/templates/`, scripts move from `<overlay>/scripts/` to `<overlay>/.harness/scripts/`: `common/scripts/` (`harness-sync`, `install-hooks`, `archive-task`, `guard-rm` pairs + `ai-native-mock.json`) and the three stack overlays' `{backend,fullstack,generic}/scripts/verify_all.{ps1,sh}.tmpl`.
3. **R3 — Canonical entry path changes everywhere live.** The invocation string `scripts/verify_all` (and every other `scripts/<name>` for a relocated script) is rewritten to `.harness/scripts/<name>` in all **live** tracked files: `AI-GUIDE.md`, `CLAUDE.md`, `.harness/rules/*.md`, `.harness/agents/*.md`, `skills/**/SKILL.md`, `docs/*.md`, `evals/*.md`, `CONTRIBUTING.md`, `MIGRATION.md`, `README.md`, `README.zh-CN.md`, `.github/copilot-instructions.md`, and the live HTML docs — subject to the live-vs-archived boundary (Q3) and the dev-facing-entry policy (Q5).
4. **R4 — Hook wiring retargets (dogfood + template).** `.claude/settings.json` Stop-hook (`harness-sync.ps1`) and PreToolUse-hook (`guard-rm.ps1`) command strings retarget to `.harness/scripts/`. The init skill's `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` substitution recipes (`skills/harness-init/SKILL.md:149-150`) retarget to `.harness/scripts/`. The template `settings.json.tmpl` retains `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` placeholders unchanged (path is baked into the substitution recipe, not the template).
5. **R5 — `verify_all` self-checks retarget.** Internal path constants that assert script presence/sync retarget from `scripts/` to `.harness/scripts/`: F.1 script-pair existence (`verify_all.ps1:269-274`), F.2 guard-rm presence + template paths (`:276-296`), J.1 settings paths list (`:587-588`), the I.6 exempt-FILE list (`:515-523`, which lists `scripts/verify_all.{ps1,sh}` and `scripts/test-verify-i6.{ps1,sh}` — must become `.harness/scripts/...` per insight L26), the secrets/grep path-exclude globs (`:45`), and `verification_history.log` append path (`:636`). The `.sh` peer carries identical edits.
6. **R6 — `sync-self` mapping retargets.** The 8 script `from`/`to` mappings in `sync-self.{ps1,sh}` (`sync-self.ps1:38-48`) retarget both sides to `.harness/scripts/`, and `install-hooks.{ps1,sh}` self-references and `harness-sync` invocations retarget.
7. **R7 — User-project verify_all template self-checks retarget.** The stack `verify_all.*.tmpl` files reference `scripts/harness-sync` for binding-drift checks (e.g. `generic/.../verify_all.ps1.tmpl:111-113`); these retarget so a freshly-initialized user project's gate finds its scripts under `.harness/scripts/`.
8. **R8 — Post-move gate is green.** `.harness/scripts/verify_all` runs and every check PASSes (count is whatever the release ships; ≥31 at v0.18.2), proving no stale path remains in any self-check.
9. **R9 — Backward-compatibility for already-initialized user projects is delivered** per the policy the user selects in Q2 (migration helper, compat shim, or doc-only). The *mechanism* is SA's design; the *policy intent* is fixed here once Q2 is answered.

## 3. Out-of-scope

- Renaming any script (filenames are preserved; only the parent directory changes).
- Changing script behavior/logic beyond the path constants that the move forces.
- Rewriting `scripts/<name>` references inside `docs/features/_archived/**` and `CHANGELOG.md` (they record historical truth) — subject to Q3 confirmation.
- Changing the placeholder set or `settings.json` schema shape (only the substituted command path changes).
- Introducing a new `verify_all` check, or refactoring existing checks beyond the path-constant retarget.
- Adding stack overlays or new scripts.

## 4. Boundary conditions

- **Empty / absent user `scripts/`.** After init, a fresh user project's `scripts/` root contains zero harness files. Whether the directory is *absent* vs *present-but-empty* is open question Q1.
- **Collision with a user file at `.harness/scripts/<name>`.** `.harness/` is harness-owned territory; init already owns `.harness/`. No new collision class is introduced. (Confirm: no template currently writes a user-authored file into `.harness/scripts/`.)
- **Hook fires with a stale path.** If any `.claude/settings.json` command still points at `scripts/`, the Stop-sync or PreToolUse guard silently no-ops (the guard fails *open* — destructive commands would pass). AC-2 must prove both hooks fire post-move.
- **Mixed live/archived references in one sweep.** A blanket find/replace of `scripts/` would corrupt archived stage docs and CHANGELOG. The live-vs-archived split is measured: ~507 references across 101 live files vs ~519 across 44 `_archived/` files. Q3 fixes the boundary.
- **PS/Bash symmetry.** Every path edit in a `.ps1` self-check has an identical edit in its `.sh` peer (insight L13 class: bash-only bugs hide when the PS verify_all runs). F.1 enforces pair existence.
- **Placeholder whitelist.** No new `{{...}}` placeholder is introduced (insight L11) — the path lives in the substitution *recipe* in `SKILL.md`, not in a `.tmpl`. If SA proposes a new placeholder, L11 (whitelist in BOTH verify_all shells) applies.
- **`-NoProfile` preservation.** Retargeted pwsh hook commands keep `-NoProfile` (insight L17) — only the path segment changes.
- **`$schema` / hooks keys untouched.** Only the `command` string's path changes; `$schema` URL and `hooks` key names stay byte-identical (insight L30 / J.1).

## 5. Acceptance criteria (refines INPUT AC-1..AC-4)

Each is verifiable by a tester via a command or an observable file state.

- **AC-1 (fresh init places scripts correctly).** After `/harness-init` on an empty dir, `.harness/scripts/` contains the expected harness scripts (verify_all pair, harness-sync pair, guard-rm pair, install-hooks pair, archive-task pair, baseline.json) and the project's `scripts/` root contains **no** harness-owned file. *Verify:* run `test-init` (regression) and inspect the generated tree; assert `.harness/scripts/verify_all.ps1` exists and `scripts/verify_all.ps1` does not. The exact end-state of an empty `scripts/` dir is gated on Q1.
- **AC-2 (hooks resolve to new paths).** In both the dogfood `.claude/settings.json` and a freshly-initialized project's `.claude/settings.json`, the Stop-hook command resolves to `.harness/scripts/harness-sync.*` and the PreToolUse command to `.harness/scripts/guard-rm.*`; both fire. *Verify:* (a) `verify_all` F.2 PASSes (it parses settings.json and matches the guard-rm command); (b) a destructive Bash call targeting a path outside the repo is blocked by the guard (per `evals/guard-rm-cases.md`); (c) a `.harness/` edit followed by session-end Stop triggers a sync.
- **AC-3 (gate is green at the new path).** `.harness/scripts/verify_all` (PS and, where the environment supports it, SH) runs and reports every check PASS. *Verify:* run `.harness/scripts/verify_all.ps1`; exit 0, all checks PASS; the I.6 retired-claim guard does not fire on the relocated self-check files (exempt-FILE list updated per L26); J.1 still PASSes.
- **AC-4 (no stale live reference remains).** A repository scan for the literal `scripts/<relocated-name>` across **live** tracked files (excluding `_archived/**`, `CHANGELOG.md`, and any file Q3 designates historical) returns zero hits for relocated scripts. *Verify:* `git grep` for each relocated script name under `scripts/` returns matches only in exempt/historical files. (The exact exempt set is fixed by Q3/Q5.)
- **AC-5 (already-initialized projects are addressed).** The backward-compat policy selected in Q2 is delivered and self-consistent: if a migration helper, it runs and is regression-covered; if a compat shim, it is documented and removable; if doc-only, `MIGRATION.md` carries an explicit, ordered manual procedure. SA designs the mechanism; Gate Reviewer vets it against the Q2 intent.
- **AC-6 (template ↔ dogfood self-consistency holds).** `sync-self --check` reports in-sync (the 8 relocated script pairs match between `templates/common/.harness/scripts/` and the repo's `.harness/scripts/`), and `verify_all` Layer-1 + Layer-2 checks PASS. *Verify:* `sync-self.ps1 -Check` exits 0; verify_all E.1/binding checks green.

## 6. Non-functional requirements (material only)

- **NFR-Perf (hook latency preserved).** Retargeted pwsh hook commands keep `-NoProfile`; no measurable per-call regression vs current p50 (insight L17). *Material:* a dropped `-NoProfile` reintroduces a 3-4s-per-call profile load.
- **NFR-Safety (guard fails closed during transition).** No window exists where the PreToolUse guard silently no-ops because the command points at a removed `scripts/` path. The dogfood `.claude/settings.json` and template substitution retarget atomically with the move.
- **NFR-Compat (cross-shell symmetry).** Every self-check path edit exists in both `.ps1` and `.sh` (insight L13). *Material:* PS-only verify_all hides bash path bugs until a Unix user hits them.

## 7. Related tasks

- **T-001 ai-safety-guardrails** (`docs/features/_archived/ai-safety-guardrails/`) — introduced `guard-rm` + the PreToolUse hook wiring and the `-NoProfile` requirement (insight L17). This task retargets that wiring.
- **T-004 i6-semantic-guard** (`docs/features/_archived/i6-semantic-guard/`) — built the I.6 retired-claim guard and its exempt-FILE list; insight L26 requires the relocated `verify_all`/`test-verify-i6` paths to stay on that list.
- **T-002 ai-native-init** (`docs/features/_archived/ai-native-init/`) — established the `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` substitution and `ai-native-mock.json`; the substitution recipes are retargeted here.
- **T-006 harness-batch-skill** (`docs/features/_archived/harness-batch-skill/`) — most recent doc-resync precedent for AI-GUIDE/README/manual-e2e-test count + entry drift (insight L14 fan-out checklist applies to R3).

## 8. Open questions for user

1. **Empty user `scripts/` — absent or just unwritten?** After init, must the user-project `scripts/` directory be (a) entirely **absent** (harness creates no `scripts/` at all), or (b) **present but empty / untouched** (harness simply stops writing into it)? (INPUT AC-1 says "ideally harness no longer requires a `scripts/` dir at all" — this needs a binding choice, because some stack overlays historically delivered `verify_all.*.tmpl` under `scripts/`.)
2. **Backward-compat policy for already-initialized projects.** Choose the *intent* (SA designs the mechanism): (a) ship a one-shot **migration helper** the user runs to move their existing `scripts/<harness-names>` → `.harness/scripts/` and rewire hooks; (b) ship a **compat shim** (a thin `scripts/verify_all` that forwards to `.harness/scripts/verify_all`) so old invocations keep working; (c) **doc-only** — `MIGRATION.md` carries a manual, ordered procedure and no code helper.
3. **Live-vs-archived rewrite boundary.** Confirm the references NOT rewritten: (a) leave both `docs/features/_archived/**` **and** `CHANGELOG.md` untouched (both record past truth) — recommended-equivalent default; (b) also leave the labeled-snapshot HTMLs (`architecture.html`, `docs/walkthrough.html`, `docs/v0.11-changes.html`, `docs/project-overview.html`, `docs/system-overview.html`) untouched as dated snapshots; (c) rewrite everything except `_archived/**`. (Measured: ~507 live refs / 101 files vs ~519 archived refs / 44 files.)
4. **Inventory completeness — does anything legitimately STAY at `scripts/`?** Confirm: (a) **nothing** stays — all 24 repo `scripts/` entries are harness-owned and move (including `test-guard-rm.{ps1,sh}`, `test-supervisor.{ps1,sh}`, and the data files); or (b) a named subset stays (specify which). The PM blast-radius and this RA's `Glob` agree the directory is 100% harness-owned, so (a) is the expected answer.
5. **Dev-facing entry transition.** Every contributor-facing doc (CLAUDE.md, AI-GUIDE.md §"Run `scripts/verify_all`", README, `docs/getting-started.md`) currently says "run `scripts/verify_all`". Update them in lockstep to `.harness/scripts/verify_all` — and is a **transition alias / note** acceptable: (a) update all docs to the new path and add a one-line "old `scripts/verify_all` is gone, use `.harness/scripts/verify_all`" note in `MIGRATION.md` only; (b) update docs AND keep a forwarding shim per Q2(b); (c) update docs, no note, no shim (clean break).
6. **Disposition of `scripts/baseline.json` and `scripts/verification_history.log`.** These are data, not executables. (a) Move both to `.harness/scripts/` alongside the scripts (verify_all's append path retargets); (b) move `baseline.json` but treat `verification_history.log` as a generated/gitignored artifact that simply regenerates at the new path; (c) leave data files at `scripts/`. Note `verification_history.log` and `baseline.json` are currently referenced by `verify_all.ps1:636` and the init skill (`SKILL.md:350,359`).

## 9. Verdict

**RESOLVED — ready for design.** All 6 open questions were answered by the user (via PM AskUserQuestion, 2026-06-04). The pre-decided constraints (target `.harness/scripts/`, dual scope, full pipeline) plus the resolutions in §10 form a complete, unambiguous brief for the Solution Architect.

## 10. Resolution (user-answered 2026-06-04 — clerical record by PM, selections are the user's)

- **Q1 → (a) absent.** A fresh `/harness-init` creates **no** `scripts/` directory at all; harness writes only into `.harness/scripts/`. AC-1 hardens to: assert `scripts/` is absent (or, if a stack legitimately needs a user `scripts/`, it contains zero harness files — but no current overlay does).
- **Q2 → (a) one-shot migration helper.** Ship a `migrate-scripts-layout.{ps1,sh}` helper that an already-initialized user runs once: it moves `scripts/<harness-names>` → `.harness/scripts/` and rewires the two hook command strings in `.claude/settings.json`. Fresh inits are clean (no shim). The helper must be regression-covered (AC-5). It is idempotent and safe to run on an already-migrated project (no-op).
- **Q3 → (a) leave historical untouched.** Do NOT rewrite `scripts/<name>` references inside `docs/features/_archived/**`, `CHANGELOG.md`, or the dated-snapshot HTMLs (`architecture.html`, `docs/walkthrough.html`, `docs/v0.11-changes.html`, `docs/project-overview.html`, `docs/system-overview.html`). These record historical truth and are consistent with the I.6 exempt philosophy. AC-4's live-scan exempt set = these files.
- **Q4 → (a) nothing stays.** All 24 repo `scripts/` entries are harness-owned and move (including `test-guard-rm`, `test-supervisor`, and the data files per Q6).
- **Q5 → (a) update docs + MIGRATION note.** Update every contributor-facing doc (CLAUDE.md, AI-GUIDE.md, README, README.zh-CN, `docs/getting-started.md`, etc.) to `.harness/scripts/verify_all` in lockstep, and add a one-line "old `scripts/verify_all` is gone; run `.harness/scripts/verify_all`, or run `migrate-scripts-layout` to upgrade an existing project" note in `MIGRATION.md`. No forwarding shim.
- **Q6 → (a) data files move.** `baseline.json` moves to `.harness/scripts/`; `verification_history.log` is a generated artifact that regenerates at `.harness/scripts/` (its append path retargets); confirm `.gitignore`/init handling follows it.

> **CLAUDE.md red-line note for SA/Dev:** `.claude/settings.json` is the live startup config — the Developer must **propose** the hook-path change for the user to apply, not silently hand-edit it. The *template* `settings.json.tmpl` and the `SKILL.md` substitution recipe ARE in-scope for direct edit.
