# 25 — Decision & escalation policy (harness-kit dogfood)

## What this is

Controls HOW a decision point is resolved when an AI agent working on this repo hits a
choice it would otherwise put to the user. A human-authored rubric
(`.harness/decision-rubric.md`) supplies the principles the AI decides by; a fixed set of
**red lines** always escalates regardless of mode. This lets the user preset their judgment
once and **review autonomous calls after the fact** instead of approving each one up front —
"review-after" replacing "decide-before".

## When to read this

- At the start of any task, **and whenever an agent is about to ask the user / call
  `AskUserQuestion` / "stop and ask"** — consult this BEFORE escalating.

## Active mode

**Active mode: 2 (rubric-guided autonomy, "balanced" calibration).**
New projects scaffolded by `/harness-init` default to **Mode 1**; this dogfood repo opts in
to Mode 2. Flip by editing this line.

## The two modes

- **Mode 1 — human decides (the safe default).** Any point the AI cannot resolve from the
  request, the code, or an unambiguous default goes to the user. This is the original harness
  behavior (RA "lists every ambiguity"; agents stop at judgment calls).
- **Mode 2 — rubric-guided autonomy.** The AI resolves any decision the rubric
  (`.harness/decision-rubric.md`) + the user's stated principles clearly cover — **including
  reversible design / implementation trade-offs** — decides, records it, and proceeds. It
  escalates only (a) the red lines below, and (b) decisions the rubric does not cover or that
  carry a major / irreversible trade-off. **Rubric coverage is the control knob:** a richer
  rubric delegates more; a sparse one degrades gracefully toward Mode 1.

## Red lines — ALWAYS escalate (both modes; the rubric cannot override these)

1. **Irreversible / destructive** — deleting or overwriting something not created in this
   task, history rewrite, force-push, dropping or migrating data.
2. **Outward-facing / publishing** — pushing to a shared branch, opening/merging a PR,
   sending a message or email, cutting a release, anything a third party will see.
3. **Scope expansion** beyond what the user asked — new features / tasks the user did not
   request are never invented autonomously (mirrors the `/harness-stream` rule).
4. **Conflict with an explicit user constraint** — a CLAUDE.md red line, a stated "don't…",
   or the project's own governance rules.
5. **Security-sensitive** choices (auth, secrets, permissions, crypto, security-surface deps)
   and **cost / quota commitments** (paid services, large compute).
6. A choice the AI assessed and is **genuinely uncertain** about with material downside.

(In THIS repo all commits/pushes are the operator's per the user's standing instruction, so
red line #2 is already honored — agents leave a green tree and the operator pushes.)

## How an agent applies it (Mode 2)

At a would-be escalation point:
1. **Red line?** → escalate. Stop.
2. **Does the rubric + the user's principles clearly cover it?** → decide accordingly,
   **log the decision** (point · options · choice · rubric basis), proceed.
3. **Otherwise** (uncovered, or major / irreversible trade-off) → escalate, and name the
   rubric line that WOULD have let you decide it (so the user can extend the rubric).

## Audit trail (what makes "review-after" safe)

Every autonomous Mode-2 decision is recorded so the user can spot-check rather than
pre-approve:
- **Pipeline tasks** → one line in the task's `PM_LOG.md`.
- **Direct / ambient work** → a short "decisions made" list in the AI's response.

A decision the user later reverses becomes a new rubric line (or a red-line tweak) — the
policy learns.

## Scope of this version

v1 governs the **orchestration / main-agent escalation layer** (where the user's friction
actually is — the agent driving the session over-asking). The deep per-agent integration —
teaching the pipeline's RA/PM contracts to be rubric-aware so dispatched stages also self-
resolve covered ambiguities — touches agent definitions and is a separate pipeline follow-up.

## Changing the policy

- **Flip the active mode** → edit the "Active mode" line above.
- **Tune what's autonomous** → edit `.harness/decision-rubric.md` (no code change — agents
  read it at decision time). Widen to delegate more; trim to delegate less.
- The **red lines** are deliberately NOT in the rubric — they are a fixed safety floor.
