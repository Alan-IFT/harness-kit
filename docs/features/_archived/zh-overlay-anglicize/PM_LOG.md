# PM Log — T-015 zh-overlay-anglicize

> Task: bring the generated zh project's AI-facing SCAFFOLDING into coherence with the new
> output-language policy (T-013: AI-facing → English). Today the i18n/zh overlay translates many
> AI-facing framework files into Chinese, contradicting the policy a zh project now declares.
> Anglicize the AI-facing scaffolding (let it fall through to the English common/ layer); keep only
> genuinely human-facing files + the policy-carrying files in the zh overlay.
>
> Mode: full (7-stage). Started 2026-06-09.

## Intervention check
- Before stage 1: `.harness/intervention.md` absent → no pending signal.

## Developer mode
- `.harness/agents/dev-*.md`: none → single Developer mode.

## PM pre-scan — current i18n/zh overlay contents (so RA classifies, not re-discovers)
zh overlay (`skills/harness-init/templates/i18n/zh/`):
- common/AI-GUIDE.md.tmpl — AI index
- common/.harness/rules/00-core.md.tmpl — AI rules + **carries the T-013 policy section**
- common/.harness/rules/05-insight-index.md.tmpl, 60-tool-handoff.md, 75-safety-hook.md.tmpl — AI rules
- common/.harness/insight-index.md.tmpl — AI memory
- common/CLAUDE.md.tmpl — AI stub + **policy line**
- common/.github/copilot-instructions.md.tmpl — AI + **policy line**
- common/docs/workflow.md, docs/dev-map.md.tmpl, docs/tasks.md.tmpl — AI/coordination (borderline)
- common/docs/spec/README.md — **human-facing** spec guide
- common/evals/golden-tasks.md.tmpl — eval seeds (borderline)
- {fullstack,backend,generic}/.harness/rules/50-<type>.md(.tmpl) — AI type rules
- NOTE: zh overlay already LACKS 65-intervention + 70-doc-size translations (pre-existing incompleteness
  per old insight) — anglicizing AI-facing rules makes that a non-issue.
en default layer (`common/`) has the English originals of all the above.

## PM-set design baseline (RA/SA refine; do NOT overturn the framing)
- **Anglicize AI-facing scaffolding** = REMOVE the purely-AI-facing translated files from the zh overlay so
  they fall through to the English `common/` versions. Candidates: AI-GUIDE.md.tmpl, 05/60/75 rule frags,
  insight-index.md.tmpl, dev-map.md.tmpl, workflow.md, type 50-*, (tasks.md.tmpl/golden-tasks — RA to classify).
- **Policy-carrying files (00-core/CLAUDE/copilot): anglicize the BODY, KEEP the T-013 zh policy
  section/line UNCHANGED.** Do NOT reverse T-013 — the three-way policy text stays exactly as shipped; only
  the surrounding non-policy prose becomes English (= common body). (This sidesteps the policy-prose-language
  philosophy fork; flag it but default to no-reversal.)
- **Human-facing files stay Chinese** (docs/spec/README.md clearly; RA classifies the borderline ones).
- OUT: harness-kit's own dogfood repo (English regardless); the en path (unchanged); whole-project runtime
  content (that's the T-013 OUTPUT policy, already shipped — this is about STATIC scaffolding language).

## Insights surfaced to downstream
- **One-sided assertion (2026-05-16)**: when asserting set-membership in templates, write the inverse too.
  Directly relevant — removing overlay files changes test-init's zh-fixture expectations; assert both
  presence (human-facing stays zh) AND absence (AI-facing is now the English common version).
- **T-013 I.6 self-trip**: never write the retired banned anchor literal in a scanned doc when describing this.
- **T-012 skill SOT / T-013 fan-out**: this is a TEMPLATE-content change (no new skill) — likely version-worthy
  (G.3/G.4) but NOT skill/check-count. Confirm. test-init is the heavy regression surface.
- **test-init recursive {{...}} scan (T-012)**: removing/anglicizing .tmpl files must leave no stray placeholder.
- **D.2 placeholder whitelist**: if file set changes, ensure no new placeholder; the English common files are
  already D.2-clean.

## Stage transitions

### Stage 1 — Requirement Analyst — dispatched 2026-06-09
- Output: `01_REQUIREMENT_ANALYSIS.md`. Verdict: **BLOCKED ON USER** (3 OQs, all defaulted).
- Classification (16 files): **11 ANGLICIZE** (delete from overlay → fall through to English common/) ·
  **3 SPECIAL** (00-core/CLAUDE/copilot: EN body, KEEP T-013 zh policy) · **2 KEEP-ZH** (docs/spec/README.md,
  evals/golden-tasks.md.tmpl). All match the PM baseline. No new skill/check/placeholder; version-worthy.
- Mechanism confirmed: SKILL §4.3 applies overlay ON TOP of English common/ → "delete from i18n/zh/" =
  fall-through to the English original (all 16 fall-through targets verified present).

### OQ resolution — PM (user-delegated; "decide, don't ask") — 2026-06-09
- **OQ-1 → KEEP the policy-section prose Chinese** (as T-013 shipped). No reversal; preserves the
  `给用户的交付总结` test marker + I.6-clean text. The SPECIAL files = EN framework body + the unchanged T-013 zh policy.
- **OQ-2 → ANGLICIZE `tasks.md.tmpl`** (AI-parsed board; T-013 already classified runtime rows EN).
- **OQ-3 → SA's design call.** Default = keep the 3 SPECIAL files in-overlay (simpler). BUT explicitly
  evaluate the alternative: serve the zh policy via the T-014 `/harness-language` mechanism at init time so the
  3 policy-carrying files need NOT be duplicated in the overlay (eliminates EN-body duplication = better
  long-term maintainability). SA recommends; if the init-mechanism is cleanly feasible + low-risk, prefer it.
- Carry HARD: the **inverse-assertion** obligation — test-init zh fixture must assert BOTH human-facing stays
  ZH AND AI-facing is now the English version (else it hides this task's own drift). And the I.6 self-trip trap.

Requirement flipped to **READY** on this baseline. Advancing to design.

### Stage 2 — Solution Architect — dispatched 2026-06-09
- Output: `02_SOLUTION_DESIGN.md`. Verdict: **READY**.
- **OQ-3 → (A)** (keep 3 SPECIAL files in overlay) — decisive finding: T-014 `language-policy.{ps1,sh}`
  reads the canonical zh policy text FROM these files (ps1:74-78 / sh:77-81), so (B) would delete T-014's own
  source and BREAK `/harness-language zh`. (B) also adds init coupling for no extra safety net (verify_all
  doesn't run on generated projects; only test-init does, same as (A)). The "duplication" (B) removes is one
  medium file (F-2) + a one-line diff in F-7/F-8.
- **SPECIAL splice** specified verbatim: each = English `common/` file with the English
  `## Output language (project-wide)` SECTION (F-2) / `Output language: **English**.` LINE (F-7/F-8) REPLACED
  by the Chinese `## 输出语言（按消费者分流）` section / `输出语言：…` line from the current zh overlay. Single
  policy section invariant (no double-section). Write-then-verify (L10).
- **11 deletions**: all fall-through targets confirmed present (8 common + 3 type-dir); unique-content audit
  found NO zh-only content lost — every zh file is a structural translation of its English original.
- **Inverse assertions**: exact EN/ZH marker pairs (present+absent on DIFFERENT strings, no T-007 trap),
  pure-grep both shells, baseline + README badge from a captured run.
- **Version**: 0.25.0 → 0.26.0 (4 G.3 sites + CHANGELOG); skill 14, check 32 unchanged; no new placeholder.
- Residual risk for the Gate: R-2 (A)-duplication drift (accepted, bounded); R-3 SPECIAL double-section
  (mitigated by §4 ⚠ note + the `Output language (project-wide)` ABSENT assertion); R-4 I.6 self-trip in
  scanned files (CHANGELOG/docs exempt; T-013 text already green).

Advancing to Gate Review.

### Stage 3 — Gate Reviewer — dispatched 2026-06-09
- Output: `03_GATE_REVIEW.md` (persisted by PM). Verdict: **APPROVED** (full-mode; gate used plan-mode words
  per dispatch). 0 BLOCKING, 7 ADVISORY. The 3 crux claims verified TRUE: OQ-3=(A) (T-014 reads the SPECIAL
  files; B breaks /harness-language zh), no-double-section splice (replace not append + ABSENT-guard), and no
  existing test requires a deleted file (4 zh asserts target 00-core which stays; markers 给用户的交付总结+commit message survive).
- 7 advisories folded into Dev brief. Key: **F-1** type-dir inverse assertion is VACUOUS (zh fixture never
  layers i18n/zh/fullstack → EN 50-fullstack ships pre-deletion) → make it meaningful OR label type-dir
  deletions audit-only; do NOT ship vacuous coverage. **F-6** baseline.json + README badges from a real
  two-shell run, never estimate. F-2..F-5/F-7 cosmetic/citation.
- 0 blocking → advance to Dev without re-Gate.

### Stage 4 — Developer — dispatched 2026-06-09
- Output: `04_DEVELOPMENT.md`. 11 git-rm deletions (zh overlay → 5 files), 3 SPECIAL splices (EN body +
  byte-preserved T-013 zh policy; single-section verified: Hard-rules PRESENT, 输出语言（按消费者分流）PRESENT,
  Output language (project-wide) ABSENT; 00-core EN body diff-identical to common/, CLAUDE/copilot differ by 1
  policy line), 2 KEEP-ZH untouched, +19 inverse assertions/shell (+ 4 T-013 retained), SKILL §4.3 → 5 files,
  version 0.26.0 (4 sites + CHANGELOG), README test-init badge 255→274.
- Captured (both shells): test-init **274/274 (ps) · 236/236 (sh)**; verify_all **32/32 both shells**, skill
  14, check 32, v0.26.0, I.6 PASS, no new placeholder. baseline.json updated to captured 274/236.
- **F-1 → (b) audit-only** (option (a) infeasible: copy_layer throws on missing source dir = the very
  i18n/zh/<type> dir the deletion removes). 3 type-dir EN fall-throughs confirmed present; CHANGELOG records audit-only.
- `/harness-language zh` (T-014) intact: language-policy.sh:80-81 reads only the 3 SPECIAL files (present). EN
  path untouched (git diff zero under templates/common/). Stage-4→5 gate satisfied.

### Stage 5 — Code Reviewer — dispatched 2026-06-09
- Output: `05_CODE_REVIEW.md` (persisted by PM). Verdict: **APPROVED**. 0 BLOCKING, 0 MAJOR, 1 MINOR, 2 NIT.
- Both crux properties verified TRUE: SPECIAL single-section invariant (00-core EN body byte-identical to
  common/, CLAUDE/copilot differ by exactly 1 line, no double-section); inverse assertions NON-VACUOUS
  (grepped whole common/ tree — ABSENT-ZH markers 项目指南/工作流/etc. genuinely absent → assertions really
  discriminate). F-1 audit-only ACCEPTED (option (a) confirmed infeasible: copy_layer aborts on missing source).
  All ACs pass; +19/shell reconciles (no fabricated tally); EN path untouched; T-014 deps intact.
- PM decision: all findings are "no action required / fine as-is / advisory" (none has UX/clarity weight) →
  NO pre-QA polish (don't over-engineer); proceed straight to QA.

### Stage 6 — QA Tester — dispatched 2026-06-09
(awaiting output)
