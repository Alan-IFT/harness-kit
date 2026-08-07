# 03 — Gate Review · T-17 `guard-cmd-chain`

- Mode: **full** · Stage 3 (gate-reviewer) · Security task
- Inputs: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY)
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker is emitted.
- Verification method: code reading only (no Bash). Every design citation below was opened and checked.
- _(Persisted verbatim by the PM Orchestrator: the gate-reviewer agent has Read/Glob/Grep only and cannot write files. Round 1.)_

---

## 0. What I verified in code (not from the docs)

| Design claim | Verified? |
|---|---|
| `split_pipes` `\|`-only, `tokenize` space/tab-only, verb = `tokens[idx]` after `sudo` | YES — `guard-rm.sh:122-146`, `:90-117`, `:213-223` |
| All reuse-audit symbols exist at cited lines (`resolve_leaf` :149-186, `is_descendant` :188-196, pwsh branch :226-241, find branch :243-262, verb loop :265-272, `parse_failed` :200, trim idiom :134-135, fallback :43-56) | YES — every one |
| `str_replace_all` at `upgrade-project.sh:124-131` | YES — exact |
| sync-self Mapping 5 is **template → repo**, one `cp` | YES — `sync-self.sh:74-76` + `sync_file` :22-33 |
| Hook is fail-closed, `matcher: "Bash"` only, no `\|\| exit 0` | YES — `.claude/settings.local.json:16-26` — so Write/Edit **is** a valid repair path and `git checkout` genuinely is not |
| `verify_all` F.2 is presence + wiring only | YES — `verify_all.sh:290-334` — four `-f` tests + three greps for `"PreToolUse"` / `"matcher":"Bash"` / `guard-rm\.(ps1\|sh)` + two template-placeholder greps. **Nothing behavioural. Check count can stay 32.** |
| `test-init` asserts guard presence/wiring only | YES — `test-init.sh:279-280` (two `-f`) + `:287-336` (three assertions, python3/grep branches, both about `settings.json` wiring). **Assertion counts genuinely do not move.** |
| `baseline.json` has no `test_guard_rm_*` key; verify_all only checks the file exists | YES — `baseline.json:1-25`, `verify_all.sh:743` |
| `.harness/rules/75-safety-hook.md` = 137 lines vs 200-line cap | YES — (`70-doc-size.md:25`); 55 added lines lands at 192 — tight but legal |
| `evals/guard-rm-cases.md` and `test-guard-rm.{sh,ps1}` have **no** template twin | YES — (not in sync-self, not under `templates/`) |
| Current guard uses no bash-4-only construct | YES — no `mapfile`, no `${v,,}`, no `declare -A` |
| The only repo-wide "first token" trigger claim lives in `75-safety-hook.md:36` + `.tmpl:22` | YES — grepped `first token\|first verb\|only inspects` across the live tree — no other surface asserts trigger semantics; README/`dev-map.md:102`/`harness-status/SKILL.md` are presence-and-wiring only, exactly as the ledger says |
| `CONTEXT.md` **already** carries the `Command position` term | YES — `CONTEXT.md:100-102` — ledger surface 11 is *already done*; the Developer must not re-add it |

---

## 1. Audit checklist

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **WARN** | IS-1 is genuinely total (row 19 + IS-2 + IS-3), and every AC names a captured exit code. Two defects: AC-3's header contradicts IS-2 for L10 (F-10), and AC-4's corpus source is not an artifact any agent can read (F-11). |
| 2 | Design completeness | **FAIL** | The scanner table does not specify the quote state inside a nested frame, so `$( )`/backtick opened inside `"…"` loses separator recognition — a **false negative** against IS-1 rows 2/5 (F-1). |
| 3 | Reuse correctness | **PASS** | Every reused symbol exists at the cited line, the `find -delete` / `resolve_leaf` / `is_descendant` byte-unchanged claims are compatible with the code as written, and the "no existing position-scanner" claim survives my own grep. |
| 4 | Risk coverage | **WARN** | R1-R10 are the right risks and R2/R6/R7 are correctly reasoned. Missing: the .NET out-of-range-index class, which is the highest-probability PS-only defect for a character lexer **and lands fail-open** (F-6). |
| 5 | Migration safety | **PASS** | No data migration; correctly refuses a feature flag under NFR-5; the template-stage → `bash -n` → drive-by-`[guard-path]` → single `sync-self` promote sequence really does keep the live copy valid after every step (one caveat, C-6). |
| 6 | Boundary handling | **FAIL** | Two structural holes: monotonicity is violated through the nested-interpreter path (F-2), and the carrier-vs-`find` branch order as written breaks either AC-1 row o or fixture rows 9/17 (F-3). Plus one unenumerated over-block class (F-9). |
| 7 | Test feasibility | **FAIL** | The stride-4 fix is right, but the design omits the row-**quoting** constraint, and a row written with double quotes would execute `rm -rf OUT` at driver-load time (F-5). AC-4's corpus is unobtainable as specified (F-11). |
| 8 | Out-of-scope clarity | **WARN** | §10.1 is crisp and §10.3 is the right instinct. But §10.2 **overstates coverage**: IS-1 row 12 / B-13 / R1's "here-doc body is structurally incapable of producing a position" is false under the union (F-4), and the override's whole-line authorization is unlisted (F-12). |

---

## 2. Adjudication of the three items the Architect flagged

### 2.1 The union anchor — **monotonicity is NOT inspection-provable as specified**

The union `P = split_pipes(s) ∪ split_positions(s)` does what the architect says **at the top level**: because `split_pipes` is byte-unchanged and its segments are still fed to `classify_segment`, every position the pre-change guard judged is still judged, and the widened `_skip_prefix` can only move the verb *forward past non-destructive tokens* (no reserved word and no assignment-shaped token is a destructive verb, and `find` is in neither list), so the strip alone can only flip ALLOW→BLOCK. That part is sound and I accept it.

It breaks one level down. §3.5 changes the pwsh call site from `classify_segment(inner, d+1)` to `classify_command_string(inner, d+1)`. Pre-change, the inner string was classified **whole**; post-change it is first `split_pipes`-decomposed. Decomposition strictly **narrows each verb's token walk**, and today's walk is exactly what catches paths that belong to a later command:

```
pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"
```

- Pre-change: outer `|` is inside `"…"` → not split; inner classified whole; tokens `Remove-Item -Recurse ./tmp | Tee-Object C:\log`; verb `Remove-Item` walks every token; `C:\log` matches `[A-Za-z]:*` in `resolve_leaf` → outside root → **BLOCK**.
- Post-change: inner `split_pipes` → `Remove-Item -Recurse ./tmp` (in-project) + `Tee-Object C:\log` (non-destructive verb) → **ALLOW**.

BLOCK→ALLOW. IS-2 violated, on a variant of fixture row 8. So: the union is the right *idea*, but the invariant it needs is **"`P` always contains the input string `s` itself, at every depth"**, not "`P ⊇ split_pipes(s)` at depth 0". The architect's own justification (pre-change segmentation retained) is only true where the pre-change segmentation *was* `split_pipes` — and inside the pwsh branch it was not.

Second half of the question — does the union import pre-change *parse-failure* behaviour? **Yes, wholesale, and the design under-reports it.** Every P_old segment still goes through the unchanged `tokenize()`, whose quote handling is naive (no backslash escapes, no here-doc awareness). So every line that BLOCKs today for an odd `'` or `"` still BLOCKs, no matter how well the new scanner understands it: `echo \'`, `rm -rf ./x # don't`, and — the load-bearing one — **any here-doc body containing a `|`** (see F-4). The scanner therefore delivers *zero* false-positive relief; the post-change over-block surface is a superset of today's. That is defensible for a fail-closed guard, but it must be stated, and L10 must be presented as **one instance of a class**, not a singleton.

**Verdict:** the claim as written is false. Monotonicity still needs a **differential test** (AC-4 already provides the machinery via `[guard-path]`), not inspection alone.

### 2.2 The AC-3 / L10 tension — **the design's resolution is correct; the requirement still needs a one-line correction**

L10 BLOCKs pre-change (`tokenize` sees an odd `'`, `guard-rm.sh:114` → `parse_failed`) and BLOCKs post-change (P_old is the whole string). Making it exit 0 would be a BLOCK→ALLOW flip — i.e. AC-3's header, applied to L10, **contradicts IS-2 directly**, not merely the design. A security invariant outranks a false-positive-budget header, so resolving in favour of the Why column is right.

But this is a contradiction *inside the acceptance criteria QA will execute*, and burying its resolution in a design section invites QA to report a red row and re-litigate it. Route a one-line correction to requirement-analyst (F-10): AC-3's header becomes "exit 0 for every row **except L10**, whose expected verdict is BLOCK, unchanged from pre-change (IS-2)". A design-level note is *not* sufficient here — cheap to fix, and it removes an adjudication from stage 6.

### 2.3 The driver row-encoding defect — **real defect, wrong failure mode, and the replacement needs one constraint the design omits**

The diagnosis is right that `|`-delimited rows cannot express AC-1 d/q or AC-3 L5/L11. The stated *consequence* is wrong. Tracing `test-guard-rm.sh:60-62` on `"d|false || rm -rf OUT|0|BLOCK"`:

```
id="d"  cmd="false "  override=""  expected=" rm -rf OUT|0|BLOCK"
```

`expected` always absorbs the residue and therefore always contains a `|`, so it can never equal `ALLOW`/`BLOCK`. Those rows **FAIL loudly**, they do not "still pass — fabricated green". Same for q, L5, L11. The fix is unchanged, but the risk framing in R7 should be corrected — a developer told to watch for silent green may not notice that the *command actually fed to the guard* was truncated (`echo hi ` instead of the full chain), which is the real hazard and is what R7's "confirm each row's `cmd` echoes back intact" already catches.

Can stride-4 express every AC-1/AC-3 row? **Yes — with a constraint the design does not state, and its absence is dangerous.** Bash array elements carry any bytes but obey the quoting of their literal:

- Rows with `$(` or backticks (**AC-1 row i** `echo $(rm -rf OUT)`) written as a **double-quoted** element would be command-substituted **when the array is defined** — the driver would really execute `rm -rf /etc/harness-guard-probe` on the developer's box. Same trap on the PS side (`@{ cmd = "echo $(rm -rf OUT)" }` invokes the subexpression). Must be single-quoted.
- Row f (newline) needs `$'echo hi\nrm -rf OUT'` — `$'…'` does **not** substitute, so it is safe; CRLF via `$'…\r\n…'`.
- L11 contains `'` and `"` but no `$` → a double-quoted element with `\"` is fine, or `$'…\'…'`.
- Existing row 8 already sets the precedent (single-quoted because of its inner `"`).

So: expressible, but the rule "**single-quote (or `$'…'`) every row containing `$`, `` ` `` or `$(`; never double-quote**" must be written into the design or handed to the Developer as a condition.

---

## 3. Numbered findings

### FAIL — routed to **solution-architect**

**F-1 · The scanner's quote state is not saved per nesting frame → false negative.**
§3.1's table has one scalar state (`NORMAL/SQ/DQ/COMMENT/HDBODY`) and one nesting stack, but `CMDSUB`/`BQ`/`PROCSUB` are specified to save only "the outer buffer". Under the table as written, `echo "$(true && rm -rf /etc/x)"` pushes `CMDSUB` **while still in DQ**, and the DQ column says `;`, `&`, `|` → *append*. The inner buffer becomes one position `true && rm -rf /etc/x`, verb `true`, **ALLOW**. P_old does not rescue it (verb `echo`). This contradicts IS-1 rows 2 and 5 and is the forbidden direction for a security fix. The table's own `)` × DQ cell — "append (unless it closes a `$(`/backtick opened in DQ)" — is an unspecified exception, i.e. that cell is **not total**: two readings are available and the design does not say which. Frame push must save *and restore* the quote state (inner buffer starts at `NORMAL`; `BQ`/`$(` opened inside DQ restores DQ on pop).

**F-2 · Monotonicity (IS-2) is violated through the nested-interpreter path.** See §2.1. Counterexample `pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"` flips BLOCK→ALLOW. The invariant must be restated as "`P` contains `s` itself at every depth", and §1/§12's "provable by inspection, not by testing" must be withdrawn — a differential run is required.

**F-3 · Carrier-vs-`find` branch ordering is self-contradictory, and both literal readings fail an AC.**
§3.4 says the carrier scan runs "*in addition* to" the unchanged `-delete` branch; §6's flow lists `verb = carrier?` and `verb = find?` as mutually exclusive branches. Neither ordering works as an exclusive branch:
- carrier first + `return` → `find /etc -delete` (fixture 9) and `find /tmp -name '*.log' -delete` (fixture 17) find no destructive/interpreter token in their scan, return clean → **BLOCK→ALLOW**, breaking AC-2 *and* IS-2;
- find first → `guard-rm.sh:250` `(( has_delete == 0 )) && return` fires for `find . -name '*.log' -exec rm -rf OUT ;` → **AC-1 row o ALLOWs**.
The design must pin: for `find`, run the carrier scan **first and without returning**, then fall through to the byte-unchanged `-delete` branch.

**F-4 · §10.2 overstates coverage — here-doc bodies are not position-free.**
IS-1 row 12, B-13 and R1 ("here-doc body characters are structurally incapable of producing a position") are false under the union, because P_old = `split_pipes(cmd)` splits the **whole command string** on `|` with no here-doc awareness. A body line containing `|` — e.g. any markdown table written via `cat > f <<'EOF'`, which is a routine agent action in this repo — yields body-derived positions, and a body line such as `| rm -rf /etc/x |` BLOCKs. It is pre-existing (so monotonic), but the residual list is a **required deliverable** of this task and this is exactly the overstatement class the dispatch forbids. §10.2 must add the general statement: *the union retains the pre-change pass, so every pre-change parse failure and every pre-change `|`-split survives; the new scanner narrows nothing and the over-block surface is a superset of today's.* L10 then reads as one instance of that class rather than a special case.

**F-5 · The replacement row encoding needs an explicit quoting constraint (execution hazard).** See §2.3. Without it, AC-1 row i as a double-quoted array element (bash) or hashtable value (PS) executes `rm -rf OUT` at driver-load time. Also correct R7's failure-mode wording (loud FAIL, not fabricated green).

**F-6 · The PS twin's most likely defect is unlisted and lands fail-OPEN.**
§9.2 covers `$isWindows`, `-join`/`+`, `-split -1`, `Out-String`, `Sort-Object -Unique`, quoting — but not the one that a character lexer *will* hit: **.NET string indexing and `Substring` throw on out-of-range**, whereas bash `${s:$i:1}` at `i == len` yields `""`. The scanner is lookahead-heavy (`$((`, `$(`, `${`, `&&`, `<<`, `<<<`, `))`, `&>`). With `guard-rm.ps1:19` `$ErrorActionPreference = 'Stop'`, an escaping terminating error exits **1, not 2** — Claude Code treats non-2 as non-blocking, so the Windows guard **silently disarms**. R4's "green-by-symmetry" framing hides this because symmetry cannot detect it. Add: every lookahead must be length-guarded; wrap the scanner in `try/catch` that maps any exception to the `__PARSE_FAIL__` path. Also reconcile the two failure signals the design specifies for PS (`Split-CommandPositions` returns `$null` per §3.1 vs the `__PARSE_FAIL__` sentinel per §9.2).

**F-7 · §3.3 rule 1's assignment glob is malformed.** `[A-Za-z_][A-Za-z0-9_]*=*` under bash pattern matching is *char-class, char-class, `*`, `=`, `*`* — it requires **two** leading name characters, so `A=1` does **not** match (single-letter assignment prefixes stay opaque: `A=1 rm -rf OUT` remains a bypass, defeating the AC-1-row-p class for one-letter names), and the unanchored `*` accepts arbitrary bytes before the `=` (`AB;rm=x` matches). Specify the exact test.

### WARN — routed to **solution-architect**

**F-8 · Table matching order and the fast-path list are unstated/unaudited.** "Exactly one row matches" requires a longest-prefix order (`$((` before `$(` before `${` before `$`); the design never says so. Separately, the §3.2 fast-path glob includes `:` — no cell in the table reacts to `:`, so every `C:\…`, `http://…` and `key: value` takes the slow path for no reason. Harmless, but it signals the list was not derived from the table. (I did verify the list is *sound*: with none of `; & ( ) { } \ ` < > # LF CR` present, the scanner can produce no position `split_pipes` misses.)

**F-9 · Unenumerated over-block: ANSI-C quoting.** `$'it\'s'` — the `\` × SQ cell is "append (literal)", so the escaped quote toggles SQ→NORMAL and the string ends in SQ → parse failure → **BLOCK**. Pre-change this ALLOWs (`tokenize` counts four balanced `'`). That is a new ALLOW→BLOCK flip absent from §10.3 and from AC-1. Under OQ-6a it must be fixed-or-recorded; pre-declaring it is cheaper than discovering it at QA.

**F-12 · §10.2 item 9 is incomplete.** A leading `HARNESS_ALLOW_OUTSIDE_RM=1` authorizes the **entire line**, including every chained position after it (`… =1 rm -rf A && rm -rf B` → exit 0 for both). Identical to today, so monotonic — but now that the guard is chain-aware everywhere else, the honest list must say the override is not.

### WARN — routed to **requirement-analyst**

**F-10 · AC-3's header contradicts IS-2 for L10.** One-line correction; see §2.2.

**F-11 · AC-4's corpus source is unobtainable.** "at least 40 command lines drawn from this repo's real Bash usage (session transcript or `git log` of driver invocations)" — Bash tool calls are not in git history and the transcript is not a file any agent can read. As written, AC-4 is unverifiable. Redefine the corpus to a readable artifact (see Q3 below for a concrete pre-answer) or the criterion will be satisfied by whatever the Developer improvises.

---

## 4. Things I checked that are **correct** (recorded so they are not re-litigated)

1. **The override's fail-closed shape holds against all three bypass paths.** `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` → prefix not at offset 0 → parsed → assignment transparent → **BLOCK**. `env HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` → line starts with `env` → no override; `env` is a carrier → dispatch on `rm` → **BLOCK**. `bash -c "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT"` → outer line does not start with the prefix; inner goes through `_skip_prefix` → verb `rm` → **BLOCK**. This works *because* step 2b is on the top-level `cmd` only — the Developer must not "helpfully" re-apply it inside `classify_command_string` (condition C-4).
2. **L9/L11/L12 pass, and the reasoning is right.** L11's payload is one single-quoted word → SQ state → no positions inside; its second position `bash .harness/scripts/guard-rm.sh` reaches the interpreter branch, whose non-option token `.harness/scripts/guard-rm.sh` classifies to a non-destructive verb → ALLOW. L9's P_old is the whole multi-line string with verb `cat` → ALLOW; its scanner position is `cat > … <<'EOF'` → ALLOW. L12 → ALLOW. **The suite can run.** (Subject to F-4: a here-doc body containing `|` is a different story.)
3. **The carrier scan does not create the feared false-positive class.** The scan runs only when the **post-prefix verb** is a carrier — the boundary is the verb position, not "the token text appears anywhere". So `grep -rn "rm -rf OUT" .` (L8) and `git commit -m "guard: block rm -rf outside root"` (L13) stay ALLOW, and `xargs -I {} rm -rf ./x` works. Residual FP class worth recording under OQ-6a: *carrier verb + a literal destructive-verb argument + a later outside path*, e.g. `timeout 5 grep -r rm /etc` → BLOCK. Exotic; record, do not chase.
4. **`patsub_replacement` coverage is complete.** The two new rewriting sites (fallback unescape §6.1, driver encoder) both mandate `str_replace_all`, the blanket "no `${var//needle/repl}` in any new code" is correct, and leaving `guard-rm.sh:54-55` byte-unchanged is right (their replacements are `"` and `\`, no `&`).
5. **Bash 3.2-safety is real and correctly motivated.** The current guard contains no bash-4 construct; `${v,,}` would be a whole-file parse error on macOS's `/bin/bash`, i.e. R2. The glob verb matcher and the linear-scan dedup follow from that.
6. **Latency reasoning is sound.** The 18-forks-per-segment `printf | tr` loop (`:265-272`) plus two at `:227` is genuinely the multiplied cost, and removing it more than pays for a 5-15× segment increase. `resolve_leaf`'s `$( )` stays bounded because it is reached only for path tokens of an actually-destructive verb.
7. **The lockstep ledger's "verified NOT to change" list is accurate.** I grepped independently: `test-real-project.{sh,ps1}`, `test-harness-upgrade.{sh,ps1}`, `upgrade-project.*`, `migrate-scripts-layout.*`, `entropy-cadence.*`, `install-hooks.*`, `hook-spec.*`, `MIGRATION.md`, `40-locations.md`, `15-skill-authoring.md`, `harness-{init,adopt,batch,stream,status}/SKILL.md`, both READMEs — **every** one references guard-rm as a *path, hook byte-form or presence assertion*, never as a trigger-semantics claim. `verify_all` F.2 and `test-init` are presence+wiring only (verified line by line). The single behavioural claim in the tree is `75-safety-hook.md:36` + `.tmpl:22`, both already ledger items 8/9. **No missed fan-out surface found** — this ledger survives the T-13/T-03/T-12 failure mode.
8. **Ledger surface 11 is already complete** — `CONTEXT.md:100-102` already carries `Command position` (the Architect added it). Do not re-add.

---

## 5. Predicted developer questions (pre-answered)

**Q1 — "Inside `$( … )` that was opened in a double-quoted region, am I in DQ or NORMAL?"**
**Unresolved — this is F-1.** Do not guess. The correct semantics (inner content parses at NORMAL quoting; the outer DQ resumes on pop) is what a shell does, and it is what IS-1 rows 2/5 require, but the table as written says otherwise. Wait for the amendment.

**Q2 — "For `find`, do I run the carrier scan, the `-delete` branch, or both?"**
**Both, carrier scan first, no `return` between them** — but this is F-3 and must come back as an amended §3.4/§6, not as a Developer judgement call, because getting it wrong silently flips fixture rows 9/17 (a green-looking `ALLOW` for `find /etc -delete`).

**Q3 — "Where do I get AC-4's 40 real command lines?"**
Not from the transcript or `git log` (F-11). Readable substitutes in-repo: fenced command blocks in `README.md` / `docs/getting-started.md` / `docs/dev-map.md`, the `Command:`/invocation lines in `docs/features/_archived/*/06_TEST_REPORT.md` and `04_*.md`, the hook byte-forms in `hook-spec.{sh,ps1}`, and the `bash .harness/scripts/*` invocations in `AI-GUIDE.md:72-86`. Quote the corpus source per line in the test report so the criterion is auditable.

**Q4 — "Can I hand-edit `.harness/scripts/guard-rm.sh` just to try something?"**
No. It is the live PreToolUse hook with no `|| exit 0` (`settings.local.json:22`); a syntax error makes `bash` exit 2, which is byte-indistinguishable from BLOCK, and **every** Bash tool call for every downstream agent dies. Edit the template; `bash -n` it; drive it with the new `[guard-path]` argument; promote once with `sync-self`. If it ever bricks: `Read` the template, `Write` the repo copy. `git checkout` is a Bash call and will itself be blocked.
Two subtleties the design does not spell out: (a) a *runtime* error (unbound variable under `set -uo pipefail`) exits **1**, which Claude Code treats as non-blocking — so a runtime bug fails **open** and `bash -n` will not catch it; the post-promotion driver run is what protects you. (b) `sync-self.sh` promotes **all nine** mappings — run `sync-self.sh --check` first and confirm only the `guard-rm` pair is listed as drifted.

**Q5 — "Should I write the driver rows with double quotes so I can embed `'`?"**
Only for rows containing **no** `$`, `` ` `` or `$(`. AC-1 row i (`echo $(rm -rf OUT)`) in a double-quoted bash array element or PS hashtable value **executes the deletion when the array is defined**. Single-quote it; use `$'…'` for the newline/CRLF rows. See F-5.

**Q6 — "`_POSITIONS` is empty and `set -u` is on."**
Use the file's existing idiom `("${_POSITIONS[@]+"${_POSITIONS[@]}"}")` (insight 2026-05-16, `guard-rm.sh:208`, `:305`), never `declare -a`, and snapshot immediately — the recursion clobbers globals.

**Q7 — "`destructive_verbs_ci` becomes unused once `_is_destructive_verb` lands. Delete it?"**
No — §3.6 keeps it deliberately as the human-readable declaration and as AC-6's diff target. Keep both lists at 9 members and keep the equal-membership comment ledger.

---

## 6. Verdict

**BLOCKED ON DESIGN.**

Route back to `harness-kit:solution-architect` with findings **F-1 … F-9** and **F-12**; route **F-10** and **F-11** to `harness-kit:requirement-analyst` (both are one-line corrections and can be done in parallel).

The design's *shape* is right and I am not asking for a redesign: the lexer-over-grammar choice, the byte-unchanged path resolver, the fork-removal, the template-staging sequence and the lockstep ledger are all correct, and the ledger in particular survives the fan-out audit that rolled back T-13/T-03/T-12. What blocks is that three of its load-bearing claims do not hold as written — a false negative (F-1), a monotonicity violation (F-2), a branch-ordering contradiction that breaks an AC either way (F-3) — plus a coverage overstatement in the residual list that this task exists to get right (F-4). All four are local amendments to §3.1/§3.2/§3.4/§3.5/§10.2; I would expect one architect pass, not a rewrite.

**When the amended design returns, these are the conditions the Developer must fold in:**

- **C-1** — `P` must contain the input string `s` itself at *every* depth, not only `split_pipes(s)` at depth 0 (F-2), and AC-4's differential run must be treated as the proof of IS-2, not inspection.
- **C-2** — nesting frames save and restore the quote state; the inner buffer of `$(`/`` ` ``/`<(` starts at `NORMAL` (F-1).
- **C-3** — for verb `find`: carrier scan first, **no `return`**, then the byte-unchanged `-delete` branch (F-3).
- **C-4** — the command-text override is evaluated **once**, on the top-level `cmd`, before `.git/` walk and before any parsing. Never inside `classify_command_string`.
- **C-5** — driver rows: single-quoted (or `$'…'`) for every row containing `$`, `` ` `` or `$(`, in **both** shells; confirm each new row's `cmd` echoes back intact in its PASS line.
- **C-6** — before `sync-self`, run `sync-self.sh --check` and confirm only the `guard-rm` pair is drifted; after it, re-run the driver against the default path and quote the captured tally (never derive it).
- **C-7** — PS: length-guard every lookahead and wrap the scanner in `try/catch` mapping any exception to `__PARSE_FAIL__`; an escaping terminating error exits 1 and fails **open** (F-6).
- **C-8** — do not re-add `Command position` to `CONTEXT.md`; it is already at `CONTEXT.md:100-102`.
- **C-9** — `.harness/rules/75-safety-hook.md` must land ≤ 200 lines (137 today; 55-line budget leaves 8 lines of headroom) and the residual section must carry F-4, F-9 and F-12.

---
---

# 03 — Gate Review · T-17 `guard-cmd-chain` — **ROUND 2**

- Round 2 · re-verification after amendments to `01_REQUIREMENT_ANALYSIS.md` (F-10, F-11) and `02_SOLUTION_DESIGN.md` (§0 changelog + 15 amended sections, verdict READY).
- Scope: only what changed, plus what the changes could have broken. Round-1 §4 "verified correct" and the six PM-resolved OQs are **not** re-opened.
- Method: code reading only (no Bash). Every new citation was opened.
- deferred-human: **defer, do not ask.** No `BLOCKED: NEEDS-HUMAN` marker.
- _(Persisted verbatim by the PM Orchestrator: the gate-reviewer agent has Read/Glob/Grep only.)_

---

## R2.0 — What I opened in code this round (not from the docs)

| Claim under test | Verified? |
|---|---|
| `verify_all.sh` I.* group contains **no** stage-doc size check | YES — `verify_all.sh:384-508`: I.1 `AI-GUIDE.md`, I.2 `.harness/rules/*`, I.3 `agents/*`, I.4 insight-index, I.5 `docs/tasks.md`, I.6 retired claims, I.7 INTERVENE. No `0[1-7]_*.md`, no `PM_LOG.md` |
| PS twin likewise | YES — `verify_all.ps1:371-483`, identical five size steps |
| A WARN is **not** status-neutral overall | **Correction to the architect's framing** — `verify_all.sh:823-825`: `errors>0 → exit 2`, **`warns>0 → exit 1`**, else 0. The `:716` comment only says a WARN doesn't change the *check count* |
| `.harness/rules/75-safety-hook.md` current size | 136 lines (round 1 said 137) → 64-line headroom to the 200 cap; the design's ≤55 budget lands ≤191 |
| `CONTEXT.md` `Command position` **not** re-added | YES — one entry only, `CONTEXT.md:100-103` |
| New PS citations in §9.2 | ALL exist — `guard-rm.ps1:19` `$ErrorActionPreference='Stop'`, `:94` `return $null`, `:97`/`:117` `,$…ToArray()`, `:174`/`:178` `,@('__PARSE_FAIL__')` |
| `guard-rm.sh` anchors for the pinned `find` order | YES — carrier/`find`/verb dispatch at `:226-272`; `(( has_delete == 0 )) && return` at `:250`; `segment_offending` is a **global** (`:201`) so the carrier scan's hits survive the `find` branch's early `return` |
| AC-4 corpus floor reachable after the S4 narrowing | YES — S2 alone: **204 matches across 67 archived stage docs** for `(bash\|pwsh) …/.harness/scripts/`. S4 is ~zero-yield as the analyst now says (`AI-GUIDE.md:72-86` is prose paths, not invocations) |
| The C-1 over-block class occurs in the corpus | **NO — zero real instances.** Grepped every `*.md` for a destructive verb followed by a top-level `\|`: the only hits are (a) `evals/guard-rm-cases.md` table rows, (b) README/BATCH_PLAN **version-history prose**, (c) this task's own docs. No `rm … \| tee /abs/path` anywhere |

---

## R2.1 — Per-finding closure

| # | Owner | Status | Where the fix lands, and whether it holds |
|---|---|---|---|
| **F-1** | architect | **CLOSED** | §3.1 "Nesting stack (F-1)" bullet 1: CMDSUB/BQ/PROCSUB save **buffer + quote state**, inner starts `NORMAL`, both restored on pop. The `)`×DQ exception clause is gone (row 19 DQ is now two total cases). Counterexample re-run below yields the required split. |
| **F-2** | architect | **CLOSED** | §3.2 pseudocode line `P = [ s ]` with the comment "at EVERY depth", §3.5 restates it for the pwsh call site, §8 R5 and §12 withdraw "provable by inspection". Counterexample re-run confirms BLOCK. |
| **F-3** | architect | **CLOSED** | §3.4 "Branch ordering for `find` — pinned" gives an explicit five-line dispatch block, and §6's flow now carries `(NO return)` / `(may return)` annotations plus the line "The carrier and `find` lines are **sequential**, not alternatives". The two sections now say the same thing — which was the whole defect. |
| **F-4** | architect | **CLOSED** | §10.2 item 11 is the general union-residue statement with the here-doc-body and odd-quote instances spelled out and the "superset of today's over-block surface" conclusion. §8 R1's "structurally incapable" is withdrawn in-place ("**Not a totality claim**"). §10.3 demotes L10 to "one instance of a class". |
| **F-5** | architect | **CLOSED** | §6.2 "Quoting constraint — mandatory, both shells", including the PS hashtable trap and the echo-back check. §8 R7 now reads "loud FAIL, not silent green". |
| **F-6** | architect | **CLOSED** | New §8 R11 + §9.2 bullet 1: every multi-char lookahead length-guarded, whole scanner in `try/catch → return $null`, and the two signals reconciled (`$null` internal, `__PARSE_FAIL__` external, converted by `Get-OffendingFromCommandString`). Both cited PS line numbers check out. |
| **F-7** | architect | **CLOSED, with a narrow residual** | §3.3 rule 1 replaces the glob with a split-then-validate test. Re-run against my four counterexamples: `A=1` matches, `AB;rm=x` rejected, `=x` rejected, `1A=x` rejected. PS twin `'^[A-Za-z_][A-Za-z0-9_]*='` is exactly equivalent. **Residual:** `A+=1 rm -rf OUT` and `a[0]=1 rm -rf OUT` are still opaque in both shells (`${t%%=*}` yields `A+` / `a[0]`, both rejected by the name class). Pre-existing and monotone, but IS-1 row 7 claims assignment prefixes are transparent. → condition C-13. |
| **F-8** | architect | **CLOSED** | §3.1 "Dispatch order is longest-prefix and is the row order below", with the three contested chains named (`$((`>`$(`>`${`>`$`; `<<<`>`<<`>`<(`>`<`; `&&`>`&>`>`&`). §3.2's fast-path paragraph is re-derived from the table with the per-character justification. Both audited below. |
| **F-9** | architect | **CLOSED (fixed, not recorded)** | §3.1 rows 1-2 + §10.3's closing paragraph. `sq_ansi` audited in detail below — including the fail-closed claim, which I confirm holds for a non-obvious reason the design does not state. |
| **F-12** | architect | **CLOSED** | §10.2 item 9 now names the whole-line authorization explicitly, with the `… =1 rm -rf A && rm -rf B` example and the "the one place that is not chain-aware" framing. |
| **F-10** | analyst | **CLOSED** | AC-3's header is now "(exit 0 for every row **except L10**, captured)", followed by a three-sentence adjudication paragraph, and the L10 row itself states "**Expected verdict: BLOCK (exit 2) — not exit 0**". There is no longer a reading under which QA reports a red row. Design §10.3 bullet 1 agrees. |
| **F-11** | analyst | **CLOSED** | AC-4 now enumerates S1-S4 as the only permitted sources, forbids transcripts/`git log` by name, and requires a per-line source-artifact citation ("A corpus line without a quoted source artifact does not count toward the 40"). The self-narrowing note on S4 is accurate and honest. Floor verified reachable (R2.0). |

**All twelve are genuinely closed.** F-7 leaves one narrow residual which is a condition, not a re-open.

---

## R2.2 — Counterexample re-runs by inspection

**1. `echo "$(true && rm -rf /etc/x)"` → BLOCK — PASS**
`echo ` buffered; `"` (row 3 NORMAL) → DQ; `$(` (row 6 DQ) pushes CMDSUB saving buffer + DQ, inner starts NORMAL; `true ` buffered; `&&` (row 13 NORMAL) **flushes → position `true`**; ` rm -rf /etc/x`; `)` (row 19 NORMAL, top=CMDSUB) **emits position `rm -rf /etc/x`**, pops, restores buffer + DQ; `"` → NORMAL; EOF flush → `echo ""`. `/etc/x` is outside root → **exit 2**. The round-1 false negative is gone.

**2. `pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"` → BLOCK at depth 1 — PASS**
Depth 0: `split_pipes` does not split (the `|` is in-quote, `guard-rm.sh:133`); the scanner runs (the `\` in `C:\log` is now a fast-path trigger) and also yields the whole string; verb `pwsh` → `classify_command_string(inner, 1)`. Depth 1: **`P = [inner]` first** — so `classify_segment` still sees the undecomposed string, tokens `Remove-Item · -Recurse · ./tmp · | · Tee-Object · C:\log`, verb destructive, walk reaches `C:\log`, matched by `resolve_leaf`'s `[A-Za-z]:*` case (`guard-rm.sh:161`) → not a descendant → **exit 2**. The decomposed positions are additional, not substitutive. F-2's regression is genuinely repaired.

**3. `find /etc -delete` (fixture 9) → BLOCK — PASS** — no fast-path character, so scanner skipped; `P = [s]`; verb `find` is a CARRIER → scan `/etc`, `-delete`: neither destructive nor an interpreter → **no dispatch, no return**; fall through to the byte-unchanged `-delete` branch → `has_delete=1` → walk from `after_verb` → `/etc` offending.

**4. `find /tmp -name '*.log' -delete` (fixture 17) → BLOCK — PASS** — identical path; `/tmp` offending at `j=1`, `-name` breaks the walk at `:254`.

**5. `find . -name '*.log' -exec rm -rf OUT ;` (AC-1 row o) → BLOCK — PASS** — `;` triggers the scanner; both `s` and the scanner position carry the full argv. Verb `find` → carrier scan finds the exact token `rm` → dispatches the existing token walk from `rm`+1 → `OUT` outside → appended to the **global** `segment_offending` (`guard-rm.sh:201`); the `find` branch then hits `(( has_delete == 0 )) && return` at `:250` — which discards nothing, because the offending path is already recorded. Exit 2.

**6. `find . -name '*.log' -delete` (fixture 10) → ALLOW — PASS** — carrier scan finds nothing; `-delete` branch walks `.` → `$PWD` → descendant; `-name` breaks. No offending path.

**7. `A=1 rm -rf OUT` → BLOCK — PASS**, and `AB;rm=x` / `=x` / `1A=x` are **not** assignments — traced against `name="${t%%=*}"` + the three tests in §3.3 (details in F-7 above).

---

## R2.3 — Audit of the NEW material

### R2.3.1 The state table after the round-2 surgery

I re-ran my full round-1 candidate list plus the six new probes the PM named. **The table is total for every input I could construct, with exactly one exception.**

Passing probes (each traced cell-by-cell): `$'…'` · `$"…"` · `<<<` · `${var//x/y}` incl. an escaped `}` · `$(( ))` at NORMAL **and inside DQ** (row 5 DQ + row 19 DQ's ARITH case — the architect's added cell is load-bearing and correct) · `[[ … ]]` · line continuation `\`+LF (correctly does **not** flush — bash joins the lines) · `\` before a quote · mid-token `#` (`http://x#frag`, `${x#*/}` both append) · `case` arm `)` (row 19's "else flush, **no pop**") · `|&` (flush then flush-empty, dropped per B-3) · `;;` · `&>` · `>|` · empty string · `<<-` with tab-stripping · `}` with no PARAM frame (row 21 "else append" — `echo }`, `xargs -I {}`) · `))` with no ARITH frame (row 19 "top=GROUP_PAREN → flush, pop", and bare `))` → "else flush, no pop"; `if ((i<2)); then` traced clean) · nested `${a[${b}]}` (LIFO PARAM pops correctly) · unbalanced `${` (stack non-empty at EOF → parse failure → BLOCK, fail-closed) · `echo "${HOME}"` (**the architect's stated motivation for the two added closers is correct** — without the PARAM frame's `}` handler the stack would never empty and a `"${HOME}"` would BLOCK) · a `)` closing a PROCSUB opened inside DQ (**vacuous, and correctly so**: row 11's DQ cell is `append`, so no PROCSUB frame is ever opened inside double quotes — which is exactly bash's own semantics, and a pleasing asymmetry against rows 4/6 which *do* push in DQ because command substitution *does* happen there).

**The one gap — N-1, below: row 4 × NORMAL has no push case.** Row 4's NORMAL cell reads only `top=BQ → emit inner, pop, restore`. There is no instruction for a backtick seen at NORMAL when the top frame is **not** BQ — i.e. the ordinary top-level `` echo `rm -rf /etc/x` ``, IS-1 row 5. Every other frame-bearing row (18, 19, 20, 21) enumerates its fallthrough explicitly; row 4 does not. A developer who falls through to the neighbouring cells' `append` produces one position `` echo `rm -rf /etc/x` `` → verb `echo` → **ALLOW**, and `s ∈ P` does not rescue it (same string, same verb). That is a false negative on an in-scope behavior. The design's §12 claim "the table is total in all five states with no exception clauses" is therefore **not quite true**.

### R2.3.2 A second, softer ambiguity — PARAM/ARITH interiors (N-2)

§3.1's prose says PARAM/ARITH characters "are appended verbatim"; the table says dispatch is uniform per row. These readings **diverge on real input**:

- *Uniform dispatch:* `echo $((1 << 3))` → row 10 fires inside ARITH, reads `3` as a here-doc delimiter, enqueues it, and EOF with a non-empty queue → **parse failure → BLOCK**. Pre-change: ALLOW. A new, unrecorded ALLOW→BLOCK on a form a developer plausibly types. Likewise `echo ${x:-(}` → unclosed GROUP_PAREN → BLOCK.
- *Verbatim:* those two are safe, but `${UNSET:-$(rm -rf /etc/x)}` yields no inner position — an unrecorded hole against IS-1 row 5's claim that `$( A )` inner positions are judged.

Both readings are **monotone** (neither loses a pre-change BLOCK), so this is not a security regression — but the Developer cannot implement the section without picking one, and each pick carries a residual that §10.2 must name. → condition C-11.

Incidentally, this is where the literal C-1 earns its keep independently of the pwsh case: under the *uniform* reading, `rm -rf ${x:-$(f)} /etc/y` has its `)` flush the buffer with `top=PARAM`, splitting the verb away from `/etc/y` (positions `rm -rf ${x:-$(f` and `)} /etc/y`, both ALLOW) — and only `s ∈ P` at depth 0 restores the BLOCK. See R2.4.

### R2.3.3 The `sq_ansi` flag

Traced all four probes the PM named plus the clear/push/pop questions:

- **Clearing on SQ exit:** the design never says it clears — and it does not need to. `sq_ansi` is *written* only by row 2's NORMAL cell and *read* only by row 1's SQ cell. SQ is enterable **only** from NORMAL row 2 (row 2's DQ cell is `append`, no state change), so every entry rewrites the flag before any read. A stale value is unreachable. Correct by construction, on an invariant the design leaves implicit → one clarifying sentence is worth adding (folded into C-11).
- **Frame push/pop:** pushes occur only from NORMAL/DQ cells and pops restore NORMAL/DQ, so `sq_ansi` is never read across a frame boundary. Safe whether or not it is included in the saved "quote state".
- `$'a\\'` → `\`+`\` consumed as a pair, closing `'` closes SQ, balanced (matches bash: the string `a\`).
- `$'\''` → `\'` consumed, next `'` closes (matches bash: the string `'`).
- `$` immediately before a `'` **inside DQ** → row 2 DQ appends and does not enter SQ, so the flag is neither set nor consulted (matches bash: `$'` inside `"…"` is literal).
- `'$'` followed by another `'` (`echo '$''x'`, and the classic `'a$'\''b'` idiom) → at each SQ entry `prev` is a `'`, not `$`, so `sq_ansi=0`.
- The one wrong-flag input is `\$'…\…'` (an escaped `$` immediately before a normal single-quoted string), where `prev` is the raw `$` and the flag is set spuriously.

**Does a wrong flag really fail closed?** Yes, and for a sharper reason than the design gives. Inside SQ every byte is appended regardless (rows 13/16/17 SQ are all `append`), so a spurious `\`-consumption cannot swallow a *separator* — it can only swallow a **quote**. And swallowing a quote makes the scanner's `'` parity differ from `tokenize()`'s by one; since `s ∈ P` and `tokenize` is byte-unchanged and counts every `'` (`guard-rm.sh:105-106,114`), `tokenize(s)` then returns 1 → `parse_failed` → exit 2. The over-block is therefore *guaranteed*, not merely likely. **Claim verified.** F-9's fix is safe; the residual (`echo \$'a\'` newly BLOCKs) is exotic enough to leave unrecorded.

### R2.3.4 The fast-path list

Trigger set `; & ( ) { } `` ` `` < > \ LF CR`; excluded `: $ | # ' " [ ]`.

- **`:` dropped — correct.** No row keys on `:`; I re-checked all 24.
- **`\` added — necessary and correctly motivated.** It is the only character that makes the scanner's quote tracking diverge from `split_pipes`'s.
- **`$` redundant — correct.** `$(`, `${`, `$((` each require a bracket already in the set; `$'…'` without a backslash produces no scanner-only position (I traced `rm -rf $'/etc/x'`: identical verdict either way, and the un-decoded `$'…'` path is the existing item-4 residual class).
- **`|` redundant — correct, and I verified the underlying premise.** Absent `\`, `#` and `<<`, the scanner's rows 2/3 and `split_pipes`'s `:131-132` toggles are *character-for-character identical*, including the same in-single/in-double cross-guards. So the two passes agree on every `|`.
- **`#` excluded — the argument is sound.** A comment can only *truncate* a position. Skipping the scanner therefore judges *more* text, never less; more text walked = more paths = only additional BLOCKs. No false negative is constructible. (Confirmed on `rm -rf ./x # see /etc/passwd`: BLOCKs either way, pre- and post-change alike.)

**But the derivation being right does not make the implementation right.** The suggested spelling `*[\;\&\(\)\{\}\`\<\>\\]*` puts ten escaped metacharacters — including a backtick and a backslash — inside one bracket expression in a `[[ ]]` pattern. `bash -n` validates syntax, **not** pattern semantics, so a single mis-parsed class member is a **silent false negative**: the scanner is skipped for that character and the guard quietly reverts to `split_pipes`-only. AC-1's rows exercise `;`, `&`, `(`, `)`, `{`, `}`, LF — but **not** the backtick, `<`, `>` or CR. → condition C-12.

---

## R2.4 — Adjudication: the literal C-1 (`s ∈ P` at every depth, including 0)

**Ruling: ACCEPT AS DESIGNED. Do not revert to the depth-conditional minimal form.** Four reasons, in order of weight.

**1. The over-block class has zero occurrences in this repo's actual usage.** I grepped every `*.md` for a destructive verb followed by a top-level `|`. Hits: the `evals/guard-rm-cases.md` fixture table; two README version-history prose rows and one BATCH_PLAN row (`v0.15.0`'s feature blurb — prose, not a command); and this task's own design/gate/PM docs. **No `rm … | tee /abs/path`-shaped command line exists in S1-S4.** The class is theoretical here. AC-4's differential will not flip a single corpus line on account of it, so it costs nothing against AC-3/AC-4's budget — and I separately checked all fourteen AC-3 rows: none has a destructive-or-carrier leading verb ahead of a top-level `|` (L5 leads with `test`, L11 with `printf`), so the false-positive budget is untouched.

**2. The literal form is not merely "safer if you get the flag wrong" — it closes a false negative the minimal form leaves open at depth 0.** The architect under-argued its own case. The scanner *splits* positions inside constructs (`)` with `top=PARAM`, `(` inside ARITH, group braces). Any such split can separate a destructive verb from a later path token — see R2.3.2's `rm -rf ${x:-$(f)} /etc/y`, which the minimal form ALLOWs and the literal form BLOCKs. Depth 0 is precisely where the richest constructs appear. "Add `s` only at depth ≥ 1" would be an optimization that removes a real safety net to buy a false positive nobody in this repo has ever written.

**3. The error-direction argument is correct as far as it goes.** A depth parameter that is wrong (and `depth` is threaded through three call sites — pwsh, the new interpreter branch, and the carrier scan's dispatch) fails **open**: the F-2 regression silently returns. An unconditional `P = [s]` has no parameter to get wrong. For a guard whose posture is fail-closed, trading a silent-open failure mode for a loud-closed one is the correct trade *even if* the false positive were realistic.

**4. It is loud, self-explanatory and reversible.** When it fires, the existing BLOCK message names the offending path (`guard-rm.sh:326-331`) and the override; the operator sees `/tmp/x.log` and knows immediately why. And the architect is right that reverting is one line.

**Condition attached:** the pre-declared class must be **test-pinned, not just prose-declared** — add a driver row `rm -rf ./build | tee /tmp/x.log` with expected **BLOCK** to both drivers and `evals/guard-rm-cases.md`. Without it, a future maintainer "fixing" the false positive silently re-opens F-2, and §10.3's bullet is the only evidence it was deliberate. → condition C-14.

---

## R2.5 — Cross-document consistency (the two amendments were made in parallel)

| Assumption the architect made | The analyst's actual text | Verdict |
|---|---|---|
| AC-3 excepts L10; L10's expected verdict is BLOCK | AC-3 header: "(exit 0 for every row **except L10**, captured)"; a dedicated paragraph "L10 is the single exception, and it is not a defect"; the L10 row states "**Expected verdict: BLOCK (exit 2) — not exit 0**" and "One instance of a class, not a singleton" | **MATCH.** IS-2 and AC-3 no longer contradict. Design §10.3 bullet 1 uses the same framing and the same `guard-rm.sh:114` mechanism |
| AC-4 is IS-2's proof obligation, and inspection does not satisfy it | AC-4's opening: "**AC-4 is the proof obligation for IS-2.** Monotonicity is **not** provable by inspection… A captured differential run is therefore the only evidence accepted for IS-2; code reading does not satisfy this criterion", citing gate F-2 and the pwsh counterexample | **MATCH**, and stronger than the design needed. §3.2, §8 R5 and §12 agree |
| Any BLOCK→ALLOW flip fails, unwaivable | AC-4 pass condition: "**Any BLOCK→ALLOW flip, on any line, at any recursion depth, fails AC-4 and fails IS-2** — it is neither recordable nor waivable" | **MATCH** with the design's invariant. Note the "at any recursion depth" clause is exactly what makes the differential able to catch an F-2-class regression |
| Corpus is a readable artifact set | S1-S4 enumerated, transcripts/`git log` forbidden by name, per-line source citation mandated | **MATCH.** S4 narrowing (`AI-GUIDE.md` lists paths, not invocations) is **accurate** — I read `AI-GUIDE.md:72-86`; it is prose bullets, and S4's yield is ~0. The ≥40 floor is still comfortably reachable from S2 alone (204 matches / 67 files) |
| §10.2 item 11's class exists in the requirement | IS-1 row 12 / B-13 still say "here-doc body → ALLOW" unchanged | **CONSISTENT, deliberately.** The requirement describes the *scanner's* contract; §10.2 item 11 discloses that the retained pre-change pass is not here-doc-aware. The analyst left rows 12/13 alone, which is right — the honest list is the design's deliverable, not IS-1's |

**One doc nit, no route:** AC-4 says "The AC-1 rows are the sole permitted difference" and then, one sentence later, "Any ALLOW→BLOCK flip outside the AC-1 rows is fixed, **or recorded**". The second sentence governs (it is the operative rule and matches OQ-6a); the first is a summary. QA should not read the first sentence as forbidding the four §10.3 classes. Not worth a round trip — noted here so stage 6 does not re-litigate it.

**No contradiction found between the amended 01 and the amended 02.**

---

## R2.6 — Doc-size ruling (`02_SOLUTION_DESIGN.md`, 746 lines vs the 500 soft cap)

**Claim (a) — "verify_all does not check stage-doc size" — VERIFIED TRUE**, in both shells. `verify_all.sh:384-508` and `verify_all.ps1:371-483` implement I.1-I.5 + I.7 over `AI-GUIDE.md`, `.harness/rules/*.md`, `agents/*.md`, `.harness/insight-index.md`, `docs/tasks.md` and INTERVENE reports only. Neither `0[1-7]_*.md` nor `PM_LOG.md` is measured anywhere. The 500-line stage-doc cap in `70-doc-size.md:30` is **policy without a mechanism**. There is no gate consequence to the overage.

**Claim (b) — is the content earning its lines?** Mostly yes. Applying rule 70's own test ("would a future AI tool need this to make a decision in the next 10 minutes"): the §3.1 table, the §3.3 assignment test, the §3.4 pinned ordering, §6.2's quoting mandate, §9.1's step table, §9.2's PS constraint list, §10.2 and §10.3 are all direct Developer input, and the §3.4/§6 duplication is deliberate *because their disagreement was F-3* — collapsing it would recreate the defect. The doc obeys rule 1 ("reference, don't paste") throughout: it cites `guard-rm.sh:265-271` rather than quoting it.

Two items do **not** earn their lines, and both are cheap:
- **§0, the round-2 changelog (26 lines)** — a stage-transition artifact. It has served its purpose the moment this review is written; it is dead weight for the Developer and for the archive.
- **§1's architecture summary (17 lines)** restates §3.1/§3.2/§3.3/§3.5 in prose.

Even removing both lands at ~700 — the overage is structural, not editorial.

**Ruling: WARN, accepted with rationale recorded; do not trim before Development.** Trimming now costs an architect round against a rollback budget already at one, buys no gate green (there is none to buy), and risks cutting a specification. A security fix does not get delayed for a mechanism-less soft cap. **But the record must be honest:** the PM should note in `PM_LOG.md` that this stage doc ships at ~1.5× the soft cap by deliberate decision, and §0 should be dropped at delivery/archive time (a Developer-stage or PM housekeeping action, not an architect round). If this repo wants the cap enforced, that is a new pool row for an `I.8` stage-doc check — explicitly **not** this task (AC-8 freezes the count at 32).

**A related and more important size point, which the architect got half-right:** `.harness/rules/75-safety-hook.md` at >200 lines is **not** cosmetic. `verify_all.sh:824` exits **1** on `warns > 0`, so an I.2 WARN means `verify_all` does not PASS, and **AC-8 fails**. The 136-line current size leaves 64 lines against the design's 55-line budget — adequate, but C-9 is now a hard requirement, not hygiene.

---

## R2.7 — Did the amendments break anything round 1 approved?

| Round-1 approved item | Still intact? |
|---|---|
| Override fail-closed shape, C-4 placement | **YES** — §5.1 states "evaluated exactly once, on the top-level `cmd`, and never inside `classify_command_string` or `classify_segment` (gate C-4)", with the self-authorization counterexample. §6's flow puts `[2b]` between `[2]` and `[3]`, before the `.git/` walk. All three round-1 bypass paths still fail closed under the amended §3.3 (the assignment strip is what makes `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` BLOCK, and the new exact test still classifies that token as an assignment) |
| Carrier false-positive boundary (L8/L13 ALLOW) | **YES** — §3.4 still keys on the *post-prefix verb*, not on token presence. Re-traced: L8 `grep -rn "rm -rf OUT" .` (verb `grep`, not a carrier; also no fast-path character, so the scanner never runs) and L13 `git commit -m "…"` (verb `git`) both ALLOW. `xargs -I {} rm -rf OUT` still BLOCKs — and I re-checked row 20's `{` cell for it: at the `{` the buffer is `xargs -I ` (non-blank) → append, no GROUP_BRACE push |
| `patsub_replacement` coverage at every rewriting site | **YES, and complete after the amendments.** §6.1 mandates `str_replace_all` for the fallback unescape and for the driver's encoder, blanket-bans `${var//needle/repl}` in new code, and leaves `guard-rm.sh:54-55` byte-unchanged. I re-checked the *new* round-2 code for missed sites: §3.3's `${t%%=*}` and §3.2's trim idiom are prefix/suffix removals, not replacements — `patsub_replacement` does not apply. No gap |
| bash-3.2 safety | **YES.** New constructs are `${s:$i:1}`, `[[ … == *[!A-Za-z0-9_]* ]]`, `$'\n'`/`$'\r'` literals, bracket-class globs and an indexed-array linear scan — all 3.2-legal. No `mapfile`, `${v,,}` or `declare -A` anywhere in the amended text |
| Latency reasoning | **YES, with one new caveat.** §9.3's fork arithmetic is unchanged and still correct (`:265-271` = 18 forks/segment, `:227` = 2). **But** the fast-path list now contains `\`, `<` and `>` — and `>` appears in a large fraction of real Bash calls. §3.2's sentence "A command with none of these characters runs **exactly** today's code path plus one `[[ ]]` test" is now true of a *minority* of commands, so the scanner's per-character loop is on the hot path in practice. This does not change the conclusion (removing ~20 forks/segment still dominates one extra pure-bash pass), but NFR-1's measurement must include a *typical redirecting* command, not only the 8192-char worst case → condition C-15 |
| 14-surface lockstep ledger | **YES** — §11 is unchanged in structure and still accurate. Round 2 added no new fan-out surface: `sq_ansi` is code (surfaces 1-4), the `$'it\'s'` evidence row lands on surfaces 5/6/7, and the new residual/over-block text lands on surfaces 8/9, which the ledger already scopes ("including items 9 and 11"). I re-ran no fan-out grep — round 1's is unaffected |
| **C-8 — `Command position` not re-added to `CONTEXT.md`** | **CONFIRMED CLEAN.** `CONTEXT.md:100-103` carries exactly one entry, unchanged. §11 row 11 reads "**Already done — do NOT re-add (C-8)**", and §2 repeats it. The architect did not touch the file |

**Nothing round 1 approved was broken by the round-2 surgery.**

---

## R2.8 — New findings (round 2)

### WARN — routed to **Developer as binding conditions** (not a design rollback)

**N-1 · Row 4 × NORMAL has no push case — the top-level backtick is unspecified.**
`§3.1` row 4's NORMAL cell reads only `top=BQ → emit inner, pop, restore`. A backtick at NORMAL with an empty stack — `` echo `rm -rf /etc/x` ``, IS-1 row 5 — matches no clause. A developer mirroring the neighbouring `append` cells produces a single position with verb `echo` → **ALLOW**, and `s ∈ P` does not save it. Contradicts §12's "the table is total … with no exception clauses". *Not routed back* because the correct cell content is uniquely determined (a backtick is self-toggling; rows 18-21 all show the pattern) and can be stated exactly, and because C-10's mandated driver row turns a wrong implementation red at edit-sequence step 4. → **C-10**.

**N-2 · PARAM/ARITH interior semantics are ambiguous, and the two readings diverge on real input.**
§3.1's prose ("appended verbatim") and the table (uniform dispatch) disagree. Uniform dispatch newly BLOCKs `echo $((1 << 3))` (row 10 fires inside ARITH, enqueues `3` as a here-doc delimiter, EOF with a non-empty queue → parse failure) and `echo ${x:-(}`; verbatim leaves `${UNSET:-$(rm -rf /etc/x)}` unjudged against IS-1 row 5's claim. Both readings are monotone, so this is a coverage-honesty and false-positive question, not a security regression. → **C-11**.

**N-3 · The fast-path bracket expression is an unverified single point of silent failure.**
The derivation is sound (R2.3.4) but the *spelling* is not testable by `bash -n`, and AC-1 exercises only 7 of the 12 trigger characters. A mis-parsed backtick, `<`, `>` or CR class member silently disables the scanner for that character. → **C-12**.

**N-4 · `A+=1` and `a[0]=1` assignment prefixes remain opaque in both shells.**
§3.3's `name="${t%%=*}"` yields `A+` / `a[0]`, both rejected by the name class; the PS regex has the identical gap. `A+=1 rm -rf /etc/x` is a live shell form and IS-1 row 7 claims assignment prefixes are transparent. Pre-existing and monotone (no regression), and the `+=` case is a one-character fix. → **C-13**.

**N-5 · The C-1 over-block is prose-declared but not test-pinned.** See R2.4. → **C-14**.

### Observations, no route, no condition
- Nested backticks (`` `a \`b\` c` ``) are appended rather than nested (row 1 consumes the escaped backtick). Monotone, exotic; mention in the rule doc only if the residual section has room.
- `echo \$'a\'` newly BLOCKs via the spurious `sq_ansi` (R2.3.3). Guaranteed fail-closed, absurdly rare; not worth a rule-doc line.
- AC-4's "sole permitted difference" / "or recorded" wording (R2.5). QA guidance only.

---

## R2.9 — Audit checklist (round 2)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | IS-1 is total (row 19 + IS-2 + IS-3); AC-3 no longer contradicts IS-2 at L10; AC-4 is now sourced from four enumerated readable artifacts with a per-line citation duty and an unwaivable BLOCK→ALLOW clause. Both round-1 defects are closed at the criterion QA executes |
| 2 | Design completeness | **PASS** | The nested-frame quote save/restore closes the F-1 false negative (counterexample re-run), the `find` ordering is pinned identically in §3.4 and §6, and the union invariant is restated at every depth. One unspecified cell remains (N-1), stated exactly as C-10 and test-pinned |
| 3 | Reuse correctness | **PASS** | Re-checked the round-2-added citations: `guard-rm.ps1:19/94/97/117/174/178` all exist as described; `guard-rm.sh:250`'s early `return` provably cannot discard the carrier scan's hits because `segment_offending` is global (`:201`) |
| 4 | Risk coverage | **PASS** | R11 now carries the .NET out-of-range class with the exit-1-fails-open mechanism named and mapped to a concrete mitigation; R1's overstatement is withdrawn in place; R5 and R7 are corrected to the true failure modes |
| 5 | Migration safety | **PASS** | Unchanged and still correct: no data migration, no feature flag under NFR-5, and the step table leaves the live guard valid after every step, with `sync-self --check` now mandated first |
| 6 | Boundary handling | **PASS** | The table survived my full re-probe (24 rows × 3 states + 6 new probes) with one gap and one ambiguity, both monotone and both conditioned. `sq_ansi`'s fail-closed direction is *provable*, not merely asserted |
| 7 | Test feasibility | **PASS** | Every AC maps to a captured exit code; the stride-4 encoding plus the mandatory single-quote rule makes AC-1 row i expressible without executing it; AC-4's corpus floor is verified reachable from S2 alone |
| 8 | Out-of-scope clarity | **PASS** | §10.1 unchanged; §10.2 now has the general union-residue statement plus the override's whole-line scope; §10.3 pre-declares four over-block classes. The residual list is now a superset-honest account rather than a coverage claim — which is the deliverable this task exists for |

---

## R2.10 — Predicted developer questions, round 2 (pre-answered)

**Q8 — "I hit a backtick at NORMAL with an empty stack. Append or push?"**
**Push.** Row 4 NORMAL is `top=BQ → emit inner, pop, restore; else push BQ (save buffer + quote state)`. A backtick is self-toggling — there is no separate opener and closer. Appending gives you a false negative on `` echo `rm -rf /etc/x` ``, and C-10's driver row will go red if you do. (Round-1 Q1's answer — inner buffer starts at NORMAL, outer quote state resumes on pop — now applies to BQ too, and it is why the *closing* backtick is always seen in NORMAL even when the frame was opened in DQ.)

**Q9 — "Inside `${…}` / `$((…))`, does the table still dispatch, or do I copy bytes until the closer?"**
**Copy bytes until the matching closer** (C-11), tracking only three things: the closer, a nested `${` / `$((` / `(` / `{` for balance, and `\`+next. Do not let rows 10, 13, 16, 17, 18 fire inside those frames — `echo $((1 << 3))` would otherwise enqueue `3` as a here-doc delimiter and BLOCK. The cost is that `${x:-$(rm …)}` yields no inner position; record it in §10.2 as class 2/5 kin. The whole-string position (`s ∈ P`) still walks its tokens, so nothing pre-change is lost.

**Q10 — "Can I trust the one-line fast-path glob?"**
Not until you have proven it per character. `bash -n` checks syntax, not pattern semantics, and a dropped class member silently disables the scanner — the exact shape of a shipped false negative. Either use the twelve separate `[[ ]]` tests §3.2 already blesses, or add a probe per trigger character. The four AC-1 never reaches are the backtick, `<`, `>` and CR.

**Q11 — "AC-4 wants 40 corpus lines and `AI-GUIDE.md` turned out to be a dud. Where do I get them?"**
S2 carries it alone: 204 `(bash|pwsh) …/.harness/scripts/…` invocation lines across 67 archived stage docs. Harvest **distinct** lines (the criterion says distinct — de-duplicate `bash .harness/scripts/verify_all.sh`, which repeats heavily), top up from S1's fenced blocks in `README.md` / `docs/getting-started.md` / `docs/dev-map.md` and S3's `hook-spec.{sh,ps1}` byte-forms, and quote the source path per line or it does not count.

**Q12 — "`rm -rf ./build | tee /tmp/x.log` now BLOCKs. Is that a bug I should fix?"**
**No — it is the design, it was adjudicated at this gate, and it is now pinned by a test (C-14).** The literal C-1 invariant (`s ∈ P` at depth 0 too) is what keeps `pwsh -c "… | Tee-Object C:\log"` a BLOCK and what keeps a scanner-split position from separating `rm` from a later absolute path. If you "fix" it with a depth condition you re-open F-2 with a **silent, fail-open** failure mode. Zero commands of this shape exist in the repo. The workaround for a user is the override.

**Q13 — "`75-safety-hook.md` is going to be tight. Can it run a few lines over 200?"**
No. `verify_all.sh:824` exits **1** on any WARN, so a 201-line rule doc means `verify_all` does not PASS and **AC-8 fails**. You have 64 lines (136 → 200) against a 55-line budget. Follow R9: **replace** the "first token after optional `sudo`" sentence and the out-of-scope bullet rather than appending beside them.

---

## R2.11 — Consolidated conditions (authoritative; supersedes round-1 C-1…C-9)

Round-1 **C-1 … C-8 all stand**; several are now design text rather than gaps, but they remain the Developer's checklist. **C-9 is strengthened.** **C-10 … C-15 are new this round.**

| # | Condition | Status |
|---|---|---|
| **C-1** | `P` contains the input string `s` itself at **every** depth, **including depth 0**. Do **not** make it depth-conditional — that failure mode is silent and open. AC-4's differential run, not inspection, is IS-2's proof. | stands (now §3.2/§6) — **literal form adjudicated and accepted, R2.4** |
| **C-2** | Nesting frames save **and restore** the quote state; the inner buffer of `` $( ``/`` ` ``/`<(` starts at `NORMAL`. | stands (now §3.1) |
| **C-3** | Verb `find`: carrier scan **first, no `return`**, then the byte-unchanged `-delete` branch. | stands (now §3.4/§6) |
| **C-4** | The command-text override is evaluated **once**, on the top-level `cmd`, before the `.git/` walk and before any parsing. Never inside `classify_command_string` / `classify_segment`. | stands (§5.1) |
| **C-5** | Driver rows: single-quote (or `$'…'`) every row containing `$`, `` ` `` or `$(`, in **both** shells; confirm each new row's `cmd` echoes back intact in its PASS line. | stands (§6.2) |
| **C-6** | Run `sync-self.sh --check` before promoting and confirm only the `guard-rm` pair is drifted; after promoting, re-run the driver against the default path and **quote** the captured tally. | stands (§9.1 step 5) |
| **C-7** | PS: length-guard every lookahead; wrap the scanner in `try/catch` mapping any exception to the parse-fail path. An escaping terminating error exits 1 and **disarms the guard**. | stands (§9.2, R11) |
| **C-8** | Do **not** re-add `Command position` to `CONTEXT.md` — it is at `CONTEXT.md:100-103`. | stands; re-confirmed clean |
| **C-9** | `.harness/rules/75-safety-hook.md` must land **≤ 200 lines** (136 today; 55-line budget → ≤191). **Hard, not cosmetic: `verify_all.sh:824` exits 1 on any WARN, so a 201-line rule doc fails AC-8.** The residual section must carry §10.2 items 9 and 11 and all four §10.3 classes, plus the residuals from C-11 and C-13. | **strengthened** |
| **C-10** | **NEW.** Row 4 × NORMAL reads: `top=BQ → emit inner, pop, restore; **else push BQ (save buffer + quote state)**`. Add driver rows `` echo `rm -rf OUT` `` → **BLOCK** and `cat <(rm -rf OUT)` → **BLOCK** to both drivers and `evals/guard-rm-cases.md`. | N-1 |
| **C-11** | **NEW.** Pin PARAM/ARITH interior semantics to **verbatim-until-closer** (recognize only the matching closer, a nested `${`/`$((`/`(`/`{` for balance, and `\`+next); no other row fires inside those frames. Add driver rows `echo $((1 << 3))` → **ALLOW** and `echo "${HOME}"` → **ALLOW**. Record in §10.2 that `${x:-$(cmd)}` inner text yields no position (class 2/5 kin). Add one code comment: *`sq_ansi` is meaningful only while state == SQ; it is re-set on every SQ entry and never read otherwise.* | N-2 |
| **C-12** | **NEW.** Prove the fast-path trigger test **per character**: either use the twelve separate `[[ ]]` tests §3.2 blesses, or add a probe row for each of `; & ( ) { } `` ` `` < > \ LF CR`. AC-1 covers only 7 of the 12; a mis-parsed bracket-expression member is a silent false negative. | N-3 |
| **C-13** | **NEW.** In §3.3's assignment test, strip an optional trailing `+` from the name (`name="${name%+}"`) so `A+=1 rm -rf OUT` BLOCKs; mirror it in the PS regex (`^[A-Za-z_][A-Za-z0-9_]*\+?=`). Record `a[0]=1 rm -rf OUT` (array-element assignment prefix) as a residual in §10.2. | N-4 |
| **C-14** | **NEW.** Test-pin the C-1 over-block: driver row `rm -rf ./build \| tee /tmp/x.log` → **BLOCK** (expected), in both drivers and the fixture, so a future "fix" cannot silently re-open F-2. | N-5 / R2.4 |
| **C-15** | **NEW.** NFR-1's measurement set must add a *typical redirecting* command (e.g. `echo hi > ./f`) alongside the ~120-char and 8192-char cases: `>` and `\` are now fast-path triggers, so the slow path is the common path, and §3.2's "runs exactly today's code path" sentence no longer describes most real commands. | R2.7 |

---

## R2.12 — What changed since round 1, in one paragraph

Both authors did surgical work. The analyst's two corrections landed exactly where I asked and are slightly stronger than requested (AC-4's unwaivable BLOCK→ALLOW clause, and the honest self-narrowing of S4). The architect closed all ten design findings, and the two mechanisms it invented to do so — the frame quote save/restore and the `sq_ansi` bit — both survive adversarial re-probing; `sq_ansi`'s fail-closed claim is in fact provable via `tokenize`'s quote parity, which is a stronger guarantee than the design states. The three round-1 blockers (false negative, monotonicity violation, branch-ordering contradiction) are gone, verified by re-running the original counterexamples cell by cell. What remains is one unspecified table cell, one prose/table ambiguity, one untested bracket expression, one one-character gap in the assignment test, and one unpinned pre-declared over-block — five items that are each a single line of specification, all monotone (none can lose a pre-change BLOCK), and all closed by conditions with a **red test row** attached where a wrong choice would otherwise be silent. That is not worth a third round; a design rollback here would buy prose, not safety.

---

## Verdict (round 2)

**APPROVED FOR DEVELOPMENT** — full-mode equivalent: **APPROVED WITH CONDITIONS**.

Development may proceed against `01_REQUIREMENT_ANALYSIS.md` (round 2) and `02_SOLUTION_DESIGN.md` (round 2), subject to the fifteen conditions in R2.11, which supersede round-1's C-1…C-9 as the single authoritative list. Findings **F-1 … F-12 are all closed**; no finding is routed back to either upstream stage. `02_SOLUTION_DESIGN.md`'s 746-line overage against the 500-line soft cap is **accepted with rationale recorded** (no gate mechanism exists; the over-cap content is specification) — PM should note it in `PM_LOG.md` and drop §0 at delivery.
