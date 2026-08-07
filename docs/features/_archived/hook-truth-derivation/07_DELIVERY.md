# Delivery Summary — T-16 `hook-truth-derivation`

- **Task**: T-16 / `hook-truth-derivation` — retire the hand-maintained byte-identical copies of the lifecycle-hook command strings across the project-creation, adoption, upgrade-repair and layout-migration flows by having each derive its commands from the single source of truth, so adding or changing a hook is a one-place edit instead of a multi-file lockstep.
- **Mode**: `full` (stages 1-7)
- **Dispatched from**: `/harness-stream` drain — **the final row in the pool**, and the row the three preceding siblings were leading up to.
- **Decision mode**: Mode 2 (balanced) · **deferred-human mode: defer, do not ask** — no interactive ask was made at any stage, and no human-reserved point was auto-decided.
- **Version**: unreleased v0.46.0 (no stamp moved)

## Stages traversed

| # | Stage | Rounds | Outcome |
|---|---|---|---|
| 1 | requirement-analyst | 1 | **READY** — 8 Open Questions, each with a binding `Recommended:` answer |
| 2 | solution-architect | 3 | r1 READY → r2 rework (11 gate findings) → **r3 record-correction only** |
| 3 | gate-reviewer | 2 | r1 **CHANGES REQUIRED** (1 FAIL, 2 WARN) → r2 **APPROVED FOR DEVELOPMENT** with 2 binding conditions |
| 4 | developer | 2 | r1 READY FOR REVIEW → r2 fix-forward (3 MINORs) → **READY FOR REVIEW** |
| 5 | code-reviewer | 2 | r1 **APPROVED** (4 MINOR, 2 NIT) → r2 **APPROVED** (2 MINOR, 4 NIT) |
| 6 | qa-tester | 1 | **PASS WITH DEFECTS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR, 1 MINOR (record) + 3 NIT |
| 7 | PM delivery | 1 | this document |

## Rollbacks: 2

| # | Trigger | Routed to | Cause |
|---|---|---|---|
| 1 | Gate review round 1 | solution-architect | **F-2** AC-7's anti-vacuity direction was specified against `git show HEAD:`, but HEAD on this tree is v0.44.0 — it predates both `hook-spec.*` and T-15's key-form anchoring, so it measured a check T-16 does not modify. **F-3** the containment-window terminator rule was **non-total** (zero matches when `"PreToolUse"` is the last key in `hooks`, then reported as "unterminated" — a red gate on a valid template). **F-1** the adapter's placement rule did not cover a variable its own candidate list reads; 3 of 4 flow files would abort at load or first call. Plus F-4…F-11. |
| 2 | Code review round 1 | developer | PM routed back **over the reviewer's non-blocking rating**: MINOR #3 was a real **cross-shell verdict divergence in the very gate check this task tightened** (case-insensitive `-match` in PS against a case-sensitive `grep` in bash). All three developer-routed MINORs were mechanical and bash-dischargeable, so fixing them before QA meant QA measured the final artifact. |

Consecutive-rollback ceiling never approached: stage 2 peaked at 1 of 3, stage 4 at 1 of 3.

**Stage 2 round 3 and stages 5b/6b were record corrections, not rollbacks** — no design decision, mechanism, interface, ledger row or acceptance criterion changed in any of them.

## Final gate result: **PASS 32 / WARN 0 / FAIL 0** (bash)

Check count **32 — unchanged**, as required. QA read the count **from the run** (`grep -cE '\.\.\. (PASS|WARN|FAIL)'` over the run output → 32) rather than from `baseline.json`, ran the full suite **3× end-to-end with zero flakes**, and independently reproduced all 18 `baseline.json` numeric keys. The coordinator re-ran `verify_all.sh` after the last edit and confirmed 32/0/0.

## Baseline changes

**None.** Every pinned count held, and none was hand-derived:

| Key | Value | Note |
|---|---|---|
| `verify_all_checks` | **32** | no check added, removed, renamed or narrowed |
| `test_init_bash_no_python3_assertions` | **355** | captured under a **python3-absent shim** — the condition the key's *name* describes. The python3-present run is **391** and was deliberately never compared against it. |
| `test_init_ps_assertions` | **316** | frozen — PowerShell is unexecutable here |
| `test_real_project_*` | 90 / 90 | |
| `test_harness_upgrade_*` | 89 / 89 | frozen deliberately (see RES-1) |
| `test_verify_i6_*` | 58 / 58 | |
| `test_supervisor_*` | 49 / 45 | 46 with python3 present, 45 under the shim |
| `test_language_*` | 39 / 39 | |
| `test_guard_rm_bash_assertions` | **87** | guard untouched |

`test-init`'s T-16 block moved **17 rows in, 17 rows out** in both shells, which is why no pin moved despite a substantial rewrite of the oracle.

## Files changed

**Flow files** — 8 files (4 pairs), edited at the `templates/common/` source and propagated by `sync-self`:
`upgrade-project.{sh,ps1}` · `migrate-scripts-layout.{sh,ps1}`, each in `.harness/scripts/` and `skills/harness-init/templates/common/.harness/scripts/`. `resilient_cmd` / `Get-ResilientCmd` **retired**; replaced by a lazily-resolved, memoised spec adapter with a single failure return that writes nothing.

**Spec headers** — 4 files (comment-only): `hook-spec.{sh,ps1}` ×2 copies each — the two provenance sentences, the corrected T-16 hand-off inventory, and the `hostos` provenance comment.

**Gate** — `verify_all.{sh,ps1}`: the `F.2` containment window (three new tokens into the **existing** accumulators; **no `step`/`Step` call added**).

**Tests** — `test-init.{sh,ps1}` (oracle re-anchored to the frozen literals; Group A′ re-purposed into idiom + substitution-discipline scans) · `test-real-project.{sh,ps1}` (comment only — literals labelled a deliberate frozen oracle).

**Prose** — `AI-GUIDE.md` · `docs/getting-started.md` · `.harness/rules/60-tool-handoff.md` (the three stale settings-location sentences) · `skills/harness-init/SKILL.md` · `skills/harness-adopt/SKILL.md` (placeholder tables now carry semantics, not bytes).

**Docs / memory** — `docs/dev-map.md` · `CONTEXT.md` (two terms coined) · `.harness/rejected-decisions.md` (two records) · `.harness/scripts/baseline.json` (`_qa_note_t16` appended; **every numeric key frozen**) · `CHANGELOG.md`.

**Explicitly not changed**, asserted by the freeze method rather than claimed: `guard-rm.{sh,ps1}` + twins · `evals/guard-rm-cases.md` · `test-guard-rm.{sh,ps1}` · `.harness/rules/75-safety-hook.md` (**still exactly 200 lines**) · `sync-self.{sh,ps1}` · `test-harness-upgrade.{sh,ps1}` · `settings.json.tmpl` (every mutation reverted byte-exact) · `.claude/**` · `CLAUDE.md` · `README.md` badges · **`docs/proposals/frontier-gaps-2026-07.md`** (untracked operator backlog — not edited, not cited as a requirement, not to ride along in any commit).

> The freeze premise was contested and **resolved by measurement**: the session's git snapshot reported a *clean* tree, but the tree was in fact dirty at S0 (38 modified + 10 untracked). The gate adjudicated the snapshot stale and the developer re-derived S0 rather than inheriting either claim. Because a dirty-set difference alone is blind to an edit inside an already-dirty file, the freeze rests on per-file **hash + mtime ordering** against the task's first write. QA left **zero footprint**: `git status --porcelain` byte-identical to QA start.

## The inherited containment residual — decided **IN SCOPE**, and closed

T-15 handed this row a QA-confirmed residual: the two settings-template assertions tested **presence, never containment**, so a template carrying the guard placeholder inside some *other* hook block while having an empty `PreToolUse` array would pass under a "wiring present" label.

**Decision: in scope for this row, and closed.** Reasons: T-15's own design nominates T-16 by name and asks that it be carried as an explicit sub-item rather than rediscovered; the weakness is a *proven false-green in the check that names the guard*; the fix adds **no check** (count holds at 32) and its blast radius is one check per shell; and it is self-detecting, because a broken assertion reddens the gate this task must pass anyway.

Closed by a containment window over the `PreToolUse` block — leading-whitespace-delimited, no JSON parser, symmetric across shells. Proven both directions: mutation **M-C** (placeholder relocated into `Stop`, `PreToolUse` emptied, `hooks` container and key preserved) yields **exactly two tokens** and whole-gate 31/0/1, while the **pre-change** gate PASSes the same mutant — the anti-vacuity direction. The pre-change artifact is an **S0 working-tree capture**, never `git show HEAD:`; QA proved its admissibility four ways, including a content-level one (the capture carries T-15's anchoring and none of T-16's three tokens).

## What was proven, and how

- **AC-2 byte-identity** — re-proved by QA against a genuinely non-circular oracle: `cb0ed57` (v0.44.0) **predates `hook-spec` entirely**, so it cannot be contaminated by the artifact under test. 8/8 cells byte-identical for both script flows, plus the prose cells.
- **Fail-closed asymmetry** — the code reviewer established it *structurally*: there is no expression in either flow that **constructs** a command string; the adapter's only source is the spec's stdout and its only alternative is "return nothing". All failure branches were enumerated into that single return and each followed to its terminal exit code. QA added the probe nobody had specified — a **partial answer** where six of eight cells resolve and `guard-rm` alone does not → exit 4, no permissive value, and no residue blessed on the re-run.
- **The `&` hazard** — not argued, **measured**: QA showed the naive `${var//…}` writes `{{GUARD_COMMAND}}` *into the middle of the live guard command*, and that the shipped literal-replacement helper is immune.
- **AC-1 single source by construction** — a byte mutated in the spec (both twins, both copies) propagated to all four flows with **zero edits to any flow**; the marker appears 0 times in every flow file. Reverted; `sync-self --check` in sync.
- **NFR-1** — measured at exactly **9** spec spawns per run, confirming the cache survives (the out-variable convention exists because a `$( … )` capture would fork a subshell and silently discard every cache write — 13 spawns against a ceiling of 9).

## Outstanding risks and residuals (all record-only; none blocking)

1. **The entire PowerShell surface is unverified.** `pwsh` is absent here; **no `.ps1` was parsed or executed by any agent in either round**. The operator list grew **11 → 16** numbered items (security-marked **2 → 4**), 24 total including the 8 un-numbered T-13 obligations. **Binding**: `verify_all.ps1` and `test-init.ps1` were re-touched *after* the list was written, so **operator items 14(a), 15(a) and 16 must be re-run against the round-2 bytes** — any earlier `ParseFile` result for either is stale.
2. **A one-sided PowerShell host-OS *selection* delta on Windows PowerShell 5.1.** Pre-change `upgrade-project.ps1` read `if ($IsWindows)`; the spec reads `if ($IsWindows -or $env:OS -eq "Windows_NT")`. On 5.1 `$IsWindows` is undefined, so the pre-change flow selected **unix** byte-forms on a Windows host and the post-change flow selects **windows**. Ruled a **strict improvement** (it fixes a latent 5.1 defect), it cannot fail-open (both selected forms are spec-authored fail-closed strings), and AC-2 is untouched because OS is a *parameter* of the 8-cell comparison. Bash has **zero** such delta. Recorded because a behaviour change shipped under a "provenance changes, bytes do not" premise must not travel silently.
3. **RES-1 — standing end-to-end coverage of a *flow-emitted* byte string is one `(tool, OS, flow)` cell.** `migrate-scripts-layout` has no byte-level standing assertion at all. All 8 cells were covered once by capture, and Group A′ pins both ends of the composition argument, but the standing 8-cell assertion is open. Deliberately not closed: doing so means unfreezing `test-harness-upgrade` and moving a PowerShell pin **no agent on this host can reconcile**.
4. **R-1 — the `"command"`-key matcher differs across shells** (`verify_all.sh:359` `[[:space:]]` vs `.ps1:341` `[ \t]`). **Deliberately left open on a measurement**, not overlooked — see the insight below. Observing the divergence requires a form-feed, vertical tab or CR inside a JSON template the gate itself owns.
5. **`verify_all.ps1:315`'s presence check is case-insensitive** against a case-sensitive bash twin. **Pre-existing at `cb0ed57`**, deliberately out of scope. Post-fix the exposure is a **diagnostic-token-set divergence, not a verdict divergence** — a lowercase placeholder now FAILs in both shells because the containment check backstops it; QA measured the bash half (2 tokens vs PS's 1, same FAIL verdict). One-character fix, bash-verifiable, no operator item needed.
6. **Minor record/style items** carried for a future pass: an unqualified "awk" claim in the in-gate comment that should name the measured awk; two off-by-one citations of that comment; `-cmatch '-replace'` leaving **both** shells equally blind to `-Replace` (symmetric and documented now, previously asymmetric and lucky — widen both sides together); a 4th pre-existing "Stop hook in `.claude/settings.json`" claim in `install-hooks.*`, out of scope here; and a corrupt spec answer being written verbatim (unreachable via `.gitattributes`, standing-detected by the re-anchored oracle).
7. **The `archive-task` insight harvester defect is untouched**, as scoped — every insight below is therefore authored as a **single unwrapped line**.

## Next steps for the operator

- Run the PowerShell verification before any release tag: `[Parser]::ParseFile` every touched `.ps1`, then the drivers. **Items 14(a), 15(a) and 16 are mandatory re-runs** against round-2 bytes.
- Reconcile `test_init_ps_assertions` (316) and the two README PS badges **together**, from a real Windows run — never separately.
- Regenerate `git diff --stat` for the commit, and keep `docs/proposals/frontier-gaps-2026-07.md` out of it.

## Insight

- 2026-08-01 · A refactor can retire a test's ORACLE without touching the test: once the four flows delegated to `hook-spec`, `test-init`'s spec-vs-live-helper comparison would have compared the spec with itself, and it was loud-red only because the extraction was NAME-anchored (`awk` range / `FunctionDefinitionAst`) and broke — had the extraction kept working, 9 rows would have gone green-and-vacuous. Audit every name-anchored extractor before retiring a symbol, and re-anchor the oracle to a frozen literal rather than to the artifact under test. · evidence: T-16, `test-init.sh:771` pre-change vs the `[T-16][A]` rows post-change
- 2026-08-01 · `[ \t]` inside a BRACKET EXPRESSION means a tab to awk but the class `{space, backslash, t}` to GNU grep 3.11, so `grep -E '"x"[ \t]*:'` MISSES a real tab and MATCHES `"x"t:` — a reviewer-suggested cross-shell "harmonization" of a gate matcher would have shipped both a false FAIL and a false PASS, and was correctly declined on measurement. Compounding trap: this host's interactive/tool-shell `grep` is ugrep 7.5.0, which reads `[ \t]` as a tab, so a by-hand check endorses the broken form while the non-interactive script run gets GNU grep. Measure a matcher per tool; never infer it from a sibling line in the same file. · evidence: T-16 round 2, `verify_all.sh:354-359` comment + captured `/usr/bin/grep --version` vs awk contrast run
- 2026-08-01 · A fixture that produces the expected verdict is NOT evidence that the rule change was necessary — T-16 cited a block-form `PreToolUse`-as-last-key template as proof that the round-1 `== IND` terminator rule was non-total, and QA measured that `== IND` PASSes it too, because the array's own `]` sits at width exactly IND. The rule change was right and the fixture was real; what was false was that it DISCRIMINATED between the old rule and the new one. A totality claim needs a fixture the rejected rule actually fails (here: an INLINE last-key form). · evidence: T-16 QA D-1, `start=68 IND=4 term=78` under both rules
- 2026-08-01 · A memoisation cache held in shell variables is SILENTLY discarded by the `x="$(fn …)"` call convention, because command substitution forks a subshell and every cache write dies with it — the function still returns the right value, so the defect is invisible except as a spawn count (13 against a documented ceiling of 9). When a helper both returns a value and mutates state, the call sites must use an out-variable, and the spawn count is the only observable that falsifies it. · evidence: T-16 D-6, measured at exactly 9 spawns per run post-fix
- 2026-08-01 · Retiring a duplicated symbol is not finished when the call sites are rewired: the PROVENANCE COMMENTS that cite it are a lockstep surface too, and they fail silently because no gate reads prose — T-16 found four separate sentences naming a helper that would no longer exist (two caught by the architect, one by the gate as a ledger omission, one by the code reviewer), and a fifth citation living in the design document's own justification, which had to be WITHDRAWN rather than re-pointed because re-quoting a sentence the task itself wrote would be circular. · evidence: T-16, `hook-spec.{sh,ps1}` provenance sentences + `02_SOLUTION_DESIGN.md` §20
