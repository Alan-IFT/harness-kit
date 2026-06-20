# Task Input — skill-authoring-vocab (T-04)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Additively enrich `.harness/rules/15-skill-authoring.md` with the named skill-design vocabulary distilled from mattpocock/skills' `writing-great-skills` (leading word, completion criterion, premature completion, no-op test + the sediment/sprawl pruning discipline, single source of truth, and the context-load vs cognitive-load / user-vs-model-invoked lens) — WITHOUT rewriting the existing 8 principles.

## Origin & rationale

T-04 of the mattpocock/skills adoption batch (idea ③). His `writing-great-skills/SKILL.md` + `GLOSSARY.md` carry a sharp, reusable VOCABULARY our `15-skill-authoring.md` lacks as named handles. Our rule already covers (P1) write-description-for-the-model, (P2) don't-state-the-obvious, (P3) Gotchas surface, (P4) don't-railroad, (P5) progressive disclosure, (P6) hooks-for-hazards, (P7) store-scripts, (P8) skills-compose-by-name. We want to ADD the named concepts that give those ideas crisper handles and add genuinely new ones.

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\productivity\writing-great-skills\SKILL.md`
- `c:\Programs\_research\mattpocock-skills\skills\productivity\writing-great-skills\GLOSSARY.md` (the full definitions: predictability, leading word, completion criterion [clarity vs demand axes], premature completion, post-completion steps, legwork, no-op, sediment, sprawl, duplication, single source of truth, information hierarchy, context pointer, co-location, granularity, context load vs cognitive load, model-invoked vs user-invoked, router skill).

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: additive edits to `.harness/rules/15-skill-authoring.md` introducing the highest-value named concepts — at minimum: **leading word**, **completion criterion** (checkable + exhaustive), **premature completion**, **no-op test** + the **sediment/sprawl** pruning discipline, **single source of truth**, and a brief **user-invoked vs model-invoked** lens (context load vs cognitive load). Map each to our existing idiom/mechanisms where one exists (e.g. no-op test ≈ our P2 "don't state the obvious"; leading word generalizes our "write for the model"). Keep existing principles intact (additive only). Note credit to the source.

Out of scope (unless analyst argues with evidence): rewriting or renumbering the existing 8 principles; importing the FULL 18-term glossary verbatim (pick the high-value subset — token economy); any new verify_all check; any version bump or distribution change (this is a DOGFOOD-only repo rule under `.harness/rules/`, NOT a template/distributed asset — confirm: no fan-out, no plugin.json/README/CHANGELOG change, no skill-count change).

## Insights to honor (verify before relying)

- **I.2 doc-size cap: rule fragments ≤200 lines each.** `15-skill-authoring.md` is currently ~81 lines; the additions must stay under 200 (token economy — this is itself a "don't bloat" rule, so practice what it preaches).
- `.harness/rules/15-skill-authoring.md` is DOGFOOD-only (AI-GUIDE indexes it; dev-map lists it under repo-specific `.harness/rules/`). It is NOT in `templates/` and NOT distributed → editing it triggers NO skill-count/version/README/CHANGELOG fan-out. Confirm against the live repo before relying.
- I.6 retired-claim guard scans current docs; introduce no banned anchor.
- This rule is referenced (not composed) by AI-GUIDE — no sync needed; rule edits don't require harness-sync.
