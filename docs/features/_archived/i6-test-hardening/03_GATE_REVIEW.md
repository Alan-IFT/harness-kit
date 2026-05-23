# 03 — Gate Review · i6-test-hardening (T-005)

Mode: **full**. Reviewer: gate-reviewer agent (dispatched 2026-05-23 by PM).

Inputs verified: `01_REQUIREMENT_ANALYSIS.md` (READY, 559 lines), `02_SOLUTION_DESIGN.md`
(READY, 488 lines), `PM_LOG.md`, `AI-GUIDE.md`, `.harness/rules/{05,30,70}*.md`,
`.harness/insight-index.md` (L7/L17/L18/L20/L23/L26/L27/L28/L29 relevant), live scripts
`scripts/verify_all.{ps1,sh}` (I.6 block at PS `:469-565` / bash `:501-595`) and
`scripts/test-verify-i6.{ps1,sh}`.

## 1. PM-flagged items — independent verification

### 1.1 Baseline count (PM flag #1) — design §9 is WRONG

GR counted `Assert` / `assert` invocations directly in the existing drivers.

**`scripts/test-verify-i6.ps1`** — 17 Assert sites; Assertion-1's site fires per fixture (20
fixtures); one of L245 or L264 fires mutually exclusively. Effective count:
- Assertion 1 (loop over 20 fixtures): 20
- Assertion 2 (either skip-stub or parity): 1
- Assertion 3 (L289 + L292 + L307 + L308 + L311 + L314): 6
- Assertion 4 (L323): 1
- Assertion 5 (L335 + L338): 2
- Assertion 6 (L347 + L350 + L353 + L356 + L359): 5
- **Total: 35**

**`scripts/test-verify-i6.sh`** — same counting (each `&&/||` pair fires exactly one branch):
- Assertion 1: 20
- Assertion 2: 1
- Assertion 3 (L277 + L282/283 + L286/287 + L291/292 + L294/295): 5
- Assertion 4 (L310): 1
- Assertion 5 (L318/319 + L321/322): 2
- Assertion 6 (L331/332 + L335/336 + L339/340 + L343/345 + L348/350): 5
- **Total: 34**

**Truth: PS = 35, bash = 34.** PM's measurement is correct. Design §9's "32/32 baseline" is
factually wrong. The architect's derivation `32 + 26 = 58` is internally inconsistent: it
cites a wrong baseline AND credits only 1 row as "removed/subsumed" when the new structural
lockstep actually subsumes several existing rows (PS L307 count, L308 entry-#10, L311 + L314
exempt-dir → 4 rows; bash L282/283 count, L286/287 entry-#10, L291/292 + L294/295 exempt-dir
→ 4 rows). The absolute target **58/58 may still land** but the derivation underpinning it is
unsound. Design §9 needs to be re-derived from baseline 35/34 with explicit row-by-row "added
/ removed / subsumed" accounting, OR §9 must downgrade to "target N is empirically determined
during dev; equality between PS and bash is the binding contract."

### 1.2 R-1 backtick decode (PM flag #2)

Verified in `scripts/verify_all.sh:523, 527, 529` — entries #2, #6, #8 use literal `\``
inside double-quoted strings. PS-side at `verify_all.ps1:488, 492, 494` uses single-quoted
strings with literal backticks. The two sides decode to the same canonical token only if the
PS parser performs the `\`` → `` ` `` substitution (§3.3 step 4).

The design names the step but does NOT show the exact PS expression. PS string literals make
this subtle; Dev will need `-replace '\\`', '`'` or equivalent with care. **Treat as Minor**:
"watch the PS escape" for Dev. Architect's recommendation to mutate entry #2's backtick in
stage 6 (AC-20 mutation) is sound.

### 1.3 R-3 PS case-sensitive operator discipline (PM flag #3)

Design §3.2 names `Test-I6FieldEq` (using `-ceq`) as the only PS comparator; §3.6 names
`-ccontains` for membership. Existing project pattern is consistent (`-cnotin` at
`verify_all.ps1:110`; `-cmatch` at `verify_all.ps1:439`; `-cmatch` at `test-supervisor.ps1:336`).
The grep rule the architect proposes for stage 5 is concrete and enforceable. **PASS.**

Ambiguity: design doesn't explicitly name `-cmatch` as required if any new parser code in
§3.3 / §3.4 introduces a case-sensitive regex contract. Recommend a Minor note for Dev: use
`-cmatch` where regex case sensitivity matters.

### 1.4 AC-15 assertion-name parity (PM flag #4)

Names like `... verify_all.ps1 $banned ...` must use PS `` `$banned `` or single-quoted
form — the existing `test-verify-i6.ps1:307` already does this. Bash uses `\$banned`
(existing L282). Both render the literal `$banned`. The §8 catalog is **rendering-correct**
but under-documents the source-level escape requirement. **Treat as Minor**: pre-answer for
Dev (use existing in-file pattern).

### 1.5 Q-3 honoring (PM flag #5)

Requirement item 14 (AC-14) is the only spot that explicitly needs a physical file. Items 10,
11, 13 talk about predicate evaluation against path strings. Q-3's PM-decision (b) confirmed
by design §6 / §12: one physical `fx-ac14-nonexempt.md` fixture at a non-exempt path; the
rest is path-only predicate testing. The synthetic dir-exempt path
`docs/features/some-task/03_GATE_REVIEW.md` is evaluated by predicate, not physically created.
**No hidden coupling. PASS.**

### 1.6 Doc-size policy (PM flag #6)

01 = 559 lines (over 500 soft cap per rule 70). 02 = 488 lines (under). Rule 70's I.* group
is WARN-level, not FAIL. archive-task at stage 7 handles compaction. **PASS with note**: PM
has acknowledged the overflow in PM_LOG and committed to archive-time compaction.

### 1.7 Out-of-scope discipline (PM flag #7)

Confirmed §2 of design + "Not touched" list + §12 design boundary together enumerate every
avoided surface explicitly: no `verify_all.{ps1,sh}` byte change, no banned-list / exempt-list
content change, no NLP/embedding upgrade, no architecture.html refresh, no manual-e2e-test.md
fix, no `sync-self` change, no template change, no `verify_all` public-function refactor.
**No scope creep detected. PASS.**

## 2. 8-dimension audit

| # | Dimension | Verdict | Rationale |
|---|---|---|---|
| 1 | Requirement completeness | PASS | 20 ACs all mechanically verifiable; §4 covers null/empty/non-ASCII/separator/git-absent/CJK-path; Q-1..Q-5 PM-decided; no untestable language. |
| 2 | Design completeness | PASS-with-finding | §3 covers items 1-18 via §3.1-§3.6 + §6 + §8; §13 records single-Developer mode. **Finding M-1: §9 expected-count derivation uses wrong baseline.** |
| 3 | Reuse correctness | PASS | §7 reuse-audit row-checked against live line ranges; 8 of 9 needs reused; only new code = two parsers + sentinel helpers + file-exempt predicate + canonical lists + Assertion 7. |
| 4 | Risk coverage | PASS-with-finding | R-1..R-5 addressed with concrete mitigations. **Finding m-1: §3.3 step 4 PS-escape syntax not spelled out (Minor).** |
| 5 | Migration safety | PASS | Driver pair is repo-local (not distributed); single-file revert restores v0.18.0; no external state. |
| 6 | Boundary handling | PASS | §4 names 8 boundary classes; design §3.2 sentinel resolves empty/null; §3.3 step 5 fails closed on length-not-4; §3.6 uses case-sensitive literal comparison. |
| 7 | Test feasibility | PASS-with-finding | AC-1..AC-20 each runnable. AC-17 transitively WARN from M-1. AC-15 feasible IF PS `$` escape correctly applied. |
| 8 | Out-of-scope clarity | PASS | §3 of 01 + §2 "Not touched" + §12 triangulate every avoided surface. |

## 3. High-probability questions during development (pre-answered)

**Q-Dev-1: PS `\`` → `` ` `` replacement syntax.** Use single-quoted regex literal:
`$decoded = $line -replace '\\`', '`'`. Single quotes prevent PS-level escape interpretation;
the regex engine treats `\\` as escaped backslash and `` ` `` as literal backtick.

**Q-Dev-2: PS Assert-name `$banned` literal — `` `$banned `` or `'... $banned ...'`?**
Either works. Match the existing in-file style (`test-verify-i6.ps1:307` uses `` `$banned ``
in a double-quoted string). Bash uses `\$banned`. AC-15 compares rendered output, not source.

**Q-Dev-3: Design §9 PASS: 58 math.** Baseline is 35/34, not 32/32. The absolute 58/58
target may still land but §9's derivation is unsound. **Routes back to Architect for §9
re-derivation OR downgrade to empirical-equality contract.**

**Q-Dev-4: Physical fixture files at canonical exempt paths?** **No.** Q-3 (b) honored:
canonical exempt-path corpus is path-only. Only AC-14 needs `$fxTmp/README.md` with banned
content (named `fx-ac14-nonexempt.md` for grep-ability).

**Q-Dev-5: sed-per-field PS-hashtable parser robustness.** OK for today's single-line-per-record
format. R-2 fails closed (length ≠ 4) on future wraps — don't try to support them.

## 4. Findings

### Major (blocking unless §9 is fixed)

**M-1 — Design §9 expected-count derivation is wrong-baselined.** Architect cited 32/32 as
today's PASS counts; GR counted 35 (PS) and 34 (bash) from the actual `Assert` / `assert`
invocations. The `+26 / +26 → 58` math doesn't account for the rows that the new structural
lockstep subsumes (PS: L307 count + L308 entry-#10 + L311 + L314 exempt-dir = 4 subsumed;
bash: L282/283 count + L286/287 entry-#10 + L291/292 + L294/295 exempt-dir = 4 subsumed).
AC-17 depends on §9 being correct. **Routes back to:** `02_SOLUTION_DESIGN.md` §9.
**Required fix:** re-derive from baseline 35/34 with explicit add/remove/subsume accounting,
OR downgrade §9 to "target N is empirically determined during dev; PS == bash equality and
3-run stability is the binding AC-17 contract."

### Minor (Dev can absorb; pre-answered above)

**m-1 — PS escape syntax for `` \` `` → `` ` `` in §3.3 step 4 not spelled out.** Pre-answered
in Q-Dev-1.

**m-2 — AC-15 §8 doesn't explicitly call out PS `$` escape for `$banned` / `$exempt` /
`$exemptDirs` substrings.** Pre-answered in Q-Dev-2; in-file exemplar at L307.

**m-3 — `-cmatch` not explicitly named in NFR-4 / R-3** for any new regex paths in §3.3 /
§3.4. The existing `Get-ShI6Banned` toggle uses `-match` on unambiguous literals (OK); new
parser code should use `-cmatch` where case-sensitivity matters.

**m-4 — 01_REQUIREMENT_ANALYSIS.md is 559 lines (over 500 soft cap).** PM has acknowledged in
PM_LOG; archive-task at stage 7 will compact. Not a Development blocker.

### Positive observations

- §7 reuse audit is row-by-row accurate; every cited line range exists.
- Insight-index alignment is clean: L7/L17/L20/L23 → NFR-4 / R-3; L19 → R-1; L24 → NFR-6;
  L26 → R-4; L27 → NFR-5; L28 → R-4 mitigation; L29 → NFR-6 sweep hook.
- Out-of-scope discipline is the cleanest in recent tasks: §3 of 01 + §2 + §12 triangulate.
- `--emit-hits` skip path (§5) preserves cross-shell parity assertion mechanism unchanged.

## 5. Verdict

**CHANGES REQUIRED**

Rationale: 7 of 8 audit dimensions PASS; design is conceptually sound, scope-clean,
risk-mitigated, and reuse-correct. **Dimension 2 (Design completeness) carries one Major
finding (M-1): §9's expected-count derivation is wrong-baselined (32/32 cited vs actual
35/34), undercounts subsumptions, and AC-17 depends on it.** Architect must (a) re-derive §9
from baseline 35/34 with explicit row-by-row accounting, OR (b) downgrade §9 to "target N is
empirically determined during dev; the binding contract is PS == bash and stability across 3
back-to-back runs." Either fix is ≤20 lines edit to §9. Once applied, design is implementable
as-is; minor findings m-1..m-4 are pre-answered for Dev or covered by archive-task.

### Three most critical findings

1. **M-1 (Major)** — Design §9 baseline factually wrong (32/32 cited, actual 35/34) and
   derivation undercounts subsumed rows. Route back to Architect.
2. **m-1 (Minor)** — §3.3 step 4 PS-escape for `` \` `` → `` ` `` not spelled out; pre-answered
   for Dev in Q-Dev-1.
3. **m-2 (Minor)** — §8 assertion-name catalog under-documents PS `$` escape; in-file exemplar
   at `test-verify-i6.ps1:307` shows the right form.

---

## 6. Re-review (round 2, 2026-05-23) — M-1 resolution check

Mode: **full**. Scope: §9 patch only (per PM dispatch); other dimensions not re-audited.

### What was checked

1. `02_SOLUTION_DESIGN.md` §9 — read in full after PM patch.
2. `01_REQUIREMENT_ANALYSIS.md` AC-17 — re-read for consistency.
3. Grep across §9 + rest of design for any stale "58" / "32/32" / "+26" residue.

### Verification of the three required checks

**Check 1 — Does §9 cleanly resolve M-1?** **YES.** The patched §9 takes Option (b) from
the original finding (downgrade to empirical-equality). It (i) explicitly acknowledges the
wrong-baseline error and cites the corrected PS=35 / bash=34 baseline,
(ii) replaces the absolute-N contract with a 3-clause contract — PS == bash equality,
3-run stability, and monotonic growth over baseline, (iii) gives clear rationale for why
absolute-N is the wrong contract shape, and (iv) preserves an informational landing-zone
range `[40, 80]` as a sanity check without binding it to AC-17. The contract is auditable,
falsifiable, and maintenance-resilient.

**Check 2 — Internal consistency of §9 itself.** **PASS.** No leftover `PASS: 58` /
`32/32 baseline` / `+26 / +26` inside §9. The two appearances of "58" and "+26" in §9
are explicitly framed as withdrawn/wrong. The "32/32" string appears once, also explicitly
labeled as the wrong prior baseline. No internal contradiction.

**Check 3 — Consistency with AC-17 wording.** **PASS, no edit to 01 needed.** AC-17 says
`N is a fixed expected integer (the architect chooses the exact N in stage 2; the
requirement is that N is deterministic across 3 back-to-back runs in each shell, no
flakes)`. The §9 empirical-equality contract satisfies this verbatim: §9 clause 2
("3-run stability ... emit identical `PASS:` integers on every run (no flakes)") IS
AC-17's determinism clause. AC-17 says the architect "chooses the exact N in stage 2";
§9's choice is "N is whatever the implementation produces, with the binding properties
being PS==bash, 3-run stability, and N > baseline." That is a legitimate architectural
choice within the latitude AC-17 grants the architect — AC-17 does NOT require a
pre-declared numeric literal.

### Residual cross-section finding (new, Minor)

**m-5 — §11 (Roll-forward order) still cited `PASS: 58 / FAIL: 0` at lines 435 and 437
as the expected post-edit output** — contradicting §9's deliberate withdrawal of an
absolute target. **PM-patched in the same round 2 cycle**: §11 step 1 / step 2 now read
"expect `FAIL: 0`; the absolute `PASS:` integer is implementation-determined per §9's
empirical-equality contract" and "expect `FAIL: 0` AND the same `PASS:` integer as the
bash twin in step 1 (per §9 clause 1: PS == bash equality)". m-5 resolved in place.

### Verdict (round 2)

**APPROVED FOR DEVELOPMENT**

Rationale: M-1 is cleanly resolved by the §9 patch — the empirical-equality contract is
internally consistent, factually grounded in the corrected 35/34 baseline, fully compatible
with AC-17's wording, and isolates the test from future innocent-refactor churn. The
residual m-5 (§11 stale `PASS: 58`) was PM-patched in this round 2 cycle and is now
resolved. All other findings from round 1 (m-1..m-4) remain pre-answered for Dev or covered
by archive-task as previously recorded.
