# Task Board — Harness Kit

> Maintained by PM Orchestrator. One row per task: outcome, rollback count, and a pointer.
>
> **Rows are pointers, not summaries.** The full record of a task lives in its doc folder
> (`07_DELIVERY.md` for the outcome, `PM_LOG.md` for the rollback ledger). A row that
> restates them is a copy nothing gates against its original — the `stage-doc-summary-header`
> decline applies here too. Keep each Outcome cell to one clause.

## Active tasks

| ID | Slug | Stage | Mode | Started | Doc folder |
|---|---|---|---|---|---|
| _(none)_ | | | | | |

## Completed tasks

| ID | Slug | Outcome | Completed | Doc folder |
|---|---|---|---|---|
| T-24 | operator-obligation-home | Delivered v0.46.0 — release-gating operator obligations get one home | 2026-08-02 | `docs/features/operator-obligation-home/` |
| T-23 | review-write-path | Delivered v0.46.0 (1 rollback) — the two review roles no longer name an output they cannot produce | 2026-08-02 | `docs/features/_archived/review-write-path/` |
| T-22 | stage-model-tiering | **Delivered as a decline** (2 rollbacks) — model-swap declined, reasoning-effort deferred | 2026-08-02 | `docs/features/_archived/stage-model-tiering/` |
| T-20 | harvest-wrapped-insight | Delivered v0.46.0 (3 rollbacks + 1 doc-correction return) — a wrapped `## Insight` bullet no longer loses continuation lines | 2026-08-01 | `docs/features/_archived/harvest-wrapped-insight/` |
| T-18 | stage-contract-split | Delivered v0.46.0 (3 rollbacks + 1 escalation) — every stage output is a typed contract plus an optional `0N_RATIONALE.md` | 2026-08-01 | `docs/features/_archived/stage-contract-split/` |
| T-17 | guard-cmd-chain | Delivered v0.46.0 (4 rollbacks) — closed a reproduced destructive-command bypass; the nine-verb rule now runs at every command position | 2026-08-01 | `docs/features/_archived/guard-cmd-chain/` |
| T-16 | hook-truth-derivation | Delivered v0.46.0 (2 rollbacks) — all four derivation flows obtain hook byte-forms from `hook-spec` | 2026-08-01 | `docs/features/_archived/hook-truth-derivation/` |
| T-15 | hook-truth-verify-scope | Delivered v0.46.0 (1 rollback + 4 doc-only rounds) — the gate stopped asserting a fact about the maintainer's machine | 2026-08-01 | `docs/features/_archived/hook-truth-verify-scope/` |
| T-14 | hook-truth-status | Delivered v0.45.0 (3 rollbacks) — `/harness-status` no longer misreports the destructive-command guard | 2026-07-31 | `docs/features/_archived/hook-truth-status/` |
| T-13 | hook-truth-spec | Delivered v0.45.0 (4 rollbacks) — new `hook-spec.{ps1,sh}`, single source of truth for lifecycle-hook wiring | 2026-07-31 | `docs/features/_archived/hook-truth-spec/` |
| T-12 | resilient-hooks | Delivered v0.44.0 (0 rollbacks) — per-turn `Stop hook error` on a fresh clone eliminated by design | 2026-06-21 | `docs/features/_archived/resilient-hooks/` |
| T-11c | entropy-watch-persist | Delivered v0.43.0 (0 rollbacks) — anti-entropy watch slice 3/3, findings persistence via a DECLINE filter | 2026-06-20 | `docs/features/_archived/entropy-watch-persist/` |
| T-11b | entropy-watch-harness | Delivered v0.42.0 (0 rollbacks) — anti-entropy watch slice 2/3, wired into the `/harness` stage-7 boundary | 2026-06-20 | `docs/features/_archived/entropy-watch-harness/` |
| T-11a | entropy-watch | Delivered v0.41.0 (1 design rollback) — anti-entropy watch core slice; new 17th skill `/harness-deflate` | 2026-06-20 | `docs/features/_archived/entropy-watch/` |
| T-10 | planning-decision-map | **Declined** (no build, 0 rollbacks) — 1:1 concept mapping onto existing surfaces | 2026-06-20 | `docs/features/_archived/planning-decision-map/` |
| T-09 | rejected-decisions-memory | Delivered v0.40.0 (0 rollbacks) — 4th memory-layer file `.harness/rejected-decisions.md` | 2026-06-20 | `docs/features/_archived/rejected-decisions-memory/` |
| T-08 | two-axis-review | Delivered v0.39.0 (0 rollbacks) — two-axis review principle folded into code-reviewer | 2026-06-20 | `docs/features/_archived/two-axis-review/` |
| T-07 | sa-design-vocab | Delivered v0.38.0 (0 rollbacks) — solution-architect gains a design-vocabulary lens | 2026-06-20 | `docs/features/_archived/sa-design-vocab/` |
| T-06 | vertical-slices | Delivered v0.37.0 (0 rollbacks) — tracer-bullet vertical-slice + smart-zone decomposition discipline | 2026-06-20 | `docs/features/_archived/vertical-slices/` |
| T-05 | durable-brief | Delivered v0.36.0 (0 rollbacks) — agent-brief durability discipline folded into requirement-analyst | 2026-06-20 | `docs/features/_archived/durable-brief/` |
| T-04 | skill-authoring-vocab | Delivered (0 rollbacks; no version bump) — enriched `.harness/rules/15-skill-authoring.md` | 2026-06-19 | `docs/features/_archived/skill-authoring-vocab/` |
| T-03 | harness-grill | Delivered v0.35.0 (0 rollbacks) — new 16th skill `/harness-grill`, a main-loop interview front-end | 2026-06-19 | `docs/features/_archived/harness-grill/` |
| T-02 | context-glossary | Delivered v0.34.0 (0 rollbacks) — new `CONTEXT.md` domain-glossary memory layer | 2026-06-19 | `docs/features/_archived/context-glossary/` |
| T-022 | stream-defer-human | Delivered v0.33.0 (0 rollbacks) — `/harness-stream` defers needs-human tasks instead of halting | 2026-06-13 | `docs/features/_archived/stream-defer-human/` |
| T-021 | stream-auto-decompose | Delivered v0.32.0 (0 rollbacks) — `/harness-stream` auto-decomposes a complex requirement at ingest | 2026-06-12 | `docs/features/_archived/stream-auto-decompose/` |
| T-003 | supervisor-agent | Delivered v0.17.0 (3 rollbacks) | 2026-05-19 | `docs/features/_archived/supervisor-agent/` |
| T-002 | ai-native-init | Delivered v0.16.0 (2 rollbacks) | 2026-05-19 | `docs/features/_archived/ai-native-init/` |
| T-001 | ai-safety-guardrails | Delivered v0.15.0 (1 rollback) | 2026-05-17 | `docs/features/_archived/ai-safety-guardrails/` |
| T-000 | initial-bootstrap | Delivered | 2026-05-15 | _(bootstrap, no docs/features/ folder)_ |
