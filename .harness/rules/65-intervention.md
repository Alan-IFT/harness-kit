# 65 — Mid-task intervention protocol (harness-kit dogfood)

## What this is

`.harness/intervention.md` is a **single-shot signal file** the human (or another tool) drops to redirect, pause, or annotate an in-flight 7-stage task. The PM Orchestrator reads it at each stage boundary, logs the consumption into `PM_LOG.md`, then **deletes the file** — presence means "unread", absence means "no pending intervention".

This gives any user a tool-agnostic "soft Ctrl-C" for long autonomous runs: write a file, the next stage transition picks it up. No process kill, no chat-window race, no agent shouting match. Works equally well across Claude Code sessions, Copilot sessions, or human/PM communication.

## File location

Always at repo root: `.harness/intervention.md`.

Never inside `docs/features/<task>/` — task-scoping is automatic because the PM only reads it during an active task.

## Read points (PM Orchestrator)

1. Immediately after the file `docs/features/<task>/PM_LOG.md` is created (before stage 1 dispatch).
2. After **every** stage completion, before deciding the next route (advance / rollback / stop).
3. At the start of any iteration in `goal` mode (Dev → QA loop).

Read = `Test-Path .harness/intervention.md`. If present, `Read` its content, act on it, then `Remove-Item` it.

## File schema (freeform-with-hints)

The body is **freeform markdown** — PM uses normal LLM understanding to act on it. Optional structured first-line hint lets you skip ambiguity:

```markdown
# Intervention

STOP — <reason for user-visible halt>
```

```markdown
# Intervention

REDIRECT 04 — Skip the websocket layer, ship REST first; we can add WS in a follow-up task.
```

```markdown
# Intervention

NOTE — The DB cluster is being rotated this afternoon; if you need migrations, gate them behind the `--dry-run` flag for now.
```

Recognized first-line keywords (case-sensitive, must follow the `# Intervention` header):

| Keyword | PM action |
|---|---|
| `STOP` | Halt the pipeline. Write the message to PM_LOG.md and surface to the user with current stage state. Do not auto-resume. |
| `REDIRECT <stage>` | Override the brief for stage `<stage>`. If already past that stage, route back to it. Log redirect rationale to PM_LOG.md. |
| `SKIP <stage>` | Skip the named stage with the given rationale. Allowed only for stages 5 (code-review) and 6 (QA); skipping 3 (gate) is forbidden. |
| `NOTE` | Acknowledge in PM_LOG.md, attach to the dispatch prompt of the next downstream agent, continue. |
| (no keyword) | Treat as `NOTE` if benign, `STOP` if ambiguous and consequential. Surface to user when in doubt. |

Stage numbers refer to the table in `pm-orchestrator.md` (`01` = requirement analysis, `04` = development, etc.).

## PM consumption protocol

When PM reads an intervention:

1. Copy the full content into the active task's `PM_LOG.md` under a `## Intervention consumed at <ISO timestamp>` heading.
2. Take the action implied by the keyword (above).
3. Delete `.harness/intervention.md` (its purpose is fulfilled; staleness would cause re-application).
4. Continue routing as adjusted, or halt if STOP.

If no task is active (no `docs/features/<task>/PM_LOG.md` yet because no `/harness*` invocation is in flight), PM leaves the file alone — it's addressed to whoever runs the next task. Mention this in any user reply.

## Who writes intervention.md

- The human user, by hand or via `/harness-intervene` skill (which generates the template skeleton).
- Another AI tool session redirecting an inflight pipeline (e.g., Copilot signaling Claude Code).
- **Never an agent inside the pipeline.** Agents communicate via stage docs and BLOCKED markers; using `.harness/intervention.md` from inside would be a side-channel and is forbidden.

## What NOT to put in intervention.md

- Permanent rules → add a `.harness/rules/*.md` fragment instead.
- Cross-task insight → wait for stage 7 and emit `## Insight` in `07_DELIVERY.md` (archive-task harvests it).
- Bug reports → use `docs/tasks.md`.

Intervention is **transient task-scoped redirection only**. If the same intervention shows up twice, the second occurrence is a sign it should become a permanent rule.

## Verification

`.harness/scripts/verify_all` does **not** validate `.harness/intervention.md` schema — the file is meant to be ephemeral and is normally absent. If a stale intervention.md is found in CI (i.e., committed by accident), the project's gitignore convention is to ignore `.harness/intervention.md`; verify_all logs a WARN if a tracked one exists.
