> Rationale portion for `01_REQUIREMENT_ANALYSIS.md`. Non-binding.

# 01 — Rationale: operator-obligation-home (T-24)

Option arguments, open-question candidate answers, and the argument selecting among them. The
binding statements are in the contract portion; nothing here overrides one.

---

## §R0 — The framing decision: relocate, do not index

The dispatch asks whether a requirement shaped as "produce a good index alongside the notes"
reproduces the defect. It does, and the evidence is unusually direct: the index that exists was
written by an operator who understood the problem, declared its own subordination, and was wrong in
**three** ways within a day — two it found and corrected itself (E-13), and one it still carries
(E-14: it attributes items 1–11 to a note that contains no numbered list).

The third error is the load-bearing one for this decision. The first two are of the class "the copy
was made carelessly"; a reader could reasonably answer them with "make the copy more carefully".
The third is different in kind: the index went looking for the origin of items 1–11, could not find
it in the pin file, and attributed it to the nearest plausible note rather than reporting that the
text is not there. A copy has no way to represent "the source I am summarizing does not contain
this". Only the thing that holds the fact can.

So the requirement is relocation (R-1). The test that separates this from the checklist is R-3 +
AC-2: an entry must be executable **without opening any other document**. An index that points back
at its sources fails that criterion by construction, which is why it is stated as a criterion rather
than as a preference.

### Why this does not create two authorities

Three copies of obligation text will exist after this task, and only one is an authority:

| Where | Status | Why it is not a second authority |
|---|---|---|
| The ledger | live, appended, read for execution | the one home |
| Archived stage documents (`_archived/guard-cmd-chain/04_DEVELOPMENT.md` etc.) | frozen · **transcription source** | nothing updates an archived stage document; after transcription no reader is sent there for current state. A copy drifts when **both** copies are maintained — a frozen record cannot drift, it can only age, and ageing is what an archive is for. Note the direction this cuts: because the archive cannot drift, it is the *better* source to transcribe from than a live note, which is exactly what §R9 turns into a rule. |
| `docs/proposals/operator-powershell-checklist.md` | drifted, out of scope, **disclosed** | it declares itself disposable and carries its own drift warning at its head. R-1 is scoped to authority-and-permission rather than to the absence of every copy, because this pipeline may not edit an operator-authored document; OQ-7 hands its removal to the operator and AC-13 requires the delivery to say so, so the copy is surfaced rather than silently tolerated |

This is the distinction the four preceding rows relied on too: `hook-spec` did not delete the
archived documents that quoted byte-forms, it removed every **live** copy.

---

## §R1 — OQ-1 candidates: where the ledger lives

| Candidate | For | Against |
|---|---|---|
| **(a) `.harness/operator-obligations.md`** | sits with the other three memory-layer files, which are exactly the same species (appended by a stage, read at a defined point); no `I.*` cap measures the path; E.1 does not compare it against the template tree | a reader may expect a template twin because three siblings have one — closed by the explicit out-of-scope item 5 |
| **(b) `docs/operator-obligations.md`** | `docs/` is the human-facing tree and the operator is human; no cap either | `docs/` is project documentation, not project state; the ledger is appended by an agent at a stage boundary, which is what `.harness/` holds |
| **(c) a structured array back inside `baseline.json`** | machine-countable for free | re-encodes the finding: prose in a machine-read pin file, and every consumer of the 19 numeric pins keeps loading it |
| **(d) a script pair `operator-obligations.{sh,ps1}` emitting the list** | the count becomes mechanical | adds a script pair, a `sync-self` mapping, an F.1 member — and a new `.ps1` on a host where PowerShell cannot run, i.e. it *creates* obligations to solve an obligation-tracking problem. Against the standing lightweight-over-heavy preference |
| **(e) a new `.harness/rules/*.md` fragment** | already an indexed, discoverable location | the 200-line cap is gated at FAIL-equivalent severity (E-19) and the content is ~14 KB; it would WARN on arrival |

**(a)** recommended. **(d)** is the one worth naming explicitly as rejected: it is the only
candidate that makes AC-4 mechanical rather than derivational, and it fails on the PowerShell
constraint plus the anti-bloat line. **(e)** is the trap a reader arrives at by analogy with rules
and is arithmetically impossible.

---

## §R2 — OQ-2 candidates: id scheme for the 8 un-numbered obligations

| Candidate | Assessment |
|---|---|
| **(a) origin-qualified `T13-1 … T13-8`** | preserves each ordinal **as the enumerating source assigns it**, makes each addressable, keeps the global integers untouched, and leaves the widening cross-reference "items 3, 6 and 8" resolvable — that cross-reference is written in the enumerating document itself and merely repeated by the note, so it resolves under the enumeration's numbering, not the mirror's |
| **(b) extend the global sequence, 18–25** | renumbers by any reading — the ordinals change and the archived documents that cite "the 8 un-numbered T-13 obligations" stop resolving. Forbidden by the dispatch |
| **(c) leave them unlabelled and describe them as a block** | this is precisely what the drifted index did, and it dropped all 8 |
| **(d) letter suffixes on the nearest global item** | invents a containment relation the sources do not state |

The only reading under which (a) is non-compliant is one where "byte-preserved numbering" forbids a
namespace prefix as well as a change of ordinal. That reading is named in OQ-2 so a human can
override it in one sentence; under it the fallback is (c) plus an explicit "8 entries, ordinals
local to their origin" header, which is strictly worse for AC-2 but violates nothing.

---

## §R3 — OQ-3: completion state, and the `entropy-findings-store` decline

The decline reads: a standalone open/fixed findings store "re-encodes a re-derived fact … the
entropy scan re-derives OPEN/FIXED each run (fixed == no-longer-surfaced, open == re-derived from
the live tree), so a separate log would add a file plus a read/write cycle plus a drift surface to
duplicate a property the design already has by construction."

Every clause of that reasoning is a claim about **re-derivability**, and the test is whether it
holds here. It does not, unevenly:

- **Re-derivable:** a few obligations end in an artifact — "pin `test_guard_rm_ps_assertions` from
  that run" is observable as the key's presence; "reconcile `test_init_ps_assertions` and both
  badges" is observable as the numbers moving together.
- **Not re-derivable:** the majority. "Run `[Parser]::ParseFile` over these twelve files and expect
  zero output" leaves nothing in the tree. "Confirm the driver reaches its `=== Result ===` line"
  leaves nothing. No scan of this repository can distinguish "never run" from "run and passed" for
  those.

So the decline's ground is absent for most of the set, and adopting its conclusion anyway would
mean the ledger cannot answer the question an operator asks first. What the decline still binds is
the **shape** of the answer: no separate file, no lifecycle, no read/write cycle. R-8 obeys that —
a field on an entry, in the entry's only home.

The second argument, independent of the decline, is against a boolean. `_qa_note_t16` marks items
14(a)/15(a)/16 as mandatory **re-runs** against later bytes (E-11). A boolean `done` is therefore a
claim that a later commit silently falsifies, which is the same defect class as a hand-summed count
— a stored assertion nothing keeps true. `never | <date> + <artifact state>` degrades honestly: it
never becomes false, it becomes *old*, and B-6 makes the reading of an old record explicit.

---

## §R4 — OQ-4: the three-way split, and why not everything moves

The dispatch is right that the notes are not purely obligations. Reading them, three kinds are
present:

1. **Standing operator obligations** — a future action gating a release. In `_qa_note_t20` this is
   item (17)(a)–(e) plus its NOTE; in `_qa_note_t16` items (12)–(16); in `_qa_note_t13` the
   MANDATORY / TWO ADDITIONAL BINDING / EIGHTH BINDING / WIDENED spans; in `_qa_note_t17` the
   "PS surface is on the standing operator list" sentence. In `_qa_note_t12`, none.
2. **Pin-writing constraints** — "TRANSCRIBED from a real run, never derived arithmetically"; "CORPUS
   FLOOR (do NOT re-baseline it upward)"; "There is deliberately NO `test_archive_task_ps_assertions`
   key … Do not invent one". These bind whoever next writes a key **in that file**.
3. **Historical narrative** — round histories, label-set corroboration, the T-12 archive correction.

Kind 2 is the interesting one, and the argument for keeping it is the T-23 insight (E-27): a duty
survives when it travels in band with the payload. A constraint on how `baseline.json`'s keys are
written, stored anywhere except `baseline.json`, is the same defect in mirror — a fact whose reader
has to know to go looking. Moving it out to "clean the file" would trade one homeless fact for
another.

Kind 3 is left alone for three reasons, in order of weight: deleting content not created by this
task is a standing red line; each sentence would need checking against its archive twin before
deletion, which is a task-sized job of its own; and it is not what EP-002 found — the finding is
that the obligations have *no other home*, not that the file is long. The cost is stated in OQ-4
rather than hidden: roughly 11 KB of narrative stays in a file every pin consumer loads.

A fourth option — compressing kind 2 into a short `_pin_rules` key — was considered and set aside
for this row: it means rewriting QA prose whose exact wording is its meaning, in the same change
that must prove a 25-item transcription lossless. Two fidelity risks in one row, where one is
avoidable.

---

## §R5 — OQ-6: why exactly one contract, and why not a rule fragment

The candidate set for R-10's home:

| Candidate | Assessment |
|---|---|
| **`agents/qa-tester.md` only** | it is the **only** agent contract that names the pin file (`:28,83,88,155`); `agents/developer.md:42` names a different artifact (`scripts/verify_baseline.json`). One file, and it is the file the writer already has open |
| all seven agent contracts | six of them have no business with the pin file; fan-out with no trigger |
| a `.harness/rules/*.md` fragment | a rule fires on its trigger, and the failure mode here is a writer who is not looking anything up. `40-locations.md` gets the lookup row (R-11) for the reader who *is* looking, which is a different reader |
| the mode skills (`/harness`, `/harness-stream`, …) | repeats `persist-duty-in-mode-skills` verbatim — four hand-synced copies of one sentence |

The in-band statement inside the pin file (R-9) is the primary lever precisely because it needs no
trigger and no contract: it reaches any writer, including a main-session agent holding no pipeline
contract at all — the shape in which the original failure occurred, per the T-23 measurement.

---

## §R6 — OQ-8: the gate that is not added, argued through

The honest form of the argument, stated because the dispatch asks for it deliberately rather than
around it:

**For a check.** It is the only mechanism that *cannot* be forgotten. A writer's contract and an
in-band note are both compliance instruments, and this repository's own standing direction
(`stage-bloat-prohibitions-only`) prefers a design that makes a failure impossible over a
prohibition that depends on someone reading it. A check asserting "the pin file contains no
obligation-shaped prose" would have caught every one of the five historical instances.

**Against.** Three legs, and the third is decisive:

1. Cost asymmetry — a check is paid on every run, by every contributor, forever, to constrain an
   event that occurs about once per delivered PowerShell-touching task.
2. Precedent — T-02, T-09, T-16, T-18, T-20 and T-23 each closed a defect class at 32 checks; the
   count has not moved since T-008, and `[[feedback_design_over_guards]]` is an operator-recorded
   principle, not an inference.
3. **The predicate does not exist.** "Obligation-shaped prose" has no mechanical form. The five
   historical instances are ordinary English sentences inside JSON strings; a matcher for them is
   either a `_qa_note_` key-name ban (trivially evaded by naming the key something else, and it
   would also ban the kind-2 content R-12 deliberately keeps) or a length heuristic (a false-positive
   engine over a file whose remaining prose R-12 preserves). A check that cannot state its predicate
   is a check that will be tuned until it stops firing.

Leg 3 is what makes this decline different from "we would rather not". The alternative lever is
verifiable at AC-9 and its failure is observable: if an obligation lands in the pin file again after
this change, the design lever has been **measured** to fail, and R-14's recorded re-surface
condition makes that measurement the trigger for reopening the question. That is the strongest form
available here — a decline with a falsifier attached.

---

## §R7 — What the requirement deliberately does not decide

- The ledger's **format** (table, per-entry heading block, front-matter). R-3 names the seven fields
  and AC-2 checks them; the shape is the architect's.
- The **command** R-7 publishes for counting. Any one-liner satisfying AC-4 does; naming it here
  would be a byte-form in a requirement document.
- Whether `.harness/rules/70-doc-size.md` gains a caps-table row for the ledger. Considered and left
  to stage 2: the file is 175/200, so one row fits, but the dogfood fragment and its
  `templates/common/` twin are kept aligned by hand and the ledger is dogfood-only — a row naming it
  would diverge the twins with no gate to catch the divergence. The self-describing alternative is
  for the ledger's own header to state why it has no cap, which costs no shared file.

---

## §R8 — The source set, the mirror, and the arithmetic re-derived

Round 1 stated the set was assembled from "five documents" and had AC-3 verify against them. That
was wrong in a way that mattered: for the eight T-13 obligations it named the note value and not the
document the note is a copy **of**. `_archived/hook-truth-spec/07_DELIVERY.md:72` says the eight
"are enumerated in `04_DEVELOPMENT.md` and mirrored into `baseline.json:_qa_note_t13` (the artifact
that travels to the operator)" — a sentence naming a mirror relation that round 1 read past.

**Why the error survived every internal check.** The mirror dropped enumeration item 5 and split
item 3's reconcile tail into the vacated ordinal, so a *split compensated for a drop*: the count
stayed at eight, the note's own "EIGHTH BINDING OPERATOR CHECK" label still bounded it, and the
"widens items 3, 6 and 8" cross-reference still landed with no residue. Every consistency test
available inside the note passes. This is the general lesson and it is now a requirement (R-4): a
mirror is self-consistent about everything except what it lost, so consistency-with-itself is not
evidence of completeness. The only instrument that detects it is a comparison against the source the
mirror was made from — which is why AC-3 now demands a per-ordinal **matches / differs / silent**
verdict rather than an id-set comparison, and why a comparison performed against a mirror is
declared not to discharge it.

**The arithmetic, re-derived rather than inherited.** Counting from the enumerating spans only:

| block | count | enumerating source | corroboration |
|---|---|---|---|
| T-17 items 1–10 | 10 | `_archived/guard-cmd-chain/04_DEVELOPMENT.md:467-492` (7) + `:830-838` (2) + `:1230-1238` (1) | `_archived/hook-truth-verify-scope/04_DEVELOPMENT.md:659` "the ten T-17 items" |
| T-15 item 11 | 1 | `_archived/hook-truth-verify-scope/04_DEVELOPMENT.md:662-676` | `:660` "appends exactly one item" |
| T-16 items 12–16 | 5 | `baseline.json:_qa_note_t16` | "(12-16) … from 11 to 16" |
| T-20 item 17 | 1 | `baseline.json:_qa_note_t20` | "(17) … from 16 to 17" |
| T-13, the eight | 8 | `_archived/hook-truth-spec/04_DEVELOPMENT.md:255-289` | `:289` "Eighth and last — no ninth"; `:444` "still **eight** items, **no ninth**"; `07_DELIVERY.md:72` "Eight binding operator items" |

17 + 8 = **25**. This agrees with `_qa_note_t16`'s "19 -> 24" and `_qa_note_t20`'s "16 to 17"
independently of the defect, and it is the same 25 as round 1 — because the mirror's loss was
compensated, the *count* never moved; only the *membership* did. So BC-2's condition is met and R-2
and AC-4 stay at 25 rather than re-opening.

**What the correction does not do.** It does not retire anything. The recovered obligation is
carried as in force, per the ruling recorded in `PM_LOG.md`: answering "is it still binding?" with
"no" would be this project's first retirement of an obligation — irreversible, and outside a scope
whose out-of-scope list reserves even *discharging* to the operator. The tree already answers "yes"
(`_archived/hook-truth-spec/04_DEVELOPMENT.md:452-453`, "Items 1, 2, 4, 5, 7 are unchanged and still
binding"), and `_qa_note_t20` records that the T-13 obligations were "NOT renumbered, reconciled,
re-read or edited", so nothing ever adjudicated the omission. What R-2 adds is the second half the
operator needs to adjudicate it later: the delivery must state **which** obligation the travelling
note has not carried since T-13. Carrying it silently would repair the ledger and leave the operator
with no reason to look — the retirement stays available, and now it is informed.

---

## §R9 — Evidence this stage could not establish

Restated from §9 of the contract with the reason each is undischargeable at stage 1:

| Residual | Why not here |
|---|---|
| RES-1 consumer-set totality | requires a hidden-inclusive search whose form must be captured; the Grep tool's dot-directory behavior was observed favourable in this session but a favourable observation is not a guarantee |
| RES-2 no consumer breaks | requires running eight drivers plus `verify_all` |
| RES-3 the 24,874-character measure | requires `wc -c` over the extracted values |
| RES-4 amendment resolution for items 1–11 | requires reading three round sections against each other; done partially here (E-9) and completed at transcription time |
| RES-5 I.6 cleanliness of the transcribed text | requires a run |
| RES-6 totality of E-6's source set | the citation chain was followed with one instrument and no dot-inclusive search was possible; G-2 is the proof that a source set stated as closed can be short by one, so the claim is not re-made — AC-3's per-ordinal verdict is what fails loudly if it is short again |
