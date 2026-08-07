> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## §1 — The instrument: a sentence-level write-act classifier, and why I built one

`04_DEVELOPMENT.md` DEV-2 and `05_RATIONALE.md` §F both classify path-token hits by hand. Hand
classification is the same instrument twice, and AC-10's whole force depends on the classification
being right, so I wrote a mechanical one from the rule in `02_SOLUTION_DESIGN.md:97-100` rather than
re-reading their tables.

My first attempt was **wrong and I am recording it**, because it would have produced a false pass.
I wrote a line-oriented regex, `(write|writes|create|…)[^.]{0,80}(03_GATE_REVIEW|…)` and its mirror.
It reported "(NONE)" on the mutants — the answer I wanted — but it also reported "(NONE)" on
`agents/gate-reviewer.md:38`, which plainly reads "`03_RATIONALE.md`, written **only when
non-empty**". The `[^.]{0,80}` window cannot cross the `.` in `.md`, so the regex could never see a
verb sitting to the right of a filename. The right answer for `:38` is "constraint — passive, no
actor", but I would have reached it by accident. A test that returns the right verdict for the wrong
reason is not evidence (T-16 D-1, applied to my own instrument).

The replacement splits each file into sentence-ish units, then applies the two conjuncts separately:
(i) an actor pattern (`You|you|PM Orchestrator|PM|pm-orchestrator|orchestrator`), (ii) a write-verb
pattern, both scoped to a unit containing one of the four declared paths. Result on the shipped
bytes and on the three mutants:

| file | path-bearing units | write-act statements |
|---|---|---|
| `agents/pm-orchestrator.md` (shipped) | 2 | **1** — `:46-48` (P3) |
| mutant `pm.md` (P3+P4 sentence cut) | 1 | **0** |
| `agents/gate-reviewer.md` (shipped) | 4 | **1** — `:14-16` (G1) |
| mutant `gr.md` (G1 sentence cut) | 3 | **0** |
| `agents/code-reviewer.md` (shipped) | 5 | **1** — `:14-16` (K1) |
| mutant `cr.md` (K1 sentence cut) | 4 | **0** |

The counts differ from DEV-2's (4 / 6 / 7) because DEV-2 counts *line* hits and this counts
*sentence* units; the classifications agree everywhere, and the uniqueness result — exactly one per
file, zero after the mutation — reproduces independently.

## §2 — AC-3: the role × act table, rebuilt from the three shipped files

Built by reading `agents/pm-orchestrator.md`, `agents/gate-reviewer.md` and `agents/code-reviewer.md`
directly. I did not open `05_RATIONALE.md` §A until after this table existed; the two agree.

| Act | Stage 3 — owner (site) | Stage 5 — owner (site) |
|---|---|---|
| Author the contract-portion body | gate-reviewer (`gr:14`) | code-reviewer (`cr:14`) |
| Author the rationale portion when non-empty | gate-reviewer (`gr:38-43`) | code-reviewer (`cr:42-46`) |
| Emit the target-path + fidelity header at the end of the final message | gate-reviewer (`gr:65-69`) | code-reviewer (`cr:48-52`) |
| Check the returned body's brackets before writing anything | pm-orchestrator (`pm:49-52`) | pm-orchestrator (`pm:49-52`) |
| Create the four declared paths | pm-orchestrator (`pm:46-48`) | pm-orchestrator (`pm:46-48`) |
| Author the corrected body on round N ≥ 2 | gate-reviewer (`gr:34-35`) | code-reviewer (`cr:36-37`) |
| Overwrite the path on round N ≥ 2 | pm-orchestrator (`pm:52-53`) | pm-orchestrator (`pm:52-53`) |
| Record the round in `PM_LOG.md` | pm-orchestrator (`pm:95-99`, corroborated `gr:35-36`) | pm-orchestrator (`pm:95-99`, corroborated `cr:37-38`) |
| Modify upstream stage docs / code and tests under review / project config | nobody (`gr:86`, `cr:101`, `pm:15`) | nobody (same) |

9 acts × 2 stages = 18 cells; 18 owned, 0 empty, 0 doubly-owned, 0 contradicted.

The one cell I expected to be doubly-owned is "author the corrected body on round N ≥ 2" against
"overwrite the path on round N ≥ 2", because `02`'s B-2 states both as one behavior. On the shipped
bytes they are two sentences with two subjects: `gr:34-35` says *you return the corrected complete
body, and the same transcription applies to the same path* (reviewer, anaphoric, no actor for the
write) and `pm:52-53` says *on round N ≥ 2 the same duty covers the same path* (PM). Clean split.

The nearest thing to a contradicted cell is `pm:10`, "You do not write requirements, designs, or
code yourself", read against P3's "**You write that body verbatim**". It is not a contradiction:
`:10`'s object set is {requirements, designs, code}, a gate review is none of them, and "yourself"
plus P5's "adds and repairs nothing … no completion of a body" is exactly the writer/author split
the arrangement introduces. Recorded because it is the sentence a future reader is most likely to
trip over.

## §3 — AC-5: the fingerprint sweep, and the QA-5 disposition

I did not re-run S1…S5. Three parties have now run them (`02`, `04`, `05`), and a fourth run of the
same searches adds nothing; what no one had run is the **inverse** search — does this task's own
wording appear anywhere it should not?

```
grep -rn --hidden --exclude-dir=.git -lE "the PM Orchestrator writes them|Stage-3 / stage-5 \
  transcription|see the transcription rule below|verbatim, authoring no part" .
→ agents/code-reviewer.md · agents/gate-reviewer.md · agents/pm-orchestrator.md
  docs/features/review-write-path/{02_SOLUTION_DESIGN.md,04_DEVELOPMENT.md,PM_LOG.md}

grep -rn --hidden --exclude-dir=.git -l "may also produce an optional sibling" .
→ docs/workflow.md · skills/harness-init/templates/common/docs/workflow.md
```

Six files and two files. No agent contract outside the three, no script, no rule fragment, no other
template. That is the positive footprint RES-D asked for, and it is the instrument the dirty set
cannot supply.

**QA-5 disposition, published so C-4's totality is closed at some stage even though `04`'s table is
not mine to edit.** `skills/harness-init/SKILL.md:83` reads "Reserved-name guard: partition names
matching the seven pipeline-agent names (`pm-orchestrator`, …, `gate-reviewer`, `developer`,
`code-reviewer`, `qa-tester`) are silently dropped before the Accept prompt", and `:291` is the same
seven-name set inside the init flow. Neither binds any verb to either role: they are identifier
enumerations, keyed on the agent **name**, in the same class as `_ai-native-prompt.md:22-23`'s
`RESERVED_NAMES` list and the `verify_all.sh:74` / `test-init` / `test-real-project` role lists —
all of which `04_DEVELOPMENT.md:241` *does* publish. **Disposition: unchanged, no edit owed.** The
gap is in the publication, not the arrangement, which is why QA-5 is MINOR: applying the T-20
question, the admissible class *is* instantiated by other published rows — this member is unlisted,
not uncovered.

## §4 — The gate runs, in full

```
$ bash .harness/scripts/verify_all.sh          # ×3
…
[I.3] Agent definitions ≤300 lines each ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit 0    (runs 1, 2, 3 identical)
```

Identifiers, extracted from each run by `grep -oE '^\[[A-Z]\.[0-9a-z]+\]'`, 32 per run, md5 of the
sequence identical across runs and equal to the list at `04_DEVELOPMENT.md:35`:

```
A.1 A.2 B.1 B.2 C.1 C.2 D.1 D.2 D.3 E.1 E.2 E.3 E.4 E.4b E.5 E.6 E.7 F.1 F.2
G.1 H.1 G.2 G.3 I.1 I.2 I.3 I.4 I.5 I.7 I.6 J.1 G.4
```

`E.4b` and the `G.1 / H.1 / G.2` interleave are pre-existing ordering, unchanged. AC-6 and AC-11 are
now measured at stage 6 rather than transcribed from stage 4 — RES-A closed.

Line counts, all eight agent contracts rather than the four cited, because AC-7 quantifies over
"every capped file the change touches" and the audit set is only trustworthy if the *untouched*
files are also under the cap:

```
$ wc -l agents/*.md
 177 code-reviewer.md · 91 developer.md · 125 gate-reviewer.md · 296 pm-orchestrator.md
 156 qa-tester.md · 101 requirement-analyst.md · 169 solution-architect.md · 287 supervisor.md
```

Max 296 against a cap of 300. `05_RATIONALE.md` §C's account of the `Read`-vs-`wc -l` skew is
confirmed from the other side: the shell figures are 296 / 125 / 177 / 287 exactly, so §C's
phantom-trailing-segment explanation is right and CR-7's correction of the harvested insight (the
skew is uniform, not three-of-four) is the one to carry into the index.

Tool grants, unchanged (S5 companion to AC-11):

```
$ grep -n '^tools:' agents/*.md
gate-reviewer.md:4:tools: Read, Glob, Grep
code-reviewer.md:4:tools: Read, Glob, Grep
pm-orchestrator.md:4:tools: Read, Write, Edit, Glob, Grep, TodoWrite, Task
(+ 5 others, all unchanged)
```

## §5 — AC-10: the three cuts, executed

Working copies only. The live files were never opened for writing; the mutants live at
`<scratch>/mut/{pm,gr,cr}.md` and the cut is by exact substring so it cannot silently take a
neighbouring sentence.

Cut 1 — `agents/pm-orchestrator.md`, from `**You write that body verbatim**` through
`that absence means none was written.` (253 characters, spanning `:46-48`). **This is the CR-5
correction, not `02`'s prediction**: P3 and P4 are one semicolon-joined sentence in the shipped
bytes, so P4 dies with P3. Residue, read live from the mutant:

```
**Stage-3 / stage-5 transcription.** `gate-reviewer` and `code-reviewer` hold no write capability;
each returns its complete document body … under a header naming each present portion's target path.
  It adds and repairs nothing: no heading, no summary, … Before anything is written, check that …
```

P1, P2, P5, P6, P7 — **not** P4. AC-2 is unanswered and worse than `02` predicted: the file
establishes that a body arrives (P2) and that its author cannot write it (P1), constrains an act it
never establishes (P5's "It" has no antecedent), and now also states no disposition for a returned
rationale portion at all.

Cut 2 and 3 — `agents/gate-reviewer.md` and `agents/code-reviewer.md`, the sentence
`You return the complete body of both portions … verbatim, authoring no part.` (209 characters
each). Residue in `gr.md`:

```
## What you produce

**You hold no write capability.**

**The contract portion** — `docs/features/<task-slug>/03_GATE_REVIEW.md`. It opens with the line …
```

plus three antecedent-less anaphors that survive at `:32-33` ("the same transcription applies to the
same path") and `:40-41` ("transcribed to that path under the same arrangement"). No sentence names
any role in connection with any of the four declared paths; the classifier returns 0 write-act
statements. AC-1 is unanswered at both stages. `cr.md` is identical in construction.

The mutation therefore bites for the reason the design claims and in the shape `05_RATIONALE.md` §F
corrected it to. The sentences are load-bearing.

## §6 — The G-25 confound, adjudicated

**The claim.** The post-change author arm reported that its `tools: Read, Glob, Grep` line was
violated because it held a shell, and offered that as evidence against "only the tool list is
self-enforcing" — the premise carrying OQ-1's decisive leg. If true, the decline of the write grant
loses its main support and `agents/gate-reviewer.md:86` / `agents/code-reviewer.md:101` ("Your
`tools:` declaration — not this rule alone — is what enforces that") ship as a false sentence.

**The alternative explanation.** That arm was dispatched as `general-purpose` (C-7's published
choice) with the contract text **pasted into the prompt**. A general-purpose sub-agent has the full
grant; pasted frontmatter is data, not configuration. On this reading the shell is fully explained
by the dispatch type and the contract text had nothing to do with it.

**Why this matters procedurally.** This is the T-16 class exactly: *a fixture that produces a
striking result is not evidence until the alternative explanation is excluded.* The claim is also
the kind that gets harvested — "tool grants aren't real" is memorable, and `.harness/insight-index.md`
is permanent and capped at 30. Letting it through unchecked would be the expensive failure.

**What I could and could not test.** `agents/qa-tester.md:4` grants no `Task`, so I cannot dispatch
a real `harness-kit:gate-reviewer` and ask it to run a shell command. That is the decisive
experiment and it is not available to me; I name it rather than substitute for it. What I *can* do
is look for the class of evidence that would survive either explanation.

**ADV-6, run.** If a `tools:` line were merely advisory in this runtime, genuine review-stage
dispatches would sometimes hold a shell. Searching every stage-3 and stage-5 document in the
repository for both directions:

```
$ grep -rlniE "no shell|no execution|cannot run|holds no .?Bash|Read/Glob/Grep only" \
    --include='03_*.md' --include='05_*.md' docs/features/
→ 15 files, ≥13 distinct dispatches, both roles, spanning v0.39 … v0.46:
  ai-native-init · guard-cmd-chain (03 and 05) · harness-batch-skill · harvest-wrapped-insight
  hook-truth-derivation (03 and 05) · hook-truth-spec · hook-truth-status ·
  hook-truth-verify-scope · scripts-relocation · stage-model-tiering · review-write-path (03R, 05, 05R)
```

Representative, and unusually explicit — `_archived/hook-truth-derivation/03_GATE_REVIEW.md:185`:
"I have Read/Glob/Grep and no execution. Every item below is *consistent* with the artifacts I read
and *not* measured by me." And `_archived/hook-truth-status/05_CODE_REVIEW.md:4`: "this reviewer has
`Read`/`Glob`/`Grep` only — no shell."

Counter-instances — a review role claiming it ran a command:

```
$ grep -rniE "I ran|I executed|my (bash|shell) run|ran the command" \
    --include='03_GATE_REVIEW.md' --include='05_CODE_REVIEW.md' docs/features/
→ 2 hits, both "I ran that exact pattern / the design's own widened pattern" over files
  = a Grep-tool regex, which is granted. Zero shell instances.
```

And the matched pair that isolates the variable. The build a genuine dispatch loads declares the
same grant as the working tree:

```
$ grep -n '^tools:' ~/.claude/plugins/cache/…/0.44.0/agents/gate-reviewer.md
4:tools: Read, Glob, Grep          (code-reviewer.md:4 identical)
```

So both conditions ran under the **same declared grant**, and differed in exactly one thing: genuine
`harness-kit:` dispatch → no shell, in ≥13 observations; `general-purpose` dispatch with the contract
as prompt text → shell, in 1 observation. In this very task, stage 3 worked around the absence of
`wc -l` by reading line offsets (`03_RATIONALE.md:83`, and the withdrawn 294 figure at G-9) and
stage 5 recorded "stage 5 holds no `Bash`" as the reason RES-A and RES-D had to travel to me. Those
are costly workarounds no agent adopts if it has a shell.

**Ruling.** The alternative explanation is **confirmed**. G-25's claim as stated is an **artifact of
the reproduction method**, not a property of the runtime, and it does not reach permanent memory.

**What survives, and I am careful to keep it.** Dismissing the whole observation would be the
opposite error. The true, narrower statement is: **a contract delivered as text — pasted into a
prompt, or restated in a skill — carries no tool enforcement; only a registered agent definition
does.** That is not news against OQ-1 (it is precisely why the design keeps the duty in the
plugin-native contracts, OQ-3), and it is the same shape as two residuals already on the books:
RES-1 (the in-band G8 header *instructs*, it does not enforce) and RES-3/RES-4 (a role may run a
build of its own contract that is not the current one). It is filed as QA-4 in that narrowed form.

**What would reverse this ruling:** one genuine `harness-kit:gate-reviewer` or
`harness-kit:code-reviewer` dispatch, with no contract text in its prompt, that successfully runs a
`Bash` call. That is a one-dispatch experiment for a `Task`-holding role and it is cheap; until it
is run, the ≥13-to-0 observational split is what the record supports.

## §7 — What the probe could not tell me, stated once

Three limits, so no later reader mistakes this stage for more coverage than it bought.

1. **The message channel is untested.** Bodies reached the writers as scratch **file paths**. Every
   failure mode that lives in the message channel — truncation, elision, re-wrapping, the oversized
   return of B-4, the interior loss of RES-2 — is removed by the fixture, not survived by the
   design. P6(c), whose subject is a header *in a message*, has nothing to range over under a file
   hand-off; the control writer recorded exactly that and refused to pass it vacuously, which is the
   right behavior and also the reason P6(c) has no clean row.
2. **Observable (e) has no subject in the handover.** The artifacts are body-only:
   `returned_body_POST.md` line 1 is the declared opening line and no G8 header appears anywhere in
   it. Even had a header been captured, (e) as `02:437` writes it — "the returned message ended with
   the G8 header" — is unsatisfiable by a conforming message, because `agents/gate-reviewer.md:65`
   orders "a header, **then** the body". I report (e) as NOT MEASURED and QA-1 as the defect.
3. **The control validates the apparatus, not the sentences.** It is `HEAD` = v0.44.0 = pre-T-18,
   so its failure on (a) is over-determined: it declares no opening line at all, and *any*
   post-T-18 contract would produce the same differential. Necessity for **this task's** sentences
   rests entirely on AC-10's three mutations (§5). Reading the control's failure as evidence that
   G1/K1/P3 caused the observable would be the T-16 error committed in the other direction, and
   RES-B is right to have bounded it.

Together the two arms satisfy the T-16 discipline that neither satisfies alone: the control shows
the observable tracks contract text at all; the mutation shows *these* sentences are the ones that
carry it.
