# INPUT — sync-hook-dangling-ref (T-020)

## User report (verbatim, 2026-06-11, via /harness-stream ambient)

> 我现在在开发项目里开发，使用当前项目的最新版，但经常报错，这是其中一个报错：Ran 1 stop hook (ctrl+o to expand)
> ⎿  Stop hook error: Failed with non-blocking status code: bash: .harness/scripts/harness-sync.sh: No such file or directory

Follow-up question (same session):

> 所以是否还需要有个doctor命令来检查和修复？
> (= "So do we also need a doctor command to check and repair?")

## Normalized goal (pool row T-01, docs/batches/default/BATCH_PLAN.md)

Eliminate by design the consumer-project failure where the Stop hook fires
`bash: .harness/scripts/harness-sync.sh: No such file or directory` on every turn —
root-cause which flow (init / adopt / upgrade / plugin-version skew) can produce a
project whose wired hook references a missing script, make that state unreachable,
and ship a repair path for already-broken projects.

## Context

- The user develops in a CONSUMER project (not this repo) running the latest harness-kit plugin; the Stop hook fires every turn, so one dangling reference = an error storm ("经常报错").
- The failing project's hook uses the **bash** variant of the sync command.
- Required design adjudication: dedicated `/harness-doctor` vs extending `/harness-status` (diagnose) + `/harness-upgrade` (repair) + atomic generation (never wire a hook whose target script wasn't written in the same flow). Orchestrator prior: extend existing surfaces, per design-over-guards. A new command only if evidence shows the existing surfaces can't host the behavior.

## Candidate suspect flows (UNVERIFIED — stage 1/2 must verify)

(a) `/harness-adopt` wiring hooks without copying scripts;
(b) pre-relocation project (scripts at `scripts/`) rewired to `.harness/scripts/` without the script landing (`/harness-upgrade` path);
(c) v0.30.0 agents-cutover dropping/conditionalizing a copy step, or making the Stop-sync hook pointless for single-developer projects (nothing left to sync but `.harness/skills/`);
(d) plugin-version skew: plugin cache updates while the project's `.harness/` stays old.
