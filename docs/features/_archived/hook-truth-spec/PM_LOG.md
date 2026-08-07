# PM Log — T-13 hook-truth-spec

- Mode: **full** (stages 1-7)
- Dispatched from: `/harness-stream` drain of `docs/batches/default/BATCH_PLAN.md`
- Deferred-human mode: **defer, do not ask**
- Baseline gate immediately before dispatch: `verify_all` bash **PASS 32 / WARN 0 / FAIL 0**

## Pre-flight

- 2026-07-31 — `.harness/intervention.md`: **absent** (no pending intervention).
- 2026-07-31 — Read `.harness/insight-index.md`. Applicable lines surfaced into dispatch prompts:
  - 2026-06-21 bash 5.2 `patsub_replacement` / `&` in `${var//}` replacement → use `str_replace_all` (evidence: T-12 dev + 05_CODE_REVIEW, upgrade-project.sh / migrate-scripts-layout.sh).
  - 2026-06-21 PowerShell is agent-unexecutable; 3 failure classes (whole-file parse, automatic-variable param collision, `\"`+`$VAR` literal idiom does not port) (evidence: T-12 operator verification).
  - 2026-06-08 PS `WriteAllText` writes no trailing newline vs bash heredoc → cross-shell byte parity (evidence: T-012 DEFECT-1).
  - 2026-06-09 Prefer single-sourcing over adding a guard check; check count stayed 32 (evidence: T-016).
  - 2026-05-23 settings.json schema traps: `_`-prefixed doc keys must be at root not inside `hooks`; `$schema` needs `.json` suffix; consult upstream schema (evidence: v0.17.2 + v0.18.2, verify_all J.1).
  - 2026-06-05 / 2026-06-19 count-ledger discipline: a check-count change is version-worthy and G.4 gates it → keep the count at 32.
- 2026-07-31 — Read `docs/tasks.md`. Related historical tasks: **T-12 resilient-hooks** (v0.44.0 — created the resilient hook byte-forms and moved dogfood hooks to `.claude/settings.local.json`; the direct upstream of this task), **T-020 sync-hook-dangling-ref** (v0.31.0 — hook congruence scans), **T-011 ambient-stream** (the ambient hook pair). Sibling rows in the same wave: T-14, T-15, T-16 (all out of scope here).
- 2026-07-31 — Added T-13 row to `docs/tasks.md` active table with `mode: full`.

## Stage transitions

### Stage 1 — requirement-analyst · 2026-07-31

- Dispatched `harness-kit:requirement-analyst` with the pool goal, the 6 pool ACs, the out-of-scope list, and the 5 surfaced insight-index hazards.
- Output: `01_REQUIREMENT_ANALYSIS.md` — 16 FRs (A spec / B installer / C symmetry), 14 boundary conditions, 13 ACs, 5 NFRs, 9 Open Questions each with a binding `Recommended:` default.
- Verdict: **READY**. No `BLOCKED: NEEDS-HUMAN`. RA confirms none of the 9 OQs is human-reserved (no guard weakening, no red-line file, no permission-config change).
- RA-surfaced facts worth carrying forward: the duplication is ~12 files (the two regression drivers carry the byte-forms as fixtures); the installer is inside the layer-1 byte-mirror set, so the bootstrap must be written generically; a live cross-shell trailing-newline asymmetry already exists in the installer pair (OQ-5).
- RA noted `INPUT.md` does not exist. **PM decision:** not created — the dispatch brief is carried forward verbatim in each downstream dispatch prompt, and `01_REQUIREMENT_ANALYSIS.md` is the binding spec for stages 2+.
- `.harness/intervention.md` re-checked after stage 1: **absent**.
- **PM routing decision: ADVANCE to stage 2 (solution-architect).**

### Stage 2 — solution-architect · 2026-07-31

- Dispatched `harness-kit:solution-architect` against `01_REQUIREMENT_ANALYSIS.md` with the hazard set re-surfaced and the OQ `Recommended:` answers declared binding-unless-overridden-with-evidence.
- Output: `02_SOLUTION_DESIGN.md` (479 lines, under the 500-line stage-doc cap). New `hook-spec.{ps1,sh}` pair sourced in `templates/common/.harness/scripts/` and byte-mirrored via a new `sync-self` mapping; 6-query CLI; AC-3 byte-identity proof lands in `test-init.{ps1,sh}`; installer bootstrap as a 5-row truth table with temp-then-rename + re-read-from-disk terminal confirmation; 25-row change ledger with mirror marks; 9-item DO-NOT-TOUCH decoy list; fail-closed invariant as 4 mechanically-greppable checks.
- Verdict: **READY**. No `BLOCKED:` marker, no rollback request against stage 1.
- Three architect-flagged items carried into the Gate dispatch as mandatory scrutiny points: **D-1** (spec interface widened to also answer `event`/`matcher`/`hostos`), **D-2** (evidence-backed sharpening of OQ-5 — the installer's PS divergence is CRLF-throughout, not one trailing newline), **D-3** (the `sync-self` mirror-set count moves 7 → 8, which the design reads AC-12 by *intent* to permit; the only place an AC is not read by letter).
- `.harness/intervention.md` re-checked after stage 2: **absent**.
- **PM routing decision: ADVANCE to stage 3 (gate-reviewer).**

### Stage 3 — gate-reviewer (round 1) · 2026-07-31

- Dispatched `harness-kit:gate-reviewer` over `01` + `02` holistically, with D-1/D-2/D-3 named as mandatory independent-verification points.
- The gate-reviewer is read-only by contract (Read/Glob/Grep, no Write) and returned its report as text. **PM persisted `03_GATE_REVIEW.md` verbatim** — transcription only, no PM authoring of professional content (Hard rule 1 respected).
- Verdict: **CHANGES REQUIRED — ROLLBACK TO STAGE 2**. Routing string: `BLOCKED ON DESIGN`. 6/8 dimensions PASS; 2 FAIL, both stage-2-owned:
  - **F-1** — the count-ledger for the one moving claim (`sync-self` mirror set 7 → 8) names 4 live sites; a 5th exists at `docs/dev-map.md:176`, inside the very table the developer is told to edit.
  - **F-2** — the AC-3 byte-identity "proof" is justified by a transitive chain (spec ≡ fixture ≡ substituted template) that does not exist in the current driver: only 2 of 4 tools have an exact-string assertion, those 2 compare a variable against itself (composition-integrity, not a pin — the exact overstatement `.harness/insight-index.md` 2026-06-09 warns about), the template carries placeholders not byte-forms, and the non-host-OS half of the fixture is never compared to anything.
  - Plus W-1…W-6 (non-blocking individually): `set -euo pipefail` pre-empts the designed exit-4 branch; template-twin wording; decoy gaps incl. the `docs/tasks.md` T-13 ID collision with the old `lang-policy-split`; PS write API unpinned for the settings body; R-2 undercounts surviving duplication in `test-harness-upgrade`.
- Gate independently **confirmed** the architect's D-2 CRLF claim byte-for-byte, **accepted** D-1 as justified, and **accepted** D-3's intent-reading of AC-12 as legitimate (only its ledger completeness is rejected). The fail-closed invariant, the 32-check count, and every out-of-scope boundary were verified intact.
- No `BLOCKED: NEEDS-HUMAN` item — the gate states every gap is resolvable from repository evidence and none touches a red line.
- `.harness/intervention.md` re-checked after stage 3 round 1: **absent**.
- **PM routing decision: ROLLBACK #1 → stage 2 (solution-architect).** Rationale: both FAILs are design defects and only the design's author may fix the design. Requirement stands READY — stage 1 is not re-opened (the one requirement-side item, W-5, is explicitly non-blocking; PM routes it to the architect as a note-to-record rather than re-opening stage 1, since the gate assigned it "optional scoping"). Consecutive-rollback counter at stage 2: **1 of 3**.

### Rollback #1 rework — stages 2 and 1 in parallel · 2026-07-31

Dispatched both rework rounds concurrently (disjoint documents, no file conflict): the architect revises `02` only; the analyst amends `01` only.

**Stage 2 rework (F-1, F-2, W-1/W-2/W-3/W-4/W-6 + 2 Minors)** — `02_SOLUTION_DESIGN.md` rewritten in place, 499 lines (cap 500), with a `## Rework round 1 — gate conditions` mapping table for diff-review.
- **F-1 closed** — architect re-grepped independently rather than accepting the single named site; confirms the live set is now closed at **five** (`AI-GUIDE.md:76`, `docs/dev-map.md:142/163/164/176`), records the search method for reproducibility, and found no live claim in either README, CONTRIBUTING, getting-started, `.harness/rules/`, `evals/` or any HTML. Two further decoys added: `docs/tasks.md` (incl. the T-13 ID collision) and `.harness/rules/10-self-consistency.md:7` (a numerically identical "7" about a *different* set). Nothing frozen was moved.
- **F-2 closed via option (a)** — all four gate sub-claims verified true, the false transitivity sentence deleted. Decisive new fact the architect found: **both derivation helpers take the OS as a parameter**, so a single Linux bash run exercises all four Windows *and* all four unix forms — making all 8 Group A comparisons independent and host-independent, none host-OS-only. Because both helper files run a full flow at load, sourcing is prohibited; the design mandates function-definition extraction (bash `awk` range + `eval`; PS `FunctionDefinitionAst` + `ScriptBlock::Create`) plus a **mandatory anti-vacuity assertion** so a failed extraction fails loudly instead of silently degrading the 8 comparisons. Group A′ (fixtures) is relabelled *lockstep only*. No stage-1 rollback owed — AC-3's own parenthetical names this oracle.
- W-1/W-2/W-3/W-4/W-6 and both Minors folded in as specified.
- Verdict: **READY**. No `BLOCKED: NEEDS-HUMAN`.

**Stage 1 amendment (W-5 only)** — `01_REQUIREMENT_ANALYSIS.md` amended narrowly (452 → 456 lines), nothing renumbered, `## Amendment 1 (gate W-5)` section added.
- The analyst verified the gate's premise and found it materially stronger than assumed: **the init templates lay down no `.gitignore` at all**, so a generated user project has no existing mechanism to lean on. Two facts bound the risk: the create path is unreachable in a freshly generated project (the distributed committed settings template declares all four hook events, so FR-10 suppresses creation — row 5 is reachable only after an operator deliberately empties that block); and the exposure is OS-mismatch rather than secret leakage, which in the guard's case *blocks* Bash calls rather than disabling the guard (safe direction, NFR-2).
- Resolution took **both** gate options split by clause: NFR-4 rewritten into three scoped clauses (distribution — universal; gitignored — this repository; generated user projects — the printed advisory as the complete requirement) plus a recorded bounded residual risk. FR-12 extended in place; new boundary row B-15 and new criterion AC-14 appended. No new work for the architect (both ratify behavior `02` already specifies); the no-`.gitignore`-edit boundary is intact.
- Verdict: **READY**.

- `.harness/intervention.md` re-checked after both rework rounds: **absent**.
- **PM routing decision: RE-DISPATCH stage 3 (gate-reviewer) for round 2**, with the round-1 findings as the diff baseline and the stage-1 amendment (B-15 / AC-14 / NFR-4) flagged as new material the architect never saw.

### Stage 3 — gate-reviewer (round 2) · 2026-07-31

- Report returned as text (agent is read-only); **PM persisted it verbatim to `03_GATE_REVIEW.md`, replacing round 1.** The round-2 report is self-contained: its §2 carries every round-1 finding with its disposition, so the file remains the complete gate record.
- Verdict: **APPROVED FOR DEVELOPMENT** (routing string `APPROVED`). **8 of 8 dimensions PASS** (was 6/8).
- Both FAILs resolved on evidence the gate gathered itself, not on the architect's account:
  - **F-1** — gate re-grepped with a wider net than the architect's and swept all 80 files mentioning `sync-self`; live set genuinely **closed at five**, no sixth site, both new decoys correctly characterized, nothing frozen scheduled to flip.
  - **F-2** — the architect's decisive claim verified true against the actual helper bodies: both derivation helpers take the OS as a *positional parameter* and read no host signal, so one Linux bash run drives all 8 cells against a live, production-consumed, independently-maintained oracle. Gate additionally confirmed the sourcing prohibition is *stronger* than stated (the bash helper `exit 1`s at load, which would kill the test driver), that the extraction precedent exists and is applicable, and that the anti-vacuity assertion is a **call-through** check whose three vacuous-pass routes are all closed.
- The stage-1 amendment was verified independently: nothing renumbered, NFR-2 byte-unchanged (and its "any boundary condition in §4" scope now auto-covers B-15), and the analyst's "no new work for the architect" assertion holds — B-15 is satisfied *by construction* because `.gitignore` is not an input to the truth table.
- Carried forward: **8 advisories A-1…A-8**, explicitly "notes, not gate conditions", all resolvable by the developer following the design as written.
- No `BLOCKED: NEEDS-HUMAN`. The only human-reserved item is the pre-existing, already-booked NFR-5 operator PowerShell run — the design books it as a mandatory `07_DELIVERY.md` item, not a gate blocker, so it does not block this pipeline.
- **Consecutive-rollback counter at stage 2 resets to 0** (stage cleared).
- `.harness/intervention.md` re-checked after stage 3 round 2: **absent**.

### Stage gate check before stage 4

- Stage 3 produced an explicit **PASS** verdict (`APPROVED FOR DEVELOPMENT`). Gate satisfied.
- Partition detection: `.harness/agents/dev-*.md` → **no matches**. **Single-developer mode**; dispatching the plugin agent `harness-kit:developer`.
- **PM routing decision: ADVANCE to stage 4 (developer).**

### Stage 4 — developer · 2026-07-31

- Dispatched `harness-kit:developer` (single-developer mode) against `02_SOLUTION_DESIGN.md` as the binding implementation, with gate §9 (ten pre-answered traps) and §10 (advisories A-1…A-8) named as required reading, and the red lines restated (`.claude/` no hand edits; `docs/tasks.md` reserved to PM, which also removes the T-13 ID-collision hazard from the developer's surface).
- Output: `04_DEVELOPMENT.md` (324 lines, under cap). Verdict: **READY FOR REVIEW**.
- **Stage gate for stage 5 satisfied**: `verify_all` **PASS 32 / WARN 0 / FAIL 0** captured, identical to the baseline taken before any edit; check count unchanged. Final run was made *after* the dogfood bootstrap, so AC-8 is satisfied from the bootstrapped state.
- Other captured drivers: `test-init` 389 (python3) / **353** (no-python3, the pinned key), `test-real-project` 90/90, `test-harness-upgrade` 89/89, `test-verify-i6` 58/58, `test-language` 39/39, `test-supervisor` 46/0, `sync-self --check` / `harness-sync --check` clean.
- AC evidence claimed: all 8 `(tool, OS)` cells byte-equal to the live `resilient_cmd` oracle behind a passing call-through anti-vacuity assertion; FC-1…FC-4 greps (FC-1 and FC-4 zero hits); guard demonstrated **blocking** out-of-project deletes (exit 2), **allowing** in-project ones (exit 0), and **failing closed at exit 127 when the guard script is absent**.
- **Two items PM is routing to the Code Reviewer as primary scrutiny:**
  - **`DEFECT-DEV-1` — a pre-existing defect the developer found and fixed**, outside the design. At HEAD `cb0ed57`, two `test-init.sh` assertions interpolated a hook command value into an `assert()` eval; on any unix host the value's single quotes closed the eval's quoting and the driver `exec`'d a hook script *over itself*, silently truncating the run so every later assertion (the whole zh block included) never executed. Invisible on MSYS, where the OS-picked value has no single quote — which is why the pinned tally of 278 was only ever producible on Windows. This moves a pinned baseline key **278 → 353** and therefore needs independent adjudication: is the fix correct, is the decomposition (278 pre-existing + 45 spec + 30 installer = 353) real rather than reconciled-to-fit, and is *what* is asserted genuinely unchanged?
  - **PowerShell remains unexecutable** (`which pwsh` → nothing). All `.ps1` marked green-by-symmetry-only with five binding operator items; `test_init_ps_assertions` deliberately left unreconciled at 316 and the README `test--init-316%2F316` badge deliberately not moved.
- Six deviations logged, all claimed additive/non-weakening. The load-bearing one: `$PSNativeCommandUseErrorActionPreference = $false` in `install-hooks.ps1` as the **PS analogue of gate W-1** (PS 7.4+ would otherwise turn a non-zero native exit into a terminating error and pre-empt the designed `exit 4`, exactly as `set -e` does in bash — W-1 covered only bash).
- `.harness/intervention.md` re-checked after stage 4: **absent**.
- **PM routing decision: ADVANCE to stage 5 (code-reviewer).**

### Stage 5 — code-reviewer (round 1) · 2026-07-31

- Report returned as text (agent is read-only); **PM persisted `05_CODE_REVIEW.md` verbatim.**
- Verdict: **CHANGES REQUIRED** — 0 CRITICAL, **1 MAJOR**, 7 MINOR, 4 NIT. Axis status: Standards-conformance worst = MINOR; Spec/design-fidelity worst = MAJOR; aggregate = MAJOR (the masking invariant held — neither axis hid the other).
- **M-1 (MAJOR, developer-owned)** — deviation DEV-4 dropped design §6 step 7's two literal confirmations (`"PreToolUse"`, `"matcher": "Bash"`) in favour of values re-derived from the spec's own answers, and enforces `n_wired > 0` instead of `== 4`. Net: the terminal confirmation is tautological about *which* hooks landed, and a `hook-spec tools` listing fewer than four ids (or omitting `guard-rm`) would produce a partial wiring that passes confirmation and **exits 0 with a green "Created" report**. The reviewer notes the stated justification only required dropping a literal `guard-rm` — neither retained literal contains that token, so FC-1's zero-hit grep survives either way.
- Reviewer explicitly adjudicated M-1 as **not** an NFR-2 hard reject: §8 row 3 never overwrites an existing machine-local file, so the direction of risk stays restore-only — a failure to *restore* completely, not a weakening of an installed guard. PM therefore routes it as a normal rollback, not a safety stop.
- **DEFECT-DEV-1 adjudicated favourably on the load-bearing question**: the reviewer independently re-derived both new assertion counts from source (45 + 30 = 75) and found a corroboration the developer had not cited — `389 − 353 = 36 = 3 × 12`, reconciling against a third-party historical constant. Verdict: the 278/45/30 decomposition is **genuine, not reconciled to fit**; the fix is correct and minimal; *what* is asserted is unchanged; and the newly-unblocked tail contains no internal contradiction. Two doc-accuracy defects remain (m-5): the "since T-011" attribution is wrong (the single-quoted unix byte-form arrived with T-12/v0.44.0), and the claim sits in unreconciled tension with this repo's own archived T-12 bash tally of 278/0 — one of the two records must be wrong and the delivery must say which.
- PS twins read as a parser: **clean on every pinned hazard** (no automatic-variable collision, single-quoted `-f` literals, no here-string, `WriteAllText` both bodies). `$PSNativeCommandUseErrorActionPreference = $false` confirmed correct and correctly scoped. Two new PS-only risks (m-3, m-4) added to the operator checklist.
- Ledger row **D11 (`docs/tasks.md`) is PM-owned (m-7)** — PM will close it at delivery, as instructed to the developer.
- No `BLOCKED: NEEDS-HUMAN`. No finding owed by the solution-architect.
- `.harness/intervention.md` re-checked after stage 5: **absent**.
- **PM routing decision: ROLLBACK #2 → stage 4 (developer).** Rationale: M-1 is a code defect and only the implementer fixes the code (routing table row 3). No design change owed. Consecutive-rollback counter at **stage 4: 1 of 3**; stage-2 counter remains cleared.

### Coordinator directive received mid-rollback · 2026-07-31

The rework dispatch was interrupted before it launched. The coordinator re-ran the gate independently (`verify_all.sh` **PASS 32 / WARN 0 / FAIL 0**, working tree matches the reported file list) and directed PM to resume routing through to a verdict without handing back to the stream. Five priorities added to the rework brief:

1. Fix M-1 exactly as the reviewer scoped it — `n_wired == 4`, not `> 0`; a spec listing fewer than four ids must fail loudly.
2. Adjudicate every MINOR and NIT explicitly — fix or record as deliberately-declined with a reason; none left silent.
3. **The archive contradiction is promoted from a doc nit (m-5) to a delivery blocker.** Determine which record is wrong — DEFECT-DEV-1's account or T-12's archived bash `278/0` — and state it plainly in `07_DELIVERY.md` **backed by a captured run, not by reasoning about which number "should" be right**. Correcting the archive is explicitly **in scope for this row**, because this row is what surfaced it. Rationale given: this repo has a standing insight that a tally never produced by a real run once survived into a stage doc; a second instance means the discipline is not holding.
4. The pre-existing `test-init.sh` eval-truncation defect must be documented in the delivery as a **distinct finding with its own before/after evidence**, since it moves a pinned baseline for reasons unrelated to this task's scope.
5. PS twins stay green-by-symmetry-only with an explicit operator-pending item; claim no PS verification that was not performed.

Plus: QA's report must carry an `## Adversarial tests` section; the gate must be green at **32** checks — if the count moved, reconcile the version stamps rather than the count. `deferred-human mode: defer, do not ask` still applies.

- `.harness/intervention.md` re-checked before resuming: **absent**.
- **PM routing decision: proceed with ROLLBACK #2 → stage 4 (developer)**, brief extended with priorities 2-5 above. Priority 3 is a scope grant from the coordinator and is recorded here as such, not as an autonomous PM scope expansion.

### Stage 4 — developer (rework round 1) · 2026-07-31

- Output: `04_DEVELOPMENT.md` updated in place (485 lines, under cap) with a `## Rework round 1 — code review` section. Verdict: **READY FOR REVIEW**.
- **M-1 fixed in both shells and both mirror halves**: exact arity `(( n_wired == 4 ))` / `$nWired -ne 4` routed through the design's `exit 4` path, naming expected *and* actual; both design-mandated literal confirmations (`"PreToolUse"`, `"matcher": "Bash"`) restored **alongside** the spec-derived ones. FC-1 re-verified after the restore — `grep -n 'guard-rm'` over all four installer files returns **zero hits**, exactly as the reviewer predicted. A new executable FC-4 assertion was added (stub spec truncating the id list to 3 → exit 4, nothing written), captured green.
- Baseline moved **353 → 354** from a captured run (bootstrap block 30 → 31 assertions).
- **Dogfood re-run: the reworked installer's generated file is `cmp`-BYTE-IDENTICAL to the pre-rework one** — M-1 changed only what is *checked*, never what is *written*. This is the cleanest possible evidence that the fix is non-regressive.
- **Archive contradiction settled empirically (coordinator priority 3 — delivery blocker).** The developer extracted `cb0ed57`'s `test-init.sh` into a scratch worktree and ran it unmodified on this box:
  - pre-change driver → last line `PASS [T-020] every settings hook command path exists on disk (AC-5)`, 72 PASS lines, **`=== Result ===` ABSENT**, `EXIT=1`, stderr empty — i.e. it really does terminate early on unix.
  - same driver with **only** the eval fix, no T-13 code → `=== Result ===  PASS: 278  FAIL: 0`, `EXIT=0`.
  - **Conclusion: T-12's archived bash `278/0` tally is the wrong record.** The *value* 278 is correct (it equals `354 − 76` and the fixed pre-change capture) but the *run never happened* — it was hand-derived as 276+2. DEFECT-DEV-1's mechanism stands; its own unverified sub-claim ("278 was a complete tally on Windows") is **withdrawn** — nobody ran it on MSYS either.
  - Both archived T-12 documents annotated **append-only** (originals left verbatim). Tally-fabrication insight re-surfaced as a **second occurrence** of the standing `.harness/insight-index.md` line. "since T-011" corrected to **T-12 / v0.44.0 → HEAD** in the dev doc, `CHANGELOG.md` and `_qa_note_t13`.
- Remaining findings adjudicated with nothing left silent: **fixed** m-1 (split confirm-vs-write diagnostics so the message is true), m-2 (exit 5 now reachable on the `mkdir` sub-path), m-4 (target excluded by exact name — logged as DEV-7), m-6 (PS fixtures now host-bound), n-1 (`while IFS= read -r`), n-2 (`chmod` exit-code check). **Declined with reason**: m-3 — every mitigation changes error semantics in a driver the agent cannot execute, and the failure mode is loud and test-driver-only; promoted instead to a binding operator item with an exact six-site line list. **Confirmed as read, no action**: n-3, n-4. **m-7** remains PM-owned.
- Captured gate: `verify_all` **PASS 32 / WARN 0 / FAIL 0** (count unchanged); `test-init` 390 (python3) / **354** (no-python3); `test-real-project` 90/0; `test-harness-upgrade` 89/0; `test-verify-i6` 58/0; `test-language` 39/0; `test-supervisor` 46/0; `sync-self --check` In sync.
- PowerShell still unexecutable — `.ps1` green-by-symmetry-only with **seven** binding NFR-5 operator items.
- `.harness/intervention.md` re-checked after the rework: **absent**.
- **PM routing decision: RE-DISPATCH stage 5 (code-reviewer) round 2.** The reviewer owns confirming its own MAJOR is closed; PM does not self-certify a code fix.

### Stage 5 — code-reviewer (round 2) · 2026-07-31

- Report returned as text; **PM persisted `05_CODE_REVIEW.md` verbatim, replacing round 1.** The round-2 report is self-contained: its §0 carries every round-1 finding with disposition.
- Verdict: **APPROVED WITH NITS** — 0 CRITICAL, **0 MAJOR**, 5 MINOR, 2 NIT. Axis status: Standards-conformance worst = MINOR; Spec/design-fidelity worst = MINOR; aggregate = MINOR.
- **M-1 CLOSED**, verified by the reviewer in all four installer files across both shells (not on the developer's paste). FC-1 still returns zero `guard-rm` hits with both literals restored — the round-1 prediction held. FC-2/FC-3 undisturbed; **FC-4 now PASS** on the question round 1 marked PARTIAL. The reviewer walked six degradation classes and confirmed: **no path in any shell, OS variant or boundary row where a missing guard yields exit 0.**
- The new executable FC-4 assertion was checked for vacuity and **discriminates specifically against the reverted `> 0` branch** — the truncated id set still contains `guard-rm`, so the literal restore alone would not catch it; only the `== 4` check does.
- The byte-identity claim was granted on structural grounds: M-1's edits touch only the validation path, never the JSON body assembly, and `n_wired` is *forced* to 4 on any run reaching the body — so byte-identical output is a necessary consequence, not a coincidence.
- **Archive contradiction: closed, and the reviewer says "well beyond the bar."** Every detail of the captured evidence cohered with its own round-1 mechanism analysis, including which of the two predicted failure branches fired. Annotations verified genuinely **append-only** by reading both archived files — originals survive verbatim, corrections are dated attributed blockquotes. The reviewer explicitly notes the archive edit **would have been an out-of-scope violation without the coordinator's grant**, so the grant is load-bearing and must be recorded in `07_DELIVERY.md`.
- Baseline re-derived from source by the reviewer: 45 + 31 = 76; 278 + 76 = **354**, matching `baseline.json`. Three independent routes now converge on 278. Both frozen README badges intact in both files; `insight-index.md` correctly not pre-appended.
- Open items at exit: **r-1** (contrived duplicate-id residual in FC-4 — reviewer recommends *recording* it as a known bound and handing it to QA as a mutation target rather than adding code this late), **r-2** (FC-4 row hardening), **r-3/r-4** (binding operator items 6 and 7), **n-6/n-7** (doc wording), **r-5** (PM-owned ledger row D11).
- The reviewer explicitly hands QA three claims it could not execute — `verify_all` 32/0/0, `test-init.sh` 354/0, and the `cmp` byte-identity — to **re-capture independently rather than inherit**, on the exact principle this task just spent a round establishing.
- No `BLOCKED: NEEDS-HUMAN`. Nothing owed by the solution-architect in either round.
- **Consecutive-rollback counter at stage 4 resets to 0** (stage cleared).
- `.harness/intervention.md` re-checked after stage 5 round 2: **absent**.
- **PM routing decision: ADVANCE to stage 6 (qa-tester)**, carrying r-1 and r-2 as the reviewer's nominated adversarial targets and the three inherit-nothing re-capture obligations.

### Stage 6 — qa-tester (round 1) · 2026-07-31

- Output: `06_TEST_REPORT.md` (372 lines, under cap), **with the mandatory `## Adversarial tests` section present** — gate condition satisfied.
- Verdict: **PASS WITH DEFECTS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 3 MINOR / 1 NIT (+1 MINOR PM-owned). QA states delivery may proceed.
- **Mandate 1 (inherit nothing) discharged**: `verify_all` **32/0/0** captured **3×**, check count 32, green **from the bootstrapped state**; `test-init` **354/0** (no-python3, 3 SKIP) and **390/0** (python3), both matching `baseline.json`. The `cmp` had to be **reconstructed** — the pre-M-1 installer no longer exists on disk — so QA rebuilt it from the M-1 delta and ran both in identical fixtures: byte-identical, `sha256 536f3e01…` on both sides and on the live dogfood file.
- **Mandate 2 (adversarial, artifact-mutated)**:
  - **r-1 CONFIRMED empirically** — `tools` emitting `guard-rm` ×4 → installer **exit 0**, file created, `jq '.hooks|keys'` → `["PreToolUse"]`. QA's verdict: a real bound, not a live defect — **but wider than the review recorded**: 3 of 7 degradation rows exit 0 with a partial wiring.
  - **r-6 (NEW, QA-found)** — 4 ids *excluding* `guard-rm`: run 1 correctly exits 5 but leaves the **guardless file present**; §8 row 3 keys on presence alone, so **run 2 exits 0** with "left byte-untouched". Loud-then-quiet.
  - **r-2 both halves proven** — arity reverted to `> 0` → the FC-4 row goes red (389/1), so the row **is** load-bearing; but with a silently broken stub the suite is 390/0 with the row green, so the vacuity vector is real.
  - QA verified a **2-line distinct-event-count patch** closing r-1 + r-6 + the mixed-duplicate case: all three offending rows become **exit 4, nothing written**; happy path output byte-identical (same sha256); `test-init` 390/0 with the assertion count unmoved. **QA correctly did not apply it** (production code with an agent-unexecutable PS twin — Hard rule 1) and routed it to the developer via PM.
- **Mandate 3**: AC-1…AC-9 and AC-11…AC-14 verified by execution with a stated failure hypothesis each. AC-3 independence proven **in both directions** (16 comparisons vs **two** live oracles, plus an artifact mutation turning exactly the mutated cell red). **NFR-2 hard boundary HOLDS** — 6 missing/unreachable-guard variants × 10 reps → exits 126/127/2, **never 0**. 44 boundary assertions green across the §8 truth table. No flakes across 3-10 repetitions of every suite.
- **Mandate 4**: zero regression delta on every driver (90 / 89 / 58 / 39 / 45 / 354 / 32); `sync-self --check` and `harness-sync --check` both `In sync.`; `baseline.json` needs no update — every pinned key already equals a run made this session. Badges, decoys and check count all frozen.
- No PowerShell claims made. Seven operator items stand; **no eighth surfaced** (one conditional 8th if the r-1 patch lands). QA confirms the PS twin carries the identical r-1 residual, so r-1/r-6 are shared-logic bounds, not PS-specific.
- No `BLOCKED: NEEDS-HUMAN`. Nothing owed by the architect or the analyst — QA explicitly clears both (r-6 is a consequence the design named; the fix belongs in the installer).
- `.harness/intervention.md` re-checked after stage 6: **absent**.
- **PM routing decision: ROLLBACK #3 → stage 4 (developer)** to apply the QA-verified patch, despite QA rating the findings non-blocking. Rationale, stated as a routing call and not a professional judgment about the patch (QA already verified it empirically): **r-6 leaves a guardless `.claude/settings.local.json` on disk that a subsequent run blesses with exit 0.** The artifact this task ships is the hook wiring; a persisted guardless wiring that later reports green is exactly the silent-degradation class the coordinator singled out when rejecting the same shape in M-1. The code reviewer's earlier "record it, don't add code this late" recommendation was made **before** r-6 existed and against r-1 alone, which is materially narrower. The patch is 2 lines, leaves the happy path byte-identical, and moves no tally. Consecutive-rollback counter at **stage 4: 1 of 3** (counter had reset when CR round 2 cleared the stage).

### Stage 4 — developer (rework round 2) · 2026-07-31

- Applied the QA-verified distinct-event-count gate in all four halves (`install-hooks.sh:205-214`, `.ps1:244-259`, plus both template twins), hardened the FC-4 row (r-2) and corrected the n-6 header falsehood in all four files **and** in `CHANGELOG.md`.
- **The routing decision was vindicated: the developer found three defects rather than copying the handed patch.** (i) An **FC-1 regression he introduced himself** — his first comment draft used the literal token `guard-rm`, taking FC-1's grep from 0 → 4 hits across all four installers; caught and reworded. (ii) A **real defect in QA's handed PowerShell form** — PowerShell's binary `-join` binds *looser* than `+`, so the diagnostic re-associated and failed **silently with no error**; rebuilt with `-f`. (iii) The same class in the PS capture (hand-joined array instead of `| Out-String`, which would re-wrap at host buffer width and could split the matched phrase).
- Captured: `verify_all` **32/0/0**; `test-init` 390/0 (py3) and 354/0 (no-py3); all other drivers at baseline; both `--check`s In sync. **No numeric `baseline.json` key moved** — only the eighth NFR-5 operator item appended. Verdict: **READY FOR REVIEW**.

### Stage 5 — code-reviewer (round 3, targeted) · 2026-07-31

- Addendum appended verbatim to `05_CODE_REVIEW.md` (round 2's body retained). Verdict: **APPROVED WITH NITS** — 0 CRITICAL, 0 MAJOR, 1 new MINOR, 5 NIT.
- **r-6 confirmed genuinely closed, and closed the right way**: the refusal precedes every filesystem effect in both shells and all four halves, so the guardless residue cannot come into existence; §8 row 3 verified byte-unchanged, so the deliberate design is intact.
- The reviewer proved the closure is **stronger than the developer's own comment argues**: since events are a function of tools, `distinct events ≤ distinct tools ≤ 4`, so `n_distinct == 4` forces the full tool set and hence the guard's presence — **without** assuming the event map is injective.
- Verified the PowerShell `-join`/`+` precedence claim against documented operator precedence and confirmed the silent no-error failure mode. Re-ran the FC-1 grep itself: zero hits across all four installers.
- Judged the developer's abstention from re-running the 6×10 NFR-2 probe **sound, not a gap** (guard/spec files untouched; generated bytes structurally forced; an in-suite live-output guard assertion did re-run).

### Stage 6 — qa-tester (round 2, targeted) · 2026-07-31

- `06_TEST_REPORT.md` updated in place (491 lines, cap 500) with a `## Round 2 — post-patch verification` section; the `## Adversarial tests` section is **retained and extended** — gate condition still satisfied.
- Verdict: **PASS WITH DEFECTS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 1 MINOR / 2 NIT (+1 PM). **r-1, r-6, r-2 and n-6 all confirmed CLOSED.** Every number re-measured this session; nothing inherited.
- Key confirmations: matrix rows 2/3/4 → exit 4 ABSENT **and their second runs also exit 4** (the point of the routing decision); happy-path sha re-derived independently as `536f3e01…`; r-2 non-vacuous both directions (389/1 each, FC-4 the only red); live dogfood `cmp` byte-identical; gate 32/0/0 across 3 runs; zero regression delta.
- **QA re-ran the NFR-2 probe the developer declined** — 6 variants × 10 reps → exits `127/126/127/2/2/2`, **0 exit-0 paths**. Its comment on the abstention is the right standard: *"his reason was sound as read, but 'unchanged file' is an argument, not evidence."*
- **QA-process finding, self-reported**: its round-1 handed patch gave a complete bash form but **only the count expression for PowerShell, no diagnostic** — so the developer had to compose the PS message and hit the `-join` trap doing it. QA states the gap is its own. Recorded; this is the honest-disclosure behaviour the pipeline is meant to produce.
- **New QA MINOR r-7**: the distinct-events gate has **zero anti-revert coverage** — QA deleted both gate lines from both bash halves and got `test-init` 390/0 and `verify_all` 32/0/0, fully green. QA further rebuts the developer's stated ground for declining an in-suite row ("assertion count had to stay unmoved") as **not a rule that exists** — the scope bar forbids a new *driver pair*, and rework 1 already moved that same key 353 → 354 from a capture.
- **PM accepts the rebuttal, and notes the constraint traces to PM's own brief** — the rework-2 dispatch restated QA's measurement ("assertion count unmoved") as part of the required end state, which the developer reasonably read as binding. PM caused the omission and will correct it.
- **PM routing decision: ROLLBACK #4 → stage 4 (developer)**, final short round. Rationale: a gate PM itself forced into existence currently has no regression coverage, which is precisely the "prove the gate is real by mutating the artifact" principle this task has enforced on every other surface. Consecutive-rollback counter at **stage 4: 2 of 3** — one round remains before the three-strike stop applies.

### Stage 4 — developer (rework round 3, final) · 2026-07-31

- Added the in-suite anti-revert row per twin (`test-init.sh:996-1018`, `.ps1:1223-1252`), re-enumerated the stale operator site list in `baseline.json:_qa_note_t13`, fixed the two citation nits, and recorded n-7/n-10/n-11 as known bounds. Baseline `354 → 355` **from a capture**.
- Captured: `verify_all` **32/0/0**; `test-init` 391/0 (py3) and 355/0 (no-py3); all other drivers at baseline; both `--check`s clean; dogfood `cmp` still byte-identical at `sha256 536f3e01…`. FC-1…FC-4 re-verified. Verdict: **READY FOR REVIEW**.
- Declined n-7 with a stated reason (closing it needs unverifiable PS code in four halves to defend against a spec that has already broken its own totality contract). Confirmed the new PS row adds **no ninth** operator item — it widens three existing ones.

### Stage 6 — qa-tester (round 3, final confirmation) · 2026-07-31

- **First dispatch died mid-flight** (API connection closed) after completing its runs but before persisting the report; `06_TEST_REPORT.md` was unchanged, so PM re-dispatched a fresh agent with an instruction to persist incrementally. Nothing was inherited from the lost run.
- Output: `06_TEST_REPORT.md` at exactly 500 lines (cap), rounds 1-2 compacted, **all three `Adversarial tests` sections retained** (§3, §12.2, §13.4) — gate condition satisfied.
- Verdict: **PASS** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR / 2 NIT record-only (+1 PM). **r-7 CLOSED by measurement, not by argument.**
- QA re-ran the full mutation matrix in a scratch clone (live tree never mutated, all six `sha256sum -c` OK on restore) and confirmed every number. It also **corrected the developer's framing**: row C is not a partition case — deleting the count leaves the variable unset and reddens every downstream row, which is loud but proves nothing about partitioning. A and D redden disjoint singletons; that is the real partition evidence.
- QA independently probed the n-7 decline rather than accepting it, established the bypass is reachable only by editing `hook-spec.sh` itself (whose `hs_event` is a `case` over four compile-time literals with no external input), and judged the decline **honest and adequately reasoned — record-only, no escalation**.
- Confirmed the eight-item operator accounting is accurate and closed n-8. Confirmed the stray untracked `docs/proposals/frontier-gaps-2026-07.md` is gate-neutral by measurement (32/0/0 both with it present and parked) and should not ride along in the commit.
- `.harness/intervention.md` re-checked after stage 6 round 3: **absent**.

### Stage gate check before stage 7

- Stage 5 (round 3) = **APPROVED WITH NITS**, 0 MAJOR. Stage 6 (round 3) = **PASS**, 0 MINOR. Both PASS — delivery gate satisfied.
- QA's report carries an `## Adversarial tests` section — task-level gate condition satisfied.
- `verify_all` **PASS 32 / WARN 0 / FAIL 0**, check count 32.

### Stage 7 — PM delivery · 2026-07-31

- Wrote `07_DELIVERY.md` (stages, 4 rollbacks with causes, final gate numbers, baseline deltas, file list, what was proven and how, 7 record-only outstanding items, 4 harvested insights).
- Closed the PM-owned ledger row **D11 / r-5**: `docs/tasks.md` active row removed, completion entry added to the Completed table. The historical `T-13 lang-policy-split` row was left untouched (the ID-collision decoy the gate flagged).
- **Entropy watch: deliberately SKIPPED.** The pm-orchestrator cadence block is the `/harness` single-task delivery surface; this task was dispatched from a `/harness-stream` drain, and the stream owns the entropy watch at its own drain boundary. Running it here would double-increment the shared `entropy-cadence` counter. The cadence is non-blocking and fail-open by contract, so skipping costs nothing. (PM also has no shell in this runtime and could not have run `entropy-cadence` regardless.) Recorded so the stream can fire its own boundary normally.
- **PM has no Bash tool in this runtime**, so `git diff --stat` could not be produced — the file list in `07_DELIVERY.md` is assembled from the design's change ledger as verified by the code reviewer, and is labelled as such. `archive-task` was delegated to a shell-capable agent rather than skipped.
