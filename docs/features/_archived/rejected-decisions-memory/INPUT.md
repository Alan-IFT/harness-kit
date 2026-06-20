# Task Input — rejected-decisions-memory (T-09)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Generalize the ad-hoc "Deliberately not adopted" pattern into a lightweight **rejected-decisions memory** (mattpocock/skills' `.out-of-scope/` idea) that prevents re-litigating declined requests/approaches — assessing whether a dedicated file or a documented convention on existing surfaces is the lighter fit, plus a light read/append habit. No heavy machinery.

## Origin & rationale

T-09 (Tier-3 ⑨) of the mattpocock/skills adoption batch. His `triage/OUT-OF-SCOPE.md` + `.out-of-scope/` directory keep a persistent record of REJECTED feature requests (one file per concept) so a new request matching a prior rejection surfaces the old decision instead of re-litigating it — institutional memory + dedup. We already do this ad-hoc: `.harness/rules/15-skill-authoring.md` has a "Deliberately not adopted" section (e.g. skill-usage telemetry); this very batch declined items (design-it-twice, ask-matt router, issue-tracker, etc.). But we have NO general, consistently-located memory of "we decided NOT to do X and why" — so a future session could re-propose a thing we already rejected.

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\OUT-OF-SCOPE.md` — the `.out-of-scope/` KB: one file per concept, why-it's-out-of-scope, prior requests, check-during-triage, when-to-write.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a lightweight rejected-decisions memory mechanism. The analyst/architect determine the LIGHTER fit between:
- (a) a dedicated memory file (e.g. `.harness/rejected-decisions.md` or `docs/decisions/rejected.md`) alongside the existing memory layer (insight-index, decision-rubric, CONTEXT.md), indexed in AI-GUIDE, with a one-line "read at decide-points / append when something is deliberately declined" habit; OR
- (b) a documented CONVENTION that formalizes + locates the existing ad-hoc "Deliberately not adopted" practice (e.g. a standard heading + where it lives), without a new always-loaded file.
Pick whichever is lighter and genuinely useful; wire a light read/append habit into the relevant agent/rule (e.g. RA or solution-architect or a rule fragment). Seed it with the genuine rejections from THIS batch (the Tier-3/Tier-4 declines) if a file is chosen.

Out of scope (unless analyst argues with evidence): mattpocock's issue-tracker dedup automation (we have no issue tracker); a new verify_all check/guard (this is memory, not a gate — feedback_design_over_guards); a heavy per-concept-file directory structure if a single file or convention suffices (token economy); auto-matching machinery.

## Insights to honor (verify before relying)

- Memory-layer discipline: insight-index is ≤30 evidence lines (I.4 cap) and is for hard-won TRUTHS; decision-rubric is autonomy principles; CONTEXT.md (T-02) is the domain glossary. A rejected-decisions memory is a DISTINCT fourth kind (declined options + why) — don't overload insight-index with it. If a new file, decide whether it needs a size cap (prefer NOT adding a verify_all guard; a soft self-discipline like CONTEXT.md is better).
- If a new file is dogfood + template: follow the decision-rubric/CONTEXT.md dual-purpose pattern (generic seed in templates/common/, real content in repo; not byte-synced).
- AI-GUIDE ≤200 (I.1); if indexed, one terse line.
- Distributed change (template asset and/or agent/rule edit) → likely a version bump; no count flip. Confirm.
- I.6 retired-claim guard: introduce no banned anchor (a "rejected decisions" doc that quotes a retired claim could self-trip — phrase carefully).
- This batch's own declines are good seed content: design-it-twice (deferred), ask-matt router (we have AI-GUIDE table), issue-tracker/triage/to-prd (no tracker, too heavy), tdd/diagnosing-bugs as skills (covered), git-guardrails/setup-pre-commit (have guard-rm/install-hooks), teach/handoff/writing-*/personal (non-fit), skill-usage telemetry (existing).
