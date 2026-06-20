# Task Input — sa-design-vocab (T-07)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Give the `solution-architect` the codebase-design **deep-module vocabulary** (module, interface, depth, seam, adapter, leverage, locality) plus the **deletion test** and "interface is the test surface" / "one adapter = hypothetical seam, two = real" principles, as an OPTIONAL design-language section — EXCLUDING the heavier design-it-twice parallel-subagent pattern this round.

## Origin & rationale

T-07 (final) of the mattpocock/skills adoption batch (idea ⑥). His `codebase-design/SKILL.md` carries a precise, reusable architecture vocabulary our solution-architect lacks as named handles: **deep module** (a lot of behaviour behind a small interface), **interface** (everything a caller must know — not just the type signature), **depth** (leverage per unit of interface), **seam** (where the interface lives), **adapter** (concrete thing satisfying an interface at a seam), **leverage** (caller payoff), **locality** (maintainer payoff). Plus sharp tests: the **deletion test** (imagine deleting the module — if complexity vanishes it was a pass-through; if it reappears across N callers it earned its keep), "the **interface is the test surface**", and "one adapter means a hypothetical seam, two means a real one."

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\engineering\codebase-design\SKILL.md` — the glossary + principles + deep-vs-shallow + designing-for-testability.
- `c:\Programs\_research\mattpocock-skills\skills\engineering\codebase-design\DEEPENING.md` (dependency categories — context, optional) and `DESIGN-IT-TWICE.md` (the parallel-subagent pattern — EXPLICITLY OUT OF SCOPE this round).

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: an OPTIONAL, terse design-language section added to `agents/solution-architect.md` introducing the deep-module vocabulary (module / interface / depth / seam / adapter / leverage / locality) + the deletion test + "interface is the test surface" + "one adapter = hypothetical seam, two = real". Framed as a LENS the architect MAY use when designing module boundaries (not a mandatory step / not railroading — per rule 15 P4). Keep it terse and additive; do not rewrite the existing solution-architect contract.

Out of scope (unless analyst argues with evidence): the design-it-twice parallel-subagent pattern (heavier; deferred — note as a future option only); the DEEPENING dependency-category taxonomy in full (a one-line pointer is enough if any); any new verify_all check; mandating the vocabulary (it is a lens the architect MAY reach for, not a required section in every 02_SOLUTION_DESIGN).

## Insights to honor (verify before relying)

- solution-architect.md was edited by T-02 (CONTEXT.md soft-dep) earlier this batch — this is another additive edit on top; keep it additive. I.3 cap: agents ≤300 lines (solution-architect ~122-123 now) — terse.
- Editing a plugin-native distributed agent (`agents/*.md`) is a shipped change → version bump + CHANGELOG likely (precedent T-05 0.36.0; T-06 took 0.37.0 → this would be 0.38.0). NO count change (content not count; 16/8/32 stay). Confirm against the live repo.
- Don't railroad (rule 15 P4): the vocabulary is a LENS the architect adapts, not a rigid checklist. The just-shipped T-04 "leading word" handle is exactly what these terms are — frame them so.
- Compose-by-name / single-source: if useful, the architect MAY note these terms could also seed `CONTEXT.md` (T-02) — but keep it light.
- I.6 retired-claim guard: introduce no banned anchor. Framework agents edited directly in top-level `agents/` (no sync).
