# 05 — Code Review · T-17 `guard-cmd-chain`

- Mode: **full** · Stage 5 (code-reviewer) · Security task
- Inputs: `01_REQUIREMENT_ANALYSIS.md` (round 2), `02_SOLUTION_DESIGN.md` (round 2), `03_GATE_REVIEW.md` **ROUND 2** (C-1 … C-15), `04_DEVELOPMENT.md`
- Method: **code reading only** (Read/Glob/Grep; no Bash, no `pwsh`). Every citation below was opened. Where I state a verdict for an input, I traced it cell-by-cell through the shipped code, not through the design table.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- _(Persisted verbatim by the PM Orchestrator: the code-reviewer agent has Read/Glob/Grep only and cannot write files.)_

---

## 1. Files reviewed

Code (read in full, both copies where mirrored):
- `/home/alan/Programs/harness-kit/.harness/scripts/guard-rm.sh` (946 lines)
- `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/scripts/guard-rm.sh`
- `/home/alan/Programs/harness-kit/.harness/scripts/guard-rm.ps1` (909 lines)
- `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1`
- `/home/alan/Programs/harness-kit/.harness/scripts/test-guard-rm.sh`
- `/home/alan/Programs/harness-kit/.harness/scripts/test-guard-rm.ps1`

Fixtures / docs / ledgers:
- `/home/alan/Programs/harness-kit/evals/guard-rm-cases.md`
- `/home/alan/Programs/harness-kit/.harness/rules/75-safety-hook.md`
- `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl`
- `/home/alan/Programs/harness-kit/.harness/scripts/baseline.json`
- `/home/alan/Programs/harness-kit/CHANGELOG.md`, `/home/alan/Programs/harness-kit/docs/dev-map.md`, `/home/alan/Programs/harness-kit/.claude-plugin/plugin.json`, `/home/alan/Programs/harness-kit/CONTEXT.md`
- `/home/alan/Programs/harness-kit/.harness/scripts/verify_all.sh` (I.2 only, to confirm the 200-line cap mechanism)

---

## 2. What I verified independently (not taken from `04_DEVELOPMENT.md`)

| Claim under test | Result |
|---|---|
| Repo ↔ template byte-identity of the guard pair | **Consistent.** Both `.sh` copies end at line 946 with identical tail bytes; both `.ps1` copies end at line 909 identically; `set -uo pipefail` at line 33 in both `.sh`. Combined with the captured `sync-self --check → In sync.` this is as strong as a diff |
| Verb set unchanged (AC-6) | **YES.** `guard-rm.sh:135` lists 9 verbs; `_is_destructive_verb` (`:150-163`) has exactly 9 arms, member-for-member. PS `$destructiveVerbs` (`:98-101`) has 9 and `Test-DestructiveVerb` **iterates that same array** — structurally drift-proof. Carriers/shell-verbs are separate lists that never block by themselves |
| No `${var//needle/repl}` in new code (B-14) | **YES.** Grep finds only the two pre-existing exempt lines `guard-rm.sh:90-91` (replacements `"` and `\`) and the two pre-existing driver lines `test-guard-rm.sh:190-191`. The newline unescape uses `str_replace_all` (`:38-45`, `:85-87`) and the driver uses `tg_replace_all` (`:171-178`) |
| bash-3.2 safety | **YES.** No `mapfile`, no `${v,,}`, no `declare -A`/`declare -a`. New constructs are `${s:$i:1}`, `+=` array append, `case` bracket globs, `${t%%=*}`, `$'\n'` literals, `unset 'arr[n-1]'` — all 3.2-legal |
| Empty-array-under-`set -u` | **YES.** Every `"${arr[@]}"` expansion is either the `${arr[@]+…}` idiom (`:778`, `:848`, `:889-910`, `:921`) or provably non-empty (`:782`, `:830`, `:872` are all guarded by `ntok == 0 → return` at `:780` or are inside a loop over the array) |
| Rule doc ≤ 200 lines in **both** copies (C-9, hard: `verify_all.sh:407` WARNs → exit 1) | **YES.** Repo copy 198 lines, `.tmpl` 188 (04 reports 197/187 — a trailing-newline counting artifact, not an error). Headroom is 2 lines |
| `baseline.json` carries the bash key only | **YES.** `:23` `test_guard_rm_bash_assertions: 81`; no PS key; `_qa_note_t17` explains the deliberate absence |
| `CONTEXT.md` untouched (C-8) | **YES.** Exactly one `Command position` entry at `:100-102` |
| `verify_all` check count | `baseline.json:10` still `verify_all_checks: 32`; nothing in the changed surface touches `verify_all.{sh,ps1}` |
| `docs/proposals/frontier-gaps-2026-07.md` | Not present in the tree and referenced only inside this task's own stage docs as an out-of-scope statement. Not edited, not used as a source |
| Version stamps | `plugin.json:4` = `0.46.0`; CHANGELOG `[0.46.0]` entry present and accurate |
| Three-way lockstep 81 ↔ 81 ↔ 81 | **YES, counted by hand.** bash driver: 17 + 19 (a–r + f2) + 14 (L) + 6 (F/V) + 25 (C/P/O/N/Q/W) = 81. Fixture: same 81 ids in five sections. PS driver: same 81 ids |

**Independent arithmetic check of the anti-revert claim.** I derived, from the code, which of the 81 rows must be red against the pre-change guard: the 17 genuinely-flipped AC-1 rows (`a` and `d` already blocked pre-change — `d`'s `||` was already covered by `split_pipes`) plus `C10a C10b C12cr C12tee C14 P1 P2 P5 O1 O2 O3 W1 Q2 F2 F3` = 15. **17 + 15 = 32**, which is exactly the reported `PASS: 49 / FAIL: 32`. The mutation table in `04_DEVELOPMENT.md` is also internally consistent with my traces (e.g. row `h` is red under *neither* the scanner nor the prefix mutation, because either mechanism alone catches it — and the report correctly omits it from both lists; `O1` appears in both lists, which is exactly right). **The anti-revert evidence is real and the new rows are load-bearing, not shape-matching.**

---

## 3. Findings — axis A: Spec / design fidelity

### MAJOR

**A-1 · [PERF/REQ] NFR-1's +20 ms budget is missed by ~38× and the delivery verdict absorbs it.**
`.harness/rules/75-safety-hook.md:121-129`, `04_DEVELOPMENT.md` "NFR results".
The 8192-character worst case measures 1487 → **2251 ms** (+764 ms) against NFR-1's *"within +20 ms of the pre-change guard"*. The developer's disposition — correct the rule doc to the measured truth — satisfies NFR-1's **second** clause (the never-true "under 50 ms" claim is genuinely gone, verified in both copies) but not its **first**, which is a numeric acceptance condition. `04_DEVELOPMENT.md` records this honestly as "PARTIALLY MET" and as Open Issue 1, yet the document's Verdict reads **READY FOR REVIEW** with no per-NFR qualification. That gap must be closed by an explicit decision, not by absorption.

My own adjudication of the engineering, so the decision can be made in one step:
- The cause is real and correctly profiled. Bash `${s:$i:1}` is O(i), so each character pass is O(n²). The pre-change guard already made **two** such passes (`tokenize`, `split_pipes`); the change adds a **third** (`split_positions`). 1487 × 1.5 = 2230 ≈ the measured 2251 — the profiling story is arithmetically self-consistent, not hand-waving.
- Therefore **+20 ms was infeasible as written** for *any* added pass. That is a requirement defect at least as much as a code defect.
- The risk is bounded: the command is truncated to 8192 first (`guard-rm.sh:128`), so the worst case is ~2.3 s and cannot approach a hook timeout. There is no fail-open path here.
- Typical commands got **faster** (49 → 46 ms; the C-15 redirecting case 39 → 33 ms), because `_is_destructive_verb` removed ~20 `printf | tr` forks per segment. That is a genuine improvement on the common path.
- A cheap mitigation exists and is not exotic: chunked indexing (`chunk="${s:$base:256}"`, then index inside the chunk) reduces the constant ~256× without changing the algorithm's shape. **I am not asking for it in this task** — rewriting the hot loop of a live fail-closed hook to chase a worst case nobody has hit is worse risk management than recording it.

**What closes this finding (no guard code change required):** the PM records the disposition — NFR-1's +20 ms clause is waived with the measured figures and the O(n²) root cause, and a follow-up pool row is opened for the chunked-indexing mitigation with the developer's own caveat attached (any length cap must fail **closed**, i.e. BLOCK rather than skip, or it becomes a trivial bypass). Owning stage: **PM / requirement-analyst** (one paragraph), *not* the developer.

### MINOR

**A-2 · [DOC/REQ] An unrecorded ALLOW→BLOCK class: `bash <<EOF … EOF` now blocks.**
`guard-rm.sh:809-819` + `:490-530`, `.ps1:785-794`.
The shell-interpreter branch judges *every* non-option token as a command string. For `bash <<'EOF'\necho hi\nEOF`, `tokenize()` does not split on newlines (`:197` splits on space/tab only), so a token is `<<EOF` + LF + `echo`. Recursing into it, the scanner reads `EOF` as a here-doc delimiter, hits end-of-input in state `H` with a non-matching pending line, and returns 1 → `parse_failed` → **exit 2**. The scanner position `bash <<'EOF'` reaches the same result via the token `<<'EOF'`.
Direction is over-block, so IS-2/AC-4 are not violated; but AC-4's pass condition requires every ALLOW→BLOCK class outside the AC-1 rows to be *fixed or recorded* (OQ-6a), and this one is neither. The accepted-over-blocks table (`75-safety-hook.md:100`) records `bash <script> "<a command string as an argument>"` — the same mechanism — but a reader would not predict the here-doc form from that row.
**Correct behaviour:** add one clause to the existing table row (both rule copies), e.g. "…and `bash <<EOF … EOF`, whose here-doc fragment is judged as a command string". Optionally pin it with a driver row. Owning stage: **developer** (documentation only).

**A-3 · [LOGIC] The one false negative I found: an escaped `\>` or `\<` immediately before `&` suppresses the separator.**
`guard-rm.sh:541-550` (row 15), mirrored at `.ps1:531-537`.
`prev` is read as the **raw** input byte at `i-1` (`:543`), exactly as design §3.1 row 15 specifies. When the preceding `>` was itself backslash-escaped, bash treats it as a literal character and the `&` **is** a separator — the scanner treats it as part of a redirect and appends instead of flushing.

```
echo a\>& rm -rf /etc/harness-guard-probe      →  guard: exit 0   (bash: runs the rm in background)
```

Traced end to end: row 1 consumes `\>` at `:411-418`; at `&`, `prev` is the raw `>` → append; EOF flushes one position whose verb is `echo`; `s ∈ P` does not rescue it (same string, same verb); `split_pipes` yields the same. Same for `\<&`.
This is **monotone** (pre-change also ALLOWed, so no IS-2 violation) and it faithfully implements the design, so it is a design hole rather than a coding slip. I am rating it MINOR rather than MAJOR because a documented residual — `/bin/rm` (rule doc residual 1) — is a strictly easier bypass of the same guard, so this does not move the real security posture. It does, however, contradict IS-1 row 2 and the shipped coverage table's unconditional "Every position judged" for `A & B`.
**Correct behaviour:** either track whether the previous `>`/`<` was appended by the row-12 dispatch at state `N` (one flag, one line, both shells) and use that instead of the raw byte, or add the case to the residual list. Owning stage: **developer**, or **solution-architect** if the fix is preferred over disclosure (it is a §3.1 row-15 amendment).

**A-4 · [DOC] The residual list understates coverage: `command rm` *is* recognized.**
`.harness/rules/75-safety-hook.md:67-68` and `.md.tmpl:53-54` — residual 1 reads "`/bin/rm`, `\rm`, `command rm` via `$(which rm)` are not recognized". But `command` is in `CARRIERS` (`guard-rm.sh:143`, `.ps1:108`), so `command rm -rf /etc/x` runs the carrier scan, dispatches at the exact token `rm`, and **BLOCKs**. The sentence (inherited verbatim from design §10.2 item 1, whose phrasing was already ambiguous) tells a user the guard is weaker than it is. Error direction is safe, but this is the task's coverage-honesty deliverable and it should be accurate in both directions.
**Correct behaviour:** drop `command rm` from residual 1 (it belongs to the carrier row of the coverage table). Owning stage: **developer**.

**A-5 · [DOC] The distributed template copy omits the "PowerShell twin is verified by symmetry only" disclosure.**
Repo copy `75-safety-hook.md:86-87` ends residual 8 with "**The PowerShell twin is verified by symmetry only** until an operator runs it on Windows." The `.tmpl` twin (`:70-72`) stops before that sentence. Design §11 row 9 sanctioned removing the *two dogfood-note blocks*, not this. The omission is the wrong way round: the people who most need to know the Windows guard is unrun are **users on Windows receiving the template**, not this repo's maintainers. Given NFR-4/AC-12 and the fact that the highest-probability PS defect (R11) fails **open**, the user-facing copy is where the caveat earns its line.
**Correct behaviour:** carry the same sentence in the `.tmpl`. Owning stage: **developer**.

### NIT

- **A-6 · [DOC]** `04_DEVELOPMENT.md` AC-1 section: "17 of the 18 were live bypasses (row `a` is the control that already blocked)". There are **19** AC-1 rows (a–r plus `f2`) and **two** did not flip — `a` and `d`, because `||` was already covered by `split_pipes`. The enumerated red list is correct; only the prose summary is off. Worth correcting because this is the headline security claim.
- **A-7 · [LOGIC]** `xargs bash --rcfile foo -c "rm -rf /etc/x"` is unjudged: the carrier's embedded-interpreter dispatch (`guard-rm.sh:831-839`, `.ps1:806-813`) breaks after the **first** non-option token, while the top-level shell branch judges **all** of them. This matches design §3.4 exactly ("its first non-option argument"), so it is a design asymmetry, not a coding defect; monotone and contrived. Record only.
- **A-8 · [LOGIC]** Pre-existing, unchanged, worth knowing: an empty leading token still hides the verb — `'' rm -rf /etc/x` tokenizes to `("" "rm" …)`, `_skip_prefix` breaks on the empty token, verb is `""` → ALLOW. Identical pre-change (monotone), same family as the documented verb-spelling residual.

---

## 4. Findings — axis B: Standards conformance

**No CRITICAL and no MAJOR on this axis.** The change is unusually well-behaved against this repo's documented rules: the live-hook edit sequence (template → `bash -n` → drive via `[guard-path]` → single `sync-self`) was followed, the repo copy was written exactly once per shell to an already-green file, the check count is frozen at 32, `CONTEXT.md` was not re-touched, the `patsub_replacement` and bash-3.2 red lines hold, and the 14-surface ledger is complete with `docs/tasks.md` / `BATCH_PLAN.md` correctly left to the PM.

### MINOR

**B-1 · [MAINT] Dead code carried into the new helper.** `guard-rm.sh:750`/`:754` (`skip_next` is initialised to 0 and tested but never set to 1) and `.ps1:727` (`$skipNext` likewise). It is the residue of the disabled find-predicate skip and it moved verbatim into the extracted `_walk_paths` / `Get-OffendingFromWalk`. Keeping the *walk logic* byte-unchanged was the right call (design §7); keeping a branch that provably cannot fire is not — a future reader will assume a skip semantics exists. `find_predicates` / `$findPredicates` (`:136`, `.ps1:103`) are likewise declared-unused; the developer disclosed those (Open Issue 5) but not `skip_next`. Either delete both dead pieces or add the one-line "kept as historical documentation of D-1/D-2" comment that `find_predicates` deserves too.

### NIT

- **B-2 · [STYLE]** `test-guard-rm.sh:158` (row `W4`) is a **double-quoted** array element containing `$` (`\$CLAUDE_PROJECT_DIR`), while the file's own mandatory rule at `:33-36` — and gate C-5 — say single-quote every row containing `$`. It is safe *today* (`\$` suppresses expansion, and there is no `$(`), and the echo-back check confirms it, but the rule exists precisely so that safety does not depend on a per-row escape analysis. The PS twin (`.ps1:157`) does it correctly with `'…'`. Prefer `$'…'` or a single-quoted concatenation.
- **B-3 · [DOC]** `04_DEVELOPMENT.md` reports the rule docs at 197/187 lines; the files are 198/188 (trailing-newline counting). Immaterial to the gate (cap 200), but the ledger should say what `wc -l` will say to the next agent, since C-9 is now a hard gate condition with only 2 lines of headroom.
- **B-4 · [DOC]** The gate's round-1 §4 item 3 asked that the carrier false-positive class (*carrier verb + literal destructive-verb argument + later outside path*, e.g. `timeout 5 grep -r rm /etc` → BLOCK) be recorded under OQ-6a. It is not in the accepted-over-blocks table. It was an observation rather than a numbered condition, so this is not a C-* miss — but the table is one row from being complete, and row `N1` already pins the adjacent boundary.

---

## 5. Adjudication of the four items the PM asked me to rule on

### 5.1 `DESIGN DRIFT` 1 — here-doc terminated by end-of-input is accepted — **ACCEPT AS A FIX-FORWARD. No architect round.**

The code does what the report says: `guard-rm.sh:611-619` compares the pending line (with `<<-` tab-stripping) against the queue front at end of input and dequeues on an exact match; anything else still falls through to `:620`'s `return 1`. `.ps1:614-620` mirrors it exactly. Row `F3` (`cat <<EOF` + LF + body, no terminator) still BLOCKs, so the fail-closed side is intact and test-pinned.

The developer's reasoning is sound, and it is in fact **stronger than the report claims**. Design §3.1's unconditional "`HDBODY` → parse failure" does not merely risk blocking a here-doc whose terminator lacks a trailing newline — it would block **essentially every here-doc an agent writes**, because the python3 JSON extraction path (`guard-rm.sh:60-67`) is a command substitution, and command substitution strips trailing newlines. The command string the guard sees therefore *never* ends in a newline. Under the literal design, AC-3 **L9** — the row the requirement calls load-bearing, and R1 the highest-impact risk — would BLOCK, and AC-3 would fail. The design contradicted the acceptance criterion; the developer resolved in favour of the criterion. That is the correct precedence, the direction is ALLOW→ALLOW (IS-2 untouched), and L9 is the pinning test. Routing this back to the architect would buy a document edit and cost a rollback.

**Disposition:** accepted. The design's §3.1 "End of input (total)" bullet should be corrected at archive time so the artifact does not preserve a false statement — a PM housekeeping edit, not an architect round.

### 5.2 `DESIGN DRIFT` 4 — the F-9 ANSI-C evidence row is wrong; recording rather than claiming a fix — **CORRECT, and the under-claim is the right call.**

I verified the claim by trace, not by trust. `echo $'it\'s fine'` contains **three** apostrophes. The scanner handles it correctly (`:421-434` sets `sq_ansi` when `prev == '$'`; `:411-418` then consumes `\'` as a pair, leaving SQ balanced) — so `sq_ansi` works exactly as designed. But `s ∈ P` means the byte-unchanged `tokenize()` still runs over the whole string, and `tokenize` counts every `'` regardless of backslashes (`:203-205`, `:212`) → odd parity → `parse_failed` → BLOCK, **pre-change and post-change alike**. And this generalises: any `$'…\'…'` string necessarily has odd apostrophe parity, so `sq_ansi` can never change a top-level verdict while the pre-change pass is retained. Design §10.3's "Evidence: a driver row `echo $'it\'s fine'` → ALLOW" is therefore unachievable as written.

Row `Q1` records the true verdict (BLOCK) and the rule doc files ANSI-C strings under accepted over-blocks (`:97`). Row `Q2` (`echo $'its fine' && rm -rf OUT`, even parity) is the row that actually exercises the flag path end-to-end and it is load-bearing (red pre-change). **Under-claiming here is correct**: the alternative — asserting a fix that the retained pass makes unobservable — is exactly the overstatement this task exists to eliminate. The flag itself is correctly kept: it is cheap, it is provably fail-closed (a spurious `sq_ansi` can only swallow a quote, which leaves the scanner in SQ at EOF or desynchronises parity with `tokenize`, both → BLOCK), and it becomes load-bearing the day `tokenize` gains backslash awareness.

**Disposition:** accepted. Design §10.3's closing paragraph should be corrected at archive time.

### 5.3 The four AC-4 ALLOW→BLOCK flips — **class is real, isolated, and recording is right under OQ-6(a).**

Mechanism confirmed by trace: the scanner treats `\"` as an escape (row 1, `:411-418`), so state stays `N` and a following top-level `;`/`&&` flushes; the resulting position carries one unmatched `"`; the byte-unchanged `tokenize()` then fails on odd parity. All four flipped corpus rows (49/51/53/55) are the **JSON-escaped Windows** `hook-spec` byte-forms, i.e. bytes that live inside a settings file, not bytes typed into the Bash tool. Probes A–D and rows `W1`/`W2`/`W3` bracket the class from both sides, and `W4` pins the **live unix hook byte-form as ALLOW** — I re-derived `W4`'s decoded string from the bash literal (`test-guard-rm.sh:158`) and from the PS literal (`.ps1:157`) and they are the same string, matching corpus row 48.

I also checked the nearest *realistic* neighbour, since that is what OQ-6(a) turns on: `python3 -c "import json; print(\"hi\")"` — the escaped quotes sit inside a **real** double-quoted region, so the `;` never flushes and the line ALLOWs. The class needs one escaped quote on each side of a top-level separator, which is a machine-generated shape. **Recording, not fixing, is the correct disposition**, and the alternative the developer names (dropping the escaped quote from the emitted position) would widen the divergence between the scanner's positions and `tokenize`'s view — new risk for no user-visible gain.

### 5.4 NFR-1 — see finding **A-1**. Correcting the doc was *necessary and correctly executed*, but it is not *sufficient*; the numeric clause needs an explicit recorded waiver.

---

## 6. PowerShell twin — review by reading (unrunnable: `pwsh` absent)

I read `guard-rm.ps1` and `test-guard-rm.ps1` against the known-fatal classes named in the dispatch. **No defect found; the twin implements the same semantics, not merely something plausible.**

| Hazard class | Result |
|---|---|
| Whole-file parse (a syntax error in a never-taken branch bricks the guard) | No construct that would fail to parse. `$BackTick = [string][char]0x60` (`:43`) and `$specialScanChars` (`:115-118`) deliberately avoid backtick-quoted literals — the exact defect class that bit T-12. The one backtick in the file is the pre-existing line-continuation at `:677` |
| Automatic-variable collision | Clean. `$stIn $sqAnsi $nestKind $nestTop $nestBuf $nestSt $hdQueue $hdLine $prevCh $posList $ovrTrim $repoRoot $truncCmd` — none collides. No `$isWindows`, `$input`, `$args`, `$error`, `$matches`, `$host`, `$home`, `$pwd`, `$this`, `$profile` |
| .NET out-of-range throw where bash yields `""` (F-6/C-7 — **fails open at exit 1**) | **Correctly closed.** Every multi-character lookahead goes through `Get-Slice` (`:141-148`), which reproduces bash's short read exactly, including `start >= Length → ''`. Single-character reads `[string]$s[$i]` occur only inside `while ($i -lt $len)` guards (`:295`, `:480`, `:489`, `:496`). `$s[$i-1]` is guarded by `if ($i -gt 0)` (`:390`, `:533`). The whole scanner body is `try { … } catch { return $null }` (`:271`, `:625-630`) |
| Failure-channel unification | One channel: `Split-CommandPositions → $null` (mirroring `Get-Tokens`), converted by the caller to the existing `,@('__PARSE_FAIL__')` (`:867`), consumed at `:886`. No new mechanism |
| Array-coercion / empty-array unrolling | `,$posList.ToArray()` (`:624`), `,$segments.ToArray()` (`:203`), `,$tokens.ToArray()` (`:183`) — an **empty** position list returns `@()`, not `$null`, so the `$null` parse-fail signal stays unambiguous. This is subtle and it is right |
| `-join` next to `+`, `-split "…", -1`, `Out-String`, `Sort-Object -Unique` | None present; `[string]::Join` used instead |
| Output-stream pollution (any uncaptured expression becomes a return value) | Clean. Every `List.Add` / `StringBuilder.Append` / `.Clear()` is `[void]`-cast; `List.RemoveAt` returns void; helper functions return only via `return` |
| Case-sensitivity parity with bash | Override prefix `StartsWith(…, Ordinal)` (`:70-71`) OK; carriers `-ceq` OK (bash `case` is case-sensitive); destructive/shell/pwsh verbs `-ieq` OK (bash uses bracket-class globs); `find` `-ceq` OK; assignment `-cmatch '^[A-Za-z_][A-Za-z0-9_]*\+?='` OK — equivalent to bash's split-then-validate including C-13's `+` |
| Same semantics, not just plausible ones | Verified branch-for-branch against the bash file: verbatim frames (`:298-340` ≡ `:337-369`), comment/here-doc states, hoisted catch-all, rows 1–23 with the same state guards, the same end-of-input totality **including drift 1** (`:614-620`), the same `nestDepth` accounting (incremented on all four command frames, decremented at all four pops), the same union with `$s` first, the same carrier-then-`find`-no-return ordering with the `# NO return here` comment at `:816` |

Residual risk is unchanged from what the task already declares: the twin is **green-by-symmetry only**. `04_DEVELOPMENT.md`'s 7-item operator list is appropriately scoped and correctly marks item 3 (R11) as a *security* item. No frozen T-13 item was reconciled and no phantom `test_guard_rm_ps_assertions` key was invented (OQ-4a).

---

## 7. Requirement coverage check

| Criterion | Implementation / evidence | Status |
|---|---|---|
| AC-1 bypass matrix (a–r, +f2), all BLOCK | Driver rows `a`…`r`,`f2`; 17 genuinely flipped (arithmetic re-derived in §2) | PASS |
| AC-2 existing behaviour preserved (17 rows, pwsh row 8, depth-2, env override + audit line) | Rows 1–17 retained verbatim in both drivers and the fixture; audit line captured | PASS |
| AC-3 legitimate corpus, exit 0 except L10 | `L1`…`L14`; L10 = BLOCK per the round-2 header; **L9 has no trailing newline and is the drift-1 pin** | PASS |
| AC-4 differential, 0 BLOCK→ALLOW | 55 corpus lines with per-line source artifact; 4 ALLOW→BLOCK (one class, isolated, recorded, pinned by W1–W4); 0 BLOCK→ALLOW, 0 UNKNOWN | PASS |
| AC-5 fail-closed | `F1`/`F2`/`F3` + the captured no-`.git` WARN + B-1 empty-stdin cases | PASS |
| AC-6 verb set unchanged | Verified by me in both shells (§2); `V1`/`V2`/`V3` ALLOW | PASS |
| AC-7 symmetry + lockstep | `sync-self --check → In sync.`; tail-byte identity confirmed; 81↔81↔81 | PASS |
| AC-8 gate green, 32 checks | 32/0/0 before and after; no check added; I.2 PASS at 198/188 lines | PASS |
| AC-9 documentation truth | Trigger sentence replaced by the coverage claim; residuals named; failure-mode table extended | WARN — **A-4**, **A-5** (two inaccuracies in the honest list; the AC itself is met) |
| AC-10 driver anti-revert | Four mutations, red-row sets internally consistent with my traces; the C-1 mutant reproduces the F-2 regression directly | PASS |
| AC-11 live-guard continuity | Tallies quoted per run; repo copy written once per shell | PASS |
| AC-12 PowerShell debt recorded | 7-item operator list + `_qa_note_t17`; nothing frozen reconciled | PASS |
| IS-1 coverage claim (total) | Rows 1–14, 18, 19 implemented; rows 15–17 disclosed | WARN — **A-3** (row 2 not total for `\>&`), **A-7** (row 9/10 corner) |
| IS-2 monotonicity | `plist+=("$s")` unconditional (`:885`); no path in `classify_segment` became less strict — I re-derived this for all six changes | PASS |
| IS-3 fail-closed | Every scanner failure path returns 1 → `parse_failed` → exit 2; no skip | PASS |
| IS-4 no false-negative-by-quoting | Separator rows are all gated on `st == "N"` (`:538`); backslash handling per B-9 | PASS |
| IS-5 existing behaviour exactly preserved | `resolve_leaf`, `is_descendant`, `find -delete`, `tokenize`, `split_pipes` untouched; `.git`-less fail-open unchanged | PASS |
| IS-6 BLOCK message quality | `:932-944` unchanged, names all offending paths | PASS |
| IS-7 driver + fixture lockstep | 81 ↔ 81 ↔ 81 | PASS |
| IS-8 documentation truth restored | Both rule copies | WARN — **A-5** (`.tmpl` divergence) |
| IS-9 cross-shell + template lockstep | Verified | PASS |
| B-1…B-14 | B-3 (`N2`/`N3`), B-4 (`F1`), B-5 (`F2`), B-6 (captured), B-9 (`W1`–`W3`), B-10 (`f2`,`C12cr`), B-14 (grep-verified) | PASS |
| NFR-1 latency | Measured, doc corrected — budget missed | **FAIL — A-1 (MAJOR)** |
| NFR-2 no new dependency | No `realpath`, no `git`, no new interpreter; python3 path + fallback intact | PASS |
| NFR-3 live-guard safety | Edit sequence honoured | PASS |
| NFR-4 cross-shell parity | Symmetry-only, declared | PASS (as scoped) |
| NFR-5 security posture | No flag, no config, no env can weaken; override is the single audited hatch | PASS |

---

## 8. Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.1 scanner, single-pass lexer + nesting stack | `split_positions` `:319-624` / `Split-CommandPositions` `:270-631` | PASS |
| §3.1 frames save **and restore** quote state; inner starts `NORMAL` (C-2) | `_sp_push_cmd` `:296-302` saves buffer+`st`; `_sp_pop_cmd` `:306-315` returns both; restored at `:458`, `:562` | PASS |
| §3.1 row 4 × NORMAL **pushes** BQ (C-10) | `:454-464` `else _sp_push_cmd BQ` — the `else` branch is present | PASS |
| §3.1 PARAM/ARITH verbatim-until-closer (C-11) | `:337-369` dedicated block ahead of all rows, tracking only the closer, nested `${`/`$((`/`(`/`{`, and `\`+next | PASS |
| §3.1 end-of-input totality | Implemented **except** the `HDBODY` clause | WARN — **drift 1 — accepted, §5.1** |
| §3.2 `P` contains `s` at every depth (C-1) | `:885` unconditional, with the fail-open warning comment `:876-879` | PASS |
| §3.2 fast-path as 12 separate tests (C-12) | `_has_scanner_trigger` `:630-645`, never a bracket expression | PASS |
| §3.3 exact assignment test + `+=` (C-13) | `:715-721` `name="${t%%=*}"`, `name="${name%+}"`, three validations | PASS |
| §3.4 carrier scan first, **no return**, then `-delete` (C-3) | `:825-843` has no `return`; `find` branch at `:846` | PASS |
| §3.5 pwsh call-site → `classify_command_string`; new shell branch | `:797`, `:809-819` | PASS |
| §3.6 fork-free verb test, 9 members, declaration retained | `:135`, `:150-163` + ledger comment | PASS |
| §5.1 override once, top-level, before the `.git` walk (C-4) | `:101-111`, between step 2 and step 3; nothing in `classify_*` mentions it; `O1`/`O2`/`O3` pin all three bypass paths | PASS |
| §6.1 patsub-safe `\n`/`\r`/`\t` unescape in the no-python3 fallback | `:82-87` via `str_replace_all` | PASS |
| §6.2 stride-4 rows + quoting mandate (C-5) | `test-guard-rm.sh:37-159`, rule written into the file | WARN — **B-2** (row `W4` letter deviation) |
| §9.2 PS constraint list (C-7) | All satisfied — §6 above | PASS |
| §10.2/§10.3 residual + over-block publication (C-9) | Both rule copies, ≤200 lines | WARN — **A-2, A-4, A-5, B-4** |
| §11 14-surface ledger | All 14 accounted for; 11 and 14 correctly untouched | PASS |
| §3.1 row 15 `prev` = raw previous byte | Implemented as specified — and that is the hole | WARN — **A-3** |
| *(undesigned)* hoisted catch-all `case` (drift 3) | `:405-408`; pattern list is **exactly** the 17 characters rows 1–23 react to — I re-derived it row by row. Semantics identical; it is what made typical commands faster | accepted |
| *(undesigned)* by-value token passing (drift 2) | `:707`, `:746`; rationale (unbound read under `set -u` exits 1 = fail-open) is correct and the empty-array expansion hazard is avoided at every call site | accepted |

---

## 9. Axis status

- **Standards-conformance:** 3 findings — worst = **MINOR** (B-1 dead code; B-2/B-3/B-4 NITs). No CRITICAL, no MAJOR. This axis is otherwise exemplary: red lines held, hot-path forks removed, live-hook sequencing respected, ledger complete.
- **Spec/design-fidelity:** 8 findings — worst = **MAJOR** (A-1, NFR-1's numeric budget missed and absorbed into a READY verdict). Then 4 MINOR (A-2 unrecorded over-block class, A-3 the single false negative, A-4/A-5 honest-list inaccuracies) and 3 NIT.
- **Aggregate = the more severe of the two = MAJOR.**

---

## 10. Verdict

**CHANGES REQUESTED — 0 CRITICAL, 1 MAJOR, 5 MINOR, 5 NIT.**

I want to be unambiguous about what this does and does not ask for, because the expensive reading would be wrong: **the guard code is sound and I am not asking for a rewrite of any mechanism.** I attacked it independently — nested-frame quote restore, backtick push, `sq_ansi`, PARAM/ARITH interiors, here-doc smuggling, `bash <<EOF`, escaped-quote parity, `$'…'` divergence, carrier/`find` ordering, override self-authorisation at three call sites, depth accounting, empty-array expansion under `set -u`, and the fast-path derivation character by character — and found exactly **one** false negative (A-3), which is monotone, contrived, and strictly harder than a residual the guard already documents. The C-1 invariant, the C-2 restore, the C-3 ordering and the C-4 placement are all really there and really load-bearing, and the 49/32 anti-revert tally reproduces from the row set arithmetically. All fifteen gate conditions are genuinely DONE.

What closes this review:

1. **A-1 (MAJOR) → PM / requirement-analyst.** One recorded disposition: NFR-1's +20 ms clause waived against the measured figures and the O(n²) root cause (with the bounded ≤ ~2.3 s worst case and the no-timeout-risk note), plus a follow-up pool row for chunked indexing carrying the developer's fail-closed caveat. **No guard code change.**
2. **A-2, A-4, A-5, B-1 (MINOR) → developer.** Three rule-doc lines (add `bash <<EOF …` to the over-block table; drop `command rm` from residual 1; carry the PS-symmetry sentence into the `.tmpl`) and one dead-code decision. None touches guard behaviour; none requires a re-run beyond `verify_all` and the 81-row suite.
3. **A-3 (MINOR) → developer, or solution-architect if fixed rather than disclosed.** Either the one-flag fix to row 15's `prev` in both shells (plus a driver row `echo a\>& rm -rf OUT` → BLOCK) or one line in the residual list. I have a mild preference for the fix: it is one variable, it fails closed if wrong, and leaving a known false negative undisclosed in a document whose whole purpose is coverage honesty is the worse of the two.
4. **NITs** (A-6, A-7, A-8, B-2, B-3, B-4) are notes; do not block on them. A-6 is worth the 30 seconds because it is the headline security claim in the delivery record.

Two design documents carry statements that are now known-false and should be corrected at archive time rather than by an architect round: §3.1's unconditional `HDBODY` end-of-input failure (§5.1) and §10.3's ANSI-C evidence row (§5.2). Both drifts are **adjudicated as correct fixes-forward**; drift 1 is in fact required to satisfy AC-3 L9 at all, given that command substitution strips the trailing newline from every here-doc the guard ever sees.

---
---

# Code Review — ROUND 2 · T-17 `guard-cmd-chain`

- Stage 5 (code-reviewer), round 2 · Security task · Mode: **full**
- Inputs: `01_REQUIREMENT_ANALYSIS.md` (rounds 3+4), `02_SOLUTION_DESIGN.md`, `03_GATE_REVIEW.md` R2, `04_DEVELOPMENT.md` **ROUND 2**, my own round-1 report above.
- Method: **code reading only** (Read/Glob/Grep; no Bash, no `pwsh`). Every citation was opened. Line counts below were obtained with a ripgrep line count, which equals `wc -l` for newline-terminated files.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- _(Persisted verbatim by the PM Orchestrator: the code-reviewer agent has Read/Glob/Grep only and cannot write files.)_

---

## 1. Disposition of every round-1 finding

| Id | Sev (R1) | Status | What closed it |
|---|---|---|---|
| **A-1** | MAJOR | **CLOSED** | `01_REQUIREMENT_ANALYSIS.md` §7 NFR-1. Verified honest — see §2 below. No guard code change, as I asked. |
| **A-2** | MINOR | **CLOSED** | `75-safety-hook.md:100` / `.md.tmpl:86` extend the shell-interpreter over-block row with "…and `bash <<EOF … EOF`, whose here-document fragment is judged the same way"; pinned by row `H1` in all three artifacts. I traced `H1` end to end (row 10 queues `EOF`, EOF-in-`H` accepts the terminator, position `bash <<EOF` → shell branch → recursion on the token `<<EOF` → unterminated here-doc → `return 1` → exit 2). Non-vacuous: red under the scanner-disabled mutation and red pre-change. |
| **A-3** | MINOR | **CLOSED as reported, but the fix introduces CR2-1** — see §3. | Rows 12/15 in both shells + `R1`/`R2`/`R3`. |
| **A-4** | MINOR | **CLOSED** | `75-safety-hook.md:67-68` / `.md.tmpl:53-54`: `command rm` is now in the "**are**" half with the reason (`command` is a carrier). Both copies identical. |
| **A-5** | MINOR | **CLOSED** | `.md.tmpl:70-73` now ends residual 8 with "**The PowerShell twin is verified by symmetry only** until an operator runs it on Windows" — byte-matching the repo copy at `:84-87`. |
| **B-1** | MINOR | **CLOSED** | `skip_next` / `$skipNext` are gone (grep over `.harness/scripts` returns zero hits). `find_predicates` (`guard-rm.sh:136-139`) and `$findPredicates` (`.ps1:103-106`) are kept with the "historical documentation of the D-1/D-2 fix … Do not re-wire without a driver row" comment, both shells. The walk logic (`_walk_paths:761-785`, `Get-OffendingFromWalk:738-761`) is otherwise unchanged: `--` handling, flag skip and the D-1/D-2 NOTE all intact. |
| **A-6** | NIT | **CLOSED** | §Corrections: 19 AC-1 rows, 17 flipped, `a` and `d` did not. Correct. |
| **B-2** | NIT | **CLOSED** | `test-guard-rm.sh:158-160` — `W4` is now single-quoted via `'"'"'`, with the reason in a comment. |
| **B-3** | NIT | **CLOSED, and the developer is right, not me.** | Counted independently: `75-safety-hook.md` = **198**, `.md.tmpl` = **189**. My round-1 "198/188" was Read-tool numbering (which shows a phantom line for the trailing newline); `wc -l` is what gate I.2 uses. 2 lines of headroom on the repo copy; I.2 passes. |
| **B-4** | NIT | **CLOSED** | `75-safety-hook.md:101` / `.md.tmpl:87` carry the carrier over-block row with the captured `timeout 5 grep -r rm /etc` → 2 vs `./docs` → 0 boundary. |
| **A-7, A-8** | NIT | **Open by design** — rated record-only in round 1, not fixed, correctly so. §Open issues 4 names both and offers publication. Fine either way. |

---

## 2. Verification of the round-2 claims (they were claims; here is what I found)

**NFR-1 waiver record — honest, and round 4 did not blunt it.** `01_REQUIREMENT_ANALYSIS.md:347-404` leads with "**Clause 1 WAIVED … Clause 2 SATISFIED**", then says in its own sentence "**It was not met, and the delivered guard does not meet it**", then the measured table with "**+764 ms — the +20 ms clause missed by ~38×**" *before* any mitigating fact. Root cause, bounding facts, and "Who decided, and on what basis" (PM, Mode 2, the three named rubric lines, red lines checked, operator reversal path) all follow in that order. Round 4 touched only the "Residual obligation" paragraph and made the record *less* flattering, not more: it now states "**No pool row and no task-board entry exist for it at the time of writing**" and names the `/harness-stream` drain as the scheduling channel. The waiver heading, the miss, and the decision basis are byte-unchanged. **A-1 is properly closed.**

**Both anti-revert tallies re-derived from the code, independently.**

- **50/35.** Round 1's pre-change red set was 32 over 81 rows (I re-derived it last round and it matched). The four new rows: `R1` and `R2` are ALLOW pre-change (verb `echo`, expected BLOCK) → red; `H1` is ALLOW pre-change (no shell-interpreter branch existed; verb `bash` not destructive, expected BLOCK) → red; `R3` is ALLOW pre-change and expects ALLOW → green. 32 + 3 = **35 FAIL**, 49 + 1 = **50 PASS**. Matches the quoted run, and matches the transcribed red-row list at `04:720-722` member-for-member.
- **83/2, and it is the only evidence that round 2 is load-bearing.** Against the round-1 guard: all 81 original rows pass (that guard scored 81/0). `R3` — round-1 reads the raw byte at `i-1` = `>` → append → one position, verb `echo` → ALLOW = expected → green. `H1` — round-1 already had the scanner and the shell branch → BLOCK = expected → green. `R1`/`R2` — round-1 appends because the raw byte at `i-1` is `>`/`<`, so the whole line is one position with verb `echo` → ALLOW ≠ BLOCK → **red**. FAIL = **2**, exactly `{R1, R2}`; PASS = **83**. The round-2 fix is specifically pinned, not riding on round 1.
- **Mutation table.** scanner-disabled 18 → **21** is exactly 18 + `R1 R2 H1` (I traced each: without scanner positions all three collapse to `{s} ∪ split_pipes(s)`, whose verbs are `echo`/`echo`/`bash`, all ALLOW). Carrier 7 and prefix 8 correctly unchanged (no new row uses a carrier or a prefix). C-1 still **1**: `H1` survives a `plist+=("$s")` deletion because `split_pipes` re-supplies the whole string when there is no `|`, so `C14` remains the only row that mutation reddens. Internally consistent.
- **Three-way lockstep at 85**, counted by me in each artifact separately: `test-guard-rm.sh` 85 rows, `test-guard-rm.ps1` 85 `id =` entries, `evals/guard-rm-cases.md` 85 table rows, header updated to `85 ↔ 85`.
- **`CHANGELOG.md` against the artifact, not against arithmetic.** `CHANGELOG.md:49-54` now reads "Regression suite 17 → 85 rows … Run against the pre-change guard the same suite scores **50/35**." That is the figure printed by the run recorded at `04:714` and independently re-derived above. The fabricated `46/31` is gone. `baseline.json:23` = **85**, transcribed, with `_qa_note_t17` carrying the round-2 decomposition and the 50/35; still **no** `test_guard_rm_ps_assertions` key.
- **Rule docs 198 / 189**, counted. Cap 200. `[I.2]` passes with 2 lines of headroom.
- **Repo ↔ template parity**: `guard-rm.sh` 959/959 lines, `guard-rm.ps1` 923/923; the row-12/15 block in the template `.sh` is byte-for-byte the repo copy's `:543-565`, and the template `.ps1` carries `$redirIdx` at the same `:294-297 / :542 / :551`.
- **Nothing regressed from my round-1 PASS list.** `plist+=("$s")` unconditional at `guard-rm.sh:899` (C-1); step 2b override at `:101-111`, still between step 2 and the `.git/` walk at `:113` (C-4); carrier scan still has no `return` and `find` follows (`:839-877`, C-3); 9-member verb list unchanged at `:135`; the only `${var//…}` uses are the two pre-existing exempt lines `:90-91` (B-14); no `mapfile`/`declare -A`/`${v,,}` (bash-3.2); `CONTEXT.md` has exactly one `Command position` entry at `:100`; `baseline.json:10` `verify_all_checks: 32`; `plugin.json:4` still `0.46.0`; `_has_scanner_trigger` still twelve separate tests (C-12); both rule copies still carry the measured latency table and the retired-50 ms note.

---

## 3. Findings — axis A: Spec / design fidelity

### MAJOR

**CR2-1 · [LOGIC/SECURITY] The new `redir_i` sentinel collides with `i - 1` at `i == 0`: a command string whose first character is `&` is no longer split. New false negative, both shells, in the fail-OPEN direction.**
`guard-rm.sh:336` + `:558-565`; `guard-rm.ps1:297` + `:550-553`.

```bash
local redir_i=-1            # :336
...
if [[ "$ch" == "&" ]]; then
    if (( redir_i == i - 1 )); then _SP_BUF="${_SP_BUF}&"   # :559-560  <- true at i==0
    else _sp_flush; fi
```

At `i == 0`, `redir_i` is still its initial `-1` and `i - 1` is also `-1`, so the test is **true** and the scanner appends the leading `&` instead of flushing. PowerShell is identical and equally affected: `$redirIdx = -1` (`:297`), `if ($redirIdx -eq ($i - 1))` (`:551`) — `-1 -eq -1` → `$true`. Both are integer comparisons (so the round-2 operator note 8 about string `-eq` is satisfied), and the symmetry is exact — the defect is symmetric too.

Traced end to end for `& rm -rf /etc/harness-guard-probe`:

| | positions emitted | verdict |
|---|---|---|
| pre-change guard | `{s}` → verb `&` | ALLOW |
| **round-1 guard** | `&` at `i=0` → `prev=""` (guarded by `(( i > 0 ))`) → flush of an empty buffer → EOF flush emits `rm -rf /etc/harness-guard-probe` | **BLOCK** |
| **round-2 guard** | `&` appended → single position `& rm -rf /etc/harness-guard-probe` → `tokenize` → `_skip_prefix` breaks on `&` (not an assignment, not `sudo`, not in the reserved-word list at `:751`) → verb `&` → not destructive | **ALLOW** |

The C-1 union does not rescue it: `s` and `split_pipes(s)` are the same string and yield the same verb `&`.

Why this is MAJOR rather than a curiosity:

1. **It is a regression against the immediately preceding shipped state**, introduced by the fix under review, in a fail-closed security hook.
2. **It inverts the fix's own stated safety property.** The comment at `:551-552` / `.ps1:538-540` says "If this index is ever wrong the worst case is a flush, i.e. MORE positions — fail-closed." At `i == 0` the wrong index causes an **append** — fewer positions, fail-open. That comment is now false at exactly one input class, and it is the class nobody looked for.
3. **It violates a written boundary condition.** `01_REQUIREMENT_ANALYSIS.md` B-3 requires that an empty position between separators leave the "verdict unchanged from the same line without the empty position". `rm -rf OUT` BLOCKs; `& rm -rf OUT` now ALLOWs. Rows `N2` (`echo hi ; ; rm -rf ./build`) and `N3` (trailing `&&`) pin B-3 only in the ALLOW direction with in-project paths, so nothing in the 85-row suite, and none of the five mutations, can see this.
4. **There is an executable vector, not only a syntactic curiosity.** A leading `&` is a syntax error in bash, so the top-level bash form cannot run — but `&` is the PowerShell *call operator*, and the guard recurses into `pwsh -c` strings via `classify_command_string` (`:811`). So:

   ```
   pwsh -c "& Remove-Item -Recurse C:\Windows"     ->  round-1: exit 2   round-2: exit 0
   ```

   That is pinned fixture **row 8** (`pwsh -c "Remove-Item -Recurse C:\Windows"` → BLOCK) plus one character. The inner string's `&` sits at `i == 0` of the recursed scan, so the collision fires at depth 1 exactly as it does at depth 0.

Why it is **not** CRITICAL, so the PM can dispute the calibration: it is **not** an IS-2 / AC-4 violation — the pre-change guard also allowed both forms, so no BLOCK→ALLOW flip against the released baseline exists and AC-4's captured result stands. The guard is also no weaker than the residuals it already discloses (`/bin/rm`, `\rm`, `eval`, `$CMD` are all strictly easier). I rated round-1's A-3 MINOR on that same reasoning and I am not moving the bar; what makes this one MAJOR is that it is a *new* hole opened while closing another, in the direction the round claimed was unreachable.

**What closes it (small, and provably safe):**
- `guard-rm.sh:559` → `if (( i > 0 && redir_i == i - 1 )); then` (or initialise `redir_i=-2` at `:336`);
- `guard-rm.ps1:551` → `if ($i -gt 0 -and $redirIdx -eq ($i - 1))` (or `$redirIdx = -2` at `:297`);
- two driver/fixture rows in three-way lockstep — `R4` `& rm -rf OUT` → BLOCK, and `R5` `'pwsh -c "& Remove-Item -Recurse C:\Windows"'` → BLOCK (single-quoted per C-5). `R5` is the one that pins the executable vector; `R4` pins B-3.
- Direction of the fix is flush-ward, i.e. strictly more positions, so it cannot flip any ALLOW→BLOCK row of the existing 85 that does not begin with `&` — and no existing row does. Re-run the 85-row suite (expect 87/0 with the new rows) and the round-1/round-2/pre-change comparisons; the AC-4 corpus needs no re-harvest for the same reason as below (no corpus line begins with `&`; I checked all 55).

Owning stage: **developer**. Two tokens of code, two rows, one comment sentence that becomes true again.

### MINOR

**CR2-2 · [DOC/REASONING] `DESIGN DRIFT` 5's monotonicity argument is false as written, and it is the stated reason the AC-4 corpus was not re-run.**
`04_DEVELOPMENT.md:624-631` and the second "Insight to surface (round 2)" bullet at `:852-856`.

The claim is `{redir_i == i-1} ⊂ {raw byte at i-1 ∈ {>,<}}`, therefore "the append branch can only shrink and the flush branch only grow ⇒ the position set is a superset of the round-1 one ⇒ no BLOCK→ALLOW flip is reachable". Two independent defects:

1. **The subset relation fails at exactly one point — and that point is CR2-1.** Round-1's append predicate is `A₁ = { i : i > 0 ∧ s[i-1] ∈ {>,<} }` (its `prev` read is guarded by `(( i > 0 ))`). Round-2's is `A₂ = { i : redir_i == i-1 }`. `0 ∈ A₂` and `0 ∉ A₁`, so `A₂ ⊄ A₁`. The append branch did not only shrink; it **grew by one element**, and that element is a reachable false negative. The argument is not merely imprecise — believing it is what made the case invisible.
2. **Even where the subset does hold, "more flushes" is not "more positions".** A flush *replaces* one combined position `P` with two fragments `P₁`, `P₂` (`P₁ · & · P₂ = P`); `P` itself is lost. Counterexample I constructed and traced: `echo hi && rm -rf a\>& /etc/harness-guard-probe` — round 1 emits the position `rm -rf a\>& /etc/harness-guard-probe` and BLOCKs; round 2 emits `rm -rf a\>` and `/etc/harness-guard-probe`, neither of which blocks, and the C-1 union does not help because `s`'s verb is `echo`. So this line is BLOCK under round 1 and ALLOW under round 2. (This one is *benign* — bash really does parse `a\>` as the word `a>` and run `/etc/…` as a separate command, so round 1 was over-blocking and round 2 is correct. But it refutes the set-inclusion claim as stated.)

**The conclusion nevertheless survives, and the AC-4 non-re-run was the right call** — for a stronger reason than the one given. IS-2 is defined against the **pre-change** guard, and round 2 did not touch `plist+=("$s")` or `split_pipes`, so every position the pre-change guard judged is still judged; BLOCK→ALLOW against the baseline remains structurally unreachable. I also verified the empirical bound myself: **none of the 55 enumerated corpus lines contains `>&` or `<&`** (I read the full per-line table), and separately, every `[<>]&` occurrence anywhere in the declared source artifacts is `2>&1`, which is precisely the *unchanged* branch (a real `>` operator at NORMAL, `redir_i == i-1` in both rounds — row `R3`'s branch). So no corpus line can move, with or without the argument. **AC-4's proof obligation is met; the corpus did not need re-running.**

**What closes it:** correct the drift-5 paragraph to the argument that actually holds (IS-2 is measured against the retained pre-change pass, which round 2 did not touch; the `[<>]&` filter bounds the corpus), and **do not surface the second round-2 insight in its current form** — "re-run the differential when the row set changes, not when the code changes in a provably narrowing direction" is a rule that, applied as written, produced CR2-1. If an insight is worth keeping here, it is the inverse one: *a sentinel compared against a derived index must be unreachable by that index's domain* (`-1` vs `i-1` at `i=0`). Owning stage: **developer** (doc), or the PM at archive time.

### NIT

- **CR2-3 · [DOC]** `04_DEVELOPMENT.md:636-642` quotes a `grep -n '[<>]&'` over README, getting-started, `hook-spec.{sh,ps1}` and `_archived/*/04_DEVELOPMENT.md`, `04_IMPLEMENTATION.md`, `06_TEST_REPORT.md`, with a single hit (`hook-spec.sh:60`). The same pattern over the same declared set returns **seven more** in-scope hits — `_archived/hook-truth-spec/04_DEVELOPMENT.md:39,268,269,348`, `_archived/hook-truth-spec/06_TEST_REPORT.md:148,456`, `_archived/harness-upgrade-skill/04_DEVELOPMENT.md:55`. All are prose mentions of `2>&1` inside sentences, none is a fenced command line or a `Command:` line, and all are the provably-unchanged branch — **the conclusion is unaffected**. But the quoted output does not reproduce over its own stated file set, which is the same class of defect as the `46/31` CHANGELOG figure this round corrected. Worth one line, not a round.
- **CR2-4 · [TEST]** `R3b` (`… 2>&1 …` in a chain) was captured as a probe but not promoted to a driver row. Not a gap of substance — `R3` already pins the append branch, and `2>&1 &&` never consults `redir_i` because the `two == "&&"` test precedes the single-`&` test in both shells. Record only.

---

## 4. Findings — axis B: Standards conformance

**No CRITICAL, no MAJOR, and nothing new.** The round-2 change followed the same discipline as round 1, and I checked each mechanism rather than the claim:

- Live-hook edit sequence honoured again: template first, `bash -n`, driven via `[guard-path]`, one `sync-self` run, `--check` → `In sync.`; the repo copy written exactly once per shell. Repo↔template line counts agree (959/959, 923/923) and the changed regions are byte-identical in both copies of both shells.
- Check count frozen at 32; `verify_all.{sh,ps1}` untouched; `CONTEXT.md` untouched; `docs/tasks.md` / `BATCH_PLAN.md` correctly left to the PM; `docs/proposals/frontier-gaps-2026-07.md` still not present and not cited.
- Rule docs at 198/189 against the hard 200 cap, and residual 1 was rewritten to stay at two lines rather than reflow to three — the right instinct with 2 lines of headroom.
- Row quoting: `R1`/`R2`/`R3` single-quoted in both drivers; `H1` uses the sanctioned `` `n `` double-quoted exception for a separator row and contains no `$`, `` ` `` or `$(`; `W4` fixed per B-2. C-5 now holds without exception.
- bash-3.2 safety, `patsub_replacement` avoidance, empty-array-under-`set -u` idioms, `[void]`-casting of every `List.Add`/`StringBuilder.Append` in the PS twin — all unchanged and all still clean in the new code.
- Dead code genuinely deleted rather than commented out; the surviving declaration carries the ledger comment I asked for, in both shells.

**Standards-conformance: no findings.**

---

## 5. PowerShell parity for the new logic (read-only; `pwsh` absent)

I read the new PS code against the same hazard list as round 1 and found **the same semantics, including the same defect** — which is the right kind of parity even though the defect is wrong.

| Hazard | Result for the row-12/15 change |
|---|---|
| Whole-file parse | `$redirIdx = -1` and `if ($redirIdx -eq ($i - 1))` are plain constructs; no backtick literal, no here-string, nothing that could fail to parse in a never-taken branch |
| Automatic-variable collision | `$redirIdx` is not a PS automatic variable; declared inside the function's `try` block, so function-scoped, initialised **before** the loop at `:297` (operator item 8's exact question — satisfied) |
| Integer vs string `-eq` | Both operands are `[int]`: `-1` literal, then `$redirIdx = $i` where `$i = 0` / `$i += 1`. No string coercion, no mis-branch. Operator item 8 is satisfied as written |
| .NET throw where bash yields `""` | The new code adds no indexing at all — it compares two integers. No new `Get-Slice`-bypass, no new `$s[$i]` outside a `while ($i -lt $len)` guard |
| Same scoping | `$redirIdx` is assigned only in the row-12 branch inside `if ($stIn -eq 'N')`, exactly like bash's `redir_i`; it survives frame pushes/pops identically, and is never touched by `Add-ScannerPosition` / `Pop-NestFrame` |
| Same order of dispatch | Row 12 → `&&` → `&>` → single `&` → `\|` → `;` → frames, identical ordering at `.ps1:541-556` and `.sh:553-567` |
| `Add-ScannerPosition` ≡ `_sp_flush` | `.ps1:231-239` trims and skips blank, same as `.sh:271-276`. (`.Trim()` trims Unicode whitespace where bash trims `[:space:]` — pre-existing, not new.) |

**The index scoping is correct in both shells**, and I checked it against the hazards the dispatch named rather than assuming: a frame push/pop, a flush, a quoted region, `&>`, `>|`, `>>`, `2>&1`, `<<`, `<<<`, `<(`/`>(`, and consecutive redirects (`echo a > b >& c`). `redir_i == i-1` requires *adjacency*, and every push and every pop consumes a character, so a stale index can never be adjacent to an `&` in a different frame — the single scanner-wide variable is sound and needs no per-frame save/restore. `<<`, `<<<`, `&>` and `>(` all deliberately leave `redir_i` unset, so the following `&` flushes; each of those divergences from round 1 is a bash syntax error or a degenerate form, and all are flush-ward. The one case that is *not* sound is CR2-1, and it is symmetric across both shells.

Operator list item 8's probes should gain the CR2-1 vector: `& rm -rf C:\x` (expect 2) and `pwsh -c "& Remove-Item -Recurse C:\Windows"` (expect 2). Item 9's "85 rows" becomes 87 if CR2-1 is fixed with the two rows I suggest.

---

## 6. The four new rows

| Row | Load-bearing? | Verdict |
|---|---|---|
| `R1` `echo a\>& rm -rf OUT` → BLOCK | **Yes, uniquely.** Red against the round-1 guard and against the scanner mutation and pre-change. Traced: row 1 consumes `\>`, `redir_i` stays `-1`, `&` flushes, position 2 = `rm -rf /etc/…` (leading space trimmed by `_sp_flush`, so `tokenize` sees `rm` as token 0) → BLOCK | PASS |
| `R2` `echo a\<& rm -rf OUT` → BLOCK | Same, `<` arm | PASS |
| `R3` `echo a>& rm -rf OUT` → ALLOW | **Not a discriminator of round 1 vs round 2** (green under both) — and that is correct for an ALLOW-side boundary. It *is* non-vacuous: I traced an "always flush" regression and `R3` goes red under it (positions `echo a>` + `rm -rf /etc/…` → BLOCK). It also states the right expectation semantically: bash reads `>& rm` as a redirect to a file named `rm`, so nothing is deleted | PASS |
| `H1` `bash <<EOF` + LF + `rm -rf OUT` + LF + `EOF` → BLOCK | **Yes.** Red pre-change and red under the scanner mutation. Genuinely exercises the disclosed mechanism (shell-interpreter branch judging the here-doc fragment), not a coincidence | PASS |

Three-way lockstep at **85 / 85 / 85** confirmed by counting each artifact separately; the fixture header reads `85 ↔ 85`. The ids match across all three.

---

## 7. Requirement coverage — deltas from round 1 only

| Criterion | Round-2 status |
|---|---|
| AC-1 bypass matrix | PASS (unchanged; prose corrected per A-6) |
| AC-3 legitimate corpus | PASS (unchanged) |
| AC-4 differential, 0 BLOCK→ALLOW | **PASS.** Non-re-run justified — verified independently (no corpus line contains `[<>]&`; the retained pre-change pass is untouched). The *stated* justification is faulty → CR2-2 |
| AC-8 gate green, 32 checks | PASS; I.2 at 198/189 |
| AC-9 documentation truth | **PASS** — A-2/A-4/A-5/B-4 all landed in both copies. Round 1's WARN is cleared |
| AC-10 driver anti-revert | PASS, strengthened: five mutations, the new one reddening exactly `{R1, R2}` |
| AC-11 live-guard continuity | PASS |
| **IS-1 row 2 (`A & B` totality)** | **FAIL for the degenerate `A` = empty → CR2-1.** Round 1's WARN on this row is otherwise cleared (the `\>&` hole is genuinely gone) |
| **B-3 (empty position between separators)** | **FAIL for a leading `&` with an outside path → CR2-1.** `N2`/`N3` pin only the in-project ALLOW direction |
| IS-2 monotonicity (vs **pre-change**) | PASS — structurally, via the untouched `{s} ∪ split_pipes(s)` retention |
| IS-8 documentation truth | PASS (A-5 closed) |
| NFR-1 latency | **PASS as waived** — clause 1 waived and recorded honestly; the developer's A/B (42→43 / 35→35 / 2213→2130 ms) shows round 2 moved nothing, so the shipped measured table still describes the shipped guard |
| All others | Unchanged from round 1 |

**Design fidelity:** `DESIGN DRIFT` 5 is the correct *direction* of change (the design's raw-`i-1` rule is a false-negative generator and had to go) and belongs with drifts 1 and 2 as an archive-time correction to §3.1 rows 12/15 — **not** an architect round. Its implementation is what CR2-1 and CR2-2 are about, not its existence.

---

## 8. Axis status

- **Standards-conformance: no findings.** Red lines held, live-hook sequencing respected again, dead code removed cleanly, quoting rule now exception-free, line-count discipline correct, ledger complete. One evidence-hygiene NIT (CR2-3) attributes here at most and blocks nothing.
- **Spec/design-fidelity: 4 findings — worst = MAJOR** (CR2-1, a new false negative introduced by this round's fix, fail-open, violating written boundary B-3 and IS-1 row 2). Then 1 MINOR (CR2-2) and 2 NIT (CR2-3, CR2-4).
- **Aggregate = the more severe of the two = MAJOR.**

Round-1 carry-over: **0 open.** All ten routed findings are closed; A-7 and A-8 remain record-only as rated.

---

## 9. Verdict

**CHANGES REQUESTED — 0 CRITICAL, 1 MAJOR, 1 MINOR, 2 NIT.**

I want to be precise about the size of this, because the expensive reading would be wrong: **round 2 did what it was asked to do.** All ten round-1 findings are genuinely closed — I re-opened each one in the code rather than reading the disposition table. The A-3 fix is the right fix, and I audited it as new code: the recorded index is correctly scoped across frame pushes and pops, flushes, quoted regions, `&>`, `>|`, `>>`, `2>&1`, `<<`, `<<<`, `<(`/`>(` and consecutive redirects, and the adjacency requirement makes the single scanner-wide variable sound without per-frame save/restore. Both tallies I was asked to re-derive reproduce exactly (50/35 and 83/2), the mutation table is internally consistent with my own traces, the lockstep really is 85/85/85, the rule docs really are 198/189, the CHANGELOG really does now match the captured run, and nothing on my round-1 PASS list moved.

What blocks is one line:

1. **CR2-1 (MAJOR) → developer.** `redir_i` / `$redirIdx` is initialised to `-1`, which is `i - 1` at `i == 0`, so a leading `&` is appended instead of flushed. `& rm -rf OUT` and — the executable one — `pwsh -c "& Remove-Item -Recurse C:\Windows"` now ALLOW where the round-1 guard BLOCKed. Fix: `(( i > 0 && redir_i == i - 1 ))` / `($i -gt 0 -and $redirIdx -eq ($i - 1))`, or a `-2` sentinel; plus rows `R4`/`R5` in three-way lockstep. Re-run the 85→87 suite and the three comparison runs; **the AC-4 corpus does not need re-harvesting** (no corpus line begins with `&`; I checked all 55).
2. **CR2-2 (MINOR) → developer, doc only.** Correct drift 5's monotonicity paragraph to the argument that actually holds, and do not surface the round-2 "don't re-run the differential when the change is provably narrowing" insight as written — it is the rule that produced CR2-1.
3. **CR2-3, CR2-4 (NIT)** are notes; do not block.

The design documents still carry three statements that are now known-false and should be corrected at **archive time** by the PM rather than by an architect round: §3.1's unconditional `HDBODY` end-of-input failure (drift 1), §10.3's ANSI-C evidence row (drift 4), and §3.1 rows 12/15's raw-previous-byte rule (drift 5). All three drifts are adjudicated as correct fixes-forward.

---
---

# Code Review — ROUND 3 · T-17 `guard-cmd-chain`

- Stage 5 (code-reviewer), round 3 · Security task · Mode: **full**
- Inputs: `05_CODE_REVIEW.md` rounds 1–2 (my own), `04_DEVELOPMENT.md` **ROUND 3**, the shipped code.
- Method: **code reading only** (Read/Glob/Grep; no Bash, no `pwsh`). Every citation was opened. Row/line counts below were obtained with an independent ripgrep count over the files themselves, not read from the record.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- _(Persisted verbatim by the PM Orchestrator: the code-reviewer agent has Read/Glob/Grep only and cannot write files.)_

---

## 1. Disposition of CR2-1 … CR2-4

| Id | Sev (R2) | Status | What closed it |
|---|---|---|---|
| **CR2-1** | MAJOR | **CLOSED — fix verified at the source, not at the call site** | `.harness/scripts/guard-rm.sh:341` `local redir_i=-2`; `.harness/scripts/guard-rm.ps1:303` `$redirIdx = -2`; template copies byte-identical at the same line numbers. Sentinel unreachability proved below, not accepted. Pinned by `R4`/`R5` in three-way lockstep, red under two independent mutants. |
| **CR2-2** | MINOR | **CLOSED** | Round-2 prose annotated `[SUPERSEDED]` (`04:624-629`, `04:651-655`), `[AMENDED]` (`04:782-787`), `[WITHDRAWN]` (`04:872-879`); the corrected argument at `04:1020-1072`. Its part 1 — "IS-2 is measured against the retained pre-change pass, which neither round touched" — I re-verified in the code: `guard-rm.sh:908` `plist+=("$s")` is still unconditional at every depth and `split_pipes` (`:223-247`) is byte-unchanged. That is the argument that actually holds, and it is the one now written down. The round-2 insight is withdrawn rather than re-worded; the inverse insight (`04:1274-1284`) is the correct one. |
| **CR2-3** | NIT | **CLOSED, and it reproduces** | I re-ran the same pattern over the same declared set myself. In-scope hits: `.harness/scripts/hook-spec.sh:60`; `_archived/hook-truth-spec/04_DEVELOPMENT.md:39,268,269,348`; `_archived/hook-truth-spec/06_TEST_REPORT.md:148,456`; `_archived/harness-upgrade-skill/04_DEVELOPMENT.md:55` — **8**, file-for-file and line-for-line identical to the quoted re-run at `04:1086-1093`. All seven new ones are prose `2>&1` mentions; conclusion unaffected. |
| **CR2-4** | NIT | **DECLINE ACCEPTED — the decision is right, the stated reason is not** | See §5. Downgraded to a one-line prose correction (CR3-2). |

Round-1 and round-2 carry-over: **0 open.** A-1's NFR-1 waiver record is untouched and still true — round 3 adds one integer literal evaluated once per `Split-CommandPositions` call, the rule docs' measured table was not edited, and the rule docs are byte-unchanged this round (198 / 189, counted).

---

## 2. Focus 1 — the sentinel audit, done at the source

The property the fix claims is *"`-2` is outside the domain of `i - 1` over this loop."* I did not accept it; I discharged it.

**Bash (`guard-rm.sh:322-648`).**

1. **Only assignment.** Grep over the whole tree: `redir_i` is written in exactly two places — `:341` (`local redir_i=-2`) and `:563` (`redir_i=$i`, inside row 12) — and read in exactly one, `:568`. There is no path that assigns it anything other than `$i` or the sentinel.
2. **`i`'s domain.** `i` is `local i=0` (`:332`) and every mutation in the function is `i=$(( i + 1|2|3 ))` — I enumerated all 43 of them by grep, including the multi-character consumers: row 1 `\`+next (`:426`, +2), row 5 `$((` (+3), rows 6/7/11 (+2), row 9 `<<<` (+3), row 10's here-doc delimiter scan (`:502-537`, +1 per byte and +1 for the backslash pair), rows 12–23 (+1 or +2), and the verbatim-frame block (`:350-378`, +1/+2/+3). **Nothing decrements `i`; nothing assigns it a non-derived value.** No helper (`_sp_flush`, `_sp_settop`, `_sp_push_v`, `_sp_pop_v`, `_sp_push_cmd`, `_sp_pop_cmd`) touches `i` or `redir_i` — I read all six.
3. **Value of `i` at the test.** Between the loop head (`:344`) and row 15 (`:567`), every branch that modifies `i` also `continue`s. So at `:568` `i` still satisfies the loop guard `0 ≤ i ≤ len-1`, hence `i-1 ∈ {-1 … len-2}` and `redir_i == i-1` can never be satisfied by `-2`. **The comment at `:556-561` is now true**, and it is true for the reason it states.
4. **Staleness cannot forge adjacency.** `redir_i == i-1` requires `i == redir_i + 1`, which is exactly the state one iteration after row 12 fires. Every subsequent iteration advances `i` by ≥1, so a stale index is permanently unequal → flush → more positions → fail-closed. Frame pushes/pops (`:471`, `:489`, `:544`, `:579`, `:585-588`) each consume ≥1 character, so a `>` recorded inside a frame can never be adjacent to an `&` outside it. This is why a single scanner-wide index needs no per-frame save/restore — same conclusion as round 2, re-derived against the new sentinel.
5. **Re-entrancy.** `redir_i` is `local`. `split_positions` calls no classifier, so it is never on its own stack; and the recursion that does exist (`classify_command_string` → `classify_segment` → `classify_command_string`, `:820`/`:837`/`:858`) enters a *fresh* `split_positions` whose `local redir_i=-2` shadows and restores. Verified.

**PowerShell (`guard-rm.ps1:273-637`).** Same discharge, plus the two PS-specific questions the dispatch asked:

- `$redirIdx = -2` (`:303`) is **unconditional**, inside the function's `try` block, **before** `$i = 0` (`:305`) and the `while` (`:307`) — no branch can reach the read at `:561` with `$redirIdx` unassigned. There is no `$redirIdx` in any other scope in the file.
- **No type coercion.** `-2` is a unary-minus integer literal → `[int]`; `$i = 0` → `[int]`, mutated only by `$i += 1|2|3` (I grepped all 43 sites — no `-=`, no `--`, no reassignment). `-eq` with an `[int]` left operand coerces the right operand to `[int]`, so `$redirIdx -eq ($i - 1)` is a numeric comparison. Operator item 8's exact question is satisfied by the `-2` form as it was by `-1`.
- The only other write is `$redirIdx = $i` (`:552`), inside `if ($stIn -eq 'N')`, exactly as in bash. Dispatch order at `:551-564` is identical to `.sh:562-574` (row 12 → `&&` → `&>` → single `&` → `|` → `;` → frames).

**Consequence, stated exactly.** Changing `-1` → `-2` alters the outcome of `redir_i == i-1` **only** when `redir_i` is still the sentinel *and* `i == 0` — and at `i == 0` no prior record can exist. So the behavioural delta of round 3 is precisely: *the `&` dispatch at index 0 of a scan, when the next character is neither `&` nor `>`*. That is one input class, provable rather than measured, and it matches the developer's claim at `04:994-996`.

---

## 3. Focus 2 — the two bypasses, and my attempt at a 23rd

**Both were real, in both directions.** `bash -c "& rm -rf OUT"` (E11) and `&rm -rf OUT` (E15) are the same `i == 0` collision as `R4`/`R5`: under the `-1` sentinel the `&` is appended, `tokenize` yields token 0 = `&` (or `&rm`), `_skip_prefix` (`:731-766`) breaks on it (not an assignment, not `sudo`, not in the reserved-word list at `:760`), the verb is not destructive, and the C-1 union does not rescue it because `{s} ∪ split_pipes(s)` is the same string with the same verb. Under `-2` the `&` flushes an empty buffer and the position becomes `rm -rf /etc/harness-guard-probe` → BLOCK. E11 additionally proves it at depth 1 through the shell-interpreter branch (`:832-842`), the twin of `R5`'s `pwsh -c` path (`:813-826`). The exit-0-before / exit-2-after captures are consistent with the code on every one of the 22 probes I re-traced.

**Blast-radius coverage.** The probe set hits `i == 0`, `i == len-1` (E4), `GROUP_PAREN` (E6), `CMDSUB` (E7), post-flush (E8), both recursion branches at depth 1 (E11 `bash -c`, E12 `sh -c`, R5 `pwsh -c`), the real-redirect boundary (E9, R3), the in-project ALLOW side (E10, E12), the degenerate forms (E1, E5, E13, E14) and the `&&`/`&>` neighbours (E2, N3). That is the right partition, and E6/E8 correctly demonstrate the negative claim ("`i` is not reset by a frame push, so the defect was `i == 0`-only").

**I tried to build a 23rd and could not, and I can say why rather than just report failure.** I enumerated the dispatch for *every possible first character* of a fresh scan at `st == N` with an empty frame stack: `\` (row 1, +2, yields the harmless word `&`), `'`/`"` (SQ/DQ; unbalanced → `:634` → BLOCK), `` ` `` (BQ push), `$` (rows 5/6/7), `<`/`>` (row 12), `&` (now flushes), `|`, `;`, `\n`, `\r` (flush), `(` (flush+push), `)` (flush), `{` (empty buffer → flush+push), `}` (append), `#` (comment), ordinary (append). **`i == 0` is now total.** For the append branch to fire at all, the immediately preceding byte must have been recorded by row 12 as an operator `>`/`<` at NORMAL — and in both bash and PowerShell the `>&word` / `<&word` forms make `word` a redirect target or an ambiguous-redirect error, never a command, which is exactly what `R3` asserts. I checked `>>&`, `>&&`, `&>`, `&>foo`, `1>&`, `2>&1`, consecutive redirects and frame-straddling `>` … `)` … `&` individually; all are either flush-ward (fail-closed) or genuinely non-executing.

**What I did find is one class over, and it is pre-existing — see CR3-1.**

---

## 4. Focus 3 — the marker correction is true of the code

Confirmed by grep over `.harness/scripts`:

- `test-guard-rm.sh:263` → `echo "=== test-guard-rm summary ==="`; `test-guard-rm.ps1:211` → the same string. **There is no `=== Result ===` in either guard driver.**
- `=== Result ===` belongs to `test-init.sh:1068`, `test-real-project.sh:288` (and the PS twins at `:1305` / `:260`) — the two collateral suites the record quotes it against, correctly.
- `verify_all.sh:804` → `=== Summary ===`, which is what the record quotes for `verify_all`.

So the per-driver marker checks are the right ones, `grep -c` = 1 for `=== test-guard-rm summary ===` is the correct presence check for the five guard-driver runs, and the developer is right that asserting `=== Result ===` on the guard driver would have been a fabricated check. This is the correct instinct applied against its own evidence-hygiene weakness, and it is the first round where that weakness produced no defect.

---

## 5. Focus 4 — CR2-4's decline

**The decline is correct. The reason given is wrong, and the wrong reason is originally mine.**

`R3b` is `ls . 2>&1 && echo ok`. Its single `&` **does** consult the index: at that offset `two` is `&1`, which is neither `&&` (`:565`) nor `&>` (`:566`), so control reaches row 15 (`:567`) and takes the *append* branch because `redir_i == i-1`. What never consults the index is the *trailing* `&&`, which the `two == "&&"` test claims first. The sentence "`2>&1 &&` never consults the index" — written by me in round 2 at `05:368` and repeated by the developer at `04:919` and `04:1107` — conflates the two `&`s.

The **conclusion survives intact**, and I re-derived it rather than assuming: `R3` already exercises the identical append branch and is a *stronger* discriminator (`R3` goes red under an always-flush regression; `R3b` stays green under it, because its fragments `ls . 2>`, `1`, `echo ok` all ALLOW). `R3b` is green under pre-change, round 1, round 2, round 3 and all six mutants, and no mutation in the anti-revert set can redden it. **A row no mutation can redden is row-set inflation** — that judgement is right, the three-way lockstep cost is real, and declining with a recorded reason is the correct disposition. Only the sentence needs a correction (CR3-2, NIT).

---

## 6. The three tallies I was asked to re-derive — all reproduce

**87 rows vs pre-change → 50 / 37.** Round 2's pre-change red set was 35 over 85 rows (re-derived last round, matched). The two new rows against the pre-change guard: positions are `{s} ∪ split_pipes(s)` only, and `split_pipes` (`:223-247`) splits on `|` **alone**, so `& rm -rf OUT` stays one string → `tokenize` token 0 = `&` → `_skip_prefix` breaks → verb `&` → ALLOW ≠ BLOCK → **red**; `pwsh -c "& Remove-Item …"` reaches the pre-existing pwsh branch, recurses on the inner string, and yields verb `&` → not a pwsh verb → ALLOW ≠ BLOCK → **red**. 35 + 2 = **37 FAIL**, PASS unchanged at **50**. I also counted the transcribed red list at `04:1203-1204` id-by-id: **exactly 37**, and exactly round 2's 35 plus `R4 R5`.

**87 rows vs round-1 guard → 85 / 2, red `{R1, R2}`.** The round-1 guard read the raw byte at `i-1` **guarded by `(( i > 0 ))`**, so at `i == 0` `prev` is `""` → not `>`/`<` → flush. `R4` and `R5` therefore **pass** against round 1; `R1`/`R2` fail as before; `R3`/`H1` pass. 85 / 2, red `{R1, R2}`. Confirmed.

**87 rows vs round-2 guard (`-2` → `-1`) → 85 / 2, red `{R4, R5}`.** Round 2 scored 85/0 on its own 85 rows, and the two new rows are precisely the sentinel collision. 85 / 2, red `{R4, R5}`. Confirmed.

**The separation holds arithmetically, and it carries the two claims it is supposed to carry.** `{R1,R2}` and `{R4,R5}` are disjoint; round 1 is *green* on `R4`/`R5`, which is the positive evidence that **CR2-1 was a regression opened by round 2, not a pre-existing hole**; and round 2 is red on `{R4,R5}` alone, which is the positive evidence that **round 3's one-token fix is individually load-bearing** and that nothing else in the 87 rows depends on it. The mutation table is likewise consistent with my traces: scanner-disabled 21 → 23 (`R4`/`R5` collapse to the `{s} ∪ split_pipes` verb `&` → ALLOW); carrier 7, C-1 1, prefix 8 unchanged, correctly — `R4`/`R5` use no carrier, no prefix, and survive a `plist+=("$s")` deletion because the scanner alone supplies `rm -rf OUT`.

**Lockstep 87/87/87, counted by me in each artifact separately, not read from the record:** `test-guard-rm.sh` 87 stride-4 rows, `test-guard-rm.ps1` 87 `@{ id = '` entries, `evals/guard-rm-cases.md` 87 id rows across five sections (17 + 19 + 14 + 6 + 31), header `87 ↔ 87` at `:14`.

---

## 7. Focus 5 — nothing regressed, checked against the artifacts

Against the **captured runs**, not arithmetic, as instructed:

- **`CHANGELOG.md:45-60`** — the new sentinel bullet (`:49-54`) states the defect, the two inputs, the PowerShell call-operator reason and the `-2` remedy accurately; "17 → **87** rows"; "Run against the pre-change guard the same suite scores **50/37**" — the figure this round's run printed. No stale figure survives; the round-1 `46/31` and round-2 `50/35` are both gone from the entry.
- **`baseline.json:23`** = `test_guard_rm_bash_assertions: **87**`, transcribed. `_qa_note_t17` (`:24`) carries the round-3 decomposition (81 + 4 + 2 = 87), the captured **50/37**, **both** single-fix comparison runs with their red sets `{R1,R2}` and `{R4,R5}`, the amended operator instruction at **87** rows, and the two new PS probes. **Still no `test_guard_rm_ps_assertions` key**, with the "do not invent one" warning intact. `verify_all_checks: 32` at `:10`.
- **Standing PASS list, re-opened in the code (not the record):** C-1 `plist+=("$s")` unconditional at `guard-rm.sh:908`; C-4 override at `:101-111`, still step 2b between the env override and the `.git/` walk at `:113`, still the only place the override is evaluated; C-3 carrier scan `:848-866` has **no `return`** and the `find -delete` branch follows at `:869`; verb set 9 members at `:135` with the mechanical twin; C-12 `_has_scanner_trigger` still **twelve separate `[[ ]]` tests** (`:654-668`), `&` present at `:657` so `R4`/`R5` reach the scanner; the only `${var//…}` uses are the two pre-existing exempt lines `:90-91` (B-14); no `mapfile` / `declare -A` / `${v,,}` (bash-3.2); `CONTEXT.md:100-102` has exactly one `Command position` entry; rule docs **198 / 189** by line count, byte-untouched this round, with A-2/A-4/A-5/B-4's round-2 fixes all still present in **both** copies (`.tmpl:54, 73, 86, 87`); version stamps `0.46.0` in all four required places; `docs/dev-map.md:102,106` still accurate.
- **Repo ↔ template parity:** `guard-rm.sh` **968 / 968**, `guard-rm.ps1` **933 / 933**, and I opened the changed regions in both template copies — `templates/…/guard-rm.sh:333-342` and `templates/…/guard-rm.ps1:294-305` are byte-identical to the repo copies at the same line numbers. Consistent with the captured `sync-self --check → In sync.`
- **Row quoting (C-5):** `R4`/`R5` are single-quoted in both drivers (`test-guard-rm.sh:182-183`, `test-guard-rm.ps1:180-181`); `R5` contains `"` and `\` and no `$`, `` ` `` or `$(`. The payload is JSON-encoded and piped to the guard, never evaluated. No execution hazard.

---

## 8. Focus 6 — PowerShell parity for the sentinel (read-only; `pwsh` absent)

| Hazard | Result |
|---|---|
| Whole-file parse | `$redirIdx = -2` is a plain integer assignment; the added lines are `#` comments. Nothing that could fail to parse in a never-taken branch. |
| Automatic-variable collision | `$redirIdx` is not a PS automatic; single scope; no new variable introduced this round. |
| Uninitialised read | Impossible: `:303` is unconditional and precedes `$i = 0` and the loop. |
| Type coercion | `[int]` on both sides at `:561`; only writes are `-2` and `$i`. |
| `$i` domain | `$i = 0` (`:305`), only `+= 1\|2\|3` across all 43 sites; loop guard `$i -lt $len`. `-2` unreachable, same proof as bash. |
| Same semantics | Row order at `:551-564` matches `.sh:562-574` cell-for-cell; comment text at `:294-302` / `:538-550` is the same argument in PS spelling. |

**Parity is exact, including the reasoning written into the comments.** The residual is unchanged and now sharper: the defect existed identically in `.ps1`, was fixed identically, and "identically" is still a reading rather than a run. Operator item 8 (amended), item 9 (87 rows) and the new item 10 correctly mark this a **security** item, not polish — `pwsh -c "& …"` is a PowerShell vector and the PowerShell guard has never executed.

---

## 9. Findings

### Axis A — Spec / design fidelity

#### MINOR

**CR3-1 · [LOGIC/DOC] A leading redirection hides the verb of its own position — `> /tmp/log rm -rf /etc/x` exits 0 and bash runs the `rm`. Pre-existing, monotone, and *not* disclosed.**
`guard-rm.sh:731-766` (`_skip_prefix`), `:191-218` (`tokenize`), `.harness/rules/75-safety-hook.md:57` and `:63-87`.

This is the class adjacent to CR2-1 that the sentinel fix does not touch, and it is the one thing I found in three rounds that a competent adversary would reach for before `\rm`. `tokenize` splits on whitespace only, so `> /tmp/log rm -rf /etc/x` yields token 0 = `>`; `_skip_prefix` recognises assignment prefixes, `sudo` and reserved words, and nothing else, so it breaks immediately; `verb` = `>` → `_is_destructive_verb` fails → `classify_segment` returns → **ALLOW**. The scanner is irrelevant here — the position is correct, the *verb within it* is not at token 0. The same holds for `2>/dev/null rm -rf /etc/x`, `2>&1 rm -rf /etc/x`, `>>f rm -rf /etc/x`, and at every position of a chain (`echo hi && > f rm -rf /etc/x`). Bash executes the `rm` in every one of these forms.

Calibration, stated plainly because the PM asked for it:
- It is **not** a regression. The pre-change guard behaves identically (same `tokenize`, same first-token rule), so IS-2, AC-4 and the captured 0 BLOCK→ALLOW all stand. Nothing in this round or the two before it made it reachable.
- It is **outside AC-1's matrix**, which is about a verb reached through *chaining*. This task fixed reachability of positions; this is reachability of the verb *inside* a position.
- The guard already discloses strictly easier bypasses (`\rm`, `/bin/rm`, `eval "$X"`, `$CMD`), so the security posture does not move.
- It is the same family as round 1's **A-8** (`'' rm -rf /etc/x`) and **A-7** (`xargs bash --rcfile foo -c "…"`), both rated record-only, and residual 5 (`a[0]=1 rm …`) already publishes one member of the family.

What is genuinely defective is the **disclosure**, in the task whose deliverable is coverage honesty: the coverage table's redirection row (`:57` "Redirection operators and targets … Not command positions") is true but reads as reassurance, and no residual names the family.

**What closes it — documentation, one line, no guard change and no re-run of any suite:** extend residual 5 (or add residual 9) in **both** rule copies to name the family — *a leading token that is not a recognized prefix hides the verb: a redirection (`> f rm -rf /etc/x`, `2>&1 rm …`), an empty token (`'' rm …`), an array-element assignment (already listed)*. Line budget is fine: 198 → 199 and 189 → 190 against the hard 200 cap, so `[I.2]` still passes. **This does not require a stage-4 rollback** — it is a doc line the PM can route to whoever is cheapest, and a follow-up pool row for the fix (note: any fix must be flush-ward/over-blocking, because skipping a leading `>` token would turn `R3`'s `>& rm` boundary into a false BLOCK — that is real design content, not a stage-5 ask).

#### NIT

- **CR3-2 · [DOC]** `04:919` and `04:1107` say `2>&1 &&` "never consults the index". The *single* `&` in `2>&1` does consult it — it takes the append branch at row 15 — it is the trailing `&&` that is claimed earlier by the `two == "&&"` test. The decline's **conclusion is correct** (`R3` is a strictly stronger discriminator of the same branch; `R3b` is green under every guard and every mutant, including an always-flush regression that reddens `R3`), so nothing changes materially. The wording originated in **my** round-2 report at `05:368`; correct both at archive time.

### Axis B — Standards conformance

#### MINOR

**CR3-3 · [STD] `04_DEVELOPMENT.md` is 1305 lines against `.harness/rules/70-doc-size.md:30`'s 500-line per-stage-doc cap.**
The developer flagged this himself (`04:1251-1258`), correctly identified the cap as **soft and ungated** (`verify_all`'s `I.*` group covers `AI-GUIDE.md`, rule fragments, agents, `insight-index.md` and `docs/tasks.md` — not per-task stage docs), correctly declined to compact three rounds of captured evidence unilaterally, and correctly assigned it to the PM at archive time under rule 70's "reference, don't paste" / compaction patterns. I record it because it is a real deviation from a documented rule and because **I should have flagged it in rounds 1 and 2** (558 and 868 lines) and did not. Owner: **PM, at archive**. Not a developer round; not a delivery blocker.

#### Everything else on this axis: **no findings.**

Live-hook edit sequence honoured a third time (template first, `bash -n`, driven via `[guard-path]`, one `sync-self`, `--check` → `In sync.`, repo copy written exactly once per shell); check count frozen at 32 with `verify_all.{sh,ps1}` untouched; `CONTEXT.md` untouched; rule docs untouched and within cap; `docs/tasks.md` / `BATCH_PLAN.md` correctly left to the PM; `docs/proposals/frontier-gaps-2026-07.md` still absent and still not cited; row quoting exception-free; repo↔template parity exact; bash-3.2 and `patsub_replacement` red lines held; `baseline.json` transcribed and free of the phantom PS key. One item deserves explicit credit as *standards work*, not just diligence: the mutant builder that **fails loudly if an anchor string does not match exactly once** (`04:1148-1150`) closes the silent-no-op-mutant false green, which is the failure mode that would have made this round's entire anti-revert evidence worthless.

---

## 10. Axis status

- **Standards-conformance: 1 finding — worst = MINOR** (CR3-3, a soft ungated doc-size cap on a stage doc, self-disclosed, PM-owned at archive). No CRITICAL, no MAJOR. Everything else on this axis is clean and was re-checked in the code, not read from the record.
- **Spec/design-fidelity: 2 findings — worst = MINOR** (CR3-1, an undisclosed pre-existing verb-hiding class; CR3-2, a prose correction that is originally mine). **No CRITICAL, no MAJOR.** CR2-1 is genuinely fixed at its source with the unreachability claim discharged rather than accepted; CR2-2's replacement argument is the sound one and I verified its structural half in the code; CR2-3 reproduces exactly; CR2-4's decline is right.
- **Aggregate = the more severe of the two = MINOR.**

---

## 11. Verdict

**APPROVED WITH NITS — 0 CRITICAL, 0 MAJOR, 2 MINOR, 1 NIT.**

**No finding in this report requires another developer round.** I want that unambiguous, and I want the reason to be the evidence rather than the rollback budget: the one MAJOR I raised in round 2 is fixed at its source, in both shells, with the sentinel-unreachability claim discharged over the loop's actual bounds, every multi-character consumer, every frame push and pop, and the recursion path; the fix's blast radius is provably one input class; the two bypasses the developer found beyond the two I named are real and really closed; and the two single-fix reverts separate cleanly and arithmetically, which is exactly the evidence that round 2 opened CR2-1 and that round 3 closed it with something load-bearing. Rounds 1 and 2 asked for changes because there was a MAJOR to fix. There is not one now.

**Conditions for QA (stage 6) to carry:**

1. **CR3-1's residual line** in both rule copies (repo + `.tmpl`), naming the leading-token verb-hiding family. Doc-only; no guard change; the 87-row suite and `verify_all` need no re-run beyond `[I.2]`'s ≤200 check (199 / 190). If the PM prefers zero further stage-4 work, this is a legitimate stage-6/7 fix-forward — but the **delivery statement must name the class either way**.
2. **CR3-2** and the three known-false design statements — §3.1's unconditional `HDBODY` end-of-input failure (drift 1), §10.3's ANSI-C evidence row (drift 4), §3.1 rows 12/15's raw-previous-byte rule *and its sentinel requirement* (drift 5, now correctly restated at `04:1063-1072`) — corrected at **archive time** by the PM. All three drifts remain adjudicated as correct fixes-forward; none needs an architect round.
3. **CR3-3**: compaction of `04_DEVELOPMENT.md` at archive, PM-owned.
4. **The PowerShell operator list is the delivery's real open risk**, not a formality: items 1–10, with item 3 (R11 — an escaping terminating error exits 1, which Claude Code treats as non-blocking, silently disarming the Windows guard) and the new item 10 marked **security**. QA must not reconcile `test_guard_rm_ps_assertions`, must not invent it, and must not treat the 87-row bash green as evidence about `.ps1`.
5. **NFR-1's waiver** stands as recorded; round 3 touched no performance path (one integer literal per `Split-CommandPositions` call), so the rule docs' measured table still describes the shipped guard. The chunked-indexing follow-up keeps the developer's caveat: **any length cap must fail closed (BLOCK, not skip)**.

**The residual bypass surface, as I understand it after three rounds — this is what the delivery has to say out loud:**

1. **Verb spelling** — `/bin/rm`, `\rm`, `$(which rm)` are unrecognised. *(Documented, residual 1.)*
2. **Indirection** — `eval "$X"`, `$CMD -rf /etc/x`, aliases, shell functions, `./script.sh`, Makefile targets. Out of reach for a text-only guard. *(Documented, residual 2.)*
3. **The verb is not at token 0 of its position** — a leading redirection (`> f rm -rf /etc/x`, `2>&1 rm …`), an empty leading token (`'' rm …`), an array-element assignment prefix, and the `xargs bash --rcfile foo -c "…"` §3.4 asymmetry. **Only the array case is documented today** — CR3-1, A-7, A-8. *This is the largest undisclosed gap.*
4. **Non-literal paths** and the unmodelled `cd`. *(Documented, residuals 3–4.)*
5. **Past 8192 characters** — unjudged. *(Documented, residual 6.)*
6. **The override authorises the whole line**, deliberately, so it stays visible at the head of the line. *(Documented, residual 7.)*
7. **Scope and shell** — `PreToolUse` governs only Claude Code's Bash tool, and **the PowerShell twin has never been executed anywhere**. *(Documented, residual 8.)* On the operational axis this is the biggest one: the Windows guard's highest-probability defect fails **open**.
8. **By design, not a defect** — the verb set is nine verbs; `mv`, `cp` and `>` truncation stay unguarded (AC-6), so `> /etc/passwd` is ALLOW on purpose. Depth > 2, unbalanced quotes and unterminated here-documents BLOCK (fail-closed), and the over-block surface is a strict superset of the pre-v0.46 one.

Within that surface, what this task actually delivered is real and I re-verified it independently across three rounds: the nine-verb rule is now evaluated at every command position the guard can identify — `;`, `&&`, `||`, `&`, newlines, subshells, brace groups, command substitutions, backticks, process substitutions, argv carriers and nested `bash -c` / `pwsh -c` strings — where before it saw only the first token of each top-level pipe segment, and `echo hi && rm -rf /etc/x` exited 0.
