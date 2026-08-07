# Test Report — T-14 `hook-truth-status`

**Stage 6 (QA)** · Date 2026-07-31 · **deferred-human mode**: defer, do not ask (no `AskUserQuestion` called).

**Under test**: `skills/harness-status/SKILL.md` — a **skill document**, i.e. a procedure an agent executes.
Tested by *executing the procedure* (design §10.2: "run the procedure against root `R`") against this
repository and against fixtures, comparing output to §5.1-§5.4's pinned strings.

**Independence (adversarial rule 2).** QA's probe executor `exec_status.py` was written **from the shipped
`SKILL.md` text alone** (§0 Steps 0.1-0.5; §3b detection/extraction + 8-row table; §3c query plan, fallback
and state rules; §1's `Present?`; §6's `+1`; §7's fix table). It was **not** derived from
`04_IMPLEMENTATION.md`'s transcript, which was read only after P-1/P-2 were captured and is used solely as a
cross-check.

**Tally honesty (NFR-6).** Every count is pasted from the run that produced it, with its
`=== Summary ===` / `=== Result ===` banner. No count was derived by arithmetic.

**Fixtures (AC-11 / design §10.2)** live **outside** the repository, under
`…/scratchpad/qa-t14/fx/` (33 roots). Post-QA `git status --porcelain` shows zero leakage (§5).

**Self-declared soft-cap breach (disclosed, not hidden)**: this report is **672 lines** against the 500-line
per-stage-doc soft cap (`.harness/rules/70-doc-size.md:33`). No gate check enforces it (verified: `verify_all`
has no stage-doc size check; the same breach was filed as NIT-1 against `04` at 502 lines). The overage is
pasted **run output**, which the QA contract and NFR-6 require verbatim, not pasted *code*, which is what
Rule 1 ("reference, don't paste") targets. Trimming further would delete the evidence for the two MAJOR
findings. Flagged for PM rather than resolved unilaterally.

**Corrected expectations adopted from PM** — superseding design §10.1 step 3, §10.2's whole-repo line and
risk R-1 (`02_SOLUTION_DESIGN.md:566`): `test-supervisor.sh` expects **`PASS: 46 / FAIL: 0`** on this
python3-present host; `.harness/scripts/baseline.json:16` is **correct at `45`**, **out of bounds in either
direction**, and was not touched. `verify_all.sh` expects **PASS 32 / WARN 0 / FAIL 0**, check count 32. QA
corroborated the 45/46 split independently (§4).

---

## 1. Test plan

| AC | Probe(s) | Fixture / root | Result |
|---|---|---|---|
| AC-1 real-state guard verdict | P-1 | this repository, as-is | **PASS** (§3.1) |
| AC-2 real-state congruence | P-2 | this repository, as-is | **PASS** (§3.1) |
| AC-3 committed-settings project | P-3 + mutation | `fx/p3_committed`, `fx/p3_committed_mut` | **PASS** (§3.2) |
| AC-4 three states distinguishable | P-6, P-6b×3, P-6c, P-7, P-13 | `fx/p6_*`, `fx/p7_absent`, `fx/p13_malformed` | **PASS** (§3.3) |
| AC-5 never-installed clone | P-8 ×3 variants | `fx/p8_never{,_noclaude,_noinstaller}` | **PASS** (§3.4) |
| AC-6 opt-out distinct | P-9 ×2 variants | `fx/p9_optout{,_nokey}` | **PASS** (§3.4) |
| AC-7 fix-line reachability | P-10, P-10b (presence **and** absence) | `fx/p10_committed_dangling`, `fx/p10b_both_dangling` | **PASS** (§3.5) |
| AC-8 spec authority + fallback | P-17, P-18, **P-18b (QA-authored)** | `fx/p17_nospec`, `fx/p18_spec_exit2`, `fx/p18b_spec_partial` | **PASS** (§3.6) |
| AC-9 gate + frozen counts | `verify_all.sh` ×3, row/denominator greps | this repository | **PASS** (§4) |
| AC-10 pinned assertions | `test-supervisor.sh` ×10 + no-python3 emulation | this repository | **PASS** (§4) |
| AC-11 no hook behavior changed | porcelain delta vs `04:18-55` | this repository | **PASS** (§4) |
| AC-12 release-claim consistency | G.4 + manifest/CHANGELOG greps | this repository | **PASS** (§4) |

All of P-1…P-21 were executed except **P-19**, disclosed as discipline-based (§6). QA-authored additions:
**P-18b**, **P-20-order-AB/BA** (the design's P-20 fixture could not distinguish its two entries — §3.7),
**ADV-1** (`hooks` of wrong JSON type), **ADV-2** (§7 key overlap).

---

## 2. Adversarial tests (one hypothesis per acceptance criterion)

Each row states the failure predicted **before** the run; the reproducer is QA's, not the Developer's; the
outcome cites pasted tool output. "Survived" = the implementation held against a test built to break it.

| AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, QA-authored) | Outcome |
|---|---|---|---|
| AC-1 | …§0 mis-reads `"hooks": {}` in the committed file as "declares hooks", so the report still names `.claude/settings.json` or reports non-healthy | `exec_status.py <repo>` | **Survived** §3.1 |
| AC-2 | …§3c keeps its own path and reports `not wired` while §3b reports wired — the two sections disagreeing about one file | same run, §3c block | **Survived** §3.1 |
| AC-3 | …machine-local-first precedence regresses the committed arrangement to `Hook source: none` or row 4 | `fx/p3_committed` | **Survived** §3.2 |
| AC-4 | …a dangling wiring reaches row 8 via the multi-path quantifier, or a mention-only decoy buys `+1` | `fx/p6b_chain_*` (3 legs), `fx/p6c_mention` | **Survived** §3.3; one **disclosed residual reproduced** (MINOR-4) |
| AC-5 | …the never-installed clone prints the guard as switched off | `fx/p8_never`, `fx/p8_never_noclaude` | **Survived** §3.4 |
| AC-6 | …opt-out and never-installed collapse to one sentence, or `<shape>` misreports which shape was seen | `fx/p9_optout`, `fx/p9_optout_nokey` | **Survived** §3.4 |
| AC-7 | …the `machine-local ∧ OTHER_DECLARES = true` branch still chains `&& …/install-hooks` (the *wrong instruction* the finding was about) | `fx/p10b_both_dangling` + explicit **absence** grep | **Survived** §3.5 |
| AC-7 (2nd) | …some *other* non-healthy state selects a fix line that cannot reach the file it named | `fx/p11_unreadable` under both readings of `SKILL.md:219` vs `:345` | **FAILED — MAJOR-2** §7 |
| AC-8 | …a spec that answers some queries then fails leaves partial output mixed into the fallback | `fx/p18b_spec_partial` (spec returns a **reversed** id order, then exits 2) | **Survived** §3.6 |
| AC-9 | …the rewrite trips I.6, or the insight index exceeds 30 lines, or the check count moved | `verify_all.sh` ×3 | **Survived** §4 |
| AC-10 | …the §1 row edit re-wrapped the pinned note and broke a fan-out assertion; and/or `45` is right for this host | `test-supervisor.sh` ×10 + **no-python3 shim** | **Survived** §4 |
| AC-11 | …a fixture or stray edit leaked into the tree | post-QA porcelain diffed against `04:18-55` | **Survived** §4 |
| AC-12 | …Branch A left G.4 without a heading for the manifest version | G.4 row + greps | **Survived** §4 |
| **FR-18 (cross-cutting)** | …§0 Step 0.1's table is **not total**, so two agents produce opposite verdicts on one input | `fx/adv_hooks_wrongtype` run under both defensible readings | **FAILED — MAJOR-1** §7 |

---

## 3. Probe evidence

### 3.1 P-1 / P-2 — AC-1, AC-2, captured against this repository as it stands

```
$ python3 exec_status.py /home/alan/Programs/harness-kit
  C1 .claude/settings.local.json -> present
  C2 .claude/settings.json -> empty
  UNKNOWN_FILES=[]  SOURCE=.claude/settings.local.json  SOURCE_KIND=machine-local  OTHER_DECLARES=False  MACHINE_STATE=installed

Hook source:  .claude/settings.local.json (machine-local settings)                  — committed .claude/settings.json declares no lifecycle hooks

  [derivation] K=1 PATHS=['.harness/scripts/guard-rm.sh'] GUARD_PATHS=['.harness/scripts/guard-rm.sh'] MISSING=[] -> ROW 8
Sub-agent dispatch:  enabled (Claude Code via Task tool)
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash")
  guard entries matched:  1
  matcher:  "Bash"
  interpreter:  sh (on PATH)
  PreToolUse hook row Present? = YES (row 8)     |     §6 guard health point = +1

  [spec] tools rc=0 / event×4 rc=0 / matcher guard-rm rc=0 'Bash' / semantics guard-rm rc=0 'fail-closed'
  [spec usable] True (invocations attempted: 7)
Hook congruence (from .claude/settings.local.json):
  Stop:              ok
  PreToolUse:        ok
  UserPromptSubmit:  ok
  SessionStart:      ok
```

- **AC-1 met**: guard **installed and wired**; effective hook source named `.claude/settings.local.json`.
- **AC-2 met**: four congruence rows, **all `ok`**, same source named; no event reported `not wired`.
- **D-2 asserted, not recomputed**: the run shows **7** spec invocations (`N+3`), the count pinned in the
  product at `SKILL.md:236` and stated at `04:125-131`.
- Byte-consistent with `04:281-375`, reached independently.

**Non-vacuity of the whole task.** The **pre-edit** procedure (`git show HEAD:skills/harness-status/SKILL.md`,
lines 68-80: *"computed by parsing `.claude/settings.json`"*, `DISABLED — … if the array is absent"*, and §3c
reading `.claude/settings.json`) against **unchanged** repository state — where `.claude/settings.json`
declares `"hooks": {}` — yields `DISABLED — .claude/settings.json has no PreToolUse for Bash` and four
`not wired` rows. **The same input flips the verdict across the edit; P-1/P-2 are not vacuous.**

### 3.2 P-3 / P-4 / P-5 — AC-3, B-1, B-2, B-3, FR-4, with mutations

```
################ p3_committed              (committed wires guard, NO machine-local file)
Hook source:  .claude/settings.json (committed settings)       — no machine-local settings file declares hooks
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.json; matcher "Bash")
  §6 guard health point = +1

################ p3_committed_mut          (ONE input flipped: guard-rm.sh deleted)
  [derivation] ... MISSING=['.harness/scripts/guard-rm.sh'] -> ROW 7
Safety hook:         WIRING DANGLING — .claude/settings.json wires "sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'" -> missing .harness/scripts/guard-rm.sh
  §6 guard health point = 0
=== §7 fix line ===  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json

################ p5_both                   (B-3 / FR-4)
Hook source:  .claude/settings.local.json (machine-local settings)                  — .claude/settings.json ALSO declares lifecycle hooks; verdicts below come from the machine-local file only
```

The AC-3 mutation flipped row 8 → row 7, left the `Hook source:` line unchanged and changed only the
`PreToolUse` congruence row — **nothing unrelated moved**. P-4 (`fx/p4_local`, B-2) → machine-local named,
row 8, `+1`.

### 3.3 P-6 / P-6b / P-6c / P-7 / P-13 — AC-4 and the row 6/7/8 boundary, both directions

The gate's round-1 false-green lived here, so this was probed hardest.

| Leg | Wired command | Disk state | Row | Point |
|---|---|---|---|---|
| P-6 | single-path guard command | guard deleted | **7** | 0 |
| P-6b leg 1 | chained `guard-rm.sh && harness-sync.sh` | guard deleted | **7** | 0 |
| P-6b leg 2 | same chained command | **sync** deleted, guard present | **7** | 0 |
| P-6b leg 3 | same chained command | both present | **8** | +1 |
| P-6c | `echo checking guard-rm.sh; bash …/harness-sync.sh` | all present | **6** | 0 |
| P-7 | PreToolUse present, no guard-rm reference | all present | **4** | 0 |
| P-13 | `bash {{SCRIPTS_DIR}}/guard-rm.sh` | n/a | **5** | 0 |

```
################ p6b_chain_guardmissing
  [derivation] K=1 PATHS=['…/guard-rm.sh', '…/harness-sync.sh'] GUARD_PATHS=['…/guard-rm.sh'] MISSING=['…/guard-rm.sh'] -> ROW 7
Safety hook:         WIRING DANGLING — … wires "sh -c 'cd "$CLAUDE_PROJECT_DIR" && bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'" -> missing .harness/scripts/guard-rm.sh

################ p6b_chain_syncmissing      <- the OTHER member of PATHS missing
  [derivation] ... MISSING=['.harness/scripts/harness-sync.sh'] -> ROW 7

################ p6b_chain_bothpresent
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash"; all 2 extracted paths exist)
  §6 guard health point = +1

################ p6c_mention
  [derivation] K=1 PATHS=['.harness/scripts/harness-sync.sh'] GUARD_PATHS=[] -> ROW 6
Safety hook:         WIRING DANGLING — … wires "sh -c 'echo checking guard-rm.sh; bash .harness/scripts/harness-sync.sh'" -> no extractable scripts/guard-rm.{sh,ps1} path in this command
  §6 guard health point = 0

################ p7_absent
Safety hook:         WIRING ABSENT — .claude/settings.local.json declares no PreToolUse entry referencing guard-rm
  PreToolUse hook row Present? = NO (row 4)
```

Row 8's `|PATHS| > 1` form (`all 2 extracted paths exist`) is exercised for the first time in this pipeline —
it is unreachable from this repository (gate Q-11). **Both directions of the boundary flip on a single-input
mutation**, so no leg is vacuous.

**Gate condition F-10 asserted exactly as the Developer stated it** (`04:98-108`): P-7's row-4 output contains
none of `guard entries matched:`, `matcher:`, `interpreter:` — confirmed above. **Gate condition F-9 asserted
as written and NOT generalised** — see MINOR-4.

**B-8 cross-file note** (`fx/b8_crossfile`: source has no guard entry, the other file does):

```
Safety hook:         WIRING ABSENT — .claude/settings.local.json declares no PreToolUse entry referencing guard-rm
  .claude/settings.json also declares a PreToolUse entry referencing guard-rm; this report's verdicts come from the effective hook source only (§0).
```

### 3.4 P-8 / P-9 — AC-5, AC-6: the two sentences must differ

```
################ p8_never                        (machine-local ABSENT)
Hook source:  none — consulted .claude/settings.local.json (absent) and .claude/settings.json (empty)
Safety hook:         NOT INSTALLED ON THIS MACHINE — no lifecycle hooks in .claude/settings.local.json (absent) or .claude/settings.json
=== §7 fix line ===  .harness/scripts/install-hooks

################ p8_never_noclaude               (B-6: no .claude/ at all)
Hook source:  none — consulted .claude/settings.local.json (absent) and .claude/settings.json (absent)
Safety hook:         NOT INSTALLED ON THIS MACHINE — …        (no crash, no fabricated verdict)

################ p8_never_noinstaller            (OQ-10a: installer absent)
=== §7 fix line ===  run /harness-adopt or /harness-upgrade

################ p9_optout                       (machine-local {"hooks":{}})
Safety hook:         HOOKS OFF (machine-local opt-out) — .claude/settings.local.json is present with "hooks": {}; the documented persistent opt-out
=== §7 fix line ===  documented persistent opt-out; no action

################ p9_optout_nokey                 (machine-local with NO hooks key)
Safety hook:         HOOKS OFF (machine-local opt-out) — .claude/settings.local.json is present with no "hooks" key; the documented persistent opt-out
```

AC-5 met: never-installed sentence + installer fix line, and **no string reporting the guard as switched off**
(row 3 did not fire; the retired `DISABLED …` string has 0 occurrences in the product — §4). AC-6 met: the two
sentences differ and `<shape>` reports the shape actually seen. **Mutations**: `absent → empty` on C1 alone
flips row 2 → row 3 and nothing else; removing `install-hooks.sh` flips only the fix line.

### 3.5 P-10 / P-10b — AC-7, presence **and** absence

```
################ p10_committed_dangling   (SOURCE_KIND = committed)
=== §7 fix line ===  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json

################ p10b_both_dangling       (machine-local ∧ OTHER_DECLARES = true)
=== §7 fix line ===  rm .claude/settings.local.json — .claude/settings.json already declares lifecycle hooks, so removing the machine-local file re-resolves this report (and Claude Code) to the committed wiring. Do NOT chain the installer: it exits early with "Committed settings already declares lifecycle hooks - no machine-local file created" and writes nothing. If the committed wiring is itself stale, run /harness-upgrade after the removal.

$ python3 exec_status.py fx/p10b_both_dangling | grep -c '&& .harness/scripts/install-hooks'
0        <- the chained installer string is ABSENT, as required
```

The **absence** half — the load-bearing half, because the finding was a *wrong* instruction — holds. The third
branch (`machine-local ∧ OTHER_DECLARES = false`, `fx/p6_dangling`) correctly prints
`rm .claude/settings.local.json && .harness/scripts/install-hooks — …`. **All three `SOURCE_KIND ×
OTHER_DECLARES` branches are separated by a single-input flip** (`OTHER_DECLARES` false→true swaps branch 2
for branch 3 and changes no other line).

### 3.6 P-17 / P-18 / P-18b — AC-8, B-15, B-16: the fallback must be whole-answer

```
################ p17_nospec               (no .harness/scripts/hook-spec.sh)
  [spec usable] False (invocations attempted: 0)
Hook congruence (from .claude/settings.local.json) — (fallback enumeration — hook wiring spec unavailable):
  Stop / PreToolUse / UserPromptSubmit / SessionStart:  ok

################ p18_spec_exit2           (spec exits 2 for `event`)
  [spec] tools rc=0 out='harness-sync\nguard-rm\nambient-prompt\nambient-reset'
  [spec] event harness-sync rc=2 out=''
  [spec usable] False (invocations attempted: 2)
Hook congruence (from .claude/settings.local.json) — (fallback enumeration — hook wiring spec unavailable):
```

**P-18b is QA-authored and is the sharper test.** P-18 as designed cannot detect partial mixing, because the
spec's row order and the fallback's row order coincide. P-18b stubs the spec to answer `tools` and all four
`event` queries **successfully but in reversed order**, then exit 2 on `matcher guard-rm`:

```
################ p18b_spec_partial
  [spec] tools rc=0 out='ambient-reset\nambient-prompt\nguard-rm\nharness-sync'
  [spec] event ambient-reset rc=0 out='SessionStart'      (…and three more, all rc=0)
  [spec] matcher guard-rm rc=2 out=''
  [spec usable] False (invocations attempted: 6)
Hook congruence (from .claude/settings.local.json) — (fallback enumeration — hook wiring spec unavailable):
  Stop:              ok
  PreToolUse:        ok
  UserPromptSubmit:  ok
  SessionStart:      ok
```

Five successful spec answers were **discarded**: row order reverted to the fallback's
`Stop / PreToolUse / UserPromptSubmit / SessionStart`, not the spec's reversed order. **No partial mixing;
design risk R-6 closed with evidence.** AC-8's second half verified by reading `SKILL.md:241-246` — the
fallback carries **event names only**, and no id → event/matcher/semantics table exists in the product
(see NIT-1 for the two guard-specific literals the fallback legitimately needs).

### 3.7 Boundary probes P-11…P-21 and QA additions

| Probe | Input | Result |
|---|---|---|
| P-11 (B-7) | machine-local truncated JSON, committed wires a healthy guard | `Hook source: UNKNOWN — …`; row **1**; **no** health point; no healthy claim |
| P-11b (QA) | byte-broken but brace-delimited `{ "hooks": { "PreToolUse": [ }` | same — exercises design F-4's divergence-table row 2 |
| P-11c (QA) | `.claude/settings.local.json` is a **directory** | same — exercises divergence-table row 1 (stricter than `install-hooks.sh:74-76`) |
| P-12 (B-10) | matcher `*` / absent / `Bash\|Write` | all row **8**, matcher printed verbatim, all flagged `— non-canonical matcher`; never downgraded to `WIRING ABSENT` |
| P-13 (B-12) | `bash {{SCRIPTS_DIR}}/guard-rm.sh` | row **5** `MALFORMED`, §3c `MALFORMED — unsubstituted placeholder`, no point |
| P-14 (B-11) | `bash scripts/guard-rm.sh`, old-layout file present | extracted → row **8** |
| P-15 (B-19) | `build-scripts/deploy.sh` wired on `Stop`, file **absent** | `Stop: ok` — not extracted, not flagged. Non-vacuous: had it been extracted, the absent file would render `DANGLING` |
| P-16 (B-13) | `.ps1` twin wired, only `.sh` on disk | row **7** on the referenced `.ps1`; the present `.sh` twin does not rescue it (OQ-4a) |
| P-20 (B-9) | see below | order decides the verdict; `K >= 2` adjunct names it |
| P-21 (B-14) | `pwsh …guard-rm.ps1`, `command -v pwsh` empty on this host, path present | row **8** *unchanged* by interpreter availability, plus the adjunct below |

```
################ p21_pwsh
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash")
  interpreter:  pwsh — NOT on PATH; the guard is fail-closed, so this BLOCKS Bash tool calls rather than silently disarming the guard
```

`<semantics>` was substituted from `hook-spec semantics guard-rm` (gate condition F-11, as stated at
`04:110-131`). See MINOR-3 for the part of P-21's *design assertion* that is not satisfiable as written.

**P-20 rebuilt by QA.** The design's P-20 fixture as first constructed could not distinguish its two entries:
a second entry referencing `guard-rm-missing.sh` does not contain the detection substring `guard-rm.sh`, so
`K` stayed 1 and the probe was vacuous. Rebuilt with entry A = `.harness/scripts/guard-rm.sh` (exists) and
entry B = `scripts/guard-rm.sh` (absent), so document order changes the **verdict**:

```
################ p20_order_AB
  [derivation] K=2 PATHS=['.harness/scripts/guard-rm.sh'] -> ROW 8
  guard entries matched:  2 — first in document order evaluated (from .claude/settings.local.json)

################ p20_order_BA          <- only the two entries' order flipped
  [derivation] K=2 PATHS=['scripts/guard-rm.sh'] MISSING=['scripts/guard-rm.sh'] -> ROW 7
Safety hook:         WIRING DANGLING — .claude/settings.local.json wires "bash scripts/guard-rm.sh" -> missing scripts/guard-rm.sh
  guard entries matched:  2 — first in document order evaluated (from .claude/settings.local.json)
```

B-9 holds and is **not** vacuous: the evaluated entry follows document order, not content.

---

## 4. Whole-repo checks — AC-9, AC-10, AC-11, AC-12

**AC-9 — `bash .harness/scripts/verify_all.sh`** (32 named check rows printed, all `PASS`; tail pasted):

```
[F.2] Guard-rm scripts and PreToolUse wiring present ... PASS
[I.4] insight-index.md ≤30 evidence lines ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0

real	0m10.594s
```

Frozen counts, pasted from the commands that produced them:

```
$ awk '/^\| Asset \| Path \| Present/,/^$/' skills/harness-status/SKILL.md | grep -c '^| '
15                                    # 1 header + 14 data rows -> 14 required-asset rows
$ grep -n 'All 14 required assets\|Total possible' skills/harness-status/SKILL.md
313:- All 14 required assets present → +6 health points
320:- Total possible: 12
$ grep -c 'DISABLED — .claude/settings.json has no PreToolUse for Bash' skills/harness-status/SKILL.md
0
$ grep -c '^- ' .harness/insight-index.md
30                                    # I.4 cap intact; index NOT hand-edited by QA
```

**AC-10 — `bash .harness/scripts/test-supervisor.sh`** (tail pasted):

```
--- Doc fan-out spot checks ---
  PASS  fan-out: AI-GUIDE.md mentions 'auxiliary (supervisor)' phrasing
  PASS  fan-out: harness-status SKILL.md notes framework agents (7 + supervisor) are plugin-provided
  PASS  fan-out: harness-status SKILL.md retired the canonical-7 asset glob (v0.30 truth)

=== Result ===
  PASS: 46
  FAIL: 0
```

Structural pin intact — `grep -nE '\(7 \+ supervisor\).*plugin-provided' skills/harness-status/SKILL.md` →
`105:` one unbroken line; `grep -cF '{pm,req,sol,gate,dev,review,qa}*'` → `0`.

**QA corroborated the 45/46 split rather than accepting it.** A stub `python3` exiting non-zero was placed
first on `PATH` (the driver's gate is `command -v python3 && python3 -c 'import json'`,
`test-supervisor.sh:293`, no `else` branch):

```
$ PATH="$SHIM:$PATH" bash .harness/scripts/test-supervisor.sh
=== Result ===
  PASS: 45
  FAIL: 0
$ sed -n '16p' .harness/scripts/baseline.json
  "test_supervisor_bash_no_python3_assertions": 45,
```

`baseline.json:16` is **correct as `45`** and was **not touched**. AC-10's basis is self-comparison on one
host (46 → 46 across this task's edits), as `04:255-270` states.

**AC-11** — porcelain delta against the Developer's pre-edit baseline (`04_IMPLEMENTATION.md:18-55`), captured
after all fixture work:

```
$ diff pre_edit.txt post_qa.txt
29a30
>  M skills/harness-status/SKILL.md
$ git status --porcelain | grep -ci 'qa-t14\|fx/'
0
```

Exactly **one** added porcelain line, and it is §7.3 IN row 1 (`CHANGELOG.md` and
`docs/features/hook-truth-status/` were already in the baseline). **No fixture leaked into the tree.** No
`.ps1`, no `verify_all`, no driver, no settings file, no installer, no template was modified.

**AC-12** — `plugin.json:4` `"version": "0.45.0"`; `CHANGELOG.md:8` `## [0.45.0] - 2026-07-31`;
`CHANGELOG.md:42` `### Fixed — hook-truth-status (T-14): …`; G.4 `PASS`; `git tag --list 'v0.45.0*'` empty and
HEAD `cb0ed57` → **Branch A confirmed live**, no version stamp moved.

**R-7 audit (no section re-reads a settings path).** Every `.claude/settings` occurrence in the product
classified: `:21-22` = §0 candidate definitions (**the only read sites**); `:67-70`, `:162-163`, `:340-342` =
pinned output strings and fix lines; `:352` = the anti-pattern forbidding re-reads. No read instruction exists
outside §0.

---

## 5. Guard interaction during fixture work (design §10.2 teardown paragraph)

The destructive-command guard was **not** disabled, weakened, unwired or worked around at any point. QA
changed no settings file, hook script or gate check.

```
$ printf '{"tool_input":{"command":"rm -rf <SCRATCH>/fx/p3_committed_mut"}}' | bash .harness/scripts/guard-rm.sh
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: rm -rf /tmp/claude-1000/…/qa-t14/fx/p3_committed_mut
  Offending path(s):
    - /tmp/claude-1000/…/qa-t14/fx/p3_committed_mut (outside /home/alan/Programs/harness-kit)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
exit=2

$ printf '{"tool_input":{"command":"rm -rf <SCRATCH>/fx/p3_committed_mut"}}' | HARNESS_ALLOW_OUTSIDE_RM=1 bash .harness/scripts/guard-rm.sh
harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.
exit=0
```

The **live PreToolUse hook** also fired on one QA Bash call and blocked it — auditable evidence that the guard
this task reports on is genuinely armed in this session:

```
PreToolUse:Bash hook error: [sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh']:
harness-kit guard-rm: BLOCKED — could not parse nested pwsh command safely; override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.
```

Teardown line actually used, override scoped to that single call:

```
$ HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf "$PWD/fx/p20_two_b" "$PWD/fx/p20_two_b_flipped"
removed the two superseded P-20 fixtures
```

An out-of-band finding surfaced while doing this — **CRITICAL-OOB-1**, §7. It concerns
`.harness/scripts/guard-rm.sh`, which this task does not touch, and is **not** a T-14 delivery blocker.

---

## 6. P-19 — disclosed as discipline-based, **not** a mechanical pass

Design §10.2 states P-19 "rests on QA *not* using Bash, which no mechanism enforces". Honored and
strengthened:

- **Tools actually available to this QA agent**: `Read`, `Write`, `Edit`, `Bash`. **No `Glob` tool is exposed
  to me**, though the skill's frontmatter lists it, so a fully faithful `Read`+`Glob` execution was impossible.
- **Genuinely shell-free**: the settings files of `fx/p6_dangling` and `fx/p7_absent` were read with the
  `Read` tool, and §0 Steps 0.1-0.5 plus §3b detection/extraction were derived by hand from those reads —
  `fx/p6_dangling`: C1 parses, `hooks` has 4 keys → `present` → `SOURCE`, `machine-local`; PreToolUse command
  contains `guard-rm.sh` → `K = 1`; the space-preceded `.harness/scripts/guard-rm.sh` satisfies the left bound
  → `PATHS = GUARD_PATHS = {that path}`. `fx/p7_absent`: no `guard-rm` substring → `K = 0` → row 4.
- **Not shell-free**: script existence was confirmed with a directory listing issued through `Bash` (`ls`),
  for want of `Glob`. It showed `guard-rm.sh` **absent** from `fx/p6_dangling` and **present** in
  `fx/p4_local`, giving row 7 and row 8 — matching the executor.
- **Conclusion**: all three FR-5 states were reproduced without executing the *procedure* through a shell, but
  **P-19 is reported as a discipline-based, partially-satisfied probe, never as a mechanical pass.** B-18
  remains rule-verified, not mechanically verified.

---

## 7. Defects found

### MAJOR-1 — §0 Step 0.1's four-state table is not total, and one reading is the false-green direction

The `present`/`empty` conditions both presuppose `hooks` is an *object*. A settings file that parses as a JSON
object whose `hooks` value is an **array** matches **no** row: not `absent`; it *does* parse as a JSON object
so not `unreadable` by the stated condition; there **is** a `hooks` key and it is **not** "an object with zero
keys" so not `empty`; and not "an object with ≥ 1 key" so not `present`.

**Reproducer** — `fx/adv_hooks_wrongtype`: C1 = `{ "hooks": [] }`, C2 wires a healthy guard:

```
### Reading A — wrong-typed `hooks` treated as `unreadable`
  C1 -> unreadable   UNKNOWN_FILES=['.claude/settings.local.json']   MACHINE_STATE=unknown
Hook source:  UNKNOWN — .claude/settings.local.json exists but could not be read or parsed; hook verdicts below are not certified
Safety hook:         UNKNOWN — .claude/settings.local.json could not be read or parsed; guard state undetermined
  §6 guard health point = 0

### Reading B — wrong-typed `hooks` treated as `empty` (declares no hooks)
  C1 -> empty        UNKNOWN_FILES=[]                                MACHINE_STATE=installed
Hook source:  .claude/settings.json (committed settings)       — no machine-local settings file declares hooks
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.json; matcher "Bash")
  §6 guard health point = +1
```

**Same input, opposite verdicts and opposite health points**, from two readings the document does not
adjudicate. This is the FR-18 property AC-1's determinism check protects, and Reading B is the direction OQ-5
rejected — a healthy guard verdict printed while a settings file Claude Code loads is structurally broken.
Rows 6/7/8's quantifiers cannot help: the divergence happens upstream, in §0.

**File**: `skills/harness-status/SKILL.md:26-31`. **Violates**: FR-18; NFR-1-directional. **Severity**: MAJOR
— no AC asserts this input and every named boundary B-1…B-20 holds, but it is a live FR-18 hole with a safety
direction. **Suggested remediation** (Developer's call): extend the `unreadable` row with "…or the top-level
`hooks` value is present but is not a JSON object" — the NFR-1-safe direction, consistent with the table's
stated "deliberately stricter than the installer" posture.

### MAJOR-2 — §7's fix-line table has overlapping keys and no precedence rule; one reading violates FR-8

§7 mixes two key families — rows 1-3 on `SOURCE_KIND`, rows 4-6 on `MACHINE_STATE` — with **no "first match
wins"** statement (unlike §3b, which has one). In the B-7 / P-11 state (`MACHINE_STATE = unknown` **and** a
candidate still resolves, so `SOURCE_KIND = committed`) **two rows match**, and `SKILL.md:219` compounds it by
telling the reader the fix line is "keyed on `SOURCE_KIND`".

**Reproducer** — `fx/p11_unreadable` (machine-local truncated JSON, committed wires a healthy guard):

```
### Reading 1 — the §7 row `MACHINE_STATE = unknown` (SKILL.md:345) wins:
  inspect .claude/settings.local.json — it is loaded by Claude Code but this report could not parse it

### Reading 2 — SKILL.md:219 says the fix line is keyed on SOURCE_KIND (= committed here):
  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json
```

Reading 2 prints `/harness-upgrade` — which rewrites `.claude/settings.json` — as the repair for a report
whose §0 line just named `.claude/settings.local.json` as the unparseable file. That is exactly the FR-8
prohibition this task exists to enforce ("The report never prints a fix instruction that cannot reach the file
it named"), reached from the shipped text with no judgment call.

**File**: `skills/harness-status/SKILL.md:219` vs `:338-345`. **Violates**: FR-8 (absolute), FR-18.
**Severity**: MAJOR — the guard verdict, the health point and every AC-7-asserted branch are unaffected; only
the UNKNOWN state's fix line diverges. **Suggested remediation**: state "first match wins" over the §7 table
with `MACHINE_STATE = unknown` first, or re-word `:219` to "keyed on §0's result".

### MINOR

- **MINOR-1** · `SKILL.md:41`, `:71`, `:161` — `UNKNOWN_FILES` is a list but §0 form 5 and §3b row 1 render a
  singular `<file>`; and Step 0.2's "every hook line carries the not-certified qualifier" (`:44`) pins no
  wording or placement. All three P-11 variants print `Hook source: UNKNOWN — .claude/settings.local.json …`
  directly above `Hook congruence (from .claude/settings.json):` with no sentence tying the two "sources"
  together, and my executor emitted no qualifier at all without the document saying that is wrong. The
  **verdict** (row 1, no point) is unaffected — output divergence, not verdict divergence. Same defect the
  code review filed as MINOR-3 (`05_CODE_REVIEW.md:55`), now confirmed by execution. **Owner**: PM (backlog).
- **MINOR-2** · `SKILL.md:288-290` — the §3c interpreter WARN tells the reader to "see the `_doc_sync_hook` /
  `_ambient_hook` notes in `settings.json`". Verified: `grep -c '_doc_sync_hook\|_ambient_hook'` returns `0`
  for **both** live settings files; the only file carrying those keys is
  `skills/harness-init/templates/common/.claude/settings.json.tmpl`. An advisory that cannot reach the file it
  names is FR-8's class, inside the section this task de-hardcoded. Design §3.4 lists this WARN as
  **unchanged**, so it is *not* developer drift. Same as code review MINOR-2, now confirmed by grep.
  **Owner**: PM (backlog).
- **MINOR-3** · design §10.2 **P-21 is not satisfiable as written**. It requires that "no command-rewrite
  proposal appears **anywhere in the output**", but §3c's design-frozen WARN (`SKILL.md:288-290`) instructs the
  report to "swap the command variant" for exactly P-21's input (a `pwsh` first token not on PATH). FR-10 is
  **not** violated — it forbids rewriting a *runnable* variant, and `pwsh` is not runnable here — so the
  product is compliant and the **probe specification** is wrong. I scoped my P-21 assertion to §3b's output
  (where no rewrite proposal appears) and disclose the narrowing rather than claim the broader assertion.
  **Owner**: PM (probe-spec correction at archive time).
- **MINOR-4** · gate F-9's disclosed residual is live and now has a reproducer. `fx/p6c_f9residual`, command
  `sh -c 'cd "$CLAUDE_PROJECT_DIR" && echo see .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'`:

```
  [derivation] K=1 PATHS=['…/guard-rm.sh', '…/harness-sync.sh'] GUARD_PATHS=['…/guard-rm.sh'] MISSING=[] -> ROW 8
Safety hook:         installed and wired (… matcher "Bash"; all 2 extracted paths exist)      §6 guard health point = +1
```

  An extractable, existing guard path in a **non-executing** position buys `+1` on a command that never
  invokes the guard. This is precisely the bound the Developer recorded at `04:80-96` under gate condition
  §R2-8.1, and the shipped text correctly qualifies its own claim ("in a non-extractable position",
  `SKILL.md:177`). **P-6c is asserted as written and NOT generalised to "any mention"**, per that condition.
  Record-only; unreachable through harness-generated wiring (`hook-spec.sh:99-114`). QA also reproduced code
  review MINOR-4's sibling residual: `fx/p12_compound`, matcher `Bash|Write` → row 8 `+1` with only a
  `— non-canonical matcher` suffix, though such an entry never fires on a Bash call. **Owner**: PM (backlog).

### NIT

- **NIT-1** · `SKILL.md:204`, `:209` hard-code the spec's current answers (`Bash`, `fail-closed`). Design §3.2
  explicitly licenses these as the **fallback** values, so this is design-faithful and is not AC-8's "second
  hand-maintained list" (the id → event/matcher/semantics table is absent, as required). Still a drift hazard
  if `hook-spec.sh` ever changes those answers. Record-only.

### Out-of-band — different component, **not** a T-14 defect, **not** a delivery blocker

- **CRITICAL-OOB-1** · `.harness/scripts/guard-rm.sh` inspects only the first verb of each top-level **pipe**
  segment, so a destructive command after `&&`, `;`, or via `xargs` is never examined. Found while performing
  the design-mandated fixture teardown: an outside-repo `rm` issued as a `&&`-chained Bash tool call passed
  the live hook, while the same `rm` standalone is blocked. Characterized against source (`guard-rm.sh`
  `split_pipes` splits on `|` only; `classify_segment` takes `tokens[0]` as the verb) and reproduced:

```
rm /tmp/x/a                                   -> exit=2      (BLOCKED)
echo hi && rm /tmp/x/a                        -> exit=0      (ALLOWED)
true; rm /tmp/x/a                             -> exit=0      (ALLOWED)
rm /tmp/x/a | cat                             -> exit=2      (BLOCKED)
cat /etc/hostname | xargs -I{} rm /tmp/x/a    -> exit=0      (ALLOWED)
```

  **Why it is not a T-14 defect**: this task changes no hook script (out-of-scope §12.3; AC-11 verified), and
  FR-5's *installed and wired* is a statement about **wiring**, which on this repository is genuinely present
  and resolves to a real script — P-1's row-8 verdict stands. **Why it must be raised**: NFR-1 is a binding
  project-level safety requirement, the health report now confidently reports this guard as healthy, and QA
  relied on the guard's blocking behavior for its own teardown plan. **Owner**: PM — file a new task against
  `.harness/scripts/guard-rm.{sh,ps1}`. QA made **no** change to the guard.

---

## 8. Stability and non-functional observations

| Suite | Runs | Result |
|---|---|---|
| `bash .harness/scripts/verify_all.sh` | 3 | `PASS: 32 / WARN: 0 / FAIL: 0` every run — no flake |
| `bash .harness/scripts/test-supervisor.sh` | 10 | `PASS: 46 / FAIL: 0` every run — no flake |
| `exec_status.py` over 33 fixtures + this repository | 2 full sweeps | identical output both sweeps |

```
=== Summary ===   PASS: 32   WARN: 0   FAIL: 0   <- run 1
=== Summary ===   PASS: 32   WARN: 0   FAIL: 0   <- run 2
=== Summary ===   PASS: 32   WARN: 0   FAIL: 0   <- run 3
=== Result ===   PASS: 46   FAIL: 0   <- runs 1-10, all identical
```

**Test-count movement**: `verify_all` 32 → 32; `test-supervisor` 46 → 46 (python3-present, self-comparison),
45 under no-python3 emulation matching `baseline.json:16`. **New automated tests added to the project suite:
0, deliberately** — the product is a skill *document* with no executable test surface, and design §12.4 /
OQ-7a forbid adding a `verify_all` check or a `test-supervisor` assertion in this task. QA's coverage is the
21-probe protocol plus 8 QA-authored probes, all captured above; executor and fixtures live outside the tree.
**Baseline updated: NO — correctly.** `.harness/scripts/baseline.json` and `.harness/insight-index.md` were
not touched by QA; no count in either moved.

**Determinism check (design §10.2's closing requirement)**: P-1 and P-3 executed by an executor written
independently of `04`'s transcript produced the same verdict tokens and the same named source. That is one
independent re-derivation, not two agents; the two FR-18 holes found are on inputs P-1/P-3 do not reach.

**Performance**: no perf NFR was stated. NFR-4's cost bound was observed rather than benchmarked — every run
performed at most two settings-file reads and exactly 7 spec invocations (`N+3`, the accepted D-2 deviation),
no repository-wide scan. `verify_all` `real 0m10.594s`; `test-supervisor` `real 0m0.172s`.

**NFR-5 (cross-shell honesty)**: this task touches no `.ps1` (AC-11 delta confirms). **QA performed no
PowerShell verification and claims none** — `hook-spec.ps1`, `test-supervisor.ps1` and `verify_all.ps1` were
not executed. No operator PowerShell item is added; none is needed.

---

## 9. Verdict

**CHANGES REQUIRED (2 MAJOR, 4 MINOR, 1 NIT; 0 BLOCKER, 0 CRITICAL in the deliverable)**

**All 12 acceptance criteria pass with captured evidence** — including the two requiring real runs against
this repository (AC-1, AC-2), the user-facing regression (AC-3), the row 6/7/8 boundary in both directions
(AC-4), both fix-line branches with the absence assertion (AC-7), the spec fallback strengthened by a
partial-answer probe the design did not have (AC-8), and every frozen count (AC-9…AC-12). The defect this task
exists to remove is provably gone: the pre-edit procedure yields `DISABLED` on unchanged repository state; the
shipped procedure yields `installed and wired` naming `.claude/settings.local.json`.

The two MAJORs are **not** AC failures — no acceptance criterion asserts either input — but both are
reproducible FR violations in the shipped product (FR-18 for both, FR-8 for MAJOR-2), both carry tool-output
reproducers above, and both are one-clause fixes confined to `skills/harness-status/SKILL.md`. MAJOR-1 also
has an NFR-1-relevant direction: one defensible reading of the shipped table prints a healthy guard while a
settings file Claude Code loads is structurally broken — the class OQ-5 chose the strict answer for. That
combination is why I route rather than approve.

**Route to**: PM → Developer, for two edits to `skills/harness-status/SKILL.md` (Step 0.1's `unreadable` row;
a first-match-wins statement over §7's table, or a re-wording of `:219`). Both sit inside the existing §7.3 IN
set, move no frozen count, add no gate check and touch no `.ps1`. Re-verification is a re-run of `verify_all`
(expect 32/0/0), `test-supervisor` (expect 46/0 on this host) and probes P-1, P-3, P-11 plus the two ADV
reproducers.

**If PM elects to ship as-is**, MAJOR-1 and MAJOR-2 must be recorded as explicit backlog rows with their
reproducers — not silently dropped — together with MINOR-1…MINOR-4, NIT-1, and CRITICAL-OOB-1 against
`.harness/scripts/guard-rm.sh`.

**QA changed nothing.** `skills/harness-status/SKILL.md`, `CHANGELOG.md`, `.harness/scripts/baseline.json`,
`.harness/insight-index.md` and every driver are byte-unchanged by this stage; the only tree change is this
report, and `git status --porcelain` shows no fixture leakage.

---

# Round 2 — re-verification of the delivered bytes

**Stage 6 (QA), round 2** · Date 2026-07-31 · **deferred-human mode**: defer, do not ask (no
`AskUserQuestion` called in this round either). Round 1 above is **retained unmodified**; this section is
appended.

**Under test**: `skills/harness-status/SKILL.md` at `wc -l` **376** (mtime `19:30:30`), carrying the
Developer's round-3 fixes for round 1's MAJOR-1 and MAJOR-2. Round 1's evidence, fixtures and executors were
kept, so this round is a *differential* verification: what changed, what must not have changed, and whether
the two divergent readings I reproduced in round 1 are still derivable from the shipped text.

**Independence (adversarial rule 2), round 2.** The round-2 probers — `totality_r2.py` (Step 0.1),
`sec7_r2.py` (§7), `prepost.py`, `mkfx2.py` — were written from the **delivered SKILL.md text alone**, before
reading `04_IMPLEMENTATION.md`'s `## Round 3`, which was then used only as a cross-check. The round-2
executor `exec_status_r2.py` is round 1's `exec_status.py` with **two** auditable encoding changes and
nothing else (diff pasted in §R2-2). Round 1's `exec_status.py` / `exec_altB.py` / `exec_altC.py` were **not
edited** — they are frozen encodings of the *round-1* text and are used as the regression oracle.

**Tally honesty (NFR-6).** Every count below is pasted from the run that produced it, labelled with its round.
No count is derived by arithmetic. One count I first mis-measured with my own regex is disclosed and
corrected in §R2-6 rather than quietly fixed.

**Fixtures (AC-11)**: **13** new roots under `…/scratchpad/qa-t14r2/fx/`, plus the **37** round-1 roots
carried forward, all **outside** the repository. Post-round-2 `git status --porcelain` delta is still exactly
one line (§R2-6).

**Soft-cap breach, re-disclosed and now larger.** `wc -l` on this file is **1282** against the 500-line
per-stage-doc soft cap (`.harness/rules/70-doc-size.md:33`); no gate check enforces it (`verify_all` 32/0/0
with the file at this size, §R2-6). PM's round-2 instruction was to **append** rather than overwrite round 1,
so the document is cumulative by direction. The overage is pasted **run output**, which NFR-6 requires
verbatim. If PM wants it inside the cap, the clean move is to split round 1 into
`06_TEST_REPORT_round1.md` at archive time — QA will not delete round-1 evidence unilaterally.

---

## R2-1. Is each divergent reading still derivable from the delivered text?

Both round-1 MAJORs were *document* defects: a table that adjudicated nothing, so two agents could read it two
ways. The fix is therefore verified first **against the bytes**, not only against my executor.

```
$ grep -n 'keyed on' skills/harness-status/SKILL.md
225:The fix line for any non-healthy row is §7's, keyed on §0's **result** with first match
288:  command string and the missing path. Fix line: §7's table, keyed on §0's result with

$ grep -n 'first match wins' skills/harness-status/SKILL.md
24:**Step 0.1 — state of each candidate** (first match wins):
163:**Verdict — first match wins:**
225:The fix line for any non-healthy row is §7's, keyed on §0's **result** with first match
289:  first match wins. When that selects `SOURCE_KIND = committed` it is `run
344:§0's result**, and **first match wins** — exactly one line, in this row order.

$ sed -n '29p;43p' skills/harness-status/SKILL.md
| `unreadable` | … or it parses but a top-level `hooks` key is present whose value is **not** a JSON object (`[]`, a string, a number, `true`, `null`) |
one state. A wrong-typed `hooks` is `unreadable`, never `empty` — the installer's probe
```

- **MAJOR-1's Reading B is textually dead.** Line 29 assigns the shape to `unreadable`; line 43 states the
  direction in prose (`never empty`); lines 41-42 assert totality outright. Three sentences, no contradiction.
- **MAJOR-2's Reading 2 is textually dead.** The phrase `keyed on SOURCE_KIND` has **0** occurrences; both
  surviving pointers (§3b `:225`, §3c `:288`) read "keyed on §0's **result** with first match wins", and §3b
  `:226-227` names the consequence explicitly ("row 1 … therefore takes §7's `MACHINE_STATE = unknown` line,
  never a `SOURCE_KIND` line, even when a candidate still resolved").

## R2-2. The round-2 executor — the only two encoding changes

```
$ diff -u qa-t14/exec_status.py qa-t14r2/exec_status_r2.py
-    hooks = doc.get("hooks", None)
-    if hooks is None or (isinstance(hooks, dict) and len(hooks) == 0):
+    if "hooks" not in doc:
         return "empty", doc
+    hooks = doc["hooks"]
     if not isinstance(hooks, dict):
         return "unreadable", None
+    if len(hooks) == 0:
+        return "empty", doc
     return "present", doc
@@ (§7 block) @@
+    p("  [row selected, first match wins] " + ( … ))     # instrumentation only
```

Note what this diff shows about **round 1's own executor**: it used `doc.get("hooks")`, which conflates an
explicit JSON `null` with an absent key. The round-2 text draws that distinction explicitly (`null` is listed
as a non-object), so my round-1 encoding would now be **wrong**. The fix is therefore not a no-op relative to
a plausible implementer.

## R2-3. Fix 1 — MAJOR-1: is Step 0.1 total, in the strict direction, with nothing moved?

`totality_r2.py` encodes the **four row conditions as four independent predicates** — no first-match
short-circuit — so the number of rows an input matches is observable. **28** inputs (round 1's set plus 15 I
added: fifo, symlink-to-dir, symlink-to-file, mode-000, empty file, whitespace-only, BOM+CRLF, trailing
garbage, `{"HOOKS":[]}`, `{"hooks":false}`, `{"hooks":[{…}]}`, a wrong-typed *sub*-value, and controls).

```
$ python3 totality_r2.py …/tot        (round 2)
{}                                                   ['empty']                      1
{"other":1}  (no hooks key)                          ['empty']                      1
{"hooks":{}}                                         ['empty']                      1
{"hooks":{"PreToolUse":[]}}                          ['present']                    1
{"hooks":[]}        <- QA MAJOR-1                    ['unreadable']                 1
{"hooks":"x"}                                        ['unreadable']                 1
{"hooks":null}                                       ['unreadable']                 1
{"hooks":3}                                          ['unreadable']                 1
{"hooks":true}                                       ['unreadable']                 1
{"hooks":false}   <- NOT in the parenthetical        ['unreadable']                 1
{"hooks":[{"matcher":"Bash"}]}  (array of entries)   ['unreadable']                 1
{"HOOKS":[]}  (case: different key)                  ['empty']                      1
<a fifo> / <symlink to a dir> / <file, mode 000>     ['unreadable']                 1
CRLF + BOM around {"hooks":{}}                       ['unreadable']                 1

INPUTS NOT LANDING ON EXACTLY ONE STATE: 0
```

**Nothing moved.** The same 28 inputs run against the **round-1** row texts (`unreadable` minus the new
clause; `empty`/`present` byte-unchanged, confirmed by `sed -n '30,31p'`):

```
$ python3 prepost.py            (round 2)
{"hooks":[]}        <- QA MAJOR-1                    []                       ['unreadable']
{"hooks":"x"}                                        []                       ['unreadable']
{"hooks":null}                                       []                       ['unreadable']
{"hooks":3}                                          []                       ['unreadable']
{"hooks":true}                                       []                       ['unreadable']
{"hooks":false}                                      []                       ['unreadable']
{"hooks":[{"matcher":"Bash"}]}                       []                       ['unreadable']
…all other 21 inputs identical pre/post…

previously-classified inputs that MOVED: 0
previously-UNclassified inputs now landing on exactly one state: 7
```

Seven, not the Developer's five — `{"hooks":false}` and `{"hooks":[{…}]}` are also newly classified, both
`unreadable`. **Every** newly-classified input lands in the strict direction.

**Direction and non-vacuity at the verdict level** (fixtures `r2_wt_{array,string,number,true,null,false,
entries}`, C1 wrong-typed, C2 wiring a healthy guard):

```
r2_wt_array  altB (round-1 divergent reading): Safety hook: installed and wired (…) | §6 guard health point = +1
r2_wt_array    r2 (delivered text)           : Safety hook: UNKNOWN — .claude/settings.local.json could not be read or parsed | §6 guard health point = 0
r2_wt_null   altB: installed and wired … +1        r2: UNKNOWN … 0
r2_wt_false  altB: installed and wired … +1        r2: UNKNOWN … 0
```

and the **control** proves the strictness is directional, not a blanket "anything unusual is unreadable":

```
################ r2_nokey_ctl        ( C1 = {"other":1} — a hooks key genuinely ABSENT )
  C1 .claude/settings.local.json -> empty
  UNKNOWN_FILES=[]  SOURCE=.claude/settings.json  SOURCE_KIND=committed  MACHINE_STATE=installed
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.json; matcher "Bash")
  §6 guard health point = +1
```

**MAJOR-1: fixed.** The `unreadable` / `empty` boundary now discriminates a *missing* key from a *wrong-typed*
one, and only the second is penalised.

## R2-4. Fix 2 — MAJOR-2: §7 first-match-wins, cell bytes, branch reachability

**(a) The six cells are byte-identical to round 1** — extracted from the delivered bytes and compared against
my **round-1** transcription (`qa-t14/exec_status.py:310-331`, written from the round-1 text and not edited
since). This is the Developer's "order-only change" claim, checked independently:

```
$ python3 sec7_r2.py            (round 2)
=== Part A: the six SHIPPED section-7 rows, in delivered document order ===
  row 1  KEY `MACHINE_STATE = unknown`
  row 2  KEY `MACHINE_STATE = never-installed`
  row 3  KEY `MACHINE_STATE = opt-out`
  row 4  KEY `SOURCE_KIND = committed`
  row 5  KEY `SOURCE_KIND = machine-local` and `OTHER_DECLARES = false`
  row 6  KEY `SOURCE_KIND = machine-local` and `OTHER_DECLARES = true`
  row count: 6

=== Part A2: byte-comparison of each shipped cell vs QA's ROUND-1 transcription ===
  MACHINE_STATE = unknown      IDENTICAL to round 1
  never-installed (part A)     IDENTICAL to round 1
  never-installed (part B)     IDENTICAL to round 1
  opt-out                      IDENTICAL to round 1
  SOURCE_KIND = committed      IDENTICAL to round 1
  machine-local, OTHER=false   IDENTICAL to round 1
  machine-local, OTHER=true    IDENTICAL to round 1
```

**No §5.3 pinned string moved.** Order-only change confirmed against a round-1 artifact, not against the
Developer's word.

**(b) Selection over every reachable §0 result**, six row conditions evaluated independently, then
first-match-wins applied in the shipped order:

```
MACHINE_STATE    SOURCE_KIND    OTHER  #match   row selected (first match wins)
unknown          none           False  1        MACHINE_STATE = unknown
unknown          machine-local  False  2        MACHINE_STATE = unknown
unknown          machine-local  True   2        MACHINE_STATE = unknown
unknown          committed      False  2        MACHINE_STATE = unknown
unknown          committed      True   2        MACHINE_STATE = unknown
never-installed  none           False  1        MACHINE_STATE = never-installed
opt-out          none           False  1        MACHINE_STATE = opt-out
installed        machine-local  False  1        SOURCE_KIND = machine-local and OTHER_DECLARES = false
installed        machine-local  True   1        SOURCE_KIND = machine-local and OTHER_DECLARES = true
installed        committed      False  1        SOURCE_KIND = committed
installed        committed      True   1        SOURCE_KIND = committed

states with NO matching row: 0
distinct rows selected by at least one state: 6 of 6
   row 1 … REACHABLE   row 2 … REACHABLE   row 3 … REACHABLE
   row 4 … REACHABLE   row 5 … REACHABLE   row 6 … REACHABLE
```

The four `#match = 2` rows are exactly the overlap round 1 filed; the ordering resolves all four to the line
that names the unparseable file. **All six branches remain individually reachable, and no state is left
without a line.**

**(c) Executed, on fixtures — including the state round 1 never reached.** My hypothesis was that the fix had
been tuned to my exact P-11 input (`unknown ∧ committed`) and would fail on its **mirror**
(`unknown ∧ machine-local`, i.e. the *committed* file is the broken one):

```
################ r2_unknown_ml   (C1 healthy+present, C2 truncated)
  UNKNOWN_FILES=['.claude/settings.json']  SOURCE=.claude/settings.local.json  SOURCE_KIND=machine-local  MACHINE_STATE=unknown
Safety hook:         UNKNOWN — .claude/settings.json could not be read or parsed; guard state undetermined
  §6 guard health point = 0
  [row selected, first match wins] MACHINE_STATE = unknown
  inspect .claude/settings.json — it is loaded by Claude Code but this report could not parse it

################ r2_both_unknown   (both candidates unreadable -> unknown ∧ SOURCE_KIND = none)
  [row selected, first match wins] MACHINE_STATE = unknown
  inspect .claude/settings.local.json, .claude/settings.json — it is loaded by Claude Code but this report could not parse it

################ r2_unknown_committed_dangling   (C1 truncated; C2 wires a MISSING guard)
  PreToolUse:        DANGLING — "…bash .harness/scripts/guard-rm.sh" -> missing .harness/scripts/guard-rm.sh
  [row selected, first match wins] MACHINE_STATE = unknown
  inspect .claude/settings.local.json — it is loaded by Claude Code but this report could not parse it
```

Absence assertions on the same three states (the load-bearing half — the finding was a *wrong* instruction):

```
  r2_unknown_ml                 : '/harness-upgrade' in fix line = 0   |   'rm .claude/settings.local.json' in fix line = 0
  r2_both_unknown               : '/harness-upgrade' in fix line = 0   |   'rm .claude/settings.local.json' in fix line = 0
  r2_unknown_committed_dangling : '/harness-upgrade' in fix line = 0   |   'rm .claude/settings.local.json' in fix line = 0
```

**Non-vacuity — and the mirror state is worse than what round 1 filed.** The same inputs under round 1's
divergent reading (`exec_altC.py`, `SOURCE_KIND`-keyed, unedited since round 1):

```
  r2_unknown_ml   round-1 divergent reading:  rm .claude/settings.local.json && .harness/scripts/install-hooks — …
  r2_unknown_ml   round-2 delivered text   :  inspect .claude/settings.json — it is loaded by Claude Code but this report could not parse it

  r2_unknown_committed_dangling  round-1 divergent reading:  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json
  r2_unknown_committed_dangling  round-2 delivered text   :  inspect .claude/settings.local.json — …
```

On `r2_unknown_ml` the old reading tells the user to **delete the only parseable, healthy settings file
because the other one is broken** — a data-loss-class instruction. Round 1 did not reach this state; the
delivered ordering removes it. **MAJOR-2: fixed.**

**(d) §3c's second corrected pointer (`:287-291`), both source kinds:**

```
  ---- p10_committed_dangling      SOURCE_KIND=committed
  PreToolUse:  DANGLING — "…bash .harness/scripts/guard-rm.sh" -> …
  fix line  :  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json
  '/harness-upgrade' occurrences in the WHOLE report: 1

  ---- p6_dangling                 SOURCE_KIND=machine-local
  PreToolUse:  DANGLING — "…bash .harness/scripts/guard-rm.sh" -> …
  fix line  :  rm .claude/settings.local.json && .harness/scripts/install-hooks — the upgrade helper …
  '/harness-upgrade' occurrences in the WHOLE report: 0
```

§3c routes correctly for **both** kinds, and the machine-local case contains **zero** `/harness-upgrade`
occurrences anywhere in the report — the absence half of FR-8.

## R2-5. Regression sweep — nothing previously proved may have moved

The round-1 executor is a **frozen encoding of the round-1 text**. Running it and the round-2 executor over
every round-1 root and comparing **full** output is therefore a direct test of "did the round-3 edits change
any verdict on an input already probed":

```
=== REGRESSION SWEEP: round-1-text executor vs round-2-text executor ===     (round 2)
roots compared (37 round-1 fixtures + this repository): 38
roots whose FULL output changed across the round-3 edits: 0
changed: (none)
```

**Is that 0 vacuous?** No — the same comparator, pointed at the two divergent-reading executors, flags exactly
the roots where those readings diverge:

```
  exec_altB vs delivered round-2 text: 1 roots differ -> adv_hooks_wrongtype
  exec_altC vs delivered round-2 text: 4 roots differ -> adv_hooks_wrongtype p11_bytebroken p11_notregular p11_unreadable
```

**Re-run explicitly this round** (captures below are from the round-2 run, not carried forward): AC-1/AC-2
against this repository, AC-3 + its mutation, the row 6/7/8 boundary (P-6, P-6b×3, P-6c, P-7, P-13), the
machine dimension (P-8×3, P-9×2), fix-line reachability (P-10, P-10b, P-6_dangling), and the spec fallback
(P-17, P-18, P-18b). **Carried forward from round 1 without re-execution**: P-11b/c, P-12, P-14, P-15, P-16,
P-19, P-20-AB/BA, P-21, B-8, MINOR-4's F-9 reproducer. That is safe because the sweep above proves their
**full** round-2 output is byte-identical to the round-1-text output, and none of them touches a wrong-typed
`hooks` value or a `MACHINE_STATE = unknown` state — the only two places the delivered text changed.

**AC-1 / AC-2, re-captured against this repository, round 2:**

```
  C1 .claude/settings.local.json -> present        C2 .claude/settings.json -> empty
  UNKNOWN_FILES=[]  SOURCE=.claude/settings.local.json  SOURCE_KIND=machine-local  OTHER_DECLARES=False  MACHINE_STATE=installed
Hook source:  .claude/settings.local.json (machine-local settings)                  — committed .claude/settings.json declares no lifecycle hooks
  [derivation] K=1 PATHS=['.harness/scripts/guard-rm.sh'] GUARD_PATHS=['.harness/scripts/guard-rm.sh'] MISSING=[] -> ROW 8
Sub-agent dispatch:  enabled (Claude Code via Task tool)
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash")
  guard entries matched:  1        matcher:  "Bash"        interpreter:  sh (on PATH)
  PreToolUse hook row Present? = YES (row 8)      §6 guard health point = +1
  [spec usable] True (invocations attempted: 7)
Hook congruence (from .claude/settings.local.json):
  Stop: ok    PreToolUse: ok    UserPromptSubmit: ok    SessionStart: ok
```

**The non-vacuity contrast still holds** — the pre-edit procedure at `HEAD` (`cb0ed57`, unchanged) still
carries the defect, on unchanged repository state:

```
$ git show HEAD:skills/harness-status/SKILL.md | grep -n 'DISABLED\|computed by parsing'
73:"Safety hook" value is computed by parsing `.claude/settings.json`:
78:- `DISABLED — .claude/settings.json has no PreToolUse for Bash` if the array
$ python3 -c "…len(json.load(open('.claude/settings.json')).get('hooks',{}))"
0                     # the committed file declares no hooks -> pre-edit text yields DISABLED
```

**AC-3, round 2** (committed settings — what generated user projects ship with), with its single-input
mutation:

```
Hook source:  .claude/settings.json (committed settings)       — no machine-local settings file declares hooks
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.json; matcher "Bash")
  §6 guard health point = +1
  -- mutation (guard-rm.sh deleted):
Safety hook:         WIRING DANGLING — .claude/settings.json wires "…" -> missing .harness/scripts/guard-rm.sh
  §6 guard health point = 0
  run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json
```

**Row 6/7/8 boundary, machine dimension, fix lines, spec fallback — round-2 captures:**

```
  p6_dangling                ROW 7 | point 0        p8_never            NOT INSTALLED ON THIS MACHINE — …   fix: .harness/scripts/install-hooks
  p6b_chain_guardmissing     ROW 7 | point 0        p8_never_noclaude   NOT INSTALLED ON THIS MACHINE — …   fix: .harness/scripts/install-hooks
  p6b_chain_syncmissing      ROW 7 | point 0        p8_never_noinstaller NOT INSTALLED …                    fix: run /harness-adopt or /harness-upgrade
  p6b_chain_bothpresent      ROW 8 | point +1       p9_optout           HOOKS OFF (machine-local opt-out) — … "hooks": {}   fix: documented persistent opt-out; no action
  p6c_mention                ROW 6 | point 0        p9_optout_nokey     HOOKS OFF (machine-local opt-out) — … no "hooks" key
  p7_absent                  ROW 4 | point 0
  p13_malformed              ROW 5 | point 0        p10b absence: '&& .harness/scripts/install-hooks' occurrences = 0

  p17_nospec        [spec usable] False (invocations attempted: 0)   fallback label present, rows Stop/PreToolUse/UserPromptSubmit/SessionStart
  p18_spec_exit2    [spec usable] False (invocations attempted: 2)   fallback label present, same row order
  p18b_spec_partial [spec usable] False (invocations attempted: 6)   fallback label present, spec's REVERSED order discarded
```

AC-5 and AC-6 still produce **different** sentences; `<shape>` still reports the shape actually seen.

## R2-6. Whole-repo gates — AC-9, AC-10, AC-11, AC-12

**`verify_all.sh`, three round-2 runs**, each `=== Summary ===` pasted from its own run:

```
########## run 1                ########## run 2                ########## run 3
=== Summary ===                 === Summary ===                 === Summary ===
  PASS: 32                        PASS: 32                        PASS: 32
  WARN: 0                         WARN: 0                         WARN: 0
  FAIL: 0                         FAIL: 0                         FAIL: 0
```

**Disclosed measurement error of mine, corrected in place.** My first check-row count printed **31**, not 32:

```
$ verify_all.sh | grep -cE '^\[[A-Z]+\.[0-9]+\] .* \.\.\. (PASS|WARN|FAIL)'
31
$ verify_all.sh | grep -cE '\.\.\. (PASS|WARN|FAIL)'
32
```

The row `[E.4b]` has a letter suffix after the digit, which my first regex excluded. **The product did not
move; my regex was wrong.** The enumerated 32 rows (`[A.1]`…`[G.4]`) were listed in full and all printed
`PASS`. Recorded rather than silently fixed, per NFR-6.

**`test-supervisor.sh`, three round-2 runs**, `=== Result ===` pasted from each:

```
########## run 1                ########## run 2                ########## run 3
=== Result ===                  === Result ===                  === Result ===
  PASS: 46                        PASS: 46                        PASS: 46
  FAIL: 0                         FAIL: 0                         FAIL: 0

  PASS  fan-out: harness-status SKILL.md notes framework agents (7 + supervisor) are plugin-provided
  PASS  fan-out: harness-status SKILL.md retired the canonical-7 asset glob (v0.30 truth)
```

Both structurally-pinned fan-out assertions green after the round-3 edits, which inserted lines in §0, §3b and
§7. `baseline.json:16`'s `45` is the correct **no-python3** value, is **out of bounds**, and was **not
touched** — round 1 corroborated the 45/46 split with a no-python3 shim; that corroboration is carried forward
and not repeated.

**AC-11 — porcelain delta vs the Developer's round-1 pre-edit baseline** (`04_IMPLEMENTATION.md:16-53`),
captured **after** all round-2 fixture work:

```
$ diff qa-t14/pre_edit.txt <(git status --porcelain)
29a30
>  M skills/harness-status/SKILL.md

$ git status --porcelain | grep -ci 'qa-t14\|fx/\|scratchpad'
0
$ git status --porcelain --untracked-files=all | grep -c 'r2_'
0
$ git diff --stat -- skills/harness-status/SKILL.md
 skills/harness-status/SKILL.md | 255 +++++++++++++++++++++++++++++++-----
 1 file changed, 228 insertions(+), 27 deletions(-)
```

Exactly **one** added porcelain line, and it is §7.3 IN row 1. `.harness/insight-index.md`,
`.harness/scripts/baseline.json`, `.harness/scripts/verify_all.sh` and `CHANGELOG.md` also show ` M`, but
**all four are already ` M` in the round-1 pre-edit baseline** (T-13's uncommitted delivery) — the diff proves
no new line. Their mtimes confirm neither the Developer's round 3 nor QA's round 2 touched them:

```
$ ls -l --time-style=+%H:%M:%S …
16:27:44  .harness/scripts/baseline.json
17:27:48  .harness/insight-index.md
18:30:21  CHANGELOG.md
13:28:07  .harness/scripts/verify_all.sh
10:42:09  .harness/scripts/test-supervisor.sh
19:30:30  skills/harness-status/SKILL.md      <- the Developer's round-3 edit
20:06:51  (current time; QA round-2 work began ~20:00)
```

**Frozen counts, each pasted from the command that produced it (round 2):**

```
$ awk '/^\| Asset \| Path \| Present/,/^$/' skills/harness-status/SKILL.md | grep -c '^| '
15                                      # 1 header + 14 data rows -> 14 required-asset rows
$ grep -n 'All 14 required assets\|Total possible' skills/harness-status/SKILL.md
321:- All 14 required assets present → +6 health points
328:- Total possible: 12
$ grep -c 'DISABLED — .claude/settings.json has no PreToolUse for Bash' skills/harness-status/SKILL.md
0
$ grep -c '^- ' .harness/insight-index.md
30
$ sed -n '16p' .harness/scripts/baseline.json
  "test_supervisor_bash_no_python3_assertions": 45,
$ wc -l skills/harness-status/SKILL.md
376
$ grep -nE '\(7 \+ supervisor\).*plugin-provided' skills/harness-status/SKILL.md
111:Note: the framework agents (7 + supervisor) are **plugin-provided** (`harness-kit:<name>`)
$ grep -cF '{pm,req,sol,gate,dev,review,qa}*' skills/harness-status/SKILL.md
0
```

**AC-12** — `G.4` PASS in all three round-2 `verify_all` runs; `HEAD` still `cb0ed57`, no version stamp moved.
Carried forward from round 1 (nothing in round 3 touched `CHANGELOG.md` or `plugin.json`; mtimes above).

## R2-7. Adversarial tests — round 2 (one hypothesis per item, written before the run)

| # | Hypothesis ("I expect failure when…") | Reproducer (all NEW, QA-authored, round 2) | Outcome |
|---|---|---|---|
| ADV-R2-1 | …`{"hooks": null}` re-opens Reading B, because "no top-level `hooks` key" is trivially conflated with a `null` value by any `get()`-style read — my **own** round-1 executor made exactly that mistake | `fx/r2_wt_null` + `totality_r2.py` | **Survived** — `unreadable`, row 1, point 0 (R2-3). The text distinguishes key-absent from key-null explicitly |
| ADV-R2-2 | …the parenthetical `([], a string, a number, true, null)` is read as **exhaustive**, leaving `{"hooks": false}` unclassified — MAJOR-1 all over again in a narrower hole | `totality_r2.py --exhaustive` mode + `fx/r2_wt_false` | **Survived as shipped** (`false` → `unreadable`), but the mis-reading *does* leave it unclassified — filed **NIT-2**, see R2-8 |
| ADV-R2-3 | …the fix was tuned to my exact P-11 input, so the **mirror** state (`unknown ∧ machine-local`) still prints `rm .claude/settings.local.json`, deleting the only healthy file | `fx/r2_unknown_ml` (NEW; round 1 never reached this state) | **Survived** — prints `inspect .claude/settings.json`; `rm …` occurrences = 0 (R2-4c). The old reading *does* print the deletion — the sharpest evidence the fix matters |
| ADV-R2-4 | …§3c's `DANGLING` pointer still emits `/harness-upgrade` under `MACHINE_STATE = unknown`, or fails for machine-local | `fx/r2_unknown_committed_dangling`, `p6_dangling`, `p10_committed_dangling` | **Survived** — `/harness-upgrade` count is 1 for committed, **0** for machine-local and 0 under `unknown` (R2-4d) |
| ADV-R2-5 | …a **healthy** guard (row 8) with a *different* event's script missing has no §7 row, or reaches one that cannot name a file the report named | `fx/r2_row8_stop_dangling` (NEW) + `sec7_r2.py` Part B | **Survived** — `Stop: DANGLING`, guard `+1` correctly retained, §7 selects row 5. **Executor gap disclosed** in R2-8 |
| ADV-R2-6 | …the "order-only" claim is false and some §5.3 cell was silently re-worded while I was looking at the ordering | `sec7_r2.py` Part A2 vs my **round-1** transcription | **Survived** — all six cells `IDENTICAL to round 1` |
| ADV-R2-7 | …the fix regressed something already proved, somewhere in the 37 round-1 roots | r1-text executor vs r2-text executor, full-output `cmp` over 38 roots | **Survived** — 0 roots changed; comparator proved sensitive (flags 1 and 4 roots against the divergent readings) |
| ADV-R2-8 | …a wrong-typed *sub*-value (`{"hooks": {"PreToolUse": "x"}}`) is `present` and then reaches row 8 | `fx/r2_subvalue` | **Survived on the safety axis** — `present`, but `K = 0` ⇒ row 4, no point under any reading. Structural gap filed **MINOR-5**, see R2-8 |
| ADV-R2-9 | …a fixture or stray edit leaked into the tree, or a frozen count moved under cover of the fix | porcelain diff, mtimes, frozen-count greps | **Survived** — delta exactly one line; 0 leakage |

## R2-8. Defects and observations — round 2

**Round-1 MAJOR-1: CLOSED.** **Round-1 MAJOR-2: CLOSED.** No new BLOCKER, CRITICAL or MAJOR.

- **NIT-2 (new, record-only)** · `SKILL.md:29` — the parenthetical `(`[]`, a string, a number, `true`,
  `null`)` omits `false`. The **normative** clause is "whose value is **not** a JSON object", and lines 41-43
  assert totality outright, so `{"hooks": false}` is `unreadable` on the shipped text and my probe confirms it.
  The mis-reading "the parenthetical is exhaustive" is the *only* way to leave an input unclassified, and it
  contradicts two other sentences in the same paragraph — which is precisely what round-1 MAJOR-1 lacked.
  Suggested one-word archive-time edit: `(e.g. [], a string, a number, true/false, null)`. **Owner**: PM
  (backlog). **Not** a re-open of MAJOR-1.
- **MINOR-5 (new, record-only, pre-existing)** · §0 is now total over the **top-level** `hooks` type, but
  `present` only asserts `hooks` is an object with ≥ 1 key. §3b's detection ("entries under `SOURCE`'s
  `hooks.PreToolUse[*].hooks[*]`") is undefined when `hooks.PreToolUse` is not an array —
  `{"hooks": {"PreToolUse": "x"}}` crashed my executor, while a document-following agent reads "no such
  entries ⇒ `K = 0` ⇒ row 4". **No reading reaches row 8 or `+1`**, so unlike MAJOR-1 there is no false-green
  direction; this is output divergence one structural level below the fix, not verdict divergence. It is
  **not** introduced by round 3 and is outside every AC. **Owner**: PM (backlog).
- **NIT-3 (new, record-only)** · When `MACHINE_STATE = unknown` coexists with a genuinely dangling wiring in
  the *readable* candidate (`fx/r2_unknown_committed_dangling`), §7's "exactly one line" rule suppresses the
  `/harness-upgrade` repair for the dangling script in favour of `inspect <unparseable file>`. FR-8 is
  **satisfied** — the printed line reaches a file the report named — and `SKILL.md:356-361` argues the
  ordering explicitly. Recording the trade-off, not objecting to it.
- **QA tool gap, disclosed** · `exec_status_r2.py` keys its §7 block on §3b's row alone, so it prints no fix
  line when the guard is row 8 but §3c reports a dangling *other* hook (ADV-R2-5). The product requires one
  ("If §3b **or** §3c reported any non-healthy hook state"). I closed that state **analytically** with
  `sec7_r2.py` Part B (row 5, exactly one match) rather than claiming an execution I did not perform.
- **Carried, unchanged, out of scope this round** (all recorded, none re-litigated): **CRITICAL-OOB-1** against
  `.harness/scripts/guard-rm.sh` — **accepted by PM and routed to the stream as a new task**; gate F-9's
  residual; round-1 MINOR-1…MINOR-4 and NIT-1; CR MINOR-2/-3/-4; the design P-20/P-21 probe-spec defects.

## R2-9. Guard interaction, round 2

The destructive-command guard was **not** disabled, weakened, unwired or worked around. `guard-rm.sh` /
`.ps1` are `git`-clean and mtime `10:42:09`, untouched in either round.

The **live PreToolUse hook fired and blocked two QA Bash calls this round** — auditable evidence the guard
this report certifies is genuinely armed in this session:

```
PreToolUse:Bash hook error: [sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh']:
harness-kit guard-rm: BLOCKED — could not parse nested pwsh command safely; override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.
```

Fail-closed behaviour and the scoped override, both pasted:

```
$ printf '{"tool_input":{"command":"rm -rf <SCRATCH>/qa-t14r2/sweep"}}' | bash .harness/scripts/guard-rm.sh
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: rm -rf /tmp/claude-1000/…/qa-t14r2/sweep
  Offending path(s):
    - /tmp/claude-1000/…/qa-t14r2/sweep (outside /home/alan/Programs/harness-kit)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
exit=2

$ printf '{"tool_input":{"command":"rm -rf <SCRATCH>/qa-t14r2/sweep"}}' | HARNESS_ALLOW_OUTSIDE_RM=1 bash .harness/scripts/guard-rm.sh
harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.
exit=0
```

The override was used on exactly **two** calls, both fixture construction outside the repository, both
re-issued after a live block:

```
$ HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf <SCRATCH>/qa-t14r2/fx/r2_row8_stop_dangling
$ HARNESS_ALLOW_OUTSIDE_RM=1 rm -f  <SCRATCH>/qa-t14r2/fx/r2_row8_stop_dangling/.harness/scripts/harness-sync.sh
```

No round-2 evidence was deleted; all 50 fixture roots and both sweeps are retained outside the tree.

## R2-10. Stability and test-count movement — round 2

| Suite | Runs (round 2) | Result |
|---|---|---|
| `bash .harness/scripts/verify_all.sh` | 3 | `PASS: 32 / WARN: 0 / FAIL: 0` every run — no flake |
| `bash .harness/scripts/test-supervisor.sh` | 3 | `PASS: 46 / FAIL: 0` every run — no flake |
| `exec_status_r2.py` over 38 roots | 2 full passes | `roots re-run byte-identical to pass 1: 38    differing: 0` |

**Test-count movement**: `verify_all` 32 → 32; `test-supervisor` 46 → 46 (python3-present, self-comparison).
**New automated tests added to the project suite: 0, deliberately** — the product is a skill *document* with
no executable test surface, and design §12.4 / OQ-7a forbid adding a `verify_all` check or a
`test-supervisor` assertion in this task. Round-2 coverage is **9 new adversarial probes**, **13 new fixture
roots**, a 28-input Step 0.1 totality prober, an 11-state §7 selection prober and a 38-root regression sweep,
all outside the tree.

**`.harness/scripts/baseline.json`: NOT updated — correctly.** No count in it moved, `:16`'s `45` is the
correct no-python3 value and is out of bounds, and no new test was added to the suite. `.harness/insight-index.md`
likewise untouched (30 lines).

**Performance**: no perf NFR stated. `verify_all` ≈ 10.6 s, `test-supervisor` ≈ 0.2 s, both unchanged from
round 1. The procedure still performs at most two settings reads and exactly 7 spec invocations per run.

**NFR-5**: no `.ps1` touched in either round; **QA performed no PowerShell verification and claims none**.

## R2-11. Verdict — round 2

**APPROVED FOR DELIVERY**

Both round-1 MAJORs are closed against the delivered bytes, by independent reproducers rather than by
inspection:

- **MAJOR-1** — Step 0.1 is total: **28** inputs, **0** landing on more than or fewer than one state,
  **0** previously-classified inputs moved, **7** previously-unclassified inputs newly classified and **all
  seven** in the strict (non-healthy) direction. The `{"other":1}` control still earns `+1`, so the
  strictness discriminates rather than blanket-fails. Round 1's Reading B is no longer derivable from the
  text and no longer reproducible in execution.
- **MAJOR-2** — §7 is first-match-wins with the `MACHINE_STATE` rows first; all **six** cells are
  **byte-identical** to my round-1 transcription (order-only change confirmed against a round-1 artifact);
  all **six** branches remain individually reachable; **no** §0 result is left without a line; and the
  `unknown` state — including the **mirror** state round 1 never reached, where the old reading told the user
  to delete the only healthy settings file — now selects a line that names the file the report named.
  `/harness-upgrade` is unreachable there. Both corrected pointers (`:225-228`, `:287-291`) route correctly
  for machine-local **and** committed sources.

Regression is clean: **38** roots, **0** changed full outputs, with the comparator independently shown to be
sensitive. This repository still reports **installed and wired** from `.claude/settings.local.json` with four
`ok` congruence rows, and the pre-edit contrast still yields `DISABLED`, so AC-1/AC-2 remain non-vacuous.
`verify_all` **32 / 0 / 0** ×3, `test-supervisor` **46 / 0** ×3, porcelain delta exactly
`M skills/harness-status/SKILL.md`, zero fixture leakage, every frozen count unmoved.

Open items are **NIT-2**, **MINOR-5** and **NIT-3** (all new, all record-only, none an AC failure, none with a
false-green direction), plus round 1's carried backlog and the PM-accepted `guard-rm.sh` stream task. None
blocks delivery.

**QA changed nothing in round 2 either.** The only tree change from this stage is this report; `SKILL.md`,
`CHANGELOG.md`, `baseline.json`, `insight-index.md`, every driver and every hook script are byte-unchanged by
QA.
