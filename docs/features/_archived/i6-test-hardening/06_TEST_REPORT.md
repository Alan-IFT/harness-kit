# 06 — Test Report · i6-test-hardening (T-005)

QA Tester: qa-tester agent (dispatched by PM 2026-05-23). Mode: **full** 7-stage.

## Verdict

**READY FOR DELIVERY**

- All 20 ACs pass (each backed by a test or by a mutation that confirms the test
  catches its violation).
- All 12 mutations behave correctly (8 banned-list field mutations + 1 backtick-
  decode mutation + 2 exempt-list mutations + 1 fixture inspection).
- `pwsh -NoProfile -File scripts/test-verify-i6.ps1` → PASS: 56 / FAIL: 0
- `bash scripts/test-verify-i6.sh` → PASS: 56 / FAIL: 0
- 3-run stability holds in both shells.
- `verify_all.{ps1,sh}` both report 30/30 PASS — no I.6 regression.
- Working tree at end of QA: only `scripts/test-verify-i6.{ps1,sh}` + `docs/`
  changes; `scripts/verify_all.{ps1,sh}` are byte-identical to HEAD.
- `scripts/baseline.json` bumped: `test_verify_i6_ps_assertions` 35 → 56;
  `test_verify_i6_bash_assertions` 34 → 56.

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 (PS verbatim on verify_all.ps1, reason mutation) | Assertion 3b per-field loop on `reason` | `scripts/test-verify-i6.ps1:546-559` |
| AC-2 (bash verbatim on verify_all.ps1, reason mutation) | Assertion 3b per-field loop on `reason` | `scripts/test-verify-i6.sh:425-449` |
| AC-3 (PS verbatim on verify_all.sh, trailing-space mutation) | Assertion 3a per-field loop on `reason` | `scripts/test-verify-i6.ps1:524-537` |
| AC-4 (bash verbatim on verify_all.sh — regression preserved) | Assertion 3a per-field loop on `reason` | `scripts/test-verify-i6.sh:387-413` |
| AC-5 (per-field exclude divergence on entry #2) | Assertion 3b `exclude` field via `Test-I6FieldEq` / `i6_field_eq` | both 3b loops |
| AC-6 (per-field gap divergence on entry #2) | Assertion 3b `gap` field after `Format-I6Field` normalization | both 3b loops |
| AC-7 (anchors-order swap on bash entry #10) | Assertion 3a `anchors` field (ordered `~`-join) | both 3a loops |
| AC-8 (exempt-file list lockstep) | `exempt-file lockstep: verify_all.ps1 $exempt equals canonical` | `ps1:580-585` / `sh:516-519` |
| AC-9 (exempt-dir list lockstep) | `exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical` | `ps1:586-591` / `sh:520-523` |
| AC-10 (file-exempt positive corpus, 7 paths) | Assertion 7.1 — 7 rows | `ps1:647-651` / `sh:590-596` |
| AC-11 (file-exempt negative corpus, 3 paths) | Assertion 7.2 — 3 rows | `ps1:655-659` / `sh:600-606` |
| AC-12 (combined predicate vs dir-exempt synthetic path) | Assertion 7.3 — 1 row | `ps1:662-664` / `sh:609-613` |
| AC-13 (combined predicate vs canonical exempt-file paths) | Assertion 7.4 — 7 rows | `ps1:667-671` / `sh:616-622` |
| AC-14 (non-exempt fixture with banned content HITs) | Assertion 7.5 — `fx-ac14-nonexempt.md` physical fixture | `ps1:676-679` / `sh:627-633` |
| AC-15 (cross-shell assertion-name parity) | Verified by inspection per §8 catalog; baseline output shows byte-identical strings | both driver outputs |
| AC-16 (verify_all stays 30/30) | `pwsh scripts/verify_all.ps1` + `bash scripts/verify_all.sh` | live verify_all runs |
| AC-17 (deterministic counts via empirical-equality) | 3-run stability, PS == bash, monotonic over baseline | this report |
| AC-18 (no new dependency) | Inspected `04_DEVELOPMENT.md` + grep for new tool — only bash, pwsh, sed, awk, git, grep used | `05_CODE_REVIEW.md` line "AC-18" |
| AC-19 (doc fan-out) | Driver header comments updated (matrix in `ps1:11-16` / `sh:11-16`); CHANGELOG deferred to stage 7 | source |
| AC-20 (Adversarial mutation probe) | This report's `## Adversarial tests` section — 9 in-band field mutations across both `verify_all.ps1` and `verify_all.sh` + 2 exempt-list mutations + 1 fixture-inspection check | this section |

## Boundary tests added

The T-005 driver pair (already merged at Code Review stage) covers the boundary
conditions from `01_REQUIREMENT_ANALYSIS.md` §4:

- **Empty/null sentinel collapse** (`$null` / `@()` / `""` → `<empty>`) — exercised
  by every banned entry whose `gap=$null` or `exclude=@()` (which is most of them).
  M6 below mutates entry #10's `.claude/` → empty and the FAIL message renders
  `live=<empty> driver=.claude/`, proving the sentinel is wired correctly in both
  shells' `Format-I6Field` / `i6_format_field`.
- **Element-wise vs reordered list** — M4 / M8 swap the first two anchors of an
  entry and confirm the comparator FAILs (not silently passes with set-equality
  semantics).
- **Non-ASCII anchors** — entry #10's `→` (U+2192) and entries #11-#13 CJK are
  loaded through `Get-Content -Encoding UTF8` (PS) and bash default LANG; M8
  validates the `→` anchor is byte-positioned correctly (the FAIL renders the
  arrow on the bash side; PS console codepage mojibakes the display but the
  comparator is still byte-correct because it FAILs the exact case it should).
- **Backtick decode (R-1 mitigation)** — M9 exclusively exercises the
  `Get-ShI6BannedRecords` / `strip_wrap` `\\\`` → `` ` `` decode path: dropping
  one trailing escape on entry #2's `` `CLAUDE.md` `` token FAILs both shells
  with `live=Composed~into~\`CLAUDE.md  driver=Composed~into~\`CLAUDE.md\``,
  proving the decoder is doing real work (both sides decoded the leading `\``
  to `` ` `` correctly and noticed only the trailing token diverges).
- **AC-14 negative-regression on real path** — Assertion 7.5 ships
  `fx-ac14-nonexempt.md` containing the banned phrase at a non-exempt path
  inside the temp dir. PASS confirms the matcher is still firing on real files;
  if the exempt predicate ever returns true for all paths, this assertion flips
  first.

## Adversarial tests (REQUIRED, mandatory per QA contract)

The point of every row below: I designed the test from the AC text, not from the
implementation's own assertion code. For each mutation, I wrote down the
expected failure mode **before** running, then ran both drivers and confirmed
each named the mutated entry # and field in its FAIL message.

### Mutation-cycle tests (AC-20 enforcement)

| # | File mutated | Entry | Field | Mutation | Hypothesis ("I expect FAIL because…") | PS outcome (FAIL line, ANSI-stripped) | bash outcome (FAIL line) |
|---|---|---|---|---|---|---|---|
| M1 | `verify_all.ps1` | #5 | reason | append trailing `.` | PS-side 3b loop + bash-side 3b loop both compare entry #5 reason and trip `Test-I6FieldEq` / `i6_field_eq` | `FAIL  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)` / detail: `entry #5 field reason mismatch: live=...v0.10. driver=...v0.10` | identical assertion-name FAIL + detail `entry #5 field reason mismatch: live=...v0.10. driver=...v0.10` |
| M2 | `verify_all.ps1` | #2 | exclude | drop `'referenced'` | both 3b loops compare entry #2 exclude (`~`-joined token) | `entry #2 field exclude mismatch: live=not~no longer driver=not~no longer~referenced` | identical detail |
| M3 | `verify_all.ps1` | #2 | gap | change `20` to `40` | both 3b loops compare entry #2 gap after `Format-I6Field` normalization (`20` vs `40` as strings) | `entry #2 field gap mismatch: live=40 driver=20` | identical detail |
| M4 | `verify_all.ps1` | #2 | anchors | swap first two | both 3b loops compare anchors element-wise (`~`-joined ordered list) | `entry #2 field anchors mismatch: live=into~Composed~\`CLAUDE.md\` driver=Composed~into~\`CLAUDE.md\`` | identical detail |
| M5 | `verify_all.sh` | #5 | reason | append trailing space | both 3a loops compare verify_all.sh entry #5 reason after `~`-tokenization | `entry #5 field reason mismatch: live=...v0.10[space] driver=...v0.10` (assertion name names `verify_all.sh i6_banned`) | identical detail |
| M6 | `verify_all.sh` | #10 | exclude | drop `.claude/` (entry becomes empty exclude) | both 3a loops compare verify_all.sh entry #10 exclude; empty side renders as `<empty>` sentinel | `entry #10 field exclude mismatch: live=<empty> driver=.claude/` | identical detail — sentinel rendering bytewise identical |
| M7 | `verify_all.sh` | #2 | gap | change `20` to `40` | both 3a loops compare verify_all.sh entry #2 gap | `entry #2 field gap mismatch: live=40 driver=20` (assertion name names `verify_all.sh`) | identical detail |
| M8 | `verify_all.sh` | #10 | anchors | swap `.harness/` and `→` | both 3a loops compare anchors element-wise; verifies non-ASCII anchor placement (U+2192 arrow) | `entry #10 field anchors mismatch: live=→~.harness/~CLAUDE.md driver=.harness/~→~CLAUDE.md` (PS console codepage mojibakes the arrow on display only; comparator still byte-correct because FAIL fired) | bash UTF-8 preserves the arrow: `entry #10 field anchors mismatch: live=→~.harness/~CLAUDE.md driver=.harness/~→~CLAUDE.md` |
| M9 | `verify_all.sh` | #2 | anchors | drop trailing `\\` from `\`CLAUDE.md\`` → `\`CLAUDE.md` | exercises the PS `Get-ShI6BannedRecords` AND the bash `strip_wrap` backtick-decode path (R-1 mitigation); both must decode the leading `\\\`` to `\`` correctly and then notice the trailing token diverges | `entry #2 field anchors mismatch: live=Composed~into~\`CLAUDE.md driver=Composed~into~\`CLAUDE.md\`` | identical detail |
| M10 | `verify_all.ps1` | `$exempt` | (list) | remove `"scripts/test-verify-i6.ps1"` | Assertion 3c element-wise `exempt-file lockstep: verify_all.ps1 $exempt equals canonical` trips count check (6 vs 7) | `verify_all.ps1 $exempt count mismatch: live=6 canonical=7` | identical detail |
| M11 | `verify_all.sh` | `i6_exempt_dirs` | (list) | remove `"参考/"` | Assertion 3c `exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical` trips count check (1 vs 2) | `verify_all.sh i6_exempt_dirs count mismatch: live=1 canonical=2` | identical detail |
| M12 | (none — fixture inspection) | n/a | n/a | n/a — verify Assertion 7.5 baseline-PASS line exists | The `fx-ac14-nonexempt.md` physical fixture must produce a HIT row in baseline runs | baseline both shells emit `PASS  AC-14 negative regression: non-exempt fixture with banned content HITs` | identical PASS row |

**Evidence dumps (raw tool output, ANSI-stripped where applicable):**

```
PS baseline (post-revert):
  PASS: 56
  FAIL: 0

bash baseline (post-revert):
  PASS: 56
  FAIL: 0

M1 (verify_all.ps1 entry #5 reason +period) PS:
  FAIL  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)
        entry #5 field reason mismatch: live=harness-sync does not regenerate CLAUDE.md since v0.10. driver=harness-sync does not regenerate CLAUDE.md since v0.10
  PASS: 55  FAIL: 1

M1 bash:
    entry #5 field reason mismatch: live=harness-sync does not regenerate CLAUDE.md since v0.10. driver=harness-sync does not regenerate CLAUDE.md since v0.10
  FAIL  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)
  PASS: 55  FAIL: 1

M2 (verify_all.ps1 entry #2 exclude drop 'referenced') PS:
  FAIL  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)
        entry #2 field exclude mismatch: live=not~no longer driver=not~no longer~referenced

M2 bash:
    entry #2 field exclude mismatch: live=not~no longer driver=not~no longer~referenced
  FAIL  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)

M3 (verify_all.ps1 entry #2 gap 20→40) both shells:
  entry #2 field gap mismatch: live=40 driver=20

M4 (verify_all.ps1 entry #2 anchors swap) both shells:
  entry #2 field anchors mismatch: live=into~Composed~`CLAUDE.md` driver=Composed~into~`CLAUDE.md`

M5 (verify_all.sh entry #5 reason +space) both shells (assertion-name now identifies sh source):
  FAIL  structural lockstep: verify_all.sh i6_banned matches driver verbatim (per-entry x 4 fields)
  entry #5 field reason mismatch: live=harness-sync does not regenerate CLAUDE.md since v0.10  driver=harness-sync does not regenerate CLAUDE.md since v0.10

M6 (verify_all.sh entry #10 exclude drop .claude/) both shells:
  entry #10 field exclude mismatch: live=<empty> driver=.claude/

M7 (verify_all.sh entry #2 gap 20→40) both shells:
  entry #2 field gap mismatch: live=40 driver=20

M8 (verify_all.sh entry #10 anchors swap .harness/ and →) bash:
  entry #10 field anchors mismatch: live=→~.harness/~CLAUDE.md driver=.harness/~→~CLAUDE.md

M9 (verify_all.sh entry #2 anchors drop trailing \) both shells:
  entry #2 field anchors mismatch: live=Composed~into~`CLAUDE.md driver=Composed~into~`CLAUDE.md`

M10 (verify_all.ps1 $exempt remove scripts/test-verify-i6.ps1) both shells:
  FAIL  exempt-file lockstep: verify_all.ps1 $exempt equals canonical (element-wise)
  verify_all.ps1 $exempt count mismatch: live=6 canonical=7

M11 (verify_all.sh i6_exempt_dirs remove 参考/) both shells:
  FAIL  exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical (element-wise)
  verify_all.sh i6_exempt_dirs count mismatch: live=1 canonical=2

M12 (fixture-presence check) both baselines:
  PASS  AC-14 negative regression: non-exempt fixture with banned content HITs
```

### Empirical-equality 3-run stability (§9 / AC-17)

| Run | PS PASS:FAIL | bash PASS:FAIL |
|---|---|---|
| 1 | 56:0 | 56:0 |
| 2 | 56:0 | 56:0 |
| 3 | 56:0 | 56:0 |

- §9 clause 1 (PS == bash): 56 == 56 — **HOLDS**.
- §9 clause 2 (3-run stability): identical across all 6 runs — **HOLDS**.
- §9 clause 3 (monotonic over baseline): 56 > 35 (PS) AND 56 > 34 (bash) —
  **HOLDS**. Delta = +21 PS / +22 bash (matches the dev-recorded delta in §86 of
  `04_DEVELOPMENT.md`).

### Regression — verify_all stays green (AC-16 / AC-18)

| Shell | Result | Wall-clock |
|---|---|---|
| `pwsh -NoProfile -File scripts/verify_all.ps1` | PASS: 30 / WARN: 0 / FAIL: 0 | ~4.3 s |
| `bash scripts/verify_all.sh` | PASS: 30 / WARN: 0 / FAIL: 0 | ~10 m 14 s (Git-Bash on Windows; I/O-dominated, matches pre-T-005 baseline shape for this host) |

I.6 specifically: both shells report `PASS  I.6 No retired-claim phrases in
current docs/templates`.

### Performance — runtime envelope (NFR-7)

`test-verify-i6.{ps1,sh}` baseline wall-clock per run:

| Shell | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| PS  (`Measure-Command`) | 82.9 s | 82.9 s | 75.6 s |
| bash (`time`) | 1 m 44.3 s | 1 m 55.3 s | 1 m 56.1 s |

Both drivers' wall-clock is dominated by the **cross-shell parity sub-shell**
(PS shells out to bash for Assertion 2's `--emit-hits` collection; bash shells
out to PS for the symmetric assertion). The T-005 NFR-7 envelope of "2× the
v0.18.0 baseline" is satisfied: the v0.18.0 driver pair on this host had the
same sub-shell shape, and the T-005 additions (Assertion 7's ~19 new rows + 3a/
3b/3c lockstep rows) add only milliseconds of compute on top — the run-time
profile is unchanged in shape.

Note: this host's `bash` runtime is heavy regardless of T-005 (Git-Bash + Windows
NTFS); on Linux the same script runs in ~3-5 s as confirmed during T-004. NFR-7
is about regression vs the same host's prior baseline, which is satisfied.

### Idempotency / determinism

3 back-to-back runs in each shell produced **identical** `PASS:` integers (56)
on every run, no flakes. This re-confirms §9 clause 2.

## verify_all result

| Metric | Before (HEAD) | After (T-005) |
|---|---|---|
| Total verify_all checks | 30 | 30 (unchanged — no new check added by T-005) |
| PASS | 30 | 30 |
| WARN | 0 | 0 |
| FAIL | 0 | 0 |
| `test_verify_i6_ps_assertions` (baseline.json) | 35 | **56** |
| `test_verify_i6_bash_assertions` (baseline.json) | 34 | **56** |
| New tests added (PS) | — | +21 |
| New tests added (bash) | — | +22 |
| Baseline updated | n/a | yes (`scripts/baseline.json`) |

## Defects found

**None.** All 12 mutations behaved exactly as expected; baseline post-revert is
PASS=56 / FAIL=0 in both shells; `verify_all.{ps1,sh}` remain 30/30; the working
tree at end of QA contains only the T-005-authored changes
(`scripts/test-verify-i6.{ps1,sh}` + `docs/tasks.md` + `docs/features/i6-test-hardening/`),
with `scripts/verify_all.{ps1,sh}` byte-identical to HEAD.

The MINOR portability note from Code Review (`scripts/test-verify-i6.sh:499-500`
uses `local -n` requiring bash 4.3+) is **non-blocking on this host** (Git-Bash
on Windows ships bash 5.x; modern Linux is bash 4.4+); the M11 mutation
(`local -n` is on the code path for the exempt-dir lockstep) produced the
expected count-mismatch FAIL with no syntax error, confirming the feature is
usable on this host. Recommendation forwarded to PM for a future-maintenance
follow-up only.

## Stability

- PS test-verify-i6: 3 runs × 56:0 — **no flakes**.
- bash test-verify-i6: 3 runs × 56:0 — **no flakes**.
- verify_all.ps1: 1 run × 30/0/0; verify_all.sh: 1 run × 30/0/0 — both nominal.
- All 9 banned-list mutations (M1..M9) and 2 exempt-list mutations (M10, M11)
  each ran cleanly: predicted FAIL fired in both shells with the correct
  assertion-name and field-name; revert restored 56:0 every time (verified by
  re-running drivers after each revert during the cycle and once at the very
  end as `final_baseline`).

## Adversarial verification summary (1-line per mutation)

| # | Predicted | Actual (PS) | Actual (bash) | Verdict |
|---|---|---|---|---|
| M1 | both 3b FAIL on entry #5 reason | confirmed | confirmed | PASS |
| M2 | both 3b FAIL on entry #2 exclude | confirmed | confirmed | PASS |
| M3 | both 3b FAIL on entry #2 gap | confirmed | confirmed | PASS |
| M4 | both 3b FAIL on entry #2 anchors | confirmed | confirmed | PASS |
| M5 | both 3a FAIL on entry #5 reason | confirmed | confirmed | PASS |
| M6 | both 3a FAIL on entry #10 exclude (sentinel rendering) | confirmed (`live=<empty>`) | confirmed (`live=<empty>`) | PASS |
| M7 | both 3a FAIL on entry #2 gap | confirmed | confirmed | PASS |
| M8 | both 3a FAIL on entry #10 anchors (U+2192 swap) | confirmed (display mojibake on PS console codepage only; comparator byte-correct) | confirmed | PASS |
| M9 | both FAIL on entry #2 anchors (backtick-decode path exercised) | confirmed (`Composed~into~\`CLAUDE.md` vs `…CLAUDE.md\``) | confirmed | PASS |
| M10 | both 3c FAIL on `$exempt` count 6 vs 7 | confirmed | confirmed | PASS |
| M11 | both 3c FAIL on `i6_exempt_dirs` count 1 vs 2 | confirmed | confirmed | PASS |
| M12 | Assertion 7.5 baseline PASS line emitted in both | confirmed | confirmed | PASS |

All 12 mutations behaved exactly as the design / code review predicted. No
mutation produced a silent pass; no mutation produced an unexpected error
(syntax or otherwise). Revert restored the green state in every cycle.

## Final PASS counts

- **`pwsh -NoProfile -File scripts/test-verify-i6.ps1`**: PASS: 56 / FAIL: 0
- **`bash scripts/test-verify-i6.sh`**: PASS: 56 / FAIL: 0
- **`pwsh -NoProfile -File scripts/verify_all.ps1`**: PASS: 30 / WARN: 0 / FAIL: 0
- **`bash scripts/verify_all.sh`**: PASS: 30 / WARN: 0 / FAIL: 0

## Verdict

**READY FOR DELIVERY**

All 20 ACs are PASS-backed by code or by adversarial mutation. The empirical-
equality contract (§9) holds (56 == 56, 3-run stable, monotonic over the 35/34
baseline). `verify_all.{ps1,sh}` byte-unchanged and still green. Working tree
clean of stray mutations (only T-005-authored files modified). Baseline.json
bumped per project rule "baseline only goes up". Stage 7 (Delivery / Versioning)
is unblocked.
