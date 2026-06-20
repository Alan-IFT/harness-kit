# Task Input — two-axis-review (T-08)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Fold the two-axis review PRINCIPLE from mattpocock/skills' `review` skill into the `code-reviewer` agent: keep **Standards-conformance** (does the change follow this repo's documented conventions) and **Spec/design-fidelity** (does it match the requirement + design) as SEPARATE, non-merged lenses so one axis cannot mask the other — as a lightweight review-structure principle, NOT literal parallel sub-agent dispatch.

## Origin & rationale

T-08 (Tier-3 ⑦) of the mattpocock/skills adoption batch. His `review/SKILL.md` runs TWO independent reviews — Standards (repo coding standards) and Spec (does it implement the originating issue/PRD) — as parallel sub-agents, and reports them SIDE BY SIDE without merging or reranking, because "a change can pass one axis and fail the other" and reporting them separately stops one axis from masking the other. Our `code-reviewer` already reviews "against requirement and design — completeness and design fidelity" (the Spec axis) and touches style; the sharp, transferable idea is the EXPLICIT SEPARATION of the two axes so a Standards pass never masks a Spec fail (or vice-versa).

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\in-progress\review\SKILL.md` — the two-axis structure + "Why two axes" rationale.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a lightweight addition to `agents/code-reviewer.md` instructing the reviewer to report findings under TWO explicitly-separated lenses — Standards-conformance (repo conventions: AI-GUIDE rules, dev-map patterns, naming, doc-size, cross-shell parity, etc.) and Spec/design-fidelity (matches 01_REQUIREMENT_ANALYSIS + 02_SOLUTION_DESIGN) — and to NOT let one axis mask the other (don't collapse to a single pass/fail that hides an axis-specific failure; surface both). Keep it a review-STRUCTURE principle, terse and additive.

Out of scope (unless analyst argues with evidence): literal parallel sub-agent dispatch (our reviewer is a single read-only agent; the runtime can't nest Task anyway — this is a principle, not a mechanism); rewriting the code-reviewer's existing severity model (BLOCKER/MAJOR/MINOR/NIT) or its rollback-routing contract; a new verify_all check; an issue-tracker dependency (his `review` assumes a spec source in an issue tracker — we use the per-task 01/02 stage docs).

## Insights to honor (verify before relying)

- `code-reviewer` is a plugin-native distributed agent (`agents/code-reviewer.md`) — editing it is a shipped change → version bump + CHANGELOG likely (precedent T-05/T-06/T-07; current is 0.38.0 → likely 0.39.0). NO count change (content not count; 16/8/32 stay). Confirm against live.
- I.3 cap: agents ≤300 lines. Keep terse.
- Don't railroad (rule 15 P4) + the just-shipped "leading word" / single-source handles (T-04): frame the two axes as a review lens, additive on the existing contract, not a rigid new procedure that bloats the agent.
- The code-reviewer is read-only (Read/Glob/Grep) — the principle must NOT require it to run anything.
- I.6 retired-claim guard: no banned anchor. Framework agents edited directly in top-level `agents/` (no sync).
- T-05 just added the durability discipline to RA/pm-orchestrator; this is the same CLASS of additive-agent-contract edit — mirror that task's shape (terse rule, version bump, no count flip).
