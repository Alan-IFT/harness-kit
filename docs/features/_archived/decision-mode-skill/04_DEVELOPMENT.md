# Development Record — decision-mode-skill (T-018)

- Author: developer (pipeline design) + operator (verification & completion)
- Date: 2026-06-10

## Summary

Implemented the Gate-approved (round-2, 8/8) §2 design, families A–D: Mode 3 added to the
decision policy, the rubric split into Preset/Custom sections, a new `/harness-decision-mode`
interactive switcher skill, the policy mechanism shipped (generic) to all generated projects,
and the full v0.27.0 → v0.28.0 release fan-out. `verify_all` C.1/G.1/G.2 skill enumeration
14 → 15. No new check (count stays 32); no I.6 banned/exempt change; no new placeholder.

## Files changed

- **Dogfood policy** — `.harness/rules/25-decision-policy.md` (+Mode 3, three-mode framing, applies-to-all-three red lines/audit); `.harness/decision-rubric.md` (Preset/Custom split; Active mode stays 2; Preset = the operator's seeded personal prefs).
- **New skill** — `skills/harness-decision-mode/SKILL.md`: interactive Mode 1/2/3 switcher (surgical single-line Active-mode edit; Mode-3 empty-Custom capture; clean-git gated, `.bak`, idempotent; **no helper script** per rule 15 P6).
- **Shipped to generated projects (GENERIC — AC-4)** — `templates/common/.harness/rules/25-decision-policy.md` (Active mode **1**), `templates/common/.harness/decision-rubric.md` (universal defaults only, NOT operator personal prefs), `templates/common/AI-GUIDE.md.tmpl` (+rule index, +memory-layer line).
- **Release fan-out** — `plugin.json` + `marketplace.json` → 0.28.0; `README.md` + `README.zh-CN.md` (skill list + badges + 15-skill counts); `CHANGELOG.md` `[0.28.0]`; `install.ps1` + `install.sh` skills array; `AI-GUIDE.md` (15 skills, 25-decision-policy Mode-3 line, workflow row); `docs/dev-map.md`; `.harness/rules/40-locations.md`; `docs/manual-e2e-test.md` + `docs/getting-started.md` (ungated fan-out counts — the Gate F-1 surface); `verify_all.{ps1,sh}` C.1/G.1/G.2 14→15; `test-init.{ps1,sh}` +2 assertions; `baseline.json` (PS 287 / bash 249).

## Verification

Run-gate deferred to the operator (pipeline sub-agents have no Bash; PS is deny-blocked).
See 06_TEST_REPORT.md for the captured runs.

## Verdict: READY FOR REVIEW (operator-verified green).
