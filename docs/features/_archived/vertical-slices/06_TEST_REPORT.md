# Test Report — vertical-slices (T-06)

> Stage 6 (QA Tester). Mode: full. deferred-human mode: defer, do not ask.
> Scope: T-06's 9 files only (sibling-task working-tree churn — T-03 harness-grill 15→16, T-05 durable-brief, default-pool/dev-map/install — explicitly excluded per dev doc "Open issues for review").
> Verify-don't-trust: every claim below is backed by a tool run (grep / git diff / verify_all.sh) pasted inline. PowerShell `verify_all.ps1` is operator-pending (PS denied to this agent) — NOT faked, NOT attested as run.

## Nature of this task & test strategy

T-06 is a **Markdown-only authoring-discipline** change: one single-sourced section + three by-name pointers + version stamps + CHANGELOG. There is no executable production code, so the "test suite" for this task is **the project's own gate (`verify_all.sh`) plus targeted adversarial greps/diffs** that encode each acceptance criterion as a reproducible check. Per out-of-scope 3 / `feedback_design_over_guards`, the discipline is **guidance, not a gate** — adding a new `verify_all` check or unit-test fixture for it is explicitly forbidden by the design. Therefore **no new automated test file is added and the test-count baseline does not increase** (this is the correct outcome for this task class, not a gap). The baseline's `verify_all_checks` stays **32**.

## Test plan

| Acceptance criterion | Test case(s) / probe | Evidence |
|---|---|---|
| AC-1 both concepts defined in exactly one SKILL.md | grep both defining sentences repo-wide | hits in `skills/harness-plan/SKILL.md` only (among shipped surfaces) |
| AC-2 defining sentences in one file; others point by name | grep "NOT a horizontal slice…" + "~120k tokens…" | no paste in batch/stream/BATCH_PLAN |
| AC-3 each row-authoring site has a by-name ref; no `../` deep link | grep pointer phrase + grep `../` in pointer files | 3 byte-identical pointers; zero `../` |
| AC-4 "NOT a horizontal slice of one layer" + "independently demoable/verifiable on its own" | read `harness-plan/SKILL.md:45` | both clauses verbatim |
| AC-5 ~120k window + "split or hand off before degrading" | read `harness-plan/SKILL.md:46` | both present verbatim |
| AC-6 `skills/` count unchanged (16) | `verify_all.sh` C.1 / G.1 / G.2 | PASS at 16 |
| AC-7 check count unchanged (32) | `verify_all.sh` summary + no script diff | 32 checks; no `verify_all` edit |
| AC-8 BATCH_PLAN column header byte-unchanged | `git diff HEAD -- BATCH_PLAN.md` | header/separator absent from diff (only +1 prose bullet) |
| AC-9 verify_all PASSes, zero delta | `bash verify_all.sh` | 32 / 0 / 0 |
| AC-10 shipped bump + CHANGELOG + no count contradiction | G.3 + G.4 + CHANGELOG read | 0.37.0 ×4 stamps + `[0.37.0]` entry; G.3/G.4 PASS |
| AC-11 no agents/* + no schema change | `git diff` agents/* (none) + BATCH_PLAN header (unchanged) | confirmed |

## Boundary tests added

No automated boundary tests are added (authoring-discipline change; no code path to exercise — see "Nature of this task"). Boundary conditions from RA §4 were instead verified by inspection/grep:
- **Single-source-target stability** — pointers name a stable heading string, no line number. Verified: all 3 carry `` `harness-plan` → "Task-decomposition discipline" `` (byte-identical).
- **No duplication** — defining sentences appear in exactly one shipped file. Verified by grep.
- **I.6 retired-claim guard** — new prose introduces no banned anchor; saved UTF-8. Verified: I.6 PASS + banned-list inspection (no vocabulary overlap).
- **Count-claim integrity** — no "16/8/32" token flipped by T-06; CHANGELOG restates them as UNCHANGED. Verified by G.4 PASS + CHANGELOG line 16.

## Adversarial tests (REQUIRED — one independent reproducer per probe, failure hypothesis first)

For each probe I wrote down the hypothesis "I expect failure when…", then ran an **independent** grep/diff/verify (not the developer's test code) and recorded the actual tool output. Verdict is based on whether the implementation **survived**.

| # | Probe | Hypothesis ("I expect failure when…") | Independent reproducer | Outcome (tool output) |
|---|---|---|---|---|
| 1 | Single-source integrity | a defining sentence was also pasted into batch/stream/template, breaking single-source | `grep -rn "NOT a horizontal slice of one layer"` + `grep -rn "~120k tokens on current state-of-the-art models"` | **Survived** — both sentences hit `skills/harness-plan/SKILL.md` only among shipped surfaces; other hits are CHANGELOG prose (I.6-exempt) + `docs/features/vertical-slices/*` stage docs + INPUT.md source quote (all expected). Zero hits in harness-batch/harness-stream/BATCH_PLAN. |
| 2 | Pointer byte-identity | a pointer used a different heading string or a `../FILE.md` deep path | `grep -rn "Task-decomposition discipline"` repo-wide; `grep` the exact pointer phrase in `skills/`+BATCH_PLAN; `grep "\.\./"` in pointer files | **Survived** — exactly 1 heading (harness-plan:41) + 3 by-name pointers (harness-batch:36, harness-stream:105, BATCH_PLAN:28), all carrying byte-identical `` `harness-plan` → "Task-decomposition discipline" ``. Zero `../` in any pointer file. |
| 3 | Concept fidelity | the vertical-slice or smart-zone rule was watered down / missing a required clause | read `harness-plan/SKILL.md:45-46` | **Survived** — :45 = "…independently demoable/verifiable on its own. It is **NOT a horizontal slice of one layer**…"; :46 = "…~120k tokens…split into smaller vertical slices, or handed off, **before** the model degrades." Both rules fully stated. |
| 4 | Schema integrity | the `\| ID \| … \| Status \|` header or separator was touched, or the pointer landed in the table | `git diff HEAD -- docs/batches/_template/BATCH_PLAN.md` | **Survived** — diff shows ONE added line (`**What makes a good row**` prose bullet under `## Column reference`). Table header (line 9) + separator (line 10) NOT in diff = byte-unchanged. Pointer is prose, not a table row. |
| 5 | No count flip | a "16 skills / 8 agents / 32 checks" token or a README verify/test/integration badge was flipped by the version bump | `git diff HEAD` README ×2 / plugin.json / marketplace.json; read README line 5; `verify_all.sh` G.3/G.4 | **Survived** — only the version token moved (→0.37.0) on 4 stamps. README line-5 `32%2F32` / `308%2F308` / `90%2F90` badges byte-intact. CHANGELOG `[0.37.0]` restates counts as **UNCHANGED**. (15→16 skills + harness-grill lines in the README diff are **T-03 sibling churn**, not T-06 — live tree is consistently 16, C.1/G.1/G.2/G.4 all PASS.) |
| 6 | Logic untouched | the harness-batch Procedure or harness-stream Ingest-triage logic was edited, not just appended to | `git diff HEAD` for both skill files | **Survived** — both diffs are purely additive (only `+` lines, zero `-`). batch: 1 pointer after `## Required input`, before `## Procedure`. stream: 1 pointer at `## Ingest triage` tail, before `## Procedure`. No procedure/triage logic line changed. |
| 7 | Version stamp consistency | one of the 4 stamps or the CHANGELOG heading missed 0.37.0 | read plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5, CHANGELOG:8; `verify_all.sh` G.3 | **Survived** — 0.37.0 on all 4 stamps + `## [0.37.0]` CHANGELOG heading. G.3 PASS (stamps consistent). |
| 8 | I.6 self-trip | the new prose contains a retired-claim banned anchor | `verify_all.sh` I.6 + read banned list (verify_all.sh:521-535) | **Survived** — I.6 PASS. Banned anchors (harness-adopt scaffolding, CLAUDE.md composition/generation, harness-sync→CLAUDE.md, 全程中文) have zero vocabulary overlap with "vertical slice / tracer-bullet / smart zone / decomposition / horizontal layer / ~120k". |

### Key tool output (verbatim)

`bash .harness/scripts/verify_all.sh` tail:
```
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

`git diff HEAD -- docs/batches/_template/BATCH_PLAN.md` (probe 4 — header NOT in hunk):
```
@@ -25,6 +25,7 @@
 - **Status** — `pending` (initial) | … | `skipped`. The skill writes; the user reads.
+- **What makes a good row** — each row should be a tracer-bullet vertical slice … See `harness-plan` → "Task-decomposition discipline".
```

## verify_all result

- Total tests / checks: **32 → 32** (no check added; correct per out-of-scope 3).
- PASS: **32**
- FAIL: **0** (required for approval — met).
- WARN: **0**
- New automated tests added: **0** (authoring-discipline change; encoding it as a `verify_all` check or unit test is forbidden by design — `feedback_design_over_guards`).
- Baseline updated: **no** — `verify_all_checks` stays 32; T-06 adds no test assertions. (The pre-existing baseline.json diff vs HEAD — `last_verify` date + `test_init_bash_no_python3_assertions` 270→273 — is **sibling-task churn**, not T-06, and is left as-is; T-06 makes zero baseline edit.)
- PowerShell `verify_all.ps1`: **operator-pending** (PS denied to this agent). Bash gate is green; the PS parity run is the operator's belt-and-suspenders, non-blocking.

## Defects found

**None.** 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR across all 8 adversarial probes and 11 acceptance criteria.

## Stability

`verify_all.sh` is deterministic (no randomness, no network, no concurrency in the checked surface); the gate ran clean. The probes are pure grep/diff over static Markdown — inherently non-flaky. Re-running any probe yields identical output. No flakes observed. ✅

## Verdict

**APPROVED FOR DELIVERY** — 11/11 acceptance criteria PASS, all 8 adversarial probes survived, `verify_all.sh` 32/0/0 (G.3 / G.4 / I.6 all PASS), zero defects, baseline preserved (32 checks, no test count change is the correct outcome for this task class). One non-blocking operator-pending item: run `verify_all.ps1` for PS parity.
