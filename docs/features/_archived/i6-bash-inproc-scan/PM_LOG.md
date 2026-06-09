# PM Orchestrator Log — i6-bash-inproc-scan

- Task: Port verify_all.sh I.6 retired-claim guard from per-(file×entry) grep-spawning to the in-process line-scan engine the PS twin already uses, killing the ~9k-process Windows/MSYS spawn storm. Migrate test-verify-i6.sh's i6_scan_file in lockstep.
- Mode: full (7-stage)
- Started: 2026-06-09
- ID: T-017

## Pre-dispatch facts gathered by PM

- No `.harness/intervention.md` present (checked at task start).
- insight-index.md applicable lines surfaced to downstream:
  - L22 (T-004): MSYS GNU grep 3.0 SIGABRTs on `-F -i`; `-E -i` unaffected. Current I.6 already uses `-E -i`, so the spawn storm is NOT the abort bug — it is sheer process count. Pure bash `shopt -s nocasematch` + `[[ =~ ]]` mirrors the PS twin and removes spawns.
  - L34 (T-013): I.6 is a FOUR-file lockstep (banned list + exempt list × verify_all.{ps1,sh} × test-verify-i6.{ps1,sh}); `I6ExpectedEntryCount` must stay 14. This task is an ENGINE swap, NOT a data change — all 4 arrays stay byte-identical, count stays 14.
  - L23 (T-004): rely on `verify_all` as the canonical exhaustive scan to validate equivalence over the live tree.
- Exact edit sites located by PM (handed to SA/Dev):
  - verify_all.sh I.6 block lines 502-601; grep call sites at line 573 (`grep -E -n -i -m1`) and line 592 (`grep -E -i -o -m1`).
  - test-verify-i6.sh `i6_scan_file` lines 114-140; single grep call site at line 122. Note: i6_scan_file emits only `idx:line_no`, never the span, so it has NO `-o` span call to port.
  - PS reference twin: verify_all.ps1 lines ~536-562 (Get-Content -Raw → split → per-entry foreach-line Match → first-success exclude test → record + break).
- HARD CONSTRAINTS from user briefing recorded; Gate + Code Reviewer must enforce:
  1. Touch ONLY verify_all.sh (I.6 block) + test-verify-i6.sh (i6_scan_file).
  2. Do NOT touch verify_all.ps1 / test-verify-i6.ps1 (pwsh is DENY-blocked here → unverifiable; already in-process).
  3. Pure engine swap: no change to banned list, exempt lists, gap defaults, i6_build_regex, exclude semantics, reporting contract, I6ExpectedEntryCount.
  4. Preserve grep -m1 semantics: stop at FIRST regex-matching line; if exclude-suppressed, do NOT fall through to a later line.
  5. Lockstep: migrate test driver to the identical new engine.
  6. NO commit / push / version bump. Confirm no CHANGELOG/version obligation applies (verify_all.sh not in sync-self mirror set, check count stays 32).

## Stage transitions

### Stage 1 — requirement-analyst — 2026-06-09
- Dispatched with mode=full + surfaced insight L22/L23/L34. INPUT.md provided.
- Output: 01_REQUIREMENT_ANALYSIS.md. Verdict **READY**.
- 8 in-scope behaviors, 6 ACs, AC-4 equivalence harness, NFR-1 cross-shell-parity/lockstep guard.
- OQ-1 (rule-30 symmetry vs constraint-2) and OQ-2 (span cosmetic) both PRE-RESOLVED by user briefing → recorded for traceability, NOT blockers. RA correctly did not mark BLOCKED.
- Intervention check: none present.
- **PM decision: ADVANCE to Stage 2 (solution-architect).** No rollback. Routing clean.

### Stage 2 — solution-architect — 2026-06-09
- Output: 02_SOLUTION_DESIGN.md. Verdict **READY**.
- Exact replacement blocks for verify_all.sh:563-595 (§6.2) and test-verify-i6.sh:114-140 (§6.3).
- SA caught a real trap (R-3): the PS twin actually FALLS THROUGH to later lines after an exclude (`break` reached on both paths via `continue`), but current bash grep -m1 STOPS at first match. Constraint 4 says preserve BASH behavior → bash port must NOT copy the PS fall-through. Out-of-scope §10 documents this as a pre-existing, unreachable-in-practice asymmetry.
- SA confirmed constraint-6 version question: verify_all.sh NOT in sync-self mirror set, no template twin, check count stays 32, NO CHANGELOG/version obligation. Surfaced as a note, not acted on. ✔ matches user instruction.
- 6 risks with mitigations (R-2 unquoted `$rx` false-negative, R-4 nocasematch leak — both flagged for Code Reviewer eyeball).
- Single-dev mode confirmed (no dev-*.md); partition section omitted correctly.
- Intervention check: none present.
- **PM decision: ADVANCE to Stage 3 (gate-reviewer).** No rollback.

### Stage 3 — gate-reviewer — 2026-06-09
- Output: 03_GATE_REVIEW.md. Verdict **APPROVED** (full mode).
- 8/8 dimensions PASS. GR independently verified: grep call sites at 573/592/122; PS R-3 break placement; bash `[[ =~ ]]`+`BASH_REMATCH`+`nocasematch` already used at verify_all.sh:463-464/581-589 (proves env supports the new engine); generated regex is pure POSIX ERE (no PCRE); verify_all.sh not in sync-self mirror set.
- WARN-1: design §6.1 prose slightly imprecise about PS break placement, but actionable pseudo-code (§6.2/§6.3) is correct → NOT routed back (no behavior/AC change).
- WARN-2: Developer must NOT touch the per-type verify_all.sh.tmpl (separate file, out of scope); AC-5 catches a slip.
- 5 dev questions pre-answered (Q-2 unquoted `$rx` = most dangerous line; Q-3 AC-4 harness is a throwaway QA artifact, not committed).
- Intervention check: none present.
- **STAGE GATE for Stage 4 SATISFIED** (explicit APPROVED verdict).
- **PM decision: ADVANCE to Stage 4 (developer, single-dev mode).** No rollback.

### Stage 4 — developer — 2026-06-09
- Code implemented EXACTLY per approved design §6.2 / §6.3. Output: 04_DEVELOPMENT.md.
- Files changed (working tree, uncommitted):
  - `.harness/scripts/verify_all.sh` — I.6 inner loop (now lines 562-613): mapfile read-once + per-line `[[ =~ $rx ]]` under nocasematch; `${BASH_REMATCH[0]}` span; grep -m1 parity (`break` after first match on both paths); both grep call sites removed.
  - `.harness/scripts/test-verify-i6.sh` — `i6_scan_file` migrated to the identical engine; grep call site removed (lockstep, constraint 5).
- No DESIGN DRIFT. No data change (banned/exempt lists, gap, i6_build_regex, I6ExpectedEntryCount=14 all byte-untouched).
- PM re-read the verify_all.sh edit (lines 562-613): correct — unquoted `$rx`, balanced shopt -s/-u nocasematch, grep -m1 break placement, report format preserved.
- **Developer verdict: BLOCKED ON CAPABILITY.** The Bash tool is NOT available in this dispatch environment ("No such tool available: Bash"); PowerShell is also unavailable (and deny-blocked). The mandatory captured runs CANNOT be produced here:
  - AC-1 `bash test-verify-i6.sh` (positive-fixture no-false-negative proof) — NOT RUN
  - AC-2 `bash verify_all.sh` 32/0/0 — NOT RUN
  - AC-3 before/after `time` — NOT CAPTURED (baseline also unobtainable: needs the same tool, pre-edit)
  - AC-4 old-vs-new equivalence over `git ls-files` — NOT RUN
- Per Developer hard rule 3 + insight L27/T-007 (pass/fail numbers MUST come from a captured run, never fabricated), I refuse to fabricate green results.

### PM HARD STOP — external capability blocked — 2026-06-09
- Stage gate for Stage 5 ("Stage 4 must show verify_all PASSED") CANNOT be satisfied — no captured run exists. I do NOT advance to Code Review / QA / Delivery on fabricated evidence.
- Triggers PM hard-stop rule 4 ("external dependency blocked") and "When to stop and ask the user: an agent reports a missing external capability."
- Intervention check: none present.
- **PM decision: STOP and escalate to user.** Code is written + design-faithful; verification must be run by the user (or an environment with a shell). Pipeline parked at end of Stage 4. Stages 5-7 NOT executed.
