# 02 — Rationale — T-20 `harvest-wrapped-insight`

Rationale portion for `02_SOLUTION_DESIGN.md`. The gate reads this by default; other stages read it
when one of their own triggers fires. Every claim here is backed by a path and a line read during
this stage.

## EVIDENCE

**F-1 — the archived corpus.** `docs/features/_archived/**/07_DELIVERY.md` matches 41 files; 34 carry
a heading matching `^##[[:space:]]+Insights?[[:space:]]*$`, every one the bare `## Insight`. Under
the contract's original Definitions 3 of the 34 carried 5 unaccounted lines
(`supervisor-agent:123,125`, `ai-native-init:120,122`, `i6-semantic-guard:96`). The gate re-derived
all three figures independently by reading every section to its terminator (`C-1`), and
`01_RATIONALE.md` E-13 carries the per-file breakdown. In all three the break is **terminal** — no
line after it satisfies the entry-start predicate — which is exactly what licenses the contract's
`Terminal footer` and no more.

**F-2 — the canonical wrapped fixture, read in full.**
`_archived/hook-truth-verify-scope/07_DELIVERY.md:196-225`: heading at `:196`, blank at `:197`, then
four entries at `:198-206`, `:207-213`, `:214-219`, `:220-225` — 4 entry-start lines and 24
continuation lines at a 2-space indent, no internal blank line, each entry's `· evidence:` pointer on
a continuation line. EOF at `:226`. This is `AC-1`'s fixture shape.

**F-3 — the live index is clean under `INSIGHT-SCAN`.** `.harness/insight-index.md:1-8` is header —
`:7` is `<!-- Append new insights below, one per line. Format:` and `:8` is `-->`, with **no** example
bullet between them, so `K-7`'s walk stops at `:9` with `comment_state` false and the comment
extension never fires on the dogfood file. `:9-38` are 30 entry-start lines with no continuation and
no unaccounted line. So `K-16`'s refusal cannot fire on T-20's own archive, `AC-8`'s "exactly 30
after" is reachable, and `K-61`'s equality holds here (raw 30 = entries 30).

**F-4 — why `K-7` needs the comment extension at all.**
`skills/harness-init/templates/common/.harness/insight-index.md.tmpl` is 9 lines; `:7` opens the
comment, `:8` is `- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>`, `:9` is
`-->`. `:8` satisfies `^[[:space:]]*-[[:space:]]`. Without the extension the header block would be
`:1-7`, `:8` would be the first entry and `:9` its continuation, and `K-12` would move both into
`insight-history.md` on the first rotation, leaving `<!--` unterminated. Pre-change this cannot
happen: `archive-task.sh:94`'s `grep -vE` returns `:1-7` and `:9` in file order and re-emits them
together, so the comment stays closed while the example line rotates away as a garbage entry. The
regression is therefore **introduced by this change**, which is why `B-19` exists and why the closure
sits in `K-7` rather than in a template edit — the file already on disk in an already-generated
project is the artifact at risk, and `upgrade-project.sh`'s `refresh_set` does not touch it.

**F-5 — `F.1` and the mirror set, recounted from the artifacts (`G-12`).** `sync-self.sh:62-93`
carries mappings numbered **2 through 9** — harness-sync, install-hooks, archive-task, guard-rm,
migrate-scripts-layout, upgrade-project, language-policy, hook-spec — that is **eight** pairs, not
nine; mapping 1 was removed at v0.30.0 (the comment at `:58-60` records it) and `AI-GUIDE.md:76`
independently says "8 dogfood script pairs". `verify_all.sh:284` enumerates
`verify_all sync-self harness-sync test-init test-real-project ambient-prompt ambient-reset
upgrade-project language-policy entropy-cadence hook-spec`: it **does** name two test drivers
(`test-init`, `test-real-project`) and omits **five** more recently added ones (`test-supervisor`,
`test-verify-i6`, `test-language`, `test-harness-upgrade`, `test-guard-rm`). So the precedent for
leaving `test-archive-task` out of `F.1` is **recency, not kind**. The round-1 figures ("nine
mappings", "the four most recently added", "no test driver named") were all wrong, in a task whose
own `AC-4` bans derived figures — insight L12's class, caught by the gate.

**F-6 — the distribution path.** `upgrade-project.sh:184,193,230,237` shows `refresh_set` containing
`archive-task.ps1 archive-task.sh` and the invariant `refresh_set == known minus verify_all.{ps1,sh},
baseline.json`. `skills/harness-upgrade/SKILL.md:192,231` confirms `verify_all` travels by a separate
splice path and that agent / skill / **rule** content is not refreshed at all — which is why the
template halves of ledger rows 25-27 reach new projects only, and why `K-64` (not a template edit) is
the only mechanism that reaches an existing project's index.

**F-7 — the second false-mechanism sentence.** `agents/developer.md:64` reads "A wrapped bullet loses
its continuation lines when harvested, so never wrap one"; `agents/pm-orchestrator.md:221` reads "the
continuation lines of a wrapped bullet are silently dropped". `01_RATIONALE.md` E-8 named only the
second. An independent repo-wide sweep found no third mechanism claim (gate `C-7` confirms). This is
insight L34's class.

**F-8 — the `I.6` decline is measured, not preferred.** `verify_all.sh:561-564` states that
`test-verify-i6.{ps1,sh}` "hold a verbatim copy of this banned list" and are exempt from the scan for
that reason. Adding one entry therefore forces both drivers to change and moves
`test_verify_i6_ps_assertions` / `test_verify_i6_bash_assertions` (58/58 at `baseline.json:17-18`),
which under this task's transcription discipline would have to come from a captured run — real cost,
for a phrase that is ordinary English.

**F-9 — no driver asserts on `I.4`.** `test-init.sh` matches `insight-index` only at `:699-701`, and
those three lines assert on `.harness/rules/05-insight-index.md`'s language, not on any check;
`test-real-project.sh` has no match. That is what makes `K-68`'s label and message change free of
assertion-tally movement. `G.4` derives the check count from the live `step` tally
(`verify_all.sh:846-850`), so a label edit cannot move it either.

**F-10 — the `AC-4` fragility, measured against the code (`G-7`).** `archive-task.sh:94-99` is
`header=$(grep -vE …)` followed by `echo "$header"`. Command substitution strips **all** trailing
newlines, so an index whose non-bullet lines end in N blank lines emits none of them, and an index
with no non-bullet line at all emits one spurious blank line from `echo ""`. `K-7`'s array walk emits
the header block verbatim in both cases. `K-13` correctly forbids `echo` post-change, which is what
makes the divergence possible at all. `K-65`'s seven conditions are the exact complement of those two
shapes plus the four other pre/post asymmetries this change introduces deliberately (trailing-
whitespace stripping, the `BC-23` status, the `K-64` header extension, and the `B-4` refusal).

**F-11 — the pre-existing dry-run abort (`G-13`).** `archive-task.sh:62` is
`[[ "$DRY_RUN" == false ]] && touch "$insight_index"` as the last command of its `then`-block under
`set -euo pipefail`. `archive-task.ps1:62-67` is the same branch written as an `if` with
`Write-Warning`, which does not terminate, so the twin already exits 0 there. `BC-23` makes exit 0
the required behavior in both; `K-63` reaches it by replacing the AND-list with an `if`, which also
removes the `set -e` interaction rather than reasoning about it. The driver **captures** the
pre-change bash status instead of asserting a predicted 1 — the L12 discipline applied to the one
figure in this design that came from reading rather than from a run.

## Prose sweep — the `K-47` enumeration

Searched over live files for `continuation line|silently dropped|one physical line|wrapped
bullet|harvest|30 lines|30 evidence`. Every hit is either a ledger row or one of the following, which
are inspected and deliberately unchanged:

- **The "one physical line" authoring preference** (out-of-scope 5, **six** files, each re-opened for
  this round): `agents/pm-orchestrator.md:193,219,223`, `agents/developer.md:51,64`,
  `skills/harness-init/templates/backend/.harness/agents/dev-db.md.tmpl:113` and
  `…/backend/.harness/agents/dev-api.md.tmpl:64`,
  `…/fullstack/.harness/agents/dev-db.md.tmpl:110` and
  `…/fullstack/.harness/agents/dev-frontend.md.tmpl:111`. (`developer.md:64` carries the preference
  **and** the false mechanism claim in one row; ledger 17 removes only the second clause.)
- **Sentences that describe harvest without stating a quantity, true before and after**:
  `agents/pm-orchestrator.md:182` and `:217-218` (the bare-heading match note, kept true by
  out-of-scope 10), `agents/developer.md:68`, `.harness/rules/65-intervention.md:78`,
  `docs/concepts.md:193`, `docs/dev-map.md:101`, `skills/harness/SKILL.md:33,40,42`,
  `skills/harness-init/templates/common/AI-GUIDE.md.tmpl:87`.
- **Out-of-scope 11(a)**: the six template `F.4` blocks —
  `generic/verify_all.sh.tmpl:190-196` / `.ps1.tmpl:220-227`, `backend/…:301-307` / `:278-…`,
  `fullstack/…:286-292` / `:258-…`.
- **Out-of-scope 11(b)**: `skills/harness-init/templates/common/.harness/insight-index.md.tmpl:3,8`.
- **History-bearing, never edited**: `CHANGELOG.md:771,1688,1694`, `docs/tasks.md:44,45`.

The three surfaces `G-8` named are **not** in this list any more — `AI-GUIDE.md:79` ("rotate old
insights … if >30 **lines**"), `.harness/rules/70-doc-size.md:152` and
`templates/common/.harness/rules/70-doc-size.md.tmpl:151` ("Harvests `## Insight` **lines**") all
state a quantity `B-6` changes, so they are ledger rows 26-27. The round-1 `K-47` listed them as
"a fact this change leaves true", which was false. The same sweep added
`.harness/rules/70-doc-size.md:28` / `.tmpl:27` (the caps-table row), `.harness/rules/05-insight-index.md:5,25`
and its `.tmpl:5,29,48`, `agents/pm-orchestrator.md:61`, `AI-GUIDE.md:37`,
`AI-GUIDE.md.tmpl:35`, `.harness/insight-index.md:3` and `docs/concepts.md:168`. `:48` of the
`05-insight-index` template describes `archive-task`'s own rotation and becomes false in a generated
project from ledger rows 3 and 4 alone, with or without `B-16` — which is `G-5`'s third leg.

Ledger row 27 (`K-69`) is kept although it sits outside `B-17`'s enumeration, because `G-8` names
`AI-GUIDE.md:79` by id and leaving a sibling sentence false is insight L34's exact failure. It is
severable: the gate may strike the row without touching another.

## Why one algorithm rather than one module, and what that costs (`K-1`, `K-67`)

Three ways to buy the PM's "agree by construction, not by parallel maintenance" were weighed.

**(a) A shared `insight-parse.{sh,ps1}` pair**, sourced by `archive-task` and invoked by
`verify_all`. Genuinely single-sourced. Rejected on dependency direction: `verify_all` is the release
gate and its own `E.1` runs `sync-self --check` over the very mapping such a module would join, so
the gate would acquire a run-time dependency on a mirrored script whose absence needs a fallback —
and any fallback *is* a second predicate. It also adds a ninth `sync-self` mapping, an `F.1`
candidate and a new distributed file, for a state machine of about fifteen lines.

**(b) `verify_all` `I.4` delegates to a new `archive-task --scan-index` read-only mode.** Same
single-sourcing, no new file. Rejected: it puts a subprocess and a new public flag on the gate's
critical path, and `K-19` has just committed to adding no flags.

**(c) One named algorithm, specified once, implemented once per file, pinned by executed
assertions.** Adopted — and, unlike round 1, priced honestly.

Round 1 claimed (c) bought agreement "by construction". The gate's `R-5` ruled that unsound and it
was right. What is genuinely constructional is narrower than the claim:

- The **entry-start predicate** is frozen at the two spellings that already exist at four sites
  (`K-3`). Nothing in this change introduces a third, so the predicate cannot drift.
- Each **check or run holds exactly one count**. Round 1's `K-26` kept `I.4`'s cap arm as a whole-file
  `grep -c` while `K-27` ran `INSIGHT-SCAN` only for the unaccounted condition — one check, two
  notions of "entry". The new `K-26` runs the scan once and derives both figures from it, so the
  divergence has no place left to live inside a shipped check. This is what `B-6` literally demands
  ("derived from the same classification of the same file").

What remains is **not** constructional and is stated as such in `K-67`: four implementations of the
state machine, in two languages, with no shared source. Two of them (bash) are compared by executed
assertions; two of them (PowerShell) are compared only by the operator run of `AC-9`'s item 17.

The deletion test still supports (c): deleting `INSIGHT-SCAN` does not make complexity vanish, it
reappears at four call sites — which is why it is named and specified once even though it is not
extracted into a file. But the seam is a *specification* seam, not a code seam, and a specification
seam is enforced by tests, not by the compiler. Saying so is the whole of `K-67`.

## Why `K-62` is a pass split rather than a clause order

The contract states the classification order and makes clauses 3 and 4 precede clause 5. An
implementation could honour that ordering with five in-line rules — and round 1's `K-2` shows exactly
how a five-rule in-line form goes wrong, because it had the closer rule at position 2. The three-pass
form removes the failure mode instead of forbidding it: the terminal footer cannot be computed at all
until pass B has produced the last entry, and by then every line it can reach is provably blank or
unaccounted. An implementer who mis-computes `f` still cannot turn a bullet into an ignorable line;
the worst available error is refusing a footer that should have been ignored, which is loud.

The proof in `K-62` turns on one step. Pass B ends the last entry at offset `e` because the next line
is blank, is an entry-start line, or does not exist. It cannot be an entry-start line — that would
open a later entry and contradict "last". So it is blank or the list ends, `in_entry` is false
afterwards, and every subsequent non-blank line falls to rule 5.

## Fence-aware discovery — why the rule is shaped this way (`K-6`, `K-71`)

Section discovery is a whole-document, fence-aware walk because the first-heading form dropped a
harvested entry at exit 0 on a document with a second `## Insight` section — inside `K-65`'s own
admissible class, where the pre-change awk re-armed its flag on every matching heading
(`06_TEST_REPORT.md` `AT-5`, `AT-9`). Three parts of `K-71` are not free choices.

**Why fence state is tracked once, for opener and terminator together.** A fence-aware opener beside a
fence-unaware terminator is the "the two disagree about where a section is" failure: the opener skips a
quoted heading that the terminator still honours, so a live section is cut short at that line. Given a
fence-aware opener the terminator is **entailed, not additional** — that is the code review's answer to
`K-6`'s literal "unchanged" — and one walk makes the disagreement unrepresentable rather than merely
forbidden.

**Why the `Quoted headings: N` report is a precondition, not decoration.** Fence awareness is a
narrowing: content the pre-change script would have harvested is now skipped. Without the report the
narrowing is inferable only from an entry that never arrived — the exact shape this task exists to
remove (user requirement 2). The review accepted the fence rule **only because** the report exists and
ruled that the two must be taken or refused together; `K-71` records the dependency in that direction.

**Why fence awareness stops at discovery, so pass B is unchanged.** Three options
(`05_RATIONALE.md` §6). *(a) shipped* — pass B classifies a fenced line normally: continuation when an
entry is open, unaccounted otherwise, so the worst case is a loud refusal and no line is silently
dropped. *(b) fenced lines → ignorable* — they would be counted only in the aggregate `ignorable lines`
figure and dropped; that is the terminal-footer channel (`AT-3` / `QA-5`) again, and **worse than it**,
because a wrapped entry whose continuation lines straddle a fence would be written to the index **with
its middle removed** — silent *corruption* of a stored entry, not merely loss of an unstored one.
*(c) fenced lines → forced continuation* — identical to (a) whenever an entry is open and undefined
when none is, buying nothing but the conversion of (a)'s loud refusal into a silent absorption. Only
(a) cannot produce the exit-0-with-lost-content shape.

**Why mode `index` stays fence-unaware.** There a fence line is either a continuation, preserved
verbatim through rotation, or unaccounted, which refuses — never dropped. "Fenced content is
documentation" is a rule about a human-authored delivery document; extending it to the stored index
would open a discard channel in the one file this task exists to keep honest.

**The refusal's blast radius is measured, not assumed.** All 41 archived `07_DELIVERY.md` files were
swept: every fence is a balanced backtick run of exactly three, every one precedes its file's
`## Insight` heading, and no `##` line falls inside one (`05_RATIONALE.md` §3). So the fence-open-at-EOF
refusal cannot fire on any archived document and `AC-15`'s `34 / 0 / 3` census is unmoved.

## `B-20` and blank lines (`QA-3`)

`B-20`'s closing inference — "no index line is dropped by a rewrite except the entries that rotation
moves out" — is false for blank lines, and `K-8` states the true property in its place. A blank line is
ignorable and belongs to no entry, and a rewrite emits header ‖ retained ‖ harvested, so blank lines
between stored entries are not re-emitted: QA measured an index of 62 lines rewritten to 32
(`06_TEST_REPORT.md` `AT-14`). No content is lost, and the pre-change script hoisted those lines to the
top instead, which is worse; what the correction owes is precision about which lines survive a rewrite,
not a change to the algorithm.

## Why the `AC-3` count comparison still discriminates — and how (`G-11`)

`AC-3`'s third leg says the comparison "holds over `AC-14`'s index fixture, on which a rule that made
post-break lines ignorable makes the two counts differ". Read against `K-26`, that needs care: once
`I.4` derives its cap figure from the same scan `archive-task` uses, a rejected rule moves **both**
counts to 1 and they agree. Unifying the count is precisely what closes `G-2`, so the two demands
would collide if "the two counts" meant "archive-task's and `I.4`'s".

`K-61` resolves it without reintroducing a second count into a shipped check. The frozen predicate is
kept as a **driver-side oracle**: the raw-marker count is a quantity no check computes, but the
driver can. Over `AC-14`'s fixture (header, entry, blank, `---`, blank, entry-start + continuation)
the raw-marker count is 2 under every rule, while the classified entry count is 2 under the adopted
rule and 1 under the rejected one. The driver asserts equality, so the rejected rule turns that row
red. `AC-16`'s fixture is the one index shape where the oracle's precondition fails by design (an
entry-start-shaped line inside the header block), so the driver asserts the inequality there instead
— and that assertion is simultaneously the `G-3` regression test.

The `archive-task`-vs-`I.4` comparison is still worth running, because it measures a different
failure: divergence between the two bash implementations of the state machine over a non-trivial
file. That is `K-67`'s second claim, discharged by test.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Entry-start predicate, bash | `grep -c '^[[:space:]]*-[[:space:]]'` | `.harness/scripts/verify_all.sh:463` | **Reuse the text verbatim**; the site moves from the check into the driver oracle (`K-61`) |
| Entry-start predicate, PowerShell | `Where-Object { $_ -match '^\s*-\s+' }` | `.harness/scripts/verify_all.ps1:450` | Reuse the text verbatim; same site move |
| Section heading + terminator matchers | awk `/^##[[:space:]]+Insights?[[:space:]]*$/` … `/^##[[:space:]]/` | `.harness/scripts/archive-task.sh:51` | Reuse the regex text; change only the evaluating tool (awk → bash), with a stated measurement obligation (`K-41` table) |
| Rotation, history-file header, date stamp | `archive-task.sh:85-91` | same | Reuse as-is; only the unit changes from lines to entries |
| Empty-array-under-`set -u` idiom | `arr=()` with the L13 comment | `archive-task.sh:46,65,73,80` | Reuse; the new arrays follow it |
| Driver with a `[path]` argument for pre-change comparison | `test-guard-rm.sh:4-8,15` | `.harness/scripts/test-guard-rm.sh` | **Reuse the shape** for `test-archive-task.{sh,ps1}` (`K-31`) |
| Driver summary + exit convention | `PASS:` / `FAIL:` block, exit 1 | `test-guard-rm.sh:262-272` | Reuse (`K-33`) |
| "New key, no PS twin key, transcribed from a run" convention | `test_guard_rm_bash_assertions` + `_qa_note_t17` | `.harness/scripts/baseline.json:23-24` | Reuse as the template for `K-37` |
| "Fold a condition into an existing step, count stays 32" technique | `F.2` containment window | `_qa_note_t16` | Reuse for `I.4` (`K-26`) |
| Label / message / counted-quantity alignment | T-009's dogfood `I.4` rename to "evidence lines" | `verify_all.{sh,ps1}`, `insight-history.md:79` | **Reuse the lesson, not the string** — `K-68` re-aligns the label to "insight entries" now that the counted quantity changes again |
| Unquoted-regex-variable hazard note | `I.6` comment | `verify_all.sh:645-648` | Reuse the discipline (`K-28`) |
| Repo-root-two-up derivation | `repo_root="$(cd "$(dirname "$0")/../.." && pwd)"` | `archive-task.sh:27` | Reuse — and it is *why* `K-32` copies the script under test into the sandbox |
| Distribution refresh of a script | `refresh_set` | `.harness/scripts/upgrade-project.sh:193,237` | Reuse — no change needed; answers `N-4` |
| An HTML-comment-aware markdown reader | (none found) | — | New, and deliberately not a regex: `K-7` scans for two literal tokens, which registers with no engine and so cannot join the L31 matcher family |
| A shared classification module | (none found) | — | Deliberately **not** created — see above |
| An existing `archive-task` test surface | (none found) | — | New driver justified; a repository-wide search for `archive-task` returns no `test-*` driver |

## Risk analysis

| R | Risk | Mitigation | Where it binds |
|---|---|---|---|
| R1 | Fixing harvest without fixing the index read and the header derivation ships a worse defect than today: newly preserved wrapped entries would be hoisted above every entry by the next rotation | The three edits are specified as one atomic change and the edit order forbids an intermediate state | `K-9`…`K-11`, `K-52` |
| R2 | The PowerShell twin is agent-unexecutable, and a parse error in a never-taken branch is fatal to the whole file | Structural parallelism plus four named construct bans, and an operator item that parse-checks before it runs | `K-20`…`K-23`, `K-56` |
| R3 | The new `I.4` condition is vacuous against an index that has no orphan | `AC-7` mutates the artifact, and the mutation is an insertion so it cannot delete a container and over-fire | `K-26`, `K-36` |
| R4 | A matcher diverges between GNU grep, ugrep, awk, bash `[[ =~ ]]` and .NET | The entry-start predicate is frozen; every matcher is registered with its evaluating tool; `[ \t]` is banned outright; the one tool change (awk → bash) carries an explicit fixture obligation; the comment tokens use no engine | `K-41` table, `K-42` |
| R5 | The `B-4` refusal is too broad and wedges a delivery | Measured over all 34 archived sections rather than argued, and `AC-15` re-measures it from a run; the three footer shapes are driver fixtures so a future narrowing turns them red | `F-1`, `AC-15` |
| R6 | The widening is too broad in the *other* direction and swallows content — the failure `G-1` found in round 1 | The pass split makes it structurally unavailable (`K-62`), and `AC-13` / `AC-14` are fixtures the rejected reading actually fails, in both containers | `K-2`, `K-62`, `K-34` |
| R7 | `AC-4`'s byte-identity floor breaks on an incidental output change rather than on a real regression | The admissible fixture class is enumerated and one fixture is pinned; the two known pre/post asymmetries (`BC-23`, `AC-16`) are asserted rather than compared | `K-65`, `K-63`, `K-35` |
| R8 | This task's own delivery is the first live exercise of both paths at a full index | `--dry-run` first, compare the echo against the section, then the real run; `B-12` guarantees the dry run classifies identically | `K-53` |
| R9 | The `K-68` label change is assumed free and is not | Measured, not assumed: no driver matches `I.4`'s label or message (`F-9`), and `G.4` counts `step` calls, not strings | `K-68`, `F-9` |
| R10 | A prose surface stating the old quantity is missed, and no gate reads prose | The sweep above is enumerated per file with line numbers, and every hit is either a ledger row or an explicit non-change with a reason | `K-47`, `K-69` |
| R11 | `verify_all` running in the `AC-7` sandbox aborts before reaching `I.4`, making the row silently absent | The row asserts the presence of the `[I.4]` line and fails on its absence; a documented in-place fallback exists with a `cmp`-restore proof | `K-36` |
| R12 | The `K-7` comment walk mis-handles a line carrying both tokens, or a comment that never closes | The walk is specified as an ordered left-to-right scan, so `<!-- x --> <!--` ends open and `--> <!--` ends open; an unclosed comment makes the whole file header block, which yields 0 entries and 0 unaccounted — refusing to harvest rather than corrupting | `K-7`, §C |
| R13 | Ledger row 27 is read as scope expansion beyond `B-17`'s enumeration | The divergence is stated in `K-69` rather than absorbed, and the row is severable | `K-69` |

## Measurement narrative — what was executed by this stage

This stage has no `Bash` tool. Every claim above was produced by file reads and content searches, and
each is cited to a path and line so the developer and QA can re-derive it. The figures that are
counts over search results rather than over a captured run are: 41 archived delivery documents, 34
with a matching heading, 5 unaccounted lines across 3 files (all three independently re-derived by
the gate, `C-1`), 8 `sync-self` mappings, 5 drivers omitted from `F.1`, 21 files in
`templates/common/.harness/scripts/`, and 9 lines in `insight-index.md.tmpl`. All are re-derivable in
one command each. No tally in this document is transcribed from a run, because this stage ran none —
and no figure in this document was obtained by arithmetic over another figure.

Every path and line number in this document was re-opened during this round; none is carried forward
from an earlier draft. The round record — what changed and which finding drove it — is in `PM_LOG.md`,
which is where `70-doc-size.md` row 8 puts it.
