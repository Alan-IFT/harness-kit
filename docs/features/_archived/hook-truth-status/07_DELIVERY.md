# Delivery Summary — T-14 `hook-truth-status`

- **Task**: `hook-truth-status` — make the project-health report resolve hook wiring from wherever it
  legitimately lives (machine-local settings first, committed settings as fallback) and own the "is the
  destructive-command guard installed on this machine" question, fixing the false `DISABLED` verdict.
- **Mode**: full (stages 1-7)
- **Dispatched from**: `/harness-stream` drain of `docs/batches/default/BATCH_PLAN.md`; deferred-human mode
  (defer, do not ask). No human-reserved decision arose; nothing was auto-decided that the decision policy
  reserves for the operator.

## Stages traversed

| # | Stage | Agent | Outcome |
|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | `READY` — 20 FR, 20 boundary rows, 12 AC, 6 NFR, 10 OQ each with a binding `Recommended:` answer |
| 2 | Solution design | solution-architect | `READY` — new `§0 Effective hook source` resolve-once module; all hook outputs routed through it |
| 3 | Gate review | gate-reviewer | **`BLOCKED ON DESIGN`** — F-1 FAIL (false-green path) + 6 WARN + 1 INFO |
| 2r | Solution design r2 | solution-architect | `READY` — all 7 findings closed; F-1 closed with set quantifiers |
| 3r | Gate review r2 | gate-reviewer | **`APPROVED FOR DEVELOPMENT`** — F-1 confirmed closed; 3 WARN carried as delivery conditions |
| 4 | Development | developer | `READY FOR REVIEW` — `verify_all` 32/0/0 |
| 5 | Code review | code-reviewer | **`CHANGES REQUIRED`** — 1 MAJOR (a false causal claim in the stage doc, queued for permanent memory) |
| 4r | Development r2 | developer | `READY FOR REVIEW` — MAJOR-1 closed at all 3 surfaces; product byte-unchanged |
| 5r | Code review r2 | code-reviewer | **`APPROVED`** |
| 6 | QA | qa-tester | **`CHANGES REQUIRED`** — 2 MAJOR found in the shipped skill text; all 12 ACs passing |
| 4rr | Development r3 | developer | `READY FOR REVIEW` — both MAJORs fixed |
| 5rr | Code review r3 | code-reviewer | **`APPROVED`** (0 CRITICAL, 0 MAJOR) |
| 6r | QA r2 | qa-tester | **`APPROVED FOR DELIVERY`** |
| 7 | Delivery | PM | this document |

All stage transitions and the reasoning behind each are in `PM_LOG.md`.

## Rollbacks: 3

1. **Stage 3 → 2** (gate finds design gap). Gate F-1: the guard-verdict decision table admitted
   `INSTALLED AND WIRED` on a guard that would not run — a multi-path hook command with the guard script
   missing, and detection-by-substring that never required the *tested* path to be the guard's. Closed by
   quantifying over the extracted path set (`PATHS` / `GUARD_PATHS`).
2. **Stage 5 → 4** (reviewer finds defect). CR MAJOR-1: the implementation doc asserted a baseline key had been
   "stale since v0.31.0". False — the key is `test_supervisor_bash_no_python3_assertions` and the driver's
   python3-gated assertion makes `45` its *correct* value. The claim was routed as an action item and queued
   for harvest into the 30-line permanent memory.
3. **Stage 6 → 4** (QA finds bugs). Two MAJORs in the shipped text: a **non-total** state table (a `hooks` value
   that is an array matched no state, giving two competent agents opposite verdicts, one of them a false green),
   and a fix-line table with **overlapping keys and no precedence rule** that routed the `unknown ∧ committed`
   state to a repair that could not reach the file the report had just named.

No stage was rolled back three times consecutively, so the hard stop never fired (two at stage 4 was the maximum).

## Final verification

**PASS.** All tallies pasted by the stage that ran them, cross-checked by a later stage against the artifact:

- `.harness/scripts/verify_all.sh` — **PASS 32 / WARN 0 / FAIL 0**. Check count **32**, unchanged (no new check;
  the duplication was removed by composition over the existing `hook-spec` tool, per this repo's T-016 precedent).
- `.harness/scripts/test-supervisor.sh` — **PASS 46 / FAIL 0** on this python3-present host, both structurally
  pinned doc fan-out assertions green, pre-edit and post-edit alike (46 → 46 across this task's edits).
- **PowerShell: not run, and none claimed.** The delivery touches **no `.ps1` file**, so nothing was added to the
  standing operator PowerShell verification list, and the frozen `test_init_ps_assertions` count and both README
  badges were not touched.

## Baseline changes

**None.** `.harness/scripts/baseline.json` is byte-unchanged. Its `test_supervisor_bash_no_python3_assertions: 45`
was investigated during code review and confirmed **correct as-is** — it is the no-python3 value of a
python3-gated driver, and `45` vs the observed `46` is the documented convention (the same file's `_qa_note_t13`
records the identical pattern for `test-init`). QA verified this empirically by shimming a failing `python3` onto
`PATH` and capturing `PASS: 45 / FAIL: 0`. Reconciling it to 46 would have corrupted a correct frozen count.

## Files changed

Delta against the pre-edit tree baseline (the tree already carried T-13's delivered-but-uncommitted changes):

```
 M skills/harness-status/SKILL.md      (the whole behavioral change; 360 -> 376 lines)
 M CHANGELOG.md                        (### Fixed — hook-truth-status (T-14), under the existing [0.45.0])
?? docs/features/hook-truth-status/    (stage docs 01-07 + PM_LOG)
```

No `.ps1`, no `verify_all` change (F.2 narrowing is T-15), no derivation-flow change (T-16), no driver edit, no
`baseline.json` edit, no `.harness/insight-index.md` hand-edit, no settings/hook/template/installer change.
`CONTEXT.md` gained two glossary terms at stage 1 under the analyst's standing glossary habit.

**Version**: OQ-6 **Branch A** — folded into the still-unreleased `0.45.0` (no `v0.45.0` tag exists; the manifest
already reads `0.45.0`). **No version stamp moved.**

## What actually changed for a user

Running `/harness-status` on this repository before this task: `DISABLED — .claude/settings.json has no
PreToolUse for Bash`, and all four lifecycle events reported `not wired` — on a machine where the guard is
installed, wired, and demonstrably blocking. After: **`installed and wired`**, naming
`.claude/settings.local.json` as the file the wiring was found in, with all four congruence rows `ok`. QA proved
the contrast by executing both the pre-edit and post-edit procedures against identical repository state, so the
fix is measured rather than argued.

The report now also distinguishes states it previously collapsed: wiring absent; wiring present but pointing at a
script that does not exist (the state that produced a per-turn error for users historically — never reported as
healthy); wiring present and resolving to an existing script. And it owns the machine dimension: a clone that
never ran the installer is told so and told how to fix it, distinctly from a deliberate opt-out, and every repair
instruction is now conditional on where the wiring actually lives — the report never prints a fix that cannot
reach the file it just named.

## Outstanding risks and carried items

**Safety — highest priority, out of scope here, needs its own task:**

- **QA CRITICAL-OOB-1: `.harness/scripts/guard-rm.sh` inspects only the first verb of each top-level *pipe*
  segment.** Captured exit codes: `rm <outside-path>` → BLOCKED (exit 2), but `echo hi && rm <outside-path>` → 0,
  `true; rm <outside-path>` → 0, and an `xargs`-mediated form → 0. `split_pipes` splits on `|` only and
  `classify_segment` reads `tokens[0]` as the verb. **Pre-existing; T-14 changes no hook script.** PM ruled it out
  of scope rather than widening an in-flight row with a safety-critical change its requirement, design and gate
  never examined. It matters more now that the health report confidently calls this guard healthy — the report is
  truthful about *wiring*, which is what it claims, but the guard's *coverage* is narrower than its reputation.

**Design documents now superseded by the shipped text** (CR MINOR-6 — record so a future re-derivation from the
design cannot re-introduce the two QA MAJORs): `02_SOLUTION_DESIGN.md` §3.1's state table and §5.3's fix table
(the product is deliberately stricter, in the NFR-1-safe direction the design itself mandates); §10.1 step 3,
§10.2 and risk R-1's `PASS: 45` expectation (superseded by 46/0 python3-present, 45/0 without); and probe specs
P-20 (its fixture as written was vacuous — QA rebuilt it) and P-21 (its "no rewrite proposal anywhere" assertion
contradicts §3c's design-frozen interpreter WARN).

**Accepted residuals in the delivered report** (each disclosed, none a false-green the design can close):

- Gate F-9: an extractable, existing guard path in a *non-executing* command position (e.g. inside an `echo`)
  still reaches the healthy row. Closing it needs shell-grammar analysis that FR-11/FR-18 do not authorize, and
  no wiring the harness generates can produce it.
- CR MINOR-4: a guard entry with a non-canonical matcher (e.g. `Write`) never fires on a Bash call yet earns the
  health point with only a flag. **Explicitly mandated by FR-9**, so not a defect of this delivery.
- CR MINOR-1 (a pinned fix-line string restated in a second byte-form), MINOR-2 (§3c's interpreter WARN still
  points at `settings.json` and names only `pwsh`/`bash`, so it can never fire on this repo's `sh`-prefixed
  commands), MINOR-3 (the `UNKNOWN` qualifier is unpinned and its `<file>` slot is singular over a list),
  MINOR-7 (the `UNKNOWN` wording says "does not parse", which is now marginally inaccurate for a wrong-typed
  `hooks` value — must **not** be fixed by moving a pinned string), QA MINOR-5 (§3b is undefined when
  `hooks.PreToolUse` is not an array; no reading reaches the healthy row).

**Backlog candidates surfaced, not folded in:**

- Gate F-8: `AI-GUIDE.md:110`, `docs/getting-started.md:180-182` and `.harness/rules/60-tool-handoff.md:72-74`
  each still say the Stop hook lives in `.claude/settings.json` — three more consumers of the same T-12
  relocation this wave exists to finish.
- `06_TEST_REPORT.md` stands at 1289 lines against the 500-line soft cap. PM declined to remediate by deleting
  round-1 evidence; the file archives out of the live tree at this delivery.

## Next steps

- **T-15 `hook-truth-verify-scope` is now unblocked** — the health report has taken ownership of the machine
  dimension, which was the precondition for the gate's F.2 guard check to shed it.
- T-16 `hook-truth-derivation` remains independently unblocked by T-13.
- The `guard-rm` segment-parsing finding wants a task of its own, ahead of the remaining wave rows.

## Insight

- 2026-07-31 · A `*_no_python3_*` baseline key is NOT comparable to a run on a python3-present host: `test-supervisor.sh`'s AC-7.3 sits inside `if command -v python3 …` with no `else`, so one unmodified driver yields 45 without python3 and 46 with it — a design that quotes such a key as its run expectation mis-derives it and manufactures a phantom "stale baseline" that a developer will then try to reconcile, corrupting a correct frozen count. Same shape as `baseline.json`'s `_qa_note_t13` (355 vs 391 for `test-init`). Read the key's NAME as part of its value before comparing. · evidence: T-14 CR MAJOR-1, `test-supervisor.sh:293-310` + `baseline.json:16,23`
- 2026-07-31 · A state table in a skill document is only executable if it is TOTAL — and totality is broken by the input class nobody enumerated, not by the ones in the examples: T-14's `§0` four-state probe classified `hooks` absent, `{}` and `{…}` but left `{"hooks": []}` (and string/number/bool/null) matching ZERO rows, so two competent agents reached opposite verdicts on one input and one of them was the false-green direction. The gate caught the same class in a DIFFERENT table one stage earlier (rows 6-8 quantified over a single extracted path while the command could yield several) — so when a review finds one non-total table, audit every OTHER table in the same document rather than closing the one finding. QA's 28-input prober evaluating all rows INDEPENDENTLY (no short-circuit) is what makes "exactly one state" falsifiable; a first-match reading hides the hole. · evidence: T-14 gate F-1 + QA MAJOR-1, `skills/harness-status/SKILL.md:24-45`
- 2026-07-31 · A conditional-repair table needs an explicit precedence rule the moment its keys can co-occur: T-14's fix-line table keyed rows on `SOURCE_KIND` and on `MACHINE_STATE` independently, and the `unknown ∧ committed` state matched two rows — the shipped reading picked the repair for a file the report had just declared unparseable, and in the mirror state it read `rm <the only healthy settings file>`, a data-loss-class instruction. Ordering the machine-state rows first with "first match wins" makes the verdict line and the fix line key on the SAME predicate, which is the structural repair; a wording patch is not. · evidence: T-14 QA MAJOR-2 + QA r2 fixture `fx/r2_unknown_ml`, `skills/harness-status/SKILL.md:343-361`
