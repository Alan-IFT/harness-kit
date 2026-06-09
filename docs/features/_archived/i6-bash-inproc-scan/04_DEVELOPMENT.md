# Development Record — i6-bash-inproc-scan (T-017)

- Mode: full
- Author: developer
- Date: 2026-06-09

## Summary

Implemented the approved design (§6.2 / §6.3) exactly: swapped the bash I.6 retired-claim scan engine
in `verify_all.sh` and the self-contained `i6_scan_file` in `test-verify-i6.sh` from a
grep-subprocess-per-(file×entry) design to an in-process read-once / per-line `[[ =~ ]]` scan under
`shopt -s nocasematch`, mirroring the already-fast PowerShell twin. The two grep call sites in
`verify_all.sh` (the `grep -E -n -i -m1` match and the `grep -E -i -o -m1` span) and the one in
`i6_scan_file` are gone. **No data changed** — `i6_banned` (14), `i6_exempt_files` (8),
`i6_exempt_dirs` (2), `i6_gap_default` (40), `i6_build_regex`, the exclude semantics, the report
contract, and `i6_expected_entry_count` (14) are byte-untouched.

## Files changed

- `.harness/scripts/verify_all.sh` — I.6 per-file scan loop: read each non-exempt file once via
  `mapfile -t i6_lines`, then per banned entry scan the lines in order; first regex-matching line wins
  (`break` after the matched-line block on both excluded and non-excluded paths = grep -m1 parity);
  span via `${BASH_REMATCH[0]}`; `$rx` unquoted in `[[ "$full_line" =~ $rx ]]`; `nocasematch` set
  before the match and unset on every exit path (no leak into J.1 / later checks).
- `.harness/scripts/test-verify-i6.sh` — `i6_scan_file` migrated to the identical in-process engine
  (lockstep, constraint 5). Emits `idx:line_no` exactly as before; span never rendered here.

## Design adherence / drift

- No DESIGN DRIFT. Implemented §6.2 and §6.3 verbatim, including R-3 (do NOT copy the PS post-exclude
  fall-through — bash `break`s after the first regex-matching line regardless of exclude outcome) and
  R-2 (`$rx` unquoted). Used design §6.4 scoping (A): `nocasematch` set/unset inside each line
  iteration, unset on both the matched-line exit and the bottom-of-loop non-match exit.
- nocasematch balance audited by reading the edited blocks: every `shopt -s nocasematch` has a
  matching `shopt -u nocasematch` on the path that follows it (matched-line branch unsets before the
  `(( excluded ))` decision; non-matching iteration unsets at loop bottom).

## verify_all result

**BLOCKED ON CAPABILITY — verification could not be executed in this environment.**

- The Bash tool is NOT available in this dispatch context (every invocation returns "No such tool
  available: Bash"). PowerShell is likewise unavailable (and is deny-blocked per the task briefing).
- Therefore the mandatory runs — `bash .harness/scripts/verify_all.sh` (AC-2, 32/0/0),
  `bash .harness/scripts/test-verify-i6.sh` (AC-1, the critical positive-fixture proof), the
  before/after `time` capture (AC-3), and the OLD-vs-NEW equivalence harness over `git ls-files`
  (AC-4) — COULD NOT be run.
- Per Developer hard rule 3 ("run verify_all before declaring done — no exceptions") and the
  insight-index discipline (L27 / T-007: pass/fail numbers MUST be pasted from a captured run, never
  fabricated), I am NOT declaring this verified. The code is written; the proof is not obtainable
  here.
- Baseline timing capture (the "before" wall-clock) was also blocked — the baseline run requires the
  same unavailable Bash tool, and it had to be captured BEFORE the edit, which was impossible.

## Open issues for review (for Code Reviewer + QA when an executor is available)

1. **R-2 eyeball**: confirm `$rx` is unquoted in both `[[ "$full_line" =~ $rx ]]` sites
   (verify_all.sh + test-verify-i6.sh). A quoted `$rx` is a silent false-negative.
2. **R-3 eyeball**: confirm the inner line loop `break`s after the FIRST regex-matching line on BOTH
   the excluded and non-excluded path (grep -m1 parity; no fall-through to a later line).
3. **R-4 eyeball**: confirm `shopt -s nocasematch` / `shopt -u nocasematch` are balanced on every
   exit path and nocasematch does not leak past the I.6 block.
4. **AC-1 (critical)**: `bash .harness/scripts/test-verify-i6.sh` must pass — its positive fixtures
   (numeric `fx_expect`, gap HIT, AC-14 non-exempt) prove the new engine still CATCHES retired claims.
5. **AC-4 equivalence**: old-grep vs new-in-process hit sets over `git ls-files` must be identical
   (both empty on the clean tree).
6. **AC-2/AC-3**: full `verify_all.sh` 32/0/0 and dramatically faster I.6 (`time` before/after).

## Dev-map updates

None — no files added/moved/removed, no structural change. The dev-map's "verify_all (32 checks)" and
script inventory remain accurate (engine-internal change, no check count change).

## Insight to surface (optional)

- 2026-06-09 · The Claude-Code-SDK PM-orchestrator dispatch context in this environment exposes ONLY
  read/write/search tools (Read/Write/Edit/Glob/Grep) — NOT Bash or PowerShell — so a task whose
  acceptance is gated on "real captured `verify_all` runs" cannot be self-verified by the dispatched
  Developer/QA roles here; the code can be authored but execution must be handed to an environment with
  a shell. Surface as BLOCKED ON CAPABILITY rather than fabricate run results (per L27 / T-007). ·
  evidence: T-017, Bash tool returns "No such tool available" at the Developer stage
- 2026-06-09 · The bash I.6 grep-per-(file×entry) engine was the root cause of the "pre-existing I.6
  MSYS wedge" flagged at T-010 delivery: it is process-COUNT (~9k spawns), not the L22 `grep -F -i`
  SIGABRT — I.6 already used `-E -i`. The fix is an in-process `mapfile` + `[[ =~ ]]` + `nocasematch`
  scan mirroring the PS twin, reusing `i6_build_regex`'s ERE verbatim. · evidence: T-017,
  verify_all.sh I.6 (post-edit)

## Verdict

**BLOCKED ON CAPABILITY** — code implemented per approved design; mandatory verification (verify_all,
test-verify-i6, before/after timing, equivalence harness) cannot be executed because no shell tool
(Bash/PowerShell) is available in this dispatch environment. Escalating to PM. NOT "READY FOR REVIEW"
in the normal sense, because the design's own ACs require captured runs that cannot be produced here.

## Operator completion (2026-06-09, main agent — has Bash)

The PM correctly handed verification back to the operator (sub-agents have no shell). On running it,
the engine-swap was confirmed CORRECT but did **not** meet AC-3 (faster): full `verify_all.sh` took
**12m13s** — no better than the ~9-min baseline. Profiling revealed the design's root-cause hypothesis
(~9k grep-scan spawns) was a **red herring**: the dominant cost is `i6_build_regex` being rebuilt
per (file × entry) ≈ 4.6k times, each forking `sed` per anchor token (~30k forks). Measured: 4.6k
rebuilds did not finish in 9 min; building the 14 regexes **once** takes 3.2s (T1); in-process scan
over the whole tree is 29s (T2).

Fix added by operator (provably equivalent — a regex is a pure function of its entry): **hoist the
14 `i6_build_regex` calls out of the file loop** into `i6_rx_a[]` (+ `i6_anchors_a/reason_a/exclude_a`),
and index into them inside the loop. The Developer's bash in-process scan is kept (it beats hoisted
grep: 29s vs ~4min of grep spawns). No semantics changed. Result: `verify_all.sh` = 32/0/0 in **44.5s**
(~12-16× faster); `test-verify-i6.sh` = 58/58 (incl. cross-shell parity bash-vs-PS + positive
banned-phrase fixtures = no false-negative). See 05 / 06 / 07.

**Verdict: COMPLETE (operator-verified).**
