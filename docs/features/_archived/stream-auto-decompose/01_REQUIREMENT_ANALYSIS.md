# 01 — Requirement Analysis: stream-auto-decompose (T-021)

> Mode: full · Analyst: requirement-analyst · Date: 2026-06-12
> Input: PM dispatch prompt + verbatim user request quoted in `docs/features/stream-auto-decompose/PM_LOG.md:5` (no separate INPUT.md was provided)
> Decision policy: Mode 2 (`.harness/rules/25-decision-policy.md:25`) — ambiguities resolved per `.harness/decision-rubric.md`, each logged in §8.

## 1. Goal

`/harness-stream` ingest currently maps one incoming requirement to exactly one `pending` pool row (`skills/harness-stream/SKILL.md:76,94`); add complexity-triaged automatic decomposition so that a single complex requirement is normalized into N smaller pool rows with `Depends on` staging, while a simple requirement keeps today's 1:1 behavior unchanged.

## 2. In-scope behaviors (functional requirements)

FR-1 **Triage point.** Decomposition triage happens at requirement-normalization time, on the two channels where the stream itself authors the row from natural language:
  - (a) chat-channel ingest under the `/loop` driver (`skills/harness-stream/SKILL.md:94`, Procedure 3a);
  - (b) ambient-turn ingest (`skills/harness-stream/SKILL.md:76` and the injected instruction block in `.harness/scripts/ambient-prompt.ps1:46-62` / `.harness/scripts/ambient-prompt.sh:43-59`).
  Channels where the user authored the row are NOT triaged — see Out-of-scope #1/#2 and decision AD-1/AD-2.

FR-2 **Complexity criteria (observable, no pseudo-quantitative thresholds).** A requirement is "complex enough to decompose" when BOTH hold:
  - (a) it contains two or more outcomes that are each *independently verifiable deliverables* — each could pass its own QA and reach `DELIVERED` on its own (signals: an explicit "and"-chain / enumeration of distinct outcomes; outcomes touching distinct subsystems or artifact classes; the Chinese/English phrasing enumerates phases, e.g. "先…再…", "X, then Y");
  - (b) no single one-sentence Goal can state the requirement without conjoining those outcomes.
  Explicit NON-criteria (must appear in the skill text as counter-examples): a single deliverable with wide fan-out (one change echoed across many files) is ONE task; long prose alone is not complexity; a list of acceptance details for one outcome is ONE task.

FR-3 **Fixed-point granularity.** Each produced sub-row must itself be a deliverable that would NOT be decomposed again under FR-2 (triage is idempotent). This is the only size bound — no numeric cap on N, no "lines of goal text" heuristic.

FR-4 **Decomposition output.** When triage fires, the stream writes N ≥ 2 `pending` rows into the pool, each with its own `ID`/`Slug`/`Goal`/`Mode`/`Depends on`/`Status` — zero schema change (columns per `docs/batches/_template/BATCH_PLAN.md:9`):
  - `Depends on` chains express only REAL ordering constraints; independent sub-tasks carry no fabricated dependency (so best-effort sibling progress is preserved, FR-8);
  - `Mode` is assigned per row by the same workflow-entry trigger mapping used for any normalized requirement (default `full`; e.g. a pure research sub-step may be `explore`). The ambient instruction's current fixed `Mode=full` wording is relaxed to "Mode per row, default full";
  - de-duplication against existing slugs/goals applies per sub-row, exactly as today.

FR-5 **Traceability.** A reader of `BATCH_PLAN.md` alone (no STREAM_LOG) must be able to tell which rows came from decomposing which original requirement. Mechanism class fixed here: a **shared slug prefix across the sub-rows** as the primary grouping signal, optionally plus an origin annotation (Goal-suffix marker or a line in the existing `## Notes` section). Exact format is the architect's choice. Constraint: no new table column.

FR-6 **Simple-requirement invariant.** A requirement that fails FR-2 produces exactly one row via exactly today's normalization path — the resulting pool row and docs path are indistinguishable from current behavior. Degenerate case: a triage that would yield 1 row IS the simple path (no traceability marker, no announcement).

FR-7 **Hard-rule amendment (scope-fidelity invariant).** The existing hard rule at `skills/harness-stream/SKILL.md:141` ("New rows must come from the user (chat / pool / `ADD`), never invented by the stream.") is AMENDED, not silently violated. The amended rule must state: the union of the sub-task Goals is requirement-equivalent to the original message — **no invented scope, no dropped scope**; the stream may derive rows only by partitioning one user requirement; inventing work the user did not ask for remains forbidden. (This mirrors red line #3 in `.harness/rules/25-decision-policy.md:53`, which cites this very stream rule — the amendment must keep that cross-reference truthful, so check whether `25-decision-policy.md:53` wording needs a touch.)

FR-8 **Failure semantics (composition, no new mechanism).** Decomposed groups inherit the existing per-row best-effort + `Depends on` blocking (`skills/harness-stream/SKILL.md:102-104`): a failed sub-task blocks only its transitive dependents; independent siblings keep running; no group-level all-or-nothing semantics are introduced.

FR-9 **Ambiguity boundary.** The existing rule "if a message is ambiguous, ask before creating a row — never guess" stays first and unchanged. Interaction contract: (1) ambiguity gate — is this an unambiguous requirement at all? if not, ask; (2) only then automatic triage (FR-2) — decomposition of a *clearly stated* multi-part requirement is automatic per the user's explicit ask ("AI自动") and asks nothing; (3) if the agent cannot produce a faithful union (cannot tell whether an outcome is requested or merely mentioned), that IS ambiguity → back to (1), ask. Decomposition never adds a confirmation step for clear requirements.

FR-10 **Announcement.** When decomposition fires, the stream states it in the ingest acknowledgment (which IDs/slugs were created from which requirement, and the dependency shape) — the user can correct a wrong split by the existing channels (edit the pool, `SKIP`, `/harness-intervene`).

FR-11 **Hook-text sync.** The ambient ingest instruction lives in two carriers: SKILL.md ambient section AND the hook scripts' injected block. Both must carry the triage wording. Four hook files move in hand-lockstep (per `AI-GUIDE.md:81`): `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`; the ps1/sh emitted blocks stay textually identical. The injected block must stay LEAN (it is a per-turn standing context cost — rule 15 P5/P6): triage criteria live in SKILL.md; the hook block gets only a one-to-two-line pointer-level instruction.

## 3. Out-of-scope (this iteration)

1. **`ADD <slug> — <goal>` intervention lines are NOT triaged** — honored verbatim as one row (decision AD-1).
2. **Pre-existing user-written `pending` rows are NOT retroactively decomposed or rewritten** — the pool is user-visible state; the stream never rewrites a row the user authored (decision AD-2). An oversized hand-written row simply runs as one task, as today.
3. `/harness-batch` untouched (frozen-list semantics; grep confirmed its only stream coupling is the `ADD`-rejection pointer at `skills/harness-batch/SKILL.md:71` — wording stays valid).
4. Parallel execution stays forbidden — serial only, per existing hard rule (`skills/harness-stream/SKILL.md:137`) and the shelved parallel design (`README.md:275`).
5. No new pool schema columns; no new `BATCH_PLAN.md` file format.
6. No new `verify_all` check, no new I.6 banned entry, no new hooks (decisions AD-4/AD-5).
7. `/harness-plan` manual decomposition flow unchanged (it remains the heavyweight design-vetted path; this feature is ingest-time triage only).
8. No mid-task re-decomposition: a `failed` sub-task is not auto-re-split; the existing "do not auto-retry" anti-pattern (`skills/harness-stream/SKILL.md:147`) extends naturally.
9. Ambient flag/hook architecture unchanged — text-only edit inside the existing instruction block.

## 4. Boundary conditions

| Condition | Required behavior |
|---|---|
| Empty message / question / aside | No row — unchanged (`SKILL.md:76`) |
| Ambiguous requirement | Ask first — unchanged; triage runs only on unambiguous requirements (FR-9) |
| Simple requirement (fails FR-2) | Exactly one row, today's path, no marker (FR-6) |
| Complex, parts independent | N rows, no fabricated `Depends on` (FR-4) |
| Complex, parts ordered | N rows with a real `Depends on` chain ("分阶段完成") |
| Triage would yield N=1 | Treated as simple — no decomposition artifacts (FR-6) |
| Very large requirement | No numeric cap; FR-3 fixed-point is the only bound; if faithful partition is impossible from the text → ambiguity → ask (FR-9) |
| Sub-row slug/goal collides with an existing row | De-dup per existing rule, per sub-row (FR-4) |
| One sub-task FAILED/BLOCKED | Transitive dependents `blocked`; independent siblings continue; stream continues (FR-8) |
| `verify_all` FAIL after any sub-task | Hard stop — unchanged (`SKILL.md:117`) |
| Concurrency | Serial only — unchanged |
| Pool file write | Same single-file edit semantics as today; no new atomicity mechanism |

## 5. Acceptance criteria (all verifiable; this is a Markdown-skill + hook-text change — gates are doc-consistency checks + adversarial reading)

AC-1 `skills/harness-stream/SKILL.md` Procedure 3a AND the ambient-turn section both contain the triage instruction with FR-2 criteria + counter-examples, FR-3 fixed-point, FR-4 output contract, and the FR-6 1:1 fallback.
AC-2 The hard rule at the current `SKILL.md:141` is replaced by the FR-7 amended rule (union-equivalence invariant present; "never invented" retained for non-derived work); `.harness/rules/25-decision-policy.md:53` cross-reference still reads truthfully.
AC-3 All four `ambient-prompt` hook files carry the updated lean instruction; the `.ps1` here-string block and `.sh` heredoc block are textually identical within each pair, and dogfood ≡ template per pair (byte-compare the emitted blocks).
AC-4 Traceability is specified in SKILL.md such that grouping is decidable from `BATCH_PLAN.md` alone (FR-5); the `ID|Slug|Goal|Mode|Depends on|Status` schema is unchanged.
AC-5 QA constructs at least four probe requirements and verifies the skill text dictates the right outcome unambiguously: (i) single deliverable → 1 row; (ii) "and"-chain of independent deliverables → N rows, no false deps; (iii) phased "X then Y" → chain; (iv) single deliverable with wide fan-out → 1 row (the counter-example holds).
AC-6 `.harness/scripts/verify_all` 32/32 PASS both shells. G.1/G.2 unaffected (no new skill name); G.4 PASSes with `plugin.json` + `marketplace.json` bumped and a matching CHANGELOG section (AD-3); I.6 green — chosen wording must not reproduce any banned anchor sequence (run, don't reason).
AC-7 Doc fan-out complete — every live surface that states stream ingest behavior is synced; grep for the old single-row claim finds no stale live text. Verified surface list in §6.
AC-8 No regression in untouched test drivers: `test-init` / `test-real-project` ambient asserts are command-wiring only (`test-init.ps1:328`, `test-init.sh:291`) — they must stay green without modification; no `test-*` driver pins harness-stream SKILL text (grep-verified 2026-06-12, see §8 evidence).

## 6. Doc surfaces (grep-verified 2026-06-12; cite before edit)

| Surface | Action |
|---|---|
| `skills/harness-stream/SKILL.md` — description:3, two-channels:45-47, ambient:60/71/76, Procedure 3a:94, Hard rules:141, Anti-patterns:144-149, Cost:151-153 | EDIT (object of change; description gains the decomposition trigger phrase per rule 15 P1; Cost notes N sub-tasks ≈ N × 7-stage) |
| `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}` | EDIT, 4-file hand-lockstep (FR-11) |
| `README.md:21` stream bullet; new Roadmap row (pattern of `README.md:271`) | EDIT |
| `README.zh-CN.md:21` + its Roadmap row | EDIT (mirror) |
| `CHANGELOG.md` | EDIT — new version section naming the change (AD-3) |
| `.claude-plugin/plugin.json:4` + `.claude-plugin/marketplace.json:17` (both `0.31.0`) | EDIT — version bump (AD-3) |
| `docs/batches/README.md:28-33` Streams paragraph (describes ingest channels) | EDIT — one sentence on triage |
| `AI-GUIDE.md:93` stream row | CHECK-ONLY — trigger text makes no ingest-granularity claim; no edit expected |
| `docs/getting-started.md:45`, `docs/dev-map.md:57`, `docs/manual-e2e-test.md:36/54/62` | NO CHANGE — one-liners / skill enumerations, no ingest semantics |
| `docs/harness-stream.html` | NO MANDATORY SYNC — version-pinned zh snapshot ("v0.22.0" in `<title>`, same class as project-overview.html v0.17.0); architect MAY refresh (AD-6) |
| `skills/harness-intervene/SKILL.md:42`, `.harness/rules/65-intervention.md:53`, `skills/harness-batch/SKILL.md:71` | CHECK-ONLY — `ADD` stays verbatim (AD-1), so wording stays true; architect may add one clarifying clause that `ADD` rows are honored as-written |

## 7. Non-functional requirements

NFR-1 **Context budget.** The per-turn injected hook block grows by at most ~2 lines (rule 15 P5/P6 + `70-doc-size.md`); SKILL.md stays within its rule-70 soft cap.
NFR-2 **Cross-shell parity.** ps1/sh hook pairs stay symmetric (`30-engineering.md` convention; insight family 2026-06-08).
NFR-3 **English** for all artifacts (repo policy).
NFR-4 **No new resident machinery** — no new hook events, checks, scripts, or schema (operator preference: design over guards).

## 8. Autonomous decisions (Mode 2 — recorded for review-after)

- **AD-1 `ADD` channel: OUT of triage.** Options: (a) triage all ingest channels uniformly; (b) triage only where the stream authors the row. Chose (b): an `ADD <slug> — <goal>` line is a user-authored row in fixed grammar — the user already chose the granularity; silently splitting it rewrites user-authored state and surprises. Rubric basis: good operator experience + match existing conventions (the pool is the user-visible source of truth, `SKILL.md:140`). Reversible later by one SKILL sentence.
- **AD-2 Pre-existing oversized `pending` rows: OUT.** Same rationale as AD-1; also keeps `/harness-batch` parity trivial (a hand-written plan runs identically under batch and stream). The clean rule the skill must state: **decomposition applies where the stream normalizes natural language; never to a row the user authored.**
- **AD-3 Version bump: YES, new minor (0.31.0 → 0.32.0 expected; final number is PM/architect's).** PM-flagged insight 2026-06-05: feature additions are version-worthy and G.4 gates the CHANGELOG↔plugin.json pairing. Precedent both ways exists (ambient shipped under `[Unreleased]`; `/harness-decision-mode` got 0.28.0); a user-facing behavior change to a shipped skill warrants a version. Rubric: honest reporting + sound engineering.
- **AD-4 No new I.6 banned entry for the retired absolute hard-rule sentence.** The old stricter rule resurrecting would disable the feature, not create a hazard or a false claim about reality; I.6 entries cost a 4-file lockstep + count bump (insight 2026-06-08) and the operator's standing preference is design-over-guards. QA's stale-claim grep (AC-7) covers the drift risk once.
- **AD-5 No new `verify_all` check.** No gate gap found: G.4 covers version pairing, F.1 already covers hook-pair existence, and the change introduces no new countable claim class.
- **AD-6 `docs/harness-stream.html` treated as a version-pinned snapshot** (no mandatory sync). Title self-identifies as v0.22.0; repo precedent: `docs/project-overview.html` "v0.17.0 snapshot" (`AI-GUIDE.md:68`).
- **Evidence for AC-8 / §6:** grep of `.harness/scripts/test-*.{ps1,sh}` for `harness-stream` → zero SKILL-text pins (only `ambient-prompt` command-wiring asserts: `test-init.ps1:107,109,328,586,699`, `test-init.sh:45,51,291`, `test-real-project.{ps1:113,sh:44,50}`); `skills/harness-status/SKILL.md` → zero `stream` matches, so the 2026-06-11 test-supervisor-pinning insight does not apply.

## 9. Related tasks

- **T-011 ambient-stream** — `docs/features/_archived/ambient-stream/` (created the ambient ingest contract + the dual-carrier hook/SKILL text this task amends; its 01/02 docs define the instruction-block mechanism).
- **T-006 harness-batch-skill** — `docs/features/_archived/harness-batch-skill/` (origin of the `ID|Slug|Goal|Mode|Depends on|Status` pool schema reused unchanged).
- Stream skill itself shipped v0.22.0 — `CHANGELOG.md:218-239` (no per-task folder; operator-era entry).
- **T-008 test-supervisor-stamps** — `docs/features/_archived/test-supervisor-stamps/` (G.4 gate this task's version bump must satisfy).

## 10. Open questions for user

None — all judgment calls were rubric-covered and are recorded in §8 for review-after. No red line is touched (the feature is exactly the user's conditional request; PM verified it is unsupported today, `PM_LOG.md:6`).

## Verdict

**READY** (for Stage 2 — solution design).
