# Task Board — Harness Kit

> Maintained by PM Orchestrator. Each task lifecycle stage is logged here.

## Active tasks

| ID | Slug | Stage | Mode | Started | Doc folder |
|---|---|---|---|---|---|
| _(none)_ | | | | | |

## Completed tasks

| ID | Slug | Outcome | Completed | Doc folder |
|---|---|---|---|---|
| T-000 | initial-bootstrap | Delivered | 2026-05-15 | _(bootstrap, no docs/features/ folder)_ |
| T-001 | ai-safety-guardrails | Delivered v0.15.0 (1 rollback) | 2026-05-17 | `docs/features/_archived/ai-safety-guardrails/` |
| T-002 | ai-native-init | Delivered v0.16.0 (2 rollbacks: M-1/M-2/M-3 from CR; BUG-2 from QA via PM override) | 2026-05-19 | `docs/features/_archived/ai-native-init/` |
| T-003 | supervisor-agent | Delivered v0.17.0 (3 rollbacks: F-1 from Gate; BUG-1 from QA via PM override; +1 within-stage round) | 2026-05-19 | `docs/features/_archived/supervisor-agent/` |
| T-004 | i6-semantic-guard | Delivered v0.18.0 (4 rollbacks: F-1/F-2 from Gate; F-4 from Gate re-review; entry-#10 from Dev; CR-MAJOR 40-locations:25 from Code Review) + in-flight archive-task.sh L13-pattern bug fix | 2026-05-23 | `docs/features/_archived/i6-semantic-guard/` |
| T-005 | i6-test-hardening | Delivered v0.18.1 (1 rollback: M-1 from Gate Review on §9 baseline; PM-applied §9+§11 patch under user-delegated authority); 12/12 QA mutations detected; PASS:56 both shells | 2026-05-23 | `docs/features/_archived/i6-test-hardening/` |
| T-006 | harness-batch-skill | Delivered v0.19.0 (1 rollback: M-1 AI-GUIDE.md skill-count drift + m-1 manual-e2e-test drift + m-2 stop-signal clarity, all from Code Review); 10/10 QA adversarial tests survived; PS verify_all 31/31 PASS stable x3 | 2026-05-23 | `docs/features/_archived/harness-batch-skill/` |
| T-007 | scripts-relocation | Delivered v0.20.0 (1 rollback: B-1 test-init contradictory asserts + M-1 test-supervisor.sh stale ref + m-1 baseline-move coverage, from Code Review; reproduce-before-fix exposed a stale 250/212 tally + 2 reviewer-missed defects); 6/6 ACs verified both shells, 12 QA adversarial probes survived, 0 defects; verify_all 31/31 PASS both shells. Scripts moved `scripts/` → `.harness/scripts/` + `migrate-scripts-layout` helper | 2026-06-04 | `docs/features/_archived/scripts-relocation/` |

## Notes

- T-000 is the initial repo creation; it predates the pipeline, so no per-stage docs exist.
- Subsequent tasks must follow the 7-stage pipeline.

