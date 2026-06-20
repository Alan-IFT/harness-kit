---
name: harness-deflate
description: Holistic anti-entropy sweep. Scans the WHOLE codebase (not one task) for
  accumulated structural rot — shallow modules, cross-seam leakage, coupling clusters,
  deepening candidates (the deep-module vocabulary) — via the read-only supervisor entropy
  lens, presents each finding with WHERE + a Strong/Worth-exploring/Speculative strength
  badge, and on your explicit authorization hands the chosen deepening to /harness-goal to
  refactor it to verify_all green. Machine reminds, you authorize, machine executes — it
  NEVER refactors without authorization. Use when "clean up the codebase entropy", "what's
  rotting / where's the ball of mud", "do an anti-entropy sweep", "减熵巡检", "做一次反熵巡检",
  "整体看看哪里在腐化". NOT /harness-supervise (per-task pipeline-anti-pattern audit, not
  whole-codebase structure), NOT /harness-goal directly (that's the execute engine this skill
  drives — use this when you want the sweep+findings first), NOT /harness (a defined feature,
  not an open-ended deepening).
allowed-tools: Read, Glob, Grep, Task
---

# /harness-deflate

A **holistic anti-entropy sweep**: scan the WHOLE codebase for accumulated structural rot,
present each finding with WHERE and a strength badge, and — only on your explicit pick —
hand the chosen deepening to `/harness-goal` to refactor it to `verify_all` green. The
loop is **machine reminds → you authorize → machine executes**; it NEVER refactors without
an explicit authorization.

This skill is thin orchestration: it owns NO scan engine and NO refactor loop. The scan is
the read-only `supervisor` entropy lens; the execute is `/harness-goal`. `allowed-tools`
deliberately excludes `Edit`/`Bash`/`PowerShell` — this skill cannot itself edit a file or
run a script; it only dispatches via `Task`.

## When to invoke

- "Clean up the codebase entropy" / "what's rotting?" / "where's the ball of mud?" /
  "do an anti-entropy sweep" — you want a holistic structural read, not a per-task audit.
- 中文："减熵巡检" / "做一次反熵巡检" / "整体看看哪里在腐化".
- You saw a `## Entropy watch` section surface at a `/harness-stream` drain and want to act
  on a finding — invoke this to authorize the deepening.

## When NOT to invoke

| Symptom | Use this instead |
|---|---|
| Audit ONE task folder for pipeline anti-patterns (rollback rate, thin docs, missing archive) | `/harness-supervise` |
| You already know the exact deepening and just want it executed to green | `/harness-goal` directly |
| A defined feature / bug / refactor (a specified change, not an open-ended deepening) | `/harness` |
| Vet a design before code | `/harness-plan` |

## Procedure

1. **Scan (dispatch the supervisor entropy lens).** Dispatch `harness-kit:supervisor` via the
   `Task` tool **in entropy mode**. The dispatch prompt MUST name: "entropy lens / EP-* /
   follow `skills/harness-deflate/references/entropy-scan.md` exactly / write
   `docs/features/_supervision/entropy-<ISO-date>.md`". That reference file is the SINGLE
   source of the scan methodology + artifact schema (the supervisor stub and this prompt both
   point at it — never restate it). The supervisor is observer-only (no Edit/Bash/Task) and
   writes exactly one artifact.
2. **Present.** Read the findings artifact. Present the findings table to the user: `ID`,
   `Class` (EP-1..EP-4), `Where` (file/module), `Strength` (`Strong` / `Worth exploring` /
   `Speculative`), and the one-line deletion-test verdict.
3. **Clean short-circuit.** If the artifact's last line is `Entropy-verdict: CLEAN` → report
   "no entropy findings" and **stop**. No execute step.
4. **Authorize gate (three-way pick).** Ask the user which finding(s) to **deflate**, to
   **decline**, or "**none**". **NEVER proceed without an explicit pick** — absent any pick, every
   finding stays open and zero edits occur.
   - **deflate `EP-NNN`** → go to step 5 (the `/harness-goal` execute).
   - **none** → every finding stays open, zero edits, stop.
   - **decline `EP-NNN`** (memory-write only — NO refactor, NO `/harness-goal` dispatch, NO
     production-file edit) → record the decline so it stops re-surfacing on future sweeps:
     1. Resolve `EP-NNN` to its row in the just-presented artifact. **If the id is not among the
        current findings** → report "EP-NNN is not among the current findings" and take NO write
        (no guessing which module was meant). Stop.
     2. The decline's concept handle = the finding's **stable key** = its `Where (file/module)`,
        normalized per the `## Decline filter` rule in `references/entropy-scan.md` (same key the
        scan filter uses — defined ONCE there; do not restate it here).
     3. **Record-shape CONTRACT** — a T-09-format record is appended to
        `.harness/rejected-decisions.md` (created from the standard seed if absent). This skill has
        NO `Edit`/`Write` tool; the append is the **main agent's** decide-point decision-recording
        habit per `.harness/rules/25-decision-policy.md` (this skill does not edit the file itself).
        The record shape:

            ## <stable-key>
            - **Decision:** declined.
            - **Why:** <user's stated reason, or "not worth the deepening" if none given>.
            - **Origin:** entropy sweep <ISO-date> · EP-<class>.

        where `<class>` is the finding's class word (`shallow module` / `cross-seam leakage` /
        `coupling cluster` / `deepening candidate`) — date + class, NOT the unstable per-run EP-NNN.
     4. **De-dup (T-09 contract):** if a record for `<stable-key>` already exists, append this
        origin to that record's `- **Origin:**` line (a re-occurrence) rather than creating a second
        record. One record per concept.
5. **Execute (only on authorization).** Dispatch `/harness-goal` via the `Task` tool with
   goal = "land the EP-<id> deepening: <Where> — <one-line solution>" and success criterion =
   "`.harness/scripts/verify_all` is green AND the deepening described in EP-<id> is in place".
   `/harness-goal` runs the Dev + QA loop to green. Repeat per authorized finding.
6. **Report.** Summarize: which findings were presented, which the user authorized, and the
   outcome of each `/harness-goal` run (final `verify_all` result + what landed).

## Relationship to the cadenced stream surface

`/harness-stream` runs this exact scan automatically at a **due** cadence boundary (the shared
`.harness/scripts/entropy-cadence` pair decides "due") and surfaces a `## Entropy watch`
section in `STREAM_REPORT.md` — informational, non-blocking, no execute. `/harness-deflate` is
the **manual** entry point and the authorize→execute front end: the manual sweep is always
"due" (no cadence check), and it is the only path that reaches the execute step. Both share
ONE scan definition (`references/entropy-scan.md`) and ONE supervisor lens.

## Hard rules

- **Never refactor without an explicit user pick.** The scan agent physically cannot refactor
  (observer-only); this skill cannot edit (no `Edit`/`Bash` in `allowed-tools`); the execute is
  a SEPARATE `/harness-goal` dispatch gated on the step-4 authorization. No code path reaches an
  edit without authorization.
- **Compose, don't reconstruct.** The scan methodology + artifact schema live ONLY in
  `references/entropy-scan.md`; the execute loop lives ONLY in `/harness-goal`. Never inline a
  copy of either.
- **Observer boundary holds.** The scan widens the supervisor's READ scope (it may read
  production source in entropy mode) but adds no write/exec capability — it still writes exactly
  one artifact, never dispatches, never edits an upstream doc.

## Anti-patterns

- **Do not** use for a single task's pipeline-health audit — that's `/harness-supervise`.
- **Do not** auto-execute a finding the user did not explicitly authorize.
- **Do not** restate the EP classification grammar or the artifact schema here — point at
  `references/entropy-scan.md`.
