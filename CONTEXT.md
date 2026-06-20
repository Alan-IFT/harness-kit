# Harness Kit

Harness Kit is a Claude Code plugin that ships a 7-agent AI-development pipeline plus
project templates. This glossary pins the project's own domain terms so the pipeline
names files, symbols, and stage docs consistently. (Single context; if the repo ever
splits into multiple bounded contexts, a root `CONTEXT-MAP.md` would index them — not
needed today.)

## Language

**Frontier**:
The set of pool tasks that are runnable right now because every task they depend on is
already done. The stream and batch modes drain the frontier, not the whole pool.
_Avoid_: ready set, runnable queue, next-up list

**Pool** (living pool):
The mutable list of tasks a stream drains, which the operator keeps adding to mid-run; a
stream re-reads it each iteration so late additions get picked up.
_Avoid_: backlog, queue, task list

**Ambient mode**:
A session-scoped stream variant where a flag file turns each user message into a
scheduler heartbeat via a prompt hook — no slash-loop, no background process.
_Avoid_: daemon mode, watch mode, background mode

**Partition agent**:
A project-local Developer agent scoped to one slice of a codebase (`dev-frontend`,
`dev-backend`, `dev-db`, …), dispatched when a design splits work across partitions.
_Avoid_: sub-developer, worker agent, dev worker

**Stage doc**:
One of the numbered per-task documents the pipeline produces in order
(`01_REQUIREMENT_ANALYSIS.md` … `07_DELIVERY.md`); each stage reads the prior docs and
writes exactly its own.
_Avoid_: phase report, work product, deliverable doc

**Verdict**:
The single binding status line a stage agent ends on (e.g. `READY`, `APPROVED FOR
DEVELOPMENT`, `BLOCKED`) that tells the PM how to route the task next.
_Avoid_: status, result, outcome, decision

**Insight**:
An evidence-backed, hard-won project truth recorded as one line in the insight index, so
a later task does not re-learn it; each carries its supporting evidence reference.
_Avoid_: lesson, learning, note, takeaway

**Rollback**:
Reverting a task's changes back to the pre-task state when a stage cannot proceed —
relied on for additive work because nothing stateful is created.
_Avoid_: undo, revert-all, back-out, unwind

**Dogfood**:
This repo running its own shipped pipeline and assets on itself, so the dogfood copy of a
file carries this project's real content while the template seed of the same file stays
generic.
_Avoid_: self-host, eat-our-own, internal copy

**Template overlay**:
A layer of files (`common/`, then a project-type layer, then a language layer) that
`/harness-init` stacks to compose a generated project; later layers win.
_Avoid_: scaffold, skeleton, preset, boilerplate

**Soft dependency**:
A resource an agent uses if present and degrades gracefully without — referenced in vague
prose, never a precondition, never given a setup pointer.
_Avoid_: optional dependency, weak dependency, nice-to-have

**Hard dependency**:
A resource an agent genuinely requires to function — the only kind that earns an explicit
setup pointer telling the reader to provision it first.
_Avoid_: required dependency, strong dependency, must-have

**Gate**:
A pass/fail checkpoint between stages — either the human-judgment Gate Review stage or the
mechanical `verify_all` run — that a task must clear before it advances.
_Avoid_: check, guard, barrier, checkpoint

> Multi-context note: this repo is a single bounded context, so one root `CONTEXT.md` is
> enough. If it ever grows several bounded contexts, a root `CONTEXT-MAP.md` indexing each
> context's own `CONTEXT.md` is the future option (out of scope today).
