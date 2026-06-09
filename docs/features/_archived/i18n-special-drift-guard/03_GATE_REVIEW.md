# 03 — Gate Review · T-016 / i18n-special-drift-guard

> Stage 3. Gate Reviewer (read-only). Persisted by PM. All claims verified against live code (2026-06-09).
> Direction: ELIMINATE (per user steer — root-cause redesign over guard accretion; check count stays 32).

## Verdict: APPROVED FOR DEVELOPMENT — 0 BLOCKING, 4 ADVISORY

ELIMINATE is feasible and code-grounded. Every make-or-break claim verified true. Residual risk is entirely
the CJK byte-fidelity of the one new file (M-1) — well-identified (R-1/R-2), with one backstop caveat (F-1).

## 8-dimension audit: all PASS
Requirement/design completeness, reuse correctness (the helper's `extract_section_to` sh:120-134 /
`Get-SectionLines` ps1:136-150 + line locators resolve BOTH the section and the line from one combined file,
zero logic change), risk coverage, migration safety (en path byte-unchanged; already-generated projects
untouched; git rollback), boundary handling, test feasibility, out-of-scope clarity (NO verify_all check added
— anti-bloat confirmed).

## The 3 crux verifications (all CONFIRMED)
1. **init-composition feasible.** (a) init runs scripts mid-flow — SKILL.md step 6 `harness-sync` (288-296) is
   a real shell call; a post-copy `language-policy --lang zh` is the same shape. (b) the helper ships into the
   project (`templates/common/.harness/scripts/language-policy.{ps1,sh}`, laid by step 4.1). (c) `/harness-language`
   already does this exact zh injection (REWRITE-SECTION/LINE sh:207-300; test-language #9 byte-identity 229-244;
   baseline 39/39). → does NOT collapse; no re-route to GUARD.
2. **`_policy/` snippet OUTSIDE every overlay layer.** All 3 copy paths copy `i18n/zh/common/` + `i18n/zh/<type>/`
   (init SKILL §4.3; test-init `copy_layer .../i18n/zh/common` sh:520/ps1:622; adopt SKILL:279) — NEVER `i18n/zh/`
   itself. A `_policy/` sibling of `common/` is never enumerated → never ships into a project. Grep `_policy` = 0 collisions.
3. **No other readers of the 3 deleted files.** Independent grep: only runtime reader = `language-policy.{sh,ps1}`
   (re-pointed); only test reader = test-init (re-modelled); SKILL.md init+adopt = doc-prose (edited). All other
   hits archival (CHANGELOG/_archived/insight-index). Deletion safe (clears insight :39 dual-purpose warning).

## Findings (all ADVISORY)
- **F-1 (most important) — test-language #9 is NOT a sufficient backstop for M-1's CJK bytes.** #9 proves
  zh→en→zh self-CONSISTENCY of whatever M-1 says — NOT that M-1's bytes equal the OLD SPECIAL files'. A mis-copied
  CJK glyph passes #9 (round-trips consistently) AND passes the §7.3 body-match (it compares only the English body).
  insight :38 warns within-shell round-trip ≠ cross-shell parity. The ONLY real guard is the design's R-1/R-2
  **pre-delete `cmp`**: extract the section/line from M-1 via the helper and `cmp` against the same extraction from
  F-2/F-7 BEFORE deleting them. Elevate this from "mitigation" to THE load-bearing dev step.
- **F-2 — section span is 9 through the trailing blank (≈9-32), not "9-31."** `extract_section_to` captures
  `[heading, next "## ")` incl. the trailing blank line (zh 00-core: 31 last content, 32 blank, 33 next `##`).
  Design §3.3 says this correctly; the §3.2 "9-31" label is one short. Copy the FULL inclusive span.
- **F-3 — §0 mischaracterizes SKILL step 5b as a mid-flow script run** (it's an inline orchestrator-model draft,
  SKILL:159-161; `HARNESS_AI_NATIVE_MOCK` short-circuits the model call, not a shell script). Cosmetic — step 6
  substantiates "init runs scripts." Verdict unaffected.
- **F-4 — adopt's "Language handling" block (harness-adopt/SKILL.md:275-284) is free prose, not a numbered step.**
  M-10 must (a) drop `00-core.md.tmpl` from the line-281 "translates" list and (b) add the injection instruction
  in adopt's idiom (mirror init step 4.4; don't assume a symmetric step number).

## Pre-answered Dev questions
1. **M-1 source/order:** region A = `i18n/zh/common/.harness/rules/00-core.md.tmpl` line 9 (`## 输出语言（按消费者分流）`)
   through line 32 (trailing blank); region B = `i18n/zh/common/CLAUDE.md.tmpl` line 3 verbatim. A, then a sentinel,
   then B. COPY never re-type (F-1). Do BEFORE deleting F-2/F-7/F-8.
2. **Prove M-1 correct:** run the helper against a throwaway fixture once with OLD path, once with M-1; `cmp` the
   resulting 00-core section + CLAUDE line. (Or awk-extract with the same anchors + `cmp`.) This is the real backstop.
3. **`extract_line_to` won't grab a section line:** the section's last content line contains `输出语言` but doesn't
   start `^输出语言：`; the first `^输出语言：` is the policy line after the sentinel. Verified both shells.
4. **Count:** NO check added; G.4 derives 32 from the live tally (verify_all.sh:714,727). Edit ONLY the version
   token 0.26.0→0.27.0 at plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5 — leave
   `verify__all-32%2F32` / `test--init-274%2F274` / `integration-82%2F82` byte-exact (L36).
5. **baseline counts:** paste the ACTUAL captured two-shell test-init totals (SA estimates ps 274→275 / bash 236→237
   but CAPTURE, don't ship the estimate); test_language stays 39/39; update the README test-init badge only if the captured PS total changed.

## Top 3 for the Developer
1. **M-1 by COPY + pre-delete `cmp` (F-1)** — neither #9 nor the body-match catches a drifted CJK glyph. Get M-1
   right and prove it BEFORE deleting the originals.
2. **Copy the full section span incl. the trailing blank (F-2).**
3. **Re-point both shells + sync-self the dogfood mirror; run test-language (39/39) + test-init + verify_all both
   shells; confirm `/harness-language zh` + en both still resolve; en path byte-unchanged.**
