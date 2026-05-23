# 05 — Code Review

## Verdict

**CHANGES REQUIRED** (1 MAJOR — AC-7 partial miss; multiple MINOR)

The implementation is otherwise solid and matches the design closely. The MAJOR issue is the recurring **Insight L5 drift class**: `AI-GUIDE.md` line 7 is explicitly named in AC-7 but the "10 skills" claim was not updated to "11 skills". This must be fixed before merge because (a) AC-7 calls it out by name and (b) the project has burned on exactly this drift before (the v0.13/v0.14 retro that motivated Insight L5).

`verify_all` does NOT catch this (G.1/G.2 check names, not the count phrase), so the gate doesn't reject it — but the AC does.

## AC verification

| AC | Status | Citation / Notes |
|---|---|---|
| **AC-1** | PASS | `skills/harness-batch/SKILL.md:36-65` — skill exists, §4c "Dispatch pm-orchestrator via the Task tool"; `docs/batches/_template/BATCH_PLAN.md` provided |
| **AC-2** | PASS | `SKILL.md:54` "sub-agent runs in its OWN context — batch skill never sees full stage docs, only return summary"; reinforced by Cost §115 |
| **AC-3** | PASS | `SKILL.md:61-65` lists 4 strong-signal stops; "3 same-stage rollbacks" folded into the FAILED-verdict bullet (functionally correct — see m-2) |
| **AC-4** | PASS | `SKILL.md:74-80` dual-check resume (DELIVERED primary + verify_all-PASS fallback) — F-7 mitigation |
| **AC-5** | PASS | `docs/batches/_template/BATCH_PLAN.md:9` columns exactly match design |
| **AC-6** | PASS | `docs/batches/README.md` = 60 lines (≤80 cap); worked example at lines 27-58 |
| **AC-7** | **MAJOR FAIL (partial)** | verify_all 6 locations + 6 description texts: PASS. README.md count phrases: PASS. README.zh-CN.md: PASS. **AI-GUIDE.md:7 still says "10 skills"** — see M-1 |
| **AC-8** | PASS | All 4 version stamps at 0.19.0 (plugin.json:4 / marketplace.json:17 / README.md:5 / README.zh-CN.md:5) |
| **AC-9** | LIKELY PASS | Reviewer cannot execute shells; source inspection + Dev's reported PS 31/31 PASS accepted as authoritative |
| **AC-10** | PASS | CHANGELOG.md:10 `[0.19.0]` section; `harness-batch` literal occurs 10× in file |

## Gate findings re-check

- F-1..F-4: OK; no action needed
- **F-5** (6-location hardcoded list): ADDRESSED; all 6 verified
- F-6: OK
- **F-7** (verdict-parse tolerance): ADDRESSED; dual-check at SKILL.md:49 + :78
- F-8..F-10: OK

## Independent checks (9 of 9)

1. Frontmatter `Task` tool: PASS — `SKILL.md:4` `Task` last in allowed-tools; description verbatim per design
2. 6 hardcoded skill-list locations: PASS — all 6 contain `harness-batch`; all 6 descriptions updated 10→11
3. 4 version stamps at 0.19.0: PASS
4. `docs/batches/README.md` size + example: PASS
5. `BATCH_PLAN.md` columns: PASS
6. CHANGELOG `[0.19.0]` mentions `harness-batch`: PASS
7. AI-GUIDE.md workflow-entry row: PASS — line 87 has English + 中文 triggers
8. `verify_all.ps1` 31/31: NOT EXECUTED (no shell tool); accepting Dev's report
9. Behavioral checklist in SKILL.md: PASS with m-2

## Findings

### MAJOR

**M-1** [AC-7 / MAINT] `AI-GUIDE.md:7` — still says `"a Claude Code Plugin that distributes 10 skills + templates"`. AC-7 explicitly enumerates AI-GUIDE.md. Recurring Insight L5 class. **Fix**: `10 skills` → `11 skills`. Precedent: T-003 made the same update at this exact line (see `docs/features/_archived/supervisor-agent/04_DEVELOPMENT.md:29`).

### MINOR

**m-1** [MAINT] `docs/manual-e2e-test.md:7, :34, :49, :54, :59` — five "ten / 10 skills" copies stale. Not in AC-7, but T-003 precedent updated this file. **Fix**: bump to "eleven / 11" and add `/harness-batch` to slash-command list at :59-60. Not a gate input.

**m-2** [DESIGN] `skills/harness-batch/SKILL.md:62` — "3 same-stage rollbacks" stop signal folded into FAILED-verdict bullet. Design lists it as a distinct row. Functionally identical. **Fix**: either split into 5th bullet, or add one-line clarifier ("FAILED is the externally-visible form of the rollback-count stop signal — pm-orchestrator's contract converts 3 same-stage rollbacks into FAILED verdict").

**m-3** [MAINT] `docs/project-overview.html:293, :311` — "10 个 skills" / "10 skills" in a v0.17.0-labeled snapshot. By-design archival; deferred.

### NIT

**n-1** `SKILL.md:34` — `<batch-id>` could read as literal vs placeholder; consider `<your-batch-id>` for clarity
**n-2** Dev self-flagged hardening: skill should refuse `<batch-id>` starting with `_` to prevent `_template` invocation. Deferred to v0.19.1+

### PRAISE

- praise-1: SKILL.md description verbatim from design — no paraphrasing drift
- praise-2: F-7 mitigation belt-and-suspenders (SKILL.md:49 + :78)
- praise-3: F-5 mitigation clean; all 6 locations updated including description texts
- praise-4: `docs/batches/README.md` worked example covers happy + failure paths
- praise-5: Hard rules include a 6th "always run verify_all after each task" — good defensive addition

## verify_all run

- PS: NOT EXECUTED (Reviewer has no shell). Accepting Dev's PS 31/31 PASS / WARN 0 / FAIL 0 report.
- Bash: NOT EXECUTED. Dev reported PASS through #25 (I.7) with documented Claude-Code-Windows-bash subprocess deadlock on I.6's large loop — pre-existing environmental quirk, not a regression.

## Rollback recommendation

Send back to Developer for:

1. **M-1** (required): `AI-GUIDE.md:7` `10 skills` → `11 skills` — closes AC-7.
2. **m-2** (recommended): clarify 5th stop signal in `skills/harness-batch/SKILL.md` strong-signal-stop §.
3. **m-1** (recommended bundle): `docs/manual-e2e-test.md` 5 count phrases + slash-command list — same drift class as M-1, cheap to fix.

After these edits, re-run `verify_all` (expect 31/31 still) and verdict should clean up to APPROVED FOR QA.

## Round 2 — PM spot-check (2026-05-23, post-Developer rollback)

PM performed a targeted re-check on the 3 changed locations rather than dispatching another full Code Reviewer sub-agent. Justification: findings were scoped + concrete + verifiable by direct file read; verify_all still PASSes 31/31 after Dev's edits; round-2 changes were documentation-only with zero gate-input impact.

| Finding | Status | Citation |
|---|---|---|
| M-1 | RESOLVED | `AI-GUIDE.md:7` now reads `"11 skills + templates"` |
| m-2 | RESOLVED | `skills/harness-batch/SKILL.md:62` — FAILED bullet gained the parenthetical "(the externally-visible form of pm-orchestrator's '3 same-stage rollbacks → STOP' hard rule — either signal alone triggers stop)" — design-table fidelity restored without splitting bullets |
| m-1 | RESOLVED | `docs/manual-e2e-test.md` — `grep -i '10 skill\|ten skill'` returns 0 matches; `harness-batch` appears 3 times (slash-command list + dry-run list + alphabetized comment) |

**Round-2 verdict: APPROVED FOR QA**

PM may now dispatch QA Tester.
