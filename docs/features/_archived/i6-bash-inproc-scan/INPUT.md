# Task Input — i6-bash-inproc-scan (T-017)

Mode: **full** (7-stage pipeline)

## Problem
The bash I.6 "retired-claim guard" in `.harness/scripts/verify_all.sh` is pathologically slow on
Windows/MSYS. The current implementation spawns up to TWO `grep` processes per
(tracked-file × banned-entry): ~330 files × 14 entries × ≈2 greps ≈ 9,000 process spawns at ~50ms
each. I.6 alone takes ~4+ minutes; the whole `verify_all.sh` takes ~9 minutes on this box. (It is
NOT hung — just slow; measured this session.)

## The fix (faithful cross-shell port — the key insight)
The PowerShell twin `.harness/scripts/verify_all.ps1` I.6 (lines ~536-562) is ALREADY in-process
and fast: it does `Get-Content -Raw` once per file, splits into lines in memory, and runs
`[regex]::new(pattern, IgnoreCase).Match($line)` per banned entry per line, first-success-then-break,
with a line-scoped `IndexOf` exclude test. Port THAT SAME STRUCTURE to bash:
- read each non-exempt file once (`mapfile -t lines < "$file"`),
- for each banned entry test the lines in order with `shopt -s nocasematch` + `[[ "$line" =~ $rx ]]`,
  REUSING the existing `i6_build_regex` output verbatim (same `.{0,gap}` ERE),
- on the first regex-matching line, run the existing line-scoped nocasematch exclude test; if not
  excluded, record the hit using the line index as line_no and `${BASH_REMATCH[0]}` as the span
  (replacing the second `grep -o`).

After the rewrite, bash mirrors the proven PS reference and the grep-spawn storm is gone.

## HARD CONSTRAINTS
1. Touch ONLY `.harness/scripts/verify_all.sh` (the I.6 block, ~lines 502-601) AND
   `.harness/scripts/test-verify-i6.sh` (its self-contained `i6_scan_file` / scan loop).
2. Do NOT touch `.harness/scripts/verify_all.ps1` or `.harness/scripts/test-verify-i6.ps1`. They are
   already in-process and fast. PowerShell CANNOT be executed here (a deny rule blocks pwsh), so any
   PS edit would be unverifiable; leaving them unchanged also preserves cross-shell parity (both
   shells end up in-process with identical semantics).
3. Pure engine swap only. Do NOT change: the `i6_banned` list, the `i6_exempt_files`/`i6_exempt_dirs`
   lists, the gap defaults, `i6_build_regex`, the exclude semantics, or the
   `file:lineNo : [...] — reason | matched: "span"` reporting contract. Do NOT change
   `test-verify-i6`'s `I6ExpectedEntryCount` or its array-mirroring assertions (the four-file
   lockstep stays intact — you change the scan ENGINE, not the data).
4. Preserve `grep -m1` semantics exactly: stop at the FIRST regex-matching line and, if that first
   line is exclude-suppressed, do NOT fall through to a later line (matches current bash behavior).
5. Lockstep: `test-verify-i6.sh` declares its OWN copy of the scan logic; migrate it to the identical
   new in-memory engine, otherwise the regression keeps exercising the OLD grep engine and proves
   nothing about the new path.
6. Do NOT git commit or push, and do NOT bump the version. Leave the change in the working tree with
   a green gate. This is a script-internal perf change: it does not alter the check count (still 32),
   any version/count claim, or any shipped template (verify_all.sh is not in sync-self's mirror set).
   Confirm no CHANGELOG/version obligation actually applies; if you find one, surface it rather than
   acting.

## Required verification evidence (QA must produce, all from real captured runs)
- `bash .harness/scripts/test-verify-i6.sh` passes — its POSITIVE fixtures (files that DO contain
  banned phrases) are the critical proof the new engine still CATCHES retired claims (no false
  negative). This is the single most important check.
- `bash .harness/scripts/verify_all.sh` = 32 PASS / 0 WARN / 0 FAIL, and demonstrably faster —
  capture wall-clock before/after (`time`), expect I.6 to drop from minutes to seconds. A full
  verify_all.sh run currently takes ~9 min; allow up to the 600000ms Bash timeout and do not mistake
  slowness for a hang.
- Equivalence proof on the real tree: run the OLD grep-based I.6 logic and the NEW in-memory I.6
  logic over the actual `git ls-files` set and assert IDENTICAL hit sets (both empty on the current
  clean tree). Treat any divergence as a blocking failure to investigate, not to paper over.
- Known COSMETIC difference: `${BASH_REMATCH[0]}` is leftmost (not grep -o's leftmost-longest), so
  the `matched: "span"` TEXT in a FAIL message could differ in length. Irrelevant while there are
  zero hits; `test-verify-i6` asserts hit indices/identities, not span text — QA should confirm the
  fixtures don't assert span text (and if any does, adjust the engine to preserve it or update the
  fixture with justification).

## Required return
Final verdict (DELIVERED / BLOCKED / FAILED), path to `07_DELIVERY.md`, files changed, before/after
`verify_all.sh` wall-clock timing, `test-verify-i6.sh` result, and the equivalence-diff result.
Do not declare done until `verify_all` PASSes and `test-verify-i6.sh` passes.
