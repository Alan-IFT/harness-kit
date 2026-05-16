---
name: harness-explore
description: Research / feasibility mode. Light-weight requirement analysis + a free-form findings document. No design, no Gate Review, no code. Use when "can we even do X?" is the question and you need evidence, not a vetted plan. Skips most of the 7-agent pipeline by design.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, WebFetch, TodoWrite, Task
---

# /harness-explore

Lightweight feasibility / research mode. Spend ~10-30 minutes finding out whether something is possible, not building it.

## When to invoke

- "Can library X handle our use case?"
- "Is provider Y's API rate-limit acceptable for our volume?"
- "What does the upstream codebase look like? Can we even patch it?"
- "Which of these 3 candidate approaches is most plausible — give me evidence per option"

The output is a **findings document with citations**, not a plan and not code.

## When NOT to invoke

- You already know the answer (skip to `/harness` or `/harness-plan`)
- The exploration would take days (split into smaller explore tasks)
- The thing under investigation is a clear bug (file a regular task)

## Procedure

The PM Orchestrator dispatches **only the Requirement Analyst** (lightly), then YOU (the PM or the user) do the exploration directly. There is no Architect, no Gate, no Developer, no QA.

1. **Create the task entry** in `docs/tasks.md` with `mode: explore` and `stage: exploring`.
2. **Create the task directory** `docs/features/<task-slug>/` and `PM_LOG.md`.
3. **Dispatch Requirement Analyst (light)** via Task tool. The Analyst writes a short `01_REQUIREMENT_ANALYSIS.md` containing:
   - The question being explored (1-3 sentences)
   - The success criteria for the exploration ("how will we know we have an answer")
   - The candidates to investigate (if applicable)
   - **No acceptance criteria, no detailed user stories** — exploration ≠ feature
4. **Conduct the exploration** (the PM or user does this directly with Read / Grep / WebFetch / Bash):
   - Read relevant code (existing project or upstream)
   - Run probe commands (`pip show`, `npm info`, `curl`-ing an API, etc.)
   - Search for past behavior in the codebase
   - Fetch upstream docs
5. **Write `findings.md`** in the task directory. Format:
   ```markdown
   # Findings: <question>

   ## Answer
   <one-paragraph direct answer>

   ## Evidence
   - Source 1: <link or file:line> — <what it shows>
   - Source 2: ...

   ## Implications for our project
   - <bullet>
   - <bullet>

   ## Recommended next step
   - <one of: "proceed via /harness-plan with approach X", "abandon — see evidence", "explore deeper — open follow-up task Y">
   ```
6. **Update tasks.md** `stage: explored`.
7. **If the exploration uncovered a non-obvious truth**, append a line to `.harness/insight-index.md` (see `.harness/rules/05-insight-index.md`).
8. **Report to user**: the answer, the recommended next step, where findings.md is.

## Output

```
docs/features/<task-slug>/
  01_REQUIREMENT_ANALYSIS.md  (light, ~1 page)
  findings.md                  (the actual deliverable)
  PM_LOG.md
```

No 02-07.

## Cost vs full pipeline

`/harness-explore` is ~15-20% of full pipeline cost. Don't bundle multiple unrelated questions — one explore task = one question.

## Anti-patterns

- **Do not** write code (other than throwaway probes). If you find yourself implementing the answer, switch to `/harness-plan` or `/harness`.
- **Do not** make verdicts about quality / architecture — that's the Architect's and Gate Reviewer's job in the full pipeline.
- **Do not** skip the `findings.md`. The artifact IS the point of the task.
- **Do not** swallow inconvenient evidence. Cite sources even when they contradict the hoped-for answer.
