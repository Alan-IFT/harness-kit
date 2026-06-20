# 06 — Test Report · sa-design-vocab (T-07)

> Stage 6 (QA Tester). Mode: full (final task of batch). deferred-human mode: defer, do not ask.
> Scope: T-07's 6 files only (T-02…T-06 working-tree churn excluded; verified vs pre-T-07 state 0.37.0 / 16 skills).
> Upstream: 01/02 READY, 03 APPROVED FOR DEVELOPMENT, 04 READY FOR REVIEW, 05 APPROVED (0 CRIT/MAJOR/MINOR, 1 source-justified NIT).
> This is a prose/content + version-fanout change: no new automated test file is added (nothing in the suite encodes agent prose); the source of truth is `verify_all` (G.3/G.4/I.3/I.6) plus the targeted adversarial probes below.

## Test plan

| Acceptance criterion | Test case(s) / probe | Evidence |
|---|---|---|
| AC-1 seven terms, one line each | grep `^- **<Term>**` in section 124-144 | 7/7 matched (Module/Interface/Depth/Seam/Adapter/Leverage/Locality) |
| AC-2 deletion test + interface-is-test-surface + one-vs-two-adapter | read lines 140-142 | all three present, one line each |
| AC-3 interface = everything a caller must know (not just signature) | read line 131 | "everything a caller must know … the type signature *and* invariants, ordering constraints, error modes, required config, and performance characteristics. Broader than the signature alone." |
| AC-4 optional framing + 12-section contract byte-unchanged | grep affordance/mandate + diff hunk-range check on lines 14-29 | affordance present, mandate absent; output contract 14-29 outside all diff hunks |
| AC-5 design-it-twice / DEEPENING name-only | grep section for procedure/parallel/category names | single combined deferred-pointer line (144); no procedure, no dispatch shape |
| AC-6 additive (lines 1-122 unchanged by T-07) | `git diff` hunk headers | only T-07 hunk = @119,3→+120,25 (insertion-only append) |
| AC-7 ≤300 lines | `wc -l` | 144 ≤ 300 |
| AC-8 0.38.0 ×4 + CHANGELOG [0.38.0], counts 16/8/32 | grep 4 stamps + CHANGELOG + count tokens | all 0.38.0; counts restated unchanged |
| AC-9 verify_all PASS, total stays 32 | `bash verify_all.sh` | PASS 32 / WARN 0 / FAIL 0 |

## Boundary tests added

No new automated test files (agent-prose payload — the suite does not encode prose; `verify_all` G.3/G.4/I.3/I.6 are the encoded gates). Boundary checks exercised as probes:
- **Cap boundary (I.3):** file = 144, against the ≤300 agent cap → 156-line headroom.
- **Fence boundary (gate Q2):** zero backtick fences inside the new section 124-144; no `` ```markdown `` and no four-backtick fence introduced.
- **Forward-path boundary (Hard rule 6 / I.6):** no `name.ext:NNN` literal in the new prose; the one `02_SOLUTION_DESIGN.md` token is a negation with no line number.
- **Count-flip boundary:** README line-5 `32%2F32`, `308`, `90`, MIT badges intact; 16/8/32 tokens unchanged; CHANGELOG restates them unchanged.
- **Version-consistency boundary (G.4):** 0.38.0 on all four stamp surfaces + matching dated `## [0.38.0]` CHANGELOG heading.

## Adversarial tests (REQUIRED, one per acceptance criterion)

Each row states a failure hypothesis, an independent reproducer I ran, and the captured outcome. Verdict is based on whether the implementation **survived** the probe.

| AC | Hypothesis ("I expect failure when…") | Reproducer (I ran this) | Outcome (tool output) |
|---|---|---|---|
| AC-1 | a term is missing or split across 2 lines | `sed -n '124,144p' … | grep -cE '^\- \*\*(Module|Interface|Depth|Seam|Adapter|Leverage|Locality)\*\*'` | Survived — `7` |
| AC-2 | one of the 3 principles is missing/fused | `sed -n '140,142p'` read | Survived — deletion test (140), interface-is-test-surface (141), one-vs-two-adapter (142), each one line |
| AC-3 | interface defined as just the type signature | `sed -n '131p'` | Survived — "everything a caller must know … *and* invariants, ordering constraints, error modes, required config, and performance characteristics. Broader than the signature alone." |
| AC-3b | depth paraphrased as impl/interface line ratio (source-rejected reading) | `sed -n '132p'` | Survived — "leverage per unit of interface … (not the impl-to-interface line ratio)" — the rejected reading is explicitly negated |
| AC-4 | a mandate word ties vocab to a required 02 field | `grep -niE 'must use|required (section|field) in .02|in every design|you must'` on 124-144 | Survived — `NONE`; affordance present ("(optional lens)" heading + "may" + "not a checklist … not a required `02_SOLUTION_DESIGN.md` field") |
| AC-4b | output contract (14-29) silently edited | `git diff HEAD` hunk headers; 14-29 ∉ {@42,15 ; @119,3} | Survived — contract lines 14-29 are outside every diff hunk (byte-unchanged) |
| AC-5 | a design-it-twice procedure or sub-agent-dispatch shape leaked in | `grep -niE 'design-it-twice|parallel'` on 124-144 | Survived — single line 144 names it as a deferred future option; no procedure, no dispatch shape |
| AC-6 | an existing line (1-122) was reworded by T-07 | `git diff HEAD -- agents/solution-architect.md` (T-07 hunk = `@@ -119,3 +120,25 @@`) | Survived — the sole T-07 hunk is an insertion-only append after line 122; all `+` lines (see note on the @42 hunk below) |
| AC-7 | append pushed file over the 300-line cap | `wc -l < agents/solution-architect.md` | Survived — `144` |
| AC-8 | a stamp left at 0.37.0, or a count token flipped | grep 4 stamps + CHANGELOG + count tokens | Survived — 0.38.0 ×4 + `## [0.38.0]`; 16/8/32 + 32%2F32/308/90 intact |
| AC-9 | verify_all FAILs or check total drifts off 32 | `bash .harness/scripts/verify_all.sh` | Survived — PASS 32 / WARN 0 / FAIL 0 |
| Gate Q2 | a stray ` ```markdown ` / four-backtick fence copied into 124-144 | `sed -n '124,144p' | grep '```'` and `grep '````'` | Survived — `NONE` in section; only 4 PRE-EXISTING fences in file (71/79 Reuse-audit, 83/104 Partition) |

### Captured tool output (evidence)

verify_all.sh summary:
```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

G.3 / G.4 / I.3 / I.6 line items (from the same run): `[G.3] Version stamps consistent … PASS`, `[G.4] Doc count/version claims consistent … PASS`, `[I.3] Agent definitions ≤300 lines each … PASS`, `[I.6] No retired-claim phrases … PASS`.

Fence probe:
```
$ sed -n '124,144p' agents/solution-architect.md | grep -n '```'  → (no output)  NONE
$ grep -n '```' agents/solution-architect.md → 71:```markdown  79:```  83:```markdown  104:```   (all pre-existing)
$ grep -n '````' agents/solution-architect.md → NONE-four-backtick
```

Additive probe (T-07 hunk):
```
$ git diff HEAD -- agents/solution-architect.md | grep '^@@'
@@ -42,15 +42,16 @@   ← Workflow CONTEXT.md soft-dep + renumber = T-02 prior-batch churn, NOT T-07
@@ -119,3 +120,25 @@  ← T-07's only hunk: insertion-only append after line 122
```

Version probe:
```
plugin.json:4  "version": "0.38.0"   marketplace.json:17 "version": "0.38.0"
README.md:5 version-0.38.0-blue       README.zh-CN.md:5 version-0.38.0-blue
CHANGELOG.md:8 ## [0.38.0] - 2026-06-20  (restates 16 skills / 8 framework agents / 32 checks unchanged; no new check; no I.6 list change)
```

### Note on the `@@ -42,15 @@` diff hunk (prior-batch churn, not a T-07 defect)

`git diff HEAD` is against committed HEAD `93fbfbb` (v0.33.0). The 04_DEVELOPMENT.md record warns the working tree carries uncommitted T-02…T-06 batch work. The `@@ -42,15 @@` hunk (Workflow step 5 = CONTEXT.md soft-dependency + step renumber 6-11) is **T-02's** footprint, already present in the live file before T-07; it is not in T-07's declared 6-file footprint and does not touch the 12-section output contract (lines 14-29) nor the new section. T-07's own footprint is exactly the `@@ -119,3 +120,25 @@` insertion-only append. Confirmed additive for T-07.

### Note on the `verify_all.sh` diff (prior-batch, check-strengthening, not circumvention)

`git diff HEAD` also shows `verify_all.sh` changed (6 ins / 6 del at C.1/G.1/G.2): adding `harness-grill` as the 16th required skill and flipping the "15 skills"→"16 skills" labels. This is **T-03's** footprint (the legitimate origin of the "16 skills" count the README/CHANGELOG now claim), it is outside T-07's 6-file footprint, and it **strengthens** a presence check (adds a required skill) — it does not weaken any gate to make T-07 pass. QA hard rule 6 (no weakening verify_all to pass) is honored: T-07 edited none of `verify_all`'s checks.

## verify_all result
- Total checks: 32 → 32 (unchanged; no new check, AC-9).
- Pass: 32
- Fail: 0 (required 0 to approve) ✅
- Warn: 0
- New automated tests added: 0 (agent-prose payload; the encoded gates are G.3/G.4/I.3/I.6, all PASS).
- Baseline updated: no change needed — check count stays 32, `last_verify` already 2026-06-20, no test-suite assertion count moved by this content change. Baseline preserved (not lowered).

## Defects found
- None. 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR.
- (Carry-forward from CR 05: 1 NIT — British "behaviour" in the new section, source-faithful to `codebase-design/SKILL.md`; non-blocking, no action.)

## Stability
- `verify_all.sh` ran clean (PASS 32 / WARN 0 / FAIL 0). The adversarial probes are deterministic file/grep/diff checks (no timing, no concurrency, no randomness) — not flake-prone. No instability observed. ✅

## Operator-pending (PowerShell denied to this agent — not faked)
- `.harness/scripts/verify_all.ps1` — present but NOT run (PS denied). Cross-shell parity is unaffected by this content change (no script edited by T-07), but the PS run is an operator-pending confirmation, not an executed result. Do not treat as verified-green until an operator runs it.

## Verdict
**APPROVED FOR DELIVERY** — 0 defects (0 BLOCKER/CRITICAL/MAJOR/MINOR). 9/9 ACs survive independent adversarial probes; gate-Q2 fence clean; additive (T-07 hunk insertion-only, lines 1-122 & output contract 14-29 byte-unchanged); source fidelity held (interface = everything a caller must know; depth = leverage per unit of interface, line-ratio reading explicitly rejected); design-it-twice name-only; no count flip (16/8/32 + 32%2F32/308/90 intact); version 0.38.0 ×4 + CHANGELOG [0.38.0]; I.3 144≤300; I.6 clean; `verify_all.sh` PASS 32/0/0. Operator-pending: `verify_all.ps1` (PS denied). PM may close T-07 as the final batch task.
