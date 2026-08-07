# Code Review — T-14 `hook-truth-status`

**Stage 5 (code-reviewer)** · Date 2026-07-31 · **deferred-human mode**: defer, do not ask (no `AskUserQuestion` called).
**Verification limits, stated up front**: this reviewer has `Read`/`Glob`/`Grep` only — no shell. Every reported run tally was therefore cross-checked **against the artifact that allegedly produced it** (driver source, settings files, `hook-spec.sh`), never against arithmetic on the stage docs (`.harness/insight-index.md:35`).

> Persisted verbatim by PM Orchestrator — the code-reviewer contract carries no `Write` tool. No PM content edits.

## Files reviewed

- `/home/alan/Programs/harness-kit/skills/harness-status/SKILL.md` (the whole product edit)
- `/home/alan/Programs/harness-kit/CHANGELOG.md:42-79` (the new subsection)
- `/home/alan/Programs/harness-kit/docs/features/hook-truth-status/04_IMPLEMENTATION.md`
- Cross-checked against: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md` (round 2), `03_GATE_REVIEW.md` §R2-6/§R2-8
- Artifacts consulted as evidence: `.harness/scripts/test-supervisor.sh`, `.harness/scripts/baseline.json`, `.harness/scripts/hook-spec.sh`, `.harness/scripts/verify_all.sh`, `.harness/insight-index.md`, `.claude/settings.local.json`, `skills/harness-upgrade/SKILL.md`, `.harness/rules/70-doc-size.md`, `docs/tasks.md`

---

## Adjudication 1 — the `test-supervisor` tally (PM-routed)

**The 46 is real, and it came from the artifact.** Independent static reconstruction of `.harness/scripts/test-supervisor.sh` yields exactly **46** logical `assert` call-sites in one run: AC-1.1-1.6 (6), AC-2.1-2.3 (3), AC-3.1-3.4 (4), AC-4.1-4.6 (6), AC-5.1-5.4 (4), AC-6.1-6.8 (8), AC-7.1-7.4 (4), I.7-emu ×4, BUG-2 ×3, F-4.1, doc fan-out ×3. No path skips an assertion on a python3-present host, and 45 is unreachable there. The self-execution transcript is likewise corroborated at source: `K = 1` and `matcher "Bash"` (`.claude/settings.local.json:16-25`), the guard command bytes (`:22`), 4 hooks keys (`:5-47`), the `tools` order `harness-sync/guard-rm/ambient-prompt/ambient-reset` (`hook-spec.sh:120`), `matcher guard-rm → Bash` (`:83-88`), `semantics guard-rm → fail-closed` (`:90-95`). **NFR-6 is satisfied on the numbers.**

**But the Developer's *diagnosis* is false, and that is the finding.** `baseline.json:16`'s key is `test_supervisor_bash_no_python3_assertions`. AC-7.3 (`test-supervisor.sh:293-310`) sits inside `if command -v python3 …; then` with **no `else` branch**, so the driver produces **45 without python3 and 46 with it**. `45` is therefore the *correct, current* value of that key, not a value stale since v0.31.0. The convention is documented in the same file: `baseline.json:23` (`_qa_note_t13`) records `355` as the no-python3 test-init tally while "the python3-present run captured 391 in the same tree" — a python3-present run legitimately exceeding a `*_no_python3_*` key is the established, intended state, not drift.

**Adjudication**: leaving `baseline.json:16` untouched is **correct** — but for the opposite reason to the one recorded. It is not "a stale key nobody may move in this ledger"; it is **a correct key that must not be moved at all**. The Developer's routed action item and harvested insight would push a *wrong* edit into a frozen count and a *false* line into the 30-line permanent memory. See **MAJOR-1**.

## Adjudication 2 — the self-declared §3c design drift (PM-routed)

**Judged CORRECT and in ledger. This is reviewed and accepted drift, not unreviewed drift.**

Re-pointing §3c's `DANGLING` / `MALFORMED` fix lines at §7 (`skills/harness-status/SKILL.md:279-286`) is **required**, not optional:

- FR-8's final sentence is report-wide and absolute — *"The report never prints a fix instruction that cannot reach the file it named."* It is not scoped to §3b.
- Design §5.3 is titled *"Fix lines (FR-8) — reachability is the whole point"* and is written as a report-wide contract; design §3.5 already required §7's blanket `/harness-upgrade` to become conditional. A §3c-local duplicate of that same blanket line is part of the blanket recommendation the design retired, not a separate surface.
- Leaving it would have shipped, on this very repository (`SOURCE_KIND = machine-local`), an FR-8 violation inside the document whose purpose is removing that class — design risk R-7 realised.
- NFR-2 is intact, verified at the consumer: `skills/harness-upgrade/SKILL.md:29-33` triggers on the **tokens** `DANGLING` / `MALFORMED`, which are byte-unchanged; the committed-wiring branch still names `/harness-upgrade`, including the MALFORMED "actual repair" parenthetical.

The Developer's named 8-line revert should **not** be taken. One byte-level nit inside the accepted change is filed as MINOR-1.

---

## Findings

### CRITICAL

None.

### MAJOR

- **MAJOR-1** · [EVIDENCE / STANDARDS] `docs/features/hook-truth-status/04_IMPLEMENTATION.md:262-271`, `:459-461`, `:486-490` — **A false causal claim about repository state, routed as an action item and queued into permanent memory.** The document asserts *"the `45` in `baseline.json` has been stale since v0.31.0"*; `.harness/scripts/test-supervisor.sh:293-310` (python3-gated AC-7.3) and the key's own name (`baseline.json:16`, `…_bash_no_python3_assertions`) prove `45` is the correct no-python3 tally, corroborated by the same file's `_qa_note_t13` precedent (`baseline.json:23`). Three downstream consequences make this fix-before-merge rather than a wording nit: (a) Open issue 1 routes PM/QA to *"reconcile it under a task that owns `baseline.json`"* — reconciling it to 46 would corrupt a correct frozen count and break the cross-shell/no-python3 convention shared by five other keys; (b) the `## Insight to surface` block would land that false claim in `.harness/insight-index.md`, a 30-line always-loaded memory, via `archive-task` at stage 7; (c) it mis-frames AC-10 for QA. **Required remediation (documentation only — no `SKILL.md` or `CHANGELOG.md` byte changes):** rewrite the tally note to state that 46 is the python3-present tally of a key defined for the no-python3 condition, that `baseline.json:16` is **correct and must not move**, and that AC-10 holds because the count did not move across this task's edits (46 → 46); withdraw Open issue 1; replace the harvested insight (the real, defensible one is *"a `*_no_python3_*` baseline key is not comparable to a python3-present run — a design quoting it as a run expectation mis-derives its expectation"*, which is what design §10.1 step 3 did). **Owner: Developer.** Secondary, non-blocking: `02_SOLUTION_DESIGN.md` §10.1 step 3 and §10.2's `(45/0, assertion count unchanged)` carry the same mis-derivation — PM should hand QA the corrected expectation (**46/0 on a python3-present host; 45/0 without python3**) so QA does not report a false FAIL or "fix" the baseline.

### MINOR

- **MINOR-1** · [DESIGN] `skills/harness-status/SKILL.md:279-283` vs `:340` — inside the (accepted) §3c re-point, the committed-wiring case restates the fix as `run /harness-upgrade to re-land current scripts and rewire hook paths`, while §5.3's pinned string, shipped correctly at `:340`, is `run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json`. Two byte-forms of one pinned contract in one document: a QA byte-assertion could be written against either, and it re-duplicates a string §7 now single-sources. Suggested: keep the pointer at §7's table and drop the inline restatement (or reproduce §7's exact bytes).
- **MINOR-2** · [REQ residual] `skills/harness-status/SKILL.md:287-290` — the §3c interpreter WARN still tells the reader to *"see the `_doc_sync_hook` / `_ambient_hook` notes in `settings.json`"*. This is the last live hardcoded committed-settings pointer in a section this task de-hardcoded; on this repository those notes live at `.claude/settings.local.json:3-4` and `.claude/settings.json` carries none — an advisory that cannot reach the file it names (FR-8's class). Design §3.4 lists this WARN as **unchanged**, so leaving it is design-faithful and **not drift**; it belongs on the backlog next to the Developer's own Open issue 2 (the same WARN names only `pwsh`/`bash` and can never fire on this repo's `sh`-prefixed commands). **Owner: PM (backlog), not Developer.**
- **MINOR-3** · [LOGIC/FR-18] `skills/harness-status/SKILL.md:41-45`, `:71`, `:161` — `UNKNOWN_FILES` is a list, but both the §0 form-5 line and §3b row 1 render a singular `<file>`; and Step 0.2's *"every hook line carries the not-certified qualifier"* pins no string, so two competent agents will word and place that qualifier differently (and QA cannot assert it in P-11). Also unpinned: when a candidate is `unreadable` **and** the other resolves (C1 broken, C2 present), the report prints one `Hook source: UNKNOWN …` line naming the broken file while §3c's header names the resolved one — determinate, but the reader is given two different "sources" with no sentence tying them together. Inherited verbatim from design §5.1/§5.2 (a) and gate-approved, so **not developer drift**; worth a pinned form in a follow-up.
- **MINOR-4** · [SAFETY residual, no action in T-14] `skills/harness-status/SKILL.md:168` + `:196-205` — a guard entry whose matcher is e.g. `Write` never fires on a Bash call, yet lands on row 8 with **+1** and only a `— non-canonical matcher` suffix. This is a false-green class of the same family as gate F-9, and it is **explicitly mandated** by FR-9 (*"never reported as wiring absent"*, matcher printed and flagged) and pinned by design §3.3, so it is not a defect of this delivery. Flagging so it is on the record next to F-9's residual; **Owner: PM (backlog / T-15 scope question)**.

### NIT

- **NIT-1** · [DOC SIZE] `docs/features/hook-truth-status/04_IMPLEMENTATION.md` is 502 lines against the 500-line per-stage-doc soft cap in `.harness/rules/70-doc-size.md:30`. No gate check enforces it (verified: `verify_all.sh` has no stage-doc size check), and the MAJOR-1 rewrite will likely absorb it.

---

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 precedence, non-empty-hooks predicate | `SKILL.md:20-31, 47-50` | PASS |
| FR-2 name the source | `:64-74` (all five forms name >=1 path), `:96`, `:161-168`, `:252-253` | PASS |
| FR-3 committed arrangement unregressed | `:47-48` (C2 wins when C1 not `present`), `:69` | PASS |
| FR-4 both declare | `:49` (`OTHER_DECLARES`), `:68` | PASS |
| FR-5 three states, never collapsed | `:159-168` rows 4 / 5-7 / 8 | PASS |
| FR-6 healthy wording pinned | `:168` | PASS |
| FR-7 dangling prints evidence, no point | `:165-167` (command + missing path), Point column `no` | PASS |
| FR-8 reachable fix line | `:219-220`, `:338-345` (6 branches), `:279-286` | PASS |
| FR-9 matcher reported not assumed | `:150` (regardless of matcher), `:196-197`, `:202-205` | PASS |
| FR-10 interpreter + fail-closed consequence | `:198-199`, `:206-211` | PASS |
| FR-11 existence on referenced script only | `:152-155`, `:317-319` ("other twin not required") | PASS |
| FR-12 never installed | `:57`, row 2 `:162`, fix `:343` | PASS |
| FR-13 opt-out distinguished | `:58-62`, row 3 `:163`, `:344` | PASS |
| FR-14 unreadable is its own state | `:29`, `:41-45`, row 1 `:161`, `:345` | PASS |
| FR-15 congruence same source, vocabulary intact | `:248-258`, `:275-286` | PASS |
| FR-16 enumeration from spec + labelled fallback | `:224-246` | PASS |
| FR-17 asset row + point location-aware, 14/12 | `:94-103`, `:313`, `:317-320` | PASS |
| FR-18 executable as written | first-match table `:157-168`; set quantifiers `:170-181` | PASS (MINOR-3 edges) |
| FR-19 read-only | `:74-75`, `:349`, `:359-360` | PASS |
| FR-20 documentation truthful | `CHANGELOG.md:42-79`; no other live doc makes a hook-source claim (verified: `verify_all.sh` references `harness-status` only in the 17-skill name arrays at `:56,339,355`) | PASS |
| AC-1 real-state proof (guard wired, source `.claude/settings.local.json`) | `04:295-339`; corroborated at `.claude/settings.local.json:16-25` | PASS (QA re-captures) |
| AC-2 congruence all `ok`, same source | `04:341-376`; all four scripts exist (`Glob .harness/scripts/*.sh`) | PASS (QA re-captures) |
| AC-3…AC-8 fixture probes | Document supports every probe (rows 1-8 + §5.3 branches + fallback `:241-246`) | QA-owned |
| AC-9 gate 32/0/0, 14 rows, denominator 12 | `04:174-204`; rows counted 14 at `SKILL.md:81-94`; `:313`, `:320` | PASS |
| AC-10 supervisor green, count unchanged | 46 -> 46, both fan-out assertions green (`:105` matches `\(7 \+ supervisor\).*plugin-provided`; `{pm,req,sol,gate,dev,review,qa}*` count 0) | PASS **with the MAJOR-1 correction** — the run is comparable to itself, not to a `no_python3` key |
| AC-11 no hook behavior changed, file set confined | delta = one line (`04:396-414`); no `.ps1`, no `verify_all`, no driver, no `docs/tasks.md` (T-14 row still reads stage 1 at `docs/tasks.md:9`), no `insight-index.md` (30 evidence lines, zero T-14 matches) | PASS |
| AC-12 release-claim consistency | Branch A: subsection under existing `## [0.45.0]` (`CHANGELOG.md:8`, `:42`); no stamp moved | PASS |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.1 §0 with six-field interface, 4-state probe, tie rule, "this table wins" | `SKILL.md:15-75` | PASS |
| §3.3 8-row table, total / mutually exclusive / first-match-wins | `:157-168` — totality verified: `UNKNOWN` -> rows 2-3 (`SOURCE=none` => C1 in {absent, empty}) -> row 4 -> rows 5-8; no gap | PASS |
| §3.3 quantifiers over `PATHS` / `GUARD_PATHS`; row 8 is the only healthy row | `:152-155`, `:167-168`, `:170-181` | PASS — no remaining path to `INSTALLED AND WIRED` on a non-running guard except the two disclosed residuals (gate F-9; MINOR-4) |
| §3.3 byte-form pin, unescaped `.` before `(ps1\|sh)` | `:263` `(^\|["' =])(\.harness/)?scripts/<name>.(ps1\|sh)` | PASS — copied, not retyped |
| §3.5 `Present?` predicate (rows 5-8) + stated asymmetry vs `+1` | `:96-103` | PASS |
| §5.1 five `Hook source:` forms | `:67-71` | PASS verbatim |
| §5.2 (a) ten verdict forms incl. multi-path row 7/8 and row 6 wording | `:161-168` | PASS verbatim |
| §5.2 (b) multiplicity adjunct | `:194-195` | PASS |
| §5.2 (c) interpreter adjunct, both forms | `:198-199` with `<semantics>` slot | PASS (F-11 substitution, stated) |
| §5.3 four fix-line rows incl. `machine-local ∧ OTHER_DECLARES = true` => removal **alone**, installer **not** chained | `:342` | PASS verbatim |
| §5.4 congruence header + fallback label | `:252-253` | PASS |
| §3.2 query plan, `N+3` = 7, twin-of-own-shell, never `command`/byte-compare | `:224-239` | PASS |
| §3.4 §3c vocabulary/pattern/resilient note/interpreter WARN unchanged | `:254-290` | PASS except the two fix-line bullets — **accepted drift, see Adjudication 2** |
| §7.3 structural pin survives unbroken | `:105`; retired glob absent (0 matches) | PASS |
| Frozen counts: 14 rows / 12 denominator / 32 checks / 17 skills | `:81-94`, `:313`, `:320`; `verify_all.sh:56,339,355` untouched name arrays | PASS |
| No `.ps1`, no twin to sync | `Glob **/harness-status/**` -> single file; `sync-self.sh` has zero `harness-status` references | PASS |
| OQ-6 Branch A | `CHANGELOG.md:42` under `:8`; 96 insertions / 0 deletions | PASS |
| §R2-8 condition 1 (F-9 bound) | `04:80-96`; skill text agrees — `:176-178` says *"in a non-extractable position"* | PASS |
| §R2-8 condition 2 (F-10 row-4 adjuncts) | `04:98-108`; skill agrees — `:189-191` *"printed in rows 5-8 only … Rows 1-4 … no adjunct at all"* | PASS |
| §R2-8 condition 3 (F-11 substitution + `N+3` = 7) | `04:110-131`; skill `:199`, `:209-211`, `:236` | PASS |
| §R2-8 condition 4 (pre-edit baseline; insight-index never hand-edited) | `04:12-59`; `.harness/insight-index.md` = 30 evidence lines, zero T-14 matches | PASS |

## Axis status

- **Standards-conformance**: **2 findings, worst = MAJOR** — MAJOR-1 (false causal claim routed as an action item and queued into `.harness/insight-index.md`, against `.harness/rules/05-insight-index.md`'s evidence contract and the repo's own 2026-07-31 tally insight), NIT-1 (stage-doc soft cap). Everything else on this axis is clean: no invented rules, edit ledger honored, frozen counts intact, cross-shell parity untouched (no `.ps1` in the delivery, correctly disclosed under NFR-5), structural pin unbroken.
- **Spec/design-fidelity**: **4 findings, worst = MINOR** — MINOR-1 (a pinned §5.3 string restated in a second byte-form), MINOR-2 (design-frozen §3c WARN's unreachable `settings.json` pointer), MINOR-3 (design-inherited unpinned `UNKNOWN` qualifier / singular `<file>`), MINOR-4 (FR-9-mandated non-canonical-matcher residual, backlog only). No CRITICAL and no MAJOR: every FR maps to shipped text, every §5.1-§5.4 pinned string ships verbatim including all round-2 additions, the §3.3 table is total and first-match-wins, and the one self-declared drift is adjudicated **correct and in ledger**.

## Verdict

**CHANGES REQUIRED (0 CRITICAL, 1 MAJOR)**

The shipped product — `skills/harness-status/SKILL.md` and the `CHANGELOG.md` subsection — is **approved as-is and needs no byte change**. The single MAJOR is confined to `04_IMPLEMENTATION.md`'s tally note, Open issue 1 and the harvested insight, and must be corrected before this reaches QA and `archive-task`, because as written it routes a wrong edit at a correct frozen count and would plant a false line in permanent memory. Route to **Developer** (documentation fix, ~15 lines) and to **PM** for the two secondary hand-offs: correct QA's `test-supervisor` expectation to **46/0 (python3-present) / 45/0 (no python3)** with `baseline.json:16` explicitly out of bounds, and carry MINOR-2 / MINOR-4 to the backlog stream.

---

## Round 2 — delta re-review (documentation-only correction)

> Persisted verbatim by PM Orchestrator. No PM content edits.

**Stage 5 (code-reviewer), round 2** · Date 2026-07-31 · **deferred-human mode**: defer, do not ask (no `AskUserQuestion` called).
**Scope**: narrow delta. Product (`skills/harness-status/SKILL.md`, `CHANGELOG.md`) was approved as-is in round 1 and is **not** re-audited — only the byte-unchanged claim is spot-checked.
**Verification limits, unchanged**: `Read`/`Glob`/`Grep` only, no shell. Every claim below is checked against the artifact that allegedly produced it, never against arithmetic on stage docs.

### Delta verified

**1. MAJOR-1 — CLOSED at all three surfaces.**

| Surface | Round-1 defect | Round-2 state | Status |
|---|---|---|---|
| Tally note `04:255-270` | "the `45` … has been stale since v0.31.0" | States 46 is the **python3-present tally of a key defined for the no-python3 condition** (`:257-261`), that `baseline.json:16` is **"out of bounds for comparison in either direction"** and must not be reconciled to 46 (`:264-265`), and that **"AC-10's basis is self-comparison, not a baseline key … 46 → 46 on the same host"** (`:267-268`). Carries an explicit retraction marker (`:256`). | CLOSED |
| Open issue 1 `04:454-456` | routed PM/QA to "reconcile it under a task that owns `baseline.json`" | **"WITHDRAWN in round 2 … Nothing for PM/QA to reconcile here."** `reconcile` now appears only inside negations (`:264`, `:456`). | CLOSED |
| `## Insight to surface` `04:482-488` | false causal claim queued for a 30-line always-loaded memory | Replaced with the comparability claim + `evidence:` clause naming `test-supervisor.sh:293-310`, `baseline.json:16`, precedent `baseline.json:23`. | CLOSED |

The corrected diagnosis is **independently confirmed at source**: `test-supervisor.sh:293` opens `if command -v python3 … && python3 -c 'import json'`, AC-7.3's three `assert` call-sites sit inside it (`:303-308`), and the block closes at `:310` with **no `else`** — 45 without python3, 46 with. The `_qa_note_t13` precedent is real (`baseline.json:23`: "The python3-present run captured 391 in the same tree"). No false claim remains.

**Insight vs `.harness/rules/05-insight-index.md`'s contract**: passes. It is a discovery, not a rule or task summary (`:30-37`); evidence is included as required (`:27`); it is falsifiable and *was* falsified-in-practice — the adversarial test at `:28` ("would someone reasonable derive this in <10 min?") is answered empirically in the negative, because design §10.1 step 3, §10.2 and risk R-1 all mis-derived it. It is distinct from the existing 2026-07-31 tally line (`insight-index.md:35`), which is about fabrication, not comparability. Acceptable to harvest — see MINOR-5 for the one formatting hazard.

**2. No new false claim; no evidence lost in the compression to 499 lines.** All four §R2-8 gate conditions still fully stated: F-9 bound (`04:80-96`), F-10 row-4 adjuncts (`:98-108`), F-11 substitution + `N+3` = 7 (`:110-131`), the two preconditions (`:133-139`). Every evidence block from round 1 survives: pre-edit porcelain baseline (`:18-55`), `verify_all` summaries (`:176-198`), OQ-6 tripwire (`:208-226`), `test-supervisor` tail (`:234-243`), the §0/§3b/§3c self-execution captures (`:281-375`), the AC-11 porcelain delta and `git diff --stat` (`:394-406`), frozen-count spot checks (`:415-420`). NIT-1 (502 → 499 lines, `.harness/rules/70-doc-size.md:30`) is **closed**. The I.6-exemption claim at `:204` is true (`verify_all.sh:528,568` exempt the whole `docs/features/` subtree).

**3. Round-2 tally attribution (NFR-6).** `test-supervisor` is exemplary: three captures enumerated, round-labelled, and the pasted tail explicitly sourced — *"pasted once from capture (3) — this round's run"* (`:230-232`). `verify_all` is adequate but weaker — see NIT-2. Both round-2 tallies are also structurally forced: no product byte moved this round and `docs/features/**` is I.6-exempt, so 32/0/0 and 46/0 are the only possible results; `verify_all_checks: 32` is corroborated at `baseline.json:10`.

**4. Frozen artifacts untouched.** `.harness/scripts/baseline.json:16` reads `"test_supervisor_bash_no_python3_assertions": 45` — byte-unchanged. `.harness/insight-index.md` holds exactly **30** evidence lines with **zero** matches for `T-14` / `hook-truth-status` / `no_python3` / `baseline.json` — not hand-edited (§R2-8 condition 4 still holds).

**5. §3c adjudication landed correctly.** `04:443-444` now reads *"Round-2 status: adjudicated CORRECT and in ledger (CR Adjudication 2) … The revert offered here in round 1 was **not** taken; these 8 lines stand."* The revert offer is gone; the item is recorded as reviewed-and-accepted, not as unresolved drift.

**6. Round-1 MINOR routing.** MINOR-1 is recorded verbatim as **Open issue 6** (`04:468-470`) with the correct disposition (product not reopened for a MINOR; QA byte-assertion should target `SKILL.md:340`) — not silently dropped. MINOR-2 remains **Open issue 2** (`:457-460`) unchanged and unactioned, correct for a PM-owned backlog item. MINOR-4 is absent from the doc, which is correct — it was PM-owned; **PM must carry it to the backlog from this review, since `04` does not record it.**

**Product byte-unchanged — spot-check (not a hash; no shell).** Every line anchor cited in round 1 still resolves to the same bytes: `SKILL.md:177` (non-extractable position), `:189` (adjuncts rows 5-8 only), `:209` (`<semantics>` = `hook-spec semantics guard-rm`), `:234`/`:236` (`N+3` = 7), `:279-283` + `:340` (the two byte-forms of MINOR-1, both intact), and `CHANGELOG.md:42` (the `### Fixed — hook-truth-status (T-14)` heading). Consistent with the byte-unchanged claim.

### New findings (round 2)

#### CRITICAL / MAJOR
None.

#### MINOR
- **MINOR-5** · [EVIDENCE / STAGE-7 HAZARD] `04:482-488` vs `.harness/scripts/archive-task.sh:51` — the harvester is `awk … flag && /^[[:space:]]*-[[:space:]]/` over `07_DELIVERY.md`'s `## Insight` section: it collects **only physical lines beginning with `- `** and silently drops continuation lines. The insight as written is an unprefixed paragraph wrapping five physical lines, so if it is transcribed into `07_DELIVERY.md` with the same wrapping, everything after the first physical line — **including the entire `· evidence:` clause** — is discarded, and what lands in permanent memory violates `05-insight-index.md:27` ("Always include evidence"). Every existing entry (`insight-index.md:28-38`) is one very long physical line; match that. No defect in the reviewed delta — this is a forward hand-off. **Owner: Developer/PM at stage 7.** Record-only companion: the index is at 30/30, so this append rotates the oldest line (`:28`, 2026-06-19 / T-03) into `insight-history.md`; `archive-task.sh:59-91` handles that and I.4 stays green.

#### NIT
- **NIT-2** · [ATTRIBUTION] `04:183-204` — the fenced `verify_all` block at `:186-198` carries no round label, while the round-2 re-run is given only as an inline one-line summary (`:202-204`). A reader cannot tell which round produced the six pasted PASS rows. The tally is 32/0/0 under either reading so there is no fabrication risk here, but the labelling is asymmetric with the `test-supervisor` treatment at `:230-232`, which is the model. Suggested: label the block "round 1, after changes" and paste round 2's own `=== Summary ===`.
- **NIT-3** · [ACCURACY — inherited from my own round-1 wording] `04:265` — "break the no-python3 convention shared by **five other keys**". Exactly **one** other key carries the `no_python3` qualifier (`baseline.json:12`); there are five other *bash-side* keys (`:12,14,18,20,22`). Defensible under the bash-family reading, wrong under the literal one. This phrase originates in my round-1 MAJOR-1 text and was carried over faithfully — the imprecision is mine, not the Developer's. Not blocking; worth one word ("bash-side") if the doc is ever touched again.
- **NIT-4** · [HAND-OFF COMPLETENESS] `04:268-270` names `02_SOLUTION_DESIGN.md` §10.1 step 3 and §10.2 as carrying the mis-derivation; risk **R-1** (`02:566`) also states *"expected `PASS: 45 / FAIL: 0` from `baseline.json:16`"*. The note's general sentence ("46/0 on a python3-present host, 45/0 without python3") covers it, so QA is not misled; PM's hand-off should name all three surfaces.

### Requirement / design coverage

Unchanged from round 1 — the product did not move, so every row of both round-1 tables stands. One row is upgraded:

| Criterion | Implementation | Round-1 status | Round-2 status |
|---|---|---|---|
| AC-10 supervisor green, count unchanged | `04:228-270`; 46 → 46 same host, both fan-out assertions green (`SKILL.md:105`; `{pm,req,sol,gate,dev,review,qa}*` count 0) | PASS **with the MAJOR-1 correction** | **PASS** — basis correctly stated as self-comparison; `baseline.json:16` correctly out of bounds |

§R2-8 conditions 1-4: all four **PASS**, restated and unaltered.

### Axis status (updated, round 2)

- **Standards-conformance**: **3 findings, worst = MINOR** — MINOR-5 (archive-task harvest would truncate the insight's evidence clause at stage 7), NIT-2 (unlabelled `verify_all` capture), NIT-3 (imprecise key count, inherited from my round-1 text). MAJOR-1 is **closed**: no false causal claim remains, no wrong edit is routed at a correct frozen count, and the harvested insight now satisfies `.harness/rules/05-insight-index.md`'s evidence + adversarial-test contract. NIT-1 closed (499 ≤ 500, `70-doc-size.md:30`). `baseline.json` and `insight-index.md` verified untouched; frozen counts, cross-shell parity and the structural pin all still intact.
- **Spec/design-fidelity**: **5 findings, worst = MINOR** — MINOR-1 (carried, recorded as Open issue 6), MINOR-2, MINOR-3, MINOR-4 (all carried, PM-owned backlog), plus NIT-4 (design R-1 not named in the corrected hand-off). No CRITICAL, no MAJOR. The §3c drift is recorded as **adjudicated correct and in ledger**, the revert offer is withdrawn, and every FR/AC row from round 1 stands unchanged on byte-identical product text.

### Verdict

**APPROVED (0 CRITICAL, 0 MAJOR; 1 MINOR + 3 NIT new, 4 MINOR carried as backlog)**

The single round-1 MAJOR is closed at all three surfaces with a diagnosis I independently re-derived from `test-supervisor.sh:293-310` and `baseline.json:16,23`. No new false claim was introduced, no evidence block or gate condition was lost in the compression, `baseline.json` and `.harness/insight-index.md` are untouched, and the product is byte-unchanged. Proceed to **QA (stage 6)**.

Three hand-offs for PM, none blocking:
1. QA's `test-supervisor` expectation is **46/0 on a python3-present host, 45/0 without python3**, with `baseline.json:16` explicitly **out of bounds in either direction**; `02_SOLUTION_DESIGN.md` §10.1 step 3, §10.2 **and R-1 (`:566`)** all quote the superseded `45`.
2. At stage 7, the insight must enter `07_DELIVERY.md` as **one physical `- `-prefixed line** or `archive-task.sh:51` drops its evidence clause (MINOR-5).
3. Carry **MINOR-2** and **MINOR-4** to the backlog stream — `04_IMPLEMENTATION.md` records MINOR-2 as Open issue 2 but does not record MINOR-4 at all; this review is its only ledger.

---

## Round 3 — delta re-review (QA's two MAJORs)

> Persisted verbatim by PM Orchestrator — the code-reviewer contract carries no `Write` tool. No PM content edits.

**Stage 5 (code-reviewer), round 3** · Date 2026-07-31 · **deferred-human mode**: defer, do not ask (no `AskUserQuestion` called).
**Scope**: narrow delta against QA's two MAJORs. Rounds 1-2 findings are re-audited only for movement.
**Verification limits, unchanged**: `Read` / `Glob` / `Grep` only, no shell. Every claim is checked against the artifact that allegedly produced it — the shipped `SKILL.md` bytes, `install-hooks.sh`, `02_SOLUTION_DESIGN.md`, `baseline.json`, `verify_all.sh` — never against arithmetic on stage docs.
**Files re-read**: `skills/harness-status/SKILL.md` (whole file, now 376 lines), `docs/features/hook-truth-status/04_IMPLEMENTATION.md` (500 lines), `06_TEST_REPORT.md`, `02_SOLUTION_DESIGN.md` §3.1/§5.3, `CHANGELOG.md:42-79`, `.harness/scripts/install-hooks.sh:60-104`, `.harness/scripts/verify_all.sh`, `.harness/scripts/baseline.json`, `.harness/insight-index.md`, `.claude/settings.local.json`, `skills/harness-upgrade/SKILL.md:27-33`.

### 1. QA MAJOR-1 — CLOSED, and the totality claim is stronger than the Developer's 13-input evidence

`SKILL.md:29`'s `unreadable` row now ends: *"…, or it parses but a top-level `hooks` key is present whose value is **not** a JSON object (`[]`, a string, a number, `true`, `null`)"*. `:41-45` states totality and the reason.

**Totality re-derived structurally, not by sampling** — the 13-input table (`04:325-341`) is correct but is a sample; the property holds for *all* inputs:

| Input | Row |
|---|---|
| nothing at the path | `absent` (only match) |
| exists, not a regular file / `Read` fails / does not parse as a JSON object | `unreadable` (`empty`/`present` both require "Parses") |
| parses, `hooks` present, value **not** an object | `unreadable` — new clause |
| parses, `hooks` present, object, 0 keys | `empty` |
| parses, `hooks` present, object, >= 1 key | `present` |
| parses, no `hooks` key | `empty` |

The five branches partition the input space with no residue, so **every input lands on exactly one state** — and disjointly, not merely by first-match: `empty`/`present` require `hooks` absent-or-object, the new clause requires `hooks` present-and-not-object, and all three require a parse the earlier `unreadable` clauses exclude. `:41-45`'s stated reasoning ("`empty` and `present` are reachable only once `hooks` is known to be absent or an object") is the correct proof, not a restatement.

**No previously-classified input changed state — provable, not sampled.** The new clause's antecedent (`hooks` present and not a JSON object) matched *no* pre-fix row: pre-fix `unreadable` required a parse failure, `empty` required no-`hooks`-key or a 0-key object, `present` required a >=1-key object. The clause can therefore only capture inputs that previously matched nothing. QA's Reading B is now unreachable.

**Strict direction, and no new false-green path.** `unreadable` => `UNKNOWN_FILES` non-empty => Step 0.2 (`:47-51`) => `MACHINE_STATE = unknown`, which forbids `installed and wired` and any health point *regardless of the other candidate*; §3b row 1 is first in a first-match-wins table (`:163`, `:167`) so it pre-empts rows 2-8; §7 row 1 is now also first (fix 2). The fix moves inputs **only** in the direction unclassified -> `unknown` -> no point. It is also robust to the reading QA exploited: even an agent that thought the wrong-typed shape "also" satisfies `empty` gets the safe answer, because `unreadable` is ordered above `empty` under the table's own `(first match wins)` header at `:24`.

**The new asserted fact at `:43-45` is true — verified at the installer, independently of `04`.** `install-hooks.sh:83-89`: after the literal `"hooks"` and its `:`, if the next non-whitespace byte is not `{` the function returns `unparseable`. For `[]`, `"x"`, `null`, `3`, `true` that byte is `[`, `"`, `n`, `3`, `t` — **all five return `unparseable`**. So the shipped sentence "the installer's probe also calls that shape unparseable" holds for every shape the clause names, and the divergence table at `:37-39` ("stricter on two classes") stays exact — the new clause is a **convergence** with the installer, not a third divergence. It also restores a property design §3.1 asserts and the pre-fix text broke: *"for any file that parses as a JSON object, report and installer return the same state"* (`02:82-83`).

### 2. QA MAJOR-2 — CLOSED; six branches still individually reachable; no pinned string moved

- `:343-345` lead-in: *"conditional on §0's result, and **first match wins** — exactly one line, in this row order"*.
- `:347-354`: order is now `MACHINE_STATE = unknown` -> `never-installed` -> `opt-out` -> `SOURCE_KIND = committed` -> `machine-local and not OTHER_DECLARES` -> `machine-local and OTHER_DECLARES`. **The `unknown` row precedes all `SOURCE_KIND` rows.**
- `:356-361` states why the order is load-bearing, correctly: Step 0.2 lets resolution continue so `unknown` can coexist with a `SOURCE_KIND`, while `never-installed`/`opt-out` imply `SOURCE_KIND = none` and never contend.

**Reachability of all six, checked against the key algebra** (not against `04`'s run): `unknown` needs `UNKNOWN_FILES` non-empty (P-11); `never-installed`/`opt-out` are defined by Step 0.4 **only when `UNKNOWN_FILES` is empty** (`:58-59`), so row 1 cannot shadow them; the three `SOURCE_KIND` rows need `MACHINE_STATE = installed`, which excludes rows 1-3 by construction, and rows 5/6 partition `machine-local` on `OTHER_DECLARES`. **All six reachable, and the table is total over every non-healthy §0 result** — no input reaches §7 with no matching row.

**No §5.3 pinned string moved — verified two independent ways.** (a) All six cells at `:349-354` are byte-identical to design §5.3 `02:412-417`. (b) Four of the six were captured *verbatim by QA before this round* and still match: `:352` = `06:229`, `:353` = `06:240-241`, `:354` = `06:232` (the full 4-sentence `OTHER_DECLARES = true` string, including the `Do NOT chain the installer` clause and the exact installer early-exit quote), `:349` = `06:525`; `:350`'s `run /harness-adopt or /harness-upgrade` = `06:210`; `:351` = `06:214`. Only row order moved.

**Downstream coherence gained, worth recording:** §3b row 1 and §7 row 1 now key on the *same* predicate (`UNKNOWN_FILES` non-empty), so the verdict line and the fix line can no longer disagree about which file is in question — that is the actual repair, and it is structural rather than a wording patch.

### 3. Adjudication 3 — the §3c pointer at `:287-291`: **IN LEDGER**

**I own this call and I judge it CORRECT and in ledger — an in-scope extension of fix 2, not new scope.** Reasons, consistent with my round-1 Adjudication 2 (which established that FR-8 is report-wide, not §3b-scoped):

- It is the **same defect in the same state**, not an adjacent improvement. §3c's `DANGLING` bullet said "keyed on §0's `SOURCE_KIND`". In the exact P-11 state QA reproduced (C1 unreadable, C2 wires a dangling path), Step 0.2 lets resolution continue, so §3c *does* run against `SOURCE = C2` and *does* print `DANGLING` — with a fix line pointing at `SOURCE_KIND = committed` => `/harness-upgrade`, which cannot reach the file §0 named unparseable. Fixing only §3b/§7 would have shipped a live instance of the very FR-8 violation the round was convened to remove.
- FR-8's final sentence is absolute and report-wide; `SKILL.md:345` restates it report-wide. A fix that leaves one of the report's two fix-line pointers keyed wrongly does not satisfy it.
- **Byte-scope is minimal and NFR-2 is intact**: only the key phrase changed. The `DANGLING` / `MALFORMED` tokens `/harness-upgrade` triggers on (`skills/harness-upgrade/SKILL.md:29-33`) are byte-unchanged, the committed case still names `/harness-upgrade`, and the MALFORMED "actual repair" parenthetical (`:292-294`) still inherits the corrected key via "Same §7 fix line".
- It was **disclosed** at `04:363-367` rather than folded in silently, which is the behaviour the ledger discipline asks for.

No other §3c byte moved (`:230-301` otherwise matches my round-1 anchors, including the design-frozen interpreter WARN and the resilient-command note). Carried **MINOR-1 stands unfixed** — `:289-291` still restates §7's committed fix in a second byte-form (`run /harness-upgrade to re-land current scripts and rewire hook paths` vs `:352`'s pinned `run /harness-upgrade — it re-lands current scripts and rewires .claude/settings.json`). The Developer had those exact lines open and did **not** widen scope to a deferred MINOR: correct discipline. QA byte-assertions must target `:352`.

### 4. Regression sweep — everything rounds 1-2 approved is still in place

| Pinned / frozen item | Round-3 state | Status |
|---|---|---|
| Structural pin, one unbroken line | `SKILL.md:111` `(7 + supervisor) … plugin-provided` | PASS |
| Retired glob `{pm,req,sol,gate,dev,review,qa}*` | 0 matches | PASS |
| Retired `DISABLED — .claude/settings.json has no PreToolUse for Bash` | 0 matches | PASS |
| 14 asset rows | `:87-100` counted = 14; `:321` `All 14 … -> +6` | PASS |
| Denominator 12 | `:328` | PASS |
| 32 checks / 17 skills | `baseline.json:10` = 32; `verify_all.sh:56,339,355` each list the same 17 names | PASS |
| Extraction pattern, live bytes | `:271` `(^\|["' =])(\.harness/)?scripts/<name>.(ps1\|sh)` — escaped `\.harness/`, **unescaped** `.` before `(ps1\|sh)` | PASS (F-5 / Q-12 intact) |
| §5.1 five forms, §5.2 (a) ten verdict forms, adjunct block | `:73-77`, `:167-174`, `:199-217` — match round-1 anchors and QA's captures | PASS |
| Four §R2-8 gate conditions still stated | `04:76-107` (F-9, F-10, F-11 + `N+3`=7, preconditions) | PASS |
| `CHANGELOG.md` unchanged **and still truthful after the reorder** | `:42-79` re-read: describes the fix line as "conditional on where the wiring lives", makes **no** "keyed on `SOURCE_KIND`" claim, and `:76-79`'s frozen counts (32 / 14 / 12) and NFR-2 sentence all still hold | PASS (FR-20) |
| No `.ps1` | `Glob skills/harness-status/**` -> single file | PASS (NFR-5) |
| `baseline.json` not edited | `:16` = `45`, `:10` = `32` | PASS |
| `.harness/insight-index.md` not edited | exactly 30 `- ` lines, zero T-14 matches | PASS |
| Repository's own verdict | `.claude/settings.local.json` re-read: `hooks` object with 4 keys, `PreToolUse` matcher `"Bash"`, command references `.harness/scripts/guard-rm.sh` => §0 form 1, §3b row 8, `+1` — **still `installed and wired` from the machine-local file** | PASS (AC-1) |
| Round-3 anchors accurate | `:29`, `:41-45`, `:225-228`, `:287-291`, `:343-345`, `:347-354`, `:356-361` all resolve as `04` states; `wc -l 376` matches | PASS |

`04`'s `git diff --stat` arithmetic is internally consistent (round 1: 211 ins / 26 del on `SKILL.md`; round 3: 228 / 27 — net +17/-1, consistent with a 16-line net addition inside blocks already wholly new vs `HEAD`, and with 360 -> 376 lines).

### 5. Round-3 tally attribution (NFR-6) and the rounds 1-2 compression

**Attribution: adequate, better than round 2's.** Both suites are captured pre- **and** post-edit with round-labelled `=== Summary ===` / `=== Result ===` banners (`04:439-450`), which closes round-2 **NIT-2** — the round-1 `verify_all` capture is now explicitly labelled ("round 1 pre-edit … round 1 post-edit … Round 2 re-run, pasted from that run", `:135-139`). `verify_all_checks: 32` is corroborated at `baseline.json:10`; both fan-out `PASS` lines are corroborated against live bytes (`SKILL.md:111` present, retired glob absent), so 32/0/0 and 46/0 are structurally forced, not merely asserted.

**Compression spot-check — nothing load-bearing dropped.** Retained: the pre-edit porcelain baseline (`:16-53`, §R2-8 condition 4), all four gate conditions (`:76-107`), the OQ-6 tripwire with its four commands (`:146-161`), the corrected tally note and its retraction marker (`:180-189`), the round-1 rendered AC-1/AC-2 output (`:210-222`), the AC-11 delta and `--stat` (`:230-253`), the §3c drift record with its round-2 adjudication (`:255-269`), Open issues 1-5 including the withdrawal (`:275-290`), dev-map "None", the harvested insight with its `evidence:` clause (`:298-304`). Superseded rather than deleted: round 1's intermediate self-execution captures, re-executed and pasted **post-fix** at `:399-424`, with the substitution disclosed at `:193-196`. Doc is exactly **500** lines — at the `.harness/rules/70-doc-size.md` cap, so NIT-1 stays closed. One degradation and two attribution residues are filed as NIT-5.

### New findings (round 3)

#### CRITICAL / MAJOR
None.

#### MINOR

- **MINOR-6** · [DESIGN / LEDGER] `04:479-481` — *"No round-3 design drift"* is a mis-label. Both fixes **do** deviate from the design's literal text: design §3.1's `unreadable` row (`02:99`) carries no wrong-typed-`hooks` clause, and design §5.3's table (`02:410-417`) is keyed "`SOURCE_KIND` (+ condition)", orders the `SOURCE_KIND` rows first and states **no** precedence rule. **I adjudicate both deviations CORRECT and in ledger** — they close holes the design itself carried (QA's two MAJORs are inherited design defects), in the direction the design mandates (`02:91-94`: "where they do disagree the report is the stricter of the two, the NFR-1-safe direction"), and fix 1 *restores* the agreement property design §3.1 asserts at `02:82-83`. Nothing to revert. The finding is that the substance was disclosed while the label says the opposite, and that `02_SOLUTION_DESIGN.md` §3.1 and §5.3 are now the **stale surfaces**: anyone re-deriving the product from the design would re-introduce both MAJORs. **Owner: PM** — record at archive time alongside the design's other now-superseded items (§10.1 step 3, §10.2, R-1 `02:566`, and QA's P-20/P-21 probe-spec defects). Not a product change.
- **MINOR-7** · [REQ / FR-20 wording] `SKILL.md:77` and `:167` (and `CHANGELOG.md:63-64`) — the `UNKNOWN` strings say the file *"exists but could not be read or parsed"* / *"a settings file that exists but does not parse"*. After fix 1 that state also covers `{"hooks": []}`, which **does** parse as JSON; only its `hooks` value is wrong-typed. The report is now marginally inaccurate about *why* it could not certify. **Do not fix in this round**: `:77` and `:167` are §5.1/§5.2 (a) pinned strings and the `CHANGELOG` line is a frozen release claim — correcting them would move pinned bytes for a wording nit and re-open QA's byte assertions. Record-only, **Owner: PM (backlog)**, natural companion to carried MINOR-3 / QA MINOR-1, whose blast radius this fix slightly widens (more inputs now land on the `unknown` state whose `<file>` slot is singular over a list and whose "not-certified qualifier" is unpinned).

#### NIT

- **NIT-5** · [ATTRIBUTION] `04:426-428`, `:433-437`, `:445-446` — three residues, none creating a fabrication risk, all disclosed: (a) three runs per suite are claimed but **two** banners per suite are pasted; the third run's identity is asserted, not captured; (b) the two fan-out `PASS` lines sit above the pre/post banner pair without their own round label (the prose says "post-edit tail below"); (c) the §3c spec-invocation block is explicitly *"re-wrapped from the captured run to fit the cap"* — honest handling, but it is no longer the run's literal bytes; and rounds 1-2's `=== Summary ===` banners are now prose-quoted rather than pasted (`:135-139`). Every number is independently corroborated (`baseline.json:10`, live greps), so this is form, not truth. Suggested for any future touch: paste the third banner or drop the claim of a third run.

### Requirement / design coverage — delta only

Every row of the round-1 tables stands; three are upgraded, none downgraded.

| Criterion | Round-2 status | Round-3 status |
|---|---|---|
| FR-18 executable as written | PASS (MINOR-3 edges) | **PASS, strengthened** — §0 Step 0.1 now total *and* disjoint (`SKILL.md:24-45`); QA's two-reading divergence is unreachable |
| FR-14 unreadable is its own state | PASS | **PASS, widened** — `:29` now captures wrong-typed `hooks`, converging with `install-hooks.sh:83-89` |
| FR-8 reachable fix line | PASS | **PASS, now report-wide** — §7 first-match-wins with `MACHINE_STATE` first (`:343-354`), §3b pointer corrected (`:225-228`), §3c pointer corrected (`:287-291`); the `unknown and committed` state can no longer print `/harness-upgrade` |
| §5.3 six pinned strings | PASS verbatim | **PASS verbatim** — byte-identical to `02:412-417` and to QA's pre-round-3 captures; only row order moved |
| §3.1 four-state table | PASS | **PASS with adjudicated drift** (MINOR-6) — product stricter than design's literal row; design is the stale surface |
| AC-1 / AC-2 real-state proof | PASS | **PASS** — re-derived by me from `.claude/settings.local.json` directly: row 8, `+1`, four `ok` rows, source named |
| AC-9 / AC-10 / AC-11 / AC-12 | PASS | **PASS** — 32/0/0 and 46/0 pre- and post-edit, frozen counts and porcelain delta unmoved, `CHANGELOG` untouched and still truthful |

§R2-8 conditions 1-4: all four **PASS**, restated and unaltered.

### Axis status (updated, round 3)

- **Standards-conformance**: **1 new finding, worst = NIT** — NIT-5 (tally-attribution residue). NIT-2 is **closed** (round captures are now labelled); NIT-1 stays closed (`04` at exactly 500 lines). Carried and still open on this axis: **MINOR-5** (stage-7 `archive-task.sh:51` would truncate the insight's `evidence:` clause unless it enters `07_DELIVERY.md` as one physical `- `-prefixed line) — so the axis worst **including carried items is MINOR**. Verified clean: no invented rules, edit ledger honored, `baseline.json` / `insight-index.md` / `verify_all.sh` / `CHANGELOG.md` untouched, frozen counts intact, no `.ps1`, structural pin unbroken, round-3 scope held to the two routed fixes plus one disclosed same-defect extension.
- **Spec/design-fidelity**: **2 new findings, worst = MINOR** — MINOR-6 (drift labelling; design §3.1/§5.3 now the stale surfaces), MINOR-7 (`UNKNOWN` wording now covers a parsing file; must not be fixed by moving pinned strings). **QA MAJOR-1 and MAJOR-2 are both CLOSED** with independently re-derived proofs — totality/disjointness argued structurally rather than by sampling, and the installer convergence verified at `install-hooks.sh:83-89`. Carried, unchanged, all PM-owned backlog: MINOR-1 (§3c's second byte-form), MINOR-2, MINOR-3, MINOR-4, plus QA's MINOR-1…MINOR-4 and NIT-1. No CRITICAL, no MAJOR on either axis.

### Verdict

**APPROVED (0 CRITICAL, 0 MAJOR; 2 MINOR + 1 NIT new, 5 MINOR carried as backlog)**

Both QA MAJORs are fixed in the shipped bytes, in the fail-safe direction only, with no previously-classified input moved, no §5.3 pinned string moved, all six §7 branches still reachable, and no new false-green path. The §3c pointer correction at `:287-291` is **adjudicated in ledger** — same defect, same state, required by FR-8's report-wide absolute, minimally scoped and disclosed. Nothing rounds 1-2 approved has regressed, and this repository still reports **installed and wired** from `.claude/settings.local.json`. Proceed to **QA (stage 6) re-verification**, then delivery.

Hand-offs for PM, none blocking:
1. **MINOR-6** — at archive time, record that `02_SOLUTION_DESIGN.md` §3.1's state table and §5.3's fix table are superseded by the shipped text (join the existing list: §10.1 step 3, §10.2, R-1 `02:566`, QA's P-20/P-21 probe specs). `04:479-481`'s "no round-3 design drift" should read "drift adjudicated in ledger".
2. **MINOR-5 stands** — the insight must enter `07_DELIVERY.md` as **one physical `- `-prefixed line** or `archive-task.sh:51` drops its `evidence:` clause.
3. Backlog carries: MINOR-1, MINOR-2, MINOR-3, MINOR-4, **MINOR-7**, QA's MINOR-1…MINOR-4 and NIT-1, F-9's residual, and QA's **CRITICAL-OOB-1** against `.harness/scripts/guard-rm.sh` as its own stream task (correctly untouched by T-14).
4. QA's re-verification expectations are unchanged: `verify_all` **32/0/0**, `test-supervisor` **46/0** on a python3-present host (**45/0** without python3), `baseline.json:16` **out of bounds in either direction**.
