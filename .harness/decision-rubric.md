# Decision Rubric — the principles the AI decides by

> Read by agents at every would-be escalation point — see `.harness/rules/25-decision-policy.md`.
> **You edit this freely:** add a line to delegate more, remove one to delegate less.
> The **red lines** in `25-decision-policy.md` always override this — they are not negotiable here.
> **Mode 2** reads the **Preset rubric** below; **Mode 3** reads the **Custom rubric** at the bottom.

## Preset rubric (Mode 2)

### Prime directive

Decide by these three principles; when they conflict, resolve in this order:
1. **Good user / operator experience.**
2. **Sound software engineering** — correctness, real tests, maintainable structure, honest reporting.
3. **Long-term ease of use & maintainability** over short-term shortcuts.

### Standing preferences (seeded 2026-06-10 from the operator's prior guidance)

- **Lightweight over heavy.** For a personal / single-maintainer project, drop over-built
  modules (vaults, tiered budget systems, heavyweight eval harnesses, production tracing).
  Prefer the smallest thing that meets the bar.
- **Design out the root cause; don't accrete guards.** Prefer eliminating a problem *class*
  by better design over piling on checks / guards / patches (which bloat the project). A new
  `verify_all` check or hook must prevent a concrete hazard, not just "feel safe".
- **Reversible & in-scope → just do it.** Refactors, doc fixes, implementation choices, file
  layout, naming, adding tests — decide and execute; report after.
- **Match existing conventions** — code style, file layout, the harness's own patterns —
  rather than introducing new ones.
- **Honest reporting, always.** State outcomes plainly: what changed / current state / what to
  watch. Never fabricate test tallies or success claims — paste from real runs.
- **Verify before declaring done** — `verify_all` PASS (and, for this repo's tooling, the
  relevant test driver too).
- **Language** — chat replies in Chinese; project file artifacts follow each repo's own policy
  (this repo: English).
- **Commits & pushes** — the operator has standing authorization for the AI to commit AND push
  on their behalf; leave a green tree and report change details / current state / attention items.
- **Profile before optimizing** a performance issue — fix the measured bottleneck, not the
  obvious-looking suspect.

### Escalate anyway (rubric-uncovered examples — extend me as they recur)

- A product-direction call with no clear principle answer (e.g. which of two good features first).
- A trade-off where the three principles genuinely conflict and the call is consequential.
- Anything matching a red line in `25-decision-policy.md`.

## Custom rubric (Mode 3)

> Author your OWN decision prompts here — under **Mode 3** the AI reads ONLY this section (the
> Preset above is ignored). The three prime principles and the red lines in
> `25-decision-policy.md` still apply. Empty by default; `/harness-decision-mode` fills this in
> on your first switch to Mode 3, or you can write it yourself.

_(empty — no custom rubric authored yet)_
