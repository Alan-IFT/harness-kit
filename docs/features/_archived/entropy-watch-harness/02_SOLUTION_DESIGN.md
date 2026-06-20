# 02 — Solution Design · T-11b `entropy-watch-harness`

- Task: Wire the cadenced anti-entropy watch into the `/harness` single-task delivery boundary, reusing the entire T-11a core.
- Mode: full · Upstream RA verdict: **READY** (PM accepted the RA's recommended OQ defaults).
- Verdict: **READY** (see §12).
- Depends on: T-11a (DELIVERED v0.41.0) — `entropy-cadence.{ps1,sh}`, the read-only supervisor entropy lens, `references/entropy-scan.md`, the `## Entropy watch` surfacing shape all exist and are reused unchanged.

---

## 1. Architecture summary

This slice is **pure documentation wiring** over the T-11a core: it adds a compact, non-blocking cadence call-sequence to the PM Orchestrator's stage-7 delivery section (`agents/pm-orchestrator.md` "What to write at delivery (stage 7)"), plus a single referencing line in the `/harness` skill (`skills/harness/SKILL.md` step 10). When a single-task `/harness` run reaches a DELIVERED outcome, the PM now increments the **same** shared cadence counter the stream uses (`.harness/scripts/entropy-cadence delivered`), checks it with the plain `check` (no `--first-of-session`), and — only when `DUE` — dispatches the existing supervisor entropy lens once, appends a `## Entropy watch` section to `07_DELIVERY.md`, then resets via `swept`. No new script, skill, state file, or `verify_all` check is introduced; the only executable additions are 4 version stamps + a CHANGELOG entry (`0.41.0` → `0.42.0`).

---

## 2. Affected modules

| File | Change | Why |
|---|---|---|
| `agents/pm-orchestrator.md` | EDIT — add cadence call-sequence + `## Entropy watch` section-format prose to the stage-7 delivery block (the authoritative home) | OQ-2 (a): the PM agent owns the delivery mechanics (07_DELIVERY, tasks.md, archive-task) this extends |
| `skills/harness/SKILL.md` | EDIT — add ONE referencing line at step 10 (declare-done) | DRY: thin user-facing restatement points at the home, zero duplicated prose |
| `.claude-plugin/plugin.json` | EDIT — `version` L4 `0.41.0` → `0.42.0` | G.3 version stamp 1/4 |
| `.claude-plugin/marketplace.json` | EDIT — `plugins[0].version` L17 `0.41.0` → `0.42.0` | G.3 version stamp 2/4 |
| `README.md` | EDIT — version badge L5 `version-0.41.0-blue` → `version-0.42.0-blue` (token only) | G.3 version stamp 3/4 |
| `README.zh-CN.md` | EDIT — version badge L5 `version-0.41.0-blue` → `version-0.42.0-blue` (token only) | G.3 version stamp 4/4 |
| `CHANGELOG.md` | EDIT — add `## [0.42.0] - <date>` section above `## [0.41.0]` (L8) | G.4 reads the latest CHANGELOG heading + count claims |

No new files. No source/script edits. No `verify_all` edits.

---

## 3. Module decomposition (no new modules)

There are **no new modules** in this slice — it is wiring + version stamps only. The behavior is expressed entirely as additive prose in `agents/pm-orchestrator.md`. The exact text is given verbatim in §6 so the Developer makes no design decisions.

---

## 4. Data model changes

None. The shared state file `.harness/entropy-watch.state` (key=value: `delivered_since_sweep`, `last_sweep`) is created/owned by `entropy-cadence` and is unchanged. The `/harness` boundary reads/writes it only through the cadence CLI (`delivered` / `check` / `swept`), never directly — same as the stream. This realizes in-scope #9 / AC-7: a `/harness` delivery advances the **same** counter the stream reads.

---

## 5. API / contract (the cadence CLI is the only "API"; reused as-is)

The `entropy-cadence` pair already exposes the only contract this slice consumes (verified in `.harness/scripts/entropy-cadence.sh`):

| Invocation | Stdout | Side-effect | Used by `/harness` boundary |
|---|---|---|---|
| `entropy-cadence delivered` | `count=<n>` | increment + write state; fail-open (stderr note, exit 0) | Step 1: once per delivered task |
| `entropy-cadence check` | `DUE` or `NOT-DUE` | none (read-only); fail-open → `NOT-DUE` | Step 2: plain form, **no** `--first-of-session` (AC-3) |
| `entropy-cadence swept` | `reset` | reset count=0 + stamp last_sweep; fail-open | Step 5: once after the section is written |

Due logic (single-sourced in the script, NOT restated at this boundary): `N=5`; `due = (count >= N) OR (first_of_session AND count >= 1)`. Because `/harness` passes no `--first-of-session`, only the counter arm can fire (boundary condition: first few isolated deliveries stay below N → `NOT-DUE`, confirmed in RA §4).

The supervisor entropy-mode dispatch contract (scan methodology + artifact schema + the `Entropy-verdict: FINDINGS-PRESENT | CLEAN` machine-readable last line) is single-sourced in `skills/harness-deflate/references/entropy-scan.md` and is **referenced, not restated** — identical to the stream and `/harness-deflate`.

---

## 6. The exact additive text (the wiring contract)

### 6a. `agents/pm-orchestrator.md` — appended INSIDE "What to write at delivery (stage 7)"

Insert the following subsection AFTER the existing "Then update `docs/tasks.md` … Then run `.harness/scripts/archive-task …`" paragraph (current last paragraph of the stage-7 section, around L193-194) and BEFORE the "## When to stop and ask the user" heading. Verbatim:

```markdown
### Entropy watch at delivery (cadenced, non-blocking — full mode only)

After the delivery is composed and BEFORE `archive-task`, run the shared anti-entropy
cadence so a due holistic sweep surfaces on the same boundary. **This fires only when the
task `mode` is `full` (the `/harness` single-task delivery). For `goal` mode, SKIP this
entire subsection** — goal mode's iterative 4⇄6 loop reaches stage 7 too, but the
single-task delivery surface is `full`-only this slice (the stream covers its own boundary).
It is **non-blocking and fail-open**: it never changes the delivery verdict, never gates or
halts, and any cadence I/O problem resolves to not-due. The cadence due-logic + threshold
live in ONE place — the shared `.harness/scripts/entropy-cadence` pair (the same unit
`/harness-stream` and `/harness-deflate` use).

1. **Increment.** Call `.harness/scripts/entropy-cadence delivered` (one increment per
   delivered single task — only a task that actually reached DELIVERED counts).
2. **Check cadence.** Call `.harness/scripts/entropy-cadence check` — the **plain counter
   form, WITHOUT `--first-of-session`** (that flag is the stream's drain-boundary trigger;
   a single-task `/harness` run has no session-drain semantics). Read the one-line stdout:
   - **`NOT-DUE`** (or any error / missing output — fail-open) → done: **no scan, no
     `## Entropy watch` section, no entropy digest**. The delivery proceeds unchanged.
   - **`DUE`** → continue.
3. **Run the scan once.** Dispatch `harness-kit:supervisor` via the `Task` tool **in entropy
   mode** — the dispatch prompt names: "entropy lens / EP-* / follow
   `skills/harness-deflate/references/entropy-scan.md` exactly / write
   `docs/features/_supervision/entropy-<ISO-date>.md`". The supervisor is observer-only and
   writes exactly one artifact. Run the scan once per `DUE` verdict.
4. **Append the section.** Read the artifact's machine-readable last line
   `Entropy-verdict: FINDINGS-PRESENT | CLEAN` and append a `## Entropy watch` section to
   `07_DELIVERY.md`: the findings table (or `None.` when `CLEAN`), a link to the entropy
   artifact, and a note that deepening a finding is opt-in via `/harness-deflate`
   (authorize → `/harness-goal`). The `/harness` delivery itself **never** runs a refactor.
   If the scan produced no readable artifact, **omit the section** but still proceed to
   step 5 (non-blocking — never wedge the boundary).
5. **Reset the cadence.** Call `.harness/scripts/entropy-cadence swept` (resets the counter
   to 0 and stamps last-sweep, so the same delivery boundary does not re-trigger).
```

This is the SAME surfacing shape as the stream's `### Entropy watch (cadenced, non-blocking)` block in `skills/harness-stream/SKILL.md` (L162-175) — mirrored, not forked. The two deliberately differ in exactly the documented ways: the `/harness` home uses the plain `check` (no `--first-of-session`), writes to `07_DELIVERY.md` (not `STREAM_REPORT.md`), and has no needs-input ordering constraint. The scan dispatch (methodology + artifact schema) points at the SAME `references/entropy-scan.md` — no second scan description is created.

Note on placement vs. existing step 10: the existing "How to start a task" step 10 already calls `archive-task` "after the final stage". This subsection runs **before** `archive-task` so the `## Entropy watch` section is present in `07_DELIVERY.md` at the moment `archive-task` moves the doc to `_archived/`. The Developer must keep the ordering: compose 07_DELIVERY → entropy watch (this subsection) → update tasks.md → archive-task.

### 6b. `skills/harness/SKILL.md` — ONE referencing line at step 10

Replace the existing step 10 line (L40) text:

> 10. **Write `07_DELIVERY.md`** (PM does this directly): summary + verify_all output + any `## Insight` section if the task surfaced non-obvious project truths.

with (the only change is the appended trailing clause — no duplicated prose):

> 10. **Write `07_DELIVERY.md`** (PM does this directly): summary + verify_all output + any `## Insight` section if the task surfaced non-obvious project truths. At this delivery boundary the PM also runs the cadenced, non-blocking entropy watch (full mode only) — see `agents/pm-orchestrator.md` → "Entropy watch at delivery". *(referencing line only — the call-sequence and section-format live there, not here)*

This satisfies in-scope #8 / AC-5: one authoritative home, one pointer, zero divergent copy.

### 6c. `CHANGELOG.md` — new `## [0.42.0]` section above L8

Add above the existing `## [0.41.0] - 2026-06-20` heading. Suggested body (Developer may tighten wording; the heading token `[0.42.0]` and the unchanged-count claims are load-bearing for G.4):

```markdown
## [0.42.0] - <date>

### Added — entropy-watch-harness (T-11b): the `/harness` single-task delivery surface

The cadenced anti-entropy watch now also fires from `/harness` (single-task), not only
`/harness-stream` — completing "auto-periodic inspection in both harness and harness-stream".

- **`/harness` delivery surface.** At the stage-7 delivery boundary, the PM Orchestrator
  increments the shared cadence (`entropy-cadence delivered`), checks the **plain** counter
  (`entropy-cadence check`, no `--first-of-session`), and on `DUE` runs the supervisor entropy
  lens once + appends a `## Entropy watch` section to `07_DELIVERY.md` + resets (`swept`).
  Non-blocking and fail-open — never changes the delivery verdict, never gates or halts.
  **Full mode only**; `goal` mode (which also exits at stage 7) is explicitly excluded this slice.
- **Pure wiring / DRY.** Reuses the T-11a core unchanged — the `entropy-cadence.{ps1,sh}` pair,
  the supervisor entropy lens, and `references/entropy-scan.md`. The call-sequence + section
  format live in ONE home (`agents/pm-orchestrator.md` stage 7); `skills/harness/SKILL.md`
  step 10 carries a single referencing line. No new script, skill, or state file.
- **Unified counter.** `/harness` and `/harness-stream` share the same
  `.harness/entropy-watch.state` — a delivery via either advances the counter; a sweep via
  either resets it.
- **No count flip.** Skills 17, agents 8, `verify_all` 32 checks all unchanged (no new gate).
  Version 0.41.0 → 0.42.0 (plugin.json, marketplace.json, both README badges).
```

---

## 7. Sequence / flow

```
/harness single task → … → stage 6 (QA) PASS → stage 7 (PM, mode=full)
  │
  ├─ compose 07_DELIVERY.md (summary + verify_all + optional ## Insight)
  │
  ├─ [Entropy watch at delivery — §6a]
  │     mode == full ? ──no(goal)──▶ skip entirely (delivery unchanged)
  │       │ yes
  │       ├─ entropy-cadence delivered           (count++; shared state; fail-open)
  │       ├─ entropy-cadence check  (plain)       → DUE | NOT-DUE | (error⇒NOT-DUE)
  │       │     NOT-DUE ─────────────────────────▶ done (no scan, no section)
  │       │     DUE
  │       ├─ Task → harness-kit:supervisor (entropy mode, references/entropy-scan.md)
  │       │           writes docs/features/_supervision/entropy-<ISO>.md
  │       ├─ read Entropy-verdict line → append ## Entropy watch to 07_DELIVERY.md
  │       │     (findings table | None. + artifact link + /harness-deflate opt-in note;
  │       │      missing artifact ⇒ omit section, still continue)
  │       └─ entropy-cadence swept                (count=0 + stamp; fail-open)
  │
  ├─ update docs/tasks.md (stage: done)
  ├─ run verify_all (must PASS — unchanged gate)
  └─ run archive-task --task <slug>  (moves 07_DELIVERY.md, incl. ## Entropy watch, to _archived/)
```

Every entropy-watch step is non-blocking: the delivery verdict and the existing hard gates (stage-3 gate, stage-5/6 pass-before-delivery, `verify_all` PASS-before-done, `guard-rm`) are untouched (NFR-1, AC-4).

---

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Cadence due-logic + threshold (N=5) + state I/O | `entropy-cadence` pair (`check`/`delivered`/`swept`, fail-open) | `.harness/scripts/entropy-cadence.{ps1,sh}` | **Reuse as-is** — call the same CLI; do NOT re-implement or restate the threshold |
| Shared deliveries-since-sweep counter | `.harness/entropy-watch.state` (key=value) | `.harness/entropy-watch.state` | **Reuse as-is** — the same single file both surfaces read/write (AC-7) |
| Holistic structural scan (EP-* methodology + artifact schema + verdict line) | supervisor entropy lens + scan reference | `agents/supervisor.md` + `skills/harness-deflate/references/entropy-scan.md` | **Reuse as-is** — dispatch in entropy mode; reference the scan source, never restate it |
| `## Entropy watch` surfacing shape (findings table / `None.` + artifact link + `/harness-deflate` opt-in note) | stream's `### Entropy watch (cadenced, non-blocking)` block | `skills/harness-stream/SKILL.md` L162-175 | **Mirror the shape** in the `/harness` home; NOT verbatim-reusable (it is bound to `STREAM_REPORT.md`, needs-input ordering, and `--first-of-session`) — RA §6 |
| Delivery mechanics this extends (07_DELIVERY, tasks.md, archive-task) | stage-7 delivery block | `agents/pm-orchestrator.md` "What to write at delivery (stage 7)" | **Extend in place** — the authoritative home for the new prose |
| Version-stamp + count-claim consistency enforcement | G.3 (4 stamps) + G.4 (latest CHANGELOG + counts) | `.harness/scripts/verify_all.{sh,ps1}` (G.3 L350/L332; G.4 L686/L624) | **Reuse as-is** — no edit; the stamps/CHANGELOG are updated to satisfy them |

The reuse audit is non-empty and proves this slice adds **no new script, skill, state, or scan description** — exactly the INPUT's "pure WIRING" mandate.

---

## 9. Risk analysis

1. **Risk: the entropy watch accidentally fires for `goal` mode** (both `full` and `goal` exit at pm-orchestrator stage 7 — OQ-3). → **Mitigation:** the §6a subsection opens with an explicit mode guard — "This fires only when the task `mode` is `full` … For `goal` mode, SKIP this entire subsection." The guard is the first sentence, not a buried caveat, so it cannot be missed. See §10 boundary decision.
2. **Risk: DRY violation — a second divergent copy of the call-sequence/section prose drifts into `skills/harness/SKILL.md`.** → **Mitigation:** §6b is a single referencing line with an inline `(referencing line only …)` reminder; AC-5 is grep-verifiable (the 3-step sequence + section-format prose appear exactly once). The scan description is referenced from `references/entropy-scan.md`, never restated.
3. **Risk: a `DUE` scan that produces no readable artifact wedges the boundary or blocks delivery.** → **Mitigation:** §6a step 4 omits the section but still runs step 5 (`swept`); the whole subsection is non-blocking/fail-open (NFR-1, RA §4 degraded path = OQ-4 (a)). The delivery verdict is unchanged.
4. **Risk: count flip — touching distributed skill/agent content trips C.1/G.1/G.2 ("17 skills") or adds a check.** → **Mitigation:** no skill/agent file is added or removed (8 agents, 17 skills unchanged); no `verify_all` check is added (G.4 must stay last — untouched). The count claims in README/CHANGELOG are NOT edited. AC-6 grep-verifies 17/8/32 unchanged.
5. **Risk: I.3 size cap — pm-orchestrator.md grows past 300 lines.** → **Mitigation:** current file is 209 lines (read this session); the §6a addition is ~30 lines → ~239, well under 300. AC-6 / NFR-3.
6. **Risk: G.4 fails because the new CHANGELOG heading or version stamps are inconsistent.** → **Mitigation:** all 4 G.3 stamps move together to `0.42.0` (plugin.json L4, marketplace.json L17, README.md L5, README.zh-CN.md L5); CHANGELOG gets the `## [0.42.0]` heading above `[0.41.0]` with count claims left unflipped. `verify_all` PASS is the declare-done gate.

---

## 10. Goal-mode boundary decision (OQ-3 — made unambiguous)

**Decision: the entropy watch at delivery fires for `full` mode ONLY; `goal` mode is explicitly guarded OUT.** (OQ-3 recommended answer (a), accepted.)

Rationale and why it cannot accidentally fire (or not fire):
- pm-orchestrator stage 7 is reached by BOTH `full` (the `/harness` single-task delivery) and `goal` (the 4⇄6 loop's terminal delivery). Because the home is the shared stage-7 block, a naive addition WOULD fire for both. The design therefore makes the guard the **first sentence** of the §6a subsection: "This fires only when the task `mode` is `full` … For `goal` mode, SKIP this entire subsection."
- The PM already knows the task `mode` at stage 7 — it is recorded in `docs/tasks.md` and is the routing key the PM uses throughout (pm-orchestrator "Task modes" table). The guard reads a value the PM already holds; no new state or detection is needed.
- This keeps the slice scoped to the INPUT's "`/harness` single-task delivery surface" and matches RA in-scope #6 / out-of-scope #6 ("Wiring the surface into the lighter modes … is out of scope"). A future task can opt `goal` in by reference — the home already exists, so no re-homing is required (the cost of deferral is one sentence change).
- The guard is symmetric with the stream: the stream surface fires only on a `/harness-stream` drain boundary; the `/harness` surface fires only on a `full` single-task delivery. `goal` mode has neither a drain boundary nor a single-task delivery semantics, so excluding it is consistent, not a special case.

There is no ambiguity left: a `goal`-mode stage-7 exit hits the first guard sentence and skips the entire subsection; a `full`-mode exit does not.

---

## 11. Migration / rollout plan

- **Backwards compatibility:** fully additive. A `/harness` run on a fresh/low counter behaves identically to today (no scan, no section — AC-1). Existing stream behavior is untouched (RA out-of-scope #7). The shared state file format is unchanged.
- **No feature flag needed:** the cadence is self-gating (counter below N → `NOT-DUE`), and the mode guard scopes it to `full`. There is nothing to flip on/off.
- **Data migration:** none. The state file is created lazily by `entropy-cadence delivered` (fail-open if no repo root).
- **Version bump sequence (do together so G.3/G.4 stay consistent):**
  1. `plugin.json` L4 `version` `0.41.0` → `0.42.0`.
  2. `marketplace.json` L17 `plugins[0].version` `0.41.0` → `0.42.0`.
  3. `README.md` L5 badge token `version-0.41.0-blue` → `version-0.42.0-blue` (token only — do NOT touch the frozen version-history table decoy region).
  4. `README.zh-CN.md` L5 badge token likewise.
  5. `CHANGELOG.md` add `## [0.42.0] - <date>` above `## [0.41.0]` (§6c), counts NOT flipped.
- **Rollback:** revert the 7 edited files. No data or schema to undo (the state file is shared and pre-existing).
- **Declare-done gate:** `.harness/scripts/verify_all` must PASS 32/32 on both shells (PS side may be operator-pending per the harness's known PS-denied-to-sub-agents constraint, same as T-11a's delivery).

---

## 12. Verdict

**READY.** The slice is pure wiring + version stamps over the T-11a core. The authoritative DRY home is `agents/pm-orchestrator.md` stage 7 (exact text in §6a); `skills/harness/SKILL.md` step 10 gets one referencing line (§6b). The boundary uses the plain `check` (no `--first-of-session`, AC-3); non-blocking and fail-open throughout (NFR-1, AC-4). The `goal`-mode boundary is explicitly guarded OUT and made unambiguous (§10). Version `0.41.0` → `0.42.0` via 4 G.3 stamps + a `## [0.42.0]` CHANGELOG section (§6c). Confirmed: **no count flip** (17 skills / 8 agents / 32 checks unchanged), **no new `verify_all` check** (G.4 stays last, untouched), **DRY** (one home + one pointer, scan single-sourced), and pm-orchestrator.md stays **≤300** (209 → ~239, I.3). This project uses single-Developer mode (no `.harness/agents/dev-*.md`), so the Partition assignment section is omitted.

### Out-of-scope clarifications (design boundaries)

This design does NOT: add a scan engine / skill / state file (all reused); change the cadence formula, threshold (N=5), or fail-open contract; use `--first-of-session`; wire the surface into `/harness-plan` / `/harness-explore` / `/harness-goal` / `/harness-batch`; touch the stream's existing T-11a block; add findings persistence / decline-tracking (T-11c); add or alter any `verify_all` check; or flip the 17/8/32 count claims.
