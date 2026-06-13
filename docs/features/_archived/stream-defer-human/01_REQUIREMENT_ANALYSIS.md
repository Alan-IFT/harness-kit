# 01 — Requirement Analysis · T-022 `stream-defer-human`

- Task: Make `/harness-stream` defer a task that needs human assistance (set it aside, keep draining everything else runnable) and surface all human-asks together at the end, instead of sitting stopped.
- Mode: full · Decision policy: this repo is Mode 2 (resolve rubric-covered ambiguities autonomously, record them; escalate red lines only — `.harness/rules/25-decision-policy.md`).
- Object of change: `skills/harness-stream/SKILL.md` (v0.32.0, 175 lines) + the dispatch contract in `agents/pm-orchestrator.md`. The shipped behavior must be **decision-mode-agnostic** (correct under Mode 1 default in generated projects, where far more points reserve human input, and under Mode 2/3).

## 1. Goal

When `/harness-stream` drains an open pool unattended, a task that needs human input is **set aside (not halted-on)**; the stream completes every other runnable task; and all human-asks are surfaced together at stream end so the human resolves them in one sitting.

## 2. Taxonomy of per-task stop-reasons (the spine of this requirement)

Every interruption to a per-task drain falls into exactly one bucket; the required behavior of each:

- **(a) DELIVERED** — task done. Required: mark `done`, continue. (No change; today's behavior — SKILL.md:124.)
- **(b) FAILED** — code defect, exhausted retries, or pm-orchestrator's 3-same-stage-rollbacks FAILED. Required: **best-effort, unchanged** — mark `failed`, mark dependents `blocked`, continue (SKILL.md:123-125, :136). Stated here only so the taxonomy is complete; no change.
- **(c) NEEDS HUMAN ASSISTANCE (NEW first-class class)** — the task cannot proceed without (i) a clarification of an ambiguous requirement, (ii) a judgment-call decision the **active decision-mode reserves for the human** (under Mode 1: any judgment call; under Mode 2/3: a red line or a rubric-uncovered/irreversible call), or (iii) authorization for a safety-critical *action* (production write, deploy, signing). Required NEW behavior: **defer** — record the exact question/missing info, set a distinct deferred marker, block only this task's own `Depends on` descendants (never siblings), **continue draining**, surface at stream end. The stream must NOT perform the action and must NOT halt.
- **(d) HARD-SAFETY STOP** — `verify_all` returns FAIL after a task (poisoned baseline); `.harness/intervention.md` contains STOP; the `guard-rm` hook blocked an attempted destructive Bash command inside a task. Required: **UNCHANGED — these halt the stream immediately** (SKILL.md:134-142).

**Bright line between (c) and (d):** a *request for* a safety-critical action defers (the action is not performed, the stream does not halt — class c); a `guard-rm` *block of a destructive command already attempted* halts (class d). Requesting deploy authorization ≠ a baseline-corrupting event; an attempted `rm` outside the repo IS.

## 3. In-scope behaviors (testable)

1. The stream classifies each per-task drain outcome into exactly one of (a)–(d) above and applies that bucket's behavior.
2. A class-(c) outcome NEVER halts the stream; the stream proceeds to the next ready task.
3. A class-(c) task records a **deferred-human-queue entry** carrying: `ID`, `Slug`, the stage/agent that raised it, the **verbatim** question or missing info, and **what input would unblock it**.
4. A class-(c) task's pool row gets a distinct deferred marker (status value — §3 decisions D-1) so report tallies separate "deferred-for-human" from "failed".
5. A class-(c) task blocks ONLY its own `Depends on` descendants; independent siblings stay runnable (mirrors the existing `failed`-dependents rule, SKILL.md:125).
6. The main loop does NOT issue a blocking `AskUserQuestion` for a **deferrable** need while running unattended (continuous / `/loop` drivers) — it records a queue entry instead (replaces SKILL.md:115 "ask via `AskUserQuestion` before creating a row" and SKILL.md:76 / the ambient-prompt hook "ask before creating a row — do not guess").
7. When dispatched by the stream, `pm-orchestrator` returns a structured verdict `BLOCKED: needs human — <verbatim question/info>` for class-(c) cases and never attempts an interactive ask, and never silently auto-decides a point the active decision-mode reserves for the human just to avoid blocking (that would violate `25-decision-policy.md`).
8. The stream passes a "running under a stream — defer, do not ask" signal in its pm-orchestrator dispatch prompt (alongside the existing mode), so the sub-agent knows interactive asks are unavailable.
9. `STREAM_REPORT.md` gains a prominent, **FIRST** `## Needs your input` section enumerating every deferred item with its exact ask and the unblocking input.
10. The final chat message **leads** with the needs-input digest (count + the asks), not a one-line tally (replaces SKILL.md:126 / :149-150 surfacing order).
11. Resume: after the human supplies input (pool edit / `ADD` / `/harness-intervene` / chat), re-invoking the stream re-runs the deferred rows via the **existing** resume semantics — a row whose `07_DELIVERY.md` is not DELIVERED is re-evaluated and runnable (SKILL.md:118). No new resume mechanism.

### Ingest-ambiguity rule (in-scope D-2)

12. An ambiguous chat/ambient message that today blocks via `AskUserQuestion` is instead **deferred to the needs-human queue** (recorded as a clarification ask, no pool row created) and the stream keeps draining — under ALL stream drivers including ambient. Rationale: the user's stated goal is "never sit stopped"; a single uniform rule is simpler and removes the last mid-drain blocking prompt. (Architect makes the final structural call; this is the requirement's intent — see Autonomous decisions D-2.)

## 4. Out-of-scope (non-goals)

- `/harness-batch` stays fail-fast — its halt policy is NOT changed (the user spoke only of the open pool). The pm-orchestrator contract change (structured `BLOCKED: needs human` return) incidentally produces a cleaner BLOCKED payload that batch also receives; batch keeps stopping on it. Acceptable: a richer halt *message* is not a halt-*policy* change.
- No parallelism — serial drain stays (SKILL.md:158, hard rule).
- No new pool-schema **column** (the `ID|Slug|Goal|Mode|Depends on|Status` shape is unchanged; a new Status **value** needs no column).
- No new `verify_all` check unless a real gate gap is proven (operator preference: design out root causes, do not accrete guards — `[[feedback_design_over_guards]]`, decision-rubric line "A new `verify_all` check … must prevent a concrete hazard").
- The three hard-safety stops (class d) are NOT weakened.
- No idle/background progress while the human is away (that is the separate `/loop` concern — SKILL.md:82).

## 5. Boundary conditions

- **Empty queue:** no deferred items → `## Needs your input` section reads "None" (or is omitted by an explicit rule the architect fixes); the final chat message leads with the normal tally.
- **All pool tasks defer:** every task is class (c) → no hard stop fires, pool "drains" to all-deferred, report lists every ask; stream exits normally (not a halt).
- **A deferred task's only dependents are siblings:** siblings must still run (dependents-blocking is `Depends on`-scoped, never positional).
- **Same task re-deferred on resume:** after the human answers, the row re-runs; if it defers again (answer insufficient), a fresh queue entry is recorded — no duplicate-suppression requirement in v1.
- **Mixed run:** failed + deferred + delivered tasks coexist; tallies and the report must separate `failed` from deferred (distinct markers, D-1).
- **Class (c) and class (d) in the same task:** a hard-safety event (d) always wins — if a task both requests authorization AND trips `guard-rm`, the `guard-rm` block halts (d), the request is moot.
- **Mode 1 project (generated default):** many more points are class (c); the feature must still terminate (drain to all-deferred), not loop.

## 6. Acceptance criteria (verifiable; this is a Markdown skill + agent-contract change)

The "tests" are doc-consistency gates + adversarial review (no runtime code):

- **AC-1 verify_all PASS both shells.** `.harness/scripts/verify_all` returns 32/0/0 (PS and bash). The feature adds no check and no skill, so **count stays 32, skills stay 15** (C.1, G.1, G.2, G.4 count claims unchanged).
- **AC-2 version surfaces lockstep.** G.3 four-way (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` + README.md badge + README.zh-CN.md badge) all bump 0.32.0 → 0.33.0; G.4 version claims + a `## [0.33.0]` CHANGELOG heading present (a feature add is version-worthy — insight 2026-06-05).
- **AC-3 no retired-claim self-trip (I.6).** New/edited prose does not resurrect a banned phrase; if "best-effort never halts" wording changes, re-check the I.6 banned/exempt lockstep (insight 2026-06-08 four-file lockstep — only if a banned anchor is touched).
- **AC-4 doc-size caps (I.1–I.3).** `agents/pm-orchestrator.md` stays ≤300 lines (currently 200); SKILL.md and edited docs stay under their caps (rule 70).
- **AC-5 ASCII-only in hook-injected text.** The ambient-prompt hook block edit uses ASCII punctuation only (no em-dash / `≡`) — insight 2026-06-12 (pwsh GBK console → mojibake for non-ASCII in hook stdout).
- **AC-6 taxonomy is unambiguous.** A reviewer reading SKILL.md can classify any of the 4 stop-reasons into exactly one bucket with the stated behavior; the (c)/(d) bright line is explicit.
- **AC-7 the pm-orchestrator contract is binding.** `agents/pm-orchestrator.md` states the structured `BLOCKED: needs human — <verbatim>` return shape and the "never silently auto-decide a reserved point to avoid blocking" rule; "When to stop and ask the user" (pm-orchestrator.md:193-200) is reconciled with stream-driven dispatch.
- **AC-8 every behavior-describing doc surface is synced** (grep-verified list, §7).
- **AC-9 adversarial pass.** Gate/Code/QA confirm: no mid-drain blocking prompt remains in any unattended path; the report leads with `## Needs your input`; resume re-runs deferred rows with no new mechanism.

## 7. Doc surfaces to sync (grep-verified — the architect's fan-out ledger)

The following surfaces describe stream stop/continue OR pm-orchestrator "ask the user" behavior and must be reconciled:

- `skills/harness-stream/SKILL.md` — description frontmatter (:3), ambient step 1 (:76), Ingest triage / Procedure 3a ambiguity-ask (:115), step g best-effort (:123-125), step h one-line report (:126), Stop conditions (:134-142), On stream completion / STREAM_REPORT (:144-153), Hard rules (:155-163), Anti-patterns (:165-171).
- `agents/pm-orchestrator.md` — "When to stop and ask the user" (:193-200), Hard rules (:12-21).
- **Ambient-prompt hook carriers (4 files, lockstep):** `.harness/scripts/ambient-prompt.{ps1,sh}` (bash :53-57 carries the "ambiguous → ask before creating a row" + "best-effort, honoring hard-safety stops" text) + the two template copies `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`. (`ambient-reset.*` unaffected.)
- `docs/batches/README.md` — stream best-effort/stop bullet (:28) and the Status-value enumeration in Column reference (only if D-1 adds a value).
- `docs/batches/_template/BATCH_PLAN.md:27` — Status-value enumeration (`pending|in-progress|done|failed|blocked|skipped`) — edited ONLY if D-1 adds a new value.
- `README.md` headline stream bullet (:21) + `README.zh-CN.md` (:21); new milestone row v0.33.0 in both (historical milestone rows for shipped versions are append-only — do not rewrite v0.22.0/v0.32.0 rows).
- `CHANGELOG.md` — new `## [0.33.0]` entry.
- `docs/dev-map.md:57` — harness-stream one-liner (only if its best-effort phrasing is now incomplete).
- `AI-GUIDE.md` workflow-entry stream row (:93) — only if the trigger text changes (it likely does not).
- **Version manifests:** `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json` (version), README badges (G.3).

**Test drivers that pin touched text (grep-confirmed):** `verify_all.{ps1,sh}` C.1/G.1/G.2 list `harness-stream` by name (presence/count only — no behavior assertion). `test-supervisor.{ps1,sh}` matches `AskUserQuestion` only in supervisor-frontmatter assertions (:138-166) — unrelated to the stream's tool list. **No `test-*.{ps1,sh}` driver asserts harness-stream/pm-orchestrator stop/continue prose**, so no test-driver text is pinned by this change beyond count/version (AC-1/AC-2). `docs/concepts.md` / `docs/workflow.md` do NOT describe stream stop behavior (grep clean) — no sync needed.

## 8. Non-functional requirements

- **Compatibility:** behavior must be correct under decision Mode 1/2/3. "Escalate to human" (decision policy) and "defer-and-continue" (this feature) **compose**: when the active mode says a point is the human's, the stream does not auto-decide it — it defers (records the ask) and continues. They do not contradict: decision policy chooses *who decides*; this feature chooses *when the human is asked* (at end, not mid-drain). The red lines in `25-decision-policy.md` are unchanged (still escalate — now via defer-and-surface, not a blocking prompt).
- **No new resident hook / no new check** (anti-bloat).
- **Cross-shell parity** for any edited hook carrier (PS/Bash byte-symmetry — the recurring parity family).

## 9. Related historical tasks

- T-021 `stream-auto-decompose` (v0.32.0, `docs/features/_archived/stream-auto-decompose/`) — the immediately prior stream change; established the 4-file ambient-prompt hook lockstep + criteria single-sourcing pattern this task reuses.
- T-011 `ambient-stream` (`docs/features/_archived/ambient-stream/`) — origin of the ambient flag/hook + the "ambiguous → ask" text being changed.
- T-006 `harness-batch-skill` (`docs/features/_archived/harness-batch-skill/`) — batch's fail-fast policy that stays unchanged (the non-goal boundary).
- T-018 `decision-mode-skill` (`docs/features/_archived/decision-mode-skill/`) — Mode 1/2/3 policy that must compose with defer-and-continue.

## 10. Autonomous decisions (Mode 2 — recorded per `25-decision-policy.md`; none are red lines)

- **D-1 — Status marker (reuse `blocked` with a reason-class vs add `needs-human` value).** RECOMMEND: a distinct status **value** (e.g. `needs-human`) so report tallies and the dependents rule cleanly separate "deferred for the human" from "blocked by a failed dependency". Adding a value needs no schema column change but DOES require editing the Status enumeration in `docs/batches/_template/BATCH_PLAN.md:27` and `docs/batches/README.md` Column reference; no `verify_all` check pins the enum, so neither choice adds a gate. Rubric basis: "good operator experience" + "honest reporting" (accurate tallies). Final structural choice is the architect's (reversible) — requirement only mandates the *distinction is visible*.
- **D-2 — Ingest-ambiguity: defer uniformly vs allow an immediate ask under ambient.** RECOMMEND uniform **defer** (in-scope item 12) — the user's goal is "never sit stopped", and a single rule is more maintainable than a driver-conditional one. Rubric basis: "good operator experience" + "long-term maintainability over a special case". Architect may carve an ambient-present exception if it argues a stronger UX case; requirement states the intent (no blocking prompt in unattended drain).
- **D-3 — Feature is version-worthy → 0.33.0** (insight 2026-06-05; G.4-gated). Not a scope expansion (the user explicitly asked: "需要修复这个问题").
- **D-4 — Batch incidental benefit accepted** (richer BLOCKED message, same halt policy) — within scope, not a batch policy change (non-goal preserved).

## 11. Open questions for user

None. The user's request is unambiguous ("fix this: finish what can be done, surface human-asks at the end"); all design-shaping ambiguities are reversible and rubric-covered (D-1, D-2) — resolved autonomously under Mode 2 and recorded above, to be finalized by the architect.

## 12. Verdict

**READY FOR DESIGN.** No open questions for the user; the requirement is testable, the doc-surface fan-out is grep-verified, and the decision-policy composition is specified. Hand to `solution-architect` (stage 2).
