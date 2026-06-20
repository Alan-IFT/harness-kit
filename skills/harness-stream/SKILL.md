---
name: harness-stream
description: Streaming / living-pool mode. Drains a continuously-growable task pool (docs/batches/<pool-id>/BATCH_PLAN.md, or the no-arg default pool docs/batches/default/) one task at a time through pm-orchestrator, re-reading the pool every iteration so tasks you add mid-run are planned and executed without re-invoking. Best-effort completion (a failed task is marked and skipped, the stream keeps going) with the same hard-safety stops as batch. Includes an ambient mode: enter by invoking with no pool-id, then every chat message is a heartbeat that folds requirements into the default pool and drains it — gated by .harness/ambient.flag via a UserPromptSubmit hook (session-scoped: a SessionStart hook auto-clears it each new session, no "off" keyword), no /loop needed. Complex multi-part requirements are triaged at ingest and auto-decomposed into N dependency-staged rows (a simple requirement stays one row; ADD lines and hand-written rows are honored as-written). A task that needs human input (clarification, a human-reserved decision, or authorization for a safety-critical action) is **deferred** — set aside, its dependents blocked, the stream keeps draining — and surfaced together at stream end; it does not halt the stream. Use when you want to fire requirements at the AI as they occur to you — in chat or by appending to the pool — and only watch results.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, TodoWrite, Task
---

# /harness-stream

Drain a **living task pool** through the full 7-stage pipeline, one task at a time, re-reading the pool every iteration. Unlike `/harness-batch` (which freezes the plan at start and stops on the first hard failure), the stream **picks up tasks you add while it runs** and keeps going past a single task's failure. This is the **"I only propose requirements and watch results"** mode.

## When to invoke

- You're developing and keep discovering new work — "also add X", "while you're at it fix Y" — and you don't want to wait for the current run to finish before queuing it.
- You want a standing drain loop: keep a pool of tasks topped up, let the AI plan order and execute, you just append and observe.
- You've been using `/harness-batch` and want the same pool to stay *open* instead of freezing at start.

The hallmark: the task list is **open-ended and grows during execution**, and you prefer "keep completing everything, tell me what broke, but don't halt the whole run over one failure".

## When NOT to invoke

| Symptom | Use this instead |
|---|---|
| A fixed, known list of tasks; stop on first failure | `/harness-batch` |
| Exactly one task | `/harness` (full 7-stage) |
| Iterate ONE goal until a measurable criterion | `/harness-goal` |
| "Vet a design before code" | `/harness-plan` |
| "Can we even do X?" / research | `/harness-explore` |
| Pause / redirect a running stream | `/harness-intervene` (or append to the pool) |

## The pool

The pool reuses the batch plan format so a batch can graduate into a stream and vice-versa:

- File: `docs/batches/<pool-id>/BATCH_PLAN.md`.
- Columns: `ID | Slug | Goal | Mode | Depends on | Status` (same validation as `/harness-batch`).
- If invoked **with a pool-id** and that file doesn't exist, point the user at `docs/batches/_template/BATCH_PLAN.md`, ask them to copy it to `docs/batches/<pool-id>/BATCH_PLAN.md`, seed at least one `pending` row, then re-invoke. (A typo'd pool-id therefore errors loudly rather than silently creating a new pool.)
- If invoked **with no pool-id**, the pool resolves to the **default pool** `docs/batches/default/BATCH_PLAN.md`, and — unlike the named-pool case — it is **auto-created** when absent by copying `docs/batches/_template/BATCH_PLAN.md`, replacing `<batch-id>` with `default`, and **stripping the example `T-01..T-03` rows** so the table starts empty. The no-arg default pool is the foundation of ambient mode (below).

The pool is **append-only-friendly**: you may add rows at any time, including while the stream is running. The stream re-reads the file every iteration, so new `pending` rows are planned into the topological frontier on the next pass.

## Two ways to add work mid-run (and the timing truth)

A running stream consumes input from two channels. Understand the timing — it's the whole point of this mode:

1. **File channel (instant).** Append a `pending` row to `BATCH_PLAN.md`, or drop an `ADD <slug> — <goal>` line in `.harness/intervention.md` (via `/harness-intervene` or by hand). The loop re-reads both at the **top of every iteration**, so a file write lands on the **next task boundary** regardless of what the AI is doing. This works even in a single continuous run.

2. **Chat channel (next tick).** Type the requirement in the chat box. While the AI is mid-task its turn is busy, so your message **queues and is delivered when the current turn ends** — i.e. it is ingested at the next iteration, not mid-task. To make this prompt, run the stream under the `/loop` driver (below) so each iteration is its own short turn. The stream **mirrors any chat-supplied requirement into the pool file** before acting on it, so nothing is lost.

If you want truly instant insertion without waiting for a task to finish, use the file channel. If you want to "just type and forget", use the chat channel under `/loop`.

## Drivers — pick one

- **Hands-off chat driver (recommended for "fire in chat").** Run `/loop /harness-stream <pool-id>` (self-paced). Each tick is its OWN turn that processes one task, so a chat message typed during a task is delivered when that tick ends and ingested on the next tick. **This is the only driver that delivers the headline "type a requirement in chat, AI folds it in, I just watch" experience**, because only a fresh turn can carry your queued chat. It also makes the "keep the pool topped up and idle until I add more" behavior real — each tick is a genuine new turn.
- **Continuous run (no dependencies, file-channel only).** Invoke `/harness-stream <pool-id>` once; the skill loops internally in a single turn, re-reading the pool file each iteration. The **file channel works perfectly here** (each iteration re-reads `BATCH_PLAN.md` + `intervention.md`), but **chat does NOT** — a message typed mid-run is queued by Claude Code until the whole invocation ends, so it cannot be ingested between internal iterations. Use this when you'll add work by appending to the pool / sending `ADD` interventions, not by chatting. Because a single turn cannot block-wait, this driver **drains the current pool and exits** rather than idling for future additions (re-invoke to drain more).

**Always state the chosen driver to the user at start, and the timing truth above.** In particular: if `/loop` is unavailable, warn explicitly that the pure chat-driven experience is not available — they must add work via the file / `ADD` channel, and chat typed mid-run won't be picked up until the run ends.

## Ambient mode (no-arg default pool + chat heartbeat)

Ambient mode is the **minimal "start once, then just keep typing" experience**: you enter ambient mode once, then every ordinary chat message becomes a turn in which the AI folds any requirement into the **default pool** and drains it — **no `/loop`, no pool-id, no re-invocation**. It works because each user message is itself a turn, and a `UserPromptSubmit` hook turns that turn into the scheduler's heartbeat.

### How it works

- **The flag.** Ambient mode is gated by a single transient flag file `.harness/ambient.flag` (gitignored, like `.harness/intervention.md`). **Presence = ambient ON; absence = ambient OFF.** It is **session-scoped**: a `SessionStart` hook (`.harness/scripts/ambient-reset.{ps1,sh}`) deletes the flag at the start of every new session, so ambient never silently carries over and there is no "off" keyword to remember.
- **The heartbeat hook.** A `UserPromptSubmit` hook (`.harness/scripts/ambient-prompt.{ps1,sh}`, wired in `.claude/settings.json`) runs on every user turn. When `.harness/ambient.flag` is present it prints an instruction block that Claude Code injects into the turn as added context — telling the agent to ingest+drain (below). When the flag is absent the hook prints **nothing** (no-op), so normal chat is unaffected. The hook never does the work itself and never blocks a turn (it always exits 0); Claude is the worker.
- **Serial only.** One task at a time — same as the rest of this skill. No parallel dispatch.
- **Resume is free.** The default pool file is the persistent state; a partially-drained pool resumes on the next message via the existing resume semantics (skip rows whose `07_DELIVERY.md` is DELIVERED).

### Enter / exit

- **Enter:** just invoke **`/harness-stream` with no pool-id** — that single action *is* "ambient on" (no keyword to remember). On enter the skill: (1) writes `.harness/ambient.flag`; (2) ensures `docs/batches/default/BATCH_PLAN.md` exists (auto-create from `_template`, empty table); (3) tells you: "Ambient mode on for this session. Type requirements; I'll fold each into the default pool and drain it."
- **Exit:** **automatic** — ambient mode is **session-scoped**. A `SessionStart` hook (`.harness/scripts/ambient-reset.{ps1,sh}`) clears `.harness/ambient.flag` at the start of every new session, so a fresh session is never silently in ambient mode; re-invoke `/harness-stream` to resume. To stop mid-session, delete `.harness/ambient.flag` (or just tell the AI to stop). There is no "off" keyword to remember.

### Each ambient turn (what the agent does when the flag is set)

1. **Ingest.** If your message reads as a requirement (not a question or aside), normalize it into `docs/batches/default/BATCH_PLAN.md` per "Ingest triage" below — one `pending` row, or N decomposed rows when the triage test fires (`Mode` per row, default `full`), de-duplicating against existing slugs/goals first. If a message is ambiguous (you cannot file it as exactly one well-formed task), do NOT guess and do NOT block: record a needs-human clarification entry ("clarify before I can file this as a task: <the ambiguous message verbatim>") to the deferred-human queue and keep draining. A plain question/aside creates **no** row.
2. **Drain.** Drain ready tasks in topological order via `pm-orchestrator`, one at a time, best-effort, honoring the existing hard-safety stops, until the pool is empty — identical to the Procedure loop below.
3. **Stop and wait** for your next message.

### Ambient vs the `/loop` chat driver

Ambient mode is **not** `/loop`. `/loop` makes the AI act while you're **silent** (idle/unattended progress); ambient mode acts **only on your messages** — your own typing is the heartbeat. Ambient mode is explicitly the minimal version: no idle progress, no background process. If you want progress while you're away, that is a separate (out-of-scope-here) `/loop` concern.

## Ingest triage (one row or many)

Applies wherever the STREAM normalizes natural language into pool rows: chat-channel ingest (Procedure 3a) and ambient turns. It NEVER applies to rows the user authored — an `ADD <slug> — <goal>` line or a hand-written pool row is honored verbatim as ONE task, at the user's chosen granularity, and an existing row is never re-triaged.

**Triage test — decompose only when BOTH hold:**
1. The message contains two or more outcomes that are each *independently verifiable deliverables* — each could pass its own QA and reach DELIVERED on its own (signals: an "and"-chain or enumeration of distinct outcomes; outcomes touching distinct subsystems or artifact classes; phased phrasing — "X, then Y" / "先…再…").
2. No single one-sentence Goal can state the requirement without conjoining those outcomes.

**NOT complex (always one row):** a single deliverable with wide fan-out (one change echoed across many files); long prose describing one outcome; a list of acceptance details for one outcome.

**When the test fires, write N ≥ 2 `pending` rows (same columns, no schema change):**
- **Slug:** derive a base slug from the requirement; every sub-row slug starts with `<base>-` (e.g. `csv-export-endpoint`, `csv-export-button`). Add one provenance line to the pool's `## Notes` section: `Decomposed <base>-* (N rows) ← "<original requirement, one line>" (YYYY-MM-DD)`.
- **Goal:** one sentence, exactly ONE independently verifiable deliverable per row. **Union invariant:** the union of the sub-row Goals must equal the original message — no invented scope, no dropped scope. If any requested outcome cannot be placed in exactly one row, that is ambiguity: ask, don't guess.
- **Depends on:** chain only REAL consumption (row B uses an artifact or behavior row A produces). Independent siblings stay unchained (`—`) so a failed sibling never blocks them.
- **Mode:** per row via the normal workflow-entry mapping (default `full`; a pure research sub-step may be `explore`).
- **Fixed point:** every produced row must FAIL test 1 on its own (exactly one deliverable), so re-running triage on any produced row returns it unchanged.
- De-duplicate each sub-row against existing slugs/goals, as for any new row.
- **Announce** in the ack which IDs/slugs were created from the requirement and the dependency shape; correct a wrong split via the pool, `SKIP`, or `/harness-intervene`.

A requirement that fails the test gets exactly today's one-row path — no marker, no announcement. Once written, derived rows are ordinary pool rows: resume, de-dup, `SKIP`, edits, and failure semantics apply identically.

Each row the triage writes (and each hand-authored row) should be a tracer-bullet vertical slice sized to the smart zone — see `harness-plan` → "Task-decomposition discipline" for what makes a good row.

## Procedure

1. **Argument validation.** With a pool-id: confirm `docs/batches/<pool-id>/BATCH_PLAN.md` exists; if not, surface the template path and stop. **With no pool-id:** resolve to `docs/batches/default/BATCH_PLAN.md` and **auto-create it** (from `_template`, empty table) if absent — this is the ambient-mode default pool.

2. **Pre-flight (once per stream start; cheap and idempotent so it's safe under `/loop`):**
   - `.harness/scripts/verify_all` baseline — capture PASS/WARN/FAIL. If already FAIL, **refuse to start** (a broken baseline makes per-task regression detection impossible). Surface and exit.
   - `.harness/insight-index.md` — read once; surface relevant lines into each task's pm-orchestrator dispatch prompt.
   - `.harness/intervention.md` — consume any pending signal per `.harness/rules/65-intervention.md` (a `STOP` here aborts before any task).

3. **Iteration loop** (one task per pass; repeat until the exit condition fires):
   - **a. Ingest.** **File channel (always):** re-read `BATCH_PLAN.md` and check `.harness/intervention.md` (below). **Chat channel (only under the `/loop` driver):** the user message(s) delivered with *this tick's turn* may contain new requirements — for each that clearly reads as a task (not a question or aside), **normalize it into `pending` row(s) per "Ingest triage" above** — one row, or N decomposed rows when the triage test fires (assign `ID`/`Slug`/`Goal`/`Mode`/`Depends on` per row), de-duplicating against existing slugs/goals first; if a message is ambiguous, do NOT guess and do NOT issue a blocking prompt: record a needs-human clarification entry (`stage=ingest`, verbatim message, "clarify before I can file this as a task") to the deferred-human queue and continue draining. Under the continuous driver there is no mid-run chat to read — skip the chat part. Then act on `.harness/intervention.md`:
     - `ADD <slug> — <goal>` → append/upsert a `pending` row, delete the intervention file, continue (user-authored: honored verbatim as ONE row, never triaged).
     - `STOP` → halt the stream (strong signal). `NOTE` → attach to the next dispatch. `SKIP <id>` → mark that row `skipped`. (`REDIRECT <id>` → reject; it targets stages, not tasks.)
   - **b. Plan.** Validate the table (required columns, unique slugs, no `Depends on` cycle). Build the topological frontier of runnable rows honoring `Depends on`. **Resume semantics (same as batch):** a row whose `docs/features/<slug>/07_DELIVERY.md` parses as `DELIVERED` (primary) OR contains a line matching `Final verify_all result: PASS` (secondary, format-tolerant fallback) is treated as done — mark `done`, skip. Every other status — `pending` / `in-progress` / `failed` / `blocked` / `needs-human` — is **re-evaluated and runnable** (so a `failed` row from a prior run is retried once its cause is fixed; a `blocked` row becomes runnable once its blocker resolves; a `needs-human` row re-runs once you supply the input recorded in the report's "Needs your input" section).
   - **c. Pick.** Take the next ready task in topological order. If none is ready (frontier empty but `pending` rows remain blocked by failures) → go to exit check.
   - **d. Dispatch.** Mark the row `in-progress`. Append to `docs/batches/<pool-id>/STREAM_LOG.md`: `<ISO-8601 UTC> · <id> · dispatching pm-orchestrator · slug=<slug> · mode=<mode>`. **Dispatch `harness-kit:pm-orchestrator` via the `Task` tool** (mode `full` unless the row says otherwise), in its OWN context, **and include in the dispatch prompt the line `deferred-human mode: defer, do not ask` so the sub-agent knows interactive asks are unavailable and returns a `BLOCKED: NEEDS-HUMAN — …` verdict instead** (see `agents/pm-orchestrator.md`). The stream never sees the stage docs, only the return summary. This is identical to `/harness-batch` step 4c; never bypass pm-orchestrator.
   - **e. Record.** Read the sub-agent's return summary (verdict `DELIVERED` / `BLOCKED` / `BLOCKED: NEEDS-HUMAN — …` / `FAILED`, path to `07_DELIVERY.md`, files-changed, final `verify_all`). Append one line to `STREAM_LOG.md`.
   - **f. Regression gate.** Run `.harness/scripts/verify_all`. If it returns **FAIL** (the task broke the baseline) → **hard stop** (see Stop conditions). Otherwise continue.
   - **g. Best-effort outcome.** Update the row `Status` from the verdict (keep the verdicts distinct so the report tallies stay honest):
     - `DELIVERED` → `done`. **Then bump the entropy cadence:** call `.harness/scripts/entropy-cadence delivered` (increments the delivered-since-sweep counter; fail-open, never blocks). Only a `DELIVERED` task counts toward the sweep cadence.
     - `BLOCKED: NEEDS-HUMAN — <verbatim ask> — <what unblocks it>` (the pm-orchestrator's self-identifying needs-human verdict — see `agents/pm-orchestrator.md` "When to stop and ask the user") → set this row `needs-human`; append a `NEEDS-HUMAN` line to `STREAM_LOG.md` and record the queue entry (id, slug, raising stage, verbatim ask, unblock) for the report's "Needs your input" section; mark **only** this row's own `Depends on` descendants `blocked`; **then keep going** to the next ready task. NEVER perform the action the task requested (e.g. a deploy/production-write authorization request defers — it is not executed) and NEVER halt the stream.
     - `FAILED` → `failed`; any other `BLOCKED` (a dependency-driven or generic block, NOT prefixed `NEEDS-HUMAN`) → `blocked`. In either case also mark every *downstream* task whose `Depends on` chain includes this row `blocked`, **then keep going**. (A task failure is best-effort, never a stream-level stop.)
   - **h. Report.** Emit a one-line status to the user: `<id> <verdict> · queue: <pending> pending / <failed> failed / <blocked> blocked / <needs-human> needs-human`.
   - **i. Continue or rest.** If ready tasks remain → next pass immediately. If the frontier is drained: under the **`/loop` driver**, end the tick and let the next tick re-check the pool + any queued chat — repeat for up to **K consecutive empty ticks** (default 3) of genuinely no new work, then exit. Under the **continuous driver** there is no blocking wait inside one turn, so a drained pool means **exit now** (write the report); the user re-invokes `/harness-stream <pool-id>` to drain anything added later.

4. **Exit conditions:**
   - Pool drained AND no new requirements for K consecutive passes → normal exit.
   - A hard stop fired (below).
   On exit, write `docs/batches/<pool-id>/STREAM_REPORT.md`.

## Stop conditions (hard — these DO halt the stream)

Best-effort means a *task* failure (including a pm-orchestrator `FAILED` verdict, even from its own "3 same-stage rollbacks" rule) **never** stops the stream — it's marked `failed`, its dependents `blocked`, and the stream moves on. Only these three genuine hazards halt the stream, because continuing would corrupt the run or defy the user:

- `.harness/scripts/verify_all` returns **FAIL** after a task — the change broke the baseline; every later task would inherit a poisoned baseline. Stop, surface, let the user fix.
- `.harness/intervention.md` contains **STOP** between passes.
- The safety hook (`.harness/scripts/guard-rm`) blocked a destructive Bash call inside a task — surfaced in the sub-agent's return summary.

A class-(c) needs-human deferral is NOT a hard stop — only these three hazards halt. The bright line: a *request for* a safety-critical action **defers** (the action is not performed); a `guard-rm` *block of a destructive command already attempted* **halts**.

(With no hard stop and no ready task left, the stream exits normally per the drained-pool rule — it does not "halt", it just finishes.)

## On stream completion

Write `docs/batches/<pool-id>/STREAM_REPORT.md`, **leading with a `## Needs your input` section** (FIRST, before the per-task table) enumerating every deferred item — each `needs-human` row AND each ingest-ambiguity clarification — using the deferred-human queue entry format (id, slug, raising stage, verbatim ask, unblock). **If there are no deferred items, the section reads `None.`** Then:

- Per-task row: `<id> | <slug> | <verdict> | link to its task folder` — `docs/features/_archived/<slug>/` once the task is DELIVERED and archived, else the live `docs/features/<slug>/` (a `needs-human` / `failed` / `blocked` row is not archived yet, so it links to the live path).
- Aggregate: done / failed / blocked / **needs-human** / skipped counts, passes run, final `verify_all` summary.
- The failed / blocked / needs-human rows remain resume-resolvable: supply the input (pool edit / `ADD` / `/harness-intervene` / chat), re-invoke `/harness-stream <pool-id>`, and the stream re-runs only the unfinished rows via the existing resume semantics (a row whose `07_DELIVERY.md` is not DELIVERED is re-evaluated and runnable — see Resume semantics, step b).
- Stop reason if a hard stop fired.

Then, **after** composing the `## Needs your input` section (it stays FIRST — T-022 invariant), run the **entropy watch** (below) so a due holistic sweep surfaces on the same boundary.

On exit, the message to the user **leads** with the needs-input digest — the count of deferred items and each ask verbatim — BEFORE the done/failed/blocked tally. A run that completed with deferrals is not "all done": surface "N item(s) need your input" first. If the queue is empty, lead with the normal tally. **If a due entropy sweep ran (below), append its one-line digest AFTER the needs-input digest and BEFORE the tally** — the two are distinct, fixed-order sections.

### Entropy watch (cadenced, non-blocking)

A holistic anti-entropy sweep is surfaced here on a **due** cadence boundary only — never every drain. It is **non-blocking**: it never changes the drain's exit verdict, and any cadence I/O problem fails open to not-due. The cadence due-logic + threshold live in ONE place, the shared `.harness/scripts/entropy-cadence` pair (see also `/harness-deflate`, which runs the same scan manually).

1. **Check cadence.** Call `.harness/scripts/entropy-cadence check --first-of-session` (pass `--first-of-session` because this is the stream's drain boundary — the flag makes a long-idle pool with ≥1 delivery due even before the counter reaches the threshold). Read the one-line stdout: `DUE` or `NOT-DUE`.
   - **`NOT-DUE`** (or any error / missing output — fail-open) → write `STREAM_REPORT.md` as usual; **no scan, no `## Entropy watch` section, no entropy digest**. Done.
   - **`DUE`** → continue.
2. **Run the scan once.** Dispatch `harness-kit:supervisor` via the `Task` tool **in entropy mode** — the dispatch prompt must name: "entropy lens / EP-* / follow `skills/harness-deflate/references/entropy-scan.md` exactly / write `docs/features/_supervision/entropy-<ISO-date>.md`". The supervisor is observer-only (no Edit/Bash/Task); it writes exactly one artifact. Run the scan **once** per `DUE` verdict (no double-surfacing even if both due-triggers fired).
3. **Read the verdict line.** From the artifact's last non-blank line `Entropy-verdict: FINDINGS-PRESENT | CLEAN`.
4. **Append the section.** Append a `## Entropy watch` section to `STREAM_REPORT.md` **after** `## Needs your input` (distinct section, fixed order): the findings table (or `None.` when `CLEAN`), a link to the entropy artifact, and a note that deepening a finding is opt-in via `/harness-deflate` (authorize → `/harness-goal`). The stream itself **never** runs a refactor.
5. **Reset the cadence.** Call `.harness/scripts/entropy-cadence swept` (resets the counter to 0 and stamps last-sweep, so the same boundary does not re-trigger). Fail-open.
6. **Lead the exit digest.** Add the entropy one-line digest to the exit message per the ordering rule above (after needs-input, before the tally).

A baseline-FAIL hard stop, a `STOP`, or a guard-rm block still take precedence and are unchanged — the entropy watch runs only on a normal drained-pool exit and never converts an informational sweep into a stop.

### Deferred-human queue

A class-(c) deferral is dual-written: a running `STREAM_LOG.md` line when the arm fires (so a mid-run kill loses nothing — the report is re-derivable from the log on re-invocation), and the report's `## Needs your input` section at exit. No third file.

**STREAM_LOG.md line** (appended at step g):

```
<ISO-8601 UTC> · <id> · NEEDS-HUMAN · slug=<slug> · stage=<raising stage/agent> · ask="<verbatim question or missing info>" · unblock="<what input resolves it>"
```

**STREAM_REPORT.md `## Needs your input` entry** (one block per deferred item; ingest-ambiguity entries use `id = —` and `stage = ingest`):

```
- <id> `<slug>` — raised by <stage/agent>
  - Ask: <verbatim question or missing info>
  - Unblocks when: <what input resolves it (pool edit / ADD / /harness-intervene / chat)>
```

Per-task stage docs are archived by each task's own pm-orchestrator. The pool artifacts (`BATCH_PLAN.md`, `STREAM_LOG.md`, `STREAM_REPORT.md`) stay in `docs/batches/<pool-id>/`.

## Hard rules

- **Never bypass pm-orchestrator.** The stream is a thin loop; all per-task routing happens inside pm-orchestrator. Do not directly dispatch RA/SA/Dev/etc.
- **Never run more than one task in parallel.** Sequential only — same as batch.
- **Re-read the pool every iteration.** The whole feature is that mid-run additions are honored; a cached plan defeats it.
- **A task failure is best-effort, a baseline failure is a hard stop.** Never suppress a `verify_all` FAIL to keep the stream running — that's the signal that protects every later task.
- **A needs-human deferral is best-effort like a failure.** Set the row `needs-human`, block only its `Depends on` descendants, surface at end — never halt and never perform the deferred action.
- **Mirror chat requirements into the pool before acting** so the pool is the single source of truth and the run is resumable.
- **Never widen scope beyond what the user asked.** Every row traces to a user requirement (chat / pool / `ADD`). The stream may *derive* rows only by partitioning ONE user requirement at ingest (see Ingest triage), and the union of the derived Goals must equal the original requirement — no invented scope, no dropped scope. Work the user did not ask for is never added; rows the user authored (`ADD` lines, hand-written pool rows) are never split or rewritten.
- **Ambient mode is gated by `.harness/ambient.flag` and serial only.** Never treat chat as tasks unless the flag is present; never run ambient tasks in parallel. The `UserPromptSubmit` hook only injects an instruction — it never does the work and never blocks a turn.

## Anti-patterns

- **Do not** use for a fixed list you want to fail-fast on — that's `/harness-batch`.
- **Do not** auto-retry a `failed` task in the same run. Mark it, skip its dependents, continue; the user fixes the cause and re-invokes to resume.
- **Do not** keep the stream spinning forever on an empty pool — exit after K empty passes so it doesn't burn turns idling.
- **Do not** promise "instant" chat ingestion mid-task — be honest that chat lands at the next iteration; the file channel is the instant one.
- **Do not** decompose a single deliverable just because it fans out across many files, nor an `ADD` line or hand-written pool row — triage applies only where the stream normalizes natural language, and only when the triage test fires.

## Cost

Roughly (tasks completed) × (full 7-stage cost), plus one `verify_all` per task and ~2 log lines/task. The stream adds no per-task overhead over `/harness-batch`; its value is eliminating the stop-update-re-invoke cycle every time you think of new work. Idle passes (empty pool) cost one pool re-read each — negligible — and stop after K. A decomposed requirement costs N × (full 7-stage) — the same as if you had filed the N rows by hand; triage itself adds no overhead.
