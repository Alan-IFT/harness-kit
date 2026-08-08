# 01 — Requirement Analysis: operator-obligation-home (T-24)

> Contract portion. Mode: **full** · deferred-human: defer, do not ask ·
> Rationale sibling: `01_RATIONALE.md` (option arguments, open-question candidate answers, the
> argument selecting among them).
> Origin: **EP-002** in `docs/features/_supervision/entropy-2026-08-02.md` (sweep-authored input,
> read-only). Primary deliverable: **one location** the release-gating operator obligations are
> read, counted and executed from.

---

## 0. Established facts (backward-looking evidence)

Path-and-line citations in this section are **evidence of what was found**, per the analyst's
EVIDENCE-citation exemption. No requirement statement below §0 anchors to a path or a line, except
where it names an artifact that exists today.

### 0.1 What the set is, and where each part of it lives

| id | Established fact | Evidence |
|---|---|---|
| E-1 | **25** obligations gate a release: **17** carrying global integers 1–17, plus **8** that carry no global integer and are enumerated 1–8 in an archived developer stage document. Re-derived here from the enumerating sources rather than inherited: 10 (T-17) + 1 (T-15) + 5 (T-16) + 1 (T-20) = 17 global, plus 8 = **25**. | `_archived/guard-cmd-chain/04_DEVELOPMENT.md:467-492`, `:830-838`, `:1230-1238`; `_archived/hook-truth-verify-scope/04_DEVELOPMENT.md:659` ("the eight T-13 items and the ten T-17 items"), `:662-676`; `baseline.json:_qa_note_t16` ("FIVE NEW NUMBERED … ITEMS (12-16) … 19 -> 24"), `:_qa_note_t20` ("ONE NEW NUMBERED … ITEM (17)"); `_archived/hook-truth-spec/04_DEVELOPMENT.md:255-289` ("**Eighth and last — no ninth**"), `07_DELIVERY.md:72` ("**Eight binding operator items**") |
| E-2 | The pin file carries **23** keys on `:2-24` — 19 numeric pins plus 4 string metadata fields — and **five** `_qa_note_t{20,17,13,16,12}` string values on `:25-29`. | `.harness/scripts/baseline.json`, re-read key by key for this document |
| E-3 | Upstream measures that prose at **24,874 characters**; not re-measured here (this stage has no shell). | `docs/proposals/operator-powershell-checklist.md:145`; `docs/features/_supervision/entropy-2026-08-02.md:49` |
| E-4 | **Items 1–11 are not in the pin file at all.** Items 1–10 live in an archived *developer* stage document, spread across three round sections; item 11's full five-leg text is a blockquote in a second task's archived *developer* stage document, and that task's archived delivery document only *names* it. | `_archived/guard-cmd-chain/04_DEVELOPMENT.md:459`, `:824`, `:1224`; `_archived/hook-truth-verify-scope/04_DEVELOPMENT.md:662-676`; `07_DELIVERY.md:122` |
| E-5 | That split was already established once, by a prior architect, and recorded with the same two sources. | `_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md:1061-1064` |
| E-6 | Assembling the set requires **seven source spans across four files**: three archived developer stage documents — ids 1–10, id 11, and the 1–8 enumeration of the eight — plus four `_qa_note_*` values inside the pin file — ids 12–16, id 17, a partial restatement of the guard-surface obligations, and a **mirror** of the 1–8 enumeration. None of the seven is a list of the set, and for the eight the enumerating span and the mirror are two different spans that do not agree (E-28). | `_archived/guard-cmd-chain/04_DEVELOPMENT.md`, `_archived/hook-truth-verify-scope/04_DEVELOPMENT.md`, `_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289`; `baseline.json:_qa_note_t16`, `:_qa_note_t20`, `:_qa_note_t17`, `:_qa_note_t13` |
| E-28 | The note that travels to the operator is a **lossy** mirror of that enumeration. It **dropped** enumeration item 5 (cross-shell byte-identity of the generated local-settings file and the generated pre-commit hook, byte-compared against the bash twin's output on the same host) and **split** item 3's reconcile tail into the vacated ordinal, so its count stayed at eight while its membership changed. The dropped item is recorded as still binding, and nothing ever adjudicated the omission. *(Id appended out of sequence deliberately: renumbering E-1…E-27 would break citations already made by `02` and `03`.)* | `_archived/hook-truth-spec/07_DELIVERY.md:72` ("mirrored into `baseline.json:_qa_note_t13`"), `04_DEVELOPMENT.md:264-266` vs `baseline.json:_qa_note_t13`; `04_DEVELOPMENT.md:452-453` ("Items 1, 2, 4, 5, 7 are unchanged and still binding"); `baseline.json:_qa_note_t20` ("NOT renumbered, reconciled, re-read or edited") |
| E-29 | The enumeration's ordinals are the ones its own text cross-references: the rework-3 widening is recorded as widening items **3, 6 and 8** in the enumerating document itself, and the mirror repeats the same three ordinals. The widening resolves under the enumerating source's numbering. | `_archived/hook-truth-spec/04_DEVELOPMENT.md:444-453`; `baseline.json:_qa_note_t13` ("this adds NO ninth item - it widens items 3, 6 and 8") |
| E-7 | `_qa_note_t12` carries **no obligation**. It is a historical record of the 2026-06-21 operator run. | `.harness/scripts/baseline.json:29` |
| E-8 | The four other notes **interleave** obligations with QA measurement records, pin-writing constraints ("transcribed, never derived"; "do NOT re-baseline upward"; "there is deliberately NO `test_archive_task_ps_assertions` key"), and an archive correction — inside single JSON string values. | `baseline.json:25-28` |
| E-9 | Items 1–10 carry a known internal inconsistency: item 2 states 81 rows / `PASS: 81` where item 9 states 87. The delivery document rules **87 correct** and records that QA could not repair it because it lives in the developer's stage document. | `_archived/guard-cmd-chain/07_DELIVERY.md:118-120` |
| E-10 | The numbering accumulated one wave at a time (10 → 11 → 16 → 17) and is cited **by number** across archived delivery, review and test documents. | `_archived/guard-cmd-chain/06_TEST_REPORT.md:619`; `_archived/hook-truth-verify-scope/07_DELIVERY.md:122`; `_archived/harvest-wrapped-insight/07_DELIVERY.md:47`; `_archived/stage-contract-split/04_DEVELOPMENT.md:90` |
| E-11 | Nothing records discharge, and discharge is **re-armable**: items 14(a)/15(a)/16 are marked *mandatory re-runs* against later bytes, so an obligation satisfied once is re-opened by a later edit to its artifact. | `baseline.json:_qa_note_t16`; `_archived/hook-truth-derivation/07_DELIVERY.md` (T-16 row, `docs/tasks.md:19`) |
| E-12 | 4 of the 25 are security-relevant. | `baseline.json:_qa_note_t16` ("its security-marked count from 2 to 4") |

### 0.2 Why a second copy is not the answer

| id | Established fact | Evidence |
|---|---|---|
| E-13 | A convenience index was authored to make the set executable and **drifted within one day**: it reported 17 obligations where there are 25, by reading one note's local indices as global item numbers. | `docs/proposals/operator-powershell-checklist.md:8-18`, `:44-52` |
| E-14 | That index is wrong in a **third** way it does not know about: its origin table attributes items "1–11 (established)" to `_qa_note_t12`, which contains no numbered list (E-7). | `docs/proposals/operator-powershell-checklist.md:56` vs `baseline.json:29` |
| E-15 | It declares itself subordinate — "a convenience index, not a new source of truth … where this summary and a note disagree, the note wins" — which is a statement of two authorities, not a resolution of them. | `docs/proposals/operator-powershell-checklist.md:4-6` |
| E-16 | Its own closing section reaches the relocation conclusion unprompted and declines to act on it. | `docs/proposals/operator-powershell-checklist.md:142-150` |
| E-17 | The four preceding rows closed this class by **relocating the fact**, not by indexing it: the hook-wiring wave gave the byte-forms one home, and T-23 gave the persist duty one owner. Both are recorded as delivered. | `docs/tasks.md:15,17,19,23,24` |

### 0.3 Consumers of the pin file (audit set — derived by reading, not certified total)

| Consumer | How it touches the file | Effect of removing obligation prose |
|---|---|---|
| `verify_all.sh:852` / `verify_all.ps1:785` (G.4 row 11) | whole-file substring test for `"verify_all_checks": <n>` | none — the numeric span is untouched |
| `agents/qa-tester.md:28,83,88,155` | reads for current counts, writes counts back, forbids downward edits | none — the keys stay |
| `upgrade-project.{sh,ps1}:195/:198`, `migrate-scripts-layout.{sh,ps1}:56/:129` | names it as a **relocate-only data file**; never parsed | none |
| `test-init.{sh,ps1}`, `test-harness-upgrade.{sh,ps1}` | synthesize their own `{"test_count":0}` fixture; never read the live file | none |
| `skills/harness-status/SKILL.md:96,118`, `harness-adopt:192,329`, `harness-init:422,495` | presence / creation / print-if-exists | none |
| `templates/**/verify_all.{sh,ps1}.tmpl` | read a **generated project's** baseline, a different file | none |

**Search form, stated because a totality claim depends on it:** this audit came from the `Grep`
tool (ripgrep-backed) over the repository with the pattern `baseline\.json|_qa_note`, and its
results **did** include paths under `.harness/`, so this invocation was not dot-blind. The set is
nonetheless **not certified total**: a plain-pattern ripgrep skips dot-directories by default
(`.harness/insight-index.md`, 2026-08-02 entry), and no stage before stage 4 can execute anything.
Re-derivation with an explicitly hidden-inclusive search, plus execution, is a named residual (§5
AC-7).

### 0.4 Constraints measured at dispatch

| id | Constraint | Evidence |
|---|---|---|
| E-18 | Gate baseline: `verify_all` bash **PASS 32 / WARN 0 / FAIL 0**; the check count stays **32**. | `docs/features/operator-obligation-home/PM_LOG.md:6`; dispatch |
| E-19 | `verify_all` exits **1** on `warns > 0`, so any document-size WARN is a hard release-gate failure, not advisory. | `.harness/insight-index.md` (2026-08-01 entry); `verify_all.sh:823-825` |
| E-20 | Only five paths carry a gated size cap: `AI-GUIDE.md` (I.1), `.harness/rules/*.md` at depth 1 (I.2), `agents/*.md` at depth 1 (I.3), `.harness/insight-index.md` (I.4), `docs/tasks.md` (I.5). No `I.*` check measures any other path. | `verify_all.sh:421-459`, `:461-556` |
| E-21 | Current counts: `AI-GUIDE.md` **114**/200; `.harness/rules/40-locations.md` **52**/200; `.harness/rules/70-doc-size.md` **175**/200; `agents/qa-tester.md` **157**/300; `agents/pm-orchestrator.md` **296**/300 — four lines of headroom. | line counts read from each file |
| E-22 | E.1 ("Layer 1") delegates to `sync-self --check`, a mapping over eight named script pairs — it is **not** a tree comparison of `.harness/`, so a new non-script file at `.harness/` root is not compared against `templates/common/`. | `verify_all.sh:194-198`; `AI-GUIDE.md:76` |
| E-23 | E.4b indexes `AI-GUIDE.md` ↔ `.harness/rules/*.md` in **both** directions. | `verify_all.sh:255-257` |
| E-24 | I.6 (retired-claim guard) exempts the whole `docs/features/` subtree and five history-bearing files; **every other tracked document is scanned**, at FAIL severity. | `verify_all.sh:635-679` |
| E-25 | `pwsh` is not installed on this host and PowerShell is not executable by any agent here; every `.ps1` in the tree ships green-by-symmetry only. | `baseline.json:_qa_note_t16,_qa_note_t17,_qa_note_t20`; `docs/proposals/operator-powershell-checklist.md:22-25` |
| E-26 | A standalone open/fixed findings store was **declined** on the ground that the state was re-derived each run by construction. | `.harness/rejected-decisions.md` `## entropy-findings-store` |
| E-27 | A duty survives when it travels **in band with the payload** — a writer holding only the in-band header produced a byte-identical result to one holding the full duty block. | `.harness/insight-index.md` (2026-08-02 entry, T-23 AC-8) |

---

## 1. Goal

Give the 25 release-gating operator obligations a single location that is meant to hold them, so
the set is read, counted and executed from that one location without reconstruction, and no second
copy is needed to make it usable.

---

## 2. In-scope behaviors

The single location is called the **obligation ledger** below. Its path is OQ-1.

**R-1 · One home.** The obligation ledger holds every release-gating operator obligation and is the
only document any reader is sent to for the current set. After this task no obligation text remains
in the numeric-pin file, and no document this task is permitted to edit restates an obligation's
content. One live document lies outside that permission — the operator-authored convenience index
under `docs/proposals/`, which restates obligation content and which this pipeline neither edits
nor deletes (§3.2). R-1 is therefore satisfied by **authority and permission**, not by the absence
of every copy: the delivery names that document as the one live restatement left standing, states
that it is subordinate to the ledger, and records its removal as an operator action.

**R-2 · Completeness.** The ledger carries all 25 obligations in force at dispatch: the 17 that
carry global integers and the 8 that carry no global integer and are enumerated 1–8 in an archived
developer stage document (E-1, E-6). The 8 are taken from that enumeration, never from the note
value that mirrors it. Where mirror and enumeration diverge, the enumeration governs (R-4), and the
delivery states to the operator **which** of the eight the travelling note has not carried since
T-13, citing the enumerating source, so the operator can act on it with the evidence in hand
(E-28). No obligation is retired by this task.

**R-3 · Self-contained entries.** Each ledger entry states, without opening any other document:
its id; the action to perform; the artifact path or paths the action applies to; the observable
that constitutes a pass; whether it is security-relevant; its origin task; and its discharge
record.

**R-4 · Transcription is lossless, and a mirror never narrows an enumeration.** Each entry
preserves every artifact path, expected figure, expected exit code, and cited insight date present
in its source text. An entry is never a summary or a paraphrase of its source. Where one obligation
is stated in more than one source, the entry carries the **union** of what those sources state; on
a conflict the source that enumerates the set governs, and the divergence is recorded in the entry.
R-5 applies to that union, so a figure superseded inside it is dropped as superseded while a source
is never dropped as redundant — the two operations stay distinct. Deriving an entry from a mirror
when an enumerating source exists is a defect of the same severity as losing an obligation.

**R-5 · Current state, not round history.** Where a source amends an earlier statement of the same
obligation, the ledger carries the amended statement only and cites the document that made the
amendment. A superseded figure is not restated. Item 2's `81` is superseded by `87` (E-9).

**R-6 · No renumbering.** Ids 1–17 keep their integers and their assignments. The 8 obligations
carrying no global integer keep the ordinals their **enumerating** source assigns them — not the
ordinals the mirror assigns — and gain an origin qualifier that makes each one addressable. No
obligation is merged with another, split, reordered, reissued or dropped; restoring an ordinal the
mirror vacated is not a renumbering, because the enumerating source never moved it.

**R-7 · The count is derived, not claimed.** The ledger states no standalone total. The count is
obtained by counting ledger entries, and the ledger publishes the exact one-line command that does
it.

**R-8 · Discharge is recorded per entry and is re-armable.** Each entry carries a discharge field
whose value is either `never` or a date together with the artifact state the run was performed
against. No entry carries a boolean open/closed state, because a later edit to the artifact
re-opens a discharged obligation (E-11).

**R-9 · The pin file says, in band, that obligations are not written there.** The numeric-pin file
carries one statement, encountered by anyone editing that file, that it pins numeric baselines only
and that a standing operator obligation is written in the ledger.

**R-10 · The writing stage is told where to write.** Every agent contract that names the numeric-pin
file as an output of its own stage also names the ledger as the destination for a standing operator
obligation, and states that an obligation is appended with the next unused id and never renumbers
an existing one.

**R-11 · Lookup.** The project's file-location lookup table and the project index's memory-layer
list each carry one line naming the ledger and what it holds.

**R-12 · What stays in the pin file.** A unit in a `_qa_note_*` value **stays** when it constrains
how a key in that same file is next written — a transcribe-don't-derive instruction, a floor that
must not be raised, a key deliberately left absent. It **moves** when it states an action a human
must perform before a release is safe. A unit that is neither — the historical narrative of a
completed task, which already has a permanent home in that task's archived stage documents — is
left byte-unchanged by this task.

**R-13 · The excision leaves the pin file valid and its numbers untouched.** Every numeric key keeps
its name, its position and its value; the file parses as JSON; the excised span is replaced by a
clause that names the ledger and carries no obligation content.

**R-14 · The declined gate is recorded.** The declined-options memory gains one record naming the
release-gate check that was **not** added, why, and the condition that would re-open the question.

**R-15 · Documentation sync.** Every document that describes where this project's parts live, or
that a rule change touches, is updated per the project's documentation rules — one line each, no
restatement of ledger content.

**R-16 · No new gate.** No check is added to, or removed from, the release gate; the check count
stays 32.

**R-17 · No PowerShell surface.** If this task creates any `.ps1` file, the ledger gains appended
entries for it and renumbers nothing.

---

## 3. Out-of-scope

1. **Discharging any obligation.** That needs a Windows host and is the operator's act.
2. Editing `docs/features/_supervision/*.md` or `docs/proposals/*.md` — including the drifted
   convenience index, which this task neither corrects nor deletes. Editing or deleting an
   operator-authored document is not this pipeline's act; R-1 is scoped to match, and the delivery
   surfaces the residual copy rather than resolving it.
3. Editing any archived stage document. The archive is a frozen historical record: nothing updates
   it and no reader is sent to it for current state, so it is not a second authority.
4. The other entropy findings — EP-001 shipped in the preceding row, EP-003 remains queued.
5. Distributing the ledger: no template twin, no `sync-self` mapping, no `test-init` assertion, no
   generated-project surface. The obligations are this repository's own PowerShell debt.
6. Pruning the historical narrative that R-12 leaves in the pin file.
7. Adding a `verify_all` check, a script, or a script pair.
8. Renumbering, merging, splitting or rewriting the content of any obligation.
9. Changing any numeric pin value.
10. Adding the ledger to any always-read path — no agent is instructed to read it at task start.

---

## 4. Boundary conditions

**B-1 · Empty.** A ledger with zero entries is a valid document and the published count command
yields `0`.

**B-2 · Source text not locatable.** If an id's source text cannot be located, the entry still
exists, states the id, names the document consulted, and records `text not located` in its action
field. The delivery states how many such entries exist. An id is never omitted for want of text.

**B-3 · Append.** A 26th obligation is added by appending one entry with the next unused integer
id; no existing entry changes.

**B-4 · Reuse.** An id is never reused, including after the obligation is discharged.

**B-5 · Concurrency.** The ledger is shared metadata. Appends are serialized by the orchestrator at
a stage boundary, exactly as `.harness/insight-index.md` and `docs/tasks.md` already are; a
parallel worker never writes it directly.

**B-6 · Stale discharge.** When an obligation's artifact is edited after a discharge was recorded,
the artifact-state component of the discharge field is what makes the record stale. A reader treats
a discharge recorded against a different artifact state as **not** discharged.

**B-7 · Malformed JSON.** The excision leaves the pin file parseable; a trailing comma, an
unterminated string or an unescaped quote breaks every JSON consumer of the file at once.

**B-8 · Retired-claim guard.** The ledger sits outside every I.6 exemption (E-24), so transcribed
obligation text that reproduces a banned anchor sequence fails the gate at FAIL severity.

**B-9 · Rules-index guard.** The line added to the project index must not contain a
`.harness/rules/` path, or the both-directions rules index (E-23) reads it as a rule fragment and
fails.

**B-10 · Count-claim guard.** No line added to any document that the count-claim check reads may
contain a check-count-shaped token, and the obligation count is stated in no such document — a
twelfth restatement of a leaking number is the defect EP-003 already names.

**B-11 · Maximum size.** The ledger carries no gated cap (E-20) and no rotation. Growth is one
entry per delivered task that creates a PowerShell surface.

**B-12 · Absence.** No script reads the ledger, so its absence breaks no execution path — the
contrast with the pin file, whose absence is observable to six consumers (§0.3), is deliberate.

**B-13 · Security markings.** Losing a security marking in transcription is a defect of the same
severity as losing an obligation.

---

## 5. Acceptance criteria

| id | Criterion | Verified by |
|---|---|---|
| **AC-1** | Every one of the 25 obligations appears in the ledger under a unique id, and a search of the pin file for each obligation's fingerprint tokens returns zero hits. The same search over the tracked live tree returns hits only in the ledger and in the out-of-scope index of AC-13; any further live restatement it finds is named in the delivery under R-1. | search over both files and over the tracked live tree, form stated |
| **AC-2** | Every ledger entry carries all seven fields of R-3 non-empty. The number of entries whose action field reads `text not located` is stated in the delivery, not left to be inferred. | per-entry field check |
| **AC-3** | Ids 1–17 appear exactly once each and none is reassigned; 8 entries carry the ordinals 1–8 in order under an origin qualifier, taken from the **enumerating** source and not from the mirror; the id sequence differs from the enumerating sources only by the addition of that qualifier. | id-set comparison against each of the seven source spans of E-6, naming which span enumerates each id block — plus, for each of the eight ordinals, a stated verdict of whether the mirror **matches**, **differs from** or is **silent on** the enumeration. A comparison performed against a mirror does not discharge this criterion. |
| **AC-4** | Running the command the ledger publishes over the ledger yields **25**, and no line of the ledger states a total. The delivery names which of the eight the travelling note has not carried since T-13, cites the enumerating source for it, and states that this task retires nothing. | execution + search + delivery read |
| **AC-5** | For each moved obligation, every artifact path, numeric expectation, exit code and cited insight date in **every** source span stating it appears in the ledger entry — the union of R-4, so text carried only by the mirror survives as well as text carried only by the enumeration. QA derives the token set **independently** from the sources, not from the developer's list. | independent re-derivation over every span AC-3 names |
| **AC-6** | `verify_all` bash reports **PASS 32 / WARN 0 / FAIL 0**, exit 0, with the check count read from the run and unchanged at 32. | execution |
| **AC-7** | No consumer of the pin file breaks, proven by execution: the file parses as JSON; G.4 PASSes; `sync-self --check` exits 0; `test-init`, `test-real-project`, `test-supervisor`, `test-verify-i6`, `test-harness-upgrade`, `test-language`, `test-guard-rm` and `test-archive-task` each report their pinned tally. The consumer set is re-derived with a hidden-inclusive search and the search form is stated. | execution |
| **AC-8** | Every numeric key in the pin file keeps its name, its position and its value. | byte comparison of the numeric span |
| **AC-9** | The pin file carries the in-band statement of R-9, and every agent contract that names the pin file as an output also names the ledger. | read every `agents/*.md` for the pin file's name; each hit's contract also names the ledger |
| **AC-10** | Post-change line counts are stated for every capped file touched and each is under its cap; `agents/pm-orchestrator.md` is byte-unchanged at 296 lines. | `wc -l` per file + digest |
| **AC-11** | No check added or removed, no script added, no `.ps1` created, no version stamp moved. | change-set inspection + G.3/G.4 |
| **AC-12** | The declined-options memory carries one record for the un-added gate, naming its re-surface condition. | read |
| **AC-13** | The drifted convenience index is neither edited nor deleted, and the ledger cites no count from it. The delivery names it as the one live restatement left standing, states that it is subordinate to the ledger, and records its removal as an operator action (R-1). | change-set inspection + search of the ledger for that path + delivery read |

---

## 6. Non-functional requirements

**NFR-1 · Context budget.** The ledger is not on any always-read path; the project index carries a
pointer line only. The prose remaining in the pin file after R-12 is not enlarged, so the cost every
consumer of the 19 numeric pins pays does not grow.

**NFR-2 · Compatibility.** The pin file stays valid JSON with its numeric keys byte-preserved
(AC-8). Nothing in this task changes the shape any script reads.

**NFR-3 · Security.** 4 of the 25 obligations are security-relevant (E-12); the marking survives
transcription (B-13). Two of them verify that the destructive-command guard blocks on Windows, so a
lost marking is a lost guarantee about published behavior.

**NFR-4 · Honesty of figures.** No figure in the ledger is derived arithmetically; each is
transcribed from the source that states it. This is the standing rule the pin file's own notes
already impose on their keys.

**NFR-5 · PowerShell.** Nothing in this task is executed under PowerShell (E-25). Any `.ps1`
touched ships green-by-symmetry only and is handled by R-17.

---

## 7. Related tasks

| Task | Why it bears on this row |
|---|---|
| **T-23 `review-write-path`** (`docs/features/_archived/review-write-path/`) | The immediately preceding row and the sibling entropy finding EP-001. Closed a two-authority defect by naming one owner rather than adding capability; its AC-12 is where the count 25 (17 + 8) is last certified. |
| **T-13 / T-16 / T-12 / T-20** (`docs/tasks.md:17,19,23,24`) | The four-row wave that eliminated hand-synchronised copies by giving the fact one home (`hook-spec`). The precedent this row is asked to follow. **T-13 `hook-truth-spec` additionally owns the enumeration of the eight** — its archived developer stage document is their enumerating source and its delivery is what identifies the note as a mirror (E-6, E-28). |
| **T-17 `guard-cmd-chain`**, **T-15 `hook-truth-verify-scope`** | The origin tasks of obligations 1–10 and 11 respectively; their archived developer stage documents are the only source of that text (E-4). |
| **T-11c `entropy-watch-persist`** | Declined a standalone open/fixed findings store (E-26). The nearest prior decline to R-8 and answered in OQ-3. |
| **T-18 `stage-contract-split`** | Source of the boundary rule this document is written under, and of the "current state, not round history" discipline R-5 applies. |

---

## 8. Open questions for user

Candidate answers and the argument selecting among them are in `01_RATIONALE.md` §R1–§R9. Each
question carries a `Recommended:` answer, which the architect adopts unless it overrides with
evidence. **None of the eight blocks stage 2.**

1. **OQ-1 · Where does the ledger live?**
   **Recommended:** `.harness/operator-obligations.md` — the memory layer's fifth kind, sibling to
   `insight-index.md` (truths), `rejected-decisions.md` (declines) and `decision-rubric.md`
   (autonomy principles), matching the convention those three already set. No `I.*` check measures
   that path (E-20), so the file carries no gated cap and the ~14 KB it receives triggers no WARN;
   E.1 does not compare it against `templates/common/` (E-22). Cap arithmetic for the edits it
   implies: `AI-GUIDE.md` 114 → 115 of 200, `.harness/rules/40-locations.md` 52 → 53 of 200,
   `agents/qa-tester.md` 157 → ≤165 of 300, `agents/pm-orchestrator.md` untouched at 296 of 300.

2. **OQ-2 · How are the 8 obligations that carry no global integer made addressable without
   renumbering anything?**
   **Recommended:** origin-qualified ids — each keeps the ordinal its **enumerating** source assigns
   and gains that origin task's handle as a namespace (`T13-1` … `T13-8`); the 17 global ones stay
   bare integers. The ordinal is preserved against the enumeration, so the widening cross-reference
   "items 3, 6 and 8" — written in the enumerating document itself and repeated by the mirror
   (E-29) — still resolves, and the ambiguity that made a reader drop 8 obligations is closed by
   construction. A human ruling is needed only if "byte-preserved numbering" is meant to forbid a
   namespace prefix as well as a change of ordinal.

3. **OQ-3 · Does the ledger carry completion state, given the nearest prior decline?**
   **Recommended:** yes — one `Last discharged` field per entry, valued `never` or a date plus the
   artifact state the run was against (R-8). The `entropy-findings-store` decline (E-26) rests on
   the state being **re-derived each run by construction**; that ground does not extend here, because
   a parse sweep or a driver run leaves no artifact in the tree from which "was this run?" is
   derivable. The cost is bounded deliberately: no new file, no new read/write cycle, no lifecycle —
   one field on an entry in its only home. A boolean is rejected outright: E-11 shows a discharged
   obligation is re-opened by a later edit, so a boolean would assert a property the next commit
   silently falsifies.

4. **OQ-4 · What moves out of the pin file and what stays?**
   **Recommended:** the three-way rule of R-12 — obligations move, pin-writing constraints stay
   in-band with the keys they constrain (E-27), and the historical narrative of completed tasks is
   left byte-unchanged this row. The residual is stated rather than hidden: the pin file keeps
   roughly 11 KB of narrative that no consumer reads mechanically, and pruning it is a separate row
   because deletion is irreversible and each sentence would need checking against its archive twin.

5. **OQ-5 · What replaces each excised span inside the note strings?**
   **Recommended:** one clause per edited note naming the ledger, carrying no ids and no counts — a
   pointer with nothing to be wrong about. Ids are recoverable in the other direction, from each
   ledger entry's origin field.

6. **OQ-6 · Which contract carries the writer duty of R-10?**
   **Recommended:** the one agent contract that names the pin file today, `agents/qa-tester.md`
   (`:28,83,88,155`) — no other agent contract names it, so the duty fans out to exactly one file
   and lands on the role that already writes it. `agents/pm-orchestrator.md` is not touched (four
   lines of headroom). The in-band statement of R-9 is the primary lever and this is the second;
   restating the duty in a third place repeats the `persist-duty-in-mode-skills` decline.

7. **OQ-7 · What becomes of the drifted convenience index, given that R-1 forbids a live
   restatement and this task cannot edit it?**
   **Recommended:** untouched in this row, and R-1 scoped to say so rather than left contradicting
   §3.2 — the dispatch puts `docs/proposals/*.md` out of scope, and editing or deleting an
   operator-authored document is not this pipeline's act. What R-1 can require and this task can
   deliver is authority plus disclosure: the ledger becomes the sole authority, and the delivery
   names the index as the one live restatement left standing, subordinate to the ledger, whose
   removal is an operator action (AC-13). The index already declares itself a disposable
   single-session aid and carries its own drift warning at its head, so the operator resolves it in
   one step rather than the pipeline resolving it unasked.

8. **OQ-8 · A release-gate check is the obvious way to keep obligations out of the pin file. Why is
   one not added?**
   **Recommended:** it is not added, and the reason is stated rather than assumed. A check —
   "the pin file contains no obligation-shaped prose", or "ledger ids are unique" — would catch a
   recurrence, and this repository has repeatedly declined exactly that trade: a check is a
   permanent per-run cost paid to constrain a writer, where naming the destination in the writer's
   own file costs nothing per run. The design lever replacing it is two-part and both parts are
   verifiable (AC-9): the in-band statement inside the pin file fires at the moment of temptation
   with no trigger to remember, and the writer's contract names the ledger. The decline is recorded
   with a re-surface condition (R-14): if an obligation lands in the pin file again after this
   change, the design lever has been measured to fail and a check becomes justified.

---

## 9. Verdict

**READY.**

Eight open questions are recorded; each carries a `Recommended:` answer that is actionable as
written, and none blocks stage 2. R-1 … R-17 are stated so that they are satisfiable by more than
one choice of location and id scheme, so OQ-1 and OQ-2 are genuinely open at the design level
rather than pre-decided by the requirement.

**Residuals handed to a stage that can execute** — this stage has no shell and certifies none of
them:

- **RES-1** — the consumer set of §0.3 is re-derived with a hidden-inclusive search and its form
  stated (AC-7); "the set is total" is not claimed here.
- **RES-2** — every consumer is proven unbroken by **execution**, not inspection (AC-7).
- **RES-3** — the 24,874-character figure (E-3) is upstream-measured and unverified here.
- **RES-4** — the source text of obligations 1–11 **and of the eight** is transcribed from archived
  stage documents whose round sections amend each other (E-4, E-9, E-29); the resolution of each
  amendment is a reading, and B-2 governs anything that cannot be located.
- **RES-5** — the ledger is scanned by I.6 (B-8); only a run proves the transcription clean.
- **RES-6** — E-6's source set is **derived by reading, not certified total**. The instrument was
  the `Grep` tool (ripgrep-backed) over `docs/features/_archived/` and `.harness/`, following the
  citation chain out of each note value; a plain-pattern ripgrep skips dot-directories by default.
  G-2 is the standing proof that a source set stated as closed can be short by one, so the
  criterion that matters is AC-3's per-ordinal mirror-versus-enumeration verdict, which fails loudly
  rather than certifying silently. A stage that can execute re-derives this set with a
  hidden-inclusive search and states its exact form.
