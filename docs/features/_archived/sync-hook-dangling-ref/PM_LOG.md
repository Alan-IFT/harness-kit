# PM_LOG — sync-hook-dangling-ref

- Task: sync-hook-dangling-ref — eliminate by design the consumer-project Stop-hook failure `bash: .harness/scripts/harness-sync.sh: No such file or directory` (root-cause the producing flow, make the state unreachable, ship a repair path).
- Mode: full (7 stages)
- Dispatched from: /harness-stream, pool docs/batches/default/, row T-01
- Board ID: T-020
- Started: 2026-06-11

## Pre-flight (per "How to start a task")

1. Task folder created: `docs/features/sync-hook-dangling-ref/`.
2. Intervention check #1 (before stage 1): `.harness/intervention.md` ABSENT — no pending intervention.
3. `.harness/insight-index.md` read in full. Entries flagged for downstream dispatch prompts (would have been attached to SA/Dev briefs):
   - 2026-06-09 · dual-purpose template files — grep other scripts/skills for reads before deleting/restructuring any template path (relevant if the fix conditionalizes `harness-sync.*` templates).
   - 2026-06-04 · every dogfood script derives repo root relative to its own location — relocating/conditionally-omitting scripts has runtime hazards invisible to path-string sweeps.
   - 2026-06-08 · `.claude/settings.json` schema breaks silently two ways; verify_all J.1 guards; consult upstream schema before editing settings templates.
   - 2026-06-08 (×2) · cross-shell `.ps1`/`.sh` byte-identity discipline if the fix touches `upgrade-project.{ps1,sh}` / `install-hooks.{ps1,sh}`.
   - 2026-06-10 · v0.30.0 agents cutover eliminated the agent copy/drift class by construction; mapping actual gate logic beat abstract cascade reasoning.
4. `docs/tasks.md` read. Related historical tasks:
   - T-007 scripts-relocation (v0.20.0): `scripts/` → `.harness/scripts/` move — candidate suspect flow (b) for the dangling reference.
   - T-011 ambient-stream (v0.22.0): hook wiring in `.claude/settings.json` (template ships wired).
   - T-012 harness-upgrade-skill (v0.23.0): `/harness-upgrade` relocate/rewire/hook-re-install — the designated repair surface in the dispatch prior.
   - T-019 agents-cutover (v0.30.0): candidate suspect flow (c) — post-cutover projects have no `.harness/agents/` to sync.
   - New Active entry added to `docs/tasks.md` as T-020, mode: full.
5. `docs/dev-map.md` not read — pipeline never reached dev/test stages (see hard stop below).

## HARD STOP — BLOCKED on missing dispatch capability (before stage 1)

- The PM runtime for this dispatch exposes only file tools (Read / Write / Edit / Glob / Grep). It has:
  - NO Task tool → cannot dispatch `harness-kit:requirement-analyst` or any of the 7 stage agents. The pipeline cannot start.
  - NO Bash / PowerShell tool → cannot run `.harness/scripts/verify_all` (delivery gate) or `.harness/scripts/archive-task` (step 10).
- Hard rules prohibit the PM from authoring requirements, design, code, or tests itself; stop conditions name "missing external capability" as a stop-and-ask case ("Do not improvise").
- Precedent: T-017 / T-018 logged stage-level "BLOCKED-on-capability (sub-agents no Bash) → operator-verified". This instance is broader: the dispatch mechanism itself is absent, so no stage ran.
- Stages traversed: none. Rollbacks: 0. No requirement/design/code artifacts were produced; no source files touched. Files written by PM: this log + the `docs/tasks.md` board entry only.
- The pre-dispatch recon facts in the task brief remain UNVERIFIED (verification was assigned to downstream stages that never ran).
- Intervention check #2 (at stop, before returning): `.harness/intervention.md` still ABSENT.

## Resume instructions

Re-issue this dispatch to a PM thread with sub-agent dispatch (Task tool) and a shell tool (Bash/PowerShell) enabled. On resume: stages 1-7 all pending — start at stage 1 (requirement-analyst). The required design adjudication (doctor-vs-extend, prior = extend `/harness-status` + `/harness-upgrade` + atomic generation) is untouched and must be settled by the Solution Architect in 02_SOLUTION_DESIGN.md.

## RESUMED — main thread assumes the PM shell (2026-06-11)

- Decision (Mode 2, logged): in this environment sub-agents are stripped of `Task` (no nested dispatch) and shell tools, so the PM **shell** runs in the main conversation thread; each of the 7 stages is still dispatched as its own `harness-kit:<role>` sub-agent in an isolated context (they need only file tools, which sub-agents do have). Shell steps (`verify_all`, `archive-task`, git) run in the main thread. This preserves the pipeline's substance — per-stage isolation and independent perspectives — and matches the T-017/T-018 precedent ("BLOCKED-on-capability → operator-verified"), one level up.
- Stage status: starting stage 1 (requirement-analyst).

## Stage progress (resumed run)

- Stage 1 requirement-analyst: READY-FOR-DESIGN. RC-1 (migrate-scripts-layout silent skip + unconditional rewire) = exact user symptom; RC-2 (init non-atomic wire), RC-3 (adopt has no {{SYNC_COMMAND}} spec), RC-4 (upgrade unchecked cp) confirmed; RC-5 (v0.30 dropped scripts) RULED OUT; RC-6 (type-template verify_all + harness-status still demand 7 agents in .harness/agents/ → fresh v0.30 project fails its own gate) found. 01 written by agent.
- Stage 2 solution-architect: READY. No /harness-doctor (OQ-1: extend status+upgrade+atomic generation); ambient pwsh hard-coding in scope (OQ-3); ~27 files; dogfood check count stays 32. 02 written by agent.
- Stage 3 gate-reviewer: GO-WITH-CONDITIONS (C1 ERE left-boundary + real matcher run; C2 exit-4 row co-occurrence semantics; C3 B7 literal-placeholder repair adjudication; C4 adopt merge-write J.1-class assertions). Reviewer had no Write tool — PM materialized 03 verbatim.
- Stage 3.5 SA amendment: C3 → option A (bounded literal-token rewrite in upgrade-project S3 first pass, REWIRE-PLACEHOLDER record, AC-9 + fixtures P/P2). 02 amended by agent (§6.2.5, §9.1).
- Intervention check (before stage 4): `.harness/intervention.md` ABSENT.
- Stage 4 developer: DONE (37 files; verify_all 32/0/0 both shells; all driver suites 0 FAIL, observed runs pasted in 04). C1-C4 satisfied; 4 design drifts declared in 04.
- Stage 5 code-reviewer: REWORK — 1 blocking MAJOR (migrate-scripts-layout apply-mode scan validated in-memory text, not disk → failed settings write = silent dangle, FR-P1 breach); 3 MINOR + 4 NIT non-blocking; C1-C4 all MET; all 4 drifts adjudicated legitimate; 04 tallies reconciled. Reviewer had no Write — PM materialized 05.
- Rollback #1 (stage 5 → stage 4, same-stage count: 1): focused rework dispatched.
- Stage 4 rework round 1: agent hit a stream-idle API error after the code landed but BEFORE writing the 04 rework section and observing verification. PM inspected the tree: MAJOR fixed in both shells + both copies (sh scan_text="$(cat ...)" apply-mode; ps1 Get-Content -Raw); optional MINOR 2/3 + NIT 1 taken; M3 read-only-settings probe added (graceful SKIP when not enforceable). PM runs the verification itself (observed-run discipline) and appends the 04 rework section with PM-attributed tallies.
