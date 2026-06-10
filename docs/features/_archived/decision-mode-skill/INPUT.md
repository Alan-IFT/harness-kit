# INPUT — T-018 decision-mode-skill

**Mode: full** (7-stage pipeline). Real shipped feature + version release (v0.27.0 → v0.28.0).

## User task

Ship a 15th skill `/harness-decision-mode` + add **Mode 3** (user-custom rubric) to the decision/escalation policy, and ship the policy mechanism (with GENERIC defaults) to all generated harness projects.

### Background (current state — read these)

This repo recently added a decision/escalation policy, currently **dogfood-only**:
- `.harness/rules/25-decision-policy.md` — Mode 1 (human decides, the default) + Mode 2 (rubric-guided autonomy) + the always-escalate red lines + the audit trail. "Active mode" line is the flip control.
- `.harness/decision-rubric.md` — the operator-authored principles the AI decides by under Mode 2 (a Prime directive of 3 principles + standing personal preferences).
- AI-GUIDE.md line 26 indexes `25-decision-policy.md`; line 37 indexes `decision-rubric.md` in the memory layer.

The user now wants (a) a third mode, (b) an interactive slash command to switch modes, (c) it shipped to all harness projects.

### A. Add Mode 3 (user-custom rubric)

- In `25-decision-policy.md` AND the new template copy: add **Mode 3 — user-custom autonomy**: the AI decides per the user's OWN custom rubric (a "Custom rubric" section the user authors) instead of the preset rubric. The **red lines and the audit trail apply to all three modes** unchanged; the three prime principles remain the floor.
- Restructure `decision-rubric.md` into two clearly-delimited sections: **`## Preset rubric (Mode 2)`** (the curated principles) and **`## Custom rubric (Mode 3)`** (user-authored; starts as an empty template with a one-line instruction). Mode 2 reads Preset; Mode 3 reads Custom.
- In THIS dogfood repo: keep the existing seeded personal preferences as the Preset section; add an empty Custom section. Active mode stays 2.

### B. New skill `skills/harness-decision-mode/SKILL.md`

- Interactive switcher. Model the surgical-edit + confirm flow on the existing `/harness-language` skill (`skills/harness-language/SKILL.md`). Flow: show the current Active mode → `AskUserQuestion` to pick Mode 1 / 2 / 3 → surgically rewrite ONLY the "Active mode" line in `.harness/rules/25-decision-policy.md` → confirm.
- If Mode 3 is picked and the Custom rubric section is empty, collect the user's custom decision prompts (`AskUserQuestion` free-text / "Other") and write them into the Custom section.
- Idempotent, non-destructive, git-clean-gated like `/harness-language`.
- The SKILL.md MUST meet `.harness/rules/15-skill-authoring.md`: a model-facing `description:` with concrete EN + 中文 triggers ("switch decision mode" / "切换决策模式" / "让 AI 自己拿主意" / "改成人工决策"), a "When NOT to invoke" surface, an "Anti-patterns" section.

### C. Ship the policy mechanism to generated projects

- Add to `skills/harness-init/templates/common/.harness/`: `rules/25-decision-policy.md` and `decision-rubric.md`.
- **CRITICAL: the shipped rubric Preset section must be GENERIC, universal defaults — NOT this repo operator's personal preferences.** Use the three prime principles + universally-safe defaults only (e.g. reversible+in-scope→just-do-it, match existing conventions, honest reporting, verify-before-done, profile-before-optimizing). The shipped policy's **Active mode defaults to 1** (new projects start human-decides). Custom section empty.
- Index the new rule in the **template AI-GUIDE** (`templates/common/AI-GUIDE.md.tmpl` or equivalent) so generated projects' E.4b-equivalent passes, and surface the decision-rubric in the template's memory layer.
- The skill is a PLUGIN skill (top-level `skills/`), consumed via the installed plugin — it does NOT need to go into templates/.

### D. Full release surfaces (this is where releases historically break — see insight-index; the `/harness-language` T-014 delivery is the best precedent for "how a skill was added")

- `.claude-plugin/plugin.json` version 0.27.0 → **0.28.0**; `marketplace.json` version; both README badges (version + skill-count if present).
- `README.md` + `README.zh-CN.md`: add the skill to the quick-start / skill list; bump any "14 skills" claim to 15; version/skill badges.
- `CHANGELOG.md`: new `[0.28.0]` section describing the feature.
- `install.ps1` + `install.sh`: add `harness-decision-mode` to the skills array (symmetric).
- `AI-GUIDE.md`: add a workflow-entry / skill row for the new skill (the `25-decision-policy` rule is already indexed in the dogfood AI-GUIDE this session).
- `docs/dev-map.md`: list the new skill + the decision-policy assets.
- Extend `test-init.{ps1,sh}` only if it asserts the shipped `.harness/rules/` set or a skill count (check whether the new template rule needs a presence assertion); reconcile `baseline.json` if its counts move.
- verify_all G.1 (README all skills), G.2 (CHANGELOG all skills), G.3 (version stamps), G.4 (count/version claims) MUST all pass.

## HARD CONSTRAINTS (apply to every stage)

1. **Do NOT git commit or push, and do NOT run the release tag.** Leave a green working tree; the operator commits/pushes (red line #2 of the very policy this ships — outward-facing/publishing is the operator's).
2. **Shipped rubric = generic defaults, never the operator's personal prefs** (those stay in the dogfood `.harness/decision-rubric.md` Preset only).
3. **Symmetry**: any `.ps1` edit needs its `.sh` twin (install scripts, test-init, any skill helper).
4. Follow `.harness/rules/10-self-consistency.md`: editing `templates/common/.harness/agents/` or a mirrored script → run `sync-self`; the new template RULE is bespoke (rules are NOT in sync-self's mirror set) so it does NOT need sync-self. The SKILL must be present for harness-sync/`.claude` if applicable (top-level plugin skill).
5. Keep every new doc within `.harness/rules/70-doc-size.md` caps.

## Verification (operator runs these — sub-agents here have NO Bash; surface BLOCKED-ON-CAPABILITY for the run gate rather than fabricating results)

- `bash .harness/scripts/verify_all.sh` = 32 PASS / 0 WARN / 0 FAIL (runs ~45s after T-017).
- `bash .harness/scripts/test-init.sh` if templates changed.
- The skill's interactive flow reviewed for correctness (surgical single-line edit of Active mode; Mode-3 custom-prompt capture).

## Insight-index lines surfaced by PM as relevant

- L24 (2026-06-05): adding a verify_all check / a "N at vX" count claim is version-worthy; G.4 enforces claim↔plugin.json version consistency.
- L26 (2026-06-06): whole-file substring claim checks need file-UNIQUE expect literals (relevant if any verify_all/test-init assertion is added).
- L30 (2026-06-08, T-013): I.6 banned/exempt list is a FOUR-file lockstep + I6ExpectedEntryCount — only if a retired claim is added (likely N/A; this is net-new).
- L31 (2026-06-08): a doc scanned by I.6 must not write a literal banned-anchor sequence (self-trip risk at archive stage).
- T-014 `/harness-language` is the canonical skill-add release precedent.
