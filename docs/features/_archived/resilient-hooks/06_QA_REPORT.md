# 06 — QA Report · T-12 `resilient-hooks` (v0.44.0)

**Mode:** full · **QA Tester stage output** · **Verdict:** APPROVED FOR DELIVERY (bash-verified; PS operator-pending)
**Upstream:** 01 READY · 02 READY · 03 APPROVED-WITH-CONDITIONS (C1–C5) · 04 READY FOR REVIEW · 05 APPROVED-WITH-NITS
**Runtime constraint:** PowerShell DENIED to this agent. All claims below are Bash tool evidence. PS-only checks are listed operator-pending — no PS tally fabricated.

---

## 1. What was validated

The original consumer bug: a wired Stop hook whose target script is ABSENT printed
`Stop hook error: bash: .harness/scripts/harness-sync.sh: No such file or directory` on
EVERY turn. The fix makes the three convenience hooks fail-OPEN + `$CLAUDE_PROJECT_DIR`-anchored
while keeping guard-rm fail-CLOSED. QA validated the USER-OBSERVABLE behaviors with independent
reproducers built from the design spec (§3.3/§3.4), NOT imported from the dev's test code.

**Important env note:** this box's `python3` is the non-functional Microsoft-Store stub
(`echo '' | python3 -c 'pass'` exits non-zero), so guard-rm.sh exercised its **sed-fallback**
JSON parser — the harder, more realistic Windows path — and still blocked correctly. The bash
test-driver tallies below are therefore the no-python3-equivalent counts.

---

## 2. Test plan — acceptance criteria → tests

| AC | Behavior | Test(s) | Evidence |
|---|---|---|---|
| AC-1 | absent convenience script → rc=0, empty stderr | independent B1 repro + test-init `[T-020]` path-exists + E.4b mutation | rc=0, 0 stderr bytes (below) |
| AC-2 | `$CLAUDE_PROJECT_DIR` anchor resolves from a subdir | independent B2 repro + test-harness-upgrade Fixture H/P real-run | rc=0, script ran, marker written |
| AC-3 | both OS exact strings | bash forms run live; pwsh forms read from settings.local.json + script output | bash byte-match to design §3.5 |
| AC-4 | ambient parity (UserPromptSubmit / SessionStart) | same fail-open form; test-init OS-picked-variant exact match | green (test-init 278/0) |
| **AC-5** | **guard-rm fail-CLOSED (the non-negotiable)** | **NEW codified Fixture Z (test-harness-upgrade.{sh,ps1}) + independent B3a/B3b/B4 repros** | **destructive BLOCKED present; rc!=0 absent** |
| AC-6 | template resilient + J.1 valid | verify_all J.1 PASS (incl. settings.local.json target) | 32/0/0 |
| AC-7 | derivation lockstep, no surviving brittle authoring form | test-init / test-real-project / upgrade / migrate all resilient | green (CR fidelity-fix landed) |
| AC-8 | repair brittle→resilient | test-harness-upgrade Fixtures A/H/M2 resilient asserts | 89/0 |
| AC-9 | dogfood move to settings.local.json | committed settings.json `hooks: {}`; local file carries 4 | confirmed by read |
| AC-10 | gitignore | `.gitignore` has `.claude/settings.local.json` | confirmed |
| AC-11 | verify_all unaffected (F.2/J.1) | verify_all F.2 + J.1 PASS post-slice-B | 32/0/0 |
| AC-12 | ripple — token still ERE-parseable + dangling still flagged | test-init mutation probe + E.4b/D.4b + test-real-project D.4b dangling | green |
| AC-13 | gate 32/32 | verify_all.sh 32/0/0 | confirmed (PS operator-pending) |
| AC-14 | count/version | G.3/G.4 PASS, no count flip (32/17/8) | green |

---

## 3. Adversarial tests (REQUIRED — one predicted failure per behavior, independent reproducers)

All four reproducers were written by QA from the design spec, run live on Bash, with the
predicted-failure hypothesis stated BEFORE running. Verdict is whether the implementation
**survived**, with actual tool output as evidence.

| # | Hypothesis ("I expect failure when…") | Reproducer (QA-authored) | Outcome (tool evidence) |
|---|---|---|---|
| B1 | absent Stop script still errors on every turn | resilient convenience cmd, missing `harness-sync.sh`, `CLAUDE_PROJECT_DIR` set, run from root | **SURVIVED** — `rc=0, stderr_bytes=0` |
| B2 | anchor broken → "No such file" from a subdir | resilient cmd, script PRESENT, cwd = deep subdir `sub/deep` | **SURVIVED** — `rc=0, stdout=ran, marker=SYNC-RAN` |
| B3a | guard not actually run when present → allow | resilient guard cmd, guard PRESENT, destructive `rm -rf /etc/...` payload | **SURVIVED** — `rc=2 BLOCKED` (benign `ls` → rc=0, proves real run) |
| B3b | missing guard silently allows (fail-open) | resilient guard cmd, guard ABSENT, destructive payload | **SURVIVED** — `rc=127` (fail-CLOSED) |
| B4a | empty `$CLAUDE_PROJECT_DIR` silently skips guard | guard PRESENT, `CLAUDE_PROJECT_DIR=""`, destructive payload | **SURVIVED** — `rc=2 BLOCKED` |
| B4b | empty var + absent guard silently allows | guard ABSENT, `CLAUDE_PROJECT_DIR=""`, destructive payload | **SURVIVED** — `rc=127` (fail-CLOSED) |

### Actual tool output (captured)

**B1 — bug is gone:**
```
rc=0  stderr_bytes=0  stderr=[]  stdout=[]
CONTROL brittle rc=127  stderr=[bash: .harness/scripts/harness-sync.sh: No such file or directory]
```
The control (original brittle `bash .harness/scripts/harness-sync.sh`) reproduces the EXACT
consumer error string at rc=127 — proving the resilient form's rc=0/empty-stderr is a real change.

**B2 — anchor works from a subdir:**
```
cwd=subdir(sub/deep)  rc=0  stdout=[ran]  stderr=[]  marker=[SYNC-RAN]
CONTROL brittle-from-subdir rc=127  stderr=[bash: .harness/scripts/harness-sync.sh: No such file or directory]
```

**B3a — guard PRESENT blocks destructive (the safety floor):**
```
guard PRESENT, destructive rm -rf /etc/...  rc=2
stderr=[harness-kit guard-rm: BLOCKED — destructive command targets path outside project root. ...]
SANITY benign 'ls -la' rc=0 (allowed — guard genuinely ran, not blanket-blocking)
```

**B3b — guard ABSENT fails CLOSED:**
```
guard ABSENT  rc=127  stderr=[bash: .harness/scripts/guard-rm.sh: No such file or directory]
```

**B4 — empty `$CLAUDE_PROJECT_DIR` degenerate (the dev-flagged drift):**
```
B4a empty-var + guard PRESENT, destructive  rc=2  (BLOCKED — guard still ran)
B4b empty-var + guard ABSENT                rc=127 (fail-CLOSED)
```
Confirms the CR adjudication: empty var can NEVER make guard-rm silently NOT run. With the
guard present, `cd ""` stays in cwd (project root) so the guard runs and blocks; with the guard
absent, the missing-file non-zero exit is the fail-closed signal. No silent-allow in any branch.

---

## 4. Codified AC-5 mutation probe — ADDED (the CR's strengthening request)

The CR NIT (05_CODE_REVIEW.md) flagged that the fail-closed invariant was only **structural**
(grep for absence of `exit 0` on the guard line) — no committed test deleted guard-rm and
asserted a destructive call is still blocked at RUNTIME. QA codified it.

**Added: Fixture Z (`test-harness-upgrade.sh` + `.ps1` twin).** Self-contained, durable, reuses
the existing `assert`/`Assert` harness, copies the REAL `guard-rm.{sh,ps1}` from the repo, builds
the resilient guard command, and:
- **Z1** — guard PRESENT → destructive out-of-repo `rm -rf` is BLOCKED (rc≠0).
- **Z1b** — guard PRESENT → benign `ls -la` is ALLOWED (rc=0) — proves the guard genuinely ran, not blanket-blocking.
- **Z2** — MUTATION: delete guard-rm → same command exits non-zero (fail-CLOSED, never silent-allow).
- **Z3** (bash only) — empty `$CLAUDE_PROJECT_DIR` + absent guard → non-zero (fail-CLOSED degenerate).

This adds **no new verify_all check** (honoring `feedback_design_over_guards` + RA §3.3 out-of-scope),
does not touch verify_all, and keeps the 32/0/0 baseline. test-harness-upgrade.sh: **85 → 89** (+4).
The `.ps1` twin gained the symmetric Z1/Z1b/Z2 (+3); it was edited symmetrically and is
**operator-pending** (PowerShell denied to QA — no PS tally fabricated).

Stability: Fixture Z ran 5/5 times PASS=4 FAIL=0, no flake.

---

## 5. Boundary tests covered

- Missing script — convenience (fail-open rc=0) AND guard (fail-closed rc!=0). [B1, B3b]
- Wrong cwd / subdirectory launch — anchor resolves. [B2]
- Empty `$CLAUDE_PROJECT_DIR` — convenience no-crash/no-FS-root; guard never silent-skip. [B4, Z3]
- guard genuinely runs (benign allowed, destructive blocked) — not blanket deny. [B3a Z1b]
- sed-fallback JSON parse path (non-functional python3 stub) exercised — guard still correct.
- Dangling-script still flagged by the unchanged ERE (token survives the anchor). [test-init mutation probe, test-real-project D.4b]

---

## 6. verify_all result + full Bash regression suite

| Suite | Result | Baseline note |
|---|---|---|
| `verify_all.sh` | **PASS 32 / WARN 0 / FAIL 0** (~41s) | unchanged (32 checks; no new check) |
| `test-init.sh` | **278 / 0** | was 276 baseline (dev resilient asserts) → bumped |
| `test-harness-upgrade.sh` | **89 / 0** | was 79 baseline (dev +6, QA +4 AC-5 Fixture Z) → bumped |
| `test-real-project.sh` | **90 / 0** | unchanged |
| `test-supervisor.sh` | **45 / 0** | unchanged |
| `test-language.sh` | **39 / 0** | unchanged |
| `test-verify-i6.sh` | **58 / 0** | unchanged |

- Total tests: before (baseline bash) → after: **test-harness-upgrade 79 → 89**, **test-init 276 → 278**; all others flat.
- Fail: **0** across every suite (required to approve — met).
- New tests added by QA: **4** (bash Fixture Z) + 3 symmetric PS (operator-pending).
- Baseline updated: **yes** — `.harness/scripts/baseline.json` `test_harness_upgrade_bash_assertions` 79→89, `test_init_bash_no_python3_assertions` 276→278, `last_verify` → 2026-06-21. Baseline only moved UP. PS keys left for the operator run to re-measure (Fixture Z PS twin will raise `test_harness_upgrade_ps_assertions` from 80).

---

## 7. Stability

- Independent behavior repros (B1–B4): ran 3×, every run `PASS=6 FAIL=0`. ✅
- AC-5 Fixture Z (full test-harness-upgrade.sh): ran 5×, every run `Z PASS=4 FAIL=0`. ✅
- No flakes observed. (Temp-dir + `git init` + sed-fallback parser all deterministic.)

---

## 8. Defects found

**None.** No BLOCKER, CRITICAL, MAJOR, or MINOR defect. The single non-negotiable
(NFR-Safety: guard-rm fail-CLOSED) is verified intact at runtime in all four cases — present/absent
× normal/empty-var. The bug-being-fixed is gone (B1 rc=0 vs control rc=127). The anchor works (B2).

The CR's two MINOR test-fidelity items (brittle `*_COMMAND` at 3 fixture-authoring sites) were
already resolved by the dev's post-CR fidelity fix (04_IMPLEMENTATION §"Fidelity fix") — verified
green via test-real-project.sh 90/0 and test-init.sh 278/0. The CR's AC-5 NIT (no codified runtime
mutation) is now closed by Fixture Z (§4).

---

## 9. Operator-pending PowerShell list (NOT run — PS denied to QA; no tally fabricated)

The bash twins all pass; the PS twins were edited symmetrically and must be run by the operator
on a Windows/pwsh box before merge (repo convention; AC-13 PS half):
1. `pwsh verify_all.ps1` — expect 32/0/0.
2. `pwsh test-harness-upgrade.ps1` — expect prior count **+3** (new Fixture Z Z1/Z1b/Z2). Then bump `test_harness_upgrade_ps_assertions` in baseline.json (currently 80, left unbumped).
3. `pwsh test-init.ps1` — expect 314 (incl. `Test-ZhOverlay` resilient literals).
4. `pwsh test-real-project.ps1` — expect 90.
5. `pwsh test-supervisor.ps1` / `test-language.ps1` / `test-verify-i6.ps1`.
6. Spot-check from 04_IMPLEMENTATION open issues: (a) `Get-ResilientCmd` brace-doubling exact bytes; (b) `.Replace()` literal substitution leaves `$env:`/`& pwsh` intact; (c) migrate `-eq` exact-match; (d) Fixture P/H/A/M2/**Z** resilient + fail-closed asserts.
7. context7 NFR-Compat re-confirmation that `$CLAUDE_PROJECT_DIR` is injected into all four hook events (not Bash-accessible to QA; design + Gate already established via mattpocock/git-guardrails cite; the form degrades safely either way).

---

## 10. Verdict

**APPROVED FOR DELIVERY** (Bash-verified; PowerShell operator-pending per repo convention).

All 14 acceptance criteria are covered by tests; the original consumer bug is gone with tool
evidence; the load-bearing fail-CLOSED safety invariant survives runtime mutation in all four
cases and is now CODIFIED (Fixture Z); the full Bash suite is green (verify_all 32/0/0 plus six
regression drivers); the baseline moved up; no defect found; zero flakes over 5 runs. The only
open item is the standard operator-pending PowerShell run.

---

## 11. Operator PowerShell run — 2026-06-21 (post-archive addendum)

The operator ran the full PS suite on Windows 11 / pwsh 7. This closed §9 — and the "green-by-symmetry"
assumption for PS-only code FAILED, surfacing **two real defects** that no `.sh` run could have caught
(PS is denied to every agent). Both are now fixed; the PS suite is green.

**DEFECT-2 (PARSE, all PS scripts carrying it).** The bash-form `else` branch of the resilient
command was authored as a double-quote concat (`"...\""+'$CLAUDE_PROJECT_DIR'+"\""...`). PowerShell
reads `"\"` as *close-string-then-stray-token*, so the file fails to **parse** — and PS parses the
WHOLE file before running, so this dead (never-taken-on-Windows) branch was fatal to the entire
script. Hit `test-init.ps1`, `test-harness-upgrade.ps1`, `test-real-project.ps1` AND the shipped
`upgrade-project.ps1` + `migrate-scripts-layout.ps1` (+ template twins) → the `/harness-upgrade`
repair path would not even load on Windows. **Fix:** rewrote every bash literal as a SINGLE-quoted
PS string (inner `'`→`''`), or `'...{0}...' -f $tool` where `$tool` must interpolate. 7 files.

**DEFECT-3 (RUNTIME, upgrade + migrate).** Once parsing was fixed, the helpers threw on first call:
`Get-ResilientCmd($tool, $isWindows)` — the parameter name `$isWindows` collides with the read-only
**automatic** `$IsWindows` (PS names are case-insensitive) → `Cannot overwrite variable isWindows
because it is read-only or constant`. The helper moved the scripts, then threw before rewiring
settings → no rewire, no `.bak`, exit 1. **Fix:** renamed the parameter `$isWindows`→`$forWin` in
`upgrade-project.ps1` + `migrate-scripts-layout.ps1` (repo + template twins). Scanned every other
function/param in both scripts — no further automatic-variable collisions.

**PS re-run after both fixes — ALL GREEN:**

| Driver | Result |
|---|---|
| `verify_all.ps1` | **32 / 0 / 0** |
| `test-init.ps1` | **316 / 0** (was 308/8 — migrate block now passes) |
| `test-harness-upgrade.ps1` | **exit 0** — every fixture A–P + M1/M2/M3 + Z PASS |
| `test-real-project.ps1` | **90 / 0** |
| `test-supervisor.ps1` | **49 / 0** · `test-language.ps1` **39 / 0** · `test-verify-i6.ps1` **58 / 0** · `test-guard-rm.ps1` **17 / 0** |

Also: a full `[Parser]::ParseFile` sweep over every `.ps1` (repo + templates/common) reports `ok:`
on all — no remaining parse error. bash side re-confirmed: `sync-self --check` In sync (E.1 twins
byte-identical), `verify_all.sh` 32/0/0.

**Ledger:** `baseline.json` `test_init_ps_assertions` 314→**316**; README `test--init` badge 314→316.
`test_harness_upgrade_ps_assertions` (was 80) to be set from the operator's `=== Summary ===` count.

**Lesson harvested** (insight-index 2026-06-21): when PS is agent-unexecutable, an operator PS run —
parse-check every `.ps1` THEN run every driver — is a MANDATORY release gate, not optional polish.
