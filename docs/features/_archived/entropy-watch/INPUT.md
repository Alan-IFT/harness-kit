# Task Input — entropy-watch (T-11)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent). Builds on T-07 (deep-module vocabulary) and T-09 (rejected-decisions memory).

## Goal (one sentence)

Add an **anti-entropy watch**: the harness automatically + periodically scans the codebase for accumulated entropy (shallow modules / cross-seam leakage / coupling / deepening opportunities), and — without the human having to remember — **reminds** them at a natural boundary (stream pool drained; `/harness` task delivered) **pointing out exactly where the problems are**, then on the user's **authorization** runs the reduction to `verify_all` green. Logic: **machine reminds → user authorizes → machine executes.**

## Origin & rationale (the user's exact direction)

This is the operator's chosen fix for the one long-term quality-erosion vector that prior analysis judged genuinely worth a DESIGN optimization (codebase entropy / "ball of mud"). Verbatim intent: *"新增反熵巡检功能，并在 harness 和 harness-stream 中自动定期巡检，在排空需求池后，提醒用户需要做减熵并指出问题所在；不能依靠人力去记住这件事，而是机器提醒、用户授权、机器执行——用户体验好、劳动力也得到解放。"*

The harness already fights entropy PER TASK (Gate/CR/QA design-fidelity, CONTEXT.md naming, the T-07 deep-module design vocabulary). What is missing is a HOLISTIC, PERIODIC, AUTO-SURFACED sweep across the whole codebase + an authorize→execute loop — so accumulated complexity gets pushed back without relying on human memory.

Reference (read-only clone): `c:\Programs\_research\mattpocock-skills\skills\engineering\improve-codebase-architecture\SKILL.md` (the scan-for-deepening + visual report idea) + `codebase-design/SKILL.md` (deep-module vocabulary, already adopted in T-07) + `codebase-design/DEEPENING.md`.

## Scope guidance (for the analyst — scope honestly, REUSE, keep lightweight, DECOMPOSE if needed)

The feature has four parts; the analyst must scope each, REUSE existing surfaces, and **decompose into vertical slices (T-06 discipline) if it exceeds one smart-zone task** — recommending the thinnest end-to-end first slice (a working scan→remind→authorize→execute path) with richer parts as follow-up rows.

1. **The scan ("巡检")** — scan the codebase for entropy using the T-07 deep-module vocabulary: shallow modules (interface ≈ implementation), cross-seam leakage, coupling clusters, deepening candidates; the deletion test. Output must POINT OUT WHERE (specific files/modules) + a recommendation strength. **Strongly prefer extending the read-only `supervisor`** (it is already the project's observer) with a deep-module/entropy lens, rather than building a heavyweight new engine. Honestly assess supervisor-vs-goal-vs-new-engine.

2. **The auto-reminder ("机器提醒，自动+定期")** — surface the findings WITHOUT the human asking:
   - In **`/harness-stream`**: when the pool drains, append an `## Entropy watch` section to `STREAM_REPORT.md` (+ lead the exit message with it) — REUSE the T-022 `## Needs your input` end-of-drain surfacing pattern.
   - In **`/harness`** (single task): at stage-7 delivery, the same check surfaces a reminder in the delivery summary.
   - **CADENCE / throttle (critical):** do NOT scan on every drain (nag fatigue + token cost). Pin a sensible default trigger — e.g. "≥ N delivered tasks since the last sweep" and/or "first drain of a session" — backed by a tiny persistent cadence counter. Reset on sweep. The analyst MUST recommend a concrete default and where the counter lives (lightest fit: a field in `tasks.md` header, or a one-line `.harness/` state file — NOT a new verify_all guard).

3. **Authorize → execute ("用户授权，机器执行")** — the reminder lists findings; the user authorizes one (or all); the harness runs the deepening refactor to `verify_all` green by **reusing `/harness-goal`** (Dev+QA loop) or the normal pipeline. **NEVER auto-refactor without explicit authorization** (refactors carry behavior risk — this is the user's stated logic). 

4. **Findings persistence (so it doesn't nag about the same thing / doesn't re-litigate)** — unfixed findings should re-surface; fixed or user-declined ones should not. Reuse existing memory where possible: a declined refactor is a natural `.harness/rejected-decisions.md` (T-09) entry; open findings could live in a light findings log. Keep it minimal.

## Hard constraints (honor the operator's standing preferences)

- **Non-blocking, NOT a guard.** The reminder never gates/blocks delivery or drain — entropy reduction is opt-in/authorized. (feedback_design_over_guards: this is "go make the design better", not "add a check that complains/blocks".)
- **Lightweight / reuse over new heavy machinery** (feedback_lightweight): extend supervisor for the scan, reuse goal for execute, reuse the STREAM_REPORT surfacing for the reminder. A thin new user-facing skill entry is acceptable (the operator explicitly wants a "新增功能"), but its logic should lean on existing agents.
- **Cadenced**, never every-drain.
- A new skill ⇒ skill-count fan-out 16 → 17 (README ×2, CHANGELOG, AI-GUIDE Workflow table, getting-started, manual-e2e, 40-locations, dev-map, verify_all C.1/G.1/G.2 HARDCODED name arrays in BOTH shells — the T-03 ledger discipline) + version bump. Enumerate every surface (the T-03/T-08 count-decoy discipline; live count is 16).

## Insights to honor (verify before relying)

- verify_all C.1/G.1/G.2 are HARDCODED name arrays in both `.{ps1,sh}` — a 16→17 skill add needs the array element + label flip in both shells (insight 2026-06-19 / T-03).
- DO-NOT-TOUCH count decoys: frozen CHANGELOG history, `docs/tasks.md` delivery rows, `docs/proposals/*`, `.harness/insight-index.md` historical lines, harness-status "14 required assets" (insight 2026-06-19).
- supervisor is read-only (`tools: Read, Write, Glob, Grep` — confirm; it writes its own report only) — keep any scan extension within its tool boundary; the EXECUTE step is a separate authorized goal/pipeline run, not the observer.
- Memory/state additions must not overload insight-index (≤30) and should follow the CONTEXT.md/rejected-decisions dual-purpose template pattern if they ship into generated projects.
- I.6 retired-claim guard; doc-size caps (AI-GUIDE ≤200, rules ≤200, agents ≤300); cross-shell parity; PS denied to sub-agents (PM runs PS-side / operator-pending).
- Decompose per T-06 if > one smart-zone task; each slice independently verifiable.
