# 03 — Gate Review — T-15 `hook-truth-verify-scope` (mode `full`)

> **Provenance note (PM):** the gate-reviewer agent runs read-only (`Read`/`Glob`/`Grep`, no
> write tool), so it returned this review as its response and the PM persisted it here
> **verbatim**. The PM authored none of the content below; the review is the gate reviewer's.

Upstream verdicts confirmed READY (01, assessment PROCEED) and READY (02). Every design claim referencing existing code was checked by reading the code; the change ledger and frozen list were re-derived by independent search, not inherited.

## 0. Ruling on R-1 / D-1

**Verified independently. The architect's factual claim is TRUE. The anchoring is CORRECT and IN SCOPE. The design's own fallback ("ship B2 unanchored, record B-8 as knowingly vacuous") is REJECTED.**

| Evidence read | Finding |
|---|---|
| `skills/harness-init/templates/common/.claude/settings.json.tmpl:5` — `"_guard_hook": "PreToolUse hook auto-runs guard-rm …"` | carries the bare token `PreToolUse` in a root-level doc string |
| same file `:48-58` — `"PreToolUse": [ { "matcher": "Bash", … "{{GUARD_COMMAND}}" } ]` | the only `"PreToolUse"` **key** in the file |
| `verify_all.sh:326` — `grep -q 'PreToolUse' "$tmpl"` | unanchored, whole-file |
| `verify_all.ps1:309` — `if ($tmpl -notmatch "PreToolUse")` | unanchored, whole-file, additionally case-insensitive |

Deleting the entire `"PreToolUse": [ … ]` array leaves line 5 intact and **both** shells still match. **B-8 is false today in both shells.** I also checked the proposed anchor both ways: `"PreToolUse"` + optional whitespace + `:` does **not** match line 5 (its quote is followed by `PreToolUse `, never a closing quote) and **does** match line 48. The mitigation works.

Why it is in scope, not OQ-6(a) creep:

1. OQ-6(a) was about comparing the template's guard command byte-form against `hook-spec`. Anchoring compares the template against *nothing external* — no second artifact, no new assertion; only the pattern tightens.
2. B-8 is a binding boundary condition in a document already READY. Shipping a check that provably cannot satisfy it is shipping a known-false requirement.
3. **Stronger than the architect's own argument:** after the narrowing, B2 is the check's *only* remaining wiring assertion. Left unanchored, the new label — "settings-template guard **wiring** present" — is live-false at birth because the check cannot detect the wiring's absence. That is a direct **FR-6** violation, i.e. the exact defect class T-15 exists to close. The fallback trades one false coverage claim for another.
4. Insight 2026-06-20 requires proving such a gate by mutating the artifact. Unanchored, M3 is un-runnable and AC-5 cannot be discharged for B2 at all.

## 1. Eight-dimension audit

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | Every FR is a testable proposition over tracked files; B-1…B-12 enumerate the input space *including the two dangerous inputs*; AC-3 is what makes AC-2 a measurement; B-12 correctly encodes WARN-as-failure. |
| 2 | Design completeness | **PASS** | Every FR/boundary/AC maps to a concrete edit (§8 L1–L8) or step (§11 S0–S12); §3 enumerates A1–A4, B0, B1, B2 exhaustively with exact tokens and evaluation order, both shells verbatim. |
| 3 | Reuse correctness | **PASS** | Every reuse claim resolves: `step()` `verify_all.sh:17-25`; `Step` `verify_all.ps1:19-37`; the accumulate-then-throw block at `verify_all.ps1:248-255` is genuinely inside `Step "E.4b"` (header `:224`); F.2 loop `:292-296`/`:278-282`; template block `:322-329`/`:306-309`; sync-self's 8 pairs (`AI-GUIDE.md:76`, `dev-map.md:181`) with `verify_all` correctly **absent**. No claimed symbol missing. |
| 4 | Risk coverage | **WARN** | R-1/R-5/R-7 unusually well-found and R-3 discharges, but three real risks are absent: F-1, F-2 (safety-critical), F-4. |
| 5 | Migration safety | **PASS** | No schema/migration/flag; `baseline.json` read-only at 32/87; every state change reversible — three mutations with named restores and mandatory re-run-green between, one scratch tree with guard-legal teardown and no override. |
| 6 | Boundary handling | **WARN** | B-1…B-5, B-7, B-9 designed for; B-9 now correct in **both** shells (D-2 fixes a real defect — today `verify_all.ps1:281` throws on the first missing script). B-8 holds *only because of* the anchoring. B-6/B0 has no falsification step (F-3). |
| 7 | Test feasibility | **WARN** | AC-1/4/5/6/7/8/11/12 directly verifiable; AC-9/AC-10 reach the honest ceiling and say so. AC-2/AC-3's load-bearing observation is measurable, but their stated whole-gate summaries are predictions over an uncharacterised index (F-7). |
| 8 | Out-of-scope clarity | **PASS** | §12 restates all eight exclusions; "no compensating check" stated three times; `frontier-gaps-2026-07.md` named as not-read/not-cited. The one live over-build risk (anchoring) is adjudicated explicitly rather than left implicit. |

**No dimension is FAIL.**

## 2. Findings

**F-1 — `E.1` co-fires on mutation M1; the stated expected output is unmeetable. MAJOR → solution-architect (§11 S7 M1).**
`templates/common/.harness/scripts/guard-rm.{ps1,sh}` is **Mapping 5** in `sync-self.sh:74-76`. `sync_file` (`:22-33`) records drift whenever `cmp -s "$src" "$dst"` fails — including when the **source** is renamed away — and `--check` exits 1 on any drift (`:95-103`), which `verify_all.sh:194-198` renders as `[E.1] … FAIL`. M1 therefore yields **`FAIL: 2`** (`E.1` + `F.2`), not the design's `FAIL: 1`. Same for A3; **no** mutation of A1–A4 avoids it, since all four paths are mirrored. AC-5's validity is untouched (F.2 still turns red on its own token), but a developer trusting the recorded expectation may "repair" E.1 by running `sync-self.sh` without `--check` while the source is missing — touching the live guard path.

**F-2 — the plan never forbids mutating A1/A2, and A2 is the live fail-closed guard. CRITICAL → solution-architect (§11 S7).**
`.claude/settings.local.json:22` wires `PreToolUse` → `sh -c '… bash .harness/scripts/guard-rm.sh'`, and `:4` states it is **fail-CLOSED** ("no exit-0 fallback, so a missing guard blocks the Bash tool call"); `.harness/rules/75-safety-hook.md:176` says the same. Renaming or deleting `.harness/scripts/guard-rm.sh` (assertion **A2**) **seizes the whole Bash toolchain**, and recovery is Read+Write only because `mv`/`git checkout` are themselves Bash calls (insight 2026-08-01). §11 S7 happens to pick a safe target (A4) but never states A1/A2 are **forbidden** targets. §9's freeze and NFR-1 both read as *delivery* constraints, not as do-not-touch-even-temporarily-during-anti-vacuity-testing. This matters precisely because the "audit every sibling" discipline in force here pushes a conscientious developer to generalise M1 to all four.

**F-3 — assertion B0 has no falsification step; it is the only untested branch. MAJOR → solution-architect (§11 S7).**
The `else` arm emitting `missing:$tmpl` is the sole branch of the new bash block (and its PS twin) that no step exercises — closing the single finding rather than the class. It is also the cheapest and is co-failure-free: the tmpl is not in sync-self's 8 pairs (E.1 unaffected), `J.1` guards with `[[ -f ]] || continue` (`verify_all.sh:660`), and `D.2` enumerates by `find … -name '*.tmpl'` (`:88`) so a renamed file drops out of the scan set. Temporarily renaming it yields exactly one FAIL.

**F-4 — an unlisted PowerShell hazard can render F.2 as WARN, a hard gate failure. MAJOR → solution-architect (§3.2).**
`verify_all.ps1:19-37`'s `Step` decides WARN by `if ($r -eq $false)` where `$r = & $action` is the scriptblock's **pipeline output**. Any statement emitting to the pipeline (a bare `Test-Path $f` line; `$problems + …` where `+=` was meant) makes `$r` an array, `$r -eq $false` a *filtering* operator returning a non-empty array, and `if` reads that as truthy → **WARN** → exit 1 (`verify_all.sh:823-825`), violating FR-4/AC-6. Same "operator silently changes meaning on an array" family as the design's own hazard 3, and absent from its four-hazard checklist. The code as written is clean (`$r` is `$null`; `$null -eq $false` is `False`), but the list is what the developer will use.
The rest of the PS restructure is **sound** against all three shipped instances: `${tmpl}` braces defeat the drive-qualified-variable silent-wrong-string; `throw ($problems -join ' ')` is parenthesized so `-join`'s below-`+` precedence cannot re-associate; `-Raw` present; no collision with a read-only automatic (`$problems`/`$tmpl`/`$tmplText`/`$f`). **The hand-off is complete in both shells** — full bodies, identical token vocabulary, identical order — which is the property whose absence manufactured the `-join` instance.

**F-5 — §3.3's symmetry claim is absolute but the code is not. MINOR → solution-architect (§3.3).**
PS `-notmatch` is case-**insensitive** (`"pretooluse":` PASSes PS, FAILs bash); .NET `\s*` matches `\n` while `grep` is line-scoped (`"PreToolUse"\n  :` PASSes PS, FAILs bash). Pathological, partly pre-existing on the `{{GUARD_COMMAND}}` assertion — but "Any input that FAILs one shell FAILs the other" is stated absolutely.

**F-6 — one frozen row's protection basis is mis-stated. MINOR → solution-architect (§9).**
§9 lists `CONTRIBUTING.md:22` among "G.4 count rows". It is not one: `g4_files` (`verify_all.sh:732-744`) has exactly eleven entries — `AI-GUIDE.md`×2, `docs/dev-map.md`×2, `.harness/rules/40-locations.md`, `README.md`×2, `README.zh-CN.md`×2, `docs/manual-e2e-test.md`, `baseline.json`. `CONTRIBUTING.md:22` is **review-protected, not gate-protected**. The freeze verdict is right; the reason is wrong — and §11's QA addition (i) publishes exactly that distinction as "the honest claim", so a wrong basis propagates into delivery.

**F-7 — scratch-tree summaries are asserted, not derived, over an uncharacterised index. MAJOR → solution-architect (§11 S0/S1/S2/S8).**
(a) `git worktree add --detach .t15-clean HEAD` gives the scratch tree **HEAD's index**, and the rsync overlay changes disk without touching it — so every git-driven check inside it (`A.1`, `A.2`, `E.7`, `I.6` at `:633`) enumerates HEAD's file list. I found nothing that turns red from this, but §11 S1's "the **exact** clean-checkout condition" is overstated: it is *the current working tree minus `.claude/settings.local.json`, over a stale index*. For F.2 specifically the construction is sufficient, so AC-2/AC-3 remain genuine measurements.
(b) The environment's git snapshot reports `HEAD = cb0ed57 (v0.44.0)` with a **clean** status, while `plugin.json:4` says `0.46.0` and `CHANGELOG.md:8` carries `## [0.46.0]`. Those cannot both be true. R-7 anticipates a gap and mitigates with the overlay — the right shape — but S0 never *measures* it.
Net: the ACs survive; the summary predictions attached to them do not.

**F-8 — `.harness/insight-index.md` is at exactly 30/30, a second razor edge. MINOR → PM (stage 7 / archive).**
`I.4` (`verify_all.sh:426-436`) WARNs above 30 `^[[:space:]]*-[[:space:]]` lines; the file has **exactly 30** (lines 9–38). A WARN exits 1 — the same trap as the 200/200 rule cap. §9 says T-15 appends only at archive time without noting the file is at cap. `archive-task` normally rotates, so this is stage-7's hazard, but neither document says so.

**F-9 — a pre-existing unbacked claim inside the 200/200 file. INFO, deliberately no action.**
`.harness/rules/75-safety-hook.md:150-151` claims verify_all would catch any tracked file hard-coding `HARNESS_ALLOW_OUTSIDE_RM=1`. No check does this (`A.1` greps secret-shaped assignments; `F.2` never did; `I.6`'s banned list lacks it). Recorded **so nobody fixes it while they're in there** — the file is at exactly 200/200 and one added line is a WARN → exit 1. Backlog, not this task.

## 3. Verified PASS statements

**The name-collision decoy is real and worse than described.** All three overlays' `F.2` is `Rule fragments <=200 lines each` (`generic/…verify_all.sh.tmpl:172,179`; `backend/…:283,290`; `fullstack/…:268,275`; `.ps1.tmpl` twins `:194`, `:252`, `:232`) — different check, different subject, **and different severity (`WARN`, not `FAIL`)**. Confirmed by count: `guard-rm|PreToolUse` returns **96 hits across 18 files, all under `templates/common/`** — zero in generic/backend/fullstack; `templates/common/.harness/scripts/` holds 21 files and ships no `verify_all`.

**The change ledger is complete.** Independent sweeps: `F.2` tree-wide excluding `_archived`; the old label string (**6** files — the 2 live scripts + 4 archived stage docs, matching the design); `settings.json|PreToolUse|guard-rm` across all of `.harness/rules/`; `F.2|guard.*wiring|verify_all.*guard` across `skills/**/SKILL.md`. **The only live doc lines stating this check's coverage are `.harness/rules/40-locations.md:42` (L3) and `AI-GUIDE.md:74` (L4).** No missed live surface. `80-settings-schema.md` describes `J.1` and is correctly absent.

**G.4 rows correctly classified frozen vs live.** The subtle case is `AI-GUIDE.md`, which carries **two** G.4 rows — `32/32` at `:42` (frozen) and `32 checks` at `:74` (the edited line). Splitting them and requiring a re-read is exactly right: both are whole-file `[[ == *…* ]]` tests, so L4 is safe iff the literal survives. `40-locations.md` likewise splits `:29` (frozen) from `:42` (L3). `MIGRATION.md:231`'s "29 checks" is correctly the decoy — not in `g4_files`; editing it would be the bug.

**Count and severity invariants hold.** I counted **32 distinct ids** in `verify_all.sh`. G.4's `${#report[@]} + 1` (`:717`), its eleven rows, and the last-check tripwire (`:806-815`) behave as described. Two mutually exclusive `step "F.2"` sites = one record. No new check. `baseline.json` read-only at 32 / 87.

**NFR-2 discharged.** `75-safety-hook.md` is **200 lines**; I read every `verify_all`/`F.2`/`settings.json` mention (`:5, 32, 150-151, 155, 158, 195`) — **none is a claim about F.2's coverage**. Its "Fully disable" section (`:153-170`) documents the durable opt-out that makes the presence-conditional form unsound (RA E-3) and stays true. Separately `AI-GUIDE.md` is **113 lines**, far under I.1's cap, so L4 is size-safe.

**Mutations produce no unexpected co-failures beyond F-1's.** `D.2` (`:79-89`) rejects only **unknown** `{{…}}` placeholders — it does not require presence — so M2 is D.2-clean. `J.1`'s event list (`:652`) still covers the remaining `Stop`/`UserPromptSubmit`/`SessionStart`, so M3 is J.1-clean. `I.6` cannot be tripped by the comment rewrite: `verify_all.{sh,ps1}` are in `i6_exempt_files` (`:562-563`), `docs/features/` is an exempt dir (`:568`), and a tracked-but-missing path is skipped cleanly (`:589`). `test-init`'s PreToolUse assertions (`test-init.sh:301-334`, `test-init.ps1:349-353`) run against a **rendered fixture**, so no `test_init_*` baseline moves — though they would break while M2/M3 are active, which §11's "run no other driver while mutated" already forbids.

**The procedure is guard-legal against the T-17 guard as it exists today.** Read from the current `guard-rm.sh`: nine destructive verbs `rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm` (`:135`, `:153-166`) plus `find -delete` (`:869-886`); carriers `xargs env nohup nice time timeout command exec find` (`:144-149`). **`rsync`, `tar`, `git`, `mv` are neither**, so `git worktree add/remove --force/prune`, `rsync -a --delete` and the `tar | tar` fallback are never judged. Scratch tree stays inside the root, no override needed, and §11 forbids `HARNESS_ALLOW_OUTSIDE_RM=1` outright. **R-5's central claim holds.**

**R-6 holds.** A linked worktree's contents are untracked in the parent, so `.t15-clean` is absent from `git ls-files` and invisible to `I.6`. Every other enumerator is path-scoped to a root that cannot reach it: `find skills` (`:68`), `find skills/harness-init/templates` (`:88`), `find agents` (`:418`), `find docs/features` (`:503`), `find .harness/rules -maxdepth 1` (`:404`, `:109`).

**Health-report steps correctly derived** from `skills/harness-status/SKILL.md:24-68`: scratch → C1 `absent`, C2 `empty` (`.claude/settings.json:21` is `"hooks": {}`) ⇒ `SOURCE = none`, `MACHINE_STATE = never-installed`; live → C1 `present` (4 hook keys), C2 `empty` ⇒ `SOURCE_KIND = machine-local`, `MACHINE_STATE = installed`, `OTHER_DECLARES = false`. Both match §0.5's line forms.

**Append targets byte-accurate.** `CONTEXT.md` **Machine-local settings** `:79`, **Effective hook source** `:84`. `rejected-decisions.md` record shape `## <key>` / Decision / Why / Origin matches §8.2 exactly. `CHANGELOG.md` `## [0.46.0]` `:8`, `## [0.45.0]` `:69`; `plugin.json:4` = `0.46.0`, so G.4's CHANGELOG-heading assert stays green with no stamp movement.

**No design prose describes this as reducing guard coverage.** §1, R-8 and §12 all state the correct thing and AC-12 binds the delivery to repeat it. **Nothing to correct.**

**An under-sold side-benefit:** `baseline.json:_qa_note_t13` records a standing operator hazard — *"verify_all.ps1 hard-parses settings.local.json with ConvertFrom-Json while the bash twin only greps"*. The narrowing removes `ConvertFrom-Json` from F.2 entirely and retires that asymmetry. That note lives on a frozen surface, so out-of-scope 6 correctly leaves it — recorded so delivery does not claim it was reconciled.

## 4. Predicted developer questions (pre-answered)

1. **"M1 turned E.1 red too — did I break the sync?"** No. Mapping 5; expect `FAIL: 2` / `exit=2` and paste it. **Do not** run `sync-self.sh` without `--check` while the source is renamed. (F-1)
2. **"Should I mutate all four guard-script assertions?"** **No — A1/A2 are forbidden.** A2 is the live fail-closed hook; removing it blocks every later Bash call and recovery is Read+Write only. A1–A4 share one loop body, so one mutation proves the mechanism. (F-2)
3. **"How do I 'execute' the health report when §0 is prose?"** Read C1/C2, apply Step 0.1's four-state table to each independently, then 0.2 → 0.4, then print the one §0.5 line. That *is* the execution — which is why OQ-7(b) declined a driver. Expected values in §3; paste, don't paraphrase.
4. **"The scratch tree shows a red check that isn't F.2 — fix it?"** No. Paste what ran and report the discrepancy. The load-bearing observation is F.2's own verdict; never adjust a recorded expectation to match, never re-derive a tally arithmetically. (F-7)
5. **"`grep -c 'step \"F.2\"'` returns 2 — is that R-2's drift?"** No. Two sites in mutually exclusive branches record one step. G.4 measures `${#report[@]}`, cross-checked by the tripwire (`:806-815`); confirm the summary prints `PASS: 32`.
6. **"Do I need `sync-self` after editing `verify_all.sh`?"** No — not one of the 8 mirrored pairs (`AI-GUIDE.md:76`), and `.harness/rules/` is never synced.

## 5. Conditions (binding)

1. **C-1 (safety, F-2).** `.harness/scripts/guard-rm.{ps1,sh}` must not be renamed/moved/emptied/deleted **at any point**, including temporarily for anti-vacuity testing. Record beside the existing `.claude/settings.local.json` prohibition.
2. **C-2 (F-1).** Record M1's true expected output as two FAILs (`E.1` + `F.2`, `FAIL: 2`, `exit=2`) and why. Never run `sync-self.sh` without `--check` while a mirrored source is renamed.
3. **C-3 (F-3).** Add a fourth mutation falsifying **B0** (temporarily rename `settings.json.tmpl`), expecting exactly one FAIL with `missing:<tmpl>`; verified co-failure-free against E.1/J.1/D.2. Restore, re-run green.
4. **C-4 (F-4).** Confirm no statement in the new PS `F.2` block emits to the pipeline, else `Step`'s `$r -eq $false` array-filters into a spurious WARN → exit 1. Add as a fifth named hazard in §10.1's operator item.
5. **C-5 (F-7).** At S0 capture `git rev-parse HEAD` with `git status --porcelain`; state what the scratch tree actually is; paste scratch runs verbatim; report any non-F.2 red as a procedure artifact rather than editing the expectation.
6. **C-6 (F-6).** Correct `CONTRIBUTING.md:22`'s basis in the delivery — review-protected, not gate-protected. The file itself stays untouched.
7. **C-7 (F-5).** Narrow §3.3's symmetry sentence or record the two accepted deviations.
8. **C-8 (F-8).** Flag to PM that `.harness/insight-index.md` is at exactly 30/30, so the stage-7 harvest must rotate, not merely append.
9. **C-9.** Implement the **anchored** B2 per §0. The unanchored fallback is not available.
10. **C-10.** `.harness/rules/75-safety-hook.md` untouched — `wc -l` = 200 before and after, absent from `git diff --name-only`. Do **not** repair F-9's unrelated stale claim there.

## 6. Verdict

The design's core is correct and independently verified: the assertion set is complete and non-vacuous once anchored; the change ledger is complete with no missed live surface; the frozen/decoy list is right (including the three-way `F.2` name collision — a WARN-severity rule-size check that would have been a wrong-target edit); the count and FAIL-severity invariants hold; the 200/200 rule fragment is genuinely untouched; and the clean-state procedure is guard-legal without disarming or overriding anything. No dimension is FAIL and no finding requires re-architecting — each is a localized correction to the hazard list, one basis label, one symmetry sentence, and the verification plan. **Nothing routes back to requirement-analyst.**

**APPROVED WITH CONDITIONS** — development may proceed subject to C-1 … C-10. C-1 is safety-critical and must be honoured before any mutation step is executed.

---
---

# 03 — Gate Review, Round 2 (targeted re-review) — T-15 `hook-truth-verify-scope` (mode `full`)

> **Provenance note (PM):** as in round 1, the gate-reviewer agent runs read-only and returned this
> review as its response; the PM persisted it here **verbatim** and authored none of it. PM routed
> round 1 back to the solution-architect (rollback #1 at stage 2) rather than handing the conditions
> to the developer, because every condition was a defect in an upstream document.

Re-review scope: §16 changelog first, then every section it names, then the code behind every factual claim it makes. Nothing was accepted on the changelog's word. The architect's "byte-unchanged" claim for §3 / §6 / §8 was spot-checked against round 1's recorded content and holds (assertion set A1–A4/B0/B1/B2 with the same tokens and order; ledger L1–L9; flow diagram).

---

## 1. Condition-by-condition ruling

| # | Ruling | Basis |
|---|---|---|
| **C-1** | **DISCHARGED — genuinely prominent** | Prohibition appears in **four** places at escalating detail: the document header's **Safety notice for the implementer** (`:14-17`, before §1), §11.0 hard rule 2 (`:476-477`), the dedicated **§11.1 Forbidden mutation targets** (`:487-519`), and the §9 guard-script frozen row (`:359`). Not buried. |
| **C-2** | **DISCHARGED — derivation independently re-verified, and I re-derived exhaustiveness the doc does not state** | see §2 below |
| **C-3** | **DISCHARGED** (one accuracy note, R2-3) | M4 falsifies the `else` arm; co-failure-freedom confirmed by my own consumer sweep |
| **C-4** | **DISCHARGED as a usable rule** (mechanism example is wrong — R2-2) | see §2 below |
| **C-5** | **DISCHARGED** | S0 now measures; the "exact clean-checkout condition" phrase is explicitly *withdrawn* at `:551-566`; the head-vs-version contradiction is named at `:530-539` with both outcomes pre-answered; ACs survive |
| **C-6** | **DISCHARGED** | `CONTRIBUTING.md:22` split into its own row (`:356`) as **review-protected, not gate-protected**; the eleven `g4_files` rows enumerated correctly |
| **C-7** | **DISCHARGED** | §3.3 (`:215-229`) narrows the claim and tables S-1/S-2 accurately |
| **C-8** | **DISCHARGED, PM-carried** | §9 (`:351`) records 30/30 + WARN-exits-1 + "rotate, not append", and explicitly marks it not the Developer's surface |
| **C-9** | **DISCHARGED — struck, not deprecated** | full-document sweep for `unanchored\|fallback` below |
| **C-10** | **DISCHARGED** | R-3 round-2 addition (`:402-410`) + S11 (`:694-699`): `wc -l` = 200 at S0 **and** S11, absent from `git diff --name-only`, both pasted, plus the explicit ban on repairing the `:150-151` stale claim |

### Verification of the load-bearing factual claims

**C-1 mechanism — accurate.** `.claude/settings.local.json:22` is `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'` — note the *absence* of the `[ -f … ] && … || exit 0` pattern its three sibling hooks (`:11`, `:32`, `:42`) all carry. `:4` (`_hook_semantics`) states fail-CLOSED explicitly; `.harness/rules/75-safety-hook.md:176` renders the same as a failure-mode row; insight-index `2026-08-01` (line 35) independently states recovery is Read+Write only because `git checkout` is itself a Bash call. Every element of §11.1's justification is real.

**C-1 "one mutation suffices" — sound.** `verify_all.sh:292-296` is a single `for f in …` loop and `verify_all.ps1:278-282` a single `foreach`; A1–A4 are four iterations of one body, so §11.1's refusal to generalise "audit every sibling" from *claims* to *mutating runtime-load-bearing files* is correct, not a rationalisation.

**C-1 safe/forbidden classification — correct.** A3/A4 are `skills/harness-init/templates/common/.harness/scripts/guard-rm.{ps1,sh}`; no hook, no `.git/hooks/pre-commit`, and no skill reads them at runtime. I checked the one propagation path that could have made M1 unsafe: the live `Stop` hook runs **`harness-sync.sh`**, which mirrors only `.harness/agents/` and `.harness/skills/` (`harness-sync.sh:28-96`) — it is *not* `sync-self`, so no automatic hook can promote M1's rename onto the live guard path. That closes the only side door I could construct.

**C-2 — correct, and exhaustive.** `sync-self.sh:74-76` is Mapping 5; `sync_file` (`:22-33`) records drift when `[[ -f "$dst" ]] && cmp -s "$src" "$dst"` fails, which a renamed-away **source** does; `--check` exits 1 (`:95-103`); `verify_all.sh:194-198` renders that as `[E.1] … FAIL`. I then enumerated every consumer of the mutated path to confirm the total is **exactly two**, which the design asserts but does not derive:

- `F.2` (`verify_all.sh:293-294`) → FAIL
- `E.1` (via Mapping 5) → FAIL
- `F.1` (`:284`, PS `:270`) → green. Its pair list is `verify_all sync-self harness-sync test-init test-real-project ambient-prompt ambient-reset upgrade-project language-policy entropy-cadence hook-spec` — **`guard-rm` is absent**, *and* F.1 only ever tests `.harness/scripts/$pair.*`, never a template path, so it could not fire on M1 even if `guard-rm` were listed. (This is the architect's incidental note (b): **correct, and true for two independent reasons**.)
- `D.2` (`:88`) enumerates only `*.tmpl`/`*.append` → green
- `I.6` (`:583-633`) enumerates `git ls-files` and skips a tracked-but-missing path at `:589`; the `.t15bak` residue is untracked → green
- `E.2`/`harness-sync` mirrors only `.harness/{agents,skills}` → green
- `J.1` (`:657`) does not list it; `G.4` count unaffected → green

⇒ `PASS: 30 / WARN: 0 / FAIL: 2`, `exit=2` is right. Write-mode prohibition present and unambiguous in **two** places (§11.0 rule 4 `:479-480`; the S7 DANGER block `:628-632`) — see R2-1 for its (incorrect) stated mechanism.

**C-3 — the new mutation genuinely falsifies B0, and co-failure-freedom is real.** Consumers of `skills/harness-init/templates/common/.claude/settings.json.tmpl` in the gate: exactly `F.2` (`:323`) and `J.1` (`:657`) — confirmed by grep over `.harness/scripts/`, and `Glob **/settings.json.tmpl` returns **one** file tree-wide, so there is no second copy to surprise anyone. `J.1` skips it cleanly at `:660`. It is in none of sync-self's nine mappings (`:63-93`), so **`E.1` stays green** — the asymmetry with M1 is correctly stated. One token, not three, is the correct expectation for the `else` arm as written (§3.1 `:119-121`).

**C-4 — the allow/forbid rule works.** `Step` at `verify_all.ps1:19-37` is verbatim as quoted (`$r = & $action` / `if ($r -eq $false)`), so severity really is decided by pipeline output. The rule at `:192-198` (assignments / `if` / `foreach` / `throw` only; forbidden bare `Test-Path`, `$problems + …`, `Write-Output`, unassigned `Get-Content`; `| Out-Null` escape hatch) forbids **all** pipeline emission, which is a strict superset of the dangerous emissions — so yes, it would prevent the failure mode, and the §3.2 body satisfies it statement by statement. The *illustration* attached to it is wrong; see R2-2.

**C-5 — measurement, not assumption.** The contradiction still stands as of this review: the environment snapshot reports `HEAD = cb0ed57 (v0.44.0)` **clean**, while `.claude-plugin/plugin.json:4` = `0.46.0` and `CHANGELOG.md:8` = `## [0.46.0] - 2026-07-31`. The design now names it, requires it measured, pre-answers **both** branches, and forbids reconciling it. The S1 restatement is accurate: `git worktree add --detach … HEAD` + a disk-only rsync overlay = current working tree minus `.claude/settings.local.json` **over HEAD's index**, and `A.1`/`A.2`/`E.7`/`I.6` (`:633`) do enumerate through git. **The ACs survive the honest restatement**: both the pre-change `F.2` (`:304-329`, pure `[[ -f ]]`/`grep` on disk paths) and the post-change `F.2` (§3.1, same) read nothing through git, so the stale index cannot move `F.2`'s verdict in either direction — the S2→S8 differential remains a genuine measurement. The discrepancy rule (`:577-585`, repeated at `:680-685`) correctly forbids editing the expectation, editing the run, or repairing the scratch tree.

**C-6 — frozen-row basis now correct.** `g4_files` (`verify_all.sh:732-744`) has exactly the eleven entries §9 lists. `CONTRIBUTING.md:22` reads "the gate currently runs 32 checks" and `CONTRIBUTING.md` is absent from `g4_files` — review-protected, not gate-protected. QA addition (i) publishes it with that evidence and adds the correct `40-locations.md` subtlety (`:29` carries the `(32 checks` literal `G.4` tests whole-file; `:42` is L3 and can be reverted unnoticed).

**C-7 — both deviations accurate, narrowed claim true.** S-1: PS `-notmatch` is case-insensitive by default. The design's escape hatch is checked and holds — `J.1`'s key test *is* case-sensitive (`[[ " $j1_valid_hook_events " != *" $jkey "* ]]`, `:687`) and the template's `"PreToolUse": [` sits at exactly 4-space indent (`settings.json.tmpl:48`), the depth `J.1` discriminates on (`:685`), so a `"pretooluse":` template really would be caught by `J.1`. S-2 is argued as unreachable, not as covered — correctly, since `J.1`'s extraction regex is also line-scoped. "For every non-pathological input, including all four S7 mutations, the shells agree" is true as narrowed.

**C-9 — struck.** Full-document sweep for `unanchored|fallback`: every surviving occurrence is either the *deleted* settings-file fallback (`:26`, `:84`), the code comment explaining why the anchor exists (`:114`), the fail-open/fail-closed sense of "fallback" (`:495`), or an explicit record that the variant is **withdrawn and not available** (`:378-387`, `:749`, `:769-773`, `:792`). Nothing in the document offers the developer a choice. §15's old "if the reviewer disagrees" paragraph is gone. Anchor re-verified against the artifact: `settings.json.tmpl:5` is `"_guard_hook": "PreToolUse hook auto-runs…` (quote-then-space — `"PreToolUse"[[:space:]]*:` cannot match) and `:48` is `"PreToolUse": [` (matches).

**C-10 — as required.** I counted `.harness/rules/75-safety-hook.md` at **exactly 200 lines** (last content line 200), and the stale claim is where round 1 put it (`:150-151`: "the verify_all release check would catch any tracked file that hard-codes it"). Both the before/after `wc -l` and the `git diff --name-only` absence are stated as mandatory pasted measurements, and the do-not-repair prohibition is explicit with its two-part reason (201st line ⇒ `I.2` WARN ⇒ exit 1; line-neutral rewrite still dirties a frozen file).

---

## 2. New findings introduced by the round-2 edits

All four are MINOR/INFO. None changes an expected output, a safety outcome, or a verdict.

**R2-1 — MINOR. The S7 DANGER block's *mechanism* is factually wrong; the prohibition it guards is still right.** `:628-632` says running `sync-self.sh` in write mode while a mirrored source is renamed "would `cp` from a **missing source** onto the live `.harness/scripts/guard-rm.sh` … producing exactly the Bash-seizure outcome §11.1 exists to prevent." It would not. `sync_file` (`sync-self.sh:28-32`) does `mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"` — `cp` with a nonexistent source **fails and leaves the destination byte-intact**; there is no truncation and no `rm` on this path (`sync_dir_of_md`'s orphan `rm -f` at `:47-55` has **zero call sites** since the v0.30.0 agent-mapping removal), and the script runs under `set -uo pipefail` without `-e`, so the failure is a message, not a cascade. Round 1 said only "touching the live guard path"; round 2 escalated it to seizure. Why this matters despite being over-safe: a developer who runs the command by accident and believes the live guard was destroyed may hand-"repair" a 900-line security script — **that** would be the destructive act. Keep hard rule 4; correct the belief. *Developer-carried.*

**R2-2 — MINOR. §3.2 hazard 5's concrete example is wrong, though the hazard class and the rule are right.** `:184-190` claims `@("missing:x") -eq $false` "returns a non-empty array, which `if` reads as truthy ⇒ WARN". It returns an **empty** array. In an array-filtering comparison PowerShell converts the right operand to the *element's* type, so the test is `"missing:x" -eq "False"` → false → `@()` → falsy → **PASS**, not WARN. The real WARN triggers are emissions that are (or contain) Boolean `$false` or `0` — precisely the list's own first forbidden item, **a bare `Test-Path $f` line**, which emits `$false` when the file is missing. Its second forbidden item, `$problems + "…"` where `+=` was meant, is a genuine silent-accumulator bug but is **not** a WARN vector. Net: the forbidden list is right, the allow/forbid rule is sufficient (it bans all emission), the rationale sentence is not. Note this defect is inherited from round-1 F-4's own wording — the architect instantiated it faithfully; I am correcting my predecessor as much as the architect. *Developer-carried; do not let a "but I proved the example is false" reading downgrade the rule.*

**R2-3 — MINOR. C-3's suffix constraint is correctly stated but its necessity is overstated, and it is one word short.** `:652-653` — "The `.t15bak` suffix is required: the new name must not end in `.tmpl`, or `D.2`'s `find … -name '*.tmpl'` (`verify_all.sh:88`) would still scan it." The mechanism is real, but (a) the find is `\( -name '*.tmpl' -o -name '*.append' \)`, so the constraint is "ends in neither `.tmpl` nor `.append`", and (b) even if still scanned, `D.2` rejects only **unknown** `{{…}}` placeholders and every placeholder in that file is whitelisted (`:84`) — so `D.2` would PASS either way and M4's one-FAIL expectation is unaffected. `.t15bak` satisfies both forms of the constraint, so the instruction as written is safe to follow verbatim. *Developer-carried as a note only.*

**R2-4 — INFO. An unlisted stale line sits one line above L3's target.** `.harness/rules/40-locations.md:41` — "Script pairs (.ps1 + .sh) for verify_all / harness-sync / sync-self / test-init / test-real-project" — names 5 of `F.1`'s 11 pairs (`verify_all.sh:284`). It is not in §9's frozen list and not in the ledger. Editing it breaks no gate (`G.4`'s expect for this file is the `(32 checks` literal at `:29`), but it would put an unledgered change into the diff and falsify S12's claim that only `:42` moved in that file. Recorded for the same reason F-9 was: **so nobody fixes it while they are in there.** *Developer-carried.*

**Incidental note (a) — CONFIRMED, with one residual check.** `verify_all.sh:821` appends to `.harness/scripts/verification_history.log` on every run; `.gitignore:33` (`*.log`) and `:34` (explicit) both cover it, and the file exists on disk. The ignore only holds if the file was never tracked, which read-only tooling cannot settle — one `git ls-files --error-unmatch .harness/scripts/verification_history.log` at S0 (expect a non-zero exit) closes it permanently. *Developer-carried, one line.*

**Incidental note (b) — CONFIRMED and stronger than claimed, but it is not in the document.** A grep of `02_SOLUTION_DESIGN.md` for `F\.1` returns only R-7's passing mention (`:435`); the F.1-excludes-guard-rm reasoning exists in the architect's report to the PM, not in the artifact the developer reads. Since M1's two-FAIL expectation is *asserted* rather than derived in §11, I have supplied the full exhaustiveness derivation in §1 above so the PM can hand it down with this review. No re-write required.

**No dangling cross-references.** M4 was added inside S7 with no renumbering; the step sequence is still S0…S12 and every `M1/M2/M3` reference elsewhere (`:58-61`, `:373`, `:387`, `:510`, `:518-519`, `:605`) still resolves. No surviving "three mutations" phrasing. The §10.1 operator item was updated consistently with C-1/C-2/C-4 (its (d) now forbids the live guard scripts and pre-declares the `E.1` co-fire; its new (e) is the WARN tripwire). §3.3's "all four mutations" agrees with §11's four. The one apparent tension — §11 S7 "one mutation at a time" vs §10.1(d)'s deliberate two-at-once — is not a contradiction: (d) is the **operator's** Windows list, whose whole purpose is multi-problem rendering.

---

## 3. Invariants — all still hold after the revision

| Invariant | Status |
|---|---|
| No new gate check; one recorded step under `F.2`; total stays 32 | **HOLDS** — §3.1/§3.2 unchanged, two `step` sites in mutually exclusive branches; the revision adds no `step`/`Step` call anywhere; `G.4`'s `${#report[@]} + 1` (`:717`) and the last-check tripwire (`:806-815`) untouched |
| Every retained assertion at FAIL severity | **HOLDS** — §3 `:80-81` unchanged; M4's expectation is `FAIL`; the S7 closing rule (`:668-670`) and the new hazard 5 exist precisely to make a WARN a reportable defect |
| 200-line rule fragment untouched | **HOLDS** — measured at exactly 200; C-10 strengthened rather than relaxed |
| Guard regression driver pinned | **HOLDS** — §7 and S10 unchanged at 87 rows; `baseline.json` read-only |
| No change to guard behaviour or the destructive verb set; anchored form binding | **HOLDS** — no edit to either guard script anywhere in the ledger; §11.1 now forbids even a temporary rename; C-9 verified struck |
| Design must not describe this as reducing guard coverage | **HOLDS** — §1 (`:33-36`), R-8, §12 unchanged; the round-2 additions are all mutation-safety prose and introduce no coverage-reduction phrasing |

---

## 4. Verdict

All ten conditions are **genuinely discharged**, not merely mentioned: each one is implemented at the location §16 claims, and every factual claim I could check against code checked out — including the two I expected to find softened (C-1's prominence and C-9's strike) and the one I expected to find hand-waved (C-3's co-failure-freedom, which the architect re-derived rather than inherited). The four new findings are accuracy defects in *rationale* attached to prohibitions that remain correct; none alters an expected run output, a mutation target, or a safety outcome, so none is a condition.

**Residual items the developer carries into stage 4** (record them in `04_IMPLEMENTATION.md`; do not edit `02`):

1. **R2-1** — hard rule 4 stands, but its stated mechanism is wrong: `cp` from a missing source cannot clobber the live guard. If the command is run by accident, verify with `git status` / `wc -l .harness/scripts/guard-rm.sh` — **do not** hand-repair the guard.
2. **R2-2** — §3.2 hazard 5's allow/forbid rule is binding; its `@("missing:x") -eq $false` example is wrong (that filters to `@()` ⇒ PASS). The genuine WARN vector is an emitted Boolean `$false`/`0`, e.g. a bare `Test-Path` line.
3. **R2-3** — rename to `settings.json.tmpl.t15bak` as written; the constraint is "ends in neither `.tmpl` nor `.append`", and `D.2` would have passed either way.
4. **R2-4** — `.harness/rules/40-locations.md:41` is stale; leave it. Only `:42` changes in that file.
5. **Note (a)** — one `git ls-files --error-unmatch .harness/scripts/verification_history.log` at S0.
6. **Note (b)** — M1's "exactly two FAILs" exhaustiveness derivation is in §1 of this review, not in `02`; paste it into `04` alongside the run.

**PM-carried, not developer-carried:** **C-8** (`.harness/insight-index.md` re-measured at exactly **30/30** evidence lines; the stage-7 harvest must **rotate**, not append — `I.4` at `verify_all.sh:426-436` WARNs above 30 and a WARN exits 1) and ledger row **L9** (`docs/tasks.md` / `BATCH_PLAN.md` status at delivery). The Developer must not pre-emptively trim the insight index.

**APPROVED FOR DEVELOPMENT** — every condition C-1 … C-10 is discharged, no invariant was broken, and the round-2 edits introduced no defect above MINOR. (Full-mode reading: development may proceed; the six residual items above are carried notes for the stage-4 document, not gating conditions.)
