# Development Record — vertical-slices (T-06)

> Stage 4 (Developer). Mode: full. Implemented design §3/§4/§9 EXACTLY; honored all 6 carry-forward gate conditions.

## Summary

Added a single-sourced **task-decomposition discipline** (tracer-bullet vertical slice + smart-zone sizing) to `skills/harness-plan/SKILL.md`, and three one-line by-name pointers to it from the three row-authoring surfaces (harness-batch, harness-stream, BATCH_PLAN template). Bumped the plugin version 0.36.0 → 0.37.0 across the four G.3 stamps and prepended the `## [0.37.0]` CHANGELOG entry. Markdown-only, additive; no procedure/schema/check/agent changed.

## Files changed (9)

- `skills/harness-plan/SKILL.md` — **single source**: inserted `## Task-decomposition discipline` section between the `## Procedure` tail and `## Output` (verbatim design §3). Procedure steps 1-7 unchanged.
- `skills/harness-batch/SKILL.md` — appended one by-name pointer after the `## Required input` paragraph (design §4a). Procedure unchanged.
- `skills/harness-stream/SKILL.md` — appended one by-name pointer at the tail of `## Ingest triage` (design §4b). Triage LOGIC unchanged (out-of-scope 6).
- `docs/batches/_template/BATCH_PLAN.md` — appended a `**What makes a good row**` bullet under `## Column reference` after the `**Status**` bullet (design §4c). Table header (lines 9-10) byte-unchanged.
- `.claude-plugin/plugin.json` — `"version": "0.36.0"` → `"0.37.0"`.
- `.claude-plugin/marketplace.json` — `plugins[0].version` `"0.36.0"` → `"0.37.0"`.
- `README.md` — line-5 badge `version-0.36.0-blue` → `version-0.37.0-blue` (only that token).
- `README.zh-CN.md` — line-5 badge `version-0.36.0-blue` → `version-0.37.0-blue` (only that token).
- `CHANGELOG.md` — prepended `## [0.37.0] - 2026-06-20` (verbatim design §9) above `## [0.36.0]`.

## verify_all result

- Baseline (task start, `bash .harness/scripts/verify_all.sh`): **PASS 32 / WARN 0 / FAIL 0**.
- After changes (`bash .harness/scripts/verify_all.sh`): **PASS 32 / WARN 0 / FAIL 0**.
- Delta: **0 new failures, 0 new warnings; baseline preserved.** G.3 sees 0.37.0 across all 4 stamps; G.4 sees the `[0.37.0]` heading with counts consistent (16/8/32); I.6 clean; no new check (32 held). PowerShell `verify_all.ps1` is PM-to-run (denied to this agent) — not faked.

## Acceptance-criteria self-review

- **AC-1** both concepts (tracer-bullet vertical slice; smart-zone ~120k) defined in exactly one SKILL.md — yes, harness-plan only.
- **AC-2** defining sentences live only in harness-plan; the 3 others are by-name pointers — yes.
- **AC-3** all three row-authoring locations carry a by-name reference; none uses a `../other/FILE.md` deep link — yes (all name `harness-plan` + heading).
- **AC-4** vertical-slice def states "NOT a horizontal slice of one layer" + "independently demoable/verifiable on its own" — yes, both verbatim.
- **AC-5** smart-zone def states the ~120k window size + "split or hand off ... before the model degrades" — yes.
- **AC-6** `skills/` count unchanged (16) — yes (no skill added/removed; G.1/G.2 PASS).
- **AC-7** verify_all check count unchanged (32) — yes (no check added; summary 32).
- **AC-8 / AC-11** BATCH_PLAN column header byte-unchanged; no `agents/*.md` touched — yes.
- **AC-9** verify_all PASSes at the same total as task start — yes (32/32).
- **AC-10** shipped-content bump: version one minor step + CHANGELOG `## [0.37.0]` + no count contradiction (G.4 green) — yes.

## Gate-condition self-review (all 6 honored)

1. Heading exactly `## Task-decomposition discipline`; the 3 pointers' name-reference byte-identical — **honored** (`grep` shows 1 heading + 3 pointers all carrying the identical quoted string; 8 total byte-identical occurrences incl. CHANGELOG refs).
2. Touched only `version-0.3x.0-blue` on README line 5 — **honored** (`32%2F32` / `308%2F308` / `90%2F90` verified untouched on both READMEs).
3. CHANGELOG restates 16 skills / 8 framework agents / 32 checks as UNCHANGED — **honored** (verbatim §9 body; G.4 PASS, no count flip).
4. All 9 files saved UTF-8 — **honored** (`file` reports UTF-8 / JSON; no BOM on any file).
5. No 07 insight quoting an I.6 banned anchor — **N/A to this stage** (no 07 written here); I.6 PASS confirms the new prose introduces no banned anchor.
6. Run verify_all before done; expect 32/32 at the same total as task start — **honored** (32/0/0, zero delta).

## Design drift

None. Implementation is byte-for-byte the design §3 section text, the §4a/4b/4c one-liners at the specified insertion points, the four §9 stamps, and the §9 CHANGELOG entry verbatim.

## Open issues for review

None. The working tree carries unrelated pre-existing changes from sibling tasks (T-03/T-05 deliveries, default-pool stream files, dev-map, install scripts); those are NOT part of T-06 and were not touched by this stage.

## Dev-map updates

None required — no file added/moved/removed; the discipline is an additive section inside an existing skill and three in-place pointers. `docs/dev-map.md` already lists all edited files.

## T-06 git diff --name-only (the 9 source files + stage docs)

```
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
CHANGELOG.md
README.md
README.zh-CN.md
docs/batches/_template/BATCH_PLAN.md
skills/harness-batch/SKILL.md
skills/harness-plan/SKILL.md
skills/harness-stream/SKILL.md
docs/features/vertical-slices/   (untracked: 01-03 + INPUT + this 04 doc)
```

## Verdict

READY FOR REVIEW
