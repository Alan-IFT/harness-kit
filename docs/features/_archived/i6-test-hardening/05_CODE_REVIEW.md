# 05 — Code Review · i6-test-hardening (T-005)

Reviewer: code-reviewer agent (dispatched by PM 2026-05-23). Mode: **full** 7-stage.

## Verdict

**APPROVED**

No CRITICAL, no MAJOR findings. One MINOR portability note (`local -n` requires bash 4.3+).
The implementation matches `02_SOLUTION_DESIGN.md` faithfully; all 20 ACs have backing code;
§9's empirical-equality contract holds (PS == bash == 56, 3-run stable, monotonic over the
35/34 baseline); `verify_all.{ps1,sh}` are byte-unchanged; the three GR-flagged Minor items
(m-1, m-2, m-3) are all correctly absorbed.

## Files reviewed

- `scripts/test-verify-i6.ps1` (706 lines)
- `scripts/test-verify-i6.sh` (556 lines)
- `scripts/verify_all.ps1:469-565` (lockstep target, unchanged — confirmed byte-identical)
- `scripts/verify_all.sh:501-599` (lockstep target, unchanged — confirmed byte-identical)
- `.harness/insight-index.md` (unchanged at task end — correct per AC-19)

## m-1 / m-2 / m-3 verification status

- **m-1 (PS backtick decode at `test-verify-i6.ps1:182`)**: VERIFIED CORRECT. Single-quoted
  regex literal `'\\`'` (pattern) → `'`'` (replacement) correctly decodes bash's `\``
  escape to a literal backtick. Bash mirror at `:376` uses `${s//\\\`/\`}` symmetrically.
  Both sides converge on the literal-backtick canonical token for entries #2/#6/#8. A wrong
  decode would FAIL the per-entry-anchors comparator on every run, not just AC-20 mutation.
- **m-2 (PS `$` escape in assertion names)**: VERIFIED CORRECT. Every PS use of `$banned`
  / `$exempt` / `$exemptDirs` inside a double-quoted assertion-name string at L540/L546/L580
  /L586 (and thrown messages L542/L581/L587) uses the `` `$ `` backtick-escape; bash twins
  at L421/L423/L449/L516/L517/L520/L521 use `\$`; both render byte-identical literal
  `$banned` / `$exempt` / `$exemptDirs` in output.
- **m-3 (no bare PS case-insensitive operators in new T-005 code)**: VERIFIED CLEAN. Full
  grep of L139-313 + L500-680 (the T-005 diff region) shows every `-eq` is on `$null` /
  `.Count` / empty-string literal where casing is meaningless. The only literal-token PS
  comparator is `-ceq '$null'` at L244 (correct). The only PS membership operator is
  `-ccontains` at L126 (correct). PS regex matchers in the diff are `-cmatch` (L171, L172,
  L211, L216-219, L261, L262, L279, L280) and `-cnotmatch` (L211) — all correct.

## Findings

### CRITICAL
(none)

### MAJOR
(none)

### MINOR

- **[MAINT] `scripts/test-verify-i6.sh:499-500` `local -n` portability.** `i6_compare_lists`
  uses bash nameref `local -n live_arr="$live_name"`, which requires bash 4.3+. macOS's
  default `/usr/bin/env bash` is bash 3.2 and would error out with "bad option: -n". The
  project's de-facto target is Git-bash on Windows (5.x) and modern Linux (4.4+), so this
  works in practice, but it's the only `local -n` usage in the entire `scripts/` tree.
  Recommendation: add a one-line comment at the function naming the bash 4.3+ floor, or
  refactor to inline expansion in a future maintenance pass. **Not blocking.**

### NIT (informational only)

- `scripts/test-verify-i6.ps1:468` — pre-existing `-notmatch 'WindowsApps'` (outside the
  T-005 diff). `-cnotmatch` would be marginally tighter against insight L7/L20/L23. No
  action required this stage.
- `scripts/test-verify-i6.ps1:121,203,293` — doc-comments contain bare `$banned` /
  `$exempt` / `$exemptDirs` without backtick-escape. PS does not interpolate inside `#`
  comments, so this is harmless. Cosmetically inconsistent with the assertion-name escapes.

## Requirement coverage matrix (AC-1..AC-20)

| AC | Implementation site | Status |
|---|---|---|
| AC-1 (PS verbatim on verify_all.ps1, reason mutation) | `ps1:546-559` Assertion 3b per-field loop | OK |
| AC-2 (bash verbatim on verify_all.ps1, reason mutation) | `sh:425-449` Assertion 3b per-field loop | OK |
| AC-3 (PS verbatim on verify_all.sh, trailing-space mutation) | `ps1:524-537` Assertion 3a per-field loop | OK |
| AC-4 (bash verbatim on verify_all.sh — regression preserved) | `sh:387-413` Assertion 3a per-field loop | OK |
| AC-5 (per-field exclude divergence on entry #2) | both 3b loops via `Test-I6FieldEq` on exclude field | OK |
| AC-6 (per-field gap divergence on entry #2) | both 3b loops; gap field compared after `Format-I6Field` normalization | OK |
| AC-7 (anchors-order swap on bash entry #10) | both 3a loops on anchors field (ordered `~`-join) | OK |
| AC-8 (exempt-file list lockstep) | `ps1:580-585` / `sh:516-519` 3c element-wise | OK |
| AC-9 (exempt-dir list lockstep) | `ps1:586-591` / `sh:520-523` 3c element-wise | OK |
| AC-10 (file-exempt positive corpus, 7 paths) | `ps1:647-651` / `sh:590-596` Assertion 7.1 | OK |
| AC-11 (file-exempt negative corpus, 3 paths) | `ps1:655-659` / `sh:600-606` Assertion 7.2 | OK |
| AC-12 (combined predicate vs dir-exempt synthetic path) | `ps1:662-664` / `sh:609-613` Assertion 7.3 | OK |
| AC-13 (combined predicate vs canonical exempt-file paths) | `ps1:667-671` / `sh:616-622` Assertion 7.4 | OK |
| AC-14 (non-exempt fixture with banned content HITs) | `ps1:676-679` / `sh:627-633` Assertion 7.5; fixture at `ps1:345` / `sh:221` | OK |
| AC-15 (cross-shell assertion-name parity) | inspected pair-by-pair against §8 catalog; byte-identical after `$` resolution | OK |
| AC-16 (verify_all stays 30/30) | PS confirmed 30/30; bash confirmed 30/30 (post-CR background run) | OK |
| AC-17 (deterministic counts via empirical-equality) | PS==bash==56; 3-run stable both shells (6 runs verified); 56 > 35 / 56 > 34 | OK |
| AC-18 (no new dependency) | only bash, pwsh, sed, awk, git, grep used | OK |
| AC-19 (doc fan-out) | driver header comments updated (`ps1:11-16` / `sh:11-16`); CHANGELOG deferred to stage 7 | OK |
| AC-20 (Adversarial mutation probe) | implementation makes all 8 mutations detectable; QA stage-6 will exercise | Deferred to stage 6 (code supports) |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.2 sentinel `<empty>` declared once per shell | `ps1:30` / `sh:26` | OK |
| §3.2 `Format-I6Field` / `i6_format_field` handles array/string/null | `ps1:139-149` 3-branch / `sh:169-171` 1-branch (sufficient because bash records pre-`~`-joined) | OK |
| §3.2 `Test-I6FieldEq` uses `-ceq` mandatory | `ps1:155` | OK |
| §3.2 `i6_field_eq` uses `[[ "$a" == "$b" ]]` literal | `sh:176` | OK |
| §3.3 `Get-ShI6BannedRecords` no bash shell-out | `ps1:166-200` pure PS text walk | OK |
| §3.3 step 4 backtick-decode | `ps1:182` `-replace '\\`', '`'` | OK |
| §3.3 step 5 fail-closed on length ≠ 4 | `ps1:187-189` throws with entry# + raw line | OK |
| §3.4 `extract_ps_banned_records` literal-keyword-anchored sed | `sh:327-360` per-field sed | OK |
| §3.5 canonical lists hard-coded per driver (Q-4 a) | `ps1:70-78` / `sh:85-93` | OK |
| §3.5 named entry-count constant | `ps1:81` / `sh:96` | OK |
| §3.6 `Test-I6FileExempt` uses `-ccontains` mandatory | `ps1:126` | OK |
| §3.6 `i6_file_exempt` uses `[[ == ]]` literal | `sh:154` | OK |
| §3.6 combined predicate `Test-I6Exempt` / `i6_exempt` | `ps1:131-134` / `sh:161-164` | OK |
| §8 assertion-name catalog (byte-identical strings) | spot-checked 3a/3b/3c/A7-1..7/A7-N1..3/A7-DIR/A7-FILE-1..7/A7-REG all match | OK |
| §11 step 3 verify_all 30/30 unchanged | live I.6 blocks unchanged; verify_all both shells 30/30 | OK |
| §12 Q-3 honored: only `fx-ac14-nonexempt.md` is physical | confirmed | OK |
| §12 Q-4 honored: canonical lists hard-coded, not shared file | confirmed | OK |
| §13 single-Developer mode | confirmed | OK |
| §9 empirical-equality contract | 56 == 56; 3-run stable; 56 > 35 and 56 > 34 | OK |

## NFR check (NFR-1..NFR-8)

- **NFR-1 PS/Bash symmetry** — spot-checked 4 pairs all symmetric. OK.
- **NFR-2 maintainability (14-entry future)** — 4 edit sites named in design §3.5. OK.
- **NFR-3 zero new false-positive surface** — all lockstep is exact-string element-wise. OK.
- **NFR-4 no L23-class operator-default bug** — m-3 grep audit clean. OK.
- **NFR-5 no L27-class `grep -F -i`** — no new such pattern. OK.
- **NFR-6 no L24 loop-var collision** — new bash loop-vars use `entry`, `xtok`, `tok`, `i`, `exempt_entry`, `nonexempt_entry`; no collision with `failures=()` / `i6_banned=()`. OK.
- **NFR-7 deterministic runtime** — O(1) string compares on loaded data; 3-run stability confirmed. OK.
- **NFR-8 doc-size compliance** — 01 = 559 over soft cap (PM-acknowledged, archive-task at stage 7); 02 = 488 OK; this 05 doc ≤ 200 lines (well under). OK.

## Three most critical findings (highest severity first)

1. **MINOR — `local -n` portability** (`scripts/test-verify-i6.sh:499-500`). Bash 4.3+ floor;
   not blocking on de-facto Windows + Linux target. Recommend a one-line comment naming
   the floor or refactoring to inline expansion. Optional Dev follow-up; non-blocker.
2. **NIT — pre-existing `-notmatch 'WindowsApps'`** (`scripts/test-verify-i6.ps1:468`).
   Outside T-005 diff; flagged for completeness. No action required.
3. **NIT — bare `$banned` in doc-comments** (`ps1:121,203,293`). Harmless (no PS
   interpolation inside `#` comments); cosmetic inconsistency only.

Verdict re-stated: **APPROVED** for QA. The Developer's verification (PASS=56 both shells,
3-run stable, monotonic over baseline, verify_all 30/30) checks out against the code. All
20 ACs have backing code or are properly deferred to QA's stage-6 mutation cycle (AC-20).
