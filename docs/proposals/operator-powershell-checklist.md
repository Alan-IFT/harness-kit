# Operator PowerShell verification — consolidated checklist

> Assembled 2026-08-02 by the `/harness-stream` operator from the five `_qa_note_*`
> values in `.harness/scripts/baseline.json`. **This document is a convenience index,
> not a new source of truth** — each item's full acceptance detail lives in those notes,
> and where this summary and a note disagree, the note wins.

> ⚠️ **This document is itself an instance of the problem it describes, and it drifted
> within a day of being written.** The entropy sweep run hours after it was created
> (finding EP-002, `docs/features/_supervision/entropy-2026-08-02.md`) caught two errors
> in the first draft: the obligation count was given as 17 when it is **25**, and the
> `_qa_note_t13` row read that note's *local* indices as if they were global item numbers,
> which silently dropped 8 obligations. Both are corrected below.
>
> The lesson is not "be more careful with the copy" — it is that a second home for a fact
> drifts from the first no matter how carefully the copy is made. Treat this file as a
> disposable reading aid for one operator session, and fix the underlying problem by giving
> these obligations a real home rather than by maintaining this index.

## Why this exists

`pwsh` is not installed on the development host (`command -v pwsh` fails). Every `.ps1`
edit across the last eight delivered rows is therefore **green-by-symmetry only** — the
bash twin was executed and proven, the PowerShell twin was reasoned about. No agent in
this project can execute PowerShell.

That distinction is not academic. A prior release shipped two PowerShell files that were
both parse-broken and runtime-broken on Windows; only an operator run caught them. The
failure modes were:

1. **A syntax error in a never-taken branch is fatal to the whole file** — PowerShell
   parses before executing, so a broken `else` that never runs still prevents the script
   from loading at all.
2. **A parameter named like a read-only automatic variable throws on first call** —
   `$isWindows` collides with the built-in `$IsWindows` (names are case-insensitive).
3. **The bash literal idiom does not port** — embedding `\"` plus an un-interpolated
   `$VAR` needs a single-quoted PowerShell string or the `-f` format operator, never
   double-quote concatenation.

None of these are visible to a bash-only run or to review by inspection.

## Standing count

**25 release-gating obligations: 17 numbered, plus 8 un-numbered inside `_qa_note_t13`.**
4 are marked security-relevant. They accumulated one wave at a time; the numbering is
continuous across tasks and must not be renumbered.

> ⚠️ **A second correction, 2026-08-02 — one obligation has been missing from the operator's
> copy since it was written.** T-24's gate stage found that `_qa_note_t13` is a **mirror** of a
> 1–8 enumeration in `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289`, and the
> mirror **dropped item 5** — *AC-10 cross-shell byte-identity of the generated
> `settings.local.json` and pre-commit hook* — while splitting item 3's reconcile tail into the
> vacated ordinal. Independently verified: the source enumerates it at position 5; the mirror
> contains the strings `AC-10` and `byte-identic` **zero times**.
>
> **The count stayed at 8 because a split compensated for a drop, so no count-based check could
> ever have caught it** — including the count I corrected above. The source states items 1, 2, 4,
> 5 and 7 are "unchanged and still binding", so **item 5 is in force and has simply never reached
> you**. Total remains 25; one of them was invisible until now. Read the source enumeration, not
> this file and not the mirror.

The 17-vs-25 split is the trap. `_qa_note_t13` carries its **own** internal sequence of 8
obligations — its text says "EIGHTH BINDING OPERATOR CHECK" and "this adds NO ninth item —
it widens items 3, 6 and 8". Those indices are local to that note. Reading them as global
item numbers is what dropped 8 obligations from this document's first draft. **Read
`_qa_note_t13` in full; its contents are not reachable through the numbered list.**

| Origin | Items | Notes |
|---|---|---|
| `_qa_note_t12` | 1–11 (established) | The wave that proved an operator run is mandatory, not optional |
| `_qa_note_t13` | **8 un-numbered, local 1–8** | Parse sweep, settings-bootstrap run, two binding code-review checks, a four-distinct-events gate, and a second anti-revert row. Its "3, 6, 8" are its own indices, not global ones. |
| `_qa_note_t16` | 12–16 | Two security-relevant; raises the security-marked count from 2 to 4 |
| `_qa_note_t17` | (folded) | Guard scanner surface — `guard-rm.ps1`, `test-guard-rm.ps1` |
| `_qa_note_t20` | 17 | Archive-task surface |

## Execution order

Run in this order. A parse failure anywhere makes every later run meaningless, so the
sweep comes first.

### Phase 1 — parse everything before running anything

```powershell
$files = @(
  '.harness/scripts/hook-spec.ps1',
  '.harness/scripts/install-hooks.ps1',
  '.harness/scripts/upgrade-project.ps1',
  '.harness/scripts/migrate-scripts-layout.ps1',
  '.harness/scripts/guard-rm.ps1',
  '.harness/scripts/archive-task.ps1',
  '.harness/scripts/sync-self.ps1',
  '.harness/scripts/verify_all.ps1',
  '.harness/scripts/test-init.ps1',
  '.harness/scripts/test-real-project.ps1',
  '.harness/scripts/test-guard-rm.ps1',
  '.harness/scripts/test-archive-task.ps1'
)
# plus each templates/common/.harness/scripts/ twin of the above that exists
foreach ($f in $files) {
  $errs = $null
  [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path $f), [ref]$null, [ref]$errs) > $null
  if ($errs) { Write-Host "PARSE FAIL: $f"; $errs }
}
```

Expect zero output. Any parse error blocks everything downstream.

### Phase 2 — the security-relevant items first

Four items are marked security-relevant. Two of them verify that the destructive-command
guard actually blocks on Windows — if that is broken, Windows users of the published
plugin have a guard that silently does nothing.

- **Guard scanner** — run `test-guard-rm.ps1`, expect **87 rows**, then pin
  `test_guard_rm_ps_assertions` **from that run** (the key is deliberately absent today
  because no real tally exists). The run must include the two probes
  `& rm -rf C:\x` and `pwsh -c "& Remove-Item -Recurse C:\Windows"`, both expecting exit 2.
- **Upgrade-repair and layout-migration flows** — parse both copies of each, then confirm
  on a brittle fixture that all eight written command values are byte-equal to the
  pre-change output, and that deleting the spec produces no settings write and a
  non-zero exit rather than a silent partial.
- **Runtime guard proof** — from the settings file the flow actually wrote, extract the
  pre-tool hook command and pipe a destructive out-of-project command into it. It must
  block.

### Phase 3 — drivers, and the trap in reading their output

```powershell
pwsh -File .harness/scripts/verify_all.ps1        # expect PASS 32 / WARN 0 / FAIL 0
pwsh -File .harness/scripts/test-init.ps1         # must REACH '=== Result ==='
pwsh -File .harness/scripts/test-archive-task.ps1 # must REACH its summary block
pwsh -File .harness/scripts/test-real-project.ps1
```

**A run that terminates without printing its own summary line is a FAILURE, not a pass.**
This repo has been bitten by exactly that: a driver was truncated mid-run by a quoting
defect, printed no summary, and was recorded as green. Check for the summary line
explicitly; do not infer success from the absence of an error.

Note also that `verify_all.ps1` hard-parses the local settings file with
`ConvertFrom-Json`, while the bash twin only greps it — a file that is byte-valid to bash
can still fail there.

### Phase 4 — reconcile the pinned counts

Two keys are deliberately unreconciled and must be set from real runs, not arithmetic:

- `test_init_ps_assertions` is frozen at **316**; both README `test--init` badges are
  frozen with it. Move the count and the badges **together**.
- `test_guard_rm_ps_assertions` and `test_archive_task_ps_assertions` do not exist yet —
  create them from the runs in Phase 2 and 3.

This repo has twice caught a tally that no run produced. Transcribe from captured output.

## A structural note

Seventeen items that gate a release currently live as prose inside string values in a
JSON file whose stated job is pinning numeric baselines — 24,874 characters of it. That
file is machine-read; this checklist is human-executed. They should not be the same file.

This is the same defect class the hook-wiring wave spent four rows eliminating: a fact
with no single home, reproduced wherever someone needed it. Worth a row of its own, but
not one this stream invented on its own authority.
