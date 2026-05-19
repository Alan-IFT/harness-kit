# 06 — Test Report · supervisor-agent (T-003 · v0.17.0)

Mode: `full` · Stage: 6/7 · Author: QA Tester · Date: 2026-05-19

## 1. Test environment

- OS: Windows 11 (`win32` PowerShell 7+); bash via Git-Bash for cross-shell adversarial probes.
- Repo: `c:\Programs\HarnessEngineering`, branch `main` clean at start.
- Drivers exercised: `scripts/verify_all.ps1`, `scripts/test-supervisor.ps1`, `scripts/test-init.ps1`.
- Fixtures used: `skills/harness-supervise/fixtures/sample-task/`, `…/sample-task-three-rollbacks/`, `…/supervisor-mock.json`, real archived `docs/features/_archived/ai-native-init/` (T-002), plus 7 ad-hoc temp fixtures under `$env:TEMP\supervisor-adv-*`.

## 2. Automated suite results

| Driver | Pass | Fail | Warn | Notes |
|---|---|---|---|---|
| `verify_all.ps1` | **30** | 0 | 0 | I.7 PASS (vacuous — no live SUPERVISION_REPORT files in repo) |
| `verify_all.sh` | (not re-run; dev report cites 30/0/0) | — | — | Bash twin asymmetry covered in bug section below |
| `test-supervisor.ps1` | **52** | 0 | — | All 11 ACs + F-4 + I.7 emulation + 11 fan-out spot checks |
| `test-init.ps1` | **227** | 0 | — | No regression from supervisor changes (additive). |

Baseline diff (`scripts/baseline.json`):
- `verify_all_checks`: 29 → **30** (+1 = I.7).
- new entry `test_supervisor_ps_assertions`: **52**.
- new entry `test_supervisor_bash_no_python3_assertions`: **49**.

Stability: ran `verify_all.ps1` and `test-supervisor.ps1` three times each — counts identical every run, no flakes observed.

## 3. AC coverage matrix

| AC | Asserted by | Outcome |
|---|---|---|
| AC-1 agent contract, ≤300 lines, AP-1..AP-4, allowed-tools whitelist | `test-supervisor.ps1` AC-1.1–AC-1.6; direct read of `.harness/agents/supervisor.md:4` line `tools: Read, Write, Glob, Grep` | PASS |
| AC-2 template byte-identity + sync-self clean | `test-supervisor.ps1` AC-2.1–AC-2.3 (sha256 compare + `sync-self -Check`) | PASS |
| AC-3 skill exists, three arg shapes, allowed-tools subset, mock env var documented | `test-supervisor.ps1` AC-3.1–AC-3.4 | PASS |
| AC-4 2-rollback → WARN | `test-supervisor.ps1` AC-4.* (HEALTHY-fixture path) + ladder emulator AC-4.3 | PARTIAL — on-disk fixture covers HEALTHY baseline only; the 2-rollback WARN rung is exercised via in-process emulator only (Code Review MINOR-4 confirmed; not a defect since the ladder logic is in `supervisor.md`, not a script) |
| AC-5 3-rollback → ALERT, Verdict INTERVENE | `test-supervisor.ps1` AC-5.1–AC-5.4 against `fixtures/sample-task-three-rollbacks/PM_LOG.md` | PASS |
| AC-6 T-002 snapshot HEALTHY (F-1 binding interpretation) | `test-supervisor.ps1` AC-6.1–AC-6.8 against real `docs/features/_archived/ai-native-init/PM_LOG.md` | PASS |
| AC-7 HARNESS_SUPERVISOR_MOCK + fallback | `test-supervisor.ps1` AC-7.1–AC-7.6 | PASS |
| AC-8 verify_all 29 → 30 | `verify_all.ps1` summary `PASS: 30` | PASS |
| AC-9 doc fan-out (CHANGELOG/README/AI-GUIDE/dev-map/plugin/marketplace/walkthrough/architecture/harness-status) | `test-supervisor.ps1` fan-out spot checks (11 assertions) | PASS |
| AC-10 backwards compat (PM never reads supervisor.md) | By construction; `test-init.ps1` 227/227 unchanged | PASS |
| AC-11 harness-status +1 row, glob preserved | `test-supervisor.ps1` two final fan-out assertions | PASS |

## 4. Adversarial tests (REQUIRED — independent reproducers)

Each row states the hypothesis BEFORE running, then the actual outcome with tool evidence.

| # | AC / contract | Hypothesis ("I expect failure when…") | Reproducer (NEW, written by QA) | Outcome |
|---|---|---|---|---|
| ADV-1 | AC-8 / I.7 / Q-1 fixed-case | I.7 PS will FALSELY fire on a report whose last line is `verdict: intervene` (lowercase). PowerShell `-match` is case-insensitive (insight L13 says use `-cnotin`/`-cmatch`). | Crafted `$env:TEMP/...adv-case-bug-temp/SUPERVISION_REPORT.md` with `verdict: intervene`, added matching Active row to `docs/tasks.md`, backdated mtime to -72h, ran `scripts/verify_all.ps1`. | **FAILED — BUG CONFIRMED.** verify_all.ps1 emitted `[I.7] … (stale: …\adv-case-bug-temp\SUPERVISION_REPORT.md (INTERVENE, 72h old, slug=adv-case-bug-temp active)) WARN`. Lowercase verdict line triggered WARN. Filed as MINOR — see §5 BUG-1. |
| ADV-2 | AC-8 / I.7 robustness | Trailing blank lines after `Verdict: INTERVENE` will hide the verdict from the parser. | Wrote fixture with 3 trailing blank lines after a valid verdict line; ran the I.7 PS code path (`Get-Content | Where-Object Trim != "" | Select-Object -Last 5`). | **Survived.** Parser correctly returned `verdict = INTERVENE`. The `Where-Object { $_.Trim() -ne "" }` filter robustifies against trailing whitespace. |
| ADV-3 | AP-1 regex (rollback-rate) | A PM_LOG line `### Rollback consumed by review (round 1)` inside a fenced code block will be counted as a real rollback. | Wrote PM_LOG with `### Stage 5` then a fenced code block containing `### Rollback consumed by review (round 1)`. Ran the AP-1 line regex per `supervisor.md:46-55`. | **Survived per spec.** Counted 1 rollback (matches `^### Rollback` line regex which is code-block-unaware). Documented as design choice; HARDENING opportunity not a bug. |
| ADV-4 | AP-1 regex breadth | A heading like `### Rollback strategy discussed` (not a real rollback event) would be counted. | Tested `'### Rollback strategy discussed' -match '^### Rollback'`. | **Matches.** Contract is the broad `^### Rollback` line regex. Convention is the narrower `### Rollback consumed by X (round N)`. Documented as HARDENING opportunity. |
| ADV-5 | AP-3 round-to-round must NOT count | T-002 has Stage 5 round-1 + round-2; if AP-3 counted round-to-round, missing-intervention would falsely show ≥1. | Re-ran `test-supervisor.ps1 F-4.1` against the real `docs/features/_archived/ai-native-init/PM_LOG.md`. | **Survived.** `missing_intervention_count = 0`. F-4 fix is correctly enforced. |
| ADV-6 | AC-1 / NFR-4 allowed-tools | If `Edit`, `Bash`, `PowerShell`, `Task`, or `AskUserQuestion` leaked into the frontmatter on either supervisor.md or SKILL.md, the safety contract is broken. | Direct line-4 read of both files + word-boundary regex per forbidden tool. | **Survived.** supervisor.md:4 → `tools: Read, Write, Glob, Grep`. SKILL.md:4 → `allowed-tools: Read, Write, Glob, Grep`. All 5 forbidden tools excluded with `\bToolName\b` regex on both files. |
| ADV-7 | AC-6 cross-task `--all` on 0 archived tasks | Behavior would be BLOCKED (script-level error) instead of one-line HEALTHY. | Static read of `supervisor.md:230` ("Clamp to [1, archived-count]; INFO-log the clamp") + `SKILL.md:129` ("Write one-line report Verdict: HEALTHY + INFO 'no archived tasks'"). | **Inconsistent contracts (MINOR doc-drift).** `supervisor.md` says clamp to `[1, 0]` which is mathematically undefined; `SKILL.md` gives the correct behavior. Filed as BUG-3. |
| ADV-8 | I.7 active-row substring match (MINOR-1) | A report at `docs/features/foo/` with `Verdict: INTERVENE` will falsely flag as "Active" when `docs/tasks.md` has `foo` Completed but `foo-extra` Active. | Built temp `docs/tasks.md` with rows for both slugs, ran the PS I.7 active-detection code. | **FAILED — BUG CONFIRMED.** slug `foo` is reported `isActive = True` because `[regex]::Escape("foo")` matches the `foo-extra` row substring. Bash twin (`grep -F "$slug"`) has the same defect. Filed as MINOR — see §5 BUG-2. |
| ADV-9 | I.7 mtime boundary | A report with mtime exactly 47.9h ago must NOT fire (gate is `>48h`). | Crafted fixture with `LastWriteTime = (Get-Date).AddHours(-47.9)`; ran PS I.7 gate. | **Survived.** `47.9 -gt 48` → False. Confirmed gate semantics. (Cosmetic note: at 48.0h, PS floating-point makes `TotalHours = 48.000007 -gt 48 = True`, bash integer `48/3600 = 48 -gt 48 = False`. Edge case ≤1 second wide; not material.) |
| ADV-10 | Slug exists in both active and archived | I.7 glob would double-count the archived report. | Built fixture with same-slug report at both `docs/features/<slug>/` and `docs/features/_archived/<slug>/`; ran `Get-ChildItem -Recurse` + the `-notmatch '_archived'` filter. | **Survived.** Filter correctly excluded `_archived` path. Result count = 1, only the active path file. |
| ADV-11 | AC-1 line cap | supervisor.md must be ≤300 lines per I.3; Code Reviewer MINOR-3 claims actual is 256, dev report says 255. | `wc -l` + `Get-Content`. | **Both tools report 255 lines.** Dev report is correct; Code Reviewer MINOR-3 is incorrect. No bug here, only a cosmetic doc-drift in 05. |
| ADV-12 | NFR-2 read whitelist | The agent file documents a whitelist; verify the whitelist explicitly excludes production source code. | Read `supervisor.md:21-22`. | **Whitelist explicit and tight.** Six paths only. Survived. |
| ADV-13 | AC-4/5 fixtures isolated (insight L22) | The 2-rollback and 3-rollback fixtures share a directory or step on each other. | `Glob skills/harness-supervise/fixtures/**`. | **Survived but partial.** `sample-task/` (HEALTHY) and `sample-task-three-rollbacks/` are isolated. No `sample-task-two-rollbacks/` exists (Code Review MINOR-4 confirmed). 2-rollback rung is asserted via emulator only — acceptable since AP-1 ladder logic is in the agent contract, not a script. |
| ADV-14 | Stability flake check | Repeated runs of verify_all + test-supervisor yield identical PASS counts. | Ran each driver 3x sequentially. | **Survived.** All three runs: verify_all 30, test-supervisor 52. No flakes. |

## 5. Found bugs

### BUG-1 — MINOR — I.7 PS regex case-insensitive (asymmetric to bash twin)

**File:line**: `scripts/verify_all.ps1:435`

**Symptom**: A SUPERVISION_REPORT.md whose last non-blank line is `verdict: intervene` (any case variant) will trigger I.7 WARN, even though Q-1 / 02_SOLUTION_DESIGN.md §15 issue #1 explicitly fixed the schema to `Verdict: <UPPERCASE>` with NO case tolerance.

**Root cause**: PowerShell `-match` is case-insensitive by default. The line reads:
```powershell
if ($line -match '^Verdict: (HEALTHY|WATCH|INTERVENE)$') { ... }
```
Bash twin at `verify_all.sh:462` uses `[[ … =~ … ]]` which IS case-sensitive by default → bash side is correct.

**Insight-index L13 directly applies**: "PowerShell `-notin` is case-INSENSITIVE; use `-cnotin`." Same rule for `-match` → `-cmatch`.

**Reproducer**: see ADV-1 above. End-to-end I.7 WARN fired on `verdict: intervene` lowercase fixture.

**Proposed fix** (1 character): `-match` → `-cmatch` at `verify_all.ps1:435`.

**Severity**: MINOR (not BLOCKER) because:
- The condition only fires when a user has manually written a malformed report; the supervisor agent's contract enforces uppercase via the report schema.
- A spurious WARN does no damage (no FAIL, no data loss).
- Still a real asymmetry with bash twin + breaks Q-1 binding contract → must be fixed before v0.17.x close.

### BUG-2 — MINOR — I.7 active-row slug match is substring-based (PS + bash)

**File:line**: `scripts/verify_all.ps1:441` (`[regex]::Escape($slug)`); `scripts/verify_all.sh:476` (`grep -F -- "$slug"`).

**Symptom**: If two slugs share a prefix (e.g. `foo` and `foo-extra`) and one is Active in `docs/tasks.md`, a report for the OTHER slug is falsely flagged as "active task" → spurious WARN possible.

**Reproducer**: see ADV-8 above. Same defect on both shells.

**Code Reviewer flagged as MINOR-1**; QA confirms it is reproducible.

**Proposed fix** (column-anchored match): require the slug to appear as a full pipe-delimited column, e.g. PS `$row -match "\|\s*$([regex]::Escape($slug))\s*\|"`; bash `grep -E "\|[[:space:]]*${slug}[[:space:]]*\|"`.

**Severity**: MINOR — not currently exploitable (no overlapping slugs in this repo), but a latent footgun for adopters with slugs like `auth` / `auth-v2`.

### BUG-3 — MINOR — `supervisor.md` vs `SKILL.md` doc drift on "0 archived tasks"

**File:line**: `.harness/agents/supervisor.md:230` says *"Clamp to `[1, archived-count]`; INFO-log the clamp"* — when archived-count is 0 this clamp is mathematically undefined. `skills/harness-supervise/SKILL.md:129` correctly says *"Write one-line report `Verdict: HEALTHY` + INFO 'no archived tasks'"*.

**Reproducer**: ADV-7 (static doc read; both files diverge on the same boundary).

**Severity**: MINOR — the SKILL.md path is the authoritative behavior; the supervisor agent contract just has a less-clear edge-case note.

**Proposed fix** (1 row): supervisor.md boundary table — replace `Cross-task N=0 or N>archived-count | Clamp to [1, archived-count]; INFO-log the clamp` with `Cross-task N=0 OR archived-count==0 | one-line Verdict: HEALTHY + INFO 'no archived tasks'. N>archived-count → clamp to archived-count; INFO-log the clamp.`

### NOT-A-BUG findings (Code Review minors reverified)

- **Code Review MINOR-3 (supervisor.md = 256 lines)**: QA measured 255 via both `wc -l` and PS `Get-Content` (ADV-11). Dev report is correct. Cosmetic noise in 05, no production impact.
- **Code Review MINOR-2 (emulator brittleness on non-monotonic stages)**: contract states stage-to-stage transitions are monotonic by definition; no PM_LOG in this repo violates that. Latent hardening opportunity, not a bug today.
- **Code Review MINOR-4 (`sample-task-two-rollbacks/` absent)**: confirmed by `Glob`. AC-4 WARN rung is asserted by the in-process emulator at `test-supervisor.ps1:60-64`. Acceptable per AC-4's wording (the ladder lives in `supervisor.md`); not a defect, only a coverage opportunity.

## 6. Coverage gaps explicitly noted

1. **AC-4 WARN rung (2 same-stage rollbacks)** is exercised by emulator only, not by an on-disk fixture; equivalent in test value but a `sample-task-two-rollbacks/` fixture would be belt-and-suspenders.
2. **End-to-end live LLM roleplay of supervisor.md** has not been exercised in this QA pass; only the mock path + emulator paths. By construction the dispatch path is just file I/O; risk is low. Documented in 04_DEVELOPMENT.md Open issue #3.
3. **Cross-task mode integration** is contract-tested only (the LLM-driven aggregation is not unit-runnable). NFR-1 wall-clock (≤60s for `--recent 10`) cannot be measured without a live run.
4. **AP-2 stage-doc-thinness** has no on-disk failing fixture; thresholds in `supervisor.md` line 92 are static-asserted by the emulator path but not exercised against a real under-min fixture.

## 7. Stability

| Driver | Runs | Result |
|---|---|---|
| `verify_all.ps1` | 3 | 30/0/0 each time, no flakes |
| `test-supervisor.ps1` | 3 | 52/0 each time, no flakes |
| `test-init.ps1` | 1 (regression spot-check) | 227/0 |

## 8. Verdict

`APPROVED FOR DELIVERY — 3 MINOR bugs filed for v0.17.x patch follow-up`

Rationale:
- All 30 verify_all checks pass; all 52 test-supervisor assertions pass; all 227 test-init assertions pass with zero regression.
- All 11 ACs covered (AC-4 partial via emulator, acceptable per contract).
- Adversarial section found **1 new bug** (BUG-1 I.7 PS case-insensitive `-match`, asymmetric to bash twin, violates Q-1 fixed-case decision and insight L13). Severity MINOR — spurious WARN only, no data loss / no FAIL escalation.
- Confirmed **2 of 4 Code Review MINOR findings** are real (MINOR-1 substring slug match = BUG-2; MINOR-4 fixture coverage gap). The other two (MINOR-2 emulator brittleness, MINOR-3 line-count off-by-one) are non-bugs in current state.
- All 3 bugs are MINOR, none block v0.17.0 ship; recommend a v0.17.1 patch sweep covering BUG-1 (`-match` → `-cmatch`), BUG-2 (column-anchored slug match in both shells), BUG-3 (boundary-row doc fix).

Baseline updated: `scripts/baseline.json` now tracks `verify_all_checks: 30`, `test_supervisor_ps_assertions: 52`, `test_supervisor_bash_no_python3_assertions: 49`.

Advance to PM Orchestrator (Stage 7) for delivery composition.

---

## Round 2 — post-rollback BUG-1 verification (2026-05-19)

PM elected to close **BUG-1 in v0.17.0** (same call as T-002's BUG-2 fix-in-release) because BUG-1 violates Q-1 (fixed-case verdict schema) which is a binding architectural decision, and the fix is one-character.

### Fix verification
- `scripts/verify_all.ps1:439`: `-match` → `-cmatch`. Helper `Get-VerdictFromReport` in `test-supervisor.ps1` also updated for emulator/production parity.
- `scripts/test-supervisor.ps1`: +2 negative-fixture assertions (lowercase `verdict: intervene` + mixed-case `Verdict: Intervene`); both correctly do NOT parse.
- `scripts/test-supervisor.sh`: +1 explicit symmetric negative assertion.
- Post-fix counts: **verify_all 30/30 PASS** (unchanged); **test-supervisor 54 PS / 50 Bash-no-python3** (52→54 / 49→50, single-shot regression block per insight L24).
- PM ran both suites directly and confirmed PASS output.

### BUG-2 + BUG-3 deferred to v0.17.1
- BUG-2 (slug-substring collision in I.7 active-row match): documented in CHANGELOG "Known limitations" — not exploitable today (no overlapping slugs in `docs/tasks.md`); fix is column-anchored regex.
- BUG-3 (doc-drift between `supervisor.md:230` clamp-N=0 vs `SKILL.md:129` empty-HEALTHY): one-line doc fix.

### Updated verdict

# `APPROVED FOR DELIVERY`

BUG-1 closed in v0.17.0; BUG-2 + BUG-3 deferred with explicit CHANGELOG rationale. No regressions.
