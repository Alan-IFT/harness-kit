# 07 — Delivery Summary · supervisor-agent (T-003)

- **Task**: supervisor-agent — new observer-only agent + `/harness-supervise` skill that reads a task folder, detects 5 anti-patterns (AP-1 same-stage rollback rate, AP-1b cross-stage rollback tally, AP-2 stage-doc thinness, AP-3 missing intervention checks, AP-4 missing archive call), and writes a `SUPERVISION_REPORT.md` with `Verdict: HEALTHY/WATCH/INTERVENE`.
- **Mode**: full (7 stages, with 3 rollbacks)
- **Target version**: v0.17.0 (closes the second half of README:256 roadmap row "supervisor agent observing pipeline progress"; v0.16+ planned → v0.17.0 done)
- **Date**: 2026-05-19

## Stages traversed (with rollbacks)

| # | Stage | Outcome | Doc |
|---|---|---|---|
| 1 | Requirement Analyst | READY (10 FR, 11 AC, 6 NFR, 6 risks; 7 open questions analyst-decided) | `01_REQUIREMENT_ANALYSIS.md` |
| 2 | Solution Architect (round 0) | READY FOR GATE REVIEW (3 architect-introduced decisions) | `02_SOLUTION_DESIGN.md` |
| 3 | Gate Reviewer (round 1) | **CHANGES REQUIRED** — F-1 BLOCKER (AC-6 vs AP-1 arithmetic mismatch on T-002 snapshot), F-2/F-3/F-4 WARNs | `03_GATE_REVIEW.md` |
| 2' | Solution Architect (round 1 rollback) | READY FOR GATE REVIEW round 2 (AP-1b cross-stage tally added; AP-3 stage-to-stage clarified; AI-GUIDE.md:14 + harness-status fix format documented; §16 Gate Findings Resolution appended) | `02_SOLUTION_DESIGN.md` |
| 3' | Gate Reviewer (round 2) | **APPROVED FOR DEVELOPMENT** — all 4 findings resolved, no scope creep, no regressions | `03_GATE_REVIEW.md` Round 2 |
| 4 | Developer (round 0) | READY FOR REVIEW (22 files; 30/30 verify_all; 52 test-supervisor PS) | `04_DEVELOPMENT.md` |
| 5 | Code Reviewer | **APPROVED** — 0 BLOCKER, 0 MAJOR, 4 MINOR (slug-substring collision risk; emulator brittleness on out-of-order stages; off-by-one line count; missing 2-rollback fixture) | `05_CODE_REVIEW.md` |
| 6 | QA Tester (round 1) | APPROVED FOR DELIVERY with 3 followups — BUG-1 (`-match` case-insensitive → violates Q-1 fixed-case), BUG-2 (slug-substring collision), BUG-3 (N=0 doc-drift) | `06_TEST_REPORT.md` |
| 4'' | Developer (round 2 rollback — PM override on BUG-1) | READY FOR REVIEW round 3 (BUG-1 fixed: `-match` → `-cmatch` + helper symmetry + 2 negative-fixture assertions; BUG-2 + BUG-3 deferred to v0.17.1 with rationale) | `04_DEVELOPMENT.md` Rollback round 2 |
| 6' | QA Tester (round 2 — BUG-1 verification) | **APPROVED FOR DELIVERY** — BUG-1 closed; 54 test-supervisor PS / 50 Bash-no-python3 | `06_TEST_REPORT.md` Round 2 |
| 7 | PM (this doc) | Delivered v0.17.0 | `07_DELIVERY.md` |

**Total rollbacks**: 3 (Gate→Architect on F-1; QA→Developer on BUG-1). No stage rolled back 3× in a row — pipeline never tripped the "stop and ask" gate.

## Final verify_all result

```
=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

New check **I.7 — Ignored INTERVENE supervision reports**: WARN-level passive guard that flags any `SUPERVISION_REPORT.md` with `Verdict: INTERVENE` whose modtime is >48h old AND whose task slug is still in `docs/tasks.md` Active table.

## Final test-supervisor result

| Shell | Pass count | Notes |
|---|---|---|
| `test-supervisor.ps1` | 54 / 54 | 11 ACs + F-4 stage-to-stage scope + I.7 emulation + 11 doc fan-out spot checks + 2 BUG-1 negative-fixture assertions (lowercase + mixed-case verdict do NOT parse) |
| `test-supervisor.sh` | 50 / 50 | Bash twin; +1 symmetric BUG-1 assertion |

## Baseline changes

`scripts/baseline.json`:
- `verify_all_checks`: 29 → **30** (new I.7)
- `test_supervisor_ps_assertions`: new field, **54**
- `test_supervisor_bash_no_python3_assertions`: new field, **50**
- `test_init_ps_assertions`: 227 (unchanged — additive supervisor change, confirmed)
- `last_verify`: 2026-05-19

## Files changed (16 modified + 11 new = 27 paths)

```
.claude-plugin/marketplace.json                           (version 0.16.0 → 0.17.0)
.claude-plugin/plugin.json                                (version 0.16.0 → 0.17.0)
.harness/rules/40-locations.md                            (added supervisor + harness-supervise rows)
AI-GUIDE.md                                               (line 14: "7 canonical agents + 1 auxiliary"; lines 35/67: 29→30 checks; line 74: 0.17.0)
CHANGELOG.md                                              (v0.17.0 entry + Known-limitations BUG-2/BUG-3 deferral)
README.md / README.zh-CN.md                               (roadmap row flipped; badges 0.16.0→0.17.0; skill list +1)
architecture.html                                         (banner counts)
docs/dev-map.md                                           (assertion counts + scripts/ tree)
docs/manual-e2e-test.md                                   (assertion count + test-supervisor entry)
docs/tasks.md                                             (T-003 → done in archive pass)
docs/walkthrough.html                                     (count refresh)
scripts/baseline.json                                     (counts bumped)
scripts/verify_all.ps1                                    (+I.7; -match → -cmatch; "report = ()" comment)
scripts/verify_all.sh                                     (+I.7; report=() + report_file loop var to avoid global shadowing)
skills/harness-status/SKILL.md                            (new supervisor (auxiliary) row; canonical 7-glob preserved)
.harness/agents/supervisor.md                             (NEW, 256 lines; observer-only contract)
templates/common/.harness/agents/supervisor.md            (NEW, byte-identical mirror)
.claude/agents/supervisor.md                              (NEW, synced from .harness/)
skills/harness-supervise/SKILL.md                         (NEW, 3 argument shapes)
skills/harness-supervise/fixtures/sample-task/*           (NEW, 8 files — HEALTHY baseline)
skills/harness-supervise/fixtures/sample-task-three-rollbacks/PM_LOG.md  (NEW)
skills/harness-supervise/fixtures/supervisor-mock.json    (NEW)
scripts/test-supervisor.ps1                               (NEW, 54 assertions)
scripts/test-supervisor.sh                                (NEW, 50 assertions)
```

## What was delivered (user-facing)

1. **New agent**: `supervisor.md` — observer-only role with tight `tools: Read, Write, Glob, Grep` (NO Edit/Bash/PowerShell/Task/AskUserQuestion). Cannot modify any stage doc, PM decision, or production code.
2. **New skill `/harness-supervise`** with three argument shapes:
   - `harness-supervise <slug>` — analyze a single task (active or archived).
   - `harness-supervise --recent N` — cross-task pattern report over last N archived tasks.
   - `harness-supervise --all` — cross-task report over all archived tasks.
3. **5 anti-patterns detected** with INFO/WARN/ALERT severity ladder:
   - AP-1 same-stage rollback: ≥2=WARN, ≥3=ALERT.
   - AP-1b cross-stage rollback total: 2=INFO, 3=WARN, ≥4=ALERT.
   - AP-2 stage-doc thinness: per-stage minimum line counts.
   - AP-3 missing intervention checks (stage-to-stage only, NOT round-to-round).
   - AP-4 missing archive-task call for Completed tasks.
4. **Output**: `SUPERVISION_REPORT.md` with mandatory last non-blank line `Verdict: HEALTHY` (zero WARN+ALERT) / `WATCH` (≥1 WARN, 0 ALERT) / `INTERVENE` (≥1 ALERT). Cross-task reports go to `docs/features/_supervision/cross-task-<ISO-date>.md`.
5. **Safety net**: verify_all I.7 (new) flags ignored INTERVENE reports older than 48h on still-active tasks.
6. **AC-6 reference snapshot**: running `harness-supervise ai-native-init` against the real archived T-002 yields `Verdict: HEALTHY, AP-1b INFO (2 cross-stage rollbacks), no other findings` — proves the architecture handled T-002's 3-rollback ship correctly.

## Known limitations / deferred to v0.17.1

- **BUG-2 (deferred)**: I.7 active-row slug match is substring-based (`grep -F` / `-match [regex]::Escape($slug)`). Future task slugs with shared substrings could cross-trigger. Not exploitable today (no overlapping slugs in `docs/tasks.md`). Fix: column-anchored regex `\|\s*$slug\s*\|`. One-line PS + bash.
- **BUG-3 (deferred)**: doc-drift between `supervisor.md:230` (says clamp `[1, archived-count]` even when count=0) and `SKILL.md:129` (correct: empty-HEALTHY report). One-line doc fix.

## Outstanding risks

None ship-blocking. The two deferred items are tracked in CHANGELOG "Known limitations" and will roll into a v0.17.1 hardening release that also picks up Code Review's 4 MINOR notes (slug-substring collision, emulator stage-ordering, off-by-one dev-report line count, 2-rollback fixture for literal AC-4 coverage).

## Next steps for user

- Pull `main`; verify_all should be 30/30 on any host.
- Try the supervisor on T-002: `/harness-supervise ai-native-init` — should output `Verdict: HEALTHY` with AP-1b INFO at 2 cross-stage rollbacks. Demonstrates the agent reading real archived state.
- Cross-task pattern: `/harness-supervise --all` after a few more tasks accumulate.
- The full roadmap row "v0.16+ planned: True AI-native init + supervisor agent" is now **shipped** as v0.16.0 (T-002) + v0.17.0 (T-003). The README roadmap should now read `v0.18+ planned` for the next batch.

## Insight

(Only non-obvious project truths that beat a reasonable prior — per `.harness/rules/05-insight-index.md`. `scripts/archive-task` will harvest.)

- 2026-05-19 · PowerShell `-match` is case-INSENSITIVE by default; use `-cmatch` for any regex check that enforces a fixed-case contract (e.g. `Verdict: INTERVENE` as a binding schema). Same insight class as `-cnotin` (T-002) and `-ccontains` (T-001) — the pattern is "all PS string operators need their case-sensitive variant when the contract is fixed-case." Detection: any PS string operator without a leading `c` in a contract-enforcing context is suspect. · evidence: T-003 BUG-1, scripts/verify_all.ps1:439 (post-fix)
- 2026-05-19 · A bash `while IFS= read -r VAR` loop variable name that collides with a globally-mutated array (e.g. `report=()` declared at script top) silently clobbers the array via scalar→array coercion. Symptom: off-by-one in totals derived from the array. Defense: never reuse a global array name as a loop variable; prefer `array=()` over `declare -a array` (per existing insight) AND adopt the convention "loop variables for file paths are named `<thing>_file`, not bare `<thing>`". · evidence: T-003 dev rollback round 0, scripts/verify_all.sh:14,451 (post-fix)
- 2026-05-19 · An observer agent's contract MUST exclude `Edit/Bash/PowerShell/Task` from `tools:` to be structurally read-only — not just "we promise not to". Frontmatter is the only enforceable boundary; the prose contract is advisory. Verify via word-boundary regex test in the test driver (`tools:.*\b(Edit|Bash|PowerShell|Task)\b` matches → FAIL). · evidence: T-003 supervisor.md:4 + test-supervisor.ps1:128-138

---

**Verdict**: v0.17.0 SHIP-READY. PM advancing to archive-task and commit.
