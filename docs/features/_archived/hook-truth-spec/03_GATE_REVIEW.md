# 03 — Gate Review · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 3 (gate-reviewer) · **Round**: 2 (re-review after stage-2 rework) · **Date**: 2026-07-31
**Upstream**: `01_REQUIREMENT_ANALYSIS.md` (READY, + Amendment 1) · `02_SOLUTION_DESIGN.md` (READY, Rework round 1)
**Gate baseline**: `verify_all` bash PASS 32 / WARN 0 / FAIL 0 — must stay 32.

> Transcription note (PM): the gate-reviewer agent is read-only by contract (Read/Glob/Grep) and returned this report as text. PM persisted it verbatim; no PM editing of content. **This report supersedes and replaces round 1**; §2 carries round 1's findings and their disposition so this file remains the complete gate record.

---

## 1. Audit checklist (round 2)

| # | Dimension | R1 | R2 | One-line reason |
|---|---|---|---|---|
| 1 | Requirement completeness | PASS | **PASS** | Amendment 1 is genuinely narrow: FR-1…FR-16 unrenumbered, B-15 appended (§4 now 15 rows), AC-14 appended (now 14), NFR-4 rewritten in place into three explicitly-scoped clauses; NFR-2's fail-closed hard-reject is byte-untouched and its "any boundary condition in §4" scope now automatically covers B-15. |
| 2 | Design completeness | PASS | **PASS** | Every FR still maps to a §11 ledger row with a mirror obligation; the new material (B-15/AC-14/extended FR-12) is already satisfied by §5.3's stdout contract and §15's no-`.gitignore`-edit boundary — verified below, no design gap owed. |
| 3 | Reuse correctness | PASS | **PASS** | Every newly-added citation checks out at the cited line: `test-verify-i6.sh:332-335`, `test-harness-upgrade.ps1:296` and `:599/:603/:608`, `docs/dev-map.md:112-114`, `.harness/rules/10-self-consistency.md:7`, `docs/tasks.md:48`, `baseline.json:10-12`, `README.md:5`. |
| 4 | Risk coverage | WARN | **PASS** | R-2 now enumerates the surviving duplication by file:line, and the rework adds R-7 (oracle silently extracts nothing) — which is exactly the failure mode option (a) introduces, and it is mitigated by a call-through assertion I confirmed cannot pass vacuously. |
| 5 | Migration safety | PASS | **PASS** | Unchanged: no schema/data migration, additive + one localized installer edit, `git revert` restores, the only side effect is a gitignored deterministically-reproducible file. |
| 6 | Boundary handling | PASS | **PASS** | §8's truth table is still total over its 16 combinations and every row fails safe; gate Minor 1 is resolved with an explicit 3-way existence probe (0a/0b) that states the answer rather than inheriting `[ -e ]`/`[ -f ]` disagreement; B-15 is satisfied by construction (`.gitignore` is not an input to the table and §15 forbids the edit). |
| 7 | Test feasibility | **FAIL** | **PASS** | F-2 resolved: the false transitivity rationale is deleted, the oracle is re-pointed at two live OS-parametric helpers, and I verified independently that a single Linux bash run does exercise all four Windows and all four unix forms. |
| 8 | Out-of-scope clarity | **FAIL** | **PASS** | F-1 resolved: I re-grepped independently and the live set is genuinely closed at five sites; no frozen claim is scheduled to flip; the two new decoys are correctly characterized. |

**8 of 8 PASS.**

---

## 2. Round-1 findings and their disposition

| R1 finding | Severity | Owner | Disposition in round 2 | Verified how |
|---|---|---|---|---|
| **F-1** count-ledger missed `docs/dev-map.md:176` | FAIL | SA | **RESOLVED.** §11's ledger is now a 5-row table naming :176 (numeral *and* the seven-name parenthetical), plus a reproducible search-method note. | Independent re-grep, §3 below |
| **F-2** AC-3's proof rested on a non-existent transitive chain | FAIL | SA | **RESOLVED.** All four sub-claims re-verified true by the architect, false rationale deleted, option (a) adopted, per-comparison evidentiary status stated, Group A′ relabelled lockstep-only. | Helper signatures/bodies + precedent + anti-vacuity, §4 below |
| **W-1** `set -euo pipefail` pre-empts exit 4 | WARN | SA | **FOLDED IN.** §3.2 "Spec capture" mandates `if ! v="$(…)"` for *every* spec call (`hostos`, `tools`, `event`, `matcher`, `command`), a **separate** `[ -n "$cmd" ]` check, and captures the tool list *before* the loop. | §5 below |
| **W-2** template-twin wording | WARN | SA | **FOLDED IN.** §2 now says the six `templates/<type>/…/verify_all.{ps1,sh}.tmpl` *do* exist and need no edit, with the grep that shows it. | §5 below |
| **W-3** decoy/D11 gaps | WARN | SA | **FOLDED IN.** `CHANGELOG.md:334` named beside `:261`; `docs/tasks.md` added as decoy 10 **with** the T-13 ID collision; `docs/dev-map.md:112-114` added to D3 as an append-only refresh. | §5 below |
| **W-4** PS write API unpinned for the settings body | WARN | SA | **FOLDED IN.** `[System.IO.File]::WriteAllText` pinned for **both** bodies with the BOM/UTF-16LE rationale; `Set-Content`/`Out-File` explicitly prohibited. | §5 below |
| **W-5** NFR-4 over-claimed for generated projects | WARN | RA | **RESOLVED by Amendment 1** (three scoped clauses + B-15 + AC-14 + extended FR-12). | §6 below |
| **W-6** R-2 undercounted the duplication | WARN | SA | **FOLDED IN**, with `.ps1` line numbers I had not cited. All verified to exist; one omission (advisory A-1). | §5 below |
| **Minor 1** non-regular file at the local-settings path | minor | SA | **FOLDED IN.** §3.2 step 0b: non-regular ⇒ `present` for the machine-local path, `unparseable` for the committed path. | Read |
| **Minor 2** PS gate hard-parses the local settings | minor | SA | **FOLDED IN** as §14 item 4 + R-5, carried to 07_DELIVERY. | Read |

Everything adjudicated correct in round 1 and not disturbed by the rework is carried forward unchanged: **D-1**'s interface widening (JUSTIFIED — `event`/`matcher`/`hostos` are required by FR-8, `verify_all.sh:652`, `verify_all.sh:315` and B-11; OQ-8 untouched); **D-2**'s CRLF-throughout claim (VERIFIED byte-for-byte — `.gitattributes:7` unconditional, `install-hooks.ps1` 73 CR / 73 lines, the `@'…'@` body at `:35-63`, the fix correct for both bodies and both mirror halves); **D-3**'s intent-reading of AC-12 (ACCEPTED — G.4 pins only check-count claims, `verify_all.sh:732-770`); the §8 truth table's totality and fail-safety; FC-1…FC-4's mechanical checkability; and the captured-not-derived baseline discipline.

---

## 3. F-1 — independently re-grepped; the live set is closed at five

I did not take the architect's word. I re-ran the search myself with a wider net than his (`script pairs`, `script-pair`, `script pair`, `mirror set`, `mirrors only`, `脚本对`, plus `(seven|7).{0,30}(pair|mirror|mapping)` and its inverse, case-insensitive, whole repo), then swept every file containing `sync-self` at all (80 files).

**Live sites — exactly five, matching the ledger:**

| # | Site | Text | In ledger? |
|---|---|---|---|
| 1 | `AI-GUIDE.md:76` | "7 dogfood script pairs (harness-sync, install-hooks, archive-task, guard-rm, migrate-scripts-layout, upgrade-project, language-policy)" | yes (D4) |
| 2 | `docs/dev-map.md:142` | "repo SOT (7 script pairs)" | yes (D3) |
| 3 | `docs/dev-map.md:163` | "sync-self touches only the 7 script pairs" | yes (D3) |
| 4 | `docs/dev-map.md:164` | same sentence, rejected-decisions row | yes (D3) |
| 5 | `docs/dev-map.md:176` | "one of the 7 mirrored script pairs (`harness-sync`, …, `language-policy`)" — `## Reusable utilities` | **yes (D3)** ← the round-1 miss, now closed |

**No sixth site exists.** Confirmed absent from `README.md`, `README.zh-CN.md`, `CONTRIBUTING.md`, `docs/getting-started.md`, `docs/concepts.md`, `docs/workflow.md`, every `.harness/rules/*.md`, `evals/`, `CONTEXT.md`, and every live `.html`. The two `README.zh-CN.md` hits (`:272`, `:280`) are historical version-table rows using 脚本对 in an unrelated sense ("回归脚本对", "ambient hook 脚本对") — not mirror-set counts. `docs/dev-map.md:88` describes `sync-self` with no count at all.

**Non-count enumerations that must move in lockstep** — all present in the ledger: `sync-self.ps1:8-21` (C2), `docs/dev-map.md:27` and `:91-98` script trees (D3), `AI-GUIDE.md` Scripts bullet list (D4). I confirmed both trees exist at those lines.

**Frozen side — re-adjudicated, nothing wrongly scheduled to flip.** I re-checked every decoy against the ledger's edit instructions: D1 edits `75-safety-hook.md` §82-87 (not the frozen `:10` attribution); D3 *appends* to `dev-map.md:112-114` without rewriting its `(T-12 v0.44)` attribution; D6 adds a new `## [0.45.0]` heading and edits no historical entry; D9/D10 move the version badge only and explicitly forbid touching `verify__all-32%2F32` / `test--init-316%2F316` (I confirmed both live at `README.md:5`); D11 touches only `docs/tasks.md:9`. **No frozen claim moves.**

**The two new decoys are correct.**
- Decoy 10 (`docs/tasks.md`): the collision is real — `docs/tasks.md:48` is `T-13 | lang-policy-split | Delivered v0.24.0`, and it is the *first* `T-13` a naive grep hits after line 9. Correctly characterized as append-only history.
- Decoy 11 (`.harness/rules/10-self-consistency.md:7`): verified verbatim — *"The source of truth for the 7 agents and `harness-sync` scripts is `skills/harness-init/templates/common/`."* This is a numerically identical "7" about the **agent** count, not the mirror set. Correctly frozen, and its v0.30 staleness (agents are 8 and plugin-native since v0.30) is genuinely pre-existing and out of scope.

Two further frozen items my sweep turned up that the decoy list does not name (advisory A-7, non-blocking): `docs/v0.11-changes.html:278` ("sync-self 只同步 … + 4 个脚本对") — a dated historical page already stale by three counts, and `evals/golden-tasks.md:78` (`.\scripts\sync-self.ps1`, a pre-T-007 path with no count). Neither is a count claim requiring a flip; recording them makes the set provably closed.

**Verdict on F-1: RESOLVED.** Dimension 8 → PASS.

---

## 4. F-2 — the decisive claim verified against the actual helper bodies

### (i) OS-parametric — TRUE, and this is the load-bearing fact

```
upgrade-project.sh:102   resilient_cmd() {
upgrade-project.sh:103       local rc_tool="$1" rc_win="$2"
upgrade-project.sh:104       if [[ "$rc_win" == true ]]; then …
```
```
upgrade-project.ps1:112  function Get-ResilientCmd($tool, $forWin) {
upgrade-project.ps1:113      if ($forWin) { …
```

Both take the OS as a **positional parameter**. Neither reads `$OSTYPE`, `$IsWindows`, `$env:OS` or any host signal anywhere in its body (lines 102-117 / 112-126 read in full). Therefore `resilient_cmd guard-rm true` on Linux returns the *Windows* byte-form, and a single Linux bash run of the new `test_hook_spec` can drive all 8 `(tool, OS)` cells against a live oracle. **The architect's decisive claim is true.** The design's Group A table ("Independent for all 8; none host-OS-only") is accurate, and this is a real upgrade over round 1, where 4 of 8 were literal-vs-literal.

Both helpers are live production code, not dead: `resilient_cmd` is called at `upgrade-project.sh:282` and `:340`; `Get-ResilientCmd` at `upgrade-project.ps1:286` and `:338`. So an edit to either implementation genuinely moves only one side of the comparison — the oracle is independent, as claimed.

### (ii) Sourcing is prohibited — TRUE for both helpers, and stronger than stated

`upgrade-project.sh` runs an argument-parsing `while` loop at `:36-47` and a precondition block at `:51-81` that calls **`exit 1`** — sourcing it would not merely "run a flow", it would terminate the sourcing shell (the test driver) before reaching line 102. `upgrade-project.ps1` reaches `Emit ("TYPE|{0}" -f $Type)` at `:128` on load. Function-definition extraction is not just preferable here, it is the only workable option. Claim confirmed.

### (iii) The cited extraction precedent exists and is applicable

`test-verify-i6.sh:332-335`:
```bash
extract_i6_banned() {
    awk '/^i6_banned=\(/{f=1;next} f&&/^\)/{f=0} f{print}' "$1" \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}
```
This is a genuine awk-range extraction of a live definition out of `verify_all.sh` for a lockstep compare — exactly the technique §9 mandates. `extract_ps_banned_records` (`:344-359`) is its PS-side counterpart. **One honest difference** (advisory A-4): the precedent extracts an *array* definition as text and never `eval`s it; the design's bash step adds `eval` of a *function* definition. The `eval` is new to this repo, not precedented. I checked that this is safe rather than merely conventional: I traced the design's awk program `/^resilient_cmd\(\) \{$/{f=1} f{print} f&&/^\}$/{exit}` against the real file — the header at `:102` matches `^resilient_cmd\(\) \{$`, the terminator at `:117` matches `^\}$` at column 0, and the ordering prints 102-117 inclusive before exiting. The extracted body declares `local rc_tool rc_win` and touches nothing else. No `eval` is banned by `verify_all`'s I.6 list (`verify_all.sh:531-546` — I read all 14 entries) or by any insight-index line (all 30 read).

### (iv) The anti-vacuity assertion cannot be implemented vacuously — VERIFIED

§9's mandate: *"Anti-vacuity gate (mandatory, one named assertion per shell, before the 8): `resilient_cmd guard-rm true` returns a non-empty string containing `guard-rm.ps1`. A failed extraction must fail that assertion loudly, never silently degrade the comparisons."*

This is a **call-through** assertion, not a "the extracted text was non-empty" assertion, which is the distinction that makes it non-defeatable. I verified the three ways a developer could accidentally make it pass while extraction yielded nothing, and all three are closed:

1. **Shadowing.** I grepped both drivers: `test-init.sh` defines no `resilient_cmd` (it has `ti_replace_all`, not the helper), and `test-init.ps1` mentions `Get-ResilientCmd` only in a comment at `:650` — no function definition. So a green anti-vacuity assertion cannot come from a pre-existing definition in the driver's scope.
2. **Silent empty result.** `test-init.sh:5` is `set -uo pipefail` — **no `-e`** — so a failed `eval` does not abort the driver; the subsequent `resilient_cmd guard-rm true` produces `command not found` on stderr and an empty stdout, which fails both halves of the assertion (non-empty **and** contains `guard-rm.ps1`).
3. **Wrong-OS false positive.** `true` selects the Windows branch, whose output contains `guard-rm.ps1`; the unix branch contains `guard-rm.sh`. The substring is discriminating.

Advisory A-3: the PS-side analogue is mandated ("one named assertion per shell") but its exact arguments are not spelled out the way the bash form is. `Get-ResilientCmd guard-rm $true` → must contain `guard-rm.ps1` is the obvious transcription and is derivable from the pinned signature; not a blocker.

### Residual honesty check

- Group A′ is relabelled **"Lockstep only — the fixtures are hand copies; catches fixture drift, is *not* independent evidence."** ✓
- §9 states plainly: *"The pre-existing `:324`/`:326` assertions are composition-integrity and must **not** be called drift-catchers in any doc."* **No composition-integrity check is described anywhere in the revised design as a drift-catcher.** ✓ This closes the insight-index 2026-06-09 contradiction that drove F-2.
- The cross-shell residual is stated, not papered over: each shell's chain closes inside its own shell; cross-shell twin identity rests on [M2] hand-lockstep + NFR-5's operator run, "recorded green-by-symmetry-only until then." ✓
- The prohibition on populating `EXP_*` or the four `*_COMMAND` variables from `hook-spec` is retained — without it the pre-existing C3 assertions would themselves degrade to composition-integrity. ✓

**Verdict on F-2: RESOLVED.** Dimension 7 → PASS.

Advisory A-2: §9's oracle reads `upgrade-project`'s copy only. `migrate-scripts-layout.sh:117` and `.ps1:36` carry a **second, independent** `resilient_cmd`/`Get-ResilientCmd` with the same name. I read `migrate-scripts-layout.sh:117-131` and confirm it is byte-identical to `upgrade-project.sh:102-117` today, so nothing is broken — but Group A pins the spec against one of the four helpers, not all four. R-2 already enumerates them as surviving duplication; §9 does not restate which copy the oracle reads. One clarifying sentence at development time removes any ambiguity.

---

## 5. W-1…W-6 and the Minors — folded in, not merely acknowledged

**W-1 (load-bearing, spot-checked).** §3.2's "Spec capture under `set -euo pipefail`" names `install-hooks.sh:16` as the cause, mandates `if ! cmd="$(…)"; then <diag>; exit 4; fi` for **every** spec call and enumerates them (`hostos`, `tools`, `event`, `matcher`, `command`), requires a **separate** `[ -n "$cmd" ]` check for the empty case, and — the part I specifically asked for — explicitly covers the loop: *"The tool list is captured the same way **before** the loop (`for tool in $(hook-spec …)` inherits the same abort)"*. §6 step 5 repeats the obligation inline. Genuinely folded in; no call site is left uncovered.

**W-2.** §2 now states the precise truth: 19 files under `templates/common/.harness/scripts/` with neither `sync-self.*` nor `verify_all.*`; the six `templates/{backend,fullstack,generic}/…/verify_all.{ps1,sh}.tmpl` **do exist** and require no edit, with the reason (no F.1-style array, names none of the affected scripts).

**W-3.** `CHANGELOG.md:334` is now named beside `:261` (both verified verbatim). `docs/tasks.md` is decoy 10 with the ID collision spelled out and `:48` confirmed. `docs/dev-map.md:112-114` is added to D3 as an **append-only** refresh, and I confirmed the `settings.local.json` row does span exactly 112-114.

**W-4 (load-bearing, spot-checked).** §3.2 pins `[System.IO.File]::WriteAllText($tmp, $body)` for the **settings** body — "BOM-free by contract" — followed by `Move-Item -LiteralPath`, and prohibits `Set-Content`/`Out-File` for *both* bodies with the correct rationale (5.1 BOM / UTF-16LE default breaking AC-10, J.1's anchored `^[[:space:]]*"\$schema"` grep and J.1's indent parser). §4 repeats "BOM-free, both shells (B-13, AC-10, W-4)"; ledger row B2 repeats it a third time. Pinned everywhere it matters.

**W-6 (load-bearing, new citations verified).** I read every newly-added `.ps1` line:
- `test-harness-upgrade.ps1:296` — `$t20pick = 'pwsh -NoProfile -Command \"…harness-sync.ps1…\"'` ✓ JSON-escaped Windows form, as described.
- `test-harness-upgrade.ps1:599`, `:603`, `:608` — three raw-`pwsh` guard invocations (`& pwsh -NoProfile -Command "Set-Location … guard-rm.ps1"`) in the Fixture Z fail-closed probe ✓ a genuinely different escaping level, as described.
- The `.sh` citations from round 1 (`:296`, `:306`, `:555`) stand.

Advisory A-1: the `.ps1` JSON-escaped citation names only `:296` (Windows). The **unix** twin sits one branch below at `test-harness-upgrade.ps1:299` and is not cited, though its `.sh` counterpart `:306` is. One missing line number in a T-16 pointer list — trivially fixable during development, not worth a round.

**Minor 1.** Resolved decisively rather than deferred: §3.2 step 0b makes a non-regular file `present` on the machine-local path (report, read nothing, write nothing) and `unparseable` on the committed path (row 1 → exit 3). §8's row-3 note lists it alongside B-6/B-7. Correct on both axes.

**Minor 2.** Recorded at §14 item 4 and as R-5, with the asymmetry stated exactly (`verify_all.ps1:290-291` `ConvertFrom-Json` vs `verify_all.sh:304` grep) and carried into 07_DELIVERY.

---

## 6. New material the architect never saw — the analyst's "no new work" claim, verified

I checked each new/changed requirement item against the *revised* design text, not against the analyst's summary.

| New item | What it demands | Where the revised design already provides it | Gap? |
|---|---|---|---|
| **FR-12 extended** — report also carries the machine-local/gitignore advisory; "modifies no `.gitignore` in any code path; the advisory is printed, never applied" | a printed advisory + a no-edit guarantee | §5.3 verbatim: *"…and a note that the file is machine-local and should be gitignored if the project tracks `.claude/`"*; §15 verbatim: *"The installer does not edit `.gitignore`…"* | **No** |
| **B-15** — no `.gitignore`, or one lacking the entry → nothing created or edited, advisory prints, write proceeds; a missing entry is never an error | `.gitignore` state must not gate the write, and must not become an error path | §8's truth table takes only `G`, `L`, `.claude/` as inputs — `.gitignore` is not an axis, so the write proceeds regardless — plus §15's no-edit boundary and §3.2's five exit codes, none of which can be reached by an ignore-rule condition | **No** — satisfied *by construction*, which is the strongest form |
| **AC-14** — AC-5's captured stdout carries all three FR-12 elements; the same run shows no `.gitignore` modification and the created file untracked/ignored | the three elements must be *in the design's report*, and the run must be capturable | §5.3 specifies all three (created path; removal command in this shell's own form `rm <path>` / `Remove-Item <path>`; machine-local/gitignore note). `.gitignore:60` carries `.claude/settings.local.json`, so `git status --porcelain` in this repo shows the file as **ignored** ✓ | **No** — see advisory A-5 |
| **NFR-4** rewritten into (a) universal / (b) this-repo / (c) advisory-by-design | scope correctness | Design needs no change: §15 already forbids the edit, FC-4 already forbids emitting/reading/persisting `HARNESS_ALLOW_OUTSIDE_RM`, R-3 already carries the "silently re-arms a deliberate disable" trust risk | **No** |

**Confirmed independently, against the amendment's own evidence claims:** I grepped `install-hooks.{sh,ps1}` for `gitignore` — **zero hits**, so B-15's no-edit guarantee is true of the code as it stands today and the design only has to preserve it. `.gitignore:58-60` carries the entry with a comment explaining why `*.local` does not match it, so AC-14's "untracked or ignored" clause is satisfiable in the dogfood run.

**Renumbering / weakening check.** FR-1…FR-16 unchanged and unrenumbered. §4 rows B-1…B-14 unchanged, B-15 appended. AC-1…AC-13 unchanged, AC-14 appended. NFR-1, NFR-2, NFR-3, NFR-5 byte-unchanged. **NFR-2 in particular is untouched** — *"not weakened in any code path, in any OS variant, under any boundary condition in §4. Any change that would let a missing guard produce exit 0 is a hard reject"* — and because its scope is "any boundary condition in §4", it now automatically covers B-15 without needing an edit. Clause (c) additionally cites NFR-2 as the reason the residual failure mode is loud rather than silent, which strengthens rather than dilutes it.

Advisory A-6, the one accuracy nit in the amendment: NFR-4's original prohibition on a **persisted guard-override environment variable** now survives only as a parenthetical inside clause (c)'s residual-risk paragraph (*"…no persisted guard-override environment variable (unchanged from the original NFR-4 text)"*), rather than as a standalone binding clause among (a)/(b)/(c). The content is preserved verbatim by the amendment's own account, and the *operative* protection is untouched: design FC-4 mandates `grep -n 'HARNESS_ALLOW_OUTSIDE_RM'` over both installers and both spec files → **zero hits**. So this is a prominence demotion with no development risk. It slightly overstates the amendment's "nothing weakened" claim; it does not warrant a rollback.

Advisory A-5: AC-14's `git status --porcelain` evidence must come from the **dogfood AC-5 run** (§14 order-of-work step 2(g)), *not* from §9's `test_install_bootstrap`, which builds its fixture with a bare `mkdir -p "$tmp/.git"` and explicitly needs no `git` binary — `git status` is not runnable there. The design does not say which run supplies AC-14's evidence because it predates AC-14. This is a capture instruction for QA/delivery, not a design change.

**Conclusion: the analyst's "no new work for the architect" assertion is correct.** No stage-2 gap is owed.

---

## 7. Hazard-defence re-check (`.harness/insight-index.md`, all 30 lines re-read)

| Hazard | Status in round 2 |
|---|---|
| Composed-vs-source body match is composition-integrity, not drift-catching (2026-06-09, line 25) | **PASS** — was FAIL. The rationale is deleted and the insight is now cited *in support of* the honest labelling, in three places. |
| Count-ledger discipline / F.1 arrays hardcoded per shell, stale entry passes silently (2026-06-19 line 32, 2026-06-20 line 35) | **PASS** — was FAIL. Live set closed at five, verified; QA is told to mutate the **artifact** (delete `hook-spec.sh`), not the array. |
| A test that implies coverage it lacks should be marked audit-only, not shipped as an assertion (2026-06-09, line 24) | **PASS** — Group A′ is explicitly demoted to lockstep-only; the cross-shell half is explicitly "green-by-symmetry-only". |
| bash 5.2 `patsub_replacement` eats `&` (2026-06-21, line 37) | **PASS** — FC-2 makes it unreachable (zero substitution over command values) rather than merely handled. |
| PS agent-unexecutable, three failure modes (2026-06-21, line 38) | **PASS** — single-quoted `-f` literals, no double-quote concat, no automatic-variable parameter names (`$forWin`/`$targetOs`), no here-strings; R-1 + §14.4 make `[Parser]::ParseFile` + a Windows driver run binding. |
| PS whole-file write omits the trailing newline (2026-06-08, line 18) | **PASS** — D-2's line-array fix for both bodies, now with `WriteAllText` pinned for both (W-4). |
| Settings-schema traps (2026-05-23, line 10) | **PASS** — root-only doc keys, `.json` suffix, consult-upstream-first, 2-space indent matching J.1's indent-based extractor. |
| Terminal assertion must re-read from disk (2026-06-11, line 29) | **PASS** — §6 step 7 and §8 note 3, naming T-020 CR MAJOR B8. |
| Captured, never hand-derived, tallies (2026-06-04, line 12) | **PASS** — bash count from a captured run; `test_init_ps_assertions` stays **316** with `_qa_note_t13`; `verify_all_checks` stays **32**. I confirmed `baseline.json:10-12` reads `32 / 316 / 278` today. |
| `harness-status` asset rows pinned by `test-supervisor` (2026-06-11, line 30) | **PASS** — decoy 7, no status asset row touched. |
| Prefer single-sourcing over adding a guard check (2026-06-09, line 26) | **PASS** — no new check; 32 held. |

No insight-index entry contradicts any assumption in the revised design. Nothing in the index prohibits `eval` or PS `ScriptBlock::Create`.

---

## 8. Unchanged hard boundaries — re-confirmed

- **Guard stays fail-CLOSED in every path, OS variant and boundary condition.** FC-1 (one origin) / FC-2 (no post-processing) / FC-3 (no exit-0 fallback in the guard branch) / FC-4 (all-four-or-nothing, never a partial file) are intact and each is mechanically checkable. §8's five rows still fail safe: row 1 → exit 3 nothing written; rows 2-3 → exit 0 nothing written; row 5 → exit 4 or 5 with the target **absent** via temp-then-rename. New for round 2: the W-1 capture form is what makes FC-4's "spec exited 0 for each" actually reachable rather than swallowed. I re-read `upgrade-project.sh:106/112` and `.ps1:115/121` and re-confirm no `|| exit 0`, no trailing `exit 0`, no `-EA SilentlyContinue` in either guard branch — so §9 Group B is satisfiable on real output.
- **`verify_all` check count stays 32.** §15, AC-12, ledger C7, G.4 row 11. No check added, removed or narrowed.
- **Out-of-scope untouched.** No hook runtime behavior changes; the four derivation flows are read (§9 uses `upgrade-project`'s helper as an oracle) but **not modified** — T-16 intact; the gate's guard check is not narrowed — T-15 intact; the health report's fixed-file assumption is untouched — T-14 intact; this repo's hooks stay in the machine-local file and the committed `.claude/settings.json` keeps `"hooks": {}`.

---

## 9. High-probability developer questions — pre-answered

1. **"Which `resilient_cmd` do I extract — `upgrade-project` or `migrate-scripts-layout`?"** `upgrade-project`, per §9. Both exist and are byte-identical today (I compared `upgrade-project.sh:102-117` against `migrate-scripts-layout.sh:117-131`), but the design names `upgrade-project` and the anti-vacuity assertion is written against it. Do not extract both; do not "improve" the oracle by comparing the two helpers to each other — that would be a lockstep check, not independent evidence.
2. **"Can I just `source upgrade-project.sh` in the test?"** No, and not merely for style: `upgrade-project.sh:52-55` calls **`exit 1`** when `--template-root` is absent, which would terminate the test driver itself. Use the awk range + `eval`. The awk program in §9 is correct as written — I traced it against the real line numbers (header `:102` matches `^resilient_cmd\(\) \{$`, terminator `:117` matches `^\}$`, and `f{print}` precedes the `exit` so the closing brace is printed).
3. **"How loud must the anti-vacuity failure be?"** It must be a **named assertion that calls the extracted function**, not a check that the extracted text is non-empty. `test-init.sh:5` is `set -uo pipefail` (no `-e`), so a missed extraction leaves `resilient_cmd` undefined and the call returns empty with a `command not found` on stderr — which fails the assertion. Neither driver defines a shadowing `resilient_cmd` / `Get-ResilientCmd` (verified), so a green anti-vacuity assertion can only mean a real extraction.
4. **"How do I get exit 4 out of a `set -e` script?"** Use the mandated form — `if ! cmd="$(bash "$sd/hook-spec.sh" command "$tool" "$os")"; then <diag>; exit 4; fi` — then a **separate** `[ -n "$cmd" ] || { <diag>; exit 4; }`. And capture the tool list into a variable *before* the `for` loop; `for tool in $(hook-spec tools)` inherits the same abort.
5. **"Do I flip the README `test--init-316%2F316` badge?"** **No.** `baseline.json:11` `test_init_ps_assertions` stays 316 in the commit with a `_qa_note_t13`; the badge tracks the PS count, and only the *bash* `test_init_bash_no_python3_assertions` (278 today) moves — from a captured run, never hand-derived. Both `verify__all-32%2F32` and the test-init badge stay untouched in the commit. Only the version badge at `README.md:5` / `README.zh-CN.md:5` moves to `0.45.0`.
6. **"There are two T-13 rows in `docs/tasks.md`."** Yes. `:9` is this task (Active table, the only row you edit). `:48` is the historical `T-13 lang-policy-split` (Delivered v0.24.0) — append-only, never touch. Same trap shape exists for `T-16` vs the historical `T-016 i18n-special-drift-guard` at `:45`.
7. **"Is `.harness/rules/10-self-consistency.md:7` a count site I missed?"** No. Its "7" is the **agent** count, not the mirror set (decoy 11). It is also stale in a second, pre-existing way (v0.30 made agents plugin-native and 8) — leave it; that is not this task's to fix.
8. **"Where does AC-14's `git status --porcelain` evidence come from?"** From the **dogfood AC-5 run** (§14 step 2(g): delete `.claude/settings.local.json`, re-run the installer), not from `test_install_bootstrap` — that fixture only `mkdir`s a fake `.git` and has no `git` binary. `.gitignore:60` carries the entry, so the created file should show as ignored, and no `.gitignore` line should appear in the porcelain output. Capture that output into the delivery evidence.
9. **"How do I write the settings body from PowerShell?"** `[System.IO.File]::WriteAllText` on the temp sibling, then `Move-Item -LiteralPath`. Never `Set-Content` / `Out-File` — BOM and UTF-16LE respectively.
10. **"Will `{{`/`}}` in `hook-spec.ps1`'s format string trip `test-init`'s no-unresolved-placeholder scan?"** No — the ERE requires an identifier between the braces and `&` is not one; `upgrade-project.ps1:117` already ships this exact idiom inside `templates/common/` and passes today.

---

## 10. Advisories carried into development (none blocking, none requiring an upstream edit)

| # | Advisory | Where |
|---|---|---|
| A-1 | The T-16 pointer list cites `test-harness-upgrade.ps1:296` (Windows JSON-escaped) but not `:299` (its unix twin), though the `.sh` side cites both `:296` and `:306`. Add `:299` when writing the spec header comment. | §3.1 header, §13 R-2 |
| A-2 | §9 does not state that the oracle reads `upgrade-project`'s copy only; `migrate-scripts-layout.{sh:117,ps1:36}` holds a second independent copy (byte-identical today, verified) that Group A does not compare against. One sentence makes the residual visible. | §9, §13 R-2 |
| A-3 | The PS anti-vacuity assertion's exact arguments are not spelled out the way the bash one is. Use `Get-ResilientCmd guard-rm $true` → non-empty and contains `guard-rm.ps1`. | §9 |
| A-4 | The cited precedent covers the awk-range extraction, not the `eval`; `eval` of extracted text is new to this repo. Verified safe here (no I.6 ban, no insight prohibition, extracted body touches only its own locals, no shadowing definition). | §9 |
| A-5 | AC-14's `git status --porcelain` evidence must come from the dogfood AC-5 run, not `test_install_bootstrap`. Capture it. | §9, §14 step 2(g) |
| A-6 | NFR-4's "no persisted guard-override environment variable" now survives only as a parenthetical inside clause (c)'s residual-risk paragraph, not as a standalone clause. Content preserved; FC-4 is the operative and unchanged protection. | `01` NFR-4 |
| A-7 | Two frozen items my re-grep found that the decoy list does not name: `docs/v0.11-changes.html:278` ("4 个脚本对", already stale) and `evals/golden-tasks.md:78` (pre-T-007 `.\scripts\sync-self.ps1` path, no count). Neither needs a flip. | §11 decoys |
| A-8 | Carried from round 1, still true: `verify_all.ps1:290-291` hard-parses `.claude/settings.local.json` with `ConvertFrom-Json` while `verify_all.sh:304` only greps — a file byte-valid to bash but malformed JSON passes on bash and FAILs on Windows. Design records it (R-5, §14 item 4); make sure it lands in 07_DELIVERY. | §13 R-5 |

---

## 11. Verdict

Both FAIL-severity findings from round 1 are resolved, and I verified each on evidence I gathered myself rather than on the architect's account:

- **F-1** — I re-grepped independently with a wider net than the architect's and swept all 80 files that mention `sync-self`. The live set is genuinely **closed at five**; there is no sixth site; the two newly-added decoys (`docs/tasks.md`'s T-13 ID collision at `:48`, and `10-self-consistency.md:7`'s numerically-identical "7" about the agent count) are both correctly characterized; and nothing I previously adjudicated as correctly-frozen is scheduled to flip.
- **F-2** — the decisive claim is **true**: `resilient_cmd($1 tool, $2 rc_win)` and `Get-ResilientCmd($tool, $forWin)` take the OS as a parameter and read no host signal, so a single Linux bash run drives all 8 cells against a live, production-consumed, independently-maintained oracle. Sourcing is prohibited for a stronger reason than stated (the bash helper `exit 1`s at load). The extraction precedent exists at `test-verify-i6.sh:332-335` and is applicable. The anti-vacuity assertion is a call-through, not a text-length check, and I closed all three routes by which it could pass vacuously. Group A′ is honestly demoted to lockstep-only, and no composition-integrity check is described anywhere as a drift-catcher.

W-1, W-2, W-3, W-4, W-6 and both Minors are folded into named sections with the load-bearing details intact — W-1 covers every call site including the tool-list loop, W-4 pins `WriteAllText` for the settings body in three separate places, and W-6's new `.ps1` citations all exist at the lines given. Amendment 1 renumbers nothing, weakens nothing binding (NFR-2 is byte-unchanged and its §4 scope now covers B-15 automatically), and its "no new work for the architect" assertion holds: FR-12's added clause ratifies §5.3, B-15 is satisfied by construction because `.gitignore` is not an input to §8's truth table, and AC-14 asserts against output the design already specifies.

The guard stays fail-CLOSED in every path, OS variant and boundary row. The check count stays 32. No out-of-scope boundary is approached. No design decision is left to the Developer.

All eight dimensions PASS. My remaining concerns are eight advisories, every one of them resolvable by the developer following the design as written; none is a design change and none touches a red-line file, permission configuration, or the guard's fail-closed semantics.

### **APPROVED FOR DEVELOPMENT**

Equivalent full-mode routing string for PM: **`APPROVED`** (advisories A-1…A-8 to be carried into `04_DEVELOPMENT.md` as notes, not as gate conditions).

No `BLOCKED: NEEDS-HUMAN` item arises. The only human-reserved item in this task remains the pre-existing, already-scheduled one: NFR-5's binding operator PowerShell run (`[Parser]::ParseFile` on every touched `.ps1`, then `install-hooks.ps1`, `test-init.ps1` and `verify_all.ps1` on Windows, then reconcile `test_init_ps_assertions`), which the design already books as a mandatory 07_DELIVERY item rather than a gate blocker.

---

**Files whose content is load-bearing for this round-2 review** (all absolute):
`/home/alan/Programs/harness-kit/.harness/scripts/upgrade-project.sh` (36-47, 51-81, 102-117, 282, 340 — the OS-parametric oracle and the load-time flow),
`/home/alan/Programs/harness-kit/.harness/scripts/upgrade-project.ps1` (112-126, 128, 286, 338),
`/home/alan/Programs/harness-kit/.harness/scripts/migrate-scripts-layout.sh` (117-131 — the second, uncompared copy),
`/home/alan/Programs/harness-kit/.harness/scripts/test-verify-i6.sh` (332-335 — the extraction precedent),
`/home/alan/Programs/harness-kit/.harness/scripts/test-init.sh` (5, 18 — `set -uo pipefail`, `repo_root`),
`/home/alan/Programs/harness-kit/.harness/scripts/test-harness-upgrade.ps1` (296, 299, 599, 603, 608),
`/home/alan/Programs/harness-kit/.harness/scripts/verify_all.sh` (531-546 I.6 banned list, 732-770 G.4),
`/home/alan/Programs/harness-kit/.harness/scripts/baseline.json` (10-12),
`/home/alan/Programs/harness-kit/docs/dev-map.md` (27, 88-105, 112-114, 142, 163, 164, 176),
`/home/alan/Programs/harness-kit/AI-GUIDE.md` (76),
`/home/alan/Programs/harness-kit/docs/tasks.md` (9, 48),
`/home/alan/Programs/harness-kit/.harness/rules/10-self-consistency.md` (7),
`/home/alan/Programs/harness-kit/.gitignore` (58-60),
`/home/alan/Programs/harness-kit/README.md` (5),
`/home/alan/Programs/harness-kit/.harness/insight-index.md` (all 30 entries).
