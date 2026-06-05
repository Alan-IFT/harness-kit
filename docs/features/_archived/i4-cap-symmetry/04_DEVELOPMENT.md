# 04 — Development Record · i4-cap-symmetry (T-009)

> Stage 4. Implements 02_SOLUTION_DESIGN.md (D1–D4 + §5) under the 5 dev-time
> conditions C-1..C-5 from 03_GATE_REVIEW.md. Upstream docs (01/02/03) read-only.

## Summary

Retargeted `verify_all`'s I.4 size check from a total-physical-line count
(`Measure-Object -Line` in PS, `wc -l` in bash — two implementations of the
wrong metric, divergent at the trailing-newline boundary) to the **same insight
DATA-line regex count** `archive-task` already rotates on, identically in both
shells. The spurious bash WARN clears with no edit to the index and no rotation
(live file = 25 data lines < 30). Two repo dogfood rule fragments got a one-word
"evidence lines" clarification; the stale `manual-e2e-test.md` test_init counts
were reconciled to a fresh captured run. No new check — tally stays 32.

## Files changed

- `.harness/scripts/verify_all.ps1` — I.4 block (lines 396–404): counting line
  `Measure-Object -Line` → `@(Get-Content … | Where-Object { $_ -match '^\s*-\s+' }).Count`
  (verbatim from `archive-task.ps1:71`, `@(...)` wrapper kept per C-1/F-4);
  Step description `"insight-index.md <=30 lines"` → `"… <=30 evidence lines"`;
  WARN body `"$n lines …"` → `"$n evidence lines …"`.
- `.harness/scripts/verify_all.sh` — I.4 block (lines 417–427): counting line
  `wc -l < …` → `grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md || true`
  (verbatim regex from `archive-task.sh:69`, **`|| true` kept** per C-1);
  all three Step descriptions + WARN body changed "lines" → "evidence lines";
  block comment updated to "≤30 evidence lines".
- `.harness/rules/05-insight-index.md` — line 5 "≤30-line append-only file" →
  "≤30-evidence-line append-only file"; line 25 "Max 30 lines total." →
  "Max 30 evidence (data) lines (header lines are free)."
- `.harness/rules/70-doc-size.md` — line 27 Caps-table cell "30 lines" →
  "30 evidence lines".
- `docs/manual-e2e-test.md` — line 3 test_init counts 227/191 → **251/213**
  (reconciled to the fresh captured run; see below).
- `.harness/scripts/baseline.json` — **no change** (already 251/213 = the fresh
  captured run; baseline.json is the canonical source per D4 and was confirmed,
  not edited).

> Not a developer edit: `docs/tasks.md` carries the PM-owned T-009 registration
> row (added at pipeline start). Left as-is; out of this stage's scope.

## The exact I.4 edits (both shells)

**PowerShell** (`verify_all.ps1:398`):
```
- $n = (Get-Content ".harness/insight-index.md" | Measure-Object -Line).Lines
+ $n = @(Get-Content ".harness/insight-index.md" | Where-Object { $_ -match '^\s*-\s+' }).Count
```

**Bash** (`verify_all.sh:419`):
```
- n=$(wc -l < .harness/insight-index.md)
+ n=$(grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md || true)
```

Threshold `>30`, WARN/PASS branches, and early-return-on-missing-file semantics
left unchanged in both shells. The two expressions are membership-equivalent and
immune to the trailing-newline / CRLF off-by-one (D3, GR §2).

**Cross-shell parity proof on the live 25-data-line file:**
| Expression | Count | Verdict |
|---|---|---|
| bash `grep -c '^[[:space:]]*-[[:space:]]'` | **25** | PASS (≤30) |
| PS `@(… Where-Object { $_ -match '^\s*-\s+' }).Count` | **25** | PASS (≤30) |
| old `wc -l` (bash, pre-edit) | 33 | (was WARN) |
| old `Measure-Object -Line` (PS, pre-edit) | 31 | (was WARN) |

Both new expressions yield the SAME integer (25) → SAME verdict (PASS). The
cross-shell split is gone; I.4 now equals `archive-task`'s rotation count.

## C-2 — old I.4 description not test-pinned (git grep)

`git grep` for `insight-index.md ≤30 lines` / `<=30 lines` repo-wide: the only
live hits were `verify_all.{ps1,sh}` themselves (what I edited). All other hits
are out of scope: `docs/features/_archived/**` (archived history), the T-009
design/gate docs, and the `.tmpl` siblings — which are all **`F.4`** (user-project,
C-3, not `I.4`). **No `test-*.{ps1,sh}` asserts the I.4 description string.** Full
rename was safe; applied.

## D4 / C-4 — baseline ↔ manual-e2e reconcile (FRESH captured run)

Ran both test-init scripts fresh this stage (python3 non-functional here — the
Microsoft Store stub fails the `echo '' | python3 -c pass` probe — so the bash run
took the **no-python3** path, which is exactly what `test_init_bash_no_python3`
measures):

| Script | `PASS:` (captured verbatim) | FAIL |
|---|---|---|
| `test-init.ps1` (tail :642) | **251** | 0 |
| `test-init.sh`  (tail :545, no-python3) | **213** | 0 |

Values set:
- `baseline.json:11` `test_init_ps_assertions` = **251** (already equal to the
  captured run → confirmed, no edit; baseline.json canonical per D4).
- `baseline.json:12` `test_init_bash_no_python3_assertions` = **213** (already
  equal → confirmed, no edit).
- `docs/manual-e2e-test.md:3` = **251 / 213** (was stale 227 / 191 → corrected to
  the captured run, the real drift D4 targets).

The stale pair 227/191 was neither the baseline value (251/213) nor a guess — the
fresh run decided, per C-4 / AC-4. Both 251 and 213 are pasted above verbatim.

## verify_all result

| Shell | Baseline (pre-edit) | After changes | I.4 |
|---|---|---|---|
| PowerShell | 31 PASS / 1 WARN / 0 FAIL | **32 PASS / 0 WARN / 0 FAIL** | WARN(31)→**PASS**(25) |
| Bash (Git-bash) | I.4 WARN observed (`wc -l`=33) | **32 PASS / 0 WARN / 0 FAIL** | WARN(33)→**PASS**(25) |

- **Delta:** 1 WARN resolved per shell (I.4); 0 new failures; tally held at 32.
- **G.4 still PASS at 32** (no Step added → claim↔version count undisturbed).
- **I.6 / E.4b / E.5 still PASS** in both shells (the "lines"→"evidence lines"
  doc edits introduced no banned anchor, changed no rule-path reference, removed
  no doc — C-5 confirmed in both shells).
- Git-bash resolved via `git.exe` root (`/mingw64/bin/git`, bash 5.2.37 MSYS2),
  not the WindowsApps WSL stub (L27).

Key SH post-edit lines:
```
[I.4] insight-index.md ≤30 evidence lines ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
  PASS: 32   WARN: 0   FAIL: 0
```

## Design drift (if any)

None. Every edit matches 02 §5 exactly. The one design/live discrepancy was
already flagged by the GR (F-1/C-1): 02 §3 D3 claims `verify_all.sh` runs
`set -euo pipefail`; live `verify_all.sh:3` is `set -uo pipefail` (no `-e`). Per
C-1 I kept `|| true` regardless (it mirrors `archive-task.sh:69` and yields a
clean `0` on zero matches) — so the prescribed code is correct even though the
design's rationale sentence is wrong. Not drift in the implementation.

## Open issues for review

- None blocking. Note for the reviewer: capturing the bash baseline while a
  later Edit landed on the same file mid-read produced a one-off spurious
  `syntax error near unexpected token '}'` in that interrupted baseline run only
  (Git-bash reads scripts incrementally). Both clean post-edit runs parse and
  pass 32/32; the artifact is not a real defect. Future stages should let a
  verify_all run finish before editing the script it is reading.

## Dev-map updates

None — no file added, moved, or removed; pure in-place logic substitution +
doc-sync. `docs/dev-map.md` already states "32 checks at v0.21.0", still accurate.

## git diff --stat (developer-owned files)

```
 .harness/rules/05-insight-index.md |  4 ++--
 .harness/rules/70-doc-size.md      |  2 +-
 .harness/scripts/verify_all.ps1    |  6 +++---
 .harness/scripts/verify_all.sh     | 10 +++++-----
 docs/manual-e2e-test.md            |  2 +-
 5 files changed, 12 insertions(+), 12 deletions(-)
```
(`baseline.json` unchanged — already at captured 251/213; `docs/tasks.md` row is
PM-owned, excluded.)

## Verdict

READY FOR REVIEW

---

DEVELOPMENT COMPLETE — verify_all PS 32/32 SH 32/32 (SH I.4 WARN resolved) · I.4 now counts evidence lines both shells · baseline test_init reconciled to 251/213

---

## Version bump v0.21.1 (release pass)

Release-ships the T-009 I.4 fix (already DONE + QA-passed, both shells 32/32) by
bumping the project version **v0.21.0 → v0.21.1** (patch — internal `verify_all`
I.4 metric fix; no externally visible behaviour change, no check added). The
verify_all check COUNT is held at **32** — only the VERSION token moves on the
count-bearing claims. Done in lockstep across the full L14 fan-out so no count/
version claim or CHANGELOG entry is left stale; G.4 used as the completeness
oracle (current-version-anchored — it FAILs on any claim still reading v0.21.0).

### Files changed (this pass only — 9 files)

**G.3-gated stamps (version → 0.21.1):**
- `.claude-plugin/plugin.json:4` — `"version": "0.21.0"` → `"0.21.1"`.
- `.claude-plugin/marketplace.json:17` — `plugins[0].version` `"0.21.0"` → `"0.21.1"`.
- `README.md:5` — version badge `version-0.21.0-blue` → `version-0.21.1-blue`
  (the `verify__all-32%2F32` badge has no version token → left at 32/32).
- `README.zh-CN.md:5` — version badge `version-0.21.0-blue` → `version-0.21.1-blue`.

**Version-bearing COUNT claims (VERSION token → v0.21.1, count KEPT at 32):**
- `AI-GUIDE.md:36` — `32/32 at v0.21.0` → `32/32 at v0.21.1`.
- `AI-GUIDE.md:69` — `32 checks at v0.21.0` → `32 checks at v0.21.1`.
- `docs/dev-map.md:60` — `(32 checks at v0.21.0)` → `(32 checks at v0.21.1)`.
- `docs/dev-map.md:133` — `runs all 32 checks (at v0.21.0)` → `... (at v0.21.1)`.
- `.harness/rules/40-locations.md:25` — `(32 checks at v0.21.0` → `(32 checks at v0.21.1`.
- `docs/manual-e2e-test.md:3` — the `verify_all at 32 checks at v0.21.0` clause →
  `... v0.21.1`. The `test-init` 251/213 assertion numbers in the same line were
  **left untouched** (they carry no version token and were reconciled in stage 4).

**CHANGELOG:**
- `CHANGELOG.md` — NEW top entry `## [0.21.1] - 2026-06-05` inserted between
  `## [Unreleased]` and `## [0.21.0]`, describing the I.4 evidence-line fix +
  cross-shell symmetry + baseline reconcile, "No check added (count stays 32)".
  Older entries (`[0.21.0]`, `[0.20.0]`, …) left verbatim.

**Left as-is (correctly):** the `verify__all-32%2F32` badges, README `(32 checks)`
(L159) / README.zh `（32 项检查）` (L159), and `baseline.json` `"verify_all_checks": 32`
carry NO version token → no edit. The I.4 logic, G.4 mechanism, `.claude/settings.json`,
test-supervisor, archive-task, and the `.tmpl` cap siblings were all out of scope
and untouched.

### How G.4 confirmed completeness

G.4 is current-version-anchored: it reads `$version` from `plugin.json` (now
`0.21.1`) and `$count` from the live step tally (`$report.Count + 1` = 32), then
asserts each of 11 parallel-array doc claims contains the exact SOT-derived
substring. After bumping `plugin.json` to 0.21.1, any count claim still reading
`v0.21.0` makes G.4 FAIL and name the file + found-value + expected-value — so I
ran G.4 as the oracle rather than trusting a manual sweep. Both shells' G.4 use
the byte-identical 11-row file/shape/expect table (`verify_all.sh:684-722`,
`verify_all.ps1:649-660`); the 6 version-bearing rows now expect `… v0.21.1`, the
5 count-only rows (2 badges, `(32 checks)`, `（32 项检查）`, baseline.json) expect
the bare `32`. G.4 PASSed in BOTH shells → every count-claim version is consistent
with `plugin.json` and no claim was missed. (The repo's own
`verification_history.log` retains the T-008 audit entries where this same G.4
FAILed on stale `v0.20.0` claims — proof the gate is load-bearing, not decorative.)

### Real verify_all tallies (both shells, post-bump)

| Shell | Invocation | Summary | G.3 | G.4 | I.4 |
|---|---|---|---|---|---|
| Bash (Git-bash 5.2.37 MSYS2) | `bash verify_all.sh` (RC=0) | **PASS: 32  WARN: 0  FAIL: 0** | PASS | PASS | PASS (25 evidence lines) |
| PowerShell (pwsh 7) | `pwsh -File verify_all.ps1` (RC=0) | **PASS: 32  WARN: 0  FAIL: 0** | PASS | PASS | PASS (25 evidence lines) |

Both shells clean 32/0/0 — the stage-4 I.4 fix means SH is now WARN-free, and this
bump kept it clean. Pre-bump baseline (captured before any edit) was already
SH 32/0/0; the bump added zero failures and the version tokens flipped G.4 from
"would-FAIL-if-bumped-without-claims" to PASS. (Operational note: under MSYS the
I.6 check — a multi-anchor scan over every `git ls-files` entry — takes ~2-3 min,
so a redirected run looks "stalled" at the I.7 line until I.6/J.1/G.4 flush; both
runs completed cleanly with RC=0 and the `=== Summary ===` block above.)

### Post-bump `git grep 0.21.0` residual

`git grep -n "0\.21\.0"` afterward → ONLY historical/audit refs remain; **no live
current-state v0.21.0 stamp**:
- `CHANGELOG.md:14` — the historical `## [0.21.0] - 2026-06-05` entry (must stay).
- `docs/tasks.md:23` — the T-008 delivery record (PM-owned history).
- `.harness/insight-index.md:33` — the L14 insight's **evidence citation**
  (`evidence: T-008, v0.21.0 ship bump`), a backward-looking fact, not a stamp.
- `.harness/scripts/verification_history.log` — append-only audit log of past runs
  (the T-008 bump's G.3/G.4-FAIL-then-PASS trace); never edited.
- `docs/features/_archived/**` — archived T-008 stage docs (frozen history).

No Roadmap row exists in this repo's README to flip (the brief's "v0.21.0 Roadmap
row" caveat is N/A here). Nothing else live references v0.21.0.

### Design drift (release pass)

None. This is a pure stamp/claim/CHANGELOG bump per the L14 + G.4 contract; no
source logic touched. The I.4 implementation from stage 4 is unchanged.

### Verdict (release pass)

VERSION BUMP COMPLETE — v0.21.1 · verify_all PS 32/32 SH 32/32 · G.4 confirmed count-claim versions consistent
