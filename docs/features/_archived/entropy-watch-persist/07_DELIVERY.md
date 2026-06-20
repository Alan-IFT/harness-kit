# Delivery Summary — entropy-watch-persist / T-11c

- **Task:** T-11c / `entropy-watch-persist` — findings persistence so the anti-entropy watch doesn't nag: OPEN re-surfaces, FIXED drops, user-DECLINED goes to `.harness/rejected-decisions.md` and is never re-litigated.
- **Mode:** full (7 stages) · **Depends on:** T-11a + T-11b (DELIVERED) · **Final slice (3/3) of the anti-entropy watch.**
- **Stages traversed:** 1 RA → 2 SA → 3 Gate → 4 Dev → 5 CR → 6 QA → 7 Delivery.
- **Rollbacks:** 0.
- **Final verify_all result:** **PASS 32/0/0 (Bash)** (G.3 0.43.0, G.4 [0.43.0], I.6 clean incl the new rejected-decisions records); test-supervisor.sh 45. verify_all.ps1 / test-supervisor.ps1 operator-pending (PS denied).
- **Version:** 0.42.0 → **0.43.0** (minor). Counts 17 skills / 8 agents / 32 checks unchanged.
- **Baseline changes:** none.

## Scope outcome — lean by design
The RA/Gate confirmed the supervisor scan RE-DERIVES findings every sweep (pure function of current structure), so OPEN re-surfaces and FIXED stops surfacing with **NO store**. The standalone findings-store was **DECLINED as overkill** (it would re-encode a re-derived fact + add a drift surface) — recorded as its own `## entropy-findings-store` decline record. The ONLY genuinely-new wiring is the DECLINE filter.

## Files changed (9 — 3 behavioral + 5 stamps + 1 memory record)
- `skills/harness-deflate/references/entropy-scan.md` — new `## Decline filter` (single source): before writing the artifact, read `.harness/rejected-decisions.md` and EXCLUDE any finding whose normalized `Where (file/module)` handle EXACTLY equals a record's `## <handle>` (NOT substring/prefix → no sibling over-suppression; NOT the per-run EP-NNN); fail-open (missing/unreadable → all surface); dropped findings don't count toward FINDINGS-PRESENT (all dropped → CLEAN).
- `agents/supervisor.md` (285 ≤300) — one clause naming the decline filter + pointer (no restatement); read-set widens by one whitelisted file, read-only.
- `skills/harness-deflate/SKILL.md` — step-4 real DECLINE action (3-way: deflate / decline / none); appends a T-09-format record, de-dups by handle, creates-from-seed; `allowed-tools` unchanged (no Edit/Write — the append is the main-agent decide-point habit, the skill states the CONTRACT); no `/harness-goal` dispatch in the decline branch.
- `.harness/rejected-decisions.md` — `## entropy-findings-store` decline record (single).
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.zh-CN.md` (0.43.0); `CHANGELOG.md` ([0.43.0]).

## Quality trail
- Gate: APPROVED — scope-down + exact-match key + fail-open + I.6 (rejected-decisions scanned) all verified; 3 non-blocking notes (DRY review-enforced; filter matches declined+deferred; append by main-agent not skill).
- CR: APPROVED — both axes (Standards/Spec) PASS; 0 CRIT/MAJOR/MINOR, 2 NIT; DRY single-source grep-verified.
- QA: APPROVED FOR DELIVERY — 0 defects; exact-match worked example (`src/a` doesn't suppress `src/ab`), fail-open, no store (Glob empty), I.6 clean, no count flip all confirmed.

## Outstanding / Next
- **The anti-entropy watch feature (T-11a/b/c) is COMPLETE.** Machine reminds (cadenced, both `/harness` and `/harness-stream`) → user authorizes → machine executes; findings don't nag (declined ones filtered).
- Operator-pending (PS deny): verify_all.ps1 (32/0/0), test-supervisor.ps1 (49) on Windows.

## Insight

- 2026-06-20 · Before adding a PERSISTENCE STORE for a producer's outputs, check whether the producer RE-DERIVES them deterministically each run (a pure function of current state). If it does, "open" and "fixed/resolved" states need NO store — open items re-derive, resolved items simply stop being produced; only the user-overlaid EXCLUSION state ("we decided not to act on this") is genuinely new information that must persist, and that can REUSE an existing decision-memory (here `.harness/rejected-decisions.md`, matched by a stable concept key, NOT the producer's per-run sequential id). Net: a "findings persistence" ask collapsed from a new store + open/fixed/declined lifecycle to a single decline-filter over the existing memory. · evidence: T-11c, references/entropy-scan.md `## Decline filter` + the declined `## entropy-findings-store` record
