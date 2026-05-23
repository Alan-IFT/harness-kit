# 02 — Solution Design · i6-test-hardening (T-005)

Mode: **full**. Inputs: `docs/features/i6-test-hardening/01_REQUIREMENT_ANALYSIS.md`
(READY); `PM_LOG.md`; live scripts at `scripts/verify_all.{ps1,sh}` and
`scripts/test-verify-i6.{ps1,sh}`; T-004 archived design at
`docs/features/_archived/i6-semantic-guard/02_SOLUTION_DESIGN.md`. Insight-index
lines L7/L17/L18/L20/L23/L26/L27/L28/L29 carried per stage 1 §7.

## 1. Architecture summary

A test-layer-only change. The driver pair `scripts/test-verify-i6.{ps1,sh}` gains
(a) a **PS-side bash-record parser** so the PS twin can lockstep `verify_all.sh`'s
`i6_banned` verbatim, (b) a **bash-side PS-hashtable parser** so the bash twin can
lockstep `verify_all.ps1`'s `$banned` verbatim, (c) a **shared 4-field
canonical-form normalization** (`anchors / reason / exclude / gap`) with a
sentinel for "no value", (d) a **file-level exempt predicate** symmetric to the
existing dir-level helper plus element-wise lockstep on both exempt-list
canonicals, and (e) **permanent fixture-driven AC-8 assertions**. No
`verify_all.{ps1,sh}` byte changes; no new dependency; no change to the matcher,
the 13-entry banned list, or the exempt-list contents.

## 2. Affected files

| File | Change |
|---|---|
| `scripts/test-verify-i6.ps1` | Edit — new helpers + new Assertion blocks (3a/3b/3c, 7) |
| `scripts/test-verify-i6.sh`  | Edit — new helpers + new Assertion blocks (3a/3b/3c, 7) |
| `docs/features/i6-test-hardening/06_TEST_REPORT.md` | QA produces in stage 6 |
| `CHANGELOG.md` | Stage 7 entry (next patch version) |

Not touched (out-of-scope per §3 of stage 1): `scripts/verify_all.{ps1,sh}`;
`docs/manual-e2e-test.md:3`; `architecture.html:326`; all templates; all
distributed skills; `sync-self`.

## 3. Module decomposition

This is one driver pair; no new module. Five named code units are added to
each shell; cross-shell symmetry is byte-tight at the name level (NFR-1, AC-15).

### 3.1 Canonical-form record (shared mental model)

A banned entry's canonical comparison form is a 4-element ordered record:
`(anchors, reason, exclude, gap)`. `anchors` and `exclude` are ordered lists of
strings (already `~`-joined in bash, `@(...)` in PS). `gap` is an integer or the
no-value sentinel. `reason` is a string. The lockstep comparator operates on
this canonical form, not on the raw source-text shape (so a PS hashtable and a
bash record compare equal when they describe the same entry).

### 3.2 The empty/null sentinel (resolves Q-1)

**PM decision (a) confirmed.** Sentinel name and value:

- PS:  `$script:I6_EMPTY = '<empty>'` (declared once near the top of the file).
- bash:`I6_EMPTY='<empty>'` (declared once near the top of the file).

Normalization function name (identical in both shells, AC-15):

- PS:  `Format-I6Field($value)` — returns `$script:I6_EMPTY` if `$value` is
  `$null`, `''`, or an array with `Count -eq 0`; otherwise returns the value
  unchanged for strings, or `($value -join '~')` for arrays. Note: PS receives
  arrays for `anchors` / `exclude` and strings for `reason`; `gap` is `$null`
  or an `int`. Helper handles all three cases.
- bash:`i6_format_field` (function) — reads `$1` as the field value; emits
  `$I6_EMPTY` if `[[ -z "$1" ]]`, otherwise emits `$1` unchanged. (bash records
  are already `~`-joined for lists; no array path needed.)

Comparison primitive (the only place `-ceq` / `[[ "$a" == "$b" ]]` is invoked):

- PS:  `Test-I6FieldEq($a, $b)` returns `$true` iff
  `(Format-I6Field $a) -ceq (Format-I6Field $b)`. **`-ceq` is mandatory**
  (NFR-4 / insight L7 / L17 / L20 / L23). Default `-eq` would mojibake-mask a
  CJK-vs-mojibake mismatch by collapsing to UTF-8 equivalents.
- bash:`i6_field_eq` — `[[ "$(i6_format_field "$1")" == "$(i6_format_field "$2")" ]]`.
  Bash `[[ == ]]` is literal-binary (no case-folding, no glob unless RHS is
  unquoted) — explicit double-quoted RHS is required.

### 3.3 PS-side bash-record parser — `Get-ShI6BannedRecords` (resolves Q-2)

**PM decision (a) confirmed.** The PS driver reads `scripts/verify_all.sh` as
text, extracts the `i6_banned=(...)` block, and yields one **parsed 4-tuple**
per record. No bash invocation. (Previously `Get-ShI6Banned` in
`test-verify-i6.ps1:277-286` returned raw lines; that helper stays for the
text-equality assertion against `test-verify-i6.sh`. The new helper does the
deeper parse.)

Signature (PS):
`Get-ShI6BannedRecords([string]$path) -> [pscustomobject[]]` where each output
object has properties `anchors` (string[]), `reason` (string), `exclude`
(string[]), `gap` (string — kept as string because the source is text; "" is
normalized via `Format-I6Field`).

Extraction logic (PS):
1. `Get-Content -Encoding UTF8 -LiteralPath $path` (UTF-8 explicit — boundary
   condition 4.5 in stage 1).
2. Walk lines; toggle an `$inArr` flag on `^i6_banned=\(` open and `^\)` close
   (same toggle as the existing `Get-ShI6Banned`).
3. For each in-array line: strip leading/trailing whitespace. Skip blanks.
4. Strip the bash double-quoted wrapper: the record line is `"...|...|...|..."`
   — peel one leading `"` and one trailing `"` (literal characters), then
   un-escape bash's backslash-backtick sequences `` \` `` → `` ` `` (entries
   #2/#6/#8 use this escape; PS array source uses literal backticks inside
   single-quoted strings, so they decode to the same canonical token).
5. Split the unwrapped string on `|` with `[StringSplitOptions]::None` so a
   trailing empty field is preserved (boundary condition 4.3). Assert the
   resulting array length is exactly 4 — if not, FAIL with the entry index and
   the raw line (boundary condition 4.5).
6. The 1st and 3rd fields are `~`-joined; split each on `~` to recover the
   ordered list (empty 3rd field → empty list).
7. Emit a `[pscustomobject]@{ anchors = [string[]]; reason = [string]; exclude
   = [string[]]; gap = [string] }`.

Multi-line robustness: today's records are single-line by contract (stage 1
§4.5 calls this out; T-004 design enforces it via the `extract_i6_banned` awk
shape). The parser does NOT attempt to join wrapped lines; if a future record
is wrapped, the unwrap step at (4) fails closed (length-not-4 FAIL with raw
line) — the maintainer gets a clear "you wrapped a record line" message.

### 3.4 Bash-side PS-hashtable parser — `extract_ps_banned_records`

Symmetric counterpart for AC-2 / AC-3 (bash driver locksteps `verify_all.ps1`).
Reads `scripts/verify_all.ps1` as text and parses each
`@{ anchors = @(...); reason = ...; exclude = @(...); gap = ... }` line into
the 4-tuple canonical form.

Implementation: a sed-based field extractor, one regex per field, anchored on
the `anchors = @(`, `reason = `, `exclude = @(`, `gap = ` literal prefixes that
already appear in `verify_all.ps1:487-499`. Each regex captures the field body
between its literal opener and the next field's literal opener / line end.
Inside `anchors = @(...)` and `exclude = @(...)`, split on `,` and then strip
each element of leading/trailing whitespace and the surrounding `'`. `gap`
captures the integer or the literal `$null` token; `$null` is normalized to
`I6_EMPTY` by `i6_format_field`. `reason` captures the double-quoted string body
(strip one leading `"` and one trailing `"`; entries do not contain embedded
`"`).

Output shape: emits one record per line in the form
`anchors~tokens|reason|exclude~tokens|gap` — i.e. **the bash record format**.
This lets the bash side use the **same string-compare primitive** for both
"verify_all.sh vs driver" and "verify_all.ps1 vs driver" — the latter is just
the PS source projected into the bash canonical form. Symmetry payoff: the
existing `extract_i6_banned` (lines 252-255) is reused unchanged on the right
operand; only the left operand acquires a second projection function. (Reuse
audit §7.)

Function name (bash): `extract_ps_banned_records`. Lives directly above
`extract_i6_banned` in the script.

### 3.5 Exempt-list canonicals (resolves Q-4 and item 8)

**PM decision (a) confirmed** — each driver hard-codes both canonicals near
the top of the file, next to `$i6Banned` / `i6_banned`. Verbatim:

**PS** (`scripts/test-verify-i6.ps1`, added directly after `$i6ExemptDirs` at
line 54):

```powershell
# The canonical list for I.6 exempt FILES at this driver's version. Element-wise
# equality against verify_all.{ps1,sh} is asserted by Assertion 3c.
$i6ExemptFiles = @(
    "CHANGELOG.md", "architecture.html", "docs/walkthrough.html",
    "scripts/verify_all.ps1", "scripts/verify_all.sh",
    "scripts/test-verify-i6.ps1", "scripts/test-verify-i6.sh"
)
# Single source of truth for the banned-list entry count. Bumping to 14 = edit here.
$script:I6ExpectedEntryCount = 13
```

**bash** (`scripts/test-verify-i6.sh`, added directly after `i6_exempt_dirs` at
line 70):

```bash
# The canonical list for I.6 exempt FILES at this driver's version. Element-wise
# equality against verify_all.{ps1,sh} is asserted by Assertion 3c.
i6_exempt_files=(
    "CHANGELOG.md" "architecture.html" "docs/walkthrough.html"
    "scripts/verify_all.ps1" "scripts/verify_all.sh"
    "scripts/test-verify-i6.ps1" "scripts/test-verify-i6.sh"
)
# Single source of truth for the banned-list entry count. Bumping to 14 = edit here.
i6_expected_entry_count=13
```

**Magic-number elimination (item 8 / NFR-2).** Today's count assertion at
`test-verify-i6.ps1:289-291` reads `$liveBanned.Count -eq 13` and at
`test-verify-i6.sh:261` reads `${#live_banned[@]} -ne 13`. Both are rewritten
to reference the named constant. The per-entry loops (`for ($i = 0; $i -lt
$liveBanned.Count; $i++)` and `for i in "${!live_banned[@]}"`) iterate over
the live array length, so they pick up the new size automatically once the
constant is bumped.

### 3.6 File-exempt predicate (item 9)

PS function name: `Test-I6FileExempt($p)` (mirror of `Test-I6DirExempt` at
`test-verify-i6.ps1:89-92`). Body: `return ($i6ExemptFiles -ccontains $p)`.
**`-ccontains` is mandatory** (NFR-4 / insight L7). Default `-contains` would
return `true` for `CHANGELOG.MD` vs `CHANGELOG.md`, masking a future
casing-drift bug between PS and bash.

bash function name: `i6_file_exempt`. Body:
```bash
i6_file_exempt() { local p="$1" ef; for ef in "${i6_exempt_files[@]}"; do
    [[ "$p" == "$ef" ]] && return 0; done; return 1; }
```
Note: `[[ == ]]` is case-sensitive literal — symmetric to PS's `-ccontains`.

Combined predicate (used by AC-12 and AC-13): `Test-I6Exempt($p)` /
`i6_exempt`, returning `true` iff file-exempt OR dir-exempt. Names byte-match
across shells (modulo PS verb-noun convention prefix).

## 4. Data model changes

None — driver scripts only. No DB, no schema, no `.harness/insight-index.md`
edit at design time (insight index may gain a line at delivery per AC-19, only
if implementation surfaces a new fact).

## 5. API / interface contracts

No public API. Internal contracts:

- Driver exit code: 0 on PASS-all; 1 on any FAIL. Unchanged from today.
- `--emit-hits <dir>` mode: behaviorally unchanged. The new Assertion 3a/3b/3c
  and Assertion 7 are skipped in `--emit-hits` mode (per stage 1 boundary 4.9)
  — that mode exists solely to feed the cross-shell parity check.
- Stdout format: existing `PASS  <name>` / `FAIL  <name>` lines stay. New
  assertions use the same `Assert "<name>" { ... }` (PS) and
  `assert "<name>" <0|1>` (bash) helpers; no new output format.

## 6. Sequence / flow

Single driver run, in either shell:

```
                       +--------------------------------------+
                       | New-FixtureCorpus  (extended in §7) |
                       +---------------+----------------------+
                                       |
                                       v
Assertion 1 — per-fixture behavioral hit/no-hit (unchanged, +AC-14 row)
Assertion 2 — cross-shell parity via --emit-hits (unchanged)
Assertion 3 — structural lockstep:
    3a — verify_all.sh i6_banned (existing for bash; NEW for PS)
    3b — verify_all.ps1 $banned  (NEW for both shells; verbatim 4-field)
    3c — exempt-FILE and exempt-DIR lockstep element-wise (NEW for both)
Assertion 4 — no-error on metacharacter/Unicode (unchanged)
Assertion 5 — gap boundary (unchanged)
Assertion 6 — F-1 / F-2 / F-4 / Rev-4 regression (unchanged, +file-exempt twin)
Assertion 7 — AC-8 permanent fixture coverage (NEW):
    7.1  file-exempt predicate: positive corpus (7 paths)
    7.2  file-exempt predicate: negative corpus (3 paths)
    7.3  combined predicate vs dir-exempt fixture path (AC-12)
    7.4  combined predicate vs file-exempt corpus paths (AC-13)
    7.5  AC-14 negative-regression: non-exempt fixture file with banned content HITs
```

Per-entry verbatim-comparison flow (Assertion 3a/3b):

```
for i in 1..I6ExpectedEntryCount:
    live  = parseRecord(live_source[i])    // 4-tuple
    self  = parseRecord(self_source[i])    // 4-tuple
    for field in (anchors, reason, exclude, gap):
        if not i6_field_eq(live[field], self[field]):
            FAIL "<assertion name>: entry #<i> field <field> mismatch
                  live=<formatted>  driver=<formatted>"
    end
end
PASS "<assertion name>: <13> entries × 4 fields verbatim"
```

Failure message format is identical across shells: same field labels, same
"live=... driver=..." layout, same entry-index style (1-based). NFR-1
inspectable.

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Re-declared I.6 matcher (regex builder + line-scoped exclude) | `Scan-I6File` / `i6_scan_file` | `scripts/test-verify-i6.ps1:62-87`, `.sh:85-111` | Reuse as-is; AC-14 (non-exempt hit) calls it |
| Bash `i6_banned` source-line extractor | `extract_i6_banned` (awk) | `scripts/test-verify-i6.sh:252-255` | Reuse as-is for the right operand of 3a |
| Bash `i6_banned` raw-line extractor (PS-side) | `Get-ShI6Banned` | `scripts/test-verify-i6.ps1:277-286` | Reuse as-is for the text-equality fall-through (kept for backward parity); deeper parse is the NEW `Get-ShI6BannedRecords` |
| Dir-exempt predicate | `Test-I6DirExempt` / `i6_dir_exempt` | `scripts/test-verify-i6.ps1:89-92`, `.sh:114-120` | Reuse as-is; the NEW file-exempt predicate is the byte-symmetric twin |
| Assert helper (PS / bash) | `Assert` / `assert` | `scripts/test-verify-i6.ps1:174-186`, `.sh:34-44` | Reuse as-is for all new assertions |
| Fixture-corpus writer | `New-FixtureCorpus` / `new_fixture_corpus` | `scripts/test-verify-i6.ps1:98-120`, `.sh:136-160` | Extend with one new fixture file `fx-ac14-nonexempt.md` (AC-14); no change to existing 20 fixtures |
| Bash bracket-equality (case-sensitive literal) | `[[ "$a" == "$b" ]]` | per-call | Reuse pattern; no new code |
| PS case-sensitive comparison | `-ceq` / `-ccontains` | per-call (insight L7/L17/L20/L23) | Reuse pattern; no new code |
| AC-8 inline injection probe (T-004 QA) | `06_TEST_REPORT.md` lines ~198-231 of the archived task | `docs/features/_archived/i6-semantic-guard/06_TEST_REPORT.md` | Superseded by Assertion 7 fixtures; archived ref only |

Reuse-density: 8 of 9 needs are met by existing code, unchanged. The only
genuinely new code is the two parser projections (§3.3 / §3.4), the two
sentinel/format helpers (§3.2), the file-exempt predicate (§3.6), the
canonical lists / count constant (§3.5), and the Assertion 7 block (§3.6).

## 8. Acceptance-name catalog (resolves AC-15)

These are the byte-identical assertion-name strings the two drivers will both
emit (NFR-1 / AC-15). The PS driver prepends nothing; the bash driver prepends
nothing; `Assert "<name>"` and `assert "<name>"` consume the string raw.

| # | Assertion name (string) | Covers |
|---|---|---|
| A3a-1 | `structural lockstep: verify_all.sh i6_banned entry count equals I6ExpectedEntryCount` | item 8 / Q-4 |
| A3a-2 | `structural lockstep: verify_all.sh i6_banned matches driver verbatim (per-entry × 4 fields)` | item 1/2 partly, item 3 |
| A3b-1 | `structural lockstep: verify_all.ps1 $banned entry count equals I6ExpectedEntryCount` | item 8 |
| A3b-2 | `structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry × 4 fields)` | item 1/2/4 |
| A3c-1 | `exempt-file lockstep: verify_all.ps1 $exempt equals canonical (element-wise)` | item 6, AC-8 |
| A3c-2 | `exempt-file lockstep: verify_all.sh i6_exempt_files equals canonical (element-wise)` | item 6, AC-8 |
| A3c-3 | `exempt-dir lockstep: verify_all.ps1 $exemptDirs equals canonical (element-wise)` | item 7, AC-9 |
| A3c-4 | `exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical (element-wise)` | item 7, AC-9 |
| A7-1..A7-7 | `file-exempt predicate: <path> is reported exempt` (one per canonical path) | item 10 / AC-10 |
| A7-N1..N3 | `file-exempt predicate: <path> is NOT reported exempt` (README.md, docs/concepts.md, scripts/harness-sync.sh) | item 11 / AC-11 |
| A7-DIR | `combined exempt: docs/features/some-task/03_GATE_REVIEW.md skipped (dir-exempt)` | item 12 / AC-12 |
| A7-FILE-1..7 | `combined exempt: <canonical exempt path> skipped (file-exempt)` | item 13 / AC-13 |
| A7-REG | `AC-14 negative regression: non-exempt fixture with banned content HITs` | item 14 / AC-14 |

All names are constructed by concatenation of fixed literals in the driver
source — no `printf` interpolation that could differ between shells. The
"<path>" substitutions iterate over the canonical-list array in identical
order in both shells; PASS-line text is therefore byte-identical (modulo the
shell's own PASS/FAIL prefix).

## 9. Expected count (resolves AC-17) — empirical-equality contract

**Revised in response to Gate Review M-1.** The earlier draft hard-coded
`PASS: 58` derived from a wrong baseline (32/32). Re-measured baseline
**today is PS = 35 / bash = 34** (counted by direct `Assert` / `assert` site
enumeration; see GR §1.1 for the row-by-row tally). Hard-coding an absolute
target N for AC-17 is fragile: any future unrelated driver-row reshuffle
(e.g. splitting one combined assertion in two) shifts N without affecting
the load-bearing property. Per long-term-maintainability principle, AC-17's
binding contract is downgraded from "PASS: <N>" to a **3-clause
empirical-equality contract**:

1. **PS == bash equality.** `pwsh -NoProfile -File scripts/test-verify-i6.ps1`
   and `bash scripts/test-verify-i6.sh` emit the same `PASS:` integer at
   their final summary line. The integer's absolute value is whatever the
   implementation produces; the binding claim is the two values are equal.
2. **3-run stability.** Three back-to-back invocations of each driver, on a
   clean working tree with no concurrent file mutations, emit identical
   `PASS:` integers on every run (no flakes). The integer matches across
   both shells per (1) and across all three runs in each shell.
3. **Monotonic growth.** The post-change `PASS:` integer is strictly greater
   than the recorded pre-change baseline in the same shell (PS: > 35;
   bash: > 34), confirming new assertions were actually added rather than
   silently removed. The "+ how many" delta is implementation-determined
   and reported in stage 6 (QA) `06_TEST_REPORT.md` as a single line:
   "post-change PS = N₁, baseline 35, delta = +(N₁ − 35); post-change
   bash = N₂, baseline 34, delta = +(N₂ − 34); N₁ == N₂ (per AC-17.1)".

**Why empirical-equality, not hard-coded N.** A future unrelated driver
maintenance task that legitimately splits one Assert into two (or merges
two into one) is a normal refactor that should NOT trigger a re-spec of
this design. The empirical-equality contract isolates AC-17 from such
churn: as long as PS and bash stay in lockstep AND the post-change count
is strictly larger than baseline, AC-17 PASSes. The "+26 / +26 symmetry"
language from the earlier draft is also withdrawn — symmetry is now
captured by AC-17.1's PS == bash clause, which holds regardless of the
exact additive count.

**Rough magnitude expectation (informational, NOT a binding AC).** Stage 1
counted the new assertions Assertion 7 introduces (7 + 3 + 1 + 7 + 1 = 19
new rows) plus a small net delta in Assertion 3 (a few new lockstep rows
minus subsumed ones). Order-of-magnitude landing zone: low-to-mid 50s in
each shell; if QA measures a final integer outside `[40, 80]`, that is a
signal something unexpected happened and PM should investigate before
accepting delivery.

## 10. Risk analysis

**R-1 — PS bash-record parser fragility on backtick escape (insight L19).**
Entries #2/#6/#8 in `verify_all.sh:523,527,529` contain `` \` `` (bash
backslash-backtick to keep the backtick literal in a double-quoted string).
The PS array source at `verify_all.ps1:488,492,494` uses single-quoted
strings with literal `` ` ``. After both decode, the anchor token is the same
literal `` `CLAUDE.md` ``. The PS parser MUST decode `` \` `` → `` ` ``
explicitly (§3.3 step 4); without this step, the comparator sees `\`` on the
left and `` ` `` on the right and FAILs spuriously. **Mitigation**: parser
includes an explicit `replace('\`', '`')` step on bash records before
splitting; the corresponding negative test in stage 6 mutates entry #2's
` `` to `` to confirm the decoder is doing real work (AC-1 already exercises
entry #5, which has no backtick — add a stage-6 mutation on entry #2 to
exercise the backtick decoder path). Insight L19 is the named ancestor; this
mitigation is a direct application.

**R-2 — Bash PS-hashtable parser brittleness on whitespace / line-wrap.**
The `verify_all.ps1` array is authored as one record per line with a
consistent leading-whitespace pattern (`        @{ anchors = @(...` at 8
spaces — see `verify_all.ps1:487-499`). A future innocent reformat (e.g.
re-indent to 4 spaces, or wrap a long line) would break the sed extraction
in §3.4. **Mitigation**: anchor each field regex on the literal keyword
(`anchors = @(`, `reason = `, `exclude = @(`, `gap = `) rather than on
column position — the regex is whitespace-tolerant before the keyword and
between `=` operators. If the file ever wraps a record across lines, the
parser fails closed (length-not-4 FAIL with raw line, same as §3.3 step 5),
and the maintainer gets a precise message. This caps R-2 to "stage-6 catches
it the next time someone reformats the array" — no silent regression
possible because the count assertion (A3b-1) FAILs the moment the parser
returns ≠ 13 records.

**R-3 — Insight L23 / L20 regression in the new comparator.** Any new PS
`-eq` / `-contains` on a path or token comparison would re-introduce the
exact class of bug T-001 / T-002 / T-003 paid for. **Mitigation**: §3.2's
`Test-I6FieldEq` is the **only** PS comparator the new code uses;
`-ccontains` is the **only** PS membership operator used for the canonical
list lockstep; stage 5 (Code Review) grep rules: `Grep "PS -eq |PS -contains
|PS -match |PS -notin " scripts/test-verify-i6.ps1` over the diff — any hit
that is not in a comment is a review-block.

**R-4 — Live-tree I.6 hit on driver edits (insight L26 / L28).** The new PS
and bash code inside `scripts/test-verify-i6.{ps1,sh}` will itself contain
the banned-phrase strings (the canonical PS array literal is a banned-phrase
container, exactly like `verify_all.ps1`'s array). **Mitigation**: both
`test-verify-i6.{ps1,sh}` are already in the I.6 **exempt-FILE list** (live
script lines 521 / 552; insight L26). The new code stays inside the same
exempt files. Stage 6 runs `pwsh scripts/verify_all.ps1` and
`bash scripts/verify_all.sh` (insight L28: live-tree run is the canonical
verdict, not hand-reasoning) to confirm 30/30 PASS post-change (AC-16 / AC-18).

**R-5 — Test runtime explosion (NFR-7 / boundary 4.0).** Assertion 7 adds
~30 new asserts, but each is an O(1) string compare on already-loaded data;
no new file I/O beyond one extra `fx-ac14-nonexempt.md` fixture. Estimated
per-shell wall-clock delta: <50ms. Acceptable upper bound: 2× today's
runtime per NFR-7. **Mitigation**: stage 6 measures wall-clock on 3
back-to-back runs (per AC-17 "no flakes") and reports.

## 11. Migration / rollout plan

**Backwards compatibility.** None at risk — the driver pair is repo-local
(not distributed via `harness-sync` or `sync-self` per stage 1 §3). Existing
consumers: the developer runs them by hand; the user has no embedded
dependency.

**Roll-forward order.**
1. Edit `scripts/test-verify-i6.sh` (helpers + Assertion 3a/3b/3c + Assertion
   7 + canonical lists + named-count constant). Run `bash
   scripts/test-verify-i6.sh` — expect `FAIL: 0`; the absolute `PASS:` integer
   is implementation-determined per §9's empirical-equality contract.
2. Edit `scripts/test-verify-i6.ps1` symmetrically. Run `pwsh
   scripts/test-verify-i6.ps1` — expect `FAIL: 0` AND the same `PASS:` integer
   as the bash twin in step 1 (per §9 clause 1: PS == bash equality).
3. Run `bash scripts/verify_all.sh` and `pwsh scripts/verify_all.ps1`.
   Expect `30/30 PASS` (no new I.6 hits — driver edits stay inside the
   exempt files, AC-16).
4. Stage 6 mutation cycle (AC-20): mutate one field per shell per field type
   (`anchors` / `reason` / `exclude` / `gap`) on at least one entry, in
   both `verify_all.ps1` and `verify_all.sh`. Confirm BOTH drivers FAIL on
   each of the 8 mutations. Revert.
5. Stage 7 (Delivery) updates `CHANGELOG.md` per insight L11 / L14
   (CHANGELOG is part of the fan-out). No `AI-GUIDE.md` / `docs/dev-map.md`
   edit required (AC-19 confirmed in stage 1).

**Rollback.** Single-file revert of `scripts/test-verify-i6.{ps1,sh}`
restores the v0.18.0 driver shape. No external state, no DB, no template
sync.

**Version label.** Next patch (e.g. v0.18.1) or next minor — stage 7 PM
chooses. The label has no requirement-level dependency (stage 1 §0).

## 12. Out-of-scope clarifications (design boundary)

- The matcher logic body in `verify_all.{ps1,sh}` (Build-I6Regex /
  i6_build_regex, the per-line scan loop, the line-scoped exclude loop) is
  **not** lockstep-asserted at the prose level (Q-5 PM decision (b)
  confirmed). The cross-shell parity assertion (Assertion 2) already
  guarantees behavioral equivalence; textual lockstep on function bodies
  brittles the test against innocent refactors and earns its line only when
  prose drift is observed in practice (not the case today).
- The Q-3 PM decision is honored: canonical exempt-path corpus (items 10,
  11, 13) is **path-only** (no physical file at literal `scripts/verify_all.ps1`
  inside the fixture temp dir). AC-14 (item 14) is **the only** case that
  needs a physical file at a non-exempt path; that file is the new
  `fx-ac14-nonexempt.md` fixture (named after AC-14 for grep-ability).
- The new `Test-I6FileExempt` / `i6_file_exempt` predicate is a **driver
  helper only** — it is NOT proposed as a public function in
  `verify_all.{ps1,sh}`. The live scripts already do file-exempt membership
  inline (lines 528, 562) and that inline form is what the driver locksteps
  against — extracting it to a named function in the live scripts is a
  separate refactor, not in scope (stage 1 §3).
- `architecture.html:326` and `docs/manual-e2e-test.md:3` are not touched
  here (stage 1 §3; PM_LOG ships the manual-e2e-test fix as a separate
  trivial commit AFTER this task).

## 13. Partition assignment

The repo runs in single-Developer mode (no `.harness/agents/dev-*.md` files
exist — Glob confirmed at design time). All edits in §2 are dispatched to the
single canonical Developer agent in stage 4. No partition table required by
the agent contract; this section is recorded for record-keeping only.

## 14. Verdict

**READY**

All five Q-decisions from stage 1 are confirmed without override:
- Q-1 (a): single canonical sentinel `<empty>` — §3.2.
- Q-2 (a): PS-side bash-record parser (no shell-out) — §3.3.
- Q-3 (b)+(a): path-only canonical corpus + one physical AC-14 file — §6 / §12.
- Q-4 (a): hard-coded canonical lists in each driver — §3.5.
- Q-5 (b): no matcher-prose lockstep — §12.

Item 8 (magic-number elimination), AC-15 (assertion-name parity), AC-17
(expected count) and partition assignment are all resolved in §3.5 / §8 / §9 /
§13 respectively. Risks R-1..R-5 each carry a concrete mitigation. The design
is implementable by the Developer agent without further architectural
decisions; stage 3 (Gate Reviewer) is the next hop.
