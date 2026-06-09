# Delivery — i6-bash-inproc-scan (T-017)

- Date: 2026-06-09
- Status: **DELIVERED**
- Final verify_all result: PASS (32/0/0, 44.5s)

## What shipped

`verify_all.sh`'s I.6 retired-claim guard no longer spawns a `grep` per (file × banned-entry) and no
longer rebuilds each entry's regex per file. It now (1) builds the 14 regexes + fields **once** before
the file loop, and (2) reads each non-exempt file once into memory and scans lines in-process with
`[[ =~ ]]` under `nocasematch` — mirroring the already-fast PowerShell twin. `test-verify-i6.sh`'s
`i6_scan_file` is migrated to the same in-process engine (lockstep).

Net effect: `verify_all.sh` on Windows/MSYS drops from ~9-12 min to **44.5s** (~12-16×), with no
behavior change. This was a correctness-preserving performance fix to the gate — no banned/exempt data,
gap, exclude semantics, report contract, or check count (still 32) changed; the PowerShell twin was
left untouched (already in-process).

## Files changed

- `.harness/scripts/verify_all.sh` — I.6: hoist the per-entry regex build out of the file loop
  (`i6_rx_a[]` + field arrays); index into them in the loop; read-once `mapfile` + per-line `[[ =~ ]]`
  scan (Developer); `${BASH_REMATCH[0]}` span; grep call sites removed.
- `.harness/scripts/test-verify-i6.sh` — `i6_scan_file` migrated to the identical in-process engine.

## Verification

- `test-verify-i6.sh`: **58/58 PASS** (positive banned-phrase fixtures ⇒ no false-negative; cross-shell
  bash↔PS parity actively passed; structural lockstep intact).
- `verify_all.sh`: **32 PASS / 0 WARN / 0 FAIL** in **44.5s** (before: 12m13s / ~9 min, captured).
- Equivalence: by-construction (regex is a pure function of its entry) + empirically via the fixtures.

Not committed by the pipeline — handed to the operator, who committed/pushed (per the standing
"all commits/pushes by the operator" instruction).

## Insight

- 2026-06-09 · The I.6 guard's pathological slowness on Windows/MSYS (~9-12 min verify_all) was dominated by `i6_build_regex` being rebuilt per (file × entry) ≈ 4.6k times — each call forks `sed` per anchor token (~30k forks) — NOT by the grep-scan spawns the T-017 design / Gate / Dev all assumed (sub-agents had no Bash, so nobody profiled). The grep→`[[ =~ ]]` engine swap alone left it at 12m13s; **hoisting the 14 regex builds out of the file loop** is what dropped it to 44.5s (measured: 4.6k rebuilds did not finish in 9 min; 14 hoisted builds = 3.2s; in-process scan over the tree = 29s). Lesson: profile the real bottleneck before optimizing a perf wart — here the named suspect (process spawns from grep) was a red herring for the actual suspect (process spawns from a hot helper's `sed` in a `$(...)`). · evidence: T-017, verify_all.sh I.6 hoist + benchmarks T1/T2, test-verify-i6 58/58, verify_all 44.5s
