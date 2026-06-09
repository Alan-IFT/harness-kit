# PM Log — T-016 i18n-special-drift-guard

> Task: resolve the T-015 R-2 accepted-duplication risk. The 3 SPECIAL i18n/zh files
> (`00-core.md.tmpl` ~50-line body, `CLAUDE.md.tmpl` ~1-line-diff, `copilot-instructions.md.tmpl`
> ~1-line-diff) carry an English framework BODY duplicated from `templates/common/`. A future edit to
> the common/ body that forgets to mirror into i18n/zh silently drifts (zh projects ship stale rules).
> These files can't be deleted (T-014 `/harness-language` reads the zh policy from them — T-015 OQ-3).
> Make the duplication SAFE + maintainable.
>
> Mode: full (7-stage). Started 2026-06-09.

## Intervention check
- Before stage 1: `.harness/intervention.md` absent → no pending signal.

## Developer mode
- `.harness/agents/dev-*.md`: none → single Developer mode.

## PM-set design lean (RA frames; SA evaluates BOTH and recommends — do NOT pre-decide blindly)
- **Lean = GUARD, not eliminate.** Add a verify_all E-class check that asserts each of the 3 SPECIAL
  i18n/zh files, MINUS its policy region (the policy section in 00-core / the single policy line in
  CLAUDE/copilot), is byte-identical to the corresponding `templates/common/` file minus ITS policy region.
  Drift → hard gate FAIL with an actionable message. Reuse T-014's heading-anchor section-location logic.
- **Why GUARD over ELIMINATE (the SA must confirm or refute):**
  - Idiomatic to THIS codebase: E.1 already guards the template↔dogfood duplication via byte-identity —
    same pattern, same philosophy ("make the bad state fail the gate").
  - Low risk: a read-only check; does NOT touch init (the most load-bearing flow).
  - Eliminating the duplication requires init to COMPOSE 00-core from common-body + zh-policy (an init
    policy-injection step) + a single-source policy snippet + re-pointing /harness-language — a big change
    to init with high test-init regression surface, for the marginal benefit of removing ~50 already-guarded
    lines. Cost/benefit favors GUARD once the guard makes silent drift impossible.
- SA: evaluate the ELIMINATE option (init-injection / policy-snippet single-source) for feasibility + risk
  and RECOMMEND; if ELIMINATE is genuinely clean+low-risk, say so. Default = GUARD.

## Insights surfaced to downstream
- **T-015 (dual-purpose file)**: the SPECIAL files are read by /harness-language at run time — any change
  must keep that read working (the guard is read-only so it's safe; an eliminate path must preserve it).
- **T-015 (vacuous fixture)**: if adding a test, ensure it actually exercises drift (mutate a body line → guard FAILs).
- **L33/G.4 (count is version-worthy)**: a NEW verify_all check moves the count 32→33 → version-worthy
  (0.26.0→0.27.0); G.4 derives count from the live tally, but the "32 checks" doc claims (40-locations:25 etc.)
  must move to 33 in lockstep. Same-file claim uniqueness (L36).
- **L13/L27 (bash)**: `arr=()`, no `grep -F -i` (MSYS); reuse the existing I.6/language-policy section-scan idiom.
- **T-013 I.6 self-trip**: don't write the banned anchor literal when describing; the preserved zh policy is anchor-free.
- **L10**: re-Read after Edit. **CJK UTF-8** for any zh comparison.

## Stage transitions

### Stage 1 — Requirement Analyst — dispatched 2026-06-09
- Output: `01_REQUIREMENT_ANALYSIS.md`. Verdict: **READY** (3 OQs defaulted; mechanism-neutral framing of GUARD vs ELIMINATE).
- Central correctness point: any solution must EXCLUDE the policy region (intentionally en≠zh) or false-FAIL.
  SPECIAL boundaries confirmed: 00-core policy section en `## Output language (project-wide)` (en 9-22) vs
  zh `## 输出语言（按消费者分流）` (zh 9-31), body after `## How this project is developed` byte-identical today;
  CLAUDE/copilot differ by exactly 1 policy line. T-014 `language-policy` reads zh policy from these files (sh:77-90).

### OQ-1 resolution — PM, REVISED per user steer (2026-06-09)
**User explicitly redirected: prefer eliminating the root cause via good design over accreting guards
("不断加守卫会使项目越来越臃肿;优秀的设计才是大家都喜爱的"). → OQ-1 = ELIMINATE, not GUARD.**
(Recorded as durable principle [[feedback_design_over_guards]].) This also keeps the verify_all check count
at **32 (no bloat)** — directly the user's goal. ELIMINATE baseline (SA designs the concrete mechanism):
- **Single-source the zh policy text** into a dedicated snippet (relocate it OUT of i18n/zh 00-core/CLAUDE/copilot
  to e.g. `templates/_policy/output-language.zh.*` or similar — SA picks the cleanest location/shape).
- **Re-point T-014 `/harness-language`** to read the zh policy from the new single source (its en source can
  stay common/ inline; en path UNCHANGED — minimal blast radius).
- **init zh COMPOSES** = lay the English `common/` 00-core/CLAUDE/copilot, then INJECT the zh policy via the
  T-014 `language-policy` mechanism (reuse, don't reinvent): "init zh" = "init en + run /harness-language zh".
- **DELETE the 3 SPECIAL i18n/zh files** → the English-body DUPLICATION disappears at the root (the R-2 risk
  is GONE, not guarded). i18n/zh overlay shrinks to the 2 human-facing files.
- **NO new verify_all check** (count stays 32). Version-worthy (0.26.0→0.27.0, mechanism/template change).
- OQ-2/OQ-3 (guard mechanics) → MOOT under ELIMINATE.

**SA mandate:** FIRST verify init's actual mechanism (is it AI-orchestrated via /harness-init SKILL.md? can it
run the language-policy helper at init time? bootstrapping?). If init-composition is genuinely infeasible or
high-risk, write a BLOCKED note + route back to PM (fallback = GUARD). Otherwise design ELIMINATE concretely:
the snippet location/shape, the /harness-language source re-point, the init-injection step (SKILL.md edit),
the 3 deletions, the test-init fixture update (it must now COMPOSE not overlay; existing T-015 inverse
assertions on the composed result should still hold), and confirm `/harness-language zh` + en path both intact.
Carry: T-013 I.6 self-trip; CJK UTF-8; reuse T-014 section-locator; en render byte-unchanged.

Requirement flipped to **READY** on the ELIMINATE baseline. Advancing to design.

### Stage 2 — Solution Architect — dispatched 2026-06-09
- Output: `02_SOLUTION_DESIGN.md`. Verdict: **READY** — ELIMINATE is **FEASIBLE** (not blocked).
- Feasibility grounded: init is AI-orchestrated + already runs scripts mid-flow (SKILL §5b transforms, §6
  harness-sync); the helper ships into the project (templates/common/.harness/scripts) before needed;
  /harness-language already does this exact zh injection (test-language 39/39).
- Design: single source `i18n/zh/_policy/output-language.zh.md.tmpl` (ONE file = zh section + line; leading-`_`
  dir is OUTSIDE overlay layers → never laid into a project; helper's extract_section_to/extract_line_to find
  both with ZERO logic change — only 2 path re-points at language-policy.sh:73-81 / .ps1:70-78). No `.en.md`
  (en single-sources from common/ inline; en path byte-unchanged).
- init zh = lay English common/ → NEW step 4.4 runs `language-policy --lang zh` (inject + rm .bak); mirrored
  for /harness-adopt. Composed zh tree == old overlaid tree byte-for-byte.
- 3 deletions (00-core/CLAUDE/copilot i18n/zh); grep confirms ONLY runtime reader was /harness-language
  (re-pointed) + test-init (re-modelled); all other hits historical/doc. Overlay 5→2 files.
- **Check count STAYS 32 (anti-bloat win)** — NO verify_all check added; the would-be guard → a positive
  test-init assertion (composed zh 00-core body byte-matches common/). Version 0.26.0→0.27.0.
- Residual risk for Gate: R-1 CJK byte-drift (M-1 snippet must be COPIED from F-2/F-7 before deletion, never
  re-typed; pre-delete cmp); R-2 section-seam trailing-blank off-by-one; R-4 dogfood mirror (sync-self after edit).

### Stage 3 — Gate Reviewer — dispatched 2026-06-09
- Output: `03_GATE_REVIEW.md` (persisted by PM). Verdict: **APPROVED FOR DEVELOPMENT**. 0 BLOCKING, 4 ADVISORY.
- 3 crux claims VERIFIED: init-composition feasible (step 6 harness-sync = real shell call; helper ships in;
  /harness-language does the injection 39/39); `_policy/` snippet OUTSIDE every overlay layer (all 3 copy paths
  copy i18n/zh/common + i18n/zh/<type>, never i18n/zh/ itself); no other readers of the 3 deleted files.
- Advisories folded into Dev brief: **F-1** (the #1) test-language #9 is NOT a backstop for M-1's CJK bytes →
  produce M-1 by COPY (never re-type) + pre-delete `cmp` of helper-extraction(M-1) vs originals; **F-2** section
  span is 9..trailing-blank (~9-32) not 9-31; **F-3** §0 step-5b mischar (cosmetic); **F-4** adopt block is prose,
  mirror init step 4.4 + drop 00-core from its "translates" list.
- 0 blocking → advance to Dev without re-Gate.

### Stage 4 — Developer — dispatched 2026-06-09
- Output: `04_DEVELOPMENT.md`. ELIMINATE implemented: M-1 snippet created by COPY (`i18n/zh/_policy/
  output-language.zh.md.tmpl`); /harness-language re-pointed (zh→M-1, en unchanged) + sync-self mirror;
  init step 4.4 + adopt edit; **3 SPECIAL files git-rm'd** (overlay 5→2 + non-overlaid _policy); test-init
  re-modelled to COMPOSE + new `[zh][T-016]` body-match assertion; version 0.26.0→0.27.0; **NO check added (count 32)**.
- **Pre-delete `cmp` proof (F-1) PASSED**: regions byte-identical; composed 00-core/CLAUDE/copilot whole-file
  byte-identical to the old overlay. bash all green: sync-self In sync, test-language 39/39, test-init 237/237,
  verify_all 32/32 (count 32, v0.27.0, I.6/G.3/G.4 PASS), /harness-language zh+en work, 全程 grep clean.
- **Dev sandbox BLOCKED PowerShell** → PS side edited+static-reviewed but unexecuted; baseline PS + README badge left at 274.
- **PM ran the PS side** (main loop allows pwsh): verify_all.ps1 **32/32** (v0.27.0, I.6 PASS, count 32),
  sync-self In sync, test-language.ps1 **39/39**, test-init.ps1 **275/275** WITH `[zh][T-016] composed zh
  00-core BODY byte-matches English common/` PASSING. PS side fully confirmed.
- **PM reconciled the captured PS number**: baseline.json test_init_ps_assertions 274→275; README.md +
  README.zh-CN.md test-init badge 274→275 (3 sites; captured-fact reconciliation, gate-neutral). Stage-4→5 gate satisfied.

### Stage 5 — Code Reviewer — dispatched 2026-06-09
- Output: `05_CODE_REVIEW.md` (persisted by PM). Verdict: **APPROVED**. 0 BLOCKING, 0 MAJOR, 1 MINOR, 2 NIT.
- Two crux confirmations: (1) duplication ACTUALLY ELIMINATED not relocated (3 files gone, English body in ONE
  place = common/, M-1 holds only the zh policy delta, body-match assertion enforces composed==common → future
  edits auto-propagate + test-guarded; R-2 root cause removed); (2) M-1 byte-correct (CJK clean, anchor-free,
  cmp-proven). All ACs + design fidelity OK; check count stays 32.
- PM decision: FIX the 1 MINOR before QA (SKILL.md "static stubs" prose now slightly inaccurate re step 4.4's
  policy-line injection — the init runbook should be accurate; maintainability). Skip 2 NITs (cosmetic).

### Stage 5b — Developer polish (CR MINOR SKILL.md prose) — dispatched 2026-06-09
- Clarified the "static stubs" Note: body is static, but step 4.4 rewrites ONLY the top policy line for zh.
  Only SKILL.md changed; `全程` grep = 0. bash verify_all 32/32 (C.2/I.6 PASS). Dev sandbox blocked pwsh.
- **PM ran PS twin: verify_all.ps1 32/32** (C.2/I.6/G.3 PASS, v0.27.0). Both shells green.

### Stage 6 — QA Tester — dispatched 2026-06-09
(awaiting output)
