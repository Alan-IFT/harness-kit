# Task Input — planning-decision-map (T-10)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent). **FINAL task of the batch. ASSESS-FIRST / DECLINE-IF-REDUNDANT.**

## Goal (one sentence)

ASSESS whether mattpocock/skills' `decision-mapping` (a fog-of-war investigation map for a pre-task idea too loose to form tasks) offers a genuinely-NEW capability over this repo's existing pool/frontier/stream + harness-explore/harness-plan — and either scope ONLY that new delta, or recommend DECLINE (recorded in `.harness/rejected-decisions.md`) if it is redundant.

## Origin & rationale (and the honest prior)

T-10 (Tier-3 ⑧, final). His `decision-mapping/SKILL.md` builds a compact git-tracked Markdown map of numbered investigation "tickets" (Research / Prototype / Discuss) with `blocked_by` edges, a "frontier" advanced one node at a time, "fog of war" beyond the frontier, each ticket sized to one ~100k-token session, bootstrap vs resume, parallelism-aware.

**Honest prior (state this plainly in the analysis):** this is the Tier-3 item the adoption plan flagged as "**overlaps our pool/frontier/stream heavily**." We ALREADY have: `docs/batches/<id>/BATCH_PLAN.md` pools with `Depends on` edges + a topological **frontier** (harness-stream/batch), `/harness-explore` (research/feasibility mode), `/harness-plan` (design-only stages 1-3), and now (T-06) a smart-zone task-sizing + vertical-slice decomposition discipline. The decision-mapping concepts map almost 1:1 onto these. The genuinely-NEW delta, IF any, is narrow: a **pre-task investigation/decision map** for when an idea is *too loose to even form BATCH_PLAN rows yet* — i.e., the phase BEFORE tasks exist, where open QUESTIONS (not tasks) are resolved one at a time to push back "fog of war" until the path is clear enough to decompose into a pool.

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\in-progress\decision-mapping\SKILL.md` — the fog-of-war map (note: it's in his `in-progress/` = a draft he hasn't shipped).

## Scope guidance — ASSESS-FIRST is the primary deliverable

The RA's FIRST job is an honest **overlap-vs-value assessment**, grounded in the live repo:
- Map each decision-mapping concept (map file, ticket, blocked_by, frontier, fog of war, ticket-types Research/Prototype/Discuss, session-sizing, bootstrap/resume) onto its existing harness equivalent (BATCH_PLAN row, Depends on, topological frontier, /harness-explore, smart-zone sizing, stream resume semantics). Be specific.
- Determine the genuinely-NEW delta (if any). The candidate is: a lightweight "pre-task investigation map" for the loose-idea phase before pool rows exist.
- Then RECOMMEND one of:
  - (A) **DECLINE** — if the delta is fully covered by existing surfaces (e.g. `/harness-explore` already handles the loose-idea/feasibility phase). Record the decline + reason in `.harness/rejected-decisions.md` (the T-09 memory — closes the loop). This is a fully acceptable, even preferred, outcome under [[feedback_design_over_guards]] / lightweight; do NOT build a duplicate.
  - (B) **MINIMAL** — if there is a real, small gap, scope the smallest addition that fills it (most likely a short note/section in `/harness-explore` or `/harness-plan` framing the loose-idea→open-questions→decompose flow, reusing the existing frontier/fog vocabulary), NOT a new heavyweight skill or a parallel pool format.

Out of scope (regardless): a new heavyweight `decision-mapping` skill duplicating the pool; a second map-file format competing with BATCH_PLAN; a new verify_all check; importing his in-progress draft verbatim.

## Insights to honor (verify before relying)

- Prefer DECLINE or MINIMAL over building a duplicate (feedback_design_over_guards / lightweight / the whole point of the T-09 rejected-decisions memory you may write into).
- If MINIMAL touches a distributed skill, version bump likely; no count flip. If DECLINE, the deliverable is the assessment doc + a rejected-decisions.md entry (+ maybe a one-line pointer where someone would look) — likely no version bump.
- harness-explore already = "research/feasibility, light requirement analysis + free-form findings" — check whether the loose-idea phase is already its job.
- Reuse the EXISTING frontier/fog vocabulary if MINIMAL (the stream skill already uses "frontier"); don't introduce a competing term set.
- I.6 retired-claim guard: no banned anchor.
