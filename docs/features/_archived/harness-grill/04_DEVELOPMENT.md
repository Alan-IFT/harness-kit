# Development Record — T-03 harness-grill

> Stage 4 (Developer). Mode: **full**. Upstream: 01 READY · 02 READY for Gate · 03 APPROVED FOR DEVELOPMENT (4 conditions C1-C4). Implemented EXACTLY per 02_SOLUTION_DESIGN §3/§4/§6 + the gate conditions.

## Summary

Shipped the 16th plugin skill `skills/harness-grill/SKILL.md` (a user-invoked, pre-pipeline, one-question-at-a-time alignment interview that emits an aligned brief to `docs/features/<slug>/INPUT.md` and stops), added a standing `Recommended:` rule to `agents/requirement-analyst.md` with a reconciled Hard-rule-1 strip-ban, and executed the complete 15→16 + version 0.35.0 release fan-out across 13 ledger files (incl. the 6 verify_all skill-name arrays + 6 labels in both shells) plus the soft install help-text in both shells. No new verify_all check (count stays 32). No test-init / baseline change.

## Files changed

### Family A — new plugin skill
- `skills/harness-grill/SKILL.md` — **NEW**. Frontmatter `name: harness-grill` + bilingual (EN+中文) model-facing `description:` with deliberate triggers and the when-NOT delta vs `/harness` / `/harness-plan` / `/harness-explore`; `allowed-tools` excludes `Task`/`Bash`/`PowerShell` (it cannot dispatch the pipeline, no helper). Body: When to invoke / When NOT to invoke / user-invoked-only posture / interview engine (one-at-a-time + wait, recommended answer per question, explore-codebase-to-self-answer, empty-answer default) / CONTEXT.md SOFT composition / the aligned-brief terminal artifact (propose-and-confirm kebab slug, confirm-before-overwrite, create-dir-as-needed, early-end residual items) / "Not a pipeline stage" / Anti-patterns (≥2 prohibitions named).

### Family B — standing rule (framework agent, plugin-native, no sync)
- `agents/requirement-analyst.md` — **EDIT ×2**. Edit 2 (section 8, `:23`): added the labelled `Recommended:` standing rule against the **verbatim live string** "numbered, with at least 2 candidate answers each." (C3). Edit 1 (Hard rule 1, `:28`): scoped the "recommend"/"suggest" strip-ban to requirement PROSE (in-scope behaviors / ACs / boundary conditions) and explicitly EXEMPTED the labelled `Recommended:` Open-Questions field, cross-referencing §8.

### Family C — release fan-out (13 files, 15→16 + 0.35.0)
- `.claude-plugin/plugin.json` — version `0.34.0` → `0.35.0`.
- `.claude-plugin/marketplace.json` — `plugins[0].version` → `0.35.0`.
- `README.md` — version badge → `0.35.0`; `15 skills` → `16 skills` (`:7`); `fifteen` → `sixteen` (`:13`); **C2: caption "(six task shapes…)" reconciled** to "(six task shapes the AI picks…, plus a pre-pipeline aligner)" + new `/harness-kit:harness-grill` bullet (framed "runs before the pipeline to align the requirement").
- `README.zh-CN.md` — version badge → `0.35.0`; `15 个 skills` → `16 个 skills` (`:7`); `15 个 AI skill` → `16 个 AI skill` (`:13`); caption gains a 中文 pre-pipeline-aligner qualifier + new 中文 grill bullet.
- `CHANGELOG.md` — new `## [0.35.0] - 2026-06-20` section above `## [0.34.0] - 2026-06-19`; contains literal `harness-grill` (multiple ×) and notes skill count `15 → 16` + version bump.
- `AI-GUIDE.md` — `15 skills` → `16 skills` (`:7`); new `/harness-grill` Workflow-entry row (EN + 中文 triggers agreeing with the SKILL.md `description:`). Stays at 110 lines (≤200, AC-10).
- `docs/getting-started.md` — `fifteen skills` → `sixteen skills` (`:36`); Pipeline group caption gains "plus a pre-pipeline aligner" + new `harness-grill` bullet.
- `docs/manual-e2e-test.md` — `fifteen`/`15 skills` → `sixteen`/`16 skills` at `:7`/`:34`/`:49`/`:60`; `harness-grill` added to all four enumerations/command listings.
- `.harness/rules/40-locations.md` — `All 15 skills` → `All 16 skills` (`:31`).
- `docs/dev-map.md` — new `harness-grill/SKILL.md` skills-tree row (prior last `└──` converted to `├──`) + new `Skill: harness-grill` "Where features live" lookup row.
- `.harness/scripts/verify_all.sh` — appended `harness-grill` to the C.1/G.1/G.2 name arrays (`:56`/`:329`/`:345`) AND flipped all 3 labels `15`→`16` (PASS+FAIL strings each).
- `.harness/scripts/verify_all.ps1` — appended `, "harness-grill"` to the C.1/G.1/G.2 arrays (`:69`/`:301`/`:327`) AND flipped all 3 labels `15`→`16` (F.1 symmetry).

### Soft (recommended) — install help-text parity
- `install.sh` — added a `/harness-grill` line to the "Use in Claude Code:" help block.
- `install.ps1` — symmetric `/harness-grill` Write-Host line (F.1 parity).

## Fan-out completeness self-check

- **34 doc-ledger sites (§6.2/§6.1/§6.3 #1-34):** all edited. Version stamps #1-4 ✔; skill-count/list #5-22 ✔; verify_all arrays+labels #23-34 ✔ (verified `grep -c harness-grill` = 3 in each shell's script).
- **6 array sites + 6 labels:** all 6 arrays carry `harness-grill` (3 sh + 3 ps, confirmed) and all 6 labels read `16` (C.1/G.1/G.2 each shell).
- **Soft install help-text:** both shells edited (row 13, §6.5).

## Condition self-review

- **C1 (frozen `15` decoys):** NOT touched — `.harness/insight-index.md:35`, `docs/proposals/plugin-native-redesign.html:65,136`. A live-tree grep for `15 skills`/`fifteen`/`15 个 skill`/`All 15 skills` returned only frozen-history surfaces: CHANGELOG `:85/:95/:109` (v0.30.1/0.30.0/0.29.0 historical entries), `docs/tasks.md:15/16/28/30` (append-only delivery records), the two C1 decoys, and CHANGELOG `:74`-class history — all intentionally left at `15`. Also UNCHANGED: every `32`/`(32 checks)`/`32%2F32`/`（32 项检查）` token, the `308`/`90` test badges, `baseline.json:skill_count_baseline:4`, harness-status `:135` "All 14 required assets".
- **C2 (README caption):** reconciled — caption now reads "six task shapes the AI picks…, plus a pre-pipeline aligner"; grill is framed as the pre-pipeline aligner, not a 7th shape. zh README caption given the equivalent qualifier. getting-started caption likewise.
- **C3 (verbatim §8 edit):** applied against the exact live `:23` string "numbered, with at least 2 candidate answers each." (not a paraphrase).
- **C4 (verify_all):** see verify_all result below — 32/0/0 on bash; PS twin is PM-to-run (sub-agents are PowerShell-denied; not faked).
- Pre-answered Q1: template `templates/common/AI-GUIDE.md.tmpl` Workflow table NOT touched. Q3: no new check (32 stays). Q4: no `.claude/skills/` copy, no harness-sync (top-level plugin skill; C.2 auto-scans `skills/**/SKILL.md` — confirmed `name:`+`description:` present). Q5: CHANGELOG `## [0.35.0]` heading present (G.4) + literal `harness-grill` (G.2); "recommend" is not an I.6 anchor and I.6 PASSed.

## verify_all result

- **Baseline (before changes):** verify_all.sh **32 PASS / 0 WARN / 0 FAIL**.
- **After changes:** verify_all.sh **32 PASS / 0 WARN / 0 FAIL**.
- **Delta:** 0 new failures, 0 new warnings. C.1 label now "All 16 skills present" + array finds `harness-grill` (PASS); C.2 frontmatter sanity scans the new SKILL.md (PASS); G.1 "README references all 16 skills" (PASS); G.2 "CHANGELOG references all 16 skills" (PASS); G.3 sees `0.35.0` across plugin.json/marketplace.json/both badges (PASS); G.4 sees `[0.35.0]` CHANGELOG heading + version-consistent claims (PASS). Check count derived dynamically — still **32**.

Additional Bash-runnable gates (C4):
- `bash .harness/scripts/test-init.sh` → **273 PASS / 0 FAIL** (unchanged from the T-02 baseline — grill is a plugin skill, no template asset, as designed).
- `bash .harness/scripts/test-real-project.sh` → **90 PASS / 0 FAIL** (unchanged).

**PM-to-run (PowerShell, denied to sub-agents — NOT faked):**
- `pwsh -File .harness/scripts/verify_all.ps1` → expect **32/0/0** (C.1/G.1/G.2 arrays + labels mirrored; G.3/G.4 read 0.35.0/[0.35.0]).
- `pwsh -File .harness/scripts/test-init.ps1` → expect green (no test-init change; PS count per `baseline.json`).
- `pwsh -File .harness/scripts/test-real-project.ps1` → expect green.

## Design drift (if any)

None. Implementation matches 02_SOLUTION_DESIGN §3 (SKILL.md content), §4 (RA edits, verbatim wording), and §6 (the 34-site ledger) exactly, with the 4 gate conditions applied. No `DESIGN DRIFT`.

## Open issues for review

- None blocking. Note for CR/QA: the AC-9 residual-`15` sweep should treat CHANGELOG `:85/:95/:109` and `docs/tasks.md:15/16/28/30` as frozen-history surfaces (same class as the C1 decoys) — these legitimately remain at `15` and are NOT live skill-count claims. (`docs/tasks.md` was not in the §6 ledger because its rows are append-only delivery history; confirmed every `15` there is inside a past-task record.)

## Dev-map updates

Added to `docs/dev-map.md`:
- Skills-tree row: `harness-grill/SKILL.md ← Pre-pipeline alignment interview (v0.35+); …emits an aligned brief…and stops (no helper script)`.
- "Where features live" row: `Skill: harness-grill | skills/harness-grill/SKILL.md | Pre-pipeline alignment interview (v0.35+)…no helper script`.

## Insight to surface (optional)

`docs/tasks.md` carries live `N skills` count tokens inside append-only delivery-record rows (e.g. "Counts stay 15 skills") that a 15→16 fan-out must NOT flip — they are frozen history, like the CHANGELOG historical entries, and were absent from the §6 ledger. · evidence: docs/tasks.md:15,16,28,30 (all "15 skills" inside past-task delivery rows)

## Verdict

READY FOR REVIEW
