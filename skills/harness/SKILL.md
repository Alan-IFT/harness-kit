---
name: harness
description: Full 7-stage Harness pipeline. Routes a real feature / bug / refactor task through Requirement Analyst → Solution Architect → Gate Reviewer → Developer → Code Reviewer → QA Tester → Delivery, with verify_all as the gate. Use when the task has a clear acceptance criterion and needs to ship. Symmetric with /harness-plan, /harness-explore, /harness-goal (the three lighter modes).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task
---

# /harness

Run the **complete 7-stage Harness pipeline** for a real feature / bug / refactor. This is the canonical mode — use it when the task has a clear acceptance criterion and you want to ship code.

## When to invoke

- Real feature work: "Add a CSV export button to the orders page."
- Real bug fix: "Race condition in the payment retry — fix it."
- Real refactor with a defined target: "Extract the auth middleware into its own package."
- Anything where the answer is "build and ship", not "research" or "evaluate" or "loop until X".

## When NOT to invoke

| Symptom of wrong mode | Use this instead |
|---|---|
| "Can we even do X?" / "Is library Y feasible?" | `/harness-explore` |
| "Vet this design before any code" / "先评审下这个想法" | `/harness-plan` |
| "Keep improving until <criterion>" / "重构到 verify_all 全绿" | `/harness-goal` |
| Typo / single-line fix / comment cleanup | Direct edit + `verify_all` |

## Procedure

The PM Orchestrator (you, if you're the PM, or a dispatched sub-agent) routes through all 7 stages strictly in order.

1. **Create the task entry** in `docs/tasks.md` with `mode: full` (or omitted — `full` is the default) and `stage: requirements`.
2. **Create the task directory** `docs/features/<task-slug>/` and `PM_LOG.md`.
3. **Read `.harness/insight-index.md`** before dispatching any stage — if any line applies, surface it to the relevant agent in their dispatch prompt.
4. **Dispatch `harness-kit:requirement-analyst`** via Task tool. Output: `01_REQUIREMENT_ANALYSIS.md`. Update `stage: design`.
5. **Dispatch `harness-kit:solution-architect`** via Task tool. Output: `02_SOLUTION_DESIGN.md`. Update `stage: gate-review`.
6. **Dispatch `harness-kit:gate-reviewer`** via Task tool. Output: `03_GATE_REVIEW.md`. If `CHANGES REQUIRED` or `REJECTED`, route back. If `APPROVED FOR DEVELOPMENT`, update `stage: development`.
7. **Dispatch `harness-kit:developer`** (or the assigned project-local partition agent — `dev-frontend` / `dev-backend` / `dev-db` / `dev-api` / `dev-services`) via Task tool. Output: `04_DEVELOPMENT.md`. Update `stage: code-review`.
8. **Dispatch `harness-kit:code-reviewer`** via Task tool. Output: `05_CODE_REVIEW.md`. If issues, route back to the developer. Update `stage: qa`.
9. **Dispatch `harness-kit:qa-tester`** via Task tool — **with the adversarial verification contract enforced** (see the `harness-kit:qa-tester` agent). Output: `06_TEST_REPORT.md` that MUST include `## Adversarial tests` section per acceptance criterion. Update `stage: delivery`.
10. **Write `07_DELIVERY.md`** (PM does this directly): summary + verify_all output + any `## Insight` section if the task surfaced non-obvious project truths. At this delivery boundary the PM also runs the cadenced, non-blocking entropy watch (full mode only) — see `agents/pm-orchestrator.md` → "Entropy watch at delivery". *(referencing line only — the call-sequence and section-format live there, not here)*
11. **Run `.harness/scripts/verify_all`**. Task is **not done** until it PASSes.
12. **Run `.harness/scripts/archive-task --task <task-slug>`** to harvest insights to `.harness/insight-index.md` and move stage docs to `docs/features/_archived/`.
13. **Update tasks.md** `stage: done` and report to user.

## Resuming from a partial run

If a previous `/harness-plan` run produced 01-03 documents for the same task slug, **skip stages 4-6** and jump to Developer. The 03_GATE_REVIEW.md's `APPROVED FOR DEVELOPMENT` verdict is the prerequisite — if missing, route through Gate Review first.

## Anti-patterns

- **Do not** skip stages. Every non-trivial change goes through all 7. If you find yourself "just writing a quick fix" without 01/02/03, you're either doing a trivial task (use direct edit) or a research task (use `/harness-explore`).
- **Do not** let agents self-route. The PM dispatches; sub-agents return; the PM decides next stage.
- **Do not** declare done without `verify_all` PASS and `archive-task` run.
- **Do not** modify upstream stage documents from a downstream stage. If Dev finds the design is wrong, write a blocker in `PM_LOG.md` and route back to Architect.

## Cost

Full 7-stage = 100% baseline. Use the lighter modes (`/harness-plan` ~35%, `/harness-explore` ~15%, `/harness-goal` budget-bound) when the task shape doesn't need the full pipeline.
