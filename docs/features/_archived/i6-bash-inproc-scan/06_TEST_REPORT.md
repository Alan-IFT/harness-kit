# Test Report — i6-bash-inproc-scan (T-017)

- QA: operator (main agent)
- Date: 2026-06-09
- Verdict: **PASS**

## Acceptance criteria

| AC | Criterion | Result |
|---|---|---|
| AC-1 | `test-verify-i6.sh` passes (positive banned-phrase fixtures ⇒ no false-negative) | **PASS — 58/58** |
| AC-2 | full `verify_all.sh` = 32 PASS / 0 WARN / 0 FAIL | **PASS — 32/0/0** |
| AC-3 | I.6 / verify_all demonstrably faster | **PASS — 12m13s → 44.5s (~12-16×)** |
| AC-4 | new engine ≡ old engine (no behavior change) | **PASS — see below** |

## Evidence (captured runs)

- `bash .harness/scripts/test-verify-i6.sh` → `PASS: 58 / FAIL: 0`, exit 0. Covers: per-fixture
  hit/no-hit (positive entries #1/#3/#4/#5/#6/#9/#10/#11/#12/#13 HIT; accurate/negation/historical/
  gap-over/empty/multiline NO-hit), **Assertion 2 cross-shell parity bash-vs-PowerShell (actively ran,
  agreed on every fixture)**, Assertion 3 structural lockstep (banned/exempt arrays + entry count),
  metacharacter/Unicode no-stderr, gap boundary (40 HIT / 41 no-hit), exempt file+dir predicates.
- `time bash .harness/scripts/verify_all.sh` → `PASS: 32 / WARN: 0 / FAIL: 0`; `real 0m44.511s`.
- Before: `real 12m13.539s` (post-engine-swap, pre-hoist) and ~9 min (original) — both captured this
  session. After hoist: 44.5s.

## AC-4 — equivalence argument + measurement

The hoist is equivalence-by-construction (CR finding 2): the per-entry regex is a pure function of the
entry, so building it once vs per-file yields byte-identical regexes; the scan loop is unchanged.
Behavioral equivalence is proven empirically by **AC-1's positive+negative fixtures** (the engine still
catches every banned phrase and still suppresses every excluded/accurate one) and by **Assertion 2's
live bash-vs-PowerShell hit-set agreement**. On the current clean tree both old and new yield zero I.6
hits (verify_all 32/0/0).

## Bottleneck profile (why AC-3 needed the hoist)

| Step | Measurement |
|---|---|
| `i6_build_regex` × 4.6k (old per-file rebuild) | did not finish in 9 min (sed-fork storm) |
| T1: build 14 regexes once (hoisted) | 3.2s |
| T2: hoisted + in-process bash scan over tree | 28.6s |
| T3: hoisted + one combined grep per file | 7.8s (rejected — needs match→entry disambiguation) |

The grep→bash engine swap alone (no hoist) = 12m13s. The hoist is what delivers AC-3; the in-process
scan (29s) is kept over hoisted-grep (~4min of spawns).

## Adversarial / regression notes

- No false-negative: AC-1 positive fixtures are the guard — all HIT.
- `nocasematch` leak check: J.1 and all later checks still PASS (32/0/0), confirming no shell-option leak.
- Cosmetic span-text difference (BASH_REMATCH vs grep -o) does not affect any assertion (indices only).

## Verdict

PASS → Delivery.
