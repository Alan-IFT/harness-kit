# 03 — Gate Review · T-10 planning-decision-map (ASSESS-FIRST / DECLINE)

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Role: independently VALIDATE the RA's DECLINE, not rubber-stamp. Verify-don't-trust against the live tree + the read-only draft.

## Independently verified (re-derived from live files, not the RA's word)
- `decision-mapping/SKILL.md` is an `in-progress/` (unshipped) draft. Its concepts re-mapped 1:1 onto live surfaces:
  - map loaded every session = pool re-read every iteration (harness-stream:9/184); ticket = BATCH_PLAN row; `Blocked by:` = `Depends on` column; **frontier** = topological frontier (harness-stream uses the *same word* :39/117/121); fog of war = append-only pool (:39); session-sizing "~100k" = T-06 smart zone (harness-plan:43-48); Research/Prototype tickets = `/harness-explore` (:3/8-18/81); Discuss + bootstrap + skip-when-no-fog = `/harness-grill` one-question-at-a-time design-tree interview (:57-72, the draft's Discuss ticket even invokes `/grilling`); resume = stream resume semantics (:120/184).
- Counts: AI-GUIDE 16 skills / 8 agents / 32 checks; verify_all C.1/G.1/G.2 hardcode the 16 skills (all present incl grill/explore/plan).

## 8-dimension audit — all PASS (Design completeness N/A by DECLINE)
No FAIL. 2 WARN informational (below).

## Decisive question — did the RA miss a genuinely-NEW capability?
Pressed each candidate delta:
1. Pre-task loose-idea map → owned by `/harness-grill` (the "haven't said what I want yet" front-end) + brief/`pending` rows for cross-session state.
2. Open QUESTIONS one-at-a-time (not tasks) → grill's engine verbatim (the draft's Discuss invokes /grilling).
3. Whole-map-in-every-session → pool re-read invariant.
4. "fog of war" TERM not surfaced in harness prose → at most a cosmetic doc tweak; INPUT warns against a competing term set; RA correctly rejected. **Not a capability gap.**
5. Parallelism-aware map → harness stream is deliberately serial (narrower scope choice, not a missing capability; adopting it = unrequested scope expansion).
**No real, valuable gap found → concur with DECLINE.**

## rejected-decisions.md `## decision-mapping` record — clean (5/5)
Well-formed per the file's record format (Decision/Why/Origin, matches to-prd/triage/ask-matt siblings); accurate reason (the 1:1 mapping + considered-and-rejected MINIMAL); single record (no duplicate); I.6-safe (read the live banned list verify_all.sh:521-536 — all CLAUDE.md-composition / scaffolding-only / 全程中文; "frontier/fog of war/blocked_by/decision map/BATCH_PLAN" match none; the file IS scanned, not exempt, and passes); no count/version change.

## No build / no surface growth — confirmed
No new skill (16 stays), no second map format, no new verify_all check (32 stays), no agent change (8 stays), no version bump. Touched files: `01_REQUIREMENT_ANALYSIS.md` (docs/features, I.6-exempt) + `.harness/rejected-decisions.md` (SOFT memory, append only).

## Findings (2 WARN, informational, non-blocking)
- F-1: 01 AC-6 "I.6 PASSes over the new doc" is over-conservative — `docs/features/` is I.6-EXEMPT, so the doc is never scanned; the real scanned surface is `.harness/rejected-decisions.md` (checked clean in §record).
- F-2: the 01 "fog of war (term not yet in prose)" row is the lone honest soft spot; pressed and judged not a capability gap.

## Verdict
**APPROVED — DECLINE CONFIRMED (no build).** The loose-idea→open-questions→decompose phase is already owned by `/harness-grill` + `/harness-explore` → BATCH_PLAN topological frontier (harness's own `frontier` vocabulary). The decline is the Mode-2 rubric-coherent outcome; the record is clean; counts stay 16/8/32. Development proceeds to archive — nothing to build.
