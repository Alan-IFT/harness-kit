> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed

- `agents/code-reviewer.md`
- `agents/gate-reviewer.md`
- `agents/pm-orchestrator.md`
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl`
- `docs/workflow.md`
- `skills/harness-init/templates/common/docs/workflow.md`
- `agents/qa-tester.md` (out of scope; opened for the K7 class check)
- `agents/developer.md`, `agents/requirement-analyst.md`, `agents/solution-architect.md`, `agents/supervisor.md` (out of scope; opened for the K7 class check and the S2 audit)
- `CONTEXT.md`, `.harness/rules/70-doc-size.md`, `.harness/rules/60-tool-handoff.md`, `skills/harness-init/SKILL.md`
- `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/agents/code-reviewer.md` (DEV-1 control artifact)

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `agents/qa-tester.md:15` vs `:92-93` | The exact K7 contradiction repaired here is live in one other contract: `:15` declares that `06_TEST_REPORT.md` "opens with the line `> Contract portion. …`" while its own fenced `## Test report format` opens with `# Test Report`. Nothing breaks today (stage 6 writes its own file and no P6 bracket applies), so it is latent, not active. Out of scope by D-6; wants the queued row named in CR-2. |
| CR-2 | MINOR | Standards-conformance | `docs/features/review-write-path/01_REQUIREMENT_ANALYSIS.md:1`, `02_SOLUTION_DESIGN.md:1` vs `agents/requirement-analyst.md:14-15`, `agents/solution-architect.md:14` | The same class again, in *produced artifacts* rather than in a fence: both contracts say the document "opens with the line `> Contract portion. …`", and both documents in this very folder open with an H1 and carry the marker at `:3`. The developer's "the produced artifacts already converged" is true of stages 3/5/6 and false of stages 1/2. One queued row should settle H1-vs-marker ordering once for all seven contracts and their examples — see the ruling in `05_RATIONALE.md` §B. |
| CR-3 | MINOR | Standards-conformance | `04_DEVELOPMENT.md:236-248` vs `skills/harness-init/SKILL.md:83,:291` | C-4 requires the AC-5 publication to be **total** over every derived site. Re-running S2 myself returns 36 files; 35 carry a published disposition and `skills/harness-init/SKILL.md` (reserved-name guard at `:83`, role enumeration at `:291`) carries none. The site needs no edit — it is the same class as `_ai-native-prompt.md:22-23` and the `verify_all`/`test-init` role lists, both of which *are* dispositioned — so this is a hole in the publication, not in the arrangement. Amend the table; do not edit the file. |
| CR-4 | MINOR | Spec/design-fidelity | `02_SOLUTION_DESIGN.md:437` vs `agents/gate-reviewer.md:18-19` | AC-8 protocol step 6(a) is executable text and cites "the declared opening line quoted at `agents/gate-reviewer.md:14-15`". Post-change `:14-15` is **G1** ("You hold no write capability…"); the declared opening line moved to `:18-19`. QA executing step 6 literally measures the wrong line. Re-derive at stage 6; no contract edit is owed. |
| CR-5 | MINOR | Spec/design-fidelity | `agents/pm-orchestrator.md:46-48` | In the shipped bytes P3 and P4 are **one sentence** (`You write that body verbatim … ; none returned ⇒ no sibling file, and that absence means none was written.`). AC-10's expected-residue row for AC-2 predicts P4 survives the P3 deletion; it does not. The criterion still bites — harder, not weaker — but QA must not read the divergence from the design's predicted residue as a failure. |
| CR-6 | MINOR | Spec/design-fidelity | `agents/pm-orchestrator.md:49-50` | P6(a) tells the writer to check that the body "begins with that document's declared opening line", and the writer's contract never states what that line is — deliberately (D-3 cites it and never re-quotes it; C-3 bars the G8/K8 header from carrying the schema). The check is therefore shape-recognition, not string comparison. Materially mitigated: every stage doc the PM reads at `:85-86` opens with the same marker shape. Design-level residual, faithfully implemented; not a developer defect. |
| CR-7 | NIT | Standards-conformance | `04_DEVELOPMENT.md:334-338` | The harvested insight states the `Read`-vs-`wc -l` skew as holding "for three of four agent contracts here". Re-derived with the only instrument stage 5 holds, the skew is **uniform** — `Read` emits a trailing empty numbered segment for every newline-terminated file, including `agents/supervisor.md:288`. The three-of-four pattern belongs to E-15's inherited figures, not to the tool. Insight-index entries are permanent and capped at 30; worth correcting before harvest. |
| CR-8 | NIT | Standards-conformance | `04_DEVELOPMENT.md:227` | `docs/tasks.md:15,:29` is attributed to "S1, S2, S4". A live S1 run (the two filenames, hidden paths included) returns 30 files and `docs/tasks.md` is not among them; the site is an S2/S4 hit only. Same imprecision class the gate raised as G-12 — outcome unaffected. |
| CR-9 | NIT | Standards-conformance | `agents/pm-orchestrator.md:44-53`, `:151` | The new block and the C1 fold wrap at ~125-130 columns where the surrounding prose wraps at ~110. Justified in `04_RATIONALE.md` §D4 as the budget escape hatch D-3 authorises, and the file already carries a 643-character line. Recorded so a later editor does not "fix" the wrap and re-cross the cap. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `agents/gate-reviewer.md:14-16`, `agents/code-reviewer.md:14-16` — both unconditional, both name the PM Orchestrator; no `if you have no Write tool` clause survives anywhere | ✅ |
| AC-2 | `agents/pm-orchestrator.md:44-53` (P1–P7), reachable from the stage table by the `:30`/`:32` pointers | ✅ |
| AC-3 | Table built from the three shipped files; published in `05_RATIONALE.md` §A — 9 acts × 2 stages, no empty cell, no doubly-owned cell, no contradicted cell | ✅ |
| AC-4 | `agents/code-reviewer.md:101` (Hard rule 2) and `:14-16` (`## What you produce`) return the same answer: **no — it authors the body, the PM writes it** | ✅ |
| AC-5 | `04_DEVELOPMENT.md:187-248`; independently re-run (30 files on S1, 36 on S2) and reconciled in `05_RATIONALE.md` §D | ✅ with CR-3 (one site unpublished; class already dispositioned) |
| AC-6 | `04_DEVELOPMENT.md:30-31` — `PASS: 32 WARN: 0 FAIL: 0`, exit 0, before and after | ✅ on the developer's run; re-run owed to stage 6 (RES-A) |
| AC-7 | `04_DEVELOPMENT.md:45-59`; **independently reproduced** at stage 5 — 296 / 125 / 177 / 287, all ≤ 300, capped file has 4 lines of headroom (`05_RATIONALE.md` §C) | ✅ |
| AC-8 | QA-owned. Contract-side preconditions verified: both brackets shipped (`gate-reviewer.md:18-21`, `code-reviewer.md:18-21`), P6 shipped (`pm-orchestrator.md:49-52`), control artifact read and confirmed pre-schema | deferred to stage 6 (RES-B, RES-C) |
| AC-9 | QA-owned. Contract-side precondition verified: `pm-orchestrator.md:52-53` + `gate-reviewer.md:34-36` + `code-reviewer.md:36-38` | deferred to stage 6 |
| AC-10 | Paper mutation re-run on the **shipped bytes**, not on the design's description: deleting `pm-orchestrator.md:46-48` / `gate-reviewer.md:15-16` / `code-reviewer.md:15-16` leaves each file with only constraints, quoted literals and antecedent-less anaphors (`05_RATIONALE.md` §F) | ✅ paper arm; behavioural arm deferred (RES-D) |
| AC-11 | `04_DEVELOPMENT.md:34-36` — 32 identifiers, unchanged, no `.harness/scripts/*` in the change set; corroborated by a repo-wide fingerprint grep returning no script hit | ✅ on the developer's run; re-run owed (RES-A) |
| AC-12 | Fingerprint grep for this task's wording returns no `.ps1` path anywhere; operator list stays at 25 (17 numbered + 8 un-numbered) | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| L-1 / P8 — markers on stage rows 3 and 5 | `agents/pm-orchestrator.md:30,:32` — bare pointers, no verb, no actor (Q-8 satisfied) | ✅ |
| L-2 / P1–P7 — the transcription block after `:42` | `:44-53`; all seven items present, 10 text lines + 1 separator blank = 11 ≤ 12 | ✅ |
| L-3 / C1 — fold the detection fence | `:150-151`; both branch outcomes survive including the literal `harness-kit:developer` and "dispatch the project-local `dev-*` agents" | ✅ |
| L-4 / C2 — delete the duplicated delivery tail | pre-change `:235-237` gone; `:187-188` is the surviving mode-independent carrier | ✅ (DRIFT 2 — the zero-cost specificity carry into step 9 — reviewed and accepted) |
| L-5…L-12 / G1–G8 | `agents/gate-reviewer.md:14-16`, `:18-21`, `:34-36`, `:38-43`, `:45-46` (G5's parenthetical deleted), `:63`, `:65-69`, `:86` | ✅ |
| L-13…L-18, L-20 / K1–K6, K8 | `agents/code-reviewer.md:14-16`, `:18-21`, `:36-38`, `:42-46`, `:48-52`, `:101`, `:108` | ✅ |
| **L-19 / K7 — re-read the fenced example** | `:119-163`. The prediction "no content change is expected" is falsified; the check bit and the repair is correct. **DRIFT 1 is UPHELD: deleting the H1 is the right direction and "begins with" stands. No route-back to the architect.** Decisive: a "carries" predicate is satisfiable by a quoted marker — `agents/code-reviewer.md:122` is itself an instance — so relaxing the bracket would re-open G-7. Full argument, and the fourth site the relaxation would have to edit, in `05_RATIONALE.md` §B | ✅ drift upheld |
| L-21/L-22 / A1, A2 | `AI-GUIDE.md.tmpl:51,:53` corrected in one line each; `:49`,`:50`,`:52`,`:54` correctly keep "writes" | ✅ |
| L-23/L-24 / A3, A4 | `docs/workflow.md:18` and its twin, byte-identical on my read of both; "produce" replaces the false generic write verb; `:10`,`:12`,`:32`,`:34`,`:66` re-read and consistent | ✅ |
| L-25/L-26 — architect-owned, not re-applied | `CONTEXT.md:54-64`, `.harness/rejected-decisions.md:282-308` present and unduplicated | ✅ |
| D-2 — role × act table | Built from the three files; every cell owned exactly once (`05_RATIONALE.md` §A) | ✅ |
| Write-act uniqueness rule (C-1) | Exactly one per file on the shipped bytes: `pm-orchestrator.md:46`, `gate-reviewer.md:15`, `code-reviewer.md:15`. Path-token hit counts reproduce the developer's tables exactly (4 / 6 / 7) | ✅ |
| C-4 — total audit publication | The `--hidden` correction is real and material: my own S1 run returns `.harness/` paths the design's literal search cannot reach | ✅ with CR-3 |
| C-5 — live counts before and after | 293 → 296, 113 → 125, 166 → 177, 287 unchanged; arithmetic 293 − 5 − 3 + 11 = 296 checks; the "C1 frees 5 not 6" correction is right | ✅ |
| DEV-1 — which build governs a dispatch | Confirms D-8 and does **not** undermine it or AC-8. Independently corroborated at stage 5: the 0.44.0 cache `code-reviewer.md:14` is character-identical to the contract loaded into this session | ✅ |
| DEV-2 / DEV-3 | Both publications reproduce against the live files | ✅ |
| P6 stated positively rather than negatively | `:49-52`; all three conditions and the "nothing is written at all" consequence present, ordering preserved | ✅ wording choice, not a content change |
| Scope discipline | No new check, no identifier renamed, no `.ps1`, no `.harness/agents/` (glob returns nothing), no `CHANGELOG.md` entry, no version stamp moved, L-25/L-26 not re-applied. Established positively by fingerprint, not by reading the drain's dirty set | ✅ with RES-E |
| R-7 — extensional read-only invariant | `gate-reviewer.md:86`, `code-reviewer.md:101`; every other read-only assertion in the three files names its object set | ✅ |
| `.harness/rules/60-tool-handoff.md:122` | Re-read against P7 rather than accepted on the design's assertion: its own remedy is "the original author re-does it", which is exactly what P7 arranges. No contradiction | ✅ |

## Axis status

- Standards-conformance: 5 findings, worst = MINOR (CR-1, CR-2, CR-3 MINOR; CR-7, CR-8, CR-9 NIT).
- Spec/design-fidelity: 3 findings, worst = MINOR (CR-4, CR-5, CR-6). All 24 dev-owned ledger rows verified applied in the shipped bytes; no design drift beyond the two the developer declared, both adjudicated and upheld.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-A | AC-6 and AC-11 rest on the developer's `verify_all` run; stage 5 holds no `Bash` and did not re-execute it. AC-7 was independently reproduced by read and needs no re-run. | `06_TEST_REPORT.md` |
| RES-B | AC-8's differential control is the 0.44.0 cache copy, which is `HEAD` and therefore **pre-T-18**, not pre-T-23. Its must-fail on observable (a) is over-determined — it declares no opening line at all. G-18's bound stands: the control validates the apparatus; necessity for *this task's* sentences rests on AC-10. | `06_TEST_REPORT.md` |
| RES-C | AC-8 step 6(a) cites `agents/gate-reviewer.md:14-15` for the declared opening line; post-change it is at `:18-19` (CR-4). AC-10's P3 mutation deletes P4 with it (CR-5). | `06_TEST_REPORT.md` |
| RES-D | This task's footprint could not be isolated by diff at stage 5: no shell, and `HEAD` is v0.44.0, so any cache-vs-tree diff carries T-18…T-22 as well. Footprint was established positively by a wording fingerprint. A `git diff --stat` scoped to the six named paths would close it. | `06_TEST_REPORT.md` |
| RES-E | **DRIFT 1 upheld — "begins with" stands, the H1 deletion is correct, no route-back to the solution-architect.** The sibling instances (CR-1 `agents/qa-tester.md`, CR-2 stages 1/2 artifacts) are out of scope and want one queued row covering H1-vs-marker ordering across all seven contracts. `agents/developer.md` is **not** affected — it carries no fenced example, contrary to `04_DEVELOPMENT.md:313-318`. | `PM_LOG.md`, `07_DELIVERY.md` |
| RES-F | RES-1…RES-5 travel unchanged. RES-4 (a callee running a pre-schema build of its own contract) **fired a second time, at stage 5**: the contract loaded into this session is character-identical to `0.44.0/agents/code-reviewer.md:14`. Two independent instances, two stages, one task. | `07_DELIVERY.md` insight harvest |

## Verdict
APPROVED
