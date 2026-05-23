# 01 — Requirement Analysis · i6-test-hardening (T-005 · v0.18+)

Mode: **full** (canonical 7-stage). Target version: next patch/minor after v0.18.0
(version label is PM/Architect's call in stage 2; no requirement-level dependency).

> Upstream inputs: `docs/features/i6-test-hardening/INPUT.md` (user request) and
> `docs/features/i6-test-hardening/PM_LOG.md` (PM framing). Both are read-only here.

## 1. Goal

Close the two non-blocking gaps left by T-004 (i6-semantic-guard, v0.18.0) by
**raising `scripts/test-verify-i6.{ps1,sh}`'s structural lockstep to symmetric
verbatim coverage in both shells** and **adding a permanent corpus fixture for the
AC-8 exemption guarantee** (file-level + dir-level), so a `reason` / `exclude` /
`gap` typo in either `verify_all.{ps1,sh}`'s I.6 banned list and a future refactor
of the I.6 exempt-list handling are both caught by the regression driver pair on
every run, not only by ad-hoc inline probes at QA time.

## 2. In-scope behaviors

The numbering below is the contract the downstream stages must satisfy. Every
item is observable — either by reading driver output, by running both shells and
diffing, or by injecting a controlled regression and confirming a FAIL.

### 2.1 Structural lockstep — symmetric verbatim coverage

1. `scripts/test-verify-i6.ps1`'s Assertion 3 ("structural lockstep") gains a
   **verbatim per-entry comparison** of `scripts/verify_all.ps1`'s `$banned`
   array against the driver's own canonical copy. Every one of the 13 entries
   is compared on at least these fields: `anchors` (ordered list, element-wise),
   `reason` (exact string), `exclude` (ordered list, element-wise), `gap` (value
   or `$null`). A divergence in any one field on any one entry produces a
   driver FAIL whose message names the entry number and the diverging field.
2. `scripts/test-verify-i6.sh`'s Assertion 3 gains a **verbatim per-entry
   comparison** of `scripts/verify_all.ps1`'s `$banned` array against the
   driver's own canonical copy. The comparison covers the same four fields
   listed in (1) for each of the 13 entries; a divergence FAILs with the
   entry number and the diverging field.
3. The existing bash-side verbatim comparison of `scripts/verify_all.sh`'s
   `i6_banned` array against the bash driver's own copy is preserved as-is
   (no regression on what works today).
4. The PS-side gains a **verbatim comparison of `scripts/verify_all.sh`'s
   `i6_banned` array** against the PS driver's canonical copy (the symmetric
   twin of (3) — today the PS driver only does this transitively via the bash
   `test-verify-i6.sh` lockstep). The comparison is field-by-field on the 13
   `|`-delimited bash records (`anchors~tokens | reason | exclude~tokens | gap`).
5. After this change, the matrix of "driver X validates live-script Y" is the
   complete 2×2:

   |              | verify_all.sh | verify_all.ps1 |
   |---|---|---|
   | test-verify-i6.sh  | verbatim, 13 entries × 4 fields | verbatim, 13 entries × 4 fields |
   | test-verify-i6.ps1 | verbatim, 13 entries × 4 fields | verbatim, 13 entries × 4 fields |

   No cell is "count-only" or "entry #10 only".
6. The exempt-FILE list of I.6 (`$exempt` in PS, `i6_exempt_files` in sh) becomes
   subject to structural lockstep too: each driver asserts the live script's
   exempt-file list **equals** a canonical list maintained in the driver,
   element-wise, in both shells. The canonical list at this task's start is
   `CHANGELOG.md`, `architecture.html`, `docs/walkthrough.html`,
   `scripts/verify_all.ps1`, `scripts/verify_all.sh`,
   `scripts/test-verify-i6.ps1`, `scripts/test-verify-i6.sh` (per the live I.6
   blocks at `scripts/verify_all.sh:546-554` and `scripts/verify_all.ps1:515-523`).
7. The existing exempt-DIR lockstep (`docs/features/` present in both scripts)
   is preserved; in addition, the assertion is upgraded to a **full element-wise
   equality** against a canonical list in the driver (`docs/features/`, `参考/`),
   in both shells.
8. The "13 entries" magic number is **defined once per driver** as a named
   constant (e.g. `$expectedI6EntryCount` / `i6_expected_entry_count`) and the
   count assertions and the per-entry loops both reference it. Bumping the list
   to 14 (a future task adding a 14th banned entry) becomes a one-line driver
   edit, not a hunt-and-replace.

### 2.2 AC-8 permanent corpus fixture — file-level and dir-level exemption

9. The driver pair gains a **file-level exempt** model that is symmetric to the
   existing `Test-I6DirExempt` / `i6_dir_exempt` dir-level helper. Each shell
   exposes a self-contained predicate (`Test-I6FileExempt` in PS,
   `i6_file_exempt` in sh) whose definition is byte-mirror of the live
   `verify_all.{ps1,sh}` exempt-file membership test (exact-string equality
   against the canonical list of in-scope item 6).
10. The driver pair gains **permanent fixture-driven assertions** that the
    file-level exemption is honored. For each canonical exempt-file path
    (in-scope item 6), the driver asserts: a synthetic input file located at
    that exact path (within the temp dir's working layout, or evaluated against
    the predicate by path) is reported **exempt** by the predicate. The
    assertion is positive (must be exempt) and is run in **both shells**.
11. The driver pair gains the corresponding **negative assertion**: a synthetic
    path that is NOT in the canonical exempt-file list (e.g. `README.md`,
    `docs/concepts.md`) is reported **NOT exempt**. Run in both shells. (The
    existing F-2 negative-case assertion for the dir-level predicate is
    preserved; this is the file-level twin.)
12. The driver pair gains a **content-bearing fixture assertion** that closes
    the AC-8 coverage gap end-to-end (not just at the predicate layer): a
    fixture file is created at a path **inside** an exempt directory
    (`docs/features/some-task/03_GATE_REVIEW.md` — the same synthetic path the
    existing dir-exempt assertion already uses) and **its content is a literal
    banned phrase** (e.g. `harness-sync regenerates CLAUDE.md`). The driver
    asserts that the combined predicate `file_exempt(path) OR dir_exempt(path)`
    short-circuits before the matcher runs on this file — equivalently, the
    file is skipped from scanning. Run in both shells.
13. The driver pair gains the **file-exempt twin** of (12): a fixture file with
    content `harness-sync regenerates CLAUDE.md` exists, and the driver
    evaluates the combined exemption predicate against each canonical
    exempt-file path with that fixture's content — asserting each canonical
    exempt path is skipped from scanning. (This models the real run-time path:
    `verify_all` iterates `git ls-files`, filters out exempt files first, then
    runs the matcher only on the survivors.)
14. A direct **negative regression assertion**: a fixture file at a NON-exempt
    path (e.g. the temp dir's `README.md`) containing the same literal banned
    phrase IS reported as a hit by the driver's matcher. This guards against a
    future bug that makes the exemption predicate return `true` for all paths
    (which would silently mask every real regression).

### 2.3 Cross-shell parity and counts

15. The new structural lockstep assertions (items 1, 2, 4, 6, 7) and the new
    AC-8 assertions (items 9-14) are present in **both** `scripts/test-verify-i6.ps1`
    and `scripts/test-verify-i6.sh`. The assertion **names** are byte-identical
    across shells where the assertion is semantically the same, so a maintainer
    grepping for a failure can find the twin by name.
16. After this change, the driver pair's pass counts grow but remain within
    twin tolerance (the documented PS-vs-bash split-count delta of 1 from
    T-004 may grow by an equal amount on both sides; any new delta must be
    documented in the driver header comment with a one-line justification —
    NO undocumented count divergence).
17. The two driver scripts still complete in **the same order of magnitude of
    wall-clock time** as today (no per-fixture I/O explosion). Acceptable
    upper bound: 2x the current `test-verify-i6.{ps1,sh}` runtime on this repo.
18. After this change, `scripts/verify_all` (both shells) still reports PASS
    30/30 on the current repo — this task adds no new `verify_all` check and
    introduces no I.6 hit on any live file.

## 3. Out-of-scope (explicit non-goals)

- **No change to `verify_all.{ps1,sh}` I.6 matcher logic.** The matcher (anchor
  scan, line-scoped exclude, `gap` budget, exempt-list handling) stays
  byte-identical to v0.18.0. Only the **regression-driver** layer changes.
- **No change to the I.6 banned-list contents** (13 entries; same anchors /
  reasons / excludes / gaps as today). No banned phrase is added or removed.
- **No change to the I.6 exempt-file or exempt-dir list contents.** The
  canonical lists asserted by the new driver assertions are exactly today's
  values (item 6, item 7).
- **No change to the I.6 check count, severity, or position in `verify_all`.**
  Count stays 30; I.6 stays FAIL severity.
- **No NLP / embedding / LLM-based matcher upgrade.** User-declared out
  ("远超本次"); T-004 design §3.2 documents the threat model
  (unintentional copy-paste drift, not active adversary). This task does NOT
  re-open that decision.
- **No `architecture.html:326` refresh.** User-declared out: the file carries
  its own v0.5/v0.6 snapshot caveat and the refresh is deferred to a future
  roadmap item.
- **No `docs/manual-e2e-test.md:3` fix in this task.** PM has decided to ship
  that single-line `v0.17.4 → v0.18.0` doc-consistency fix as a separate
  trivial commit AFTER this task, NOT as part of the 7-stage pipeline.
- **No new `scripts/test-*` pair.** The existing `scripts/test-verify-i6.{ps1,sh}`
  pair is extended in place; no third script is added.
- **No `sync-self` change.** `scripts/test-verify-i6.{ps1,sh}` is repo-bespoke
  (T-004 §7.4); `sync-self` mirrors only `harness-sync`, `install-hooks`,
  `archive-task`, `guard-rm`.
- **No template / `skills/harness-init/templates/` change.** The I.6 regression
  driver is not distributed via the plugin; it stays repo-local.
- **No retroactive doc cleanup** triggered by the stronger lockstep. If the
  lockstep upgrade surfaces a real divergence between the driver and
  `verify_all.{ps1,sh}`, that is a finding routed back through PM, not silently
  patched here (in-scope item 18 asserts the current state is consistent —
  if it is not, that is a blocker).

## 4. Boundary conditions

- **Empty exempt list** (`$exempt = @()` / `i6_exempt_files=()`): driver must
  not crash; the count-equality assertion FAILs with a clear message; the
  per-element assertions emit zero comparisons. (Not a configuration we ship,
  but the driver must not panic on a future edit that empties the list.)
- **Exempt list reordered** (same elements, different order): item 6 / item 7
  assertions FAIL because they specify **element-wise** equality. Rationale:
  ordering is part of the contract — a reviewer reading the live script and
  the canonical list side-by-side benefits from the order matching. If a future
  task wants order-insensitive comparison, that is a deliberate spec change.
- **Banned-list field empty** (`exclude = @()` / `gap = $null`): the verbatim
  comparison must treat `@()` and `$null` consistently across shells — bash's
  empty-string field after a `|` split and PS's `@()` / `$null` both represent
  "no value", and the lockstep assertion's normalization must collapse them so
  a semantically equal pair does not falsely diverge. (Concrete: bash record
  `"scaffolding-only|...||"` and PS hashtable `exclude = @(); gap = $null` must
  compare equal under the driver's normalization.)
- **Non-ASCII anchor / exclude tokens** (entries #10-#13: U+2192 arrow, Chinese
  CJK characters, `不`): the verbatim comparison reads source files as UTF-8 in
  both shells (PS `Get-Content -Encoding UTF8` / bash default LANG); a
  re-encoding bug that mojibakes one side must FAIL the lockstep, not silently
  pass via a decoded-equal-to-decoded round-trip.
- **Banned-list entry containing `|` or `~` inside a `reason` string** (not
  the case today, but a hazard called out in `verify_all.sh:512-514`): the
  bash record split would corrupt; the lockstep verbatim comparison detects
  the corruption because the corrupted side's field count differs from 4.
  Required behavior: FAIL with a message that names the corrupted entry index
  and shows the raw record line.
- **Driver run with `git` unavailable**: the lockstep assertions read static
  `scripts/verify_all.{ps1,sh}` source — they do NOT depend on `git ls-files`.
  The AC-8 fixture assertions also do not depend on `git`. Required: the new
  assertions PASS in a non-git environment (consistent with how today's
  structural assertions work).
- **Driver run on a Windows-vs-POSIX path-separator difference**: the
  canonical exempt-file paths use forward slashes (`scripts/verify_all.ps1`),
  matching `git ls-files`'s POSIX output. The driver must compare against the
  POSIX form in both shells — a PS-side accidental `\` substitution
  (insight class L7 / L20: PS operator defaults) must not normalize the
  separator in a way that makes the lockstep falsely pass.
- **Fixture file path containing CJK** (e.g. inside `参考/`): one of the
  exempt directories is `参考/`. The driver's AC-8 negative-case assertions
  that exercise the exempt-dir predicate at the canonical paths must accept
  CJK directory names without crash on Windows (NTFS UTF-16) and POSIX (UTF-8).
- **`--emit-hits` parity mode is unaffected**: the new assertions are skipped
  in `--emit-hits` mode (which exists solely to feed the cross-shell parity
  assertion); only the full regression run exercises them.

## 5. Acceptance criteria

Every AC is mechanically verifiable by running one of the two driver scripts,
running `verify_all`, or grepping the diff.

- **AC-1 (PS verbatim lockstep on verify_all.ps1).** Mutate
  `scripts/verify_all.ps1` entry #5's `reason` from `"harness-sync does not
  regenerate CLAUDE.md since v0.10"` to `"harness-sync does not regenerate
  CLAUDE.md since v0.10."` (trailing period). Run
  `pwsh scripts/test-verify-i6.ps1`: it FAILs Assertion 3 with a message
  naming entry #5 and the `reason` field. Revert; re-run: PASS.
- **AC-2 (bash verbatim lockstep on verify_all.ps1).** Same mutation as AC-1.
  Run `bash scripts/test-verify-i6.sh`: it FAILs Assertion 3 with a message
  naming entry #5 and the `reason` field. Revert; re-run: PASS.
- **AC-3 (PS verbatim lockstep on verify_all.sh).** Mutate
  `scripts/verify_all.sh` entry #5's record from
  `"regenerates~CLAUDE.md|harness-sync does not regenerate CLAUDE.md since v0.10||"`
  to the same string with a trailing space in the reason. Run
  `pwsh scripts/test-verify-i6.ps1`: it FAILs Assertion 3 with a message
  naming entry #5 and the field. Revert; re-run: PASS.
- **AC-4 (bash verbatim lockstep on verify_all.sh — regression preserved).**
  Same mutation as AC-3. Run `bash scripts/test-verify-i6.sh`: it FAILs (the
  existing assertion). Revert; re-run: PASS. (This restates today's behavior
  to make explicit it is not regressed.)
- **AC-5 (per-field divergence on exclude).** Mutate
  `scripts/verify_all.ps1` entry #2's `exclude` from
  `@('not','no longer','referenced')` to `@('not','no longer')` (drop
  `'referenced'`). Both `test-verify-i6.ps1` and `test-verify-i6.sh` FAIL with
  a message naming entry #2 and the `exclude` field.
- **AC-6 (per-field divergence on gap).** Mutate
  `scripts/verify_all.ps1` entry #2's `gap` from `20` to `40`. Both drivers
  FAIL with a message naming entry #2 and the `gap` field.
- **AC-7 (per-field divergence on anchors order).** Mutate
  `scripts/verify_all.sh` entry #10's record by swapping the first two
  anchors (`.harness/~→` → `→~.harness/`). Both drivers FAIL with a message
  naming entry #10 and the `anchors` field.
- **AC-8 (exempt-file list lockstep).** Mutate
  `scripts/verify_all.ps1`'s `$exempt` array: remove
  `"scripts/test-verify-i6.ps1"`. Both drivers FAIL the exempt-file lockstep
  assertion with a message naming the missing path. Revert; re-run: PASS.
- **AC-9 (exempt-dir list lockstep).** Mutate
  `scripts/verify_all.sh`'s `i6_exempt_dirs` array: remove `"参考/"`. Both
  drivers FAIL the exempt-dir lockstep assertion with a message naming the
  missing path. Revert; re-run: PASS.
- **AC-10 (file-level exempt predicate — positive corpus).** For each path P
  in the canonical exempt-file list, both drivers' file-exempt predicate
  returns true for P. The assertion is run in both shells and names the path
  that fails (if any).
- **AC-11 (file-level exempt predicate — negative corpus).** For each path Q
  in a small negative corpus (`README.md`, `docs/concepts.md`,
  `scripts/harness-sync.sh`), both drivers' file-exempt predicate returns
  false for Q.
- **AC-12 (AC-8 dir-level fixture).** A fixture at
  `docs/features/some-task/03_GATE_REVIEW.md` (synthetic, evaluated by path —
  the file need not physically exist for the predicate test) carrying the
  literal `harness-sync regenerates CLAUDE.md` content is treated as exempt by
  the combined `file_exempt OR dir_exempt` predicate in both shells. (This
  closes the gap that T-004's QA filled with an inline injection probe.)
- **AC-13 (AC-8 file-level fixture).** For each path P in the canonical
  exempt-file list, the same fixture content from AC-12 evaluated against P
  is treated as exempt by the combined predicate in both shells.
- **AC-14 (negative regression — non-exempt path still hits).** A fixture at
  a non-exempt path (e.g. `README.md` under the temp dir) carrying the same
  banned content is reported as a hit by the driver's matcher in both shells.
  This guards against a future bug that makes the exemption predicate return
  `true` for all paths.
- **AC-15 (cross-shell assertion-name parity).** Every new assertion in (1)
  through (14) has a byte-identical name string in `test-verify-i6.ps1` and
  `test-verify-i6.sh` (where the assertion is semantically the same).
  Verified by `diff <(grep -oE 'PASS\|FAIL  [^"]+' bash-output) <(...ps-output)`
  on the assertion-name column, OR by inspection of the two driver sources.
- **AC-16 (verify_all stays green).** After the driver changes are committed,
  `bash scripts/verify_all.sh` and `pwsh scripts/verify_all.ps1` both report
  30/30 PASS on the current repo. No new I.6 hit; no new `verify_all` check.
- **AC-17 (deterministic counts).** `bash scripts/test-verify-i6.sh` and
  `pwsh -NoProfile -File scripts/test-verify-i6.ps1` each print a final
  `PASS: N` line where N is a fixed expected integer (the architect chooses
  the exact N in stage 2; the requirement is that N is deterministic across
  3 back-to-back runs in each shell, no flakes).
- **AC-18 (no new dependency).** No new tool, runtime, language, library, or
  external command is introduced. The driver continues to use only `bash`,
  `pwsh`/`powershell`, `grep`, `sed`, `awk`, `git` — the same set as today.
- **AC-19 (doc fan-out).** The driver header comments are updated to describe
  the new lockstep coverage (2×2 matrix from item 5). `CHANGELOG.md` records
  the task. The insight-index line on I.6 (`.harness/insight-index.md` line 26
  at task start) gains a one-line follow-up note if the implementation
  surfaces a new insight; otherwise no insight-index edit. **No** edit to
  `AI-GUIDE.md` or `docs/dev-map.md` is required by this task (the existing
  v0.18.0 entries already describe the test driver pair; the architect
  confirms in stage 2 that no version-stamp drift accumulates).
- **AC-20 (Adversarial — mutation-detection probe).** QA runs at least one
  mutation per field (`anchors` / `reason` / `exclude` / `gap`) on at least
  one entry, in both `verify_all.ps1` and `verify_all.sh`, and confirms each
  mutation is caught by BOTH drivers (8 mutation runs minimum). Revert
  confirms green state recovers.

## 6. Non-functional requirements

- **NFR-1 PS/Bash symmetry (rule 30 item 20).** The two drivers' new
  assertions are behaviorally identical: same canonical list, same per-field
  comparison semantics, same assertion names, same failure messages
  (modulo shell-syntax differences in formatting). Symmetry is asserted by
  inspection in stage 5 (Code Review).
- **NFR-2 maintainability.** Adding a 14th banned-list entry in
  `verify_all.{ps1,sh}` requires editing at most: (a) `verify_all.ps1`,
  (b) `verify_all.sh`, (c) the driver's canonical copy in each of
  `test-verify-i6.ps1` and `test-verify-i6.sh`, and (d) the named
  entry-count constant in each driver. No further hand-editing of test
  assertions is required. (This is the property the existing bash-side
  verbatim lockstep already has; this task extends it symmetrically.)
- **NFR-3 zero new false-positive surface.** The new lockstep assertions
  compare driver-canonical to live-script verbatim — they do not introduce
  semantic interpretation that could itself drift. The exempt-list
  assertions use exact-string element-wise equality, not regex.
- **NFR-4 no L23-class operator-default bug.** PS string operators in any
  new comparison code use the explicit case-sensitive variant where the
  contract is fixed-case (`-ceq` over `-eq` for path / list-element
  comparison) — per insight L17 / L20 / L23. The bash side uses `[[ == ... ]]`
  with explicit literal semantics, not unanchored regex.
- **NFR-5 no L27-class grep bug.** No new code path combines `grep -F -i` on
  GNU grep 3.0 / MSYS — per insight L27. Where a case-insensitive literal
  substring test is needed, bash uses `shopt -s nocasematch` + `[[ == *glob* ]]`
  (the pattern already established in the T-004 implementation).
- **NFR-6 no L24-class loop-variable collision.** Any new bash loop variable
  is named `<thing>_file` / `<thing>_entry` and never collides with a
  globally-mutated array (e.g. `failures=()` in the driver).
- **NFR-7 deterministic test runtime.** Driver wall-clock stays within 2× of
  today's runtime on this repo (item 17). Adding 7 file-exempt fixture
  assertions + 7 file-exempt predicate assertions + ~52 lockstep
  field-comparison operations (13 entries × 4 fields) is far inside this
  budget — the assertions are all O(1) string compares on already-loaded
  source text.
- **NFR-8 doc-size compliance (rule 70).** This stage doc stays ≤ 500 lines.

## 7. Related tasks

- **T-004 / i6-semantic-guard (v0.18.0)** — `docs/features/_archived/i6-semantic-guard/`.
  Direct parent: defined the I.6 gap-tolerant matcher, the 13-entry banned list,
  AC-8 ("CHANGELOG / `_archived/` exemption preserved"), the inline injection
  probe used at QA, and the `test-verify-i6.{ps1,sh}` driver pair this task
  extends. Key references:
  - `02_SOLUTION_DESIGN.md` §3.1-§3.6 — banned-entry data structure
    (anchors / reason / exclude / gap), bash record format, PS hashtable shape,
    exempt-dir semantics.
  - `02_SOLUTION_DESIGN.md` §7.1-§7.3 — current test-driver structure (the
    `Assert` helper, the corpus, the three existing structural assertions
    this task extends).
  - `06_TEST_REPORT.md` "AC-8 — exemption preserved" (lines ~198-231) — the
    inline injection probe that this task replaces with permanent fixtures.
- **T-001 / ai-safety-guardrails (v0.15.0)** — `docs/features/_archived/ai-safety-guardrails/`.
  Established the PS case-sensitive-operator discipline (insight L7) that
  NFR-4 carries forward.
- **T-002 / ai-native-init (v0.16.0)** — `docs/features/_archived/ai-native-init/`.
  Insight L11 (CHANGELOG must be in any version-sweep fan-out) applies to
  AC-19; L12 (separate temp dirs for independent fixtures) applies to any
  new fixture allocation.
- **T-003 / supervisor-agent (v0.17.0)** — `docs/features/_archived/supervisor-agent/`.
  Insight L24 (bash loop-variable collision with global array) applies to
  NFR-6; the `test-supervisor.{ps1,sh}` driver pattern that
  `test-verify-i6.{ps1,sh}` follows is established here.
- **I.6 introduction (v0.15.1, no per-task stage docs)** — pre-pipeline
  delivery. Background only.

Relevant insight-index lines at task start (verified per PM_LOG and direct
read of `.harness/insight-index.md`):

| Line | Subject | Applies how |
|---|---|---|
| L7  (2026-05-17) | PS `-contains` case-insensitivity | NFR-4 |
| L17 (2026-05-19) | PS `-notin` case-insensitivity | NFR-4 |
| L18 (2026-05-19) | I.6 retired-claim guard design intent | Threat-model context for in-scope items |
| L20 (2026-05-19) | PS string-operator case-sensitivity family | NFR-4 |
| L23 (2026-05-19) | PS `-match` / `-cmatch` distinction | NFR-4 |
| L26 (2026-05-23) | v0.18 I.6 upgrade + test-verify-i6 exempt note | Context for items 6 / 9-14 |
| L27 (2026-05-23) | GNU grep 3.0 `-F -i` SIGABRT | NFR-5 |
| L28 (2026-05-23) | Live-tree matcher run is canonical | Verification methodology in stage 4 / 6 |
| L29 (2026-05-23) | Sweep sibling scripts when capturing L13 patterns | NFR-6 — sweep new bash loops for `declare -a` / collision |

## 8. Open questions

Per PM's framing ("decision authority delegated to PM; user reviews outcome
only"), each open question carries a **PM-decided** sub-section with the
binding answer, derived from the user's principle (good UX, software
engineering standards, long-term maintainability). All Q-items are
PM-resolvable; none routes to the user as a hard blocker.

### Q-1 — Normalization of "no value" across shells

The bash record `"scaffolding-only|harness-adopt has been fully automated
since v0.3||"` has `exclude` = empty string and `gap` = empty string after
the `|` split. The PS hashtable equivalent has `exclude = @()` and
`gap = $null`. The verbatim comparison must collapse these as equal.

Candidates:
- (a) Normalize both sides to a canonical sentinel before comparing
  (`""` ≡ `@()` ≡ `$null` all map to a single token, e.g. the literal
  string `"<empty>"`).
- (b) Compare structured field-by-field with shell-native emptiness checks:
  bash `[[ -z "$field" ]]`, PS `($field -eq $null) -or ($field.Count -eq 0)`.

**PM-decided: (a).** Rationale: a single canonical sentinel produces uniform
failure-message rendering (the maintainer reads the same diff layout
regardless of which side is empty), and the normalization function becomes a
single named helper in each shell — long-term maintainability (the user's
principle). (b) leaks shell idiom into the assertion site, which makes the
two drivers' assertion code harder to keep symmetric. The Architect may
override in stage 2 IFF a concrete reason emerges (e.g. a fixture for a
truly empty `reason` field that should be flagged, not normalized away);
otherwise (a) stands.

### Q-2 — How does the PS driver parse `verify_all.sh`'s bash records?

The PS driver must read the bash records and field-split them on `|`
(matching the bash record format `anchors~tokens | reason | exclude~tokens
| gap`). Two implementations are possible:

Candidates:
- (a) PS reads `verify_all.sh` as text, extracts the `i6_banned=(...)` block
  with a regex, then for each record string splits on `|` and on `~` for the
  inner lists — same as what `test-verify-i6.ps1`'s existing `Get-ShI6Banned`
  already does at the line-text level, just deeper.
- (b) PS shells out to `bash` to source `verify_all.sh` and dump the parsed
  array (e.g. via `declare -p i6_banned`).

**PM-decided: (a).** Rationale: (b) makes the PS lockstep fail when `bash`
is missing (the WindowsApps WSL stub case T-004 already worked around for
the cross-shell parity assertion); (a) keeps the structural lockstep
self-contained — the PS driver validates `verify_all.sh` source even on a
pure-Windows host with no usable bash. The dollar-cost is one ~10-line
parser routine that mirrors `extract_i6_banned` in `test-verify-i6.sh`.
Long-term maintainability (the user's principle) favors fewer cross-shell
runtime dependencies in the test layer. The Architect may override in
stage 2 IFF (a) turns out to be fragile against a future authoring style
(e.g. multi-line records), but the current format is single-line per record
so this risk is low.

### Q-3 — Does the file-exempt fixture have to physically exist at the path?

In-scope items 12-13 talk about "fixture content at the exempt path". Two
shapes are possible:

Candidates:
- (a) The driver creates physical files inside the temp dir at the
  canonical exempt paths (e.g. `$fxTmp/scripts/verify_all.ps1` containing
  the banned phrase), then evaluates the combined predicate against those
  paths.
- (b) The driver only evaluates the combined predicate against the
  canonical path strings (no physical file at that location); the "content"
  is conceptual and lives in a single shared fixture file at a non-exempt
  path (the AC-14 file), used to verify the matcher's positive-hit path.

**PM-decided: (b) for the canonical exempt-path corpus (items 10, 11, 13);
(a) for the AC-14 negative-regression case.** Rationale:
1. The exemption test is structurally about the **path filter**, not the
   content — `verify_all` skips the file BEFORE reading any byte. A
   path-only predicate test correctly mirrors what the live code does.
2. Creating real files at literal repo paths (`scripts/verify_all.ps1`)
   inside a fixture dir requires reproducing the `scripts/` directory
   layout under the temp dir, which is incidental complexity.
3. The AC-14 case DOES need a real file at a non-exempt path because that
   case exercises the matcher (not the predicate) — the file's content is
   what gets scanned.
4. Long-term maintainability (the user's principle) favors the minimal
   fixture that exercises the contract.

The Architect may override IFF (b) misses a real coverage gap (e.g. a
hypothetical future bug where the exempt check is content-conditional
rather than path-conditional); given the current matcher design, no such
bug shape exists.

### Q-4 — Canonical exempt-file list location

The driver must own a canonical exempt-file list (item 6). Two shapes:

Candidates:
- (a) Each driver hard-codes the list as a constant near the top of the
  file (mirror of how each driver hard-codes `$i6Banned` / `i6_banned`).
- (b) The list lives in a shared data file (e.g. `scripts/i6-canonical.tsv`)
  that both drivers read.

**PM-decided: (a).** Rationale: today's driver pair already hard-codes the
banned-list canonical copy in each shell (the entire point of the
verbatim lockstep). Adding a third source of truth ((b)) trades a small
DRY win for a new artifact that itself can drift. Long-term
maintainability (the user's principle) favors fewer moving parts. The
Architect may override IFF the list grows past ~20 entries; at 7 entries
today, hard-coded is unambiguously correct.

### Q-5 — Should the new lockstep assertions also check `verify_all` source for the matcher logic itself (i6_build_regex / Build-I6Regex)?

The lockstep today guards only the **data** (`$banned` / `i6_banned`); the
matcher **logic** (the regex builder, the per-line scan loop) is identical
prose between `verify_all.{ps1,sh}` and `test-verify-i6.{ps1,sh}` but is
not asserted equal.

Candidates:
- (a) Yes — extend the lockstep to also assert the regex-builder function
  body matches between driver and live script (textual equality after
  whitespace normalization).
- (b) No — leave matcher-logic lockstep as a stage-5 (Code Review) concern.

**PM-decided: (b).** Rationale: the user-stated motivation for this task is
the two specific T-004 leftover gaps (PS structural lockstep weaker than
bash; AC-8 no permanent fixture). Adding lockstep on matcher prose is
scope creep; the existing cross-shell parity assertion (driver Assertion 2)
already catches **behavioral** divergence in the matcher, which is the
load-bearing property. A textual lockstep on function bodies would also
brittle the test against innocent refactors (e.g. renaming a local
variable). Long-term maintainability favors keeping the lockstep tight on
data, loose on prose. May be revisited in a future task if matcher prose
drift is ever observed in practice (none has been to date).

## 9. Verdict

**READY**

All five open questions (Q-1..Q-5) are framed with **PM-binding decisions**
under the user-delegated authority, per PM's dispatch instruction. None of
the questions requires a user answer before stage 2 may proceed. The
Architect may confirm or override any Q-decision in `02_SOLUTION_DESIGN.md`;
if a Q-decision is overridden in a way that materially changes scope, that
routes back through PM (per the standard pipeline contract), not back to
the user.

Inputs respected:
- T-004's archived stage docs read; AC-8's existing inline-probe coverage
  and the current `Test-I6DirExempt` / `i6_dir_exempt` shape (no
  file-exempt twin today) confirmed.
- Live I.6 blocks read at `scripts/verify_all.ps1:469-565`,
  `scripts/verify_all.sh:501-595`, `scripts/test-verify-i6.ps1:269-316`,
  `scripts/test-verify-i6.sh:242-295` — the asymmetry the task targets is
  verified to match the PM_LOG description (bash side does verbatim
  per-entry on verify_all.sh and count+entry-#10 on verify_all.ps1; PS side
  does nothing verbatim and relies on the bash twin transitively).
- PM-decided out-of-scope items (architecture.html refresh, NLP upgrade,
  manual-e2e-test.md doc fix) are explicitly recorded in §3.
- All applicable insight-index lines (L7, L17, L18, L20, L23, L26, L27,
  L28, L29) are mapped to NFRs / methodology notes; none constrains the
  in-scope behaviors in a way that would require user input.

Next stage: Solution Architect reads this document and produces
`02_SOLUTION_DESIGN.md`.
