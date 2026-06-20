# 01 — Requirement Analysis · T-09 `rejected-decisions-memory`

**Mode:** full · **Decision mode:** Mode 2 (preset-rubric autonomy) · **Human-input mode:** deferred-human (defer, do not ask — every ambiguity carries a recommended resolution and the verdict is not blocked on it).

---

## 1. Goal

Give the harness-kit repo one consistently-located, lightweight memory of "we deliberately decided NOT to do X, and why," so a future session re-proposing an already-rejected request or approach surfaces the prior decision instead of re-litigating it.

---

## 2. The lighter-fit decision (file vs convention) — resolved

The task asks the analyst to make the file-vs-convention choice testable. Resolved here, grounded in the live repo, because the rest of the requirement depends on it.

**Decision: a single dedicated memory FILE (option a), in its lightest form — `.harness/rejected-decisions.md`, NOT a per-concept directory, NOT a new always-loaded file, NOT a new gate.**

Reasoning grounded in the live memory layer:

1. **The repo's memory layer is a set of named, single-purpose files, each indexed once in AI-GUIDE and read on a trigger** — not a set of conventions scattered across host docs. The live layer is: `.harness/insight-index.md` (≤30 hard-won truths), `.harness/decision-rubric.md` (autonomy principles), `CONTEXT.md` (domain glossary). A rejected-decisions memory is a genuinely DISTINCT fourth kind of content (declined options + why), so it matches the layer's existing shape: one more named file, one more AI-GUIDE line, one trigger. A convention (option b) would be the only memory artifact with no home of its own — it would have to live as a heading inside an unrelated rule fragment (`15-skill-authoring.md`), which is exactly the ad-hoc state this task exists to fix.

2. **The convention already exists and has already failed at its one job.** `15-skill-authoring.md` has a "Deliberately not adopted" section. It is invisible to anyone not editing skills: a future session deciding NOT to add an issue-tracker has no reason to load the skill-authoring rule, so the convention does not get read at the decide-point. Formalizing the heading (option b) does not fix the read-at-decide gap; only a file indexed at the memory layer and pointed at from a decision trigger does.

3. **A single file beats mattpocock's per-concept directory for this repo's scale.** mattpocock's `.out-of-scope/` is one-file-per-concept tuned to an issue-tracker with many requests per concept and automated dedup. This repo has no issue tracker (out of scope per INPUT) and a handful of declines total — a per-concept directory is sediment. One append-only file with one short record per declined concept carries the same institutional-memory + dedup value at a fraction of the surface. (Honors token economy and `feedback_lightweight`.)

4. **It costs almost nothing per task.** It is read ONLY at a decide-point (not always-loaded like AI-GUIDE), and written ONLY when something is deliberately declined. Between those moments it is zero context tax. This is strictly lighter than any always-resident mechanism and is the same load profile as `decision-rubric.md`.

Why NOT the lighter-looking option (b) convention, stated plainly so it is not re-proposed: a convention with no file is cheaper to ship but does not deliver the read-at-decide habit (point 2) and leaves the memory layer asymmetric (point 1). The genuine value here is a discoverable, decide-point-triggered record; only a file delivers it. This is the smallest thing that meets the bar, not over-engineering.

---

## 3. In-scope behaviors (numbered, testable)

1. A new file `.harness/rejected-decisions.md` exists in the repo (dogfood copy with this project's real content).
2. The file opens with a header that states, in ≤6 lines: what it is (deliberately-declined options + why), when to read it (at a non-trivial decide-point, before proposing a new approach/feature), when to append (when something is deliberately declined — a real rejection, not a deferral), and a pointer to `.harness/rules/05-insight-index.md` and `.harness/rules/25-decision-policy.md` as siblings (so the four memory kinds are cross-referenced).
3. Each record in the file is a short entry (target ≤ ~8 lines) with these fields: concept name (kebab-case-style short handle), the decision (one line: declined / deferred), why it is out of scope (substantive — references project scope, a technical constraint, or a strategic choice; not "we don't want it"), and prior request(s) / origin task.
4. The file distinguishes a **rejection** (durable: declined on principle) from a **deferral** (a "not now," e.g. design-it-twice) — a deferral is recorded with an explicit `deferred` marker so it is not mistaken for a permanent rejection.
5. The file is seeded with this batch's genuine declines as initial records: at minimum `design-it-twice` (deferred), `ask-matt-router` (declined — AI-GUIDE workflow table already routes), `issue-tracker-dedup` / `to-prd` / `triage` (declined — no issue tracker, too heavy), `skill-usage-telemetry` (declined — existing "Deliberately not adopted" entry, migrated/cross-referenced), and the non-fit skill family (`teach` / `handoff` / `writing-*` / `personal`, `git-guardrails` / `setup-pre-commit`, `tdd` / `diagnosing-bugs`).
6. The existing `15-skill-authoring.md` "Deliberately not adopted" → skill-usage-telemetry entry is reconciled with the new file: the telemetry decision is represented in `.harness/rejected-decisions.md` (single source of the declined-options memory), and `15-skill-authoring.md` either keeps a one-line pointer to it or is left intact — the two are not contradictory and the telemetry rationale is not duplicated verbatim in two places that can drift.
7. A generic, placeholder-free seed of the file ships in the distribution at `skills/harness-init/templates/common/.harness/rejected-decisions.md` (template seed = generic example/empty-with-header; dogfood = real content), following the `decision-rubric.md` / `CONTEXT.md` dual-purpose pattern (NOT byte-synced by `sync-self`).
8. `AI-GUIDE.md` indexes the file with exactly ONE terse line in the "Memory layer" block, alongside the existing three memory-layer entries, naming it as the fourth distinct kind (declined options + why) and stating its read/append trigger.
9. `docs/dev-map.md` gains one row locating the new file (where-does-X-live lookup), consistent with how the other memory-layer files are listed.
10. The read-at-decide / append-on-decline habit is wired into the decision layer as the single source: `.harness/rules/25-decision-policy.md` (the rule loaded precisely at a decide/escalate point) references reading `.harness/rejected-decisions.md` at a decide-point and appending to it when a request/approach is deliberately declined. Agents that already read the memory layer at decision time (requirement-analyst step 7, solution-architect step 5 — the CONTEXT.md soft-read sites) gain a one-line soft-read pointer to it; the habit is single-sourced in the decision policy and referenced (not restated) elsewhere, per the T-05 single-source-the-boundary insight.
11. The new file's records use behavioral / conceptual prose; any backward-looking origin citation (e.g. "origin: T-09 batch") is an evidence-style reference and is permitted (the forward/backward boundary of T-05's durability rule).

---

## 4. Out-of-scope (explicitly NOT this iteration)

1. A per-concept directory (`.out-of-scope/` style, one file per concept) — a single append-only file suffices at this repo's scale.
2. Any new `verify_all` check / gate / hook for this file — it is memory, not a gate (`feedback_design_over_guards`); no size guard, no presence guard, no content guard.
3. mattpocock's issue-tracker dedup automation and any auto-matching machinery (concept-similarity matching, "surface the prior decision" automation) — the repo has no issue tracker; matching is done by a human/agent reading the file.
4. Overloading `.harness/insight-index.md` with declined-options content — insight-index stays ≤30 hard-won TRUTHS; rejected-decisions is a separate file.
5. A hard size cap enforced by a gate. (Soft self-discipline only — see boundary conditions; resolved in OQ-2.)
6. Re-opening / reversing past decisions automatically — removing or revising a record is a manual human act.
7. Migrating the non-fit declines of OTHER future batches; this iteration seeds only the mattpocock-batch declines named in the INPUT.
8. A skill-count or check-count flip (15 skills / 32 checks are unchanged by this task).

---

## 5. Boundary conditions

- **File absent (generated or upgraded project that predates this feature):** every consumer (AI-GUIDE pointer, decision-policy reference, RA/SA soft-read) treats the file as a SOFT dependency — read-if-present, degrade gracefully, never BLOCK, no setup pointer (the `CONTEXT.md` soft-dependency model, T-02). A decide-point with no file proceeds normally.
- **Empty file (header only, no records):** valid state — a fresh project has declined nothing yet. The template seed ships in exactly this state (header + a single illustrative/empty example, no real declines).
- **Duplicate concept on append:** appending a concept that already has a record adds the new origin to that record's prior-requests line rather than creating a second record (one record per concept).
- **Deferral vs rejection ambiguity:** if it is unclear whether something is a permanent rejection or a "not now," it is recorded as `deferred` (the safer marker — a deferral re-surfaced and re-decided is correct; a deferral mis-recorded as a permanent rejection would wrongly suppress a future good idea).
- **I.6 retired-claim self-trip:** the file and its records describe DECLINED options; phrase records so they do not reproduce any I.6 banned-anchor sequence (the same hazard that bit T-013's archive). No record may quote a retired-claim anchor verbatim.
- **Cross-shell / encoding:** the file is plain Markdown, UTF-8, no script generates it at runtime, so there is no cross-shell parity surface. (If any record contains CJK, save UTF-8 — same discipline as every other repo doc.)
- **Max size:** soft target only (see OQ-2). No gate fires at any size; the file rotates/compacts by human discipline if it ever grows large, the way `docs/tasks.md` rotation is manual.

---

## 6. Acceptance criteria (verifiable)

1. `.harness/rejected-decisions.md` exists with the header described in behavior #2 (≤6 header lines, states what/when-read/when-append + sibling pointers).
2. The file contains the seed records named in behavior #5, each with the four fields of behavior #3, and each rejection/deferral correctly marked per behavior #4. **Verify:** read the file; each named decline is present with a substantive `why`.
3. `skills/harness-init/templates/common/.harness/rejected-decisions.md` exists, is placeholder-free (passes `test-init`'s no-unresolved-`{{...}}` scan), contains a generic header + empty/illustrative body (no harness-kit-specific real declines), and is NOT in `sync-self`'s byte-mirror set. **Verify:** grep the seed for `{{`; confirm it is absent from `sync-self` mirror list; confirm `sync-self` reports no drift after this change.
4. `AI-GUIDE.md` has exactly one new line in the Memory-layer block naming the file as the fourth memory kind with its trigger, and AI-GUIDE stays ≤200 lines (I.1). **Verify:** AI-GUIDE line count ≤200; the line is present and singular.
5. `docs/dev-map.md` has one row locating the file. **Verify:** the row resolves to the real path.
6. `.harness/rules/25-decision-policy.md` references reading/appending the file at a decide-point (single source of the habit), and requirement-analyst + solution-architect each carry a one-line soft-read pointer to it at their existing memory-read step — the habit text is single-sourced (decision policy) and referenced, not restated, elsewhere. **Verify:** grep the four files; the read/append rule prose appears in exactly one canonical place; the others point to it by name. Rule 25 stays ≤200 lines.
7. No new `verify_all` check is added (count stays 32) and no new hook is added. **Verify:** `verify_all` check count is 32 before and after; `git diff` shows no new check block.
8. The skill-usage-telemetry decision is not duplicated as two divergent rationales: it lives in `.harness/rejected-decisions.md`, and `15-skill-authoring.md` either points to it or is left unchanged without a contradicting second copy. **Verify:** the two files do not state two different reasons for the telemetry decline.
9. `.harness/scripts/verify_all` PASSes (32/32) after the change, with no new WARN attributable to this task. **Verify:** run verify_all both shells (PS may be operator-pending per the deny rule).
10. No I.6 self-trip: the new file, its records, and any harvested insight at delivery contain no I.6 banned-anchor sequence. **Verify:** `verify_all` I.6 group PASSes including the new file in scope.
11. Version is bumped (distributed change — a new template asset ships into generated projects + agent/rule edits); the bump is a normal MINOR with NO count flip (15/32 unchanged). **Verify:** `plugin.json` version increments by one minor; `verify_all` G.4 (claim↔version consistency) PASSes; no count claim changes anywhere.

---

## 7. Non-functional requirements

- **Token economy (material):** the file must be cheap — read only at a decide-point, written only on a decline, zero always-on load. Records stay terse (behavior #3); the file is a single doc, not a directory. This is the whole point of choosing the lightest form.
- **Memory-layer distinctness (material):** the four memory kinds (insight-index = truths, decision-rubric = autonomy principles, CONTEXT.md = glossary, rejected-decisions = declined options) stay non-overlapping; no content that belongs in one is duplicated into another. The AI-GUIDE line states the distinction in one phrase so the boundary does not blur.
- **Distribution parity:** the template seed is generic and placeholder-free so every newly-init'd project gets the mechanism empty-but-ready, the same way CONTEXT.md and decision-rubric.md ship.
- **No gate / no guard:** consistent with `feedback_design_over_guards` — the mechanism's value comes from being read, not from being enforced. No `verify_all` check, no hook, no hard size cap.

---

## 8. Related tasks

- **T-02 `context-glossary`** (`docs/features/_archived/context-glossary/`) — the directly-reusable precedent: a new memory-layer file (`CONTEXT.md`) shipped as dogfood + generic non-byte-synced template seed, wired as a SOFT dependency into requirement-analyst + solution-architect (read-if-present, lazy-maintain, graceful-degrade), AI-GUIDE memory-layer index line, dev-map row, no new verify_all check. This task follows the same blueprint for the fourth memory kind.
- **T-04 `skill-authoring-vocab`** / `15-skill-authoring.md` "Deliberately not adopted" — the existing ad-hoc practice this task generalizes; the telemetry decline migrates/cross-references from here.
- **T-05 `durable-brief`** (`docs/features/_archived/durable-brief/`) — source of the forward-only / backward-evidence boundary that governs how records cite origins (behavior #11), and of the single-source-the-rule-in-one-agent discipline applied to wiring the habit (behavior #10).
- **T-016 `i18n-special-drift-guard`** — precedent for eliminating a problem class by design rather than adding a verify_all check (no count flip); the basis for the no-new-guard stance here.
- **T-013 `lang-policy-split`** — source of the I.6 self-trip hazard (a memory/insight doc quoting a retired-claim anchor) honored in boundary conditions and AC-10.
- **Reference (read-only):** `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\OUT-OF-SCOPE.md` — the `.out-of-scope/` KB this generalizes (one-file-per-concept, why-out-of-scope, prior-requests, check-during-triage, when-to-write); adopted in single-file form for this repo's scale.

---

## 9. Open questions (deferred-human mode — recommended resolution given, not blocking)

1. **File location.** (a) `.harness/rejected-decisions.md` (sits with the other `.harness/` memory-layer siblings insight-index + decision-rubric); (b) `docs/decisions/rejected.md` (a new docs subtree). **Recommended: (a)** — it co-locates with the existing memory layer that AI-GUIDE already groups, needs no new directory, and matches "the four memory kinds live together." Basis: rubric "match existing conventions" + lightweight.

2. **Soft size discipline.** (a) no size discipline at all; (b) a soft, documented self-discipline note in the file header (e.g. "if this grows past ~1 screen of records, compact merged/obsolete ones") with NO gate; (c) a `verify_all` cap. **Recommended: (b)** — a one-line soft note costs nothing, mirrors the `docs/tasks.md` manual-rotation discipline, and explicitly avoids a gate. (c) is out of scope (`feedback_design_over_guards`). Basis: rubric "design out the root cause; don't accrete guards."

3. **Where the read/append habit is single-sourced.** (a) `.harness/rules/25-decision-policy.md` (the rule loaded exactly at a decide-point) as the canonical source, with RA/SA carrying one-line pointers; (b) requirement-analyst as canonical (like T-05's durability rule); (c) a brand-new rule fragment. **Recommended: (a)** — the decide-point is precisely when the policy rule loads, so the read-at-decide habit belongs there and reaches every decide-point (not just the RA stage); RA/SA reference it. (c) adds a rule fragment for one habit — sediment. Basis: rubric "lightweight" + T-05 single-source discipline.

4. **Fate of the existing `15-skill-authoring.md` telemetry entry.** (a) replace it with a one-line pointer to the new file (single source of declined-options memory); (b) leave it in place and ALSO record telemetry in the new file (two locations, drift risk); (c) move it and leave nothing. **Recommended: (a)** — single source of truth; the skill-authoring rule keeps a one-line pointer so a skill author still finds it, but the rationale lives once in the rejected-decisions file. Basis: SSOT (rule 15) + no-duplication.

5. **Version bump size.** (a) MINOR (e.g. v0.39.0 → v0.40.0) — a new distributed template asset + agent/rule edits are user-visible distributed surface; (b) PATCH — treat as dogfood-only. **Recommended: (a) MINOR, no count flip** — the template seed ships into every generated project (distributed change), so it is version-worthy as a feature, exactly like T-02 (CONTEXT.md) bumped a minor; the 15/32 counts do NOT change. Basis: T-008 count↔version insight (this is a version-worthy distributed change but NOT a count change). PM/operator confirms the exact number from current `plugin.json`.

(All five are resolved with a recommendation; none blocks. Under deferred-human mode the pipeline proceeds on the recommended answers and the operator reviews after.)

---

## Verdict

**READY.** Decision-mode-2 autonomy plus deferred-human mode: the file-vs-convention call is resolved (single dedicated file, lightest form), seeding is specified, the read/append habit's wiring is specified, no new guard, memory-layer distinctness preserved, version bump confirmed as MINOR with no count flip. All open questions carry a recommended resolution and none is a blocking ambiguity. Proceed to Solution Architecture.
