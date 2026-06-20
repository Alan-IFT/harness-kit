# 06 — Test Report · T-09 rejected-decisions-memory

> Stage 6 (QA Tester). Mode: full. deferred-human: defer (do not ask). Bash available; PowerShell DENIED (PS twins marked operator-pending, never faked).
> CR = APPROVED WITH NOTES (both axes clean). Scope: T-09 attributable artifacts only; co-mingled sibling churn ignored.

## Test plan

| Acceptance criterion | Test case(s) / evidence | File |
|---|---|---|
| AC-1 dogfood file + ≤6-substance header, no gate | header read (8 soft-wrapped / 6 substance lines, soft size note "no gate enforces size") | `.harness/rejected-decisions.md` |
| AC-2 named seed records, 4 fields each, deferral/declined marked | independent reproducer: 9 `##` records, Decision/Why/Origin ×9, all 9 named declines PRESENT, exactly one `deferred` | `.harness/rejected-decisions.md` |
| AC-3 generic placeholder-free seed ≠ dogfood, not byte-synced | `{{...}}` scan NONE; `diff -q` DIFFER; sync-self has no mirror ref; verify_all E.1/E.2 PASS | template seed |
| AC-4 AI-GUIDE 4th memory line ≤200 | line 40 present + singular; AI-GUIDE 111 lines | `AI-GUIDE.md` |
| AC-5 dev-map location row | row resolves to both real paths | `docs/dev-map.md` |
| AC-6 read/append single-sourced in rule 25; RA/SA pointer-only | rule 25:22 canonical; RA:43 + SA:45 say "per `.harness/rules/25-decision-policy.md`"; rule 25 = 106 lines | rule 25 / RA / SA |
| AC-7 no new check (32); no new hook | verify_all = 32 checks, same as baseline | `verify_all.sh` |
| AC-8 telemetry not two divergent rationales | rule 15:99-104 gloss = same reason (standing per-call cost / single-maintainer) + points to new file for "their reasons" | `15-skill-authoring.md` |
| AC-9 verify_all PASSes 32/32, no new WARN | 32/0/0 (3 stable runs) | `verify_all.sh` |
| AC-10 no I.6 self-trip, both files in scope | I.6 PASS; both in `git ls-files`; banned-anchor topic scan NONE | both new files |
| AC-11 version +1 minor, G.4 PASS, no count claim changed | 0.40.0 in 4 stamps + CHANGELOG [0.40.0]; G.3/G.4 PASS; no count flip | stamps/CHANGELOG |

## Boundary tests added

No NEW automated tests authored this stage — the single load-bearing assertion (`rejected-decisions.md seed present (generic)`) was added by the developer in BOTH shells (sh + ps1 twin), and its non-vacuity is PROVEN below by mutation (the strongest boundary test). The recursive `{{...}}` placeholder scan (test-init) auto-covers the seed's placeholder-free property across all 3 project types + the zh fall-through path. Boundary states exercised:
- File-present (happy): seed lands in generic/fullstack/backend + zh fall-through → +3 assertions.
- File-absent (mutation): assertion FAILs ×3 → non-vacuous.
- Empty/illustrative seed body: 1 `example-declined-concept` stub, no real declines (generic).
- Dogfood vs seed divergence: not byte-identical (AC-3).

## Adversarial tests (REQUIRED, one per probe — independent reproducers, stated hypothesis)

| Probe | Hypothesis ("I expect failure when…") | Reproducer (mine) | Outcome (tool output) |
|---|---|---|---|
| **Load-bearing mutation** | If the seed assertion is vacuous, removing the template seed still passes test-init.sh | `mv` seed away → `bash test-init.sh` → restore → re-run | **Survived (non-vacuous proven).** Without seed: `PASS: 273 / FAIL: 3` — `FAIL rejected-decisions.md seed present (generic)` ×3 (one per project type). After restore (byte-identical, IDENTICAL): `PASS: 276 / FAIL: 0`. |
| **I.6 self-trip** | A seed record quotes a banned anchor (CLAUDE.md gen/compose, `全程中文`, `scaffolding-only`) → I.6 FAIL | `grep -Eni 'CLAUDE\.md|全程.*中文|scaffolding-only|composed|regenerat|Generated from'` both files + verify_all I.6 | **Survived.** Topic scan = `NONE (clean)`; `[I.6] … PASS`; both files in `git ls-files` (non-exempt, in scan scope). |
| **Placeholder scan** | Seed carries `{{UPPER_SNAKE}}` → test-init `{{...}}` scan FAIL | `grep -rEn '\{\{[A-Z_]+\}\}'` seed (and dogfood) | **Survived.** Both = `NONE (clean)`. |
| **Single-source** | Habit prose is duplicated (RA/SA/15 restate the read/append rule, not point) | grep rule 25 / RA / SA / 15 / AI-GUIDE | **Survived.** Canonical prose only in rule 25:22-28. RA:43 + SA:45 = "append … per `.harness/rules/25-decision-policy.md`" (pointer). 15:99-104 = "now live in `.harness/rejected-decisions.md` with their reasons" (pointer). AI-GUIDE:40 = "governed by `25-decision-policy.md`". |
| **C1 no count flip** | A live `16 skills`/`32 checks` token was flipped to 15 | grep `15 skills/检查/checks/技能` across live docs | **Survived.** Only hits = CHANGELOG 186/196/210 (immutable `[0.30.x]` history; 186 = "byte-identical to v0.30.0"). [0.40.0] §35-36 restates "**16 skills / 8 framework agents / 32 checks**". C.1/G.1/G.2/G.4 PASS. |
| **C2 baseline** | PS field or README badge was edited by this agent (PM reconciles PS) | grep baseline `test_init_ps_assertions` + both README `test--init` badges | **Survived.** `test_init_ps_assertions: 308` unchanged; both badges `test--init-308%2F308` unchanged; bash field = 276 (matches captured run). |
| **Dogfood ≠ seed** | The two files are byte-identical (generated projects ship harness's real declines) | `diff -q` | **Survived.** `DIFFER` (9 real records vs 1 stub). |
| **Version + caps** | A stamp lags 0.39.0, or a capped file >200 | grep stamps + CHANGELOG; `wc -l` | **Survived.** 0.40.0 in plugin/marketplace/2 READMEs + CHANGELOG [0.40.0]; AI-GUIDE 111, rule25 106, rule15 113 (all ≤200); RA 77, SA 144 (≤300). G.3 PASS. |

### Tool-output evidence (key lines)

```
# verify_all.sh (3 stable runs, identical)
PASS: 32 / WARN: 0 / FAIL: 0
[G.3] Version stamps consistent … PASS   [I.6] No retired-claim phrases … PASS   [G.4] Doc count/version claims consistent … PASS

# test-init.sh (2 stable runs, identical)
PASS: 276 / FAIL: 0

# Mutation (seed removed)
FAIL  rejected-decisions.md seed present (generic)   (×3)
PASS: 273 / FAIL: 3
# Mutation restored → IDENTICAL → PASS: 276 / FAIL: 0
# git ls-files (both back, staged A): .harness/rejected-decisions.md + templates/common/.harness/rejected-decisions.md

# AC-2 reproducer:  records(## headings)=9  Decision=9  Why=9  Origin=9 ; exactly 1 'deferred' (design-it-twice)

# Stamps: plugin 0.40.0 / marketplace 0.40.0 / README 0.40.0 / README.zh-CN 0.40.0 / CHANGELOG [0.40.0] - 2026-06-20
```

> Mutation note: the `git mv`-fallback during the mutation transiently unstaged the seed; I re-staged it (`git add`) so `git ls-files` lists BOTH files exactly as before the test, and re-ran verify_all (I.6 PASS, both in scope). The tmp backup was removed. Final tree state = pre-test state.

## verify_all result
- Total checks: 32 → 32 (no new check; AC-7).
- Pass: 32
- Fail: 0 (gate green)
- Warn: 0
- New tests added (this stage): 0 (developer's +3 assertions proven non-vacuous by mutation).
- Baseline updated: no change needed — `test_init_bash_no_python3_assertions` already = 276 and matches the captured `test-init.sh` run (273+3). `verify_all_checks` stays 32.

## test-init result
- `test-init.sh`: PASS 276 / FAIL 0 (2 stable runs). Matches baseline `test_init_bash_no_python3_assertions: 276` (= 273 prior + 3 = +1 assertion × 3 project types).
- `test-init.ps1`: NOT RUN — PowerShell denied to this agent. **operator-pending**: PM runs `pwsh .harness/scripts/test-init.ps1` (expect 308+3=311, capture the real total), sets baseline `test_init_ps_assertions` from the captured run, updates both README `test--init-308%2F308` badges to the captured total. Do not hand-type 311.

## Defects found
None. 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR.

## Stability
- `verify_all.sh` ran 3×, all 32/0/0 — no flakes. ✅
- `test-init.sh` ran 2× clean (276/0) + 1× mutated (273/3, deterministic) + restored (276/0) — deterministic, no flakes. ✅

## Operator-pending (PowerShell — PM reconciles; never faked)
1. `pwsh .harness/scripts/test-init.ps1` → capture total → set baseline `test_init_ps_assertions` + both README `test--init` badges from the captured run (expect 311).
2. `pwsh .harness/scripts/verify_all.ps1` → expect 32/0/0 (PS twin; bash twin confirmed 32/0/0 incl. G.3/G.4/I.6).
3. (Optional) `test-real-project` both shells → expect 90/90 unchanged; reconcile only if the captured run moves.
4. Reconcile the co-mingled non-T-09 working-tree churn at commit (PM's, flagged in 04 — not a T-09 defect).

## Verdict
**APPROVED FOR DELIVERY** (0 defects). Every AC has independent test evidence; the one load-bearing assertion is proven non-vacuous by mutation; verify_all.sh 32/0/0 and test-init.sh 276/0 are stable; baseline preserved (bash 276 matches captured run, PS 308 left for PM). PowerShell twins are operator-pending per the deny rule, not faked.
