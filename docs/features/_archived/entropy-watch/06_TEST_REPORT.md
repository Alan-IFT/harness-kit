# 06 — Test Report · T-11a entropy-watch

> Stage 6 (QA Tester). Mode: full. deferred-human: defer, do not ask. CR = APPROVED WITH NOTES (both axes clean).
> PowerShell denied to sub-agent → every PS-half run is **operator-pending** (never faked).
> Source of truth: `.harness/scripts/verify_all.sh` (Bash). Cadence behavior probed via the live `entropy-cadence.sh`.

## Test plan

| Acceptance criterion | Test case(s) | Evidence |
|---|---|---|
| AC-1 scan grammar+determinism | EP-1..EP-4 grammar + `Entropy-verdict:` spec present in reference | `grep -c` = 7 hits in `references/entropy-scan.md` |
| AC-2 observer boundary | frontmatter `tools:` excludes Edit/Bash/PowerShell/Task; entropy exception widens READ only | `supervisor.md` L4 = `Read, Write, Glob, Grep`; word-boundary assert CLEAN |
| AC-3 shared due-check single source | `N=5` literal once per shell; no skill restates threshold | sh L27 (count 1), ps1 L32 (count 1); stream/deflate restate = 0 |
| AC-4 stream surface (DUE/NOT-DUE) | stream wiring: cadence check → DUE appends `## Entropy watch` after `## Needs your input`; NOT-DUE → no scan/section | `harness-stream/SKILL.md` L158-176 (read) |
| AC-6 non-blocking + fail-open + 32 checks | cadence always exit 0; watch runs only on normal drain exit; no new check | verify_all 32/0/0; fail-open probes exit 0 |
| AC-7 cadence semantics | fresh→NOT-DUE; ×4→NOT-DUE; 5th→DUE (inclusive); swept→reset; first-of-session count≥1→DUE | live `entropy-cadence.sh` sequence (below) |
| AC-8 state location + malformed→fail-open | gitignored key=value record; garbage/NUL/empty → NOT-DUE, exit 0, self-heal | corruption probe (below); `git status` shows untracked |
| AC-9 authorize→execute | skill `allowed-tools` excludes Edit/Bash; execute = separate `/harness-goal` dispatch | `harness-deflate/SKILL.md` L15 = `Read, Glob, Grep, Task` |
| AC-11 skill fan-out ledger | 16→17 live arrays flipped both shells; F.1 +entropy-cadence; decoys frozen | C.1/G.1/G.2 = "17 skills"; mutation B (below); decoy sweep |
| AC-12 gate + adversarial section | verify_all.sh 32/0/0; this `## Adversarial tests` section present | full run (below) |

AC-5 (/harness surface) and AC-10 (persistence) = T-11b/T-11c, out of scope.

## Boundary tests added (executed against live `entropy-cadence.sh`)
- Fresh/absent state → `check` → NOT-DUE.
- Counter exactly N-1 (=4) → `check` → NOT-DUE (4 < 5).
- Counter exactly N (=5) → `check` → DUE — **the `>= N` boundary is inclusive at 5**.
- `swept` → counter resets to 0, `last_sweep` stamped → `check` → NOT-DUE.
- `--first-of-session` with count=0 → NOT-DUE (requires count ≥ 1); with count=1 → DUE.
- Malformed state (NUL bytes + non-integer count) → `check` → NOT-DUE, exit 0; `delivered` self-heals to a valid record.
- Empty state file → `check` → NOT-DUE, exit 0.

## Adversarial tests (REQUIRED — one hypothesis per probe, with tool output)

Verdict is based on whether the implementation **survived** these independent reproducers (I wrote each one from the AC / boundary table, not from `04_DEVELOPMENT.md`).

| Probe | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote it) | Outcome |
|---|---|---|---|
| Cadence boundary | counter==N is off-by-one → DUE fires at 4 or skips at 5 | live `entropy-cadence.sh check/delivered/swept` sequence | **Survived** — NOT-DUE@4, DUE@5 (inclusive), reset on swept |
| first-of-session | flag makes count==0 DUE (over-eager) | `check --first-of-session` at count 0 then 1 | **Survived** — NOT-DUE@0, DUE@1 (requires count≥1) |
| Fail-open | garbage/NUL state crashes the script or returns DUE → blocks a drain | write NUL+non-int state, then `check` | **Survived** — NOT-DUE, exit 0; `delivered` self-heals |
| Load-bearing mutation A (F.1) | the pair isn't actually gated | remove `entropy-cadence` from F.1 array, then delete `entropy-cadence.sh` | **Gated** — array-only removal silently passes; deleting a real half → F.1 **FAIL** |
| Load-bearing mutation B (16→17) | the 17th skill isn't actually gated in README | remove `harness-deflate` from G.1 array, then remove the README mention | **Gated** — array-only passes; removing the README mention → G.1 **FAIL** `missing: harness-deflate` |
| Observer boundary | entropy exception leaked Edit/Bash/Task into frontmatter | assert `supervisor.md` L4 has no Edit/Bash/PowerShell/Task | **Survived** — `tools: Read, Write, Glob, Grep` |
| AC-3 single source | threshold duplicated → AC-3 violated | grep `N=5` per shell + in skills | **Survived** — 1 per shell, 0 in skills |
| Decoys frozen | a frozen count wrongly flipped | grep "14 assets", "8 agents", "32 checks", 314, "18 skills", "9 agents" | **Survived** — all frozen; no over-flip |
| Stability | cadence non-deterministic / flaky | run full boundary sequence ×3 | **Survived** — identical all 3 runs |

### Tool output (evidence)

**Cadence boundary + first-of-session:**
```
fresh/absent      check                       -> NOT-DUE
delivered ×4      check                       -> NOT-DUE   (4 < 5)
delivered (5th)   check                       -> DUE       (inclusive at N=5)
swept             check                       -> NOT-DUE   (count=0, last_sweep stamped)
count=0           check --first-of-session    -> NOT-DUE   (needs count >= 1)
count=1           check                       -> NOT-DUE   (1 < 5)
count=1           check --first-of-session    -> DUE
```

**Fail-open (corrupt state):**
```
state = \x00\x01garbage...\xff\xfeNULbyte / delivered_since_sweep=not-a-number / last_sweep=###
check                    -> NOT-DUE   exit 0
check --first-of-session -> NOT-DUE   exit 0
delivered                -> count=1   exit 0   (self-healed valid record)
empty file: check        -> NOT-DUE   exit 0
```

**Load-bearing mutation A (F.1 gating):**
```
remove entropy-cadence from F.1 array only:   [F.1] ... PASS   (array-only NOT sufficient to fail)
restore array, hide entropy-cadence.sh:       [F.1] ... FAIL   (genuine gating proven)
restore file:                                 [F.1] ... PASS
```

**Load-bearing mutation B (G.1 / 16→17 gating):**
```
remove harness-deflate from G.1 array only:   [G.1] ... PASS   (array-only NOT sufficient to fail)
restore array, remove README mention:         [G.1] ... FAIL   missing: harness-deflate
restore README:                               [G.1] ... PASS
```

**Note on mutation mechanics (honest):** removing a name from a verify_all array does NOT by itself fail the check — these arrays fail only when a *listed* asset is missing. So the array-only mutation proves coverage *stops* (a silent regression risk), while the *genuine* gating proof is removing the underlying asset (the file / the README mention) with the array intact. Both directions are recorded above; the pair and the 17th skill are confirmed actually gated. After every mutation the file was restored byte-identical to a pre-mutation backup (`diff` = IDENTICAL).

**Observer boundary + supervisor size:**
```
supervisor.md L4: tools: Read, Write, Glob, Grep   (no Edit/Bash/PowerShell/Task)
supervisor.md line count: 279   (≤ 300, expected 279)
harness-deflate SKILL.md L15: allowed-tools: Read, Glob, Grep, Task
```

**Decoys frozen:**
```
harness-status "14 required assets"  -> present, unchanged
"17 skills + 8 framework agents"     -> banner correct (agents stay 8)
"32 checks"                          -> README L169, L277-280 unchanged
test--init-314 badge                 -> unchanged
no "9 framework agents" / "18 skills" anywhere -> CLEAN (no over-flip)
```

**Stability (×3):**
```
run 1: fresh=NOT-DUE  after4=NOT-DUE  after5=DUE  afterswept=NOT-DUE
run 2: fresh=NOT-DUE  after4=NOT-DUE  after5=DUE  afterswept=NOT-DUE
run 3: fresh=NOT-DUE  after4=NOT-DUE  after5=DUE  afterswept=NOT-DUE
```

## Non-blocking (informational, fail-open) — confirmed by SKILL read
`harness-stream/SKILL.md` L158-176: the entropy watch runs **after** `## Needs your input` (T-022 FIRST invariant preserved), is explicitly "non-blocking — never changes the drain's exit verdict", fails open to NOT-DUE on any cadence I/O error, and "a baseline-FAIL hard stop, a STOP, or a guard-rm block still take precedence … never converts an informational sweep into a stop." It is informational output, not a guard and not a verify_all check.

## verify_all result
- Total checks: 32 → 32 (no new check; the new skill extends C.1/G.1/G.2 *arrays*, the cadence pair joins the F.1 *array* — neither is a new check row).
- **PASS: 32 · WARN: 0 · FAIL: 0** (`bash .harness/scripts/verify_all.sh`).
- C.1/G.1/G.2 assert "17 skills"; F.1 includes entropy-cadence; G.3 0.41.0 consistent; G.4 [0.41.0] heading + count claims consistent; I.3 supervisor 279 ≤ 300; I.6 clean over the new SKILL + reference + cadence pair.
- New automated tests added: **0** (T-11a adds no automated-test assertions; behavior is covered by the existing verify_all arrays + the adversarial smoke probes above. The cadence script is dogfood-only this slice; no test-init seed asset — design §Out-of-scope).
- Baseline updated: **no** (counts unchanged — verify_all 32, test-init 276, test-supervisor 45; baseline only goes up and nothing went up).

## Regression
- `test-init.sh` → **276/0** (unchanged — new skill is top-level, not a generated-project asset).
- `test-supervisor.sh` → **45/0** (supervisor structural asserts intact after the entropy-lens edit + Hard-rule #1 exception).
- verify_all.sh full run → **32/0/0** (baseline preserved).

## Defects found
- None (BLOCKER / CRITICAL / MAJOR / MINOR): **0**.
- NIT (informational, not a defect): after a `delivered` self-heal over a corrupt file, a malformed `last_sweep` value (e.g. `###`) is preserved verbatim — `read_last_sweep` does not validate it. Harmless: `last_sweep` is an informational/unparsed field (design §3) and never enters the due-logic, which uses only the (validated) integer counter. No action required.

## Stability
- Cadence boundary sequence ran 3 times → identical results, no flakes. PASS.
- verify_all.sh / test-init.sh / test-supervisor.sh each ran cleanly (deterministic). PASS.

## PowerShell (operator-pending — NOT faked)
PS execution is denied to the sub-agent (confirmed: `pwsh` invocation blocked by the deny rule). The following are operator-pending and must be run by the operator/PM:
- `verify_all.ps1` (expect 32/0/0), `test-init.ps1` (expect 314), `test-supervisor.ps1` (expect 49).
- `entropy-cadence.ps1` runtime smoke (expect byte-symmetric with the .sh half).
PS-half correctness rests on code inspection: `entropy-cadence.ps1` mirrors the .sh half line-for-line — same `N=5` (L32), same `due = (count -ge N) -or (firstOfSession -and count -ge 1)` (L96), same `check/delivered/swept` sub-commands and `DUE/NOT-DUE/count=/reset` stdout, raw-byte UTF-8 write (`WriteAllBytes`, no BOM), `.git`-walk repo-root, `$ErrorActionPreference='SilentlyContinue'` fail-open, `exit 0` on all paths.

## Verdict
**APPROVED FOR DELIVERY** — 0 defects (0 BLOCKER/CRITICAL/MAJOR/MINOR, 1 NIT informational). verify_all.sh 32/0/0; test-init 276; test-supervisor 45. Cadence boundary inclusive at N=5, fail-open exit 0 on corrupt/empty/absent state, both load-bearing mutations confirm genuine gating (F.1 pair + 16→17 skill), observer boundary held (frontmatter Read/Write/Glob/Grep), supervisor 279 ≤ 300, decoys frozen, non-blocking wiring confirmed. PS twin (verify_all.ps1, test-init.ps1, test-supervisor.ps1, entropy-cadence.ps1) operator-pending per the deny rule.
