# 01 — Rationale — T-20 `harvest-wrapped-insight`

Rationale portion for `01_REQUIREMENT_ANALYSIS.md`. The gate reads this by default; other stages
read it when one of their own triggers fires.

## EVIDENCE

Backward-looking proof, cited by path and line as the insight-index and stage-doc rules require.
The forward-looking contract deliberately carries none of these anchors.

**E-1 — the harvest filter.** `.harness/scripts/archive-task.sh:51` emits only lines matching
`/^[[:space:]]*-[[:space:]]/` from inside the section; `.harness/scripts/archive-task.ps1:52`
does the same with `Where-Object { $_ -match '^\s*-\s+' }` and additionally `.Trim()`s each
survivor. Continuation lines are not emitted by either.

**E-2 — the defect in production.** `docs/features/_archived/hook-truth-verify-scope/07_DELIVERY.md:196-224`
carries four wrapped entries, each 6-8 physical lines with a 2-space continuation indent and no
internal blank line, every one ending in a `· evidence:` pointer on a continuation line. All four
lost their pointers. The repair record is at `:147-171` of the same file.

**E-3 — the rotation orphan, established by reading the code rather than assumed.**
`archive-task.sh:94` computes the header as `grep -vE '^[[:space:]]*-[[:space:]]'` over the
**whole** index — every non-bullet line in the file, in file order. `archive-task.ps1:93` is the
same with `-notmatch`. So a continuation line stored in the index is not merely left behind by
rotation: the rewrite at `:95-100` emits `header` first, so continuation lines are **hoisted to the
top of the file, above every entry**, detached from the bullet they belong to. `current` at
`:66-70` collects only bullet lines, so `remaining` and `rotated` both lose them too. This makes
B-8 a repair of a specific observed behavior, not a precaution.

Two consequences worth carrying forward. First, the orphan only materializes on the **rotation**
path — the append path at `:102-106` does not rewrite the file — which is why the damage has been
invisible so far and why this task, running at a full index, will exercise it. Second, fixing
harvest without fixing `current` would be strictly worse than today: the fix would start writing
wrapped entries that the next rotation would then shred.

**E-4 — the `I.4` gate.** `.harness/scripts/verify_all.sh:463` is
`grep -c '^[[:space:]]*-[[:space:]]'`. It counts markers, so continuation lines do not inflate it
and B-6 costs nothing. Adopting that exact form as the entry-start predicate is what buys the
three-way agreement for free.

**E-5 — the governing lesson.** `docs/features/_archived/insight-history.md:79` (T-009): "A
document-size cap is only enforceable if its gate check, its auto-remediation, and its documented
intent all count the SAME quantity." *Correction to the dispatch brief:* the brief located this in
`.harness/insight-index.md`; it was rotated out on 2026-07-31 and now lives in insight-history at
that line. Nothing about its force changes.

**E-6 — the same lesson is unlearned in the distribution.** All six shipped templates still count
physical lines:
`skills/harness-init/templates/generic/.harness/scripts/verify_all.sh.tmpl:192` uses
`wc -l < .harness/insight-index.md`, and its PowerShell twin at `verify_all.ps1.tmpl:222` uses
`Measure-Object -Line`; the `backend` (`:303` / `:280`) and `fullstack` (`:288` / `:260`) twins are
identical. T-009 fixed the dogfood `I.4` and never propagated to `F.4`. Two independent
consequences: a generated project's cap check fires on header and continuation lines that
`archive-task` can never rotate away, and the `wc -l` / `Measure-Object -Line` pair still carries
the off-by-one on a file with no trailing newline that T-009 names by hand. This is a finding this
task surfaced rather than one the brief handed down, and it is the basis for **out-of-scope 11(a)**
and its follow-up task — not for an in-scope behavior. See E-13 for why: the defect is
pre-existing, not manufactured by this change.

**E-7 — preamble prose is real and must not become fatal.**
`docs/features/_archived/stream-defer-human/07_DELIVERY.md:17` is a section containing only the
parenthetical `(omitted — nothing surfaced …)` and no bullet at all;
`docs/features/_archived/supervisor-agent/07_DELIVERY.md:117` opens its section with
`(Only non-obvious project truths that beat a reasonable prior …)` and then bullets. A rule that
refused on *any* non-bullet line would have refused to archive both. This is why the
ignorable/unaccounted split in the contract's Definitions is positional rather than uniform, and
why BC-3 and BC-4 exist as separate rows.

**E-8 — the authoring contracts already document the defect.**
`agents/pm-orchestrator.md:219-221` instructs "write **one physical line** … and the continuation
lines of a wrapped bullet are silently dropped"; `agents/developer.md:51` and six
`templates/**/dev-*.md.tmpl` files carry the "one physical line" phrasing. Only the
pm-orchestrator sentence makes a *claim about the mechanism*, so only it becomes false — hence
B-17 is narrow.

**E-9 — the latent `set -u` abort behind BC-14.** `archive-task.sh:77-79` loops
`for ((i=0; i<rotate_count; i++)) rotated+=("${current[$i]}")` with no clamp. When harvested
entries alone push `rotate_count` past `${#current[@]}` the expansion is unbound and
`set -euo pipefail` aborts. It aborts *before* the write block at `:85`, so no corruption results
today, but the failure is unexplained to the caller. Same family as the T-004 finding at
`insight-history.md:71`.

**E-10 — no test surface exists.** A repository-wide search for `archive-task` returns 49 files,
none of them a `test-*` driver. AC-1 to AC-4 therefore need a surface that does not exist yet,
which is what OQ-4 costs.

**E-11 — the mirror set.** `.harness/scripts/sync-self.sh:70-72` maps both `archive-task` copies;
`verify_all.sh:194` runs `sync-self.sh --check` as E.1. `verify_all` itself is **not** in the
mirror set and its `F.1` symmetry list at `:284` does not name `archive-task`, so a new test pair
does not automatically enter either list — a deliberate choice for the architect to make.

**E-12 — the operator PowerShell list.** The numbered items live in `.harness/scripts/baseline.json`
inside `_qa_note_t16` (items 12-16, taking the list from 11 to 16) with the un-numbered T-13
obligations in `_qa_note_t13`. AC-9 adds item 17 and touches nothing else.

**E-13 — the archived corpus, and why the widening is needed at all.** Measured by the architect and
independently re-derived by the gate over `docs/features/_archived/**/07_DELIVERY.md`: 41 files, 34
carrying a matching `## Insight` heading, and exactly 3 carrying exactly 5 lines that are
unaccounted under this contract's original Definitions. All 5 are a document footer left inside the
section by 2026-05 documents that predate the delivery schema's `## Verdict` heading:
`_archived/supervisor-agent/07_DELIVERY.md:123,125` (`---`, `**Verdict**: …`),
`_archived/ai-native-init/07_DELIVERY.md:120,122` (same shape) and
`_archived/i6-semantic-guard/07_DELIVERY.md:96` (`---` alone, section terminated by
`## Delivery-stage addendum` at `:98`). In all three the break is **terminal**: no line after it
satisfies the entry-start predicate. That is the exact scope of the licensed widening, and it is why
`Terminal footer` is anchored to the last entry rather than to the first break.

**E-14 — the two index headers differ, which is why `Header block` is extended through an open HTML
comment.** `.harness/insight-index.md:7-8` is `<!-- Append new insights below, one per line. Format:`
then `-->`, with no example bullet, so the dogfood header block is `:1-8` and the first entry is
`:9`. `skills/harness-init/templates/common/.harness/insight-index.md.tmpl:7-9` keeps the example
line `- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>` at `:8` **inside**
the comment, and it satisfies the entry-start predicate. Without the comment extension, a generated
project's first entry-start line is that example, the header block ends at `:7`, `-->` at `:9`
becomes its continuation, and the first rotation carries both into the history file leaving `<!--`
unterminated. Pre-change this cannot happen, because the header is derived by `grep -vE` over the
whole file and the comment stays closed. The extension closes it without editing a template file —
which matters, because the template is not the artifact at risk: the file already on disk in an
already-generated project is, and no template edit reaches it.

**E-15 — the pre-existing dry-run abort behind BC-23.** `archive-task.sh:62` is
`[[ "$DRY_RUN" == false ]] && touch "$insight_index"` as the last command of its `then`-block under
`set -euo pipefail`, so `--dry-run` against a **missing** index exits 1 today, after printing the
warning. Both `BC-10` and `B-12` cross this path. B-12 requires the dry run to return the status of
the corresponding real run, and the real run creates the file and exits 0, so the required behavior
is exit 0 and the pre-existing exit 1 is a defect rather than a baseline to freeze. BC-23 states it
so that the AC-4 comparison cannot absorb the change silently.

## Why the entry boundary is defined the way it is

Three candidate boundaries were considered.

**(a) Entry = entry-start line plus every following non-blank line until the next entry-start or
`##` heading.** Blank lines do not terminate. Rejected: trailing prose after the last bullet would
be silently absorbed *into* the last insight, which converts one silent-loss defect into a
silent-corruption defect. It also cannot express BC-6 at all.

**(b) Entry = entry-start line plus every following line indented more than the marker.** Rejected
on measurement grounds rather than taste: it introduces a second predicate that `I.4` does not
share, so the three-way agreement AC-3 demands would have to be re-established by changing `I.4`'s
regex — and a regex change here is exactly the surface the T-16 finding
(`.harness/insight-index.md:31`) says must be measured per tool, because this host's interactive
`grep` is ugrep while the scripts get GNU grep. Zero benefit for a real cross-shell risk.

**(c) Entry = entry-start line plus following non-blank lines, terminated by a blank line, an
entry-start line, or a `##` heading.** Adopted (OQ-1). It reuses `I.4`'s predicate verbatim as the
start test, so agreement is by construction rather than by maintenance; it makes trailing prose and
mid-bullet blank lines *unaccounted* and therefore reportable; and it matches the observed wrapped
shape in E-2 exactly, which has no internal blank lines.

The cost of (c) is BC-7: a continuation line that happens to begin with `- ` is read as a new
entry. This is not silent — the entry count in the B-5 tally rises and `I.4` counts it the same way
— and it is the price of keeping one predicate. Accepting a visible mis-split is better than
accepting a second predicate that can drift from the gate.

## Why the ignorable class widens to a *terminal footer* and not to a *closer block*

E-13 establishes that some widening is required: three archived sections would otherwise be refused
by B-4, which is the wedging failure the PM's stage-1 constraint forbids. Two candidate widenings
were on the table.

**(i) Closer block** (the declined form): the *first* thematic break at or after the first
entry-start line, plus every line after it, is ignorable — evaluated before the entry-start test.
Rejected on two independent grounds. It is not licensed by the evidence: in all three corpus files
the break is terminal, so the corpus constrains only the treatment of non-entry-start lines after a
break, and a narrower rule still scores 0 of 34. And it is unsafe: a bullet after a break becomes
ignorable, so a delivery section drops it at exit 0 with no diagnostic and an index rewrite deletes
it, with the index refusal unable to fire because the line is ignorable rather than unaccounted.
That is the defect class this task exists to remove, re-created inside its own fix.

**(ii) Terminal footer** (adopted): the first thematic break **after the last line of the last
entry**, plus every line after it. Three properties follow.

- *It scores 0 of 34.* In each corpus file the break follows the last entry's last line, so the
  whole footer is ignorable and no section refuses.
- *It cannot absorb content.* A footer begins after the last entry-start line, so by construction it
  contains none; and the classification order evaluates entry-start and continuation **before** the
  footer clause, so even a mis-implemented footer boundary cannot turn a bullet or a continuation
  into an ignorable line. The ordering is the exact inversion of the declined rule's.
- *It leaves the discriminating case loud.* A break with an entry-start line later in the section is
  not a terminal footer, so the break falls through to unaccounted and B-4 refuses, naming the line.

Two consequences worth stating. A thematic break that abuts an entry with no blank line between is a
**continuation** (BC-22), not a footer start, because the footer is defined from the last line of the
last entry — content is preserved rather than dropped, which is the safe direction. And the footer
clause is scoped to a delivery document's section: the insight index has no document footer, and it
is the one file where an ignorable line outside the header block would be *deleted* by a rewrite, so
B-20 keeps the index strict and any stray line there visible.

**Withdrawn (round 3, X-6 / G-14).** Round 2 closed this section by claiming the rule dissolved the
"one check, two notions of entry" hazard for free, on the ground that no entry-start line is ever
ignorable anywhere — hence a count of entry-start lines and a count of classified entries would
agree on every file that classifies clean and disagree only on a file that refuses. That claim is
false and the architect falsified it by measurement (`K-67`): the header-block clause precedes the
entry-start clause, so an index whose header block holds an entry-start-shaped line — which is
exactly the shipped `insight-index.md.tmpl` shape (E-14) — makes the two figures differ by one with
no refusal at all. It is the same over-reach the contract's classification-order consequence
carried, in its derived form.

What survives is narrower and is what the terminal-footer rule actually buys: pass-C demotion can
only move an *unaccounted* line to ignorable, so the footer clause never absorbs an entry-start or
continuation line. The raw-marker / classified-entry agreement therefore holds on every clean file
**whose header block holds no entry-start-shaped line**, with the shipped-template shape as the one
designed exception. That is the form AC-3's third leg now states, and the hazard itself is closed
not by this rule but by deriving both figures from one classification of one file (B-6).

## OQ-1 — blank line as terminator

- (a) Blank line terminates the entry. — **Recommended.**
- (b) Blank line is a continuation like any other non-blank line.

(b) makes BC-5 and BC-6 unrepresentable: prose after the section's last bullet becomes part of that
insight, and the run reports success. The whole point of this task is that content must not move
silently. (a) also matches how the delivery template renders the section.

## OQ-2 — the detectability lever

- (a) Non-zero exit, taken before any mutation, plus the `I.4` condition as a standing second
  layer. — **Recommended.**
- (b) Printed warning, exit 0.
- (c) `verify_all` assertion only.
- (d) Richer echo only (B-5 without B-4).

Argument for (a). The T-15 failure mode was precisely *an orchestrator trusting a console echo*, so
(b) and (d) address the wrong observer: a warning printed by a tool whose output an agent skims is
the same failure with different words. The dispatch brief notes correctly that `verify_all` exits 1
on `warns > 0` (`.harness/insight-index.md:22`), which gives a WARN teeth **inside verify_all** —
but `archive-task` is not `verify_all`, has its own exit status, and is invoked once at stage 7;
a WARN string there is inert. (c) alone is too late: by the time `verify_all` runs, the delivery
document has already been moved into `_archived/`, which is frozen, so the diagnostic points at
something the pipeline is no longer allowed to edit.

Why the refusal must precede the write, and not merely accompany it: `archive-task` writes the
index at step 2 and moves the directory at step 3, with no transaction across them. A loud failure
*after* a partial write leaves a residue the next run treats as normal — the loud-then-quiet shape
recorded at `.harness/insight-index.md:15`. Ordering the check first costs nothing because the
classification is already complete before any write happens.

The second layer matters for a different failure: B-4 protects the *harvest* path, but an
already-stored orphan (from a pre-change run, or a hand edit) is only visible to something that
reads the index. `I.4` reads the index every gate run, and the condition folds into the existing
step without moving the check count — the same technique T-16 used for F.2, recorded in
`baseline.json` `_qa_note_t16` ("NO new step/Step call, check count stays 32").

What would settle this with the operator: a ruling on whether refusing to archive is acceptable
friction at stage 7. The recommendation assumes yes, on the grounds that the repair is deleting or
reflowing one line in a document the PM has open at that moment.

## OQ-3 — template scope — resolved as (b)

- (a) Repair the six template cap checks in this task. — recommended at round 1.
- (b) Leave them; record a follow-up row. — **adopted**, by gate ruling.

The recommendation for (a) rested on a necessity claim: that shipping a harvester which preserves
continuation lines would *manufacture* a WARN in every generated project. The gate falsified that
claim against the artifact. `insight-index.md.tmpl` ships a **9-line header**, so a generated project
at the cap already holds ≥39 physical lines against a 30-*line* check: it reports non-PASS today,
before this task. This change aggravates the magnitude and does not flip the verdict, so the defect
is pre-existing and its repair is scope expansion under red line 3. Out-of-scope 11 records it with
enough precision for the follow-up, together with the second defect in the same file (the header
sentence and the entry-start-shaped example line).

What survives from (a)'s argument is only the part that is genuinely caused by this change: the
`-->` rotation described in E-14. That is a regression this task would *introduce*, so B-19 forbids
it — and the extended `Header block` definition closes it inside the algorithm, with no template
edit, which is also the only route that reaches an already-generated project.

## OQ-4 — test surface

- (a) New `test-archive-task.{sh,ps1}` pair. — **Recommended.**
- (b) Fold fixtures into `test-init` or `test-real-project`.
- (c) Prove by hand runs recorded in the stage docs only.

(a) because AC-4's regression floor needs to drive the *committed pre-change* script against the
same fixtures — the discipline at `.harness/insight-index.md:12`, cross-check a tally against the
artifact that produced it — and that argues for a driver with a `[script-path]` argument, the shape
T-17 used for `test-guard-rm`. (c) is not durable: the next refactor has nothing to run. (b)
overloads drivers whose subject is project generation.

Costs of (a), stated so the architect can price them: one new bash driver executed here, one PS
twin green-by-symmetry, one new `baseline.json` key transcribed from a real run and never derived,
and one new numbered operator item (AC-9). It does **not** force an `F.1` symmetry-list edit
(E-11), but the architect should state whether it takes one.

## OQ-5 — whitespace normalization

- (a) Strip trailing whitespace including CR; preserve leading whitespace. — **Recommended.**
- (b) Preserve every byte.
- (c) Trim both ends, as the PowerShell twin does today.

The twins disagree today: bash preserves the raw line, PowerShell `.Trim()`s it (E-1). B-13 forces
a single answer. (c) destroys continuation indent, which is the content this task exists to keep.
(b) leaves the PowerShell CRLF hazard live — `-split "`n"` leaves a trailing `\r` on every line of
a CRLF document, which `.Trim()` currently hides and which would start landing inside the index the
moment the trim is removed. (a) removes exactly that hazard and nothing else.

## OQ-6 — the superseded insight line

- (a) Append a superseding entry; leave the original unedited. — **Recommended.**
- (b) Edit the line in place to reflect the fix.

`AI-GUIDE.md:37` says append-only, never edit other people's lines; the line in question was
written by the PM at T-15 delivery. Its dated, evidence-scoped form already reads as a historical
finding, and a reader who reaches it also reaches this task's entry. (b) is cleaner to read and is
the operator's call to make if they want it.

## OQ-7 — bypass flag

- (a) No flag. — **Recommended.**
- (b) An `--allow-skipped` escape hatch.

(b) recreates the silent path in one flag, and the first agent that hits a refusal under time
pressure will reach for it. The legitimate escape — fix the delivery document — is cheaper than the
flag and leaves the memory correct.

## Risks

| R | Risk | Note for the architect |
|---|---|---|
| R1 | Fixing harvest without fixing the index-read (`current`) and the header derivation ships a worse defect than today | E-3; the three edits are one atomic change |
| R2 | The PowerShell twin is unexecutable, and a parse error in a never-taken branch is fatal to the whole file | `.harness/insight-index.md:11`; keep the twin structurally parallel to the bash form |
| R3 | The new `I.4` condition is vacuous against the current index, which has no orphan | AC-7 mandates artifact mutation, per `.harness/insight-index.md:26` |
| R4 | A regex change to any of the three predicates diverges between GNU grep, ugrep and awk | `.harness/insight-index.md:31`; the recommendation avoids the risk by not changing the predicate |
| R5 | This task's own delivery runs both harvest and rotation against the fixed script, at a full index — the first live exercise is the delivery itself | AC-8 and AC-12 exist for exactly this; keep this task's own insights unwrapped until AC-1 passes |
| R6 | `docs/tasks.md` and `docs/dev-map.md` describe `archive-task`'s behavior and are doc-sync surfaces | scope check at design time; not asserted here |
| R7 | Any widening of the ignorable class can re-create the silent-drop defect inside the fix | the classification order puts entry-start and continuation ahead of the footer clause, so the failure is structurally unavailable; AC-13 and AC-14 are the fixtures that fail under the declined ordering |
| R8 | The footer clause applies to delivery sections and not to the index, so one algorithm carries a scope parameter | it is one clause, not a second predicate: entry-start, continuation and header classification are identical in both, and B-20 states the index side explicitly |
| R9 | The `Header block` comment extension is exercised by no dogfood file — the dogfood comment carries no example bullet (E-14) | AC-16 drives it from the shipped template content, so the case is covered by an artifact rather than by inspection |
| R10 | BC-23 changes an exit status that the AC-4 pre/post comparison also observes | stated as the single named exception to B-11 and recorded in the delivery; the comparison must assert it rather than absorb it |

## Note on the dispatch brief

Two corrections, neither of which changes the task:

1. The T-009 lesson is at `docs/features/_archived/insight-history.md:79`, not in
   `.harness/insight-index.md` — it was rotated out on 2026-07-31 (E-5).
2. The brief asks whether rotation "leaves continuations behind as orphans". Read closely, it does
   something more damaging: it hoists them to the top of the file above every entry (E-3). The
   requirement B-8 is written against the observed behavior.

One item the brief did not contain and this stage found: the six shipped template cap checks never
received the T-009 alignment (E-6). It was the reason OQ-3 existed; the gate ruled it pre-existing
and it is now out-of-scope 11(a), carried by a follow-up task.

## Round record

**Round 3 — two text corrections, no behavior and no scope change.**

1. **X-6 (from G-14).** The classification-order consequence in the contract, and its derived
   restatement in the section on the terminal footer above, asserted that no entry-start or
   continuation line is ever ignorable at any position in any file. Clause 1 (header block) precedes
   clause 3 (entry-start), so a predicate-matching line inside the index header block is ignorable —
   which BC-24, B-19, AC-16 and E-14 all require. The universal is now qualified to the
   terminal-footer clause, with the header-block case stated as required behavior rather than as an
   exception; the derived form is withdrawn on the record with the architect's `K-67` cited as the
   falsifying measurement. The property that is kept is the one the gate ratified as structural: the
   footer clause can only demote an *unaccounted* line, so it can never absorb an entry-start or
   continuation line.

2. **X-7 (from G-15).** AC-3's third leg required that on AC-14's fixture "a rule that made
   post-break lines ignorable makes the two counts differ". The design derives `archive-task`'s
   count and `I.4`'s count from one classification of one file, so the rejected rule moves both to 1
   together and they agree — the criterion was falsified by the closure of G-2. The leg now names
   the comparison the design actually performs (`K-61`): the raw count of entry-start-predicate lines
   against the classified entry count, equal on every index fixture whose header block holds no
   entry-start-shaped line, with the one designed inequality raw = entries + 1 on AC-16's
   shipped-template fixture. Over AC-14's fixture the raw count is 2 under every rule and the
   classified count is 2 adopted / 1 rejected, so the equality assertion turns red exactly on the
   rejected rule. AC-3 and `K-34`'s AC-14 row now describe one comparison.

Nothing else in either document was re-opened: no behavior, boundary condition, open question or
scope line was touched.
