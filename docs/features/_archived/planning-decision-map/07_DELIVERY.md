# Delivery Summary — planning-decision-map (T-10)

- **Task:** T-10 / `planning-decision-map` — ASSESS-FIRST: whether mattpocock/skills' `decision-mapping` offers a genuinely-new capability over the existing pool/frontier/stream + explore/plan/grill.
- **Mode:** full (assess-first) · **Depends on:** — · **FINAL task of the batch.**
- **Outcome / Verdict:** **DECLINED (no build).** Confirmed by an independent Gate review.
- **Stages traversed:** 1 RA (assessment + DECLINE recommendation) → 3 Gate (DECLINE CONFIRMED). Dev/CR/QA skipped — nothing to build/test.
- **Rollbacks:** 0
- **Final verify_all result:** **PASS 32/0/0 (Bash)** — the only non-docs change is the append to `.harness/rejected-decisions.md` (I.6-scanned, clean). verify_all.ps1 operator-pending (PS denied).
- **Version:** none — no build, no distributed surface touched. Counts stay 16 skills / 8 framework agents / 32 checks.

## Why DECLINED

`decision-mapping` (an unshipped `in-progress/` draft) maps 1:1 onto existing harness surfaces — independently re-derived by both RA and Gate from the live files:

| decision-mapping concept | existing harness equivalent |
|---|---|
| the map (git-tracked, loaded every session) | `BATCH_PLAN.md` pool, re-read every iteration |
| ticket | pool row (`ID \| Slug \| Goal \| Mode \| Depends on \| Status`) |
| `Blocked by:` edges | the `Depends on` column |
| frontier (advance one node) | the topological **frontier** (harness-stream uses the same word) |
| fog of war (incomplete beyond frontier) | the append-only pool |
| session-sizing (~100k) | the T-06 smart-zone task sizing |
| Research / Prototype tickets | `/harness-explore` (research/feasibility/throwaway probe) |
| Discuss / bootstrap / skip-when-no-fog | `/harness-grill` one-question-at-a-time design-tree interview |
| resume | stream resume semantics |

The only candidate genuinely-new delta — a pre-task investigation map for the loose-idea phase before pool rows exist — is already owned by `/harness-grill` (resolves open questions one at a time, the "haven't said what I want yet" front-end) + `/harness-explore`, handing into the BATCH_PLAN frontier. Building it would duplicate the pool and produce the consumer of an already-declined producer (`to-prd` was declined earlier this batch). A MINIMAL note was considered and rejected (not a gap; risks a competing term set). DECLINE holds surface area flat — the [[feedback_design_over_guards]] / lightweight outcome.

## Files changed (2 — assessment only, no build)
- `docs/features/planning-decision-map/01_REQUIREMENT_ANALYSIS.md` (the overlap assessment)
- `.harness/rejected-decisions.md` (new `## decision-mapping` record — closes the loop: the T-09 memory layer's first real use)

## Quality trail
- RA (01): DECLINE recommendation with a full 1:1 concept-mapping; appended the rejected-decisions record.
- Gate (03): APPROVED — DECLINE CONFIRMED; independently re-derived the mapping, pressed every candidate gap (incl. the "fog of war" term soft spot), found none; verified the record clean (well-formed, accurate, single, I.6-safe, no count/version change).

## Outstanding risks / Next steps for user
- Operator-pending: `verify_all.ps1` confirm 32/32 (PS denied; the rejected-decisions.md append is I.6-symmetric across shells).
- If a future user ever can't find the loose-idea entry point, the smallest fix (only if the gap is OBSERVED) is a one-line pointer in the AI-GUIDE "Workflow entry" table to `/harness-grill` / `/harness-explore` — not built now (speculative).
