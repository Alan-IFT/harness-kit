# 02 — Solution Design · sa-design-vocab (T-07)

**Mode:** full · **Stage:** 2 (Solution Architect) · **deferred-human mode:** defer, do not ask.
**Date:** 2026-06-20 · **Upstream verdict:** RA `READY` (`01_REQUIREMENT_ANALYSIS.md` §9) · **Verdict:** see §12.

> OQ defaults adopted (PM-accepted, RA §8): OQ-1 → (b) standalone late section after the
> "What good / bad looks like" lists, near file end · OQ-2 → (a) heading `## Design vocabulary (optional lens)`
> · OQ-3 → (a) include one combined deferred-pointer line naming design-it-twice + DEEPENING as future
> options · OQ-4 → (a) one `### Added` CHANGELOG block under `## [0.38.0]` with the counts/checks footnote.

---

## 1. Architecture summary

A single OPTIONAL design-language section is appended to the plugin-native framework agent
`agents/solution-architect.md`, giving the Stage-2 architect named handles (the codebase-design
deep-module vocabulary + four sharp tests/principles) as a LENS it MAY reach for when designing
module boundaries. The edit is purely additive (one new `##` section at the file end); the existing
12-section `02_SOLUTION_DESIGN.md` output structure, Hard rules, Workflow, Mode-specific note,
Reuse-audit format, and Partition-assignment format stay byte-for-byte unchanged. No code, script,
gate, or count moves — this is agent-prose content plus the standard shipped-content version
fan-out (0.37.0 → 0.38.0 across five surfaces).

## 2. Affected modules

| File | Change | Why |
|---|---|---|
| `agents/solution-architect.md` | edit (append one `##` section) | The behavioral payload: the optional design-vocabulary lens |
| `.claude-plugin/plugin.json` | edit (`version` 0.37.0 → 0.38.0) | G.3/G.4 version-claim consistency for a shipped-content change |
| `.claude-plugin/marketplace.json` | edit (`plugins[0].version` → 0.38.0) | same version surface |
| `README.md` | edit (line-5 badge `version-0.38.0-blue`, that token only) | same version surface |
| `README.zh-CN.md` | edit (line-5 badge `version-0.38.0-blue`, that token only) | same version surface |
| `CHANGELOG.md` | edit (prepend `## [0.38.0]` entry) | G.4 claim/version record + counts-unchanged footnote |

No other file is touched. Confirmed via glob `.harness/agents/dev-*.md` → **none** (single Developer mode).

## 3. Module decomposition (the new section — exact content)

The agent is the "module"; the new section is the only new "public API" surface. The architect
(Stage 4 / Developer) appends the following **verbatim** as a new top-level `##` section. It is
designed to land at ~22 body lines (heading + lead + 7 glossary lines + 4 principle lines +
1 deferred-pointer line + spacing), inside the ≤25-line target (NFR-1).

````markdown
## Design vocabulary (optional lens)

A lens you **may** reach for when designing or sharpening a module boundary — these are leading
words to think *with*, not a checklist to tick off and not a required `02_SOLUTION_DESIGN.md` field.
Aim for **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam.

- **Module** — anything with an interface and an implementation (a function, class, package, or a tier-spanning slice). Scale-agnostic; not "component"/"service".
- **Interface** — everything a caller must know to use it correctly: the type signature *and* invariants, ordering constraints, error modes, required config, and performance characteristics. Broader than the signature alone.
- **Depth** — leverage per unit of interface: how much behaviour a caller exercises per unit of interface they must learn. Deep = much behaviour behind a small interface (not the impl-to-interface line ratio).
- **Seam** — the location where the interface lives: a place you can alter behaviour without editing in that place. Where the seam goes is its own decision, separate from what sits behind it.
- **Adapter** — a concrete thing that satisfies an interface at a seam (a role/slot, not a substance).
- **Leverage** — the caller's payoff from depth: one implementation pays back across N call sites and M tests.
- **Locality** — the maintainer's payoff from depth: change, bugs, and verification concentrate in one place — fix once, fixed everywhere.

When the lens is useful:

- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through; if complexity reappears across N callers, it earned its keep.
- **The interface is the test surface.** Callers and tests cross the same seam — if you need to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam; two means a real one.** Don't introduce a seam unless something actually varies across it.

_Future options (not used here): finer dependency categories (in-process / local-substitutable / remote-owned / true-external) and a design-it-twice parallel-exploration pattern — both deferred._
````

**Insertion point:** append as the **last** `##` section of `agents/solution-architect.md`, after the
existing `## What "bad" looks like (avoid)` block (which currently ends the file at line 122, with
the section list running lines 117-122). Insert one blank line, then the section. No existing line is
edited, reordered, or reworded (additive boundary, AC-6).

**Source-fidelity notes (against `codebase-design/SKILL.md`, RA boundary #8):**
- depth = leverage per unit of interface — the line explicitly rejects the impl-to-interface line
  ratio (SKILL.md "Rejected framings", line 107).
- interface = everything a caller must know, broader than the signature (SKILL.md line 16; AC-3).
- seam = where the interface lives (SKILL.md line 22); adapter = concrete thing satisfying an
  interface at a seam (SKILL.md line 24).
- The four principle lines are the deletion test, interface-is-the-test-surface, and the
  one-adapter/two-adapter rule, transcribed from SKILL.md lines 63-65.

## 4. Data model changes

None. No schema, no table, no config key. This is agent-prose plus a version stamp.

## 5. API contracts

None changed. Critically, the `02_SOLUTION_DESIGN.md` **output contract** (the 12-section list at
`agents/solution-architect.md` lines 14-29) is **byte-unchanged** — the vocabulary is a lens, NOT a
new required output section (AC-4). The new `## Design vocabulary (optional lens)` section is
reference material the architect *may* consult; it adds no field any downstream stage parses.

## 6. Sequence / flow

```
PM dispatches Stage 2  →  solution-architect.md loaded into context (now +~22 lines)
                          │
                          ├─ architect reads RA doc, AI-GUIDE, rules, dev-map, CONTEXT.md, grep
                          │
                          ├─ when shaping a module boundary, architect MAY reach for the lens:
                          │     name the module/interface/seam, run the deletion test, ask
                          │     "one adapter or two?" — or skip it entirely (no gate, no field)
                          │
                          └─ writes 02_SOLUTION_DESIGN.md in the unchanged 12-section structure
```

The lens never sits on a required path. A design that never mentions a single vocabulary term is
still a complete, conformant `02_SOLUTION_DESIGN.md` (no-railroad, RA boundary #3).

## 7. Reuse audit

| Need | Existing code/source | File path | Decision |
|---|---|---|---|
| Deep-module glossary + 4 principles (verbatim meanings) | `codebase-design/SKILL.md` glossary (l.14-28), Principles (l.62-65), Rejected framings (l.107) | `c:\Programs\_research\mattpocock-skills\skills\engineering\codebase-design\SKILL.md` | Distil into 7 one-liners + 4 principle lines; preserve exact meanings (boundary #8) |
| "Optional lens / may / leading word" framing | rule 15 "Leading word" handle + P4 "Don't railroad" | `.harness/rules/15-skill-authoring.md` (l.42-44, l.70-74) | Reuse the handle; frame the terms AS leading words, not a checklist (AC-4, in-scope #13) |
| Additive-edit-on-solution-architect precedent | T-02 CONTEXT.md soft-dep step (Workflow step 5) | `agents/solution-architect.md` line 45 | Reuse the "additive late/inline, never a blocker" pattern; append, don't rewrite |
| Shipped-content version fan-out (5 surfaces + CHANGELOG) | T-06 vertical-slices entry; T-05 durable-brief entry | `CHANGELOG.md` l.8-16 (T-06); `docs/features/_archived/vertical-slices/02_SOLUTION_DESIGN.md` | Reuse the exact 4-stamp + CHANGELOG pattern, bumped 0.37.0 → 0.38.0 |
| Counts-unchanged footnote wording | T-06 CHANGELOG footnote | `CHANGELOG.md` line 16 | Reuse: restate 16 skills / 8 framework agents / 32 checks UNCHANGED; no new check; no I.6 list change |
| New `verify_all` check? | (none — and none wanted) | — | NOT added: this is authoring guidance, not a hazard gate (rule 15 P6; RA out-of-scope #5) |

## 8. Risk analysis

1. **Railroad drift — the section reads as mandatory.** If the prose reads "use these seven terms in
   every design" or ties the vocabulary to an output field, it violates in-scope #5 / AC-4 / boundary
   #3. *Mitigation:* the heading itself carries "(optional lens)"; the lead sentence carries **may** +
   "leading words to think *with*, not a checklist" + "not a required `02_SOLUTION_DESIGN.md` field";
   the 12-section list (lines 14-29) is byte-unchanged. Three independent affordance signals.

2. **No-op section — re-states what the model already knows.** A generic "design good modules" blurb
   fails the no-op test (rule 15 P2; RA boundary #2). *Mitigation:* the load-bearing distinctions each
   push past default behavior: interface = *everything a caller must know* (not the signature),
   depth = *leverage per unit of interface* (the source explicitly rejects the line-ratio reading),
   and the four sharp tests (deletion / test-surface / one-vs-two-adapter) are decision rules, not
   platitudes.

3. **Source-meaning drift.** Paraphrasing could invert a definition (e.g. depth-as-line-ratio).
   *Mitigation:* §3 source-fidelity notes pin each term to its `codebase-design/SKILL.md` line; the
   depth line explicitly negates the ratio reading; reviewer cross-checks against SKILL.md l.14-28/62-65/107.

4. **Cap breach.** `agents/solution-architect.md` must end ≤300 lines (I.3). *Mitigation:* current
   122 lines (file ends at 122; line 123 is the EOF newline) + ~22 section lines + 1 blank separator
   ≈ **145 lines** — comfortably under 300. See §3 line budget; projected count in §10.

5. **Accidental count-claim flip on the version bump.** Touching README/CHANGELOG risks flipping a
   "16 / 8 / 32" token. *Mitigation:* README edit is the version *token only* (the 32/32, 308/308,
   90/90 badges stay); the CHANGELOG `[0.38.0]` footnote restates counts UNCHANGED; G.4 FAILs on a
   count↔version contradiction as backstop; no count token is edited anywhere (T-03 decoy-set
   discipline, insight 2026-06-19).

6. **I.6 banned-anchor self-trip.** *Mitigation:* I.6 banned anchors are all about CLAUDE.md
   generation/composition + zh-policy (verify_all.sh l.521-536); none overlap module / interface /
   depth / seam / adapter / leverage / locality / deletion test. `agents/` is NOT an I.6 exempt dir,
   so the file IS scanned — but the new text introduces no banned sequence. The section also writes
   no forward-looking `name.ext:NNN` path:line into agent prose (Hard rule 6, RA boundary #7).

## 9. Migration / rollout plan

Backwards-compatible and additive; no data migration, no feature flag.

1. Append the §3 section verbatim to `agents/solution-architect.md` after the `## What "bad" looks
   like (avoid)` block. Verify lines 1-122 are byte-unchanged.
2. Bump version stamps to **0.38.0**: `.claude-plugin/plugin.json` (`version`, line 4);
   `.claude-plugin/marketplace.json` (`plugins[0].version`, line 17); `README.md` badge (line 5,
   `version-0.37.0-blue` → `version-0.38.0-blue`, that token only); `README.zh-CN.md` badge (line 5).
3. Prepend the `## [0.38.0]` CHANGELOG entry (§ below) above `## [0.37.0]`.
4. Run `.harness/scripts/verify_all` — expect **32/32 PASS**, same total as task start (AC-9). G.3
   sees 0.38.0 across the four stamps; G.4 sees the `[0.38.0]` heading with counts consistent
   (16/8/32); I.3 cap OK (~145 ≤ 300); I.6 clean.

**Rollback:** revert the six files (one git revert); the agent returns to its 122-line 0.37.0 state.
No state, no migration, nothing to undo beyond the file contents.

**No sync, no template copy.** Framework agents are plugin-native — `agents/solution-architect.md`
is edited DIRECTLY in the top-level `agents/` and auto-discovered as `harness-kit:solution-architect`
(AI-GUIDE.md l.13, l.107; sync-self no longer mirrors agents since v0.30). There is no
`skills/harness-init/templates/.../solution-architect.md.tmpl` to keep in step, and `harness-sync`
is not run for this change.

### Version stamp targets (G.3) — bump 0.37.0 → 0.38.0

| Surface | File | Token |
|---|---|---|
| plugin.json | `.claude-plugin/plugin.json` | `"version": "0.38.0"` (line 4) |
| marketplace.json | `.claude-plugin/marketplace.json` | `plugins[0].version = "0.38.0"` (line 17) |
| README badge | `README.md` | `version-0.38.0-blue` shield (line 5) |
| README.zh-CN badge | `README.zh-CN.md` | `version-0.38.0-blue` shield (line 5) |

### CHANGELOG `[0.38.0]` entry (G.4) — prepend above `## [0.37.0]`

```markdown
## [0.38.0] - 2026-06-20

### Added — sa-design-vocab: an optional deep-module design-vocabulary lens for the solution-architect (T-07)

The `solution-architect` gains an OPTIONAL `## Design vocabulary (optional lens)` section adapted
from mattpocock's `codebase-design` skill: named handles for designing **deep modules** — **module**,
**interface** (everything a caller must know, not just the type signature), **depth** (leverage per
unit of interface), **seam** (where the interface lives), **adapter**, **leverage**, **locality** —
plus four sharp tests: the **deletion test**, "the interface is the test surface", and
"one adapter means a hypothetical seam, two means a real one". It is framed as a **lens the architect
MAY reach for** when shaping a module boundary (leading words to think with, per rule 15 P4 / the
"leading word" handle) — NOT a mandate and NOT a new required `02_SOLUTION_DESIGN.md` field; the
12-section output contract is unchanged.

- **`agents/solution-architect.md`**: one new additive `## Design vocabulary (optional lens)` section
  at the file end (after "What bad looks like"). The heavier design-it-twice parallel-subagent
  pattern and the full DEEPENING dependency-category taxonomy are **not** introduced — named only, in
  a single deferred-pointer line. The existing contract, Hard rules, Workflow, and output structure
  are byte-unchanged.
- Version 0.37.0 → 0.38.0 (plugin.json, marketplace.json, both README version badges). Counts
  unchanged: **16 skills / 8 framework agents / 32 checks**. No new `verify_all` check (the lens is
  authoring guidance, not a gate); no I.6 banned/exempt-list change; no `harness-sync` / no template
  copy (agents are plugin-native, edited directly in top-level `agents/`).
```

## 10. Projected line count

`agents/solution-architect.md`: **122 lines today** (last content line is 122; the cat-n `123` is the
trailing-newline marker). New section = heading + 1 lead paragraph (3 lines) + "Aim for deep modules"
(1) + 7 glossary lines + "When the lens is useful:" (1) + 3 principle lines + 1 deferred-pointer line
+ in-section blank lines (~5) ≈ **22 lines**, plus 1 blank separator before the section.

**Projected total ≈ 145 lines — well under the I.3 ≤300 cap** (AC-7). Headroom > 150 lines.

## 11. Out-of-scope clarifications

1. **No design-it-twice procedure.** Named only, inside the single deferred-pointer line; no
   parallel-subagent dispatch shape, no procedure (RA out-of-scope #1; AC-5).
2. **No DEEPENING four-category taxonomy reproduced.** The four category names appear only inside the
   same one-line deferred pointer as a future extension; no ports-&-adapters / replace-don't-layer
   detail (RA out-of-scope #2; AC-5).
3. **No change to the `02_SOLUTION_DESIGN.md` output structure** (sections 1-12) — the lens adds no
   required field (AC-4).
4. **No mandate** that the architect use the vocabulary in any design (no railroading; RA out-of-scope #4).
5. **No new `verify_all` check, gate, or guard, and no I.6 banned/exempt-list change** (RA out-of-scope #5).
6. **No count change** — 16 skills / 8 framework agents / 32 checks stay literally unchanged (RA out-of-scope #6).
7. **No edit to other agents, to `.harness/rules/15-skill-authoring.md`, or to `CONTEXT.md`.** The
   vocabulary MAY later seed `CONTEXT.md` (T-02) — a future option, explicitly not this task (RA
   out-of-scope #7/#8). The "leading word" handle is consumed, not changed.
8. **No sync / no `.claude/` edit / no template copy** — framework agents are plugin-native (RA
   out-of-scope #9).

## Partition assignment

**Omitted — single Developer mode.** No `.harness/agents/dev-*.md` partition agents exist in this
repo (confirmed: glob `.harness/agents/dev-*.md` → none). The plugin `harness-kit:developer`
implements all six file edits in this dependency order: (1) `agents/solution-architect.md` section
append; (2) the four version stamps (plugin.json, marketplace.json, README.md, README.zh-CN.md);
(3) the `CHANGELOG.md [0.38.0]` entry; (4) run `verify_all`. Steps 1-3 are mutually independent
content edits; step 4 depends on 1-3.

## 12. Verdict

**READY.**

Rationale: Mode `full`, upstream RA `READY`. The design specifies the EXACT verbatim section (§3),
its precise insertion point (append as the last `##` section, after the line-122
"What bad looks like" block), the byte-unchanged 12-section output contract, the five version
surfaces + CHANGELOG entry (§9), and a projected total of ~145 lines (≤300, §10). The section is an
OPTIONAL lens framed with three independent affordance signals ("(optional lens)" heading + **may** +
"leading words to think with, not a checklist / not a required field") and is NOT tied to any
required `02_SOLUTION_DESIGN.md` field (AC-4, no railroad). Counts stay 16 / 8 / 32 with no new check
and no I.6 list change. All 9 acceptance criteria are addressed; all source meanings are pinned to
`codebase-design/SKILL.md`. A junior developer can implement this without further design decisions.

PM may advance to Stage 3 (Gate Reviewer).
