# 06 — Test Report · i6-semantic-guard (T-004 · v0.18.0)

Stage 6 adversarial QA. Walked the 11 ACs, ran the matcher under independent
reproducers, and stress-tested the false-positive guard.

## Test plan

| AC | Test case | Driver / probe file |
|---|---|---|
| AC-1 bypass caught | `fx-bypass.md` (in-driver) + my own AC-1 probe (40-char extreme-end gap) | `scripts/test-verify-i6.{sh,ps1}` + inline `tmp_qa_adv.{sh,ps1}` (deleted post-run) |
| AC-2 adjacent caught | `fx-adjacent.md` + inline `ac2.md` | same |
| AC-3 false positive not raised | `fx-accurate.md`, `fx-negation-pre.md`, `fx-historical.md`, `fx-arrow-accurate.md` + inline `ac3.md`/`ac3b.md` | same |
| AC-4 repo stays green | live `bash verify_all.sh` + `pwsh verify_all.ps1`; inline injection-and-restore probe on `docs/tasks.md` | live verify_all both shells |
| AC-5 cross-shell parity | driver Assertion 2 + my inline corpus run through bash AND PS matchers | both `test-verify-i6.{sh,ps1}` Assertion 2; `tmp_qa_adv.{sh,ps1}` |
| AC-6 case-insensitivity | `fx-case.md` + inline `ac6.md` (full ALL-CAPS) | same |
| AC-7 metachar safety | `fx-meta-backtick.md`, `fx-meta-arrow.md` + inline `ac7-meta.md` with regex-class chars | same |
| AC-8 exemption preserved | inline injection probe on `CHANGELOG.md` AND `docs/features/_archived/...` | both verify_all shells run live |
| AC-9 gap boundary | `fx-gap-exact.md` (40), `fx-gap-over.md` (41) + my own 40 and 41 dot-filler probes | same |
| AC-10 docs synced | live grep sweep across §10 file list for `v0.18.0` and absence of `v0.17.4` | Grep |
| AC-11 test driver | bash and PS test-verify-i6 both run | same |

## Boundary tests confirmed

- Empty file → NO hit (`fx-empty.md`) — both shells.
- Multiline (anchors on separate lines) → NO hit (`fx-multiline.md`) — both shells (D-3).
- Gap = 40 chars → HIT; gap = 41 chars → NO hit (exact boundary).
- Unicode CJK case-folding (no-op) and U+2192 arrow → both shells agree.
- CRLF line ending (Windows) on a banned phrase → HIT in both shells.
- Regex metacharacters in line content (`[.+*?{}()|^$\\]`) → no engine error, no false-fire.

## verify_all result — both shells

**bash** (`bash scripts/verify_all.sh`):

```
[I.6] No retired-claim phrases in current docs/templates ... PASS

=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

**PowerShell** (`pwsh -NoProfile -File scripts/verify_all.ps1`):

```
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS

=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

Both shells: 30/0/0, I.6 = PASS. Check count unchanged at 30 (no new check added).

## test-verify-i6 result — both shells

**bash** (`bash scripts/test-verify-i6.sh`):

```
=== Result ===
  PASS: 34
  FAIL: 0
```

**PowerShell** (`pwsh -NoProfile -File scripts/test-verify-i6.ps1`):

```
=== Result ===
  PASS: 35
  FAIL: 0
```

Twin count delta of 1 is the documented bash combined-vs-PS-split structural lockstep
assertion (per dev's 04_DEVELOPMENT.md, expected).

## Adversarial tests (REQUIRED — one per AC)

I re-implemented the matcher predicate in **independent probe scripts**
(`tmp_qa_adv.{sh,ps1}`, removed after the run — fixtures regenerated on each
invocation, no shared state with the developer's driver). The probes target shapes
explicitly NOT in the developer's fixture corpus.

### AC-1 — bypass caught (novel shape, max-gap-budget clause)

- **Hypothesis**: a multi-clause sentence packing exactly the 40-char gap budget
  between `regenerates` and `CLAUDE.md` might slip if my char-count was off-by-one
  or the regex pre-evaluation trimmed something.
- **Probe**: `And so harness-sync regenerates, with documented architectural change, CLAUDE.md`
  — `awk` confirmed `index_after("regenerates") .. index("CLAUDE.md")` = exactly 40 chars.
- **Outcome — SURVIVED**: both shells HIT entry #5.

```
AC-1 measured inter-anchor chars: 40
AC-1 scan result:
5:1:regenerates, with documented architectural change, CLAUDE.md
```

### AC-2 — adjacent still caught (zero-gap, with prefix noise)

- **Hypothesis**: maybe the line-start anchor or `grep -m1` short-circuit drops a
  match that doesn't start at column 0.
- **Probe**: `prefix prefix regenerates CLAUDE.md`.
- **Outcome — SURVIVED**: both shells HIT entry #5.

```
AC-2 scan result:
5:1:regenerates CLAUDE.md
```

### AC-3 — false positive NOT raised

Three independent probes, each engineered to *almost* trip the matcher:

- **AC-3-a hypothesis**: short accurate prose with the two anchor *words* tightly
  packed (`composed in CLAUDE.md style`) might trip entry #2 (`Composed~into~`CLAUDE.md``)
  via the gap-tolerant scan, even though the middle anchor `into` is missing.
- **AC-3-a outcome — SURVIVED**: NO HIT in either shell. Ordered-anchor structure
  (middle anchor missing) does its job.

```
AC-3 scan result (expected: NO HIT — entry #2 lacks 'into'):
(no hits)
```

- **AC-3-b hypothesis** (inverse — confirms entry #2 IS firable): historical narration
  `Composed into \`CLAUDE.md\` was the v0.2 model` carries all three anchors with no
  negation. Should HIT (entry #2 has no `v0.2` exclude after F-4 fix).
- **AC-3-b outcome — SURVIVED**: HIT entry #2 in both shells. Confirms the guard is
  not silently broken on entry #2.

```
AC-3-b scan result (expected: HIT entry #2 — no negation):
2:1:Composed into `CLAUDE.md`
```

- **AC-3-c hypothesis**: regex metacharacters in line content might leak through the
  `.claude/` exclude and let entry #10 false-fire.
- **AC-3-c outcome — SURVIVED**: NO HIT. Both shells agree the `.claude/` line-scoped
  exclude clears `[.+*?{}()|^$\\]/.harness/ → CLAUDE.md continues here .claude/`.

### AC-4 — repo stays green (live injection + restore probe)

- **Hypothesis**: maybe the matcher is broken in a way that always returns no hits,
  so the live PASS is meaningless.
- **Probe**: appended `QA-PROBE-MARKER: harness-sync regenerates CLAUDE.md (this is a banned phrase appended for the AC-4 adversarial probe)` to `docs/tasks.md` (tracked,
  non-exempt), ran `bash verify_all.sh`, then `cp` restored the file from backup,
  re-ran verify_all to confirm green state recovers.
- **Outcome — SURVIVED**: with the injection, verify_all reported **PASS 29 / WARN 0 / FAIL 1** and named the exact line:

```
[I.6] No retired-claim phrases in current docs/templates ... FAIL
      Retired-claim phrases found in live files:
docs/tasks.md:26 : [regenerates~CLAUDE.md] — harness-sync does not regenerate CLAUDE.md since v0.10 | matched: "regenerates CLAUDE.md"

=== Summary ===
  PASS: 29
  WARN: 0
  FAIL: 1
```

After restore: **PASS 30 / WARN 0 / FAIL 0**. Proves the matcher is actually alive
and the live PASS is meaningful. File was diff-confirmed byte-identical to backup.

### AC-5 — cross-shell parity (independent corpus)

- **Hypothesis**: bash `grep -E` and PS `[regex]` could diverge on one of the
  metachar / CJK / CRLF probes; the driver's parity assertion might be passing only
  on the fixtures it knows.
- **Probe**: ran my full inline corpus (12 fixture cases) through both shells, then
  hand-diffed each `(idx:line:span)` triple.
- **Outcome — SURVIVED**: every shell pair agrees byte-for-byte. Highlights:
  - CRLF line ending → both shells HIT entry #5, same span (`regenerates CLAUDE.md`).
  - ALL-CAPS `HARNESS-SYNC REGENERATES THE CLAUDE.MD STUB` → both HIT entry #5.
  - U+2192 arrow in `.harness/ subtree → CLAUDE.md per the old contract` → both HIT entry #10.
  - Backtick-spans `regenerates \`CLAUDE.md\` continuously` → both HIT entries #5 AND #6 (entry #5's anchors are a substring of entry #6's; the matcher is intentionally inclusive — not a defect).

### AC-6 — case-insensitivity (full ALL-CAPS)

- **Hypothesis**: maybe the PS implementation uses an operator-default
  case-insensitivity that misbehaves on `.MD` (extension casing).
- **Probe**: `HARNESS-SYNC REGENERATES THE CLAUDE.MD STUB`.
- **Outcome — SURVIVED**: both shells HIT entry #5, matched span `REGENERATES THE CLAUDE.MD`.

### AC-7 — metacharacter safety (engine doesn't crash, doesn't false-match)

- **Hypothesis (a)**: a line packed with regex metacharacters might cause the engine
  to parse part of the file content as a regex operator.
- **Probe (a)**: `[.+*?{}()|^$\\]/.harness/ → CLAUDE.md continues here .claude/`.
- **Outcome — SURVIVED**: no parser error; the entry #10 match would have fired but
  the `.claude/` line-scoped exclude clears it. **Bash stderr is empty; PS no exception.**

- **Hypothesis (b)**: backtick in PS hashtable could mis-escape.
- **Probe (b)**: `harness-sync regenerates \`CLAUDE.md\` continuously`.
- **Outcome — SURVIVED**: both shells HIT entries #5 + #6, no parser error.

### AC-8 — exemption preserved (the CR's flagged coverage gap)

The CR explicitly noted this AC was covered only **indirectly** via the live
verify_all PASS. I closed the gap with a direct injection probe.

- **Hypothesis**: maybe the exempt-file / exempt-dir test has a subtle off-by-one
  (e.g. case-sensitive path comparison on Windows; or `CHANGELOG.md` is matched as
  prefix instead of exact).
- **Probe**: appended `QA-PROBE: harness-sync regenerates CLAUDE.md` to BOTH
  `CHANGELOG.md` AND `docs/features/_archived/ai-safety-guardrails/01_REQUIREMENT_ANALYSIS.md`,
  ran both shells, then restored from backup.
- **Outcome — SURVIVED**: both shells reported PASS 30/0/0 with both files
  carrying the banned phrase, confirming the exemption mechanism works under the
  new matcher:

```
--- bash verify_all ---
[I.6] No retired-claim phrases in current docs/templates ... PASS

=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0

--- PS verify_all ---
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS

=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 0
```

Files restored; diff confirmed byte-identical to backups.

### AC-9 — gap boundary (40 HIT, 41 NO HIT — independent re-creation)

- **Hypothesis**: the global default could be misread as 39, 41, or applied to the
  wrong entry; only an exact-boundary test catches off-by-one.
- **Probe**: generated `regenerates` + 40 literal `.` chars + `CLAUDE.md` (HIT case),
  and `regenerates` + 41 literal `.` chars + `CLAUDE.md` (NO-HIT case).
- **Outcome — SURVIVED**: both shells: 40 → HIT entry #5 with the matched span
  containing all 40 dots; 41 → NO HIT.

```
AC-9-40 (expect HIT):
5:1:regenerates........................................CLAUDE.md
AC-9-41 (expect NO-HIT):
(no hits)
```

### AC-10 — docs synced (live grep sweep across §10 files)

- **Hypothesis**: an additional `v0.17.4` freshness stamp survived in a §10 file.
- **Probe**: `Grep` for `0\.18\.0` and `v0\.17\.4` in each §10 file:
  - `AI-GUIDE.md:35,68` → `v0.18.0` ✅
  - `.claude-plugin/plugin.json:4` → `"version": "0.18.0"` ✅
  - `.claude-plugin/marketplace.json:17` → `"version": "0.18.0"` ✅
  - `README.md:5` → `version-0.18.0` ✅
  - `CHANGELOG.md:10` → `## [0.18.0] - 2026-05-23` ✅
  - `.harness/rules/40-locations.md:25` → `30 items at v0.18.0` ✅ (CR-flagged MAJOR — fixed)
  - `.harness/rules/40-locations.md:43` → `gap-tolerant ordered-anchor scan since v0.18` ✅
  - `docs/dev-map.md:74,130` → `at v0.18.0` ✅
  - `docs/dev-map.md:78` → still `v0.17.4` (test-supervisor assertion-count stamp;
    explicitly out of T-004 §10 scope per CR — correct to leave).
- **Outcome — SURVIVED**: both `40-locations.md:25` AND `:43` are on v0.18.0,
  confirming the CR rollback fix landed.

### AC-11 — test driver (run both, stability x3)

- **Hypothesis**: the drivers could be flaky on temp-dir creation, encoding, or grep
  race conditions.
- **Probe**: ran each driver 3 times back-to-back.
- **Outcome — SURVIVED**: 3/3 bash runs = 34/0; 3/3 PS runs = 35/0. No flakes.

## Regression sweep — every literal banned phrase still hits

For each of the 13 entries I wrote the literal phrase to a fresh file and ran the
matcher. Confirmed each fires its expected entry (and entries #5/#7 *also* fire on
the backtick variants #6/#8 — entry-prefix overlap is by design, not a regression).

```
Entry #1 literal: 1:1:scaffolding-only
Entry #2 literal: 2:1:Composed into `CLAUDE.md`
Entry #3 literal: 3:1:composed by filename order
Entry #4 literal: 4:1:composition order in CLAUDE.md
Entry #5 literal: 5:1:regenerates CLAUDE.md
Entry #6 literal: 5:1:regenerates `CLAUDE.md  ; 6:1:regenerates `CLAUDE.md`
Entry #7 literal: 7:1:regenerated CLAUDE.md
Entry #8 literal: 7:1:regenerated `CLAUDE.md ; 8:1:regenerated `CLAUDE.md`
Entry #9 literal: 9:1:Generated from .harness/rules
Entry #10 literal: 10:1:.harness/ → CLAUDE.md
Entry #11 literal: 11:1:harness-sync 生成 CLAUDE.md
Entry #12 literal: 12:1:harness-sync 合成 CLAUDE.md
Entry #13 literal: 13:1:重新生成的 CLAUDE.md
```

## Insight-index size check

`.harness/insight-index.md` is **27 lines** total (within the I.4 ≤30-line cap, also
PASSed by live verify_all). Both new lines (26, 27) carry an `evidence: T-004, ...`
suffix — evidence-backed per L11 / I.4 contract.

## Defects found

**None of severity BLOCKER / CRITICAL / MAJOR / MINOR / NIT** were uncovered by the
adversarial pass.

### Acknowledged residual (documented design trade-off, NOT a defect)

- The entry #10 `.claude/` line-scoped exclude has a known residual bypass:
  `.harness/ → CLAUDE.md is what it does, despite .claude/ being in the tree` —
  all #10 anchors present, factually a false claim, but `.claude/` on the line
  clears it. Both shells confirmed NO HIT. This is the **explicit design
  trade-off** recorded in `02_SOLUTION_DESIGN.md` §3.2 — the threat model is
  accidental copy-paste drift, not a determined adversary, and the same shape
  exists for #2/#4 (negation word elsewhere on the line). PM-approved; not a QA
  finding.

## Stability

- `bash test-verify-i6.sh`: 3 runs, 34/34 each. ✅
- `pwsh test-verify-i6.ps1`: 3 runs, 35/35 each. ✅
- `bash verify_all.sh`: 2 runs (pre- and post-AC-4 restore), 30/0/0 each. ✅
- `pwsh verify_all.ps1`: 2 runs (pre- and post-AC-8 restore), 30/0/0 each. ✅
- No flakes observed.

## Baseline update

Added two new keys to `scripts/baseline.json` (baseline only goes up; existing keys
preserved):

```json
"test_verify_i6_ps_assertions": 35,
"test_verify_i6_bash_assertions": 34
```

`verify_all_checks` unchanged at 30 (no new verify_all check, per design).
`last_verify` bumped to `2026-05-23`.

## Verdict

**APPROVED FOR DELIVERY**

Both shells PASS 30/0/0; both test-verify-i6 drivers green (bash 34/34, PS 35/35);
all 11 ACs survived independent adversarial probes including the CR's flagged
AC-8 coverage gap (now directly fixtured via the live injection-and-restore probe);
fan-out is complete; insight-index within size cap; no flakes; no defects.
