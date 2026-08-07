# 01 — Requirement Analysis — T-20 `harvest-wrapped-insight`

> Contract portion. Reasoning, evidence citations, option comparisons and open-question
> candidates are in `01_RATIONALE.md`.

Mode: `full`. Human channel: deferred — the open questions carry a binding `Recommended:` answer and
all seven are resolved; the rulings are recorded in `PM_LOG.md`.

Identifiers (`B-n`, `BC-n`, `AC-n`) are stable labels. A gap in a sequence is a withdrawn
identifier, never a missing row; withdrawn identifiers are not reused.

## Goal

`archive-task` discards every continuation line of a `## Insight` bullet that wraps, at exit 0
and with a console echo that reprints the truncated text as if it were complete; harvest,
rotation and the `I.4` cap check must agree on one entry boundary that preserves those lines,
and any line the harvester does not account for must be reported instead of dropped.

## Definitions

These names are used by every statement below and are binding.

- **Section** — for a delivery document, the lines after a `## Insight` / `## Insights` heading up
  to, but excluding, the next `##` heading or end of file. For the insight index, the whole file.
- **Entry-start line** — a line matching the form `^[[:space:]]*-[[:space:]]`. This is exactly the
  form `I.4` counts, unchanged by this task.
- **Continuation line** — a non-blank line that follows an entry-start line and is neither an
  entry-start line, a `##` heading, nor separated from it by a blank line.
- **Insight entry** — one entry-start line together with its continuation lines, in order. Its last
  line is the last of those lines.
- **Header block** (of the insight index) — the lines preceding the file's first entry-start line,
  extended forward through the end of any HTML comment that is open at that entry-start line. An
  entry-start line sitting inside a comment opened within the header block therefore does not end
  the header block.
- **Thematic break** — a line matching `^[[:space:]]{0,3}(-{3,}|\*{3,}|_{3,})[[:space:]]*$`. The
  spaced forms are excluded: `- - -` satisfies the entry-start predicate and is classified
  entry-start, visibly, in the family of BC-7.
- **Terminal footer** — of a *delivery document's* section only: the lines from the first thematic
  break that follows the last line of the section's **last** insight entry, through the end of that
  section. A section with no entry-start line has no terminal footer; a section whose only thematic
  breaks lie before the last line of its last entry has no terminal footer. The insight index has no
  terminal footer.
- **Ignorable line** — a line of the header block or of the section preamble; a blank line; or a
  line of a terminal footer.
- **Unaccounted line** — a non-blank line that is none of the above.

**Classification order.** Every line receives exactly one kind, by the first clause that matches:

1. the line is in the header block, or precedes the section's first entry-start line → **ignorable**;
2. the line is blank → **ignorable**;
3. the line is an entry-start line → **entry-start**;
4. the line is a continuation line → **continuation**;
5. the line is in a terminal footer → **ignorable**;
6. otherwise → **unaccounted**.

Clauses 3 and 4 are evaluated **before** clause 5. Consequence, and a binding property in its own
right, **scoped to clause 5**: the terminal-footer clause never makes an entry-start line or a
continuation line ignorable, at any position in any file, including after a thematic break — it can
only ever absorb lines that are neither an entry-start line nor a continuation of one.

This property does **not** extend to clause 1, which precedes clause 3: a line that satisfies the
entry-start predicate but lies inside the header block, or inside the section preamble, **is**
ignorable. That is required behavior, not an exception — the `Header block` definition, BC-24, B-19
and AC-16 all depend on it, because the shipped index template carries an entry-start-shaped example
line inside the HTML comment of its header block. Any statement that a predicate-matching line is
never ignorable is true only of the terminal-footer clause and false of the header block.

## In-scope behaviors

**B-1** — `archive-task` harvests insight entries from a delivery document's section, an entry being
the unit defined above.

**B-2** — Every line of a harvested entry reaches `.harness/insight-index.md` with its characters
preserved, including the leading whitespace of continuation lines.

**B-3** — Every line inside the section is classified as exactly one of entry-start, continuation,
ignorable, or unaccounted, by the classification order above. The classification is total: no line
falls through, and no line receives two kinds.

**B-4** — When the section contains at least one unaccounted line, `archive-task` emits a
diagnostic naming the delivery document, the 1-based line number and the line's text for each such
line, exits non-zero, and leaves the insight index, the insight history file and the task
directory byte-identical to their pre-run state.

**B-5** — The harvest echo prints every line of every harvested entry, and prints a per-run tally of
entries harvested, continuation lines harvested, ignorable lines skipped — with the terminal-footer
line count stated as its own figure — and unaccounted lines, so an echo that looks complete cannot
accompany discarded content.

**B-6** — The rotation cap is measured in entries, which is the quantity `I.4` counts. A
continuation line never counts toward the 30-entry cap. `I.4`'s count and `archive-task`'s count are
derived from the same classification of the same file, so one file never yields two entry counts.

**B-7** — Rotation moves whole entries: a rotated entry's entry-start line and all of its
continuation lines are written to `docs/features/_archived/insight-history.md` in order, and none
of them remains in the insight index.

**B-8** — An index rewrite preserves the header block verbatim and in position, and relocates no
line belonging to an entry into it.

**B-9** — After a rewrite the index contains the header block, then the retained entries in their
original relative order, then the newly harvested entries in their source order.

**B-10** — Reading the stored index applies the same entry boundary as B-1, so an already-stored
wrapped entry survives a later rotation intact.

**B-11 (bash)** — For a delivery document whose entries are all single physical lines, both the
append path and the rotation path produce an insight index and an insight history file
byte-identical to those the pre-change `archive-task.sh` produces. This floor is scoped to bash;
B-18 states what the PowerShell twin owes in its place. BC-23 is the one stated exception, and it is
an exit status, not file content.

**B-12** — The dry-run mode performs the same classification, reports the same four counts, writes
nothing, and returns the same exit status as the corresponding real run.

**B-13** — The bash and PowerShell twins produce byte-identical insight-index and insight-history
content for identical input.

**B-14** — `verify_all`'s `I.4` reports a non-PASS status when the insight index contains an
unaccounted line. `I.4` keeps its check id, keeps counting entries for the cap, and the total check
count stays 32 — no `step` / `Step` call is added or removed.

**B-15** — The repository and `skills/harness-init/templates/common/` copies of `archive-task.sh`
and `archive-task.ps1` stay byte-identical, so `sync-self --check` and `verify_all` E.1 pass.

**B-17** — Prose that states continuation lines are silently dropped, or that states the rotation
cap counts physical lines, is corrected to current behavior wherever this task ships the behavior it
describes: the agent contracts, the repository rule fragments and their template twins, and the
**header block** of `.harness/insight-index.md`. The "one physical line per insight" authoring
preference is not retired, and no entry line of the insight index is edited (AC-11).

**B-18** — The PowerShell twin's output floor is B-13, not B-11: for identical input its
post-change insight-index and insight-history content is byte-identical to the post-change bash
output. Its permitted differences from pre-change PowerShell output are exactly three — LF line
terminators with no BOM, leading whitespace preserved, trailing whitespace stripped. Any other
difference from pre-change PowerShell output is a defect.

**B-19** — This change introduces no new corruption in a generated project's shipped insight index.
Harvest and rotation over an index whose header block is the shipped template content leave that
header block intact and complete, including its HTML comment and the comment's example line, with no
line of it written into the insight history file.

**B-20** — In the insight index, the only ignorable lines are blank lines and the lines of the header
block. Any other line that is neither an entry-start line nor a continuation line is unaccounted, so
no entry-start line and no continuation line is dropped by a rewrite except the entries that rotation
moves out. Blank lines between stored entries belong to no entry and are not re-emitted: a rewrite is
shorter than its input by those blank lines in addition to the rotated-out entries, and no entry
content is lost. (Evidence: `06_TEST_REPORT.md` finding `QA-3`, reproducer `AT-14` — a
blank-separated index measured 62 lines before and 32 lines after one rotation.)

## Out-of-scope

1. The insight index's content policy, quality bar, deduplication or ordering. This is a transport
   defect.
2. `docs/proposals/frontier-gaps-2026-07.md` — not read, not cited, not edited, not committed.
3. Changing the 30-entry cap or any other numeric cap in the document-size policy.
4. Adding or removing a `verify_all` check; the count stays 32.
5. Retiring the "one physical line per insight" authoring instruction from agent contracts or
   templates (B-17 corrects only the false claims about dropping and about the counted quantity, not
   the preference).
6. Editing any **entry line** of `.harness/insight-index.md` — an entry-start line or a continuation
   line — other than by the rotation mechanism, and editing anything under
   `docs/features/_archived/`. The index's prose header block is not an entry line and is corrected
   by B-17.
7. Making the archive operation transactional across the index write and the directory move.
8. Executing PowerShell. The `.ps1` twin is green-by-symmetry and its run is an operator item.
9. Extending `/harness-upgrade` to refresh rule content (already declined —
   `upgrade-rule-content-refresh`).
10. Any change to how the section heading itself is matched: a suffixed heading such as
    `## Insight to surface` continues not to match.
11. **Two pre-existing distribution defects, withdrawn from this task and carried by a follow-up
    task**, neither of which this change creates:
    (a) the project-type template cap check corresponding to `I.4` counts physical lines rather than
    entries, and its label and message name a line count — it already reports non-PASS today in any
    generated project whose index reaches the cap, because the shipped index header alone is 9 lines;
    (b) `skills/harness-init/templates/common/.harness/insight-index.md.tmpl` ships a header sentence
    stating the cap in lines, and an example bullet inside its HTML comment that satisfies the
    entry-start predicate and so inflates any entry-start count by one. B-19 forbids this task from
    making (b) *worse*; repairing (b), and (a), belongs to the follow-up.
    This leaves one accepted asymmetry on the record: B-17 corrects the cap sentence in the dogfood
    index's header block, and the identical sentence in `insight-index.md.tmpl` stays untouched until
    the follow-up ships, because that file is edited once, for both of its defects, by the task that
    owns them.

## Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| BC-1 | No `## Insight` / `## Insights` heading | 0 entries, exit 0, index not written |
| BC-2 | Heading present, section empty | 0 entries, exit 0, index not written |
| BC-3 | Heading present, preamble prose only, no entry-start line | 0 entries, exit 0, index not written, 0 unaccounted lines |
| BC-4 | Preamble prose between the heading and the first entry-start line | ignorable; not harvested; counted and reported |
| BC-5 | Non-blank prose after the last entry, separated from it by a blank line, with no thematic break between the last entry's last line and it | unaccounted → B-4 refusal |
| BC-6 | A blank line inside an authored bullet | terminates that entry; the following non-blank lines are unaccounted → B-4 refusal |
| BC-7 | A continuation line whose text begins with a `- ` marker after optional leading whitespace | classified entry-start; it becomes its own entry and increments the reported entry count and `I.4`'s count identically |
| BC-8 | Delivery document with CRLF line endings | the carriage return is removed before classification and before write; no CR is written into the index |
| BC-9 | Trailing whitespace on a harvested line | removed; leading whitespace preserved (OQ-5) |
| BC-10 | Insight index file absent | created; it has an empty header block; harvested entries are written into it |
| BC-11 | Insight index containing zero entries | rotation does not fire; entries are appended |
| BC-12 | Entry total after harvest is exactly 30 | no rotation |
| BC-13 | Entry total after harvest is 31 | exactly one entry rotated, oldest first |
| BC-14 | Harvested entries alone exceed the cap, so the rotate count exceeds the number of stored entries | every stored entry rotates, no stored entry is read past the end, the run completes without an unbound-variable abort, and the index holds the harvested entries |
| BC-15 | `insight-history.md` absent | created with its header before the first rotation block |
| BC-16 | Task directory absent, or already archived | existing refusals unchanged: exit non-zero, nothing written |
| BC-17 | Entry of any line count | harvested whole; no per-entry length cap |
| BC-18 | Concurrent runs | unchanged single-process assumption; no locking added |
| BC-19 | Delivery document present but unreadable | exit non-zero before any write |
| BC-20 | Thematic break after the last entry's last line, followed only by blank lines and non-entry-start prose to the end of the section (the archived-corpus shape: `---` then a `**Verdict**:` footer) | terminal footer; every line of it ignorable; 0 unaccounted lines; exit 0; the entries before it harvested in full |
| BC-21 | Thematic break after an entry, separated from it by a blank line, with an entry-start line later in the same section | no terminal footer exists; the thematic break is unaccounted → B-4 refusal naming its line number and text; the post-break entry-start line and its continuations are classified entry-start / continuation and are never ignorable |
| BC-22 | Thematic break on the line immediately after an entry-start line or a continuation line, with no blank line between | continuation of that entry; harvested with it; preserved verbatim |
| BC-23 | `--dry-run` against a missing insight index | reports the classification and the counts, writes nothing, exits 0 — the same status as the corresponding real run (BC-10, B-12). The pre-change scripts exit 1 on this path; the change of status is stated in the delivery and is the one exception to B-11 |
| BC-24 | Index whose header block ends with an HTML comment containing an entry-start line (the shipped template shape) | the whole comment belongs to the header block; that line is not an entry; 0 entries from the header; no rotation moves any line of it (B-19) |

## Acceptance criteria

| id | criterion | verification |
|---|---|---|
| AC-1 | A section carrying one wrapped entry of ≥3 physical lines ending in an `· evidence:` pointer is harvested so the index gains exactly those lines with their characters preserved and the evidence pointer present | driver run + byte comparison of the index against the expected content |
| AC-2 | A section carrying an unaccounted line makes the run exit non-zero, name the document and the 1-based line number, and leave index, history and task directory byte-identical and mtime-unmoved | driver run + `cmp` + mtime comparison |
| AC-3 | For one index file, the entry count `archive-task` reports equals `I.4`'s count; a wrapped entry in the rotating position lands in the history file with all its lines and leaves zero lines behind in the index; and — the discriminating leg — a test-driver oracle compares, for an index fixture, the raw count of lines satisfying the entry-start predicate against the classified entry count reported for that same file: the two are equal on every index fixture whose header block holds no entry-start-shaped line, including AC-14's (raw 2, entries 2), with exactly one designed inequality, raw = entries + 1, on AC-16's shipped-template fixture. Over AC-14's fixture the raw count is 2 under every classification rule, so a rule that made post-break lines ignorable drives the classified count to 1 and turns the equality assertion red | rotation run over a fixture index containing a wrapped entry, then `I.4` over the result; then the driver-side raw-marker-against-classified-entry comparison over the AC-14 and AC-16 fixtures, asserting equality on the first and the stated inequality on the second |
| AC-4 (bash) | Over a delivery document whose entries are all single physical lines, post-change `archive-task.sh` output is byte-identical to pre-change output on both the append path and the rotation path | run the **committed pre-change** script, extracted from git to a scratch path, against the same fixtures and `cmp` the outputs — compared against the artifact, never derived arithmetically |
| AC-5 | `bash .harness/scripts/verify_all.sh` reports PASS 32 / WARN 0 / FAIL 0 and exits 0; every published check-count literal still reads 32 | captured run + grep of the count literals |
| AC-6 | `bash .harness/scripts/sync-self.sh --check` exits 0 with both `archive-task` copies changed | captured run |
| AC-7 | `I.4`'s new condition is non-vacuous: inserting an unaccounted line into a scratch copy of the index makes `I.4` non-PASS, and removing it restores PASS | mutation of the artifact, not inspection of the pattern |
| AC-8 | This task's own delivery exercises both harvest and rotation (the index is at 30 entries): afterwards the index has exactly 30 entries, and every rotated entry appears exactly once in the history file and zero times in the index | post-archive count + grep |
| AC-9 | The PowerShell surface is added to the standing operator list as **one** new numbered item covering a parse check over both `.ps1` copies and a run reproducing AC-1, AC-2, AC-3, AC-13 and B-18's byte-identity comparison against the post-change bash outputs; items 1-16 are neither renumbered nor reconciled | inspection of the operator list |
| AC-11 | No entry line of `.harness/insight-index.md` that existed before this task — entry-start or continuation — is edited or removed other than by the rotation mechanism. The file's prose header block is outside this criterion and is corrected under B-17 | diff of the index against its pre-task state, read per line kind |
| AC-12 | Insight entries authored during this task are single unwrapped physical lines until the fix is proven by AC-1 | inspection of this task's stage docs |
| AC-13 | **Discriminating fixture, delivery section.** A section of the shape: entry, blank, `---`, blank, entry-start line with one continuation line. The run exits non-zero, names the `---` line's 1-based number and text, writes nothing, and its tally reports the post-break entry-start line and its continuation as content — never as ignorable. A rule that classifies every line after a thematic break as ignorable exits 0 on this fixture and drops both lines with no diagnostic | driver case asserting exit status, diagnostic text, the per-kind tally, and byte-identity of all three artifacts |
| AC-14 | **Discriminating fixture, index.** An index of the shape: header block, entry, blank, `---`, blank, entry-start line with one continuation line. Every `archive-task` run over it refuses before writing and `I.4` reports non-PASS; after the refusal neither the post-break entry-start line nor its continuation has been removed from the index. A rule that classifies post-break lines as ignorable lets the run proceed and the rewrite delete both | driver case: run, assert exit status, `cmp` the index against its pre-run bytes, then `I.4` over the fixture |
| AC-15 | **Non-wedging floor.** The classifier reports 0 unaccounted lines for every `## Insight` section in `docs/features/_archived/**/07_DELIVERY.md` — all 34 that carry a matching heading, including the 3 whose sections end in a `---` + `**Verdict**:` footer | driver case walking the real archived corpus read-only, tally transcribed from the captured run |
| AC-16 | An index fixture whose header block is the shipped `insight-index.md.tmpl` content, driven through harvest and rotation, ends with that header block byte-identical and its HTML comment closed, and the history file contains no line of it | driver case + `cmp` of the header block region and grep of the history file |

## Non-functional requirements

**N-1 — Backward compatibility.** An index file, a history file and a delivery document written
before this change are all valid inputs. No migration step, no flag, no state.

**N-2 — Cross-shell parity.** B-13 is a hard requirement, not a symmetry claim: the two twins are
compared by byte-identity of their outputs, which is the standing failure family for this repo's
script pairs. B-11's pre/post regression floor is bash-only; B-18 carries the PowerShell side.

**N-3 — PowerShell honesty.** No PowerShell tally, parse result or run outcome is reported that an
agent did not execute; the `.ps1` twin ships green-by-symmetry with its obligations on the operator
list (AC-9).

**N-4 — Distribution.** The fix reaches generated projects through the template overlay; the
architect states which upgrade path carries it to already-generated projects. B-19 binds the fix in
those projects to be non-destructive against an index file that already exists on disk there, which
no template edit can achieve.

**N-5 — Performance and security.** Not material: the index is capped at 30 entries, delivery
documents are capped at 500 lines, no new process is spawned and no path outside the repository is
touched.

## Related tasks

- **T-15 `hook-truth-verify-scope`** (`docs/features/_archived/hook-truth-verify-scope/`) — the task
  whose four insights were truncated; its `07_DELIVERY.md` is the reproduction fixture and its
  `## Insight` section is the canonical wrapped shape.
- **T-009** — aligned `I.4` with `archive-task`'s rotation quantity in the dogfood copies; the
  governing lesson for this task's AC-3 and B-6, and the lineage of the follow-up in out-of-scope 11.
- **T-004** — the previous `archive-task` defect (`declare -a` under `set -u`), and the lesson to
  sweep sibling copies at the time of recording.
- **T-16 `hook-truth-derivation`** — the anti-vacuity discipline behind AC-7, the
  measure-a-matcher-per-tool discipline that constrains any regex change here, and the rule that a
  totality claim needs a fixture the rejected reading actually fails (AC-13, AC-14).
- **T-18 `stage-contract-split`** — shipped this document's contract/rationale structure and named
  T-20 as out of its own scope.

## Open questions

All seven are resolved; the rulings and their basis are in `PM_LOG.md`. Each line records the
analyst's recommendation and the adopted answer.

**OQ-1** — Does a blank line terminate an insight entry?
`Recommended:` yes. **Adopted** (PM): yes — this is what makes BC-5 and BC-6 detectable rather than
absorbed.

**OQ-2** — Which lever makes an unaccounted line detectable: a non-zero exit, a printed warning at
exit 0, or a `verify_all` assertion?
`Recommended:` a non-zero exit taken before any mutation, plus the B-14 `I.4` condition as a
standing second layer, no new check id. **Adopted** (PM): as recommended, with the non-wedging floor
added as a binding constraint — now discharged by the terminal-footer clause and measured by AC-15.

**OQ-3** — Does repairing the generated-project cap check stay in this task's scope?
`Recommended:` yes. **Adopted** (gate, reversing the PM's stage-1 ruling): no — the defect fires
today, before this task, so it is pre-existing and its repair is scope expansion. B-16 and AC-10 are
withdrawn; the work is out-of-scope 11 and is carried by a follow-up task.

**OQ-4** — What is the test surface: a new `test-archive-task.{sh,ps1}` pair, or fixtures folded
into an existing driver?
`Recommended:` a new pair. **Adopted** (PM): a new pair; the bash driver is executed and its tally
transcribed from that run into one new `baseline.json` key; the PowerShell twin is
green-by-symmetry under AC-9.

**OQ-5** — Is trailing whitespace on a harvested line stripped or preserved?
`Recommended:` stripped, with leading whitespace preserved. **Adopted** (PM): as recommended — this
is what makes B-13 achievable, and it is one of B-18's three permitted PowerShell differences.

**OQ-6** — The insight-index line recording this defect becomes partly false once it is fixed: edit
it in place, or supersede it with an appended line?
`Recommended:` append a superseding entry and leave the original unedited. **Adopted** (PM): as
recommended, per the append-only rule. This governs entry lines; the file's prose header block is
governed by B-17.

**OQ-7** — Does `archive-task` gain a flag to bypass the B-4 refusal?
`Recommended:` no. **Adopted** (PM): no — the escape is to correct the delivery document, and a
bypass flag reintroduces the silent path this task exists to remove.

## Verdict

`READY` — no open question stands. All seven are resolved.

Round 2 discharged the gate's X-1 and X-3 in this document: the `Ignorable line` definition is
re-authored around the terminal footer with the entry-start and continuation clauses evaluated ahead
of it, and B-16 / AC-10 are withdrawn to out-of-scope 11.

Round 3 discharges the two analyst-owned conditions of `APPROVED WITH CONDITIONS`, both text-only:
**X-6** qualifies the classification-order consequence to the terminal-footer clause and states the
header-block case it wrongly excluded, and **X-7** restates AC-3's third leg as the raw-marker /
classified-entry comparison the design performs. Neither changes a behavior, a boundary condition or
the scope, and neither requires an architect pass or re-gating. The round record is in
`01_RATIONALE.md`.
