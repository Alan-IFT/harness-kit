---
name: harness-grill
description: Relentlessly interview the user ONE question at a time to pin down what they
  actually want BEFORE any pipeline runs — a pre-pipeline alignment session that walks the
  design tree, gives a recommended answer for every question, explores the codebase to
  self-answer instead of asking when the repo already decides it, reads CONTEXT.md for
  canonical terms when present, and emits an aligned brief to docs/features/<slug>/INPUT.md
  that /harness, /harness-plan, or the /harness-stream pool then consumes. User-invoked
  only (you start the session deliberately); it does not write design, code, or findings
  and does not change the 7-stage pipeline. Use when "grill me on this", "interview me
  about this plan", "pin down what I actually want before we build", "stress-test my
  requirement first", "拷问我的需求", "逐条对齐需求", "动手前先把需求问清楚", "先把需求拷问
  清楚再开干". NOT /harness (requirement already clear enough to ship), NOT /harness-plan
  (vet an existing design, not discover the requirement), NOT /harness-explore (feasibility
  "can we even do X?" research) — grill is the "I'm not sure I've said what I actually
  want yet" front-end that PRECEDES all three.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, TodoWrite
---

# /harness-grill

A relentless, pre-pipeline **alignment interview**: one question at a time, a recommended
answer per question, self-answering from the codebase where it can — until you and the
agent share an understanding of what you actually want. It ends by writing an **aligned
brief** to `docs/features/<slug>/INPUT.md` and **stops**. It does not run the pipeline.

## When to invoke

- You have a fuzzy idea and want it pinned down before the pipeline spends effort on the
  wrong target — "grill me on this", "interview me about this plan", "pin down what I
  actually want before we build", "stress-test my requirement first".
- 中文触发："拷问我的需求"、"逐条对齐需求"、"动手前先把需求问清楚"、"先把需求拷问清楚再开干"。
- You suspect "the agent will build something subtly off" — grill targets exactly that #1
  failure mode by forcing the ambiguities into the open *before* any code is written.

## When NOT to invoke

The bright-line delta vs the three sibling work-starting skills:

- **Requirement already clear enough to ship** → `/harness` (full 7-stage pipeline).
- **You have a design and want it vetted** (not to discover the requirement) → `/harness-plan`.
- **"Can we even do X?" feasibility** research with evidence → `/harness-explore`.

Grill is **PRE-pipeline alignment**. It produces a brief and STOPS — it never runs the
pipeline, writes design or code, or produces findings. It is the "I'm not sure I've said
what I actually want yet" front-end that *precedes* all three of the above.

## User-invoked only

This is a deliberately **user-started** session — the human types a grill trigger to start
an alignment session on purpose. Do **not** invoke it as a side effect of another task, and
do not auto-fire it on an ordinary request. (Its triggers are all explicit, deliberate
phrasings, so it does not match incidental asks.)

## The interview engine

Interview relentlessly until you reach a shared understanding of what the user wants. Walk
down each branch of the design tree, resolving dependencies between decisions one by one.
The invariants (adapt the order to the conversation — this is not a rigid script):

1. **One question at a time.** Ask exactly one open question per turn and **wait for the
   user's answer** before asking the next. Asking multiple questions in a single turn is
   bewildering — never batch (see Anti-patterns).
2. **A recommended answer per question.** Present every question *with* your own
   **Recommended:** answer. The user may accept it, override it, or refine it.
3. **Explore the codebase to self-answer.** Before asking, check whether the repository
   already answers the question — existing conventions, file locations, prior art, what a
   symbol already does. If it does, **resolve it yourself**: state what you found and the
   chosen resolution, record it, and do **not** ask the user.
4. **Empty / "I don't know" answer** → adopt your Recommended answer as the working default
   and continue. Never hang waiting on a perfect answer.

## CONTEXT.md composition (SOFT dependency)

If a project glossary `CONTEXT.md` (usually repo root) is present, read it and use its
canonical terms when phrasing questions and writing the brief. If you coin or sharpen a
domain term during the interview, lazy-maintain it inline in `CONTEXT.md` (bold term + a
1-2 sentence definition + an `_Avoid_:` list of synonyms) — the same SOFT contract the
requirement-analyst and solution-architect already follow.

If `CONTEXT.md` is absent: just proceed without it. Never block, never print a setup
pointer, and never create `CONTEXT.md` solely to populate it — create or sharpen it **only**
when a term is genuinely coined during the interview.

## The terminal artifact — the aligned brief

When the session reaches alignment (or the user ends it early), write **one** brief:

- **Slug.** Propose a kebab-case `<slug>` derived from the agreed goal and confirm it with
  the user (fall back to a slug the user supplies). This mirrors how the PM already slugs
  tasks.
- **Path.** `docs/features/<slug>/INPUT.md`. Create the `docs/features/<slug>/` path as
  needed — do not fail because the parent directory is absent.
- **Collision.** If the target `INPUT.md` already exists, **confirm before overwriting** —
  never silently clobber an unrelated brief. On decline, offer a different slug.
- **Brief shape** (so the requirement-analyst can consume it as its `INPUT.md`):
  - a one-sentence **Goal**;
  - the **resolved decisions** (each: question → agreed answer, noting where a decision was
    self-answered from the codebase);
  - any **residual open items**;
  - if relevant, a **Glossary touches** note listing terms coined or sharpened in
    `CONTEXT.md`.
  The brief is the requirement-analyst's *input*, not a requirement spec itself — it does
  not pre-empt the RA's structured 9-section document.
- **Early end.** If the user ends before alignment is complete, write whatever was agreed
  and record the residual open items in the brief — never silently lose the partial
  interview.

## Not a pipeline stage

Grill is a standalone front-end. It does **not** alter `pm-orchestrator` routing or the
7-stage flow, and it does not dispatch any agent. After writing the brief, tell the user how
to pick it up: run `/harness <slug>` (or `/harness-plan <slug>`), or drop the slug into a
`/harness-stream` pool. Then **stop**.

## Anti-patterns

- **Asking multiple questions in one turn.** One at a time, always — batching is
  bewildering.
- **Asking the user a question the codebase already answers.** Explore and resolve it
  yourself instead.
- **Silently overwriting an existing brief.** Confirm before overwriting an existing
  `INPUT.md`.
- **Running the pipeline / writing design or code / producing findings.** Out of scope —
  emit the brief and stop.
- **Blocking on an absent `CONTEXT.md`.** It is a convenience, never a precondition.
