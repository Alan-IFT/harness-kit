# 06 — Test Report · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 6 (qa-tester) · **Date**: 2026-07-31
**Upstream**: `01_REQUIREMENT_ANALYSIS.md` (READY + Amendment 1) · `02_SOLUTION_DESIGN.md` (READY, rework 1) · `03_GATE_REVIEW.md` (APPROVED 8/8) · `04_DEVELOPMENT.md` (READY FOR REVIEW, **rework 3**) · `05_CODE_REVIEW.md` (**APPROVED WITH NITS**, 0 CRITICAL / 0 MAJOR / 5 MINOR / 2 NIT)

> **Inheritance policy.** Nothing in `04_DEVELOPMENT.md` was accepted as evidence. Every number
> below comes from a run I made in this session; the reproducers under "Adversarial tests" were
> written from the acceptance criteria, not from the developer's test code.

## **FINAL VERDICT: PASS** *(round 3, §13.9)* — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR /
2 NIT record-only (+1 MINOR owned by PM). **r-7 is CLOSED.** Rounds 1 (§1-§11) and 2 (§12) are
retained below in compacted form; their verdicts are superseded.

## 1. MANDATE 1 — the three re-captured claims (round 1, none inherited)

`verify_all` bash **32/0/0**, `grep -cE '\.\.\. (PASS|WARN|FAIL)'` = **32**, 3 consecutive runs ✅ ·
`test-init.sh` no-python3 **354/0, exit 0, 3 SKIP** (shim exiting 9) ✅ · python3 **390/0** ✅ ·
`cmp` pre- vs post-M-1 generated file **BYTE-IDENTICAL**, `sha256 536f3e01…` both sides ✅.

**The `cmp` was reconstructed, not inherited.** The pre-M-1 installer no longer exists on disk,
so I rebuilt it from the M-1 delta in `05_CODE_REVIEW.md` §1 and ran both installers in identical
fixture trees: `cmp` silent, `sha256 536f3e01…b49a9` both sides — confirming the reviewer's §3
structural argument **by execution**. It is also the sha the live `.claude/settings.local.json` carries.

## 2. Test plan — every acceptance criterion mapped to an executed check

| AC | Check(s) | Where |
|---|---|---|
| AC-1 spec answers both axes | 8 cells × (`command` + `semantics`), exit 0, non-empty | captured inline §2.1; `test-init.sh` `[T-13][A]`/`[B]` |
| AC-2 semantics + guard not weakened | 4 × `semantics`; both guard commands scanned for `\|\| exit 0` / `exit 0` / `-EA SilentlyContinue` | FC-3 §5; `[T-13][B]` |
| AC-3 byte-identity, proven | **QA reproducer `qa_ac3.sh`**: 8 cells × **2 live oracles** = 16 comparisons + 2 anti-vacuity | §3 A-1 |
| AC-4 congruence token survives | **QA reproducer `qa_ac4.sh`**: production ERE from `migrate-scripts-layout.sh:260` + on-disk existence check | §3 A-2 |
| AC-5 bootstrap a missing local file | live dogfood delete → run → JSON parse, `$schema`, event set, matcher, BOM/CR/newline | §4 |
| AC-6 idempotent, no backup | snapshot → 2nd + 3rd run → `cmp` → `find` for any sibling | §4 |
| AC-7 no double-wire | `qa_boundary.sh` §8 row 2 (committed hooks present) | §6 |
| AC-8 gate green from bootstrapped state | `verify_all` re-run after the AC-5 bootstrap | §1, §4 |
| AC-9 guard actually guards | **QA reproducer `qa_ac9.sh`**: 6 probes driven through the command **parsed from the generated file** | §3 A-3, §5 |
| AC-10 cross-shell byte parity | ❌ not executable — PowerShell absent. Green-by-symmetry-only | §8 |
| AC-11 both shells symmetric | 4/4 mirror halves `diff`-clean; F.1 array carries `hook-spec`; `sync-self --check` = In sync | §7 |
| AC-12 release-claim consistency | both README badge sets frozen; `verify_all_checks` 32; G.3/G.4 PASS | §7 |
| AC-13 documentation truthful | `75-safety-hook.md:88-111` disable path read + the documented opt-out byte-form executed | §7 |
| AC-14 report complete, no `.gitignore` move | captured stdout + `git status --porcelain` + `git check-ignore -v` | §4 |

## 3. Adversarial tests (REQUIRED — one predicted failure per acceptance criterion)

Reproducers are QA-owned, at `…/scratchpad/qa/` (`qa_ac3.sh`, `qa_ac4.sh`, `qa_ac9.sh`,
`qa_boundary.sh`, `qa_failclosed.sh`, `qa_fc4_variants.sh`). They are **not** added to the repo
suite: OQ-9a/§3.6 forbid a new driver *pair*. 79 QA assertions ran.

### The two targets the reviewer nominated

| # | Hypothesis ("I expect failure when…") | Reproducer (NEW, mine) | Outcome |
|---|---|---|---|
| **r-1** | the spec answers 4 **duplicate** ids including `guard-rm`: `== 4` passes, both restored literals pass, every spec-derived per-tool check passes ⇒ exit 0 with one event wired | `qa_fc4_variants.sh` — mutates `hook-spec.sh:120`'s fixed `printf`, i.e. the **artifact** | **CONFIRMED — reviewer's reasoning holds empirically.** MINOR |
| **r-2a** | reverting arity to `> 0` leaves the FC-4 row green (row not load-bearing) | template installer mutated to `> 0`, full `test-init.sh` | **SURVIVED — row IS load-bearing.** Exactly 1 red, 389/1 |
| **r-2b** | a silently broken stub makes the FC-4 row pass without reaching the arity branch | stub `hs_good` repointed at a nonexistent path | **CONFIRMED — vacuity vector is real.** 390/0, row green |

**Round-1 degradation matrix** (7 artifact mutations, `hook-spec.sh:120`'s fixed `printf`
rewritten, assertion list untouched) — **superseded by the re-measured §12.3**. Summary: 4
distinct ids ⇒ exit 0, 4 events wired; **4 duplicate ids ⇒ exit 0, one event**; **4 mixed dupes
⇒ exit 0, three events**; **4 valid ids w/o guard ⇒ exit 5 but file PRESENT and guardless, so
run 2 exits 0**; 3 ids / 5 ids / bogus id ⇒ exit 4, ABSENT. Rows 2-3 filed MINOR **r-1**, row 4
filed MINOR **r-6** (new, mine). r-2a arity → `> 0` ⇒ **389/1**, one red (row IS load-bearing);
r-2b stub → nonexistent path ⇒ **390/0**, row green without reaching the arity branch
(**vacuity vector real**). Proposed close (verified in scratch): also `grep -qF` the diagnostic.

### One hypothesis per acceptance criterion

| AC | Hypothesis | Reproducer | Outcome |
|---|---|---|---|
| AC-1 | some `(tool, OS)` cell returns empty or non-zero | 8 cells × `command`+`semantics` | **Survived** — 8/8, rc 0/0, lengths 83–251 |
| AC-2 | the *unix* guard form hides an `exit 0` inside the `sh -c '…'` body | substring scan of live output, both OS | **Survived** — `\|\| exit 0`, `exit 0`, `-EA SilentlyContinue` all absent; `-NoProfile` ×2 on Windows (NFR-3) |
| AC-3 | Group A is a fixture compared to itself, so 8/8 green proves nothing | `qa_ac3.sh` — **sed** range (not awk) into two *namespaced* functions, 8 cells vs `upgrade-project.sh` **and** `migrate-scripts-layout.sh` | **Survived** — 18/18. Then I **mutated the artifact**: `hook-spec.sh:109` gained `\|\| exit 0` ⇒ my reproducer 16/2 and the developer's driver went **exactly 3 red** ([A], [A'], [B] for guard-rm unix). Independence proven both ways |
| AC-4 | the ERE is loose enough to match anything | `qa_ac4.sh` — ERE lifted from the **production** consumer + negative control + on-disk existence | **Survived** — 9/9; negative control extracts nothing |
| AC-5 | the created file is not real JSON, or carries a doc key inside `hooks`, or a BOM | live delete → install → `json.load`, indent-4 `_` grep, `od` on first/last bytes | **Survived** — parses; root keys `$schema,_comment,_hook_semantics,hooks`; 0 indent-4 `_` keys; first byte `7b`, last two `7d 0a`, zero CR |
| AC-6 | a 3rd run, or a concurrent run, leaves a temp/backup sibling | 3 sequential + 2 concurrent runs, `find` for `settings.local.json.*` / `*.bak*` / `*.tmp*` | **Survived** — byte-identical every time, 0 siblings |
| AC-7 | a *minified* or prose-bearing committed settings misclassifies and double-wires | 4 exotic-but-legal layouts + a real hooks block | **Survived** — declared-hooks ⇒ no local file; minified/prose/escaped-`\"hooks\"`/whitespace-heavy empty ⇒ bootstrap |
| AC-8 | the bootstrapped file trips F.2 or J.1 | `verify_all` after the AC-5 bootstrap | **Survived** — 32/0/0, F.2 + J.1 PASS |
| AC-9 | the guard fails **open** when `CLAUDE_PROJECT_DIR` is empty/unset (`cd ""` may succeed) | `qa_failclosed.sh` — 6 missing/unreachable-guard variants, ×10 | **Survived** — exit 127/126/127/2/127/127. **Zero exit-0 paths.** Block/allow both directions green (§5) |
| AC-10 | — | **not executable** (no `pwsh`) | ⚠️ green-by-symmetry-only |
| AC-11 | one mirror half drifted from the other | `diff` on all 4 halves + `sync-self --check` | **Survived** — 4/4 identical, "In sync." |
| AC-12 | a frozen badge or count claim moved | grep both READMEs; `git diff --stat` over all 12 decoys | **Survived** — `verify__all-32%2F32` + `test--init-316%2F316` intact in both; every decoy byte-untouched |
| AC-13 | the disable path still documents only the committed file | read `75-safety-hook.md:88-111`, then **execute** the documented opt-out byte-form | **Survived** — the section states the re-arm hazard and the opt-out; `{ "hooks": {} }` verbatim ⇒ left byte-untouched, exit 0 |
| AC-14 | the installer touches `.gitignore`, or the file shows as tracked | `git status --porcelain`, `git diff -- .gitignore`, `git check-ignore -v`, `git ls-files` | **Survived** — no `.gitignore` line, empty diff, `!! .claude/settings.local.json`, untracked |

## 4. AC-5 / AC-6 / AC-14 — live dogfood on this repo (captured)

*(Compacted; §12.5 and §13.6 re-ran this identically.)* `rm .claude/settings.local.json` →
install → **exit 0**, all three FR-12 elements; `cmp` vs pre-delete **BYTE-IDENTICAL** (NFR-1
corroborated); 2nd + 3rd runs "left byte-untouched, no backup written", exit 0, byte-identical;
**0** `settings.local.json.*` / `*.bak*` / `*.tmp*` siblings; **no `.gitignore` line** in
`git status --porcelain`, empty `git diff`, `git check-ignore -v` → `.gitignore:60`, status `!!`.

## 5. FC-1…FC-4 — the fail-closed invariant, re-verified by me

**FC-1** `grep -n 'guard-rm'` over all **4** installers → **zero hits** (exit 1) · **FC-2**
`grep -nE '^[^#]*(\$\{[A-Za-z_]+//|sed |-replace|\.Replace\()'` over both installers + both specs
→ **zero hits** · **FC-3** substring scan of the live `command guard-rm windows|unix` output →
`|| exit 0`, `exit 0`, `-EA SilentlyContinue` all absent, `-NoProfile` ×2 (win) · **FC-4**
`grep -n 'HARNESS_ALLOW_OUTSIDE_RM'` ×4 → zero hits, but the 7-row matrix shows **3 of 7 rows
exit 0 with a partial wiring** → r-1/r-6.

**AC-9, both directions, driven through the command parsed out of the generated file** (behind an
anti-vacuity gate — the script refuses to report unless the parsed value names `guard-rm.sh`):
`BLOCKED rc=2` for `rm -rf /tmp/qa-outside-probe`, `rm -rf ~/Documents`, `rm -f /etc/hosts`
("destructive command targets path outside project root"); `ALLOWED rc=0` for `rm -rf
node_modules`, `rm -f docs/features/_scratch/x.txt`, `git status`.

**Missing/unreachable guard (NFR-2), 6 variants × 10 reps:** absent **127** · chmod 000 **126** ·
no `.harness/` **127** · `CLAUDE_PROJECT_DIR` nonexistent **2** · empty **127** · unset **127**.
Exit-0 count: **0** across all 60. The `cd ""` hypothesis does not break it. *(Re-measured §12.6.)*

## 6. Boundary tests executed (`qa_boundary.sh` — 44 assertions, written from §4)

`B-1` unknown tool/os/query, 4 arity violations, empty query → exit **2**, empty stdout, named
diagnostic (9/9) · `B-2` empty command answer / spec absent → exit 4, nothing written · `B-3`
`.claude/` absent → created · `B-4` committed settings absent → bootstrap · `B-5` 4 unparseable
shapes → exit **3**, no local file **and no pre-commit hook** · `B-6`/`B-7`/§8-row-3 local file
unparseable / empty-`hooks` / **a directory at that path** → exit 0, byte-untouched, no sibling
(6/6) · `B-8` unwritable `.claude/` → exit **5**, target absent · `B-10` two concurrent runs →
one file, identical bytes · `B-11` `hostos` under `msys`/`cygwin`/`darwin23`/native → exactly
`windows`/`unix` · `B-14` no `.git/` → exit 1 · `B-15` no `.gitignore` → none created, advisory
printed; pre-existing one lacking the entry → byte-untouched · §3.2 step 0b directory at the
**committed** path → exit 3 · `R-4` 4 exotic layouts classify correctly.
**`=== qa_boundary: PASS=44 FAIL=0 ===`** — 5 consecutive runs, identical.

## 7. Regression — every other driver vs `baseline.json`

`verify_all` **32 checks, 32/0/0** · `test-init` (no-py3) **354/0** · `test-real-project` **90/0** ·
`test-harness-upgrade` **89/0** (incl. Z1/Z1b/Z2/Z3) · `test-verify-i6` **58/0** · `test-language`
**39/0** · `test-supervisor` (no-py3) **45/0** · both `--check`s `In sync.`. **Δ = 0 everywhere.**
Mirror halves `diff`-clean 4/4; F.1 array carries `hook-spec` (`verify_all.sh:284`); both READMEs
still `verify__all-32%2F32` + `test--init-316%2F316`; 12 DO-NOT-TOUCH decoys `git diff`-empty; zero
historical `## [x.y.z]` headings removed. **Baseline updated: NO** — every pinned key already
equalled a captured run; no test deleted, narrowed or skipped; `verify_all` not modified.

## 8. Cross-shell / operator-pending (green-by-symmetry-only)

PowerShell is not executable in this runtime (`which pwsh` → not found). I claim **no** PS
verification. Everything below stays exactly as `04_DEVELOPMENT.md` booked it; **no eighth
operator item surfaced from my testing**:

1. `[Parser]::ParseFile` on `hook-spec.ps1` (×2), `install-hooks.ps1` (×2), `test-init.ps1`, `sync-self.ps1`, `verify_all.ps1`.
2. `install-hooks.ps1` in a clone with the local settings deleted — exit 0, Windows byte-forms, FR-12 report, idempotence.
3. `test-init.ps1` green, then reconcile `test_init_ps_assertions` (**316**, unreconciled) and only then move both README `test--init-316%2F316` badges together.
4. `verify_all.ps1` — it hard-parses the generated file with `ConvertFrom-Json` where bash only greps (R-5 / A-8).
5. **AC-10** cross-shell byte-identity of `settings.local.json` + the generated pre-commit hook — unproven until (2) runs and `cmp` compares on one host.
6. (r-3) the `& pwsh … 2>&1` native captures under `$ErrorActionPreference = "Stop"` — confirm the driver reaches its `=== Result ===` line. *(Site list re-enumerated to seven in §13.7.)*
7. (r-4) `test-init.ps1:1140` `Get-ChildItem -Filter` Win32 wildcard semantics — confirm the AC-6 sibling row is green on Windows.

**Conditional 8th** (the r-1 patch's PS twin) **landed** — see §12.11. The list is **eight**;
§13.7 re-verifies the count and item 6's site list against the live file.

## 9. Defects found in round 1 *(all four dispositioned in §12)*

- **[MINOR] r-1 — FC-4 counts ids, not events.** `install-hooks.sh:202` / `.ps1:241`, all four
  halves. 4 duplicate ids ⇒ exit **0**, one event wired. *Repro*: `hook-spec.sh:120` emits
  `guard-rm ×4` → exit 0, `jq '.hooks|keys'` = `["PreToolUse"]`. → **CLOSED, §12.3.**
- **[MINOR] r-6 — a step-7 refusal leaves a guardless file the next run blesses** *(new, mine)*.
  4 ids excluding `guard-rm`: run 1 exits **5** but leaves the file present; §8 row 3 keys on
  presence, so **run 2 exits 0**. Fix must refuse *before* writing. → **CLOSED at the root, §12.3.**
- **[MINOR] r-2 — the FC-4 assertion is conditionally vacuous.** `test-init.sh:986-988` /
  `.ps1:1207-1210` accept any exit 4; a silently broken stub keeps the row green. → **CLOSED, §12.4.**
- **[NIT] n-6** — `install-hooks.{sh,ps1}:31-32` header claims exit 5 always leaves the target
  ABSENT; the confirmation path leaves it present. → **CLOSED, §12.10.**
- **[MINOR] r-5 (carried)** — `docs/tasks.md:9` still reads Stage 1. **Owner: PM.** → **open.**

All four dev-owned items **Owner: developer**. **Patch handed, not applied** (production code
with an unexecutable PS twin — hard rule 1): two lines after `install-hooks.sh:202`, PS twin via
`@($wired | … | Sort-Object -Unique).Count`. §12.9 records the process defect in that hand-off.

## 10. Stability (round 1)

`verify_all.sh` ×3 → 32/0/0 · `test-init.sh` (no-python3) ×3 → 354/0 · `qa_ac3.sh` ×10 → 18/0 ·
`qa_ac4.sh` ×10 → 9/0 · `qa_boundary.sh` ×5 → 44/0 · `qa_failclosed.sh` ×10 → 6/6 blocked, **0
hard rejects**. **No flakes observed.** ✅

## 11. Verdict — round 1 *(superseded by §12.13, then by §13.9)*

### **PASS WITH DEFECTS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 3 MINOR / 1 NIT (+1 MINOR PM)

Gate 32/0/0 (32 checks) ×3, green **from the bootstrapped state** (AC-8). AC-1…AC-9 and
AC-11…AC-14 verified by execution, one independent reproducer + stated hypothesis each; AC-3's
independence proven both ways. AC-10 and the whole PS surface green-by-symmetry-only, 7 operator
items + a conditional 8th. NFR-2 holds (6×10, never 0). Baseline unchanged. Ownership:
r-1/r-6/r-2/n-6 → developer, r-5 → PM; **solution-architect: nothing** (r-6 is a consequence the
design named at §8 row 3 / R-3 and the fix belongs in the installer); **requirement-analyst:
nothing.** No `BLOCKED: NEEDS-HUMAN` item arises.

# 12. Round 2 — post-patch verification

**Date**: 2026-07-31 · **Upstream**: `04_DEVELOPMENT.md` §"Rework round 2 — QA".

> **Inheritance policy, again.** Every number in §12 is from a run I made in *this* session; the
> developer's captures were read as hypotheses to refute. Reproducers are QA-owned at
> `…/scratchpad/qa2/` (`qa_matrix2.sh`, `qa_failclosed2.sh`, `qa_dogfood2.sh`, `probe2.py`,
> `probeB.py`, `mutate.py`) — written from the ACs and FC-4, not from his test code.

## 12.1 The patch landed in all four halves — CONFIRMED

Both bash halves (repo + `skills/…/templates/common/…`) carry the arity gate at `:205` and the
distinct-events gate at `:213-214`; both PS halves carry `:244` and `:255-259` — as claimed. All
four mirror pairs `diff`-clean (installers **and** `hook-spec.{sh,ps1}`); `sync-self --check` and
`harness-sync --check` both `In sync.` exit 0.

## 12.2 Adversarial tests — round 2 *(extends §3; §3 stands unmodified)*

One independent reproducer + one stated failure hypothesis per closed defect.

| # | Hypothesis ("I expect failure when…") | Reproducer (NEW, mine) | Outcome |
|---|---|---|---|
| r-1 | duplicate/mixed ids still reach exit 0 — the gate counts the wrong thing | `qa_matrix2.sh` rows 2-3 (artifact mutated at `hook-spec.sh:120`) | **Survived** — exit 4, ABSENT |
| r-6 | run 1 refuses but run 2 finds residue and exits 0 | `qa_matrix2.sh` **second run per row** | **Survived** — run 2 also exit 4, still ABSENT |
| r-2 | the hardened row is still green with a broken stub | `mutate.py` r2b + full `test-init.sh` | **Survived** — 389/1, that row the only red |
| r-2 | the anti-revert property was traded away for the diagnostic | `mutate.py` r2a (arity → `> 0`) + full suite | **Survived** — 389/1, same single red |
| n-6 | header still claims exit 5 ⇒ ABSENT on both sub-paths | read all 4 headers + the live `confirm_failed` body | **Survived** — split, and runtime text agrees |
| NFR-2 | a missing guard yields exit 0 somewhere (dev declined to re-measure) | `qa_failclosed2.sh`, 6 variants × 10 | **Survived** — 0 exit-0 paths |
| **new** | the gate counts *lines*, so a multi-line `event` answer slips through | `probeB.py` | **FAILED** — exit 0, partial wiring. Filed **n-7** |
| **new** | deleting the new gate turns no repo test red | `probe2.py` (gate removed from both halves) | **FAILED** — 390/0 and 32/0/0 still green. Filed **r-7** |

## 12.3 The 7-row degradation matrix, re-measured — **and the second run of every row**

Artifact mutated (`hook-spec.sh:120`'s fixed `printf`), never the assertion list. Verbatim:

```
1 four distinct        run1 exit=0 PRESENT events=[Stop,PreToolUse,UserPromptSubmit,SessionStart] | run2 exit=0 PRESENT "left byte-untouched"
2 four dupes w guard   run1 exit=4 ABSENT  "expected 4 DISTINCT hook events, got 1: PreToolUse PreToolUse PreToolUse PreToolUse" | run2 exit=4 ABSENT
3 four mixed dupes     run1 exit=4 ABSENT  "...got 3: Stop PreToolUse PreToolUse SessionStart"    | run2 exit=4 ABSENT
4 four ids no guard    run1 exit=4 ABSENT  "...got 3: Stop Stop UserPromptSubmit SessionStart"    | run2 exit=4 ABSENT
5/6/7 3 ids · 5 ids · one bogus id        run1+run2 exit=4 ABSENT ("expected 4 ids, got 3" / "got 5" / "unrecognized tool: bogus-tool")
```

**r-6 is closed at the root, exactly as the routing decision required.** Rows 2/3/4 refuse
*before* the write, so the guardless residue never comes into existence and §8 row 3 has nothing
to bless; the second run re-derives the same refusal from the spec rather than finding a file.
§8 row 3 is byte-untouched. Matrix re-run **3×**, identical. **Row 1 hash re-derived by me**:
`sha256 536f3e0125cb58592ee2ab00883845356409b9764595c0966f32be507d9b49a9` — byte-equal to the
live file and to round 1. Happy path unchanged.

## 12.4 r-2 — non-vacuous in both directions, full-suite (scratch copy, control = unmutated)

```
control  PASS: 390 FAIL: 0 | r-2b stub -> nonexistent path  PASS: 389 FAIL: 1
                           | r-2a arity reverted to `> 0`   PASS: 389 FAIL: 1
both reds: FAIL [T-13][install] spec listing fewer than 4 tool ids -> exit 4, NOTHING written
```

Round 1's r-2b was **390/0 green**; it is now red, and the anti-revert property (r-2a) survives
the patch. **r-2 closed.**

## 12.5 Live dogfood, end-to-end · 12.6 NFR-2 re-run *(the probe the developer declined)*

Dogfood: `rm .claude/settings.local.json` → install exit **0**, full FR-12 report → `cmp` vs the
pre-delete snapshot **BYTE-IDENTICAL** at `sha256 536f3e01…b49a9` → 2nd run "left byte-untouched,
no backup written" → **0** siblings → `git check-ignore -v` `.gitignore:60`, status `!!`, no
`.gitignore` diff. *(Re-run identically in §13.6.)*

NFR-2, wired command parsed out of the generated file behind an anti-vacuity gate (refuses to
report unless the parsed value names `guard-rm.sh`), 6 variants × 10 reps: `absent=127
chmod000=126 no-tree=127 badcpd=2 empty=2 unset=2`, identical all 10; **exit-0 count 0**.
**No path where a missing guard yields exit 0.** Round 1's 127 for empty/unset vs 2 here is my
harness (`sh` = dash, whose `cd ""` errors), not a behavior change; both are refusals. The
developer's reason for declining was sound (`guard-rm`/`hook-spec` untouched) but **"unchanged
file" is an argument, not evidence**, so I re-measured. Corroboration: the live session guard
**blocked two of my own tool calls** unprompted — fail-closed on an unparseable input.

## 12.7 Gate and regressions — every number from a run I made this session

`verify_all.sh` **32/0/0, 32 check lines** ×3 (key 32) · `test-init.sh` python3 **390/0**,
no-python3 **354/0, 3 SKIP** (key 354) · `test-real-project` **90/0** · `test-harness-upgrade`
**89/0** · `test-verify-i6` **58/0** · `test-language` **39/0** · `test-supervisor` **45/0**
(keys 90 · 89 · 58 · 39 · 45) · both `--check`s `In sync.` exit 0. **Δ = 0 on every key.**

**No numeric key in `baseline.json` moved — confirmed, not inherited.** Its `git diff` is exactly
two hunks: `test_init_bash_no_python3_assertions 278 → 354` (the round-0 T-13 change) and the
`_qa_note_t13` **string**. All 17 numeric keys re-listed, each equal to a capture above. Both
README badge sets still `verify__all-32%2F32` + `test--init-316%2F316`; all 12 DO-NOT-TOUCH
decoys `git diff --stat` empty; no file added, moved or removed. **Baseline updated: NO.**

## 12.8 The three defects the developer fixed rather than copying — assessed

- **FC-1 regression he introduced and caught.** Re-verified: `grep -n 'guard-rm'` over all four
  installers → **zero hits, exit 1**. FC-2/FC-3/FC-4 also re-checked clean.
- **`wc -l` padding, declined.** Verified: `n="   4"; (( n == 4 ))` is **true** in bash — the
  decline is cosmetic-only and correct.
- **The `-join`/`+` defect in the form I handed — see §12.9.**

## 12.9 QA-process finding — my round-1 patch was an incomplete cross-shell hand-off

§9 handed the developer a *complete* bash form (count + diagnostic) but for PowerShell **only
the count expression** and no diagnostic; he composed the PS message himself and hit an
operator-precedence trap doing it. That gap is mine. **Rule for next time: a patch handed for an
unexecutable shell must be handed complete and explicitly marked unverified, or not handed at
all.** On the precedence claim I make **no verification claim** (`pwsh` absent); the language
spec classes binary `-join` with the comparison operators while `about_Operator_Precedence`
tabulates it tighter — they disagree, which is why the trap exists. Decisively, the shipped `-f`
form at `.ps1:258` with the parenthesised `$eventList` at `:257` is correct under either reading.

## 12.10 New defects introduced or surfaced by this rework

- **[MINOR] r-7 — the fix for r-1/r-6 has no anti-revert coverage.** I deleted both new gate
  lines from **both** bash halves: `test-init.sh` **390/0** and `verify_all` **32/0/0**, fully
  green — nothing in the repo suite would notice the gate being reverted, which is precisely the
  property r-2 established for the arity gate. The developer declined an in-suite row because
  "the assertion count had to stay unmoved"; **no such rule exists** — OQ-9a/§3.6 forbids a new
  *driver pair*, not a new assertion, and rework 1 already moved this key 353 → 354 from a
  capture for exactly this reason. *Repro*: `probe2.py`. *Fix*: one row per twin + a re-captured
  key. **Owner: developer.** → **CLOSED in round 3, §13.3/§13.4.** *(PM subsequently withdrew
  the count constraint, confirming it was never a rule.)*
- **[NIT] n-7 — the gate counts LINES, not answers.** `install-hooks.sh:213` is bypassable by an
  `event` answer containing an embedded newline. *Repro* (`probeB.py`, artifact mutated): events
  `Stop`/`PreToolUse`/`PreToolUse`/`SessionStart\nUserPromptSubmit` → 5 lines, 4 unique → **exit
  0, file PRESENT**, `PreToolUse` wired twice, output not valid JSON. Strictly narrower than r-1
  (needs `hs_event` rewritten to violate its own single-token contract); the PS twin's
  `Sort-Object -Unique` over an object array is not exposed the same way. **Owner: developer.**
  → **assessed and accepted as record-only in §13.5.**
- **[NIT] n-8 — `baseline.json:_qa_note_t13` carries stale line numbers.** Operator check (a)
  cites `test-init.ps1:…,`**`1207,1216`**; the actual native captures were at **`1215,1225`**.
  `04_DEVELOPMENT.md` item 6 was correct, so the two records disagreed. **Owner: developer.**
  → **CLOSED in round 3, §13.7** (list re-enumerated to seven sites and verified).
- **[MINOR] r-5 (carried, PM).** `docs/tasks.md:9` has a T-13 Active row still reading
  **"1 — requirement analysis"** at stage 6. **Owner: PM.**

No other defect was introduced. The n-6 fix is correct in all four headers *and* matches the
runtime text, and the same falsehood was corrected in `CHANGELOG.md:29-33`.

## 12.11 Cross-shell / operator-pending (round 2)

**PowerShell is not executable here.** I claim **no** PS verification: the `.ps1` gate at
`:244-259`, the PS FC-4 row at `test-init.ps1:1190-1222`, `Sort-Object -Unique`'s
case-insensitivity and the `-f` diagnostic are **green-by-symmetry-only**. The **eighth** NFR-5
operator item is present in `04_DEVELOPMENT.md` and `baseline.json:_qa_note_t13` and accurate in
substance. Items 1-7 unchanged and still binding. **No ninth item arises from my testing.**

## 12.12 Round-2 stability

`verify_all.sh` ×3 → 32/0/0 every time · `test-init.sh` ×2/×2 → 354/0 · 390/0 every time ·
`qa_matrix2.sh` (7 rows × 2 runs) ×3 → identical exits and presence · `qa_failclosed2.sh` ×10 →
identical exits, 0 hard rejects. **No flakes observed.** ✅

## 12.13 Round-2 verdict *(superseded by §13.9)*

### **PASS WITH DEFECTS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 1 MINOR / 2 NIT (+1 MINOR PM)

**r-1 CLOSED** (matrix rows 2/3 exit 4, ABSENT) · **r-6 CLOSED at the root** (row 4 refuses
*before* the write; run 2 also exits 4, so no guardless residue exists for §8 row 3 to bless —
the specific reason PM routed) · **r-2 CLOSED** (389/1 both directions, the FC-4 row the only
red in each) · **n-6 CLOSED** (all four headers split the exit-5 sub-paths; the CHANGELOG claim
corrected). Happy path `536f3e01…b49a9` re-derived. NFR-2 holds 6×10, never 0. Gate 32/0/0 ·
390/0 · 354/0 · 90/0 · 89/0 · 58/0 · 39/0 · 45/0; no numeric baseline key moved; badges frozen.
**New**: r-7, n-7, n-8 → developer; r-5 → PM; code-reviewer / solution-architect /
requirement-analyst: nothing; qa-tester: one process finding (§12.9).

# 13. Round 3 — final confirmation

**Date**: 2026-07-31 · **Upstream**: `04_DEVELOPMENT.md` §"Rework round 3 — QA (r-7)". Scope:
close **r-7**. Every number below is from a run I made in *this* session; the developer's round-3
captures were read as hypotheses. Mutations ran in a **scratch clone** (`…/scratchpad/qa3/ctl`),
so the live tree was never mutated. PM withdrew the "assertion count must stay unmoved"
constraint, so the fix is now an in-suite row plus a re-captured key.

## 13.1 The new row exists in both twins — CONFIRMED

`test-init.sh:996-1018` and `test-init.ps1:1223-1252`: a stub answering `tools` with `guard-rm`
×4 (4 ids → 1 distinct event), delegating every other query, asserting **exit 4 + target ABSENT
+ `grep -qF 'expected 4 DISTINCT hook events, got 1'`** — as claimed, and structurally symmetric
to the round-2 arity row (7). `sync-self --check` / `harness-sync --check` both `In sync.`

## 13.2 Baseline 354 → 355 — equals a capture I made; decomposition re-derived

```
test-init.sh (python3 shim exit 9)  PASS: 355  FAIL: 0  exit 0  3 SKIP
decomposition from MY run: pre-existing 278 + [T-13] spec 45 + [T-13][install] 32 = 355
test-init.sh (python3 present)      PASS: 391  FAIL: 0        391 - 355 = 36 = 3 x 12
```

`test_init_bash_no_python3_assertions` = **355** ✅ · `test_init_ps_assertions` = **316**, still
**UNRECONCILED** ✅ · `verify_all_checks` = **32** ✅. Baseline `git diff` is exactly two hunks
(the 278→355 key, the `_qa_note_t13` string); no other numeric key moved; the key rose, never
fell. **Baseline updated by me: NO** — the developer's value already equals my capture.

## 13.3 Mutation matrix — re-run by me (A, B, C, D), scratch clone, no-python3

```
control                                        PASS: 355  FAIL: 0
(A) both gate lines deleted, both bash halves  PASS: 354  FAIL: 1
    FAIL [T-13][install] spec answering 4 ids that collapse to 1 event (FC-4)  <- ONLY red
(B) only `(( n_distinct == 4 ))` deleted       PASS: 354  FAIL: 1   same single row red
(C) only `n_distinct=$(printf ...)` deleted    PASS: 338  FAIL: 17  (unset var poisons step 6)
(D) arity reverted to `(( n_wired > 0 ))`      PASS: 354  FAIL: 1
    FAIL [T-13][install] spec listing fewer than 4 tool ids (FC-4)             <- ONLY red
```

**All four match the developer's matrix exactly.** D's red is the **r-2 arity row** with the new
row **still green**; A/B's red is the new row with the arity row still green — the two rows
**cleanly partition the two gates**, as claimed. C is not a partition case (an unset
`$n_distinct` reddens every downstream bootstrap row) — loud, but it proves nothing about
partitioning. Files restored from the pre-mutation copies and **re-hashed**: all six `sha256sum
-c` **OK** (bash installers `b543f2da…f015a2`, PS twins `b22793c1…12dfd`).

## 13.4 Adversarial tests — round 3 *(extends §3 and §12.2; both stand unmodified)*

| # | Hypothesis ("I expect failure when…") | Reproducer (NEW, mine) | Outcome |
|---|---|---|---|
| **r-7** | deleting the gate still leaves the suite fully green | mutation (A), full suite, scratch clone | **Survived — 354/1, new row the only red. r-7 CLOSED** |
| **r-7b** | the new row is *vacuously* green — any exit 4 satisfies it | mutation (D): gate present, **arity** reverted | **Survived** — new row green, a *different* row red ⇒ pinned to its own branch |
| **r-7c** | the two rows are redundant (one mutation reddens both) | A vs D red-row sets | **Survived** — disjoint singletons |
| **new** | the baseline number is asserted, not captured | independent decomposition of my run | **Survived** — 278+45+32=355, 391−355=36 |
| **n-7** | the line-count bypass is reachable from a *non-mutated* spec | `hook-spec.sh:74-81` + input-source scan | **Survived — unreachable**; §13.5 |
| **new** | the stray `docs/proposals/` file perturbs the gate | park it, re-run `verify_all` | **Survived** — 32/0/0 present *and* parked |

## 13.5 n-7 recorded rather than patched — the decline is honest and adequate

I probed the decline rather than accepting it. `hs_event` (`hook-spec.sh:74-81`) is a `case` over
four **compile-time string literals**; a scan for external input (`read`, `cat`, `$(<`, `source`,
env interpolation) finds **only** `${OSTYPE:-}` in `hs_hostos`, which never reaches an `event`
answer. The embedded-newline bypass is therefore reachable **only by editing `hook-spec.sh`
itself** — and whoever can do that can equally delete the gate from `install-hooks.sh`, so an
installer-side validation buys nothing against that threat model. Against that, the fix must land
in **four halves including two unexecutable `.ps1` files**: shipping unverifiable code to close an
unreachable hole. **The decline is correct and correctly reasoned**, and it is recorded as known
bound (ii) in `baseline.json:_qa_note_t13`, so it travels to the operator. **Record-only; not a
residual risk that must be escalated.** Caveat: bounds (i) and (ii) both weaken if a future task
makes an `event` answer dynamic or adds a fifth tool.

## 13.6 Gate, regressions, FC invariants, dogfood — all re-captured

`verify_all` **32/0/0, 32 check lines, ×3** · `test-init` **391/0** (python3), **355/0, 3 SKIP**
(no-python3) · `test-real-project` **90/0** · `test-harness-upgrade` **89/0** · `test-verify-i6`
**58/0** · `test-language` **39/0** · `test-supervisor` **45/0** · both `--check`s `In sync.`
exit 0. **Δ = 0 against every pinned key.** **FC-1** `grep -n 'guard-rm'` over all four
installers → **zero hits, exit 1** (the comment regression he made once before has **not**
returned) · **FC-2** zero post-processing hits over both installers + both specs · **FC-3** live
`command guard-rm unix|windows`: `|| exit 0`, `exit 0`, `-EA SilentlyContinue` all **absent** on
both, `-NoProfile` ×2 on Windows · **FC-4** zero `HARNESS_ALLOW_OUTSIDE_RM` hits ×4.

**Dogfood** (live repo): pre-delete `sha256 536f3e0125cb58592ee2ab00883845356409b9764595c0966f32be507d9b49a9`
→ delete → install exit 0 → **same sha**, `cmp` **BYTE-IDENTICAL** → 2nd run "left byte-untouched,
no backup written", still identical → **0** siblings. **Badges**: both READMEs still
`verify__all-32%2F32` + `test--init-316%2F316`; the only README hunk is the **version** badge
`0.44.0 → 0.45.0` — the release bump, not a frozen test claim. **`docs/tasks.md`**: one insertion,
PM's pre-existing T-13 row, still reading `1 — requirement analysis` — untouched by this round's
change set, still the open **r-5**. I did not edit it.

**Incidental — `docs/proposals/frontier-gaps-2026-07.md` (untracked, 12 492 B).** Not part of
T-13's change set: no code, no test, no baseline edit; its header says it was "Recorded
2026-07-31 at the operator's request" and it discusses T-13 **in the third person** ("T-13 was
interrupted this session") — consistent with the developer's statement that he neither created nor
touched it. `verify_all` references nothing under `docs/proposals/`, and I confirmed independence
by measurement: **32/0/0 with it present, 32/0/0 with it parked. Gate-neutral, out of scope**; it
should **not** ride along in T-13's commit.

## 13.7 Operator-item accounting — the "no ninth item" claim is accurate

Verified against the live file, not the doc. Item **6**'s site list is exactly the seven
`& pwsh … 2>&1` native captures at `test-init.ps1:1073, 1120, 1161, 1180, 1215, 1246, 1256` — my
`grep -n` returns those seven and only those, so round-2's **n-8 (stale line numbers) is CLOSED**
and `04_DEVELOPMENT.md` and `_qa_note_t13` now agree. Item **3** gains the new row, item **8**
gains its PS-side coverage; the list stays at **eight** and **no ninth item arises from my
testing.** One wording nit: items 3/8 call `Test-InstallBootstrap` "**32 `Assert`s** per twin",
but the *source* has **29** `assert`/`Assert` calls in each shell — one sits inside a four-tool
`for`/`foreach`, yielding **32 runtime rows** (32 `[T-13][install]` PASS lines in my run). **32 is
the number the operator needs**, so the guidance is right; only the word is loose. Filed **n-9
(NIT, record-only, developer).**

## 13.8 Round-3 stability

`verify_all.sh` ×3 → **32/0/0** every time · `test-init.sh` no-python3 ×3 → **355/0** every time ·
python3 ×1 → 391/0 · mutation rows deterministic. **No flakes observed.** ✅

## 13.9 Round-3 verdict

### **PASS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR / 2 NIT record-only (+1 MINOR PM)

**Nothing blocks delivery. Nothing needs another developer round.**

- **r-7 is CLOSED — the finding of the round, discharged by measurement.** Deleting the gate now
  makes the suite go red: mutation (A) → **354/1**, the new row the **only** red. The row is
  non-vacuous (D keeps it green while reddening a *different* row) and non-redundant (A and D
  redden **disjoint** singletons). Baseline moved **354 → 355 from a capture I reproduced**.
- **n-7 — record-only, decline accepted.** Unreachable without editing `hook-spec.sh`, whose
  `hs_event` is four compile-time literals; the fix would ship unverifiable PS code to close an
  unreachable hole. Recorded as bound (ii) in `_qa_note_t13`. **No escalation.**
- **n-8 — CLOSED** (seven-site list re-enumerated and verified against the live file).
- **n-9 — NEW NIT, record-only, developer.** "32 `Assert`s per twin" is 29 source calls / 32
  runtime rows; the operator-facing number (32) is right, only the wording is loose.
- **r-5 — still open, PM.** `docs/tasks.md:9` reads `1 — requirement analysis` at stage 6.
- **No regression.** 32/0/0 (32 checks) ×3 · 391/0 · 355/0 · 90/0 · 89/0 · 58/0 · 39/0 · 45/0 ·
  both `--check`s `In sync.`; FC-1…FC-4 clean; dogfood byte-identical at `536f3e01…b49a9`;
  frozen badges unmoved; `docs/tasks.md` not edited by me. The stray `docs/proposals/` file is
  gate-neutral and out of scope (§13.6).
- **Constraints honored**: `verify_all` and its checks unmodified; no test deleted, narrowed or
  skipped; baseline only rose. **Baseline updated by me: NO** — it already equals my capture.
- **PowerShell unexecutable; I claim no PS verification.** The new `test-init.ps1:1223-1252` row,
  the `.ps1` gate and `Sort-Object -Unique`'s case-insensitivity are **green-by-symmetry-only**,
  carried by the **eight** binding NFR-5 operator items.
- **Ownership**: n-7 + n-9 → **developer** (both record-only); r-5 → **PM**; **code-reviewer,
  solution-architect, requirement-analyst: nothing.** Everything remaining is **record-only** —
  PM can carry n-7, n-9 and the eight operator items straight into `07_DELIVERY.md`.
- No `BLOCKED: NEEDS-HUMAN` item arises. The only human-reserved work is the NFR-5 operator run.
