# 06 — Test Report · scripts-relocation (T-007)

> Stage 6 of 7. Independent QA validation of the `scripts/` → `.harness/scripts/`
> relocation against AC-1..AC-6 + gate conditions C-1..C-3. All claims below are
> backed by real tool runs (BOTH shells: pwsh + Git-for-Windows bash 5.2.37 / git
> 2.53.0, MSYS — not the WindowsApps stub, per L27/C-3). No production code edited.

## Mechanical results

| AC | Command run (both shells where applicable) | Result |
|---|---|---|
| **AC-3** gate green at new path | `.harness/scripts/verify_all.ps1` / `.sh` | **PS 31/31 PASS, 0 WARN, 0 FAIL, exit 0** · **SH 31/31 PASS, 0 WARN, 0 FAIL, exit 0** |
| **AC-1 + AC-5 + C-1** fresh init + migrate fixture | `.harness/scripts/test-init.ps1` / `.sh` | **PS 251 PASS / 0 FAIL, exit 0** · **SH 213 PASS / 0 FAIL, exit 0** (dev's corrected counts verified true) |
| **AC-4** zero stale live refs | independent `git grep` (see below) | **0 stale bare `scripts/<relocated>` refs** in live tracked files |
| **AC-6** template↔dogfood self-consistency | `sync-self.ps1 -Check` / `sh --check` | **PS "In sync" exit 0** · **SH "In sync" exit 0** (Layer-1 byte-identity clean) |
| **AC-2** moved guard fires | guard probe + `test-guard-rm.ps1`/`.sh` | guard BLOCKS outside-repo / ALLOWS in-repo; **17/17 PASS both shells** |

### AC-1/AC-5/C-1 — migrate fixture coverage (verified present in both shells)
The `test-init` migrate fixture asserts the full required end-state: present-at-NEW
(`.harness/scripts/{verify_all,harness-sync,guard-rm,baseline.json}`) + **vacated-at-OLD**
(`OLD scripts/harness-sync.ps1`, `OLD scripts/guard-rm.sh`, `OLD scripts/baseline.json`
vacated) + settings-rewired (Stop cmd, PreToolUse cmd, `_doc_sync_hook` doc string,
`permissions.allow`) + `-NoProfile`/`$schema` preserved + timestamped `.bak` written +
**idempotency** (2nd run = NO new `.bak`) + user-authored `scripts/deploy.sh` NOT moved.

### AC-4 — independent stale-reference scan
`git grep -E 'scripts/(verify_all|harness-sync|sync-self|install-hooks|archive-task|guard-rm|test-init|test-real-project|test-supervisor|test-verify-i6|test-guard-rm|migrate-scripts-layout)\.(ps1|sh)|scripts/(baseline\.json|verification_history\.log)'`
excluding `_archived/**`, `CHANGELOG.md`, the 5 dated HTML snapshots, propose-only
`.claude/settings.json`, `docs/features/scripts-relocation/**`, `MIGRATION.md`, and the
intentional source-pattern literals in `migrate-scripts-layout.*` + OLD-layout
test-init fixtures — then post-filtered to drop the `.harness/scripts/` (NEW) prefix.
**Result: zero hits.** The only remaining bare `scripts/` refs are in (a) `.claude/settings.json`
(4 sites — the propose-only red-line file, exactly matching the dev's proposed diff,
correctly NOT applied), and (b) `MIGRATION.md` lines 105-248 — the **historical**
v0.1.x→v0.2.0 body (below the appended T-007 section at line 1), correctly preserved.

## Adversarial tests (REQUIRED — ≥1 per AC, designed to BREAK it)

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW — I wrote it) | Outcome |
|---|---|---|---|
| AC-1/5 | helper corrupts/misses sites on a realistic OLD-layout project | synthetic OLD fixture in temp dir, run `migrate-scripts-layout.ps1` **and** `.sh`, assert 19-point end-state | **Survived** — both shells ALL-PASS (moves to NEW, vacates OLD, rewires all 4 settings sites, `.bak`, valid JSON, `deploy.sh` untouched) |
| AC-1/5 | 2nd run writes a new `.bak` / mutates | run helper twice on migrated fixture | **Survived** — "Already migrated / nothing to do.", no new `.bak`, both shells |
| AC-1/5 | `-DryRun`/`--dry-run` still writes something | DryRun on fresh OLD fixture, md5 settings before/after | **Survived** — 0 files moved, 0 `.bak`, settings md5 identical, both shells |
| AC-1/5 | `./`-prefix + extra flags (`-ExecutionPolicy Bypass --extra`) break substring replace or corrupt `$schema`/JSON | hostile settings.json, run helper, parse result as JSON | **Survived** — `./` prefix + extra flags preserved, no `.harness/.harness/` double-prefix, `$schema` intact, valid JSON, both shells |
| AC-1/5 | no-trailing-newline settings → invalid JSON / breaks idempotent fixed-point | settings ending at `}` (byte `0x7D`), run helper, re-run | **Survived** — valid JSON both shells; PS keeps no-newline (`0x7D`), SH adds one (`0x0A`, NIT n-1) but fixed-point compare strips it → idempotent (no new `.bak` on run 2) |
| AC-1/5 | already-migrated project (files moved + settings new) is not a clean no-op | fully-migrated fixture, run helper | **Survived** — "Already migrated / nothing to do.", no `.bak` |
| AC-2 | moved guard at new path fails to block outside-repo `rm` (fail-open) | pipe `{"tool_input":{"command":"rm -rf /c/Windows/Temp/..."}}` to `.harness/scripts/guard-rm.ps1` | **Survived** — BLOCKED, exit 2, correct stderr; in-repo `rm` ALLOWED exit 0; `git status` ALLOWED |
| AC-2 | canonical destructive eval cases regress after move | `test-guard-rm.ps1` / `.sh` (drives `evals/guard-rm-cases.md`) | **Survived** — 17/17 PASS both shells (incl. `Remove-Item C:\Windows` BLOCK) |
| AC-3 | F.1 self-check is path-blind (wouldn't catch a reverted constant) | flip F.1 path `.harness/scripts/`→`scripts/` in temp copy; + direct `Test-Path` matrix | **Survived** — mutated F.1 FAILs `Missing scripts/verify_all.ps1`; OLD path all-False, NEW path all-True |
| AC-3 (RISK-C boundary) | a re-added stray `scripts/zombie.ps1` slips a standing gate | drop stray script, run verify_all | **Boundary confirmed as documented** — verify_all still 31/31 (no standing repo-hygiene guard; gate-accepted residual, deferred follow-up) |
| AC-4 | scan methodology is unsound (misses a re-added ref) | inject `scripts/verify_all.ps1` into temp copy of `AI-GUIDE.md`, re-run grep | **Survived** — methodology CAUGHT the injected ref; control (real file) = 0 |
| AC-6 | byte-identity check is dead (wouldn't catch drift) | append 1 byte to `templates/common/.harness/scripts/guard-rm.sh`, run `sync-self -Check`; restore | **Survived** — drift detected (exit 1, names the file); byte-exact restore → clean (exit 0), identical md5 |

Full tool output for every row was captured during the QA run (verbatim PASS/FAIL
lines, exit codes, BLOCK stderr, md5 sums, hex last-bytes).

## Regression sweep (confirmed NOT broken by T-007)
- `verify_all.ps1` / `.sh`: **31/31 PASS** both shells, exit 0 (re-run for stability — stable).
- `test-init.ps1` / `.sh`: **251 / 213 PASS, 0 FAIL** both shells.
- `test-guard-rm.ps1` / `.sh`: **17/17 PASS** both shells.
- `test-verify-i6.ps1` / `.sh`: **56/56 PASS** both shells (I.6 retired-claim guard correctly
  treats the relocated `verify_all` / `test-verify-i6` self-check files as file-exempt, L26).
- `sync-self -Check`: clean both shells.
- **`test-supervisor.sh`: 46 PASS / 7 FAIL — PRE-EXISTING, not a T-007 regression.** All 7 are
  version-literal fan-out assertions (`30/30 at v0.17.1`, `0.17.1` badges, `30 checks at v0.17.1`
  in AI-GUIDE/README/README.zh-CN/plugin.json/marketplace.json/dev-map). Verified by reading
  `test-supervisor.sh:380-403`: these are **version-stamp** checks (repo is at v0.19.0 / 31 checks),
  **zero are path failures**. Owned by the PM's deferred version-bump pass (NIT n-2), not relocation.

## Boundary / cross-shell findings (all benign)
- **NIT n-1 (re-confirmed, not a defect):** SH helper's `printf '%s\n'` adds a trailing newline
  the PS `WriteAllText` does not. Confirmed live (last byte `0x0A` vs `0x7D`). Result is valid JSON
  and idempotency holds (fixed-point compare strips trailing newline). The dev's decision to leave
  it is correct. No route-back.
- **My ad-hoc guard case `Remove-Item C:\\Windows\\System32\\drivers` returned ALLOW** — traced to
  my own bash double-backslash escaping, not a guard defect; the canonical eval form (`Remove-Item
  -Recurse C:\Windows`, case 7/8/12) BLOCKs correctly. No defect.

## verify_all result
- Total checks: 31 → 31 (no check added/removed — out-of-scope per RA §3).
- PASS: 31 · FAIL: **0** · WARN: 0 (both shells).
- New tests added by QA: 0 (per task brief — ran existing regressions + independent adversarial
  probes; dev's migrate fixture is sound and was independently re-derived, not trusted).
- Baseline updated: **yes (up-only)** — `.harness/scripts/baseline.json` informational counts
  refreshed to observed truth: `test_init_ps_assertions` 227→251, `test_init_bash_no_python3_assertions`
  191→213, `last_verify`→2026-06-04. These fields are metadata (verify_all does not read them);
  the edit does not break Layer-1 sync (baseline.json is a repo-only data file) and verify_all
  stays 31/31. Counts only increased.

## Defects found
**None.** No BLOCKER / CRITICAL / MAJOR / MINOR defect. The two prior-round defects
(B-1 contradictory migrate assertions, M-1 stale `test-supervisor.sh:153`) are verified FIXED:
the migrate fixture's "vacated" assertions target the OLD `scripts/` source and genuinely pass
on a real run; `test-supervisor.sh` AC-2.3 invokes `.harness/scripts/sync-self.sh`.

## Stability
- `verify_all` (PS) and `sync-self -Check` re-run a 2nd time after the baseline edit — identical
  (31/31, "In sync"). `test-init` / `test-guard-rm` / `test-verify-i6` each deterministic across runs.
  No flakes observed.

## Verdict
**APPROVED FOR DELIVERY.** All six acceptance criteria verified mechanically in BOTH shells with
real tool evidence; every adversarial probe (12, ≥1 per AC) survived; the migration helper — the
highest-risk user-facing artifact — holds under hostile settings formatting, no-newline input,
dry-run, idempotency, partial-migration, and user-file-preservation in both shells. Conditions
C-1 (flipped init AC-1), C-2 (settings end-state asserted incl. doc string), C-3 (both shells via
real Git-bash) all satisfied. The 7 `test-supervisor` fan-out failures are pre-existing version-stamp
drift, not relocation regressions. One human step remains outside QA scope: applying the propose-only
`.claude/settings.json` diff (or running `migrate-scripts-layout`) so the dogfood hooks resolve at runtime.
