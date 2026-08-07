# Delivery Summary — T-17 `guard-cmd-chain`

- **Task**: `guard-cmd-chain` — make the destructive-command guardrail evaluate every command in a compound command line, not only the leading verb of each top-level pipe segment.
- **Mode**: full (stages 1-7)
- **Dispatched by**: `/harness-stream` drain, operator-authorized interleave. Security task.
- **deferred-human mode**: defer, do not ask. **No `BLOCKED: NEEDS-HUMAN` was raised** — no point in this task required an interactive human decision, and the one judgment call that arose (NFR-1's waiver) was rubric-covered under Mode 2 and is recorded for after-the-fact review.
- **Entropy-watch cadence**: deliberately **not run** — the stream owns that boundary (per dispatch).

---

## What shipped

Before this change, the guard judged the first token after an optional `sudo`, **per top-level pipe
segment**. The stream reproduced the consequence directly from exit codes:

| Command fed to the guard | Pre-change | Shipped |
|---|---|---|
| `rm -rf <outside project root>` | 2 (blocked) | 2 |
| `echo hi && rm -rf <outside>` | **0 — bypass** | **2** |
| `true; rm -rf <outside>` | **0 — bypass** | **2** |
| `ls \| xargs rm -rf <outside>` | **0 — bypass** | **2** |
| `rm -rf ./build` (in-project) | 0 (correct) | 0 |

Reproduced and closed by QA's own runs, not inherited: pre-change `2 / 0 / 0 / 0 / 0` → shipped
`2 / 2 / 2 / 2 / 0`.

The nine-verb rule is now evaluated at **every command position the guard can identify** in one
command line: `;`, `&&`, `||`, `&`, newlines and CRLF, subshells, brace groups, command
substitutions, backticks, process substitutions, argv carriers (`xargs`, `env`, `nohup`, `nice`,
`time`, `timeout`, `command`, `exec`, `find … -exec/-execdir`) and nested `bash -c` / `sh -c` /
`pwsh -c` strings. Mechanism: a single-pass, quote/here-doc/comment-aware position scanner, unioned
with the **byte-unchanged** pre-change decomposition **and the input string itself at every
recursion depth** — so monotonicity (no command line that blocked before now passes) holds by
construction, and the path-resolution code that preserves the existing behaviour was not touched.

**The destructive verb set is unchanged.** `mv`, `cp` and output redirection remain deliberately
unguarded. This task fixed *reachability* of the existing verb set, nothing more.

---

## Stages traversed

| Stage | Agent | Rounds | Outcome |
|---|---|---|---|
| 1 | requirement-analyst | 4 | READY. Rounds 2-4 were corrections routed from the Gate (AC-3/AC-4) and from Code Review (NFR-1's waiver record) |
| 2 | solution-architect | 2 | READY. Round 2 closed ten Gate findings |
| 3 | gate-reviewer | 2 | Round 1 **BLOCKED ON DESIGN**; round 2 **APPROVED FOR DEVELOPMENT** with 15 binding conditions |
| 4 | developer | 3 | READY FOR REVIEW |
| 5 | code-reviewer | 3 | Rounds 1-2 **CHANGES REQUESTED**; round 3 **APPROVED WITH NITS** (0 CRITICAL, 0 MAJOR) |
| 6 | qa-tester | 2 | **PASS WITH NOTES** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 4 MINOR / 5 NIT |
| 7 | pm-orchestrator | 1 | This document |

Dates: stages 1-5 on 2026-07-31; stages 6-7 on 2026-08-01.

## Rollbacks — 4 total

| # | From → to | Cause |
|---|---|---|
| 1 | Gate → architect | **F-1** a `$( )` opened inside `"…"` never reset the quote state, so `echo "$(true && rm -rf /etc/x)"` **allowed** — a false negative, the forbidden direction. **F-2** the headline "monotonicity provable by inspection" was false: the nested-`pwsh` call site flipped a case from BLOCK to ALLOW. **F-3** the carrier-vs-`find` branch order broke an acceptance criterion under *both* readings. **F-4** the residual list overstated coverage. Plus five more |
| 2 | Gate → requirement-analyst | **F-10** AC-3's header contradicted the monotonicity invariant for one row. **F-11** AC-4's corpus source (session transcript / `git log`) was **unobtainable by any agent**, making the criterion unverifiable |
| 3 | Code review → developer | 1 MAJOR (NFR-1, routed onward to the requirement stage) + 5 MINOR: one false negative (`\>&` suppressing a separator), an unrecorded over-block class, two documentation inaccuracies, dead code |
| 4 | Code review → developer | 1 MAJOR — **the round-2 fix opened a new hole while closing one**: the `redir_i` sentinel `-1` equals `i - 1` at `i == 0`, so a leading `&` was appended instead of flushed. `pwsh -c "& Remove-Item -Recurse C:\Windows"` — a pinned fixture row plus one character — flipped to ALLOW |

Stage 4 ended at **2 consecutive** rollbacks; the three-consecutive stop rule was never reached. The
Code Reviewer stated explicitly in round 3 that no remaining finding required another developer
round, on the evidence rather than on the rollback budget.

---

## Final verification — every figure quoted from the run that produced it

```
=== Summary ===            (bash .harness/scripts/verify_all.sh, exit 0)
  PASS: 32   WARN: 0   FAIL: 0

=== test-guard-rm summary ===   (bash .harness/scripts/test-guard-rm.sh, exit 0)
  PASS: 87   FAIL: 0
```

| Run | Result | What it proves |
|---|---|---|
| Driver vs shipped guard | **87 / 0** | The suite is green |
| Driver vs **pre-change** guard | **50 / 37** | 37 rows are anti-revert protection that did not exist before |
| Driver vs **round-1** guard | 85 / 2, red exactly `{R1, R2}` | Round 2's fix is individually load-bearing |
| Driver vs **round-2** guard | 85 / 2, red exactly `{R4, R5}` | Round 3's one-token fix is individually load-bearing — and, because the two red sets are **disjoint**, that the round-2 regression was opened by round 2 rather than pre-existing |
| Mutants (scanner / carrier / union / prefix / sentinel) | 23 / 7 / 1 / 8 / 2 red | Each mechanism is separately pinned |
| AC-4 differential, 55 sourced corpus lines | **0 BLOCK→ALLOW**, 4 ALLOW→BLOCK (one isolated class, recorded and pinned) | Monotonicity, by measurement rather than by argument |
| Adversarial + fuzz | ~1,870 probes, **0 BLOCK→ALLOW**, **0 exit codes outside {0,2}** in 1,500 fuzz inputs | No silent-disarm path on bash |
| Collateral | `test-init` 391/0, `test-real-project` 90/0 | Nothing else moved |

**Check count held at 32.** No `verify_all` check was added — the defect class was closed by
extending the regression driver instead, following the T-016 precedent.

## Baseline changes

- `test-guard-rm` regression suite: **17 → 87 rows**, three-way lockstep across the bash driver, the
  PowerShell driver and `evals/guard-rm-cases.md` (87/87/87, machine-checked).
- `.harness/scripts/baseline.json`: new key `test_guard_rm_bash_assertions: 87`. This driver was
  previously the **only** one in the repo with no pinned count — the class had no anti-revert
  protection at all. The PowerShell key was deliberately **not** invented (no operator run has
  produced a real tally).
- `verify_all_checks: 32` — unchanged.
- Version `0.44.0 → 0.46.0` (0.45.0 is T-13/T-14's, delivered-but-uncommitted).

---

## Outstanding risks

1. **The PowerShell twin has never been executed anywhere.** This is the largest operational risk in
   the delivery, and it is not a formality: the highest-probability PowerShell defect for a character
   lexer (a .NET out-of-range `Substring`) throws, and under `$ErrorActionPreference = 'Stop'` an
   escaping terminating error exits **1**, which Claude Code treats as non-blocking — i.e. the
   Windows guard would **silently disarm**. The code is written to prevent this (every lookahead
   length-guarded, the scanner wrapped in `try/catch` mapping to the parse-fail path) and the Code
   Reviewer verified it by reading, but reading is not running. **10 items are queued on the standing
   operator PowerShell list**, with items 3 and 10 marked as *security* items. The frozen T-13 items
   were not touched.
   - Known inconsistency in that list: item 2 still says "(81 rows) … Expect `PASS: 81`" while item 9
     says 87. **The correct figure is 87.** (QA could not fix it — it lives in the developer's stage
     doc.)
2. **`.harness/rules/75-safety-hook.md` is at exactly 200 lines — the cap, with zero headroom.** The
   next line added to it fails `verify_all`, because a WARN exits 1. Whoever edits that file next
   must re-flow rather than append.
3. **NFR-1's +20 ms latency clause is WAIVED**, not met — recorded in full in the requirement
   document. The 8192-character worst case costs roughly 1.5 s → 1.5-3.1 s depending on payload
   *shape*. Root cause is pre-existing: bash `${s:$i:1}` is O(i), so every character pass is O(n²),
   and the guard already made two such passes before this change added a third. Bounded by the
   8192-character truncation, no hook-timeout risk, no fail-open path, and **typical commands got
   faster** (~43 → ~40 ms, because ~20 subprocess forks per segment were removed). A chunked-indexing
   follow-up is **recommended but not scheduled** — see Next steps.
4. **The newly published residual class is not pinned by any test.** QA deliberately declined to add
   driver rows for it, because doing so would have invalidated every tally already quoted across
   three stage documents and broken the three-artifact lockstep. It preserved the baseline at 87
   rather than lowering it, and recommended a pool row with the tradeoff stated. I endorse that call.

## Residual bypass surface — what this fix does NOT close

Published in `.harness/rules/75-safety-hook.md` and its template twin, and stated here because a
security fix that overstates its coverage is worse than one that names its edges. Every item below
was verified empirically by QA against **both** the shipped and the pre-change guard, so each is
confirmed pre-existing rather than introduced.

1. **Verb spelling** — `/bin/rm`, `\rm`, `$(which rm)` are not recognized. (`'rm'` and `"rm"` *are*.)
2. **Indirection** — `eval "$X"`, `$CMD -rf …`, aliases, shell functions, `./script.sh`, Makefile
   targets, `ssh`. Structurally out of reach for a text-only guard.
3. **The verb is not at token 0 of its position** — this is the largest gap, and it was undisclosed
   until this task published it. A leading redirection hides the verb: `> /tmp/log rm -rf <outside>`
   exits 0 and bash runs the `rm`. Also `2>/dev/null`, `2>&1`, `3>&1`, `>>f`, `&>`, `<<<`,
   `< /dev/null`; an array-element assignment prefix (`a[0]=1 rm …`); and the `xargs bash --rcfile
   foo -c "…"` asymmetry. It propagates into every frame type and into `bash -c` and `pwsh -c`. QA
   corrected two of the review's examples from measurement — `'' rm …` and `xargs sh --rcfile` are
   *not executable* — and found a bound nobody had stated: an **argv carrier rescues the class**
   (`timeout 5 2>/dev/null rm …` blocks).
4. **Non-literal and ANSI-C paths, and the unmodelled `cd`** — `rm -rf $HOME/x` and `rm -rf $'/etc/x'`
   resolve as literals and are judged in-project though bash executes them; `cd /tmp && rm -rf ./x`
   is evaluated but resolved against the guard's own cwd.
5. **Beyond 8192 characters** — content past the truncation point is unjudged (a severed here-doc
   terminator blocks rather than skips).
6. **The override authorizes the whole line**, deliberately — every chained position after a leading
   `HARNESS_ALLOW_OUTSIDE_RM=1`. It is the one place the guard is not chain-aware. Smuggling it
   mid-chain does **not** work: `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf <outside>` blocks.
7. **Scope** — `PreToolUse` governs only Claude Code's Bash tool; Write/Edit and other tools are
   unaffected (this is also the deliberate repair path for a bricked guard). And the PowerShell twin
   is unverified everywhere.
8. **By design, not a gap** — the verb set is nine verbs; `mv`, `cp` and `>` truncation stay
   unguarded, so `> /etc/passwd` allows on purpose. Depth > 2, unbalanced quotes and unterminated
   here-documents all **block** (fail-closed), and the over-block surface is a strict superset of the
   pre-v0.46 one.

---

## Files changed

`git diff --stat HEAD` reports 37 files / 5993 insertions / 539 deletions, but **that includes
T-13's and T-14's delivered-but-uncommitted work** (expected — this repo commits only when the
operator asks). Attributable to **T-17 alone**:

| File | Change |
|---|---|
| `.harness/scripts/guard-rm.sh` · `.ps1` | +772 / +751 — the position scanner, widened prefix strip, argv carriers, shell-interpreter branch, audited command-text override |
| `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` · `.ps1` | byte-identical twins (the **source**; the repo copies are written only by `sync-self`) |
| `.harness/scripts/test-guard-rm.sh` · `.ps1` | +227 / +194 — stride-4 row encoding, `[guard-path]` / `-Guard` argument, 17 → 87 rows |
| `evals/guard-rm-cases.md` | +115 — 87 rows, lockstep with both drivers |
| `.harness/rules/75-safety-hook.md` + `.md.tmpl` | +153 each — coverage claim replaces the first-token trigger; residual list; accepted over-blocks; measured latency band |
| `.harness/scripts/baseline.json` | `test_guard_rm_bash_assertions: 87` + note |
| `CHANGELOG.md` | the `[0.46.0]` entry |
| `docs/dev-map.md` | 2 lines |
| `CONTEXT.md` | the **Command position** term (added by the architect at stage 2) |
| `docs/features/guard-cmd-chain/` | 7 stage documents (untracked) |
| Version stamps ×4 | `0.44.0 → 0.46.0` (spans T-13/T-14's 0.45.0 too) |

**Not touched**: `verify_all.{sh,ps1}` by T-17 (no check added), `CONTEXT.md` by the developer,
`docs/proposals/frontier-gaps-2026-07.md` (untracked operator backlog — never opened, edited or
cited), and the frozen T-13 PowerShell items.

**Nothing is committed.**

---

## Next steps for the operator

1. **Run the PowerShell list** before the next release tag — 10 items, of which items 3 and 10 are
   security items. Read item 9's row count (87), not item 2's stale 81. Nothing about the bash green
   is evidence about the `.ps1`.
2. **Two follow-ups are recommended and deliberately NOT scheduled** (the pool belongs to the stream;
   inventing rows is not mine to do):
   - **Chunked indexing** for the O(n²) character scan — a 256-character window cuts the constant
     ~256× without changing the algorithm's shape. **Binding caveat**: any length cap introduced
     along the way must fail **closed** (BLOCK, not skip), or it becomes a trivial bypass.
   - **Pin the newly published residual class** with driver rows, accepting that this re-bases every
     tally quoted in this task's stage documents.
   - A third candidate, if the verb-hiding class is judged worth closing rather than disclosing: any
     fix must be flush-ward/over-blocking, because skipping a leading `>` token would turn the
     `>& rm` redirect-target boundary into a false block.
3. **Spot-check the NFR-1 waiver** — it is recorded with the measured figures, the root cause, the
   bounding facts, and the rubric lines it was decided on. Reversing it means reinstating a feasible
   number and scheduling the chunked-indexing work into scope.
4. The two other pool rows named in the dispatch (narrowing the gate's guard check; re-pointing the
   four command-derivation flows) were **not touched**, as instructed.

---

## Insight

- 2026-08-01 · A sentinel compared against a **derived index** must be outside that index's domain: `redir_i=-1` tested as `redir_i == i-1` is *true* at `i == 0`, so a guard's "was the previous character a redirect operator" memory fired on the very first character and appended a leading `&` instead of splitting on it — reopening a bypass (`pwsh -c "& Remove-Item …"`, since `&` is PowerShell's call operator) inside the fix that closed a different one. The fix's own comment asserted the wrong-index case could only over-block; at `i == 0` it under-blocked. Fix at the source (`-2`) rather than at the call site, and discharge the out-of-domain claim over the loop's actual bounds instead of assuming it. · evidence: guard-cmd-chain CR2-1, `guard-rm.sh:341`
- 2026-08-01 · A "this change is provably narrowing, so the differential need not be re-run" argument is exactly where the counterexample hides — here the set-inclusion claim `{new} ⊂ {old}` failed at precisely the one point that *was* the defect, and believing the argument is what made the case invisible. A second, independent flaw: "more flushes" is not "more positions", because a split *replaces* a combined position with fragments and the combined one is lost. Monotonicity claims about a security guard are measured against the **pre-change** baseline, never argued by set inclusion over an intermediate state. · evidence: guard-cmd-chain CR2-2 / DESIGN DRIFT 5
- 2026-08-01 · Editing a **live fail-closed `PreToolUse` hook** has one safe sequence, because the failure modes are asymmetric and both are silent: a syntax error exits 2 (indistinguishable from a BLOCK, kills every subsequent Bash call including the one that would fix it) while a runtime error under `set -uo pipefail` exits 1, which Claude Code treats as non-blocking — so the guard **fails open** and `bash -n` cannot see it. Stage the change in the **unwired template copy**, syntax-check it, drive it through a `[guard-path]` argument, then promote once via `sync-self`; recovery is Read+Write only, since `git checkout` is itself a Bash call and would be blocked. · evidence: guard-cmd-chain, three dev rounds with zero toolchain outages
- 2026-08-01 · `verify_all` exits **1 on `warns > 0`**, so a WARN is *not* status-neutral — the 200-line rule-fragment cap is a hard release gate, not advisory, and a 201-line rule document fails the "gate must PASS" criterion. An architect explicitly assumed the opposite. (Stage docs under `docs/features/` are, by contrast, genuinely unmeasured by the `I.*` group — that cap is policy without a mechanism.) · evidence: guard-cmd-chain gate R2.6, `verify_all.sh:823-825`
- 2026-08-01 · Command substitution strips trailing newlines, so a guard that reads its input through `$( … )` **never** sees a command string ending in a newline — which makes an unconditional "here-document body still open at end of input ⇒ parse failure" rule block essentially every `cat > f <<'EOF' … EOF` an agent writes, seizing the toolchain. Accept a here-document whose terminator is the final line; keep the genuinely unterminated case blocking. When a design rule and an acceptance criterion contradict, the criterion wins and the design is corrected. · evidence: guard-cmd-chain DESIGN DRIFT 1, AC-3 L9
- 2026-08-01 · A worst-case latency figure for a character-scanning guard varies by payload **shape**, not just length: at an identical 8192 characters, a dense `&&` chain ending in an empty position measured ~3.1 s while the same length ending in a real command measured ~2.2 s, and a here-doc truncated mid-body was *cheaper than pre-change* because it exits fail-closed early. Two "contradictory" measurements were both correct, of different lines. Publish a band with its shape-dependence, not four false-precision integers. · evidence: guard-cmd-chain QA MINOR-1 + round-2 re-measurement
