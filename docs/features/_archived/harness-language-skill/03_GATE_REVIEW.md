# 03 — Gate Review · T-014 / harness-language-skill

> Stage 3. Gate Reviewer (read-only). Persisted by PM. Verified against the resolved baseline (7 OQs accepted).

## Verdict: APPROVED FOR DEVELOPMENT — 0 BLOCKING, 4 ADVISORY

Design is sound, code-grounded; the two highest-risk areas (section-locator foundation, I.6 self-trip) are verified correct.

## 8-dimension audit: all PASS
Requirement/design completeness, reuse correctness, risk coverage, migration safety (purely additive — no template policy CONTENT change → test-init stays green; git-clean + .bak rollback; no new placeholder), boundary handling, test feasibility, out-of-scope clarity — all PASS.

## Load-bearing claims verified against LIVE code
1. **Canonical headings EXACT.** en `## Output language (project-wide)` (common/00-core.md.tmpl:9, ends at `## How this project is developed`:24); zh `## 输出语言（按消费者分流）` (i18n/zh:9, ends at `## 这个项目怎么开发`:33). CLAUDE.md top lines + copilot top line (at :6, YAML frontmatter pushes it down) confirmed both langs. Locator's `^(Output language:|输出语言：)` anchor is line-number-independent. **Built on solid ground.**
2. **Locator idempotence/round-trip SOUND.** [START,next-`##`) slice + single-source-from-template = byte-stable. "Section is last" → END=EOF handled. "User lines inside section" → replaced by design (section is policy-owned; AC-5 surgical scope preserved). Trailing-blank off-by-one (en 9-23 / zh 9-32 inclusive of blank before next ##) is the one hazard → flagged R7, test #9 (byte-identical round-trip both shells) mitigates.
3. **Fan-out COMPLETE.** No `.harness/skills/` (Glob empty); 13 skills ship from `skills/<name>/` via plugin.json. Independent grep of 13 skills/thirteen/13 个/0.24.0/All 13 → every live site is in the design's 18-site list. G.1/G.2/C.1 match skill NAMES (grep -q "harness-language" at verify_all.sh:56,330,346 / .ps1:68,300,326) → README.md + CHANGELOG.md MUST contain `harness-language` literally. "Six task shapes" (README:15) = Pipeline group; new skill → Setup group (README:23-26, sibling of harness-upgrade), stays six. tasks.md:26 grep hit = T-013 history row → do NOT touch.
4. **Check count stays 32.** C.1/C.2/G.1/G.2 loop the array (no new Step); C.2 globs skills/**/SKILL.md (auto-covers new skill — needs valid frontmatter); F.1 name-only. G.4 derived count unaffected.
5. **I.6 self-trip avoidance VERIFIED SAFE (most important).** Banned anchor = `全程` within 40 chars of `中文` (verify_all.sh:536 / .ps1:501). The applied zh canonical text (i18n/zh 00-core.md.tmpl:9-31) contains `中文` repeatedly but NEVER `全程` (read in full) → APPLYING the policy is safe. Helper EXTRACTS (never embeds) prose → helper file safe. Only META-descriptions in SCANNED files are the risk. Exempt: CHANGELOG, docs/features/, verify_all.{ps1,sh}, test-verify-i6.{ps1,sh}, architecture.html, walkthrough.html, project-overview.html, 参考/. SCANNED (must paraphrase): SKILL.md, helper, test, AI-GUIDE, READMEs, getting-started, manual-e2e-test, 40-locations, harness-upgrade hint.
6. **No new {{...}} placeholder.** Policy sections have zero `{{…}}`; `{{LANG}}` is the init selector, not embedded. D.2 untouched.
7. **sync-self mirror = 6 explicit pairs** (sync-self.sh:62-83: harness-sync, install-hooks, archive-task, guard-rm, migrate-scripts-layout, upgrade-project) → adding language-policy = 7. E.1 (runs sync-self --check) enforces byte-identity. AI-GUIDE.md:71 "6 script pairs" prose → "7" in lockstep. (insight-index "4 scripts" is stale.)
8. **Helper root-derivation = cwd (correct).** upgrade-project.sh:13,45 precedent — pwd-derived, template via $TEMPLATE_ROOT. L31 two-up does NOT apply to a project-targeting tool reading pwd.

## Findings (all ADVISORY)
- **F-1**: helper real path is `skills/harness-init/templates/common/.harness/scripts/language-policy.{ps1,sh}` (where upgrade-project lives), NOT a literal top-level `templates/` (design §1/§2 shorthand). The §4/§3.1 full `<template-root>/skills/harness-init/templates/common/...` form is correct.
- **F-2**: marketplace.json `version` at **line 17** (design said :19). Grep the field, don't trust line numbers. plugin.json:4 correct.
- **F-3**: add `language-policy` to F.1; do NOT add `test-language` (live precedent: test-harness-upgrade is NOT in F.1; F.1 is a curated subset).
- **F-4**: design §8 exempt list omits project-overview.html + 参考/ — treat the LIVE verify_all exempt array as authoritative.

## SA residual items — adjudicated
(a) absent-section --force insert: §5.2 step 2 ("before first `## `, or EOF") is well-defined; reached only after AskUserQuestion insert/abort (AC-7); helper never inserts without --force. (b) test-language: assert on NEW markers (输出语言（按消费者分流）heading, human-side 用**中文** / agent-side 用**英文** discriminants) + absence of retired form; NEVER put 全程 adjacent to 中文 in the test (SCANNED). (c) sync-self = 6 pairs → add language-policy as Mapping 8 in both shells, bump AI-GUIDE:71 "6→7 script pairs", run sync-self then verify_all (E.1 gates).

## Top thing for Dev
**Run verify_all live before declaring done, watching for I.6 FAIL.** The self-trip hit T-013 three times (incl. delivery). Every new/edited SCANNED file must describe the switch WITHOUT writing `全程` adjacent to `中文`. Applied zh text is already safe; the risk is purely META descriptions. Paraphrase in English; extract (never embed) policy prose; let verify_all prove green before commit.
