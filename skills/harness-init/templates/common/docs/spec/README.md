# Project SPECs

This folder is the source of truth for **project-level requirements**. Each major feature should have
its own SPEC document before the pipeline picks it up.

## File naming

- `README.md` — this file, an index.
- `<feature>.md` — one SPEC per feature, e.g. `csv-export.md`, `auth-v2.md`.

## What a SPEC contains

- **Goal**: one paragraph, business reason.
- **Scope**: what's in, what's out.
- **Constraints**: technical, regulatory, time.
- **Acceptance criteria**: testable conditions.
- **Risks / open questions** for human resolution.

## How SPECs flow into the pipeline

1. You write a rough SPEC (or paste a chat) here.
2. You hand it to Requirement Analyst: _"Refine `docs/spec/csv-export.md` into a task requirement."_
3. Analyst writes `docs/features/<task>/01_REQUIREMENT_ANALYSIS.md` referencing this SPEC.
4. PM Orchestrator drives the rest.

## Style

Use absolute language: "must", "will". Avoid "should", "might", "maybe".
If unsure, write an open question; the Requirement Analyst will resolve it with the user.
