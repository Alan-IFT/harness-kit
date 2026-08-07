# Test Report — T-16 `hook-truth-derivation`

- **Stage**: 6 (qa-tester), mode `full`, dispatched from a `/harness-stream` drain.
- **Inputs**: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (round 2) ·
  `03_GATE_REVIEW.md` round 2 (APPROVED WITH CONDITIONS, §8 = 8 inspection-only items) ·
  `04_DEVELOPMENT.md` (round 2, READY FOR REVIEW) · `05_CODE_REVIEW.md` round 2 (APPROVED,
  0 CRITICAL / 0 MAJOR, §8 = 5 inspection-only items).
- **Host**: bash 5.2.21 · GNU grep 3.11 (`/usr/bin/grep`) · GNU awk 5.2.1 · python3 present ·
  **`pwsh` ABSENT** (`command -v pwsh` fails). **No `.ps1` was executed or parsed by me either.**
- **deferred-human**: defer, do not ask. No `BLOCKED: NEEDS-HUMAN` point arose.
- **Method rule applied throughout**: every tally below is transcribed from the artifact that
  produced it. Nothing in this report is re-derived from `04_DEVELOPMENT.md`.

---

## 0. QA freeze discipline

- QA start `git status --porcelain` = 62 lines; QA end = **byte-identical** (`diff` empty).
- Every mutation I applied was reverted and confirmed by `sha256sum` **before** the next driver ran.
- Stray sweep at S-final for `*.t16bak`, `verify_all.s0*`, `*.qabak`, `*.bak-*`: **none**.
- `.harness/rules/75-safety-hook.md` = **200** lines, untouched.
- `docs/proposals/frontier-gaps-2026-07.md`: untracked, mtime `Jul 31 16:41` (pre-dates T-16's
  `T0 = 1785532976 / 2026-08-01 05:22:56`). Not read for requirements, not cited, not edited.

---

## 1. Test plan — every acceptance criterion mapped to a measurement

| AC | Test case(s) | Where / how measured |
|---|---|---|
| AC-1 single source | spec mutation `M-SPEC` in **both twins, both copies each** (4 files); all four flows re-run | §4 · QA-authored fixtures `qa-t16/mut-up`, `qa-t16/mut-mig`, spec invoked as `SKILL.md:198` documents |
| AC-2 byte-identity | 8 `(tool,OS)` cells × 2 script flows, diffed against an oracle **independent of hook-spec** | §3 · `git show cb0ed57:.harness/scripts/test-real-project.sh:48-57` (v0.44.0, predates `hook-spec` entirely) |
| AC-2 (prose flows) | 8 cells from `cb0ed57:skills/harness-init/SKILL.md:187-190`, `\|` unescaped per B-4 | §3.3 |
| AC-3 no literal survives | independent re-implementation of both A′ scans over 3 trees | §6 · `qa-t16/aprime.sh` |
| AC-4 fail-closed | static half (4 flow-emitted guard values) + runtime half executing the **written** value | §5 · `qa-t16/ac4.sh` |
| AC-5 spec-unreachable | 7 degradation probes, each in the write **and** re-run direction | §5 |
| AC-6 prose true | grep + read-back of all three sentences; caps re-measured | §7 |
| AC-7 containment | M-C forward, S0 pre-change anti-vacuity, F-3 totality, **plus two QA-authored mutants** | §2 |
| AC-8 regressions | all 8 pinned drivers, both python3 conditions, each to its own summary line | §1.2 |
| AC-9 gate | `verify_all.sh`, check count read from the run | §1.1 |
| AC-10 PS honesty | operator list re-read from `baseline.json:_qa_note_t16` | §9 |
| AC-11 no scope leakage | `sha256sum -c` over the 20-entry S0 frozen table | §8 |
| NFR-1 flow latency | counting shim around the spec | §5.4 |
| NFR-2 no new surface | check count 32, no new script/state file | §1.1 |
| B-5 `&` hazard | naive `${var//…}` vs the shipped helper, on the real spec answer | §6.2 |
| B-6 `{{NAME}}` tokens | grep over the four shipped flow files | §5.4 |
| B-7 CR / multi-line | adversarial corrupt-spec probe | §10 · **one MINOR observation** |

---

## 1.1 `verify_all` result

```
$ bash .harness/scripts/verify_all.sh ; echo "EXIT=$?"
...
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
[G.1] README references all 17 skills ... PASS
[H.1] Test fixtures present ... PASS
[G.2] CHANGELOG references all 17 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.1] AI-GUIDE.md ≤200 lines ... PASS
[I.2] Rule fragments ≤200 lines each ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.4] insight-index.md ≤30 evidence lines ... PASS
[I.5] docs/tasks.md ≤300 lines ... PASS
[I.7] Ignored INTERVENE supervision reports (WARN if >48h old on active task) ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
EXIT=0
```

Check count **read from the run**, not from `baseline.json`:

```
$ grep -cE '\.\.\. (PASS|WARN|FAIL)' verify_all-FINAL.txt
32
```

**AC-9 / NFR-2: PASS.** 32 checks, 32 PASS, **0 WARN** (a WARN would be a gate failure —
`verify_all` exits 1 on `warns > 0`), 0 FAIL, exit 0. `G.4` (which cross-checks the *live* check
count against the docs) is itself green, so the 32 is doubly anchored.

Enumerated for the record — the run emitted exactly these 32 ids, `G.4` last:
`A.1 A.2 B.1 B.2 C.1 C.2 D.1 D.2 D.3 E.1 E.2 E.3 E.4 E.4b E.5 E.6 E.7 F.1 F.2 G.1 H.1 G.2 G.3
I.1 I.2 I.3 I.4 I.5 I.7 I.6 J.1 G.4`.

> **Method note.** My first count used `grep -cE '^\[[A-Z]\.[0-9]+\]'` and returned **31** — it
> silently misses `[E.4b]`. Corrected before use. Recorded because a check-count pin verified with
> the wrong regex is exactly the "arithmetic instead of artifact" failure this repo pins against.

`sync-self --check`:

```
$ bash .harness/scripts/sync-self.sh --check ; echo "EXIT=$?"
In sync.
EXIT=0
```

---

## 1.2 Pinned drivers — real runs, each to its own summary line

Every row below is a transcribed run I executed. **A run that terminates without its summary line
is a failure, not a pass** — each was checked for its own terminator.

| Driver | Condition | Summary line reached | Result | Pin | Verdict |
|---|---|---|---|---|---|
| `verify_all.sh` | — | `=== Summary ===` | **PASS 32 / WARN 0 / FAIL 0** | `verify_all_checks` 32 | ✔ |
| `test-init.sh` | python3 **present** | `=== Result ===` | **PASS 391 / FAIL 0** | (no pin — not comparable) | ✔ |
| `test-init.sh` | python3 **shimmed to exit 127** | `=== Result ===` | **PASS 355 / FAIL 0** | `test_init_bash_no_python3_assertions` 355 | ✔ |
| `test-real-project.sh` | — | `=== Result ===` | **PASS 90 / FAIL 0** | `test_real_project_bash_assertions` 90 | ✔ |
| `test-harness-upgrade.sh` | — | `=== Summary ===` | **PASS 89 / FAIL 0** | `test_harness_upgrade_bash_assertions` 89 | ✔ |
| `test-verify-i6.sh` | — | `=== Result ===` | **PASS 58 / FAIL 0** | `test_verify_i6_bash_assertions` 58 | ✔ |
| `test-supervisor.sh` | python3 present | `=== Result ===` | **PASS 46 / FAIL 0** | (no pin) | ✔ |
| `test-supervisor.sh` | python3 **shimmed** | `=== Result ===` | **PASS 45 / FAIL 0** | `test_supervisor_bash_no_python3_assertions` 45 | ✔ |
| `test-language.sh` | — | `=== Summary ===` | **PASS 39 / FAIL 0** | `test_language_bash_assertions` 39 | ✔ |
| `test-guard-rm.sh` | — | `=== test-guard-rm summary ===` | **PASS 87 / FAIL 0** | `test_guard_rm_bash_assertions` 87 | ✔ |

The **355** tally, captured against the artifact that produced it (gate-review §8 item 1 — the
design's "17 rows in, 17 rows out" is arithmetic and the gate explicitly refused to certify it):

```
$ printf '#!/bin/sh\nexit 127\n' > $W/shim/python3 && chmod +x $W/shim/python3
$ PATH="$W/shim:$PATH" python3 -c 'pass'; echo "shim exit=$?"
shim exit=127
$ PATH="$W/shim:$PATH" bash .harness/scripts/test-init.sh ; echo "EXIT=$?"
...
  PASS  [BUG-2] broadened regex catches lowercase '{{project_name}}'

=== Result ===
  PASS: 355
  FAIL: 0
EXIT=0
```

The shim is the **python3-absent** condition the pin is named for: `test-init.sh:287-288` gates on
a *real invocation* (`echo '' | python3 -c 'pass'`), which the shim fails, so `init_have_python=0`
and the 3 `SKIP` blocks fire. The python3-**present** figure is **391** and is never compared
against 355.

All 18 numeric `baseline.json` keys re-read and matched against the frozen ledger:

```
.version = 1
.skill_count_baseline = 4          .template_agent_count_baseline = 7
.project_template_count_baseline = 2
.verify_all_checks = 32            .test_init_ps_assertions = 316
.test_init_bash_no_python3_assertions = 355
.test_real_project_ps_assertions = 90     .test_real_project_bash_assertions = 90
.test_supervisor_ps_assertions = 49       .test_supervisor_bash_no_python3_assertions = 45
.test_verify_i6_ps_assertions = 58        .test_verify_i6_bash_assertions = 58
.test_harness_upgrade_ps_assertions = 89  .test_harness_upgrade_bash_assertions = 89
.test_language_ps_assertions = 39         .test_language_bash_assertions = 39
.test_guard_rm_bash_assertions = 87
```

**Every bash pin is reproduced by a run I executed.** No pin moved. **AC-8: PASS.**

---

## 2. AC-7 — containment, both directions, plus two mutants the pipeline did not run

### 2.1 M-C forward (post-change gate must FAIL with exactly two tokens)

Mutation applied to `skills/harness-init/templates/common/.claude/settings.json.tmpl`:
`:43 "{{SYNC_COMMAND}}" → "{{GUARD_COMMAND}}"` (guard placeholder relocated into the `Stop` block)
and `:48-58 → '    "PreToolUse": [],'` (array emptied; the `hooks` container **and** the
`"PreToolUse"` key both survive). Result still valid JSON (`python3 -c "json.load(...)"` → `valid JSON`).

```
$ bash .harness/scripts/verify_all.sh ; echo "EXIT=$?"
EXIT=2
21:[F.2] Guard-rm scripts and settings-template guard wiring present ... FAIL
22-       skills/harness-init/templates/common/.claude/settings.json.tmpl:guard_command_not_in_PreToolUse skills/harness-init/templates/common/.claude/settings.json.tmpl:PreToolUse_no_command_entry

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
```

**Exactly two tokens**, and the two that did *not* fire are the proof: not
`no_GUARD_COMMAND_placeholder` (the placeholder is in the file) and not `no_PreToolUse_block`
(the key is present). That contrast *is* the presence-vs-containment distinction. Whole gate
**PASS 31 / WARN 0 / FAIL 1**, exit 2 — the design's prediction matched to the token.

### 2.2 Anti-vacuity — the pre-change gate must PASS on the same mutation

The pre-change artifact is the **S0 working-tree capture**, never `git show HEAD:`. I re-verified
its admissibility four ways, two of them independent of the developer's bookkeeping:

```
$ git cat-file -e cb0ed57:.harness/scripts/hook-spec.sh
fatal: path '.harness/scripts/hook-spec.sh' exists on disk, but not in 'cb0ed57'
       ^ HEAD is v0.44.0 and predates hook-spec entirely — HEAD:verify_all.sh is inadmissible

$ sha256sum t16-captures/s0/.harness_scripts_verify_all.sh
e5ef1fdd2293728c40a10d9fefc48561e6e7021ad43aae329c5008b4a7a679c1   <- equals the recorded S0 hash
$ sha256sum .harness/scripts/verify_all.sh
7e6c0ab64dbcf90bd3e6ee615310bb40e4671e98142bae101c23e647f34311be   <- live file hashes DIFFERENTLY
S0 live mtime 1785522577 -> 2026-08-01 02:29:37
T0            1785532976 -> 2026-08-01 05:22:56      S0 < T0 : True

# CONTENT-level admissibility (mine, not inherited):
$ grep -c 'guard_command_not_in_PreToolUse|PreToolUse_no_command_entry|PreToolUse_block_unterminated' s0/...verify_all.sh
0                                                    <- carries NONE of T-16's three new tokens
$ grep -n 'narrowed T-15' s0/...verify_all.sh
290:# F.2 — Guard-rm scripts ... (v0.15+; narrowed T-15)
314:    grep -qE '"PreToolUse"[[:space:]]*:' "$tmpl" || ...:no_PreToolUse_block
                                                     <- carries T-15's key-form anchoring
```

That fourth check is the one I trust most: the capture is provably **post-T-15 and pre-T-16** by its
own content, so it is the right artifact regardless of hashes or mtimes. Run:

```
$ cp s0/...verify_all.sh .harness/scripts/verify_all.s0qa.sh
$ bash .harness/scripts/verify_all.s0qa.sh ; echo "EXIT=$?"
PRE-CHANGE GATE EXIT=0
21:[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
$ rm -f .harness/scripts/verify_all.s0qa.sh    # deleted in the same step
$ find . -name 'verify_all.s0*' -not -path './.git/*'      # -> nothing
```

**The containment fix is load-bearing**: the same mutant that the pre-change gate blesses, the
post-change gate FAILs. Template restored byte- and mtime-exact
(`a58dc73f…aad56`, mtime `1785522855`) before any other driver ran.

### 2.3 The terminator rule's totality — I built the case the pipeline's case does **not** cover

See **Defect D-1** in §11. Summary of the measurement:

| Fixture | shipped `≤ IND` rule | round-1 `== IND` rule | real gate |
|---|---|---|---|
| block-form `PreToolUse` moved to last key inside `hooks` (**the case `04:202-204` and `02 §7.1` cite**) | `start=68 IND=4 term=78` → PASS | `start=68 IND=4 term=78` → **also PASS** | `[F.2] PASS`, 32/0/0 |
| **inline** `PreToolUse` as last key inside `hooks` (**QA-authored**) | `start=68 IND=4 term=69` → window `[68,68]` → PASS | `term=NR+1` → **`PreToolUse_block_unterminated` → FAIL** | `[F.2] PASS`, 32/0/0 |

```
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{GUARD_COMMAND}}" } ] } ]
  }
}
=== SHIPPED rule (<= IND) ===   start=68 IND=4 term=69 unterminated=no
=== ROUND-1 rule (== IND) ===   start=68 IND=4 term=71 unterminated=YES->FAIL
=== real gate on inline-last fixture ===  EXIT=0
21:[F.2] ... PASS      PASS: 32   WARN: 0   FAIL: 0
```

**The shipped rule is correct and strictly more total than round 1's.** The record's *evidence* for
that is not (D-1).

### 2.4 The terminator-**exclusion** tightening — QA-authored mutation `M-D`

`02 §7.1` claims (by inspection only) that round 1's *inclusive* window would let an inline sibling
event at width `IND` donate evidence to `PreToolUse`. I built that mutant: empty `"PreToolUse": [],`
immediately followed by an inline `"PostToolUse": [ … "command": "{{GUARD_COMMAND}}" … ],` at width 4.

```
    "PreToolUse": [],
    "PostToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{GUARD_COMMAND}}" } ] } ],
=== real gate (shipped, terminator EXCLUDED) ===  EXIT=2
[F.2] ... FAIL
       ...settings.json.tmpl:guard_command_not_in_PreToolUse ...settings.json.tmpl:PreToolUse_no_command_entry
  PASS: 31   WARN: 0   FAIL: 1
=== counterfactual: round-1 INCLUSIVE window on same file ===
inclusive window would contain GUARD_COMMAND: 1; "command": 1     <- would have PASSED
```

**Confirmed by measurement**, and rows evaluated independently (both tokens fire, so neither is
hiding behind a first match). Template restored byte-exact.

---

## 3. AC-2 — byte-identity against an oracle independent of the artifact under test

Comparing a post-change flow against `hook-spec` is circular. My oracle is
**`cb0ed57` (v0.44.0)**, which predates `hook-spec.{sh,ps1}` entirely (proved above) and is where
these byte-forms originated (T-12). I evaluated the eight literals at
`cb0ed57:.harness/scripts/test-real-project.sh:48-57` **in their own quoting context** (B-4).

### 3.1 Oracle ⇄ spec

```
$ diff ORACLE.tsv spec.tsv
IDENTICAL (8/8)
```

### 3.2 Oracle ⇄ what the flows actually WRITE (QA-authored 8-cell fixture, values re-encoded to the JSON-string body)

```
ambient-prompt  unix     sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'
ambient-prompt  windows  pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"
ambient-reset   unix     sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'
ambient-reset   windows  pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"
guard-rm        unix     sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
guard-rm        windows  pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"
harness-sync    unix     sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'
harness-sync    windows  pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"

$ diff ORACLE.tsv flow-upgrade.tsv     -> BYTE-IDENTICAL 8/8 (upgrade-project flow)
$ diff ORACLE.tsv flow-migrate.tsv     -> BYTE-IDENTICAL 8/8 (migrate-scripts-layout flow)
```

### 3.3 Prose flows

`cb0ed57:skills/harness-init/SKILL.md:187-190` carried all 8 byte-forms. With markdown `\|`
unescaped (B-4, presentation excluded), compared against the spec's answers:

```
cells compared: 8, differing: 0
```

And post-change both tables carry **no** byte-form:

```
$ grep -n 'Set-Location -LiteralPath|CLAUDE_PROJECT_DIR' skills/harness-init/SKILL.md   -> NONE (0 hits)
$ grep -n 'Set-Location -LiteralPath|CLAUDE_PROJECT_DIR' skills/harness-adopt/SKILL.md  -> NONE (0 hits)
```

**AC-2: PASS.** 8 cells × 2 script flows measured from emitted settings, 8 cells for the prose
flows, all against a pre-`hook-spec` oracle. This also independently discharges **RES-1's** one-time
half (the developer's C-2 used a *different* oracle and got the same answer; two independent oracles
agreeing is stronger than either alone).

---

## 4. AC-1 — single source, by construction

Mutation `M-SPEC`: `2>/dev/null ` → `2>/dev/nullQAMUT16 ` in the two unix `hs_command` /
`Get-HsCommand` shapes, applied to **both twins × both copies each = 4 files**.

```
$ bash .harness/scripts/hook-spec.sh command guard-rm unix
sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/nullQAMUT16 && bash .harness/scripts/guard-rm.sh'

=== ZERO edits to any flow file ===
.harness/scripts/upgrade-project.sh                     QAMUT16 hits=0
.harness/scripts/upgrade-project.ps1                    QAMUT16 hits=0
.harness/scripts/migrate-scripts-layout.sh              QAMUT16 hits=0
.harness/scripts/migrate-scripts-layout.ps1             QAMUT16 hits=0
skills/harness-init/SKILL.md                            QAMUT16 hits=0
skills/harness-adopt/SKILL.md                           QAMUT16 hits=0
```

All four flows then emit the mutated value:

```
FLOW 1 upgrade-project        EXIT=0   QAMUT16 in written settings: 8   pre-mutation form: 0
        sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/nullQAMUT16 && bash .harness/scripts/guard-rm.sh'   (S3.2, unix)
        sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/nullQAMUT16 && bash .harness/scripts/guard-rm.sh'   (S3.0, {{GUARD_COMMAND}})
FLOW 2 migrate-scripts-layout EXIT=0   QAMUT16: 4   pre-mutation form: 0
FLOW 3 harness-init SKILL.md — documented command executed verbatim (SKILL.md:198):
        $ bash .harness/scripts/hook-spec.sh command guard-rm "$(bash .harness/scripts/hook-spec.sh hostos)"
        sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/nullQAMUT16 && bash .harness/scripts/guard-rm.sh'
FLOW 4 harness-adopt SKILL.md:316 defers to the same invocation -> same answer, same twin
```

(8 for `upgrade-project` = 4 unix S3.2 cells + 4 S3.0 placeholder cells; the 4 windows cells keep
their unmutated windows shape, correctly, since only the unix shapes were mutated.)

Reverted from byte-preserving copies:

```
$ diff spec-sha-before.txt spec-sha-after.txt   -> SPEC RESTORED BYTE-EXACT (4/4 files)
$ grep -rn QAMUT16 .harness/ skills/ docs/ *.md -> 0 hits
$ bash .harness/scripts/hook-spec.sh command guard-rm unix
sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
$ bash .harness/scripts/sync-self.sh --check -> In sync.  EXIT=0
```

**AC-1: PASS.** `.ps1` twins mutated and reverted symmetrically but **not executed** — see §9.

---

## 5. AC-4 / AC-5 / B-1 / B-2 / B-3 — I tried hard to make a branch emit a permissive guard

### 5.1 Static half — all four flow-emitted `guard-rm` values (2 flows × 2 OS)

```
  upgrade-project          unix      ||exit0=False  trailing-exit0=False
  upgrade-project          windows   ||exit0=False  trailing-exit0=False
  migrate-scripts-layout   unix      ||exit0=False  trailing-exit0=False
  migrate-scripts-layout   windows   ||exit0=False  trailing-exit0=False
  values checked: 4, violations: 0
```

### 5.2 Runtime half — executing the value the flow **actually wrote**

```
  emitted value: sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
  --- guard present, benign payload (ls -la) ---
      exit=0
  --- guard present, DESTRUCTIVE payload outside project root ---
      exit=2  stderr=harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  --- guard ABSENT (deleted) ---
      exit=127  stderr=bash: .harness/scripts/guard-rm.sh: No such file or directory
  --- guard absent AND CLAUDE_PROJECT_DIR empty (degenerate) ---
      exit=127
  --- guard absent, .harness/scripts dir removed entirely ---
      exit=127
  --- restored: guard present again, destructive payload ---
      exit=2  (anti-vacuity: the probe really reaches a working guard)
```

The middle rows make the probe anti-vacuous. Payload targets a **non-existent** path outside the
repo, so a guard failure would have been harmless. **AC-4 unix half: PASS.** Windows runtime half
remains operator items 12(f)/13(e) and is **not claimed**.

### 5.3 Degradation matrix — seven ways to deny the flow an answer, each in the write and re-run direction

| # | Condition | Exit | Empty `"command"` | Guard permissive? | Residue |
|---|---|---|---|---|---|
| 1 | spec **absent** (all 3 candidates miss), token+brittle fixture | **4** | 0 | **no** | 9 `GAP\|hook-spec\|absent\|…`, 4 `CONFLICT\|congruence\|…`, `SUMMARY\|` present, 0 `.bak` |
| 2 | — **re-run** of #1 | **4** | 0 | **no** | `GAP`/`CONFLICT` output identical, 0 `.bak` |
| 3 | spec present but **`chmod 000`** (unreadable) | **4** | 0 | **no** | 9 `GAP\|`, 0 `.bak` |
| 4 | spec **exit 2**, empty stdout, every query | **4** | 0 | **no** | 9 `GAP\|`, 0 `.bak` |
| 5 | spec **exit 0 with empty stdout**, every query | **4** | 0 | **no** | 9 `GAP\|`, 0 `.bak` |
| 6 | **partial** — spec answers everything *except* `guard-rm` (exit 0, empty) | **4** | 0 | **no** | 6 of 8 cells rewired; only `guard-rm` left brittle + `{{GUARD_COMMAND}}` unresolved; 1 `CONFLICT\|` |
| 7 | **`hostos` fails**, `command` works | **4** | 0 | **no** | 1 `GAP\| host OS undeterminable`, 4 `CONFLICT\|`, **`SUMMARY\|` present** (no unbound-variable abort) |

The **partial** case is the sharpest, and it is exactly the fail-closed asymmetry B-3 demands:

```
RESULT|REWIRE-PLACEHOLDER|.claude/settings.json (SYNC_COMMAND -> sh -c 'cd \"$CLAUDE_PROJECT_DIR\" ...')
GAP|hook-spec|absent|.claude/settings.json (GUARD_COMMAND: hook wiring spec unavailable at .../hook-spec.sh — placeholder left unresolved)
RESULT|REWIRE-PLACEHOLDER|.claude/settings.json (AMBIENT_PROMPT_COMMAND -> ...)
RESULT|REWIRE-RESILIENT|.claude/settings.json (harness-sync.ps1 -> resilient form)
GAP|hook-spec|absent|.claude/settings.json (guard-rm.ps1: hook wiring spec unavailable — brittle command left as-is)
GAP|hook-spec|absent|.claude/settings.json (guard-rm.sh: hook wiring spec unavailable — brittle command left as-is)
CONFLICT|congruence|"command": "{{GUARD_COMMAND}}" -> unresolved placeholder token
    exit=4 | empty-cmd=0 | GUARD-unresolved=1 | .bak=1
      Ev_guard-rm_ps1    PERMISSIVE=False  'pwsh -NoProfile -File .harness/scripts/guard-rm.ps1'
      Ev_guard-rm_sh     PERMISSIVE=False  'bash .harness/scripts/guard-rm.sh'
      Ph_GUARD           PERMISSIVE=False  '{{GUARD_COMMAND}}'
```

**The "loud refusal then quiet blessing on the second run" pattern is not present.** Re-run of the
partial case:

```
  EXIT=4
    GAP|hook-spec|absent|... (GUARD_COMMAND: ... placeholder left unresolved)
    GAP|hook-spec|absent|... (guard-rm.ps1 ...)   GAP|... (guard-rm.sh ...)
    CONFLICT|congruence|"command": "{{GUARD_COMMAND}}" -> unresolved placeholder token
  .bak count after run2: 1     <- unchanged from run 1, no churn
```

I could find **no branch** that emits a permissive `guard-rm` command, writes an empty `"command"`,
or leaves a guardless residue that a second run blesses. **AC-4 / AC-5 / B-1 / B-2 / B-3: PASS.**

Case 7 also re-measures the design's F-4 repair independently: the `hostos`-failure branch skips the
S3.0 placeholder loop only, `ph_o`/`ph_c` are at S3 scope, the run reaches `SUMMARY|` and exits 4 —
**not** the exit-1 unbound-variable abort the un-hoisted counterfactual produces.

### 5.4 NFR-1 (spawn ceiling) and B-6 (`{{NAME}}` tokens)

Counting shim wrapped around the spec, full `upgrade-project` run:

```
  total spec invocations: 9   (NFR-1 ceiling: 9 = 8 cells + hostos)
    1 command ambient-prompt unix     1 command ambient-prompt windows
    1 command ambient-reset  unix     1 command ambient-reset  windows
    1 command guard-rm       unix     1 command guard-rm       windows
    1 command harness-sync   unix     1 command harness-sync   windows
    1 hostos
```

Exactly one invocation per `(tool, OS)` plus one `hostos`, with **no** repeat — the memoisation
survives, which is the measurable proof that D-6's out-variable convention (no
`x="$(hsa_command …)"` subshell) is honoured at every call site. **NFR-1: PASS.**

```
=== B-6: literal {{NAME}} tokens in the four shipped flow files? ===
  upgrade-project.sh            (none)
  upgrade-project.ps1           (none)
  migrate-scripts-layout.sh     (none)
  migrate-scripts-layout.ps1    (none)
```

---

## 6. AC-3 and the `&` hazard

### 6.1 The A′ scans, re-implemented by me, over three trees

The developer's F-12 correction says the idiom scan was **red** pre-change (16 hits). I confirmed it
from **two** independent pre-change trees:

```
### A: HEAD cb0ed57 (v0.44.0, predates hook-spec entirely) ###
  upgrade-project.sh          idiom=4  subst=0      upgrade-project.ps1         idiom=4  subst=0
  migrate-scripts-layout.sh   idiom=4  subst=0      migrate-scripts-layout.ps1  idiom=4  subst=0
  == HEAD v0.44.0 TOTALS: idiom=16  subst=0
### B: S0 working-tree capture (post-T-15 / pre-T-16) ###
  == S0 pre-change TOTALS: idiom=16  subst=0
### C: LIVE post-change tree ###
  upgrade-project.sh          idiom=0  subst=0      upgrade-project.ps1         idiom=0  subst=0
  migrate-scripts-layout.sh   idiom=0  subst=0      migrate-scripts-layout.ps1  idiom=0  subst=0
  == POST-CHANGE TOTALS: idiom=0  subst=0
### DRIFT 1: an ABSENT flow file must score 'missing' and FAIL the row ###
  absent file scores: 'missing'  -> row passes? 0  (expected: 'missing' / 0)
```

**16/0 → 0/0 confirmed. DRIFT 1 confirmed** — an absent flow file scores `missing`, not `0`, and
fails its row, so deleting a flow cannot make both of its scan rows vacuously green.

**Anti-vacuity by mutating the artifact, not the assertion.** Two non-comment lines appended to
`.harness/scripts/upgrade-project.sh`
(`: "${CLAUDE_PROJECT_DIR:-}"` and `qa_av="${PATH//x/y}"`), then `test-init.sh`:

```
  FAIL  [T-16][A'] upgrade-project.sh carries no hook-command byte-form idiom outside comments (got 1)
  PASS  [T-16][A'] upgrade-project.ps1 ... (got 0)
  PASS  [T-16][A'] migrate-scripts-layout.sh ... (got 0)
  PASS  [T-16][A'] migrate-scripts-layout.ps1 ... (got 0)
  FAIL  [T-16][A'] upgrade-project.sh uses no pattern-substitution operator (& / patsub hazard) (got 1)
  PASS  ... (the other three, got 0)
EXIT=1
```

Exactly 2 rows red, exactly the mutated file, the other 6 unaffected — the rows are load-bearing and
independently evaluated. File restored byte-exact (`57253542…a1b7`). **AC-3: PASS.**

### 6.2 B-5 — the `&` hazard is real, and the shipped helper is what stops it

```
bash version: 5.2.21(1)-release
patsub_replacement default: patsub_replacement	on

spec answer (contains a literal &):
  pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"

SHIPPED helper str_replace_all:
  {"command": "pwsh -NoProfile -Command \"...CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\""}

NAIVE ${var//needle/repl} (what the helper exists to avoid):
  {"command": "pwsh -NoProfile -Command \"...CLAUDE_PROJECT_DIR; {{GUARD_COMMAND}} pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\""}

VERDICT: DIFFER — the naive form corrupts. helper is load-bearing.
```

Note *what* the corruption would be: the `&` expands to the matched text, i.e. the naive form would
write **`{{GUARD_COMMAND}}` back into the middle of the guard command** — an unresolved token inside
a live security hook. Measured, not argued. And the standing A′ substitution scan shows **zero**
pattern-substitution operators on any non-comment line of any of the four flows, so no spec-derived
value can reach a pattern-substitution replacement on any path. **B-5: PASS.**

### 6.3 The circularity repair (OQ-1) is non-tautological — proven by mutating the spec

Mutated `hook-spec.sh`'s two unix shapes and ran `test-init.sh`:

```
  PASS  [T-16][oracle] ANTI-VACUITY: the frozen EXP_* fixture (guard-rm, windows) is a non-empty string naming guard-rm.ps1
  PASS  [T-16][A] command harness-sync windows is byte-equal to the FROZEN test-init fixture (independent of every flow)
  ... (3 more windows rows PASS)
  FAIL  [T-16][A] command harness-sync   unix is byte-equal to the FROZEN test-init fixture (independent of every flow)
  FAIL  [T-16][A] command guard-rm       unix ...
  FAIL  [T-16][A] command ambient-prompt unix ...
  FAIL  [T-16][A] command ambient-reset  unix ...
EXIT=1
```

Exactly the 4 mutated cells go red. The counterfactual is measured too: under the *same* mutation
all four flows emitted the mutated value (§4), so a Group A that still compared the spec against a
flow would have been **green-and-vacuous**. `hook-spec.sh` restored byte-exact (`a5f1734c…c753`).

---

## 7. AC-6 — the three prose consumers

```
$ grep -rn 'Stop hook in `?\.claude/settings\.json' AI-GUIDE.md docs/ .harness/rules/ skills/ CONTEXT.md README.md
  (0 hits in any of the three named consumers)
```

Read back:

- `AI-GUIDE.md:110` — "A Stop hook runs `harness-sync` automatically at session end; a project
  generated by `/harness-init` ships that hook in its committed `.claude/settings.json`, while this
  repo keeps its own wiring machine-local — `/harness-status` §0 "Effective hook source" reports
  which file a given project actually loads it from."
- `.harness/rules/60-tool-handoff.md:71-77` — same durable statement, same generated-vs-this-repo
  clause, same deferral to the authority.
- `docs/getting-started.md:180-184` — same.

None names a fixed file as the location of *this* repo's hooks; each defers to `/harness-status` §0.
Caps re-measured **after** the edits: `AI-GUIDE.md` **113**/200, `60-tool-handoff.md` **131**/200,
`75-safety-hook.md` **200**/200 untouched. `I.1`/`I.2` green, 0 WARN. **AC-6: PASS.**

One observation, not a defect of this task — see **D-3** in §11.

---

## 8. AC-11 — no scope leakage, re-measured

I re-ran the S0 frozen table myself rather than trusting the record:

```
$ sha256sum -c t16-captures/S0-frozen-sha.txt | grep -v ': OK$'
.harness/scripts/baseline.json: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

**19 of 20** frozen paths are byte-identical to S0, including all four `guard-rm` copies,
`evals/guard-rm-cases.md`, both `test-guard-rm` twins, `75-safety-hook.md`,
`docs/proposals/frontier-gaps-2026-07.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, both
`sync-self` twins, both `test-harness-upgrade` twins, `README.md`, `.claude/settings.json`,
`.claude/settings.local.json`, and `skills/harness-init/templates/common/.claude/settings.json.tmpl`
— that last one is also my proof that M-C, M-D and both F-3 fixtures were reverted byte-exactly.

The single mismatch is `baseline.json`, ledger row 25's deliberate `_qa_note_t16` append; its
correct frozen assertion is *every numeric key*, and all 18 are reproduced above. **AC-11: PASS.**

Note for the record: `guard-rm.{sh,ps1}` and `evals/guard-rm-cases.md` **do** differ from
`HEAD (cb0ed57)` — that is T-17's delivered-but-uncommitted work in the dirty set B-11 warns about,
not T-16's. Against **S0** (the correct baseline) they are byte-identical.

---

## 9. AC-10 — PowerShell honesty (carried forward, unchanged)

`command -v pwsh` fails on this host. **No `.ps1` in this change set has been executed, parsed or
verified by me, in any round, by any agent.** Everything I state about a `.ps1` is *reading*.

The numbered operator list (items **12-16**, two security-marked pairs) is present verbatim in
`baseline.json:_qa_note_t16` with exact commands, and no PS pin moved
(`test_init_ps_assertions` 316 · `test_real_project_ps_assertions` 90 ·
`test_supervisor_ps_assertions` 49 · `test_verify_i6_ps_assertions` 58 ·
`test_harness_upgrade_ps_assertions` 89 · `test_language_ps_assertions` 39). Both README PS badges
stay frozen and move only together with the operator's run.

**BINDING, carried to `07_DELIVERY.md`**: operator items **14(a)**, **15(a)** and **16** must be
re-run **against the round-2 bytes** — `verify_all.ps1` and `test-init.ps1` were re-touched after
the operator list was written, so any round-1 `ParseFile` result for either is stale. Item 14(a)
now additionally covers the `-cnotmatch` pair that is the whole point of MINOR #3, and 15(a) the
five `-cmatch`/`-cnotmatch` flips in the A′ scans.

**AC-10: PASS** (honesty preserved; the PS surface remains unverified by construction, and is
stated as such).

---

## 10. Specific claims the gate and the reviewer could only inspect — re-measured

| Claim | Source | My measurement | Verdict |
|---|---|---|---|
| `test-init.sh` → `PASS: 355` from the artifact, not arithmetic | gate §8.1 | ran it under a python3-exit-127 shim; `=== Result === PASS: 355 FAIL: 0` | **confirmed** |
| `verify_all` 32/0/0, count read from the run | gate §8.2 | 32 result lines counted from the run; `G.4` cross-checks live count | **confirmed** |
| M-C → exactly two tokens, whole gate 31/0/1 | gate §8.3 | pasted in §2.1 | **confirmed** |
| pre-change `[F.2]` PASS on M-C from an S0 capture, both admissibility directions | gate §8.4 | pasted in §2.2, plus a **content-level** admissibility proof of my own | **confirmed, strengthened** |
| `test-harness-upgrade` 89/89, `test-real-project` 90/90 | gate §8.5 | 89/0 and 90/0, each at its own summary line | **confirmed** |
| A′ pre-change 16 idiom / 0 subst, post-change 0/0 | gate §8.6 / F-12 | 16/0 from **two** independent pre-change trees; 0/0 live | **confirmed** |
| `hook-spec.{sh,ps1}` do not exist at HEAD | gate §8.8 | `git cat-file -e cb0ed57:…` → *"exists on disk, but not in 'cb0ed57'"* | **confirmed** |
| the grep/awk `[ \t]` transcript at `04:385-403` | review §8.1 | re-run below | **confirmed** |
| the eight round-2 re-verification runs at `04:428-437` | review §8.2 | all eight re-run | **confirmed** |
| `verify_all.ps1:315` exposure is diagnostic-token-only, not verdict | `04` open issue 5 | bash half measured below; PS half by reading | **confirmed** |
| the F-3 totality case's *evidence* | `04:202-204`, `02 §7.1` | see **D-1** | **NOT confirmed — record defect** |
| the ugrep "login shell" attribution | `04:421-423` | see **D-2** | **substance confirmed, mechanism misattributed** |

### 10.1 The `[ \t]`-inside-a-bracket-expression measurement, re-run

```
$ /usr/bin/grep --version | head -1
grep (GNU grep) 3.11

$ cat -A t2.txt
"command"^I: X$          <- a REAL tab
"command"t: X$
"command"\: X$
"command": X$

$ /usr/bin/grep -nE '"command"[ \t]*:' t2.txt      # the "cheap fix"
2:"command"t: X$
3:"command"\: X$
4:"command": X$                                    # <- MISSES the real tab, MATCHES garbage

$ /usr/bin/grep -nE '"command"[[:space:]]*:' t2.txt   # as shipped
1:"command"^I: X$
4:"command": X$

$ awk '/^"command"[ \t]*:/ {print NR": "$0}' t2.txt   # awk, for contrast
1: "command"^I: X$                                    # <- awk DOES read \t as a tab
4: "command": X$
```

**Reproduced exactly.** GNU grep 3.11 reads `[ \t]` as `{space, backslash, t}`; gawk 5.2.1 reads it
as a tab. The developer's decline of the "cheap harmonization" is **correct**, and the code
reviewer's adjudication of it is **correct**: the cheap fix would ship a matcher that both
false-FAILs a tab-indented `"command"\t:` and false-PASSes `"command"t:`. `verify_all.sh:359` keeps
`[[:space:]]`; the in-gate comment at `:354-358` (verified: exactly those lines, guarding `:359` —
NIT R2-2's correction is right) records why.

The **compounding trap**, reproduced on the same fixture:

```
### the agent shell's bare `grep`  (= ugrep 7.5.0) ###
1:"command"^I: X$
4:"command": X$                       <- ENDORSES the broken form
### /usr/bin/grep (GNU 3.11) — what a `bash script.sh` run actually gets ###
2:"command"t: X$   3:"command"\: X$   4:"command": X$
```

### 10.2 Open issue 5 (`verify_all.ps1:315`) — the reviewer's reasoning checked on the bash side

Citations re-verified against the live files: `verify_all.sh:324` is `grep -q '{{GUARD_COMMAND}}'`
(case-sensitive); `verify_all.ps1:315` is `-notmatch` (case-**in**sensitive); `:338` and `:341` are
`-cnotmatch`; the key-form matcher is `[ \t]` in **both** shells (`sh:333` inside `awk`, `ps1:321`),
so R-1 really is closed there and survives only on the `"command"` key (`sh:359` vs `ps1:341`).

Lowercase-placeholder mutation, bash gate:

```
BASH GATE EXIT=2
[D.2] Placeholders documented ... FAIL
      skills/harness-init/templates/common/.claude/settings.json.tmpl: {{guard_command}}
[F.2] ... FAIL
       ...settings.json.tmpl:no_GUARD_COMMAND_placeholder ...settings.json.tmpl:guard_command_not_in_PreToolUse
  PASS: 30   WARN: 0   FAIL: 2
```

Bash emits **2** `F.2` tokens. By reading `verify_all.ps1`, the PS twin's `:315` would find the
lowercase form (case-insensitive) and so *not* emit `no_GUARD_COMMAND_placeholder`, while `:338`'s
`-cnotmatch` still emits `guard_command_not_in_PreToolUse` — **1** token, same FAIL verdict. And
`D.2` catches it in both shells regardless. **The residual is accurately stated**: a
diagnostic-token-set divergence, not a verdict divergence. Bash-verifiable one-character fix; no
operator PS item needed. (The PS half is *read*, not run — pwsh absent.)

---

## 11. Defects found

### D-1 · **MINOR (record)** · the F-3 totality evidence does not discriminate; the claim "round 1's rule would have FAILed here" is false

- **Where**: `04_DEVELOPMENT.md:202-204` ("*with the whole `"PreToolUse"` block moved to be the
  **last** key inside `hooks`… Round 1's `== IND` rule would have FAILed here*") and
  `02_SOLUTION_DESIGN.md:604-607` + §7.1 table row 3 ("*That matches **zero** lines whenever
  `"PreToolUse"` is the last key inside `hooks`: every following line dedents to 2 (`  }`) then 0
  (`}`), never back to 4*" · terminator predicted to be "the two-space `}` line").
- **Reproducer**: `python3 apply-reorder.py` (the developer's own fixture script, byte-for-byte the
  same transformation I built independently), then run both rules over the result:
  ```
  === SHIPPED rule (<= IND) ===   start=68 IND=4 term=78 (window 68..77)   -> PASS
  === ROUND-1 rule (== IND) ===   start=68 IND=4 term=78  unterminated=no  -> ALSO PASS
  ```
  The block-form `PreToolUse` array closes with its own `    ]` at width **exactly 4**, which the
  `== IND` rule finds. The design's premise ("every following line dedents to 2 then 0, never back
  to 4") overlooks the array's own closing bracket. `term` is line 78 (`    ]`), **not** the
  two-space `}` line.
- **Impact**: **none on shipped behaviour.** The shipped `≤ IND` rule *is* strictly more total —
  I constructed the case that proves it (inline `PreToolUse` as last key inside `hooks`: shipped
  rule PASSes, `== IND` rule FAILs with `PreToolUse_block_unterminated`; real gate 32/0/0 — §2.3).
  What is defective is the **record**: a claim reported as a measured run, in a repo whose own rule
  is "a tally/claim is cross-checked against the artifact that produced it", where the artifact
  does not support it.
- **Route**: PM → solution-architect (`02 §7.1`) and developer (`04:202-204`), record edit only.
  Recommended replacement evidence: the inline-last-key fixture, pasted from §2.3.

### D-2 · **NIT (record)** · the ugrep compounding trap is misattributed to a login shell

- **Where**: `04_DEVELOPMENT.md:421-423` and the third insight bullet at `04:325-327`: "*this host's
  **interactive** `grep` is ugrep 7.5.0 … so the same experiment run by hand in a **login shell**
  prints the opposite result*".
- **Reproducer**: `bash -lic 'type grep; grep --version | head -1'` →
  `grep is aliased to 'grep --color=auto'` / `grep (GNU grep) 3.11`. A real login shell gets **GNU
  grep**, not ugrep. `command -v ugrep` / `command -v ug` → **not on PATH**. The ugrep is reached
  through a `grep()` **shell function installed into the agent's tool shell by Claude Code**, which
  execs `claude -G` under `ARGV0=ugrep`.
- **Impact**: the *substance* is confirmed and is if anything worse than stated — it is the **agent's
  own by-hand `grep`** that endorses the broken form, which is precisely the shell an agent uses to
  "check" a matcher. Only the mechanism attribution is wrong. The insight, as written, would send a
  future reader to look in `~/.bashrc` and find nothing.
- **Route**: PM → developer / insight-harvester. One clause: s/interactive `grep` … login shell/the
  agent tool shell's `grep` function (Claude Code), while a login shell and `bash script.sh` both
  get GNU grep 3.11/.

### D-3 · **NIT (record, pre-existing, out of T-16's scope)** · a fourth stale "Stop hook in `.claude/settings.json`" sentence survives

- **Where**: `.harness/scripts/install-hooks.sh:8` and `.ps1:8`, plus both `templates/common/`
  copies (4 files): "*Claude Code keeps them fresh via a **Stop hook in .claude/settings.json**…*".
- **Reproducer**: `git show cb0ed57:.harness/scripts/install-hooks.sh | sed -n '1,12p'` → present at
  `:5`. **Pre-existing, not T-16's**, and not in `01 §2`'s nine-item inventory.
- **Impact**: **AC-6 is unaffected** — it names exactly three sentences and all three are fixed.
  The `install-hooks` sentence is materially different: it ships into a **generated project**, where
  the claim is true, and its own next clause is about Claude-Code-specificity, not location.
  Recorded because it is the same class as round-2 MINOR #1 and a future "one-place" edit should
  sweep it.
- **Route**: PM → backlog, next task. Not blocking.

### D-4 · **NIT (record)** · no flow validates a spec answer beyond non-emptiness

- **Reproducer** (`qa-t16/b7.sh`): a stub spec whose `command` answer carries a trailing CR, or two
  lines:
  ```
  ### B7-a: spec answer terminated with a CARRIAGE RETURN ###
    exit=0   raw CR in file: 1   valid JSON: NO -> Invalid control character at: line 8 column 38
      '            "command": "sh -c CORRUPT\r"'
  ### B7-b: spec answer is MULTI-LINE ###
    exit=0   valid JSON: NO -> Invalid control character at: line 8 column 30
      '            "command": "line1'
  ```
  The flow writes the value verbatim, produces invalid JSON, and exits **0** with no diagnostic.
- **Why this is not a T-16 defect**: (a) B-2 only requires rejecting *empty*; (b) the corruption
  channel is **unreachable through the supported distribution path** — `.gitattributes` forces
  `*.sh text eol=lf`, so a CRLF `hook-spec.sh` cannot arrive from a checkout, and the adapter only
  ever forms `.sh` candidates and runs them with `bash`, so B-7's cross-shell `$( )` CR path really
  is unreachable rather than merely handled; (c) it is **standing-detected at source** — a
  control-character-bearing spec answer fails `[T-16][A]`'s byte-equality rows against the frozen
  `EXP_*` fixture (proved in §6.3, where a 15-byte spec change reddened exactly 4 rows); (d) it is
  not a regression — pre-change the same corruption class lived in the flow file's own literal.
- **Route**: record-only, carry as a note beside RES-1. No action this row.

### No BLOCKER, no CRITICAL, no MAJOR.

Nothing I ran produced a `verify_all` FAIL, a WARN, a moved pin, a permissive guard command, a
guardless residue, an empty `"command"` value, or a byte divergence in any of the 8 `(tool, OS)`
cells for any of the four flows.

---

## Adversarial tests (REQUIRED — one per acceptance criterion)

Each row states a falsification hypothesis written **before** the run, an independent reproducer
(none of these is copied from `04_DEVELOPMENT.md`'s test code), and the outcome with tool output.
Verdict is based on whether the implementation *survived*, not on whether the developer's tests pass.

| AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, QA-authored unless noted) | Outcome |
|---|---|---|---|
| **AC-1** | a flow keeps a private fast path, so a spec mutation reaches 3 of 4 flows but not the 4th | `M-SPEC` in 4 spec files + 4 QA fixtures + the `SKILL.md:198` command run verbatim | **Survived** — all 4 flows emit the mutated value, `QAMUT16 hits=0` in every flow file (§4) |
| **AC-2** | at least one of the 8 cells drifted — most likely `guard-rm windows`, the only shape with a bare `&` and no `exit 0` | oracle = `cb0ed57:test-real-project.sh:48-57` (**predates `hook-spec`**, so non-circular); flows run on a QA fixture, values re-encoded to the JSON-string body | **Survived** — `diff` → 0 differing lines, 8/8, **both** script flows; prose cells 8/8 (§3) |
| **AC-3** | the idiom scan is a tautology (green because it always was) | re-implemented both scans over HEAD, S0 and live; then **mutated the artifact** and re-ran `test-init` | **Survived** — 16→0 (red-before, green-after) and mutation reddens exactly 2 rows (§6.1) |
| **AC-4 / B-3** | some branch writes a permissive guard: spec absent / unreadable / exit 2 / exit 0+empty / **partial (only `guard-rm` unanswered)** / hostos undeterminable; and the residue is blessed on re-run | 7 probes × (run 1 + re-run), each auditing exit code, empty `"command"`, `\|\| exit 0`, trailing `exit 0`, `.bak` churn | **Survived** — 0 permissive, 0 empty, exit 4 every time, run 2 never quieter than run 1 (§5.3) |
| **AC-4 runtime** | the emitted command silently allows when the guard is gone | executed the value the flow **wrote**, guard present/absent/dir-removed/empty `CLAUDE_PROJECT_DIR` | **Survived** — 0 / 2 / **127** / 127 / 127 / 2 (§5.2) |
| **AC-5** | the degradation branch leaves a plan/report residue that run 2 blesses at exit 0 | `upgrade-project` and `migrate-scripts-layout`, spec-free, twice each | **Survived** — identical output, identical settings, no `.bak` churn (§5.3) |
| **AC-6** | a fourth copy of the false sentence survives somewhere | repo-wide grep beyond the three named files | **Partially survived** — 3/3 fixed; a **4th, pre-existing, out-of-scope** instance found in `install-hooks.*` → **D-3 (NIT)** |
| **AC-7 fwd** | M-C produces 3+ tokens, or 1, because the containment audit mis-predicted which evidence the mutation destroys | applied M-C, ran the real gate, read the token string | **Survived** — exactly 2, and exactly the 2 predicted; 31/0/1 (§2.1) |
| **AC-7 anti-vac** | the "pre-change" artifact is really the post-change one, making the direction vacuous | S0 capture + 4 admissibility proofs incl. a **content-level** one | **Survived** — `[F.2] PASS` pre-change on the same mutant (§2.2) |
| **AC-7 totality** | the `≤ IND` rule has a hole: a valid template it FAILs, or a broken one it PASSes | built the **inline-last-key** fixture and the **sibling-donation** fixture `M-D`; ran the real gate on each and simulated both round-1 rules | **Survived** — inline-last-key PASSes (round-1 rule FAILs it); `M-D` FAILs with 2 tokens (round-1 inclusive window would have PASSed it). **And it falsified the record's evidence → D-1** (§2.3, §2.4) |
| **AC-8** | a driver dies mid-run and the tally is read from a truncated log | ran all 8, both python3 conditions, checked each for **its own** terminator (`=== Result ===` / `=== Summary ===` / `=== test-guard-rm summary ===`) | **Survived** — all reached their summary line; every bash pin reproduced (§1.2) |
| **AC-9** | the check count is 31 or 33 and `baseline.json` is being read instead of the run | counted result lines from the run; caught my own bad regex (31) before trusting it | **Survived** — 32 from the run, `G.4` concurs (§1.1) |
| **AC-10** | some `.ps1` claim slipped in as "verified" | `command -v pwsh`; re-read the operator list | **Survived** — pwsh absent, nothing claimed; 14(a)/15(a)/16 carried as binding re-runs (§9) |
| **AC-11** | a frozen file moved under cover of the dirty tree | `sha256sum -c` over the 20-entry S0 table + git-status delta | **Survived** — 19/20 identical, the 20th is the documented `baseline.json` append with all 18 numerics frozen (§8) |
| **B-5** | a spec-derived value reaches a `${var//…}` replacement on some path and the `&` corrupts it | naive-vs-helper contrast on the real spec answer + the standing substitution scan over all 4 flows | **Survived** — helper immune, naive form demonstrably writes `{{GUARD_COMMAND}}` into the guard command; 0 substitution operators anywhere (§6.2) |
| **NFR-1** | the cache dies in a subshell, so the spec is spawned 12-13 times | counting shim wrapped round the spec, full flow run | **Survived** — exactly **9**, each `(tool,OS)` once + `hostos` once (§5.4) |
| **OQ-1** | the re-anchored oracle is green-and-vacuous (spec compared with itself) | mutated the **spec** and ran `test-init` | **Survived** — 4 Group A rows go red; and the same mutation makes every flow emit it, proving the *old* oracle would have been vacuous (§6.3) |
| **B-7** | a corrupt spec answer is written verbatim into a live hook | stub spec emitting a CR-terminated and a multi-line answer | **FAILED as a raw probe** — invalid JSON at exit 0. Downgraded to **D-4 (NIT)** after reachability + standing-detection analysis (§11) |

---

## 13. Stability

Full suite run **3 times** end to end, after all mutations were reverted:

```
### stability round 1 ###
=== Summary ===   PASS: 32   WARN: 0   FAIL: 0   <- verify_all
=== Result ===   PASS: 391   FAIL: 0   <- test-init(py3)
=== Result ===   PASS: 355   FAIL: 0   <- test-init(no-py3)
=== test-guard-rm summary ===   PASS: 87   FAIL: 0   <- test-guard-rm
=== Summary ===   PASS: 89   FAIL: 0   <- test-harness-upgrade
### stability round 2 ###   (identical)
### stability round 3 ###   (identical)
```

**No flakes observed.** ✅ Counts identical across all three rounds, in both python3 conditions.

---

## 14. Test suite / baseline changes

**No test was added, and `baseline.json` was not modified.** Rationale, stated rather than assumed:

- Every acceptance criterion already has at least one **standing** assertion after T-16
  (`[T-16][oracle]` ×1, `[T-16][A]` ×8, `[T-16][A']` ×8 in each shell, plus `F.2`'s three new
  containment tokens in the gate), and I proved each of those load-bearing by mutating the
  **artifact** rather than the assertion (§2.3, §2.4, §6.1, §6.3).
- Adding a bash-only assertion would move `test_init_bash_no_python3_assertions` **without** its PS
  twin. `pwsh` is absent here, so `test_init_ps_assertions` (316) could not be reconciled from a
  run, which is exactly what OQ-8(b) forbids and what NFR-3 (cross-shell parity) exists to prevent.
  A one-sided pin move would be a worse outcome than the coverage it buys.
- The one genuine standing-coverage gap is **RES-1**, already recorded as a residual. Closing it
  needs a *paired* bash+PS assertion and therefore an operator PS run — see §15.

Baseline only goes up; it did not need to go up, and it did not go down. All 18 numeric keys are
byte-frozen and reproduced from real runs (§1.2).

---

## 15. Residuals confirmed accurate and travelling to `07_DELIVERY.md`

- **RES-1** — *"standing end-to-end coverage of a flow-emitted byte string is one `(tool, OS, flow)`
  cell (`test-harness-upgrade.sh:421` vs `t20_pick`); `migrate-scripts-layout` has none."*
  **Accurate, verified.** `test-harness-upgrade.sh:421` is the only full-byte-string equality
  assertion on a flow-emitted value. `test-init.sh:637-645` does assert on
  `migrate-scripts-layout`-emitted values, but by **substring/property**
  (`grep -qF 'pwsh -NoProfile -File .harness/scripts/harness-sync.ps1'`, `grep -qF 'CLAUDE_PROJECT_DIR'`,
  "no `exit 0` on the guard line") — not byte equality to a frozen fixture. My §3.2 measurement
  covered all 8 cells for both flows **once**; the standing 8-cell assertion is still open.
  **Recommended closure**: a paired bash+PS row-set, landed together with an operator PS run.
- **R-1** — *the `"command"`-key matcher divergence*. **Accurate, and correctly located.** Verified
  against the live files: key form is `[ \t]` in **both** shells (`verify_all.sh:333` inside `awk`,
  `verify_all.ps1:321`), so R-1 is closed there; it survives only on `verify_all.sh:359`
  (`'"command"[[:space:]]*:'`, `grep -qE`) vs `verify_all.ps1:341` (`'"command"[ \t]*:'`,
  `-cnotmatch`). Observing it needs a form-feed / vertical tab / CR between `"command"` and its
  colon in a JSON template the gate itself owns. **The decision to leave it open is correct and I
  re-measured the reason** (§10.1). Deliberately open.
- **Open issue 5** — *`verify_all.ps1:315` presence check is case-insensitive against a
  case-sensitive bash twin at `verify_all.sh:324`; pre-existing at `cb0ed57`; post-MINOR-#3 the
  exposure is a diagnostic-token divergence only, not a verdict divergence, because `:338`
  backstops it.* **Accurate.** Bash half measured (2 tokens, FAIL); PS half read (1 token, FAIL);
  `D.2` catches it independently in both shells. Bash-verifiable one-character fix, no operator PS
  item needed (§10.2).
- **Operator PowerShell items 14(a), 15(a) and 16 must be re-run against the round-2 bytes** —
  carried forward, binding (§9).
- **New, from this stage**: **D-1** (record defect, architect + developer), **D-2** (insight wording),
  **D-3** (pre-existing 4th prose sentence, backlog), **D-4** (record-only note beside RES-1).

---

## 16. verify_all result summary

- Total checks: **32 → 32** (unchanged; read from the run, corroborated by `G.4`)
- PASS: **32** · WARN: **0** · FAIL: **0** · exit **0**
- Total bash assertions across the pinned drivers: **391 / 355 / 90 / 89 / 58 / 46 / 45 / 39 / 87**,
  all pins reproduced, **0 failures**
- New tests added: **0** — see §14 for the reasoned decision
- Baseline updated: **no** (not needed; not lowered; all 18 numerics frozen and re-measured)

---

## Verdict

> **PASS WITH DEFECTS** — 0 BLOCKER, 0 CRITICAL, 0 MAJOR, **1 MINOR (record) + 3 NIT**.
> **APPROVED FOR DELIVERY**, conditional only on record edits, none of which touch code.

The implementation survived every falsification attempt I could construct. The two things I set out
hardest to break — the fail-closed asymmetry and byte-identity — both held under conditions the
pipeline did not test: a **partial** spec answer where six of eight cells resolve and `guard-rm`
alone does not (six rewired, guard left brittle, exit 4, no permissive value, no residue blessed on
re-run), and byte-comparison against an oracle taken from **`cb0ed57`, which predates `hook-spec`
entirely** and is therefore non-circular in a way the developer's own spec-adjacent comparison could
not be. The containment fix is genuinely load-bearing in both directions and survived two mutants
nobody upstream ran. The `&` hazard is not theoretical: I measured the naive form writing
`{{GUARD_COMMAND}}` into the middle of a live guard command, and the shipped helper stopping it.

The one MINOR is a **record** defect and it is exactly the class this repo pins against: the F-3
totality claim was reported as a measured run, and the artifact it names does not support it — the
`PreToolUse` array's own closing bracket sits at width exactly `IND`, so round 1's rule terminates
there too. The shipped `≤ IND` rule *is* strictly more total; I built the fixture that proves it
(inline `PreToolUse` as the last key inside `hooks`) and it is pasted above, ready to replace the
non-discriminating one in `02 §7.1` and `04:202-204`.

Nothing PowerShell was executed or parsed, by me or by any agent in any round. Operator items
**12-16** remain the only evidence path for nine `.ps1` files, and **14(a), 15(a) and 16 must be
re-run against the round-2 bytes**. That, RES-1, R-1 and open issue 5 are the obligations that must
reach `07_DELIVERY.md`.

QA left no footprint: `git status --porcelain` is byte-identical to its state at QA start, 19 of 20
S0-frozen paths hash unchanged (the 20th being `baseline.json`'s documented append with all 18
numerics frozen), `75-safety-hook.md` is at 200/200, and the stray sweep is empty.
