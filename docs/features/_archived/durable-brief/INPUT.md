# Task Input — durable-brief (T-05)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Fold the agent-brief **durability discipline** (behavioral not procedural, no file paths/line numbers, complete testable acceptance criteria, explicit out-of-scope, durable across refactors) into the `requirement-analyst` hard rules and the `pm-orchestrator` dispatch-prompt contract — sharpening every stage hand-off, WITHOUT touching the insight-index's evidence citations (which legitimately DO cite file:line).

## Origin & rationale

T-05 of the mattpocock/skills adoption batch (idea ④). His `triage/AGENT-BRIEF.md` + deprecated `qa/SKILL.md` codify "durability over precision": a brief an agent works from must describe **what** the system should do (behavioral), name interfaces/types/contracts, give **complete testable acceptance criteria** and **explicit scope boundaries**, and **NOT** reference file paths or line numbers (they go stale across the days/weeks an issue waits and across refactors).

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\AGENT-BRIEF.md` — the canonical principles (durability over precision; behavioral not procedural; complete acceptance criteria; explicit scope boundaries) + good/bad examples.
- `c:\Programs\_research\mattpocock-skills\skills\deprecated\qa\SKILL.md` — "Rules for all issue bodies": no file paths/line numbers, describe behaviors not code, durable after refactors.

## Why this targets RA + pm-orchestrator

Our `requirement-analyst` produces `01_REQUIREMENT_ANALYSIS.md` (the spec the pipeline works from) and our `pm-orchestrator` writes the per-stage dispatch prompts. Both are "briefs" in mattpocock's sense. Folding the durability discipline here makes every downstream hand-off sharper and more refactor-resilient.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a concise durability rule added to `agents/requirement-analyst.md` (its "Hard rules" / "What good looks like" — behavioral-not-procedural, complete+testable acceptance criteria already partly present, explicit out-of-scope, AVOID file-path/line-number anchors in the requirement spec itself); and a matching one-liner in `agents/pm-orchestrator.md`'s dispatch contract (dispatch prompts to downstream stages should be behavioral + carry the acceptance criteria + scope boundary, not procedural file:line instructions). Keep both additive and terse.

Out of scope (unless analyst argues with evidence): rewriting the RA's existing 9-section output structure or the pm-orchestrator routing; any change that bans file:line in the INSIGHT-INDEX or in stage docs' EVIDENCE citations (those legitimately cite file:line as proof — the durability rule applies to the forward-looking SPEC/brief, NOT the backward-looking evidence); a new verify_all check; importing mattpocock's GitHub-issue-specific template verbatim.

## Insights to honor (verify before relying)

- **Tension to resolve carefully:** this repo's insight-index entries and stage-doc evidence INTENTIONALLY cite `file:line` (e.g. `verify_all.ps1:439`) as proof. The durability rule must be scoped to the forward-looking requirement/brief (what to build), NOT the backward-looking evidence (what was proven). Make that boundary explicit so the new rule doesn't contradict the insight-index contract (`.harness/rules/05-insight-index.md`).
- I.3 doc-size cap: agent definitions ≤300 lines. requirement-analyst.md ~75 lines (just edited by T-03), pm-orchestrator.md ~207 lines — both have headroom; keep additions terse.
- `agents/*.md` are plugin-native (distributed as harness-kit:<name>) — editing them is a shipped-behavior change. Determine whether a version bump + CHANGELOG entry is warranted (likely yes, like prior agent-content changes); enumerate any agent-count claims (8 plugin-native agents) — but this changes agent CONTENT, not COUNT, so no count flip. Confirm against the live repo.
- Framework agents are edited directly in top-level `agents/` (no sync, no templates copy since v0.30).
- I.6 retired-claim guard: introduce no banned anchor.
