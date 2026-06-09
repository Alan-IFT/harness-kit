# 05 — Code Review · T-015 / zh-overlay-anglicize

> Stage 5. Code Reviewer (read-only). Persisted by PM. Reviewed vs 02 design, 01 ACs, 03 gate (F-1..F-7).

## Verdict: APPROVED — 0 BLOCKING · 0 MAJOR · 1 MINOR · 2 NIT

Every load-bearing property holds against live code. The two highest-risk ones (SPECIAL single-section
invariant; inverse-assertion non-vacuity) verified TRUE. Gate F-1 honored. No behavior drift. Routing: none.

## The two most important verifications
### 1. SPECIAL splice — single-section invariant — PASS
`i18n/zh/.../00-core.md.tmpl`: EXACTLY ONE policy section `## 输出语言（按消费者分流）` (:9); English
`## Output language (project-wide)` heading ABSENT (grep-confirmed) → no double-section. Header `:1-7`
byte-identical to `common/00-core.md.tmpl:1-7`; English body headings match common/ verbatim (offset-shifted
by the longer zh policy block); `## How this project is developed`→EOF identical. Preserved zh block = T-013
text byte-for-byte (`给用户的交付总结`:17, `commit message`:25); **no `全程`**.
`CLAUDE.md.tmpl`: differs from common/ by EXACTLY line 3 (the policy line). copilot: differs by EXACTLY line 6
(correctly adopts the EN body's 4th red-line bullet, not the old zh one). CLEAN.

### 2. Inverse assertions REAL, not vacuous (Gate F-1) — PASS
Both shells symmetric (sh:533-571 / ps1:634-672), +19 assert calls each, present+absent on DIFFERENT strings
(no T-007 trap). PRESENT-EN markers (`project index`, `The 7-Agent Pipeline`, `Task Board`, `Dev Map`,
`Cross-task insight index`) exist in the EN fall-through targets. **ABSENT-ZH markers (`项目指南|工作流|任务看板|
开发导航|跨任务`) grep over the ENTIRE `templates/common/` tree → No matches** → if a deletion were reverted, the
`! grep` assertion would genuinely FAIL. Truly discriminating.

## F-1 adjudication: ACCEPT option (b) audit-only
Option (a) genuinely infeasible: `copy_layer` hard-aborts on missing source (`test-init.sh:69` exit 1 /
`ps1:53` throw), and the deletion removes the entire `i18n/zh/<type>` dir → a fixture layer would abort the run;
guarding it = vacuous (English file already ships from layer 2). 3 type-dir EN targets confirmed present
(Glob) + CHANGELOG:18 records audit-only. No misleading assertion shipped. Correct, honest choice.

## AC coverage: AC-1..AC-12 all PASS (AC-11 verify_all pending QA re-run). Design fidelity: all PASS.
- Exactly 5 overlay files (Glob); 11 deletions each with present EN fall-through; no over-deletion.
- EN path untouched (SPECIAL files live only under `i18n/zh/`; common/ unchanged) — AC-7.
- T-014 dependency intact (3 SPECIAL files on disk; language-policy reads 00-core + CLAUDE from i18n/zh/common).
- Version 0.26.0 at 4 G.3 sites + CHANGELOG `[0.26.0]`; skill 14, check 32; README test-init badge 274;
  baseline.json 274/236 (matches +19/shell). No new `{{...}}`.
- SKILL.md:107 lists exactly the 5 remaining + records the anglicized files as not-in-overlay.

## Findings (all advisory — none block)
- **MINOR [TEST] test-init sh:524/ps1:626** — the retained T-013 `commit message` PRESENT marker lives INSIDE
  the preserved Chinese policy block, so it doesn't by itself prove the body is English — but the NEW
  `## Hard rules (red lines)` assertion (sh:555) does. Property covered; no action.
- **NIT [DOC] CHANGELOG:12** — deliberately paraphrases to dodge the I.6 `全程...中文` anchor (CHANGELOG is
  exempt anyway). Flagged so a future editor doesn't "fix" it back.
- **NIT [TEST]** — the 5 ABSENT-ZH markers are bare substrings; today none collide in `common/` (verified).
  Heading-anchoring would be marginally more robust; current is fine.

## Residual risk for QA (verify by RUNNING)
#1: run a real `{{LANG}}=zh` init (or test-init `-Keep`) and inspect the generated tree — confirm (a) AI-GUIDE,
rule fragments, workflow/dev-map/tasks, type 50-* are the ENGLISH renders; (b) `.harness/rules/00-core.md` =
English body + the single Chinese `## 输出语言（按消费者分流）` section (NO `## Output language (project-wide)`
second section); (c) docs/spec/README.md + evals/golden-tasks.md are CHINESE; **(d) `/harness-language zh`
still works on the freshly-generated project** (only a real round-trip proves the T-014 section-extraction
still resolves after body anglicization). Re-run verify_all + test-init BOTH shells (reproduce 274/236, 32/32;
the Dev's no-python3 bash path is environment-specific).
