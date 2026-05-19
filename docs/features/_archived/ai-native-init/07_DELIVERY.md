# 07 — Delivery Summary · ai-native-init (T-002)

- **Task**: ai-native-init — AI-customized `50-<project-slug>.md` rule fragment + optional partition agents, opt-in, added to both `/harness-init` and `/harness-adopt`.
- **Mode**: full (7 stages)
- **Target version**: v0.16.0 (roadmap line previously "0.16+ planned" in README.md:256 — now flipped to done)
- **Date**: 2026-05-19

## Stages traversed (with rollbacks)

| # | Stage | Outcome | Doc |
|---|---|---|---|
| 1 | Requirement Analyst | READY (11 FR, 12 AC, 8 NFR, 8 risks; 6 open questions analyst-decided) | `01_REQUIREMENT_ANALYSIS.md` |
| 2 | Solution Architect | READY FOR GATE REVIEW (3 architect decisions added: inline prompt, four-invariant detector, env-var mock fixture) | `02_SOLUTION_DESIGN.md` |
| 3 | Gate Reviewer | APPROVED FOR DEVELOPMENT (8-dim audit: 6 PASS / 2 WARN / 0 FAIL; 4 binding Dev-time findings A/D/F/G + 2 cosmetic) | `03_GATE_REVIEW.md` |
| 4 | Developer (round 0) | READY FOR REVIEW (19 files; 29/29 verify_all; 222 test-init PS) | `04_DEVELOPMENT.md` |
| 5 | Code Reviewer (round 1) | **CHANGES REQUIRED** — 3 MAJOR: M-1 CHANGELOG count drift, M-2 AC-10 not byte-level, M-3 opt-in/opt-out share temp dir | `05_CODE_REVIEW.md` |
| 4' | Developer (round 1 rollback) | READY FOR REVIEW round 2 (M-1/M-2/M-3 all fixed; 225 test-init PS / 189 Bash-no-python3) | `04_DEVELOPMENT.md` Rollback round 1 |
| 5' | Code Reviewer (round 2) | **APPROVED** — all 3 MAJORs resolved, no regressions | `05_CODE_REVIEW.md` Round 2 |
| 6 | QA Tester (round 1) | APPROVED FOR DELIVERY with 2 MAJOR follow-ups — adversarial sweep found BUG-1 (reserved-name shell asymmetry) + BUG-2 (placeholder regex misses whitespace-padded `{{ NAME }}`) | `06_TEST_REPORT.md` |
| 4'' | Developer (round 2 rollback — PM override) | READY FOR REVIEW round 3 (BUG-2 fixed; BUG-1 deferred to v0.16.1 with rationale) | `04_DEVELOPMENT.md` Rollback round 2 |
| 6' | QA Tester (round 2) | **APPROVED FOR DELIVERY** — BUG-2 closed; 227 test-init PS / 191 Bash-no-python3 | `06_TEST_REPORT.md` Round 2 |
| 7 | PM (this doc) | Delivered v0.16.0 | `07_DELIVERY.md` |

**Total rollbacks**: 2 (round 1 from Code Review on M-1/M-2/M-3; round 2 from PM override on QA's BUG-2). No stage rolled back 3× — pipeline never tripped the "stop and ask" gate.

## Final verify_all result

```
=== Summary ===
  PASS: 29
  WARN: 0
  FAIL: 0
```

Verified by PM directly post-final-rollback. New check D.3 ("AI-generated 50-*.md sanity, per-section sources") added.

## Final test-init result

| Shell | Pass count | Notes |
|---|---|---|
| `test-init.ps1` | 227 / 227 | +50 from v0.15.1 (177 → 227): +45 AI-native ×3 project types, +3 AC-10 byte-compare, +2 BUG-2 regression. |
| `test-init.sh` (Windows, python3 stub) | 191 / 191 | Python-gated AI-native sub-block correctly SKIPped (parallel to existing `init_have_python` pattern); on real-python3 host, full 227 surface runs. |

## Baseline changes

`scripts/baseline.json` post-delivery:
- `verify_all_checks`: 28 → **29**
- `test_init_ps_assertions`: 177 → **227**
- `test_init_bash_no_python3_assertions`: ~155 (estimated v0.15.1) → **191**
- `last_verify`: 2026-05-19

## Files changed (22 in working tree at delivery)

```
.claude-plugin/marketplace.json                       (version 0.15.1 → 0.16.0)
.claude-plugin/plugin.json                            (version 0.15.1 → 0.16.0)
.harness/rules/40-locations.md                        (lookup-table refresh)
AI-GUIDE.md                                           (28/v0.15.1 → 29/v0.16.0 at lines 35 + 67)
CHANGELOG.md                                          (v0.16.0 entry + Known-limitations BUG-1 deferral)
MIGRATION.md                                          (version reference refresh)
README.md / README.zh-CN.md                           (roadmap row flipped, badges bumped)
architecture.html                                     (banner counts updated)
docs/dev-map.md                                       (assertion counts + scripts/ tree)
docs/manual-e2e-test.md                               (assertion count header)
docs/tasks.md                                         (T-002 entry → done in archive pass)
docs/walkthrough.html                                 (sample output count refresh)
scripts/baseline.json                                 (counts bumped, see above)
scripts/test-init.ps1   +205 lines                    (AI-native block + AC-10 byte-compare + BUG-2 regression)
scripts/test-init.sh    +178 lines                    (symmetric Bash; python3-gated AI-native sub-block)
scripts/verify_all.ps1   +87 lines                    (new D.3 per-section check; D.2 regex broadened + -cnotin)
scripts/verify_all.sh   +104 lines                    (symmetric D.3 + D.2 regex broadening)
skills/harness-adopt/SKILL.md   +49 lines             (Q6 + step 4b "AI rule synthesis (opt-in)")
skills/harness-init/SKILL.md   +144 lines             (Q6 + step 5b "AI customization (opt-in)" + slug sanitizer + env-var mock)
skills/harness-init/templates/common/AI-GUIDE.md.tmpl (conditional 50-<type/slug> marker at line 23)
skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl (parallel marker)
```

Two **new** files (untracked, will be added):
```
skills/harness-init/templates/common/.harness/rules/_ai-native-prompt.md      (178 lines — canonical AI prompt as shipped reference)
skills/harness-init/templates/common/scripts/ai-native-mock.json              (mock fixture; doubles as user-facing dry-run aid)
```

Net: **24 paths** delta from v0.15.1 → v0.16.0 (22 modified + 2 added).

## What was delivered (user-facing)

1. **`/harness-init` gains Q6**: "AI customization (reads your stack description + top-level filenames to draft a tailored rule file; ~10s; you can edit before commit. Default: No, keep static stub)."
2. **`/harness-adopt` gains parallel Q6**.
3. **On opt-in**, the skill enumerates top-level files (cap: 100 entries), reads 7 named manifests (cap: 50 KB each), drafts `.harness/rules/50-<project-slug>.md` with 6 mandated sections and `<!-- source: ... -->` provenance comments, deletes the static stub, updates the AI-GUIDE index line (and the zh parallel).
4. **Optional partition agents**: AI proposes `dev-<name>.md` for natural module boundaries; each draft requires explicit Accept/Rename/Reject. Reserved pipeline-agent names (the 7 specialists) are filtered before the user sees them.
5. **On opt-out**, behavior is **byte-identical to v0.15.1** (asserted in test-init via `[System.IO.File]::ReadAllBytes` per-byte loop / `cmp -s`).
6. **Mock fixture** (`HARNESS_AI_NATIVE_MOCK` env var) lets users and CI dry-run the AI-native path with a deterministic canned response — no live LLM call.
7. **Safety nets**: verify_all D.3 (per-section source-annotation check + 6 required headings + no `{{...}}` literals); broadened D.2 regex now catches whitespace-padded and lowercase placeholder leaks.

## Known limitations / deferred to v0.16.1

- **BUG-1 (deferred)**: Reserved-name filter asymmetric between PS `-icontains` (case-insensitive) and Bash Python `not in` (case-sensitive). A user-project Bash init with an AI that proposed `Developer` (capitalized) would NOT be filtered by the Bash twin, only by the PS twin. Runtime path goes through the orchestrator AI (which honors the reserved set in any case), so the user-facing impact is limited to defense-in-depth. Slated for a one-line `.lower()` fix in v0.16.1.
- **AC-2 coverage (defense-in-depth)**: the 100-entry top-level enumeration cap and the named-manifest-only read scope are documented in `SKILL.md` prose and the `_ai-native-prompt.md` shipped reference, but not asserted in `test-init.{ps1,sh}` because the mock fixture short-circuits the input-gathering step. Coverage gap accepted; would need a SKILL-level integration test (out of scope for v0.16.0).

## Outstanding risks

None ship-blocking. The two known limitations above are tracked in CHANGELOG "Known limitations" and will roll into a v0.16.1 hardening release that ALSO picks up QA's 5 MINOR coverage gaps (R-1 documentation tightening, R-3 Bash arithmetic-parse hardening, R-4 D.3 positive/negative fixtures, N-1 awk-regex comment, N-2 SKILL Q6 split into sub-bullets).

## Next steps for user

- Pull `main`, run `scripts/verify_all` to confirm green (should be 29/29 on any host).
- Try AI-native init on a fresh greenfield: `/harness-init` → answer Q6=Yes. Inspect the generated `.harness/rules/50-<project-slug>.md` and verify the source-citation comments make sense for your stack.
- To dry-run without invoking a real LLM: `$env:HARNESS_AI_NATIVE_MOCK = "scripts/ai-native-mock.json"` (after init) and re-run the customization step.
- T-003 (supervisor agent observing pipeline progress) is the next remaining roadmap item; T-002's PM has the context loaded to run it on request.

## Insight

(Only non-obvious project truths that beat a reasonable prior — per `.harness/rules/05-insight-index.md`. `scripts/archive-task` will harvest these into `.harness/insight-index.md`.)

- 2026-05-19 · PowerShell `-notin` (default operator) is case-INSENSITIVE; the symmetric case-sensitive variant is `-cnotin`. A D.2-style whitelist check that uses `-notin` will silently let `{{stack}}` through if `{{STACK}}` is in the whitelist. Same bug class as v0.15.0's `-contains` rollback. Always use `-cnotin` / `-ccontains` for case-sensitive placeholder / flag whitelists. · evidence: T-002 round-2 rollback, scripts/verify_all.ps1:101 (post-fix)
- 2026-05-19 · A round-1 doc-resync sweep that updates README/AI-GUIDE/dev-map/walkthrough/architecture but misses CHANGELOG.md (the very file that DESCRIBES the sweep) is a recurring failure mode — the writer optimizes for "consumer-facing surfaces" and forgets that CHANGELOG itself states counts. Add CHANGELOG to the explicit fan-out checklist of any insight-index-line-14 sweep. · evidence: T-002 round-1 review M-1, CHANGELOG.md:43,45,47,55 (post-fix)
- 2026-05-19 · When two test cases share a temp dir, "bidirectional opt-in/opt-out" assertions silently degrade into "sequence of opt-in then opt-out" rather than two independent end states. Detection: search test code for `[opt-out]` and `[opt-in]` assertions sharing a `$tmp` / `mktemp -d` allocation. Fix: separate `mktemp -d -t harness-test-optout-XXXXXX` allocations with isolated lifecycle. · evidence: T-002 round-1 review M-3, scripts/test-init.{ps1,sh} (post-fix)

---

**Verdict**: v0.16.0 SHIP-READY. PM advancing to archive-task and commit.
