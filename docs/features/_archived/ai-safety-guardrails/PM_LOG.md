# PM_LOG — ai-safety-guardrails

## 2026-05-16T... · PM Orchestrator · task opened

- Task slug: `ai-safety-guardrails`
- Mode: `full` (7-stage pipeline)
- User invocation: `/harness-kit:harness` with autonomous-decision mandate (`你来决策就可以了`)
- Intervention check: `.harness/intervention.md` absent. OK.
- Insight-index scan: 5 relevant entries — most pertinent:
  - "Edit tool occasionally reports SUCCESS without applying the change — re-Read or Grep to verify." → developer must verify edits.
  - "Any new `{{...}}` placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails." → developer must update D.2 if introducing placeholders.
  - "`sync-self` only syncs `.harness/agents/` + 4 specific scripts (harness-sync, install-hooks, archive-task) — NOT `.harness/rules/`." → if developer adds new sync targets, they need explicit handling.
  - "Releases shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values." → if this task bumps version, README/AI-GUIDE/manual counts must be updated.
  - "When asserting set-membership in templates, write the inverse check too." → if new rule/hook file is added, both directions of indexing need verifying.
- Dispatching stage 1: Requirement Analyst.

## 2026-05-16 · Stage 1 complete

- Requirement Analyst returned `READY` (no open questions; 12 decisions recorded in §8 per user mandate).
- Scope locked: D1 docs + D2 callout + D3 guard-rm hook. 19 in-scope items, 13 acceptance criteria, all verifiable.
- Stage advance: requirements → design. Dispatching Solution Architect.

## 2026-05-16 · Stage 2 complete

- Solution Architect returned `READY FOR GATE REVIEW`.
- 34 files enumerated. Partition = `developer` (single mode). Version bump `v0.15.0`.
- New verify_all check ID = `F.2` (reviving the vacated v0.14.x slot, 27 checks total).
- New placeholder `{{GUARD_COMMAND}}` (must be added to D.2 whitelist in BOTH ps1 + sh).
- Algorithm: regex tokenization, walk-up `.git/` for repo root, leaf-only symlinks, override = `HARNESS_ALLOW_OUTSIDE_RM=1`, parse failure → BLOCK.
- Stage advance: design → gate-review.

## 2026-05-16 · Stage 3 complete

- Gate Reviewer returned **APPROVED WITH CONDITIONS** (5 conditions C-1..C-5).
- 8-dimension audit: 7 PASS + 1 WARN (test feasibility — covered by C-1).
- All design citations verified.
- Conditions forwarded to Developer in dispatch prompt:
  - C-1: extend `scripts/test-init.{ps1,sh}` with PreToolUse + guard-rm assertions.
  - C-2: fix `AI-GUIDE.md:58` count drift while editing (write 4 pairs + 4 names).
  - C-3: bump "(5 allowed)" → "(7 allowed)" in `.harness/rules/40-locations.md:29`.
  - C-4: re-Read/Grep after every Edit on multi-surface files.
  - C-5 (optional): R13 risk row.
- Stage advance: gate-review → development.

## 2026-05-17 · Stage 4 complete

- Developer reported all 5 gate conditions satisfied + full design implemented.
- PM independent re-verification:
  - `pwsh -File scripts/verify_all.ps1` → **PASS 27, WARN 0, FAIL 0**.
  - `bash scripts/verify_all.sh` → **PASS 27, WARN 0, FAIL 0**.
  - `pwsh -File scripts/test-guard-rm.ps1` → **PASS 11, FAIL 0**.
  - `git status` shows 28 modified + 11 new files (within expected ~35 file budget).
- Developer noted one principled disagreement with gate review F-5: template's `F.*` ID is intentional (user-project context vs dogfood `I.*`); not applied. Reasonable.
- Stage advance: development → code-review.

## 2026-05-17 · Stage 5 complete

- Code Reviewer returned **APPROVED**.
- All 4 gate conditions (C-1..C-4) verified satisfied.
- 6-dim audit: PASS across the board; 6 MINORs + 4 NITs (no CRITICAL/MAJOR).
- F-5 (template `F.*` vs dogfood `I.*`) confirmed as gate-review misread, not a real drift.
- Stage advance: code-review → qa.

## 2026-05-17 · Stage 6 returned BLOCKED ON DEV (rollback #1)

- QA Tester reported **BLOCKED ON DEV** with 2 CRITICAL + 1 MAJOR + 2 MINOR defects.
- **D-1 CRITICAL**: `Remove-Item -Path <outside>` bypasses PS guard (case-insensitive `-contains` matches `-Path` to find-predicate `-path`, skips next token).
- **D-2 CRITICAL**: `rm -name /etc/passwd` (and `-path`/`-type`/`-mtime`) bypasses BOTH shells. Find-predicate skip is applied to every destructive verb, not gated to `find`. 5-byte adversarial defeat.
- **D-3 MAJOR**: hook spawns `pwsh` without `-NoProfile`; measured p50=3.7s, p95=4s, vs 50ms NFR. With `-NoProfile`: p50=10ms.
- **D-4 MINOR**: silent global `HARNESS_ALLOW_OUTSIDE_RM=1` survives a single stderr line; no `harness-status` health check.
- **D-5 MINOR**: depth-3 nested pwsh tokenizer-eats inner segment without recursion.
- Other 24+ adversarial cases passed; regression suites all clean.
- Routing back to Developer with three specific fixes (D-1+D-2 same root cause; D-3 add `-NoProfile`; new fixture rows). D-4/D-5 documented but optional for this rollback.
- Stage rollback: qa → development.

## 2026-05-17 · Stage 4 rollback complete

- Developer reported targeted fixes for D-1+D-2 (root cause: find-predicate skip not gated to `find` verb) and D-3 (`-NoProfile` added to both pwsh hooks).
- Fixture suite extended 11 → 17.
- PM independent verification: verify_all 27/27 both shells; test-guard-rm 17/17 both shells; D-2 reproducer `rm -name /etc/passwd` → BLOCK exit 2.
- Stage advance: development → qa (re-dispatch).

## 2026-05-17 · Stage 6 re-run complete — PASSED

- QA re-verified all 5 defects:
  - D-1 (CRITICAL): FIXED — exit 2 BLOCK.
  - D-2 (CRITICAL): FIXED — exit 2 BLOCK.
  - D-3 (MAJOR): PARTIALLY FIXED — 3769ms → 360ms p50 (10× speedup). Absolute 50ms NFR unreachable on Windows pwsh due to ~176ms cold-start floor. QA accepts; filed NIT to revise NFR in follow-up.
  - D-4, D-5 (MINOR): documented as known limitations per dispatch.
- Fixture suite 17/17 PASS both shells.
- Full regression clean (verify_all 27/27, test-init 177/177, test-real-project 82/82).
- Two new adversarial spot-checks (ADV-NEW-1, ADV-NEW-2) both BLOCK correctly.
- QA verdict: **PASSED — APPROVED FOR DELIVERY**.
- Stage advance: qa → delivery.
