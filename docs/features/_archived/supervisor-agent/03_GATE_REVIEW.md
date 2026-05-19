# 03 — Gate Review · supervisor-agent (T-003)

Mode: `full` · Stage: 3/7 · Author: Gate Reviewer (read-only; persisted by PM) · Date: 2026-05-19

## Eight-dimension audit

| # | Dimension | Verdict | Justification |
|---|---|---|---|
| 1 | Requirements ↔ Design alignment | WARN | AC-6's "AP-1 WARN (2 rollbacks at stages 5 and 6)" is incompatible with AP-1's same-stage tally (F-1). |
| 2 | Code-citation accuracy | PASS | 20/20 substantively verified; two trivial range-edge fuzzes. |
| 3 | Reuse audit credibility | PASS | Every reuse (gate-reviewer pattern, sync-self dir-of-md, mock-env-var pattern, I.* family, separate-temp-dir) is real. |
| 4 | Risk coverage | PASS | R-1..R-8 cover the obvious surfaces; architect-added R-7/R-8 are correct additions. |
| 5 | Backwards compatibility | PASS | No agent contract / rule / existing-check edits. Pure-add. |
| 6 | Documentation discipline | WARN | `AI-GUIDE.md:14` says "7 agent role contracts" — adding supervisor.md as an 8th file needs a count tweak; not listed in §4 fan-out (F-3). |
| 7 | Self-consistency | PASS | `sync-self` `dir-of-md` mapping (line 39) is whole-folder so supervisor.md is picked up automatically; AC-2 closed by `sync-self -Check`. New check `I.7` doesn't collide. |
| 8 | Testability | WARN | AC-6 snapshot on T-002 is well-grounded but only works after F-1 is resolved. |

## Cited-code sanity sweep (20 references)

All 20 file:line citations resolve. Two trivial range-edge fuzzes (rule 65 22→21, test-init.sh 249→252) — non-load-bearing.

## Findings

### F-1 (BLOCKER on AC-6 testability)
- 01 AC-6 asserts: "Running supervisor on the archived T-002 folder produces AP-1 WARN (2 rollbacks at stages 5 and 6)".
- 02 §8 AP-1 defines: "WARN at ≥2 rollbacks **same stage**".
- Actual T-002 PM_LOG has 1 rollback inside Stage 5 and 1 inside Stage 6 — different stages.
- Under the design's same-stage rule, T-002 produces 0 AP-1 findings, not WARN.
- **Resolution required**: either widen AP-1 to include a cross-stage tally (recommend: add AP-1b "≥2 rollbacks anywhere in task = INFO; ≥3 = WARN"), or rewrite AC-6 to use a different fixture that genuinely has 2 same-stage rollbacks.

### F-2 (WARN — dev-time clarification)
`harness-status/SKILL.md:24` glob `{pm,req,sol,gate,dev,review,qa}*.md` won't auto-pick supervisor*.md. AC-11 says count 7→8. Document the exact fix format (add a row vs widen glob) so dev doesn't decide at code-write time.

### F-3 (WARN — doc fan-out)
`AI-GUIDE.md:14` literally says "7 agent role contracts". §4 fan-out doesn't include this line. Either bump the count (e.g. "7 canonical + 1 auxiliary supervisor") or add a separate note.

### F-4 (WARN — AP-3 ambiguity on round-N entries)
AP-3 says "Intervention check between every pair of completed stage entries". T-002's PM_LOG has rounds within a single stage (Stage 5 round-1, Stage 5 round-2). Contract should explicitly state: intervention-check audit operates on stage-to-stage transitions only, not round-to-round within a stage. Without this clarification, AC-6 "zero AP-3 findings" would force the developer to resolve the ambiguity at code-write time.

## Open-issues review (Design §15)

| # | Issue | Decision |
|---|---|---|
| 1 | Verdict-line case-sensitivity | Resolve at dev time — fixed-case only. |
| 2 | `docs/features/_supervision/` gitignore | Defer — user preference; recommend tracked, mention in CHANGELOG. |
| 3 | `harness-status` asset-table edit | Resolve at dev time — adopt architect's "add a row" recommendation (see F-2). |

## Pre-answered Developer questions

| Q | Answer |
|---|---|
| AP-4 on in-flight tasks | Only fires when `docs/tasks.md` marks task Completed AND stage docs remain at `docs/features/<slug>/`. In-flight rows (gate-review/dev/etc) never trigger. |
| What counts as a "task" in cross-task mode | Folder under `_archived/` — globbed via `07_DELIVERY.md`. T-000 (no folder) never enters cross-task scope. |
| AP-2 min line count for `03_GATE_REVIEW.md` | 20 lines per §8 row 2; if too aggressive after running on T-001/T-002, drop to 15 (single-file edit in `supervisor.md`). |
| Python3 gating for `test-supervisor.sh` | Match `test-init.sh:198-201` pattern only if test-supervisor.sh does JSON validation. Otherwise plain bash + grep suffices. |
| Slug normalization in I.7 | Out of scope; use literal slug from folder name. |

## Verdict

# `CHANGES REQUIRED`

Architect must resolve F-1 (the only true blocker) and tighten F-4 (AP-3 contract). F-2 and F-3 are recommended doc fan-out additions. Citation accuracy 20/20 substantively correct — code-evidence trust is high. The design is structurally sound; the blocker is a single arithmetic inconsistency between AC-6 (uses T-002 as fixture) and AP-1 (same-stage threshold).

PM action: rollback to Stage 2 (Architect) with narrow scope.

---

## Round 2 — post-rollback audit (2026-05-19)

### F-1 — FIXED
- §8 row "AP-1b rollback-rate (cross-stage tally)": 0-1 no finding · 2 INFO · 3 WARN · ≥4 ALERT.
- §8 row "AP-1 rollback-rate (same-stage)" unchanged.
- §11 rows 14-17 + §16 paragraph: T-002 trace yields AP-1b INFO + Verdict: HEALTHY.
- Manual trace confirms (Stage 5: 1 rollback; Stage 6: 1 rollback; AP-1 finds nothing; AP-1b counts 2 cross-stage → INFO; no WARN/ALERT → HEALTHY).

### F-2 — FIXED
§4 row explicitly says "add a new row `| Supervisor (auxiliary) | .claude/agents/supervisor.md | ? |`; do NOT widen the existing glob".

### F-3 — FIXED
§4 AI-GUIDE.md row: bump line 14 phrasing `7 agent role contracts` → `7 canonical agents + 1 auxiliary (supervisor)`, plus existing line 35 + line 67 check-count bumps.

### F-4 — FIXED
§8 AP-3 row: explicit "audit operates on stage-to-stage transitions only, e.g. `Stage 4 → Stage 5`; round-to-round events within a single stage are explicitly NOT audited".

### Scope-creep check
No new files / checks / ACs added. Only the 4 findings addressed.

### Doc-size check
295 lines, under 300 cap.

### Round-2 verdict

# `APPROVED FOR DEVELOPMENT`

Developer may proceed to Stage 4.
