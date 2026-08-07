# PM_LOG — T-17 `guard-cmd-chain`

- Mode: **full** (stages 1-7)
- Dispatched by: `/harness-stream` drain (operator-authorized interleave, security task)
- deferred-human mode: **defer, do not ask** → any human-reserved point returns
  `BLOCKED: NEEDS-HUMAN — <ask> — <what unblocks it>`
- Entropy-watch cadence at stage 7: **skipped** (stream owns that boundary, per dispatch)

## Task start checks

| Check | Result |
|---|---|
| `.harness/intervention.md` present? | No — nothing to consume |
| `.harness/agents/dev-*.md` present? | None → **single Developer mode** (`harness-kit:developer`) |
| Related history in `docs/tasks.md` | **T-14 `hook-truth-status`** explicitly surfaced this bypass out-of-band: *"`guard-rm.sh` only inspects the first verb of each top-level PIPE segment (`echo hi && rm <outside>` passes) — pre-existing, needs its own task."* This task is that task. Also related: **T-12 `resilient-hooks`** (guard hook is fail-CLOSED, lives in gitignored `.claude/settings.local.json` in this repo), **T-13 `hook-truth-spec`** (`hook-spec` declares guard-rm fail-CLOSED; also the standing operator PowerShell debt). |
| `docs/dev-map.md` read | Yes — dev/test stages touch `.harness/scripts/guard-rm.{sh,ps1}`, `test-guard-rm.{sh,ps1}`, `templates/common/.harness/scripts/`, `.harness/rules/75-safety-hook.md` + template twin |

## Insight-index entries surfaced to downstream (applicable subset)

Passed into the dispatch prompts of the stages named:

1. **(→ Dev, QA)** 2026-06-21 · bash 5.2 enables `patsub_replacement` by default, so an unescaped `&` in the replacement of `${var//needle/repl}` expands to the matched text; use the repo's literal-replacement helper (`str_replace_all`) for any rewriting. *(Named as a hazard in the dispatch too.)*
2. **(→ Dev, QA)** 2026-07-31 · A hook/command value interpolated into an `eval`-based `assert` helper silently truncates a test driver on unix — the residue ends the run mid-suite with **no `=== Result ===` line and no FAIL**. Detection signal is the *absence* of the summary line, not a red row. Directly relevant: this task feeds command strings containing `&&`, `;`, `|`, quotes and subshells into `test-guard-rm`.
3. **(→ QA)** 2026-07-31 · A pass/fail tally can be fabricated even when its value is correct — cross-check a reported tally against **the artifact that allegedly produced it**, not against arithmetic.
4. **(→ SA, Dev)** 2026-06-21 · PowerShell that an agent cannot execute is not validatable by symmetry and ships broken three ways (whole-file parse before execution → a syntax error in a never-taken branch is fatal; `$isWindows` automatic-variable collision; the `.sh` quoting idiom does not port). An operator PS run is a mandatory release gate.
5. **(→ SA, QA)** 2026-07-31 · A state/decision table is only executable if it is **total**; totality breaks on the input class nobody enumerated. Evaluate rows independently (no short-circuit) to make "exactly one state" falsifiable. Applies to any new command-splitting grammar table.
6. **(→ SA, Dev)** 2026-06-09 / 2026-06-09 · This repo has an explicit precedent (T-016) for eliminating a defect class by better design **without inflating the verify_all check count** — the gate stayed 32. The dispatch names the same constraint.
7. **(→ QA)** 2026-06-20 · A gate that checks artifact PRESENCE is load-bearing only against a missing artifact; a mutation test proving a check is real must mutate the **artifact**, not the check's own array.

## Stage log

### Stage 1 — requirement-analyst → `01_REQUIREMENT_ANALYSIS.md` · verdict **READY**

Intervention check before dispatch: none present. Intervention check after stage: none present.

- Code reading **confirms** the stream's reproduced table on all five rows (no contradiction):
  `tokenize()` splits on space/tab only, `split_pipes()` on `|` only, verb = first token after
  optional `sudo`. Every bypass row traced to specific lines.
- Two findings the dispatch did not name, both load-bearing:
  **E-1** the documented `HARNESS_ALLOW_OUTSIDE_RM=1 <cmd>` *command-text* override works only by
  accident (unknown-verb path, **no audit line**), and making assignment prefixes transparent would
  turn it into a BLOCK; **E-2** the guard is wired fail-closed with no `|| exit 0`, so a malformed
  guard blocks every Bash call for every downstream agent.
- Coverage claim delivered as a **total** 19-row table (row 19 + monotonicity invariant IS-2 +
  fail-closed row 18), which is the shape the totality insight asked for.
- Biggest false-positive hazard identified is *not* chained cleans but **here-document bodies and
  the test harness's own invocation** (AC-3 L9/L11) — a quote-unaware splitter would make the suite
  self-blocking.

**PM decision: ADVANCE to stage 2.** No rollback. Six Open Questions carry `Recommended:` answers;
under deferred-human mode + Mode 2 (balanced) I adopt all six recommendations as the Architect's
binding input, logged here as autonomous calls because **none weakens the guard relative to today**
(each either narrows what passes, or discloses a residual without changing behaviour):

| OQ | Adopted | Why it is not a human-reserved call |
|---|---|---|
| OQ-1 command-text override | (a) recognize + audit it | Strictly better than today (today it passes **silently**); also closes the `FOO=1 rm` bypass |
| OQ-2 `cd` modelling | (a) out of scope, documented residual | Declining to widen scope; behaviour unchanged on that axis |
| OQ-3 `/bin/rm` · `\rm` | (a) out of scope, disclosed | Bound by the operator's "verb set unchanged" constraint |
| OQ-4 pin the driver count | (a) pin bash key only, no new check | Additive ledger line; AC-8 holds the gate at 32 |
| OQ-5 `bash -c` / `sh -c` | (a) in scope via existing depth-2 recursion | Adds a reachability path, not a verb — inside the operator's scope |
| OQ-6 unforeseen over-block | (a) fix-if-realistic else record with rationale | Fail-closed posture; an over-block is a usability cost, not a safety defect |

If the operator disagrees with any of these, the fix is a `REDIRECT` intervention or a follow-up row —
none of them is irreversible.

### Stage 2 — solution-architect → `02_SOLUTION_DESIGN.md` · verdict **READY**

Intervention check after stage: none present. Single-developer mode (no `dev-*` partitions), so no
partition-assignment section was requested or produced.

- **Chosen shape**: a single-pass, quote/here-doc/comment-aware **position scanner** whose output is
  **unioned with the byte-unchanged `split_pipes()`** — so IS-2 monotonicity holds *by construction
  and is provable by inspection*, and the path-resolution code that preserves AC-2/AC-5 stays
  byte-unchanged. Scanner is a lexer (5 states × 17 input classes, explicit nesting stack), total,
  with every unresolvable end-state → exit 2.
- **Three findings that change the work** (none were in my dispatch):
  1. `test-guard-rm.sh`'s `|` row delimiter **cannot express** AC-1 rows d/q or AC-3 L5/L11 — those
     rows would be silently truncated into *different* commands that still pass, i.e. **fabricated
     green**. Row encoding must become a stride-4 flat array.
  2. Newline coverage (IS-1 row 2) is **python3-dependent today** — the no-python3 JSON fallback
     unescapes only `\"` and `\\`, so AC-1 row f would pass **vacuously** on a python3-less host.
  3. The real latency bottleneck is **pre-existing and multiplied** by this change: ~20 `printf | tr`
     forks *per segment*, and segments go from 1-2 to 5-15. Replaced with a bash-3.2-safe glob
     matcher (`${v,,}` would be a whole-file parse error on macOS — the bricking risk).
- **Sequencing under NFR-3**: the *template* copy is unwired, so it is the staging area — `bash -n`,
  drive it via a new `[guard-path]` argument (which AC-10's mutation proof needs anyway), then
  promote with one `sync-self`. The live guard changes exactly once, to an already-green file.
  Recovery if it ever bricks is **Write-tool only** (`git checkout` is itself a Bash call).
- 14-surface lockstep ledger produced, plus an explicit "verified NOT to change" list.
- Architect appended one glossary term (**Command position**) to `CONTEXT.md` — inside its standing
  lazy-maintain convention.

**PM decision: ADVANCE to stage 3.** No rollback. Three items are flagged by the architect as
*decisions* rather than omissions and are dispatched to the Gate as explicit adjudication asks — the
union anchor, the AC-3 **L10** internal tension (table header says exit 0; that row's own Why column
says "no worse than pre-change", and it already BLOCKs today), and the driver row-encoding defect.

### Stage 3 round 1 — gate-reviewer → `03_GATE_REVIEW.md` · verdict **BLOCKED ON DESIGN**

Intervention check after stage: none present.
Note: the gate-reviewer agent has Read/Glob/Grep only and **cannot write files**; PM persisted its
report verbatim to `03_GATE_REVIEW.md` (recorded in the doc header). This is a framework quirk, not
a stage irregularity.

The gate did the job the dispatch asked for — it independently re-derived the design's claims from
code and **falsified three load-bearing ones**:

- **F-1 (FAIL)** the scanner keeps one scalar quote state, so `$( )` opened inside `"…"` never
  restores/resets quoting → `echo "$(true && rm -rf /etc/x)"` **ALLOWs**. A false negative — the
  forbidden direction for a security fix. The offending table cell is also non-total (two readings).
- **F-2 (FAIL)** the headline "monotonicity provable by inspection" is **false**: the nested-pwsh
  call site changes from classify-whole to classify-decomposed, so
  `pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"` flips **BLOCK→ALLOW**. Invariant must be
  restated as "P contains `s` itself at every depth", and IS-2 now needs a **differential test**.
- **F-3 (FAIL)** the carrier-vs-`find` branch ordering is self-contradictory and *both* literal
  readings break an AC (either `find /etc -delete` starts passing, or AC-1 row o passes).
- **F-4 (FAIL)** the residual list **overstates coverage** — "here-doc bodies cannot produce a
  position" is false under the union, because the retained pre-change pass splits the *whole* string
  on `|` with no here-doc awareness. This is precisely the overstatement class this task exists to
  avoid, so it is a real finding, not pedantry.
- **F-5** driver rows containing `$(` written double-quoted would **execute `rm -rf OUT` at
  driver-load time**; **F-6** the PS lexer's out-of-range `Substring` throws → exit **1**, which
  Claude Code treats as non-blocking, i.e. the Windows guard **silently disarms** (fail-open);
  **F-7** the assignment glob is malformed (`A=1` unmatched); **F-8/F-9/F-12** WARNs.
- Two WARNs route to **requirement-analyst**: **F-10** AC-3's header contradicts IS-2 for row L10;
  **F-11** AC-4's corpus ("session transcript or `git log`") is **unobtainable by any agent**, so the
  criterion is unverifiable as written.

It also corrected the architect's *diagnosis* of the driver defect (those rows FAIL loudly, they do
not fabricate green) and independently re-ran the fan-out audit, confirming **no missed lockstep
surface** — the failure mode that rolled back T-13/T-03/T-12.

**PM decision: ROLLBACK.** Design gaps → `solution-architect` (F-1…F-9, F-12); requirement gaps →
`requirement-analyst` (F-10, F-11). Per the routing table, only the author of a document may fix it.

- Rollback count at stage 2 (design): **1**. Rollback count at stage 1 (requirement): **1**.
  Neither is near the 3-consecutive stop rule.
- The two are dispatched **in parallel** (the gate itself said they are independent). To keep them
  from diverging I bind the RA's corrections to the exact text the gate pre-answered, and hand the
  architect that same corrected text — so neither waits on the other.
- Not re-opened: the six OQ rulings stand; the gate reviewed only whether the design *honours* them.

### Stage 1 round 2 — requirement-analyst → `01_REQUIREMENT_ANALYSIS.md` amended (F-10, F-11)

Four surgical hunks, nothing else touched: a round-2 changelog block; AC-3's header now reads
"exit 0 for every row **except L10**" with an explicit paragraph stating L10's expected verdict is
**BLOCK (exit 2)** and that QA records it as a PASS when it exits 2; row L10's Why column rewritten
to lead with that verdict and to frame it as **one instance of the F-4 class**, not a singleton;
AC-4 retitled and restructured into proof-obligation / corpus / auditability / pass-condition.

Two things the analyst did beyond the brief, both good:

- It **verified the corpus sources itself instead of trusting the gate**, and corrected one of the
  gate's pre-answers: `AI-GUIDE.md` lists script *paths* in prose, not `bash .harness/scripts/*`
  invocations, so that source is low-yield and a line counts from it only when written as a full
  invocation. This forecloses a Developer claiming a batch of lines that do not exist. It also
  confirmed the ≥40 floor is comfortably reachable (one source alone yields 269+ lines).
- AC-4's pass condition now states that **any BLOCK→ALLOW flip at any recursion depth fails AC-4 and
  IS-2 — not recordable, not waivable**, which is the right asymmetry for a security fix.

It also flagged (rather than silently fixing) a pre-existing round-1 cross-reference typo inside the
text it was rewriting (AC-4 pointed at OQ-4 where it meant OQ-6a). Cross-criterion consistency was
checked against AC-5 and AC-4 and holds: L10 is in neither the AC-1 nor the fail-closed set, and it
is BLOCK before and after, so it is not a flip.

**PM: requirement side of the rollback is CLOSED.** Awaiting the architect's round-2 amendment
before re-gating.

### Stage 2 round 2 — solution-architect → `02_SOLUTION_DESIGN.md` amended · verdict **READY**

Intervention check after stage: none present. All ten findings resolved; the gate's §4 "verified
correct" list carried through untouched. Highlights:

- **F-1**: frames now save/restore **buffer + quote state**, inner buffer starts at `NORMAL`, and the
  non-total `)`×DQ exception is *deleted* rather than clarified. Re-verifying totality forced two
  closers the round-1 table lacked (`}`×PARAM, `))`×ARITH) — without them `echo "${HOME}"` would
  have blocked. That is the totality discipline paying off exactly as intended.
- **F-2**: invariant restated to `P = [s] ∪ split_pipes(s) ∪ split_positions(s)`; "provable by
  inspection" **explicitly withdrawn** in both §1 and §12.
- **F-9**: **fixed rather than recorded** (one `sq_ansi` bit), justified under OQ-6(a) as a form a
  developer really types (`git commit -m $'don\'t …'`), with a wrong flag failing closed.
- **F-8**: re-deriving the fast-path list from the final table found a **missing** entry — `\` — that
  was load-bearing (`echo \'a|b` diverges from `split_pipes`). The WARN was worth raising.

**One deliberate deviation the architect disclosed rather than buried**: it adopted gate condition
C-1 *literally* (`{s}` at **every** depth, including 0) instead of the strictly-minimal "depth ≥ 1".
The literal form adds one new ALLOW→BLOCK class (top-level `|`, destructive/carrier leading verb,
absolute outside path in a later stage, e.g. `rm -rf ./build | tee /tmp/x.log`); the minimal form
would add none. Its reason: a depth-conditional flag **fails open** when set wrong. It pre-declared
the class in §10.3 and offered the one-line reversal. This is a genuine safety-vs-false-positive
trade and it goes to the Gate for adjudication — I am not ruling on it as a router.

Also disclosed: `02_SOLUTION_DESIGN.md` is ~746 lines against rule 70's **500-line soft cap** for a
stage doc, after a compression pass (round 1 was 579). Routed to the Gate as a discipline item.

**PM decision: RE-GATE (stage 3 round 2).** Both upstream documents are amended and mutually
consistent by construction (each cites the other's change).

### Stage 3 round 2 — gate-reviewer → `03_GATE_REVIEW.md` (round-2 section appended) · verdict **APPROVED FOR DEVELOPMENT (with 15 conditions)**

Intervention check after stage: none present. Report again persisted verbatim by PM (gate has no
Write tool).

All twelve round-1 findings **closed**, each re-verified by re-running the original counterexample
cell by cell rather than by reading the amendment's claims. Nothing round 1 approved was broken.
The gate also re-probed the *new* mechanisms and found five residual specification gaps — all
**monotone** (none can lose a pre-change BLOCK) — and converted them into Developer conditions with
a red test row attached, rather than spending a third round on prose. I agree with that calibration.

Three gate outputs that change what downstream must do:

1. **`verify_all` exits 1 on `warns > 0`** (`verify_all.sh:823-825`) — the architect's framing that a
   WARN is status-neutral was wrong. So the I.2 rule-doc size cap is a **hard** AC-8 requirement:
   `.harness/rules/75-safety-hook.md` must land ≤200 lines (136 today).
2. **The literal C-1 adjudication** (the item I explicitly refused to rule on as a router) — gate
   **accepts the architect's literal form** and requires it *not* be reverted, on evidence I could
   not have supplied: it grepped the corpus and found **zero** real instances of the over-block
   shape, found that the literal form also closes a *depth-0* false negative the minimal form leaves
   open, and noted the minimal form's failure direction is **silent and open**. It attached C-14
   (test-pin the over-block) so a future maintainer cannot "fix" it and silently re-open F-2.
3. **Doc-size ruling**: `verify_all` does **not** measure stage docs in either shell, so rule 70's
   500-line cap on `02_SOLUTION_DESIGN.md` is policy without a mechanism. Gate ruling — accept the
   ~746-line overage with rationale recorded rather than spend an architect round; drop the design's
   §0 changelog at delivery. **Recorded here as required: this task's design doc ships at ~1.5× the
   soft stage-doc cap by deliberate decision, because the over-cap content is specification (the
   state table, the deliberate §3.4/§6 duplication that exists *because* their disagreement was
   F-3, and the residual list that is the task's deliverable).**

**PM decision: ADVANCE to stage 4 (development).** Stage gate satisfied — stage 3 produced an
explicit approval verdict. Rollback tally: stage 2 = 1, stage 1 = 1, stage 3 = 0 consecutive.
Single-developer mode → dispatch `harness-kit:developer` with the 15 conditions as binding.

### Stage 4 — developer → `04_DEVELOPMENT.md` · verdict **READY FOR REVIEW**

Intervention check after stage: none present.

**Gate for stage 5 satisfied**: `verify_all` **PASS 32 / WARN 0 / FAIL 0**, quoted from its run;
identical to the pre-dispatch baseline, check count held at **32** (no new gate check — the T-016
precedent held).

Captured tallies, each quoted from the run that produced it (never derived — the T-12 fabricated-
tally lesson):

| Run | Result |
|---|---|
| `test-guard-rm.sh` vs promoted guard | `PASS: 81 / FAIL: 0` (was 17) |
| `test-guard-rm.sh` vs **pre-change** guard (`git show HEAD:`) | `PASS: 49 / FAIL: 32` — anti-revert proof |
| AC-4 differential, 55 sourced corpus lines | identical 51, ALLOW→BLOCK 4, **BLOCK→ALLOW 0**, UNKNOWN 0 |
| `test-init.sh` / `test-real-project.sh` collateral | `391/0` / `90/0`, `=== Result ===` present in both |
| Mutations (scanner / carriers / C-1 / prefix) | 18 / 7 / 1 / 8 red rows |

The live-guard sequencing held: the template copy was the staging area, and the live guard changed
exactly once per shell, to an already-green file. All fifteen gate conditions C-1…C-15 report DONE
with per-condition evidence. The `=== Result ===` presence check was performed explicitly, which is
the exact T-13 failure signal.

**Four items the developer surfaced rather than buried** — routed to Code Review as explicit
adjudication asks:

1. **DESIGN DRIFT** — a here-doc terminated by end-of-input is accepted instead of failing the parse
   as design §3.1 says. Rationale: the design's reading would BLOCK every `cat > f <<'EOF' … EOF`
   whose terminator lacks a trailing newline — the toolchain-seizure risk R1 exists to prevent.
   Direction is ALLOW→ALLOW so IS-2 is untouched, and a genuinely unterminated here-doc still BLOCKs.
2. **DESIGN DRIFT** — design §10.3's F-9 evidence row is **wrong**: `echo $'it\'s fine'` has *three*
   apostrophes, so the retained `tokenize()` BLOCKs it pre-change too (captured). `sq_ansi` is
   implemented as designed but is unobservable at top level, so ANSI-C strings are recorded as an
   accepted over-block rather than **claimed fixed**. That is the coverage-honesty discipline of this
   task applied against the design's own claim.
3. **NFR-1 miss, reported not hidden** — typical commands got *faster* (49→46 ms; redirecting
   39→33 ms) but the 8192-char worst case is +764 ms against a +20 ms budget. Profiled root cause:
   bash `${s:$i:1}` is O(i), so the **pre-change** guard already paid 1487 ms before any new code ran.
   Per NFR-1's own instruction the rule doc was corrected to the measured truth — the "under 50 ms"
   claim was never true.
4. **Four AC-4 lines flip ALLOW→BLOCK**, all one isolated class (a backslash-escaped quote pair
   *spanning* a top-level separator — the JSON-escaped Windows `hook-spec` byte-forms). Recorded per
   OQ-6(a) and pinned by test rows; the **live unix hook byte-form does not self-block** (exit 0,
   verified) — which is the case that would have mattered.

**PowerShell**: `pwsh` is **not installed on this host**, so the twin was neither run nor even
parse-checked. Seven items added to the standing operator PS list; one is a security item (the
length-guarded lookahead + `try/catch`, because an escaping error exits 1 and silently *disarms* the
Windows guard). No frozen T-13 item was touched and no PS baseline key was invented.

**PM decision: ADVANCE to stage 5 (code review).** `verify_all` PASSED in the development doc, which
is the stage-5 entry gate.

### Stage 5 round 1 — code-reviewer → `05_CODE_REVIEW.md` · verdict **CHANGES REQUESTED** (0 CRITICAL / 1 MAJOR / 5 MINOR / 5 NIT)

Intervention check after stage: none present. Report persisted verbatim by PM (reviewer has no
Write tool). Axis status: standards-conformance worst = MINOR; spec/design-fidelity worst = MAJOR;
aggregate = MAJOR, so the masking invariant correctly forbids an APPROVED verdict.

The reviewer attacked the guard independently rather than auditing the report, and **re-derived the
anti-revert tally from the code**: it enumerated which of the 81 rows must be red against the
pre-change guard (17 flipped AC-1 rows + 15 others) and got **32**, matching the developer's
captured `PASS: 49 / FAIL: 32` exactly. It also cross-checked the mutation table against its own
traces, including a row that correctly appears in *neither* mutation list. That is the T-12
fabricated-tally lesson applied properly — checking a tally against the artifact that produced it.

Its independent smuggling attempts found exactly **one** false negative in the whole change (A-3).

**PM decision: ROLLBACK to stage 4, plus one requirement-stage record.** Rollback tally: stage 4 =
1 (first), stage 1 = 2 non-consecutive amendment rounds, stage 2 = 1. Nothing near the
three-consecutive stop rule.

#### Mode-2 autonomous decision — A-1 (the MAJOR): NFR-1's +20 ms clause is **WAIVED**, not blocked on

Point · options · choice · rubric basis, per `25-decision-policy.md`'s audit-trail requirement:

- **Point.** The 8192-char worst case measures +764 ms against NFR-1's "+20 ms" clause. Accept the
  miss and record it, or hold the task and rewrite the scanner's hot loop.
- **Red-line check first.** Not red line 5 (security-sensitive): the reviewer verified the *security*
  behaviour is unaffected, the command is truncated to 8192 first so the worst case is bounded at
  ~2.3 s, it **cannot approach a hook timeout**, and there is **no fail-open path** — that last point
  is the only one that would have made this a security decision. Not red line 1 (nothing
  irreversible), not 3 (declining extra work is not scope expansion), not 6 (I am not uncertain —
  the reviewer supplied measurements and an arithmetically self-consistent root cause).
- **Choice.** Waive the numeric clause; keep the doc correction the developer already made; open a
  follow-up rather than rewriting a live fail-closed hook's hot loop inside a security task.
- **Rubric basis.** *"Profile before optimizing — fix the measured bottleneck, not the
  obvious-looking suspect"* (it was profiled: bash `${s:$i:1}` is O(i), and the **pre-change** guard
  already paid 1487 ms of the 2251 ms, so +20 ms was infeasible for *any* added pass — a requirement
  defect as much as a code defect); *"Lightweight over heavy — the smallest thing that meets the
  bar"*; *"Honest reporting, always"* (the miss is recorded with real numbers, not absorbed).
  Typical commands got **faster** (49→46 ms), which is the path that actually runs.
- **Reversibility.** Fully reversible: the mitigation the reviewer names (chunked indexing) is a
  constant-factor change that does not alter the algorithm's shape.

Because this waives a clause **authored by the requirement-analyst rather than by the operator**, I
route the record to its owner (stage 1) instead of writing it myself, and I will surface it
prominently in the return summary so the operator can reverse it if they disagree.

**Routing of the rest** — A-2, A-4, A-5, B-1 and the NITs to the **developer** (documentation +
dead-code, no behaviour change). **A-3 to the developer as a fix, not a disclosure**: the reviewer
mildly preferred the fix, it is one flag in each shell, it fails closed if wrong, and leaving a known
false negative undisclosed in a task whose deliverable is coverage honesty is the worse option. The
resulting one-line divergence from design §3.1 row 15 joins drifts 1 and 2 as an **archive-time doc
correction**, which the reviewer already adjudicated as the right treatment — an architect round here
would buy prose, not safety.

### Stage 1 round 3 — requirement-analyst → NFR-1 amended (A-1 waiver recorded)

Two edits, nothing else moved. NFR-1 now leads with **WAIVED**, states plainly "it was not met, and
the delivered guard does not meet it", puts the ~38× miss *before* any mitigating fact, and carries
the measured table, the O(n²) root cause, the bounding facts, the satisfied second clause, the
chunked-indexing follow-up with its fail-closed caveat, and who decided on what rubric basis. That
is the shape a waiver has to have to be reviewable rather than absorbed.

**The analyst caught an honesty defect in my own instruction, and it is right.** I told it to record
that "a follow-up pool row is **opened**" — but no such row exists anywhere. Writing that a row
exists when it does not is precisely the overstatement class this task exists to eliminate, and it
would have shipped inside the document that adjudicates overstatement.

I am **not** fixing it by creating the row. The pool belongs to `/harness-stream`, and
`25-decision-policy.md` red line 3 forbids inventing tasks the operator did not request — a
recommendation is mine to make, a schedule is not. So the wording must come down to a recommendation,
which needs one more surgical requirement-analyst pass (I cannot author requirement text myself, and
downstream cannot edit upstream). Queued behind the developer's round 2 so the two do not collide.
The follow-up will also be surfaced explicitly in `07_DELIVERY.md` and in the return summary to the
stream, which is the channel that can actually schedule it.

### Stage 4 round 2 — developer → `04_DEVELOPMENT.md` (round-2 section) · verdict **READY FOR REVIEW**

Intervention check after stage: none present. All nine routed findings dispositioned; **A-1 left
untouched exactly as instructed** (no hot-loop change, no chunked indexing, requirement doc not
opened for writing) — the boundary held.

- **A-3 FIXED, not disclosed**: new scanner row 12 records the index at which a redirection operator
  is *actually appended*; row 15 tests that index instead of the raw byte at `i-1`. Pinned by
  `R1`/`R2` → BLOCK and `R3` (a real `>&` dup-redirect) → ALLOW, so the fix is bracketed from both
  sides rather than only proven in the blocking direction.
- A-2 recorded + pinned (`H1`), A-4 and A-5 fixed in both copies, B-1 resolved deliberately and
  consistently (`skip_next` deleted since the branch provably cannot fire; `find_predicates` kept
  with the historical-documentation comment), all four NITs done.

Numbers, each quoted from its run: `verify_all` **PASS 32 / WARN 0 / FAIL 0** (count held at 32);
driver **`PASS: 85 / FAIL: 0`** (81→85, three-way lockstep machine-checked 85/85/85 with `comm -3`
empty in both directions); vs pre-change guard **`PASS: 50 / FAIL: 35`**; vs the **round-1** guard
with row 12/15 reverted, **`PASS: 83 / FAIL: 2`** with red rows *exactly* `R1 R2` — that last run is
what proves the round-2 fix specifically, not just the round-1 change. Collateral `test-init` 391/0,
`test-real-project` 90/0, `sync-self --check` `In sync.`, rule docs 198/189 lines against the 200
cap, `=== Result ===` present on every run.

**Three things the developer did that were not asked for and are right:**

1. It corrected a **fabricated tally in `CHANGELOG.md`** — the 0.46.0 entry claimed a pre-change
   suite score of `46/31` that **no run ever printed** — to the captured `50/35`. That is this
   repo's most-repeated defect class (T-12's `278`, T-13's rework) caught by the author itself.
2. It corrected the *code reviewer's* line-count figures rather than deferring to them: the review
   said 198/188, but `wc -l` — which is what gate I.2 actually uses — now reads **198/189**.
   Checking the number against the tool that consumes it is the right instinct.
3. It A/B-measured its own round-2 change (42→43 ms, 35→35 ms, 2213→2130 ms), found it to be noise,
   and therefore **left the rule doc's measured table unedited** rather than restating numbers it
   had not re-established.

**DESIGN DRIFT 5** declared: row 15 no longer reads the raw byte at `i-1`. Monotonicity argued by
construction — `{redir_i == i-1}` is a strict subset of `{raw byte at i-1 ∈ {>,<}}`, so the append
branch can only shrink and the position set can only grow, making a BLOCK→ALLOW unreachable. That is
why the 55-line AC-4 corpus was not re-harvested; the Code Reviewer should confirm that reasoning
rather than take it.

**PM decision: RE-REVIEW (stage 5 round 2).**

### Stage 1 round 4 — requirement-analyst → NFR-1 residual-obligation paragraph corrected

One paragraph. `is opened` → **recommended, not yet scheduled**, plus the explicit negative
("no pool row and no task-board entry exist for it at the time of writing") and the naming of the
`/harness-stream` drain as the channel that can schedule it. The analyst verified the underlying fact
first (`docs/tasks.md` has no matching row) rather than taking my word, and confirmed the waiver text
— heading, "it was not met", the ~38× miss, root cause, bounding facts, decision basis — is
byte-unchanged. The correction made the document strictly more accurate without blunting it.

### Stage 5 round 2 — code-reviewer → `05_CODE_REVIEW.md` (round-2 section) · verdict **CHANGES REQUESTED** (0 CRITICAL / 1 MAJOR / 1 MINOR / 2 NIT)

Intervention check after stage: none present. Report persisted verbatim by PM.

**All ten round-1 findings closed**, each re-opened in the code rather than read off the disposition
table. Both tallies I asked it to re-derive reproduce exactly (**50/35** and **83/2**, the latter
being the only evidence the round-2 fix is load-bearing rather than riding on round 1); the mutation
table is consistent with its own traces; lockstep really is 85/85/85; the CHANGELOG now matches the
captured run. It also conceded a point *against itself* — its round-1 line counts were Read-tool
numbering, and the developer's `wc -l` figures are the ones gate I.2 actually uses.

**CR2-1 (MAJOR) — the round-2 fix opened a new hole while closing one.** `redir_i` is initialised to
`-1`, which *equals* `i - 1` at `i == 0`, so a command string whose first character is `&` is appended
instead of flushed: `& rm -rf <outside>` ALLOWs where the round-1 guard BLOCKed. Symmetric in both
shells. Three things make this the right call to route back rather than absorb:

- It is **fail-open**, and it **inverts the fix's own stated safety property** — the code comment
  claims a wrong index can only cause a flush (more positions, fail-closed); at `i == 0` it causes an
  append.
- It violates written boundary **B-3** (`rm -rf OUT` BLOCKs, `& rm -rf OUT` does not), and the
  existing rows pin B-3 only in the ALLOW direction with in-project paths — so **none of the 85 rows
  and none of the five mutations could see it**.
- There is an **executable vector**, not just a syntactic curiosity: `&` is PowerShell's call
  operator and the guard recurses into `pwsh -c` strings, so `pwsh -c "& Remove-Item -Recurse
  C:\Windows"` — pinned fixture row 8 plus one character — flips to ALLOW.

The reviewer explicitly invited me to dispute its MAJOR-not-CRITICAL calibration; I accept it. The
pre-change guard also allowed both forms, so **IS-2 and AC-4 are not violated** and the captured
differential still stands — this is a regression against the round-1 intermediate state, not against
the shipped baseline.

**CR2-2 (MINOR)** — drift 5's monotonicity argument is false as written, and it was the stated reason
the AC-4 corpus was not re-harvested. The reviewer verified the *conclusion* independently (IS-2 is
measured against the untouched pre-change pass; no corpus line contains `>&`/`<&` — it read all 55),
so **AC-4's proof obligation is met** and no re-run is needed; it is the reasoning that must be
corrected. It also warns against surfacing the round-2 insight as written, since that rule is what
produced CR2-1 — the inverse is the real lesson.

**PM decision: ROLLBACK to stage 4 (round 3).** Rollback tally at stage 4: **2 consecutive**. One
more would hit the three-consecutive stop rule and escalate to the operator, so I am sizing this
dispatch tightly: two tokens of code, two driver rows, one comment, one doc paragraph — no new
mechanism, no re-harvest.

### Stage 4 round 3 — developer → `04_DEVELOPMENT.md` (round-3 section) · verdict **READY FOR REVIEW**

Intervention check after stage: none present.

CR2-1 fixed with **one token per shell** — the `-2` sentinel rather than the `i > 0` guard, chosen
because it repairs the defect at its source rather than at the one call site: over the loop
`i ∈ {0…len-1}`, `i-1 ∈ {-1…len-2}`, so `-1` is inside that domain and `-2` cannot be. The comment
that asserted the wrong-index-only-flushes property is now true.

Runs, each quoted: `verify_all` **PASS 32 / WARN 0 / FAIL 0** (delta 0, count held); **87/0** against
the promoted guard; **50/37** against pre-change; **85/2 red exactly `R1 R2`** against the round-1
guard; **85/2 red exactly `R4 R5`** against the round-2 guard with only this round's fix reverted.
Those last two separating cleanly is the point of the round — it proves round 3's fix is itself
load-bearing *and* that CR2-1 was a regression opened by round 2, not a pre-existing hole.

**Three things worth recording about how this round was done:**

1. It went **beyond the two inputs the reviewer named** — 22 probes at `i == 0`, `i == len-1`, inside
   `GROUP_PAREN`/`CMDSUB`, after a flush, and at depth 1 in both recursion branches — and found **two
   more** live bypasses nobody had named: `bash -c "& rm -rf OUT"` and the no-space `&rm -rf OUT`.
   All four now exit 2; the other 18 did not move. That is the exhaustiveness the dispatch asked for
   actually happening rather than being asserted.
2. It **refused to claim a check it had not run.** My dispatch told it to confirm `=== Result ===` in
   every run; it reported that the guard driver prints `=== test-guard-rm summary ===` and that
   `=== Result ===` belongs to the *other* two drivers, so claiming that marker on the guard driver
   would have been a fabricated check. It verified each driver's own marker instead. My instruction
   was sloppy and it corrected me rather than producing a green that meant nothing.
3. It **declined CR2-4** with a reason (promoting `R3b` would be row-set inflation — it is green
   under every guard and mutant, because `2>&1 &&` never reaches the index test) and re-ran it as a
   probe to show that, rather than silently adding a row to look thorough.

It also self-reported that CR2-3 was its **second evidence-hygiene defect in two rounds** — both
figures written from a draft instead of transcribed from a run. That pattern is delivery-worthy
regardless of how this task ends.

Flagged for me, correctly: `04_DEVELOPMENT.md` is now **1304 lines against rule 70's 500-line
stage-doc cap** — WARN-level, ungated (`verify_all`'s `I.*` group does not measure stage docs, as the
Gate established in R2.6), and PM-owned at archive time. Recorded here; handled at delivery.

**PM decision: RE-REVIEW (stage 5 round 3).** Scoped to the sentinel and its blast radius.

### Stage 5 round 3 — code-reviewer → `05_CODE_REVIEW.md` (round-3 section) · verdict **APPROVED WITH NITS** (0 CRITICAL / 0 MAJOR / 2 MINOR / 1 NIT)

Intervention check after stage: none present. Report persisted verbatim by PM.

CR2-1 **closed at its source**: the reviewer *discharged* the sentinel-unreachability claim instead of
accepting it — enumerating all 43 `i` mutations in each shell, confirming nothing decrements `i`,
that every branch modifying `i` also `continue`s, that no helper touches either variable, and that
`local`/function scope makes recursion safe. It then re-derived all three tallies (50/37, and both
85/2 runs) and confirmed `{R1,R2}` and `{R4,R5}` are **disjoint** — which is what simultaneously
proves CR2-1 was opened by round 2 and that round 3's one token is individually load-bearing.

It also tried to build a 23rd bypass in the class **and explained why it could not**, by enumerating
the dispatch for every possible first character at `i == 0` and showing the position is now total.
A negative result with a proof beats a negative result with an assurance.

Two more things worth recording. The reviewer **corrected itself twice**: its round-1 line counts
were Read-tool numbering (the developer's `wc -l` figures are what gate I.2 uses), and CR2-4's
"`2>&1 &&` never consults the index" was **its own round-2 sentence**, which conflates the two `&`s —
it traced the code, found the decline's *conclusion* still right for a different reason, and
downgraded it to a prose fix. It also noted it should have flagged the doc-size overage in rounds 1
and 2 and did not.

**CR3-1 (MINOR) is the finding that matters for delivery honesty.** A leading redirection hides the
verb of its own position — `> /tmp/log rm -rf /etc/x` exits 0 and bash runs the `rm`. It is
**pre-existing and monotone** (same `tokenize`, same first-token rule pre-change), so IS-2, AC-4 and
the captured 0 BLOCK→ALLOW all stand, and it is outside AC-1's chaining matrix — this task fixed
reachability *of positions*, and this is reachability of the verb *inside* a position. What is
defective is the **disclosure**: it is the same family as A-7/A-8, of which only the array-assignment
member is published today. The reviewer calls it "the largest undisclosed gap" and "the one thing a
competent adversary would reach for before `\rm`".

**PM decision: ADVANCE to stage 6 (QA).** Stage-5 gate satisfied — no CRITICAL, no MAJOR, and the
reviewer stated explicitly that no finding requires another developer round, on the evidence rather
than on the rollback budget. Stage 4 therefore ends at **2** consecutive rollbacks; the
three-consecutive stop rule was never reached.

**CR3-1 routed to QA rather than to a fourth developer round**, deliberately: QA is the stage that can
*prove* the class empirically (it has a shell, and can run the pre-change guard to confirm the
"pre-existing" claim rather than inherit it), it is doc-only, and this task's Gate requires QA to name
what the guard is still blind to. Fixing the disclosure in the same stage that verifies the claim is
tighter than routing a one-line doc edit back through development.

### Stage 6 round 1 — qa-tester → `06_TEST_REPORT.md` · verdict **PASS WITH NOTES** (0 BLOCKER / 0 CRITICAL / 0 MAJOR / 4 MINOR / 5 NIT)

Intervention check after stage: none present. `## Adversarial tests` section present (hard gate for
this task) at line 336.

**The original bypass is reproduced and closed, by QA's own runs**: pre-change `2 / 0 / 0 / 0 / 0`
→ shipped `2 / 2 / 2 / 2 / 0` across the stream's five-row table. Every tally independently
reproduced — `verify_all` 32/0/0 (×3), driver 87/0 (×10), 50/37 pre-change with the red set matching
member-for-member, and both 85/2 runs with **disjoint** red sets. QA rebuilt the mutants itself with
an anchor-exactly-once builder and **self-tested that builder's failure mode**, which is what stops a
silently-unapplied mutant from producing a false green.

Scale: ~1,870 probes across 9 corpora. **0 BLOCK→ALLOW flips anywhere.** **0 non-`{0,2}` exit codes
in 1,500 fuzz inputs** — it specifically hunted the exit-1 silent-disarm (the bash analogue of the PS
R11 hazard) and found none. **0 false positives on 50 realistic developer commands**, including the
two that would have crippled the toolchain (a heredoc write and the guard's own harness invocation).

**QA wrote what it measured, not what it was told.** Two places its runs contradicted the code
reviewer's description of CR3-1 and it reported the measurement instead: `'' rm -rf OUT` is not
executable (`rc=127`), and `xargs sh --rcfile` is not executable (only the `bash` variant is). It also
found members of the family the review had not listed (`< /dev/null rm`, `3>&1`, `&>`, `<<<`, and
propagation into every frame type plus `bash -c` **and `pwsh -c`**) and a bound the review did not
state (an argv carrier **rescues** the class). Crucially it confirmed the class is **pre-existing on
both guards** — had it been a regression, that would have been rollback-grade, and it says so.

CR3-1's disclosure landed in both rule copies, byte-identical, written from QA's own runs; it first
landed at 200/200 and re-flowed to **199 / 190** rather than ship with zero headroom.

**MINOR-3 deserves explicit endorsement**: QA declined to add driver rows for the newly-published
residual because doing so would invalidate every tally already quoted in three stage docs and break
the three-artifact lockstep, and it **preserved the baseline at 87 rather than lowering it**. It
recommended a pool row with the tradeoff stated instead. That is the right call — a test suite is not
worth more than the integrity of the evidence already captured against it.

**PM decision: one scoped fix-forward inside stage 6, then deliver.** Stage-7 gate is otherwise
satisfied (stage 5 APPROVED WITH NITS, stage 6 PASS). **MINOR-1** is the one finding I will not carry
into delivery unfixed: the *shipped* rule doc — which users receive — quotes a measured latency table
that **does not reproduce** (8192-char chain measures 1501 → 3107 ms against a documented 1487 →
2251; the pre-change column *does* reproduce, so it is not host load). In a task whose deliverable is
coverage honesty, shipping an optimistic measured number is exactly the defect class. QA holds the
reproducing measurements, so QA corrects the table — this is a fix-forward within stage 6, **not** a
third consecutive rollback to stage 4 (which would have hit the stop rule and escalated).

**MINOR-2** (operator PS list item 2 still says "81 rows" where item 9 says 87) lives in the
developer's stage doc, which QA may not edit. I carry the corrected figure into `07_DELIVERY.md`
myself and flag the internal inconsistency there.

### Stage 6 round 2 — qa-tester → `06_TEST_REPORT.md` (round-2 section) · **APPROVED FOR DELIVERY**

Intervention check after stage: none present.

**QA improved on my instruction rather than executing it.** I told it to replace the rule doc's
latency figures with its own. Instead it re-measured, found its round-2 run reproduced the
*developer's* numbers rather than its own round-1 numbers, and chased the disagreement instead of
overwriting digits. The variance is **payload shape, not host load**: at an identical 8192
characters, a dense `&&` chain ending in an empty position costs ~3.0-3.1 s while the same length
ending in a real command costs ~2.2 s, and a here-doc truncated mid-body is *cheaper than pre-change*
because it exits fail-closed early. Both "contradictory" measurements were correct, of different
lines. It published a **band with its shape-dependence and its method** (median of 3 × 10
invocations) rather than four false-precision integers — which is the more durable artifact and
would have been the right answer even if my instruction had been followed literally. MINOR-4
(`rm -rf $'/etc/x'`) also landed, at zero net lines, by re-flowing an existing residual.

Re-verified after the edit: `verify_all` **32 / 0 / 0** with `[I.2] PASS`, driver **87 / 0** with its
marker present, each run twice.

Incidental dogfood worth recording: QA's own first attempt to append its report was **BLOCKED by the
shipped guard** (a here-doc with odd quote parity). The published over-block table is accurate in
live use, not merely in the driver.

---

## Stage 7 — delivery

Intervention check before delivery: none present. **No intervention was found at any of the 14 stage
boundaries in this task.**

Stage-7 gate satisfied: stage 5 **APPROVED WITH NITS** (0 CRITICAL, 0 MAJOR) and stage 6 **PASS WITH
NOTES** (0 BLOCKER, 0 CRITICAL, 0 MAJOR). `07_DELIVERY.md` written; `docs/tasks.md` updated.

**Entropy-watch cadence: deliberately NOT run** — the dispatch states the stream owns that boundary.
No `entropy-cadence` call was made in either direction, so the stream's counter is untouched.

### PM housekeeping decisions at delivery (recorded for review)

1. **`02_SOLUTION_DESIGN.md`: correction block added, sections not rewritten.** Both code-review
   rounds assigned me the archive-time correction of three now-false design statements (drifts 1, 4,
   5). I added a `POST-DELIVERY CORRECTION` block at the head naming all three with evidence
   pointers, rather than editing the sections. Reason: the design is the record of what was
   *decided*; silently rewriting it would erase the fact that the implementation diverged and why,
   which is exactly the history a future reader needs. No reader is misled either way.
2. **`04_DEVELOPMENT.md` (1304 lines) is NOT compacted, deliberately.** Rule 70's stage-doc cap is
   500 lines; the Gate established it is **policy without a mechanism** (`verify_all`'s `I.*` group
   does not measure stage docs, in either shell), and the Code Reviewer assigned compaction to me.
   I am declining, and recording it rather than quietly skipping it. The over-cap content is three
   rounds of *captured* evidence for a security fix in which two regressions were caught — including
   the mutation red-sets and the comparison runs that are the only proof each fix is load-bearing.
   Rule 70's own test is "cuts are made by removing what doesn't earn its line", and I am a router,
   not the author who knows which captures are load-bearing. Compacting a security task's evidence
   trail to satisfy an ungated soft cap is the wrong trade. If the operator disagrees, compaction is
   a lossless-to-attempt follow-up.
3. **No pool row created** for either recommended follow-up (chunked indexing; pinning the newly
   published residual). `25-decision-policy.md` red line 3 forbids inventing tasks the operator did
   not request, and the pool belongs to `/harness-stream`. Both are surfaced in `07_DELIVERY.md` and
   in the return summary, which is the channel that can schedule them.
4. **`docs/tasks.md`'s active row for T-17 was stale** at stage 6 (still reading "Stage 1") — caught
   by the capture step, not by me. Corrected as part of the delivery update.

### Rollback ledger (final)

| # | Route | Trigger |
|---|---|---|
| 1 | Gate → architect | F-1 false negative, F-2 false monotonicity headline, F-3 branch-order contradiction, F-4 coverage overstatement, +5 more |
| 2 | Gate → requirement-analyst | F-10 AC contradiction, F-11 unverifiable corpus source |
| 3 | Code review → developer | 1 MAJOR + 5 MINOR (one false negative, one unrecorded over-block, two doc inaccuracies, dead code) |
| 4 | Code review → developer | 1 MAJOR — the round-2 fix's own sentinel regression |

Max consecutive at any one stage: **2** (stage 4). The three-consecutive stop rule was never reached,
and stage 5 round 3 stated explicitly that its remaining findings did not require another developer
round — on the evidence, not on the budget.

