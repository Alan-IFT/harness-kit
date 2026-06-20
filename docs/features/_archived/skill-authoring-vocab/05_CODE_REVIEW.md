# 05 — Code Review · T-04 skill-authoring-vocab

> Stage 5 (Code Reviewer). Mode: full. deferred-human: defer. Read-only; persisted by PM.
> Scope: ONLY the T-04 hunk in `.harness/rules/15-skill-authoring.md` (unrelated T-02/T-03 working-tree changes excluded).
> Upstream: 01 READY · 02 READY · 03 APPROVED · 04 READY FOR REVIEW.

## Findings
- CRITICAL / MAJOR / MINOR: none.
- NIT [STYLE]: provenance mattpocock sentence joined into the Anthropic paragraph (design-specified §7a; compliant). NIT [MAINT]: two new concepts use `*(new — no prior handle)*`, the load lens uses `*(new lens)*` — cosmetic marker variance; AC-4 met. Neither blocks.

## Requirement coverage (AC-1…AC-9) — all ✅
- AC-1 all 7 concepts named (axes "checkable"/"exhaustive" present; pair "context load"/"cognitive load" present).
- AC-2 no-op test→P2, leading word→P1 (generalizes). AC-3 sediment/sprawl→P5+70-doc-size cap, SSOT→anti-bloat "Deliberately not adopted".
- AC-4 the 3 genuinely-new marked *(new)*, NO false P-mapping. AC-5 P1-P8 byte-stable (additive; new section between P8 and "Deliberately not adopted"). AC-6 mattpocock writing-great-skills/GLOSSARY credited, Anthropic line+URL preserved.
- AC-7 116 lines (≤200). AC-8 verify_all.sh 32/0/0, no I.6 anchor in new prose (the lone pre-existing "中文" is NOT the banned 全程→中文 run). AC-9 dogfood-only, no fan-out.

## Task-specific verification
4 mapped concepts point at live principles whose text matches the claim (P1 "write description for the model"; P2 "don't state the obvious"; P5 progressive disclosure + cap; "Deliberately not adopted" literally "delete duplication rather than guard it"). 3 new concepts correctly unmapped. Intro re-wrap dropped no provenance info (URL intact). New content meets the rule's own bar (terse named handles, no no-op restatement, single co-located block, no sprawl).

## Design fidelity (02 §7) — all ✅
7a provenance both-sources coexist; 7b new section placed P8↔"Deliberately not adopted" with 7 handles; OQ-1(a) single appended section; OQ-2(a) router skill excluded; OQ-3(a) one-sentence load lens; 7c 116 within the "exact wrap free if ≤200" license (no drift).

## Verdict
**APPROVED** — 0 CRITICAL/MAJOR/MINOR, 2 NIT. Every AC implemented + cited; mapped concepts resolve to real matching principles; new concepts correctly new; P1-P8 byte-stable; 116 ≤200; no I.6 anchor; dogfood-only no fan-out no new check. AC-8 PS tally PM-owned (PS denied); reviewer-side static I.2/I.6 inspection clean. No user question.
