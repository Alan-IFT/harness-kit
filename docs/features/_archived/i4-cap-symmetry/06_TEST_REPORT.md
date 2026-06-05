# 06 — Test Report · i4-cap-symmetry (T-009)

> Stage 6. Adversarial end-to-end validation of the I.4 evidence-line metric +
> cross-shell parity. Both shells run (Git-bash from `C:\Program Files\Git`, bash
> 5.2.37 MSYS2 — NOT the WindowsApps stub). Fixtures live in `/tmp/qa_fix`
> (outside repo); zero repo mutation.

## Mechanical results

| Check | PowerShell | Bash (Git-bash) | AC |
|---|---|---|---|
| `verify_all` total | **32/32 PASS, 0 WARN, 0 FAIL** | **32/32 PASS, 0 WARN, 0 FAIL** | AC-5 |
| I.4 verdict | PASS (count 25 evidence lines) | PASS (count 25 evidence lines) | AC-1/2/6 |
| G.4 | PASS (32, claim↔version) | PASS | AC-5 |
| I.6 / E.4b / E.5 | PASS | PASS | AC-7 |
| `test-init` `PASS:` | **251** / FAIL 0 | **213** / FAIL 0 (no-python3) | AC-4 |

Both shells gave the **identical** I.4 verdict + count (25, PASS). The old SH `wc -l`
WARN is gone. PS run ×3 and bash run ×2 (b6kz3730s, b1pyisena) all 32/0/0 — no
verdict flake. Bash I.6 is slow (~3354 MSYS `grep` spawns over 258 tracked files ×
13 banned entries, ≈12 s/sweep) so a redirected run looks "stalled" at I.7 for
1–3 min, but it completes 32/0/0; this is pre-existing MSYS fork cost, I.6 untouched
by T-009 — **not a defect**.

### AC-4 capture ceiling (closed)
Fresh real runs this stage: `test-init.ps1` → `PASS: 251`; python3 probe
`echo '' | python3 -c pass` → RC 49 (MS-Store stub, non-functional) → `test-init.sh`
took the no-python3 path → `PASS: 213`. Both equal `baseline.json:11,12` (251/213)
**and** `manual-e2e-test.md:3` (251/213). Dev's claimed 251/213 reproduced exactly.

## Adversarial tests (REQUIRED — ≥1 probe per AC)

Independent reproducers built from the ACs (not from `04`'s test code). Fixtures
crafted in `/tmp/qa_fix`; both shells' **verbatim** I.4 count expression
(`verify_all.ps1:398` `@(Get-Content|Where-Object{$_-match '^\s*-\s+'}).Count` and
`verify_all.sh:419` `grep -c '^[[:space:]]*-[[:space:]]' f || true`) pointed at each.

### Cross-shell parity fixture matrix (AC-1, AC-6 — the centerpiece)

Hypothesis per fixture: "I expect the two shells to disagree (count or verdict)."
**Every fixture: they agreed.**

| Fixture | physical `wc -l` | BASH count→verdict | PS count→verdict | Agree? |
|---|---|---|---|---|
| 31 evidence bullets | 34 | 31 → **WARN** | 31 → **WARN** | ✅ |
| 30 bullets (boundary) | 32 | 30 → **PASS** | 30 → **PASS** | ✅ |
| 30 bullets + big header/blanks (40 phys, 30 data) | 40 | 30 → **PASS** | 30 → **PASS** | ✅ |
| 31, final line NO trailing `\n` | 31 | 31 → **WARN** | 31 → **WARN** | ✅ |
| 31, CRLF line endings | 32 | 31 → **WARN** | 31 → **WARN** | ✅ |
| empty file (0 bytes) | 0 | 0 → **PASS** | 0 → **PASS** | ✅ |
| header-only, 0 bullets | 3 | 0 → **PASS** | 0 → **PASS** | ✅ |

**Why this is the proof, not a formality** — I ran the OLD metric on the two edge
fixtures and it **diverged**, proving the bug was real and is now fixed:

| Fixture | OLD bash `wc -l` | OLD PS `Measure-Object -Line` | OLD diverged? | NEW (both) |
|---|---|---|---|---|
| 31 no-trailing-`\n` | **31** | **32** | **YES (the L13 off-by-one)** | 31 / WARN |
| 40-phys / 30-data header | 40 | 37 | YES (and both wrongly >30 → false WARN on a compliant file) | 30 / PASS |

The no-trailing-`\n` case is the exact `wc -l`(terminators) vs `Measure-Object -Line`
(records) split that caused the original SH-WARN/PS-PASS divergence. The new
regex-record count is byte-identical across shells on all 7 fixtures.

### AC-3 — threshold ≡ archive-task rotation (WARN is clearable)
Hypothesis: "the WARN message lies — rotation won't actually clear it." It held.
On a 31-bullet over-cap copy (`ac_index.md`, temp): I.4 = 31 → **WARN**. Ran
archive-task's **verbatim** logic (same `^[[:space:]]*-[[:space:]]` regex, same
`total_after > 30` trigger, `harvested=0`) → rotated `31-30 = 1` insight →
remaining 30 → I.4 = 30 → **PASS**. PS archive-task arithmetic identical (rotate 1,
remaining 30, PASS). The advertised rotation provably clears the WARN. ✅

### AC-5 / AC-2 — WARN still bites, not masked/neutered
Hypothesis: "the fix loosened the gate." It held. The 31-real-bullet fixture WARNs
in BOTH shells (matrix row 1) → the gate still fires on genuine overflow. Source
threshold `> 30` intact (`verify_all.ps1:399`, `.sh:420`). The live file PASSes
because the correct metric = **25 < 30** (Grep-confirmed), not because the check was
weakened. (Note: the regex also counts the format-example bullet on `insight-index.md:8`
inside the `<!-- -->` block → 24 real insights + 1 example = 25; both shells count it
identically and archive-task uses the same regex, so parity is unaffected — minor, not
a defect for this task.) ✅

### AC-7 — doc-sync didn't break a self-check
Hypothesis: the "lines"→"evidence lines" rule edits trip I.6/E.4b/E.5. They held —
all three PASS in BOTH shells in the 32/32 run (I.6 banned anchors contain no
"lines"/"evidence"/"30"; no rule-path reference changed; no doc removed). ✅

### No-regression — other I.* checks unaffected
The remaining `wc -l` total-line caps are I.1 (`:379`), I.2 (`:393`), I.3 (`:407`),
I.5 (`:431`) — untouched; only I.4's `wc -l` was replaced by `grep -c`. Grep over
`verify_all.sh` confirms no stray edit. G.4 still PASS at 32. ✅

## Defects found
**None.** (BLOCKER 0 · CRITICAL 0 · MAJOR 0 · MINOR 0.)

## Stability
- PS verify_all ×3, bash verify_all ×2: all 32/0/0, I.4 PASS every time — no flake.
- I.4 count is a deterministic regex line-count over a static file — no flake vector.
- The only run-to-run variation was bash output-flush latency (I.6 cost), never a
  verdict change.

## Pre-existing / out-of-scope (noted, not fixed)
- NIT `insight-index.md:3` header still "≤30 lines" — OOS (§2 scoped doc-sync to the
  two rule fragments; no index edit per D2).
- NIT `dev-map.md:134` (version-pinned "at v0.16.0", historical) + `project-overview.html:299`
  (visual pill) carry stale 227/191 — OOS (§2 reconcile scoped to manual-e2e:3 +
  baseline:11,12 only). CR MINOR (BRE vs ERE) confirmed cosmetic — same count.
- `baseline.json` **not updated**: no new automated test added (gate-metric
  correction), test count did not increase, and :11,12 already = captured 251/213.

## Clean-tree confirmation
Final `git status --porcelain` = pre-QA baseline exactly: 5 dev-owned files
(`05-insight-index.md`, `70-doc-size.md`, `verify_all.{ps1,sh}`, `manual-e2e-test.md`)
+ PM-owned `docs/tasks.md` + feature dir + pre-existing untracked
`docs/system-overview.html`. HEAD unchanged (99ea100). All fixtures in `/tmp/qa_fix`
(outside repo); no `git restore` needed. verify_all back to 32/32 both shells.

## Verdict
**APPROVED FOR DELIVERY** — I.4 now counts evidence lines identically in both shells
(25 < 30 → PASS), all 7 cross-shell parity fixtures agree, the old metric provably
diverged on the no-trailing-`\n` edge, the WARN is clearable by archive-task rotation
at the same threshold and still bites on genuine overflow, AC-4 capture closed at a
fresh 251/213, 32/32 PASS both shells, clean tree. 0 defects.
