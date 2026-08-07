# 06 — Test Report · T-17 `guard-cmd-chain`

- Mode: **full** · Stage 6 (qa-tester) · **Security task**
- Inputs: `01_REQUIREMENT_ANALYSIS.md` (rounds 2–4), `05_CODE_REVIEW.md` **round 3** (§11 conditions +
  residual list), `04_DEVELOPMENT.md` round 3. `02_SOLUTION_DESIGN.md` read as background only — its
  three known-false statements (drifts 1, 4, 5) were **not** used as an oracle.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- Method: **independent execution.** Every number below is quoted from a run I performed in this
  session, with my own harness. I did not re-use the developer's driver as my oracle for the
  acceptance criteria — I wrote a separate probe runner (`probe.py`) and a separate corpus harvester
  (`harvest.py`) and derived the expectations from the ACs, not from `04_DEVELOPMENT.md`'s test code.
  The developer's 87-row driver was then run as a *second*, corroborating instrument.
- **No deletion was performed anywhere.** Every probe feeds the guard
  `{"tool_input":{"command": …}}` on stdin and reads the exit code, exactly as the PreToolUse hook
  does. Executability of a bypass was established separately with `touch` standing in for the verb
  (`exec_check.sh`), never with a destructive verb.
- Guard code was **not** modified. All comparison guards and mutants are scratch copies driven
  through the driver's `[guard-path]` argument.

---

## 0. Headline

| | |
|---|---|
| `verify_all` | **PASS 32 / WARN 0 / FAIL 0** — 3 consecutive runs, identical; check count unchanged |
| 87-row guard driver, shipped guard | **PASS 87 / FAIL 0** — 10 consecutive runs, identical |
| The original five-row bypass table | Reproduced on both guards; **all four bypasses close, the in-project case still passes** |
| QA-authored probes executed | **~1,870** across two guards (50 legitimate-form, 148 adversarial, 140 harvested corpus, 1,500 fuzz, plus boundary/latency/concurrency sets) |
| **BLOCK → ALLOW flips found (IS-2 violations)** | **0**, in every differential I ran |
| Non-`{0,2}` exit codes found (fail-open candidates) | **0** in 1,500 fuzz inputs |
| False positives on 50 realistic developer commands | **0** |
| Defects | 0 BLOCKER, 0 CRITICAL, 0 MAJOR, **4 MINOR**, 4 NIT |
| **Verdict** | **PASS WITH NOTES** |

---

## 1. Test plan — one test per acceptance criterion

| Acceptance criterion | My test case(s) | Artifact | Result |
|---|---|---|---|
| **AC-1** bypass matrix, exit 2 for every row | `cases_stream5.json` (the stream's original 5 rows) + driver rows `a`…`r`,`f2` + `cases_adv.json` D1–D9, H1–H50 | `probe.py`, `test-guard-rm.sh` | **PASS** |
| **AC-2** existing behaviour preserved (17 rows, pwsh row 8, depth-2, env override + audit line) | driver rows 1–17; `boundary.py` B-7 audit-line capture; `cases_adv.json` E3/E4 | `probe.py`, driver | **PASS** |
| **AC-3** legitimate corpus, exit 0 except L10 | driver rows `L1`…`L14` (L10 = BLOCK per the round-2 header) + my own **50-line** `cases_legit.json` | `probe.py`, driver | **PASS** |
| **AC-4** differential, 0 BLOCK→ALLOW | my own `harvest.py`: **140 distinct command lines** harvested from S1/S2/S3/S4 by script, run against both guards; plus 148 adversarial and 1,500 fuzz differentials | `harvest.py`, `fuzz.py` | **PASS** |
| **AC-5** fail-closed | `cases_adv.json` F1–F7; `boundary.py` B-1/B-6 | `probe.py`, `boundary.py` | **PASS** |
| **AC-6** verb set unchanged | byte-diff of `destructive_verbs_ci` pre vs post; 9 arms of `_is_destructive_verb`; 9 members of `$destructiveVerbs`; `V1`/`V2`/`V3` + H36–H39 | `grep`, `probe.py` | **PASS** |
| **AC-7** symmetry + lockstep | `cmp` repo↔template on both guards; `sync-self --check`; independent 87/87/87 count | `cmp`, `sync-self.sh` | **PASS** |
| **AC-8** gate green, 32 checks | `verify_all.sh` ×3, before and after my doc edit; `[I.2]` at 199/190 | `verify_all.sh` | **PASS** |
| **AC-9** documentation truth | read both rule copies; **CR3-1 residual line added by me** after empirical confirmation | Read/Edit | **PASS** (see §6) |
| **AC-10** driver anti-revert | I rebuilt all 6 comparison guards/mutants myself with an anchor-match builder and re-ran each | `build_variants.py`, driver | **PASS** |
| **AC-11** live-guard continuity | every tally below quoted from its own run; guard never edited | — | **PASS** |
| **AC-12** PowerShell debt recorded | operator list item count + security marking checked; `pwsh` absence confirmed; no reconciliation attempted | Read, `command -v pwsh` | **PASS** (1 NIT) |

---

## 2. Job 1 — the original bypass, reproduced and closed

The stream's original table was captured on the pre-change guard. I re-ran all five rows against
**both** guards. Pre-change guard = `git show HEAD:.harness/scripts/guard-rm.sh` → scratch (336
lines, `bash -n` clean), driven through the `[guard-path]` mechanism. **No deletion performed.**

```
### PRE-CHANGE guard (git show HEAD:.harness/scripts/guard-rm.sh)
         BLOCK exit=2 S1-control               rm -rf /etc/harness-guard-probe
         ALLOW exit=0 S2-andand                echo hi && rm -rf /etc/harness-guard-probe
         ALLOW exit=0 S3-semi                  true; rm -rf /etc/harness-guard-probe
         ALLOW exit=0 S4-xargs                 ls | xargs rm -rf /etc/harness-guard-probe
         ALLOW exit=0 S5-inproj                rm -rf ./build

### SHIPPED guard (.harness/scripts/guard-rm.sh)
         BLOCK exit=2 S1-control               rm -rf /etc/harness-guard-probe
         BLOCK exit=2 S2-andand                echo hi && rm -rf /etc/harness-guard-probe
         BLOCK exit=2 S3-semi                  true; rm -rf /etc/harness-guard-probe
         BLOCK exit=2 S4-xargs                 ls | xargs rm -rf /etc/harness-guard-probe
         ALLOW exit=0 S5-inproj                rm -rf ./build
```

**The reported table reproduces exactly on the pre-change guard (2/0/0/0/0), all three bypasses
close on the shipped guard, and the in-project case is untouched.** This is the task's core claim
and it is real.

---

## 3. Job 2 — every reported tally, cross-checked against the run that produces it

I treated no number as arithmetic. Each row below is the output of a command I ran.

### 3.1 `verify_all`

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

Three consecutive runs, byte-identical. Check count **32**, unchanged, no check added.
`[I.2] Rule fragments ≤200 lines each ... PASS`.

### 3.2 The four driver runs — marker verified present in each

The guard driver's summary marker is `=== test-guard-rm summary ===` (not `=== Result ===`, which
belongs to `test-init`/`test-real-project`). I asserted `grep -c` **= 1** on every run; a missing
marker would have been a failure, not a pass.

| Guard under test | Marker | `PASS` | `FAIL` | Red set (transcribed from that run's failure list) |
|---|---|---|---|---|
| **shipped** `.harness/scripts/guard-rm.sh` | 1 | **87** | **0** | — |
| **pre-change** (`git show HEAD:…`) | 1 | **50** | **37** | `b c e f f2 g h i j k l m n o p q r F2 F3 C10a C10b C12cr C12tee C14 P1 P2 P5 O1 O2 O3 Q2 W1 R1 R2 H1 R4 R5` |
| **round-1** (rows 12/15 back to the raw-`prev` byte) | 1 | **85** | **2** | exactly **`{R1, R2}`** |
| **round-2** (round 3's fix reverted, `-2` → `-1`) | 1 | **85** | **2** | exactly **`{R4, R5}`** |

```
===================== GUARD: /home/alan/Programs/harness-kit/.harness/scripts/guard-rm.sh
driver exit=0
marker count: 1
=== test-guard-rm summary ===
  PASS: 87
  FAIL: 0
-- red count: 0
===================== GUARD: …/guard-pre.sh
marker count: 1
  PASS: 50
  FAIL: 37
===================== GUARD: …/guard-round1.sh
marker count: 1
  PASS: 85
  FAIL: 2
-- red rows: R1 R2
===================== GUARD: …/guard-round2.sh
marker count: 1
  PASS: 85
  FAIL: 2
-- red rows: R4 R5
```

**All four tallies reproduce, and the red set of the pre-change run matches `04_DEVELOPMENT.md`'s
transcription member-for-member (37 ids).** `{R1,R2}` and `{R4,R5}` are disjoint, which is the
positive evidence that CR2-1 was opened by round 2 and closed by round 3.

### 3.3 Collateral, lockstep, parity, ledger

| Claim | My check | Result |
|---|---|---|
| `test-init.sh` | run | `=== Result ===` **PASS: 391 / FAIL: 0** |
| `test-real-project.sh` | run | `=== Result ===` **PASS: 90 / FAIL: 0** |
| `sync-self.sh --check` | run | **`In sync.`** |
| repo ↔ template guard parity | `cmp` | `guard-rm.sh` **identical** (968/968), `guard-rm.ps1` **identical** (933/933). Drivers are correctly *not* in the template (only the guard pair is in sync-self's mirror set) |
| three-way lockstep | counted per artifact | bash driver **87** (from PASS+FAIL of its own run), `test-guard-rm.ps1` **87** `id = ` entries, `evals/guard-rm-cases.md` **92** `^\| ` rows − **5** section headers = **87**. Fixture header reads `87 ↔ 87` |
| `baseline.json` | read | `verify_all_checks: 32`, `test_guard_rm_bash_assertions: 87` — **both match my captured runs**. `test_guard_rm_ps_assertions` **absent**, correctly |
| rule docs | `wc -l` | **199 / 190** after my edit (cap 200) — see §6 |
| `pwsh` | `command -v pwsh` | **absent**, confirmed on this host |

---

## 4. Job 3 — mutation: the new assertions are load-bearing

I rebuilt every mutant myself with `build_variants.py`. **The builder asserts each anchor string
occurs exactly once and aborts otherwise, and it `bash -n`s and byte-compares each output** — a
mutant that silently fails to apply is a false green. I verified the check works rather than
trusting it:

```
built + bash -n clean: guard-round2.sh  (37665 bytes, differs from source)
built + bash -n clean: guard-round1.sh  (37746 bytes, differs from source)
built + bash -n clean: mut-scanner.sh   (37645 bytes, differs from source)
built + bash -n clean: mut-carrier.sh   (37646 bytes, differs from source)
built + bash -n clean: mut-c1.sh        (37653 bytes, differs from source)
built + bash -n clean: mut-prefix.sh    (37651 bytes, differs from source)
anchor-check selftest OK -> ANCHOR MISMATCH in selftest: 'local redir_i=-999' occurs 0 times (want 1)
```

All six re-run through the 87-row driver:

```
===================== MUTANT: mut-scanner
  PASS: 64   FAIL: 23
  red(23): b c e f f2 g i q F2 F3 C10a C10b C12cr C12tee P5 O1 Q2 W1 R1 R2 H1 R4 R5
===================== MUTANT: mut-carrier
  PASS: 80   FAIL: 7
  red(7): j k l m n o O2
===================== MUTANT: mut-c1
  PASS: 86   FAIL: 1
  red(1): C14
===================== MUTANT: mut-prefix
  PASS: 79   FAIL: 8
  red(8): p P1 P2 P3 P4 P5 O1 O3
```

plus the sentinel mutant (`-2` → `-1`) at **2**, red exactly `{R4, R5}`, and the round-1 mutant at
**2**, red exactly `{R1, R2}` (§3.2).

**All five reported mutation counts reproduce — scanner 23, carrier 7, C-1 1, prefix 8, sentinel 2 —
and the red row *identities* match, not just the counts.** The assertions are load-bearing against
both the mechanism (scanner) and the specific one-token fix (sentinel).

---

## 5. Job 4 — false positives, the primary design tension

### 5.1 AC-3's corpus

`L1`…`L14` all hold, with **L10 = BLOCK (exit 2)** per AC-3's round-2 header — recorded as a PASS,
as the criterion requires. Load-bearing rows `L9` (here-document write) and `L11`/`L12` (the guard's
own test-harness invocation) are ALLOW; had they blocked, the suite could not run.

### 5.2 Beyond the corpus — 50 realistic developer commands, **0 false positives**

I wrote `cases_legit.json` from scratch: commands a developer or agent in *this* repo actually
types, deliberately including the ones that would cripple the toolchain if they blocked.

```
  PASS   ALLOW exit=0 G1-heredoc-write    cat > docs/notes.md <<'EOF'\nSome text about rm -rf and deletion.\nEOF
  PASS   ALLOW exit=0 G3-heredoc-dash     cat <<-'EOF' > ./x.txt\n<TAB>indented body\n<TAB>EOF
  PASS   ALLOW exit=0 G4-guard-suite      bash .harness/scripts/test-guard-rm.sh
  PASS   ALLOW exit=0 G5-guard-suite-arg  bash .harness/scripts/test-guard-rm.sh /tmp/scratch/guard-round1.sh
  PASS   ALLOW exit=0 G6-verify-all       bash .harness/scripts/verify_all.sh 2>&1 | tail -20
  PASS   ALLOW exit=0 G7-commit-msg       git commit -m "guard: block rm -rf outside root"
  PASS   ALLOW exit=0 G9-grep-verb        grep -rn 'rm -rf' .harness/scripts
  PASS   ALLOW exit=0 G11-chain-clean     rm -rf ./build && rm -rf ./dist && mkdir -p build dist
  PASS   ALLOW exit=0 G25-live-hook       sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
  PASS   ALLOW exit=0 G37-printf-json     printf '%s' '{"tool_input":{"command":"echo hi && rm -rf /etc/x"}}' | bash .harness/scripts/guard-rm.sh
  PASS   ALLOW exit=0 G43-comment         echo hi   # rm -rf /etc/harness-guard-probe
  … (50 rows total)

=== qa-probe summary ===
  PASS: 50
  FAIL: 0
```

The same 50 lines against the **pre-change** guard: also **50/0 ALLOW**. Zero flips in either
direction — the false-positive budget is not merely met, it is unmoved.

Covered explicitly, as instructed: `cat > f <<'EOF'` heredoc write (G1/G2/G3/G38), the guard's own
test-harness invocation (G4/G5/G37), `git commit -m` with a destructive verb in the message
(G7/G8), `grep` for the string (G9/G10/G24/G50), chained in-project cleans (G11/G12/G13/G16/G19).

### 5.3 The false positives I *did* find

Two of my own ~30 Bash tool calls this session were BLOCKed by the live guard. Both had a one-step
workaround (split the command), and both are in already-documented classes — but they are real
usability cost and I am recording them rather than smoothing them over:

```
PreToolUse:Bash hook error: harness-kit guard-rm: BLOCKED — could not parse the command safely
(unbalanced quotes, nesting past depth 2, or an unterminated here-document);
override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.
```

Reproduced and classified:

| Reproducer | pre | post | Class |
|---|---|---|---|
| `echo "  bash driver rows: $(( $(grep -cE '^    (\"\|\\$?.)' …) ))"` | **BLOCK** | BLOCK | **Pre-existing** — odd quote parity from `\"`; not a T-17 regression |
| `echo "$(basename "$(dirname "$(pwd)")")"` | ALLOW | **BLOCK** | T-17, depth > 2 — documented, and pinned as driver row `F2` |
| `bash ./run.sh --filter 'a(b'` | ALLOW | **BLOCK** | T-17 — interpreter argument with an unbalanced paren judged as a command string. In the documented row `bash <script> "<a command string as an argument>"` (`75-safety-hook.md:100`) |

`bash ./run.sh --msg "hello (world); done"` (balanced) ALLOWs, so the class is narrow: it needs an
*unbalanced* grouping character inside an interpreter argument.

### 5.4 Independent AC-4 differential — my own corpus, my own harvester

I did not re-use the developer's 55 rows. `harvest.py` scrapes command lines from exactly the four
artifact sets AC-4 declares (S1 README/getting-started/dev-map, S2 70 archived stage docs, S3
`hook-spec.{sh,ps1}`, S4 `AI-GUIDE.md`) and runs each against both guards:

```
corpus size (distinct command lines, all from declared artifacts): 140
sources: S1=['README.md','README.zh-CN.md','docs/getting-started.md','docs/dev-map.md']
         S3=['.harness/scripts/hook-spec.sh','.harness/scripts/hook-spec.ps1']
         S4=['AI-GUIDE.md']  S2=70 archived stage docs

*** BLOCK -> ALLOW  (IS-2 violation, unwaivable): 0

ALLOW -> BLOCK  (new over-block): 5
    bash sync-self.sh --check  →  In sync.   (exit 0)                         [_archived/harness-upgrade-skill/06_TEST_REPORT.md]
    bash test-harness-upgrade.sh →  PASS: 37   FAIL: 0   (exit 0)             [_archived/harness-upgrade-skill/06_TEST_REPORT.md]
    bash test-init.sh  →  PASS: 213   FAIL: 0   (exit 0)                      [_archived/harness-upgrade-skill/06_TEST_REPORT.md]
    cat /etc/hostname | xargs -I{} rm /tmp/x/a    -> exit=0      (ALLOWED)     [_archived/hook-truth-status/06_TEST_REPORT.md]
    echo hi && rm /tmp/x/a                        -> exit=0      (ALLOWED)     [_archived/hook-truth-status/06_TEST_REPORT.md]

UNKNOWN exit codes: 0
identical verdicts: 135 / 140
```

I diagnosed all five rather than reporting the count:

- The last two are **the intended fix**. They are the `hook-truth-status` report's own record of the
  original bypass (`echo hi && rm /tmp/x/a` → exit 0); they now BLOCK. That is AC-1 working.
- The first three are harvester artefacts — documentation lines of the form *command + `→` +
  captured result*. The trailing `(exit 0)` makes `(exit` an unbalanced token, and the
  shell-interpreter branch judges it as a command string → parse fail → BLOCK. Isolated, every
  component ALLOWs (`bash sync-self.sh --check` → 0, `echo hi ; (exit 0)` → 0). Same documented
  class as `bash <script> "<arg>"`. **No new class, nothing to record.**

**0 BLOCK→ALLOW over 140 lines. IS-2 holds on my corpus as well as the developer's.**

---

## 6. The CR3-1 fix-forward routed to me (doc-only) — applied *after* empirical confirmation

I verified the class before writing about it (§7.3), and my runs **contradict the reviewer's
description in one respect**, so I wrote what I measured rather than what round 3 described:

- The reviewer groups `'' rm -rf /etc/x` with the executable members. **Bash does not execute it**:
  `bash -c "'' touch …"` → `rc=127`, `bash: line 1: : command not found`, marker absent. It is a
  guard-analysis gap with no executable effect. I said so.
- `xargs bash --rcfile foo -c "…"` **is** executable (marker created, `rc=0`). `xargs sh --rcfile …`
  is **not** (`sh: 0: Illegal option --`, `rc=123`). I named `bash` specifically.
- The redirection members **are** executable, at every position I tried.

Both rule copies now carry (byte-identical text, verified with `diff`):

> 5. **A leading token other than `NAME=`/`NAME+=`, `sudo` or a reserved word hides the verb of its own position** — a redirection (`> f rm -rf /etc/x`,
>    `2>/dev/null rm …`, `2>&1 rm …`, `< /dev/null rm …`), an array element (`a[0]=1 rm …`), an empty token (`'' rm …`), or `xargs bash --rcfile f -c "rm …"`
>    (a carrier's interpreter takes only arg 1). Pre-existing. Bash runs all but the empty form — at any chain position, and in `( )`/`$( )`/`bash -c`.

Line budget, the hard constraint: I first landed a 4-line version at **200 / 191** — which passes
(`verify_all.sh:403` WARNs at `n > 200`) but leaves **zero** headroom on a gate that exits 1 on any
WARN. I re-flowed to 3 lines, giving **199 / 190** — the budget the reviewer predicted, with one
line of headroom preserved.

```
  199 .harness/rules/75-safety-hook.md
  190 skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl
[I.2] Rule fragments ≤200 lines each ... PASS
  PASS: 32   WARN: 0   FAIL: 0
```

`sync-self.sh --check` → **`In sync.`** after the edit (the rule docs are hand-maintained, not in
sync-self's mirror set, so the two copies were edited in lockstep by hand and diffed).

---

## Adversarial tests

_(Section 7. This is the report's hard gate; §7.1–§7.7 below are its subsections.)_

**One stated failure hypothesis per acceptance criterion, an independent reproducer written by me,
and the outcome with tool output.** Where the implementation survived, I say what I tried and why it
held. Where it did not, the finding is in §8.

| AC | Hypothesis ("I expect failure when…") | Reproducer (all NEW, written by me) | Outcome |
|---|---|---|---|
| **AC-1** | a destructive verb is reachable through a form the 19-row matrix does not enumerate — interpreters inside interpreters, loop/conditional bodies, `\|&`, `;&`, `&&&`, stacked carriers, `-execdir`, `!` | `cases_adv.json` D1–D9 + H1–H50 (`probe.py`) | **Survived.** 51 of 113 adversarial lines flipped ALLOW→BLOCK vs pre-change. `bash -c "sh -c \"bash -c 'rm …'\""` → 2, `while :; do rm -rf OUT; done` → 2, `echo hi \|& rm -rf OUT` → 2, `nohup nice timeout 5 rm -rf OUT` → 2, `find . -execdir rm -rf OUT \;` → 2, `! rm -rf OUT` → 2 |
| **AC-2** | the widened parse silently drops a position the old guard judged — i.e. a BLOCK→ALLOW flip somewhere in the pre-existing surface | full differential: 113 + 25 + 140 + 50 + 10 adversarial/legit/corpus lines, **plus 1,500 pseudo-random fuzz inputs** built from 54 shell metacharacter atoms, each ALLOW checked against the pre-change guard | **Survived. 0 BLOCK→ALLOW, everywhere.** `fuzz.py`: `BLOCK(pre) -> ALLOW(post) flips (IS-2 violations): 0` |
| **AC-3** | a legitimate compound command a developer here would really type gets blocked | my own 50-line `cases_legit.json`, run against both guards | **Survived** — 50/50 ALLOW on both guards. Three genuine over-blocks found *outside* that corpus, all in documented classes (§5.3) |
| **AC-4** | the corpus was cherry-picked; a fresh harvest from the same declared artifacts finds a flip | `harvest.py` — my own scraper, 140 distinct lines, S1–S4 | **Survived.** 0 BLOCK→ALLOW; the 5 ALLOW→BLOCK all diagnosed (§5.4), 2 of them are the intended fix |
| **AC-5** | some malformed input makes the guard exit **1** instead of 0/2 — Claude Code treats exit 1 as **non-blocking**, so that is a silent disarm (the bash analogue of the PS R11 hazard) | `fuzz.py`, 1,500 inputs, hunting non-`{0,2}` exit codes; plus `boundary.py` empty stdin / non-JSON / no-`command` | **Survived.** `non-{0,2} exit codes (fail-open candidates): 0`. Unbalanced quotes → 2, unterminated here-doc → 2, wrong terminator → 2, depth 3 (`$( $( $( ) ) )` and `( { $( ) } )`) → 2, unbalanced backtick → 2 |
| **AC-6** | the verb set drifted, or a near-miss verb was quietly added | byte-diff of `destructive_verbs_ci` pre vs post; count the `case` arms; probe `mv`/`cp`/`>`/`truncate`/`dd` | **Survived.** Verb string byte-identical pre and post (`rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm`); 9 arms; PS array 9. `truncate -s0 OUT` → 0, `dd of=OUT` → 0, `mv OUT .` → 0, `echo '' > /etc/passwd` → 0 — unguarded **on purpose** |
| **AC-7** | repo and template guards diverged, or the lockstep count is asserted rather than counted | `cmp` on all four scripts; count 87 in each of the three artifacts separately | **Survived.** `identical: guard-rm.sh` (968/968), `identical: guard-rm.ps1` (933/933); 87 / 87 / 87 counted independently |
| **AC-8** | my doc edit pushes a rule fragment to 201 lines and `[I.2]` WARNs → `verify_all` exits 1 | edit, `wc -l`, re-run `verify_all` | **Survived** — 199/190, `[I.2] … PASS`, 32/0/0. (It *would* have failed at 201; I measured before believing it, and backed off from 200 to 199 for headroom) |
| **AC-9** | the residual list is still incomplete after CR3-1, or overstates coverage in the other direction | probe every residual claim: `command rm` (claimed covered), `'rm'`/`"rm"` (claimed covered), `/bin/rm`/`\rm`/`$(which rm)` (claimed not) | **Survived.** `command rm -rf OUT` → **2**, `'rm' -rf OUT` → **2**, `"rm" -rf OUT` → **2**, `r'm' -rf OUT` → **2**; `/bin/rm` → 0, `\rm` → 0, `$(which rm)` → 0. Residual 1 is accurate in **both** directions |
| **AC-10** | a mutant fails to apply and produces a false green | rebuilt all 6 with an anchor-exactly-once builder + `bash -n` + byte-difference assertion; **self-tested the anchor check with a deliberately wrong anchor** | **Survived.** Selftest aborts as designed; all 6 differ from source; all five red sets reproduce (§4) |
| **AC-11** | a quoted tally is arithmetic rather than a capture | every number in this report re-derived from a run; driver ×10, `verify_all` ×3 | **Survived** — no flakes, no drift |
| **AC-12** | the PS operator list is incoherent, or a phantom `test_guard_rm_ps_assertions` was invented | read items 1–10; `command -v pwsh`; grep `baseline.json` | **Survived, 1 NIT.** 10 items; **item 3 marked security** ("fails OPEN", R11) and **item 10 marked security** ("This is a **security** item, not polish"); key **absent**; no frozen T-13 item reconciled. NIT: item 2 still literally says "(81 rows) … Expect `PASS: 81`" while the twice-amended item 9 says 87 — see §8 NIT-2 |

### 7.1 Verb spelling and indirection

**ALLOW, all pre-existing, all documented (residuals 1–2):** `/bin/rm -rf OUT`, `\rm -rf OUT`
(executable — `\touch` marker created), `$(which rm) -rf OUT`, `./rm -rf OUT`,
`ls | xargs /usr/bin/rm -rf OUT`, `echo hi && /bin/rm -rf OUT`; `eval "rm -rf OUT"`,
`CMD=rm; $CMD -rf OUT`, `alias z=rm; z -rf OUT`, `./cleanup.sh`, `bash cleanup.sh`, `make nuke`,
`ssh host rm -rf OUT`, `git submodule foreach rm -rf OUT`, `P=/etc/…; rm -rf "$P"`.

**BLOCK — the guard is stronger here than residual 1 might suggest:** `'rm' -rf OUT`,
`"rm" -rf OUT`, `r'm' -rf OUT` (quotes stripped), `RM -rf OUT` (case-insensitive),
`command rm -rf OUT` (carrier). One over-performance: `f() { rm -rf OUT; }; f` **BLOCKs** — the
brace-group body is a position, so a function *definition* carrying a literal destructive verb is
caught even though the *call* is not.

### 7.3 The leading-token verb-hiding family — CR3-1, verified empirically in both directions

This is the reviewer's "largest undisclosed gap" and the part of this report that matters most.
**Every member is ALLOW on the shipped guard, and every member is ALLOW on the pre-change guard —
so the class is pre-existing, not a regression. There is no rollback-grade finding here.**

| Probe | pre-change | shipped | bash really executes it? |
|---|---|---|---|
| `> /tmp/log rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `2>/dev/null rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `2>&1 rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `>>f rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `< /dev/null rm -rf OUT` *(mine, beyond the reviewer's list)* | ALLOW | **ALLOW** | **EXECUTED** |
| `3>&1 rm -rf OUT`, `9>/tmp/log rm …`, `&> /tmp/log rm …`, `<<< hi rm …`, `> /tmp/a > /tmp/b rm …` *(mine)* | ALLOW | **ALLOW** | (same mechanism) |
| `echo hi && > /tmp/log rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `echo hi && 2>/dev/null rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `true; >>f rm -rf OUT` | ALLOW | **ALLOW** | **EXECUTED** |
| `( > /tmp/log rm -rf OUT )` *(mine)* | ALLOW | **ALLOW** | **EXECUTED** |
| `echo $(> /tmp/log rm -rf OUT)` *(mine)* | ALLOW | **ALLOW** | **EXECUTED** |
| `bash -c "> /tmp/log rm -rf OUT"` *(mine)* | ALLOW | **ALLOW** | **EXECUTED** |
| `{ > /tmp/log rm -rf OUT ; }`, `` echo `2>/dev/null rm …` ``, `cat <(> /tmp/log rm …)` *(mine)* | ALLOW | **ALLOW** | (same mechanism) |
| `2>/dev/null sudo rm -rf OUT` *(mine — defeats the `sudo` skip too)* | ALLOW | **ALLOW** | — |
| `A=1 2>/dev/null rm -rf OUT` and `2>/dev/null A=1 rm -rf OUT` *(mine)* | ALLOW | **ALLOW** | — |
| **`pwsh -c "> C:\log Remove-Item -Recurse C:\Windows"`** *(mine — the class reaches the Windows path)* | ALLOW | **ALLOW** | — |
| `'' rm -rf OUT` · `"" rm -rf OUT` · `echo hi && '' rm -rf OUT` | ALLOW | **ALLOW** | **NOT executed** — `rc=127`, `bash: line 1: : command not found` |
| `a[0]=1 rm -rf OUT` (already residual 5) | ALLOW | **ALLOW** | **EXECUTED** |
| `xargs bash --rcfile foo -c "rm -rf OUT"` (A-7) | ALLOW | **ALLOW** | **EXECUTED** |
| `xargs sh --rcfile foo -c "rm -rf OUT"` *(mine)* | ALLOW | **ALLOW** | **NOT executed** — `sh: 0: Illegal option --` |

**Two boundaries I found that the reviewer's list does not state, and that make the gap smaller than
it reads:**

```
  BLOCK exit=2 K19-carrier-then-redir   timeout 5 2>/dev/null rm -rf /etc/harness-guard-probe
  BLOCK exit=2 K20-nohup-redir          nohup > /tmp/log rm -rf /etc/harness-guard-probe &
  BLOCK exit=2 C19-env-leading-redir    env FOO=1 > /tmp/log rm -rf /etc/harness-guard-probe
```

An **argv carrier rescues the class**: the carrier scan walks *every* remaining token, so the
leading redirection no longer hides the verb. The gap is confined to a position whose *first* token
is the redirection.

Executability was established with `touch` as the stand-in verb — no destructive verb was ever run:

```
=== executability of guard-ALLOWed forms (touch stands in for the verb) ===
  EXECUTED      C1     > …/log touch …/M1
  EXECUTED      C2     2>/dev/null touch …/M2
  EXECUTED      C5     echo hi && > …/log touch …/M5
  EXECUTED      C11    a[0]=1 touch …/M11
  EXECUTED      C15    ( > …/log touch …/M15 )
  EXECUTED      C17    bash -c "> …/log touch …/M17"
  not-executed  C8     '' touch …/M8
  EXECUTED      A2     \touch …/M2b
```

### 7.4 Depth and interpreters inside interpreters

**All BLOCK:** `bash -c "bash -c 'rm -rf OUT'"`, `bash -c "sh -c \"bash -c 'rm -rf OUT'\""`,
`pwsh -c "bash -c 'rm -rf OUT'"`, `pwsh -c "pwsh -c 'Remove-Item -Recurse C:\Windows'"`,
`ls | xargs -I {} bash -c "rm -rf OUT"`, `nohup bash -c '…' &`, `sh -c '…'`,
`( ( ( rm -rf OUT ) ) )`, `echo $(echo $(rm -rf OUT))`; and past depth 2 —
`echo $(echo $(echo $(rm -rf OUT)))`, `( { $( rm -rf OUT ) } )` — **BLOCK** fail-closed.

**I could not get anything through by nesting.** Every path either judges the verb or fails closed.

### 7.5 The override

| Probe | Verdict | Audit line |
|---|---|---|
| `HARNESS_ALLOW_OUTSIDE_RM=1` in the **hook process environment**, plain `rm -rf OUT` | **ALLOW (0)** | `harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.` |
| same, on a **chained** line `echo hi && rm -rf OUT` | **ALLOW (0)** | same line captured |
| `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` (leading command-text prefix) | **ALLOW (0)** | documented form (OQ-1a) |
| **`echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT`** | **BLOCK (2)** | — |
| `( HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT )` *(mine)* | **BLOCK (2)** | — |
| `bash -c "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT"` | **BLOCK (2)** | — |
| `export HARNESS_ALLOW_OUTSIDE_RM=1 && rm -rf OUT` *(mine)* | **BLOCK (2)** | — |
| `HARNESS_ALLOW_OUTSIDE_RM=0` in the environment *(mine)* | **BLOCK (2)** | — |

**The override authorizes only as a leading prefix on the whole line, exactly as documented, and the
environment-variable form exits 0 with its audit line.** Four independent self-authorization vectors
(mid-chain, subshell, nested interpreter, `export`-then-chain) all block.

### 7.6 Fail-closed

`echo hi && rm -rf '/etc/…` (unbalanced `'`) → **2**; `… "/etc/…` (unbalanced `"`) → **2**;
`` echo `rm -rf OUT `` (unbalanced backtick) → **2**; `cat <<EOF` + body, no terminator → **2**;
`cat <<EOF` + body + `NOTEOF` (wrong terminator) → **2**; depth 3 → **2**.
**No input in any fail-closed set yielded exit 0.**

### 7.7 The attack I most wanted to land, and why it did not

A PreToolUse exit of **1** is treated as *non-blocking* by Claude Code, so any input that makes the
guard exit 1 while carrying a destructive verb silently disarms the hook — the same shape as the
security item the PowerShell operator list marks as R11. I fuzzed 1,500 inputs assembled from 54
shell metacharacter atoms (including NUL, CR, `$'`, `${`, `$((`, `<<EOF`, backticks, process
substitutions, `bash -c`, `pwsh -c`, `find -exec`, unbalanced everything) specifically hunting for
that:

```
fuzz inputs: 1500
non-{0,2} exit codes (fail-open candidates): 0
BLOCK(pre) -> ALLOW(post) flips (IS-2 violations): 0
```

The guard is `set -uo pipefail` without `-e` and routes every unresolved parse to `parse_failed` →
exit 2. I found no crash, no timeout and no third exit code. **This is the strongest single piece of
evidence in this report that the change did not open a fail-open path.**

---

## 8. Defects found

**0 BLOCKER · 0 CRITICAL · 0 MAJOR.** Nothing here blocks delivery.

**MINOR-1 · [DOC/PERF] The shipped rule doc's measured latency table understates the post-change
worst case on this host — and the delivery quotes the optimistic figure.**
`.harness/rules/75-safety-hook.md:122-130`, `01_REQUIREMENT_ANALYSIS.md` §7 NFR-1 table.
I am **not** re-litigating the waived +20 ms clause. I am reporting that two of the four numbers the
waiver rests on did not reproduce. Reproducer (`boundary.py`, 5 iterations each, same host, both
guards driven identically, run twice):

```
  dense &&  (819 separators)         len=8190  pre= 1501.3  post= 3107.1  delta=+1605.8
  dense &&  (819 separators) rerun   len=8190  pre= 1507.1  post= 3110.1  delta=+1603.0
  sparse: one long word              len=8185  pre= 1727.2  post= 1791.3  delta=  +64.2
  here-document 8192                 len=8122  pre= 1782.2  post= 2750.1  delta= +967.8
  typical ~110-char chain                      pre=   41.7  post=   38.2
  echo hi > ./f                                pre=   39.7  post=   32.5
```

The doc says 8192-char `&&` chain **1487 → 2251**; I measure **1501 → 3107**. The *pre-change*
column reproduces almost exactly (1501 vs 1487), which rules out host or load as the explanation for
the post-change gap — it is either the figure or the separator density of the chain that was
measured. The here-document row is worse: doc **1561 → 1659** (+98 ms), measured **1782 → 2750**
(+968 ms), ~10× the stated delta.
**Everything the waiver actually turns on still holds** and I verified each: typical commands got
faster (41.7 → 38.2; 39.7 → 32.5, matching the doc's shape), the worst case is bounded by the 8192
truncation, ~3.1 s is nowhere near a hook timeout, and there is no fail-open path. But
"~2.3 s bounded worst case" is a floor, not a ceiling. **Fix: correct the two figures, or state the
chain composition they were measured on.** Owner: PM at archive / requirement-analyst. Doc only.

**MINOR-2 · [DOC] The operator PowerShell list contradicts itself on the row count.**
`04_DEVELOPMENT.md:459-496` item 2 still reads "(81 rows) … Expect `PASS: 81 / FAIL: 0`". Item 9 was
amended in round 2 to 85 and in round 3 to **87**. An operator working the list top-down hits the
stale expectation first, on the one instrument that can distinguish "symmetric by construction" from
"symmetric in fact". The list is otherwise coherent: **10 items, item 3 and item 10 both explicitly
marked security**, `test_guard_rm_ps_assertions` correctly absent, no frozen T-13 item reconciled.
**Fix: one number.** Owner: PM at archive.

**MINOR-3 · [TEST] The residual surface this delivery publishes is not pinned by any test.**
The 87-row suite contains no row for the CR3-1 class. Nothing in the suite, and none of the six
mutants, would go red if a future change altered the behaviour of `> f rm -rf OUT` in either
direction — so the newly published residual line can silently become false. I deliberately did
**not** add rows: doing so changes the row set, which invalidates every tally quoted in this
delivery (87, 50/37, 85/2 ×2, and all five mutation counts) and requires three-artifact lockstep
plus a `sync-self` run. **Recommendation for a follow-up pool row**, with the decision the PM has to
make attached: pinning `> f rm -rf OUT` → ALLOW documents-by-test but also *pins a hole open*; the
alternative is to pin it only once the class is fixed. Owner: PM to schedule.

**MINOR-4 · [DOC] An executable path-axis false negative not named anywhere.**
`rm -rf $'/etc/harness-guard-probe'` → **exit 0**, and bash **does** execute it (verified with
`touch $'…'` → marker created). Pre-existing (`ALLOW` on the pre-change guard too) and arguably
inside residual 4 ("paths that are not literal text"), but residual 4's examples are `$HOME/x` and
`$(cat list)` — a reader would not predict that an ANSI-C-quoted *literal* path is unresolved. Same
family: `rm -rf ~/x` **BLOCKs** but `rm -rf $HOME/x` ALLOWs. Path resolution is explicitly out of
this task's scope (OQ-2/OQ-3), so this is disclosure, not a fix. I did not add it to residual 4:
the file has one line of headroom and MINOR-1's correction has a stronger claim on it.

### NITs (do not block)

- **NIT-1** `_qa_note_t17` in `baseline.json` is accurate and matches my runs (87 = 17 + 64 + 4 + 2;
  50/37; both red sets). No action.
- **NIT-2** `04_DEVELOPMENT.md` is 1305 lines against the 500-line soft cap (CR3-3, already
  self-disclosed, PM-owned at archive). Confirmed still true; ungated, so `verify_all` cannot see it.
- **NIT-3** The coverage table's redirection row (`75-safety-hook.md:57`) — "Redirection operators
  and targets … Not command positions" — is *true* but is the sentence a reader will use to conclude
  the redirection case is handled. Residual 5 now says otherwise three lines later. A cross-reference
  would close the loop; not worth a line at 199/200.
- **NIT-4** `evals/guard-rm-cases.md` row count is verifiable only as 92 `^| ` rows minus 5 section
  headers. A future counter that greps naively will get 92 and "fix" a non-existent drift.
- **NIT-5 (mine)** This report is over `.harness/rules/70-doc-size.md`'s 500-line per-stage-doc cap.
  I compacted the redundant sections and kept the captured output, because captured output is the
  thing a QA report exists to carry — but I am flagging my own deviation rather than only NIT-2's.
  Same disposition as CR3-3: soft, ungated, PM-owned at archive.

---

## 9. Boundary tests added / executed

| Boundary | Probe | Result |
|---|---|---|
| **B-1** empty stdin · JSON without `tool_input.command` · non-JSON · empty command | `boundary.py` | all **exit 0** |
| **B-2** >8192 characters | `rm` hidden past the cut → **ALLOW** (residual 6, as documented); `rm` before the cut → **BLOCK**; >8192-char here-document write → **BLOCK** (truncation leaves it unterminated → fail-closed, exactly as B-2 requires) | recorded |
| **B-3** empty position between separators | driver `N2`/`N3`; `R4` (`& rm -rf OUT` → **BLOCK**) — the boundary CR2-1 violated and round 3 restored | **PASS** |
| **B-4** unbalanced quotes | `F1`/`F2` + my `F1-unbalanced-sq`/`F2-unbalanced-dq`/`F7-unbalanced-backtick` | all **BLOCK** |
| **B-5** nesting past depth 2 | `F3-depth3-cmdsub`, `F6-depth3-mixed` | **BLOCK** |
| **B-6** no `.git/` ancestor | run with `cwd=/tmp` | **exit 0** + `harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.` |
| **B-7** env override | see §7.5 | **exit 0** + audit line captured |
| **B-8/B-9** separators and escaped quotes inside quoted regions | `W1`–`W4`, `H32-semi-in-dq-then-real` (`echo "a;b" ; rm -rf OUT` → **BLOCK**: the quoted `;` is not a separator, the real one is) | **PASS** |
| **B-10** newline / CRLF | `f`, `f2`, `C12cr`, my `H27-newline-cr` (`echo hi\r\n\rrm -rf OUT` → **BLOCK**) | **PASS** |
| **B-11** multiple offending paths | `rm -rf /etc/probe-a && rm -rf /etc/probe-b ; rm -rf /etc/probe-c` → **exit 2 once**, message names `/etc/probe-a`, `/etc/probe-b`, `/etc/probe-c` (de-dup not required) | **PASS** |
| **B-12** concurrency | **12 parallel** guard invocations, alternating expected ALLOW/BLOCK: `results == expected` → **MATCH**. Stateless: no temp file, no lock | **PASS** |
| **B-13** verb only in a here-doc body / comment / quoted literal | `L7`, `L9`, `G43-comment`, `H33-rm-after-heredoc` (verb *after* a terminated here-doc → **BLOCK**, correctly) | **PASS** |
| **B-14** `patsub_replacement` | grep: only the two pre-existing exempt lines `guard-rm.sh:90-91` | **PASS** |
| Unicode / non-ASCII | `echo hi &&<NBSP>rm -rf OUT` → ALLOW — but bash does **not** execute it (`bash: line 1: <NBSP>rm: command not found`). Not a bypass | recorded |
| Path traversal | `rm -rf ./build/../../../../etc/…` → **BLOCK**; `rm -rf -- /etc/…` → **BLOCK**; `rm --recursive --force /etc/…` → **BLOCK**; `rm -rf /etc/harness-guard-*` → **BLOCK**; `rm -rf /etc/{a,b}` → **BLOCK**; `rm -rf "/etc"/…` → **BLOCK** | **PASS** |

---

## 10. Stability

| Suite | Runs | Result |
|---|---|---|
| `test-guard-rm.sh` (87 rows, live guard) | **10** | `PASS: 87 / FAIL: 0` every run — **no flakes** |
| `verify_all.sh` | **3** | `PASS: 32 / WARN: 0 / FAIL: 0` every run — **no flakes** |
| 12 parallel guard invocations | 1 | verdicts exactly as expected — **stateless, no interference** |
| `harvest.py` differential (140 lines × 2 guards) | 2 (31-line and 140-line configurations) | consistent |
| latency benchmark | 2 | `3107.1` / `3110.1` ms — stable to 0.1 % |

**No flaky test observed.**

---

## 11. `verify_all` result and baseline

- **Total `verify_all` checks: 32 → 32** (frozen, as AC-8 requires; no check added, removed or modified)
- **PASS: 32 · WARN: 0 · FAIL: 0** — before my doc edit and after it
- Guard driver assertions: **87 → 87**
- New tests added to the pinned suite: **0** (see MINOR-3 for the reason and the recommendation)
- New QA tests written and executed this session: **~1,870 probe executions** across 9 corpora,
  retained as artifacts (`probe.py`, `build_variants.py`, `harvest.py`, `fuzz.py`, `boundary.py`,
  `exec_check.sh`, and 8 case files)
- **`baseline.json` updated: NO — and it did not need to be.** Both pinned values already match my
  captured runs (`verify_all_checks: 32`, `test_guard_rm_bash_assertions: 87`). Nothing moved down.
  `test_guard_rm_ps_assertions` remains correctly **absent**; I did not invent it.

---

## 12. PowerShell — not tested, and deliberately so

`command -v pwsh` → **absent on this host**. I ran **nothing** against `.ps1`, and I am **not**
treating the 87-row bash green as evidence about the PowerShell twin.

What I did check (read-only, and the only things that are checkable here):

- The standing operator list has **10 items** (1–7 round 1, 8–9 round 2, 8/9 amended + 10 added
  round 3) and is coherent apart from MINOR-2.
- **Item 3** is marked security — R11, "an escaping terminating error … exits **1**, which Claude
  Code treats as non-blocking, silently disarming the Windows guard".
- **Item 10** is marked security — "This is a **security** item, not polish: the vector
  `pwsh -c "& …"` is a PowerShell one."
- `test_guard_rm_ps_assertions` is absent from `baseline.json`, with the "do not invent one" warning
  intact. I did not reconcile it and did not reconcile any frozen T-13 item.
- `test-guard-rm.ps1` carries **87** `id = ` entries, matching the bash driver and the fixture.
- Repo ↔ template `guard-rm.ps1` are byte-identical (933/933).

One finding from my bash runs is **directly relevant to the PS risk** and belongs in the operator
list: the CR3-1 class reaches the PowerShell path —
`pwsh -c "> C:\log Remove-Item -Recurse C:\Windows"` → **exit 0** (§7.3). Worth adding as an
item-8 probe when an operator finally runs the twin.

---

## 13. The residual bypass surface I could not close

**This is the statement that must go into the delivery.** Every line was verified by me, on this
host, in this session — not inherited from the review.

1. **Verb spelling.** `/bin/rm`, `\rm`, `$(which rm)`, `./rm` — **ALLOW**, and bash executes them.
   `'rm'`, `"rm"`, `command rm`, `RM` are **caught**. *(Documented, residual 1 — accurate in both
   directions; I checked both.)*
2. **Indirection.** `eval "$X"`, `$CMD -rf …`, aliases, `./script.sh`, `bash script.sh`, Makefile
   targets, `ssh host rm …`, `git submodule foreach rm …` — **ALLOW**. Out of reach for a text-only
   guard. *(Documented, residual 2.)*
3. **The verb is not at token 0 of its position — the largest gap, and now disclosed.** A **leading
   redirection** (`> f rm -rf /etc/x`, `2>/dev/null rm …`, `2>&1 rm …`, `>>f rm …`, `< /dev/null rm …`,
   `3>&1 rm …`, `&> f rm …`, `<<< x rm …`) hides the verb of its own position — at **any** position of
   a chain, and inside `( )`, `{ }`, `$( )`, backticks, `<( )` and `bash -c`, **and inside
   `pwsh -c`**. Bash really executes all of these. It also defeats the `sudo` skip
   (`2>/dev/null sudo rm …`) and combines with assignment prefixes. Same family: an
   **array-element assignment** (`a[0]=1 rm …`, executable) and `xargs bash --rcfile f -c "rm …"`
   (executable; the `sh` variant is not). An **empty leading token** (`'' rm …`) is a guard-analysis
   gap but bash does **not** execute it, so it is not a live bypass.
   **Bounded by:** an argv carrier rescues the class — `timeout 5 2>/dev/null rm …`,
   `nohup > f rm …` and `env FOO=1 > f rm …` all **BLOCK**, because the carrier scan walks every
   remaining token. **All of it is pre-existing** — identical verdicts on the pre-change guard, so
   IS-2 and AC-4 stand and this is not a regression. **Now published** in both rule copies (§6).
4. **Non-literal and expansion-bearing paths.** `rm -rf $HOME/x` and `rm -rf $'/etc/x'` — **ALLOW**
   and executable; `cd` is not modelled, so `cd / && rm -rf etc/x`, `cd /tmp && rm -rf ./x` and
   `pushd /etc && rm -rf ./x` all **ALLOW**. Symlinks are leaf-only by design. *(Residuals 3–4;
   the ANSI-C form is MINOR-4.)*
5. **Past 8192 characters.** Unjudged — verified: a `rm -rf OUT` after 8300 characters of padding
   exits 0; the same verb before the cut exits 2. *(Documented, residual 6.)*
6. **The override authorizes the whole line**, deliberately, as a leading prefix only. Every
   self-authorization vector I tried (mid-chain, subshell, nested interpreter, `export`-then-chain)
   BLOCKs. *(Documented, residual 7.)*
7. **Scope and shell.** `PreToolUse` governs only Claude Code's Bash tool. **The PowerShell twin has
   never been executed anywhere**, and its highest-probability defect (R11) fails **open**. On the
   operational axis this is the largest residual risk in the delivery, and no bash evidence speaks
   to it. *(Documented, residual 8; operator items 3 and 10.)*
8. **By design, not a defect.** Nine verbs; `mv`, `cp`, `truncate`, `dd` and `>` truncation are
   unguarded on purpose — verified: `mv /etc/x .` → 0, `cp x /etc/x` → 0, `truncate -s0 /etc/x` → 0,
   `dd of=/etc/x` → 0, `echo '' > /etc/passwd` → 0. Depth > 2, unbalanced quotes and unterminated
   here-documents **BLOCK**, and the over-block surface is a strict superset of the pre-v0.46 one.

**Within that surface, what shipped is real and I confirmed it independently:** the nine-verb rule is
now evaluated at every command position the guard can identify — `;`, `&&`, `||`, `&`, newlines and
CRLF, subshells, brace groups, command substitutions, backticks, process substitutions, argv
carriers, loop and conditional bodies, and nested `bash -c` / `sh -c` / `pwsh -c` strings — where
before it saw only the first token of each top-level pipe segment, and `echo hi && rm -rf /etc/x`
exited 0.

---

## 14. Verdict

**PASS WITH NOTES — APPROVED FOR DELIVERY.**

`verify_all`: **PASS 32 / WARN 0 / FAIL 0** (32 checks, frozen; 3 identical runs).
`test-guard-rm.sh`: **PASS 87 / FAIL 0** against the shipped guard (10 identical runs);
**PASS 50 / FAIL 37** against the pre-change guard;
**PASS 85 / FAIL 2** against the round-1 guard, red exactly `{R1, R2}`;
**PASS 85 / FAIL 2** against the round-2 guard, red exactly `{R4, R5}`.
Mutations: scanner **23**, carrier **7**, C-1 **1**, prefix **8**, sentinel **2** — all reproduced,
red-row identities included, with an anchor-match builder whose failure mode I self-tested.
Collateral: `test-init.sh` **391/0**, `test-real-project.sh` **90/0**. `sync-self --check` →
**`In sync.`**. Rule docs **199 / 190** (cap 200), `[I.2] PASS`. Three-way lockstep **87/87/87**.
Guards repo ↔ template byte-identical (968/968, 933/933). Baseline preserved at 32 / 87, matching
its runs; no PS key invented.

**0 BLOCKER, 0 CRITICAL, 0 MAJOR.** Four MINOR findings, all documentation or scheduling, none
touching guard behaviour, none requiring a stage-4 round: MINOR-1 (two latency figures in the rule
doc did not reproduce; the waiver's conclusion is unaffected), MINOR-2 (one stale row count in the
operator PS list), MINOR-3 (the published residual is not pinned by a test — recommendation, with
the tradeoff stated), MINOR-4 (an ANSI-C-quoted path is an executable path-axis false negative,
pre-existing and out of this task's scope).

The one fix-forward routed to me is done: **CR3-1's residual line is in both rule copies**, written
from my own empirical runs — including the two places where those runs contradicted the description
I was handed (`'' rm …` does not execute; `xargs sh --rcfile` does not execute) — at 199/190 with
`[I.2]` still passing.

I attacked this guard for the whole session — verb spelling, indirection, the leading-token family
in fourteen variants across five nesting contexts, interpreters inside interpreters, four override
self-authorization vectors, unicode, CRLF, truncation, path traversal, and 1,500 fuzz inputs hunting
specifically for the exit-1 silent-disarm — and I did not find a single BLOCK→ALLOW flip, a single
non-`{0,2}` exit code, or a single false positive on fifty realistic commands. Everything I got
through was already ALLOW on the pre-change guard, and the largest such class is now published.

---

# Round 2 — MINOR-1 fix-forward: the published latency figures, re-measured

Round 1 above is the record and is unchanged. This section records one scoped documentation
correction routed back to me, the method behind it, and the re-verification. **No production code,
driver, eval, baseline or other stage doc was touched** — the change is two rule-doc copies.

## What I re-measured, and how

Host: `Linux 6.8.0-136-generic x86_64`, `12th Gen Intel(R) Core(TM) i5-12400` (12 threads),
`GNU bash 5.2.21(1)`, `Python 3.12.3`, load average `1.34 / 1.75 / 2.09` at start and
`1.21 / 1.77 / 2.06` at end (so no load excursion across the window).

Method, deliberately stronger than round 1's single pass:

- **3 independent repeats** of the whole matrix × **10 invocations** per (guard, case); the repeat
  is the outer loop, so host drift shows up as spread *between* repeats instead of hiding inside
  one mean. Reported value is the **median of the 3 repeat-means**, with min-max quoted.
- Pre- and post-change guards alternate **inside** each repeat, so any slow window hits both.
- Pre-change guard = `git show HEAD:.harness/scripts/guard-rm.sh`, verified byte-identical to the
  round-1 pre-change copy (`PRECHANGE-GUARD == HEAD guard (byte-identical)`).
- The shipped guard's mtime (`23:55:04`) predates every round-1 and round-2 measurement, so both
  rounds timed the **same build**. The build is not a variable.
- No deletion anywhere: every payload is fed to a guard on stdin and only its exit code is read.

Drivers: `t17/remeasure.py`, then `t17/variants.py` and `t17/heredoc.py` to isolate the cause of the
round-1 / round-2 disagreement.

## Result — and why round 1 and the developer's table both reproduced

```
=== medians of 3 repeats x 10 invocations ===
case                        chars    pre(med) pre[min-max]           post(med) post[min-max]
typical ~110-char chain        91        43.3 [   39.8-   45.1]        39.9 [   36.1-   41.7]  ratio=0.92x
echo hi > ./f                  13        41.9 [   37.4-   42.4]        35.2 [   32.6-   36.0]  ratio=0.84x
8192 && chain (819 seps)     8192      1478.7 [ 1473.4- 1508.8]      2266.0 [ 2256.9- 2315.1]  ratio=1.53x
8192 single long word        8185      1707.5 [ 1703.2- 1768.6]      1739.7 [ 1729.8- 1740.5]  ratio=1.02x
8192 here-document           8192      1657.1 [ 1587.4- 1662.1]      1657.9 [ 1636.4- 1722.3]  ratio=1.00x
```

That run reproduces the **developer's** figures (2251, 1659), not my round-1 figures (3107, 2750) —
so before correcting anything I had to find out which measurement was wrong. Neither was. The
variable is **payload shape**, and it is worth ~40 %:

```
=== variant sweep (median of 3 reps x 5 invocations) ===
  dense 819 && , stdout/err PIPE         len=8190  rc=[0]      pre= 1505.2 [ 1496.6- 1542.4]  post= 3119.0 [ 3059.4- 3154.3]
  dense 819 && , stdout/err DEVNULL      len=8190  rc=[0]      pre= 1513.8 [ 1492.0- 1540.3]  post= 2987.6 [ 2984.0- 3077.4]
  dense && + in-project rm               len=8192  rc=[0]      pre= 1539.0 [ 1529.2- 1653.7]  post= 2227.7 [ 2220.7- 2275.4]
  dense && + OUTSIDE rm (BLOCK)          len=8131  rc=[0, 2]   pre= 1452.3 [ 1443.5- 1496.5]  post= 2214.9 [ 2186.1- 2242.2]
  here-doc 400 lines (len<8192)          len=15519 rc=[0, 2]   pre= 1580.0 [ 1575.8- 1626.6]  post= 1578.6 [ 1573.5- 1625.0]
  here-doc truncated to 8192             len=8192  rc=[0, 2]   pre= 1573.9 [ 1545.2- 1622.6]  post= 1538.0 [ 1524.9- 1599.3]

=== here-document shapes (median of 3 reps x 5 invocations) ===
  TERMINATED here-doc, fits under 8192     len=8189  rc(pre/post)=0/0  pre= 1561.7 [ 1549.1- 1606.4]  post= 2159.0 [ 2145.3- 2203.1]
  UNTERMINATED (truncated at 8192)         len=8192  rc(pre/post)=0/2  pre= 1569.4 [ 1560.9- 1590.0]  post= 1552.9 [ 1552.1- 1601.1]
  819 && , trailing empty segment          len=8190  rc(pre/post)=0/0  pre= 1453.9 [ 1445.8- 1508.3]  post= 3009.0 [ 2928.1- 3013.4]
  819 && , trailing real command           len=8192  rc(pre/post)=0/0  pre= 1453.2 [ 1451.1- 1502.7]  post= 2214.5 [ 2197.9- 2280.8]
```

Two shape effects, both reproducible, neither host load:

1. **Trailing empty segment.** `("echo a && " * 819)` ends in a separator, leaving an empty final
   position: **3009-3119 ms**. The same length ending in a real command: **2215-2228 ms**. My
   round-1 3107.1 / 3110.1 was the first shape; the doc's 2251 was the second. Both were correct
   measurements of different lines.
2. **Terminated vs truncated here-document.** A here-doc that *closes* inside 8192 characters is
   parsed in full: **2159 ms**. One truncated at 8192 is unterminated, so the guard exits
   **fail-closed early** and costs **1553 ms** — cheaper than the pre-change guard. The doc's 1659
   was the cheap (fail-closed) shape; my round-1 2750 was a terminated one. I could not reconstruct
   round-1's exact 8122-character body (it was built inline and never saved to disk), so I do not
   republish that single figure — the band below covers it.

So MINOR-1's *diagnosis* — the shipped figures are optimistic — stands: 2251 and 1659 are each the
cheap end of their own shape. But its implied fix (swap in 3107/2750) would have been just as
false-precise. Replacing four integers with four other integers would have needed correcting again.

## What I changed in the two rule copies

`.harness/rules/75-safety-hook.md` and its `.tmpl` twin, **Wall-clock cost** section, replaced with
a range plus the reason for the range:

> Bash guard, Linux/i5-12400/bash 5.2, median of 3 repeats × 10 invocations, pre → post. Typical
> commands got **faster** (~20 forks per segment removed): ~110-char chain 43 → **40 ms**,
> `echo hi > ./f` 42 → **35 ms**. A full 8192-character line — the truncation bound, so the worst
> case — was ~1.5 s and is now **~1.5-3.1 s**, the spread set by shape not length: a dense
> 819-`&&` chain is dearest, one long word or a fail-closed here-doc cheapest. Order of magnitude on
> this host, not a budget — `${s:$i:1}` is O(i), so every character pass is O(n²), the scanner adds
> a third, and the pre-change guard already paid most of it. Nothing forks per token: a slow block
> means a long command, not a process storm, far from any hook timeout; no path fails open.

Kept, because it is true and load-bearing: typical commands got *faster*; the worst case is bounded
by the 8192 truncation; no hook-timeout risk; no fail-open path; the root cause is `${s:$i:1}` being
O(i), with the pre-change guard already paying most of it. The retired "under 50 ms" claim stays
retired (heading unchanged; the `[I.6]` retired-phrase check still PASSes). Every number published
is one I measured in this session, and the band `~1.5-3.1 s` contains all four post-change
8192-character shapes I could produce, as well as both round-1 readings.

**MINOR-4 made it in**, at zero net lines, by re-flowing residual 4 rather than appending to it:

> 4. **Paths that are not literal text** — `rm -rf $HOME/x` resolves the literal token, so it ALLOWs
>    where `~/x` BLOCKs; so does `rm -rf $'/etc/x'`, an ANSI-C-quoted *literal* that bash does
>    execute. [...]

The CR3-1 residual (item 5) is untouched — I re-read it after the edit and it is byte-identical to
what round 1 landed.

## Byte-identity of the two copies

```
PERF BLOCK (heading+paragraph): byte-identical across both copies
bfe7dbb3e38ad0c2e77cc91a003df334  75-safety-hook.md.perf2
bfe7dbb3e38ad0c2e77cc91a003df334  75-safety-hook.md.tmpl.perf2
RESIDUAL 4: byte-identical
ba79d5b153c3a5ac7ba36c429a707a90  75-safety-hook.md.r4
ba79d5b153c3a5ac7ba36c429a707a90  75-safety-hook.md.tmpl.r4
```

A whole-file `diff` of the two copies shows **only** the five pre-existing intentional divergences
(dogfood note, `install-hooks` paragraph, two failure-mode rows, nested-clone wording). Neither
edited region appears in that diff.

## Re-verification (quoted from the runs)

```
$ wc -l .harness/rules/75-safety-hook.md skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl
  200 .harness/rules/75-safety-hook.md
  191 skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl

$ bash .harness/scripts/verify_all.sh
[I.2] Rule fragments ≤200 lines each ... PASS
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
EXIT=0

$ bash .harness/scripts/test-guard-rm.sh
=== test-guard-rm summary ===
  PASS: 87
  FAIL: 0
EXIT=0
```

The repo copy is at **200 / 200** — exactly at the cap, zero headroom left. `[I.2]` WARNs only at
`> 200`, so 200 PASSes, but the next line added to this file fails AC-8. Stability: `verify_all` and
the driver were each run **twice** after the edit, both times `32 / 0 / 0` and `87 / 0`. The driver
run is a no-change confirmation (I edited a rule doc, not code) and it was confirmed, not assumed.
Check count unchanged at 32, verb set untouched, no check added, `baseline.json` untouched, nothing
committed.

One incidental dogfood datum: my first attempt to append this section was **BLOCKED** by the shipped
guard — a heredoc carrying this text has odd quote parity, exactly the accepted over-block the rule
doc documents ("An odd `'` or `"` anywhere — including inside a here-document body"). The published
over-block table is accurate in live use, not just in the driver.

## Round-2 verdict

**APPROVED FOR DELIVERY.** MINOR-1 is closed by correction: the published latency claim is now a
measured range with its shape dependence named, sourced entirely from runs in this session, and it
should not need correcting on different hardware. MINOR-4 is closed by disclosure inside residual 4.
MINOR-2 (developer document) and MINOR-3 (follow-up pool row) remain open and belong to the PM.
