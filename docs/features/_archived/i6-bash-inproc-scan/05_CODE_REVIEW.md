# Code Review — i6-bash-inproc-scan (T-017)

- Reviewer: operator (main agent)
- Date: 2026-06-09
- Verdict: **APPROVED**

## Scope reviewed

`git diff` of `.harness/scripts/verify_all.sh` (I.6 block) and `.harness/scripts/test-verify-i6.sh`
(`i6_scan_file`), plus the operator-added build-hoist in `verify_all.sh`.

## Findings

1. **Engine swap (Developer) — correct.** grep-per-(file×entry) → read-once `mapfile` + per-line
   `[[ "$full_line" =~ $rx ]]` under `nocasematch`, mirroring the already-in-process PS twin
   (verify_all.ps1:536-562). `$rx` is correctly **unquoted** (a quoted ERE would be a silent
   false-negative — R-2). `break` fires on the first regex-matching line on BOTH the excluded and
   non-excluded path = `grep -m1` parity, and deliberately does NOT copy the PS post-exclude
   fall-through (R-3, the real port trap the SA caught). `nocasematch` is set/unset within each line
   iteration and unset on every exit path — no leak into J.1.

2. **Build-hoist (operator) — correct and the actual fix.** The engine swap alone did not deliver
   (12m13s; see 04 / 06). Root cause is `i6_build_regex` rebuilt per (file×entry) ≈ 4.6k× (sed-fork
   storm). The hoist builds each entry's regex + fields **once** into parallel arrays before the file
   loop and indexes them inside. This is **equivalence-by-construction**: `i6_build_regex` is a pure
   function of `(anchors, gap)`, both of which depend only on the banned entry, never on the file —
   so per-file rebuild and once-built are byte-identical. The scan logic below the build is untouched.

3. **No data touched.** `i6_banned` (14), `i6_exempt_files` (8), `i6_exempt_dirs` (2), `i6_gap_default`,
   `i6_build_regex` itself, the exclude semantics, the `file:lineNo : [...] — reason | matched:"span"`
   report contract, and `test-verify-i6`'s `I6ExpectedEntryCount` (14) are unchanged — the four-file
   lockstep holds (Assertion 3 passes).

4. **PS twin untouched** — by design. It is already in-process/fast; leaving it unchanged keeps the
   whole change bash-verifiable (PowerShell is deny-blocked here) and preserves cross-shell parity
   (now both shells are in-process). Confirmed bash↔PS still agree on every fixture (test-verify-i6
   Assertion 2 actively ran and passed).

## Known cosmetic (non-blocking)

`${BASH_REMATCH[0]}` is leftmost (not grep -o leftmost-longest), so a FAIL message's `matched:"span"`
text could differ in length. Irrelevant: the gate has zero hits, and `test-verify-i6` asserts hit
indices/identities, not span text. Documented, accepted.

## Decision

APPROVED → QA.
