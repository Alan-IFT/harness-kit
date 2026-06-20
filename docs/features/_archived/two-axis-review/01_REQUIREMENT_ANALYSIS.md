# 01 — Requirement Analysis — two-axis-review (T-08)

**Mode:** full · **Stage:** 1 (Requirement Analyst) · **Verdict:** READY (see §9)
**deferred-human mode:** defer, do not ask — every ambiguity below carries a Recommended answer; none is a blocker.

## 1. Goal

Make the `code-reviewer` agent report its findings under two explicitly-separated lenses —
**Standards-conformance** and **Spec/design-fidelity** — so a pass on one lens cannot mask a
failure on the other, as a terse additive review-structure principle (not parallel sub-agent
dispatch).

## 2. Honest additive-value finding (read this first)

The dispatch asked the analyst to judge whether this is genuinely additive or near-redundant.
Finding: **additive, but narrowly** — the delta is exactly the EXPLICIT SEPARATION, nothing more.

Evidence from the live `agents/code-reviewer.md`:
- The agent already covers the Spec/design-fidelity axis (dimensions 2 "Requirement fidelity"
  and 3 "Design fidelity", plus the "Requirement coverage check" and "Design fidelity check"
  tables) and partially covers the Standards axis (dimension 6 "Maintainability" + the rule
  "Inventing rules not in AI-GUIDE.md / `.harness/rules/` or design").
- What is absent: any instruction that the two axes are SEPARATELY scored and that a single
  collapsed verdict must not hide an axis-specific failure. The current verdict rule
  (`APPROVED` if no CRITICAL/MAJOR) is computed across ALL dimensions merged — exactly the
  collapse the mattpocock `review` skill's "Why two axes" section warns against ("a change can
  pass one axis and fail the other").

So the real, transferable, non-redundant idea is: **the two axes must each surface their own
worst finding so neither is masked by an aggregate verdict.** That is a small, real
improvement to the EXISTING contract, not a new capability.

Recommendation: **build the minimal form** — a terse additive lens that (a) names the two
axes, (b) tells the reviewer to attribute each of the 6 existing dimensions to an axis, and
(c) requires the verdict to state per-axis status so neither is masked — and DECLINE everything
heavier (parallel sub-agents, a 7th dimension, a rewrite of the severity model or rollback
routing). This is the same CLASS and shape as T-05 (durable-brief): a terse additive
agent-contract rule + version bump + no count flip.

## 3. In-scope behaviors (numbered, testable)

1. `agents/code-reviewer.md` contains a single additive section that names exactly two review
   axes: **Standards-conformance** (does the change follow this repo's documented conventions —
   AI-GUIDE rules, `.harness/rules/*`, dev-map patterns, naming, doc-size caps, cross-shell
   parity) and **Spec/design-fidelity** (does the change match `01_REQUIREMENT_ANALYSIS.md` and
   `02_SOLUTION_DESIGN.md`).
2. The section maps the agent's 6 existing review dimensions onto the two axes (e.g. dimensions
   2 + 3 are Spec/design-fidelity; dimension 6 + "no invented rules" are Standards-conformance;
   dimensions 1/4/5 may serve either) so the axes reorganize the SAME findings rather than add
   new ones.
3. The section states the masking rule in one sentence: a verdict MUST NOT collapse the two
   axes into a single pass/fail that hides an axis-specific failure — each axis surfaces its own
   findings and its own worst result.
4. The review-document `## Verdict` (or an adjacent line) is required to express per-axis status
   so a reader sees both — i.e. the verdict cannot read `APPROVED` while one axis carries an
   unaddressed CRITICAL/MAJOR.
5. The existing severity model (CRITICAL / MAJOR / MINOR / NIT) is reused unchanged; the two
   axes are an attribution lens over the same severities, not a parallel severity scale.
6. The existing rollback-routing contract (CHANGES REQUIRED → route back to developer via PM)
   is reused unchanged; the addition adds no new routing path.
7. The agent stays structurally read-only: its `tools:` frontmatter remains `Read, Glob, Grep`
   (no `Edit`/`Bash`/`PowerShell`/`Task`), and the new section requires the reviewer to RUN
   nothing.
8. The addition is terse: the agent file stays within the I.3 cap (≤300 lines) and the new
   content reads as a lens/invariant, not a rigid new procedure (rule 15 P4 anti-railroad).
9. A version bump 0.38.0 → 0.39.0 is applied to every place the version is pinned (plugin.json,
   marketplace.json, both README version badges) with a matching CHANGELOG `## [0.39.0]` entry.
10. The counts **16 skills / 8 framework agents / 32 checks** are unchanged everywhere they are
    claimed (CHANGELOG entry, plugin.json description, READMEs, verify_all G.1/G.2/C.1 arrays);
    this is a content edit, not a count change.
11. The existing review-document format (the 6-dimension findings, the Requirement coverage
    check table, the Design fidelity check table, the Files reviewed list) remains present; the
    two-axis lens is additive on top, not a replacement of any existing block.

## 4. Out-of-scope (explicitly NOT done this iteration)

1. Literal parallel sub-agent dispatch (the code-reviewer is a single read-only agent and the
   runtime cannot nest `Task`; this is a principle, not a mechanism).
2. Rewriting or extending the severity model (CRITICAL/MAJOR/MINOR/NIT stays as-is).
3. Rewriting the rollback-routing contract or adding a new routing path.
4. A new `verify_all` check, a new I.6 banned/exempt entry, or any gate change.
5. An issue-tracker dependency (the upstream `review` skill assumes a tracker; we use the
   per-task `01`/`02` stage docs as the spec source).
6. Adding a 7th review dimension or a new required document section (the two axes reorganize the
   existing 6 dimensions; they do not add a dimension).
7. Any change to `harness-sync`, templates, or `.claude/` (the framework agent is plugin-native
   and edited directly in top-level `agents/`).
8. Any edit to other agents (requirement-analyst, solution-architect, etc.) — this is
   single-sourced in `code-reviewer.md` only.

## 5. Boundary conditions

1. **No `02_SOLUTION_DESIGN.md` present** (e.g. an explore-mode or trivial task that skipped
   design): the Spec/design-fidelity axis reviews against `01` alone and the verdict notes the
   design-fidelity axis as "no design doc — requirement-only"; it does not fabricate findings
   and does not block on the absence.
2. **No findings on one axis**: that axis reports a clean result explicitly (e.g. "Standards:
   no findings") rather than being silently omitted — silence is the masking failure mode this
   feature exists to prevent.
3. **Findings on both axes**: both are surfaced; the verdict states both; the aggregate verdict
   is the more severe of the two axes (a CRITICAL on either axis means CHANGES REQUIRED).
4. **A finding spans both axes** (e.g. a naming choice that is both a convention violation and a
   design drift): the reviewer attributes it to the axis where it is most actionable and may
   note the cross-reference; double-counting is not required.
5. **Agent file at the I.3 cap**: if adding the section would exceed ≤300 lines, the addition is
   tightened (terser prose, fewer examples) rather than the cap being raised.
6. **Cross-shell**: this is a Markdown content edit with no script behavior; no PowerShell/Bash
   parity surface is introduced.

## 6. Acceptance criteria (verifiable)

- **AC-1** `agents/code-reviewer.md` contains a section naming both axes (Standards-conformance,
  Spec/design-fidelity) with the masking rule stated. *Verify:* grep the file for both axis
  names and the masking statement.
- **AC-2** The agent's `tools:` frontmatter is still exactly `Read, Glob, Grep` (no
  Edit/Bash/PowerShell/Task). *Verify:* word-boundary regex over the frontmatter line.
- **AC-3** The verdict instruction requires per-axis status such that `APPROVED` is impossible
  while either axis holds an unaddressed CRITICAL/MAJOR. *Verify:* read the verdict rule for the
  per-axis condition.
- **AC-4** The 6 existing review dimensions, the Requirement coverage check, and the Design
  fidelity check are all still present (additive, not replacement). *Verify:* grep for each
  existing heading/table.
- **AC-5** The severity model and the rollback-routing contract are byte-equivalent in meaning
  (no new severity, no new routing path). *Verify:* diff the severity + verdict-routing blocks
  against the pre-change file.
- **AC-6** `agents/code-reviewer.md` is ≤300 lines. *Verify:* line count (I.3 cap).
- **AC-7** Version is 0.39.0 in plugin.json, marketplace.json, and both README badges, with a
  matching `## [0.39.0]` CHANGELOG entry. *Verify:* grep each location; `verify_all` G.3/G.4.
- **AC-8** Counts 16 / 8 / 32 are unchanged everywhere claimed. *Verify:* grep + `verify_all`
  G.1/G.2/C.1.
- **AC-9** `verify_all` reports 32/0/0 (no new check, no WARN/FAIL introduced). *Verify:* run
  `verify_all` (operator runs the PowerShell twin if sub-agent PS is denied — precedent T-05/T-07).
- **AC-10** No new I.6 banned/exempt entry is introduced and the edit does not self-trip I.6.
  *Verify:* `verify_all` I.6 passes; test-verify-i6 entry count unchanged.

## 7. Non-functional requirements

- **NFR-1 (terseness / anti-bloat):** the addition is a lens framed as an invariant, not a rigid
  procedure (rule 15 P4 "don't railroad" + the "sediment/sprawl" handle). Spend lines only on
  what changes the reviewer's default behavior (the no-op test, rule 15 P2): naming the two axes
  and the masking rule. Do not re-explain what the 6 dimensions already do.
- **NFR-2 (single source of truth):** the two-axis principle lives in exactly one place
  (`code-reviewer.md`); no other agent restates it (mirrors T-05's single-source discipline).
- **NFR-3 (read-only safety):** the principle must require nothing to be run; structural
  read-only is enforced by the unchanged `tools:` frontmatter (insight 2026-05-19 L2).

## 8. Related tasks

- **T-05 / durable-brief** (`docs/features/_archived/durable-brief/`) — the closest precedent:
  a terse additive agent-contract edit + version bump + no count flip, single-sourced in one
  agent. Mirror its shape. (insight 2026-06-20)
- **T-07 / sa-design-vocab** (`docs/features/_archived/sa-design-vocab/`) — same mattpocock
  adoption batch, same "additive optional lens on an existing agent, 12-section contract
  byte-unchanged, no count flip, version bump" pattern.
- **T-04 / skill-authoring-vocab** (`docs/features/_archived/skill-authoring-vocab/`) — supplies
  rule 15's "leading word" / "no-op test" / anti-railroad handles this edit is graded against.
- **Reference (read-only, external):** `c:\Programs\_research\mattpocock-skills\skills\in-progress\review\SKILL.md`
  — source of the two-axis structure and the "Why two axes" rationale; only the SEPARATION
  principle is adopted (its parallel-sub-agent mechanism and issue-tracker dependency are
  explicitly out of scope, §4.1/§4.5).

## 9. Open questions (deferred-human mode: recommended, not blocking)

1. **Verdict surfacing — per-axis line vs annotated single verdict?**
   (a) Add a one-line per-axis status above the existing `## Verdict` (e.g. "Standards: clean ·
   Spec/design: 1 MAJOR"); (b) keep one verdict but require it to enumerate the worst finding
   per axis when not APPROVED.
   **Recommended: (a)** — an explicit per-axis line makes the "neither masks the other" property
   visible at a glance and is the cheapest verifiable form of AC-3.
2. **Where in the file does the section live?**
   (a) A new `## Two review axes` section placed near the top (right after "The 6 review
   dimensions") so the lens frames the dimensions; (b) at the file end as an optional lens (the
   T-07 placement).
   **Recommended: (a)** — unlike T-07's optional lens, the masking rule must bind the verdict,
   so it belongs in the main contract flow, not as a tail appendix; placing it adjacent to the
   dimension table is where the axis-attribution is anchored.
3. **Dimension-to-axis attribution — fixed table or guidance?**
   (a) A small fixed mapping (dims 2,3 → Spec/design; dim 6 + "no invented rules" → Standards;
   dims 1,4,5 → either); (b) one sentence of guidance and let the reviewer attribute per
   finding.
   **Recommended: (a) as guidance, not a rigid grid** — name the canonical mapping for the
   unambiguous dimensions and explicitly allow 1/4/5 to land on either axis, satisfying the
   "leading word" anchor without railroading (rule 15 P4).

## Verdict

**READY.** The scope is well-posed and minimal; the three open questions all have recommended
answers and none blocks the next stage (deferred-human mode). The additive value is real but
narrow — the EXPLICIT SEPARATION so neither axis masks the other — and the build is scoped to
exactly that, declining the heavier mattpocock mechanism. Version 0.38.0 → 0.39.0; counts
16/8/32 unchanged; no new check.
