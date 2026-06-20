# 06 — Test Report · T-11c entropy-watch-persist

> Stage 6 (QA Tester). Mode: full (final slice; decline-filter only). deferred-human: defer, do not ask.
> Two gates RUN (Bash): `verify_all.sh` 32/0/0, `test-supervisor.sh` 45/0. PowerShell denied → PS
> twins marked operator-pending (never faked). CR APPROVED (both axes PASS); QA verifies, does not trust.
> This slice is a PROSE CONTRACT (a decline-filter spec single-sourced in the scan reference) — there is
> no executable filter to unit-test, so the adversarial probes are inspection/grep against the contract,
> plus the two real gates that DO execute (G.3/G.4 stamping + I.6 banned-anchor scan + supervisor harness).

## Test plan

| Acceptance criterion (01 §Acceptance) | Verification | Evidence |
|---|---|---|
| AC-1 declined module's EP row omitted | spec exact-match drop rule present + worked sibling example | `entropy-scan.md` L75-83; AT-1 |
| AC-2 remove record → finding reappears | filter is deterministic set subtraction keyed ONLY on the record | `entropy-scan.md` L91; AT-2 |
| AC-3 `decline EP-NNN` writes T-09 `## <Where>` record | step-4 record-shape contract (Decision/Why/Origin) | `SKILL.md` L75-87; AT-3 |
| AC-4 2nd decline same handle → append origin, no 2nd record | T-09 de-dup clause | `SKILL.md` L88-90; AT-4 |
| AC-5 decline = no refactor / no production edit / verify_all green | no `/harness-goal` in decline branch; `allowed-tools` unchanged; gate green | `SKILL.md` L67-90, L15; verify_all 32/0/0; AT-5 |
| AC-6 non-declined still-shallow re-surfaces | only declined-key matches subtracted; re-derive untouched | `entropy-scan.md` L91, L96-98; AT-6 |
| AC-7 verify_all green + 0.43.0 + no count flip | gate run; 4 stamps + CHANGELOG; 17/8/32/90/314 intact | verify_all 32/0/0 (G.3/G.4 PASS); AT-7 |

## Boundary tests covered (inspection of the contract)
- **Absent rejected-decisions.md** → fail-open no-op, all findings surface (`entropy-scan.md` L87-89).
- **Header-only / empty file** → "no declines", identical to absent (L89).
- **Unreadable file** → no-op, never suppress on read failure (L87-88).
- **Stale declined handle (matches no finding)** → suppresses nothing, sits harmlessly (L83).
- **Two findings same normalized key** → both dropped when that key is declined (L81-83).
- **All findings dropped** → `Entropy-verdict: CLEAN` (L79-82).
- **Decline of an ID not in the just-presented artifact** → report + NO write, no guessing (`SKILL.md` L69-71).
- **Path-sep / leading-./ / trailing-/ variance** → normalized on BOTH sides before equality (L69-74).

## Adversarial tests (REQUIRED — one per acceptance criterion)

Each row states a failure hypothesis BEFORE the probe, then the outcome with tool evidence. For a prose
contract the "implementation" is the spec text; "survived" = the contract forecloses the failure mode.

| AC | Hypothesis ("I expect failure when…") | Reproducer (independent) | Outcome (with evidence) |
|---|---|---|---|
| AC-1 | the match is substring/prefix → a declined `src/a` over-suppresses sibling `src/ab` | grep the exact match rule in `entropy-scan.md`; reason the worked example | **Survived** — L75-78 says drop **iff** `normalize(Where) == normalize(handle)`, "EXACT string equality after normalization — NOT substring, NOT prefix". `src/a != src/ab` and `src/a` is a *prefix* of `src/ab` which is explicitly excluded → sibling NOT suppressed. |
| AC-2 | nothing but the record causes the drop, so removal might not restore the finding | inspect for any 2nd suppression source | **Survived** — L91 "deterministic set subtraction (declined-key set − derived-finding set)"; the only suppressor is a matching declined/deferred record. Remove it → key no longer in subtrahend → finding re-derived (round-trip holds). |
| AC-3 | decline writes a malformed / EP-NNN-keyed record (unstable key) | read `SKILL.md` step-4 record shape | **Survived** — L81-87: `## <stable-key>` + `Decision: declined` + `Why` + `Origin: entropy sweep <ISO-date> · EP-<class>`; L87 "date + class, NOT the unstable per-run EP-NNN". |
| AC-4 | a 2nd decline of the same handle creates a duplicate record | read de-dup clause | **Survived** — L88-90: if a record for `<stable-key>` exists, append origin to its `Origin` line "rather than creating a second record. One record per concept." Live file has the `## entropy-findings-store` record exactly once (grep count = 1). |
| AC-5 | the decline path dispatches `/harness-goal` or grants an Edit/Write tool | grep `/harness-goal` in SKILL + read `allowed-tools` | **Survived** — `allowed-tools: Read, Glob, Grep, Task` (L15, no Edit/Write). `/harness-goal` appears at L65 (the **deflate** branch) and L91/L94 (deflate execute); the **decline** branch L67-90 says "NO `/harness-goal` dispatch, NO production-file edit" and contains no Task call. verify_all 32/0/0. |
| AC-6 | the filter accidentally subtracts a non-declined finding | inspect subtraction scope | **Survived** — L91 subtraction is keyed ONLY on declined/deferred records (L76); a non-declined still-shallow module is re-derived each sweep (L96-98 determinism) and re-surfaces. |
| AC-7 | a count flipped or a stamp missed the bump | run verify_all; grep counts/badges | **Survived** — verify_all 32/0/0 incl G.3 (4 stamps @ 0.43.0), G.4 ([0.43.0] + claim↔plugin.json). Live counts: 17 skills / 8 agents / 32 checks; README line-5 badges `version-0.43.0 / 32%2F32 / 314%2F314 / 90%2F90` intact. |

### Extra adversarial probe — DRY (NFR-1)
- Hypothesis: the key-rule mechanics are restated in a 2nd place → drift surface.
- Reproducer: `grep -rn "exact string equality"` (repo-wide, case-insensitive) and `grep "Decline filter"`.
- Outcome: **Survived.** "EXACT string equality" + the normalize/match mechanics live ONLY in
  `entropy-scan.md` L75-78. `supervisor.md` L154-156 and `SKILL.md` L73-74 only POINT
  ("read it for the key + match + fail-open contract", "normalized per the `## Decline filter` rule …
  do not restate it here"). Other `exact string equality` hits are the 02/03 design/gate docs, not the
  two pointer files.

### Extra adversarial probe — no findings-store created (scope-down)
- Hypothesis: a standalone open/fixed store file was created despite the scope-down.
- Reproducer: `Glob **/entropy-findings*` and `Glob .harness/entropy-*.md`.
- Outcome: **Survived.** Both globs return "No files found". The store concept is itself recorded as a
  single `## entropy-findings-store` decline in `.harness/rejected-decisions.md` (grep count = 1).

### Extra adversarial probe — I.6 on the new records
- Hypothesis: a new decline record / scan section / SKILL prose quotes a banned retired-claim anchor and
  trips I.6 (rejected-decisions.md IS scanned).
- Reproducer: full `verify_all.sh` (I.6 runs against the live tree incl the new records).
- Outcome: **Survived.** `[I.6] No retired-claim phrases in current docs/templates ... PASS` with the
  `## entropy-findings-store` record + the `## Decline filter` section + the SKILL step-4 prose present.

## verify_all result
- Total checks: 32 → 32 (no new check; check count unchanged).
- PASS: 32 · FAIL: 0 · WARN: 0.
- G.3 version stamps consistent @ 0.43.0 (plugin.json + marketplace.json + README + README.zh-CN) — PASS.
- G.4 [0.43.0] CHANGELOG heading + claim↔plugin.json consistency — PASS.
- I.6 banned-anchor scan (incl new rejected-decisions records + scan section + SKILL prose) — PASS.
- test-supervisor.sh: 45 PASS / 0 FAIL (supervisor edited; 285 lines ≤300 cap — I.3 PASS).
- New automated tests added: 0 (this slice is a prose contract — no executable filter; the two existing
  gates fully cover the gated surface: stamping, I.6, supervisor doc-shape/≤300). Baseline test counts
  unchanged by design (RA/02: NO new check, NO count flip).
- Baseline updated: NO (correct — counts unchanged; baseline only moves up, and nothing went up).

## Defects found
- None. 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR.
- (Pre-existing NIT carried from CR, non-blocking: the live `## Decline filter` heading drops the design's
  `(T-11c)` suffix — consistent with the file's other suffix-free headings; the frozen `supervisor.md`
  `v0.17.0` example stamp at L167 is correctly untouched, not a G.3 stamp.)

## Stability
- `verify_all.sh` and `test-supervisor.sh` each run once this session; both deterministic gates with no
  network / no time-of-day dependence in the checks exercised. No flake observed. The decline filter is
  specified as a deterministic set subtraction (NFR-2), so re-runs over an unchanged tree + unchanged
  rejected-decisions.md yield an identical findings list.

## PowerShell twins
- `verify_all.ps1` / `test-supervisor.ps1` NOT run (PowerShell denied in this environment). Marked
  **operator-pending** — an operator should run the PS twins for cross-shell parity. NOT faked. The
  `.sh` gates are the executed source of truth here.

## Verdict
**APPROVED FOR DELIVERY** — 0 defects. All 7 acceptance criteria survive their adversarial probe; 8
boundary conditions covered by the contract; DRY single-sourced (key rule only in `entropy-scan.md`,
both pointers point); no findings-store created (single `## entropy-findings-store` decline record);
decline path is dispatch-free + adds no tool; fail-open + dropped-not-counted + all-dropped→CLEAN
specified; verify_all.sh 32/0/0 (G.3 0.43.0, G.4 [0.43.0], I.6 clean incl new records);
test-supervisor.sh 45/0; supervisor 285 ≤300; 17/8/32/90/314 unchanged; README badges intact. PS twins
operator-pending.
