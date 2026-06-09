# 03 — Gate Review · T-015 / zh-overlay-anglicize

> Stage 3. Gate Reviewer (read-only). Persisted by PM. Full-mode verdict: **APPROVED** (the review used
> plan-mode "APPROVED FOR DEVELOPMENT" wording per the dispatch; equivalent = APPROVED, advance to Dev).

## Verdict: APPROVED — 0 BLOCKING, 7 ADVISORY

Every load-bearing claim verified TRUE against live code; design is implementable without further design decisions.

## The 3 crux verifications (all CONFIRMED)
1. **OQ-3=(A) finding — TRUE.** `language-policy.sh:77-81` (zh) sets `tmpl_common=.../i18n/zh/common`, reads
   `00-core.md.tmpl` + `CLAUDE.md.tmpl` from it, and `exit 1`s if absent (sh:83-90 / ps1:80-87). Deleting
   F-2/F-7 (option B) would permanently break `/harness-language zh`. (A) is correct; (B) genuinely infeasible.
2. **SPECIAL splice / no double-section — SAFE.** en `00-core.md.tmpl:9` = `## Output language (project-wide)`
   (section 9-22); zh `:9` = `## 输出语言（按消费者分流）` (section 9-31). "Replace not append" → exactly one
   (Chinese) policy section. The inverse trio (assert `## Hard rules (red lines)` PRESENT, `Output language
   (project-wide)` ABSENT, `输出语言（按消费者分流）` PRESENT) genuinely guards the double-section bug.
3. **No existing test requires a deleted file — SAFE.** All 4 existing zh assertions (test-init sh:523-526 /
   ps1:625-628) target `00-core.md` (a SPECIAL file that STAYS). Its preserved zh block holds both AC-8 markers
   `给用户的交付总结` (zh:17) + `commit message` (zh:25) and has no `全程` → existing assertions still pass. No
   assertion references any of the 11 deleted files. No landmine.

## 8-dimension audit: all PASS
Requirement/design completeness, reuse correctness (overlay fall-through SKILL.md:104-108 + T-014 dependency
+ test-init harness all real), risk coverage, migration safety (EN path byte-identical; T-014 preserved; git
revert rollback), boundary handling, test feasibility (all §7 marker pairs verified collision-free), out-of-scope clarity.

## Findings (all ADVISORY)
- **F-1 (most important) — type-dir inverse assertion is VACUOUS.** test-init's zh fixture layers only
  common→fullstack→i18n/zh/common (sh:518-520) — it NEVER layers `i18n/zh/fullstack`, so the English
  `50-fullstack.md` ships ALREADY, pre-deletion. An EN-marker assertion on it passes regardless of F-14/15/16
  deletion → does NOT exercise the deletion. Dev must either (a) add an `i18n/zh/fullstack` fixture layer to
  make it meaningful, OR (b) drop the "covered" claim and treat the 3 type-dir deletions as AUDIT-ONLY (EN
  target confirmed present). Do NOT ship a vacuous assertion that implies coverage it lacks (honest-coverage).
- **F-2** — design §4.1 fence says zh block `:9-32`; actual is `:9-31` (line 32 = blank). Verbatim text is
  byte-correct. Cosmetic.
- **F-3** — OQ-3 finding cites `ps1:80` for the guard; actual guard `ps1:80-87`/`sh:83-90`. Materially correct.
- **F-4** — helper path label: real shipped helper at `skills/harness-init/templates/common/.harness/scripts/`
  (+ dogfood copy `.harness/scripts/`). Dev does NOT edit it (it only READS the SPECIAL files). Informational.
- **F-5** — type-dir EN targets at `templates/{type}/.harness/rules/50-*.md(.tmpl)` (NOT under common/).
  Confirmed present. EN marker `## Fullstack-specific rules` (50-fullstack.md:3) is a clean choice.
- **F-6 (Dev obligation)** — README test-init badge + baseline.json (`test_init_ps_assertions:255`,
  `test_init_bash_no_python3_assertions:217`) MUST come from a real two-shell run, never hand-estimated
  (insight 2026-06-04). The most error-prone mechanical step.
- **F-7** — mode/verdict vocabulary mismatch (dispatch used plan-mode words; this is full mode). Full-mode verdict = APPROVED.

## Pre-answered Dev questions
1. Edit NO `language-policy` file — it only READS F-2/F-7 (that's why they stay); editing F-2's English body
   doesn't affect T-014 (it extracts only the `输出语言（按消费者分流）` section you preserve verbatim).
2. F-2 splice: keep en header `:1-7` (placeholders) verbatim, REPLACE en policy `:9-22` with the zh block
   (zh `:9-31`), keep en body `:24-77` verbatim. Write full file (L10), re-Read, confirm `## Hard rules (red
   lines)` AND `## 输出语言（按消费者分流）` both present, `Output language (project-wide)` ABSENT.
3. Type-dir EN marker `## Fullstack-specific rules` — but see F-1 (won't exercise the deletion unless you add the fixture layer).
4. Keeping the zh policy won't trip I.6 (no `全程` in the preserved block; CHANGELOG/docs exempt). Don't write `全程...中文` in SKILL.md/READMEs/AI-GUIDE/test-init.
5. Baseline: run test-init BOTH shells, paste the real PS + bash-no-python3 totals into baseline.json + both README badges. Never estimate.

## Top 3 for the Developer
1. **Single-section invariant (R-3):** splice REPLACES the English policy section — never leave both. The `Output language (project-wide)` ABSENT assertion is the guard.
2. **Baseline + badge from a captured two-shell run (F-6):** most likely G.3/G.4/baseline-drift failure point.
3. **Type-dir coverage honesty (F-1):** don't trust/ship the vacuous `50-fullstack.md` assertion — make it meaningful or label the 3 type-dir deletions audit-only.
