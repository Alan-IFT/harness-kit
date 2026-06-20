# Rejected decisions — deliberately not adopted (and why)

> Deliberately-declined requests / approaches + why, so a re-proposal finds the prior
> decision instead of re-litigating it. **Read** at a non-trivial decide-point before
> proposing a new approach / feature; **append** when something is deliberately declined
> (a real rejection — or a `deferred` "not now", marked as such). One record per concept;
> a re-occurrence adds its origin to that record, not a second record. Sibling memory:
> `.harness/insight-index.md` (truths), `.harness/decision-rubric.md` (autonomy principles),
> `CONTEXT.md` (glossary). Soft self-discipline: if this grows past ~one screen, compact
> merged/obsolete records — no gate enforces size.

## design-it-twice
- **Decision:** deferred (not now).
- **Why:** a parallel-exploration design pattern; useful but not yet pulled in — the
  solution-architect lens already names it as a future option. Re-surface when a genuinely
  high-stakes design call warrants exploring two approaches in parallel.
- **Origin:** mattpocock-adoption batch (T-07 design-vocab discussion).

## ask-matt-router
- **Decision:** declined.
- **Why:** a "which sibling skill / role handles this" router. The AI-GUIDE "Workflow entry"
  table already routes a request to the right mode/skill, so a second router is duplication.
- **Origin:** mattpocock-adoption batch.

## issue-tracker-dedup
- **Decision:** declined.
- **Why:** this repo has no issue tracker; the upstream one-file-per-concept dedup + auto-matching
  machinery is built for a tracker with many requests per concept. At this repo's scale a single
  human-read file carries the institutional-memory value at a fraction of the surface.
- **Origin:** mattpocock-adoption batch (this file's own basis).

## to-prd
- **Decision:** declined.
- **Why:** a request-to-PRD conversion flow tied to an issue tracker / many-stakeholder intake;
  this repo's intake is the 7-stage pipeline starting at the requirement-analyst, so a separate
  PRD stage is redundant weight.
- **Origin:** mattpocock-adoption batch.

## triage
- **Decision:** declined.
- **Why:** an inbound-request triage workflow presupposing a queue of external requests; this
  single-maintainer repo has no such queue, and the pipeline's PM routing already triages tasks.
- **Origin:** mattpocock-adoption batch.

## skill-usage-telemetry
- **Decision:** declined.
- **Why:** a per-call hook logging every skill invocation to find under-triggering skills. It is
  a standing per-call cost for a single-maintainer project and cuts against the repo's anti-bloat
  line — no resident hook unless it prevents a concrete hazard. Gather usage ad hoc if ever needed.
- **Origin:** migrated here from `.harness/rules/15-skill-authoring.md` "Deliberately not adopted".

## skills-teach-handoff-writing-personal
- **Decision:** declined (skill family).
- **Why:** the upstream `teach`, `handoff`, `writing-*`, and `personal` skills target a human
  knowledge-base / personal-workflow audience, not an AI-development pipeline distribution — out
  of fit for what this repo ships.
- **Origin:** mattpocock-adoption batch (non-fit tier).

## skills-git-guardrails-setup-pre-commit
- **Decision:** declined.
- **Why:** the upstream `git-guardrails` and `setup-pre-commit` skills overlap this repo's existing
  `guard-rm` PreToolUse safety hook and `install-hooks` pre-commit installer — adopting them would
  duplicate mechanisms we already ship.
- **Origin:** mattpocock-adoption batch.

## skills-tdd-diagnosing-bugs
- **Decision:** declined.
- **Why:** TDD and bug-diagnosis practice is already covered by this repo's engineering rules and
  the QA/code-reviewer stages of the pipeline; a separate skill for each would restate covered
  ground.
- **Origin:** mattpocock-adoption batch.

## decision-mapping
- **Decision:** declined.
- **Why:** an unshipped (`in-progress/`) upstream draft that builds a separate "decision map" of
  numbered investigation tickets with `blocked_by` edges, a frontier, and fog of war. Every concept
  maps 1:1 onto a live harness surface: the map = the `BATCH_PLAN.md` pool, a ticket = a pool row,
  `blocked_by` = the `Depends on` column, frontier = the topological frontier (`/harness-stream`
  already uses that word), fog of war = the append-only pool, session-sizing = the T-06 smart zone,
  ticket-types Research/Prototype = `/harness-explore`, Discuss/bootstrap = `/harness-grill`'s
  one-question-at-a-time design-tree interview, resume = the stream resume semantics. The only
  candidate delta (a pre-task investigation map for the loose-idea phase before pool rows exist,
  resolving open *questions* not tasks) is already owned by `/harness-grill` (questions) +
  `/harness-explore` (research/prototype) handing into the BATCH_PLAN frontier. Building it would be a
  parallel map format competing with the pool — exactly the duplication this batch already declined
  for `to-prd` (decision-mapping's own hand-off target), `ask-matt-router`, and `triage`. A MINIMAL
  note restating the loose-idea→questions→decompose flow was considered and rejected too: not a gap
  (grill's description already states that flow) and it risks introducing a competing term set.
- **Origin:** mattpocock-adoption batch (T-10, the final / assess-first item; assessment at
  `docs/features/planning-decision-map/01_REQUIREMENT_ANALYSIS.md`).

## entropy-findings-store
- **Decision:** declined.
- **Why:** a standalone open/fixed findings store re-encodes a re-derived fact; the entropy scan
  re-derives OPEN/FIXED each run (fixed == no-longer-surfaced, open == re-derived from the live
  tree), so a separate log would add a file plus a read/write cycle plus a drift surface to
  duplicate a property the design already has by construction. Declines are the only state that needs
  memory, and they reuse this T-09 file. Lightweight / design-over-guards line.
- **Origin:** T-11c entropy-watch-persist scope-down (RA + architect).
