# Task Input — vertical-slices (T-06)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Add a tracer-bullet **vertical-slice** decomposition discipline (each task an independently-verifiable end-to-end slice, NOT a horizontal layer) plus a **smart-zone** task-sizing heuristic (size a task to fit one ~120k-token reasoning window) to the harness-plan decomposition guidance and the batch/stream task-authoring guidance.

## Origin & rationale

T-06 of the mattpocock/skills adoption batch (idea ⑤). His `to-issues/SKILL.md` breaks a plan into **tracer-bullet vertical slices**: each issue is a thin slice cutting through ALL layers end-to-end (schema→API→UI→tests), demoable/verifiable on its own — explicitly NOT a horizontal slice of one layer. His `ask-matt/SKILL.md` adds the **smart zone** (~120k tokens — the window in which the model still reasons sharply; size a unit of work to fit it, hand off before degrading). Our `/harness-plan` decomposes a design into tasks, and `/harness-batch` + `/harness-stream` consume a task list (BATCH_PLAN.md rows) — the place to plant "what makes a GOOD task row."

Reference (read-only clone):
- `c:\Programs\_research\mattpocock-skills\skills\engineering\to-issues\SKILL.md` — the vertical-slice rules ("each slice delivers a narrow but COMPLETE path through every layer; a completed slice is demoable/verifiable on its own; NOT a horizontal slice of one layer"; tracer-bullet framing).
- `c:\Programs\_research\mattpocock-skills\skills\engineering\ask-matt\SKILL.md` — the smart-zone (~120k) framing + context-hygiene.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a concise vertical-slice + smart-zone task-decomposition discipline added to the relevant skill(s). The analyst/architect determine the best home(s) — candidates: `skills/harness-plan/SKILL.md` (where a design is decomposed into tasks), and the task-authoring guidance in `skills/harness-batch/SKILL.md` / `skills/harness-stream/SKILL.md` and/or `docs/batches/_template/BATCH_PLAN.md` (where rows are authored). Keep it terse; reference, don't duplicate across the three skills (single-source the discipline in one place and point at it, per the rule-15 compose-by-name + the just-shipped single-source-of-truth handle from T-04).

Out of scope (unless analyst argues with evidence): rewriting the harness-plan/batch/stream procedures; changing the BATCH_PLAN column schema; a new verify_all check; importing the GitHub-issue-specific template verbatim (we use BATCH_PLAN rows, not an issue tracker).

## Insights to honor (verify before relying)

- Editing distributed skill SKILL.md content is a shipped change → likely a version bump + CHANGELOG (precedent: any skill-content edit). Determine which skills change and whether the change is version-worthy. NO skill-count change (editing existing skills, not adding one) → no 16→17 fan-out.
- Doc-size: skills have no hard line cap in verify_all, but rule 70 + token economy apply — keep additions terse; single-source the discipline rather than pasting it into 3 skills (T-04 just shipped the "single source of truth" handle — practice it).
- If you single-source the discipline in one file and reference it from others, ensure the reference target is stable (e.g. a section in harness-plan, or a short shared note). Avoid deep cross-file `../other/FILE.md` references if the repo's convention is compose-by-name (rule 15 P8).
- I.6 retired-claim guard: introduce no banned anchor.
- Skills are distributed from top-level `skills/`; `.harness/skills/` mirror is empty (no harness-sync needed for top-level skill edits — confirm).
