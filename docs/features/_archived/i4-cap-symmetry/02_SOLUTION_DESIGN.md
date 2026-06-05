# 02 — Solution Design — i4-cap-symmetry (T-009)

**Mode:** full · **Upstream verdict:** READY (01_REQUIREMENT_ANALYSIS.md §11) · **This verdict:** READY
**Design-decisions owned here:** D1–D4 (resolved below) · **Guiding principle:** UX / SE-standard / long-term maintainability.

---

## 1. Architecture summary

`verify_all`'s I.4 size check is retargeted from a *total-physical-line* count (today `Get-Content | Measure-Object -Line` in PS, `wc -l` in bash — two different implementations of the wrong metric, divergent at the no-trailing-newline boundary) to the **same insight DATA-line regex count** that `archive-task` already rotates on. After the change, I.4 in both shells, the `archive-task` rotation trigger in both shells, and the documented intent (`AI-GUIDE.md:34`) all measure one quantity: the count of `^\s*-\s+` bullet lines. The live `.harness/insight-index.md` is 25 data lines < 30, so the spurious bash WARN clears with **no edit to the index and no rotation**. Two rule fragments get a one-word wording clarification so their cap text names the metric the code now enforces. Separately, the `baseline.json` ↔ `manual-e2e-test.md` `test_init` count drift is reconciled to a single captured real run, with `baseline.json` declared canonical. No new check; count stays 32.

---

## 2. Affected modules (file paths, grounded by reading the live files)

| File | Section | Current state (read this stage) | Change |
|---|---|---|---|
| `.harness/scripts/verify_all.ps1` | I.4 block, **lines 396–404** | `$n = (Get-Content … \| Measure-Object -Line).Lines` (total lines) | Replace counting expr with shared data-line regex count |
| `.harness/scripts/verify_all.sh` | I.4 block, **lines 417–427** | `n=$(wc -l < .harness/insight-index.md)` (total lines) | Replace counting expr with shared data-line regex count |
| `.harness/scripts/archive-task.ps1` | rotate, **lines 69–76** | already counts `^\s*-\s+`, triggers `total_after > 30` | **NO CHANGE** (already canonical) |
| `.harness/scripts/archive-task.sh` | rotate, **lines 65–74** | already counts `^[[:space:]]*-[[:space:]]`, triggers `total_after > 30` | **NO CHANGE** (already canonical) |
| `.harness/rules/05-insight-index.md` | lines 5, 25 | "≤30-line append-only file" / "Max 30 lines total" (reads as total) | One-word clarify → "evidence lines" |
| `.harness/rules/70-doc-size.md` | line 27 (Caps table) | "`.harness/insight-index.md` 30 lines" | One-word clarify → "30 evidence lines" |
| `.harness/scripts/baseline.json` | lines 11, 12 | `test_init_ps_assertions: 251`, `test_init_bash_no_python3_assertions: 213` | Set to captured-run numbers (canonical source) |
| `docs/manual-e2e-test.md` | line 3 | `test-init.ps1 at 227` / `test-init.sh at 191 (no-python3)` | Set to **same** captured-run numbers as baseline.json |

> Line numbers above were re-read this stage; the RA's `:398/:419` cites the *counting* line inside each block (correct), and the block spans match `:396-404` / `:417-427`.

This is a **logic-substitution + doc-sync** task. No new module, no data model, no API, no dependency. Sections "Module decomposition / Data model / API contracts" (SA template §3–5) are **N/A** and stated so in §11.

---

## 3. Design decisions D1–D4 (resolved)

### D1 — Canonical metric: **DATA lines** (`^\s*-\s+` bullet count). CONFIRMED.

Override of total-line metric, accepting the RA's strong prior. Justification (all three reasons confirmed against live files):
- **(a) Documented intent.** `AI-GUIDE.md:34` reads "≤30 **evidence-backed lines** of project-specific facts" — the *facts* are the bullets, not the 8-line header.
- **(b) Already the rotation metric.** `archive-task.ps1:71` and `archive-task.sh:69` count exactly `^\s*-\s+` / `^[[:space:]]*-[[:space:]]` and trigger at `total_after > 30`. Picking DATA lines makes I.4 measure the *same quantity it tells the user to fix* ("archive-task auto-rotates").
- **(c) Lowest blast radius.** 3 of 4 existing sites (intent + both archive-task shells) already use this metric; only I.4 (and ambiguous rule wording) is the outlier. Candidate B (total lines) would require editing 5+ sites: trim the live file now, retune both archive-task triggers to total-line semantics, and would penalize the fixed 8-line header (leaving ~22 lines of real budget). Rejected.

Per the guiding principle: DATA lines is the SE-standard "measure what you advertise" choice and the long-term-maintainable one (one metric, three sites converge).

### D2 — Rotate the live file now? **NO.** CONFIRMED.

Re-counted this stage with the canonical regex: `Grep '^\s*-\s+'` over `.harness/insight-index.md` = **25 occurrences** (independently confirmed, not trusting RA's 25). 25 < 30 → no rotation due. Under D1 the file PASSes I.4 in both shells with **zero edits to the index**; the bash WARN was purely the 8 header lines (title + 3 blockquote + 1 blank + 3-line HTML comment) pushing `wc -l` to 33. (RA §2 note: file grew 23→25 data lines via T-007/T-008 appends since INPUT was written; defect unchanged.)

### D3 — Byte-identical cross-shell count (the subtle part). **Reuse archive-task's exact regexes — a regex-filtered line count, immune to the trailing-newline/CRLF divergence.** CONFIRMED.

**Chosen expressions (drop-in, each yields the same integer for the same bytes):**

- **PowerShell** (mirrors `archive-task.ps1:71`):
  ```powershell
  $n = @(Get-Content ".harness/insight-index.md" | Where-Object { $_ -match '^\s*-\s+' }).Count
  ```
- **Bash** (mirrors `archive-task.sh:69`):
  ```bash
  n=$(grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md)
  ```

**Why this is robust (the load-bearing reasoning):**

1. **Newline-terminator-agnostic.** The L13/RA root cause was `wc -l` (counts `\n` terminators) vs `Measure-Object -Line` (counts line *records*) disagreeing by one when the final line has no trailing `\n`. A **regex-filtered count of matching lines** sidesteps this entirely: both `Get-Content` (PS) and `grep` line-splitting treat a final unterminated line as a line, so a data bullet on the last line is counted by both whether or not a trailing newline exists. The count is over *matches*, not over *separators*.
2. **CRLF-safe.** The regex is anchored at `^` and matches `-` + whitespace near the start; trailing `\r` (Windows line endings read on Linux, or vice-versa) sits at end-of-line and never affects the leading-anchor match. `Get-Content` strips the EOL; `grep` matching `^[[:space:]]*-[[:space:]]` is unaffected by a terminal `\r`.
3. **Provably identical to the three other sites.** Both expressions are the *verbatim* regex `archive-task` already uses for rotation — so I.4(PS) ≡ archive-task(PS) ≡ archive-task(bash) ≡ I.4(bash) on what counts as "a line", satisfying AC-3 by construction (no independent reimplementation to drift).
4. **PS `\s+` vs bash `[[:space:]]` (single, no `+`) equivalence — verified, not assumed.** The two archive-task regexes differ by one detail: PS requires `-` + *one-or-more* whitespace; bash (unanchored-at-end "contains" match) requires `-` + *at least one* whitespace char. For membership ("is this a data bullet?") they are equivalent — both demand a dash followed by ≥1 whitespace. Every real insight line is `- <digit>…` (dash + single space), which both match. A pathological `-` with no following whitespace (e.g. a markdown `---` rule or `-x`) is rejected by both. I deliberately **reuse each shell's existing archive-task regex unchanged** rather than "harmonize" them, because (i) they already agree on every membership decision, and (ii) the test strategy (§8) includes a fixture proving parity, so any latent disagreement would be caught — and changing archive-task's regex is out of scope (§4 OOS-2).

**`@(...)` wrapper in PS is mandatory:** without it, a single-match result is a scalar string (`.Count` would be the string length, not 1) and a zero-match result is `$null` (`.Count` throws/0). The `@(…)` forces an array so `.Count` is always the match count — same defensive pattern `archive-task.ps1:69-71` relies on via `@()` initialization.

**`grep -c` exit-code note (bash):** `grep -c` prints `0` and **exits 1** when there are no matches (empty/headerless file). Under `set -e` (verify_all.sh runs with `set -euo pipefail` — confirm at top of file) an unguarded `n=$(grep -c …)` would abort the script on a zero-match file. Mitigation: append `|| true` →
```bash
n=$(grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md || true)
```
This mirrors archive-task.sh:69's existing `… || true` guard on the same grep. `n` is `0` (PASS) on a headerless/empty file. **Developer: confirm `set -e` state at verify_all.sh top and keep the `|| true`.**

### D4 — `baseline.json` vs `manual-e2e-test.md`: **`baseline.json` is canonical; correct `manual-e2e-test.md` to match a captured real run. No deriving mechanism.** CONFIRMED.

Current drift (read this stage): `baseline.json:11,12` = **251 / 213**; `manual-e2e-test.md:3` = **227 / 191**. Do **not** guess which is right.

**Mechanism (lowest-maintenance, scope-bound — no G.4-scale gate):**
1. **At dev time, capture a real run.** Run `.harness/scripts/test-init.ps1` and `.harness/scripts/test-init.sh` (the **no-python3** path for the bash number, per RA §5.7). Each prints `PASS: <n>` at its tail (`test-init.ps1:642`, `test-init.sh:545`). Paste both `PASS:` integers verbatim into `07_DELIVERY.md` as the captured artifact (the T-007 L32 / RA AC-4 "numbers come from a captured run, never fabricated" discipline).
2. **`baseline.json` is the single source of truth** for these counts (it is the machine-readable artifact already consumed by tests/`G.3`; `manual-e2e-test.md` is human prose). Set `baseline.json:11` = captured PS `PASS:`; `:12` = captured bash-no-python3 `PASS:`.
3. **`manual-e2e-test.md:3` is corrected to reference the same two integers** (prose stays prose; no runtime derivation). It is **not** machine-derived from baseline.json — building a derive/gate for two integers in a manual checklist is over-engineering (RA OOS §4.1; T-008 G.4 lesson: a new gate is version-worthy and unjustified here). The recurrence cost is one line of human edit per re-capture, which the captured-run discipline already forces.

**Why baseline.json canonical (not the reverse):** it is the structured artifact other tooling reads; a human checklist deriving *from* it would be acceptable but adds machinery for no measurable benefit at this scale. Declaring one canonical and hand-syncing the other is the minimal SE-standard choice. (Note: the **value** 251/213 vs 227/191 is *not* prejudged here — INPUT notes T-007 saw 251/213, but per AC-4 the Developer's fresh captured run decides; both files take whatever the run prints.)

---

## 4. Out-of-scope clarifications

- **OOS-1:** The G.4 claim↔version mechanism (T-008) is not extended. No new gate for D4.
- **OOS-2:** `archive-task.{ps1,sh}` get **no change** — confirmed by reading: both already count the data-line regex and trigger `total_after > 30`, which is exactly the metric+threshold I.4 adopts. Touching them would be a no-op refactor and risks the L13 symmetry it currently has.
- **OOS-3:** The numeric cap `30` is unchanged (RA OOS §4.3). This task fixes *what* is measured.
- **OOS-4:** Check count stays **32** (RA AC-5). No new check; see §6 risk R2 for why the "future genuine-overflow masking" concern does not justify one.
- **OOS-5:** No reconcile of any baseline metric other than the two `test_init` numbers (supervisor/verify_i6/verify_all_checks untouched — RA OOS §4.5).
- **N/A sections:** Module decomposition (§3 of SA template), Data model (§4), API contracts (§5), Sequence/flow (§6) — this is an in-place logic substitution with no new control flow.

---

## 5. Exact edit specification (Developer hand-off)

### 5.1 `verify_all.ps1` I.4 — lines 396–404

Replace **only line 398**:
```powershell
# FROM:
    $n = (Get-Content ".harness/insight-index.md" | Measure-Object -Line).Lines
# TO:
    $n = @(Get-Content ".harness/insight-index.md" | Where-Object { $_ -match '^\s*-\s+' }).Count
```
Leave lines 396–397 (Step header + `Test-Path` early-return = PASS), 399–403 (`> 30` WARN), 404 (`}`) **unchanged**. The threshold `$n -gt 30` and the early-return-PASS semantics are already correct under the new metric.

### 5.2 `verify_all.sh` I.4 — lines 417–427

Replace **only line 419**:
```bash
# FROM:
    n=$(wc -l < .harness/insight-index.md)
# TO:
    n=$(grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md || true)
```
Leave lines 417–418, 420–427 (the `> 30` WARN / `else` PASS / missing-file PASS) **unchanged**.

### 5.3 Message wording — keep accurate

Both shells' Step description string is `"insight-index.md <=30 lines"` / `"insight-index.md ≤30 lines"` and the WARN message says "$n lines". Update the user-facing text to name the metric so the message stays truthful under the new count:
- PS line 396 description → `"insight-index.md <=30 evidence lines"`; line 401 WARN → `"($n evidence lines — archive-task auto-rotates; manual overflow)"`.
- SH line 421 WARN → `"$n evidence lines — archive-task auto-rotates; manual overflow"`; line 423/426 PASS description → `"insight-index.md ≤30 evidence lines"`.

  > **Caution (Developer):** the Step **id+description string** is what `verify_all` prints and may be asserted elsewhere. Before editing the description text, grep for the literal `"insight-index.md ≤30 lines"` / `"<=30 lines"` across the repo (tests, baseline, docs). If any test or doc pins the old description string, either update it in the same symmetric edit or **leave the description unchanged and only fix the WARN message body** (`$n evidence lines`). The WARN-body wording is the load-bearing accuracy fix; the description suffix is cosmetic. Prefer the smallest edit that keeps the message truthful.

### 5.4 Rule-wording doc-sync (RA AC-7) — **SAFE to apply, do it**

I verified the self-check surface this stage:
- **I.6** banned-claims (`verify_all.ps1:487-501`) are *all* about CLAUDE.md composition/regeneration; **none** contain "lines", "evidence", "30", or "insight-index". The word swap "lines"→"evidence lines" cannot match any I.6 anchor list. The rule files are **not** in the I.6 `$exempt` list, but they don't need to be — no banned phrase is introduced.
- **E.4b** (`verify_all.ps1:225`) matches `.harness/rules/<file>.md` *path* references; the edits don't add/remove any rule-path reference. Safe.
- **E.5** (`:259`) checks doc presence only. Safe.

Apply these minimal one-word clarifications:
- `.harness/rules/05-insight-index.md:5`: "**≤30-line** append-only file" → "**≤30-evidence-line** append-only file".
- `.harness/rules/05-insight-index.md:25`: "Max **30 lines total**." → "Max **30 evidence (data) lines** (header lines are free)."
- `.harness/rules/70-doc-size.md:27` (Caps table cell): "30 lines" → "30 evidence lines".

> `05-insight-index.md` and `70-doc-size.md` are **bespoke dogfood rules** (not template-synced — insight L12: `sync-self` does not touch `.harness/rules/`). So **no template sibling** under `.../*.tmpl` needs a matching edit. Confirm with `Grep "30 lines" .harness/` that no other dogfood rule states the cap.

---

## 6. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| **R1** | A count expression still diverges PS↔bash on an edge (no-trailing-newline, CRLF, leading-whitespace bullet). | Low | Regex-filtered match count is terminator-agnostic by construction (D3 §1-2). **Proof obligation:** QA runs the §8 fixtures (31-data-line, no-trailing-newline, CRLF) and asserts byte-identical verdict. Reusing archive-task's verbatim regex means any divergence would already break rotation parity, which the existing archive-task tests guard. |
| **R2** | Switching to data-lines **masks a genuinely overflowing file** in the future (header bloats, or someone pastes a 40-line paragraph as one bullet). | Low | (a) Header bloat is bounded by design — `05/70` cap the *evidence* metric, and a runaway header is a separate doc-size concern not in this cap's contract. (b) A multi-line paste is still N bullets if multi-bullet, or 1 over-long bullet caught by the per-task "reference don't paste" discipline (`70-doc-size.md` Rule 1). (c) Adding a *second* total-line check is **version-worthy** (T-008 G.4 lesson) and **not justified** here — the documented contract is the evidence metric; do **not** add it (OOS-4). |
| **R3** | D4 reconcile picks the **wrong canonical value** (uses stale 227/191 or stale 251/213 instead of the true current run). | Medium | AC-4 mandates a **fresh captured run** pasted into `07_DELIVERY.md`; both files take whatever `PASS:` prints. The number is *not* prejudged in this design (§3 D4). QA re-runs `test-init.{ps1,sh}` and diffs against `baseline.json` — a mismatch fails AC-4. |
| **R4** | Rule-wording edit trips a verify_all self-check (I.6 / E.4b / E.5). | Very low | Verified safe this stage (§5.4): no banned anchor introduced, no rule-path reference changed, no doc removed. **Proof obligation:** Developer/QA re-run `verify_all` both shells *after* the doc edit → must stay 32/32 (RA AC-7). |
| **R5** | Editing the Step **description string** breaks a test/baseline that pins the old text. | Low | §5.3 caution: grep for the literal description before editing; fall back to WARN-body-only edit if pinned. |
| **R6** | `grep -c` aborts verify_all.sh under `set -e` on a zero-match file. | Low | `|| true` guard (D3) mirrors archive-task.sh:69. QA boundary fixture: an empty / header-only insight file → both shells PASS with count 0. |

---

## 7. Migration / rollout plan

- **Backwards compatibility:** I.4's *contract* (≤30, PASS/WARN, archive-task auto-rotates) is unchanged; only the measured quantity is corrected. No consumer of I.4's output changes shape. No data migration.
- **No feature flag** — this is a bug fix in a dogfood gate; the gate self-validates the change (NFR-2 dogfood self-gating: run the edited `verify_all` in both shells; both must be 32/32 PASS, 0 WARN on I.4).
- **Sequence:** (1) edit both `verify_all` I.4 counting lines + messages; (2) edit the two rule fragments; (3) capture `test-init.{ps1,sh}` run, set `baseline.json:11,12`, sync `manual-e2e-test.md:3`; (4) run `verify_all` both shells → 32/32; (5) run the §8 QA fixtures.
- **Rollback:** single-file-region reverts; each edit is independent (I.4 PS, I.4 bash, 2 rule lines, baseline, manual doc). No coupled migration to unwind.
- **Version:** no check added → not inherently version-worthy by the G.4 rule. PM decides whether a patch bump is warranted for a gate-metric correction; this design does **not** mandate one (no claim/version count changes).

---

## 8. Test strategy for QA

**Cross-shell symmetry (AC-1, AC-6) — the defining proof:**
1. **Live file:** run `verify_all.ps1` and `verify_all.sh`; diff the I.4 line. Both must report the same count (25) and **PASS**.
2. **31-data-line fixture (over-cap):** craft a temp insight file with 31 `^\s*-\s+` bullets (+ arbitrary header). Point both I.4 expressions at it (or temporarily swap the live file in a scratch copy). **BOTH must WARN**, identical count 31.
3. **30-data-line fixture (boundary):** 30 bullets → **BOTH PASS** (≤30). Confirms 30=PASS/31=WARN boundary parity (RA §5.4).
4. **No-trailing-newline fixture:** a file whose final line is a data bullet with **no terminating `\n`** → both shells count it identically (this is the exact `wc -l`/`Measure-Object` off-by-one that bit the old metric). Repeat with a **CRLF** variant → both agree.
5. **Empty / header-only fixture:** 0 data lines → both PASS, count 0 (R6 / `grep -c || true` guard).

**Threshold alignment with rotation (AC-3) — the "WARN is clearable" proof:**
6. With the 31-bullet over-cap fixture in place, confirm I.4 WARNs in both shells; run `archive-task` (with a harvest that pushes `total_after > 30`); confirm the rotation triggers at the **same** count, then re-run `verify_all` → I.4 PASS in both. This proves I.4's cap and archive-task's `total_after > 30` trigger measure the same quantity.

**Baseline reconcile (AC-4):**
7. Run `test-init.ps1` and `test-init.sh` (no-python3); assert `baseline.json:11` == PS `PASS:`, `baseline.json:12` == bash `PASS:`, and `manual-e2e-test.md:3` states the **same** two integers. Cite the run in the delivery.

**Doc-sync regression (AC-7):**
8. After the rule-wording edits, re-run `verify_all` both shells → still **32/32 PASS** (proves I.6/E.4b/E.5 untripped).

**Gate (AC-5):** final `verify_all` both shells → RC 0, **32/32 PASS**, 0 FAIL, 0 WARN on I.4.

---

## 9. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Data-line count (PS) | `Get-Content \| Where-Object { $_ -match '^\s*-\s+' }` | `.harness/scripts/archive-task.ps1:71` | **Reuse verbatim** — guarantees I.4≡rotation parity |
| Data-line count (bash) | `grep -E '^[[:space:]]*-[[:space:]]'` (+ `\|\| true`) | `.harness/scripts/archive-task.sh:69` | **Reuse verbatim** (as `grep -c`) — same parity reason |
| Rotation trigger / threshold | `total_after > 30` on data-line count | `archive-task.{ps1,sh}:74-76 / 72-74` | Reuse as the alignment target; **no edit** to archive-task |
| PASS/WARN reporting | `step "I.4" … "WARN"/"PASS"` (bash) · `Step … return $false` (PS) | `verify_all.sh:17,421-426` · `verify_all.ps1:396-404` | Reuse structure; swap only the counting line |
| Captured-run number for baseline | `PASS: <n>` tail of test-init | `test-init.ps1:642` · `test-init.sh:545` | Reuse as the AC-4 capture artifact; no new tooling |
| Self-check safety verification | I.6 `$banned`/`$exempt`, E.4b path-index, E.5 presence | `verify_all.ps1:225,259,470-524` | Read to prove doc edit is safe (no banned anchor / no path-ref removed) |
| Doc-size cap wording | rule fragments (bespoke, not template-synced) | `.harness/rules/05-insight-index.md`, `70-doc-size.md` | Edit in place; **no `.tmpl` sibling** (L12) |
| New module / dependency | (none needed) | — | None — pure logic substitution + doc-sync |

**No new dependency introduced.** (SA hard-rule 4 satisfied vacuously.)

---

## 10. Partition assignment

**No `.harness/agents/dev-*.md` files exist** (`Glob '.harness/agents/dev-*.md'` → none; only the 8 single-pipeline agents). This project runs **single-Developer mode** → partition table omitted per SA template §11. One Developer owns all edits; recommended dispatch order = the §7 sequence (verify_all I.4 ×2 → rule fragments ×2 → baseline+manual capture). All PS/bash edits are sibling-symmetric (RA AC-6 / insight L13/L20).

---

## 11. Verdict

**READY.** No requirement-level ambiguity (upstream READY). All four design decisions resolved with the metric, threshold, exact counting expressions, and canonical-source choice fixed; every edit is a named single-line/region substitution citing absolute file paths and read-confirmed line numbers. Self-check safety for the doc edit was verified against I.6/E.4b/E.5 this stage. Module-decomposition / data-model / API / sequence sections are N/A (in-place logic substitution). A junior Developer can implement without further design decisions; the only runtime value left open (the captured `test_init` count) is **correctly** deferred to a real run per AC-4, not guessable now.

---

DESIGN COMPLETE — D1:DATA-lines(`^\s*-\s+`) D2:no-rotate(25<30) D3:`@(Get-Content|Where-Object{$_-match'^\s*-\s+'}).Count` ≡ `grep -c '^[[:space:]]*-[[:space:]]' file || true` D4:baseline.json-canonical(manual-e2e-test corrected to captured run)
DESIGN RISK: R3(D4 reconcile value must come from a fresh captured run, not the current stale 251/213 or 227/191 — Developer must capture, not guess) · R5(verify Step-description string isn't test-pinned before renaming; fall back to WARN-body-only edit)
doc path: c:\Programs\HarnessEngineering\docs\features\i4-cap-symmetry\02_SOLUTION_DESIGN.md
