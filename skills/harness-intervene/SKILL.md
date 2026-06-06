---
name: harness-intervene
description: Drop a redirect / pause / note / add-task signal into a running 7-stage Harness pipeline (or a /harness-stream pool). Use when an autonomous task needs course correction, or a new task queued, without killing the session. Writes .harness/intervention.md which the PM Orchestrator (or the stream loop) picks up at the next stage / task boundary.
allowed-tools: Read, Write, Bash, PowerShell
---

# /harness-intervene

Soft Ctrl-C for an in-flight Harness pipeline.

## When to use

- The pipeline is mid-task and you want to redirect the next stage without aborting.
- You want to pause for review at the next stage boundary.
- You want to leave a note for the next downstream agent (e.g., "DB rotation today, use --dry-run").
- You're on a different tool/session than the one running the pipeline (e.g., Copilot redirecting a Claude Code task).

**Do not use** for:
- Permanent project rules → add a `.harness/rules/*.md` fragment.
- Cross-task lessons → emit `## Insight` in the task's `07_DELIVERY.md`.
- Bug reports → use `docs/tasks.md`.

## How it works

1. You (or this skill) write `.harness/intervention.md` at the project root.
2. PM Orchestrator checks for the file after every stage completion.
3. If found, PM consumes it: logs into `PM_LOG.md`, takes the implied action, deletes the file.
4. Pipeline continues with your redirect applied (or halts, per your directive).

Full protocol: `.harness/rules/65-intervention.md`.

## Procedure

1. Detect intent from the user's request. The first-line keyword controls PM behavior:

| Intent | First-line keyword | Effect |
|---|---|---|
| Halt now, surface to user | `STOP — <reason>` | Pipeline halts at next stage boundary. |
| Override next stage's brief | `REDIRECT <stage> — <text>` | PM rewrites the stage's brief; routes back if past it. |
| Skip stage 5 (review) or 6 (QA) | `SKIP <stage> — <reason>` | Stage skipped with logged rationale. Forbidden for stage 3. |
| Informational note | `NOTE — <text>` | Attached to next dispatch; pipeline continues. |
| Add a task to a running stream pool | `ADD <slug> — <goal>` | Appended as a `pending` row to the active `/harness-stream` pool; planned on the next iteration. **Stream-only** — only meaningful while `/harness-stream` is draining a pool (a `/harness-batch` plan is frozen; a single-task PM only logs it as a note). |

Stage numbers: `01` requirement-analysis · `02` solution-design · `03` gate-review · `04` development · `05` code-review · `06` qa · `07` delivery. `ADD`'s argument is a task slug, not a stage number.

2. Check whether `.harness/intervention.md` already exists.
   - If it does, **STOP** and ask the user — there's already an unread intervention; overwriting would silently discard it.
   - The user can choose: "append to existing", "overwrite", or "cancel".

3. Write `.harness/intervention.md` using this skeleton:

```markdown
# Intervention

<KEYWORD> <args> — <message>

<optional additional paragraphs — PM uses LLM understanding; keep it concise>
```

4. Confirm what was written and remind the user of the pickup timing:

```
Wrote .harness/intervention.md (NOTE keyword).

The PM Orchestrator will consume it at the next stage boundary.
If the pipeline is between stages right now, it'll be picked up at the next dispatch.
If no /harness* task is currently in flight, it stays as-is for the next task.
```

For an **`ADD`** intervention the consumer is different — emit an ADD-specific reminder instead:

```
Wrote .harness/intervention.md (ADD).

A running /harness-stream pool consumes this at the next task boundary and queues the task.
If no stream is currently draining a pool, a single-task PM will only log it as a note —
start /harness-stream <pool-id> (or append the row to BATCH_PLAN.md) to actually queue it.
```

5. Do NOT also message the agents directly or modify stage docs — intervention.md is the only channel for this signal.

## Examples

User: "tell the dev to skip websockets for now, ship REST first"

You write:
```markdown
# Intervention

REDIRECT 04 — Skip the websocket layer for now; ship the REST API end-to-end first. Websockets can be a follow-up task once the REST surface stabilizes.
```

---

User: "stop the pipeline, I want to review the design before code is written"

You write:
```markdown
# Intervention

STOP — User requested manual design review before stage 4. Please summarize the current state of 02_SOLUTION_DESIGN.md and wait for green light.
```

---

User: "skip the QA stage for this fast-follow"

You write:
```markdown
# Intervention

SKIP 06 — Fast-follow patch; user explicitly waived QA for this scoped change. Document the waiver in 07_DELIVERY.md.
```

---

User: "tell whoever's doing dev work that the DB is being rotated this afternoon"

You write:
```markdown
# Intervention

NOTE — Database is being rotated this afternoon (~16:00 local). If your work touches migrations or schema, gate them behind a --dry-run flag for now and surface them in 07_DELIVERY.md so they can be applied after rotation.
```

---

User: "while the stream runs, also add a task to add CSV export to the orders page" (a `/harness-stream` pool is active)

You write:
```markdown
# Intervention

ADD orders-csv-export — Add a CSV export button to the orders page that downloads the current filtered result set. Backend endpoint + frontend button + a test.
```

## Hard rules

- **One pending intervention at a time.** Refuse to overwrite without explicit user confirmation.
- **Never** put rules, insights, or bug reports here. Wrong channel.
- **Never** skip stage 3 (gate-review) — refuse and explain why if the user asks.
- **Never** dispatch agents from this skill. Only write the file; the PM picks it up.
- **Do not** delete `.harness/intervention.md` yourself once written — that's PM's job after consumption.
