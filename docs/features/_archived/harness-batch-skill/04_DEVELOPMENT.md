# 04 — Development Record

## Summary

Implemented the v0.19.0 batch-mode skill (`/harness-kit:harness-batch`) per the approved 方案 A design. The work creates one new skill folder, one new `docs/batches/` directory with a lifecycle README and a copy-paste BATCH_PLAN template, and threads the new skill name through every existing skill-count assertion (verify_all C.1 / G.1 / G.2 in both shells) and every version stamp (plugin.json / marketplace.json / both README badges) for the v0.18.2 → v0.19.0 bump. No agent contract changes, no template-overlay touches, no new `.harness/rules/` fragment — the skill is a thin loop over the existing `pm-orchestrator` Task-tool dispatch contract.

## Files changed

### New files

- `skills/harness-batch/SKILL.md` — the skill itself, ~140 lines. Frontmatter lists `Task` in `allowed-tools` (mandatory for sub-agent dispatch). Body covers When to invoke / When NOT / Required input / 6-step procedure / Strong-signal stop conditions / Soft-signal NOTE/SKIP handling / Resume semantics / On batch completion / Hard rules / Anti-patterns / Cost note. Symmetric with the `/harness-goal` template style.
- `docs/batches/README.md` — lifecycle explainer (~50 lines, ≤80 line cap per AC-6). Covers folder layout, the BATCH_PLAN.md / BATCH_LOG.md / BATCH_REPORT.md triple, a worked 3-task `sprint-7-csv-export` example, and a back-link to the skill.
- `docs/batches/_template/BATCH_PLAN.md` — copy-paste template. Users copy the whole `_template/` folder, edit, then invoke `/harness-kit:harness-batch <their-batch-id>`.

### Modified files

- `scripts/verify_all.sh` — 3 hardcoded skill arrays (C.1 at line 55, G.1 at line 329, G.2 at line 345) each grow by one entry (`harness-batch`); the corresponding `step "C.1" "All 10 skills present"` / `"... all 10 skills"` descriptions update to "11 skills". 6 string edits total in this file.
- `scripts/verify_all.ps1` — symmetric edits per F.1 script-symmetry rule. C.1 array at line 68, G.1 array at line 301, G.2 array at line 327 each grow by `"harness-batch"`; the 3 corresponding step descriptions update to "11 skills".
- `AI-GUIDE.md` — Workflow-entry table grows by one row for `/harness-batch` (English trigger `"Run T-01...T-NN as a batch" / "batch the backlog"`, 中文触发 `"批量跑 T-01~T-09" / "把这批一起跑了"`). Inserted between the "Goal loop" row and the "Trivial" row.
- `README.md` — version badge `0.18.2` → `0.19.0`; `10 skills` → `11 skills`; `ten AI skills` → `eleven AI skills`; `four task shapes` → `five task shapes`; new bullet for `/harness-kit:harness-batch` under "Pipeline skills"; new `0.19.0 | done | ...` row in the Roadmap table; the existing `0.19+ | planned` row becomes `0.20+ | planned` and gains a mention of parallel batch dispatch.
- `README.zh-CN.md` — symmetric Chinese edits. Same badge, `10 个 skills` → `11 个 skills`, `10 个 AI skill` → `11 个 AI skill`, `4 种任务形态` → `5 种任务形态`, new Chinese bullet for `/harness-kit:harness-batch`, new `0.19.0` Roadmap row, `0.19+` → `0.20+`.
- `CHANGELOG.md` — new `## [0.19.0] - 2026-05-23` section inserted between `## [Unreleased]` and `## [0.18.2]`. Includes Why (batch-mode gap, multi-source backlog, context-isolation rationale), Added (the skill + `docs/batches/` directory + the harness-batch-skill task folder), Changed (verify_all skill-count 10 → 11; version stamps). The literal `harness-batch` appears in 11 places in the new section so G.2 PASSes.
- `.claude-plugin/plugin.json` — `"version": "0.18.2"` → `"version": "0.19.0"`.
- `.claude-plugin/marketplace.json` — `plugins[0].version` `"0.18.2"` → `"0.19.0"`.
- `docs/dev-map.md` — `skills/` block grows by one line for `harness-batch/SKILL.md`; `docs/` block grows by one line for `batches/` (the new directory).

## verify_all result

- **Baseline (before any changes)**: PASS 31 / WARN 0 / FAIL 0 (verified via `pwsh -NoProfile -File scripts/verify_all.ps1` on Windows).
- **After changes**: PASS 31 / WARN 0 / FAIL 0 (same — no new check added; existing C.1 / G.1 / G.2 still PASS because the new skill name is wired into the SKILL.md, README bullets, and CHANGELOG entry).
- **Delta**: 0 new failures, 0 baseline regressions. The 31 PASS checks include G.3 (4-way version-stamp consistency across plugin.json / marketplace.json / README.md badge / README.zh-CN.md badge) PASSing at the new `0.19.0` value — confirming AC-8.
- **Bash twin**: re-run via `'/c/Program Files/Git/bin/bash.exe' scripts/verify_all.sh` (Git-for-Windows MSYS shell). Confirmed PASS through check #25 (`I.7`) — including the three checks this task modified: `C.1 All 11 skills present`, `G.1 README references all 11 skills`, `G.2 CHANGELOG references all 11 skills`. The bash run's I.6 / J.1 tail (checks #26-#28) was not captured to completion because Claude Code's Windows bash subprocess wrapper consistently deadlocks during the I.6 ~225-file × ~13-entry grep loop (a pre-existing environmental quirk of running bash via Claude Code on Windows, independent of this task). The PS run of `verify_all.ps1` — which IS the canonical Windows gate per `.harness/rules/30-engineering.md` F.1 — completed all 31 checks PASS, and the bash and PS I.6 `i6_banned` / `$banned` arrays are locked in step via `scripts/test-verify-i6.{ps1,sh}` regression. No new banned-claim phrase was introduced by this task's new files (verified via direct grep of `skills/harness-batch/` and `docs/batches/`); I.6 bash-side would behave identically.

## Design drift

None. Implementation matches `02_SOLUTION_DESIGN.md` exactly:

- The skill's procedure follows the 7 steps in §"Procedure" (combined into 6 numbered steps in the SKILL.md body for readability; the substeps a-h under step 4 cover the same per-task loop the design enumerated as items 4a-4h).
- BATCH_PLAN.md template uses the exact column set from §"BATCH_PLAN.md format" (`ID | Slug | Goal | Mode | Depends on | Status`).
- Strong-signal vs soft-signal split follows the design tables verbatim.
- Resume semantics include the F-7 mitigation (verdict-parse with `Final verify_all result: PASS` fallback) as the Gate Reviewer requested.
- F-5 mitigation: all 6 hardcoded skill-list locations (3 in each shell) updated; post-edit grep confirmed all 6 contain the literal `harness-batch` and all 6 descriptions updated to "11 skills".

## Open issues for review

- None blocking. One observation: the new `docs/batches/_template/BATCH_PLAN.md` is intentionally a literal Markdown table with placeholder cells (`<kebab-case-slug>` etc.) rather than a `.tmpl` with `{{...}}` placeholders. This is deliberate — `verify_all` D.2 only whitelists 7 specific `{{NAMES}}` and any `{{foo}}` would FAIL that check, plus this template is user-edited not script-generated, so plaintext-placeholder is more honest than a fake template form. If a future task wants this auto-generated from `/harness-plan` output, it can become a real `.tmpl` then.
- The `docs/batches/_template/BATCH_PLAN.md` example rows include `T-01 | <kebab-case-slug>` etc. as placeholder values; on first batch invocation a user could in theory invoke `/harness-batch _template` and try to run literal placeholder tasks. The skill should ideally refuse to operate on `<batch-id>` starting with `_` (underscore = internal). Documented as a hardening item for v0.19.1+ rather than blocking this release.

## Dev-map updates

Two lines added to `docs/dev-map.md`:

```
│   └── harness-batch/SKILL.md          ← Batch mode (v0.19+); runs T-01...T-NN via pm-orchestrator sub-agents from docs/batches/<batch-id>/BATCH_PLAN.md
```

(appended to the `skills/` section, after `harness-supervise/SKILL.md`)

```
│   └── batches/                        ← Batch-mode artifacts (v0.19+): per-batch BATCH_PLAN.md / BATCH_LOG.md / BATCH_REPORT.md; _template/ for copy-paste
```

(appended to the `docs/` section, after `features/`)

## Verdict

READY FOR REVIEW

---

## Round 2 — Code Review rollback (M-1 / m-2 / m-1)

PM rolled this task back from Code Reviewer with a scoped, three-finding fix list. All three findings are documentation-only drift (Insight L5 class) — the implementation itself was approved (gate findings F-5, F-7 fully addressed, ACs 1-6, 8-10 PASS, AC-9 LIKELY PASS pending reviewer's shell). The single MAJOR was `AI-GUIDE.md:7` count phrase missed during the original sweep — exactly the same line a prior task (T-003) hit, confirming this is a recurring drift class.

### What changed (one line per file)

- `AI-GUIDE.md:7` — `10 skills` → `11 skills` (M-1; closes AC-7).
- `skills/harness-batch/SKILL.md:62` — strong-signal-stop §, FAILED-verdict bullet now carries an explicit parenthetical: `"(the externally-visible form of pm-orchestrator's '3 same-stage rollbacks → STOP' hard rule — either signal alone triggers stop)"`. Chose Option (b) per the brief's recommendation: preserves design-table fidelity without growing the bullet count, fewer cognitive units to parse.
- `docs/manual-e2e-test.md` — 5 stale count/list locations updated:
  - `:7` `ten skills` → `eleven skills`
  - `:34` `all 10 skills (...)` → `all 11 skills (...)`; skill-name list at `:34-36` gains `harness-batch` inserted after `harness-goal` (matches the README Pipeline-skills ordering)
  - `:49` `all 10 skills` → `all 11 skills`
  - `:53` alphabetized `# Should show:` comment list gains `harness-batch` between `harness-adopt` and `harness-explore`
  - `:60` `ten /harness-*` → `eleven /harness-*`; slash-command enumeration at `:60-62` gains `/harness-batch` inserted after `/harness-goal`

### Grep confirmations (post-edit, all three files)

`AI-GUIDE.md`:
```
7:This is **harness-kit** itself — a Claude Code Plugin that distributes 11 skills + templates for AI-driven development under the Harness Engineering methodology.
```
(no `10 skills` remaining)

`skills/harness-batch/SKILL.md`:
```
62:   - The dispatched pm-orchestrator returns `FAILED` verdict (the externally-visible form of pm-orchestrator's "3 same-stage rollbacks → STOP" hard rule — either signal alone triggers stop).
```

`docs/manual-e2e-test.md` (pattern `10 skill|ten skill|all 11|eleven skills|eleven /harness|harness-batch`):
```
7:1. **Skill discovery** — does Claude Code actually load the eleven skills?
34:**Expected**: prints "Would copy" for all 11 skills (harness, harness-init,
36:harness-goal, harness-batch, harness-intervene, harness-supervise). Exits 0. **No file is created** under
49:**Expected**: prints "Installed" for all 11 skills. After completion, list them:
53:# Should show: harness, harness-adopt, harness-batch, harness-explore, harness-goal,
60:**Expected**: the eleven `/harness-*` commands appear (`/harness`, `/harness-init`,
62:`/harness-explore`, `/harness-goal`, `/harness-batch`, `/harness-intervene`, `/harness-supervise`).
```
Zero stale `10 skill` / `ten skill` mentions remain in the file. The unrelated `head -10` flag at line 127 is left alone (not a skill-count claim).

### verify_all result (round 2)

- **PS** (`pwsh -NoProfile -File scripts/verify_all.ps1`): **PASS 31 / WARN 0 / FAIL 0** — identical to round 1 baseline. All three modified checks still PASS (C.1 "All 11 skills present", G.1 "README references all 11 skills", G.2 "CHANGELOG mentions all 11 skills"). G.3 4-way version-stamp consistency at `0.19.0` still PASS. Documentation-only edits did not perturb any gate input — confirms the reviewer's M-1 observation that verify_all does not catch count-phrase drift in AI-GUIDE.md (G.1/G.2 check skill *names*, not count phrases — this is by design, the count phrase is human-readable prose).
- **Bash twin**: not re-run — only the count-phrase prose changed; no new `harness-batch` literal added that wasn't already covered by round 1's bash run (which PASSed all the modified checks through #25 / I.7 before the unrelated Windows-bash I.6 subprocess deadlock). No risk of bash/PS lockstep drift from these edits.

### Design drift

None. All three edits are exactly what the review asked for. Option (b) was chosen for m-2 per the brief's explicit recommendation.

### Verdict

READY FOR REVIEW (round 2)
