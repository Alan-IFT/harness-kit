# 07 — Delivery: sync-hook-dangling-ref (T-020)

Verdict: **DELIVERED** · v0.31.0 · 2026-06-11 · Mode: full (7 stages, 1 rollback)

## What shipped

A consumer project could end up with a `.claude/settings.json` hook wired to a script that
does not exist on disk (the user-reported symptom: Stop hook fires
`bash: .harness/scripts/harness-sync.sh: No such file or directory` on every turn).
This release makes that state **unreachable by construction**, **loudly diagnosable**, and
**mechanically repairable** — without adding a new command (the user's "doctor" question was
adjudicated: extend `/harness-status` + `/harness-upgrade` instead; see 02 §2).

- **Prevention:** `migrate-scripts-layout.{ps1,sh}` and `upgrade-project.{ps1,sh}` now use
  presence-gated per-variant hook rewires and end with a terminal hook↔script congruence
  scan (new exit code 4; apply mode re-reads the written file from disk). `/harness-init`
  step 10b and `/harness-adopt`'s terminal step assert the same invariant in prose flows;
  adopt's substitution table gains `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` with OS-pick rules.
- **Repair:** `/harness-upgrade` re-lands missing script pairs (refresh set widened with the
  ambient pair), repairs wired literal placeholder tokens to the OS-picked command
  (`REWIRE-PLACEHOLDER`, gate condition C3/option A), and exits 4 with explicit
  `CONGRUENCE-FAIL` records when an end state would dangle. Idempotent; raw-text + `.bak`.
- **Diagnosis:** `/harness-status` §3c checks all 4 hook events (ok / not wired / DANGLING /
  MALFORMED + interpreter-availability WARN); the six type-template `verify_all` gain an
  E.4b/D.4b dangling-hook FAIL row.
- **RC-6 (found during analysis):** the type templates' E.3/D.3 and `/harness-status` still
  demanded 7 framework agents in `.harness/agents/` — a healthy v0.30 project failed its own
  gate. Replaced with the v0.30-correct expectation (partition `dev-*` only; WARN on legacy
  copies). Ambient hooks' hard-coded `pwsh` became OS-picked placeholders (OQ-3).

## Stage trail

| Stage | Verdict |
|---|---|
| 1 Requirement Analyst | READY-FOR-DESIGN (RC-1..4 confirmed, RC-5 ruled out, RC-6 found) |
| 2 Solution Architect | READY (+C3 amendment §6.2.5) |
| 3 Gate Reviewer | GO-WITH-CONDITIONS (C1-C4) |
| 4 Developer | 37 files; all suites green (observed runs in 04) |
| 5 Code Reviewer | REWORK (1 MAJOR: B8 silent-dangle on failed settings write) → rework round 1 → **APPROVED-WITH-NOTES** |
| 6 QA Tester | **PASS-WITH-NOTES** — user-scenario replay: symptom reproduced verbatim (rc=127) → repaired (rc=0) → idempotent; AC-7 cross-shell `cmp` byte-identical; 1 pre-existing MINOR (D-1 CRLF, routed to OQ-4 follow-up) |
| 7 Delivery | this document |

Run notes: the pipeline ran with the PM shell in the main thread (sub-agents in this
environment have no Task tool); each stage still ran as its own isolated sub-agent. The
stage-4 rework agent was killed by a stream-idle API error after its code landed — the PM
attributed the changes in 04 ("Rework round 1") and observed the verification runs itself.

## Verification

- test-harness-upgrade 79/0 (sh) + 80/0 (ps1) · test-init 270/0 + 308/0 · test-real-project
  90/0 ×2 · test-supervisor 45/0 + 49/0 · test-verify-i6 58/0 ×2 · test-language 39/0 ×2 ·
  test-guard-rm 17/0 ×2 · sync-self --check "In sync." (QA-captured, both shells)
- Final verify_all result: PASS (32/0/0; see below for the delivery-time run)

## Follow-ups (not in this task)

- OQ-4 template-docs sweep: pre-existing stale usage headers in 2 verify_all ps1 templates;
  D-1 MSYS sed CRLF→LF normalization on first rewire (pre-existing, loud, JSON-intact).
- E.4b sh/ps output cosmetics (dedupe/quoting divergence; both FAIL identically).

## Insight

- 2026-06-11 · A terminal "end-state" assertion must read the medium the state actually lives in — the migrate helper's congruence scan validated the in-memory settings text it intended to write, so a failed write (read-only/disk-full) exited 0 silently dangling, while its sibling upgrade-project had the correct re-read-from-disk pattern; the Code Reviewer caught it by comparing siblings. When two helpers share a pattern, audit them as a pair: the divergence IS the bug signal. · evidence: T-020 05_CODE_REVIEW MAJOR B8, migrate-scripts-layout.sh:175 (post-fix), test-harness-upgrade M3 probes
- 2026-06-11 · `skills/harness-status/SKILL.md`'s asset rows are structurally pinned by `test-supervisor.{ps1,sh}` doc fan-out asserts — editing/retiring a status asset row breaks test-supervisor even though no fan-out list names that coupling; update the asserts to the new state (don't delete) and treat status-SKILL row edits as a test-supervisor touchpoint. · evidence: T-020 dev round 1, test-supervisor.sh:390-395 pre-fix 2-assert failure on the §6.7 row removal
