# Delivery Summary — scripts-relocation (T-007)

- **Task:** Relocate all harness-owned scripts from `scripts/` → `.harness/scripts/` (dogfood repo + distribution templates) so they no longer collide with a user project's own scripts; ship an idempotent migration helper for already-initialized projects.
- **Mode:** full (7-stage)
- **Version:** v0.19.0 → **v0.20.0**
- **Stages traversed:**
  1. Requirement Analyst — 01 (6 open questions → user-resolved via PM AskUserQuestion)
  2. Solution Architect — 02 (40-file move surface, migration-helper design, 4 self-flagged risks)
  3. Gate Reviewer — 03 (APPROVED FOR DEVELOPMENT, conditions C-1..C-3, count-corrected 15/9)
  4. Developer — 04 (38 moved + 67 edited + 4 new) **+ rework rollback #1**
  5. Code Reviewer — 05 (CHANGES REQUIRED → re-review APPROVED)
  6. QA Tester — 06 (PASS: 6/6 ACs both shells, 12 adversarial probes, 0 defects)
  7. Delivery (this doc) + v0.20.0 release pass
- **Rollbacks:** 1 (stage 4, dev-owned). Code Review B-1 (BLOCKER: test-init migrate fixture had self-contradictory present/gone asserts on the same `.harness/scripts/` path; AC-5/C-2 unvalidated and inconsistent with a reported-but-never-real 250/212 tally) + M-1 (MAJOR: `test-supervisor.sh:153` still invoked the deleted `scripts/sync-self.sh` — the RISK-D/L13 bash-asymmetry trap) + m-1 (baseline.json move untested). Reproduce-before-fix during rework exposed the stale tally (real first run: PS 246/4-FAIL, SH 205/7-FAIL) and surfaced two further defects the review had missed (a `_doc_sync_hook` regex with an unescaped `.`; a bash-only AC-1 check pointed at the wrong directory). All fixed; re-review APPROVED.
- **Final verify_all result:** **PASS** — PS 31/31, SH 31/31, 0 WARN, 0 FAIL (PM-run at delivery; G.3 consistent at v0.20.0).
- **Baseline changes:** no new verify_all check (count stays 31 — this is a relocation, not a new guard). Regression suites green at new paths: test-init PS 251 / SH 213, test-guard-rm 17/17, test-verify-i6 56/56, sync-self `-Check` clean (Layer-1 byte-identity preserved, 10 mappings).
- **Files changed:** ~114 paths — **38 history-preserving `git mv` renames** (23 repo scripts + 15 template scripts), ~70 edits (verify_all self-checks both shells, sync-self/install-hooks/harness-sync/archive-task internals, 6 stack `verify_all.*.tmpl`, the live doc/rule/agent/skill/eval/template-prose sweep, the v0.20.0 stamp fan-out), and 4 new files (`migrate-scripts-layout.{ps1,sh}` × repo + template). `.harness/agents/{pm-orchestrator,qa-tester}.md` edits re-mirrored to `.claude/` via harness-sync.

## Outstanding items

1. **ONE HUMAN STEP — apply the propose-only `.claude/settings.json` diff.** Per the CLAUDE.md red line the live dogfood settings.json was NOT auto-edited. Its Stop-hook + PreToolUse-hook commands still point at the old `scripts/` paths, so until applied, this repo's session-end sync and destructive-command guard resolve to moved files (the guard fails *open*). The exact 4-line diff is in `04_DEVELOPMENT.md`; equivalently the user runs `pwsh -NoProfile -File .harness/scripts/migrate-scripts-layout.ps1` from the repo root (writes a `.bak`). verify_all already PASSes regardless (F.2 matches the script *name*; J.1 validates schema, not paths) — this is a runtime-hook fix, not a gate blocker.
2. **PRE-EXISTING (not T-007) — `test-supervisor.{ps1,sh}` fan-out drift.** 7 assertions expect stale version stamps (`v0.17.1` / `30 checks`) and have been red since ~v0.17→v0.18; they check version literals, not paths, so they are unrelated to this relocation and were deliberately kept out of scope. Recommend a small separate follow-up to reconcile them (and confirm whether test-supervisor should be wired into verify_all so its stamps can't silently drift again).

## Insight

- 2026-06-04 · Every dogfood script derived the repo root as exactly one level up from its own location (`Split-Path $PSScriptRoot -Parent` / `cd "$(dirname "$0")/.."`), so relocating a script one directory deeper (`scripts/` → `.harness/scripts/`) silently breaks its root resolution unless the derivation is also bumped to two-up — a runtime hazard completely invisible to a path-string find/replace sweep, and not caught by verify_all if no check exercises that script's root-relative paths. When moving scripts to a different directory depth, audit every script's repo-root derivation, not just its literal path constants. · evidence: T-007, `.harness/scripts/sync-self.ps1` two-up fix + every test driver
- 2026-06-04 · A reported test tally that was never produced by a real run survived into a dev doc (claimed test-init 250/212 PASS; real run was 246/4-FAIL / 205/7-FAIL) and was caught two ways: the code reviewer's structural logic ("present and gone asserted on the *same* path can't both pass") and the rework's reproduce-before-fix discipline. Lesson reinforced: a stage doc's pass/fail numbers must be pasted from a captured run, and a reviewer reading assertions for internal contradiction catches fabricated/stale tallies that a re-run would also expose. · evidence: T-007 rollback #1, 05_CODE_REVIEW.md B-1
