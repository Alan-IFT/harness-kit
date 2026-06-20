# Task Input — entropy-watch-persist (T-11c)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** T-11a (cadence + supervisor lens + stream surface) and T-11b (/harness surface) — both DELIVERED.

## Goal (one sentence)

Add a lightweight **findings-persistence** layer so the anti-entropy watch doesn't nag: an OPEN finding re-surfaces on the next sweep, a FIXED one drops, and a user-DECLINED one goes to `.harness/rejected-decisions.md` (T-09) and is never re-litigated.

## Origin & rationale

T-11a/T-11b made the watch fire (machine reminds → authorize → execute), but each sweep currently re-derives findings from scratch — so an already-fixed module won't reappear (good) but a user who looked at a finding and said "not worth it" would see it again every sweep (bad UX, the operator's "用户体验好" goal). This slice gives findings memory: open / fixed / declined, so the reminder stays signal, not noise.

## Scope guidance (for the analyst — REUSE, keep lightweight, decline-if-overkill)

In scope: a minimal persistence mechanism so the entropy watch's findings have state across sweeps:
- **OPEN** findings re-surface next sweep.
- **FIXED** findings (the deepening shipped / the module is no longer shallow) drop silently.
- **DECLINED** findings (user said "not worth it") are recorded in `.harness/rejected-decisions.md` (REUSE T-09 — a declined deepening is exactly a rejected decision) and excluded from future sweeps (matched by a stable finding key, e.g. module/concept, like the rejected-decisions de-dup).
The analyst/architect determine the LIGHTEST mechanism: likely a small findings log (e.g. `.harness/entropy-findings.md` or a section the supervisor scan reads+writes) keyed by a stable finding identity, + the supervisor scan filtering out keys present in rejected-decisions, + a `/harness-deflate` path to mark a finding declined (→ append to rejected-decisions). Honestly assess whether rejected-decisions alone (for declines) + the scan's natural "re-derive, fixed ones don't reappear" already covers most of it — if FIXED and OPEN need no new store (the scan re-derives them every time) and only DECLINE needs wiring (filter against rejected-decisions), scope DOWN to just that (the lightest correct design).

Out of scope (unless analyst argues): a heavy findings database; auto-classifying fixed-vs-open by diffing the codebase (the scan already re-derives, so "fixed" = "no longer surfaced"); changing the cadence/scan/surface from T-11a/b; any new verify_all check.

## Insights to honor (verify before relying)

- **Lean hard on T-09 rejected-decisions** for the DECLINE case (a declined deepening = a rejected decision; the file already de-dups by concept and is read at decide-points). The supervisor scan should SKIP any finding whose key matches a rejected-decisions entry — that alone delivers "declined ones don't re-litigate".
- **FIXED needs no store if the scan re-derives** every sweep (a fixed module simply stops being shallow → stops surfacing). Confirm this against the T-11a scan design (`references/entropy-scan.md`) — if true, only DECLINE needs new wiring and OPEN/FIXED are free. Scope to the minimum.
- Reuse, don't re-implement: cadence (entropy-cadence), scan (supervisor lens + references/entropy-scan.md), surfacing (T-11a/b). This slice only adds the decline-filter + (if needed) a tiny open-findings note.
- If a new file ships into generated projects, follow the CONTEXT.md/rejected-decisions dual-purpose pattern (generic seed, not byte-synced) + test-init seed assertion + baseline reconcile. If it's repo-only runtime state, gitignore it (like entropy-watch.state).
- Distributed edit → version bump (0.42.0 → likely 0.43.0); no count flip; no new verify_all check. I.6 clean; PS-deny.
