# 02 — Solution Design — durable-brief (T-05)

**Mode:** full · **Stage:** 2 (Solution Architect) · **Verdict:** see §12
**Upstream:** `01_REQUIREMENT_ANALYSIS.md` verdict = READY (8 in-scope behaviors, 9 ACs, 4 OQs all recommended-answered).
**OQ defaults adopted (PM-accepted):** OQ-1 → (c) Hard rule + good/bad pair · OQ-2 → (a) boundary single-sourced in RA, PM one-liner references not restates · OQ-3 → (a) bump 0.35.0 → 0.36.0 · OQ-4 → (a) generic exemplar, repo-specific nuance carried by the RA boundary clause.
**deferred-human mode:** defer, do not ask.

## 1. Architecture summary

A documentation-only, additive change to two plugin-native shipped agent contracts. `agents/requirement-analyst.md` gains a new Hard rule (durability discipline: behavioral-not-procedural requirement prose, no forward-looking file-path/line-number anchors, with an explicit EVIDENCE-citation exemption clause) plus one good/bad exemplar pair in its existing "What good / bad looks like" lists. `agents/pm-orchestrator.md` gains one terse dispatch-contract line stating that dispatch prompts carry behavioral intent + acceptance criteria + scope boundary (not procedural file:line), referencing — not restating — the RA boundary clause. The forward/backward boundary is **single-sourced in the RA file**. No routing, no output-structure, no rule, no gate, no count changes. Because `agents/*.md` are plugin-native shipped assets, the edit is a shipped-behavior change: minor version bump 0.35.0 → 0.36.0 with a CHANGELOG entry and the standing version-stamp fan-out, all counts held constant.

## 2. Affected modules

| File | Change | Why |
|---|---|---|
| `agents/requirement-analyst.md` | edit (add Hard rule 6 + 1 good entry + 1 bad entry) | owns the forward-looking requirement spec (the "brief"); authoritative home of the boundary clause |
| `agents/pm-orchestrator.md` | edit (add 1 dispatch-contract line) | writes per-stage dispatch prompts (also "briefs"); inherits the discipline by reference |
| `.claude-plugin/plugin.json` | edit (version 0.35.0 → 0.36.0) | G.3 stamp target; agent-CONTENT change is a shipped-behavior change |
| `.claude-plugin/marketplace.json` | edit (`plugins[0].version` → 0.36.0) | G.3 stamp target |
| `README.md` | edit (version badge → 0.36.0) | G.3 stamp target |
| `README.zh-CN.md` | edit (version badge → 0.36.0) | G.3 stamp target |
| `CHANGELOG.md` | edit (prepend `## [0.36.0]` entry) | G.4 claim/version consistency + release record |

No other file is touched. Specifically NOT touched (protected): `.harness/rules/05-insight-index.md`, `.harness/insight-index.md`, any stage-doc EVIDENCE convention, `docs/spec/`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.claude/`, any other agent, any `skills/harness-init/templates/` copy, any `verify_all` check.

## 3. Module decomposition

No new modules. Two prose insertions into existing agent contracts; the exact text is specified verbatim in §4–§5.

## 4. RA durability text (EXACT, additive)

### 4a. New Hard rule 6 — append to `agents/requirement-analyst.md`'s "Hard rules" list (after rule 5)

The discipline is behavioral, terse, and self-consistent (it names behaviors, not paths — it is its own exemplar, NFR-1). The EVIDENCE-exemption clause is the **single source** of the forward/backward boundary; nothing downstream restates it.

```markdown
6. **Behavioral, not procedural — and no forward-looking file:line anchors.** Write requirement statements by *what* the system does and by naming interfaces / types / contracts / config shapes — not by *how* to implement them. Forward-looking requirement prose (in-scope behaviors, acceptance criteria, boundary conditions — the brief the pipeline builds FROM) must NOT anchor to file paths or line numbers: they go stale across refactors and across the time a task waits. *(Exemption: this ban is on forward-looking requirement prose ONLY. Backward-looking **EVIDENCE** citations are exempt and KEEP citing path-and-line as proof — exactly as `.harness/rules/05-insight-index.md` and stage-doc EVIDENCE sections already require. The brief says what to build; evidence proves what was found.)*
```

Notes on the exact wording:
- "path-and-line" / "file paths or line numbers" are written as **prose descriptions of the concept**, never as a literal `name.ext:NNN` token — this keeps the rule from approaching an I.6 anchor and keeps it durable (NFR-1).
- The phrase "complete, testable acceptance criteria" is **deliberately NOT repeated** here — it already lives in "What you produce" §5 + "What good looks like" ("Every requirement is something a tester can verify"). The new rule says "acceptance criteria" only as one of the three forward-looking surfaces governed by the ban, reinforcing the existing requirement rather than adding a competing one (behavior 5 / AC-5-of-RA — i.e. RA in-scope behavior 5).
- The exemption clause names `.harness/rules/05-insight-index.md` and "stage-doc EVIDENCE sections" so a future editor understands *why* evidence is exempt but the brief is not (boundary condition: error-path/staleness rationale).

### 4b. Good/bad exemplar pair (generic, OQ-4 (a)) — into the existing lists

Append one entry to the **"What 'good' looks like"** bullet list:

```markdown
- A requirement names the behavior / interface / type, not the line it currently lives on — so it survives a refactor.
```

Append one entry to the **"What 'bad' looks like (avoid)"** bullet list:

```markdown
- "Change the field on the function around the middle of the handler file." → anchors a forward-looking requirement to a transient location; describe the interface and the desired behavior instead.
```

Notes on the exact wording:
- The "bad" exemplar is phrased as a *procedural location instruction in plain prose* ("the field on the function around the middle of the handler file") rather than a literal `path:line` token — this satisfies AC-2 (a behavioral-vs-procedural contrast pair) while avoiding writing a literal `file.ext:NN` sequence in a scanned file (boundary condition: self-trip / NFR-1; OQ-4 (a) rationale). It mirrors mattpocock's good/bad framing without copying his GitHub-issue template (out-of-scope 5).
- Generic by design (OQ-4 (a)): portable, terse, no repo-specific `file:line` token. The repo-specific forward/backward nuance is carried only by the boundary clause in 4a, not duplicated here.

## 5. PM dispatch one-liner (EXACT, additive)

### 5a. One line appended to `agents/pm-orchestrator.md`'s dispatch surface

OQ-2 (a): the boundary nuance is NOT restated in PM — PM points at the RA rule. Insertion point: the **"Cross-task memory (read at task start)"** section, immediately after the existing insight-surfacing paragraph (so the new line and the preserved `insight-index`-surfacing instruction sit adjacent, making AC-5-preservation obvious by proximity). Exact line:

```markdown
A dispatch prompt to a downstream stage carries the **behavioral intent + acceptance criteria + scope boundary**, not procedural file:line instructions — the same durability discipline the requirement-analyst's Hard rule 6 states (whose EVIDENCE-citation exemption is why the `insight-index` lines you surface above, which carry path-and-line evidence, stay unchanged).
```

Notes on the exact wording:
- "not procedural file:line instructions" appears as a **prose phrase**, not a literal `path.ext:NN` token — I.6-safe.
- It references "requirement-analyst's Hard rule 6" rather than re-explaining the forward/backward boundary → single-source (OQ-2 (a)), keeps PM's addition to exactly one line.
- The parenthetical explicitly ties the surfaced `insight-index` lines (which DO carry path-and-line evidence) to the RA exemption, which is precisely why behavior 4 must NOT weaken the existing insight-surfacing instruction (AC-5). The existing instruction in §"Cross-task memory" ("include the relevant line(s) in the dispatch prompt") stays byte-present and unmodified — the new line is appended after it, additive only (AC-9).

## 6. Sequence / flow (how the discipline propagates)

```
User request → INPUT.md
   │
   ▼
RA writes 01_REQUIREMENT_ANALYSIS.md
   │  Hard rule 6 (4a) governs the prose: behavioral, no forward file:line
   │  good/bad pair (4b) teaches the contrast
   │  EVIDENCE sections / cited insight lines still carry path-and-line (exemption)
   ▼
PM composes dispatch prompts (Task tool)
   │  dispatch line (5a): behavioral intent + AC + scope boundary, not procedural file:line
   │  surfaced insight-index lines (path-and-line evidence) preserved unchanged
   ▼
Downstream stages (SA / Dev / …) receive durable, refactor-resilient briefs
```

The change alters no control flow, no routing, no stage order — it sharpens the *content* of two artifacts already produced at the same points in the existing flow.

## 7. Reuse audit

| Need | Existing code/pattern | File path | Decision |
|---|---|---|---|
| Scope a ban to requirement prose while exempting a labelled construct | Hard rule 1's strip-list scoping (ban on requirement prose, `Recommended:` field exempt) | `agents/requirement-analyst.md` (Hard rule 1, set by T-03) | **Reuse the exact pattern** — model the new ban's "exemption clause" on rule 1's parenthetical-exception shape |
| Forward/backward evidence boundary (what may cite path-and-line) | EVIDENCE-citation contract (insight lines carry `file:line` as proof) | `.harness/rules/05-insight-index.md`, `.harness/insight-index.md` | **Reference, do NOT edit** — the RA exemption clause names these as the protected surface |
| Insight-surfacing into dispatch prompts | "Cross-task memory" instruction + insight-format example | `agents/pm-orchestrator.md` §"Cross-task memory" | **Reuse / preserve** — append the new line adjacent; do not weaken it |
| Good/bad exemplar framing | mattpocock durability principles + good/bad examples | `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\AGENT-BRIEF.md` (read-only) | **Adapt, do not import** — borrow the behavioral-vs-procedural framing; do NOT copy the GitHub-issue template (out-of-scope 5) |
| Additive terse agent-content edit + version bump, no count flip | T-02 (RA+architect → 0.34.0), T-03 (RA → 0.35.0), T-022 (PM → 0.33.0) | `docs/features/_archived/{context-glossary,harness-grill,stream-defer-human}/` | **Reuse the precedent** — same edit class, same bump-but-no-count-flip handling |
| Version stamp fan-out targets | G.3 check (4 stamps) + G.4 (claim↔version) | `.harness/scripts/verify_all.ps1:332-354`, CHANGELOG G.4 block | **Reuse the standing convention** — bump the 4 G.3 stamps + 1 CHANGELOG heading |
| I.6 banned-anchor list (avoid self-trip) | 14-entry banned list + exempt set | `.harness/scripts/verify_all.ps1:486-526` | **Read to verify** new text trips none — confirmed clean (§ risk R1) |

Reuse audit is non-empty and proves the code was read: the new ban is modelled on Hard rule 1's existing scoping pattern, and the I.6 list was inspected line-by-line to confirm no self-trip.

## 8. Risk analysis

- **R1 — self-trip on I.6 retired-claim guard (boundary condition: self-trip; this bit T-013).** *Mitigation:* the banned list (`verify_all.ps1:486-501`) contains only CLAUDE.md-composition/regeneration anchors, `scaffolding-only`, and `全程中文` — none overlap "behavioral", "procedural", "file path", "line number", "evidence", or "forward-looking". The §4–§5 text deliberately writes path-and-line as **prose concepts**, never as a literal `name.ext:NNN` token, in the rule, the exemplars, and (at delivery) the 07 insight harvest. No banned/exempt-list entry is added or changed → the four-file I.6 lockstep and `I6ExpectedEntryCount` (insight 2026-06-08) are untouched. Verified by the gate (AC-7).
- **R2 — the new ban reads as a blanket ban and contradicts `05-insight-index.md` (the #1 design tension).** *Mitigation:* the exemption clause (4a) is mandatory and single-sourced; AC-3 makes its absence an automatic rollback, AC-6 requires the protected files stay byte-unchanged. The clause names the exempt surfaces explicitly and states the rationale (brief goes stale; evidence proves what was found), so no reader can mistake it for a universal ban.
- **R3 — PM one-liner duplicates / drifts from the RA boundary nuance.** *Mitigation:* OQ-2 (a) — PM references "requirement-analyst's Hard rule 6" instead of restating the boundary; single source of truth, one line only, no duplicated nuance to drift.
- **R4 — version stamp mismatch fails G.3, or a count claim is accidentally flipped (T-008/T-010/T-03 count-ledger class).** *Mitigation:* bump all four G.3 stamps together (plugin.json, marketplace.json, both README badges) to 0.36.0; the CHANGELOG entry explicitly states counts unchanged (16 skills / 8 framework agents / 32 checks). NO count token is edited anywhere — this is a content edit, not a count flip (behavior 8). The verify_all C.1/G.1/G.2 skill-name arrays and the `harness-status` HEALTH denominator (insight 2026-06-19 decoy set) are NOT touched.
- **R5 — accidental non-additive edit (a reword deletes an existing rule/section).** *Mitigation:* every edit is a pure append (new list item / new line); AC-9 (`git diff` shows additions only) is the check. Target subsections ("Hard rules", "What good looks like", "What bad looks like", "Cross-task memory") were all confirmed present verbatim in the live files this stage (boundary condition: null/absent target section — not triggered).

## 9. Migration / rollout plan

No data, no API, no schema. Rollout sequence:

1. Edit `agents/requirement-analyst.md` (Hard rule 6 + good entry + bad entry) — §4.
2. Edit `agents/pm-orchestrator.md` (one dispatch line) — §5.
3. Bump version stamps to **0.36.0**: `.claude-plugin/plugin.json` (`version`), `.claude-plugin/marketplace.json` (`plugins[0].version`), `README.md` badge, `README.zh-CN.md` badge.
4. Prepend `## [0.36.0]` CHANGELOG entry (heading + body) — §10.
5. Run `.harness/scripts/verify_all` → expect 32/32 (PS run operator-pending per the standing deny-rule).

**Backwards compatibility:** total. The agents are plugin-native and auto-discovered; an updated contract takes effect on next dispatch. No consumer reads a removed surface. **Rollback:** `git revert` the single commit — there is no data migration to unwind. **Feature flags:** none needed (prose contract change).

## 10. Version + CHANGELOG (G.3 / G.4)

**Version bump:** 0.35.0 → **0.36.0** (MINOR — additive agent behavior, no count flip).

**G.3 stamp targets (all four bumped together):**

| Stamp | File | Field |
|---|---|---|
| plugin.json | `.claude-plugin/plugin.json` | `"version": "0.36.0"` |
| marketplace.json | `.claude-plugin/marketplace.json` | `plugins[0].version = "0.36.0"` |
| README badge | `README.md` | `version-0.36.0-blue` shield (line 5) |
| README.zh-CN badge | `README.zh-CN.md` | `version-0.36.0-blue` shield (line 5) |

**G.4 CHANGELOG (`[0.36.0]` heading prepended above `[0.35.0]`):**

```markdown
## [0.36.0] - 2026-06-20

### Added — durable-brief: durability discipline folded into the requirement-analyst + pm-orchestrator briefs (T-05)

The requirement-analyst and pm-orchestrator now write **durable, refactor-resilient briefs** — behavioral-not-procedural, with no forward-looking file-path/line-number anchors — adapted from mattpocock's "durability over precision" agent-brief principles. The discipline applies to the FORWARD-looking spec/brief only; backward-looking EVIDENCE citations (insight-index + stage-doc EVIDENCE) keep citing path-and-line as proof, and that boundary is single-sourced in the requirement-analyst.

- **`agents/requirement-analyst.md`**: a new Hard rule 6 — requirement prose is behavioral (names interfaces/types/contracts/config shapes), not procedural, and forward-looking requirement statements (in-scope behaviors, acceptance criteria, boundary conditions) carry no file-path/line-number anchors (they go stale across refactors and wait time). The rule carries an explicit EVIDENCE-citation exemption (single source of the forward/backward boundary): backward-looking evidence keeps citing path-and-line exactly as `.harness/rules/05-insight-index.md` and stage-doc EVIDENCE require. Plus one generic good/bad exemplar pair in the existing "What good / bad looks like" lists. The existing "complete, testable acceptance criteria" requirement is reinforced, not duplicated.
- **`agents/pm-orchestrator.md`**: one line in the dispatch contract — a dispatch prompt carries behavioral intent + acceptance criteria + scope boundary, not procedural file:line, referencing the requirement-analyst's Hard rule 6 (no restated nuance). The existing instruction to surface applicable `insight-index` lines (which carry path-and-line evidence) into dispatch prompts is preserved unchanged.
- Version 0.35.0 → 0.36.0 (plugin.json, marketplace.json, both README version badges). Counts unchanged: **16 skills / 8 framework agents / 32 checks**. No new `verify_all` check; no I.6 banned/exempt-list change; `.harness/rules/05-insight-index.md` and `.harness/insight-index.md` untouched (protected by the exemption); no template copy edited (agents are plugin-native, edited directly in top-level `agents/`).
```

The CHANGELOG body itself uses **prose** ("file-path/line-number", "path-and-line", "file:line") and never a literal `name.ext:NN` token — and CHANGELOG.md is in the I.6 exempt list anyway (`verify_all.ps1:517`), but it stays clean regardless.

## 11. Line-count projection (I.3 cap = 300)

| File | Before | Added | Projected after | Headroom |
|---|---|---|---|---|
| `agents/requirement-analyst.md` | 75 | +1 Hard-rule line + 1 good entry + 1 bad entry ≈ **+4** | **~79** | well under 300 |
| `agents/pm-orchestrator.md` | 207 | +1 dispatch line (+ at most 1 blank) ≈ **+2** | **~209** | well under 300 |

Both stay far below the 300-line I.3 cap (AC-7). Additions are terse per NFR-2.

## 12. Out-of-scope clarifications (design boundaries)

This design does NOT:
- add, remove, or reword any `verify_all` check, nor any I.6 banned/exempt entry (no new gate).
- change PM routing, rollback rules, mode table, intervention protocol, or the RA 9-section output structure / any existing Hard rule's substance.
- touch `.harness/rules/05-insight-index.md`, `.harness/insight-index.md`, `docs/spec/`, `CLAUDE.md`, `.github/copilot-instructions.md`, or `.claude/`.
- edit any agent other than `requirement-analyst` and `pm-orchestrator`, or any `skills/harness-init/templates/` copy (agents are plugin-native, edited directly in top-level `agents/` — no sync, no template copy).
- flip any count claim (16 skills / 8 framework agents / 32 checks all hold).
- import mattpocock's GitHub-issue template verbatim (the discipline is adapted to the harness brief format).
- restate the forward/backward boundary in the PM file (it is single-sourced in RA per OQ-2 (a)).

## 13. Partition assignment

**Omitted — not applicable.** No `.harness/agents/dev-*.md` partition agents exist in this repo (confirmed: glob `.harness/agents/dev-*.md` → none). The task runs in **single Developer mode**; the plugin `harness-kit:developer` implements all edits in dependency order: (1) the two `agents/*.md` content edits, (2) the four G.3 version stamps, (3) the CHANGELOG `[0.36.0]` entry, (4) `verify_all`.

## 14. Verdict

**READY.**

Rationale: the change is documentation-only and fully additive; every edit's exact text is specified verbatim (§4, §5, §10) so a developer needs no further design decision. The #1 design tension (forward brief vs backward evidence) is resolved by the single-sourced exemption clause in RA (§4a), referenced — not duplicated — by PM (§5a), satisfying AC-3 / AC-6. The four PM-accepted OQ defaults are all honored. The I.6 banned list was read line-by-line and the new prose trips none (§8 R1); the protected evidence-citation files are untouched (§8 R2, §12). Version handling follows the decisive repo precedent (§7, §10) with no count flip and no new check. Both agent files stay far under the I.3 cap (§11).
