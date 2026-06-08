# 01 — Requirement Analysis: ambient-stream

> Stage 1 · requirement-analyst · mode: full · 2026-06-08

## 1. Goal

Let a user run the living-pool stream **once with no pool-id**, then keep typing requirements in normal chat; while an explicit "ambient" flag is set, each user message becomes a turn in which the AI folds new requirements into a single default pool and drains all ready tasks through the existing pipeline until the pool is empty — with no `/loop`, no pool-id argument, and no re-invocation between additions.

## 2. In-scope behaviors (numbered, testable)

1. **Default-pool resolution.** Invoking the stream surface with **no pool-id argument** resolves the pool to `docs/batches/default/BATCH_PLAN.md`.
2. **Default-pool auto-creation.** When `docs/batches/default/BATCH_PLAN.md` does not exist at no-arg invocation, it is created by copying `docs/batches/_template/BATCH_PLAN.md` (with `<batch-id>` replaced by `default`). The example task rows from the template are left as a seedable starting point OR replaced with an empty task table — see Open Question 1.
3. **Ambient enter.** A defined enter action (keyword/command — Open Question 2) writes an **ambient flag marker file** at a fixed path (SA decides exact path; the requirement is only that the path is fixed and discoverable).
4. **Ambient flag is transient and gitignored.** The marker file is runtime state, not version-controlled; `.gitignore` excludes it (matching the existing `.harness/intervention.md` convention).
5. **Ambient exit.** A defined exit action (keyword/command — Open Question 2) removes the ambient flag marker file. After exit, normal chat is no longer treated as task input.
6. **UserPromptSubmit hook — gated heartbeat.** A `UserPromptSubmit` hook runs on every user turn. When the ambient flag marker file is present, the hook injects instruction/context into the turn telling the agent to (a) normalize any requirement-like message into a `pending` row in the default pool (de-duplicated against existing slugs/goals), (b) drain ready tasks in topological order through the harness pipeline until the pool is empty, then (c) stop and wait.
7. **Hook no-op when flag absent.** When the ambient flag marker file is absent, the `UserPromptSubmit` hook injects nothing (it is a no-op); normal chat is unaffected.
8. **Hook instructs, does not execute.** The hook script never performs ingestion/draining itself; it only emits the instruction text. Claude (the agent) is the worker.
9. **Serial drain only.** At most one task runs at a time. No parallel dispatch.
10. **Resume is free.** The pool file (`BATCH_PLAN.md`) is the only persistent state needed; a partially-drained pool resumes correctly on the next user turn because the existing stream resume semantics (skip rows whose `07_DELIVERY.md` is DELIVERED) apply unchanged.
11. **Reuse existing draining semantics.** Per-task routing goes through `pm-orchestrator` (never bypassed); best-effort completion and the existing hard-safety stops (verify_all FAIL, STOP intervention, guard-rm block) apply unchanged.
12. **Hook script twins.** The new hook script ships as both `.ps1` and `.sh`, present in both the dogfood `.harness/scripts/` and the template `skills/harness-init/templates/common/.harness/scripts/` (so `sync-self --check` E.1 and F.1 symmetry stay green).
13. **Template settings wiring.** `skills/harness-init/templates/common/.claude/settings.json.tmpl` is edited to register the `UserPromptSubmit` hook (so users who run `/harness-init` get it). The pwsh command passes `-NoProfile`. `$schema` stays the canonical `.json` URL. No doc/underscore keys are placed inside the `hooks` object.
14. **Dogfood settings PROPOSE-ONLY.** The dogfood `.claude/settings.json` is NOT edited by the Developer; the exact hook JSON block to paste is surfaced in `04_DEVELOPMENT.md` and `07_DELIVERY.md`.
15. **Doc updates.** harness-stream `SKILL.md` gains an ambient section; README (EN + zh) reflects the no-arg/ambient capability; `CHANGELOG.md` gets an `[Unreleased]` entry; AI-GUIDE.md and dev-map.md are updated if a new script/path is introduced.

## 3. Out-of-scope

1. `/loop` integration and any idle/unattended progress while the user is silent (the heartbeat is exclusively the user's own chat messages).
2. Parallel task execution (explicitly deferred; parallel-stream remains deferred per commit 01502c0).
3. Multiple concurrent ambient pools / multiple default pools.
4. Any **new lettered** `verify_all` check that would force a version bump.
5. Any skill-count / check-count claim change (the minimal version must not bump counts; if SA finds a count change unavoidable, that is escalated, not silently absorbed).
6. Mid-task chat ingestion (chat lands at the next turn boundary; this is the same timing truth already documented for harness-stream).

## 4. Boundary conditions

- **No pool-id + no existing default pool** → auto-create from template (behavior 2).
- **No pool-id + existing default pool with pending rows** → resume/append into it (behaviors 1, 10).
- **Ambient flag present but message is NOT a requirement** (a question/aside) → no new row created; the agent answers normally and (if pool non-empty) still drains ready tasks. Ambiguous message → ask before creating a row (do not guess), per existing stream rule.
- **Ambient flag absent** → hook injects nothing; chat is ordinary (behavior 7).
- **Duplicate requirement** (same slug/goal already in pool) → de-dupe, no second row (behavior 6a).
- **Empty pool + ambient ON + non-requirement message** → no rows to drain; agent simply responds and waits.
- **Ambient enter when already in ambient mode** → idempotent (flag already present; re-entering is a no-op or refreshes the marker).
- **Ambient exit when not in ambient mode** → idempotent (no flag to remove; no error).
- **Concurrency** → serial only; no two tasks at once (behavior 9). The hook itself must be fast and side-effect-light (it only echoes instruction text).
- **pwsh per-call cost** → the hook must pass `-NoProfile` so the user's `$PROFILE` does not run per turn (insight L17: 3.7s p50 without it).
- **Stale flag across sessions** → because the flag is a file, it persists across sessions; exit must be explicit. (A user who forgets to exit will have chat captured next session — this is the documented trade-off; exit keyword is the mitigation.)

## 5. Acceptance criteria (verifiable)

- **AC-1** No-arg invocation resolves to `docs/batches/default/BATCH_PLAN.md` (verify: SKILL.md procedure states it; QA traces the no-arg path).
- **AC-2** No-arg invocation with absent default pool creates it from `_template` (verify: file presence after the action; auto-creation logic stated in SKILL.md).
- **AC-3** Ambient enter writes the flag marker file at the fixed path; ambient exit removes it (verify: presence/absence; QA enter-then-exit case).
- **AC-4** Flag marker file is matched by `.gitignore` (verify: `git check-ignore` or `.gitignore` line presence).
- **AC-5** With flag present, the `UserPromptSubmit` hook emits the ingest+drain instruction text (verify: run the hook script with flag present → non-empty instruction output).
- **AC-6** With flag absent, the `UserPromptSubmit` hook emits nothing / no-op (verify: run the hook script with flag absent → empty/no-op output).
- **AC-7** Hook script twins (`.ps1` + `.sh`) exist in both dogfood `.harness/scripts/` and template `templates/common/.harness/scripts/` (verify: file presence; F.1 pair list; E.1 sync-self check green).
- **AC-8** Template `settings.json.tmpl` registers `UserPromptSubmit` with a `-NoProfile` pwsh command, canonical `$schema`, and no doc keys inside `hooks` (verify: J.1 schema check; grep for `-NoProfile`).
- **AC-9** Dogfood `.claude/settings.json` is UNCHANGED by the Developer; the exact propose-only block appears in 04 + 07 (verify: git diff shows no `.claude/settings.json` change; 04/07 contain the block).
- **AC-10** Docs updated: harness-stream SKILL.md ambient section, README EN+zh, CHANGELOG `[Unreleased]`, dev-map (+ AI-GUIDE if a new script/path added) (verify: presence of each edit; doc-sync rules).
- **AC-11** `.harness/scripts/verify_all` PASSES on the user's shell (Windows → `.ps1`); both twins kept in lockstep (verify: paste real Summary into 07).
- **AC-12** No version bump and no count-claim change (verify: plugin.json/marketplace.json/README badges unchanged; G.3/G.4 green without a bump). If SA must introduce a count change, that is escalated.
- **AC-13** If any new `{{...}}` placeholder is added to a `.tmpl`, it is added to BOTH verify_all D.2 whitelists (verify: D.2 green; grep both shells).

## 6. Non-functional requirements

- **Performance:** the `UserPromptSubmit` hook adds negligible per-turn latency; `-NoProfile` is mandatory on the pwsh command (insight L17).
- **Compatibility:** PS/Bash twin symmetry (F.1); both shells behave identically; verify_all PASSES on Windows `.ps1` and stays in lockstep with `.sh`.
- **Schema correctness:** template `settings.json.tmpl` must satisfy verify_all J.1 (valid `hooks` keys; canonical `$schema` `.json` URL; no underscore keys inside `hooks`). `UserPromptSubmit` must be confirmed a valid hook event against the upstream schema before editing.
- **Safety:** the dogfood `.claude/settings.json` is propose-only (red line); the hook must never silently capture casual chat (gated by the flag; explicit exit provided).

## 7. Related tasks

- `docs/features/_archived/` (parallel-stream deferral, commit 01502c0) — parallel execution stays OUT of scope here.
- `/harness-stream` shipped v0.22.0 (commit 2e134ea) with the `ADD` intervention keyword and living-pool draining — this task extends that surface; see `skills/harness-stream/SKILL.md` (esp. the "Two ways to add work mid-run" and "Procedure" sections) and `.harness/rules/65-intervention.md`.
- T-001 ai-safety-guardrails (`docs/features/_archived/ai-safety-guardrails/`) — established the `-NoProfile` pwsh-hook insight (L17) and the guard-rm `PreToolUse` hook command shape to mirror.
- T-008/T-010 (G.4 count↔version gate) — the no-version-bump constraint is governed by G.3/G.4.

## 8. Open questions for user

> Note: the design is converged with the user (per PM brief). These are the only residual decisions; PM/SA may resolve them within the converged design rather than blocking on the user. Candidate answers provided.

1. **Default-pool seed content on auto-creation.** When `docs/batches/default/BATCH_PLAN.md` is auto-created, should the task table be (a) the template's example rows verbatim (user deletes them), or (b) an **empty task table** (header only, no example `T-01..` rows) so the first chat-supplied requirement is the first row? — Recommendation deferred to SA; (b) is cleaner for ambient use.
2. **Enter/exit surface.** Ambient enter/exit should be (a) chat keywords the agent recognizes (e.g. "ambient on" / "ambient off"), (b) a tiny helper script invoked once, or (c) an argument to the stream skill invocation (e.g. `/harness-stream --ambient` to enter, a keyword to exit). — SA chooses; constraint is only "a clear way in and a clear way out".

## 9. Verdict

**READY** — the design is converged and authoritative; the two open questions are intra-design refinements explicitly delegated to the Solution Architect (the PM brief authorizes RA/SA to validate + detail, not re-derive). No requirement is ambiguous to the point of blocking; both open questions carry a recommended default and are bounded by the converged design and SCOPE. Advancing to Stage 2 (solution-architect).
