# Delivery Summary

## Summary

- Task: `review-write-path` (T-23) — reconcile the review stages' declared capability with the output their own contracts require, so the obligation stops existing only as a parenthetical in one of the three contracts that implement it. Origin: entropy finding **EP-001** (`docs/features/_supervision/entropy-2026-08-02.md`, graded Strong).
- Mode: **full** (stages 1-7), dispatched from a `/harness-stream` drain under `deferred-human mode: defer, do not ask`.
- Stages traversed (all 2026-08-02): 1 requirement-analyst `READY` → 2 solution-architect `READY` → 3 gate-reviewer r1 `BLOCKED ON DESIGN` → **2 solution-architect r2** `READY` → 3 gate-reviewer r2 `APPROVED WITH CONDITIONS` → 4 developer `READY FOR REVIEW` → 5 code-reviewer `APPROVED` → *(PM-executed AC-8/AC-9 probe)* → 6 qa-tester `PASS / APPROVED FOR DELIVERY` → 7 delivery.
- Rollbacks: **1** — gate round 1 returned two CRITICALs against the design: **G-1**, the AC-10 uniqueness constraint was *unsatisfiable* (P3 was required to be the only statement naming who writes, while P7/G3/G4/K3/K4 all named the PM, so the mutation left AC-1/AC-2 answered and the criterion would have passed on paper at stage 2 and failed at stage 6); and **G-2**, a dispatched stage loads the plugin-cache build, not the working tree, so AC-8/AC-9 carried an undischargeable precondition. Stage 2 was rolled back once; the three-consecutive-rollback stop was never approached.
- Final verify_all result: **PASS 32 / WARN 0 / FAIL 0, exit 0** — re-measured by QA across four runs, identical tally each time, identifier sequence byte-stable (md5 `3c71cadb914686c248a60ec4d9e71a28`) and equal to the developer's run. Check count **32 held**; no identifier renamed; no `.ps1` surface created, so the standing operator list stays at **25 (17 numbered + 8 un-numbered)**, un-renumbered.
- Baseline changes: **none** — no key moves, `verify_all_checks` stays 32, nothing lowered, `baseline.json` sha256-identical before and after. 0 tests added (this is contract text with no runtime surface). Agent line counts under the 300-line hard gate: `pm-orchestrator` **296** (4 lines of headroom), `gate-reviewer` 125, `code-reviewer` 177, `supervisor` 287 — all by live `wc -l`.
- Outstanding risks:
  - **The change is edited, not in force.** A dispatched stage loads `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/agents/`, which is byte-identical to `HEAD` — and `HEAD` *is* the v0.44.0 release commit. The gap is entirely uncommitted working-tree state; the unstarted link is **commit**. The arrangement governs a real run only after commit → push → marketplace publish → `/plugin` update → new session (RES-3). This delivery must not be read as though the arrangement is live on this host.
  - **P6(b) is two-way readable** (QA-2): "ends with its `## Verdict` line" admits both the heading and the verdict token, and QA's reproducer shows the heading reading fails **5/5** on every conforming document in the repo. Both probe writers independently took the safe token reading and neither routed back a compliant body, so the gate's `BLOCKED ON DESIGN` trigger did not fire — but a pass here is explicitly *not* evidence of unambiguity. Under the strict reading the failure shape is a **wedge**, not a loud failure: the reviewer returns the same body and the round stalls until the three-rollback stop.
  - **P6(a)'s predicate is undefined in any document the writer loads** (QA-3, G-23): the writer is told to check that the body begins with "that document's declared opening line" and is deliberately never told what that line is, so the check is shape-recognition rather than string comparison. R-2 holds for the *duty*, not for the duty's *predicate*.
  - **AC-8 observable (e) is unsatisfiable as written** (QA-1) and was reported **NOT MEASURED**, never as passed. G8 ships as "header, **then** the body", so a conforming message ends with the body.
  - **Three uninstantiated class members** (QA-6): stage 5 has zero behavioral rows, "rationale portion present" has zero rows, and P6(c) has no clean row. Named rather than glossed.
  - The 500-line returned-body cap is a documented contract with **no enforcement point** — P6 checks brackets and header/portion correspondence, not length.
- Files changed: **8 tracked files**, footprint established *positively* by wording fingerprint rather than by reading the drain's dirty set (a scoped `git diff --stat` is path-level only here, because `HEAD` is v0.44.0 and those hunks carry T-18…T-22).
  - `agents/pm-orchestrator.md` — the writer's duty (P1-P7) + stage-table pointers; two in-file condensations paid for it (293 → 296)
  - `agents/gate-reviewer.md` — G1-G8; the conditional parenthetical deleted (113 → 125)
  - `agents/code-reviewer.md` — K1-K8; hard rule 2's self-contradiction closed (166 → 177)
  - `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` — the distributed false attribution at `:51`, `:53`
  - `docs/workflow.md` + `skills/harness-init/templates/common/docs/workflow.md` — the generic write verb at `:18` in each; hand-maintained twins that nothing keeps in lockstep, verified byte-identical after
  - `CONTEXT.md` (two glossary terms) + `.harness/rejected-decisions.md` (two decline records) — the architect's own stage-2 rows, gate-cleared as inside its contract
  - Untracked/ignored: `verify_all.sh` appended four rows to the git-ignored `.harness/scripts/verification_history.log`.
- Next steps for user:
  1. **Commit.** Nothing in this arrangement governs a dispatched stage until the change is committed, published and pulled by `/plugin` update.
  2. **One queued row, recommended:** settle `# H1`-vs-marker ordering once across all seven contracts and their fenced examples. `agents/qa-tester.md:15` vs `:92-93` is a live contract-internal contradiction of exactly the shape repaired here, and stages 1/2 still produce H1-first artifacts. `agents/developer.md` is **not** in the class (no fenced example) — the code reviewer corrected the developer's scope claim on this.
  3. **Optional row:** disambiguate P6(b) to the verdict-token reading. Cheap, and the strict reading's failure mode is a wedge.
  4. `agents/supervisor.md:283`'s identical mis-attribution (OQ-4 / RES-5) stays unrepaired by design; the formulation to apply is G6/K5.

**What was decided, and why.** OQ-1 offered a write grant to the two review roles (removing the indirection entirely) against naming the duty in the orchestrator's contract. The architect took **direction 2+3 jointly — no capability changed** — and the gate adjudicated it independently and upheld it, publishing a four-point case *for* the grant and a three-point rebuttal. Decisive: the duty's failure leaves an inspectable artifact and is falsifiable on every run, while the invariant's failure — a verifier quietly amending the work it judges — leaves no artifact at all. The analyst's two-conjunct override condition was tested and failed on conjunct 2, with `agents/supervisor.md:283` as the evidence that this repo's only live prose confinement ships with a false statement of its own basis. The decline is recorded as `reviewer-write-grant`.

**The arrangement was measured, not asserted.** The controlled reproduction ran five sub-agent dispatches (`general-purpose`, chosen because it carries no competing build of either contract under test). The load-bearing arm is **variant B** — a writer whose *only* fidelity information was the reviewer's in-band header, which is the exact main-session-PM shape T-22 failed in. It persisted the body **byte-identical** (`cmp` clean, sha256 `fd5ff7f0…`) and added nothing; `grep 'round 2'` on the document returns 0. Variant A and variant B produced **byte-identical files despite holding different instruction sets** — non-self-referential corroboration that (d) does not carry the verdict. The differential control **must-failed as required**: driven by the authentic 0.44.0 build it produced a body opening `# 03 — Gate Review …` with none of the five declared section names, and the writer **routed it back and wrote nothing**. Bound stated rather than hidden: the control is `HEAD` and therefore pre-T-18, so its failure on (a) is over-determined — it validates the apparatus, and necessity for *this task's* sentences rests on AC-10's three mutations (1 write-act statement per shipped file → 0 in every mutant).

**A striking result was adjudicated away rather than harvested.** A probe arm reported that its `tools: Read, Glob, Grep` line was violated because it held a shell, and raised it against the premise carrying OQ-1's decisive leg. QA excluded the alternative explanation: 15 stage-3/5 documents across ≥13 genuine dispatches record read-only tooling with **zero** counter-instances, and the arm in question had been handed a contract as *pasted prompt text*, which is inert. The strong claim did not reach permanent memory; only the narrow corollary survives.

## Insight

- 2026-08-02 · In this repo a dispatched sub-agent does **not** load the working-tree `agents/*.md` — it
  loads the version-scoped plugin cache (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/agents/`),
  which here is byte-identical to `HEAD`, so editing an agent contract governs no run until commit → push →
  marketplace publish → `/plugin` update → new session, and **commit is usually the unstarted link**. The
  consequence that keeps biting is not staleness but *self-reference*: a stage editing its own contract runs
  under the pre-change build and must be told which text binds it — this fired four separate times in one
  task (gate r1, gate r2, code review, QA), and QA's own report would have opened `# Test Report` with no
  marker line had it followed its loaded contract. A corollary worth keeping separate: a contract delivered
  as prompt **text** carries no tool enforcement at all — only a registered agent definition does — so a
  reproduction that pastes a contract cannot be used as evidence about what tool grants enforce.
  · evidence: T-23, `03_RATIONALE.md` §R2 + `05_RATIONALE.md` §E + `06_TEST_REPORT.md` QA-7/QA-4
- 2026-08-02 · `rg` skips dot-directories by default, so an audit search written as a plain pattern returns
  **zero** hits under any `.harness/` path while still returning enough non-hidden hits to look complete —
  which silently drops precisely the distributed-twin class (`templates/common/.harness/rules/*`, the six
  partition `dev-*.md.tmpl`) that a totality condition exists to cover. The failure is invisible because a
  publication covering 35 of 36 sites reads exactly like one covering 36. Any "the audit set is total" claim
  must state **which form of the search produced it**, and `--hidden` is not optional in a repo whose source
  of truth lives under a dot-directory. · evidence: T-23, `04_DEVELOPMENT.md` C-4 vs `02`'s literal S1
- 2026-08-02 · A capability-shaped defect can be closed by naming the *writer* instead of granting the
  *capability*, and the thing that makes it survive is an **in-band** constraint travelling with the payload:
  a writer holding no orchestrator contract — the main-session shape the original failure occurred in —
  persisted a returned body byte-identical and added nothing, producing a file byte-identical to the one a
  writer holding the full duty block produced. Two writers with different instruction sets converging on the
  same bytes is the non-self-referential evidence; a byte-identity check against a body the writer itself
  captured is not, because a uniformly-reshaping writer passes it. The schema-absolute observables — first
  line, declared section set, absence of a round section — are what carry such a verdict.
  · evidence: T-23, AC-8 variants A/B vs the must-fail 0.44.0 control
- 2026-08-02 · A mandatory re-read whose *predicted* result is "no change expected" is worth keeping
  precisely because of the case where it bites: here a contract's fenced worked example carried an
  instruction (open with an H1) that the same contract's schema statement contradicted (begin with the
  marker line), so a document written the way its own contract *demonstrates* would have been routed back
  unwritten. This is the mirror image of the known hazard — the danger is not only that a by-reference reader
  drops an instruction rendered inside an example, but that the example silently **contradicts** the rule
  above it, and only re-reading the example against the changed rule finds it.
  · evidence: T-23, K7 / DESIGN DRIFT 1, `agents/code-reviewer.md` fence vs `:20-21`

## Verdict

DELIVERED
