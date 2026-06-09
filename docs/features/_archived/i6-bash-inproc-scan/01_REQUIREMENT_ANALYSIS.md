# 01 — Requirement Analysis: i6-bash-inproc-scan (T-017)

- Mode: full
- Author: requirement-analyst
- Date: 2026-06-09

## 1. Goal

Replace the per-(tracked-file × banned-entry) `grep`-subprocess scan engine in the bash
`verify_all.sh` I.6 retired-claim guard with an in-process line-scan engine semantically identical
to the already-fast PowerShell twin, eliminating the ~9,000-process MSYS spawn storm, while
preserving every I.6 behavior and the four-file lockstep.

## 2. In-scope behaviors (numbered, testable)

1. `verify_all.sh` I.6 reads each non-exempt tracked file's content into memory exactly once per
   file (not once per banned entry).
2. For each banned entry, I.6 tests the file's lines in source order using a bash-native
   case-insensitive regex match (`shopt -s nocasematch` + `[[ "$line" =~ $rx ]]`) against the
   regex produced by the existing `i6_build_regex` (unchanged ERE with `.{0,gap}` gaps).
3. On the FIRST line where the regex matches, I.6 applies the existing line-scoped exclude test
   (case-insensitive literal substring over the WHOLE matched line). If excluded, the entry
   produces NO hit and the scan for that entry STOPS (does not fall through to a later line) —
   preserving the current `grep -m1` first-match-wins semantics.
4. When the first matching line is not excluded, I.6 records a hit using the 1-based line index as
   `line_no` and `${BASH_REMATCH[0]}` as the matched span, truncated to 120 chars, in the exact
   existing report format: `file:lineNo : [anchors] — reason | matched: "span"`.
5. I.6 spawns ZERO `grep` (or other external) processes inside the per-file / per-entry scan loop.
   (External calls outside the scan loop — `git ls-files`, `sed` inside `i6_build_regex` — are out
   of scope and unchanged.)
6. `test-verify-i6.sh`'s self-contained `i6_scan_file` function is migrated to the identical
   in-process engine (same read-once + per-entry line scan + first-match + line-scoped exclude),
   so the regression exercises the NEW engine, not the retired grep engine.
7. The set of files exempted (`i6_exempt_files`, `i6_exempt_dirs`) and the skip order are unchanged.
8. The bash I.6 hit set over the live `git ls-files` tree is identical to the hit set the
   pre-change grep engine produced (currently: empty on the clean tree).

## 3. Out-of-scope (explicitly NOT done this iteration)

- Any edit to `.harness/scripts/verify_all.ps1` or `.harness/scripts/test-verify-i6.ps1`. They are
  already in-process; pwsh is execution-blocked here (deny rule) so PS edits would be unverifiable.
- Any change to the `i6_banned` list contents, the exempt lists, `i6_gap_default`, `i6_build_regex`,
  the exclude semantics, the report-line format string, or `i6_expected_entry_count` /
  `$script:I6ExpectedEntryCount` (data, not engine).
- Any other verify_all check (J.1, I.1-I.5, I.7, G.*, etc.).
- Any version bump, CHANGELOG entry, git commit, or git push.
- Performance work on any other dogfood script.

## 4. Boundary conditions

- **Empty file**: a tracked file with zero lines must produce no hit and no error. (`mapfile`/loop
  over an empty file iterates zero times.)
- **File with no trailing newline**: the final line must still be scanned. (The current
  `grep -n` reads it; the in-memory engine must too — `mapfile -t` captures a final no-newline line.)
- **Multi-line file where anchors are split across two lines**: must NOT hit (single-line scan
  semantics — the `.` in the ERE does not cross a newline because each line is matched
  independently). This already holds for both grep `-n` (line-oriented) and the PS twin
  (split-then-per-line); the bash port must preserve it. Fixture `fx-multiline.md` covers this.
- **First matching line is exclude-suppressed**: entry yields no hit; scan does NOT continue to a
  later matching line (constraint 4 / in-scope #3). Fixture `fx-negation-pre.md` covers the
  exclude path.
- **Regex metacharacters / backtick / arrow / CJK in anchors**: `i6_build_regex` already escapes
  metacharacters and is reused verbatim; `[[ =~ ]]` with the same ERE must scan without stderr.
  Fixtures `fx-meta-backtick.md`, `fx-meta-arrow.md`, `fx-e11/e12/e13.md` cover this.
- **Gap boundary**: exactly-`gap` chars between anchors HITs; `gap+1` does NOT. The ERE is unchanged,
  so `[[ =~ ]]` must reproduce the grep `-E` boundary exactly. Fixtures `fx-gap-exact.md` (HIT) /
  `fx-gap-over.md` (no hit) cover this.
- **Span text cosmetic difference**: `${BASH_REMATCH[0]}` is leftmost (POSIX ERE leftmost match),
  whereas `grep -o` is leftmost-LONGEST. The `matched: "span"` text in a FAIL line could differ in
  length between old and new engines. This is cosmetic (the report contract is the format, not the
  exact span length) and irrelevant while the tree has zero hits. See OQ-2.

## 5. Acceptance criteria (each verifiable)

- **AC-1** `bash .harness/scripts/test-verify-i6.sh` exits 0 with all assertions PASS, INCLUDING the
  positive-fixture hit assertions (Assertion 1 entries with a numeric `fx_expect`, Assertion 5 gap
  HIT, Assertion 7.5 AC-14 non-exempt HIT) — proving the new engine still CATCHES retired claims.
- **AC-2** `bash .harness/scripts/verify_all.sh` reports 32 PASS / 0 WARN / 0 FAIL.
- **AC-3** Measured wall-clock of `bash .harness/scripts/verify_all.sh` after the change is
  dramatically lower than before; I.6's contribution drops from minutes to seconds. (Captured via
  `time` before and after.)
- **AC-4** An equivalence harness running the OLD grep-based I.6 logic and the NEW in-process logic
  over the identical live `git ls-files` set yields IDENTICAL hit sets (both empty on the clean
  tree). Any divergence is a blocking failure.
- **AC-5** `git diff --stat` shows changes confined to `.harness/scripts/verify_all.sh` and
  `.harness/scripts/test-verify-i6.sh` only.
- **AC-6** No `grep` (or other external command) invocation remains inside the I.6 per-file scan
  loop in `verify_all.sh`, nor inside `i6_scan_file` in `test-verify-i6.sh`. (Verified by reading the
  diff; the two retired call sites are verify_all.sh:573 and :592, and test-verify-i6.sh:122.)

## 6. Non-functional requirements

- **NFR-1 (cross-shell parity)** Rule 30/20: PS and bash scripts are symmetric. This change INCREASES
  parity — the bash engine converges onto the PS twin's already-in-process structure (read-raw →
  per-line `Match` → first-success → line-scoped exclude → record + break). The four-file I.6
  lockstep (banned list + exempt lists mirrored across both verify_all and both test drivers, insight
  L34) must remain intact: this is an engine change with ZERO data change, so all mirrored arrays and
  `I6ExpectedEntryCount`=14 stay byte-identical. The existing Assertion 2 (cross-shell parity) and
  Assertion 3 (structural lockstep) in `test-verify-i6.sh` must continue to PASS unchanged. Note:
  Assertion 2 SKIPs when pwsh is unavailable (it is, here) — that is acceptable and pre-existing.
- **NFR-2 (no new dependency)** The in-process engine uses only bash builtins (`mapfile`/`read`,
  `[[ =~ ]]`, `shopt nocasematch`, `BASH_REMATCH`). No python/jq/grep — consistent with verify_all's
  MSYS-portable, dependency-free posture.
- **NFR-3 (MSYS safety)** Insight L22: MSYS GNU grep 3.0 SIGABRTs on `-F -i`; the current I.6 uses
  `-E -i` so the slowness is process-COUNT, not the abort bug. The replacement removes the spawns
  entirely, which also removes any residual MSYS-grep exposure in the scan loop.

## 7. Related tasks

- **T-004** (`docs/features/_archived/i6-semantic-guard/`) — created the gap-tolerant I.6 engine
  (v0.18.0). Insight L22 (MSYS grep `-F -i` abort; use `shopt nocasematch` + `[[ ]]`) and L23
  (rely on verify_all as the canonical exhaustive scan) originate here. The exclude path already
  uses `shopt -s nocasematch` — this task extends that bash-native approach to the main match too.
- **T-005** (`docs/features/_archived/i6-test-hardening/`, v0.18.1) — hardened the four-file lockstep
  matrix in `test-verify-i6.{ps1,sh}`; defines `i6_scan_file`, the fixture corpus, and the lockstep
  assertions this task must keep green.
- **T-013** (`docs/features/_archived/lang-policy-split/`, v0.24.0) — established insight L34 (I.6 is a
  FOUR-file lockstep; `I6ExpectedEntryCount` bumps only on banned-list add/remove). Confirms this
  engine-only change must NOT touch the count.
- **T-010** (`docs/features/_archived/g4-version-decouple/`) — its delivery note explicitly flagged a
  "pre-existing I.6 MSYS wedge" on bash; this task resolves the root cause of that wedge.

## 8. Open questions for user

- **OQ-1 — Rule-30 symmetry vs HARD CONSTRAINT 2.** Rule 30 says "if you change one shell script,
  change the other." HARD CONSTRAINT 2 forbids touching the PS twin.
  - (a) Treat the constraint as authoritative: the PS twin is ALREADY in-process, so leaving it
    unchanged makes the two shells converge (more symmetric), and pwsh is unverifiable here.
  - (b) Also touch the PS twin for "symmetry."
  Analyst reading: (a). The user briefing pre-resolves this — the symmetry rule's intent (behavioral
  equivalence) is SATISFIED by porting bash onto the PS structure, not violated. No code reason to
  touch PS. **Default (a); flag for confirmation only because a rule is nominally in tension.**

- **OQ-2 — Span-text cosmetic divergence.** `${BASH_REMATCH[0]}` (leftmost) vs `grep -o`
  (leftmost-longest) can change the `matched: "span"` length in a FAIL report.
  - (a) Accept the cosmetic difference (tree has zero hits; `test-verify-i6` asserts hit
    indices/identities, not span text — to be confirmed by QA reading the fixtures).
  - (b) Re-derive a leftmost-longest span to byte-match grep -o output.
  Analyst reading: (a), CONTINGENT on QA confirming no fixture asserts span text. The user briefing
  states the same and instructs QA to verify. **Default (a); QA gates the contingency.**

## 9. Verdict

**READY.**

OQ-1 and OQ-2 are both pre-resolved by the user's own briefing (which supplies the (a) answers as
the intended design and assigns QA the span-text confirmation). They are recorded for traceability,
not as blockers — neither requires a user decision to proceed, and choosing otherwise would
contradict the explicit task constraints. No genuine ambiguity remains that would change the
in-scope behaviors or acceptance criteria.
