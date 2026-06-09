# 15 — Skill & agent authoring (harness-kit dogfood)

## What this is

How to write a skill (`skills/<name>/SKILL.md`) or agent (`.harness/agents/<name>.md`) so it
actually fires when it should and stays maintainable. Distilled from Anthropic's
"Lessons from building Claude Code: how we use skills"
(https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills) and mapped onto
the mechanisms this repo already has. This repo **is** a skills distribution, so most non-trivial
work here is skill / agent authoring — these are the house rules for it.

This is the **quality bar**. `CONTRIBUTING.md` → "Adding or changing a skill" is the **mechanical
checklist** (frontmatter, `allowed-tools`, README/CHANGELOG/install fan-out). Read both.

## When to read this

- Before adding or materially changing any `skills/<name>/SKILL.md` or `.harness/agents/<name>.md`.
- When a skill exists but isn't triggering — the `description:` is the prime suspect (see P1).
- When a SKILL.md is growing past one screen and you're deciding what to keep inline (see P5).

## The principles (blog lesson → our mechanism)

1. **Write the description for the model, not the human.** The `description:` frontmatter is the
   only thing Claude scans to decide "is there a skill for this?" Lead with the concrete triggers a
   user would actually type — both English and 中文 — and an explicit *when NOT to use* delta against
   sibling skills. The `AI-GUIDE.md` "Workflow entry" table indexes those same triggers; keep the
   SKILL.md description and that table in agreement.

2. **Don't state the obvious.** Spend lines on what pushes Claude *out* of its default behaviour —
   the project-specific contract, the ordering constraint, the gotcha — not on re-explaining what a
   well-known tool or language already does. Every line costs context budget on every load (`70-doc-size.md`).

3. **A Gotchas surface is the highest-signal content.** In our idiom that is two things working
   together: each skill's own **"When NOT to invoke" / "Anti-patterns"** section (the static, known
   traps) and the project-wide, evidence-backed **`.harness/insight-index.md`** (the ones learned the
   hard way, harvested by `archive-task`). When a skill bites, the fix lands in one of those two —
   never as a silent inline patch. Treat a skill's first version as a seed: it earns its depth as
   real edge cases get appended, not by being exhaustive on day one.

4. **Don't railroad.** Give the agent the constraints and the failure modes, then let it adapt.
   Prefer "here is the contract + here is what breaks it" over a rigid step list that fails the moment
   reality differs. The agent definitions that survive rollbacks state *invariants*, not scripts.

5. **Progressive disclosure — load by trigger, not all at once.** This is the spine of the repo:
   `AI-GUIDE.md` indexes, rule fragments carry a "when to read" trigger, agents load on dispatch.
   Apply the same shape *inside* a skill: when a SKILL.md outgrows the genuinely always-needed
   instruction, push the detail into a sibling file the skill points at on demand (a `references/`
   note or a template under the skill dir) instead of front-loading it. Keep every file under its
   `70-doc-size.md` cap.

6. **On-demand hooks are for hazards, not bookkeeping.** A hook earns its place only when it must
   intercept something Claude cannot be trusted to never do (`guard-rm` PreToolUse) or when a turn
   legitimately becomes a heartbeat (`ambient-prompt` UserPromptSubmit). A hook that runs on every
   call just to record something is a standing tax — see "Deliberately not adopted".

7. **Store scripts; compose, don't reconstruct.** When a skill needs real logic (file rewrites,
   cross-shell parity, byte-identity) put it in a `.{ps1,sh}` pair under `.harness/scripts/` and have
   the skill *call* it. Keep the PowerShell and Bash halves symmetric (`30-engineering.md` #20).

8. **Skills compose by name.** Reference a sibling skill / agent by name and let the dispatcher
   resolve it — the whole 7-stage pipeline is exactly this (`pm-orchestrator` names the downstream
   roles). Never inline a copy of another skill's logic.

## Deliberately not adopted

- **Skill-usage telemetry / per-call usage logging.** The blog suggests a `PreToolUse` hook that logs
  every skill invocation to find under-triggering skills. We decline it: it is a standing per-call
  cost for a single-maintainer project and cuts against this repo's anti-bloat line — we delete
  duplication rather than guard it, and we don't add a check or a resident hook unless it prevents a
  concrete hazard. If usage data is ever needed, gather it ad hoc, not as resident instrumentation.
  (Recorded here so a future contributor doesn't "helpfully" re-add it.)

## Adversarial check (before shipping a skill / agent)

> If a user typed the most natural phrasing of this need — in English **and** in 中文 — would the
> `description:` alone make Claude pick THIS skill over its siblings?

- **Yes** → ship it.
- **Only because I know the internals** → the description is written for you, not the model. Rewrite per P1.
- **It triggers, but on the wrong requests** → add the *when NOT to* delta.
