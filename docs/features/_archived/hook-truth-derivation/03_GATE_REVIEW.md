# 03 — Gate Review · T-16 `hook-truth-derivation`

> **Provenance note (PM)**: the gate-reviewer agent is read-only by contract (Read/Glob/Grep — no Write tool). It returned this report as its reply; PM persisted it verbatim at this path.
>
> **This is Round 2 and it supersedes Round 1 in full.** The round-1 report (CHANGES REQUIRED, findings F-1 … F-11) is historically accurate but no longer the operative verdict. Where round 1 and this document disagree — and there are two places, both adjudicated in §3 below — **this document governs**. Round 1's finding index is retained in the appendix; its resolutions are recorded in `02_SOLUTION_DESIGN.md §18` and in `PM_LOG.md`.

- **Mode**: `full` (stages 1-7), dispatched from a `/harness-stream` drain. Verdict vocabulary per the round-2 dispatch; the full-mode routing equivalent is stated at the end.
- **Inputs audited**: `01_REQUIREMENT_ANALYSIS.md` (READY, unchanged since round 1), `02_SOLUTION_DESIGN.md` (READY, revised in place, new `§18`).
- **Method**: `§18`'s closure claims were **not** accepted as evidence. Every one of F-1 … F-11 was re-verified against the real files. The three new autonomous calls (D-5, D-6, D-7), which no gate round has seen, were audited from scratch. The `resilient_cmd` / `Get-ResilientCmd` mention set was re-swept repo-wide, because a *retirement* changes which files mention a symbol.
- **deferred-human**: defer, do not ask. Mode 2 (balanced). No human-reserved point arose.

---

## 1. Audit checklist (8 dimensions)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | Unchanged and unedited. Every AC remains falsifiable; AC-4's split-host proof is now owned end-to-end (operator items 12(f)/13(e)). |
| 2 | Design completeness | **PASS** | The three round-1 under-specifications are closed at the mechanism level, not patched: resolution is lazy (F-1), the skip boundary is a named line range (F-4), the cache loop uses an explicit counter (F-5). The PS side now defines every function its own interface names. |
| 3 | Reuse correctness | **PASS** | Every reuse target re-read and still valid. `install-hooks.ps1:190-199` exists with the cited shape, and the design's two additions to it (`$global:LASTEXITCODE = 1` in the `catch`; `@($out) \| Select-Object -First 1`) close two real gaps in the precedent rather than inventing a pattern. `hs_expected <tool> <os>` exists at `test-init.sh:62-74` with the argument order the new probe uses. |
| 4 | Risk coverage | **PASS** | R-1 … R-11 are the real risks. R-3 now predicts the true pre-repair symptom, and R-11/RES-1 records the one coverage loss this change causes. |
| 5 | Migration safety | **PASS** | No data migration; no flag needed. The one new on-disk artifact (`verify_all.s0.sh`) is placed correctly and deleted in the same step — see §6. |
| 6 | Boundary handling | **PASS** | The containment-window rule is now **total** over arbitrary text input, verified by construction and against the real template (§3). The degradation matrix is total and quantified (4+1+8+8). |
| 7 | Test feasibility | **PASS** | The round-1 FAIL is cleared: no pre-change claim in this task now derives from `git show HEAD:`, and admissibility of each S0 capture is asserted from both directions (hash + `mtime < T0`, **and** the live file must hash differently at proof time). |
| 8 | Out-of-scope clarity | **PASS** | Eleven exclusions, now including RES-1. The "improving while in there" clause survives the rework — and D-5, the one change that *is* a "while I was in there" edit, is justified by the deletion test rather than by convenience (§4). |

No dimension is WARN or FAIL. Two new findings exist (§7); both are corrections to written claims, not to mechanisms, and neither moves a dimension off PASS.

---

## 2. Closure of F-1 … F-11 — verified against code, not against §18

| # | Claim | Verified how | Status |
|---|---|---|---|
| **F-1** | Lazy resolution removes the binding-order constraint in all four files | Re-measured every cell myself. `upgrade-project.sh`: helper `:93-117`, `template_common_scripts` `:56`, **`dst_dir` `:150`**, first call `:282`. `upgrade-project.ps1`: helper `:102-126`, `$templateCommonScripts` `:67`, `$dstDir` `:147`, first call `:286`. `migrate-scripts-layout.sh`: helper `:112-131`, `dst_dir` `:40`, call `:193`. `migrate-scripts-layout.ps1`: helper block **`:31-50`**, `$root` `:53`, **`$dstDir` `:56`**, call `:168`. In all four, first *call* is after every binding the candidate list reads. The block genuinely reads no flow variable at definition time. | **CLOSED** |
| | PS side implementable without invention | `Resolve-HookSpecPath`, `Get-HookSpecPathForMessage`, `Invoke-HookSpecCached`, `Get-HookSpecCommand`, `Get-HookSpecHostOs` are all now **defined**, not merely named. The dangling `$hsCacheOk` is gone. `Set-StrictMode` appears **nowhere in this repository** (repo-wide search: the only hit is the design document itself), so `if ($dstDir)` on an undefined variable is `$null`→false, not an error — the design's stated premise is true. | **CLOSED** |
| **F-2** | `git show HEAD:` eliminated everywhere | Rule 2 at the head of `§11` binds C-1, C-3, C-4 **and** `§7.2` to S0 working-tree captures. I re-read `§7.2`, `§11 C-1/C-3/C-4` and `§14`'s anti-vacuity row: no `git show HEAD:` survives as a *source*; the only remaining use is `git diff --stat HEAD -- <path>`, explicitly labelled corroboration, not proof. | **CLOSED** |
| | "This capture is the pre-change state" is *provable*, not asserted | Two-sided: (a) hash equals the S0 table entry **and** S0 mtime `< T0` — this reuses `§13`'s own method rather than inventing a second provenance rule; (b) at proof time the **live** `verify_all.sh` must hash *differently*, which is the direction that catches "the pre-change copy is actually the post-change file". That converse check is what makes it a proof rather than a convention. Placement is correct: `verify_all.sh:5-7` is `repo_root="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$repo_root"`, so the copy must be exactly two levels below the root, which `.harness/scripts/verify_all.s0.sh` is. | **CLOSED** |
| **F-3** | Terminator rule is total | Re-derived over the input domain (§3 below). | **CLOSED** |
| **F-4** | `ph_o`/`ph_c` hoist restores exit 4 | `upgrade-project.sh:248-250` is `settings="$root/.claude/settings.json"` / `settings_new=""` / `if [[ ! -f "$settings" ]]`. The design's target ("immediately after `settings_new=""` (`:249`) and before the `if`") is a real, unambiguous insertion point at S3 scope, and it makes bash structurally identical to `upgrade-project.ps1:250-256`. With `ph_o` bound at S3 scope, `:607`'s `[[ "$cmd_line" == *"$ph_o"* ]]` cannot hit an unbound variable, so the branch reaches the terminal scan and exits 4 as `§5` row 2 predicts. Part 2 ("skip means skip the `:275-287` loop") is also correct: `ph_names`/`ph_tools` are read only inside `:273-287`. | **CLOSED** |
| **F-5** | No `[@]` expansion of a possibly-empty array on any path | Two sites, both closed structurally rather than guarded: the cache scan is `for (( i = 0; i < hsa_n; i++ ))` over an explicit counter — no array expansion at all; `cands` receives the sibling candidate **unconditionally**, so `"${cands[@]}"` is provably non-empty. I looked for a third: there is none — `hsa_keys[$hsa_n]="$k"` is an assignment, and `${hsa_keys[$i]}` is a single-element read inside the bound. | **CLOSED** |
| **F-6** | The two standing 4-row scans are real | Both are real and both would redden on a real regression — see §7 F-12 for a correction to the design's *characterisation* of their pre-change state. | **CLOSED, with F-12** |
| | RES-1 reaches `07_DELIVERY.md` | Named in three places that all travel: `§16 R-11`, `§16.1 RES-1` ("these must reach `07_DELIVERY.md`"), `§17.11`. Its measurement is accurate — I re-read `test-harness-upgrade.sh:288-309` (`t20_pick`, host-OS-conditional, `harness-sync` only) and `:421`, and it is indeed the single standing flow-emitted-vs-independent-literal assertion. | **CLOSED** |
| **F-7** | Operator register restated correctly | The two registers are now separated in a table: **11** numbered (10 from T-17 `guard-cmd-chain`, items 3 and 10 security; 1 from T-15) + **8** un-numbered T-13 prose obligations in `baseline.json:_qa_note_t13` = **19**; this task appends items 12-16 → **16** numbered (4 security), **24** total. `01 AC-10` keys on "eleven items, two marked security" — the numbered figure — and `§12` states the mapping **11 → 16** explicitly. Internally consistent, and consistent with AC-10. | **CLOSED** |
| | `60-tool-handoff.md` = 128 | Re-measured two independent ways: a line-count scan returns **128**, and a tail read shows the last content line is 128. `75-safety-hook.md` = **200**, `AI-GUIDE.md` = **113** — both match the design. The correction 129 → 128 is right. | **CLOSED** |
| **F-8** | Pre-repair symptom stated once, correctly | `test-init.sh:771`'s awk range is `/^resilient_cmd\(\) \{$/ … /^\}$/`; `:772` calls the extracted body; `:774` is the probe; `:776-785` is Group A. `§8` and `R-3` now both say **9 loud red rows**, with the tautology retained only as the counterfactual. No self-contradiction remains. | **CLOSED** |
| **F-9** | PS call-site contradiction removed at the root | `upgrade-project.ps1:278` is `if ($IsWindows)` and `:286` is `Get-ResilientCmd $ph.Tool $IsWindows` — both confirmed on the file. `§3.5` now carries both as explicit rows, and D-5 removes the positional-automatic problem rather than patching the argument. | **CLOSED** |
| **F-10** | Mandate and check now have the same width | `§4` names all five shapes; `§11 C-7`'s pattern `\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?/` matches all of them. I ran that exact pattern over the four flow files: **2 hits, both comment lines** (`upgrade-project.sh:120`, `migrate-scripts-layout.sh:135`) — no false positives on `${dst_dir:-}`, `${dst_dir}/…`, `${#arr[@]}` or `${var##*/}`, all of which I checked against the pattern. `-replace`: **0 hits** in either `.ps1`. | **CLOSED** |
| **F-11** | AC-4's Windows runtime half is owned | Operator items **12(f)** and **13(e)** carry the exact probe on the **flow-written** settings file, with `test-harness-upgrade.ps1:599-608` cited as corroborating precedent and explicitly *not* as a substitute. That distinction is the correct one — Fixture Z probes a transcribed literal; `01 AC-4` asks for a flow-emitted one. | **CLOSED** |

---

## 3. The three adjudications the dispatch asked for

### 3.1 F-2 · "C-4 as written was impossible" — **the architect is right on the fact; the specific claim is unverifiable by me**

Two separable propositions.

**(a) `hook-spec.{sh,ps1}` does not exist at HEAD.** Confirmed as far as this toolset allows, and from independent directions: `CHANGELOG.md:8` is `## [0.46.0]` with 0.45.0 (T-13, which created the spec) below it, while HEAD is `cb0ed57 feat(v0.44.0)`; `verify_all.sh:284`'s F.1 pair list includes `hook-spec`, an entry T-13 added; `verify_all.sh:290` carries T-15's `(v0.15+; narrowed T-15)` annotation. So any comparison one of whose sides is `hook-spec.*` **at HEAD** has an empty side. That premise holds.

**(b) Round-1 C-4 sourced *both* sides from HEAD.** I cannot verify this. `02_SOLUTION_DESIGN.md` was revised **in place**, the round-1 text is uncommitted and no copy survives anywhere in the tree (`PM_LOG.md`'s stage-2 round-1 entry does not quote C-4). My own round-1 wording — "the byte-forms in `upgrade-project.sh` and `SKILL.md:187-190` have not moved since T-12" — describes only the *SKILL.md* side, and is silent on the spec side.

**Adjudication.** On substance the architect wins either way, and I say so plainly: if C-4's spec side came from HEAD, it was impossible; if it came from the working tree, it rested on precisely the untested tree-state assumption `§13` forbids inheriting, which my round-1 "probably safe" explicitly flagged as a guess rather than a measurement. Rule 2 is strictly stronger than either patch and is the correct resolution. **My round-1 "probably safe" characterisation is withdrawn** — it was an unverified inference and should not have been offered even hedged. The architect was right to refuse to inherit it. The one thing I will not do is certify the narrower claim about the round-1 text, and `04_DEVELOPMENT.md` should not cite this review as having done so.

### 3.2 F-3 · totality of the new rule, and the §3.5 claim about my round-1 reading

**The terminator rule is total.** Over `L[0…N-1]`: step 1 partitions the input two ways (a key-form line exists, or it does not) and the "does not" branch emits exactly one token with no window computed; on the other branch `IND` is defined for any line, and step 3 either finds a least `j > start` satisfying "non-blank ∧ width ≤ IND" or it does not, with `term = N` on the latter. Step 4's window `[start, term-1]` is non-empty because `term ≥ start+1`. Step 5 keeps rows 4-5 evaluated on the `term = N` branch, so the emitted token set is a **function** of the input — no input maps to "undefined". `≤ IND` (rather than `= IND`) is what makes step 3 total; excluding the terminator line is an independent tightening that I did not ask for and that is correct: it stops an inline sibling event at width `IND` from satisfying `PreToolUse_no_command_entry` with evidence that is not `PreToolUse`'s.

**The three-row table re-verified against the real `settings.json.tmpl`.** Row 1: key at `:48`, `IND = 4`; `:49-57` have widths 6,8,8,10,12,12,10,8,6 — none ≤ 4; `:58` is `    ],` at width 4 → `term = 58`, window `[48,57]`, containing `"command"` at `:53` and `{{GUARD_COMMAND}}` at `:54` → **PASS**. Row 2 (M-C): next non-blank line at width ≤ 4 is `    "UserPromptSubmit": [` → window is the single mutated line → no `"command"`, no placeholder → **exactly two tokens**, unchanged from round 1. Row 3 (`PreToolUse` last inside `hooks`): the terminator becomes the two-space `}` closing `hooks`, the window ends at the array's `]` line, evidence stays inside → **PASS**, where the round-1 rule gave FAIL. All three rows are correct.

**On §3.5.** The architect is right and my round-1 statement was incomplete. I wrote that §3.5 was "total over the three call sites" and named `sh:282`/`ps1:286`, `sh:340`/`ps1:338`, `migrate sh:193`/`ps1:168` — which is true of `resilient_cmd`/`Get-ResilientCmd` invocations, and is **not** a totality claim over the surface `§3.5` actually has to cover, because `upgrade-project.ps1:278`'s bare `if ($IsWindows)` is a host-OS read that the change also has to move and that no `resilient_cmd` search would ever return. I confirmed both PS reads on the file. The extended five-row table is total over the real surface. **Adjudicated in the architect's favour.**

### 3.3 F-4 · "the PS twin was never broken" — **the architect is right; my round-1 note was wrong**

`upgrade-project.ps1:250-256` reads: `$settings = …` (`:250`), `$new = $null` (`:251`), the two-line assembly comment (`:252-253`), `$phOpen = "{" + "{"` (`:254`), `$phClose = "}" + "}"` (`:255`), then `if (-not (Test-Path $settings))` (`:256`). S3.0 does not begin until `:262`. **`$phOpen` is at S3 scope, outside S3.0 and outside the settings-absent branch.** My round-1 sentence "the PS twin has the same shape" was a false symmetry assumption of exactly the class this repo keeps recording — and it was the *unsafe* direction of that error, because a developer told to "fix both shells" would have moved a correct line.

Stating it plainly: **the architect's narrowing is correct, my round-1 F-4 overreached on the PowerShell half, and the bash half stands exactly as written.** The consequent framing is also correct and materially better than what I asked for: the hoist is not an invention but an *alignment of bash onto the PS twin's existing placement*, so the edit removes a cross-shell asymmetry rather than creating one. Ledger row 3 correctly says "**minus** the `ph_o` hoist".

---

## 4. The three ungated autonomous calls

### D-5 — retiring `resilient_cmd` / `Get-ResilientCmd`

**Gated: ACCEPTED.** This is the change class I was most suspicious of, so I audited it hardest.

- **Deletion test.** After the change the helper's whole body would be `if ($forWin) { 'windows' } else { 'unix' }` fed straight into `hsa_command`. It carries no behaviour, and every call site has to change anyway (each grows a failure branch; the bash sites must stop using `$( … )`; `ps1:286` must stop passing `$IsWindows` positionally). Retaining it would be keeping a name, not a mechanism. The call is right.
- **Every call site updated in all four files.** Confirmed by repo-wide search: definitions at `upgrade-project.sh:102`, `.ps1:112`, `migrate-scripts-layout.sh:117`, `.ps1:36`; invocations at `upgrade-project.sh:282,340`, `.ps1:286,338`, `migrate-scripts-layout.sh:193`, `.ps1:168`. All eight are in `§3.5`'s table or its D-5 clause; the four `templates/common/` twins carry the identical line numbers and are covered by ledger rows 1/3/5/7 plus `sync-self` Mappings 6 and 7 (`sync-self.sh:78-84`, verified — file-by-file `sync_file` calls, not a directory scan).
- **Does retirement break a test driver that extracts the symbol by name?** This was the specific hazard, and it is handled. There are exactly **two** name-anchored extractors in the repo, and `§8` deletes both: `test-init.sh:771`'s `awk '/^resilient_cmd\(\) \{$/…'` range, and `test-init.ps1:892-898`'s `FunctionDefinitionAst`/`$_.Name -eq 'Get-ResilientCmd'` filter. I searched for a third — `test-harness-upgrade.{sh,ps1}`, `test-real-project.{sh,ps1}`, `verify_all.{sh,ps1}`, `sync-self.*` and every other driver: **none** references either symbol. No frozen count is put at risk by the retirement itself.
- **The frozen-count question.** `§8`'s "17 rows in, 17 out" is arithmetically right and structurally verified against the artifact's source: `test-init.sh` `:774` (probe, 1) + `:776-785` (Group A, 8) + `:788-795` (Group A′, 8) = 17, with `:767`'s `[T-13] hook-spec.sh present` untouched and correctly excluded. `test-init.ps1` `:905` (probe, 1) + `:920` (A) + `:924` (A′) × 8 cells = 17, with `:928`'s Group C — the third `Assert` in the `:909-936` per-cell loop — untouched. Lifting A′ out leaves the loop at 2 × 8 = 16 and adds a separate 8-row block: 24 either way. So `test_init_bash_no_python3_assertions = 355` and `test_init_ps_assertions = 316` both hold **by structure**. See §8 for why that is not the same thing as a measurement.

### D-6 — the out-variable convention

**Gated: ACCEPTED, and the justification is correct.** The spawn arithmetic checks out: without a surviving cache, `upgrade-project` issues 4 S3.0 calls + 8 S3.2 calls + 1 `hostos` = **13**; with the cache, at most 8 distinct `(tool, os)` command keys + 1 `hostos` = **9**. Under bash, `x="$(hsa_command …)"` forks a subshell and every `hsa_keys`/`hsa_n` write is discarded in the child — the cache would silently never fill. That is a real defect that neither round-1 document nor my round-1 review caught, and the design is right to name it as forced rather than preferred.

Correctness under `set -uo pipefail` (no `-e`), checked line by line against `§3.3`:

- `if hsa_command "$tool" "$os"; then` — a function in an `if` condition; no `-e` and no abort even under `-e`. Correct.
- `v="$(bash "$hsa_bin" "$@" 2>/dev/null)"; rc=$?` — the subshell here captures only the *spec's* stdout; the cache write happens afterwards in the parent. Correct, and materially different from the forbidden shape.
- `hsa_resolve` returns 0 on every path (`{ hsa_bin="$c"; return 0; }` or the trailing `hsa_bin="-"; return 0`), and its rc is discarded by the next statement. The `[[ … ]] && …` short-circuits are never the last statement of a function, so no rc leaks. Correct.
- `return "${hsa_rcs[$i]}"` reads an index strictly below `hsa_n`, always set. Correct under `set -u`.
- `$(hsa_path)` is a pure reader and is explicitly permitted; it writes nothing.

**No emitted byte changes.** The chain is `hook-spec.sh:103-111` `printf '%s\n'` → `$( … )` strips exactly the one trailing newline → plain assignment → `str_replace_all`. `resilient_cmd`'s `printf '%s'` produced the same bytes; I compared `upgrade-project.sh:106,108,112,114` against `hook-spec.sh:103,105,109,111` and they are the same literals. The value is never re-printed with `printf "$v"`, never `echo`'d, never unquoted. On the PS side `Invoke-HookSpecCached` returns `$val` and nothing else reaches the output stream — `Resolve-HookSpecPath` returns bare, the `+=` and preference assignments emit nothing, and `$first`/`$s` are assignments. One PS subtlety the design gets right and that I flag for the operator rather than as a defect: `$script:hsCacheVal += $null` appends a `$null` **element** (it does not no-op the way `+= @()` would), which is what keeps the key and value arrays index-aligned for cached failures.

### D-7 — RES-1 as a residual rather than unfreezing `test-harness-upgrade`

**Gated: ACCEPTED.** The reasoning is sound and, more to the point, the alternative is worse: adding assertions to `test-harness-upgrade.{sh,ps1}` moves `test_harness_upgrade_ps_assertions` (89), a pin no agent on this host can reconcile — which is the phantom-count trap `baseline.json:_qa_note_t17` names in its own words ("Do not invent one"), and injecting unrunnable PowerShell into a currently-green driver is `insight-index.md:20` verbatim. It also breaks the frozen set that makes retiring Group A's live-oracle role safe in the first place, which would be circular. The residual is correctly narrow (an adapter that post-processes the captured value), correctly routed, and the follow-up's shape is stated.

---

## 5. Change-ledger re-sweep after D-5 and the round-2 additions

A retirement changes the "which files mention this symbol" set, so I re-swept the whole repository for `resilient_cmd` / `Get-ResilientCmd` / `ResilientCmd` and classified every **live** hit (excluding `docs/features/_archived/**`, `CHANGELOG.md`, `docs/tasks.md`, and the T-16 stage documents themselves).

| Live mention | Ledger disposition | OK? |
|---|---|---|
| `upgrade-project.sh:93,102` (helper) + `:265,268` (S3.0 comments), ×2 twins | rows 1-2, "in place of `resilient_cmd` (retired) … comment rewrite" | ✓ |
| `upgrade-project.ps1:102,112,286,338`, ×2 twins | rows 3-4 — and I checked for a PS analogue of the `sh:265,268` comments: there is none, `:102` is the helper's own header and dies with it | ✓ |
| `migrate-scripts-layout.sh:112,117,193`, ×2 twins | rows 5-6 | ✓ |
| `migrate-scripts-layout.ps1:31,36,168`, ×2 twins | rows 7-8 | ✓ |
| `hook-spec.sh:10` (provenance `:8-10`), `:42` (hand-off `:39-52`), `:97-98` (second provenance), ×2 twins | row 9, all three ranges named | ✓ |
| `hook-spec.ps1:9` (`:7-9`), `:41` (`:38-51`), **`:94`** (second provenance) | row 11 names **only** `:38-51` and `:7-9` | **✗ — see F-13** |
| `test-init.sh:751,771,772,774,781,783` | row 15 (`:750-760` SCOPE-NOTE rewrite + `§8`) | ✓ |
| `test-init.ps1:700,873,896,901,904,905,917,920` | row 16 (`:872-881` + `:700` comment + `§8`) — `:700` is a genuine round-2 catch, and it has **no bash twin**, verified | ✓ |
| `baseline.json:26` (`_qa_note_t12` narrating the T-12 `$isWindows` collision) | `§3.5` decoy list — historical, correctly never edited | ✓ |
| `insight-index.md:20`, `docs/tasks.md:18`, `CHANGELOG.md:127` | `§3.5` decoy list | ✓ |

**Round 2's own additions are real and were needed.** `hook-spec.sh:8-10` does say "transcribed VERBATIM from the canonical derivation helper (upgrade-project.sh `resilient_cmd`)" and `:97-98` does say "Transcribed verbatim from upgrade-project.sh:104-116"; `test-init.ps1:700` does say "matches `Get-ResilientCmd`'s output". All three name a helper that will not exist. Catching them was correct.

**The ledger is complete after one addition** — `hook-spec.ps1:94`. Round 1's independent 54-file idiom sweep (`CLAUDE_PROJECT_DIR`, `Set-Location -LiteralPath`) still stands unchanged: no lockstep surface is missing, no `sync-self` mapping needs adding, and the twin pairs are covered by Mappings 6/7/9 which I re-read at `sync-self.sh:78-93`.

---

## 6. Standing constraints re-confirmed after the rework

- **Check count 32, no `step`/`Step` added.** `verify_all.sh:301-322` accumulates into `f2_problems` and emits exactly one `step "F.2"` on each of two mutually exclusive branches; `verify_all.ps1:287-311` is one `Step "F.2"` block accumulating `$problems` and ending in `throw ($problems -join ' ')`. `§7.1` adds three tokens to those accumulators and nothing else. `baseline.json:10` = `32`, untouched. ✓
- **`guard-rm` fail-closed on every branch, including the new lazy-resolution failure paths.** There is no expression anywhere in `§3`, `§4`, `§5` that *constructs* a command string; the adapter's only source is the spec's stdout and its only alternative is "return nothing". The new failure surfaces (`hsa_bin="-"`, a skipped candidate from `${dst_dir:-}` being empty, `Join-Path` never reached because `if ($dstDir)` is false) all funnel into the same single failure return. The `hostos`-failure branch now leaves all four placeholder tokens in place and reaches `:607` with `ph_o` bound → exit 4. No branch writes a guard command; no branch leaves residue that the `$new -cne $raw` / `settings_new != settings_raw` write gate could later bless. ✓
- **`75-safety-hook.md` untouched at 200/200.** Measured: **200** lines. It is in `§13`'s frozen set, out of the edit set, and `§9`'s not-changed list says so with the right escalation rule if that ever changes. ✓
- **No cap breach anywhere.** `AI-GUIDE.md` **113**/200; largest rule fragment **200**/200 (`75-safety-hook.md`, at cap, not over); `60-tool-handoff.md` **128**/200 → ≤130 after L3; `insight-index.md` **30**/30 bullets at `:9-38`, and `archive-task.sh:59-96` genuinely rotates (`if (( total_after > 30 ))` → move the oldest to `insight-history.md`), so stage 7 does not breach `I.4` provided each new insight is **one physical line**. `verify_all` exits 1 on `warns > 0`, so all of this is hard-gate, not advisory. ✓
- **Pinned counts.** `baseline.json` re-read in full: `verify_all_checks` 32, `test_init_ps_assertions` 316, `test_init_bash_no_python3_assertions` 355, `test_real_project_{ps,bash}` 90/90, `test_harness_upgrade_{ps,bash}` 89/89, `test_guard_rm_bash` 87, `test_supervisor` 49/45, `test_verify_i6` 58/58, `test_language` 39/39. `§15` matches every one. The "17 rows in, 17 out" claim is **structurally** verified (§4, D-5) but is arithmetic, and this repo's rule — `insight-index.md` 2026-07-31, "cross-check a reported tally against **the artifact that allegedly produced it**, not against arithmetic" — forbids me from certifying it. **I cannot execute it; the claim is unverified-by-me and must be captured at stage 4** (see §8).
- **PowerShell completeness and ownership.** Every `.ps1` family in the ledger has an operator item with an exact command: `upgrade-project.ps1` → 12 (security), `migrate-scripts-layout.ps1` → 13 (security), `verify_all.ps1` → 14, `test-init.ps1` → 15, `hook-spec.ps1` + `test-real-project.ps1` + the three `templates/common/` twins → 16. `[Parser]::ParseFile` appears in all five. No `.ps1` is described as verified anywhere in the document. ✓
- **Developer feasibility (Bash only).** Every AC is dischargeable on bash or explicitly routed: AC-1 → C-5; AC-2 → C-1/C-2 (bash) and C-3 at the source-literal level + item 12(b)/13(b) for PS; AC-3 → Group A′ scan 1 + C-7; AC-4 → C-6 (unix runtime, executed) + items 12(f)/13(e) (Windows runtime, operator); AC-5 → C-2 re-run; AC-7 → the S0 pre-change run + M-C; AC-8/AC-9 → bash drivers; AC-10 → `§12`; AC-11 → `§13`. Nothing is left implicitly on the developer that they cannot run. ✓

---

## 7. New findings — introduced by the round-2 rework, not previously gated

### F-12 · MEDIUM · route to **solution-architect** (carried as a binding condition) — "both scans are green on the pre-change tree" is false for the idiom scan

`§8` states, and `§18 F-6` repeats with the words **"measured, not assumed"**: *"Both scans are green on the pre-change tree, so they are regressions rather than fixes."*

I measured it. The **substitution-discipline scan** is green: over the four flow files, the widened pattern yields **2 hits, both comment lines** (`upgrade-project.sh:120`, `migrate-scripts-layout.sh:135`), and `-replace` yields **0** in either `.ps1`. That row is a true regression.

The **idiom scan is red pre-change on all four files** — 16 non-comment hits:

- `upgrade-project.sh:106,108,112,114`
- `upgrade-project.ps1:115,117,121,123`
- `migrate-scripts-layout.sh:121,123,127,129`
- `migrate-scripts-layout.ps1:39,41,45,47`

The design's own supporting sentence concedes this — it says the idioms "appear on non-comment lines today only inside the `resilient_cmd` / `Get-ResilientCmd` bodies **this change deletes**" — which is a statement that the hits *exist today*. Green-after-red is exactly what an AC-3 assertion should be; the scan is correct and desirable. What is wrong is the *claim about its pre-change state*, asserted as measured in a document whose entire discipline is "measure, don't assume", and in the one place where this repo has repeatedly shipped a fabricated-but-plausible claim.

Why it matters operationally: a developer who adds the A′ block before deleting the helper bodies sees 4 red rows and may "repair" the scan (add an exclusion, narrow the file set) rather than recognising an unfinished edit. `04_DEVELOPMENT.md` and `06_TEST_REPORT.md` must not transcribe the sentence as written.

### F-13 · MINOR · route to **solution-architect** (carried as a binding condition) — ledger row 11 omits `hook-spec.ps1:94`, the PS twin of the `sh:97-98` provenance sentence round 2 just added

`hook-spec.sh:97-98` reads *"The four literal shapes. Transcribed verbatim from upgrade-project.sh:104-116 — do not retype them…"* and is correctly added to ledger row 9. Its exact twin, `hook-spec.ps1:94` — *"The four literal shapes. Transcribed verbatim from upgrade-project.ps1:113-125"* — is **not** in row 11, which names only `:38-51` and `:7-9`.

Consequence: after the change, both `hook-spec.ps1` copies would still cite a line range in `upgrade-project.ps1` that no longer contains `Get-ResilientCmd`, in the one file whose entire job is being the single source of truth about those bytes. It is comment-only and breaks no gate, but it is a **lockstep-surface omission in a ledger** — this repo's most frequent gate failure — and it is a cross-shell asymmetry introduced *inside the fix for a cross-shell asymmetry*, which is the "audit siblings as a pair, the divergence is the bug signal" insight (`insight-index.md`, 2026-06-11) applied to a comment.

### Record-only observations (no action required beyond noting them)

- **R-1.** `§7.1` step 1 specifies the key-form matcher as `^[[:space:]]*"PreToolUse"[[:space:]]*:` in bash and `^[ \t]*"PreToolUse"[ \t]*:` in PowerShell — two different whitespace classes, in a section that elsewhere correctly insists on `[ \t]` in both shells for the *width* measurement. The bash form is preservation (`verify_all.sh:314` uses `[[:space:]]` today) and divergence requires a form-feed or vertical tab in the leading whitespace of a JSON key line, so this is unreachable in practice. Recorded because it is the same deviation family T-15 logged, and because the design recorded the tab/space edge but not this one.
- **R-2.** `01 NFR-1` says spec invocations are "bounded above by **8** per run"; the design says "**≤ 9** … (8 command keys + 1 hostos)" and twice attributes the ceiling of 9 to NFR-1. The 9th is `hostos`, which D-1 adds and NFR-1 does not contemplate; D-1 discloses the cost. No requirement is violated, but the attribution is loose.
- **R-3.** `§3.1` names `hsa_path` / `$script:hsSpecPath` as the diagnostic reader; `§3.4` defines the PS reader as `Get-HookSpecPathForMessage`. Cosmetic; the call shape in `§3.4` uses the right name.
- **R-4.** `hook-spec.sh:47`'s existing hand-off list cites `test-init.sh:46-59` for the `EXP_*` fixtures; the true extent is `:53-60` for the literals and `:62-74` for `hs_expected`. `§9.1` replaces that whole list, so the developer should not transcribe the stale range forward.
- **R-5.** `§7.1` step 1 takes the **first** matching key line. A template with two `"PreToolUse"` keys (invalid JSON) whose evidence lives in the second would FAIL — deterministic and conservative, i.e. the right direction, but unnamed in the rule.
- **R-6.** The new anti-vacuity probe (`hs_expected guard-rm windows` non-empty and contains `guard-rm.ps1`) is genuinely weaker than the retired call-through probe: it no longer proves an extraction worked. That is acceptable because the failure it used to guard is now loud by construction — Group A compares the spec against the same fixture, so an empty fixture reddens 8 rows rather than passing 8 vacuously. Verified the fixture is real: `EXP_WIN_GUARD` at `test-init.sh:54` is non-empty and contains `guard-rm.ps1`.

---

## 8. What I could verify only by inspection — the developer must capture these empirically

I have Read/Glob/Grep and no execution. Every item below is *consistent* with the artifacts I read and *not* measured by me. None may be reported as verified on the strength of this review.

1. **`bash .harness/scripts/test-init.sh` → `PASS: 355`.** The 17-in/17-out claim is structural. Per `insight-index.md` (2026-07-31), a tally is cross-checked against the artifact that produced it, never against arithmetic. Capture the `=== Result ===` line; a run that terminates without it is a failure, not a pass.
2. **`bash .harness/scripts/verify_all.sh` → `PASS 32 / WARN 0 / FAIL 0`**, with the check count read from the run, not from `baseline.json`.
3. **M-C's exactly-two-token prediction** on the post-change gate, and **`PASS 31 / WARN 0 / FAIL 1`** whole-gate.
4. **The pre-change `[F.2]` PASS on M-C**, from the S0 capture, with both admissibility assertions recorded: S0 hash + `mtime < T0`, and the live file hashing *differently* at proof time. My round-1 hand-trace of `verify_all.sh:313-314` over M-C is a trace, not a run.
5. **`test-harness-upgrade.{sh,ps1}` staying 89/89**, and `test-real-project` 90/90, from real runs. My round-1 fixture-reachability analysis (every fixture reaches resolution candidate 1) is still the right prediction under lazy resolution, but it is a prediction.
6. **The four `.harness/scripts/` flow files returning 0 non-comment hits for both A′ scans *after* the change** — and, per F-12, the correct pre-change baseline of **16 idiom hits / 0 substitution hits**.
7. **Everything PowerShell**, without exception — the five operator items are the only evidence path.
8. **HEAD's contents.** I have no git access. "`hook-spec.{sh,ps1}` does not exist at HEAD" is corroborated by `CHANGELOG.md`, the `cb0ed57 feat(v0.44.0)` commit subject, and T-13-era lines in `verify_all.sh`, but it is not a `git show`. The developer re-derives S0 at task start and inherits neither this nor the session snapshot's "clean tree" claim.

---

## 9. High-probability developer questions — pre-answered

**Q1. Where does the adapter block go?**
Exactly where the retired helper sits, in all four files: `upgrade-project.sh:93-117`, `.ps1:102-126`, `migrate-scripts-layout.sh:112-131`, `.ps1:31-50`. It defines functions and inert scalars only and reads no flow variable at definition time. Round 1's placement question is resolved — do not "improve" it by hoisting the block downward.

**Q2. In what order do I make the edits so nothing goes transiently red for the wrong reason?**
Flow files first (delete the helper bodies, add the adapter, rewire the call sites), `test-init` second. If you do it the other way round you will see **13 red rows** in `test-init.sh` — 9 from the still-live oracle path (probe + Group A) and 4 from the new idiom scan hitting the helper bodies that are still present. That is the expected intermediate state, not a defect, and it is the point `§8`'s "both scans are green pre-change" gets wrong (F-12).

**Q3. Why must I never write `x="$(hsa_command …)"`?**
The cache lives in shell variables; a command substitution forks a subshell and every write to `hsa_keys`/`hsa_vals`/`hsa_n` dies with it, so each of the 12 call-site invocations re-spawns the spec — 13 spawns instead of 9. `$(hsa_path)` is fine; it is a pure reader. This is D-6 and it is forced, not stylistic.

**Q4. Which `verify_all.sh` is "the pre-change gate"?**
The S0 capture of the **working tree**, taken before your first write. Never `git show HEAD:` — HEAD on this tree is v0.44.0, predates `hook-spec.*` entirely, and predates T-15's key-form anchoring in the very check you are modifying. Place the copy at `.harness/scripts/verify_all.s0.sh` (it derives `repo_root` from `dirname "$0"/../..` — verified at `verify_all.sh:5-7`), run it, capture the `[F.2]` line, delete it immediately. Nothing enumerates `.harness/scripts/` — `F.1` is a fixed pair list at `verify_all.sh:284` and `sync-self` is file-by-file — so the transient file breaks no check, but do not leave it for `git status` at S-final.

**Q5. Do I need to hoist `$phOpen` in the PowerShell twin too?**
**No.** `upgrade-project.ps1:254` is already at S3 scope, outside S3.0 and outside the `if (-not (Test-Path $settings))` branch. Only bash's `ph_o`/`ph_c` at `:270` move, to just after `settings_new=""` (`:249`). Moving the PS line would create the asymmetry this edit exists to remove. (Round 1 said otherwise; round 1 was wrong — see §3.3.)

**Q6. What is the pre-repair symptom in `test-init`?**
**9 loud red rows**, not a green tautology: the awk range at `:771` extracts the delegating body, which calls `hsa_command` — undefined in the driver's scope — so `$probe` is empty, `:774` reddens, and Group A's `$b` is empty so all 8 rows redden. In PowerShell, `Get-ResilientCmd` is retired, `$fnAst` is `$null`, the call throws, `catch` empties the probe, same 9 rows.

**Q7. Will the widened C-7 grep false-positive on my own adapter?**
No. I checked the pattern against every expansion the adapter uses: `${dst_dir:-}`, `${template_common_scripts:-}`, `${hsa_keys[$i]}`, `${hsa_vals[$i]}`, `${hsa_rcs[$i]}`, `"$dst_dir/hook-spec.sh"`, `$(dirname -- "$0")/hook-spec.sh`. None matches — the pattern requires `/` immediately after the identifier or its subscript, and `}`, `:` and `#` all break it. It does match `${arr[i]//…}`, `${!ref//…}` and `${var/…/…}`, which is the point.

**Q8. Two things I must correct while writing.**
(a) Add `hook-spec.ps1:94` to ledger row 11 — it is the twin of `hook-spec.sh:97-98` and carries the same now-false provenance claim (F-13). (b) Record the true pre-change state of the A′ idiom scan (16 hits, 4 rows red) rather than the design's "green" (F-12). Both go in `04_DEVELOPMENT.md`.

---

## 10. Verdict

> **APPROVED FOR DEVELOPMENT**

All eleven round-1 findings are closed, and I verified each against the real files rather than against `§18`'s account of them. The three fixes I care most about are structural rather than cosmetic: lazy resolution *removes* the binding-order constraint instead of satisfying it, so a future re-ordering of either flow cannot resurrect F-1; the C-style counter loop *removes* the empty-array expansion instead of guarding it; and `≤ IND` plus terminator-exclusion makes the containment window a total function of its input, verified three ways against the real `settings.json.tmpl`. Rule 2 is a stronger answer to F-2 than the three-site patch I asked for. The two adjudications the architect requested both go **in the architect's favour**, and I state that plainly: `upgrade-project.ps1:254` is at S3 scope and my round-1 F-4 overreached on the PowerShell half; and my round-1 §3.5 totality reading covered `resilient_cmd` call sites but not the two `$IsWindows` host-OS reads, which is a real gap the extended table closes.

The three ungated autonomous calls all survive scrutiny. D-5 was the dangerous one — a "while I was in there" retirement of a symbol that two test drivers extract by name — and it holds: the deletion test is genuinely failed by the surviving wrapper, all eight call sites in all four files are accounted for, both name-anchored extractors are deleted by `§8`, no third extractor exists anywhere in the repository, and the row arithmetic is 17-in/17-out in both shells so no pin moves. D-6 is forced by a real defect (a silently discarded cache, 13 spawns against a ceiling of 9) that neither the round-1 design nor my round-1 review caught, and its bash form is correct under `set -uo pipefail` and emits no different byte. D-7 correctly refuses to unfreeze `test-harness-upgrade` and pay in a PowerShell pin no agent can reconcile.

Two new findings arose from the rework itself. Neither requires a design decision, neither moves a mechanism or a pinned count, and both are dischargeable by a developer with bash — which is why they are **binding conditions** rather than a third rollback:

1. **F-12** — `§8` / `§18 F-6`'s "both scans are green on the pre-change tree — measured, not assumed" is false for the idiom scan, which is red on 4 of 4 files (16 non-comment hits) pre-change. The scan is correct; the claim about it is not, and it must not be transcribed into `04`/`06`.
2. **F-13** — ledger row 11 omits `hook-spec.ps1:94`, the PowerShell twin of the `hook-spec.sh:97-98` provenance sentence round 2 correctly added. One row, one file, comment-only — but it is a lockstep-surface omission, and this is the class the gate exists to catch.

Both route to **solution-architect** for the record; **neither routes back for rework** — the developer applies them mechanically and records the result. Record-only items R-1 … R-6 need no action beyond being noted.

**No finding routes to requirement-analyst.** `01_REQUIREMENT_ANALYSIS.md` stands as written and unedited, exactly as it did in round 1.

**What the developer must capture empirically, because I could only verify it by inspection**: the `test-init.sh` 355 tally from a real run with its `=== Result ===` line (the 17-in/17-out claim is arithmetic, and this repo's rule is that a tally is cross-checked against the artifact that produced it — **that claim is unverified by me**); `verify_all` 32/0/0; M-C's exactly-two-token prediction and the 31/0/1 whole-gate; the pre-change `[F.2]` PASS from the S0 capture with both admissibility assertions; `test-harness-upgrade` 89/89 and `test-real-project` 90/90; the true pre- and post-change hit counts for both A′ scans; and the entire PowerShell surface, which no agent here can touch and which lives or dies on operator items 12-16.

Full-mode equivalent of this verdict for PM routing: **APPROVED WITH CONDITIONS** — conditions F-12 and F-13, plus the eight empirical captures in §8. Development may proceed.

---

## Appendix — Round 1 finding index (superseded, retained for traceability)

Round 1 verdict: **CHANGES REQUIRED** (dimension 7 FAIL; dimensions 2 and 6 WARN). All 11 findings routed to solution-architect; none to requirement-analyst. Each finding's resolution is recorded in `02_SOLUTION_DESIGN.md §18` and re-verified in §2 above.

| # | Sev | Title | Round-2 status |
|---|---|---|---|
| F-1 | MAJOR | Adapter placement contradicts the variables its own resolution order reads (`dst_dir` bound after the helper in 3 of 4 files) | CLOSED — lazy resolution |
| F-2 | MAJOR | AC-7's anti-vacuity direction measures the wrong artifact (`git show HEAD:` = v0.44.0) | CLOSED — S0-capture Rule 2 |
| F-3 | MAJOR | Containment-window terminator rule is non-total (`"PreToolUse"` last key in `hooks` → zero matches → false FAIL) | CLOSED — `≤ IND`, terminator excluded |
| F-4 | MEDIUM | `hostos`-failure skip leaves `ph_o` unbound → exit 1, destroying the contracted exit 4 | CLOSED (bash); PS half withdrawn — see §3.3 |
| F-5 | MEDIUM | `"${!hs_keys[@]}"` on an empty array breaks the bash-3.2 target the array choice was justified by | CLOSED — C-style counter loop |
| F-6 | MEDIUM | Standing flow-byte coverage drops 8 cells → 1, unrecorded as a residual | CLOSED — 2 standing scans + residual RES-1 |
| F-7 | MINOR | Operator-list arithmetic internally inconsistent (11 numbered vs a sentence implying 19) | CLOSED — two registers, 11 → 16 / 19 → 24 |
| F-8 | MINOR | §8 self-contradicts on the pre-repair symptom (green tautology vs red probe) | CLOSED — 9 loud red rows |
| F-9 | MINOR | `upgrade-project.ps1:286` passes automatic `$IsWindows` positionally; `Get-HookSpecHostOs` named but undefined | CLOSED at the root by D-5 |
| F-10 | MINOR | C-7's grep narrower than the §4 mandate it enforces | CLOSED — both widened |
| F-11 | MINOR | AC-4's Windows runtime half neither a stage-4 obligation nor an operator item | CLOSED — operator items 12(f)/13(e) |

Round 1's positively-verified claims (still standing, not re-litigated in round 2): change-ledger completeness via an independent 54-file idiom sweep; the `&`/`patsub_replacement` hazard genuinely unreachable by construction; fail-closed preserved on every degradation branch with no loud-then-quiet residue; mutation M-C correctly predicted with a real anti-vacuity direction; all cap measurements; the freeze contradiction adjudicated in favour of B-11's dirty-tree premise (the "clean" git snapshot is stale, and S0 must still be re-derived); and scope discipline (32 checks, no guard/verb-set change, untracked operator backlog untouched, harvester defect and T-17 residual excluded).
