# 03 — Gate Review · ai-native-init (T-002)

Mode: `full` · Stage: 3/7 · Author: Gate Reviewer (read-only role; persisted by PM) · Date: 2026-05-19

## Eight-dimension audit

| # | Dimension | Verdict | Justification |
|---|---|---|---|
| 1 | Requirements ↔ Design alignment | PASS | Every FR (FR-1…FR-11) and AC (AC-1…AC-12) maps to a §4 change-set entry and a §10 test assertion. Bidirectional opt-out / opt-in (AC-3 + AC-10) lives in 02_SOLUTION_DESIGN.md:220-223. |
| 2 | Code-citation accuracy | WARN | Most citations resolve (table below). One factual claim is wrong: §7 says section list matches `templates/fullstack/.harness/rules/50-fullstack.md`, but that file's headings are `Partition Developers / API contracts / Database`. Match is actually with `templates/generic/.harness/rules/50-generic.md.tmpl`. |
| 3 | Reuse audit credibility | PASS | All 9 §5 reuse entries resolve and contain what is claimed. |
| 4 | Risk coverage | PASS | All 8 requirement-level risks have countermeasures in §13; architect added R9 (AI-GUIDE drift) and R10 (i18n/zh) plus explicitly-accepted residual (build-command invention). |
| 5 | Backwards compatibility | PASS | AC-10 + §10 rows 1+2 give a byte-identical proof for opt-out. NFR-Compat-2 makes it a hard requirement. Default Q6=No (decision Q2) means opt-out is the no-action path. |
| 6 | Documentation discipline | WARN | Design touches all four insight-index-line-14 hot spots. **Missing**: design bumps `AI-GUIDE.md:67` ("28 checks at v0.15.1") but misses parallel claim at `AI-GUIDE.md:35` ("28/28 at v0.15.1"). Both must be bumped. |
| 7 | Self-consistency | PASS | Layer-1 (10-self-consistency.md:5-11) explicitly preserved — all 7 agent files listed under "NOT touched". Layer-2 preserved (AI step writes to `.harness/`). D.2 placeholder whitelist unchanged. D.3 doesn't conflict. |
| 8 | Testability | PASS | `HARNESS_AI_NATIVE_MOCK` env-var pattern parallels existing `init_have_python` gate at `test-init.sh:198-201`. §10's 14 assertions cover AC-1…AC-12 plus boundary FR-5. |

## Cited-code sanity sweep (representative entries)

| Cited reference | Match? | Notes |
|---|---|---|
| `README.md:256` v0.16+ planned row | Y | Will be flipped to "done". |
| `01_REQUIREMENT_ANALYSIS.md:73` NFR-Compat-2 | Y | — |
| `skills/harness-init/SKILL.md:46-75` (Q1-Q5) | Y | — |
| `skills/harness-init/SKILL.md:90-145` (template copy + substitution) | Y | — |
| `skills/harness-adopt/SKILL.md:48-65` (reconnaissance) | Y | — |
| `scripts/verify_all.ps1:88` (7-agent array) | Y | — |
| `scripts/verify_all.ps1:93-107` (D.2) | Y | — |
| `scripts/verify_all.ps1:94` ({{PROJECT_NAME}}+{{PROJECT_TYPE}}) | Y | — |
| `scripts/verify_all.ps1:141-173` (E.4b) | Y | — |
| `scripts/verify_all.ps1:284-296` (I.2) | Y | — |
| `scripts/verify_all.sh:74-84` / `:126-152` / `:282-294` | Y | — |
| `templates/common/AI-GUIDE.md.tmpl:23` (`50-{{PROJECT_TYPE}}.md` hard-code) | Y | — |
| `templates/fullstack/.harness/rules/50-fullstack.md` skeleton match (§7) | **N** | Misleading; matches `50-generic.md.tmpl`, not 50-fullstack. |
| `scripts/test-init.ps1:230-249` (claimed bidirectional) | **N** | Actual bidirectional E.5 assertion is at `test-init.ps1:195-205`. Cosmetic mis-pointer. |
| `AI-GUIDE.md:67` ("28 checks at v0.15.1") | Y | But parallel `AI-GUIDE.md:35` ("28/28 at v0.15.1") missed in §4. |

Overall: 19 of 21 spot-checked citations resolve correctly; 2 are cosmetic mis-pointers (Findings B + C below).

## Findings — Dev-time conditions

### Finding A (Must) — `templates/i18n/zh/common/AI-GUIDE.md.tmpl` IS present
Design §14 issue 1 says "zh overlay likely does NOT have its own AI-GUIDE.md.tmpl". Gate verified: the file exists and contains the same hard-coded `50-{{PROJECT_TYPE}}.md` reference. The conditional replacement is **required, not optional**. Developer must treat as a hard subtask; the zh path cannot be silently skipped.

### Finding B (Cosmetic) — `test-init.ps1:230-249` mis-citation in Decision §3 Q2 rationale
Design says "opt-in default would silently break the bidirectional test in `scripts/test-init.ps1:230-249`". Actual lines 230-249 are the placeholder-leak cleanliness block; the genuine bidirectional E.5 assertion lives at `test-init.ps1:195-205` (bash twin at `test-init.sh:158-167`). Rationale stands.

### Finding C (Cosmetic) — Skeleton-match citation (§7) points at wrong file
Design §7 claims six section headings "match `templates/fullstack/.harness/rules/50-fullstack.md` skeleton". They actually match the generic template. The mandate itself (six fixed headings) is internally consistent.

### Finding D (Must) — `AI-GUIDE.md:35` check-count claim also needs bump
Design §9 bumps `AI-GUIDE.md:67` from "28 checks at v0.15.1" → "29 checks at v0.16.0". `AI-GUIDE.md:35` ALSO says "28/28 at v0.15.1; check count grows with releases" and is missing from §4. Add it.

### Finding E (PASS confirmation) — D.2 captures 7 placeholders; no new placeholder needed
Verified `verify_all.ps1:94`. Design's claim that no new placeholder is introduced (decision Q4 rationale) is correct.

### Finding F (Must) — Re-Read discipline applies to ALL Writes/Edits in this task
Insight-index line 10 covers (i) writing `50-<project-slug>.md` and (ii) editing AI-GUIDE.md to swap the index line. Design §6 covers both. Same discipline must apply to (iii) the **zh** AI-GUIDE.md.tmpl edit and (iv) the new `_ai-native-prompt.md` shipped file. Developer should make re-Read mandatory for every Write/Edit in this task.

### Finding G (Should) — D.3 "≥1 source annotation" is too lax
Design §9 says D.3 asserts ≥1 `<!-- source: ... -->` annotation. AC-7 is stronger: "Every `##` or `###` section whose content is non-template includes at least one `<!-- source: ... -->` comment". D.3 should be tightened to per-section, not file-global, to keep verify_all and AC-7 aligned.

### Finding H (PASS confirmation) — Mock-fixture path consistency
After template copy step 4, the shipped `templates/common/scripts/ai-native-mock.json` lands at `<tempdir>/scripts/ai-native-mock.json`. Consistent with §10 test setup. No issue.

## Open-issues review (Design §14)

| # | Open issue | Gate decision |
|---|---|---|
| 1 | zh AI-GUIDE.md.tmpl presence | **Resolve at Dev time** — verified present (Finding A). Required subtask. |
| 2 | Exact v0.16.0 CHANGELOG wording | **Resolve at Dev time** — copywriting; covered at release-prep step. |
| 3 | Test-init assertion count after change | **Resolve at Dev time** — Developer measures post-implementation count; writes new number into `docs/manual-e2e-test.md` AND any AI-GUIDE.md sentence referring to it. |

None of the three is design-blocking.

## Pre-answered Developer questions

| Question | Answer |
|---|---|
| When `HARNESS_AI_NATIVE_MOCK` is set, skip live AI call? | **Yes** — env-var's content IS the AI response (§3 A3, §6 step 5b.4). |
| Delete `50-<type>.md` before or after writing `50-<slug>.md`? | **After** (§6 step 5b.7) — write, re-Read, then delete. Keep static stub on write/read failure. |
| User's cwd basename fails the slug regex? | Developer must define a sanitizer (lowercase, replace non-matching chars with `-`, trim to 40 chars, leading-digit rule). Document in 04. |
| How to "AI call" inside SKILL.md without a real tool? | The orchestrator AI does the completion inline. In tests, `HARNESS_AI_NATIVE_MOCK` short-circuits. No new MCP / tool surface. |
| Inter-partition name collisions? | AI prompt must propose distinct names; duplicate proposals dropped after the first. Add to prompt. |

## Verdict

# `APPROVED FOR DEVELOPMENT`

Dev-time conditions to honor (must): Finding A (zh AI-GUIDE.md.tmpl edit), Finding D (AI-GUIDE.md:35 also bumps), Finding F (re-Read every Write/Edit), Finding G (D.3 per-section annotation check).
Dev-time conditions to honor (should): Findings B, C cosmetic citation fixes; not blocking. Findings E, H are PASS confirmations, no action.
