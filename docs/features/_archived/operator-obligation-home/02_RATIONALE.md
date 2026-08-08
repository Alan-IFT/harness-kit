> Rationale portion for `02_SOLUTION_DESIGN.md`. Non-binding.

# 02 — Rationale: operator-obligation-home (T-24)

Option arguments, the reuse audit, risk narratives, the evidence behind each ruling, and the
suggested byte-forms the contract constrains but does not fix. Nothing here overrides a contract key.

---

## §W — Suggested replacement clauses (K-24) and the in-band sentence (K-25)

Each satisfies every K-24 constraint: contains the literal path, says the obligation is written there
and not here, contains no digit, no id, no count, no `"` and no `\`.

- `_qa_note_t13` — replaces **span B only**, and therefore follows the retained K-45 clause's colon,
  which supplies its lead-in. Lower-case opening is deliberate:
  `the standing operator obligations of this task, and this widening of them, are written in .harness/operator-obligations.md, not here.`
  Span A is replaced by nothing, so the value reads
  `…green-by-symmetry-only. WIDENED in QA rework 3 (this adds NO ninth item - it widens items 3, 6 and 8): the standing operator obligations of this task, and this widening of them, are written in .harness/operator-obligations.md, not here.`
- `_qa_note_t16` (replaces the interior span):
  `The standing operator obligations for these PowerShell surfaces are written in .harness/operator-obligations.md, not here.`
- `_qa_note_t17` (replaces the trailing span):
  `The standing operator obligation for this PowerShell surface is written in .harness/operator-obligations.md, not here.`
- `_qa_note_t20` (replaces the interior span; supplies the antecedent the next kept sentence needs):
  `The standing operator obligation for this PowerShell surface, with its (a)-(e) legs, is written in .harness/operator-obligations.md, not here.`

K-25's sentence, appended to the existing `"notes"` value at `:5`:
`This file pins numeric baselines only; a standing operator obligation is written in .harness/operator-obligations.md, never here.`

Checked: no digit in any authored clause, so B-10 cannot fire on `baseline.json` (a `G.4` file); no `"`
or `\`, so B-7 cannot fire; `verify_all_checks` and every numeric key are untouched, so `G.4` row 11's
whole-file substring `"verify_all_checks": 32` still matches. The digits inside the retained K-45
clause are pre-existing bytes, not added ones.

---

## §R-mirror — how the eight are derived, and why round 1's derivation was wrong

**This section replaces round 1's §R-transcription, which is withdrawn.** That section derived the
eight local ordinals from `_qa_note_t13` and argued the decomposition was *self-corroborating*: the
note's own "widens items 3, 6 and 8" lands on exactly three widened things, and its "EIGHTH BINDING
OPERATOR CHECK" label fixes the upper bound. The argument was valid. Its premise was false.

`_archived/hook-truth-spec/07_DELIVERY.md:72` states the relation in one sentence: "**Eight binding
operator items** are enumerated in `04_DEVELOPMENT.md` and mirrored into `baseline.json:_qa_note_t13`
(the artifact that travels to the operator)." The enumeration is at `04_DEVELOPMENT.md:253-289`,
numbered 1–8, closing "**Eighth and last — no ninth.**" Round 1 transcribed the copy, not the
original, and the copy had lost a member.

**Why every internal check still passed.** The mirror dropped enumeration item 5 (`:264-266`, AC-10
cross-shell byte-identity) and split item 3's reconcile tail into the vacated ordinal. A *split
compensated for a drop*, so the count stayed at eight, the "EIGHTH …" label still bounded it, and the
widening cross-reference still landed with no residue. This is the general lesson R-4 now encodes: a
mirror is self-consistent about everything except what it lost, so consistency-with-itself is not
evidence of completeness, and **no count-based instrument can detect this class of loss**.

**K-46, stated at length.** The instrument that does detect it is the enumerating source's own
cross-reference. S-F `:452-453` reads "Items 1, 2, 4, 5, 7 are unchanged and still binding", and
`:444-451` names 3, 6 and 8 as the widened ones. Together they partition 1–8 exactly once — total and
consistent under S-F's numbering. Under the mirror's numbering the same two sentences contradict each
other: the widening of item 3 is expressly *the reconcile target* ("`Test-InstallBootstrap` is now
**32** `Assert` calls, matching the bash twin — the number to reconcile `test_init_ps_assertions`
against in item 3", S-F `:288-289`, echoed at `:449-450`), and the reconcile leg is what the mirror
holds at its ordinal 5 — an ordinal the partition sentence calls *unchanged*. A thing cannot be both
widened and unchanged. So the mirror's numbering is not merely a different convention; it is falsified
by the source it was copied from, without counting anything. That is why R-6 restores S-F's ordinals
and why the restoration is not a renumbering.

**Direction of the round-1 rule.** K-17/K-18 already said the archive governs wherever the note does
not carry the text, and K-18 had even spotted this loss shape for id 1 (`_qa_note_t17` omits the
template twin at S-A `:467`). The rule was right; it was not applied to the one row-set where the note
*does* carry text and is nevertheless a copy. R-4's widened form closes exactly that hole.

**Why switching source naively would have caused the reverse loss.** Four things exist **only** in the
mirror: the `$nDistinct` byte-form, the `never Out-String` warning, the re-enumeration parenthetical on
the seven capture sites, and the whole `KNOWN BOUNDS (i)/(ii)` paragraph. Transcribing from S-F alone
would have dropped all four — trading one loss for its mirror image. R-4's union rule is the fix, and
§4.1's fifth column is where it is executed.

---

## §R-K45 — the fourth disposition, and why "left byte-unchanged" is the right one

Round 1 wrote that the clause "this adds NO ninth item — it widens items 3, 6 and 8" is "transcribed
into **no** entry (R-7)". That is a fourth disposition: excised with the span and written nowhere.
R-12 offers three, and G-4 is right that inventing a fourth is a defect — not pedantry, because the
same design invokes R-12 elsewhere (K-42) to justify leaving units of the same kind alone.

Three candidate dispositions were tested against R-12's own definitions:

| Disposition | Test | Verdict |
|---|---|---|
| **moves** | "states an action a human must perform before a release is safe" | fails — the clause states no action |
| **stays** (kind 2) | "constrains how a key in that same file is next written" | fails — it constrains no key |
| **left byte-unchanged** (kind 3) | "the historical narrative of a completed task, which already has a permanent home in that task's archived stage documents" | **holds** — S-F `:444-453` is that home and states it verbatim |

Kind 3 is not a residual bucket here; it is a positive match on every clause of R-12's definition,
including the "already has a permanent home" test, which S-F satisfies word for word.

The mechanical consequence is the one genuinely new instruction in this round: `_qa_note_t13`'s
excision becomes **two spans** with the clause surviving between them. That costs nothing — the clause
already ends in a colon, so the K-24 replacement reads as its continuation — and it buys back the
in-tree corroboration G-4 said the round-1 plan destroyed.

**What is not lost.** "No ninth" is a cardinality claim about the T13 block. R-7 forbids the ledger to
store a total, and AC-4 derives one instead, so the ledger represents it by *having eight `T13-` ids*
rather than by asserting it. "Widens items 3, 6 and 8" is represented by which three entries K-15
allocates the widening to, and by their `Origin` fields citing both S-F `:444-453` and the mirror's
widening span. Neither statement is orphaned, and both keep their permanent home in the frozen archive.

---

## §R-K44 — defining the fingerprint-token set without weakening AC-1

G-5 is a real contradiction and it cannot be resolved by adjusting either side alone. AC-1 wants zero
hits in the pin file for each obligation's fingerprint tokens. V-6 wants `Do not invent one` to remain
**present** in the pin file. Entry 2 transcribes a span (S-A `:470-473`) whose last sentence is "The
key is deliberately absent today — do not invent one", and K-23 deliberately keeps the near-identical
kind-2 sentence in `_qa_note_t17` / `_qa_note_t20`. So a token drawn naively from entry 2 fails AC-1
by construction.

Two ways out were considered:

1. **Narrow V-6** — stop requiring the kind-2 sentence to survive. Rejected: it is the whole point of
   R-12 kind 2 and of the T-23 in-band precedent (E-27). The pin-writing constraint must stay in band
   with the key it constrains.
2. **Define the token set** so kind-2 and kind-3 wording is excluded. Adopted (K-44).

Option 2 is not a loophole, and the reason is definitional rather than convenient. R-12 partitions the
note content by *what a unit does*: kind 1 states an obligation, kind 2 constrains a future write to a
key in that file, kind 3 records history. A fingerprint of an obligation can only be drawn from kind-1
material. When an entry transcribes a kind-2 sentence — as entry 2 does, because R-4 forbids dropping
tokens from its span — it carries that sentence as *context*, not as the obligation's identity. So the
exclusion tracks R-12's own partition; AC-1 still fails loudly if any kind-1 sentence survives in the
pin file, which is what it exists to catch.

The residual is honest and recorded as RES-D9/RES-D10: K-44's exclusion list is stated
non-exhaustively, so QA re-derives its own token set (AC-5) rather than inheriting V-5's.

---

## §R-K4a — why the discharge state is a commit sha

G-7 is right that `<artifact state>` had no stated form and that no shipped entry exercises one, so the
choice had to be made on argument rather than on precedent. Four forms were weighed:

| Form | For | Against |
|---|---|---|
| **40-hex `HEAD` sha** | one token covers an entry naming five artifacts; needs no tooling; the operator can read it with `git rev-parse HEAD` on Windows; B-6 becomes a one-line `git diff --quiet` | pins the whole repo, so an unrelated commit makes an entry read stale |
| per-artifact sha256 digest list | precise — only the named artifacts move it | an entry naming five files carries five 64-char digests; unreadable, and the operator must compute them |
| version stamp (`v0.46.0`) | short and human | a version covers many commits, so it cannot distinguish "run against current bytes" from "run, then edited" — the exact failure E-11 describes |
| line count | trivially computed | changes on reformatting and not on semantic edits; the weakest signal available |

The sha wins on the criterion that matters: B-6 needs a *decidable* staleness rule, and only the sha
gives one that a reader can execute. Its cost — over-reporting staleness after an unrelated commit —
is the safe direction: it errs toward "re-run it", never toward "already done". The `+dirty` marker
exists because a run performed against an uncommitted tree pins nothing at all, and pretending
otherwise would reintroduce the stored-assertion defect OQ-3 rejects a boolean for.

Generated artifacts (T13-2's `settings.local.json`, T13-5's pre-commit hook) have no tracked path, so
their entries pin the generator. That is a real weakening — the generated bytes could differ for host
reasons with the generator unchanged — and it is precisely why T13-5 exists as a separate obligation:
byte-identity of generated output is not derivable from the generator's state, which is the same
argument OQ-3 makes against the `entropy-findings-store` decline reaching this set.

---

## §R-BC10 — the check count that travels with the obligations

Four entries carry a check-count-bearing figure after transcription, not three: id 7 (S-A `:491`,
"expect 32/0/0"), id 11 (S-B `:665`, `PASS 32 / WARN 0 / FAIL 0`), id 14 (S-D, both forms plus
`31/0/1`) and id 17 (S-E, `PASS 32 / WARN 0 / FAIL 0`). The gate's G-10 named 11, 14 and 17; id 7 was
found by re-reading S-A's span list for this round.

Three responses were available. **Drop the figures** — forbidden by R-4 and NFR-4, and it would make
the obligation unexecutable, since "expect 32/0/0" *is* the pass observable. **Rewrite them as a
pointer** ("expect the current check count") — a paraphrase, which R-4 forbids, and it would also be
false to the source, which pinned 32 deliberately. **Disclose** — adopted.

The disclosure matters because the sites are ungated: `G.4`'s eleven-file array does not read the
ledger, and B-10 only forbids adding a count-shaped token to a document the count-claim check *does*
read. So nothing will notice if the count moves. What contains the damage is that each figure sits
inside quoted obligation text with an `Origin` field naming the task that stated it — so a future
reader sees a stale *obligation* (which is true: that obligation was written against a 32-check gate),
not a wrong ledger. EP-003 is the row that owns the general problem, and RES-D8 hands it four more
sites rather than letting them arrive unannounced.

---

## §R-OQ1 — why the location argument was re-derived rather than inherited

The recommendation's ground ("no `I.*` check measures that path") is correct, but it was worth
re-establishing from the source because the failure mode is asymmetric: a WARN exits 1, so a wrong
location does not degrade the design, it fails the release gate outright.

Five caps were read line by line (`verify_all.sh:422, 439, 453, 472, 548`). Two further surfaces:

- **`E.1` / the template-mirror question.** `sync-self.sh` defines `sync_dir_of_md` at `:35-56` and
  then **never calls it**; the live mapping is **sixteen** top-level `sync_file` calls at `:63-93`, one
  per file, covering eight script pairs. *(Round 1 said "nine calls over eight pairs" — the pair count
  was right, the call count wrong; G-12.)* So E-22's "not a tree comparison" is right and stronger than
  stated: there is no directory walk in the file at all. The decisive corroboration is empirical:
  `.harness/decision-rubric.md` and `.harness/rejected-decisions.md` already exist in **both**
  `.harness/` and `skills/harness-init/templates/common/.harness/` with no mapping and no gate
  comparing them.
- **`E.4b`.** Its forward arm enumerates `.harness/rules/` only, so the ledger is invisible to it. Its
  reverse arm reads **only `AI-GUIDE.md`** (`verify_all.sh:248-252`, PS twin `:239`) and FAILs on a
  reference to a non-existent fragment — which is B-9. *(Round 1 extended B-9's ground to
  `40-locations.md` and `docs/dev-map.md`; the constraint is harmless but the ground was inaccurate,
  G-15. K-29 now binds B-9 to the `AI-GUIDE.md` line and keeps the other two as a uniform habit.)*

Candidate (e), a new `.harness/rules/*.md` fragment, is arithmetically impossible: `I.2` caps it at 200
lines and the transcribed set runs well past that. Candidate (d), a script pair, creates a `.ps1` on a
host where PowerShell cannot run — it manufactures operator obligations in order to track operator
obligations. Candidate (c), a structured array back inside `baseline.json`, re-encodes EP-002 exactly.

---

## §R-OQ2 — testing "does a namespace prefix count as renumbering?"

The operative test is whether any citation stops resolving. Both registers were checked by Grep over
`docs/features/_archived/`, and round 1's claim needs one correction.

- **Citations of the seventeen — ordinal and frequent, so no prefix:** "items 3 and 10 marked as
  *security*" (`guard-cmd-chain/07_DELIVERY.md:116`), "item **11**"
  (`hook-truth-verify-scope/07_DELIVERY.md:122`), "items 1-16" and "(17)" (`_qa_note_t20`), "sixteen
  unrenumbered items" (`stage-contract-split/03_GATE_REVIEW.md:44`). A prefix **would** break these.
- **Citations of the eight from *outside* S-F and its mirror — all cardinal, never ordinal:** "the
  eight enumerated T-13 items" (`guard-cmd-chain/04_DEVELOPMENT.md:463`), "The **eight T-13 items** …
  are untouched" (`hook-truth-verify-scope/04_DEVELOPMENT.md:659`), "**8** items, written as prose"
  (`hook-truth-derivation/02_SOLUTION_DESIGN.md:1062`), "T-13's 8 and T-17's 10"
  (`hook-truth-verify-scope/05_CODE_REVIEW.md:149`).
- **Correction to round 1.** Round 1 wrote that "the only ordinal citation of the eight anywhere is the
  note's own 'it widens items 3, 6 and 8'". That is false. S-F cites its own ordinals repeatedly —
  `:264` ("until **step 2** runs"), `:284` ("item 1's `ParseFile` sweep", "re-run item 2"), `:289`
  ("the number to reconcile … in item 3"), `:449-453` (items 3, 6, 8 and "Items 1, 2, 4, 5, 7"). Far
  from weakening (a), this **strengthens** it: those citations resolve only under S-F's numbering, so
  adopting S-F's ordinals repairs four internal references that the mirror's numbering breaks (§R-mirror).

Hence K-9: qualify the eight with `T13-`, leave the seventeen bare. The fallback the analyst named —
leave the eight unlabelled with a block header — is what the drifted checklist did, and it dropped all
eight; strictly worse, not adopted.

---

## §R-OQ3 — engaging `entropy-findings-store` on its own ground

The decline's reasoning is entirely re-derivability: "the entropy scan re-derives OPEN/FIXED each run …
a separate log would add a file plus a read/write cycle plus a drift surface to duplicate a property
the design already has by construction." Applied to this set:

| Obligation shape | Leaves an artifact? | Count |
|---|---|---|
| pin a key from a run, reconcile a badge | yes, weakly | ≈4 |
| `[Parser]::ParseFile` sweeps expecting zero output | no | 6 |
| driver runs expecting a summary line and a tally | no | 8 |
| fixture byte-comparisons, mutation probes, runtime guard probes | no | ≈7 |

So the ground is present for at most four of twenty-five, and it is weak even there: E-11 marks items
14(a) / 15(a) / 16 as mandatory **re-runs against later bytes**, so a present key proves *a* run
happened, never that it happened against today's artifact. The property is not re-derivable by
construction, which is the whole premise of the decline.

What the decline *does* bind is shape, and R-8 obeys it: no new file, no lifecycle, no read/write
cycle, no second reader. K-33 follows — appending an origin line to that record would be wrong, because
this is not a re-occurrence of the declined concept. A boolean `done` was rejected outright: E-11 makes
it a stored assertion the next commit silently falsifies, whereas `never | <date> + <sha>` never
becomes false, only old, and B-6 makes the reading of an old record explicit.

---

## §R-OQ8 — the four mechanisms, and why the decline survives its strongest counterexample

Round 1 tested three mechanisms and concluded correctly, but its record would have sent the next
reader down a path it never walked, because all three grounds quantify over **adding a check id** and
the strongest available candidate adds none. G-8 and G-9 are about the record, not the decision.

**Mechanisms 1 and 2 (pin-file-side predicates).** Both fail on measurement. A length heuristic fires
on the kind-3 narrative R-12 deliberately keeps; an imperative-verb matcher cannot separate kind 1 from
kind 2, because the text K-23 keeps is itself imperative ("Do not invent one", "do NOT re-baseline it
upward", "move only together … never separately"). R-12 is a semantic split and no lexical matcher
implements it. This is the same disjointness K-44 exploits, seen from the other side — which is worth
noting, because it means the two keys stand or fall together.

**Mechanism 3 (ledger-side id uniqueness).** This one *does* have a mechanical form, so round 1 was
right to withdraw the analyst's "no predicate exists". Declined on scope (R-16 pins the count at 32),
relevance (it guards duplicate ids, not homeless obligations) and cost (32 → 33 cascades through
`G.4`'s eleven sites plus `CONTRIBUTING.md:22`).

**Mechanism 4 (an `I.6` banned-list entry) — the counterexample.** `i6_banned` is a data-driven array
(`verify_all.sh:640-655`); the scan walks every tracked file via `git ls-files` (`:742`);
`baseline.json` is tracked and absent from the exemptions (`:666-679`). An added record calls no
`step`, so the count stays 32 and **none of the grounds above reaches it**. It is declined on two
grounds of its own:

1. **It moves a frozen PowerShell pin.** `verify_all.sh:636-638` says in terms that the
   `test-verify-i6` drivers "hold a verbatim copy of this banned list", and `:673-674` exempts them for
   that reason. One added record therefore moves `test_verify_i6_bash_assertions` **and**
   `test_verify_i6_ps_assertions` (both `58`, `baseline.json:17-18`), and the PowerShell half cannot be
   re-measured on this host (E-25). A row whose entire subject is that PowerShell obligations cannot be
   discharged would be manufacturing another one. It also reopens `insight-prose-i6-banned-phrase`, a
   recorded decline against touching that list.
2. **The anchor cannot be aimed.** `I.6` has file *exemptions* and no file *inclusions*. Any anchor
   sharp enough to match obligation prose inside `baseline.json` matches the ledger too — whose entire
   content is that prose — so the mechanism FAILs the gate on the artifact this design creates.
   Exempting the ledger means a second edit to the same frozen-pin-bearing list.

Ground 1 is the decisive one and it is *independent* of the count argument, which is what makes the
decline survive. K-32's record now names all four with this reasoning, and its stated count is four,
matching §9 (G-9's mismatch closed).

The falsifier is unchanged and remains stronger than a hope: the anti-entropy sweep
(`skills/harness-deflate/`, cadence `.harness/scripts/entropy-cadence.{ps1,sh}`) produced EP-002 itself.

---

## §R-K16 — why `KNOWN BOUNDS` moves with T13-8

Three readings were available. **Leave it in the note** (it states no action, so R-12 does not move
it) — rejected: it would orphan a qualifier from the obligation it qualifies, which is EP-002's failure
shape in miniature. **Copy it into T13-8 and leave it in the note** — rejected outright: two maintained
copies is the disease. **Move it with T13-8** — adopted; its subject is the four-distinct-events gate,
i.e. T13-8's artifact, and both bounds state what discharging that obligation does and does not
establish, which is R-3's "observable that constitutes a pass" read honestly.

Note the difference from K-45, since the two look similar and resolve oppositely. `KNOWN BOUNDS`
qualifies an obligation, so it is kind 1 by attachment and moves. The widening lead-in describes what a
past round did to the item *set*, has a verbatim permanent home in S-F, and constrains no future
action — so it is kind 3 and stays. The test is whether the unit says something about *what the
operator must do or observe*.

Round 2 additionally located both bounds in the archive — (i) at S-F `:429-432` and
`hook-truth-spec/07_DELIVERY.md:73`, (ii) at S-F `:418-419` and `07_DELIVERY.md:74` — so T13-8's
`Origin` cites four spans and the move is not a one-source transcription.

---

## §R-K17 — note-primary vs archive-primary, and why the rule is split

Ids 12–17 and ids 1–11 take opposite rules, which looks inconsistent until the reason is named: R-4
measures losslessness against *the source that enumerates the obligation*. For 12–17 that is the note
value, which both enumerates `(12)`–`(17)` and is the text R-12 excises. For 1–11 no note carries the
text at all (E-4), so the archived stage document is the only source. For the eight, the note carries
text **but is a copy**, and R-4's widened form makes the enumeration govern — the case round 1 had no
rule for.

The trap K-17 closes is real: `hook-truth-derivation/02_SOLUTION_DESIGN.md:1072-1084` carries a longer,
earlier variant of items 12–14 (full `pwsh -NoProfile -c …` command lines, fixture names `fx-8cell` /
`fx-tokens`, line citations). A developer who "helpfully" merged it would be importing round-1 archive
text into an entry the note already amended, breaching R-5 in the opposite direction from the one
everyone watches for.

---

## §R-reuse — reuse audit

| Need | Existing code / asset | Path | Decision |
|---|---|---|---|
| A `.harness/`-root Markdown file appended by a stage, read at a defined point, gated by nothing, with a `templates/common/` sibling and no sync mapping | `rejected-decisions.md`, `decision-rubric.md` | `.harness/rejected-decisions.md`, `.harness/decision-rubric.md` | **Reuse the shape as-is** — the ledger is the **fourth** such file and the memory layer's **fifth kind** (G-13: round 1 conflated the two counts) |
| A declined-options memory with a re-surface condition | the file's own record format | `.harness/rejected-decisions.md:1-10` | Reuse — append one record (K-32), no new mechanism |
| A memory-layer index line | the `**Memory layer**:` list | `AI-GUIDE.md:36-40` | Reuse — one line appended |
| A file-location lookup row | `## What lives where` | `.harness/rules/40-locations.md:3-25` | Reuse — one row |
| A writer-duty statement attached to the artifact it governs | the T-23 in-band precedent (E-27) | `.harness/insight-index.md` 2026-08-02 entry | Reuse the principle — K-25 puts the statement inside `baseline.json` itself |
| An authoritative statement of *which* obligations the eight are | the enumeration + its own partition sentence | `_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289`, `:444-453` | **Reuse instead of re-deriving** — this is the round-2 correction; round 1 re-derived a decomposition that the archive already states explicitly |
| Counting entries of an appended memory file | `I.4`'s INSIGHT-SCAN over `.harness/insight-index.md` | `verify_all.sh:461-545` | **Not reused.** That scanner exists because the index's entries are multi-line and its cap is gated; the ledger has neither property, and reusing a 90-line state machine to count a fixed marker is more surface for less need |
| An obligation index | `docs/proposals/operator-powershell-checklist.md` | — | **Not reused, not deleted** — the drifted second copy this task exists to make unnecessary (OQ-7) |
| A gate check enforcing the invariant | (none, and none added) | — | K-32 records the decline with four mechanisms and a re-surface condition |
| Machine-countable obligation list via a script pair | (none) | — | Declined at OQ-1 candidate (d): a new `.ps1` on a PowerShell-less host manufactures the debt it would track |

---

## §R-risk — risk narratives behind K-36 … K-46

**Silent obligation loss (K-36).** This is the failure the row exists to close, and it has now happened
**twice** in evidence: once in the drifted convenience index, and once inside this very pipeline, where
a valid argument over a false premise reached a self-consistent wrong answer. The lesson round 2 adds
is that the structural defence cannot be arithmetic. Both prior instances kept a plausible count. The
defence is (i) transcribe from the source that enumerates, (ii) record a per-ordinal verdict against
every other source that states the same obligation, and (iii) have QA re-derive that verdict from the
sources rather than from the developer's output. AC-4's `25` and K-11's `4` are still worth running,
but they backstop a different failure — an entry simply omitted, with nothing compensating.

**Self-counting (K-37).** A rendered example entry inside the header would match `^- Id: ` and report
26. This is a live instance of a recorded truth — a contract inheriting a schema by reference silently
drops what an example renders rather than states — so the contract names the seven fields and forbids
showing them.

**JSON breakage (K-38).** The mitigation is procedural rather than clever: exact-string replacement
inside existing values, no key added, no re-serialisation, a parse proof before the gate, and
replacement clauses written free of `"` and `\` so no escaping judgement is needed at edit time. Round
2 adds a second parse hazard to watch: `_qa_note_t13` now takes **two** edits rather than one, so the
developer must not collapse them into a single regex.

**Over-excision (K-39).** Every review of a deletion watches for "did too little leave?"; almost none
watches for "did too much leave?". V-6's presence probe is the asymmetric half, and round 2 adds the
K-45 clause to its anchor list — which matters, because that clause is the one unit an implementer is
most likely to sweep away, having read the round-1 plan.

**`I.6` (K-40).** All fourteen banned entries key on retired `CLAUDE.md` composition/regeneration
claims, `harness-adopt` scaffolding, or `全程 中文`. No obligation span mentions `CLAUDE.md`, so the
assessed risk is low — but the check is FAIL severity and the ledger sits outside every exemption, so
only a run proves it. If it fires, the fix is at the ledger; §R-OQ8 ground 1 explains why touching the
banned list is worse than it looks.

**Stale references left behind (K-42).** After the excision the notes still narrate "items 1-16 … are
NOT renumbered", and `_qa_note_t13` still carries the widening clause. This looks like drift and is
not: those sentences describe what T-13, T-16 and T-20 *did*, which remains true. Stating it here means
a reviewer who notices them finds the ruling instead of filing a finding.

**Consumer-audit totality (K-43).** A plain-pattern ripgrep skips dot-directories, which would silently
drop `.harness/`. V-11 uses two instruments with different blindnesses; BC-9 requires the
hidden-inclusive form to be **executed** and its exact form stated before AC-7 is claimed. Totality is
still not claimed, because a consumer could read the file through a path this task never imagined.

---

## §R-glossary — CONTEXT.md maintenance

`CONTEXT.md` carried **Operator obligation**, **Obligation ledger** and **Discharge** from stage 1, and
gained **Origin-qualified id** and **Pin-writing constraint** in stage 2 round 1. The term G-1 showed
was missing — **Enumerating source**, with **mirror** defined inside it — is already present at
`CONTEXT.md:239-245`, added upstream in round 2, and its wording ("a mirror is self-consistent about
everything except what it lost") is exactly the rule this design implements. Round 2 adds no glossary
term: the vocabulary the finding needed is in place, and duplicating **mirror** as a separate entry
would create the two-homes defect this row exists to close. Stage 2 uses both terms as canonical
throughout §4 and §4.1, and `Origin-qualified id` was re-checked against R-6's new wording (it already
says "as its **enumerating source** assigns it") and needs no edit.

---

## §R-scope — boundary calls a reviewer may want argued

1. **`docs/concepts.md` and `README.md` untouched.** `concepts.md`'s "What the project remembers" table
   (`:193`) names `insight-index.md` and not `rejected-decisions.md`; `README.md` mentions the
   rejected-decisions memory only in the v0.34–0.40 adoption paragraph. A memory-layer file shipping
   without an entry in either is the established precedent, so R-15 is satisfied by `dev-map.md`,
   `40-locations.md` and `AI-GUIDE.md`.
2. **`CHANGELOG.md` under the existing `[0.46.0]` heading.** T-16, T-17 and T-20 all shipped under that
   one heading; creating a new heading would move a version stamp and breach AC-11 and `G.3`.
3. **`70-doc-size.md` gains no caps row.** The gain is discoverability for a reader looking up caps;
   the cost is a divergence between two hand-aligned twins with no gate watching, for a file that has
   no cap to state. The ledger's own header carries the statement instead.
4. **Document size, round 2.** BC-7 forbids growth. The contract entered this round at 512 lines and
   leaves it at **510**, with every new key (K-4a, K-44, K-45, K-46), the re-issued §4.1 table, V-14,
   V-15, §12.5 and four new residuals absorbed by compressing argument out of the contract and into
   this file — which is what the stage-doc boundary rule prescribes and what BC-7 asks for by name.
