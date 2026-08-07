> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

Opened under **T5.1** (a design-fidelity finding turns on why the design chose a shape), **T5.2** (adjudicating a developer-recorded `DESIGN DRIFT`) and **T5.3** (a reuse-correctness / risk finding), plus boundary-rule rows for measurement narrative and captured evidence longer than 5 lines.

## §A — AC-3: the role × act table, built from the three shipped files

Built by reading the three contracts, not by copying D-2. Citations are to the working-tree files as they now stand.

| Act | Stage 3 owner | Stage 5 owner | Where each contract says so |
|---|---|---|---|
| Author the contract-portion body | gate-reviewer | code-reviewer | `gate-reviewer.md:14`, `code-reviewer.md:14`, `pm-orchestrator.md:44-45` |
| Author the rationale portion when non-empty | gate-reviewer | code-reviewer | `gate-reviewer.md:38-43`, `code-reviewer.md:42-46`, `pm-orchestrator.md:45` |
| Emit the target-path + fidelity header | gate-reviewer | code-reviewer | `gate-reviewer.md:65-69`, `code-reviewer.md:48-52`, `pm-orchestrator.md:45-46` |
| Check the returned body's brackets before writing | pm-orchestrator | pm-orchestrator | `pm-orchestrator.md:49-52` |
| Create `03_GATE_REVIEW.md` / `05_CODE_REVIEW.md` | pm-orchestrator | pm-orchestrator | `pm-orchestrator.md:46-47`, `gate-reviewer.md:15-16`, `code-reviewer.md:15-16` |
| Create `03_RATIONALE.md` / `05_RATIONALE.md` when returned | pm-orchestrator | pm-orchestrator | `pm-orchestrator.md:47-48`, `gate-reviewer.md:42-43`, `code-reviewer.md:45-46` |
| Author the corrected body on round N ≥ 2 | gate-reviewer | code-reviewer | `gate-reviewer.md:34-35`, `code-reviewer.md:36-37` |
| Overwrite the path on round N ≥ 2 | pm-orchestrator | pm-orchestrator | `pm-orchestrator.md:52-53`; anaphors at `gate-reviewer.md:34-35`, `code-reviewer.md:36-37` |
| Record the round in `PM_LOG.md` | pm-orchestrator | pm-orchestrator | `pm-orchestrator.md:53`, `:95-99`; `gate-reviewer.md:35-36`, `code-reviewer.md:37-38` |
| Modify upstream stage docs / code / config | nobody | nobody | `gate-reviewer.md:86`, `code-reviewer.md:101`, `pm-orchestrator.md:15` |

Nine acts, two stages, eighteen cells. Every cell has exactly one owner. No cell is empty. No contract contradicts a cell — I checked the three most likely contradiction sites specifically:

1. `pm-orchestrator.md:30,:32` ("Output document" column). Names the stage's output; applies no verb and addresses no actor. Same standard the design applies to `skills/harness/SKILL.md:36`. The added pointers make the row self-resolving rather than misleading.
2. `pm-orchestrator.md:95-99` (`## Round records`). Names a different path (`PM_LOG.md`) and a different act; unedited; consistent with P7.
3. `.harness/rules/60-tool-handoff.md:122-124`. "Never edit `docs/features/<task>/01–07` documents authored by an upstream agent … the original author re-does it." I read this rather than accepting the design's disposition, because a PM overwriting `03_GATE_REVIEW.md` on round 2 is the obvious candidate contradiction. It is not one: the rule's own remedy *is* P7 — the original author re-does it and returns a corrected complete body. The rule forbids a downstream agent substituting its own judgement, which P5 forbids independently.

## §B — DRIFT 1 (K7 / L-19): the ruling, and why the direction and not just the edit

**Ruling: upheld. The H1 goes; `begins with` stays. This is not a route-back to the solution-architect.**

The developer's framing is correct and the conflict was real: after K2, `agents/code-reviewer.md:20-21` says the returned body "begins with that line", while its own worked example put `# Code Review` first and the marker third. A stage-5 body written the way its own contract demonstrated would have tripped P6(a) at `pm-orchestrator.md:49-50` and been routed back unwritten. That is a behavioural defect this task would have introduced, in the one file whose internal consistency is R-8's whole subject.

**Why the other direction is worse, decisively.** The alternative is to relax K2/G2, P6(a) and AC-8(a) from "begins with" to "carries". The bracket's entire value is that it is a **first-line test** — cheap, mechanical, and evaluable by a writer that holds nothing but the returned text. "Carries" converts it into a search over the body, and a search is satisfied by a *quotation*. This is not hypothetical: `agents/code-reviewer.md:122` is a copy of the stage-5 marker inside a fence, and any review of this task quotes the marker at least once. Under "carries", a body whose real opening line had been lost but which quoted the marker anywhere — inside a fence, inside a findings row, inside a design-fidelity cell — would pass the check. That is precisely the tail/opening-loss case G-7 was cleared on and RES-2 already concedes for the interior. Widening the bracket would trade a closed finding for a cosmetic, exactly as `04_RATIONALE.md` §D3 argues.

Three further supports the developer did not use:

1. **`CONTEXT.md:54-58` is a fourth site.** The `Returned body` glossary term — an L-25 row already applied at stage 2 and gate-verified — reads "the contract portion **beginning with its declared opening line**". Relaxing the bracket would require editing a permanent glossary term written this round, not three sites but four.
2. **`.harness/rules/70-doc-size.md:49` treats the marker as structure.** The boundary rule's classification unit list names "the `> Contract portion.` header line" as a unit of a declared shape, while `:59-60` says a heading "carries no content" and is *not classified*. The marker is a classified unit; the H1 is not. Deleting an unclassified structural ornament to protect a classified unit's position is the right way round.
3. **No mechanism reads the H1.** `agents/supervisor.md:97,:99` validates stage-3 and stage-5 documents on `## Findings`, `## Verdict` and a 20-line minimum. `verify_all` does not read stage documents at all. Nothing greps `# Code Review`.

**On "this changes the shape of every future `05_CODE_REVIEW.md`" — weighed, and it is the smaller change.** It aligns stage 5 with stage 3, which has had no H1 since the T-18 schema landed and whose contract carries no fenced example to disagree with (`agents/gate-reviewer.md` has no fence at all — this is why the design, reasoning mostly from the gate side because AC-8 probes it, did not foresee the conflict). The cost is a title line that the filename already supplies and that the marker's own text partly restates.

**Did K7 do its job? Yes — and the T-18 QA-12 mechanism is confirmed twice over.** K7 existed because an instruction rendered inside a schema example is silently dropped by a by-reference reader. Here the failure mode was the mirror image: the example itself *carried* an instruction (put an H1 first) that the schema statement contradicted, and only a mandatory re-read with a null prediction would have caught it. A check whose predicted result is null and which nevertheless bites is the strongest possible evidence for keeping that class of check. The developer's decision to record it as a reviewer decision point rather than silently resolving it is the correct handling.

**Scope of the queued row (CR-1, CR-2), corrected.** The developer's Open issue 6 names `agents/developer.md` as carrying the same mismatch. It does not: `agents/developer.md` has **no fenced example** — a fence scan across `agents/` returns fences only in `supervisor.md`, `pm-orchestrator.md`, `code-reviewer.md`, `qa-tester.md` and `solution-architect.md`, and its `## What 04_DEVELOPMENT.md must contain` at `:53-65` is a section table, not a document template. The real membership of the class is:

- `agents/qa-tester.md:15` vs `:92-93` — a live contract-internal contradiction, identical in shape to the one just fixed. Latent only because stage 6 writes its own file and no P6 bracket applies to it.
- `agents/requirement-analyst.md:14-15` and `agents/solution-architect.md:14` vs the artifacts they produce: `01_REQUIREMENT_ANALYSIS.md:1` and `02_SOLUTION_DESIGN.md:1` in this very folder both open with an H1 and carry the marker at `:3`. No fence is involved; the contradiction is between a contract and the documents written under it.
- `agents/pm-orchestrator.md:198` is **not** in the class: it declares four shapes for `07_DELIVERY.md` and never claims an opening marker line, so its `# Delivery Summary` fence at `:206` contradicts nothing.
- `agents/solution-architect.md:93-101,:105-126` are section-level snippets, not whole-document templates. Not in the class.

So the queued row is: *settle H1-vs-marker ordering once, across all seven contracts and their examples, and make the produced 01/02 conform.* It is one row, not a sweep, and this task correctly declines to do it — it has no ledger row, D-6 dispositions the four sibling contracts as unchanged, and doing it here would be exactly the over-build attractor the gate named at dimension 8.

## §C — How I settled the line counts without a shell, and the finding I withdrew

C-5 is a binding condition and the PM asked me not to accept it on assertion, so I re-derived it with the only instrument stage 5 holds.

A first pass produced an apparent contradiction. Full reads of the three post-change files terminated at 297 / 126 / 178 — each exactly one above the developer's published `wc -l` — while `04_RATIONALE.md:26-30` publishes `lastbyte=0a` for all four, under which `Read` and `wc -l` should agree. I was one edit away from filing that as a MINOR finding against §D1.

It would have been wrong. An offset read of `agents/supervisor.md` from `:282` shows content through `:287` and an **empty numbered line 288** — the tool emits a trailing empty segment for a newline-terminated file, and full-file rendering strips the trailing whitespace so the phantom is invisible at the end of a whole-file read but visible in a partial one. Repeating the partial read at the tail of each file settles it:

| file | last line with content | phantom | implied `wc -l` | developer's figure |
|---|---|---|---|---|
| `agents/pm-orchestrator.md` | `:296` | `:297` empty | 296 | 296 ✓ |
| `agents/gate-reviewer.md` | `:125` | `:126` empty | 125 | 125 ✓ |
| `agents/code-reviewer.md` | `:177` | `:178` empty | 177 | 177 ✓ |
| `agents/supervisor.md` | `:287` | `:288` empty | 287 | 287 ✓ |

All four reproduce exactly. `lastbyte=0a` is consistent with every observation. AC-7 is independently verified: 296 / 125 / 177 / 287, cap 300, four lines of headroom on the capped file, and 293 − 5 (C1) − 3 (C2) + 11 (block) = 296 is arithmetically exact. The "C1 frees 5, not 6" correction is right for the reason given — one of the two separator blanks must survive the fold — and the observation that the two inherited errors cancelled at 297 is also right.

Two consequences worth recording. First, this is the T-18 RES-4 pattern arriving from the other side: a read-only stage substituting a content-read for a byte measurement can be *wrong* about the citation while feeling right about the content, and the discipline that saves it is re-measuring at a second offset rather than filing on the first reading. Second, it is why CR-7 is filed: the developer's harvested insight attributes the skew to three files out of four, when in fact the tool behaves uniformly and the odd one out is E-15's inherited figure for `supervisor`. An insight-index entry is permanent and the index is capped at 30; a mechanism stated one way when it works another way will mislead the next task that plans a budget against it.

## §D — The audit re-derivation, run independently

The `--hidden` finding is real and is the most valuable thing in `04_DEVELOPMENT.md`. My tooling searches dot-directories by default, which let me check the claim directly rather than take it: an S1-class run returns `.harness/rules/60-tool-handoff.md`, `.harness/rejected-decisions.md`, `.harness/scripts/test-verify-i6.{sh,ps1}`, `.harness/insight-index.md`, all six `templates/*/.harness/agents/dev-*.md.tmpl`, `templates/common/.harness/rules/00-core.md.tmpl` and both `60-tool-handoff.md` copies — 30 files in total. Every one of those `.harness/`-pathed sites is invisible to the design's S1 as literally written. The trap's shape is exactly as described: the search does not fail, it returns a plausible-looking 20-odd files, and what it silently drops is the distributed-twin class that R5 names as the highest risk and that the ⊕ rows exist to close. A C-4 publication built on the literal search would have been non-total in precisely the class C-4 exists to prevent. Correcting the instrument before publishing is the right call and the insight is worth harvesting.

Reconciliation of my runs against the publication:

- **S1 (two filenames), 30 files.** All 30 carry a published disposition. Occurrence counts match the developer's line lists everywhere I checked (`agents/pm-orchestrator.md` 4, `gate-reviewer.md` 3, `code-reviewer.md` 3, the six `dev-*.md.tmpl` 1 each, both `workflow.md` copies 2 each, both `60-tool-handoff.md` copies 3 each).
- **S2 (two role names), 36 files.** 35 dispositioned; `skills/harness-init/SKILL.md` is not — CR-3. Its two hits are `:83` (the reserved-name guard listing the seven pipeline-agent names) and `:291` (the same enumeration in the init flow). Neither attributes an authoring or writing verb, so the disposition is "unchanged", identical to `_ai-native-prompt.md:22-23`'s `RESERVED_NAMES` list and the `verify_all`/`test-init`/`test-real-project` role-name lists — all three of which the developer *did* publish. The class is instantiated by other rows, which is why this is MINOR and not MAJOR: applying the T-20 discipline (*which members of the admissible class does no row instantiate?*), the answer is none — this member is unlisted, not uncovered.
- **`docs/workflow.md` read end to end**, since it is a changed file and R-9 quantifies over every attribution in it. Eight role-name occurrences: `:10`,`:12` (the arrow chain, same class as the dogfood `AI-GUIDE.md` and the stage table), `:32`,`:34` (one-line role jobs, no verb), `:43`,`:45`,`:46` (rollback routing). `:66` reads "Each stage produces a document. PM reads it, decides …, writes its decision to `PM_LOG.md`" — *produces*, not writes, and the only write verb in the file is bound to `PM_LOG.md` and to the PM. The file is internally coherent under the new arrangement, not merely patched at `:18`. The twin matches on the lines I read.

## §E — DEV-1, corroborated at stage 5, and what it does to AC-8

DEV-1 confirms D-8 and sharpens it correctly: the cache is not lagging a publish, it is byte-identical to `HEAD`, and `HEAD` **is** the v0.44.0 release commit — so the whole gap is uncommitted working-tree state and link 1 of the four-link chain is the unstarted one. The distinction genuinely needs a shell (`git show HEAD:… | diff -`), and refusing to assert it at stage 2 was right.

I can add a second, independent instance from this stage. The contract loaded into my session declares `## What you produce` as "A file `docs/features/<task-slug>/05_CODE_REVIEW.md` containing structured findings across 6 dimensions, severity-rated, with a verdict", and Hard rule 2 as "You do not edit any document. Read-only." — the pre-T-18 text, including the E-8 contradiction this task repairs. `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/agents/code-reviewer.md:14` is character-identical to it. So **RES-4 / G-10 fired twice in one task**: at stage 3 (O-2) and again at stage 5, in the role whose contract the change edits. The covering statement "a callee may not load the *current* build of its own contract" is now evidenced on two stages by two independent observations, which is a stronger basis for the stage-7 harvest than the design had.

None of this undermines D-8 or AC-8. It confirms the premise AC-8's controlled reproduction rests on: a live dispatch would exercise the 0.44.0 build and measure nothing about this change. Two bounds for QA:

1. The control is **pre-T-18**, not pre-T-23 (`HEAD` predates the schema itself). Its failure on observable (a) is over-determined — the 0.44.0 contract declares no opening line at all, so *any* post-T-18 contract text would produce the same differential. That is G-18's bound, unchanged; the necessity claim for this task's sentences rests on AC-10's three mutations, not on the control. Reporting a control failure as evidence that *these* sentences caused the observable would over-claim.
2. Step 6(a)'s citation is stale (CR-4). The declared opening line is `agents/gate-reviewer.md:18-19`; `:14-15` is now G1.

## §F — Write-act uniqueness, re-run on the shipped bytes

Grepped the four declared path tokens per file and classified every hit. Counts and line numbers reproduce the developer's DEV-2 tables exactly.

**`agents/pm-orchestrator.md` — 4 hits.** `:30`, `:32` constraint + pointer (no verb, no addressed actor); `:46` **the write-act statement (P3)**; `:47` its continuation. The `## Round records` block at `:95-99` names `PM_LOG.md` — a different path and act, out of scope by construction, unedited.

**`agents/gate-reviewer.md` — 6 hits.** `:15` **the write-act statement (G1)**, `:16` continuation; `:18` constraint; `:19` quoted literal (the declared opening line, characters preserved); `:38` constraint (passive, no actor); `:39` quoted literal. G3 `:34-35`, G4 `:42-43`, G6 `:86`, G8 `:65-69` hit zero path tokens — genuinely anaphoric, as Q-7 requires.

**`agents/code-reviewer.md` — 7 hits.** `:15` **the write-act statement (K1)**, `:16` continuation; `:18` constraint; `:19` quoted literal; `:42` constraint; `:43` quoted literal; `:122` quoted literal inside the fenced example. K3 `:36-37`, K4 `:45-46`, K5 `:101`, K8 `:48-52` hit zero.

C-10's three named cases are all covered: the `:30`/`:32` stage rows, P8's marker (worded as a bare pointer from the start, so its conditional never fired), and the quoted opening lines (now at `:19`/`:39` and `:19`/`:43`/`:122` after renumbering).

**AC-10 re-run on the actual text.** Delete `pm-orchestrator.md:46-48`: the file still says a body arrives (P2) and that its author cannot write it (P1), and states no disposition for it — AC-2 unanswered. Delete `gate-reviewer.md:15-16` or `code-reviewer.md:15-16`: no sentence names any role in connection with the four declared paths; `:36`/`:38` name the PM for `PM_LOG.md`, a different path and act — AC-1 unanswered at both stages. The mutation bites.

One divergence from the design's prediction, filed as CR-5: P3 and P4 are **one sentence** in the shipped text, spanning `:46-48` and joined by a semicolon. The AC-10 expected-residue row for AC-2 lists P4 among the survivors; it is not one. This makes the mutation stronger, not weaker, and the reason it does not affect the verdict is that P4's loss removes a *constraint on* the act rather than an answer to "who writes it". QA should delete the whole sentence `:46-48` and expect P5–P7 (not P4–P7) as the residue.

**A note on conjunct (i), which the gate raised as G-13 and which the shipped text confirms.** "Names or addresses the acting role" is vacuous in a second-person document, so uniqueness in `agents/pm-orchestrator.md` rests entirely on conjunct (ii) — the verb-plus-declared-path test. That is not a defect in the implementation; it is a property of the rule, and `04_RATIONALE.md` §D7 shows the developer wording P8's marker, K5 and the G8/K8 header specifically to survive it. K5's construction is the neatest of the three: pointing at `## What you produce` instead of restating the act means Hard rule 2 answers AC-4 with the same answer as the schema section and still dies with K1 under the mutation.

## §G — Dimensions with nothing to report

Dimension 1 (Logic) produced CR-5 and CR-6 and nothing further: the change is contract prose with no control flow, and the one genuine control structure — P6's three-condition bracket check with its "nothing is written at all" consequence — is stated in the correct order (check before write) and is logically equivalent to the design's negative form, per the mapping in `04_RATIONALE.md` §D8, which I verified line by line against `:49-52`. Dimension 4 (Performance): no runtime surface; the only cost dimension is ingest, and the NFR that this task must not increase what a stage reads at dispatch is met — every statement lands in a file the acting role already loads, no rule fragment gained normative text, and B-7's degradation clauses at `gate-reviewer.md:45-46` and `code-reviewer.md:39-40` both survive. Dimension 5 (Security): no input parsing, no credentials, no execution path; the nearest analogue is the tool-grant surface, and S5 shows all eight `tools:` lines unchanged, which I confirmed against the two reviewer contracts at `:4`.
