# PM_LOG — T-005 i6-test-hardening

> PM Orchestrator log. One entry per stage transition or notable decision.

## Task framing

Source: user-initiated follow-up after T-004 (i6-semantic-guard, v0.18.0) shipped.
User asked PM to triage four leftover non-blocking observations from T-004 CR/QA notes and
two larger-picture concerns. Decision authority delegated: "你来决策就可以了，我只看结果".

### Decisions in scope (will be addressed by this task)

- **Obs-A** — `test-verify-i6.ps1` structural lockstep is weaker than bash side. Bash extracts
  `verify_all.sh` `$i6_banned` lines verbatim and compares all 13 entries; PS side only checks
  entry count + entry #10's `exclude=@('.claude/')` clause. Means a typo in any of #1, #3-9,
  #11-13's `reason` strings (or `exclude` / `gap` clauses) in `verify_all.ps1` would slip past
  PS lockstep. The cross-shell parity assertion (existing) provides a partial safety net but
  only catches divergences that change behavioral hit sets — a `reason`-string typo doesn't.
  → **Build symmetric verbatim lockstep** for `verify_all.ps1` `$banned`; for symmetry, also
  add verify_all.ps1 verbatim lockstep on the bash side.

- **Obs-B** — AC-8 (CHANGELOG.md file-exempt + `docs/features/_archived/` dir-exempt preserved)
  had only an inline injection probe in T-004 QA, no permanent corpus fixture. Means a future
  refactor to verify_all's exempt-list handling could silently regress AC-8 without
  test-verify-i6 catching it.
  → **Add permanent fixtures** that model file-level exemption (parallel to existing dir-level
  `Test-I6DirExempt`) and assert the exempt-list in `verify_all.{ps1,sh}` matches the driver's
  canonical list.

- **Obs-C** — `docs/manual-e2e-test.md:3` still claims `v0.17.4` for `scripts/verify_all`. Not
  in T-004 design §10's fan-out contract, so was not touched then. Single-line doc consistency
  fix; long-term maintainability and user UX both improve from accuracy here.
  → **Trivial follow-up commit** (separate from main task), not pipelined.

### Decisions OUT of scope (will NOT be addressed)

- **Obs-D** — `architecture.html:326` says `v0.17.4`. User explicitly said: "该文件本身带
  v0.5/v0.6 snapshot caveat 并明确把刷新延后到 v0.18+ roadmap，按设计契约这次不动". Honored.

- **Obs-E** — Upgrade I.6 matcher to NLP/embedding-grade semantic matching. User explicitly
  said: "远超本次"; T-004 design §3.2 documents the trade-off (threat model = unintentional
  copy-paste drift, NOT active adversary). Honored — no scope expansion.

## Stage log

### 2026-05-23 — Task created (Stage 0)

- mode: full
- stage: requirements
- Insight-index lines reviewed before dispatching Stage 1:
  - L18 (T-003 retired-claim guard design) — still authoritative for I.6 threat model.
  - L23 (PS `-cmatch` / case-sensitive operators) — applies if new structural-lockstep
    regex uses any string operator with case-sensitivity contract.
  - L26 (v0.18.0 I.6 upgrade + test-verify-i6 exempt note) — names this regression-driver
    pair as an exempt FILE in the live I.6 scan; this task ADDs to the driver pair.
  - L27 (GNU grep 3.0 `-F -i` bug + bash discovery) — applies to any new bash regex/string
    matching added in test-verify-i6.sh; prefer `shopt -s nocasematch` + `[[ == *glob* ]]`.
  - L28 (live-tree matcher run is the canonical exhaustive scan) — design must run
    verify_all over the live tree, not hand-reason about per-family safety.
  - L29 (sweep sibling scripts when capturing L13-style insight) — relevant if any
    `declare -a` patterns are introduced.

### 2026-05-23 — Stage 1 (Requirement Analysis) complete

- Verdict: **READY** (all five open questions Q-1..Q-5 carry PM-binding decisions under
  user-delegated authority; none routes to user as a blocker).
- Output: `01_REQUIREMENT_ANALYSIS.md` — 9 sections, 20 ACs, 8 NFRs.
- Note: 559 lines, marginally over the 500-line soft cap (rule 70). Acceptable for stage 1 of
  a structurally dense test-hardening task; will compact in archive if still over after
  delivery. No FAIL impact on `verify_all` (I.* doc-size checks are WARN, not FAIL).

### 2026-05-23 — Stage 1 → Stage 2 transition

- Stage advanced: `requirements → design`.
- Updating tasks.md row stage.

### 2026-05-23 — Stage 2 (Solution Design) complete

- Verdict: **READY**, ~488 lines (well under cap).
- Output: `02_SOLUTION_DESIGN.md` — 14 sections, all 5 Q-decisions confirmed without override.
- Architect surfaced 5 risks (R-1..R-5) with mitigations; top 3 for GR: R-1 (backtick decode
  in PS bash-record parser), R-3 (PS case-sensitive operator discipline), AC-17 expected-count
  uncertainty.
- **PM-measured baseline note for GR**: actual current `PASS:` counts are **PS=35 / bash=34**,
  not the 32/32 the architect cited in §9 of the design. Architect's derivation `32 + 26 = 58`
  has the wrong baseline but the absolute target 58/58 likely holds (PM hand-derivation:
  35+23 = 58; 34+24 = 58 — the architect's row attribution miscounts 3 already-existing rows
  as "new" but the final absolute lands on 58). Asking GR to either confirm the absolute or
  re-derive cleanly.

### 2026-05-23 — Stage 2 → Stage 3 transition

- Stage advanced: `design → gate-review`.

### 2026-05-23 — Stage 3 (Gate Review) round 1

- Verdict: **CHANGES REQUIRED**.
- One Major finding M-1: design §9 expected-count derivation wrong-baselined (cited 32/32,
  actual 35/34; undercounts subsumed rows). AC-17 depends on §9.
- Four Minor findings m-1..m-4: PS escape syntax not spelled out; AC-15 `$` escape under-doc;
  `-cmatch` not named for new regex paths; 01 over 500-line soft cap (archive-task handles).
- All Minor findings pre-answered for Dev in §3 of GR (Q-Dev-1..Q-Dev-5).
- File: `03_GATE_REVIEW.md` written by PM (the GR agent could not Write per its harness
  restriction; PM transcribed the verdict in full).

### 2026-05-23 — Stage 3 → Stage 2 routing back

- Per /harness contract: CHANGES REQUIRED routes back to Architect for the M-1 fix.
- PM applied the fix in place under user-delegated authority (rather than a fresh Architect
  dispatch): chose GR's Option (b) — downgrade §9 to empirical-equality contract — because
  it is more robust against future driver-row reshuffles (the long-term maintainability
  principle the user named). The patch is ≤20 lines inside §9 only; matches GR's pre-answer
  in Q-Dev-3 verbatim.

### 2026-05-23 — Stage 3 (Gate Review) round 2

- Re-dispatched GR with a scoped prompt: verify M-1 resolved by the §9 patch; do NOT
  re-audit dimensions that already PASSed.
- Verdict: **APPROVED FOR DEVELOPMENT**.
- One residual Minor m-5 surfaced: §11 (Roll-forward) still cited stale `PASS: 58 / FAIL: 0`.
  PM patched in the same cycle (§11 step 1 / step 2 now reference §9's empirical contract).
  GR re-review block appended to `03_GATE_REVIEW.md` as §6.

### 2026-05-23 — Stage 3 → Stage 4 transition

- Stage advanced: `gate-review → development`.

### 2026-05-23 — Stage 4 (Development) complete

- Developer agent hit token rate limit (83 tool uses, 55-min runtime) before writing
  `04_DEVELOPMENT.md`; PM transcribed the implementation record from the verified script
  edits and tool-log evidence.
- Code edits in place:
  - `scripts/test-verify-i6.ps1`: 388 → 706 lines (+318)
  - `scripts/test-verify-i6.sh`:  365 → 556 lines (+191)
- All 7 PM-defined verification gates passed:
  1. `bash test-verify-i6.sh` → PASS: 56, FAIL: 0 ✅
  2. `pwsh test-verify-i6.ps1` → PASS: 56, FAIL: 0 ✅
  3. PS == bash (56 == 56) ✅
  4. 3-run stability confirmed (foreground runs identical)
  5. Monotonic: 56 > 35 (PS), 56 > 34 (bash) ✅
  6. `verify_all.sh` 30/30 PASS, `verify_all.ps1` 30/30 PASS ✅
  7. No bare `-eq`/`-contains`/`-match`/`-notin` in new PS code outside comments ✅
- Empirical landing-zone check (§9 informational): PASS=56 is inside `[40, 80]`.
- Stage advanced: `development → code-review`.

### 2026-05-23 — Stage 5 (Code Review) complete

- Verdict: **APPROVED**.
- Findings: 0 CRITICAL, 0 MAJOR, 1 MINOR (`local -n` requires bash 4.3+; non-blocking on
  de-facto Windows+Linux target), 2 NITs (pre-existing `-notmatch` + cosmetic doc-comments).
- m-1 / m-2 / m-3 from GR all VERIFIED CORRECT.
- 3-run stability confirmed across 6 runs (PS×3 + bash×3, all PASS:56).
- bash `verify_all.sh` confirmed 30/30 PASS (post-CR background run completed).
- PM decision on MINOR `local -n`: NOT patching this round; flagging for future maintenance.
  Rationale: zero risk on actual target platforms (Git-bash on Windows ≥5.x, all modern
  Linux ≥4.4); fix would require either an inline expansion (verbose) or a comment naming
  the floor; deferring to a future cleanup pass keeps the T-005 diff scope-clean. Will note
  in delivery as a known-limitation insight.

### 2026-05-23 — Stage 5 → Stage 6 transition

- Stage advanced: `code-review → qa`.

### 2026-05-23 — Stage 6 (QA) complete

- Verdict: **READY FOR DELIVERY**.
- 12 mutations executed (M1-M12): all 12 detected by both drivers; mutation revert cycle
  left `verify_all.{ps1,sh}` byte-identical to HEAD.
- Adversarial coverage: anchors / reason / exclude / gap each mutated on both
  `verify_all.ps1` and `verify_all.sh`. M9 specifically exercised the PS backtick-decode
  path (R-1 mitigation), confirming the decode is doing real work.
- AC-8 + AC-9 exempt-list mutations (M10 / M11) detected.
- AC-14 negative-regression (M12 / fixture present in baseline output) confirmed.
- 3-run stability: 56:0 every run × 6 runs, no flakes.
- `verify_all.ps1` and `verify_all.sh` both 30/30/0 PASS.
- QA also bumped `scripts/baseline.json` `test_verify_i6_ps_assertions` 35→56 and
  `test_verify_i6_bash_assertions` 34→56 (required since the asset-count contract changed).

### 2026-05-23 — Stage 6 → Stage 7 transition

- Stage advanced: `qa → delivery`.

### 2026-05-23 — Stage 7 (Delivery)
