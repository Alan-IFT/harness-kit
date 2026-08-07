# 04 — Development Record · T-17 `guard-cmd-chain`

- Mode: **full** · Stage 4 (developer) · Security task · single-developer (no partitions)
- Inputs: `01_REQUIREMENT_ANALYSIS.md` (round 2), `02_SOLUTION_DESIGN.md` (round 2),
  `03_GATE_REVIEW.md` **ROUND 2** (C-1 … C-15 authoritative)
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker is emitted.
- Every tally below is **quoted from the run that produced it**. Nothing is derived arithmetically.

---

## Summary

The destructive-command `PreToolUse` guard now evaluates the (unchanged) nine-verb rule at
**every command position in a command line**, not just the first token of each top-level pipe
segment. This lands as a new single-pass, quote/here-document/comment-aware position scanner
with an explicit nesting stack, unioned with the byte-unchanged pre-change decomposition **plus
the input string itself at every recursion depth**; plus a widened prefix strip (assignments,
`sudo`, reserved words), argv-carrier reachability, `bash -c` nested interpreters, and an
audited command-text override. The regression suite went 17 → **81** rows in three-way lockstep
(bash driver ↔ PS driver ↔ `evals/guard-rm-cases.md`), and the 55-line AC-4 differential shows
**zero BLOCK→ALLOW flips**. `verify_all` PASS 32 / WARN 0 / FAIL 0, check count held at 32.

---

## Files changed — against the design §11 lockstep ledger (all 14 surfaces)

| # | Surface | What changed |
|---|---|---|
| 1 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` | **The whole change, edited here first** (unwired staging area): `split_positions()` scanner + helpers, `_has_scanner_trigger()`, `classify_command_string()` union, `_skip_prefix()`, `_walk_paths()`, `_is_destructive_verb()` / `_is_carrier_verb()` / `_is_pwsh_verb()` / `_is_shell_verb()`, carrier scan, `bash`/`sh`/`dash`/`zsh`/`ksh` branch, pwsh call-site change, step-2b command-text override, `str_replace_all` + `\n`/`\r`/`\t` unescape in the no-python3 JSON fallback, new BLOCK message wording |
| 2 | `.harness/scripts/guard-rm.sh` | byte-mirrored dest — **written only by `sync-self`**, never hand-edited |
| 3 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1` | symmetric change: `Split-CommandPositions` (try/catch → `$null`), `Get-Slice` length-guarded lookahead, `Test-ScannerTrigger`, `Get-OffendingFromCommandString` union, `Get-PrefixIndex`, `Get-OffendingFromWalk`, `Test-DestructiveVerb` / `Test-CarrierVerb` / `Test-PwshVerb` / `Test-ShellVerb`, carrier scan, shell-interpreter branch, step-2b override |
| 4 | `.harness/scripts/guard-rm.ps1` | byte-mirrored dest — written only by `sync-self` |
| 5 | `.harness/scripts/test-guard-rm.sh` | `[guard-path]` argument; **stride-4 flat-tuple rows replacing the `id\|cmd\|override\|expected` delimiter**; `tg_replace_all` + `\n`/`\r`/`\t` escaping in the no-python3 encoder; 17 → 81 rows; the mandatory quoting rule written into the file |
| 6 | `.harness/scripts/test-guard-rm.ps1` | `-Guard` parameter; same 81 ids; same quoting rule (single-quoted rows, `` `n ``/`` `r `` only for separator rows) |
| 7 | `evals/guard-rm-cases.md` | 17 → 81 rows in five new sections, plus driver notes on the guard-path argument, the row-quoting safety rule and the missing-summary-line detector |
| 8 | `.harness/rules/75-safety-hook.md` | trigger description **replaced** by the coverage claim; chaining removed from out-of-scope; new "Residual limitations" and "Accepted over-blocks" sections; failure-mode rows rewritten; the never-true 50 ms claim replaced by measured figures. **136 → 197 lines** (cap 200) |
| 9 | `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` | same edits minus the two dogfood-note blocks. **122 → 187 lines** |
| 10 | `.harness/scripts/baseline.json` | `test_guard_rm_bash_assertions: 81` (transcribed) + `_qa_note_t17`. **No PS key** — `pwsh` is absent on this host, so no real tally exists |
| 11 | `CONTEXT.md` | **untouched** (C-8) — `Command position` is already at `CONTEXT.md:100-103` |
| 12 | `CHANGELOG.md` + version stamps | one `[0.46.0]` entry; `0.45.0 → 0.46.0` in `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:17`, `README.md:5`, `README.zh-CN.md:5` (G.3 needs all four) |
| 13 | `docs/dev-map.md` | guard line now says "judges EVERY command position since v0.46"; driver line names the optional guard-path argument |
| 14 | `docs/tasks.md`, `docs/batches/default/BATCH_PLAN.md` | **not touched — PM-owned** |

**Verified NOT changed** (re-confirmed by `sync-self --check` returning "In sync." plus green runs):
`verify_all.{sh,ps1}` (F.2 stays presence + wiring), `test-init.{sh,ps1}` (391/0 captured below —
assertion counts did not move), `test-real-project.{sh,ps1}` (90/0), `hook-spec.{sh,ps1}`,
`.claude/settings.local.json`, every `SKILL.md`, `AI-GUIDE.md:33`. Both README **guard**
descriptions are untouched; only the version badge moved.
`docs/proposals/frontier-gaps-2026-07.md` was not opened, edited or cited.

---

## Edit sequence actually followed (design §9.1 — the live-guard hazard)

The guard is the live fail-closed `PreToolUse` hook with no `|| exit 0`, so the repo copy was
changed **exactly once**, to an already-green file:

0. Baseline captured (below).
1. `test-guard-rm.sh` re-encoded (stride-4, `[guard-path]`, newline escaping) with the **17
   original rows only** → re-run against the untouched live guard: `PASS: 17 / FAIL: 0`.
2. `test-guard-rm.ps1` re-encoded (`-Guard`).
3. Full change written to the **template** copy → `bash -n` exit 0; grep confirmed no
   `mapfile` / `declare -A` / `${v,,}` (bash-3.2 safety).
4. 64 new rows added to both drivers + the fixture → driven **against the template** via
   `[guard-path]`: `PASS: 81 / FAIL: 0`. The same driver against the repo copy: `PASS: 49 /
   FAIL: 32` (the anti-revert evidence).
5. `sync-self.sh --check` → drift list named **only** `.harness/scripts/guard-rm.sh`; then one
   `sync-self.sh` run; then the driver against the **default** path → `PASS: 81 / FAIL: 0`.
6-7. Mutations and the AC-4 differential (below).
8. PS twin written to the template → `sync-self --check` named only `guard-rm.ps1` → promoted →
   `sync-self --check` → **"In sync."**
9. Docs, `baseline.json`, `CHANGELOG.md`, version stamps → `verify_all` 32/0/0.

The live guard was never left unrunnable; no Write-tool repair was needed.

---

## verify_all result

**Baseline**, captured immediately before any edit:

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**After changes** (final run):

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**Delta: 0 new failures, 0 new warnings, check count held at 32** (AC-8). No `verify_all` check
was added or removed. `[I.2] Rule fragments ≤200 lines each ... PASS` with the rule doc at
**197** lines — the gate's correction that `verify_all.sh:823-825` exits 1 on `warns > 0` was
treated as binding, so the doc was compressed rather than allowed to run over.

### Driver tallies — each quoted from its own run

| Driver | Run | Output |
|---|---|---|
| `test-guard-rm.sh` (live guard, **pre-change**, baseline) | `bash .harness/scripts/test-guard-rm.sh` | `PASS: 17` / `FAIL: 0` |
| `test-guard-rm.sh` (re-encoded driver, 17 rows, guard untouched — step 1) | same | `PASS: 17` / `FAIL: 0` |
| `test-guard-rm.sh` (81 rows, **template** guard — step 4) | `bash … test-guard-rm.sh skills/…/guard-rm.sh` | `PASS: 81` / `FAIL: 0` |
| `test-guard-rm.sh` (81 rows, **pre-change** guard from `git show HEAD:`) | `bash … test-guard-rm.sh <scratch>/prechange-guard.sh` | `PASS: 49` / `FAIL: 32` |
| `test-guard-rm.sh` (81 rows, **promoted live** guard — step 5, final) | `bash .harness/scripts/test-guard-rm.sh` | `PASS: 81` / `FAIL: 0` |
| `test-init.sh` (collateral check) | `bash .harness/scripts/test-init.sh` | `=== Result ===` `PASS: 391` / `FAIL: 0` |
| `test-real-project.sh` (collateral check) | `bash .harness/scripts/test-real-project.sh` | `=== Result ===` `PASS: 90` / `FAIL: 0` |

Every run above ended with its summary line — checked explicitly, because a driver that
truncates mid-suite prints **no** summary and **no** FAIL (T-13's failure mode).

---

## Evidence per acceptance criterion

`OUT` = `/etc/harness-guard-probe`. No deletion was performed anywhere; the guard is fed JSON on
stdin exactly as the driver does. All exit codes are captured from real runs.

### AC-1 — bypass matrix, exit 2 for every row · **PASS**

All 18 rows (a–r) plus a CRLF variant `f2` are driver rows and all print `-> BLOCK` in the
`PASS: 81` run. Against the pre-change guard, rows **b c e f f2 g h i j k l m n o p q r** all
print `got ALLOW, expected BLOCK` — 17 of the 18 were live bypasses (row `a` is the control that
already blocked). Row `i` echoes back as `echo $(rm -rf /etc/harness-guard-probe)`, i.e.
unexpanded — the C-5 execution hazard did not fire.

### AC-2 — existing behaviour preserved · **PASS**

All 17 original fixture rows keep their verdicts in the final `PASS: 81` run, including row 8
(`pwsh -c "Remove-Item -Recurse C:\Windows"` → BLOCK), rows 9/10/17 (the `find` branch), and row
11 (env override → ALLOW). The env-override audit line was captured from stderr:

```
== A) env-var override (fixture row 11 / AC-2) ==
harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.
   exit=0
```

The depth-2 bound still holds — see AC-5 row F2.

### AC-3 — legitimate-form corpus, exit 0 except L10 · **PASS**

L1–L9 and L11–L14 all print `-> ALLOW`; **L10 prints `-> BLOCK`, which the driver records as a
PASS**, exactly as the round-2 criterion requires. L9 (the here-document write) and L11 (the
guard's own self-test invocation) are the load-bearing rows and both ALLOW, so the suite can run
and the file-writing toolchain is not crippled. L14's audit line, captured live:

```
== B) command-text override prefix (AC-3 L14 / OQ-1a) ==
harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.
   exit=0
== C) pre-change behaviour of the SAME command-text form (E-1: silent, no audit line) ==
   stderr=[]
   exit=0
```

That is E-1 confirmed and fixed: the documented override text used to reach exit 0 with **no**
audit line at all; it is now recognized and audited, at the same exit code.

### AC-4 — differential run, the proof obligation for IS-2 · **PASS**

Corpus: **55 distinct command lines**, every one harvested from the enumerated sources only —
S1 (`README.md` 4, `docs/getting-started.md` 6), S2 (`_archived/*/04_DEVELOPMENT.md` 29,
`_archived/*/04_IMPLEMENTATION.md` 3, `_archived/*/06_TEST_REPORT.md` 5), S3
(`hook-spec.{sh}` byte-forms, 8). **S4 yielded 0**, exactly as the gate predicted
(`AI-GUIDE.md:72-86` lists paths in prose, not invocations). Lines were de-duplicated on the
command text. No transcript and no `git log` was used.

```
=== AC-4 differential ===
  corpus lines : 55
  identical    : 51
  ALLOW->BLOCK : 4
  BLOCK->ALLOW : 0   (MUST be 0)
  UNKNOWN      : 0   (MUST be 0)
```

**Zero BLOCK→ALLOW flips at any depth. IS-2 holds on captured evidence.** Full per-line table
(source artifact · pre verdict · post verdict · command):

| # | Source artifact | pre | post | Command |
|---|---|---|---|---|
| 1 | README.md | ALLOW | ALLOW | `git clone https://github.com/Alan-IFT/harness-kit ~/harness-kit` |
| 2 | README.md | ALLOW | ALLOW | `mkdir my-app && cd my-app` |
| 3 | README.md | ALLOW | ALLOW | `claude` |
| 4 | README.md | ALLOW | ALLOW | `.harness/rules/*.md     ← edit this (single source of truth, modular fragments)` |
| 5 | docs/getting-started.md | ALLOW | ALLOW | `cd /path/to/empty/folder` |
| 6 | docs/getting-started.md | ALLOW | ALLOW | `cd /path/to/existing/project` |
| 7 | docs/getting-started.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/verify_all.ps1` |
| 8 | docs/getting-started.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/harness-sync.ps1     # syncs .harness/agents/ → .claude/agents/` |
| 9 | docs/getting-started.md | ALLOW | ALLOW | `mkdir -p .harness/skills/<name>` |
| 10 | docs/getting-started.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/harness-sync.ps1     # syncs .harness/skills/ → .claude/skills/` |
| 11 | _archived/ambient-stream/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1` |
| 12 | _archived/ambient-stream/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/harness-sync.ps1` |
| 13 | _archived/ambient-stream/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/guard-rm.ps1` |
| 14 | _archived/ambient-stream/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/ambient-prompt.sh` |
| 15 | _archived/ambient-stream/06_TEST_REPORT.md | ALLOW | ALLOW | `bash .harness/scripts/verify_all.sh` |
| 16 | _archived/decision-mode-skill/06_TEST_REPORT.md | ALLOW | ALLOW | `bash .harness/scripts/test-init.sh` |
| 17 | _archived/entropy-watch-harness/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-supervisor.sh` |
| 18 | _archived/entropy-watch-harness/06_TEST_REPORT.md | ALLOW | ALLOW | `pwsh .harness/scripts/verify_all.ps1` |
| 19 | _archived/harness-grill/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-real-project.sh` |
| 20 | _archived/harness-grill/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/test-init.ps1` |
| 21 | _archived/harness-grill/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/test-real-project.ps1` |
| 22 | _archived/hook-truth-spec/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -File .harness/scripts/install-hooks.ps1` |
| 23 | _archived/hook-truth-status/04_IMPLEMENTATION.md | ALLOW | ALLOW | `bash .harness/scripts/harness-sync.sh` |
| 24 | _archived/hook-truth-status/04_IMPLEMENTATION.md | ALLOW | ALLOW | `bash .harness/scripts/guard-rm.sh` |
| 25 | _archived/hook-truth-status/06_TEST_REPORT.md | **BLOCK** | **BLOCK** | `bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'` (odd `'` — pre-existing parse failure, identical both ways) |
| 26 | _archived/i6-bash-inproc-scan/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-verify-i6.sh` |
| 27 | _archived/rejected-decisions-memory/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh .harness/scripts/test-init.ps1` |
| 28 | _archived/resilient-hooks/04_IMPLEMENTATION.md | ALLOW | ALLOW | `bash .harness/scripts/sync-self.sh` |
| 29 | _archived/scripts-relocation/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/migrate-scripts-layout.ps1` |
| 30 | _archived/scripts-relocation/04_DEVELOPMENT.md | **BLOCK** | **BLOCK** | `bash "$repo_root/.harness/scripts/sync-self.sh` (odd `"` — pre-existing, identical both ways) |
| 31 | _archived/scripts-relocation/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/verify_all.ps1` |
| 32 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/sync-self.sh --check          # In sync.` |
| 33 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/verify_all.sh                 # 32/0/0` |
| 34 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/verify_all.ps1   # 32/0/0` |
| 35 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-harness-upgrade.sh       # 76/0` |
| 36 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-harness-upgrade.ps1  # 77/0` |
| 37 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-init.sh                  # 270/0` |
| 38 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-init.ps1    # 308/0` |
| 39 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-real-project.sh          # 90/0` |
| 40 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-real-project.ps1  # 90/0` |
| 41 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-supervisor.sh            # 45/0` |
| 42 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-supervisor.ps1    # 49/0` |
| 43 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-verify-i6.sh             # 58/0` |
| 44 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-verify-i6.ps1     # 58/0` |
| 45 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `bash .harness/scripts/test-language.sh              # 39/0` |
| 46 | _archived/sync-hook-dangling-ref/04_DEVELOPMENT.md | ALLOW | ALLOW | `pwsh -NoProfile -File .harness/scripts/test-language.ps1      # 39/0` |
| 47 | _archived/sync-hook-dangling-ref/06_TEST_REPORT.md | ALLOW | ALLOW | `bash .harness/scripts/harness-sync.sh && bash .harness/scripts/extra-helper.sh` |
| 48 | hook-spec.sh (guard-rm/unix) | ALLOW | ALLOW | `sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'` — **the live hook byte-form; it does not self-block** |
| 49 | hook-spec.sh (guard-rm/windows) | ALLOW | **BLOCK** | `pwsh -NoProfile -Command \"Set-Location … ; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"` |
| 50 | hook-spec.sh (harness-sync/unix) | ALLOW | ALLOW | `sh -c 'cd \"$CLAUDE_PROJECT_DIR\" … exec bash .harness/scripts/harness-sync.sh \|\| exit 0'` |
| 51 | hook-spec.sh (harness-sync/windows) | ALLOW | **BLOCK** | `pwsh -NoProfile -Command \"Set-Location … if (Test-Path …) { … }; exit 0\"` |
| 52 | hook-spec.sh (ambient-prompt/unix) | ALLOW | ALLOW | `sh -c 'cd \"$CLAUDE_PROJECT_DIR\" … exec bash .harness/scripts/ambient-prompt.sh \|\| exit 0'` |
| 53 | hook-spec.sh (ambient-prompt/windows) | ALLOW | **BLOCK** | `pwsh -NoProfile -Command \"Set-Location … ambient-prompt.ps1 … \"` |
| 54 | hook-spec.sh (ambient-reset/unix) | ALLOW | ALLOW | `sh -c 'cd \"$CLAUDE_PROJECT_DIR\" … exec bash .harness/scripts/ambient-reset.sh \|\| exit 0'` |
| 55 | hook-spec.sh (ambient-reset/windows) | ALLOW | **BLOCK** | `pwsh -NoProfile -Command \"Set-Location … ambient-reset.ps1 … \"` |

**The four ALLOW→BLOCK flips are one class, isolated by probe, and recorded (OQ-6a).** All four
are the JSON-escaped **Windows** hook byte-forms, in which a backslash-escaped quote pair
**spans** a top-level separator. The scanner correctly treats `\"` as an escape and splits at the
separator; the retained, byte-unchanged `tokenize()` then sees odd quote parity in the resulting
position and fails closed. Isolated:

```
--- probe A: same form with REAL quotes (no backslash escape) ---   exit=0
--- probe B: minimal repro, escaped quote spanning a separator ---  exit=2   (`echo \"a ; b\"`)
--- probe C: same, no separator between the escaped quotes ---      exit=0   (`echo \"a b\"`)
--- probe D: the LIVE unix hook byte-form ---                       exit=0
```

Disposition: **recorded, not fixed** — the `\"` form is a settings-file JSON byte-form, not
something typed into the Bash tool (probe A shows the typed form is fine), the direction is
over-block, and it is precisely design §10.2 item 11's pre-declared class. It is now pinned by
driver rows **W1/W2/W3/W4** (repro + both boundaries + the live unix byte-form) and written into
`75-safety-hook.md`'s accepted-over-blocks table.

### AC-5 — fail-closed · **PASS**

Driver rows `F1` (unbalanced quote in a chained line), `F2` (nesting past depth 2), `F3`
(unterminated here-document) all `-> BLOCK`. The deliberate fail-open, captured live:

```
== D) no .git ancestor -> WARN + exit 0 (B-6, deliberate fail-open) ==
harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.
   exit=0
```

No input in the AC-1 or fail-closed sets yields exit 0. B-1 boundaries also captured:
`empty stdin exit=0`, `no command field exit=0`.

### AC-6 — verb set unchanged · **PASS**

```
diff <pre-change> <shipped> on destructive_verbs_ci  ->  bash verb list IDENTICAL
diff <pre-change> <shipped> on $destructiveVerbs     ->  ps verb list IDENTICAL
```

Driver rows `V1` (`mv OUT .`), `V2` (`cp x OUT`), `V3` (`echo hi > OUT`) all `-> ALLOW` — still
deliberately unguarded. `_is_destructive_verb` / `Test-DestructiveVerb` are mechanical twins of
the declaration lists (9 members each), with the equal-membership ledger written as a comment
above both, and both declarations are kept as the diff target.

### AC-7 — symmetry and lockstep · **PASS**

```
bash .harness/scripts/sync-self.sh --check
In sync.
```

Id lockstep is three-way and machine-checked: bash driver **81**, fixture **81**, PS driver
**81**, `comm -3` empty in both directions for both pairings. Both rule-doc copies carry the same
coverage claim, residual list and accepted-over-block table (hand-maintained — `.harness/rules/`
is not in sync-self's mirror set).

### AC-8 — gate green, count frozen · **PASS** — 32 checks, PASS 32 / WARN 0 / FAIL 0 (above).

### AC-9 — documentation truth · **PASS**

```
grep -n 'first token after optional|Verbs (first token|50 ms wall-clock|Performance over 50 ms'
  .harness/rules/75-safety-hook.md  <tmpl>
  none — AC-9 satisfied in both copies
```

The only surviving occurrence of the phrase is the negation inside the new coverage claim
("**not** just the first token of each top-level pipe segment"). Residual limitations (IS-1 rows
15-17 plus the C-11 and C-13 residuals) are named, and the failure-mode table covers the new
BLOCK causes.

### AC-10 — driver anti-revert (mutation proof) · **PASS**

Four mutations of a **scratch copy** of the promoted guard, each `bash -n`-clean, each driven
through `[guard-path]`:

| Mutation | Red rows | Which |
|---|---|---|
| scanner disabled (`if _has_scanner_trigger "$s"` → `if false`) | **18** | b c e f f2 g i q F2 F3 C10a C10b C12cr C12tee P5 O1 Q2 W1 |
| carrier scan disabled (`if _is_carrier_verb "$verb"` → `if false`) | **7** | j k l m n o O2 |
| C-1 invariant deleted (`plist+=("$s")` → no-op) | **1** | C14 |
| prefix strip disabled (`_skip_prefix …` → `_PREFIX_IDX=0`) | **8** | p P1 P2 P3 P4 P5 O1 O3 |

The C-1 mutation additionally reproduces the exact F-2 monotonicity regression the invariant
exists to prevent, proven directly rather than by a driver row:

```
--- F-2 counterexample vs the C-1-invariant mutant (expect ALLOW = the regression) ---
exit=0
--- same vs the shipped guard (expect BLOCK) ---
exit=2
```

(`pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"`.) Every new mechanism is
load-bearing; no new assertion is a presence check.

### AC-11 — live-guard continuity · **PASS**

The driver was run and its tally captured after every edit (table above). The repo copy was valid
at every intermediate state, and every tally in this document is quoted from the run that printed
it. No tally was derived arithmetically.

### AC-12 — PowerShell debt recorded · **PASS** (recorded, not executed — see below).

---

## NFR results

- **NFR-1 / C-15 latency — PARTIALLY MET, measured and reported honestly.** 20 invocations each,
  same host, pre-change → post-change:

  | Command | chars | pre | post | delta |
  |---|---|---|---|---|
  | (a) typical ~110-char chain | 110 | 49 ms | **46 ms** | **−3 ms** |
  | (d) typical redirecting `echo hi > ./f` (C-15) | 13 | 39 ms | **33 ms** | **−6 ms** |
  | (b) 8192-char `&&` worst case | 8194 | 1487 ms | **2251 ms** | **+764 ms** |
  | (c) 8192-char here-document payload | 15519 | 1561 ms | **1659 ms** | **+98 ms** |

  Typical commands — including C-15's redirecting case, which now takes the scanner path —
  got **faster**, because `_is_destructive_verb`'s glob list removed ~20 `printf | tr` forks per
  segment. The **8192-char worst case misses the +20 ms budget by ~744 ms**. Root cause, profiled
  rather than guessed: bash substring indexing `${s:$i:1}` is O(i), so *every* character pass over
  the command string is O(n²) — the pre-change guard already pays this twice (1487 ms before any
  of my code runs) and the scanner is a third such pass. A hoisted catch-all `case` for
  non-special bytes was added and re-measured (it is what brought (a) from +? to −3 ms), but the
  remaining cost is inherent to a bash character lexer, which is the gate-approved shape. Per
  NFR-1's own instruction the rule document was corrected **to the measured truth** rather than
  the reverse: the never-true "under 50 ms" claim and its failure-mode row are gone, replaced by
  this table. Flagged under "Open issues" for the reviewer.
- **NFR-2 no new dependency — MET.** No `realpath`, no `git`, no new interpreter; the
  python3-optional JSON path and its heuristic fallback are intact (the fallback gained a
  patsub-safe `\n`/`\r`/`\t` unescape, which is what makes AC-1 row `f` real on a no-python3 host).
- **NFR-3 live-guard safety — MET.** See the edit sequence; the repo copy changed once per shell.
- **NFR-4 cross-shell parity — PARTIAL by construction.** `pwsh` is **not installed on this host**
  (`command -v pwsh` fails), so the `.ps1` twin could not even be parse-checked. See AC-12.
- **NFR-5 security posture — MET.** No configuration, environment variable or committed file can
  weaken the guard; no feature flag was added; the per-call override is still the single visible
  escape hatch, and it is now *audited* where it used to be silent.

---

## Gate conditions C-1 … C-15 — per-condition disposition

| # | Condition | Disposition | Evidence |
|---|---|---|---|
| **C-1** | `P` contains `s` at every depth, including 0; not depth-conditional; AC-4 is IS-2's proof | **DONE** | `classify_command_string`: `plist+=("$s")` unconditional, with the fail-open warning in a comment. Mutation proof + AC-4's 0 BLOCK→ALLOW |
| **C-2** | Frames save **and restore** quote state; inner buffer of `` $( ``/`` ` ``/`<(` starts at `NORMAL` | **DONE** | `_sp_push_cmd` saves buffer + `st`; `_sp_pop_cmd` restores both. Gate counterexample 1 `echo "$(true && rm -rf /etc/x)"` → **exit 2** |
| **C-3** | `find`: carrier scan first, **no `return`**, then the byte-unchanged `-delete` branch | **DONE** | Carrier block has no `return`; `find` branch follows. Row `o` BLOCK, fixtures 9/17 BLOCK, fixture 10 ALLOW, L6 ALLOW — all captured |
| **C-4** | Override evaluated **once**, on the top-level `cmd`, before the `.git/` walk | **DONE** | Step 2b sits between step 2 and step 3; nothing in `classify_*` mentions it. Rows **O1/O2/O3** all BLOCK |
| **C-5** | Driver rows single-quoted (or `$'…'`) when containing `$`, `` ` `` or `$(`, both shells; confirm echo-back | **DONE** | Rule written into both drivers. Echo-back verified: row `i` → `echo $(rm -rf /etc/harness-guard-probe)`, `C11a` → `echo $((1 << 3))`, `C11b` → `echo "${HOME}"`, `W4` → `…$CLAUDE_PROJECT_DIR…` — all literal, none expanded |
| **C-6** | `sync-self --check` before promoting, only `guard-rm` drifted; re-run driver after, quote the tally | **DONE** | Run 1 drift list: `.harness/scripts/guard-rm.sh` only. Run 2: `.harness/scripts/guard-rm.ps1` only. Final `--check`: **"In sync."** Post-promotion driver: `PASS: 81 / FAIL: 0` |
| **C-7** | PS: length-guard every lookahead; wrap the scanner in `try/catch` → parse-fail path | **DONE** | Every multi-char lookahead goes through `Get-Slice` (which mirrors bash's short read instead of throwing); the whole `Split-CommandPositions` body is `try { … } catch { return $null }`, and the caller converts `$null` to the one existing `,@('__PARSE_FAIL__')` channel |
| **C-8** | Do **not** re-add `Command position` to `CONTEXT.md` | **DONE** | `CONTEXT.md` not opened for writing; unchanged |
| **C-9** | Rule doc ≤ 200 lines; residuals must carry §10.2 items 9 & 11, all four §10.3 classes, plus C-11 and C-13 residuals | **DONE** | **197** lines (`.tmpl` 187). `[I.2] … PASS`. Residual list items 4 (C-11's `${x:-$(cmd)}`), 5 (C-13's `a[0]=1`), 7 (override whole-line scope = item 9); over-block table carries the union-residue class (item 11), the C-1 pipe class, depth > 2, and unterminated structure |
| **C-10** | Row 4 × NORMAL **pushes** BQ; driver rows for backtick and `<(` | **DONE** | Row-4 branch: `top == BQ → pop/restore; else _sp_push_cmd BQ`. Rows **C10a** (`` echo `rm -rf OUT` ``) and **C10b** (`cat <(rm -rf OUT)`) → BLOCK; both red under the scanner mutation |
| **C-11** | PARAM/ARITH pinned to **verbatim-until-closer**; rows `echo $((1 << 3))` and `echo "${HOME}"`; `sq_ansi` comment | **DONE** | A dedicated verbatim block handles PARAM/ARITH/VPAREN/VBRACE ahead of all other rows, recognizing only the closer, nested `${`/`$((`/`(`/`{`, and `\`+next. Rows **C11a/C11b** → ALLOW. The `sq_ansi` comment is in both shells. `${x:-$(cmd)}` residual recorded in the rule doc |
| **C-12** | Prove the fast-path trigger test **per character** | **DONE, both ways** | Implemented as twelve separate `[[ ]]` tests (never one bracket expression), **and** probed per character. The probe first asserts its own copy is byte-identical with the shipped function: `OK  probe body is byte-identical with …_has_scanner_trigger`, then 12 PASS + 4 negative controls, `FAIL: 0`. Load-bearing coverage also exists end-to-end for `; & ( ) { } `` ` `` LF CR`; `<`/`>`/`\` are provably redundant members (they never flush and never push on their own) and are kept for safety |
| **C-13** | Strip an optional trailing `+` from the assignment name; PS `^[A-Za-z_][A-Za-z0-9_]*\+?=`; record `a[0]=1` | **DONE** | `name="${name%+}"` in bash, the exact regex in PS. Row **P2** (`A+=1 rm -rf OUT`) → BLOCK (red pre-change and under the prefix mutation). `a[0]=1` recorded as residual 5 |
| **C-14** | Test-pin the C-1 over-block `rm -rf ./build \| tee /tmp/x.log` → BLOCK | **DONE** | Row **C14** in all three artifacts; it is the *only* row the C-1 mutation turns red, which is exactly the anti-revert property asked for |
| **C-15** | NFR-1 measurement set must include a typical **redirecting** command | **DONE** | Case (d) `echo hi > ./f`: 39 → **33 ms**. Included in the rule doc's measured table |

---

## Design drift

**`DESIGN DRIFT` 1 — here-document terminated by end-of-input is accepted, not a parse failure.**
Design §3.1 "End of input (total)" says `HDBODY` → parse failure unconditionally. As written that
would BLOCK every `cat > f <<'EOF' … EOF` whose final line is the terminator with **no trailing
newline** — the ordinary shape of an agent file-write, and exactly the seizure R1 warns about
(AC-3 L9 is load-bearing). Implemented instead: at end of input in `HDBODY`, compare the pending
line against the queue front (with `<<-` tab-stripping) and accept it as a terminator if it
matches; anything else is still a parse failure. Direction check: pre-change such a line ALLOWs,
so this keeps ALLOW→ALLOW — **no BLOCK→ALLOW flip**, IS-2 unaffected. A genuinely unterminated
here-document still BLOCKs (row **F3**, captured exit 2, AC-5).

**`DESIGN DRIFT` 2 — `_skip_prefix` takes its tokens by value, not by dynamic scope.**
Design §3.3 does not specify the calling convention. It is implemented as
`_skip_prefix "${tokens[@]}"` writing `_PREFIX_IDX`, and `_walk_paths <start> "${tokens[@]}"`
likewise, rather than reading the caller's `tokens` through bash dynamic scoping. Reason: an
undefined-variable read under `set -uo pipefail` exits **1**, which Claude Code treats as
non-blocking — i.e. that failure mode is silently **fail-open**. By-value passing removes the
possibility. No behavioural difference; fork-free either way (§9.3 respected).

**`DESIGN DRIFT` 3 (performance addition) — a hoisted catch-all in the scanner loop.**
Not in the §3.1 table: before row 1, a single `case "$ch"` sends every byte that no dispatch row
keys on straight to append. The pattern list is exactly the 17 characters rows 1-23 react to, and
nothing in the scanner's state depends on an ordinary byte beyond appending it (`prev` and
`sq_ansi` are read from `$s` directly, never accumulated). Semantics identical; re-verified by
re-running the full 81-row suite, the trigger probe and the 55-line differential after adding it.

**`DESIGN DRIFT` 4 (correction of a design claim, no code consequence) — the F-9 ANSI-C fix is
unobservable at the top level, and its stated evidence row is wrong.** Design §10.3's closing
paragraph fixes `sq_ansi` "rather than recording it" and offers as evidence "a driver row
`echo $'it\'s fine'` → **ALLOW**". Measured: that command has **three** apostrophes, so the
byte-unchanged `tokenize()` sees odd parity and it **BLOCKs pre-change too** — captured, row
**Q1** passes identically against the pre-change guard. Every `$'…\'…'` string necessarily has odd
apostrophe parity, so `sq_ansi` can never change a top-level verdict while the pre-change pass is
retained; it is an instance of §10.2 item 11's class, exactly like L10. The flag is implemented as
designed (it is correct, cheap, and would matter if `tokenize` ever gained backslash awareness),
but row Q1's expected verdict is **BLOCK**, and the rule doc records ANSI-C strings under accepted
over-blocks rather than claiming they are fixed.

**Not drift, but worth the reviewer's eye — one over-block that follows from §3.5 as written.**
`bash <script> "<a command string as an argument>"` now BLOCKs when the argument itself parses as
a destructive command with an outside path, because §3.5 deliberately judges *every* non-option
token of a shell interpreter (that breadth is what catches `bash --rcfile foo -c "rm -rf OUT"`).
This bit during development — a probe invocation of the form
`bash gprobe.sh "<guard> pwsh -c \"Remove-Item … C:\log\""` was blocked by the live guard, and the
documented command-text override was used to complete it. Recorded in the accepted-over-blocks
table; not fixed, because narrowing it would reintroduce a false negative.

---

## PowerShell surface added to the standing operator list

**`pwsh` is not installed on this host** (`command -v pwsh` → not found), so the `.ps1` twin was
neither run nor parse-checked. It ships **green-by-symmetry only**. This task adds the following
to the standing T-13 operator PowerShell list; **no frozen item is reconciled** (the eight
enumerated T-13 items and the deliberately unreconciled `test_init_ps_assertions` / README badges
are untouched).

1. `[Parser]::ParseFile` over **`.harness/scripts/guard-rm.ps1`**, its template twin, and
   **`.harness/scripts/test-guard-rm.ps1`**. PowerShell parses the whole file before executing,
   so a syntax error in a never-taken branch is fatal to the entire guard.
2. Run `pwsh -File .harness/scripts/test-guard-rm.ps1` (81 rows) and, separately, with
   `-Guard <template-path>`. Expect `PASS: 81 / FAIL: 0`; then pin
   `test_guard_rm_ps_assertions` in `baseline.json` **from that run**. The key is deliberately
   absent today — do not invent one.
3. **Highest-probability defect (R11), and it fails OPEN:** the scanner is lookahead-heavy. Every
   lookahead goes through `Get-Slice`, which is length-guarded, and `Split-CommandPositions` is
   wrapped in `try/catch → return $null`. Confirm no exception escapes: an escaping terminating
   error under `$ErrorActionPreference = 'Stop'` exits **1**, which Claude Code treats as
   non-blocking, silently disarming the Windows guard. A green symmetry review cannot detect this.
4. Confirm the **override prefix is case-SENSITIVE**: `StartsWith(…, [StringComparison]::Ordinal)`
   is deliberate; PS `-eq`/`-match` are case-insensitive and would accept
   `harness_allow_outside_rm=1`, a widening. Probe `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf C:\x`
   (exit 0 + audit line) and `harness_allow_outside_rm=1 rm -rf C:\x` (expect exit 2).
5. Confirm the new driver's row quoting did not pre-expand: PS hashtable values are single-quoted
   for every row containing `$`, a backtick or `$(` — a double-quoted `@{ cmd = "echo $(rm …)" }`
   would invoke the subexpression at array-definition time and really delete the path. Check that
   row `i`, `C10a`, `C11a`, `C11b` and `W4` echo back **literally** in their PASS lines.
6. Confirm `$BackTick = [string][char]0x60` and the `$specialScanChars` array parse and behave
   (they replace backtick-quoted literals precisely to avoid a whole-file parse hazard), and that
   no new variable collides with an automatic (`$stIn`, `$sqAnsi`, `$nestKind`, `$nestTop`,
   `$hdQueue`, `$prevCh`, `$posList` were chosen for this reason).
7. Re-run `pwsh -File .harness/scripts/verify_all.ps1` (expect 32/0/0) and
   `pwsh -File .harness/scripts/sync-self.ps1 --check` (expect "In sync.").

---

## Open issues for review

1. **NFR-1's +20 ms budget is missed on the 8192-character worst case (+764 ms).** Typical
   commands improved. The cause is pre-existing O(n²) bash string indexing, which the pre-change
   guard already paid twice (1487 ms) before any new code ran. I did not attempt a rewrite: the
   character-lexer shape is what the gate approved, and NFR-1's own remedy ("correct the rule
   document to the measured truth") has been applied. If the operator wants the worst case back
   under control, that is a follow-up pool row (candidate: cap the scanner at a length threshold —
   but note that any such cap must fail **closed**, i.e. BLOCK rather than skip, or it becomes a
   trivially exploitable bypass).
2. **Four AC-4 corpus lines flip ALLOW→BLOCK** (the escaped-quote-spanning-a-separator class).
   Recorded rather than fixed, per OQ-6a, and pinned by rows W1-W4. If the reviewer disagrees with
   that judgement, the alternative is to make the scanner drop a backslash-escaped quote from the
   emitted position — which is a real change to §3.1 row 1 and would need its own re-verification.
3. **`bash <script> "<command string>"` over-blocks** (see the drift section). Realistic enough
   that I hit it myself; narrowing it would reintroduce a false negative, so it is recorded.
4. **The PowerShell twin is entirely unverified.** `pwsh` is absent from this host — not merely
   denied. Item 3 of the operator list is a *security* item, not polish.
5. The `find_predicates` / `$findPredicates` arrays remain declared-but-unused in both shells
   (pre-existing, unchanged — deliberately left alone as historical documentation of the D-1/D-2
   fix).

---

## Dev-map updates

No new files or modules were created, so no new tree entries were added. Two existing lines were
made accurate rather than narrower than the truth:

```
│       ├── guard-rm.{ps1,sh}           ← Destructive-command PreToolUse guard (v0.15+); judges EVERY command position since v0.46
│       ├── test-guard-rm.{ps1,sh}      ← Driver for evals/guard-rm-cases.md (on-demand); takes an optional guard path ([guard-path] / -Guard) so a staged copy can be driven without touching the live hook
```

---

## Insight to surface

- A test driver for a **live** `PreToolUse` hook must be able to drive an *arbitrary* copy of the
  hook, or the change cannot be verified before it goes live: adding a one-argument guard path to
  `test-guard-rm.{sh,ps1}` is what let the whole 81-row suite, four deletion mutations and a
  55-line pre-vs-post differential run *against staged copies*, so the fail-closed repo copy was
  written exactly once, to an already-green file. · evidence: `.harness/scripts/test-guard-rm.sh:16`
  (`guard="${1:-$repo_root/.harness/scripts/guard-rm.sh}"`), design §9.1 steps 4-7
- A guard that widens *what it parses* while reusing an unchanged tokenizer inherits that
  tokenizer's blind spots **on the newly-created substrings**, which is a different and larger
  over-block surface than it had on whole lines: the new scanner correctly treats `\"` as an
  escape and splits at a separator between two of them, and `tokenize()` — which has no backslash
  awareness — then rejects the resulting position for odd quote parity. Four of this repo's own
  `hook-spec` byte-forms flipped ALLOW→BLOCK for exactly this reason, all in the *safe*
  direction. · evidence: AC-4 differential rows 49/51/53/55; probe B `echo \"a ; b\"` exit 2 vs
  probe C `echo \"a b\"` exit 0; driver rows W1-W3
- An unbound-variable read under `set -uo pipefail` exits **1**, and Claude Code treats non-2 as
  non-blocking — so in a fail-closed hook, a *runtime* bug fails **open** while a *syntax* bug
  fails closed. `bash -n` catches only the second. That asymmetry is why helper functions here
  take their arrays by value rather than through bash dynamic scoping. · evidence: gate R2.10 Q4;
  `guard-rm.sh` `_skip_prefix` / `_walk_paths` calling convention

---

## Verdict

**READY FOR REVIEW.**

`verify_all`: **PASS 32 / WARN 0 / FAIL 0** (baseline PASS 32 / WARN 0 / FAIL 0 — no delta, check
count held at 32). `test-guard-rm.sh`: **PASS 81 / FAIL 0** against the promoted guard, **PASS 49 /
FAIL 32** against the pre-change guard. AC-4 differential over 55 sourced corpus lines: **0
BLOCK→ALLOW flips**. All fifteen gate conditions C-1 … C-15 are DONE; four deviations are flagged
above as `DESIGN DRIFT` with their reasons and direction-of-risk analysis.

_(Everything above this line is the **round-1** record and is left byte-unchanged on purpose — it
is the record of what was captured then. Round-2 corrections to two round-1 statements are in
§"Corrections to round-1 prose" below, not by editing round 1.)_

---
---

# Development Record — ROUND 2 (rework after stage-5 code review)

- Input: `05_CODE_REVIEW.md` (**CHANGES REQUESTED** — 0 CRITICAL, 1 MAJOR, 5 MINOR, 5 NIT)
- Routed to me: **A-2, A-3, A-4, A-5, B-1** (MINOR) and the NITs **A-6, B-2, B-3, B-4**.
- **A-1 (the MAJOR) is NOT mine this round.** The PM waived NFR-1's +20 ms clause under Mode 2
  and routed the record to the requirement-analyst. I did **not** touch the scanner's hot loop,
  did **not** implement chunked indexing, and did **not** edit `01_REQUIREMENT_ANALYSIS.md`.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- Every tally below is **quoted from the run that produced it**; each run's summary line was
  checked for presence (a truncated driver prints no summary and no FAIL — T-13's failure mode).

## Per-finding disposition

| Finding | Sev | Disposition | Where |
|---|---|---|---|
| **A-2** `bash <<EOF … EOF` over-block unrecorded | MINOR | **RECORDED + pinned.** Clause added to the shell-interpreter row of the accepted-over-blocks table in **both** rule copies; new driver/fixture row `H1` (BLOCK) in all three artifacts | `75-safety-hook.md:100`, `.md.tmpl:86`, `test-guard-rm.{sh,ps1}`, `evals/guard-rm-cases.md` |
| **A-3** escaped `\>` / `\<` before `&` suppresses the separator | MINOR | **FIXED**, not disclosed. New scanner row 12 records where a redirection operator is actually appended; row 15 tests that index instead of the raw byte at `i-1`. Both shells. Pinned by `R1`/`R2` (BLOCK) with `R3` as the real-`>&` boundary (ALLOW) | `guard-rm.sh:334-336,545-565`, `guard-rm.ps1:294-297,532-553` |
| **A-4** residual 1 understates coverage (`command rm` **is** recognized) | MINOR | **FIXED** in both rule copies; `command rm` moved into the "are recognized" half with the reason (`command` is a carrier) | `75-safety-hook.md:67-68`, `.md.tmpl:53-54` |
| **A-5** `.tmpl` omits the PowerShell-symmetry disclosure | MINOR | **FIXED.** The sentence now ends residual 8 in the distributed template too | `.md.tmpl:70-73` |
| **B-1** dead code (`skip_next` / `$skipNext`, unused `find_predicates`) | MINOR | **BOTH, deliberately and identically in both shells:** the branch that provably cannot fire (`skip_next` / `$skipNext`) is **deleted**; the declaration that is genuinely documentation (`find_predicates` / `$findPredicates`) is **kept with the one-line "historical documentation of D-1/D-2" comment** the reviewer asked for | `guard-rm.sh:136-139,761-768`, `guard-rm.ps1:103-106,738-745` |
| **A-6** "17 of the 18" AC-1 rows | NIT | **CORRECTED** below (round 1 left byte-unchanged per instruction) | §Corrections |
| **B-2** row `W4` double-quoted while containing `$` | NIT | **FIXED.** `W4` is now single-quoted with the `'"'"'` idiom, like `L11`/`Q1`. Echo-back re-verified literal (`… -> ALLOW` line prints `$CLAUDE_PROJECT_DIR` unexpanded) | `test-guard-rm.sh:158-160` |
| **B-3** rule-doc line counts | NIT | **CORRECTED with the actual `wc -l` output** below — and the reviewer's 198/188 is itself off by one against `wc -l`, which is what gate I.2 uses | §Corrections |
| **B-4** carrier over-block class absent from the table | NIT | **ADDED** to both rule copies, with the live exit codes captured (`timeout 5 grep -r rm /etc` → 2, `timeout 5 grep -r rm ./docs` → 0) | `75-safety-hook.md:101`, `.md.tmpl:87` |

## The A-3 fix — what it is and why it fails closed

Design §3.1 row 15 says: on `&` at NORMAL, look at the **raw input byte** at `i-1`; if it is
`>` or `<`, the `&` is part of a redirection, so append instead of flushing. That is what
shipped, and it is a false negative whenever the preceding `>`/`<` was itself escaped — bash
reads `\>` as ordinary text, so the `&` **is** a separator:

```
--- captured against the PRE-round-2 (round-1) live guard ---
  exit=0  A-3 R1  escaped >& before separator   (want 2)      <- the false negative
  exit=0  A-3 R2  escaped <& before separator   (want 2)
  exit=0  A-3 R3  REAL >& dup redirect boundary (want 0)
  exit=0  A-3 R3b real 2>&1 in a chain          (want 0)
--- same probes against the promoted round-2 guard ---
  exit=2  A-3 R1  escaped >& before separator   (want 2)
  exit=2  A-3 R2  escaped <& before separator   (want 2)
  exit=0  A-3 R3  REAL >& dup redirect boundary (want 0)
  exit=0  A-3 R3b real 2>&1 in a chain          (want 0)
```

Implementation, one variable and one dispatch row per shell:

- **row 12** (new, NORMAL-only, ahead of the separator rows): `>` / `<` are appended **and the
  index is recorded** in `redir_i` / `$redirIdx`.
- **row 15** now tests `redir_i == i - 1` instead of `prev == ">" || prev == "<"`.

> **[SUPERSEDED IN ROUND 3 — code review CR2-2.]** The subset claim in the next paragraph is
> **false at exactly one point, `i == 0`**, and that point is the CR2-1 false negative. Round 1's
> append predicate was guarded by `(( i > 0 ))`; round 2's was not, so the append branch *grew*
> by one element instead of only shrinking. The corrected argument — which reaches the same
> conclusion for a different and sounder reason — is in §"CR2-2" of the round-3 record below.
> Do not reuse the paragraph as written.

**Monotonicity is by construction, not by measurement.** `redir_i` is assigned *only* where a
`>`/`<` is appended, so `{ redir_i == i-1 }` is a **subset** of `{ raw byte at i-1 ∈ {>,<} }`.
The append branch can therefore only shrink and the flush branch only grow ⇒ the position set
is a superset of the round-1 one ⇒ no BLOCK→ALLOW flip is reachable from this change, at any
depth (IS-2 holds without needing a new differential). A wrong index can only cause a flush,
i.e. more positions — fail-closed, exactly as the reviewer required.

Because of that, the 55-line AC-4 corpus was **not** re-harvested (its row set did not change).
I checked the weaker claim empirically too: no corpus source line contains a `&` immediately
preceded by `>` or `<` —

```
grep -n '[<>]&' README.md docs/getting-started.md .harness/scripts/hook-spec.{sh,ps1}
                _archived/*/04_DEVELOPMENT.md _archived/*/04_IMPLEMENTATION.md
                _archived/*/06_TEST_REPORT.md
  .harness/scripts/hook-spec.sh:60:    printf '%s\n' "hook-spec: $1" >&2     <- hook-spec's own
                                                                                die(), not an
                                                                                emitted hook form
```

> **[SUPERSEDED IN ROUND 3 — code review CR2-3.]** That output does **not** reproduce over its
> own stated file set: the same pattern returns **8** in-scope hits, not 1. The full re-run is
> quoted in §"CR2-3" of the round-3 record below. The conclusion is unaffected (the 7 additional
> hits are all prose mentions of `2>&1`, the provably *unchanged* branch), but the evidence as
> quoted was wrong.

— so no AC-4 line can be touched by rows 12/15, and `W4` (the live unix hook byte-form) is
still ALLOW in the 85-row run.

## Files changed in round 2

| Surface | What changed |
|---|---|
| `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` | **edited here first** (unwired staging area): scanner row 12 + `redir_i`, row-15 test, `skip_next` deleted, `find_predicates` ledger comment |
| `.harness/scripts/guard-rm.sh` | byte-mirrored dest — written by **one** `sync-self` run, never hand-edited |
| `skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1` | symmetric: `$redirIdx` + row 12, row-15 test, `$skipNext` deleted, `$findPredicates` ledger comment |
| `.harness/scripts/guard-rm.ps1` | byte-mirrored dest — same `sync-self` run |
| `.harness/scripts/test-guard-rm.sh` | `W4` re-quoted (B-2); rows `R1` `R2` `R3` `H1` added → **85 rows** |
| `.harness/scripts/test-guard-rm.ps1` | same four ids, same expectations |
| `evals/guard-rm-cases.md` | same four rows + lockstep header `81 ↔ 81` → **`85 ↔ 85`** |
| `.harness/rules/75-safety-hook.md` | residual 1 (A-4); over-block row extended with `bash <<EOF` (A-2); new carrier over-block row (B-4). **197 → 198 lines** by `wc -l` (cap 200) |
| `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` | same three edits **plus** the PowerShell-symmetry sentence (A-5). **187 → 189 lines** |
| `.harness/scripts/baseline.json` | `test_guard_rm_bash_assertions` 81 → **85** (transcribed from the `PASS: 85` line); `_qa_note_t17` updated with the round-2 decomposition and the new 50/35 pre-change tally |
| `CHANGELOG.md` | new bullet for the escaped-redirect fix; "17 → 81 rows" → "17 → 85 rows"; **corrected a stale figure**: the entry said the pre-change score was `46/31`, which was never captured — the round-1 run printed `49/32` and the round-2 run prints `50/35` |

**Untouched, deliberately:** `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`,
`03_GATE_REVIEW.md`, `05_CODE_REVIEW.md`, `CONTEXT.md`, `docs/proposals/frontier-gaps-2026-07.md`
(still never opened), `docs/tasks.md` / `BATCH_PLAN.md` (PM-owned), every frozen T-13 PowerShell
item, `verify_all.{sh,ps1}` (check count still 32), the verb set, version stamps (still 0.46.0).
Nothing was committed.

## Edit sequence actually followed (the live-hook hazard, unchanged from round 1)

1. Baseline `verify_all` (below) + probes against the **live round-1 guard** capturing the A-3
   false negative.
2. Change written to the **template** `.sh` → `bash -n` exit 0 → driven via `[guard-path]`:
   `PASS: 81 / FAIL: 0` on the then-current row set, probes flipped to exit 2.
3. Template `.ps1` given the symmetric change (unrunnable — `pwsh` absent).
4. Four rows added to both drivers + the fixture; three-way id lockstep machine-checked
   (`comm -3` empty both directions, both pairings, **85 / 85 / 85**); driven against the
   template: `PASS: 85 / FAIL: 0`.
5. `sync-self.sh --check` → drift list named **exactly** the guard pair and nothing else →
   **one** `sync-self.sh` run → `--check` → `In sync.` → driver against the **default** path.
6. Docs, `baseline.json`, `CHANGELOG.md` → `verify_all` → collateral suites.

The live guard was never left unrunnable; no Write-tool repair was needed.

## verify_all result

**Baseline** (captured before any round-2 edit):

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**After the round-2 changes:**

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**Delta: 0 new failures, 0 new warnings, check count held at 32.** No `verify_all` check was
added, removed or modified. `[I.2] Rule fragments ≤200 lines each ... PASS`.

### Driver and probe tallies — each quoted from its own run

| Run | Command | Output |
|---|---|---|
| 85 rows, **template** guard (step 4) | `bash … test-guard-rm.sh skills/…/guard-rm.sh` | `PASS: 85` / `FAIL: 0` |
| 85 rows, **promoted live** guard (final) | `bash .harness/scripts/test-guard-rm.sh` | `PASS: 85` / `FAIL: 0` |
| 85 rows, **pre-change** guard (`git show HEAD:`) | `bash … test-guard-rm.sh <scratch>/prechange-guard.sh` | `PASS: 50` / `FAIL: 35` |
| 85 rows, **round-1** guard (row 12/15 fix reverted in a scratch copy) | `bash … test-guard-rm.sh <scratch>/round1-guard.sh` | `PASS: 83` / `FAIL: 2` — red rows **exactly `R1 R2`** |
| `test-init.sh` (collateral) | `bash .harness/scripts/test-init.sh` | `=== Result ===` `PASS: 391` / `FAIL: 0` |
| `test-real-project.sh` (collateral) | `bash .harness/scripts/test-real-project.sh` | `=== Result ===` `PASS: 90` / `FAIL: 0` |

Red rows against the **pre-change** guard (35, transcribed from that run's failure list):
`b c e f f2 g h i j k l m n o p q r F2 F3 C10a C10b C12cr C12tee C14 P1 P2 P5 O1 O2 O3 Q2 W1
R1 R2 H1` — i.e. round 1's 32 plus the three new load-bearing rows; `R3` is green pre-change
(ALLOW→ALLOW), which is why PASS went 49 → 50 rather than 49 → 49.

### AC-10 anti-revert mutations, re-run over the enlarged row set

Each mutation is a `bash -n`-clean scratch copy of the **promoted** guard driven via
`[guard-path]`; tallies quoted from those runs:

| Mutation | Red rows | Which |
|---|---|---|
| scanner disabled (`if _has_scanner_trigger "$s"` → `if false`) | **21** (was 18) | b c e f f2 g i q F2 F3 C10a C10b C12cr C12tee P5 O1 Q2 W1 **R1 R2 H1** |
| carrier scan disabled (`if _is_carrier_verb "$verb"` → `if false`) | **7** | j k l m n o O2 |
| C-1 invariant deleted (`plist+=("$s")` → `:`) | **1** | C14 |
| prefix strip disabled (`_skip_prefix …` → `_PREFIX_IDX=0`) | **8** | p P1 P2 P3 P4 P5 O1 O3 |
| **row 12/15 reverted to the raw-`prev` test** (new this round) | **2** | **R1 R2** |

The last row is the point: the new rows pin the *round-2 fix specifically*, not just the
round-1 change.

## NFR-1 — not my finding, but I measured my own delta so the waiver stays true

I changed no performance path. Row 12 adds two comparisons per **special** byte at NORMAL only
(ordinary bytes still exit at the hoisted catch-all). A/B, 20 invocations each, same host,
round-1 guard (rebuilt in scratch) → round-2 guard:

```
  case a: round-1 guard   42 ms  ->  round-2 guard   43 ms (mean of 20)
  case d: round-1 guard   35 ms  ->  round-2 guard   35 ms (mean of 20)
  case b: round-1 guard 2213 ms  ->  round-2 guard 2130 ms (mean of 20)
```

Within host noise in both directions, so the rule doc's measured table (49→46 / 39→33 /
1487→2251 / 1561→1659) still describes this guard and was **not** edited. The chunked-indexing
mitigation remains a follow-up with my standing caveat: **any length cap must fail closed**
(BLOCK rather than skip), or it is a trivially exploitable bypass.

## Design drift (round 2)

**`DESIGN DRIFT` 5 — scanner row 15 no longer reads the raw input byte at `i-1`.**
Design §3.1 row 15 specifies the raw previous byte. As shown above that is a **false negative**
for `\>&` / `\<&`, which contradicts IS-1 row 2's "every position judged" for `A & B` — the
guard's own published coverage claim. Implemented instead: row 12 records the index at which a
redirection operator was appended, and row 15 tests that index. The divergence is strictly
narrowing (subset argument above), so it can only ever produce **more** positions. Same
treatment as drifts 1 and 2: an **accepted archive-time doc correction** to §3.1 rows 12/15,
not an architect round. Pinned by `R1`/`R2` (must BLOCK) and `R3` (the real `>&` dup-redirect
must stay ALLOW).

> **[AMENDED IN ROUND 3 — code review CR2-1 + CR2-2.]** The drift itself stands and is still the
> right direction of change. Two statements in it do not: "the divergence is strictly narrowing"
> was false at `i == 0` (that is CR2-1, a **new fail-open hole**, now fixed by moving the
> sentinel to `-2`), and the subset argument it leans on is not sound (CR2-2). The drift now also
> covers the sentinel value, and is pinned by `R4`/`R5` in addition to `R1`/`R2`/`R3`. See the
> round-3 record below for the restated drift and the corrected argument.

**Not drift, recorded per A-2.** `bash <<EOF … EOF` BLOCKs because §3.5 judges every non-option
token of a shell interpreter as a command string and here that token is the here-document
fragment. Direction is over-block; now in the accepted-over-blocks table of both rule copies and
pinned by row `H1`.

**Not drift, recorded per B-4.** A carrier verb with a literal destructive verb among its
arguments and an outside path later (`timeout 5 grep -r rm /etc` → exit **2**; the in-project
`timeout 5 grep -r rm ./docs` → exit **0**, both captured) is now in the same table. `N1`
(`ls | xargs grep rm` → ALLOW) already pins the adjacent boundary.

## Corrections to round-1 prose (round 1 itself left byte-unchanged, per instruction)

- **A-6 — the AC-1 headline claim.** Round 1's AC-1 section says "All 18 rows (a–r) plus a CRLF
  variant `f2`… 17 of the 18 were live bypasses (row `a` is the control that already blocked)".
  Correct statement: there are **19** AC-1 rows (`a`–`r` plus `f2`); **17 flipped** and **two
  did not** — `a` (the control) and `d`, whose `||` was already covered by the pre-change
  `split_pipes`. The enumerated red list in round 1 was right (it lists 17 ids and omits both
  `a` and `d`); only the summary sentence was wrong. 17 + 15 other flipped rows = the 32 red
  rows of the round-1 pre-change run, which is the arithmetic the reviewer re-derived
  independently.
- **B-3 — rule-doc line counts.** Reported at the counts `wc -l` prints, since gate I.2 is
  `n=$(wc -l < "$f"); (( n > 200 ))`:
  ```
  wc -l .harness/rules/75-safety-hook.md
                        skills/…/rules/75-safety-hook.md.tmpl
    198 .harness/rules/75-safety-hook.md          (was 197 before round 2)
    189 …/75-safety-hook.md.tmpl                  (was 187 before round 2)
  ```
  Both files end with a newline (`tail -c 1 | od -c` → `\n`) and `grep -c ''` agrees with
  `wc -l`. Note for the record: the review's "the files are 198/188, 04 reports 197/187 — a
  trailing-newline counting artifact" is itself one line high against `wc -l` — 197/187 *was*
  the `wc -l` truth at round 1; the 198/188 numbers are Read-tool line numbering. **Headroom is
  2 lines on the repo copy**, which is why residual 1 was rewritten to stay at two lines instead
  of reflowing to three.

## PowerShell surface — additions to the standing operator list

`pwsh` is still **not installed on this host**, so the `.ps1` twin was again neither run nor
parse-checked; it ships green-by-symmetry only. The round-1 seven-item list stands unchanged,
plus:

8. **Row 12 / `$redirIdx` in `Split-CommandPositions`.** Confirm `$redirIdx` (no collision with
   a PS automatic variable) is initialised **before** the scan loop and that
   `if ($redirIdx -eq ($i - 1))` is an integer comparison, not a string one — PS `-eq` on a
   string left operand would compare `'-1'` to an int and could mis-branch. A wrong result in
   the "append" direction is the only fail-**open** direction here; a wrong result in the
   "flush" direction merely over-blocks. Probe `echo a\>& rm -rf C:\x` (expect exit 2),
   `echo a\<& rm -rf C:\x` (expect 2) and `echo a>& rm -rf C:\x` (expect 0).
9. Re-run `test-guard-rm.ps1` at **85** rows (rows `R1 R2 R3 H1` are new) and pin
   `test_guard_rm_ps_assertions` from that run — the key is still deliberately absent.

## Open issues for review (round 2)

1. **A-1 is unaddressed by design** — it was routed to the requirement-analyst, not to me. My
   only contribution is the A/B above showing round 2 did not move the numbers.
2. Round-1 open issues 2 (the escaped-quote ALLOW→BLOCK class), 3 (`bash <script> "<cmd>"`),
   4 (the PS twin is unverified — still a *security* item, not polish) and 5 (`find_predicates`)
   stand; 5 is now explicitly commented rather than merely disclosed.
3. `CHANGELOG.md`'s 0.46.0 entry carried a **stale pre-change figure** (`46/31`) that no run ever
   printed; corrected to the captured `50/35`. Flagging it because it means the round-1 CHANGELOG
   text was written from an earlier draft rather than from a run — the reviewer did not catch it
   and neither did round 1's own "quote every tally" rule.
4. `A-7` (`xargs bash --rcfile foo -c "…"` unjudged) and `A-8` (empty leading token hides the
   verb) were rated record-only by the reviewer and are **not** fixed here. `A-8` is pre-existing
   and monotone; `A-7` is a §3.4 design asymmetry. Neither is in the rule doc's residual list —
   if the PM wants them published, that is a one-line addition each and the repo copy has exactly
   2 lines of headroom left.

## Dev-map updates

None. No file, module or folder was added, moved or removed in round 2; the two `docs/dev-map.md`
lines updated in round 1 are still accurate (the guard still "judges EVERY command position since
v0.46", the driver still takes an optional guard path).

## Insight to surface (round 2)

- A lexer rule written as *"look at the raw input byte at `i-1`"* is a **false-negative
  generator** in any language with escapes: the byte at `i-1` does not tell you how the byte at
  `i-1` was *consumed*. The fix is to record the index at which the operator was actually
  emitted and compare indices — one integer, and it degrades to over-blocking rather than
  under-blocking when it is wrong. · evidence: `guard-rm.sh:548-566` row 12/15;
  `echo a\>& rm -rf /etc/x` exit 0 → exit 2; scratch-mutant run "row 12/15 reverted → red rows
  exactly `R1 R2`"
- ~~When a fix's monotonicity can be proven by **set inclusion on the branch predicate**
  (`{redir_i == i-1} ⊂ {byte at i-1 ∈ {>,<}}`), the expensive corpus differential is not the
  evidence that matters and re-running it proves less than the argument does. Re-run the
  differential when the *row set* changes, not when the *code* changes in a provably narrowing
  direction.~~ · evidence: this round's IS-2 argument vs round 1's 55-line AC-4 run
  **[WITHDRAWN IN ROUND 3 — code review CR2-2.]** Not surfaced. The set inclusion it rests on is
  false at `i == 0`, and this rule, applied as written, is what let CR2-1 ship. The replacement
  insight is in the round-3 record below.

## Verdict (round 2)

**READY FOR REVIEW.**

`verify_all`: **PASS 32 / WARN 0 / FAIL 0** (baseline PASS 32 / WARN 0 / FAIL 0 — no delta,
check count held at 32, no check added). `test-guard-rm.sh`: **PASS 85 / FAIL 0** against the
promoted live guard; **PASS 50 / FAIL 35** against the pre-change guard; **PASS 83 / FAIL 2**
against the round-1 guard with red rows exactly `R1 R2`. Collateral suites unchanged
(`test-init.sh` 391/0, `test-real-project.sh` 90/0). `sync-self.sh --check` → **`In sync.`**
Rule docs **198 / 189** lines by `wc -l` (cap 200). All nine routed findings are dispositioned;
one new deviation is flagged as `DESIGN DRIFT` 5.

---
---

# Development Record — ROUND 3 (rework after stage-5 code review, round 2)

- Input: `05_CODE_REVIEW.md` **ROUND 2** (**CHANGES REQUESTED** — 0 CRITICAL, **1 MAJOR**, 1 MINOR,
  2 NIT). Routed to me: **all four** — CR2-1 (MAJOR, code), CR2-2 (MINOR, doc), CR2-3 and CR2-4
  (NIT).
- The reviewer closed all ten round-1 findings and re-derived both anti-revert tallies
  independently. This round changes **one token per shell**, adds **two driver rows**, corrects
  **one code comment** and **three doc paragraphs**. No other mechanism was opened.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- Every tally below is **quoted from the run that produced it**, and every run was checked for the
  presence of its summary line. **Note on the marker:** `test-guard-rm.{sh}` prints
  `=== test-guard-rm summary ===` (`test-guard-rm.sh:263`), **not** `=== Result ===` — that marker
  belongs to `test-init.sh` / `test-real-project.sh`, and `verify_all.sh` prints `=== Summary ===`.
  I checked for each driver's own marker; `grep -c` returned **1** for every run quoted here.
  Reporting a `=== Result ===` check on the guard driver would have been a fabricated check.

## Per-finding disposition

| Finding | Sev | Disposition | Where |
|---|---|---|---|
| **CR2-1** sentinel `-1` collides with `i - 1` at `i == 0`; a leading `&` is appended, not flushed | **MAJOR** | **FIXED** in both shells by moving the sentinel to **`-2`** (the reviewer's second suggested form), applied symmetrically. Code comment made true again. Pinned by new rows `R4`/`R5` in three-way lockstep. Reproduced before the fix and re-probed after | `guard-rm.sh:334-341,550-574`, `guard-rm.ps1:294-303,538-564`, both drivers, `evals/guard-rm-cases.md` |
| **CR2-2** drift-5 monotonicity argument false as written | MINOR | **CORRECTED.** The round-2 paragraphs are annotated in place as `[SUPERSEDED]` / `[AMENDED]` (not rewritten — the captured record stays auditable, the practice used for the T-12 archive), and the argument that actually holds is restated below. The round-2 insight is **withdrawn, not surfaced**; the inverse insight is offered instead | §CR2-2 below; annotations at the round-2 §"The A-3 fix", §"Design drift (round 2)", §"Insight to surface (round 2)" |
| **CR2-3** quoted `grep -n '[<>]&'` does not reproduce over its own file set | NIT | **FIXED.** Re-run over the same declared set and quoted in full: **8** hits, not 1. Round-2 block annotated `[SUPERSEDED]` | §CR2-3 below |
| **CR2-4** `R3b` captured as a probe, never promoted to a row | NIT | **DECLINED, recorded.** `R3` already pins that branch and `2>&1 &&` never consults the index (the `two == "&&"` test precedes the single-`&` test in both shells). `R3b` remains a standing probe in my probe script and is re-run below. Promoting it would add a row that no mutation can redden | this section |

## CR2-1 — the fix, and why `-2` rather than `i > 0`

The reviewer offered two forms. I took the **sentinel** one and applied it symmetrically:

```bash
# guard-rm.sh:341   (was: local redir_i=-1)
local redir_i=-2
```
```powershell
# guard-rm.ps1:303  (was: $redirIdx = -1)
$redirIdx = -2
```

Reason for choosing this form over `(( i > 0 && redir_i == i - 1 ))`: it repairs the defect at
its **source** rather than at the one call site. The property the code needs is *"the sentinel is
not a value `i - 1` can take"*. Over this loop `i ∈ {0 … len-1}`, so `i - 1 ∈ {-1 … len-2}`;
`-1` is **inside** that domain and `-2` is not. Stating it at the declaration means any future
second reader of `redir_i` inherits the guarantee instead of having to re-derive the `i > 0`
condition. Both forms are equivalent on today's code — I am not claiming otherwise — and the
comparison stays integer in both shells, so operator item 8's question is still satisfied.

The code comment the reviewer called out (it asserted a wrong index "can only cause a flush",
which was false at `i == 0`) is now true and says *why*:

> Because the "none yet" sentinel (-2) is OUTSIDE the domain of `i - 1`, a stale or never-set
> index can only ever compare unequal, i.e. cause a flush, i.e. MORE positions — fail-closed.
> That property is what makes a single scanner-wide index sound without per-frame save/restore,
> and it holds only while the sentinel stays unreachable (see its declaration).

The declaration site carries the rest: why `-1` is forbidden, that `&` is PowerShell's call
operator, and that `R4`/`R5` pin it.

### Reproduced first, then re-probed — 22 probes, three guards

The rollback budget says be exhaustive, so I did not test only the two reported inputs. I probed
the new predicate at `i == 0`, at `i == len-1`, inside each frame type, after a flush, at depth 1
in both recursion branches (`bash -c` and `pwsh -c`), and on the no-space variant. Captured
(`exit` is the guard's real exit code; 2 = BLOCK, 0 = ALLOW):

```
--- LIVE ROUND-2 GUARD (before this round) --- | --- PROMOTED ROUND-3 GUARD (after) ---
  exit=0  R4   & rm -rf OUT                (want 2)  |  exit=2  R4   & rm -rf OUT
  exit=0  R5   pwsh -c "& Remove-Item …"   (want 2)  |  exit=2  R5   pwsh -c "& Remove-Item …"
  exit=0  E11  bash -c "& rm -rf OUT"      (want 2)  |  exit=2  E11  bash -c "& rm -rf OUT"
  exit=0  E15  &rm -rf OUT                 (want 2)  |  exit=2  E15  &rm -rf OUT
  ---- the other 18 probes, unchanged by this round ----
  exit=2  b8   pwsh -c "Remove-Item -Recurse C:\Windows"   (want 2)   both rounds
  exit=2  R1   echo a\>& rm -rf OUT                        (want 2)   both rounds
  exit=0  R3   echo a>& rm -rf OUT                         (want 0)   both rounds
  exit=0  R3b  ls . 2>&1 && echo ok                        (want 0)   both rounds   <- CR2-4
  exit=0  N3   echo hi &&                                  (want 0)   both rounds
  exit=0  E1   &                                           (want 0)   both rounds
  exit=2  E2   && rm -rf OUT                               (want 2)   both rounds
  exit=2  E3   echo hi & rm -rf OUT                        (want 2)   both rounds
  exit=0  E4   echo hi &                    (i == len-1)   (want 0)   both rounds
  exit=0  E5   & echo hi                                   (want 0)   both rounds
  exit=2  E6   (& rm -rf OUT)               (GROUP_PAREN)  (want 2)   both rounds
  exit=2  E7   echo $(& rm -rf OUT)         (CMDSUB)       (want 2)   both rounds
  exit=2  E8   echo hi && & rm -rf OUT      (after flush)  (want 2)   both rounds
  exit=0  E9   echo a > b &                 (real redirect + trailing &)  (want 0)  both rounds
  exit=0  E10  rm -rf ./build &             (in-project)   (want 0)   both rounds
  exit=0  E12  sh -c "& rm -rf ./build"     (depth 1, in-project)     (want 0)  both rounds
  exit=0  E13  && echo hi                                  (want 0)   both rounds
  exit=0  E14  echo a\>&                                   (want 0)   both rounds
```

Two things worth stating precisely, because they bound the blast radius of both the defect and
the fix:

1. **The defect fired only at `i == 0` of a scan.** `i` is not reset by a frame push, so `E6`
   (`(& …`, `&` at `i == 1`) and `E8` (`… && & …`) already flushed under round 2 — they are
   green in both columns. What made the vector real is that the *recursion* restarts `i` at 0 on
   the inner string, which is why `R5`/`E11`/`E12` are depth-1 instances of the same `i == 0`.
2. **The fix changes behavior for exactly one input class: a command string whose first
   character is `&`.** Every other probe is byte-identical across the two columns. That is the
   property the AC-4 argument below rests on, and it is checkable rather than asserted.

### The two new rows, in three-way lockstep

| Row | Command | Expect | Pins |
|---|---|---|---|
| `R4` | `& rm -rf OUT` | **BLOCK** | written boundary **B-3** — `rm -rf OUT` BLOCKs, so the same line with an empty leading position must BLOCK too. `N2`/`N3` pinned B-3 only in the ALLOW direction with in-project paths, which is why the 85-row suite could not see this |
| `R5` | `pwsh -c "& Remove-Item -Recurse C:\Windows"` | **BLOCK** | the executable vector — row 8 plus one character. `&` is PowerShell's call operator; the guard recurses into `pwsh -c` strings, so the collision fired at depth 1 exactly as at depth 0 |

Both are **single-quoted** in both drivers per C-5 (`R5` also contains `"` and `\`). Three-way id
lockstep machine-checked with a static extractor over all three artifacts (no guard run involved),
`comm -3` empty in both pairings, no duplicate ids:

```
counts: sh=87  ps=87  fx=87
--- sh vs ps symmetric difference ---
--- sh vs fx symmetric difference ---
--- duplicate ids (sh) ---
--- duplicate ids (fx) ---
lockstep mismatches: 0
```

The fixture header now reads `87 ↔ 87`.

## CR2-2 — the corrected argument for not re-running AC-4

The reviewer is right on both counts, and I want to be explicit that the *first* one is not a
presentational defect: `A₂ = { i : redir_i == i-1 }` contains `0` while round 1's
`A₁ = { i : i > 0 ∧ s[i-1] ∈ {>,<} }` does not, so the append branch **grew** by one element.
Believing the subset claim is what made me stop looking. The second — that a flush *replaces* one
combined position with two fragments and loses the combined one, so "more flushes" ≠ "more
positions" — I re-derived on the reviewer's own counterexample and it holds.

**The argument that actually supports the conclusion, in two independent parts:**

1. **Structural, against the right baseline.** IS-2 / AC-4 are defined against the **pre-change**
   guard, and neither round 2 nor round 3 touched `plist+=("$s")` (`guard-rm.sh:908`, still
   unconditional at every depth) or `split_pipes`. Every position the pre-change guard judged is
   therefore still judged, so a BLOCK→ALLOW flip *against the released baseline* is structurally
   unreachable no matter what the scanner does. This does **not** depend on any claim about the
   scanner's branch predicates, which is exactly why it survives where the round-2 argument died.
2. **Empirical, and specific to round 3.** Round 3 changes behavior for **one input class only**:
   a string whose first character is `&` (demonstrated probe-by-probe above, not asserted). I
   checked the recorded 55-line corpus statically — a read of the frozen table in the round-1
   record, **not** a re-harvest and **not** a re-run of the differential, per the reviewer's
   instruction that it does not need re-harvesting:

```
rows extracted        : 55 (ids 1..55, contiguous=True)
commands starting with '&' (the ONLY class round 3 changes) : 0
commands containing [<>]&                                   : 0
commands containing any '&' (all mid-string => unchanged)   : 5
   2   mkdir my-app && cd my-app
   25  bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'
   47  bash .harness/scripts/harness-sync.sh && bash .harness/scripts/extra-helper.sh
   48  sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
   49  pwsh -NoProfile -Command \"Set-Location … ; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"
```

Four of the five are `&&`, which is dispatched by the `two == "&&"` test *before* the single-`&`
test in both shells and never consults the index at all. The fifth (line 49) has its single `&`
at an index > 0, where round 2 and round 3 are identical. **Zero corpus lines begin with `&`, so
no corpus line can move.** Note that this second part is the *empirical bound*, not the proof —
part 1 is the proof, and it does not need part 1's predicate reasoning to be sound.

Restated **`DESIGN DRIFT` 5** (superseding the round-2 wording):

> **`DESIGN DRIFT` 5 — scanner row 15 tests a recorded index instead of the raw input byte at
> `i-1`, and the index's "none yet" sentinel is `-2`.** Design §3.1 row 15 specifies the raw
> previous byte, which is a false negative for `\>&` / `\<&` (round 2). Testing a recorded index
> instead requires one thing the design does not state: the sentinel must be outside the domain
> of `i - 1`, or the test is true at `i == 0` and a leading `&` is swallowed (round 3). Both
> halves are fixes-forward and belong together as an **accepted archive-time doc correction** to
> §3.1 rows 12/15 — not an architect round. Pinned by `R1`/`R2` (escaped redirect must BLOCK),
> `R3` (real `>&` dup-redirect must stay ALLOW), `R4`/`R5` (leading `&` must BLOCK, at depth 0
> and depth 1). Direction of risk: with the sentinel unreachable, a wrong or stale index can only
> cause a flush — more positions — which is the fail-closed direction.

## CR2-3 — the evidence re-run, quoted in full

Same pattern, same declared file set (`_archived/` expanded to its real path
`docs/features/_archived/`, abbreviated to `_arch/` in the output below for width):

```
grep -n '[<>]&' README.md docs/getting-started.md .harness/scripts/hook-spec.sh
                .harness/scripts/hook-spec.ps1
                docs/features/_archived/*/04_DEVELOPMENT.md
                docs/features/_archived/*/04_IMPLEMENTATION.md
                docs/features/_archived/*/06_TEST_REPORT.md

.harness/scripts/hook-spec.sh:60:    printf '%s\n' "hook-spec: $1" >&2
_arch/hook-truth-spec/06_TEST_REPORT.md:148:6. (r-3) the `& pwsh … 2>&1` native captures under …
_arch/hook-truth-spec/06_TEST_REPORT.md:456:`& pwsh … 2>&1` native captures at `test-init.ps1:…
_arch/harness-upgrade-skill/04_DEVELOPMENT.md:55:  - `verify_all.sh` → **exit code 0** (captured …
_arch/hook-truth-spec/04_DEVELOPMENT.md:39:- **DECLINED, recorded**: m-3 — the `& pwsh … 2>&1` …
_arch/hook-truth-spec/04_DEVELOPMENT.md:268:   `test-init.ps1:1073,1120,…` — **seven** `& pwsh …
_arch/hook-truth-spec/04_DEVELOPMENT.md:269:   captures under script-scope `$ErrorActionPrefer…
_arch/hook-truth-spec/04_DEVELOPMENT.md:348:| **CR r-7 / QA n-8 (MINOR)** — `baseline.json:_qa…
```

**8 hits, not 1.** Seven are prose mentions of `2>&1` / `& pwsh … 2>&1` inside sentences; none is
a fenced command line or a `Command:` line, so none is a corpus line — the conclusion is
unaffected, and the corpus check above is the load-bearing evidence anyway. The reviewer is right
that this is the same defect class as the `46/31` CHANGELOG figure I corrected last round: a
figure written from a draft rather than transcribed from the run. I have no explanation for it
beyond that, and it is the second occurrence in two rounds.

## CR2-4 — declined, with the reason

`R3b` (`ls . 2>&1 && echo ok`) stays a probe. Promoting it would add a row that is green under
every guard I can construct — pre-change, round 1, round 2, round 3 and all four mutants — because
`2>&1 &&` is dispatched by the `two == "&&"` test before the single-`&` test ever reads the index.
A row no mutation can redden is row-set inflation, and the three-way lockstep cost is real. It is
re-run as probe `R3b` above and green. If the reviewer disagrees, it is a three-line addition.

## Files changed in round 3

| Surface | What changed |
|---|---|
| `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` | **edited here first** (unwired staging area): `local redir_i=-1` → `-2`, with the domain rationale at the declaration; row-12 comment's fail-closed sentence made true |
| `.harness/scripts/guard-rm.sh` | byte-mirrored dest — written by **one** `sync-self` run, never hand-edited |
| `skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1` | symmetric: `$redirIdx = -1` → `-2`, same two comments |
| `.harness/scripts/guard-rm.ps1` | byte-mirrored dest — same `sync-self` run |
| `.harness/scripts/test-guard-rm.sh` | rows `R4` `R5` added (single-quoted) → **87 rows** |
| `.harness/scripts/test-guard-rm.ps1` | same two ids, same expectations |
| `evals/guard-rm-cases.md` | same two rows + lockstep header `85 ↔ 85` → **`87 ↔ 87`** |
| `.harness/scripts/baseline.json` | `test_guard_rm_bash_assertions` 85 → **87** (transcribed from the `PASS: 87` line); `_qa_note_t17` gains the round-3 decomposition, the captured 50/37, and both single-fix comparison runs; the operator note now says 87 rows and names the two new probes |
| `CHANGELOG.md` | new bullet for the leading-`&` sentinel fix; "17 → 85 rows" → "17 → 87 rows"; pre-change figure 50/35 → **50/37**, transcribed from this round's run |
| `docs/features/guard-cmd-chain/04_DEVELOPMENT.md` | this round-3 record + four `[SUPERSEDED]` / `[AMENDED]` / `[WITHDRAWN]` annotations on round-2 prose |

**Untouched, deliberately:** `.harness/rules/75-safety-hook.md` and its `.tmpl` (CR2-2 is a
task-doc correction; CR2-1 is a fixed bug, not a new residual — so the rule docs stay at
**198 / 189** against the 200 cap), `CONTEXT.md`, `01_REQUIREMENT_ANALYSIS.md`,
`02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md`, `05_CODE_REVIEW.md`,
`docs/proposals/frontier-gaps-2026-07.md` (still never opened), `docs/tasks.md` /
`BATCH_PLAN.md` (PM-owned), every frozen T-13 PowerShell item, `verify_all.{sh,ps1}` (check count
still **32**), the verb set, version stamps (still 0.46.0). Nothing was committed.

## Edit sequence actually followed (the live-hook hazard, unchanged)

1. Baseline `verify_all`; CR2-1 reproduced against the **live round-2 guard** with a probe script
   written by the **Write** tool (a Bash call whose own text contains an outside-path deletion is
   judged by the live hook — the probe payloads must live in a file, not on my command line).
2. Change written to the **template** `.sh` → `bash -n` exit 0 → probes re-run against the
   template path: the four red probes flip to 2, the other 18 do not move.
3. Template `.ps1` given the symmetric change (unrunnable — `pwsh` absent).
4. Two rows added to both drivers + the fixture; three-way lockstep machine-checked
   (**87 / 87 / 87**, `comm -3` empty both pairings); driven against the template:
   `PASS: 87 / FAIL: 0`.
5. `sync-self.sh --check` → drift list named **exactly** `guard-rm.ps1` + `guard-rm.sh` and
   nothing else → **one** `sync-self.sh` run → `--check` → `In sync.` → driver and probes re-run
   against the **default** path.
6. Comparison guards + mutants rebuilt from the fixed template by a Python builder that
   `bash -n`s each one and **fails loudly if an anchor string does not match exactly once**
   (a silent no-op mutant is a false green); all 7 built clean.
7. Docs, `baseline.json`, `CHANGELOG.md` → `verify_all` → collateral suites.

The live guard was never left unrunnable; no Write-tool repair was needed.

## verify_all result

**Baseline** (captured before any round-3 edit):

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**After the round-3 changes:**

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

**Delta: 0 new failures, 0 new warnings, check count held at 32.** No `verify_all` check was
added, removed or modified. `[I.2] Rule fragments ≤200 lines each ... PASS` (198 / 189 by
`wc -l`, unchanged this round).

### Driver runs — each quoted from its own run, summary line verified present

| Run | Guard | Output |
|---|---|---|
| 87 rows, **template** guard (step 4) | `skills/…/templates/common/.harness/scripts/guard-rm.sh` | `PASS: 87` / `FAIL: 0` |
| 87 rows, **promoted live** guard (final) | `.harness/scripts/guard-rm.sh` | `PASS: 87` / `FAIL: 0` |
| 87 rows, **pre-change** guard | `git show HEAD:.harness/scripts/guard-rm.sh` → scratch | `PASS: 50` / `FAIL: 37` |
| 87 rows, **round-1** guard (rows 12/15 back to the raw-`prev` test) | scratch | `PASS: 85` / `FAIL: 2` — red **exactly `R1 R2`** |
| 87 rows, **round-2** guard (**this round's fix reverted**, `-2` → `-1`) | scratch | `PASS: 85` / `FAIL: 2` — red **exactly `R4 R5`** |
| `test-init.sh` (collateral) | — | `=== Result ===` `PASS: 391` / `FAIL: 0` |
| `test-real-project.sh` (collateral) | — | `=== Result ===` `PASS: 90` / `FAIL: 0` |

Every guard-driver run printed `=== test-guard-rm summary ===` (checked with `grep -c`, = 1 in
all five); both collateral runs printed `=== Result ===`; `verify_all` printed `=== Summary ===`.

**The two single-fix runs are the point of this round.** They are what proves each fix is
individually load-bearing, and they separate cleanly:

- revert **round 2's** fix only → red = `{R1, R2}` (the escaped-redirect false negative), `R4`/`R5`
  green — i.e. round 1 did **not** have CR2-1, confirming it was a regression opened by round 2;
- revert **round 3's** fix only → red = `{R4, R5}`, `R1`/`R2` green — i.e. the `-2` sentinel is
  load-bearing on its own and nothing else in the 87 rows depends on it.

Red rows against the **pre-change** guard (37, transcribed from that run's failure list):
`b c e f f2 g h i j k l m n o p q r F2 F3 C10a C10b C12cr C12tee C14 P1 P2 P5 O1 O2 O3 Q2 W1 R1
R2 H1 R4 R5` — round 2's 35 plus `R4 R5`. PASS stayed **50** (no previously-red row went green).

### AC-10 anti-revert mutations, re-run over the 87-row set

Two red sets moved, so all four were re-run (plus the two comparison guards above, which are the
fifth and sixth anti-revert mutants). Each mutant is a `bash -n`-clean scratch copy of the
**promoted** guard, driven via `[guard-path]`; tallies quoted from those runs:

| Mutation | Red rows | Which | vs round 2 |
|---|---|---|---|
| scanner disabled (`if _has_scanner_trigger "$s"` → `if false`) | **23** | b c e f f2 g i q F2 F3 C10a C10b C12cr C12tee P5 O1 Q2 W1 R1 R2 H1 **R4 R5** | 21 → 23 (+ the two new rows) |
| carrier scan disabled (`if _is_carrier_verb "$verb"` → `if false`) | **7** | j k l m n o O2 | unchanged |
| C-1 invariant deleted (`plist+=("$s")` → `:`) | **1** | C14 | unchanged |
| prefix strip disabled (`_skip_prefix …` → `_PREFIX_IDX=0`) | **8** | p P1 P2 P3 P4 P5 O1 O3 | unchanged |
| rows 12/15 reverted to the raw-`prev` test (round-1 guard) | **2** | R1 R2 | unchanged |
| **sentinel `-2` → `-1` (round-2 guard) — new this round** | **2** | **R4 R5** | new |

`R4`/`R5` go red under the scanner mutation as well as under the sentinel mutation, i.e. they are
non-vacuous against both the mechanism and the specific fix.

## PowerShell surface — standing operator list, amended

`pwsh` is still **not installed on this host** (`command -v pwsh` → nothing), so the `.ps1` twin
was again neither run nor parse-checked; it ships green-by-symmetry only. The round-1 seven-item
list and round-2 item 8 stand, with these amendments:

- **Item 8 (amended).** `$redirIdx` is now initialised to **`-2`**, not `-1`. Confirm the literal
  is an `[int]` and that `if ($redirIdx -eq ($i - 1))` is still an integer comparison. Add two
  probes: `& rm -rf C:\x` (expect **2**) and `pwsh -c "& Remove-Item -Recurse C:\Windows"`
  (expect **2**). Both were exit 0 on the bash twin before this round's fix.
- **Item 9 (amended).** Re-run `test-guard-rm.ps1` at **87** rows (was 85; `R4`/`R5` are new) and
  pin `test_guard_rm_ps_assertions` from that run — the key is still deliberately absent.
- **Item 10 (new).** The PS twin's defect and its fix were both symmetric to bash, so a PS run is
  the *only* thing that can distinguish "symmetric by construction" from "symmetric in fact" here.
  This is a **security** item, not polish: the vector `pwsh -c "& …"` is a PowerShell one.

## Open issues for review (round 3)

1. **The PS twin remains unverified** — unchanged from rounds 1 and 2, and CR2-1 sharpens it: the
   defect existed identically in `.ps1` and I fixed it identically, but "identically" is my
   reading, not a run.
2. Round-1 open issues 2 (escaped-quote ALLOW→BLOCK class), 3 (`bash <script> "<cmd>"`),
   5 (`find_predicates`) and round-2 open issue 1 (**A-1 / NFR-1 is the requirement-analyst's**,
   not mine) all stand unchanged. I touched no performance path this round — the change is one
   integer literal, evaluated once per `Split-CommandPositions` call — so the measured latency
   table in the rule docs still describes the shipped guard and was not edited.
3. `A-7` and `A-8` remain record-only, as rated in round 1. Unchanged.
4. **This file is now 1304 lines against the 500-line per-task stage-doc cap** in
   `.harness/rules/70-doc-size.md`. It was already over after round 1 (558) and round 2 (868);
   round 3 adds the record above. The cap is **WARN-level and ungated** — `verify_all`'s `I.*`
   group covers `AI-GUIDE.md`, rule fragments, agents, `insight-index.md` and `docs/tasks.md`,
   but **not** per-task stage docs, so nothing flags it and I am flagging it by hand. I did not
   compact: three rounds of captured run evidence is the thing this task is being judged on, and
   compaction of a stage doc is not mine to do unilaterally. **Owner: PM**, at archive time
   (rule 70's "reference, don't paste" / compaction patterns).
5. **Two rounds, two evidence-hygiene defects from me** (`46/31` in round 1's CHANGELOG, the
   `[<>]&` grep in round 2). Both were figures written from a draft rather than transcribed from
   a run, and both were caught by review rather than by my own "quote every tally" rule — because
   that rule, as I was applying it, covered *tallies* and not *quoted command output*. I have
   extended it to the latter for this round (every block quoted above is a real capture), but the
   reviewer should treat my quoted evidence as needing the same verification as my numbers.

## Dev-map updates

None. No file, module or folder was added, moved or removed in round 3; `docs/dev-map.md:106`
still describes the driver and its optional guard-path argument accurately, and the guard's
"judges EVERY command position since v0.46" line is unaffected.

## Insight to surface (round 3)

- A **sentinel compared against a derived index must be unreachable by that index's domain**: the
  scanner's "no redirection recorded yet" value was `-1` while the test was `redir_i == i - 1`,
  whose domain includes `-1` at `i == 0`, so the guard silently took the append branch on any
  command string beginning with `&` — a fail-**open** hole in a fail-closed hook, at depth 0 and
  (via `pwsh -c` recursion, where `&` is the call operator) at depth 1. The `i > 0` guard that
  the previous implementation carried was what had been masking the domain overlap, so removing
  the raw-byte read removed the guard with it. Pick the sentinel from outside the domain (`-2`)
  rather than re-deriving the bounds check at each call site. · evidence: `guard-rm.sh:341` /
  `guard-rm.ps1:303`; captured `& rm -rf OUT` exit 0 → exit 2 and
  `pwsh -c "& Remove-Item -Recurse C:\Windows"` exit 0 → exit 2; scratch-mutant run
  "sentinel `-2` → `-1` → red rows exactly `R4 R5`"

_(The round-2 insight about not re-running a differential when the change is "provably narrowing"
is **withdrawn**, not surfaced — it is the rule that produced this defect. The round-2 insight
about raw-byte lexer rules being false-negative generators stands and is unaffected.)_

## Verdict (round 3)

**READY FOR REVIEW.**

`verify_all`: **PASS 32 / WARN 0 / FAIL 0** (baseline PASS 32 / WARN 0 / FAIL 0 — no delta, check
count held at 32, no check added). `test-guard-rm.sh`: **PASS 87 / FAIL 0** against the promoted
live guard; **PASS 50 / FAIL 37** against the pre-change guard; **PASS 85 / FAIL 2** against the
round-1 guard with red rows exactly `R1 R2`; **PASS 85 / FAIL 2** against the round-2 guard (this
round's fix reverted) with red rows exactly `R4 R5`. Six anti-revert mutations re-run; the two
whose red sets moved are accounted for. Collateral suites unchanged (`test-init.sh` 391/0,
`test-real-project.sh` 90/0). `sync-self.sh --check` → **`In sync.`**; repo ↔ template byte-identical
(`cmp` clean, 968/968 and 933/933 lines). Rule docs **198 / 189** by `wc -l` (cap 200), untouched.
Three-way lockstep **87 / 87 / 87**. All four round-2 findings are dispositioned (CR2-1 fixed,
CR2-2 corrected, CR2-3 fixed, CR2-4 declined with reason); `DESIGN DRIFT` 5 is restated to cover
both halves of the change.
