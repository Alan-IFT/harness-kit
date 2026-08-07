# Delivery Summary

> Contract portion. Rationale: 07_RATIONALE.md (absent = none written).

## Summary

- Task: T-18 `stage-contract-split` — split every pipeline stage's output into a typed **contract** carrying only what downstream stages consume and a free-form **rationale** carrying reasoning only the gate and reviewers read, with round history in the routing log.
- Mode: full
- Stages traversed: 1 → 2 → 3 → **2** → 3 → 4 → 5 → **4** → 5 → 6 → **2** → 3 → 4 → 5 → 6 → *(operator ruling)* → 2 + 4 → 6 → 7, all 2026-08-01
- Rollbacks: 3 — (1) gate → architect, design gap: the design breached its own flagship rule in its flagship edit; (2) reviewer → developer, AC-4 unmet for stage 7; (3) QA → architect, the boundary rule was non-total *as a system* and `## Insight` misrouted in the false-green direction. A fourth was escalated to the human instead of dispatched.
- Final verify_all result: **PASS 32 / WARN 0 / FAIL 0**, exit 0, count 32 read from the run (QA ×3, stdout md5-identical; operator re-ran independently)
- Baseline changes: none — check count 32 → 32, no check added or removed, `baseline.json` untouched, no version stamp moved, no PowerShell surface created (operator list stays at **sixteen** unrenumbered items)
- Outstanding risks: eleven named travelling residuals, headed by **RES-QA7** and **RES-QA8** (below). The guarantee is **structural for multi-line forms, compliance for anything that fits on one line** — no other wording of the grade is authorised.
- Files changed: **34 shipped surfaces** across the design's 29 ledger rows — both `70-doc-size.md` twins, all 8 framework agents, all 6 partition `dev-*.md.tmpl`, 4 skills, 2 `verify` skill templates, `00-core.md.tmpl`, the zh language policy, both `60-tool-handoff` twins, both `workflow.md` twins, `AI-GUIDE.md` + twin, `CONTEXT.md`, `CHANGELOG.md`, `.harness/rejected-decisions.md` — plus this task folder. A `git diff --stat` figure is **not** quoted: the tree carries ~89 uncommitted files from five sibling tasks, so a path-scoped stat sweeps in sibling work (`75-safety-hook.md.tmpl` alone) and would misattribute it. The ledger is the accurate count.
- Next steps for user: nothing is blocking. T-20 executes next and is the first task to run under this structure, which gives the before/after comparison. Review the residual list if you want any of it promoted to a pool row.

## What shipped

The normative **stage-doc boundary rule** is single-sourced as a section of `.harness/rules/70-doc-size.md` and its `/harness-init` template twin: an ordered six-step classification ladder, a "Not units" clause, a self-contained "Verbatim byte-form" definition, and a 14-row first-match-wins table with a terminal, reachable default. Each stage's existing numbered document **becomes** the contract — same filename, so backwards compatibility cost zero mechanism and no archive was touched — and reasoning moves to an optional `0N_RATIONALE.md` sibling written only when non-empty. Every downstream agent names contract portions as its inputs and enumerates the triggers on which it opens a rationale (T2.1–T2.4, T4.1–T4.4, T5.1–T5.4, T6.1–T6.3, T7.1–T7.3); the gate reads both portions of stages 1 and 2 by default, and its 8 audit dimensions are unchanged in number and wording. Round and rollback history lives in `PM_LOG.md`; no stage schema contains a changelog section.

**The enforcement is structural, not prohibitive, for the class the task was launched against.** A body destined verbatim for a shipped artifact has no location: ladder step 2 makes a fence one unit however long, rows 5 and 6 reject fences and blockquotes syntactically regardless of author intent, row 2 hands a byte-form to rows 3/4/9, and the one byte-carrying declared shape is gated on rows 3/4 having matched. The load-bearing property — found by QA and previously unstated anywhere — is that **every declared shape is line-shaped**, so a body needing more than one line has no container to hide in. The flagship 115-line pre-written block was walked through all fourteen rows by three independent parties, with the row-2 guard present *and* removed, and reaches `no home` every time.

## The measured result

Demonstrated on `docs/features/_archived/hook-truth-verify-scope/` (T-15), attributed span by span against the live archived files:

| Stage | Lines it must read today | Under the new structure | Reduction |
|---|---|---|---|
| 4 (developer) | 1649 | **1028** | **37.7 %** |
| 5 (code review) | 2309 | 1087 | 52.9 % |
| 6 (QA) | 2505 | 1210 | 51.7 % |

AC-9's binding floor was 30 %; the published stage-4 figure clears it by 7.7 points. The figure moved **down** twice during the pipeline — 40.1 % → 38.6 % → 37.7 % — because two reviewers re-attributed spans toward the contract, and the smallest measurement is the one published. Three parties independently confirmed the arithmetic reconciles against the artifact (134 + 95 + 14 = 243, the real file length) rather than against itself.

## Where the guarantee stops

**The grade, stated in full: structural for multi-line forms, compliance for anything that fits on one line.** A reading that comes away believing the guarantee is total is a misreading. Both stopping points are named: an unmarked normative sentence, and a one-line byte-form inside a declared shape's cell — for the latter, ladder step 1 makes the containing row the unit and states that sub-parts are never classified separately, so row 2 tests the container and never its contents, and row 4's never-matches-source-code bound is never reached.

This was ruled on by the operator rather than forced closed, and the reasoning is recorded at `.harness/rejected-decisions.md` under `byte-form-subpart-classification`: QA-7's corrective requires the rule to see sub-parts, and "sub-parts are never classified separately" exists to close the determinism defect QA found first — fixing one reopens the other. A change-ledger row must quote its target state; asking the structure to decide whether one line of characters is an interface shape or an implementation literal is asking structure to perform a semantic judgement, and forcing it would buy a few percent by introducing misclassification. The honest boundary is better than a false total.

## Residuals travelling

| id | Statement |
|---|---|
| **RES-QA7** | **The same bytes with the same purpose reach opposite destinations depending on the markdown container they sit in.** Evidence: this design's own E22 ledger cell offered the characters now standing at `skills/harness-goal/SKILL.md:68` and reached the contract ungated; the same intent as a blockquote at `_archived/stream-defer-human/02_SOLUTION_DESIGN.md:94` reaches `no home`. Accepted and published, not closed. |
| **RES-QA8** | Two ladder steps name the FR-9 header line with different spans and different destinations. **AC-1 is met in outcome — 0 observed misroutes across every contract produced — and unmet in the guarantee.** Both halves stand. |
| RES-1 | AP-2's stage-7 minimum (15 lines) is reachable at **margin 0**; three parties reproduced the measurement. The threshold was published, never tuned. The cheapest true fix is the FR-9 header the schema already mandates and the stage-7 template does not ledger. |
| RES-3 | Two skills still close-enumerate the per-task document set; both are output manifests, so neither misroutes a read. |
| RES-5 | The reconstructed T-15 `02` contract is 725 lines against the 500-line cap, and no check measures anything under `docs/features/` in either shell — that cap is policy without a mechanism. |
| RES-6 | The round-record clause is a 12-copy hand-maintained invariant across 14 surfaces; collapsing it trades AC-11's single-source against the degradation duty an agent must carry for a project whose rule fragment predates this task. |
| RES-8 | The shipped rule carries a round-relative comparative that its own row 8 would route to the routing log — cosmetic for a classifier, real as a self-application defect. |
| RES-9 | Six of seven agent schemas state only one direction of the rule's relationship to a declared shape; the converse ships only in the architect's contract. |
| QA-9 / QA-10 / QA-11 | Row 2's parenthetical is wrong about its own table; starvation demonstrated on live fail-closed guard bytes; the batch driver's `OR` fallback marks a `BLOCKED: NEEDS-HUMAN` delivery `done` and skips it on resume, at a rate this task's own template change raises to the authored default. |
| QA-13 / QA-14 | Four orphaned `499L` citations and one six-versus-five count; V-2 mislabels RES-QA7 as a determinism exception when it is a defect of kind — an error in the conservative direction. |

## What the pipeline caught

Eleven-plus findings, every one real. The gate caught the design **breaching its own flagship rule in its flagship edit**, and a "renames no heading / no other file changes" closure claim that was false in eight places. The code reviewer caught the last unmet acceptance clause, then **ruled its own earlier proposed fix directionally wrong** when the developer pushed back with evidence. QA falsified the boundary rule **twice** — first non-total as a system, with `## Insight` misrouting in the false-green direction and silently defeating the insight harvester at exit 0; then, after the fix, the hole having moved from *which row* to *which unit*. Three separate agents published measurements against their own interest: the developer shipped the smaller reduction figure and an unfavourable threshold measurement rather than tuning it, and QA corrected its own round-2 instrument after the developer's count proved right.

## Insight

- 2026-08-01 · A classification rule keyed on **surface form** routes identical content to opposite destinations depending on the markdown container it sits in, and the divergence is invisible until someone walks both containers: the same normative bytes reached `no home` as a blockquote and reached the contract ungated inside a table cell, because the unit rule names the containing row and forbids classifying sub-parts — so any such rule is a **size filter, not a kind filter**, below the granularity at which its unit is defined · evidence: T-18 QA-7, `.harness/rules/70-doc-size.md:47-50` vs `:79`
- 2026-08-01 · Making a document-classification rule TOTAL and making it CATCH a content kind are in direct tension and can trade against each other indefinitely: the clause that closed the determinism defect ("sub-parts are never classified separately") is exactly the clause that opened the gating hole, so a third round would have reopened the first defect — recognise the oscillation and put the acceptance-bar decision to the human rather than spending the round · evidence: T-18 QA-1 vs QA-7, `.harness/rejected-decisions.md` `byte-form-subpart-classification`
- 2026-08-01 · A contract that inherits a document schema **by reference** silently drops every instruction the inline version renders *inside* the schema example rather than as a numbered rule — "same schema as X" reads as covering a line that is only ever shown, never stated — which is why two of six partition templates shipped without the header instruction while a by-reference sibling had it · evidence: T-18 QA-12, `backend/dev-db.md.tmpl:76` inside the fence vs `backend/dev-api.md.tmpl:65` spelled out
- 2026-08-01 · A downstream stage that cannot execute (no `Bash`) will substitute a content-read against a specification for a byte-diff and can be right about the content while wrong about the citation, so hand every execution-requiring claim to the one stage that can run it as a named residual rather than letting the gap decay into an assumption — here it recovered three mis-cited line ranges and one mis-instrumented count · evidence: T-18 RES-4, code-reviewer round 3 vs QA round 2 byte-diffs

## Verdict

DELIVERED
