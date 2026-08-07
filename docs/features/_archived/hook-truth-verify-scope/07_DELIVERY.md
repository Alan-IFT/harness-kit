# Delivery Summary — T-15 `hook-truth-verify-scope`

- **Task**: `hook-truth-verify-scope` — narrow `verify_all`'s guard-wiring check (`F.2`) to assertions
  the repository itself can answer, so a clean checkout stops failing the release gate on an
  environment condition.
- **Mode**: `full` (7 stages), dispatched from a `/harness-stream` drain, `deferred-human mode: defer`.
- **Outcome**: **DELIVERED** (built — the ASSESS-FIRST re-evaluation returned **PROCEED**, not decline).

## Stages traversed

| Stage | Agent | Result |
|---|---|---|
| 1 Requirement (ASSESS FIRST) | requirement-analyst | **PROCEED**, READY |
| 2 Design r1 | solution-architect | READY |
| 3 Gate r1 | gate-reviewer | APPROVED **WITH CONDITIONS** C-1…C-10 → rollback |
| 2 Design r2 | solution-architect | READY — all 10 conditions folded, 0 disputed |
| 3 Gate r2 | gate-reviewer | **APPROVED FOR DEVELOPMENT** — all 10 discharged |
| 4 Development | developer | READY FOR REVIEW — `verify_all` PASSED 32/0/0 |
| 5 Code review | code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 7 MINOR, 6 NIT |
| 4 Dev r2 + 2 Design r3 | developer / solution-architect | doc-only fix-forwards (parallel, disjoint files) |
| 6 QA | qa-tester | **APPROVED FOR DELIVERY** — 0 blocking, 2 MINOR doc-only |
| 4 Dev r3 + 2 Design r4 | developer / solution-architect | doc-only fix-forwards (parallel, disjoint files) |
| 7 Delivery | PM | this document |

All stage transitions and decisions are in `PM_LOG.md`. `.harness/intervention.md` was checked at
every stage boundary and was absent each time.

## Rollbacks

**1 rollback** — stage 3 → stage 2, gate-driven.

The gate approved *with conditions*, but its findings routed **1 CRITICAL and 4 MAJORs to the
architect**, and every one was a defect in the design document rather than in the code. Since
downstream agents may not edit upstream documents, carrying them as dispatch-prompt patches would
have left the design stale and made the implementation answer to a prompt instead of an approved
spec. The decisive finding: the verification plan never *forbade* mutating the two live guard-script
assertions, one of which is the live fail-CLOSED `PreToolUse` hook — renaming it seizes the entire
Bash toolchain, and recovery is Read+Write only. The plan happened to pick a safe target but never
said the dangerous ones were off-limits, while the "audit every sibling" discipline in force actively
pushed toward generalising the mutation to all four.

Four further **fix-forward rounds** (2 after code review, 2 after QA) are *not* counted as rollbacks:
all were doc-only, on disjoint files, and none touched shipped code logic. No stage rolled back twice.

## The ASSESS-FIRST outcome

This row was dispatched with an explicit instruction that it might no longer be worth building, since
T-13 made the machine-local settings file bootstrappable and T-14 gave the health report ownership of
the machine dimension. Stage 1 tested the decline case against evidence and rejected it:

- The clean-checkout failure is **reproducible in both shells**: the machine-local file is gitignored,
  so the check falls back to the committed settings file, which has carried an empty hooks object
  since T-12 — all three wiring assertions then fail at FAIL severity.
- The check's own in-code justification ("a user project that keeps hooks in the committed file is
  still validated") is **false for this script**: this 32-check gate is dogfood-only; generated
  projects run the type-overlay gate, which contains zero occurrences of the guard/hook tokens. The
  machine read protected exactly one machine and removing it costs **zero** user-facing coverage.
- The cheap middle path — assert only when the file is present — is **unsound**, because the
  documented durable opt-out *is* a present machine-local file with an empty hooks object. A
  present-implies-wired assertion at FAIL severity would turn the documented disable path into a gate
  failure. The machine dimension has no correct expression inside a repository gate at all.
- The T-10 decline precedent was tested and distinguished: T-10 declined because **no defect
  remained**; here a reproducible FAIL remained, and this change *removes* surface rather than adding it.

## Final `verify_all` result

**PASS** — `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`, pasted from the run that produced it (re-run after
the last edit of the last round). A WARN would have been a hard failure here: `verify_all` exits 1 on
`warns > 0`.

## Baseline changes

**None.** No pinned count moved and no version stamp moved.

- Gate check count **32**, unchanged — no new check was added, including one that would have
  "compensated" for the narrowing. Two `step` call sites in mutually exclusive branches record one check.
- Guard regression driver **87 / 0**, pin held.
- Other drivers, all pasted from their runs: `test-verify-i6` 58/0 · `test-init` 391/0 ·
  `test-real-project` 90/0 · `test-harness-upgrade` 89/0 · `test-language` 39/0 · `test-supervisor` 46/0 ·
  `sync-self --check` in sync. **Every driver printed a summary line** — QA treated the *absence* of one
  as a failure signal, per the T-13 insight; none occurred.
- `test-supervisor`'s 46 against a baseline of 45 is **correct, not a stale pin**: the baseline key names
  the *no-python3* variant and python3 is present on this host. QA read the key's name as part of its
  value rather than "reconciling" a correct frozen count — exactly the trap recorded in insight-index.
- Version folded into the **unreleased 0.46.0**; no stamp moved.

## What shipped

`F.2` became a single-source check over tracked repository content, in both shells. It asserts seven
facts, all at **FAIL** severity: the four guard scripts exist (repo pair + distributed template pair),
and three facts about the distributed settings template — that it exists, that it carries the guard
command placeholder, and that it carries a `"PreToolUse"` hook key. The settings-file evidence
selection and its three wiring assertions are deleted; **no settings file is read in either shell**.

Two corrections rode along, both forced by the narrowing rather than bolted on:

- **The template hook-block assertion was vacuous and is now anchored.** The old whole-file match was
  satisfied by the template's own documentation string, so deleting the entire hook block still passed
  — in both shells. QA proved this against the *committed pre-change script*: with the block deleted,
  the old gate emitted no hook-block token at all. Anchoring to the JSON key form is what makes the
  check's new label true rather than merely narrower.
- **The PowerShell branch stopped throwing on the first problem** and now accumulates, matching its
  bash twin, so both shells report every problem in one message.

## Guard coverage — stated plainly (AC-12)

**Behavioural guard coverage is unchanged.** The gate has never asserted what the guard *does* — only
that its scripts exist and something is wired. That blindness is how the chained-command bypass
survived until T-17. Behavioural coverage lives in the regression driver, still **87 rows**, unmoved.

**The machine dimension moved; it did not evaporate.** It is owned and reported by `/harness-status`
§0 "Effective hook source", confirmed **by execution** in both the never-installed and the
installed-and-wired states, and independently re-derived by the code reviewer from live inputs.

## Outstanding risks

1. **PowerShell is unverified.** `pwsh` is not installed on this host, so the `.ps1` twin is
   **green-by-symmetry only**. It was audited statement-by-statement against all five known hazards
   (whole-file parse failure from a never-taken branch, read-only automatic-variable collision, the
   `-join` precedence trap, and the step harness deriving severity from pipeline output), plus
   structural brace/paren counts and a top-level step-count match — but an audit is not a run. Added as
   item **11** on the standing operator PowerShell list; the frozen T-13/T-17 items were not touched.
2. **A stated coverage residual, deliberately not fixed.** The placeholder assertion and the hook-block
   assertion each test **presence** over the whole file, never **containment** — so a template with the
   placeholder inside a different hook and an empty pre-tool block **passes** while the label reads
   "wiring present". QA confirmed this empirically with two constructed templates, one of them in
   precisely the state that caused the original defect. Closing it means matching the placeholder
   within the block's byte range or against the hook wiring spec — that is **T-16**'s territory, and it
   is flagged there as an explicit sub-item. Nothing currently pins it; T-16 should carry a regression row.
3. **Three cross-shell deviations, all argued unreachable, none with a PowerShell-side backstop.** The
   PS regex engine is wider than the POSIX bracket expression along two axes (case folding, whitespace
   breadth). Two of the three exist *because* this task anchored the assertion — recorded as an
   accepted cost of the anchor, not a reason to revisit it, since the anchor's benefit is measured and
   the stricter shell is not weakened. The "PS accepts a superset of bash" direction is **observed
   across 13 measured cases, not proved**.
4. **Freeze evidence is weaker than usual for this tree.** Three sibling rows are uncommitted, so ~37
   files were already dirty and "absent from the diff" was unsatisfiable. The frozen list is carried by
   an mtime table plus targeted reads, not by a diff; byte-level freeze of already-dirty files is
   unprovable without a commit.
5. **Nothing was committed.** The tree is left green; the operator commits.
6. **A latent defect in `archive-task` was found by this delivery and is NOT fixed** (out of scope —
   it is a new defect class in a different tool). See the archive-time incident below; it needs its
   own pool row, covering both shells and the two distributed template copies.

## Archive-time incident (stage 7) — the harvester silently truncated this task's insights

Running `archive-task` harvested all four `## Insight` bullets, rotated four old ones out, moved the
stage docs, and exited **0** — while **truncating every one of the four to its first physical line**,
leaving zero surviving `· evidence:` pointers.

- **Root cause**: the harvester's awk filter emits only lines matching the bullet marker
  (`archive-task.sh:52`). A bullet authored as *wrapped* text loses every continuation line. Prior
  insights survived only because they happened to be written as single unwrapped lines.
- **Why it is nasty**: it fails silently at exit 0; the script's own console echo reprints the same
  truncated first lines, so the output *looks* correct; and `I.4` cannot catch it because that check
  counts bullet **lines**, not content. The gate stayed green at 32/0/0 with the memory corrupted.
- **Contributing cause on this side**: the index header (`Append new insights below, one per line`)
  is a **hard input contract**, not a style note. This delivery's `## Insight` section violated it.
- **Repair (PM, at delivery)**: the four insights were rewritten in the index as complete single
  lines with their evidence pointers restored, a **fifth** was added recording the harvester defect
  itself, and — because that would have put the index at **31 of 30**, and a WARN exits 1 — one
  oldest entry was hand-rotated to `insight-history.md` using the same oldest-first mechanism the
  script uses, under a labelled heading. Nothing was dropped or duplicated.
- **Independently verified afterwards**: `verify_all` **32 / 0 / 0** exit 0 with `I.4` and `I.5` both
  PASS; index at exactly **30** bullets; **5 of 5** T-15 bullets complete and evidence-bearing; the
  rotated entry present exactly **once** in history (38 bullets) and **zero** times in the index; the
  200-line rule fragment still 200; all 8 stage docs archived; and both guard scripts plus the
  machine-local settings file provably untouched by mtime ordering.
- **Not fixed here**: the harvester itself, its PowerShell mirror, and the two template copies. Fixing
  it is scope expansion beyond this task and belongs to its own row.

## Files changed

Seven files, plus this task's stage docs:

- `.harness/scripts/verify_all.sh` — `F.2` narrowed, anchored, relabelled, comment rewritten
- `.harness/scripts/verify_all.ps1` — same seven facts, accumulate-then-throw (green-by-symmetry)
- `.harness/rules/40-locations.md` — one line; the stale line immediately above was deliberately left
- `AI-GUIDE.md` — script-index phrase; the gate-protected count literal on the same line survived
- `CHANGELOG.md` — one entry appended inside the existing `[0.46.0]`
- `CONTEXT.md` — one glossary term
- `.harness/rejected-decisions.md` — one record for the rejected presence-conditional form

Untouched and verified: both guard scripts, `.claude/settings.local.json`, `.claude/settings.json`,
`.gitignore`, `baseline.json`, and `.harness/rules/75-safety-hook.md` (exactly **200 of 200** lines,
md5-identical before and after; its unrelated stale claim deliberately **not** repaired, since a 201st
line would WARN and a WARN exits 1).

## Next steps for the user

1. **Review and commit.** Agents leave a green tree; commits are yours.
2. **Run the PowerShell verification list before the next release tag** — now **11** items, two marked
   security. Item 11 is this task's `verify_all.ps1` `F.2` block.
3. **T-16** is unblocked and inherits the containment residual as an explicit sub-item.

## Insight

- 2026-08-01 · A verification gate that reads **machine state** cannot be made correct by
  conditionalizing it — "assert only when the machine-local file exists" is *also* wrong, because the
  documented durable opt-out for this repo's safety hook **is** a present file carrying an empty hooks
  object, so a present-implies-wired assertion at FAIL severity turns the documented disable path into
  a gate failure. The only sound resolutions are to drop the assertion or to move it to a reporter that
  can distinguish absent / opt-out / dangling / healthy. Corollary for ASSESS-FIRST: a sibling row
  making a failure *repairable* (an installer that bootstraps the file) does not make the gate correct —
  CI cannot be fixed by documentation. · evidence: T-15, `01_REQUIREMENT_ANALYSIS.md` E-3 vs
  `.harness/rules/75-safety-hook.md:160-170`
- 2026-08-01 · An unanchored whole-file `grep` for a JSON **key** is silently vacuous when the same file
  documents itself: `settings.json.tmpl:5`'s `_guard_hook` doc string contains the bare token
  `PreToolUse`, so `grep -q 'PreToolUse'` passed with the **entire** `"PreToolUse": [...]` array deleted,
  in both shells, for as long as the check existed. Proved by running the *committed pre-change script*
  against the mutated artifact — it emitted no hook-block token at all. Anchor a key assertion to the
  key form (`"name"` + optional space + `:`), and prove it by mutating the artifact, never by inspecting
  the pattern. · evidence: T-15 QA E-6/E-8, `verify_all.sh:314` post-fix
- 2026-08-01 · On a working tree carrying uncommitted sibling work, "the frozen file is absent from
  `git diff --name-only`" is **not** a freeze proof — 37 files were already dirty, so the check could not
  pass regardless of what the task did. A dirty-set **difference** is not a sufficient substitute either:
  it is blind to a content edit inside a file that was *already* dirty. The sound substitute is the
  difference **plus** per-file mtime ordering against the task's first write. · evidence: T-15 S0 vs S11,
  `05_CODE_REVIEW.md` ruling 2
- 2026-08-01 · An anti-vacuity mutation that deletes a **container** falsifies every assertion whose
  evidence lives inside it: deleting the `"PreToolUse"` array also deletes the only `{{GUARD_COMMAND}}`
  (it sits at `settings.json.tmpl:54`, inside `:48-58`), so the mutation emitted two tokens where the
  architect and both gate rounds predicted one. The **check-level** prediction stayed right, which is
  exactly what makes the mis-prediction easy to miss. Check containment before predicting a
  single-token detail. · evidence: T-15 M3 run vs `02_SOLUTION_DESIGN.md:640-646`
