# Batch Plan — default

> Created: 2026-06-11 · Updated: 2026-06-19
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | sync-hook-dangling-ref | Eliminate by design the consumer-project failure where the Stop hook fires `bash: .harness/scripts/harness-sync.sh: No such file or directory` on every turn — root-cause which flow can produce a project whose wired hook references a missing script, make that state unreachable, and ship a repair path for already-broken projects. | full | — | done |
| T-02 | context-glossary | Add a `CONTEXT.md` domain-glossary memory layer (tight definition + `_Avoid_` format) as a dogfood file and a harness-init template asset, wired as a SOFT dependency that the requirement-analyst and solution-architect reference and lazily maintain, indexed in AI-GUIDE.md — killing verbose/inconsistent domain naming at the root with no new verify_all guard. | full | — | done |
| T-03 | harness-grill | Add a `/harness-grill` main-loop skill that interviews the user one question at a time (recommending an answer for each, exploring the codebase to self-answer where it can) and emits an aligned brief that becomes the requirement-analyst's `INPUT.md`, plus a "recommend an answer per open question" rule on the requirement-analyst — composing with `CONTEXT.md` into a grill-with-docs-style alignment front-end. | full | T-02 | done |
| T-04 | skill-authoring-vocab | Additively enrich `.harness/rules/15-skill-authoring.md` with the named skill-design vocabulary from mattpocock/skills' writing-great-skills (leading word, completion criterion, premature completion, no-op test + sediment/sprawl pruning discipline, single source of truth, and the context-load vs cognitive-load / user-vs-model-invoked lens) without rewriting existing principles. | full | — | done |
| T-05 | durable-brief | Fold the agent-brief durability discipline (behavioral not procedural, no file paths/line numbers, complete testable acceptance criteria, explicit out-of-scope, durable across refactors) into the requirement-analyst's hard rules and the pm-orchestrator dispatch-prompt contract — sharpening stage hand-offs without touching insight-index evidence citations. | full | — | done |
| T-06 | vertical-slices | Add a tracer-bullet vertical-slice decomposition discipline (each task an independently-verifiable end-to-end slice, not a horizontal layer) plus a smart-zone task-sizing heuristic (size a task to one ~120k-token reasoning window) to the harness-plan decomposition guidance and the batch/stream task-authoring guidance. | full | — | done |
| T-07 | sa-design-vocab | Give the solution-architect the codebase-design deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) plus the deletion test and "interface is the test surface" / "one adapter = hypothetical seam, two = real" principles, as an optional design-language section — excluding the heavier design-it-twice parallel-subagent pattern this round. | full | — | done |
| T-08 | two-axis-review | Fold the two-axis review PRINCIPLE from mattpocock/skills' `review` skill into the code-reviewer agent: keep Standards-conformance (does it follow this repo's conventions) and Spec/design-fidelity (does it match the requirement+design) as SEPARATE, non-merged lenses so one axis cannot mask the other — as a lightweight review-structure principle, NOT literal parallel sub-agent dispatch. | full | — | done |
| T-09 | rejected-decisions-memory | Generalize the ad-hoc "Deliberately not adopted" pattern into a lightweight rejected-decisions memory (mattpocock/skills' `.out-of-scope/` idea) that prevents re-litigating declined requests/approaches — assess whether a dedicated file or a documented convention on existing surfaces is the lighter fit, and wire a light read/append habit. No heavy machinery. | full | — | done |
| T-10 | planning-decision-map | ASSESS-FIRST: mattpocock/skills' `decision-mapping` (fog-of-war investigation map for a pre-task idea too loose to form tasks) overlaps heavily with our existing pool/frontier/stream + harness-explore/harness-plan. Honestly scope ONLY the genuinely-new delta (a planning-phase open-question map BEFORE tasks exist); if it is fully redundant, recommend DECLINE rather than build a duplicate feature (feedback_design_over_guards / lightweight). | full | — | done (DECLINED, no build) |

| T-11a | entropy-watch | Anti-entropy watch — thinnest end-to-end slice: supervisor entropy/deep-module scan lens + shared "remind-if-due" cadence check (N≥5 delivered since last sweep, or first session drain) + `.harness/entropy-watch.state` + `/harness-stream` pool-drained `## Entropy watch` surface (reuse T-022 pattern) + new 17th skill entry + authorize→execute via `/harness-goal`. Non-blocking, no new gate. | full | — | done |
| T-11b | entropy-watch-harness | Add the `/harness` single-task stage-7 delivery surface calling the SAME shared remind-if-due check (so both harness and stream auto-remind). | full | T-11a | done |
| T-11c | entropy-watch-persist | Findings-persistence store: open findings re-surface, fixed ones drop, user-declined ones go to `.harness/rejected-decisions.md` (no re-litigation). | full | T-11a | done (decline-filter only; standalone store DECLINED as overkill) |

## Notes (optional)

- This batch adopts six ideas distilled from a deep read of github.com/mattpocock/skills (research artifact at `c:\Programs\_research\mattpocock-adoption-plan.html`). Mapping: T-02=① shared-language CONTEXT.md, T-03=② grill interview, T-04=③ skill-authoring vocabulary, T-05=④ durable agent-brief, T-06=⑤ tracer-bullet vertical slices + smart-zone sizing, T-07=⑥ deep-module design vocabulary.
- Second wave (Tier-3 "缓议" items, queued on user request 2026-06-20): T-08=⑦ two-axis review principle, T-09=⑨ rejected-decisions memory, T-10=⑧ planning-phase decision map (ASSESS-FIRST — decline if redundant with the existing pool/frontier/stream). These were originally flagged as marginal/heavier; the RA stage must honestly assess value+overlap and descope or recommend decline where appropriate rather than force-build.
- Source repo shallow-cloned at `c:\Programs\_research\mattpocock-skills\` for reference during implementation.
- T-03 depends on T-02 (the grill front-end composes with CONTEXT.md). T-02 and T-07 both edit `solution-architect.md`; T-03 and T-05 both edit `requirement-analyst.md` — serial execution (stream invariant) avoids file conflicts.
- Runtime quirk (carried from T-01): sub-agents have no `Task` tool, so the PM shell runs in the main thread while each stage runs as its own isolated sub-agent.
- T-01 is a prior completed run (DELIVERED v0.31.0, archived); kept for lineage and skipped by resume semantics.

## Column reference

- **ID** — batch-local identifier. **Slug** — kebab-case; becomes `docs/features/<slug>/`. **Goal** — one sentence; pm-orchestrator's task-description input. **Mode** — `full` | `plan` | `goal`. **Depends on** — comma-separated IDs or `—`. **Status** — `pending` | `in-progress` | `done` | `failed` | `blocked` | `needs-human` | `skipped`.
