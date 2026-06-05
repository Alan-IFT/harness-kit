# 01 — Requirement Analysis — i4-cap-symmetry (T-009)

**Mode:** full · **Verdict:** READY · **Design-decisions deferred to SA:** 4

---

## 1. Goal

Make the insight-index size cap (`verify_all` I.4) measure the documented "evidence/data
lines" metric identically in PowerShell and Bash and identically to `archive-task`'s rotation
trigger, so that I.4 is cross-shell symmetric, truthful, and any WARN it emits is clearable by
the auto-rotation it advertises; and reconcile the `baseline.json` ↔ `manual-e2e-test.md`
`test_init` counts from a captured real run.

---

## 2. Grounded current state (read, not assumed)

| Site | Metric today | Value on live file |
|---|---|---|
| `verify_all.ps1:398` (I.4) | total physical lines, `Get-Content \| Measure-Object -Line` | lands ≤30 in this env → **PASS** |
| `verify_all.sh:419` (I.4) | total physical lines, `wc -l < file` | **33** → **WARN** |
| `archive-task.ps1:71` (rotate) | DATA lines, `Where-Object { $_ -match '^\s*-\s+' }` | counts data only |
| `archive-task.sh:69` (rotate) | DATA lines, `grep -E '^[[:space:]]*-[[:space:]]'` | counts data only |
| `archive-task.{ps1,sh}:76/74` rotation trigger | `total_after > 30` where `total_after` = DATA-line count + harvested | DATA-line semantics |
| `AI-GUIDE.md:34` (documented intent) | "≤30 **evidence-backed lines** of project-specific facts" | DATA-line semantics |
| `.harness/rules/05-insight-index.md:5,25` | "≤30-line append-only file" / "Max 30 lines total" | wording is ambiguous (reads as total) |
| `.harness/rules/70-doc-size.md:27` | "`.harness/insight-index.md` 30 lines" | wording is ambiguous (reads as total) |

**Live `.harness/insight-index.md` exact counts (captured this stage):**
- Total physical lines: **33**.
- DATA lines (`^\s*-\s+` bullets, lines 10–33): **25** (Grep-confirmed; this is the same regex `archive-task` rotates on).
- Header / structural (non-data) lines: **8** (33 − 25): title, 3 blockquote lines, 1 blank, 3-line HTML comment.

> Note vs INPUT: INPUT cited 23 data lines / 30 total; the live file has grown to **25 data lines / 33 total** because T-007 and T-008 each appended one insight (lines 32, 33) after INPUT was written. The defect is unchanged: under the documented DATA metric the file is **25 < 30** (no rotation due, WARN is false); only the 8 header lines push the total over 30 in the SH path.

**Root cause of the cross-shell L13 divergence:** PS `Measure-Object -Line` and bash `wc -l` are
*both* total-physical-line counters but disagree by one at the boundary because `wc -l` counts
newline terminators while `Measure-Object -Line` counts line records — a final line without a
trailing newline is counted by `Measure-Object` but not by `wc -l` (and vice-versa for a trailing
blank line). So even if both kept the total-line metric, they would not be guaranteed equal. The
defect is two-fold: (a) **wrong metric** (total vs documented DATA), and (b) **two different
implementations of that wrong metric** that disagree by one.

---

## 3. In-scope behaviors (numbered, testable)

1. I.4 in `verify_all.ps1` and I.4 in `verify_all.sh` compute the **same numeric quantity** from
   the same `.harness/insight-index.md`, using the **same definition** of "a counted line".
2. The quantity I.4 counts is the **documented insight-index cap metric** (the metric that
   `AI-GUIDE.md:34` and `05-insight-index.md` describe).
3. I.4's PASS/WARN verdict for any given `.harness/insight-index.md` is **identical across the two
   shells** (no file exists for which PS PASSes and SH WARNs, or vice-versa).
4. The quantity I.4 counts is the **same quantity** `archive-task.{ps1,sh}` use to decide rotation
   (the `total_after > 30` trigger), so an I.4 WARN is, by construction, an over-threshold state
   that running `archive-task` reduces.
5. On the **current live file** (25 data lines / 33 total), I.4 reaches a single deterministic
   verdict in both shells consistent with the chosen metric (SA decision D1 fixes which verdict;
   see §6).
6. `verify_all` ends at **32/32 PASS in both shells, 0 FAIL** (the SH I.4 WARN resolves to PASS;
   RC 0 in both). The total check count remains **32** unless the SA adds a check with explicit
   justification + version bump (T-008 G.4 lesson).
7. `baseline.json:11,12` (`test_init_ps_assertions`, `test_init_bash_no_python3_assertions`) and
   `manual-e2e-test.md:3` (`test-init.ps1` / `test-init.sh` no-python3 assertion counts) state the
   **same two numbers**, set from a single captured real run of `test-init.{ps1,sh}`.
8. Every code edit is applied symmetrically to the PS and Bash siblings (insight L13/L20): I.4 in
   both `verify_all` shells; if `archive-task` is touched, both `archive-task` shells.
9. **In-scope doc-sync (conditional):** if the chosen I.4 metric makes the wording in
   `05-insight-index.md` (lines 5, 25) and/or `70-doc-size.md` (line 27) materially misleading
   (i.e. they read as "total physical lines" when the cap now counts evidence lines), the wording
   is corrected to name the evidence/data metric — provided that editing those rule files does not
   itself trip a `verify_all` self-check (verify against I.6 retired-claim scan and E.4b / E.5
   indexing before and after the edit; the edit is gated by AC-5).

---

## 4. Out of scope

1. The G.4 claim↔version mechanism (delivered in T-008) — not extended here.
2. Any `archive-task` change beyond aligning its rotation **metric/threshold** to I.4 (no broad
   rotation-algorithm refactor, no change to where rotated lines land).
3. Changing the **numeric cap value 30** — this task fixes *what is measured*, not the limit.
   (If the SA finds the number itself wrong, that is a separate flagged decision, not a default.)
4. Adding a new `verify_all` check / changing the check count from 32 — excluded unless the SA
   produces an explicit justification and the accompanying version bump.
5. Reconciling any baseline/doc counts other than the two `test_init` numbers named in AC-4
   (the other baseline metrics — supervisor, verify_i6, verify_all_checks — are not in scope).
6. Re-deriving or re-validating the *content* of the insights themselves.

---

## 5. Boundary conditions

1. **Missing file:** `.harness/insight-index.md` absent → I.4 must reach the same verdict in both
   shells (today both treat absent as PASS-equivalent: PS early-returns at `:397`, SH `:426` emits
   PASS). Behavior preserved and symmetric.
2. **Empty file (0 bytes / 0 data lines):** count = 0 ≤ 30 → PASS in both shells.
3. **No-trailing-newline final line:** the chosen count must be identical whether or not the file
   ends in a newline (this is the exact `wc -l` vs `Measure-Object -Line` off-by-one that caused
   the L13 divergence). The metric definition must be newline-terminator-agnostic.
4. **Exactly at the cap (count == 30):** `≤30` is PASS; `>30` is WARN. Both shells and
   `archive-task` (`> 30` triggers rotation) must agree on the boundary so that 30 = PASS / no
   rotation, 31 = WARN / rotate-by-1.
5. **Data line with leading whitespace / blank lines among bullets:** the counted-line definition
   (`^\s*-\s+` family) must match `archive-task`'s regex exactly so I.4 and rotation never disagree
   on what is a "line".
6. **CRLF vs LF line endings:** this repo is edited on Windows and Linux; the count must be stable
   across line-ending style (relevant to both `wc -l` and `Measure-Object -Line`).
7. **baseline reconcile — python3 present vs absent:** `test-init.sh` reports a different assertion
   count with/without python3 (per `manual-e2e-test.md:3`: 191 no-python3 / 227 with). The
   reconciled SH number is specifically the **no-python3** count (the column both
   `baseline.json:12` and the manual doc track). The captured run must record which python3 state
   produced it.

---

## 6. Design decisions deferred to SA (framed, not decided)

> RA frames the trade-offs; SA picks the mechanism. These are the four "design crux" items from
> INPUT, refined against the grounded numbers.

**D1 — Which metric is canonical: DATA lines or TOTAL physical lines?**
- *Candidate A (DATA lines, `^\s*-\s+`):* aligns I.4 with the documented intent (`AI-GUIDE.md:34`
  "evidence-backed lines"), with `archive-task`'s existing rotation regex, and makes the 8-line
  fixed header free. Under this metric the live file is 25 < 30 → WARN clears with no edit to the
  index. Cross-shell symmetry is achievable via a shared regex count (`grep -c` / `-match` count).
- *Candidate B (TOTAL lines):* keeps the literal "≤30-line file" reading but penalizes the fixed
  header (8 lines today), leaving only ~22 evidence lines of real budget, and requires either
  trimming the live file now or changing `archive-task` to rotate on total lines.
- *RA observation (not a decision):* A is consistent with 3 of 4 existing sites (intent + both
  archive-task shells); B is consistent with 1 (the literal rule wording). A is lower-blast-radius.
  SA decides; if SA picks B, AC-2's branch (rotate the file + retune archive-task) activates.

**D2 — Does the live file need rotation now?**
- Determined entirely by D1: under A, 25 < 30 → no rotation, WARN clears by metric change alone.
  Under B, 33 > 30 → the file is rotated/trimmed and `archive-task`'s trigger is retuned to match.

**D3 — How to guarantee PS and Bash count identically.**
- Whatever metric D1 selects, the SA specifies a counting method that yields the *same integer* in
  both shells for the same bytes, including the no-trailing-newline and CRLF edge cases (§5.3,
  §5.6). The current `Measure-Object -Line` vs `wc -l` pair is *not* guaranteed equal even on the
  same metric and must be replaced/normalized. Mechanism (shared regex count vs normalized total)
  is the SA's; the requirement is bit-for-bit verdict parity (AC-1).

**D4 — `baseline.json` vs `manual-e2e-test.md`: which is canonical, and prevent future drift?**
- The two disagree (baseline 251/213 vs manual 227/191). INPUT notes T-007 reported 251/213 from a
  real run (baseline may be current, manual stale) — **but this stage does not assume that**; the
  number is set from a fresh captured run (AC-4). SA decides whether one file should *derive* from
  the other (or from a run artifact) to stop recurrence, scope-bound — no G.4-scale mechanism
  (out of scope §4.1).

---

## 7. Acceptance criteria (verifiable; refines INPUT AC-1..AC-6)

- **AC-1 (metric correctness + symmetry):** For the live `.harness/insight-index.md`, `verify_all.ps1`
  I.4 and `verify_all.sh` I.4 emit the **same verdict** (PASS or WARN) and, where observable, the
  **same reported count**, and that count is the metric chosen in D1.
  *Verify:* run both shells; diff the I.4 line. Additionally feed a crafted 31-data-line fixture and
  a 30-data-line fixture; both shells flip verdict at the same boundary.
- **AC-2 (current file passes / or is rotated):** Under D1=A, I.4 **PASSes in both shells** on the
  unmodified live file (false WARN gone). Under D1=B, the live file is rotated to satisfy the cap
  **and** `archive-task`'s trigger matches the I.4 cap.
  *Verify:* run both shells on the live file → I.4 PASS in both (branch A), or run `archive-task`
  then re-run and confirm I.4 PASS + rotation occurred (branch B).
- **AC-3 (threshold alignment):** I.4's counted quantity and threshold equal `archive-task`'s
  rotation counted quantity and threshold, so a WARN state is one that `archive-task` reduces.
  *Verify:* construct a 31-line over-cap fixture, confirm I.4 WARNs in both shells, run
  `archive-task`, confirm I.4 then PASSes in both shells (the advertised rotation actually clears it).
- **AC-4 (baseline reconcile):** `baseline.json:11` == `manual-e2e-test.md` `test-init.ps1` count
  and `baseline.json:12` == `manual-e2e-test.md` `test-init.sh` (no-python3) count, both equal to a
  **captured real run** recorded in the delivery.
  *Verify:* the two files state identical numbers; the delivery cites the run that produced them.
- **AC-5 (gate green, 32/32, no silent new check):** `verify_all` exits **RC 0 with 32/32 PASS in
  both PowerShell and Bash, 0 FAIL, 0 WARN on I.4**. Check count remains 32; if the SA adds a check,
  the delivery contains the justification + the `plugin.json`/claim version bump (G.4 stays green).
  *Verify:* run `.harness/scripts/verify_all` in both shells; assert RC 0 and "32/32".
- **AC-6 (PS/Bash edit symmetry, L13):** every changed behavior is present in both shells; no
  shell-only edit. *Verify:* the I.4 verdict-parity test (AC-1) is the behavioral proof; reviewer
  confirms each touched `.ps1` has its `.sh` sibling edited and vice-versa.
- **AC-7 (doc-sync, conditional — §3.9):** if rule wording was corrected, `05-insight-index.md`
  and/or `70-doc-size.md` name the evidence/data metric consistently with the fixed I.4, **and**
  `verify_all` (including I.6 retired-claim and E.4b/E.5 indexing) stays PASS after the edit.
  *Verify:* re-run `verify_all` both shells post-doc-edit → still 32/32 PASS. (If no rule wording
  was misleading under the chosen metric, this AC is N/A and the delivery states so.)

---

## 8. Non-functional requirements

1. **Cross-shell determinism (L13/L20):** the single hard NFR — PS and Bash must be byte-identical
   in verdict on identical input. This is the defining property of the task, captured testably in
   AC-1/AC-3/AC-6.
2. **Dogfood self-gating:** this is the harness repo itself; the edited `verify_all` gates its own
   change. The post-change run must be clean in the same shell that ran the change (no "passes on
   my machine" — both shells run).
3. **No performance/security surface:** I.4 reads one small file; no perf or security NFR is material.

---

## 9. Related tasks

- **T-007** (`docs/features/_archived/` — script relocation to `.harness/scripts/`): source of the
  `test_init` real-run numbers (251/213) cited in INPUT; introduced insight L31 (root-derivation
  hazard) and L32 (fabricated-tally lesson). Relevant to AC-4's "capture from a real run" discipline.
- **T-008** (G.4 claim↔version gate, v0.21.0): source of the "adding a check needs a version bump"
  constraint behind AC-5; insight L33. The G.4 gate must stay green across this task's edits.
- **Standing insights consulted in `.harness/insight-index.md`:** L13/L20 (cross-shell PS/bash
  operator + count symmetry — the core hazard class here), L26/L27 (I.6 matcher + exempt-file
  discipline — relevant to the conditional doc-sync AC-7 not tripping I.6).
- **SPECs:** no `docs/spec/` SPEC governs insight-index sizing beyond the two rule fragments already
  cited (`05-insight-index.md`, `70-doc-size.md`); both are read-only inputs and the canonical
  statement of intent alongside `AI-GUIDE.md:34`.

---

## 10. Open questions for user

None. The user supplied the governing principle (the cap means the documented evidence/data-line
metric; INPUT §Goal + design crux). The four remaining choices are **design** decisions correctly
owned by the SA (§6), not requirement ambiguities. No user bounce required.

---

## 11. Verdict

**READY.** No requirement-level ambiguity remains; 4 design decisions (§6) are framed and deferred
to the SA. The single hard constraint is cross-shell verdict parity (NFR-1) ending at 32/32 PASS in
both shells, 0 FAIL, with the SH I.4 WARN resolved to PASS.
