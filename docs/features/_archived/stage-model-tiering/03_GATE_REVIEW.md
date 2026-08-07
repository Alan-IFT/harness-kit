# 03 — Gate Review: stage-model-tiering (T-22)

> **Provenance note (PM Orchestrator, not the gate).** The `harness-kit:gate-reviewer`
> agent is defined with tools `Read, Glob, Grep` — it has **no `Write` tool** and is
> structurally unable to create its own stage document, even though its contract names
> `03_GATE_REVIEW.md` as its output. PM transcribed the body below **verbatim** from the
> gate's returned report. PM authored none of it and altered nothing. The same defect
> applies to `harness-kit:code-reviewer` (also `Read, Glob, Grep`); it is recorded as an
> out-of-band framework finding in `07_DELIVERY.md` and is **out of scope for T-22**.

---

## Verdict

**BLOCKED ON DESIGN** — route to `harness-kit:solution-architect` (stage 2).

**No rollback to stage 1 is requested.** U-a/U-b/U-c are confirmed immaterial to what is built; U-d's fix is design-owned (see G-3).

The DECLINE **survives** my independent third-pass re-derivation, including the compound BUILD-favourable case stage 2 never assembled. What does not survive is the **byte-form of the one artifact this task ships**: §6's 24-line record carries three claims that the design's own rationale refutes, all three erring in the decline-favourable direction, and §2 FL-2 plus §16/R6 carry two further over-claims of the same shape. The record is permanent memory frozen by D-1 (character identity is an acceptance criterion), so the developer may not correct it — only stage 2 can.

---

## Gate priority 1 — independent re-derivation

### 1.1 The corrected break-even — algebra AGREED, FL-2's universal claim REJECTED

`f = a(1−r)/[c_d + c_o·(1−S)/S]` is correct, and `∂f/∂S > 0` for `c_o > 0` (as `S↑`, `(1−S)/S↓`, denominator↓). Agreed.

**FL-2's conclusion does not follow.** As `S→1`, corrected `f → a(1−r)/c_d`; stage 1's is `a(1−r)/0.445`. The corrected bar sits at or below stage 1's **only while `c_d > 0.445`** — i.e. only while `p < 0.80`. At the gate-caught corner `p = 1` (`c_d = 0.358`, `k = 0`), corrected `f = 0.1492/0.358 = 0.417 > 0.335`. **The design states that exact value itself, at FL-11**, and then asserts the opposite universally at FL-2 ("at or below stage 1's at **every point** of the published 6.7–45% band").

FL-2 is the row that converts "stage 1's central claim is false" into "the decline is strengthened". PM's suspicion is warranted: it over-claims in exactly the author-favourable direction, and it is the guard-cmd-chain CR2-2 shape — a set-inclusion-style claim that fails precisely at the point that matters. → **G-4**.

FL-7's "non-material" ruling inherits the same defect: "`f` rises with `S` only up to stage 1's own 11.2% at `S→1`" mixes `c_d = 0.445` (stage 1's, for the 11.2%) into a corrected model that elsewhere uses `c_d = 0.58` (sup = 8.6%) or `0.358` (sup = 13.9%). Three different values of the same parameter across three rows of one contract.

### 1.2 FL-3 — VERIFIED, both halves

Routing claim verified against the live table, `agents/pm-orchestrator.md:125-130`: `Gate finds requirement gap → requirement-analyst` (125), `Gate finds design gap → solution-architect` (126), `Reviewer finds design drift → solution-architect` (128), `QA finds untested requirement → requirement-analyst` (130). A stage-1/2-originated defect does **not** route to stage 4. Stage 1's `C` measured the wrong stage set.

Percentages re-derived from the source measurement, not inherited. I spot-checked three of T-20's thirteen archived stage documents by direct read; all three matched exactly (`02_SOLUTION_DESIGN.md` = 500, `01_REQUIREMENT_ANALYSIS.md` = 324, `04_RATIONALE.md` = 485), so I accept the volume table.

- gate-caught (2+3): 1452/4051 = **35.84%** ✓
- late-caught (2+3+4+5+6): 3254/4051 = **80.32%** ✓
- stage 1's (4+5+6): 1802/4051 = **44.48%** ✓
- `A` (1+2): 1512/4051 = **37.32%** ✓
- `c_d = 0.445 ⟹ p = (0.803−0.445)/(0.803−0.358) = 0.804` ✓

### 1.3 The compound BUILD case — stage 2 never assembled it; I did

Stage 2 tested its three BUILD-direction items one at a time and found each survivable. That is the T-20 hole verbatim ("which members of the admissible class does no row instantiate?"). Compounded at the most BUILD-favourable defensible values:

| parameter | most BUILD-favourable defensible value | source |
|---|---|---|
| `a` | 0.373 (the proxy's uncorrected ceiling — FL-5 shows correction only lowers it) | `01_RATIONALE` §R2.2 |
| `1−r` | 0.8 (a genuinely cheap tier; `0.4` is unsourced) | `02_RATIONALE` §R4.3 |
| `c_d` | 0.358 (`p = 1`, every induced defect gate-caught) | design FL-3 |
| `k = c_o/c_d` | 0 | design FL-1 |
| `S` | → 1 | design FL-2 |

`f = 0.373 × 0.8 / 0.358 = **0.834** extra rollbacks/task` — **27.8%** against the n=6 mean of 3.0, **43.9%** against the n=10 mean of 1.9.

**The decline still survives**, for reasons that are rate-free: (i) no rollback-attribution instrument exists per originating stage at any resolution, and the entire recorded history is ten tasks — a 0.83/task shift needs ~30 attributed tasks to resolve even at this magnitude, which is F-2 by definition; (ii) Finding C (the addressable set is the two longest-propagation roles) and Finding D (no per-consumer reversibility) are both independent of every parameter above. I confirm stage 2's FL-11 direction: the compound corner *is* F-1 + F-2 + F-3, so the preconditions discriminate.

**But the design's published surface is mislabelled.** "The full parameter surface spans 0.6% – 13.9%" (FL-4, FL-10, §18) is the surface at *fixed* `1−r = 0.4` against a *fixed* n=6 base — two of the three self-reported BUILD adjustments held constant. Compounded, it reaches ~28% (n=6) / ~44% (n=10). Calling it "the full parameter surface" and "across the entire corrected parameter surface" is a claim the document's own §R4.2 and §R4.3 contradict. → **G-4**.

### 1.4 Finding D — VERIFIED, does not weaken

Checked against actual dispatch call sites, not against `01`:

- `agents/pm-orchestrator.md:135-136` — "The generic framework agents are **plugin-provided** — dispatch them as `harness-kit:<name>`"; `:142-143` dispatches `harness-kit:developer`; partition `dev-*` are the only bare-name dispatches (`:138-139`).
- `skills/harness-stream/SKILL.md:122` — "Dispatch `harness-kit:pm-orchestrator` via the `Task` tool".
- Grep across all `*.md`: 173 namespaced `harness-kit:<role>` dispatch/reference sites; **zero** bare-name dispatch of any framework role.
- `.claude/agents/` — glob returns nothing. Empty, as claimed.
- `AI-GUIDE.md:13,48,57` — single source, no sync, not materialized since v0.30. Verified.

A consumer's `.claude/agents/solution-architect.md` creates a bare-named agent nothing dispatches. **FL-8 holds; Finding D is the decline's strongest leg and it is sound.** One caveat I cannot discharge in-repo: upstream namespace-resolution precedence is not verifiable without network. It does not matter here, because the dispatch string is explicitly namespaced at every site.

### 1.5 The delegated-share band — bound REJECTED as stated

FL-7's ruling ("widening the band upward cannot lift the bar into detectable range") is true at the design's central parameters and **false in the compound**: at `S→1` with `1−r = 0.8` and `p = 1` the bar reaches 28–44% relative, which a ≥20–30-task attributed baseline resolves. The correct statement is that no *instrument* exists, not that no `S` puts the bar in range. Same defect family as G-4.

---

## Gate priority 2 — rulings on the four upstream defects

| id | Ruling | Reason |
|---|---|---|
| **U-a** §4.1 bolded heading vs its own body | **AGREE — cosmetic. No stage-1 rollback.** | §2.6 ("Append one … record") and AC-5 ("contains exactly one") are mutually consistent, agree with §4.1's body, and are the only text a developer builds from. No reading produces a different artifact. |
| **U-b** "eighteen records" | **AGREE the count is wrong; AGREE it is immaterial.** Independently counted: `^## ` headings at lines 12, 19, 25, 32, 39, 45, 52, 59, 66, 73, 92, 101, 112, 128, 137, 148, 162, 176, 191, 201, 224, 234, 245 = **23 records in a 255-line file**. Stage 2's count is exact. | No AC and no build step reads the count. The co-located material claim (no `stage-model-tiering` record exists) is correct — independently re-verified. Recorded as a WARN, not a rollback: unlike T-14/T-16, nothing branches on it. |
| **U-c** "~one screen" | **AGREE — false and immaterial.** 255 lines / 23 records already exceeds it; no gate reads the file's size (I confirmed: I.1 = AI-GUIDE, I.2 = rules, I.3 = agents, I.4 = insight-index, I.5 = tasks.md — none touches `rejected-decisions.md`). D-6/D-11 handle length explicitly instead. |
| **U-d** the superseded operator disposition | **DISAGREE with stage 2's handling on two counts. This is G-3, and it is the finding that most needs stage 2's attention.** See below. |

**U-d ruled in full.** Stage 2 was right that the line must be engaged rather than passed over in silence, and right that it is not a red-line-4 conflict. It is wrong about *why*, and the mitigation it chose writes a new inaccuracy into permanent memory.

1. `02_RATIONALE` §R6 justifies "not blocking" with "**the pool row itself is an ASSESS-FIRST row**". It is not. `docs/batches/default/BATCH_PLAN.md:37` reads "**Wire** the per-agent model and reasoning-effort declarations that the agent definition format already supports…" — an imperative build row, status `in-progress`. Compare the rows that genuinely are assess-first: T-10 at `:55` ("ASSESS-FIRST — decline if redundant with the existing pool/frontier/stream") and the second-wave instruction "the RA stage must honestly assess value+overlap and descope or recommend decline where appropriate rather than force-build". T-22's row carries none of that language. The ASSESS-FIRST framing was conferred **by PM at stage 0** (`PM_LOG.md:41-42`), which is an agent's framing, not the operator's. R6's second leg (PM pre-authorised both outcomes) is verified and does hold — but the first leg is false and it is doing half the work of the non-materiality ruling.
2. The record's `Origin` clause — "**supersedes** the 'still worth doing' disposition at `docs/proposals/cost-attribution-2026-08.md:81-84`, which pre-dates the role-level evidence" — mischaracterises the line it names. Read in place, `:81-84` sits inside a **"Recommended disposition"** list of *pool rows*, parallel to "T-21 — complete" and "A new candidate, not scheduled"; it corrects T-22's **priority** ("from 'primary cost lever' to 'secondary, after context reduction'") and reinforces its existing constraint. `:72` says "then **consider** tiering for roles whose defect-catching record shows they can afford it", and the operator's own stream log frames it identically (`STREAM_LOG.md:88`: "ASSESS-FIRST (T-21 downgraded this from primary to secondary lever)"). On the strongest reading the document said *run the row at secondary priority* — which is what happened — and took no position on its outcome. The record therefore claims to supersede a position the source arguably never took, while leaving the position the sources **did** take (BATCH_PLAN:37 "wire it"; BATCH_PLAN:41 "this is unused wiring, not a missing mechanism") unquoted and unrebutted anywhere in any shipped artifact.

The consequence is precisely the one PM named, inverted: a future reader follows the `Origin` pointer to `:81-84`, finds a priority note rather than a contrary disposition, and concludes the record mis-cited its own source. Meanwhile the live build row it actually overrides is never mentioned.

---

## Gate priority 3 — is the design executable and non-vacuous

### 3.1 The freeze proof — sound, with one mis-derived anchor

- **`agents/` is genuinely outside the dirty set.** Verified from the session-start `git status` snapshot: the modified-file stream runs `… README.zh-CN.md` → `docs/batches/default/BATCH_PLAN.md`, and `agents/` sorts strictly between those two paths. No `agents/` entry appears. FZ-1's basis holds — path-scoped emptiness against an unmoved `H0` **is** a content-identity statement, not a difference argument. (Not a live check; A2 at S-A remains authoritative, and §8.2's contingency already tells the developer what to do if it comes back non-empty.)
- **FZ-4's expected null is correctly labelled**, and §8.2 pre-empts the misreading. Correct call.
- **Non-vacuity is genuinely specified**, not asserted: §10.2 item 1 + R-2 require QA to copy `agents/developer.md` to a scratch dir, append a `model:` line, and show FZ-1/2/3/5 each **fire**. That satisfies the standing anti-vacuity bar (T-15 unanchored-grep, T-16 `[T-16][A]` oracle). This is the design's strongest section.
- **MINOR defect — `T0` is mis-derived (G-6).** A7 takes `T0 = stat -c %Y 01_REQUIREMENT_ANALYSIS.md`, but FZ-3's stated purpose is "the task's first write … stages 1, 2 and 3, which S-A cannot reach". `stat` returns 01's **last** write, not the task's first; the task's earliest artifact is `PM_LOG.md` (stage 0). Using the later value opens a blind window (an agent-file edit made during stage 1 before 01's final write passes FZ-3). The window is closed by FZ-1 in practice, so this is a NOTE for the developer rather than a rollback trigger — but the design should say so rather than claim retroactive coverage FZ-3 does not deliver.

### 3.2 The record byte-form — conventions correct, content defective

Conventions all verified against the real file:
- **Three fields** (`Decision`/`Why`/`Origin`) — correct; all 23 records carry exactly these.
- **Re-surface folded into `Why`** — precedent confirmed at `byte-form-subpart-classification:219-220` and `shared-insight-parse-module:254`. D-2 correct.
- **`deferred (not now)` marking** — precedent confirmed at `design-it-twice:13` and `hook-spec-raw-query:192`.
- **D-6 length** — the fenced block is design lines 89-112 = **24 lines** (1+2+17+4), and the file's longest existing record is `byte-form-subpart-classification` at 201-222 = **22**. Both figures exact.
- **D-4's archived path** — both cited precedents confirmed dangling: `docs/features/_archived/planning-decision-map/` and `docs/features/_archived/stage-contract-split/` both exist, so `:89-90` and `:219`'s pre-archive paths resolve to nothing today. The deliberate forward reference is the right call and RK-3/R-1 protect it.
- **D-5 / I.6 clearance — VERIFIED, and the self-trip risk is real.** `verify_all.sh:666-675` exempts exactly eight files (CHANGELOG, `architecture.html`, `docs/walkthrough.html`, `docs/project-overview.html`, both `verify_all` twins, both `test-verify-i6` twins) and `:676-679` exempts only `docs/features/` and `参考/`. `.harness/rejected-decisions.md` is **not** exempt, and the scan source is `git ls-files` (`:742`), which includes it. The 14 banned entries are at `:641-654`; I read all fourteen anchor sets against the §6 text and none matches. **D-5 clears.**
- **Byte-form placement complies with `70-doc-size.md` row 3/4** — written once, under a `## Byte-form specification` heading, with the I.6 test result stated in the row.

### 3.3 Line counts — independently verified

`agents/pm-orchestrator.md` = **293**, `agents/supervisor.md` = **287** (read to EOF; both confirmed exactly). I.3's mechanism verified at `verify_all.sh:447-459`: `wc -l` per file, WARN at `> 300`. Exit semantics verified at `:933` — `(( warns > 0 )) && exit 1`. **The cap is a hard gate; a WARN fails AC-7.** D-13's ±1 trailing-newline note is correct given `wc -l`. D-14's "the cap is not the reason for the decline" is a good guard against a false rationale entering the archive. I did not independently measure the other six agent files; all sit ≥131 lines below cap per §8.3 and the developer re-measures every one at S-A.

Also verified for AC-6/V-2/V-3: G.4 derives the count as `${#report[@]} + 1 = 32` (`:823-826`); `sync-self.sh` carries **no** mapping for `.harness/rejected-decisions.md` (agent mappings removed at v0.30, `:58-60`), so E.1 is unaffected and RK-7's "do not run sync-self" instruction is correct. `.harness/insight-index.md` sits at exactly **30** entries — R-3 verified; I.4 warns at `> 30`, so the harvest-plus-rotation at stage 7 stays green.

### 3.4 Stage doc sizes — PASS, and this is not a policy breach

`.harness/rules/70-doc-size.md:31` caps a per-task stage doc at **500 lines each**. `02_SOLUTION_DESIGN.md` (403) and `02_RATIONALE.md` (316) are each compliant, so the "policy without a mechanism" hazard does not bite. On proportionality: 719 lines of stage-2 output for a 24-line record looks disproportionate only if the deliverable is read as the record. It is not — the commissioned deliverable is the assessment, and the falsification in §2/§R2 is the substance. I rule this proportionate. Two observations: §2 and §R2 restate the same parameter surface three times in three different parameterisations (which is how G-4 got in), and §16's five-row findings table duplicates §R6 nearly verbatim.

### 3.5 Stages 4/5/6/7 — none empty, each verifiable

Confirmed against §11. Stage 4 has the only production edit plus the S-A/S-B captures, which genuinely cannot be produced later (stage 5 has no Bash mandate; `T0`-anchored mtimes must be read before more writes land). Stage 5 has a named, falsifiable substantive check ("does 04's freeze section **support** AC-6 or merely assert it"). Stage 6 has two real adversarial items (mutation-test the proof; attack the arithmetic) and is explicitly instructed to use independent reproducers. Stage 7 has the archive that makes D-4 correct, plus R-1/R-3. Partition assignment correctly ruled N/A — `.harness/agents/dev-*.md` glob is empty, so `harness-kit:developer` per `agents/pm-orchestrator.md:142-143`. **PASS.**

**Prediction the gate is pre-empting:** §10.2 item 7 instructs QA to reproduce the record's "0.15–0.34" from §R2's parameter table. It will not reproduce (G-1), and QA will file it. Fixing it at stage 6 costs a design rollback plus a re-run of 3→4→5→6; fixing it now costs one 2→3 round.

---

## The 8-dimension audit

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **WARN** | All eight ACs are testable and their verification steps are executable, and §3's nine out-of-scope items are unambiguous. But AC-6 verifies "the eight agent file line counts against the values recorded in §4.3", and §4.3 records **two** of eight. The design repairs this with §8.3's full table; the criterion as written is not self-executing. |
| 2 | Design completeness | **FAIL** | Every in-scope behavior of §2.1–§2.6 is covered and §6 specifies the sole artifact byte-for-byte — but that byte-form ships three statements the same design's rationale refutes (G-1, G-2, G-3), and §2 FL-2 ships a fourth (G-4). The one thing this task builds is defective. |
| 3 | Reuse correctness | **PASS** | Every reuse claim in §12 resolved on inspection: 23 three-field records, the two folded-`Why` precedents, the two `deferred` precedents, both dangling `Origin` citations, the T-15 freeze method, `agents/pm-orchestrator.md:125-130`'s routing table as normative evidence, `verify_all.sh:933`'s WARN semantics, and the `dev-*` override surface as F-3's natural shape. Zero broken citations. This is the audit's strongest dimension. |
| 4 | Risk coverage | **WARN** | RK-1…RK-8 name the real hazards, and RK-1/RK-2/RK-8 are the right top three. But RK-6's mitigation is quoted from the record sentence that G-1 shows is false, so the mitigation rests on the defect; and no risk row covers "the record's numbers trace to nothing in the design" or "the record's `Origin` mis-describes its own source". |
| 5 | Migration safety | **PASS** | Append-only (`+25 -0`, D-9), no reflow (D-10), rollback = delete the block, no parser reads the file (verified: no `I.*` check and no `sync-self` mapping touches it), no distributed surface, no version. Reversibility is a property of the change, not a promise. |
| 6 | Boundary handling | **PASS** | Dirty tree, already-dirty target file, trailing-newline artefact, ±1 `wc -l` delta with the digest as discriminator, empty-vs-non-empty A2, expected-null FZ-4, mtime-touched-without-edit, insight index at exactly its cap, the archived-path window — each has a designed contingency, and each contingency says "record it, do not stop". Exemplary. |
| 7 | Test feasibility | **PASS** | Every AC has a mechanical or read-verification, AC-7 is asserted on the exit code rather than the printed text, AC-5 is checked for exactness *and* for near-miss headings, and R-2 makes the freeze proof discriminate rather than merely pass. No criterion is unverifiable. |
| 8 | Out-of-scope clarity | **PASS** | Three independent statements of scope (`01` §3's nine items, `02` §3's "explicitly not touched" file list, `02` §15's prohibition list) that agree with each other. Over-build risk is near zero. |

---

## Findings

| id | Severity | Finding | Owner |
|---|---|---|---|
| **G-1** | **MAJOR** | The record's `- **Why:**` states "**stress-testing that model only lowered the bar**." The design's own FL-10 says the opposite in the same document — "three adjustments run in the BUILD direction" — and FL-11 gives `f = 0.417 > 0.335`, i.e. a corner where stress-testing **raised** it. My compound derivation puts it at 0.834. This sentence enters permanent memory and RK-6 explicitly relies on it as a mitigation. | `02` §6 |
| **G-2** | **MAJOR** | The record's "roughly **0.15–0.34** extra rollbacks per task (**≈3–11%** relative against a mean of 3.0, n=6)" is internally inconsistent — 0.15/3.0 = **5.0%**, not 3%, and FL-4 itself pairs 0.15 with "≈5%". Worse, the pair `0.15–0.34 / 3–11%` corresponds to **no computation anywhere in the design**: §R2.4's surface is 0.017–0.417 (0.6–13.9%), and 0.34 is stage 1's *superseded* point estimate. The record's headline number is a third, untraceable range. §10.2 item 7 sends QA to reproduce exactly this. | `02` §6 |
| **G-3** | **MAJOR** | U-d is inadequately discharged, in two places. (a) `02_RATIONALE` §R6's premise "the pool row itself is an ASSESS-FIRST row" is contradicted by `BATCH_PLAN.md:37`, an imperative "**Wire** …" row still marked `in-progress`; the assess-first framing came from PM at `PM_LOG.md:41-42`, not the operator. (b) The record's `Origin` says it "supersedes the 'still worth doing' disposition" at `cost-attribution-2026-08.md:81-84`, but that line is a **priority** correction inside a pool-row disposition list (reinforced by `:72` "then consider tiering" and `STREAM_LOG.md:88`), while the operator statements the decline actually overrides — `BATCH_PLAN.md:37` and `:41` ("already supported by the agent definition format — this is unused wiring, not a missing mechanism") — are quoted nowhere in any shipped artifact. | `02` §6 + §16/§R6 |
| **G-4** | **MAJOR** | Two over-claims in the contract, both decline-favourable, both refuted inside the same document. (a) **FL-2**: "the corrected bar sits at or below stage 1's at **every point** of the published band" holds only for `c_d > 0.445` (`p < 0.80`); FL-11 states the counterexample. (b) **FL-4/FL-10/§18**: "the **full** parameter surface spans 0.6%–13.9%" is the surface at fixed `1−r = 0.4` and a fixed n=6 base — two of the three self-reported BUILD adjustments held constant. Compounded it reaches ≈28% (n=6) / ≈44% (n=10). FL-7's non-materiality ruling inherits the same defect and additionally uses a third value of `c_d`. | `02` §2 |
| **G-5** | **MINOR** | The record says context reduction "already **banks** a double-digit cut with no capability trade-off". `02_RATIONALE` §R4.3 says the ≈16% "is an upper bound rather than a banked number" because it applies a stage-read reduction to the whole cache-read line including main-loop reads. The rationale explicitly notes the record avoids "16%" — but "banks" asserts realisation, which is the disclaimed part. Third over-claim in 24 lines, same direction. | `02` §6 |
| **G-6** | **MINOR** | FZ-3's `T0` (A7) is `stat` on `01_REQUIREMENT_ANALYSIS.md`, which returns that file's **last** write, not "the task's first write" as §8.1 states. The task's earliest artifact is `PM_LOG.md`. Retroactive coverage of stages 1–3 is actually carried by FZ-1, not FZ-3; the design should say so or re-anchor `T0` to `min(mtime)` over the task folder. | `02` §8.1 |
| **G-7** | **MINOR** | The record's F-2 threshold ("a ≈10% change per originating stage") is a single number pinned to a superseded point estimate. Given the design's own surface (and the compound), F-2 should state the resolution needed across the published surface rather than one figure. | `02` §6 |
| **G-8** | **WARN, no action** | `01` §4.1 carries two factual errors in one paragraph (U-a's self-contradicting heading; U-b's "eighteen" for 23). Independently confirmed. Neither is read by any AC or build step. Recorded so the archive carries the correction; **not** a stage-1 rollback trigger. | `01` §4.1 |
| **G-9** | **WARN, no action** | `02_RATIONALE` §R4.2 cites `STREAM_LOG.md:58-70` for "T-11a = 1, T-11b = 0, T-11c = 0, T-12 = 0". The three zeros are in that range; **T-11a's "1 design rollback" is at `:53`**. Values correct, range short by one record. Also: `:86` records T-20's delivery with **no** rollback count at all, so the n=6 window is "tasks with a recorded count", not "tasks in the window" — worth one clause if §R4.2 is being touched anyway. | `02_RATIONALE` §R4.2 |
| **G-10** | **NOTE** | AC-6 verifies eight line counts against `01` §4.3, which records two. `02` §8.3 supplies all eight, so the criterion is satisfiable — but only by reading the design, not the requirement it belongs to. No action needed; recorded so stage 5 does not file it as a defect. | `01` §5 |

---

## Human-reserved point (deferred, not asked)

**HR-1 — whether a `declined` record may be written against a still-open operator-authored build row.**

`01_RATIONALE` §R2.4 classifies this decision, by name, as "**precisely a red-line-6 shape**" — a choice assessed and found genuinely uncertain with material downside — and then self-resolves it, on the reasoning that "under Mode 2 the resolution is to escalate **or to take the conservative side**; the dispatch pre-authorized the conservative side".

`.harness/rules/25-decision-policy.md:53` is explicit: red lines **always** escalate, in all three modes, and "no rubric can override these"; `:73` gives one branch — "Red line? → escalate. Stop." There is no take-the-conservative-side branch. And `agents/pm-orchestrator.md:293` is directly on point: deferred-human mode does not mean self-resolve, it means return `BLOCKED: NEEDS-HUMAN — …`; "Do NOT silently auto-decide a point the active decision mode reserves for the human just to avoid blocking — that violates `25-decision-policy.md`; defer-and-surface instead." A PM dispatch framing is not the operator.

I am **not** blocking on this — the analysis is sound, the artifact is reversible, and PM's stage-0 framing was made in good faith. But per my dispatch I name it so PM can surface it. The narrow question, answerable by the operator in one line:

> `BLOCKED: NEEDS-HUMAN — T-22's pool row (BATCH_PLAN.md:37) is an imperative "Wire the per-agent model and reasoning-effort declarations…" row, status in-progress, and cost-attribution-2026-08.md:81-84 lists T-22 as "still worth doing" at corrected priority. The assessment recommends DECLINE and would write a permanent `declined` record that suppresses future re-proposals. Confirm the decline, or confirm that the operator's build row is withdrawn/superseded — one line either way. — What would unblock it: an operator ruling on whether the decline record may be written, and on what the record's Origin field should say about BATCH_PLAN.md:37 and cost-attribution-2026-08.md:81-84.`

---

## High-probability developer questions — pre-answered

1. **"FZ-4 shows no difference. Did I break it?"** No. Expected null (§8.2). `.harness/rejected-decisions.md` is already dirty, so its entry does not move. Record the null; AC-6 is carried by FZ-1 + FZ-2 + FZ-3. Do not manufacture a difference.
2. **"Which timestamp is `T0`?"** As specified, `stat -c %Y` on `01_REQUIREMENT_ANALYSIS.md` — its *last* write. See G-6: capture `PM_LOG.md`'s mtime too and record both; note in `04_DEVELOPMENT.md` that stage-1..3 retroactive coverage comes from FZ-1's path-scoped `git status` emptiness against an unmoved `H0`, not from FZ-3.
3. **"The `Origin` path doesn't exist yet — should I write the pre-archive path?"** **No.** D-4 + RK-3 are binding; R-1 makes stage 7 confirm it resolves after `archive-task`. Stage 5 and stage 6 are instructed not to file it. Do not "fix" it.
4. **"I edited a file under `.harness/` — do I run `sync-self`?"** **No.** Verified: `sync-self.sh` carries no mapping for `.harness/rejected-decisions.md` (its agent mappings were removed at v0.30, `:58-60`), so E.1 is unaffected. RK-7 forbids running it.
5. **"`verify_all` printed `WARN: 0` — is exit 1 possible?"** Only if `warns > 0` (`verify_all.sh:933`). Assert on `echo $?` **and** the summary line; both must agree. AC-7 fails on any WARN.
6. **"Will my stage-7 insight trip I.4?"** The index is at exactly 30 and I.4 warns at `> 30`. `archive-task` rotates the oldest out on harvest, so the count stays 30. R-3 says the rotation is expected behaviour, not a defect.
7. **"§6's numbers look wrong when I check them against §R2.4."** They are — G-1/G-2. Do **not** silently correct the byte-form; D-1 freezes it. If you reach stage 4 before stage 2's correction lands, stop and report.

---

## What I verified and found sound (positive statements)

- The falsification of stage 1 is real work, not theatre. FL-1's `c_o > 0` argument is correct under **both** readings of OQ-2, and I verified both texts exist and contradict each other (`skills/harness-stream/SKILL.md:122` vs `docs/batches/default/BATCH_PLAN.md:58`).
- FL-3 is the strongest finding in either upstream document: it is grounded in a **normative** routing table, not an inferred convention, and I verified all four rows.
- Every one of the nine citation spot-checks in `02_RATIONALE` §R1 that I re-checked (proposal `:19-30`, `:34`, `:36-40`, `:45-54`, `:56-63`, `:73-76`, `:85-87`; `BATCH_PLAN.md:42`, `:46`; `STREAM_LOG.md:72-86` → 4/3/4/1/2/4, mean exactly 3.0, range 1–4) resolved correctly. The citation layer under this task is sound.
- Finding D is verified independently against dispatch call sites and is decisive on its own, independent of every parameter in the break-even.
- §8's five-predicate freeze proof plus §10.2 item 1's mutation test is the correct answer to the T-15 dirty-tree problem, and it is the first freeze claim in this repo designed to be shown *failing* before it is trusted.
- The insight index was checked entry by entry against the design's assumptions. Three entries bear directly on this task (WARN-is-a-gate; dirty-set-difference-plus-mtime; fixture-that-passes-is-not-a-discriminating-fixture) and the design honours all three. No index entry contradicts the design.

---

## Conditions for re-gating

Stage 2 returns with G-1…G-5 corrected in `02_SOLUTION_DESIGN.md` §6 and §2, and G-6/G-7 addressed or explicitly ruled. Re-gate is narrow: I will re-read §2 FL-2/FL-4/FL-7/FL-10, §6's byte-form, and §16 U-5 + `02_RATIONALE` §R6 only. Nothing else in this design needs to move — §3, §7, §8, §10, §11, §12, §13, §14 and §15 all pass and should be left alone.

**Route: stage 2 (`harness-kit:solution-architect`). Not stage 1.** If PM wants the operator-disposition rebuttal (G-3) to live in the assessment itself rather than only in the record's `Origin` and `02` §16, that is an additional stage-1 correction PM may elect — the gate does not require it, because `01` and `02` are archived together and `02` can carry the rebuttal in full.

---

## Round 2 — re-gate

> Transcribed verbatim by PM from the gate's returned round-2 report, for the same
> no-`Write`-tool reason recorded at the top of this file.

**Scope honoured.** I re-read only §2 FL-2/FL-4/FL-7/FL-9/FL-10/FL-11, §6's byte-form, §16 U-4/U-5 + §16.1, `02_RATIONALE` §R2.4/§R2.5/§R4.2/§R4.3/§R6, and the two deltas PM named (§8's D-15, §10.2 item 7). §3, §7, §10.1, §11, §12, §13, §14, §15 were not re-reviewed; my round-1 PASS on them stands.

### Verdict

**APPROVED FOR DEVELOPMENT** — full-mode equivalent: **APPROVED WITH CONDITIONS**. Route to stage 4 (`harness-kit:developer`). Conditions C-1…C-5 below are binding; none requires a design edit.

---

### 1. Round-1 findings — disposition

| id | Round-2 state | Evidence I checked myself |
|---|---|---|
| **G-1** | **FIXED** | The new `Why` sentence — "stress-testing moved that bar in **both** directions, and the decline holds at its most BUILD-favourable corner too" — is **true**. FL-2 now conditions the "at or below stage 1's" verdict on `c_d > 0.445` and names FL-11's `0.417 > 0.335` in the row itself; FL-10 states three adjustments run toward BUILD; the compound is `f = 0.834`, which is my round-1 derivation adopted verbatim and correctly attributed. RK-6 no longer rests on the withdrawn sentence — it now opens "**Not** mitigated by claiming the corrections are one-directional — they are not." |
| **G-2** | **FIXED, and it reproduces.** | I re-derived both endpoints independently, not from the design's worked line. Low: `a(1−r) = 0.373×0.4 = 0.1492`; denominator `= 0.58(1 + 0.933/0.067) = 0.58 × 14.9254 = 8.6567`; `f = 0.017236`; `/3.0 = 0.575%` → record's **0.6%** ✓. High: `0.373×0.8 = 0.2984`; `/0.358 = 0.83352` → **0.834**; `/1.9 = 43.87%` → record's **44%** ✓; `/3.0 = 27.78%` → **27.8%** ✓. I also re-derived every cell of §R2.4(a) (0.257/0.197/0.147/0.116/0.064/0.057/0.017 and their percentages) and all four rows of §R2.4(b) — **all sixteen figures reproduce to the stated precision**. `c_d = 0.358p + 0.803(1−p)` gives `p = 0.804` at 0.445, `0.5805` at `p = 0.5`, `0.656` at `p = 0.33` ✓. §10.2 item 7's arithmetic is correct as printed and rules a mismatch CRITICAL. **The finding I predicted QA would file no longer exists.** |
| **G-3(a)** | **FIXED — and my round-1 attribution was wrong. I withdraw it.** | `STREAM_LOG.md:88` reads verbatim `2026-08-01T13:30:45Z · T-22 · dispatching pm-orchestrator · slug=stage-model-tiering · mode=full · ASSESS-FIRST (T-21 downgraded this from primary to secondary lever)` — written at the dispatch boundary, before any stage ran. It was not conferred by PM at stage 0. PM's correction is accepted without reservation. `BATCH_PLAN.md:42` also reads verbatim as quoted, including "**Do not skip to T-22.**", and `:55` is a genuine ASSESS-FIRST row exactly as §R6 characterises it. §R6 states the old premise as false and withdrawn rather than dropping it, and does not repeat my PM-attribution. |
| **G-3(b)** | **FIXED. Stage 2's correction of PM's framing is RIGHT — see §2 below.** | `BATCH_PLAN.md:37` and `:41` are quoted **verbatim** in §16.1 (I compared character-for-character against the source rows). The `cost-attribution-2026-08.md:81-84` supersession claim is gone from both documents; `Origin` now cites `:37`/`:41` and points at §16.1; R-1 additionally verifies the `### 16.1` anchor survives the archive, which is a genuine strengthening I did not ask for. |
| **G-4** | **FIXED, and no over-claim of the family survives in §2.** | FL-2 carries its condition and its counterexample in the row. FL-4 says "No figure in this document may be quoted as 'the break-even' without its cell". FL-7's `c_d`-mixing is withdrawn **by name** and replaced with the instrument argument. FL-10 states plainly that round 1's label was wrong and reports the ×3 movement as favouring BUILD. §18 restated. **U-4 was found and fixed by stage 2, not by me** — its "both corrections move the break-even down" carried the identical defect and I missed it in round 1. I checked the boundary case: "`c_o > 0` always lowers `f`" is true on the attainable domain (`S < 1` strictly, since the orchestrator is nonzero — which is FL-1's own premise), so U-4's replacement text is sound. |
| **G-5** | **FIXED** | "banks" is gone; the record makes **no** quantitative context-reduction claim at all — only "context reduction is the safer lever", which rests on the qualitative half. §R4.3 states the ≈16% is an upper bound and says why. |
| **G-6** | **FIXED, and the freeze proof is not weakened — it is strengthened.** | See §3 below. |
| **G-7** | **FIXED** | F-2 now reads "a rollback-attribution instrument resolving that surface per originating stage (sub-1% at its low end, so a ≥20-task baseline is a floor, not a sufficiency)" — a resolution requirement across the published surface, with ≥20 demoted from threshold to floor. "sub-1% at its low end" matches the verified 0.575%. |
| **G-8 / G-10** | Unchanged WARN/NOTE, upstream, no action. |
| **G-9** | **FIXED** | Re-verified against the log: `:53` T-11a "1 design rollback", `:58` T-11b 0, `:61` T-11c 0, `:68` T-12 0; `:73/:75/:77/:79/:81/:84` give 4/3/4/1/2/(3+1) → mean exactly 3.0, range 1–4; `:86` records T-20 with **no** count. Both documents now cite `:53-70`, both name the off-by-one as round 1's, and both carry the `:86` clause. n=10 mean = 19/10 = 1.9 ✓. |
| **HR-1** | **WITHDRAWN by the gate. No operator ruling is required.** | On the evidence I have now verified — `STREAM_LOG.md:88`, the dispatch brief's verbatim pre-authorisation ("recommend DECLINE and build nothing … **Record the decline in the rejected-decisions memory so it is not re-litigated**"), and operator-authored `BATCH_PLAN.md:42`'s conditionality — the decline **and the record** are the commissioned deliverable, not a unilateral override. My round-1 red-line-6 framing rested on the premise that the assess-first framing was an agent's; that premise is false. The narrow question I reserved ("may a `declined` record be written against a still-open build row") is also answered inside the design: `:37` stays `in-progress` and §16.1 states that closing it is the operator's act. PM's non-escalation was correct. |

---

### 2. Ruling on the substantive claim — stage 2 is right about `:41`

PM accepted stage 2's correction without independent verification; I have now verified it, and it holds.

`BATCH_PLAN.md:41`'s full sentence is *"The capability is already supported by the agent definition format — this is unused wiring, not a missing mechanism."* Its factual antecedent in the same note is that "all eight framework agent definitions declare name/description/tools and NO model". I checked that directly: all eight files under `/home/alan/Programs/harness-kit/agents/` declare `name:` and `tools:` and **not one declares `model:`** or any effort key. So `:41` is **true as stated**, and nothing in the decline contradicts it.

The distinction is not pedantry — it is the whole repair:

- `:37` is **imperative** ("Wire …"), status `in-progress`, and this task does not do what it says. That is an override, and §16.1's answer is the strongest available one: the row is overridden by **its own two conditions**, both of which returned against it (T-21's attribution came back at 78% cache traffic; the per-role defect-catching bar empties the addressable set).
- `:41` is **declarative** about mechanism availability. It makes no build demand, so there is nothing to override. What the decline adds are two qualifications — that plugin-wide availability is exactly what makes Finding D bite, and that for the *effort* lever the availability premise is itself unconfirmed (OQ-1). Both are accurate.

Had the record claimed to "override" `:41`, a future reader would check `:41`, find a true statement, and conclude the record misread its source — **the identical failure mode as the withdrawn `:81-84` supersession claim**. Flattening the two would have re-created G-3(b) in a new place. Stage 2 caught that and PM did not; I record it as the correct call.

---

### 3. G-6 / D-15 — the freeze proof is stronger, not weaker

D-15 does not re-anchor `T0`; it narrows FZ-3's claim and moves retroactive coverage of stages 0–2 onto FZ-1. That is the right move and it is **sound**:

- `agents/` starts **outside** the dirty set (confirmed again from the session `git status`: the modified stream runs `README.zh-CN.md` → `docs/batches/default/BATCH_PLAN.md`, and `agents/` sorts strictly between them with no entry).
- HEAD has not moved in a very long time — `cb0ed57` predates the entire T-13…T-22 wave, all of which sits uncommitted.
- Therefore `git status --porcelain -- agents/` empty at S-A is a **content-identity statement against `H0`** over an interval that strictly contains the task. That is strictly stronger than the window FZ-3 ever bounded. D-15's wording ("over the whole interval since that commit, which strictly contains the task") is exactly right, and the honest caveat — it proves net identity, not the absence of an edit-and-revert — is what FZ-2's digests and FZ-5 exist for.

**One executability gap, and it is the origin of condition C-1.** D-15's argument requires that `H0` *predate the task*. A1 captures `H0` and FZ-1 requires it unchanged S-A→S-B, but **nothing captures that `H0` is older than the task's first artifact**. The design now captures the other half (A7b's `min(mtime)` over the task folder), so joining them is one command. D-15 is otherwise fully executable: `T0` stays fixed, A7b adds one `stat`, and the developer writes the limitation into `04_DEVELOPMENT.md`.

---

### 4. Record byte-form, I.6, and D-5

- **22 lines confirmed against the real files.** Design lines 108–129: 1 heading + 2 `Decision` + 16 `Why` + 3 `Origin` = 22, exactly as D-6 states. The file's longest existing record, `byte-form-subpart-classification`, is lines **201–222 = 22**. So the new record **equals** the maximum rather than exceeding it, as claimed. `shared-insight-parse-module` still ends at line **255** (D-7 ✓).
- **Three-field convention holds.** The new record carries exactly `Decision` / `Why` / `Origin`, and the re-surface preconditions stay folded into `Why` per the two cited precedents (`:219-220`, `:254`, both re-read).
- **I.6 clearance re-verified for the round-2 text.** `.harness/rejected-decisions.md` is not in `i6_exempt_files` (`verify_all.sh:666-675`, eight entries: CHANGELOG, `architecture.html`, `docs/walkthrough.html`, `docs/project-overview.html`, both `verify_all` twins, both `test-verify-i6` twins) and not under `i6_exempt_dirs` (`:676-679`: `docs/features/`, `参考/`). I read all fourteen anchor sets at `:641-654` against the new record text: **not one anchor's first token appears in it** — no `CLAUDE.md`, no `compos*`, no `regenerat*`, no `Generated~from~.harness/rules`, no `scaffolding-only`, no `.harness/` token at all in the record body, and no Chinese. **Zero matches. D-5 clears again for round 2.**
- **D-5's paraphrase decision is correct.** Quoting the anchors inside `02_SOLUTION_DESIGN.md` would itself be safe (`docs/features/` is exempt, and stays exempt after archival to `docs/features/_archived/`). The live hazard is **travel**: this task harvests an insight at stage 7 into `.harness/insight-index.md`, which is **not** exempt and **is** scanned. Paraphrasing at the source removes that path at zero cost. The paraphrase is also accurate — I checked each of its four negative claims against the fourteen entries. D-5 remains executable because nothing in it is a developer action: V-4/V-1 re-check I.6 **mechanically** by running the gate.

---

### 5. The six BUILD-direction movements, and the two load-bearing legs

I verified each published movement and then tested whether any of them, alone or compounded, breaks the decline's remaining surface.

| # | Movement | Accurate? |
|---|---|---|
| 1 | FL-5 — the document-line proxy already flatters BUILD (`A` strictly decreasing, `C` strictly increasing in δ) | ✓ re-derived |
| 2 | FL-9/§R4.2 — n=6 is a selected sub-series; n=10 gives 1.9 and scales every relative bar by ≈1.58× | ✓ re-derived from the log |
| 3 | §R4.3 — `1−r = 0.4` is unsourced; `0.8` doubles every cell | ✓ `f` is linear in `(1−r)` |
| 4 | FL-2/U-4 — the FL-3 correction **raises** the bar at `p = 1` (`0.417 > 0.335`) | ✓ |
| 5 | FL-10/§R2.4(b) — the compound triples the published top (13.9% → 43.9%) | ✓ matches my own compound exactly |
| 6 | §R2.5 — **every** relative percentage, stage 1's 11.2% included, is a framing not a measurement | ✓ sound, and it removes an argument round 1 leaned on |

The compound correctly holds `a = 0.373` at the **uncorrected** proxy ceiling — i.e. it declines to bank movement 1 in its own favour. That is the right construction for a most-BUILD-favourable corner and it matches my round-1 table row for row.

**Leg 1 — no rollback-attribution instrument at any resolution over a ten-task history.** Holds. Every one of the six movements is a magnitude claim; none of them creates an instrument. I attacked it directly by looking for one: the only attribution anywhere in the log is *prose*, in `STREAM_LOG.md:53` ("1 design rollback — Gate caught supervisor I.3 breach…"), present in one of ten entries, absent from all six of the n=6 window, and absent entirely for T-20 (`:86`). That is not an instrument by the standard the record itself sets two lines later in F-2 ("resolving that surface **per originating stage**"). See G-12 for the one phrasing caveat.

**Leg 2 — Findings C and D carry no rate parameter.** Holds. Finding D re-verified live this round: `.claude/agents/` returns **nothing**, all eight `agents/*.md` exist as the single source, dispatch is namespaced. Finding C is an exclusion argument grounded in the operator's own bar; no parameter in §R2.4 appears in it.

**Neither leg fails. The decline stands.**

---

### 6. Doc sizes — 499 is a policy figure, not a gate risk

Stated plainly, as asked. **No `verify_all` check measures the size of a `docs/features/` stage document.** The size family is I.1 (`AI-GUIDE.md` ≤200, `:421`), I.2 (`.harness/rules/*.md` ≤200, `:433`), I.3 (`agents/*.md` ≤300, `:447`), I.4 (insight entries ≤30, `:461`), I.5 (`docs/tasks.md` ≤300, `:547`), I.7 (ignored INTERVENE reports, `:559`). I.6 is content-only. The only place `verify_all` touches `docs/features/` at all is the SUPERVISION_REPORT scan (`:566-612`) and the I.6 exemption (`:677`).

So the 500-line cap at `70-doc-size.md:31` is **policy with no mechanism**. I confirmed the actual sizes: `02_SOLUTION_DESIGN.md` = **499**, `02_RATIONALE.md` = **406**. Both compliant. **499 carries zero exit-code exposure** — it cannot produce a WARN and cannot fail AC-7/V-1. The live constraint it creates is for stage 4, not stage 2: `04_DEVELOPMENT.md` and `04_RATIONALE.md` must each stay ≤500 by policy, which is why the full S-A/S-B captures belong in the rationale sibling.

---

### 7. Findings opened this round

| id | Severity | Finding |
|---|---|---|
| **G-11** | **MINOR — WARN, no action** | D-5's justification cites "**T-13**'s delivery-stage self-trip". The real event is **T-013**, a different task from an earlier batch: `docs/features/_archived/harness-language-skill/07_DELIVERY.md:44` records "The I.6 self-trip that bit **T-013** three times", and `verify_all.sh:654`'s own banned entry is tagged `（T-013）`. This batch's T-13 is `hook-truth-spec`, whose documents contain no such event (its only I.6 mentions are `04_DEVELOPMENT.md:238` and `03_GATE_REVIEW.md:267`, neither a trip). **The substance is right and the decision is right** — only the ID is wrong, it lives in an archived stage doc and never reaches the frozen record, and it changes nothing that is built. A rollback to change three characters would be the `BATCH_PLAN.md:46` "pure process friction, zero yield" shape. Recorded so the archive carries the correction. Stage 5 must **not** escalate it. |
| **G-12** | **NOTE — the strongest remaining attack surface** | The record's "nothing here attributes a rollback to the stage that caused it, **at any resolution**" is a universal negative, and `STREAM_LOG.md:53` does attribute one rollback to its originating stage in prose. It survives, because the record's own F-2 clause supplies the calibration ("resolving that surface per originating stage"), under which one prose note in ten entries is plainly not an instrument — and because §10.2 item 7 already commissions QA to attack exactly this and rules a successful attack CRITICAL. I flag it because it is the same *shape* as G-4 and it is in frozen memory. **Not a blocker**, and QA should be pointed at `:53` specifically so the attack is real rather than notional. |
| **G-13** | **NOTE** | The record's "0.6%–44%" takes its low end against the n=6 mean and its high end against n=10 without saying so. §R2.4 discloses this explicitly ("the two extremes each taken against their own baseline"); the record does not. It errs **against** the author (44% vs 27.8% on a single n=6 base), i.e. the opposite of round 1's defect direction, and §10.2 item 7 spells out both bases. No action. |
| **G-14** | **NOTE** | §16.1 does not cite `BATCH_PLAN.md:43`, which is the operator statement most favourable to this decline: *"Prefer tuning reasoning effort (same model, less depth on mechanical work) over swapping to a smaller model, and treat any downgrade of a verification role as requiring positive evidence rather than absence of objection."* That is a near-exact operator pre-authorisation of the two-lever split the record ships. Omitted evidence that would only strengthen the case is not a defect; recorded so the archive carries the pointer. |
| **G-15** | **NOTE** | §R4.1's worked example (`δ = 1047` → `A' = 29.7%`, `c_d = 0.844`, `f = 0.141` → 4.7%) is a fourth parameterisation. I re-derived it and it is arithmetically correct. §R2.4's sole-authority claim is scoped to "`02_SOLUTION_DESIGN.md` and the §6 record" — the rationale is outside that scope, so there is no contradiction. QA must not file it against item 7. |
| **G-16** | **NOTE** | RK-9 says QA reproduces "all **four** endpoints"; §10.2 item 7 specifies **two** (plus the n=6 restatement of the high one). Item 7 is the operative instruction. |

---

### 8. Eight-dimension audit — round 2

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **WARN** | Unchanged from round 1: AC-6 compares eight line counts against `01` §4.3, which records two. §8.3 supplies all eight, so the criterion is satisfiable from the design. G-10 stands; no rollback. |
| 2 | Design completeness | **PASS** | The one artifact this task ships now carries only statements its own rationale supports: all sixteen figures on §R2.4's surface reproduce independently, the `Why`'s directional claim is true, `Origin` cites sources that say what it says they say, and §16.1 quotes them verbatim. This was the FAIL in round 1 and it is cleared. |
| 3 | Reuse correctness | **PASS** | Re-verified this round rather than inherited: 23 records / three fields / 22-line maximum at `:201-222` / last record ending at `:255`; eight `agents/*.md` with no `model:` key; `.claude/agents/` empty; `verify_all.sh:641-654` and `:666-679` read in full. Zero broken citations in the round-2 deltas except G-11's task ID. |
| 4 | Risk coverage | **PASS** | RK-6 no longer rests on a false premise and names the two rate-free legs instead. RK-9 is new and covers precisely the round-1 defect class ("a number in §6 traces to no derivation, or `Origin` mis-describes its source"), with a CRITICAL-rated mechanical check behind it. |
| 5 | Migration safety | **PASS** | Unchanged: append-only `+23 -0`, no parser, rollback is deleting the block. |
| 6 | Boundary handling | **PASS** | D-15 states a limitation honestly rather than papering over it, and both contingencies still say "record it, do not stop". The one uncovered precondition (`H0` predating the task) is closed by condition C-1, not by a design change. |
| 7 | Test feasibility | **PASS** | §10.2 item 7 is now arithmetic a QA agent can execute and fail, with a CRITICAL severity attached, and item 4 pre-scopes itself around the `Origin` quotation. R-1 verifies both the path and the `### 16.1` anchor. |
| 8 | Out-of-scope clarity | **PASS** | Unchanged; §15 additionally bars closing the operator's row, which is the correct boundary. |

---

### 9. Binding conditions for stage 4

- **C-1.** At S-A, additionally record `git log -1 --format=%cI` for `H0` and confirm it **precedes** the minimum mtime in A7b's task-folder scan. D-15's transfer of stages 0–2 coverage onto FZ-1 depends on `H0` predating the task; nothing else captures it. If `H0` does **not** predate the task, record the fact and rely on FZ-2 + FZ-5; do not stop.
- **C-2.** §6 is frozen (D-1). Do **not** correct the byte-form for G-12, G-13, or anything else. If you believe a §6 figure is wrong, **stop and report** — only stage 2 may change it.
- **C-3.** State D-15's limitation in `04_DEVELOPMENT.md` in D-15's own terms: retroactive coverage of stages 0–2 is carried by **FZ-1**, not FZ-3. Do not claim FZ-3 covers stages 1–3.
- **C-4.** Do not run `sync-self` (RK-7 — no mapping exists). And at stage 7: do **not** quote any I.6 banned-anchor text in the harvested insight bullet. `.harness/insight-index.md` is scanned and is **not** exempt; this is the exact travel path D-5's paraphrase guards.
- **C-5.** AC-7 is asserted on `echo $?` **and** the summary line; both must agree. A WARN is a failure (`verify_all.sh:932-934`).

### 10. Gate rulings that pre-empt downstream false positives

Recorded so stages 5 and 6 do not spend a round on them:

1. **`01` §2.6's "single-digit saving" component is satisfied qualitatively** by "The saving is a proportional discount on a bill that is 78% cache traffic." Stage 5 must **not** file the absence of a numeral as an AC-5/§2.6 gap — quantifying it is precisely what produced G-5, and the operator's own framing of the magnitude (`BATCH_PLAN.md:42`, "a 7% lever") lives in the archived assessment, not in permanent memory. The other three why-components are present near-verbatim and I checked each.
2. **QA item 4 will encounter "The effort lever is deferred rather than declined" in the `Why`.** That is not a D-3 violation: item 4's token is `reasoning-effort`, which appears only in the `Decision` line (paired with `deferred`) and inside the `Origin` quotation (which item 4 explicitly excludes). Do not file it.
3. **44% vs §R2.4's 43.9% is rounding, not a mismatch**, and item 7 pre-computes both. Same for `0.02`/`0.83` against `0.017`/`0.834`.
4. **D-4's archived `Origin` path is still deliberate.** It does not resolve until stage 7. Do not "fix" it; R-1 confirms it after `archive-task`, including the `### 16.1` anchor.
5. **FZ-4's null is the expected result.** Do not manufacture a difference.

### 11. Stage 4/5/6/7 work definitions after the round-2 edits

Confirmed intact, and two are slightly larger than in round 1:

- **Stage 4** — unchanged plus A7b and C-1's one command. Still the only stage that can produce the freeze evidence.
- **Stage 5** — §11 now audits against **D-1…D-15** (D-15 is new and in the range). Its substantive item ("does 04's freeze section *support* AC-6 or merely assert it") is untouched.
- **Stage 6** — §10.2 still has exactly **seven** items, and item 7 is now materially stronger: it carries executable arithmetic, a CRITICAL severity, and a second charge ("name an instrument in this repo that would detect it"). G-12 gives that charge a concrete target.
- **Stage 7** — R-1 strengthened to a two-part check; R-3's insight rotation unchanged; C-4 adds one prohibition. Delivery should state that `BATCH_PLAN.md:37`'s disposition remains the operator's act (§16.1), so the row is not silently treated as built.

**Rollback count at stage 2 remains 1.** No further design work is required before development begins.
