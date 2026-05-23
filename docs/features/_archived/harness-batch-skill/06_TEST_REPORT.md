# 06 — Test Report

## Scope

T-006 (`harness-batch-skill`) is a markdown-only change: one new skill, one new docs directory, one CHANGELOG entry, threaded skill-count updates across `verify_all.{sh,ps1}` + 4 doc files + 4 version stamps. There is no runtime/binary code to unit-test. QA verification is therefore:

1. **Tool-evidence grep** for every AC's contractual artifact (file presence, exact phrase, column header, version literal).
2. **`scripts/verify_all.ps1` × 3 runs** for stability + 31/31 PASS.
3. **`scripts/verify_all.sh`** attempted; documented Windows-bash I.6 subprocess deadlock (pre-existing, not introduced by T-006).
4. **Adversarial reproducer per AC** — each with a stated falsifiable hypothesis written BEFORE the run.

No baseline.json change required (no new check added; `verify_all_checks` stays at 31).

## Test plan

| Acceptance criterion | Reproducer | File / Evidence |
|---|---|---|
| AC-1 skill exists, dispatches via Task | `grep -n "allowed-tools" skills/harness-batch/SKILL.md` and grep for "pm-orchestrator" + "`Task` tool" | `skills/harness-batch/SKILL.md:4,54` |
| AC-2 context isolation (per-task summaries only) | grep `SKILL.md` for "OWN context" / "summary" prose | `SKILL.md:54,115` |
| AC-3 5 strong-signal stops | grep `SKILL.md` for FAILED, verify_all, intervention, guard-rm, rollback | `SKILL.md:62-65` |
| AC-4 resume idempotency | grep `SKILL.md` for `Status: done`, idempotent, skip, 07_DELIVERY | `SKILL.md:49,74-79` |
| AC-5 BATCH_PLAN columns + blocked-on-dependent | column-header grep + `blocked` grep | `_template/BATCH_PLAN.md:9`, `SKILL.md:57-59` |
| AC-6 docs/batches/README ≤80 + worked example | `wc -l`, `Worked example` heading grep | `docs/batches/README.md` |
| AC-7 11-skills lockstep (4 doc files + 6 hardcoded lists) | grep `10 skill` (expect 0 live hits), grep `11 skill` (expect ≥4 live hits), `harness-batch` literal in all 6 array locations | `AI-GUIDE.md:7`, `README.md:7`, `README.zh-CN.md:7,13`, `manual-e2e-test.md:7,34,49`, `verify_all.{sh,ps1}` |
| AC-8 4-way version stamp at 0.19.0 | grep `"version"` in 2 JSON manifests + `version-X.Y.Z` badge regex in 2 READMEs | `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:17`, `README.md:5`, `README.zh-CN.md:5` |
| AC-9 verify_all 31/31 PASS | `pwsh -NoProfile -File scripts/verify_all.ps1` ×3 | summary blocks below |
| AC-10 CHANGELOG `[0.19.0]` + `harness-batch` literal | `grep "^## \[0\.19\.0\]"` + count `harness-batch` mentions | `CHANGELOG.md:10` (10 mentions) |

## Boundary / regression tests

- **I.4 insight-index ≤30 lines** (regression): `wc -l .harness/insight-index.md` → 30. PASS.
- **No `{{…}}` placeholder in new files** (D.2 regression): grep `\{\{` in `skills/harness-batch/` and `docs/batches/` → no matches. PASS.
- **I.6 banned-phrase guard** (regression): PS verify_all explicitly PASSes I.6 (visible in summary). Confirms no new `10 skill` / `ten skill` / etc. drift was introduced into a live production file by T-006.
- **G.3 4-way version-stamp consistency** (regression): PS verify_all explicitly PASSes G.3 at `0.19.0` literal.

## Adversarial tests (REQUIRED — one independent reproducer per AC)

Each row was written by QA from the acceptance criterion text alone (not from Dev's reported grep evidence), with the failure hypothesis stated **before** the run.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (actual tool output) |
|---|---|---|---|
| **AC-1** | …if `allowed-tools` is missing `Task`, or if the procedure body never names "Task tool" / "pm-orchestrator" together — skill would be unable to dispatch sub-agents | `Grep allowed-tools skills/harness-batch/SKILL.md` AND `Grep "pm-orchestrator\|Task tool\|Task\` tool" skills/harness-batch/SKILL.md` | **Survived** — `4:allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite, Task` (Task last), and `54: c. Dispatch \`pm-orchestrator\` via the \`Task\` tool. … The sub-agent runs in its OWN context — the batch skill never sees the full stage docs, only the return summary.` |
| **AC-2** | …if the procedure tells the skill to read 07_DELIVERY.md fully (would accumulate stage doc content in batch context) rather than just a one-line summary | `Grep "OWN context\|return summary\|07_DELIVERY" skills/harness-batch/SKILL.md` | **Survived** — `54: … sub-agent runs in its OWN context — the batch skill never sees the full stage docs, only the return summary.` and `115: Each task's pm-orchestrator runs in its own context, so the batch orchestrator's context grows by ~one summary line per task, not by N × per-task stage docs.` 07_DELIVERY appears only as a *check for existence* (line 49, 78) and as a *summary field name* (line 55), never as "read full contents into batch context." |
| **AC-3** | …if any of the 5 strong-signal stops (FAILED verdict / verify_all FAIL / 3 rollbacks / intervention STOP / guard-rm block) is missing or vaguely worded in the strong-signal section | `Grep "FAILED\|verify_all\|intervention\|guard-rm\|rollback" skills/harness-batch/SKILL.md` and inspect lines 62-65 | **Survived** — `SKILL.md:62-65` lists 4 explicit bullets covering all 5 signals; the 3-rollback signal is intentionally folded into the FAILED-verdict bullet with the m-2 parenthetical: `62: … pm-orchestrator returns \`FAILED\` verdict (the externally-visible form of pm-orchestrator's "3 same-stage rollbacks → STOP" hard rule — either signal alone triggers stop).` `63: verify_all returns FAIL after a task …` `64: .harness/intervention.md contains STOP …` `65: safety hook (scripts/guard-rm) blocked …`. All 5 enumerated and each is a strong stop. |
| **AC-4** | …if SKILL.md doesn't actually explain how it *detects* already-done tasks (only "skips" without detection rule) | `Grep "Status: done\|idempotent\|skip\|07_DELIVERY" skills/harness-batch/SKILL.md` | **Survived** — explicit dual-check detection rule at `SKILL.md:49` (`Tasks marked Status: done, OR whose 07_DELIVERY.md … exists with DELIVERED verdict (primary) … falling back to Final verify_all result: PASS (secondary)`) and reinforced at `SKILL.md:74-79` ("Resume semantics" subsection: `Status: done → skip without re-evaluation; pending/in-progress/failed/blocked → re-evaluate by 07_DELIVERY.md check`). |
| **AC-5** | …if BATCH_PLAN.md header doesn't match the exact specified column order, or if SKILL.md doesn't handle blocked-on-dependent-fail | `Grep "\| ID \| Slug \| Goal" docs/batches/_template/BATCH_PLAN.md` + `Grep "blocked" skills/harness-batch/SKILL.md` | **Survived** — `_template/BATCH_PLAN.md:9: \| ID \| Slug \| Goal (one sentence) \| Mode \| Depends on \| Status \|` (all 6 columns, exact order). `SKILL.md:59: h. If the task FAILED, mark every task whose Depends on chain includes it as blocked (skip without dispatching), then stop the batch (do not auto-continue after a failure).` Explicit blocked handling. |
| **AC-6** | …if `docs/batches/README.md` >80 lines or lacks a worked example heading | `wc -l docs/batches/README.md` + `Grep "Worked example\|worked example" docs/batches/README.md` | **Survived** — `60 c:/Programs/HarnessEngineering/docs/batches/README.md` (≤80 cap satisfied with 20 lines headroom). Worked example heading at `26:## Worked example`, with full 3-task BATCH_PLAN.md inline example + happy-path narration + failure-path counterfactual (lines 27-58). |
| **AC-7** | …on the recurring Insight L5 drift — at least one live doc file still says "10 skills" or one of the 6 hardcoded arrays misses `harness-batch`. This is the hypothesis with the highest historical hit rate. | `Grep "10 skill\|ten skill\|10 个 skill\|10 个 AI skill"` across AI-GUIDE.md, README.md, README.zh-CN.md, docs/manual-e2e-test.md (expect 0 matches) + `Grep "harness-batch"` in verify_all.sh + verify_all.ps1 (expect 3+3=6 matches) + `Grep "11 skill\|eleven skill\|11 个 skill\|11 个 AI skill"` in the 4 docs (expect ≥4 matches) | **Survived** — `Grep "10 skill\|ten skill\|..."` across the 4 live docs returned **No matches found**. `Grep "11 skill\|eleven skill\|..."` returned 6 hits across the 4 files (`AI-GUIDE.md:7`, `README.md:7`, `README.zh-CN.md:7,13`, `manual-e2e-test.md:7,34,49`). `Grep "harness-batch"` in verify_all.sh hit lines `55, 329, 345`; in verify_all.ps1 hit lines `68, 301, 327` — all 6 hardcoded arrays carry the new entry. **The recurring drift is closed.** |
| **AC-8** | …if even one of the 4 version stamps is stale at 0.18.2 — G.3 would FAIL hard | `Grep "version" .claude-plugin/plugin.json` + `marketplace.json` + `Grep "version-[0-9]+\.[0-9]+\.[0-9]+" README.md README.zh-CN.md` | **Survived** — all 4 exactly `0.19.0`: `plugin.json:4: "version": "0.19.0"`, `marketplace.json:17: "version": "0.19.0"`, `README.md:5: ![version](https://img.shields.io/badge/version-0.19.0-blue)…`, `README.zh-CN.md:5: ![version](https://img.shields.io/badge/version-0.19.0-blue)…`. And verify_all's G.3 4-way consistency check PASSes (visible in PS run 1 summary). |
| **AC-9** | …if verify_all reports any FAIL or fewer than 31 PASS, or if it's flaky across runs | `pwsh -NoProfile -File scripts/verify_all.ps1` × 3 sequential runs | **Survived** — all 3 runs: `PASS: 31 / WARN: 0 / FAIL: 0`. Run 1 included full per-check log (all 31 PASS individually shown). Bash twin attempted with 60s timeout: reached check 29 (I.7) all PASS before hitting the documented Windows-bash I.6 subprocess deadlock (Dev 04_DEVELOPMENT.md confirms this is a pre-existing environmental quirk of Git-for-Windows bash under Claude-Code, not introduced by T-006). The 3 modified checks (C.1, G.1, G.2 — all "11 skills") PASS in bash too. PS is the canonical Windows gate per F.1. |
| **AC-10** | …if CHANGELOG lacks `## [0.19.0]` section or that section doesn't mention `harness-batch` literally (G.2 would FAIL) | `Grep "^## \[0\.19\.0\]" CHANGELOG.md` + count `harness-batch` mentions in file | **Survived** — `CHANGELOG.md:10: ## [0.19.0] - 2026-05-23`. `harness-batch` literal appears **10 times** in CHANGELOG.md (count grep returned `CHANGELOG.md:10 Found 10 total occurrences`). G.2 verify_all check confirms in PS run 1 summary: `[G.2] CHANGELOG mentions all 11 skills … PASS`. |

## verify_all result

- **Total checks**: 31 → 31 (no new check; matches `baseline.json: verify_all_checks: 31`)
- **PASS**: 31 (every run)
- **FAIL**: 0
- **WARN**: 0
- **New tests added**: 0 (no automated test layer applies to a markdown-skill change; the adversarial grep table above IS the test layer)
- **Baseline updated**: no (no metric moved; `verify_all_checks` stays at 31, no test-script assertion-count change)

### Per-run summary tallies (PS, canonical Windows gate)

```
Run 1 (full per-check log captured):
=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 0

Run 2:
=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 0

Run 3:
=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 0
```

### Bash twin (best-effort, expected partial run on Windows)

```
[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 11 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Template agents complete ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[F.2] Guard-rm scripts and PreToolUse wiring present ... PASS
[G.1] README references all 11 skills ... PASS
[H.1] Test fixtures present ... PASS
[G.2] CHANGELOG references all 11 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.1] AI-GUIDE.md ≤200 lines ... PASS
[I.2] Rule fragments ≤200 lines each ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.4] insight-index.md ≤30 lines ... PASS
[I.5] docs/tasks.md ≤300 lines ... PASS
[I.7] Ignored INTERVENE supervision reports (WARN if >48h old on active task) ... PASS
[killed after 60s on I.6's known Windows-bash subprocess deadlock — pre-existing per 04_DEVELOPMENT.md]
```

All 3 T-006-modified checks (C.1, G.1, G.2 — "11 skills" assertions) PASS in bash too before the kill. PS run 1 explicitly shows I.6 PASS (`[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS`), so the banned-claim guard is satisfied — no new "10 skill" / "ten skill" drift was introduced by T-006 into a live production file.

## Defects found

None. All 10 ACs survived their adversarial reproducer. All 31 verify_all checks PASS, 3 runs stable.

## Stability

PS verify_all.ps1 ran 3 times consecutively. All three: `PASS: 31 / WARN: 0 / FAIL: 0`. No flakes observed.

## Verdict

**APPROVED FOR DELIVERY**
