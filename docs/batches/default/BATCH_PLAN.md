# Batch Plan — default

> Created: 2026-06-11
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | sync-hook-dangling-ref | Eliminate by design the consumer-project failure where the Stop hook fires `bash: .harness/scripts/harness-sync.sh: No such file or directory` on every turn — root-cause which flow (init / adopt / upgrade / plugin-version skew) can produce a project whose wired hook references a missing script, make that state unreachable, and ship a repair path for already-broken projects. | full | — | done |

## Notes (optional)

- T-01 user context (verbatim symptom from a real consumer project on the latest plugin version):
  `Stop hook error: Failed with non-blocking status code: bash: .harness/scripts/harness-sync.sh: No such file or directory`.
  The user reports this class of error fires "经常" (frequently — consistent with a Stop hook running every turn).
- T-01 design adjudication required: the user asked whether a dedicated `/harness-doctor` (check + repair) command is needed. Orchestrator's prior: prefer extending the existing surfaces — `/harness-status` (diagnose) and `/harness-upgrade` (repair) — plus making generation atomic (never wire a hook whose target script was not written), per the project's design-over-guards principle. The Solution Architect must adjudicate doctor-vs-extend with evidence and record the decision; a new command is acceptable only if the existing two surfaces genuinely cannot host the behavior.
- Known facts from pre-dispatch recon (verify before relying): templates still ship `harness-sync.{ps1,sh}` under `skills/harness-init/templates/common/.harness/scripts/`; `settings.json.tmpl` wires Stop → `{{SYNC_COMMAND}}` (OS-picked at init); the failing project got the bash variant. Candidate suspects: `/harness-adopt` wiring hooks without copying scripts, pre-relocation projects (scripts at `scripts/`) with a rewired-but-uncopied path after `/harness-upgrade`, or v0.30 cutover dropping a copy step.

## Column reference

- **ID** — batch-local identifier (`T-NN`). Does NOT collide with repo-wide `docs/tasks.md` IDs.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`. Must be unique within the batch.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same batch, or `—` for none.
- **Status** — `pending` (initial) | `in-progress` | `done` | `failed` | `blocked` | `skipped`. The skill writes; the user reads.
