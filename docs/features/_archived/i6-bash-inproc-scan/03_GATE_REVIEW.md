# 03 — Gate Review: i6-bash-inproc-scan (T-017)

- Mode: full
- Reviewer: gate-reviewer
- Date: 2026-06-09
- Upstream verdicts: 01 READY, 02 READY (both confirmed)

## Verification performed (not trusting upstream blindly)

- Read `verify_all.sh` I.6 block (502-601). Confirmed the two retired grep call sites at line 573
  (`grep -E -n -i -m1`) and 592 (`grep -E -i -o -m1`) exactly as the design states.
- Read `test-verify-i6.sh` `i6_scan_file` (114-140). Confirmed the single grep call site at line 122
  and that the function emits ONLY `idx:line_no` (line 138 `printf '%s:%s\n' "$idx" "$line_no"`) —
  it never renders a span, so OQ-2's span cosmetic does NOT touch the driver. Design §6.3 correct.
- Read `verify_all.ps1` I.6 (536-562) to validate the design's R-3 claim. Confirmed: the PS inner
  loop is `Match → if (-not Success) continue → if ($excluded) continue → record → break`. So the
  `break` is reached ONLY on the non-excluded path; after an exclude PS `continue`s to later lines
  (fall-through). The design's CONCLUSION (bash must NOT copy this; keep grep -m1 first-match-stop) is
  correct and constraint-4-compliant. See WARN-1 for a wording nuance.
- Grepped `verify_all.sh` for `=~` / `BASH_REMATCH` / `nocasematch`: already used at lines 463-464
  (`[[ "$line" =~ ^Verdict:...$ ]]` + `BASH_REMATCH[1]`) and 581-589 (existing exclude nocasematch).
  Proves the bash in this environment supports `[[ =~ ]]` ERE + `BASH_REMATCH` + `shopt nocasematch`
  — the engine the design relies on is already exercised by passing checks. R-1/R-2 feasibility
  confirmed.
- Confirmed the generated regex shape from `i6_build_regex` (verify_all.sh:539-547): escaped literal
  tokens joined by `.{0,N}`. No backreferences, no PCRE-only syntax, no lookaround — pure POSIX ERE,
  identically supported by `grep -E` and bash `[[ =~ ]]`. R-1 mitigation sound.
- Confirmed `verify_all.sh` is NOT in the sync-self mirror set (AI-GUIDE.md:72 lists the 7 mirrored
  pairs; verify_all is not among them; it has a `.tmpl` distributed under
  `skills/harness-init/templates/<type>/` but that is a SEPARATE per-type file, not a sync-self
  twin of the dogfood verify_all.sh, and is out of scope here). Constraint-6 "no version/CHANGELOG
  obligation" is correct. See WARN-2 for one thing the Developer must NOT do.

## Audit checklist (8 dimensions)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | 8 in-scope behaviors all testable; ACs map 1:1 to fixtures + live runs; OQ-1/OQ-2 pre-resolved with explicit defaults, no live ambiguity. |
| 2 | Design completeness | PASS | §6.2 + §6.3 give exact drop-in replacement blocks for both files; every in-scope behavior (read-once, first-match, line-scoped exclude, span, report format) is covered with line-anchored pseudo-code. |
| 3 | Reuse correctness | PASS | Reuse audit verified against real lines: `i6_build_regex` (539), nocasematch exclude (584-589), exempt loops (565-568) all exist as cited and are reused verbatim. |
| 4 | Risk coverage | PASS | 6 risks cover the real failure modes: R-2 (unquoted `$rx` false-negative) and R-3 (PS fall-through trap) are the two that would actually bite; both are the highest-value reviewer eyeball targets. No obvious risk missed (see note on R-5 boundary below — already covered). |
| 5 | Migration safety | PASS | Working-tree-only, two files, trivial `git checkout` rollback; no data/version/CHANGELOG. §9 reasoning verified against AI-GUIDE.md:72. |
| 6 | Boundary handling | PASS | empty file (`fx-empty`), no-trailing-newline (most `printf '%s'` fixtures), multi-line split anchors (`fx-multiline`), exclude-suppressed first line (`fx-negation-pre`), gap boundary (`fx-gap-exact`/`fx-gap-over`), CJK/metachar (`fx-e11/12/13`,`fx-meta-*`) — all mapped to existing fixtures that the new engine must keep green. |
| 7 | Test feasibility | PASS | AC-1 (test-verify-i6 positive fixtures), AC-2 (32/0/0), AC-3 (`time` before/after), AC-4 (old-vs-new equivalence harness over `git ls-files`), AC-5/AC-6 (diff scope + no-grep-in-loop) are all mechanically verifiable. AC-4's harness is the one piece QA must BUILD (see Q-3). |
| 8 | Out-of-scope clarity | PASS | §10 is explicit: PS twin untouched, PS post-exclude fall-through deliberately not aligned, no span re-derivation beyond BASH_REMATCH, no other check touched. Low over-build risk. |

## Findings

- **WARN-1 (doc nuance, design §6.1 — NOT blocking).** The design's prose says the PS `break` "is
  reached on BOTH the excluded and non-excluded path." Strictly, PS's `if ($excluded) { continue }`
  means the EXCLUDED path does NOT reach `break` and falls through to later lines; only the
  non-excluded path reaches `break`. The design's actionable pseudo-code (§6.2/§6.3) is nonetheless
  CORRECT — it puts the bash `break` after the matched-line block on BOTH paths, which is exactly the
  grep -m1 behavior constraint 4 demands. So the wording is slightly loose but the implementation
  instruction is right. Not routed back: this does not change any in-scope behavior or AC, and the
  Developer has the correct code to copy. Code Reviewer should simply confirm the bash `break`
  placement matches §6.2 (first-match-then-stop), independent of the §6.1 prose.

- **WARN-2 (constraint reinforcement for Developer — NOT blocking).** There IS a
  `skills/harness-init/templates/<type>/.harness/scripts/verify_all.sh.tmpl` (the distributed
  per-project verify_all). It is NOT a sync-self twin and NOT in scope. The Developer MUST touch ONLY
  the dogfood `.harness/scripts/verify_all.sh` (and `test-verify-i6.sh`), never the `.tmpl`. AC-5
  (diff confined to the two files) catches a slip. Recorded so the Developer does not "helpfully"
  port the change into the template.

## High-probability developer questions (pre-answered)

- **Q-1: Should `shopt -s nocasematch` be set per-line or once around the line loop?** Either (design
  §6.4 (A) or (B)). Hard requirement: it must cover BOTH the `[[ =~ ]]` match and the `[[ == *x* ]]`
  exclude, and must be `shopt -u` before control leaves the per-entry scan so it never leaks into
  J.1 / other checks. Reviewer will grep for balanced set/unset.

- **Q-2: Must `$rx` be unquoted in `[[ "$line" =~ $rx ]]`?** YES — unquoted so it is a regex.
  Quoting it makes it a literal string and silently breaks ALL matching (R-2 false-negative). This is
  the single most dangerous line; the positive fixtures (AC-1) fail loudly if it is wrong.

- **Q-3: Where does the AC-4 equivalence harness live / does it ship?** It is a QA verification
  artifact, NOT a shipped file. QA writes a throwaway script (or inline command) that runs the OLD
  grep logic and the NEW in-memory logic over the same `git ls-files` set and diffs the hit lists.
  It does not get committed and is not part of the two-file diff (AC-5). Both hit sets are expected
  empty on the clean tree; QA must still build it so a future non-empty tree is covered.

- **Q-4: Does `mapfile` exist on the MSYS bash here?** Yes — `mapfile`/`readarray` is a bash 4+
  builtin; the Git-for-Windows bash is 4.4+/5.x. (The driver already uses `mapfile`-class array reads
  elsewhere via `read -a`; `mapfile -t` is standard.) If a paranoid fallback is wanted, a
  `while IFS= read -r` loop with a final-line guard is equivalent — but `mapfile -t` is fine and
  simpler. Developer may use `mapfile -t`.

- **Q-5: Will the cosmetic span difference (BASH_REMATCH leftmost vs grep -o leftmost-longest) break
  any assertion?** Not in `i6_scan_file` (it emits no span). In `verify_all.sh` it only affects FAIL
  report text, and the tree has zero hits. QA confirms no fixture asserts span text (per OQ-2).

## Verdict

**APPROVED.**

The design is implementable as-is. WARN-1 and WARN-2 are documentation/constraint-reinforcement
notes, not defects in the actionable design — neither requires routing back to RA or SA. The two
real hazards (R-2 unquoted `$rx`, R-3 PS-port fall-through trap) are explicitly flagged for the Code
Reviewer's eyeball, and the positive-fixture ACs make a false-negative regression fail loudly.
Development may proceed.
