# 06 — Test Report · T-04 `skill-authoring-vocab`

**Mode:** full · **Stage:** 6 (QA Tester) · **deferred-human:** defer, do not ask
**Upstream:** 01 READY · 02 READY · 04 READY FOR REVIEW · 05 APPROVED.
**Verdict:** `APPROVED FOR DELIVERY` (see bottom). 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 1 MINOR (informational).

> Deliverable is a single additive doc edit to a dogfood rule (`.harness/rules/15-skill-authoring.md`).
> There is no runtime surface and no new automated test to author — the acceptance criteria are
> static-content + verify_all assertions, so QA validates them as an adversary against the live file
> and the project gate (`verify_all.sh`), not via a new unit test. The project's encoded safety net
> for this file is `verify_all.sh` checks **I.2** (≤200-line rule cap) and **I.6** (retired-claim
> guard); both are exercised below.

## Test plan

| Acceptance criterion | Test case(s) / probe | Evidence location |
|---|---|---|
| AC-1 all 7 named handles present (incl. checkable/exhaustive axes, context/cognitive load pair) | `grep -ic` each of the 9 handle tokens | Adversarial AC-1 below |
| AC-2 no-op→P2, leading word→P1 (generalizes) | grep the cross-ref clauses + confirm P1/P2 heading text | Adversarial AC-2 |
| AC-3 sediment/sprawl→P5+70-doc-size cap; SSOT→anti-bloat "Deliberately not adopted" | grep cross-ref clauses + confirm target text exists | Adversarial AC-3 |
| AC-4 the 3 genuinely-new carry a *(new)* marker and assert NO `→ Px` | scope-grep each new bullet for any `P[0-9]` | Adversarial AC-4 |
| AC-5 P1–P8 byte-stable (additive only) | `git diff -- 15-skill-authoring.md` hunk inspection | Adversarial AC-5 |
| AC-6 mattpocock/skills `writing-great-skills` credited; Anthropic line preserved | diff hunk 1 (provenance re-wrap) | Adversarial AC-6 |
| AC-7 final file ≤200 lines | `awk END NR` physical line count | Adversarial AC-7 |
| AC-8 verify_all green, no new FAIL/WARN (esp. I.2, I.6) | run `verify_all.sh`; I.2/I.6 PASS | verify_all result below |
| AC-9 no fan-out (plugin.json/README/CHANGELOG/skill-count/templates untouched by this task) | `git diff --name-only` + per-file T-04-footprint scan | Adversarial AC-9 |

## Boundary tests added

This is a static doc; the boundary surface is the file's hard caps and the guard it must not trip.
No runtime null/empty/concurrency inputs apply. The boundary conditions exercised:

- **Max size (200-line cap, I.2):** physical line count measured = **115** ≤ 200. PASS.
- **Banned-anchor guard (I.6 error path):** scanned the new section (lines 66–97) for every live
  banned anchor token, and the whole file for the `全程`→`中文` ordered run. None present. PASS.
- **Unicode/encoding:** file contains CJK (`中文`) and em-dashes; stays UTF-8; I.6 scans it cleanly.
- **Cross-reference integrity (dangling-pointer boundary):** every `→ Px` the new prose asserts
  resolves to a live principle whose text still matches the claim (checked literally, see AC-2/AC-3).

## Adversarial tests (REQUIRED — one per acceptance criterion)

Independent reproducers run directly against the live file and the project gate, each with a stated
failure hypothesis written before running. Verdict is based on whether the implementation **survived**.

| AC | Hypothesis ("I expect failure when…") | Reproducer (I ran this) | Outcome (tool output) |
|---|---|---|---|
| AC-1 | one of the 7 concepts is named only in the design doc, not in the live file | `grep -ic` each handle in `15-skill-authoring.md` | **Survived** — all 9 tokens count ≥1 (see output) |
| AC-2 | the P1/P2 cross-ref points at a renamed/moved principle | grep clause + confirm P1/P2 heading literal text | **Survived** — clauses present, targets match |
| AC-3 | sediment/sprawl cites a P5 that no longer says progressive disclosure, or SSOT anchor absent from "Deliberately not adopted" | grep clauses + confirm the literal phrase exists in §"Deliberately not adopted" | **Survived** — P5 + cap clause + the literal "delete duplication rather than guard it" all present |
| AC-4 | a "new" concept secretly smuggles a `→ Px` mapping | scope-grep each of the 3 new bullets for `P[0-9]` | **Survived** — 0 `P` tokens in any of the 3 new bullets |
| AC-5 | the edit silently mutated a P1–P8 line (rewrite/renumber/reorder) | `git diff -- 15-skill-authoring.md` — inspect both hunks | **Survived** — both hunks additive; P1–P8 block outside the diff, 0 deletions in the principles hunk |
| AC-6 | the mattpocock sentence overwrote the Anthropic line or dropped its URL | inspect diff hunk 1 | **Survived** — Anthropic line + URL byte-stable; sentence added by re-wrap (+2 net) |
| AC-7 | the file exceeds the 200-line I.2 cap | `awk END {print NR}` | **Survived** — 115 physical lines |
| AC-8 | the new prose trips I.6 or otherwise turns the gate non-green | `bash verify_all.sh` (×3 for stability) | **Survived** — 32/0/0 all three runs; I.2 PASS, I.6 PASS |
| AC-9 | this task also touched a fan-out file (plugin.json/README/CHANGELOG/marketplace/skill-count) | `git diff --name-only` + per-fan-out-file scan for any T-04 footprint | **Survived** — every fan-out change is attributable to siblings T-02/T-03; **0** T-04 footprint in any fan-out file |

### Evidence — AC-1 (concept presence)

```
[3] leading word
[1] completion criterion
[1] premature completion
[2] no-op
[2] sediment
[2] sprawl
[1] single source of truth
[2] user-invoked
[2] model-invoked
```
All seven required concepts (the sediment/sprawl pair and the user/model-invoked pair count as one
concept each) are present. Axes `checkable`/`exhaustive` and the load pair `context load`/`cognitive
load` are named inline in their bullets (verified in the AC-3/AC-4 bullet bodies below).

### Evidence — AC-2 (leading word → P1, no-op → P2)

```
73:  behaviour for the fewest tokens. Generalizes **P1** ("write for the model"): word the
76:  a no-op: you pay load to say what the model already does. The named handle for **P2** ("don't
```
Targets exist and match the claim:
```
25:1. **Write the description for the model, not the human.** …
31:2. **Don't state the obvious.** …
```

### Evidence — AC-3 (sediment/sprawl → P5 + cap; SSOT → "Deliberately not adopted")

```
88:  **sprawl** is length itself even when every line is live and unique. Cure both via the **P5**
46:5. **Progressive disclosure — load by trigger, not all at once.** …
50:   … Keep every file under its
[70-doc-size.md referenced on line 89]
```
SSOT anchor literally present inside §"Deliberately not adopted" (wrapped 103–104):
```
delete
  duplication rather than guard it
```

### Evidence — AC-4 (3 new concepts: *(new)* marker, NO P-mapping)

```
78:- **Completion criterion** *(new — no prior handle)* …  → P[0-9] in bullet: NONE
82:- **Premature completion** *(new — no prior handle)* …  → P[0-9] in bullet: NONE
94:- **User-invoked vs model-invoked** *(new lens)* …       → P[0-9] in bullet: NONE
```
Completion-criterion bullet names both axes ("checkable"/"exhaustive"); user/model-invoked bullet
names both loads ("context load"/"cognitive load"). None of the three asserts a `→ Px` mapping.

### Evidence — AC-5 / AC-6 (additive byte-stability)

`git diff -- .harness/rules/15-skill-authoring.md` shows exactly two hunks:
- **Hunk 1** `@@ -6,8 +6,10 @@` — intro re-wrap that appends the mattpocock provenance sentence;
  the Anthropic attribution line and its URL are unchanged (re-wrapped, not removed). Net +2 lines.
- **Hunk 2** `@@ -61,6 +63,39 @@` — pure-add of the `## Named vocabulary` section between P8 and
  `## Deliberately not adopted`; **0 deletions**.

The P1–P8 principle bodies fall outside both hunks → byte-stable. AC-5 and AC-6 both hold.

### Evidence — AC-9 (no fan-out attributable to T-04)

The working tree is shared with siblings and shows many modified files. Per-file scan of every
fan-out target for a T-04 footprint (`skill-authoring|mattpocock|named vocabulary|leading word|…`):

```
.claude-plugin/plugin.json      no T-04 footprint
.claude-plugin/marketplace.json no T-04 footprint
README.md                       no T-04 footprint
README.zh-CN.md                 no T-04 footprint
CHANGELOG.md                    no T-04 footprint
```
The version bump (0.33.0 → 0.35.0), CHANGELOG headers, README skill-count, and verify_all C.1/G.x
edits are explicitly authored by **T-03 (`harness-grill`, skill 15→16)** and **T-02
(`context-glossary`)** — both named in the CHANGELOG diff. T-04's mutation footprint is exactly:
`.harness/rules/15-skill-authoring.md` + the untracked `docs/features/skill-authoring-vocab/` docs.
No plugin.json / README / CHANGELOG / skill-count / templates edit is attributable to T-04.

## verify_all result

- Gate command: `bash .harness/scripts/verify_all.sh` → **PASS 32 / WARN 0 / FAIL 0** (exit 0).
- **I.2** (rule fragments ≤200 lines each): **PASS**.
- **I.6** (no retired-claim phrases): **PASS**.
- Total tests/checks: **32 → 32** (this task adds no check — design honored [[feedback_design_over_guards]]).
- Pass: 32 · Fail: 0 · Warn: 0.
- New automated tests added: **0** (static doc edit; AC surface is verify_all I.2/I.6 + content asserts, all green).
- Baseline updated: **no T-04-attributable change.** `verify_all_checks` stays 32. The baseline.json
  diff present in the tree (test_init_bash 270→273, last_verify date) is sibling-attributable
  (T-03 test-init.sh for the 16th skill), not T-04. Baseline not regressed; nothing to raise for this task.

### PowerShell twin (operator-pending)

`verify_all.ps1` is denied to sub-agents (PowerShell blocked in this environment) — **not run, not
faked**, marked **operator-pending**. The `.sh` twin is authoritative for this stage. For I.6 the
banned-anchor list is the 1:1 twin of the `.ps1` list (asserted in lockstep by the verify-i6 test
pair), so the I.6 result transfers; the `.ps1` run remains the PM/operator's to confirm.

## Defects found

- **[MINOR / informational]** Line-count drift in upstream stage docs: 04_DEVELOPMENT.md and 02 say
  **115**, 05_CODE_REVIEW.md says **116**; the live file is **115** (`awk END NR`). Cosmetic
  metadata inaccuracy in the docs, not in the deliverable; both values are far under the 200 cap.
  No action required; recorded for accuracy. Reproducer: `awk 'END{print NR}' .harness/rules/15-skill-authoring.md` → 115.

No BLOCKER, CRITICAL, or MAJOR defects.

## Stability

- `verify_all.sh` ran **3 times**; each run: 32/0/0 with I.2=PASS and I.6=PASS. No flakes observed. ✅

## Verdict

**APPROVED FOR DELIVERY.**

All 9 acceptance criteria survived independent adversarial reproducers; verify_all.sh is 32/0/0 with
I.2 and I.6 both PASS and stable across 3 runs; the file is 115 ≤ 200 lines; the edit is provably
additive (P1–P8 byte-stable, two additive hunks); the 3 genuinely-new concepts carry a *(new)*
marker and assert no false `→ Px` mapping; the 4 mapped concepts resolve to live principles whose
text matches the claim; and no fan-out artifact (plugin.json / README / CHANGELOG / marketplace /
skill-count / templates) is attributable to T-04. One MINOR informational doc line-count drift, no
action required. The `verify_all.ps1` twin is operator-pending (PowerShell denied; not faked).
