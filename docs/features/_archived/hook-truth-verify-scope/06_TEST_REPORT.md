# 06 — Test Report — T-15 `hook-truth-verify-scope` (mode `full`)

- Stage 6, QA. Date 2026-08-01. deferred-human mode: **defer, do not ask** — no operator question raised.
- Upstream: `01` READY · `02` round 3 READY · `03` round 2 APPROVED FOR DEVELOPMENT · `04` READY FOR REVIEW · `05` APPROVED (0 CRITICAL, 0 MAJOR).
- **Body 184 lines / Appendix 463 lines (647 total, measured with `wc -l`, not estimated).** The body is inside `.harness/rules/70-doc-size.md:30`'s 500-line cap; the appendix is mandated verbatim evidence under `02` §11.0 rule 5 and is exempt from Rule 1 per the allowance in `02` §11.3, whose appendix pattern this document follows.
- **Documents 01–05 were not edited.** Two doc-only findings route back to the architect via the PM (§ Defects); neither blocks delivery.

## 0. Method — what makes this an independent verification

Everything below was **executed by me**, not read out of `04_DEVELOPMENT.md`. Three deliberate departures from the developer's procedure, each chosen to be strictly stronger:

1. **The clean-state tree carries a refreshed index.** `02` §11 S1 built a worktree at `HEAD` and overlaid the working tree on top, leaving a **stale index** — so `A.1`, `A.2`, `E.7` and `I.6` (via `git ls-files`, `verify_all.sh:633`) enumerated *HEAD's* file list, not the overlaid one. That honest limitation is recorded at `02:689-704`. I removed it: after the overlay I ran `git add -A` **inside the linked worktree**, so its index matches the overlaid content and every git-driven check enumerated the real file set. The main repository's index was never touched (verified: porcelain stayed at its 47 rows plus the scratch dir).
2. **All artifact mutations ran inside the scratch worktree, never on the live tree.** This is what let me probe **A1 and A2** — `.harness/scripts/guard-rm.ps1` and `guard-rm.sh`, the forbidden mutation targets of `02` §11.1 — which nobody had falsified, because in the scratch tree they are ordinary copies and the live fail-closed `PreToolUse` hook is wired to the **live** path. The live guard scripts' mtime is unchanged at `2026-07-31 23:55:04` across the entire session.
3. **The pre/post differential ran both gates over the same bytes.** I extracted `git show HEAD:.harness/scripts/verify_all.sh` into the scratch tree and ran the **real pre-change gate**, not a reconstruction of its predicate. Same tree, same run, only the `F.2` code differs.

Hard rules honoured: `.claude/settings.local.json` never renamed, moved, edited, emptied or deleted (mtime unchanged at `2026-07-31 17:09:15`); `.harness/scripts/guard-rm.{sh,ps1}` never touched; `HARNESS_ALLOW_OUTSIDE_RM` never set; `sync-self` never run in write mode; the scratch tree lived at `./.t15qa-clean` **inside** the project root and was removed with `git worktree remove --force` (no destructive verb from the guard's nine-verb set). No expectation was ever edited to match a run.

---

## 1. Test plan — acceptance criterion → test

| AC | Test performed by me | Evidence |
|---|---|---|
| AC-1 | live `bash .harness/scripts/verify_all.sh` | E-1 |
| AC-2 | shipped gate on a clean state with **no** machine-local settings file, refreshed index | E-3 |
| AC-3 | **pre-change** `HEAD` gate on that identical state | E-4 |
| AC-4 | `02` §3.4 three-part recipe (a) enumeration (b) masked count (c) inverse | E-11 |
| AC-5 | **seven** independent artifact mutations + three multi-problem mutations | E-6, E-7 |
| AC-6 | status word in every red run | E-6, E-7 (all `FAIL`, `WARN: 0` throughout) |
| AC-7 | `verify_all_checks` = 32; `G.3`/`G.4` PASS; `32 checks` literals intact | E-1, E-10, E-12 |
| AC-8 | `bash .harness/scripts/test-guard-rm.sh` ×3 | E-2, E-13 |
| AC-9 | PS audited by reading; `pwsh` confirmed absent | E-9 |
| AC-10 | health-report machine dimension — **not re-verified**, see §6 | — |
| AC-11 | live doc surfaces re-enumerated; frozen surfaces audited | E-10, E-12 |
| AC-12 | delivery prose audited for the "reduces guard coverage" error | E-12 |
| B-1…B-4 | four machine-settings states × both gate versions | E-5 |
| B-5…B-8 | mutations M-A1…M-A4, M-B0, M-B1, M-B2 | E-6 |
| B-9 | M-ALL (5 tokens), M-B1B2 (2 tokens), M-MIX (3 tokens across both families) | E-7 |
| B-12 | `PASS 32 / WARN 0 / FAIL 0` on five consecutive runs | E-1, E-13 |

## 2. Headline result — does a clean checkout actually pass?

**Yes, and the differential is decisive.** Same scratch tree, same bytes, run back-to-back:

| Gate | `[F.2]` | Detail | Summary | exit |
|---|---|---|---|---|
| **pre-change** (`git show HEAD:…/verify_all.sh`) | **FAIL** | `.claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command` | `PASS: 31 / WARN: 0 / FAIL: 1` | **2** |
| **shipped** | **PASS** | — | `PASS: 32 / WARN: 0 / FAIL: 0` | **0** |

Full 32-line listings: **E-3** and **E-4**. Note that in *my* construction **no non-`F.2` check is red in either run** — the "procedure artifact" discrepancy rule `02:715-723` had to be invoked zero times, because refreshing the index removed the cause.

**What remains unproven, stated plainly.** This is still not literally `git clone && verify_all`. No commit of the T-15 content exists to clone — `HEAD` is `cb0ed57` with 47 dirty rows, and `01` out-of-scope 8 forbids committing. What was demonstrated is the strongest form available before a commit: *the current tracked content, with the machine-local settings file absent, over an index that matches it*. The one input a real clone would differ on — `.claude/settings.local.json` absent — is exactly the variable under test, and `F.2` now reads no settings file at all, so no other clone-vs-worktree difference can reach it. **The requirement's core claim is established.**

## 3. Anti-vacuity — is every retained assertion load-bearing?

**All seven fail independently, each on its own token, each at `FAIL` severity, `WARN: 0` in every run** (E-6). Four of these were run by the developer; **three were not**: A1, A2 (forbidden live, safe in the scratch tree) and A3.

| Assertion | Mutation | `[F.2]` detail | Summary |
|---|---|---|---|
| A1 | `rm .harness/scripts/guard-rm.ps1` | `missing:.harness/scripts/guard-rm.ps1` | `30/0/2` (`E.1` co-fires) |
| A2 | `rm .harness/scripts/guard-rm.sh` | `missing:.harness/scripts/guard-rm.sh` | `30/0/2` |
| A3 | `rm templates/common/…/guard-rm.ps1` | `missing:skills/…/guard-rm.ps1` | `30/0/2` |
| A4 | `rm templates/common/…/guard-rm.sh` | `missing:skills/…/guard-rm.sh` | `30/0/2` |
| B0 | `rm …/settings.json.tmpl` | `missing:skills/…/settings.json.tmpl` — **one token, not three** | `31/0/1` |
| B1 | `{{GUARD_COMMAND}}` → `XGUARD_COMMANDX` | `…settings.json.tmpl:no_GUARD_COMMAND_placeholder` | `31/0/1` |
| B2 | delete the `"PreToolUse": […]` array | `…settings.json.tmpl:no_PreToolUse_block` | `31/0/1` |

`E.1` co-firing on A1–A4 is the mirrored-source behaviour derived at `02` §11.2 M1 — **confirmed for all four paths, not just A4**, which closes the design's own "no A1–A4 mutation can avoid this" claim by measurement rather than by argument. `sync-self.sh` was never run in write mode.

**Accumulation (B-9) — the probe nobody had run.** The check does **not** stop at the first problem, in three shapes (E-7):

- **M-ALL** — all four guard scripts *and* the template removed → **five** tokens in one message, and `B1`/`B2` correctly suppressed behind `B0`.
- **M-B1B2** — template present, both placeholder and hook key broken → **two** tokens.
- **M-MIX** — two guard scripts missing **and** the placeholder broken → **three** tokens spanning both assertion families.

The PowerShell accumulator is audit-only (§6).

## 4. Adversarial tests

One stated failure hypothesis per acceptance criterion, written **before** the run. Verdict rests on whether the implementation survived, not on whether the developer's tests pass.

| AC | Hypothesis — "I expect this to fail because…" | Reproducer (all NEW, written by me) | Outcome |
|---|---|---|---|
| AC-2 | the developer's stale index masks a git-driven check that a real clone would fail; refreshing it will expose a red row | worktree + overlay + `git add -A`, then the shipped gate (E-3) | **Survived** — `32/0/0`, exit 0, zero non-`F.2` reds. Stronger than `04`'s run. |
| AC-3 | the pre-change failure was described, not reproduced, and may not reproduce on the current content | real `HEAD` gate over the same bytes (E-4) | **Survived** — reproduced exactly: three-token `.claude/settings.json` detail, exit 2. |
| AC-5 / B-5 | A1 and A2 were *never* falsified by anyone; the loop may only detect template paths | `rm` each of A1, A2, A3 in the scratch tree (E-6) | **Survived** — each turns `F.2` red on its own token. Held because A1–A4 are one loop body. |
| AC-5 / B-8 | the anchor is proven only by an out-of-band grep; the *gate* may not discriminate the doc string | P3: empty `hooks`, keep `_guard_hook` at `:5`, move `{{GUARD_COMMAND}}` into a `Stop` hook so **B1 stays satisfied and B2 fails alone** (E-8) | **Survived** — `no_PreToolUse_block` **as the only token**. This is the isolated B2 proof `04` could not obtain (its M3 entangled B1). |
| AC-5 / R-1 | the old unanchored form would *also* have caught M3, making the anchor decorative | run the **real pre-change gate** on the M-B2-mutated template (E-6, M-B2) | **Survived, and this is the signature result.** Old gate detail: `… :no_GUARD_COMMAND_placeholder` — **no `no_PreToolUse` token at all**, i.e. it did not notice the hook block was gone, because `_guard_hook` at `:5` satisfied it. New gate: `…:no_PreToolUse_block`. Quoted-`"PreToolUse"` count in the mutated file: **0**; bare-word count: **1**. |
| AC-6 | one mutation renders `WARN` (bash detail-arg loss) | status word inspected in all 13 red runs | **Survived** — `FAIL` every time, `WARN: 0` every time. |
| AC-9 / S-1 | PS's case-insensitivity is a silent hole with no backstop | P1: `"PreToolUse":` → `"pretooluse":` through the real gate (E-8) | **Survived with a caveat** — bash `F.2` FAILs **and `J.1` co-fires**, confirming §3.3's "J.1 owns key spelling" rationale by measurement. |
| AC-9 / S-2 | the newline deviation likewise has a backstop | P2: key and colon on different lines (E-8) | **FOUND A GAP (doc-only)** — bash `F.2` FAILs but **`J.1` passes cleanly** (still valid JSON). S-2 has **no** backstop, unlike S-1. See MINOR-2. |
| AC-9 / FR-7 | S-1 and S-2 are not the only shell deviations | 13-case differential corpus, bash executed vs .NET semantics modelled (E-9) | **FOUND A GAP (doc-only)** — a **third** deviation class: Unicode whitespace (`U+00A0`, `U+0085`) matches .NET `\s`, not POSIX `[[:space:]]`. See MINOR-1. |
| AC-4 | the check still reaches a settings file by some path the reviewer's read missed | §3.4 recipe (a)+(b)+(c) re-run on the live files (E-11) | **Survived** — targets are only `$f` and `$tmpl`; masked needle count `0`/`0`; comment names both files; `f2_hooks_file`/`hooksFile` have **0 hits tree-wide**. |
| AC-7 | `G.4` is not actually load-bearing on the count claims | D2: flip `32 checks` → `33 checks` in `AI-GUIDE.md` (scratch tree, E-10) | **Survived** — `G.4` turns red, `31/0/1`, exit 2. |
| AC-11 | the L3 doc fix is gate-protected, so the delivery claim "review-protected" is wrong | D1: revert `.harness/rules/40-locations.md:42` to its retired wording (scratch tree, E-10) | **Confirmed unprotected** — `32/0/0`, **no check catches it**. The honest claim to publish is "review-protected, not gate-protected", exactly as `02` §11 QA (i) predicted. |
| AC-8 | the 87 is a stale pin that the driver no longer produces | `test-guard-rm.sh` ×3 (E-2, E-13) | **Survived** — `PASS: 87 / FAIL: 0`, and the **summary line is present** in every run. |
| §3.5 residual | the reviewer's containment residual is theoretical and unreachable through the gate | P4 and P6 (E-8) | **CONFIRMED REAL — the implementation does *not* survive this, by design.** See §5. |

**Anchor-defeat attempts that the implementation withstood.** Beyond the table: an escaped key form inside a JSON *string value* (`"_note": "add \"PreToolUse\": []"`) does **not** match — because JSON must escape interior quotes, the byte sequence becomes `\"PreToolUse\"`, which the anchored pattern cannot satisfy. So within valid JSON the anchor is not defeatable by string content; only by a **real key in the wrong place** (P4/P6).

## 5. The declined-scope residual, confirmed empirically

`05` finding SPEC/COVERAGE and `02` §3.5 state that B1 and B2 assert **presence**, never **containment**. **I did not take this on the reviewer's say-so — I reproduced it through the real gate, twice** (E-8):

- **P4** — `"PreToolUse": []` left **empty**, `{{GUARD_COMMAND}}` moved into the `Stop` hook → **`F.2` PASS, exit 0**, under a label reading "settings-template guard **wiring** present". Nothing in the distributed template would wire the guard.
- **P6** — `"hooks": {}` entirely, with the only `"PreToolUse":` key parked under an unrelated `_example_only` object → **`F.2` PASS, exit 0**. This is notable because `"hooks": {}` is *precisely* the committed-settings state that created the original T-15 defect.

`J.1` catches neither. **This is declined scope (OQ-6(b) → T-16) and I did not fix it.** The delivery must state the residual from this measurement rather than from the reviewer's inference, and the T-16 row should carry it as a sub-item — with a regression row, since nothing currently pins it.

## 6. Regressions — every tally pasted from the run that produced it

**No tally below is re-derived arithmetically. A missing summary line was treated as a failure signal; every driver printed one.** (E-13.)

| Driver | Result (pasted) | Summary line present? | Baseline key | Verdict |
|---|---|---|---|---|
| `verify_all.sh` (live) | `PASS: 32  WARN: 0  FAIL: 0`, exit 0 | yes ×5 runs | `verify_all_checks: 32` | **match** |
| `test-guard-rm.sh` | `PASS: 87  FAIL: 0`, exit 0 | yes ×3 runs | `test_guard_rm_bash_assertions: 87` | **match, pin held** |
| `test-verify-i6.sh` | `PASS: 58  FAIL: 0`, exit 0 | yes | `…_bash_assertions: 58` | match |
| `test-init.sh` | `PASS: 391  FAIL: 0`, exit 0 | yes | `…_bash_no_python3: 355` | consistent — `python3` **is** present here; `baseline.json:_qa_note_t13` records 391 as the python3-present figure |
| `test-real-project.sh` | `PASS: 90  FAIL: 0`, exit 0 | yes | `…_bash_assertions: 90` | match |
| `test-harness-upgrade.sh` | `PASS: 89  FAIL: 0`, exit 0 | yes | `…_bash_assertions: 89` | match |
| `test-language.sh` | `PASS: 39  FAIL: 0`, exit 0 | yes | `…_bash_assertions: 39` | match |
| `test-supervisor.sh` | `PASS: 46  FAIL: 0`, exit 0 | yes | `…_bash_no_python3: 45` | **+1, pre-existing** — the driver is byte-unmodified vs `HEAD` (`git diff --name-only` empty) and contains 8 `python3` references; the key names the *no-python3* variant. Not a T-15 effect. |
| `sync-self.sh --check` | `In sync.`, exit 0 | n/a | — | match |

`test-init.sh` matters here beyond routine regression: it renders the settings template and asserts `PreToolUse` against the rendered fixture, i.e. it is the driver most exposed to the template mutations. Green.

**Frozen-list verification (independent of the developer's set-difference, which `05` ruling 2 correctly called unsound).** Method: mtime ordering against T-15's first write (`verify_all.sh` at `02:29:37`) plus direct content reads (E-12).

- `.harness/rules/75-safety-hook.md` — **exactly 200 lines**, mtime `2026-08-01 01:14:04` (**before** the T-15 window), and the deliberately-unrepaired stale claim at `:150-151` is verbatim intact. Not "improved while in there".
- Every file with an mtime ≥ `02:29:37` is exactly L1–L7 plus `settings.json.tmpl` (the mutate/restore cycle) — and the template is **absent from `git diff --name-only`**, i.e. byte-identical to `HEAD` despite the moved mtime.
- Every `02` §9 frozen surface has an mtime **before** the window: `insight-index.md` `01:25:59` (and still exactly **30/30** bullets — not trimmed), `baseline.json` `23:57:33`, `README.md` `22:36:19`, `README.zh-CN.md` `22:36:23`, `docs/dev-map.md` `22:37:28`, `BATCH_PLAN.md` `01:30:16`, `docs/tasks.md` `01:31:29`, `evals/guard-rm-cases.md` `23:51:59`, `skills/harness-status/SKILL.md` `19:30:30`, `MIGRATION.md` / `CONTRIBUTING.md` / `docs/manual-e2e-test.md` / `.claude/settings.json` all `2026-07-31 10:42:09`.
- **Count-claim rows.** `baseline.json:10` = `32`, `:23` = `87`. `g4_files` (`verify_all.sh:720-732`) has exactly **eleven** entries and `CONTRIBUTING.md` is **not** among them — read from the array, not from memory. The literals on the two T-15-edited lines survived: `AI-GUIDE.md:74` still carries `32 checks`, `AI-GUIDE.md:42` still `32/32`, `40-locations.md:29` still `(32 checks,`.
- **Historical CHANGELOG rows** `:217, 741, 757, 1248, 1282, 1303` all still carry their retired `F.2` text; the T-15 block sits at `:69-94`, immediately before `## [0.45.0]` at `:96`; the `## [0.46.0] - 2026-07-31` heading date is unmoved.
- **`docs/tasks.md:18`** (the sibling `05` flagged as unenumerated) — read; still the frozen T-12 delivery row, unedited. Correctly left alone.
- **NFR-1.** `.claude/settings.local.json` mtime `2026-07-31 17:09:15` and `.harness/scripts/guard-rm.{sh,ps1}` mtime `2026-07-31 23:55:04` — all three unchanged across the whole session.
- **Tree state.** `git status --porcelain` is **byte-identical** to its pre-QA state (47 rows); `find` for `*t15*` outside `docs/features/` returns nothing; `git worktree list` shows only the main tree.

**Delivery prose.** No live surface describes this change as reducing guard coverage. The only tree-wide hit for that phrase family is `CHANGELOG.md:66-67`, which is T-17's block asserting the **opposite** ("no configuration that can weaken the guard"). `CHANGELOG.md:90-93` states behavioural coverage unchanged at 87 rows and the machine dimension relocated. `CHANGELOG.md:83` now reads "All **seven** assertions" — the `05` miscount fix landed.

## 7. What I could not verify

Stated so the delivery does not over-claim.

1. **PowerShell was not executed.** `command -v pwsh` → not installed. `verify_all.ps1` `F.2` is **green-by-symmetry only**. Specifically unexecuted: whether the file still parses at all (a parse error kills the entire gate on Windows), the accumulate-then-throw restructure, the `${tmpl}` brace disambiguation, `Get-Content -Raw`, and hazard 5 (a pipeline emission silently becoming `WARN`). What I *did* do is a statement-by-statement read of `.ps1:287-311` against all five hazards of `02` §3.2 — every statement is an assignment, an `if`/`foreach` whose body is an assignment, or the `throw`; `${tmpl}` braces present at both colon-adjacent sites; `throw ($problems -join ' ')` parenthesized with no `+`; `-Raw` present; no automatic-variable collision — plus structural counts (block braces 12/12, parens 12/12, whole-file braces 286/286 balanced, 32 top-level `Step` calls matching bash's 32 distinct ids). This is an audit, **not** a run. `02` §10.1's operator item 11 stands and is the only thing that can close it.
2. **The shell-deviation corpus models .NET regex in Python**, executed only on the bash side. MINOR-1 and MINOR-2 are therefore *modelled* for PowerShell.
3. **AC-10 (health report) was not re-verified.** `05` NIT records that FR-9's "confirmed by execution" is discharged by hand-applying a **prose** skill — there is no executable — and OQ-7(b) declined a driver. `05` re-derived both halves independently and ruled them correct. I did not add a third derivation; **do not add a driver** (declined scope).
4. **A literal `git clone` was not tested** — no commit of this content exists (§2).
5. **Byte-level freeze of files already dirty at S0** cannot be proven by diff, since no pre-T-15 snapshot was committed. mtime ordering plus targeted content reads is the strongest method available, and it is the method `05` ruling 2 identified as the one that actually carries the claim.

## 8. Defects

**0 BLOCKER · 0 CRITICAL · 0 MAJOR · 2 MINOR · 2 NIT · 1 observation.** Nothing blocks delivery; no rollback requested.

- **MINOR-1 — [SPEC/DESIGN, doc-only] → solution-architect (stage 2), non-blocking.** `02` §3.3 claims "exactly **two** recorded, accepted deviations" between the shells for B2. There is at least a **third** class: .NET `\s` matches Unicode whitespace that POSIX `[[:space:]]` does not under this locale, so `"PreToolUse"<U+00A0>:` and `"PreToolUse"<U+0085>:` match in PowerShell and not in bash (E-9, bash executed / PS modelled). Same direction (PS strictly more permissive) and same pathological reachability, so §3.3's **acceptance argument carries unchanged** — only the completeness word "exactly two" is wrong. Reproducer: `python3` corpus in E-9. Fix is one sentence in `02` §3.3 (e.g. "two named deviations, both instances of the general rule that .NET's `\s` and case handling are wider than POSIX's"), applied at delivery or in T-16.
- **MINOR-2 — [SPEC/DESIGN, doc-only] → solution-architect (stage 2), non-blocking.** `02` §3.3 gives S-1 and S-2 the same acceptance rationale, but they are not equally covered. S-1 (case) has a **backstop**: a lowercase key makes `J.1` co-fire (E-8 P1), so the design's "J.1's event-name list owns key spelling" is empirically true. S-2 (newline between key and colon) has **no backstop** — `J.1` passes cleanly because the file is still valid JSON (E-8 P2) — so on Windows that pathological template would be undetected by the whole gate, not merely by `F.2`. The verdict (accept, unreachable via a stable JSON formatter) is unchanged; the *stated basis* for S-2 must not borrow S-1's backstop.
- **NIT-1 — [DOC] → PM at delivery.** `CHANGELOG.md:80-83` enumerates four guard scripts + two template facts, then says "All seven assertions". The number is right (B0, template presence, is the seventh) but it is not in the enumeration — the same under-enumeration that produced the original "six facts" miscount. One clause would close it.
- **NIT-2 — [PORTABILITY, pre-existing] → backlog, not T-15.** This host's `grep` is **ugrep 7.5.0**, not GNU grep. `05`'s NIT about `grep -q '{{GUARD_COMMAND}}'` relying on an unescaped `{` being literal in BRE is therefore still untested against GNU grep or busybox. Confirmed working here; unchanged by T-15 (`02` §7 directed reuse). `grep -qF` would remove the question.
- **Observation (not a defect) — `test-supervisor.sh` reports 46 against `baseline.json`'s `test_supervisor_bash_no_python3_assertions: 45`.** The driver is byte-unmodified vs `HEAD`, `python3` is present on this host, and the key explicitly names the no-python3 variant. Pre-existing and outside T-15's surface. **No baseline edit** — `02` §4 makes `baseline.json` read-only for this task.

**Routing summary:** MINOR-1 and MINOR-2 → **stage 2 (solution-architect)**, doc-only, deliverable in parallel with stage 7 or folded into T-16. NIT-1 → **stage 7 (PM)**. NIT-2 → backlog. Nothing routes to the developer; nothing routes to a rollback.

## 9. verify_all result

- Total checks: 32 → **32** (unchanged, as required — `01` FR-5, out-of-scope 4).
- **PASS: 32 · WARN: 0 · FAIL: 0 · exit 0**, five consecutive runs.
- New automated tests added: **0**, deliberately. `02` §12 forbids a new gate check and OQ-7(b) forbids a new driver; adding either would be scope expansion on a task whose thesis is that this check should shrink. The thirteen mutations and eight template probes in this report are **exploratory**, run against scratch copies, and left no residue.
- **Baseline updated: no.** No count moved and `02` §4 makes `baseline.json` read-only here. Nothing went down.
- **Recommendation to the PM, for the T-16 row (not for T-15):** the containment residual confirmed in §5 currently has **no** regression coverage in any driver. When T-16 closes it, the P4/P6 constructions in E-8 are ready-made rows.

## 10. Stability

- `verify_all.sh` run **5×** consecutively: `PASS: 32 / WARN: 0 / FAIL: 0`, exit 0 every time, `[F.2] … PASS` every time. **No flakes.**
- `test-guard-rm.sh` run **3×**: `PASS: 87 / FAIL: 0`, exit 0 every time, summary line present every time. **No flakes.**
- Scratch-tree gate run **>20×** across the mutation matrix; every restore returned it to `32/0/0`. **No ordering or residue effects.**
- The tree is left **green** and byte-identical to its pre-QA state.

## 11. Verdict

**APPROVED FOR DELIVERY** (0 BLOCKER, 0 CRITICAL, 0 MAJOR; 2 MINOR doc-only findings routed to stage 2, neither blocking).

The headline claim is genuinely established by an independent, stronger construction than the developer's; all seven retained assertions are load-bearing under artifact mutation, including the three nobody had probed; the anchoring — this task's signature fix — is proven by running the **real pre-change gate** against a mutated artifact and watching it fail to notice the deleted hook block; multi-problem accumulation holds in three shapes; the whole gate and every driver is green with every tally pasted from its own run; and the frozen surfaces held, including the 200/200 rule fragment, the 30/30 insight index and both pinned baselines. Two residuals are carried forward honestly rather than papered over: the B1/B2 containment gap (declined scope, now confirmed by measurement instead of inference) and the entirely unexecuted PowerShell twin.

---

# Appendix E — Verbatim runs

Each block names the exact command that produced it. Nothing is shortened, re-columned or re-derived.

## E-1 — AC-1, live gate (`bash .harness/scripts/verify_all.sh`)

```
[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 17 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Plugin agents present ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
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
exit=0
```

## E-2 — AC-8, guard regression driver (`bash .harness/scripts/test-guard-rm.sh`)

```
  PASS  case  R4: & rm -rf /etc/harness-guard-probe -> BLOCK
  PASS  case  R5: pwsh -c "& Remove-Item -Recurse C:\Windows" -> BLOCK

=== test-guard-rm summary ===
  PASS: 87
  FAIL: 0
exit=0
```

## E-3 — AC-2, shipped gate on the clean state (refreshed index)

Construction: `git worktree add --detach .t15qa-clean HEAD` · `rsync -a --delete --exclude '.git' --exclude '.t15qa-clean' --exclude '.claude/settings.local.json' ./ .t15qa-clean/` · `git -C .t15qa-clean add -A` (534 files indexed) · `.t15qa-clean/.claude/` contains **only** `settings.json`, whose `:21` is `"hooks": {}`.

```
$ bash .t15qa-clean/.harness/scripts/verify_all.sh; echo "exit=$?"
[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 17 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Plugin agents present ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
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
exit=0
```

## E-4 — AC-3, the **real pre-change gate** on that identical state

Construction: `git show HEAD:.harness/scripts/verify_all.sh > .t15qa-clean/.harness/scripts/verify_all_prechange.sh`. Its `F.2` body was read back and confirmed to carry the `f2_hooks_file` selection, the three machine-wiring greps, and the **unanchored** `grep -q 'PreToolUse' "$tmpl"`.

```
$ bash .t15qa-clean/.harness/scripts/verify_all_prechange.sh; echo "exit=$?"
... (A.1 through F.1 identical to E-3, all PASS) ...
[F.2] Guard-rm scripts and PreToolUse wiring present ... FAIL
       .claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command
... (G.1 through G.4 identical to E-3, all PASS) ...

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
exit=2
```

## E-5 — B-1…B-4, four machine-settings states × both gate versions

```
### B-1 no machine-local settings file (clean checkout)
-- post-change: [F.2] Guard-rm scripts and settings-template guard wiring present ... PASS   exit=0
-- pre-change : [F.2] Guard-rm scripts and PreToolUse wiring present ... FAIL
       .claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command
                exit=2

### B-3 machine-local present with EMPTY hooks object (documented opt-out)
-- post-change: [F.2] ... PASS   exit=0
-- pre-change : [F.2] ... FAIL
       .claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command
                exit=2

### B-2 machine-local present and fully wired (copy of the live file)
-- post-change: [F.2] ... PASS   exit=0
-- pre-change : [F.2] ... PASS   exit=0

### B-4 committed settings.json ABSENT, no machine-local either
-- post-change: [F.2] ... PASS   exit=0
-- pre-change : [F.2] ... FAIL
       missing:.claude/settings.json-or-settings.local.json
                exit=2
```

B-3 is the one that empirically kills the "presence-conditional" middle path (`01` E-3 / OQ-2): the documented durable opt-out is a *present* file, and the pre-change gate is red on it.

## E-6 — AC-5/AC-6, seven independent artifact mutations (scratch tree)

```
##### BASELINE (unmutated scratch tree)
[F.2] ... PASS
=== Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0

##### M-A1 : rm .harness/scripts/guard-rm.ps1
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... FAIL
      Run .harness/scripts/sync-self.sh
[F.2] ... FAIL
       missing:.harness/scripts/guard-rm.ps1
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-A2 : rm .harness/scripts/guard-rm.sh
[E.1] ... FAIL
[F.2] ... FAIL
       missing:.harness/scripts/guard-rm.sh
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-A3 : rm skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1
[E.1] ... FAIL
[F.2] ... FAIL
       missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-A4 : rm skills/harness-init/templates/common/.harness/scripts/guard-rm.sh
[E.1] ... FAIL
[F.2] ... FAIL
       missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-B0 : rm skills/harness-init/templates/common/.claude/settings.json.tmpl
[E.1] ... PASS
[F.2] ... FAIL
       missing:skills/harness-init/templates/common/.claude/settings.json.tmpl
=== Summary === PASS: 31 WARN: 0 FAIL: 1 | exit=2

##### M-B1 : {{GUARD_COMMAND}} -> XGUARD_COMMANDX
[E.1] ... PASS
[F.2] ... FAIL
       skills/harness-init/templates/common/.claude/settings.json.tmpl:no_GUARD_COMMAND_placeholder
=== Summary === PASS: 31 WARN: 0 FAIL: 1 | exit=2

##### M-B2 : delete the "PreToolUse": [ ... ] array, KEEP the _guard_hook doc string
-- _guard_hook doc string still present:
5:  "_guard_hook": "PreToolUse hook auto-runs guard-rm before every Bash tool call. ..."
-- count of quoted "PreToolUse": 0
-- count of bare word PreToolUse: 1
-- NEW (anchored) gate:
[F.2] ... FAIL
       skills/…/settings.json.tmpl:no_GUARD_COMMAND_placeholder skills/…/settings.json.tmpl:no_PreToolUse_block
=== Summary === PASS: 31 WARN: 0 FAIL: 1 | exit=2
-- OLD (pre-change, UNANCHORED) gate on the SAME mutated file:
[F.2] Guard-rm scripts and PreToolUse wiring present ... FAIL
       .claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command skills/…/settings.json.tmpl:no_GUARD_COMMAND_placeholder
=== Summary === PASS: 31 WARN: 0 FAIL: 1 | exit=2
```

The last block is the anchoring proof: the old gate's token list contains **no** `no_PreToolUse` for the template — with the entire hook array deleted, it still believed the template was wired, because `_guard_hook` at `:5` satisfied its unanchored match.

## E-7 — B-9, multi-problem accumulation (scratch tree)

```
##### M-ALL : all five artifacts broken simultaneously
[F.2] ... FAIL
       missing:.harness/scripts/guard-rm.ps1 missing:.harness/scripts/guard-rm.sh missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1 missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh missing:skills/harness-init/templates/common/.claude/settings.json.tmpl
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-B1B2 : template present, BOTH placeholder and hook key broken
[F.2] ... FAIL
       skills/…/settings.json.tmpl:no_GUARD_COMMAND_placeholder skills/…/settings.json.tmpl:no_PreToolUse_block
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### M-MIX : two guard scripts missing AND placeholder broken
[F.2] ... FAIL
       missing:.harness/scripts/guard-rm.ps1 missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh skills/…/settings.json.tmpl:no_GUARD_COMMAND_placeholder
=== Summary === PASS: 30 WARN: 0 FAIL: 2 | exit=2

##### FINAL RESTORE CHECK
[F.2] ... PASS
=== Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0
```

## E-8 — Anchor-defeat and containment probes (scratch tree, real gate)

```
=== P0 baseline: shipped template ===
   gate: PASS   other reds:  | exit=0

### P1 lowercase key:  "PreToolUse": -> "pretooluse":
48:    "pretooluse": [
   gate: FAIL
   detail: skills/…/settings.json.tmpl:no_PreToolUse_block
   other reds: J.1, | exit=2

### P2 key split across a newline:  "PreToolUse"\n      : [
    "PreToolUse"
      : [
   gate: FAIL
   detail: skills/…/settings.json.tmpl:no_PreToolUse_block
   other reds:  | exit=2          <-- J.1 does NOT co-fire; S-2 has no backstop

### P3 doc-string only (hooks emptied, _guard_hook kept, placeholder moved to a Stop hook)
  quoted "PreToolUse" count: 0 ; bare-word count: 1 ; placeholder present: 1
   gate: FAIL
   detail: skills/…/settings.json.tmpl:no_PreToolUse_block      <-- B2 fails ALONE
   other reds:  | exit=2

### P4 CONTAINMENT RESIDUAL: "PreToolUse": [] (empty) + {{GUARD_COMMAND}} moved into the Stop hook
  hooks now: {'PreToolUse': 0, 'Stop': 1}
  PreToolUse array is EMPTY; the guard command lives in Stop.
   gate: PASS   other reds:  | exit=0        <-- residual confirmed

### P5 FALSE POSITIVE probe: no hook block, key form only inside a JSON string value
38:  "_note": "remember to add \"PreToolUse\": [] and {{GUARD_COMMAND}} someday"
   gate: FAIL
   detail: skills/…/settings.json.tmpl:no_PreToolUse_block
   other reds:  | exit=2        <-- JSON escaping defeats the false positive

### P6 hooks:{} entirely — key form present only under an unrelated top-level object
  hooks = {} ; the ONLY "PreToolUse": key lives under _example_only (not a hook at all)
   gate: PASS   other reds:  | exit=0        <-- residual confirmed, widest form

### P7 hooks key REMOVED entirely (no hooks object at all)
  'hooks' key present: 0 ; placeholder present: 0
   gate: FAIL
   detail: skills/…/settings.json.tmpl:no_GUARD_COMMAND_placeholder skills/…/settings.json.tmpl:no_PreToolUse_block
   other reds:  | exit=2

=== RESTORE CHECK ===
   gate: PASS   other reds:  | exit=0
```

## E-9 — Shell-deviation corpus (bash **executed**; PowerShell **modelled**, not run)

`command -v pwsh` → *not installed*. bash column: real `grep -qE '"PreToolUse"[[:space:]]*:'`. PS column: `re.search(r'"PreToolUse"\s*:', s, re.IGNORECASE)` as a model of .NET `-notmatch`.

```
case                       bash grep -qE  PS -notmatch (modelled)    deviation
C1  canonical              True           True
C2  no space               True           True
C3  tab before colon       True           True
C4  lowercase key          False          True                        <-- DEVIATION (S-1, recorded)
C5  UPPERCASE key          False          True                        <-- DEVIATION (S-1, recorded)
C6  newline before colon   False          True                        <-- DEVIATION (S-2, recorded)
C7  NBSP U+00A0 b4 colon   False          True                        <-- DEVIATION (NOT recorded -> MINOR-1)
C8  NEL U+0085 b4 colon    False          True                        <-- DEVIATION (NOT recorded -> MINOR-1)
C9  doc string only        False          False
C10 escaped in a value     False          False
C11 no colon at all        False          False
C12 CR before colon        True           True
C13 UTF-16LE canonical     False          True                        <-- speculative; PS decode behaviour unverified

LANG=en_US.UTF-8 LC_ALL=unset
ugrep 7.5.0 x86_64-pc-linux-gnu +sse2; -P:pcre2jit; -z:zlib,bzip2,zstd,brotli,7z,tar/pax/cpio/zip
```

C13 is listed for completeness but **not** claimed as a finding: PowerShell's `Get-Content -Raw` decode behaviour on a BOM-less UTF-16 file was not executed.

## E-10 — Doc-claim protection probes (scratch tree)

```
### D0 baseline
   reds: [] | === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0

### D1 QA-(i): revert .harness/rules/40-locations.md:42 to its retired wording
- Guard-rm script pair (repo + distributed template) + the settings template's guard wiring (F.2, v0.15+; FAIL if missing; reads no settings file — machine hook state is reported by `/harness-status`)
- Guard-rm scripts + `.claude/settings.json` PreToolUse wiring (F.2, v0.15+; FAIL if missing)
   reds: [] | === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0     <-- NO gate catches it

### D2 is G.4 load-bearing? flip '32 checks' -> '33 checks' in AI-GUIDE.md
   reds: [G.4,] | === Summary === PASS: 31 WARN: 0 FAIL: 1 | exit=2  <-- G.4 IS load-bearing

### D3 does any live doc still carry the retired label "PreToolUse wiring"?
   (no hits in .harness/rules/, AI-GUIDE.md, CONTEXT.md)

### RESTORE
   reds: [] | === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0
```

## E-11 — AC-4, `02` §3.4 three-part recipe on the **live** files

```
=== (a) POSITIVE — every file-touching operation in the bash F.2 block, with its target ===
5:    [[ -f "$f" ]] || f2_problems="$f2_problems missing:$f"
8:if [[ -f "$tmpl" ]]; then
9:    grep -q '{{GUARD_COMMAND}}' "$tmpl" || f2_problems="$f2_problems $tmpl:no_GUARD_COMMAND_placeholder"
10:    grep -qE '"PreToolUse"[[:space:]]*:' "$tmpl" || f2_problems="$f2_problems $tmpl:no_PreToolUse_block"

=== (a) POSITIVE — PowerShell F.2 block ===
6:        if (-not (Test-Path $f)) { $problems += "missing:$f" }
9:    if (Test-Path $tmpl) {
10:        $tmplText = Get-Content $tmpl -Raw

=== (b) NEGATIVE — masked code-line count of settings-read needles (expect 0 / 0) ===
bash: 0
ps1 : 0

=== (c) INVERSE — the comment MUST name both settings files ===
3:# .claude/settings.json, not the gitignored .claude/settings.local.json. Its result is a
3:# .claude/settings.json, not the gitignored .claude/settings.local.json. Its result is a

=== deleted machinery gone tree-wide (f2_hooks_file / hooksFile) ===
   0 hits
=== retired problem tokens (no_Bash_matcher / no_guard-rm_command) in .harness/scripts/ ===
   0 hits

=== recorded-step count ===
grep -c 'step "F.2"' verify_all.sh  -> 2   (mutually exclusive if/else, one record)
grep -c 'Step "F.2"' verify_all.ps1 -> 1
```

Permitted targets are `$f` and `$tmpl` only; **zero** JSON-parser calls in either shell.

## E-12 — Frozen-surface audit (live tree)

```
=== 200-line rule fragment ===
200 .harness/rules/75-safety-hook.md
in any committed file — `.claude/settings.json` does not accept it, and the
verify_all release check would catch any tracked file that hard-codes it.
(^ the known-stale, deliberately-unrepaired claim at :150-151 — still there)

=== pinned baselines ===
10:  "verify_all_checks": 32,
23:  "test_guard_rm_bash_assertions": 87,

=== mtime ordering (T-15's first write is verify_all.sh at 02:29:37) ===
MIGRATION.md                                                     2026-07-31 10:42:09
CONTRIBUTING.md                                                  2026-07-31 10:42:09
.claude/settings.json                                            2026-07-31 10:42:09
docs/manual-e2e-test.md                                          2026-07-31 10:42:09
.claude/settings.local.json                                      2026-07-31 17:09:15   <- NFR-1 untouched
skills/harness-status/SKILL.md                                   2026-07-31 19:30:30
README.md                                                        2026-07-31 22:36:19
README.zh-CN.md                                                  2026-07-31 22:36:23
docs/dev-map.md                                                  2026-07-31 22:37:28
.harness/scripts/test-guard-rm.sh                                2026-07-31 23:51:34
evals/guard-rm-cases.md                                          2026-07-31 23:51:59
.harness/scripts/guard-rm.sh                                     2026-07-31 23:55:04   <- live guard untouched
.harness/scripts/guard-rm.ps1                                    2026-07-31 23:55:04   <- live guard untouched
.harness/scripts/baseline.json                                   2026-07-31 23:57:33
.harness/rules/75-safety-hook.md                                 2026-08-01 01:14:04   <- frozen, 200/200
.harness/insight-index.md                                        2026-08-01 01:25:59   <- frozen, 30/30
docs/batches/default/BATCH_PLAN.md                               2026-08-01 01:30:16
docs/tasks.md                                                    2026-08-01 01:31:29
--- T-15 edit window starts here ---
.harness/scripts/verify_all.sh                                   2026-08-01 02:29:37   L1
.harness/scripts/verify_all.ps1                                  2026-08-01 02:29:57   L2
AI-GUIDE.md                                                      2026-08-01 02:30:07   L4
CONTEXT.md                                                       2026-08-01 02:30:40   L6
.harness/rejected-decisions.md                                   2026-08-01 02:30:48   L7
skills/…/common/.claude/settings.json.tmpl                       2026-08-01 02:34:15   mutate/restore, content clean
.harness/rules/40-locations.md                                   2026-08-01 02:39:51   L3
CHANGELOG.md                                                     2026-08-01 03:04:50   L5

=== settings template absent from git diff --name-only ===
(empty)  -> byte-identical to HEAD despite the moved mtime

=== g4_files (verify_all.sh:720-732) — eleven entries, CONTRIBUTING.md absent ===
AI-GUIDE.md · AI-GUIDE.md · docs/dev-map.md · docs/dev-map.md · .harness/rules/40-locations.md ·
README.md · README.zh-CN.md · README.md · README.zh-CN.md · docs/manual-e2e-test.md · .harness/scripts/baseline.json

=== insight-index bullet count (I.4 cap 30) ===
30

=== CHANGELOG placement + the 'seven assertions' fix ===
8:## [0.46.0] - 2026-07-31
69:### Changed — hook-truth-verify-scope (T-15): …
83:  `"PreToolUse"` hook key. All seven assertions stay at **FAIL** severity; none was softened.
96:## [0.45.0] - 2026-07-31
historical F.2 rows still intact at :217, :741, :757, :1248, :1282, :1303

=== live doc lines naming F.2 coverage (only L3 and L4) ===
.harness/rules/40-locations.md:42: Guard-rm script pair (repo + distributed template) + the settings
  template's guard wiring (F.2, v0.15+; FAIL if missing; reads no settings file — machine hook state
  is reported by `/harness-status`)
AI-GUIDE.md:74: … (32 checks, including … + F.2 guard-rm scripts + settings-template wiring + …)

=== teardown ===
git worktree remove --force .t15qa-clean && git worktree prune
git worktree list -> /home/alan/Programs/harness-kit  cb0ed57 [main]
find . -name '*t15*' (excluding .git and docs/features) -> (none)
git status --porcelain -> 47 rows, byte-identical to the pre-QA capture
```

## E-13 — Stability

```
=== STABILITY: 5 consecutive live gate runs ===
run 1: === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0 | F.2=PASS
run 2: === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0 | F.2=PASS
run 3: === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0 | F.2=PASS
run 4: === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0 | F.2=PASS
run 5: === Summary === PASS: 32 WARN: 0 FAIL: 0 | exit=0 | F.2=PASS

=== STABILITY: 3 consecutive guard regression runs ===
run 1: === test-guard-rm summary === PASS: 87 FAIL: 0 | exit=0
run 2: === test-guard-rm summary === PASS: 87 FAIL: 0 | exit=0
run 3: === test-guard-rm summary === PASS: 87 FAIL: 0 | exit=0

=== other drivers (each printed its own summary line) ===
test-verify-i6.sh        === Result ===  PASS: 58  FAIL: 0      exit=0
test-init.sh             === Result ===  PASS: 391 FAIL: 0      exit=0   (python3 present)
test-real-project.sh     === Result ===  PASS: 90  FAIL: 0      exit=0
test-harness-upgrade.sh  === Summary === PASS: 89  FAIL: 0      exit=0
test-language.sh         === Summary === PASS: 39  FAIL: 0      exit=0
test-supervisor.sh       === Result ===  PASS: 46  FAIL: 0      exit=0   (baseline key is the no-python3 variant, 45)
sync-self.sh --check     In sync.                               exit=0
```
