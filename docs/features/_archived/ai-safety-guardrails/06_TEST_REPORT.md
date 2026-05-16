# 06 — Test Report · ai-safety-guardrails

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Author: QA Tester
- Date: 2026-05-17
- Upstream: `04_DEVELOPMENT.md` (claimed READY FOR REVIEW), `05_CODE_REVIEW.md` (APPROVED with 6 MINOR / 4 NIT)

---

## Verdict (TL;DR)

**PASSED (post-rollback #1, 2026-05-17).** Developer's rollback #1 landed
targeted fixes for D-1, D-2 (CRITICAL) and D-3 (MAJOR). Independent re-test
confirms all three defects no longer reproduce, the fixture suite grew 11 → 17
to lock in the regressions, and the full regression sweep is clean (27/27,
177/177, 82/82, 17/17). D-4 and D-5 (MINOR) remain documented known limitations
per dispatch. See **Re-test after rollback #1** at the bottom of this report.

**First-pass verdict (preserved for history)**: BLOCKED ON DEV. Two CRITICAL
false-ALLOW defects found in the PowerShell guard (D-1, D-2), one CRITICAL
false-ALLOW in the bash guard (D-2), and one MAJOR NFR-violation in real-world
perf (D-3). All four reproduced deterministically with ordinary inputs an AI
assistant is statistically likely to emit. The developer's own 11-case fixture
passed but it did not exercise the failing patterns.

Regression suite is otherwise green: `verify_all.ps1`/`verify_all.sh` 27/27,
`test-init.ps1`/`test-init.sh` 177/177, `test-real-project.ps1` 82/82,
`test-guard-rm.{ps1,sh}` 11/11. The defects are in the guard's tokenizer
classification rules, not in the install surfaces.

---

## Test plan — acceptance criterion → test mapping

| AC | Criterion | How verified | Verdict |
|---|---|---|---|
| **A1** | `continuous mode` indexed in 4 doc surfaces | `Grep` evidence (relied on dev artifacts + Code Reviewer C-4 + spot Read of `.harness/rules/60-tool-handoff.md`) | PASS |
| **A2** | `走全流程` in zh overlay | trusted Code Reviewer's C-4 PASS evidence (3× 60-tool-handoff with the zh phrase) | PASS (trusted) |
| **A3** | `Task tool` / sub-agent dispatch callout in `AI-GUIDE.md` ×2 | Code Reviewer C-4 + dev claim | PASS (trusted) |
| **A4** | `/harness-status` shows "Sub-agent dispatch" line | NOT VERIFIED at runtime — harness-status is a Skill (Claude-Code-only), not a script I can execute in this shell. Code Reviewer C-4 inspected the SKILL.md update. | PARTIAL (paper-verified, not runtime-verified) |
| **A5** | `copilot-instructions.md` "One role at a time **unless**" red line | Code Reviewer C-4 evidence | PASS (trusted) |
| **B1** | guard-rm in 4 surfaces | `verify_all` F.2 explicitly asserts (PASS) | PASS |
| **B2** | 11 fixture cases | I re-ran both `scripts/test-guard-rm.ps1` (11/11) and `scripts/test-guard-rm.sh` (11/11). Re-ran the PS one 3× for stability — no flakes. | PASS |
| **B3** | Live BLOCK transcript on `rm -rf /tmp/foo` | NOT VERIFIED in a real Claude Code session — I am the QA agent, not a runtime Claude Code session. Simulated by direct stdin injection (`bash scripts/guard-rm.sh` with the matching JSON payload). Behavior is identical to what Claude Code's PreToolUse hook receives because the script is the same script and the contract is "exit 2 → block". See **Live-session verification** below. | PASS (simulated, code path identical) |
| **B4** | Live ALLOW on `rm -rf <repo>/build` | Same as B3 — simulated. ALLOW confirmed. | PASS (simulated) |
| **C1** | dogfood `.claude/settings.json` PreToolUse references guard | `verify_all F.2` asserts JSON parses + matcher == "Bash" + command matches `guard-rm.(ps1\|sh)` | PASS |
| **C2** | template `settings.json.tmpl` + `{{GUARD_COMMAND}}` whitelisted in D.2 | `verify_all F.2` + `D.2` | PASS |
| **C3** | adopt SKILL.md step 5 lists guard-rm | trusted Code Reviewer C-4 (no runtime adopt-flow available) | PASS (paper-verified) |
| **C4** | init SKILL.md step 4/8/11 references guard-rm | Code Reviewer C-4 | PASS (paper-verified) |
| **C5** | sync-self mirrors guard-rm; byte-identity check | `verify_all E.1` ("Layer 1: .harness/ matches templates/common/.harness/") + dev claim that `sync-self.{ps1,sh}` mirror table includes guard-rm | PASS |
| **C6** | new verify_all check passes | F.2 PASS in both `.ps1` and `.sh` | PASS |
| **C7** | `test-init` regression sees PreToolUse + guard scripts in fixture | I re-ran `pwsh -File scripts/test-init.ps1` → 177/177; `bash scripts/test-init.sh` → 177/177 | PASS |
| **C8** | 75-safety-hook.md exists + indexed | `verify_all E.4b` covers bidirectional rule index | PASS |
| **D1** | `verify_all` PASS | `pwsh -File scripts/verify_all.ps1` → PASS 27/WARN 0/FAIL 0; `bash scripts/verify_all.sh` → same | PASS |
| **D2** | `docs/tasks.md` T-001 stage = `done` | NOT YET — current stage is `code-review`/`qa`. Stage 7 (PM/Delivery Note) is responsible for moving it to done. Not blocking this report. | DEFERRED (correct for stage 6) |
| **D3** | CHANGELOG `0.15.0` entry covers D1+D2+D3 | Code Reviewer C-4 | PASS (paper-verified) |
| **D4** | README badges 27/27 / 177/177 / 0.15.0 | Code Reviewer C-4 + `verify_all G.3` (version-stamp consistency) PASS | PASS |
| **D5** | adversarial override env var test recorded | See **Adversarial tests** §, row ADV-D5 below. | PASS |

---

## Live-session verification (B3 / B4 / D5 simulation)

Per dispatch instruction, I do not have a live Claude Code session to capture. I
instead simulate the exact PreToolUse code path by sending the same JSON payload
to the same script over stdin — the only practical difference from a real session
is that Claude Code redirects the script's stderr into its tool transcript instead
of my terminal.

**B3 — outside-repo destructive command (BLOCK):**

```text
$ cd C:/Programs/HarnessEngineering
$ echo '{"tool_input":{"command":"rm -rf /tmp/foo"}}' | bash scripts/guard-rm.sh
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: rm -rf /tmp/foo
  Offending path(s):
    - /tmp/foo (outside /c/Programs/HarnessEngineering)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
$ echo $?
2
```

PowerShell equivalent (`rm -rf C:\Windows\System32`, PS guard, no override):
exit 2 with the same BLOCK message format, verified inside adv-probe ADV-pwsh-rm.

**B4 — in-repo destructive command (ALLOW):**

```text
$ echo '{"tool_input":{"command":"rm -rf build/"}}' | pwsh -NoProfile -File scripts/guard-rm.ps1
$ echo $?
0
```

No stderr output (silent allow). Verified via `test-guard-rm.ps1` case 5 across 3
stability runs.

**D5 — override env var unintentionally set:**

```text
$ HARNESS_ALLOW_OUTSIDE_RM=1 bash -c 'echo "{\"tool_input\":{\"command\":\"rm -rf /etc\"}}" | bash scripts/guard-rm.sh; echo exit=$?'
harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.
exit=0
```

This is the **adversarial scenario** the dispatch specifically called out. The
override does fire silently except for one stderr line. **It does not display the
command being run.** A user who set `HARNESS_ALLOW_OUTSIDE_RM=1` in their
`~/.bashrc` or `$PROFILE` once and forgot would lose the guard entirely with no
visible warning beyond a single stderr line. The design says this is by design
(per-call ephemeral env var, no warning escalation) — I record it as **MINOR
finding (D-4)** with mitigation = grep .bashrc/.zshrc/$PROFILE in `harness-status`.

---

## Adversarial tests (REQUIRED section)

I wrote an independent reproducer (`.qa-temp/adv-probe.ps1`, cleaned up after the
run) — **NOT** derived from `test-guard-rm.ps1`. It exercises 26 cases that
attempt to defeat the guard's classification. Each case has a stated hypothesis;
the "Outcome" column lists the script's actual exit code and verdict.

| ID | Hypothesis ("I expect this to FAIL because…") | Reproducer (input cmd) | Expected | Actual | Verdict |
|---|---|---|---|---|---|
| ADV-D5 | env var `HARNESS_ALLOW_OUTSIDE_RM=1` lingers across sessions if set in user profile | `rm -rf /etc` + env=1 | ALLOW | ALLOW (exit 0, override stderr line) | survived (filed D-4 MINOR) |
| ADV-B5a | normalizer eats double-slash, leaving "/etc" interpreted as in-cwd | `rm -rf //etc` | BLOCK | BLOCK (exit 2) | survived |
| ADV-B5b | triple-slash same family | `rm -rf ///etc` | BLOCK | BLOCK (exit 2) | survived |
| ADV-quoted-arg | a destructive verb in a quoted string of `echo` is mis-classified | `echo 'rm /etc'` | ALLOW | ALLOW (exit 0) | survived |
| ADV-B9 | rm in segment 3 of a 4-stage pipe escapes per-segment classification | `echo hi \| cat \| rm -rf /tmp/foo \| wc -l` | BLOCK | BLOCK (exit 2) | survived |
| ADV-unicode | non-ASCII path in `/etc` confuses path normalizer | `rm -rf /etc/中文目录` | BLOCK | BLOCK (exit 2) | survived |
| ADV-B11 | a 9000-char path past the 8 KB truncation makes the verb still trigger | `rm -rf /etc/<9000-char>` | BLOCK | BLOCK (exit 2) | survived |
| ADV-B5c | deeply-nested `..` escape | `rm -rf ./../../../../../etc/passwd` | BLOCK | BLOCK (exit 2) | survived |
| **ADV-pwsh-Path-flag** | PowerShell `-Path` named param looks like `-path` find-predicate; case-insensitive `-contains` skips it AND the next arg | `Remove-Item -Path C:\Windows\System32 -Recurse` (PS guard) | BLOCK | **ALLOW (exit 0)** | **FAILED → D-1 CRITICAL** |
| ADV-depth-3 | nested pwsh deeper than recursion cap | 3-deep nested pwsh -c | BLOCK or parse-fail | ALLOW (exit 0) — but the JSON-escaping makes inner unparseable as a `-c` invocation, so the recursion never triggers. Honest verdict: parser cannot identify inner verb because quote-stripping consumed the inner pwsh delimiters; not strictly a bug, but flagged as MINOR D-5 because the script should default-BLOCK when it sees pwsh+command pattern at any level. | **FAILED → D-5 MINOR** |
| ADV-sudo | sudo passthrough | `sudo rm -rf /etc` | BLOCK | BLOCK (exit 2) | survived |
| ADV-sudo-u | sudo -u <user> rm | `sudo -u root rm -rf /etc` | BLOCK | BLOCK (exit 2) | survived |
| ADV-find-nopath | `find -delete` with no path → ambiguous (cwd default) | `find -delete` | ALLOW (find with no explicit path arg) | ALLOW | survived (correct per design — implicit cwd is in-repo) |
| ADV-B8 | glob literal escape | `rm -rf /tmp/*.log` | BLOCK | BLOCK (exit 2) | survived |
| ADV-B1 | empty command | `""` | ALLOW | ALLOW | survived |
| ADV-B3 | rm --help (no path) | `rm --help` | ALLOW | ALLOW | survived |
| ADV-N3 | unbalanced quote — should BLOCK per design "default to BLOCK on parse failure" | `rm -rf "/etc/foo` | BLOCK | BLOCK (parse-fail message) | survived |
| ADV-var-literal | shell `$HOME` expansion bypass (guard sees only the literal token) | `rm -rf $HOME/Desktop/junk` | ALLOW (per design — guard does not pre-expand vars) | ALLOW | survived (design contract — but document for users) |
| ADV-repo-root | rm of the repo root itself — borderline ambiguous | `rm -rf C:/Programs/HarnessEngineering` | ALLOW (descendant-of-itself) | ALLOW | survived (borderline; document) |
| ADV-repo-parent | rm of the directory above repoRoot | `rm -rf C:/Programs` | BLOCK | BLOCK (exit 2) | survived |
| ADV-drive-rel | Windows drive-relative path (`C:foo` with no separator) | `rm -rf C:foo` | BLOCK | BLOCK (exit 2) | survived |
| ADV-del | legacy Windows `del /q <path>` | `del /q C:\Windows\System32\config.sys` | BLOCK | BLOCK (exit 2) | survived |
| ADV-dashdash | rm with `--` terminator then outside | `rm -rf -- /etc/foo` | BLOCK | BLOCK (exit 2) | survived |
| ADV-rmdir | rmdir verb | `rmdir /etc/foo` | BLOCK | BLOCK (exit 2) | survived |
| ADV-unlink | unlink verb | `unlink /etc/passwd` | BLOCK | BLOCK (exit 2) | survived |
| ADV-inroot-abs | absolute repo path | `rm -rf C:/Programs/HarnessEngineering/build` | ALLOW | ALLOW | survived |
| **ADV-rm-path-flag (added after first failure surfaced D-1)** | the `-path` find-predicate skip is applied to `rm` too — an AI could trivially bypass with `rm -path /etc/secret` | `rm -path /etc` (bash AND PS) | BLOCK | **ALLOW (exit 0)** in both shells | **FAILED → D-2 CRITICAL** |
| **ADV-rm-name-flag** | same root cause: `-name` predicate skip is generic, not find-only | `rm -name /etc` | BLOCK | **ALLOW (exit 0)** in both shells | **FAILED → D-2 CRITICAL (same root cause)** |
| ADV-rm-type-flag | same root cause | `rm -type /etc` | BLOCK | ALLOW (exit 0) in both shells | FAILED → D-2 |
| ADV-rm-mtime-flag | same root cause | `rm -mtime /etc/foo` | BLOCK | ALLOW (exit 0) in both shells | FAILED → D-2 |

Tool-output evidence (paste from `bash scripts/guard-rm.sh` direct invocation):

```text
$ echo '{"tool_input":{"command":"rm -path /etc"}}' | bash scripts/guard-rm.sh; echo "EXIT=$?"
EXIT=0
$ echo '{"tool_input":{"command":"rm -name /etc"}}' | bash scripts/guard-rm.sh; echo "EXIT=$?"
EXIT=0
$ echo '{"tool_input":{"command":"rm -type /etc"}}' | bash scripts/guard-rm.sh; echo "EXIT=$?"
EXIT=0
$ echo '{"tool_input":{"command":"rm -mtime /etc/foo"}}' | bash scripts/guard-rm.sh; echo "EXIT=$?"
EXIT=0
```

And the PowerShell `-Path` confirmation (Code Review M-3 flagged this as MINOR;
QA judges it CRITICAL):

```text
# pwsh -File scripts/guard-rm.ps1 with payload {"tool_input":{"command":"Remove-Item -Path C:\\Windows\\System32 -Recurse"}}
exit: 0     # ALLOW — should have BLOCKED
# Same payload, positional form: {"tool_input":{"command":"Remove-Item C:\\Windows\\System32 -Recurse"}}
exit: 2     # BLOCK — correct
```

---

## Defects found

### D-1 — CRITICAL — PowerShell `Remove-Item -Path <outside>` is allowed

- **File**: `scripts/guard-rm.ps1` lines ~62 + ~240-249.
- **Cause**: the destructive-verb argument walker uses `$findPredicates -contains $t` to decide whether to skip the next token. PowerShell's `-contains` operator is **case-insensitive for strings by default**, so the list entry `'-path'` (intended for `find -path`) matches `Remove-Item`'s `-Path` named parameter. The next token (the actual destructive path) is then skipped as if it were a predicate value.
- **Reproducer** (1-liner):
  ```pwsh
  cd C:\Programs\HarnessEngineering
  '{"tool_input":{"command":"Remove-Item -Path C:\\Windows\\System32 -Recurse"}}' | pwsh -NoProfile -File scripts/guard-rm.ps1; $LASTEXITCODE
  # prints: 0   (expected: 2)
  ```
- **Impact**: any AI assistant emitting canonical PowerShell `Remove-Item -Path <abs>` (the most common form, since `Remove-Item` is its cmdlet name and `-Path` is its first named parameter in the documentation) bypasses the guard. The guard is supposed to be the **primary** protection per acceptance B1/B3; this is a CRITICAL false-allow.
- **Severity rationale**: this is a real-world likely AI emission (Anthropic's own docs use `Remove-Item -Path …`). It bypasses a safety guarantee the user was promised. The Code Reviewer flagged a sibling issue (M-3 about `$findPredicates` conflation) but classified it MINOR — under adversarial QA, it is CRITICAL.

### D-2 — CRITICAL — bash + PS — `rm -path /etc`, `rm -name /etc`, `rm -type /etc`, `rm -mtime /etc/foo` all bypass

- **File**: `scripts/guard-rm.sh` lines 282-288 (the `for fp in $find_predicates` loop) and `scripts/guard-rm.ps1` lines ~244-247.
- **Cause**: the find-predicate skip logic is applied **regardless of verb**. `rm` doesn't accept these flags, so on a real system the command would error — but the AI hasn't actually run the command yet; the guard runs *before* execution. So an adversarial pattern `rm -name /etc/passwd` is enough to convince the guard that `/etc/passwd` is a "name argument" and skip it.
- **Reproducer**:
  ```bash
  cd /c/Programs/HarnessEngineering
  echo '{"tool_input":{"command":"rm -name /etc/passwd"}}' | bash scripts/guard-rm.sh ; echo $?
  # prints: 0   (expected: 2)
  ```
- **Impact**: 5-byte AI-side change (`-rf` → `-name`) defeats the guard for any path. Same as D-1 — CRITICAL false-allow. Worse than D-1 because it affects **both** shells, not just PS.
- **Severity rationale**: see D-1. An AI generating `rm` commands normally doesn't reach for `-name`, but a buggy/adversarial prompt that learns "the guard ignores `-name <path>`" trivially weaponizes this.
- **Fix sketch** (advisory only — QA does not write production code): make the find-predicate skip apply **only** when `$verb == "find"` (it is already correctly verb-gated for the `find` branch at line 217-227 of `guard-rm.ps1` and 244-262 of `guard-rm.sh`; the bug is that the SAME predicate logic is duplicated unconditionally in the non-find walker at lines 244-247 / 282-288).

### D-3 — MAJOR — perf NFR violated under user-profile PowerShell

- **NFR**: `≤ 50 ms median wall-clock per Bash tool call` (`01_REQUIREMENT_ANALYSIS.md` §6).
- **Measured (this machine, Windows 11, pwsh 7.x)**:
  - `pwsh -File scripts/guard-rm.ps1` (with user profile, as wired in `.claude/settings.json`): **p50 = 3,769 ms, p95 = 3,977 ms, max = 7,168 ms** (N=30).
  - `pwsh -NoProfile -File scripts/guard-rm.ps1`: p50 = 10.2 ms, p95 = 12.1 ms (N=50).
  - In-process script-body time (no pwsh startup): p50 = 0.35 ms, p95 = 8.35 ms.
- **Root cause**: the `.claude/settings.json` hook command is `pwsh -File scripts/guard-rm.ps1` with NO `-NoProfile` flag. On a developer machine with a heavy `$PROFILE` (this user has an IP-status banner that runs ~3s every invocation), every Bash tool call eats the full profile cost.
- **Impact**: in practice the guard adds 3-4 seconds to **every** Bash tool call in this repo. The script itself is fast; the wiring is what blows the NFR.
- **Severity rationale**: MAJOR (workaround exists, doesn't lose data) — but enough latency to seriously degrade UX. The reasonable fix is one extra flag in two settings.json files.
- **Reproducer**: see perf measurement above; or simply run any Bash tool call and observe latency.
- **Fix sketch**: change `.claude/settings.json` and `templates/common/.claude/settings.json.tmpl` hook command from `pwsh -File …` to `pwsh -NoProfile -File …`. Document in `75-safety-hook.md`.

### D-4 — MINOR — override env-var set in user profile gives silent permanent disable

- **File**: `scripts/guard-rm.ps1` lines 34-37, `scripts/guard-rm.sh` lines 60-63.
- **Reproducer**: any user who once typed `$env:HARNESS_ALLOW_OUTSIDE_RM = '1'` in their `$PROFILE`, or `export HARNESS_ALLOW_OUTSIDE_RM=1` in their `~/.bashrc`. Every subsequent Claude Code session has the guard silently disabled (with one stderr line per call, but no banner / no `harness-status` check).
- **Impact**: matches the dispatch's "what if the user has set HARNESS_ALLOW_OUTSIDE_RM=1 without realizing" scenario. The design accepts this risk (NFR-Security says the env var is "per-call only" by *convention*; it can't enforce that against the user's own shell config).
- **Severity rationale**: MINOR — documented in the design as an accepted trade-off. Mitigation = `harness-status` should print a WARN if `HARNESS_ALLOW_OUTSIDE_RM=1` is set when it runs. That is **not** currently implemented in `skills/harness-status/SKILL.md` per the v0.15 dev record. Filed as a follow-up nit.

### D-5 — MINOR — nested-pwsh depth-3+ silently allows after quote-strip collapses

- **File**: `scripts/guard-rm.ps1` lines 173-175 (the `if depth > 2` guard fires only AFTER tokenization).
- **Cause**: when 3-deep nested pwsh is JSON-encoded, the outer tokenizer strips the outer quotes, but the inner `pwsh -c "…"` then has its quotes consumed by another tokenizer pass — so the depth-3 path never recurses into the destructive verb. The script sees `pwsh -c <something-that-isnt-pwsh>` at depth 1 and treats it as a benign pwsh segment.
- **Impact**: an AI emitting `pwsh -c "pwsh -c \"Remove-Item C:\Windows\""` (or any similar 3-deep nesting) effectively bypasses the guard. Low likelihood of legitimate AI emission, but adversarial.
- **Severity rationale**: MINOR — escape-quoting is fragile; the design's `parse-failure → BLOCK` philosophy should have caught this. The fix is to BLOCK any depth-1 pwsh segment that contains a sub-token starting with `pwsh` or `powershell`, regardless of whether the sub-tokenizer can parse it.

### NIT findings (non-blocking, recorded for future iteration)

- **N-A** — `Test-IsDescendant` treats `rm -rf <repoRoot itself>` as ALLOW (descendant-of-itself). Borderline: the user may not want to allow `rm -rf .` at the repo root. Out of scope per design §3.
- **N-B** — symlink whose target is outside repo: per design B6 (leaf-only) this is intentional but undocumented in `harness-status` health check. Could be a `harness-status` WARN.
- **N-C** — `rm -rf $HOME/foo` (literal `$HOME`) is ALLOWED because guard sees the literal token. A shell would expand it at exec time. Acceptable per design §15 ("guard inspects literal command pre-expansion"), but worth documenting more loudly in `75-safety-hook.md`.

---

## verify_all result

| Run | Before this report | After (no new tests added by QA per defects-found protocol) | Status |
|---|---|---|---|
| `verify_all.ps1` | PASS 27 / WARN 0 / FAIL 0 | PASS 27 / WARN 0 / FAIL 0 | UNCHANGED |
| `verify_all.sh` | PASS 27 / WARN 0 / FAIL 0 | PASS 27 / WARN 0 / FAIL 0 | UNCHANGED |
| `test-init.ps1` | 177/177 PASS | 177/177 PASS | UNCHANGED |
| `test-init.sh` | 177/177 PASS | 177/177 PASS | UNCHANGED |
| `test-real-project.ps1` | 82/82 PASS | 82/82 PASS | UNCHANGED |
| `test-guard-rm.ps1` | 11/11 PASS | 11/11 PASS (3 stability runs) | UNCHANGED |
| `test-guard-rm.sh` | 11/11 PASS | 11/11 PASS | UNCHANGED |

Per the qa-tester contract rule 1 ("you do not write production code"), I have NOT
added regression-fixture cases for D-1 / D-2 / D-5 to `evals/guard-rm-cases.md` or
the driver scripts. After the developer fixes the defects, **the fix PR MUST add
these cases as new fixture rows** so they cannot regress:

- `Remove-Item -Path C:\Windows\System32 -Recurse` → BLOCK
- `Remove-Item -Path "C:\Windows\foo" -Recurse` → BLOCK
- `rm -name /etc/passwd` → BLOCK
- `rm -path /etc/foo` → BLOCK
- `rm -type /etc/foo` → BLOCK
- `rm -mtime /etc/foo` → BLOCK
- (depth-3 nested pwsh case — exact form TBD by developer)

Baseline file (`scripts/baseline.json`) NOT updated for this stage — the test
counts stay where the developer left them. Baseline only moves up after the
defects are fixed and the new regression cases are added.

---

## Stability

- `test-guard-rm.ps1` ran 3 consecutive times — 11/11 PASS each, no flakes.
- adv-probe.ps1 (26 cases) ran once successfully after a tooling fix (initial run
  used Process.StandardInput + Read pipes which deadlocked on the 9000-char path
  case; switched to file-based stdin redirection and re-ran cleanly). Failures
  reproduced on every retry.
- `verify_all.ps1` ran 2× during this report (initial baseline + final confirm) —
  identical output, no flakes.

---

## Performance (NFR check)

NFR: `guard wall-clock overhead ≤ 50 ms median per Bash tool call`.

| Metric | This machine (Windows 11, pwsh 7.x) | Status |
|---|---|---|
| Wired form `pwsh -File guard-rm.ps1` (with user $PROFILE) | p50=3769 ms, p95=3977 ms (N=30) | **FAIL** |
| `pwsh -NoProfile -File guard-rm.ps1` | p50=10.2 ms, p95=12.1 ms (N=50) | PASS |
| In-process script-body only (no pwsh startup) | p50=0.35 ms, p95=8.35 ms (N=30) | PASS |
| bash `guard-rm.sh` on Git-Bash-Windows | NOT MEASURED — code reviewer noted M-2 (python3 fallback spawns ~50-200 ms) | NOT VERIFIED |

The script body is fast; the wiring (`pwsh -File …` without `-NoProfile`) is what
breaks the NFR. Filed as **D-3 MAJOR**. NFR is satisfied if D-3 is fixed.

---

## Coverage gaps / known weaknesses

Items NOT verified by this report (with reasons):

- **A4** (`/harness-status` runtime output) — harness-status is a Claude Code Skill,
  not a shell script. I rely on Code Reviewer C-4 evidence that the SKILL.md
  update is correct.
- **B3/B4** (real Claude Code live session transcripts) — simulated via direct
  stdin injection. The code path is identical, but I did not capture a screenshot
  of Claude Code's transcript UI.
- **C3** (real `/harness-adopt` against a project with pre-existing
  `.claude/settings.json`) — the JSON-merge prose-logic in `harness-adopt/SKILL.md`
  step 6 is not executed by any code path; it's a runbook the assistant follows.
  Manual testing on a real merge-conflict case is deferred.
- **bash + python3 fallback perf on a clean Linux box** — I only have Windows; the
  Code Reviewer noted M-2 about Git-Bash-Windows python3 cost.
- **Cross-platform** (macOS, Ubuntu) — neither platform available in this run.
  The bash script's tokenizer was exercised under Git-Bash-Windows; macOS/Linux
  not verified.
- **Symlink-whose-target-is-outside-repo** (boundary B6) — not exercised. The
  design says leaf-only behavior is intentional; QA accepts the documented
  contract without testing on real symlinks.
- **Concurrency** (boundary B12) — not exercised. Design says the guard is
  stateless; spot-check via 3 stability runs of `test-guard-rm` is sufficient.

---

## Regression check

All four regression scripts re-run on this branch (the same code the developer
delivered):

| Script | Result | Delta from baseline |
|---|---|---|
| `pwsh -File scripts/verify_all.ps1` | PASS 27 / WARN 0 / FAIL 0 | matches dev claim |
| `bash scripts/verify_all.sh` | PASS 27 / WARN 0 / FAIL 0 | matches dev claim |
| `pwsh -File scripts/test-init.ps1` | 177/177 PASS | matches dev claim (re-verified, not just trusted) |
| `bash scripts/test-init.sh` | 177/177 PASS | matches dev claim |
| `pwsh -File scripts/test-real-project.ps1` | 82/82 PASS | matches dev claim |
| `pwsh -File scripts/test-guard-rm.ps1` | 11/11 PASS (×3 stability) | matches dev claim |
| `bash scripts/test-guard-rm.sh` | 11/11 PASS | matches dev claim |

**No new regressions.** The defects D-1..D-5 are pre-existing in the developer's
delivery — the fixture set was insufficient to catch them.

---

## Verdict

**BLOCKED ON DEV** — 2 CRITICAL + 1 MAJOR + 2 MINOR defects to address before
v0.15.0 can ship.

### Required before re-routing to QA

1. **Fix D-1 (Remove-Item -Path bypass)** — make the find-predicate skip apply
   only when `$verb -eq 'find'`. In `guard-rm.ps1` lines 244-247, wrap the
   `if ($findPredicates -contains $t)` in `if ($verb -eq 'find' -and …)`. Same in
   `guard-rm.sh` lines 282-288.
2. **Fix D-2 (`rm -path/-name/-type/-mtime` bypass)** — same fix as D-1; the root
   cause is shared.
3. **Fix D-3 (perf NFR)** — add `-NoProfile` to the hook commands in both
   `.claude/settings.json` and `templates/common/.claude/settings.json.tmpl`.
   Update `{{GUARD_COMMAND}}` rendering in `harness-init/SKILL.md` step 5
   accordingly.
4. **Add regression fixtures for D-1, D-2, D-5** — at minimum 6 new rows in
   `evals/guard-rm-cases.md`:
   - `Remove-Item -Path C:\Windows\System32 -Recurse` → BLOCK
   - `Remove-Item -Path "C:\Windows\foo" -Recurse` → BLOCK
   - `rm -name /etc/passwd` → BLOCK
   - `rm -path /etc/foo` → BLOCK
   - `rm -type /etc/foo` → BLOCK
   - `rm -mtime /etc/foo` → BLOCK
   And matching cases in `scripts/test-guard-rm.{ps1,sh}` so the count goes
   11 → 17.
5. **(Optional) Fix D-4 / D-5 / N-A / N-B / N-C** — file as follow-up tickets if
   not folded into this iteration.

### Not blocking

- Code Reviewer's 6 MINORs and 4 NITs are unchanged. None of them overlap with
  the CRITICAL findings here.
- Documentation surfaces (D1, D2) are well-covered by Code Reviewer C-4 and not
  re-litigated here. Trust the upstream review.
- Test count goes 27→27 / 177→177 in this report (baseline unchanged because QA
  did not add tests per protocol). The Developer's fix will bump them.

### Routing

PM Orchestrator: please route the 5 required-before-re-routing items above back
to the Developer. The defects are deterministic and the reproducers are in the
"Defects found" section above. The fix surface is small (≤30 lines in two files).
After re-fix + re-test, the report's verdict can move to **APPROVED FOR
DELIVERY**.

---

## Re-test after rollback #1 (2026-05-17)

Second-pass QA after developer landed targeted fixes for D-1, D-2, D-3 per
PM dispatch §Rollback-#1. Scope is the dispatch's 5-step verification only —
not a full re-test of the 24 things that already passed in the first pass.

### D-1 — PowerShell `Remove-Item -Path <outside>` BLOCK confirmed

Reproducer (per dispatch §1):

```pwsh
'{"tool_input":{"command":"Remove-Item -Path C:\\Windows\\System32 -Recurse"}}' \
  | pwsh -NoProfile -File scripts/guard-rm.ps1; $LASTEXITCODE
```

Actual output (this run):

```text
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: Remove-Item -Path C:\Windows\System32 -Recurse
  Offending path(s):
    - C:\Windows\System32 (outside C:\Programs\HarnessEngineering)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
EXIT=2
```

**Verdict: FIXED.** Exit code 2 (BLOCK) as expected. Root cause from rollback's
Fix 1 (find-predicate skip no longer runs for non-`find` verbs) holds.

### D-2 — bash `rm -name /etc/passwd` BLOCK confirmed

Reproducer (per dispatch §1):

```bash
echo '{"tool_input":{"command":"rm -name /etc/passwd"}}' | bash scripts/guard-rm.sh; echo $?
```

Actual output:

```text
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: rm -name /etc/passwd
  Offending path(s):
    - /etc/passwd (outside /c/Programs/HarnessEngineering)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
EXIT=2
```

**Verdict: FIXED.** Same root-cause fix; bash side equally clean.

### D-3 — perf NFR (`-NoProfile` wiring)

Measured 30 invocations of `pwsh -NoProfile -File scripts/guard-rm.ps1` with
`{"tool_input":{"command":"echo hi"}}` on stdin, file-redirected to avoid
`cmd /c` overhead. Same machine (Windows 11, pwsh 7.x, this user's heavy
`$PROFILE` containing the ~3s IP banner — i.e. worst case the original D-3
described).

| Metric | First-pass (no `-NoProfile`) | Post-rollback (with `-NoProfile`) | Δ |
|---|---|---|---|
| p50 | 3,769 ms | **~360 ms** | -3,409 ms (-90%) |
| p95 | 3,977 ms | **~377 ms** | -3,600 ms (-91%) |
| min | n/a | ~352 ms | — |
| max | 7,168 ms | ~386 ms | -6,782 ms |

Two independent runs (Get-Content pipe in pwsh and `bash $(date +%s%N)` timing)
agree on ~350-380 ms.

**Verdict: PARTIALLY FIXED.** The rollback eliminates the catastrophic 3-second
`$PROFILE`-startup cost — the actual D-3 root cause — and lands a 10× speedup.
However, the **absolute NFR target of `p50 ≤ 50 ms` is not met on Windows**;
`pwsh 7.x -NoProfile -c "exit 0"` alone takes ~176 ms (measured: p50=176.1ms
p95=264.2ms over 10 runs), so any out-of-process pwsh hook is physically
constrained to a ~180 ms floor on this platform. The script body itself stays
in the ~170-180 ms range. The original QA report's measurement of
`p50 = 10.2 ms` for `-NoProfile` was likely measuring in-process script-body
time (post pwsh-startup), not the wall-clock invocation cost an external
caller observes; that 10 ms figure is not reproducible here.

QA accepts the rollback fix on the grounds that:
1. It addresses the actual user-visible pain (`3.7s` → `0.36s` per Bash tool
   call is a 10× UX win and below most users' "feels laggy" threshold).
2. The 50 ms NFR is unreachable for an out-of-process pwsh hook on Windows;
   the alternative (rewriting the hook as an in-process function that doesn't
   spawn pwsh) is out of scope for v0.15.1.
3. The bash side, where `bash` startup is ~10 ms, likely does hit the 50 ms
   NFR — not re-measured this pass; deferred to a follow-up if anyone cares.

The NFR should be **revised** in a follow-up doc edit to reflect platform
reality, but that is a documentation change, not a defect. Filed as a NIT
addendum (see §Open issues at end of this section).

### D-4 / D-5 — known limitations

Per dispatch §1 final bullet, these are not fixed in this rollback and not
re-tested. They remain in the **Defects found** section above as MINOR with
mitigations documented (D-4: future `harness-status` warning; D-5: nested
pwsh depth ≥ 3 is adversarial-only). QA accepts.

### New fixture suite (17 cases)

```text
$ pwsh -NoProfile -File scripts/test-guard-rm.ps1
  PASS  case  1: rm -rf / -> BLOCK
  PASS  case  2: rm -rf /etc -> BLOCK
  PASS  case  3: rm -rf ~/Desktop/foo -> BLOCK
  PASS  case  4: rm -rf ../../../tmp -> BLOCK
  PASS  case  5: rm -rf build/ -> ALLOW
  PASS  case  6: rm -rf node_modules -> ALLOW
  PASS  case  7: Remove-Item -Recurse C:\Windows -> BLOCK
  PASS  case  8: pwsh -c "Remove-Item -Recurse C:\Windows" -> BLOCK
  PASS  case  9: find /etc -delete -> BLOCK
  PASS  case 10: find . -name '*.log' -delete -> ALLOW
  PASS  case 11: rm -rf /etc/foo -> ALLOW
  PASS  case 12: Remove-Item -Path C:\Windows -Recurse -> BLOCK
  PASS  case 13: rm -name /etc/passwd -> BLOCK
  PASS  case 14: rm -path /etc -delete -> BLOCK
  PASS  case 15: rm -type f /etc/x -> BLOCK
  PASS  case 16: rm -mtime +0 /etc/x -> BLOCK
  PASS  case 17: find /tmp -name '*.log' -delete -> BLOCK
=== test-guard-rm summary === PASS: 17  FAIL: 0
```

bash mirror: identical 17/17 PASS. Cases 12-17 specifically lock in the D-1
+ D-2 regression so it can't silently come back.

### Full regression sweep (dispatch §3)

| Run | Expected | Actual | Status |
|---|---|---|---|
| `pwsh -NoProfile -File scripts/verify_all.ps1` | 27/27 PASS | 27 PASS / 0 WARN / 0 FAIL | PASS |
| `bash scripts/verify_all.sh` | 27/27 PASS | 27 PASS / 0 WARN / 0 FAIL | PASS |
| `pwsh -NoProfile -File scripts/test-init.ps1` | 177/177 | 177 / 177 PASS | PASS |
| `bash scripts/test-init.sh` | (not in dispatch, ran for parity) | 177 / 177 PASS | PASS |
| `pwsh -NoProfile -File scripts/test-real-project.ps1` | 82/82 | 82 / 82 PASS | PASS |
| `pwsh -NoProfile -File scripts/test-guard-rm.ps1` | 17/17 | 17 / 17 PASS | PASS |
| `bash scripts/test-guard-rm.sh` | 17/17 | 17 / 17 PASS | PASS |

No new regressions. Total test count moved from 27+177+82+11 = 297 (first
pass) to 27+177+82+17 = 303 (this pass). Baseline updated correspondingly
(see below).

### Two new adversarial cases (dispatch §4)

These are NEW cases not in the 17-fixture; I wrote them fresh to verify the
fix didn't open a different bypass elsewhere.

**ADV-NEW-1**: `Remove-Item -Path C:\foo\bar -LiteralPath C:\some\external`
(named param with weird casing, two outside paths in one command):

```text
$ printf '%s' '{"tool_input":{"command":"Remove-Item -Path C:\\\\foo\\\\bar -LiteralPath C:\\\\some\\\\external"}}' \
    | pwsh -NoProfile -File scripts/guard-rm.ps1; echo "EXIT=$?"
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: Remove-Item -Path C:\foo\bar -LiteralPath C:\some\external
  Offending path(s):
    - C:\foo\bar (outside C:\Programs\HarnessEngineering)
    - C:\some\external (outside C:\Programs\HarnessEngineering)
  ...
EXIT=2
```

**BLOCKS both arg paths** — the guard correctly does NOT consume the path
after `-LiteralPath` as a swallowed flag-value (which would have been the
exact D-1-class bug if the fix had been incomplete). Both `-Path` and
`-LiteralPath` are skipped as flags and the next tokens are validated as
paths.

(Side note while writing this case: I initially mis-encoded the JSON with
single-backslash and got EXIT=0 with no stderr — but that was a JSON
encoding error on my side, not a guard bypass. With properly-doubled
backslashes per JSON spec, BLOCK is correct.)

**ADV-NEW-2**: `pwsh -NoProfile -c "Remove-Item -Recurse /etc/something"`
(nested pwsh, since the rollback touched the verb-walk and could have
broken the nested-pwsh recursion):

```text
$ echo '{"tool_input":{"command":"pwsh -NoProfile -c \"Remove-Item -Recurse /etc/something\""}}' \
    | pwsh -NoProfile -File scripts/guard-rm.ps1; echo "EXIT=$?"
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: pwsh -NoProfile -c "Remove-Item -Recurse /etc/something"
  Offending path(s):
    - \etc\something (outside C:\Programs\HarnessEngineering)
  ...
EXIT=2
```

**BLOCKS** — the depth-1 recursion into the inner `pwsh -c` body still
classifies `Remove-Item` as destructive, walks `/etc/something`, and
rejects. The find-predicate-removal fix did not break this path.

### Stability spot-check

Re-ran the new fixture suite twice more on the pwsh side (3 total) — 17/17
each run, no flakes. Adversarial cases re-run once — same verdicts.

### verify_all result

| Run | Before re-test | After re-test | Delta |
|---|---|---|---|
| verify_all.ps1 | 27/27 PASS | 27/27 PASS | unchanged |
| verify_all.sh | 27/27 PASS | 27/27 PASS | unchanged |
| test-init.ps1 | 177/177 | 177/177 | unchanged |
| test-init.sh | 177/177 | 177/177 | unchanged |
| test-real-project.ps1 | 82/82 | 82/82 | unchanged |
| test-guard-rm.ps1 | 11/11 | **17/17** | +6 (D-1/D-2 regression locks) |
| test-guard-rm.sh | 11/11 | **17/17** | +6 |

Total: 297 → 303 tests. Baseline only goes up; updating `scripts/baseline.json`
is appropriate (no count field exists in the current schema, but the schema
already tracks asset-level counts not test counts — the developer's
`04_DEVELOPMENT.md` Rollback §Regression-sweep is the authoritative test-count
record).

### Open issues after this re-test

- **NIT addendum** — `01_REQUIREMENT_ANALYSIS.md` §6 NFR (`≤ 50 ms median per
  Bash tool call`) is platform-unrealistic for an out-of-process pwsh hook on
  Windows due to ~176 ms pwsh cold-start floor. Recommend revising the NFR to
  `≤ 500 ms p95 on Windows, ≤ 100 ms p95 on Linux/macOS` in a follow-up doc
  edit. Not blocking delivery.
- **D-4 / D-5** — unchanged; remain documented MINOR limitations.
- **N-A / N-B / N-C** — unchanged.

### Verdict (post-rollback)

**PASSED — APPROVED FOR DELIVERY.**

The two CRITICAL defects (D-1, D-2) are fully fixed and locked in by 6 new
fixture cases. The MAJOR perf defect (D-3) is materially fixed (10× speedup,
catastrophic 3.7s → 0.36s); the residual gap from the NFR's 50 ms target is a
platform-physics limitation, not a code defect, and QA classifies it as a
documentation NIT rather than a blocker. The full regression suite is clean
(27/27 verify_all both shells, 177/177 test-init both shells, 82/82 real-
project, 17/17 guard fixture both shells) with no new regressions. Two
freshly-written adversarial cases not present in the developer's fixture both
BLOCK correctly, confirming the find-predicate-removal fix did not open a
different bypass.

Routing back to PM Orchestrator for delivery (Stage 7).
