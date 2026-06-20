# 02 — Solution Design · two-axis-review (T-08)

**Mode:** full · **Stage:** 2 (Solution Architect) · **deferred-human mode:** defer, do not ask.
**Date:** 2026-06-20 · **Upstream verdict:** RA `READY` (`01_REQUIREMENT_ANALYSIS.md` Verdict) · **Verdict:** see §12.

> OQ defaults adopted (PM-accepted, RA §9): OQ-1 → (a) an explicit one-line per-axis status line
> above the existing `## Verdict` · OQ-2 → (a) a new `## Two review axes` section placed right after
> "The 6 review dimensions" so the lens frames the dimensions · OQ-3 → (a) name the canonical
> mapping for the unambiguous dimensions and allow 1/4/5 on either axis, as guidance not a rigid grid.

---

## 1. Architecture summary

A single additive `## Two review axes` section is inserted into the plugin-native framework agent
`agents/code-reviewer.md`, directly after the existing "The 6 review dimensions" table, naming two
explicitly-separated review lenses — **Standards-conformance** and **Spec/design-fidelity** —
attributing the agent's six EXISTING dimensions onto the two axes (no new dimension), and stating
the masking rule: a verdict must not collapse the two axes into a single pass/fail that hides an
axis-specific failure. Two existing blocks gain one line each so the rule binds the output: the
Workflow grows one verdict-prep step, and the "Review document format" template gains a one-line
per-axis status line above the existing `## Verdict`. The severity model (CRITICAL/MAJOR/MINOR/NIT),
the rollback-routing contract (CHANGES REQUIRED → route to developer via PM), the 6-dimension table,
the Requirement-coverage check, and the Design-fidelity check are all byte-unchanged in meaning. The
agent stays read-only (`tools: Read, Glob, Grep`). No code, script, gate, or count moves — agent-prose
content plus the standard shipped-content version fan-out 0.38.0 → 0.39.0 across four stamps + CHANGELOG.

## 2. Affected modules

| File | Change | Why |
|---|---|---|
| `agents/code-reviewer.md` | edit (insert one `##` section after the 6-dimension table; +1 Workflow step; +1 line in the format template) | The behavioral payload: the two-axis lens + the masking rule binding the verdict |
| `.claude-plugin/plugin.json` | edit (`version` 0.38.0 → 0.39.0, line 4) | G.3/G.4 version-claim consistency for a shipped-content change |
| `.claude-plugin/marketplace.json` | edit (`plugins[0].version` → 0.39.0, line 17) | same version surface |
| `README.md` | edit (line-5 badge `version-0.39.0-blue`, that token only) | same version surface |
| `README.zh-CN.md` | edit (line-5 badge `version-0.39.0-blue`, that token only) | same version surface |
| `CHANGELOG.md` | edit (prepend `## [0.39.0]` entry above `## [0.38.0]`) | G.4 claim/version record + counts-unchanged footnote |

No other file is touched. Confirmed via glob `.harness/agents/dev-*.md` → **none** (single Developer
mode; partition assignment §11 omitted).

## 3. Module decomposition — the exact additive content

The agent is the "module"; the new section + two one-line touches are the only new surface. The
Developer (Stage 4) applies these THREE edits to `agents/code-reviewer.md`. All existing lines other
than the two single-line touches in §3.2/§3.3 stay byte-for-byte unchanged (additive boundary, AC-4/AC-5).

### 3.1 New section — insert verbatim after the 6-dimension table

**Insertion point:** immediately after the "The 6 review dimensions" table (the table ends at the
dimension-6 "Maintainability" row, currently line 25), and BEFORE the `## Severity levels` heading
(currently line 27). Insert one blank line, then the section, then one blank line before `## Severity
levels`. This places the lens so it FRAMES the dimensions it re-organizes (OQ-2 (a)) and so the
masking rule sits in the main contract flow, not as a tail appendix.

Paste the INNER content only (the four-backtick fence below is a display wrapper, not part of the file —
gate Q2 / T-07 dev note):

````markdown
## Two review axes

The 6 dimensions above are read through **two explicitly-separated lenses**. Score each axis on its
own; never merge them into one pass/fail — a change can clear one axis and fail the other, and a
collapsed verdict would hide that.

- **Standards-conformance** — does the change follow THIS repo's documented conventions: AI-GUIDE
  rules, `.harness/rules/*`, dev-map patterns, naming, doc-size caps, cross-shell parity? (Dimension
  6 Maintainability, plus the "no invented rules" check, live here.)
- **Spec/design-fidelity** — does the change match `01_REQUIREMENT_ANALYSIS.md` and
  `02_SOLUTION_DESIGN.md`? (Dimensions 2 Requirement fidelity + 3 Design fidelity, plus the
  Requirement-coverage and Design-fidelity check tables, live here.)

Dimensions 1 (Logic), 4 (Performance), and 5 (Security) attribute to whichever axis a given finding
is most actionable on — a broken error path against a spec'd behaviour is Spec/design-fidelity; the
same bug against an undocumented edge is Standards. Attribute, don't double-count; cross-reference if
a finding genuinely spans both.

**Masking rule (binds the verdict).** Each axis surfaces its OWN findings and its OWN worst result.
An axis with nothing to report says so explicitly ("Standards: no findings") — silence is the masking
failure this lens exists to prevent. The verdict cannot read `APPROVED` while either axis carries an
unaddressed CRITICAL or MAJOR; the aggregate is the more severe of the two axes. If there is no
`02_SOLUTION_DESIGN.md` (a requirement-only task), the Spec/design-fidelity axis reviews against `01`
alone and the per-axis line notes "Spec/design: no design doc — requirement-only" rather than
fabricating or blocking.
````

### 3.2 Workflow — one new verdict-prep step (edit, not append)

The existing Workflow step 6 ("Write verdict:") is preceded by one new step so the per-axis result is
computed before the verdict is written. Change the current step 6 to step 7 and insert:

````markdown
6. Group every finding under its axis (Standards-conformance / Spec/design-fidelity) and record each
   axis's worst severity — including an explicit clean result for an axis with no findings.
````

The existing `APPROVED` / `CHANGES REQUIRED` sub-bullets under the (now-renumbered) verdict step are
UNCHANGED in wording — the routing contract is untouched (AC-5).

### 3.3 Review document format — one new per-axis status line (edit)

In the fenced `## Review document format` template, insert ONE line directly above the existing
`## Verdict` line (OQ-1 (a)):

````markdown
## Axis status
- Standards-conformance: <clean | N findings, worst = SEVERITY>
- Spec/design-fidelity: <clean | N findings, worst = SEVERITY>
````

The existing `## Verdict` line and its example (`CHANGES REQUIRED (2 CRITICAL, 1 MAJOR)`) stay as-is.
This makes the "neither masks the other" property visible at a glance and is the cheapest verifiable
form of AC-3.

## 4. Data model changes

None. No schema, no table, no config key. Agent-prose content plus a version stamp.

## 5. API contracts

None broken. The reviewer's OUTPUT contract — the `05_CODE_REVIEW.md` shape — is EXTENDED additively
by one `## Axis status` block above the existing `## Verdict`; every existing block (Files reviewed,
Findings by severity, Requirement coverage check, Design fidelity check, Verdict) is retained
verbatim (AC-4). No downstream stage parses a removed/renamed field. The severity vocabulary
(CRITICAL/MAJOR/MINOR/NIT) and the verdict-routing values (`APPROVED` / `CHANGES REQUIRED`) are
byte-equivalent in meaning (AC-5) — the two axes are an ATTRIBUTION lens over the same severities, not
a parallel severity scale or a new routing path.

## 6. Sequence / flow

```
PM dispatches Stage 5  →  code-reviewer.md loaded (now +~22 lines)
                          │
                          ├─ reads 01 / 02 / 04 + changed files + tests (Workflow steps 1-5, unchanged)
                          │
                          ├─ writes findings across the 6 dimensions (unchanged)
                          │
                          ├─ NEW step 6: group each finding under its axis; record each axis's worst
                          │     severity (an empty axis reports "clean", never silence)
                          │
                          ├─ step 7 (was 6): emit `## Axis status` (per-axis line) THEN `## Verdict`;
                          │     APPROVED is impossible if either axis holds an open CRITICAL/MAJOR;
                          │     aggregate = more severe of the two axes
                          │
                          └─ CHANGES REQUIRED → route back to developer via PM (routing UNCHANGED)
```

The two axes reorganize the SAME findings; no finding is invented and no severity is rescaled. A
clean review still reads `APPROVED` — now with two explicit "clean" axis lines proving neither was
silently skipped.

## 7. Reuse audit

| Need | Existing code/source | File path | Decision |
|---|---|---|---|
| Two-axis structure + "Why two axes" rationale | `review/SKILL.md` "Why two axes" (l.62-69) + side-by-side reporting (l.57-60) | `c:\Programs\_research\mattpocock-skills\skills\in-progress\review\SKILL.md` | Adopt the SEPARATION principle ONLY; drop parallel sub-agents (l.38-54) + issue-tracker dep (l.13,26-32) — RA §4.1/§4.5 |
| The 6 review dimensions to attribute onto axes | The dimension table | `agents/code-reviewer.md` (the "The 6 review dimensions" table) | Reuse as-is; the lens re-groups them, adds none (AC-4) |
| Severity model (CRITICAL/MAJOR/MINOR/NIT) | The "Severity levels" block | `agents/code-reviewer.md` (`## Severity levels`) | Reuse byte-unchanged; axes attribute over it, not replace it (AC-5) |
| Rollback routing (CHANGES REQUIRED → developer via PM) | Hard rule 1 + the verdict step's `CHANGES REQUIRED` bullet | `agents/code-reviewer.md` (`## Hard rules` #1; Workflow verdict step) | Reuse byte-unchanged; no new routing path (AC-5) |
| Read-only safety boundary | `tools: Read, Glob, Grep` frontmatter | `agents/code-reviewer.md` (frontmatter `tools:` line) | Leave untouched; lens requires running nothing (AC-2, insight 2026-05-19 L2) |
| "Lens / leading word / no-railroad" framing | rule 15 "Leading word" handle + P4 "Don't railroad" + No-op test | `.harness/rules/15-skill-authoring.md` (l.42-44, l.70-77) | Frame the axes as leading words + an invariant (the masking rule), not a rigid procedure |
| Additive agent-contract edit + 4-stamp version fan-out + CHANGELOG | T-07 sa-design-vocab design | `docs/features/_archived/sa-design-vocab/02_SOLUTION_DESIGN.md` | Mirror the exact shape, bumped 0.38.0 → 0.39.0; same single-source / no-count-flip discipline |
| Counts-unchanged footnote wording | T-07 CHANGELOG `[0.38.0]` footnote | `CHANGELOG.md` (the `[0.38.0]` entry's last bullet) | Reuse: restate 16 / 8 / 32 UNCHANGED; no new check; no I.6 list change |
| New `verify_all` check? | (none — and none wanted) | — | NOT added: this is review guidance, not a hazard gate (rule 15 P6; RA §4.4) |

## 8. Risk analysis

1. **Railroad drift — the section reads as a rigid new procedure (rule 15 P4 / RA NFR-1).**
   *Mitigation:* the section is framed as a LENS over the existing dimensions plus a single binding
   INVARIANT (the masking rule); the only procedural addition is one verdict-prep Workflow step and
   one output line — it does not re-explain what the 6 dimensions already do (no-op test, rule 15 P2).
   The masking rule is stated as one invariant ("never merge them; APPROVED impossible if either axis
   holds an open CRITICAL/MAJOR"), not a multi-step script.

2. **No-op / duplication — the agent ALREADY covers both axes implicitly (RA §2 honest finding).**
   *Mitigation:* the load-bearing delta is the EXPLICIT SEPARATION + the masking rule, which the
   current contract lacks — its verdict ("`APPROVED` if no CRITICAL/MAJOR") is computed across all
   dimensions MERGED, exactly the collapse the masking rule forbids. The new content changes default
   behavior: a per-axis status line + an axis-can't-be-silent rule + a "more severe of the two axes"
   aggregate. Nothing restates a dimension's definition.

3. **Severity / routing accidentally rewritten.** Touching the verdict step risks editing the
   `APPROVED` / `CHANGES REQUIRED` wording or the routing. *Mitigation:* §3.2 inserts a NEW step and
   only RENUMBERS the existing verdict step; its sub-bullets and Hard rule 1 are byte-unchanged
   (AC-5). The new content adds an attribution lens and a per-axis output line — no fifth severity,
   no second routing path.

4. **Cap breach.** `agents/code-reviewer.md` must end ≤300 lines (I.3). *Mitigation:* current 108
   lines + ~22 (new section + 1 Workflow line + 3 format lines + separators) ≈ **130 lines** —
   comfortably under 300 (see §10). If the section would breach the cap, tighten the prose rather than
   raise the cap (RA boundary §5.5) — not a live concern given the >170-line headroom.

5. **Count-claim flip on the version bump (insight 2026-06-19 decoy discipline).** Touching
   README/CHANGELOG risks flipping a "16 / 8 / 32" token. *Mitigation:* README edit is the version
   *token only* (the 32%2F32, 308, 90 badges stay); the CHANGELOG `[0.39.0]` footnote restates counts
   UNCHANGED; G.4 FAILs on a count↔version contradiction as backstop; no count token is edited
   anywhere.

6. **I.6 banned-anchor self-trip (insight 2026-06-08, Hard rule 6).** *Mitigation:* the I.6 banned
   anchors are all about CLAUDE.md generation/composition + zh-policy (verify_all.sh l.521-536); none
   overlap "Standards-conformance / Spec-design-fidelity / axis / masking / lens / per-axis". `agents/`
   is NOT an I.6 exempt dir, so the file IS scanned — but the new text introduces no banned sequence.
   The section writes NO literal `name.ext:NNN` path:line into agent prose (Hard rule 6) — file
   references in the new section are bare filenames (`01_REQUIREMENT_ANALYSIS.md`, `.harness/rules/*`),
   never `name.ext:NNN`. (The path:line citations in THIS design doc are backward-looking evidence and
   live under the `docs/features/` I.6-exempt subtree — insight 2026-06-20 forward/backward boundary.)

## 9. Migration / rollout plan

Backwards-compatible and additive; no data migration, no feature flag.

1. Edit `agents/code-reviewer.md`: (a) insert the §3.1 section after the 6-dimension table and before
   `## Severity levels`; (b) insert the §3.2 verdict-prep step and renumber the existing verdict step;
   (c) insert the §3.3 `## Axis status` block above the `## Verdict` line in the format template.
   Verify all other lines + the `tools:` frontmatter are byte-unchanged.
2. Bump version stamps to **0.39.0**: `.claude-plugin/plugin.json` (`version`, line 4);
   `.claude-plugin/marketplace.json` (`plugins[0].version`, line 17); `README.md` badge (line 5,
   `version-0.38.0-blue` → `version-0.39.0-blue`, that token only); `README.zh-CN.md` badge (line 5).
3. Prepend the `## [0.39.0]` CHANGELOG entry (§ below) above `## [0.38.0]`.
4. Run `.harness/scripts/verify_all` — expect **32/32 PASS**, same total as task start (AC-9). G.3
   sees 0.39.0 across the four stamps; G.4 sees the `[0.39.0]` heading with counts consistent
   (16/8/32); I.3 cap OK (~130 ≤ 300); I.6 clean; C.1/G.1/G.2 count arrays untouched.

**Rollback:** revert the six files (one `git revert`); the agent returns to its 108-line 0.38.0 state.
No state, no migration, nothing to undo beyond the file contents.

**No sync, no template copy.** Framework agents are plugin-native — `agents/code-reviewer.md` is
edited DIRECTLY in top-level `agents/` and auto-discovered as `harness-kit:code-reviewer` (AI-GUIDE.md
l.13, l.107; sync-self no longer mirrors agents since v0.30). There is no template `.tmpl` twin to
keep in step, and `harness-sync` is not run for this change.

### Version stamp targets (G.3) — bump 0.38.0 → 0.39.0

| Surface | File | Token |
|---|---|---|
| plugin.json | `.claude-plugin/plugin.json` | `"version": "0.39.0"` (line 4) |
| marketplace.json | `.claude-plugin/marketplace.json` | `plugins[0].version = "0.39.0"` (line 17) |
| README badge | `README.md` | `version-0.39.0-blue` shield (line 5) |
| README.zh-CN badge | `README.zh-CN.md` | `version-0.39.0-blue` shield (line 5) |

### CHANGELOG `[0.39.0]` entry (G.4) — prepend above `## [0.38.0]`

```markdown
## [0.39.0] - 2026-06-20

### Added — two-axis-review: explicit Standards / Spec-design axis separation in the code-reviewer so neither masks the other (T-08)

The `code-reviewer` now reads its 6 existing review dimensions through **two explicitly-separated
lenses** adapted from mattpocock's `review` skill — **Standards-conformance** (does the change follow
this repo's documented conventions: AI-GUIDE rules, `.harness/rules/*`, dev-map patterns, naming,
doc-size, cross-shell parity) and **Spec/design-fidelity** (does it match `01_REQUIREMENT_ANALYSIS.md`
and `02_SOLUTION_DESIGN.md`) — and reports them separately so a pass on one axis cannot mask a failure
on the other. The verdict gains a per-axis status line and a masking rule: `APPROVED` is impossible
while either axis holds an unaddressed CRITICAL/MAJOR, and the aggregate is the more severe of the two
axes.

- **`agents/code-reviewer.md`**: one new additive `## Two review axes` section after the 6-dimension
  table, one verdict-prep Workflow step, and one `## Axis status` line above the existing `## Verdict`
  in the format template. The two axes ATTRIBUTE the SAME 6 dimensions (dims 2,3 + the coverage/design
  check tables → Spec/design-fidelity; dim 6 + "no invented rules" → Standards; dims 1,4,5 → either) —
  no 7th dimension. The severity model (CRITICAL/MAJOR/MINOR/NIT), the rollback-routing contract, and
  the read-only `tools: Read, Glob, Grep` frontmatter are byte-unchanged. The heavier parallel
  sub-agent mechanism and the issue-tracker dependency from the upstream skill are NOT adopted.
- Version 0.38.0 → 0.39.0 (plugin.json, marketplace.json, both README version badges). Counts
  unchanged: **16 skills / 8 framework agents / 32 checks**. No new `verify_all` check (the lens is
  review guidance, not a gate); no I.6 banned/exempt-list change; no `harness-sync` / no template copy
  (agents are plugin-native, edited directly in top-level `agents/`).
```

## 10. Projected line count

`agents/code-reviewer.md`: **108 lines today** (last content line is 108). Additions:
- §3.1 new `## Two review axes` section: heading + lead (3 lines) + 2 axis bullets (4 lines wrapped) +
  the dims-1/4/5 paragraph (3 lines) + the masking-rule paragraph (5 lines) + in-section blanks (~4)
  ≈ **19 lines**, + 2 separator blanks around it.
- §3.2 one new Workflow step ≈ **1 line** (renumber is in place, no net new line for the rename).
- §3.3 `## Axis status` block in the format template ≈ **3 lines** + 1 blank.

**Projected total ≈ 130 lines — well under the I.3 ≤300 cap** (AC-6). Headroom > 170 lines.

## 11. Out-of-scope clarifications

1. **No parallel sub-agent dispatch.** The reviewer is a single read-only agent; the runtime can't
   nest `Task`. The two axes are a principle, not a mechanism (RA §4.1).
2. **No severity-model change.** CRITICAL/MAJOR/MINOR/NIT stays byte-unchanged; the axes attribute
   over it (RA §4.2, AC-5).
3. **No rollback-routing change.** CHANGES REQUIRED → developer via PM is the only routing path; no
   new path added (RA §4.3, AC-5).
4. **No 7th review dimension and no new required document section beyond the additive `## Axis status`
   line.** The axes re-group the existing 6 dimensions; they do not add a dimension (RA §4.6, AC-4).
5. **No new `verify_all` check, no new I.6 banned/exempt entry, no gate change** (RA §4.4, AC-9/AC-10).
6. **No issue-tracker dependency.** The Spec/design-fidelity axis reads the per-task `01`/`02` stage
   docs as the spec source, not an external tracker (RA §4.5).
7. **No count change** — 16 skills / 8 framework agents / 32 checks stay literally unchanged (RA §3 #10).
8. **No edit to any other agent** (requirement-analyst, solution-architect, etc.) — single-sourced in
   `code-reviewer.md` only (RA §4.8, NFR-2).
9. **No sync / no `.claude/` edit / no template copy** — framework agents are plugin-native (RA §4.7).

## 12. Partition assignment

**Omitted — single Developer mode.** No `.harness/agents/dev-*.md` partition agents exist in this
repo (confirmed: glob `.harness/agents/dev-*.md` → none). The plugin `harness-kit:developer` applies
all six file edits in this dependency order: (1) the three `agents/code-reviewer.md` edits (§3.1 →
§3.2 → §3.3, all in one file); (2) the four version stamps (plugin.json, marketplace.json, README.md,
README.zh-CN.md); (3) the `CHANGELOG.md [0.39.0]` entry; (4) run `verify_all`. Steps 1-3 are mutually
independent content edits; step 4 depends on 1-3.

## 13. Verdict

**READY.**

Rationale: Mode `full`, upstream RA `READY`. The design specifies the EXACT additive content (§3.1
verbatim section, §3.2 one Workflow step, §3.3 one output line), its precise insertion point (the new
section after the 6-dimension table and before `## Severity levels`; the `## Axis status` block above
`## Verdict`), the byte-unchanged severity model + rollback routing + read-only frontmatter, the four
version surfaces + CHANGELOG `[0.39.0]` entry (§9), and a projected total of ~130 lines (≤300, §10).
The genuine delta is exactly the EXPLICIT AXIS SEPARATION + the masking rule so an aggregate
`APPROVED` can never hide an axis-specific CRITICAL/MAJOR — the heavier mattpocock mechanism (parallel
sub-agents, issue tracker) is declined. The section is framed as a lens + one invariant (no railroad,
rule 15 P4). Counts stay 16 / 8 / 32 with no new check and no I.6 list change; the agent stays
read-only. All 10 acceptance criteria are addressed. A junior developer can implement this without
further design decisions.

PM may advance to Stage 3 (Gate Reviewer).
