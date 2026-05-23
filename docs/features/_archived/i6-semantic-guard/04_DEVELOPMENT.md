# Development Record — i6-semantic-guard (T-004)

## Verdict

**READY FOR REVIEW**

The earlier `BLOCKED ON DESIGN` is resolved. The architect's Rev-4 fix (entry #10
`exclude=.claude/`) was applied to both `verify_all` scripts; the R-2 fix, the
`test-verify-i6.{ps1,sh}` regression pair, and the full v0.18.0 version fan-out are
complete. **Both shells: `verify_all` PASS 30 / WARN 0 / FAIL 0, I.6 = PASS. Both
shells: `test-verify-i6` all assertions pass (bash 34/34, PowerShell 35/35).**

## Summary

Completed the I.6 gap-tolerant retired-claim guard for v0.18.0. The matcher rewrite
(gap-tolerant ordered-anchor scan, line-scoped exclude, 13-entry list, `docs/features/`
exempt-dir) was already in place from the prior pass; this pass applied the one design
change since (entry #10's `exclude=.claude/`), fixed the R-2 `dev-map.md:113` line,
built the cross-shell `test-verify-i6` regression pair per design §7, and fanned the
v0.18.0 version stamp across all §10 surfaces. No new `verify_all` check — count stays 30.

## Files changed

### Production code
- `scripts/verify_all.sh` — entry #10 `i6_banned` record gained `exclude` token
  `.claude/` (`...since v0.10||` → `...since v0.10|.claude/|`); `i6_exempt_files`
  array gained `scripts/test-verify-i6.ps1` + `scripts/test-verify-i6.sh`; I.6 comment
  header updated to note the test-driver exemption. (The matcher rewrite itself was
  done in the prior pass.)
- `scripts/verify_all.ps1` — entry #10 `$banned` hashtable `exclude = @()` →
  `exclude = @('.claude/')`; `$exempt` array gained `scripts/test-verify-i6.ps1` +
  `scripts/test-verify-i6.sh`; exempt-files comment updated.
- `scripts/test-verify-i6.sh` — **NEW**. Bash regression driver for the I.6 matcher.
  Self-contained re-declaration of the matcher predicate (regex builder + per-line
  scan + line-scoped exclude), a 20-file fixture corpus per §7.2 in an isolated temp
  dir (`--keep-temp` to retain), `--emit-hits <dir>` parity-helper mode, and 6
  assertion groups (behavioral, cross-shell parity, structural lockstep, no-stderr,
  gap-boundary, F-1/F-2/F-4/Rev-4 regression).
- `scripts/test-verify-i6.ps1` — **NEW**. PowerShell twin, mirrored fixture corpus +
  assertion set, same `--emit-hits` mode.

### Docs / version fan-out (v0.17.4 → v0.18.0, per design §10)
- `docs/dev-map.md` — R-2 fix on line 113 (`Scaffolding-only in 0.1` → `Fully
  automated repo adoption since v0.3`); `30 checks at v0.17.4` → `v0.18.0` (×2);
  added `test-verify-i6.{ps1,sh}` to the scripts enumeration.
- `CHANGELOG.md` — new `## [0.18.0]` section describing the I.6 upgrade, the
  exempt-dir widening, the new test pair, and the version stamps.
- `AI-GUIDE.md` — `30 checks at v0.17.4` → `v0.18.0` and `I.6 retired-claim phrase
  guard` → `I.6 gap-tolerant retired-claim guard` (lines ~35, ~68); added a
  `test-verify-i6.{ps1,sh}` line to the scripts list.
- `.harness/rules/40-locations.md` — I.6 description line: appended `gap-tolerant
  ordered-anchor scan since v0.18`.
- `.harness/insight-index.md` — appended two dated 2026-05-23 follow-up lines (I.6
  gap-tolerant at v0.18.0; the GNU-grep `-F -i` SIGABRT + Windows `Get-Command bash`
  WSL-stub gotcha). File is 27 lines — within the I.4 30-line cap.
- `README.md` / `README.zh-CN.md` — version badge `0.17.4` → `0.18.0`; new `0.18.0`
  Roadmap row; the old `0.18+` planned row renumbered to `0.19+`.
- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` — `"version"`
  `0.17.4` → `0.18.0`.

## verify_all result

- Baseline (before this task's changes): PASS 30 / WARN 0 / FAIL 0.
- After the matcher rewrite, before entry #10's `exclude`: PASS 29 / WARN 0 / FAIL 1
  (I.6 hit 3 lines: `dev-map.md:113` expected + `README.md:196` / `README.zh-CN.md:198`
  the design gap — this was the prior `BLOCKED ON DESIGN` state).
- After this pass (entry #10 `exclude=.claude/` + R-2 `dev-map.md:113` fix):

  **PowerShell** — `pwsh -NoProfile -File scripts/verify_all.ps1`:
  ```
  [I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS
  === Summary ===
    PASS: 30
    WARN: 0
    FAIL: 0
  ```

  **bash** — `bash scripts/verify_all.sh`:
  ```
  [I.6] No retired-claim phrases in current docs/templates ... PASS
  === Summary ===
    PASS: 30
    WARN: 0
    FAIL: 0
  ```

- Delta: 0 new failures; the prior FAIL=1 (I.6) resolved by entry #10's `exclude`
  (clears the 2 README lines) + R-2 (`dev-map.md:113`). Check count unchanged at 30,
  per design (no new check). Cross-shell parity confirmed — both shells agree I.6 = PASS.

## test-verify-i6 result

- **bash** — `bash scripts/test-verify-i6.sh`:
  ```
  === Result ===
    PASS: 34
    FAIL: 0
  ```
- **PowerShell** — `pwsh -NoProfile -File scripts/test-verify-i6.ps1`:
  ```
  === Result ===
    PASS: 35
    FAIL: 0
  ```
- Both drivers run the same 20-file fixture corpus (§7.2, including
  `fx-arrow-accurate.md`, `fx-historical.md`, `fx-negation-pre.md`, gap-boundary,
  metachar/Unicode, multiline, empty, and one fixture per banned entry). The count
  differs by 1 because the bash structural-lockstep is one combined assertion while
  the PS twin splits it into "13 entries" + "matches verbatim". All assertion groups
  pass: behavioral hit/no-hit, cross-shell parity (each twin invokes the other's
  `--emit-hits` mode and compares the full hit set), structural lockstep against the
  live `verify_all` 13-entry list (incl. #10's `.claude/`), no-stderr on
  metacharacter fixtures, gap-boundary (40 HIT / 41 NO-hit), and the
  F-1/F-2/F-4/Rev-4 regression cases.

## Design drift (for the reviewer)

- **`DESIGN DRIFT — minor` (carried over, already in design §3.3/§14 Rev-4):** the
  bash line-scoped exclude uses `shopt -s nocasematch` + `[[ == *glob* ]]` instead of
  the §3.3-pseudocode `grep -F -i -q` — Git-for-Windows GNU grep 3.0 SIGABRTs on
  `-F -i`. Behaviorally identical; the design already records this. No action needed.

- **`DESIGN DRIFT — minor` (NEW, needs reviewer sign-off): I.6 exempt-FILE list
  extended.** The new `scripts/test-verify-i6.{ps1,sh}` regression drivers hold a
  verbatim copy of the 13-entry `i6_banned` list (mandated by design §7.3 assertion
  #3, structural lockstep) *plus* banned-phrase fixture strings (e.g.
  `regenerates CLAUDE.md`, `scaffolding-only`). Once these files are `git add`-ed they
  would be scanned by I.6 and FAIL — exactly the reason `verify_all.{ps1,sh}` are
  already in the `i6_exempt_files` list ("verify_all itself stores the banned-phrase
  strings"). Design §2 lists the test pair as NEW files but §3/§12 say "exempt-FILE
  membership unchanged"; adding the test pair IS a change to exempt-file membership.

  **Decision taken (flagged, not blocked):** added both test scripts to
  `i6_exempt_files` / `$exempt` in both verify_all scripts. Rationale for not
  re-routing to the architect: (1) the exemption mechanism is pre-existing and
  design-sanctioned; (2) the design's own §7.3 #3 *requires* the test pair to hold
  the banned list verbatim, so the design intends this; (3) it is the identical class
  as `verify_all.*` self-exemption — a re-block would be disproportionate. If the
  reviewer disagrees with treating this as in-scope drift rather than a design-doc
  change, route to the architect to formally amend §3/§12 (one sentence). The
  behavior is correct either way — verified: I.6 PASS in both shells.

## Open issues for review

- None functional. The one item warranting a reviewer eye is the exempt-file drift
  above — a scope/process call, not a correctness defect.
- The new test pair is repo-bespoke; per design §7.4 / D-6, `sync-self` is unchanged
  (it mirrors only `harness-sync`/`install-hooks`/`archive-task`/`guard-rm`). F.1
  script-symmetry only checks a fixed 5-pair list, so the new pair just needs both
  `.ps1` + `.sh` present — confirmed.

## Dev-map updates

`docs/dev-map.md`:
- Line 113 (R-2): `Scaffolding-only in 0.1` → `Fully automated repo adoption since v0.3`.
- Scripts box: `verify_all` note `30 checks at v0.17.4` → `v0.18.0`; new line
  `test-verify-i6.{ps1,sh} ← verify_all I.6 gap-tolerant matcher regression (v0.18+;
  fixture corpus + cross-shell parity + structural lockstep)`.
- Reusable-utilities table: `verify_all` row `at v0.17.4` → `at v0.18.0`.

## Insight to surface

- GNU grep 3.0 as shipped with Git-for-Windows MSYS aborts (SIGABRT, exit 134) when
  `-F` and `-i` are combined; `-F -q`, `-i -q`, and `-E -i` are unaffected. Prefer
  bash-native `shopt -s nocasematch` + `[[ == *glob* ]]` for case-insensitive literal
  substring tests in dogfood scripts. · evidence: T-004 I.6 line-scoped exclude,
  scripts/verify_all.sh
- On Windows, `Get-Command bash` resolves the WindowsApps WSL launcher stub *before*
  Git-for-Windows bash; a script that shells out to bash must derive Git-bash from
  `git.exe`'s install root (`<Git>\bin\bash.exe`) or it gets a non-POSIX stub that
  prints a "WSL not installed" banner. · evidence: T-004 test-verify-i6.ps1 cross-shell
  parity assertion
- The I.6 regression driver necessarily holds a verbatim copy of the banned list, so
  the I.6 exempt-FILE list must grow with it — the same self-reference that already
  exempts `verify_all.*`. A guard that scans the whole repo for banned phrases will
  always need to exempt its own test fixtures. · evidence: T-004, verify_all I.6
  `i6_exempt_files`

(Both insight-index follow-up lines are appended to `.harness/insight-index.md` at
27 lines total — within the I.4 30-line cap, so no archive-rotation was needed.)

## Verdict

READY FOR REVIEW

## Rev-2 (Code Review fix)

Code Review 05 flagged one MAJOR: the `.harness/rules/40-locations.md` section-header
freshness stamp on line 25 still read `30 items at v0.17.4`. The companion I.6
description line (43) had been correctly bumped to `since v0.18` in the original pass,
but line 25 was missed during the v0.18.0 version fan-out.

### Edit (1 line, 1 file)

- `.harness/rules/40-locations.md:25`
  - Before: `` `scripts/verify_all` checks (30 items at v0.17.4, all must PASS — count grows with releases): ``
  - After:  `` `scripts/verify_all` checks (30 items at v0.18.0, all must PASS — count grows with releases): ``

Re-Read line 25 after the edit (per insight L10) confirms the new text is in place.
Check count unchanged at 30.

### Grep sweep — remaining `v0.17.4` references

`Grep "v0\.17\.4"` over tracked files returns 16 hits across 9 files. Classification
against the §10 contract + the Code Review 05 explicit allow-list:

| Path:Line | Category | Action |
|---|---|---|
| `architecture.html:326` | Exempt — v0.5 snapshot caveat per §10 / CR-05 §57 | Leave |
| `CHANGELOG.md:12,28,55` | Exempt — CHANGELOG (per CR-05 explicit exemption) | Leave |
| `docs/manual-e2e-test.md:3` | MINOR observation in CR-05 §20, not §10 contract, told to leave alone | Leave |
| `docs/dev-map.md:78` | `test-supervisor.{ps1,sh}` assertion-count stamp ("57 PS / 53 Bash at v0.17.4") — a *different* freshness stamp (test-suite assertion counts, not verify_all check counts), not part of T-004 §10 scope | Leave; flag as Open issue (separate refresh) |
| `docs/features/i6-semantic-guard/01,02,04,05`, `PM_LOG.md` | Frozen task-history audit trail (the historical "v0.17.4 + this change" narrative) — historical references in task docs are never retro-bumped | Leave |

Zero remaining hits qualify as `v0.17.4` freshness-stamp drift under T-004's §10
contract. The `dev-map.md:78` test-supervisor stamp is a real but out-of-scope
observation (the next test-supervisor touch should refresh it); raising it now would
expand T-004 beyond its design.

### verify_all — both shells

**PowerShell** — `pwsh -NoProfile -File scripts/verify_all.ps1`:
```
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS
=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

**bash** — `bash scripts/verify_all.sh`:
```
[I.6] No retired-claim phrases in current docs/templates ... PASS
=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

Both shells: PASS 30 / WARN 0 / FAIL 0; I.6 = PASS; check count unchanged at 30.

### test-verify-i6 — both shells

**PowerShell** — `pwsh -NoProfile -File scripts/test-verify-i6.ps1`:
```
=== Result ===
  PASS: 35
  FAIL: 0
```

**bash** — `bash scripts/test-verify-i6.sh`:
```
=== Result ===
  PASS: 34
  FAIL: 0
```

All assertion groups still pass in both drivers (behavioral, cross-shell parity,
structural lockstep against the live 13-entry `i6_banned` list, no-stderr,
gap-boundary 40-HIT/41-NO-hit, F-1/F-2/F-4/Rev-4 regression). Twin count delta of 1
is the long-standing structural-lockstep split (PS = "13 entries" + "matches
verbatim", bash = one combined assertion), unchanged from Rev-1.

### Verdict (unchanged)

The Rev-1 `## Verdict` above still reads `READY FOR REVIEW`. The MAJOR is resolved
with a one-line stamp bump; no design drift, no new files, no new checks.
