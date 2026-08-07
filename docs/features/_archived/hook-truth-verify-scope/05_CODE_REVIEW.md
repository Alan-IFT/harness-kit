# 05 — Code Review — T-15 `hook-truth-verify-scope` (mode `full`)

> **Provenance note (PM):** the code-reviewer agent runs read-only (`Read`/`Glob`/`Grep`, no write
> tool), so it returned this review as its response and the PM persisted it here **verbatim**. The
> PM authored none of the content below.

- Reviewer: stage 5, read-only, independent. Date 2026-08-01.
- Upstream: `01` READY · `02` round 2 READY · `03` round 2 APPROVED FOR DEVELOPMENT · `04` READY FOR REVIEW
- **Tooling limitation declared:** this reviewer has Read/Glob/Grep only — no Bash, no `git`, no `pwsh`. Every finding below is from reading the live tree. Claims that are only checkable by running a command (`git diff`, mtime) are re-derived by other means where possible and marked where not.

## Files reviewed

- `.harness/scripts/verify_all.sh` (`:282-322`, `:640-670`, `:688-745`, `:17-25`)
- `.harness/scripts/verify_all.ps1` (`:19-37`, `:268-311`, `:598-642`)
- `.harness/rules/40-locations.md` (`:25-52`)
- `.harness/rules/75-safety-hook.md` (`:146-155`, `:190-200`)
- `AI-GUIDE.md` (`:38-45`, `:70-79`)
- `CHANGELOG.md` (`:1-100`, plus historical `F.2` rows `:217, 741, 757, 1248, 1282, 1303`)
- `CONTEXT.md` (`:73-96`), `.harness/rejected-decisions.md` (`:101-110`)
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` (whole file)
- `.claude/settings.json`, `.claude/settings.local.json` (read-only, NFR-1 check)
- `.harness/scripts/baseline.json`, `docs/tasks.md`, `docs/batches/default/BATCH_PLAN.md`, `skills/harness-verify/SKILL.md`, `skills/harness-status/SKILL.md`, `.harness/rules/70-doc-size.md`
- Docs: `01`, `02` (both halves), `03` (both rounds), `04`

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[SPEC/DESIGN]** `02_SOLUTION_DESIGN.md:88-89` — the AC-4 inspection recipe ("zero occurrences of `settings.local.json`, `.claude/settings.json`, `ConvertFrom-Json` between the `F.2` header comment and the next check") is unsatisfiable by the design's own prescribed comment, which names both paths, and by the template path `…/.claude/settings.json.tmpl`, which contains `.claude/settings.json` as a prefix. The **criterion** is met (see ruling 3); the **recipe** is defective. → *solution-architect*, doc-only.
- **[SPEC/DESIGN]** `02_SOLUTION_DESIGN.md:65` says the narrowed check asserts "**six facts**" and then tables **seven** (A1–A4, B0, B1, B2). `CHANGELOG.md:83` inherited the miscount ("All six assertions stay at **FAIL** severity"). Behaviourally harmless; it is a live user-facing doc claim. → *solution-architect* for the design text, one-word fix in `CHANGELOG.md` at delivery.
- **[SPEC/COVERAGE]** `.harness/scripts/verify_all.sh:313-314` / `.ps1:301-306` — B1 and B2 assert **presence** independently, never **containment**. A template carrying `{{GUARD_COMMAND}}` inside the `Stop` hook and `"PreToolUse": []` would PASS while the label reads "settings-template guard **wiring** present". This is the same entanglement M3 exposed from the other direction (`settings.json.tmpl:54` sits inside `:48-58`). Widening is explicitly declined scope (OQ-6(b) → T-16), so **do not fix here**; state the residual in `07_DELIVERY.md` so the new label is not over-read. → *solution-architect / T-16 backlog*.
- **[SPEC/DOC]** `04_DEVELOPMENT.md:580-589` — the AC-11 enumeration of surviving `F.2` mentions omits `docs/tasks.md:18`, which carries a **present-tense** statement of the retired behaviour inside T-12's delivered row ("F.2 reads guard evidence from settings.local.json (fallback), J.1 adds it as a target"). I rule it **frozen-historical**, the same class as `CHANGELOG.md:217`, so nothing should be edited — but an unenumerated sibling in exactly the claim class this task is closing should be named. → *developer*, doc-only.
- **[STANDARDS/DOC]** `04_DEVELOPMENT.md:519-522` — "The equivalent measurement that *is* sound is the set difference between the S0 dirty set and the S11 dirty set" overstates. A difference over **filenames** cannot detect a content edit to a file that was already dirty at S0, and most of `02` §9's frozen list was already dirty. What actually carries the freeze claim is the **mtime table** at `:540-546`. The queued Insight bullet at `:736-741` states it correctly ("the sound substitutes are the … difference **and** mtime ordering"); the S11 prose must match, because this insight is headed for `.harness/insight-index.md` as permanent memory. → *developer*, doc-only. See ruling 2.
- **[STANDARDS/PROCESS]** `04_DEVELOPMENT.md:56-87` — the S0 `git status --porcelain`, which `02` §11 S0 demands as "the **full** output, not a summary", was **reformatted into two columns** "for line economy". Every name is preserved (I reconstructed 37 modified + 9 untracked from the pasted list and both counts are exact), and the transformation is disclosed — but it is a reconstruction of the one paste the design singled out for verbatim treatment, and it sits in tension with the same document's justification for its size overage at `:716-722` ("no pasted run was shortened"). Raw would have cost ~37 lines. → *developer*, process note.
- **[STANDARDS/DOC-SIZE]** `04_DEVELOPMENT.md` is ~755 lines against the 500-line per-stage-doc cap in `.harness/rules/70-doc-size.md:30`, whose Rule 1 additionally caps raw evidence at ≤5 lines (`:43-44`). Soft/WARN-level with no `I.*` mechanism over `docs/features/`, and disclosed rather than hidden. The root cause is `02` §11 mandating verbatim full-run pastes (S2 and S8 are 32-line listings each) — the two rules collide and the design granted no allowance. The developer's tie-break (never shorten a tally) is the correct one. → *solution-architect*, for a stated evidence budget or appendix pattern in future designs.

### NIT

- **[DOC]** `04_DEVELOPMENT.md:552-555` — "byte-equal to design §3.1 / §3.2 respectively" is true for bash (`verify_all.sh:290-322` is byte-identical to `02` §3.1) but cannot be literally true for PowerShell: `02` §3.2's fence carries the parenthetical `# (same comment body as the bash twin…)` where the shipped file carries the actual 11-line comment plus the 4-line inner comment. The shipped PS is statement-identical **plus** the comment body §3.2 directed — which is better fidelity, not worse. Reword to "statement-for-statement, comment body expanded as §3.2 directs".
- **[STYLE]** `.harness/scripts/verify_all.sh:313` — `grep -q '{{GUARD_COMMAND}}'` relies on `{` being literal in BRE (GNU-safe; POSIX leaves a bare `{` underspecified). `grep -qF` would be unambiguous and would mirror the PS twin's `[regex]::Escape`. Pre-existing; `02` §7 directed reuse.
- **[STYLE]** `.harness/scripts/verify_all.sh:305,313,314,316` — the accumulator prepends a space, so `F.2`'s FAIL detail prints at 7 leading spaces against the framework's 6 (`step()`, `:22`). Pre-existing and, incidentally, an authenticity marker in the pasted runs.
- **[PROCESS]** `04_DEVELOPMENT.md:195-215, 464-485` — FR-9/AC-10's "confirmed **by execution**" is discharged by the developer applying `skills/harness-status/SKILL.md` §0 **by hand** and transcribing what it would print. There is no executable to run for a prose skill, and OQ-7(b) declined a driver, so this is the only available form. I re-derived both halves independently from the live inputs (`.claude/settings.local.json` hooks keys `Stop/PreToolUse/UserPromptSubmit/SessionStart`; `.claude/settings.json` `"hooks": {}` at `:21`; `.harness/scripts/guard-rm.sh` present) — **both verdicts are correct**. Recorded so QA knows those two blocks are derivations, not captures.
- **[SCOPE]** The mandated full-porcelain paste necessarily names `docs/proposals/frontier-gaps-2026-07.md`, which `01` out-of-scope 7 says must be "not cited". Two instructions collide; the developer correctly prioritized the verbatim-paste rule. **Not** a scope breach — recorded so nobody reads it as one.
- **[DESIGN]** L8's filename (`04_IMPLEMENTATION.md` → `04_DEVELOPMENT.md`) is PM-instructed and is the canonical stage-4 name. No action.

---

## Rulings on the four self-reported discrepancies

### 1. M3's mis-predicted expectation and the substitute anchoring proof — **SOUND, and stronger than the developer claims**

The cause is confirmed against the artifact: `settings.json.tmpl`'s only `{{GUARD_COMMAND}}` is at `:54`, **inside** the `"PreToolUse": [ … ]` array spanning `:48-58`. Deleting the container necessarily deletes the placeholder, so two tokens is the *correct* output and the design's single-token prediction was wrong. The check-level prediction (`FAIL: 1`, `exit=2`) held because `FAIL` counts failing checks.

**The B2 anti-vacuity proof is not substituted at all.** The M3 gate run (`04:339-347`) emitted `…settings.json.tmpl:no_PreToolUse_block` — a token no code path other than the B2 grep at `verify_all.sh:314` can produce — against a genuinely mutated artifact, at `FAIL` severity. Combined with B2 evaluating **true** on the unmutated artifact in every green run, that is the complete two-directional anti-vacuity demonstration AC-5 asks for, and it satisfies the insight-2026-06-20 form exactly: the asserted artifact (the hook block) was made *missing*, and the gate went red.

**Does it prove the *anchoring* is load-bearing?** Yes, and that is what the read-only comparison at `04:356-361` adds. The pre-change assertion was literally a single `grep -q 'PreToolUse' "$tmpl"` (`02` R-1, independently re-derived by the gate at `03:189` against `verify_all.sh:326` / `.ps1:309`). Running that exact pattern on the M3-mutated file **is** running the old predicate — not a reconstruction of a script, and not a hand-assembled artifact. Old → exit 0 (would have PASSed); new → exit 1 (FAILs). The anchor is therefore the sole reason the mutation is detectable, and I independently confirmed the discriminator: `:5` is `"_guard_hook": "PreToolUse hook auto-runs…` (quote-then-**space**, cannot match `"PreToolUse"[[:space:]]*:`) while `:48` is `"PreToolUse": [` (matches).

Two residual notes, neither blocking: (a) a stronger proof was available and unused — the S2 scratch tree contained the pre-change `verify_all.sh`, so retaining a copy and running it against the M3-mutated template would have removed the last inferential step (the byte-form of the old grep); (b) the PS equivalent (`-notmatch "PreToolUse"` → `-notmatch '"PreToolUse"\s*:'`) was not demonstrated at all, which is R-4 green-by-symmetry, already declared.

### 2. "Absent from `git diff --name-only`" substituted by a dirty-set difference — **SOUND ONLY AS A COMBINATION; the difference alone does not protect the frozen list**

Answering the question directly: **no.** A set difference over *filenames* is structurally blind to a content edit inside a file that was already dirty at S0. And the exposure is not hypothetical — of `02` §9's frozen list, these were already `M` at S0: `.harness/rules/75-safety-hook.md`, `.harness/insight-index.md`, `.harness/scripts/baseline.json`, `README.md`, `README.zh-CN.md`, `docs/dev-map.md`, `docs/batches/default/BATCH_PLAN.md`, `evals/guard-rm-cases.md`, both live guard scripts, both `test-guard-rm` drivers, `skills/harness-status/SKILL.md`, both template guard scripts, and two `_archived/resilient-hooks/*` stage docs. For every one of those, the difference would have reported "no new name" whether or not T-15 edited them.

What makes the substitute hold is the **second, independent measurement** the developer bolted on: the per-file **mtime table** (`04:540-546`) ordered against the first T-15 write at `02:29:37`. An mtime *does* move on a content edit to an already-dirty file, so that measurement covers the gap the set difference leaves. The developer did not present the difference alone — but the S11 prose *says* the difference is "the equivalent measurement that *is* sound", which is the overstatement recorded as a MINOR above. The Insight bullet queued for permanent memory states it correctly.

**Residual holes I could identify, both narrow:**
- Files T-15 legitimately edited whose frozen *content* lives inside them — `CHANGELOG.md`'s historical sections and `AI-GUIDE.md:42` — are reachable by neither measurement. **I verified these by direct read instead:** `CHANGELOG.md:8` still reads `## [0.46.0] - 2026-07-31`, T-17's bullets `:10-67` are intact, the new T-15 block sits at `:69-94` immediately before `## [0.45.0]` at `:96` exactly as L5 specifies, and all six historical `F.2` rows (`:217, 741, 757, 1248, 1282, 1303`) still carry their old text. `AI-GUIDE.md:42` still reads `32/32`.
- Two already-dirty archived stage docs (`_archived/resilient-hooks/04_IMPLEMENTATION.md`, `06_QA_REPORT.md`) are in neither the mtime table nor the difference. Spot-check: `_archived/resilient-hooks/05_CODE_REVIEW.md:57,73,105` still cite the pre-change `verify_all.sh:303-321` numbering and `PM_LOG.md:14` still says "F.2 settings.local.json fallback both shells" — i.e. the archived subtree still carries retired claims, consistent with being untouched.

Verdict: the frozen list **is** protected, by the mtime table rather than by the difference. The claim needs the wording fix, not a re-run.

### 3. AC-4's self-inconsistent "zero occurrences" recipe — **CRITERION GENUINELY SATISFIED; the recipe is the defect**

AC-4's text is "*Neither implementation contains any read of a settings file inside the guard check* — verifiable by inspection of the check's body in both shells." The criterion is about **reads**, not string occurrences; the occurrence count was `02` §3's proposed operationalization, not the criterion.

I inspected both bodies independently. Bash `:301-322`: the only file accesses are four `[[ -f "$f" ]]` over guard-script paths, one `[[ -f "$tmpl" ]]`, and two `grep` calls whose sole target is `$tmpl` = `skills/harness-init/templates/common/.claude/settings.json.tmpl`. PowerShell `:288-310`: five `Test-Path` and one `Get-Content $tmpl -Raw`. **No settings file is opened in either shell.** The deleted machinery is gone tree-wide: `f2_hooks_file` and `$hooksFile` return zero hits, and the three retired tokens (`no_PreToolUse`, `no_Bash_matcher`, `no_guard-rm_command`) survive only in prose. FR-3 holds.

The developer's refusal to trim the comment was correct and load-bearing: FR-6 requires the comment to describe what the check asserts, and the comment's entire value is naming the two files it does **not** read. Trimming to make a count look right would have traded a real requirement for a cosmetic one. The measurement substituted (code lines, template path excluded → 0/0/0 both shells) is the right operationalization. → recipe defect routes to *solution-architect*.

### 4. Template mtime moved, content byte-identical — **NOT A DEFECT; the strongest available proof was used**

`skills/harness-init/templates/common/.claude/settings.json.tmpl` is one of the few `02` §9 frozen surfaces that was **clean at S0** (it is absent from the S0 porcelain). For it, and unlike for the rest of the frozen list, `git diff --name-only` **is** a valid content-freeze proof — and it is the proof the developer used, backed by `cmp` after each of M2/M3/M4. mtime movement without content movement is the expected signature of a mutate-and-restore cycle. Reporting it rather than omitting it is the correct behaviour. No action.

---

## Independent verification (things I checked myself, not from `04`)

| Claim | How I checked | Result |
|---|---|---|
| 200-line rule fragment untouched, exactly 200 lines | Read `.harness/rules/75-safety-hook.md:190-200`; no line 201 exists | PASS 200 |
| …and not "improved while in there" | Read `:146-155` — the unbacked `verify_all` claim at `:150-151` is intact | PASS unrepaired, per C-10 |
| No new check; one recorded step; total 32 | `step "F.2"` at `verify_all.sh:319` and `:321`, mutually exclusive `if/else`; exactly one `Step "F.2"` at `.ps1:287`; `baseline.json:10` = 32; `G.4`'s `${#report[@]} + 1` at `:705` and its last-check tripwire untouched | PASS |
| Every retained assertion at FAIL, nothing softened to WARN | bash emits `step … "FAIL" "$f2_problems"`; PS `throw` → `Step`'s `catch` → FAIL (`.ps1:31-36`). No WARN or INFO path exists in either block | PASS |
| PS body complete, symmetric, and clear of all five hazards | Read `.ps1:287-311` statement by statement: `${tmpl}` braces at both colon-adjacent sites; `throw ($problems -join ' ')` parenthesized, no `+`; `Get-Content … -Raw` present; no automatic-variable collision (`$problems`/`$tmpl`/`$tmplText`/`$f`); **every statement is an assignment, an `if`/`foreach` whose body is an assignment, or the `throw`** — no bare `Test-Path`, no `$problems + …`, no `Write-Output`, no unassigned `Get-Content`, so `$r` is `$null` and `$null -eq $false` is `False` ⇒ PASS | PASS (green-by-symmetry; not executed) |
| Hazard 5 not downgraded by R2-2 | The shipped block clears the **rule** (bans all emission), not merely the wrong example. The real vector named in R2-2 — a bare `Test-Path` line — is absent | PASS |
| Neither guard script modified; machine-local settings untouched | All four asserted paths present via Glob; `.claude/settings.local.json:16-25` still wires `PreToolUse`/matcher `Bash` → `bash .harness/scripts/guard-rm.sh` with **no `|| exit 0`** (fail-closed intact); `.claude/settings.json:21` still `"hooks": {}` | PASS NFR-1 intact (content read; mtime not checkable by me) |
| Both live doc lines corrected | `40-locations.md:42` matches L3's prescribed wording byte-for-byte; `AI-GUIDE.md:74` carries `F.2 guard-rm scripts + settings-template wiring` | PASS |
| `G.4` literals on edited lines survived | `AI-GUIDE.md:74` still contains `32 checks`; `40-locations.md:29` still `(32 checks,`; `AI-GUIDE.md:42` still `32/32` | PASS |
| The stale line above the edit target was left alone | `40-locations.md:41` still names 5 of the 11 `F.1` pairs (`verify_all.sh:284` lists 11) — unchanged | PASS R2-4 honoured |
| `g4_files` really has eleven entries, `CONTRIBUTING.md` absent | Read `verify_all.sh:720-732` | PASS (`04:605` cites `:720-731`; the array literal is `:720-732`, entries on `:721-731` — citation is one line short, immaterial) |
| L6/L7 appends match the design | `CONTEXT.md:84-88` byte-matches `02` §8.1 and sits between **Machine-local settings** and **Effective hook source** as specified; `.harness/rejected-decisions.md:101-110` byte-matches §8.2 | PASS |
| Baselines unmoved | `baseline.json:10` = 32, `:23` = 87 | PASS |
| No mutation residue | Glob `**/*t15*` → **no files** (no `.t15bak`, no `.t15-clean`) | PASS |
| No driver or doc pins the old label | Tree-wide grep for `PreToolUse wiring`: only archived stage docs and this task's own `02`/`04` | PASS OQ-3(b) safe |
| **The clean-checkout goal is closed in *both* shells, not just bash** | `F.2` was not the only consumer of a machine-local file. I checked the other one: `J.1` skips a missing target in **both** twins — `verify_all.sh:648` `[[ -f "$jt" ]] || continue` and `.ps1:614` `if (-not (Test-Path -LiteralPath $t.path)) { continue }` | PASS no residual clean-checkout FAIL on either shell |
| No tally in `04` re-derived arithmetically | See below | PASS |

**Tally cross-check (per your instruction).** Every number in `04` reconciles with the artifact pasted beside it, and several reconcile with the *script* in ways a fabricated paste would not:

- S0's "37 modified + 9 untracked" — I counted the pasted two-column list: exactly **37** and **9**.
- The S0 list contains all of L1–L6 (`verify_all.{sh,ps1}`, `40-locations.md`, `AI-GUIDE.md`, `CHANGELOG.md`, `CONTEXT.md`) and does **not** contain `.harness/rejected-decisions.md` — which is precisely what makes the S11 claim "T-15 newly dirtied exactly one path, L7" internally consistent.
- Every summary sums to 32: S2 31+0+1, S6 32+0+0, M1 30+0+2, M2/M3/M4 31+0+1, S8 32+0+0.
- The S2 and S8 listings each contain exactly 32 `[id]` lines.
- The pasted runs reproduce the script's **actual, non-obvious call order** — `G.3` before `I.1`, `I.7` before `I.6` (`verify_all.sh:494` vs `:623`), `J.1` before `G.4`, `H.1` between `G.1` and `G.2`. A reconstructed run would almost certainly have sorted these.
- The pasted `F.2` detail lines are indented **7** spaces while `E.1`'s is **6** — the exact signature of `step()`'s `echo "      $detail"` (`:22`) plus the accumulator's leading space (`:305`).
- S2's `F.2` line prints the **old** label; S6/S7/S8's print the **new** one.

No fabricated or re-derived tally found.

**Delivery prose check.** No surface describes this as reducing guard coverage. `CHANGELOG.md:90-93` states the opposite explicitly ("Behavioural guard coverage is unchanged… still **87 rows**, unmoved… the machine dimension did not disappear"), and the in-code comment at `verify_all.sh:298-300` / `.ps1:284-286` says the same. AC-12's remaining half is a stage-7 obligation.

## Requirement coverage check

| Criterion | Implementation / evidence | Status |
|---|---|---|
| FR-1 four guard scripts | `verify_all.sh:302-306`, `.ps1:289-293` | PASS |
| FR-2 template placeholder + hook block | `verify_all.sh:311-317`, `.ps1:298-309` | PASS |
| FR-3 no settings read | verified by inspection, both shells (ruling 3) | PASS |
| FR-4 all assertions FAIL | `sh:321`; PS `throw` → `Step` catch `.ps1:31-36` | PASS |
| FR-5 one recorded step | 2 bash sites in one `if/else`; 1 PS site | PASS |
| FR-6 label + comment honest | new label both shells; comment `sh:290-300` / `.ps1:276-286` | PASS |
| FR-7 shell symmetry | same facts, order, token strings; §3.3's S-1/S-2 deviations unchanged | PASS |
| FR-8 live docs corrected, history frozen | L3, L4 corrected; historical rows intact | PASS (see MINOR on `docs/tasks.md:18`) |
| FR-9 machine dimension by execution | `04` S3 + S9; I re-derived both from live inputs | PASS (hand-applied skill — NIT) |
| AC-1 32/0/0 exit 0 | `04:253-262` | PASS |
| AC-2 clean state green | `04:396-436`, full 32-line run, `F.2 … PASS` | PASS |
| AC-3 pre-change FAIL on same state | `04:147-189`, `exit=2`, three-token detail | PASS |
| AC-4 no settings read | ruling 3 | PASS |
| AC-5 anti-vacuity by artifact mutation | M1 (loop), M2 (B1), M3 (B2), M4 (B0); ruling 1 | PASS |
| AC-6 FAIL not WARN | `WARN: 0` in all four mutation summaries; no WARN path in code | PASS |
| AC-7 count 32, no stamp moved | `baseline.json:10`; `plugin.json`/`marketplace.json` both `0.46.0`; `G.3`+`G.4` PASS | PASS |
| AC-8 test-guard-rm 87/0 | `04:489-496`; `baseline.json:23` = 87 | PASS |
| AC-9 PS green-by-symmetry + operator item 11 | `04:615-643`; T-13's 8 and T-17's 10 declared untouched | PASS |
| AC-10 health report both states | `04` S3 + S9, re-derived by me | PASS |
| AC-11 live doc surface consistent | L3 + L4; frozen rows unedited | PASS (MINOR: enumeration incomplete) |
| AC-12 delivery states coverage unchanged | `CHANGELOG.md:90-93` PASS; `07_DELIVERY.md` pending | PENDING stage 7 |
| B-1…B-12 | B-1/B-2 by construction; B-3 demonstrated `04:443-459`; B-4 trivially (no read) — not exercised, no AC requires it; B-5 M1; B-6 M4; B-7 M2; B-8 M3; B-9 M3's two-token message (bash); B-10/B-11 honoured; B-12 32/0/0 | PASS |
| NFR-1 / NFR-2 / NFR-3 / NFR-4 | guard scripts + settings + `.gitignore` untouched; 200/200 verified by me; tallies reconcile; user projects run a different gate | PASS |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3 assertion set A1–A4, B0, B1, B2 with exact token vocabulary | `verify_all.sh:301-317`, `.ps1:288-309` | PASS |
| §3.1 bash body | `verify_all.sh:290-322` — byte-identical | PASS |
| §3.2 PS body + five hazards | `.ps1:276-311` — statement-identical, comment body expanded as directed | PASS (NIT on the "byte-equal" wording) |
| §3.3 symmetry, S-1/S-2 only | same tokens, same order, same join | PASS |
| B2 anchored to the JSON key form (C-9, no fallback) | `'"PreToolUse"[[:space:]]*:'` / `'"PreToolUse"\s*:'` | PASS |
| PS accumulate-then-throw per `E.4b` idiom (D-2) | `$problems = @()` … `throw ($problems -join ' ')` | PASS |
| L3 / L4 exact wording | matches | PASS |
| L5 CHANGELOG placement | end of `[0.46.0]`, immediately before `[0.45.0]`; heading date unmoved; T-17 bullets intact | PASS |
| L6 / L7 exact appends + position | matches §8.1 / §8.2 | PASS |
| §9 frozen list | no flip found; see ruling 2 for method limits | PASS |
| §10.1 operator item 11 | reproduced verbatim in `04:625-639` | PASS |
| §11 S0–S12 + QA (i)(ii)(iii) | all executed; three substitutions disclosed and ruled on above | PASS |
| §11.1 forbidden mutation targets | A1/A2 never mutated; all four guard paths present; live hook armed | PASS |
| Hard rules 1–5 | no `settings.local.json` touch, no live-guard touch, no `HARNESS_ALLOW_OUTSIDE_RM`, no write-mode `sync-self`, no edited expectation | PASS |
| No new check / no new file under `.harness/scripts/` / no new dependency | confirmed; the block now has **no** JSON-parser dependency at all (a small improvement) | PASS |
| §3 "six facts" vs seven tabled rows | design-internal miscount, inherited by `CHANGELOG.md:83` | **MINOR** (drift in the doc, not the code) |
| AC-4 verification recipe (§3 `:88-89`) | unsatisfiable as written | **MINOR** (recipe defect) |

## Axis status

- **Standards-conformance:** 3 findings + 3 NITs, **worst = MINOR**. The shipped code is correct in both languages: quoting is safe, the anchor is correct and discriminating, the two shells are symmetric in facts, order and token strings, no surrounding check regressed, and the PS twin is a complete body that clears all five named hazards on independent audit. The MINORs are all in the development *record* (a reformatted mandated paste, an overstated freeze claim, the 500-line doc cap), not in the change.
- **Spec/design-fidelity:** 4 findings + 3 NITs, **worst = MINOR**. Every FR (1–9), boundary condition (B-1…B-12) and acceptance criterion (AC-1…AC-11) is implemented and evidenced; AC-12's second half is a stage-7 obligation. No silent drift: the two design-text defects (the "six facts" miscount and the unsatisfiable AC-4 recipe) were surfaced by the developer rather than papered over, and the one coverage residual (B1/B2 assert presence, not containment) is explicitly declined scope routed to T-16.

Neither axis carries an unaddressed CRITICAL or MAJOR, so the aggregate is MINOR.

## Verdict

**APPROVED** (0 CRITICAL, 0 MAJOR, 7 MINOR, 6 NIT)

All four self-reported discrepancies resolve **soundly**, not merely honestly:

1. the anchoring proof is direct (the real gate run emitted `no_PreToolUse_block` against a real mutated artifact) and the read-only comparison is a faithful re-execution of the old predicate, not a reconstruction;
2. the freeze substitute holds — but on the **mtime table**, not on the set difference, which alone cannot see an edit to an already-dirty file; the S11 wording must be corrected before that claim reaches permanent memory;
3. AC-4 is genuinely satisfied and the design's recipe, not the implementation, is the defect — the refusal to trim the comment was the right call;
4. the moved mtime is a non-defect proved by the strongest evidence actually available for that file.

None of the MINORs blocks merge. Recommended routing before delivery: **developer** — the three doc-record corrections (S11 freeze wording, AC-11 enumeration to name `docs/tasks.md:18` as frozen, the "byte-equal §3.2" rewording); **solution-architect** — the "six facts"/seven-rows miscount (plus the one-word `CHANGELOG.md:83` fix), the AC-4 recipe defect, the stage-doc evidence-budget collision, and the B1/B2 containment residual as a T-16 note. `07_DELIVERY.md` still owes AC-12's second half and should state the containment residual so the new label is not over-read.
