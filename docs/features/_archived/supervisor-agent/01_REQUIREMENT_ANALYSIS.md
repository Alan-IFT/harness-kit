# 01 — Requirement Analysis · supervisor-agent (T-003 · v0.17.0)

Mode: **full** (canonical 7-stage). Target version v0.17.0.

## Goal

Add an **observer-only** agent + skill that reads an in-flight or completed 7-stage pipeline's task folder, detects a fixed catalog of anti-patterns, and writes a single `SUPERVISION_REPORT.md` for human/PM review — **without modifying any production code, stage doc, PM decision, or routing the pipeline.**

## User stories

1. **Mid-pipeline health check** — User running a long `/harness` task pauses between stages, runs `/harness-supervise <slug>`, and gets a report flagging (e.g.) "Stage 4 doc is 18 lines and missing a partition-assignment section; rollback risk." User chooses to write an `intervention.md` STOP or let pipeline continue.
2. **Post-pipeline retrospective** — After `archive-task`, user runs `/harness-supervise <slug>` (resolves against `docs/features/_archived/<slug>/`) to surface "what would supervisor have warned us about?" — feeds the next task's planning.
3. **Cross-task trend report** — User runs `/harness-supervise --recent N` (or `--all`); supervisor reads the last N archived tasks, identifies recurring anti-patterns (e.g. "3 of last 4 tasks had ≥2 rollbacks at Code Review"), proposes evolution-principle candidates without committing them.
4. **PM-invoked auto-check** — PM Orchestrator, after consuming an intervention or at user-configurable stage boundaries, MAY dispatch the supervisor for a single task and embed the report path in the next dispatch prompt — purely informational, never auto-acts on findings.

## In-scope behaviors

1. New agent definition at `.harness/agents/supervisor.md` AND byte-identical mirror at `templates/common/.harness/agents/supervisor.md` (sync-self covers it).
2. New skill at `skills/harness-supervise/SKILL.md` (skill name: `harness-supervise`). Skill takes one of three argument shapes: `<task-slug>` (single task), `--recent <N>` (last N archived), `--all` (every archived task).
3. Supervisor reads ONLY: target task folder (`docs/features/<slug>/` or `docs/features/_archived/<slug>/`), `.harness/insight-index.md`, `docs/tasks.md`, `.harness/rules/65-intervention.md`, `.harness/rules/70-doc-size.md`. No other repo file reads (no production code, no other tasks unless cross-task mode).
4. Supervisor writes EXACTLY one file: `docs/features/<slug>/SUPERVISION_REPORT.md` for single-task mode, or `docs/features/_supervision/cross-task-<ISO-date>.md` for cross-task mode. No other file writes/edits.
5. Detects at minimum these 4 anti-patterns; each finding has severity `INFO` / `WARN` / `ALERT`:
   - **AP-1 rollback-rate**: `WARN` at ≥2 rollbacks same stage in one task; `ALERT` at 3 (PM-hard-stop threshold per workflow.md:44).
   - **AP-2 stage-doc-thinness**: per-stage minimum-content checklist (e.g. RA must have all 9 sections per analyst contract; QA must have `## Adversarial tests`); `WARN` if any required section missing or under N lines (N defined per stage in agent contract).
   - **AP-3 missing-intervention-checks**: PM_LOG.md must contain an "Intervention check" entry between each pair of completed stages per rule 65-intervention.md read-points; `WARN` for each missing boundary.
   - **AP-4 missing-archive-call**: for tasks marked Completed in `docs/tasks.md`, stage docs must live under `_archived/<slug>/`; `ALERT` if they remain at `docs/features/<slug>/` (per rule 70-doc-size.md rule 4).
6. Cross-task mode: aggregates AP-1..AP-4 over N tasks; surfaces patterns at `ALERT` when ≥3 of last N tasks share the same anti-pattern.
7. Severity scheme is fixed and documented in the agent contract: `INFO` (observation, no action implied) · `WARN` (review recommended) · `ALERT` (project-level rot likely).
8. Report includes a final **Verdict** line: `HEALTHY` (zero WARN/ALERT), `WATCH` (≥1 WARN, 0 ALERT), `INTERVENE` (≥1 ALERT). The verdict is read by humans only — no agent consumes it programmatically in v0.17.0.
9. `verify_all` gains exactly one new check (rationale captured in NFR-3 + open question Q-4): a passive guard that flags a `SUPERVISION_REPORT.md` whose `Verdict: INTERVENE` has been ignored (i.e., file present + task still active + ≥48h old). Severity WARN, not FAIL.
10. Skill is invoked manually only — supervisor is NOT inserted as a new pipeline stage and is NOT auto-dispatched by PM in v0.17.0 (per backwards compatibility constraint).

## Out-of-scope (explicit non-goals for v0.17.0)

- Supervisor MUST NOT edit any stage doc (`0[1-7]_*.md`), `PM_LOG.md`, production code, agent contracts, rule fragments, or `docs/tasks.md`.
- Supervisor MUST NOT call any agent, dispatch any sub-task, or write `.harness/intervention.md` (rule 65 forbids agents from writing it).
- Supervisor MUST NOT auto-rollback, auto-advance, or modify PM routing.
- No real-time / streaming observation. Supervisor runs on demand; reads the task folder as it exists at invocation time.
- No new PM contract clauses, no changes to the 7-stage pipeline shape, no agent-count change in `harness-status` asset list (supervisor is an 8th agent file but not part of the canonical 7).
- No machine-learning or trend extrapolation. Anti-pattern thresholds are static, declared in `supervisor.md`.
- No alert delivery mechanism (no email, no webhook). File-on-disk only.

## Boundary conditions

- **Missing task folder**: supervisor exits with `BLOCKED — task folder not found: <path>`. Writes no report.
- **Empty task folder** (folder exists, no docs): writes a report with `Verdict: HEALTHY` and a single INFO finding "pipeline has not started".
- **Task folder mid-pipeline** (some stage docs absent): supervisor evaluates only present docs; absence of a doc is not itself an anti-pattern unless `docs/tasks.md` marks the stage as completed.
- **Archived path resolution**: if `<slug>` is not found at `docs/features/<slug>/`, fall back to `docs/features/_archived/<slug>/`. If neither exists → BLOCKED.
- **Concurrent runs**: two `/harness-supervise` invocations on the same slug — second overwrites first's report; documented behavior, not protected against (single-user assumption).
- **Cross-task mode N=0 or N>completed-task-count**: clamp to `[1, completed-task-count]`; INFO-log the clamp.
- **PM_LOG.md absent or malformed**: AP-3 emits `INFO — cannot verify intervention checks (PM_LOG.md absent/unparseable)`, does NOT emit WARN/ALERT. Avoids false positives on legacy tasks (T-000).
- **Doc-size cap honored**: `SUPERVISION_REPORT.md` ≤ 200 lines (matches rule fragment cap); cross-task report ≤ 300 lines (matches per-task stage doc cap from rule 70).

## Acceptance criteria

- **AC-1**: `c:\Programs\HarnessEngineering\.harness\agents\supervisor.md` exists, ≤ 300 lines (rule 70 agent cap), declares the 4 anti-patterns AP-1..AP-4 with explicit thresholds, and explicitly lists the read-only / write-one-file constraints.
- **AC-2**: `templates/common/.harness/agents/supervisor.md` is byte-identical to the dogfood copy (verifiable by `scripts/sync-self --check`).
- **AC-3**: `skills/harness-supervise/SKILL.md` exists with three documented argument shapes; `allowed-tools` is a subset of `{Read, Write, Glob, Grep, Task}` (NOT including Edit, Bash, PowerShell, AskUserQuestion).
- **AC-4**: Running supervisor on a fixture task folder containing 2 same-stage rollbacks produces a `SUPERVISION_REPORT.md` whose Verdict is `WATCH` and which lists AP-1 at WARN.
- **AC-5**: Running supervisor on a fixture with 3 rollbacks produces Verdict `INTERVENE` and AP-1 at ALERT.
- **AC-6**: Running supervisor on the archived `ai-native-init` (T-002) folder produces a deterministic report (snapshot test) flagging: AP-1 WARN (2 rollbacks at stages 5 and 6), zero AP-3 findings (PM logged intervention checks at every boundary), zero AP-4 (task is archived). Fixture committed.
- **AC-7**: Running supervisor without a real LLM call: the agent definition is testable via a mock-fixture pattern analogous to T-002's `HARNESS_AI_NATIVE_MOCK` — provide `HARNESS_SUPERVISOR_MOCK=1` env var that bypasses any sub-Task dispatch and emits the canned report from the fixture; covered by `scripts/test-init` or a new `scripts/test-supervisor` (architect decides). Required so CI does not need live LLM.
- **AC-8**: `verify_all` gains exactly one new check; total goes 29 → 30. Check passes on T-002 archived state.
- **AC-9**: `docs/tasks.md`, `AI-GUIDE.md`, `README.md` roadmap row, `CHANGELOG.md`, `docs/manual-e2e-test.md`, `docs/walkthrough.html`, `architecture.html`, `docs/dev-map.md` are all updated for v0.17.0 (insight-index L14 + L21 fan-out discipline).
- **AC-10**: Running `/harness` end-to-end on a sandbox task with the supervisor agent present produces identical stage doc outputs as without it (additive change verification).
- **AC-11**: `scripts/harness-status` includes supervisor.md in the agent-asset list (asset count goes 7 → 8 — but this is a status report change, not a contract change to "the 7-stage pipeline" wording elsewhere; see Q-5).

## Non-functional requirements

- **NFR-1 performance**: Single-task supervise completes in ≤ 30s wall-clock on a 7-stage task folder of typical size (≤ 5MB of docs). Cross-task `--recent 10` ≤ 60s.
- **NFR-2 token budget**: Supervisor MUST NOT read production source code, MUST NOT read other tasks' folders in single-task mode. Cross-task mode reads only `07_DELIVERY.md` + `PM_LOG.md` of each target task (not all 7 stage docs), to bound cost.
- **NFR-3 doc-size compliance**: All new docs and the report respect rule 70 caps (agent ≤ 300, rule fragment ≤ 200, report ≤ 200, cross-task report ≤ 300).
- **NFR-4 safety**: Supervisor's `allowed-tools` excludes `Edit`, `Bash`, `PowerShell`, `Task`, `AskUserQuestion` — so it physically cannot edit upstream docs, run scripts, dispatch agents, or prompt the user. Write only to its designated report path; verified by a `verify_all` check or test.
- **NFR-5 determinism**: Given the same task folder, the supervisor's findings list is deterministic (same anti-patterns, same severities). The narrative prose may vary; the structured findings table does not. Required for snapshot testing in AC-6.
- **NFR-6 false-positive budget**: On the 3 existing tasks (T-000/T-001/T-002), supervisor MUST emit zero ALERT findings (T-000's bootstrap legacy is handled by AP-3's "INFO not WARN" rule for missing PM_LOG).

## Backwards compatibility

- v0.16.0 → v0.17.0 is purely **additive**. No PM contract clause changes. The 7-stage pipeline runs unchanged whether supervisor exists or not. Users who do not invoke `/harness-supervise` see no behavior change.
- No rename of existing agents/skills. No change to `.harness/rules/*.md` cap numbers or trigger phrasing. No removal of any existing `verify_all` check.
- `harness-status` skill's "7 agents" copy stays — supervisor is an auxiliary agent (8th file) not part of the canonical 7-stage routing.
- Existing tasks (T-000/T-001/T-002) need no migration. Supervisor reads them as-is.

## Open questions — analyst-decided

Each carries a default decision with rationale; the Architect can override in stage 2.

- **Q-1 skill name**: `/harness-supervise` (verb form, matching `/harness-verify`, `/harness-intervene`). `[ANALYST-DECIDED: harness-supervise · rationale: verb-form symmetry with existing skills; clearer than the noun "supervisor"]`
- **Q-2 invocation mode**: manual only (user types `/harness-supervise <slug>`); not auto-invoked by PM in v0.17.0. `[ANALYST-DECIDED: manual-only · rationale: backwards-compat additive; auto-dispatch can land in v0.18 once anti-pattern thresholds are battle-tested and false-positive budget proven]`
- **Q-3 severity scheme**: 3 levels `INFO`/`WARN`/`ALERT`. `[ANALYST-DECIDED: INFO/WARN/ALERT · rationale: matches verify_all's PASS/WARN/FAIL feel without colliding with it; ALERT distinct from FAIL because nothing is broken — it's a rot signal]`
- **Q-4 verify_all integration**: 1 new check (passive guard for ignored INTERVENE reports). `[ANALYST-DECIDED: 1-check-WARN · rationale: any more would expand verify_all into supervisor-territory; the supervisor IS the deep check, verify_all just notices its report was ignored]`
- **Q-5 always-loaded vs on-demand**: supervisor agent is on-demand only (not in PM's always-loaded list, not in the 7-stage table). `[ANALYST-DECIDED: on-demand · rationale: zero context cost when unused; per-call token cost only when user invokes the skill]`
- **Q-6 cross-task storage**: cross-task reports go to a new folder `docs/features/_supervision/cross-task-<ISO-date>.md` (not inside `_archived/` to keep archive scope = per-task). `[ANALYST-DECIDED: _supervision/-folder · rationale: separate concern, separate folder; archive-task does not touch it; can be gitignored or kept per project preference]`
- **Q-7 anti-pattern catalog evolution**: thresholds + the 4 anti-patterns are declared in `supervisor.md` (not in a separate rule fragment), so adding AP-5 in v0.18+ is an agent-contract edit not a rule edit. `[ANALYST-DECIDED: agent-contract-declared · rationale: same-locality-as-logic; rule fragments are for cross-cutting policy, not per-agent thresholds]`

## Risks

- **R-1 false-positive alerts**: Supervisor flags WARN/ALERT for a task that humans would judge fine (e.g. legitimate 2-rollback at QA when the user explicitly requested a tighter check). **Mitigation**: NFR-6 sets a zero-ALERT floor on the existing 3 tasks; AC-6 snapshot on T-002 protects against regression; severity-tuning is allowed in v0.17.x patches without bumping major-feature semver.
- **R-2 token cost runaway in cross-task mode**: `--all` on a project with 100 archived tasks blows the context window. **Mitigation**: NFR-2 caps cross-task reads to `07_DELIVERY.md` + `PM_LOG.md` only; documented `--recent N` is the recommended path.
- **R-3 stale anti-pattern definitions**: thresholds defined today (≥2 rollbacks = WARN) may become outdated as the project's baseline shifts. **Mitigation**: Q-7 keeps thresholds in `supervisor.md` (single-file edit); v0.18+ may add a `--threshold-config` flag if drift is observed.
- **R-4 supervisor becomes a routing actor**: scope creep where "supervisor flags this so PM should auto-rollback" sneaks in. **Mitigation**: out-of-scope list is explicit; NFR-4 enforces via `allowed-tools` exclusion of `Task`/`Edit`.
- **R-5 report-ignored anti-pattern**: user runs supervisor, gets ALERT, ignores it, project rot continues. **Mitigation**: FR-9 (the one verify_all check) makes ignored INTERVENE reports visible at the daily verify gate.
- **R-6 sync drift**: `templates/common/.harness/agents/supervisor.md` falls out of sync with dogfood copy. **Mitigation**: AC-2 verifies byte-identity via existing `sync-self --check`.

## Related historical tasks

- `T-001 / ai-safety-guardrails` (v0.15.0) — precedent for new-rule-fragment + verify_all check; insight L7/L8 (PS case-insensitivity) apply if supervisor does any string matching of stage doc content.
- `T-002 / ai-native-init` (v0.16.0) — direct precedent: roadmap-driven, version bump, mock-fixture pattern (`HARNESS_AI_NATIVE_MOCK`), insight L11/L12 (CHANGELOG fan-out, separate temp dirs for bidirectional tests) apply.
- See `docs/features/_archived/ai-native-init/PM_LOG.md` for the 2-rollback pattern this supervisor would have flagged at WARN at stage 5 round-1.

## Insight-index entries to honor

- 2026-05-19 · CHANGELOG.md must be in the explicit fan-out of any version/count sweep (T-002 round-1 M-1). → applies to AC-9.
- 2026-05-19 · PowerShell `-notin` is case-INSENSITIVE; use `-cnotin` (T-002 BUG-2). → applies if supervisor's PS pre-flight does string matching.
- 2026-05-19 · Bidirectional test cases must use separate temp dirs. → applies if AC-7 mock fixture has on/off cases.
- 2026-05-16 · Releases shipped feature code but left README badges / skill list at pre-release values. → applies to AC-9.
- 2026-05-16 · One-sided assertions hide bidirectional drift. → applies: any "supervisor detects X" assertion needs an inverse "supervisor does NOT flag Y" assertion.

## Verdict

**READY** — all open questions resolved under analyst authority per the user's "your call on decisions" directive. Architect may override any `[ANALYST-DECIDED]` line in stage 2.
