# Delivery Summary — T-014 harness-language-skill

- **Task:** new `/harness-language [en|zh]` skill — let any harness project (esp. already-init'd OLD
  projects) SET / SWITCH (en↔zh) / REFRESH its project-level output-language policy. Closes the same
  "old projects can't pull new config" gap /harness-upgrade closed for scripts — here for the language
  policy T-013 shipped.
- **Mode:** full (7-stage).
- **Stages traversed:** 1 Requirement (2026-06-08) → OQ resolution (user-delegated, all 7 RA defaults) →
  2 Design → 3 Gate (APPROVED, 0 blocking / 4 advisory) → 4 Developer → 5 Code Review (APPROVED, 2 minor)
  → 5b SKILL wording polish → 6 QA (PASS, 13/13 adversarial) → 7 Delivery.
- **Rollbacks:** 0.
- **Final verify_all:** **PASS — 32/32, 0 WARN, 0 FAIL** (PM-run, PS; reproduced 32/32 both shells by Dev
  + QA). skill **14**, version **0.25.0**, I.6 PASS, G.3/G.4 PASS.
- **Baseline changes:** check count stays 32; skill count **13 → 14**; version **0.24.0 → 0.25.0**;
  baseline.json gained `test_language_ps_assertions: 39` / `_bash_assertions: 39`. New regression pair
  `test-language.{ps1,sh}` (39/39). sync-self mirror set 6 → 7 pairs.

## What shipped

- `skills/harness-language/SKILL.md` — judgment layer (`/harness-language [en|zh]`): git-repo + clean-tree
  gates, plugin-cache discovery (glob fallback, CLAUDE_PLUGIN_ROOT-optional), detect-then-confirm via
  AskUserQuestion, dry-run→confirm→apply, absent-section CONFLICT→AskUserQuestion(insert/abort)→`--force`,
  final report. Single SOT (`skills/<name>/`).
- `language-policy.{ps1,sh}` (template `templates/common/.harness/scripts/` + dogfood mirror via sync-self)
  — deterministic helper: heading-anchor locate (matches EITHER the en or zh policy heading), slice to next
  `## ` (or EOF), replace with the TARGET language's canonical block **extracted from the template** (never
  embedded); one-line CLAUDE.md/copilot swap; `.bak`; NOOP-on-byte-identity; dry-run; `--force` insert.
  Byte-stable, cross-shell-byte-identical, idempotent. cwd-derived (project target).
- `test-language.{ps1,sh}` — 39-assertion regression incl. the byte-identical zh→en→zh round-trip.
- One hint line in `skills/harness-upgrade/SKILL.md` (only edit to an existing skill).
- Full fan-out: skill 13→14, version 0.24.0→0.25.0 across verify_all arrays/labels + F.1 (both shells),
  sync-self set, AI-GUIDE (+ "6→7 script pairs"), README×2 (+ badges, new bullet under **Setup**; "six task
  shapes" unchanged), getting-started, manual-e2e-test, dev-map, 40-locations, plugin.json, marketplace.json,
  CHANGELOG `[0.25.0]`. Check count stays 32 (no new lettered check).

## Notes for the user

- Scope (deliberate): this command manages the language **policy config** (the 3 policy-bearing files),
  NOT whole-project content translation, and NOT the i18n/zh overlay's other AI-facing template files
  (that anglicization remains the separate logged follow-up). An old project runs `/harness-language zh`
  to get T-013's three-way policy; en↔zh switch uses the same command.
- The interactive layer (AskUserQuestion confirm, precondition gates) lives in SKILL.md and is
  VERIFIED-BY-SPEC; first real end-to-end exercise is an actual `/harness-language` run on a project.
- The I.6 self-trip that bit T-013 three times did NOT recur here: every new/edited scanned file was
  grepped for the retired-phrase anchor (zero hits); the helper extracts (never embeds) the policy prose.

## Insight

- 2026-06-08 · PowerShell `$raw -split "`n", -1` (the regex `-split` operator with an explicit `-1` limit) collapses a multi-line string to a SINGLE element when the limit arg is misread as an option — silently breaking line-splitting and any round-trip built on it. Use the .NET method `$raw.Split("`n")` for a literal newline split instead. Surfaced building the cross-shell byte-identical section locator. · evidence: T-014, `language-policy.ps1` Read-Lines
- 2026-06-08 · For a cross-shell pair that GENERATES the same file (config-section rewrite), byte-identity across shells requires three aligned choices: read-time CR-strip per line (so a CRLF target normalizes to LF in both shells), a single explicit trailing `\n` on write (PS `($lines -join "`n") + "`n"` vs bash awk ORS / `cp` of an LF-built temp), and slicing an inclusive section span `[heading, next "## ")` that keeps the trailing blank line. A within-shell round-trip test does NOT prove cross-shell parity — assert bash-output vs PS-output byte-identity explicitly (QA did, via `cmp` across shells). Generalizes the cross-shell-parity family with [[feedback]] from T-012 DEFECT-1. · evidence: T-014, language-policy.{ps1,sh} + QA cross-shell cmp
