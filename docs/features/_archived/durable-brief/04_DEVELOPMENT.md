# Development Record — durable-brief (T-05)

**Stage:** 4 (Developer) · **Mode:** full · **Gate:** APPROVED FOR DEVELOPMENT (C-1, C-2)

## Summary

Documentation-only, additive edit to two plugin-native agent contracts. `agents/requirement-analyst.md` gained Hard rule 6 (behavioral-not-procedural + no forward-looking file-path/line-number anchors, with the single-sourced EVIDENCE-citation exemption) plus one good and one bad exemplar. `agents/pm-orchestrator.md` gained one dispatch-contract line referencing — not restating — the RA rule. Version bumped 0.35.0 → 0.36.0 across the four G.3 stamps with a CHANGELOG `[0.36.0]` entry. No count token, no verify_all check, no I.6 list change, no protected-file edit.

## Files changed (T-05 scope)

- `agents/requirement-analyst.md` — appended Hard rule 6 after rule 5 (verbatim §4a); appended 1 "good" entry after the "No technology mentioned" line (verbatim §4b); appended 1 "bad" entry after the "Add an option to do X" line (verbatim §4b). All three are pure additions.
- `agents/pm-orchestrator.md` — appended the one dispatch-contract line (verbatim §5a) in "Cross-task memory" immediately after the insight-surfacing paragraph, before the "Mid-task intervention" heading. Pure addition; lines 51-57 byte-present.
- `.claude-plugin/plugin.json` — `version` 0.35.0 → 0.36.0.
- `.claude-plugin/marketplace.json` — `plugins[0].version` 0.35.0 → 0.36.0.
- `README.md` — version badge (line 5) 0.35.0 → 0.36.0.
- `README.zh-CN.md` — version badge (line 5) 0.35.0 → 0.36.0.
- `CHANGELOG.md` — prepended the `## [0.36.0]` entry (verbatim §10) above `## [0.35.0]`.

## verify_all result

- **Baseline (`verify_all.sh`, before edits):** PASS 32 / WARN 0 / FAIL 0.
- **After changes (`verify_all.sh`):** PASS 32 / WARN 0 / FAIL 0.
- **Delta:** 0 new failures, 0 new warnings. G.3 sees 0.36.0 across all four stamps; G.4 sees CHANGELOG `[0.36.0]` and consistent count claims (live check count stays 32); I.3 caps OK; I.6 clean.
- **PowerShell (`verify_all.ps1`):** operator-pending per the standing deny-rule — PM to run. Not faked here.

## Line counts (I.3 cap = 300)

- `agents/requirement-analyst.md`: **77** lines (≤300).
- `agents/pm-orchestrator.md`: **208** lines (≤300).

## Acceptance-criteria self-review

- **AC-1 (RA durability rule present):** Hard rule 6 present, asserts behavioral-not-procedural + no forward-looking file-path/line-number anchors.
- **AC-2 (good/bad exemplar present):** good entry ("names the behavior / interface / type, not the line it currently lives on") + bad entry (procedural location instruction in prose) form the contrast pair.
- **AC-3 (forward/backward boundary explicit):** Hard rule 6's exemption clause names `.harness/rules/05-insight-index.md` and stage-doc EVIDENCE as exempt — single source of the boundary.
- **AC-4 (PM dispatch one-liner present):** present in "Cross-task memory".
- **AC-5 (insight-surfacing preserved):** the existing insight-surfacing paragraph (lines 51-57, incl. "include the relevant line(s) in the dispatch prompt") is byte-present and unweakened; the new line is appended after it.
- **AC-6 (no contradiction / protected files untouched):** `.harness/rules/05-insight-index.md` and `.harness/insight-index.md` not in the T-05 edit set; the exemption clause references them rather than altering them.
- **AC-7 (caps + gate green):** both agents ≤300; `verify_all.sh` 32/0/0.
- **AC-8 (version + CHANGELOG fan-out):** four stamps at 0.36.0; CHANGELOG `[0.36.0]` states counts unchanged (16 skills / 8 framework agents / 32 checks); G.3/G.4 green.
- **AC-9 (additive only):** the three RA edits and the one PM edit are pure insertions — no existing Hard rule, output section, list entry, or routing rule deleted.

## Condition self-review

- **C-1 (no literal `path-token`):** every reference to the concept is PROSE. Hard rule 6 uses "file:line" as a word and "path-and-line" / "file paths or line numbers" as descriptions. The bad exemplar uses plain prose ("the field on the function around the middle of the handler file") — no literal `name.ext:NNN` sequence. The PM line uses "file:line" as a word. The CHANGELOG body uses "file-path/line-number", "path-and-line", "file:line" as prose. This 04 doc likewise carries no literal banned-anchor token. **Honored.** Confirmed clean by verify_all.sh I.6 = PASS.
- **C-2 (additive-only for both agent files):** my T-05 edits add only `+` lines; no `-` line is attributable to T-05. The `-` lines visible in the HEAD-relative diff belong to prior uncommitted stream work (T-03 rule-1 + section-8 rework; T-02 CONTEXT.md workflow step), not T-05. All six existing RA Hard rules and all existing PM sections remain present. **Honored.**

## Design drift

None. All four edits use the verbatim text from §4a / §4b / §5a / §10. No deviation.

## Open issues for review

- The shared working tree carries uncommitted changes from prior stream tasks (T-02/T-03 and others: `solution-architect.md`, `verify_all.{ps1,sh}`, `docs/*`, etc.). These are NOT T-05 scope. A HEAD-relative `git diff` therefore shows more than T-05 touched; the T-05 scope is the seven files listed under "Files changed". The reviewer should scope review to those seven.

## Dev-map updates

None. No file added/moved/removed; no module structure change. `docs/dev-map.md` not edited by T-05.

## git diff --name-only (T-05 scope)

```
agents/requirement-analyst.md
agents/pm-orchestrator.md
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
README.md
README.zh-CN.md
CHANGELOG.md
```

## Verdict

READY FOR REVIEW
