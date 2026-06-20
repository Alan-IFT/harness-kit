# 01 — Requirement Analysis · sa-design-vocab (T-07)

**Mode:** full · **Stage:** 1 (Requirement Analyst) · **deferred-human mode:** defer, do not ask.
**Date:** 2026-06-20 · **Verdict:** see §9.

---

## 1. Goal

Add an OPTIONAL deep-module design-language section to the `solution-architect` agent so the
architect has named handles (module, interface, depth, seam, adapter, leverage, locality), the
deletion test, "the interface is the test surface", and "one adapter = hypothetical seam, two =
real" available as a LENS when designing module boundaries — terse and additive, never a mandatory
step in every design.

---

## 2. In-scope behaviors

Each item is numbered and testable.

1. The agent file `agents/solution-architect.md` gains exactly one new design-language section
   (one new top-level `##` heading) introducing the seven-term deep-module vocabulary: **module**,
   **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**. Each term appears
   with a one-line meaning (not a paragraph each).

2. The new section states the **deletion test** in one line: imagine deleting the module — if
   complexity vanishes it was a pass-through; if complexity reappears across N callers it earned
   its keep.

3. The new section states **"the interface is the test surface"** (callers and tests cross the
   same seam) in one line.

4. The new section states **"one adapter means a hypothetical seam, two means a real one"**
   (do not introduce a seam unless something actually varies across it) in one line.

5. The new section is framed as an **optional lens the architect MAY reach for** when designing or
   improving module boundaries — the text contains an explicit affordance word ("may" / "optional"
   / "when designing module boundaries, you can reach for…") and contains NO mandate word
   ("must use these terms in every design" / "required section in `02_SOLUTION_DESIGN.md`"). The
   `02_SOLUTION_DESIGN.md` output structure (sections 1-12) is unchanged: no new required output
   section is added.

6. The interface term is defined as **everything a caller must know** (type signature plus
   invariants, ordering constraints, error modes, required config, performance characteristics) —
   not merely the type-level signature. (This is the load-bearing distinction that makes the
   vocabulary worth adopting.)

7. The design-it-twice parallel-subagent pattern is **NOT introduced as a usable instruction**. At
   most a single line names it as a deferred future option (zero or one line; no procedure, no
   sub-agent dispatch shape).

8. The DEEPENING dependency-category taxonomy (in-process / local-substitutable / remote-owned /
   true-external) is **NOT reproduced**. At most a single pointer line states that finer dependency
   categories exist as a future extension (zero or one line).

9. The edit is **additive**: every pre-existing line of `agents/solution-architect.md` that is not
   part of the new section remains byte-for-byte unchanged (no rewrite of the existing contract,
   Hard rules, Workflow, Mode-specific note, Reuse-audit format, or Partition-assignment format).
   The new section may be inserted at one location; no existing section is deleted, reordered, or
   reworded.

10. The new section is **terse**: after the edit, `agents/solution-architect.md` total line count is
    ≤300 (the I.3 agent cap). Starting point is 123 lines; the section is expected to add roughly
    15-25 lines.

11. The change ships a **version bump** from 0.37.0 to **0.38.0** applied consistently across all
    version-claim surfaces: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, the
    `README.md` version badge, the `README.zh-CN.md` version badge, and a new dated
    `## [0.38.0]` CHANGELOG entry. (Editing a plugin-native distributed agent is a shipped change;
    `verify_all` G.4 gates version-claim ↔ `plugin.json` consistency.)

12. The new CHANGELOG `## [0.38.0]` entry explicitly records: **no count change** — 16 skills /
    8 framework agents / 32 checks stay (content edit, not a count edit) — and **no new `verify_all`
    check** and **no I.6 banned/exempt-list change**.

13. The vocabulary terms are presented as **leading words** (compact, reusable handles the architect
    thinks WITH), consistent with rule 15's "leading word" guidance and rule 15 P4 ("don't
    railroad") — i.e. they anchor a region of design thinking, they are not a checklist the
    architect must tick off.

---

## 3. Out-of-scope (explicitly NOT done this iteration)

1. The **design-it-twice** parallel-subagent pattern (spinning up parallel sub-agents to design an
   interface several ways, then comparing). Deferred; named only (see in-scope #7).
2. The full **DEEPENING dependency-category taxonomy** (the four categories + ports & adapters +
   replace-don't-layer testing). Pointer-only (see in-scope #8).
3. Any change to the `02_SOLUTION_DESIGN.md` output structure (sections 1-12) — the vocabulary is a
   lens, not a new required output field.
4. Any **mandate** that the architect use the vocabulary in every design (no railroading).
5. Any new `verify_all` check, gate, or guard for this content.
6. Any change to skill/agent/check **counts** (16 / 8 / 32 stay).
7. Any edit to other agents (`requirement-analyst.md`, `gate-reviewer.md`, etc.) or to `CONTEXT.md`.
   The vocabulary MAY later seed `CONTEXT.md` (T-02), but that is a future option, not this task.
8. Any edit to `.harness/rules/15-skill-authoring.md` — the "leading word" handle there already
   exists (T-04); this task consumes it, it does not change it.
9. Any `harness-sync` run or `.claude/` edit — framework agents are plugin-native (edited directly
   in top-level `agents/`, no sync).

---

## 4. Boundary conditions

1. **Cap boundary.** `agents/solution-architect.md` must end ≤300 lines. Current 123 → an addition
   of more than 177 lines would breach the cap (and would not be terse). The section must stay small.
2. **Empty / no-op risk.** A section that only re-lists generic design advice the model already
   knows is a no-op (fails rule 15 P2 / the "no-op test"). The interface-is-more-than-signature
   distinction (#6) and the four named tests/principles must each say something the default model
   behavior does not.
3. **Railroad boundary.** The section must read as optional. If a reader (or the gate) can
   reasonably conclude "I now must apply these seven terms to every `02_SOLUTION_DESIGN.md`", the
   framing has failed (violates in-scope #5 and rule 15 P4).
4. **Additive boundary.** A diff that touches any existing line outside the new section (beyond the
   single insertion point and the trailing-newline mechanics) violates in-scope #9.
5. **Version-consistency boundary.** A version claim left at 0.37.0 on any one of the five surfaces
   while another reads 0.38.0 is an inconsistency `verify_all` G.4 will FAIL. All five move together.
6. **Count-claim boundary.** Any accidental edit to a "16 skills" / "8 agents" / "32 checks" claim
   is out of scope and would trip the count ledger; counts must remain literally unchanged.
7. **I.6 banned-anchor boundary.** The new text must introduce no banned retired-claim anchor and
   must not write a literal `name.ext:NNN` forward-looking path:line into the agent prose (Hard
   rule 6, forward-only — the agent contract is a forward-looking surface).
8. **Source-fidelity boundary.** Term meanings must match the reference glossary
   (`codebase-design/SKILL.md`): e.g. depth = leverage per unit of interface (NOT the
   implementation-to-interface line ratio, which the source explicitly rejects); seam = where the
   interface lives; adapter = a concrete thing satisfying an interface at a seam.

---

## 5. Acceptance criteria

Each criterion is verifiable by reading the diff, counting lines, or running the gate.

- **AC-1** `agents/solution-architect.md` contains one new `##` section that names all seven terms
  (module, interface, depth, seam, adapter, leverage, locality), each with a one-line meaning.
  *Verify:* grep the section for the seven terms.
- **AC-2** The section contains the deletion test, "the interface is the test surface", and "one
  adapter = hypothetical seam, two = real", each as a single concise line.
  *Verify:* read the section.
- **AC-3** The interface term is defined as "everything a caller must know" (broader than the type
  signature), citing at least invariants/ordering/error-modes/config as part of the interface.
  *Verify:* read the interface line.
- **AC-4** The section is framed optional: it contains an affordance word ("may"/"optional"/"a lens")
  and contains no mandate that ties the vocabulary to a required `02_SOLUTION_DESIGN.md` field.
  The 12-section output structure is byte-unchanged.
  *Verify:* read the section + diff the output-structure list (sections 1-12).
- **AC-5** No design-it-twice procedure and no DEEPENING four-category taxonomy appear; each is at
  most one deferred-pointer line.
  *Verify:* grep the section for "parallel" / the four category names — at most a pointer line.
- **AC-6** The diff is additive: no existing line of `agents/solution-architect.md` outside the new
  section is changed.
  *Verify:* `git diff` shows only insertions (plus the single insertion point's adjacency).
- **AC-7** `agents/solution-architect.md` total line count ≤300.
  *Verify:* line count of the file.
- **AC-8** Version reads 0.38.0 on all five surfaces (plugin.json, marketplace.json, README.md
  badge, README.zh-CN.md badge) with a matching dated `## [0.38.0]` CHANGELOG entry; counts stay
  16 / 8 / 32.
  *Verify:* grep each surface; run `verify_all` (G.4 version-claim consistency + count ledger).
- **AC-9** `.harness/scripts/verify_all` PASSes with all checks green and no new WARN/FAIL
  introduced by this change; the check total stays 32.
  *Verify:* run `verify_all`.

---

## 6. Non-functional requirements

1. **Terseness / context budget (material).** This is an agent loaded on every Stage-2 dispatch;
   every line is a per-dispatch context tax (rule 15 P2/P5, `70-doc-size.md`). The section must
   earn each line against the no-op test. Target add ≤~25 lines.
2. **Cross-shell parity (not material here).** No script is edited; `verify_all` PS/Bash parity is
   unaffected by this content change.
3. **Source fidelity (material).** Term meanings must not drift from the reference glossary
   (see boundary #8); a paraphrase that inverts "depth = leverage" into "depth = line ratio" would
   ship a wrong definition.

---

## 7. Related tasks

- **T-02 / context-glossary** (`docs/features/_archived/context-glossary/`) — added `CONTEXT.md`
  and the earlier additive edit to `solution-architect.md` (CONTEXT.md soft-dependency). This task
  is another additive edit on the same file; keep it additive (insight: solution-architect ~122-123
  lines now). The vocabulary terms could later seed `CONTEXT.md` — future option only.
- **T-04 / skill-authoring-vocab** (`docs/features/_archived/skill-authoring-vocab/`) — added the
  "leading word" and "no-op test" handles to rule 15. This task's terms ARE leading words; frame
  them per rule 15 P4 (don't railroad). T-04 consumed, not changed.
- **T-05 / durable-brief** (`docs/features/_archived/durable-brief/`) — established Hard rule 6
  (briefs behavioral, no forward-looking file:line); honored in boundary #7.
- **T-06 / vertical-slices** (`docs/features/_archived/vertical-slices/`) — immediately prior batch
  task, shipped 0.37.0; this task takes 0.38.0. Same "additive agent/skill content + version bump +
  CHANGELOG, no count change" shape (precedent for AC-8/AC-9).
- **T-03 / harness-grill** — established the standing "recommend an answer per Open Question" rule
  applied in §8 below.
- Source reference (read-only clone): `codebase-design/SKILL.md` (glossary + principles + deep-vs-
  shallow + designing-for-testability); `DEEPENING.md` and `DESIGN-IT-TWICE.md` are explicitly
  out of scope this round (see §3).

---

## 8. Open questions for the user (deferred-human mode: recommended answers applied)

Per deferred-human mode, each question carries a recommended answer; the pipeline proceeds on the
recommendation rather than blocking. None of these is a human-reserved red line, so none blocks.

1. **Where in `agents/solution-architect.md` does the new section go?**
   (a) Immediately after the Hard-rules block, before Workflow.
   (b) After the "What good looks like" / "What bad looks like" lists, near the file end. — **Recommended.**
   (c) Inside the Workflow as a new step.
   *Recommended (b):* placing it as a standalone late section keeps the existing contract/Workflow
   byte-unchanged (additive, AC-6) and reads as a reference lens rather than a mandatory step
   (AC-4), best honoring the no-railroad framing. The architect leaves the exact line for design.

2. **Section heading wording?**
   (a) `## Design vocabulary (optional lens)` — **Recommended.**
   (b) `## Deep-module design language`.
   (c) `## Module-boundary vocabulary`.
   *Recommended (a):* the word "optional lens" in the heading itself encodes the no-railroad framing
   (AC-4) at the lowest token cost. Final wording is the architect's call within this constraint.

3. **Include the deferred-pointer line for design-it-twice / DEEPENING at all, or omit entirely?**
   (a) Include one combined deferred-pointer line naming both as future options. — **Recommended.**
   (b) Omit both entirely (cite them only in this requirement doc).
   *Recommended (a):* a single line ("finer dependency categories and a design-it-twice
   parallel-exploration pattern exist as future extensions") preserves the trail for a later task at
   minimal cost and matches in-scope #7/#8's "at most one line" cap. If the architect judges it adds
   no leverage, (b) is acceptable — both satisfy AC-5.

4. **CHANGELOG entry granularity?**
   (a) One `### Added` block under `## [0.38.0]` summarizing the section + the no-count-change note. — **Recommended.**
   (b) Split into multiple sub-bullets.
   *Recommended (a):* matches the house CHANGELOG style of the T-04/T-05/T-06 entries (one Added
   block per task with a counts/checks footnote).

---

## 9. Verdict

**READY.**

Rationale: This is mode `full`. All ambiguities are resolved with recommended answers per
deferred-human mode (none is a human-reserved red line — they are placement/wording/granularity
choices the architect can finalize within the stated constraints). The requirement is behavioral
and testable: 13 in-scope behaviors, 9 boundary conditions, 9 acceptance criteria. The new section
is specified as an OPTIONAL lens the architect MAY reach for (in-scope #5, #13; AC-4; boundary #3) —
not a mandatory step and not a new required `02_SOLUTION_DESIGN.md` field. Version target is
**0.38.0** (0.37.0 → 0.38.0) across five surfaces with a matching CHANGELOG entry; counts stay
16 / 8 / 32 with no new check.

PM may advance to Stage 2 (Solution Architect).
