# Delivery Summary — T-13 `hook-truth-spec`

- **Task**: T-13 / `hook-truth-spec` — establish a single executable source of truth for the harness lifecycle-hook wiring (four events × two OS command byte-forms + each one's fail-open / fail-closed semantics), and prove it by having the one-shot local-environment installer regenerate a missing machine-local settings file from it idempotently.
- **Mode**: `full` (stages 1-7)
- **Dispatched from**: `/harness-stream` drain of `docs/batches/default/BATCH_PLAN.md`
- **Decision mode**: Mode 2 (balanced) · **deferred-human mode: defer, do not ask** — no interactive ask was made at any stage, and no human-reserved point was auto-decided.
- **Version**: v0.44.0 → **v0.45.0**

## Stages traversed

| # | Stage | Rounds | Outcome |
|---|---|---|---|
| 1 | requirement-analyst | 2 | READY; Amendment 1 (gate W-5) |
| 2 | solution-architect | 2 | READY; rework round 1 (gate F-1/F-2) |
| 3 | gate-reviewer | 2 | R1 CHANGES REQUIRED (2 FAIL) → R2 **APPROVED FOR DEVELOPMENT**, 8/8 PASS |
| 4 | developer | 4 | READY FOR REVIEW (initial + 3 rework rounds) |
| 5 | code-reviewer | 3 | R1 CHANGES REQUIRED (1 MAJOR) → R2 APPROVED WITH NITS → R3 **APPROVED WITH NITS** |
| 6 | qa-tester | 3 | R1 PASS WITH DEFECTS → R2 PASS WITH DEFECTS → R3 **PASS** (0 MINOR) |
| 7 | PM delivery | 1 | this document |

## Rollbacks: 4

| # | Trigger | Routed to | Cause |
|---|---|---|---|
| 1 | Gate review round 1 | solution-architect (+ analyst, parallel) | **F-1** count-ledger missed a live site; **F-2** the AC-3 byte-identity "proof" rested on a transitive chain that did not exist in the driver. Analyst amended NFR-4 scoping (W-5) in parallel. |
| 2 | Code review round 1 | developer | **M-1** — the installer enforced `n_wired > 0` instead of `== 4` and had dropped two design-mandated literal confirmations, so a partial wiring could exit 0 with a green report. |
| 3 | QA round 1 | developer | **r-1 / r-6** — PM routed this back *over QA's non-blocking rating*: a step-7 refusal left a **guardless** settings file that the next run blessed with exit 0. |
| 4 | QA round 2 | developer | **r-7** — the gate PM had just forced into existence had zero anti-revert coverage. The constraint that caused the omission ("assertion count must stay unmoved") came from PM's own brief and was withdrawn. |

Consecutive-rollback ceiling was never reached: stage 2 peaked at 1 of 3, stage 4 at 2 of 3.

## Final gate result: **PASS 32 / WARN 0 / FAIL 0** (bash)

Check count **32 — unchanged**, as required (a change would trip the G.4 version/claim consistency gate). Captured 3× by QA in the final round, and green **from the bootstrapped state** (AC-8).

## Baseline changes

| Key | Before | After | Why |
|---|---|---|---|
| `test_init_bash_no_python3_assertions` | 278 | **355** | +45 hook-spec block, +32 installer-bootstrap block (runtime rows). Both moves captured from real runs. |
| `test_init_ps_assertions` | 316 | **316** | Deliberately unreconciled — PowerShell is unexecutable in this runtime. Both README `test--init-316%2F316` badges correspondingly frozen. |
| `verify_all_checks` | 32 | **32** | No check added, removed or narrowed. |
| all other keys | — | unchanged | `test-real-project` 90/0, `test-harness-upgrade` 89/0, `test-verify-i6` 58/0, `test-language` 39/0, `test-supervisor` 45/0 |

## Files changed

> PM has no shell in this runtime, so this list is assembled from the design's change ledger as verified by the code-reviewer across all rounds — **not** from a `git diff --stat`. Regenerate the stat before tagging.

**New (4)** — the hook wiring spec, source in the distributed template and byte-mirrored into the repo:
`skills/harness-init/templates/common/.harness/scripts/hook-spec.{sh,ps1}` · `.harness/scripts/hook-spec.{sh,ps1}`

**Modified — scripts:** `install-hooks.{sh,ps1}` (both repo and `templates/common/` halves) · `sync-self.{sh,ps1}` (new Mapping 9) · `verify_all.{sh,ps1}` (F.1 name array + PS Step label only — **no check added**) · `test-init.{sh,ps1}` · `baseline.json`

**Modified — docs/rules:** `.harness/rules/75-safety-hook.md` + its `.tmpl` twin · `.harness/rules/40-locations.md` · `docs/dev-map.md` · `AI-GUIDE.md` · `CONTEXT.md` (two terms coined at stage 1) · `CHANGELOG.md` · `README.md` · `README.zh-CN.md` · `.claude-plugin/plugin.json` · `.claude-plugin/marketplace.json`

**Modified — archive (under explicit coordinator scope grant, append-only):**
`docs/features/_archived/resilient-hooks/04_IMPLEMENTATION.md` · `docs/features/_archived/resilient-hooks/06_QA_REPORT.md`

**Task docs:** `docs/features/hook-truth-spec/{PM_LOG,01…07}.md` · `docs/tasks.md` (PM-owned)

**Not in this change set** — an untracked `docs/proposals/frontier-gaps-2026-07.md` appeared in the working tree mid-session. Neither PM nor any stage agent created it; QA confirmed by measurement that the gate is 32/0/0 both with it present and with it parked. **It should not ride along in T-13's commit.**

## What was proven, and how

- **AC-3 (byte-identity)** — all 8 `(tool, OS)` cells compared against the **live** `resilient_cmd` / `Get-ResilientCmd` helpers, extracted by awk-range/AST rather than sourced (sourcing would `exit 1` the test driver), behind a **call-through** anti-vacuity assertion whose three vacuous-pass routes were each closed. The decisive enabling fact: both helpers take the OS as a *parameter* and read no host signal, so one Linux bash run drives all four Windows and all four unix forms.
- **NFR-2 (fail-closed)** — re-measured by QA: 6 missing/unreachable-guard variants × 10 repetitions → exits 127/126/127/2/2/2, **never 0**. FC-1…FC-4 verified independently by the reviewer in all four installer halves.
- **The installer bootstrap** — a 7-row degradation matrix, artifact-mutated, with **both runs of every row** measured. After the final patch, every degraded row exits 4 with the target **absent**, so no guardless residue can exist for the idempotence rule to bless.
- **Anti-revert** — deleting either gate line turns the suite red with the new row as the sole failure; reverting the arity check reddens a *different* single row. The two rows cleanly partition the two gates.

## Outstanding risks and known bounds (all record-only; none blocking)

1. **PowerShell is green-by-symmetry-only.** No `.ps1` in this change set was executed. **Eight binding operator items** are enumerated in `04_DEVELOPMENT.md` and mirrored into `baseline.json:_qa_note_t13` (the artifact that travels to the operator). At minimum, before any release tag: `[Parser]::ParseFile` every touched `.ps1`, then run `install-hooks.ps1`, `test-init.ps1` and `verify_all.ps1` on Windows, then reconcile `test_init_ps_assertions` (316) and the two README badges **together**.
2. **n-10 — the distinct-events gate assumes `hook-spec` has exactly four tools.** A future *fifth* tool with a fifth distinct event would reopen a narrow guardless-residue path. Requires *adding* to the spec, not degrading it. Relevant to T-16 and to any later hook addition.
3. **n-7 — the bash gate counts lines, not answers.** An `event` answer containing an embedded newline would bypass it. QA probed reachability: `hs_event` is a `case` over four compile-time string literals with no external input, so the bypass requires editing `hook-spec.sh` itself — and whoever can do that can equally delete the gate. Declined as unreachable; recorded so it travels.
4. **n-11 — `sort -u` is case-sensitive, `Sort-Object -Unique` is not.** On a mutated spec the PS twin is stricter than bash. Disclosed in-code and in the operator note.
5. **n-9 — wording only**: the operator note calls `Test-InstallBootstrap` "32 `Assert` calls"; the source has 29, one inside a four-tool loop, yielding 32 runtime rows. 32 is the number the operator needs, so the guidance is operationally right.
6. **The archive annotation (DEV-8) was made under an explicit coordinator scope grant.** The code reviewer notes it would otherwise have been an out-of-scope violation, so the grant is load-bearing and is recorded here for any later audit.
7. **Interim duplication is unchanged, by design.** The four derivation flows still carry hand-maintained byte-form copies; `test-harness-upgrade.{sh,ps1}` carries two more. **T-16** consumes the spec and deletes them; the spec's header comment names every remaining call site so the follow-up cannot lose them.

## Next steps

- **T-16** (`hook-truth-derivation`) is now unblocked — the spec exists in the distributed template, reachable by the upgrade-repair and layout-migration flows, with its T-16 hand-off enumerated in the header.
- **T-14 / T-15** are an independent chain and were untouched, as scoped.
- Run the operator PowerShell verification before tagging v0.45.0.
- Regenerate `git diff --stat` for the commit, and keep `docs/proposals/frontier-gaps-2026-07.md` out of it.

## Insight

- 2026-07-31 · A pass/fail tally can be **fabricated even when its value is correct** — T-12 archived a bash `test-init 278/0` that no run produced (hand-derived 276+2) and it survived a full pipeline precisely *because* 278 was right; it was only caught when a later task ran the committed pre-change driver and found it terminates with no `=== Result ===` line at all. Second occurrence of the 2026-06-04 tally insight, so the discipline needs a sharper rule: cross-check a reported tally against **the artifact that allegedly produced it**, not against arithmetic. · evidence: T-13 rework 1, captured `cb0ed57` worktree run + `_archived/resilient-hooks/04_IMPLEMENTATION.md:122` annotation
- 2026-07-31 · A hook command value interpolated into an `eval`-based `assert` helper **silently truncates the whole test driver** on unix: the value's single quote closes the eval's quoting and the residue `… && exec bash <hook> || exit 0` either execs over the driver or exits it, so the run ends mid-suite with **no summary line and no FAIL**. Invisible on MSYS, where the OS-picked value is the `pwsh` form with no `'`. Detection signal is the *absence* of `=== Result ===`, not a red row. Exposure window T-12 → T-13. · evidence: T-13 DEFECT-DEV-1, `test-init.sh:363-368` fix, 278 → 353 tally recovery
- 2026-07-31 · PowerShell's **binary** `-join` sits in the comparison-operator precedence group, **below** `+`, so `"…" + $n + ": " + ($a | …) -join ' ' + ")"` re-associates to `("…" + $n + ": " + $a) -join (' ' + ")")` and produces a wrong string **with no error at all**. Use `-f` (which binds above `+`) or parenthesize. New member of the agent-unexecutable-PS hazard family, and it arrived via a *verified* patch handed over with a complete bash form but only a partial PS form — a cross-shell hand-off must be complete in both shells or it manufactures this class. · evidence: T-13 rework 2, `install-hooks.ps1:257-258`, QA self-reported hand-off gap
- 2026-07-31 · "All four or nothing" enforced as a count of **ids** is strictly weaker than a count of **distinct events**: duplicate ids satisfy an arity check and every per-item comparison, wiring one event while reporting green. Because events are a function of tools, `distinct events == 4` forces the full tool set **without** assuming the event map is injective. Equally load-bearing: the refusal must precede the **write** — a loud exit-5 refusal *after* the write leaves a residue that the "never overwrite an existing file" idempotence rule then blesses at exit 0 on the next run (loud-then-quiet). · evidence: T-13 QA r-1/r-6, `install-hooks.sh:205,213-214` + 7-row degradation matrix
