# PM Log — T-014 harness-language-skill

> Task: new `/harness-language [en|zh]` skill — let any harness project (esp. already-init'd OLD
> projects) SET / SWITCH (en↔zh) / REFRESH its project-level output-language policy. Closes the same
> "old projects can't pull new config" gap as /harness-upgrade did for scripts — here for the language
> policy T-013 just shipped.
>
> Mode: full (7-stage). Started 2026-06-08.

## Intervention check
- Before stage 1: `.harness/intervention.md` absent → no pending signal.

## Developer mode
- `.harness/agents/dev-*.md`: none → single Developer mode.

## PM-set design baseline (RA/SA refine, do NOT overturn)
- Dedicated `/harness-language [en|zh]` skill (NOT a /harness-upgrade flag). Language = first-class
  init-Q5 config with set/switch/refresh semantics; distinct intent from /harness-upgrade's
  "catch up to framework version".
- Covers set / switch(en↔zh) / refresh; no-arg = refresh current language to latest canonical text.
- SCOPE (surgical): rewrite ONLY the policy-bearing files — generated project's
  `.harness/rules/00-core.md` "Output language/输出语言" section + `CLAUDE.md` top line +
  `.github/copilot-instructions.md` top line — to the TARGET language's current canonical policy
  (en = single-language English; zh = T-013 three-way split). NO whole-project content translation
  (that is a larger separate follow-up).
- Non-destructive, idempotent, dry-run, `.bak`; self-bootstrapping from plugin templates; reuse the
  existing policy templates + {{LANG}} mechanism (don't fork a second policy-text source).

## Insights surfaced to downstream (from .harness/insight-index.md)
- **T-013 (delivery self-trip)**: when DESCRIBING an I.6 banned phrase in ANY scanned doc, never write
  the literal — use English/paraphrase, or verify_all I.6 self-trips. Highly relevant (this task's
  zh policy text + docs reference the same retired phrasing).
- **T-013 (I.6 4-file lockstep)**: I.6 banned/exempt lists mirror across verify_all.{ps1,sh} +
  test-verify-i6.{ps1,sh} + I6ExpectedEntryCount — only relevant if this task touches I.6 (it may not).
- **T-012 (skill SOT)**: skills ship from `skills/<name>/` only (no `.harness/skills/`); new skill =
  version+count worthy (G.3/G.4 fan-out; skill 13→14; "six task shapes" stays six; group under Setup).
- **T-012 ({{...}} piece-wise)**: a script shipping into generated projects that must name a placeholder
  can't contain the literal `{{NAME}}` (test-init scan) — assemble from pieces. Relevant if a helper
  references {{LANG}}.
- **L11/L30**: no new `{{...}}` placeholder → keep D.2 untouched; never re-serialize settings.json.
- **L31 / L13 / L27 / L10**: root-derivation depth; bash `arr=()`; no `grep -F -i` (MSYS); re-Read after Edit.

## Stage transitions

### Stage 1 — Requirement Analyst — dispatched 2026-06-08
- Output: `01_REQUIREMENT_ANALYSIS.md`. Verdict: **BLOCKED ON USER** (7 OQs, all with defaults).

### OQ resolution — PM (user-delegated authority; "decide, don't ask") — 2026-06-08
All 7 RA defaults ACCEPTED (design baseline):
- **OQ-1 → heading-anchor matching** (NO new markers): replace from the canonical policy heading to the
  next `##`. Old target projects have the heading but wouldn't have new markers, so markers add cost
  without helping. en/zh headings differ ("Output language (project-wide)" vs "输出语言（按消费者分流）").
  Hand-mangled heading → AskUserQuestion confirm fallback.
- **OQ-2 → detection order** 00-core.md → CLAUDE.md → copilot, first confident hit, always confirm pre-filled.
- **OQ-3 → NO persisted PROJECT_LANG marker** (rely on inference; keeps D.2 untouched).
- **OQ-4 → /harness-upgrade gets a one-line hint** ("/harness-language can refresh the language policy"),
  hint only, no auto cross-command call.
- **OQ-5/6 → absent-section + min-precondition** per RA defaults.
- **OQ-7 → safety gates mirror /harness-upgrade** (git repo + clean tree + `.bak`, dry-run, idempotent).
- Carry HARD: the **I.6 self-trip trap** — any SKILL/doc text describing the retired blunt-all-Chinese
  phrasing must paraphrase, NEVER write the literal banned anchor (hit T-013 delivery 3×).

Requirement flipped to **READY**. Advancing to design.

### Stage 2 — Solution Architect — dispatched 2026-06-08
- Output: `02_SOLUTION_DESIGN.md`. Verdict: **READY**. skill + `language-policy.{ps1,sh}` helper
  (mirrors upgrade-project two-layer; joins sync-self set 6→7 pairs; test-language.{ps1,sh} does not).
- Section-locator: match FIRST line == either canonical heading (en `## Output language (project-wide)`
  / zh `## 输出语言（按消费者分流）`), slice to next `## ` (or EOF), replace with TARGET lang's canonical
  block EXTRACTED from template (never embedded literal). CLAUDE.md/copilot one-line swap on
  `^(Output language:|输出语言：)`. NOOP on byte-identity. zh→en→zh byte-identical (single text source =
  templates). No heading → CONFLICT exit 2 → skill mediates via AskUserQuestion (never auto-insert).
- Fan-out 18 sites; version 0.24.0→0.25.0; skill 13→14; check count STAYS 32 (C.1/C.2/G.1/G.2 loop the
  array; F.1 +name-only). G.1/G.2 match skill NAMES → README/CHANGELOG MUST mention `harness-language`.
  Six task shapes stays six; new skill under Setup. Only existing-skill edit: 1 hint line in harness-upgrade.
- I.6 self-trip plan verified vs exempt boundary: CHANGELOG + docs/features/ exempt; SKILL/helper/test/
  AI-GUIDE/READMEs/getting-started/manual-e2e/40-locations SCANNED → paraphrase, never literal anchor.
  No I.6 list change → 4-file lockstep untouched.
- SA flagged for Gate: (a) absent-section --force insertion point; (b) test-language embeds only the SAFE
  three-way zh text; (c) read LIVE sync-self array shape (insight says "4 scripts" but live mirror is 6 pairs).

### Stage 3 — Gate Reviewer — dispatched 2026-06-08
- Output: `03_GATE_REVIEW.md` (persisted by PM). Verdict: **APPROVED FOR DEVELOPMENT**. 0 BLOCKING, 4 ADVISORY.
- All load-bearing claims verified vs live code: exact en/zh headings, locator soundness, fan-out
  completeness (no missed site), check count stays 32, I.6 self-trip VERIFIED SAFE (applied zh text has
  no 全程; only meta-descriptions are the risk), sync-self = 6 pairs→7, helper cwd-derived (L31 N/A).
- 4 ADVISORY folded into Dev brief: F-1 helper path = skills/harness-init/templates/common/.harness/scripts/
  (not literal top-level templates/); F-2 marketplace.json version at line 17 (grep, don't trust line);
  F-3 add language-policy to F.1 NOT test-language; F-4 live verify_all exempt array is authoritative.
- 0 blocking → advance to Dev without re-Gate.

### Stage 4 — Developer — dispatched 2026-06-08
- Output: `04_DEVELOPMENT.md`. Captured (both shells): sync-self In sync; test-language **39/0 · 39/0**
  (incl. byte-identical zh→en→zh round-trip); test-init 255/0 · 217/0; test-verify-i6 58/0; verify_all
  **32/32 BOTH shells**, skill 14, v0.25.0, I.6 PASS. All 4 Gate advisories honored.
- I.6 self-trip avoided: grep of every scanned new/edited file = ZERO `全程` hits. Helper extracts
  (never embeds) zh prose; applied zh canonical text has no 全程.
- Dev self-flagged: (1) minor DESIGN DRIFT — temp-file/line-array section injection to preserve the
  section's trailing blank line (R7 off-by-one mitigation); (2) insight: PS `$raw -split "\n",-1`
  collapses to ONE element (silently breaks line-split) — fix uses `.Split("\n")`.
- Stage-4→5 gate satisfied.

### Stage 5 — Code Reviewer — dispatched 2026-06-08
- Output: `05_CODE_REVIEW.md` (persisted by PM). Verdict: **APPROVED**. 0 BLOCKING, 0 MAJOR, 2 MINOR, 1 NIT.
  All 13 ACs covered; I.6 zero-risk (grep: no 全程 in scanned files); fan-out exhaustive; byte-identical
  round-trip proven (test #9); design-drift (section-injection for trailing-blank) ACCEPTED.
- PM decision on the 2 MINOR: FIX the SKILL.md step-4 no-arg-refresh wording (AI runbook clarity — load-bearing)
  before QA. ACCEPT the PS ValidateSet vs bash-custom-message divergence as-is (de-idiomatizing PS would be
  lower quality; contract holds: exit≠0, no change). NIT (LANG_ARG naming) = no action (correct as-is).

### Stage 5b — Developer polish (CR MINOR SKILL.md wording) — dispatched 2026-06-08
- Reworded SKILL.md Step 4 (no-arg refresh) to specify the `--lang <either> --dry-run` detect-only probe;
  verified accurate vs helper's real DETECT contract (sh:169/ps1:182 emit unconditionally post-validation,
  pre-mutation; --dry-run suppresses writes). `全程` grep on SKILL.md = 0. bash verify_all 32/32 I.6 PASS.
- Sub-agent's pwsh was blocked by its env deny rule → **PM ran verify_all.ps1 directly: 32/32, C.2/I.6/G.3/G.4
  PASS**. Both shells green after the fix.

### Stage 6 — QA Tester — dispatched 2026-06-08
(awaiting output)
