# 15 — Skill & agent authoring (harness-kit dogfood)

## What this is

How to write a skill (`skills/<name>/SKILL.md`) or agent (`.harness/agents/<name>.md`) so it
actually fires when it should and stays maintainable. Distilled from Anthropic's
"Lessons from building Claude Code: how we use skills"
(https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills) and mapped onto
the mechanisms this repo already has. The named vocabulary in "Named vocabulary" below is
distilled from mattpocock/skills `writing-great-skills` (its `GLOSSARY.md`). This repo **is** a
skills distribution, so most non-trivial work here is skill / agent authoring — these are the
house rules for it.

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

## Named vocabulary (mattpocock/skills)

Crisp handles for the ideas above — reuse these as the canonical words when reviewing a
skill. Each maps to an existing principle, or is marked **new** where this rule had no handle.

- **Leading word** (a.k.a. *Leitwort*) — a compact pretrained concept the model thinks *with*
  while running the skill; repeated as a token (never a sentence) it anchors a region of
  behaviour for the fewest tokens. Generalizes **P1** ("write for the model"): word the
  `description:` and the body with the leading words you actually type when you want the skill.
- **No-op test** — "does this line change behaviour versus the model's default?" If not, it is
  a no-op: you pay load to say what the model already does. The named handle for **P2** ("don't
  state the obvious"); it is also how you grade whether a leading word still beats the default.
- **Completion criterion** *(new — no prior handle)* — the bar that tells the agent a unit of
  work is done, on two axes: **checkable** (clear — can it tell done from not-done?) and
  **exhaustive** (demanding — "every X accounted for", not "produce a list"). The strongest
  criteria are both.
- **Premature completion** *(new — no prior handle)* — ending a step before it is genuinely
  done, attention slipping to *being* done. Defence, in order: **sharpen the criterion first**
  (local, cheap); only if it is irreducibly fuzzy *and* you observe the rush, **hide the later
  steps** by splitting the sequence across a real context boundary.
- **Sediment / sprawl** — the two length faults this rule's anti-bloat stance prunes against:
  **sediment** is stale layers never cleared (adding feels safe, removing feels risky);
  **sprawl** is length itself even when every line is live and unique. Cure both via the **P5**
  progressive-disclosure ladder and the `70-doc-size.md` cap — the ≤200-line cap this very file
  is held to.
- **Single source of truth** — each meaning lives in exactly one authoritative place; its
  violation is **duplication**. This is the repo's existing anti-bloat stance ("delete
  duplication rather than guard it", see "Deliberately not adopted") given its name.
- **User-invoked vs model-invoked** *(new lens)* — keep the `description:` and the skill is
  model-invoked (agent-discoverable, reachable by other skills, pays a per-turn **context
  load**); strip it and it is user-invoked (zero context load, but spends the human's
  **cognitive load** — they become the index of which skill to reach for).

## Deliberately not adopted

Project-wide declined options (incl. **skill-usage telemetry / per-call usage logging** — the
blog's "log every invocation" hook, which we decline as a standing per-call cost that buys nothing
for a single-maintainer repo) now live in **`.harness/rejected-decisions.md`** with their reasons.
Record a new skill/agent-authoring decline there, not here — one source, no drift.

## Adversarial check (before shipping a skill / agent)

> If a user typed the most natural phrasing of this need — in English **and** in 中文 — would the
> `description:` alone make Claude pick THIS skill over its siblings?

- **Yes** → ship it.
- **Only because I know the internals** → the description is written for you, not the model. Rewrite per P1.
- **It triggers, but on the wrong requests** → add the *when NOT to* delta.
