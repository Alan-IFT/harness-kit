# Task Input — harness-grill (T-03)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM shell in main thread (sub-agents have no Task; Bash works in sub-agents, PowerShell denied → PM runs PS-side).
**deferred-human mode:** defer, do not ask. Genuine human-reserved calls → `BLOCKED: NEEDS-HUMAN — <q> — <unblock>`.
**Depends on:** T-02 (context-glossary, DELIVERED) — the grill front-end composes with `CONTEXT.md`.

## Goal (one sentence)

Add a `/harness-grill` main-loop skill that interviews the user one question at a time (recommending an answer for each, exploring the codebase to self-answer where it can) and emits an aligned brief that becomes the requirement-analyst's `INPUT.md`, plus a "recommend an answer per open question" rule on the requirement-analyst — composing with `CONTEXT.md` into a grill-with-docs-style alignment front-end.

## Origin & rationale

T-03 of the mattpocock/skills adoption batch (idea ②). His most popular skill is **grilling**: a relentless, ONE-question-at-a-time interview that walks the design tree, gives a recommended answer per question, and explores the codebase instead of asking when it can. It targets the #1 failure mode "the agent didn't do what I want." Our requirement-analyst currently lists ambiguities as a BATCH in a doc and stops (`BLOCKED ON USER`); it is not an interactive interview and doesn't recommend an answer per question.

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\productivity\grilling\SKILL.md` — the ~5-line engine: "Interview relentlessly… one question at a time, waiting for feedback on each… for each question provide your recommended answer… if a question can be answered by exploring the codebase, explore instead."
- `c:\Programs\_research\mattpocock-skills\skills\engineering\grill-with-docs\SKILL.md` — grilling + domain-modeling composed (builds CONTEXT.md inline).
- `c:\Programs\_research\mattpocock-skills\skills\engineering\ask-matt/SKILL.md` — "smart zone (~120k)" + context-hygiene framing (keep alignment in one window).

## Why a new main-loop skill (not just an RA change)

Grilling is fundamentally an INTERACTIVE multi-turn loop with the user; the requirement-analyst is a sub-agent that cannot hold a back-and-forth (it writes a doc and stops). So the interactive interview belongs in a MAIN-LOOP skill that runs BEFORE the pipeline and produces a pre-aligned brief; the RA then consumes that brief as its `INPUT.md`. Division of labor: grill = main-loop interactive alignment; RA = structured spec from the aligned brief.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a new `skills/harness-grill/SKILL.md` (user-invoked main-loop skill: relentless one-question-at-a-time interview, a recommended answer per question, explore-codebase-to-self-answer, reads `CONTEXT.md` if present for canonical terms and may sharpen it inline, emits an aligned brief written to a feature `INPUT.md` so `/harness` or the pool can pick it up); a one-line rule added to `agents/requirement-analyst.md` that each Open Question must carry a recommended answer (cheap even under the batch model — and it ALREADY does this under deferred-human mode, so this generalizes that to a standing rule); all the new-skill fan-out (README.md + README.zh-CN.md "all N skills", CHANGELOG, AI-GUIDE.md "Workflow entry" table, getting-started if it enumerates skills, plugin.json/marketplace if skills are listed there, the skill-count claims gated by G.4, version bump); doc-size discipline.

Out of scope (unless the analyst argues with evidence): making grill model-invoked/auto-firing (it is user-invoked — the human starts an alignment session deliberately); a separate domain-modeling skill (CONTEXT.md maintenance folds into the grill + RA/SA prose, per T-02); changing the pipeline stage count or pm-orchestrator routing (grill is a PRE-pipeline front-end, not a stage); building a verify_all guard for grill.

## Insights to honor (verify before relying — from .harness/insight-index.md + this batch)

- New skill = a FAN-OUT: G.1/G.2 require README + CHANGELOG to reference EVERY skill; G.4 gates skill-count claims against plugin.json + the live tally; a count change is version-worthy (insight 2026-06-05). The Architect must enumerate EVERY skill-count / skill-list surface (the T-008/T-018 ledger discipline — getting-started.md "fourteen/N skills" fan-out bit T-018's Gate). Currently 15 skills → 16.
- Skill authoring quality bar: `.harness/rules/15-skill-authoring.md` — description written for the model, "when NOT to invoke" delta vs siblings (esp. vs `/harness-plan`, `/harness-explore`, `/harness` which also start work), progressive disclosure, no railroading.
- AI-GUIDE.md ≤200 (I.1); a new Workflow-entry row + skill index line must stay under cap.
- This is the 15→16 skill; mirror the exact registration pattern of a recent skill add (T-018 `/harness-decision-mode`, T-014 `/harness-language`) — those are the canonical fan-out references.
- SKILL.md must be synced to `.claude/` via harness-sync if placed under `.harness/skills/`; but distributed skills live under top-level `skills/<name>/` (the product). Determine the correct home (this is a FRAMEWORK skill shipped by the plugin, like the other `/harness-*` skills under top-level `skills/`).
