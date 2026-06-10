# 03 — Gate Review · T-018 decision-mode-skill

> Stage 3 (Gate Reviewer). Mode: **full**. Independent verification — I read the live tree, not just the
> upstream docs. Upstream verdicts: RA `READY`, SA `READY for Gate Review`.

## Audit checklist (8 dimensions)

| # | Dimension | Verdict | One-line reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | 14 ACs, all operator-verifiable; the generic-vs-personal boundary (AC-4) is concrete with a banned-phrase list; OQ defaults are safe + in-scope. |
| 2 | Design completeness | **FAIL** | The §7 fan-out ledger — which IS the Developer's authoritative checklist for the #1 recurring failure surface — **omits `docs/getting-started.md`**, a live "fourteen skills" claim WITH its own skill enumeration list. See F-1. |
| 3 | Reuse correctness | **PASS** | Reuse audit accurate: `/harness-language` pattern reused, its helper correctly NOT reused (§3 rationale sound — no section-slicing here); T-014 §11 ledger shape mirrored. Verified `skills/harness-language/SKILL.md` exists and matches the cited flow. |
| 4 | Risk coverage | **PASS** | R1 (generic-leak) correctly named #1; R2 (count fan-out), R3 (ps/sh F.1), R4 (baseline fabrication), R5 (I.6), R6 (custom clobber), R7 (doc-size) are the real risks. The F-1 gap is itself an instance of R2 the ledger under-delivered on — see F-1. |
| 5 | Migration safety | **PASS** | Additive/backwards-compatible; dogfood Active mode stays 2 (no behavior change); green-tree `git reset` rollback; no data/API/schema. |
| 6 | Boundary handling | **PASS** | BC-1…BC-7 designed: empty-Custom capture, non-empty leave (OQ-3), idempotent no-op, dirty-tree refuse, hand-mangled Active-mode-line conflict (§3 step 2 recognizer), missing-policy halt (OQ-4). |
| 7 | Test feasibility | **PASS** | Each AC is checkable; operator-run gates (verify_all/test-init/baseline) explicitly marked so no agent fabricates a tally (insight L23 honored). G.3/G.4/C.1/G.1/G.2/F.1 mapping is correct. |
| 8 | Out-of-scope clarity | **PASS** | §11 boundaries explicit: no helper, no new check, no zh copy (OQ-2), no install-array gap fix (OQ-1), no bootstrap (OQ-4), no per-agent integration. Over-build risk low. |

## Findings

### F-1 — Design FAIL: §7 fan-out ledger omits `docs/getting-started.md` (BLOCKED ON DESIGN)

**Responsible document:** `02_SOLUTION_DESIGN.md` §7 (the fan-out ledger) + §2 Family D.

**Evidence (live-tree grep, `14 skills|fourteen|十四|All 14`):**
- `docs/getting-started.md:36` — "Either path makes **fourteen** skills available in Claude Code:" — followed
  by a THREE-group skill enumeration (Pipeline `:38-45`, Setup `:47-52`, Operations `:53+`). The new skill
  needs (a) `fourteen` → `fifteen`, AND (b) a `harness-decision-mode` bullet added to the **Operations**
  group. **This file appears NOWHERE in the §7 ledger (rows 1-20) nor in §2 Family D.**
- This is not hypothetical: the T-014 precedent the SA explicitly cites as its ledger template
  (`docs/features/_archived/harness-language-skill/02_SOLUTION_DESIGN.md:492`) DID fan out
  `docs/getting-started.md:36` + the Setup group. T-018's ledger dropped it.

**Why this blocks (not a WARN):** §7 is described in the design itself as "the Developer's checklist" and "the
project's #1 recurring failure surface (insight L24/L5)". A surface omitted from the ledger is the exact
mechanism by which T-008 (F-1/F-2/F-5) and T-006 (M-1) shipped stale counts. The Developer implements FROM the
ledger; a gap here = a guaranteed stale `fourteen` in `getting-started.md` post-ship. The Gate's job is to
catch ledger incompleteness BEFORE development, since the count claims are not all gate-enforced (the SA's own
§7 NOTE correctly says #12/#16/#17 are MANUAL/ungated — and `getting-started.md` is in that same ungated class,
making the omission un-catchable by verify_all).

**Route:** back to **solution-architect** to add `docs/getting-started.md` to the §7 ledger (count flip
`:36` + new Operations-group bullet), and while there, re-confirm the ledger against a fresh
`fourteen`/`十四`/`14 skills` grep so no other ungated surface is missing.

### F-2 — Design WARN: §7 row 16 under-specifies `manual-e2e-test.md`'s `fourteen` sites (advisory)

**Responsible document:** `02_SOLUTION_DESIGN.md` §7 row 16.

Row 16 lists `docs/manual-e2e-test.md` `:34`,`:49` ("14 skills") "+ enumerations", but the live tree also has
**`:7`** ("does Claude Code actually load the **fourteen** skills?") and **`:60`** ("the **fourteen**
`/harness-*` commands appear"). "+ enumerations" is vague for the project's #1 failure surface. Advisory
(not blocking) because the file IS in the ledger and the SA's §7 NOTE already instructs CR/QA to grep every
`14`/`fourteen`/`十四` token — but the SA should make row 16 explicit (`:7`, `:34`, `:49`, `:60` + the
enumeration lists) so the Developer flips all four, not just two. Bundle this fix with F-1.

### F-3 — INFO (no action): G.4 / check-count correctly excluded

Confirmed the SA's call: G.4 gates the verify_all CHECK count (32, derived from plugin.json + live tally), NOT
the skill count. T-018 adds NO check → check count stays 32 → G.4 stays green on the version bump alone. The
zh `（32 项检查）` and en `32 checks` / `32/32` tokens are CHECK counts and must NOT be touched during the
skill-count flip (insight L26 same-file token discrimination). The SA stated this correctly (§7 NOTE + R2);
recording it so the Developer does not over-flip.

## High-probability developer questions (pre-answered)

1. **"Do I add `harness-decision-mode` to `.claude/skills/`?"** → NO. `.claude/skills/` and `.harness/skills/`
   are EMPTY in dogfood (SA OQ-5, verified); plugin skills live only under top-level `skills/`. No sync.
2. **"What's the exact baseline.json test-init number after adding 2 presence assertions?"** → Do NOT guess.
   Write the assertions; mark the number `[operator-run]`; the OPERATOR runs test-init and reconciles
   baseline.json + the README test-init badge (insight L23). Same for whether the README `275/275` test-init
   badge moves.
3. **"Where exactly does the new skill bullet go in README — Setup or Operations?"** → SA §7 row 6 says
   **Operations skills** (`README.md:29-33`). getting-started.md (per F-1 fix) → its **Operations** group.
   Match each README/doc's existing grouping.
4. **"Do I touch the `32 checks` / `（32 项检查）` / `32/32` tokens?"** → NO (F-3). Only `14`/`fourteen`/`十四`
   SKILL tokens flip to `15`/`fifteen`/`十五`.
5. **"Is the template rubric a copy of the dogfood one?"** → NO. Author it FRESH from §4.2's generic skeleton;
   the dogfood personal-prefs (banned list, AC-4) must NOT appear. This is R1, the #1 correctness risk.

## Verdict

**BLOCKED ON DESIGN** (full mode).

One blocking finding (F-1: the fan-out ledger — the Developer's authoritative checklist — omits a live,
ungated skill-count surface `docs/getting-started.md`). F-2 (manual-e2e-test under-specification) is advisory
but should be fixed in the same SA pass. Everything else PASSes; the design is otherwise complete, well-reasoned,
and implementable. Route back to **solution-architect** to amend §2/§7 only; expect a fast turnaround (the fix
is two ledger rows + one row clarification, no rethink).

---

## Re-review (round 2, post-Amendment 1) — 2026-06-10

Read `02_SOLUTION_DESIGN.md` "Amendment 1". **I did not trust the SA's A1.3 re-grep claim** — I re-ran an
independent live-tree `fourteen|14 skills|14 个 skill|14 个 AI|All 14|14个` grep, **excluding `docs/features/**`**
(archived + this task's own docs are neither shipped nor gated), per insight L19 (rely on an actual matcher run,
not hand-reasoning).

**Independent grep result — every live skill-count surface, cross-checked against the amended ledger:**

| Surface (live grep hit) | Token | Ledger row | Status |
|---|---|---|---|
| `AI-GUIDE.md:7` | `14 skills` | §7 row 12 | ✓ covered |
| `.harness/rules/40-locations.md:30` | `All 14 skills` | §7 row 17 | ✓ covered |
| `.harness/scripts/verify_all.sh:59,:333,:349` | `All 14 skills` / `references all 14 skills` | §7 row 14 | ✓ covered |
| `.harness/scripts/verify_all.ps1:68,:300,:326` | `All 14 skills` / `mentions all 14 skills` | §7 row 15 | ✓ covered |
| `README.md:7,:13` | `14 skills` / `fourteen` | §7 row 5 | ✓ covered |
| `README.zh-CN.md:7,:13` | `14 个 skills` / `14 个 AI skill` | §7 row 7 | ✓ covered |
| `docs/getting-started.md:36` | `fourteen skills` | **A1.1 rows 21-22** | ✓ NOW covered (F-1 closed) |
| `docs/manual-e2e-test.md:7,:34,:49,:60` | `fourteen`/`14 skills` (×4) | **A1.2 row 16 clarified** | ✓ NOW explicit (F-2 closed) |

Zero remaining uncovered surfaces. Confirmed NO premature `fifteen`/`15 skills` claim exists anywhere (the flip
hasn't started). Confirmed `README.zh-CN.md:257` (`14 个文件`, a v0.15.1 CHANGELOG "14 FILES" prose ref) does
NOT match the skill-token grep — correctly out of scope (L26 token-discrimination upheld). The `32`/
`（32 项检查）`/`32/32` CHECK-count tokens remain untouched (F-3 reaffirmed).

**Re-review verdict: APPROVED.** F-1 and F-2 are closed; the §7 ledger is now exhaustive and independently
verified. All 8 dimensions PASS. Development may proceed. The Developer implements strictly from the §2/§7/§4
ledger + the amended rows; the operator-run gates (verify_all, test-init/baseline) remain the final arbiter.
