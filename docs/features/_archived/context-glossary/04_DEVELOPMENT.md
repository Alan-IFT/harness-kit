# Development Record — context-glossary (T-02)

**Mode:** full · **Stage:** 4 (Developer) · **Date:** 2026-06-19
**Upstream:** `03_GATE_REVIEW.md` = APPROVED FOR DEVELOPMENT. Design (`02_SOLUTION_DESIGN.md`) implemented exactly.

## Summary

Added a `CONTEXT.md` domain-glossary memory layer as the proven dual-purpose pattern: a real
dogfood file at the repo root (this repo's genuine vocabulary) and a generic, placeholder-free
template seed that every `/harness-init` project receives at its root. Wired it into the
requirement-analyst and solution-architect contracts as a token-light SOFT dependency, indexed
it once in the AI-GUIDE memory layer, recorded it in dev-map, added a symmetric seed-present
test-init assertion in both shells, and bumped the version to 0.34.0. No new `verify_all` check
(count stays 32), no new template placeholder (whitelist stays 7).

## Files changed

**New (2):**
- `CONTEXT.md` (repo root) — dogfood glossary. `# Harness Kit` title + 1-2 sentence context
  description (with the single-context / future `CONTEXT-MAP.md` parenthetical) + `## Language`
  with 13 real harness-kit terms (frontier, pool, ambient mode, partition agent, stage doc,
  verdict, insight, rollback, dogfood, template overlay, soft dependency, hard dependency, gate),
  each a bold term + 1-2 sentence definition + `_Avoid_:` synonyms. Glossary only, no
  implementation detail / no file-path-as-definition. Trailing multi-context future note (OQ-5).
- `skills/harness-init/templates/common/CONTEXT.md` — generic, placeholder-free seed.
  `# {Your Project}` (single brace, mixed case), an instruction line telling the project to list
  its domain terms in the `_Avoid_` format, and two illustrative example stubs (`ExampleTerm`,
  `AnotherTerm`). Distinct content from the dogfood file (AC-3); ships verbatim (plain `.md`, not
  `.tmpl`).

**Edited (10):**
- `agents/requirement-analyst.md` — new Workflow step 7 (SOFT-dependency CONTEXT.md sentence,
  verbatim from design §3.3); steps 7-10 renumbered to 8-11.
- `agents/solution-architect.md` — new Workflow step 5 (analogous SOFT-dependency sentence);
  steps 5-10 renumbered to 6-11.
- `AI-GUIDE.md` — one new Memory-layer bullet for `CONTEXT.md` (description + when-to-read
  trigger), after the `decision-rubric.md` entry. File now 110 lines (≤200, I.1).
- `docs/dev-map.md` — one "Where features live" row for the dual `CONTEXT.md` location, after
  the `Project templates` row. The two `32 checks` claim strings (lines 60/133-region) untouched.
- `.harness/scripts/test-init.ps1` — `Assert "CONTEXT.md seed present (generic glossary)"` after
  the `decision-rubric.md` assertions.
- `.harness/scripts/test-init.sh` — symmetric `assert "CONTEXT.md seed present (generic glossary)"`
  in the same position.
- `.claude-plugin/plugin.json` — `version` 0.33.0 → 0.34.0.
- `.claude-plugin/marketplace.json` — `plugins[0].version` 0.33.0 → 0.34.0.
- `README.md` — `version-0.34.0` badge (the `test--init-` badge LEFT AS-IS — see "PM must run").
- `README.zh-CN.md` — `version-0.34.0` badge (the `test--init-` badge LEFT AS-IS).
- `CHANGELOG.md` — new `## [0.34.0] - 2026-06-19` entry describing the glossary asset + SOFT
  wiring + the no-new-check / placeholder-stays-7 / count-stays-32 notes.

## verify_all result

Ran `.harness/scripts/verify_all.sh` (Bash available in this sub-agent; PowerShell denied):

- Baseline (before edits): not separately captured this session, but the repo was clean at
  HEAD 93fbfbb with verify_all green at 32/32.
- **After changes: PASS 32 · WARN 0 · FAIL 0** (full green).
- Delta: 0 new failures. G.3 (version stamps consistent) PASS — 0.34.0 agrees across
  plugin.json / marketplace.json / both README version badges. G.4 (count/version claims) PASS —
  CHANGELOG `[0.34.0]` heading present, check count still 32. I.6 (retired-claim guard) PASS — no
  banned anchor in the new dogfood/seed/agent/AI-GUIDE/dev-map text. I.1/I.2/I.3 doc-size caps PASS.

Regression runs (Bash side only — PowerShell denied for sub-agents):
- `test-init.sh`: **273 PASS / 0 FAIL** (was 270; +3 = the new seed-present assertion × 3 project
  types). Includes the recursive no-unresolved-placeholder scan over the generated seed (auto-covers
  AC-3 placeholder-free).
- `test-real-project.sh`: **90 PASS / 0 FAIL** — unchanged (driver has no per-asset count; the seed
  rides the overlay). `test_real_project_*` baseline fields stay at 90/90.

## AC self-review (read-back against 01 §5)

- **AC-1** PASS — root `CONTEXT.md` opens with `# Harness Kit` + 1-2 sentence description; `## Language`
  with 13 entries, each bold term + 1-2 sentence def + `_Avoid_:` line (≥3 satisfied; aimed ~8-12, has 13).
- **AC-2** PASS — every term is harness-kit-specific, drawn from the behavior-3 candidate set; no general
  programming concepts.
- **AC-3** PASS — seed present under `templates/common/`, `grep -c '{{'` returns 0, and `diff` vs root
  dogfood reports DIFFER (verified this session).
- **AC-4** PASS — requirement-analyst.md Workflow step 7 = read-if-present + lazy-maintain-inline +
  "convenience, never a precondition"; no setup pointer, no BLOCKED-on-absent.
- **AC-5** PASS — solution-architect.md Workflow step 5 = analogous; "it never blocks the design."
- **AC-6** PASS — AI-GUIDE Memory-layer has exactly one new `CONTEXT.md` bullet; file 110 lines (≤200).
- **AC-7** PASS — dev-map "Where features live" row records both the root dogfood and the template seed path.
- **AC-8** PASS (Bash) — verify_all 32/32, count unchanged at 32. **PowerShell side: PM to confirm** (denied here).
- **AC-9** PARTIAL — test-init.sh + test-real-project.sh green (Bash). **PS test-init + baseline reconcile:
  PM to run** (see below). test-real-project total unchanged at 90/90.
- **AC-10** PASS — I.6 scan green; no banned-anchor phrase in any added/edited file.

## Design drift

None. The two agent sentences are pasted verbatim from design §3.3; the AI-GUIDE line, dev-map row, and
version-stamp set match §3.4/§3.5/§5 exactly. The dogfood glossary has 13 terms (design said ≥3, "aim
~8-12"); 13 is within the intended spirit and all are from the sanctioned candidate set — not a drift.

## Open issues for review

None blocking. The only outstanding work is the PowerShell-side capture + baseline reconcile, which this
runtime cannot perform (PowerShell denied for sub-agents) — see below.

## BLOCKED ON CAPABILITY (PM must run) — PowerShell + baseline + test-init badge

This runtime denies PowerShell to sub-agents, so I could NOT run the `.ps1` regressions and MUST NOT
hand-guess their tallies (insight 2026-06-04 — fabricated tallies). The PM must:

1. **Run `verify_all.ps1`** → confirm 32/32 PASS (Bash side already green here).
2. **Run `test-init.ps1`** → capture its total PASS count.
3. **Run `test-init.sh`** → captured here as **273** (PM may re-confirm).
4. **Run `test-real-project.ps1`** → capture its total (Bash side captured here = **90**, unchanged).
5. **Reconcile `baseline.json`** from the captured runs:
   - `test_init_ps_assertions` (currently 308) → the captured `test-init.ps1` total.
   - `test_init_bash_no_python3_assertions` (currently 270) → the captured `test-init.sh` total
     (this session's run shows **273**; PM confirms).
   - `test_real_project_*` (currently 90/90) → leave at 90/90 if the captured runs still show 90 (they do
     on the Bash side).
6. **Update BOTH README `test--init-308%2F308` badges** (README.md:5, README.zh-CN.md:5) to the captured
   `test-init.ps1` total. I deliberately left these badges unchanged — no gate catches them (G.3 checks only
   `version-`, G.4 only `verify__all-`), and they must reflect the real captured number, not a guess.

I left the `baseline.json` `test_init_*` fields and the README `test--init-` badges at their pre-task values
on purpose, per F-1 and the no-fabricated-tally insight.

## Dev-map updates

Added one row to the "Where features live" table:
`| Domain glossary (`CONTEXT.md`) | repo-root `CONTEXT.md` (dogfood, real terms) + skills/harness-init/templates/common/CONTEXT.md (generic seed) | Dual-purpose like decision-rubric.md … Single context; multi-context via a future root CONTEXT-MAP.md. |`
No top-level-layout tree edit was needed (the table row is the AC-7 satisfier; the tree note was optional in design §3.5).

## Verdict

READY FOR REVIEW
