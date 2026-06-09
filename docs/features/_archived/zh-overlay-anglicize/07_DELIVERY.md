# Delivery Summary — T-015 zh-overlay-anglicize

- **Task:** bring a generated zh project's AI-facing STATIC scaffolding into coherence with the
  output-language policy T-013 shipped. The i18n/zh overlay was translating many AI-facing framework
  files into Chinese, so a zh project DECLARED "AI-facing → English" while shipping a Chinese AI-GUIDE,
  Chinese rules, etc. This anglicizes the AI-facing scaffolding (it now falls through to the English
  `common/` layer); only genuinely human-facing files + the policy declaration stay Chinese.
- **Mode:** full (7-stage).
- **Stages traversed:** 1 Requirement (2026-06-09) → OQ resolution (user-delegated, OQ-1 keep zh policy,
  OQ-2 anglicize tasks seed, OQ-3 → SA) → 2 Design (OQ-3 = (A)) → 3 Gate (APPROVED, 0 blocking / 7
  advisory) → 4 Developer → 5 Code Review (APPROVED, 0 blocking) → 6 QA (PASS, 0 defects) → 7 Delivery.
- **Rollbacks:** 0.
- **Final verify_all:** **PASS — 32/32, 0 WARN, 0 FAIL** (PM-run, PS; reproduced 32/32 both shells by Dev
  + QA). skill 14, version **0.26.0**, I.6 PASS.
- **Baseline changes:** check count stays 32; skill count stays 14; version **0.25.0 → 0.26.0**;
  baseline.json test-init 255→**274** (ps) / 217→**236** (sh) from the +19/shell inverse assertions
  (captured run). No new skill, no new check, no new placeholder.

## What shipped

- **11 deletions** (`git rm`) from the i18n/zh overlay: `AI-GUIDE.md.tmpl`, rule fragments `05-insight-index`
  / `60-tool-handoff` / `75-safety-hook`, `insight-index.md.tmpl`, `docs/workflow.md` / `dev-map.md.tmpl` /
  `tasks.md.tmpl`, and the 3 type `50-<type>` rules → init now serves the English `common/`/type originals.
- **3 SPECIAL files edited in place** (00-core.md.tmpl, CLAUDE.md.tmpl, copilot-instructions.md.tmpl):
  English `common/` framework body + the byte-for-byte preserved T-013 Chinese policy section/line. 00-core
  has EXACTLY ONE policy section (the Chinese one); the English `## Output language (project-wide)` heading
  is absent. CLAUDE/copilot differ from the English version by exactly the one policy line.
- **2 KEEP-ZH files untouched** (docs/spec/README.md, evals/golden-tasks.md.tmpl — genuinely human-facing).
- **test-init**: +19 inverse assertions/shell (symmetric, pure-grep, present+absent on different strings)
  asserting AI-facing files are now the English render AND human-facing files stay Chinese AND 00-core is
  single-section; existing 4 T-013 zh assertions retained.
- **SKILL.md step-4.3** overlay-file list corrected to the 5 remaining files.
- **Version fan-out**: 0.25.0→0.26.0 (plugin.json, marketplace.json, both README badges) + CHANGELOG `[0.26.0]`;
  README test-init badge 255→274.

## Notes for the user

- The zh project's language POLICY itself stays Chinese (T-013, unchanged) — only the surrounding AI-facing
  framework scaffolding became English. A Chinese team still reads the policy declaration + their human docs
  + all runtime human-facing output in Chinese; the AI reads English framework files.
- This completes the language model: T-013 (output policy) + T-014 (set/switch/refresh command) + T-015
  (scaffolding coherence). Already-generated old projects pull all of this via `/harness-upgrade` (scripts)
  + `/harness-language` (policy); the anglicized scaffolding reaches them on a fresh init or future content-refresh.
- A pre-existing overlay incompleteness (the zh overlay never had `65-intervention`/`70-doc-size` translations)
  is now moot — those AI-facing rules are English by design.

## Insight

- 2026-06-09 · A template file can be DUAL-PURPOSE: both an init-overlay source AND the canonical source a separate runtime tool reads at run time. The i18n/zh `00-core.md.tmpl` + `CLAUDE.md.tmpl` are read by `/harness-language` (`language-policy.{ps1,sh}`) to extract the zh policy section — so "delete the overlay file to anglicize it" would have silently broken `/harness-language zh` (the helper `exit 1`s on the missing source). Before deleting/restructuring a template file, grep the OTHER scripts/skills for reads of that path — a file's consumers are not only the init flow. (This killed design-option-B and forced the in-place SPECIAL-splice.) · evidence: T-015 OQ-3, language-policy.sh:77-81 reads i18n/zh SPECIAL files
- 2026-06-09 · A test-init inverse assertion only EXERCISES an overlay deletion if the fixture actually LAYERS the directory being removed. test-init's zh fixture layers common→<type>→i18n/zh/common but NOT i18n/zh/<type>, so an EN-marker assertion on a type-dir file (50-<type>) passes whether or not the zh type file is deleted — vacuous coverage. When a deletion can't be regressed by the existing fixture topology, mark it audit-only (confirm the EN fall-through exists) rather than ship an assertion that implies coverage it lacks. Extends the one-sided-assertion insight (2026-05-16). · evidence: T-015 Gate F-1, test-init zh fixture layering (copy_layer common→type→i18n/zh/common)
