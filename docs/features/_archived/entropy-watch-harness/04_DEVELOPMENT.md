# Development Record — T-11b `entropy-watch-harness`

## Summary
Wired the cadenced anti-entropy watch into the `/harness` single-task delivery boundary by
adding the §6a stage-7 subsection to `agents/pm-orchestrator.md` (the one authoritative home)
plus a single referencing line to `skills/harness/SKILL.md` step 10. Pure documentation wiring
over the T-11a core (no new script/skill/state/check). Folded in both gate conditions (F-1
supervisor enumeration, F-2 dev-map parenthetical) and bumped 0.41.0 → 0.42.0.

## Files changed
- `agents/pm-orchestrator.md` — inserted the `### Entropy watch at delivery (cadenced, non-blocking — full mode only)` subsection between the "Then run archive-task" paragraph and the "## When to stop and ask the user" heading. Full-mode guard is the FIRST sentence; the 3-step sequence is `entropy-cadence delivered` → plain `entropy-cadence check` (no `--first-of-session`) → if DUE: supervisor entropy-mode scan (references `references/entropy-scan.md`, not restated) + append `## Entropy watch` to 07_DELIVERY.md + `entropy-cadence swept`. Ordering note: compose 07_DELIVERY → entropy watch → tasks.md → archive-task. (§6a verbatim.)
- `skills/harness/SKILL.md` — step 10: appended ONE referencing clause pointing at `agents/pm-orchestrator.md` → "Entropy watch at delivery". No duplicated call-sequence/section-format prose. (§6b.)
- `agents/supervisor.md` — **F-1:** updated the entropy-mode dispatcher enumeration in three places (Hard-rule-1 exception line, the `## Entropy lens` heading, and the blockquote) to name the `/harness` single-task delivery as a THIRD dispatcher alongside `/harness-deflate` and a due `/harness-stream` drain.
- `docs/dev-map.md` — **F-2:** dropped the "(and later `/harness`)" parenthetical on the entropy-cadence reusable-utilities row → now "called by `/harness-stream` AND `/harness`" (shipped state). Only one parenthetical existed (L174); no "(later `/harness`)" at L103.
- `.claude-plugin/plugin.json` — `version` 0.41.0 → 0.42.0 (stamp 1/4).
- `.claude-plugin/marketplace.json` — `plugins[0].version` 0.41.0 → 0.42.0 (stamp 2/4).
- `README.md` — version badge token `version-0.41.0-blue` → `version-0.42.0-blue` (stamp 3/4).
- `README.zh-CN.md` — version badge token likewise (stamp 4/4).
- `CHANGELOG.md` — prepended `## [0.42.0] - 2026-06-20` section (§6c). The 17 / 8 / 32 counts are stated as descriptive "all unchanged" prose (no flip).

## verify_all result
- Baseline (before changes): PASS 32 / WARN 0 / FAIL 0.
- After changes: PASS 32 / WARN 0 / FAIL 0.
- Delta: 0 new failures, 0 new warnings, baseline preserved. G.3 confirms all four version stamps at 0.42.0; G.4 confirms the CHANGELOG `## [0.42.0]` heading + count-claim consistency against plugin.json.
- `bash .harness/scripts/test-supervisor.sh` (supervisor.md was edited): PASS 45 / FAIL 0 — structural asserts (AP-ids/severity/tools/≤300, doc fan-out) intact.
- PowerShell side (`verify_all.ps1`) is PM-to-run (PowerShell denied to sub-agents per the harness's known constraint).

## Acceptance-criteria + condition self-review
- **AC-1 (below-threshold → no scan/section):** the §6a subsection branches `NOT-DUE → no scan, no section, delivery unchanged`. Plain `check` is counter-only, so isolated early deliveries stay below N=5. ✔
- **AC-2 (≥N → one scan + section + reset):** §6a steps 3-5 dispatch the supervisor once, append `## Entropy watch` (findings table | `None.` + artifact link + `/harness-deflate` opt-in note), then `swept`. ✔
- **AC-3 (plain `check`, no `--first-of-session`):** §6a step 2 calls `entropy-cadence check` with the explicit "WITHOUT `--first-of-session`" note; grep confirms no `--first-of-session` in the `/harness` home. ✔
- **AC-4 (non-blocking / fail-open):** subsection opens "non-blocking and fail-open … never changes the delivery verdict, never gates or halts"; step 4 omits the section but still runs step 5 on a missing artifact. ✔
- **AC-5 (DRY):** `entropy-cadence delivered` call-sequence appears in exactly ONE place (`agents/pm-orchestrator.md` L208); `skills/harness/SKILL.md` has 0 occurrences of `entropy-cadence` (pointer-only). Scan single-sourced via `references/entropy-scan.md`. ✔
- **AC-6 (counts + version):** plugin.json reads 0.42.0; 17 skills / 8 framework agents / 32 checks claims unchanged; no new check (count stays 32, G.4 last); verify_all PASS 32/32. ✔
- **AC-7 (unified counter):** both surfaces call the same `entropy-cadence` pair against the same `.harness/entropy-watch.state`; documented in §6a + CHANGELOG. ✔
- **Goal-mode guard:** the full-mode guard is the FIRST sentence of §6a (`agents/pm-orchestrator.md` L198) — a `goal`-mode stage-7 exit hits it and skips the subsection. ✔
- **F-1 (supervisor enumeration):** three locations now name `/harness` as a third entropy-mode dispatcher; test-supervisor green; supervisor.md ≤300. ✔
- **F-2 (dev-map parenthetical):** "(and later `/harness`)" removed; row now reflects both `/harness-stream` AND `/harness`. ✔

## Line counts (≤300 cap, I.3)
- `agents/pm-orchestrator.md`: 250 lines (was 208; +42). Under 300. ✔
- `agents/supervisor.md`: 280 lines (was 279 committed-base; T-11a working-tree entropy lens + my F-1 enumeration touches). Under 300. ✔

## Design drift (if any)
None. Implementation matches §6a verbatim, §6b (single referencing line), §6c (CHANGELOG), and the F-1/F-2 gate conditions exactly.

## Open issues for review
- The committed HEAD base is 0.40.0 with uncommitted T-11a working-tree changes (16→17 skills, version→0.41.0 stamps, supervisor entropy lens, dev-map deflate rows) present but not yet committed. T-11b layers cleanly on top of that working tree; `git diff --name-only` therefore lists T-11a files alongside the T-11b ones. The T-11b-attributable edits are the 9 files in "Files changed". Reviewer/PM should be aware the diff is T-11a + T-11b combined against HEAD@0.40.0.
- No code-level open issues; this slice is documentation wiring.

## Dev-map updates
No structural change to the project (no files added/moved/removed). The existing dev-map entropy-cadence row was edited for F-2 accuracy ("(and later `/harness`)" → "AND `/harness`"); no new line appended.

## T-11b git diff --name-only (full working tree against HEAD; T-11b-attributable subset noted)
```
.claude-plugin/marketplace.json      (T-11b: version 0.42.0)
.claude-plugin/plugin.json           (T-11b: version 0.42.0)
.gitignore                           (pre-existing T-11a working-tree)
.harness/insight-index.md            (pre-existing T-11a working-tree)
.harness/rules/40-locations.md       (pre-existing T-11a working-tree)
.harness/scripts/verify_all.ps1      (pre-existing T-11a working-tree)
.harness/scripts/verify_all.sh       (pre-existing T-11a working-tree)
AI-GUIDE.md                          (pre-existing T-11a working-tree)
CHANGELOG.md                         (T-11b: ## [0.42.0] prepended)
README.md                            (T-11b: version badge; pre-existing T-11a 16→17 prose)
README.zh-CN.md                      (T-11b: version badge; pre-existing T-11a 16→17 prose)
agents/pm-orchestrator.md            (T-11b: §6a stage-7 subsection)
agents/supervisor.md                 (T-11b: F-1 enumeration; pre-existing T-11a entropy lens)
docs/batches/default/BATCH_PLAN.md   (pre-existing T-11a working-tree)
docs/batches/default/STREAM_LOG.md   (pre-existing T-11a working-tree)
docs/dev-map.md                      (T-11b: F-2 parenthetical; pre-existing T-11a deflate rows)
docs/features/_archived/insight-history.md  (pre-existing T-11a working-tree)
docs/getting-started.md              (pre-existing T-11a working-tree)
docs/manual-e2e-test.md              (pre-existing T-11a working-tree)
docs/tasks.md                        (pre-existing T-11a working-tree)
skills/harness-stream/SKILL.md       (pre-existing T-11a working-tree)
skills/harness/SKILL.md              (T-11b: step 10 referencing line)
```

## Verdict
READY FOR REVIEW
