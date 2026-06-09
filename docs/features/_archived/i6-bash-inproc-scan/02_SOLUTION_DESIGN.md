# 02 — Solution Design: i6-bash-inproc-scan (T-017)

- Mode: full
- Author: solution-architect
- Date: 2026-06-09
- Upstream: 01_REQUIREMENT_ANALYSIS.md verdict READY (confirmed)

## 1. Architecture summary

Swap the bash I.6 scan engine in `verify_all.sh` from a grep-subprocess-per-(file×entry) design to
a read-once / in-memory line-scan design that is structurally identical to the existing PowerShell
twin. The banned/exempt data, the `i6_build_regex` ERE, the exclude semantics, and the report
contract are untouched — only the matching mechanism changes (external `grep` → bash builtins
`mapfile` + `[[ =~ ]]` under `shopt -s nocasematch`). The same engine is mirrored into
`test-verify-i6.sh`'s self-contained `i6_scan_file` so the regression exercises the new path. No PS
file is touched; the change makes the two shells MORE symmetric.

## 2. Affected modules

| File | Change |
|---|---|
| `.harness/scripts/verify_all.sh` | I.6 per-file scan loop (lines 563-595): replace inner grep-based match+span with read-once in-memory line scan. |
| `.harness/scripts/test-verify-i6.sh` | `i6_scan_file` (lines 114-140): replace the single grep match with the identical in-memory line scan. |

No other file changes. `verify_all.ps1` / `test-verify-i6.ps1` are the unchanged reference; their
structure (verify_all.ps1 lines ~536-562) is the port target.

## 3. Module decomposition

No new modules, no new functions. `i6_build_regex` is reused verbatim as the regex source. The
change is entirely within two existing scan loops. (Pseudo-code in §6.)

## 4. Data model changes

None. `i6_banned` (14 entries), `i6_exempt_files` (8), `i6_exempt_dirs` (2), `i6_gap_default` (40),
and `i6_expected_entry_count` (14) are byte-unchanged. The four-file lockstep stays intact.

## 5. API / contract

The I.6 OUTPUT contract is unchanged:
- Hit report line (per hit): `${scan_file}:${line_no} : [${e_anchors}] — ${e_reason} | matched: "${span:0:120}"`
- Step verdict: PASS when no hits, FAIL with the joined hit list when any hit.
- `i6_scan_file` (test driver) contract: one `idx:line_no` line per banned entry that hits
  (idx = 1-based into i6_banned), empty output = no hit. Span is NOT emitted by `i6_scan_file`,
  so the cosmetic span difference (OQ-2) does not affect the driver's output at all.

## 6. Flow / engine design (the exact port)

### 6.1 PowerShell reference (verify_all.ps1, what we are mirroring)

```
$content = Get-Content -LiteralPath $file -Raw            # read once
$lines = $content -split "`r?`n"
foreach ($b in $banned) {
    $rx = [regex]::new((Build-I6Regex $b.anchors $gap), IgnoreCase)
    $lineNo = 0
    foreach ($line in $lines) {
        $lineNo++
        $m = $rx.Match($line); if (-not $m.Success) { continue }   # first match wins
        # line-scoped exclude over WHOLE line:
        $excluded = $false
        foreach ($x in $b.exclude) { if ($line.IndexOf($x, OrdinalIgnoreCase) -ge 0) { $excluded=$true; break } }
        if ($excluded) { continue }                                # excluded → keep scanning? NO:
        $span = $m.Value (≤120)
        $hits += "...$span..."
        break                                                      # <-- break is OUTSIDE the if
    }
}
```

**CRITICAL semantics note (constraint 4 / RA in-scope #3):** in the PS twin the `break` is the LAST
statement of the matching-line block and is reached on BOTH the excluded and non-excluded path —
when `$excluded` is true the code `continue`s the inner foreach... which means PS DOES keep scanning
later lines after an exclude. **The current BASH engine does NOT** — `grep -m1` returns the first
regex-matching line and the exclude test is applied only to THAT line; if excluded, the entry yields
no hit and never looks at a later line. **The bash port must preserve the BASH behavior (constraint
4 is explicit: "do NOT fall through to a later line"), NOT copy PS's fall-through.** This is the one
place where a literal PS port would be WRONG. See Risk R-3 — the bash port keeps grep -m1 semantics:
the inner line loop `break`s after the FIRST regex-matching line regardless of exclude outcome.

> Note for downstream: this divergence is pre-existing and intentional; the fixture corpus only
> exercises single-line files for every exclude case (`fx-negation-pre.md`, `fx-arrow-accurate.md`,
> `fx-historical.md` is two-line but its anchors land beyond the gap so it never matches), so PS and
> bash agree on every fixture today (Assertion 2 parity is green when pwsh is present). The bash port
> must not change bash's first-match-then-stop behavior; doing so is out of scope.

### 6.2 Bash port — `verify_all.sh` I.6 inner block (replaces lines 563-595)

Read each non-exempt file ONCE into an array, then per entry scan the array. Exact pseudo-code:

```bash
i6_hits=""
while IFS= read -r scan_file; do
    skip=0
    for ex in "${i6_exempt_files[@]}"; do [[ "$scan_file" == "$ex" ]] && { skip=1; break; }; done
    (( skip == 1 )) && continue
    for ed in "${i6_exempt_dirs[@]}"; do [[ "$scan_file" == "$ed"* ]] && { skip=1; break; }; done
    (( skip == 1 )) && continue
    [[ -f "$scan_file" ]] || continue

    # --- read the file ONCE into memory (was: 14×2 greps per file) ---
    i6_lines=()
    mapfile -t i6_lines < "$scan_file" 2>/dev/null

    for entry in "${i6_banned[@]}"; do
        IFS='|' read -r e_anchors e_reason e_exclude e_gap <<< "$entry"
        rx=$(i6_build_regex "$e_anchors" "${e_gap:-$i6_gap_default}")

        # split exclude tokens once per entry (unchanged tokenization)
        xtoks=()
        if [[ -n "$e_exclude" ]]; then
            old_ifs="$IFS"; IFS='~'; read -r -a xtoks <<< "$e_exclude"; IFS="$old_ifs"
        fi

        # in-memory line scan: first regex-matching line wins (grep -m1 parity)
        line_idx=0
        for full_line in "${i6_lines[@]}"; do
            line_idx=$((line_idx + 1))
            shopt -s nocasematch
            if [[ "$full_line" =~ $rx ]]; then
                span="${BASH_REMATCH[0]}"
                # line-scoped exclude test over the WHOLE matched line (unchanged semantics)
                excluded=0
                for xtok in "${xtoks[@]}"; do
                    [[ -z "$xtok" ]] && continue
                    [[ "$full_line" == *"$xtok"* ]] && { excluded=1; break; }
                done
                shopt -u nocasematch
                # grep -m1 parity: stop at the FIRST matching line whether or not excluded.
                if (( ! excluded )); then
                    i6_hits="${i6_hits}${scan_file}:${line_idx} : [${e_anchors}] — ${e_reason} | matched: \"${span:0:120}\""$'\n'
                fi
                break
            fi
            shopt -u nocasematch
        done
    done
done < <(git ls-files 2>/dev/null)
```

Key correctness points:
- `mapfile -t i6_lines < "$scan_file"` reads the whole file once; `-t` strips the trailing newline
  per line (matches `grep -n`'s line content). A final no-newline line is still captured by mapfile.
- `[[ "$full_line" =~ $rx ]]` — `$rx` is UNQUOTED so it is treated as a regex (quoting would make it
  a literal). `$rx` is the SAME ERE string `i6_build_regex` already builds for grep `-E`. Bash
  `[[ =~ ]]` uses ERE (POSIX), matching grep `-E`'s dialect for the `.{0,N}` bounded-gap +
  escaped-literal constructs this regex uses. (No backreferences, no PCRE-only syntax in the
  generated pattern — verified against the 14 entries.)
- `shopt -s nocasematch` makes BOTH `[[ =~ ]]` and the `[[ == *glob* ]]` exclude test
  case-insensitive — replacing grep's `-i` on the match AND the existing nocasematch on the exclude.
  It is set immediately before the match and unset on every exit path from the line iteration
  (the matched-line block's end, and the bottom of the loop body for the non-matching path) so it
  never leaks past the scan. (Alternative: set once before the for-loop and unset once after — also
  acceptable and slightly cleaner; see §6.4. Developer may choose either as long as nocasematch does
  not leak past the I.6 block and the match + exclude are both case-insensitive.)
- `span="${BASH_REMATCH[0]}"` replaces the second `grep -o`. `BASH_REMATCH[0]` is the full-match
  span of the most recent successful `[[ =~ ]]`. Leftmost (not leftmost-longest) — cosmetic only
  (OQ-2), and zero hits on the clean tree means no span is ever rendered.
- `break` after the matched-line block (reached on both excluded and non-excluded paths) gives
  grep -m1 first-match-then-stop semantics (constraint 4).

### 6.3 Bash port — `test-verify-i6.sh` `i6_scan_file` (replaces lines 114-140)

`i6_scan_file` emits `idx:line_no` per hitting entry; it never renders a span, so it is a strict
subset of the verify_all engine. Mirror exactly:

```bash
i6_scan_file() {
    local scan_file="$1"
    [[ -f "$scan_file" ]] || return 0
    local i6_lines=()
    mapfile -t i6_lines < "$scan_file" 2>/dev/null
    local idx=0 entry e_anchors e_reason e_exclude e_gap rx
    for entry in "${i6_banned[@]}"; do
        idx=$((idx + 1))
        IFS='|' read -r e_anchors e_reason e_exclude e_gap <<< "$entry"
        rx=$(i6_build_regex "$e_anchors" "${e_gap:-$i6_gap_default}")
        local xtoks=()
        if [[ -n "$e_exclude" ]]; then
            local old_ifs="$IFS"; IFS='~'; read -r -a xtoks <<< "$e_exclude"; IFS="$old_ifs"
        fi
        local line_idx=0 full_line xtok excluded
        for full_line in "${i6_lines[@]}"; do
            line_idx=$((line_idx + 1))
            shopt -s nocasematch
            if [[ "$full_line" =~ $rx ]]; then
                excluded=0
                for xtok in "${xtoks[@]}"; do
                    [[ -z "$xtok" ]] && continue
                    [[ "$full_line" == *"$xtok"* ]] && { excluded=1; break; }
                done
                shopt -u nocasematch
                (( ! excluded )) && printf '%s:%s\n' "$idx" "$line_idx"
                break
            fi
            shopt -u nocasematch
        done
    done
}
```

This keeps the function's output contract (`idx:line_no` lines) byte-identical to the old grep
version for every fixture (line numbers are 1-based, same as `grep -n`).

### 6.4 nocasematch scoping (developer note)

`shopt -s nocasematch` is global to the shell while set. Two equally acceptable scopings:
- (A) set/unset inside each line iteration (as shown in §6.2/§6.3) — most defensive.
- (B) set once before the `for full_line` loop, unset once after it (covers both `[[ =~ ]]` and the
  exclude `[[ == ]]`). Cleaner; the Developer may use (B).
Either way: nocasematch MUST be unset before control leaves the per-entry scan, and MUST cover BOTH
the regex match and the exclude substring test (they were `-i` grep and nocasematch respectively
before — both stay case-insensitive). Do not leave nocasematch set for the rest of verify_all.

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Build the bounded-gap ERE from anchors | `i6_build_regex` | `verify_all.sh:539` / `test-verify-i6.sh:101` | Reuse verbatim — same output feeds `[[ =~ ]]` instead of `grep -E`. |
| Case-insensitive literal substring exclude | `shopt -s nocasematch` + `[[ == *x* ]]` | `verify_all.sh:584-589` | Reuse verbatim — already bash-native (insight L22); only the MATCH around it changes. |
| In-process per-line scan structure | PS twin foreach-line `.Match()` | `verify_all.ps1:545-562` | Port structure to bash; do NOT copy PS's post-exclude fall-through (R-3). |
| Exempt-file / exempt-dir skip | `i6_exempt_files` / `i6_exempt_dirs` loops | `verify_all.sh:565-568` | Reuse verbatim — outside the engine swap. |
| Read whole file into lines | `mapfile -t` | bash builtin | New use here; standard, no dependency (NFR-2). |

## 8. Risk analysis

- **R-1 — `[[ =~ ]]` ERE dialect differs from grep -E.** Mitigation: the generated regex uses only
  escaped literals + `.{0,N}` bounded quantifiers + `.` — all POSIX ERE, identically supported by
  bash `[[ =~ ]]` and grep `-E`. No PCRE/GNU-only constructs. AC-4 (equivalence over live tree) and
  the gap-boundary fixtures (`fx-gap-exact`=HIT, `fx-gap-over`=no-hit) are the empirical proof; a
  divergence there is blocking, not papered over. The CJK-anchor entries (#11-14) are matched
  byte-wise by both engines (UTF-8 bytes; `.` and `.{0,N}` count bytes in both) — fixtures
  `fx-e11/e12/e13` lock this.
- **R-2 — `$rx` quoting in `[[ =~ ]]`.** If `$rx` is accidentally quoted it becomes a literal and
  every match fails (silent false-negative — the worst outcome: a retired claim slips through).
  Mitigation: `$rx` MUST be unquoted in `[[ "$line" =~ $rx ]]`; the positive fixtures (Assertion 1
  numeric expects, AC-14) FAIL loudly if matching breaks, and AC-1 makes that the single most
  important gate. Code Reviewer must eyeball this exact line.
- **R-3 — Copying PS's post-exclude fall-through.** A naive "faithful PS port" would, after an
  exclude, `continue` to later lines (PS does). That would CHANGE bash behavior and violate
  constraint 4. Mitigation: the design's `break` sits after the matched-line block on BOTH paths;
  §6.1 calls this out explicitly. Reviewer must confirm the inner loop stops at the first
  regex-matching line regardless of exclude.
- **R-4 — nocasematch leaking past I.6.** If `shopt -s nocasematch` is set and not unset, later
  checks (J.1 etc.) silently become case-insensitive. Mitigation: §6.4 scoping rule — unset on every
  exit path; Reviewer greps for balanced `shopt -s`/`shopt -u` in the I.6 block.
- **R-5 — `mapfile` on a file without a trailing newline / empty file.** `mapfile -t` captures a
  final no-newline line and yields an empty array for an empty file (zero iterations, no error).
  Mitigation: boundary fixtures `fx-empty.md` (no hit, no error) and the no-trailing-newline fixtures
  (most `printf '%s'` fixtures have NO trailing newline — e.g. `fx-bypass.md`, `fx-e1.md`) already
  exercise this; they must still HIT after the change (Assertion 1). This is strong pre-existing
  coverage for the boundary.
- **R-6 — Lockstep drift if only verify_all.sh is migrated.** If `test-verify-i6.sh`'s `i6_scan_file`
  keeps the grep engine, the regression validates the OLD path (constraint 5). Mitigation: §6.3
  migrates the driver to the identical engine; Code Reviewer confirms NO grep remains in either file's
  scan loop (AC-6).

## 9. Migration / rollout plan

- Single working-tree edit to two files. No data migration, no version bump, no CHANGELOG.
- **Verify_all.sh is NOT in sync-self's mirror set** (mirror set = harness-sync, install-hooks,
  archive-task, guard-rm, migrate-scripts-layout, upgrade-project, language-policy — per AI-GUIDE.md
  line 72 / dev-map §"Reusable utilities"). So there is NO template twin under
  `skills/harness-init/templates/` to keep in lockstep, and `sync-self` does not touch it.
  **CHANGELOG/version obligation check (constraint 6): NONE applies.** The check count stays 32 (no
  check added/removed), no `N checks at vX` claim changes (G.4 untouched), no shipped template
  changes. Confirmed — no version bump required, nothing to surface to the user beyond this note.
- Rollback: revert the two files (`git checkout -- .harness/scripts/verify_all.sh
  .harness/scripts/test-verify-i6.sh`). The engine swap is self-contained.

## 10. Out-of-scope clarifications

- The PS twin's post-exclude fall-through (§6.1) is NOT being aligned to bash in this task — it is a
  latent cross-shell asymmetry only reachable by a multi-line file whose first regex-match is on an
  excluded line AND a later line also matches AND is not excluded. No such file exists in the tree or
  fixtures. Aligning it would require editing the PS twin (forbidden here) and is a separate task.
- No change to the report SPAN derivation beyond `grep -o` → `${BASH_REMATCH[0]}` (cosmetic, OQ-2).
- No optimization of the exempt-skip loops, `git ls-files`, or `i6_build_regex`'s internal `sed`
  (those run once per file / once per entry, not in the hot inner loop).

## 11. Partition assignment

Single Developer mode (no `.harness/agents/dev-*.md` present). Section omitted per agent contract.

## 12. Verdict

**READY.** The design is implementable without further decisions: §6.2 and §6.3 give the exact
replacement blocks, R-3 flags the one PS-port trap, and §9 resolves the constraint-6 version question
(no obligation). Hand to Gate Reviewer.
