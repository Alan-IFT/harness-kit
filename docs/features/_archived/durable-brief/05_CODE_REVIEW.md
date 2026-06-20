# 05 — Code Review · T-05 durable-brief

> Stage 5 (Code Reviewer). Mode: full. deferred-human: defer. Read-only; persisted by PM.
> Upstream: 01 READY · 02 READY · 03 APPROVED (C-1/C-2) · 04 READY FOR REVIEW.
> Scope: T-05 additions only — working tree carries unrelated T-02/T-03/T-04 churn (e.g. T-03's RA rule-1/§8/CONTEXT), explicitly NOT reviewed. Reviewed: RA Hard rule 6 + 1 good + 1 bad entry; PM dispatch line; 4 version stamps @0.36.0; CHANGELOG [0.36.0].

## Findings
- CRITICAL / MAJOR / MINOR: none.
- NIT [STYLE]: Hard rule 6 is a dense ~95-word paragraph (legible, under cap); PM line is one long sentence with a nested parenthetical (deliberate per OQ-2(a)). Neither blocks.

## Requirement coverage (AC-1…AC-9) — all ✅
- AC-1 RA Hard rule 6 (behavioral-not-procedural + no forward-looking file:line). AC-2 good entry (names behavior/interface/type, not the line) + bad entry (plain prose). AC-3 exemption clause names 05-insight-index.md + stage-doc EVIDENCE as exempt, with rationale. AC-4 PM dispatch one-liner (behavioral + AC + scope boundary, not procedural file:line). AC-5 insight-surfacing para (pm-orchestrator:51-57) byte-present, new line appended after. AC-6 protected files NOT in edit set, no contradiction (05 requires evidence path/line; rule 6 exempts exactly that). AC-7 caps RA 77 / PM 208 ≤300 + verify_all.sh 32/0/0. AC-8 4 stamps @0.36.0 + CHANGELOG [0.36.0] (counts stated unchanged 16/8/32). AC-9 additive only.

## Carry-forward conditions
- **C-1** ✅: regex scan for `name.ext:NNN` over RA/PM/new CHANGELOG block → no match; path/line written as prose; bad-exemplar plain prose; verify_all.sh I.6 PASS (PS operator-pending).
- **C-2** ✅: all 6 RA Hard rules + 9-section output + both good/bad lists intact; all PM sections intact; only inserts, no T-05 deletion.

## Scoping verifications
Caps OK (RA 77, PM 208 ≤300). No count token flipped (the new CHANGELOG 16/8/32 is additive prose stating UNCHANGED; the 15→16 at CHANGELOG:26 belongs to the prior [0.35.0] T-03 entry; README line-7 count claim unchanged). No new verify_all check (live 32). 05-insight-index.md + insight-index.md untouched; evidence-citation convention preserved (forward brief banned, backward evidence exempt) — no self-contradiction.

## Verdict
**APPROVED WITH NOTES** — 0 CRIT/MAJOR/MINOR, 2 NIT (preference). All 9 ACs + design §4a/§4b/§5a/§10 verbatim; C-1/C-2 hold; single-sourced boundary (RA owns, PM references). Operator-pending: verify_all.ps1 (PS deny; bash 32/0/0) before done. No route-back.
