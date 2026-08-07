# Code Review

> Contract portion. Rationale: `05_RATIONALE.md`.
>
> **Provenance note (PM Orchestrator, not the reviewer).** `harness-kit:code-reviewer` is
> defined with tools `Read, Glob, Grep` — it has **no `Write` tool** and cannot create the
> stage document its own contract names. PM transcribed the body below **verbatim** from the
> reviewer's returned report and authored none of it. Same defect as `harness-kit:gate-reviewer`
> (see `03_GATE_REVIEW.md`); recorded as an out-of-band framework finding in `07_DELIVERY.md`
> and **out of scope for T-22**.

## Files reviewed

- `.harness/rejected-decisions.md` (the only production edit; record at `:257-278`)
- `docs/features/stage-model-tiering/04_DEVELOPMENT.md`
- `docs/features/stage-model-tiering/04_RATIONALE.md`
- `docs/features/stage-model-tiering/02_SOLUTION_DESIGN.md` (§6 byte-form read character-for-character against the live record; §7/§8/§10/D-1…D-15)
- `docs/features/stage-model-tiering/01_REQUIREMENT_ANALYSIS.md` (§0, §2.6, §4.5, §5, §8)
- `docs/features/stage-model-tiering/03_GATE_REVIEW.md` round 2 §3/§4/§9/§10
- `.harness/scripts/verify_all.sh:640-655`, `:666-679`, `:742`, `:932-934` (cited-anchor verification)
- `docs/batches/default/STREAM_LOG.md:88`, `agents/developer.md`, `.harness/rules/70-doc-size.md`
- No tests exist for this change and none is admissible (`01` §3.3 bars adding a check); the standing test surface is `verify_all`, run twice.

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MAJOR | Spec/design-fidelity | `04_RATIONALE.md:377` | The mutation table's FZ-1′ row (`control 156/0` → `mutated 179/0`) cannot be produced by the method the table declares at `:367-369`. A one-line `model: haiku` append moves `git diff --numstat -- agents/` by **+1** (288/130 → 289/130), not by +23; and a scratch copy outside the work tree is untracked, so the stated command cannot see it at all. The two cells are the pre-edit and post-edit numstat of `.harness/rejected-decisions.md` itself (179 − 23 = 156, both with 0 deletions, matching `:190` exactly). The property FZ-1′ was added for **is** demonstrated by that experiment, but it is a different experiment presented under another one's method, so the row's `FIRES ✔` is unearned as printed and stage 6 cannot reproduce it. FZ-1′ is the leg introduced to compensate for FZ-1's failure, so its evidence quality is load-bearing for the drift narrative. Derivation and the excluded alternative readings: `05_RATIONALE.md` §1. |
| CR-2 | MINOR | Spec/design-fidelity | `04_RATIONALE.md:279-285` | "Two things, **both stronger** than what FZ-1 would have given for stages 0–3" is false for both items. Item 1 (FZ-3 vs `T_dispatch`) is weaker than content identity — `04_DEVELOPMENT.md:136` says so itself. Item 2 (FZ-1′) compares S-A→S-B and supplies **zero** coverage of stages 0–3, the exact interval FZ-1's failure vacated. The binding document states this correctly; the rationale overstates it. Same over-claim family the gate rolled stage 2 back for (G-1/G-4). |
| CR-3 | MINOR | Spec/design-fidelity | `02_SOLUTION_DESIGN.md:173-177` | D-9's acceptance command is internally inconsistent with §8.2 FZ-4 in the same document: `git diff --stat` against `H0` cannot show `+23 −0` for a file the design elsewhere states is already dirty. **RULED: adequately handled, no rollback to stage 2.** D-9's substance (append-only, 23 added, 0 deleted) is verified two ways at `04_RATIONALE.md:189-197`, the `\ No newline` tolerance is shown unneeded, and nothing downstream consumes the `+23` figure against `HEAD` (§10.2 item 6 asks only for zero deletions, which holds against `H0` at 179/0). Defect is in `02`, which stage 4 may not edit; reported, not corrected. |
| CR-4 | MINOR | Standards-conformance | `04_DEVELOPMENT.md:49-92` | A 40-line `verify_all` transcript is pasted into the **contract** document. `.harness/rules/70-doc-size.md` row 13 sends a captured tool run longer than 5 lines to the rationale, and Rule 1 caps raw evidence at ≤5 lines; no earlier row matches (the declared `## verify_all result` shape is `key: value` lines, and row 7's ≤5-line allowance does not reach it). AC-7 and C-5 are fully satisfiable by the 4-line summary + `exit=0`; the 32-check listing earns nothing in the contract. No size emergency — the file is 249 lines against a 500 cap — hence MINOR. |
| CR-5 | MINOR | Standards-conformance | `04_DEVELOPMENT.md` (whole file) | The `## Condition disposition` section required by `agents/developer.md:61` is absent. All five gate conditions **are** disposed of in the binding document (C-1 at `:117-122`, C-2 at `:16`, C-3 at `:124-138`, C-4 at `:99`, C-5 at `:45`), so no content is missing — only the declared container and its `id \| disposition \| evidence` row shape, which exists so a reviewer can audit conditions without hunting. |
| CR-6 | MINOR | Standards-conformance | `04_DEVELOPMENT.md:46,207-210` | The document twice cites the wrong `verify_all.sh` lines and files the error **as a correction of a correct upstream citation**. Live: `932` `(( errors > 0 )) && exit 2`, `933` `(( warns > 0 )) && exit 1`, `934` `exit 0`. So `02` §10.1 / gate C-5's `932-934` is exact, and open issue 1's claim that "the range starts one line early" is itself off by one. Semantics are unaffected (a WARN still exits 1). Flagged because the propagation risk is asymmetric: left standing, it invites stage 6/7 to "fix" a correct citation into a wrong one. **Withdraw open issue 1.** |
| CR-7 | NIT | Standards-conformance | `04_DEVELOPMENT.md:22-34,161-203` | `## Files changed` and `## Design drift` are written as bullets/paragraphs, not in the declared row shapes (`path \| what changed \| ledger id`; `id \| design item \| what was done instead \| why`). Substance is complete and this task defines no change-ledger ids, so the `ledger id` column has no referent. |
| CR-8 | NIT | Standards-conformance | `04_DEVELOPMENT.md:3`, `04_RATIONALE.md:3` | Opening lines are variants of the two literals `agents/developer.md:15-16` declares. Consistent with `01`/`02`/`03` in this task and with the batch's practice, so this is a convention question for the operator, not this task's invention. Not this stage's to fix. |
| CR-9 | NIT | Spec/design-fidelity | `04_RATIONALE.md:287-293` | "`01` was right and `02` refined it into an error" is right about the outcome, imprecise about the mechanism: `02` §8's inference (path-scoped emptiness against an unmoved `H0` ⇒ content identity) is **logically valid**; what failed was an empirical premise certified twice off an elided artifact. The lesson the archive should carry is the one the insight bullet at `:231-236` already states correctly — never take a negative off a context-carried `git status` snapshot — not "do not reason about the dirty set". The persisting artifact is right; only this framing sentence is loose. |

**Not filed, deliberately.** The six items pre-ruled at `03_GATE_REVIEW.md` round 2 §10 (archived `Origin` path; FZ-4's null; the `44%`/`0.02`/`0.83` roundings; G-11's T-13-vs-T-013 ID; `01` §2.6's qualitative single-digit component; G-10's `01` §4.3 line-count reference) were each checked and none is filed. G-11 in particular is verified real (`verify_all.sh:654` is tagged `（T-013）`) and is **not** escalated, per the gate's instruction and `BATCH_PLAN.md:46`'s zero-yield test.

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 · band + confidence grade + named non-derivable step | `01` §0.1 A-5 (6.7–45%, LOW) and A-4 (cache-traffic share, reason given) | ✅ (read-verified; QA owns the independent pass) |
| AC-2 · saving derived from share + addressable set, not a price ratio | `01` §0.2 + `02` §2 FL-1/FL-4 + `02_RATIONALE.md` §R2.4; projection zero | ✅ |
| AC-3 · eight roles, each with positive-evidence basis | `01` §0.3 — six rows covering 8 roles, each with a cited basis | ✅ |
| AC-4 · propagation vs dogfood-only, with reason | `01` §0.4; independently re-verified as FL-8 and again at gate round 2 §5 | ✅ |
| AC-5 · exactly one `## stage-model-tiering` record carrying both markings, the why, F-1/F-2/F-3, origin | `.harness/rejected-decisions.md:257-278`. **Verified by my own grep**, not by the developer's: one `^## ` heading at `:257`; the only other case-insensitive hits are `:276`/`:278`, both mid-line inside `Origin`. `01` §2.6's seven mandated elements each present (see Design fidelity check, RK-5 row) | ✅ |
| AC-6 · no `agents/*.md` edited, no skill, no check, no version/count change | FZ-2 (8/8 digests) + FZ-3 (8/8 vs `T0` and `T_dispatch`) + FZ-5 (8/8 exact line counts) + degraded-FZ-1's absence of any `??` entry; 32 checks at both runs; 17 skills via `[C.1]/[G.1]/[G.2]`; version via `[G.3]` | ✅ **holds, with two named uncovered class members** — see RES-1. Not weakened by CR-1: the predicates that carry AC-6 (FZ-2, FZ-3, FZ-5) are each genuinely mutation-tested with internally consistent control values |
| AC-7 · PASS 32 / WARN 0 / FAIL 0 on bash | `04_DEVELOPMENT.md:41-92`; summary and `exit=0` both asserted (C-5). Exit semantics confirmed by my own read of `verify_all.sh:932-934` | ✅ |
| AC-8 · every OQ has a recommended answer + blocking classification; no BLOCKING unresolved | `01` §8 OQ-1…OQ-5; OQ-4 is scoped "BLOCKING for the filing only, not for this task" and the filing is operator-reserved | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §6 / D-1 / C-2 · character identity of the record | I compared design `:108-129` against live `:257-278` line by line, including `—`, `–`, `≥`, `…` and every `**` span. **All 22 lines identical.** The developer's digest chain is also non-circular: `sed -n '108,129p'` from `02` (fences confirmed at `:107`/`:130`) → `record.txt` → append → `tail -n 22`; my independent read closes it regardless | ✅ |
| D-2 · three fields, preconditions folded into `Why` | `Decision`/`Why`/`Origin` only; F-1/F-2/F-3 inside `Why` at `:271-275`, matching the cited precedents `:219-220` and `:254` | ✅ |
| D-3 · both markings in `Decision`, separated | `:258-259`; the trailing clause forbids the blanket reading | ✅ |
| D-4 · archived `Origin` path left un-"fixed" | `:278`; RK-3 respected | ✅ |
| D-6 · 22 lines = 1 + 2 + 16 + 3, equal to the file's longest record | Live record is 22 lines; `byte-form-subpart-classification` is `:201-222` = 22 | ✅ |
| D-7 / §7 · append at end after `shared-insight-parse-module` | Previous record still ends at `:255`, blank separator at `:256`, new record `:257-278`; 255 + 1 + 22 = 278 | ✅ |
| D-9 · append-only `+23 −0` | Substance verified; stated command measures the wrong baseline | ⚠️ CR-3 (design defect, ruled no-rollback) |
| D-10 · no reflow of the 23 existing records | **Independently corroborated without the developer's digest**: every pre-edit line citation in `02` §12 and D-2 (`:12-17`, `:73-90`, `:191-199`, `:201-222`, `:219-220`, `:254`, `:255`) resolves to identical content in the post-edit file, and the record count is 23 → 24 by my own count | ✅ |
| D-11 · no compaction · D-12 · 293/287 confirmed · D-13 · ±1 not invoked · D-14 · cap not cited as a reason | All hold; D-14 checked against both the record and `04` — no text implies the 300-line cap constrained the decision | ✅ |
| D-15 / C-3 · limitation stated in D-15's own terms | `04_DEVELOPMENT.md:124-138`, including the direct `PM_LOG.md`-is-latest confirmation D-15 predicts | ✅ |
| §8 FZ-1 · `agents/` outside the dirty set | **FALSE on this tree** (8 files, 288+/130−). **RULED: designed contingency §8.2-1 fired and was executed exactly — record, shift load to FZ-2, do not stop. No rollback to stage 2.** A rollback cannot manufacture the `[H0, S-A]` content evidence now, since the baseline was never captured before the task; and nothing built changes. The developer's diagnosis that `01` §4.5 had declined to rely on dirty-set membership is correct (see CR-9 for the one imprecision) | ✅ handled |
| §8 FZ-1 residual strength (unclaimed) | Degraded FZ-1 is **not** wholly dead: path-scoped porcelain returned exactly eight ` M` lines and no `??` at S-A and S-B, so it retains full strength for the "new untracked file under `agents/`" mode its Covers column names. `04` reports the predicate as wholly degraded and under-claims here | ➕ correction in the developer's favour |
| §8.2 FZ-2 / FZ-3 / FZ-5 | 8/8 each; every epoch, margin and conversion in `04_RATIONALE.md` §R1/§R5 re-derived by me and exact (`05_RATIONALE.md` §2) | ✅ |
| FZ-1′ (added leg, §8.2 contingency) | Addition is legitimate under the contingency and removes nothing specified. But it is **subsumed by FZ-2** (digest identity implies numstat identity) and its mutation evidence is unreproducible | ⚠️ CR-1, RES-2 |
| §11 · does `04`'s freeze section **support** AC-6 or merely assert it? | **It supports it.** Per-predicate observed values, not restatements; a failed predicate reported as failed and traced to the clause authorising the continuation; a mutation table with control-vs-mutated values; and — the strongest signal — the disclosure at `04_DEVELOPMENT.md:142` that FZ-1's `git status` form **does not** fire, a self-damaging result with every incentive to omit, corroborated on real data by FZ-4's null. This is the opposite of the "evidence section restates the claim" defect this stage exists to catch | ✅ |
| §10.2-1 / R-2 · does the proof discriminate? | Genuinely, for the three filesystem predicates: FZ-2 control `a7fabb1c…` matches capture A6, FZ-3 control `1785579706` matches A4, FZ-5 control `91` matches A5, and the mutated FZ-3 offset (`+4 596 s` past `T0`) checks out. Not genuinely for the two git-based rows | ⚠️ CR-1 |
| RK-5 · §6 vs `01` §2.6 element by element | handle `:257` · `declined` `:258` · `deferred` `:258` · addressable-set-of-two `:260-261` · unmeasurable break-even `:264-265` · no per-consumer reversibility `:267-269` · F-1/F-2/F-3 `:271-275` · origin `:276-278`. The single-digit-saving component is carried qualitatively at `:266-267` and is **not** filed, per gate round 2 §10.1 | ✅ |
| V-1…V-6 | All confirmed; V-4's non-vacuity re-checked by my own read — `.harness/rejected-decisions.md` is neither in `i6_exempt_files` (`:666-675`) nor under `i6_exempt_dirs` (`:676-679`), and `git ls-files` is the scan source (`:742`), so I.6 ran over the record text | ✅ |
| C-1…C-5 | All five disposed of in the contract document, though not in a declared section | ✅ / CR-5 |
| §3 · explicitly-not-touched set | No `agents/`, `skills/`, `.harness/scripts/`, `docs/proposals/`, `.claude-plugin/`, `CHANGELOG.md`, `README*.md`, `docs/dev-map.md`, `CONTEXT.md` edit; `sync-self` not run (C-4) | ✅ |

## Axis status

- **Standards-conformance:** 5 findings (CR-4, CR-5, CR-6, CR-7, CR-8), worst = **MINOR**. Doc-size caps met (249 / 423 against 500); no red line touched; no invented rule applied; no `.claude/` or bootstrap-stub edit; cross-shell parity not engaged (V-6, no `.ps1` executed).
- **Spec/design-fidelity:** 4 findings (CR-1, CR-2, CR-3, CR-9), worst = **MAJOR**. All eight acceptance criteria are satisfied; the MAJOR is an evidence-provenance defect in the freeze proof's non-vacuity table, not a failure of the criterion it supports.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | AC-6 holds but is not airtight, and the residual must be stated in its true narrow form rather than waved off: no surviving predicate covers (a) a content edit to an `agents/*.md` during stages 0–3 that also preserved the mtime, or (b) an edit-and-revert inside `[S-A, S-B]`. (a) is narrowed — but not closed — by three independent in-record anchors: `01` §4.3 (stage 1, two line counts), `02` §8.3 (stage 2, all eight), and `03` round 2 §2 (stage 3, live read finding no `model:` key in any of the eight), all of which reproduce exactly at S-A/S-B. Note that the mtime-backdating technique is demonstrated **inside this task** at `04_RATIONALE.md:368`, so "no such operation occurred" is testimony, not a predicate. | `06_TEST_REPORT.md` |
| RES-2 | FZ-1′ must not be counted as an independent leg: digest identity (FZ-2) implies numstat identity, and FZ-1′ covers only `[S-A, S-B]`, contributing nothing to the stages 0–3 interval that FZ-1's failure vacated. Likewise FZ-5 alone cannot carry a one-line mutation — the developer already states this at `04_DEVELOPMENT.md:144-147`. Independent legs for AC-6 are FZ-2 and FZ-3. | `06_TEST_REPORT.md` |
| RES-3 | QA's independent reproduction of §10.2 item 1 must run FZ-1′ under the method the table declares and report the real delta (expected +1 insertion, not +23). If it reproduces 156/0 → 179/0 from a documented command over `agents/`, CR-1 is falsified and I withdraw it. | `06_TEST_REPORT.md` |
| RES-4 | C-4 forward-clearance, checked so stage 7 need not: the `## Insight to surface` bullet at `04_DEVELOPMENT.md:231-236` matches **no** first token of the fourteen I.6 anchor sets at `verify_all.sh:640-655` — no `scaffolding-only`, no `Compos*`/`compos*`, no `regenerat*`, no `Generated~from~.harness/rules`, no `.harness/` token, no Chinese. Stage 7 must re-run the check against the **final consolidated** `07_DELIVERY.md` wording, which may differ. | `07_DELIVERY.md` |
| RES-5 | The eight `agents/*.md` carry 288 insertions / 130 deletions of uncommitted work against `cb0ed57`. Any future freeze argument in this repo that leans on `agents/` being clean is wrong for as long as this wave stays uncommitted. Endorsed from `04_DEVELOPMENT.md` open issue 3. | `07_DELIVERY.md` |
| RES-6 | `02` §10.1's `verify_all.sh:932-934` citation is **correct**; `04`'s attempted correction of it is not. Do not propagate the `933-935` numbers. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |

## Verdict

**CHANGES REQUIRED (0 CRITICAL, 1 MAJOR)** — routes to **stage 4 (developer)** only, not to stage 2.

---

# Round 2 — re-review

> Transcribed verbatim by PM from the reviewer's returned round-2 report, for the same
> no-`Write`-tool reason recorded at the top of this file.

## Scope honoured

Round 1's passes are not re-litigated: character identity of the 22-line record, AC-1…AC-8, D-1…D-15, and the two `DESIGN DRIFT` rulings stand as written. This round adjudicates CR-1's falsifier, checks the deltas, and rules on the new upward finding.

## Production artifact — confirmed unchanged

Confirmed by my own read, not by the developer's report:

- `.harness/rejected-decisions.md` ends at **line 278** (EOF); previous record's `- **Origin:** T-20 …` still at `:255`; blank separator at `:256`; new heading at `:257`. 255 + 1 + 22 = 278, D-7 arithmetic intact.
- `:257-278` re-compared line-by-line against `02_SOLUTION_DESIGN.md:108-129` (fences at `:107`/`:130`): **all 22 lines identical**, including `—`, `–`, `≥`, `…` and every `**` span. No drift from round 1.
- I have **no Bash tool**, so I cannot re-execute `sha256` or `numstat`. I state that plainly rather than inheriting: `072fe740…5117` and `179 0` are reported, not re-run by me. The property they certify — character identity of the appended record — I verified directly by reading, which is the stronger check and does not depend on the digest.

## CR-1 — adjudication: falsifier NOT met; CR-1 **upheld as filed and now CLOSED by the fix**

The falsifier I bound myself to was: *"If a documented command over `agents/` produces 156/0 for a control derived from `agents/developer.md`, CR-1 is wrong and I withdraw it."* The developer reproduced my reading (e) — `156 0` / `179 0` are the pre- and post-append numstat of `.harness/rejected-decisions.md` against the `H0` blob — and confirmed it against its own interest. **The falsifier is not met. I do not withdraw CR-1.** It is upheld as filed and discharged by fix option 1.

### Is M-b a sound instrument for FZ-1′, or does it relocate the problem?

**Sound — with its fidelity established empirically rather than by construction, and one named gap that does not touch FZ-1′.**

1. **The two instruments measure the same thing.** On the real tree FZ-1′ is `git diff --numstat -- agents/` = work tree vs index, path-scoped; all eight files are ` M` (unstaged), so index == HEAD == `H0` and the measurement is live-vs-`H0`-blob. In M-b, HEAD carries the same eight `git show cb0ed57:agents/*.md` blobs, the index equals HEAD after the commit, and the work tree carries the same live files. Same comparison.
2. **The pathspec is genuinely exercised, not stubbed.** The mutated cell is reported as `28 39 agents/developer.md` (`04_RATIONALE.md:433`), so the files sit under `agents/` inside the scratch repo and `-- agents/` filters a real path prefix. Had they been committed at the scratch root, the pathspec would have been vacuous and the whole row worthless. It is not.
3. **The one real difference is configuration, and it is closed by measurement.** `--numstat` output is sensitive to `.gitattributes` (text/binary, diff drivers), `core.autocrlf` and `diff.algorithm`; a fresh `git init` inherits global/system config but not this repo's local config or attributes. That gap is closed **empirically**: the control reproduces the real tree **per file, all eight** — `40/13 · 27/39 · 41/16 · 47/4 · 33/9 · 45/21 · 51/26 · 4/2`. Eight independent agreements would break under any config difference that changed hunk accounting. Reporting per-file rather than the total is what makes M-b auditable; a total-only match would have been far weaker, and the developer chose the stronger form.
4. **Control-fidelity ⇒ mutated-fidelity is the one extra inference, and it is triangulated, not asserted.** `--numstat` is per-file local, so appending to `developer.md` cannot move another row; the mutated result is exactly the arithmetic prediction (27→28, all else unchanged); and the same +1 is independently pinned by FZ-5's 91→92 and by M-a's digest change.
5. **Named gap, and it is a different, smaller class than CR-1.** M-b's fidelity rests on a control that reproduces a real, non-trivial value. The FZ-1 `??` row has **no such anchor** — its control is "no `??`" in both trees, the uninformative value both produce trivially. So for that one row M-b is not validated by its control, and the property at risk (whether an untracked `agents/*.md` is reported at all) is exactly the state a fresh `git init` does not inherit. **This is not CR-1 relocated:** CR-1 was "a cell that cannot be produced by its declared method"; the `??` row **can** be produced by its declared method, reproducibly — the only question is whether M-b's answer transports to the real tree. See RES-9; I closed half of it myself below.
6. **Credit where it is due on the most consequential row.** The ` M` row's `✘` — the negative the whole drift narrative turns on — does not depend on M-b's fidelity at all: it is independently corroborated on **real data** by FZ-4's null (`04_RATIONALE.md:379-382`), where this task's own +23-line edit to an already-dirty file moved nothing in porcelain. The fixture and the live tree agree on the finding that damages the author's case.

### The volunteered `3ada48b2…dc79` match — what it actually corroborates

It corroborates **consistency, not correctness**, and it does more work than it first appears to:

- Since M-b's mutated `developer.md` digests equal for M-a's, the two fixtures produced **byte-identical** mutated files. Combined with M-b's per-file numstat control being pinned to the real tree, this gives a **second, independent pin** on M-b's work-tree copy being the live file — and simultaneously back-certifies M-a's fixture provenance (M-a's control `a7fabb1c…9152` already matched capture A6).
- Correctness of the appended bytes comes from elsewhere — FZ-5's 91→92 and FZ-1′'s +1 both say exactly one line was added — so the three checks triangulate.
- **Where it is weaker than it looks:** same author, same session, no independent party. It excludes *inconsistency between the two runs*; it does not exclude *common-mode* error across both. And it corroborates the FZ-2 row, which was never the doubted one. CR-1's closure rests on the M-b re-run and its per-file control — **not** on this digest match. I record it as a credibility signal (volunteered, falsifiable, under no obligation, consistent with round 1's finding that this document discloses self-damaging results) rather than as load-bearing evidence.

### Per-file arithmetic — re-derived, internally consistent

Insertions 40+27+41+47+33+45+51+4 = **288** ✔. Deletions 13+39+16+4+9+21+26+2 = **130** ✔. Matches §R1 A2's `--stat` total and §R3's independent per-file list. Glob order puts `developer.md` second = 27/39 ✔, consistent with the mutated row naming `agents/developer.md`; 27→28 gives **289/130** ✔. Cross-check for absurdity: implied `H0` line counts (live − ins + del) are 103 / 250 / 285 etc., all non-negative and plausible; implied `H0` total 1218 vs live 1376. Nothing contradicts.

### Is the two-method table honest and QA-reproducible?

**Yes**, row by row, subject to two caveats (CR-14, RES-7). M-a's three rows carry controls that match live captures A6/A4/A5; M-b's three rows carry a control checkable against the real tree. The provenance note at `:434-438` names `156/0 → 179/0` as the `rejected-decisions.md` experiment it actually was, and — correctly — phrases it as disambiguating numbers a reader may meet **elsewhere** (they are live in `PM_LOG.md` and in `05_RATIONALE.md:26`), which keeps it out of `70-doc-size.md` row 8's "claim about an earlier draft". **Checked and deliberately not filed.**

## Ruling on open issue 4 / DR-4 (`02:314-316`)

I verified the defect independently: `02:314-316` says *"run FZ-1, FZ-2, FZ-3 and FZ-5 against the mutated copy. Each must **fire**"*, and `02:218` defines FZ-1 as `git status --porcelain -- agents/`. A scratch-directory copy is outside the work tree; the path-scoped command cannot see it. The defect is real.

**One correction to the framing, and it matters for how QA reacts.** PM's summary calls this "a vacuous pass". It is the opposite: `02` demands *"Each must fire"*, and the prescribed fixture guarantees FZ-1 **cannot** fire — so literal execution yields a **spurious negative** on the highest-value QA item (RK-1, AC-6), which a conscientious QA agent could read as the freeze proof failing. That is worse than vacuity, and it is why reporting alone is insufficient.

**Ruling: this must reach QA as a BINDING correction — reporting in `04` is not adequate — and it does NOT route to stage 2.** Stated explicitly as required:

- **Binding, because** `02` §10.2 is the document stage 6 works from; an open issue buried in `04` does not condition it, and RES-3 depends on it. It travels in this document's residual table, which QA reads. → **RES-8**.
- **No rollback to stage 2**, for four reasons: (i) §10.2 is QA guidance, not a build contract — nothing built depends on it; (ii) the remedy is one sentence and stage 6 can execute it today, since M-b is a worked, reproducible reading already in the record; (iii) a stage-2 round re-opens a §6 record that C-2 freezes, buying zero artifact change — the `BATCH_PLAN.md:46` zero-yield shape; (iv) symmetry — I ruled DR-1 (a *false empirical premise*, substantively larger) no-rollback; a defect in a QA hint is strictly smaller. The counter-argument I acknowledge: unlike DR-1, `02` pre-wrote no contingency here. Binding the correction into stage 6 fully covers that, and DR-4 + open issue 4 carry it into the archive.
- **Stage 6 remedy, as the developer notes:** use a tree where the command can observe the mutation. M-b is one; for the `??` leg the real tree also works, since creating and deleting a scratch file *outside* `agents/` is not needed — but note the true expected results are **FZ-1 ` M` form: does NOT fire** (that is the measurement, not a failure) and **FZ-1 `??` form: fires**. `02`'s "each must fire" is wrong for the first of these regardless of fixture.

## Fixes verified

| Round-1 id | Status | Evidence checked this round |
|---|---|---|
| **CR-1** | **RESOLVED** (fix option 1 + provenance note) | `04_RATIONALE.md:407-418` (M-a/M-b declared), `:424-431` (`method` column), `:433-438` (provenance note); per-file control re-derived above |
| **CR-2** | **RESOLVED** | `04_RATIONALE.md:302-314` — "**neither is stronger**"; FZ-3 "**weaker than content identity**"; FZ-1′ "supplies **zero** coverage of stages 0–3 … corroboration, not a leg" |
| **CR-3** | Carried as DR-2, upstream | `04_DEVELOPMENT.md:127` — unchanged ruling, no action owed |
| **CR-4** | **RESOLVED** | 32-check listing now at `04_RATIONALE.md:211-256` (row 13); `04_DEVELOPMENT.md:34-50` is 17 lines. See CR-12 for the residue |
| **CR-5** | **RESOLVED** | `04_DEVELOPMENT.md:134-142` — `## Condition disposition` with the exact declared header `gate condition id \| disposition \| evidence`, C-1…C-5 |
| **CR-6** | **RESOLVED, citations verified live by me** | I read `verify_all.sh:932-934` this round: `932` `(( errors > 0 )) && exit 2`, `933` `(( warns > 0 )) && exit 1`, `934` `exit 0` — **exact**. `04_DEVELOPMENT.md:43` now cites `:933` correctly; open issue 1 withdrawn; new open issue 2 (`:157-159`) records the guard. Also re-verified `:666-675` (8 `i6_exempt_files`), `:676-679` (`i6_exempt_dirs`), `:826` (`g4_count=$(( ${#report[@]} + 1 ))`) — all exact |
| **CR-7** | **RESOLVED** | `04_DEVELOPMENT.md:24-28` and `:124-129` are tables in the declared row shapes; drift keyed DR-1…DR-4; `ledger id` honestly `—` |
| **CR-8** | Left alone per my own round-1 ruling | — |
| **CR-9** | **RESOLVED** | `04_RATIONALE.md:320-330` — "the premise — **not the inference** — is what failed"; inference stated as logically valid; lesson correctly located in the insight bullet |
| **RES-1** | **RESOLVED into open issue 1** | `04_DEVELOPMENT.md:146-156` — narrow form, all three anchors (`01` §4.3, `02` §8.3, `03` round 2 §2), mtime-backdating named as demonstrated in-task. Still travels to stage 6 |
| **RES-2** | **RESOLVED** | FZ-1′ demoted at `04_DEVELOPMENT.md:62`, `:89-90`, `:116`, `:202` and `04_RATIONALE.md:314`; independent legs stated as FZ-2 + FZ-3 everywhere |
| **➕ under-claim** | **RESOLVED and strengthened** | `04_DEVELOPMENT.md:61` "PARTLY DEGRADED"; `??` leg mutation-tested at `04_RATIONALE.md:430`, `:452-455`. Aligns with the design's own Covers column (`02:218`: "plus any new untracked file under `agents/`") |

**Is the `??` mutation a real discriminator?** Yes — and for a better reason than it first appears. Showing that `git status` prints `??` for an untracked file is near-definitional; what the run actually excludes is the failure class where the leg is **silently dead** — a `.gitignore` pattern, `.git/info/exclude`, or `status.showUntrackedFiles=no` suppressing the entry. That class is real and is exactly why running it beats reasoning about it. **I closed the largest part myself this round:** I read `/home/alan/Programs/harness-kit/.gitignore` (61 lines) and **no pattern matches `agents/*.md`** — the entries are `参考/`, OS/editor/Node/Python junk, `*.log`, `*.local`/`.env.*.local`, root-anchored `/dist/ /build/ /out/`, and four `.harness/`/`.claude/` runtime files. The unclosed half is `.git/info/exclude` and `status.showUntrackedFiles`, neither readable without a shell → RES-9. Note also that M5 is covered by three predicates, not one: FZ-2/FZ-5's eight-file glob would return nine entries (`04_RATIONALE.md:455` says so). This supersedes `05_RATIONALE.md` §4's "M5 · not tested" row.

## New findings (round 2)

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| **CR-10** | MINOR | Spec/design-fidelity | `04_DEVELOPMENT.md:204` | The Verdict states *"**Every** predicate has been shown to fire on a mutation under the method its own row declares, so the proof discriminates."* The document's own table says otherwise: FZ-1's ` M` form is `✘ **does NOT fire**` (`04_RATIONALE.md:429`), and only its `??` sub-leg fires, on a different mutation. Everywhere else the document is scrupulous about this (`:61` "PARTLY DEGRADED", `:95-96`); the Verdict is the one place it isn't — and the Verdict is the paragraph downstream stages quote. This is the CR-2 over-claim family surfacing in the one paragraph I did not check in round 1. Precise repair: "…except FZ-1's ` M` form, whose non-firing is itself the measured result." Not blocking: the disambiguating sentence sits two clauses earlier in the same paragraph. |
| **CR-11** | MINOR *(conditional)* | Spec/design-fidelity | `02_SOLUTION_DESIGN.md:314-316` | Open issue 4 / DR-4, verified independently — see the ruling above. **MINOR conditional on RES-8 travelling to stage 6.** If RES-8 is dropped, this becomes MAJOR, because literal execution produces a spurious negative on the AC-6 item `02` itself calls highest-value. Upstream defect; reported, not corrected — `02` is not stage 4's or stage 5's to edit. |
| **CR-12** | NIT | Standards-conformance | `04_DEVELOPMENT.md:34-50` | CR-4's substance is fixed (the 40-line transcript is gone), but the section is not the declared `key: value` shape (`agents/developer.md:59`): baseline/after/delta are bullet-prefixed, and two bolded evidence paragraphs (I.6 non-vacuity, V-3/E.1) sit under a heading whose declared content is baseline/after/delta. Those two are binding statements with no declared home, so `70-doc-size.md` row 5 legitimately puts them in the contract — the gap is in the schema, not the author. Same convention family as CR-8; not this stage's to fix. |
| **CR-13** | NIT | Spec/design-fidelity | `04_RATIONALE.md:440-455` | §R6's "four results worth stating plainly" names one FZ-1′ blind spot (untracked files contribute no diff) but not the sharper one: **an in-place edit of a line already inside a changed hunk can leave `--numstat` bit-for-bit unchanged**, so FZ-1′'s +1 resolution is not a floor on its sensitivity — there exist content edits it does not see at all. Costs the proof nothing, precisely because FZ-1′ is now correctly demoted to corroboration subsumed by FZ-2; filed so nobody later promotes FZ-1′ on the strength of "it fires". |
| **CR-14** | NIT | Spec/design-fidelity | `04_RATIONALE.md:426` | The M-a mutated cell `3ada48b2…dc79` is **fixture-specific**: reproducing that exact hex requires the exact appended bytes (`printf 'model: haiku\n'` vs `echo`, and the source file's trailing-newline state), which the declared method does not pin. The reproducible claim is **FIRES / does-not-fire**, not hex equality. QA must not read a different mutated hex as a discrepancy. Folded into RES-3. Mitigating: the M-b run reproduced the same hex from an independently built fixture, so the mutation is evidently deterministic and simple. |

## Requirement coverage — delta only

AC-1…AC-5, AC-7, AC-8: unchanged from round 1, all ✅. **AC-6: ✅, and materially better supported than at round 1** — FZ-1′'s mutation row is now measured under a declared, reproducible method with an externally pinned control, and the `??` leg is mutation-tested rather than asserted. AC-6's two independent legs remain FZ-2 and FZ-3; the residual is unchanged and still travels as RES-1.

## Doc-size / policy note

`04_DEVELOPMENT.md` = **207** lines; `04_RATIONALE.md` = **exactly 500** — I verified the last content line is 500 (`- **No verify_all check added, removed or renamed** — count stays 32.`), i.e. **at** the `70-doc-size.md` cap, not over. Confirmed no `verify_all` check measures `docs/features/` stage-doc size: the 32-check listing carries I.1 (AI-GUIDE), I.2 (rules), I.3 (agents), I.4 (insight-index), I.5 (`docs/tasks.md`) and nothing for stage docs. Policy, not gate — as the gate established. **One operational consequence worth PM's attention: there is zero headroom for a round 3 on `04_RATIONALE.md`.** Every finding above is repairable inside `04_DEVELOPMENT.md` or by in-place substitution; none of them requires new rationale lines. If a later stage does demand rationale text, something must be cut first.

## Out-of-scope sweep

Nothing CRITICAL or MAJOR outside the reviewed deltas. Checked and not filed: `04_RATIONALE.md:434-438`'s provenance note against `70-doc-size.md` row 8 (ruled conforming — it disambiguates numbers live in `PM_LOG.md` and `05_RATIONALE.md:26`, not a claim about a superseded draft); no `## Round N` / changelog section in either `04_*` document (row 8 respected, corrections made in place); no `.claude/`, `CLAUDE.md`, or bootstrap-stub edit; no invented rule applied.

## Axis status

- **Standards-conformance: 1 finding (CR-12), worst = NIT.** Declared shapes now present (`## Condition disposition`, `## Files changed`, `## Design drift`); row-13 transcript relocated; row-8 respected; doc caps met (207/500 and 500/500); every cited `verify_all.sh` anchor re-verified live and exact; no red line touched; cross-shell parity not engaged (V-6, no `.ps1` executed).
- **Spec/design-fidelity: 4 findings (CR-10, CR-11, CR-13, CR-14), worst = MINOR.** CR-1 upheld and closed; CR-2, CR-6, CR-9, RES-1, RES-2 and the ➕ under-claim all resolved. No axis carries an unaddressed CRITICAL or MAJOR.

Aggregate = the more severe of the two = **MINOR**.

## Residuals travelling to stage 6

RES-1, RES-2, RES-4, RES-5, RES-6 carry forward unchanged. RES-3 is **spent as written** (its falsifier is adjudicated) and is replaced:

| id | Statement | Must reach |
|---|---|---|
| **RES-3′** | *(supersedes RES-3)* CR-1's falsifier was tested and **not met**; do not re-run the 156/0 hypothesis. QA reproduces FZ-1′ under **M-b**: expect control **288/130, per file** `40/13 · 27/39 · 41/16 · 47/4 · 33/9 · 45/21 · 51/26 · 4/2`, and mutated **289/130** (`28 39 agents/developer.md`). Check the **control per file first** — that is what validates the fixture; a total-only match does not. Judge M-a's rows by FIRES / does-not-fire, **not** by reproducing the hex `3ada48b2…dc79` (CR-14). | `06_TEST_REPORT.md` |
| **RES-7** | **M-b's reproducibility is time-bounded.** Its control depends on `cb0ed57` being reachable **and** the eight `agents/*.md` remaining uncommitted with unchanged content. If the T-13…T-21 wave is committed before QA runs, the control collapses to 0/0 and every M-b row becomes unreproducible through no fault of the record. QA must state the tree state it observed. Sharpens RES-5. | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| **RES-8** | **BINDING correction to `02` §10.2 item 1 (`02:314-316`).** Do **not** run FZ-1 against a scratch-*directory* copy: the path-scoped `git status --porcelain -- agents/` cannot see a file outside the work tree, and `02`'s "each must fire" would then produce a **spurious negative** on the AC-6 item, not a vacuous pass. Use a tree where the command can observe the mutation (M-b at `04_RATIONALE.md:411-418` is one such). True expected results: FZ-1 ` M` form **does not fire** for a content edit (that is the measurement, and it is corroborated on real data by FZ-4's null); FZ-1 `??` form **fires** for a new untracked `agents/*.md`. `02` is wrong on the first of these regardless of fixture. **Ruled: no rollback to stage 2.** | `06_TEST_REPORT.md`, `07_DELIVERY.md` |
| **RES-9** | The `??` leg's mutation was run in M-b, whose untracked-file visibility a fresh `git init` does not inherit from this repo, and whose control (`no ??` in both) carries no fixture validation. **I cleared the `.gitignore` half myself** — `/home/alan/Programs/harness-kit/.gitignore`, 61 lines, no pattern matches `agents/*.md`. Two checks remain and need a shell: `git check-ignore -v agents/sneaky.md` and `git config status.showUntrackedFiles`. Small residual; the leg is corroboration for M5, which FZ-2/FZ-5's eight-file glob also covers. | `06_TEST_REPORT.md` |

## Verdict

**APPROVED WITH NITS (0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT).**

CR-1 is upheld — the falsifier I bound myself to was tested and not met — and **closed** by a fix that is stronger than the relabel I would have accepted: a real re-run under a declared method whose fidelity is pinned per file against the live tree, not argued from construction. The developer confirmed the finding against its own interest and volunteered a corroborating digest it had no obligation to report. All eight round-1 items are resolved or correctly carried; no axis carries a blocking finding. The two MINORs are a one-clause over-claim in the Verdict paragraph (CR-10) and an upstream `02` defect I have ruled must travel as a **binding** correction rather than a note (CR-11 / RES-8), with **no rollback to stage 2**. Proceeds to **stage 6 (QA)** with residuals RES-1, RES-2, RES-3′, RES-4, RES-5, RES-6, RES-7, RES-8, RES-9.
