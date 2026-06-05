# 05 — Code Review · scripts-relocation (T-007)

> Stage 5 of 7. Independent review of `04_DEVELOPMENT.md` against `02_SOLUTION_DESIGN.md` + gate conditions C-1..C-3.
> Persisted verbatim by PM: code-reviewer is read-only (`tools: Read, Glob, Grep`) and returned its review as its final message.

## Files reviewed
All relocated `.harness/scripts/*.{ps1,sh}` (sync-self, harness-sync, install-hooks, archive-task, guard-rm, verify_all, test-init, test-supervisor, test-verify-i6, test-real-project, test-guard-rm, migrate-scripts-layout), `MIGRATION.md`, `.claude/settings.json`, all `skills/harness-init/templates/**` scripts/tmpl/prose, all live docs/rules/agents/skills/evals.

## Findings

### BLOCKER

**B-1 [LOGIC/TEST] `test-init.ps1:556-557` + `test-init.sh:485-486` — migrate-regression assertions are self-contradictory; AC-5/C-2 is not actually validated and cannot be all-PASS as reported.**
The migrate fixture asserts a file is **present** at `.harness/scripts/` and, two lines later, asserts the **same path** is **gone**:
- `test-init.ps1:554` `Assert "[migrate] .harness/scripts/harness-sync.ps1 present" { Test-Path …".harness/scripts/harness-sync.ps1" }` vs `:556` `… "gone" { -not (Test-Path …".harness/scripts/harness-sync.ps1") }` — identical path, opposite expectation. `:557` asserts `.harness/scripts/guard-rm.sh` gone while it is present after migration.
- `test-init.sh:483` present vs `:485` gone on `.harness/scripts/harness-sync.sh`; `:486` gone on `.harness/scripts/guard-rm.ps1` (present after migration).

After a **correct** migration the destination files ARE present, so the "gone" assertions evaluate false and FAIL. This is irreconcilable with the dev's reported "test-init PS 250/250, SH 212/212 PASS" — exactly one of each present/gone pair must fail. Intended end-state was that the **OLD source path** `scripts/<name>` is vacated; the assertion was written against `.harness/scripts/<name>` (the destination) instead.
Why BLOCKER: (a) the dev's AC-5 verification evidence is internally inconsistent; (b) C-2 (assert migrate end-state) is not actually enforced; (c) `verify_all` does NOT run `test-init` (only F.1:271-273 pair-exists), so green 31/31 verify_all does not cover this. Fix: change `:556/:557` (PS) and `:485/:486` (SH) to assert the OLD path is gone, e.g. `-not (Test-Path …"scripts/harness-sync.ps1")` / `[[ ! -f "$tmp/scripts/harness-sync.sh" ]]`, and **re-run both shells to confirm a genuine all-PASS** (reconcile the reported counts).

### MAJOR

**M-1 [LOGIC] `test-supervisor.sh:153` — stale OLD-path reference; the RISK-D/L13 bash-asymmetry trap left in the bash twin.**
`if bash "$repo_root/scripts/sync-self.sh" --check …` still points at the deleted `scripts/` location. The PS twin `test-supervisor.ps1:153` was correctly handled via `$PSScriptRoot`. At runtime under bash the path does not exist → `bash` fails → `&>/dev/null` swallows it → `else` branch → `AC-2.3 sync-self --check is clean` asserts 0 (FAIL). This is the only stale live `scripts/<harness>` reference remaining in any tracked non-exempt file (exhaustive grep). Fix: `bash "$repo_root/.harness/scripts/sync-self.sh" --check`.

### MINOR

**m-1 [TEST] `test-init.ps1:526` + `test-init.sh:459` — baseline.json synthesized at the NEW path, contradicting its own comment; helper's baseline.json move is never exercised.**
Both write `'{"test_count":0}'` to `.harness/scripts/baseline.json`, but the comment says "synthesize at the OLD path so the move is exercised." The downgrade loops (`test-init.ps1:519-520`, `test-init.sh:456`) don't include `baseline.json`, so it's never under `scripts/`; the helper's baseline.json move (`migrate-scripts-layout.ps1:42-48`) is never tested and `[migrate] baseline.json present` (PS:555 / SH:484) passes trivially. Fix: synthesize baseline.json under `scripts/` and add it to the downgrade set.

### NIT

**n-1 [STYLE] `migrate-scripts-layout.sh:110` — `printf '%s\n'` adds a trailing newline; PS twin (`WriteAllText`) does not.** 1-byte cross-shell artifact asymmetry, both valid JSON, idempotency preserved (`:100` comparison strips trailing newlines). Not blocking.

**n-2 [INFO] `.harness/rules/40-locations.md:25` — "30 items at v0.18.0" is a stale count, but PRE-EXISTING (not T-007 drift).** Path was correctly retargeted; count drift predates this task. Note for the PM version-bump pass.

## Requirement coverage
- AC-1 ✅ (scripts/ absent assertion present) · AC-2 ✅ (F.2 retargeted; settings propose-only) · AC-3 ✅ (verify_all symmetric) · **AC-4 ❌ M-1** (stale test-supervisor.sh ref) · **AC-5 ❌ B-1** (contradictory assertions; m-1 gap) · AC-6 ✅ (Layer-1 byte-identity, 10 mappings both endpoints).

## Design fidelity (verified correct)
Root-derivation two-up in every moved script (DRIFT #1) ✅; guard-rm left location-independent ✅; verify_all PS/Bash symmetry ✅ (except test-supervisor M-1); I.6 exempt list = new paths (L26) ✅; migrate helper surgical substring replace / `.bak` / idempotent fixed-point / `-DryRun` / all-4-sites / leaves user custom scripts ✅ both shells; `.claude/settings.json` NOT edited, propose-diff correct ✅; MIGRATION.md append-not-rewrite ✅; Q3 exempt files untouched ✅; R7 6-tmpl scope ✅; sync-self migrate mapping ✅.

## Open-issue assessment (dev-raised)
- Version bump / CHANGELOG deferred to PM — correct (G.3 lockstep; partial bump would break it). PM-scope, not a defect.
- Settings handshake (propose-only diff) — correct, accurate, minimal. PM/user-scope, not a defect.

## Verdict
**CODE REVIEW VERDICT: CHANGES REQUIRED (1 BLOCKER, 1 MAJOR)** — the migrate regression has self-contradictory present/gone assertions so AC-5/C-2 isn't validated and can't be all-PASS as reported (B-1), and `test-supervisor.sh:153` still invokes the deleted `scripts/sync-self.sh` (M-1, RISK-D/L13 trap). Both route back to the Developer; root-derivation, live sweep, I.6 list, migrate-helper logic, propose-only settings, and exempt-file preservation are otherwise correct.

---

## Re-review (rollback #1) — VERDICT: APPROVED

Focused verification of the Developer's Rework round 1, by reading the actual current files (read-only; cannot run tests).

- **B-1 (BLOCKER) — FIXED.** "gone"/"vacated" assertions now target the OLD source `scripts/<name>` (test-init.ps1:558-560 / test-init.sh:488-490) while "present" stays on `.harness/scripts/<name>`; fixture settings.json synthesized in OLD layout so the helper has a real rewrite. Harness soundness re-confirmed (`Assert` test-init.ps1:36 throws on false; `assert` test-init.sh:32 else-branches on non-zero) — the corrected fixture genuinely catches regressions. Dev disclosure accepted: prior 250/212 was never a real run (real baseline 246/4-fail PS, 205/7-fail SH); +1 to 251/213 is the new OLD-baseline.json-vacated assertion per shell.
- **Defect A (reviewer-missed) — `_doc_sync_hook` regex — FIXED.** PS lookbehind `(?<!\.harness/)scripts/harness-sync\.` + bash sed-strip-then-grep, both logically traced: PASS on migrated form, FAIL on a stale bare ref. Portable (no grep -P dependency).
- **Defect B (reviewer-missed) — bash AC-1 leaked-script check — FIXED.** test-init.sh:184 now asserts no harness file under OLD `scripts/`, symmetric with PS twin (was backwards, checking `.harness/scripts/`).
- **M-1 (MAJOR) — FIXED.** test-supervisor.sh:153 → `.harness/scripts/sync-self.sh`. Independent exhaustive live-ref sweep: every remaining bare `scripts/<harness-name>` hit is exempt/expected (_archived, CHANGELOG, dated HTMLs, propose-only settings.json, task work-products, MIGRATION historical body, intentional source-pattern literals in migrate-scripts-layout + OLD-layout fixture labels). Zero stale live runtime refs.
- **m-1 (MINOR) — FIXED.** baseline.json synthesized at OLD path + in downgrade set + in helper `$known` → move branch genuinely exercised.
- **Scope (verified):** only test-init.{ps1,sh} + test-supervisor.sh changed; `.claude/settings.json` still OLD-layout (propose-only honored); migrate helper + upstream docs untouched; no new PS/Bash asymmetry.
- **Pre-existing fan-out failures (verified out-of-scope):** test-supervisor.sh:378-409 check version/count literals (`v0.17.1`, `30 checks`, badges, plugin/marketplace version) — NOT paths; already red before T-007 (repo at v0.19.0/31). Version-stamp drift for the PM bump pass, not relocation drift.

**CODE REVIEW VERDICT: APPROVED** — all originals + both missed defects genuinely fixed; corrected counts (test-init 251/213, verify_all 31/31 both shells) consistent with verified changes; no new blocking findings.
