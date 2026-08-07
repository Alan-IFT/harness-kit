# 05 — Code Review · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 5 (code-reviewer) · **Round**: 2 (rollback 1 of max 3) · **Date**: 2026-07-31
**Upstream**: `01_REQUIREMENT_ANALYSIS.md` (READY + Amendment 1) · `02_SOLUTION_DESIGN.md` (READY, rework 1) · `03_GATE_REVIEW.md` (APPROVED, 8/8 PASS) · `04_DEVELOPMENT.md` (READY FOR REVIEW, rework round 1)

> Transcription note (PM): the code-reviewer agent is read-only by contract (Read/Glob/Grep) and returned this report as text. PM persisted it verbatim, replacing round 1; no PM editing of content.

> **Reviewer capability disclosure (binding on how you read this).** Read / Glob / Grep only — no Bash, no git, no pwsh. I cannot re-execute `verify_all`, `test-init.sh`, the installer, `cmp`, `diff` or `git`. Execution claims are marked **[unverifiable-here]** and treated as hypotheses. Where an execution claim had a *checkable structural or arithmetic consequence*, I checked that consequence from source and say so. This round I re-derived the new assertion counts from source, re-walked every M-1 edit in all four installer files, and read both archive annotations in place.

**This report supersedes round 1 and stands alone.** §0 carries round 1's findings and their disposition; §1-§6 are this round's verification.

---

## 0. Round 1 summary and disposition (the review record, carried forward)

Round 1 verdict was **CHANGES REQUIRED (0 CRITICAL, 1 MAJOR, 7 MINOR, 4 NIT)**. Round 1 also adjudicated PASS on a large surface that this rework did not disturb and which I have **not** re-litigated: the spec pair's PS hazard class (no `param()`, no automatic-variable collision, single-quoted `-f` literals, no here-string, `WriteAllText` on both bodies); FC-1/FC-2/FC-3; §8's truth table and the B-7 opt-out; the AC-3 oracle as a genuine call-through against the live OS-parametric `resilient_cmd` for all 8 cells; the count ledger closed at exactly five live sites; every DO-NOT-TOUCH decoy frozen; the `test_hook_spec` block at 45 assertions; DEV-1's fix being semantics-preserving.

| # | Round-1 finding | Sev | Developer disposition | **My round-2 verdict** |
|---|---|---|---|---|
| **M-1** | `n_wired > 0` not `== 4`; DEV-4 dropped both design-mandated step-7 literals ⇒ FC-4 / §6 step 7 not enforced | MAJOR | FIXED | **CLOSED — verified in all four files, both shells. See §1.** |
| m-1 | step-6 `write_failed` reused for step-7 ⇒ false "left absent" message | MINOR | FIXED | **Closed** (`install-hooks.sh:260-265` / `.ps1:309-314`). One residual doc echo → new **n-6**. |
| m-2 | `mkdir -p .claude` failure aborts exit 1 (documented as "not a git repo"); B-8 exit 5 unreachable | MINOR | FIXED | **Closed** (`sh:222` `\|\| write_failed`; `.ps1:259-265` try/catch). Verified `Stop-OnWriteFailure` is defined at `:249`, before its first use at `:264`. |
| m-3 | six `& pwsh … 2>&1` native captures under `$ErrorActionPreference = "Stop"` may raise and kill the PS driver | MINOR | **DECLINED** as a code change; promoted to binding operator item #6 | **Decline accepted as honest and adequately mitigated. See §5.** Site list corrected 5 → 6 and verified exact. |
| m-4 | `Get-ChildItem -Filter "settings.local.json.*"` Win32 wildcard ≠ `find -name` | MINOR | FIXED defensively (DEV-7) **and** kept as operator item #7 | **Closed** (`test-init.ps1:1139-1142`). |
| m-5 | "since T-011" wrong; the 278 claim contradicts this repo's archive | MINOR | FIXED **empirically** (captured pre-change run) + both archived docs annotated (DEV-8) | **Closed and well beyond the bar. See §4.** |
| m-6 | `Test-InstallBootstrap` hardcodes the Windows fixtures; bash twin is host-bound | MINOR | FIXED | **Closed** (`test-init.ps1:1005-1019`, now `$IsWindows -or $env:OS`, matching `Test-Type`). |
| m-7 | ledger row D11 `docs/tasks.md` open | MINOR | Not mine — PM-owned | **Still open, PM. Correctly out of developer scope.** |
| n-1 | `for tool in $spec_tools` glob-exposed | NIT | FIXED | **Closed** (`install-hooks.sh:181-196`, `while IFS= read -r` over a here-string). Correctly **not** a pipeline, so the array appends survive the loop; and `hook-spec.sh` never reads stdin, so the child processes cannot eat the id list. |
| n-2 | `$PSNativeCommandUseErrorActionPreference = $false` silences a failing `chmod +x` | NIT | FIXED | **Closed** (`.ps1:157-167`, explicit `$LASTEXITCODE` check, aborts with the child's status). |
| n-3 | `Write-Error` under `Stop` makes `exit 1` dead | NIT | Confirmed-no-action | **Agreed.** Pre-existing; observable exit is still 1. |
| n-4 | spec queried before `mkdir -p .claude` (design §8 row 4 orders the reverse) | NIT | Confirmed-no-action | **Agreed.** Strictly better; recorded so it is never re-read as drift. |

---

## 1. M-1 closure — verified in all four installer files, both shells

**CLOSED.** Not on the developer's paste; re-grepped and read.

| Design obligation | bash (repo **and** `templates/common/`) | PowerShell (repo **and** `templates/common/`) |
|---|---|---|
| Exact arity | `install-hooks.sh:202` — `(( n_wired == 4 )) \|\| spec_fail "tools (expected 4 ids, got $n_wired)"` | `install-hooks.ps1:241` — `if ($nWired -ne 4) { Stop-OnSpecFailure "tools (expected 4 ids, got $nWired)" }` |
| Routed through the design's exit 4 | `spec_fail` → `exit 4` (`:166-170`) | `Stop-OnSpecFailure` → `exit 4` (`:198-202`) |
| Names expected *and* actual | yes | yes |
| §6 step-7 literal `"PreToolUse"` | `:273` `grep -qF --` | `:323-325` ordinal `IndexOf` |
| §6 step-7 literal `"matcher": "Bash"` | `:274` `grep -qF --` | `:326-328` ordinal `IndexOf` |
| Spec-derived per-tool checks **kept alongside** | `:275-283` | `:329-341` |
| `> 0` / `-eq 0` arity gone | grep for `n_wired > 0` → 0 hits | grep for `nWired -eq 0` → 0 hits |

Both mirror halves are line-for-line coincident at 202 / 241 / 273-274 / 323-327 in all four files — consistent with the claimed `diff`-clean mirrors and E.1 green. The remaining `-eq 0` in the PS twin (`:215`, `if ($specTools.Count -eq 0) { Stop-OnSpecFailure 'tools (no tool ids)' }`) is a *distinct* empty-list guard before the loop with its own diagnostic, not the arity check; it cannot admit a partial wiring because `:241` runs after it. The dev doc's blanket "`> 0` / `-eq 0` are gone" is imprecise on that one line only — cosmetic, no finding.

**FC-1 re-verified after the restore, as I predicted in round 1.** `Grep 'guard-rm'` restricted to `**/install-hooks.{sh,ps1}` returns **zero hits in all four files**. Neither restored literal carries the token. The prediction holds: FC-1 never required dropping them.

**FC-2, FC-3, FC-4 re-checked:**

- **FC-2 — PASS, undisturbed.** No `${var//…}`, `sed`, `-replace` or `.Replace()` on any code line of any of the four installers. The command value reaches the body by plain expansion (`sh:243` / `.ps1:285`) and is compared unmodified at `sh:281` / `.ps1:338`. B-12 remains unreachable, not merely handled.
- **FC-3 — PASS, undisturbed.** `hook-spec.sh:108-109` (unix guard) and `:102-103` (windows guard) carry no `|| exit 0`, no trailing `exit 0`, no `-EA SilentlyContinue`; both `-NoProfile` flags intact (NFR-3). Note the *convenience* branch at `:111` does carry `|| exit 0` — that is the designed fail-open form and is correctly confined to the non-guard branch.
- **FC-4 — now PASS on the question round 1 marked PARTIAL.** I walked every degradation class for "is there still a path to a partial wiring that exits 0?":

  | Degraded spec | Outcome | Where caught |
  |---|---|---|
  | Fewer than 4 ids (a tool dropped) | **exit 4, nothing written** | `sh:202` / `.ps1:241` — the M-1 fix |
  | 4 ids but `guard-rm` absent | **exit 5, no success line**, file flagged present-but-unconfirmed | the restored literals `sh:273-274` / `.ps1:323-327` |
  | ≥5 ids / any unknown id | exit 4 on the `event <bogus>` query (hook-spec exits 2) | `sh:183` / `.ps1:221` |
  | Spec missing / non-zero / empty answer | exit 4, nothing written | W-1 capture form throughout |
  | `guard-rm` present but the matcher is `none` | exit 5 (the `"matcher": "Bash"` literal misses) | `sh:274` / `.ps1:326` |
  | **4 ids, all duplicates including `guard-rm`** | **exit 0 with one event wired** | **nothing — see MINOR r-1** |

  The last row is the only residual, it is contrived (it requires rewriting `hook-spec.sh:120`'s fixed `printf`, not merely degrading it), and critically **the guard is present and fail-closed in it**. The two restored literals are exactly what converts the realistic "guard silently dropped" case from exit 0 into exit 5. **There is no path in any shell, OS variant or boundary row where a missing guard yields exit 0.** The hard boundary holds.

---

## 2. The new executable FC-4 assertion — non-vacuous, and it genuinely discriminates

`test-init.sh:974-989` / `test-init.ps1:1190-1212`. The stub moves the real spec aside and delegates every query except `tools` to it, truncating `tools` to 3 ids via `head -n 3` / `Select-Object -First 3`. The kept 3 are `harness-sync`, `guard-rm`, `ambient-prompt` (the spec's fixed order at `hook-spec.sh:120`).

**Would it fail if the branch were reverted to `> 0`?** Yes — and this is the sharp part. With `n_wired > 0`, all three per-tool query sets succeed, the body is written with three events, and step 7 passes: the truncated set **still contains `guard-rm`**, so both restored literals are satisfied and every spec-derived per-tool check compares against the same three answers. The installer would exit 0 with the file present, and the assertion `[[ $rc -eq 4 && ! -f "$localset" ]]` goes red on both halves of the conjunction. The row therefore exercises the `== 4` branch **specifically** — it is not accidentally covered by the literal restore. That is a well-designed test, and it is the same anti-vacuity lens I applied to the AC-3 call-through in round 1.

**One residual vacuity vector, MINOR r-2:** the assertion accepts *any* exit 4. If the stub itself were silently broken (wrong `hs_good` path, PS parse error in the stub, `& pwsh` unavailable), the installer would exit 4 via `spec_fail "tools"` and the row would pass green without ever reaching the arity check. The stub reads correctly to me (`$tmp` is expanded at write time into an absolute path; `hook-spec.sh` is invoked as `bash "$spec"` so no exec bit is needed; the explicit `exit 0` masks any SIGPIPE from `head`), so I judge this a hardening gap and not a live defect. Grepping the captured stderr for `expected 4 ids, got 3` would close it by construction, and would also make it a proper mutation target.

Both twins land the row at the same position (7 of 8) with the same text, so the bash/PS lockstep is intact.

---

## 3. The byte-identity claim — structurally sound

The developer's `cmp`-identical claim is **[unverifiable-here]**, but the structural question the coordinator asked — *does any M-1 edit touch the JSON body assembly path, or only the validation path?* — is checkable and the answer is **only the validation path**:

- bash: body assembly is `:224-251` (doc strings, `body` array, the `while (( i < n_wired ))` emitter). M-1's edits are at `:198-202` (before the body exists) and `:268-274` (after the rename). Nothing between `:224` and `:254` moved.
- PS: body assembly is `:267-292`; M-1's edits are at `:237-241` and `:318-328`. Same conclusion.

The only shared variable is `n_wired` / `$nWired`, used as the emitter's loop bound. On any run that reaches the body, its value was 4 before the change and is *forced* to be 4 after it — the check only rejects earlier, it never alters the value. **Byte-identical output is the necessary consequence, not a coincidence.** The claim is granted.

---

## 4. The archive contradiction — resolved, and resolved the right way

This is the item the coordinator singled out. I hold it to the high bar asked for, and it clears it.

**(a) Consistency with the evidence and with my own round-1 §1(a).** My round-1 analysis said exactly one of two records must be false, that the mechanism analysis made T-12's archived `278/0` bash tally the more probable falsehood, and that the delivery record must **state** which rather than leave a contradiction. The developer did not argue the point — he extracted `cb0ed57` into a scratch worktree and ran it. The reported result (last line `PASS [T-020] every settings hook command path exists on disk (AC-5)`, 72 PASS lines, **no `=== Result ===`**, `EXIT=1`) is precisely what my §1(a) mechanism predicted, and it discriminates between the two branches I identified: `EXIT=1` with an empty stderr is the `exec bash …ambient-prompt.sh` branch (the script exits 1 when `$CLAUDE_PROJECT_DIR` is unset in that context), not the `|| exit 0` branch. The last line printed is `:351`, and the run dies on the very next assertion at `:365` — the first row that interpolates a single-quote-bearing value. Every detail coheres. `278 = 354 − 76` is confirmed independently below. **Conclusion granted: the value 278 is right, the run record is fabricated.**

**(b) Append-only annotation — verified by reading both files.**
- `_archived/resilient-hooks/04_IMPLEMENTATION.md`: the original `test-init.sh 278/0` line survives **verbatim at `:122`**; the correction is a blockquote at `:126-134`, after it, clearly attributed and dated, and it explicitly instructs the reader not to read the line above as a capture. No number above it was altered; the "Design drift" section following it (`:136-151`) is untouched.
- `_archived/resilient-hooks/06_QA_REPORT.md`: the §6 table (`:135-143`), the `276 → 278` totals line (`:145`) and the baseline line (`:148`) all survive **verbatim**; the correction is a blockquote at `:150-159`. It names all three affected rows rather than just the table.

No history is rewritten in either file. This is exactly the shape design decoy #2 and #3 protect (`_archived/**` and append-only history rows), and the coordinator's scope grant covers it. **I do not flag it as an out-of-scope violation** — and I note it would have been one without the grant, so the grant is load-bearing and should be recorded in `07_DELIVERY.md`.

**(c) Attribution corrected to T-12 / v0.44.0 in all three live places** — verified:
- `04_DEVELOPMENT.md:178-180` — "Exposure window: T-12 / v0.44.0 → HEAD (corrected in rework 1)".
- `CHANGELOG.md:46-47` — "arrived with **T-12 / v0.44.0**, so the exposure window is T-12 → HEAD".
- `baseline.json:_qa_note_t13` — "the exposure window is T-12 -> HEAD, NOT 'since T-011'".
A repo-wide grep for `T-011` returns no surviving live claim of the old attribution; the remaining hits are historical archive references and two `upgrade-project.*` comments about an unrelated fact.

**(d) The tally-fabrication insight is re-surfaced as a second occurrence** — `04_DEVELOPMENT.md:465`, and again inside the `06_QA_REPORT.md` annotation itself, both citing `.harness/insight-index.md:12` (2026-06-04) as the first. `insight-index.md` itself is correctly **untouched** (decoy #4: appended at delivery/archive time, not now). The framing the developer landed — "the number was right, which is exactly why nobody noticed… cross-check every reported tally against the artifact that allegedly produced it" — is the correct generalization and is stronger than what I asked for.

**The withdrawal is the part I want to commend.** The developer's own round-0 sub-claim ("the pinned 278 was a complete tally only on Windows") was itself unverified, and rather than quietly keeping it he withdrew it in writing (`04_DEVELOPMENT.md:212-215`, and in `_qa_note_t13`). Correcting someone else's record while withdrawing your own unverified claim in the same breath is the behaviour this repo's insight discipline is supposed to produce.

---

## 5. m-3's decline — honest and adequately mitigated

The stated reason is that every candidate mitigation changes error semantics in a driver the agent cannot execute. That is true but not airtight: scoping `$ErrorActionPreference = 'Continue'` around the six captures would be a narrow, low-risk mitigation. Weighing against it:

- The site list was **corrected upward** (5 → 6) rather than left flattering, and I verified all six exactly: `test-init.ps1:1073, 1120, 1161, 1180, 1207, 1216`. The new one is the FC-4 row at `:1207` — i.e. the developer's own new code added a site and he said so.
- The mechanical claim is accurate: `Test-InstallBootstrap` has `try`/`finally` at `:1004`/`:1219` with **no `catch`**, so a `NativeCommandError` would indeed propagate out and kill the driver after running cleanup, exactly as described.
- The failure mode is loud (no `=== Result ===` line) — the identical signature the T-12 archive fabrication turned on, and the operator is now explicitly told to *check for that line*.
- It is test-driver-only and touches no shipped behaviour.
- The operator PS run is already booked and binding.

**Accepted.** Recorded verbatim in `baseline.json:_qa_note_t13` as well as operator item #6, so it cannot be lost between here and delivery.

---

## 6. Baseline discipline — re-derived from source

I counted the assertions myself rather than accepting the decomposition.

- `test_hook_spec` (`test-init.sh:761-856`): 1 + 1 + 8(A) + 8(A′) + 4+2(B) + 8(C) + 4+4+1+1(D) + 3(E) = **45** — unchanged from round 1.
- `test_install_bootstrap` (`:861-998`): named `assert` calls at `873, 874, 880, 881, 891, 895, 897, 899, 901, 903, 909×4, 913, 915, 919, 921, 922, 924, 926, 929, 935, 936, 940, 943, 950, 958, 970, 988, 995` = **31** when the read-only probe at `:963-971` is not skipped. Exactly **+1** over round 1's 30, and the added one is `:988` — the FC-4 row. Nothing else moved.
- 45 + 31 = **76**; 278 + 76 = **354**. `baseline.json:12` reads **354**. ✔
- The PS twin's `Test-InstallBootstrap` also counts **31** Assert calls (`1041 … 1218`), so the twins stay in lockstep.
- Independent corroboration survives the move: `390 − 354 = 36 = 3 × 12`, the documented per-type size of the python3-gated AI-native block.
- The bash tally is claimed from a captured run **[unverifiable-here]**, but three routes now converge on 278 for the pre-existing set (arithmetic `354 − 76`; the archived value; the newly captured fixed-pre-change run), so a hand-derived 354 would have to be a coincidence in three places.
- `baseline.json:11` `test_init_ps_assertions` = **316**, unreconciled and flagged as such in `_qa_note_t13`. ✔
- `README.md:5` and `README.zh-CN.md:5` both still carry `test--init-316%2F316` and `verify__all-32%2F32`; only `version-0.45.0-blue` moved. **Both frozen badges intact in both files.** ✔
- `baseline.json:10` `verify_all_checks` = **32**; the rework touched no `verify_all.*` file, and 32/0/0 is reported captured. ✔

---

## Findings (round 2)

### CRITICAL
*(none)*

### MAJOR
*(none — round 1's M-1 is closed; see §1)*

### MINOR

- **r-1 [LOGIC / DESIGN] `install-hooks.sh:202,275-283` · `.ps1:241,329-341` (all four files)** — a spec answering with **four duplicate ids that include `guard-rm`** satisfies `== 4`, satisfies both restored literals and satisfies every spec-derived per-tool check (it compares one command four times), so it exits 0 having wired one event, not four. FC-4's letter is "all four **events** or nothing". The safety direction is unaffected — the guard is present and fail-closed in that scenario, and every id set *lacking* `guard-rm` is caught by the literals at exit 5 — and it requires rewriting `hook-spec.sh:120`'s fixed `printf` rather than degrading it, which is why this is MINOR and not a re-opening of M-1. Cheap close: assert the four event names are distinct, or add `"Stop"` / `"UserPromptSubmit"` / `"SessionStart"` to the literal confirmation list. **Good QA mutation target** (mutate the artifact, not the assertion list): make `tools` emit `guard-rm` four times and check the exit code.
- **r-2 [TEST] `test-init.sh:986-988` · `test-init.ps1:1207-1210`** — the FC-4 row accepts *any* exit 4, so a silently broken stub (wrong path, PS parse error in the generated stub, `pwsh` unavailable) would produce exit 4 via `spec_fail "tools"` and pass the row green without exercising the arity branch. The stub reads correctly to me, so this is a hardening gap, not a live defect; also grepping the captured output for `expected 4 ids, got 3` would make the row non-vacuous by construction. Note this also makes the row's anti-revert property conditional on the stub working — which is the property that justifies the assertion's existence.
- **r-3 [PS-RISK, carried from m-3] `test-init.ps1:1073,1120,1161,1180,1207,1216`** — six `& pwsh … 2>&1` native captures under script-scope `$ErrorActionPreference = "Stop"`. Declined as a code change, adequately mitigated (§5). Remains **binding operator item #6**; must not be dropped from `07_DELIVERY.md`.
- **r-4 [PS-RISK, carried from m-4] `test-init.ps1:1139-1142`** — defensively fixed (target excluded by exact name, result wrapped in `@()`); remains **binding operator item #7** because it is unexecutable here.
- **r-5 [COMPLETENESS, carried from m-7] ledger row D11 `docs/tasks.md`** — still open. **Owner: PM.** Correctly outside the developer's surface, and keeping it there also keeps the historical `T-13 lang-policy-split` collision at `docs/tasks.md:48` off his edit path.

### NIT

- **n-6 [DOC] `install-hooks.sh:31-32` · `install-hooks.ps1:31-32` (all four files)** — the exit-code header still reads *"5 writing or confirming the machine-local settings file failed (the target is left ABSENT, never half-written)"*. Since m-1's fix, the step-7 confirmation path deliberately leaves the target **present** and says so at runtime (`sh:262` / `.ps1:311`). The header now contradicts the (correct) runtime message on that sub-path. One clause: "…on the write path the target is left absent; on the confirmation path it is present and the diagnostic says so." Not a behaviour issue — the runtime message is louder than the header and is right.
- **n-7** — `04_DEVELOPMENT.md:44` says "`> 0` / `-eq 0` are gone"; `install-hooks.ps1:215`'s `$specTools.Count -eq 0` empty-list pre-guard survives (correctly, with its own distinct diagnostic). Purely a wording imprecision in the dev doc; no code change wanted.
- **n-3, n-4** from round 1 — confirmed-no-action, agreed, recorded so re-review does not re-raise them.

---

## Requirement coverage check (deltas from round 1 only; all others verified ✅ in round 1 and undisturbed)

| Criterion | Implementation | Status |
|---|---|---|
| FR-8 bootstrap when no hooks + no local file | `install-hooks.sh:148-295` / `.ps1:165-351` | ✅ |
| FR-11 JSON shape | body assembly untouched by the rework (§3); artifact re-inspected | ✅ |
| AC-5 bootstrap | `test-init.sh:883-929` + dogfood capture | ✅ (run **[unverifiable-here]**) |
| AC-6 idempotent, no backup | `:931-943`; PS twin now host-equivalent at `.ps1:1139-1142` | ✅ |
| AC-8 gate 32/0/0 | no `verify_all` file touched in rework; 32/0/0 reported captured | ✅ (run **[unverifiable-here]**) |
| AC-10 cross-shell byte parity | unchanged; green-by-symmetry-only as NFR-5 permits | ⚠️ operator-pending, as designed |
| AC-12 release-claim consistency | `README.md:5` / `README.zh-CN.md:5` — version badge only; `verify__all-32%2F32` + `test--init-316%2F316` unmoved in **both**; `baseline.json:10-11` still 32 / 316 | ✅ |
| **NFR-2 fail-closed** | FC-1 zero hits ×4 files · FC-2 zero code-line hits ×4 · FC-3 both guard branches clean · **FC-4 now enforced** (§1) | ✅ **(was the M-1 gap)** |
| NFR-5 PS operator gate | seven binding items in `04_DEVELOPMENT.md:394-423`, mirrored into `baseline.json:_qa_note_t13` | ✅ |

All other FR-1…FR-16 / AC-1…AC-14 / NFR-3 / NFR-4 rows were verified ✅ in round 1 and are untouched by this rework.

---

## Design fidelity check (deltas from round 1 only)

| Design item | Implementation | Status |
|---|---|---|
| **§6 step 7 — confirmation includes literal `"PreToolUse"` + `"matcher": "Bash"` + the 4 commands verbatim** | `sh:267,273,274,275-283` / `.ps1:317,323,326,329-341`, all four files | ✅ **(was ❌ MAJOR)** |
| **§10 FC-4 — all-four-or-nothing** | `sh:202` `(( n_wired == 4 ))` / `.ps1:241` `-ne 4`, both → exit 4; executably asserted `test-init.sh:988` / `.ps1:1209` | ✅ **(was ❌ MAJOR)**, with the duplicate-id residual at MINOR r-1 |
| §6 step 6 vs step 7 diagnostics distinguished | `write_failed` `sh:213-218` vs `confirm_failed` `sh:260-265`; `Stop-OnWriteFailure` `.ps1:249-254` vs `Stop-OnConfirmFailure` `.ps1:309-314` | ✅ (header wording lags → n-6) |
| §3.2 W-1 non-swallowing capture for every spec call | `sh:173-196` — now `while IFS= read -r` (n-1), still `if ! v="$(…)"` + separate `[ -n ]` on all five queries | ✅ |
| §9 baseline from a captured run; PS stays 316; checks stay 32 | `baseline.json:10-12,23` — 32 / 316 / 354 | ✅ |
| §11 D11 `docs/tasks.md` | not edited (DEV-6) | ⚠️ **open — PM** |
| §11 decoys frozen | re-checked after the rework: both README badge sets intact, `insight-index.md` untouched, no historical `## [x.y.z]` moved, `_archived/**` **annotated append-only under explicit coordinator grant** (DEV-8), originals verbatim | ✅ |

**Eight logged deviations**: DEV-1 (correct, and now empirically corroborated); DEV-2, DEV-3, DEV-5 unchanged and correct; **DEV-4 withdrawn** — the developer struck it through and recorded that the reviewer was right, which is the honest disposition; DEV-6 disclosed non-action (PM); DEV-7 (m-4 defensive fix) additive and symmetry-improving; DEV-8 (archive annotation) in scope by grant, append-only, verified.

---

## Axis status

- **Standards-conformance — 3 findings, worst = MINOR** (r-2, r-3, r-4; plus n-6, n-7). No `.claude/` hand-edit, no red-line file touched, doc-size caps respected, byte-mirror discipline intact in both directions at every M-1 line, `verify_all` still 32, count ledger unmoved, both frozen README badges unmoved, `insight-index.md` correctly not pre-appended, cross-shell parity preserved on every rework edit (both twins land 31 bootstrap assertions with matching text and ordering). No rule invented in this review. The archived-doc edit is in scope by explicit coordinator grant and is genuinely append-only.
- **Spec/design-fidelity — 2 findings, worst = MINOR** (r-1; plus r-5, the PM-owned open ledger row). **Round 1's sole MAJOR is closed on evidence I gathered myself, in all four files and both shells.** §6 step 7 and §10 FC-4 are now implemented as written, the byte-identity claim is structurally necessary rather than asserted, the baseline decomposition re-derives exactly from source, and the archive contradiction is settled empirically with the losing record annotated rather than rewritten.
- **Aggregate** = the more severe of the two = **MINOR**.

---

## Verdict

### **APPROVED WITH NITS** (0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT)

M-1 is genuinely fixed, not narrated as fixed. The fix is exactly the shape round 1 asked for — arity `== 4` through the design's `exit 4` path naming expected and actual, both design literals restored *alongside* the spec-derived checks, FC-1 still at zero hits, in both shells and both mirror halves — and it is backed by a new executable assertion that discriminates against the reverted branch. The rework introduced no regression I can find, and the archive contradiction was resolved the hard way, by running the artifact.

**Owner = developer, non-blocking, fold into delivery or leave for QA:**
- **r-1** — the duplicate-id residual in FC-4. Either close it (assert distinct event names, or add the other three event literals to the confirmation) or record it explicitly in `07_DELIVERY.md` as a known bound of FC-4. My recommendation: record it and hand it to QA as a mutation target rather than adding code this late in the round.
- **r-2** — harden the FC-4 row by also matching the `expected 4 ids, got 3` diagnostic, in both twins.
- **n-6** — one clause in the exit-code header of all four installer files.

**Owner = developer, must land in `07_DELIVERY.md`:** the **seven** binding NFR-5 operator items verbatim, r-3 and r-4 among them; the coordinator's scope grant for the archived-document annotation (DEV-8), so the archive edit is defensible on any later audit; and the tally-fabrication second-occurrence insight for `insight-index.md` at archive time.

**Owner = PM:** **r-5** — close ledger row D11 (`docs/tasks.md:9` active row + completion entry), avoiding the historical `T-13 lang-policy-split` row at `:48`.

**Owner = solution-architect:** nothing. No drift is attributable to the design in either round.

**Owner = QA (stage 6):** r-1 and r-2 are the two highest-value adversarial targets I can hand over, both mutations of the *artifact* rather than the assertion list. The three claims I could not execute — `verify_all` 32/0/0, `test-init.sh` 354/0, and the `cmp` byte-identity of the pre- and post-rework generated settings file — are all cheaply re-runnable by QA on bash and should be re-captured independently rather than inherited, on the exact principle this task just spent a round establishing.

No `BLOCKED: NEEDS-HUMAN` item arises. The only human-reserved item remains the pre-existing, already-booked NFR-5 PowerShell operator run, now carrying seven checks, with `test_init_ps_assertions` correctly left unreconciled at 316 and both README `test--init-316%2F316` badges correctly frozen until that run moves them together.

---
---

# Round 3 addendum — code review · T-13 `hook-truth-spec`

> Transcription note (PM): appended verbatim as returned by the read-only code-reviewer agent after developer rework round 2 (the QA r-1/r-6/r-2/n-6 patch). Round 2's body above stands unchanged.

**Scope**: only the rework-round-2 surface (QA r-1 / r-6 / r-2 / n-6 + regression). Everything cleared in round 2 stands and is not re-litigated except where this rework disturbed it.

**Reviewer capability disclosure (unchanged)**: Read/Glob/Grep only — no Bash, no git, no pwsh. Execution claims are marked **[unverifiable-here]**. Where a claim had a checkable structural consequence, I checked the consequence from source and say so. This round I re-read all four installer halves at the changed regions, both hardened test rows, the PS precedence claim against PowerShell's documented operator precedence, the baseline, both READMEs, `docs/tasks.md`, design §8/§10, and 20 line citations.

---

### A. The distinct-event-count gate — closes r-1, r-6 and the mixed-duplicate case, **before** the write

Verified present, identical, in **all four halves** (`.harness/scripts/` and `skills/harness-init/templates/common/.harness/scripts/`):

| Half | Arity gate | Distinct gate | Both route to |
|---|---|---|---|
| `install-hooks.sh` (×2) | `:205` `(( n_wired == 4 )) \|\| spec_fail "tools (expected 4 ids, got $n_wired)"` | `:213-214` `n_distinct=$(printf '%s\n' "${wired_events[@]}" \| sort -u \| wc -l)` + `(( n_distinct == 4 )) \|\| spec_fail …` | `spec_fail` → `exit 4` (`:172`) |
| `install-hooks.ps1` (×2) | `:244` `if ($nWired -ne 4) { Stop-OnSpecFailure … }` | `:255-259` `@($wired \| ForEach-Object { $_.event } \| Sort-Object -Unique).Count` + `-ne 4` | `Stop-OnSpecFailure` → `exit 4` (`:204`) |

**Ordering is the load-bearing property and it holds.** bash: the gate at `:213-214` precedes `mkdir -p "$repo_root/.claude"` (`:234`), the temp write (`:265`) and the rename (`:266`). PS: `:255-259` precedes `New-Item` (`:277-283`), `WriteAllText` (`:313`) and `Move-Item` (`:318`). The guardless residue r-6 turned on therefore **cannot come into existence** on this path, and §8 row 3 is untouched — verified at `02_SOLUTION_DESIGN.md:242`, byte-unchanged. This is the correct fix given row 3 is deliberate.

**The closure is stronger than the comment claims, and I verified it independently of the developer's reasoning.** Events are a function of tools, so `distinct events ≤ distinct tools ≤ 4`. `n_distinct == 4` therefore forces four *distinct tool ids*, which forces the full tool set, which forces the destructive-command guard to be present — **without** relying on the event map being injective (the comment's argument does rely on that). Any 4-id multiset that omits the guard has ≤3 distinct tools ⇒ ≤3 distinct events ⇒ refused. QA matrix rows 2, 3 and 4 are all closed by one gate. Unknown ids remain caught upstream by `event <bogus>` → spec exit 2 → `spec_fail` → exit 4 (`sh:186` / `.ps1:223`).

The emitter is untouched: bash body assembly `:236-263`, PS `:285-310`; both sit *below* the new gate and read `n_wired`/`$nWired`, whose value on any run reaching them was 4 before and is forced to 4 now. **Byte-identity of the happy path is a structural necessity, not a coincidence** — same argument as round 2 §3, and it still holds. (The sha256 match is **[unverifiable-here]**.)

Residual, and it is narrower than r-6 was: if `hook-spec` ever gained a **fifth** tool with a fifth distinct event, a 4-id answer omitting the guard could satisfy `n_distinct == 4`, get written, then fail step 7 (`sh:285` / `.ps1:341`) → exit 5 with a guardless file present → §8 row 3 blesses run 2 at exit 0. That needs an *addition* to the spec, not a degradation of it — strictly more contrived than QA's r-6, and NFR-2 is unaffected (the guard is absent from the settings file, not fail-open). Filed **n-10**, record-only.

### B. The three self-found defects — all three verified

1. **FC-1 regression he caused and fixed.** Re-run by me, not inherited: `Grep 'guard-rm'` over `**/install-hooks.{sh,ps1}` → **0 matches, 0 files**, across all four installers. Neither new comment block carries the token ("the destructive-command guard" at `sh:202,208` / `.ps1:241,247`). FC-1 clean.
2. **The `-join` precedence defect in QA's handed PS form — claim CORRECT.** PowerShell's documented precedence puts the *binary* `-split -join -is -isnot -as -replace` family in the comparison-operator group, **below** `+`/`-` (only the *unary* forms are high-precedence). So `"…" + $n + ": " + ($wired | …) -join ' ' + ")"` re-associates to `("…" + $n + ": " + $wired) -join (' ' + ")")` — left operand collapses to a single string via string+array coercion, `-join` on one element returns it unchanged, and the result is silently wrong with **no error**. Exactly the T-12 PS-idiom hazard class. The rebuild at `.ps1:258` — `Stop-OnSpecFailure ('tools (expected 4 DISTINCT hook events, got {0}: {1})' -f $nDistinct, $eventList)` with `$eventList` computed on its own line at `:257` — is correct: `-f` binds *above* `+`, the array right-operand form is the standard idiom, and it is parenthesized anyway. **Finding it in a handed-over form rather than copying it is the right behaviour and I want it on the record.**
3. **The `Out-String` point.** `test-init.ps1:1215` is `@(& pwsh … 2>&1 | ForEach-Object { [string]$_ }) -join "`n"`. Correct on three counts: `Out-String` would re-wrap at the host buffer width and could split `expected 4 ids, got 3`; the `[string]$_` cast is needed because `2>&1` on a native command yields `ErrorRecord`s; and `$LASTEXITCODE` (captured at `:1216`) survives the pipeline and the join. The `@(…) -join` precedence here is unambiguous (no `+` in the expression).

### C. r-2 — non-vacuous by construction, and both directional claims are supported by the source

`test-init.sh:991-993`:
```
( cd "$tmp" && bash "$inst" > "$tmp/fc4.out" 2>&1 ); rc=$?
ok=0; [[ $rc -eq 4 && ! -f "$localset" ]] && grep -qF -- 'expected 4 ids, got 3' "$tmp/fc4.out" && ok=1
```
`test-init.ps1:1215-1220` is the ordinal-`IndexOf` twin, same conjunction, same row position (7 of 8), one `assert`/`Assert` each — **assertion count unmoved**, consistent with 354/390 not moving.

- *Broken stub* → installer exits 4 via `spec_fail "tools"` (`sh:178`), whose stderr is `Hook wiring spec did not answer: tools` — the grep misses → red. Supports the reported 389/1.
- *Arity reverted to `> 0`* → three ids now fall through to the **distinct** gate, which refuses with `expected 4 DISTINCT hook events, got 3: …`. Exit is still 4 and the file still absent, so the old assertion would have stayed green — but the grep for `expected 4 ids, got 3` misses → red. The anti-revert property survives *because* it is now carried by the diagnostic, exactly as the dev doc states. Supports the second 389/1.

Both claims are internally consistent with the source; the runs themselves are **[unverifiable-here]** and QA re-ran the same two mutations.

`set -e` interaction checked: the failing `grep` is not the command following the final `&&`, so it cannot abort the driver (and QA's 389/1 captures confirm the driver still reaches its summary).

### D. n-6 — closed

Exit-code header now distinguishes the two exit-5 sub-paths at `:31-35` in **all four** installer files (verified by reading each). `CHANGELOG.md:29-33` carries the same correction *and* now names the distinct-events refusal in the exit-4 description — the live release claim is no longer false, and it is T-13's own `## [0.45.0]` section, not a historical heading.

### E. Regression surface

| Check | Result |
|---|---|
| `baseline.json` numeric keys | **No numeric key moved** — `verify_all_checks` 32, `test_init_ps_assertions` 316, bash 354, 90/90/49/45/58/58/89/89/39/39 all as pinned (`:10-22`) |
| Eighth operator item | **Present and accurate** in both places — `04_DEVELOPMENT.md:380-387` and `baseline.json:_qa_note_t13` ("EIGHTH BINDING OPERATOR CHECK"). Cites the right gate (`install-hooks.ps1:245-259`), the right row (`test-init.ps1:1190-1222`), the `-Unique` case-insensitivity, the `-f`/`-join` hazard, and correctly upgrades QA's *conditional* 8th to unconditional |
| Frozen README badges | `README.md:5` and `README.zh-CN.md:5` both still `verify__all-32%2F32` + `test--init-316%2F316`; only `version-0.45.0-blue` differs from HEAD |
| Check count 32 | No `verify_all.*` file is in the round-2 change set; baseline key still 32; both badges unmoved. The 32/0/0 re-capture is **[unverifiable-here]** |
| `docs/tasks.md` | Untouched. r-5 remains open, PM-owned |
| Design §8 row 3 | `02_SOLUTION_DESIGN.md:242` unchanged; §10 FC-4 (`:358-360`) unchanged |
| Doc size | `04_DEVELOPMENT.md` last content line is 500 — at the `70-doc-size.md:30` cap, not over |
| Citation spot-check | 15+ citations verified exact; 3 classes stale (n-8, n-9, r-7) |

### F. FC-1…FC-4 and NFR-2

- **FC-1** — re-run by me: zero hits ×4 files.
- **FC-2** — undisturbed; the new gate performs no substitution on any command value, and the value still reaches the body by plain expansion (`sh:255` / `.ps1:303`) and is compared unmodified (`sh:293` / `.ps1:356`).
- **FC-3** — `hook-spec.{sh,ps1}` and `guard-rm.{sh,ps1}` are not in this round's change set; the guard's byte-form is still asserted on **live output** every run by `test-init.sh:804-807`.
- **FC-4** — now enforced on both axes (ids, then events), both through exit 4, both before any write. The degradation matrix has **no row where a partial or guardless wiring exits 0**, and no row where a missing guard exits 0.

**Judgment on the NFR-2 abstention: sound, not a gap.** The 6×10 probe drives the guard *command string parsed out of the generated file*. Three independent facts make re-measurement unnecessary rather than merely inconvenient: (1) neither `guard-rm.*` nor `hook-spec.*` is in the change set; (2) the generated file's bytes are structurally forced to be unchanged (§A); (3) the guard byte-form is re-measured **in-suite on live output** by `[T-13][B]`, which was re-run green this round. The developer stating the abstention explicitly rather than implying coverage is the correct disclosure. No gap.

---

## Findings (round 3 — new only)

### CRITICAL / MAJOR
*(none)*

### MINOR

- **r-7 [DOC / OPERATOR] `baseline.json:_qa_note_t13`, check (a)** — still cites `test-init.ps1:1073,1120,1161,1180,**1207,1216**`; the actual `& pwsh … 2>&1` sites are `…,**1215,1225**` (the round-2 insertion shifted the last two). `04_DEVELOPMENT.md:367` *was* corrected; its baseline mirror was not. This matters more than the usual citation nit because `_qa_note_t13` is the artifact that physically travels to the Windows operator, and the fix is one string. **Owner: developer (stage 4).**

### NIT

- **n-8 [DOC] `04_DEVELOPMENT.md:404`** — "Rebuilt with `-f`, the file's existing idiom (`.ps1:347`)": the file's only pre-existing `-f` is `install-hooks.ps1:365`; `:347` is the step-7 `for` header. **Owner: developer.**
- **n-9 [DOC] `04_DEVELOPMENT.md` "Implemented, mapped to FR / AC"** — three rows carry pre-rework ranges in both shells ("Generated file", "Temp-then-rename", "Report"). Carried from rework 1, **not** newly introduced by this round. **Owner: developer.**
- **n-10 [LOGIC — residual bound] `install-hooks.sh:213-214` / `.ps1:255-259`** — the gate's closure of r-6 depends on `hook-spec` having exactly four tools. A future fifth tool with a fifth distinct event would let a guardless 4-id answer pass the gate. Requires *adding* to the spec, not degrading it. Record as a known bound in `07_DELIVERY.md`. **Owner: developer (record) / solution-architect (if a fifth tool is ever specced).**
- **n-11 [PARITY] `install-hooks.sh:213` vs `.ps1:255`** — `sort -u` is case-sensitive, `Sort-Object -Unique` is not, so on a *mutated* spec answering e.g. `Stop`/`stop` the PS twin refuses and the bash twin proceeds. Only reachable on a rewritten spec, and only in the stricter direction on PS. Correctly disclosed in the code comment and the operator note; record-only.
- **n-12 [TEST — accepted decline]** the distinct-events gate has **no in-suite regression row**, declined by the frozen-assertion-count mandate and covered out-of-suite by the 7-row matrix. I accept the decline as correctly reasoned and correctly recorded. A later task wanting in-suite coverage adds one row per twin and moves the baseline **from a capture**.

### Carried, unchanged
**r-3** and **r-4** remain binding operator items 6 and 7; **r-5** (`docs/tasks.md`) remains **PM-owned**. Operator list is now correctly **eight** items.

## Axis status (round 3)

- **Standards-conformance — 4 findings, worst = MINOR** (r-7; n-8, n-9, n-11). No `.claude/` hand-edit, no red-line file touched, doc cap respected (500), byte-mirror discipline intact — all four installer halves line-for-line coincident at `205/213-214` and `244/255-259` and at the `:31-35` header — both frozen README badges unmoved, no numeric baseline key moved, check count still 32, `docs/tasks.md` untouched, `insight-index.md` untouched, cross-shell parity preserved on every round-2 edit including the test rows. The PS `-join` and `Out-String` fixes are the repo's own hazard classes handled correctly rather than copied.
- **Spec/design-fidelity — 2 findings, worst = NIT** (n-10, n-12; plus carried r-5, PM-owned). §8 row 3 is untouched, §10 FC-4 is now enforced on the axis its letter names, the refusal precedes every filesystem effect so the r-6 residue cannot exist, r-2 is non-vacuous by construction in both directions, and the happy path's bytes are structurally forced to be unchanged.
- **Aggregate** = the more severe = **MINOR**.

---

## Verdict (round 3)

### **APPROVED WITH NITS** (0 CRITICAL, 0 MAJOR, 1 new MINOR, 5 NIT; carried: r-3/r-4 operator, r-5 PM)

The r-6 shape PM routed this back for is genuinely closed, and closed the right way: the refusal happens **before** the write in both shells and all four mirror halves, so the guardless residue never comes into existence and §8 row 3 — which must not change, and did not — never gets the chance to bless it. Both gates route through the design's `exit 4`. The closure is in fact stronger than the developer's own comment argues, and it holds without assuming the event map is injective. r-2 is non-vacuous by construction with the anti-revert property preserved, n-6 is corrected in all four headers **and** in the live CHANGELOG claim that repeated it, and the two PS defects he found in the handed-over form are both real — I verified the `-join`/`+` precedence claim against PowerShell's documented operator precedence and it is exactly as stated, including the silent no-error failure mode. Declining to re-run the 6×10 NFR-2 probe is sound, not a gap, and is backed by an in-suite live-output assertion that did re-run.

**Owner = developer (stage 4), non-blocking:** r-7 (one stale operator-site string in `baseline.json`), n-8, n-9 (citation hygiene); record n-10, n-11, n-12 as known bounds; carry the **eight** binding NFR-5 operator items verbatim, the DEV-8 scope grant, and the tally-fabrication second-occurrence insight into `07_DELIVERY.md`.

**Owner = PM:** r-5 — `docs/tasks.md` active row.

**Owner = solution-architect:** nothing. No drift attributable to the design in any round.

No `BLOCKED: NEEDS-HUMAN` item arises. The only human-reserved work remains the already-booked NFR-5 PowerShell operator run, now carrying **eight** items.
