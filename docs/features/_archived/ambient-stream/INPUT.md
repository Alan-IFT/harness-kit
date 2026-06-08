# PM Dispatch Input — ambient-stream (mode: full)

## Task (one line)
Add a minimal "ambient chat-driven stream" mode to harness-kit so a user starts the stream ONCE with no pool-id, then keeps typing requirements in chat; the AI folds each message into a default pool and drains ready tasks through the pipeline until the pool is empty — no /loop, no pool-id, no re-invocation.

## Converged design (authoritative starting point — validate + detail, do not re-derive)
1. No pool-id → default pool `docs/batches/default/BATCH_PLAN.md`, auto-created from `docs/batches/_template/BATCH_PLAN.md` if absent.
2. Ambient mode is a gated flag (marker file; SA decides exact path; gitignored if transient). Flag gates the hook so normal chat is NOT treated as tasks unless ambient ON. Clear EXIT keyword/command removes the flag.
3. A UserPromptSubmit hook is the heartbeat. When flag set, hook injects context instructing the agent to: (a) if message reads as a requirement, normalize into a `pending` row (de-dupe); (b) drain ready tasks topologically until pool empty; (c) stop and wait. When flag absent, hook is a no-op. Hook only reminds/instructs — Claude is the worker.
4. Serial only. No parallel dispatch.
5. Resume is free — the pool file is the persistent state.
6. Prefer ENHANCING the existing harness-stream skill (no-arg default-pool + ambient enter/exit) over a new skill (avoids C.1/G.1/G.2 + count-claim + README/CHANGELOG/AI-GUIDE/manual-e2e-test/dev-map fan-out). SA makes the final call.

## Scope
- IN: default-pool logic, ambient enter/exit + flag, UserPromptSubmit hook script (PS+Bash twins) + template settings wiring, docs, verify_all green.
- OUT: /loop integration, idle/unattended progress, parallel execution, any new verify_all lettered check that would force a version bump.

## Relevant insights surfaced
- L17 pwsh hooks need `-NoProfile`.
- L30 settings.json schema breaks two ways — consult upstream first; J.1 gates it.
- L11 new `{{...}}` placeholder → both verify_all D.2 whitelists.
- L33 count/version claim change is version-worthy (G.4) — minimal version aims NOT to change counts.
