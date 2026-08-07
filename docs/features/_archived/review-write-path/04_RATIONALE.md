> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

Opened on triggers: **T4.1** (about to record `DESIGN DRIFT` → read `02_RATIONALE.md`) and the
boundary rule's rows 12 and 13 (measurement narrative; captured tool runs longer than 5 lines).

## §D1 — The line-count measurement, and why C-5 was load-bearing

The gate carried G-9 as MINOR-open: its round-1 figure of 294 for `agents/pm-orchestrator.md` did
not reproduce in round 2, and it withdrew the figure rather than defend it. `02_RATIONALE.md:160-161`
defends the inherited numbers on a different basis — "294 / 287 / 167 / 114 are the last line
numbers of full reads of the four files, matching E-15's measured values".

Live `wc -l`, run before any edit:

```
  293 agents/pm-orchestrator.md
  113 agents/gate-reviewer.md
  166 agents/code-reviewer.md
  287 agents/supervisor.md
```

Three of the four are one lower than the inherited figure; `supervisor` matches. The obvious
suspicion — a missing trailing newline making `wc -l` undercount — is wrong:

```
agents/pm-orchestrator.md: wc-l=293 lastbyte=0a
agents/gate-reviewer.md:   wc-l=113 lastbyte=0a
agents/code-reviewer.md:   wc-l=166 lastbyte=0a
agents/supervisor.md:      wc-l=287 lastbyte=0a
```

Every file ends with `0a`, so `wc -l` *is* the physical line count, and it is the same expression
the gate itself evaluates — `verify_all.sh:451` is literally `n=$(wc -l < "$f")`. The inherited
figures came from reading the last line number of a full `Read`, which reports one line past the
end for these three files. `supervisor`'s match is a coincidence of that file, not a validation of
the method — which is precisely why a method that is right three times out of four is worse than
one that is right once, and why C-5 said "treat **no** count as measured until you run it".

The consequence was material, not cosmetic. The design's worst case was 294 − 9 + 12 = 297 against
a 300 cap with `verify_all` exiting 1 on any WARN. The true base was 293, and — see §D4 — C1 frees
5 rather than 6, so the true worst case was 293 − 8 + 12 = 297 as well. The two errors happened to
cancel. Had only the C1 error been present, the ceiling would have been 298; had only the base error
been present, 296. Neither would have breached, but neither was known before measuring.

Post-change, measured again:

```
  296 agents/pm-orchestrator.md
  125 agents/gate-reviewer.md
  177 agents/code-reviewer.md
  287 agents/supervisor.md
```

## §D2 — S5 in full (the AC-11 companion proof)

Identical before and after the change:

```
agents/code-reviewer.md:4:tools: Read, Glob, Grep
agents/developer.md:4:tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, TodoWrite
agents/gate-reviewer.md:4:tools: Read, Glob, Grep
agents/pm-orchestrator.md:4:tools: Read, Write, Edit, Glob, Grep, TodoWrite, Task
agents/qa-tester.md:4:tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
agents/requirement-analyst.md:4:tools: Read, Write, Edit, Glob, Grep
agents/solution-architect.md:4:tools: Read, Write, Edit, Glob, Grep
agents/supervisor.md:4:tools: Read, Write, Glob, Grep
```

This also re-confirms D-6's assertion that `AI-GUIDE.md.tmpl` `:49`, `:50`, `:52`, `:54` keep
"writes": analyst, architect, developer and QA all hold `Write`. Only rows `:51` and `:53` — the two
roles that do not — were corrected.

## §D3 — The K7 drift, argued at length

The design gave K7 an unusual shape: a mandatory check with a predicted null result, justified by
T-18 QA-12 (an instruction rendered only inside a schema example is silently dropped by a
by-reference reader). It is worth recording that the check found something, because the design's
own confidence that it would not is part of the evidence.

**The conflict.** After K2, `agents/code-reviewer.md` says two things about the same artifact:

- `:18-21` (schema): the returned body "is the **complete file content** — it begins with that line
  and ends with the `## Verdict` line", where "that line" is
  `> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).`
- `:108-152` (worked example), pre-change: fence-line 1 was `# Code Review`, fence-line 2 blank,
  fence-line 3 the declared opening line.

**Is the schema reading really literal?** Yes, and the design says so twice outside the contract
table. `02_RATIONALE.md:158-159`: the design "makes the opening line part of what the author returns
(G2/K2) rather than something the writer is trusted to prepend". `02_RATIONALE.md:181-182`: the
bracket is "begins with the declared opening line and ends with the `## Verdict` line … built
entirely from facts the contracts already state". P6(a) in `agents/pm-orchestrator.md` is now the
executable form of it, and AC-8(a) says "line 1 is the declared opening line".

So the conflict is real. Under the pre-change example, a stage-5 body written exactly as its own
contract demonstrates would trip P6(a) and be routed back unwritten — a live behavioural defect
introduced by this task, in a file whose internal consistency is R-8's whole subject.

**Which side gives?** Four pieces of evidence point the same way.

1. *Produced artifacts already do it.* `docs/features/review-write-path/03_GATE_REVIEW.md:1` is the
   marker line, no H1 — written this round under the T-18 schema. `01` E-10 records `06:1` likewise
   for the QA report. The stages whose schema declares an opening line put it first.
2. *No mechanism requires an H1.* `agents/supervisor.md:97,:99` validates stage-3 and stage-5
   documents on required headings (`## Findings`, `## Verdict`) and a 20-line minimum. `verify_all`
   does not read stage documents at all (`docs/features/` is exempt at `verify_all.sh:637`,`:677`).
   Nothing anywhere greps for `# Code Review`.
3. *K7's literal requirements survive the change.* It asks that the fence "still show the opening
   line", "end with `## Verdict`", and "gain no round or changelog section". All three hold; only
   the parenthetical prediction "no content change is expected" is falsified, and a prediction is
   not a constraint.
4. *`agents/gate-reviewer.md` has no fenced example*, which is exactly why stage 3 had no conflict
   to expose and why the design — which reasoned mostly from the gate-reviewer side, since AC-8
   probes it — did not see this one.

**The alternative, stated fairly.** Keep `# Code Review` and relax K2/P6(a)/AC-8(a) from "begins
with" to "carries". That is defensible: every archived `05_CODE_REVIEW.md` and `03_GATE_REVIEW.md`
in `docs/features/_archived/` opens with an H1, and the `> Contract portion.` marker is a T-18
addition (unreleased v0.46.0) that historical documents predate. But it costs the bracket its
mechanical checkability — "carries the line somewhere" is not a first-line test — and RES-2 already
concedes interior loss; widening the bracket to a search would concede the tail case too, which is
G-7's cleared finding. So the relaxation trades a closed finding for a cosmetic. I took the other
side, and flagged it so stage 5 can take this one instead. If it does, the repair is a route-back to
the architect, not a developer edit, because it changes P6, AC-8(a) and the D-4/D-5 G2/K2 rows.

## §D4 — Why C1 frees 5 net lines and not 6

The design measured C1 as "7 physical lines (`:140` blank, `:141` fence open, `:142-144` body,
`:145` fence close, `:146` blank)", gross 10 with C2, net 9 after a 1-line fold cost. Q-2 repeats it.

`:140` and `:146` are the blank lines separating the fence from the prose paragraph above and the
"In partitioned mode" paragraph below. Deleting the fence removes the need for **one** of them, not
both — the two surviving paragraphs still need a blank between them. So the deletable set is
`:140` plus `:141-145` = 6 lines, and the fold spends 1 (one sentence becomes two), for a net of 5.
Gross is 9, not 10; net 8, not 9.

Measured confirmation: 293 − 5 − 3 + 11 = 296, and `wc -l` returns 296.

This is why the transcription block was re-wrapped once. At ~110 columns it came to 11 text lines
and the file measured 297 — inside the design's ceiling but with zero margin against its own stated
figure. Re-wrapping the same sentences to ~130 columns (a width the file already uses freely — its
longest line is 643 characters) gave 10 text lines and 296. No P-item was dropped, no text moved to
another file, and no line was appended past the cap. That is exactly the escape hatch D-3 authorises:
"the Developer condenses further inside this file and publishes the site".

## §D5 — The `--hidden` finding, in full

`02`'s S1 is specified as:

```
rg -n '03_GATE_REVIEW|05_CODE_REVIEW' -g '!docs/features/_archived/**'
```

Run literally, it returns 25 files. Run with `--hidden` it returns 25 lines more, and every one of
them is a site the design's ⊕ rows were added to cover:

```
skills/harness-init/templates/backend/.harness/agents/dev-api.md.tmpl:48
skills/harness-init/templates/backend/.harness/agents/dev-db.md.tmpl:48
skills/harness-init/templates/backend/.harness/agents/dev-services.md.tmpl:49
skills/harness-init/templates/fullstack/.harness/agents/dev-backend.md.tmpl:44
skills/harness-init/templates/fullstack/.harness/agents/dev-db.md.tmpl:46
skills/harness-init/templates/fullstack/.harness/agents/dev-frontend.md.tmpl:49
skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl:15
skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md:32,:33,:122
.harness/rules/60-tool-handoff.md:32,:33,:125
.harness/insight-index.md:19,:46,:60,:61
.harness/rejected-decisions.md:187,:287
.harness/scripts/test-verify-i6.sh:586,:587,:626,:627
.harness/scripts/test-verify-i6.ps1:635,:665,:666
```

The trap's shape is worth naming precisely: the search **does not fail**. It returns 25 files
including `agents/`, `docs/`, `skills/*/SKILL.md` and both `AI-GUIDE.md.tmpl` lines — a result that
looks complete and reconciles against most of the ledger. What is missing is exactly the
distributed-twin class, which is the class R5 identifies as the highest risk and the class the ⊕
rows exist to close. A developer reconciling S1-as-written against the ledger would find the six
`dev-*.md.tmpl` rows unreproducible and could plausibly conclude the architect had over-listed them.

The design's own headline about search insufficiency is about *line* granularity (S1 ∪ S2 finds
`docs/workflow.md` but not `:18`). That is true and I reproduced it. This is a second, independent
insufficiency at *path* granularity, orthogonal to the first. Both had to be corrected for the C-4
publication to be total.

## §D6 — DEV-1: what a shell established that a reader could not

D-8 was assembled by `Read`/`Glob` and correctly refused to assert the *cause* of the version gap,
handing it over as DEV-1. The decisive command is one that has no `Read` equivalent:

```
$ for f in <cache>/agents/*.md; do
    git show HEAD:agents/$(basename $f) | diff -q - "$f" && echo "== HEAD"
  done
code-reviewer.md: cache == HEAD
developer.md: cache == HEAD
gate-reviewer.md: cache == HEAD
pm-orchestrator.md: cache == HEAD
qa-tester.md: cache == HEAD
requirement-analyst.md: cache == HEAD
solution-architect.md: cache == HEAD
supervisor.md: cache == HEAD
```

Reading the cache file tells you it differs from the working tree. Only a shell can tell you it is
*identical to `HEAD`*, which is what distinguishes "the cache lags a published release" from "the
working tree has not been committed". It is the second. `HEAD` is `cb0ed57 feat(v0.44.0)`, the cache
declares `0.44.0`, and the `0.46.0` claim exists only in two uncommitted JSON files. There is no
missing publish step; there is a missing commit.

This tightens R8 rather than loosening it. The four-link chain is intact and unstarted, so RES-3
stands exactly as written and AC-8 must remain the controlled reproduction. It also means the
0.44.0 differential control is *two commits* behind in content terms but exactly one release behind
in version terms — the gate's G-18 bound ("this control validates the apparatus rather than
isolating this task's sentences") is unaffected.

Method note, per the T-22 insight: every negative here comes from a live run.
`git status --porcelain agents/ .claude-plugin/` was executed, not read off a dispatch-carried
snapshot, and it returns ten modified paths including all eight `agents/*.md`. `ls .claude/agents`
and `ls .harness/agents` both return "No such file or directory" — the O-5 negative, established by
a command whose failure mode is loud.

## §D7 — Wording choices that were not free

Three places where the design states a constraint and the wording had to be chosen carefully, because
the write-act uniqueness rule is decided by wording alone (G-13: conjunct (i) is vacuous in a
second-person document, so uniqueness rests entirely on conjunct (ii)).

1. **P8's marker.** Q-8 forbids "a write verb plus an actor". I used "— see the transcription rule
   below": no verb of any kind, no actor. "transcription" appears only as the *name* of the rule
   being pointed at. Had I written "— transcribed by you, below", the file would have carried two
   write-act statements and AC-10's P3 mutation would have left a survivor that answers AC-2.
2. **K5.** The natural rewrite of Hard rule 2 is "…you author the body and the PM writes it", which
   would be a second write-act statement in `code-reviewer.md` if it named a declared path — it does
   not, so it would survive the rule, but it *would* survive the K1 mutation and weaken AC-10. I
   wrote "Your own stage document you **author** but do not persist: see `## What you produce`",
   which answers AC-4 with the same answer and dies with K1.
3. **G8/K8's header.** "returned to its author rather than persisted as a partial file" — "its
   author" is a generic noun, not a role name, and "persisted" is applied to no path. The header
   names no role, as C-3 requires, while still carrying return-don't-truncate.

## §D8 — P6 stated positively

The design states P6 as three conditions that make a return *non-intact*. I wrote the check
positively. The mapping is exact:

| design (negative) | contract text (positive) |
|---|---|
| (a) the contract body does not begin with that document's declared opening line | "check that the body begins with that document's declared opening line" |
| (b) it does not end with its `## Verdict` line | "that it ends with its `## Verdict` line" |
| (c) the header names a target path for which no portion is present, **or** the author reports it could not return whole | "that every header-named path has a portion present with no author-reported partial return" |
| on any of them nothing is written at all; route back; record the reason in `PM_LOG.md` | "on any failure **nothing is written at all** — route the round back to that reviewer and record the reason in `PM_LOG.md`" |

The positive form is 3 lines shorter at the wrap width used, which the budget needed. It is
logically equivalent and preserves the ordering constraint ("Before anything is written").
